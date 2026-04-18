@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0tools\godot.ps1" validate %*
