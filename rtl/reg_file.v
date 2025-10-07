module reg_file#(
    parameter ADDR_SIZE     = 12    ,
    parameter DATA_SIZE     = 32    ,
    parameter PSTRB_SIZE    = 4     ,
    parameter DIV_VAL_SIZE  = 4     
)
(
    input                           sys_clk, sys_rst_n, // System signals
    input                           wr_en, rd_en, // Slave signals
    input   [ADDR_SIZE-1 : 0]       addr,   // Slave signal
    input   [DATA_SIZE-1 : 0]       wdata, 
    input   [63 : 0]                cnt, // From counter
    input                           dbg_mode, // From top
    input   [3 : 0]                 pstrb, 
    output  [DATA_SIZE-1 : 0]       rdata,
    output                          div_en, // Output for cnt_ctrl
    output  [DIV_VAL_SIZE-1 : 0]    div_val, // Output for cnt_ctrl
    output                          halt_req_out, // Output for cnt_ctrl
    output                          timer_en,
    output                          err_en,
    output  [DATA_SIZE-1 : 0]       wdata_counter,
    output  [7 : 0]                 reg_sel_out,
    output                          int_en
);
    // REGISTER ADDRESSES
    parameter TCR_ADDR      = 12'h00;
    parameter TDR0_ADDR     = 12'h04;
    parameter TDR1_ADDR     = 12'h08;
    parameter TCMP0_ADDR    = 12'h0c;
    parameter TCMP1_ADDR    = 12'h10;
    parameter TIER_ADDR     = 12'h14;
    parameter TISR_ADDR     = 12'h18;
    parameter THCSR_ADDR    = 12'h1c;
    // DEFAULT_VAL
    parameter DEFAULT_VAL   = 0     ;
    // REGISTER
    reg [7 : 0] reg_sel;
    reg [DATA_SIZE-1 : 0] tdr0_r    ;
    reg [DATA_SIZE-1 : 0] tdr1_r    ;
    reg [DATA_SIZE-1 : 0] tcmp0_r   ;
    reg [DATA_SIZE-1 : 0] tcmp1_r   ;
    reg [DATA_SIZE-1 : 0] tier_r    ;
    reg [DATA_SIZE-1 : 0] tisr_r    ;
    reg  [31 : 0] tcr_r;
    reg                   timer_en_d;
    // WIRE
    wire [31 : 0]           low_cnt         ;
    wire [DATA_SIZE-1 : 0]  tcmp0_tmp       ;
    wire [DATA_SIZE-1 : 0]  tcmp1_tmp       ;
    wire [DATA_SIZE-1 : 0]  tier_tmp        ;
    wire [DATA_SIZE-1 : 0]  tisr_tmp        ;
    wire                    div_en_tmp      ;
    wire                    timer_en_tmp    ;               
    wire [3 : 0]            div_val_tmp     ;
    wire [DATA_SIZE-1 : 0]  high_cnt        ;
    wire err_div_en;
    wire err_div_val0;
    wire err_div_val1;
    wire [31 : 0] tcr_tmp;
    wire [31 : 0] tcr_tmp1;
    // ONE HOT DESIGN
    always@(*) begin
        case(addr) 
            TCR_ADDR    :   reg_sel = 8'b00000001;
            TDR0_ADDR   :   reg_sel = 8'b00000010;
            TDR1_ADDR   :   reg_sel = 8'b00000100;
            TCMP0_ADDR  :   reg_sel = 8'b00001000;
            TCMP1_ADDR  :   reg_sel = 8'b00010000;
            TIER_ADDR   :   reg_sel = 8'b00100000;
            TISR_ADDR   :   reg_sel = 8'b01000000;
            THCSR_ADDR  :   reg_sel = 8'b10000000;
            default     :   reg_sel = 8'b00000000;
        endcase
    end
    // Mask bit 
    wire [31 : 0] mask;
    
    assign mask = { {8{pstrb[3]}}, {8{pstrb[2]}}, {8{pstrb[1]}}, {8{pstrb[0]} }};

    //TDR0 
    assign low_cnt  = cnt[DATA_SIZE-1 : 0];
    always@(*) begin
        if(!sys_rst_n) 
            tdr0_r = DEFAULT_VAL;
        else
            tdr0_r = low_cnt;
    end
    //TDR1
    assign high_cnt = cnt[63 : 32];
    always@(*) begin
        if(!sys_rst_n)
            tdr1_r = DEFAULT_VAL;
        else 
            tdr1_r = high_cnt;
    end

    //TCR
    assign err_div_en   = timer_en && wr_en && reg_sel[0] && (wdata[1] != div_en) && mask[1] == 1'b1;
    assign err_div_val0 = (reg_sel[0] && wr_en) && (wdata[11 : 8] >= 9) && mask[11 : 8] == 4'b1111;
    assign err_div_val1 = timer_en & wr_en & reg_sel[0] & (wdata[11 : 8] != div_val) & mask[11 : 8] == 4'b1111;
    assign err_en       = err_div_en | err_div_val0 | err_div_val1;
    assign timer_en_tmp = wr_en && reg_sel[0] && !err_en && mask[0] ? wdata[0] : timer_en;

    assign div_en_tmp = !timer_en && wr_en && reg_sel[0] && !err_en && mask[1] ? wdata[1] : div_en;

    assign div_val_tmp = !timer_en && wr_en && reg_sel[0] && (wdata[11 : 8] < 9) && mask[11 : 8] && !err_en ? wdata[11 : 8]  : div_val;
    assign tcr_tmp1 = {20'b0, div_val_tmp, 6'b0, div_en_tmp, timer_en_tmp};
    assign tcr_tmp = wr_en && reg_sel[0] ? (tcr_r & ~mask) | (tcr_tmp1 & mask) : tcr_r;
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) 
            tcr_r <= {20'b0, 4'b0001, 6'b0, 1'b0, 1'b0};
        else begin
            tcr_r <= tcr_tmp;
            timer_en_d <= timer_en;
            end
    end
    assign div_val  =   tcr_r[11 : 8];
    assign div_en   =   tcr_r[1];
    assign timer_en =   tcr_r[0];

    // TCMP0
    assign tcmp0_tmp = wr_en && reg_sel[3] ? (tcmp0_r & ~mask) | (wdata & mask) : tcmp0_r;
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) 
            tcmp0_r <= 32'hffffffff;
        else 
            tcmp0_r <= tcmp0_tmp;
    end
    // TCMP1
    assign tcmp1_tmp = wr_en && reg_sel[4] ? (tcmp1_r & ~mask) | (wdata & mask) : tcmp1_r;
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) 
            tcmp1_r <= 32'hffffffff;
        else 
            tcmp1_r <= tcmp1_tmp;
    end

    // TIER
    assign tier_tmp = wr_en && reg_sel[5] ? (tier_r[0] & ~mask) | (wdata[0] & mask) : tier_r;
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n)
            tier_r <= DEFAULT_VAL;
        else 
            tier_r <= tier_tmp;
    end
    assign int_en = tier_r[0] ? tisr_r[0] : 0;
    // TISR
    assign tisr_tmp = wdata[0] && wr_en && reg_sel[6] ? DEFAULT_VAL : 
                                                        ({tcmp1_r, tcmp0_r} == {tdr1_r, tdr0_r} ? 1'b1 : tisr_r);
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) 
            tisr_r <= DEFAULT_VAL;
        else 
            tisr_r <= tisr_tmp;
    end
    // THCSR 
    wire halt_ack_tmp;
    reg halt_req_r;
    wire halt_req_tmp;
    reg halt_ack_r;
    assign halt_ack_tmp = dbg_mode & halt_req_r;
    always@(*) begin
        if(!sys_rst_n)
            halt_ack_r = 0;
        else 
            halt_ack_r = halt_ack_tmp;
    end

    assign halt_req_tmp = wr_en && reg_sel[7] ? (halt_req_r & ~mask) | (wdata[0] & mask) : halt_req_r;
    always@(posedge sys_clk or negedge sys_rst_n) begin
        if(!sys_rst_n) 
            halt_req_r <= 0;
        else 
            halt_req_r <= halt_req_tmp;
    end

    assign halt_req_out = halt_ack_r;
    // READ 
    reg [DATA_SIZE-1 : 0] rdata_r;
    always@(*) begin
        if(rd_en) begin
            case(addr)
                TCR_ADDR    : rdata_r = {20'b0, tcr_r[11 : 8], 6'b0, tcr_r[1 : 0]};
                TDR0_ADDR   : rdata_r = tdr0_r;
                TDR1_ADDR   : rdata_r = tdr1_r;
                TCMP0_ADDR  : rdata_r = tcmp0_r;
                TCMP1_ADDR  : rdata_r = tcmp1_r;
                TIER_ADDR   : rdata_r = tier_r;
                TISR_ADDR   : rdata_r = tisr_r;
                THCSR_ADDR  : rdata_r = {30'h0,halt_ack_r, halt_req_r};
                default     : rdata_r = DEFAULT_VAL;
            endcase
        end else begin
            rdata_r = DEFAULT_VAL;
        end
    end
    assign rdata = rdata_r;
    assign reg_sel_out = reg_sel;
    assign wdata_counter   = wr_en && reg_sel[1] ? (tdr0_r & ~mask) | (wdata & mask) : (tdr1_r & ~mask) | (wdata & mask);
endmodule
