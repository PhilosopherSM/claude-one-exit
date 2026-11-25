@echo off
setlocal
wsl.exe -d Ubuntu --cd "%~dp0." -- bash ./Start-Ubuntu-Wayland.sh || goto failed

powershell.exe -NoProfile -File "%~dp0Ensure-Docker-Desktop.ps1" || goto failed

call "%~dp0..\hk-tailscale\desktop\Open-Container-Desktop.cmd" --check || goto failed
exit /b 0

:failed
echo.
echo Setup did not finish. See the last step above.
echo No browser or Claude window was opened by this launcher.
pause
exit /b 1
