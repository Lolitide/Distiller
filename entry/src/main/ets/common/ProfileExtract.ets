/**
 * 知了 · 用户画像素材提取（端侧规则，**全程不出端侧**）
 *
 * 职责：把「我自己发过的消息」与「我自己的操作」统计成一张**词频表**——
 * 每条只有「类别 + 词 + 次数」，**绝不包含任何聊天原话**。
 * 这张表就是唯一会被发到后端的画像素材（后端只做无状态归纳，见 `profile_summarize.py`）。
 *
 * 为什么用规则而不是把消息原文丢给模型：
 *   1. 隐私——原文不出端侧，"不存用户任何信息"的红线才守得住；
 *   2. 与 `group_lexicon`（按群词表）同一套口径：**只允许「词 + 次数 + 类别」**；
 *   3. 确定性——同一批消息永远得到同一张表，可复现、可测试。
 *
 * 词从三处来（都落在「词」这一层，不产句子）：
 *   · 自己消息正文里的**地点/身份/关注点/作息**模式（见下面的词表与后缀扫描）；
 *   · 消息已经被解析出的 `event`（`place` / `tags`）——复用已有管道，比自己再抽一遍准；
 *   · 自己的**操作**（忽略过哪一类）——只统计动作，不猜原因。
 */

import { RobotMessage, ProfileMaterial, ProfileTerm, ProfileCounters } from './Types';
import { isActionable } from '../nlp/EventTypes';

/** 地点后缀：命中后取其前 2 个汉字一起当地名（`康桥` + `苑` = `康桥苑`）。 */
const PLACE_SUFFIX: string[] = [
  '苑', '校区', '门口', '食堂', '广场', '公寓', '操场', '超市', '餐厅', '教学楼', '馆', '楼',
];

/** 身份后缀 / 身份词 */
const ROLE_SUFFIX: string[] = ['书院', '学院', '专业', '系', '班', '届'];
const ROLE_WORDS: string[] = [
  '大一', '大二', '大三', '大四', '研一', '研二', '研三', '博士', '硕士', '本科生', '研究生',
];

/** 关注点词表（出现即计数；词本身就是词条，不做上位归纳） */
const INTEREST_WORDS: string[] = [
  '竞赛', '比赛', '传智杯', '蓝桥杯', '考研', '保研', '实习', '招聘', '校招', '社团',
  '选课', '四六级', '托福', '雅思', '球赛', '志愿', '入党', '奖学金', '论文', '组会',
  '实验', '考试', '答辩', '军训', '迎新', '竞选',
];

/** 作息词表 */
const SCHEDULE_WORDS: string[] = [
  '早上', '上午', '中午', '下午', '晚上', '凌晨', '半夜', '今晚', '明早', '周末',
];

/** 交给后端的词条上限（后端还会按其 `MAX_VOCAB` 再截一次） */
const MAX_TERMS: number = 60;
/** 地点/身份前缀取几个汉字 */
const PREFIX_LEN: number = 2;
/** 同一类被忽略多少次才算一条"偏好"证据 */
const PREF_MIN_DISMISS: number = 3;

interface TermCounter {
  kind: string;
  term: string;
  count: number;
}

function isCjk(ch: string): boolean {
  const code: number = ch.charCodeAt(0);
  return code >= 0x4e00 && code <= 0x9fff;
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}

/** 取 `at` 之前连续的汉字，最多 `maxLen` 个。 */
function cjkPrefix(text: string, at: number, maxLen: number): string {
  let out: string = '';
  for (let i = at - 1; i >= 0 && out.length < maxLen; i--) {
    const ch: string = text.charAt(i);
    if (!isCjk(ch)) {
      break;
    }
    out = ch + out;
  }
  return out;
}

/** 统计 `kw` 在 `text` 里出现的次数（不重叠）。 */
function countOccur(text: string, kw: string): number {
  if (kw.length === 0 || text.length === 0) {
    return 0;
  }
  let n: number = 0;
  let from: number = 0;
  while (true) {
    const at: number = text.indexOf(kw, from);
    if (at < 0) {
      break;
    }
    n++;
    from = at + kw.length;
  }
  return n;
}

function addTerm(map: Map<string, TermCounter>, kind: string, term: string, inc: number): void {
  const t: string = term.trim();
  if (t.length === 0 || inc <= 0) {
    return;
  }
  const cur: TermCounter | undefined = map.get(t);
  if (cur === undefined) {
    const fresh: TermCounter = { kind: kind, term: t, count: inc };
    map.set(t, fresh);
    return;
  }
  cur.count += inc; // 同一个词被两种类别命中时，保留先到的类别
}

export class ProfileExtract {
  /** 扫正文：地点（后缀扫描）、身份（后缀 + 词表）、关注点/作息（词表计数）。 */
  private static scanText(map: Map<string, TermCounter>, text: string): void {
    if (text.length === 0) {
      return;
    }
    ProfileExtract.scanSuffix(map, text, PLACE_SUFFIX, 'place');
    ProfileExtract.scanSuffix(map, text, ROLE_SUFFIX, 'role');
    for (let i = 0; i < ROLE_WORDS.length; i++) {
      const n: number = countOccur(text, ROLE_WORDS[i]);
      if (n > 0) {
        addTerm(map, 'role', ROLE_WORDS[i], n);
      }
    }
    for (let i = 0; i < INTEREST_WORDS.length; i++) {
      const n: number = countOccur(text, INTEREST_WORDS[i]);
      if (n > 0) {
        addTerm(map, 'interest', INTEREST_WORDS[i], n);
      }
    }
    for (let i = 0; i < SCHEDULE_WORDS.length; i++) {
      const n: number = countOccur(text, SCHEDULE_WORDS[i]);
      if (n > 0) {
        addTerm(map, 'schedule', SCHEDULE_WORDS[i], n);
      }
    }
  }

