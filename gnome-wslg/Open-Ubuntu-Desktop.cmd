@echo off
wsl.exe -d Ubuntu --cd "%~dp0." -- bash ./Start-Ubuntu-Wayland.sh
if errorlevel 1 pause
