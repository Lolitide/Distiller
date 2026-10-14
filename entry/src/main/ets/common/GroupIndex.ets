/**
 * 群维度聚合：把已落库的消息按群分组，供「群聊」页做卡片列表与详情页筛选。
 * 纯函数，不依赖 UI，方便单测。
 */
import { RobotMessage } from './Types';
import { isActionable } from '../nlp/EventTypes';

/** 群卡片：一个群的概况 */
export interface GroupCard {
  openid: string;
  label: string;
  /** 该群「事项」条数（待办/通知/活动/出行计划，来自 event.kind） */
  todo: number;
  /** 该群消息总条数 */
  total: number;
  /** 群内最近一条消息时间 */
  lastTime: string;
}

/** 群详情页的路由参数 */
export interface GroupParams {
  openid: string;
}

function indexOfGroup(cards: GroupCard[], openid: string): number {
  for (let i = 0; i < cards.length; i++) {
    if (cards[i].openid === openid) {
      return i;
    }
  }
  return -1;
}

/** 按群聚合出卡片列表：有事项的在前，其次按最近活跃排序。 */
export function buildGroupCards(msgs: RobotMessage[]): GroupCard[] {
  const cards: GroupCard[] = [];
  for (let i = 0; i < msgs.length; i++) {
    const m: RobotMessage = msgs[i];
    let hit: number = indexOfGroup(cards, m.group_openid);
    if (hit < 0) {
      const fresh: GroupCard = { openid: m.group_openid, label: m.group_label, todo: 0, total: 0, lastTime: '' };
      cards.push(fresh);
      hit = cards.length - 1;
    }
    const c: GroupCard = cards[hit];
    c.total = c.total + 1;
    const ev = m.event;
    if (ev !== undefined && isActionable(ev.kind)) {
      c.todo = c.todo + 1;
    }
    if (m.timestamp > c.lastTime) {
      c.lastTime = m.timestamp;
    }
  }
  cards.sort((a: GroupCard, b: GroupCard): number => {
    if (a.todo !== b.todo) {
      return b.todo - a.todo;
    }
    if (a.lastTime === b.lastTime) {
      return 0;
    }
    return a.lastTime < b.lastTime ? 1 : -1;
  });
  return cards;
}

/** 取某个群的消息（保持原顺序）。 */
export function messagesOfGroup(msgs: RobotMessage[], openid: string): RobotMessage[] {
  const out: RobotMessage[] = [];
  for (let i = 0; i < msgs.length; i++) {
    if (msgs[i].group_openid === openid) {
      out.push(msgs[i]);
    }
  }
  return out;
}

/** 取某个群的显示名（找不到就回退 openid）。 */
export function labelOfGroup(msgs: RobotMessage[], openid: string): string {
  for (let i = 0; i < msgs.length; i++) {
    if (msgs[i].group_openid === openid) {
      return msgs[i].group_label;
    }
  }
  return openid;
}
