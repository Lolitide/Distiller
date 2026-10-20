# -*- coding: utf-8 -*-
"""按群自学习的「领域词表」——个性化识别的载体。

设计（对齐用户诉求：**不同学校/不同群各自学自己的专业名词**）：

    群消息 ──模式抽取──▶ 校内地名 / 组织名（高精度、按构造即成立）
                            └──▶ 只影响这个群：地点抽取 / 标签 / 聚类关键词

**为什么不用 n-gram 统计挖词**：实测过（仲英书院群 8 万条），"频次 + 熵 + PMI + 上下文归类"
在语料一大时**必然退化为噪声**——`还有`、`的话`、`交小西` 都会偶然挨着 `书院/食堂` 若干次。
改用**模式抽取**：`苑|书院|校区|门口|食堂|广场|公寓` 前面的 2~4 个字就是地名
（`康桥苑`→康桥、`文治书院`→文治）。按构造就是高精度，不需要调阈值。

**隐私（关键）**：只落盘「词 + 次数 + 类别」这类**派生统计量**，
**绝不落盘聊天正文**。落盘文件里不可能出现任何一句话的原文。

纯标准库，零依赖。
"""

from __future__ import annotations

import glob
import json
import os
import re
import threading
from collections import Counter, defaultdict
from pathlib import Path

import pipeline_proto as RULES

BASE_DIR = Path(__file__).resolve().parent

# ---------------------------------------------------------------- 参数

MIN_NAME_COUNT = 3     # 一个地名至少出现多少次才收录（模式抽取精度高，3 次足够）
MAX_TERMS = 400        # 每群最多保留多少个词
NAME_MIN, NAME_MAX = 2, 4   # 名称长度（字）

# 非人话：系统消息 / 拍一拍（定义在 pipeline_proto，唯一真值源）
_SYSTEM_RE = RULES._SYSTEM_RE
_NOISE_CHARS = re.compile(r"\[[^\]]*\]|@某人|\[链接\]")
_CJK_RUN = re.compile(r"[\u4e00-\u9fa5]+")

# 地点后缀：几乎只用于"某地名 + 后缀"（前缀就是名字本身）
_PLACE_SUFFIXES = ("苑", "书院", "校区", "门口", "食堂", "广场", "公寓", "澡堂", "驿站")
# 组织后缀
_ORG_SUFFIXES = ("社团", "学生会", "志愿服务队", "工作室", "俱乐部", "协会", "实践团", "宣讲团")
# 通用地点/词：它们本身不是"本校专名"，已由通用正则覆盖，收录进来只会添乱
_GENERIC = set("""
宿舍 教室 食堂 图书馆 操场 厕所 浴室 澡堂 超市 医院 门口 广场 中心 公寓 驿站 校区 书院
一楼 二楼 三楼 四楼 五楼 楼上 楼下 这边 那边 里面 外面 上面 下面 前面 后面 旁边 附近 周围
同学 老师 学姐 学长 新生 大家 我们 你们 他们 自己 现在 今天 明天 后天 昨天 时候 时间
哪个 哪些 这个 那个 什么 怎么 这种 那种 每个 各种 别的 其他 一个 一起 咱们 问问 学校
""".split())
# 纯数量词前缀（一食堂/二食堂/三号楼）
_NUMERIC_RE = re.compile(r"^[零〇一二三四五六七八九十百千万两]+$")

CATEGORIES = ("place", "org")


def _pattern_extract(texts: list[str]) -> dict[str, Counter]:
    """按「前缀 + 后缀」抽实体名。返回 ``{cat: Counter(词 -> 次数)}``。

    对每个后缀位置，枚举长度 2~4 的前缀**全部计入**：
    真名（`仲英`）会在每次出现时都被计入，被上下文污染的长前缀（`我们仲英`）只在
    特定上下文出现，计数远低于真名，阈值一卡就掉了。
    """
    hits: dict[str, Counter] = {"place": Counter(), "org": Counter()}
    for text in texts:
        for cat, suffixes in (("place", _PLACE_SUFFIXES), ("org", _ORG_SUFFIXES)):
            counter = hits[cat]
            for suf in suffixes:
                start = 0
                while True:
                    idx = text.find(suf, start)
                    if idx < 0:
                        break
                    for n in range(NAME_MIN, NAME_MAX + 1):
                        name = text[max(0, idx - n):idx]
                        if len(name) != n:
                            continue
                        if _is_bad_name(name):
                            continue
                        counter[name] += 1
                    start = idx + len(suf)
    return hits


