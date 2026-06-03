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
--*     Single use/project License. Additional use requires written permission.
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
--*   May//2013      Logic Tectonics Inc.          
--*                 
--*                                        Added FIFOs
--*                                        Added 16-bit reg address mode
--*                                        Augmented the status register reads
--*                 
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
use work.tectonics_i2c_master_avl_intfc_pkg.all;                                                                                                             

entity tectonics_i2c_master_avl_intfc is
   generic(
      g_rev                          : natural   := 5;           -- revision, shows up on the rev reg reads   
      g_arst_pol                     : std_logic := '1';         -- default to '1' sets internal reset polarity            
      g_input_clk_hz                 : integer   := 100_000_000; -- used by the I2C module to set the bit rate                                
      g_i2c_bus_clk_hz               : integer   := 400_000      -- used by the I2C module to set the bit rate
      --g_rd_stp_strt                  : boolean   := false      -- If true then insert real stop start in between 
      --                                                         -- reg address and read data phases versus just a start.
                                                                 -- Some devices reqauire this
      
   );

   port(
      
      -- Clock and reset
      arst                     : in   std_logic;  -- Module async reset
      clk                      : in   std_logic;  -- Module memory bus interface clock
      
      -- Slave control interface to setup the module and read status. All in clk domain                                            
      avl_slave_irq            : out  std_logic;          
      avl_slave_waitrequest    : out  std_logic;        
      avl_slave_address        : in   std_logic_vector(7 downto 0);  
      avl_slave_chipselect     : in   std_logic;
      avl_slave_write          : in   std_logic;
      avl_slave_writedata      : in   std_logic_vector(31 downto 0);  
      avl_slave_read           : in   std_logic;
      avl_slave_readdata       : out  std_logic_vector(31 downto 0);
      avl_slave_readdatavalid  : out  std_logic;
                                                                            
      
      -- I2C pin interface
      i2c_data_oe              : out  std_logic;
      i2c_clk_oe               : out  std_logic;
                                 
      i2c_data_in              : in   std_logic;
      i2c_clk_in               : in   std_logic      
      
   );

end entity tectonics_i2c_master_avl_intfc;


