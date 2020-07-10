module top #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_T = 1400
) (
   input clk_i,

   input [3:0] sw_i,
   input [3:0] button_i,
   input [2:0] rot_ni,

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

   wire rst_n = ~button_i[3];

   wire [2:0] fantasy_mode;
   rotary #(
      .N (8),
      .SAT (1),
      .INIT (3),
      .T (3)
   ) i_rotary (
      .clk_i (clk_i),
      .rst_ni (rst_n),
      .rot_ni (rot_ni),
      .zero_i (button_i[0]),
      .inc_i (button_i[1]),
      .dec_i (button_i[2]),
      .counter_o (fantasy_mode)
   );

   assign hdmi_in_hpd_o = hdmi_out_hpd_i || sw_i[3];

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

   // LED monitor

   reg [31:0] vin_clk_c;
   always @(posedge vin_clk) begin
      vin_clk_c <= vin_clk_c + 1;
   end

   assign led_o[0] = fantasy_mode[0];
   assign led_o[1] = fantasy_mode[1];
   assign led_o[2] = fantasy_mode[2];
   assign led_o[3] = vin_clk_c[26];

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

   wire AXI0_ARREADY, AXI1_ARREADY;
   wire AXI0_AWREADY, AXI1_AWREADY;
   wire AXI0_BVALID, AXI1_BVALID;
   wire AXI0_RLAST, AXI1_RLAST;
   wire AXI0_RVALID, AXI1_RVALID;
   wire AXI0_WREADY, AXI1_WREADY;
   wire [1:0] AXI0_BRESP, AXI1_BRESP;
   wire [1:0] AXI0_RRESP, AXI1_RRESP;
   wire [5:0] AXI0_BID, AXI1_BID;
   wire [5:0] AXI0_RID, AXI1_RID;
   wire [63:0] AXI0_RDATA, AXI1_RDATA;
   wire [7:0] AXI0_RCOUNT, AXI1_RCOUNT;
   wire [7:0] AXI0_WCOUNT, AXI1_WCOUNT;
   wire [2:0] AXI0_RACOUNT, AXI1_RACOUNT;
   wire [5:0] AXI0_WACOUNT, AXI1_WACOUNT;
   wire AXI0_ACLK, AXI1_ACLK;
   wire AXI0_ARVALID, AXI1_ARVALID;
   wire AXI0_AWVALID, AXI1_AWVALID;
   wire AXI0_BREADY, AXI1_BREADY;
   wire AXI0_RDISSUECAP1_EN, AXI1_RDISSUECAP1_EN;
   wire AXI0_RREADY, AXI1_RREADY;
   wire AXI0_WLAST, AXI1_WLAST;
   wire AXI0_WRISSUECAP1_EN, AXI1_WRISSUECAP1_EN;
   wire AXI0_WVALID, AXI1_WVALID;
   wire [1:0] AXI0_ARBURST, AXI1_ARBURST;
   wire [1:0] AXI0_ARLOCK, AXI1_ARLOCK;
   wire [2:0] AXI0_ARSIZE, AXI1_ARSIZE;
   wire [1:0] AXI0_AWBURST, AXI1_AWBURST;
   wire [1:0] AXI0_AWLOCK, AXI1_AWLOCK;
   wire [2:0] AXI0_AWSIZE, AXI1_AWSIZE;
   wire [2:0] AXI0_ARPROT, AXI1_ARPROT;
   wire [2:0] AXI0_AWPROT, AXI1_AWPROT;
   wire [31:0] AXI0_ARADDR, AXI1_ARADDR;
   wire [31:0] AXI0_AWADDR, AXI1_AWADDR;
   wire [3:0] AXI0_ARCACHE, AXI1_ARCACHE;
   wire [3:0] AXI0_ARLEN, AXI1_ARLEN;
   wire [3:0] AXI0_ARQOS, AXI1_ARQOS;
   wire [3:0] AXI0_AWCACHE, AXI1_AWCACHE;
   wire [3:0] AXI0_AWLEN, AXI1_AWLEN;
   wire [3:0] AXI0_AWQOS, AXI1_AWQOS;
   wire [5:0] AXI0_ARID, AXI1_ARID;
   wire [5:0] AXI0_AWID, AXI1_AWID;
   wire [5:0] AXI0_WID, AXI1_WID;
   wire [63:0] AXI0_WDATA, AXI1_WDATA;
   wire [7:0] AXI0_WSTRB, AXI1_WSTRB;

   assign AXI0_RDISSUECAP1_EN = 0;
   assign AXI1_RDISSUECAP1_EN = 0;
   assign AXI0_WRISSUECAP1_EN = 0;
   assign AXI1_WRISSUECAP1_EN = 0;

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
      .rst_ni (rst_n),
      .mode_i (fantasy_mode),

      .vin_clk_i (vin_clk),
      .vin_hs_i (vin_hs),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),
      .vin_data_i (vin_data),

      .vout_data_i (sw_i[2] ? vin_data : mid_data),
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
      .rst_ni (rst_n),
      .mode_i (fantasy_mode),

      .vin_clk_i (vin_clk),
      .vin_vs_i (vin_vs),
      .vin_de_i (vin_de),

      .data_i (fan_data),
      .data_o (vout_data),

      .m_axi_arready (AXI1_ARREADY),
      .m_axi_awready (AXI1_AWREADY),
      .m_axi_bvalid (AXI1_BVALID),
      .m_axi_rlast (AXI1_RLAST),
      .m_axi_rvalid (AXI1_RVALID),
      .m_axi_wready (AXI1_WREADY),
      .m_axi_bresp (AXI1_BRESP),
      .m_axi_rresp (AXI1_RRESP),
      .m_axi_bid (AXI1_BID),
      .m_axi_rid (AXI1_RID),
      .m_axi_rdata (AXI1_RDATA),
      .m_axi_aclk (AXI1_ACLK),
      .m_axi_arvalid (AXI1_ARVALID),
      .m_axi_awvalid (AXI1_AWVALID),
      .m_axi_bready (AXI1_BREADY),
      .m_axi_rready (AXI1_RREADY),
      .m_axi_wlast (AXI1_WLAST),
      .m_axi_wvalid (AXI1_WVALID),
      .m_axi_arburst (AXI1_ARBURST),
      .m_axi_arlock (AXI1_ARLOCK),
      .m_axi_arsize (AXI1_ARSIZE),
      .m_axi_awburst (AXI1_AWBURST),
      .m_axi_awlock (AXI1_AWLOCK),
      .m_axi_awsize (AXI1_AWSIZE),
      .m_axi_arprot (AXI1_ARPROT),
      .m_axi_awprot (AXI1_AWPROT),
      .m_axi_araddr (AXI1_ARADDR),
      .m_axi_awaddr (AXI1_AWADDR),
      .m_axi_arcache (AXI1_ARCACHE),
      .m_axi_arlen (AXI1_ARLEN),
      .m_axi_arqos (AXI1_ARQOS),
      .m_axi_awcache (AXI1_AWCACHE),
      .m_axi_awlen (AXI1_AWLEN),
      .m_axi_awqos (AXI1_AWQOS),
      .m_axi_arid (AXI1_ARID),
      .m_axi_awid (AXI1_AWID),
      .m_axi_wid (AXI1_WID),
      .m_axi_wdata (AXI1_WDATA),
      .m_axi_wstrb (AXI1_WSTRB)
   );

   // Delayer

   axi_delayer #(
      .H_WIDTH (H_WIDTH),
      .V_HEIGHT (V_HEIGHT)
   ) i_axi_delayer (
      .clk_i (vin_clk),
      .rst_ni (rst_n),
      .ren_i (~sw_i[2]),
      .wen_i (~sw_i[3]),
      .vs_i (vin_vs),
      .de_i (vin_de),
      .data_i (vin_data),
      .data_o (mid_data),

      .m_axi_arready (AXI0_ARREADY),
      .m_axi_awready (AXI0_AWREADY),
      .m_axi_bvalid (AXI0_BVALID),
      .m_axi_rlast (AXI0_RLAST),
      .m_axi_rvalid (AXI0_RVALID),
      .m_axi_wready (AXI0_WREADY),
      .m_axi_bresp (AXI0_BRESP),
      .m_axi_rresp (AXI0_RRESP),
      .m_axi_bid (AXI0_BID),
      .m_axi_rid (AXI0_RID),
      .m_axi_rdata (AXI0_RDATA),
      .m_axi_aclk (AXI0_ACLK),
      .m_axi_arvalid (AXI0_ARVALID),
      .m_axi_awvalid (AXI0_AWVALID),
      .m_axi_bready (AXI0_BREADY),
      .m_axi_rready (AXI0_RREADY),
      .m_axi_wlast (AXI0_WLAST),
      .m_axi_wvalid (AXI0_WVALID),
      .m_axi_arburst (AXI0_ARBURST),
      .m_axi_arlock (AXI0_ARLOCK),
      .m_axi_arsize (AXI0_ARSIZE),
      .m_axi_awburst (AXI0_AWBURST),
      .m_axi_awlock (AXI0_AWLOCK),
      .m_axi_awsize (AXI0_AWSIZE),
      .m_axi_arprot (AXI0_ARPROT),
      .m_axi_awprot (AXI0_AWPROT),
      .m_axi_araddr (AXI0_ARADDR),
      .m_axi_awaddr (AXI0_AWADDR),
      .m_axi_arcache (AXI0_ARCACHE),
      .m_axi_arlen (AXI0_ARLEN),
      .m_axi_arqos (AXI0_ARQOS),
      .m_axi_awcache (AXI0_AWCACHE),
      .m_axi_awlen (AXI0_AWLEN),
      .m_axi_awqos (AXI0_AWQOS),
      .m_axi_arid (AXI0_ARID),
      .m_axi_awid (AXI0_AWID),
      .m_axi_wid (AXI0_WID),
      .m_axi_wdata (AXI0_WDATA),
      .m_axi_wstrb (AXI0_WSTRB)
   );

   processing_system7_0 i_ps (
      .S_AXI_HP0_ARREADY (AXI0_ARREADY),
      .S_AXI_HP0_AWREADY (AXI0_AWREADY),
      .S_AXI_HP0_BVALID (AXI0_BVALID),
      .S_AXI_HP0_RLAST (AXI0_RLAST),
      .S_AXI_HP0_RVALID (AXI0_RVALID),
      .S_AXI_HP0_WREADY (AXI0_WREADY),
      .S_AXI_HP0_BRESP (AXI0_BRESP),
      .S_AXI_HP0_RRESP (AXI0_RRESP),
      .S_AXI_HP0_BID (AXI0_BID),
      .S_AXI_HP0_RID (AXI0_RID),
      .S_AXI_HP0_RDATA (AXI0_RDATA),
      .S_AXI_HP0_RCOUNT (AXI0_RCOUNT),
      .S_AXI_HP0_WCOUNT (AXI0_WCOUNT),
      .S_AXI_HP0_RACOUNT (AXI0_RACOUNT),
      .S_AXI_HP0_WACOUNT (AXI0_WACOUNT),
      .S_AXI_HP0_ACLK (AXI0_ACLK),
      .S_AXI_HP0_ARVALID (AXI0_ARVALID),
      .S_AXI_HP0_AWVALID (AXI0_AWVALID),
      .S_AXI_HP0_BREADY (AXI0_BREADY),
      .S_AXI_HP0_RDISSUECAP1_EN (AXI0_RDISSUECAP1_EN),
      .S_AXI_HP0_RREADY (AXI0_RREADY),
      .S_AXI_HP0_WLAST (AXI0_WLAST),
      .S_AXI_HP0_WRISSUECAP1_EN (AXI0_WRISSUECAP1_EN),
      .S_AXI_HP0_WVALID (AXI0_WVALID),
      .S_AXI_HP0_ARBURST (AXI0_ARBURST),
      .S_AXI_HP0_ARLOCK (AXI0_ARLOCK),
      .S_AXI_HP0_ARSIZE (AXI0_ARSIZE),
      .S_AXI_HP0_AWBURST (AXI0_AWBURST),
      .S_AXI_HP0_AWLOCK (AXI0_AWLOCK),
      .S_AXI_HP0_AWSIZE (AXI0_AWSIZE),
      .S_AXI_HP0_ARPROT (AXI0_ARPROT),
      .S_AXI_HP0_AWPROT (AXI0_AWPROT),
      .S_AXI_HP0_ARADDR (AXI0_ARADDR),
      .S_AXI_HP0_AWADDR (AXI0_AWADDR),
      .S_AXI_HP0_ARCACHE (AXI0_ARCACHE),
      .S_AXI_HP0_ARLEN (AXI0_ARLEN),
      .S_AXI_HP0_ARQOS (AXI0_ARQOS),
      .S_AXI_HP0_AWCACHE (AXI0_AWCACHE),
      .S_AXI_HP0_AWLEN (AXI0_AWLEN),
      .S_AXI_HP0_AWQOS (AXI0_AWQOS),
      .S_AXI_HP0_ARID (AXI0_ARID),
      .S_AXI_HP0_AWID (AXI0_AWID),
      .S_AXI_HP0_WID (AXI0_WID),
      .S_AXI_HP0_WDATA (AXI0_WDATA),
      .S_AXI_HP0_WSTRB (AXI0_WSTRB),

      .S_AXI_HP1_ARREADY (AXI1_ARREADY),
      .S_AXI_HP1_AWREADY (AXI1_AWREADY),
      .S_AXI_HP1_BVALID (AXI1_BVALID),
      .S_AXI_HP1_RLAST (AXI1_RLAST),
      .S_AXI_HP1_RVALID (AXI1_RVALID),
      .S_AXI_HP1_WREADY (AXI1_WREADY),
      .S_AXI_HP1_BRESP (AXI1_BRESP),
      .S_AXI_HP1_RRESP (AXI1_RRESP),
      .S_AXI_HP1_BID (AXI1_BID),
      .S_AXI_HP1_RID (AXI1_RID),
      .S_AXI_HP1_RDATA (AXI1_RDATA),
      .S_AXI_HP1_RCOUNT (AXI1_RCOUNT),
      .S_AXI_HP1_WCOUNT (AXI1_WCOUNT),
      .S_AXI_HP1_RACOUNT (AXI1_RACOUNT),
      .S_AXI_HP1_WACOUNT (AXI1_WACOUNT),
      .S_AXI_HP1_ACLK (AXI1_ACLK),
      .S_AXI_HP1_ARVALID (AXI1_ARVALID),
      .S_AXI_HP1_AWVALID (AXI1_AWVALID),
      .S_AXI_HP1_BREADY (AXI1_BREADY),
      .S_AXI_HP1_RDISSUECAP1_EN (AXI1_RDISSUECAP1_EN),
      .S_AXI_HP1_RREADY (AXI1_RREADY),
      .S_AXI_HP1_WLAST (AXI1_WLAST),
      .S_AXI_HP1_WRISSUECAP1_EN (AXI1_WRISSUECAP1_EN),
      .S_AXI_HP1_WVALID (AXI1_WVALID),
      .S_AXI_HP1_ARBURST (AXI1_ARBURST),
      .S_AXI_HP1_ARLOCK (AXI1_ARLOCK),
      .S_AXI_HP1_ARSIZE (AXI1_ARSIZE),
      .S_AXI_HP1_AWBURST (AXI1_AWBURST),
      .S_AXI_HP1_AWLOCK (AXI1_AWLOCK),
      .S_AXI_HP1_AWSIZE (AXI1_AWSIZE),
      .S_AXI_HP1_ARPROT (AXI1_ARPROT),
      .S_AXI_HP1_AWPROT (AXI1_AWPROT),
      .S_AXI_HP1_ARADDR (AXI1_ARADDR),
      .S_AXI_HP1_AWADDR (AXI1_AWADDR),
      .S_AXI_HP1_ARCACHE (AXI1_ARCACHE),
      .S_AXI_HP1_ARLEN (AXI1_ARLEN),
      .S_AXI_HP1_ARQOS (AXI1_ARQOS),
      .S_AXI_HP1_AWCACHE (AXI1_AWCACHE),
      .S_AXI_HP1_AWLEN (AXI1_AWLEN),
      .S_AXI_HP1_AWQOS (AXI1_AWQOS),
      .S_AXI_HP1_ARID (AXI1_ARID),
      .S_AXI_HP1_AWID (AXI1_AWID),
      .S_AXI_HP1_WID (AXI1_WID),
      .S_AXI_HP1_WDATA (AXI1_WDATA),
      .S_AXI_HP1_WSTRB (AXI1_WSTRB),

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
