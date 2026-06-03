	sdm_mailbox u0 (
		.in_clk_clk         (_connected_to_in_clk_clk_),         //   input,   width = 1,   in_clk.clk
		.in_reset_reset     (_connected_to_in_reset_reset_),     //   input,   width = 1, in_reset.reset
		.avmm_address       (_connected_to_avmm_address_),       //   input,   width = 4,     avmm.address
		.avmm_write         (_connected_to_avmm_write_),         //   input,   width = 1,         .write
		.avmm_writedata     (_connected_to_avmm_writedata_),     //   input,  width = 32,         .writedata
		.avmm_read          (_connected_to_avmm_read_),          //   input,   width = 1,         .read
		.avmm_readdata      (_connected_to_avmm_readdata_),      //  output,  width = 32,         .readdata
		.avmm_readdatavalid (_connected_to_avmm_readdatavalid_), //  output,   width = 1,         .readdatavalid
		.avmm_waitrequest   (_connected_to_avmm_waitrequest_),   //  output,   width = 1,         .waitrequest
		.irq_irq            (_connected_to_irq_irq_)             //  output,   width = 1,      irq.irq
	);

