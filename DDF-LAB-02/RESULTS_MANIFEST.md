# DDF-LAB-02 v0.1 - preparation and acceptance status

**Date:** 2026-10-17. This record reflects the *assistant-side build environment*, not an execution on the student's Windows computer.

| Procedure | Status | Evidence |
|---|---|---|
| Reproducible mathematical model | MODEL_PASS | results/model_check.log |
| Selected RTL source-text assertions | STATIC_SOURCE_ASSERTIONS_PASS | results/static_source.log |
| Icarus RTL parsing | NOT RUN | Icarus not installed in build environment |
| Verilog HDL functional simulation | NOT RUN | No vvp executable; no HDL `SIM_PASS` log |
| Intentional-mutation test via HDL simulator | NOT RUN | Cannot claim mutation detection until vvp run |
| Yosys generic synthesis | NOT RUN | Yosys not installed in build environment |
| FPGA timing, resources, power | NOT RUN | No selected FPGA or vendor constraints |
| PDF/ZIP reproducibility check | Recorded separately | PDFs, SHA256SUMS.txt and ZIP integrity |

A user-facing result must be updated from the **actual log of their system**, not from an expected console transcript.
