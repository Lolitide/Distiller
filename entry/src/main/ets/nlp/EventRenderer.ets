/**
 * T2 模板成句：输出 = 模板 × 槽位。
 *
 * 原则：**措辞全部来自原话，语序来自模板**，所以不会出现「AI 编了一句话」。
 * 代价是字段少的时候句子短 —— 对提醒类应用这是可接受的取舍。
 */

import { CampusEvent, EVENT_CHAT, EVENT_IGNORE, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from './EventTypes';
import { cleanAction, removeTimeAndPlace, stripFiller } from './SlotExtractor';
import { timeSlotDisplay } from './TimeParser';
import { replaceAllLiteral, stripChars } from './TextUtil';

/** 由槽位拼出的一句话（不是模型生成的）。 */
export function renderOneLine(ev: CampusEvent): string {
  if (ev.kind === EVENT_IGNORE || ev.kind === EVENT_CHAT) {
    return '';
  }

  // 先把已经单独成字段的时间串和地点从「动作文本」里抠掉，否则会重复
  let residual: string = removeTimeAndPlace(ev.sourceText, ev.place);
  if (ev.who.length > 0) {
    residual = replaceAllLiteral(residual, ev.who, '');
  }
  residual = stripFiller(residual);
  residual = cleanAction(residual);
  residual = residual.replace(/\s+/g, '');
  residual = stripChars(residual, ' ，,。.、！!～~）)(（');

  const body: string = residual.length > 0 ? residual : ev.action;

  let line: string = body;
  if (ev.kind === EVENT_PLAN) {
    line = '计划' + body;
    if (ev.place.length > 0) {
      line = line + '；途经/目的地：' + ev.place;
    }
  } else if (ev.kind === EVENT_NOTICE) {
    line = '通知：' + body;
  }

  const parts: string[] = [line];
  if (ev.time !== null) {
    parts.push('时间：' + timeSlotDisplay(ev.time));
  }
  if (ev.place.length > 0 && ev.kind !== EVENT_PLAN) {
    parts.push('地点：' + ev.place);
  }
  if (ev.who.length > 0 && ev.kind === EVENT_TODO) {
    parts.push('对象：' + ev.who);
  }
  if (ev.deadline.length > 0) {
    parts.push('截止：' + ev.deadline);
  }

  let out: string = '';
  for (let i = 0; i < parts.length; i++) {
    const p: string = parts[i];
    if (p.length > 0 && stripChars(p, '；').length > 0) {
      out = out.length === 0 ? p : out + '；' + p;
    }
  }
  if (ev.confidence < 0.5) {
    out = out + '（字段不完整，建议人工确认）';
  }
  return out;
}
