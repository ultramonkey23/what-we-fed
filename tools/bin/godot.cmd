@echo off
REM Shim on PATH: forwards to tools\godot.ps1 (tools\ itself is not on PATH so godot.ps1 is not invoked as "godot").
setlocal
set "POWERSHELL_EXE=powershell.exe"
where pwsh.exe >nul 2>nul
if %ERRORLEVEL%==0 set "POWERSHELL_EXE=pwsh.exe"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\godot.ps1" exec %*
exit /b %ERRORLEVEL%
