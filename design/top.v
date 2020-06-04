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

   localparam KN = 21;
   localparam DELAYS = (KN-1)/2 + 1;

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

   // Convolution
   reg [7:0] conv_d[0:KN-1];
   reg [13:0] conv_dm[0:KN-1];
   genvar i;
   generate
      for (i = 0; i < KN - 1; i = i + 1) begin : gen_conv_d
         always @(posedge vin_clk_i) begin
            if (vin_hs) begin
               conv_d[i] <= 0;
            end else if (vin_de) begin
               conv_d[i] <= conv_d[i + 1];
            end
         end
      end
   endgenerate
   always @(*) begin
      conv_d[KN-1] <= gray;
   end

   always @(posedge vin_clk_i) begin
      conv_dm[00] <= conv_d[00] * 3;
      conv_dm[01] <= conv_d[01] * 5;
      conv_dm[02] <= conv_d[02] * 7;
      conv_dm[03] <= conv_d[03] * 9;
      conv_dm[04] <= conv_d[04] * 11;
      conv_dm[05] <= conv_d[05] * 14;
      conv_dm[06] <= conv_d[06] * 16;
      conv_dm[07] <= conv_d[07] * 17;
      conv_dm[08] <= conv_d[08] * 18;
      conv_dm[09] <= conv_d[09] * 19;
      conv_dm[10] <= conv_d[10] * 19;
      conv_dm[11] <= conv_d[11] * 19;
      conv_dm[12] <= conv_d[12] * 18;
      conv_dm[13] <= conv_d[13] * 17;
      conv_dm[14] <= conv_d[14] * 16;
      conv_dm[15] <= conv_d[15] * 14;
      conv_dm[16] <= conv_d[16] * 11;
      conv_dm[17] <= conv_d[17] * 9;
      conv_dm[18] <= conv_d[18] * 7;
      conv_dm[19] <= conv_d[19] * 5;
      conv_dm[20] <= conv_d[20] * 3;
   end

   reg [15:0] conv_result_t;
   always @(*) begin
      conv_result_t = 0;
      conv_result_t = conv_result_t + conv_dm[00];
      conv_result_t = conv_result_t + conv_dm[01];
      conv_result_t = conv_result_t + conv_dm[02];
      conv_result_t = conv_result_t + conv_dm[03];
      conv_result_t = conv_result_t + conv_dm[04];
      conv_result_t = conv_result_t + conv_dm[05];
      conv_result_t = conv_result_t + conv_dm[06];
      conv_result_t = conv_result_t + conv_dm[07];
      conv_result_t = conv_result_t + conv_dm[08];
      conv_result_t = conv_result_t + conv_dm[09];
      conv_result_t = conv_result_t + conv_dm[10];
      conv_result_t = conv_result_t + conv_dm[11];
      conv_result_t = conv_result_t + conv_dm[12];
      conv_result_t = conv_result_t + conv_dm[13];
      conv_result_t = conv_result_t + conv_dm[14];
      conv_result_t = conv_result_t + conv_dm[15];
      conv_result_t = conv_result_t + conv_dm[16];
      conv_result_t = conv_result_t + conv_dm[17];
      conv_result_t = conv_result_t + conv_dm[18];
      conv_result_t = conv_result_t + conv_dm[19];
      conv_result_t = conv_result_t + conv_dm[20];
   end
   wire [7:0] conv_result = conv_result_t[15:8];

   // Line buffer
   reg [7:0] line_buffer[0:1919];
   reg [10:0] cursor;
   always @(posedge vin_clk_i, negedge rst_n) begin
      if (~rst_n) begin
         cursor <= 0;
      end else if (vin_hs) begin
         cursor <= 0;
      end else if (vin_de) begin
         cursor <= cursor + 1;
         line_buffer[cursor] <= conv_result;
      end
   end

   // Extra stages
   reg [26:0] delay[0:DELAYS-1];
   generate
      for (i = 0; i < DELAYS-1; i = i + 1) begin : gen_delay
         always @(posedge vin_clk_i, negedge rst_n) begin
            if (~rst_n) begin
               delay[i] <= 0;
            end else begin
               delay[i] <= delay[i + 1];
            end
         end
      end
   endgenerate
   always @(posedge vin_clk_i, negedge rst_n) begin
      if (~rst_n) begin
         delay[DELAYS-1] <= 0;
      end else begin
         delay[DELAYS-1] <= {vin_hs, vin_vs, vin_de, vin_data};
      end
   end

   // Output selection
   wire vout_clk_o = vin_clk_i;
   reg vout_hs;
   reg vout_vs;
   reg vout_de;
   reg [23:0] vout_data;
   always @(*) begin
      if (button_ni[1]) begin
         vout_hs = delay[0][26];
         vout_vs = delay[0][25];
         vout_de = delay[0][24];
         vout_data = {24{conv_result[7]}} ^ delay[0][23:0];
      end else begin
         vout_hs = vin_hs;
         vout_vs = vin_hs;
         vout_de = vin_de;
         vout_data = vin_data;
      end
   end

   // HDMI out
   adv7511 i_adv7511 (
      .clk_i (clk_i2c),
      .rst_ni (rst_n),
      .vout_scl_io,
      .vout_sda_io
   );
   always @(posedge vin_clk_i) begin
      vout_hs_o <= vout_hs;
      vout_vs_o <= vout_vs;
      vout_de_o <= vout_de;
      vout_data_o <= vout_data;
   end

endmodule
