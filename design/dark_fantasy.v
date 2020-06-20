module dark_fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input clk_i,
   input rst_ni,

   input [3:0] sw_i,
   output [3:0] led_o,

   output hdmi_in_hpd_o,
   input hdmi_out_hpd_i,

   input vs_i,
   input hs_i,
   input de_i,
   input [23:0] data_i,
   output [23:0] data_o,

   input M_AXI_ARREADY,
   input M_AXI_AWREADY,
   input M_AXI_BVALID,
   input M_AXI_RLAST,
   input M_AXI_RVALID,
   input M_AXI_WREADY,
   input [1:0] M_AXI_BRESP,
   input [1:0] M_AXI_RRESP,
   input [63:0] M_AXI_RDATA,
   input [5:0] M_AXI_BID,
   input [5:0] M_AXI_RID,
   output M_AXI_ACLK,
   output M_AXI_ARVALID,
   output M_AXI_AWVALID,
   output M_AXI_BREADY,
   output M_AXI_RREADY,
   output M_AXI_WLAST,
   output M_AXI_WVALID,
   output [1:0] M_AXI_ARBURST,
   output [1:0] M_AXI_ARLOCK,
   output [2:0] M_AXI_ARSIZE,
   output [1:0] M_AXI_AWBURST,
   output [1:0] M_AXI_AWLOCK,
   output [2:0] M_AXI_AWSIZE,
   output [2:0] M_AXI_ARPROT,
   output [2:0] M_AXI_AWPROT,
   output [31:0] M_AXI_ARADDR,
   output [31:0] M_AXI_AWADDR,
   output [63:0] M_AXI_WDATA,
   output [3:0] M_AXI_ARCACHE,
   output [3:0] M_AXI_ARLEN,
   output [3:0] M_AXI_ARQOS,
   output [3:0] M_AXI_AWCACHE,
   output [3:0] M_AXI_AWLEN,
   output [3:0] M_AXI_AWQOS,
   output [7:0] M_AXI_WSTRB,
   output [5:0] M_AXI_ARID,
   output [5:0] M_AXI_AWID,
   output [5:0] M_AXI_WID
);

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
      .vout_hpd_i (hdmi_out_hpd_i),

      .vin_clk_i (clk_i),
      .vin_hs_i (hs_i),
      .vin_vs_i (vs_i),
      .vin_de_i (de_i),
      .vin_data_i (data_i),
      .vout_data_i (mid_data),
      .vout_data_o (data_o)
   );

   axi_delayer #(
      .H_WIDTH (H_WIDTH),
      .V_HEIGHT (V_HEIGHT)
   ) i_axi_delayer (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .wen_i (~sw_i[3]),
      .vs_i (vs_i),
      .de_i (de_i),
      .data_i (data_i),
      .data_o (mid_data),

      .m_axi_arready (M_AXI_ARREADY),
      .m_axi_awready (M_AXI_AWREADY),
      .m_axi_bvalid (M_AXI_BVALID),
      .m_axi_rlast (M_AXI_RLAST),
      .m_axi_rvalid (M_AXI_RVALID),
      .m_axi_wready (M_AXI_WREADY),
      .m_axi_bresp (M_AXI_BRESP),
      .m_axi_rresp (M_AXI_RRESP),
      .m_axi_bid (M_AXI_BID),
      .m_axi_rid (M_AXI_RID),
      .m_axi_rdata (M_AXI_RDATA),
      .m_axi_aclk (M_AXI_ACLK),
      .m_axi_arvalid (M_AXI_ARVALID),
      .m_axi_awvalid (M_AXI_AWVALID),
      .m_axi_bready (M_AXI_BREADY),
      .m_axi_rready (M_AXI_RREADY),
      .m_axi_wlast (M_AXI_WLAST),
      .m_axi_wvalid (M_AXI_WVALID),
      .m_axi_arburst (M_AXI_ARBURST),
      .m_axi_arlock (M_AXI_ARLOCK),
      .m_axi_arsize (M_AXI_ARSIZE),
      .m_axi_awburst (M_AXI_AWBURST),
      .m_axi_awlock (M_AXI_AWLOCK),
      .m_axi_awsize (M_AXI_AWSIZE),
      .m_axi_arprot (M_AXI_ARPROT),
      .m_axi_awprot (M_AXI_AWPROT),
      .m_axi_araddr (M_AXI_ARADDR),
      .m_axi_awaddr (M_AXI_AWADDR),
      .m_axi_arcache (M_AXI_ARCACHE),
      .m_axi_arlen (M_AXI_ARLEN),
      .m_axi_arqos (M_AXI_ARQOS),
      .m_axi_awcache (M_AXI_AWCACHE),
      .m_axi_awlen (M_AXI_AWLEN),
      .m_axi_awqos (M_AXI_AWQOS),
      .m_axi_arid (M_AXI_ARID),
      .m_axi_awid (M_AXI_AWID),
      .m_axi_wid (M_AXI_WID),
      .m_axi_wdata (M_AXI_WDATA),
      .m_axi_wstrb (M_AXI_WSTRB)
   );

endmodule