architecture rtl of tectonics_i2c_master_avl_intfc is



   
component tectonics_i2c_master_core is
  generic(
     g_arst_pol        : std_logic := '0';
     g_input_clk_hz    : integer   := 50_000_000;  --input clock speed from user logic in hz
     g_bus_clk_hz      : integer   := 400_000;     --speed the i2c bus (scl) will run at in hz
     g_assert_mstr_ack : boolean   := false        -- If true will assert master read data ack. Some devices dont like that
  );   
    
  port(
     clk                   : in     std_logic;                    -- System clock
     arst                  : in     std_logic;                    -- Async reset, polarity set by g_arst_pol
     ena_pls               : in     std_logic;                    -- latch in command and start on positive pulse (sync'd to clk), needs to be cleared
                                                                  -- before busy goes low after the transaction.                                      
     chip_addr             : in     std_logic_vector(6 downto 0); -- Chip address
     
     reg_addr_16b_enb      : in     std_logic := '1';              -- if '1' use 16 bit reg addr. If not then use low 7:0 only 
     reg_addr_msbyte_first : in     std_logic := '1';              -- if '1' and reg_addr_16b_en, send MSB first.     
     
     
     reg_addr              : in     std_logic_vector(15 downto 0); -- Register Address
     rwn                   : in     std_logic;                    -- '0' is write, '1' is read
     xfer_len              : in     std_logic_vector(9 downto 0); -- 0 based transfer length. upt o 1023 (1204)
     fast_rd               : in     std_logic;                    -- If '1' and a read, will skip writing the register address.
     rd_stp_strt           : in     std_logic;                    -- '1' = insert real stop start in between read addr and first data phase. '0' = just repeated start bit      
                           
     data_wr               : in     std_logic_vector(7 downto 0); -- Data to write to slave
     data_wr_ack           : out    std_logic;                    -- one clock wide pulse to advance the write data for multi byte transfers
                           
     busy                  : out    std_logic;                    -- indicates transaction in progress
     data_rd               : out    std_logic_vector(7 downto 0); -- Data read from slave
     data_rd_valid         : out    std_logic;                    -- Pulse one clock wide for each data value read.
                           
     ack_error             : out    std_logic;                    -- Flag if improper acknowledge from slave
                           
     --sda                 : inout  std_logic;                  -- Serial data output of i2c bus , uncomment if wanting to do tristate in this module level 
     --scl                 : inout  std_logic                   -- Serial clock output of i2c bus, uncomment if wanting to do tristate in this module level 
                           
                           
     sda                   : in   std_logic;                      -- serial data input of i2c bus 
     scl                   : in   std_logic;                      -- serial clock input of i2c bus
                           
                                                                  -- Connect at top level to open collector tristate 
                                                                  -- logic. So if these are high, drive the signal low
                                                                  -- and if these are high then drive 'Z'.
     sda_oe                : out  std_logic;                      -- Active high serial data output  enable 
     scl_oe                : out  std_logic                       -- Active high serial clock output enable 
     
  );                   
    
    
end component tectonics_i2c_master_core;   

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
                                                                             
   --signal high                           : std_logic;
   --signal low                            : std_logic;
                                                                                                     
   signal wr_strb_bus                    : std_logic_vector(c_num_of_regs-1 downto 0);                                     
   --signal rd_strb_bus                  : std_logic_vector(c_num_of_regs-1 downto 0);                                     
                                         
   --signal ctrl_reg                       : std_logic_vector(7 downto 0);                                                                                
   signal irq_enb_reg                    : std_logic_vector(7 downto 0);
   signal irq_stat_reg                   : std_logic_vector(7 downto 0);    
   signal i2c_addr_reg                   : std_logic_vector(31 downto 0);  -- rwn(7), RD = '1', WR = '0'
                                                                           -- chip_addr(6:0) 
                                                                           -- reg_addr(31:16)  
                                                                           
   --signal i2c_wr_data_reg                : std_logic_vector(31 downto 0);  -- Write data (one byte at a time)

   signal i2c_stat_ctrl_reg              : std_logic_vector(17 downto 0);  -- Write '1' to bit 0 to clear status and start transaction
                                                                           -- (0)    W1/R  = '0' idle/complete , '1' = busy    
                                                                           -- (1)    RO = ack_error  '1' = ack error
                                                                           -- (2)    RW = If '1' and a read, will skip writing the register address. 
                                                                           -- (3)    RW = rd_stp_strt, '1' = insert real stop start in between read addr and first data phase. '0' = just repeated start bit    
                                                                           -- (4)    RW = reg_addr_16b_enb     
                                                                           -- (5)    RW = reg_addr_msbyte_first
                                                                           -- (6)    RW = '1' reset fifos
                                                                                                                                             
                                                                           -- (17:8) RW = 0 based (0 = 1 byte) transfer length up to 1023 (1024).                                                                      
                                                                           
   signal i2c_busy                       : std_logic; 
   signal i2c_ack_error                  : std_logic;
                                                                                                                                                                
   signal avl_slave_readdatavalid_sig    : std_logic;
   signal avl_slave_readdata_sig         : std_logic_vector(31 downto 0);
  
   --signal quick_busy                     : std_logic;   
    
   signal i2c_ena_pls                    : std_logic;  
   
   signal xfer_len                       : std_logic_vector(9 downto 0); -- transfer size for reapeated reads for auto-incrementing
                                                                         -- capable devices                                                                                                                                                        
   signal fast_rd                        : std_logic;                    -- If '1' and a read, will skip writing the register address.  
   
   signal rd_stp_strt                    : std_logic;
   
   signal reg_addr_16b_enb               : std_logic;
   signal reg_addr_msbyte_first          : std_logic;
   
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
   
   
                                                                                                                                                                                 
begin                                                                                            
--                                                                                               
-- Convienent static level signals                                                               
--
--high      <= '1';
--low       <= '0';
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
irq_stat_reg                     <= (others => '0'); -- tie off
                                                                                   
process(clk,arst)                                                                           

begin
   if arst = g_arst_pol then    
     
      --ctrl_reg                       <= (others => '0');     
      irq_enb_reg                      <= (others => '0');
      --irq_stat_reg                   <= (others => '0');
                                       
      i2c_addr_reg                     <= (others => '0');                             
      --i2c_wr_data_reg                  <= (others => '0');
      i2c_stat_ctrl_reg                <= (others => '0');
                                                                              
      i2c_ena_pls                      <= '0';
                                       
      --quick_busy                     <= '0'; -- just for instant read of the busy     
      
      tx_fifo_wr_en                    <= '0'; 
      
   elsif clk'event and clk = '1' then
 
      --if wr_strb_bus(c_ctrl_reg_addr)     = '1'  then ctrl_reg        <= avl_slave_writedata(ctrl_reg'length-1 downto 0);          end if;                                                                                                                                     
      if wr_strb_bus(c_irq_enb_reg_addr)            = '1'  then irq_enb_reg            <= avl_slave_writedata(irq_enb_reg'length -1 downto 0);      end if;
      if wr_strb_bus(c_i2c_addr_reg_addr)           = '1'  then i2c_addr_reg           <= avl_slave_writedata(i2c_addr_reg 'length -1 downto 0);    end if;             
      
      tx_fifo_wr_en <= '0'; --self clear
      if wr_strb_bus(c_i2c_data_reg_addr)           = '1'  then         
         tx_fifo_wr_en   <= '1'; 
         tx_fifo_wr_data <= avl_slave_writedata(7 downto 0);         
      end if;
      
      i2c_ena_pls          <= '0';   -- self clearing 
      i2c_stat_ctrl_reg(0) <= '0';   -- self clearing 
      
      i2c_stat_ctrl_reg(6) <= '0'; -- self clearing reset FIFOs
      
      if wr_strb_bus(c_i2c_stat_ctrl_reg_addr)  = '1' then -- If requesting to start a transfer
         if avl_slave_writedata(0) = '1' then 
            i2c_ena_pls    <= '1';
         end if;
         i2c_stat_ctrl_reg <= avl_slave_writedata(i2c_stat_ctrl_reg'length-1 downto 0);   
      end if;  
                                                                                          
      --quick_busy <= avl_slave_chipselect and avl_slave_write;       
        
   end if;
end process; 
                      
-- Connect the i2c_stat_ctrl_reg() to the individual signals

fast_rd               <= i2c_stat_ctrl_reg(2);
rd_stp_strt           <= i2c_stat_ctrl_reg(3);

reg_addr_16b_enb      <= i2c_stat_ctrl_reg(4);
reg_addr_msbyte_first <= i2c_stat_ctrl_reg(5);

xfer_len              <= i2c_stat_ctrl_reg(17 downto 8);

avl_slave_irq   <= '1' when (irq_stat_reg and irq_enb_reg) /= all_zeros(irq_stat_reg'left downto 0) else '0';  


--
-- TX (Write) data FIFO
--

tx_fifo_arst <= g_arst_pol when arst = g_arst_pol else not(g_arst_pol);
tx_fifo_srst <= i2c_stat_ctrl_reg(6);

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
-- Instatiate the RX (read) data FIFO
--

rx_fifo_arst <= g_arst_pol when arst = g_arst_pol else not(g_arst_pol);
rx_fifo_srst <= i2c_stat_ctrl_reg(6);


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
   

                                
--                                                                                                        
-- Generate the read mux for the control and status registers, 1 cycle latency                                             
--                                                                                                    
process(clk,arst)                                                                                    
begin                                                                                                                   
   if arst = g_arst_pol then                                                                  
                                                                                              
      avl_slave_readdatavalid_sig <= '0';                                                     
      avl_slave_readdata_sig       <= (others => '0');  
      
      rx_fifo_rd_en <= '0';
                                            
   elsif clk'event and clk = '1' then                                                         
                                                                                              
      avl_slave_readdatavalid_sig <= '0';                                                     
      avl_slave_readdata_sig       <= (others => '0');  
      
      rx_fifo_rd_en <= '0'; -- only a pulse as the ack for look ahead fifo                                       
      
      if avl_slave_chipselect = '1' and avl_slave_read = '1' then
         avl_slave_readdatavalid_sig <= '1';
         
         case conv_integer('0'&avl_slave_address) is
           
           when c_rev_reg_addr =>
              avl_slave_readdata_sig <= all_zeros(31 downto 8)& conv_std_logic_vector(g_rev,8);
          
           --when c_ctrl_reg_addr => 
           --   avl_slave_readdata_sig <= all_zeros(31 downto ctrl_reg'length)&ctrl_reg;
                                          
           when c_irq_enb_reg_addr =>  
              avl_slave_readdata_sig <= all_zeros(31 downto irq_enb_reg'length)&irq_enb_reg;   
               
           when c_irq_stat_reg_addr =>                                                                                               
              avl_slave_readdata_sig <= all_zeros(31 downto irq_stat_reg'length)&irq_stat_reg;               
                                        
           when c_i2c_addr_reg_addr => 
              avl_slave_readdata_sig <= i2c_addr_reg;    --all_zeros(31 downto i2c_addr_reg'length)&
                    
           when c_i2c_data_reg_addr => 
           
              rx_fifo_rd_en <= '1';  
              avl_slave_readdata_sig <= all_zeros(15 downto rx_fifo_rd_level'length) & rx_fifo_rd_level & all_zeros(7 downto 0) & rx_fifo_rd_data;  
                    
           when c_i2c_stat_ctrl_reg_addr =>
              avl_slave_readdata_sig <= all_zeros(31 downto 18)&i2c_stat_ctrl_reg(17 downto 8)&all_zeros(7 downto 6)&i2c_stat_ctrl_reg(5 downto 2)&i2c_ack_error&i2c_busy;                          
                                                                                                   
           when others =>
              avl_slave_readdata_sig <= (others => '-'); -- dont care
              
         end case; 
      end if;
   end if;                                                                                                       
end process;                                                                                                     
 
                                                                                                                
avl_slave_readdatavalid <= avl_slave_readdatavalid_sig;                                                             
avl_slave_readdata      <= avl_slave_readdata_sig;                                                                   


--
-- Instantiate the I2C master module
--

inst_tectonics_i2c_master_core : tectonics_i2c_master_core
  generic map(
     g_arst_pol        => g_arst_pol,     
     g_input_clk_hz    => g_input_clk_hz, 
     g_bus_clk_hz      => g_i2c_bus_clk_hz,
     g_assert_mstr_ack => false   
  )   
                                          
  port map(                               
     clk                   => clk,                    
     arst                  => arst,
     ena_pls               => i2c_ena_pls,
                                                                                                        
     chip_addr             => i2c_addr_reg(6 downto 0),
     
     reg_addr_16b_enb      => reg_addr_16b_enb,     
     reg_addr_msbyte_first => reg_addr_msbyte_first,
     
     reg_addr              => i2c_addr_reg(31 downto 16),
     rwn                   => i2c_addr_reg(7),
     xfer_len              => xfer_len,
     fast_rd               => fast_rd,
     rd_stp_strt           => rd_stp_strt,
                           
     data_wr               => tx_fifo_rd_data,   
     data_wr_ack           => tx_fifo_rd_en,      
     
     busy                  => i2c_busy,                                                       
                                                       
     data_rd               => rx_fifo_wr_data,
     data_rd_valid         => rx_fifo_wr_en, 
                           
     ack_error             => i2c_ack_error,
                           
     --sda                 : inout  std_logic;                   
     --scl                 : inout  std_logic                         
                           
     sda                   => i2c_data_in,                      
     scl                   => i2c_clk_in,                       
                                                                                                                                                                                
     sda_oe                => i2c_data_oe,                      
     scl_oe                => i2c_clk_oe                       
     
  );                      
               
end;  --rtl

