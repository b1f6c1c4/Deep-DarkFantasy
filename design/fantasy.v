module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_W = 6,
   parameter SMOOTH_T = 1400
) (
   input rst_ni,
   input [1:0] mode_i,

   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

   input [23:0] vout_data_i,
   output vout_hs_o,
   output vout_vs_o,
   output vout_de_o,
   output [23:0] vout_data_o,

   output blk_y_o
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
      .rx_o (blk_y_o)
   );

   // Output mix
   smoother #(
      .HBLKS (HBLKS),
      .VBLKS (VBLKS),
      .SMOOTH_W (SMOOTH_W),
      .SMOOTH_T (SMOOTH_T)
   ) i_smoother (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),
      .dl_i (mode_i[1] ^ mode_i[0]),
      .ld_i (mode_i[0]),

      .vin_vs_i (vin_vs_i),
      .vin_hs_i (vin_hs_i),
      .vin_de_i (vin_de_i),
      .vin_data_i (vout_data_i),

      .ht_cur_i (ht_cur),
      .vt_cur_i (vt_cur),
      .blk_i (blk_y_o),

      .vout_vs_o (vout_vs_o),
      .vout_hs_o (vout_hs_o),
      .vout_de_o (vout_de_o),
      .vout_data_o (vout_data_o)
   );

endmodule
