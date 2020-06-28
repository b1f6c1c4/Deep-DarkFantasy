module overlay #(
   parameter WIDTH = 1,
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
   localparam WN = 8 << WIDTH;
   localparam WORDS = (BLKS + WIDTH - 1) / WIDTH;
   localparam MAX_CNT = 200000000;

   reg [WN-1:0] rom[0:WORDS-1];
   initial begin
      $readmemh("overlay/rom.mem", rom);
   end

   reg vin_de_r;
   reg [$clog2(XMAX+2)-1:0] hc;
   reg [$clog2(YMAX+2)-1:0] vc;
   wire hcen = hc >= XMIN && hc <= XMAX;
   wire vcen = vc >= YMIN && vc <= YMAX;
   wire mask = hcen && vcen && vin_de_i;
   reg [$clog2(BLKS)-1:0] addr;
   always @(posedge vin_clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         hc <= 0;
         vc <= 0;
         addr <= 0;
      end else if (vin_vs_i) begin
         hc <= 0;
         vc <= 0;
         addr <= 0;
      end else if (vin_de_i) begin
         hc <= hc <= XMAX ? hc + 1 : hc;
         if (mask) begin
            addr <= addr + 1;
         end
      end else if (vin_de_r && ~vin_de_i) begin
         hc <= 0;
         vc <= vc <= YMAX ? vc + 1 : vc;
      end
   end
   reg mask_r, mask_rr, mask_rrr;
   reg [$clog2(WORDS)-1:0] waddr_r, waddr_rr;
   reg [$clog2(WIDTH)-1:0] baddr_r, baddr_rr, baddr_rrr;
   reg [WN-1:0] pat_rrr;
   reg [7:0] pat_rrrr, pat_rrrrr;
   always @(posedge vin_clk_i) begin
      vin_de_r <= vin_de_i;
      mask_r <= mask;
      mask_rr <= mask_r;
      mask_rrr <= mask_rr;
      waddr_rr <= waddr_r;
      baddr_rr <= baddr_r;
      baddr_rrr <= baddr_rr;
      if (mask_rr) begin
         pat_rrr <= rom[waddr_rr];
      end
      pat_rrrrr <= pat_rrrr;
   end
   always @(posedge vin_clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         waddr_r <= 0;
         baddr_r <= 0;
         pat_rrrr <= 8'b0;
      end else begin
         if (mask) begin
            waddr_r <= addr / WIDTH;
            baddr_r <= addr % WIDTH;
         end
         if (mask_rrr) begin
            pat_rrrr <= pat_rrr >> (8 * (WIDTH - baddr_rrr - 1));
         end else begin
            pat_rrrr <= 8'b0;
         end
      end
   end

   reg [31:0] cnt;
   (* mark_debug = "true" *) reg [2:0] mode;
   (* mark_debug = "true" *) reg en;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt <= 0;
         mode <= 0;
         en <= 1;
      end else if (mode != mode_i) begin
         cnt <= 0;
         mode <= mode_i;
         en <= 1;
      end else if (cnt < MAX_CNT) begin
         cnt <= cnt + 1;
         en <= 1;
      end else begin
         en <= 0;
      end
   end

   always @(*) begin
      data_o = data_i;
      if (en && pat_rrrrr[mode]) begin
         if (data_i[23:16] >= 128) begin
            data_o[23:16] = data_i[23:16] - 128;
         end else begin
            data_o[23:16] = 127 - data_i[23:16];
         end
         if (data_i[15:8] >= 128) begin
            data_o[15:8] = data_i[15:8] - 128;
         end else begin
            data_o[15:8] = 127 - data_i[15:8];
         end
         if (data_i[7:0] >= 128) begin
            data_o[7:0] = data_i[7:0] - 128;
         end else begin
            data_o[7:0] = 127 - data_i[7:0];
         end
      end
   end

endmodule
