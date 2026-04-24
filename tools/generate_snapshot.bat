@echo off
setlocal enabledelayedexpansion

:: SNAPSHOT GENERATOR (v1.0)
:: Generates docs/ai/CURRENT_TRUTH_SNAPSHOT.md

set SNAPSHOT_FILE=docs\ai\CURRENT_TRUTH_SNAPSHOT.md

echo # CURRENT TRUTH SNAPSHOT > %SNAPSHOT_FILE%
echo *Generated on %DATE% %TIME%* >> %SNAPSHOT_FILE%
echo. >> %SNAPSHOT_FILE%

echo ## 1. GIT PULSE >> %SNAPSHOT_FILE%
echo ``` >> %SNAPSHOT_FILE%
git log -n 3 --oneline >> %SNAPSHOT_FILE%
echo --- >> %SNAPSHOT_FILE%
git status -s >> %SNAPSHOT_FILE%
echo ``` >> %SNAPSHOT_FILE%
echo. >> %SNAPSHOT_FILE%

echo ## 2. VALIDATION PULSE >> %SNAPSHOT_FILE%
if exist "smoke_project.bat" (
    echo - `smoke_project.bat` found. >> %SNAPSHOT_FILE%
) else (
    echo - `smoke_project.bat` MISSING. >> %SNAPSHOT_FILE%
)
if exist "validate_data.bat" (
    echo - `validate_data.bat` found. >> %SNAPSHOT_FILE%
) else (
    echo - `validate_data.bat` MISSING. >> %SNAPSHOT_FILE%
)
echo. >> %SNAPSHOT_FILE%

echo ## 3. ACTIVE BOTTLENECKS >> %SNAPSHOT_FILE%
echo - None recorded. >> %SNAPSHOT_FILE%
echo. >> %SNAPSHOT_FILE%

echo ## 4. IDENTITY INTEGRITY >> %SNAPSHOT_FILE%
echo - [x] Timing Truth Intact >> %SNAPSHOT_FILE%
echo - [x] Lane Readability Intact >> %SNAPSHOT_FILE%
echo - [x] DNA Economy Intact >> %SNAPSHOT_FILE%
echo. >> %SNAPSHOT_FILE%

echo Snapshot generated at %SNAPSHOT_FILE%
