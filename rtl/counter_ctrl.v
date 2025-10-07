module counter_ctrl(
    input clk, rst_n,
    input div_en, timer_en, halt_req,
    input [3 : 0] div_val,
    output cnt_en
);
    reg timer_en_d;
    wire default_mode;
    reg [7 : 0] limit = 1;
    // DEFAULT_MODE
    assign default_mode = timer_en && !div_en && !(halt_req);

    // CONTROL_MODE
    wire ctrl_mode;
    always@(*) begin
        if(div_en) begin
            case(div_val) 
                4'b0000 : limit = 8'd0;
                4'b0001 : limit = 8'd1;
                4'b0010 : limit = 8'd3;
                4'b0011 : limit = 8'd7;
                4'b0100 : limit = 8'd15;
                4'b0101 : limit = 8'd31;
                4'b0110 : limit = 8'd63;
                4'b0111 : limit = 8'd127;
                4'b1000 : limit = 8'd255;
                default : limit = 8'd0;
            endcase
        end else begin
            limit = 1;
        end
    end

    wire [7 : 0] cnt_limit_tmp;
    reg  [7 : 0] cnt_limit_r;

    assign cnt_limit_tmp = timer_en_d & !timer_en ? 8'b0 :  cnt_limit_r == limit && !(halt_req) ? 0 : 
                                                    div_en && timer_en && !(halt_req) ? 
                                                                                    cnt_limit_r + 1 : cnt_limit_r;
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt_limit_r <= 0;
            timer_en_d  <= 0;
            end
        else begin
            cnt_limit_r <= cnt_limit_tmp;
            timer_en_d  <= timer_en;
            end
    end
    assign ctrl_mode = cnt_limit_r == limit && timer_en && div_en && !(halt_req);
    assign cnt_en    =  div_en && !(halt_req)? ctrl_mode : default_mode;

endmodule
