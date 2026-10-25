/**
 * 导入任务（FE-60 的对称入口）：系统文件选择器 → 读 JSON 文本 → 交给 ViewModel 解析。
 *
 * 只读**用户主动选择**的文件，不申请存储权限；解析与字段白名单在 `TaskExportViewModel.parseJson()`。
 */
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskImportService';
const ERROR_USER_CANCELED: number = 13900042;

export class TaskImportFileResult {
  ok: boolean = false;
  cancelled: boolean = false;
  text: string = '';
  message: string = '';
}

export class TaskImportService {
  static async pickJson(context: common.Context): Promise<TaskImportFileResult> {
    const result: TaskImportFileResult = new TaskImportFileResult();
    try {
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      options.fileSuffixFilters = ['知了备份|.json'];
      const selectPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await selectPicker.select(options);
      if (uris === undefined || uris === null || uris.length === 0) {
        result.cancelled = true;
        return result;
      }
      result.text = fileIo.readTextSync(uris[0]);
      result.ok = result.text.length > 0;
      if (!result.ok) {
        result.message = '文件是空的';
      }
      return result;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'pick json failed: %{public}d %{public}s', err.code, err.message);
      if (err.code === ERROR_USER_CANCELED) {
        result.cancelled = true;
        return result;
      }
      result.message = '读取失败：' + err.code;
      return result;
    }
  }
}
