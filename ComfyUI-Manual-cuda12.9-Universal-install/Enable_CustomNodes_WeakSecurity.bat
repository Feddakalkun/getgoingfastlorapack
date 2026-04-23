@echo off
setlocal EnableDelayedExpansion

:: -----------------------------------------------------------------------------
:: WARNING: Lowering security lets non-default channel custom_nodes install.
:: Use only if you understand the risk. You can revert later by setting
::   security_level = normal
:: -----------------------------------------------------------------------------

echo ============================================================
echo  WARNING
echo  This will set ComfyUI-Manager security_level to "weak".
echo  That reduces protections against untrusted custom nodes.
echo  Continue? ^(Y/N^)
echo ============================================================
choice /c YN /n
if errorlevel 2 (
  echo Aborted by user.
  exit /b 1
)

:: Target config file
set "CFG=%~dp0ComfyUI\user\default\ComfyUI-Manager\config.ini"

if not exist "%CFG%" (
  echo ERROR: File not found at %CFG%
  pause
  exit /b 1
)

:: Backup original
copy /y "%CFG%" "%CFG%.bak" >nul
if errorlevel 1 (
  echo Error: Could not create backup. Aborting.
  exit /b 1
)

:: Replace the security_level line with "weak"
set "TMP=%CFG%.tmp"
(for /f "usebackq delims=" %%A in ("%CFG%") do (
  echo %%A | findstr /b /c:"security_level =" >nul && (
    echo security_level = weak
  ) || (
    echo %%A
  )
)) > "%TMP%"

:: If no security_level line existed, append it
findstr /b /c:"security_level =" "%TMP%" >nul || (
  echo security_level = weak>>"%TMP%"
)

:: Move final file into place
move /y "%TMP%" "%CFG%" >nul

echo.
echo Done. security_level set to "weak".
echo A backup was saved as:
echo   %CFG%.bak
pause
endlocal
