module double_buffer #(
   parameter DEPTH = 1
) (
   input clk_i,
   input freeze_i,
   input de_i,
   input [7:0] wd_i,
   output reg [DEPTH-1:0] buf_a
);

   reg [DEPTH-1:0] buf_b;
   always @(posedge clk_i) begin
      if (freeze_i) begin
         buf_a <= buf_b;
         buf_b <= 0;
      end else if (de_i) begin
         buf_b <= buf_b + {1'b0,wd_i};
      end
   end

endmodule
