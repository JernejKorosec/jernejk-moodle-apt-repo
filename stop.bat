@echo off
cd /d "%~dp0"
set "COMPOSE_FILE=%~dp0docker\docker-compose.yml"
echo Stopping apt-repo container...
call docker compose -f "%COMPOSE_FILE%" down
echo.
echo Container stopped successfully!
pause
