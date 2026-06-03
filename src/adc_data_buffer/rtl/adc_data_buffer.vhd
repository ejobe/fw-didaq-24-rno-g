--*
--*                          RTL source file 
--*             By Logic Tectonics for the University of Chicago 
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics          www.logic-tectonics.com 
--*   Phone  : 815-975-7070
-------------------------------------------------------------------------------
--*
--*   Description: This module implements a two stage FIFO buffer.
--*                The fist stage, completely sync, will act a a rolling
--*                buffer during capture of data. If it gets full during 
--*                capture it starts to auto drop data while maintaining 
--*                the first in first out temporal/sequential alignment.                                   
--*                When it is told to stop capturing it the first
--*                stage fifo starts to unload the data into the second
--*                stage small fifo that acts as the interface to the 
--*                rest of the system. The second stage fifo is async and
--*                converts to the necessary read clock domain.                                    
--*                                                   
--*                                                   
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   20250119       Logic Tectonics       First Draft
--*   20250202       Same                  Bug fixes during top level sim.
--*
--*   
--*----------------------------------------------------------------------------
--*   
--*   Reference:  
--*
--*   Synthesis Considerations:
--*
--*
--*   Par Considerations: There are meta flops
--*
--*----------------------------------------------------------------------------

library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


entity adc_data_buffer is

   port(
      
      arstn                      : in   std_logic;                      -- Chip async reset active low.

      clk_wr                     : in   std_logic;                      -- The data will be pushed in at this rate which will also be 
      clk_rd                     : in   std_logic;                      -- 125MHz clock for the avalon interface                                                                                                                                               
      
      -- Data form the JESD link
      -- All of these re in the clk_wide domain                                                          
      adc_0_wide_data            : in  std_logic_vector(31 downto 0);   -- The data format is big endian, where the              
      adc_0_wide_data_valid      : in  std_logic;                       -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                                        -- octet/sample is placed in bit [7:0].                                                                                                                          
      adc_1_wide_data            : in  std_logic_vector(31 downto 0);                                                        
      adc_1_wide_data_valid      : in  std_logic;                                                                                                  
                                 
      adc_2_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_2_wide_data_valid      : in  std_logic;                                                                                                  
                                 
      adc_3_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_3_wide_data_valid      : in  std_logic;                                                                                               
                                                                         
      adc_4_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_4_wide_data_valid      : in  std_logic;                                                                                                                                                                        
                                                                                    
      adc_5_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_5_wide_data_valid      : in  std_logic;                                                                                                   
                                 
      adc_6_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_6_wide_data_valid      : in  std_logic;                                                                                                    
                                 
      adc_7_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_7_wide_data_valid      : in  std_logic;                                                                                          
                                                                        
      adc_8_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_8_wide_data_valid      : in  std_logic;                                                                                                                                                                    
                                                                                    
      adc_9_wide_data            : in  std_logic_vector(31 downto 0);  
      adc_9_wide_data_valid      : in  std_logic;                                                                                                
                                 
      adc_10_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_10_wide_data_valid     : in  std_logic;                                                                                                 
                                 
      adc_11_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_11_wide_data_valid     : in  std_logic;     

      adc_12_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_12_wide_data_valid     : in  std_logic;                                                                                   
                                                                                                                                                                      
      adc_13_wide_data           : in  std_logic_vector(31 downto 0);                                                        
      adc_13_wide_data_valid     : in  std_logic;                                                                                                  
                                 
      adc_14_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_14_wide_data_valid     : in  std_logic;                                                                                                  
                                 
      adc_15_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_15_wide_data_valid     : in  std_logic;                                                                                               
                                                                        
      adc_16_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_16_wide_data_valid     : in  std_logic;                                                                                                                                                                        
                                                                                   
      adc_17_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_17_wide_data_valid     : in  std_logic;                                                                                                   
                                 
      adc_18_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_18_wide_data_valid     : in  std_logic;                                                                                                    
                                 
      adc_19_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_19_wide_data_valid     : in  std_logic;                                                                                          
                                                                       
      adc_20_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_20_wide_data_valid     : in  std_logic;                                                                                                                                                                    
                                                                                   
      adc_21_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_21_wide_data_valid     : in  std_logic;                                                                                                
                                 
      adc_22_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_22_wide_data_valid     : in  std_logic;                                                                                                 
                                 
      adc_23_wide_data           : in  std_logic_vector(31 downto 0);  
      adc_23_wide_data_valid     : in  std_logic;           
            
      
      -- ADC data buffer/FIFO interfaces. 
      -- When capture_ctrl(0) is high the buffers in the adc buffer module will capture
      -- data from the link. 
      -- If they become full they will begin to discard the oldest sample. 
      -- When capture_ctrl(0) is set to 0 they will stop capturing and will allow the 
      -- data to be read through the fifo interface to this module.
      -- They can then be read through the adc_0_fifo_data/rd_ack
      -- interfaces or flushed using capture_ctrl(1). The other bits of capture_ctrl(31:2) are not used yet. 
   
      -- The capture_stat(23:0) are the empty indications for each FIFO.
      -- Note that the FIFO interface to this module will not show data until 
      -- after capture_ctrl(0) is set low into order to maintain proer sequential 
      -- data order. I.e. so you can read while capturing.    
      --
      -- The FIFOs are build time settable in depth (easy to change) min setting is enough to store 1 us of samples from
      -- each adc.  
      
      capture_ctrl                       : in   std_logic_vector(31 downto 0); -- In clk_avs domain (this module will convert to other domain as needed)  
      capture_stat                       : out  std_logic_vector(31 downto 0); -- In clk_avs domain (this module converts to this domain before sending)      
      
      adc_0_fifo_data                    : out std_logic_vector(31 downto 0);  -- Data from channel 4 8-bit samps packed              
      adc_0_fifo_rd_ack                  : in  std_logic;                                                                                  
                                                                                                                                                                                                                                                         
      adc_1_fifo_data                    : out std_logic_vector(31 downto 0);                                                        
      adc_1_fifo_rd_ack                  : in  std_logic;                                                                                                  
                                         
      adc_2_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_2_fifo_rd_ack                  : in  std_logic;                                                                                                  
                                         
      adc_3_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_3_fifo_rd_ack                  : in  std_logic;                                                                                               
                                                                                 
      adc_4_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_4_fifo_rd_ack                  : in  std_logic;                                                                                                                                                                        
                                                                                            
      adc_5_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_5_fifo_rd_ack                  : in  std_logic;                                                                                                   
                                         
      adc_6_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_6_fifo_rd_ack                  : in  std_logic;                                                                                                    
                                         
      adc_7_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_7_fifo_rd_ack                  : in  std_logic;                                                                                          
                                                                                
      adc_8_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_8_fifo_rd_ack                  : in  std_logic;                                                                                                                                                                    
                                                                                            
      adc_9_fifo_data                    : out std_logic_vector(31 downto 0);  
      adc_9_fifo_rd_ack                  : in  std_logic;                                                                                                
                                         
      adc_10_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_10_fifo_rd_ack                 : in  std_logic;                                                                                                 
                                         
      adc_11_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_11_fifo_rd_ack                 : in  std_logic;                                                                                             
 
      adc_12_fifo_data                   : out std_logic_vector(31 downto 0);               
      adc_12_fifo_rd_ack                 : in  std_logic;                                                                                  
                                                                                                                                                                                                                                                        
      adc_13_fifo_data                   : out std_logic_vector(31 downto 0);                                                        
      adc_13_fifo_rd_ack                 : in  std_logic;                                                                                                  
                                         
      adc_14_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_14_fifo_rd_ack                 : in  std_logic;                                                                                                  
                                         
      adc_15_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_15_fifo_rd_ack                 : in  std_logic;                                                                                               
                                                                                
      adc_16_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_16_fifo_rd_ack                 : in  std_logic;                                                                                                                                                                        
                                                                                           
      adc_17_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_17_fifo_rd_ack                 : in  std_logic;                                                                                                   
                                         
      adc_18_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_18_fifo_rd_ack                 : in  std_logic;                                                                                                    
                                         
      adc_19_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_19_fifo_rd_ack                 : in  std_logic;                                                                                          
                                                                               
      adc_20_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_20_fifo_rd_ack                 : in  std_logic;                                                                                                                                                                    
                                                                                           
      adc_21_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_21_fifo_rd_ack                 : in  std_logic;                                                                                                
                                         
      adc_22_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_22_fifo_rd_ack                 : in  std_logic;                                                                                                 
                                         
      adc_23_fifo_data                   : out std_logic_vector(31 downto 0);  
      adc_23_fifo_rd_ack                 : in  std_logic                                      
                                                                                             
                   
   );
   
