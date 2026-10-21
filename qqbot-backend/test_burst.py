# -*- coding: utf-8 -*-
"""解析队列的突发压测（阶段 1c 的验收）。

默认用**打桩解析器**（每条 50ms），只验证队列机制：
  1. 50 条突发不触发降级；
  2. 可执行事项（待办/通知/活动/出行计划）**先于**闲聊出队。

加 `--real` 则走真实模型（约 50×3s，需 Ollama），用于量真实吞吐。

    .venv\\Scripts\\python.exe -X utf8 test_burst.py
    .venv\\Scripts\\python.exe -X utf8 test_burst.py --real
"""

from __future__ import annotations

import os
import sys
import threading
import time

os.environ.setdefault("QQBOT_LLM_WORKERS", "1")

import llm_worker  # noqa: E402

FAKE_MS = 50
N_TOTAL = 50
N_ACTIONABLE = 10

ok_count = 0
fail_count = 0


def check(name: str, cond: bool, detail: str = "") -> None:
    global ok_count, fail_count
    if cond:
        ok_count += 1
        print(f"PASS  {name}  {detail}")
    else:
        fail_count += 1
        print(f"FAIL  {name}  {detail}")


ACTIONABLE_TEXTS = [
    "明天上午9点记得去教学楼交实验报告",
    "通知：本周五截止报名，请大家尽快填写表格",
    "周六下午三点在篮球场集合，参加班级比赛",
    "后天坐高铁返校，记得带学生证",
    "务必在周三前提交课程设计",
    "请大家准时参加班会",
    "今晚八点开会，地点在活动室",
    "记得带上身份证领取材料",
    "下周一开始考试，注意复习",
    "报名链接在群公告，截止到周五",
]
CHAT_TEXTS = ["哈哈哈", "那我先去吃饭了", "有人吗", "感觉今天好热", "咋回事呢",
              "你们在干嘛", "好家伙", "笑死", "收到收到", "行吧"]


def _payloads() -> list[dict]:
    out: list[dict] = []
    for i in range(N_TOTAL):
        if i < N_ACTIONABLE:
            text = ACTIONABLE_TEXTS[i % len(ACTIONABLE_TEXTS)]
        else:
            text = CHAT_TEXTS[i % len(CHAT_TEXTS)] + f" #{i}"
        out.append({
            "msg_id": f"burst_{i}",
            "group_openid": "g_burst",
            "group_label": "压测群",
            "sender": "压测",
            "content": text,
            "timestamp": "2026-10-20 10:00:00",
        })
    return out


def _wait_all(done: threading.Event, timeout_s: float) -> bool:
    return done.wait(timeout=timeout_s)


def main() -> int:
    real = "--real" in sys.argv
    print("=" * 78)
    print(f"解析队列突发压测：{N_TOTAL} 条（可执行 {N_ACTIONABLE} + 闲聊 {N_TOTAL - N_ACTIONABLE}）"
          f" · 模式={'真实模型' if real else f'打桩 {FAKE_MS}ms'}")
    print("=" * 78)

    processed_order: list[str] = []
    done = threading.Event()
    lock = threading.Lock()

    if real:
        saved_parse = llm_worker._parse
        saved_store = llm_worker._store

        def fake_store(payload: dict, parse: dict) -> None:  # type: ignore[no-redef]
            _record(payload)

        def real_parse(payload: dict):  # type: ignore[no-redef]
            return saved_parse(payload)

        llm_worker._parse = real_parse  # type: ignore[assignment]
        llm_worker._store = fake_store  # type: ignore[assignment]
    else:
        def fake_parse(payload: dict):  # type: ignore[no-redef]
            time.sleep(FAKE_MS / 1000.0)
            return {"engine": "rules", "kind": "待办", "title": payload["content"][:10]}

        def fake_store(payload: dict, parse: dict) -> None:  # type: ignore[no-redef]
            _record(payload)

        llm_worker._parse = fake_parse  # type: ignore[assignment]
        llm_worker._store = fake_store  # type: ignore[assignment]

    def _record(payload: dict) -> None:
        with lock:
            processed_order.append(payload["msg_id"])
            if len(processed_order) >= N_TOTAL:
                done.set()

    t0 = time.perf_counter()
    llm_worker.start()
    payloads = _payloads()
    # 先塞闲聊、后塞可执行：如果优先级生效，可执行会插队
    for p in payloads[N_ACTIONABLE:]:
        llm_worker.submit(p)
    for p in payloads[:N_ACTIONABLE]:
        llm_worker.submit(p)

    finished = _wait_all(done, 900 if real else 60)
    elapsed = time.perf_counter() - t0
    st = llm_worker.stats()

    print()
    print(f"总耗时：{elapsed * 1000:.0f} ms")
    print(f"出队顺序（前 12）：{processed_order[:12]}")
    print(f"指标：{st}")

    check("50 条全部处理完", finished and len(processed_order) == N_TOTAL,
          f"{len(processed_order)}/{N_TOTAL}")
    check("没有因队列满降级", int(st.get("degraded") or 0) == 0, str(st.get("degraded")))
    first10 = processed_order[:N_ACTIONABLE]
    # 不假设「哪些文本一定被判成可执行」（那是分类器的职责，不是队列的）；
    # 只验证队列语义：优先级必须单调不降，即所有 prio=0 都排在 prio=1 之前。
    prio_of = {p["msg_id"]: llm_worker._priority_of(p) for p in payloads}
    seq = [prio_of.get(i, 1) for i in processed_order]
    monotonic = all(seq[k] <= seq[k + 1] for k in range(len(seq) - 1))
    n_prio0 = sum(1 for v in prio_of.values() if v == 0)
    check("可执行事项优先出队（优先级单调）", monotonic, f"prio0={n_prio0} 前10={first10}")

    if real:
        avg = elapsed / max(1, len(processed_order))
        print()
        print(f"平均每条：{avg * 1000:.0f} ms（用于对比 workers=1 vs 2）")

    print()
    print("=" * 78)
    print(f"结果：通过 {ok_count} 项，失败 {fail_count} 项")
    print("=" * 78)
    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
