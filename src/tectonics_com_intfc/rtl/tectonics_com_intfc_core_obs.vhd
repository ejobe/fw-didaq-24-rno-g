--*----------------------------------------------------------------------------
--*
--*                          RTL source file 
--*                      Logic Tectonics IP Module
--*        Logic Tectonics Copyright 2011-2015 ALL RIGHTS RESERVED
--*           Licensed non-exclusively to end customer
--*                        royalty free, AS IS.   
--*          
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics, www.logic-tectonics.com       
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This module creates an async serial port with 
--*                transmit and receive fifo buffer.
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description 
--*   -----------    --------------        -----------
--*   Dec//2011       DAK                   Coded
--*   Aug//2015       DAK                   Updated the FIFO wrapper inst.  
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


entity tectonics_com_intfc_core is
   generic(
      g_vendor             : string    := "altera";
      g_arst_pol           : std_logic := '1';   -- default to '1' being te polarity of arst input
      g_tx_fifo_depth      : positive  := 4096;  -- Support 16 for now
      g_tx_fifo_lev_width  : positive  := 13;    -- Set to the log2(g_tx_fifo_depth)+1 for one based
      g_rx_fifo_depth      : positive  := 4096;  -- Support 16 for now              
      g_rx_fifo_lev_width  : positive  := 13;    -- Set to the log2(g_tx_fifo_depth)+1 for one based
      
      g_serial_rate_width  : positive  := 16;   -- Set to minimum of 9 for serial rates 230400 to 300 Baud with 3.686Mz referncee
                                               
      g_tx_fifo_use_logic  : boolean   := false;
      g_rx_fifo_use_logic  : boolean   := false
       
   );   
      

   port(
      
      arst           : in   std_logic;                     --  Async reset, polarity set by arst_pol
      clk            : in   std_logic;                     --  Clk. Pos edge active.
      
      revision       : out  std_logic_vector(15 downto 0); -- Revision of the core
                                                          
      ser_ref_pls    : in   std_logic;                     -- This is a pulse, one clk wide, at 3.686Mz (or within 2%)

      ser_rate       : in   std_logic_vector(g_serial_rate_width-1 downto 0); 
                                                           -- for 3.686M(reference):
                                                           -- This sets the bit rate 2 = 115200   Baud -- serial rate = 3.686M(reference)/(2*16)
                                                           -- This sets the bit rate 4 = 57.6k    Baud 3.686M(reference)/(4*16)
                                                           -- This sets the bit rate 8 = 28.8k    Baud
                                                           -- This sets the bit rate 16 = 14.4k   Baud                                                     
                                                           -- 24  = 9600 Baud                      
                                                           -- 48  = 4800 Baud                      
                                                           -- 768 = 300  Baud
                                                           
      ser_stop_bits  : in std_logic_vector(1 downto 0);    -- 00 = 2 
                                                           -- 01 = 1
                                                           -- 10 = 2
                                                           -- 11 = 2
                                                           
      ser_parity     : in std_logic_vector(1 downto 0);    -- 00 = none
                                                           -- 01 = even
                                                           -- 10 = odd
                                                           -- 11 = none
                                                           
      data_size      : in std_logic_vector(1 downto 0);    -- 00 = 8
                                                           -- 01 = 7
                                                           -- 10 = reserved
                                                           -- 11 = reserved                                                      
                                                                                                                    
      tx_data         : in  std_logic_vector(7 downto 0);
      tx_wr           : in  std_logic;                                          -- One clock wide to write the data on tx_data() into the tx fifo
      tx_level        : out std_logic_vector(g_tx_fifo_lev_width-1 downto 0);   -- Use this as the LSBs of the tx FIFO level.
      tx_full         : out std_logic;                                          -- Use as the MSB of the level to represent complete level
      tx_empty        : out std_logic;                                          -- Active high TX FIFO empty signal
                      
      rx_data         : out std_logic_vector(7 downto 0);
      rx_par_err      : out std_logic;                                          -- If the rx fifo is not empty then if this is set
                                                                                -- the data word about to be read has a parity error id this is '1'
      rx_rdack        : in  std_logic;
      rx_level        : out std_logic_vector(g_rx_fifo_lev_width-1 downto 0);   -- Use this as the LSBs of the rx FIFO level.
      rx_full         : out std_logic;                                          -- Use as the MSB of the level to represent complete level
      rx_empty        : out std_logic;                                          -- Active high RX FIFO empty signal
                      
      ser_tx          : out std_logic;                                          -- Serial transmit line
      ser_rx          : in  std_logic;                                          -- Serial receive line
                      
      tx_en           : in  std_logic;                                          -- Uart will ignore writes to the TX fifo (and will flush the TX FIFO) if this is not set
      rx_en           : in  std_logic;                                          -- Uart will ignore incoming serial traffic (and will flush the RX FIFO) if this is not set
      
      tx_busy         : out std_logic;                                          -- '1' when TX is enabled and either transmitting or FIFO is not empty
      
      rx_par_err_pls  : out std_logic;                                          -- Pulsed when data with a parity error is written to the rx fifo 

      rx_fifo_ovf_pls : out std_logic;                                          -- Pulsed when RX FIFO is full when a new char arrives.      
            
      rx_idle_setting : in  std_logic_vector(5 downto 0);                       -- Sete the time in characters (for the set baud rate)
                                                                                -- for the rx_idle_pls to fire after a period of receive activity                 
      tx_pace_setting : in  std_logic_vector(5 downto 0);                       -- Sete the 
      
      rx_idle_pls     : out std_logic                                           -- Fire off after a period of inactivity of RX                                                 
                                                                                                                                                                        
      
   );
   
