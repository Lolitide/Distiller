"""查看数据库里已收集到的群消息。"""

import asyncio
import aiosqlite


async def main():
    async with aiosqlite.connect("bot.db") as db:
        db.row_factory = aiosqlite.Row

        total = (await (await db.execute("SELECT COUNT(*) AS c FROM group_messages")).fetchone())["c"]
        print(f"数据库共 {total} 条消息\n")

        cursor = await db.execute(
            """
            SELECT msg_id, group_openid, sender_name, content,
                   timestamp, event_type, created_at
            FROM group_messages
            ORDER BY created_at DESC, rowid DESC
            LIMIT 20
            """
        )
        rows = await cursor.fetchall()
        if not rows:
            print("数据库里还没有消息。")
            print("排查建议：先运行 diag.py，看群里发消息时是否打印 '>>> 收到事件'。")
            return

        for r in rows:
            tag = r["event_type"] or "?"
            print(f"[{r['created_at']}] ({tag}) {r['sender_name']}: {r['content']}")
            print(f"    group={r['group_openid']}  msg_id={r['msg_id']}")


asyncio.run(main())
