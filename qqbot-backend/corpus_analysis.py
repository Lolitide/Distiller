# -*- coding: utf-8 -*-
"""群聊语料分析：统计 + 分级分布 + 新词/黑话候选挖掘（零依赖）。

用途：用真实的学生群聊天记录，回测我们的分级/抽取能力，并从**自己的语料**里挖
校园黑话候选（结论：现成黑话词库不存在，只能自己挖）。

运行：
    .venv\\Scripts\\python.exe -X utf8 corpus_analysis.py [语料目录]

输入：QQChatExporter V5 导出的 .txt（形如
    <发送者>:
    时间: YYYY-MM-DD HH:MM:SS
    内容: <正文>
）
"""

from __future__ import annotations

import glob
import json
import math
import os
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

import pipeline_proto as RULES  # noqa: E402

DEFAULT_DIR = BASE_DIR.parent / "聊天记录"

_META_KEYS = ("聊天名称:", "聊天类型:", "导出时间:", "消息总数:", "时间范围:")
_CJK = re.compile(r"[\u4e00-\u9fa5]+")
_NOISE_CHARS = re.compile(r"\[[^\]]*\]|@某人|\[链接\]")
# 系统消息 / 拍一拍 / 加群提示：复用 pipeline_proto 的定义（唯一真值源）
_SYSTEM_RE = RULES._SYSTEM_RE

# 新词挖掘参数
MIN_N, MAX_N = 2, 5          # 候选词长度范围
MIN_FREQ = 20                # 最低出现次数
MAX_FREQ = 4000              # 上限：太高频的是通用词（可以/什么/这个），不是黑话
MIN_ENTROPY = 1.2            # 左右邻字最低熵（太低说明只是固定搭配的一部分）
MIN_PMI = 0.5                # 内部凝聚度：最差切分的 PMI 下限（log2 尺度，0.5≈adjacent 显著共现）
TOPN = 60


def parse_export(path: str) -> tuple[dict, list[dict]]:
    """解析一个导出文件（.txt 或 *_chunked_jsonl 目录）-> (元信息, 消息列表)。"""
    if os.path.isdir(path):
        return parse_jsonl_dir(path)
    return parse_txt_export(path)


