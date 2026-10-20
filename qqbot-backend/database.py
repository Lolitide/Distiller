"""SQLite 落库层：保存与查询群聊消息。"""

import json
import aiosqlite

DB_PATH = "bot.db"


async def init_db():
    """初始化数据库，创建消息表（含旧库自动补列）。"""
    async with aiosqlite.connect(DB_PATH) as db:
        # 开启 WAL 模式，提升并发读写性能
        await db.execute("PRAGMA journal_mode=WAL;")
        await db.execute("""
            CREATE TABLE IF NOT EXISTS group_messages (
                msg_id        TEXT PRIMARY KEY,
                group_openid  TEXT NOT NULL,
                sender_openid TEXT,
                sender_name   TEXT,
                member_role   TEXT,
                content       TEXT,
                timestamp     TEXT,
                attachments   TEXT,
                mentions      TEXT,
                created_at    TEXT DEFAULT (datetime('now'))
            )
        """)
        # 兼容旧库：补上 message_type / event_type 列
        cursor = await db.execute("PRAGMA table_info(group_messages)")
        existing = {row[1] for row in await cursor.fetchall()}
        for column, ddl in (
            ("message_type", "ALTER TABLE group_messages ADD COLUMN message_type INTEGER"),
            ("event_type", "ALTER TABLE group_messages ADD COLUMN event_type TEXT"),
        ):
            if column not in existing:
                await db.execute(ddl)
        await db.commit()


def _dump(items) -> str:
    """把 SDK 对象列表安全地转成 JSON 字符串。"""
    result = []
    for item in items or []:
        if hasattr(item, "__dict__"):
            result.append({k: v for k, v in vars(item).items()})
        elif isinstance(item, dict):
            result.append(item)
        else:
            result.append(str(item))
    return json.dumps(result, ensure_ascii=False, default=str)


def _first_attr(obj, *names, default=None):
    """按顺序取第一个存在且非空的属性值。"""
    for name in names:
        value = getattr(obj, name, None)
        if value:
            return value
    return default


async def save_group_message(message, event_type: str | None = None) -> bool:
    """把群消息写入数据库。

    同时兼容两类消息对象：

    * botpy 的 ``GroupMessage`` / ``C2CMessage``（``botpy_main.py`` 使用）
    * ``qqbot_agent_sdk`` 的 ``InboundEvent`` 数据类（``main.py`` 使用）

    返回 True 表示新插入，False 表示已存在。

    Args:
        message: 消息对象。
        event_type: 触发该消息的事件名，便于区分全量/AT 消息。
    """
    author = getattr(message, "author", None)

    # 群聊优先 member_openid，单聊用 user_openid；SDK 的 InboundEvent 直接给 user_id
    sender_openid = _first_attr(
        author or message, "member_openid", "user_openid", "user_id", "id"
    )
    sender_name = _first_attr(author or message, "username", "user_name") or sender_openid
    if not sender_name:
        sender_name = "未知用户"

    group_openid = _first_attr(
        message, "group_openid", "chat_id", default=""
    ) or ""

    msg_id = _first_attr(message, "id", "message_id")
    member_role = getattr(author, "member_role", None) if author is not None else None

    async with aiosqlite.connect(DB_PATH) as db:
        cursor = await db.execute(
            """
            INSERT OR IGNORE INTO group_messages
                (msg_id, group_openid, sender_openid, sender_name,
                 member_role, content, timestamp, attachments, mentions,
                 message_type, event_type)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                msg_id,
                group_openid,
                sender_openid,
                sender_name,
                member_role,
                getattr(message, "content", None),
                getattr(message, "timestamp", None),
                _dump(_first_attr(message, "attachments")),
                _dump(_first_attr(message, "mentions")),
                getattr(message, "message_type", None),
                event_type or getattr(message, "event_type", None),
            ),
        )
        await db.commit()
        return cursor.rowcount > 0


# 向后兼容旧调用名
save_message = save_group_message


async def query_recent_messages(group_openid: str, limit: int = 20):
    """查询某个群最近的消息（用于验证存储是否正常）。"""
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        cursor = await db.execute(
            """
            SELECT sender_name, content, timestamp
            FROM group_messages
            WHERE group_openid = ?
            ORDER BY timestamp DESC
            LIMIT ?
            """,
            (group_openid, limit),
        )
        rows = await cursor.fetchall()
        return [dict(r) for r in rows]
