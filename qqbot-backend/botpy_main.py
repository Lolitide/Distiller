"""QQ 机器人后端：监听群聊消息并落库（支持"全量模式"）。

【本文件修复的核心问题】
群聊开启"全量模式"（接收所有消息）后，平台下发的群消息事件类型是
``GROUP_MESSAGE_CREATE``，而**不是** ``GROUP_AT_MESSAGE_CREATE``。

botpy 的分发逻辑是 ``on_ + 事件名小写``，所以：

    GROUP_MESSAGE_CREATE     -> on_group_message_create      （原先没写 -> 被静默丢弃）
    GROUP_AT_MESSAGE_CREATE  -> on_group_at_message_create   （原先只写了这个）

旧代码只实现了 ``on_group_at_message_create``，因此全量模式下普通群消息
到达客户端后找不到对应回调，只在 debug 级别记一行"事件未注册"，
终端看起来就是"什么反应都没有"。

本文件同时实现两个回调，并增加原始事件日志，便于排查。
"""

import asyncio
import logging
import os
import re
import sys

import botpy
import httpx
from botpy.message import C2CMessage, GroupMessage

from dotenv import load_dotenv

load_dotenv()

import relay  # 机器人消息中继：把群消息按订阅定向分发给 App
from database import init_db, save_group_message

# ---------------- 日志配置 ----------------
# 注意：botpy 内部用 logging.basicConfig 配置自己的格式，
# 这里统一走 root logger 的 handler，避免被覆盖后看不到中文输出。
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
    force=True,
)
logger = logging.getLogger("qqbot")

APP_ID = os.environ.get("QQBOT_APP_ID", "")
APP_SECRET = os.environ.get("QQBOT_SECRET", "")
PLAIN_TEXT = re.compile(r"<@!?\d+>")


def _plain_text(content) -> str:
    """把群消息里的 <@!123> 这类 @ 标记换成可读的「@某人」，避免 App 里出现原始标记。"""
    return PLAIN_TEXT.sub("@某人", str(content or ""))


def _json_safe(value, depth: int = 0):
    """把 SDK 对象递归转成「可 JSON 序列化且**保留原生类型**」的结构。

    早期版本对每个值做 ``str()``，把 ``size`` 变成 ``"27065"``、``height`` 变成
    ``"None"``——端上按数字用就会算出 NaN。这里只把不可序列化的对象降级成 str。
    """
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if depth >= 3:
        return str(value)
    if isinstance(value, dict):
        return {str(k): _json_safe(v, depth + 1) for k, v in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_safe(v, depth + 1) for v in value]
    if hasattr(value, "__dict__"):
        return {
            k: _json_safe(v, depth + 1)
            for k, v in vars(value).items()
            if not k.startswith("_")
        }
    return str(value)


def _json_list(items) -> list:
    """把 SDK 的附件/mentions 列表转成可 JSON 序列化的普通结构。"""
    if not items:
        return []
    if isinstance(items, (list, tuple)):
        return [_json_safe(item) for item in items]
    return [_json_safe(items)]


