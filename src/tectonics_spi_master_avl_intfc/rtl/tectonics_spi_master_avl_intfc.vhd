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
--*   Description: This file implements an Avalon interface for the SPI
--*                master core.
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
                                                                          
library work;                                                             
use work.tectonics_spi_master_avl_intfc_pkg.all;                                                                                                             

entity tectonics_spi_master_avl_intfc is
   generic(
      g_spi_module_rev               : std_logic_vector(15 downto 0) := X"0003";    -- revision, shows up on the rev reg reads   
      g_arst_pol                     : std_logic := '1';         -- default to '1' sets internal reset polarity            
      g_delay_miso_samp_val          : natural range 0 to 2 := 0 -- Shift samp MISO point by this many extra clocks, 1 or 2
                                                                 -- For very slow devices.
      
   );

   port(
      
      -- Clock and reset
      arst                     : in   std_logic;  -- Module async reset                                                                             
      clk                      : in   std_logic;  -- Module memory bus interface clock
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            : out  std_logic;  
      avl_slave_waitrequest    : out  std_logic;                
      avl_slave_address        : in   std_logic_vector(7 downto 0); -- 32-bit word address 
      avl_slave_chipselect     : in   std_logic;
      avl_slave_write          : in   std_logic;
      avl_slave_writedata      : in   std_logic_vector(31 downto 0);  
      avl_slave_read           : in   std_logic;
      avl_slave_readdata       : out  std_logic_vector(31 downto 0);
      avl_slave_readdatavalid  : out  std_logic;
                                                                            
      
      -- SPI pin interface
      -- SPI interface
      spi_sclk             : out std_logic;
      spi_ss_n             : out std_logic;
      spi_mosi             : out std_logic;
      spi_miso             : in  std_logic                 
      
   );

end entity tectonics_spi_master_avl_intfc;


architecture rtl of tectonics_spi_master_avl_intfc is

-- Components

