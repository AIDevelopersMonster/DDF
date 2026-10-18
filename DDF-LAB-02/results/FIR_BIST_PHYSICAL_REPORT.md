# DDF-LAB-02 — Physical FPGA Test Report

Date recorded: 2026-10-18 09:52:00
Platform: Sipeed Tang Nano 9K
FPGA: GW1NR-9C
Toolchain: Gowin Education V1.9.9Beta-4

## Programming

Mode: SRAM via JTAG
Programming exit code: 0
User Code: 0x00000894
Status Code: 0x0003F020

## Physical observations

LED1: ON
LED2: OFF
LED3: BLINKING

Result: FIR_HARDWARE_BIST_PASS

## Verification

20 directed vectors in hardware BIST.
Positive HDL simulation: PASS
Negative mutation simulation: DETECTED
FPGA BIST indication: PASS

## Bitstream

File: fir_bist9k.fs
SHA256: C7D0808A9979F2EEAE3B44A85DD0332DD0CEC461976040436CFF46F2FB40FB84

## Limitations

This experiment verifies the built-in self-test
on physical FPGA hardware.

External UART data exchange: NOT RUN
Independent PC-to-FPGA comparison: NOT RUN
