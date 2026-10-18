# DDF-LAB-01 — Architecture Decision Record

Status: PROVISIONAL
Date: 2026-10-15
Tool: GNU Octave 11.3.0

## Requirements
R01: Useful-signal gain >= 0.95
R02: White-noise STD ratio <= 0.55
R03: Group delay <= 2 samples

## Accepted candidates
N=4: gain=0.9761, noise=0.499, delay=1.5
N=5: gain=0.9619, noise=0.447, delay=2.0

## Selected baseline
Architecture: Direct FIR
Window length: N=4
Input: unsigned 12-bit
Output: unsigned 12-bit, floor(sum/4)
Accumulator width: 14 bits
History: 3 x 12-bit delay registers

## Evidence
signals.m: functional equivalence PASS
noise_test.m: requirements verification PASS
architecture_sweep.m: N=4 and N=5 accepted
fixed_point.m: integer arithmetic model PASS
signals.csv: numerical model results
signals.svg: signal visualization

## Limitations
No RTL simulation or FPGA synthesis performed.
PPA estimates are not measured.
Sample clock frequency is not specified.
Timing and interface requirements remain open.
