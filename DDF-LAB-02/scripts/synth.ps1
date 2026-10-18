# Optional structural synthesis. Does not prove FPGA timing or PPA.
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
    $msys='C:\msys64\ucrt64\bin'
    if (Test-Path $msys) { $env:PATH="$msys;$env:PATH" }
    if (-not (Get-Command yosys -ErrorAction SilentlyContinue)) {
        Write-Host 'SYNTH_NOT_RUN: yosys is not installed'; exit 0
    }
    New-Item -ItemType Directory -Force -Path 'results' | Out-Null
    & yosys -V | Tee-Object -FilePath 'results/yosys_version.txt'
    & yosys -l results/synth.log -s scripts/synth.ys
    if ($LASTEXITCODE -ne 0) { throw 'SYNTH_FAIL: see results/synth.log' }
    Write-Host 'GENERIC_SYNTH_PASS: inspect results/synth.log'
    Write-Host 'Not a device-specific timing/resource certification.'
} finally { Pop-Location }