end entity adc_data_buffer;      
      
architecture rtl of adc_data_buffer is     

-- Components 

component generic_fifo_shell is
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
      g_rd_levwidth   : positive  := 10;       -- Width of the level port. The high order bit is the same as the full bit
                                                                                                   
      g_uniquify      :  string   := "none"
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

end component generic_fifo_shell;

constant c_in_fifo_log2_depth : natural := 10; -- sets the first stage fifo depth


-- Constants
--constant invert_mask	: std_logic_vector(23 downto 0) := x"CCCC"; --sign invert chs 0,1
-- Types 


-- Signals

signal all_ones                     : std_logic_vector(31 downto 0);
signal all_zeros                    : std_logic_vector(31 downto 0);
                                    
type fifo_data_type                 is array (0 to 23) of std_logic_vector(31 downto 0);  

--signal adc_wide_data_valid        : std_logic_vector(23 downto 0);                    
--signal adc_wide_data_ready        : std_logic_vector(23 downto 0);                    
--
signal in_fifo_wr_en                : std_logic_vector(23 downto 0);                               
signal in_fifo_wr_data              : fifo_data_type;
signal in_fifo_wr_full              : std_logic_vector(23 downto 0);                                     
                                                        
type   in_fifo_rd_level_type        is array (0 to 23) of std_logic_vector(c_in_fifo_log2_depth downto 0);                                                  
signal in_fifo_rd_en                : std_logic_vector(23 downto 0);                                     
signal in_fifo_rd_data              : fifo_data_type;   
signal in_fifo_rd_level             : in_fifo_rd_level_type;
signal in_fifo_rd_empty             : std_logic_vector(23 downto 0);                                      
                                    

