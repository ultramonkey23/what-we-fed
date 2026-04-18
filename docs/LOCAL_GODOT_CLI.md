# Local Godot CLI Workflow

Use the repo-local wrappers from the project root:

```bat
run_project.bat
validate_project.bat
```

What they do:
- `run_project.bat` launches the project from terminal.
- `validate_project.bat` runs a quick import pass, then a one-frame headless smoke run.
- Both wrappers keep Godot logs and writable editor state inside `.godot-cli/` instead of relying on global AppData paths.

If Godot is not on `PATH`, the wrapper will try common Windows install/unpack locations first.

If auto-discovery misses your install, use either of these repo-safe overrides:

1. Current shell only:

```powershell
$env:WHAT_WE_FED_GODOT_EXE = "C:\full\path\to\Godot_v4.6.1-stable_win64_console.exe"
```

2. Persistent for this repo checkout:

Create `.godot-cli\godot_path.txt` containing the full path to the executable on the first line.
