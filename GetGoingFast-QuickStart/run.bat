@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Get Going Fast - QuickStart Runner

set "LAUNCHER_DIR=%~dp0"
if "%LAUNCHER_DIR:~-1%"=="\" set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"
set "APP_ROOT=%LAUNCHER_DIR%\.."
set "TARGET_RUN=%APP_ROOT%\run.bat"

echo.
echo ============================================================
echo  GET GOING FAST - QUICKSTART RUN
echo ============================================================
echo.
echo  Launcher folder: %LAUNCHER_DIR%
echo  App root:        %APP_ROOT%
echo.

if /I "%~1"=="--dry-run" goto :dry_run

if not exist "%TARGET_RUN%" goto :missing

echo Delegating to:
echo   %TARGET_RUN%
echo.
call "%TARGET_RUN%"
exit /b %ERRORLEVEL%

:dry_run
echo [DRY RUN] run.bat wrapper is configured correctly.
if exist "%TARGET_RUN%" (
  echo [DRY RUN] Found target script.
  exit /b 0
) else (
  echo [DRY RUN] Missing target script.
  exit /b 1
)

:missing
echo [ERROR] Could not find:
echo   %TARGET_RUN%
echo.
echo Keep this QuickStart folder inside:
echo   H:\07-feddafront-v7\Fedda_hub-v10\get-going-fast
pause
exit /b 1
