module rgb_to_gray (
   input clk_i,
   input [7:0] r_i,
   input [7:0] g_i,
   input [7:0] b_i,
   output reg [2:0] k_o
);

   reg [11:0] Yr_r, Yg_r, Yb_r;
   always @(*) begin
      Yr_r <= 3 * {1'b0,r_i};
      Yg_r <= 11 * {1'b0,g_i};
      Yb_r <= 1 * {1'b0,b_i};
   end

   wire [11:0] Y = Yr_r + Yg_r + Yb_r;
   always @(posedge clk_i) begin
      k_o <= Y[11:9];
   end

endmodule
