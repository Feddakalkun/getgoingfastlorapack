import { useEffect, useMemo, useState, type ReactNode } from "react";
import { motion } from "motion/react";
import {
  BadgeCheck,
  FolderPlus,
  LoaderCircle,
  Play,
  RefreshCcw,
  Rocket,
  ShieldAlert,
  Sparkles,
  Terminal,
  WandSparkles
} from "lucide-react";

type Project = {
  id: string;
  name: string;
  token: string;
  repeats: number;
  steps: number;
  resolution: string;
  createdAt: string;
};

type StatusPayload = {
  installerDir: string;
  comfyDir: string;
  installerReady: boolean;
  comfyInstalled: boolean;
  comfyRunning: boolean;
  runningProcess?: { ProcessId: number; Name: string } | null;
  pythonVersions: string[];
  projects: Project[];
};

const emptyStatus: StatusPayload = {
  installerDir: "",
  comfyDir: "",
  installerReady: false,
  comfyInstalled: false,
  comfyRunning: false,
  runningProcess: null,
  pythonVersions: [],
  projects: []
};

async function callApi<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, init);
  const payload = await response.json();
  if (!response.ok) {
    const message = payload?.message ?? `Request failed (${response.status})`;
    throw new Error(message);
  }
  return payload as T;
}

