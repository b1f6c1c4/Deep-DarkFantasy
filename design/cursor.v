module cursor #(
   parameter HP = 1920,
   parameter VP = 1080,
   parameter KH = 30,
   parameter KV = 30,
   parameter HBLKS = 10,
   parameter VBLKS = 10
) (
   input clk_i,
   input hs_i,
   input vs_i,
   input de_i,

   output de_fall_o,
   output h_save_o,
   output v_save_o,
   output reg [31:0] ht_cur_o,
   output reg [31:0] vt_cur_o
);

   // Edge detection
   reg de_r;
   always @(posedge clk_i) begin
      de_r <= de_i;
   end
   assign de_fall_o = de_r && ~de_i;

   // Tile cursor
   reg [31:0] hx_cur;
   reg [31:0] vx_cur;
   always @(posedge clk_i) begin
      if (hs_i) begin
         hx_cur <= 0;
      end else if (de_i) begin
         hx_cur <= hx_cur + 1;
      end
   end
   always @(posedge clk_i) begin
      if (vs_i) begin
         vx_cur <= 0;
      end else if (de_fall_o) begin
         vx_cur <= vx_cur + 1;
      end
   end

   reg [31:0] hp_cur;
   reg [31:0] vp_cur;
   assign h_save_o = de_i && (hp_cur == KH-1 || hx_cur == HP-1);
   assign v_save_o = de_fall_o && (vp_cur == KV-1 || vx_cur == VP-1);
   always @(posedge clk_i) begin
      if (vs_i) begin
         hp_cur <= 0;
         vp_cur <= 0;
      end else begin
         if (de_i) begin
            hp_cur <= h_save_o ? 0 : hp_cur + 1;
         end
         if (de_fall_o) begin
            vp_cur <= v_save_o ? 0 : vp_cur + 1;
         end
      end
   end
   always @(posedge clk_i) begin
      if (vs_i) begin
         ht_cur_o <= 0;
         vt_cur_o <= 0;
      end else begin
         if (~de_i) begin
            ht_cur_o <= 0;
         end else if (h_save_o) begin
            ht_cur_o <= ht_cur_o + 1;
         end
         if (v_save_o) begin
            vt_cur_o <= vt_cur_o + 1;
         end
      end
   end

endmodule
