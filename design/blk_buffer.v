module blk_buffer #(
   parameter BLKS = 10,
   parameter MAX = 2
) (
   input clk_i,
   input [31:0] tile_i,
   input vs_i,
   input vs_r_i,
   input de_i,
   input [2:0] wd_i,
   output reg rx_o
);
   localparam DEPTH = $clog2(MAX);
   localparam THRES = MAX >= 4096 ? (~32'h1ff & MAX / 2) : MAX / 2;

   wire buf_a[0:BLKS-1];
   genvar i;
   generate
      for (i = 0; i < BLKS; i = i + 1) begin : g
         double_buffer #(
            .DEPTH (DEPTH),
            .THRES (THRES)
         ) i_double_buffer (
            .clk_i,
            .freeze_i (~vs_r_i && vs_i),
            .de_i (de_i && i == tile_i),
            .wd_i,
            .buf_a (buf_a[i])
         );
      end
   endgenerate

   always @(posedge clk_i) begin
      rx_o <= buf_a[tile_i];
   end

endmodule
