--*
--*                          RTL source file 
--*             By Logic Tectonics for the University of Chicago 
--*
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics          www.logic-tectonics.com 
--*   Phone  : 815-975-7070
-------------------------------------------------------------------------------
--*
--*   Description: This module implements a group of 6 JESD modules
--*                for a specific side of the die. Each handles 2 ADCs. 
--*                They share the same reset sequencer                                                  
--*                There are 6 jesd modules in this module and
--*                the pin assignments at the top level
--*                assume 2 per bank such that the grouping
--*                will work. The outut os thie module 
--*                in 12 streaming interfaces that do not support
--*                backpressure. It could but the destination/consumer should
--*                be responsible for flow control at its own egress
--*                as the AD sources do not have the capability for 
--*                buffering.
--*                                                      
--*                                                   
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
--*   202501xx       Logic Tectonics       First Draft
--*   20251115       Same                  Updated GTS reset sequencer to
--*                                        add the new ports for 25.1.1:
--*                                        i_refclk_bus_out            
--*                                        o_shoreline_refclk_fail_stat
--*                                        Done.
--*   20251204       Same                  Updated comments for use on pass2 board
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


entity jesd_12_chan_if is

   port(
      
      --arstn                      : in   std_logic;                    -- Chip async reset active low.
      clk_sysref                 : in   std_logic_vector(2 downto 0);   -- 3.125MHz, one per bank, there are two XCVRs per JEDS module
                                                                        -- two jesd module per bank      
      clk_gts_pll_ref            : in   std_logic_vector(2 downto 0);   -- 156.25 MHz reference to the transceiver PLLs, one per bank                   
                                                                        
      clk_link_lane              : in   std_logic;                      -- 250 MHz lane and link clock. Can use the same since the same rate
      clk_avs                    : in   std_logic;                      -- 125MHz clock for the avalon interface
                                                                        
      clk_wide                   : in   std_logic;                      -- The data will be pushed out at this rate which will be 
                                                                        -- >250MHz for the downstream buffers 
                                                                        -- which need to capture data for all 24 ADC not just the 12 in this module 
      
      out_fifo_rst_n             : in   std_logic;                      -- The FIFO will sychronize this as needed
                                                                        -- so this can be in any domain but use clk_avs 
                                                                        -- preferred and assert for at least 2 clk_avs.
                                                                        -- Assertion will flush the FIFO.
																								
		sync_adc_n						: out	std_logic_vector(2 downto 0);
                                                                                                   
      rx_rst_n                   : in  std_logic_vector(5 downto 0);    -- domain for these?, async reset?                                      
      rx_rst_ack_n               : out std_logic_vector(5 downto 0);    -- domain for these?                                                                                               
      rx_out_of_reset            : out std_logic_vector(5 downto 0);    -- domain for these?                                           
                                                                                                                                     
      rx_adc_ser_data_p          : in  std_logic_vector(11 downto 0);   -- Serial lanes from ADC.                                                             
      rx_adc_ser_data_n          : in  std_logic_vector(11 downto 0);   -- Serial lanes from ADC 
                                                                        -- Expected mapping (for 3 ADC chips each with 4 ADCs):
                                                                        -- (0)  = ADC Chip(N)   channel A
                                                                        -- (1)  = ADC Chip(N)   channel B
                                                                        -- (2)  = ADC Chip(N)   channel C
                                                                        -- (3)  = ADC Chip(N)   channel D
                                                                        --                   ...
                                                                        -- (8)  = ADC Chip(N+2) channel A
                                                                        -- (9)  = ADC Chip(N+2) channel B
                                                                        -- (10) = ADC Chip(N+2) channel C
                                                                        -- (11) = ADC Chip(N+2) channel D                                                                                                                                               
                                                                        
      loopback_enb               : in  std_logic_vector(5 downto 0);    -- possibly hook up
                                                                      
      avs_rst_n                  : in  std_logic; 
      avs_select                 : in  std_logic_vector(2 downto 0);    -- Set to select which core is to be addressed. Set before addressing
      avs_chipselect             : in  std_logic;                     
      avs_address                : in  std_logic_vector(9 downto 0); 
      avs_read                   : in  std_logic;                     
      avs_readdata               : out std_logic_vector(31 downto 0);
      avs_waitrequest            : out std_logic;                    
      avs_write                  : in  std_logic;                     
      avs_writedata              : in  std_logic_vector(31 downto 0); 
       
      dev_lanes_aligned_from_ext : in  std_logic;
      dev_lanes_aligned_to_ext   : out std_logic;
                                                                  
      adc_lane_locked_to_data    : out std_logic_vector(11 downto 0);  -- todo: Domain?     
                                                                
      adc_0_wide_data            : out std_logic_vector(31 downto 0); -- The data format is big endian, where the              
      adc_0_wide_data_valid      : out std_logic;                     -- earliest octet/sample is placed in bit [31:24] and the latest                                                              
                                                                      -- octet/sample is placed in bit [7:0].                                                                                                                          
      adc_1_wide_data            : out std_logic_vector(31 downto 0);                                                        
      adc_1_wide_data_valid      : out std_logic;                                                                                                  
                                 
      adc_2_wide_data            : out std_logic_vector(31 downto 0);  
      adc_2_wide_data_valid      : out std_logic;                                                                                                  
                                 
      adc_3_wide_data            : out std_logic_vector(31 downto 0);  
      adc_3_wide_data_valid      : out std_logic;                                                                                               
                                                                         
      adc_4_wide_data            : out std_logic_vector(31 downto 0);  
      adc_4_wide_data_valid      : out std_logic;                                                                                                                                                                        
                                                                                    
      adc_5_wide_data            : out std_logic_vector(31 downto 0);  
      adc_5_wide_data_valid      : out std_logic;                                                                                                   
                                 
      adc_6_wide_data            : out std_logic_vector(31 downto 0);  
      adc_6_wide_data_valid      : out std_logic;                                                                                                    
                                 
      adc_7_wide_data            : out std_logic_vector(31 downto 0);  
      adc_7_wide_data_valid      : out std_logic;                                                                                          
                                                                        
      adc_8_wide_data            : out std_logic_vector(31 downto 0);  
      adc_8_wide_data_valid      : out std_logic;                                                                                                                                                                    
                                                                                    
      adc_9_wide_data            : out std_logic_vector(31 downto 0);  
      adc_9_wide_data_valid      : out std_logic;                                                                                                
                                 
      adc_10_wide_data           : out std_logic_vector(31 downto 0);  
      adc_10_wide_data_valid     : out std_logic;                                                                                                 
                                 
      adc_11_wide_data           : out std_logic_vector(31 downto 0);  
      adc_11_wide_data_valid     : out std_logic                                                                                             
                   
   );
   
