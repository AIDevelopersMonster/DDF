module top_probe (
    input  wire clk_27m,
    input  wire rst_n,
    output reg  led_n
);

reg [23:0] counter;

always @(posedge clk_27m or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 24'd0;
        led_n   <= 1'b1;
    end
    else if (counter == 24'd13499999) begin
        counter <= 24'd0;
        led_n   <= ~led_n;
    end
    else begin
        counter <= counter + 1'b1;
    end
end

endmodule
