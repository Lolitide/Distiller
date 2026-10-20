# -*- coding: utf-8 -*-
"""生成「人工标注包」：从真实语料分层抽样 + 产出一个**单文件、离线可用**的网页标注器。

为什么要有这个东西：
    现有 236 条评测集的标签是 AI 标的，有"AI 味道"的风险。
    「这条该不该提醒我」是**产品价值判断**，只能由人来定；AI 只能按枚举定义往里塞。
    所以这里只问人三件人能回答的事（见 labeler.html 顶部说明），
    再由脚本把它换算成"提醒"的 precision / recall。

用法：
    .venv\\Scripts\\python.exe -X utf8 make_labeling_kit.py [--n 300]
    然后**双击** labeling\\labeler.html → 标注 → 点「导出 JSON」
"""

from __future__ import annotations

import argparse
import glob
import json
import random
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

import pipeline_proto as RULES  # noqa: E402
from corpus_analysis import parse_export  # noqa: E402

CORPUS_DIR = BASE_DIR.parent / "聊天记录"
OUT_DIR = BASE_DIR / "labeling"
SEED = 20261014


def _skip_texts() -> set[str]:
    """已经标注过的文本（两个评测集），不重复抽样。"""
    seen: set[str] = set()
    for name in ("eval_set.json", "eval_set_real.json"):
        p = BASE_DIR / name
        if not p.exists():
            continue
        try:
            for it in json.loads(p.read_text(encoding="utf-8"))["items"]:
                seen.add(it["text"])
        except (ValueError, KeyError):
            pass
    return seen


def _segments(msgs: list[dict], gap_minutes: int = 15, max_len: int = 12) -> list[list[dict]]:
    """把某个群的消息切成「对话片段」：间隔 > gap 或长度超 max_len 就断开。

    为什么按片段而不是单条：聊天消息**离开上下文无法判断**
    （「对」「12月吧」「有啥」单看永远是闲聊；「蓝桥杯比赛」+「12月11号」合起来才是活动）。
    而且产品的单位本来就是「一段对话」（候选/簇），按单条标注测的不是产品行为。
    """
    ordered = sorted(msgs, key=lambda m: str(m.get("timestamp") or ""))
    out: list[list[dict]] = []
    cur: list[dict] = []
    for m in ordered:
        if cur:
            prev = RULES._parse_ts(str(cur[-1].get("timestamp") or ""))
            now = RULES._parse_ts(str(m.get("timestamp") or ""))
            if abs((now - prev).total_seconds()) > gap_minutes * 60 or len(cur) >= max_len:
                out.append(cur)
                cur = []
        cur.append(m)
    if cur:
        out.append(cur)
    return out


def sample(n: int) -> list[dict]:
    """分层抽样**对话片段**：一半是「现有规则认为含实义」的，一半是其余。

    这样既能测**误报**（把闲聊对话当成提醒），也能测**漏报**（该提醒的没提醒）。
    """
    already = _skip_texts()
    hot: list[dict] = []      # 片段里现有规则判为有实义
    cold: list[dict] = []     # 纯闲聊/忽略
    seen: set[str] = set()

    for path in sorted(glob.glob(str(CORPUS_DIR / "*.txt"))
                       + glob.glob(str(CORPUS_DIR / "*_chunked_jsonl"))):
        meta, msgs = parse_export(path)
        group = (meta.get("group") or "")[:18]
        clean: list[dict] = []
        for m in msgs:
            text = RULES.normalize(m.get("content") or "")
            if not text or RULES._SYSTEM_RE.search(text):
                continue
            clean.append({"text": text, "sender": (m.get("sender") or "")[:10],
                          "timestamp": str(m.get("timestamp") or "")})
        for seg in _segments(clean):
            texts = [x["text"] for x in seg]
            key = "|".join(texts)[:60]
            if key in seen:
                continue
            # 片段里只要有一条被现有规则判为有实义，就归入 hot
            hot_seg = False
            for it in seg:
                k = RULES.classify(it["text"])
                if k in (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_ACTIVITY, RULES.EVENT_PLAN):
                    hot_seg = True
                    break
            joined = " ".join(texts)
            if joined in already or any(t in already for t in texts):
                continue
            seen.add(key)
            item = {"group": group, "seg": seg}
            (hot if hot_seg else cold).append(item)

    random.seed(SEED)
    random.shuffle(hot)
    random.shuffle(cold)
    half = n // 2
    picked = hot[:half] + cold[: n - half]
    random.shuffle(picked)
    for i, it in enumerate(picked, 1):
        it["id"] = f"L{i:04d}"
    return picked


