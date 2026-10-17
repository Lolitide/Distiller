/*
 * service/system · MediaPickService —— 从系统相册**选图**（不申请任何权限）。
 *
 * 用途：半模态「添加任务 · 截图」那一块，点一下拉起系统的图片选择器（picker）。
 *
 * 官方事实（`@ohos.file.photoAccessHelper.d.ts` 逐条核过）：
 *  · `photoAccessHelper.PhotoViewPicker.select(options)` **从 API 10 起可用**、未废弃，
 *    返回 `Promise<PhotoSelectResult>`，其中 `photoUris: Array<string>`；
 *  · 官方注释原文：`photoUris` 里的 URI **带持久授权**（"has permanent authorization"），
 *    所以可以直接丢给 `Image()` 显示、也能留给以后的 OCR 读图，**不需要再申请相册权限**；
 *  · `PhotoSelectOptions.maxSelectNumber` 控制选几张，`MIMEType` 用 `PhotoViewMIMETypes.IMAGE_TYPE`（`'image/*'`）。
 *    ⚠️ 系统 picker 是"安全组件"，用户自己选哪张由系统弹窗决定 —— **走它就不要 READ_IMAGEVIDEO 权限**，
 *    这是官方一直推荐的做法（用权限反而更重）。
 *
 * 分层纪律：页面/组件**不许直接调系统能力**（`references/02-编码规约.md` §…、开发指南 §9.4），
 * 所以相册 picker 收口在这里；组件只 import `service/system` 的**桶**。
 * 返回也守「成功 / 用户取消 / 失败 + 错误码」的契约，**不把异常抛给页面**。
 *
 * ⚠️ 本文件是新增（`service/system/` 在 `01-项目基线.md` §5 归属表里是需求方名下）——
 * 只是加了一个「选图」出口，没动已有的三个规划成员；`index.ets` 里补了一行桶导出。
 */
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'MediaPickService';

/** 选图结果：三种状态用字段区分（`uri` 有值＝选中；`cancelled`＝用户自己取消；`errorCode`≠0＝失败） */
export class MediaPickResult {
  /** 选中图片的 URI（空串＝没选到）。可直接给 `Image()` 用，带持久授权 */
  uri: string = '';
  /** 用户主动取消了选择（不算错误，不要弹"失败"提示） */
  cancelled: boolean = false;
  /** 失败时的 `BusinessError.code`（0 ＝ 没出错） */
  errorCode: number = 0;
}

/**
 * 拉起系统图片选择器选**一张**图。
 * 说明：拉起的瞬间页面会被系统 picker 覆盖，返回后继续；用户取消时 `cancelled=true`。
 */
export async function pickSingleImage(): Promise<MediaPickResult> {
  const result: MediaPickResult = new MediaPickResult();
  try {
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const selected: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    if (selected.photoUris.length > 0) {
      result.uri = selected.photoUris[0];
    } else {
      result.cancelled = true;
    }
  } catch (error) {
    const err = error as BusinessError;
    result.errorCode = err.code;
    hilog.error(DOMAIN, TAG, 'pick image failed: %{public}d, %{public}s', err.code, err.message);
  }
  return result;
}
