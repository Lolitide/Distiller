# -*- coding: utf-8 -*-
"""集成自测：POST /api/relay/parse（手动添加任务：无状态抽取，文本/截图/文件）。

运行：.venv\\Scripts\\python.exe -X utf8 test_parse_api.py
不依赖 QQ、不依赖 Ollama（强制规则路径；OCR 用打桩验证接线，501 分支真验证）。
"""

from __future__ import annotations

import asyncio
import base64
import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

# 沙箱内临时存储，别污染真实 relay_store.json
_tmp = Path(__file__).resolve().parent / "_tmp_test" / "relay_store_parse.json"
_tmp.parent.mkdir(parents=True, exist_ok=True)
if _tmp.exists():
    _tmp.unlink()
os.environ["QQBOT_RELAY_STORE"] = str(_tmp)
# 词表也指到沙箱，避免清除逻辑动到真实 group_lexicon.json
_lex = Path(__file__).resolve().parent / "_tmp_test" / "group_lexicon_parse.json"
if _lex.exists():
    _lex.unlink()
os.environ["QQBOT_GROUP_LEXICON"] = str(_lex)

import llm_parse  # noqa: E402
llm_parse.available = lambda: False  # 强制规则路径，避免依赖本机模型

import relay  # noqa: E402
import server  # noqa: E402
import office_extract  # noqa: E402

FAILS: list[str] = []


def check(label: str, cond: bool, extra: str = "") -> None:
    print(f"{'PASS' if cond else 'FAIL'}  {label}{('  ' + str(extra)) if extra else ''}")
    if not cond:
        FAILS.append(label)


GID = "15B451ACFDB0816E3233D1947DEAC820"

dev = relay.STORE.register_device("parse-api")
DEVICE, TOKEN = dev["device_id"], dev["token"]
HEADERS = {"x-device-id": DEVICE, "x-device-token": TOKEN}
relay.STORE.subscribe(DEVICE, GID)


def call(path: str, query: dict | None = None) -> dict:
    status, payload = asyncio.run(
        server.handle_relay_api(path, "GET", query or {}, HEADERS, b"")
    )
    assert status == 200, (status, payload)
    return payload["data"]


def post(path: str, body: dict, headers: dict | None = None) -> tuple[int, dict]:
    return asyncio.run(
        server.handle_relay_api(path, "POST", {}, headers or HEADERS,
                                json.dumps(body).encode("utf-8"))
    )


