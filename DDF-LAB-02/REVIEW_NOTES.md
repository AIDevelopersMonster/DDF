# Pre-publication / teaching audit: DDF-LAB-02 v0.1

## Scope
- Practical continuation of DDF-LAB-01 (system model) and the L04/L05 theory.
- Uses Verilog-2005 in DUT, SystemVerilog-compatible testbench syntax.
- Functional testbench and controlled faulty RTL are supplied.
- Student is allowed to choose another suitable CLI simulator and explain its limits.

## Verified in preparation container
- Python numerical oracle versus distinct running-sum model: MODEL_PASS.
- Targeted textual source assertions: STATIC_SOURCE_ASSERTIONS_PASS.
- PDF generated from RU/EN markdown, rendered and visually reviewed.
- PDFs contain searchable text and bookmarks; PDF text layout checked against page bounds.
- ZIP integrity and checksums will be recorded in SHA256SUMS.txt.

## Not verified; must be disclosed
- Icarus Verilog parsing and functional HDL simulation: NOT RUN, no installed tool.
- Mutation failure in HDL tool: NOT RUN; predicted only.
- Yosys generic synthesis: NOT RUN; no installed tool.
- FPGA device synthesis, PPA, timing and hardware: NOT RUN.

## Next factual gates
1. Student runs `scripts/run.ps1 -Mode All` on a machine with Icarus and retains exact tool versions.
2. Confirm both positive SIM_PASS and negative MUTATION_DETECTED (with actual nonzero mutant vvp status).
3. Inspect and attach VCD and source SHA-256; any bugs trigger v0.2, never silent replacement of v0.1.
4. Optional Yosys run only when justified by laboratory aims.
5. Independent technical reviews and real logs before changing publication status.
