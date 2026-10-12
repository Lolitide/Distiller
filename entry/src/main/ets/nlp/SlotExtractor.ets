/**
 * T2 槽位抽取：动作 / 地点 / 人物 / 截止。
 *
 * **找不到就留空，绝不猜**。宁可卡片少一行，也不要出现「编了个地点」。
 */

import { parseTime, Ymd } from './TimeParser';
import { replaceAllLiteral, stripChars } from './TextUtil';

const VENUE_RE: RegExp =
  /((?:教学楼|教室|图书馆|食堂|宿舍|操场|体育馆|会议室|实验室|报告厅|大礼堂|活动中心|食堂|超市|火车站|机场|医院|梧桐苑|\d+号楼|[\u4e00-\u9fa5]{2,3}楼|[\u4e00-\u9fa5]{2,3}馆|[\u4e00-\u9fa5]{2,3}苑))/;

const PERSON_RE: RegExp = /([\u4e00-\u9fa5]{2,4})(老师|同学|学长|学姐|导员|主任|班长|教授)/;

const WHO_RE: RegExp = /(全体|所有人|大家|各班|班委|组长|负责人)/;

/** 通知类文案的客套尾巴，抽完字段后要剪掉 */
const TAIL_NOISE: string[] = ['可以参加', '有兴趣的同学', '有兴趣的可以', '大家', '同学们',
  '可以看看', '注意一下', '有兴趣'];

/** 句首语气词 */
const LEAD_FILLER: string[] = ['记得', '别忘了', '别忘', '要', '需要', '请', '麻烦', '应该', '可以',
  '一下', '尽快', '务必', '注意', '大家', '同学们', '我们', '我'];

/**
 * 把时间表达与已抽出的地点从原文里抠掉，剩下的就是「要做的事」。
 * 不这么做的话，会出现「来教学楼上课；地点：教学楼」这种重复。
 */
export function removeTimeAndPlace(text: string, place: string): string {
  let out: string = text;
  out = out.replace(/(\d{4})[-/年](\d{1,2})[-/月](\d{1,2})[日号]?/g, '');
  out = out.replace(/(\d{1,2})[月/](\d{1,2})[日号]?/g, '');
  out = out.replace(/今天|明天|后天|大后天|今晚|明晚|今早/g, '');
  out = out.replace(/(下{0,2})(?:周|星期|礼拜)[一二三四五六日天]/g, '');
  out = out.replace(/(上午|早上|中午|下午|晚上|傍晚)?\s*\d{1,2}[:：点](\d{1,2})?(半)?/g, '');
  if (place.length > 0) {
    out = replaceAllLiteral(out, place, '');
  }
  return out;
}

export function cleanAction(s: string): string {
  let out: string = s;
  for (let i = 0; i < TAIL_NOISE.length; i++) {
    out = replaceAllLiteral(out, TAIL_NOISE[i], '');
  }
  out = out.replace(/[，,。.、；;]{2,}/g, '，');
  out = out.replace(/\s+/g, '');
  for (let k = 0; k < 3; k++) {
    const before: string = out;
    out = out.replace(/[，,。.、；;]?\s*(可以)?(参加|参与|报名参加|看看|了解一下)$/g, '');
    if (out === before) {
      break;
    }
  }
  return stripChars(out, ' ，,。.、！!～~）)');
}

export function stripFiller(s: string): string {
  let out: string = s;
  for (let i = 0; i < LEAD_FILLER.length; i++) {
    out = replaceAllLiteral(out, LEAD_FILLER[i], '');
  }
  return stripChars(out, ' ，,。.、！!～~');
}

export interface EventSlots {
  action: string;
  place: string;
  who: string;
  deadline: string;
}

/** 抽取 动作 / 地点 / 人物 / 截止；找不到就是空串。 */
export function extractSlots(text: string, kind: string, base: Ymd): EventSlots {
  const t: string = text;

  let place: string = '';
  const vm: RegExpExecArray | null = VENUE_RE.exec(t);
  if (vm !== null) {
    // 剪掉紧跟前面的方位/趋向动词（「记得来教学楼」->「教学楼」）
    place = vm[1].replace(/^[来到去在往上下的了]/, '');
  }

  let who: string = '';
  const pm: RegExpExecArray | null = PERSON_RE.exec(t);
  if (pm !== null) {
    who = pm[0];
  } else {
    const wm: RegExpExecArray | null = WHO_RE.exec(t);
    if (wm !== null) {
      who = wm[1];
    }
  }

  let action: string = removeTimeAndPlace(t, place);
  if (who.length > 0) {
    action = replaceAllLiteral(action, who, '');
  }
  action = stripFiller(action);
  action = cleanAction(action);
  // 动作开头的趋向动词去掉（「来上课」->「上课」）
  action = action.replace(/^[来到去往]/, '');
  action = action.replace(/[，,。.、]{2,}/g, '，');
  action = stripChars(action, ' ，,。.、！!～~）)');

  let deadline: string = '';
  const dm: RegExpExecArray | null =
    /(?:截止|ddl|DDL|deadline)[^\u4e00-\u9fa5]{0,4}([^\s，,。.；;]{1,16})/.exec(t);
  if (dm !== null) {
    deadline = dm[1];
  } else if (t.indexOf('之前') >= 0 || t.indexOf('以前') >= 0) {
    const slot = parseTime(t, base);
    if (slot !== null) {
      deadline = slot.text;
    }
  }

  return { action: action, place: place, who: who, deadline: deadline };
}
