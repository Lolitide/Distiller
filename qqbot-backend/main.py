import asyncio
import os
import logging

import httpx

from dotenv import load_dotenv
load_dotenv()  # 必须在读取环境变量之前调用

from qqbot_agent_sdk import (
    QQApiClient,
    QQWebSocket,
    WSCallbacks,
    EventParser,
)
from qqbot_agent_sdk import dto as _dto
from qqbot_agent_sdk import websocket as _sdk_websocket
from qqbot_agent_sdk.event_parser import EventParser as _EventParser

from database import init_db, save_message

# ----------------------------------------------------------------------
# 修复：SDK 自带的 EventParser 没有登记 GROUP_MESSAGE_CREATE（全量模式群消息），
# 导致开启全量模式后解析返回 None，消息被丢弃、终端毫无输出。
# 这里把它按"群消息"注册进去，解析逻辑与 GROUP_AT_MESSAGE_CREATE 完全一致。
# ----------------------------------------------------------------------
_EventParser._EVENT_HANDLERS.setdefault(
    "GROUP_MESSAGE_CREATE",
    _EventParser._parse_group.__func__,
)

# SDK 的 MESSAGE_EVENT_TYPES 是 frozenset，且被 websocket 模块按值导入，
# 所以两个地方的引用都要替换，否则 websocket 层不会把事件派发出来。
_MESSAGE_EVENT_TYPES = set(_dto.MESSAGE_EVENT_TYPES) | {"GROUP_MESSAGE_CREATE"}
_dto.MESSAGE_EVENT_TYPES = _MESSAGE_EVENT_TYPES
_sdk_websocket.MESSAGE_EVENT_TYPES = _MESSAGE_EVENT_TYPES

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

# 从环境变量读取凭据
APP_ID = os.environ.get("QQBOT_APP_ID", "")
APP_SECRET = os.environ.get("QQBOT_SECRET", "")


async def main():
    # 0. 凭据检查，防止 .env 未加载
    if not APP_ID or not APP_SECRET:
        raise SystemExit(
            "错误：未检测到有效的 AppID/AppSecret。\n"
            "请确认 .env 文件存在且变量名为 QQBOT_APP_ID / QQBOT_SECRET，\n"
            "并确保 main.py 顶部调用了 load_dotenv()。"
        )
    logger.info(f"使用 AppID: {APP_ID}")

    # 1. 初始化数据库
    await init_db()
    logger.info("数据库初始化完成")

    # 2. 创建 API 客户端
    api = QQApiClient(app_id=APP_ID, client_secret=APP_SECRET)

    # 3. 创建 httpx.AsyncClient 并注入（关键，否则 get_gateway_url 会报错）
    http_client = httpx.AsyncClient(timeout=30.0)
    api.setup(http_client)
    logger.info("HTTP 客户端已注入")

    # 4. 定义消息事件处理回调
    async def on_message(event_type: str, raw: dict):
        """
        event_type 可能是 GROUP_MESSAGE_CREATE 或 GROUP_AT_MESSAGE_CREATE
        raw 是原始事件 JSON
        """
        logger.info(f"收到事件类型: {event_type}")

        # 只处理群消息事件
        if event_type not in ("GROUP_MESSAGE_CREATE", "GROUP_AT_MESSAGE_CREATE"):
            return

        event = EventParser().parse(event_type, raw)
        if not event:
            logger.warning(f"事件解析失败: {raw}")
            return

        # 打印消息内容
        sender = event.user_name or event.user_id or "未知用户"
        logger.info(f"[群消息][{event_type}] {sender}: {event.content}")

        # 写入数据库
        try:
            is_new = await save_message(event, event_type=event_type)
            if is_new:
                logger.info(f"消息已入库: {event.message_id}")
            else:
                logger.info(f"消息已存在，跳过: {event.message_id}")
        except Exception as e:
            logger.error(f"入库失败: {e}", exc_info=True)

    # 5. 创建 WebSocket 连接
    ws = QQWebSocket(
        callbacks=WSCallbacks(
            on_message_event=on_message,
            get_token=api.ensure_token_sync,
            get_gateway_url=api.get_gateway_url_sync,
            # 以下为新增的必填回调
            on_connected=lambda: logger.info("WebSocket 已连接"),
            on_disconnected=lambda: logger.warning("WebSocket 已断开"),
            on_fatal_error=lambda code, msg: logger.error(f"致命错误 [{code}]: {msg}"),
            get_session=lambda: (None, None),              # 无需会话恢复时返回空
            set_session=lambda sid, seq: None,             # 无需存储会话
            set_heartbeat_interval=lambda interval: None,  # 使用默认心跳
            clear_token=lambda: None,                      # 不需要手动清除
            fail_pending=lambda reason: None,              # 不需要处理待定请求
        )
    )

    # 6. 获取 Token 和 Gateway 地址，启动 WebSocket
    await api.ensure_token()
    gateway_url = await api.get_gateway_url()
    logger.info(f"正在连接 Gateway: {gateway_url[:60]}...")

    ws.start(gateway_url, asyncio.get_running_loop())
    logger.info("WebSocket 已启动，开始监听群消息...")

    # 7. 保持运行
    try:
        await asyncio.Event().wait()
    finally:
        ws.stop()
        await http_client.aclose()
        logger.info("已停止")


if __name__ == "__main__":
    asyncio.run(main())