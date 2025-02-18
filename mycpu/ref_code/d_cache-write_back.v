module d_cache_write_back (
    input wire clk, rst, ades, no_dcache,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
    //Cache配置
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    
    //Cache存储单元
    reg                 cache_valid [CACHE_DEEPTH - 1 : 0];
    reg [TAG_WIDTH-1:0] cache_tag   [CACHE_DEEPTH - 1 : 0];
    reg [31:0]          cache_block [CACHE_DEEPTH - 1 : 0];
    reg cache_dirty [CACHE_DEEPTH-1:0]; //cache是否已被修改 为1时表示脏

    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //访问Cache line
    wire c_valid;
    wire [TAG_WIDTH-1:0] c_tag;
    wire [31:0] c_block;
    wire c_dirty;

    assign c_valid = cache_valid[index];
    assign c_tag   = cache_tag  [index];
    assign c_block = cache_block[index];
    assign c_dirty = cache_dirty[index];

    //判断是否命中
    wire hit, miss;
    assign hit = c_valid & (c_tag == tag) & ~no_dcache; // cache line的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;

    //读或写
    wire read, write;
    assign write = cpu_data_wr;
    assign read = cpu_data_req & ~write; // 请求数据且不写
    
    //数据是否被修改
    wire dirty,clean;
    assign dirty=c_dirty;
    assign clean=~dirty;

    // 提前声明数据
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    wire write_finish;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg in_RM; //确定是否处于RM状态
    reg [1:0] state;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            in_RM<=0;
        end
        else begin
            if(~ades)begin
                if(~no_dcache)begin // 经过cache时
                    case(state)
                        IDLE:begin
                            if(cpu_data_req)begin // 请求数据
                                if(hit)begin // 命中
                                    state<=IDLE; // 一周期处理完成
                                end
                                else if(miss&dirty)begin // 未命中且数据已被修改
                                    state<=WM; // 进入写数据阶段 
                                end
                                else if(miss&clean)begin // 未命中且数据未更改
                                    state<=RM; // 进入读阶段
                                end
                            end
                            in_RM<=0;//不处于读阶段
                        end
                        RM:begin
                            if(cache_data_data_ok)begin//读数据完成
                                state<=IDLE;//回到默认状态
                            end
                            in_RM<=1;//处于读阶段
                        end
                        WM:begin
                            if(cache_data_data_ok)begin//写数据完成
                                state<=RM;//写完读
                            end
                        end
                        default: state <= IDLE;
                    endcase
                end
                else begin // 不经过cache时
                    case(state)
                    IDLE:   state <= cpu_data_req & read & miss ? RM :
                                    //  cpu_data_req & read & hit  ? IDLE :
                                     cpu_data_req & write       ? WM : IDLE;
                    RM:     state <= read_finish ? IDLE : RM;
                    WM:     state <= write_finish ? IDLE : WM;
                    endcase
                end
            end
        end
    end

    //读内存
    //变量read_req, addr_rcv, read_finish用于构造类sram信号。
    wire read_req;      //一次完整的读事务，从发出读请求到结束
    reg addr_rcv;       //地址接受成功(addr_ok)后到结束
    // wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    read_req & cache_data_req & cache_data_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : addr_rcv;
    end
    assign read_req = state==RM;
    assign read_finish = read_req & cache_data_data_ok;

    //写内存
    wire write_req;     
    reg waddr_rcv;      
    // wire write_finish;   
    always @(posedge clk) begin
        waddr_rcv <= rst ? 1'b0 :
                     write_req & cache_data_req & cache_data_addr_ok ? 1'b1 :
                     write_finish ? 1'b0 : waddr_rcv;
    end
    assign write_req = state==WM;
    assign write_finish = write_req & cache_data_data_ok;

    // output to mips core
    assign cpu_data_rdata   = hit ? c_block : cache_data_rdata;
    assign cpu_data_addr_ok = no_dcache ? cache_data_req & cache_data_addr_ok : 
                                        (cpu_data_req & hit) | cache_data_req & read_req & cache_data_addr_ok;
    //                         请求数据且命中      数据缺失(若脏，先写数据，写完数据之后)进入读数据阶段
    assign cpu_data_data_ok = no_dcache ? cache_data_data_ok : 
                                        (cpu_data_req & hit) | cache_data_data_ok & read_req;
    //                         请求数据且命中      数据缺失   (若脏，先写数据，写完数据之后)进入读数据阶段

    //output to axi interface
    assign cache_data_req   = read_req & ~addr_rcv | write_req & ~waddr_rcv;
    assign cache_data_wr    = write_req;
    assign cache_data_size  = cpu_data_size;
    assign cache_data_addr  = no_dcache ? cpu_data_addr : cache_data_wr?{c_tag,index,offset}:cpu_data_addr;
    //                                                  写入内存的数据地址        原tag  相同的索引  以当前偏移量写入
    assign cache_data_wdata = no_dcache ? cpu_data_wdata : c_block;
    //                                                  写入内存的数据为原数据

    //写入Cache
    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
    end

    wire [31:0] write_cache_data;
    wire [3:0] write_mask;

    //根据地址低两位和size,生成写掩码（针对sb，sh等不是写完整一个字的指令），4位对1个字（4字节）中每个字的写使能
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //掩码的使用：位为1的代表需要更新的。
    //位拓展{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data = cache_block[index] & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    wire isIDLE= state==IDLE;
    integer t;
    always @(negedge clk) begin
        if(rst ) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache置为无效  脏位置0
                cache_valid[t] = 0;
                cache_dirty[t] = 0;
            end
        end
        else begin
            if(~no_dcache )begin // 当经过d_cache时才需要修改cache
                if(read_finish) begin //已完成读内存且得到数据
                    cache_valid[index_save] <= 1'b1;             //将Cache line置为有效
                    cache_tag  [index_save] <= tag_save;
                    cache_block[index_save] <= cache_data_rdata; //写入Cache line
                    cache_dirty[index_save] <= 0;//新读出的数据为clean
                end
                else if(write & isIDLE & (hit | in_RM)) begin
                // 写数据且       命中返回至IDLE阶段 或 未命中从读内存阶段回到IDLE阶段
                    cache_block[index] <= write_cache_data;      
                //写入Cache line，使用index而不是index_save
                    cache_dirty[index]<=1; //写入cache时将脏位置1
                end
            end
        end
    end
    // always @(negedge clk)begin
    //     if(~rst & ~no_dcache & ~read_finish & write & isIDLE & (hit | in_RM)) begin
    //         cache_block[index] <= write_cache_data;
    //         cache_dirty[index] <= 1;
    //     end
    // end
endmodule