end entity jesd_12_chan_if;      
      
architecture rtl of jesd_12_chan_if is     

-- Components 
component jesd204b_core is
    port (
        pma_cu_clk                     : in  std_logic                     := 'X';             -- clk
        pll_refclk                     : in  std_logic                     := 'X';             -- clk
        src_sss_grant                  : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- src_rs_grant
        src_sss_req                    : out std_logic_vector(1 downto 0);                     -- src_rs_req
        o_refclk_bus_out               : out std_logic; 
        jesd204_rx_rst_n               : in  std_logic                     := 'X';             -- reset_n
        
        rx_serial_data                 : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
        rx_serial_data_n               : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
        rxphy_clk                      : out std_logic_vector(1 downto 0);                     -- export
        jesd204_rx_rst_ack_n           : out std_logic;                                        -- export
        rx_locked_to_data              : out std_logic_vector(1 downto 0);                     -- rx_locked_to_data
        
        jesd204_rx_out_of_reset        : out std_logic;                                        -- export
        
        jesd204_rx_avs_chipselect      : in  std_logic                     := 'X';             -- chipselect
        jesd204_rx_avs_address         : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- address
        jesd204_rx_avs_read            : in  std_logic                     := 'X';             -- read
        jesd204_rx_avs_readdata        : out std_logic_vector(31 downto 0);                    -- readdata
        jesd204_rx_avs_waitrequest     : out std_logic;                                        -- waitrequest
        jesd204_rx_avs_write           : in  std_logic                     := 'X';             -- write
        jesd204_rx_avs_writedata       : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        
        jesd204_rx_int                 : out std_logic;                                        -- irq
        
        jesd204_rx_link_data           : out std_logic_vector(63 downto 0);                    -- data
        jesd204_rx_link_valid          : out std_logic;                                        -- valid
        jesd204_rx_link_ready          : in  std_logic                     := 'X';             -- ready
        jesd204_rx_dev_sync_n          : out std_logic;                                        -- export
        
        jesd204_rx_sysref              : in  std_logic                     := 'X';             -- export
        jesd204_rx_somf                : out std_logic_vector(3 downto 0);                     -- export
        jesd204_rx_csr_hd              : out std_logic;                                        -- export
        jesd204_rx_csr_cs              : out std_logic_vector(1 downto 0);                     -- export
        jesd204_rx_csr_l               : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_k               : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_n               : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_np              : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_s               : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_cf              : out std_logic_vector(4 downto 0);                     -- export
        jesd204_rx_csr_f               : out std_logic_vector(7 downto 0);                     -- export
        jesd204_rx_csr_m               : out std_logic_vector(7 downto 0);                     -- export
        jesd204_rx_alldev_lane_aligned : in  std_logic                     := 'X';             -- export
        jesd204_rx_dev_lane_aligned    : out std_logic;                                        -- export
        jesd204_rx_sof                 : out std_logic_vector(3 downto 0);                     -- export
        jesd204_rx_frame_error         : in  std_logic                     := 'X';             -- export
        csr_rx_testmode                : out std_logic_vector(3 downto 0);                     -- export
        jesd204_rx_dlb_data            : in  std_logic_vector(63 downto 0) := (others => 'X'); -- export
        jesd204_rx_dlb_data_valid      : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
        jesd204_rx_dlb_kchar_data      : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
        jesd204_rx_dlb_errdetect       : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
        jesd204_rx_dlb_disperr         : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
        jesd204_rx_avs_rst_n           : in  std_logic                     := 'X';             -- reset_n
        jesd204_rx_avs_clk             : in  std_logic                     := 'X';             -- clk
        rxlink_clk                     : in  std_logic                     := 'X'              -- clk
    );
