@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Get Going Fast - Runner

set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "APP_DIR=%BASE_DIR%\GetGoingFast-App"
set "LOG_DIR=%BASE_DIR%\logs"
set "RUN_LOG=%LOG_DIR%\run.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
echo [%date% %time%] runner start> "%RUN_LOG%"

echo.
echo ============================================================
echo  GET GOING FAST - RUN
echo ============================================================
echo.

if not exist "%APP_DIR%\package.json" goto :err_missing

where node >nul 2>nul || goto :err_node
where npm >nul 2>nul || goto :err_npm

pushd "%APP_DIR%" || goto :err_pushd
if not exist "node_modules" (
  echo node_modules missing, installing...
  call npm install >> "%RUN_LOG%" 2>&1 || (popd & goto :err_npm_install)
)

start "" "http://127.0.0.1:3000"
echo Starting app (frontend + local API)...
call npm run dev
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
  echo.
  echo [ERROR] App exited with code %EXIT_CODE%.
  echo Check log:
  echo   %RUN_LOG%
  pause
  exit /b %EXIT_CODE%
)
exit /b 0

:err_missing
echo [ERROR] App not installed in:
echo   %APP_DIR%
echo.
echo Run install.bat first.
pause
exit /b 1

:err_node
echo [ERROR] Node.js not found. Install Node.js LTS: https://nodejs.org/
pause
exit /b 1

:err_npm
echo [ERROR] npm not found. Reinstall Node.js LTS.
pause
exit /b 1

:err_pushd
echo [ERROR] Could not enter app directory:
echo   %APP_DIR%
pause
exit /b 1

:err_npm_install
echo [ERROR] npm install failed. Check log:
echo   %RUN_LOG%
pause
exit /b 1
