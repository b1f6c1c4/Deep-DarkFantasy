module axi_source #(
   parameter WIDTH = 24, // Must be 8x
   parameter SIZE = 128,
   parameter AXI = 64 // Must be 32 or 64
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
   input [AXI-1:0] m_axi_rdata,
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
   localparam BATCH = AXI * TRANS;
   localparam NBATCH = (WIDTH * SIZE + BATCH - 1) / BATCH;

   // M_AXI_R -> fifo -> repacker -> fifo -> data_o

   wire rfval1, rfrdy1;
   wire [AXI-1:0] rfdata1;
   fifo #(
      .WIDTH (AXI)
   ) i_rfifo1 (
      .clk_i (clk_i),
      .srst_i (aval_i),
      .in_val_i (m_axi_rvalid),
      .in_data_i (m_axi_rdata),
      .in_rdy_o (m_axi_rready),
      .out_val_o (rfval1),
      .out_data_o (rfdata1),
      .out_rdy_i (rfrdy1)
   );

   wire rfval2, rfrdy2;
   wire [WIDTH-1:0] rfdata2;
   repacker #(
      .IN (AXI / 8),
      .OUT (WIDTH / 8)
   ) i_rpacker (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .srst_i (aval_i),
      .in_val_i (rfval1),
      .in_data_i (rfdata1),
      .in_rdy_o (rfrdy1),
      .out_val_o (rfval2),
      .out_data_o (rfdata2),
      .out_rdy_i (rfrdy2)
   );

   fifo #(
      .WIDTH (WIDTH)
   ) i_rfifo2 (
      .clk_i (clk_i),
      .srst_i (aval_i),
      .in_val_i (rfval2),
      .in_data_i (rfdata2),
      .in_rdy_o (rfrdy2),
      .out_val_o (),
      .out_data_o (data_o),
      .out_rdy_i (rdy_i)
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
         rladdr <= addr_i + (NBATCH - 1) * TRANS * AXI / 8;
      end else if (arval && m_axi_arready) begin
         raddr <= raddr + TRANS * AXI / 8;
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
   assign m_axi_arsize = $clog2(AXI / 8); // 4/8 bytes each transfer
   assign m_axi_arprot = 0;
   assign m_axi_araddr = raddr;
   assign m_axi_arcache = 0;
   assign m_axi_arlen = TRANS - 1;
   assign m_axi_arqos = 0;
   assign m_axi_arid = 0;

   // assign m_axi_rready;

endmodule
