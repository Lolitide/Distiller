# -*- coding: utf-8 -*-
"""小模型横向评测：用同一套真实语料标签，比较不同模型在「分级 / 时间 / 地点 / 幻觉」上的表现。

用法：
    .venv\\Scripts\\python.exe -X utf8 eval_llm.py qwen3:4b qwen3.5:4b qwen3:8b

不传参数则只评测 `llm_parse.MODEL` 当前值。
结果同时写到 `eval_results_<模型>.json`，方便对比。

指标口径：
  kind  : 分类正确率（六选一枚举）
  time  : 时间「原话」正确率（空↔空；非空要求与标注一致或互相包含）
  place : 地点「原话」正确率（同上）
  幻觉率 : 模型产出的结构化字段不是原文子串、被安全闸清空的比例（越低越好）
  召回   : 摘要里包含 must_contain 关键信息的比例（衡量"有没有漏关键点"）
  未产出 : extract 直接返回 None（枚举不合法/无有效字段）的比例 → 会回退规则
"""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

import llm_parse  # noqa: E402
import pipeline_proto as RULES  # noqa: E402

EVAL_PATH = BASE_DIR / "eval_set.json"


def _load() -> dict:
    data = json.loads(EVAL_PATH.read_text(encoding="utf-8"))
    items = list(data["items"])
    # 追加「真实语料抽样」那一批（标签见 eval_set_real.json 的生成脚本）
    extra = BASE_DIR / "eval_set_real.json"
    if extra.exists():
        try:
            items += json.loads(extra.read_text(encoding="utf-8"))["items"]
        except (ValueError, KeyError):
            pass
    data["items"] = items
    return data


def _match(expected: str, got: str) -> bool:
    """判定两个"原话片段"是否算命中（要求一致或互相包含，容忍模型多带了修饰）。"""
    e, g = (expected or "").strip(), (got or "").strip()
    if not e and not g:
        return True
    if not e or not g:
        return False
    return e in g or g in e


def evaluate(model: str, data: dict, label: str | None = None, verbose: bool = True) -> dict:
    llm_parse.MODEL = model
    name = label or model
    items = data["items"]
    total = len(items)
    stats = {"kind": 0, "time": 0, "place": 0, "must_hit": 0, "must_total": 0,
             "halluc": 0, "none": 0, "n_time": 0, "n_place": 0}
    fails: list[str] = []
    elapsed = 0.0

    for it in items:
        t0 = time.time()
        obj = llm_parse.extract(it["text"])
        elapsed += time.time() - t0

        if obj is None:
            stats["none"] += 1
            fails.append(f"  [{it['id']}] 未产出（回退规则）: {it['text'][:30]}")
            continue

        if obj.get("_nullified"):
            stats["halluc"] += 1

        # 标注有歧义的样本用 kind_any：命中任意一个都算对
        acceptable = it.get("kind_any") or [it["kind"]]
        if obj.get("kind") in acceptable:
            stats["kind"] += 1
        else:
            fails.append(f"  [{it['id']}] kind: 期望 {'/'.join(acceptable)} 得到 {obj.get('kind')} | {it['text'][:30]}")

        # 只对「标注里声明了」的字段计分（闲聊样本不该因为模型多抽了个时间就算错）
        if "time_text" in it:
            stats["n_time"] += 1
            if _match(it["time_text"], obj.get("time_text", "")):
                stats["time"] += 1
            else:
                fails.append(f"  [{it['id']}] time: 期望 {it['time_text']!r} 得到 {obj.get('time_text')!r} | {it['text'][:30]}")

        if "place" in it:
            stats["n_place"] += 1
            if _match(it["place"], obj.get("place", "")):
                stats["place"] += 1
            else:
                fails.append(f"  [{it['id']}] place: 期望 {it['place']!r} 得到 {obj.get('place')!r} | {it['text'][:30]}")

        # 摘要召回：must_contain 里的关键信息有没有出现在 summary
        must = it.get("must_contain") or []
        if must:
            summary = obj.get("summary") or ""
            for key in must:
                stats["must_total"] += 1
                if key in summary:
                    stats["must_hit"] += 1

    n = total or 1
    result = {
        "model": name,
        "total": total,
        "kind_acc": round(stats["kind"] / n, 4),
        "time_acc": round(stats["time"] / stats["n_time"], 4) if stats["n_time"] else None,
        "place_acc": round(stats["place"] / stats["n_place"], 4) if stats["n_place"] else None,
        "halluc_rate": round(stats["halluc"] / n, 4),
        "must_recall": round(stats["must_hit"] / stats["must_total"], 4) if stats["must_total"] else None,
        "no_output_rate": round(stats["none"] / n, 4),
        "avg_latency_s": round(elapsed / n, 2),
        "fails": fails,
    }
    if verbose:
        print(f"\n===== {name} =====")
        print(f"  kind 分类正确率 : {result['kind_acc']:.1%}  ({stats['kind']}/{total})")
        print(f"  时间原话正确率  : {result['time_acc'] if result['time_acc'] is None else format(result['time_acc'], '.1%')}")
        print(f"  地点原话正确率  : {result['place_acc'] if result['place_acc'] is None else format(result['place_acc'], '.1%')}")
        print(f"  幻觉率(字段编造): {result['halluc_rate']:.1%}")
        print(f"  摘要关键信息召回: {result['must_recall'] if result['must_recall'] is None else format(result['must_recall'], '.1%')}")
        print(f"  未产出(回退规则): {result['no_output_rate']:.1%}")
        print(f"  平均单条耗时    : {result['avg_latency_s']}s")
        if fails:
            print(f"  ---- 失败明细（前 25 条）----")
            print("\n".join(fails[:25]))
    return result


def main() -> int:
    data = _load()
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    variants = [a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--prompt=")] or ["base"]
    models = args or [llm_parse.MODEL]
    print(f"评测集 {EVAL_PATH.name}：{len(data['items'])} 条；base_time={data['base_time']}；prompt={variants}")
    results = []
    for variant in variants:
        if not llm_parse.set_prompt(variant):
            print(f"未知 prompt 变体：{variant}")
            return 1
        for model in models:
            r = evaluate(model, data, label=f"{model} [{variant}]")
            r["variant"] = variant
            results.append(r)
    if len(results) > 1:
        print("\n===== 对比汇总 =====")
        print(f"{'模型[prompt]':<26}{'kind':>8}{'time':>8}{'place':>8}{'幻觉':>8}{'召回':>8}{'未产出':>8}{'耗时':>8}")
        for r in results:
            rec = "-" if r["must_recall"] is None else f"{r['must_recall']:.0%}"
            t = "-" if r["time_acc"] is None else f"{r['time_acc']:.1%}"
            pl = "-" if r["place_acc"] is None else f"{r['place_acc']:.1%}"
            print(f"{r['model']:<26}{r['kind_acc']:>8.1%}{t:>8}{pl:>8}"
                  f"{r['halluc_rate']:>8.1%}{rec:>8}{r['no_output_rate']:>8.1%}{r['avg_latency_s']:>7.2f}s")
    out = BASE_DIR / "eval_results.json"
    out.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n结果已写入 {out.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