signal out_fifo_wr_en               : std_logic_vector(23 downto 0);                               
--signal out_fifo_wr_data             : fifo_data_type;
signal out_fifo_wr_full             : std_logic_vector(23 downto 0);                                     
                                                                                                      
signal out_fifo_rd_en               : std_logic_vector(23 downto 0);                                     
signal out_fifo_rd_data             : fifo_data_type;   
signal out_fifo_rd_empty            : std_logic_vector(23 downto 0);                                      

signal capt_enb_in_clk_wr_domain_mf : std_logic;
signal capt_enb_in_clk_wr_domain    : std_logic;

signal flush_in_clk_wr_domain_mf    : std_logic;
signal flush_in_clk_wr_domain       : std_logic;

signal flush_in_clk_rd_domain       : std_logic;
signal capt_enb_in_clk_rd_domain    : std_logic;
 
signal in_fifo_rst                  : std_logic;                                               
signal out_fifo_rst                 : std_logic; 

begin -- rtl                           

all_ones  <= (others => '1');
all_zeros <= (others => '0');

process(clk_wr,arstn)
begin
   if arstn = '0' then
      capt_enb_in_clk_wr_domain_mf <= '0';
      capt_enb_in_clk_wr_domain    <= '0';
      
      flush_in_clk_wr_domain_mf    <= '0';
      flush_in_clk_wr_domain       <= '0';
      
   elsif clk_wr'event and clk_wr = '1' then
      capt_enb_in_clk_wr_domain_mf <= capture_ctrl(0);
      capt_enb_in_clk_wr_domain    <= capt_enb_in_clk_wr_domain_mf;
      
      flush_in_clk_wr_domain_mf    <= capture_ctrl(1);
      flush_in_clk_wr_domain       <= flush_in_clk_wr_domain_mf;
      
   end if;
