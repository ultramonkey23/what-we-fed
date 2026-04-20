@echo off
REM Shim on PATH: forwards to tools\godot.ps1 (tools\ itself is not on PATH so godot.ps1 is not invoked as "godot").
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\godot.ps1" exec %*
exit /b %ERRORLEVEL%
