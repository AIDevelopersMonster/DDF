// DDF-LAB-02 UART receiver, 8N1, 27 MHz / 115200 baud (234 clocks/bit).
// Verilog-2005, single-clock, two-flop input synchronizer.
`default_nettype none
module ddf_uart_rx #(
    parameter integer CLKS_PER_BIT = 234
) (
    input wire clk,
    input wire rst_n,
    input wire serial_in,
    output reg [7:0] byte_out,
    output reg byte_valid
);
    localparam [1:0] IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state;
    reg [15:0] timer;
    reg [2:0] bit_no;
    reg [7:0] shift;
    reg sync1, sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync1 <= 1'b1;
            sync2 <= 1'b1;
            state <= IDLE;
            timer <= 16'd0;
            bit_no <= 3'd0;
            shift <= 8'd0;
            byte_out <= 8'd0;
            byte_valid <= 1'b0;
        end else begin
            sync1 <= serial_in;
            sync2 <= sync1;
            byte_valid <= 1'b0;
            case (state)
                IDLE: begin
                    if (!sync2) begin
                        timer <= (CLKS_PER_BIT/2)-1;
                        state <= START;
                    end
                end
                START: begin
                    if (timer != 0)
                        timer <= timer - 16'd1;
                    else if (!sync2) begin
                        state <= DATA;
                        timer <= CLKS_PER_BIT-1;
                        bit_no <= 3'd0;
                    end else
                        state <= IDLE; // False start.
                end
                DATA: begin
                    if (timer != 0)
                        timer <= timer - 16'd1;
                    else begin
                        shift[bit_no] <= sync2;
                        timer <= CLKS_PER_BIT-1;
                        if (bit_no == 3'd7)
                            state <= STOP;
                        else
                            bit_no <= bit_no + 3'd1;
                    end
                end
                STOP: begin
                    if (timer != 0)
                        timer <= timer - 16'd1;
                    else begin
                        if (sync2) begin
                            byte_out <= shift;
                            byte_valid <= 1'b1;
                        end
                        // On invalid stop: silently discard frame. The host
                        // detects missing response by timeout; S1 resets state.
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
`default_nettype wire
