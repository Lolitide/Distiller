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

/** 子步骤（副卡片每个 Step 前面的圆圈读 `done`）。见《任务字段表》#25。 */
export interface CandidateStep {
  content: string;
  /** 0 未完成 / 1 完成 */
  done: number;
}

/** 重要性：0 普通（不显示标识）/ 1 重要（红圈+感叹号）/ 2 紧急（红实心+白感叹号） */
export const PRIORITY_NONE: number = 0;
export const PRIORITY_IMPORTANT: number = 1;
export const PRIORITY_URGENT: number = 2;

/** 难度：0 易 / 1 中 / 2 难（只参与排序，卡片不显示） */
export const LEVEL_EASY: number = 0;
export const LEVEL_MEDIUM: number = 1;
export const LEVEL_HARD: number = 2;

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
  /** 需带物品 / 关键注意事项（每条都是原文里逐字出现的短句；端侧规则不产出，通常为空） */
  items: string[];
  /** 0~1，低于阈值前端要标「待确认」 */
  confidence: number;
  /** **必须保留**：卡片要能回到原话 */
  sourceText: string;
  sender: string;
  timestamp: string;
  msgId: string;
  tags: string[];

  // ---- 卡片字段（《任务字段表&idea更新》v1）----------------------------
  // 全部**可选**：端侧规则（EventBuilder）不产这些，只有后端解析才有。
  // 用户在本机改过的值会写回这里并落库（随 `RobotMessage.event` 一起）。

  /** 0 普通 / 1 重要 / 2 紧急 —— 卡片上那个红圈就是它 */
  priority?: number;
  /** 0 易 / 1 中 / 2 难 —— 只参与排序 */
  level?: number;
  /** 截止时刻（毫秒）；0/未定义 = 没有截止 */
  dueAt?: number;
  /** 重复周期：none / day / week / month / year / workingDay */
  repeat?: string;
  /** 重复周期的原话（如「每周一三五」），与 repeat 是两件事 */
  repeatText?: string;
  /** 子步骤；非空才显示副卡片 */
  steps?: CandidateStep[];
  /** 后端置信度 ×100 的整数（0~100） */
  certainty?: number;
  /** 缺失字段名（place / who / dueAt），确认态高亮用 */
  missingFields?: string[];
  /** 来源通道：bot / manual / paste / share / voice */
  channel?: string;
  /** 类型：作业 / 考试 / 活动 / 通知 / 其他（可自定义） */
  category?: string;
}

/** 该类型是否值得做成结构化卡片（闲聊/忽略不做）。 */
export function isActionable(kind: string): boolean {
  return kind === EVENT_TODO || kind === EVENT_NOTICE || kind === EVENT_PLAN
    || kind === EVENT_ACTIVITY;
}
