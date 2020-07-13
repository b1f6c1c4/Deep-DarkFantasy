module blk_buffer #(
   parameter HBLKS = 10,
   parameter VBLKS = 10,
   parameter PXS = 30 * 30
) (
   input clk_i,
   input rst_ni,
   input h_save_i,
   input v_save_i,
   input de_i,
   input [23:0] wd_i,

   output Y_rrr_o,
   output C_rrr_o,
   output L_rrr_o
);
   localparam Y_DEPTH = $clog2(PXS * 512 * 255 + 1);
   localparam Y_THRES = PXS * 256 * 255;
   localparam Y_HYS = PXS * 256 * 10;
   localparam C_DEPTH = $clog2(PXS * 255 + 1);
   localparam C_THRES = PXS * 89; // 0.35 * 255
   localparam C_HYS = PXS * 5;
   localparam L_DEPTH = $clog2(PXS * 2 * 255 + 1);
   localparam L_THRES = PXS * 256;
   localparam L_HYS = PXS * 15;

   // Control

   reg h_clear_i, h_clear_r, h_clear_rr, h_clear_rrr;
   reg h_save_r, h_save_rr, h_save_rrr, h_save_rrrr, h_save_rrrrr;
   reg v_save_r, v_save_rr, v_save_rrr, v_save_rrrr, v_save_rrrrr, v_save_rrrrrr;
   always @(posedge clk_i) begin
      h_clear_i <= ~de_i || h_save_i;

      h_clear_r <= h_clear_i;
      h_save_r <= h_save_i;
      v_save_r <= v_save_i;

      h_clear_rr <= h_clear_r;
      h_save_rr <= h_save_r;
      v_save_rr <= v_save_r;

      h_clear_rrr <= h_clear_rr;
      h_save_rrr <= h_save_rr;
      v_save_rrr <= v_save_rr;

      h_save_rrrr <= h_save_rrr;
      v_save_rrrr <= v_save_rrr;

      h_save_rrrrr <= h_save_rrrr;
      v_save_rrrrr <= v_save_rrrr;

      v_save_rrrrrr <= v_save_rrrrr;
   end

   reg [$clog2(HBLKS+1)-1:0] cls_cnt;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cls_cnt <= 0;
      end else if (v_save_i) begin
         cls_cnt <= HBLKS;
      end else if (h_save_i && |cls_cnt) begin
         cls_cnt <= cls_cnt - 1;
      end
   end

   // Datapath: Shift registers for block sums

   wire [47:0] p_1, p_2, p_3, p_4, p_5; // _rrrrr
   wire [Y_DEPTH-1:0] bacc0_Y;
   wire [C_DEPTH-1:0] bacc0_C;
   wire [L_DEPTH-1:0] bacc0_L;
   shift_reg #(
      .DELAYS (HBLKS),
      .WIDTH (Y_DEPTH)
   ) i_bacc_Y (
      .clk_i (clk_i),
      .cen_i (~rst_ni || h_save_rrrrr),
      .d_i ({Y_DEPTH{rst_ni}} & p_4[Y_DEPTH-1:0]),
      .d_o (bacc0_Y)
   );
   shift_reg #(
      .DELAYS (HBLKS),
      .WIDTH (C_DEPTH)
   ) i_bacc_C (
      .clk_i (clk_i),
      .cen_i (~rst_ni || h_save_rrrrr),
      .d_i ({C_DEPTH{rst_ni}} & p_5[24+C_DEPTH-1:24]),
      .d_o (bacc0_C)
   );
   shift_reg #(
      .DELAYS (HBLKS),
      .WIDTH (L_DEPTH)
   ) i_bacc_L (
      .clk_i (clk_i),
      .cen_i (~rst_ni || h_save_rrrrr),
      .d_i ({L_DEPTH{rst_ni}} & p_5[L_DEPTH-1:0]),
      .d_o (bacc0_L)
   );

   // Datapath: Y

   DSP48E1 #(
      .OPMODEREG (1),
      .AREG (1),
      .CREG (1),
      .MREG (0),
      .DREG (1), .ADREG (1)
   ) i_dsp_1 (
      .A ({22'b0,wd_i[23:16]}),
      .B (18'd109),
      .C ({{(48-Y_DEPTH){1'b0}},bacc0_Y}),
      .PCIN (0),
      .PCOUT (p_1),
      .P (),

      // (h_save_i && ~|cls_cnt) == 0: XY = M, Z = 0
      // (h_save_i && ~|cls_cnt) == 1: XY = M, Z = C_r
      .OPMODE ((h_save_i && ~|cls_cnt) ? 7'b0110101 : 7'b0000101),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00000), // M = A_r * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (0), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (0), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .AREG (1),
      .CREG (0),
      .MREG (1),
      .DREG (1), .ADREG (1)
   ) i_dsp_2 (
      .A ({22'b0,wd_i[15:8]}),
      .B (18'd37),
      .C (0),
      .PCIN (p_1),
      .PCOUT (p_2),
      .P (),

      // XY = M_r, Z = PCIN
      .OPMODE (7'b0010101),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00000), // M_r <= A_r * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (0), .CEM (1), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (0), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .AREG (2),
      .CREG (0),
      .MREG (1),
      .DREG (1), .ADREG (1)
   ) i_dsp_3 (
      .A ({22'b0,wd_i[7:0]}),
      .B (18'd366),
      .C (0),
      .PCIN (p_2),
      .PCOUT (p_3),
      .P (),

      // XY = M_r, Z = PCIN
      .OPMODE (7'b0010101),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00000), // M_r <= A_rr * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (0), .CEM (1), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (0), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .OPMODEREG (1),
      .CREG (0),
      .MREG (0),
      .DREG (1), .ADREG (1),
      .USE_MULT ("NONE")
   ) i_dsp_4 (
      .A (0),
      .B (0),
      .C (0),
      .PCIN (p_3),
      .PCOUT (),
      .P (p_4),

      // h_clear_rrr == 0: X = P_r, Y = 0, Z = PCIN
      // h_clear_rrr == 1: X = 0, Y = 0, Z = PCIN
      .OPMODE (h_clear_rrr ? 7'b0010000 : 7'b0010010),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00010),
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (0), .CED (0), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (0), .RSTD (0), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   // Datapath: C & L

   wire [23:0] ab_5c = bacc0_C;
   wire [23:0] ab_5l = bacc0_L;
   wire [47:0] ab_5 = (h_save_i && ~|cls_cnt) ? {ab_5c,ab_5l} : 0;
   reg [47:0] ab_5_r, ab_5_rr;
   always @(posedge clk_i) begin
      ab_5_r <= ab_5;
      ab_5_rr <= ab_5_r;
   end

   wire [23:0] C_rrr, L_rrr;
   cl i_cl (
      .clk_i (clk_i),
      .rst_ni (rst_ni),
      .wd_i (wd_i),
      .C_rrr_o (C_rrr[7:0]),
      .L_rrr_o (L_rrr[8:1]),
      .Lex_rrr_o (L_rrr[0])
   );
   assign C_rrr[23:8] = 0;
   assign L_rrr[23:9] = 0;

   DSP48E1 #(
      .OPMODEREG (1),
      .AREG (2),
      .BREG (2),
      .CREG (1),
      .MREG (0),
      .DREG (1), .ADREG (1),
      .USE_MULT ("NONE"),
      .USE_SIMD ("TWO24")
   ) i_dsp_5 (
      .A (ab_5_rr[47:18]),
      .B (ab_5_rr[17:0]),
      .C ({C_rrr,L_rrr}),
      .PCIN (),
      .PCOUT (),
      .P (p_5),

      // h_clear_rrr == 0: X = A_rr:B_rr, Y = C_r, Z = P_r
      // h_clear_rrr == 1: X = A_rr:B_rr, Y = C_r, Z = 0
      .OPMODE (h_clear_rrr ? 7'b0001111 : 7'b0101111),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00010),
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (0), .CEM (0), .CEP (1), .CEAD (0),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (0), .RSTM (0), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   // Datapath: Block Comparers

   reg fb_Y_r, fb_Y_rr, fb_Y_rrr, fb_Y_rrrr, fb_Y_rrrrr;
   reg fb_C_r, fb_C_rr, fb_C_rrr, fb_C_rrrr, fb_C_rrrrr;
   reg fb_L_r, fb_L_rr, fb_L_rrr, fb_L_rrrr, fb_L_rrrrr;

   wire p_4s = p_4 >= (fb_Y_rrrrr ? Y_THRES - Y_HYS : Y_THRES + Y_HYS);
   wire p_5c = p_5[47:24] >= (fb_C_rrrrr ? C_THRES - C_HYS : C_THRES + C_HYS);
   wire p_5l = p_5[23:0] >= (fb_L_rrrrr ? L_THRES - L_HYS : L_THRES + L_HYS);

   reg [HBLKS-1:0] bt_Y, bt_C, bt_L;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         bt_Y <= 0;
         bt_C <= 0;
         bt_L <= 0;
      end else if (h_save_rrrrr) begin
         bt_Y <= {p_4s,bt_Y[HBLKS-1:1]};
         bt_C <= {p_5c,bt_C[HBLKS-1:1]};
         bt_L <= {p_5l,bt_L[HBLKS-1:1]};
      end
   end

   // Datapath: Frame Buffers

   wire [HBLKS-1:0] lbuf_Y, lbuf_C, lbuf_L;
   shift_reg #(
      .DELAYS (VBLKS-1),
      .WIDTH (HBLKS)
   ) i_lbs_Y (
      .clk_i (clk_i),
      .cen_i (~rst_ni || v_save_rrrrrr),
      .d_i ({HBLKS{rst_ni}} & bt_Y),
      .d_o (lbuf_Y)
   );
   shift_reg #(
      .DELAYS (VBLKS-1),
      .WIDTH (HBLKS)
   ) i_lbs_C (
      .clk_i (clk_i),
      .cen_i (~rst_ni || v_save_rrrrrr),
      .d_i ({HBLKS{rst_ni}} & bt_C),
      .d_o (lbuf_C)
   );
   shift_reg #(
      .DELAYS (VBLKS-1),
      .WIDTH (HBLKS)
   ) i_lbs_L (
      .clk_i (clk_i),
      .cen_i (~rst_ni || v_save_rrrrrr),
      .d_i ({HBLKS{rst_ni}} & bt_L),
      .d_o (lbuf_L)
   );

   reg [HBLKS-1:0] lbuf_Y_r, lbuf_C_r, lbuf_L_r;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         lbuf_Y_r <= 0;
         lbuf_C_r <= 0;
         lbuf_L_r <= 0;
      end else if (v_save_rrrrrr) begin
         lbuf_Y_r <= lbuf_Y;
         lbuf_C_r <= lbuf_C;
         lbuf_L_r <= lbuf_L;
      end else if (h_save_i) begin
         lbuf_Y_r <= {lbuf_Y_r[0],lbuf_Y_r[HBLKS-1:1]};
         lbuf_C_r <= {lbuf_C_r[0],lbuf_C_r[HBLKS-1:1]};
         lbuf_L_r <= {lbuf_L_r[0],lbuf_L_r[HBLKS-1:1]};
      end
   end

   // Datapath: Final Outputs

   always @(posedge clk_i) begin
      {fb_Y_r, fb_Y_rr, fb_Y_rrr, fb_Y_rrrr, fb_Y_rrrrr} <= {lbuf_Y_r[0], fb_Y_r, fb_Y_rr, fb_Y_rrr, fb_Y_rrrr};
      {fb_C_r, fb_C_rr, fb_C_rrr, fb_C_rrrr, fb_C_rrrrr} <= {lbuf_C_r[0], fb_C_r, fb_C_rr, fb_C_rrr, fb_C_rrrr};
      {fb_L_r, fb_L_rr, fb_L_rrr, fb_L_rrrr, fb_L_rrrrr} <= {lbuf_L_r[0], fb_L_r, fb_L_rr, fb_L_rrr, fb_L_rrrr};
   end

   assign Y_rrr_o = fb_Y_rrr;
   assign C_rrr_o = fb_C_rrr;
   assign L_rrr_o = fb_L_rrr;

endmodule
