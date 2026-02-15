@echo off
cd /d "%~dp0"
echo Logging into apt-repo container...
docker compose exec apt-repo bash
