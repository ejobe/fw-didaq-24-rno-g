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


`timescale 1 ns / 1 ns
module intel_user_rst_clkgate (
	output logic ninit_done
);

	localparam USER_RESET_DELAY = 0;
	
	initial begin
		#0 ninit_done = 1;
		#1 ninit_done = 0;
	end
					
	
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "3f+jgPHiPLm0Yqto6eGOM8SNs8jN2V9NF8f31TH5HF4wRcai62xlSGrNZVItgFD/zXA3SIp5KO9/bmLMf25LSv9a8U7WcOKY2ENgnWmUHwMLl/GaU2CvYLSO3TeR1bkDzxW2FrGr9zR7XEwLyh1Z11QvmbRqKDcUYBPw56qt7LC1LVpEjSrLKBZHisq6GXRk0sRk54EYx97JV0R6IXeoJLIyzFbgejQcpkFkETVuaOs64HXHMJ7A5Fheb5lA0Z4lcEGIX4MWkSwln7jbyovsaGnaqTv5xN1Y1+bcycWCeo4WqTj8TFPTIx3GIzz69SGGkCuq9NISKqu2vlGFrOwbRzj8FvyGQYcZzlwCPhXjggN2ZrxuupM4OlY3RIT9SKOYF8TsnEUhyXgIUtXgf4c0QRg+fBd6VyK6cMgXNtTR4K5IG6tx7X/YmNQKbjGCSsp7NAXnBD2nxrkoaL9BWyIkrnuZPgQgMiJqJIJ3HPnZ8UwGg7Eb8fk5HHOz7aD2RBChKA8OKf7XzRvhHpeRpgZ25Pt2loAkACvEWmziPUjnJs5sqE7j9ehO7k+zSeeHoNtjg8V3R2xZ0GxLdpfrb8liyiQfZG61+fmHPqnWo0Ctdn+35NyXqCnwU2URGPfiloFcEQ3WXvcopeaXN9tIJoA5Lc5nFwQyMzGgY5szcfRyzcK5OSP9AUW7RPjBB4AHFRR5G+RzLJMDlB2NA82abR5//uWJZi+14G8Ibojbs6bkF7U6gwun9w9PEcElvErmIAiwI1oNKY0qpu1g6EzGYjg9KljErAdUFG3hBX2gAmCX1PMwlWDxoMCjB+NLDu13eueD8LjxctxpGRBqWzyGJg4fF0FG8A2Bp1Paz0E22DAaIDlrjelglKLguNfXT4a1eMNHd5HC2N6PHvPP4zezE3TWxjDjvTO6eDnzry7kjfL6qjNhsSKYG/a4am9A5CxVlqoqbjZgSdCHC9SlRfeqVLpxtKk8pMEcmcvHnn+1UAOG2UluWkPp064/r6Gvq0NhdDat"
`endif