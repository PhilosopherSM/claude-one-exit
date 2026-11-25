@echo off
setlocal
powershell.exe -NoProfile -File "%~dp0gnome-wslg\Ensure-Docker-Desktop.ps1" || goto failed
wsl.exe -d Ubuntu --cd "%~dp0." --exec /bin/bash ./setup.sh || goto failed
powershell.exe -NoProfile -File "%~dp0gnome-wslg\Install-Docker-StartMenu.ps1" || goto failed
echo Ready. Search Start for Claude (Docker), Firefox (Docker), or Terminal (Docker).
pause
exit /b 0
:failed
echo Setup stopped. Review the message above and docs\setup.md, then run Setup.cmd again.
pause
exit /b 1
