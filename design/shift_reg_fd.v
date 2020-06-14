module shift_reg_fd #(
   parameter DELAYS = 2,
   parameter WIDTH = 1
) (
   input clk_i,
   input [WIDTH-1:0] d_i,
   output [WIDTH-1:0] d_o
);

   wire [WIDTH-1:0] delay[0:DELAYS-1];
   genvar i, j;
   generate
      for (i = 0; i < DELAYS; i = i + 1) begin : g
         for (j = 0; j < WIDTH; j = j + 1) begin : b
            FD d (
               .C(clk_i),
               .D((i == 0) ? d_i[j] : delay[i - 1][j]),
               .Q(delay[i][j])
            );
         end
      end
   endgenerate

   assign d_o = delay[DELAYS-1];

endmodule
