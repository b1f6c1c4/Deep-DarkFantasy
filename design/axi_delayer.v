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
   always @(posedge clk_i) begin
      vs_r <= vs_i;
      bs <= bs ^ vs_rise;
   end

   assign m_axi_aclk = clk_i;


   // M_AXI_R -> | -> repacker -> fifo -> vout

   reg rbuffed;
   reg [63:0] rbuff;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         rbuffed <= 0;
         rbuff <= 0;
      end else if (vs_rise) begin
         rbuffed <= 0;
         rbuff <= 0;
      end else if (m_axi_rvalid && m_axi_rready) begin
         rbuffed <= 1;
         rbuff <= m_axi_rdata;
      end else if (rbuffed && m_axi_rready) begin
         rbuffed <= 0;
      end
   end

   wire rfval, rfrdy;
   wire [23:0] rfdata;
   repacker #(
      .IN (64),
      .OUT (24),
      .BUFF (384)
   ) i_rpacker (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (vs_rise),
      .in_val_i (rbuffed),
      .in_data_i (rbuff),
      .in_rdy_o (m_axi_rready),
      .out_val_o (rfval),
      .out_data_o (rfdata),
      .out_rdy_i (rfrdy)
   );

   rfifo #(
      .WLEN (8),
      .DEPTH (24),
      .BURST_LEN (1)
   ) i_rfifo (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (vs_rise),
      .in_incr_i (rfval && rfrdy),
      .in_data_i (rfdata),
      .in_rdy_o (rfrdy),
      .out_incr_i (de_i),
      .out_data_o (data_o)
   );

   reg arval;
   reg [31:0] raddr;
   wire rglast = raddr == ((bs ? BBASE : ABASE) + SIZE - 16 * 8);
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         raddr <= ABASE;
      end else if (vs_rise) begin
         raddr <= bs ? ABASE : BBASE;
      end else if (arval && m_axi_arready) begin
         raddr <= raddr + 16 * 8;
      end
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         arval <= 0;
      end else if (vs_rise && ren_i) begin
         arval <= 1;
      end else if (arval && m_axi_arready) begin
         arval <= ~rglast && ren_i;
      end
   end

   assign m_axi_arvalid = arval;
   assign m_axi_arburst = 2'b01; // INCR
   assign m_axi_arlock = 0;
   assign m_axi_arsize = 3'b011; // 8 bytes each transfer
   assign m_axi_arprot = 0;
   assign m_axi_araddr = raddr;
   assign m_axi_arcache = 0;
   assign m_axi_arlen = 4'b1111; // 16 transfers each
   assign m_axi_arqos = 0;
   assign m_axi_arid = 0;

   // assign m_axi_rready;


   // vin -> repacker -> fifo -> M_AXI_W

   wire wde;
   wire [63:0] wd;
   repacker #(
      .IN (24),
      .OUT (64),
      .BUFF (88)
   ) i_wpacker (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (vs_rise),
      .in_val_i (de_i),
      .in_data_i (data_i),
      .in_rdy_o (),
      .out_val_o (wde),
      .out_data_o (wd),
      .out_rdy_i (1)
   );

   wire fifo_valid;
   wfifo #(
      .WLEN (7),
      .DEPTH (64),
      .BURST_LEN (16)
   ) i_wfifo (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (vs_rise),
      .in_incr_i (wde),
      .in_data_i (wd),
      .out_val_o (fifo_valid),
      .out_data_o (m_axi_wdata),
      .out_incr_i (m_axi_wvalid && m_axi_wready)
   );

   reg awval, wemit;
   reg [31:0] waddr;
   reg wglast;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         waddr <= BBASE;
         wglast <= 0;
      end else if (vs_rise) begin
         waddr <= bs ? BBASE : ABASE;
         wglast <= 0;
      end else if (awval && m_axi_awready) begin
         waddr <= waddr + 16 * 8;
         if (bs) begin
            wglast <= waddr == ABASE + SIZE - 16 * 8;
         end else begin
            wglast <= waddr == BBASE + SIZE - 16 * 8;
         end
      end
   end

   reg [3:0] wcnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         awval <= 0;
         wemit <= 0;
         wcnt <= 0;
      end else if (vs_rise) begin
         awval <= 0;
         wemit <= 0;
         wcnt <= 0;
      end else if (awval && m_axi_awready) begin
         awval <= 0;
         wcnt <= 0;
         if (wemit) begin
            wcnt <= wcnt + 1;
         end
      end else if ((~wemit || &wcnt) && fifo_valid && ~wglast && wen_i) begin
         awval <= 1;
         wemit <= 1;
         wcnt <= 0;
      end else if (wemit && m_axi_wlast) begin
         wemit <= 0;
         wcnt <= 0;
      end else if (wemit && m_axi_wready) begin
         wcnt <= wcnt + 1;
      end
   end

   assign m_axi_awvalid = awval;
   assign m_axi_awburst = 2'b01; // INCR
   assign m_axi_awlock = 0;
   assign m_axi_awsize = 3'b011; // 8 bytes each transfer
   assign m_axi_awprot = 0;
   assign m_axi_awaddr = waddr;
   assign m_axi_awcache = 0;
   assign m_axi_awlen = 4'b1111; // 16 transfers each
   assign m_axi_awqos = 0;
   assign m_axi_awid = 0;

   assign m_axi_wlast = &wcnt;
   assign m_axi_wvalid = wemit;
   // assign m_axi_wdata;
   assign m_axi_wstrb = 8'b11111111;
   assign m_axi_wid = 0;

   assign m_axi_bready = 1;

endmodule
