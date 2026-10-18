// DDF-LAB-02: independent transaction-history oracle.
// Testbench uses $fatal (SystemVerilog task); DUT is Verilog-2005.
`timescale 1ns/1ps
`default_nettype none
module tb_moving_average4;
    reg clk;
    reg rst_n;
    reg valid_in;
    reg [11:0] data_in;
    wire valid_out;
    wire [11:0] data_out;

    moving_average4 dut (
        .clk(clk), .rst_n(rst_n), .valid_in(valid_in),
        .data_in(data_in), .valid_out(valid_out), .data_out(data_out)
    );

    reg [11:0] accepted [0:1023];
    reg [11:0] wanted_data;
    reg wanted_valid;
    reg [15:0] lfsr;
    integer count_valid;
    integer total_valid;
    integer total_outputs;
    integer checks;
    integer i;
    reg [8*256-1:0] vcd_path;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Drive away from rising edge, check after nonblocking updates.
    // Oracle uses all ACCEPTED input transactions, not DUT registers.
    task step;
        input next_rst_n;
        input next_valid;
        input [11:0] next_data;
        integer j;
        integer s;
        begin
            @(negedge clk);
            rst_n = next_rst_n;
            valid_in = next_valid;
            data_in = next_data;

            if (!next_rst_n) begin
                count_valid = 0;
                wanted_valid = 1'b0;
                wanted_data = 12'd0;
            end else if (next_valid) begin
                if (count_valid >= 1024)
                    $fatal(1, "SIM_FAIL: reference buffer exceeded");
                accepted[count_valid] = next_data;
                count_valid = count_valid + 1;
                total_valid = total_valid + 1;
                s = 0;
                for (j = 0; j < 4; j = j + 1)
                    if ((count_valid - 1 - j) >= 0)
                        s = s + accepted[count_valid - 1 - j];
                wanted_data = s / 4;
                wanted_valid = 1'b1;
            end else begin
                wanted_valid = 1'b0;
                // data_out must hold its last value when input is invalid.
            end

            @(posedge clk);
            #1;
            if (valid_out !== wanted_valid)
                $fatal(1, "SIM_FAIL valid: check=%0d got=%b want=%b",
                       checks, valid_out, wanted_valid);
            if (data_out !== wanted_data)
                $fatal(1, "SIM_FAIL data: check=%0d got=%0d want=%0d valid=%b",
                       checks, data_out, wanted_data, wanted_valid);
            checks = checks + 1;
            if (valid_out === 1'b1)
                total_outputs = total_outputs + 1;
        end
    endtask

    initial begin
        if (!$value$plusargs("VCD=%s", vcd_path))
            vcd_path = "results/filter.vcd";
        $dumpfile(vcd_path);
        $dumpvars(0, tb_moving_average4);

        rst_n = 1'b1;
        valid_in = 1'b0;
        data_in = 12'd0;
        count_valid = 0;
        total_valid = 0;
        total_outputs = 0;
        checks = 0;
        wanted_data = 12'd0;
        wanted_valid = 1'b0;
        lfsr = 16'hACE1;

        // Reset; after release: one impulse of magnitude 4.
        step(1'b0, 1'b0, 12'd0);
        step(1'b0, 1'b0, 12'd0);
        step(1'b1, 1'b1, 12'd4);
        step(1'b1, 1'b1, 12'd0);
        step(1'b1, 1'b0, 12'd4095); // Invalid sample must be ignored.
        step(1'b1, 1'b1, 12'd0);
        step(1'b1, 1'b1, 12'd0);
        step(1'b1, 1'b1, 12'd0);
        step(1'b0, 1'b0, 12'd0); // Fresh reset before full-scale test.
        // Full-scale sequence: 1023, 2047, 3071, 4095.
        step(1'b1, 1'b1, 12'd4095);
        step(1'b1, 1'b1, 12'd4095);
        step(1'b1, 1'b1, 12'd4095);
        step(1'b1, 1'b1, 12'd4095);
        step(1'b1, 1'b0, 12'd0);
        step(1'b1, 1'b0, 12'd4095);
        // Reset amid an active history; prior transactions disappear.
        step(1'b0, 1'b0, 12'd0);
        step(1'b1, 1'b1, 12'd4095);
        step(1'b1, 1'b1, 12'd0);
        // Deterministic reproducible mixed pattern, including valid gaps.
        for (i = 0; i < 128; i = i + 1) begin
            lfsr = {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
            step(1'b1, ((i % 7) != 0), lfsr[11:0]);
        end

        if (total_valid != total_outputs)
            $fatal(1, "SIM_FAIL transaction counts %0d != %0d",
                   total_valid, total_outputs);
        if (checks < 140 || total_valid < 100)
            $fatal(1, "SIM_FAIL test coverage sanity checks=%0d valid=%0d",
                   checks, total_valid);
        $display("SIM_PASS: moving_average4 checks=%0d inputs=%0d outputs=%0d",
                 checks, total_valid, total_outputs);
        $finish;
    end

    initial begin
        #20000;
        $fatal(1, "SIM_FAIL watchdog timeout");
    end
endmodule
`default_nettype wire
