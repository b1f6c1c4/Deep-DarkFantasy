module mem (
   input clk_i_p,
   input clk_i_n,
   input rst_ni,
   output clk_o,
   output rst_no,

   input vin_val_i,
   input [26:0] vin_data_i,
   output vin_rdy_o,

   output vout_val_o,
   output [26:0] vout_data_o,
   input vout_rdy_i,

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
   output [0:0] ddr3_odt
);

   localparam nCK_PER_CLK = 4;
   localparam ADDR_WIDTH = 29;
   localparam APP_DATA_WIDTH = 2 * nCK_PER_CLK * 32;
   localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;

   reg vin_vs_r;
   always @(posedge clk_o, negedge rst_no) begin
      if (~rst_no) begin
         vin_vs_r <= 0;
      end else begin
         vin_vs_r <= vin_vs;
      end
   end

   reg [ADDR_WIDTH-1:0] rwaddr;
   wire [2:0] rwcmd;
   wire rwval, rwrdy, rval, wval, wrdy;
   wire wend, rend;
   wire [APP_DATA_WIDTH-1:0] wdata;
   wire [APP_DATA_WIDTH-1:0] rdata;

   always @(posedge clk_o, negedge rst_no) begin
      if (~rst_no) begin
      end
   end

   ddr3 i_ddr3 (
      .sys_clk_p (clk_i_p),
      .sys_clk_n (clk_i_n),
      .sys_rst (rst_ni),

      .app_addr (rwaddr),
      .app_cmd (rwcmd),
      .app_en (rwval),
      .app_rdy (rwrdy),
      .app_hi_pri (1'b0),
      .app_rd_data (rdata),
      .app_rd_data_end (rend),
      .app_rd_data_valid (rval),
      .app_wdf_data (wdata),
      .app_wdf_end (wend),
      .app_wdf_mask ({APP_MASK_WIDTH{1'b1}}),
      .app_wdf_rdy (wrdy),
      .app_wdf_wren (wval),
      .app_ref_req (1'b0),
      .app_zq_req (1'b0),
      .ui_clk (clk_o),
      .ui_clk_sync_rst (rst_no),

      .ddr3_dq (ddr3_dq),
      .ddr3_dqs_n (ddr3_dqs_n),
      .ddr3_dqs_p (ddr3_dqs_p),
      .ddr3_addr (ddr3_addr),
      .ddr3_ba (ddr3_ba),
      .ddr3_ras_n (ddr3_ras_n),
      .ddr3_cas_n (ddr3_cas_n),
      .ddr3_we_n (ddr3_we_n),
      .ddr3_reset_n (ddr3_reset_n),
      .ddr3_ck_p (ddr3_ck_p),
      .ddr3_ck_n (ddr3_ck_n),
      .ddr3_cke (ddr3_cke),
      .ddr3_cs_n (ddr3_cs_n),
      .ddr3_dm (ddr3_dm),
      .ddr3_odt (ddr3_odt)
   );

endmodule
