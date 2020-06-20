module repacker #(
   parameter IN = 24,
   parameter OUT = 64,
   parameter BUFF = 192
) (
   input clk_i,
   input rst_ni,

   input de_i,
   input [IN-1:0] d_i,
   output de_o,
   output [OUT-1:0] d_o
);

   reg [$clog2(BUFF)-1:0] v;
   assign de_o = de_i ? v >= OUT : |v;

   reg [BUFF-1:0] mem;
   reg [IN+BUFF-1:0] mx;
   reg [$clog2(IN+BUFF)-1:0] vx;

   always @(*) begin
      mx = {{IN{1'b0}},mem};
      vx = v;
      if (de_i) begin
         mx = mx | ({{BUFF{1'b0}},d_i} << v);
         vx = vx + IN;
      end
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         mem <= 0;
         v <= 0;
      end else if (de_o) begin
         mem <= mx >> OUT;
         v <= vx - OUT;
      end else begin
         mem <= mx[BUFF-1:0];
         v <= vx;
      end
   end

   assign d_o = mx[OUT-1:0];

endmodule
