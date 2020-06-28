module overlay #(
   parameter HBLKS = 10,
   parameter VBLKS = 10
) (
   input clk_i,
   input rst_ni,
   input [2:0] mode_i,

   input vin_clk_i,
   input [$clog2(HBLKS)-1:0] ht_cur_i,
   input [$clog2(VBLKS)-1:0] vt_cur_i,
   input [23:0] data_i,
   output reg [23:0] data_o
);
   localparam BLKS = HBLKS * VBLKS;
   localparam DEPTH = $clog2(BLKS);
   localparam MAX_CNT = 200000000;

   reg [7:0] rom[0:BLKS-1];
   initial begin
      $readmemb("overlay/rom.mem", rom);
   end

   reg [7:0] pat_r, pat_rr, pat_rrr, pat_rrrr, pat_rrrrr;
   always @(posedge vin_clk_i) begin
      pat_r <= rom[ht_cur_i + HBLKS * vt_cur_i];
      pat_rr <= pat_r;
      pat_rrr <= pat_rr;
      pat_rrrr <= pat_rrr;
      pat_rrrrr <= pat_rrrr;
   end

   reg [2:0] mode;
   reg [31:0] cnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt <= 0;
         mode <= 0;
      end else if (mode != mode_i) begin
         cnt <= 0;
         mode <= mode_i;
      end else if (cnt < MAX_CNT) begin
         cnt <= cnt + 1;
      end
   end

   always @(*) begin
      data_o = data_i;
      if (cnt < MAX_CNT && pat_rrrrr[mode_i]) begin
         if (data_i[23:16] >= 8'h55) begin
            data_o[23:16] = 0;
         end else begin
            data_o[23:16] = 8'h55 - data_i[23:16];
         end
         if (data_i[15:8] >= 8'h55) begin
            data_o[15:8] = 0;
         end else begin
            data_o[15:8] = 8'h55 - data_i[15:8];
         end
         if (data_i[7:0] >= 8'h55) begin
            data_o[7:0] = 0;
         end else begin
            data_o[7:0] = 8'h55 - data_i[7:0];
         end
      end
   end

endmodule
