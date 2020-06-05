module top(
   input clk_i_p,
   input clk_i_n,
   output [3:0] led_o,
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

   localparam ML = 192;
   localparam WN = 1920;
   localparam MR = 88;
   localparam WA = ML + WN + MR;

   localparam KH = 20;
   localparam KV = 10;

   localparam DELAYS = WA * KV;

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
   assign vin_rst_no = rst_n;
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
      .r_i(vin_data[23:16]),
      .g_i(vin_data[15:8]),
      .b_i(vin_data[7:0]),
      .k_o(gray)
   );

   // Block buffer
   reg vin_hs_r, vin_de_r;
   reg [31:0] h_cur, hb_cur, vp_cur;
   always @(posedge vin_clk_i) begin
      if (vin_vs) begin
         h_cur <= 0;
         hb_cur <= 0;
         vp_cur <= 0;
         vin_hs_r <= 0;
         vin_de_r <= 0;
      end else begin
         vin_hs_r <= vin_hs;
         vin_de_r <= vin_de;
         if (~vin_de && vin_de_r) begin
            h_cur <= 0;
            hb_cur <= 0;
            vp_cur <= (vp_cur == KV-1) ? 0 : vp_cur + 1;
         end else if (vin_de) begin
            if (h_cur == KH-1) begin
               h_cur <= 0;
               hb_cur <= hb_cur + 1;
            end else begin
               h_cur <= h_cur + 1;
            end
         end
      end
   end

   reg [31:0] blk_buf_a[0:WN/KH-1];
   reg [31:0] blk_buf_b[0:WN/KH-1];
   genvar i;
   generate
      for (i = 0; i < WN/KH; i = i + 1) begin : gen_buffer
         always @(posedge vin_clk_i) begin
            if (vin_hs && ~vin_hs_r && vp_cur == KV-1) begin
               blk_buf_a[i] <= blk_buf_b[i];
               blk_buf_b[i] <= 0;
            end else if (vin_de && i == hb_cur) begin
               blk_buf_b[i] <= blk_buf_b[i] + {1'b0,gray};
            end
         end
      end
   endgenerate

   // Extra stages
   reg [26:0] delay[0:DELAYS-1];
   generate
      for (i = 0; i < DELAYS; i = i + 1) begin : gen_delay
         always @(posedge vin_clk_i) begin
            delay[i] <= (i == 0) ? {vin_hs, vin_vs, vin_de, vin_data} : delay[i - 1];
         end
      end
   endgenerate

   // Output selection
   wire [31:0] active_blk = blk_buf_a[hb_cur];
   wire active_light = active_blk > (KH * KV * 255 / 2);
   wire [26:0] active_delay = button_ni[1] ? delay[DELAYS-1] : delay[0];
   reg vout_hs, vout_vs, vout_de;
   reg [23:0] vout_data;
   always @(*) begin
      vout_hs = active_delay[26];
      vout_vs = active_delay[25];
      vout_de = active_delay[24];
      vout_data = {24{active_light}} ^ active_delay[23:0];
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
