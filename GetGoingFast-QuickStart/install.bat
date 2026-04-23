@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Get Going Fast - QuickStart Installer

set "LAUNCHER_DIR=%~dp0"
if "%LAUNCHER_DIR:~-1%"=="\" set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"
set "APP_ROOT=%LAUNCHER_DIR%\.."
set "TARGET_INSTALL=%APP_ROOT%\install.bat"

echo.
echo ============================================================
echo  GET GOING FAST - QUICKSTART INSTALL
echo ============================================================
echo.
echo  Launcher folder: %LAUNCHER_DIR%
echo  App root:        %APP_ROOT%
echo.

if /I "%~1"=="--dry-run" goto :dry_run

if not exist "%TARGET_INSTALL%" goto :missing

echo Delegating to:
echo   %TARGET_INSTALL%
echo.
call "%TARGET_INSTALL%"
exit /b %ERRORLEVEL%

:dry_run
echo [DRY RUN] install.bat wrapper is configured correctly.
if exist "%TARGET_INSTALL%" (
  echo [DRY RUN] Found target script.
  exit /b 0
) else (
  echo [DRY RUN] Missing target script.
  exit /b 1
)

:missing
echo [ERROR] Could not find:
echo   %TARGET_INSTALL%
echo.
echo Keep this QuickStart folder inside:
echo   H:\07-feddafront-v7\Fedda_hub-v10\get-going-fast
pause
exit /b 1
