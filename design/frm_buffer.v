module frm_buffer #(
   parameter MAX = 2
) (
   input clk_i,
   input vs_i,
   input de_i,
   input [7:0] wd_i,
   output rx_o
);
   localparam DEPTH = $clog2(MAX) + 1;

   reg vs_r;
   always @(posedge clk_i) begin
      vs_r <= vs_i;
   end

   reg [DEPTH-1:0] frm_buf_a;
   reg [DEPTH-1:0] frm_buf_b;
   always @(posedge clk_i) begin
      if (~vs_i && vs_r) begin
         frm_buf_a <= frm_buf_b;
         frm_buf_b <= 0;
      end else if (de_i) begin
         frm_buf_b <= frm_buf_b + {1'b0,wd_i};
      end
   end

   assign rx_o = frm_buf_a >= MAX / 2;

endmodule
