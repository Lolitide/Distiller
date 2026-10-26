/**
 * service/ai —— AI 能力子域
 *
 * 已落地成员（见 docs/开发指南.md §9.1）：
 *   TextExtractService  实体与时间抽取（Natural Language Kit）—— 端侧兜底，抽「时间 + 地点」
 *   OcrService          图片文字识别（Core Vision Kit）
 *   SpeechService       语音转文字（Core Speech Kit）
 *
 * 纪律：这三项能力都不支持模拟器或需要真机，且模拟器上静态 import 会让应用直接闪退，
 * 所以对它们的引用一律走动态引入（import()），不要在这里做顶层 import。
 * 页面不直接引用本目录下的实现文件，只引用本桶文件。
 */
export { OcrService } from './OcrService';
export { SpeechCallbacks, SpeechService } from './SpeechService';
export { LocalTimeHint, TextExtractResult, TextExtractService } from './TextExtractService';
