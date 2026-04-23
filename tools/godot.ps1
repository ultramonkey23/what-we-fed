param(
    [ValidateSet("run", "validate", "smoke", "editor", "resolve", "debug", "exec", "add-path")]
    [string]$Mode = "run",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GodotArgs
)

$ErrorActionPreference = "Stop"
$GodotArgs = @($GodotArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Get-RepoLocalGodotPathFile {
    $repoRoot = Get-RepoRoot
    return Join-Path $repoRoot ".godot-cli\godot_path.txt"
}

function Get-ConfiguredGodotPath {
    $pathFile = Get-RepoLocalGodotPathFile

    if ($env:WHAT_WE_FED_GODOT_EXE) {
        return $env:WHAT_WE_FED_GODOT_EXE
    }

    if (Test-Path $pathFile) {
        $configuredPath = (Get-Content $pathFile | Select-Object -First 1).Trim()
        if ($configuredPath) {
            return $configuredPath
        }
    }

    return $null
}

function Get-GodotSearchRoots {
    return @(
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "$env:LOCALAPPDATA\Programs",
        "$env:ProgramFiles",
        "$env:ProgramFiles(x86)"
    )
}

function Find-GodotExecutable {
    $commandCandidates = @(
        "godot4_console.exe",
        "godot4.exe",
        "godot_console.exe",
        "godot.exe"
    )

    foreach ($commandName in $commandCandidates) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command -and $command.Path) {
            return $command.Path
        }
    }

    $nameCandidates = @(
        "Godot_v4.6.1-stable_win64_console.exe",
        "Godot_v4.6.1-stable_mono_win64_console.exe",
        "Godot_v4.6.1-stable_win64.exe",
        "Godot_v4.6.1-stable_mono_win64.exe",
        "Godot_v4.3-stable_win64_console.exe",
        "Godot_v4.3-stable_win64.exe"
    )

    foreach ($root in Get-GodotSearchRoots) {
        if (-not (Test-Path $root)) {
            continue
        }

        foreach ($candidateName in $nameCandidates) {
            $match = Get-ChildItem -Path $root -Recurse -Depth 4 -File -Filter $candidateName -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($match) {
                return $match.FullName
            }
        }

        $fallback = Get-ChildItem -Path $root -Recurse -Depth 4 -File -Include *godot*console*.exe,*godot*.exe -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1
        if ($fallback) {
            return $fallback.FullName
        }
    }

    return $null
}

function Resolve-GodotExecutable {
    $candidate = Get-ConfiguredGodotPath
    if (-not $candidate) {
        $candidate = Find-GodotExecutable
    }

    if (-not $candidate) {
        $pathFile = Get-RepoLocalGodotPathFile
        throw @"
Unable to locate a Godot executable.

Fix one of these:
1. Set WHAT_WE_FED_GODOT_EXE for the current shell.
2. Write the full path to the executable into:
   $pathFile
3. Install or unpack Godot in a common local path such as Downloads or Program Files.
"@
    }

    $resolved = Resolve-Path $candidate -ErrorAction Stop
    return $resolved.Path
}

function Get-RepoLocalStatePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ChildPath
    )

    $repoRoot = Get-RepoRoot
    $fullPath = Join-Path $repoRoot ".godot-cli\$ChildPath"
    New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
    return $fullPath
}

function Set-GodotLocalEnvironment {
    $env:APPDATA = Get-RepoLocalStatePath -ChildPath "AppData\Roaming"
    $env:LOCALAPPDATA = Get-RepoLocalStatePath -ChildPath "AppData\Local"
    $env:TEMP = Get-RepoLocalStatePath -ChildPath "Temp"
    $env:TMP = $env:TEMP
}

function Get-DefaultLogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModeName
    )

    $logsDir = Get-RepoLocalStatePath -ChildPath "logs"
    return Join-Path $logsDir ("godot-{0}.log" -f $ModeName)
}

function Invoke-Godot {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [string]$LogPath = "",
        [bool]$Quiet = $false
    )

    $godotExe = Resolve-GodotExecutable
    $repoRoot = Get-RepoRoot

    Set-GodotLocalEnvironment

    Write-Host ("Using Godot: {0}" -f $godotExe)
    Write-Host ("Project root: {0}" -f $repoRoot)
    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        Write-Host ("Log file: {0}" -f $LogPath)
    }

    if ($Quiet) {
        & $godotExe @Arguments *> $null
    } else {
        & $godotExe @Arguments
    }
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw ("Godot exited with code {0}." -f $exitCode)
    }
}