component tectonics_spi_master_core is
   generic(
      g_arst_pol                  : std_logic := '1';            -- Default to '1' sets internal reset polarity
      g_delay_miso_samp_val       : natural range 0 to 2 := 0    -- Shift samp MISO point by this many extra clocks, 1 or 2
                                                                 -- For very slow devices.
   );

   port(
      
      -- Clock and reset
      arst                 : in  std_logic;                    -- Module async reset
      clk                  : in  std_logic;                    -- Module clock, fastest SPI clock rate is 1/2 clk  

      -- Local Interface
      spi_clk_pol          : in  std_logic;                    -- '1' = Output SPI clock has rising  edge in center of spi_mosi bit period
                                                               -- '0' = Output SPI clock has falling edge in center of spi_mosi bit period
      
      miso_samp_clk_edge   : in  std_logic;                    -- '1' = If spi_clk_pol = '1' then sample MISO on rising  edge of spi clk in center of bit period
                                                               --       If spi_clk_pol = '0' then sample MISO on falling edge of spi clk in center of bit period
                                                               -- '0' = If spi_clk_pol = '1' then sample MISO on falling edge of spi clk at end of bit period
                                                               --       If spi_clk_pol = '0' then sample MISO on rising  edge of spi clk at end of bit period
                                                               
                                                               -- Another way to look at miso_samp_clk_edge is that if '1' then sample in center of bit period, else, at end. 
                                                               -- And spi_clk_pol is just the clock polarity setitng for the bit period. 
                                                               --
                                                               --  If spi_clk_pol = '0':
                                                               --     miso_samp_clk_edge = '0' means sample MISO on rising  edge of spi clk at end of bit period
                                                               --     miso_samp_clk_edge = '1' means sample MISO on falling edge of spi clk in center of bit period
                                                               -- 
                                                               --  If spi_clk_pol = '1':
                                                               --     miso_samp_clk_edge = '0' means sample MISO on falling edge of spi clk at end of bit period
                                                               --     miso_samp_clk_edge = '1' means sample MISO on rising  edge of spi clk in center of bit period
                                                               -- 
                                                                
                                                                                                                             
 
                                                               
      pace                 : in  std_logic_vector(3 downto 0); -- Used to pace the serial rate, bigger results in a slower spi_clk.
                                                               -- So the 
                                                               -- 0 = clk/2 pace_factor = 2
                                                               -- 1 = clk/4 pace_factor = 4
                                                               -- 2 = clk/6
                                                               -- 3 = clk/8          
                                                               -- 4 = clk/10
                                                               -- 5 = clk/16
                                                               -- 6 = clk/18
                                                               -- 7 = clk/20
                                                               -- others = clk/20 pace_factor = 22
                                                               
      ss_to_clk_gap        : in std_logic_vector(3 downto 0):= "0001";  -- 0 = ~1.5 SPI clocks 
                                                                        -- 1 = 30 SPI clocks
      clk_to_ss_gap        : in std_logic_vector(3 downto 0):= "0001";  -- 0 = ~1.5 SPI clocks                                                                   
                                                                        -- 1 = 60 SPI clocks                                                                     
      
      delay_enb            : in std_logic;                    -- If '1' then insert delay as defined below.
      delay_byte_pos       : in std_logic_vector(7 downto 0); -- After this byte (1 based) add a delay in the transfer to allow external device to have time to fetch data
                                                              -- If 0, then will insert delay after each byte
      delay_time_spi_clks  : in std_logic_vector(9 downto 0); -- Number of clocks (1 based) to delay after the delay byte before continuing with remaining bytes  
                                                              -- So delay would be 
                                                              
                                                              -- clk/pace_factor * delay_time_spi_clks.
      tx_lsb_first         : in std_logic;                    -- '1' = lsb first for each byte. '0' = msb first.                                                                
      rx_lsb_first         : in std_logic;                    -- '1' = lsb first for each byte. '0' = msb first.                                                                
                                                              
                                                                                                                                                      
      spi_tx_msg_rdy       : in  std_logic;                    -- There is a message in the external message queue if this is '1';
      spi_tx_msg_len       : in  std_logic_vector(9 downto 0); -- One based 1024 max (0=1024)
      spi_tx_msg_sent_pls  : out std_logic;                    -- Fired after the message is sent, this should be used by the external msg length manager to advance to the next 
                                                               -- MSG length value. So if there is a fifo out there for this then it is a look ahead type...                                                              
      
      spi_tx_msg_rd_ack    : out std_logic;                    -- 1 clk wide pulse that acks the data from the external message queue. Its an ack so
      spi_tx_msg_data      : in  std_logic_vector(7 downto 0); -- data is expected to stay stable until spi_tx_msg_rd_ack is pulsed (i.e. a look ahead FIFO rather than a request FIFO) 
                                                               -- Else its the data for the message that follows in bytes. Max message is 256 bytes (mesage length of 0 = 256 bytes)
      
      spi_rx_msg_wr_ack    : out std_logic;                     -- 1 clk wide pulse indicating that a data byte from the external device is valid. Pulses once per byte received.
                                                                -- Data byte on spi_rx_msg_data() is valid and new when this pulses '1'.
      spi_rx_msg_data      : out  std_logic_vector(7 downto 0); -- Data only valid spi_rx_msg_wr_ack is pulsed. External device needs to store the byte when this pulses
      
                                                               
                                                               
      -- SPI interface
      spi_sclk             : out std_logic;
      spi_ss_n             : out std_logic;                                                                 
      spi_mosi             : out std_logic;
      spi_miso             : in  std_logic                      
                                                                                                                                                  
   );

end component tectonics_spi_master_core;

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
                                                                                                                                                           
end component generic_fifo_shell;                                                                                         
                                                                                                                           
