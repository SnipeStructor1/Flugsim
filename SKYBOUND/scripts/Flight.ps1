param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
& $Godot --path (Join-Path $root "benchmarks/godot") --rendering-method forward_plus 'res://flight/flight.tscn'
if ($LASTEXITCODE -ne 0) { throw "Flight simulator exited with code $LASTEXITCODE" }
