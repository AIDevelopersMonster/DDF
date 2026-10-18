# DDF-LAB-02 / PowerShell 7: run positive and mutation tests.
# The RTL uses Verilog-2005; the self-checking TB uses $fatal (SV).
param([ValidateSet('All','Positive','Negative')][string]$Mode='All')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Push-Location $root
try {
    $msys='C:\msys64\ucrt64\bin'
    if (Test-Path $msys) { $env:PATH="$msys;$env:PATH" }
    foreach($tool in @('iverilog','vvp')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            throw "Missing $tool. Install MSYS2 UCRT64 Icarus Verilog or add it to PATH."
        }
    }
    New-Item -ItemType Directory -Force -Path 'results' | Out-Null
    & iverilog -V *> 'results/iverilog_version.txt'
    & vvp -V *> 'results/vvp_version.txt'

    # Distinguish RTL Verilog-2005 syntax check from a functional simulation.
    & iverilog -g2005 -Wall -tnull -s moving_average4 'rtl/moving_average4.v' 2>&1 |
        Tee-Object -FilePath 'results/rtl_syntax.log'
    if ($LASTEXITCODE -ne 0) { throw 'RTL Verilog-2005 parsing failed' }
    'RTL_PARSE_PASS (not SIM_PASS or SYNTH_PASS)' | Out-File 'results/rtl_parse_status.txt'

    foreach($case in @(
        @{ Name='positive'; File='rtl/moving_average4.v'; Mutation=$false },
        @{ Name='mutation'; File='rtl_mutant/moving_average4.v'; Mutation=$true }
    )) {
        if ($Mode -eq 'Positive' -and $case.Mutation) { continue }
        if ($Mode -eq 'Negative' -and -not $case.Mutation) { continue }
        $bin="results/$($case.Name).vvp"
        $log="results/$($case.Name).log"
        & iverilog -g2012 -Wall -s tb_moving_average4 -o $bin $case.File 'tb/tb_moving_average4.v' 2>&1 |
            Tee-Object -FilePath "results/$($case.Name)_compile.log"
        if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $($case.Name)" }
        $output=@(& vvp $bin "+VCD=results/$($case.Name).vcd" 2>&1 |
            Tee-Object -FilePath $log)
        $rc=$LASTEXITCODE
        if (-not $case.Mutation) {
            if ($rc -ne 0 -or -not ($output -match '^SIM_PASS: moving_average4')) {
                throw "SIM_FAIL: reference implementation; check $log (exit $rc)"
            }
            'SIM_PASS' | Out-File 'results/positive_status.txt'
            Write-Host 'SIM_PASS: positive DUT'
        } else {
            if ($rc -eq 0 -or -not ($output -match 'SIM_FAIL')) {
                throw "Mutation test did not detect the defect; inspect $log (exit $rc)"
            }
            'MUTATION_DETECTED (expected failing DUT)' | Out-File 'results/mutation_status.txt'
            Write-Host 'MUTATION_DETECTED: bad RTL correctly rejected'
        }
    }
    Get-FileHash -Algorithm SHA256 'rtl/moving_average4.v','rtl_mutant/moving_average4.v',
        'tb/tb_moving_average4.v','scripts/run.ps1' |
        Select-Object Path,Hash | Format-Table -AutoSize | Out-String |
        Out-File 'results/source_hashes.txt'
    Write-Host 'See results/*.log, results/*.vcd, results/source_hashes.txt'
} finally { Pop-Location }
