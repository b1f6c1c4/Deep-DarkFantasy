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

   wire AXI_ARREADY;
   wire AXI_AWREADY;
   wire AXI_BVALID;
   wire AXI_RLAST;
   wire AXI_RVALID;
   wire AXI_WREADY;
   wire [1:0] AXI_BRESP;
   wire [1:0] AXI_RRESP;
   wire [5:0] AXI_BID;
   wire [5:0] AXI_RID;
   wire [63:0] AXI_RDATA;
   wire [7:0] AXI_RCOUNT;
   wire [7:0] AXI_WCOUNT;
   wire [2:0] AXI_RACOUNT;
   wire [5:0] AXI_WACOUNT;
   wire AXI_ACLK;
   wire AXI_ARVALID;
   wire AXI_AWVALID;
   wire AXI_BREADY;
   wire AXI_RDISSUECAP1_EN = 0;
   wire AXI_RREADY;
   wire AXI_WLAST;
   wire AXI_WRISSUECAP1_EN = 0;
   wire AXI_WVALID;
   wire [1:0] AXI_ARBURST;
   wire [1:0] AXI_ARLOCK;
   wire [2:0] AXI_ARSIZE;
   wire [1:0] AXI_AWBURST;
   wire [1:0] AXI_AWLOCK;
   wire [2:0] AXI_AWSIZE;
   wire [2:0] AXI_ARPROT;
   wire [2:0] AXI_AWPROT;
   wire [31:0] AXI_ARADDR;
   wire [31:0] AXI_AWADDR;
   wire [3:0] AXI_ARCACHE;
   wire [3:0] AXI_ARLEN;
   wire [3:0] AXI_ARQOS;
   wire [3:0] AXI_AWCACHE;
   wire [3:0] AXI_AWLEN;
   wire [3:0] AXI_AWQOS;
   wire [5:0] AXI_ARID;
   wire [5:0] AXI_AWID;
   wire [5:0] AXI_WID;
   wire [63:0] AXI_WDATA;
   wire [7:0] AXI_WSTRB;

   dark_fantasy #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV)
   ) i_dark (
      .clk_i (vin_clk),
      .rst_ni (rst_n),

      .sw_i (sw_i),
      .led_o (led_o),

      .hdmi_in_hpd_o (hdmi_in_hpd_o),
      .hdmi_out_hpd_i (hdmi_out_hpd_i),

      .vs_i (vin_vs),
      .hs_i (vin_hs),
      .de_i (vin_de),
      .data_i (vin_data),
      .data_o (vout_data),

      .M_AXI_ARREADY (AXI_ARREADY),
      .M_AXI_AWREADY (AXI_AWREADY),
      .M_AXI_BVALID (AXI_BVALID),
      .M_AXI_RLAST (AXI_RLAST),
      .M_AXI_RVALID (AXI_RVALID),
      .M_AXI_WREADY (AXI_WREADY),
      .M_AXI_BRESP (AXI_BRESP),
      .M_AXI_RRESP (AXI_RRESP),
      .M_AXI_RDATA (AXI_RDATA),
      .M_AXI_BID (AXI_BID),
      .M_AXI_RID (AXI_RID),
      .M_AXI_ACLK (AXI_ACLK),
      .M_AXI_ARVALID (AXI_ARVALID),
      .M_AXI_AWVALID (AXI_AWVALID),
      .M_AXI_BREADY (AXI_BREADY),
      .M_AXI_RREADY (AXI_RREADY),
      .M_AXI_WLAST (AXI_WLAST),
      .M_AXI_WVALID (AXI_WVALID),
      .M_AXI_ARBURST (AXI_ARBURST),
      .M_AXI_ARLOCK (AXI_ARLOCK),
      .M_AXI_ARSIZE (AXI_ARSIZE),
      .M_AXI_AWBURST (AXI_AWBURST),
      .M_AXI_AWLOCK (AXI_AWLOCK),
      .M_AXI_AWSIZE (AXI_AWSIZE),
      .M_AXI_ARPROT (AXI_ARPROT),
      .M_AXI_AWPROT (AXI_AWPROT),
      .M_AXI_ARADDR (AXI_ARADDR),
      .M_AXI_AWADDR (AXI_AWADDR),
      .M_AXI_WDATA (AXI_WDATA),
      .M_AXI_ARCACHE (AXI_ARCACHE),
      .M_AXI_ARLEN (AXI_ARLEN),
      .M_AXI_ARQOS (AXI_ARQOS),
      .M_AXI_AWCACHE (AXI_AWCACHE),
      .M_AXI_AWLEN (AXI_AWLEN),
      .M_AXI_AWQOS (AXI_AWQOS),
      .M_AXI_WSTRB (AXI_WSTRB),
      .M_AXI_ARID (AXI_ARID),
      .M_AXI_AWID (AXI_AWID),
      .M_AXI_WID (AXI_WID)
   );

   processing_system7_0 i_ps (
      .S_AXI_HP0_ARREADY (AXI_ARREADY),
      .S_AXI_HP0_AWREADY (AXI_AWREADY),
      .S_AXI_HP0_BVALID (AXI_BVALID),
      .S_AXI_HP0_RLAST (AXI_RLAST),
      .S_AXI_HP0_RVALID (AXI_RVALID),
      .S_AXI_HP0_WREADY (AXI_WREADY),
      .S_AXI_HP0_BRESP (AXI_BRESP),
      .S_AXI_HP0_RRESP (AXI_RRESP),
      .S_AXI_HP0_BID (AXI_BID),
      .S_AXI_HP0_RID (AXI_RID),
      .S_AXI_HP0_RDATA (AXI_RDATA),
      .S_AXI_HP0_RCOUNT (AXI_RCOUNT),
      .S_AXI_HP0_WCOUNT (AXI_WCOUNT),
      .S_AXI_HP0_RACOUNT (AXI_RACOUNT),
      .S_AXI_HP0_WACOUNT (AXI_WACOUNT),
      .S_AXI_HP0_ACLK (AXI_ACLK),
      .S_AXI_HP0_ARVALID (AXI_ARVALID),
      .S_AXI_HP0_AWVALID (AXI_AWVALID),
      .S_AXI_HP0_BREADY (AXI_BREADY),
      .S_AXI_HP0_RDISSUECAP1_EN (AXI_RDISSUECAP1_EN),
      .S_AXI_HP0_RREADY (AXI_RREADY),
      .S_AXI_HP0_WLAST (AXI_WLAST),
      .S_AXI_HP0_WRISSUECAP1_EN (AXI_WRISSUECAP1_EN),
      .S_AXI_HP0_WVALID (AXI_WVALID),
      .S_AXI_HP0_ARBURST (AXI_ARBURST),
      .S_AXI_HP0_ARLOCK (AXI_ARLOCK),
      .S_AXI_HP0_ARSIZE (AXI_ARSIZE),
      .S_AXI_HP0_AWBURST (AXI_AWBURST),
      .S_AXI_HP0_AWLOCK (AXI_AWLOCK),
      .S_AXI_HP0_AWSIZE (AXI_AWSIZE),
      .S_AXI_HP0_ARPROT (AXI_ARPROT),
      .S_AXI_HP0_AWPROT (AXI_AWPROT),
      .S_AXI_HP0_ARADDR (AXI_ARADDR),
      .S_AXI_HP0_AWADDR (AXI_AWADDR),
      .S_AXI_HP0_ARCACHE (AXI_ARCACHE),
      .S_AXI_HP0_ARLEN (AXI_ARLEN),
      .S_AXI_HP0_ARQOS (AXI_ARQOS),
      .S_AXI_HP0_AWCACHE (AXI_AWCACHE),
      .S_AXI_HP0_AWLEN (AXI_AWLEN),
      .S_AXI_HP0_AWQOS (AXI_AWQOS),
      .S_AXI_HP0_ARID (AXI_ARID),
      .S_AXI_HP0_AWID (AXI_AWID),
      .S_AXI_HP0_WID (AXI_WID),
      .S_AXI_HP0_WDATA (AXI_WDATA),
      .S_AXI_HP0_WSTRB (AXI_WSTRB),

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
