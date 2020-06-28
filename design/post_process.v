module post_process (
   input rst_ni,

   input inv_en_rrr,
   input [29:0] shift_rrr,
   input [17:0] gain_rrr,

   input vin_clk_i,
   input vin_hs_i,
   input vin_vs_i,
   input vin_de_i,

   input [23:0] vout_data_i,
   output vout_hs_o,
   output vout_vs_o,
   output vout_de_o,
   output [23:0] vout_data_o
);

   reg [23:0] wd_r, wd_rr, wd_rrr;
   always @(posedge vin_clk_i) begin
      {wd_r, wd_rr, wd_rrr} <= {vout_data_i, wd_r, wd_rr};
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

endmodule
