# Windows 10, PowerShell 7. Run baseline and known-mutant end-to-end UART TB.
$ErrorActionPreference = 'Stop'
$hw = (Resolve-Path $PSScriptRoot).Path
$lab = (Resolve-Path (Join-Path $hw '..\..')).Path
$msys = 'C:\msys64\ucrt64\bin'
if (Test-Path $msys) { $env:Path = "$msys;$env:Path" }
foreach ($name in @('iverilog','vvp')) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "MISSING_TOOL: $name"
    }
}
Push-Location $lab
try {
    New-Item -ItemType Directory -Path 'results' -Force | Out-Null
    $common = @(
        'hardware/tangnano9k/rtl/ddf_uart_rx.v',
        'hardware/tangnano9k/rtl/ddf_uart_tx.v',
        'hardware/tangnano9k/rtl/top_fir_uart_v02.v',
        'hardware/tangnano9k/tb/tb_top_fir_uart_v02.v'
    )
    foreach ($test in @(
        @{ Name='positive'; DUT='rtl/moving_average4.v'; ExpectedFail=$false },
        @{ Name='mutant'; DUT='rtl_mutant/moving_average4.v'; ExpectedFail=$true }
    )) {
        $bin = "results/fir_uart_v02_$($test.Name).vvp"
        $log = "results/fir_uart_v02_$($test.Name).log"
        & iverilog -g2012 -Wall -s tb_top_fir_uart_v02 -o $bin $test.DUT @common 2>&1 |
            Tee-Object -FilePath "results/fir_uart_v02_$($test.Name)_compile.log"
        if ($LASTEXITCODE -ne 0) { throw "COMPILE_FAIL: $($test.Name)" }
        & vvp $bin 2>&1 | Tee-Object -FilePath $log
        $rc = $LASTEXITCODE
        $body = Get-Content -LiteralPath $log -Raw
        if (-not $test.ExpectedFail) {
            if ($rc -ne 0 -or $body -notmatch 'UART_V02_BRIDGE_SIM_PASS') {
                throw "UART_V02_BRIDGE_SIM_FAIL (exit=$rc). Inspect $log"
            }
            Write-Host 'UART_V02_BRIDGE_SIM_PASS'
        } else {
            if ($rc -eq 0 -or $body -notmatch 'UART_TB_MISMATCH') {
                throw "UART_MUTATION_TEST_FAIL (exit=$rc). Inspect $log"
            }
            Write-Host 'UART_V02_BRIDGE_MUTATION_DETECTED'
        }
    }
    Write-Host 'DDF_UART_V02_PREFLIGHT_PASS'
} finally { Pop-Location }
