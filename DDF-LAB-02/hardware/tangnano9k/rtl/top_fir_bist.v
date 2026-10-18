// DDF-LAB-02: Hardware built-in self-test for moving_average4.
// Target: Tang Nano 9K, 27 MHz. Board pins in top_fir_bist.cst.
// All expected results are hard-coded from an independent reference table.
// LEDs are active LOW: led_n[0]=PASS, led_n[1]=FAIL, led_n[2]=heartbeat.
`default_nettype none
module top_fir_bist #(
    parameter integer BLINK_HALF_PERIOD = 13500000
) (
    input  wire       clk_27m,
    input  wire       rst_n,
    output wire [2:0] led_n
);
    localparam [5:0] VECTOR_COUNT = 6'd20;
    reg [5:0] index;

    reg        sample_valid;
    reg [11:0] sample_data;
    reg [11:0] expected_current;
    wire       result_valid;
    wire [11:0] result_data;

    moving_average4 dut (
        .clk       (clk_27m),
        .rst_n     (rst_n),
        .valid_in  (sample_valid),
        .data_in   (sample_data),
        .valid_out (result_valid),
        .data_out  (result_data)
    );

    // Directed vectors.  Invalid samples must be ignored; data_out must hold.
    // Each expected value is a literal, not computed from the DUT's registers.
    always @* begin
        sample_valid     = 1'b0;
        sample_data      = 12'd0;
        expected_current = 12'd0;
        case (index)
             0: begin sample_valid=0; sample_data=12'd0;    expected_current=12'd0;    end
             1: begin sample_valid=1; sample_data=12'd4;    expected_current=12'd1;    end
             2: begin sample_valid=1; sample_data=12'd0;    expected_current=12'd1;    end
             3: begin sample_valid=0; sample_data=12'd4095; expected_current=12'd1;    end
             4: begin sample_valid=1; sample_data=12'd0;    expected_current=12'd1;    end
             5: begin sample_valid=1; sample_data=12'd0;    expected_current=12'd1;    end
             6: begin sample_valid=1; sample_data=12'd0;    expected_current=12'd0;    end
             7: begin sample_valid=1; sample_data=12'd4095; expected_current=12'd1023; end
             8: begin sample_valid=1; sample_data=12'd4095; expected_current=12'd2047; end
             9: begin sample_valid=1; sample_data=12'd4095; expected_current=12'd3071; end
            10: begin sample_valid=1; sample_data=12'd4095; expected_current=12'd4095; end
            11: begin sample_valid=0; sample_data=12'd42;   expected_current=12'd4095; end
            12: begin sample_valid=1; sample_data=12'd0;    expected_current=12'd3071; end
            13: begin sample_valid=1; sample_data=12'd1;    expected_current=12'd2047; end
            14: begin sample_valid=1; sample_data=12'd2;    expected_current=12'd1024; end
            15: begin sample_valid=1; sample_data=12'd3;    expected_current=12'd1;    end
            16: begin sample_valid=1; sample_data=12'd4;    expected_current=12'd2;    end
            17: begin sample_valid=0; sample_data=12'd4000; expected_current=12'd2;    end
            18: begin sample_valid=1; sample_data=12'd4095; expected_current=12'd1026; end
            19: begin sample_valid=0; sample_data=12'd4095; expected_current=12'd1026; end
            default: begin sample_valid=0; sample_data=0; expected_current=0; end
        endcase
    end

    // At each posedge: the DUT consumes vector[index], while this checker
    // compares the DUT's PREVIOUS registered result against prev_expected.
    // Nonblocking assignments make the one-edge observation delay explicit.
    reg [11:0] prev_expected;
    reg        prev_valid;
    reg        check_pending;
    reg        pass_latched;
    reg        fail_latched;
    wire       result_matches = (result_data == prev_expected) &&
                                (result_valid == prev_valid);

    reg [24:0] heartbeat_count;
    reg heartbeat;

    always @(posedge clk_27m or negedge rst_n) begin
        if (!rst_n) begin
            index           <= 6'd0;
            prev_expected   <= 12'd0;
            prev_valid      <= 1'b0;
            check_pending   <= 1'b0;
            pass_latched    <= 1'b0;
            fail_latched    <= 1'b0;
            heartbeat_count <= 25'd0;
            heartbeat       <= 1'b0;
        end else begin
            if (heartbeat_count == BLINK_HALF_PERIOD-1) begin
                heartbeat_count <= 25'd0;
                heartbeat       <= ~heartbeat;
            end else begin
                heartbeat_count <= heartbeat_count + 25'd1;
            end

            if (index < VECTOR_COUNT) begin
                if (check_pending && !result_matches)
                    fail_latched <= 1'b1;
                prev_expected <= expected_current;
                prev_valid    <= sample_valid;
                check_pending <= 1'b1;
                index         <= index + 6'd1;
            end else if (index == VECTOR_COUNT) begin
                // Final comparison: vector 19's result is now registered.
                if (check_pending && !result_matches)
                    fail_latched <= 1'b1;
                else if (check_pending && !fail_latched)
                    pass_latched <= 1'b1;
                index <= VECTOR_COUNT + 6'd1;
            end
        end
    end

    assign led_n[0] = ~pass_latched;
    assign led_n[1] = ~fail_latched;
    assign led_n[2] = ~heartbeat;
endmodule
`default_nettype wire
