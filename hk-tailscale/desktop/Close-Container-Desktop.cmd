@echo off
setlocal
wsl.exe -d Ubuntu --cd "%~dp0." -- docker compose -f compose.browser.yaml stop browser
if not errorlevel 1 exit /b 0
echo Could not stop the desktop container. Check Docker Desktop and try again.
if /i not "%~1"=="--check" pause
exit /b 1
