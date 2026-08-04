@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo  ============================================
echo   习惯见证者 - 本地预览服务器 (运行于E盘)
echo  ============================================
echo.
echo  本机访问    : http://127.0.0.1:8732/habit-witness-demo.html
echo  iPhone访问  : 用手机浏览器打开下面的局域网IP地址
echo                http://YOUR-IP:8732/habit-witness-demo.html
echo                (手机和电脑需连接同一个Wi-Fi)
echo.
echo  若Windows防火墙弹出提示, 请点击"允许访问".
echo  按 Ctrl+C 停止服务.
echo.
ipconfig | findstr /i "IPv4"
echo.
if not exist "%~dp0.runtime\python\python.exe" (
  echo  [错误] 未找到 E 盘 Python 运行时: .runtime\python\python.exe
  pause
  exit /b 1
)
"%~dp0.runtime\python\python.exe" -m http.server 8732 --bind 0.0.0.0
pause