end component jesd204b_core;

component jesd_gts_reset_sequencer is
    port (
        o_src_rs_grant               : out std_logic_vector(11 downto 0);                    -- src_rs_grant
        i_src_rs_priority            : in  std_logic_vector(11 downto 0) := (others => 'X'); -- src_rs_priority
        i_src_rs_req                 : in  std_logic_vector(11 downto 0) := (others => 'X'); -- src_rs_req
        o_pma_cu_clk                 : out std_logic_vector(2 downto 0);                     -- clk
        i_refclk_bus_out             : in  std_logic; 
        o_shoreline_refclk_fail_stat : out std_logic 
        
    );
end component jesd_gts_reset_sequencer;

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


-- Constants

-- Types 


-- Signals

signal all_ones                   : std_logic_vector(31 downto 0);
signal all_zeros                  : std_logic_vector(31 downto 0);

signal reset_grant                : std_logic_vector(11 downto 0);
signal reset_priority             : std_logic_vector(11 downto 0);
signal reset_req                  : std_logic_vector(11 downto 0);
signal reset_pma_cu_clk           : std_logic_vector(2 downto 0); -- one per xcvr bank
signal pma_cu_clk                 : std_logic_vector(5 downto 0); -- JESD modules in same bank share so (0)=(1),2=3, 4=5 
                                  
type adc_wide_data_type           is array (0 to 11) of std_logic_vector(31 downto 0);
signal adc_wide_data              : adc_wide_data_type;
signal adc_wide_data_valid        : std_logic_vector(11 downto 0);                    
signal adc_wide_data_ready        : std_logic_vector(11 downto 0);                    
                                  
signal pll_refclk                 : std_logic_vector(5 downto 0);  -- JESD modules in same bank share so (0)=(1),2=3, 4=5 
                                  
signal jesd204_rx_sysref          : std_logic_vector(5 downto 0);  -- JESD modules in same bank share so (0)=(1),2=3, 4=5 
   
signal o_refclk_bus_out           : std_logic_vector(5 downto 0);
                               