export default function App() {
  const [status, setStatus] = useState<StatusPayload>(emptyStatus);
  const [loadingStatus, setLoadingStatus] = useState(true);
  const [busyAction, setBusyAction] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const [projectName, setProjectName] = useState("My Awesome Character");
  const [triggerToken, setTriggerToken] = useState("ggf_character");
  const [repeats, setRepeats] = useState(16);
  const [steps, setSteps] = useState(2400);
  const [resolution, setResolution] = useState("1024,1024");

  async function refreshStatus() {
    setLoadingStatus(true);
    try {
      const payload = await callApi<StatusPayload>("/api/comfy/status");
      setStatus(payload);
      setError(null);
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : "Failed to load status.");
    } finally {
      setLoadingStatus(false);
    }
  }

  useEffect(() => {
    refreshStatus();
  }, []);

  const vibeLine = useMemo(() => {
    if (status.comfyRunning) {
      return "Engine hot. Build your LoRA and drop jaws.";
    }
    if (status.comfyInstalled) {
      return "ComfyUI installed. One click from launch.";
    }
    return "Start from zero. End with: 'did I really make that?'";
  }, [status.comfyInstalled, status.comfyRunning]);

  async function runAction(
    actionId: string,
    path: string,
    body?: Record<string, unknown>
  ) {
    setBusyAction(actionId);
    setError(null);
    setMessage(null);
    try {
      const payload = await callApi<{ message?: string }>(path, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: body ? JSON.stringify(body) : undefined
      });
      setMessage(payload.message ?? "Done.");
      await refreshStatus();
    } catch (caughtError) {
      setError(caughtError instanceof Error ? caughtError.message : "Action failed.");
    } finally {
      setBusyAction(null);
    }
  }

  return (
    <div className="min-h-screen bg-black text-white">
      <header className="sticky top-0 z-30 border-b border-white/10 bg-black/80 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4 md:px-10">
          <div>
            <p className="font-title text-xs tracking-[0.45em] text-orange-300 uppercase">Get Going Fast</p>
            <h1 className="font-title text-3xl leading-none tracking-[0.08em] md:text-5xl">
              Local LoRA Forge
            </h1>
            <p className="mt-1 text-sm text-zinc-400">{vibeLine}</p>
          </div>
          <button
            onClick={refreshStatus}
            className="inline-flex items-center gap-2 rounded-full border border-white/20 px-4 py-2 text-sm hover:border-orange-300 hover:text-orange-200"
          >
            <RefreshCcw className={`h-4 w-4 ${loadingStatus ? "animate-spin" : ""}`} />
            Refresh
          </button>
        </div>
      </header>

      <main className="mx-auto grid max-w-7xl gap-6 px-5 py-6 md:grid-cols-12 md:px-10 md:py-8">
        <section className="stage-card md:col-span-7">
          <h2 className="section-title">
            <Terminal className="h-5 w-5 text-orange-300" />
            ComfyUI Control Deck
          </h2>

          <div className="grid gap-3 md:grid-cols-2">
            <StatusPill label="Installer Ready" active={status.installerReady} />
            <StatusPill label="Comfy Installed" active={status.comfyInstalled} />
            <StatusPill label="Comfy Running" active={status.comfyRunning} />
            <StatusPill label="Python Detected" active={status.pythonVersions.length > 0} />
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-2">
            <ActionButton
              busy={busyAction === "install"}
              onClick={() => runAction("install", "/api/comfy/install")}
              icon={<Rocket className="h-4 w-4" />}
              title="Install ComfyUI"
              subtitle="Opens installer terminal (interactive)"
            />
            <ActionButton
              busy={busyAction === "run"}
              onClick={() => runAction("run", "/api/comfy/run")}
              icon={<Play className="h-4 w-4" />}
              title="Run ComfyUI"
              subtitle="Launch local Comfy engine"
            />
            <ActionButton
              busy={busyAction === "update"}
              onClick={() => runAction("update", "/api/comfy/update")}
              icon={<RefreshCcw className="h-4 w-4" />}
              title="Update ComfyUI"
              subtitle="Pull latest core updates"
            />
            <ActionButton
              busy={busyAction === "weak"}
              onClick={() => runAction("weak", "/api/comfy/weak-security")}
              icon={<ShieldAlert className="h-4 w-4" />}
              title="Enable Weak Security"
              subtitle="Needed for some custom nodes"
            />
          </div>

          <div className="mt-5 rounded-xl border border-white/10 bg-zinc-950/70 p-4 text-sm text-zinc-300">
            <p className="font-semibold text-zinc-100">Paths</p>
            <p className="mt-1 break-all">{status.installerDir || "..."}</p>
            <p className="mt-1 break-all text-zinc-400">{status.comfyDir || "..."}</p>
            {status.pythonVersions.length > 0 && (
              <p className="mt-2 text-zinc-400">Detected: {status.pythonVersions.join(" | ")}</p>
            )}
          </div>
        </section>

        <section className="stage-card md:col-span-5">
          <h2 className="section-title">
            <FolderPlus className="h-5 w-5 text-orange-300" />
            LoRA Project Wizard
          </h2>

          <label className="field">
            Project name
            <input value={projectName} onChange={(event) => setProjectName(event.target.value)} />
          </label>

          <label className="field mt-3">
            Trigger token
            <input value={triggerToken} onChange={(event) => setTriggerToken(event.target.value)} />
          </label>

          <div className="mt-3 grid grid-cols-2 gap-3">
            <label className="field">
              Repeats
              <input
                type="number"
                min={1}
                max={200}
                value={repeats}
                onChange={(event) => setRepeats(Number(event.target.value))}
              />
            </label>
            <label className="field">
              Max steps
              <input
                type="number"
                min={100}
                max={50000}
                value={steps}
                onChange={(event) => setSteps(Number(event.target.value))}
              />
            </label>
          </div>

          <label className="field mt-3">
            Resolution (width,height)
            <input value={resolution} onChange={(event) => setResolution(event.target.value)} />
          </label>

          <button
            onClick={() =>
              runAction("project", "/api/projects/create", {
                name: projectName,
                token: triggerToken,
                repeats,
                steps,
                resolution
              })
            }
            disabled={busyAction === "project"}
            className="mt-4 inline-flex w-full items-center justify-center gap-2 rounded-xl bg-orange-400 px-4 py-3 font-semibold text-black disabled:opacity-60"
          >
            {busyAction === "project" ? (
              <>
                <LoaderCircle className="h-4 w-4 animate-spin" />
                Creating project
              </>
            ) : (
              <>
                <WandSparkles className="h-4 w-4" />
                Create training-ready project
              </>
            )}
          </button>

          <p className="mt-3 text-xs text-zinc-400">
            Creates folders + starter files: `dataset/raw`, `dataset/train`, `output/lora`, `training-plan.md`.
          </p>
        </section>

        <section className="stage-card md:col-span-12">
          <h2 className="section-title">
            <Sparkles className="h-5 w-5 text-orange-300" />
            Your Projects
          </h2>
          {status.projects.length === 0 ? (
            <p className="text-zinc-400">No projects yet. Create one from the wizard.</p>
          ) : (
            <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3">
              {status.projects.map((project) => (
                <motion.div
                  key={project.id}
                  layout
                  className="rounded-xl border border-white/10 bg-zinc-950/60 p-4"
                >
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold">{project.name}</h3>
                    <BadgeCheck className="h-4 w-4 text-emerald-400" />
                  </div>
                  <p className="mt-1 text-xs uppercase tracking-[0.18em] text-orange-300">{project.token}</p>
                  <p className="mt-2 text-sm text-zinc-400">
                    repeats {project.repeats} | steps {project.steps} | {project.resolution}
                  </p>
                </motion.div>
              ))}
            </div>
          )}
        </section>
      </main>

      {(error || message) && (
        <div className="fixed bottom-5 right-5 z-40 max-w-md rounded-xl border border-white/20 bg-black/90 px-4 py-3 text-sm">
          {error ? <p className="text-red-300">{error}</p> : <p className="text-emerald-300">{message}</p>}
        </div>
      )}
    </div>
  );
}

function StatusPill({ label, active }: { label: string; active: boolean }) {
  return (
    <div
      className={`rounded-full border px-3 py-2 text-sm ${
        active
          ? "border-emerald-400/40 bg-emerald-400/15 text-emerald-200"
          : "border-zinc-700 bg-zinc-900/70 text-zinc-400"
      }`}
    >
      {label}
    </div>
  );
}

function ActionButton({
  title,
  subtitle,
  icon,
  onClick,
  busy
}: {
  title: string;
  subtitle: string;
  icon: ReactNode;
  onClick: () => void;
  busy: boolean;
}) {
  return (
    <button
      onClick={onClick}
      disabled={busy}
      className="rounded-xl border border-white/15 bg-zinc-900/80 p-4 text-left transition hover:border-orange-300/50 hover:bg-zinc-900 disabled:opacity-60"
    >
      <div className="flex items-center gap-2 text-sm font-semibold">
        {busy ? <LoaderCircle className="h-4 w-4 animate-spin" /> : icon}
        {title}
      </div>
      <p className="mt-1 text-xs text-zinc-400">{subtitle}</p>
    </button>
  );
}
