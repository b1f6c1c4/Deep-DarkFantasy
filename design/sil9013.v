module sil9013(
   input clk_i,
   input rst_ni,
   inout vin_scl_io,
   inout vin_sda_io
);

   wire [9:0] i;
   reg [7:0] dev;
   reg [15:0] a;
   reg [7:0] d;
   always @(*) begin
      dev = 8'h60;
      case(i)
         // Software reset
         00: begin a = 16'h0005; d = 8'b00010000; end
         // System control
         01: begin a = 16'h0008; d = 8'b00000101; end
         // Input port switch
         02: begin a = 16'h0009; d = 8'b00000001; end
         // Software reset
         03: begin a = 16'h0005; d = 8'b00000100; end
         // Auto control
         04: begin a = 16'h00b5; d = 8'b00000100; end
         default: begin dev = 8'hff; a = 16'hffff; d = 8'hff; end
      endcase
   end

   i2c_config i_i2c_config (
      .rst (~rst_ni),
      .clk (clk_i),
      .clk_div_cnt (16'd499),
      .i2c_addr_2byte (1'b0),
      .lut_index (i),
      .lut_dev_addr (dev),
      .lut_reg_addr (a),
      .lut_reg_data (d),
      .error (),
      .done (),
      .i2c_scl (vin_scl_io),
      .i2c_sda (vin_sda_io)
   );

endmodule
