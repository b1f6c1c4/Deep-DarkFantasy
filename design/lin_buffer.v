module lin_buffer #(
   parameter MAX = 2
) (
   input clk_i,
   input freeze_i,
   input hs_i,
   input de_i,
   input [7:0] wd_i,
   output rx_o
);
   localparam DEPTH = $clog2(MAX) + 1;

   reg hs_r;
   always @(posedge clk_i) begin
      hs_r <= hs_i;
   end

   wire [DEPTH-1:0] buf_a;
   double_buffer #(
      .DEPTH (DEPTH)
   ) i_double_buffer (
      .clk_i,
      .freeze_i (freeze_i && hs_i && ~hs_r),
      .de_i,
      .wd_i,
      .buf_a (buf_a)
   );

   assign rx_o = buf_a >= MAX / 2;

endmodule
