# DDF-LAB-02 / Tang Nano 9K / UART v0.2 diagnostic patch

## Observed physical discrepancy (v0.1)

The COM10 host reported `FIR_HARDWARE_MISMATCH seq=2 input=0 expected=1 FPGA=0`.
A complete UART frame was received, with matching sequence, status and XOR.
Therefore a complete link outage is unlikely; no root cause is established yet.
Do NOT replace or delete the v0.1 failure report and trace.

## Specific hardware-risk correction

In v0.1 `wire fir_rst_n = rst_n && (state != ST_SOFT_RESET);`
feeds a combinational multi-bit FSM-state decode directly into the FIR's
asynchronous reset. Real FPGA state transitions may glitch and sporadically
clear the FIR sample history. In binary terms, ST_PREP=9 (1001)
transitioning to ST_TX_START=10 (1010) could transiently decode 8 (1000),
which is ST_SOFT_RESET, depending on physical routing delays and FSM encoding.
This can reset history AFTER a correct response, explaining why sample 4
returns 1 while the following sample 0 returns 0. An ordinary zero-delay RTL
simulator does not model this physical hazard. The actual Gowin encoding and
reset-net behavior are not yet established, so this is a testable HYPOTHESIS,
not a proven diagnosis.

In v0.2 `fir_soft_reset_hold` is a flop, asserted on a valid RESET opcode and
released one clock later. The FIR clock/reset pin sees only external reset or
a transition from this dedicated flop, not a combinational FSM decode.
The original `rtl/moving_average4.v` (mathematical filter) is unmodified.

## Files (add-only, keeps v0.1 for reproducibility)

- `rtl/top_fir_uart_v02.v`: new registered reset bridge.
- `tb/tb_top_fir_uart_v02.v`: end-to-end UART tests and reset monitor.
- `test_fir_uart_v02.ps1`: positive and negative RTL simulation.
- `build_fir_uart_v02.tcl`: separate Gowin build directory and output name.
- `run_fir_uart_v02.ps1`: independent PC oracle and NEW v0.2 report/trace names.

All paths below are relative to `C:\GitHub\DDF\DDF-LAB-02`.

### 1. Preflight - must pass before hardware

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\test_fir_uart_v02.ps1
```

Expected: `UART_V02_BRIDGE_SIM_PASS`,
`UART_V02_BRIDGE_MUTATION_DETECTED`, `DDF_UART_V02_PREFLIGHT_PASS`.
The mutant must fail the oracle for the intended reason.

### 2. Gowin CLI (same tested Education v1.9.9Beta-4)

```powershell
$gw = 'C:\Gowin\Gowin_V1.9.9Beta-4_Education\IDE\bin\gw_sh.exe'
& $gw '.\hardware\tangnano9k\build_fir_uart_v02.tcl' 2>&1 |
  Tee-Object '.\results\gowin_fir_uart_v02_build.log'
$rc = $LASTEXITCODE
Write-Host "Build exit: $rc"
```

Check `DDF_FIR_UART_V02_BITSTREAM_READY`, exit code 0 and review PNR timing.
Expected bitstream path:
`hardware/tangnano9k/build/fir_uart_v02/impl/pnr/fir_uart9k_v02.fs`.
The hash must DIFFER from v0.1. A separate directory prevents stale output.

### 3. Only after successful build, program SRAM, never Flash

```powershell
$prog = 'C:\Gowin\Gowin_V1.9.9Beta-4_Education\Programmer\bin\programmer_cli.exe'
$fs = (Resolve-Path '.\hardware\tangnano9k\build\fir_uart_v02\impl\pnr\fir_uart9k_v02.fs').Path
$log = (Join-Path (Get-Location).Path 'results\fir_uart_v02_sram_program.log')
Push-Location (Split-Path $prog -Parent)
try {
  & $prog --device GW1NR-9C --operation_index 2 --fsFile $fs --cable-index 1 2>&1 |
    Tee-Object -FilePath $log
  $rc = $LASTEXITCODE
} finally { Pop-Location }
Write-Host "Program exit: $rc"
```

Check exit code 0; press/release S1 once. Close serial monitor programs.

### 4. External comparison using verified COM10

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\run_fir_uart_v02.ps1 -Port COM10 -RandomCount 256 -Seed 20261018
```

- Pass means independently checked physical results for the chosen trace.
- Fail means inspect new v0.2 trace and report, without revising v0.1.
- The 256 samples alone cannot exhaustively prove all input patterns.

### Publication discipline

Record two separate statuses: v0.1 hardware FAIL and v0.2 outcome. Do not
rewrite prior logs, turn a hypothesis into a proven cause, or mark lab complete
until external comparison passes and final bilingual report is audited.
