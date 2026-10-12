/**
 * 知了 · 消息解析规则（纯函数，不依赖任何 Kit，便于本地单测）
 *
 * 依据「知了调研.md」：Natural Language Kit 只能抽实体与词性，不能判断「这条消息要干什么」，
 * 因此事项判断（类别 + 摘要）由本地关键词规则完成，词性（wordTag）只作为加权参考。
 */

import { ParsedEntity } from './Types';

interface CategoryRule {
  category: string;
  keywords: string[];
}

interface TypeLabel {
  type: string;
  label: string;
}

/** 类别关键词表（类别取自「知了调研」用户画像：教务 / 活动 / 招聘 / 二手 / 闲聊） */
const CATEGORY_RULES: CategoryRule[] = [
  {
    category: '教务',
    keywords: ['作业', '实验报告', '报告', '考试', '补考', '重修', '选课', '课表', '论文', '答辩',
      '成绩', '学分', '教学', '学籍', '期末', '期中', '课堂', '课程', 'deadline', 'DDL']
  },
  {
    category: '活动',
    keywords: ['讲座', '报名', '活动', '比赛', '竞赛', '社团', '晚会', '沙龙', '分享会', '招新',
      '演出', '展览', '论坛', '训练营', '开放日']
  },
  {
    category: '招聘',
    keywords: ['招聘', '实习', '内推', '简历', '岗位', '面试', '校招', '求职', '宣讲', '兼职',
      '录用', 'offer', 'Offer']
  },
  {
    category: '二手',
    keywords: ['转让', '出售', '求购', '闲置', '二手', '出个', '低价', '甩卖', '代购', '收一个', '收个']
  }
];

const FALLBACK_CATEGORY: string = '闲聊';

/** 实体类型 -> 展示标签 */
const TYPE_LABELS: TypeLabel[] = [
  { type: 'datetime', label: '时间' },
  { type: 'location', label: '地点' },
  { type: 'name', label: '联系人' },
  { type: 'phoneNo', label: '电话' },
  { type: 'url', label: '链接' },
  { type: 'email', label: '邮箱' }
];

/** 把连续空白（含换行）压缩成单个空格，方便生成摘要。 */
export function normalizeText(text: string): string {
  let out: string = '';
  let prevSpace: boolean = false;
  for (let i = 0; i < text.length; i++) {
    const ch: string = text.charAt(i);
    const isSpace: boolean = ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r';
    if (isSpace) {
      if (!prevSpace && out.length > 0) {
        out += ' ';
      }
      prevSpace = true;
    } else {
      out += ch;
      prevSpace = false;
    }
  }
  return out.trim();
}

function isSentenceEnd(ch: string): boolean {
  return ch === '。' || ch === '！' || ch === '？' || ch === '!' || ch === '?';
}

/** 取首句摘要，超长截断。 */
export function buildSummary(content: string, maxLen: number): string {
  const text: string = normalizeText(content);
  if (text.length === 0) {
    return '';
  }
  let end: number = text.length;
  for (let i = 0; i < text.length; i++) {
    if (isSentenceEnd(text.charAt(i))) {
      end = i;
      break;
    }
  }
  let s: string = text.substring(0, end).trim();
  if (s.length === 0) {
    s = text;
  }
  if (s.length > maxLen) {
    s = s.substring(0, maxLen) + '…';
  }
  return s;
}

/** 实体类型对应的中文标签；未知类型返回空串。 */
export function entityTypeLabel(type: string): string {
  for (let i = 0; i < TYPE_LABELS.length; i++) {
    if (TYPE_LABELS[i].type === type) {
      return TYPE_LABELS[i].label;
    }
  }
  return '';
}

/**
 * 判定消息类别。
 * nounWords 为分词结果中词性为名词类的词，命中关键词且该词为名词时加权（词性参考）。
 * 零命中或并列时回落到「闲聊」。
 */
export function classifyCategory(content: string, nounWords: string[]): string {
  if (content.length === 0) {
    return FALLBACK_CATEGORY;
  }
  let best: string = FALLBACK_CATEGORY;
  let bestScore: number = 0;
  for (let i = 0; i < CATEGORY_RULES.length; i++) {
    const rule: CategoryRule = CATEGORY_RULES[i];
    let score: number = 0;
    for (let k = 0; k < rule.keywords.length; k++) {
      const kw: string = rule.keywords[k];
      if (content.indexOf(kw) >= 0) {
        score += nounWords.indexOf(kw) >= 0 ? 2 : 1;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      best = rule.category;
    }
  }
  return best;
}

/** 由实体生成列表页展示的关键字段行，如「时间 周五」「地点 三教301」。 */
export function buildKeyFields(entities: ParsedEntity[]): string[] {
  const out: string[] = [];
  for (let i = 0; i < entities.length; i++) {
    if (out.length >= 6) {
      break;
    }
    const e: ParsedEntity = entities[i];
    const label: string = entityTypeLabel(e.type);
    if (label.length === 0 || e.text.length === 0) {
      continue;
    }
    const item: string = label + ' ' + e.text;
    if (out.indexOf(item) < 0) {
      out.push(item);
    }
  }
  return out;
}