signal avs_chipselects            : std_logic_vector(7 downto 0);  -- needed to decode up to 6 so needed to be this wide 
                                                             -- 7 and 6 will be unused
     
type avs_readdata_core_type       is array (0 to 5) of std_logic_vector(31 downto 0);                   
signal avs_readdata_core          : avs_readdata_core_type;
signal avs_waitrequest_core       : std_logic_vector(5 downto 0); 
                                  
signal rx_rst_n_core              : std_logic_vector(5 downto 0);
signal rx_rst_ack_n_core          : std_logic_vector(5 downto 0);
signal rx_out_of_reset_core       : std_logic_vector(5 downto 0);

signal jesd204_rx_dev_sync_n_core : std_logic_vector(5 downto 0);
                               
signal rx_locked_to_data_core     : std_logic_vector(11 downto 0); 
signal rx_phyclk_test				 : std_logic_vector(5 downto 0);


type rx_link_data_type            is array (0 to 5) of std_logic_vector(63 downto 0);
signal rx_link_data_core          : rx_link_data_type;
signal rx_link_valid_core         : std_logic_vector(5 downto 0);  
signal rx_link_ready_core         : std_logic_vector(5 downto 0);

signal alldev_lane_aligned_core   : std_logic_vector(5 downto 0);
signal dev_lane_aligned_core      : std_logic_vector(5 downto 0);
signal dev_lane_aligned_core_sync : std_logic_vector(5 downto 0);
signal dev_lane_aligned_core_mf   : std_logic_vector(5 downto 0);

signal syspll_clk_gts_pll_ref		 : std_logic_vector(2 downto 0);
signal gts_pll_ref_locked			 : std_logic_vector(2 downto 0);

signal fifo_wr_en                      : std_logic_vector(5 downto 0);                               
signal fifo_wr_data                    : rx_link_data_type; 
signal fifo_wr_full                    : std_logic_vector(5 downto 0);                                     
                                                                                                                
signal fifo_rd_en                      : std_logic_vector(5 downto 0);                                     
signal fifo_rd_data                    : rx_link_data_type;   
signal fifo_rd_empty                   : std_logic_vector(5 downto 0);                                      
signal fifo_rd_data_valid              : std_logic_vector(5 downto 0); -- High when read data is valid. Hand

 
begin -- rtl                           

all_ones  <= (others => '1');
all_zeros <= (others => '0');
--
-- Instantiate the reset sequancer. The is one per group of sub banks
-- one per group 6x jesd modules. So only one here
--

reset_priority <= (others => '0'); -- not used to set same for all

inst_jesd_gts_reset_sequencer : jesd_gts_reset_sequencer
    port map(
        o_src_rs_grant               => reset_grant,   
        i_src_rs_priority            => reset_priority,
        i_src_rs_req                 => reset_req,     
        o_pma_cu_clk                 => reset_pma_cu_clk,
        i_refclk_bus_out             => o_refclk_bus_out(0), --only need from one in the group
        o_shoreline_refclk_fail_stat => open        
    );
	 
pma_cu_clk <= reset_pma_cu_clk(2) & reset_pma_cu_clk(2) &
              reset_pma_cu_clk(1) & reset_pma_cu_clk(1) &
              reset_pma_cu_clk(0) & reset_pma_cu_clk(0);
    
pll_refclk <= clk_gts_pll_ref(2) & clk_gts_pll_ref(2) &               
              clk_gts_pll_ref(1) & clk_gts_pll_ref(1) &
				  clk_gts_pll_ref(0) & clk_gts_pll_ref(0); 
				  
--pll_refclk <= syspll_clk_gts_pll_ref(2) & syspll_clk_gts_pll_ref(2) &               
--              syspll_clk_gts_pll_ref(1) & syspll_clk_gts_pll_ref(1) &
--              syspll_clk_gts_pll_ref(0) & syspll_clk_gts_pll_ref(0); 
              
jesd204_rx_sysref <= clk_sysref(2) & clk_sysref(2) &              
                     clk_sysref(1) & clk_sysref(1) &
                     clk_sysref(0) & clk_sysref(0); 
         
                     
--
-- Decode the discrete chip selects based on the upper order address bits.
--    
 
