module axi_delayer #(
   parameter H_WIDTH = 1920,
   parameter V_HEIGHT = 1080,
   parameter BASE = 32'h20000000
) (
   input clk_i,
   input rst_ni,

   input ren_i,
   input wen_i,
   input vs_i,
   input de_i,
   input [23:0] data_i,
   output [23:0] data_o,

   input m_axi_arready,
   input m_axi_awready,
   input m_axi_bvalid,
   input m_axi_rlast,
   input m_axi_rvalid,
   input m_axi_wready,
   input [1:0] m_axi_bresp,
   input [1:0] m_axi_rresp,
   input [63:0] m_axi_rdata,
   input [5:0] m_axi_bid,
   input [5:0] m_axi_rid,
   output m_axi_aclk,
   output m_axi_arvalid,
   output m_axi_awvalid,
   output m_axi_bready,
   output m_axi_rready,
   output m_axi_wlast,
   output m_axi_wvalid,
   output [1:0] m_axi_arburst,
   output [1:0] m_axi_arlock,
   output [2:0] m_axi_arsize,
   output [1:0] m_axi_awburst,
   output [1:0] m_axi_awlock,
   output [2:0] m_axi_awsize,
   output [2:0] m_axi_arprot,
   output [2:0] m_axi_awprot,
   output [31:0] m_axi_araddr,
   output [31:0] m_axi_awaddr,
   output [63:0] m_axi_wdata,
   output [3:0] m_axi_arcache,
   output [3:0] m_axi_arlen,
   output [3:0] m_axi_arqos,
   output [3:0] m_axi_awcache,
   output [3:0] m_axi_awlen,
   output [3:0] m_axi_awqos,
   output [7:0] m_axi_wstrb,
   output [5:0] m_axi_arid,
   output [5:0] m_axi_awid,
   output [5:0] m_axi_wid
);
   localparam SIZE = H_WIDTH * V_HEIGHT * 24 / 8;
   localparam ABASE = BASE;
   localparam BBASE = BASE + SIZE;

   reg vs_r, bs;
   wire vs_rise = ~vs_r && vs_i;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         vs_r <= 0;
         bs <= 0;
      end else begin
         vs_r <= vs_i;
         bs <= bs ^ vs_rise;
      end
   end

   reg inited;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         inited <= 0;
      end else if (vs_i) begin
         inited <= 1;
      end
   end

   reg [3:0] srst_cnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         srst_cnt <= 4'd15;
      end else if (vs_rise) begin
         srst_cnt <= 4'd15;
      end else if (|srst_cnt) begin
         srst_cnt <= srst_cnt - 1;
      end
   end

   assign m_axi_aclk = clk_i;

   axi_sink #(
      .WIDTH (24),
      .SIZE (H_WIDTH * V_HEIGHT)
   ) i_sink (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (~rst_ni || |srst_cnt),

      .en_i (wen_i),

      .aval_i (~inited || vs_i),
      .addr_i (bs ? ABASE : BBASE),
      .val_i (de_i),
      .data_i (data_i),

      .m_axi_awready (m_axi_awready),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_wready (m_axi_wready),
      .m_axi_bresp (m_axi_bresp),
      .m_axi_bid (m_axi_bid),
      .m_axi_awvalid (m_axi_awvalid),
      .m_axi_bready (m_axi_bready),
      .m_axi_wlast (m_axi_wlast),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_awburst (m_axi_awburst),
      .m_axi_awlock (m_axi_awlock),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awprot (m_axi_awprot),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awcache (m_axi_awcache),
      .m_axi_awlen (m_axi_awlen),
      .m_axi_awqos (m_axi_awqos),
      .m_axi_awid (m_axi_awid),
      .m_axi_wid (m_axi_wid),
      .m_axi_wdata (m_axi_wdata),
      .m_axi_wstrb (m_axi_wstrb)
   );

   axi_source #(
      .WIDTH (24),
      .SIZE (H_WIDTH * V_HEIGHT)
   ) i_source (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (~rst_ni || |srst_cnt),

      .en_i (ren_i),

      .aval_i (~inited || vs_i),
      .addr_i (bs ? BBASE : ABASE),
      .rdy_i (de_i),
      .data_o (data_o),

      .m_axi_arready (m_axi_arready),
      .m_axi_rlast (m_axi_rlast),
      .m_axi_rvalid (m_axi_rvalid),
      .m_axi_rresp (m_axi_rresp),
      .m_axi_rid (m_axi_rid),
      .m_axi_rdata (m_axi_rdata),
      .m_axi_arvalid (m_axi_arvalid),
      .m_axi_rready (m_axi_rready),
      .m_axi_arburst (m_axi_arburst),
      .m_axi_arlock (m_axi_arlock),
      .m_axi_arsize (m_axi_arsize),
      .m_axi_arprot (m_axi_arprot),
      .m_axi_araddr (m_axi_araddr),
      .m_axi_arcache (m_axi_arcache),
      .m_axi_arlen (m_axi_arlen),
      .m_axi_arqos (m_axi_arqos),
      .m_axi_arid (m_axi_arid)
   );

endmodule
