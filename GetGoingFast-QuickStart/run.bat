@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Get Going Fast - Portable Runner

set "LAUNCHER_DIR=%~dp0"
if "%LAUNCHER_DIR:~-1%"=="\" set "LAUNCHER_DIR=%LAUNCHER_DIR:~0,-1%"
set "CFG_FILE=%LAUNCHER_DIR%\launcher.config"
set "APP_ROOT="
set "LOG_DIR=%LAUNCHER_DIR%\logs"
set "RUN_LOG=%LOG_DIR%\run.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
echo [%date% %time%] portable run start> "%RUN_LOG%"

echo.
echo ============================================================
echo  GET GOING FAST - PORTABLE RUN
echo ============================================================
echo.
echo  This launcher can live anywhere.
echo.

call :resolve_app_root
if errorlevel 1 goto :abort

echo  Using app root:
echo    %APP_ROOT%
echo.

if /I "%~1"=="--dry-run" (
  echo [DRY RUN] Resolution OK.
  echo [DRY RUN] App root: %APP_ROOT%
  exit /b 0
)

where node >nul 2>nul || goto :err_node
where npm >nul 2>nul || goto :err_npm

pushd "%APP_ROOT%" || goto :err_pushd
if not exist "node_modules" (
  echo node_modules missing, running npm install...
  call npm install >> "%RUN_LOG%" 2>&1
  if not "%ERRORLEVEL%"=="0" (
    popd
    goto :err_npm_install
  )
)

start "" "http://127.0.0.1:3000"
echo Starting app...
call npm run dev
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
  echo [ERROR] App exited with code %EXIT_CODE%.
  echo See log:
  echo   %RUN_LOG%
  pause
  exit /b %EXIT_CODE%
)

exit /b 0

:resolve_app_root
if exist "%CFG_FILE%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%CFG_FILE%") do (
    if /I "%%A"=="APP_ROOT" set "APP_ROOT=%%B"
  )
)
if defined APP_ROOT call :validate_app_root "%APP_ROOT%" && exit /b 0

set "CANDIDATE=%LAUNCHER_DIR%\.."
call :validate_app_root "%CANDIDATE%"
if not errorlevel 1 (
  set "APP_ROOT=%CANDIDATE%"
  goto :save_and_ok
)

set "CANDIDATE=%CD%"
call :validate_app_root "%CANDIDATE%"
if not errorlevel 1 (
  set "APP_ROOT=%CANDIDATE%"
  goto :save_and_ok
)

echo Enter full path to your get-going-fast folder.
set /p "APP_ROOT=Path: "
if not defined APP_ROOT exit /b 1

call :validate_app_root "%APP_ROOT%"
if errorlevel 1 (
  echo [ERROR] That path is not a valid get-going-fast app root.
  echo Required: package.json, src\App.tsx, server\index.ts
  exit /b 1
)

:save_and_ok
> "%CFG_FILE%" echo APP_ROOT=%APP_ROOT%
exit /b 0

:validate_app_root
set "TRY_PATH=%~1"
if not exist "%TRY_PATH%\package.json" exit /b 1
if not exist "%TRY_PATH%\src\App.tsx" exit /b 1
if not exist "%TRY_PATH%\server\index.ts" exit /b 1
exit /b 0

:abort
echo [ERROR] Could not resolve app root.
pause
exit /b 1

:err_node
echo [ERROR] Node.js not found. Install Node.js LTS first.
pause
exit /b 1

:err_npm
echo [ERROR] npm not found. Reinstall Node.js LTS.
pause
exit /b 1

:err_pushd
echo [ERROR] Could not enter app root:
echo   %APP_ROOT%
pause
exit /b 1

:err_npm_install
echo [ERROR] npm install failed. See log:
echo   %RUN_LOG%
pause
exit /b 1