process(avs_chipselect,avs_select)  
variable avs_chipselects_var : std_logic_vector(7 downto 0);                   
begin

  avs_chipselects_var := (others => '0');
  if avs_chipselect = '1' then
     -- simple check for out of range so will force access to 0 to not lockup bus
     if conv_integer('0'&avs_select) > 5 then
        avs_chipselects_var(0):= '1';   
     else   
       avs_chipselects_var(conv_integer('0'&avs_select)) := '1';
     end if;
  end if;                                  
  avs_chipselects <= avs_chipselects_var;            
end process;   
--
-- Decode which avl bus to send back to the bus
--
avs_readdata    <= avs_readdata_core(conv_integer('0'&avs_select))    when conv_integer('0'&avs_select) <= 5 else avs_readdata_core(0);   
avs_waitrequest <= avs_waitrequest_core(conv_integer('0'&avs_select)) when conv_integer('0'&avs_select) <= 5 else avs_waitrequest_core(0);

-- Map these to intermediates in case needing acccess at this level        
rx_rst_n_core   <= rx_rst_n;            
rx_rst_ack_n    <= rx_rst_ack_n_core;    
rx_out_of_reset <= rx_out_of_reset_core;

-- Send this to higher layers to read if needed
adc_lane_locked_to_data  <= rx_locked_to_data_core;

-- To align all of these drive 0s until all the dev_lane_aligned_core() bits are '1' plus the 
-- signal from the other jesd 12 core says aligned too. Can only really do the latter if everone 
alldev_lane_aligned_core <= (others => '0') when dev_lane_aligned_core /= all_ones(5 downto 0) or dev_lanes_aligned_from_ext /= '1' else (others => '1');    
-- Send to other jesd 12 module to allow sycn across both. Todo: do frame/link clocks for both modules need to common for this to work 
dev_lanes_aligned_to_ext <= '0' when dev_lane_aligned_core /= all_ones(5 downto 0) else '1';
-- sync driving
sync_adc_n(0) <= jesd204_rx_dev_sync_n_core(0) and jesd204_rx_dev_sync_n_core(1);
sync_adc_n(1) <= jesd204_rx_dev_sync_n_core(2) and jesd204_rx_dev_sync_n_core(3);
sync_adc_n(2) <= jesd204_rx_dev_sync_n_core(4) and jesd204_rx_dev_sync_n_core(5);     
--
-- There are two JESD cores per bank.
-- Each JESD core supports 2 ADC channels. 
-- Using 3 banks we get : 3 banks * 2 JESD core per bank * 2 ADC lanes per core = 12 ADC lanes
-- This loops thrugh the instantiation of the 6 JESD cores.
--
gen_jesd_cores : for i in 0 to 5 generate
                                                                                
