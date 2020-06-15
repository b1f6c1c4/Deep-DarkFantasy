module blk_buffer #(
   parameter HBLKS = 10,
   parameter VBLKS = 10,
   parameter MAX = 2
) (
   input clk_i,
   input [31:0] ht_i,
   input [31:0] vt_i,
   input v_save_i,
   input h_save_i,
   input de_i,
   input [2:0] wd_i,
   output reg rx_o
);
   localparam DEPTH = $clog2(MAX);
   localparam THRES = MAX >= 4096 ? (~32'h1ff & MAX / 2) : MAX / 2;

   reg [VBLKS-1:0] buf_a[0:HBLKS-1];

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
            end
         end
      end
   endgenerate

   always @(posedge clk_i) begin
      if (h_save_i) begin
         rx_o <= buf_a[ht_i + 1][vt_i];
      end else begin
         rx_o <= buf_a[ht_i][vt_i];
      end
   end

endmodule
