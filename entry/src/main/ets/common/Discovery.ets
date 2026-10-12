import { connection, http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Config } from './Config';
import { ApiResult, HealthData, parseApi } from './Types';

const DOMAIN: number = 0x0000;
const TAG: string = 'Discovery';
const HOST_MIN: number = 1;
const HOST_MAX: number = 254;
const BATCH_SIZE: number = 32;
const PROBE_TIMEOUT_MS: number = 800;

/**
 * 局域网自动发现：读取本机 Wi-Fi 所在网段，批量探测 Config.discoveryPort 端口上的
 * /api/relay/health，命中即返回 http://<ip>:<port>。无需修改后端。
 */
export class Discovery {
  static localCandidates(): string[] {
    const candidates: string[] = [];
    const selfIps: string[] = [];
    try {
      const net: connection.NetHandle = connection.getDefaultNetSync();
      const props: connection.ConnectionProperties = connection.getConnectionPropertiesSync(net);
      const links: connection.LinkAddress[] = props.linkAddresses;
      for (let i = 0; i < links.length; i++) {
        const addr: connection.NetAddress = links[i].address;
        if (addr.family === 1) {
          selfIps.push(addr.address);
        }
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'read local ip failed');
      return candidates;
    }
    for (let s = 0; s < selfIps.length; s++) {
      const parts: string[] = selfIps[s].split('.');
      if (parts.length !== 4) {
        continue;
      }
      const prefix: string = parts[0] + '.' + parts[1] + '.' + parts[2] + '.';
      for (let h = HOST_MIN; h <= HOST_MAX; h++) {
        const ip: string = prefix + h;
        if (ip !== selfIps[s] && candidates.indexOf(ip) < 0) {
          candidates.push(ip);
        }
      }
    }
    hilog.info(DOMAIN, TAG, 'candidates=%{public}d', candidates.length);
    return candidates;
  }

  private static baseOf(ip: string): string {
    return 'http://' + ip + ':' + Config.discoveryPort;
  }

  private static async probe(ip: string): Promise<string> {
    const httpRequest = http.createHttp();
    const base: string = Discovery.baseOf(ip);
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: PROBE_TIMEOUT_MS,
        readTimeout: PROBE_TIMEOUT_MS
      };
      const res: http.HttpResponse = await httpRequest.request(base + Config.healthPath, options);
      if (res.responseCode === 200) {
        const parsed: ApiResult<HealthData> = parseApi<HealthData>(res.result as string);
        if (parsed.ok) {
          hilog.info(DOMAIN, TAG, 'found server at %{public}s', base);
          return base;
        }
      }
    } catch (e) {
      // 该地址不可达，忽略
    } finally {
      httpRequest.destroy();
    }
    return '';
  }

  /** 扫描本机网段，返回第一个可达的后端地址；找不到返回空串。 */
  static async autoFind(): Promise<string> {
    const hosts: string[] = Discovery.localCandidates();
    for (let start = 0; start < hosts.length; start += BATCH_SIZE) {
      const end: number = Math.min(start + BATCH_SIZE, hosts.length);
      const batch: string[] = hosts.slice(start, end);
      const tasks: Promise<string>[] = [];
      for (let i = 0; i < batch.length; i++) {
        tasks.push(Discovery.probe(batch[i]));
      }
      const results: string[] = await Promise.all(tasks);
      for (let j = 0; j < results.length; j++) {
        if (results[j].length > 0) {
          return results[j];
        }
      }
    }
    hilog.info(DOMAIN, TAG, 'no server found in local subnet');
    return '';
  }
}
