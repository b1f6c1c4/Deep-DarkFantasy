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

   output rx_o
);
   localparam DEPTH = $clog2(PXS * 512 * 255);
   localparam THRES = PXS * 256 * 255;

   reg [VBLKS-1:0] buf_a[0:HBLKS-1];

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

   reg [DEPTH-1:0] bacc[0:HBLKS-2];

   wire [47:0] p_1, p_2, p_3, p_4;
   wire p_4s;

   DSP48E1 #(
      .AREG (1),
      .CREG (1),
      .MREG (0)
   ) i_dsp_1 (
      .A (wd_i[23:16]),
      .B (18'd109),
      .C (bacc[0]),
      .PCIN (0),
      .PCOUT (p_1),
      .P (),

      // h_save_i == 0: XY = M, Z = 0
      // h_save_i == 1: XY = M, Z = C_r
      .OPMODE (h_save_i ? 7'b0110101 : 7'b0000101),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00000), // M = A_r * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (1), .CEM (1), .CEP (1), .CEAD (1),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (~rst_ni), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .AREG (2),
      .MREG (0)
   ) i_dsp_2 (
      .A (wd_i[15:8]),
      .B (18'd37),
      .C (0),
      .PCIN (p_1),
      .PCOUT (p_2),
      .P (),

      // XY = M, Z = PCIN
      .OPMODE (7'b0010101),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00000), // M = A_rr * B_r
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (1), .CEM (1), .CEP (1), .CEAD (1),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (~rst_ni), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .AREG (2),
      .MREG (1)
   ) i_dsp_3 (
      .A (wd_i[7:0]),
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
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (1), .CEM (1), .CEP (1), .CEAD (1),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (~rst_ni), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   DSP48E1 #(
      .OPMODEREG (1),
      .MASK (48'h7fffffffffff),
      .PATTERN (48'h800000000000),
      .USE_MULT ("NONE"),
      .USE_PATTERN_DETECT ("PATDET")
   ) i_dsp_4 (
      .A (0),
      .B (0),
      .C (~THRES + 1),
      .PCIN (p_3),
      .PCOUT (),
      .P (p_4),

      // h_clear_rrr == 0: X = P_r, Y = 0, Z = PCIN
      // h_clear_rrr == 1: X = 0, Y = C_r, Z = PCIN
      .OPMODE (h_clear_rrr ? 7'b0011100 : 7'b0010010),
      .ALUMODE (4'b0000), // P_r <= Z + X + Y + CIN
      .INMODE (5'b00010),
      .CARRYINSEL (3'b000), // CIN = CARRYIN

      .D (0),
      .CEA1 (1), .CEA2 (1), .CEB1 (1), .CEB2 (1), .CEC (1), .CED (1), .CEM (1), .CEP (1), .CEAD (1),
      .CEALUMODE (1), .CECTRL (1), .CECARRYIN (1), .CEINMODE (1),
      .RSTA (~rst_ni), .RSTB (~rst_ni), .RSTC (~rst_ni), .RSTD (~rst_ni), .RSTM (~rst_ni), .RSTP (~rst_ni),
      .RSTCTRL (~rst_ni), .RSTALLCARRYIN (~rst_ni), .RSTALUMODE (~rst_ni), .RSTINMODE (~rst_ni),
      .CLK (clk_i),
      .ACIN (0), .BCIN (0), .CARRYIN (0), .CARRYCASCIN (0), .MULTSIGNIN (0),
      .ACOUT (), .BCOUT (), .CARRYOUT (), .CARRYCASCOUT (), .MULTSIGNOUT (),
      .PATTERNDETECT (p_4s), .PATTERNBDETECT (), .OVERFLOW (), .UNDERFLOW ()
   );

   reg bt[0:HBLKS-1];

   genvar i, j;
   generate
      for (i = 0; i < HBLKS; i = i + 1) begin : g
         if (i < HBLKS - 1) begin
            always @(posedge clk_i, negedge rst_ni) begin
               if (~rst_ni) begin
                  bacc[i] <= 0;
               end else if (v_save_i) begin
                  bacc[i] <= 0;
               end else if (i == HBLKS - 2) begin
                  if (h_save_rrrrr) begin
                     bacc[i] <= p_4;
                  end
               end else begin
                  if (h_save_i) begin
                     bacc[i] <= bacc[i + 1];
                  end
               end
            end
         end
         always @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
               bt[i] <= 0;
            end else if (h_save_rrrrr) begin
               if (i == HBLKS - 1) begin
                  bt[i] <= p_4s;
               end else begin
                  bt[i] <= bt[i + 1];
               end
            end
         end
         for (j = 0; j < VBLKS; j = j + 1) begin : v
            always @(posedge clk_i, negedge rst_ni) begin
               if (~rst_ni) begin
                  buf_a[i][j] <= 0;
               end else if (v_save_rrrrrr) begin
                  if (j == VBLKS - 1) begin
                     buf_a[i][j] <= bt[i];
                  end else begin
                     buf_a[i][j] <= buf_a[i][j + 1];
                  end
               end else if (h_save_i) begin
                  buf_a[i][j] <= buf_a[(i + 1) % HBLKS][j];
               end
            end
         end
      end
   endgenerate

   assign rx_o = buf_a[0][0];

endmodule
