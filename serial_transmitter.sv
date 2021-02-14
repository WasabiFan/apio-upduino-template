// Basic transmit-only UART module.
// "clock" is assumed to be the 48MHz internal HFOSC.
// "tx_data" is the next byte to transmit; tx_data_available is a flag
// indicating that the parent would like to transmit. "tx_ready" is high when
// ready to transmit. "serial_tx" should be the output pin for the UART.
// Captures the incoming byte on rising clock edge when tx_data_available is
// high.
module serial_transmitter(
        input logic clock,
        input logic reset,
        input logic [7:0] tx_data,
        input logic tx_data_available,
        output logic tx_ready,
        output logic serial_tx
    );

    // 48MHz (48000000) / 9600 
    localparam cycles_per_bit = 5000;

    logic [3:0] data_shift_buffer_remaining;
    logic [9:0] data_shift_buffer;

    assign tx_ready = data_shift_buffer_remaining == 4'b0;
    assign serial_tx = data_shift_buffer[0];

    logic [12:0] ticks_since_last_shift;
    always_ff @(posedge clock) begin
        ticks_since_last_shift <= ticks_since_last_shift + 1;

        data_shift_buffer <= data_shift_buffer;
        data_shift_buffer_remaining <= data_shift_buffer_remaining;

        if (reset) begin
            data_shift_buffer <= {10{ 1'b1 }};
            data_shift_buffer_remaining <= 0;
            ticks_since_last_shift <= 0;
        end else if (tx_data_available && tx_ready) begin
            data_shift_buffer <= { 1'b1, tx_data, 1'b0 };
            data_shift_buffer_remaining <= 10;
            ticks_since_last_shift <= 0;
        end else if (ticks_since_last_shift == cycles_per_bit - 1) begin
            ticks_since_last_shift <= 0;

            if (data_shift_buffer_remaining > 0) begin
                data_shift_buffer <= { 1'b1, data_shift_buffer[9:1] };
                data_shift_buffer_remaining <= data_shift_buffer_remaining - 1;
            end
        end
    end
endmodule
