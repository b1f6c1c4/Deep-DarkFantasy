module blk_buffer #(
   parameter HP = 1920,
   parameter ML = 192,
   parameter KH = 10,
   parameter MAX = 2
) (
   input clk_i,
   input vp_last_i,
   input hs_i,
   input hs_r_i,
   input de_i,
   input de_r_i,
   input [7:0] wd_i,
   output reg rx_o
);
   localparam BLKS = (HP + KH - 1) / KH;
   localparam DEPTH = $clog2(MAX) + 1;
   localparam BD = $clog2(BLKS) + 1;
   localparam MD = $clog2(ML) + 1;

   reg [MD-1:0] ml_cnt;
   always @(posedge clk_i) begin
      if (hs_i && ~hs_r_i) begin
         ml_cnt <= ML - 1;
      end else if (~de_i && de_r_i) begin
         ml_cnt <= 0;
      end else if (|ml_cnt) begin
         ml_cnt <= ml_cnt - 1;
      end
   end

   reg [BD-1:0] h_cur, hb_cur;
   always @(posedge clk_i) begin
      if (|ml_cnt) begin
         h_cur <= 0;
         hb_cur <= 0;
      end else if (h_cur == KH-1) begin
         h_cur <= 0;
         hb_cur <= hb_cur + 1;
      end else begin
         h_cur <= h_cur + 1;
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
            .freeze_i (vp_last_i && ~de_i && de_r_i),
            .de_i (de_i && i == hb_cur),
            .wd_i,
            .buf_a (buf_a[i])
         );
      end
   endgenerate

   always @(posedge clk_i) begin
      rx_o <= buf_a[hb_cur] >= MAX / 2;
   end

endmodule