end process;   


-- Map the input data to FIFO inputs, manage the writes.
-- Only write when in capture mode and not in flush mode and there is data avialable from the adcs.
-- Having the flush term might be overkill if SW behaves properly and does not ever enable capture and flush... 
--
in_fifo_wr_data(0) <= adc_0_wide_data;     
in_fifo_wr_en(0) <= adc_0_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(1) <= adc_1_wide_data;       
in_fifo_wr_en(1) <= adc_1_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(2) <= adc_2_wide_data;       
in_fifo_wr_en(2) <= adc_2_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(3) <= adc_3_wide_data;       
in_fifo_wr_en(3) <= adc_3_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(4) <= adc_4_wide_data;       
in_fifo_wr_en(4) <= adc_4_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(5) <= adc_5_wide_data;       
in_fifo_wr_en(5) <= adc_5_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(6) <= adc_6_wide_data;       
in_fifo_wr_en(6) <= adc_6_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(7) <= adc_7_wide_data;       
in_fifo_wr_en(7) <= adc_7_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(8) <= adc_8_wide_data;       
in_fifo_wr_en(8) <= adc_8_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(9) <= adc_9_wide_data;       
in_fifo_wr_en(9) <= adc_9_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0'; 
                      
in_fifo_wr_data(10) <= adc_10_wide_data;      
in_fifo_wr_en(10) <= adc_10_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(11) <= adc_11_wide_data;      
in_fifo_wr_en(11) <= adc_11_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';

in_fifo_wr_data(12) <= adc_12_wide_data;      
in_fifo_wr_en(12) <= adc_12_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(13) <= adc_13_wide_data;      
in_fifo_wr_en(13) <= adc_13_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(14) <= adc_14_wide_data;      
in_fifo_wr_en(14) <= adc_14_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(15) <= adc_15_wide_data;      
in_fifo_wr_en(15) <= adc_15_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(16) <= adc_16_wide_data;      
in_fifo_wr_en(16) <= adc_16_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(17) <= adc_17_wide_data;      
in_fifo_wr_en(17) <= adc_17_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(18) <= adc_18_wide_data;      
in_fifo_wr_en(18) <= adc_18_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(19) <= adc_19_wide_data;      
in_fifo_wr_en(19) <= adc_19_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(20) <= adc_20_wide_data;      
in_fifo_wr_en(20) <= adc_20_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(21) <= adc_21_wide_data;      
in_fifo_wr_en(21) <= adc_21_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(22) <= adc_22_wide_data;      
in_fifo_wr_en(22) <= adc_22_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';
                      
in_fifo_wr_data(23) <= adc_23_wide_data;      
in_fifo_wr_en(23) <= adc_23_wide_data_valid  when capt_enb_in_clk_wr_domain_mf = '1' and flush_in_clk_wr_domain = '0' else '0';

--
-- Input FIFOs, autoread if almost full and still capturing
--
in_fifo_rst <= flush_in_clk_wr_domain or not(arstn);
 
gen_in_fifos : for i in 0 to 23 generate 

