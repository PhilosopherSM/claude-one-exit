@echo off
wsl.exe -d Ubuntu -- systemctl --user stop ubuntu-wslg-wayland.service
if errorlevel 1 pause
