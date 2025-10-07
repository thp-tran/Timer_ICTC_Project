module apb_slave#(
    parameter DATA_SIZE     = 32    ,
    parameter ADDR_SIZE     = 32    ,
    parameter PSTRB_SIZE    = 4     
)
(
    input                           pclk        ,
    input                           prst_n      ,
    input                           pwrite      ,
    input                           psel        ,
    input                           penable     ,
    input                           err_en      , //ERR FROM REGISTER FILES
    input [DATA_SIZE -  1 : 0  ]    pwdata      ,
    input [PSTRB_SIZE - 1 : 0  ]    pstrb       ,
    input [ADDR_SIZE -  1 : 0  ]    addr        ,
    output[DATA_SIZE -  1 : 0  ]    wdata       ,
    output                          wr_en       , 
    output                          rd_en       ,
    output                          pready      ,
    output                          pslverr
);
    
    reg     pready_r    ;
    wire    pready_tmp  ;

    assign pready_tmp = !pready_r ? psel && penable : ~pready_r;
    always@(posedge pclk or negedge prst_n) begin
        if(!prst_n)
            pready_r <= 0;
        else 
            pready_r <= pready_tmp;
    end
    assign wdata   = pwdata;
    assign pready  = pready_r;
    assign wr_en   = pready_r && psel && penable && pwrite;
    assign rd_en   = pready_r && psel && penable && !pwrite;
    assign pslverr = err_en;
endmodule
