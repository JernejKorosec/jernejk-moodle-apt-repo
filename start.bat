@echo off
cd /d "%~dp0"

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
call docker build -t jernejk-moodle-apt-repo-builder .
echo [OK] Image built successfully
echo.

echo [3/3] Starting container...
call docker compose up -d apt-repo
echo [OK] Container started successfully!
echo.
echo ========================================
echo Container is ready. Run login.bat to enter.
echo ========================================
echo.
pause