class MyClient(botpy.Client):
    async def on_ready(self):
        """机器人准备就绪时触发。"""
        robot = self.robot
        logger.info("机器人「%s」已上线！(id=%s)", getattr(robot, "name", "?"), getattr(robot, "id", "?"))

    # ------------------------------------------------------------------
    # 下面三个回调分别是：全量群消息 / @机器人 / 单聊
    # ------------------------------------------------------------------

    async def on_group_message_create(self, message: GroupMessage):
        """群内**全量**消息（机器人开启"接收所有消息"后的普通消息）。"""
        await self._handle_group_message(message, "GROUP_MESSAGE_CREATE")

    async def on_group_at_message_create(self, message: GroupMessage):
        """群内 @机器人 的消息。"""
        await self._handle_group_message(message, "GROUP_AT_MESSAGE_CREATE")

    async def on_c2c_message_create(self, message: C2CMessage):
        """单聊消息：这里承担「App ↔ QQ 账号」的绑定（用户发配对码给机器人）。

        注意：机器人**不能主动私聊推送**（平台 2025-04-21 起下线主动消息），
        所以单聊只用于「用户主动发 → 机器人被动回」，这也是配对的唯一入口。
        """
        try:
            author = getattr(message, "author", None)
            user_openid = getattr(author, "user_openid", None) or getattr(
                author, "member_openid", None
            )
            content = (getattr(message, "content", "") or "").strip()
            logger.info("[单聊] %s: %s", getattr(author, "username", None), content)
            logger.info(
                "  [id诊断] user_openid=%s member_openid=%s union_openid=%s",
                user_openid,
                getattr(author, "member_openid", None),
                getattr(author, "union_openid", None),
            )

            code = relay.parse_bind_command(content)
            reply = self._bind_reply(code, user_openid, content)
            await message.reply(content=reply)
        except Exception:
            logger.exception("处理单聊消息异常")

    def _bind_reply(self, code: str, user_openid: str, content: str) -> str:
        """根据单聊内容生成回复文案（不涉及网络，便于单独测试）。"""
        if not user_openid:
            return "没能识别到你的账号，请在手机 QQ 里重新给我发一次。"

        if code:
            result = relay.STORE.bind_by_code(code, user_openid)
            if result.get("ok"):
                logger.info("[绑定] 成功 code=%s user=%s", code, user_openid)
                return (
                    "绑定成功 ✅\n"
                    "回到「知了」App，在「订阅管理」里勾选你想接收通知的群。\n"
                    "（发的配对码 5 分钟内有效，只能使用一次）"
                )
            reason = result.get("reason")
            tips = {
                "invalid_code": "这个配对码我没找到，请在 App 里重新生成一个。",
                "expired_code": "配对码已过期（5 分钟有效），请在 App 里重新生成。",
                "used_code": "这个配对码已经用过了，请在 App 里重新生成一个。",
                "unknown_device": "配对码对应的设备已失效，请在 App 里重新生成。",
            }
            logger.info("[绑定] 失败 code=%s reason=%s", code, reason)
            return tips.get(reason, "绑定失败，请在 App 里重新生成配对码再试一次。")

        if content in ("解绑", "unbind"):
            # 单聊只能拿到 user_openid，反查设备后删除绑定
            removed = relay.STORE.unbind_by_openid(user_openid)
            logger.info("[解绑] user=%s removed=%s", user_openid, removed)
            return "已解除绑定。服务器上与本账号相关的绑定关系已删除。" if removed else "当前没有绑定关系。"

        # 其余内容（含空消息、问候语、"状态/帮助"）统一回一段使用说明
        bound = relay.STORE.devices_of_openid(user_openid)
        if bound:
            return (
                "你已经绑定「知了」✅\n"
                f"已授权的设备数：{len(bound)}\n"
                "在 App 的「订阅管理」里可以勾选要接收的群。\n"
                "发送「解绑」可以解除绑定。"
            )
        return (
            "你好，我是「知了」的信息采集机器人 🦗\n"
            "把 App 里显示的配对码发给我即可完成绑定，例如：绑定 7K3M9Q\n"
            "（我只会转发你订阅的群里公开可见的文本消息，不会读取你的本地聊天记录）"
        )

    async def _handle_group_message(self, message: GroupMessage, event_type: str):
        """群消息统一处理：打印 + 入库 + 交给中继服务按订阅分发。"""
        author = getattr(message, "author", None)
        sender = getattr(author, "username", None) or getattr(author, "member_openid", None) or "未知用户"
        group_openid = getattr(message, "group_openid", None)
        content = _plain_text(getattr(message, "content", None))

        logger.info("[群消息][%s] %s: %s", event_type, sender, content)
        logger.info(
            "  [id诊断] member_openid=%s user_openid=%s union_openid=%s union_account=%s",
            getattr(author, "member_openid", None),
            getattr(author, "user_openid", None),
            getattr(author, "union_openid", None),
            getattr(author, "union_user_account", None),
        )

        # ① 推给控制台服务（server.py）的中继窗口：App 从服务端进程拉消息。
        #    正文不落盘，只存在于服务端进程内存的 30 分钟窗口里。
        try:
            info = await self._push_to_relay(
                group_openid=group_openid,
                sender=sender,
                content=content or "",
                msg_id=getattr(message, "id", "") or "",
                timestamp=getattr(message, "timestamp", None),
                event_type=event_type,
                sender_openid=getattr(author, "member_openid", None) or "",
                attachments=_json_list(getattr(message, "attachments", None)),
            )
            if info.get("seq"):
                logger.info(
                    "  已推送到中继窗口 seq=%s（该群订阅设备数=%s）",
                    info["seq"],
                    info["subscribers"],
                )
        except Exception as e:
            logger.error("推送到中继失败: %s", e, exc_info=True)

        # ② 落本机的运维库（控制台「数据库」页要用；这是本地运维数据，不是分发通道）
        try:
            is_new = await save_group_message(message, event_type=event_type)
        except Exception as e:
            logger.error("入库失败: %s", e, exc_info=True)
            return

        if is_new:
            logger.info("  已入库 msg_id=%s group=%s", message.id, group_openid)
        else:
            logger.info("  重复消息，跳过 msg_id=%s", message.id)

    async def _push_to_relay(
        self,
        group_openid: str,
        sender: str,
        content: str,
        msg_id: str,
        timestamp,
        event_type: str,
        sender_openid: str,
        attachments: list | None = None,
    ) -> dict:
        """把群消息推给控制台服务（server.py）的中继窗口（HTTP 内部通道）。"""
        ts = "" if timestamp is None else str(timestamp)
        payload = {
            "group_openid": group_openid or "",
            "sender": sender,
            "content": content,
            "msg_id": msg_id,
            "timestamp": ts,
            "event_type": event_type,
            "sender_openid": sender_openid,
            "attachments": attachments or [],
        }
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.post(
                relay.INTERNAL_RELAY_URL,
                json=payload,
                headers={"X-Relay-Key": relay.INTERNAL_RELAY_KEY},
            )
            resp.raise_for_status()
            return resp.json()

    # ------------------------------------------------------------------
    # 原始事件日志（兜底排查）
    # ------------------------------------------------------------------

    def ws_dispatch(self, event: str, *args, **kwargs) -> None:
        """所有解析后的事件都经过这里，先打印再交给父类分发。

        这样即使平台下发的事件类型与预期不符，终端也能立刻看到，
        不会出现"什么都没发生"的黑盒状态。
        """
        if event not in ("ready", "resumed"):
            logger.info("收到网关事件: %s", event)
        super().ws_dispatch(event, *args, **kwargs)


async def main():
    if not APP_ID or not APP_SECRET:
        raise SystemExit(
            "错误：未检测到有效的 AppID/AppSecret。\n"
            "请确认 .env 文件存在且变量名为 QQBOT_APP_ID / QQBOT_SECRET。"
        )
    logger.info("使用 AppID: %s", APP_ID)

    await init_db()
    logger.info("数据库初始化完成")

    # public_messages = 1 << 25（GROUP_AND_C2C_EVENT），群聊消息必须带这个 intent
    intents = botpy.Intents(public_messages=True)

    client = MyClient(intents=intents)
    logger.info("正在启动机器人...")
    await client.start(appid=APP_ID, secret=APP_SECRET)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("已手动停止")
