@echo off
setlocal
set "POWERSHELL_EXE=powershell.exe"
where pwsh.exe >nul 2>nul
if %ERRORLEVEL%==0 set "POWERSHELL_EXE=pwsh.exe"
"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" validate-data %*
exit /b %ERRORLEVEL%
