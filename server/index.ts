import express from "express";
import fs from "node:fs";
import path from "node:path";
import { execFileSync, spawn } from "node:child_process";

type ProjectConfig = {
  id: string;
  name: string;
  token: string;
  repeats: number;
  steps: number;
  resolution: string;
  createdAt: string;
};

const app = express();
const port = 8787;

const workspaceRoot = path.resolve(process.cwd());
const installerDir = path.join(workspaceRoot, "ComfyUI-Manual-cuda12.9-Universal-install");
const comfyDir = path.join(installerDir, "ComfyUI");
const projectsDir = path.join(workspaceRoot, "projects");

app.use(express.json({ limit: "2mb" }));

function ensureProjectsDir() {
  if (!fs.existsSync(projectsDir)) {
    fs.mkdirSync(projectsDir, { recursive: true });
  }
}

function slugify(input: string) {
  return input.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}

function runBatch(batchFileName: string) {
  const batchPath = path.join(installerDir, batchFileName);
  if (!fs.existsSync(batchPath)) {
    throw new Error(`Missing script: ${batchFileName}`);
  }

  spawn("cmd.exe", ["/c", "start", "", batchPath], {
    cwd: installerDir,
    detached: true,
    stdio: "ignore"
  }).unref();
}

function detectComfyRunning() {
  try {
    const raw = execFileSync(
      "powershell",
      [
        "-NoProfile",
        "-Command",
        "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*ComfyUI*main.py*' } | Select-Object -First 1 ProcessId,Name | ConvertTo-Json -Compress"
      ],
      { encoding: "utf8" }
    ).trim();
    if (!raw) {
      return null;
    }
    return JSON.parse(raw) as { ProcessId: number; Name: string };
  } catch {
    return null;
  }
}

function detectPythonVersions() {
  try {
    const result = execFileSync("py", ["-0p"], { encoding: "utf8" });
    return result
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.startsWith("-"));
  } catch {
    return [];
  }
}

function listProjects() {
  ensureProjectsDir();
  const folders = fs.readdirSync(projectsDir, { withFileTypes: true }).filter((entry) => entry.isDirectory());
  return folders
    .map((entry) => {
      const projectFile = path.join(projectsDir, entry.name, "project.json");
      if (!fs.existsSync(projectFile)) {
        return null;
      }
      try {
        return JSON.parse(fs.readFileSync(projectFile, "utf8")) as ProjectConfig;
      } catch {
        return null;
      }
    })
    .filter((item): item is ProjectConfig => item !== null)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

app.get("/api/health", (_req, res) => {
  res.json({ ok: true });
});

app.get("/api/comfy/status", (_req, res) => {
  const runningProcess = detectComfyRunning();
  const pythonVersions = detectPythonVersions();
  res.json({
    installerDir,
    comfyDir,
    installerReady: fs.existsSync(path.join(installerDir, "install-comfyUI-Manual-Universal.bat")),
    comfyInstalled:
      fs.existsSync(comfyDir) &&
      fs.existsSync(path.join(comfyDir, "main.py")) &&
      fs.existsSync(path.join(comfyDir, "venv")),
    comfyRunning: Boolean(runningProcess),
    runningProcess,
    pythonVersions,
    projects: listProjects()
  });
});

app.post("/api/comfy/install", (_req, res) => {
  try {
    runBatch("install-comfyUI-Manual-Universal.bat");
    res.json({ ok: true, message: "Installer launched in a new terminal window." });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to start installer.";
    res.status(400).json({ ok: false, message });
  }
});

app.post("/api/comfy/run", (_req, res) => {
  try {
    runBatch("run-comfy.bat");
    res.json({ ok: true, message: "ComfyUI launch command started." });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to launch ComfyUI.";
    res.status(400).json({ ok: false, message });
  }
});

app.post("/api/comfy/update", (_req, res) => {
  try {
    runBatch("Update-ComfyUI.bat");
    res.json({ ok: true, message: "Update script started." });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to start updater.";
    res.status(400).json({ ok: false, message });
  }
});

app.post("/api/comfy/weak-security", (_req, res) => {
  try {
    runBatch("Enable_CustomNodes_WeakSecurity.bat");
    res.json({ ok: true, message: "Weak security script started (confirm in terminal)." });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Failed to start weak security script.";
    res.status(400).json({ ok: false, message });
  }
});

app.post("/api/projects/create", (req, res) => {
  const {
    name,
    token,
    repeats = 16,
    steps = 2400,
    resolution = "1024,1024"
  } = (req.body ?? {}) as Partial<ProjectConfig>;

  if (!name || !token) {
    res.status(400).json({ ok: false, message: "Project name and token are required." });
    return;
  }

  ensureProjectsDir();
  const id = slugify(name) || `project-${Date.now()}`;
  const dir = path.join(projectsDir, id);
  fs.mkdirSync(path.join(dir, "dataset", "raw"), { recursive: true });
  fs.mkdirSync(path.join(dir, "dataset", "train"), { recursive: true });
  fs.mkdirSync(path.join(dir, "output", "lora"), { recursive: true });
  fs.mkdirSync(path.join(dir, "logs"), { recursive: true });

  const config: ProjectConfig = {
    id,
    name,
    token,
    repeats: Number(repeats),
    steps: Number(steps),
    resolution,
    createdAt: new Date().toISOString()
  };

  const plan = [
    `# ${name} - LoRA Plan`,
    "",
    `Trigger token: ${token}`,
    `Repeats: ${config.repeats}`,
    `Max steps: ${config.steps}`,
    `Resolution: ${config.resolution}`,
    "",
    "Workflow:",
    "1. Put your clean source photos in dataset/raw",
    "2. Put final curated + captioned training files in dataset/train",
    "3. Use ComfyUI Manager to install your LoRA training nodes if needed",
    "4. Run your LoRA training workflow and save outputs in output/lora"
  ].join("\n");

  const captionTemplate = `${token}, photo of ${name}, realistic skin texture, detailed face`;

  fs.writeFileSync(path.join(dir, "project.json"), JSON.stringify(config, null, 2), "utf8");
  fs.writeFileSync(path.join(dir, "training-plan.md"), plan, "utf8");
  fs.writeFileSync(path.join(dir, "caption-template.txt"), `${captionTemplate}\n`, "utf8");

  res.json({
    ok: true,
    message: "Project scaffold created.",
    project: config,
    paths: {
      root: dir,
      raw: path.join(dir, "dataset", "raw"),
      train: path.join(dir, "dataset", "train"),
      output: path.join(dir, "output", "lora")
    }
  });
});

app.listen(port, () => {
  console.log(`Get Going Fast API listening on http://127.0.0.1:${port}`);
});
