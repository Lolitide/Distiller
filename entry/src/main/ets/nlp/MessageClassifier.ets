/**
 * T1 分级过滤：噪声 / 闲聊 / 待办 / 通知 / 出行计划。
 *
 * 这一步是整个链路里收益最大的过滤 —— 绝大多数群消息（数字、表情、寒暄）
 * 在这里就被判为 ignore/闲聊，根本不进后续的槽位抽取。
 *
 * 刻意保守：**宁可漏判成闲聊，也不要误判成待办**。
 * 一条假提醒比漏掉一条更伤信任。
 */

import { isNoise } from './MessageNormalizer';
import { EVENT_CHAT, EVENT_IGNORE, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from './EventTypes';
import { anyIn } from './TextUtil';

/** 行为动作触发词（用于"事件性"判断，也用于砍掉语气词） */
export const ACTION_HINTS: string[] = ['记得', '别忘', '要', '需要', '请', '交', '提交', '报名',
  '参加', '开会', '上课', '考试', '买', '去', '来', '做', '完成', '准备', '截止', 'ddl', 'DDL'];

const NOTICE_HINTS: string[] = ['通知', '报名', '截止', '开始', '启动', '比赛', '大赛', '活动',
  '招聘', '开放', '申请', '公布'];

const PLAN_HINTS: string[] = ['去', '到', '出发', '坐车', '坐火车', '坐飞机', '旅游', '出差', '回'];

/** 有这些词才值得进「待办」 */
const TASK_MARKERS: string[] = ['记得', '别忘了', '别忘', '要', '需要', '请', '务必', '尽快',
  '截止', 'ddl', 'DDL', '交', '提交', '报名', '参加', '考试', '开会', '上课', '完成', '准备', '买', '做'];

/** 出现这些闲聊信号，即使有任务词也降级为闲聊 */
const CHAT_MARKERS: string[] = ['那我', '干脆', '得了', '哈哈', '呵呵', 'hh', '感觉', '好像',
  '是不是', '吗', '呢', '咋', '啥', '你们', '了没', '有没有'];

/** 粗分类。顺序很重要：先排除噪声与闲聊，再判断出行/通知/待办。 */
export function classify(text: string): string {
  const t: string = text.trim();
  if (isNoise(t)) {
    return EVENT_IGNORE;
  }

  const hasChat: boolean = anyIn(t, CHAT_MARKERS);
  // 疑问句基本不是待办（「几点停电」「你们参加了吗」）
  const isQuestion: boolean = /(吗|呢|\?|？|几点|什么时候|怎么|为什么)$/.test(t);
  const strongTask: boolean = /(记得|别忘|需要|请|务必|尽快|截止|ddl|DDL)/.test(t);

  if (isQuestion && !strongTask) {
    return EVENT_CHAT;
  }
  if (hasChat && !strongTask) {
    return EVENT_CHAT;
  }

  // 出行意图优先：这类句子往往没有任务词，但信息量高（时间 + 目的地 + 交通）
  if (anyIn(t, PLAN_HINTS) && /(旅游|出差|出发|坐车|坐火车|坐飞机|回家|返校)/.test(t)) {
    return EVENT_PLAN;
  }

  if (anyIn(t, NOTICE_HINTS)) {
    return EVENT_NOTICE;
  }
  if (strongTask || anyIn(t, TASK_MARKERS)) {
    return EVENT_TODO;
  }
  return EVENT_CHAT;
}
