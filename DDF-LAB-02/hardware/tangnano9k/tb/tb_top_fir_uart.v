// End-to-end UART simulation: an external serial master, not an RTL peek.
// Independent history/oracle; checksum, sequence, reset and HOLD verified.
`timescale 1ns/1ps
`default_nettype none
module tb_top_fir_uart;
    localparam integer CPB=16;
    reg clk=0;
    reg rst_n=0;
    reg serial_in=1;
    wire serial_out;
    wire [2:0] led_n;
    reg [7:0] response [0:5];
    reg [11:0] history [0:3];
    reg [15:0] lfsr;
    integer test_count;
    integer sample_count;
    integer i;
    integer j;
    integer sum;
    integer last_wanted;
    reg [7:0] checksum;

    always #5 clk = ~clk;

    top_fir_uart #(.UART_CLKS_PER_BIT(CPB), .BLINK_HALF_PERIOD(80)) dut (
        .clk_27m(clk), .rst_n(rst_n), .uart_rx(serial_in),
        .uart_tx(serial_out), .led_n(led_n)
    );

    task send_byte;
        input [7:0] value;
        integer bit_idx;
        begin
            @(negedge clk); serial_in=0;
            repeat(CPB) @(negedge clk);
            for (bit_idx=0; bit_idx<8; bit_idx=bit_idx+1) begin
                serial_in=value[bit_idx];
                repeat(CPB) @(negedge clk);
            end
            serial_in=1;
            repeat(CPB) @(negedge clk);
        end
    endtask

    task receive_byte;
        output [7:0] value;
        integer bit_idx;
        begin
            value=0;
            @(negedge serial_out);
            repeat(CPB/2) @(posedge clk);
            if (serial_out !== 0)
                $fatal(1,"UART_TB_FRAMING_ERROR start");
            for(bit_idx=0;bit_idx<8;bit_idx=bit_idx+1) begin
                repeat(CPB) @(posedge clk);
                value[bit_idx]=serial_out;
            end
            repeat(CPB) @(posedge clk);
            if (serial_out !== 1)
                $fatal(1,"UART_TB_FRAMING_ERROR stop");
        end
    endtask

    task send_frame;
        input [7:0] op;
        input [7:0] seq;
        input [15:0] value;
        input corrupt;
        reg [7:0] cs;
        begin
            cs=8'ha5 ^ op ^ seq ^ value[15:8] ^ value[7:0];
            if (corrupt) cs=cs ^ 8'h01;
            send_byte(8'ha5);
            send_byte(op);
            send_byte(seq);
            send_byte(value[15:8]);
            send_byte(value[7:0]);
            send_byte(cs);
        end
    endtask

    task receive_frame;
        integer k;
        begin
            for (k=0;k<6;k=k+1)
                receive_byte(response[k]);
        end
    endtask

    task do_request;
        input [7:0] op;
        input [7:0] seq;
        input [15:0] value;
        input corrupt;
        input [7:0] expected_status;
        integer wanted;
        begin
            wanted=last_wanted;
            if (expected_status == 8'h00) begin
                if (op == 8'h02) begin
                    wanted=0;
                end else if (op == 8'h01) begin
                    sum=value;
                    for(j=0;j<3;j=j+1)
                        sum=sum+history[j];
                    wanted=sum/4;
                end
            end
            fork
                send_frame(op,seq,value,corrupt);
                receive_frame();
            join
            checksum=response[0]^response[1]^response[2]^
                     response[3]^response[4];
            if (response[0] !== 8'h5a || response[2] !== seq ||
                response[5] !== checksum || response[3][7:4] !== 4'b0000)
                $fatal(1,"UART_TB_PROTOCOL_FAIL tx=%0d hdr=%h seq=%h crc=%h/%h",
                       test_count,response[0],response[2],response[5],checksum);
            if (response[1] !== expected_status)
                $fatal(1,"UART_TB_STATUS_FAIL tx=%0d got=%h expected=%h",
                       test_count,response[1],expected_status);
            if ({response[3][3:0],response[4]} !== wanted[11:0])
                $fatal(1,"UART_TB_MISMATCH tx=%0d op=%h val=%d got=%d wanted=%d",
                       test_count,op,value,{response[3][3:0],response[4]},wanted);
            if (expected_status==0 && op==8'h02) begin
                for(j=0;j<4;j=j+1) history[j]=0;
                last_wanted=0;
            end else if(expected_status==0 && op==8'h01) begin
                for(j=3;j>0;j=j-1) history[j]=history[j-1];
                history[0]=value[11:0];
                last_wanted=wanted;
                sample_count=sample_count+1;
            end
            test_count=test_count+1;
        end
    endtask

    initial begin
        for(i=0;i<4;i=i+1) history[i]=0;
        test_count=0;
        sample_count=0;
        last_wanted=0;
        lfsr=16'hace1;
        repeat(12) @(negedge clk);
        rst_n=1;
        repeat(16) @(negedge clk);
        do_request(8'h02,8'd1,16'd0,0,8'h00); // Reset history.
        do_request(8'h01,8'd2,16'd4,0,8'h00); // Expected 1.
        do_request(8'h01,8'd3,16'd0,0,8'h00);
        do_request(8'h03,8'd4,16'd0,0,8'h00); // HOLD, no valid_in.
        do_request(8'h01,8'd5,16'd0,0,8'h00);
        do_request(8'h01,8'd6,16'd0,0,8'h00);
        do_request(8'h01,8'd7,16'd0,0,8'h00);
        do_request(8'h01,8'd8,16'd4095,0,8'h00);
        do_request(8'h01,8'd9,16'd4095,0,8'h00);
        do_request(8'h01,8'd10,16'd4095,0,8'h00);
        do_request(8'h01,8'd11,16'd4095,0,8'h00);
        do_request(8'h03,8'd12,16'd0,0,8'h00);
        do_request(8'h01,8'd13,16'd0,1,8'he2); // Bad XOR, reject.
        do_request(8'h77,8'd14,16'd0,0,8'he1); // Bad opcode.
        do_request(8'h01,8'd15,16'h1001,0,8'he3); // > 12 bits.
        do_request(8'h01,8'd16,16'd0,0,8'h00); // History unchanged by errors.
        do_request(8'h02,8'd17,16'd0,0,8'h00);
        do_request(8'h01,8'd18,16'd4095,0,8'h00);
        for(i=0;i<96;i=i+1) begin
            lfsr={lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};
            if((i%13)==0) do_request(8'h03,(i+19),16'd0,0,8'h00);
            else do_request(8'h01,(i+19),{4'b0000,lfsr[11:0]},0,8'h00);
        end
        if(test_count<100 || sample_count<80)
            $fatal(1,"UART_TB_COVERAGE_FAIL transactions=%d samples=%d",test_count,sample_count);
        $display("UART_BRIDGE_SIM_PASS: transactions=%0d samples=%0d reset/hold/errors tested",
                 test_count,sample_count);
        $finish;
    end
    initial begin
        #10000000;
        $fatal(1,"UART_TB_TIMEOUT");
    end
endmodule
`default_nettype wire
