param(
	[Parameter(ValueFromRemainingArguments = $true)]
	[string[]]$Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "asset_orchestrator.py"
$candidates = [System.Collections.Generic.List[string]]::new()
if ($env:PYTHON -and (Test-Path -LiteralPath $env:PYTHON)) {
	$candidates.Add($env:PYTHON) | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
	$userLocalPython = Join-Path $env:USERPROFILE "AppData\Local\Python\bin\python.exe"
	if (Test-Path -LiteralPath $userLocalPython) {
		$candidates.Add($userLocalPython) | Out-Null
	}
}
if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
	$localPython = Join-Path $env:LOCALAPPDATA "Python\bin\python.exe"
	if (Test-Path -LiteralPath $localPython) {
		$candidates.Add($localPython) | Out-Null
	}
}
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd -and $pythonCmd.Source) {
	$candidates.Add($pythonCmd.Source) | Out-Null
}

$pythonExe = $null
foreach ($candidate in $candidates | Select-Object -Unique) {
	try {
		& $candidate -V *> $null
		if ($LASTEXITCODE -eq 0) {
			$pythonExe = $candidate
			break
		}
	}
	catch {
	}
}

if (-not $pythonExe) {
	throw "No usable Python runtime found. Set PYTHON or install Python."
}

& $pythonExe $scriptPath @Args
exit $LASTEXITCODE
