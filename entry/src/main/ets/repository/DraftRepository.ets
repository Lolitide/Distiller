/**
 * 「添加任务」草稿的落盘（preferences 单键）。
 *
 * 用途：用户填到一半把半模态关掉（或 App 被切走），下次点「＋」继续编辑。
 * 只存表单字段（名称/时间/标签/原文…），**不存任何身份信息或后端数据**；
 * 保存成功或点「重置」时清空。
 */
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AddTaskDraft } from '../viewmodel/AddTaskDraft';

const DOMAIN: number = 0x0000;
const TAG: string = 'DraftRepository';
const STORE_NAME: string = 'distiller_draft';
const K_DRAFT: string = 'add_task_draft';

export class DraftRepository {
  private static store: preferences.Preferences | undefined = undefined;

  private static ensure(context: common.Context): preferences.Preferences | undefined {
    if (DraftRepository.store !== undefined) {
      return DraftRepository.store;
    }
    try {
      DraftRepository.store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      return DraftRepository.store;
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'getPreferencesSync failed: %{public}s', err.message);
      return undefined;
    }
  }

  static save(context: common.Context, draft: AddTaskDraft): void {
    const store: preferences.Preferences | undefined = DraftRepository.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(K_DRAFT, draft.toJson());
      store.flushSync();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'save draft failed: %{public}s', err.message);
    }
  }

  /** 恢复上次草稿；没有/损坏都返回 false（调用方用空草稿） */
  static load(context: common.Context, draft: AddTaskDraft): boolean {
    const store: preferences.Preferences | undefined = DraftRepository.ensure(context);
    if (store === undefined) {
      return false;
    }
    try {
      const raw: preferences.ValueType = store.getSync(K_DRAFT, '');
      const text: string = typeof raw === 'string' ? raw : '';
      return draft.loadJson(text);
    } catch (error) {
      return false;
    }
  }

  static clear(context: common.Context): void {
    const store: preferences.Preferences | undefined = DraftRepository.ensure(context);
    if (store === undefined) {
      return;
    }
    try {
      store.putSync(K_DRAFT, '');
      store.flushSync();
    } catch (error) {
      // 清不掉不影响使用，下次保存会覆盖
    }
  }
}
