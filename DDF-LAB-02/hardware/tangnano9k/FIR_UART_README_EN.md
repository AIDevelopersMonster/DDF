# DDF-LAB-02: Tang Nano 9K external UART comparison (v0.1)

Status: SOURCE_PREPARED / LOCAL_HDL_SIM_NOT_RUN / GOWIN_BUILD_NOT_RUN / FPGA_UART_NOT_RUN.
Do not mark physical validation PASS before actual hardware execution and a saved host trace.

## Scope

The previously tested FIR core `../../rtl/moving_average4.v` is NOT changed.
This add-on provides a 115200-8N1 stop-and-wait UART bridge on the Tang Nano 9K,
with a matching independent PowerShell 7 reference model on the PC.
The bridge accepts one command at a time, and the host must wait for the response
before sending another frame. There is NO streaming FIFO/backpressure or throughput claim.

## Board signals (Sipeed Tang Nano 9K)

- Input clock 27 MHz: FPGA pin 52.
- Button S1, active-low reset: FPGA pin 3.
- FPGA TX -> onboard BL702 USB serial RX: FPGA pin 17.
- FPGA RX <- onboard BL702 USB serial TX: FPGA pin 18.
- Active-low LEDs: pins 10 / 11 / 13.
- LED1 toggles on accepted SAMPLE, LED2 latches bad command, LED3 blinks.
- Windows interface: use verified COM port (COM10 in this experiment).

Reference pin source: https://github.com/sipeed/RV-Debugger-BL702 (Tang Nano 9K production pin map).
For some board revisions or debugger firmware, UART behavior may differ. Confirm COM10
is associated with the plugged-in board by disconnect/reconnect if needed.

## Wire protocol (both directions are exactly six bytes)

Request: `A5 op seq hi lo xor`; `xor = A5 ^ op ^ seq ^ hi ^ lo`.
Response: `5A status seq hi lo xor`; `xor = 5A ^ status ^ seq ^ hi ^ lo`.
Byte order: high 4 bits of a 12-bit unsigned sample in `hi[3:0]`, then `lo`.
- `op=01`: accept a sample, return floor(sum of last four accepted samples / 4).
- `op=02`: reset the FIR sample history, return 0000.
- `op=03`: HOLD (do not assert valid_in), return held output value.
- `status=00`: success; `E1`: invalid opcode; `E2`: bad XOR; `E3`: >12-bit payload.
Status/sequence/checksum/range are always checked by the host. Missing or truncated
responses fail by timeout. XOR catches many accidental corruptions but not all patterns.
No signed samples or byte stream mode. Reset/hold requests use zero payload.

## 1. Preflight (existing Icarus Verilog)

From `C:\GitHub\DDF\DDF-LAB-02` in PowerShell 7:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\test_fir_uart.ps1
```

Expected: `UART_BRIDGE_SIM_PASS`, `UART_BRIDGE_MUTATION_DETECTED`,
`DDF_UART_PREFLIGHT_PASS`. Until these appear, do NOT program hardware.

## 2. Gowin Education 1.9.9Beta-4 build

```powershell
$gw = 'C:\Gowin\Gowin_V1.9.9Beta-4_Education\IDE\bin\gw_sh.exe'
& $gw '.\hardware\tangnano9k\build_fir_uart.tcl' 2>&1 |
  Tee-Object '.\results\gowin_fir_uart_build.log'
Write-Host "Build exit: $LASTEXITCODE"
```

Verify `DDF_FIR_UART_BITSTREAM_READY` and exit code 0. The `.fs` is under
`hardware/tangnano9k/build/fir_uart/impl/pnr/fir_uart9k.fs` (ignored by Git).
Review timing/resource reports before physical claims.

## 3. Program SRAM only (DO NOT write FLASH)

```powershell
$prog = 'C:\Gowin\Gowin_V1.9.9Beta-4_Education\Programmer\bin\programmer_cli.exe'
$fs = (Resolve-Path '.\hardware\tangnano9k\build\fir_uart\impl\pnr\fir_uart9k.fs').Path
$log = (Join-Path (Get-Location).Path 'results\fir_uart9k_sram_program.log')
Push-Location (Split-Path $prog -Parent)
try {
  & $prog --device GW1NR-9C --operation_index 2 --fsFile $fs --cable-index 1 2>&1 |
    Tee-Object -FilePath $log
  $rc = $LASTEXITCODE
} finally { Pop-Location }
Write-Host "SRAM programming exit code: $rc"
```

After programming, press/release S1 once to initialize the UART and FIR state.
Never mark programming success until the programmer has returned exit code 0.

## 4. Physical PC-to-FPGA comparison through COM10

Close serial monitors and tools holding COM10. In PowerShell 7:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\run_fir_uart.ps1 -Port COM10 -RandomCount 256 -Seed 20261018
```

The PC runs directed tests, HOLD requests, midstream reset, then 256
seeded random samples. It calculates a separate 4-sample history and compares
every response, with packet sequence, XOR, range and response status checks.
Expected only after actual hardware: `FIR_UART_HARDWARE_PASS`.

Generated proof:
- `results/FIR_UART_HARDWARE_REPORT.json` (PASS/FAIL, versions, hashes, counts)
- `results/fir_uart_hardware_trace.csv` (each input/expected/actual/RTT)
- `results/fir_uart9k_sram_program.log` and Gowin build log.

If the serial exchange fails, the host returns FAIL and saves the partial trace.
Likely causes: a different COM port, another program occupying COM10, firmware not
loaded, a serial USB bridge issue, or UART timing/pin constraints.

## Limitations

- The original FIR is verified for accepted 12-bit unsigned samples; hardware
  output is floored integer division by four with zero startup history.
- The external UART validation is a finite set of directed and deterministic
  randomized samples, NOT a proof for every possible infinite input trace.
- Programming is volatile SRAM. Flash is not overwritten.
- No maximum throughput or timing closure assertion without reviewed Gowin reports.
- Host script requires Windows PowerShell 7 with System.IO.Ports and access to COM10.
