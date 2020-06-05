module button #(
   parameter NUM = 4,
   parameter DIV = 4000000
) (
   input clk_i,
   input [NUM-1:0] button_ni,
   output reg [NUM-1:0] button_hold_o,
   output reg [NUM-1:0] button_press_o,
   output reg [NUM-1:0] button_release_o
);

   genvar i;
   generate
      for (i = 0; i < NUM; i = i + 1) begin : g
         reg last_n;
         reg [31:0] counter;
         always @(posedge clk_i) begin
            button_press_o[i] <= 0;
            button_release_o[i] <= 0;
            if (button_ni[i] ^ last_n) begin
               counter <= 0;
               last_n <= button_ni[i];
            end else if (counter == DIV) begin
               button_hold_o[i] <= ~last_n;
               button_press_o[i] <= ~last_n;
               button_release_o[i] <= last_n;
               counter <= counter + 1;
            end else begin
               counter <= counter + 1;
            end
         end
      end
   endgenerate

endmodule
