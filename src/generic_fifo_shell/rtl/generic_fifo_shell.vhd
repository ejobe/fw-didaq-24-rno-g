--*----------------------------------------------------------------------------
--*                                RTL source file
--*                               
--*                                Dean Kostan 2014
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics. www.logic-tectonics.com         
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This is a generic FIFO shell and is used to selectively 
--*                instantiate vendor specific FIFOs based on genertic settings
--*                          
--*                    
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   Mar/05/2014    DAK                   Started...
--*   Jan//2015      DAK                   Added new fifos
--*   20230522       DAK                   Added alt_sync_fifo_wr8_rd8_1024_deep_la
--*   202412xx       Same                  Adding cores for  
--*                                        new project.
--*                                        Added alt_sync_fifo_wr32_rd32_1024_deep_la 
--*                                              alt_async_fifo_wr32_rd32_32_deep_dr_la
--*                                         
--*----------------------------------------------------------------------------
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


entity generic_fifo_shell is
   generic(
      g_vendor           : string    := "altera";
                         
      g_arst_pol         : std_logic := '1';      -- Sets internal reset polarity of the async reset input      
      g_syncd_arst_width : positive  := 3;        -- Sets the width of the reset stretcher for async FIFOs reset input 
      g_sync             : boolean   := true;     -- True if synchronous, false async (different clocks on read/write ports
      g_showahead        : boolean   := false;    -- If true then its a lookahead fifo, else the read data shows up 1 cycle
                                                  -- after the rd_en is asserted   
      g_use_logic        : boolean   := false;    -- If true use a logic version versus core, not currently supported for aync or differnt port
                                                  -- sizes for write versus read side
                         
                                                  
      g_wr_data_width    : positive  := 18;       -- Fifo write side data width
      g_wr_depth         : positive  := 512;      -- Number of words deep from write side perspective
      g_wr_levwidth      : positive  := 10;       -- Width of the level port. The high order bit is the same as the full bit
                                                  
                         
      g_rd_data_width    : positive  := 18;       -- Fifo write side data width                                                                            
      g_rd_depth         : positive  := 512;      -- Number of words deep from write side perspective                                                      
      g_rd_levwidth      : positive  := 10;       -- Width of the level port. The high order bit is the same as the full bit
                                                                                                      
      g_uniquify         :  string   := "none"
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
      rd_en                 : in   std_logic;  -- is an ack for showahead, request for non showahead
      rd_data               : out  std_logic_vector(g_rd_data_width-1 downto 0);
      rd_empty              : out  std_logic;
      rd_level              : out  std_logic_vector(g_rd_levwidth-1 downto 0);
      rd_data_valid         : out  std_logic -- High when read data is valid. Handles cases of fifo read latency in non lookahead. In lookahead it is not(rd_empty)    
  
   );

end entity generic_fifo_shell;


architecture rtl of generic_fifo_shell is



-- components 

component alt_sync_fifo_wr8_rd8_1024_deep_la IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		
		clock		: IN STD_LOGIC ;
		
		wrreq		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		
		rdreq		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		
		usedw		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);		
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC 
		
		
	);
END component alt_sync_fifo_wr8_rd8_1024_deep_la;

component alt_sync_fifo_wr32_rd32_1024_deep_la IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		
		clock		: IN STD_LOGIC ;
		
		wrreq		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		
		rdreq		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		
		usedw		: OUT STD_LOGIC_VECTOR (9 DOWNTO 0);		
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC 
		
		
	);
END component alt_sync_fifo_wr32_rd32_1024_deep_la;




component alt_async_fifo_wr64_rd64_16_deep_dr_la is
    port (
        data    : in  std_logic_vector(63 downto 0); 
        wrreq   : in  std_logic;           
        rdreq   : in  std_logic;           
        wrclk   : in  std_logic;           
        rdclk   : in  std_logic;           
        aclr    : in  std_logic;           
        q       : out std_logic_vector(63 downto 0);                   
        rdusedw : out std_logic_vector(3 downto 0);                    
        wrusedw : out std_logic_vector(3 downto 0);                    
        rdfull  : out std_logic;                                       
        rdempty : out std_logic;                                       
        wrfull  : out std_logic                                        
    );
end component alt_async_fifo_wr64_rd64_16_deep_dr_la;


component alt_async_fifo_wr32_rd32_32_deep_dr_la is
    port
    (
        aclr        : in std_logic  := '0';
        data        : in std_logic_vector (31 downto 0);
        rdclk       : in std_logic;
        rdreq       : in std_logic;
        wrclk       : in std_logic;
        wrreq       : in std_logic;
        q           : out std_logic_vector (31 downto 0);
        rdempty     : out std_logic;
        rdfull      : out std_logic;
        rdusedw     : out std_logic_vector (4 downto 0);
        wrfull      : out std_logic;
        wrusedw     : out std_logic_vector (4 downto 0)
    );
