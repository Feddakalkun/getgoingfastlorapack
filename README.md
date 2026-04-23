# Get Going Fast

Local-first LoRA workspace that wraps your existing ComfyUI installer and gives a clean training project wizard.

## Local features

- Launch `install-comfyUI-Manual-Universal.bat` from UI
- Launch `run-comfy.bat` and `Update-ComfyUI.bat` from UI
- Optional `Enable_CustomNodes_WeakSecurity.bat` action from UI
- Create LoRA project scaffolds in `projects/<slug>/`
- Keep project config (`project.json`) + starter `training-plan.md`

## Local run

1. Double-click `install.bat`
2. Double-click `run.bat`
3. Browser opens at [http://127.0.0.1:3000](http://127.0.0.1:3000)

`npm run dev` starts:
- Vite frontend on `3000`
- Local API on `8787`
