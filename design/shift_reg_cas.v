module shift_reg_cas #(
   parameter DELAYS = 2,
   parameter WIDTH = 1
) (
   input clk_i,
   input [WIDTH-1:0] d_i,
   output [WIDTH-1:0] d_o
);
   localparam EACH = 256;
   localparam STAGES = (DELAYS + EACH - 1) / EACH;

   wire [WIDTH-1:0] d[0:STAGES-1];
   assign d[0] = d_i;
   genvar i;
   generate
      for (i = 0; i < STAGES - 1; i = i + 1) begin : g
         if (i % 7 == 0) begin
            shift_reg_fd #(
               .DELAYS (EACH),
               .WIDTH (WIDTH)
            ) i_shift_reg (
               .clk_i (clk_i),
               .d_i (d[i]),
               .d_o (d[i+1])
            );
         end else begin
            shift_reg #(
               .DELAYS (EACH),
               .WIDTH (WIDTH)
            ) i_shift_reg (
               .clk_i (clk_i),
               .d_i (d[i]),
               .d_o (d[i+1])
            );
         end
      end
   endgenerate
   shift_reg #(
      .DELAYS (DELAYS - (STAGES - 1) * EACH),
      .WIDTH (WIDTH)
   ) i_shift_reg (
      .clk_i (clk_i),
      .d_i (d[STAGES-1]),
      .d_o (d_o)
   );

endmodule
