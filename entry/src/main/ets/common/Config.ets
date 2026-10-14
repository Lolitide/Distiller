export class Config {
  static baseUrl: string = 'http://192.168.1.104:8730';
  static healthPath: string = '/api/relay/health';
  static pollIntervalMs: number = 5000;
  static idlePollIntervalMs: number = 10000;
  static bindPollIntervalMs: number = 2000;
  static bindPollMaxTimes: number = 60;
}
