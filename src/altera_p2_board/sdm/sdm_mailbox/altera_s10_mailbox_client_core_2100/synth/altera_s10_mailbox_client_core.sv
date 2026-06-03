// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// $Id: //acds/rel/25.1.1/ip/pgm/altera_s10_mailbox_client/altera_s10_mailbox_client_core.sv#1 $
// $Revision: #1 $
// $Date: 2025/04/24 $
// $Author: psgswbuild $


`timescale 1 ns / 1 ns
module altera_s10_mailbox_client_core #(
        parameter CMD_FIFO_DEPTH                = 0,
        parameter URG_FIFO_DEPTH                = 0,
        parameter RSP_FIFO_DEPTH                = 0,
        parameter CMD_USE_MEMORY_BLOCKS         = 0,
        parameter URG_USE_MEMORY_BLOCKS         = 0,
        parameter RSP_USE_MEMORY_BLOCKS         = 0,
        parameter HAS_URGENT                    = 0,
        parameter HAS_STATUS                    = 0,
        parameter HAS_STREAM                    = 0,
        parameter STREAM_WIDTH                  = 0,
        parameter HAS_OFFLOAD                   = 0
    ) (
        input                           clk,
        input                           reset,
        
        input                           command_ready,
        output logic                    command_valid,
        output logic [31:0]             command_data,
        output logic                    command_startofpacket,
        output logic                    command_endofpacket,
        
        output logic                    response_ready,
        input                           response_valid,
        input [31:0]                    response_data,
        input                           response_startofpacket,
        input                           response_endofpacket,

        input                           urgent_ready,
        output logic                    urgent_valid,
        output logic [31:0]             urgent_data,

        input                           stream_ready,
        output logic                    stream_valid,
        output logic [STREAM_WIDTH-1:0] stream_data,
        input                           stream_active, 

        output logic                    avst_stream_ready,
        input                           avst_stream_valid,
        input [STREAM_WIDTH-1:0]        avst_stream_data,
       
        input [3:0]                     avmm_address,
        input                           avmm_write,
        input [31:0]                    avmm_writedata,
        input                           avmm_read,
        output logic [31:0]             avmm_readdata,
        output logic                    avmm_readdatavalid,
	// add waitrequest signal
	output logic					avmm_waitrequest,
        
        input                           command_invalid,

        output logic                    irq,
        
        // +------------------------------------------------------------------------------------------------------------------------
        // | Crypto interface:
        // | 1. User AXI clock input (used to clock AXI interface, will go through clock crosser in crypto fabric IP)
        // | 2. User AXI reset input (used to clock AXI interface, will go through clock crosser in crypto fabric IP)
        // | 3. SDM AXI target input from crypto fabric 
        // | 4. Mailbox client AXI target output interface to user
        // | 5. conduit signlas from crypto fabric for mailbox ISR: 
        // |    a. crypto_error_recovery_in_progress
        // |    b. crypto_memory_timeout
        // +------------------------------------------------------------------------------------------------------------------------
        //User AXI clock input/output to be connected to crypto fabric
        input                           axi_clk_in,
        
        //User AXI reset input/output to be connected to crypto fabric 
        input                           axi_reset_in,
        
        //SDM crypto fabric AXI target input
        input [3:0]                     crypto_axi_target_awid,           
        input [31:0]                    crypto_axi_target_awaddr,         
        input [7:0]                     crypto_axi_target_awlen,          
        input [2:0]                     crypto_axi_target_awsize,         
        input [1:0]                     crypto_axi_target_awburst,        
        input                           crypto_axi_target_awlock,         
        input [3:0]                     crypto_axi_target_awcache,        
        input [2:0]                     crypto_axi_target_awprot,         
        input [3:0]                     crypto_axi_target_awqos,          
        input                           crypto_axi_target_awvalid,        
        input [4:0]                     crypto_axi_target_awuser,         
        output logic                    crypto_axi_target_awready,        
        input [63:0]                    crypto_axi_target_wdata,          
        input                           crypto_axi_target_wlast,          
        output logic                    crypto_axi_target_wready,         
        input                           crypto_axi_target_wvalid,         
        input [7:0]                     crypto_axi_target_wstrb,          
        output logic [3:0]              crypto_axi_target_bid,            
        output logic [1:0]              crypto_axi_target_bresp,          
        output logic                    crypto_axi_target_bvalid,         
        input                           crypto_axi_target_bready,         
        output logic [63:0]             crypto_axi_target_rdata,          
        output logic [1:0]              crypto_axi_target_rresp,          
        output logic                    crypto_axi_target_rlast,          
        output logic                    crypto_axi_target_rvalid,         
        input                           crypto_axi_target_rready,         
        input [3:0]                     crypto_axi_target_arid,           
        input [31:0]                    crypto_axi_target_araddr,         
        input [7:0]                     crypto_axi_target_arlen,          
        input [2:0]                     crypto_axi_target_arsize,         
        input [1:0]                     crypto_axi_target_arburst,        
        input                           crypto_axi_target_arlock,         
        input [3:0]                     crypto_axi_target_arcache,        
        input [2:0]                     crypto_axi_target_arprot,         
        input [3:0]                     crypto_axi_target_arqos,          
        input                           crypto_axi_target_arvalid,        
        input [4:0]                     crypto_axi_target_aruser,         
        output logic                    crypto_axi_target_arready,        
        output logic [3:0]              crypto_axi_target_rid,            
        
        //Mailbox AXI target interface output to user
        output logic [3:0]              axi_target_awid,           
        output logic [31:0]             axi_target_awaddr,         
        output logic [7:0]              axi_target_awlen,          
        output logic [2:0]              axi_target_awsize,         
        output logic [1:0]              axi_target_awburst,        
        output logic                    axi_target_awlock,         
        output logic [3:0]              axi_target_awcache,        
        output logic [2:0]              axi_target_awprot,         
        output logic [3:0]              axi_target_awqos,          
        output logic                    axi_target_awvalid,        
        output logic [4:0]              axi_target_awuser,         
        input                           axi_target_awready,        
        output logic [63:0]             axi_target_wdata,          
        output logic                    axi_target_wlast,          
        input                           axi_target_wready,         
        output logic                    axi_target_wvalid,         
        output logic [7:0]              axi_target_wstrb,          
        input [3:0]                     axi_target_bid,            
        input [1:0]                     axi_target_bresp,          
        input                           axi_target_bvalid,         
        output logic                    axi_target_bready,         
        input [63:0]                    axi_target_rdata,          
        input [1:0]                     axi_target_rresp,          
        input                           axi_target_rlast,          
        input                           axi_target_rvalid,         
        output logic                    axi_target_rready,         
        output logic [3:0]              axi_target_arid,           
        output logic [31:0]             axi_target_araddr,         
        output logic [7:0]              axi_target_arlen,          
        output logic [2:0]              axi_target_arsize,         
        output logic [1:0]              axi_target_arburst,        
        output logic                    axi_target_arlock,         
        output logic [3:0]              axi_target_arcache,        
        output logic [2:0]              axi_target_arprot,         
        output logic [3:0]              axi_target_arqos,          
        output logic                    axi_target_arvalid,        
        output logic [4:0]              axi_target_aruser,         
        input                           axi_target_arready,        
        input [3:0]                     axi_target_rid,
        
        input                           crypto_error_recovery_in_progress,
        input                           crypto_memory_timeout
    );
    
    localparam CMD_FIFO_LEVEL_WIDTH = log2ceil(CMD_FIFO_DEPTH) + 1;
    localparam URG_FIFO_LEVEL_WIDTH = log2ceil(URG_FIFO_DEPTH) + 1;
    localparam RSP_FIFO_LEVEL_WIDTH = log2ceil(RSP_FIFO_DEPTH) + 1;
    
    logic                   sop_enable;
    logic [31:0]            cmd_in_data_fifo;
    logic                   cmd_in_valid_fifo;
    logic                   cmd_in_ready_fifo;
    logic                   cmd_in_sop_fifo;
    logic                   cmd_in_eop_fifo;

    logic [31:0]            urg_in_data_fifo;
    logic                   urg_in_valid_fifo;
    logic                   urg_in_ready_fifo;

    logic [31:0]            out_data_fifo;
    logic                   out_valid_fifo;
    logic                   out_ready_fifo;
    logic                   out_sop_fifo;
    logic                   out_eop_fifo;

    logic [31:0]            urg_data_fifo;
    logic                   urg_valid_fifo;
    logic                   urg_ready_fifo;

    logic [31:0]            rsp_fifo_out_data;
    logic [31:0]            rsp_fifo_out_data_dly;
    logic                   rsp_fifo_out_valid;
    logic                   rsp_fifo_out_ready;
    logic                   rsp_fifo_out_sop;
    logic                   rsp_fifo_out_eop;
    logic [31:0]            cmd_fifo_fill_level;
    logic [31:0]            urg_fifo_fill_level;
    logic [31:0]            rsp_fifo_fill_level;
    logic                   cmd_data_addr;
    logic                   cmd_eop_addr;
    logic                   urg_cmd_addr;
    logic                   cmd_fifo_info_addr;
    logic                   urg_fifo_info_addr;
    logic                   rsp_data_addr;
    logic                   rsp_fifo_info_addr;
    logic                   ier_addr;
    logic                   isr_addr;
    logic                   timer_1_addr;
    logic                   timer_2_addr;
    logic                   unused_addr;
    logic                   cmd_data_wr;
    logic                   cmd_eop_wr;
    logic                   urg_cmd_wr;
    logic                   ier_wr;
    logic                   timer_1_wr;
    logic                   timer_2_wr;
    logic                   timer_1_rd;
    logic                   timer_2_rd;
    logic                   cmd_fifo_info_rd;
    logic                   urg_fifo_info_rd;
    logic                   rsp_data_rd;
    logic                   rsp_fifo_info_rd;
    logic                   ier_rd;
    logic                   isr_rd;
    logic                   wo_rd;
    logic                   unused_rd;
    logic                   timer_1_timeout;
    logic                   timer_1_timeout_dly;
    logic                   timer_1_timeout_pulse;
    logic                   timer_2_timeout;
    logic [10 : 0]          cmd_length;
    logic [10 : 0]          beat_counter;
    logic [10 : 0]          next_beat_counter;
    logic                   last_command;
    logic                   timer_enable_1;
    logic [30:0]            timeout_period_1;   
    logic                   timer_enable_2;
    logic [30:0]            timeout_period_2;  
    logic [RSP_FIFO_LEVEL_WIDTH-1:0] rsp_fifo_fill_level_int;
    logic [CMD_FIFO_LEVEL_WIDTH-1:0] cmd_fifo_fill_level_int;  
    logic [URG_FIFO_LEVEL_WIDTH-1:0] urg_fifo_fill_level_int;
    
    logic crypto_memory_timeout_synced;
    logic crypto_error_recovery_in_progress_synced;
    
    logic cmd_fifo_full_reg;
    
    // +--------------------------------------------------
    // | Address decoder:
    // | cmd_fifo: the empty space inside the cmd fifo
    // | rsp_info: the fill level inside rsp fifo and
    // |           two bits: sop and eop of the packet
    // +--------------------------------------------------
    assign cmd_data_addr       = (avmm_address == 4'd0);
    assign cmd_eop_addr        = (avmm_address == 4'd1);
    assign cmd_fifo_info_addr  = (avmm_address == 4'd2);
    assign urg_cmd_addr        = (avmm_address == 4'd3);
    assign urg_fifo_info_addr  = (avmm_address == 4'd4);
    assign rsp_data_addr       = (avmm_address == 4'd5);
    assign rsp_fifo_info_addr  = (avmm_address == 4'd6);
    assign ier_addr            = (avmm_address == 4'd7);
    assign isr_addr            = (avmm_address == 4'd8);
    assign timer_1_addr        = (avmm_address == 4'd9);
    assign timer_2_addr        = (avmm_address == 4'd10);
    // Unused address are from 11 until 15, check MSB and 3rd bit is 1, or MSB, 1st and 2nd bit are 1 for 11.
    assign unused_addr         = ( avmm_address[3] & avmm_address[2] ) || ( avmm_address[3] & avmm_address[1] & avmm_address[0] );

    // +--------------------------------------------------
    // | Write enable
    // +--------------------------------------------------
	
    assign cmd_data_wr = cmd_data_addr & avmm_write & !avmm_waitrequest;
    assign cmd_eop_wr  = cmd_eop_addr  & avmm_write & !avmm_waitrequest;
    assign urg_cmd_wr  = urg_cmd_addr  & avmm_write & !avmm_waitrequest;
    assign ier_wr      = ier_addr      & avmm_write & !avmm_waitrequest;
    assign timer_1_wr  = timer_1_addr  & avmm_write & !avmm_waitrequest;
    assign timer_2_wr  = timer_2_addr  & avmm_write & !avmm_waitrequest;
													

    // +--------------------------------------------------
    // | Read enable
    // +--------------------------------------------------
	
    assign cmd_fifo_info_rd = cmd_fifo_info_addr & avmm_read & !avmm_waitrequest;
    assign urg_fifo_info_rd = urg_fifo_info_addr & avmm_read & !avmm_waitrequest;
    assign rsp_data_rd      = rsp_data_addr      & avmm_read & !avmm_waitrequest;
    assign rsp_fifo_info_rd = rsp_fifo_info_addr & avmm_read & !avmm_waitrequest;
    assign ier_rd           = ier_addr           & avmm_read & !avmm_waitrequest;
    assign isr_rd           = isr_addr           & avmm_read & !avmm_waitrequest;
    assign timer_1_rd       = timer_1_addr       & avmm_read & !avmm_waitrequest;
    assign timer_2_rd       = timer_2_addr       & avmm_read & !avmm_waitrequest;
    
    // These are WO register, return 0 when read happens
    assign wo_rd            = (cmd_data_addr | cmd_eop_addr | urg_cmd_addr) & avmm_read & !avmm_waitrequest;

    // Read transaction to unused address offset
    assign unused_rd        = unused_addr & avmm_read & !avmm_waitrequest;
	
    // +-------------------------------------------------
    // | Waitrequest signal
    // +-------------------------------------------------
    
    // assert waitrequest when :
    // 1) reset
    // 2) cmd_fifo is not ready , !cmd_in_ready_fifo 
    // 3) urg_fifo is not ready, !urg_in_ready_fifo 

    generate
        if (HAS_URGENT == 1) begin
			assign avmm_waitrequest			= reset | !cmd_in_ready_fifo | !urg_in_ready_fifo ;
		end else begin
			assign avmm_waitrequest			= reset | !cmd_in_ready_fifo ;
	    end
	endgenerate
	
    // +--------------------------------------------------
    // | SOP generator
    // +--------------------------------------------------
      always @(posedge clk) begin
         if (reset) begin
            sop_enable <= 1'b1;
         end
         else begin
            if (cmd_data_wr) 
               sop_enable <= 1'b0;
            if (cmd_eop_wr)
                sop_enable <= 1'b1;
         end
      end

    // +--------------------------------------------------
    // | Internal command FIFO control signals
    // +--------------------------------------------------
    assign cmd_in_data_fifo     = avmm_writedata;
    // only write when read is high, when fifo empty discard the value
    assign cmd_in_valid_fifo    = (cmd_data_wr | cmd_eop_wr) & cmd_in_ready_fifo & !cmd_fifo_full_reg;
    assign cmd_in_sop_fifo      = sop_enable;
    assign cmd_in_eop_fifo      = cmd_eop_wr;
    logic [31:0]        cmd_fifo_depth;
    logic [31:0]        cmd_fifo_empty_space;
    logic [31:0]        urg_fifo_depth;
    logic [31:0]        urg_fifo_empty_space;
    logic [31:0]        cmd_fifo_empty_space_combi;
    assign cmd_fifo_depth       = CMD_FIFO_DEPTH[31:0];
    assign cmd_fifo_empty_space = cmd_fifo_depth - cmd_fifo_fill_level;
    assign urg_in_valid_fifo = urg_cmd_wr & urg_in_ready_fifo;
    assign urg_fifo_depth       = URG_FIFO_DEPTH[31:0];
    assign urg_fifo_empty_space = urg_fifo_depth - urg_fifo_fill_level;
    assign cmd_fifo_empty_space_combi = cmd_fifo_depth - {{(32-CMD_FIFO_LEVEL_WIDTH){1'b0}}, cmd_fifo_fill_level_int};
    // +--------------------------------------------------
    // | Internal FIFO for imcomming command packet
    // +--------------------------------------------------
    intel_avst_dp_scfifo
    #(
    .SYMBOLS_PER_BEAT    (1),
    .USE_PACKET          (1),
    .BITS_PER_SYMBOL     (32),
    .FIFO_DEPTH          (CMD_FIFO_DEPTH),
    .ERROR_WIDTH         (0),
    .USE_OUT_FILL_LEVEL  (1)
    ) cmd_fifo
    (
    .clk                    (clk),
    .reset_n                (~reset),
    .in_data                (cmd_in_data_fifo),
    .in_valid               (cmd_in_valid_fifo),
    .in_ready               (cmd_in_ready_fifo),
    .in_startofpacket       (cmd_in_sop_fifo),
    .in_endofpacket         (cmd_in_eop_fifo),
    .out_data               (out_data_fifo),
    .out_valid              (out_valid_fifo),
    .out_ready              (out_ready_fifo),
    .out_startofpacket      (out_sop_fifo),
    .out_endofpacket        (out_eop_fifo),
    .out_fifo_fill_level    (cmd_fifo_fill_level_int),
    .in_error               (1'b0),
    .out_error              ()
    );
    
    always @(posedge clk) begin
       if (reset) begin
          cmd_fifo_fill_level <= {32{1'b0}};
       end
       else begin
          if (cmd_fifo_info_rd) 
             cmd_fifo_fill_level <= {{(32-CMD_FIFO_LEVEL_WIDTH){1'b0}}, cmd_fifo_fill_level_int};
       end
    end
    
    // +--------------------------------------------------
    // | Output mapping for command
    // +--------------------------------------------------
    assign out_ready_fifo           = command_ready; 
    assign command_valid            = (timer_1_timeout_pulse & command_ready) ? 1'b1:out_valid_fifo;
    assign command_data             = (timer_1_timeout_pulse & command_ready) ? 32'hDEADBEEF:out_data_fifo;
    assign command_startofpacket    = out_sop_fifo;
    assign command_endofpacket      = (timer_1_timeout_pulse & !last_command & command_ready) ? 1'b1:out_eop_fifo;

    // +--------------------------------------------------
    // | Internal FIFO for incomming urgent packet
    // +--------------------------------------------------
    generate
        if (HAS_URGENT == 1) begin
            intel_avst_dp_scfifo
            #(
            .SYMBOLS_PER_BEAT    (1),
            .USE_PACKET          (0),
            .BITS_PER_SYMBOL     (32),
            .FIFO_DEPTH          (URG_FIFO_DEPTH),
            .ERROR_WIDTH         (0),
            .USE_OUT_FILL_LEVEL  (1)
            ) urg_fifo
            (
            .clk                    (clk),
            .reset_n                (~reset),
            .in_data                (cmd_in_data_fifo),
            .in_valid               (urg_in_valid_fifo),
            .in_ready               (urg_in_ready_fifo),
            .in_startofpacket       (1'b0),
            .in_endofpacket         (1'b0),
            .out_data               (urg_data_fifo),
            .out_valid              (urg_valid_fifo),
            .out_ready              (urg_ready_fifo),
            .out_startofpacket      (),
            .out_endofpacket        (),
            .out_fifo_fill_level    (urg_fifo_fill_level_int),
            .in_error               (1'b0),
            .out_error              ()
            );
        end else begin 
            assign urg_data_fifo = '0;
            assign urg_valid_fifo = '0;
            assign urg_fifo_fill_level_int = '0;
            assign urg_in_ready_fifo = '0;
        end
    endgenerate
    
    
    always @(posedge clk) begin
       if (reset) begin
          urg_fifo_fill_level <= {32{1'b0}};
       end
       else begin
          if (urg_fifo_info_rd) 
             urg_fifo_fill_level <= {{(32-URG_FIFO_LEVEL_WIDTH){1'b0}}, urg_fifo_fill_level_int};
       end
    end

    // +--------------------------------------------------
    // | Output mapping for command
    // +--------------------------------------------------
    assign urg_ready_fifo           = urgent_ready; 
    assign urgent_valid             = urg_valid_fifo;
    assign urgent_data              = urg_data_fifo;


    // +--------------------------------------------------
    // | Internal response FIFO control signals
    // +--------------------------------------------------
    // Since the avmm readdata has latency of 2
    // flow the read signal and use this as ready 
    logic rsp_data_rd_dly1;
    logic rsp_data_rd_dly2;
    always_ff @(posedge clk) begin
        if (reset) begin 
            rsp_data_rd_dly1   <= '0;
            rsp_data_rd_dly2   <= '0;
        end
        else begin 
            rsp_data_rd_dly1   <= rsp_data_rd;
            rsp_data_rd_dly2   <= rsp_data_rd_dly1;
        end


    end

    // +--------------------------------------------------
    // | Internal FIFO for imcomming response packet
    // +--------------------------------------------------
    intel_avst_dp_scfifo
    #(
    .SYMBOLS_PER_BEAT    (1),
    .USE_PACKET          (1),
    .BITS_PER_SYMBOL     (32),
    .FIFO_DEPTH          (RSP_FIFO_DEPTH),
    .ERROR_WIDTH         (0),
    .USE_OUT_FILL_LEVEL  (1)
    ) rsp_fifo
    (
    .clk                    (clk),
    .reset_n                (~reset),
    .in_data                (response_data),
    .in_valid               (response_valid),
    .in_ready               (response_ready),
    .in_startofpacket       (response_startofpacket),
    .in_endofpacket         (response_endofpacket),
    .out_data               (rsp_fifo_out_data),
    .out_valid              (rsp_fifo_out_valid),
    .out_ready              (rsp_data_rd),
    .out_startofpacket      (rsp_fifo_out_sop),
    .out_endofpacket        (rsp_fifo_out_eop),
    .out_fifo_fill_level    (rsp_fifo_fill_level_int),
    .in_error               (1'b0),
    .out_error              ()
    );
    
    always @(posedge clk) begin
       if (reset) begin
          rsp_fifo_fill_level <= {32{1'b0}};
       end
       else begin
          if (rsp_fifo_info_rd) 
             rsp_fifo_fill_level <= {{(32-RSP_FIFO_LEVEL_WIDTH){1'b0}}, rsp_fifo_fill_level_int};
       end
    end
    
    //+--------------------------------------------------
    //| Interrupt enable register
    //+--------------------------------------------------
    logic en_data_valid;
    logic en_cmd_fifo_not_full;    
    logic en_command_invalid;
    logic en_eop_timeout;
    logic en_backpressure_timeout;
    logic en_crypto_memory_timeout;
    logic en_crypto_error_recovery_in_progress;
    logic en_wr_cmd_fifo_when_full;
    logic en_rd_rsp_fifo_when_empty;
    
    logic   irq_en;
    logic   irq_status;

    always_ff @(posedge clk) begin
        if (reset) begin 
            en_data_valid                           <= '0;
            en_cmd_fifo_not_full                    <= '0;
            en_command_invalid                      <= '0;
            en_eop_timeout                          <= '0;
            en_backpressure_timeout                 <= '0;
            en_crypto_memory_timeout                <= '0;
            en_crypto_error_recovery_in_progress    <= '0;
            en_wr_cmd_fifo_when_full                <= '0;
            en_rd_rsp_fifo_when_empty               <= '0;
        end
        else if (ier_wr) begin 
            en_data_valid                           <= avmm_writedata[0];
            en_cmd_fifo_not_full                    <= avmm_writedata[1];
            en_command_invalid                      <= avmm_writedata[3];
            en_eop_timeout                          <= avmm_writedata[4];
            en_backpressure_timeout                 <= avmm_writedata[5];
            en_crypto_memory_timeout                <= avmm_writedata[6];
            en_crypto_error_recovery_in_progress    <= avmm_writedata[7];
            en_wr_cmd_fifo_when_full                <= avmm_writedata[8];
            en_rd_rsp_fifo_when_empty               <= avmm_writedata[9];
        end
    end
    
    //+--------------------------------------------------
    //| Internal register logic for:
    //| 1. write to command fifo when FULL
    //| 2. read from response fifo when EMPTY
    //| to be used in "Interrupt Status Register" logic
    //+--------------------------------------------------
    logic cmd_data_wr_reg;
    logic cmd_eop_wr_reg;
    
    always_ff @(posedge clk) begin
        if (reset)
            cmd_data_wr_reg           <= '0;
        else begin 
            cmd_data_wr_reg <= cmd_data_wr;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset)
            cmd_eop_wr_reg           <= '0;
        else begin 
            cmd_eop_wr_reg <= cmd_eop_wr;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset)
            cmd_fifo_full_reg           <= '0;
        else begin 
            cmd_fifo_full_reg <= (cmd_fifo_empty_space_combi == 32'b0);
        end
    end
    
    logic rsp_data_rd_reg;
    logic rsp_fifo_empty_reg;
    
    always_ff @(posedge clk) begin
        if (reset)
            rsp_data_rd_reg           <= '0;
        else begin 
            rsp_data_rd_reg <= rsp_data_rd;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset)
            rsp_fifo_empty_reg           <= '0;
        else begin 
            rsp_fifo_empty_reg <= (rsp_fifo_fill_level_int == '0);
        end
    end

    //+--------------------------------------------------
    //| Interrupt status register
    //+--------------------------------------------------
    logic status_data_valid;
    logic status_cmd_fifo_not_full;
    logic status_wr_cmd_fifo_when_full;
    logic status_rd_rsp_fifo_when_empty;
    logic set_data_valid;
    logic set_cmd_fifo_not_full;
    logic set_wr_cmd_fifo_when_full;
    logic set_rd_rsp_fifo_when_empty;
    logic stream_active_asserted;
    logic eop_timeout;
    logic backpressure_timeout;
    logic crypto_memory_timeout_asserted;
    logic crypto_error_recovery_in_progress_asserted;
    
    assign set_data_valid               = rsp_fifo_out_valid;
    assign set_cmd_fifo_not_full        = (cmd_fifo_empty_space_combi == 32'b0) ? 1'b0 : 1'b1;
    assign set_wr_cmd_fifo_when_full    = ((cmd_data_wr_reg | cmd_eop_wr_reg) & (cmd_fifo_full_reg));
    assign set_rd_rsp_fifo_when_empty   = rsp_data_rd_reg & rsp_fifo_empty_reg;
    
    always_ff @(posedge clk) begin
        if (reset)
            status_data_valid           <= '0;
        else begin 
            if (set_data_valid)
                status_data_valid <= 1'b1;
            else
                status_data_valid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset)
            status_cmd_fifo_not_full <= '0;
        else begin 
            if (set_cmd_fifo_not_full)
                status_cmd_fifo_not_full <= 1'b1;
            else
                status_cmd_fifo_not_full <= '0;
        end
    end

    always_ff @(posedge clk) begin
        stream_active_asserted <= stream_active;
    end
    
    //eop_timeout and backpressure_timeout is clk_enabled. The value should be latched until reset 
    always_ff @(posedge clk) begin
        if (reset) begin 
            eop_timeout <= 1'b0;
        end else begin 
            if (timer_1_timeout) begin 
                eop_timeout <= 1'b1;
            end 
        end 
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin 
            backpressure_timeout <= 1'b0;
        end else begin 
            if (timer_2_timeout) begin 
                backpressure_timeout <= 1'b1;
            end 
        end 
    end
    
    always_ff @(posedge clk) begin
        crypto_memory_timeout_asserted <= crypto_memory_timeout_synced;
    end
    
    always_ff @(posedge clk) begin
        crypto_error_recovery_in_progress_asserted <= crypto_error_recovery_in_progress_synced;
    end
    
    //cmd_fifo and rsp_fifo protection logic. If user accidentally writes when cmd_fifo is full or reads when rsp_fifo is empty,
    //the respective error status will be triggered to inform the user of this programming flow error occurence.
    //the values will be latched till the user asserts the mailbox client reset
    always_ff @(posedge clk) begin
        if (reset)
            status_wr_cmd_fifo_when_full <= '0;
        else begin 
            if (set_wr_cmd_fifo_when_full)
                status_wr_cmd_fifo_when_full <= 1'b1;
        end
    end
    
    always_ff @(posedge clk) begin
        if (reset)
            status_rd_rsp_fifo_when_empty <= '0;
        else begin 
            if (set_rd_rsp_fifo_when_empty)
                status_rd_rsp_fifo_when_empty <= 1'b1;
        end
    end
    
    //+--------------------------------------------------
    //| IRQ
    //+--------------------------------------------------    
    logic irq_nxt;
    assign irq_nxt = (en_data_valid & status_data_valid) | (en_cmd_fifo_not_full & status_cmd_fifo_not_full) | (en_command_invalid & command_invalid) | stream_active_asserted | (en_eop_timeout & eop_timeout) | (en_backpressure_timeout & backpressure_timeout) | (en_crypto_memory_timeout & crypto_memory_timeout_asserted) | (en_crypto_error_recovery_in_progress & crypto_error_recovery_in_progress_asserted) | (en_wr_cmd_fifo_when_full & status_wr_cmd_fifo_when_full) | (en_rd_rsp_fifo_when_empty & status_rd_rsp_fifo_when_empty);
    always_ff @(posedge clk) begin
        if (reset)
            irq <= 1'b0;
        else
            irq <= irq_nxt;
    end

    //+--------------------------------------------------
    //| Avalon ReadData
    //+--------------------------------------------------
    logic [31:0] ier_readdata_internal;
    logic [31:0] isr_readdata_internal;
    logic [31:0] csr_readdata_next;
    logic [31:0] fifo_info_readdata_next;
    logic [31:0] rsp_fifo_fill_lv_eop_sop;
    logic [31:0] csr_readdata;
    logic [31:0] avmm_readdata_next;
    logic [31:0] timer_data_1;
    logic [31:0] timer_data_2;
    logic [31:0] timer_data_dly_1;
    logic [31:0] timer_data_dly_2;
    
    assign ier_readdata_internal = {22'h0, en_rd_rsp_fifo_when_empty, en_wr_cmd_fifo_when_full, en_crypto_error_recovery_in_progress , en_crypto_memory_timeout , en_backpressure_timeout, en_eop_timeout, en_command_invalid, 1'b0, en_cmd_fifo_not_full, en_data_valid};
    assign isr_readdata_internal = {22'h0, status_rd_rsp_fifo_when_empty, status_wr_cmd_fifo_when_full, crypto_error_recovery_in_progress_asserted , crypto_memory_timeout_asserted , backpressure_timeout, eop_timeout, command_invalid, stream_active_asserted, status_cmd_fifo_not_full, status_data_valid};
    assign csr_readdata_next = (ier_readdata_internal & {32{ier_rd}}) | (isr_readdata_internal & {32{isr_rd}});
    // Combine the rsp fifo fill level together with eop and sop information
    assign rsp_fifo_fill_lv_eop_sop = {rsp_fifo_fill_level[29:0], rsp_fifo_out_eop, rsp_fifo_out_sop};
    assign timer_data_1 = {timer_enable_1, timeout_period_1[30:0]};
    assign timer_data_2 = {timer_enable_2, timeout_period_2[30:0]};
    
    logic cmd_fifo_info_rd_dly;
    logic rsp_fifo_info_rd_dly;
    logic urg_fifo_info_rd_dly;
    logic fifo_info_rd_dly;
    logic csr_rd_dly;
    logic wo_rd_dly;
    logic unused_rd_dly;
    logic rd;
    logic timer_rd_dly_1;
    logic timer_rd_dly_2;
    // the csr from fifo take one cycles to have output
    // cmd_fifo_empty_space
    always_ff @(posedge clk) begin
        if (reset) begin 
            cmd_fifo_info_rd_dly <= '0;
            rsp_fifo_info_rd_dly <= '0;
            urg_fifo_info_rd_dly <= '0;
            fifo_info_rd_dly     <= '0;
            wo_rd_dly            <= '0;
            unused_rd_dly        <= '0;
            csr_rd_dly           <= '0;
            timer_rd_dly_1       <= '0;
            timer_rd_dly_2       <= '0;
        end
        else begin 
            cmd_fifo_info_rd_dly <= cmd_fifo_info_rd;
            rsp_fifo_info_rd_dly <= rsp_fifo_info_rd;
            urg_fifo_info_rd_dly <= urg_fifo_info_rd;
            fifo_info_rd_dly     <= cmd_fifo_info_rd | rsp_fifo_info_rd | urg_fifo_info_rd;
            wo_rd_dly            <= wo_rd;
            unused_rd_dly        <= unused_rd;
            csr_rd_dly           <= ier_rd | isr_rd;
            timer_rd_dly_1       <= timer_1_rd;
            timer_rd_dly_2       <= timer_2_rd;
        end
    end
    assign rd = cmd_fifo_info_rd_dly | rsp_fifo_info_rd_dly | fifo_info_rd_dly | csr_rd_dly | rsp_data_rd_dly1 | wo_rd_dly | unused_rd_dly | timer_rd_dly_1 | timer_rd_dly_2;
    assign fifo_info_readdata_next = (cmd_fifo_empty_space & {32{cmd_fifo_info_rd_dly}}) | (rsp_fifo_fill_lv_eop_sop & {32{rsp_fifo_info_rd_dly}}) | (urg_fifo_empty_space & {32{urg_fifo_info_rd_dly}});
    // fifo data out put 
    always_ff @(posedge clk) begin
        if (reset) 
            rsp_fifo_out_data_dly <= '0;
        else begin 
            if (rsp_data_rd)
                rsp_fifo_out_data_dly <= rsp_fifo_out_data;

        end
    end
    
    // timer 1 data output 
    always_ff @(posedge clk) begin
        if (reset) 
            timer_data_dly_1 <= '0;
        else begin 
            if (timer_1_rd)
                timer_data_dly_1 <= timer_data_1;
        end
    end
    
    // timer 2 data output 
    always_ff @(posedge clk) begin
        if (reset) 
            timer_data_dly_2 <= '0;
        else begin 
            if (timer_2_rd)
                timer_data_dly_2 <= timer_data_2;
        end
    end
    
    // Select output readdata
    always_comb begin
        if (fifo_info_rd_dly)
            avmm_readdata_next = fifo_info_readdata_next;
        else if (csr_rd_dly)
            avmm_readdata_next = csr_readdata;
        else if (rsp_data_rd_dly1)
            avmm_readdata_next = rsp_fifo_out_data_dly;
        else if (timer_rd_dly_1)
            avmm_readdata_next = timer_data_dly_1;
        else if (timer_rd_dly_2)
            avmm_readdata_next = timer_data_dly_2;
        else
            avmm_readdata_next = '0;
    
    end

    always_ff @(posedge clk) begin
        if (reset)
            csr_readdata <= 32'h0;
        else
            csr_readdata <= csr_readdata_next;
    end
    

    always_ff @(posedge clk) begin
        if (reset) begin 
            avmm_readdata <= 32'h0;
            avmm_readdatavalid <= '0;
        end
        else begin 
            avmm_readdata <= avmm_readdata_next;
            avmm_readdatavalid <= rd;
        end
    end

    //+--------------------------------------------------
    //| Streaming interface control logic
    //+--------------------------------------------------
    // For streaming, assign from user side avst to the output to SDM
    // there is no need logic to control this
    // For stream active, user is supposed to read from ISR 
    always_comb begin
        stream_valid       = avst_stream_valid;
        stream_data        = avst_stream_data;
        avst_stream_ready  = stream_ready;
    end
    
   // --------------------------------------------------
    // Calculates the log2ceil of the input value
    // --------------------------------------------------
    function integer log2ceil;
        input integer val;
        integer i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction
    
    //+--------------------------------------------------
    //| Detect command length 
    //+--------------------------------------------------
    // Get the command length for timer control
    // If the command transaction hangs at the last word of the command packet, send a dummy data and the reset_handler in driver will send the EOP and trigger erronemous_trigger condition
    // This will ensure erronemous_trigger condition is triggered, if we just send a fake EOP from client in this case, it will not. 
    // If the command transaction hangs before the last word of the command packet, send fake EOP from client, the reset_handler will detect that the length of command data doesn't match and will trigger erronemous_trigger condition
    // The beat_counter will start counting when the command comes in, so last_command => the second last word 
    always_ff @(posedge clk) begin
        if (reset)
            cmd_length <= '0;
        else begin 
            // Capture the length upfront from incoming packet
            if (out_valid_fifo & out_sop_fifo & out_ready_fifo)
                cmd_length <= out_data_fifo[22:12];
        end
    end // always_ff @
    
    // beat_counter: counts command beat (word) that is sending to output
    always_ff @(posedge clk) begin
        if (reset)
            beat_counter <= 11'h0;
        else  
            beat_counter <= next_beat_counter;
        end
    
    always_comb begin
        next_beat_counter = beat_counter;
        if (out_valid_fifo & out_ready_fifo) begin
            next_beat_counter  = beat_counter + 1'b1;
            if (out_eop_fifo)
                next_beat_counter  = '0;
        end
    end
    
    assign last_command = (beat_counter == cmd_length) ? 1'b1 : 1'b0;
    
    //+--------------------------------------------------
    //| Timer 1 register 
    //+-------------------------------------------------- 
    // When user writes to timer 1 or 2 CSR address, register timer_enable bit 31 to determine if timer should start or not (timer_enable). 
    // At the same time, register bit 30 to 0 as the timer_period, if user sets as all 0 , set to default value
    // After a timeout occurs, user wont be enable to set timer_enable without a reset, because it is guarded with timer_timeout. 
    always_ff @(posedge clk) begin
        if (reset) begin 
            timer_enable_1 <= 1'b0;
        end else begin 
            if (timer_1_wr & !timer_1_timeout) begin 
                timer_enable_1 <= avmm_writedata[31];
            end else if (timer_1_timeout) begin 
                timer_enable_1 <= 1'b0;
            end
        end 
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin 
            timeout_period_1        <= 31'h7FF_FFFF;
        end else begin 
            if (timer_1_wr & (avmm_writedata[30:0] != 0)) begin 
                timeout_period_1        <= avmm_writedata[30:0];
            end else if (timer_1_wr & (avmm_writedata[30:0] == 0)) begin 
                timeout_period_1        <= 31'h7FF_FFFF;
            end else begin 
                timeout_period_1        <= timeout_period_1;
            end
        end        
    end

    //+--------------------------------------------------
    //| Timer 2 register 
    //+--------------------------------------------------  
    always_ff @(posedge clk) begin
        if (reset) begin 
            timer_enable_2 <= 1'b0;
        end else begin 
            if (timer_2_wr & !timer_2_timeout) begin 
                timer_enable_2 <= avmm_writedata[31];
            end else if (timer_2_timeout) begin 
                timer_enable_2 <= 1'b0;
            end
        end 
    end
    
    always_ff @(posedge clk) begin
        if (reset) begin 
            timeout_period_2        <= 31'h7FF_FFFF;
        end else begin 
            if (timer_2_wr & (avmm_writedata[30:0] != 0)) begin 
                timeout_period_2        <= avmm_writedata[30:0];
            end else if (timer_2_wr & (avmm_writedata[30:0] == 0)) begin 
                timeout_period_2        <= 31'h7FF_FFFF;
            end else begin 
                timeout_period_2        <= timeout_period_2;
            end
        end        
    end

    //+--------------------------------------------------
    //| SOP control logic to qualify timer start or stop
    //+--------------------------------------------------
    logic     sop_detected;
    logic [30:0] countdown_value_1;
        
    always_ff @(posedge clk) begin 
        if (reset) begin
            sop_detected <= 1'b0;
        end else begin 
            if (out_sop_fifo && !out_eop_fifo) begin //When detect SOP, set sop_detected
                sop_detected <= 1'b1;
            end else if (!out_sop_fifo && out_eop_fifo) begin //When detect EOP, clear sop_detected
                sop_detected <= 1'b0;
            end 
        end 
    end 
    
    //+------------------------------------------------------
    //| Timer 1 counter logic - EOP missing error handling
    //+-----------------------------------------------------
    //Timer 1 will register timeout period when user reset, or when a new sop is detected. 
    //If a timeout occurs, it will stop running as timer_enable_1 will be deasserted, and countdown_value_1 will stay at 0
    //Timer 1 will start counting when timer is enabled, sop is detected, and there are no writes from the CMD_FIFO (valid is low) and the SDM is ready (ready is high)
    //For both timers, timer_timeout is set by countdown_value, after it hits 0 from a timeout, it can only be reset by a user reset, as it won't enter timer_enable condition again.
    always_ff @(posedge clk) begin 
        if (reset) begin 
            countdown_value_1 <= 31'h7FF_FFFF;
        end else begin
            if ( (timer_enable_1 & sop_detected & !out_valid_fifo & out_ready_fifo) & !timer_1_timeout) begin 
                countdown_value_1 <= countdown_value_1 - 1'b1;
            end else if (out_sop_fifo & !sop_detected) begin 
                countdown_value_1 <= timeout_period_1;
            end
        end 
    end 
    
    //+--------------------------------------------------------------------
    //| Timer 2 counter logic - SDM backpressuring error handling
    //+--------------------------------------------------------------------
    //Timer 2 will be reset when user reset, or or when a new sop is detected.
    //If a timeout occurs, it will stop running as timer_enable_2 will be deasserted, and countdown_value_2 will stay at 0
    //Timer 2 will start counting when timer is enabled, sop is detected, and when out_valid_fifo from FIFO to SDM is high (there's data to be sent to SDM) and out_ready_fifo is LOW (SDM not ready to receive data)
    logic [30:0] countdown_value_2;
    
    always_ff @(posedge clk) begin 
        if (reset) begin 
            countdown_value_2 <= 31'h7FF_FFFF;
        end else begin
            if ( (timer_enable_2 & sop_detected & out_valid_fifo & !out_ready_fifo) & !timer_2_timeout ) begin 
                countdown_value_2 <= countdown_value_2 - 1'b1;
            end else if (out_sop_fifo & !sop_detected)begin 
                countdown_value_2 <= timeout_period_2;
            end
        end 
    end 
    
    //+------------------------------------------------------------------
    //| Timer 1 timeout logic 
    //+------------------------------------------------------------------
    //countdown_value is XORed together, this only sets timeout when all bits are 0. 
    //Timer 1 timeout will trigger eop_timeout bit[4], this requires user reset to recover
    //guard timer_1_timeout_pulse with command_ready to ensure timer_timeout_pulse is prolonged if command_ready is not asserted. 
    assign timer_1_timeout = ~| countdown_value_1;
    
    always_ff @(posedge clk) begin 
        if (reset) begin 
            timer_1_timeout_dly <= 1'b0;
        end else begin
            if (command_ready) begin 
                timer_1_timeout_dly  <= timer_1_timeout;
            end
        end 
    end 
    
    //timer_1_timeout_pulse is used to ensure only 1 cyle of fake valid/data/eop is sent 
    assign timer_1_timeout_pulse = !timer_1_timeout_dly & timer_1_timeout;
    
    //+------------------------------------------------------------------
    //| Timer 2 timeout logic 
    //+------------------------------------------------------------------
    //Timer 2 timeout will trigger backpressure_timeout bit[5], this is a fatal error (user reset can't recover this) as something might be wrong with the SDM hard block
    assign timer_2_timeout = ~| countdown_value_2;
    
    //+--------------------------------------------------
    //| Crypto AXI target interface control logic
    //+--------------------------------------------------
    // For Crypto AXI target interface, assign from crypto fabric SDM output (memory target endpoint) to mailbox user side AXI target interface
    always_comb begin
        axi_target_awid                     = crypto_axi_target_awid;           
        axi_target_awaddr                   = crypto_axi_target_awaddr;       
        axi_target_awlen                    = crypto_axi_target_awlen;         
        axi_target_awsize                   = crypto_axi_target_awsize;       
        axi_target_awburst                  = crypto_axi_target_awburst;     
        axi_target_awlock                   = crypto_axi_target_awlock;       
        axi_target_awcache                  = crypto_axi_target_awcache;     
        axi_target_awprot                   = crypto_axi_target_awprot;       
        axi_target_awqos                    = crypto_axi_target_awqos;         
        axi_target_awvalid                  = crypto_axi_target_awvalid;     
        axi_target_awuser                   = crypto_axi_target_awuser;   
        crypto_axi_target_awready           = axi_target_awready; 
        axi_target_wdata                    = crypto_axi_target_wdata;          
        axi_target_wlast                    = crypto_axi_target_wlast;         
        crypto_axi_target_wready            = axi_target_wready;  
        axi_target_wvalid                   = crypto_axi_target_wvalid;         
        axi_target_wstrb                    = crypto_axi_target_wstrb;    
        crypto_axi_target_bid               = axi_target_bid;            
        crypto_axi_target_bresp             = axi_target_bresp;          
        crypto_axi_target_bvalid            = axi_target_bvalid;   
        axi_target_bready                   = crypto_axi_target_bready;         
        crypto_axi_target_rdata             = axi_target_rdata;          
        crypto_axi_target_rresp             = axi_target_rresp;          
        crypto_axi_target_rlast             = axi_target_rlast;          
        crypto_axi_target_rvalid            = axi_target_rvalid;  
        axi_target_rready                   = crypto_axi_target_rready;         
        axi_target_arid                     = crypto_axi_target_arid;           
        axi_target_araddr                   = crypto_axi_target_araddr;         
        axi_target_arlen                    = crypto_axi_target_arlen;          
        axi_target_arsize                   = crypto_axi_target_arsize;         
        axi_target_arburst                  = crypto_axi_target_arburst;        
        axi_target_arlock                   = crypto_axi_target_arlock;         
        axi_target_arcache                  = crypto_axi_target_arcache;        
        axi_target_arprot                   = crypto_axi_target_arprot;         
        axi_target_arqos                    = crypto_axi_target_arqos;          
        axi_target_arvalid                  = crypto_axi_target_arvalid;        
        axi_target_aruser                   = crypto_axi_target_aruser;  
        crypto_axi_target_arready           = axi_target_arready;        
        crypto_axi_target_rid               = axi_target_rid;  
    end
    
    //synchronize crypto_memory_timeout status from sdm's clock to mailbox client's clk (not synching to user_axi_clk because mbox AVMM and interrupt logic are all running on mailbox's generic clock)
    altera_std_synchronizer_bundle 
    #(
       .depth  ( 3 ),
       .width  ( 1 ) 
     ) crypto_memory_timeout_sync (
       .clk        ( clk ),
       .reset_n    ( 1'b1 ), //doesn't get reset by user clock. only way to reset this value is to allow SDM + soft IP to complete error recovery
       .din        ( crypto_memory_timeout ),
       .dout       ( crypto_memory_timeout_synced )
     );
     
     //synchronize crypto_memory_timeout status from from sdm's clock to mailbox client's clk (not synching to user_axi_clk because mbox AVMM and interrupt logic are all running on mailbox's generic clock)
     altera_std_synchronizer_bundle 
    #(
       .depth  ( 3 ),
       .width  ( 1 ) 
     ) crypto_error_recovery_in_progress_sync (
       .clk        ( clk ),
       .reset_n    ( 1'b1 ), //dpesn't get reset by user clock. only way to reset this value is to allow SDM + soft IP to complete error recovery
       .din        ( crypto_error_recovery_in_progress ),
       .dout       ( crypto_error_recovery_in_progress_synced )
     );
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "k/oU1TtIiVps3NAMy1TbDmVGP/Il8DrVvaJm70h4A8ngRF4fFemcOlXRaMOTTRhrq0BN4qOqj9x5iyd0cTK/fe88z7sxfH4tY+e9Tjl5X0HQ6M4fvKiIuE1gbCUGlKM+tRf7aAC7GxVMLRL76JURvkXpbEbtGwucZBIWK+WoesRFuf/N6ZSo5gEygGZ1bdfN9GO/RFG0/xAYUSYbAjk1e4ULZAqPgHSv9YoqT9AmeUrsTfZQxCLVh/N86413umOtHWWgUzBk3oUZ4TSaWH4wH47B+qoHL57t+3Sni3WuZebiqQl8okqlY/MzpXxpmxxezdyvKBSrxDvz56X0H1P1vYmzqxTaAA8n+b7uxfpsqi3fGRnd3UaeD0J2j2z9ma13YbCpGBagwwI2aVo+iOE7BOQ+iRS+Km1n6HAdoRLf5Gb4R+WwlePOhDTScXBwDBUBbFcRd33OaFrd0P4hEKkoGcc0q2nxDsGA53mkW+r+RrWQrYzfgQjR3t4XYC0F2rcbsO4ABZYR/8/ecCCxHeArE5MHLuCoQqltRIfkfIz26QkD85R95nBAl9cQCh+SOoB1qVwfL3gNJs5AEtZ/Zp3c9vkmz8VMfq5hoC4hRjAFBZl3f/HvqiYMt5V500rQ8LFFEQCeByh73lFbczOsYmLO30azgnQ6BmbPrMl2ZKBFrWuukgLoxYX9NWQBdn2ywLO6xYxYyxaXub4bNtie41qfIEtvT6TpqlzFbpXF20DaPrIviRsNyGUB09pxLaHEWukUSexGgb8p2BjIHHmIgUzX9+umw9iyrYZgaUSdeOFGRTzEvUGfK5XlgC7jNIsXJ//LDqNwxqMHGNtS4mtmQvDoF10GkQKI1efRCZT8v4lkkCYZdBz1xj3YO8HmsdoftVGA5aNEBIEWxUrEHPNieCJINAkuWKk0XtUK5X9L/favQgGcnGUY343nAnK/jqIubfuzmmOgf7gROOFHpF9u0KdkYPPNJKWNaANUawIRu+mFKa0+MDF0SsN4D8nZ4XSQW6zl"
`endif