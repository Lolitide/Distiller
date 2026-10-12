import { describe, it, expect } from '@ohos/hypium';
import { buildKeyFields, buildSummary, classifyCategory, entityTypeLabel, normalizeText } from '../main/ets/common/ParseRules';
import { ParsedEntity } from '../main/ets/common/Types';

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

    it('classify_noun_boost_keeps_result', 0, () => {
      expect(classifyCategory('周五前交实验报告', ['实验'])).assertEqual('教务');
    });

    it('summary_first_sentence', 0, () => {
      expect(buildSummary('周五前交实验报告。地点三教301', 24)).assertEqual('周五前交实验报告');
    });

    it('summary_truncate', 0, () => {
      const s: string = buildSummary('这是一条非常长的通知内容需要被截断处理', 10);
      expect(s.length).assertEqual(11);
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
}
