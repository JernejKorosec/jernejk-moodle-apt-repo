@echo off
cd /d "%~dp0"
set "COMPOSE_FILE=%~dp0docker\docker-compose.yml"
echo Logging into apt-repo container...
docker compose -f "%COMPOSE_FILE%" exec apt-repo bash