  /**
   * 后缀扫描：`苑|食堂|书院…` 前面的 2 个汉字就是名字。
   *
   * 前缀必须**正好** `PREFIX_LEN` 个汉字，否则丢弃——「…的食堂」这种前置词
   * 会污染词表（这是按群词表踩过的坑，这里用同一条规矩挡掉）。
   */
  private static scanSuffix(map: Map<string, TermCounter>, text: string, suffixes: string[],
    kind: string): void {
    for (let s = 0; s < suffixes.length; s++) {
      const suf: string = suffixes[s];
      let from: number = 0;
      while (true) {
        const at: number = text.indexOf(suf, from);
        if (at < 0) {
          break;
        }
        from = at + suf.length;
        const pre: string = cjkPrefix(text, at, PREFIX_LEN);
        if (pre.length !== PREFIX_LEN) {
          continue;
        }
        addTerm(map, kind, pre + suf, 1);
      }
    }
  }

  /** 最活跃时段（三小时窗口）；算不出返回空串。 */
  private static activeHours(list: RobotMessage[]): string {
    const buckets: number[] = [];
    for (let h = 0; h < 24; h++) {
      buckets.push(0);
    }
    let total: number = 0;
    for (let i = 0; i < list.length; i++) {
      const ts: string = list[i].timestamp;
      if (ts.length < 13) {
        continue;
      }
      const h: number = Number(ts.substring(11, 13));
      if (Number.isNaN(h) || h < 0 || h > 23) {
        continue;
      }
      buckets[h] = buckets[h] + 1;
      total++;
    }
    if (total === 0) {
      return '';
    }
    let best: number = -1;
    let bestN: number = 0;
    for (let h = 0; h < 24; h++) {
      if (buckets[h] > bestN) {
        bestN = buckets[h];
        best = h;
      }
    }
    if (best < 0) {
      return '';
    }
    const from: number = best > 0 ? best - 1 : 0;
    const to: number = best < 23 ? best + 1 : 23;
    return pad2(from) + ':00-' + pad2(to + 1) + ':00';
  }

  /**
   * 排序 + 去污染 + 截断。
   *
   * 去污染：某个词是**已保留词**的子串、且计数不更高时丢弃
   * （`我们仲英` 被 `仲英书院` 吸收）。与按群词表同一条规矩。
   */
  private static rankTerms(map: Map<string, TermCounter>, cap: number): ProfileTerm[] {
    const arr: TermCounter[] = [];
    map.forEach((v: TermCounter) => {
      arr.push(v);
    });
    arr.sort((a: TermCounter, b: TermCounter): number => {
      if (b.count !== a.count) {
        return b.count - a.count;
      }
      return b.term.length - a.term.length;
    });
    const out: ProfileTerm[] = [];
    for (let i = 0; i < arr.length; i++) {
      if (out.length >= cap) {
        break;
      }
      let absorbed: boolean = false;
      for (let j = 0; j < out.length; j++) {
        if (out[j].term.indexOf(arr[i].term) >= 0 && out[j].count >= arr[i].count) {
          absorbed = true;
          break;
        }
      }
      if (absorbed) {
        continue;
      }
      const t: ProfileTerm = { kind: arr[i].kind, term: arr[i].term, count: arr[i].count };
      out.push(t);
    }
    return out;
  }

  /**
   * 从本机消息里抽出画像素材。
   *
   * 只吃 `is_self === true` 的消息（服务端据 `sender_openid` 判定，
   * 见 `relay.py` 的 `window_since`）——别人的话不进画像。
   */
  static material(list: RobotMessage[]): ProfileMaterial {
    const map: Map<string, TermCounter> = new Map<string, TermCounter>();
    const dismissedByKind: Map<string, number> = new Map<string, number>();
    const mine: RobotMessage[] = [];
    let todoCount: number = 0;
    let dismissCount: number = 0;

    for (let i = 0; i < list.length; i++) {
      const m: RobotMessage = list[i];
      if (m.is_self !== true) {
        continue;
      }
      mine.push(m);
      ProfileExtract.scanText(map, m.content);

      const ev = m.event;
      if (ev !== undefined) {
        // 复用已解析出的事件：地点与标签比自己再抽一遍准
        if (ev.place.length > 0) {
          addTerm(map, 'place', ev.place, 1);
        }
        for (let t = 0; t < ev.tags.length; t++) {
          addTerm(map, 'interest', ev.tags[t], 1);
        }
        if (isActionable(ev.kind)) {
          todoCount++;
        }
      }
      if (m.dismissed === true) {
        dismissCount++;
        if (ev !== undefined && ev.kind.length > 0) {
          dismissedByKind.set(ev.kind, (dismissedByKind.get(ev.kind) ?? 0) + 1);
        }
      }
    }

    // 偏好：只统计"我确实忽略过"的动作，不猜原因（措辞也只陈述事实）
    let topKind: string = '';
    let topKindN: number = 0;
    dismissedByKind.forEach((n: number, kind: string) => {
      if (n > topKindN) {
        topKindN = n;
        topKind = kind;
      }
    });
    if (topKindN >= PREF_MIN_DISMISS) {
      addTerm(map, 'preference', topKind + '类常被忽略', topKindN);
    }

    const counters: ProfileCounters = {
      selfMsgs: mine.length,
      todoCount: todoCount,
      dismissCount: dismissCount,
      activeHours: ProfileExtract.activeHours(mine)
    };
    return { terms: ProfileExtract.rankTerms(map, MAX_TERMS), counters: counters };
  }
}
