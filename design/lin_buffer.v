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

   reg [DEPTH-1:0] lin_buf_a;
   reg [DEPTH-1:0] lin_buf_b;
   always @(posedge clk_i) begin
      if (freeze_i && hs_i && ~hs_r) begin
         lin_buf_a <= lin_buf_b;
         lin_buf_b <= 0;
      end else if (de_i) begin
         lin_buf_b <= lin_buf_b + {1'b0,wd_i};
      end
   end

   assign rx_o = lin_buf_a >= MAX / 2;

endmodule