inst_jesd204b_core : jesd204b_core                                           
    port map(     
                                                                                       
        pma_cu_clk                     => pma_cu_clk(i),
        pll_refclk                     => pll_refclk(i),
        jesd204_rx_sysref              => jesd204_rx_sysref(i),
        
        o_refclk_bus_out               => o_refclk_bus_out(i),
                                                                                                   
        src_sss_grant                  => reset_grant((i+1)*2-1 downto i*2),                  
        src_sss_req                    => reset_req  ((i+1)*2-1 downto i*2),                     
                                                                                                    
        rx_serial_data                 => rx_adc_ser_data_p((i+1)*2-1 downto i*2),          
        rx_serial_data_n               => rx_adc_ser_data_n((i+1)*2-1 downto i*2),          
                                                                                                   
        jesd204_rx_rst_n               => rx_rst_n_core(i),       
        jesd204_rx_rst_ack_n           => rx_rst_ack_n_core(i),   
        jesd204_rx_out_of_reset        => rx_out_of_reset_core(i),                                     
            
        jesd204_rx_dev_sync_n          => jesd204_rx_dev_sync_n_core(i),   -- held low when core is in reset 
                                                                          -- not sure what to do with this yet
        rxphy_clk                      => open, -- for subclass 1 this cant be used as the rxlink clk 
                                                -- however sould be the same frequency 
                                                -- : out std_logic_vector(1 downto 0);                                                   
        rx_locked_to_data              => rx_locked_to_data_core((i+1)*2-1 downto i*2),  -- todo: domain?                  
        
        jesd204_rx_avs_rst_n           => avs_rst_n,        
        jesd204_rx_avs_clk             => clk_avs,           
        jesd204_rx_avs_chipselect      => avs_chipselects(i),
        jesd204_rx_avs_address         => avs_address,
        jesd204_rx_avs_read            => avs_read,
        jesd204_rx_avs_readdata        => avs_readdata_core(i),                    
        jesd204_rx_avs_waitrequest     => avs_waitrequest_core(i),                 
        jesd204_rx_avs_write           => avs_write,
        jesd204_rx_avs_writedata       => avs_writedata,
        
        jesd204_rx_int                 => open, -- for now, todo: ?
        
        rxlink_clk                     => clk_link_lane, -- This is the clock used by this streaming interface = datarate/40
        jesd204_rx_sof                 => open, -- todo: not sure we care about this : out std_logic_vector(3 downto 0);
        jesd204_rx_frame_error         => '0',                            
        jesd204_rx_link_data           => rx_link_data_core(i), 
        jesd204_rx_link_valid          => rx_link_valid_core(i), ----- signal that toggles write to FIFO
        jesd204_rx_link_ready          => rx_link_ready_core(i),

        jesd204_rx_somf                => open, --: out std_logic_vector(3 downto 0);                 
        jesd204_rx_csr_hd              => open, --: out std_logic;                                    
        jesd204_rx_csr_cs              => open, --: out std_logic_vector(1 downto 0);                 
        jesd204_rx_csr_l               => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_k               => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_n               => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_np              => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_s               => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_cf              => open, --: out std_logic_vector(4 downto 0);                 
        jesd204_rx_csr_f               => open, --: out std_logic_vector(7 downto 0);                 
        jesd204_rx_csr_m               => open, --: out std_logic_vector(7 downto 0);  
                       
        jesd204_rx_alldev_lane_aligned => dev_lane_aligned_core(i), --alldev_lane_aligned_core(i),         
        jesd204_rx_dev_lane_aligned    => dev_lane_aligned_core(i),    -- used to align all cores
 
        csr_rx_testmode                => open, -- todo: : out std_logic_vector(3 downto 0);                 
        
        -- Loopback
        jesd204_rx_dlb_data            => (others=>'0'), --X"FFEEDDCCBBAA9988",        -- : in  std_logic_vector(63 downto 0)
        jesd204_rx_dlb_data_valid      => "00" , --  for now. Possibly hook up to drive for tesitng : in  std_logic_vector(1 downto 0) 
        jesd204_rx_dlb_kchar_data      => X"00", --  for now. Possibly hook up to drive for tesitng : in  std_logic_vector(7 downto 0) 
        jesd204_rx_dlb_errdetect       => X"00", --  for now. Possibly hook up to drive for tesitng : in  std_logic_vector(7 downto 0) 
        jesd204_rx_dlb_disperr         => X"00"  --  for now. Possibly hook up to drive for tesitng : in  std_logic_vector(7 downto 0) 
        
    );


end generate gen_jesd_cores;

--
-- Ouptut FIFO to get this module and the other jesd 12 chan if module's output
-- align. Treat clk_link_lane and clk_wide as async but they are not. They are just
-- possibly shifted by up to one clock. since different PLLs can be repsonsible 
-- depending on getting clarification on if the same core PLL can be used for all 6
-- banks for the frame/link clock source. If they are all the same then
-- everthing will be fully aligned and this fifo wont hurt either 
-- 

-- not clear what clock this is in so just sync the vector.
-- used to control writes to the FIFOs
process(clk_link_lane)
begin
   if clk_link_lane'event and clk_link_lane = '1' then
      dev_lane_aligned_core_mf   <= dev_lane_aligned_core;
      dev_lane_aligned_core_sync <= dev_lane_aligned_core_mf;
   end if;
end process;

--fifo_wr_en         <= rx_link_valid_core when dev_lane_aligned_core_sync = all_ones(5 downto 0) and fifo_wr_full = all_zeros(5 downto 0) else (others => '0');  
fifo_wr_en         <= rx_link_valid_core when fifo_wr_full = all_zeros(5 downto 0) else (others => '0');  
fifo_wr_data       <= rx_link_data_core;      
rx_link_ready_core <= not fifo_wr_full;                              

