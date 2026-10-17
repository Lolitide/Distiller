/**
 * 知了 · 我的画像
 *
 * 一句话：**这台手机上的"我关心什么"**。
 *
 * 数据流：本机消息（只取 `is_self === true`，即我本人发的）
 *   → `ProfileExtract` 统计成「词 + 次数 + 类别」的词频表（**不含原话**）
 *   → `POST /api/relay/profile` 交给后端的小模型归纳（后端**只处理、不存储**）
 *   → 结果落回本机 preferences（`Store.getProfile/saveProfile`）。
 *
 * 首版定位是**只展示**：能看、能删、能手动加、能导出导入，
 * 但**不参与**候选排序或提醒强度——先把"归纳得准不准"这件事看清楚。
 */

import { picker, fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { Store } from '../common/Store';
import { ApiClient } from '../common/ApiClient';
import { ProfileExtract } from '../common/ProfileExtract';
import { BottomNav } from '../common/BottomNav';
import { safeToast } from '../common/UiParts';
import {
  RobotMessage, ProfileEntry, ProfileEntryRaw, ProfileBody, ProfileData, ProfileExport,
  ProfileKind, ProfileMaterial, toProfileKind, profileKindLabel, profileEntryId, nowTimestamp
} from '../common/Types';

/** 展示顺序（与后端 KINDS 无关，纯 UI） */
const KIND_ORDER: ProfileKind[] = [
  ProfileKind.INTEREST, ProfileKind.PLACE, ProfileKind.ROLE,
  ProfileKind.SCHEDULE, ProfileKind.PREFERENCE
];
/** 新增自身消息到这个数，就提示"可以更新画像了" */
const AUTO_HINT_THRESHOLD: number = 30;
/** 一次最多让后端归纳多少条 */
const MAX_ENTRIES: number = 40;

function clampWeight(v: number): number {
  if (!Number.isFinite(v)) {
    return 0;
  }
  if (v < 0) {
    return 0;
  }
  return v > 100 ? 100 : Math.round(v);
}

/** 权重映射成透明度（1.0 很实，0.45 很淡）——一眼看出哪些词更能代表我 */
function weightAlpha(w: number): number {
  const a: number = 0.45 + 0.55 * (clampWeight(w) / 100);
  return a;
}

@Entry
@Component
struct ProfilePage {
  @State entries: ProfileEntry[] = [];
  @State analyzing: boolean = false;
  /** 自上次分析以来新增的「我自己发的」消息条数 */
  @State newSelf: number = 0;
  @State selfMsgs: number = 0;
  @State engine: string = '';
  @State lastAt: number = 0;
  @State showAdd: boolean = false;
  @State addTerm: string = '';
  @State addKind: ProfileKind = ProfileKind.INTEREST;
  @State importing: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  reload(): void {
    this.entries = Store.getProfile();
    this.lastAt = Store.getProfileAt();
    const material: ProfileMaterial = ProfileExtract.material(Store.getMessages());
    this.selfMsgs = material.counters.selfMsgs;
    this.newSelf = ProfilePage.countNewSelf(Store.getMessages(), this.lastAt);
    if (this.entries.length > 0) {
      this.engine = this.entries[0].source;
    }
  }

  /** 自 `since` 之后（按消息时间戳）新增的自身消息条数。 */
  static countNewSelf(list: RobotMessage[], since: number): number {
    if (since <= 0) {
      let n: number = 0;
      for (let i = 0; i < list.length; i++) {
        if (list[i].is_self === true) {
          n++;
        }
      }
      return n;
    }
    let n: number = 0;
    for (let i = 0; i < list.length; i++) {
      const m: RobotMessage = list[i];
      if (m.is_self !== true) {
        continue;
      }
      const t: number = ProfilePage.tsOf(m.timestamp);
      if (t > 0 && t >= since) {
        n++;
      }
    }
    return n;
  }

  static tsOf(ts: string): number {
    if (ts.length < 19) {
      return 0;
    }
    const fixed: string = ts.substring(0, 10) + 'T' + ts.substring(11, 19) + '+08:00';
    const t: number = Date.parse(fixed);
    return Number.isNaN(t) ? 0 : t;
  }

  entriesOf(kind: ProfileKind): ProfileEntry[] {
    const out: ProfileEntry[] = [];
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].kind === kind) {
        out.push(this.entries[i]);
      }
    }
    out.sort((a: ProfileEntry, b: ProfileEntry): number => b.weight - a.weight);
    return out;
  }

  countOf(kind: ProfileKind): number {
    return this.entriesOf(kind).length;
  }

  engineText(): string {
    if (this.entries.length === 0) {
      return '';
    }
    return this.engine === 'llm' ? '由本机模型归纳' : '由规则统计';
  }

  lastAtText(): string {
    if (this.lastAt <= 0) {
      return '还没分析过';
    }
    const d: Date = new Date(this.lastAt);
    return d.getFullYear() + '-' + pad2(d.getMonth() + 1) + '-' + pad2(d.getDate())
      + ' ' + pad2(d.getHours()) + ':' + pad2(d.getMinutes());
  }

  // ------------------------------------------------------------ 分析

  async analyze(): Promise<void> {
    if (this.analyzing) {
      return;
    }
    const material: ProfileMaterial = ProfileExtract.material(Store.getMessages());
    if (material.counters.selfMsgs === 0) {
      safeToast(this.getUIContext(), '还没采集到你自己发的消息（只统计你本人发的）');
      return;
    }
    if (material.terms.length === 0) {
      safeToast(this.getUIContext(), '没能从你的消息里统计出词条，先多聊几句再试');
      return;
    }
    this.analyzing = true;
    try {
      const body: ProfileBody = { material: material, max_entries: MAX_ENTRIES };
      const data: ProfileData | null = await ApiClient.requestProfile(body);
      if (data === null) {
        safeToast(this.getUIContext(), '分析失败：连不上服务器，或模型正忙');
        return;
      }
      const now: number = Date.now();
      const merged: ProfileEntry[] = ProfilePage.merge(this.entries, data.entries, now, data.engine);
      Store.saveProfile(merged);
      Store.setProfileAt(now);
      this.entries = merged;
      this.engine = data.engine;
      this.lastAt = now;
      this.newSelf = 0;
      safeToast(this.getUIContext(),
        '画像已更新：' + merged.length + ' 条（' + (data.engine === 'llm' ? '模型' : '规则') + '）');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      safeToast(this.getUIContext(), '分析失败：' + err.message);
    } finally {
      this.analyzing = false;
    }
  }

  /**
   * 把这一轮的结果并进已有画像。
   *
   * 三条规矩：
   *   1. **手动加的条目永远不动**（只刷权重）——用户的手工劳动不能被机器覆盖；
   *   2. 这一轮没被选中的旧词条**权重减半**，时间久了自然沉底（不直接删，避免抖一下就没）；
   *   3. 同一个 (类别, 词) 复用同一个 id，反复分析不会长出重复条目。
   */
  static merge(prev: ProfileEntry[], raw: ProfileEntryRaw[], now: number,
    engine: string): ProfileEntry[] {
    const byId: Map<string, ProfileEntry> = new Map<string, ProfileEntry>();
    for (let i = 0; i < prev.length; i++) {
      byId.set(prev[i].id, prev[i]);
    }
    const fresh: string[] = [];
    for (let i = 0; i < raw.length; i++) {
      const term: string = raw[i].term.trim();
      if (term.length === 0) {
        continue;
      }
      const kind: ProfileKind = toProfileKind(raw[i].kind);
      const id: string = profileEntryId(kind, term);
      fresh.push(id);
      const weight: number = clampWeight(raw[i].weight);
      const old: ProfileEntry | undefined = byId.get(id);
      if (old === undefined) {
        const e: ProfileEntry = {
          id: id, kind: kind, term: term, weight: weight,
          evidence: raw[i].evidence, firstTs: now, lastTs: now,
          source: engine, reason: raw[i].reason, manual: false
        };
        byId.set(id, e);
      } else {
        old.weight = weight;
        old.evidence = raw[i].evidence;
        old.lastTs = now;
        old.reason = raw[i].reason;
        if (!old.manual) {
          old.source = engine;
        }
      }
    }
    const out: ProfileEntry[] = [];
    byId.forEach((e: ProfileEntry) => {
      if (fresh.indexOf(e.id) < 0 && !e.manual) {
        e.weight = clampWeight(e.weight * 0.5);
      }
      out.push(e);
    });
    return out;
  }

  // ------------------------------------------------------------ 增删

  removeEntry(id: string): void {
    const next: ProfileEntry[] = [];
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].id !== id) {
        next.push(this.entries[i]);
      }
    }
    Store.saveProfile(next);
    this.entries = next;
    safeToast(this.getUIContext(), '已删除该词条');
  }

  confirmRemove(e: ProfileEntry): void {
    this.getUIContext().showAlertDialog({
      title: '删除词条',
      message: '把「' + e.term + '」从画像里删掉？下次重新分析时它可能又被统计出来。',
      primaryButton: {
        value: '删除',
        action: () => {
          this.removeEntry(e.id);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  addManual(): void {
    const term: string = this.addTerm.trim();
    if (term.length === 0) {
      safeToast(this.getUIContext(), '先填一个词');
      return;
    }
    const now: number = Date.now();
    const id: string = profileEntryId(this.addKind, term);
    const next: ProfileEntry[] = [];
    let replaced: boolean = false;
    for (let i = 0; i < this.entries.length; i++) {
      if (this.entries[i].id === id) {
        replaced = true;
        next.push(this.entries[i]);
      } else {
        next.push(this.entries[i]);
      }
    }
    if (!replaced) {
      const e: ProfileEntry = {
        id: id, kind: this.addKind, term: term, weight: 80,
        evidence: 0, firstTs: now, lastTs: now,
        source: 'manual', reason: '手动添加', manual: true
      };
      next.push(e);
    }
    Store.saveProfile(next);
    this.entries = next;
    this.addTerm = '';
    this.showAdd = false;
    safeToast(this.getUIContext(), replaced ? '这个词已经在画像里了' : '已添加');
  }

  confirmClear(): void {
    this.getUIContext().showAlertDialog({
      title: '清空画像',
      message: '清掉本机保存的全部画像词条？聊天消息不受影响，清空后可以重新分析。',
      primaryButton: {
        value: '清空',
        action: () => {
          Store.clearProfile();
          Store.setProfileAt(0);
          this.entries = [];
          this.lastAt = 0;
          this.newSelf = this.selfMsgs;
          safeToast(this.getUIContext(), '已清空画像');
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  // ------------------------------------------------------------ 导出 / 导入

  async exportProfile(): Promise<void> {
    if (this.entries.length === 0) {
      safeToast(this.getUIContext(), '画像还是空的，没什么可导出');
      return;
    }
    try {
      const payload: ProfileExport = {
        version: 1,
        exported_at: nowTimestamp(),
        entries: this.entries
      };
      const text: string = JSON.stringify(payload);
      const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
      options.newFileNames = ['zhiliao_profile_' + Date.now() + '.json'];
      const uris: Array<string> = await new picker.DocumentViewPicker().save(options);
      if (uris.length === 0) {
        return;
      }
      const f: fileIo.File = fileIo.openSync(uris[0],
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.writeSync(f.fd, text);
      } finally {
        fileIo.closeSync(f);
      }
      safeToast(this.getUIContext(), '已导出 ' + this.entries.length + ' 条词条');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      safeToast(this.getUIContext(), '导出失败：' + err.message);
    }
  }

  async importProfile(): Promise<void> {
    if (this.importing) {
      return;
    }
    this.importing = true;
    try {
      const options: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      options.maxSelectNumber = 1;
      const uris: Array<string> = await new picker.DocumentViewPicker().select(options);
      if (uris.length === 0) {
        return;
      }
      const f: fileIo.File = fileIo.openSync(uris[0], fileIo.OpenMode.READ_ONLY);
      let text: string = '';
      try {
        const size: number = fileIo.statSync(f.fd).size;
        if (size <= 0 || size > 4 * 1024 * 1024) {
          safeToast(this.getUIContext(), '文件为空或过大（上限 4MB）');
          return;
        }
        const buf: ArrayBuffer = new ArrayBuffer(size);
        fileIo.readSync(f.fd, buf);
        const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
        text = decoder.decodeToString(new Uint8Array(buf));
      } finally {
        fileIo.closeSync(f);
      }
      const imported: number = ProfilePage.importInto(text, this.entries);
      if (imported < 0) {
        safeToast(this.getUIContext(), '这不是本应用的画像文件（格式不对）');
        return;
      }
      this.entries = Store.getProfile();
      safeToast(this.getUIContext(), '已导入 ' + imported + ' 条词条');
    } catch (e) {
      const err: BusinessError = e as BusinessError;
      safeToast(this.getUIContext(), '导入失败：' + err.message);
    } finally {
      this.importing = false;
    }
  }

  /**
   * 解析导入文件并合并到当前画像。返回新增/更新的条数；格式不对返回 -1。
   *
   * 外部文件一律当**不可信输入**：逐条校验字段，不认识的类别归到「关注点」，
   * 权重夹到 0-100——不认识的条目宁可丢，也不要让脏数据进偏好设置。
   */
  static importInto(text: string, current: ProfileEntry[]): number {
    let parsed: ProfileExport | null = null;
    try {
      parsed = JSON.parse(text) as ProfileExport;
    } catch (e) {
      return -1;
    }
    if (parsed === null || parsed.entries === undefined) {
      return -1;
    }
    const list: ProfileEntry[] = parsed.entries;
    if (list.length === 0) {
      return -1;
    }
    const byId: Map<string, ProfileEntry> = new Map<string, ProfileEntry>();
    for (let i = 0; i < current.length; i++) {
      byId.set(current[i].id, current[i]);
    }
    let n: number = 0;
    for (let i = 0; i < list.length; i++) {
      const raw: ProfileEntry = list[i];
      const term: string = (raw.term ?? '').trim();
      if (term.length === 0) {
        continue;
      }
      const kind: ProfileKind = toProfileKind(raw.kind);
      const id: string = profileEntryId(kind, term);
      const old: ProfileEntry | undefined = byId.get(id);
      const ts: number = Number.isFinite(raw.lastTs) ? raw.lastTs : Date.now();
      if (old === undefined) {
        const e: ProfileEntry = {
          id: id, kind: kind, term: term,
          weight: clampWeight(Number(raw.weight)),
          evidence: Number.isFinite(raw.evidence) ? raw.evidence : 0,
          firstTs: Number.isFinite(raw.firstTs) ? raw.firstTs : ts,
          lastTs: ts,
          source: typeof raw.source === 'string' && raw.source.length > 0 ? raw.source : 'manual',
          reason: typeof raw.reason === 'string' ? raw.reason : '',
          manual: raw.manual === true
        };
        byId.set(id, e);
        n++;
      } else if (ts > old.lastTs) {
        old.weight = clampWeight(Number(raw.weight));
        old.lastTs = ts;
        n++;
      }
    }
    const merged: ProfileEntry[] = [];
    byId.forEach((e: ProfileEntry) => {
      merged.push(e);
    });
    Store.saveProfile(merged);
    return n;
  }

  // ------------------------------------------------------------ UI

  @Builder
  kindSection(kind: ProfileKind) {
    if (this.countOf(kind) > 0) {
      Column({ space: 8 }) {
        Row({ space: 6 }) {
          Text(profileKindLabel(kind))
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
          Text('' + this.countOf(kind))
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .width('100%')

        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.entriesOf(kind), (e: ProfileEntry) => {
            Row({ space: 6 }) {
              Text(e.term)
                .fontSize(14)
                .fontColor('#1F3A5F')
                .opacity(weightAlpha(e.weight))
              Text('×')
                .fontSize(13)
                .fontColor(Color.Gray)
                .padding({ left: 2, right: 2 })
                .onClick(() => {
                  this.confirmRemove(e);
                })
            }
            .backgroundColor(e.manual ? '#EAF1FA' : '#F4F6F8')
            .borderRadius(12)
            .padding({ left: 10, right: 8, top: 5, bottom: 5 })
            .margin({ right: 8, bottom: 8 })
          }, (e: ProfileEntry) => e.id + '#' + e.weight + '#' + (e.manual ? '1' : '0'))
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
  }

  @Builder
  kindChip(kind: ProfileKind) {
    Text(profileKindLabel(kind))
      .fontSize(13)
      .fontColor(this.addKind === kind ? Color.White : '#1F3A5F')
      .backgroundColor(this.addKind === kind ? '#2E75B6' : '#EAF1FA')
      .borderRadius(10)
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .margin({ right: 8, bottom: 8 })
      .onClick(() => {
        this.addKind = kind;
      })
  }

  build() {
    Column() {
      Row({ space: 8 }) {
        Button('返回')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Text('我的画像')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 4 })

      Scroll() {
        Column({ space: 14 }) {
          // ---- 状态 ----
          Column({ space: 4 }) {
            Text('已采集你自己发的消息 ' + this.selfMsgs + ' 条 · 词条 ' + this.entries.length + ' 条')
              .fontSize(13)
            Text('上次分析：' + this.lastAtText() + (this.engineText().length > 0 ? ' · ' + this.engineText() : ''))
              .fontSize(12)
              .fontColor(Color.Gray)
            if (this.newSelf >= AUTO_HINT_THRESHOLD) {
              Text('有 ' + this.newSelf + ' 条新消息可以分析')
                .fontSize(12)
                .fontColor(Color.Orange)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')

          // ---- 操作 ----
          Row({ space: 10 }) {
            Button(this.analyzing ? '分析中…' : '重新分析')
              .enabled(!this.analyzing)
              .onClick(() => {
                this.analyze();
              })
            Button('手动添加')
              .onClick(() => {
                this.showAdd = !this.showAdd;
              })
          }
          .width('100%')

          if (this.showAdd) {
            Column({ space: 8 }) {
              TextInput({ placeholder: '例如：考研 / 康桥苑 / 仲英书院', text: this.addTerm })
                .onChange((value: string) => {
                  this.addTerm = value;
                })
                .width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(KIND_ORDER, (k: ProfileKind) => {
                  this.kindChip(k);
                }, (k: ProfileKind) => k)
              }
              .width('100%')
              Row({ space: 10 }) {
                Button('添加')
                  .onClick(() => {
                    this.addManual();
                  })
                Button('取消')
                  .onClick(() => {
                    this.showAdd = false;
                    this.addTerm = '';
                  })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(10)
            .backgroundColor('#F7F9FB')
            .borderRadius(10)
          }

          // ---- 词条 ----
          if (this.entries.length === 0) {
            Column({ space: 6 }) {
              Text('还没有画像')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              Text('画像由「你自己在群里发过的消息」统计而来。先订阅几个群、聊几句，'
                + '再点上面的「重新分析」即可生成。')
                .fontSize(12)
                .fontColor(Color.Gray)
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          } else {
            ForEach(KIND_ORDER, (k: ProfileKind) => {
              this.kindSection(k);
            }, (k: ProfileKind) => k)
          }

          // ---- 导出 / 导入 / 清空 ----
          Column({ space: 8 }) {
            Text('管理')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Row({ space: 10 }) {
              Button('导出')
                .onClick(() => {
                  this.exportProfile();
                })
              Button('导入')
                .enabled(!this.importing)
                .onClick(() => {
                  this.importProfile();
                })
            }
            Button('清空画像')
              .onClick(() => {
                this.confirmClear();
              })
            Text('画像只存在这台手机上。分析时只把「词 + 出现次数」这类统计发给你的服务器，'
              + '不含任何聊天原文；服务器不留存，分析完即忘。导出/导入用于换手机时自己搬运。')
              .fontSize(12)
              .fontColor(Color.Gray)
              .lineHeight(18)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.Top)

      BottomNav({ current: 'profile' })
    }
    .width('100%')
    .height('100%')
  }
}

function pad2(n: number): string {
  return n < 10 ? '0' + n : '' + n;
}
