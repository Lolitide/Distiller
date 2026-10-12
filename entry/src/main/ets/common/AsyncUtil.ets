/** 异步小工具：给可能不返回的 AI/网络调用加超时保护。 */

/**
 * 在 ms 毫秒内返回结果；超时或失败返回 null。
 * 用于避免设备端 AI 能力偶发不返回时把调用方的队列/锁永久卡住。
 */
export function withTimeout<T>(p: Promise<T>, ms: number): Promise<T | null> {
  let timerId: number = -1;
  const timer: Promise<T | null> = new Promise<T | null>((resolve: (value: T | null) => void) => {
    timerId = setTimeout(() => {
      resolve(null);
    }, ms);
  });
  const raced: Promise<T | null> = Promise.race<T | null>([p, timer]);
  return raced.then((value: T | null): T | null => {
    if (timerId >= 0) {
      clearTimeout(timerId);
    }
    return value;
  });
}
