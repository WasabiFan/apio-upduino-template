`timescale 1ns/1ps

module serial_transmitter_tb();
    initial begin
        $dumpfile("serial_transmitter_tb.vcd");
        $dumpvars(0,serial_transmitter_tb);
    end

    reg clock, reset;
    wire tx_ready, serial_tx;

    reg tx_data_available;
    reg [7:0] tx_data;

    serial_transmitter u_serial_transmitter (
        .clock                (clock),
        .reset                (reset),
        .tx_data              (tx_data),
        .tx_data_available    (tx_data_available),
        .tx_ready             (tx_ready),
        .serial_tx            (serial_tx)
    );

    initial begin
        clock = 1'b0;
    end

    always begin
        #10 clock = !clock;
    end

    initial begin
        tx_data_available <= 1'b0; tx_data = 8'b0;

        @(posedge clock); reset <= 1'b1;
        @(posedge clock); reset <= 1'b0;
        @(posedge clock);

        @(posedge clock); tx_data_available <= 1'b0; tx_data = 8'hAB;
        repeat(5000) @(posedge clock);
        @(posedge clock); tx_data_available <= 1'b1;
        @(posedge clock); tx_data_available <= 1'b0;
        repeat(5000*10-1) @(posedge clock);
        @(posedge clock); tx_data_available <= 1'b1; tx_data = 8'h11;
        @(posedge clock); tx_data_available <= 1'b0;
        repeat(5000*10-1) @(posedge clock);

        $finish;
    end
endmodule
