# DDF-LAB-02 v0.1: Moving-average FIR in Verilog (L04 + L05)

**Date:** 2026-10-17. **Status:** METHOD_READY / HDL_SIM_NOT_RUN on preparation host.

This course lab bridges the DDF-LAB-01 GNU Octave model and lectures DDF-L04 (HDL semantics) + DDF-L05 (functional simulation). The DUT is **synthesizable Verilog-2005**; the independent testbench uses `$fatal` and is compiled in SystemVerilog-2012 mode. The work is designed for Windows 10 + PowerShell 7 + MSYS2 UCRT64 but does not require a specific vendor FPGA platform.

## Start here

- `docs/DDF-LAB-02_v0.1_RU.md`: full Russian methodology with blank and prepared protocols.
- `docs/DDF-LAB-02_v0.1_EN.md`: full English methodology.
- `rtl/moving_average4.v`: baseline DUT, 12-bit unsigned input and 14-bit sum.
- `tb/tb_moving_average4.v`: independent full-transaction oracle and directed/LFSR tests.
- `rtl_mutant/moving_average4.v`: *deliberately wrong* RTL for negative validation.
- `scripts/run.ps1`: PowerShell 7 run with positive/negative modes; emits VCD and logs.
- `scripts/synth.ps1`: optional generic Yosys synthesis (not FPGA timing).
- `scripts/model_check.py`: non-HDL numeric model check.
- `results/`: preparation logs and placeholder NOT_RUN record. After student execution, add real simulator logs here.
- `assets/`: architecture and timing explanatory SVG figures.

## Windows 10 / PowerShell 7

From an MSYS2 UCRT64 terminal, install Icarus if needed:

```sh
pacman -S --needed mingw-w64-ucrt-x86_64-iverilog
```

Then, inside the extracted project directory:

```powershell
pwsh -NoProfile -File .\scripts\run.ps1 -Mode All
```

Positive simulation must exit successfully and print `SIM_PASS`. The negative mutant must exit nonzero inside `vvp`; the wrapper validates this and prints `MUTATION_DETECTED`. Do not confuse expected mutant failure with a baseline DUT failure.

Optional generic synthesis:

```powershell
pwsh -NoProfile -File .\scripts\synth.ps1
```

If tools are not installed, record `NOT RUN`. Earlier Python MODEL_PASS is not HDL SIM_PASS.

## Evidence categories

MODEL_PASS = numeric Python check executed; STATIC_SOURCE_ASSERTIONS_PASS = selected textual assertions checked; RTL_PARSE_PASS = Verilog parser success; SIM_PASS = actual positive HDL testbench pass; MUTATION_DETECTED = actual mutant rejection; GENERIC_SYNTH_PASS = completed generic synthesis; TIMING_PASS and FPGA_PASS each require independent subsequent evidence.

## Provenance, licenses and publication

DDF-L04 v0.1 (2026-10-16), DDF-L05 v0.1 (2026-10-17) and DDF-LAB-01 provided the basis. The old 2025 L04/L05 lecture texts are not known to be available, and no historical text was reconstructed. Author of course: Alex Malachevsky, ORCID 0009-0008-6009-3196; research partner: Sol. No publication license is asserted for these course assets without the author's decision. No Zenodo deposit or DOI is claimed.

## Regenerate the teaching PDFs

Requires Python 3, Pandoc and WeasyPrint with a font supporting Cyrillic.

```bash
python scripts/make_diagrams.py
python scripts/build_pdf.py
```

The PDF output uses the CSS file `scripts/pdf.css`. This PDF pipeline is an artifact-generation dependency only; it is **not** a requirement for students simply running the Verilog laboratory.