function Clear-RepoLocalShaderCache {
    $repoRoot = Get-RepoRoot
    $stateRoot = Join-Path $repoRoot ".godot-cli"
    $shaderCache = Join-Path $stateRoot "AppData\Roaming\Godot\app_userdata\What We Fed\shader_cache"

    if (-not (Test-Path $shaderCache)) {
        return
    }

    $resolvedStateRoot = (Resolve-Path $stateRoot).Path
    $resolvedShaderCache = (Resolve-Path $shaderCache).Path
    if (-not $resolvedShaderCache.StartsWith($resolvedStateRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Refusing to clear shader cache outside repo-local state: {0}" -f $resolvedShaderCache)
    }

    Remove-Item -LiteralPath $resolvedShaderCache -Recurse -Force
}

function Invoke-GodotImport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]
        [string]$ImportLog
    )

    Clear-RepoLocalShaderCache

    $importArgs = @("--path", $RepoRoot, "--import", "--log-file", $ImportLog)
    try {
        Invoke-Godot -Arguments $importArgs -LogPath $ImportLog
        return @($ImportLog)
    } catch {
        Write-Host ""
        Write-Host "Import pass failed before validation could inspect project errors." -ForegroundColor DarkYellow
        Write-Host "Retrying import in headless mode to avoid Windows renderer/import crashes." -ForegroundColor DarkYellow
        Write-Host ""

        $headlessImportLog = Get-DefaultLogFile -ModeName "import-headless"
        $headlessImportArgs = @("--path", $RepoRoot, "--headless", "--import", "--log-file", $headlessImportLog)
        Invoke-Godot -Arguments $headlessImportArgs -LogPath $headlessImportLog -Quiet $true
        return @($ImportLog, $headlessImportLog)
    }
}

function Get-GodotLogErrors {
    # Reads a Godot log file and returns error lines, filtering out known-safe
    # warnings that appear in every clean headless run on Windows.
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogPath,
        [string[]]$AdditionalSafePatterns = @()
    )

    if (-not (Test-Path $LogPath)) {
        return @()
    }

    # These patterns appear in clean headless runs on Windows and are not real errors.
    $safePatterns = @(
        "Failed to read the root certificate store",
        "ObjectDB instances leaked at exit"
    ) + $AdditionalSafePatterns

    $errors = [System.Collections.Generic.List[string]]::new()
    $inErrorBlock = $false

    foreach ($line in (Get-Content $LogPath -ErrorAction SilentlyContinue)) {
        # Error-class prefixes that matter.
        if ($line -match "^(ERROR|SCRIPT ERROR|USER ERROR|USER WARNING):" -or $line -match "^Parse Error:") {
            $isSafe = $false
            foreach ($safe in $safePatterns) {
                if ($line -match [regex]::Escape($safe)) {
                    $isSafe = $true
                    break
                }
            }
            if (-not $isSafe) {
                $errors.Add($line)
                $inErrorBlock = $true
            } else {
                $inErrorBlock = $false
            }
        } elseif ($inErrorBlock -and $line -match "^\s+at:") {
            # Stack-trace context for the preceding error Ã¢â‚¬" keep it.
            $errors.Add($line)
        } else {
            $inErrorBlock = $false
        }
    }

    return $errors.ToArray()
}

