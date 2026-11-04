/*
 * service/system · MediaPickService —— 从系统相册**选图**（不申请任何权限），并**立刻复制进应用沙箱**。
 *
 * ## 为什么必须复制（2026-11-03 AGC 审核实测 bug）
 *
 * 审核在 HarmonyOS 6.1（Pura 80 Ultra）上按「任务列表 → 任务 → 图片与文件 → 点图」复现：
 * 预览报「该文件可能移动或重命名，预览失败」。
 *
 * 根因是**相册 URI 只带临时授权**。官方 d.ts（`@ohos.file.photoAccessHelper.d.ts`，
 * `PhotoSelectResult.photoUris` 字段注释）原文：
 *   "This URI array can be used only by calling the photoAccessHelper.getAssets API through
 *    temporary authorization. For details, see Using a Media File URI."
 * 也就是说 picker 返回的 `file://media/...` 只在**本次进程**内可读；应用重启（或系统回收授权）后
 * 详情页缩略图、大图预览、端侧 OCR 全都读不到 —— 这正是审核看到的现象。
 * （旧版本这里的注释写成「返回的 URI 带持久授权」，是错的，已按 d.ts 更正。）
 *
 * 结论：选完图的第一件事就是把它复制到 `<filesDir>/media/截图-<时间戳>-<盐>.<ext>`，之后**只用沙箱 URI**：
 * 重启后仍可读、不依赖相册授权、用户删掉相册里那张原图也不影响任务里的截图。
 * 副本的回收见 `TaskMediaCleanupService`（没有任务引用就删）。
 *
 * 分层纪律：页面/组件**不许直接调系统能力**（`references/02-编码规约.md`、开发指南 §9.4），
 * 所以相册 picker 与落盘都收口在这里；组件只 import `service/system` 的**桶**。
 * 返回守「成功 / 用户取消 / 失败 + 错误码」的契约，**不把异常抛给页面**。
 */
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'MediaPickService';

/** 沙箱内存截图的目录名（相对 `context.filesDir`） */
const MEDIA_DIR: string = 'media';
/** 认不出后缀时的兜底（相册 picker 只给图片，jpg 最稳） */
const DEFAULT_EXT: string = '.jpg';
/** 只认这些图片后缀，避免把 URI 尾巴上的查询串之类拼进文件名 */
const IMAGE_EXTS: string[] = ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif', '.heic'];
/** 复制失败的自定义错误码（不走系统错误码空间，只用来说明"这次没拿到可用文件"） */
const ERROR_COPY_FAILED: number = -1;

/** 选图结果：三种状态用字段区分（`uri` 有值＝选中；`cancelled`＝用户自己取消；`errorCode`≠0＝失败） */
export class MediaPickResult {
  /** 沙箱里的 `file://` URI：给 `Image()` / 系统预览器 / OCR 用，**重启后依然有效** */
  uri: string = '';
  /** 同一文件的沙箱绝对路径：需要 `fileIo` 直接开文件时用 */
  path: string = '';
  /** 用户主动取消了选择（不算错误，不要弹"失败"提示） */
  cancelled: boolean = false;
  /** 失败时的 `BusinessError.code`（0 ＝ 没出错） */
  errorCode: number = 0;
}

/**
 * 拉起系统图片选择器选**一张**图，并把选中的图片复制进应用沙箱。
 *
 * @param context 页面上下文（`getUIContext().getHostContext()`），用来定位沙箱目录
 */
export async function pickSingleImage(context: common.Context): Promise<MediaPickResult> {
  const result: MediaPickResult = new MediaPickResult();
  try {
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const selected: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    if (selected.photoUris === undefined || selected.photoUris.length === 0) {
      result.cancelled = true;
      return result;
    }
    // 只在"临时授权还热着"的这几百毫秒里复制，之后一律用沙箱 URI
    const savedPath: string = copyIntoMediaDir(context, selected.photoUris[0]);
    if (savedPath.length === 0) {
      // 复制失败就**不要把临时 URI 交出去** —— 它过一会儿就失效，用户会在详情页看到打不开
      result.errorCode = ERROR_COPY_FAILED;
      return result;
    }
    result.path = savedPath;
    result.uri = fileUri.getUriFromPath(savedPath);
    return result;
  } catch (error) {
    const err = error as BusinessError;
    result.errorCode = err.code;
    hilog.error(DOMAIN, TAG, 'pick image failed: %{public}d, %{public}s', err.code, err.message);
    return result;
  }
}

/** 把相册里那张图复制到 `<filesDir>/media/`，返回沙箱绝对路径（失败返回空串） */
function copyIntoMediaDir(context: common.Context, sourceUri: string): string {
  let source: fileIo.File | undefined = undefined;
  try {
    const dir: string = context.filesDir + '/' + MEDIA_DIR;
    let exists: boolean = false;
    try {
      exists = fileIo.accessSync(dir);
    } catch (error) {
      exists = false;
    }
    if (!exists) {
      fileIo.mkdirSync(dir);
    }
    const destPath: string = dir + '/' + buildFileName(sourceUri);
    source = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);
    fileIo.copyFileSync(source.fd, destPath);
    hilog.info(DOMAIN, TAG, 'screenshot copied into sandbox: %{public}s', destPath);
    return destPath;
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, 'copy screenshot failed: %{public}d, %{public}s', err.code, err.message);
    return '';
  } finally {
    if (source !== undefined) {
      try {
        fileIo.closeSync(source);
      } catch (error) {
        // 关不掉不影响已经复制好的文件
      }
    }
  }
}

/**
 * 副本的文件名：`截图-20261103-090812-3f9a.png`。
 *
 * 为什么不用纯 UUID 当名字：这份文件会交给**系统图片预览器**打开，标题栏显示的就是文件名 ——
 * 一串 UUID 看着像故障。带上时间戳既可读，又能保证不重名（到秒 + 随机盐）。
 */
function buildFileName(sourceUri: string): string {
  const now: Date = new Date();
  const stamp: string = `${now.getFullYear()}${pad2(now.getMonth() + 1)}${pad2(now.getDate())}`
    + '-' + `${pad2(now.getHours())}${pad2(now.getMinutes())}${pad2(now.getSeconds())}`;
  // 随机盐：同一秒内选两张图也不会撞名
  const salt: string = Date.now().toString(36) + Math.floor(Math.random() * 1000).toString(36);
  return '截图-' + stamp + '-' + salt + suffixOf(sourceUri);
}

function pad2(value: number): string {
  return value < 10 ? '0' + value : '' + value;
}

/** 从相册 URI 尾巴上取图片后缀（取不到就用 `.jpg`） */
function suffixOf(uri: string): string {
  const slash: number = uri.lastIndexOf('/');
  const name: string = slash >= 0 ? uri.substring(slash + 1) : uri;
  const dot: number = name.lastIndexOf('.');
  if (dot <= 0) {
    return DEFAULT_EXT;
  }
  const ext: string = name.substring(dot).toLowerCase();
  for (let i: number = 0; i < IMAGE_EXTS.length; i++) {
    if (ext === IMAGE_EXTS[i]) {
      return ext;
    }
  }
  return DEFAULT_EXT;
}
