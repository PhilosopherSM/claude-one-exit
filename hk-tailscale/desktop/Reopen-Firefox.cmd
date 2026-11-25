@echo off
setlocal
powershell.exe -NoProfile -File "%~dp0..\..\gnome-wslg\Ensure-Docker-Desktop.ps1" || goto failed
wsl.exe -d Ubuntu --cd "%~dp0..\..\gnome-wslg" -- bash ./Open-Docker-App.sh firefox --wslg %* || goto failed
exit /b 0

:failed
echo Could not reopen Firefox. Review the last step shown above.
if /i not "%~1"=="--check" pause
exit /b 1
