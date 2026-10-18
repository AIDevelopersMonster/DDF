# DDF-LAB-02 — Four-tap FIR filter: from Verilog to physical FPGA validation

**Final laboratory guide and experimental record · revision 1.0 · 18 October 2026**

**Course:** Digital Design Flow (DDF), supporting DDF-L04 and DDF-L05.  
**Single repository:** https://github.com/AIDevelopersMonster/DDF  
**Laboratory directory:** `DDF-LAB-02`  
**Hardware target:** Sipeed Tang Nano 9K, Gowin GW1NR-9C family FPGA.  
**Status:** `FIR_HARDWARE_FUNCTIONAL_PASS` for the tested UART v0.2 build. This is **not** a claim of certified timing closure, maximum operating frequency, or exhaustive verification.

> **Evidence discipline.** This report is grounded in the operator's PowerShell outputs and two hardware-run JSON records dated 2026-10-18. The complete 294-row CSV was also retrieved from the published GitHub repository and independently replayed against a fresh mathematical reference. Section 6.3 displays its first ten rows; section 6.4 records the complete audit. Historical preparation logs marked `NOT RUN` must not be retroactively changed.

## 1. Objective and acceptance criteria

Implement a four-sample moving-average FIR as a synthesizable digital hardware block and test it first by simulation and then in a physical FPGA against an independent host reference.

Functional acceptance requires:
1. A precisely specified RTL input/output and reset contract.
2. Passing positive HDL tests and detection of a deliberately defective RTL mutant.
3. A Gowin build for a selected device.
4. Actual JTAG detection, programming and observable board operation.
5. A physical built-in self-test (BIST) with the expected LED result.
6. Real PC–FPGA UART transactions checked against a separate host arithmetic model.
7. Retained tool details, file hashes, passing and failing experimental evidence.

These **functional** criteria have been met for the tested setup. Post-place-and-route timing closure, power, reliability and all possible input traces have **not** been substantiated to the level needed for those separate claims.

## 2. Mathematical definition and RTL contract

Source: `rtl/moving_average4.v`, synthesizable Verilog-2005.

For each **accepted** unsigned 12-bit sample `x[n]`:

`y[n] = floor((x[n] + x[n-1] + x[n-2] + x[n-3]) / 4)`.

Missing start-up samples count as zero. The maximum accumulator value is `4 × 4095 = 16380` and requires 14 bits. The nominal state consists of three 12-bit history registers, a 12-bit output register and one `valid_out` register: 49 bits.

- `valid_in=1`: accept a sample, update history and register the new result.
- `valid_in=0`: hold the sample history and `data_out`; deassert `valid_out`.
- `rst_n=0`: clear history, output and validity.
- The FIR core exposes **no** `ready`/backpressure interface; the wrapper must respect the core's acceptance semantics.

The UART wrapper implements an independent stop-and-wait request/response protocol. The original FIR mathematical algorithm and RTL file are unchanged across the two hardware runs.

## 3. Proven hardware and toolchain environment

| Component | Recorded configuration |
|---|---|
| Host | Windows 10, PowerShell 7 |
| HDL simulator | Icarus Verilog (`iverilog`, `vvp`), MSYS2 UCRT64 |
| FPGA suite | Gowin EDA **V1.9.9Beta-4 Education** |
| Tcl executable | `C:\Gowin\Gowin_V1.9.9Beta-4_Education\IDE\bin\gw_sh.exe` |
| Programmer | `...\Programmer\bin\programmer_cli.exe` |
| Target part for implementation | `GW1NR-LV9QN88PC6/I5` |
| Detected JTAG | GW1NR family, ID `0x1100481B`, one device, FT2CH at 2.5 MHz |
| Host connection | USB JTAG/UART, **COM10** |
| UART framing | 115200 baud, 8 data bits, no parity, 1 stop bit |
| Board oscillator | 27 MHz |

