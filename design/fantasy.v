module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_T = 1400
) (
   input clk_i,
   input rst_ni,
   input [2:0] mode_i,

   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

   input [23:0] vout_data_i,
   output vout_hs_o,
   output vout_vs_o,
   output vout_de_o,
   output [23:0] vout_data_o
);

   localparam HP = H_WIDTH;
   localparam VP = V_HEIGHT;
   localparam ML = H_TOTAL - H_START;
   localparam MR = H_START - H_WIDTH;
   localparam WA = ML + HP + MR;

   localparam HBLKS = (HP + KH - 1) / KH;
   localparam VBLKS = (VP + KV - 1) / KV;

   // Cursors
   wire de_fall, h_save, v_save;
   wire [$clog2(HBLKS)-1:0] ht_cur;
   wire [$clog2(VBLKS)-1:0] vt_cur;
   cursor #(
      .HP (HP),
      .VP (VP),
      .KH (KH),
      .KV (KV),
      .HBLKS (HBLKS),
      .VBLKS (VBLKS)
   ) i_cursor_in (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),
      .hs_i (vin_hs_i),
      .vs_i (vin_vs_i),
      .de_i (vin_de_i),

      .de_fall_o (de_fall),
      .h_save_o (h_save),
      .v_save_o (v_save),
      .ht_cur_o (ht_cur),
      .vt_cur_o (vt_cur)
   );

   // Blk mode
   wire [7:0] px_C_rrr, px_L_rrr;
   wire blk_Y, blk_C, blk_L;
   blk_buffer #(
      .HBLKS (HBLKS),
      .VBLKS (VBLKS),
      .PXS (KH * KV)
   ) i_blk_buffer (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),
      .h_save_i (h_save),
      .v_save_i (v_save),
      .de_i (vin_de_i),
      .wd_i (vin_data_i),

      .px_C_rrr_o (px_C_rrr),
      .px_L_rrr_o (px_L_rrr),

      .Y_o (blk_Y),
      .C_o (blk_C),
      .L_o (blk_L)
   );
   reg blk_Y_r, blk_C_r, blk_L_r;
   reg blk_Y_rr, blk_C_rr, blk_L_rr;
   reg blk_Y_rrr, blk_C_rrr, blk_L_rrr;
   always @(posedge vin_clk_i) begin
      {blk_Y_r, blk_C_r, blk_L_r} <= {blk_Y, blk_C, blk_L};
      {blk_Y_rr, blk_C_rr, blk_L_rr} <= {blk_Y_r, blk_C_r, blk_L_r};
      {blk_Y_rrr, blk_C_rrr, blk_L_rrr} <= {blk_Y_rr, blk_C_rr, blk_L_rr};
   end

   // Mode mix
   wire [2:0] mode;
   smoother #(
      .HBLKS (HBLKS),
      .VBLKS (VBLKS),
      .SMOOTH_T (SMOOTH_T)
   ) i_smoother (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),

      .ht_cur_i (ht_cur),
      .vt_cur_i (vt_cur),

      .mode_i (mode_i),
      .mode_o (mode)
   );

   // Parameters
   reg inv_en_rrr;
   reg [29:0] shift_rrr;
   reg [17:0] gain_rrr;
   always @(*) begin
      if (mode == 0) begin // Inv
         inv_en_rrr = 1;
         shift_rrr = 0;
         gain_rrr = 32768;
      end else if (mode == 1) begin // Inv and dim
         inv_en_rrr = 1;
         shift_rrr = 0;
         gain_rrr = 21845;
      end else if (mode == 2) begin // Y-based Inv
         inv_en_rrr = blk_Y_rrr;
         shift_rrr = 0;
         gain_rrr = 32768;
      end else if (mode == 3) begin // Inv or dim
         inv_en_rrr = ~blk_C_rrr && blk_Y_rrr;
         shift_rrr = 0;
         gain_rrr = ~blk_C_rrr ? 32768 : 16384;
      end else if (mode == 4) begin // Shift and dim
         inv_en_rrr = 0;
         if (px_C_rrr < 89) begin // 0.35
            shift_rrr = blk_L_rrr ? 30'sd2 * $signed($signed(px_L_rrr) - 30'sd128) : 30'sd0;
            gain_rrr = 32768;
         end else begin
            shift_rrr = (px_L_rrr - px_C_rrr / 30'sd2) / 30'sd2;
            gain_rrr = ~blk_L_rrr ? 32768 : 21845;
         end
      end else if (mode == 5) begin // Dim
         inv_en_rrr = 0;
         shift_rrr = 0;
         gain_rrr = 13763;
      end else if (mode == 6) begin // Dim
         inv_en_rrr = 0;
         shift_rrr = 0;
         gain_rrr = 21845;
      end else begin // Pass
         inv_en_rrr = 0;
         shift_rrr = 0;
         gain_rrr = 32768;
      end
   end

   // Post process
   wire [23:0] vout_data_rrrrrr;
   post_process i_post_process (
      .rst_ni (rst_ni),

      .inv_en_rrr (inv_en_rrr),
      .shift_rrr (shift_rrr),
      .gain_rrr (gain_rrr),

      .vin_clk_i (vin_clk_i),
      .vin_hs_i (vin_hs_i),
      .vin_vs_i (vin_vs_i),
      .vin_de_i (vin_de_i),

      .vout_data_i (vout_data_i),
      .vout_hs_o (vout_hs_o),
      .vout_vs_o (vout_vs_o),
      .vout_de_o (vout_de_o),
      .vout_data_o (vout_data_rrrrrr)
   );

   // Overlay
   overlay #(
      .HBLKS (HBLKS),
      .VBLKS (VBLKS)
   ) i_overlay (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .mode_i (mode_i),

      .vin_clk_i (vin_clk_i),
      .ht_cur_i (ht_cur),
      .vt_cur_i (vt_cur),
      .data_i (vout_data_rrrrrr),
      .data_o (vout_data_o)
   );

endmodule
