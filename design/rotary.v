module rotary #(
   parameter N = 12,
   parameter INIT = 0,
   parameter SAT = 1,
   parameter T = 3
) (
   input clk_i,
   input rst_ni,

   input zero_i,
   input inc_i,
   input dec_i,
   input [T-1:0] rot_ni,
   output [$clog2(N)-1:0] counter_o
);

   reg [31:0] man_cnt;
   reg [2:0] man, man_r;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         man_cnt <= 0;
         man <= 2'b0;
         man_r <= 2'b0;
      end else begin
         man <= {zero_i,inc_i,dec_i};
         man_r <= 2'b0;
         if (man == {zero_i,inc_i,dec_i}) begin
            if (man_cnt < 1800000) begin
               man_cnt <= man_cnt + 1;
            end else if (man_cnt == 1800000) begin
               man_cnt <= man_cnt + 1;
               man_r <= man;
            end
         end else begin
            man_cnt <= 0;
         end
      end
   end

   reg [31:0] pre_cnt;
   reg [T-1:0] pre_rot_n, pre_rot_nr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         pre_cnt <= 0;
         pre_rot_n <= {T{1'b1}};
         pre_rot_nr <= {T{1'b1}};
      end else begin
         pre_rot_n <= rot_ni;
         if (pre_rot_n == rot_ni) begin
            if (pre_cnt < 80000) begin
               pre_cnt <= pre_cnt + 1;
            end else begin
               pre_rot_nr <= pre_rot_n;
            end
         end else begin
            pre_cnt <= 0;
         end
      end
   end

   reg [31:0] cnt;
   reg [T-1:0] rot_nr, rot_nrr;
   reg [1:0] aut;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt <= 0;
         rot_nr <= {T{1'b1}};
         rot_nrr <= {T{1'b1}};
         aut <= 2'b00;
      end else if (rot_nrr == rot_nr) begin
         aut <= 2'b00;
         if (~&pre_rot_nr) begin
            rot_nr <= pre_rot_nr;
            cnt <= 0;
         end
      end else begin
         aut <= 2'b00;
         if (rot_nr != pre_rot_nr) begin
            rot_nr <= pre_rot_nr;
            cnt <= 0;
            if (rot_nr == {rot_nrr[0],rot_nrr[T-1:1]}
               && pre_rot_nr == {rot_nr[0],rot_nr[T-1:1]}) begin
               rot_nrr <= rot_nr;
               aut <= 2'b10;
            end else if (rot_nr == {rot_nrr[T-2:0],rot_nrr[T-1]}
               && pre_rot_nr == {rot_nr[T-2:0],rot_nr[T-1]}) begin
               rot_nrr <= rot_nr;
               aut <= 2'b01;
            end
         end else if (cnt < 200000) begin
            cnt <= cnt + 1;
         end else if (rot_nr == {rot_nrr[0],rot_nrr[T-1:1]}) begin
            cnt <= 0;
            rot_nrr <= rot_nr;
            aut <= 2'b10;
         end else if (rot_nr == {rot_nrr[T-2:0],rot_nrr[T-1]}) begin
            cnt <= 0;
            rot_nrr <= rot_nr;
            aut <= 2'b01;
         end else begin
            cnt <= 0;
            rot_nrr <= rot_nr;
         end
      end
   end

   (* mark_debug = "true" *) reg [$clog2(N)-1:0] out;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         out <= INIT;
      end else if (man_r[2]) begin
         out <= INIT;
      end else if ((man_r[1] || aut[1]) && ~(man_r[0] || aut[0])) begin
         if (out == N - 1) begin
            out <= SAT ? N - 1 : 0;
         end else begin
            out <= out + 1;
         end
      end else if (~(man_r[1] || aut[1]) && (man_r[0] || aut[0])) begin
         if (out == 0) begin
            out <= SAT ? 0 : N - 1;
         end else begin
            out <= out - 1;
         end
      end
   end

   assign counter_o = out;

endmodule
