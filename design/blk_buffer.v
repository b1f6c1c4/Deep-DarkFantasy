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
   reg [$clog2(VBLKS)-1:0] vt_r, vt_rr, vt_rrr;
   reg h_save_r, h_save_rr, h_save_rrr;
   reg v_save_r, v_save_rr, v_save_rrr;
   reg de_r, de_rr;
   reg [23:0] wd_r;
   always @(posedge clk_i) begin
      ht_r <= ht_i;
      vt_r <= vt_i;
      h_save_r <= h_save_i;
      v_save_r <= v_save_i;
      de_r <= de_i;
      wd_r <= wd_i;

      ht_rr <= ht_r;
      vt_rr <= vt_r;
      h_save_rr <= h_save_r;
      v_save_rr <= v_save_r;
      de_rr <= de_r;

      ht_rrr <= ht_rr;
      vt_rrr <= vt_rr;
      h_save_rrr <= h_save_rr;
      v_save_rrr <= v_save_rr;
   end

   reg [3*DEPTH-1:0] brgb[0:HBLKS-1];
   reg bt[0:HBLKS-1];

   wire [3*DEPTH-1:0] b0n;
   assign b0n[3*DEPTH-1:2*DEPTH] = brgb[0][3*DEPTH-1:2*DEPTH] + 109 * wd_i[23:16];
   assign b0n[2*DEPTH-1:1*DEPTH] = brgb[0][2*DEPTH-1:1*DEPTH] + 366 * wd_i[15:8];
   assign b0n[1*DEPTH-1:0*DEPTH] = brgb[0][1*DEPTH-1:0*DEPTH] + 37 * wd_i[7:0];
   wire [DEPTH-1:0] bzr = brgb[HBLKS-1][3*DEPTH-1:2*DEPTH];
   wire [DEPTH-1:0] bzg = brgb[HBLKS-1][2*DEPTH-1:1*DEPTH];
   wire [DEPTH-1:0] bzb = brgb[HBLKS-1][1*DEPTH-1:0*DEPTH];

   genvar i, j;
   generate
      for (i = 0; i < HBLKS; i = i + 1) begin : g
         always @(posedge clk_i) begin
            if (v_save_i) begin
               brgb[i] <= 0;
            end else if (h_save_i) begin
               brgb[i] <= (i == HBLKS - 1) ? b0n : brgb[i + 1];
            end else if (i == 0 && de_i) begin
               brgb[i] <= b0n;
            end
         end
         always @(posedge clk_i) begin
            if (h_save_r) begin
               if (i == HBLKS - 1) begin
                  bt[i] <= (bzr + bzg + bzg) >= THRES;
               end else begin
                  bt[i] <= bt[i + 1];
               end
            end
         end
         for (j = 0; j < VBLKS; j = j + 1) begin : v
            always @(posedge clk_i) begin
               if (v_save_rr && j == vt_rr) begin
                  buf_a[i][j] <= bt[i];
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