gen_out_fifos : for i in 0 to 5 generate 

inst_generic_fifo_shell : generic_fifo_shell
   generic map(
      g_vendor        => "altera",
                    
      g_arst_pol      => '0',      
      g_sync          => false,     
      g_showahead     => true,    
                      
      g_use_logic     => false,                                                               
                                   
      g_wr_data_width => 64,       
      g_wr_depth      => 256,      
      g_wr_levwidth   => 9,                                    
                    
      g_rd_data_width => 64,                           
      g_rd_depth      => 256,                          
      g_rd_levwidth   => 9      
                                                                                 
      --g_uniquify      => "distributed_mem"
   )
   port map(
      
      -- Clock and reset
      arst                  => out_fifo_rst_n,      
      srst                  => '0',
      
      wr_clk                => clk_link_lane,
      wr_en                 => fifo_wr_en(i),  
      wr_data               => fifo_wr_data(i),
      wr_full               => fifo_wr_full(i),
      wr_level              => open,
      
      rd_clk                => clk_wide,     
      rd_en                 => fifo_rd_en(i),   
      rd_data               => fifo_rd_data(i), 
      rd_empty              => fifo_rd_empty(i),
      rd_level              => open,
      rd_data_valid         => fifo_rd_data_valid(i)    
  
   );

end generate gen_out_fifos;                               

-- Always read if not empty.        
fifo_rd_en <= not fifo_rd_empty;

  
-- Connect up to ports
-- Four octets are packed into a 32-bit data  
-- width per lane. The data format is big endian!!!         
-- The first octet is located at bit[31:24], followed by  
-- bit[23:16], bit[15:8], and the last octet is bit[7:0]. 
-- Lane 0 data is always located in the lower 32-bit      
-- data. If more than one lane is instantiated, lane 1 is 
-- located at bit[63:32], with the first octet position at
-- bit[63:56].                                            


          
adc_0_wide_data        <= fifo_rd_data(0)(31 downto 0); 
adc_0_wide_data_valid  <= not fifo_rd_empty(0);
                    
adc_1_wide_data        <= fifo_rd_data(0)(63 downto 32); 
adc_1_wide_data_valid  <= not fifo_rd_empty(0);
                      
adc_2_wide_data        <= fifo_rd_data(1)(31 downto 0); 
adc_2_wide_data_valid  <= not fifo_rd_empty(1);             
                                                        
adc_3_wide_data        <= fifo_rd_data(1)(63 downto 32);
adc_3_wide_data_valid  <= not fifo_rd_empty(1);             
                      
adc_4_wide_data        <= fifo_rd_data(2)(31 downto 0); 
adc_4_wide_data_valid  <= not fifo_rd_empty(2);             
                                                        
adc_5_wide_data        <= fifo_rd_data(2)(63 downto 32);
adc_5_wide_data_valid  <= not fifo_rd_empty(2);             
                      
adc_6_wide_data        <= fifo_rd_data(3)(31 downto 0); 
adc_6_wide_data_valid  <= not fifo_rd_empty(3);             
                                                        
adc_7_wide_data        <= fifo_rd_data(3)(63 downto 32);
adc_7_wide_data_valid  <= not fifo_rd_empty(3);             
                      
adc_8_wide_data        <= fifo_rd_data(4)(31 downto 0); 
adc_8_wide_data_valid  <= not fifo_rd_empty(4);             
                                                        
adc_9_wide_data        <= fifo_rd_data(4)(63 downto 32);
adc_9_wide_data_valid  <= not fifo_rd_empty(4);             
                      
adc_10_wide_data       <= fifo_rd_data(5)(31 downto 0); 
adc_10_wide_data_valid <= not fifo_rd_empty(5);             
                                                        
adc_11_wide_data       <= fifo_rd_data(5)(63 downto 32);
adc_11_wide_data_valid <= not fifo_rd_empty(5);             



                                               
end rtl;                                                         
                                                            
                                                           
                                                             
                                                                         
                                                       
                                                       
                                                       
                                                       