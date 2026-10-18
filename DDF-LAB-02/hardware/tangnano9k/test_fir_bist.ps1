# DDF-LAB-02: preflight test, using existing Icarus install.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path $PSScriptRoot).Path
$lab = (Resolve-Path (Join-Path $root '..\..')).Path
$env:Path = "C:\msys64\ucrt64\bin;$env:Path"
foreach ($name in @('iverilog','vvp')) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing $name in PATH"
    }
}
New-Item -ItemType Directory -Force (Join-Path $lab 'results') | Out-Null
Push-Location $lab
try {
    foreach ($test in @(
        @{ Name='positive'; DUT='rtl/moving_average4.v'; Extra='' },
        @{ Name='mutant'; DUT='rtl_mutant/moving_average4.v'; Extra='+EXPECT_MUTANT' }
    )) {
        $bin = "results/fir_bist_$($test.Name).vvp"
        $log = "results/fir_bist_$($test.Name).log"
        & iverilog -g2012 -Wall -s tb_top_fir_bist -o $bin $test.DUT `
            'hardware/tangnano9k/rtl/top_fir_bist.v' `
            'hardware/tangnano9k/tb/tb_top_fir_bist.v'
        if ($LASTEXITCODE -ne 0) { throw "Icarus compile failure: $($test.Name)" }
        if ($test.Extra) {
            & vvp $bin $test.Extra 2>&1 | Tee-Object -FilePath $log
        } else {
            & vvp $bin 2>&1 | Tee-Object -FilePath $log
        }
        if ($LASTEXITCODE -ne 0) { throw "Icarus simulation failure: $($test.Name)" }
        $expected = if ($test.Extra) { 'BIST_MUTATION_DETECTED' } else { 'BIST_SIM_PASS' }
        if (-not (Select-String -Path $log -Pattern "^$expected" -Quiet)) {
            throw "Missing expected marker: $expected"
        }
    }
    Write-Host 'DDF_FIR_BIST_SIM_AND_MUTATION_PASS'
} finally {
    Pop-Location
}
