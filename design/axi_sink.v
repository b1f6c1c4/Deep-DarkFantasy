module axi_sink #(
   parameter WIDTH = 24, // Must be 8x
   parameter SIZE = 128,
   parameter AXI = 64 // Must be 32 or 64
) (
   input clk_i,
   input rst_ni,
   input srst_i,

   input en_i,

   input aval_i,
   input [31:0] addr_i,

   input val_i,
   input [WIDTH-1:0] data_i,

   input m_axi_awready,
   input m_axi_bvalid,
   input m_axi_wready,
   input [1:0] m_axi_bresp,
   input [5:0] m_axi_bid,
   output m_axi_awvalid,
   output m_axi_bready,
   output m_axi_wlast,
   output m_axi_wvalid,
   output [1:0] m_axi_awburst,
   output [1:0] m_axi_awlock,
   output [2:0] m_axi_awsize,
   output [2:0] m_axi_awprot,
   output [31:0] m_axi_awaddr,
   output [AXI-1:0] m_axi_wdata,
   output [3:0] m_axi_awcache,
   output [3:0] m_axi_awlen,
   output [3:0] m_axi_awqos,
   output [AXI/8-1:0] m_axi_wstrb,
   output [5:0] m_axi_awid,
   output [5:0] m_axi_wid
);
   localparam TRANS = 16;
   localparam BATCH = AXI * TRANS;
   localparam NBATCH = (WIDTH * SIZE + BATCH - 1) / BATCH;

   // data_i -> repacker -> fifo -> | -> M_AXI_W

   wire wfval, wfrdy;
   wire [AXI-1:0] wfdata;
   repacker #(
      .IN (WIDTH / 8),
      .OUT (AXI / 8)
   ) i_wpacker (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (aval_i),
      .in_val_i (val_i),
      .in_data_i (data_i),
      .in_rdy_o (),
      .out_val_o (wfval),
      .out_data_o (wfdata),
      .out_rdy_i (wfrdy)
   );

   wire fifo_valid;
   reg wde2;
   wire [AXI-1:0] wd2;
   fifo #(
      .WIDTH (AXI),
      .BURST (TRANS - 1)
   ) i_wfifo (
      .clk_i (clk_i),
      .srst_i (srst_i),
      .en_i (~aval_i),
      .in_val_i (wfval),
      .in_data_i (wfdata),
      .in_rdy_o (wfrdy),
      .out_val_o (fifo_valid),
      .out_data_o (wd2),
      .out_rdy_i (wde2)
   );

   reg awval, wemit;
   reg [31:0] waddr, wladdr;
   reg wglast;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         waddr <= 0;
         wladdr <= 0;
         wglast <= 0;
      end else if (aval_i) begin
         waddr <= addr_i;
         wladdr <= addr_i + (NBATCH - 1) * TRANS * AXI / 8;
         wglast <= 0;
      end else if (awval && m_axi_awready) begin
         waddr <= waddr + TRANS * AXI / 8;
         wglast <= waddr == wladdr;
      end
   end

   always @(*) begin
      wde2 = 0;
      if (aval_i) begin
         wde2 = 0;
      end else if ((~m_axi_wvalid || m_axi_wlast) && fifo_valid && ~wglast && en_i) begin
         wde2 = 1;
      end else if (m_axi_wvalid && m_axi_wready && ~m_axi_wlast) begin
         wde2 = 1;
      end
   end

   reg [AXI-1:0] wbuff;
   reg [3:0] wcnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         awval <= 0;
         wemit <= 0;
         wcnt <= 0;
         wbuff <= 0;
      end else if (aval_i) begin
         awval <= 0;
         wemit <= 0;
         wcnt <= 0;
      end else if (awval && m_axi_awready) begin
         awval <= 0;
         wcnt <= 0;
         if (wemit) begin
            wcnt <= wcnt + 1;
            wbuff <= wd2;
         end
      end else if ((~wemit || &wcnt) && fifo_valid && ~wglast && en_i) begin
         awval <= 1;
         wemit <= 1;
         wcnt <= 0;
         wbuff <= wd2;
      end else if (wemit && m_axi_wready && m_axi_wlast) begin
         wemit <= 0;
         wcnt <= 0;
         wbuff <= wd2;
      end else if (wemit && m_axi_wready) begin
         wcnt <= wcnt + 1;
         wbuff <= wd2;
      end
   end

   assign m_axi_awvalid = awval;
   assign m_axi_awburst = 2'b01; // INCR
   assign m_axi_awlock = 0;
   assign m_axi_awsize = $clog2(AXI / 8); // 4/8 bytes each transfer
   assign m_axi_awprot = 0;
   assign m_axi_awaddr = waddr;
   assign m_axi_awcache = 0;
   assign m_axi_awlen = TRANS - 1;
   assign m_axi_awqos = 0;
   assign m_axi_awid = 0;

   assign m_axi_wlast = &wcnt;
   assign m_axi_wvalid = wemit;
   assign m_axi_wdata = wbuff;
   assign m_axi_wstrb = {(AXI/8){1'b1}};
   assign m_axi_wid = 0;

   assign m_axi_bready = 1;

endmodule
