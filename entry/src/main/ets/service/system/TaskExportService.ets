/**
 * service/system · TaskExportService —— 把导出文本**落到文件系统或剪贴板**（FE-60）。
 *
 * 为什么单独一层：`viewmodel/TaskExportViewModel` 只拼字符串（CSV/JSON 口径），
 * 「写到哪儿」是系统能力 —— 按分层纪律（开发指南 §9.4）页面/组件不直接调系统 API，
 * 统一收口在 `service/system/` 里。
 *
 * 两条出口（验收项要的就是这两个）：
 *  ① **文件**：`picker.DocumentViewPicker.save()` 拉起系统「保存到…」面板，用户自己选目录/改名；
 *     → 官方不需要任何权限（picker 是系统安全组件），本服务也不申请。
 *  ② **剪贴板**：`pasteboard.getSystemPasteboard().setData(...)`，贴到聊天/文档里就能用。
 *
 * 结果的形状（工程硬约束第 10 条）：成功 / **用户取消** / 失败 + 错误码，三者分得开 ——
 * 用户取消**不算失败**，页面不该弹"导出失败"。
 *
 * 官方 API 出处（`@ohos.file.picker.d.ts` / `@ohos.file.fs.d.ts`，均核过 d.ts）：
 *  · `class DocumentViewPicker { constructor(context: Context); save(option?: DocumentSaveOptions): Promise<Array<string>> }`
 *  · `DocumentSaveOptions.newFileNames?: Array<string>` / `fileSuffixChoices?: Array<string>`（形如 `'CSV|.csv'`）
 *  · `fileIo.openSync(uri, OpenMode.READ_WRITE | OpenMode.CREATE)` → `writeSync(fd, string)` → `closeSync`
 */
import { common } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'TaskExportService';

/** 用户主动取消保存时系统给的错误码（部分版本会 reject 而不是返回空数组） */
const ERROR_USER_CANCELED: number = 13900042;

/** 一次导出的结果 */
export class TaskExportResult {
  /** 真的写成功了 */
  ok: boolean = false;
  /** 用户在系统面板里取消了（**不是错误**） */
  cancelled: boolean = false;
  /** 失败时的 `BusinessError.code`（0 ＝ 没出错） */
  errorCode: number = 0;
  /** 给人看的一句话（失败用；成功时为空） */
  message: string = '';
}

export class TaskExportService {
  /**
   * 拉起系统保存面板并写入文本。
   *
   * @param context 页面上下文（`getUIContext().getHostContext()`）
   * @param fileName 预填的文件名（用户仍可改）
   * @param suffixChoice 后缀选项，形如 `'CSV|.csv'`（官方格式：`描述|后缀`）
   * @param content 要写入的文本
   * @param companionFileName 可选：伴随文件名（CSV 的隐式标识 `.meta.json`）
   * @param companionContent 可选：伴随文件内容
   *
   * 一次 `save()` 可创建多个文件（官方说明「用户可以保存一个或多个文件」），
   * 所以 CSV 的主文件与元数据伴随文件在同一次保存流程里落盘。
   */
  static async saveFile(context: common.Context, fileName: string, suffixChoice: string,
    content: string, companionFileName?: string, companionContent?: string): Promise<TaskExportResult> {
    const result: TaskExportResult = new TaskExportResult();
    try {
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      const metaName: string = companionFileName !== undefined ? companionFileName : '';
      const metaContent: string = companionContent !== undefined ? companionContent : '';
      const withCompanion: boolean = metaName.length > 0 && metaContent.length > 0;
      if (withCompanion) {
        // 两个名字都自带扩展名（主文件 .csv、伴随文件 .csv.meta.json），不再让选择器追加后缀
        options.newFileNames = [fileName, metaName];
      } else {
        options.newFileNames = [fileName];
        options.fileSuffixChoices = [suffixChoice];
      }
      const savePicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(context);
      const uris: string[] = await savePicker.save(options);
      if (uris === undefined || uris === null || uris.length === 0 || uris[0].length === 0) {
        // 取消：系统在某些版本上直接返回空数组
        result.cancelled = true;
        return result;
      }
      TaskExportService.writeText(uris[0], content);
      // 伴随文件：系统没返回第二个 URI 时（个别版本一次只给一个）只保证主文件
      if (withCompanion && uris.length > 1 && uris[1].length > 0) {
        try {
          TaskExportService.writeText(uris[1], metaContent);
        } catch (error) {
          const err = error as BusinessError;
          hilog.warn(DOMAIN, TAG, 'save meta file failed: code=%{public}d msg=%{public}s',
            err.code, err.message);
        }
      }
      result.ok = true;
      return result;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'save file failed: code=%{public}d msg=%{public}s', err.code, err.message);
      result.errorCode = err.code;
      if (err.code === ERROR_USER_CANCELED) {
        result.cancelled = true;
        return result;
      }
      result.ok = false;
      result.message = '保存失败（' + err.code + '）';
      return result;
    }
  }

  /** 把一段文本写进指定 URI（打开 → 写 → 关闭；关不掉不影响已写入的内容） */
  private static writeText(uri: string, content: string): void {
    let file: fileIo.File | undefined = undefined;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, content);
    } finally {
      if (file !== undefined) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
          // 关不掉不影响已经写进去的内容
        }
      }
    }
  }

  /** 把文本整段塞进系统剪贴板（分类粘贴不需要任何权限） */
  static async copyToClipboard(content: string): Promise<TaskExportResult> {
    const result: TaskExportResult = new TaskExportResult();
    try {
      const data: pasteboard.PasteData =
        pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      await pasteboard.getSystemPasteboard().setData(data);
      result.ok = true;
      return result;
    } catch (error) {
      const err = error as BusinessError;
      hilog.warn(DOMAIN, TAG, 'copy to clipboard failed: code=%{public}d msg=%{public}s', err.code, err.message);
      result.errorCode = err.code;
      result.message = '复制失败（' + err.code + '）';
      return result;
    }
  }
}
