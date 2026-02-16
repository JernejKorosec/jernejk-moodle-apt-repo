@echo off
cd /d "%~dp0"
set "DOCKER_DIR=%~dp0docker"
set "COMPOSE_FILE=%DOCKER_DIR%\docker-compose.yml"
set "DOCKERFILE=%DOCKER_DIR%\Dockerfile"

echo.
echo ========================================
echo Starting apt-repo container...
echo ========================================
echo.

echo [1/3] Checking Docker daemon...
docker ps >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not running!
    pause
    exit /b 1
)
echo [OK] Docker is running
echo.

echo [2/3] Building/rebuilding image...
call docker build -t jernejk-moodle-apt-repo-builder -f "%DOCKERFILE%" "%DOCKER_DIR%"
echo [OK] Image built successfully
echo.

echo [3/3] Starting container...
call docker compose -f "%COMPOSE_FILE%" up -d apt-repo
echo [OK] Container started successfully!
echo.
echo ========================================
echo Container is ready. Run login.bat to enter.
echo ========================================
echo.
pause
