module fifo #(
   parameter WIDTH = 24,
   parameter BURST = 0
) (
   input clk_i,
   input srst_i,

   input in_val_i,
   input [WIDTH-1:0] in_data_i,
   output in_rdy_o,

   output reg out_val_o,
   output [WIDTH-1:0] out_data_o,
   input out_rdy_i
);
   localparam PIECES = (WIDTH + 32 - 1) / 32;

   wire [32*PIECES-1:0] wdata, rdata;
   wire [PIECES-1:0] fulls, emptys, aemptys;
   wire full = |fulls;
   wire empty = |emptys;
   wire aempty = |aemptys;
   reg rden;

   reg rbuf, rbuf_next;
   always @(posedge clk_i) begin
      rbuf <= rbuf_next;
   end

   assign in_rdy_o = ~full;
   assign wdata = in_data_i;
   assign out_data_o = rdata[WIDTH-1:0];

   genvar i;
   generate
      for (i = 0; i < PIECES; i = i + 1) begin : g
         wire [32:0] w = wdata[i*32+31:i*32];
         wire [63:0] ro;
         assign rdata[i*32+31:i*32] = ro[31:0];
         FIFO36E1 #(
            .ALMOST_FULL_OFFSET (1),
            .ALMOST_EMPTY_OFFSET (BURST > 0 ? BURST - 1 : 1),
            .EN_SYN ("TRUE"),
            .DATA_WIDTH (36),
            .DO_REG (0)
         ) inst (
            .RST (srst_i),
            .RSTREG (0),
            .REGCE (0),

            .WRCLK (clk_i),
            .WREN (~srst_i && in_val_i && in_rdy_o),
            .DI ({32'b0,w[31:0]}),
            .DIP (0),
            .FULL (fulls[i]),
            .ALMOSTFULL (),
            .WRCOUNT (), .WRERR (),

            .RDCLK (clk_i),
            .RDEN (rden),
            .DO (ro),
            .DOP (),
            .EMPTY (emptys[i]),
            .ALMOSTEMPTY (aemptys[i]),
            .RDCOUNT (), .RDERR (),

            .INJECTDBITERR (0), .INJECTSBITERR (0),
            .DBITERR (), .SBITERR (), .ECCPARITY ()
         );
      end
   endgenerate

   always @(*) begin
      if (srst_i) begin
         rden = 0;
         out_val_o = 0;
         rbuf_next = 0;
      end else if (BURST == 0) begin
         if (empty) begin
            rden = 0;
            out_val_o = rbuf;
            rbuf_next = rbuf && ~out_rdy_i;
         end else if (~rbuf) begin
            rden = 1; // prefetch
            out_val_o = 0;
            rbuf_next = 1;
         end else if (out_rdy_i) begin
            rden = 1; // prefetch next
            out_val_o = rbuf;
            rbuf_next = 1;
         end else begin
            rden = 0; // keep
            out_val_o = 1;
            rbuf_next = 1;
         end
      end else begin
         out_val_o = ~aempty;
         if (empty) begin
            rden = 0;
            rbuf_next = rbuf && ~out_rdy_i;
         end else if (~rbuf) begin
            rden = 1; // prefetch
            rbuf_next = 1;
         end else if (out_rdy_i) begin
            rden = 1; // prefetch next
            rbuf_next = 1;
         end else begin
            rden = 0; // keep
            rbuf_next = 1;
         end
      end
   end

endmodule
