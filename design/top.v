module top (
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
   inout hdmi_out_ddc_scl_io,
   inout hdmi_out_ddc_sda_io,
   output hdmi_out_clk_n,
   output hdmi_out_clk_p,
   output [2:0] hdmi_out_data_n,
   output [2:0] hdmi_out_data_p
);

   assign hdmi_in_hpd_o = hdmi_out_hpd_i;

   wire hdmi_in_clk;
   wire [2:0] hdmi_in_data;
   IBUFDS #(
      .DIFF_TERM("FALSE"),
      .IBUF_LOW_PWR("FALSE"),
      .IOSTANDARD("TMDS_33")
   ) hdmi_in_clk_ibuf (
      .I(hdmi_in_clk_p),
      .IB(hdmi_in_clk_n),
      .O(hdmi_in_clk)
   );
   IBUFDS #(
      .DIFF_TERM("FALSE"),
      .IBUF_LOW_PWR("FALSE"),
      .IOSTANDARD("TMDS_33")
   ) hdmi_in_data_ibuf[2:0] (
      .I(hdmi_in_data_p),
      .IB(hdmi_in_data_n),
      .O(hdmi_in_data)
   );

   wire hdmi_out_clk = hdmi_in_clk;
   wire [2:0] hdmi_out_data = hdmi_in_data ^ sw_i[2:0];
   OBUFDS #(
      .IOSTANDARD("TMDS_33"),
      .SLEW("FAST")
   ) hdmi_out_clk_obuf (
      .I(hdmi_out_clk),
      .O(hdmi_out_clk_p),
      .OB(hdmi_out_clk_n)
   );
   OBUFDS #(
      .IOSTANDARD("TMDS_33"),
      .SLEW("FAST")
   ) hdmi_out_data_obuf[2:0] (
      .I(hdmi_out_data),
      .O(hdmi_out_data_p),
      .OB(hdmi_out_data_n)
   );

   // wire hdmi_in_ddc_scl_i, hdmi_in_ddc_scl_o, hdmi_in_ddc_scl_t;
   // wire hdmi_in_ddc_sda_i, hdmi_in_ddc_sda_o, hdmi_in_ddc_sda_t;
   // wire hdmi_out_ddc_scl_i, hdmi_out_ddc_scl_o, hdmi_out_ddc_scl_t;
   // wire hdmi_out_ddc_sda_i, hdmi_out_ddc_sda_o, hdmi_out_ddc_sda_t;
   // IOBUF hdmi_in_ddc_scl_iobuf (
   //    .IO(hdmi_in_ddc_scl_io),
   //    .I(hdmi_in_ddc_scl_o),
   //    .O(hdmi_in_ddc_scl_i),
   //    .T(hdmi_in_ddc_scl_t)
   // );
   // IOBUF hdmi_in_ddc_sda_iobuf (
   //    .IO(hdmi_in_ddc_sda_io),
   //    .I(hdmi_in_ddc_sda_o),
   //    .O(hdmi_in_ddc_sda_i),
   //    .T(hdmi_in_ddc_sda_t)
   // );
   // IOBUF hdmi_out_ddc_scl_iobuf (
   //    .IO(hdmi_out_ddc_scl_io),
   //    .I(hdmi_out_ddc_scl_o),
   //    .O(hdmi_out_ddc_scl_i),
   //    .T(hdmi_out_ddc_scl_t)
   // );
   // IOBUF hdmi_out_ddc_sda_iobuf (
   //    .IO(hdmi_out_ddc_sda_io),
   //    .I(hdmi_out_ddc_sda_o),
   //    .O(hdmi_out_ddc_sda_i),
   //    .T(hdmi_out_ddc_sda_t)
   // );

endmodule
