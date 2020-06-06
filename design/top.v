module top #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input clk_i_p,
   input clk_i_n,
   output reg [3:0] led_o,
   input [3:0] button_ni,

   // HDMI in
   inout vout_scl_io,
   inout vout_sda_io,
   output vout_clk_o,
   output reg vout_de_o,
   output reg vout_hs_o,
   output reg vout_vs_o,
   output reg [23:0] vout_data_o,

   // HDMI out
   inout vin_scl_io,
   inout vin_sda_io,
   input vin_clk_i,
   output vin_rst_no,
   input vin_de_i,
   input vin_hs_i,
   input vin_vs_i,
   input [23:0] vin_data_i,

   output fan_no
);

   localparam HP = H_WIDTH;
   localparam VP = V_HEIGHT;
   localparam ML = H_TOTAL - H_START;
   localparam MR = H_START - H_WIDTH;
   localparam WA = ML + HP + MR;
   localparam DELAYS = WA * KV + 5;

   wire [3:0] button_hold;
   wire [3:0] button_press;
   wire [3:0] button_release;
   button i_button (
      .clk_i (vin_clk_i),
      .button_ni (button_ni),
      .button_hold_o (button_hold),
      .button_press_o (button_press),
      .button_release_o (button_release)
   );
   wire rst_n = button_ni[0];

   assign fan_no = 0;

   wire clk_video; // 148.571MHz
   wire clk_i2c; // 100MHz
   wire pll_locked;
   sys_pll i_sys_pll (
      .clk_in1_p (clk_i_p),
      .clk_in1_n (clk_i_n),
      .reset (~rst_n),
      .clk_out1 (clk_video),
      .clk_out2 (clk_i2c),
      .locked (pll_locked)
   );

   // HDMI in
   assign vin_rst_no = 1'b1;
   sil9013 i_sil9013 (
      .clk_i (clk_i2c),
      .rst_ni (rst_n),
      .vin_scl_io,
      .vin_sda_io
   );
   reg vin_hs, vin_vs, vin_de;
   reg [23:0] vin_data;
   always @(posedge vin_clk_i) begin
      vin_hs <= vin_hs_i;
      vin_vs <= vin_vs_i;
      vin_de <= vin_de_i;
      vin_data <= vin_data_i;
   end

   // Gray calculation
   wire [7:0] gray;
   rgb_to_gray i_rgb_to_gray (
      .clk_i (vin_clk_i),
      .r_i(vin_data[23:16]),
      .g_i(vin_data[15:8]),
      .b_i(vin_data[7:0]),
      .k_o(gray)
   );

   // Vertical cursor
   reg vin_de_r;
   reg [31:0] vp_cur;
   always @(posedge vin_clk_i) begin
      if (vin_vs) begin
         vp_cur <= 0;
         vin_de_r <= 0;
      end else begin
         vin_de_r <= vin_de;
         if (~vin_de && vin_de_r) begin
            vp_cur <= (vp_cur == KV-1) ? 0 : vp_cur + 1;
         end
      end
   end

   // Blk mode
   wire blk_x;
   blk_buffer #(
      .HP (HP),
      .KH (KH),
      .MAX (KH * KV * 255)
   ) i_blk_buffer (
      .clk_i (vin_clk_i),
      .freeze_i (vp_cur == KV-1),
      .hs_i (vin_hs),
      .de_i (vin_de),
      .wd_i (gray),
      .rx_o (blk_x)
   );

   // Line mode
   wire lin_x;
   lin_buffer #(
      .MAX (HP * KV * 255)
   ) i_lin_buffer (
      .clk_i (vin_clk_i),
      .freeze_i (vp_cur == KV-1),
      .hs_i (vin_hs),
      .de_i (vin_de),
      .wd_i (gray),
      .rx_o (lin_x)
   );

   // Frame mode
   wire frm_x;
   frm_buffer #(
      .MAX (HP * VP * 255)
   ) i_frm_buffer (
      .clk_i (vin_clk_i),
      .vs_i (vin_vs),
      .de_i (vin_de),
      .wd_i (gray),
      .rx_o (frm_x)
   );

   // Extra stages
   wire [26:0] vin_delay;
   shift_reg_cas #(
      .DELAYS (DELAYS),
      .WIDTH (27)
   ) i_shift_reg (
      .clk_i (vin_clk_i),
      .d_i ({vin_hs, vin_vs, vin_de, vin_data}),
      .d_o (vin_delay)
   );

   // Output modes
   localparam DIRECT = 3'd0;
   localparam INV = 3'd1;
   localparam BLK_DARK = 3'd2;
   localparam BLK_LIGHT = 3'd3;
   localparam LIN_DARK = 3'd4;
   localparam LIN_LIGHT = 3'd5;
   localparam FRM_DARK = 3'd6;
   localparam FRM_LIGHT = 3'd7;
   reg [2:0] oper_mode;
   always @(posedge vin_clk_i, negedge rst_n) begin
      if (~rst_n) begin
         oper_mode <= BLK_DARK;
      end else if (button_press[1]) begin
         case (oper_mode)
            DIRECT: oper_mode <= BLK_DARK;
            BLK_DARK: oper_mode <= LIN_DARK;
            LIN_DARK: oper_mode <= FRM_DARK;
            FRM_DARK: oper_mode <= DIRECT;
            INV: oper_mode <= BLK_LIGHT;
            BLK_LIGHT: oper_mode <= LIN_LIGHT;
            LIN_LIGHT: oper_mode <= FRM_LIGHT;
            FRM_LIGHT: oper_mode <= INV;
         endcase
      end else if (button_press[2]) begin
         case (oper_mode)
            DIRECT: oper_mode <= INV;
            INV: oper_mode <= DIRECT;
            BLK_DARK: oper_mode <= BLK_LIGHT;
            BLK_LIGHT: oper_mode <= BLK_DARK;
            LIN_DARK: oper_mode <= LIN_LIGHT;
            LIN_LIGHT: oper_mode <= LIN_DARK;
            FRM_DARK: oper_mode <= FRM_LIGHT;
            FRM_LIGHT: oper_mode <= FRM_DARK;
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
         LIN_DARK: px_inv = lin_x;
         LIN_LIGHT: px_inv = ~lin_x;
         FRM_DARK: px_inv = frm_x;
         FRM_LIGHT: px_inv = ~frm_x;
      endcase
   end
   always @(*) begin
      led_o = 4'b0000;
      case (oper_mode)
         DIRECT: led_o = 4'b0000;
         INV: led_o = 4'b1000;
         BLK_DARK: led_o = 4'b0001;
         BLK_LIGHT: led_o = 4'b1001;
         LIN_DARK: led_o = 4'b0010;
         LIN_LIGHT: led_o = 4'b1010;
         FRM_DARK: led_o = 4'b0100;
         FRM_LIGHT: led_o = 4'b1100;
      endcase
   end

   // Output mix
   reg vout_hs, vout_vs, vout_de;
   reg [23:0] vout_data;
   always @(*) begin
      vout_hs = vin_delay[26];
      vout_vs = vin_delay[25];
      vout_de = vin_delay[24];
      vout_data = {24{px_inv}} ^ vin_delay[23:0];
   end

   // HDMI out
   adv7511 i_adv7511 (
      .clk_i (clk_i2c),
      .rst_ni (rst_n),
      .vout_scl_io,
      .vout_sda_io
   );
   assign vout_clk_o = vin_clk_i;
   always @(posedge vin_clk_i) begin
      vout_hs_o <= vout_hs;
      vout_vs_o <= vout_vs;
      vout_de_o <= vout_de;
      vout_data_o <= vout_data;
   end

endmodule
