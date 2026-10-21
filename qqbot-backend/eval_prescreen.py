# -*- coding: utf-8 -*-
"""规则预筛的 A/B 校验（阶段 1a 的准入门槛）。

只对**会被预筛跳过的**消息调用模型（其余路径完全不变），因此：
  * 非跳过项的前后结果相同，对总体准确率的贡献为 0；
  * 跳过项的前后差异就是本次改动的**全部影响**。

用法：
    .venv\\Scripts\\python.exe -X utf8 eval_prescreen.py

门槛（不达标就别开预筛）：
  1. 被跳过的样本里，标注为「待办/通知/活动/出行计划」的条数 = 0
     （宁可多调模型，也不能漏掉真事项）；
  2. kind 命中数变化 >= -2 条（236 条约等于 1pt）。

注意：只读评测集，不落盘任何新数据。
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

import llm_parse
import llm_worker
import pipeline_proto as RULES

BASE_DIR = Path(__file__).resolve().parent
ACTIONABLE = ("待办", "通知", "活动", "出行计划")


def _load_items() -> list[dict]:
    items: list[dict] = []
    for name in ("eval_set.json", "eval_set_real.json"):
        path = BASE_DIR / name
        if not path.exists():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except ValueError:
            continue
        items.extend(list(data.get("items") or []))
    return items


def main() -> int:
    items = _load_items()
    if not items:
        print("没有评测集")
        return 1

    print("=" * 78)
    print(f"预筛 A/B：{len(items)} 条（仅对会被跳过的样本调用模型）")
    print("=" * 78)
    print(f"开关：QQBOT_LLM_PRESCREEN={'1' if llm_worker._PRESCREEN_ON else '0'}"
          f" · 模型={llm_parse.MODEL} · 可用={llm_parse.available()}")
    print()

    skipped: list[dict] = []
    for it in items:
        if llm_worker.prescreen_skip(it.get("text") or ""):
            skipped.append(it)

    print(f"会被跳过：{len(skipped)} / {len(items)}"
          f"（{100.0 * len(skipped) / len(items):.1f}%）")

    before_ok = 0
    after_ok = 0
    danger: list[str] = []
    changed: list[str] = []
    elapsed = 0.0

    for it in skipped:
        text = it.get("text") or ""
        acceptable = it.get("kind_any") or [it.get("kind")]
        t0 = time.time()
        obj = llm_parse.extract(text)
        elapsed += time.time() - t0
        before_kind = (obj or {}).get("kind") or RULES.classify(text)
        after_kind = RULES.classify(text)
        b_ok = before_kind in acceptable
        a_ok = after_kind in acceptable
        before_ok += 1 if b_ok else 0
        after_ok += 1 if a_ok else 0
        if b_ok != a_ok:
            changed.append(
                f"  [{it.get('id')}] 期望 {'/'.join(acceptable)} | 模型={before_kind}"
                f" → 规则={after_kind} | {text[:26]}"
            )
        if after_kind not in ACTIONABLE and it.get("kind") in ACTIONABLE:
            danger.append(
                f"  [{it.get('id')}] 期望 {it.get('kind')}，预筛后变成 {after_kind}"
                f" | {text[:26]}"
            )

    print()
    print("— 被跳过样本的质量 —")
    print(f"  模型原本命中：{before_ok} / {len(skipped)}")
    print(f"  规则兜底命中：{after_ok} / {len(skipped)}")
    delta = after_ok - before_ok
    print(f"  kind 命中变化：{delta:+d} 条")
    if llm_parse.available() and len(skipped):
        print(f"  省下的模型时间：约 {elapsed:.0f}s（这 {len(skipped)} 条不再调用）")

    if danger:
        print()
        print(f"危险项（期望可执行、预筛后不是可执行）：{len(danger)} 条")
        for line in danger[:20]:
            print(line)
    else:
        print()
        print("危险项：无（被跳过的样本里没有标注为可执行的）")

    if changed:
        print()
        print(f"结论变化的样本（{len(changed)} 条）：")
        for line in changed[:20]:
            print(line)

    print()
    print("=" * 78)
    ok = (len(danger) == 0) and (delta >= -2)
    print("判定：" + ("PASS —— 可以开启预筛" if ok else "FAIL —— 不要开启预筛，或收紧判据"))
    print("=" * 78)
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main())
