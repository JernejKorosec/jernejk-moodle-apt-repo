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
  echo ERROR: %CFG% not found in repo root.
  echo Create it or copy the example content from documentation.
  exit /b 1
)

for %%V in (RELEASE_TAG PKG_VERSION SCRIPTS_DIR COMMIT_MESSAGE TAG_MESSAGE PUSH REMOTE BRANCH) do (
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
  echo ERROR: RELEASE_TAG is required in %CFG%.
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
  echo ERROR: scripts\%SCRIPTS_DIR% does not exist.
  exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
  echo ERROR: Not inside a git repository.
  exit /b 1
)

git rev-parse -q --verify "refs/tags/%RELEASE_TAG%" >nul 2>nul
if not errorlevel 1 (
  echo ERROR: Tag %RELEASE_TAG% already exists.
  exit /b 1
)

call :set_key "docker-script\00_config.env.example" "SCRIPTS_DIR" "%SCRIPTS_DIR%"
if errorlevel 1 exit /b 1
call :set_key "docker-script\00_config.env.example" "RELEASE_TAG" "%RELEASE_TAG%"
if errorlevel 1 exit /b 1
call :set_key "docker-script\00_config.env.example" "PKG_VERSION" "%PKG_VERSION%"
if errorlevel 1 exit /b 1

echo.
echo ===== Release Summary =====
echo RELEASE_TAG   = %RELEASE_TAG%
echo PKG_VERSION   = %PKG_VERSION%
echo SCRIPTS_DIR   = %SCRIPTS_DIR%
echo COMMIT_MESSAGE= %COMMIT_MESSAGE%
echo TAG_MESSAGE   = %TAG_MESSAGE%
echo PUSH          = %PUSH%
echo REMOTE/BRANCH = %REMOTE% / %BRANCH%
echo ===========================
echo.

git add -A

git diff --cached --quiet
if %ERRORLEVEL% EQU 0 (
  echo ERROR: No staged changes found. Nothing to commit.
  exit /b 1
)

git commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 (
  echo ERROR: Commit failed.
  exit /b 1
)

git tag -a "%RELEASE_TAG%" -m "%TAG_MESSAGE%"
if errorlevel 1 (
  echo ERROR: Failed to create tag %RELEASE_TAG%.
  exit /b 1
)

if /I "%PUSH%"=="true" goto :do_push
if /I "%PUSH%"=="1" goto :do_push
if /I "%PUSH%"=="yes" goto :do_push

echo Release commit and tag created locally.
echo Push manually if needed:
echo   git push %REMOTE% %BRANCH%
echo   git push %REMOTE% %RELEASE_TAG%
exit /b 0

:do_push
git push "%REMOTE%" "%BRANCH%"
if errorlevel 1 (
  echo ERROR: Push of branch failed.
  exit /b 1
)
git push "%REMOTE%" "%RELEASE_TAG%"
if errorlevel 1 (
  echo ERROR: Push of tag failed.
  exit /b 1
)
echo Release commit and tag pushed successfully.
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
echo commit_new.bat - Release commit and tag helper
echo.
echo PURPOSE
echo   Reads release variables from commit.ver, updates build config values,
echo   creates a git commit, creates an annotated git tag, and optionally pushes.
echo.
echo USAGE
echo   commit_new.bat
echo   commit_new.bat -h ^| --help ^| -help ^| help ^| ? ^| -?
echo.
echo REQUIRED FILE
echo   commit.ver in repository root.
echo.
echo commit.ver fields
echo   RELEASE_TAG    Required. Example: v0.18.0
echo   PKG_VERSION    Required/optional. Example: 0.18.0
echo                  If omitted, derived from RELEASE_TAG without leading v.
echo   SCRIPTS_DIR    Optional. Default: release
echo   COMMIT_MESSAGE Optional. Default: Release moodle-admin-scripts %%RELEASE_TAG%%
echo   TAG_MESSAGE    Optional. Default: Release %%RELEASE_TAG%%
echo   PUSH           Optional. true/false, yes/no, 1/0. Default: false
echo   REMOTE         Optional. Default: origin
echo   BRANCH         Optional. Default: main
echo.
echo WHAT IT CHANGES
echo   Updates these keys in docker-script\00_config.env.example:
echo     SCRIPTS_DIR, RELEASE_TAG, PKG_VERSION
echo   Then commits all staged changes and tags the commit.
echo.
echo EXAMPLE FLOW
echo   1. Edit commit.ver values.
echo   2. Run: commit_new.bat
echo   3. If PUSH=false, push manually later.
echo.
exit /b 0
