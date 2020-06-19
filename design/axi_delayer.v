module axi_delayer #(
   parameter H_WIDTH = 1920,
   parameter V_HEIGHT = 1080,
   parameter BASE = 32'h0a000000
) (
   input clk_i,
   input rst_ni,

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
   input [31:0] m_axi_rdata,
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
   output [31:0] m_axi_wdata,
   output [3:0] m_axi_arcache,
   output [3:0] m_axi_arlen,
   output [3:0] m_axi_arqos,
   output [3:0] m_axi_awcache,
   output [3:0] m_axi_awlen,
   output [3:0] m_axi_awqos,
   output [3:0] m_axi_wstrb,
   output [5:0] m_axi_arid,
   output [5:0] m_axi_awid,
   output [5:0] m_axi_wid
);

   reg vs_r, bs;
   wire vs_rise = ~vs_r && vs_i;
   always @(posedge clk_i) begin
      vs_r <= vs_i;
      bs <= bs ^ vs_rise;
   end

   assign m_axi_aclk = clk_i;


   // M_AXI_R -> vout

   reg arval, rwait;
   wire fifo_ready;
   rfifo #(
      .WLEN (8),
      .DEPTH (24),
      .BURST_LEN (16)
   ) i_rfifo (
      .clk_i (clk_i),
      .rst_ni (rst_ni && ~vs_rise),
      .in_incr_i (m_axi_rvalid),
      .in_data_i (m_axi_rdata[23:0]),
      .in_rdy_o (fifo_ready),
      .out_incr_i (de_i),
      .out_data_o (data_o)
   );

   reg [31:0] raddr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         raddr <= BASE;
      end else if (vs_rise) begin
         raddr <= bs ? BASE : (BASE + H_WIDTH * V_HEIGHT * 4);
      end else if (arval && m_axi_arready) begin
         raddr <= raddr + 16 * 4;
      end
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni || vs_rise) begin
         arval <= 0;
         rwait <= 0;
      end else if (~rwait && fifo_ready) begin
         arval <= 1;
         rwait <= 1;
      end else if (arval && m_axi_arready) begin
         arval <= 0;
      end else if (rwait && m_axi_rlast) begin
         rwait <= 0;
      end
   end

   assign m_axi_arvalid = arval;
   assign m_axi_arburst = 2'b01; // INCR
   assign m_axi_arlock = 0;
   assign m_axi_arsize = 3'b010; // 4 bytes each transfer
   assign m_axi_arprot = 0;
   assign m_axi_araddr = raddr;
   assign m_axi_arcache = 4'b0011; // Bufferable, Cacheable
   assign m_axi_arlen = 4'b1111; // 16 transfers each
   assign m_axi_arqos = 0;
   assign m_axi_arid = 0;

   assign m_axi_rready = 1;


   // vin -> M_AXI_W

   reg awval, wwait;
   wire [23:0] wdata;
   wire fifo_valid;
   wfifo #(
      .WLEN (8),
      .DEPTH (24),
      .BURST_LEN (16)
   ) i_wfifo (
      .clk_i (clk_i),
      .rst_ni (rst_ni && ~vs_rise),
      .in_incr_i (de_i),
      .in_data_i (data_i),
      .out_val_o (fifo_valid),
      .out_data_o (wdata),
      .out_incr_i (wwait && ~awval && m_axi_wready)
   );

   reg [31:0] waddr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         waddr <= BASE;
      end else if (vs_rise) begin
         waddr <= bs ? (BASE + H_WIDTH * V_HEIGHT * 4) : BASE;
      end else if (awval && m_axi_awready) begin
         waddr <= waddr + 16 * 4;
      end
   end

   reg [3:0] wcnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         wcnt <= 0;
      end else if (vs_rise || awval) begin
         wcnt <= 0;
      end else if (wwait && m_axi_wready) begin
         wcnt <= wcnt + 1;
      end
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni || vs_rise) begin
         awval <= 0;
         wwait <= 0;
      end else if (~wwait && fifo_valid) begin
         awval <= 1;
         wwait <= 1;
      end else if (awval && m_axi_awready) begin
         awval <= 0;
      end else if (wwait && &wcnt) begin
         wwait <= 0;
      end
   end

   assign m_axi_awvalid = awval;
   assign m_axi_awburst = 2'b01; // INCR
   assign m_axi_awlock = 0;
   assign m_axi_awsize = 3'b010; // 4 bytes each transfer
   assign m_axi_awprot = 0;
   assign m_axi_awaddr = waddr;
   assign m_axi_awcache = 4'b0011; // Bufferable, Cacheable
   assign m_axi_awlen = 4'b1111; // 16 transfers each
   assign m_axi_awqos = 0;
   assign m_axi_awid = 0;

   assign m_axi_wlast = &wcnt;
   assign m_axi_wvalid = wwait && ~awval;
   assign m_axi_wdata = {8'h00,wdata};
   assign m_axi_wstrb = 4'b1111;
   assign m_axi_wid = 0;

   assign m_axi_bready = 1;

endmodule
