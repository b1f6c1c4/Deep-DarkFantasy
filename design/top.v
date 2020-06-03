module top(
   input clk_i_p,
   input clk_i_n,
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

   assign fan_no = 0;

   wire clk_video; // 148.571MHz
   wire clk_i2c; // 100MHz
   wire pll_locked;
   sys_pll i_sys_pll (
      .clk_in1_p (clk_i_p),
      .clk_in1_n (clk_i_n),
      .clk_out1 (clk_video),
      .clk_out2 (clk_i2c),
      .locked (pll_locked)
   );

   reg a;
   reg [31:0] counter_a;
   always @(posedge clk_video) begin
      if (counter_a == 32'd99999999) begin
         counter_a <= 32'd0;
         a <= ~a;
      end else begin
         counter_a <= counter_a + 32'd1;
         a <= a;
      end
   end

   reg b;
   reg [31:0] counter_b;
   always @(posedge clk_i2c) begin
      if (counter_b == 32'd99999999) begin
         counter_b <= 32'd0;
         b <= ~b;
      end else begin
         counter_b <= counter_b + 32'd1;
         b <= b;
      end
   end

   assign led_o[0] = a;
   assign led_o[1] = ~a;
   assign led_o[2] = b;
   assign led_o[3] = ~b;

   // HDMI in
   assign vout_de_o = 0;
   assign vout_hs_o = 0;
   assign vout_vs_o = 0;
   assign vout_data_o = 24'b0;

   // HDMI out
   assign vin_rst_no = 1;

endmodule
