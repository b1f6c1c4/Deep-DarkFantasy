module blk_buffer #(
   parameter HBLKS = 10,
   parameter VBLKS = 10,
   parameter PXS = 30 * 30
) (
   input clk_i,
   input [$clog2(HBLKS)-1:0] ht_i,
   input [$clog2(VBLKS)-1:0] vt_i,
   input vs_i,
   input h_save_i,
   input v_save_i,
   input de_i,
   input [23:0] wd_i,

   input rclk_i,
   input [$clog2(HBLKS)-1:0] rht_i,
   input [$clog2(VBLKS)-1:0] rvt_i,
   input rvs_i,
   input rh_save_i,
   output reg rx_o
);
   localparam DEPTH = $clog2(PXS * 255);
   localparam THRES = PXS * 128;

   reg [VBLKS-1:0] buf_a[0:HBLKS-1];
   reg [VBLKS-1:0] mbuf_a[0:HBLKS-1];
   reg [VBLKS-1:0] r1buf_a[0:HBLKS-1];
   reg [VBLKS-1:0] r2buf_a[0:HBLKS-1];

   reg [$clog2(HBLKS)-1:0] ht_r, ht_rr, ht_rrr;
   reg h_save_r, h_save_rr, h_save_rrr;
   reg de_r, de_rr;
   reg [23:0] wd_r;
   always @(posedge clk_i) begin
      ht_r <= ht_i;
      h_save_r <= h_save_i;
      de_r <= de_i;
      wd_r <= wd_i;

      ht_rr <= ht_r;
      h_save_rr <= h_save_r;
      de_rr <= de_r;

      ht_rrr <= ht_rr;
      h_save_rrr <= h_save_rr;
   end

   reg [DEPTH-1:0] br[0:HBLKS-1], bg[0:HBLKS-1], bb[0:HBLKS-1];
   reg [DEPTH-1:0] br_r, bg_r, bb_r;
   reg [DEPTH-1:0] brf_r, bgf_r, bbf_r;
   reg [DEPTH-1:0] br_rr, bg_rr, bb_rr;
   reg bt_rrr;
   always @(*) begin
      if (de_rr && !h_save_rr) begin
         brf_r = br_rr;
         bgf_r = bg_rr;
         bbf_r = bb_rr;
      end else begin
         brf_r = br_r;
         bgf_r = bg_r;
         bbf_r = bb_r;
      end
   end
   always @(posedge clk_i) begin
      br_r <= br[ht_i];
      bg_r <= bg[ht_i];
      bb_r <= bb[ht_i];

      br_rr <= brf_r + 109 * wd_r[23:16];
      bg_rr <= bgf_r + 366 * wd_r[15:8];
      bb_rr <= bbf_r + 37 * wd_r[7:0];

      bt_rrr <= (br_rr + bg_rr + bb_rr) >= THRES;
   end

   genvar i, j;
   generate
      for (i = 0; i < HBLKS; i = i + 1) begin : g
         reg bt;
         always @(posedge clk_i) begin
            if (v_save_i) begin
               br[i] <= 0;
               bg[i] <= 0;
               bb[i] <= 0;
            end else begin
               if (i == ht_rr && de_rr) begin
                  br[i] <= br_rr;
                  bg[i] <= bg_rr;
                  bb[i] <= bb_rr;
               end
               if (i == ht_rrr && h_save_rrr) begin
                  bt <= bt_rrr;
               end
            end
         end
         for (j = 0; j < VBLKS; j = j + 1) begin : v
            always @(posedge clk_i) begin
               if (v_save_i && j == vt_i) begin
                  buf_a[i][j] <= bt;
               end
               if (vs_i) begin
                  mbuf_a[i][j] <= buf_a[i][j];
               end
            end
            always @(posedge rclk_i) begin
               if (rvs_i) begin
                  r1buf_a[i][j] <= mbuf_a[i][j];
                  r2buf_a[i][j] <= r1buf_a[i][j];
               end
            end
         end
      end
   endgenerate

   always @(posedge rclk_i) begin
      if (rh_save_i) begin
         rx_o <= r2buf_a[rht_i + 1][rvt_i];
      end else begin
         rx_o <= r2buf_a[rht_i][rvt_i];
      end
   end

endmodule
