module rgb_to_gray (
   input clk_i,
   input [7:0] r_i,
   input [7:0] g_i,
   input [7:0] b_i,
   output reg [7:0] k_o
);

   reg [16:0] Yr, Yg, Yb;
   always @(*) begin
      Yr = 109 * r_i;
      Yg = 366 * g_i;
      Yb = 37 * b_i;
   end

   wire [16:0] Y = Yr + Yg + Yb;
   always @(posedge clk_i) begin
      k_o <= Y[16:9];
   end

endmodule
