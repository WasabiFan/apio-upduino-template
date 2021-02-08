module top (
  input wire gpio_2,
  output wire led_red,
  output wire led_blue,
  output wire led_green,
  output wire spi_cs,
  output wire serial_txd
);
    // Explicitly disable the SPI flash since it shares data lines with UART
    assign spi_cs = 1'b1;

    // Use GPIO pin 2 as reset. Tie to ground for reset. "reset" here is active-high.
    logic reset;
    assign reset = ~gpio_2;

    logic  int_osc;
    logic  [27:0] frequency_counter_i;

    // Internal oscillator
    /* verilator lint_off PINMISSING */
    SB_HFOSC u_SB_HFOSC (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(int_osc));
    /* verilator lint_on PINMISSING */

    // Serial transmitter
    logic [7:0] serial_tx_data;
    logic serial_tx_data_available, serial_tx_ready;
    serial_transmitter serial_out (
      .clock                (int_osc),
      .reset                (reset),
      .tx_data              (serial_tx_data),
      .tx_data_available    (serial_tx_data_available),
      .tx_ready             (serial_tx_ready),
      .serial_tx            (serial_txd)
    );

    // Dummy data to demonstrate serial transmission
    `define text "Hello world!\r\n"
    logic [$bits(`text)-1:0] serial_string_buf;
    localparam text_len = $bits(serial_string_buf);
    logic last_serial_tx_ready;

    assign serial_tx_data_available = 1'b1;
    assign serial_tx_data = serial_string_buf[text_len-1:text_len-8];

    always_ff @(posedge int_osc) begin
      if (reset) begin
        serial_string_buf <= `text;
        last_serial_tx_ready <= 1'b0;
      end else if (serial_tx_ready && !last_serial_tx_ready) begin
        serial_string_buf <= { serial_string_buf[text_len-8-1:0], serial_string_buf[text_len-1:text_len-8] };
        last_serial_tx_ready <= serial_tx_ready;
      end else begin
        serial_string_buf <= serial_string_buf;
        last_serial_tx_ready <= serial_tx_ready;
      end
    end

    // Counter for LED pattern
    always @(posedge int_osc) begin
      frequency_counter_i <= frequency_counter_i + 1'b1;
    end

    // LED driver
    SB_RGBA_DRV RGB_DRIVER (
      .RGBLEDEN(1'b1                                            ),
      .RGB0PWM (frequency_counter_i[25]&frequency_counter_i[24] ),
      .RGB1PWM (frequency_counter_i[25]&~frequency_counter_i[24]),
      // red LED tied to "reset" to indicate when you're triggering reset
      .RGB2PWM (reset                                           ),
      .CURREN  (1'b1                                            ),
      .RGB0    (led_green                                       ),
      .RGB1    (led_blue                                        ),
      .RGB2    (led_red                                         )
    );
    defparam RGB_DRIVER.RGB0_CURRENT = "0b000001";
    defparam RGB_DRIVER.RGB1_CURRENT = "0b000001";
    defparam RGB_DRIVER.RGB2_CURRENT = "0b000001";
endmodule