switch ($Mode) {
    "add-path" {
        # Put tools\bin on PATH (not tools\) so `godot` resolves to godot.cmd, not godot.ps1 (PowerShell prefers .ps1 in the same folder).
        $toolsDir = (Resolve-Path $PSScriptRoot).Path
        $binDir = (Resolve-Path (Join-Path $PSScriptRoot "bin")).Path
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $parts = @()
        if (-not [string]::IsNullOrWhiteSpace($userPath)) {
            $parts = $userPath.Split(";") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }
        $out = [System.Collections.Generic.List[string]]::new()
        $hadBin = $false
        $removedLegacy = $false
        foreach ($p in $parts) {
            if ($p -ieq $toolsDir) {
                $removedLegacy = $true
                continue
            }
            if ($p -ieq $binDir) {
                $hadBin = $true
            }
            $out.Add($p)
        }
        if (-not $hadBin) {
            $out.Add($binDir)
        }
        $newPath = ($out | Where-Object { $_ }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host ("User PATH updated. Godot shim directory: {0}" -f $binDir) -ForegroundColor Green
        if ($removedLegacy) {
            Write-Host ("Removed legacy PATH entry: {0}" -f $toolsDir) -ForegroundColor DarkYellow
        }
        Write-Host "Open a new terminal, then run: godot --version"
        exit 0
    }
    "exec" {
        $godotExe = Resolve-GodotExecutable
        Set-GodotLocalEnvironment
        Write-Host ("Using Godot: {0}" -f $godotExe)
        & $godotExe @GodotArgs
        exit $LASTEXITCODE
    }
    "resolve" {
        Write-Host (Resolve-GodotExecutable)
    }
    "editor" {
        $logFile = Get-DefaultLogFile -ModeName "editor"
        $args = @("--editor", "--path", (Get-RepoRoot), "--log-file", $logFile) + $GodotArgs
        Invoke-Godot -Arguments $args -LogPath $logFile
    }
    "run" {
        $logFile = Get-DefaultLogFile -ModeName "run"
        $args = @("--path", (Get-RepoRoot), "--log-file", $logFile) + $GodotArgs
        Invoke-Godot -Arguments $args -LogPath $logFile
    }
    "debug" {
        $logFile = Get-DefaultLogFile -ModeName "debug-harness"
        $args = @("--path", (Get-RepoRoot), "--log-file", $logFile) + $GodotArgs + @("res://scenes/dev/DebugBootScene.tscn")
        Invoke-Godot -Arguments $args -LogPath $logFile
    }
    "smoke" {
        $repoRoot = Get-RepoRoot
        $smokeLog = Get-DefaultLogFile -ModeName "smoke"
        $smokeArgs = @("--path", $repoRoot, "--headless", "--quit-after", "1", "--log-file", $smokeLog) + $GodotArgs
        Invoke-Godot -Arguments $smokeArgs -LogPath $smokeLog

        $logErrors = Get-GodotLogErrors -LogPath $smokeLog
        if ($logErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "SMOKE FAILED - errors found in smoke log:" -ForegroundColor Red
            foreach ($line in $logErrors) {
                Write-Host ("  {0}" -f $line) -ForegroundColor Red
            }
            Write-Host ""
            Write-Host ("Full log: {0}" -f $smokeLog)
            exit 1
        }

        Write-Host "SMOKE OK" -ForegroundColor Green
    }
    "validate" {
        $repoRoot = Get-RepoRoot

        # Step 1: import pass - re-import any new or changed assets.
        # Uses the non-headless path so audio and texture importers have full access.
        $importLog = Get-DefaultLogFile -ModeName "import"
        $importLogs = @(Invoke-GodotImport -RepoRoot $repoRoot -ImportLog $importLog | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_) -and $_ -like "*.log"
        })
        if ($importLogs.Count -eq 0) {
            $importLogs = @($importLog)
        }

        # Step 2: headless smoke run - boot the project for one frame and quit.
        # This catches autoload failures, parse errors, and missing-node crashes.
        $validateLog = Get-DefaultLogFile -ModeName "validate"
        $smokeArgs = @("--path", $repoRoot, "--headless", "--quit-after", "1", "--log-file", $validateLog) + $GodotArgs
        Invoke-Godot -Arguments $smokeArgs -LogPath $validateLog

        # Step 3: scan import and smoke logs for real errors.
        # Godot exits 0 even on GDScript parse or runtime errors.
        $logErrors = [System.Collections.Generic.List[string]]::new()
        $headlessImportSafePatterns = @(
            'Condition "_sock == (SOCKET)(~0)" is true. Returning: FAILED',
            'Condition "err != OK" is true. Returning: ERR_CANT_CREATE'
        )
        foreach ($logPath in $importLogs) {
            $additionalSafe = @()
            if ($logPath -like "*godot-import-headless.log") {
                $additionalSafe = $headlessImportSafePatterns
            }
            foreach ($line in (Get-GodotLogErrors -LogPath $logPath -AdditionalSafePatterns $additionalSafe)) {
                $logErrors.Add(("{0}: {1}" -f (Split-Path $logPath -Leaf), $line))
            }
        }
        foreach ($line in (Get-GodotLogErrors -LogPath $validateLog)) {
            $logErrors.Add(("{0}: {1}" -f (Split-Path $validateLog -Leaf), $line))
        }
        if ($logErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "VALIDATE FAILED - errors found in validation logs:" -ForegroundColor Red
            foreach ($line in $logErrors) {
                Write-Host ("  {0}" -f $line) -ForegroundColor Red
            }
            Write-Host ""
            Write-Host ("Import log: {0}" -f $importLog)
            Write-Host ("Smoke log: {0}" -f $validateLog)
            exit 1
        }

        Write-Host "VALIDATE OK" -ForegroundColor Green
    }
}