-- Constants                                                                                                                                      
                                                                                                                       
                                                                                                                              
-- Types, subtypes                                                                                                             
                                                                                                                                                                                                                                                    
                                                                                                                      
-- Signals                                                                                                            
   signal all_zeros                      : std_logic_vector(31 downto 0);                                             
                                                                                                                      
   signal wr_strb_bus                    : std_logic_vector(c_num_of_regs-1 downto 0);                                
   --signal rd_strb_bus                  : std_logic_vector(c_num_of_regs-1 downto 0);
                                                                                                                       
   signal spi_irq_enb_reg                : std_logic_vector(7 downto 0);
   signal spi_irq_stat_reg               : std_logic_vector(7 downto 0);
   
   signal spi_settings_0_reg             : std_logic_vector(31 downto 0); 
   signal spi_settings_1_reg             : std_logic_vector(31 downto 0);
   signal spi_ctrl_reg                   : std_logic_vector(31 downto 0); 
   signal spi_stat_reg                   : std_logic_vector(31 downto 0);
   signal spi_action_reg                 : std_logic_vector(31 downto 0);
                                                                                                                                                                
   signal avl_slave_readdatavalid_sig    : std_logic;
   signal avl_slave_readdata_sig         : std_logic_vector(31 downto 0);
   
   signal tx_fifo_arst                   : std_logic;                                                           
   signal tx_fifo_srst                   : std_logic;  
                                                       
   signal tx_fifo_wr_en                  : std_logic;                                           
   signal tx_fifo_wr_data                : std_logic_vector(7 downto 0);        
   signal tx_fifo_wr_full                : std_logic;                                           
   signal tx_fifo_wr_level               : std_logic_vector(10 downto 0);          
                                                                                             
   signal tx_fifo_rd_en                  : std_logic;                                           
   signal tx_fifo_rd_data                : std_logic_vector(7 downto 0);        
   signal tx_fifo_rd_empty               : std_logic;                                           
   signal tx_fifo_rd_level               : std_logic_vector(10 downto 0);          
   signal tx_fifo_rd_data_valid          : std_logic;
                                       
   signal rx_fifo_arst                   : std_logic;                                                           
   signal rx_fifo_srst                   : std_logic;  
                                                       
   signal rx_fifo_wr_en                  : std_logic;                                           
   signal rx_fifo_wr_data                : std_logic_vector(7 downto 0);        
   signal rx_fifo_wr_full                : std_logic;                                           
   signal rx_fifo_wr_level               : std_logic_vector(10 downto 0);          
                                                                                             
   signal rx_fifo_rd_en                  : std_logic;                                           
   signal rx_fifo_rd_data                : std_logic_vector(7 downto 0);        
   signal rx_fifo_rd_empty               : std_logic;                                           
   signal rx_fifo_rd_level               : std_logic_vector(10 downto 0);          
   signal rx_fifo_rd_data_valid          : std_logic;
   
   -- Spi settings register signals   
   signal spi_clk_pol                    : std_logic;                          
   signal miso_samp_clk_edge             : std_logic;                          
   signal pace                           : std_logic_vector(3 downto 0);                                                                                                                                                                                                                            
   signal ss_to_clk_gap                  : std_logic_vector(3 downto 0);                                                                                                   
   signal clk_to_ss_gap                  : std_logic_vector(3 downto 0);                                                                                                                                                                                       
   signal delay_enb                      : std_logic;                    
   signal delay_byte_pos                 : std_logic_vector(7 downto 0);                                                               
   signal delay_time_spi_clks            : std_logic_vector(9 downto 0);                                                                                                                           
   signal tx_lsb_first                   : std_logic;                    
   signal rx_lsb_first                   : std_logic;                       
   
   -- SPI data/message transfer signals
   signal spi_tx_msg_rdy                 : std_logic;                       
   signal spi_tx_msg_len                 : std_logic_vector(9 downto 0);    
   signal spi_tx_msg_sent_pls            : std_logic;                       
                                                                 
   signal spi_tx_msg_rd_ack              : std_logic;                       
   signal spi_tx_msg_data                : std_logic_vector(7 downto 0);                                                                 
                                                                   
   signal spi_rx_msg_wr_ack              : std_logic;                    
   signal spi_rx_msg_data                : std_logic_vector(7 downto 0);                                                                                    
                                                                                       
                                                                                                                                                                              
