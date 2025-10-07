module top(
    input               sys_clk, sys_rst_n                  ,
    input               tim_psel, tim_pwrite, tim_penable   ,
    input   [31 : 0]    tim_paddr                            ,
    input   [31 : 0]    tim_pwdata                          ,
    output  [31 : 0]    tim_prdata                          , 
    input   [3 :  0]    tim_pstrb                           ,
    output              tim_pready                          ,
    output              tim_pslverr                         ,
    output              tim_int                             ,
    input               dbg_mode
);
    reg                 tim_pslverr_r               ;
    wire                pslverr, tim_pslverr_tmp    ;
    wire                err_en_tmp, pready_tmp      ;
    wire                wr_en_tmp, rd_en_tmp        ; 
    wire [31 : 0]       rdata_tmp                   ;
    wire [63 : 0]       cnt_tmp                     ;
    wire [31 : 0]       wdata                       ;
    wire                halt_req_tmp                ;
    wire                timer_en_tmp                ;
    wire [7 : 0]        reg_sel_tmp                 ;
    wire [3 : 0]        div_val_tmp                 ;
    wire                div_en_tmp                  ;
    wire [31 : 0]       wdt                         ;
    assign tim_prdata = rdata_tmp;
    assign tim_pready = pready_tmp;
    apb_slave slave(
                     .pwdata    ( tim_pwdata  )     ,
                     .addr      ( tim_paddr   )     ,  
                     .pclk      ( sys_clk     )     ,
                     .prst_n    ( sys_rst_n   )     ,
                     .psel      ( tim_psel    )     ,
                     .penable   ( tim_penable )     ,
                     .pwrite    ( tim_pwrite  )     ,
                     .pstrb     ( tim_pstrb   )     ,
                     .pready    ( pready_tmp  )     ,
                     .pslverr   ( tim_pslverr )     ,
                     .err_en    ( err_en_tmp  )     ,
                     .wr_en     ( wr_en_tmp   )     ,
                     .wdata     ( wdata       )     ,
                     .rd_en     ( rd_en_tmp   )
    );

    reg_file register(
                    .dbg_mode       ( dbg_mode          )   ,
                    .sys_clk        ( sys_clk           )   ,
                    .sys_rst_n      ( sys_rst_n         )   ,
                    .wr_en          ( wr_en_tmp         )   ,
                    .rd_en          ( rd_en_tmp         )   ,      
                    .addr           ( tim_paddr[11 : 0] )   ,
                    .wdata          ( wdata             )   ,
                    .rdata          ( rdata_tmp         )   ,
                    .cnt            ( cnt_tmp           )   ,
                    .div_en         ( div_en_tmp        )   ,
                    .div_val        ( div_val_tmp       )   ,
                    .halt_req_out   ( halt_req_tmp      )   ,
                    .timer_en       ( timer_en_tmp      )   ,
                    .err_en         ( err_en_tmp        )   ,
                    .int_en         ( tim_int           )   ,
                    .reg_sel_out    ( reg_sel_tmp       )   ,
                    .wdata_counter  ( wdt               )   ,
                    .pstrb          ( tim_pstrb         )
    );

    counter_ctrl counter_contrl(
                               .clk         ( sys_clk       )   ,
                               .rst_n       ( sys_rst_n     )   ,
                               .div_en      ( div_en_tmp    )   ,
                               .div_val     ( div_val_tmp   )   ,
                               .halt_req    ( halt_req_tmp  )   ,
                               .cnt_en      ( cnt_en_tmp    )   ,
                               .timer_en    ( timer_en_tmp  )
    );

    counter cnt(
                .timer_en   ( timer_en_tmp  )   ,
                .clk        ( sys_clk       )   ,
                .rst_n      ( sys_rst_n     )   ,
                .cnt_en     ( cnt_en_tmp    )   ,
                .wdata      ( wdt           )   ,
                .reg_sel    ( reg_sel_tmp   )   ,
                .wr_en      ( wr_en_tmp     )   ,
                .cnt        ( cnt_tmp       )
            
    );
endmodule
