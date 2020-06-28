module cl (
   input clk_i,
   input rst_ni,
   input [23:0] wd_i,
   output [7:0] C_rrr_o,
   output [7:0] L_rrr_o,
   output Lex_rrr_o
);

   reg [23:0] rbg_r, rbg_rr;
   reg [7:0] max_rrr, min_rrr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         rbg_r <= 0;
         rbg_rr <= 0;
         max_rrr <= 0;
         min_rrr <= 0;
      end else begin
         if (wd_i[23:16] >= wd_i[15:8]) begin
            rbg_r <= {wd_i[23:16],wd_i[15:8],wd_i[7:0]};
         end else begin
            rbg_r <= {wd_i[15:8],wd_i[23:16],wd_i[7:0]};
         end
         if (rbg_r[15:8] >= rbg_r[7:0]) begin
            rbg_rr <= {rbg_r[23:16],rbg_r[15:8],rbg_r[7:0]};
         end else begin
            rbg_rr <= {rbg_r[23:16],rbg_r[7:0],rbg_r[15:8]};
         end
         if (rbg_rr[23:16] >= rbg_rr[15:8]) begin
            max_rrr <= rbg_rr[23:16];
         end else begin
            max_rrr <= rbg_rr[15:8];
         end
         min_rrr <= rbg_rr[7:0];
      end
   end

   assign C_rrr_o = max_rrr - min_rrr;
   wire [8:0] L = max_rrr + min_rrr;
   assign L_rrr_o = L[8:1];
   assign Lex_rrr_o = L[0];

endmodule