begin                                                                                      
--                                                                                               
-- Convienent static level signals                                                               
--
all_zeros <= (others => '0');

avl_slave_waitrequest <= '0'; -- all accesses are 0 WS for the requests and can be back to back

--
-- Generate the write strobes for the setup and control registers
-- written to at the system interface clock rate
--
process(avl_slave_address, avl_slave_write, avl_slave_chipselect)
   variable wr_strb_bus_var : std_logic_vector(wr_strb_bus'range);
begin
   wr_strb_bus_var := (others => '0'); -- preset the variable to all '0's                      
   if avl_slave_write = '1' and avl_slave_chipselect = '1' then                                           
      for i in 0 to c_num_of_regs-1 loop      
         if conv_integer('0'&avl_slave_address) = i then
            wr_strb_bus_var(i) := '1';
         end if;  
      end loop;
   end if;
   wr_strb_bus <= wr_strb_bus_var; 
end process;

--
-- Generate the write register process to manage the writing to all control/setup registers
--       

                                                                                   
process(clk,arst)                                                                           

begin
   if arst = g_arst_pol then    
     
      spi_irq_enb_reg                  <= (others => '0');                                     
      spi_settings_0_reg               <= (others => '0');
      spi_settings_1_reg               <= (others => '0');
      
      spi_settings_0_reg(r_spi_clk_pol_range_type        ) <= "1";    -- Spi clock has pos edge in center of bit period                                                                                
      spi_settings_0_reg(r_miso_samp_clk_edge_range_type ) <= "1";    -- Sample MISO in center of bit period     
      spi_settings_0_reg(r_pace_range_type               ) <= "0001"; -- SPI clock is CLK/4                                           
      spi_settings_0_reg(r_ss_to_clk_gap_range_type      ) <= "0000";                                                                 
      spi_settings_0_reg(r_clk_to_ss_gap_range_type      ) <= "0000";                                                                 
      spi_settings_0_reg(r_delay_enb_range_type          ) <= "0";                                                                                       
      spi_settings_0_reg(r_delay_byte_pos_range_type     ) <= (others => '0');                                                         
      spi_settings_1_reg(r_delay_time_spi_clks_range_type) <= (others => '0');                                                            
      spi_settings_0_reg(r_tx_lsb_first_range_type       ) <= "0";                                                                                       
      spi_settings_0_reg(r_rx_lsb_first_range_type       ) <= "0";                                                                                                                                                      

            
      spi_ctrl_reg                     <= (others => '0');                                                                                   
      spi_action_reg                   <= (others => '0');
      
      tx_fifo_wr_en                    <= '0';
      tx_fifo_wr_data                  <= (others => '0');
      
      
      
   elsif clk'event and clk = '1' then
                                                                                                                             
      if wr_strb_bus(c_spi_irq_enb_reg_addr)        = '1'  then spi_irq_enb_reg     <= avl_slave_writedata(spi_irq_enb_reg'length -1 downto 0);       end if;
      if wr_strb_bus(c_spi_settings_0_reg_addr)     = '1'  then spi_settings_0_reg  <= avl_slave_writedata(spi_settings_0_reg'length -1 downto 0);   end if;
      if wr_strb_bus(c_spi_settings_1_reg_addr)     = '1'  then spi_settings_1_reg  <= avl_slave_writedata(spi_settings_1_reg'length -1 downto 0);   end if;
      
      spi_ctrl_reg(0) <= '0'; -- TX FIFO sync reset, self clear, after reset wait until the FIFOs say empty before proceeding
      spi_ctrl_reg(1) <= '0'; -- RX FIFO sync reset, self clear, after reset wait until the FIFOs say empty before proceeding
      if wr_strb_bus(c_spi_ctrl_reg_addr)           = '1'  then spi_ctrl_reg       <= avl_slave_writedata(spi_ctrl_reg'length -1 downto 0);          end if;
           
      -- SPI action register is used to sett he transaction 
      if wr_strb_bus(c_spi_action_reg_addr)         = '1'  then 
         spi_action_reg <= avl_slave_writedata(spi_action_reg'length -1 downto 0);           
      elsif spi_tx_msg_sent_pls = '1' then  -- Clear the spi_tx_msg_rdy when the module finish sending the TX message    
         spi_action_reg(0) <= '0';          -- Bit 0 is set to indicate that a new TX master SPI messsage is in the TX FIFO and ready to be sent  
                                            -- SW can read this to make sure last message was sent before sending another  
      end if;
      
      
      -- Manage writing to the TX FIFO
      tx_fifo_wr_en <= '0';
      if wr_strb_bus(c_spi_tx_fifo_data_reg_addr) = '1' then
         tx_fifo_wr_en   <= '1';     
         tx_fifo_wr_data <= avl_slave_writedata(7 downto 0);
      end if;
      
      
   end if;
end process; 

spi_stat_reg <= (others => '0'); -- for now

-- Control register mappings
tx_fifo_srst <= spi_ctrl_reg(0);
rx_fifo_srst <= spi_ctrl_reg(1);

-- Action register mappings
spi_tx_msg_rdy <= spi_action_reg(0); -- cleared when spi_tx_msg_sent_pls = '1'
spi_tx_msg_len <= spi_action_reg(25 downto 16);    



-- Assignments form the settings register
spi_clk_pol          <= spi_settings_0_reg(r_spi_clk_pol_range_type        )(r_spi_clk_pol_range_type'low);
miso_samp_clk_edge   <= spi_settings_0_reg(r_miso_samp_clk_edge_range_type )(r_miso_samp_clk_edge_range_type'low);
pace                 <= spi_settings_0_reg(r_pace_range_type               );
ss_to_clk_gap        <= spi_settings_0_reg(r_ss_to_clk_gap_range_type      );
clk_to_ss_gap        <= spi_settings_0_reg(r_clk_to_ss_gap_range_type      );
delay_enb            <= spi_settings_0_reg(r_delay_enb_range_type          )(r_delay_enb_range_type'low);
delay_byte_pos       <= spi_settings_0_reg(r_delay_byte_pos_range_type     );
tx_lsb_first         <= spi_settings_0_reg(r_tx_lsb_first_range_type       )(r_tx_lsb_first_range_type'low);
rx_lsb_first         <= spi_settings_0_reg(r_rx_lsb_first_range_type       )(r_rx_lsb_first_range_type'low);

delay_time_spi_clks  <= spi_settings_1_reg(r_delay_time_spi_clks_range_type);


spi_irq_stat_reg   <= (others => '0'); -- tie off for now.
avl_slave_irq  <= '1' when (spi_irq_stat_reg and spi_irq_enb_reg) /= all_zeros(spi_irq_stat_reg'left downto 0) else '0';  
                                
--                                                                                                        
-- Generate the read mux for the control and status registers, 1 cycle latency                                             
--                                                                                                    
process(clk,arst)                                                                                    
begin                                                                                                                   
   if arst = g_arst_pol then                                                                  
                                                                                              
      avl_slave_readdatavalid_sig <= '0';                                                     
      avl_slave_readdata_sig       <= (others => '0');                                        
   elsif clk'event and clk = '1' then                                                         
                                                                                               
      avl_slave_readdatavalid_sig <= '0';                                                     
      avl_slave_readdata_sig      <= (others => '0');                                   
      
      if avl_slave_chipselect = '1' and avl_slave_read = '1' then
         avl_slave_readdatavalid_sig <= '1';
         
         case conv_integer('0'&avl_slave_address) is                     
           
           when c_spi_rev_reg_addr =>
              avl_slave_readdata_sig <= all_zeros(31 downto g_spi_module_rev'length)& g_spi_module_rev;
          
           when c_spi_irq_enb_reg_addr =>  
              avl_slave_readdata_sig <= all_zeros(31 downto spi_irq_enb_reg'length)&spi_irq_enb_reg;  
              
           when c_spi_irq_stat_reg_addr =>
              avl_slave_readdata_sig <= (others => '0'); -- todo:                            
                                        
           when c_spi_settings_0_reg_addr => 
              avl_slave_readdata_sig <= spi_settings_0_reg;
              
           when c_spi_settings_1_reg_addr => 
              avl_slave_readdata_sig <= spi_settings_1_reg;                           
              
           when c_spi_action_reg_addr =>    
              avl_slave_readdata_sig <= spi_action_reg; 
              
           when c_spi_ctrl_reg_addr =>    
              avl_slave_readdata_sig <= spi_ctrl_reg;
                                                            
           when c_spi_tx_fifo_stat_reg_addr =>              
              avl_slave_readdata_sig <= all_zeros(31 downto 16) & all_zeros(15 downto tx_fifo_wr_level'length) & tx_fifo_wr_level;
              
           when c_spi_rx_fifo_stat_reg_addr =>              
              avl_slave_readdata_sig <= all_zeros(31 downto 16) & all_zeros(15 downto rx_fifo_rd_level'length) & rx_fifo_rd_level;    
              
           when c_spi_rx_fifo_data_reg_addr => -- read formthe RX FIFO
                               
                avl_slave_readdata_sig <= all_zeros(31 downto rx_fifo_rd_data'length)&rx_fifo_rd_data;                                              
                                                                                                   
           when others =>
              avl_slave_readdata_sig <= (others => '-'); -- dont care
              
         end case; 
      end if;
   end if;                                                                                                       
end process;  
                                                                                                   
rx_fifo_rd_en <= '1' when avl_slave_chipselect = '1' and avl_slave_read = '1' and conv_integer('0'&avl_slave_address) = c_spi_rx_fifo_data_reg_addr else '0'; -- this is an ack for the lookahead FIFO  
                                                                                                                
avl_slave_readdatavalid <= avl_slave_readdatavalid_sig;                                                             
avl_slave_readdata      <= avl_slave_readdata_sig;                                                                   

--
-- Instatiate the TX data FIFO
--

tx_fifo_arst <= g_arst_pol when arst = g_arst_pol else not(g_arst_pol);



tx_fifo_rd_en   <= spi_tx_msg_rd_ack;  -- this is an ack since lookahead FIFO 
spi_tx_msg_data <= tx_fifo_rd_data;  

inst_tx_fifo : generic_fifo_shell 
   generic map(
      g_vendor        => "altera",
                      
      g_arst_pol      => g_arst_pol,      
      g_sync          => true,     
      g_showahead     => true,    
                                   
      g_use_logic     => false,    
                                                                                           
      g_wr_data_width => 8,       
      g_wr_depth      => 1024,     
      g_wr_levwidth   => 11,       
                                                       
      g_rd_data_width => 8,                    
      g_rd_depth      => 1024,                  
      g_rd_levwidth   => 11                                                                                            
   )
   port map(
      
      -- Clock and reset
      arst                  => tx_fifo_arst,     
      srst                  => tx_fifo_srst,
      
      wr_clk                => clk,
      wr_en                 => tx_fifo_wr_en,  
      wr_data               => tx_fifo_wr_data,
      wr_full               => tx_fifo_wr_full,                                                                                    
      wr_level              => tx_fifo_wr_level,                                                                      
                                                                                                                                                    
      rd_clk                => clk,                                                                                                         
      rd_en                 => tx_fifo_rd_en, -- this is an ack since lookahead FIFO                                          
      rd_data               => tx_fifo_rd_data,                                        
      rd_empty              => tx_fifo_rd_empty,                                       
      rd_level              => tx_fifo_rd_level,                                       
      rd_data_valid         => tx_fifo_rd_data_valid                                  
                                                                                                                                                  
   );                      

--
-- Instatiate the RX data FIFO
--

rx_fifo_arst <= g_arst_pol when arst = g_arst_pol else not(g_arst_pol);

rx_fifo_wr_en   <= spi_rx_msg_wr_ack;
rx_fifo_wr_data <= spi_rx_msg_data;  

inst_rx_fifo : generic_fifo_shell 
   generic map(
      g_vendor        => "altera",   
                                     
      g_arst_pol      => g_arst_pol, 
      g_sync          => true,       
      g_showahead     => true,       
                                     
      g_use_logic     => false,      
                                     
      g_wr_data_width => 8,          
      g_wr_depth      => 1024,       
      g_wr_levwidth   => 11,         
                                     
      g_rd_data_width => 8,          
      g_rd_depth      => 1024,       
      g_rd_levwidth   => 11          
                
   )

   port map(
      
      arst                  => rx_fifo_arst,              
      srst                  => rx_fifo_srst,              
                                                          
      wr_clk                => clk,                       
      wr_en                 => rx_fifo_wr_en,             
      wr_data               => rx_fifo_wr_data,           
      wr_full               => rx_fifo_wr_full,           
      wr_level              => rx_fifo_wr_level,                             
                                                                             
      rd_clk                => clk,                                          
      rd_en                 => rx_fifo_rd_en,                                                          
      rd_data               => rx_fifo_rd_data,                            
      rd_empty              => rx_fifo_rd_empty,                           
      rd_level              => rx_fifo_rd_level,                           
      rd_data_valid         => rx_fifo_rd_data_valid                       
                       
                                                                                                                                                  
   );     
   
inst_tectonics_spi_master_core : tectonics_spi_master_core 
   generic map(
      g_arst_pol             => g_arst_pol,
      g_delay_miso_samp_val  => g_delay_miso_samp_val                                                              
   )
   port map(
      
      -- Clock and reset
      arst                 => arst,
      clk                  => clk,                    -- Module clock, fastest SPI clock rate is 1/2 clk  

      -- Local Interface
      spi_clk_pol          => spi_clk_pol,        
      miso_samp_clk_edge   => miso_samp_clk_edge, 
      pace                 => pace,                   
      ss_to_clk_gap        => ss_to_clk_gap,                                                                           
      clk_to_ss_gap        => clk_to_ss_gap,                                                                                                                                                                        
      delay_enb            => delay_enb,          
      delay_byte_pos       => delay_byte_pos,                                                    
      delay_time_spi_clks  => delay_time_spi_clks,
      tx_lsb_first         => tx_lsb_first,       
      rx_lsb_first         => rx_lsb_first,       
                                                                                                                                                      
      spi_tx_msg_rdy       => spi_tx_msg_rdy,
      spi_tx_msg_len       => spi_tx_msg_len,
      spi_tx_msg_sent_pls  => spi_tx_msg_sent_pls,                                                                        
                           
      spi_tx_msg_rd_ack    => spi_tx_msg_rd_ack,
      spi_tx_msg_data      => spi_tx_msg_data,                                                       
                
      spi_rx_msg_wr_ack    => spi_rx_msg_wr_ack,                                                      
      spi_rx_msg_data      => spi_rx_msg_data,     
                                                                                                                              
      -- SPI interface
      spi_sclk             => spi_sclk,
      spi_ss_n             => spi_ss_n,
      spi_mosi             => spi_mosi,
      spi_miso             => spi_miso                     
                                                                                                                                                  
   );







               
end;  --rtl