inst_generic_fifo_shell : generic_fifo_shell
   generic map(
      g_vendor        => "altera",
                    
      g_arst_pol      => '1',      
      g_sync          => true,     
      g_showahead     => true,    
                      
      g_use_logic     => false,                                                               
                                   
      g_wr_data_width => 32,       
      g_wr_depth      => 2**c_in_fifo_log2_depth,       
      g_wr_levwidth   => c_in_fifo_log2_depth+1,  -- set to log2(g_wr_depth) + 1                                  
                    
      g_rd_data_width => 32,                           
      g_rd_depth      => 2**c_in_fifo_log2_depth,                          
      g_rd_levwidth   => c_in_fifo_log2_depth+1  -- set to log2(g_wr_depth) + 1     
                                                                                 
      --g_uniquify      => "distributed"
   )
   port map(
      
      -- Clock and reset
      arst                  => in_fifo_rst,      
      srst                  => '0',
      
      wr_clk                => clk_wr,
      wr_en                 => in_fifo_wr_en(i),  
      wr_data               => in_fifo_wr_data(i),
      wr_full               => in_fifo_wr_full(i),
      wr_level              => open,
      
      rd_clk                => clk_wr,     
      rd_en                 => in_fifo_rd_en(i),   
      rd_data               => in_fifo_rd_data(i), 
      rd_empty              => in_fifo_rd_empty(i),
      rd_level              => in_fifo_rd_level(i),
      rd_data_valid         => open    
  
   );
   --
   -- Manage the auto read to keep it as a running FIFO
   -- by reading if almost full during normal capture so its a rolling buffer. 
   -- Its a sync FIFO so
   -- should be spot on in terms of level reporting
   -- If not in capture mode or in flush/reset mode the the reads come from the 
   -- second stage out FIFO not being full and the in fifo having data to be read.
   --  
    in_fifo_rd_en(i) <= '1' when capt_enb_in_clk_wr_domain = '1' and conv_integer('0'&in_fifo_rd_level(i)) > (2**c_in_fifo_log2_depth-3) else -- so if almost full start auto popping/reading
                        '1' when capt_enb_in_clk_wr_domain = '0' and flush_in_clk_wr_domain = '0' and in_fifo_rd_empty(i) = '0' and out_fifo_wr_full(i) = '0' else -- only transfer data to the out fifo when not in active capture
                        '0';
   
end generate gen_in_fifos;  

 
-- These are already in the correct domain for reads
capt_enb_in_clk_rd_domain <= capture_ctrl(0);
flush_in_clk_rd_domain    <= capture_ctrl(1);
 
out_fifo_rst <= flush_in_clk_rd_domain or not(arstn);
 
gen_out_fifos : for i in 0 to 23 generate 

inst_generic_fifo_shell : generic_fifo_shell
   generic map(
      g_vendor        => "altera",
                    
      g_arst_pol      => '1',      
      g_sync          => false,     
      g_showahead     => true,    
                      
      g_use_logic     => false,                                                               
                                   
      g_wr_data_width => 32,       
      g_wr_depth      => 32,       
      g_wr_levwidth   => 6,  -- set to log2(g_wr_depth) + 1                                  
                    
      g_rd_data_width => 32,                           
      g_rd_depth      => 32,                          
      g_rd_levwidth   => 6,  -- set to log2(g_wr_depth) + 1     
                                                                                 
      g_uniquify      => "distributed_mem"
   )
   port map(
      
      -- Clock and reset
      arst                  => out_fifo_rst,      
      srst                  => '0',
      
      wr_clk                => clk_wr,
      wr_en                 => out_fifo_wr_en(i),  
      wr_data               => in_fifo_rd_data(i),    -- from the read side of the "in" fifo
      wr_full               => out_fifo_wr_full(i),
      wr_level              => open,
      
      rd_clk                => clk_rd,     
      rd_en                 => out_fifo_rd_en(i),   
      rd_data               => out_fifo_rd_data(i), 
      rd_empty              => out_fifo_rd_empty(i),
      rd_level              => open,
      rd_data_valid         => open    
  
   );
   
   -- Write to this fifo when not flushing or not when the main circular FIFO is capturing
   out_fifo_wr_en(i) <= '1' when capt_enb_in_clk_wr_domain = '0' and flush_in_clk_wr_domain = '0' and in_fifo_rd_empty(i) = '0' and out_fifo_wr_full(i) = '0' else
                        '0';                                                                                                                                      
   -- map the empties to these status bits                     
   capture_stat(i) <= out_fifo_rd_empty(i); 
end generate gen_out_fifos; 

