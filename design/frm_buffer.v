module frm_buffer #(
   parameter MAX = 2
) (
   input clk_i,
   input vs_i,
   input de_i,
   input [7:0] wd_i,
   output reg rx_o
);
   localparam DEPTH = $clog2(MAX) + 1;

   reg vs_r;
   always @(posedge clk_i) begin
      vs_r <= vs_i;
   end

   wire [DEPTH-1:0] buf_a;
   double_buffer #(
      .DEPTH (DEPTH)
   ) i_double_buffer (
      .clk_i,
      .freeze_i (~vs_i && vs_r),
      .de_i,
      .wd_i,
      .buf_a (buf_a)
   );

   always @(posedge clk_i) begin
      rx_o <= buf_a >= MAX / 2;
   end

endmodule
