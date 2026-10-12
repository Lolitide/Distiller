/**
 * 主入口：把一条群消息变成「事件对象」。
 *
 * 流程：T0 归一化 -> T1 分级 -> T2 槽位/时间 -> 置信度 -> 标签。
 */

import { normalize } from './MessageNormalizer';
import { classify } from './MessageClassifier';
import { parseTime, Ymd, TimeSlot, ymdFromTimestamp } from './TimeParser';
import { extractSlots, EventSlots } from './SlotExtractor';
import { renderOneLine } from './EventRenderer';
import { CampusEvent, EVENT_CHAT, EVENT_IGNORE, EVENT_NOTICE, EVENT_TODO } from './EventTypes';

interface TagRule {
  word: string;
  tag: string;
}

const TAG_RULES: TagRule[] = [
  { word: '作业', tag: '课程' },
  { word: '实验', tag: '课程' },
  { word: '考试', tag: '考试' },
  { word: '比赛', tag: '竞赛' },
  { word: '报名', tag: '报名' },
  { word: '截止', tag: '截止' },
  { word: '会议', tag: '会议' },
  { word: '答辩', tag: '答辩' },
  { word: '旅游', tag: '出行' },
  { word: '火车', tag: '出行' },
  { word: '停电', tag: '生活' }
];

function tagsOf(text: string, kind: string): string[] {
  const tags: string[] = [];
  for (let i = 0; i < TAG_RULES.length; i++) {
    const r: TagRule = TAG_RULES[i];
    if (text.indexOf(r.word) >= 0 && tags.indexOf(r.tag) < 0) {
      tags.push(r.tag);
    }
  }
  if (kind === EVENT_NOTICE && tags.indexOf('通知') < 0) {
    tags.push('通知');
  }
  return tags;
}

/** 把一条群消息变成事件对象。base 一般不用传，会用消息自己的时间戳。 */
export function buildEvent(rawText: string, sender: string, timestamp: string, msgId: string,
  base: Ymd | null = null): CampusEvent {
  const text: string = normalize(rawText);
  const baseYmd: Ymd = base !== null ? base : ymdFromTimestamp(timestamp);
  const kind: string = classify(text);

  if (kind === EVENT_IGNORE) {
    return {
      kind: EVENT_IGNORE, title: '', action: '', time: null, place: '', who: '',
      deadline: '', confidence: 0, sourceText: text, sender: sender, timestamp: timestamp,
      msgId: msgId, tags: []
    };
  }

  const timeSlot: TimeSlot | null = parseTime(text, baseYmd);
  const slots: EventSlots = extractSlots(text, kind, baseYmd);

  // 置信度：字段越全越可信
  let conf: number = 0.35;
  if (timeSlot !== null) {
    conf += timeSlot.unresolved ? 0.10 : 0.25;
  }
  if (slots.action.length >= 3) {
    conf += 0.15;
  }
  if (slots.place.length > 0) {
    conf += 0.10;
  }
  if (kind === EVENT_TODO || kind === EVENT_NOTICE) {
    conf += 0.15;
  }
  conf = Math.min(0.95, conf);
  if (kind === EVENT_CHAT) {
    conf = Math.min(conf, 0.3);
  }
  conf = Math.round(conf * 100) / 100;

  let title: string = slots.action.length > 0 ? slots.action : text;
  if (title.length > 22) {
    title = title.substring(0, 22);
  }

  return {
    kind: kind,
    title: title,
    action: slots.action.length > 0 ? slots.action : text,
    time: timeSlot,
    place: slots.place,
    who: slots.who,
    deadline: slots.deadline,
    confidence: conf,
    sourceText: text,
    sender: sender,
    timestamp: timestamp,
    msgId: msgId,
    tags: tagsOf(text, kind)
  };
}

/** 由模板拼出的一句话。 */
export function eventOneLine(ev: CampusEvent): string {
  return renderOneLine(ev);
}