-- Set the rest of these to 0 until used for soemthing.
capture_stat(31 downto 24) <= (others => '0'); 

--
-- Map the ouputs
--    
adc_0_fifo_data   <= out_fifo_rd_data(0);
out_fifo_rd_en(0) <= adc_0_fifo_rd_ack; 
                  
adc_1_fifo_data   <= out_fifo_rd_data(1);
out_fifo_rd_en(1) <= adc_1_fifo_rd_ack; 
                  
adc_2_fifo_data   <= out_fifo_rd_data(2);
out_fifo_rd_en(2) <= adc_2_fifo_rd_ack; 
                  
adc_3_fifo_data   <= out_fifo_rd_data(3);
out_fifo_rd_en(3) <= adc_3_fifo_rd_ack; 
                  
adc_4_fifo_data   <= out_fifo_rd_data(4);
out_fifo_rd_en(4) <= adc_4_fifo_rd_ack; 
                  
adc_5_fifo_data   <= out_fifo_rd_data(5);
out_fifo_rd_en(5) <= adc_5_fifo_rd_ack; 
                  
adc_6_fifo_data   <= out_fifo_rd_data(6);
out_fifo_rd_en(6) <= adc_6_fifo_rd_ack; 
                  
adc_7_fifo_data   <= out_fifo_rd_data(7);
out_fifo_rd_en(7) <= adc_7_fifo_rd_ack; 
                  
adc_8_fifo_data   <= out_fifo_rd_data(8);
out_fifo_rd_en(8) <= adc_8_fifo_rd_ack; 
                  
adc_9_fifo_data   <= out_fifo_rd_data(9);
out_fifo_rd_en(9) <= adc_9_fifo_rd_ack; 
                  
adc_10_fifo_data   <= out_fifo_rd_data(10);
out_fifo_rd_en(10) <= adc_10_fifo_rd_ack;
                  
adc_11_fifo_data   <= out_fifo_rd_data(11);
out_fifo_rd_en(11) <= adc_11_fifo_rd_ack;

adc_12_fifo_data   <= out_fifo_rd_data(12);
out_fifo_rd_en(12) <= adc_12_fifo_rd_ack;
                  
adc_13_fifo_data   <= out_fifo_rd_data(13);
out_fifo_rd_en(13) <= adc_13_fifo_rd_ack;
                  
adc_14_fifo_data   <= out_fifo_rd_data(14);
out_fifo_rd_en(14) <= adc_14_fifo_rd_ack;
                  
adc_15_fifo_data   <= out_fifo_rd_data(15);
out_fifo_rd_en(15) <= adc_15_fifo_rd_ack;
                  
adc_16_fifo_data   <= out_fifo_rd_data(16);
out_fifo_rd_en(16) <= adc_16_fifo_rd_ack;
                  
adc_17_fifo_data   <= out_fifo_rd_data(17);
out_fifo_rd_en(17) <= adc_17_fifo_rd_ack;
                  
adc_18_fifo_data   <= out_fifo_rd_data(18);
out_fifo_rd_en(18) <= adc_18_fifo_rd_ack;
                  
adc_19_fifo_data   <= out_fifo_rd_data(19);
out_fifo_rd_en(19) <= adc_19_fifo_rd_ack;
                  
adc_20_fifo_data   <= out_fifo_rd_data(20);
out_fifo_rd_en(20) <= adc_20_fifo_rd_ack;
                  
adc_21_fifo_data   <= out_fifo_rd_data(21);
out_fifo_rd_en(21) <= adc_21_fifo_rd_ack;
                  
adc_22_fifo_data   <= out_fifo_rd_data(22);
out_fifo_rd_en(22) <= adc_22_fifo_rd_ack;
                  
adc_23_fifo_data   <= out_fifo_rd_data(23);
out_fifo_rd_en(23) <= adc_23_fifo_rd_ack;

                                               
end rtl;                                                         
                                                            
                                                           
                                                             
                                                                         
                                                       
                                                       
                                                       
                                                       