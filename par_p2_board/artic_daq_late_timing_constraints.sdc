#**************************************************************
# This file needs to be listed last in the file list for the project
# so it get processed after synthesis
# 
# 
#**************************************************************

# Just some examples left below for reference for actual board

#**************************************************************
# Set Input Delay
#**************************************************************
# suppose +- 100 ps skew
# Board Delay (Data) + Propagation Delay - Board Delay (Clock)
# max 5.4(max) +0.4(trace delay) +0.1  = 5.9
# min 2.7(min) +0.4(trace delay) -0.1 = 3.0

#set_input_delay -max -clock clk_dram_ext 5.9 [get_ports DRAM_DQ*]
#set_input_delay -min -clock clk_dram_ext 3.0 [get_ports DRAM_DQ*]


#**************************************************************
# Set Output Delay
#**************************************************************
# suppose +- 100 ps skew
# max : Board Delay (Data) - Board Delay (Clock) + tsu (External Device)
# min : Board Delay (Data) - Board Delay (Clock) - th (External Device)
# max 1.5+0.1 =1.6
# min -0.8-0.1 = 0.9

#set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_DQ* DRAM_*DQM}]
#set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_DQ* DRAM_*DQM}]
#set_output_delay -max -clock clk_dram_ext 1.6  [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]
#set_output_delay -min -clock clk_dram_ext -0.9 [get_ports {DRAM_ADDR* DRAM_BA* DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N}]



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************
# Everything should use synchronizer stages that need syncro stages so tig these clocks        

set_false_path -from [get_clocks {inst_pll_sysref_fabric|iopll_0_clk_250m}] -to [get_clocks {inst_main_pll_1|iopll_0_clk_125m}]
set_false_path -from [get_clocks {inst_main_pll_1|iopll_0_clk_125m}]        -to [get_clocks {inst_pll_sysref_fabric|iopll_0_clk_250m}]

set_false_path -from [get_clocks {inst_main_pll_1|iopll_0_clk_260m}]        -to [get_clocks {inst_pll_sysref_fabric|iopll_0_clk_250m}]
set_false_path -from [get_clocks {inst_pll_sysref_fabric|iopll_0_clk_250m}] -to [get_clocks {inst_main_pll_1|iopll_0_clk_260m}]

set_false_path -from [get_clocks {inst_main_pll_1|iopll_0_clk_260m}]        -to [get_clocks {inst_main_pll_1|iopll_0_clk_125m}]
set_false_path -from [get_clocks {inst_main_pll_1|iopll_0_clk_125m}]        -to [get_clocks {inst_main_pll_1|iopll_0_clk_260m}]

set_false_path -from [get_keepers {inst_main_pll_1|iopll_0|tennm_ph2_iopll~pll_ctrl_reg}] -to [get_keepers  {sys_reset_n_pipe[*]}]

# This should be okay as should be fixed settings. Launch clockos the clkref intothe pll, latch clk is the sysref refernce to to the second PLL used to gen the syncrefs the xcvr modules
set_false_path -from [get_keepers {inst_pll_sysref_fabric|iopll_0|tennm_ph2_iopll~pll_ctrl_reg}] -to [get_keepers {inst_io_pll_sysref|iopll_0|tennm_ph2_iopll~pll_ctrl_reg}]

#****************************************************************
# Set Multicyle paths
#****************************************************************

# dont need and dont due since for multi byte accessed the updated address wont meet timing  
##This address is supplied byt the API and its many cycles after its setup that the transaction is performed
#set_multicycle_path -from [get_keepers {inst_spi_slave_reg_intfc|avl_mst_addr_reg[*}] -to [get_keepers {inst_jesd_12_chan_if_high|gen_jesd_cores[*].inst_jesd204b_core|intel_jesd204b_gts_0|rx_base_inst|j204b_gts_rx_csr_inst|rx_regmap|readdata[*}] -setup -end 2
#set_multicycle_path -from [get_keepers {inst_spi_slave_reg_intfc|avl_mst_addr_reg[*}] -to [get_keepers {inst_jesd_12_chan_if_low|gen_jesd_cores[*].inst_jesd204b_core|intel_jesd204b_gts_0|rx_base_inst|j204b_gts_rx_csr_inst|rx_regmap|readdata[*}] -setup -end 2
#
#
## Same reason
#set_multicycle_path -from [get_keepers {inst_tectonics_ser_debug|cap_addr[*}] -to [get_keepers {inst_jesd_12_chan_if_high|gen_jesd_cores[*].inst_jesd204b_core|intel_jesd204b_gts_0|rx_base_inst|j204b_gts_rx_csr_inst|rx_regmap|readdata[*}] -setup -end 2
#set_multicycle_path -from [get_keepers {inst_tectonics_ser_debug|cap_addr[*}] -to [get_keepers {inst_jesd_12_chan_if_low|gen_jesd_cores[*].inst_jesd204b_core|intel_jesd204b_gts_0|rx_base_inst|j204b_gts_rx_csr_inst|rx_regmap|readdata[*}] -setup -end 2


#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



