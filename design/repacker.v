module repacker #(
   parameter IN = 24,
   parameter OUT = 64,
   parameter BUFF = 192
) (
   input clk_i,
   input rst_ni,

   input in_val_i,
   input [IN-1:0] in_data_i,
   output in_rdy_o,

   output out_val_o,
   output [OUT-1:0] out_data_o,
   input out_rdy_i
);

   wire push = in_val_i && in_rdy_o;
   wire pop = out_val_o && out_rdy_i;

   reg [$clog2(BUFF)-1:0] v;
   assign out_val_o = push ? v >= OUT - 1 : v >= OUT;
   assign in_rdy_o = v + IN <= BUFF;

   reg [BUFF-1:0] mem;
   reg [IN+BUFF-1:0] mx;
   reg [$clog2(IN+BUFF)-1:0] vx;

   always @(*) begin
      mx = {{IN{1'b0}},mem};
      vx = v;
      if (push) begin
         mx = mx | ({{BUFF{1'b0}},in_data_i} << v);
         vx = vx + IN;
      end
   end

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         mem <= 0;
         v <= 0;
      end else if (pop) begin
         mem <= mx >> OUT;
         v <= vx - OUT;
      end else begin
         mem <= mx[BUFF-1:0];
         v <= vx;
      end
   end

   assign out_data_o = mx[OUT-1:0];

endmodule
