module overlay #(
   parameter XMIN = 0,
   parameter XMAX = 0,
   parameter YMIN = 0,
   parameter YMAX = 0
) (
   input clk_i,
   input rst_ni,
   input [2:0] mode_i,

   input vin_clk_i,
   input vin_vs_i,
   input vin_de_i,

   input [23:0] data_i,
   output reg [23:0] data_o
);
   localparam HBLKS = XMAX - XMIN + 1;
   localparam VBLKS = YMAX - YMIN + 1;
   localparam BLKS = HBLKS * VBLKS;
   localparam MAX_CNT = 200000000;

   reg [7:0] rom[0:BLKS-1];
   initial begin
      $readmemh("overlay/rom.mem", rom);
   end

   reg vin_de_r;
   reg [$clog2(XMAX+1)-1:0] hc;
   reg [$clog2(YMAX+1)-1:0] vc;
   always @(posedge vin_clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         hc <= 0;
         vc <= 0;
      end else if (vin_vs_i) begin
         hc <= 0;
         vc <= 0;
      end else if (vin_de_i) begin
         hc <= hc <= XMAX ? hc + 1 : hc;
      end else if (vin_de_r && ~vin_de_i) begin
         hc <= 0;
         vc <= vc <= YMAX ? vc + 1 : vc;
      end
   end
   reg [$clog2(BLKS)-1:0] addr_r;
   reg mask_r;
   always @(posedge vin_clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         vin_de_r <= 0;
         addr_r <= 0;
         mask_r <= 0;
      end else begin
         vin_de_r <= vin_de_i;
         addr_r <= (hc - XMIN) + (vc - YMIN) * HBLKS;
         mask_r <= hc >= XMIN && hc <= XMAX && vc >= YMIN && vc <= YMAX;
      end
   end

   reg [7:0] pat_rr, pat_rrr, pat_rrrr, pat_rrrrr;
   always @(posedge vin_clk_i) begin
      if (mask_r) begin
         pat_rr <= rom[addr_r];
      end else begin
         pat_rr <= 8'b0;
      end
      {pat_rrr, pat_rrrr, pat_rrrrr} <= {pat_rr, pat_rrr, pat_rrrr};
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