def _is_bad_name(name: str) -> bool:
    if not name or len(name) < NAME_MIN:
        return True
    if not _CJK_RUN.fullmatch(name):      # 必须全是汉字
        return True
    if name in _GENERIC:                  # 通用词
        return True
    if _NUMERIC_RE.fullmatch(name):       # 纯数量词（一/二/三号楼）
        return True
    return False


def learn_group_terms(messages: list[dict], max_terms: int = MAX_TERMS) -> dict[str, dict]:
    """从一个群的消息里学出领域词表。

    返回 ``{词: {"count": n, "cat": "place|org", "score": n}}``。
    """
    texts: list[str] = []
    for m in messages:
        text = RULES.normalize(m.get("content") or "")
        if not text or _SYSTEM_RE.search(text):
            continue
        texts.append(_NOISE_CHARS.sub("", text))

    hits = _pattern_extract(texts)

    out: dict[str, dict] = {}
    merged: list[tuple[int, str, str]] = []
    for cat, counter in hits.items():
        for name, count in counter.items():
            if count >= MIN_NAME_COUNT:
                merged.append((count, name, cat))
    merged.sort(reverse=True)

    accepted: dict[str, int] = {}
    for count, name, cat in merged:
        # 上下文污染/拼接过滤：与已收词互为子串、且计数不低于它 -> 丢掉
        # （'我们仲英' 含 '仲英'；'四大发明广场' 与 '发明' 同源，只留最长的）
        if any(name != other and (other in name or name in other) and count <= other_count
               for other, other_count in accepted.items()):
            continue
        if name in accepted:
            continue
        accepted[name] = count
        out[name] = {"count": count, "cat": cat, "score": count}
        if len(out) >= max_terms:
            break
    return out


# ---------------------------------------------------------------- 落盘（只有词表）

