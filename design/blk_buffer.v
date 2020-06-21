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

   reg h_save_r, h_save_rr;
   reg v_save_r, v_save_rr, v_save_rrr;
   always @(posedge clk_i) begin
      h_save_r <= h_save_i;
      v_save_r <= v_save_i;

      h_save_rr <= h_save_r;
      v_save_rr <= v_save_r;

      v_save_rrr <= v_save_rr;
   end

   reg [3*DEPTH-1:0] brgb[0:HBLKS-1];
   reg bt[0:HBLKS-1];

   wire [3*DEPTH-1:0] b0n;
   assign b0n[3*DEPTH-1:2*DEPTH] = brgb[0][3*DEPTH-1:2*DEPTH] + 109 * wd_i[23:16];
   assign b0n[2*DEPTH-1:1*DEPTH] = brgb[0][2*DEPTH-1:1*DEPTH] + 37 * wd_i[15:8];
   assign b0n[1*DEPTH-1:0*DEPTH] = brgb[0][1*DEPTH-1:0*DEPTH] + 366 * wd_i[7:0];

   reg [3*DEPTH-1:0] b0n_r;
   wire [DEPTH-1:0] b0nr_r = b0n_r[3*DEPTH-1:2*DEPTH];
   wire [DEPTH-1:0] b0nb_r = b0n_r[2*DEPTH-1:1*DEPTH];
   wire [DEPTH-1:0] b0ng_r = b0n_r[1*DEPTH-1:0*DEPTH];
   reg [DEPTH-1:0] b0n_rr;
   always @(posedge clk_i) begin
      b0n_r <= b0n;
      b0n_rr <= b0nr_r + b0nb_r + b0ng_r;
   end

   genvar i, j;
   generate
      for (i = 0; i < HBLKS; i = i + 1) begin : g
         always @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
               brgb[i] <= 0;
            end else if (v_save_i) begin
               brgb[i] <= 0;
            end else if (i == HBLKS - 1) begin
               if (h_save_r) begin
                  brgb[i] <= b0n_r;
               end
            end else if (i == 0) begin
               if (de_i) begin
                  brgb[i] <= b0n;
               end
            end else begin
               if (h_save_i) begin
                  brgb[i] <= brgb[i + 1];
               end
            end
         end
         always @(posedge clk_i, negedge rst_ni) begin
            if (~rst_ni) begin
               bt[i] <= 0;
            end else if (h_save_rr) begin
               if (i == HBLKS - 1) begin
                  bt[i] <= b0n_rr >= THRES;
               end else begin
                  bt[i] <= bt[i + 1];
               end
            end
         end
         for (j = 0; j < VBLKS; j = j + 1) begin : v
            always @(posedge clk_i, negedge rst_ni) begin
               if (~rst_ni) begin
                  buf_a[i][j] <= 0;
               end else if (v_save_rrr) begin
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
