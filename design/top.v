module top(
   input clk_i_p,
   input clk_i_n,
   output [3:0] led_o,
   input [3:0] button_ni,

   // HDMI in
   inout vout_scl_io,
   inout vout_sda_io,
   output vout_clk_o,
   output reg vout_de_o,
   output reg vout_hs_o,
   output reg vout_vs_o,
   output reg [23:0] vout_data_o,

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

   wire rst_n = button_ni[0];

   assign fan_no = 0;

   wire clk_video; // 148.571MHz
   wire clk_i2c; // 100MHz
   wire pll_locked;
   sys_pll i_sys_pll (
      .clk_in1_p (clk_i_p),
      .clk_in1_n (clk_i_n),
      .reset (~rst_n),
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
   assign vin_rst_no = rst_n;
   sil9013 i_sil9013 (
      .clk_i (clk_i2c),
      .rst_ni (rst_n),
      .vin_scl_io,
      .vin_sda_io
   );
   reg vin_hs, vin_vs, vin_de;
   reg [23:0] vin_data;
   always @(posedge vin_clk_i) begin
      vin_hs <= vin_hs_i;
      vin_vs <= vin_vs_i;
      vin_de <= vin_de_i;
      vin_data <= vin_data_i;
   end

   // HDMI out
   adv7511 i_adv7511 (
      .clk_i (clk_i2c),
      .rst_ni (rst_n),
      .vout_scl_io,
      .vout_sda_io
   );
   always @(posedge vin_clk_i) begin
      vout_hs_o <= vout_hs;
      vout_vs_o <= vout_vs;
      vout_de_o <= vout_de;
      vout_data_o <= vout_data;
   end

   // HDMI middle buffer
   assign vout_clk_o = vin_clk_i;
   reg vout_hs, vout_vs, vout_de;
   reg [23:0] vout_data;
   always @(posedge vin_clk_i) begin
      vout_hs <= vin_hs;
      vout_vs <= vin_vs;
      vout_de <= vin_de;
      vout_data <= vin_data;
   end

endmodule
