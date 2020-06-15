module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
) (
   input [3:0] button_ni,
   output reg [3:0] led_o,

   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,
   input [23:0] vin_data_i,

   output vout_clk_o,
   output reg vout_hs_o,
   output reg vout_vs_o,
   output reg vout_de_o,
   output reg [23:0] vout_data_o
);

   localparam HP = H_WIDTH;
   localparam VP = V_HEIGHT;
   localparam ML = H_TOTAL - H_START;
   localparam MR = H_START - H_WIDTH;
   localparam WA = ML + HP + MR;

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

   // HDMI in
   reg vin_hs, vin_vs, vin_de;
   reg [23:0] vin_data;
   always @(posedge vin_clk_i) begin
      vin_hs <= vin_hs_i;
      vin_vs <= vin_vs_i;
      vin_de <= vin_de_i;
      vin_data <= vin_data_i;
   end

   // Edge detection
   reg vin_vs_r, vin_hs_r, vin_de_r;
   always @(posedge vin_clk_i) begin
      vin_vs_r <= vin_vs;
      vin_hs_r <= vin_hs;
      vin_de_r <= vin_de;
   end

   // Gray calculation
   wire [2:0] gray;
   rgb_to_gray i_rgb_to_gray (
      .clk_i (vin_clk_i),
      .r_i(vin_data[23:16]),
      .g_i(vin_data[15:8]),
      .b_i(vin_data[7:0]),
      .k_o(gray)
   );

   // Tile cursor
   reg [31:0] hp_cur, ht_cur;
   reg [31:0] vp_cur, vt_cur;
   reg [31:0] tile_cur;
   always @(posedge vin_clk_i) begin
      if (vin_vs) begin
         hp_cur <= 0;
         ht_cur <= 0;
         vp_cur <= 0;
         vt_cur <= 0;
         tile_cur <= 0;
      end else if (vin_de) begin
         if (ht_cur == (HP + KH - 1) / KH) begin
            // ignore
         end else if (hp_cur == KH-1) begin
            hp_cur <= 0;
            ht_cur <= ht_cur + 1;
            tile_cur <= tile_cur + 1;
         end else begin
            hp_cur <= hp_cur + 1;
         end
      end else if (~vin_hs_r && vin_hs) begin
         hp_cur <= 0;
         ht_cur <= 0;
         if (vt_cur == (VP + KV - 1) / KV) begin
            // ignore
         end else if (vp_cur == KV-1) begin
            vp_cur <= 0;
            vt_cur <= vt_cur + 1;
            tile_cur <= tile_cur + 1;
         end else begin
            vp_cur <= vp_cur + 1;
         end
      end
   end

   // Blk mode
   wire blk_x;
   blk_buffer #(
      .BLKS (((HP + KH - 1) / KH) * ((VP + KV - 1) / KV)),
      .MAX (KH * KV * 7)
   ) i_blk_buffer (
      .clk_i (vin_clk_i),
      .tile_i (tile_cur),
      .vs_i (vin_vs),
      .vs_r_i (vin_vs_r),
      .de_i (vin_de),
      .wd_i (gray),
      .rx_o (blk_x)
   );

   // Output modes
   localparam DIRECT = 3'd0;
   localparam INV = 3'd1;
   localparam BLK_DARK = 3'd2;
   localparam BLK_LIGHT = 3'd3;
   reg [2:0] oper_mode;
   always @(posedge vin_clk_i, negedge rst_n) begin
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
   reg vout_hs, vout_vs, vout_de;
   reg [23:0] vout_data;
   always @(*) begin
      vout_hs = vin_hs;
      vout_vs = vin_vs;
      vout_de = vin_de;
      vout_data = {24{px_inv}} ^ vin_data;
   end

   // HDMI out
   assign vout_clk_o = vin_clk_i;
   always @(posedge vin_clk_i) begin
      vout_hs_o <= vout_hs;
      vout_vs_o <= vout_vs;
      vout_de_o <= vout_de;
      vout_data_o <= vout_data;
   end

endmodule
