// DDF-LAB-02 v0.1
// Verilog-2005 synthesizable moving average; 4 accepted samples.
// Contract: rising clk && valid_in accepts unsigned data_in.
// The registered valid_out/data_out settle after that same edge.
// Missing samples before reset are treated as zero.
// No ready/backpressure; downstream must accept every valid_out.
`default_nettype none
module moving_average4 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [11:0] data_in,
    output reg         valid_out,
    output reg  [11:0] data_out
);
    reg  [11:0] d1, d2, d3;
    wire [13:0] sum_comb;

    // Explicit 14-bit zero extension avoids expression-width ambiguity.
    assign sum_comb = {2'b00, data_in}
                    + {2'b00, d1}
                    + {2'b00, d2}
                    + {2'b00, d3};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1        <= 12'd0;
            d2        <= 12'd0;
            d3        <= 12'd0;
            data_out  <= 12'd0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            if (valid_in) begin
                data_out <= sum_comb[13:2];
                d3 <= d2;
                d2 <= d1;
                d1 <= data_in;
            end
        end
    end
endmodule
`default_nettype wire