Board pin mapping used: clock **52**, S1 active-low reset **3**, FPGA TX **17**, FPGA RX **18**, active-low LEDs 1–3 **10/11/13**. Verify pin mapping against the relevant board revision before porting the exercise.

## 4. Reproducible laboratory procedure

Run all commands in PowerShell 7. All laboratory materials belong to **one** repository rooted at `C:\GitHub\DDF`; each laboratory is a directory, not a separate GitHub repository.

### Stage A — reference model and RTL review

Study `DDF-LAB-01`, `rtl/moving_average4.v`, `tb/tb_moving_average4.v` and `RESULTS_MANIFEST.md`. Explain truncating division by four, zero-padded start-up, valid gaps and reset. Numeric/model-only checks must not be presented as HDL simulation.

### Stage B — positive and mutation HDL tests

```powershell
Set-Location "C:\GitHub\DDF\DDF-LAB-02"
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\run.ps1 -Mode All
```

Observed: `RTL_PARSE_PASS`, `SIM_PASS`, `MUTATION_DETECTED`. The positive run reported **146 checks, 120 accepted samples and 120 output events**. The deliberately wrong divide-by-eight mutant failed with `check=2 got=0 want=1`.

The process-scoped `-ExecutionPolicy Bypass` is used only for a reviewed local script; it does not change Windows execution policy globally.

### Stage C — standalone FIR synthesis

```powershell
$gw = "C:\Gowin\Gowin_V1.9.9Beta-4_Education\IDE\bin\gw_sh.exe"
& $gw ".\scripts\gowin_synth.tcl"
```

The generated report is `build/gowin_syn/impl/gwsynthesis/ddf_lab02_syn.rpt.html`. For the **standalone FIR core**, excluding UART: **49 registers, 37 ALU primitives, 1 LUT**; logic usage `38/8640`, register usage `49/6693`. These are not the resources of the completed UART design.

### Stage D — JTAG diagnostics and BIST

```powershell
$prog = "C:\Gowin\Gowin_V1.9.9Beta-4_Education\Programmer\bin\programmer_cli.exe"
& $prog --scan-cables
& $prog --scan
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\test_fir_bist.ps1
& $gw ".\hardware\tangnano9k\build_fir_bist.tcl"
```

First, a standalone LED-blink bitstream was loaded into SRAM and was visibly running on the board. The FIR BIST then passed a 20-directed-vector simulation and mutation test, was implemented and programmed, and produced the observed physical indication: **LED1 ON, LED2 OFF, LED3 BLINKING**.

SRAM programming is volatile and does not program nonvolatile Flash.

