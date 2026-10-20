# -*- coding: utf-8 -*-
"""端到端自测：ingest_group_message -> 后台线程（小模型/规则）-> window_since 带 parse。

不依赖 QQ、不依赖设备授权（直接写 STORE），只验证「消息进窗口时是否已带结构化 parse」。
运行：.venv\\Scripts\\python.exe -X utf8 test_llm_e2e.py
"""

from __future__ import annotations

import json
import sys
import time

import pipeline_proto
import relay
import llm_worker

GID = "TEST_GROUP_PARSE_E2E"

SAMPLES = [
    ("张静雯", "【通知】原定5月27日下午2:30主D104的心理委员培训，改为6月3日周三下午2:30在主楼D104，"
              "全体心理委员和宿舍长参加，不能参加者提前向辅导员请假。"),
    ("硫酸Cu", "明天去超市买点吃的"),
    ("郑源旭", "没签到签退咋办😯"),
    ("陈皖", "【个人资料补订】还有需要各科期末历年题详解的同学自行在下面登记，"
            "快递2-3天左右送达学校驿站，留意短信提醒。"),
    ("Oliver", "智慧社区签到签退码，请心理委员转发给各班同学一下"),
]


def main() -> int:
    llm_worker.start()
    print("worker enabled:", llm_worker.enabled())

    dev = relay.STORE.register_device("e2e-test")
    did = dev["device_id"]
    relay.STORE.subscribe(did, GID)
    print("device:", did)

    for i, (sender, content) in enumerate(SAMPLES):
        info = relay.ingest_group_message(GID, sender, content, msg_id=f"e2e_{i}")
        print(f"  ingest[{i}] -> {info}")

    deadline = time.time() + 90
    got: list[dict] = []
    while time.time() < deadline:
        got = relay.window_since(did, 0)["messages"]
        if len(got) >= len(SAMPLES):
            break
        time.sleep(1)

    print(f"\n窗口内消息数 = {len(got)} / {len(SAMPLES)}\n")
    failures = 0
    for m in got:
        p = m.get("parse")
        if not p:
            print(f"[X] seq={m.get('seq')} 没有 parse")
            failures += 1
            continue
        print(f"[{p.get('engine')}] kind={p.get('kind')} cat={p.get('category')} conf={p.get('confidence')}")
        print(f"     summary : {p.get('summary')}")
        print(f"     time    : {p.get('timeText')} -> {p.get('timeNormalized')}")
        print(f"     slots   : place={p.get('place')!r} who={p.get('who')!r} deadline={p.get('deadline')!r}")
        # 断言：字段值必须能在原文（已归一化）里找到
        src = pipeline_proto.normalize(m.get("content") or "")
        for key in ("action", "place", "who", "deadline", "timeText"):
            v = p.get(key) or ""
            if v and v not in src:
                print(f"[X] 字段 {key}={v!r} 不是原文子串（幻觉护栏失效）")
                failures += 1
        print()

    engines = [m["parse"]["engine"] for m in got if m.get("parse")]
    print("engine 统计:", {e: engines.count(e) for e in set(engines)})
    print("FAILURES:", failures)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
