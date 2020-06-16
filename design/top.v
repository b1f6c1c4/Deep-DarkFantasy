module top #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input clk_i,

   input [3:0] sw_i,
   input [3:0] button_i,

   output [3:0] led_o,
   output [2:0] led5_o,
   output [2:0] led6_o,

   output hdmi_in_hpd_o,
   inout hdmi_in_ddc_scl_io,
   inout hdmi_in_ddc_sda_io,
   input hdmi_in_clk_n,
   input hdmi_in_clk_p,
   input [2:0] hdmi_in_data_n,
   input [2:0] hdmi_in_data_p,

   input hdmi_out_hpd_i,
   output hdmi_out_clk_n,
   output hdmi_out_clk_p,
   output [2:0] hdmi_out_data_n,
   output [2:0] hdmi_out_data_p
);

   wire clk_ref, rst_ref_n; // 200MHz
   ref_pll i_ref_pll (
      .resetn(1'b1),
      .clk_in1(clk_i),
      .clk_out1(clk_ref),
      .locked(rst_ref_n)
   );

   assign hdmi_in_hpd_o = sw_i[3] || hdmi_out_hpd_i;

   // HDMI in

   wire hdmi_in_ddc_scl_i, hdmi_in_ddc_scl_o, hdmi_in_ddc_scl_t;
   wire hdmi_in_ddc_sda_i, hdmi_in_ddc_sda_o, hdmi_in_ddc_sda_t;
   IOBUF i_hdmi_in_ddc_scl_iobuf (
      .IO(hdmi_in_ddc_scl_io),
      .I(hdmi_in_ddc_scl_o),
      .O(hdmi_in_ddc_scl_i),
      .T(hdmi_in_ddc_scl_t)
   );
   IOBUF i_hdmi_in_ddc_sda_iobuf (
      .IO(hdmi_in_ddc_sda_io),
      .I(hdmi_in_ddc_sda_o),
      .O(hdmi_in_ddc_sda_i),
      .T(hdmi_in_ddc_sda_t)
   );

   wire vin_clk, vin_rst_n;
   wire vin_hs, vin_vs, vin_de;
   wire [23:0] vin_data;
   dvi2rgb_1080p i_dvi2rgb (
      .RefClk(clk_ref),
      .aRst_n(rst_ref_n),
      .pRst_n(1'b1),
      .PixelClk(vin_clk),
      .aPixelClkLckd(), // DEPRECATED
      .pLocked(vin_rst_n),

      .TMDS_Clk_n(hdmi_in_clk_n),
      .TMDS_Clk_p(hdmi_in_clk_p),
      .TMDS_Data_n(hdmi_in_data_n),
      .TMDS_Data_p(hdmi_in_data_p),

      .SCL_I(hdmi_in_ddc_scl_i),
      .SCL_O(hdmi_in_ddc_scl_o),
      .SCL_T(hdmi_in_ddc_scl_t),
      .SDA_I(hdmi_in_ddc_sda_i),
      .SDA_O(hdmi_in_ddc_sda_o),
      .SDA_T(hdmi_in_ddc_sda_t),

      .vid_pData(vin_data),
      .vid_pHSync(vin_hs),
      .vid_pVSync(vin_vs),
      .vid_pVDE(vin_de)
   );

   // HDMI out

   wire [23:0] vout_data;
   rgb2dvi_1080p i_rgb2dvi (
      .PixelClk(vin_clk),
      .aRst_n(vin_rst_n),

      .TMDS_Clk_n(hdmi_out_clk_n),
      .TMDS_Clk_p(hdmi_out_clk_p),
      .TMDS_Data_n(hdmi_out_data_n),
      .TMDS_Data_p(hdmi_out_data_p),

      .vid_pData(vout_data),
      .vid_pHSync(vin_hs),
      .vid_pVDE(vin_de),
      .vid_pVSync(vin_vs)
   );

   // Process

   fantasy #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV)
   ) i_fantasy (
      .button_ni (~button_i),
      .led_o (led_o),

      .vin_clk_i (vin_clk),
      .vin_hs_i (vin_hs),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),
      .vin_data_i (vin_data),

      .vout_clk_i (vin_clk),
      .vout_hs_i (vin_hs),
      .vout_vs_i (vin_vs),
      .vout_de_i (vin_de),
      .vout_data_i (vin_data),
      .vout_data_o (vout_data)
   );

endmodule