### Stage E — UART v0.2 simulation, implementation and SRAM load

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\hardware\tangnano9k\test_fir_uart_v02.ps1
& $gw ".\hardware\tangnano9k\build_fir_uart_v02.tcl"
$fs = (Resolve-Path ".\hardware\tangnano9k\build\fir_uart_v02\impl\pnr\fir_uart9k_v02.fs").Path
Get-FileHash $fs -Algorithm SHA256
```

UART v0.2's HDL testbench passed **114 transactions, including 99 samples** and RESET/HOLD/error cases. The deliberately wrong FIR was rejected. Gowin generated `fir_uart9k_v02.fs`.

Load **SRAM only**:

```powershell
$log = (Join-Path (Get-Location).Path "results\fir_uart_v02_sram_program.log")
Push-Location (Split-Path $prog -Parent)
try {
    & $prog --device GW1NR-9C --operation_index 2 `
        --fsFile $fs --cable-index 1 2>&1 |
        Tee-Object -FilePath $log
    $progRc = $LASTEXITCODE
} finally { Pop-Location }
if ($progRc -ne 0) { throw "FPGA PROGRAMMING FAILED" }
```

Press and release S1 after programming; close any serial application currently holding COM10.

### Stage F — real UART host-to-FPGA comparison

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass `
    -File .\hardware\tangnano9k\run_fir_uart_v02.ps1 `
    -Port COM10 -RandomCount 256 -Seed 20261018
```

The PowerShell host runs a stop-and-wait exchange. It validates the 6-byte response header, transaction sequence number, status, XOR checksum and 12-bit range, and compares each FPGA result with its independently maintained four-sample history.

Generated evidence:
- `results/FIR_UART_V02_HARDWARE_REPORT.json`
- `results/fir_uart_v02_hardware_trace.csv`
- `results/fir_uart_v02_sram_program.log`
- `results/gowin_fir_uart_v02_build.log`

**PASS condition:** no transport/protocol/comparison failure through the complete requested test series, and the actual `FIR_UART_V02_HARDWARE_PASS` output. UART LED activity alone does not establish this result.

## 5. Stop-and-wait UART protocol

Exactly 6 bytes per request and response:

| Direction | Format |
|---|---|
| PC → FPGA | `A5 op seq hi lo xor` |
| FPGA → PC | `5A status seq hi lo xor` |

`xor` is the XOR of the preceding five bytes. The 12-bit unsigned sample is encoded as `hi[3:0]`, `lo[7:0]`.

| Code | Meaning |
|---|---|
| `01` | SAMPLE — accept sample, return new moving average |
| `02` | RESET — clear sample history |
| `03` | HOLD — accept no sample, return held result |
| `00` | OK status |
| `E1` | Invalid opcode |
| `E2` | Incorrect packet XOR |
| `E3` | Payload exceeds 12 bits |

XOR is not a cryptographic integrity guarantee and cannot detect every pattern of multi-bit corruption. The interface is not a high-throughput streaming FIFO.

## 6. Experimental data — 18 October 2026

### 6.1. Failed v0.1 versus successful v0.2

| Item | UART v0.1 | UART v0.2 |
|---|---|---|
| Start, UTC | `2026-10-18T07:16:00.1173883Z` | `2026-10-18T07:26:44.1652825Z` |
| Status | `FIR_UART_HARDWARE_FAIL` | **`FIR_UART_V02_HARDWARE_PASS`** |
| Reported transactions | 3 | **294** |
| Counted SAMPLE operations | 2 | **270** |
| HOLD operations | 0 | **21** |
| RESET operations | 1 | **3** |
| Failure | `seq=2; in=0; expected=1; FPGA=0` | None reported |
| Host link | COM10, 115200 8N1 | COM10, 115200 8N1 |
| PRNG seed | 20261018 | 20261018 |

The successful report is internally consistent: **270 SAMPLE + 21 HOLD + 3 RESET = 294 transactions**. Its SAMPLE count comprises 14 directed and 256 seeded pseudorandom samples.

The v0.1 failure report is retained as primary negative evidence; v0.2 used the same requested random count and seed.

### 6.2. Source and bitstream identity (SHA256)

| Artifact | SHA256 |
|---|---|
| Original FIR RTL in **both** runs | `D81EA8E8BB023B9BBE61255442CB4CFC93DF6BD930B69F38821A1D67A0F9DBB1` |
| UART v0.1 FPGA bitstream | `6AEC266A40B886360DFE91EF427B4924805F77B50537BB95B052DE55F73DC00C` |
| UART v0.2 FPGA bitstream | `F9B5232A3FCA23764910301E5CBE2857C7F3F7536D2012CB474640FD21E21197` |

The identical RTL hash establishes that the recorded FIR core file was unchanged across the two host runs. Different bitstream hashes establish that different FPGA configuration files were used, but do not independently prove a particular failure mechanism.

### 6.3. First ten real CSV records

The table below shows the **first 10 of 294 actual records**. The complete published CSV was retrieved and independently replayed (section 6.4). `RoundTripMs` includes host, USB/UART and protocol overhead, not just FIR combinational or register delay.

| Seq | Phase | Op | Input | Expected | FPGA | Equal | RoundTripMs |
|---:|---|---:|---:|---:|---:|---|---:|
| 0 | initial_reset | 2 | 0 | 0 | 0 | True | 11.688 |
| 1 | directed | 1 | 4 | 1 | 1 | True | 2.267 |
| 2 | directed | 1 | 0 | 1 | 1 | True | 2.278 |
| 3 | directed | 1 | 0 | 1 | 1 | True | 2.231 |
| 4 | directed | 1 | 0 | 1 | 1 | True | 2.280 |
| 5 | directed | 1 | 0 | 0 | 0 | True | 2.208 |
| 6 | directed | 1 | 4095 | 1023 | 1023 | True | 2.220 |
| 7 | directed | 1 | 4095 | 2047 | 2047 | True | 2.252 |
| 8 | directed | 1 | 4095 | 3071 | 3071 | True | 2.283 |
| 9 | directed | 1 | 4095 | 4095 | 4095 | True | 2.260 |

### 6.4. Independent replay of all 294 CSV records

Source: `results/fir_uart_v02_hardware_trace.csv` in the published repository, URL: https://github.com/AIDevelopersMonster/DDF/blob/main/DDF-LAB-02/results/fir_uart_v02_hardware_trace.csv .

This review did **not** rely solely on the `Equal` column. Every row was independently replayed using `floor(sum(last four accepted samples)/4)`, zero-padded history, explicit history reset for `Opcode=2`, and unchanged history for `Opcode=3`. Sequence integrity was checked as `Sequence = zero-based row index modulo 256`.

| Check | Observed |
|---|---:|
| Data records, excluding CSV header | **294** |
| `initial_reset` | 1 |
| `directed` | 14 |
| `random` | 256 |
| `hold_no_valid` | 21 |
| `midstream_reset` | 2 |
| SAMPLE / HOLD / RESET totals | **270 / 21 / 3** |
| `Expected` versus independently computed reference | **0 mismatches** |
| `FPGA` versus independently computed reference | **0 mismatches** |
| Sequence discontinuities | **0** |

This establishes arithmetic and structural consistency of the published trace; it does not independently repeat the electrical measurement. Host-measured `RoundTripMs` includes USB/UART and software overhead and cannot certify the core's maximum frequency or throughput.

## 7. Investigation of the v0.1 hardware failure

In v0.1, the FIR's asynchronous reset was driven by a combinational decode of the UART controller's FSM state:

```verilog
wire fir_rst_n = rst_n && (state != ST_SOFT_RESET);
```

Version v0.2 introduces the registered `fir_soft_reset_hold` signal; the original `moving_average4.v` core remains unchanged.

**Observed:** v0.1 passed zero-delay HDL simulation but failed on physical hardware at `seq=2`. v0.2 passed both HDL simulation and the 294-transaction physical test.

**Plausible explanation:** a transient FSM state-decode hazard may have momentarily asserted asynchronous reset and erased sample history. **Not demonstrated:** the actual waveform or duration of such a transient in silicon. Confirming this mechanism would require further instrumentation or targeted experiments. Successful corrective action is evidence of effectiveness, not a complete causal proof.

## 8. Claim boundaries and reproducibility

**Supported:** executed mathematical/HDL test coverage, mutation detection, standalone FIR synthesis, working JTAG programming, physical LED/BIST observations, actual UART responses and host-reference comparison success for the v0.2 series.

**Not separately established:** post-route timing closure, maximum clock, power draw, long-term reliability, immunity to arbitrary UART interference, full formal equivalence and a proved microscopic cause of the v0.1 failure.

Do not claim the standalone 49-register/37-ALU/1-LUT resource figure for the larger UART wrapper. Preserve the original v0.1 files and failed logs. Transient `build/` files can be regenerated from the Tcl scripts; their bitstream hashes are captured in the experimental reports.

## Appendix A. Blank student laboratory record

| Field | Student entry |
|---|---|
| Operator / date / board revision | __________________ |
| OS, PowerShell, Icarus and Gowin versions | __________________ |
| Git branch / commit / working-tree state | __________________ |
| FPGA, JTAG ID, COM port | __________________ |
| Original RTL SHA256 | __________________ |
| Positive RTL test (checks, transactions) | __________________ |
| Mutation test (observed failure) | __________________ |
| Synthesis resource counts | __________________ |
| P&R errors, timing report and outcome | __________________ |
| FPGA configuration SHA256 | __________________ |
| SRAM programming result and user code | __________________ |
| Physical LED1 / LED2 / LED3 | __________________ |
| UART rate, seed, SAMPLE/HOLD/RESET totals | __________________ |
| Compared transactions / mismatches | __________________ |
| CSV and JSON evidence location and hashes | __________________ |
| Exceptions, limitations, final judgment | __________________ |
| Checked by / date | __________________ |

**Recording discipline:** use `NOT RUN` or `NOT VERIFIED`, not a guessed PASS, for any missing test or evidence.

## Appendix B. Completed DDF-LAB-02 experiment record

| Item | Observed result |
|---|---|
| Experiment date | 2026-10-18 |
| Board / device | Tang Nano 9K / GW1NR-9C (implementation part `GW1NR-LV9QN88PC6/I5`) |
| Tools | Windows 10, PowerShell 7, Icarus Verilog, Gowin Education 1.9.9Beta-4 |
| USB / JTAG | FT2CH; one JTAG device, `0x1100481B` |
| UART | COM10; 115200 8N1 |
| Baseline RTL simulation | `SIM_PASS`: 146 checks, 120 inputs, 120 outputs |
| Baseline mutation | `MUTATION_DETECTED` |
| Core-only synthesis | `GOWIN_SYN_PASS`: 49 registers, 37 ALU, 1 LUT |
| SRAM LED probe | 100% program, exit code 0; observed blinking LED |
| Physical FIR BIST | 20 directed vectors; LED1 ON, LED2 OFF, LED3 BLINK |
| UART v0.1 | FAIL: `seq=2 input=0 expected=1 FPGA=0` |
| UART v0.2 simulation | `UART_V02_BRIDGE_SIM_PASS`, 114 transactions, 99 samples; mutant detected |
| UART v0.2 hardware | **PASS: 270 samples, 21 HOLD, 3 RESET, 294 transactions** |
| Bitstream hashes | See §6.2 |
| Full post-route timing and power | `NOT VERIFIED` from the supplied evidence |
| Overall judgment | **DDF-LAB-02 functional hardware acceptance completed**, within the stated limits |

## Appendix C. Primary evidence and project files

1. `rtl/moving_average4.v`, `rtl_mutant/moving_average4.v`, `tb/tb_moving_average4.v`.
2. `scripts/run.ps1`, `scripts/gowin_synth.tcl`.
3. `hardware/tangnano9k/rtl/top_fir_bist.v`, `test_fir_bist.ps1`, `build_fir_bist.tcl`.
4. `hardware/tangnano9k/rtl/top_fir_uart.v`, `top_fir_uart_v02.v`, `ddf_uart_rx.v`, `ddf_uart_tx.v`.
5. `hardware/tangnano9k/test_fir_uart_v02.ps1`, `build_fir_uart_v02.tcl`, `run_fir_uart_v02.ps1`, `UART_V02_RESET_DIAGNOSTIC.md`.
6. `results/FIR_UART_HARDWARE_REPORT.json` (failed run), `results/FIR_UART_V02_HARDWARE_REPORT.json` (successful run).
7. `results/fir_uart_hardware_trace.csv`, `results/fir_uart_v02_hardware_trace.csv`; Gowin, Icarus and SRAM program logs.
8. `docs/DDF-LAB-02_v0.1_EN.md` is the historical preparatory guide; **do not overwrite** it with this final record.

**Publication note:** retain both JSON and both CSV traces, source files, scripts and checksums; publish them in a reviewed commit to the single `DDF` repository. No DOI, publication license or formal certification is asserted by this document.
