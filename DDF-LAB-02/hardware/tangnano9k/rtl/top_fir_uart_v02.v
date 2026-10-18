// DDF-LAB-02: stop-and-wait UART access to the UNMODIFIED moving_average4.
// Clock 27 MHz, UART 115200 8N1, 234 clocks/bit. No vendor IP required.
// FPGA TX=pin17, FPGA RX=pin18 on Sipeed Tang Nano 9K.
// Request:  A5 op seq hi lo xor(A5,op,seq,hi,lo).
// Response: 5A status seq hi lo xor(5A,status,seq,hi,lo).
// Op 01 SAMPLE (12-bit); 02 RESET history; 03 HOLD (no new sample).
// Status 00 OK, E1 opcode error, E2 checksum error, E3 input range error.
// One outstanding command; the PC MUST wait for each 6-byte response.
// Active-low LEDs: LED1 toggles per accepted SAMPLE, LED2 error latch,
// LED3 heartbeat. S1 / pin3 is hardware reset.
`default_nettype none
module top_fir_uart_v02 #(
    parameter integer UART_CLKS_PER_BIT = 234,
    parameter integer BLINK_HALF_PERIOD = 13500000
) (
    input wire clk_27m,
    input wire rst_n,
    input wire uart_rx,
    output wire uart_tx,
    output wire [2:0] led_n
);
    localparam [3:0]
        ST_SYNC=0, ST_OP=1, ST_SEQ=2, ST_HI=3, ST_LO=4, ST_CRC=5,
        ST_ISSUE=6, ST_WAIT_RESULT=7, ST_SOFT_RESET=8, ST_PREP=9,
        ST_TX_START=10, ST_TX_WAIT_BUSY=11, ST_TX_WAIT_DONE=12;
    localparam integer GAP_LIMIT = UART_CLKS_PER_BIT * 20;

    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_busy;
    reg [3:0] state;
    reg [15:0] gap_count;
    reg [7:0] req_op, req_seq, req_hi, req_lo, req_crc;
    reg [7:0] rsp_status, rsp_crc;
    reg [11:0] rsp_data;
    reg [2:0] tx_index;
    reg sample_toggle, error_latched, heartbeat;
    reg [24:0] heartbeat_count;

    // HW v0.2: A combinational FSM decode must NOT drive an asynchronous
    // FIR reset. State-register transitions could glitch the decoder and
    // erase the sample history in silicon (RTL zero-delay simulation misses it).
    // The soft reset is now a dedicated flip-flop asserted for exactly one
    // clock interval, only by opcode 02. External pushbutton reset stays async.
    reg fir_soft_reset_hold;
    wire fir_rst_n = rst_n && !fir_soft_reset_hold;
    wire fir_valid_in = (state == ST_ISSUE) && (req_op == 8'h01);
    wire fir_valid_out;
    wire [11:0] fir_data_out;

    moving_average4 fir (
        .clk(clk_27m), .rst_n(fir_rst_n),
        .valid_in(fir_valid_in), .data_in({req_hi[3:0], req_lo}),
        .valid_out(fir_valid_out), .data_out(fir_data_out)
    );

    ddf_uart_rx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) receive (
        .clk(clk_27m), .rst_n(rst_n), .serial_in(uart_rx),
        .byte_out(rx_data), .byte_valid(rx_valid)
    );

    reg [7:0] tx_data;
    always @* begin
        case (tx_index)
            3'd0: tx_data = 8'h5a;
            3'd1: tx_data = rsp_status;
            3'd2: tx_data = req_seq;
            3'd3: tx_data = {4'd0, rsp_data[11:8]};
            3'd4: tx_data = rsp_data[7:0];
            3'd5: tx_data = rsp_crc;
            default: tx_data = 8'h00;
        endcase
    end

    ddf_uart_tx #(.CLKS_PER_BIT(UART_CLKS_PER_BIT)) transmit (
        .clk(clk_27m), .rst_n(rst_n),
        .start(state == ST_TX_START), .byte_in(tx_data),
        .busy(tx_busy), .serial_out(uart_tx)
    );

    assign led_n[0] = ~sample_toggle;
    assign led_n[1] = ~error_latched;
    assign led_n[2] = ~heartbeat;

    always @(posedge clk_27m or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_SYNC;
            fir_soft_reset_hold <= 1'b0;
            gap_count <= 16'd0;
            req_op <= 8'd0;
            req_seq <= 8'd0;
            req_hi <= 8'd0;
            req_lo <= 8'd0;
            req_crc <= 8'd0;
            rsp_status <= 8'd0;
            rsp_data <= 12'd0;
            rsp_crc <= 8'd0;
            tx_index <= 3'd0;
            sample_toggle <= 1'b0;
            error_latched <= 1'b0;
            heartbeat_count <= 25'd0;
            heartbeat <= 1'b0;
        end else begin
            // Assert after RESET is accepted; release on the next clock.
            // This registered control never decodes changing FSM bits
            // directly into the sensitive asynchronous reset pin.
            if ((state == ST_ISSUE) && (req_op == 8'h02))
                fir_soft_reset_hold <= 1'b1;
            else if (state == ST_SOFT_RESET)
                fir_soft_reset_hold <= 1'b0;

            if (heartbeat_count == BLINK_HALF_PERIOD-1) begin
                heartbeat_count <= 25'd0;
                heartbeat <= ~heartbeat;
            end else
                heartbeat_count <= heartbeat_count + 25'd1;

            // Frame inter-byte timeout resynchronizes on a new A5 marker.
            if ((state >= ST_OP && state <= ST_CRC) &&
                !rx_valid && gap_count >= GAP_LIMIT) begin
                state <= ST_SYNC;
                gap_count <= 16'd0;
            end else begin
                if (state >= ST_OP && state <= ST_CRC) begin
                    if (rx_valid) gap_count <= 16'd0;
                    else gap_count <= gap_count + 16'd1;
                end else
                    gap_count <= 16'd0;

                case (state)
                    ST_SYNC: if (rx_valid && rx_data == 8'ha5) begin
                        req_crc <= 8'ha5;
                        rsp_status <= 8'h00;
                        state <= ST_OP;
                    end
                    ST_OP: if (rx_valid) begin
                        req_op <= rx_data;
                        req_crc <= req_crc ^ rx_data;
                        state <= ST_SEQ;
                    end
                    ST_SEQ: if (rx_valid) begin
                        req_seq <= rx_data;
                        req_crc <= req_crc ^ rx_data;
                        state <= ST_HI;
                    end
                    ST_HI: if (rx_valid) begin
                        req_hi <= rx_data;
                        req_crc <= req_crc ^ rx_data;
                        state <= ST_LO;
                    end
                    ST_LO: if (rx_valid) begin
                        req_lo <= rx_data;
                        req_crc <= req_crc ^ rx_data;
                        state <= ST_CRC;
                    end
                    ST_CRC: if (rx_valid) begin
                        if (rx_data != req_crc) begin
                            rsp_status <= 8'he2;
                            error_latched <= 1'b1;
                            state <= ST_PREP;
                        end else if (req_op != 8'h01 && req_op != 8'h02 && req_op != 8'h03) begin
                            rsp_status <= 8'he1;
                            error_latched <= 1'b1;
                            state <= ST_PREP;
                        end else if (req_hi[7:4] != 4'b0000) begin
                            rsp_status <= 8'he3;
                            error_latched <= 1'b1;
                            state <= ST_PREP;
                        end else begin
                            rsp_status <= 8'h00;
                            state <= ST_ISSUE;
                        end
                    end
                    ST_ISSUE: begin
                        if (req_op == 8'h01) begin
                            sample_toggle <= ~sample_toggle;
                            state <= ST_WAIT_RESULT;
                        end else if (req_op == 8'h02) begin
                            sample_toggle <= 1'b0;
                            error_latched <= 1'b0;
                            state <= ST_SOFT_RESET;
                        end else
                            state <= ST_PREP;
                    end
                    ST_WAIT_RESULT: state <= ST_PREP;
                    ST_SOFT_RESET: state <= ST_PREP;
                    ST_PREP: begin
                        rsp_data <= fir_data_out;
                        rsp_crc <= 8'h5a ^ rsp_status ^ req_seq ^
                                   {4'd0, fir_data_out[11:8]} ^ fir_data_out[7:0];
                        tx_index <= 3'd0;
                        state <= ST_TX_START;
                    end
                    ST_TX_START: state <= ST_TX_WAIT_BUSY;
                    ST_TX_WAIT_BUSY: if (tx_busy) state <= ST_TX_WAIT_DONE;
                    ST_TX_WAIT_DONE: if (!tx_busy) begin
                        if (tx_index == 3'd5)
                            state <= ST_SYNC;
                        else begin
                            tx_index <= tx_index + 3'd1;
                            state <= ST_TX_START;
                        end
                    end
                    default: state <= ST_SYNC;
                endcase
            end
        end
    end
endmodule
`default_nettype wire