end entity tectonics_com_intfc_core;      
      
architecture rtl of tectonics_com_intfc_core is     


-- Functions
function a4d69(z : std_logic; vec : std_logic_vector(7 downto 0)) return std_logic is
variable temp : std_logic;
begin
   temp := '0';
   for i in 0 to 7 loop
      temp := temp xor vec(i); 
   end loop;
   if z = '1' then
      return not(temp);
   else 
      return temp;    
   end if;

end a4d69;
                 
-- Components
component uart_generic_fifo_shell
   generic(      
      g_vendor        : string    := "altera";
                      
      g_arst_pol      : std_logic := '1';         -- Sets internal reset polarity
      g_sync          : boolean   := true;        -- True if synchronous, false async (different clocks on read/write ports)
      g_showahead     : boolean   := true;        -- If true then its a lookahead fifo, else the read data shows up 1 cycle
                                                  -- after the rd_en is asserted
      g_use_logic     : boolean   := false;                                       

      g_wr_data_width : positive  := 18;       -- Fifo write side data width
      g_wr_depth      : positive  := 512;      -- Number of words deep from write side perspective
      g_wr_levwidth   : positive  := 10;       -- Width of the level port. The high order bit is the same as the full bit
                                               
         
      g_rd_data_width : positive  := 18;       -- Fifo write side data width                                                                            
      g_rd_depth      : positive  := 512;      -- Number of words deep from write side perspective                                                      
      g_rd_levwidth   : positive  := 10        -- Width of the level port. The high order bit is the same as the full bit
   );

   port(
      
      -- Clock and reset
      arst                  : in   std_logic;  -- Module async reset polarity set by the generic     
      srst                  : in   std_logic;  -- Sync reset, only used in synchronous versions. Active high.
      
      wr_clk                : in   std_logic;  -- Read and write clock if sync, write clock if async
      wr_en                 : in   std_logic;
      wr_data               : in   std_logic_vector(g_wr_data_width-1 downto 0);
      wr_full               : out  std_logic;
      wr_level              : out  std_logic_vector(g_wr_levwidth-1 downto 0);
      
      rd_clk                : in   std_logic;  -- read clock if async     
      rd_en                 : in   std_logic;
      rd_data               : out  std_logic_vector(g_rd_data_width-1 downto 0);
      rd_empty              : out  std_logic;
      rd_level              : out  std_logic_vector(g_rd_levwidth-1 downto 0);
      rd_data_valid         : out  std_logic -- High when read data is valid. Handles cases of fifo read latency    
  
   );

