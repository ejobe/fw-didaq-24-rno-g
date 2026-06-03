--*----------------------------------------------------------------------------
--*                                VHDL RTL source file
--*                                 Logic Tectonics Inc
--*                                 All Rights Reserved
--*                                     2013-2015
--*               Tectonics IP, licensed to end customer non-exclusively
--*               and royalty free, AS IS, with no other representations. 
--*                    This header must be included with
--*                the source code wherever used to be in compliance 
--*                        with the terms of this license.                         
--*     Single use/project License. Addition use requires written permission.
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics Inc. www.logic-tectonics.com         
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This file implements an Avalon I2C HW interface 
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

package tectonics_i2c_master_avl_intfc_pkg is
   
   constant c_num_of_regs                    : positive := 8;
                                             
   constant c_rev_reg_addr                   : natural  := 16#00#;
   constant c_ctrl_reg_addr                  : natural  := 16#01#;  
   constant c_irq_enb_reg_addr               : natural  := 16#02#;
   constant c_irq_stat_reg_addr              : natural  := 16#03#;                                                                     
   constant c_i2c_addr_reg_addr              : natural  := 16#04#;                             
   constant c_i2c_data_reg_addr              : natural  := 16#05#;
   constant c_i2c_stat_ctrl_reg_addr         : natural  := 16#06#;
   constant c_i2c_rd_data_rd_ptr_reg_addr    : natural  := 16#07#;
   
end tectonics_i2c_master_avl_intfc_pkg;

package body tectonics_i2c_master_avl_intfc_pkg is

end tectonics_i2c_master_avl_intfc_pkg; 