class GroupLexiconStore:
    """``group_openid -> {词: {count, cat}}`` 的落盘存储。

    **文件里只有词与计数，没有任何聊天正文。** 原子替换写入，与 RelayStore 同款。
    """

    def __init__(self, path: Path | str | None = None):
        env = os.environ.get("QQBOT_GROUP_LEXICON")
        self.path = Path(path or env or (BASE_DIR / "group_lexicon.json"))
        self._lock = threading.RLock()
        self._data: dict[str, dict] = {}
        self._load()

    def _load(self) -> None:
        try:
            raw = json.loads(self.path.read_text(encoding="utf-8"))
            if isinstance(raw, dict) and isinstance(raw.get("groups"), dict):
                self._data = raw["groups"]
        except (OSError, ValueError):
            self._data = {}

    def _flush(self) -> None:
        with self._lock:
            self.path.parent.mkdir(parents=True, exist_ok=True)
            tmp = self.path.with_suffix(".tmp")
            tmp.write_text(
                json.dumps({"version": 1, "groups": self._data}, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            for _ in range(5):
                try:
                    os.replace(tmp, self.path)
                    break
                except PermissionError:  # Windows 偶发占用
                    import time

                    time.sleep(0.05)

    def merge(self, group_openid: str, terms: dict[str, dict]) -> int:
        """把一个群新学到的词并入（同词取更大 count）。返回新增词数。"""
        if not group_openid or not terms:
            return 0
        with self._lock:
            cur = self._data.setdefault(group_openid, {})
            added = 0
            for word, info in terms.items():
                old = cur.get(word)
                if old is None:
                    cur[word] = {"count": info["count"], "cat": info["cat"]}
                    added += 1
                else:
                    old["count"] = max(int(old.get("count") or 0), int(info["count"]))
                    old["cat"] = info["cat"] or old.get("cat")
            if len(cur) > MAX_TERMS:
                keep = sorted(cur.items(), key=lambda kv: -int(kv[1].get("count") or 0))[:MAX_TERMS]
                self._data[group_openid] = dict(keep)
            self._flush()
            return added

    def terms(self, group_openid: str) -> dict[str, dict]:
        with self._lock:
            return dict(self._data.get(group_openid) or {})

    def words_of_category(self, group_openid: str, cat: str, limit: int | None = None) -> list[str]:
        """按类别取词，**按出现次数降序**（高频的才是真名，噪声都沉在尾部）。

        ``limit``：只取 top-N。生产默认取前 20——实测前 15 个基本全是真校内名，
        再往后噪声比例明显上升。
        """
        items = [(w, int(i.get("count") or 0)) for w, i in self.terms(group_openid).items()
                 if i.get("cat") == cat]
        items.sort(key=lambda kv: -kv[1])
        words = [w for w, _ in items]
        return words[:limit] if limit else words

    def drop(self, group_openid: str, word: str) -> bool:
        """用户手动删掉一个学错的词（对应 /feedback）。"""
        with self._lock:
            cur = self._data.get(group_openid) or {}
            if word in cur:
                cur.pop(word)
                self._flush()
                return True
            return False

    def forget(self, group_openid: str) -> None:
        """一键删除：连派生词表一起清。"""
        with self._lock:
            if self._data.pop(group_openid, None) is not None:
                self._flush()

    def stats(self) -> dict:
        return {
            "groups": len(self._data),
            "terms": sum(len(v) for v in self._data.values()),
            "by_category": {
                cat: sum(1 for v in self._data.values() for i in v.values() if i.get("cat") == cat)
                for cat in CATEGORIES
            },
        }


STORE = GroupLexiconStore()


# ---------------------------------------------------------------- 在线增量学习

MIN_LEARN_MESSAGES = 30   # 一个群在窗口里至少这么多条才值得学（太少只会学到噪声）


def learn_from_window(items, store: GroupLexiconStore | None = None,
                      min_messages: int = MIN_LEARN_MESSAGES) -> dict[str, int]:
    """从**运行中的消息窗口**给每个群增量学词表。

    ``items``：relay 窗口里的消息（须带 ``group_openid`` / ``content``）。
    返回 ``{group_openid: 新增词数}``。按群隔离，只往该群自己的词表里并。

    与离线引导 ``build_from_exports`` 的区别：这里输入是实时窗口（可能只有几十条），
    所以设了 ``min_messages`` 下限，并且**只做并集累加**——学到的词会随进程留存
    （落盘），窗口清空也不会丢。
    """
    store = store or STORE
    by_group: dict[str, list[dict]] = defaultdict(list)
    for m in items:
        gid = m.get("group_openid") or ""
        if gid:
            by_group[gid].append(m)

    added: dict[str, int] = {}
    for gid, msgs in by_group.items():
        if len(msgs) < min_messages:
            continue
        terms = learn_group_terms(msgs)
        if terms:
            added[gid] = store.merge(gid, terms)
    return added


# ---------------------------------------------------------------- 引导脚本

def build_from_exports(directory: Path | str, store: GroupLexiconStore | None = None) -> dict:
    """用导出的群聊文件，给每个群学一份词表（离线引导 / 回测用）。"""
    from corpus_analysis import parse_export

    store = store or STORE
    report: dict[str, dict] = {}
    for path in sorted(glob.glob(str(Path(directory) / "*.txt"))):
        meta, msgs = parse_export(path)
        group = meta.get("group") or os.path.basename(path)
        if not msgs:
            continue
        terms = learn_group_terms(msgs)
        store.merge(group, terms)
        by_cat: dict[str, list[str]] = defaultdict(list)
        for w, i in terms.items():
            by_cat[i["cat"]].append(w)
        report[group] = {"learned": len(terms), **{k: v[:20] for k, v in by_cat.items()}}
    return report


if __name__ == "__main__":
    import sys

    target = Path(sys.argv[1]) if len(sys.argv) > 1 else BASE_DIR.parent / "聊天记录"
    if not target.exists():
        print(f"找不到语料目录：{target}")
        raise SystemExit(1)
    rep = build_from_exports(target)
    for group, info in rep.items():
        print(f"\n▸ {group}  学到 {info['learned']} 词")
        for cat in CATEGORIES:
            if info.get(cat):
                print(f"    {cat:5s}: {'、'.join(info[cat])}")
    print("\n词表统计:", STORE.stats())