def parse_jsonl_dir(path: str) -> tuple[dict, list[dict]]:
    """解析 QQChatExporter 的 chunked jsonl 导出目录（manifest.json + chunks/*.jsonl）。

    记录格式：{"id","seq","time":"2026-09-26T16:01:23.000Z","sender":{name,groupCard},
              "type":"text|system|json|reply|...","content":{"text":...},"recalled":bool}
    """
    meta: dict = {"file": os.path.basename(path.rstrip("\\/"))}
    try:
        man = json.loads((Path(path) / "manifest.json").read_text(encoding="utf-8", errors="replace"))
        info = man.get("chatInfo") or {}
        meta["group"] = str(info.get("name") or meta["file"])
        stat = man.get("statistics") or {}
        rng = stat.get("timeRange") or {}
        meta["span"] = f"{rng.get('start','')} - {rng.get('end','')}"
    except (OSError, ValueError):
        meta["group"] = meta["file"]

    msgs: list[dict] = []
    for chunk in sorted(glob.glob(str(Path(path) / "chunks" / "*.jsonl"))):
        with open(chunk, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except ValueError:
                    continue
                if rec.get("type") == "system" or rec.get("system") or rec.get("recalled"):
                    continue
                content = rec.get("content") or {}
                text = content.get("text") if isinstance(content, dict) else str(content)
                if not text:
                    continue
                sender = rec.get("sender") or {}
                msgs.append({
                    "group": meta["group"],
                    "sender": str(sender.get("groupCard") or sender.get("name") or sender.get("nickname") or ""),
                    "timestamp": _iso_to_local(str(rec.get("time") or "")),
                    "content": str(text),
                })
    meta["parsed"] = len(msgs)
    return meta, msgs


def _iso_to_local(iso: str) -> str:
    """2026-09-26T16:01:23.000Z -> 2026-09-27 00:01:23（东八区）。"""
    if not iso:
        return ""
    try:
        dt = datetime.strptime(iso[:19], "%Y-%m-%dT%H:%M:%S") + timedelta(hours=8)
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except ValueError:
        return iso


def parse_txt_export(path: str) -> tuple[dict, list[dict]]:
    """解析一个导出文件 -> (元信息, 消息列表)。"""
    meta: dict = {"file": os.path.basename(path)}
    msgs: list[dict] = []
    sender = None
    ts = ""
    with open(path, encoding="utf-8", errors="replace") as fh:
        for raw in fh:
            line = raw.rstrip("\n")
            if not line.strip():
                continue
            if line.startswith("聊天名称:"):
                meta["group"] = line.split(":", 1)[1].strip()
                continue
            if line.startswith("时间范围:"):
                meta["span"] = line.split(":", 1)[1].strip()
                continue
            if line.startswith("消息总数:"):
                meta["declared"] = line.split(":", 1)[1].strip()
                continue
            if any(line.startswith(k) for k in _META_KEYS) or line.startswith("[") or line.startswith("====") or line.strip().startswith("QQ聊天记录"):
                continue
            if line.startswith("时间:"):
                ts = line.split(":", 1)[1].strip()
                continue
            if line.startswith("内容:"):
                content = line.split(":", 1)[1].strip()
                if sender and content:
                    msgs.append({
                        "group": meta.get("group", ""),
                        "sender": sender,
                        "timestamp": ts,
                        "content": content,
                    })
                sender = None
                continue
            if line.endswith(":"):
                sender = line[:-1].strip()
    meta["parsed"] = len(msgs)
    return meta, msgs


def load_corpus(directory: Path) -> list[dict]:
    all_msgs: list[dict] = []
    metas: list[dict] = []
    for path in sorted(glob.glob(str(directory / "*.txt")) + glob.glob(str(directory / "*_chunked_jsonl"))):
        meta, msgs = parse_export(path)
        metas.append(meta)
        all_msgs.extend(msgs)
    print("=" * 78)
    print("一、语料规模")
    print("=" * 78)
    for m in sorted(metas, key=lambda x: -x.get("parsed", 0)):
        print(f"  {m.get('parsed', 0):6d} 条  {m.get('group','?')}   ({m.get('span','')})")
    span_min = min((x["timestamp"] for x in all_msgs if x["timestamp"]), default="")
    span_max = max((x["timestamp"] for x in all_msgs if x["timestamp"]), default="")
    print(f"\n  合计 {len(all_msgs)} 条 / {len(metas)} 个群")
    print(f"  时间范围 {span_min} ~ {span_max}")
    print(f"  发言人数 {len({x['sender'] for x in all_msgs})}")
    return all_msgs


def classify_stats(msgs: list[dict]) -> None:
    print()
    print("=" * 78)
    print("二、用现有规则分级（pipeline_proto.classify）在真实语料上的表现")
    print("=" * 78)
    kinds: Counter = Counter()
    triggers: Counter = Counter()
    sys_count = 0
    samples: dict[str, list[str]] = defaultdict(list)
    for m in msgs:
        text = RULES.normalize(m["content"])
        if _SYSTEM_RE.search(text):
            sys_count += 1
            continue
        kind = RULES.classify(text)
        kinds[kind] += 1
        if kind == RULES.EVENT_TODO:
            # 归因到「实际命中的判据」，而不是旧的裸关键词
            if RULES._TASK_STRONG_RE.search(text):
                triggers["<强任务词>" + RULES._TASK_STRONG_RE.search(text).group(0)] += 1
            m = RULES._TASK_COLLOC_RE.search(text)
            if m:
                triggers["<搭配>" + m.group(0)[:8]] += 1
        if kind in (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_PLAN) and len(samples[kind]) < 10:
            samples[kind].append(text[:56])
    total = sum(kinds.values()) or 1
    print(f"  系统消息/拍一拍等噪声：{sys_count} 条（已剔除，不计入分级）\n")
    for kind, count in kinds.most_common():
        print(f"  {kind:6s} {count:7d}  ({count * 100 / total:5.1f}%)")
    print("\n  —— 「待办」的触发词归因（哪个词最常把它误判成待办）——")
    for w, c in triggers.most_common(12):
        print(f"    {c:7d}  {w}")
    print("\n  —— 误判样本 ——")
    for kind in (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_PLAN):
        if samples.get(kind):
            print(f"\n  [{kind}]")
            for s in samples[kind][:6]:
                print(f"    · {s}")


def _entropy(counter: Counter) -> float:
    total = sum(counter.values())
    if total <= 0:
        return 0.0
    return -sum((c / total) * math.log(c / total) for c in counter.values())


def mine_new_words(msgs: list[dict]) -> None:
    print()
    print("=" * 78)
    print("三、新词/黑话候选（频次 + 左右邻熵 + 内部凝聚度PMI，从语料自身挖）")
    print("=" * 78)
    grams: Counter = Counter()
    left: dict[str, Counter] = defaultdict(Counter)
    right: dict[str, Counter] = defaultdict(Counter)
    char_total = 0

    for m in msgs:
        text = RULES.normalize(m["content"])
        if _SYSTEM_RE.search(text):
            continue
        text = _NOISE_CHARS.sub("", text)
        for run in _CJK.findall(text):
            length = len(run)
            char_total += length
            # 注意：n 从 1 开始，否则 2 字词的切开部分（单字）取不到频率，PMI 恒为 0
            for n in range(1, MAX_N + 1):
                for i in range(length - n + 1):
                    g = run[i:i + n]
                    grams[g] += 1
                    if n >= MIN_N:
                        if i > 0:
                            left[g][run[i - 1]] += 1
                        if i + n < length:
                            right[g][run[i + n]] += 1

    total_grams = char_total or 1
    scored: list[tuple[float, str, int]] = []
    for g, freq in grams.items():
        if len(g) < MIN_N:
            continue
        if freq < MIN_FREQ or freq > MAX_FREQ:
            continue
        lb, rb = _entropy(left[g]), _entropy(right[g])
        if min(lb, rb) < MIN_ENTROPY:
            continue
        # 内部凝聚度：最差切分的 PMI（真正的词，切开的概率会显著低于整体）
        n = len(g)
        cohesion = float("inf")
        for k in range(1, n):
            a, b = g[:k], g[k:]
            fa, fb = grams.get(a, 0), grams.get(b, 0)
            if fa <= 0 or fb <= 0:
                cohesion = 0.0
                break
            pmi = math.log2((freq / total_grams) / ((fa / total_grams) * (fb / total_grams)))
            cohesion = min(cohesion, pmi)
        if cohesion == float("inf") or cohesion < MIN_PMI:
            continue
        scored.append((cohesion * min(lb, rb) * math.log(freq + 1), g, freq))
    scored.sort(reverse=True)

    picked: list[tuple[float, str, int]] = []
    for score, g, freq in scored:
        if any(g in p and freq <= p_freq * 1.05 for _, p, p_freq in picked):
            continue
        picked.append((score, g, freq))
        if len(picked) >= TOPN:
            break

    print(f"  n-gram {len(grams)} 个 → 过阈(freq {MIN_FREQ}~{MAX_FREQ}, 熵>={MIN_ENTROPY}, PMI>={MIN_PMI}) → top {len(picked)}：\n")
    for _, g, freq in picked:
        print(f"    {freq:6d}  {g}")


def main() -> int:
    directory = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DIR
    if not directory.exists():
        print(f"找不到语料目录：{directory}")
        return 1
    msgs = load_corpus(directory)
    if not msgs:
        print("没有解析到消息，检查导出格式。")
        return 1
    classify_stats(msgs)
    mine_new_words(msgs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
