@echo off
chcp 65001 >nul
cd /d "%~dp0"

rem dev 模式的两个开关（这里是唯一来源，start.bat 也复用本脚本）
rem 控制台只绑本机：局域网扫不到；对外只经内网穿透的「公开口」(QQBOT_PUBLIC_PORT)
set QQBOT_CONSOLE_HOST=127.0.0.1
set QQBOT_DEV_INGEST=1
rem 一条龙：后端起来后自动把机器人拉起来（不用再去网页点「启动」）
set QQBOT_AUTOSTART_BOT=1

rem Push Kit（后台通知）：服务账号 JSON —— 千万别进仓库（qqbot-backend 整个目录已被 .gitignore）
rem 服务账号文件里**没有** project_id（新格式），所以单独给一个
set QQBOT_PUSH_SA=%~dp0service_account.json
set QQBOT_PUSH_PROJECT_ID=101653523865357174

rem 被 start.bat / run-dev-silent.vbs 调用时：隐藏窗口直接跑，不打印横幅、不 pause
if /i "%~1"=="-silent" (
    ".venv\Scripts\python.exe" -X utf8 server.py
    exit /b 0
)

echo ============================================================
echo   知了 · 机器人通道【联调模式】
echo ============================================================
echo   与 console.bat 的区别：
echo     1. 控制台只监听本机（局域网扫不到）
echo     2. 打开假消息注入开关，机器人没上线也能测 App
echo.
echo   手机 App 里填「内网穿透」的固定地址（见 funnel.bat / tunnel.bat 的输出）
echo.
echo   注入一条测试消息（另开一个 PowerShell 窗口执行）：
echo     $b="http://127.0.0.1:8730"
echo     $r=Invoke-RestMethod "$b/api/relay/device/register" -Method Post -ContentType "application/json" -Body '{}'
echo     $h=@{"X-Device-Id"=$r.data.device_id;"X-Device-Token"=$r.data.token}
echo     Invoke-RestMethod "$b/api/relay/dev/ingest" -Method Post -Headers $h -ContentType "application/json" -Body '{"group_openid":"PASTE_GROUP_ID"}'
echo ============================================================
echo.

".venv\Scripts\python.exe" -X utf8 server.py
pause
