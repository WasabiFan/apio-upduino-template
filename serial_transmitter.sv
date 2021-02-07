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

    logic [12:0] clock_divider;
    always_ff @(posedge clock) begin
        clock_divider <= (clock_divider == (cycles_per_bit-1)) ? 0 : clock_divider + 1;

        if (reset) begin
            data_shift_buffer <= {10{ 1'b1 }};
            data_shift_buffer_remaining <= 0;
            clock_divider <= 0;
        end else if (clock_divider == 0) begin
            if (tx_data_available && tx_ready) begin
                data_shift_buffer <= { 1'b1, tx_data, 1'b0 };
                data_shift_buffer_remaining <= 10;
            end else begin
                data_shift_buffer <= { 1'b1, data_shift_buffer[9:1] };
                data_shift_buffer_remaining <= data_shift_buffer_remaining - 1;
            end
        end else begin
            data_shift_buffer <= data_shift_buffer;
            data_shift_buffer_remaining <= data_shift_buffer_remaining;
        end
    end
endmodule
