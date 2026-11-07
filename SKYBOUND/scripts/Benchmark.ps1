param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$Python = "python",
    [switch]$Smoke
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$arguments = @((Join-Path $root "benchmarks/tools/run.py"), "--godot", $Godot)
if ($Smoke) { $arguments += "--smoke" }
& $Python @arguments
if ($LASTEXITCODE -ne 0) { throw "Benchmark failed: $LASTEXITCODE" }
