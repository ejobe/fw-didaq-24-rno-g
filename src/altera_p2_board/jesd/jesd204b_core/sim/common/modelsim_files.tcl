
namespace eval jesd204b_core {
  proc get_design_libraries {} {
    set libraries [dict create]
    dict set libraries intel_adme_gts_100                   1
    dict set libraries intel_directphy_gts_900              1
    dict set libraries pcs_hal_2100                         1
    dict set libraries one_lane_hal_2100                    1
    dict set libraries fec_hal_2100                         1
    dict set libraries pldif_hal_2100                       1
    dict set libraries phy_hal_2100                         1
    dict set libraries hal_top_2100                         1
    dict set libraries n_channel_superset_2100              1
    dict set libraries intel_jesd204b_gts_phy_191           1
    dict set libraries intel_jesd204b_gts_rx_191            1
    dict set libraries intel_jesd204_clock_reset_bridge_191 1
    dict set libraries intel_jesd204b_gts_400               1
    dict set libraries jesd204b_core                        1
    return $libraries
  }
  
  proc get_memory_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set memory_files [list]
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/SM_SRC_VLIW_MIF.mif"]"
    lappend memory_files "[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/SM_SRC_VLIW_MIF.mif"]"
    return $memory_files
  }
  
  proc get_common_design_files {QSYS_SIMDIR} {
    set design_files [dict create]
    return $design_files
  }
  
  proc get_design_files {QSYS_SIMDIR QUARTUS_INSTALL_DIR} {
    set design_files [list]
    lappend design_files "-makelib intel_adme_gts_100 \"[normalize_path "$QSYS_SIMDIR/../intel_adme_gts_100/sim/jesd204b_core_intel_adme_gts_100_hlahszy.sv"]\"   -end"                                                        
    lappend design_files "-makelib intel_adme_gts_100 \"[normalize_path "$QSYS_SIMDIR/../intel_adme_gts_100/sim/alt_xcvr_avmm_arb.sv"]\"   -end"                                                                               
    lappend design_files "-makelib intel_adme_gts_100 \"[normalize_path "$QSYS_SIMDIR/../intel_adme_gts_100/sim/alt_xcvr_arbiter.sv"]\"   -end"                                                                                
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_intel_adme_gts_900_5c56gqq.vhd"]\"   -end"                         
    lappend design_files "-makelib pcs_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pcs_hal_2100/sim/jesd204b_core_pcs_hal_2100_i6srn2q.sv"]\"   -end"                                                                          
    lappend design_files "-makelib pcs_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pcs_hal_2100/sim/ch4_pcs.sv"]\"   -end"                                                                                                     
    lappend design_files "-makelib pcs_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pcs_hal_2100/sim/pcs_hal_coreip.sv"]\"   -end"                                                                                              
    lappend design_files "-makelib one_lane_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../one_lane_hal_2100/sim/jesd204b_core_one_lane_hal_pcs_hal_2100_ij4zeoi.vhd"]\"   -end"                                                  
    lappend design_files "-makelib fec_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../fec_hal_2100/sim/jesd204b_core_fec_hal_2100_lxszoea.sv"]\"   -end"                                                                          
    lappend design_files "-makelib fec_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../fec_hal_2100/sim/ch4_fec.sv"]\"   -end"                                                                                                     
    lappend design_files "-makelib fec_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../fec_hal_2100/sim/fec_hal_coreip.sv"]\"   -end"                                                                                              
    lappend design_files "-makelib one_lane_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../one_lane_hal_2100/sim/jesd204b_core_one_lane_hal_fec_hal_2100_hmiwnzy.vhd"]\"   -end"                                                  
    lappend design_files "-makelib pldif_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pldif_hal_2100/sim/jesd204b_core_pldif_hal_2100_4b63owa.sv"]\"   -end"                                                                    
    lappend design_files "-makelib pldif_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pldif_hal_2100/sim/pldif_hal_coreip.sv"]\"   -end"                                                                                        
    lappend design_files "-makelib pldif_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pldif_hal_2100/sim/ch4_pldif.sv"]\"   -end"                                                                                               
    lappend design_files "-makelib pldif_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pldif_hal_2100/sim/ch4_pldif_no_deskew.sv"]\"   -end"                                                                                     
    lappend design_files "-makelib pldif_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../pldif_hal_2100/sim/pldif_staticmux.sv"]\"   -end"                                                                                         
    lappend design_files "-makelib one_lane_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../one_lane_hal_2100/sim/jesd204b_core_one_lane_hal_pldif_hal_2100_kovldoi.vhd"]\"   -end"                                                
    lappend design_files "-makelib phy_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../phy_hal_2100/sim/jesd204b_core_phy_hal_2100_anjxnha.sv"]\"   -end"                                                                          
    lappend design_files "-makelib phy_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../phy_hal_2100/sim/phy_staticmux.sv"]\"   -end"                                                                                               
    lappend design_files "-makelib phy_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../phy_hal_2100/sim/phy_hal_coreip.sv"]\"   -end"                                                                                              
    lappend design_files "-makelib phy_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../phy_hal_2100/sim/ch4_phy.sv"]\"   -end"                                                                                                     
    lappend design_files "-makelib one_lane_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../one_lane_hal_2100/sim/jesd204b_core_one_lane_hal_phy_hal_2100_cqvqhza.vhd"]\"   -end"                                                  
    lappend design_files "-makelib one_lane_hal_2100 \"[normalize_path "$QSYS_SIMDIR/../one_lane_hal_2100/sim/jesd204b_core_one_lane_hal_2100_35gmzui.sv"]\"   -end"                                                           
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/jesd204b_core_hal_top_one_lane_hal_2100_c7tzbta.vhd"]\"   -end"                                                            
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/jesd204b_core_hal_top_2100_p4w2ruq.sv"]\"   -end"                                                                          
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/hip_sip_boundary_p4w2ruq.sv"]\"   -end"                                                                                    
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/shared_ptp.sv"]\"   -end"                                                                                                  
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/mc.sv"]\"   -end"                                                                                                          
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/shared_hal_coreip.v"]\"   -end"                                                                                            
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/chptp.sv"]\"   -end"                                                                                                       
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/jesd204b_core_n_channel_superset_hal_top_2100_mkorooy.vhd"]\"   -end"                                
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/jesd204b_core_n_channel_superset_2100_h2bmroi.sv"]\"   -end"                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ncss_avmm_decoder.sv"]\"   -end"                                                           
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_addr_gen.sv"]\"   -end"                                                          
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_csr.sv"]\"   -end"                                                               
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_flow_ctrl.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane.sv"]\"   -end"                                                              
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane2lane.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane_rst_sequence_fsm.sv"]\"   -end"                                             
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane_wrapper.sv"]\"   -end"                                                      
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_monitor.sv"]\"   -end"                                                           
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_stagger_block.sv"]\"   -end"                                                     
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_synchronizers.sv"]\"   -end"                                                     
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/sopc_synchronizer.v"]\"   -end"                                                            
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ncss_common_ptp_top.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom.sv"]\"   -end"                                          
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ff_macro_init.sv"]\"   -end"                                                               
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_lavmm_arbiter.sv"]\"   -end"                            
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_arbiter.sv"]\"   -end"                              
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_rx.sv"]\"   -end"                                   
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx.sv"]\"   -end"                                   
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx_rx.sv"]\"   -end"                                
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi.std_func.sv"]\"   -end"                                                      
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_n_channel_superset_900_qebg4di.vhd"]\"   -end"                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/sip_async_mapping.sv"]\"   -end"                                                                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_avmm.sv"]\"   -end"                                                                  
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_csr_wrap.v"]\"   -end"                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_ccg.v"]\"   -end"                                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_gray_cntr_3.v"]\"   -end"                                                                  
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_gray_cntr_5_sl.v"]\"   -end"                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_std_synchronizer_nocut.v"]\"   -end"                                                        
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_eq_5_ena.v"]\"   -end"                                                                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_neq_5_ena.v"]\"   -end"                                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_wys_lut.v"]\"   -end"                                                                      
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_sip_csr.v"]\"   -end"                                                                
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_tx_dsk_gen.sv"]\"   -end"                                                                       
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_rx_deskew.sv"]\"   -end"                                                                   
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_word_delay.v"]\"   -end"                                                                   
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_mlab.v"]\"   -end"                                                                         
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_xcvr_resync_std.sv"]\"   -end"                                                              
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_data_sync.sv"]\"   -end"                                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/alt_xcvr_resync_etile.sv"]\"   -end"                                                                 
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/altera_std_synchronizer_nocut_etile.v"]\"   -end"                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_900_ccqah4q.sv"]\"   -end"                                         
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_900_ccqah4q_sip.sv"]\"   -end"                                     
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/jesd204b_core_intel_jesd204b_gts_phy_intel_directphy_gts_191_x7bynya.vhd"]\"   -end"           
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_intel_adme_gts_900_5c56gqq.vhd"]\"   -end"                         
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/jesd204b_core_hal_top_one_lane_hal_2100_c7tzbta.vhd"]\"   -end"                                                            
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/jesd204b_core_hal_top_2100_nxxghuq.sv"]\"   -end"                                                                          
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/hip_sip_boundary_nxxghuq.sv"]\"   -end"                                                                                    
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/shared_ptp.sv"]\"   -end"                                                                                                  
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/mc.sv"]\"   -end"                                                                                                          
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/shared_hal_coreip.v"]\"   -end"                                                                                            
    lappend design_files "-makelib hal_top_2100 \"[normalize_path "$QSYS_SIMDIR/../hal_top_2100/sim/chptp.sv"]\"   -end"                                                                                                       
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/jesd204b_core_n_channel_superset_hal_top_2100_obpnyoy.vhd"]\"   -end"                                
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/jesd204b_core_n_channel_superset_2100_4jxhtba.sv"]\"   -end"                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ncss_avmm_decoder.sv"]\"   -end"                                                           
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_addr_gen.sv"]\"   -end"                                                          
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_csr.sv"]\"   -end"                                                               
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_flow_ctrl.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane.sv"]\"   -end"                                                              
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane2lane.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane_rst_sequence_fsm.sv"]\"   -end"                                             
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_lane_wrapper.sv"]\"   -end"                                                      
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_monitor.sv"]\"   -end"                                                           
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_stagger_block.sv"]\"   -end"                                                     
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/intel_src_synchronizers.sv"]\"   -end"                                                     
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/sopc_synchronizer.v"]\"   -end"                                                            
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ncss_common_ptp_top.sv"]\"   -end"                                                         
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom.sv"]\"   -end"                                          
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/ff_macro_init.sv"]\"   -end"                                                               
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_lavmm_arbiter.sv"]\"   -end"                            
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_arbiter.sv"]\"   -end"                              
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_rx.sv"]\"   -end"                                   
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx.sv"]\"   -end"                                   
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi_pld_chnl_dp_sip_atom_mux_tx_rx.sv"]\"   -end"                                
    lappend design_files "-makelib n_channel_superset_2100 \"[normalize_path "$QSYS_SIMDIR/../n_channel_superset_2100/sim/intelfpga/tennm_sm_hssi.std_func.sv"]\"   -end"                                                      
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_n_channel_superset_900_lxxn6ma.vhd"]\"   -end"                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/sip_async_mapping.sv"]\"   -end"                                                                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_avmm.sv"]\"   -end"                                                                  
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_csr_wrap.v"]\"   -end"                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_ccg.v"]\"   -end"                                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_gray_cntr_3.v"]\"   -end"                                                                  
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_gray_cntr_5_sl.v"]\"   -end"                                                               
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_std_synchronizer_nocut.v"]\"   -end"                                                        
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_eq_5_ena.v"]\"   -end"                                                                     
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_neq_5_ena.v"]\"   -end"                                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_wys_lut.v"]\"   -end"                                                                      
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/intel_directphy_sip_csr.v"]\"   -end"                                                                
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_tx_dsk_gen.sv"]\"   -end"                                                                       
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_rx_deskew.sv"]\"   -end"                                                                   
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_word_delay.v"]\"   -end"                                                                   
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/directphy_mlab.v"]\"   -end"                                                                         
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_xcvr_resync_std.sv"]\"   -end"                                                              
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/dphy_gts_data_sync.sv"]\"   -end"                                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/alt_xcvr_resync_etile.sv"]\"   -end"                                                                 
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/altera_std_synchronizer_nocut_etile.v"]\"   -end"                                                    
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_900_6idpasa.sv"]\"   -end"                                         
    lappend design_files "-makelib intel_directphy_gts_900 \"[normalize_path "$QSYS_SIMDIR/../intel_directphy_gts_900/sim/jesd204b_core_intel_directphy_gts_900_6idpasa_sip.sv"]\"   -end"                                     
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/jesd204b_core_intel_jesd204b_gts_phy_intel_directphy_gts_191_lvsxkwq.vhd"]\"   -end"           
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/intelfpga/j204b_gts_phy_adapter_jesd204b_core_intel_jesd204b_gts_phy_191_nidu6yi.v"]\"   -end" 
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/intelfpga/jesd204b_core_intel_jesd204b_gts_phy_191_nidu6yi.v"]\"   -end"                       
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_8b10b_dec_top.v"]\"   -end"                                            
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_8b10b_dec.v"]\"   -end"                                                
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_rx_mlpcs.v"]\"   -end"                                                 
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_rx_pcs.v"]\"   -end"                                                   
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_wa.v"]\"   -end"                                                       
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_xn_8b10b_dec.v"]\"   -end"                                             
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/phy/intelfpga/j204b_gts_sip_rst_seq_rx.v"]\"   -end"                                           
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/common/intelfpga/j204b_gts_wys_lut.v"]\"   -end"                                               
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/common/intelfpga/j204b_gts_bit_synchronizer.v"]\"   -end"                                      
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/common/intelfpga/altera_std_synchronizer_nocut.v"]\"   -end"                                   
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/common/intelfpga/j204b_gts_rstctrl.v"]\"   -end"                                               
    lappend design_files "-makelib intel_jesd204b_gts_phy_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_phy_191/sim/common/intelfpga/j204b_gts_pipeline.v"]\"   -end"                                              
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_base.v"]\"   -end"                                                     
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_csr.v"]\"   -end"                                                      
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_ctl.v"]\"   -end"                                                      
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_descrambler.v"]\"   -end"                                              
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_char_val.v"]\"   -end"                                             
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_cs.v"]\"   -end"                                                   
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_data_store.v"]\"   -end"                                           
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_ecc_dec.v"]\"   -end"                                              
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_ecc_enc.v"]\"   -end"                                              
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_ecc_fifo_hard.v"]\"   -end"                                        
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_ecc_fifo.v"]\"   -end"                                             
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_frame_align.v"]\"   -end"                                          
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_fs_char_replace.v"]\"   -end"                                      
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_lane_align.v"]\"   -end"                                           
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll_wo_ecc_fifo.v"]\"   -end"                                          
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_gts_rx_dll.v"]\"   -end"                                                      
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/rx/intelfpga/j204b_rx_regmap.v"]\"   -end"                                                       
    lappend design_files "-makelib intel_jesd204b_gts_rx_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_rx_191/sim/common/intelfpga/j204b_gts_pipeline.v"]\"   -end"                                                
    lappend design_files "-makelib intel_jesd204_clock_reset_bridge_191 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204_clock_reset_bridge_191/sim/clock_reset_bridge/intelfpga/intel_jesd204_clock_reset_bridge.v"]\"   -end"
    lappend design_files "-makelib intel_jesd204b_gts_400 \"[normalize_path "$QSYS_SIMDIR/../intel_jesd204b_gts_400/sim/jesd204b_core_intel_jesd204b_gts_400_tfixbgi.v"]\"   -end"                                             
    lappend design_files "-makelib jesd204b_core \"[normalize_path "$QSYS_SIMDIR/jesd204b_core.vhd"]\"   -end"                                                                                                                 
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
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
      append ELAB_OPTIONS {  -voptargs=+acc -voptargs=-noprotectopt -suppress 7063\,7061\,3009\,3053\,12003\,8630\,12023\,8604\,3839\,7033 -nocvg}
    }
    append ELAB_OPTIONS { -t fs}
    return $ELAB_OPTIONS
  }
  
  
  proc get_sim_options {SIMULATOR_TOOL_BITNESS} {
    set SIM_OPTIONS ""
    if ![ string match "bit_64" $SIMULATOR_TOOL_BITNESS ] {
    } else {
    }
    return $SIM_OPTIONS
  }
  
  
  proc get_env_variables {SIMULATOR_TOOL_BITNESS} {
    set ENV_VARIABLES [dict create]
    set LD_LIBRARY_PATH [dict create]
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
    
    return $libraries
  }
  
}