end component alt_async_fifo_wr32_rd32_32_deep_dr_la;

component alt_async_fifo_wr64_rd64_256_deep_la is
    port (
        data    : in  std_logic_vector(63 downto 0); 
        wrreq   : in  std_logic;           
        rdreq   : in  std_logic;           
        wrclk   : in  std_logic;           
        rdclk   : in  std_logic;           
        aclr    : in  std_logic;           
        q       : out std_logic_vector(63 downto 0);                   
        rdusedw : out std_logic_vector(7 downto 0);                    
        wrusedw : out std_logic_vector(7 downto 0);                    
        rdfull  : out std_logic;                                       
        rdempty : out std_logic;                                       
        wrfull  : out std_logic                                        
    );
end component alt_async_fifo_wr64_rd64_256_deep_la;

-- Constants

   
-- Types, subtypes

 
-- Signals

signal fifo_arst : std_logic;

signal srst_pipe : std_logic_vector(3 downto 0);

--
type array_of_vec_type is array (0 to g_wr_depth-1) of std_logic_vector(g_wr_data_width-1 downto 0);
signal data_array        : array_of_vec_type;
signal wr_ptr            : std_logic_vector(g_wr_levwidth-2   downto 0) := (others => '0'); -- just for sim when not used;
signal rd_ptr            : std_logic_vector(g_wr_levwidth-2   downto 0) := (others => '0'); -- just for sim when not used;
signal lev               : std_logic_vector(g_wr_levwidth-1   downto 0) := (others => '0'); -- just for sim when not used;
signal rd_data_reg       : std_logic_vector(g_wr_data_width-1 downto 0) := (others => '0'); -- just for sim when not used
signal rd_data_valid_reg : std_logic := '0'; -- just for sim when not used
signal full_sig          : std_logic;
signal rd_full_sig       : std_logic;
signal empty_sig         : std_logic;
signal wr_usedw          : std_logic_vector(g_wr_levwidth-1 downto 0);
signal rd_usedw          : std_logic_vector(g_rd_levwidth-1 downto 0);

signal wr_rst_busy       : std_logic;
signal rd_rst_busy       : std_logic;

signal fifo_arst_mf       : std_logic;

signal fifo_arst_sync     : std_logic; 
signal syncd_arst_pipe    : std_logic_vector(g_syncd_arst_width-1 downto 0);
signal syncd_arst         : std_logic;
                          
signal all_zeros          : std_logic_vector(31 downto 0); 
signal all_ones           : std_logic_vector(31 downto 0);  
   
begin

all_zeros <= (others => '0');
all_ones  <= (others => '1');

--
-- Correct the polarity of the async reset if necessary
--

fifo_arst <= '1' when arst = g_arst_pol else '0';

--
-- Just to clean this up a bit for some async fifos used in
-- a sync configuration/use case. 
--

