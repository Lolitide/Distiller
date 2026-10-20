# -*- coding: utf-8 -*-
"""OOXML（docx/xlsx/pptx）与 PDF 文本抽取——POST /api/relay/parse 的文件通道。

设计约束（AGENTS.md §3 改动纪律）：
- docx/xlsx/pptx 本质是 zip+XML，**只用标准库**（zipfile + xml.etree），零新依赖；
- PDF 走**软依赖** pypdf（纯 Python，MIT）：没装不影响服务启动，只影响
  /parse 的 .pdf 分支（server.py 返回 not_supported，前端提示用户自己总结）。
- 只抽文本不还原样式；结果给「用户总结 / LLM 抽取」用，抽不到就是抽不到，
  **绝不编造**。
- .doc/.xls/.ppt（OLE2 老格式）不支持——明确报错让用户转存新格式，
  不做启发式猜测。
"""

from __future__ import annotations

import re
import zipfile
from io import BytesIO
from xml.etree import ElementTree

# PDF 软依赖：纯 Python，pip install pypdf
try:
    from pypdf import PdfReader
except ImportError:  # 没装也不崩：/parse 的 .pdf 分支按 not_supported 降级
    PdfReader = None  # type: ignore[assignment]

# 每种格式内部先截到这个量级；/parse 外层还有 MAX_PARSE_TEXT_CHARS(4000) 的闸
MAX_CHARS = 8000

# OOXML 主命名空间（wordprocessingml / spreadsheetml / drawingml —— 三者不同，别混用）
_W_NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
_S_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
_A_NS = "{http://schemas.openxmlformats.org/drawingml/2006/main}"

# 支持的抽取扩展名（老格式 .doc/.xls/.ppt 不在其中，落 400）
SUPPORTED_EXTS = (".docx", ".xlsx", ".pptx", ".pdf")


def pdf_supported() -> bool:
    """pypdf 是否已安装（决定 /parse 的 .pdf 分支走 501 还是真解析）。"""
    return PdfReader is not None


def extract_docx(data: bytes) -> str:
    """docx：逐段落抽 <w:t>，段落用 \\n 连接（保住行结构，便于读）。"""
    with zipfile.ZipFile(BytesIO(data)) as zf:
        xml = zf.read("word/document.xml")
    root = ElementTree.fromstring(xml)
    lines: list[str] = []
    for para in root.iter(f"{_W_NS}p"):
        text = "".join(t.text or "" for t in para.iter(f"{_W_NS}t")).strip()
        if text:
            lines.append(text)
    return "\n".join(lines)[:MAX_CHARS]


def extract_xlsx(data: bytes) -> str:
    """xlsx：抽 sharedStrings 字符串池 + 各 sheet 的 inline string。

    不还原行列结构（要做需解析 <c r="A1"> 引用矩阵，工程量大且对
    「读内容做总结」场景收益低）；单元格文本逐行输出。
    """
    out: list[str] = []
    with zipfile.ZipFile(BytesIO(data)) as zf:
        names = zf.namelist()
        if "xl/sharedStrings.xml" in names:
            root = ElementTree.fromstring(zf.read("xl/sharedStrings.xml"))
            for t in root.iter(f"{_S_NS}t"):
                text = (t.text or "").strip()
                if text:
                    out.append(text)
        for name in sorted(n for n in names
                           if re.fullmatch(r"xl/worksheets/sheet\d+\.xml", n)):
            root = ElementTree.fromstring(zf.read(name))
            for t in root.iter(f"{_S_NS}t"):
                text = (t.text or "").strip()
                if text:
                    out.append(text)
    return "\n".join(out)[:MAX_CHARS]


def extract_pptx(data: bytes) -> str:
    """pptx：逐页抽 <a:t>（slide1.xml, slide2.xml, ... 按页号排序）。"""
    out: list[str] = []
    with zipfile.ZipFile(BytesIO(data)) as zf:
        slide_names = sorted(
            (n for n in zf.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", n)),
            key=lambda n: int(re.search(r"(\d+)", n).group(1)),
        )
        for name in slide_names:
            root = ElementTree.fromstring(zf.read(name))
            for t in root.iter(f"{_A_NS}t"):
                text = (t.text or "").strip()
                if text:
                    out.append(text)
    return "\n".join(out)[:MAX_CHARS]


def extract_pdf(data: bytes) -> str:
    """PDF：pypdf 逐页 extract_text；扫描版/图片型 PDF 抽出来是空串。

    pypdf 未装时调用方应先用 pdf_supported() 判掉，不该走到这里。
    """
    if PdfReader is None:
        return ""
    reader = PdfReader(BytesIO(data))
    pages: list[str] = []
    for page in reader.pages:
        text = (page.extract_text() or "").strip()
        if text:
            pages.append(text)
    return "\n".join(pages)[:MAX_CHARS]


def extract_any(suffix: str, data: bytes) -> str:
    """按扩展名分发。不支持的扩展名抛 ValueError（调用方转 400）。"""
    if suffix == ".docx":
        return extract_docx(data)
    if suffix == ".xlsx":
        return extract_xlsx(data)
    if suffix == ".pptx":
        return extract_pptx(data)
    if suffix == ".pdf":
        return extract_pdf(data)
    raise ValueError(f"不支持的扩展名: {suffix or '(无)'}")
