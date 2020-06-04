module cdc_fifo #(
   parameter DW = 1,
   parameter QW = 7
) (
   input wclk_i,
   input wrst_ni,
   input wval_i,
   input [DW-1:0] wdata_i,
   output reg wrdy_o,

   input rclk_i,
   input rrst_ni,
   output reg rval_o,
   output [DW-1:0] rdata_o,
   input rrdy_i
);

   reg [DW-1:0] queue[0:((1<<QW)-1)];
   reg [QW:0] wbin, wgray, wgray_r, wgray_r_r;
   reg [QW:0] rbin, rgray, rgray_w, rgray_w_w;
   wire [QW:0] mask = {2'b1,{(QW-1){1'b0}}};

   assign rdata_o = queue[rbin[QW-1:0]];
   always @(posedge wclk_i) begin
      if (wval_i && wrdy_o) begin
         queue[wbin[QW-1:0]] <= wdata_i;
      end
   end

   // Intra-clock domain
   wire [QW:0] wbin_next = wbin + (wval_i && wrdy_o ? 1 : 0);
   wire [QW:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
   wire [QW:0] wrdy_next = ~(wgray_next == (rgray_w_w ^ mask));
   always @(posedge wclk_i, negedge wrst_ni) begin
      if (~wrst_ni) begin
         wrdy_o <= 1'b0;
         wbin <= 0;
         wgray <= 0;
      end else begin
         wrdy_o <= wrdy_next;
         wbin <= wbin_next;
         wgray <= wgray_next;
      end
   end
   wire [QW:0] rbin_next = rbin + (rval_o && rrdy_i ? 1 : 0);
   wire [QW:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
   wire [QW:0] rval_next = ~(rgray_next == wgray_r_r);
   always @(posedge rclk_i, negedge rrst_ni) begin
      if (~rrst_ni) begin
         rval_o <= 1'b0;
         rbin <= 0;
         rgray <= 0;
      end else begin
         rval_o <= rval_next;
         rbin <= rbin_next;
         rgray <= rgray_next;
      end
   end

   // Inter-clock domain
   always @(posedge wclk_i, negedge wrst_ni) begin
      if (~wrst_ni) begin
         rgray_w <= 0;
         rgray_w_w <= 0;
      end else begin
         rgray_w <= rgray;
         rgray_w_w <= rgray_w;
      end
   end
   always @(posedge rclk_i, negedge rrst_ni) begin
      if (~rrst_ni) begin
         wgray_r <= 0;
         wgray_r_r <= 0;
      end else begin
         wgray_r <= wgray;
         wgray_r_r <= wgray_r;
      end
   end

endmodule
