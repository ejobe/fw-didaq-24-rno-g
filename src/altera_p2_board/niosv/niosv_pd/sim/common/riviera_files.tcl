source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_clock_in/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_avalon_spi_slave_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_tectonics_ser_debug_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_timer_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_avl_i2c_master_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_reset_in/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_avl_mst_sbc_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_intel_lw_uart_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_intel_onchip_memory_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_intel_onchip_memory_1/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_intel_generic_serial_flash_interface_top_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_avl_spi_master_0/sim/common/riviera_files.tcl]
source [file join [file dirname [info script]] ./../../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_1/sim/common/riviera_files.tcl]

namespace eval niosv_pd {
  proc get_design_libraries {} {
    set libraries [dict create]
    set libraries [dict merge $libraries [niosv_pd_clock_in::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_avalon_spi_slave_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_tectonics_ser_debug_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_timer_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_avl_i2c_master_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_jesd_12_chan_interface_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_reset_in::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_avl_mst_sbc_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_intel_lw_uart_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_intel_onchip_memory_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_intel_onchip_memory_1::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_intel_generic_serial_flash_interface_top_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_avl_spi_master_0::get_design_libraries]]
    set libraries [dict merge $libraries [niosv_pd_jesd_12_chan_interface_1::get_design_libraries]]
    dict set libraries altera_merlin_master_translator_193 1
    dict set libraries altera_merlin_slave_translator_191  1
    dict set libraries altera_merlin_master_agent_1940     1
    dict set libraries altera_merlin_slave_agent_1930      1
    dict set libraries altera_avalon_sc_fifo_1932          1
    dict set libraries altera_merlin_router_1921           1
    dict set libraries altera_merlin_traffic_limiter_1921  1
    dict set libraries altera_merlin_demultiplexer_1921    1
    dict set libraries altera_merlin_multiplexer_1922      1
    dict set libraries altera_mm_interconnect_1920         1
    dict set libraries altera_reset_controller_1924        1
    dict set libraries niosv_pd                            1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    set memory_files [concat $memory_files [niosv_pd_clock_in::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_clock_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_avalon_spi_slave_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avalon_spi_slave_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_tectonics_ser_debug_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_tectonics_ser_debug_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_timer_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_timer_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_avl_i2c_master_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_i2c_master_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_jesd_12_chan_interface_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_reset_in::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_reset_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_avl_mst_sbc_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_mst_sbc_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_intel_lw_uart_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_lw_uart_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_intel_onchip_memory_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_intel_onchip_memory_1::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_1/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_intel_generic_serial_flash_interface_top_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_generic_serial_flash_interface_top_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_avl_spi_master_0::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_spi_master_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set memory_files [concat $memory_files [niosv_pd_jesd_12_chan_interface_1::get_memory_files "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_1/sim/" "$QUARTUS_INSTALL_DIR"]]
    return $memory_files
  }
  
  proc get_common_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR} {
    set design_files [dict create]
    set design_files [dict merge $design_files [niosv_pd_clock_in::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_clock_in/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_avalon_spi_slave_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avalon_spi_slave_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_tectonics_ser_debug_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_tectonics_ser_debug_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_timer_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_timer_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_avl_i2c_master_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_i2c_master_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_jesd_12_chan_interface_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_reset_in::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_reset_in/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_avl_mst_sbc_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_mst_sbc_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_intel_lw_uart_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_lw_uart_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_intel_onchip_memory_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_intel_onchip_memory_1::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_1/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_intel_generic_serial_flash_interface_top_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_generic_serial_flash_interface_top_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_avl_spi_master_0::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_spi_master_0/sim/"]]
    set design_files [dict merge $design_files [niosv_pd_jesd_12_chan_interface_1::get_common_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_1/sim/"]]
    return $design_files
  }
  
  proc get_design_files {USER_DEFINED_COMPILE_OPTIONS USER_DEFINED_VERILOG_COMPILE_OPTIONS USER_DEFINED_VHDL_COMPILE_OPTIONS QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [list]
    set design_files [concat $design_files [niosv_pd_clock_in::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_clock_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_avalon_spi_slave_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avalon_spi_slave_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_tectonics_ser_debug_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_tectonics_ser_debug_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_timer_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_timer_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_avl_i2c_master_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_i2c_master_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_jesd_12_chan_interface_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_reset_in::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_reset_in/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_avl_mst_sbc_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_mst_sbc_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_intel_lw_uart_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_lw_uart_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_intel_onchip_memory_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_intel_onchip_memory_1::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_1/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_intel_generic_serial_flash_interface_top_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_generic_serial_flash_interface_top_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_avl_spi_master_0::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_spi_master_0/sim/" "$QUARTUS_INSTALL_DIR"]]
    set design_files [concat $design_files [niosv_pd_jesd_12_chan_interface_1::get_design_files $USER_DEFINED_COMPILE_OPTIONS $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_VHDL_COMPILE_OPTIONS "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_1/sim/" "$QUARTUS_INSTALL_DIR"]]
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_translator_193/sim/niosv_pd_altera_merlin_master_translator_193_lgcew2q.sv"]\"  -work altera_merlin_master_translator_193"                       
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_translator_191/sim/niosv_pd_altera_merlin_slave_translator_191_xg7rzxi.sv"]\"  -work altera_merlin_slave_translator_191"                          
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_master_agent_1940/sim/niosv_pd_altera_merlin_master_agent_1940_r3ep6da.sv"]\"  -work altera_merlin_master_agent_1940"                                   
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_agent_1930/sim/niosv_pd_altera_merlin_slave_agent_1930_jxauz3i.sv"]\"  -work altera_merlin_slave_agent_1930"                                      
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_slave_agent_1930/sim/altera_merlin_burst_uncompressor.sv"]\"  -work altera_merlin_slave_agent_1930"                                                     
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_avalon_sc_fifo_1932/sim/niosv_pd_altera_avalon_sc_fifo_1932_22gxxgi.v"]\"  -work altera_avalon_sc_fifo_1932"                                              
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/niosv_pd_altera_merlin_router_1921_snflkoy.sv"]\"  -work altera_merlin_router_1921"                                                     
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_router_1921/sim/niosv_pd_altera_merlin_router_1921_zvpb73q.sv"]\"  -work altera_merlin_router_1921"                                                     
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/niosv_pd_altera_merlin_traffic_limiter_altera_avalon_sc_fifo_1921_a53nykq.v"]\"  -work altera_merlin_traffic_limiter_1921"
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/altera_merlin_reorder_memory.sv"]\"  -work altera_merlin_traffic_limiter_1921"                                                 
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/altera_avalon_st_pipeline_base.v"]\"  -work altera_merlin_traffic_limiter_1921"                                                
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_traffic_limiter_1921/sim/niosv_pd_altera_merlin_traffic_limiter_1921_p3fvlba.sv"]\"  -work altera_merlin_traffic_limiter_1921"                          
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/niosv_pd_altera_merlin_demultiplexer_1921_mjyo7yy.sv"]\"  -work altera_merlin_demultiplexer_1921"                                
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/niosv_pd_altera_merlin_demultiplexer_1921_qu3ovsa.sv"]\"  -work altera_merlin_demultiplexer_1921"                                
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/niosv_pd_altera_merlin_multiplexer_1922_sqao2qy.sv"]\"  -work altera_merlin_multiplexer_1922"                                      
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"  -work altera_merlin_multiplexer_1922"                                                             
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_demultiplexer_1921/sim/niosv_pd_altera_merlin_demultiplexer_1921_iuml3li.sv"]\"  -work altera_merlin_demultiplexer_1921"                                
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/niosv_pd_altera_merlin_multiplexer_1922_6lkfprq.sv"]\"  -work altera_merlin_multiplexer_1922"                                      
    lappend design_files "vlog  $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_merlin_multiplexer_1922/sim/altera_merlin_arbitrator.sv"]\"  -work altera_merlin_multiplexer_1922"                                                             
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_mm_interconnect_1920/sim/niosv_pd_altera_mm_interconnect_1920_lv3rznq.v"]\"  -work altera_mm_interconnect_1920"                                           
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1924/sim/altera_reset_controller.v"]\"  -work altera_reset_controller_1924"                                                              
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/../altera_reset_controller_1924/sim/altera_reset_synchronizer.v"]\"  -work altera_reset_controller_1924"                                                            
    lappend design_files "vlog -v2k5 $USER_DEFINED_VERILOG_COMPILE_OPTIONS $USER_DEFINED_COMPILE_OPTIONS  \"[normalize_path "$QSYS_SIMDIR/niosv_pd.v"]\"  -work niosv_pd"                                                                                                                                     
    return $design_files
  }
  
  proc get_non_duplicate_elab_option {ELAB_OPTIONS NEW_ELAB_OPTION} {
    set IS_DUPLICATE [string first $NEW_ELAB_OPTION $ELAB_OPTIONS]
    if {$IS_DUPLICATE == -1} {
      return $NEW_ELAB_OPTION
    } else {
      return ""
    }
  }
  
  
  proc get_elab_options {SIMULATOR_TOOL_BITNESS} {
    set ELAB_OPTIONS ""
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_clock_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_avalon_spi_slave_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_tectonics_ser_debug_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_timer_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_avl_i2c_master_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_jesd_12_chan_interface_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_reset_in::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_avl_mst_sbc_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_intel_lw_uart_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_intel_onchip_memory_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_intel_onchip_memory_1::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_intel_generic_serial_flash_interface_top_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_avl_spi_master_0::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    append ELAB_OPTIONS [get_non_duplicate_elab_option $ELAB_OPTIONS [niosv_pd_jesd_12_chan_interface_1::get_elab_options $SIMULATOR_TOOL_BITNESS]]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    append SIM_OPTIONS [niosv_pd_clock_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_avalon_spi_slave_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_tectonics_ser_debug_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_timer_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_avl_i2c_master_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_jesd_12_chan_interface_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_reset_in::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_avl_mst_sbc_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_intel_lw_uart_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_intel_onchip_memory_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_intel_onchip_memory_1::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_intel_generic_serial_flash_interface_top_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_avl_spi_master_0::get_sim_options $SIMULATOR_TOOL_BITNESS]
    append SIM_OPTIONS [niosv_pd_jesd_12_chan_interface_1::get_sim_options $SIMULATOR_TOOL_BITNESS]
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_clock_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_avalon_spi_slave_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_tectonics_ser_debug_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_timer_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_avl_i2c_master_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_jesd_12_chan_interface_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_reset_in::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_avl_mst_sbc_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_intel_lw_uart_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_intel_onchip_memory_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_intel_onchip_memory_1::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_intel_generic_serial_flash_interface_top_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_avl_spi_master_0::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    set LD_LIBRARY_PATH [dict merge $LD_LIBRARY_PATH [dict get [niosv_pd_jesd_12_chan_interface_1::get_env_variables $SIMULATOR_TOOL_BITNESS] "LD_LIBRARY_PATH"]]
    dict set ENV_VARIABLES "LD_LIBRARY_PATH" $LD_LIBRARY_PATH
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $ENV_VARIABLES
  }
  
  
  proc normalize_path {FILEPATH} {
      if {[catch { package require fileutil } err]} { 
          return $FILEPATH 
      } 
      set path [fileutil::lexnormalize [file join [pwd] $FILEPATH]]  
      if {[file pathtype $FILEPATH] eq "relative"} { 
          set path [fileutil::relative [pwd] $path] 
      } 
      return $path 
  } 
  proc get_dpi_libraries {QSYS_SIMDIR} {
    set libraries [dict create]
    set libraries [dict merge $libraries [niosv_pd_clock_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_clock_in/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_avalon_spi_slave_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avalon_spi_slave_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_tectonics_ser_debug_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_tectonics_ser_debug_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_timer_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_timer_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_avl_i2c_master_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_i2c_master_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_jesd_12_chan_interface_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_reset_in::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_reset_in/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_avl_mst_sbc_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_mst_sbc_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_intel_lw_uart_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_lw_uart_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_intel_onchip_memory_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_intel_onchip_memory_1::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_onchip_memory_1/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_intel_generic_serial_flash_interface_top_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_intel_generic_serial_flash_interface_top_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_avl_spi_master_0::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_avl_spi_master_0/sim/"]]
    set libraries [dict merge $libraries [niosv_pd_jesd_12_chan_interface_1::get_dpi_libraries "$QSYS_SIMDIR/../../ip/niosv_pd/niosv_pd_jesd_12_chan_interface_1/sim/"]]
    
    return $libraries
  }
  
}
