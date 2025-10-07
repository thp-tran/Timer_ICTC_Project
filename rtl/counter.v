module counter#
(
    parameter DATA_SIZE = 32,
    parameter CNT_SIZE  = 64
)
(
    input clk, rst_n,
    input cnt_en,
    input [DATA_SIZE-1 : 0] wdata,
    input [7 : 0] reg_sel,
    input wr_en,
    input timer_en,
    output [CNT_SIZE-1 : 0] cnt
);
    reg                      timer_en_d = 0;
    reg     [CNT_SIZE-1 : 0] cnt_r;
    wire    [CNT_SIZE-1 : 0] cnt_tmp;
    wire    [CNT_SIZE-1 : 0] cnt_nxt;
    wire tdr0_sel, tdr1_sel;
    assign tdr0_sel = wr_en && reg_sel[1];
    assign tdr1_sel = wr_en && reg_sel[2];
    assign cnt_tmp[31 :  0] = tdr0_sel ? wdata : cnt_r[31 :  0]  ;
    assign cnt_tmp[63 : 32] = tdr1_sel ? wdata : cnt_r[63 : 32]  ;
    assign cnt_nxt          = timer_en_d & !timer_en ? 64'b0 : tdr1_sel || tdr0_sel ? cnt_tmp :
                                                     cnt_en  ? cnt_r + 1 : cnt_r;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt_r <= 0;
        else 
            cnt_r <= cnt_nxt;
    end
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n)
            timer_en_d <= 0;
        else 
            timer_en_d <= timer_en;
    end
    assign cnt = cnt_r;
endmodule 
