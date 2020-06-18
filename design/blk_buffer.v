module blk_buffer #(
   parameter HBLKS = 10,
   parameter VBLKS = 10,
   parameter MAX = 2
) (
   input clk_i,
   input [$clog2(HBLKS)-1:0] ht_i,
   input [$clog2(VBLKS)-1:0] vt_i,
   input vs_i,
   input h_save_i,
   input v_save_i,
   input de_i,
   input [7:0] wd_i,

   input rclk_i,
   input [$clog2(HBLKS)-1:0] rht_i,
   input [$clog2(VBLKS)-1:0] rvt_i,
   input rvs_i,
   input rh_save_i,
   output reg rx_o
);
   localparam DEPTH = $clog2(MAX);
   localparam THRES = MAX >= 4096 ? (~32'h1ff & MAX / 2) : MAX / 2;

   reg [VBLKS-1:0] buf_a[0:HBLKS-1];
   reg [VBLKS-1:0] mbuf_a[0:HBLKS-1];
   reg [VBLKS-1:0] r1buf_a[0:HBLKS-1];
   reg [VBLKS-1:0] r2buf_a[0:HBLKS-1];

   genvar i, j;
   generate
      for (i = 0; i < HBLKS; i = i + 1) begin : g
         reg [DEPTH-1:0] b;
         reg bt;
         wire [DEPTH-1:0] bn = b + wd_i;
         always @(posedge clk_i) begin
            if (v_save_i) begin
               b <= 0;
            end else if (i == ht_i) begin
               if (de_i) begin
                  b <= bn;
               end
               if (h_save_i) begin
                  bt <= bn > THRES;
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
