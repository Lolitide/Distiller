/**
 * T3 事件聚合：把零散对话收成「一个事件」，这样才读得懂。
 *
 * 规则（简单、可解释、端侧秒级可算）：
 *   1. 只聚合非噪声事件；
 *   2. 必须**共享标签或关键词**且在 gapMinutes 内 → 同一簇。
 *      刻意不用「同一发送者」当条件：同一个人连发几句无关的话，
 *      不该被拼成一个事件；
 *   3. 每条闲聊只在**有共同关键词**时才并簇（否则水群会被拼成一个"事件"）；
 *   4. 每簇取信息量最大的一条当代表。
 */

import { CampusEvent, EVENT_CHAT, EVENT_IGNORE, isActionable } from './EventTypes';
import { tsToMillis } from './TimeParser';
import { eventOneLine } from './EventBuilder';

export interface EventCluster {
  title: string;
  oneLine: string;
  kind: string;
  count: number;
  spanStart: string;
  spanEnd: string;
  senders: string[];
  tags: string[];
  confidence: number;
}

const STOPWORDS: string = '的了是在有和就不都一个上也很到说要去你会着没有看好自己这我们他们可以什么怎么这个那个';

function hasStopChar(g: string): boolean {
  for (let i = 0; i < g.length; i++) {
    if (STOPWORDS.indexOf(g.charAt(i)) >= 0) {
      return true;
    }
  }
  return false;
}

/** 汇总展示用的筛选 + 排序：丢掉单条闲聊，待办/通知/出行计划优先。 */
export function pickDigestClusters(clusters: EventCluster[]): EventCluster[] {
  const picked: EventCluster[] = [];
  for (let i = 0; i < clusters.length; i++) {
    const c: EventCluster = clusters[i];
    // 单条闲聊不算「事件」，不进汇总
    if (c.kind === EVENT_CHAT && c.count < 2) {
      continue;
    }
    picked.push(c);
  }
  picked.sort((a: EventCluster, b: EventCluster): number => {
    const pa: number = isActionable(a.kind) ? 0 : 1;
    const pb: number = isActionable(b.kind) ? 0 : 1;
    if (pa !== pb) {
      return pa - pb;
    }
    if (a.count !== b.count) {
      return b.count - a.count;
    }
    return b.confidence - a.confidence;
  });
  return picked;
}

/** 极简关键词：中文按 2-4 字滑窗 + 去停用词。端侧不需要分词库也能用。 */
export function keywordsOf(text: string, top: number = 4): string[] {
  const cleaned: string = text.replace(/\[[^\]]*\]|@某人|\[链接\]|[^\u4e00-\u9fa5A-Za-z0-9]/g, '');
  const counts: Map<string, number> = new Map<string, number>();
  const sizes: number[] = [2, 3, 4];
  for (let s = 0; s < sizes.length; s++) {
    const n: number = sizes[s];
    for (let i = 0; i + n <= cleaned.length; i++) {
      const g: string = cleaned.substring(i, i + n);
      if (hasStopChar(g)) {
        continue;
      }
      counts.set(g, (counts.get(g) ?? 0) + 1);
    }
  }
  const grams: string[] = [];
  counts.forEach((value: number, key: string) => {
    grams.push(key);
  });
  grams.sort((a: string, b: string): number => {
    const ca: number = counts.get(a) ?? 0;
    const cb: number = counts.get(b) ?? 0;
    if (ca !== cb) {
      return cb - ca;
    }
    return b.length - a.length;
  });
  return grams.slice(0, top);
}

function intersects(a: string[], b: string[]): boolean {
  for (let i = 0; i < a.length; i++) {
    if (b.indexOf(a[i]) >= 0) {
      return true;
    }
  }
  return false;
}

/** 同义归并：把不同说法归到同一个「概念」，解决「换个说法就聚不上」的问题。 */
const SYNONYM_GROUPS: string[][] = [
  ['停电', '断电', '跳闸', '没电', '来电'],
  ['作业', '实验报告', '报告', '大作业'],
  ['考试', '测验', '期中考试', '期末考试', '补考'],
  ['报名', '报名表', '填报'],
  ['会议', '开会', '例会', '班会'],
  ['讲座', '分享会', '沙龙', '论坛'],
  ['招聘', '校招', '宣讲会', '宣讲', '实习'],
  ['火车', '高铁', '动车', '车站'],
  ['比赛', '竞赛', '大赛', '挑战赛']
];

