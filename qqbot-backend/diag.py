"""网关事件诊断工具（不落库，只打印）。

用途：当"发了消息但终端没反应"时，用这个脚本判断问题出在哪一层：

    1) 连不上 / 鉴权失败  -> 终端直接报错，属凭据或网络问题
    2) 连上了但一条事件都没有 -> 平台侧没往这个机器人推事件
       （常见原因：群聊未开启"接收所有消息"、机器人未上线/未在群内、
         intent 不匹配、沙箱环境等）
    3) 收到了事件但类型不是预期 -> 终端会打印真实事件名，据此调整回调

运行：
    .venv\\Scripts\\python.exe diag.py
然后去群里发几条消息（包括 @机器人 和普通消息），观察终端输出。
按 Ctrl+C 退出。
"""

import asyncio
import logging
import os
import sys

import botpy
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
    force=True,
)
logger = logging.getLogger("diag")

APP_ID = os.environ.get("QQBOT_APP_ID", "")
APP_SECRET = os.environ.get("QQBOT_SECRET", "")


class DiagClient(botpy.Client):
    # ---- 记录所有"解析后"的事件名，这是判断事件是否到达的关键 ----
    def ws_dispatch(self, event: str, *args, **kwargs) -> None:
        if event in ("ready", "resumed"):
            logger.info(">>> 状态事件: %s", event)
        else:
            logger.info(">>> 收到事件: %s", event)
        super().ws_dispatch(event, *args, **kwargs)

    async def on_ready(self):
        logger.info(">>> READY：机器人「%s」已上线", getattr(self.robot, "name", "?"))

    async def on_group_message_create(self, message):
        logger.info(">>> [全量群消息] %s: %s", _who(message), getattr(message, "content", None))

    async def on_group_at_message_create(self, message):
        logger.info(">>> [@群消息] %s: %s", _who(message), getattr(message, "content", None))

    async def on_c2c_message_create(self, message):
        logger.info(">>> [单聊消息] %s: %s", _who(message), getattr(message, "content", None))

    async def on_at_message_create(self, message):
        logger.info(">>> [频道@消息] %s", getattr(message, "content", None))


def _who(message):
    author = getattr(message, "author", None)
    return (
        getattr(author, "username", None)
        or getattr(author, "member_openid", None)
        or getattr(author, "user_openid", None)
        or "未知"
    )


async def main():
    if not APP_ID or not APP_SECRET:
        raise SystemExit("未读到 QQBOT_APP_ID / QQBOT_SECRET，请检查 .env")

    logger.info("AppID: %s", APP_ID)
    logger.info("intent: public_messages(1<<25) = %s", bool(botpy.Intents(public_messages=True).value & (1 << 25)))

    # 打开 botpy 的 debug 日志，能看到 identify / hello / 原始帧
    logging.getLogger("botpy").setLevel(logging.DEBUG)

    client = DiagClient(intents=botpy.Intents(public_messages=True))
    logger.info("正在连接网关...（现在去群里发消息）")
    await client.start(appid=APP_ID, secret=APP_SECRET)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("已退出")
