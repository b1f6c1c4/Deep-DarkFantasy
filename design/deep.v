module deep #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_T = 1400
) (
   input [3:0] button_i,
   input [2:0] rot_ni,

   output [3:0] led_o,

   output hdmi0_in_hpd_o,
   inout hdmi0_in_ddc_scl_io,
   inout hdmi0_in_ddc_sda_io,
   input hdmi0_in_clk_n,
   input hdmi0_in_clk_p,
   input [2:0] hdmi0_in_data_n,
   input [2:0] hdmi0_in_data_p,

   input hdmi0_out_hpd_i,
   output hdmi0_out_clk_n,
   output hdmi0_out_clk_p,
   output [2:0] hdmi0_out_data_n,
   output [2:0] hdmi0_out_data_p,

   output hdmi1_in_hpd_o,
   inout hdmi1_in_ddc_scl_io,
   inout hdmi1_in_ddc_sda_io,
   input hdmi1_in_clk_n,
   input hdmi1_in_clk_p,
   input [2:0] hdmi1_in_data_n,
   input [2:0] hdmi1_in_data_p,

   input hdmi1_out_hpd_i,
   output hdmi1_out_clk_n,
   output hdmi1_out_clk_p,
   output [2:0] hdmi1_out_data_n,
   output [2:0] hdmi1_out_data_p,

   inout [31:0] MIO,
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
   inout [1:0] DDR_DM,
   inout [15:0] DDR_DQ,
   inout [1:0] DDR_DQS_n,
   inout [1:0] DDR_DQS,
   inout PS_SRSTB,
   inout PS_CLK,
   inout PS_PORB
);

   wire clk_200MHz, clk_333kHz;

   wire rst_n = ~button_i[3];

   wire [2:0] fantasy_mode;
   rotary #(
      .N (8),
      .SAT (1),
      .INIT (3),
      .T (3)
   ) i_rotary (
      .clk_i (clk_333kHz),
      .rst_ni (rst_n),
      .rot_ni (rot_ni),
      .zero_i (button_i[0]),
      .inc_i (button_i[1]),
      .dec_i (button_i[2]),
      .counter_o (fantasy_mode)
   );

   // LED monitor

   assign led_o[0] = fantasy_mode[0];
   assign led_o[1] = fantasy_mode[1];

   // Memory

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

   wire AXI2_ARREADY, AXI3_ARREADY;
   wire AXI2_AWREADY, AXI3_AWREADY;
   wire AXI2_BVALID, AXI3_BVALID;
   wire AXI2_RLAST, AXI3_RLAST;
   wire AXI2_RVALID, AXI3_RVALID;
   wire AXI2_WREADY, AXI3_WREADY;
   wire [1:0] AXI2_BRESP, AXI3_BRESP;
   wire [1:0] AXI2_RRESP, AXI3_RRESP;
   wire [5:0] AXI2_BID, AXI3_BID;
   wire [5:0] AXI2_RID, AXI3_RID;
   wire [63:0] AXI2_RDATA, AXI3_RDATA;
   wire [7:0] AXI2_RCOUNT, AXI3_RCOUNT;
   wire [7:0] AXI2_WCOUNT, AXI3_WCOUNT;
   wire [2:0] AXI2_RACOUNT, AXI3_RACOUNT;
   wire [5:0] AXI2_WACOUNT, AXI3_WACOUNT;
   wire AXI2_ACLK, AXI3_ACLK;
   wire AXI2_ARVALID, AXI3_ARVALID;
   wire AXI2_AWVALID, AXI3_AWVALID;
   wire AXI2_BREADY, AXI3_BREADY;
   wire AXI2_RDISSUECAP1_EN, AXI3_RDISSUECAP1_EN;
   wire AXI2_RREADY, AXI3_RREADY;
   wire AXI2_WLAST, AXI3_WLAST;
   wire AXI2_WRISSUECAP1_EN, AXI3_WRISSUECAP1_EN;
   wire AXI2_WVALID, AXI3_WVALID;
   wire [1:0] AXI2_ARBURST, AXI3_ARBURST;
   wire [1:0] AXI2_ARLOCK, AXI3_ARLOCK;
   wire [2:0] AXI2_ARSIZE, AXI3_ARSIZE;
   wire [1:0] AXI2_AWBURST, AXI3_AWBURST;
   wire [1:0] AXI2_AWLOCK, AXI3_AWLOCK;
   wire [2:0] AXI2_AWSIZE, AXI3_AWSIZE;
   wire [2:0] AXI2_ARPROT, AXI3_ARPROT;
   wire [2:0] AXI2_AWPROT, AXI3_AWPROT;
   wire [31:0] AXI2_ARADDR, AXI3_ARADDR;
   wire [31:0] AXI2_AWADDR, AXI3_AWADDR;
   wire [3:0] AXI2_ARCACHE, AXI3_ARCACHE;
   wire [3:0] AXI2_ARLEN, AXI3_ARLEN;
   wire [3:0] AXI2_ARQOS, AXI3_ARQOS;
   wire [3:0] AXI2_AWCACHE, AXI3_AWCACHE;
   wire [3:0] AXI2_AWLEN, AXI3_AWLEN;
   wire [3:0] AXI2_AWQOS, AXI3_AWQOS;
   wire [5:0] AXI2_ARID, AXI3_ARID;
   wire [5:0] AXI2_AWID, AXI3_AWID;
   wire [5:0] AXI2_WID, AXI3_WID;
   wire [63:0] AXI2_WDATA, AXI3_WDATA;
   wire [7:0] AXI2_WSTRB, AXI3_WSTRB;

   assign AXI2_RDISSUECAP1_EN = 0;
   assign AXI3_RDISSUECAP1_EN = 0;
   assign AXI2_WRISSUECAP1_EN = 0;
   assign AXI3_WRISSUECAP1_EN = 0;

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

      .S_AXI_HP2_ARREADY (AXI2_ARREADY),
      .S_AXI_HP2_AWREADY (AXI2_AWREADY),
      .S_AXI_HP2_BVALID (AXI2_BVALID),
      .S_AXI_HP2_RLAST (AXI2_RLAST),
      .S_AXI_HP2_RVALID (AXI2_RVALID),
      .S_AXI_HP2_WREADY (AXI2_WREADY),
      .S_AXI_HP2_BRESP (AXI2_BRESP),
      .S_AXI_HP2_RRESP (AXI2_RRESP),
      .S_AXI_HP2_BID (AXI2_BID),
      .S_AXI_HP2_RID (AXI2_RID),
      .S_AXI_HP2_RDATA (AXI2_RDATA),
      .S_AXI_HP2_RCOUNT (AXI2_RCOUNT),
      .S_AXI_HP2_WCOUNT (AXI2_WCOUNT),
      .S_AXI_HP2_RACOUNT (AXI2_RACOUNT),
      .S_AXI_HP2_WACOUNT (AXI2_WACOUNT),
      .S_AXI_HP2_ACLK (AXI2_ACLK),
      .S_AXI_HP2_ARVALID (AXI2_ARVALID),
      .S_AXI_HP2_AWVALID (AXI2_AWVALID),
      .S_AXI_HP2_BREADY (AXI2_BREADY),
      .S_AXI_HP2_RDISSUECAP1_EN (AXI2_RDISSUECAP1_EN),
      .S_AXI_HP2_RREADY (AXI2_RREADY),
      .S_AXI_HP2_WLAST (AXI2_WLAST),
      .S_AXI_HP2_WRISSUECAP1_EN (AXI2_WRISSUECAP1_EN),
      .S_AXI_HP2_WVALID (AXI2_WVALID),
      .S_AXI_HP2_ARBURST (AXI2_ARBURST),
      .S_AXI_HP2_ARLOCK (AXI2_ARLOCK),
      .S_AXI_HP2_ARSIZE (AXI2_ARSIZE),
      .S_AXI_HP2_AWBURST (AXI2_AWBURST),
      .S_AXI_HP2_AWLOCK (AXI2_AWLOCK),
      .S_AXI_HP2_AWSIZE (AXI2_AWSIZE),
      .S_AXI_HP2_ARPROT (AXI2_ARPROT),
      .S_AXI_HP2_AWPROT (AXI2_AWPROT),
      .S_AXI_HP2_ARADDR (AXI2_ARADDR),
      .S_AXI_HP2_AWADDR (AXI2_AWADDR),
      .S_AXI_HP2_ARCACHE (AXI2_ARCACHE),
      .S_AXI_HP2_ARLEN (AXI2_ARLEN),
      .S_AXI_HP2_ARQOS (AXI2_ARQOS),
      .S_AXI_HP2_AWCACHE (AXI2_AWCACHE),
      .S_AXI_HP2_AWLEN (AXI2_AWLEN),
      .S_AXI_HP2_AWQOS (AXI2_AWQOS),
      .S_AXI_HP2_ARID (AXI2_ARID),
      .S_AXI_HP2_AWID (AXI2_AWID),
      .S_AXI_HP2_WID (AXI2_WID),
      .S_AXI_HP2_WDATA (AXI2_WDATA),
      .S_AXI_HP2_WSTRB (AXI2_WSTRB),

      .S_AXI_HP3_ARREADY (AXI3_ARREADY),
      .S_AXI_HP3_AWREADY (AXI3_AWREADY),
      .S_AXI_HP3_BVALID (AXI3_BVALID),
      .S_AXI_HP3_RLAST (AXI3_RLAST),
      .S_AXI_HP3_RVALID (AXI3_RVALID),
      .S_AXI_HP3_WREADY (AXI3_WREADY),
      .S_AXI_HP3_BRESP (AXI3_BRESP),
      .S_AXI_HP3_RRESP (AXI3_RRESP),
      .S_AXI_HP3_BID (AXI3_BID),
      .S_AXI_HP3_RID (AXI3_RID),
      .S_AXI_HP3_RDATA (AXI3_RDATA),
      .S_AXI_HP3_RCOUNT (AXI3_RCOUNT),
      .S_AXI_HP3_WCOUNT (AXI3_WCOUNT),
      .S_AXI_HP3_RACOUNT (AXI3_RACOUNT),
      .S_AXI_HP3_WACOUNT (AXI3_WACOUNT),
      .S_AXI_HP3_ACLK (AXI3_ACLK),
      .S_AXI_HP3_ARVALID (AXI3_ARVALID),
      .S_AXI_HP3_AWVALID (AXI3_AWVALID),
      .S_AXI_HP3_BREADY (AXI3_BREADY),
      .S_AXI_HP3_RDISSUECAP1_EN (AXI3_RDISSUECAP1_EN),
      .S_AXI_HP3_RREADY (AXI3_RREADY),
      .S_AXI_HP3_WLAST (AXI3_WLAST),
      .S_AXI_HP3_WRISSUECAP1_EN (AXI3_WRISSUECAP1_EN),
      .S_AXI_HP3_WVALID (AXI3_WVALID),
      .S_AXI_HP3_ARBURST (AXI3_ARBURST),
      .S_AXI_HP3_ARLOCK (AXI3_ARLOCK),
      .S_AXI_HP3_ARSIZE (AXI3_ARSIZE),
      .S_AXI_HP3_AWBURST (AXI3_AWBURST),
      .S_AXI_HP3_AWLOCK (AXI3_AWLOCK),
      .S_AXI_HP3_AWSIZE (AXI3_AWSIZE),
      .S_AXI_HP3_ARPROT (AXI3_ARPROT),
      .S_AXI_HP3_AWPROT (AXI3_AWPROT),
      .S_AXI_HP3_ARADDR (AXI3_ARADDR),
      .S_AXI_HP3_AWADDR (AXI3_AWADDR),
      .S_AXI_HP3_ARCACHE (AXI3_ARCACHE),
      .S_AXI_HP3_ARLEN (AXI3_ARLEN),
      .S_AXI_HP3_ARQOS (AXI3_ARQOS),
      .S_AXI_HP3_AWCACHE (AXI3_AWCACHE),
      .S_AXI_HP3_AWLEN (AXI3_AWLEN),
      .S_AXI_HP3_AWQOS (AXI3_AWQOS),
      .S_AXI_HP3_ARID (AXI3_ARID),
      .S_AXI_HP3_AWID (AXI3_AWID),
      .S_AXI_HP3_WID (AXI3_WID),
      .S_AXI_HP3_WDATA (AXI3_WDATA),
      .S_AXI_HP3_WSTRB (AXI3_WSTRB),

      .FCLK_CLK0 (clk_200MHz),
      .FCLK_CLK1 (clk_333kHz),
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

   // Core

   dark #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV),
      .SMOOTH_T (SMOOTH_T),
      .BASE (32'h20000000)
   ) i_dark_0 (
      .clk_ref_i (clk_200MHz),
      .rst_ref_ni (rst_n),

      .clk_i (clk_333kHz),
      .rst_ni (rst_n),
      .ren_i (1),
      .wen_i (1),
      .mode_i (fantasy_mode),
      .led_o (led_o[3]),

      .hdmi_in_hpd_o (hdmi0_in_hpd_o),
      .hdmi_in_ddc_scl_io (hdmi0_in_ddc_scl_io),
      .hdmi_in_ddc_sda_io (hdmi0_in_ddc_sda_io),
      .hdmi_in_clk_n (hdmi0_in_clk_n),
      .hdmi_in_clk_p (hdmi0_in_clk_p),
      .hdmi_in_data_n (hdmi0_in_data_n),
      .hdmi_in_data_p (hdmi0_in_data_p),

      .hdmi_out_hpd_i (hdmi0_out_hpd_i),
      .hdmi_out_clk_n (hdmi0_out_clk_n),
      .hdmi_out_clk_p (hdmi0_out_clk_p),
      .hdmi_out_data_n (hdmi0_out_data_n),
      .hdmi_out_data_p (hdmi0_out_data_p),

      .m_axi0_arready (AXI0_ARREADY),
      .m_axi0_awready (AXI0_AWREADY),
      .m_axi0_bvalid (AXI0_BVALID),
      .m_axi0_rlast (AXI0_RLAST),
      .m_axi0_rvalid (AXI0_RVALID),
      .m_axi0_wready (AXI0_WREADY),
      .m_axi0_bresp (AXI0_BRESP),
      .m_axi0_rresp (AXI0_RRESP),
      .m_axi0_rdata (AXI0_RDATA),
      .m_axi0_bid (AXI0_BID),
      .m_axi0_rid (AXI0_RID),
      .m_axi0_aclk (AXI0_ACLK),
      .m_axi0_arvalid (AXI0_ARVALID),
      .m_axi0_awvalid (AXI0_AWVALID),
      .m_axi0_bready (AXI0_BREADY),
      .m_axi0_rready (AXI0_RREADY),
      .m_axi0_wlast (AXI0_WLAST),
      .m_axi0_wvalid (AXI0_WVALID),
      .m_axi0_arburst (AXI0_ARBURST),
      .m_axi0_arlock (AXI0_ARLOCK),
      .m_axi0_arsize (AXI0_ARSIZE),
      .m_axi0_awburst (AXI0_AWBURST),
      .m_axi0_awlock (AXI0_AWLOCK),
      .m_axi0_awsize (AXI0_AWSIZE),
      .m_axi0_arprot (AXI0_ARPROT),
      .m_axi0_awprot (AXI0_AWPROT),
      .m_axi0_araddr (AXI0_ARADDR),
      .m_axi0_awaddr (AXI0_AWADDR),
      .m_axi0_wdata (AXI0_WDATA),
      .m_axi0_arcache (AXI0_ARCACHE),
      .m_axi0_arlen (AXI0_ARLEN),
      .m_axi0_arqos (AXI0_ARQOS),
      .m_axi0_awcache (AXI0_AWCACHE),
      .m_axi0_awlen (AXI0_AWLEN),
      .m_axi0_awqos (AXI0_AWQOS),
      .m_axi0_wstrb (AXI0_WSTRB),
      .m_axi0_arid (AXI0_ARID),
      .m_axi0_awid (AXI0_AWID),
      .m_axi0_wid (AXI0_WID),

      .m_axi1_arready (AXI1_ARREADY),
      .m_axi1_awready (AXI1_AWREADY),
      .m_axi1_bvalid (AXI1_BVALID),
      .m_axi1_rlast (AXI1_RLAST),
      .m_axi1_rvalid (AXI1_RVALID),
      .m_axi1_wready (AXI1_WREADY),
      .m_axi1_bresp (AXI1_BRESP),
      .m_axi1_rresp (AXI1_RRESP),
      .m_axi1_rdata (AXI1_RDATA),
      .m_axi1_bid (AXI1_BID),
      .m_axi1_rid (AXI1_RID),
      .m_axi1_aclk (AXI1_ACLK),
      .m_axi1_arvalid (AXI1_ARVALID),
      .m_axi1_awvalid (AXI1_AWVALID),
      .m_axi1_bready (AXI1_BREADY),
      .m_axi1_rready (AXI1_RREADY),
      .m_axi1_wlast (AXI1_WLAST),
      .m_axi1_wvalid (AXI1_WVALID),
      .m_axi1_arburst (AXI1_ARBURST),
      .m_axi1_arlock (AXI1_ARLOCK),
      .m_axi1_arsize (AXI1_ARSIZE),
      .m_axi1_awburst (AXI1_AWBURST),
      .m_axi1_awlock (AXI1_AWLOCK),
      .m_axi1_awsize (AXI1_AWSIZE),
      .m_axi1_arprot (AXI1_ARPROT),
      .m_axi1_awprot (AXI1_AWPROT),
      .m_axi1_araddr (AXI1_ARADDR),
      .m_axi1_awaddr (AXI1_AWADDR),
      .m_axi1_wdata (AXI1_WDATA),
      .m_axi1_arcache (AXI1_ARCACHE),
      .m_axi1_arlen (AXI1_ARLEN),
      .m_axi1_arqos (AXI1_ARQOS),
      .m_axi1_awcache (AXI1_AWCACHE),
      .m_axi1_awlen (AXI1_AWLEN),
      .m_axi1_awqos (AXI1_AWQOS),
      .m_axi1_wstrb (AXI1_WSTRB),
      .m_axi1_arid (AXI1_ARID),
      .m_axi1_awid (AXI1_AWID),
      .m_axi1_wid (AXI1_WID)
   );

   dark #(
      .H_WIDTH (H_WIDTH),
      .H_START (H_START),
      .H_TOTAL (H_TOTAL),
      .V_HEIGHT (V_HEIGHT),
      .KH (KH),
      .KV (KV),
      .SMOOTH_T (SMOOTH_T),
      .BASE (32'h20000000)
   ) i_dark_1 (
      .clk_ref_i (clk_200MHz),
      .rst_ref_ni (rst_n),

      .clk_i (clk_333kHz),
      .rst_ni (rst_n),
      .ren_i (1),
      .wen_i (1),
      .mode_i (fantasy_mode),
      .led_o (led_o[2]),

      .hdmi_in_hpd_o (hdmi1_in_hpd_o),
      .hdmi_in_ddc_scl_io (hdmi1_in_ddc_scl_io),
      .hdmi_in_ddc_sda_io (hdmi1_in_ddc_sda_io),
      .hdmi_in_clk_n (hdmi1_in_clk_n),
      .hdmi_in_clk_p (hdmi1_in_clk_p),
      .hdmi_in_data_n (hdmi1_in_data_n),
      .hdmi_in_data_p (hdmi1_in_data_p),

      .hdmi_out_hpd_i (hdmi1_out_hpd_i),
      .hdmi_out_clk_n (hdmi1_out_clk_n),
      .hdmi_out_clk_p (hdmi1_out_clk_p),
      .hdmi_out_data_n (hdmi1_out_data_n),
      .hdmi_out_data_p (hdmi1_out_data_p),

      .m_axi0_arready (AXI2_ARREADY),
      .m_axi0_awready (AXI2_AWREADY),
      .m_axi0_bvalid (AXI2_BVALID),
      .m_axi0_rlast (AXI2_RLAST),
      .m_axi0_rvalid (AXI2_RVALID),
      .m_axi0_wready (AXI2_WREADY),
      .m_axi0_bresp (AXI2_BRESP),
      .m_axi0_rresp (AXI2_RRESP),
      .m_axi0_rdata (AXI2_RDATA),
      .m_axi0_bid (AXI2_BID),
      .m_axi0_rid (AXI2_RID),
      .m_axi0_aclk (AXI2_ACLK),
      .m_axi0_arvalid (AXI2_ARVALID),
      .m_axi0_awvalid (AXI2_AWVALID),
      .m_axi0_bready (AXI2_BREADY),
      .m_axi0_rready (AXI2_RREADY),
      .m_axi0_wlast (AXI2_WLAST),
      .m_axi0_wvalid (AXI2_WVALID),
      .m_axi0_arburst (AXI2_ARBURST),
      .m_axi0_arlock (AXI2_ARLOCK),
      .m_axi0_arsize (AXI2_ARSIZE),
      .m_axi0_awburst (AXI2_AWBURST),
      .m_axi0_awlock (AXI2_AWLOCK),
      .m_axi0_awsize (AXI2_AWSIZE),
      .m_axi0_arprot (AXI2_ARPROT),
      .m_axi0_awprot (AXI2_AWPROT),
      .m_axi0_araddr (AXI2_ARADDR),
      .m_axi0_awaddr (AXI2_AWADDR),
      .m_axi0_wdata (AXI2_WDATA),
      .m_axi0_arcache (AXI2_ARCACHE),
      .m_axi0_arlen (AXI2_ARLEN),
      .m_axi0_arqos (AXI2_ARQOS),
      .m_axi0_awcache (AXI2_AWCACHE),
      .m_axi0_awlen (AXI2_AWLEN),
      .m_axi0_awqos (AXI2_AWQOS),
      .m_axi0_wstrb (AXI2_WSTRB),
      .m_axi0_arid (AXI2_ARID),
      .m_axi0_awid (AXI2_AWID),
      .m_axi0_wid (AXI2_WID),

      .m_axi1_arready (AXI3_ARREADY),
      .m_axi1_awready (AXI3_AWREADY),
      .m_axi1_bvalid (AXI3_BVALID),
      .m_axi1_rlast (AXI3_RLAST),
      .m_axi1_rvalid (AXI3_RVALID),
      .m_axi1_wready (AXI3_WREADY),
      .m_axi1_bresp (AXI3_BRESP),
      .m_axi1_rresp (AXI3_RRESP),
      .m_axi1_rdata (AXI3_RDATA),
      .m_axi1_bid (AXI3_BID),
      .m_axi1_rid (AXI3_RID),
      .m_axi1_aclk (AXI3_ACLK),
      .m_axi1_arvalid (AXI3_ARVALID),
      .m_axi1_awvalid (AXI3_AWVALID),
      .m_axi1_bready (AXI3_BREADY),
      .m_axi1_rready (AXI3_RREADY),
      .m_axi1_wlast (AXI3_WLAST),
      .m_axi1_wvalid (AXI3_WVALID),
      .m_axi1_arburst (AXI3_ARBURST),
      .m_axi1_arlock (AXI3_ARLOCK),
      .m_axi1_arsize (AXI3_ARSIZE),
      .m_axi1_awburst (AXI3_AWBURST),
      .m_axi1_awlock (AXI3_AWLOCK),
      .m_axi1_awsize (AXI3_AWSIZE),
      .m_axi1_arprot (AXI3_ARPROT),
      .m_axi1_awprot (AXI3_AWPROT),
      .m_axi1_araddr (AXI3_ARADDR),
      .m_axi1_awaddr (AXI3_AWADDR),
      .m_axi1_wdata (AXI3_WDATA),
      .m_axi1_arcache (AXI3_ARCACHE),
      .m_axi1_arlen (AXI3_ARLEN),
      .m_axi1_arqos (AXI3_ARQOS),
      .m_axi1_awcache (AXI3_AWCACHE),
      .m_axi1_awlen (AXI3_AWLEN),
      .m_axi1_awqos (AXI3_AWQOS),
      .m_axi1_wstrb (AXI3_WSTRB),
      .m_axi1_arid (AXI3_ARID),
      .m_axi1_awid (AXI3_AWID),
      .m_axi1_wid (AXI3_WID)
   );

endmodule
