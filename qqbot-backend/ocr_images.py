# -*- coding: utf-8 -*-
"""图片 OCR：用**本地多模态模型**（Ollama）离线识别图片文字，零新依赖、不出网。

为什么要它：QQChatExporter 导出的 txt 里图片只有占位符 `[图片:xxx.jpg]`，
标注时看不到内容就没法判断"这段该不该提醒"。把图片重新导出（勾"下载媒体"）后，
用这个脚本批量 OCR，把识别文字注回标注包。

用法：
    .venv\\Scripts\\python.exe -X utf8 ocr_images.py [图片目录] [-o 输出.json]
    默认目录：qqbot-backend\\ocr_test
"""

from __future__ import annotations

import argparse
import base64
import json
import urllib.error
import urllib.request
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
OLLAMA = "http://127.0.0.1:11434/api/chat"
MODEL = "qwen3.5:9b"
EXTS = (".png", ".jpg", ".jpeg", ".webp", ".bmp")

PROMPT = (
    "请提取这张图片里的**所有可见文字**，按从上到下、从左到右的顺序逐行输出。"
    "要求：只输出文字本身，不要解释、不要总结、不要加标题；保留数字与符号。"
    "最后另起一行输出 `类型：xxx`（xxx 用不超过 8 个字描述这张图是什么，"
    "例如：通知截图 / 聊天截图 / 二维码 / 课表 / 海报 / 表格）。"
    "如果图中没有任何文字，只输出 `无文字`。"
)


def ocr(path: Path, timeout: int = 180) -> dict:
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    body = {
        "model": MODEL,
        "messages": [{"role": "user", "content": PROMPT, "images": [b64]}],
        "stream": False,
        "think": False,
        "options": {"temperature": 0, "num_predict": 700},
    }
    req = urllib.request.Request(
        OLLAMA, data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        return {"file": path.name, "ok": False, "error": f"HTTP {exc.code}: {exc.read()[:120]}"}
    except Exception as exc:  # noqa: BLE001
        return {"file": path.name, "ok": False, "error": str(exc)}

    text = ((data.get("message") or {}).get("content") or "").strip()
    kind = ""
    lines = text.splitlines()
    if lines and lines[-1].startswith("类型："):
        kind = lines[-1].replace("类型：", "").strip()
        text = "\n".join(lines[:-1]).strip()
    return {"file": path.name, "ok": True, "kind": kind, "text": text}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("directory", nargs="?", default=str(BASE_DIR / "ocr_test"))
    ap.add_argument("-o", "--out", default="", help="结果写到哪里（默认同目录 ocr_result.json）")
    args = ap.parse_args()

    root = Path(args.directory)
    if not root.exists():
        print(f"目录不存在：{root}")
        return 1
    files = [p for p in sorted(root.rglob("*")) if p.suffix.lower() in EXTS]
    if not files:
        print(f"{root} 下没有图片（支持 {', '.join(EXTS)}）")
        return 1

    print(f"找到 {len(files)} 张图，用本地 {MODEL} 逐张识别…\n")
    out: list[dict] = []
    for i, p in enumerate(files, 1):
        r = ocr(p)
        out.append(r)
        if r["ok"]:
            preview = r["text"].replace("\n", " ⏎ ")[:100]
            print(f"[{i}/{len(files)}] {p.name}  ({r['kind'] or '未分类'})")
            print(f"    {preview if preview else '（无文字）'}")
        else:
            print(f"[{i}/{len(files)}] {p.name}  ❌ {r['error']}")

    dest = Path(args.out) if args.out else root / "ocr_result.json"
    dest.write_text(json.dumps({"model": MODEL, "results": out}, ensure_ascii=False, indent=1),
                    encoding="utf-8")
    print(f"\n结果已写入 {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