end component; 
   
constant a4d65 : boolean := false; 

    
type a4d3 is ( a4d4,
                             a4d5,
                             a4d6,
                             a4d7,
                             a4d8,
                             a4d9
                           );
                           
type a4d10 is ( a4d11,    
                             a4d11_end,
                             a4d12,        
                             a4d13,           
                             a4d14
                            );                
                            
  
   
   

signal a4d15 : a4d3;    
      
signal a4d16       : std_logic;            
signal a4d17       : std_logic;            
signal a4d18         : std_logic;
signal a4d18_data    : std_logic_vector(7 downto 0);
signal a4d19      : std_logic;
signal a4d20    : std_logic_vector(7 downto 0);
signal a4d21      : std_logic;
signal a4d23       : std_logic;
signal a4d24      : std_logic_vector(g_tx_fifo_lev_width-1 downto 0);
                          
signal a4d25 : std_logic_vector(ser_rate'length-1 downto 0);
signal a4d26     : std_logic;           
signal a4d26_cnt : std_logic_vector(3 downto 0); 
signal a4d27   : std_logic;

signal a4d28     : std_logic;
signal a4d29    : std_logic_vector(2 downto 0);                          
signal a4d30      : std_logic;                          

signal a4d31         : std_logic;                         
signal a4d32  : positive range 5 to 7;  

signal a4d33       : a4d10;
signal a4d34       : std_logic;            
signal a4d35       : std_logic;            
signal a4d36         : std_logic;
signal a4d36_data    : std_logic_vector(8 downto 0);
signal a4d37      : std_logic;
signal a4d38    : std_logic_vector(8 downto 0);
signal a4d39      : std_logic;
signal a4d40       : std_logic;
signal a4d41      : std_logic_vector(g_tx_fifo_lev_width-1 downto 0);

signal a4d42           : std_logic; 
signal a4d42r          : std_logic;
signal a4d42rr         : std_logic;
signal a4d43         : std_logic;

signal a4d44 : std_logic_vector(ser_rate'length-1 downto 0);
signal a4d45     : std_logic;           
signal a4d45_cnt : std_logic_vector(3 downto 0);                           

signal a4d46     : std_logic;
signal a4d47     : std_logic;
signal a4d48    : std_logic_vector(2 downto 0);
signal a4d49        : std_logic_vector(7 downto 0); 
signal a4d50  : std_logic;

signal a4d51      : std_logic;

signal a4d52    : std_logic;
signal a4d53     : std_logic;
signal a4d54        : integer range 0 to 11*((2**rx_idle_setting'length)-1); 


signal a4d55  : std_logic_vector(rx_idle_setting'length-1 downto 0);

signal a4d56  : std_logic_vector(tx_pace_setting'length-1 downto 0);
signal a4d57        : integer range 0 to 11*((2**tx_pace_setting'length)-1); 
signal a4d58       : std_logic;

signal a4d59            : std_logic;
signal a4d60            : std_logic;

signal a4d61 : std_logic;



begin -- rtl   

revision <= conv_std_logic_vector(16#12#,revision'length); -- Major.Minor


a4d17 <= not(a4d59);

a4d16 <= '1' when arst = g_arst_pol else '0';


   
tx_fifo : uart_generic_fifo_shell
   generic map(      
      g_vendor        =>  g_vendor,
                      
      g_arst_pol      =>  '1',    
      g_sync          =>  true,   
      g_showahead     =>  true,   
                                  
      g_use_logic     =>  false,  
                      
      g_wr_data_width =>  8,     
      g_wr_depth      =>  g_tx_fifo_depth,        
      g_wr_levwidth   =>  g_tx_fifo_lev_width,    
                                 
                      
      g_rd_data_width => 8,                            
      g_rd_depth      => g_tx_fifo_depth,              
      g_rd_levwidth   => g_tx_fifo_lev_width   
   )

   port map(                   
                                               
      arst           => a4d16,
      srst           => a4d17,
                     
      wr_clk         => clk,                
      wr_en          => a4d18,         
      wr_data        => a4d18_data,       
      wr_full        => a4d23,
      wr_level       => a4d24,
                     
      rd_clk         => clk, 
      rd_en          => a4d19,  
      rd_data        => a4d20,
      rd_empty       => a4d21,
      rd_level       => open,
      rd_data_valid  => open
  
   );   
     
   
a4d18      <= tx_wr;       
a4d18_data <= tx_data;   
tx_level        <= a4d24;
tx_full         <= a4d23;
tx_empty        <= a4d21;




process(clk, arst)
begin
   if arst = g_arst_pol then
      a4d25 <= (others => '0');   
      a4d26     <= '0';
      a4d26_cnt <= (others => '0');
      
      a4d59 <= '0';
      a4d60 <= '0';
   elsif clk'event and clk = '1' then
   
      a4d26 <= '0';   
      if ser_ref_pls = '1' then 
         if a4d25 >= ser_rate then
            a4d25 <= conv_std_logic_vector(1,a4d25'length);
            a4d26 <= '1';
         else
            a4d25 <= a4d25 + 1;
         end if;
      end if;      
   
      if a4d26 = '1' then 
         a4d26_cnt <= a4d26_cnt + 1; 
      end if;   
      
      a4d59 <= tx_en;
      a4d60 <= rx_en;
      
   end if;  
end process;

a4d27  <= '1' when conv_integer('0'&a4d26_cnt) = 0 and a4d26 = '1' else '0'; 

a4d28    <= '1' when conv_integer('0'&a4d26_cnt) = 15 and a4d26 = '1' else '0';


process(data_size)
begin
   case data_size is 
      when "00" => 
         a4d32 <= 7;  
      when "01" =>              
         a4d32 <= 6;
      when others => 
         a4d32 <= 7;
   end case;
end process;
                
    
process(clk, arst)
begin
   if arst = g_arst_pol then
      a4d30     <= '0'; 
      a4d15      <= a4d4;
   elsif clk'event and clk = '1' then
      case a4d15 is 
        
         when a4d4 =>
            if a4d59 = '1' and a4d21 = '0' and (a4d58 = '0' or conv_integer('0'&a4d56) = 0) then                                       
               if a4d27 = '1' then                                      
                  if ser_parity = "10" then 
                     if a4d65 then 
                        a4d30 <= not a4d69('1',a4d20);
                     else                             
                        a4d30 <= a4d69('1',a4d20);
                     end if;
                  else 
                     if a4d65 then 
                        a4d30 <= not a4d69('0',a4d20);
                     else
                        a4d30 <= a4d69('0',a4d20);
                     end if;
                  end if;    
                  a4d15  <= a4d5;
               end if;
            end if;              

         when a4d5 =>
            if a4d27 = '1' then 
               a4d15  <= a4d6;
            end if;         

         when a4d6 =>
            if (conv_integer('0'&a4d29) = a4d32) and a4d27 = '1' then 
                                                                      
                                                                      
                                                                      
               if ser_parity = "01" or ser_parity = "10" then            
                  a4d15  <= a4d7;
               else
                  a4d15  <= a4d8; 
               end if;      
            end if;
        
         when a4d7 =>                                                                  
            if a4d27 = '1' then                                                         
               a4d15 <= a4d8;                                               
            end if;
            
         when a4d8 =>
            case ser_stop_bits is 
            
               when "01" =>  
                  if a4d28 = '1' then 
                     a4d15  <= a4d4;
                  end if;
                              
               when "10" => 
                  if a4d27 = '1' then 
                     a4d15  <= a4d9;
                  end if;
                              
               when others => 
                  if a4d27 = '1' then 
                     a4d15  <= a4d9;
                  end if;
      
            end case;                    
         
         when a4d9 =>
            if a4d28 = '1' then 
               a4d15  <= a4d4;
            end if;               
   
         when others =>
         
            null;
      end case;
   end if;  
end process;    

a4d19 <= '1' when (a4d15 = a4d8 and a4d28 = '1') else '0';


tx_busy <= '1' when a4d15 /= a4d4 or a4d21 = '0' else '0'; 



process(arst,clk)
begin
   if arst = g_arst_pol then
      a4d56 <= (others => '0');
      a4d57       <=  0;
      a4d58      <= '0';
   elsif clk'event and clk = '1' then
      a4d56 <= tx_pace_setting;
      if conv_integer('0'&a4d56) /= 0 then
         if a4d19 = '1' then 
                             
            a4d57 <= 11 * conv_integer('0'&a4d56);
            a4d58 <= '1';
         elsif a4d27 = '1' then
            if a4d57 > 0 then
               a4d57 <= a4d57-1;
            end if;   
         
            if a4d57 = 1 then 
               a4d58 <= '0';
            end if;       
         end if;  
      else
         a4d57       <=  0; 
         a4d58      <= '0';
      end if;            
   end if;
end process;


process(arst,clk)
begin
   if arst = g_arst_pol then
   
      a4d31          <= '1';
      a4d29 <= (others => '0');      
   elsif clk'event and clk = '1' then
      if a4d15 = a4d6 then 
         if a4d27 = '1' then 
            a4d29 <= a4d29 + 1;
         end if;   
      else
         a4d29 <= (others => '0');
      end if;                                                       



      case a4d15 is    
         when a4d5 => 
            a4d31 <= '0';  

         when a4d6 => 
            a4d31 <= a4d20(conv_integer('0'&a4d29));
                      
         when a4d7 =>
            a4d31 <= a4d30;          
         when others =>      
             a4d31 <= '1';               
      end case;                    
   end if;
end process;

ser_tx <= a4d31;     



a4d35 <= not(a4d60);
a4d34 <= '1' when arst = g_arst_pol else '0';


   
rx_fifo : uart_generic_fifo_shell
   generic map(      
      g_vendor        =>  g_vendor,
                      
      g_arst_pol      =>  '1',    
      g_sync          =>  true,   
      g_showahead     =>  true,   
                                  
      g_use_logic     =>  false,  
                      
      g_wr_data_width =>  9,     
      g_wr_depth      =>  g_rx_fifo_depth,        
      g_wr_levwidth   =>  g_rx_fifo_lev_width,    
                                 
                      
      g_rd_data_width => 9,                            
      g_rd_depth      => g_rx_fifo_depth,              
      g_rd_levwidth   => g_rx_fifo_lev_width   
   )

   port map(                   
                                               
      arst           => a4d34,
      srst           => a4d35,
                     
      wr_clk         => clk,                
      wr_en          => a4d36,         
      wr_data        => a4d36_data,       
      wr_full        => a4d40,
      wr_level       => open,
                     
      rd_clk         => clk, 
      rd_en          => a4d37,  
      rd_data        => a4d38,
      rd_empty       => a4d39,
      rd_level       => a4d41,
      rd_data_valid  => open
  
   );      
   
   
   
   

  
rx_data      <= a4d38(7 downto 0);
rx_par_err   <= '1' when a4d38(8) = '1' and a4d39 = '0' else '0';  
             
a4d37 <= rx_rdack;        
rx_level      <= a4d41;      
rx_full       <= a4d40;
rx_empty      <= a4d39;
 
process(arst,clk)
begin
   if arst = g_arst_pol then
      a4d42   <= '1';
      a4d42r  <= '1';
      a4d42rr <= '1';
   
   elsif clk'event and clk = '1' then

      a4d42   <= ser_rx;
      a4d42r  <= a4d42;
      a4d42rr <= a4d42r;

   end if;
end process;   

a4d43 <= not(a4d42r) and a4d42rr;  

process(clk, arst)
begin
   if arst = g_arst_pol then
      a4d44 <= (others => '0');   
      a4d45     <= '0';
      a4d45_cnt <= (others => '0');
   elsif clk'event and clk = '1' then
      if a4d51 = '1' then 
         a4d45 <= '0';   
         if ser_ref_pls = '1' then 
            if a4d44 >= ser_rate then
               a4d44 <= conv_std_logic_vector(1,a4d44'length);
               a4d45 <= '1';
            else
               a4d44 <= a4d44 + 1;
            end if;
         end if;      
         
         if a4d45 = '1' then 
            a4d45_cnt <= a4d45_cnt + 1; 
         end if;   
      else
          a4d44 <= ser_rate;   
          a4d45     <= '0';            
          a4d45_cnt <= (others => '0');      
      
      end if;   
   end if;  
end process;


a4d46    <= '1' when conv_integer('0'&a4d45_cnt) = 7  and a4d45 = '1' else '0';
a4d47    <= '1' when conv_integer('0'&a4d45_cnt) = 15 and a4d45 = '1' else '0';

                                                                        
process(clk, arst)                                                      
begin
   if arst = g_arst_pol then
      a4d50  <= '0'; 
      a4d49        <= (others => '0');
      a4d61 <= '0';                                                                                        
      a4d33       <= a4d11;                                                                                
                                                                                                                                   
   elsif clk'event and clk = '1' then    
      a4d61 <= '0';                                                                                          
      case a4d33 is                                                                                                         
                                                                                                                                   
         when a4d11 =>
            a4d49 <= (others => '0');
            if a4d43 = '1' and a4d60 = '1' then                                         
               a4d33    <= a4d11_end;
            end if;              
            
         when a4d11_end =>
            if a4d47 = '1' then                                        
               a4d33    <= a4d12;
            end if;    
            
         when a4d12 =>
            if a4d46 = '1' then                                        
               a4d49(conv_integer('0'&a4d48)) <= a4d42rr;
            end if;   
         
            if (conv_integer('0'&a4d48) = a4d32) and a4d47 = '1' then
               if ser_parity = "01" or ser_parity = "10" then            
                  a4d33  <= a4d13;
               else
                  a4d50 <= '0'; 
                  a4d33      <= a4d14; 
               end if;      
            end if;                                                   
                                                                      
         when a4d13 =>                                                
            if a4d46 = '1' then                                       
               
               if ((ser_parity = "01") and a4d42rr /= a4d69('0',a4d49)) or
                  ((ser_parity = "10") and a4d42rr /= a4d69('1',a4d49)) then
                  
                  a4d50 <= '1';
                  
               else   
                  a4d50 <= '0';
               end if; 
            end if; 
         
            if a4d47 = '1' then 
               a4d61 <= a4d50;                                       
               a4d33       <= a4d14;
            end if;                  

         when a4d14 =>                                     
            a4d33    <= a4d11;
            
         when others =>
          
            null;
      end case;
   end if;  
end process;    

a4d51 <= '1' when a4d33 /= a4d11 else '0'; 

a4d36      <= '1' when a4d33 = a4d14 else '0';
a4d36_data <= a4d50 & a4d49; 

rx_par_err_pls <= a4d61;

rx_fifo_ovf_pls <= a4d40 and a4d36;

process(arst,clk)
begin
   if arst = g_arst_pol then
      a4d48 <= (others => '0');      
   elsif clk'event and clk = '1' then
      if a4d33 = a4d12 then 
         if a4d47 = '1' then 
            a4d48 <= a4d48 + 1;
         end if;   
      else
         a4d48 <= (others => '0');
      end if;                                                                             
   end if;
end process;


process(arst,clk)
begin
   if arst = g_arst_pol then
      a4d53    <= '0';
      a4d52   <= '0';
      a4d55 <= (others => '0');
      a4d54       <= 0;      
      
   elsif clk'event and clk = '1' then
      a4d55 <= rx_idle_setting;
   
      a4d52 <= '0';
      
      
      if a4d33 = a4d14 then 
         a4d53 <= '1';
      elsif a4d52 = '1' then 
         a4d53 <= '0';
      end if;   
     
      if a4d53 = '1' then     
         if (a4d33 /= a4d11) then 
                                  
            a4d54 <= 11 * conv_integer('0'&a4d55);
      
         elsif a4d27 = '1' then  
            a4d54 <= a4d54 - 1;
            if a4d54 = 1 then
               a4d52 <= '1';
            end if;
         end if;   
      else 
          a4d54 <= 11 * conv_integer('0'&a4d55);
      end if;         
                                                                          
   end if;
end process;

rx_idle_pls <= a4d52;



   
end rtl;   