module rfifo #(
   parameter WLEN = 8,
   parameter DEPTH = 24,
   parameter BURST_LEN = 16
) (
   input clk_i,
   input rst_ni,

   input in_incr_i,
   input [23:0] in_data_i,
   output reg in_rdy_o,

   input out_incr_i,
   output [23:0] out_data_o
);
   localparam LEN = 1 << WLEN;

   reg [DEPTH-1:0] mem[0:LEN-1];
   reg [WLEN-1:0] wptr, rptr;

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         wptr <= 0;
         rptr <= 0;
      end else begin
         if (in_incr_i) begin
            wptr <= wptr + 1;
         end
         if (out_incr_i) begin
            rptr <= rptr + 1;
         end
      end
   end

   always @(posedge clk_i) begin
      if (in_incr_i) begin
         mem[wptr] <= in_data_i;
      end
   end

   always @(*) begin
      if (~rst_ni) begin
         in_rdy_o = 0;
      end else if (wptr < rptr) begin
         in_rdy_o = rptr - wptr > BURST_LEN;
      end else begin
         in_rdy_o = wptr - rptr < LEN - BURST_LEN;
      end
   end

   assign out_data_o = mem[rptr];

endmodule

module wfifo #(
   parameter WLEN = 8,
   parameter DEPTH = 24,
   parameter BURST_LEN = 16
) (
   input clk_i,
   input rst_ni,

   input in_incr_i,
   input [23:0] in_data_i,

   output reg out_val_o,
   output [23:0] out_data_o,
   input out_incr_i
);
   localparam LEN = 1 << WLEN;

   reg [DEPTH-1:0] mem[0:LEN-1];
   reg [WLEN-1:0] wptr, rptr;

   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         wptr <= 0;
         rptr <= 0;
      end else begin
         if (in_incr_i) begin
            wptr <= wptr + 1;
         end
         if (out_incr_i) begin
            rptr <= rptr + 1;
         end
      end
   end

   always @(posedge clk_i) begin
      if (in_incr_i) begin
         mem[wptr] <= in_data_i;
      end
   end

   always @(*) begin
      if (~rst_ni) begin
         out_val_o = 0;
      end else if (wptr < rptr) begin
         out_val_o = rptr - wptr < LEN - BURST_LEN;
      end else begin
         out_val_o = wptr - rptr > BURST_LEN;
      end
   end

   assign out_data_o = mem[rptr];

endmodule
