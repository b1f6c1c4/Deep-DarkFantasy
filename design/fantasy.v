module fantasy #(
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter SMOOTH_W = 6,
   parameter SMOOTH_T = 1400
) (
   input rst_ni,
   input [2:0] mode_i,

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
   wire [7:0] px_C_rrr, px_L_rrr;
   wire blk_Y, blk_C, blk_L;
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

      .px_C_rrr_o (px_C_rrr),
      .px_L_rrr_o (px_L_rrr),

      .Y_o (blk_Y),
      .C_o (blk_C),
      .L_o (blk_L)
   );

   reg [2:0] mode_r;
   reg [23:0] wd_r, wd_rr, wd_rrr, wd_rrrr, wd_rrrrr;
   reg blk_Y_r, blk_C_r, blk_L_r;
   reg blk_Y_rr, blk_C_rr, blk_L_rr;
   reg blk_Y_rrr, blk_C_rrr, blk_L_rrr;
   always @(posedge vin_clk_i) begin
      mode_r <= mode_i;
      {wd_r, wd_rr, wd_rrr, wd_rrrr, wd_rrrrr} <= {vout_data_i, wd_r, wd_rr, wd_rrr, wd_rrrr};
      {blk_Y_r, blk_C_r, blk_L_r} <= {blk_Y, blk_C, blk_L};
      {blk_Y_rr, blk_C_rr, blk_L_rr} <= {blk_Y_r, blk_C_r, blk_L_r};
      {blk_Y_rrr, blk_C_rrr, blk_L_rrr} <= {blk_Y_rr, blk_C_rr, blk_L_rr};
   end

   reg inv_en_rrr;
   reg [29:0] shift_rrr;
   reg [17:0] gain_rrr;
   always @(*) begin
      if (mode_r == 0) begin // Inv
         inv_en_rrr = 1;
         shift_rrr = 0;
         gain_rrr = 32768;
      end else if (mode_r == 1) begin // Inv and dim
         inv_en_rrr = 1;
         shift_rrr = 0;
         gain_rrr = 21845;
      end else if (mode_r == 2) begin // Y-based Inv
         inv_en_rrr = blk_Y_rrr;
         shift_rrr = 0;
         gain_rrr = 32768;
      end else if (mode_r == 3) begin // Inv or dim
         inv_en_rrr = ~blk_C_rrr && blk_Y_rrr;
         shift_rrr = 0;
         gain_rrr = ~blk_C_rrr ? 32768 : 16384;
      end else if (mode_r == 4) begin // Shift and dim
         inv_en_rrr = 0;
         if (px_C_rrr < 89) begin // 0.35
            shift_rrr = blk_L_rrr ? 30'sd2 * $signed($signed(px_L_rrr) - 30'sd128) : 30'sd0;
            gain_rrr = 32768;
         end else begin
            shift_rrr = (px_L_rrr - px_C_rrr / 30'sd2) / 30'sd2;
            gain_rrr = ~blk_L_rrr ? 32768 : 21845;
         end
      end else if (mode_r == 5) begin // Dim
         inv_en_rrr = 0;
         shift_rrr = 0;
         gain_rrr = 21845;
      end else begin // Pass
         inv_en_rrr = 0;
         shift_rrr = 0;
         gain_rrr = 32768;
      end
   end

   wire [47:0] p_r, p_b, p_g; // _rrrrr
   DSP48E1 #(
      .AREG (1),
      .BREG (1),
      .CREG (1),
      .DREG (1),
      .ADREG (0),
      .MREG (0),
      .PREG (1),
      .USE_DPORT ("TRUE")
   ) i_dsp_r (
      .A (shift_rrr),
      .B (gain_rrr),
      .C (0),
      .D ({17'b0,({8{inv_en_rrr}} ^ wd_rrr[23:16])}),
      .PCIN (),
      .PCOUT (),
      .P (p_r),

      .OPMODE (7'b0000101), // XY <= M, Z = 0
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b01100), // AD = D_r - A_r, M = AD * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (1), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (~rst_ni), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (vin_clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );
   DSP48E1 #(
      .AREG (1),
      .BREG (1),
      .CREG (0),
      .DREG (1),
      .ADREG (0),
      .MREG (0),
      .PREG (1),
      .USE_DPORT ("TRUE")
   ) i_dsp_b (
      .A (shift_rrr),
      .B (gain_rrr),
      .C (0),
      .D ({17'b0,({8{inv_en_rrr}} ^ wd_rrr[15:8])}),
      .PCIN (),
      .PCOUT (),
      .P (p_b),

      .OPMODE (7'b0000101), // XY <= M, Z = 0
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b01100), // AD = D_r - A_r, M = AD * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (1), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (~rst_ni), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (vin_clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );
   DSP48E1 #(
      .AREG (1),
      .BREG (1),
      .CREG (0),
      .DREG (1),
      .ADREG (0),
      .MREG (0),
      .PREG (1),
      .USE_DPORT ("TRUE")
   ) i_dsp_g (
      .A (shift_rrr),
      .B (gain_rrr),
      .C (0),
      .D ({17'b0,({8{inv_en_rrr}} ^ wd_rrr[7:0])}),
      .PCIN (),
      .PCOUT (),
      .P (p_g),

      .OPMODE (7'b0000101), // XY <= M, Z = 0
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b01100), // AD = D_r - A_r, M = AD * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (1), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (~rst_ni), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (vin_clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   reg vs_r, vs_rr, vs_rrr, vs_rrrr, vs_rrrrr;
   reg hs_r, hs_rr, hs_rrr, hs_rrrr, hs_rrrrr;
   reg de_r, de_rr, de_rrr, de_rrrr, de_rrrrr;
   always @(posedge vin_clk_i) begin
      {vs_r, vs_rr, vs_rrr, vs_rrrr, vs_rrrrr} <= {vin_vs_i, vs_r, vs_rr, vs_rrr, vs_rrrr};
      {hs_r, hs_rr, hs_rrr, hs_rrrr, hs_rrrrr} <= {vin_hs_i, hs_r, hs_rr, hs_rrr, hs_rrrr};
      {de_r, de_rr, de_rrr, de_rrrr, de_rrrrr} <= {vin_de_i, de_r, de_rr, de_rrr, de_rrrr};
   end

   assign vout_vs_o = vs_rrrrr;
   assign vout_hs_o = hs_rrrrr;
   assign vout_de_o = de_rrrrr;
   assign vout_data_o = {p_r[22:15],p_b[22:15],p_g[22:15]};

   // Output mix
   /* smoother #( */
   /*    .HBLKS (HBLKS), */
   /*    .VBLKS (VBLKS), */
   /*    .SMOOTH_W (SMOOTH_W), */
   /*    .SMOOTH_T (SMOOTH_T) */
   /* ) i_smoother ( */
   /*    .clk_i (vin_clk_i), */
   /*    .rst_ni (rst_ni), */
   /*    .dl_i (mode_i[1] ^ mode_i[0]), */
   /*    .ld_i (mode_i[0]), */

   /*    .vin_vs_i (vin_vs_i), */
   /*    .vin_hs_i (vin_hs_i), */
   /*    .vin_de_i (vin_de_i), */
   /*    .vin_data_i (vout_data_i), */

   /*    .ht_cur_i (ht_cur), */
   /*    .vt_cur_i (vt_cur), */

   /*    .px_C_rrr_i (px_C_rrr), */
   /*    .px_L_rrr_i (px_L_rrr), */

   /*    .Y_i (Y), */
   /*    .C_i (C), */
   /*    .L_i (L), */

   /*    .vout_vs_o (vout_vs_o), */
   /*    .vout_hs_o (vout_hs_o), */
   /*    .vout_de_o (vout_de_o), */
   /*    .vout_data_o (vout_data_o) */
   /* ); */

endmodule
