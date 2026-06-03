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



`timescale 1 ps / 1 ps

module intel_avst_dp_scfifo #(
    parameter SYMBOLS_PER_BEAT   = 1,
    parameter USE_PACKET         = 1,
    parameter BITS_PER_SYMBOL    = 8,
    parameter FIFO_DEPTH         = 16,
    parameter ERROR_WIDTH        = 0,
    parameter USE_OUT_FILL_LEVEL = 0
)(
    clk,
    reset_n,

    in_data,
    in_valid,
    in_ready,
    in_startofpacket,
    in_endofpacket,
    
    out_data,
    out_valid,
    out_ready,
    out_startofpacket,
    out_endofpacket,
    out_fifo_fill_level,
    in_error,
    out_error
);
    localparam DATA_WIDTH           = SYMBOLS_PER_BEAT * BITS_PER_SYMBOL;
    localparam ADDR_WIDTH           = log2ceil(FIFO_DEPTH);
    localparam PAYLOAD_WIDTH        = USE_PACKET ? (DATA_WIDTH + ERROR_WIDTH + 2) : (DATA_WIDTH + ERROR_WIDTH); // 1 sop + 1 eop
    localparam SYNC_DEPTH           = 3;
    
    input                           clk;
    input                           reset_n;
                           
    // sink                         
    input [DATA_WIDTH - 1 : 0]      in_data;
    input                           in_valid;
    output reg                      in_ready;
    input                           in_startofpacket;
    input                           in_endofpacket;
    input [((ERROR_WIDTH > 0)   ? ERROR_WIDTH - 1   : 0) : 0] in_error;
    // source
    output reg [DATA_WIDTH - 1 : 0] out_data;
    output reg                      out_valid;
    input                           out_ready;
    output reg                      out_startofpacket;
    output reg                      out_endofpacket;
    output reg [((ERROR_WIDTH > 0)   ? ERROR_WIDTH - 1   : 0) : 0] out_error;
    output wire [ADDR_WIDTH : 0]    out_fifo_fill_level;
    
    wire read, write, next_empty, next_full;
    wire internal_out_ready;
    wire [ADDR_WIDTH-1 : 0] next_wr_ptr;
    wire [ADDR_WIDTH-1 : 0] next_rd_ptr;
    wire [ADDR_WIDTH-1 : 0] incremented_wr_ptr;
    wire [ADDR_WIDTH-1 : 0] incremented_rd_ptr;
    
    reg [ADDR_WIDTH-1 : 0]  wr_ptr;
    reg [ADDR_WIDTH-1 : 0]  rd_ptr;
    reg empty, full, internal_out_valid;
    reg [PAYLOAD_WIDTH - 1 : 0] in_payload, out_payload, internal_out_payload;
    
    assign read = internal_out_ready && internal_out_valid;
    assign write = in_ready && in_valid;
    assign in_ready = !full;
    assign internal_out_ready = out_ready || !out_valid;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            internal_out_valid <= 0;
        else begin
            if (read && (incremented_rd_ptr == wr_ptr)) begin
                internal_out_valid <= 1'b0;
            end
            else begin
                internal_out_valid <= !empty;
            end
        end
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            out_valid   <= 1'b0;
            out_payload <= {PAYLOAD_WIDTH{1'b0}};
        end
        else if (internal_out_ready) begin 
            out_valid   <= internal_out_valid;
            out_payload <= internal_out_payload;
        end
    end
            
    generate if (ERROR_WIDTH > 0) begin
    	if (USE_PACKET) begin
            assign in_payload = {in_startofpacket, in_endofpacket, in_data, in_error};
            assign {out_startofpacket, out_endofpacket, out_data, out_error} = out_payload;
        end
        else begin
            assign in_payload = {in_data, in_error};
            assign {out_data, out_error} = out_payload;
        end
    end
    else begin
    	if (USE_PACKET) begin
            assign in_payload = {in_startofpacket, in_endofpacket, in_data};
            assign {out_startofpacket, out_endofpacket, out_data} = out_payload;
        end
        else begin
            assign in_payload = in_data;
            assign out_data = out_payload;
        end
    end
    endgenerate

    assign next_full = (read && !write) ? 1'b0 :
                         (write && !read) ? (incremented_wr_ptr == rd_ptr) : full;
                         
    assign next_empty = (read && !write) ? (incremented_rd_ptr == wr_ptr) :
                         (write && !read) ? 1'b0 : empty;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            empty <= 1;
            full  <= 0;
        end
        else begin 
            empty <= next_empty;
            full  <= next_full;
        end
    end
    
    // ---------------------------------------------------------------------
    // Pointer Management
    //
    // Increment our good old read and write pointers on their native
    // clock domains.
    // ---------------------------------------------------------------------
    assign incremented_wr_ptr = wr_ptr + 1'b1;
    assign incremented_rd_ptr = rd_ptr + 1'b1;
    assign next_wr_ptr = (write) ? incremented_wr_ptr : wr_ptr;
    assign next_rd_ptr = (read) ? incremented_rd_ptr : rd_ptr;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end
        else begin
            wr_ptr <= next_wr_ptr;
            rd_ptr <= next_rd_ptr;
        end
    end

    generate if (USE_OUT_FILL_LEVEL) begin
        reg [ADDR_WIDTH : 0] out_fill_level;
        always @(posedge clk or negedge reset_n) begin
            if (!reset_n) 
                out_fill_level <= 0;
            else if (next_full)
                out_fill_level <= FIFO_DEPTH[ADDR_WIDTH:0];
            else begin
                out_fill_level[ADDR_WIDTH]       <= 1'b0;
                out_fill_level[ADDR_WIDTH-1 : 0] <= next_wr_ptr - next_rd_ptr;
            end
        end

        assign out_fifo_fill_level = out_fill_level + {{ADDR_WIDTH{1'b0}}, out_valid};
    end
    else begin
        assign out_fifo_fill_level = {ADDR_WIDTH+1{1'b0}};
    end
    endgenerate
    
    //Options for altera_syncram primitive component, both etools library and altera primitive library has the same instance name
    //||    Option      ||      Description          ||         Device          ||
    //||    option 1    ||  DM ETOOLS primitive      ||      Diamond Mesa       ||
    //||    option 2    ||  Default altera primitive ||      Other devices      || 
    altera_syncram  altera_syncram_component (
                .aclr1 (1'b0),
                .address_a (wr_ptr),
                .address_b (next_rd_ptr),
                .clock0 (clk),
                .clock1 (clk),
                .data_a (in_payload),
                .wren_a (write),
                .q_b (internal_out_payload),
                .aclr0 (1'b0),
                .address2_a (1'b1),
                .address2_b (1'b1),
                .addressstall_a (1'b0),
                .addressstall_b (1'b0),
                .byteena_a (1'b1),
                .byteena_b (1'b1),
                .clocken0 (1'b1),
                .clocken1 (1'b1),
                .clocken2 (1'b1),
                .clocken3 (1'b1),
                .data_b ({PAYLOAD_WIDTH{1'b1}}),
                .eccencbypass (1'b0),
                .eccencparity (8'b0),
                .eccstatus (),
                .q_a (),
                .rden_a (1'b1),
                .rden_b (1'b1),
                .sclr (1'b0),
                .wren_b (1'b0));
    defparam
        altera_syncram_component.address_aclr_b  = "NONE",
        altera_syncram_component.address_reg_b  = "CLOCK1",
        altera_syncram_component.clock_enable_input_a  = "BYPASS",
        altera_syncram_component.clock_enable_input_b  = "BYPASS",
        altera_syncram_component.clock_enable_output_b  = "BYPASS",
        altera_syncram_component.intended_device_family  = "Stratix 10",
        altera_syncram_component.lpm_type  = "altera_syncram",
        altera_syncram_component.numwords_a  = FIFO_DEPTH,
        altera_syncram_component.numwords_b  = FIFO_DEPTH,
        altera_syncram_component.operation_mode  = "DUAL_PORT",
        altera_syncram_component.outdata_aclr_b  = "NONE",
        altera_syncram_component.outdata_sclr_b  = "NONE",
        altera_syncram_component.outdata_reg_b  = "UNREGISTERED",
        //power_up_uninitialized changed to TRUE as easic doesnt support "FALSE" value
        altera_syncram_component.power_up_uninitialized = "TRUE",
        altera_syncram_component.widthad_a  = ADDR_WIDTH,
        altera_syncram_component.widthad_b  = ADDR_WIDTH,
        altera_syncram_component.width_a  = PAYLOAD_WIDTH,
        altera_syncram_component.width_b  = PAYLOAD_WIDTH,
        altera_syncram_component.width_byteena_a  = 1;
    
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
		
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "BfqIHX5jPZBjp297qyQnoddY/ZUy/a6P9WRLOPOfmf0u0plst+Bp5jXfJiNaTOCVXakwwTrEFblSY7a/xf5BFdWNRBCBRv9U4qfHa4V//puVI7hQNkrXX13e2aMl6uc6s/9+E1LxNWOtnFcB2x0G6sF4ZO3VDIbI3lHk7CilVtIVFXdauUq+rO8qIF3n/PvX1zVRrRBJbLmBjPQgI3HmNR2N7VPos5peQ/Z5PmBnqGuJoxo8V6uCfqCZViuzoS5dYAktJW49q+mNXCR/MGskYeretEOeVEoAY/DK60aAJyptmJkH9WCgxPIbrZ57mfCuocIpLmA4apKOkzsO4kXcJYWUuLkcXOrUcI77hNbUMlkbKrIt8Oku/GmW4lkCuQWg/6diOqji8gk/xFAr9saOBMx00gdT64d1z9nx6vjWBe2XfAROw+T/3JnB/ocZsAh0Mag329blsEBy9BWG7JGD6sjROy6yLJcqo7xlwlZgrpGZlbkNNGJHJ5OySWl3OpPscdFZeNR+VFo6y+SzW0yAJa22j/9hlMtpJu0z+g3f/pT4t8O/ymcd8SXpz7y1QFcUOIdj7oH9x+pvcftFVgYbxnEDNO1kNN8J6YncuP0l+zsomXNeWO6rxOktcwogNXITHn7I8GM6bmImbpPHZaSyI7ZpvZmgV4UcLZv0uvBpZ++P3H4sVJ/sUIeLKex2qLiGSxc0nQt6EVnPL5hk5I+kGnpsnJJ0nyX7+554WmlF0hBMA8bgt650EeMih3yZl+rTC7roR38IS/T0FipXA8RB4ezXzKh90YXizCiComrH8m9qm2PJhFQVzTEwy16+G6spgro7xeI5E5LfcDO8pDsBy6lxquFOPs/fgOHiTsMeVdEdsTyQJYRDwW1MaMKTMfZXlk72BXmWg4MmGl5r/hQsHUxKk9rQN6n1al5pZuLjrZkShQR0IJCQDN4xsguf/2KGFeWnleRK5++AYjZ6AUOeOycI7yOvobsoRqTRmlquee7fGEmwqlHYFyIFBv4HoOuX"
`endif