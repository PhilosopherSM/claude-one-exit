@echo off
setlocal
if /i "%~1"=="--check" (
    wsl.exe -d Ubuntu --cd "%~dp0..\..\gnome-wslg" -- bash ./Open-Docker-App.sh prepare --check
    exit /b
)
call "%~dp0Reopen-Claude.cmd" || exit /b 1
call "%~dp0Reopen-Firefox.cmd"
exit /b
