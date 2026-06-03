--*----------------------------------------------------------------------------
--*                                VHDL RTL source file
--*                          Tectonic Innovation/Logic Tectonics
--*                                 All Rights Reserved
--*                                     2013-2015
--*               Tectonics IP, licensed to end customer non-exclusively
--*               and royalty free, AS IS, with no other representations. 
--*                    This header must be included with
--*                the source code wherever used to be in compliance 
--*                         with the terms of this license.                         
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics. www.logic-tectonics.com         
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This file implements an Avalon SPI HW interface 
--*                                                                                                                  
--*                    
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   May//2013      Logic Tectonics       
--*----------------------------------------------------------------------------
--*   References:
--*   
--*   Synthesis Considerations:
--*
--*   Par Considerations:
--*                                                                                                          
--*----------------------------------------------------------------------------    
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package tectonics_spi_master_avl_intfc_pkg is
   
   constant c_num_of_regs                    : positive := 11;
                                             
   constant c_spi_rev_reg_addr               : natural  := 16#00#; 
   constant c_spi_irq_enb_reg_addr           : natural  := 16#01#;
   constant c_spi_irq_stat_reg_addr          : natural  := 16#02#; 
   
   constant c_spi_settings_0_reg_addr        : natural  := 16#03#;
   constant c_spi_settings_1_reg_addr        : natural  := 16#04#;
   constant c_spi_ctrl_reg_addr              : natural  := 16#05#;
   constant c_spi_stat_reg_addr              : natural  := 16#06#;
   constant c_spi_action_reg_addr            : natural  := 16#07#;
                                                
   constant c_spi_tx_fifo_data_reg_addr      : natural  := 16#08#;
   constant c_spi_tx_fifo_stat_reg_addr      : natural  := 16#09#;
   
   constant c_spi_rx_fifo_data_reg_addr      : natural  := 16#0A#;
   constant c_spi_rx_fifo_stat_reg_addr      : natural  := 16#0B#;
   
   
   -- Define the fields in the spi_settings_0_reg
   subtype r_spi_clk_pol_range_type            is natural range 0  downto   0;
   subtype r_miso_samp_clk_edge_range_type     is natural range 1  downto   1;
   subtype r_pace_range_type                   is natural range 5  downto   2;
   subtype r_ss_to_clk_gap_range_type          is natural range 9  downto   6;
   subtype r_clk_to_ss_gap_range_type          is natural range 13 downto  10;
   subtype r_delay_enb_range_type              is natural range 14 downto  14;
   subtype r_delay_byte_pos_range_type         is natural range 22 downto  15;
   subtype r_tx_lsb_first_range_type           is natural range 23 downto  23;
   subtype r_rx_lsb_first_range_type           is natural range 24 downto  24;
   
   -- Define the fields in the spi_settings_0_reg
   subtype r_delay_time_spi_clks_range_type    is natural range  9 downto  0;   
   
                                

   
end tectonics_spi_master_avl_intfc_pkg;

package body tectonics_spi_master_avl_intfc_pkg is

end tectonics_spi_master_avl_intfc_pkg; 

