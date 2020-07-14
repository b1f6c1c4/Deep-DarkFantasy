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

   wire full, empty, aempty;
   wire [63:0] rdata;
   reg rden;

   reg rbuf, rbuf_next;
   always @(posedge clk_i) begin
      rbuf <= rbuf_next;
   end

   assign in_rdy_o = ~full;
   assign out_data_o = rdata[WIDTH-1:0];

   FIFO36E1 #(
      .ALMOST_FULL_OFFSET (1),
      .ALMOST_EMPTY_OFFSET (BURST > 0 ? BURST - 1 : 1),
      .EN_SYN ("TRUE"),
      .DATA_WIDTH (WIDTH <= 8 ? 9 : WIDTH <= 16 ? 18 : WIDTH <= 32 ? 36 : 72),
      .DO_REG (0)
   ) inst (
      .RST (srst_i),
      .RSTREG (0),
      .REGCE (0),

      .WRCLK (clk_i),
      .WREN (~srst_i && in_val_i && in_rdy_o),
      .DI (in_data_i),
      .DIP (0),
      .FULL (full),
      .ALMOSTFULL (),
      .WRCOUNT (), .WRERR (),

      .RDCLK (clk_i),
      .RDEN (rden),
      .DO (rdata),
      .DOP (),
      .EMPTY (empty),
      .ALMOSTEMPTY (aempty),
      .RDCOUNT (), .RDERR (),

      .INJECTDBITERR (0), .INJECTSBITERR (0),
      .DBITERR (), .SBITERR (), .ECCPARITY ()
   );

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
