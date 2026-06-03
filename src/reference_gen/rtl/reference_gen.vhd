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
--*   Description: This module generates timing references.
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   apr/2016       Logic Tectonics       Updated Header
--*
--*   
--*----------------------------------------------------------------------------
--*   
--*   Reference:  
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


entity reference_gen is
   generic(
      g_arst_pol  : std_logic := '1'; -- default to '1' being te polarity of arst input
      
      g_n_main         : positive  := 3277;  -- This is the n factor for to generate the ms and us tick refernce from clk in 
      g_k_main         : positive  := 17;    -- This is the k factor for to generate the ms and us tick refernce from clk in 
                                             -- Make sure to set to create a 1 MHz clock from clk in.
      
      g_n_misc         : positive  := 755;   -- This is the n factor for to generate misc_tick refernce from clk in
      g_k_misc         : positive  := 13;    -- This is the k factor for to generate misc_tick refernce from clk in
                                             
      g_m_ms           : positive  := 1000;  -- One based these are divisors to create slower ticks from the ms and us ticks, max is 1024
      g_m_us           : positive  := 20     -- These are divisors to create slower ticks from the ms and us ticks. 1000 max
        
      
   );   
      

   port(
      
      arst           : in   std_logic;       --  Async reset, polarity set by arst_pol
      clk            : in   std_logic;       --  Clk. Pos edge active.
                     
      ms_tick        : out  std_logic;       -- millisecond tick pulse (one clk wide)
      us_tick        : out  std_logic;       -- microsecond tick pulse (one clk wide)
      
      ms_tick_div_m  : out  std_logic;
      us_tick_div_m  : out  std_logic;
      
      misc_tick      : out  std_logic                                                            
      
   );
   
end entity reference_gen;      
      
architecture rtl of reference_gen is     

-- Components
component timing_gen
   generic(
      g_arst_pol  : std_logic := '1'; 
      g_n         : positive  := 10; 
      g_k         : positive  := 13
   );   
      

   port(
      
      arst        : in   std_logic;           
      clk         : in   std_logic;           
                  
      tick_pls    : out  std_logic            
   );
   
end component;      


 
   -- Constants

   -- Types 
   
   
   -- Signals
   
   signal us_tick_sig_p         : std_logic;
   signal us_tick_sig           : std_logic;
   signal us_tick_cnt           : std_logic_vector(9 downto 0);
   signal ms_tick_sig           : std_logic;
   signal ms_tick_cnt           : std_logic_vector(9 downto 0);
   signal ms_tick_div_m_sig     : std_logic;
   signal us_tick_div_m_sig     : std_logic;
   signal us_tick_cnt_m         : std_logic_vector(9 downto 0);
   
begin -- rtl   

--
-- Generate the main tick refernce
--
inst_main_timing_gen : timing_gen
   generic map(
      g_arst_pol => g_arst_pol,
      g_n        => g_n_main,  
      g_k        => g_k_main  
   )   
      
   port map(
                
      arst     => arst,
      clk      => clk, 
                
      tick_pls => us_tick_sig_p
   );

--us_tick <= us_tick_sig; -- See below, need to delay to align with us_tick to be cleaner  

--
-- Count 1000 us to get a millisecond
--   
process(clk, arst)
begin
   if arst = g_arst_pol then
      us_tick_cnt   <= (others => '0');
      ms_tick_sig   <= '0';
      us_tick_sig   <= '0'; -- just for alignment reasons
   elsif clk'event and clk = '1' then
      us_tick_sig <= us_tick_sig_p;
      ms_tick_sig <= '0';
      if us_tick_sig_p = '1' then 
         if conv_integer('0'&us_tick_cnt) = 999 then -- count 1000 us to equal one millisecond
            ms_tick_sig <= '1';
            us_tick_cnt <= (others => '0'); 
         else
            us_tick_cnt <= us_tick_cnt + 1;         
         end if;
      end if;      
   end if;
end process;

--ms_tick <= ms_tick_sig;  

--
-- Generate the process that counts a certain number of ms tick and outputs a tick
--   
process(clk,arst)
begin
   if arst = g_arst_pol then
      ms_tick <= '0';
      ms_tick_cnt       <= (others => '0');
      ms_tick_div_m_sig <= '0';
   elsif clk'event and clk = '1' then  
      ms_tick_div_m_sig <= '0';
      if ms_tick_sig = '1' then 
         if conv_integer('0'&ms_tick_cnt) = (g_m_ms - 1) then -- count to g_m_ms-1 
            ms_tick_div_m_sig <= '1';
            ms_tick_cnt <= (others => '0'); 
         else
            ms_tick_cnt <= ms_tick_cnt + 1;         
         end if;
      end if;  
      ms_tick <= ms_tick_sig;    
   end if; 
end process;   

ms_tick_div_m <= ms_tick_div_m_sig;


--
-- Generate the process that counts a certain number of us tick and outputs a tick
--   
process(clk,arst)
begin
   if arst = g_arst_pol then
      us_tick <= '0';
      us_tick_cnt_m     <= (others => '0');
      us_tick_div_m_sig <= '0';
   elsif clk'event and clk = '1' then  
      us_tick_div_m_sig <= '0';
      if us_tick_sig = '1' then 
         if conv_integer('0'&us_tick_cnt_m) = (g_m_us - 1) then -- count to g_m_ms-1 
            us_tick_div_m_sig <= '1';
            us_tick_cnt_m <= (others => '0'); 
         else
            us_tick_cnt_m <= us_tick_cnt_m + 1;         
         end if;
      end if; 
      us_tick <= us_tick_sig;     
   end if; 
end process;   

us_tick_div_m <= us_tick_div_m_sig;

   
--
-- Generate the misc tick
--
inst_misc_timing_gen : timing_gen
   generic map(
      g_arst_pol => g_arst_pol,
      g_n        => g_n_misc,  
      g_k        => g_k_misc  
   )   
      

   port map(
                
      arst     => arst,
      clk      => clk, 
                
      tick_pls => misc_tick
   );

end rtl;   