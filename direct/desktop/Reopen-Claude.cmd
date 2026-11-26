@echo off
setlocal
powershell.exe -NoProfile -File "%~dp0..\..\gnome-wslg\Ensure-Docker-Desktop.ps1" || goto failed
wsl.exe -d Ubuntu --cd "%~dp0..\..\gnome-wslg" -- bash ./Open-Docker-App.sh claude --wslg %* || goto failed
if /i "%~1"=="--check" exit /b 0
start "" /min powershell.exe -WindowStyle Hidden -NoProfile -STA -File "%~dp0..\..\gnome-wslg\Bridge-Claude-Screenshot.ps1"
exit /b 0

:failed
echo Could not reopen Claude. Review the last step shown above.
if /i not "%~1"=="--check" pause
exit /b 1
