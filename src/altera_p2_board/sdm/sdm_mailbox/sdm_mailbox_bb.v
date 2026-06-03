module sdm_mailbox (
		input  wire        in_clk_clk,         //   in_clk.clk,          Clock Input
		input  wire        in_reset_reset,     // in_reset.reset,        Reset Input
		input  wire [3:0]  avmm_address,       //     avmm.address
		input  wire        avmm_write,         //         .write
		input  wire [31:0] avmm_writedata,     //         .writedata
		input  wire        avmm_read,          //         .read
		output wire [31:0] avmm_readdata,      //         .readdata
		output wire        avmm_readdatavalid, //         .readdatavalid
		output wire        avmm_waitrequest,   //         .waitrequest
		output wire        irq_irq             //      irq.irq
	);
endmodule

