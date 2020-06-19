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

   inout [53:0] MIO,
   inout DDR_CAS_n,
   inout DDR_CKE,
   inout DDR_Clk_n,
   inout DDR_Clk,
   inout DDR_CS_n,
   inout DDR_DRSTB,
   inout DDR_ODT,
   inout DDR_RAS_n,
   inout DDR_WEB,
   inout [2:0] DDR_BankAddr,
   inout [14:0] DDR_Addr,
   inout DDR_VRN,
   inout DDR_VRP,
   inout [3:0] DDR_DM,
   inout [31:0] DDR_DQ,
   inout [3:0] DDR_DQS_n,
   inout [3:0] DDR_DQS,
   inout PS_SRSTB,
   inout PS_CLK,
   inout PS_PORB
);

   wire clk_ref, rst_ref_n; // 200MHz
   ref_pll i_ref_pll (
      .resetn(1'b1),
      .clk_in1(clk_i),
      .clk_out1(clk_ref),
      .locked(rst_ref_n)
   );

   wire rst_n = ~button_i[0];

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

   wire [23:0] mid_data;

   fantasy #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV)
   ) i_fantasy (
      .sw_i (sw_i),
      .led_o (led_o),

      .vin_hpd_o (hdmi_in_hpd_o),
      .vin_clk_i (vin_clk),
      .vin_hs_i (vin_hs),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),
      .vin_data_i (vin_data),

      .vout_hpd_i (hdmi_out_hpd_i),
      .vout_clk_i (vin_clk),
      .vout_hs_i (vin_hs),
      .vout_vs_i (vin_vs),
      .vout_de_i (vin_de),
      .vout_data_i (mid_data),
      .vout_data_o (vout_data)
   );

   // Memory

   wire axi_arready;
   wire axi_awready;
   wire axi_bvalid;
   wire axi_rlast;
   wire axi_rvalid;
   wire axi_wready;
   wire [1:0] axi_bresp;
   wire [1:0] axi_rresp;
   wire [5:0] axi_bid;
   wire [5:0] axi_rid;
   wire [31:0] axi_rdata;
   wire [7:0] axi_rcount;
   wire [7:0] axi_wcount;
   wire [2:0] axi_racount;
   wire [5:0] axi_wacount;
   wire axi_aclk;
   wire axi_arvalid;
   wire axi_awvalid;
   wire axi_bready;
   wire axi_rdissuecap1_en = 0;
   wire axi_rready;
   wire axi_wlast;
   wire axi_wrissuecap1_en = 0;
   wire axi_wvalid;
   wire [1:0] axi_arburst;
   wire [1:0] axi_arlock;
   wire [2:0] axi_arsize;
   wire [1:0] axi_awburst;
   wire [1:0] axi_awlock;
   wire [2:0] axi_awsize;
   wire [2:0] axi_arprot;
   wire [2:0] axi_awprot;
   wire [31:0] axi_araddr;
   wire [31:0] axi_awaddr;
   wire [3:0] axi_arcache;
   wire [3:0] axi_arlen;
   wire [3:0] axi_arqos;
   wire [3:0] axi_awcache;
   wire [3:0] axi_awlen;
   wire [3:0] axi_awqos;
   wire [5:0] axi_arid;
   wire [5:0] axi_awid;
   wire [5:0] axi_wid;
   wire [31:0] axi_wdata;
   wire [3:0] axi_wstrb;

   axi_delayer #(
      .H_WIDTH (H_WIDTH),
      .V_HEIGHT (V_HEIGHT)
   ) i_axi_delayer (
      .clk_i (vin_clk),
      .rst_ni (rst_n),
      .vs_i (vin_vs),
      .de_i (vin_de),
      .data_i (vin_data),
      .data_o (mid_data),

      .m_axi_arready (axi_arready),
      .m_axi_awready (axi_awready),
      .m_axi_bvalid (axi_bvalid),
      .m_axi_rlast (axi_rlast),
      .m_axi_rvalid (axi_rvalid),
      .m_axi_wready (axi_wready),
      .m_axi_bresp (axi_bresp),
      .m_axi_rresp (axi_rresp),
      .m_axi_bid (axi_bid),
      .m_axi_rid (axi_rid),
      .m_axi_rdata (axi_rdata),
      // .m_axi_rcount (axi_rcount),
      // .m_axi_wcount (axi_wcount),
      // .m_axi_racount (axi_racount),
      // .m_axi_wacount (axi_wacount),
      .m_axi_aclk (axi_aclk),
      .m_axi_arvalid (axi_arvalid),
      .m_axi_awvalid (axi_awvalid),
      .m_axi_bready (axi_bready),
      // .m_axi_rdissuecap1_en (axi_rdissuecap1_en),
      .m_axi_rready (axi_rready),
      .m_axi_wlast (axi_wlast),
      // .m_axi_wrissuecap1_en (axi_wrissuecap1_en),
      .m_axi_wvalid (axi_wvalid),
      .m_axi_arburst (axi_arburst),
      .m_axi_arlock (axi_arlock),
      .m_axi_arsize (axi_arsize),
      .m_axi_awburst (axi_awburst),
      .m_axi_awlock (axi_awlock),
      .m_axi_awsize (axi_awsize),
      .m_axi_arprot (axi_arprot),
      .m_axi_awprot (axi_awprot),
      .m_axi_araddr (axi_araddr),
      .m_axi_awaddr (axi_awaddr),
      .m_axi_arcache (axi_arcache),
      .m_axi_arlen (axi_arlen),
      .m_axi_arqos (axi_arqos),
      .m_axi_awcache (axi_awcache),
      .m_axi_awlen (axi_awlen),
      .m_axi_awqos (axi_awqos),
      .m_axi_arid (axi_arid),
      .m_axi_awid (axi_awid),
      .m_axi_wid (axi_wid),
      .m_axi_wdata (axi_wdata),
      .m_axi_wstrb (axi_wstrb)
   );

   processing_system7_0 i_ps (
      .S_AXI_HP0_ARREADY (axi_arready),
      .S_AXI_HP0_AWREADY (axi_awready),
      .S_AXI_HP0_BVALID (axi_bvalid),
      .S_AXI_HP0_RLAST (axi_rlast),
      .S_AXI_HP0_RVALID (axi_rvalid),
      .S_AXI_HP0_WREADY (axi_wready),
      .S_AXI_HP0_BRESP (axi_bresp),
      .S_AXI_HP0_RRESP (axi_rresp),
      .S_AXI_HP0_BID (axi_bid),
      .S_AXI_HP0_RID (axi_rid),
      .S_AXI_HP0_RDATA (axi_rdata),
      .S_AXI_HP0_RCOUNT (axi_rcount),
      .S_AXI_HP0_WCOUNT (axi_wcount),
      .S_AXI_HP0_RACOUNT (axi_racount),
      .S_AXI_HP0_WACOUNT (axi_wacount),
      .S_AXI_HP0_ACLK (axi_aclk),
      .S_AXI_HP0_ARVALID (axi_arvalid),
      .S_AXI_HP0_AWVALID (axi_awvalid),
      .S_AXI_HP0_BREADY (axi_bready),
      .S_AXI_HP0_RDISSUECAP1_EN (axi_rdissuecap1_en),
      .S_AXI_HP0_RREADY (axi_rready),
      .S_AXI_HP0_WLAST (axi_wlast),
      .S_AXI_HP0_WRISSUECAP1_EN (axi_wrissuecap1_en),
      .S_AXI_HP0_WVALID (axi_wvalid),
      .S_AXI_HP0_ARBURST (axi_arburst),
      .S_AXI_HP0_ARLOCK (axi_arlock),
      .S_AXI_HP0_ARSIZE (axi_arsize),
      .S_AXI_HP0_AWBURST (axi_awburst),
      .S_AXI_HP0_AWLOCK (axi_awlock),
      .S_AXI_HP0_AWSIZE (axi_awsize),
      .S_AXI_HP0_ARPROT (axi_arprot),
      .S_AXI_HP0_AWPROT (axi_awprot),
      .S_AXI_HP0_ARADDR (axi_araddr),
      .S_AXI_HP0_AWADDR (axi_awaddr),
      .S_AXI_HP0_ARCACHE (axi_arcache),
      .S_AXI_HP0_ARLEN (axi_arlen),
      .S_AXI_HP0_ARQOS (axi_arqos),
      .S_AXI_HP0_AWCACHE (axi_awcache),
      .S_AXI_HP0_AWLEN (axi_awlen),
      .S_AXI_HP0_AWQOS (axi_awqos),
      .S_AXI_HP0_ARID (axi_arid),
      .S_AXI_HP0_AWID (axi_awid),
      .S_AXI_HP0_WID (axi_wid),
      .S_AXI_HP0_WDATA (axi_wdata),
      .S_AXI_HP0_WSTRB (axi_wstrb),

      .MIO (MIO),
      .DDR_CAS_n (DDR_CAS_n),
      .DDR_CKE (DDR_CKE),
      .DDR_Clk_n (DDR_Clk_n),
      .DDR_Clk (DDR_Clk),
      .DDR_CS_n (DDR_CS_n),
      .DDR_DRSTB (DDR_DRSTB),
      .DDR_ODT (DDR_ODT),
      .DDR_RAS_n (DDR_RAS_n),
      .DDR_WEB (DDR_WEB),
      .DDR_BankAddr (DDR_BankAddr),
      .DDR_Addr (DDR_Addr),
      .DDR_VRN (DDR_VRN),
      .DDR_VRP (DDR_VRP),
      .DDR_DM (DDR_DM),
      .DDR_DQ (DDR_DQ),
      .DDR_DQS_n (DDR_DQS_n),
      .DDR_DQS (DDR_DQS),
      .PS_SRSTB (PS_SRSTB),
      .PS_CLK (PS_CLK),
      .PS_PORB (PS_PORB)
   );

endmodule
