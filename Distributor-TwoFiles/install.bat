@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Get Going Fast - Installer

set "REPO_URL=https://github.com/GGAFD/getgoingfast.git"
set "BASE_DIR=%~dp0"
if "%BASE_DIR:~-1%"=="\" set "BASE_DIR=%BASE_DIR:~0,-1%"
set "APP_DIR=%BASE_DIR%\GetGoingFast-App"
set "LOG_DIR=%BASE_DIR%\logs"
set "LOG_FILE=%LOG_DIR%\install.log"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul
echo [%date% %time%] installer start> "%LOG_FILE%"

echo.
echo ============================================================
echo  GET GOING FAST - ONE FILE INSTALLER
echo ============================================================
echo.
echo  This will install/update the app in:
echo    %APP_DIR%
echo.
echo  Repo:
echo    %REPO_URL%
echo.

where git >nul 2>nul || goto :err_git
where node >nul 2>nul || goto :err_node
where npm >nul 2>nul || goto :err_npm

echo [1/5] Tool checks passed.
echo [%date% %time%] tool checks ok>> "%LOG_FILE%"

if exist "%APP_DIR%\.git" (
  echo [2/5] Existing app found. Updating...
  pushd "%APP_DIR%" || goto :err_pushd

  for /f "delims=" %%r in ('git remote get-url origin 2^>nul') do set "ORIGIN_URL=%%r"
  if /I not "!ORIGIN_URL!"=="%REPO_URL%" (
    popd
    goto :err_remote
  )

  for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "CURRENT_BRANCH=%%b"
  if not defined CURRENT_BRANCH set "CURRENT_BRANCH=main"

  git fetch origin >> "%LOG_FILE%" 2>&1 || (popd & goto :err_git_update)
  git checkout !CURRENT_BRANCH! >> "%LOG_FILE%" 2>&1 || (popd & goto :err_git_update)
  git pull --ff-only origin !CURRENT_BRANCH! >> "%LOG_FILE%" 2>&1 || (popd & goto :err_git_update)
  popd
) else (
  echo [2/5] Cloning app...
  git clone %REPO_URL% "%APP_DIR%" >> "%LOG_FILE%" 2>&1 || goto :err_clone
)

echo [3/5] Installing npm dependencies...
pushd "%APP_DIR%" || goto :err_pushd
if not exist "package.json" (
  popd
  goto :err_empty_repo
)
call npm install >> "%LOG_FILE%" 2>&1 || (popd & goto :err_npm_install)

echo [4/5] Verifying build...
call npm run build >> "%LOG_FILE%" 2>&1 || (popd & goto :err_build)
popd

echo [5/5] Optional ComfyUI installer
set "COMFY_INSTALLER=%APP_DIR%\ComfyUI-Manual-cuda12.9-Universal-install\install-comfyUI-Manual-Universal.bat"
if exist "%COMFY_INSTALLER%" (
  choice /c YN /n /m "  Launch ComfyUI installer now? (Y/N): "
  if errorlevel 2 (
    echo  Skipped ComfyUI installer.
  ) else (
    start "Get Going Fast - Comfy Installer" cmd /k ""%COMFY_INSTALLER%""
  )
) else (
  echo  ComfyUI installer script not found. You can still run the app UI.
)

echo.
echo ============================================================
echo  INSTALL COMPLETE
echo ============================================================
echo.
echo  Next:
echo    Run run.bat in this same folder.
echo.
echo  Log:
echo    %LOG_FILE%
echo.
pause
exit /b 0

:err_git
echo [ERROR] Git not found. Install Git: https://git-scm.com/downloads
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
echo [ERROR] Could not enter app directory.
pause
exit /b 1

:err_remote
echo [ERROR] Existing app folder points to another git remote:
echo   !ORIGIN_URL!
echo Expected:
echo   %REPO_URL%
pause
exit /b 1

:err_git_update
echo [ERROR] Git update failed. See:
echo   %LOG_FILE%
pause
exit /b 1

:err_clone
echo [ERROR] Git clone failed. See:
echo   %LOG_FILE%
pause
exit /b 1

:err_empty_repo
echo [ERROR] Repo cloned, but app files are missing.
echo This usually means the GitHub repo is empty.
echo Push your project files to:
echo   %REPO_URL%
echo Then run install.bat again.
pause
exit /b 1

:err_npm_install
echo [ERROR] npm install failed. See:
echo   %LOG_FILE%
pause
exit /b 1

:err_build
echo [ERROR] npm run build failed. See:
echo   %LOG_FILE%
pause
exit /b 1
