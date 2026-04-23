@echo off
cd /d "%~dp0ComfyUI"

:: Activate virtual environment
call venv\scripts\activate

:: Detect if currently on a branch
for /f %%i in ('git symbolic-ref --short HEAD 2^>nul') do set branch=%%i

:: If not on a branch (i.e., detached HEAD), switch to master
if not defined branch (
    echo You are in a detached HEAD state. Switching to master...
    git checkout master
)

:: Pull latest changes
echo Pulling latest updates from GitHub...
git pull
python -m pip install -r requirements.txt

echo.
echo ============================
echo ComfyUI has been updated!
echo If you're using ComfyUI Manager, open it and run its own update function.
echo ============================
pause