`timescale 1ns/1ns
module axi_delayer_tb;

   logic clk_i, rst_ni;
   logic ren_i, wen_i;
   logic vs_i, de_i;
   logic [23:0] data_i, data_o;

   logic m_axi_arready, m_axi_arvalid, m_axi_rvalid, m_axi_rready;
   logic [63:0] m_axi_rdata;

   logic m_axi_awvalid, m_axi_wvalid, m_axi_wready;
   logic [63:0] m_axi_wdata;

   axi_delayer inst (
      .clk_i,
      .rst_ni,

      .ren_i,
      .wen_i,
      .vs_i,
      .de_i,
      .data_i,
      .data_o,

      .m_axi_arready,
      .m_axi_arvalid,
      .m_axi_awready (1),
      .m_axi_awvalid,

      .m_axi_rvalid,
      .m_axi_rdata,
      .m_axi_rready,

      .m_axi_wvalid,
      .m_axi_wdata,
      .m_axi_wready
   );

   initial begin
      clk_i = 0;
      forever #1 clk_i = ~clk_i;
   end

   logic [63:0] cnt_w, cnt_r;
   logic [63:0] mem_w, mem_r;
   logic [63:0] mem[1920*1080*24/64-1:0];
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt_w <= 0;
         cnt_r <= 0;
         mem_w <= 0;
         mem_r <= 0;
      end else begin
         cnt_r <= cnt_r +
            ((m_axi_arvalid && m_axi_arready) ? 16 : 0) -
            ((m_axi_rvalid && m_axi_rready) ? 1 : 0);
         if (m_axi_rvalid && m_axi_rready) begin
            mem_r <= mem_r + 1;
         end
         cnt_w <= cnt_w +
            (m_axi_awvalid ? 16 : 0) -
            ((m_axi_wvalid && m_axi_wready) ? 1 : 0);
         if (m_axi_wvalid && m_axi_wready) begin
            mem_w <= mem_w + 1;
            mem[mem_w] <= m_axi_wdata;
         end
      end
   end
   assign m_axi_arready = cnt_r < 69;
   assign m_axi_rvalid = cnt_r > 0;
   assign m_axi_rdata = mem[mem_r];
   assign m_axi_wready = cnt_w > 0 || m_axi_awvalid;

   initial begin
      rst_ni = 0;
      ren_i = 0;
      wen_i = 1;
      vs_i = 0;
      de_i = 0;
      data_i = 0;
      repeat (30) @(negedge clk_i);
      rst_ni = 1; repeat (30) @(negedge clk_i);
      vs_i = 1; repeat (5*2200) @(negedge clk_i);
      vs_i = 0;
      de_i = 0; repeat (36*2200) @(negedge clk_i);
      repeat (1080) begin
         de_i = 0; repeat (192) @(negedge clk_i);
         repeat (1920) begin
            de_i = 1; @(negedge clk_i); data_i = data_i + 1;
         end
         de_i = 0; repeat (88) @(negedge clk_i);
      end
      de_i = 0; repeat (4*2200) @(negedge clk_i);

      ren_i = 1;
      wen_i = 0;
      data_i = 0;
      vs_i = 1; repeat (5*2200) @(negedge clk_i);
      vs_i = 0;
      de_i = 0; repeat (36*2200) @(negedge clk_i);
      repeat (1080) begin
         de_i = 0; repeat (192) @(negedge clk_i);
         repeat (1920) begin
            de_i = 1; @(negedge clk_i); data_i = data_i + 1;
            assert(data_o === data_i);
         end
         de_i = 0; repeat (88) @(negedge clk_i);
      end
      de_i = 0; repeat (4*2200) @(negedge clk_i);

      $finish;
   end

endmodule
