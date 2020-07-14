module axi_source #(
   parameter WIDTH = 24, // Must be 8x
   parameter SIZE = 128
) (
   input clk_i,
   input rst_ni,

   input en_i,

   input aval_i,
   input [31:0] addr_i,

   input rdy_i,
   output [WIDTH-1:0] data_o,

   input m_axi_arready,
   input m_axi_rlast,
   input m_axi_rvalid,
   input [1:0] m_axi_rresp,
   input [63:0] m_axi_rdata,
   input [5:0] m_axi_rid,
   output m_axi_arvalid,
   output m_axi_rready,
   output [1:0] m_axi_arburst,
   output [1:0] m_axi_arlock,
   output [2:0] m_axi_arsize,
   output [2:0] m_axi_arprot,
   output [31:0] m_axi_araddr,
   output [3:0] m_axi_arcache,
   output [3:0] m_axi_arlen,
   output [3:0] m_axi_arqos,
   output [5:0] m_axi_arid
);
   localparam TRANS = 16;
   localparam BATCH = 64 * TRANS;
   localparam NBATCH = (WIDTH * SIZE + BATCH - 1) / BATCH;

   // M_AXI_R -> | -> repacker -> fifo -> data_o

   reg rbuffed;
   reg [63:0] rbuff;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         rbuffed <= 0;
         rbuff <= 0;
      end else if (aval_i) begin
         rbuffed <= 0;
      end else if (m_axi_rvalid && m_axi_rready) begin
         rbuffed <= 1;
         rbuff <= m_axi_rdata;
      end else if (rbuffed && m_axi_rready) begin
         rbuffed <= 0;
      end
   end

   wire rfval, rfrdy;
   wire [WIDTH-1:0] rfdata;
   repacker #(
      .IN (8),
      .OUT (WIDTH / 8),
      .BUFF (32)
   ) i_rpacker (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (aval_i),
      .in_val_i (rbuffed),
      .in_data_i (rbuff),
      .in_rdy_o (m_axi_rready),
      .out_val_o (rfval),
      .out_data_o (rfdata),
      .out_rdy_i (rfrdy)
   );

   rfifo #(
      .WLEN (7),
      .DEPTH (WIDTH),
      .BURST_LEN (1)
   ) i_rfifo (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (aval_i),
      .in_val_i (rfval),
      .in_data_i (rfdata),
      .in_rdy_o (rfrdy),
      .out_incr_i (rdy_i),
      .out_data_o (data_o)
   );

   reg arval;
   reg [31:0] raddr, rladdr;
   wire rglast = raddr == rladdr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         raddr <= 0;
         rladdr <= 0;
      end else if (aval_i) begin
         raddr <= addr_i;
         rladdr <= addr_i + (NBATCH - 1) * TRANS * 8;
      end else if (arval && m_axi_arready) begin
         raddr <= raddr + TRANS * 8;
      end
   end

   reg aval_r;
   always @(posedge clk_i) begin
      aval_r <= aval_i;
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         arval <= 0;
      end else if (aval_i) begin
         arval <= 0;
      end else if (aval_r && en_i) begin
         arval <= 1;
      end else if (arval && m_axi_arready) begin
         arval <= ~rglast && en_i;
      end
   end

   assign m_axi_arvalid = arval;
   assign m_axi_arburst = 2'b01; // INCR
   assign m_axi_arlock = 0;
   assign m_axi_arsize = 3'b011; // 8 bytes each transfer
   assign m_axi_arprot = 0;
   assign m_axi_araddr = raddr;
   assign m_axi_arcache = 0;
   assign m_axi_arlen = TRANS - 1;
   assign m_axi_arqos = 0;
   assign m_axi_arid = 0;

   // assign m_axi_rready;

endmodule
