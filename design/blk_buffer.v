module blk_buffer #(
   parameter WN = 1920,
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
   localparam BLKS = WN / KH;
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

   reg [DEPTH-1:0] blk_buf_a[0:BLKS-1];
   reg [DEPTH-1:0] blk_buf_b[0:BLKS-1];
   genvar i;
   generate
      for (i = 0; i < BLKS; i = i + 1) begin : g
         always @(posedge clk_i) begin
            if (freeze_i && hs_i && ~hs_r) begin
               blk_buf_a[i] <= blk_buf_b[i];
               blk_buf_b[i] <= 0;
            end else if (de_i && i == hb_cur) begin
               blk_buf_b[i] <= blk_buf_b[i] + {1'b0,wd_i};
            end
         end
      end
   endgenerate

   assign rx_o = blk_buf_a[hb_cur] >= MAX / 2;

endmodule
