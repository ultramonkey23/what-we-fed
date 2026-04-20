@echo off
REM Appends this repo's tools\bin folder to your Windows user PATH so "godot" runs tools\bin\godot.cmd.
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" add-path
