@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

cd /d "%~dp0"
IF EXIST "disclaimer.md" (
   TYPE "disclaimer.md"
   pause
)

IF EXIST "about.nfo" TYPE "about.nfo"

ECHO.

:: Detect installed Python versions
set "FOUND_PYTHON="
for %%V in (3.10 3.11 3.12 3.13) do (
    py -%%V --version >nul 2>&1
    if !errorlevel! == 0 (
        if not defined FOUND_PYTHON set "FOUND_PYTHON=%%V"
    )
)

if defined FOUND_PYTHON (
    echo Detected Python %FOUND_PYTHON% on your system.
    set "DEFAULT_PY=!FOUND_PYTHON!"
) else (
    echo No supported Python detected. You will need 3.10 - 3.13 installed.
    set "DEFAULT_PY=3.10"
)

:PYTHON_VERSION
echo.
echo Please select your Python version [default: %DEFAULT_PY%]:
echo 1. Python 3.10
echo 2. Python 3.11
echo 3. Python 3.12
echo 4. Python 3.13
echo.
set /p PYTHON_CHOICE="Enter your choice (1-4, or press Enter for default): "

if "%PYTHON_CHOICE%"=="" (
    set PYTHON_VERSION=%DEFAULT_PY%
) else if "%PYTHON_CHOICE%"=="1" (
    set PYTHON_VERSION=3.10
) else if "%PYTHON_CHOICE%"=="2" (
    set PYTHON_VERSION=3.11
) else if "%PYTHON_CHOICE%"=="3" (
    set PYTHON_VERSION=3.12
) else if "%PYTHON_CHOICE%"=="4" (
    set PYTHON_VERSION=3.13
) else (
    echo Invalid choice. Try again.
    goto PYTHON_VERSION
)

:: Verify Python version exists
py -%PYTHON_VERSION% --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Python %PYTHON_VERSION% is not installed on this system.
    echo Please install it before running choosing this option.
    echo.
    pause
    exit /b
)

echo.
echo Installing ComfyUI with Python %PYTHON_VERSION%...
echo.

git clone https://github.com/comfyanonymous/ComfyUI.git

cd ComfyUI
:: Ensure ComfyUI is on tracked branch (avoid detached HEAD)
git fetch origin
git checkout master 2>nul || git checkout main
git reset --hard origin/HEAD

:: Create and activate venv
echo Creating virtual environment...
py -%PYTHON_VERSION% -m venv venv
if errorlevel 1 (
    echo Failed to create venv!
    pause
    exit /b
)

call venv\Scripts\activate

:: Upgrade pip
python -m pip install --upgrade pip

:: Install core requirements
pip install -r requirements.txt
pip uninstall -y torch torchvision torchaudio
pip install torch==2.8.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129
pip install torchsde
pip install "triton-windows<3.5" onnx onnxruntime onnxruntime-gpu accelerate diffusers huggingface_hub hf_transfer hf_xet piexif requests ultralytics==8.3.197

:: Install Acceleration
if "%PYTHON_VERSION%"=="3.10" (
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py310/flash_attn-2.8.2-cp310-cp310-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py310/sageattention-2.2.0+cu128torch2.8.0.post2-cp39-abi3-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py310/insightface-0.7.3-cp310-cp310-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py310/deepspeed-0.16.5-cp310-cp310-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py310/xformers-0.0.33+c159edc0.d20250906-cp39-abi3-win_amd64.whl
) else if "%PYTHON_VERSION%"=="3.11" (
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py311/flash_attn-2.8.2-cp311-cp311-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py311/sageattention-2.2.0+cu128torch2.8.0.post2-cp39-abi3-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py311/insightface-0.7.3-cp311-cp311-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py311/deepspeed-0.16.5-cp311-cp311-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py311/xformers-0.0.33+c159edc0.d20250906-cp39-abi3-win_amd64.whl
) else if "%PYTHON_VERSION%"=="3.12" (
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py312/flash_attn-2.8.2-cp312-cp312-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py312/sageattention-2.2.0+cu128torch2.8.0.post2-cp39-abi3-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py312/insightface-0.7.3-cp312-cp312-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py312/deepspeed-0.16.5-cp312-cp312-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py312/xformers-0.0.33+c159edc0.d20250906-cp39-abi3-win_amd64.whl
) else if "%PYTHON_VERSION%"=="3.13" (
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py313/flash_attn-2.8.2-cp313-cp313-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py313/sageattention-2.2.0+cu128torch2.8.0.post2-cp39-abi3-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py313/insightface-0.7.3-cp313-cp313-win_amd64.whl
    pip install https://github.com/gjnave/support-files/raw/main/support/wheels/py313/xformers-0.0.33+c159edc0.d20250906-cp39-abi3-win_amd64.whl
)


:: Setup custom_nodes
cd custom_nodes
IF NOT EXIST "ComfyUI-Manager" git clone https://github.com/ltdrdata/ComfyUI-Manager
IF NOT EXIST "ComfyUI_IPAdapter_plus" git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus
IF NOT EXIST "ComfyUI-GGUF" git clone https://github.com/city96/ComfyUI-GGUF

REM Download Base Models
:: Download deliberate_v2.safetensors
IF NOT EXIST "%~dp0ComfyUI\models\checkpoints\deliberate_v2.safetensors"  (
    curl -L "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16" -o "ComfyUI\models\checkpoints\deliberate_v2.safetensors" --progress-bar
)

:: Download v1-5-pruned-emaonly.safetensors
IF NOT EXIST "%~dp0ComfyUI\models\checkpoints\v1-5-pruned-emaonly.safetensors" (
    curl -L "https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" -o "ComfyUI\models\checkpoints\v1-5-pruned-emaonly.safetensors" --progress-bar
)

echo.
echo Installation complete!
echo Launching ComfyUI...
echo.

cd /d "%~dp0ComfyUI"
call venv\Scripts\activate
python main.py

pause