_HTML = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8" />
<title>知了 · 消息标注</title>
<style>
  body { font-family: -apple-system, "Microsoft YaHei", sans-serif; margin: 0; background: #f5f6f8; color: #222; }
  .wrap { max-width: 760px; margin: 0 auto; padding: 16px; }
  .bar { height: 6px; background: #e5e7eb; border-radius: 3px; overflow: hidden; margin-bottom: 12px; }
  .bar > i { display: block; height: 100%; background: #2E75B6; width: 0; }
  .meta { font-size: 13px; color: #666; margin-bottom: 6px; }
  .card { background: #fff; border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px; }
  .text { font-size: 17px; line-height: 1.5; margin: 8px 0 18px; }
  .line { padding: 5px 8px; border-left: 3px solid transparent; margin-bottom: 2px; }
  .line:nth-child(even) { background: #fafbfc; }
  .line.img { color: #a08000; background: #fffbe6; border-left-color: #f0c000; }
  .who { color: #8a8f98; font-size: 12px; margin-right: 8px; }
  .q { font-size: 13px; color: #444; margin: 14px 0 8px; font-weight: 600; }
  button { font: inherit; font-size: 15px; padding: 9px 14px; margin: 0 8px 8px 0; border-radius: 8px;
           border: 1px solid #d0d5dd; background: #fff; cursor: pointer; }
  button:hover { border-color: #2E75B6; }
  button.sel { background: #2E75B6; color: #fff; border-color: #2E75B6; }
  input { font: inherit; font-size: 15px; padding: 8px 10px; border-radius: 8px; border: 1px solid #d0d5dd; width: 92%; }
  .hint { font-size: 12px; color: #999; margin-top: 10px; line-height: 1.7; }
  .row { display: flex; justify-content: space-between; align-items: center; margin-top: 14px; }
  .k { font-size: 11px; color: #999; }
  .done { text-align: center; padding: 40px 0; }
  .btn2 { background: #2E75B6; color: #fff; border-color: #2E75B6; }
</style>
</head>
<body>
<div class="wrap">
  <div class="bar"><i id="pbar"></i></div>
  <div class="meta" id="meta"></div>

  <div class="card" id="card">
    <div class="text" id="text"></div>

    <div class="q">1. 这段对话，你会想让 App 提醒你吗？（1 / 2 / 3）</div>
    <div id="q1"></div>

    <div id="q2box" style="display:none">
      <div class="q">2. 最关键的信息是哪个？（4 / 5 / 6 / 7 / 8）</div>
      <div id="q2"></div>
    </div>

    <div class="q">3. 这段里有没有「新生 / 外人不一定懂」的词？<span style="font-weight:400;color:#888">（你自己看得懂也要填 —— 正因为你看得懂，才知道哪些是门槛）</span></div>
    <input id="slang" placeholder="例如：开打、苕皮、组队、上号 —— 用、分隔；没有就留空" />

    <div class="row">
      <span class="k">空格/回车 = 下一条（未选会记为「拿不准」）</span>
      <button id="prev">上一条</button>
    </div>
  </div>

  <div class="done" id="done" style="display:none">
    <h2>标完了，谢谢！</h2>
    <p style="color:#666">点下面的按钮导出，把文件发回来即可。</p>
    <button class="btn2" id="export2">导出 JSON</button>
  </div>

  <div class="row" style="margin-top:18px">
    <span class="k" id="cnt"></span>
    <span>
      <button id="export">导出 JSON</button>
      <button id="load">导入上次进度</button>
      <input id="file" type="file" accept=".json" style="display:none" />
    </span>
  </div>
  <div class="hint">
    进度自动存在浏览器本地；换浏览器/清了缓存就用「导出 → 导入上次进度」续上。<br />
    <b>单位是「一段对话」</b>（同一群、连续的一小段聊天）—— 单条消息往往判断不了，请整段看完再答。<br />
    <b style="color:#a08000">黄底行 = 图片消息</b>：导出文件里不含图片内容，看不到就别猜，直接选「拿不准」。<br />
    只判「该不该提醒」和「最关键的信息」，<b>不用管属于哪一类</b>（那是后端的事）。<br />
    第 3 问请<b>站在新生的角度</b>想：这个词如果是个刚入学的人看到，会不会懵？会懵就填。
    这些词会进「按群词表」，让模型认识你们学校的说法（你自己懂不算，别漏了）。
  </div>
</div>

<script id="data" type="application/json">__ITEMS__</script>
<script>
const ITEMS = JSON.parse(document.getElementById('data').textContent);
const KEY = 'zhiliao_labels_v1';
const K1 = [['yes','要提醒'],['no','不用'],['unsure','拿不准']];
const K2 = [['time','时间'],['place','地点'],['who','谁'],['action','要做什么'],['unknown','不确定']];
let labels = {};
let i = 0;
let cur1 = '', cur2 = '';

function loadLS() { try { labels = JSON.parse(localStorage.getItem(KEY) || '{}'); } catch (e) { labels = {}; } }
function saveLS() { try { localStorage.setItem(KEY, JSON.stringify(labels)); } catch (e) {} }

function firstUnlabeled() {
  for (let k = 0; k < ITEMS.length; k++) { if (!labels[ITEMS[k].id]) { return k; } }
  return ITEMS.length;
}

function render() {
  const total = ITEMS.length;
  const done = Object.keys(labels).length;
  document.getElementById('pbar').style.width = (total ? (done * 100 / total) : 0) + '%';
  document.getElementById('cnt').textContent = '已标 ' + done + ' / ' + total;
  if (i >= total) {
    document.getElementById('card').style.display = 'none';
    document.getElementById('done').style.display = 'block';
    document.getElementById('meta').textContent = '全部完成';
    return;
  }
  document.getElementById('card').style.display = 'block';
  document.getElementById('done').style.display = 'none';
  const it = ITEMS[i];
  document.getElementById('meta').textContent = (i + 1) + ' / ' + total + '   ·   群：' + (it.group || '未知')
    + '   ·   ' + it.seg.length + ' 条消息';
  const box = document.getElementById('text');
  box.innerHTML = '';
  it.seg.forEach(function (m) {
    const line = document.createElement('div');
    const raw = m.text;
    const isImg = /^\\s*\\[图片[:：]/.test(raw);
    line.className = isImg ? 'line img' : 'line';
    const who = document.createElement('span');
    who.className = 'who';
    who.textContent = (m.timestamp && m.timestamp.length >= 16 ? m.timestamp.slice(11, 16) + ' ' : '') + (m.sender || '');
    const tx = document.createElement('span');
    // 导出文件里**没有图片内容**（只有占位符），所以别让标注者瞎猜
    tx.textContent = isImg ? '[图片 · 内容未知（导出未含图片）]' : raw;
    line.appendChild(who);
    line.appendChild(tx);
    box.appendChild(line);
  });

  const saved = labels[it.id] || {};
  cur1 = saved.remind || '';
  cur2 = saved.focus || '';
  document.getElementById('slang').value = (saved.slang || []).join('、');
  drawQ(K1, 'q1', cur1);
  drawQ(K2, 'q2', cur2);
  document.getElementById('q2box').style.display = cur1 === 'yes' ? 'block' : 'none';
  document.getElementById('slang').focus();
}

function drawQ(opts, box, sel) {
  const el = document.getElementById(box);
  el.innerHTML = '';
  opts.forEach(function (o, idx) {
    const b = document.createElement('button');
    b.textContent = o[1] + '  (' + (box === 'q1' ? (idx + 1) : (idx + 4)) + ')';
    if (o[0] === sel) { b.className = 'sel'; }
    b.onclick = function () {
      if (box === 'q1') { cur1 = o[0]; if (cur1 !== 'yes') { cur2 = ''; } }
      else { cur2 = o[0]; }
      commit();
      drawQ(opts, box, box === 'q1' ? cur1 : cur2);
      document.getElementById('q2box').style.display = cur1 === 'yes' ? 'block' : 'none';
    };
    el.appendChild(b);
  });
}

function commit() {
  const it = ITEMS[i];
  if (!it) { return; }
  const slang = document.getElementById('slang').value.split(/[、,，\\s]+/).filter(function (s) { return s.length > 0; });
  const texts = it.seg.map(function (m) { return m.text; });
  labels[it.id] = { text: texts.join(' '), n: texts.length, group: it.group,
                    remind: cur1 || 'unsure', focus: cur2 || '', slang: slang };
  saveLS();
  document.getElementById('pbar').style.width = (Object.keys(labels).length * 100 / ITEMS.length) + '%';
  document.getElementById('cnt').textContent = '已标 ' + Object.keys(labels).length + ' / ' + ITEMS.length;
}

function next() { commit(); if (i < ITEMS.length - 1) { i++; } else { i = ITEMS.length; } render(); }
function prev() { commit(); if (i > 0) { i--; } render(); }

document.addEventListener('keydown', function (e) {
  const tag = (e.target && e.target.tagName) || '';
  if (tag === 'INPUT' && e.key !== 'Enter') { return; }
  if (e.key === 'Enter' || e.key === ' ') {
    if (tag === 'INPUT') { document.activeElement.blur(); }
    e.preventDefault(); next(); return;
  }
  const n = parseInt(e.key, 10);
  if (e.key === '1') { cur1 = 'yes'; commit(); render(); }
  else if (e.key === '2') { cur1 = 'no'; cur2 = ''; commit(); render(); }
  else if (e.key === '3') { cur1 = 'unsure'; cur2 = ''; commit(); render(); }
  else if (e.key === '4' && cur1 === 'yes') { cur2 = 'time'; commit(); render(); }
  else if (e.key === '5' && cur1 === 'yes') { cur2 = 'place'; commit(); render(); }
  else if (e.key === '6' && cur1 === 'yes') { cur2 = 'who'; commit(); render(); }
  else if (e.key === '7' && cur1 === 'yes') { cur2 = 'action'; commit(); render(); }
  else if (e.key === '8' && cur1 === 'yes') { cur2 = 'unknown'; commit(); render(); }
});

function exportJSON() {
  commit();
  const out = { version: 1, labeled: Object.keys(labels).map(function (k) { return Object.assign({ id: k }, labels[k]); }) };
  const blob = new Blob([JSON.stringify(out, null, 1)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'labels_' + new Date().toISOString().slice(0, 10) + '.json';
  a.click();
}

document.getElementById('prev').onclick = prev;
document.getElementById('export').onclick = exportJSON;
document.getElementById('export2').onclick = exportJSON;
document.getElementById('load').onclick = function () { document.getElementById('file').click(); };
document.getElementById('file').onchange = function (e) {
  const f = e.target.files[0];
  if (!f) { return; }
  const r = new FileReader();
  r.onload = function () {
    try {
      const o = JSON.parse(r.result);
      (o.labeled || []).forEach(function (x) { labels[x.id] = x; });
      saveLS(); i = firstUnlabeled(); render();
    } catch (err) { alert('文件读不了：' + err); }
  };
  r.readAsText(f);
};

loadLS();
i = firstUnlabeled();
render();
</script>
</body>
</html>
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=300, help="抽样条数（默认 300）")
    args = ap.parse_args()

    items = sample(args.n)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "items.json").write_text(
        json.dumps({"version": 1, "items": items}, ensure_ascii=False, indent=1), encoding="utf-8")

    payload = json.dumps(items, ensure_ascii=False).replace("</", "<\\/")
    (OUT_DIR / "labeler.html").write_text(_HTML.replace("__ITEMS__", payload), encoding="utf-8")

    kinds = {}
    total_msgs = 0
    for it in items:
        total_msgs += len(it["seg"])
        hot = False
        for m in it["seg"]:
            k = RULES.classify(m["text"])
            if k in (RULES.EVENT_TODO, RULES.EVENT_NOTICE, RULES.EVENT_ACTIVITY, RULES.EVENT_PLAN):
                hot = True
        kinds["含实义" if hot else "纯闲聊/忽略"] = kinds.get("含实义" if hot else "纯闲聊/忽略", 0) + 1
    print(f"抽样 {len(items)} 段对话（共 {total_msgs} 条消息，平均 {total_msgs / max(1, len(items)):.1f} 条/段）-> {OUT_DIR}")
    print("  分布：", kinds)
    print(f"  → 双击打开：{(OUT_DIR / 'labeler.html')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
