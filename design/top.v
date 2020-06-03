module top(
   input clk_i_p,
   input rst_ni,
   output [3:0] led_o,
   input [3:0] button_ni,

   // HDMI in
   inout vout_scl_io,
   inout vout_sda_io,
   output vout_clk_o,
   output vout_de_o,
   output vout_hs_o,
   output vout_vs_o,
   output [23:0] vout_data_o,

   // HDMI out
   inout vin_scl_io,
   inout vin_sda_io,
   input vin_clk_i,
   output vin_rst_no,
   input vin_de_i,
   input vin_hs_i,
   input vin_vs_i,
   input [23:0] vin_data_i,

   output fan_no
);

   assign led_o = button_ni;
   assign fan_no = 0;

   // HDMI in
   assign vout_de_o = 0;
   assign vout_hs_o = 0;
   assign vout_vs_o = 0;
   assign vout_data_o = 24'b0;

   // HDMI out
   assign vin_rst_no = 1;

endmodule
