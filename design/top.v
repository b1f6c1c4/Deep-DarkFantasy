module top(
   input clk_i_p,
   input clk_i_n,
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

   wire rst_ni = button_ni[0];

   assign fan_no = 0;

   wire clk_video; // 148.571MHz
   wire clk_i2c; // 100MHz
   wire pll_locked;
   sys_pll i_sys_pll (
      .clk_in1_p (clk_i_p),
      .clk_in1_n (clk_i_n),
      .reset (~rst_ni),
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
   assign vin_rst_no = 1;
   sil9013 i_sil9013 (
      .clk_i (clk_i2c),
      .rst_ni,
      .vin_scl_io,
      .vin_sda_io
   );

   // HDMI out
   assign vout_clk_o = vin_clk_i;
   assign vout_hs_o = vin_hs_i;
   assign vout_vs_o = vin_vs_i;
   assign vout_de_o = vin_de_i;
   assign vout_data_o = vin_data_i;
   adv7511 i_adv7511 (
      .clk_i (clk_i2c),
      .rst_ni,
      .vout_scl_io,
      .vout_sda_io
   );

endmodule
