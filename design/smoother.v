module smoother #(
   parameter HBLKS = 10,
   parameter VBLKS = 10
) (
   input clk_i,
   input rst_ni,
   input dl_i,
   input ld_i,

   input vin_vs_i,
   input vin_hs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

   input [$clog2(HBLKS)-1:0] ht_cur_i,
   input [$clog2(VBLKS)-1:0] vt_cur_i,
   input blk_i,

   output vout_vs_o,
   output vout_hs_o,
   output vout_de_o,
   output [23:0] vout_data_o
);
   localparam SW_DELAY = 125 * 148500;
   localparam FANTASY = 1400 * 148500;
   localparam FAN_W = 6;
   localparam FAN_WIDTH = 2**FAN_W / 2;
   localparam PHASE = (HBLKS / 2 + VBLKS / 2 + 2 * FAN_WIDTH) * 256;
   localparam FAN_PHASE_DIV = FANTASY / PHASE;

   reg dl_en, ld_en; // Fantasy target
   reg dl_px, ld_px; // Delay phase
   reg [$clog2(SW_DELAY)-1:0] dl_pc, ld_pc;
   reg dl_fx, ld_fx; // Fantasy phases
   reg [$clog2(PHASE)-1:0] dl_fp, ld_fp; // Fantasy phase counter
   reg [$clog2(FAN_PHASE_DIV)-1:0] dl_fc, ld_fc; // Fantasy phase clock div counter
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         dl_en <= 0;
         dl_px <= 0;
         dl_pc <= 0;
         dl_fx <= 0;
         dl_fp <= 0;
         dl_fc <= 0;
      end else begin
         if (dl_fx) begin
            if (dl_fc < FAN_PHASE_DIV - 1) begin
               dl_fc <= dl_fc + 1;
            end else if (dl_fp < PHASE - 1) begin
               dl_fp <= dl_fp + 1;
               dl_fc <= 0;
            end else begin // leave fantasy phase
               dl_fx <= 0;
               dl_fp <= 0;
               dl_fc <= 0;
            end
         end
         if (dl_px) begin
            if (dl_en != dl_i) begin
               if (dl_pc < SW_DELAY - 1) begin
                  dl_pc <= dl_pc + 1;
               end else if (dl_fx) begin // cancel fantasy phase
                  dl_en <= dl_i;
                  dl_px <= 0;
                  dl_pc <= 0;
                  dl_fx <= 0;
                  dl_fp <= 0;
                  dl_fc <= 0;
               end else begin // enter fantasy phase
                  dl_en <= dl_i;
                  dl_px <= 0;
                  dl_pc <= 0;
                  dl_fx <= 1;
               end
            end else begin // cancel delay phase
               dl_px <= 0;
               dl_pc <= 0;
            end
         end else if (~dl_fx) begin
            if (dl_en != dl_i) begin
               dl_px <= 1;
               dl_pc <= 0;
            end
         end
      end
   end
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         ld_en <= 0;
         ld_px <= 0;
         ld_fx <= 0;
         ld_pc <= 0;
         ld_fp <= 0;
         ld_fc <= 0;
      end else begin
         if (ld_fx) begin
            if (ld_fc < FAN_PHASE_DIV - 1) begin
               ld_fc <= ld_fc + 1;
            end else if (ld_fp < PHASE - 1) begin
               ld_fp <= ld_fp + 1;
               ld_fc <= 0;
            end else begin // leave fantasy phase
               ld_fx <= 0;
               ld_fp <= 0;
               ld_fc <= 0;
            end
         end
         if (ld_px) begin
            if (ld_en != ld_i) begin
               if (ld_pc < SW_DELAY - 1) begin
                  ld_pc <= ld_pc + 1;
               end else if (ld_fx) begin // cancel fantasy phase
                  ld_en <= ld_i;
                  ld_px <= 0;
                  ld_pc <= 0;
                  ld_fx <= 0;
                  ld_fp <= 0;
                  ld_fc <= 0;
               end else begin // enter fantasy phase
                  ld_en <= ld_i;
                  ld_px <= 0;
                  ld_pc <= 0;
                  ld_fx <= 1;
               end
            end else begin // cancel delay phase
               ld_px <= 0;
               ld_pc <= 0;
            end
         end else if (~ld_fx) begin
            if (ld_en != ld_i) begin
               ld_px <= 1;
               ld_pc <= 0;
            end
         end
      end
   end

   reg [7:0] dl_fpl_r, ld_fpl_r;
   always @(posedge clk_i) begin
      dl_fpl_r <= dl_fp[7:0];
      ld_fpl_r <= ld_fp[7:0];
   end

   reg [$clog2(PHASE)-1:0] dl_rel, ld_rel;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         dl_rel <= {1'b0,{($clog2(PHASE)-1){1'b1}}};
      end else if (~dl_fx) begin
         dl_rel <= {1'b0,{($clog2(PHASE)-1){1'b1}}};
      end else if (ht_cur_i < HBLKS / 2) begin
         if (vt_cur_i < VBLKS / 2) begin
            dl_rel <= (dl_fp >> 8) + ht_cur_i - HBLKS / 2 + vt_cur_i - VBLKS / 2;
         end else begin
            dl_rel <= (dl_fp >> 8) + ht_cur_i - HBLKS / 2 - vt_cur_i + VBLKS / 2;
         end
      end else begin
         if (vt_cur_i < VBLKS / 2) begin
            dl_rel <= (dl_fp >> 8) - ht_cur_i + HBLKS / 2 + vt_cur_i - VBLKS / 2;
         end else begin
            dl_rel <= (dl_fp >> 8) - ht_cur_i + HBLKS / 2 - vt_cur_i + VBLKS / 2;
         end
      end
   end
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         ld_rel <= {1'b0,{($clog2(PHASE)-1){1'b1}}};
      end else if (~ld_fx) begin
         ld_rel <= {1'b0,{($clog2(PHASE)-1){1'b1}}};
      end else if (ht_cur_i < HBLKS / 2) begin
         if (vt_cur_i < VBLKS / 2) begin
            ld_rel <= (ld_fp >> 8) + ht_cur_i - HBLKS / 2 + vt_cur_i - VBLKS / 2;
         end else begin
            ld_rel <= (ld_fp >> 8) + ht_cur_i - HBLKS / 2 - vt_cur_i + VBLKS / 2;
         end
      end else begin
         if (vt_cur_i < VBLKS / 2) begin
            ld_rel <= (ld_fp >> 8) - ht_cur_i + HBLKS / 2 + vt_cur_i - VBLKS / 2;
         end else begin
            ld_rel <= (ld_fp >> 8) - ht_cur_i + HBLKS / 2 - vt_cur_i + VBLKS / 2;
         end
      end
   end

   reg [7:0] dl_phx, ld_phx;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         dl_phx <= 8'hff;
      end else if (dl_rel[$clog2(PHASE)-1]) begin
         dl_phx <= 8'h00;
      end else if (dl_rel >= 2 * FAN_WIDTH) begin
         dl_phx <= 8'hff;
      end else begin
         dl_phx <= {dl_rel,dl_fpl_r} >> FAN_W;
      end
   end
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         ld_phx <= 8'hff;
      end else if (ld_rel[$clog2(PHASE)-1]) begin
         ld_phx <= 8'h00;
      end else if (ld_rel >= 2 * FAN_WIDTH) begin
         ld_phx <= 8'hff;
      end else begin
         ld_phx <= {ld_rel,ld_fpl_r} >> FAN_W;
      end
   end

   reg blk_r, blk_rr;
   always @(posedge clk_i) begin
      blk_r <= blk_i;
      blk_rr <= blk_r;
   end

   reg l_inv, d_inv;
   reg [7:0] l_ctrl, d_ctrl;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         l_inv <= 0;
         d_inv <= 0;
         l_ctrl <= 255;
         d_ctrl <= 0;
      end else if (~blk_rr) begin // this is a dark block
         if (dl_en) begin // dark (non-inv) -> light (inv)
            l_inv <= dl_phx >= 64;
            d_inv <= dl_phx >= 192;
            if (dl_phx < 128) begin
               l_ctrl <= (127 - dl_phx) * 2 + 1;
               d_ctrl <= 0;
            end else begin
               l_ctrl <= 0;
               d_ctrl <= (dl_phx - 128) * 2 + 1;
            end
         end else begin // light (inv) -> dark (non-inv)
            l_inv <= dl_phx < 64;
            d_inv <= dl_phx < 192;
            if (dl_phx < 128) begin
               l_ctrl <= dl_phx * 2;
               d_ctrl <= 255;
            end else begin
               l_ctrl <= 255;
               d_ctrl <= 255 - (dl_phx - 128) * 2 - 1;
            end
         end
      end else begin // this is a light block
         if (ld_en) begin // dark (inv) -> light (non-inv)
            l_inv <= ld_phx < 192;
            d_inv <= ld_phx < 64;
            if (ld_phx < 128) begin
               l_ctrl <= 0;
               d_ctrl <= 255 - ld_phx * 2;
            end else begin
               l_ctrl <= (ld_phx - 128) * 2 + 1;
               d_ctrl <= 0;
            end
         end else begin // light (non-inv) -> dark (inv)
            l_inv <= ld_phx >= 192;
            d_inv <= ld_phx >= 64;
            if (ld_phx < 128) begin
               l_ctrl <= 255;
               d_ctrl <= ld_phx * 2;
            end else begin
               l_ctrl <= 255 - (ld_phx - 128) * 2 - 1;
               d_ctrl <= 255;
            end
         end
      end
   end

   reg vs_r, vs_rr, vs_rrr, vs_rrrr;
   reg hs_r, hs_rr, hs_rrr, hs_rrrr;
   reg de_r, de_rr, de_rrr, de_rrrr;
   reg [23:0] data_r, data_rr, data_rrr;
   always @(posedge clk_i) begin
      vs_r <= vin_vs_i;
      hs_r <= vin_hs_i;
      de_r <= vin_de_i;
      data_r <= vin_data_i;

      vs_rr <= vs_r;
      hs_rr <= hs_r;
      de_rr <= de_r;
      data_rr <= data_r;

      vs_rrr <= vs_rr;
      hs_rrr <= hs_rr;
      de_rrr <= de_rr;
      data_rrr <= data_rr;

      vs_rrrr <= vs_rrr;
      hs_rrrr <= hs_rrr;
      de_rrrr <= de_rrr;
   end

   reg [23:0] data_o;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         data_o <= 24'h808080;
      end else begin
         if (data_rrr[23:16] >= 128) begin
            data_o[23:16] <= {8{l_inv}} ^ data_rrr[23:16];
            if (~l_inv && (data_rrr[23:16] > l_ctrl)) begin
               data_o[23:16] <= l_ctrl;
            end else if (l_inv && (~data_rrr[23:16] < l_ctrl)) begin
               data_o[23:16] <= l_ctrl;
            end
         end else begin
            data_o[23:16] <= {8{d_inv}} ^ data_rrr[23:16];
            if (~d_inv && (data_rrr[23:16] < d_ctrl)) begin
               data_o[23:16] <= d_ctrl;
            end else if (d_inv && (~data_rrr[23:16] > d_ctrl)) begin
               data_o[23:16] <= d_ctrl;
            end
         end
         if (data_rrr[15:8] >= 128) begin
            data_o[15:8] <= {8{l_inv}} ^ data_rrr[15:8];
            if (~l_inv && (data_rrr[15:8] > l_ctrl)) begin
               data_o[15:8] <= l_ctrl;
            end else if (l_inv && (~data_rrr[15:8] < l_ctrl)) begin
               data_o[15:8] <= l_ctrl;
            end
         end else begin
            data_o[15:8] <= {8{d_inv}} ^ data_rrr[15:8];
            if (~d_inv && (data_rrr[15:8] < d_ctrl)) begin
               data_o[15:8] <= d_ctrl;
            end else if (d_inv && (~data_rrr[15:8] > d_ctrl)) begin
               data_o[15:8] <= d_ctrl;
            end
         end
         if (data_rrr[7:0] >= 128) begin
            data_o[7:0] <= {8{l_inv}} ^ data_rrr[7:0];
            if (~l_inv && (data_rrr[7:0] > l_ctrl)) begin
               data_o[7:0] <= l_ctrl;
            end else if (l_inv && (~data_rrr[7:0] < l_ctrl)) begin
               data_o[7:0] <= l_ctrl;
            end
         end else begin
            data_o[7:0] <= {8{d_inv}} ^ data_rrr[7:0];
            if (~d_inv && (data_rrr[7:0] < d_ctrl)) begin
               data_o[7:0] <= d_ctrl;
            end else if (d_inv && (~data_rrr[7:0] > d_ctrl)) begin
               data_o[7:0] <= d_ctrl;
            end
         end
      end
   end

   assign vout_vs_o = vs_rrrr;
   assign vout_hs_o = hs_rrrr;
   assign vout_de_o = de_rrrr;
   assign vout_data_o = data_o;

endmodule
