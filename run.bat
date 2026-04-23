@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Get Going Fast - Launcher

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "LOG_DIR=%ROOT%\logs"
set "RUN_LOG=%LOG_DIR%\run.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
echo [%date% %time%] run start> "%RUN_LOG%"

echo.
echo ============================================================
echo  GET GOING FAST - RUN
echo ============================================================
echo.

where node >nul 2>nul || goto :err_node
where npm >nul 2>nul || goto :err_npm

pushd "%ROOT%" || goto :err_pushd

if not exist "node_modules" (
  echo [1/3] node_modules missing, installing...
  call npm install >> "%RUN_LOG%" 2>&1
  if not "%ERRORLEVEL%"=="0" (
    popd
    goto :err_npm_install
  )
)

echo [2/3] Starting local API + web UI...
echo [%date% %time%] starting npm run dev>> "%RUN_LOG%"

echo [3/3] Opening browser...
start "" "http://127.0.0.1:3000"

call npm run dev
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" (
  echo.
  echo [ERROR] App stopped with code %EXIT_CODE%
  echo Check: %RUN_LOG%
  pause
  exit /b %EXIT_CODE%
)

exit /b 0

:err_node
echo.
echo [ERROR] Node.js not found.
echo Install Node.js LTS: https://nodejs.org/
pause
exit /b 1

:err_npm
echo.
echo [ERROR] npm not found.
echo Reinstall Node.js LTS so npm is included.
pause
exit /b 1

:err_pushd
echo.
echo [ERROR] Could not enter project folder.
pause
exit /b 1

:err_npm_install
echo.
echo [ERROR] npm install failed.
echo Check: %RUN_LOG%
pause
exit /b 1
