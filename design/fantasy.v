module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input [3:0] sw_i,
   output [3:0] led_o,

   output vin_hpd_o,
   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

   input vout_hpd_i,
   input vout_clk_i,
   input vout_hs_i,
   input vout_vs_i,
   input vout_de_i,
   input [23:0] vout_data_i,
   output [23:0] vout_data_o
);

   localparam HP = H_WIDTH;
   localparam VP = V_HEIGHT;
   localparam ML = H_TOTAL - H_START;
   localparam MR = H_START - H_WIDTH;
   localparam WA = ML + HP + MR;

   localparam HBLKS = (HP + KH - 1) / KH;
   localparam VBLKS = (VP + KV - 1) / KV;

   // Gray calculation
   wire [7:0] gray;
   rgb_to_gray i_rgb_to_gray (
      .clk_i (vin_clk_i),
      .r_i(vin_data_i[23:16]),
      .g_i(vin_data_i[15:8]),
      .b_i(vin_data_i[7:0]),
      .k_o(gray)
   );

   // Cursors
   wire de_fall, h_save, v_save;
   wire [31:0] ht_cur;
   wire [31:0] vt_cur;
   cursor #(
      .HP (HP),
      .VP (VP),
      .KH (KH),
      .KV (KV),
      .HBLKS (HBLKS),
      .VBLKS (VBLKS)
   ) i_cursor_in (
      .clk_i (vin_clk_i),
      .hs_i (vin_hs_i),
      .vs_i (vin_vs_i),
      .de_i (vin_de_i),

      .de_fall_o (de_fall),
      .h_save_o (h_save),
      .v_save_o (v_save),
      .ht_cur_o (ht_cur),
      .vt_cur_o (vt_cur)
   );

   wire rde_fall, rh_save;
   wire [31:0] rht_cur;
   wire [31:0] rvt_cur;
   cursor #(
      .HP (HP),
      .VP (VP),
      .KH (KH),
      .KV (KV),
      .HBLKS (HBLKS),
      .VBLKS (VBLKS)
   ) i_cursor_out (
      .clk_i (vout_clk_i),
      .hs_i (vout_hs_i),
      .vs_i (vout_vs_i),
      .de_i (vout_de_i),

      .de_fall_o (rde_fall),
      .h_save_o (rh_save),
      .v_save_o (),
      .ht_cur_o (rht_cur),
      .vt_cur_o (rvt_cur)
   );

   // Blk mode
   wire blk_x;
   blk_buffer #(
      .HBLKS (HBLKS),
      .VBLKS (VBLKS),
      .MAX (KH * KV * 255)
   ) i_blk_buffer (
      .clk_i (vin_clk_i),
      .ht_i (ht_cur),
      .vt_i (vt_cur),
      .vs_i (vin_vs_i),
      .h_save_i (h_save),
      .v_save_i (v_save),
      .de_i (vin_de_i),
      .wd_i (gray),

      .rclk_i (vout_clk_i),
      .rht_i (rht_cur),
      .rvt_i (rvt_cur),
      .rvs_i (vout_vs_i),
      .rh_save_i (rh_save),
      .rx_o (blk_x)
   );

   // Output selection
   reg px_inv;
   always @(*) begin
      px_inv = 0;
      if (sw_i[1:0] == 2'b00) begin
         px_inv = blk_x;
      end else if (sw_i[1:0] == 2'b01) begin
         px_inv = 0;
      end else if (sw_i[1:0] == 2'b10) begin
         px_inv = 1;
      end else if (sw_i[1:0] == 2'b11) begin
         px_inv = ~blk_x;
      end
   end

   // Delay monitor
   reg vin_fancy;
   always @(posedge vin_clk_i, posedge sw_i[3]) begin
      if (sw_i[3]) begin
         vin_fancy <= 0;
      end else if (vin_de_i && (vin_data_i == 24'h890604)) begin
         vin_fancy <= 1;
      end
   end
   reg vout_fancy;
   always @(posedge vout_clk_i, posedge sw_i[3]) begin
      if (sw_i[3]) begin
         vout_fancy <= 0;
      end else if (vout_de_i && (vout_data_i == 24'h890604)) begin
         vout_fancy <= 1;
      end
   end

   reg vout_vs_r;
   always @(posedge vout_clk_i) begin
      vout_vs_r <= vout_vs_i;
   end

   reg [31:0] cnt;
   always @(posedge vout_clk_i, posedge sw_i[3]) begin
      if (sw_i[3]) begin
         cnt <= 0;
      end else if (vout_vs_r && ~vout_vs_i) begin
         if (~vout_fancy && vin_fancy) begin
            if (~&cnt) begin
               cnt <= cnt + 1;
            end
         end
      end
   end
   assign led_o[3] = |cnt[31:3];
   assign led_o[2:0] = cnt[2:0];

   // Output mix
   assign vout_data_o = {24{px_inv}} ^ vout_data_i;
   assign vin_hpd_o = vout_hpd_i || sw_i[3] && ~sw_i[2];

endmodule
