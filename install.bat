@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Get Going Fast - Installer

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "LOG_DIR=%ROOT%\logs"
set "LOG_FILE=%LOG_DIR%\install.log"
set "COMFY_INSTALLER=%ROOT%\ComfyUI-Manual-cuda12.9-Universal-install\install-comfyUI-Manual-Universal.bat"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
echo [%date% %time%] install start> "%LOG_FILE%"

echo.
echo ============================================================
echo  GET GOING FAST - ONE CLICK INSTALL
echo ============================================================
echo.
echo  Target: %ROOT%
echo.

where node >nul 2>nul || goto :err_node
where npm >nul 2>nul || goto :err_npm

echo [1/4] Node/npm checks passed.
echo [%date% %time%] node/npm check ok>> "%LOG_FILE%"

echo [2/4] Installing app dependencies...
pushd "%ROOT%" || goto :err_pushd
call npm install >> "%LOG_FILE%" 2>&1
if not "%ERRORLEVEL%"=="0" (
  popd
  goto :err_npm_install
)

echo [3/4] Building app once to verify setup...
call npm run build >> "%LOG_FILE%" 2>&1
if not "%ERRORLEVEL%"=="0" (
  popd
  goto :err_build
)
popd

echo [4/4] Optional ComfyUI local install
if exist "%COMFY_INSTALLER%" (
  echo.
  choice /c YN /n /m "  Launch ComfyUI installer now? (Y/N): "
  if errorlevel 2 (
    echo  Skipped ComfyUI installer.
  ) else (
    echo  Launching ComfyUI installer in a new window...
    start "Get Going Fast - Comfy Installer" cmd /k ""%COMFY_INSTALLER%""
  )
) else (
  echo  Comfy installer not found at:
  echo    %COMFY_INSTALLER%
)

echo.
echo ============================================================
echo  INSTALL COMPLETE
echo ============================================================
echo.
echo  Next step:
echo    run.bat
echo.
echo  Install log:
echo    %LOG_FILE%
echo.
pause
exit /b 0

:err_node
echo.
echo [ERROR] Node.js not found.
echo Install Node.js LTS: https://nodejs.org/
echo [%date% %time%] ERROR node missing>> "%LOG_FILE%"
pause
exit /b 1

:err_npm
echo.
echo [ERROR] npm not found.
echo Reinstall Node.js LTS so npm is included.
echo [%date% %time%] ERROR npm missing>> "%LOG_FILE%"
pause
exit /b 1

:err_pushd
echo.
echo [ERROR] Could not enter project folder.
echo [%date% %time%] ERROR pushd failed>> "%LOG_FILE%"
pause
exit /b 1

:err_npm_install
echo.
echo [ERROR] npm install failed.
echo Check: %LOG_FILE%
echo [%date% %time%] ERROR npm install failed>> "%LOG_FILE%"
pause
exit /b 1

:err_build
echo.
echo [ERROR] npm run build failed.
echo Check: %LOG_FILE%
echo [%date% %time%] ERROR build failed>> "%LOG_FILE%"
pause
exit /b 1
