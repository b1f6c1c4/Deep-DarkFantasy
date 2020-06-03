module adv7511(
   input clk_i,
   input rst_ni,
   inout vout_scl_io,
   inout vout_sda_io
);

   wire [9:0] i;
   reg [15:0] a;
   reg [7:0] d;
   always @(*) begin
      case(i)
         // Power up
         00: begin a = 16'h0041; d = 8'b00010000; end
         // Fixed registers
         01: begin a = 16'h0098; d = 8'h03; end
         02: begin a = 16'h009a; d = 8'he0; end
         03: begin a = 16'h009c; d = 8'h30; end
         04: begin a = 16'h009d; d = 8'h61; end
         05: begin a = 16'h00a2; d = 8'ha4; end
         06: begin a = 16'h00a3; d = 8'ha4; end
         07: begin a = 16'h00e0; d = 8'hd0; end
         08: begin a = 16'h00f9; d = 8'h00; end
         // Video input / output
         09: begin a = 16'h0015; d = 8'b00000000; end
         10: begin a = 16'h00d0; d = 8'b00111100; end
         // AVI InfoFrame
         11: begin a = 16'h0055; d = 8'b00010010; end
         // Hot plug detection
         12: begin a = 16'h00d6; d = 8'b11000000; end
      endcase
   end

   i2c_config i_i2c_config (
      .rst (~rst_ni),
      .clk (clk_i2c),
      .clk_div_cnt (16'd499),
      .i2c_addr_2byte (1'b0),
      .lut_index (i),
      .lut_dev_addr (8'h72),
      .lut_addr (a),
      .lut_data (d),
      .error (),
      .done (),
      .i2c_scl (vout_scl_io),
      .i2c_sda (vout_sda_io)
   );

endmodule
