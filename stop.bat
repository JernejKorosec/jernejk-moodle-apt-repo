@echo off
cd /d "%~dp0"
echo Stopping apt-repo container...
call docker compose down
echo.
echo Container stopped successfully!
pause
