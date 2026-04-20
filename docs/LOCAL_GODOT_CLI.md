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
