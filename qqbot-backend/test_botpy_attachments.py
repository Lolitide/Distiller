"""自测：botpy_main 的附件序列化必须**保留原生类型**。

回归点（2026-10-15）：旧实现 `_json_list` 对每个值做 `str()`，于是 `size` 从 27065
变成 `"27065"`、`height` 从 None 变成 `"None"`。端上 `MessageAttachment.size?: number`
按数字用会算出 NaN，文件附件的体积也就没法显示。

这里用**模拟的 botpy 附件对象**（字段放在 __dict__ 里）验证：数字/None/中文/嵌套
都原样保留，私有字段剔除，并且能直接被 json.dumps。

运行：.venv\\Scripts\\python.exe -X utf8 test_botpy_attachments.py
"""

import json
import sys

import botpy_main

FAILS: list[str] = []


def check(label: str, cond: bool, extra=None) -> None:
    if cond:
        print(f"PASS  {label}" + (f"  {extra}" if extra is not None else ""))
    else:
        print(f"FAIL  {label}  {extra}")
        FAILS.append(label)


class FakeAttachment:
    """模拟 botpy 的 MessageAttachment（字段在 __dict__ 里）。"""

    def __init__(self) -> None:
        self.content_type = "file"
        self.filename = "朗读文章.docx"
        self.size = 27065
        self.height = None
        self.width = None
        self.url = "https://tjc-download.ftn.qq.com/ftn_handler/xxx?fname=a.docx"
        self._private = "不应出现"


class FakeNested:
    def __init__(self) -> None:
        self.inner = FakeAttachment()


print("=" * 78)
print("botpy_main._json_list：附件序列化保留原生类型")
print("=" * 78)

out = botpy_main._json_list([FakeAttachment()])
check("列表长度", len(out) == 1, len(out))
item = out[0] if out else {}
check("content_type 原样", item.get("content_type") == "file", item.get("content_type"))
check("filename 原样（中文）", item.get("filename") == "朗读文章.docx", item.get("filename"))
check(
    "size 仍是 int（不是 '27065'）",
    item.get("size") == 27065 and isinstance(item.get("size"), int),
    repr(item.get("size")),
)
check("height 仍是 None（不是 'None'）", item.get("height") is None, repr(item.get("height")))
check("url 原样", str(item.get("url")).startswith("https://"), item.get("url"))
check("私有字段被剔除", "_private" not in item, list(item.keys()))

nested = botpy_main._json_list([FakeNested()])
inner = nested[0].get("inner") if (nested and isinstance(nested[0], dict)) else None
check(
    "嵌套对象被展开且保留数字",
    isinstance(inner, dict) and inner.get("size") == 27065,
    inner,
)

check("空列表 -> []", botpy_main._json_list([]) == [], None)
check("None -> []", botpy_main._json_list(None) == [], None)
check("单个对象也包成列表", len(botpy_main._json_list(FakeAttachment())) == 1, None)
check(
    "纯 dict 原样透传",
    botpy_main._json_list([{"size": 12, "h": None}]) == [{"size": 12, "h": None}],
    None,
)

try:
    json.dumps(out, ensure_ascii=False)
    check("json.dumps 不报错", True, None)
except Exception as exc:  # noqa: BLE001
    check("json.dumps 不报错", False, exc)

print()
print("失败项：", FAILS if FAILS else "无，全部通过")
sys.exit(1 if FAILS else 0)
