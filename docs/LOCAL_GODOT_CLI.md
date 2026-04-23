# Local Godot CLI Workflow

Use [PROJECT_SETUP_AND_VALIDATION.md](../PROJECT_SETUP_AND_VALIDATION.md) as the main workflow entrypoint.

Quick command summary from repo root:

```bat
run_project.bat
validate_project.bat
editor_project.bat
resolve_godot.bat
```

Repo-local overrides:

1. Current shell only:

```powershell
$env:WHAT_WE_FED_GODOT_EXE = "C:\full\path\to\Godot_v4.6.1-stable_win64_console.exe"
```

2. Persistent for this checkout:

Create `.godot-cli\godot_path.txt` and put the full executable path on line 1.

## Use `godot` from any terminal (Windows)

This repo ships `tools/bin/godot.cmd` (only `tools\bin` is added to `PATH`, not `tools\`, so PowerShell does not treat `godot.ps1` as the `godot` command).

1. From repo root, run once (updates your **user** `PATH`):

```bat
add_tools_to_path.bat
```

Or:

```powershell
pwsh -ExecutionPolicy Bypass -File "tools\godot.ps1" add-path
```

2. **Close and reopen** your terminal (PATH is read at startup).

3. Run Godot CLI as usual, for example:

```bat
godot --path "%CD%" --headless --quit-after 1
```

The shim runs `tools\godot.ps1 exec …`, which resolves the engine then passes your arguments through. Repo wrappers (`run_project.bat`, etc.) prefer PowerShell 7 (`pwsh.exe`) when available and fall back to Windows PowerShell.

`validate_project.bat` clears only the repo-local generated shader cache before import, then tries the normal import pass first. If Godot still crashes before project errors can be inspected, it retries import in headless mode and then continues to the one-frame smoke validation.

## Opt-in Agent Trace Log

Ad hoc combat trace events are disabled by default. To capture them during a debug run, set `WHAT_WE_FED_AGENT_TRACE` to a short session id before running a wrapper:

```powershell
$env:WHAT_WE_FED_AGENT_TRACE = "hud-bind"
.\debug_harness.bat
```

Any non-empty value enables tracing except `0`, `false`, `no`, and `off`.

Trace output is written under the repo-local Godot user data path when using the wrappers:

```text
.godot-cli\AppData\Roaming\Godot\app_userdata\What We Fed\debug\agent_trace.jsonl
```

If you previously added the whole `tools` folder to `PATH` and `godot` fails with a `ValidateSet` error, remove that `tools` entry from **User** environment variables and run `add_tools_to_path.bat` again.
