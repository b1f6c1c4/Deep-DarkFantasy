module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input [3:0] button_i,
   output reg [3:0] led_o,

   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

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

   wire [3:0] button_hold;
   wire [3:0] button_press;
   wire [3:0] button_release;
   button i_button (
      .clk_i (vout_clk_i),
      .button_i (~button_i),
      .button_hold_o (button_hold),
      .button_press_o (button_press),
      .button_release_o (button_release)
   );
   wire rst_n = button_i[0];

   // Gray calculation
   wire [2:0] gray;
   rgb_to_gray i_rgb_to_gray (
      .clk_i (vin_clk_i),
      .r_i(vin_data_i[23:16]),
      .g_i(vin_data_i[15:8]),
      .b_i(vin_data_i[7:0]),
      .k_o(gray)
   );

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
   wire [$clog2(HBLKS)-1:0] rht_cur;
   wire [$clog2(VBLKS)-1:0] rvt_cur;
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
      .MAX (KH * KV * 7)
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

   // Output modes
   localparam DIRECT = 3'd0;
   localparam INV = 3'd1;
   localparam BLK_DARK = 3'd2;
   localparam BLK_LIGHT = 3'd3;
   reg [2:0] oper_mode;
   always @(posedge vout_clk_i, negedge rst_n) begin
      if (~rst_n) begin
         oper_mode <= BLK_DARK;
      end else if (button_press[1]) begin
         case (oper_mode)
            DIRECT: oper_mode <= BLK_DARK;
            BLK_DARK: oper_mode <= DIRECT;
            INV: oper_mode <= BLK_LIGHT;
            BLK_LIGHT: oper_mode <= INV;
         endcase
      end else if (button_press[2]) begin
         case (oper_mode)
            DIRECT: oper_mode <= INV;
            INV: oper_mode <= DIRECT;
            BLK_DARK: oper_mode <= BLK_LIGHT;
            BLK_LIGHT: oper_mode <= BLK_DARK;
         endcase
      end
   end
   wire [2:0] oper_mode_x = ~button_hold[3] ? oper_mode : DIRECT;

   // Output selection
   reg px_inv;
   always @(*) begin
      px_inv = 0;
      case (oper_mode_x)
         DIRECT: px_inv = 0;
         INV: px_inv = 1;
         BLK_DARK: px_inv = blk_x;
         BLK_LIGHT: px_inv = ~blk_x;
      endcase
   end
   always @(*) begin
      led_o = 4'b0000;
      case (oper_mode)
         DIRECT: led_o = 4'b0000;
         INV: led_o = 4'b1000;
         BLK_DARK: led_o = 4'b0001;
         BLK_LIGHT: led_o = 4'b1001;
      endcase
   end

   // Output mix
   assign vout_data_o = {24{px_inv}} ^ vout_data_i;

endmodule
