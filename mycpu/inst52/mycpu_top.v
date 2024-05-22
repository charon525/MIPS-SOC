module mycpu_top(


    input aclk,
    input aresetn,  //low active
    input [5:0] ext_int,

//    //cpu inst sram
//    output        inst_sram_en   ,
//    output [3 :0] inst_sram_wen  ,
//    output [31:0] inst_sram_addr ,
//    output [31:0] inst_sram_wdata,
//    input  [31:0] inst_sram_rdata,
//    //cpu data sram
//    output        data_sram_en   ,
//    output [3 :0] data_sram_wen  ,
//    output [31:0] data_sram_addr ,
//    output [31:0] data_sram_wdata,
//    input  [31:0] data_sram_rdata,
    
    // debug信号
    output [31:0] debug_wb_pc, // pcW
    output [3:0] debug_wb_rf_wen, // 写寄存器使能信号
    output [4:0] debug_wb_rf_wnum, // 写回regfile的寄存器值WriteRegW
    output [31:0] debug_wb_rf_wdata, // 写入regfile的数据值ResultW
    
    //axi
    //ar  读地址通道
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      , // +++
    //r       读数据通道
    input  [3 :0] rid          , // +++
    input  [31:0] rdata        , // +++
    input  [1 :0] rresp        , // +++
    input         rlast        , // +++
    input         rvalid       , // +++
    output        rready       ,
    //aw          写地址通道
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      , // +++
    //w          写数据通道
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       , // +++
    //b           
    input  [3 :0] bid          , // +++
    input  [1 :0] bresp        , // +++
    input         bvalid       , // +++
    output        bready       
);

// 例子
	wire [31:0] pc;
	wire [31:0] instr;
