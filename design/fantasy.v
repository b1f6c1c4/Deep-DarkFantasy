module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input rst_ni,
   input [3:0] sw_i,
   output [3:0] led_o,

   output vin_hpd_o,
   input vout_hpd_i,

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
   wire blk_x;
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
      .rx_o (blk_x)
   );

   assign led_o[0] = blk_x;
   assign led_o[3] = vout_hpd_i;

   // Clock monitor
   reg [31:0] vin_clk_c, vout_clk_c;
   always @(posedge vin_clk_i) begin
      vin_clk_c <= vin_clk_c + 1;
   end
   assign led_o[1] = vin_clk_c[26];
   assign led_o[2] = vin_clk_c[26];

   // Output mix
   smoother i_smoother (
      .clk_i (vin_clk_i),
      .rst_ni (rst_ni),
      .dl_i (sw_i[1]),
      .ld_i (sw_i[0]),

      .vin_vs_i (vin_vs_i),
      .vin_hs_i (vin_hs_i),
      .vin_de_i (vin_de_i),
      .vin_data_i (sw_i[2] ? vin_data_i : vout_data_i),

      .ht_cur_i (ht_cur),
      .vt_cur_i (vt_cur),
      .blk_i (blk_x),

      .vout_vs_i (vout_vs_i),
      .vout_hs_i (vout_hs_i),
      .vout_de_i (vout_de_i),
      .vout_data_o (vout_data_o)
   );

   assign vin_hpd_o = vout_hpd_i || sw_i[3];

endmodule