--
-- For now if its a sync fifo it will use the srst input directly
-- and the fifo completely runs from wr_clk. If async it
-- use the wr_clk to generate this pulse and the (async) FIFOs
-- are built to sync the arst they get (this syncd_arst) with thier respective domains
-- External codes shoudl wait 3 wr clocks clocks after an async reset before
-- checking the wr_full 
--
process(wr_clk)
begin
   if wr_clk'event and wr_clk = '1' then
      fifo_arst_mf   <= fifo_arst;
      fifo_arst_sync <= fifo_arst_mf;
      if srst = '1' or fifo_arst_sync = '1' then
         syncd_arst_pipe <= (others => '1');
      else 
         syncd_arst_pipe <= syncd_arst_pipe(syncd_arst_pipe'left-1 downto 0) &'0';
      end if;
      --syncd_arst   <= srst or fifo_arst_mf;
   end if;
end process; 
syncd_arst <= syncd_arst_pipe(syncd_arst_pipe'left);    

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

----------------------start alt_sync_fifo_wr8_rd8_1024_deep_la ----------------------------------------------

using_alt_sync_fifo_wr8_rd8_1024_deep_la : if              
  
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
   
inst_alt_sync_fifo_wr8_rd8_1024_deep_la : alt_sync_fifo_wr8_rd8_1024_deep_la
    port map
    (
        aclr       => fifo_arst,   -- Converted to '1' active polarity    
        sclr       => srst,        -- driectly from top since on the core and always active high
        
        clock      => wr_clk,
        
        wrreq      => wr_en,
        data	   => wr_data,
        
        rdreq 	    => rd_en,
        q		    => rd_data,   
        
        usedw       => wr_usedw(wr_usedw'left-1 downto 0), 	
        empty	    => empty_sig,
        full	    => full_sig         
 
    );
    
    rd_data_valid <= not(empty_sig); -- and rd_en; -- If not empty and reading then the lookahead is data output is valid 
    
    rd_empty       <= empty_sig;
    wr_full        <= full_sig;
    rd_level       <= (others => '0') when empty_sig = '1' else full_sig & wr_usedw(wr_usedw'left-1 downto 0); 
    wr_level       <= full_sig & wr_usedw(wr_usedw'left-1 downto 0); 
  
end generate using_alt_sync_fifo_wr8_rd8_1024_deep_la;

----------------------------------- end alt_sync_fifo_wr8_rd8_1024_deep_la -----------------


----------------------start alt_sync_fifo_wr32_rd32_1024_deep_la ----------------------------------------------

using_alt_sync_fifo_wr32_rd32_1024_deep_la : if              
  
  g_vendor        = "altera" and
                              
  g_sync          = true     and 
  g_showahead     = true     and 
                              
  g_use_logic     = false    and 
                                                            
  g_wr_data_width = 32       and 
  g_wr_depth      = 1024     and 
  g_wr_levwidth   = 11       and                                     
                              
  g_rd_data_width = 32       and 
  g_rd_depth      = 1024     and       
  g_rd_levwidth   = 11        
   
   
  generate   
   
inst_alt_sync_fifo_wr32_rd32_1024_deep_la : alt_sync_fifo_wr32_rd32_1024_deep_la
    port map
    (
        aclr       => fifo_arst,   -- Converted to '1' active polarity    
        sclr       => srst,        -- driectly from top since on the core and always active high
        
        clock      => wr_clk,
        
        wrreq      => wr_en,
        data	   => wr_data,
        
        rdreq 	    => rd_en,
        q		    => rd_data,   
        
        usedw       => wr_usedw(wr_usedw'left-1 downto 0), 	
        empty	    => empty_sig,
        full	    => full_sig         
 
    );
    
    rd_data_valid <= not(empty_sig); -- and rd_en; -- If not empty and reading then the lookahead is data output is valid 
    
    rd_empty       <= empty_sig;
    wr_full        <= full_sig;
    rd_level       <= (others => '0') when empty_sig = '1' else full_sig & wr_usedw(wr_usedw'left-1 downto 0); 
    wr_level       <= full_sig & wr_usedw(wr_usedw'left-1 downto 0); 
  
end generate using_alt_sync_fifo_wr32_rd32_1024_deep_la;

----------------------------------- end alt_sync_fifo_wr32_rd32_1024_deep_la -----------------


--------------  alt_async_fifo_wr64_rd64_16_deep_dr_la ----------------------------------------------

using_alt_async_fifo_wr64_rd64_16_deep_dr_la : if -- _dr means distributed mem, Usually for anything <= 128 deep
  
  g_vendor       = "altera" and
                             
  g_sync         = false    and 
  g_showahead    = true     and 
                             
  g_use_logic    = false    and                                                              
                                                                                            
  g_wr_data_width= 64       and                                                              
  g_wr_depth     = 16       and                                                              
  g_wr_levwidth  = 5        and                                                              
                                                                                                  
  g_rd_data_width= 64       and                                                                   
  g_rd_depth     = 16       and                                                                    
  g_rd_levwidth  = 5        and                                                                  
                                                                                                   
  g_uniquify      =  "distributed_mem" 
                                                                                                  
   generate        
                                                                                  
   --
   -- Note that this fifo was generated with logic to sync the aclr
   -- input with the respective clocks.
   --
inst_alt_async_fifo_wr64_rd64_16_deep_dr_la : alt_async_fifo_wr64_rd64_16_deep_dr_la 
  port map (
   
     aclr    => syncd_arst, 
                                               
     wrclk   => wr_clk,                        
     wrreq   => wr_en,
     data    => wr_data,     
     wrusedw => wr_usedw(wr_usedw'left-1 downto 0), -- Not wider since only for block based async  
     wrfull  => full_sig,  
      
     rdclk   => rd_clk,                          
     rdreq   => rd_en,                          
     q       => rd_data, 
     rdfull  => rd_full_sig,                    
     rdempty => empty_sig,                          
                                        
     rdusedw => rd_usedw(rd_usedw'left-1 downto 0) -- Not wider since only for block based async       
                                                         
  );
  
    -- Since lookahead this is true                                                                 
    rd_data_valid <= not(empty_sig);-- and rd_en;              
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig or fifo_arst_sync;     
    -- Be pessemistic                                                  
    rd_level     <= '0' & all_ones(rd_usedw'left-1 downto 0)  when rd_full_sig = '1' else '0' & rd_usedw(rd_usedw'left-1 downto 0); 
    wr_level     <= '1' & all_zeros(wr_usedw'left-1 downto 0) when full_sig = '1'    else '0' & wr_usedw(wr_usedw'left-1 downto 0);     
    

end generate using_alt_async_fifo_wr64_rd64_16_deep_dr_la;



--------------  alt_async_fifo_wr32_rd32_32_deep_dr_la ----------------------------------------------

using_alt_async_fifo_wr32_rd32_32_deep_dr_la : if -- _dr means disctibuted mem, Usually for anything <= 128 deep
  
  g_vendor        = "altera" and
                              
  g_sync          = false    and 
  g_showahead     = true     and 
                              
  g_use_logic     = false    and                                                              
                                                                                             
  g_wr_data_width = 32       and                                                              
  g_wr_depth      = 32       and                                                              
  g_wr_levwidth   = 6        and                                                              
                                                                                                   
  g_rd_data_width = 32       and                                                                   
  g_rd_depth      = 32       and                                                                    
  g_rd_levwidth   = 6        and                                                                  
                                                                                                   
  g_uniquify      =  "distributed_mem" 
                                                                                                  
   generate        
                                                                                  
   --
   -- Note that this fifo was generated with logic to sync the aclr
   -- input with the respective clocks.
   --
inst_alt_async_fifo_wr32_rd32_16_deep_dr_la : alt_async_fifo_wr32_rd32_32_deep_dr_la 
  port map (
   
     aclr    => syncd_arst, 
                                               
     wrclk   => wr_clk,                        
     wrreq   => wr_en,
     data    => wr_data,     
     wrusedw => wr_usedw(wr_usedw'left-1 downto 0), -- Not wider since only for block based async  
     wrfull  => full_sig,  
      
     rdclk   => rd_clk,                          
     rdreq   => rd_en,                          
     q       => rd_data, 
     rdfull  => rd_full_sig,                    
     rdempty => empty_sig,                          
                                        
     rdusedw => rd_usedw(rd_usedw'left-1 downto 0) -- Not wider since only for block based async       
                                                         
  );
  
    -- Since lookahead this is true                                                                 
    rd_data_valid <= not(empty_sig);-- and rd_en;              
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig or fifo_arst_sync;     
    -- Be pessemistic                                                  
    rd_level     <= '0' & all_ones(rd_usedw'left-1 downto 0)  when rd_full_sig = '1' else '0' & rd_usedw(rd_usedw'left-1 downto 0); 
    wr_level     <= '1' & all_zeros(wr_usedw'left-1 downto 0) when full_sig = '1'    else '0' & wr_usedw(wr_usedw'left-1 downto 0);     
    

end generate using_alt_async_fifo_wr32_rd32_32_deep_dr_la;

--------------  alt_async_fifo_wr64_rd64_256_deep_la ----------------------------------------------

using_alt_async_fifo_wr64_rd64_256_deep_la : if 
  
  g_vendor        = "altera" and
                              
  g_sync          = false    and 
  g_showahead     = true     and 
                              
  g_use_logic     = false    and                                                              
                                                                                             
  g_wr_data_width = 64       and                                                              
  g_wr_depth      = 256      and                                                              
  g_wr_levwidth   = 9        and                                                              
                                                                                                   
  g_rd_data_width = 64       and                                                                   
  g_rd_depth      = 256      and                                                                    
  g_rd_levwidth   = 9                                                                          
                                                                                                   
  --g_uniquify      =  "distributed_mem" 
                                                                                                  
   generate        
                                                                                  
   --
   -- Note that this fifo was generated with logic to sync the aclr
   -- input with the respective clocks.
   --
inst_alt_async_fifo_wr64_rd64_256_deep_la : alt_async_fifo_wr64_rd64_256_deep_la 
  port map (
   
     aclr    => syncd_arst, 
                                               
     wrclk   => wr_clk,                        
     wrreq   => wr_en,
     data    => wr_data,     
     wrusedw => wr_usedw(wr_usedw'left-1 downto 0), -- Not wider since only for block based async  
     wrfull  => full_sig,  
      
     rdclk   => rd_clk,                          
     rdreq   => rd_en,                          
     q       => rd_data, 
     rdfull  => rd_full_sig,                    
     rdempty => empty_sig,                          
                                        
     rdusedw => rd_usedw(rd_usedw'left-1 downto 0) -- Not wider since only for block based async       
                                                         
  );
  
    -- Since lookahead this is true                                                                 
    rd_data_valid <= not(empty_sig);-- and rd_en;              
    
    rd_empty     <= empty_sig;
    wr_full      <= full_sig or fifo_arst_sync;     
    -- Be pessemistic                                                  
    rd_level     <= '0' & all_ones(rd_usedw'left-1 downto 0)  when rd_full_sig = '1' else '0' & rd_usedw(rd_usedw'left-1 downto 0); 
    wr_level     <= '1' & all_zeros(wr_usedw'left-1 downto 0) when full_sig = '1'    else '0' & wr_usedw(wr_usedw'left-1 downto 0);     
    

end generate using_alt_async_fifo_wr64_rd64_256_deep_la;


end; -- rtl