//	wire memwrite;
	/*增添信号*/
	wire [3:0] sel;
	wire inst_en,data_en;
	/*结束*/
	wire [31:0] aluout, writedata, readdata;
	
	// SOC
	wire regwritetmp;
	
	// axi
	wire clk,resetn;
	assign clk = aclk;
	assign resetn = aresetn;
	//instr sram to sram like
    wire i_stall;
    wire longstall;  // mips传过来
   //data sram to sram like
    wire d_stall;

    // 刷去取出的错误指令
    wire flushF;
    reg flush;
    wire flush_long;
    reg flush_tmp;
    begin
        always@(resetn or i_stall or flushF) begin
            if(~resetn) begin
                flush = 1'b0;
            end else if(~i_stall | flushF) begin
                flush = flushF;
            end else begin
                flush = flush;
            end
        end
        always@(posedge clk) begin
            if(!resetn) begin
                flush_tmp <= 1'b0;
            end else begin
                flush_tmp <= flush;
            end
        end
    end
    assign flush_long = flush_tmp;

    // cache
    // i_cache
    wire cache_inst_req,cache_inst_wr;
    wire [1:0] cache_inst_size;
    wire [31:0] cache_inst_addr;
    wire [31:0] cache_inst_wdata;
    wire [31:0] cache_inst_rdata;
    wire cache_inst_addr_ok;
    wire cache_inst_data_ok;
    // d_cache
    wire cache_data_req,cache_data_wr;
    wire [1:0] cache_data_size;
    wire [31:0] cache_data_addr;
    wire [31:0] cache_data_wdata;
    wire [31:0] cache_data_rdata;
    wire cache_data_addr_ok;
    wire cache_data_data_ok;
    wire ades;

	
    mips mips(
        .clk(~clk),
        .rst(~resetn),
        //instr
        .inst_en(inst_en),
        .pcF(pc),                    //pcF
        .instrF(instr),              //instrF
        //data
        .data_en(data_en),
        // .memwriteM(memwrite),
        .sel(sel),
        .aluoutM(aluout),
        .writedataM(writedata),
        .readdataM(readdata),
        
        // 连接SOC
        .pcW(debug_wb_pc),
        .regwriteW(regwritetmp),
        .writeregW(debug_wb_rf_wnum),
        .resultW(debug_wb_rf_wdata),
        
        // axi
        .inst_on(i_stall),
        .data_on(d_stall),
        .longstall(longstall),
        .flushF(flushF),
        .flush(flush_long),

        // d_cache
        .ades(ades)
    );

    // SOC
    wire[31:0] instr_paddr,data_paddr;
    wire no_dcache;  //是否经过d cache
    mmu mmu(pc,instr_paddr,aluout,data_paddr,no_dcache);

    reg [31:0] inst_addr_tmp;
    reg do_finish_instr; //读指令事务结束
    always@(posedge clk) begin
        if(~resetn) begin
            inst_addr_tmp <= 32'b0;
        end else if(do_finish_instr) begin
            inst_addr_tmp <= instr_paddr;
        end else begin
            inst_addr_tmp <= inst_addr_tmp;
        end
    end

    //assign debug_wb_rf_wen = {4{regwritetmp&(~(i_stall | d_stall))}};
    assign debug_wb_rf_wen = {4{regwritetmp}};

    //cpu inst sram
    wire inst_sram_en;  //mips传过来
    //wire [3 :0] inst_sram_wen;
    wire [31:0] inst_sram_addr ; //inst_sram_addr  <---- instr_paddr（pc映射后的指令地址）
    //wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata; //inst_sram_rdata  <---- instr
    
    assign inst_sram_en = inst_en;
    assign inst_sram_addr = inst_addr_tmp; // +++
    // sram like 
    wire inst_req, inst_wr;
    wire [1:0] inst_size;
    wire [31:0] inst_addr;
    wire [31:0] inst_wdata;
    
    wire inst_addr_ok,inst_data_ok;
    wire [31:0] inst_rdata;
    reg   addr_rcv_instr; //地址握手成功
    // reg   do_finish_instr; //读指令事务结束
    // 保存读出来的数据
    reg [31:0] inst_rdata_save;
    begin
        always@(posedge clk) begin
            if(~resetn) begin
                addr_rcv_instr <= 1'b0;
            end else if(inst_req & inst_addr_ok & ~inst_data_ok) begin
                addr_rcv_instr <= 1'b1;
            end else if(inst_data_ok) begin
                addr_rcv_instr <= 1'b0;
            end else begin
                addr_rcv_instr <= addr_rcv_instr; // 防止发生latch锁存
            end
        end
        always @(posedge clk) begin
            if(~resetn) begin
                do_finish_instr <= 1'b0;
            end else if(inst_data_ok) begin
                do_finish_instr <= 1'b1;
            end else if(~longstall) begin
                do_finish_instr <= 1'b0;
            end else begin
                do_finish_instr <= do_finish_instr;
            end
        end
        always @(posedge clk) begin
            if(~resetn) begin
                inst_rdata_save <= 32'b0;
            end else if(inst_data_ok) begin
                inst_rdata_save <= inst_rdata;
            end else  begin
                inst_rdata_save <= inst_rdata_save;
            end
        end
    end

    //sram like
    assign inst_req = inst_sram_en & ~addr_rcv_instr & ~do_finish_instr; 
    assign inst_wr = 1'b0;
    assign inst_size = 2'b10;
    assign inst_addr = inst_sram_addr;
    assign inst_wdata = 32'b0;
    // sram
    assign inst_sram_rdata = inst_rdata_save;
    assign i_stall = inst_sram_en & ~do_finish_instr;
    assign instr = !flush && !flush_tmp ? inst_sram_rdata : 32'b0;
   
    //cpu data sram
    wire        data_sram_en   ;  // mips传过来
    wire [3 :0] data_sram_wen  ;// sel信号代替，mips传过来
    wire [31:0] data_sram_addr ; // aluout为读、写地址，mips传过来
    wire [31:0] data_sram_wdata; // writedata为待写入数据，mips传过来
    wire [31:0] data_sram_rdata;//readdata为读出数据，传入mips
    
    assign data_sram_en = data_en;
    assign data_sram_wen = sel;
    assign data_sram_addr = data_paddr;
    assign data_sram_wdata = writedata;

    // sram like
    wire data_req, data_wr;
    wire [1:0] data_size;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire [31:0] data_rdata;
    wire  data_addr_ok;
    wire  data_data_ok;

    reg addr_rcv_data; //地址握手成功
    reg do_finish_data; //读写事务结束
    reg [31:0] data_rdata_save;
    begin
        always @(posedge clk) begin
            if(~resetn) begin
                addr_rcv_data <= 1'b0;
            end else if(data_req & data_addr_ok & ~data_data_ok) begin
                addr_rcv_data <= 1'b1;
            end else if(data_data_ok) begin
                addr_rcv_data <= 1'b0;
            end else begin
                addr_rcv_data <= addr_rcv_data;
            end
        end
        always @(posedge clk) begin
            if(~resetn) begin
                do_finish_data <= 1'b0;
            end else if(data_data_ok) begin
                do_finish_data <= 1'b1;
            end else if(~longstall) begin
                do_finish_data <= 1'b0;
            end else begin
                do_finish_data <= do_finish_data;
            end
        end
        always @(posedge clk) begin
            if(~resetn) begin
                data_rdata_save <= 32'b0;
            end else if(data_data_ok) begin
                data_rdata_save <= data_rdata;
            end else begin
                data_rdata_save <= data_rdata_save;
            end
        end
    end

    //sram like
    assign data_size = (sel ==4'b0001 || sel ==4'b0010 || sel ==4'b0100 || sel ==4'b1000) ? 2'b00:
                       (sel ==4'b0011 || sel ==4'b1100 ) ? 2'b01 : 2'b10;
    assign data_req = data_sram_en & ~addr_rcv_data & ~do_finish_data;
    assign data_wr = data_sram_en & (|data_sram_wen);
    assign data_addr = data_sram_addr;
    assign data_wdata = data_sram_wdata;
    //sram
    assign data_sram_rdata = data_rdata_save;
    assign d_stall = data_sram_en & ~do_finish_data;
    assign readdata = data_sram_rdata;

    // cache
    i_cache_direct_map i_cache(
    .clk                (clk                ),
    .rst                (~resetn            ),
    // .flush              (flush_long         ),
    //mips core
    .cpu_inst_req       (inst_req           ),
    .cpu_inst_wr        (inst_wr            ),
    .cpu_inst_size      (inst_size          ),
    .cpu_inst_addr      (inst_addr          ),
    .cpu_inst_wdata     (inst_wdata         ),
    .cpu_inst_rdata     (inst_rdata         ),
    .cpu_inst_addr_ok   (inst_addr_ok       ),
    .cpu_inst_data_ok   (inst_data_ok       ),

    //sram-like interface
    .cache_inst_req     (cache_inst_req     ),
    .cache_inst_wr      (cache_inst_wr      ),
    .cache_inst_size    (cache_inst_size    ),
    .cache_inst_addr    (cache_inst_addr    ),
    .cache_inst_wdata   (cache_inst_wdata   ),
    .cache_inst_rdata   (cache_inst_rdata   ),
    .cache_inst_addr_ok (cache_inst_addr_ok ),
    .cache_inst_data_ok (cache_inst_data_ok )
    );

    d_cache_write_back d_cache(
    // d_cache_write_through d_cache(
    .clk                (clk                ),
    .rst                (~resetn            ),
    .ades               (ades               ), // 地址例外
    .no_dcache          (no_dcache          ), // 不经过cache
    //mips core
    .cpu_data_req       (data_req           ),
    .cpu_data_wr        (data_wr            ),
    .cpu_data_size      (data_size          ),
    .cpu_data_addr      (data_addr          ),
    .cpu_data_wdata     (data_wdata         ),
    .cpu_data_rdata     (data_rdata         ),
    .cpu_data_addr_ok   (data_addr_ok       ),
    .cpu_data_data_ok   (data_data_ok       ),

    //sram-like interface  
    .cache_data_req     (cache_data_req     ),
    .cache_data_wr      (cache_data_wr      ),
    .cache_data_size    (cache_data_size    ),
    .cache_data_addr    (cache_data_addr    ),
    .cache_data_wdata   (cache_data_wdata   ),
    .cache_data_rdata   (cache_data_rdata   ),
    .cache_data_addr_ok (cache_data_addr_ok ),
    .cache_data_data_ok (cache_data_data_ok )
    );
    
    cpu_axi_interface interface1(
    .clk(clk),
    .resetn(resetn),
    
    .inst_req(cache_inst_req), // cache_inst_req
    .inst_wr(cache_inst_wr), // cache_inst_wr
    .inst_size(cache_inst_size), // cache_inst_size
    .inst_addr(cache_inst_addr), // cache_inst_addr
    .inst_wdata(cache_inst_wdata), // cache_inst_wdata
    .inst_rdata(cache_inst_rdata), // cache_inst_rdata
    .inst_addr_ok(cache_inst_addr_ok), // cache_inst_addr_ok
    .inst_data_ok(cache_inst_data_ok), // cache_inst_data_ok

    // .inst_req(inst_req), // cache_inst_req
    // .inst_wr(inst_wr), // cache_inst_wr
    // .inst_size(inst_size), // cache_inst_size
    // .inst_addr(inst_addr), // cache_inst_addr
    // .inst_wdata(inst_wdata), // cache_inst_wdata
    // .inst_rdata(inst_rdata), // cache_inst_rdata
    // .inst_addr_ok(inst_addr_ok), // cache_inst_addr_ok
    // .inst_data_ok(inst_data_ok), // cache_inst_data_ok
    
    .data_req(cache_data_req), // cache_data_req 接入cache
    .data_wr(cache_data_wr), // cache_data_wr
    .data_size(cache_data_size), // cache_data_size
    .data_addr(cache_data_addr), // cache_data_addr
    .data_wdata(cache_data_wdata), // cache_data_wdata
    .data_rdata(cache_data_rdata), // cache_data_rdata
    .data_addr_ok(cache_data_addr_ok), // cache_data_addr_ok
    .data_data_ok(cache_data_data_ok), // cache_data_data_ok

    // .data_req(data_req), // 不接入cache
    // .data_wr(data_wr),
    // .data_size(data_size),
    // .data_addr(data_addr),
    // .data_wdata(data_wdata),
    // .data_rdata(data_rdata),
    // .data_addr_ok(data_addr_ok),
    // .data_data_ok(data_data_ok),
    
    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),
    
    .rid(rid),
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
    
    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),
    
    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
    
    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready)
    );
    
    
        // ascii
    instdec instdec(.instr(instr));
endmodule