`timescale 1ns/1ps
`default_nettype none
module tb_top_fir_bist;
    reg clk_27m = 1'b0;
    reg rst_n = 1'b0;
    wire [2:0] led_n;
    always #5 clk_27m = ~clk_27m;
    top_fir_bist #(.BLINK_HALF_PERIOD(4)) dut (
        .clk_27m(clk_27m),
        .rst_n(rst_n),
        .led_n(led_n)
    );
    initial begin
        repeat (4) @(negedge clk_27m);
        rst_n = 1'b1;
        repeat (32) @(negedge clk_27m);
        if ($test$plusargs("EXPECT_MUTANT")) begin
            if (led_n[0] !== 1'b1 || led_n[1] !== 1'b0)
                $fatal(1, "BIST_MUTATION_NOT_DETECTED leds=%b", led_n);
            $display("BIST_MUTATION_DETECTED: known wrong FIR rejected in simulated FPGA wrapper");
        end else begin
            if (led_n[0] !== 1'b0 || led_n[1] !== 1'b1)
                $fatal(1, "BIST_SIM_FAIL leds=%b", led_n);
            $display("BIST_SIM_PASS: 20 directed vectors, 3 LED hardware wrapper");
        end
        $finish;
    end
    initial begin
        #5000;
        $fatal(1,"BIST_SIM_FAIL: timeout");
    end
endmodule
`default_nettype wire
