# DDF-LAB-02 - Windows HDL Verification Report

Execution date: 2026-10-18 09:03:22 +03:00

## Actual results

- RTL_PARSE_PASS
- SIM_PASS
- MUTATION_DETECTED

## Positive test

SIM_PASS: moving_average4 checks=146 inputs=120 outputs=120

## Negative mutation test

FATAL: tb/tb_moving_average4.v:75: SIM_FAIL data: check=2 got=0 want=1 valid=1

## Evidence

- results/positive.log
- results/mutation.log
- results/rtl_parse_status.txt
- results/iverilog_version.txt
- results/vvp_version.txt
- results/source_hashes.txt

## Limitations

- Generic synthesis: NOT RUN
- FPGA implementation: NOT RUN
- Physical hardware testing: NOT RUN

This report records actual HDL simulation,
not FPGA hardware verification.
