module overlay #(
   parameter H_WIDTH = 1920,
   parameter V_HEIGHT = 1080,
   parameter BASE = 32'h21000000
) (
   input clk_i,
   input rst_ni,
   input [2:0] mode_i,

   input vin_clk_i,
   input vin_vs_i,
   input vin_de_i,

   input [23:0] data_i,
   output reg [23:0] data_o,

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
   localparam MAX_CNT = 200000000;

   reg vs_r;
   wire vs_rise = ~vs_r && vin_vs_i;
   always @(posedge vin_clk_i) begin
      vs_r <= vin_vs_i;
   end

   assign m_axi_aclk = vin_clk_i;

   assign m_axi_awvalid = 0;
   assign m_axi_bready = 0;
   assign m_axi_wlast = 0;
   assign m_axi_wvalid = 0;
   assign m_axi_awburst = 0;
   assign m_axi_awlock = 0;
   assign m_axi_awsize = 0;
   assign m_axi_awprot = 0;
   assign m_axi_awaddr = 0;
   assign m_axi_wdata = 0;
   assign m_axi_awcache = 0;
   assign m_axi_awlen = 0;
   assign m_axi_awqos = 0;
   assign m_axi_wstrb = 0;
   assign m_axi_awid = 0;
   assign m_axi_wid = 0;

   wire [7:0] pat;
   reg [7:0] pat_r, pat_rr, pat_rrr, pat_rrrr, pat_rrrrr;
   always @(posedge vin_clk_i) begin
      {pat_r, pat_rr, pat_rrr, pat_rrrr, pat_rrrrr} <= {pat, pat_r, pat_rr, pat_rrr, pat_rrrr};
   end

   axi_source #(
      .WIDTH (8),
      .SIZE (H_WIDTH * V_HEIGHT)
   ) i_source (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),

      .en_i (1),

      .aval_i (vs_rise),
      .addr_i (BASE),
      .rdy_i (vin_de_i),
      .data_o (pat),

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

   reg [31:0] cnt;
   (* mark_debug = "true" *) reg [2:0] mode;
   (* mark_debug = "true" *) reg en;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt <= 0;
         mode <= 0;
         en <= 1;
      end else if (mode != mode_i) begin
         cnt <= 0;
         mode <= mode_i;
         en <= 1;
      end else if (cnt < MAX_CNT) begin
         cnt <= cnt + 1;
         en <= 1;
      end else begin
         en <= 0;
      end
   end

   always @(*) begin
      data_o = data_i;
      if (en && pat_rrrrr[mode]) begin
         if (data_i[23:16] >= 128) begin
            data_o[23:16] = data_i[23:16] - 128;
         end else begin
            data_o[23:16] = 127 - data_i[23:16];
         end
         if (data_i[15:8] >= 128) begin
            data_o[15:8] = data_i[15:8] - 128;
         end else begin
            data_o[15:8] = 127 - data_i[15:8];
         end
         if (data_i[7:0] >= 128) begin
            data_o[7:0] = data_i[7:0] - 128;
         end else begin
            data_o[7:0] = 127 - data_i[7:0];
         end
      end
   end

endmodule