/** 取文本里出现的「概念」（同义组归并后的代表词）。 */
export function conceptsOf(text: string): string[] {
  const out: string[] = [];
  for (let g = 0; g < SYNONYM_GROUPS.length; g++) {
    const group: string[] = SYNONYM_GROUPS[g];
    for (let w = 0; w < group.length; w++) {
      if (text.indexOf(group[w]) >= 0) {
        if (out.indexOf(group[0]) < 0) {
          out.push(group[0]);
        }
        break;
      }
    }
  }
  return out;
}

function mergeUnique(base: string[], extra: string[]): string[] {
  const out: string[] = [];
  for (let i = 0; i < base.length; i++) {
    if (out.indexOf(base[i]) < 0) {
      out.push(base[i]);
    }
  }
  for (let i = 0; i < extra.length; i++) {
    if (out.indexOf(extra[i]) < 0) {
      out.push(extra[i]);
    }
  }
  return out;
}

interface WorkingCluster {
  events: CampusEvent[];
  senders: string[];
  lastTs: string;
  tags: string[];
  keywords: string[];
  concepts: string[];
  kind: string;
}

/** 把事件列表聚成若干「事件簇」。 */
export function clusterEvents(events: CampusEvent[], gapMinutes: number = 30): EventCluster[] {
  const items: CampusEvent[] = [];
  for (let i = 0; i < events.length; i++) {
    const e: CampusEvent = events[i];
    if (e.kind !== EVENT_IGNORE && e.sourceText.length > 0) {
      items.push(e);
    }
  }
  items.sort((a: CampusEvent, b: CampusEvent): number => tsToMillis(a.timestamp) - tsToMillis(b.timestamp));

  const work: WorkingCluster[] = [];
  for (let i = 0; i < items.length; i++) {
    const ev: CampusEvent = items[i];
    const t: number = tsToMillis(ev.timestamp);
    const kw: string[] = keywordsOf(ev.sourceText);
    const concepts: string[] = conceptsOf(ev.sourceText);
    let placed: boolean = false;
    for (let c = 0; c < work.length; c++) {
      const cl: WorkingCluster = work[c];
      const last: number = tsToMillis(cl.lastTs);
      const shareTag: boolean = intersects(cl.tags, ev.tags);
      const shareKw: boolean = intersects(cl.keywords, kw);
      // 同义归并后的概念相同也算「同一件事」（换个说法也能聚上）
      const shareConcept: boolean = intersects(cl.concepts, concepts);
      // 只有「共享标签/关键词/概念」才算同一件事。
      // 刻意不用「同一类型」当条件：那会让 30 分钟内所有同类型消息被拼成一坨。
      if ((t - last) <= gapMinutes * 60000 && (shareTag || shareKw || shareConcept)) {
        cl.events.push(ev);
        cl.senders.push(ev.sender);
        cl.lastTs = ev.timestamp;
        cl.tags = mergeUnique(cl.tags, ev.tags);
        cl.keywords = mergeUnique(cl.keywords, kw);
        cl.concepts = mergeUnique(cl.concepts, concepts);
        placed = true;
        break;
      }
    }
    if (!placed) {
      work.push({
        events: [ev],
        senders: [ev.sender],
        lastTs: ev.timestamp,
        tags: ev.tags.slice(0),
        keywords: kw,
        concepts: concepts,
        kind: ev.kind
      });
    }
  }

  const out: EventCluster[] = [];
  for (let c = 0; c < work.length; c++) {
    const cl: WorkingCluster = work[c];
    let best: CampusEvent = cl.events[0];
    for (let k = 0; k < cl.events.length; k++) {
      const e: CampusEvent = cl.events[k];
      if (e.confidence > best.confidence
        || (e.confidence === best.confidence && e.sourceText.length > best.sourceText.length)) {
        best = e;
      }
    }
    out.push({
      title: best.title,
      oneLine: eventOneLine(best),
      kind: best.kind,
      count: cl.events.length,
      spanStart: cl.events[0].timestamp,
      spanEnd: cl.lastTs,
      senders: mergeUnique([], cl.senders),
      tags: cl.tags,
      confidence: best.confidence
    });
  }
  return out;
}
