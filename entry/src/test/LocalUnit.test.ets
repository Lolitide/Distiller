import { describe, it, expect } from '@ohos/hypium';
import { buildKeyFields, buildSummary, classifyCategory, entityTypeLabel, normalizeText } from '../main/ets/common/ParseRules';
import { ParsedEntity } from '../main/ets/common/Types';
import { normalize } from '../main/ets/nlp/MessageNormalizer';
import { parseTime, TimeSlot, Ymd } from '../main/ets/nlp/TimeParser';
import { buildEvent, eventOneLine } from '../main/ets/nlp/EventBuilder';
import { CampusEvent, EVENT_CHAT, EVENT_IGNORE, EVENT_NOTICE, EVENT_PLAN, EVENT_TODO } from '../main/ets/nlp/EventTypes';

/** 与 pipeline_proto/test_pipeline.py 的 base 一致 */
const BASE: Ymd = { y: 2026, mo: 10, d: 12 };

export default function localUnitTest() {
  describe('parseRulesTest', () => {
    it('classify_edu', 0, () => {
      expect(classifyCategory('周五前交实验报告', [])).assertEqual('教务');
    });
    it('classify_activity', 0, () => {
      expect(classifyCategory('今晚有讲座，欢迎报名', [])).assertEqual('活动');
    });
    it('classify_job', 0, () => {
      expect(classifyCategory('急招前端实习生，可内推', [])).assertEqual('招聘');
    });
    it('classify_secondhand', 0, () => {
      expect(classifyCategory('出一本二手教材，价格好商量', [])).assertEqual('二手');
    });
    it('classify_fallback_chat', 0, () => {
      expect(classifyCategory('今天天气不错', [])).assertEqual('闲聊');
    });
    it('summary_first_sentence', 0, () => {
      expect(buildSummary('周五前交实验报告。地点三教301', 24)).assertEqual('周五前交实验报告');
    });
    it('normalize_whitespace', 0, () => {
      expect(normalizeText('a\n\n  b\tc')).assertEqual('a b c');
    });
    it('key_fields_skip_unknown', 0, () => {
      const entities: ParsedEntity[] = [
        { type: 'datetime', text: '周五' },
        { type: 'location', text: '三教301' },
        { type: 'unknown', text: 'x' }
      ];
      const kf: string[] = buildKeyFields(entities);
      expect(kf.length).assertEqual(2);
      expect(kf[0]).assertEqual('时间 周五');
      expect(kf[1]).assertEqual('地点 三教301');
    });
    it('entity_label', 0, () => {
      expect(entityTypeLabel('phoneNo')).assertEqual('电话');
      expect(entityTypeLabel('nope')).assertEqual('');
    });
  });

  // 对齐 pipeline_proto/test_pipeline.py 的 23 项断言
  describe('eventPipelineTest', () => {
    it('表情标记被解码', 0, () => {
      expect(normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+WTh+Whnl0ifQ==">')).assertEqual('[哇塞]');
    });
    it('另一个表情也能解', 0, () => {
      expect(normalize('<faceType=4,faceId="",ext="eyJ0ZXh0IjoiW+eVpeeVpeeVpV0ifQ==">')).assertEqual('[略略略]');
    });
    it('纯数字是噪声', 0, () => {
      expect(buildEvent('124124', '', '', '').kind).assertEqual(EVENT_IGNORE);
    });
    it('纯表情是噪声', 0, () => {
      expect(buildEvent('<faceType=6,faceId="0",ext="eyJ0ZXh0IjoiIn0=">', '', '', '').kind).assertEqual(EVENT_IGNORE);
    });
    it('ok 是噪声', 0, () => {
      expect(buildEvent('ok', '', '', '').kind).assertEqual(EVENT_IGNORE);
    });
    it('bb 是噪声', 0, () => {
      expect(buildEvent('bb', '', '', '').kind).assertEqual(EVENT_IGNORE);
    });

    it('今天上午9点 -> 当天', 0, () => {
      const s: TimeSlot | null = parseTime('今天上午9点记得来教学楼上课', BASE);
      expect(s !== null && s.normalized === '2026-10-12 09:00').assertTrue();
    });
    it('明天 -> 次日', 0, () => {
      const s: TimeSlot | null = parseTime('明天去超市买点吃的', BASE);
      expect(s !== null && s.normalized === '2026-10-13').assertTrue();
    });
    it('后天 -> 第三天', 0, () => {
      const s: TimeSlot | null = parseTime('后天先去火车站坐车', BASE);
      expect(s !== null && s.normalized === '2026-10-14').assertTrue();
    });
    it('下周三 -> 正确日期', 0, () => {
      const s: TimeSlot | null = parseTime('下周三交作业', BASE);
      expect(s !== null && s.normalized.indexOf('2026-10-21') === 0).assertTrue();
    });
    it('只写下周不猜日期', 0, () => {
      const s: TimeSlot | null = parseTime('下周交作业', BASE);
      expect(s !== null && s.unresolved && s.normalized === '').assertTrue();
    });
    it('没写时间就不给时间', 0, () => {
      expect(parseTime('去北京旅游', BASE)).assertNull();
    });

    it('记得上课 -> 待办 / 地点 / 成句', 0, () => {
      const e: CampusEvent = buildEvent('今天上午9点记得来教学楼上课', '硫酸Cu', '2026-10-12T19:53:42+08:00', 'm1', BASE);
      expect(e.kind).assertEqual(EVENT_TODO);
      expect(e.place).assertEqual('教学楼');
      const line: string = eventOneLine(e);
      expect(line.indexOf('2026-10-12 09:00') >= 0).assertTrue();
      expect(line.indexOf('教学楼') >= 0).assertTrue();
    });

    it('大赛报名 -> 通知 + 标签', 0, () => {
      const e: CampusEvent = buildEvent('最近大学生职业规划大赛报名，有兴趣的同学可以参加',
        '硫酸Cu', '2026-10-12T20:03:24+08:00', 'm2', BASE);
      expect(e.kind).assertEqual(EVENT_NOTICE);
      expect(e.tags.indexOf('竞赛') >= 0 || e.tags.indexOf('报名') >= 0).assertTrue();
    });

    it('坐车去旅游 -> 出行计划', 0, () => {
      const e: CampusEvent = buildEvent('后天先去火车站坐车，再去北京旅游',
        '硫酸Cu', '2026-10-12T19:54:33+08:00', 'm3', BASE);
      expect(e.kind).assertEqual(EVENT_PLAN);
    });

    it('疑问句 -> 闲聊且不成句', 0, () => {
      const e: CampusEvent = buildEvent('几点停电', '硫酸Cu', '2026-10-12T20:09:30+08:00', 'm4', BASE);
      expect(e.kind).assertEqual(EVENT_CHAT);
      expect(eventOneLine(e)).assertEqual('');
    });

    it('参加了吗 不被当成通知', 0, () => {
      const e: CampusEvent = buildEvent('最近那个比赛你们参加了吗',
        '硫酸Cu', '2026-10-12T20:08:54+08:00', 'm5', BASE);
      expect(e.kind).assertEqual(EVENT_CHAT);
    });

    it('每条事件都带原话', 0, () => {
      const e: CampusEvent = buildEvent('明天去超市买点吃的',
        '硫酸Cu', '2026-10-12T19:54:03+08:00', 'm6', BASE);
      expect(e.sourceText).assertEqual('明天去超市买点吃的');
    });

    it('低置信度会提示人工确认', 0, () => {
      const e: CampusEvent = buildEvent('明天去超市买点吃的',
        '硫酸Cu', '2026-10-12T19:54:03+08:00', 'm6', BASE);
      const line: string = eventOneLine(e);
      expect(line.indexOf('请人工确认') >= 0 || e.confidence >= 0.5).assertTrue();
    });
  });
}
