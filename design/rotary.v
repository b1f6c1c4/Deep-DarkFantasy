module rotary #(
   parameter N = 12,
   parameter INIT = 0,
   parameter SAT = 1,
   parameter T = 3
) (
   input clk_i,
   input rst_ni,

   input [T-1:0] rot_ni,
   output reg [$clog2(N)-1:0] counter_o
);

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
            if (pre_cnt < 40000) begin
               pre_cnt <= pre_cnt + 1;
            end else begin
               pre_cnt <= 0;
               pre_rot_nr <= pre_rot_n;
            end
         end else begin
            pre_cnt <= 0;
         end
      end
   end

   reg [31:0] cnt;
   reg [T-1:0] rot_nr, rot_nrr;
   always @(posedge clk_i, negedge rst_ni) begin
      if (~rst_ni) begin
         cnt <= 0;
         rot_nr <= {T{1'b1}};
         rot_nrr <= {T{1'b1}};
         counter_o <= INIT;
      end else if (rot_nrr == rot_nr) begin
         if (~&pre_rot_nr) begin
            rot_nr <= pre_rot_nr;
            cnt <= 0;
         end
      end else begin
         if (rot_nr != pre_rot_nr) begin
            rot_nr <= pre_rot_nr;
            cnt <= 0;
            if (rot_nr == {rot_nrr[0],rot_nrr[T-1:1]}
               && pre_rot_nr == {rot_nr[0],rot_nr[T-1:1]}) begin
               rot_nrr <= rot_nr;
               if (counter_o == N - 1) begin
                  counter_o <= SAT ? N - 1 : 0;
               end else begin
                  counter_o <= counter_o + 1;
               end
            end else if (rot_nr == {rot_nrr[T-2:0],rot_nrr[T-1]}
               && pre_rot_nr == {rot_nr[T-2:0],rot_nr[T-1]}) begin
               rot_nrr <= rot_nr;
               if (counter_o == 0) begin
                  counter_o <= SAT ? 0 : N - 1;
               end else begin
                  counter_o <= counter_o - 1;
               end
            end
         end else if (cnt < 200000) begin
            cnt <= cnt + 1;
         end else if (rot_nr == {rot_nrr[0],rot_nrr[T-1:1]}) begin
            cnt <= 0;
            rot_nrr <= rot_nr;
            if (counter_o == N - 1) begin
               counter_o <= SAT ? N - 1 : 0;
            end else begin
               counter_o <= counter_o + 1;
            end
         end else if (rot_nr == {rot_nrr[T-2:0],rot_nrr[T-1]}) begin
            cnt <= 0;
            rot_nrr <= rot_nr;
            if (counter_o == 0) begin
               counter_o <= SAT ? 0 : N - 1;
            end else begin
               counter_o <= counter_o - 1;
            end
         end else begin
            cnt <= 0;
            rot_nrr <= rot_nr;
         end
      end
   end

endmodule