# ---------------------------------------------------------------- /health 能力位
print("=" * 78)
print("一、/health 能力位：parse 常驻，ocr 跟随模型可用性")
print("=" * 78)
health = call("/health")
check("api_version = 2", health.get("api_version") == 2, str(health.get("api_version")))
check("capabilities 含 parse", "parse" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("capabilities 含 candidates", "candidates" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("capabilities 含 feedback", "feedback" in (health.get("capabilities") or []),
      str(health.get("capabilities")))
check("模型不可用时不谎报 ocr", "ocr" not in (health.get("capabilities") or []),
      str(health.get("capabilities")))

# ---------------------------------------------------------------- 文本解析
print()
print("二、POST /parse 文本：明天下午两点去康桥苑开会")
print("=" * 78)
before_window = relay.window_stats()
before_candidates = call("/candidates", {"after": ["0"]})

status, payload = post("/parse", {"text": "明天下午两点去康桥苑开会", "source": "manual"})
check("状态 200", status == 200, str(status))
data = payload.get("data") or {}
cand = data.get("candidate") or {}
check("返回 candidate", bool(cand), str(payload)[:120])
check("candidate_id 是 m_ 前缀临时值", str(cand.get("candidate_id", "")).startswith("m_"),
      str(cand.get("candidate_id")))
check("rev_seq = 0（不入候选流）", cand.get("rev_seq") == 0, str(cand.get("rev_seq")))
check("kind 是待办", cand.get("kind") == "待办", cand.get("kind"))
tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
check("相对时间以当前时刻归一化", cand.get("time_normalized") == f"{tomorrow} 14:00",
      cand.get("time_normalized"))
check("地点抽取到 康桥苑", cand.get("place") == "康桥苑", cand.get("place"))
check("标题非空", bool(cand.get("title")), cand.get("title"))
check("手动来源没有原话 msg_ids 为空", cand.get("source", {}).get("msg_ids") == [],
      str(cand.get("source", {}).get("msg_ids")))
check("group_openid 为空", cand.get("source", {}).get("group_openid") == "",
      str(cand.get("source", {}).get("group_openid")))
check("渠道写进 group_label", cand.get("source", {}).get("group_label") == "manual",
      str(cand.get("source", {}).get("group_label")))
check("响应回显参与解析的 text", data.get("text") == "明天下午两点去康桥苑开会",
      str(data.get("text"))[:60])

# 幂等：同文本再解析一次 -> 同 candidate_id
status2, payload2 = post("/parse", {"text": "明天下午两点去康桥苑开会", "source": "manual"})
check("同文本幂等（candidate_id 相同）",
      payload2["data"]["candidate"]["candidate_id"] == cand.get("candidate_id"))

# ---------------------------------------------------------------- 隐私：不进窗口/候选流
print()
print("三、隐私红线：只处理、不存储（窗口与候选流均不变）")
print("=" * 78)
after_window = relay.window_stats()
check("窗口消息数不变", after_window == before_window,
      f"{before_window} -> {after_window}")
after_candidates = call("/candidates", {"after": ["0"]})
check("候选流不变（不混入手动候选）", after_candidates == before_candidates,
      f"{len(before_candidates['candidates'])} -> {len(after_candidates['candidates'])}")

# ---------------------------------------------------------------- 忽略改判闲聊
print()
print("四、kind=忽略 一律改判 闲聊（手动输入不当噪声丢）")
print("=" * 78)
status, payload = post("/parse", {"text": "哈哈哈", "source": "manual"})
c2 = payload["data"]["candidate"]
check("纯闲聊不判成 忽略", c2.get("kind") != "忽略", c2.get("kind"))
check("闲聊也有完整候选形状（可存为低优先级待办）",
      c2.get("kind") == "闲聊" and bool(c2.get("title")), f"{c2.get('kind')} / {c2.get('title')}")

# ---------------------------------------------------------------- 参数校验
print()
print("五、参数校验与错误分支")
print("=" * 78)
status, payload = post("/parse", {})
check("缺内容 -> 400 bad_request", status == 400 and payload.get("error", {}).get("code") == "bad_request",
      f"{status} {str(payload)[:100]}")
status, payload = post("/parse", {"text": "   "})
check("纯空白 text -> 400", status == 400, str(status))
status, payload = asyncio.run(server.handle_relay_api("/parse", "GET", {}, HEADERS, b""))
check("GET /parse -> 400", status == 400, str(status))

# 超长文本截断到 4000 字符
status, payload = post("/parse", {"text": "记" * 5000})
check("超长文本截断到 4000 字符", len(payload["data"]["text"]) == 4000,
      str(len(payload["data"]["text"])))

# ---------------------------------------------------------------- 图片：模型不可用 -> 501
print()
print("六、image_b64：模型不可用时 501 not_supported（前端据此降级端侧 OCR）")
print("=" * 78)
status, payload = post("/parse", {"image_b64": base64.b64encode(b"faketest").decode()})
check("无模型 -> 501", status == 501, str(status))
check("错误码 not_supported", payload.get("error", {}).get("code") == "not_supported",
      str(payload.get("error"))[:100])

# ---------------------------------------------------------------- 图片：打桩验证 OCR 接线
print()
print("七、image_b64：打桩 ocr_image 验证接线（模型可用 -> 文本进管道）")
print("=" * 78)
llm_parse.available = lambda: True  # 假装模型在线
# 本机 Ollama 可能真的在跑：再桩掉簇级抽取，保证这条走**规则**路径（测试不依赖模型）
llm_parse.extract_thread = lambda texts: None
OCR_TEXT = "记得明天下午两点在康桥苑开会"
llm_parse.ocr_image = lambda b64, timeout=120: OCR_TEXT if b64 else ""
try:
    health_ocr = call("/health")
    check("模型可用时 capabilities 含 ocr", "ocr" in (health_ocr.get("capabilities") or []),
          str(health_ocr.get("capabilities")))
    status, payload = post("/parse", {"image_b64": "data:image/png;base64," + base64.b64encode(b"fake").decode()})
    check("截图解析 200", status == 200, f"{status} {str(payload)[:100]}")
    c3 = payload["data"]["candidate"]
    check("OCR 文本进了抽取管道", payload["data"]["text"] == OCR_TEXT, str(payload["data"]["text"])[:60])
    check("data: 前缀被剥离后仍能解析", c3.get("place") == "康桥苑", c3.get("place"))
    check("截图候选 kind 正确", c3.get("kind") == "待办", c3.get("kind"))
    check("走的是规则路径（不依赖本机 Ollama）", c3.get("engine") == "rules", c3.get("engine"))

    # OCR 无文字 -> 400
    llm_parse.ocr_image = lambda b64, timeout=120: ""
    status, payload = post("/parse", {"image_b64": base64.b64encode(b"blank").decode()})
    check("OCR 无文字 -> 400", status == 400 and payload.get("error", {}).get("code") == "bad_request",
          f"{status} {str(payload)[:100]}")

    # 图片文件走同一 OCR 路径
    llm_parse.ocr_image = lambda b64, timeout=120: OCR_TEXT
    status, payload = post("/parse", {"file_b64": base64.b64encode(b"fakepng").decode(),
                                      "file_name": "截图.png"})
    check("图片文件（.png）走 OCR -> 200", status == 200, str(status))
    check("图片文件解析出内容", payload["data"]["text"] == OCR_TEXT, str(payload["data"]["text"])[:60])
finally:
    llm_parse.available = lambda: False
    llm_parse.ocr_image = llm_parse.__dict__.get("_real_ocr_image", llm_parse.ocr_image)

# ---------------------------------------------------------------- 文件解析
print()
print("八、file_b64：文本文件按 UTF-8/GBK 解码进管道")
print("=" * 78)
txt_content = "下周三之前交实验报告".encode("utf-8")
status, payload = post("/parse", {"file_b64": base64.b64encode(txt_content).decode(),
                                  "file_name": "待办.txt", "source": "manual_file"})
check("UTF-8 文本文件 -> 200", status == 200, f"{status} {str(payload)[:100]}")
c4 = payload["data"]["candidate"]
check("文件文本进了管道", payload["data"]["text"] == "下周三之前交实验报告",
      str(payload["data"]["text"])[:60])
check("渠道 manual_file 透传到 group_label", c4.get("source", {}).get("group_label") == "manual_file",
      str(c4.get("source", {}).get("group_label")))
check("文本文件候选是待办", c4.get("kind") == "待办", c4.get("kind"))

gbk_content = "记得交学费".encode("gbk")
status, payload = post("/parse", {"file_b64": base64.b64encode(gbk_content).decode(),
                                  "file_name": "通知.txt"})
check("GBK 文本文件可解码", status == 200 and payload["data"]["text"] == "记得交学费",
      f"{status} {str(payload.get('data', {}))[:80]}")

status, payload = post("/parse", {"file_b64": base64.b64encode(os.urandom(64)).decode(),
                                  "file_name": "乱码.txt"})
check("二进制冒充 txt -> 400", status == 400, str(status))

status, payload = post("/parse", {"file_b64": base64.b64encode(b"%PDF-fake").decode(),
                                  "file_name": "论文.pdf"})
check("不支持的扩展名 -> 400", status == 400 and payload.get("error", {}).get("code") == "bad_request",
      f"{status} {str(payload)[:100]}")

status, payload = post("/parse", {"file_b64": "!!!not-base64!!!", "file_name": "a.txt"})
check("非法 base64 -> 400", status == 400, str(status))

# ---------------------------------------------------------------- 文本+截图混合
print()
print("九、text + image_b64 合并解析（截图 OCR 与手打备注拼一起）")
print("=" * 78)
llm_parse.available = lambda: True
llm_parse.extract_thread = lambda texts: None  # 强制规则路径，不依赖本机 Ollama
llm_parse.ocr_image = lambda b64, timeout=120: "下午两点开始"
try:
    status, payload = post("/parse", {"text": "社团招新", "image_b64": base64.b64encode(b"fake").decode()})
    check("混合来源 200", status == 200, str(status))
    check("两段文本按序拼接", payload["data"]["text"] == "社团招新\n下午两点开始",
          repr(payload["data"]["text"])[:80])
    c5 = payload["data"]["candidate"]
    check("混合候选仍是待办", c5.get("kind") == "待办", c5.get("kind"))
finally:
    llm_parse.available = lambda: False

# ---------------------------------------------------------------- Office / PDF 文件
print()
print("十、file_b64：Office 文档与 PDF（office_extract：docx/xlsx/pptx 标准库，pdf pypdf）")
print("=" * 78)


def _zip_bytes(entries: dict[str, str]) -> bytes:
    import zipfile as _zf
    from io import BytesIO as _BIo
    buf = _BIo()
    with _zf.ZipFile(buf, "w") as zf:
        for name, content in entries.items():
            zf.writestr(name, content)
    return buf.getvalue()


def _make_docx(paragraphs: list[str]) -> bytes:
    w = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
    ps = "".join(f"<w:p><w:r><w:t>{p}</w:t></w:r></w:p>" for p in paragraphs)
    xml = f'<?xml version="1.0"?><w:document {w}><w:body>{ps}</w:body></w:document>'
    return _zip_bytes({"word/document.xml": xml})


def _make_xlsx(cells: list[str]) -> bytes:
    w = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
    si = "".join(f"<si><t>{c}</t></si>" for c in cells)
    shared = f'<?xml version="1.0"?><sst {w}>{si}</sst>'
    return _zip_bytes({"xl/sharedStrings.xml": shared})


def _make_pptx(texts: list[str]) -> bytes:
    a = 'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"'
    ts = "".join(f"<a:t>{t}</a:t>" for t in texts)
    xml = f'<?xml version="1.0"?><p:sld {a} xmlns:p="p"><p:sp>{ts}</p:sp></p:sld>'
    return _zip_bytes({"ppt/slides/slide1.xml": xml})


def _minimal_pdf(text: str) -> bytes:
    """手工构造单页 PDF（含可抽取文本层），xref 偏移按实际字节计算。

    注意：简单字体（Type1 Helvetica）只支持单字节编码，text 必须是 ASCII；
    中文 PDF 需 CID/Type0 字体，构造太复杂，这里只验证管道（b64→pypdf→文本）。
    """
    stream = f"BT /F1 24 Tf 72 700 Td ({text}) Tj ET".encode("ascii")
    objs: list[bytes] = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R "
        b"/Resources << /Font << /F1 5 0 R >> >> >>",
        b"<< /Length " + str(len(stream)).encode() + b" >>\nstream\n" + stream + b"\nendstream",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
    ]
    out = bytearray(b"%PDF-1.4\n")
    offsets: list[int] = []
    for i, body in enumerate(objs, start=1):
        offsets.append(len(out))
        out += f"{i} 0 obj\n".encode() + body + b"\nendobj\n"
    xref_pos = len(out)
    n = len(objs) + 1
    out += f"xref\n0 {n}\n".encode()
    out += b"0000000000 65535 f \n"
    for off in offsets:
        out += f"{off:010d} 00000 n \n".encode()
    out += f"trailer\n<< /Size {n} /Root 1 0 R >>\nstartxref\n{xref_pos}\n%%EOF".encode()
    return bytes(out)


status, payload = post("/parse", {
    "file_b64": base64.b64encode(_make_docx(["下周三之前交实验报告", "记得带上实验数据"])).decode(),
    "file_name": "作业.docx", "source": "manual_file"})
check("docx 解析 200", status == 200, f"{status} {str(payload)[:100]}")
check("docx 段落按行抽出", payload["data"]["text"] == "下周三之前交实验报告\n记得带上实验数据",
      repr(payload["data"]["text"])[:80])
check("docx 候选是待办", payload["data"]["candidate"]["kind"] == "待办",
      payload["data"]["candidate"]["kind"])

status, payload = post("/parse", {
    "file_b64": base64.b64encode(_make_xlsx(["交实验报告", "周三截止"])).decode(),
    "file_name": "表格.xlsx"})
check("xlsx 解析 200", status == 200, f"{status} {str(payload)[:100]}")
check("xlsx 字符串池抽出", payload["data"]["text"] == "交实验报告\n周三截止",
      repr(payload["data"]["text"])[:80])

status, payload = post("/parse", {
    "file_b64": base64.b64encode(_make_pptx(["传智杯比赛报名", "截止周五"])).decode(),
    "file_name": "通知.pptx"})
check("pptx 解析 200", status == 200, f"{status} {str(payload)[:100]}")
check("pptx 文本抽出", payload["data"]["text"] == "传智杯比赛报名\n截止周五",
      repr(payload["data"]["text"])[:80])

# pypdf 软依赖：装了走真解析，没装走 501
if office_extract.pdf_supported():
    status, payload = post("/parse", {
        "file_b64": base64.b64encode(_minimal_pdf("Pay fee by Friday")).decode(),
        "file_name": "notice.pdf"})
    check("pdf 解析 200", status == 200, f"{status} {str(payload)[:100]}")
    check("pdf 文本抽出", "Pay fee by Friday" in (payload["data"]["text"] or ""),
          repr(payload["data"]["text"])[:80])
    check("pdf 响应含候选", "candidate" in payload["data"], str(payload)[:120])

    # 模拟 pypdf 未装 -> 501 not_supported（前端降级：让用户自己总结）
    real_reader = office_extract.PdfReader
    office_extract.PdfReader = None
    try:
        status, payload = post("/parse", {
            "file_b64": base64.b64encode(_minimal_pdf("x")).decode(),
            "file_name": "通知.pdf"})
        check("pypdf 未装 -> 501", status == 501 and payload.get("error", {}).get("code") == "not_supported",
              f"{status} {str(payload)[:100]}")
    finally:
        office_extract.PdfReader = real_reader
else:
    status, payload = post("/parse", {
        "file_b64": base64.b64encode(b"%PDF-fake").decode(),
        "file_name": "通知.pdf"})
    check("pypdf 未装 -> 501", status == 501, str(status))

# 损坏 docx（随机字节冒充）-> 400
status, payload = post("/parse", {
    "file_b64": base64.b64encode(os.urandom(64)).decode(),
    "file_name": "损坏.docx"})
check("损坏 docx -> 400", status == 400 and payload.get("error", {}).get("code") == "bad_request",
      f"{status} {str(payload)[:100]}")

# 老格式 .doc 明确拒绝（引导转存新格式）
status, payload = post("/parse", {
    "file_b64": base64.b64encode(b"ole2-fake").decode(),
    "file_name": "旧文档.doc"})
check("老格式 .doc -> 400", status == 400, str(status))
check("错误信息给出支持类型清单", "docx" in str(payload.get("error", {})), str(payload.get("error"))[:120])

relay.STORE.forget_device(DEVICE)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
