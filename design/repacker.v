module repacker #(
   parameter IN = 3,
   parameter OUT = 8,
   parameter W = 8
) (
   input clk_i,
   input rst_ni,
   input srst_i,

   input in_val_i,
   input [W*IN-1:0] in_data_i,
   output in_rdy_o,

   output out_val_o,
   output [W*OUT-1:0] out_data_o,
   input out_rdy_i
);
   localparam BUFF = IN + OUT - 1;

   wire push = in_val_i && in_rdy_o;
   wire pop = out_val_o && out_rdy_i;

   reg [$clog2(BUFF+IN+1)-1:0] v;

   assign in_rdy_o = pop ? v + IN <= BUFF + OUT : v + IN <= BUFF;
   assign out_val_o = v >= OUT;

   reg [W-1:0] mem[0:BUFF-1];
   reg [W-1:0] mx[0:IN+BUFF-1];

   genvar i;
   generate
      for (i = 0; i < IN + BUFF; i = i + 1) begin : gi
         always @(*) begin
            if (v <= i && i < v + IN && push) begin
               mx[i] = in_data_i >> (W*(i - v));
            end else if (i < BUFF && i < v) begin
               mx[i] = mem[i];
            end else begin
               mx[i] = 0;
            end
         end
      end
      for (i = 0; i < BUFF; i = i + 1) begin : gm
         always @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
               mem[i] <= 0;
            end else if (srst_i) begin
               mem[i] <= 0;
            end else if (pop) begin
               if (i + OUT < IN + BUFF) begin
                  mem[i] <= mx[i + OUT];
               end else begin
                  mem[i] <= 0;
               end
            end else begin
               mem[i] <= mx[i];
            end
         end
      end
      for (i = 0; i < OUT; i = i + 1) begin : go
         assign out_data_o[W*i+W-1:W*i] = mem[i];
      end
   endgenerate

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         v <= 0;
      end else if (srst_i) begin
         v <= 0;
      end else begin
         v <= v + (push ? IN : 0) - (pop ? OUT : 0);
      end
   end

endmodule
