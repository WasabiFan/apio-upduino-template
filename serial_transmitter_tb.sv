`timescale 1ns/1ps

module serial_transmitter_tb();
    initial begin
        $dumpfile("serial_transmitter_tb.vcd");
        $dumpvars(0,serial_transmitter_tb);
    end

    reg clock, reset;
    wire tx_data_available, tx_ready, serial_tx;
    wire [7:0] tx_data;

    serial_transmitter u_serial_transmitter (
        .clock                (clock),
        .reset                (reset),
        .tx_data              (tx_data),
        .tx_data_available    (tx_data_available),
        .tx_ready             (tx_ready),
        .serial_tx            (serial_tx)
    );

    assign tx_data = 8'd65;
    assign tx_data_available = tx_ready;

    initial begin
        clock = 1'b0;
    end

    always begin
        #10 clock = !clock;
    end

    initial begin
        @(posedge clock); reset = 1'b1;
        @(posedge clock); reset = 1'b0;
        repeat(1000000) @(posedge clock);

        $finish;
    end
endmodule
