export class Config {
  static baseUrl: string = 'http://192.168.1.104:8730';
  static healthPath: string = '/api/relay/health';
  static pollIntervalMs: number = 5000;
  static idlePollIntervalMs: number = 10000;
  static bindPollIntervalMs: number = 2000;
  static bindPollMaxTimes: number = 60;
  /** 附件落盘总占用上限（字节），超出按最旧优先淘汰（见 AttachmentStore） */
  static attachmentLimitBytes: number = 200 * 1024 * 1024;
}
