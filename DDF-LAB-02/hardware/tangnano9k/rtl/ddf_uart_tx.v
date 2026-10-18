// DDF-LAB-02 UART transmitter, 8N1, no FIFO, start/busy handshake.
`default_nettype none
module ddf_uart_tx #(
    parameter integer CLKS_PER_BIT = 234
) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] byte_in,
    output reg busy,
    output reg serial_out
);
    reg [9:0] shift;
    reg [3:0] bit_no;
    reg [15:0] timer;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            serial_out <= 1'b1;
            shift <= 10'h3ff;
            timer <= 16'd0;
            bit_no <= 4'd0;
        end else if (!busy) begin
            serial_out <= 1'b1;
            if (start) begin
                shift <= {1'b1, byte_in, 1'b0};
                serial_out <= 1'b0; // Start bit immediately.
                timer <= CLKS_PER_BIT-1;
                bit_no <= 4'd0;
                busy <= 1'b1;
            end
        end else if (timer != 0) begin
            timer <= timer - 16'd1;
        end else if (bit_no == 4'd9) begin
            serial_out <= 1'b1;
            busy <= 1'b0; // Stop bit has completed.
        end else begin
            serial_out <= shift[1];
            shift <= {1'b1, shift[9:1]};
            bit_no <= bit_no + 4'd1;
            timer <= CLKS_PER_BIT-1;
        end
    end
endmodule
`default_nettype wire
