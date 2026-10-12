/**
 * 事件类型（**封闭枚举**）与事件对象。
 *
 * 事件类型是固定几类，每种类型有自己的槽位表 —— 这样"种类少"不是缺点，
 * 而是可控、可测、无幻觉的接口。
 */

import { TimeSlot } from './TimeParser';

export const EVENT_TODO: string = '待办';
export const EVENT_NOTICE: string = '通知';
export const EVENT_ACTIVITY: string = '活动';
export const EVENT_PLAN: string = '出行计划';
export const EVENT_CHAT: string = '闲聊';
export const EVENT_IGNORE: string = '忽略';

/** 整理出来的「事件对象」：不是一句话，而是一组结构化字段。 */
export interface CampusEvent {
  /** 事件类型（封闭枚举） */
  kind: string;
  /** 标题：优先用原话里的关键短句 */
  title: string;
  /** 要做的事（原话里切出来的） */
  action: string;
  time: TimeSlot | null;
  place: string;
  who: string;
  deadline: string;
  /** 0~1，低于阈值前端要标「待确认」 */
  confidence: number;
  /** **必须保留**：卡片要能回到原话 */
  sourceText: string;
  sender: string;
  timestamp: string;
  msgId: string;
  tags: string[];
}

/** 该类型是否值得做成结构化卡片（闲聊/忽略不做）。 */
export function isActionable(kind: string): boolean {
  return kind === EVENT_TODO || kind === EVENT_NOTICE || kind === EVENT_PLAN
    || kind === EVENT_ACTIVITY;
}
