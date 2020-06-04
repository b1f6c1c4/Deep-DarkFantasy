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
   // wire [23:0] data_r;
   // mem i_mem (
   //    .clk_i_p (clk_i_p),
   //    .clk_i_n (clk_i_n),
   //    .rst_ni (rst_ni),
   //    .step_i (vin_de),
   //    .data_i (vin_data),
   // );

   assign vout_clk_o = vin_clk_i;
   wire vout_hs, vout_vs, vout_de;
   wire [23:0] vout_data;
   wire mid_l, mid_r;
   wire [23:0] mid_d;

   reg fancy_clock;
   reg [31:0] counter;
   always @(posedge clk_i2c) begin
      if (counter == 32'd10000000) begin
         fancy_clock = ~fancy_clock;
         counter <= 0;
      end else begin
         counter <= counter + 1;
      end
   end

   assign led_o[2] = fancy_clock;
   cdc_fifo #(.DW(27), .QW(5)) i_cdc_fifo_1 (
      .wclk_i (fancy_clock),
      .wrst_ni (rst_n),
      .wval_i (~button_ni[2]),
      .wdata_i ({vin_hs,vin_vs,vin_de,vin_data}),
      .wrdy_o (led_o[0]),
      .rclk_i (fancy_clock),
      .rrst_ni (rst_n),
      // .rval_o (mid_r),
      .rval_o (led_o[1]),
      // .rdata_o (mid_d),
      .rdata_o ({vout_hs,vout_vs,vout_de,vout_data}),
      // .rrdy_i (mid_l)
      .rrdy_i (~button_ni[3])
   );
   // assign led_o[1] = mid_l;
   // assign led_o[2] = mid_r;
   // cdc_fifo #(.DW(27), .QW(7)) i_cdc_fifo_2 (
   //    .wclk_i (vin_clk_i),
   //    .wrst_ni (rst_n),
   //    .wval_i (mid_r),
   //    .wdata_i (mid_d),
   //    .wrdy_o (mid_l),
   //    .rclk_i (vin_clk_i),
   //    .rrst_ni (rst_n),
   //    .rval_o (led_o[3]),
   //    .rdata_o ({vout_hs,vout_vs,vout_de,vout_data}),
   //    .rrdy_i (button_ni[3])
   // );

   // always @(posedge vin_clk_i) begin
   //    vout_hs <= vin_hs;
   //    vout_vs <= vin_vs;
   //    vout_de <= vin_de;
   //    if (~button_ni[1]) begin
   //       vout_data <= data_r ^ vin_data;
   //    end else if (~is_light_r) begin
   //       vout_data <= data_r;
   //    end else begin
   //       vout_data <= {8'hff - data_r[23:16], 8'hff - data_r[15:8], 8'hff - data_r[7:0]};
   //    end
   // end

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
