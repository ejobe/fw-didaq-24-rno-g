--*
--*                          RTL source file 
--*                      Logic Tectonics IP Module
--*        Logic Tectonics Copyright 2016 ALL RIGHTS RESERVED
--*             Licensed non-exclusively to end customer
--*                        royalty free, AS IS.   
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics			www.logic-tectonics.com	
--*   Phone  : 815-975-7070
-------------------------------------------------------------------------------
--*
--*   Description: This module implements an fin * N/2^K clock timing generator. 
--*                Limitations are that the output pulse train frequency is not
--*                more than the Fin/2
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   apr/2016       Logic Tectonics       Updated header
--*
--*   
--*----------------------------------------------------------------------------
--*   
--*   Reference: Xilix X Journal article circa 1999. 
--*
--*   Synthesis Considerations:
--*
--*
--*   Par Considerations:
--*
--*----------------------------------------------------------------------------

library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity timing_gen is
   generic(
      g_arst_pol  : std_logic := '1'; -- default to '1' being te polarity of arst input
      g_n         : positive  := 10; 
      g_k         : positive  := 13
   );   
      

   port(
      
      arst        : in   std_logic;                          --  Async reset, polarity set by arst_pol
      clk         : in   std_logic;                          --  Clk. Pos edge active.
                  
      tick_pls    : out  std_logic                           -- Async read strobe, active low
   );
   
end entity timing_gen;      
      
architecture rtl of timing_gen is     
 
   -- Constants

   -- Types 
   
   
   -- Signals
   
   signal accum                 : std_logic_vector(g_k-1 downto 0);
   signal n_val                 : std_logic_vector(g_k-1 downto 0);
   signal accum_msb_r           : std_logic;
   signal tick_pls_reg          : std_logic;
   
begin -- rtl   

   n_val <= conv_std_logic_vector(g_n,g_k);
   

   --
   -- Accumulator for the pulse generator and other functions.
   --
   process(clk,arst)
   begin
      if arst = g_arst_pol then
         accum        <= (others => '1');
         accum_msb_r  <= '0';
         tick_pls_reg <= '0';   
      elsif clk'event and clk = '1' then
         accum        <= accum + n_val; 
         accum_msb_r  <= accum(accum'left);
         tick_pls_reg <= not(accum_msb_r) and  accum(accum'left); -- pulse on change to high  
      end if;
   end process;
   
   -- The positive strobe is created from the the detection of the falling edge after the metastability
   -- FFs 
   tick_pls <= tick_pls_reg; 
  

end rtl;   