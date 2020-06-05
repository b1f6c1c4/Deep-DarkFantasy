module blk_buffer #(
   parameter HP = 1920,
   parameter KH = 10,
   parameter MAX = 2
) (
   input clk_i,
   input freeze_i,
   input hs_i,
   input de_i,
   input [7:0] wd_i,
   output rx_o
);
   localparam BLKS = HP / KH;
   localparam DEPTH = $clog2(MAX) + 1;

   reg hs_r, de_r;
   reg [31:0] h_cur, hb_cur;
   always @(posedge clk_i) begin
      hs_r <= hs_i;
      de_r <= de_i;
      if (~de_i && de_r) begin
         h_cur <= 0;
         hb_cur <= 0;
      end else if (de_i) begin
         if (h_cur == KH-1) begin
            h_cur <= 0;
            hb_cur <= hb_cur + 1;
         end else begin
            h_cur <= h_cur + 1;
         end
      end
   end

   wire [DEPTH-1:0] buf_a[0:BLKS-1];
   genvar i;
   generate
      for (i = 0; i < BLKS; i = i + 1) begin : g
         double_buffer #(
            .DEPTH (DEPTH)
         ) i_double_buffer (
            .clk_i,
            .freeze_i (freeze_i && hs_i && ~hs_r),
            .de_i (de_i && i == hb_cur),
            .wd_i,
            .buf_a (buf_a[i])
         );
      end
   endgenerate

   assign rx_o = buf_a[hb_cur] >= MAX / 2;

endmodule
