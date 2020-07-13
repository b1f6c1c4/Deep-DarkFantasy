module dark #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_T = 1400,
   parameter BASE = 32'h20000000
) (
   input clk_ref_i,
   input rst_ref_ni,

   input clk_i,
   input rst_ni,
   input ren_i,
   input wen_i,
   input [2:0] mode_i,
   output led_o,

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
   output [2:0] hdmi_out_data_p,

   input m_axi0_arready,
   input m_axi0_awready,
   input m_axi0_bvalid,
   input m_axi0_rlast,
   input m_axi0_rvalid,
   input m_axi0_wready,
   input [1:0] m_axi0_bresp,
   input [1:0] m_axi0_rresp,
   input [63:0] m_axi0_rdata,
   input [5:0] m_axi0_bid,
   input [5:0] m_axi0_rid,
   output m_axi0_aclk,
   output m_axi0_arvalid,
   output m_axi0_awvalid,
   output m_axi0_bready,
   output m_axi0_rready,
   output m_axi0_wlast,
   output m_axi0_wvalid,
   output [1:0] m_axi0_arburst,
   output [1:0] m_axi0_arlock,
   output [2:0] m_axi0_arsize,
   output [1:0] m_axi0_awburst,
   output [1:0] m_axi0_awlock,
   output [2:0] m_axi0_awsize,
   output [2:0] m_axi0_arprot,
   output [2:0] m_axi0_awprot,
   output [31:0] m_axi0_araddr,
   output [31:0] m_axi0_awaddr,
   output [63:0] m_axi0_wdata,
   output [3:0] m_axi0_arcache,
   output [3:0] m_axi0_arlen,
   output [3:0] m_axi0_arqos,
   output [3:0] m_axi0_awcache,
   output [3:0] m_axi0_awlen,
   output [3:0] m_axi0_awqos,
   output [7:0] m_axi0_wstrb,
   output [5:0] m_axi0_arid,
   output [5:0] m_axi0_awid,
   output [5:0] m_axi0_wid,

   input m_axi1_arready,
   input m_axi1_awready,
   input m_axi1_bvalid,
   input m_axi1_rlast,
   input m_axi1_rvalid,
   input m_axi1_wready,
   input [1:0] m_axi1_bresp,
   input [1:0] m_axi1_rresp,
   input [63:0] m_axi1_rdata,
   input [5:0] m_axi1_bid,
   input [5:0] m_axi1_rid,
   output m_axi1_aclk,
   output m_axi1_arvalid,
   output m_axi1_awvalid,
   output m_axi1_bready,
   output m_axi1_rready,
   output m_axi1_wlast,
   output m_axi1_wvalid,
   output [1:0] m_axi1_arburst,
   output [1:0] m_axi1_arlock,
   output [2:0] m_axi1_arsize,
   output [1:0] m_axi1_awburst,
   output [1:0] m_axi1_awlock,
   output [2:0] m_axi1_awsize,
   output [2:0] m_axi1_arprot,
   output [2:0] m_axi1_awprot,
   output [31:0] m_axi1_araddr,
   output [31:0] m_axi1_awaddr,
   output [63:0] m_axi1_wdata,
   output [3:0] m_axi1_arcache,
   output [3:0] m_axi1_arlen,
   output [3:0] m_axi1_arqos,
   output [3:0] m_axi1_awcache,
   output [3:0] m_axi1_awlen,
   output [3:0] m_axi1_awqos,
   output [7:0] m_axi1_wstrb,
   output [5:0] m_axi1_arid,
   output [5:0] m_axi1_awid,
   output [5:0] m_axi1_wid
);

   assign hdmi_in_hpd_o = hdmi_out_hpd_i;

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
      .RefClk(clk_ref_i),
      .aRst_n(rst_ref_ni),
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

   // LED monitor

   reg [31:0] vin_clk_c;
   always @(posedge vin_clk) begin
      vin_clk_c <= vin_clk_c + 1;
   end

   assign led_o = vin_clk_c[26];

   // HDMI out

   wire vout_hs, vout_vs, vout_de;
   wire [23:0] vout_data;
   rgb2dvi_1080p i_rgb2dvi (
      .PixelClk(vin_clk),
      .aRst_n(vin_rst_n),

      .TMDS_Clk_n(hdmi_out_clk_n),
      .TMDS_Clk_p(hdmi_out_clk_p),
      .TMDS_Data_n(hdmi_out_data_n),
      .TMDS_Data_p(hdmi_out_data_p),

      .vid_pData(vout_data),
      .vid_pHSync(vout_hs),
      .vid_pVDE(vout_de),
      .vid_pVSync(vout_vs)
   );

   // Process

   wire [23:0] mid_data, fan_data;

   fantasy #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV),
      .SMOOTH_T (SMOOTH_T)
   ) i_fantasy (
      .rst_ni (rst_ni),
      .mode_i (mode_i),

      .vin_clk_i (vin_clk),
      .vin_hs_i (vin_hs),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),
      .vin_data_i (vin_data),

      .vout_data_i (~ren_i ? vin_data : mid_data),
      .vout_hs_o (vout_hs),
      .vout_vs_o (vout_vs),
      .vout_de_o (vout_de),
      .vout_data_o (fan_data)
   );

   // Overlay

   overlay #(
      .H_WIDTH (H_WIDTH),
      .V_HEIGHT (V_HEIGHT)
   ) i_overlay (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .mode_i (mode_i),

      .vin_clk_i (vin_clk),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),

      .data_i (fan_data),
      .data_o (vout_data),

      .m_axi_arready (m_axi1_arready),
      .m_axi_awready (m_axi1_awready),
      .m_axi_bvalid (m_axi1_bvalid),
      .m_axi_rlast (m_axi1_rlast),
      .m_axi_rvalid (m_axi1_rvalid),
      .m_axi_wready (m_axi1_wready),
      .m_axi_bresp (m_axi1_bresp),
      .m_axi_rresp (m_axi1_rresp),
      .m_axi_bid (m_axi1_bid),
      .m_axi_rid (m_axi1_rid),
      .m_axi_rdata (m_axi1_rdata),
      .m_axi_aclk (m_axi1_aclk),
      .m_axi_arvalid (m_axi1_arvalid),
      .m_axi_awvalid (m_axi1_awvalid),
      .m_axi_bready (m_axi1_bready),
      .m_axi_rready (m_axi1_rready),
      .m_axi_wlast (m_axi1_wlast),
      .m_axi_wvalid (m_axi1_wvalid),
      .m_axi_arburst (m_axi1_arburst),
      .m_axi_arlock (m_axi1_arlock),
      .m_axi_arsize (m_axi1_arsize),
      .m_axi_awburst (m_axi1_awburst),
      .m_axi_awlock (m_axi1_awlock),
      .m_axi_awsize (m_axi1_awsize),
      .m_axi_arprot (m_axi1_arprot),
      .m_axi_awprot (m_axi1_awprot),
      .m_axi_araddr (m_axi1_araddr),
      .m_axi_awaddr (m_axi1_awaddr),
      .m_axi_arcache (m_axi1_arcache),
      .m_axi_arlen (m_axi1_arlen),
      .m_axi_arqos (m_axi1_arqos),
      .m_axi_awcache (m_axi1_awcache),
      .m_axi_awlen (m_axi1_awlen),
      .m_axi_awqos (m_axi1_awqos),
      .m_axi_arid (m_axi1_arid),
      .m_axi_awid (m_axi1_awid),
      .m_axi_wid (m_axi1_wid),
      .m_axi_wdata (m_axi1_wdata),
      .m_axi_wstrb (m_axi1_wstrb)
   );

   // Delayer

   axi_delayer #(
      .H_WIDTH (H_WIDTH),
      .V_HEIGHT (V_HEIGHT),
      .BASE (BASE)
   ) i_axi_delayer (
      .clk_i (vin_clk),
      .rst_ni (rst_ni),
      .ren_i (ren_i),
      .wen_i (wen_i),
      .vs_i (vin_vs),
      .de_i (vin_de),
      .data_i (vin_data),
      .data_o (mid_data),

      .m_axi_arready (m_axi0_arready),
      .m_axi_awready (m_axi0_awready),
      .m_axi_bvalid (m_axi0_bvalid),
      .m_axi_rlast (m_axi0_rlast),
      .m_axi_rvalid (m_axi0_rvalid),
      .m_axi_wready (m_axi0_wready),
      .m_axi_bresp (m_axi0_bresp),
      .m_axi_rresp (m_axi0_rresp),
      .m_axi_bid (m_axi0_bid),
      .m_axi_rid (m_axi0_rid),
      .m_axi_rdata (m_axi0_rdata),
      .m_axi_aclk (m_axi0_aclk),
      .m_axi_arvalid (m_axi0_arvalid),
      .m_axi_awvalid (m_axi0_awvalid),
      .m_axi_bready (m_axi0_bready),
      .m_axi_rready (m_axi0_rready),
      .m_axi_wlast (m_axi0_wlast),
      .m_axi_wvalid (m_axi0_wvalid),
      .m_axi_arburst (m_axi0_arburst),
      .m_axi_arlock (m_axi0_arlock),
      .m_axi_arsize (m_axi0_arsize),
      .m_axi_awburst (m_axi0_awburst),
      .m_axi_awlock (m_axi0_awlock),
      .m_axi_awsize (m_axi0_awsize),
      .m_axi_arprot (m_axi0_arprot),
      .m_axi_awprot (m_axi0_awprot),
      .m_axi_araddr (m_axi0_araddr),
      .m_axi_awaddr (m_axi0_awaddr),
      .m_axi_arcache (m_axi0_arcache),
      .m_axi_arlen (m_axi0_arlen),
      .m_axi_arqos (m_axi0_arqos),
      .m_axi_awcache (m_axi0_awcache),
      .m_axi_awlen (m_axi0_awlen),
      .m_axi_awqos (m_axi0_awqos),
      .m_axi_arid (m_axi0_arid),
      .m_axi_awid (m_axi0_awid),
      .m_axi_wid (m_axi0_wid),
      .m_axi_wdata (m_axi0_wdata),
      .m_axi_wstrb (m_axi0_wstrb)
   );

endmodule
