module rgb_blink_tb();
    initial begin
       $dumpfile("rgb_blink_tb.vcd");
       $dumpvars(0,rgb_blink_tb);
    end

  wire led_red, led_green, led_blue;

  rgb_blink top (
      .led_red(led_red),
      .led_green(led_green),
      .led_blue(led_blue)
  );
endmodule
