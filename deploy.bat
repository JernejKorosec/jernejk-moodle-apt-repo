@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help
if /I "%~1"=="-help" goto :help
if /I "%~1"=="help" goto :help
if "%~1"=="?" goto :help
if "%~1"=="-?" goto :help

set "CFG=commit.ver"
if not exist "%CFG%" (
  echo ERROR: %CFG% not found.
  exit /b 1
)

for %%V in (RELEASE_TAG PKG_VERSION SCRIPTS_DIR COMMIT_MESSAGE TAG_MESSAGE PUSH REMOTE BRANCH GPG_KEY_ID MAINTAINER_NAME MAINTAINER_EMAIL) do (
  set "%%V="
)

for /f "usebackq tokens=1,* delims==" %%A in ("%CFG%") do (
  set "k=%%A"
  set "v=%%B"
  call :trim k
  if defined k (
    if not "!k:~0,1!"=="#" (
      if not "!k:~0,1!"==";" (
        call :trim v
        set "!k!=!v!"
      )
    )
  )
)

if not defined RELEASE_TAG (
  echo ERROR: RELEASE_TAG missing in %CFG%.
  exit /b 1
)
if not defined PKG_VERSION (
  set "PKG_VERSION=%RELEASE_TAG:v=%"
)
if not defined SCRIPTS_DIR (
  set "SCRIPTS_DIR=release"
)
if not defined COMMIT_MESSAGE (
  set "COMMIT_MESSAGE=Release moodle-admin-scripts %RELEASE_TAG%"
)
if not defined TAG_MESSAGE (
  set "TAG_MESSAGE=Release %RELEASE_TAG%"
)
if not defined PUSH (
  set "PUSH=false"
)
if not defined REMOTE (
  set "REMOTE=origin"
)
if not defined BRANCH (
  set "BRANCH=main"
)

if not exist "scripts\%SCRIPTS_DIR%" (
  echo ERROR: scripts\%SCRIPTS_DIR% not found.
  exit /b 1
)

echo.
echo ===== Click Deploy =====
echo RELEASE_TAG   = %RELEASE_TAG%
echo PKG_VERSION   = %PKG_VERSION%
echo SCRIPTS_DIR   = %SCRIPTS_DIR%
echo PUSH          = %PUSH%
echo REMOTE/BRANCH = %REMOTE% / %BRANCH%
echo ========================
echo.

echo [1/6] Checking Docker daemon...
docker ps >nul 2>nul
if errorlevel 1 (
  echo ERROR: Docker is not running.
  exit /b 1
)

echo [2/6] Building image...
docker build -t jernejk-moodle-apt-repo-builder .
if errorlevel 1 (
  echo ERROR: docker build failed.
  exit /b 1
)

echo [3/6] Starting container...
docker compose up -d apt-repo
if errorlevel 1 (
  echo ERROR: docker compose up failed.
  exit /b 1
)

echo [4/6] Writing docker-script/00_config.env from commit.ver...
copy /y "docker-script\00_config.env.example" "docker-script\00_config.env" >nul
if errorlevel 1 (
  echo ERROR: Failed to create docker-script\00_config.env.
  exit /b 1
)

call :set_key "docker-script\00_config.env" "SCRIPTS_DIR" "%SCRIPTS_DIR%"
if errorlevel 1 exit /b 1
call :set_key "docker-script\00_config.env" "RELEASE_TAG" "%RELEASE_TAG%"
if errorlevel 1 exit /b 1
call :set_key "docker-script\00_config.env" "PKG_VERSION" "%PKG_VERSION%"
if errorlevel 1 exit /b 1
if defined GPG_KEY_ID (
  call :set_key "docker-script\00_config.env" "GPG_KEY_ID" "%GPG_KEY_ID%"
  if errorlevel 1 exit /b 1
)
if defined MAINTAINER_NAME (
  call :set_key "docker-script\00_config.env" "MAINTAINER_NAME" "%MAINTAINER_NAME%"
  if errorlevel 1 exit /b 1
)
if defined MAINTAINER_EMAIL (
  call :set_key "docker-script\00_config.env" "MAINTAINER_EMAIL" "%MAINTAINER_EMAIL%"
  if errorlevel 1 exit /b 1
)

echo [5/6] Running build/sign pipeline in container...
docker compose exec apt-repo bash -lc "chmod +x /docker-script/*.sh && bash /docker-script/run_all.sh"
if errorlevel 1 (
  echo ERROR: run_all.sh failed.
  exit /b 1
)

echo [6/6] Running commit/tag/push flow...
call commit_new.bat
if errorlevel 1 (
  echo ERROR: commit_new.bat failed.
  exit /b 1
)

echo.
echo Click deploy completed successfully.
exit /b 0

:trim
set "s=!%~1!"
for /f "tokens=* delims= " %%Z in ("!s!") do set "s=%%Z"
:trim_tail
if defined s if "!s:~-1!"==" " (
  set "s=!s:~0,-1!"
  goto :trim_tail
)
set "%~1=!s!"
exit /b 0

:set_key
set "_file=%~1"
set "_key=%~2"
set "_val=%~3"
powershell -NoProfile -Command "$f='%_file%'; $k='%_key%'; $v='%_val%'; if(-not (Test-Path $f)){ exit 2 }; $c=Get-Content $f; if($c -match ('^'+[regex]::Escape($k)+'=')){ $c=$c -replace ('^'+[regex]::Escape($k)+'=.*$'), ($k+'='+$v) } else { $c += ($k+'='+$v) }; Set-Content $f $c"
if errorlevel 1 (
  echo ERROR: Failed updating %_key% in %_file%.
  exit /b 1
)
exit /b 0

:help
echo.
echo deploy.bat - One-command build/sign/commit/tag/push release flow
echo.
echo USAGE
echo   deploy.bat
echo   deploy.bat -h ^| --help ^| -help ^| help ^| ? ^| -?
echo.
echo REQUIRED
echo   commit.ver in repository root
echo.
echo FLOW
echo   1. Read commit.ver
echo   2. docker build
echo   3. docker compose up -d apt-repo
echo   4. Create/update docker-script\00_config.env
echo   5. Run /docker-script/run_all.sh in container
echo   6. Run commit_new.bat (commit + tag + optional push)
echo.
echo NOTES
echo   - GPG signing happens in step 5 if GPG_KEY_ID is set in docker-script\00_config.env.
echo   - Push behavior is controlled by PUSH/REMOTE/BRANCH in commit.ver.
echo   - To prepare GPG key first: bash /docker-script/07_gpg_setup.sh
echo.
exit /b 0
