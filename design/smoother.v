module smoother #(
   parameter HBLKS = 10,
   parameter VBLKS = 10,
   parameter SMOOTH_T = 1400
) (
   input clk_i,
   input rst_ni,

   input [$clog2(HBLKS)-1:0] ht_cur_i,
   input [$clog2(VBLKS)-1:0] vt_cur_i,

   input [2:0] mode_i,
   output reg [2:0] mode_o
);
   localparam FANTASY = SMOOTH_T * 148500;
   localparam PHASE = HBLKS / 2 + VBLKS / 2;
   localparam FAN_PHASE_DIV = FANTASY / PHASE;

   reg [$clog2(FAN_PHASE_DIV)-1:0] fc;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         fc <= 0;
      end else if (fc < FAN_PHASE_DIV - 1) begin
         fc <= fc + 1;
      end else begin
         fc <= 0;
      end
   end

   reg [2:0] modes[0:PHASE-1];
   genvar i;
   generate
      for (i = 0; i < PHASE; i = i + 1) begin : g
         always @(posedge clk_i) begin
            if (~|fc) begin
               modes[i] <= i == 0 ? mode_i : modes[i - 1];
            end
         end
      end
   endgenerate

   wire [$clog2(PHASE)-1:0] h_rel = ht_cur_i < HBLKS / 2
      ? HBLKS / 2 - ht_cur_i - 1 : ht_cur_i - HBLKS / 2;
   wire [$clog2(PHASE)-1:0] v_rel = vt_cur_i < VBLKS / 2
      ? VBLKS / 2 - vt_cur_i - 1 : vt_cur_i - VBLKS / 2;

   reg [$clog2(PHASE)-1:0] rel_r;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         rel_r <= PHASE - 1;
      end else begin
         rel_r <= h_rel + v_rel;
      end
   end

   reg [2:0] mode_rr;
   always @(posedge clk_i) begin
      {mode_rr, mode_o} <= {modes[rel_r], mode_rr};
   end

endmodule
