# -*- coding: utf-8 -*-
"""把人工标注的 labels_*.json 换算成「提醒」的 precision / recall（阶段 3 的验收）。

配套 `make_labeling_kit.py`：
    .venv\\Scripts\\python.exe -X utf8 make_labeling_kit.py --n 300
    双击 labeling\\labeler.html 标注 → 导出 JSON
    .venv\\Scripts\\python.exe -X utf8 eval_labels.py labeling\\labels_2026-10-21.json

判定口径（与产品一致）：
  * 一段对话里**任意一条**被判成 待办/通知/活动/出行计划 -> 流水线会给提醒；
  * 人工 `remind=yes` 视作应该提醒，`no` 视作不该提醒，`unsure` 跳过。

可选：
  --llm   对「规则与人工不一致」的片段再跑一次模型，看模型能不能救回来（慢）。
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pipeline_proto as RULES
import llm_worker

BASE_DIR = Path(__file__).resolve().parent
ACTIONABLE = (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_ACTIVITY, RULES.EVENT_PLAN)


def _find_labels(argv: list[str]) -> Path | None:
    for a in argv[1:]:
        if a.startswith("-"):
            continue
        p = Path(a)
        if p.exists():
            return p
    cands = sorted(BASE_DIR.glob("labeling/labels_*.json")) + sorted(BASE_DIR.glob("labels_*.json"))
    return cands[-1] if cands else None


def _pipeline_yes(texts: list[str]) -> bool:
    for t in texts:
        if RULES.classify(t) in ACTIONABLE:
            return True
    return False


def _llm_yes(texts: list[str]) -> bool:
    for t in texts:
        obj = llm_parse_extract(t)
        if obj and obj.get("kind") in ACTIONABLE:
            return True
    return False


def llm_parse_extract(text: str):
    import llm_parse
    return llm_parse.extract(text)


def main() -> int:
    labels_path = _find_labels(sys.argv)
    if labels_path is None:
        print("找不到 labels_*.json。先标注并导出，或把文件路径作为参数传进来。")
        return 1
    use_llm = "--llm" in sys.argv

    data = json.loads(labels_path.read_text(encoding="utf-8"))
    labeled = list(data.get("labeled") or [])
    if not labeled:
        print(f"{labels_path} 里没有 labeled")
        return 1

    items: dict[str, dict] = {}
    ip = BASE_DIR / "labeling" / "items.json"
    if ip.exists():
        try:
            for it in json.loads(ip.read_text(encoding="utf-8")).get("items") or []:
                items[str(it.get("id"))] = it
        except ValueError:
            pass

    tp = fp = fn = tn = 0
    skipped = 0
    fn_list: list[dict] = []
    fp_list: list[dict] = []
    prescreen_lost: list[str] = []

    for row in labeled:
        remind = str(row.get("remind") or "")
        if remind not in ("yes", "no"):
            skipped += 1
            continue
        texts: list[str] = []
        it = items.get(str(row.get("id")))
        if it:
            texts = [str(m.get("text") or "") for m in it.get("seg") or []]
        if not texts and row.get("text"):
            texts = [str(row.get("text"))]

        got = _pipeline_yes(texts)
        want = remind == "yes"
        if got and want:
            tp += 1
        elif got and not want:
            fp += 1
            fp_list.append(row)
        elif not got and want:
            fn += 1
            fn_list.append(row)
        else:
            tn += 1

        # 预筛安全：人工说该提醒，但这几句里有没有会被预筛跳过的
        if want:
            for t in texts:
                if llm_worker.prescreen_skip(t):
                    prescreen_lost.append(f"[{row.get('id')}] {t[:34]}")
                    break

    total = tp + fp + fn + tn
    precision = tp / (tp + fp) if (tp + fp) else 0.0
    recall = tp / (tp + fn) if (tp + fn) else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) else 0.0

    print("=" * 78)
    print(f"人工标注评分：{labels_path.name}")
    print("=" * 78)
    print(f"有效标注 {total} 条（unsure 跳过 {skipped} 条）")
    print()
    print(f"  该提醒（yes）: {tp + fn}    不该提醒（no）: {fp + tn}")
    print(f"  流水线判提醒: {tp + fp}")
    print()
    print(f"  precision（提醒里有多少是对的）: {precision * 100:.1f}%  ({tp}/{tp + fp})")
    print(f"  recall（该提醒的抓到了多少）  : {recall * 100:.1f}%  ({tp}/{tp + fn})")
    print(f"  F1                            : {f1 * 100:.1f}%")

    if prescreen_lost:
        print()
        print(f"⚠ 预筛会跳过的「该提醒」片段：{len(prescreen_lost)} 条（预筛开启后可能漏）")
        for line in prescreen_lost[:15]:
            print("   " + line)
    else:
        print()
        print("预筛安全检查：没有「该提醒」被预筛跳过。")

    if fp_list:
        print()
        print(f"误报（人工=不用，流水线=提醒）{len(fp_list)} 条：")
        for row in fp_list[:15]:
            print(f"   [{row.get('id')}] {str(row.get('text') or '')[:48]}")

    if fn_list:
        print()
        print(f"漏报（人工=要提醒，流水线=不提醒）{len(fn_list)} 条：")
        for row in fn_list[:15]:
            print(f"   [{row.get('id')}] {str(row.get('text') or '')[:48]}")
        if use_llm:
            saved = 0
            for row in fn_list:
                texts = [str(row.get("text") or "")]
                if _llm_yes([t for t in texts if t]):
                    saved += 1
            print(f"   模型能救回：{saved}/{len(fn_list)}（--llm）")

    print()
    print("=" * 78)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
