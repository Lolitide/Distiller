@echo off
setlocal
cd /d "%~dp0"
title QQ Bot Console

rem Push Kit（后台通知）：服务账号 JSON + 项目 ID（服务账号文件里没有 project_id）
rem service_account.json 在 qqbot-backend 目录内，整个目录已被 .gitignore 排除
set QQBOT_PUSH_SA=%~dp0service_account.json
set QQBOT_PUSH_PROJECT_ID=101653523865357174

if /i "%~1"=="-silent" (
    wscript.exe //nologo "%~dp0run-silent.vbs"
    exit /b 0
)

echo ==========================================================
echo   QQ Bot Console
echo   Starting local web console...
echo ==========================================================
echo.

if /i not "%~1"=="-NoBrowser" (
    start "" /b cmd /c "timeout /t 2 <nul >nul 2>&1 & start "" http://127.0.0.1:8730"
)

".venv\Scripts\python.exe" -X utf8 server.py

echo.
echo Console stopped.
pause
