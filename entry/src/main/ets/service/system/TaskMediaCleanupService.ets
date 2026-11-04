/*
 * service/system · TaskMediaCleanupService —— 清理「已经没有任何任务引用」的截图副本。
 *
 * ## 为什么需要它（2026-11-03，AGC 审核那条「图片预览失败」的收尾）
 *
 * 为了修「相册 URI 只带临时授权、重启后读不到」，选图时会把图**复制**进 `<filesDir>/media/`
 * （见 `MediaPickService`）。复制之后就有个新账要还：**任务被彻底删除时，副本不会自己消失**。
 * 不清理会积压两件事：
 *   · 存储：每张截图一份副本，长期占用应用空间；
 *   · 隐私：用户在回收站里「彻底删除」任务，预期是这条任务的图和文字一起没了
 *     （《隐私政策》里「删除即清除」就是这个口径），留着文件属于言行不一。
 *
 * ## 为什么做成"启动时扫一遍"，而不是在每个删除入口手动删
 *
 * 删除入口有好几个（列表多选删除、详情页删除、回收站彻底删除、清空全部任务…），
 * 逐个挂清理既容易漏、也容易在「软删→回收站→恢复」链路上误删还能用的文件。
 * 反过来做**引用计数式**的清扫最稳：只要还有任务（含回收站、含待确认）引用它，就留着；
 * 没人引用就删。启动时扫一次，代价是一次目录列举。
 *
 * ⚠️ 调用方必须把**全部**任务传进来（含 `store.trashList`），否则会把回收站里还需要的图删掉。
 */
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Task } from '../../model';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskMediaCleanup';

/** 截图副本目录名（与 `MediaPickService` 里保持一致） */
const MEDIA_DIR: string = 'media';

export class TaskMediaCleanupService {
  /** 截图副本目录的绝对路径 */
  private static mediaDir(context: common.Context): string {
    return context.filesDir + '/' + MEDIA_DIR;
  }

  /**
   * 清扫一次：删掉 `<filesDir>/media` 下没有任何任务引用的文件。
   *
   * @param tasks **全部**任务（`store.allTasks()` + `store.trashList`）
   * @returns 实际删掉的文件数（失败不抛，返回删成功的个数）
   */
  static async sweep(context: common.Context, tasks: Task[]): Promise<number> {
    const dir: string = TaskMediaCleanupService.mediaDir(context);
    let names: string[] = [];
    try {
      if (!fileIo.accessSync(dir)) {
        return 0;
      }
      names = fileIo.listFileSync(dir);
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'list media dir failed: %{public}d %{public}s', err.code, err.message);
      return 0;
    }
    if (names.length === 0) {
      return 0;
    }

    // 引用集合：按文件名比对（副本都在同一个目录里，文件名是唯一键）
    const keep: Set<string> = new Set<string>();
    for (let i: number = 0; i < tasks.length; i++) {
      const urls: string[] | undefined = tasks[i].urls;
      if (urls === undefined) {
        continue;
      }
      for (let j: number = 0; j < urls.length; j++) {
        const uri: string = urls[j];
        const slash: number = uri.lastIndexOf('/');
        if (slash >= 0 && slash < uri.length - 1) {
          keep.add(uri.substring(slash + 1));
        }
      }
    }

    let removed: number = 0;
    for (let i: number = 0; i < names.length; i++) {
      const name: string = names[i];
      if (keep.has(name)) {
        continue;
      }
      try {
        fileIo.unlinkSync(dir + '/' + name);
        removed = removed + 1;
      } catch (error) {
        const err = error as BusinessError;
        hilog.warn(DOMAIN, TAG, 'unlink %{public}s failed: %{public}d %{public}s', name, err.code, err.message);
      }
    }
    hilog.info(DOMAIN, TAG, 'sweep done: files=%{public}d kept=%{public}d removed=%{public}d',
      names.length, keep.size, removed);
    return removed;
  }
}
