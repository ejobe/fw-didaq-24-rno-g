--*----------------------------------------------------------------------------
--*
--*                          RTL source file 
--*                      Logic Tectonics IP Module
--*        Logic Tectonics Copyright 2011-2015 ALL RIGHTS RESERVED
--*                      Licensed non-exclusively 
--*                        royalty free, AS IS.   
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics, www.logic-tectonics.com       
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This is a generic FIFO shell and is used to slectively 
--*                instantiate vendor specific FIFOs based on genertic settings
--*                 
--*                          
--*                     
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   Jul//2011      DAK                   Coded.
--*   Jul//2015      DAK                   Added new fifos
--*----------------------------------------------------------------------------
--*
--*   References:
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


entity uart_generic_fifo_shell is
   generic(
      g_vendor        : string    := "altera";
   
      g_arst_pol      : std_logic := '1';      -- Sets internal reset polarity      
      g_sync          : boolean   := true;     -- True if synchronous, false async (different clocks on read/write ports
      g_showahead     : boolean   := false;    -- If true then its a lookahead fifo, else the read data shows up 1 cycle
                                               -- after the rd_en is asserted   
      g_use_logic     : boolean   := false;    -- If true use a logic version versus core, not currently supported for aync or differnt port
                                               -- sizes for write versus read side
       
                                               
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

end entity uart_generic_fifo_shell;


architecture rtl of uart_generic_fifo_shell is



-- components 

component tic_uart_sync_tx_la_fifo_1k is
    port
    (
        aclr        : in  std_logic ;
        clock       : in  std_logic ;
        data        : in  std_logic_vector (7 downto 0);
        rdreq       : in  std_logic ;
        sclr        : in  std_logic ;
        wrreq       : in  std_logic ;
        empty       : out std_logic ;
        full        : out std_logic ;
        q           : out std_logic_vector (7 downto 0);
        usedw       : out std_logic_vector (9 downto 0)
    );
end component;

component tic_uart_sync_tx_la_fifo_2k is
    port
    (
        aclr        : in  std_logic ;
        clock       : in  std_logic ;
        data        : in  std_logic_vector (7 downto 0);
        rdreq       : in  std_logic ;
        sclr        : in  std_logic ;
        wrreq       : in  std_logic ;
        empty       : out std_logic ;
        full        : out std_logic ;
        q           : out std_logic_vector (7 downto 0);
        usedw       : out std_logic_vector (10 downto 0)
    );
end component;

component tic_uart_sync_tx_la_fifo_4k is
    port
    (
        aclr        : in  std_logic ;
        clock       : in  std_logic ;
        data        : in  std_logic_vector (7 downto 0);
        rdreq       : in  std_logic ;
        sclr        : in  std_logic ;
        wrreq       : in  std_logic ;
        empty       : out std_logic ;
        full        : out std_logic ;
        q           : out std_logic_vector (7 downto 0);
        usedw       : out std_logic_vector (11 downto 0)
    );
end component;


component tic_uart_sync_rx_la_fifo_1k is
	port
	(
		aclr		: in  std_logic ;
		clock		: in  std_logic ;
		data		: in  std_logic_vector (8 downto 0);
		rdreq		: in  std_logic ;
		sclr		: in  std_logic ;
		wrreq		: in  std_logic ;
		empty		: out std_logic ;
		full		: out std_logic ;
		q		    : out std_logic_vector (8 downto 0);
		usedw		: out std_logic_vector (9 downto 0)
	);
end component;


component tic_uart_sync_rx_la_fifo_2k is
	port
	(
		aclr		: in  std_logic ;
		clock		: in  std_logic ;
		data		: in  std_logic_vector (8 downto 0);
		rdreq		: in  std_logic ;
		sclr		: in  std_logic ;
		wrreq		: in  std_logic ;
		empty		: out std_logic ;
		full		: out std_logic ;
		q		    : out std_logic_vector (8 downto 0);
		usedw		: out std_logic_vector (10 downto 0)
	);
end component;

component tic_uart_sync_rx_la_fifo_4k is
	port
	(
		aclr		: in  std_logic ;
		clock		: in  std_logic ;
		data		: in  std_logic_vector (8 downto 0);
		rdreq		: in  std_logic ;
		sclr		: in  std_logic ;
		wrreq		: in  std_logic ;
		empty		: out std_logic ;
		full		: out std_logic ;
		q		    : out std_logic_vector (8 downto 0);
		usedw		: out std_logic_vector (11 downto 0)
	);
end component;

-- Constants

   
-- Types, subtypes

 
-- Signals

signal fifo_arst : std_logic;

signal srst_pipe : std_logic_vector(3 downto 0);

--
type array_of_vec_type is array (0 to g_wr_depth-1) of std_logic_vector(g_wr_data_width-1 downto 0);
signal data_array        : array_of_vec_type;
signal wr_ptr            : std_logic_vector(g_wr_levwidth-2   downto 0);
signal rd_ptr            : std_logic_vector(g_wr_levwidth-2   downto 0);
signal lev               : std_logic_vector(g_wr_levwidth-1   downto 0);
signal rd_data_reg       : std_logic_vector(g_wr_data_width-1 downto 0); 
signal rd_data_valid_reg : std_logic;
signal full_sig          : std_logic;
signal empty_sig         : std_logic;

signal wr_usedw          : std_logic_vector(g_wr_levwidth-1 downto 0);
   
begin

--
-- Correct the polarity of the async reset if necessary
--

fifo_arst <= '1' when arst = g_arst_pol else '0';


-- --
-- -- Logic based version - no macros
-- --
using_logic_version : if g_sync and
                         g_use_logic and
                        (g_wr_data_width = g_rd_data_width) generate
 
   --
   -- read and Write pointers, level
   --
   process(wr_clk,fifo_arst)
   variable update_vec : std_logic_vector(1 downto 0);
   begin
      if fifo_arst = '1' then
         wr_ptr            <= (others => '0');
         rd_ptr            <= (others => '0');
         lev               <= (others => '0');
         rd_data_reg       <= (others => '0');
         rd_data_valid_reg <= '0';
         
      elsif wr_clk'event and wr_clk = '1' then
         if srst = '1' then
            wr_ptr            <= (others => '0');   
            rd_ptr            <= (others => '0');
            lev               <= (others => '0');
            rd_data_reg       <= (others => '0');
            rd_data_valid_reg <= '0';
         else
            rd_data_valid_reg <= '0';
            -- Update logic for the pointers and the lev
            update_vec := rd_en & wr_en;
            case update_vec is
            
               when "01" => -- write only
                  if lev(lev'left) /= '1' then -- dont write if full 
                     wr_ptr <= wr_ptr + 1;   
                     rd_ptr <= rd_ptr;     -- just explicitely showing this although VHDL does not require
                     lev    <= lev + 1;
                     data_array(conv_integer('0'&wr_ptr)) <= wr_data;    -- Update the specific data  in the array
                  end if;   
               when "10" => -- read only
                  if conv_integer('0'&lev) /= 0 then -- dont read if empty 
                     wr_ptr <= wr_ptr; -- just explicitely showing this although VHDL does not require  
                     rd_ptr <= rd_ptr + 1; 
                     lev    <= lev - 1;
                     rd_data_reg <= data_array(conv_integer('0'&rd_ptr));
                     rd_data_valid_reg <= '1';
                  end if;             
                  
               when "11" =>
                            
                  if lev(lev'left) = '1' then -- if full
                     wr_ptr <= wr_ptr;     -- Dont update the write pointer! just explicitely showing this although VHDL does not require
                     rd_ptr <= rd_ptr + 1; -- read pointer will advance
                     lev    <= lev - 1;  -- lev with decrement since write was rejected but read was not.
                     rd_data_reg <= data_array(conv_integer('0'&rd_ptr)); 
                     rd_data_valid_reg <= '1';            
                  elsif conv_integer('0'&lev) = 0 then -- if empty
                     wr_ptr <= wr_ptr + 1; -- Write pointer will advance
                     rd_ptr <= rd_ptr;     -- Dont update the read pointer! just explicitely showing this although VHDL does not require
                     lev    <= lev + 1;  -- lev with decrement since write was rejected but read was not.
                     data_array(conv_integer('0'&wr_ptr)) <= wr_data;    -- Update the specific data byte in the array             
                  else -- neither empty nor full   
                     wr_ptr <= wr_ptr + 1; -- Update the write pointer
                     rd_ptr <= rd_ptr + 1; -- Update the read pointer
                     lev    <= lev;      -- lev stays the same since simultaneous read and write
                     rd_data_reg <= data_array(conv_integer('0'&rd_ptr));   
                     rd_data_valid_reg <= '1';              
                     data_array(conv_integer('0'&wr_ptr)) <= wr_data;    -- Update the specific data  in the array                            
                  end if;
                          
                when others =>  
                   null;        
            end case;
         end if;      
      end if;    
   end process;   
   
   --
   -- Drive output data port with registered output or direct from array based on the lookahead setting
   --
    
   rd_data       <= data_array(conv_integer('0'&rd_ptr)) when g_showahead else rd_data_reg;
   rd_data_valid <= '1' when ((conv_integer('0'&lev) /= 0) and g_showahead) or ((rd_data_valid_reg = '1') and not(g_showahead)) else '0';    
   rd_empty      <= '1' when conv_integer('0'&lev) = 0 else '0';
   wr_full       <= lev(lev'left); 
   rd_level      <= lev(lev'left downto 0); 
   wr_level      <= lev(lev'left downto 0);

end generate using_logic_version;



--
-- Selective instantiation of fifos
--

-- 1k TX 
using_tic_uart_sync_tx_la_fifo_1k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 8        and 
  g_wr_depth     = 1024     and 
  g_wr_levwidth  = 11       and                                     
                             
  g_rd_data_width= 8        and 
  g_rd_depth     = 1024     and       
  g_rd_levwidth  = 11        
   
   
   generate
  
   -- Gen a read valid for sync fifos only
   --process(wr_clk,fifo_arst)
   --begin
   --   if fifo_arst = '1' then
   --      rd_data_valid <= '0';
   --   elsif wr_clk'event and wr_clk = '1' then         
   --      rd_data_valid <= rd_en;
   --   end if;   
   --end process;   
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
     
inst_tic_uart_sync_tx_la_fifo_1k : tic_uart_sync_tx_la_fifo_1k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(9 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(9 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(9 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_tx_la_fifo_1k;

-- 2k TX
using_tic_uart_sync_tx_la_fifo_2k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 8        and 
  g_wr_depth     = 2048     and 
  g_wr_levwidth  = 12       and                                     
                             
  g_rd_data_width= 8        and 
  g_rd_depth     = 2048     and       
  g_rd_levwidth  = 12        
   
   
   generate
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
   
inst_tic_uart_sync_tx_la_fifo_2k : tic_uart_sync_tx_la_fifo_2k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(10 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(10 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(10 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_tx_la_fifo_2k;


-- 4k TX
using_tic_uart_sync_tx_la_fifo_4k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 8        and 
  g_wr_depth     = 4096     and 
  g_wr_levwidth  = 13       and                                     
                             
  g_rd_data_width= 8        and 
  g_rd_depth     = 4096     and       
  g_rd_levwidth  = 13        
   
   
   generate
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
   
inst_tic_uart_sync_tx_la_fifo_4k : tic_uart_sync_tx_la_fifo_4k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(11 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(11 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(11 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_tx_la_fifo_4k;


----------------------RX FIFOs------------------------------------

-- 1k rx 
using_tic_uart_sync_rx_la_fifo_1k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 9        and 
  g_wr_depth     = 1024     and 
  g_wr_levwidth  = 11       and                                     
                             
  g_rd_data_width= 9        and 
  g_rd_depth     = 1024     and       
  g_rd_levwidth  = 11        
   
   
   generate
  
   -- Gen a read valid for sync fifos only
   --process(wr_clk,fifo_arst)
   --begin
   --   if fifo_arst = '1' then
   --      rd_data_valid <= '0';
   --   elsif wr_clk'event and wr_clk = '1' then         
   --      rd_data_valid <= rd_en;
   --   end if;   
   --end process;   
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
     
inst_tic_uart_sync_rx_la_fifo_1k : tic_uart_sync_rx_la_fifo_1k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(9 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(9 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(9 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_rx_la_fifo_1k;

-- 2k rx
using_tic_uart_sync_rx_la_fifo_2k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 9        and 
  g_wr_depth     = 2048     and 
  g_wr_levwidth  = 12       and                                     
                             
  g_rd_data_width= 9        and 
  g_rd_depth     = 2048     and       
  g_rd_levwidth  = 12        
   
   
   generate
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
   
inst_tic_uart_sync_rx_la_fifo_2k : tic_uart_sync_rx_la_fifo_2k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(10 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(10 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(10 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_rx_la_fifo_2k;


-- 4k rx
using_tic_uart_sync_rx_la_fifo_4k : if
  
  g_vendor       = "altera" and
                             
  g_sync         = true     and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and 
                                                           
  g_wr_data_width= 9        and 
  g_wr_depth     = 4096     and 
  g_wr_levwidth  = 13       and                                     
                             
  g_rd_data_width= 9        and 
  g_rd_depth     = 4096     and       
  g_rd_levwidth  = 13        
   
   
   generate
   
   rd_data_valid <= not empty_sig; -- for lookahead this is true 
   
inst_tic_uart_sync_rx_la_fifo_4k : tic_uart_sync_rx_la_fifo_4k

    port map(
        aclr        => fifo_arst,                                                 
        clock       => wr_clk,                                                    
        data        => wr_data,                                                   
        rdreq       => rd_en,                                                     
        sclr        => srst,                                                      
        wrreq       => wr_en,                                                     
        empty       => empty_sig,                                                  
        full        => full_sig,                                                  
        q           => rd_data,                                                   
        usedw       => wr_usedw(11 downto 0) 
    );
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig;                                                       
    rd_level     <= full_sig & wr_usedw(11 downto 0);  -- converted level handle count for being full        
    wr_level     <= full_sig & wr_usedw(11 downto 0);  -- use same for both sides of a sync fifo     
    

end generate using_tic_uart_sync_rx_la_fifo_4k;




end; -- rtl


