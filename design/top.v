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

   // DDR3
   inout [31:0] ddr3_dq,
   inout [3:0] ddr3_dqs_n,
   inout [3:0] ddr3_dqs_p,
   output [14:0] ddr3_addr,
   output [2:0] ddr3_ba,
   output ddr3_ras_n,
   output ddr3_cas_n,
   output ddr3_we_n,
   output ddr3_reset_n,
   output [0:0] ddr3_ck_p,
   output [0:0] ddr3_ck_n,
   output [0:0] ddr3_cke,
   output [0:0] ddr3_cs_n,
   output [3:0] ddr3_dm,
   output [0:0] ddr3_odt,

   output fan_no
);

   wire rst_n = button_ni[0];

   assign fan_no = 0;

   wire clk_fast; // 200MHz
   wire clk_i2c; // 100MHz
   wire pll_locked;
   sys_pll i_sys_pll (
      .clk_in1_p (clk_i_p),
      .clk_in1_n (clk_i_n),
      .reset (~rst_n),
      .clk_out1 (clk_fast),
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

   // Dark / light detection
   reg [29:0] acc_cur;
   reg is_light_r;
   always @(posedge vin_clk_i) begin
      if (vin_vs) begin
         is_light_r <= acc_cur >= 30'd263347200;
         acc_cur <= 30'd0;
      end else if (vin_de) begin
         acc_cur <= acc_cur + {1'b0,{gray}};
      end
   end

   // Frame buffer
   wire mem_clk, mem_rst_n;
   wire vin_mem_val, vin_mem_rdy;
   wire [26:0] vin_mem_data;
   cdc_fifo #(.DW(27), .QW(10)) i_cdc_fifo_1 (
      .wclk_i (vin_clk_i),
      .wrst_ni (rst_n),
      .wval_i (1'b0),
      .wdata_i ({vin_hs,vin_vs,vin_de,vin_data}),
      .wrdy_o (led_o[0]),
      .rclk_i (mem_clk),
      .rrst_ni (mem_rst_n),
      .rval_o (vin_mem_val),
      .rdata_o (vin_mem_data),
      .rrdy_i (vin_mem_rdy)
   );

   assign led_o[1] = vin_mem_val;
   assign led_o[2] = vin_mem_rdy;
   wire vout_mem_val, vout_mem_rdy;
   wire [26:0] vout_mem_data;
   mem i_mem (
      .clk_i_p,
      .clk_i_n,
      .rst_ni (rst_n),
      .clk_o (mem_clk),
      .rst_no (mem_rst_n),
      .vin_val_i (vin_mem_val),
      .vin_data_i (vin_mem_data),
      .vin_rdy_o (vin_mem_rdy),
      .vout_val_o (vout_mem_val),
      .vout_data_o (vout_mem_data),
      .vout_rdy_i (vout_mem_rdy),
      .ddr3_dq,
      .ddr3_dqs_n,
      .ddr3_dqs_p,
      .ddr3_addr,
      .ddr3_ba,
      .ddr3_ras_n,
      .ddr3_cas_n,
      .ddr3_we_n,
      .ddr3_reset_n,
      .ddr3_ck_p,
      .ddr3_ck_n,
      .ddr3_cke,
      .ddr3_cs_n,
      .ddr3_dm,
      .ddr3_odt
   );

   assign vout_clk_o = vin_clk_i;
   wire vout_hs, vout_vs, vout_de;
   wire [23:0] vout_data;
   cdc_fifo #(.DW(27), .QW(10)) i_cdc_fifo_2 (
      .wclk_i (mem_clk),
      .wrst_ni (mem_rst_n),
      .wval_i (vout_mem_val),
      .wdata_i (vout_mem_data),
      .wrdy_o (vout_mem_rdy),
      .rclk_i (vin_clk_i),
      .rrst_ni (rst_n),
      .rval_o (led_o[3]),
      .rdata_o ({vout_hs,vout_vs,vout_de,vout_data}),
      .rrdy_i (button_ni[3])
   );

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
