--*----------------------------------------------------------------------------
--*                          RTL source file 
--*                      Logic Tectonics IP Module
--*        Logic Tectonics Copyright 2011-2021 ALL RIGHTS RESERVED
--*                       Licensed to the University of Chicago
--*                  royalty free, AS IS specifically/only for
--*                      the Aritc daq project  
--*           
--*----------------------------------------------------------------------------
--*   Author : Logic Tectonics          www.logic-tectonics.com 
--*   Phone  : 815-975-7070
-------------------------------------------------------------------------------
--*
--*   Description: This module creates serial debug module that allows an external
--*                PC to access the register block though a serial port.
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   2011-2021      Logic Tectonics       First Attempt
--*   20250201       Same                  Changed to support MSByte first3
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


entity tectonics_ser_debug is
   generic(
   
      g_arst_pol           : std_logic := '1';                                           -- default to '1' being te polarity of arst input
      g_ser_rate           : std_logic_vector(8 downto 0) := conv_std_logic_vector(2,9); -- 115.2k;  Setting of 1 would be 230.4k
      g_ser_debug_mult_sim : natural := 1; -- will use faster baud rate by this factor
      
      g_ser_stop_bits      : std_logic_vector(1 downto 0) := "01";                       -- One stop bit
      g_ser_parity         : std_logic_vector(1 downto 0) := "00";                       -- None
      
      g_tx_fifo_depth      : positive  := 1024;    -- Support 8 for now               
      g_tx_fifo_lev_width  : positive  := 11;      -- Set to the log2(g_tx_fifo_depth)+1 
      g_rx_fifo_depth      : positive  := 1024;    -- Support 8 for now               
      g_rx_fifo_lev_width  : positive  := 11;     -- Set to the log2(g_tx_fifo_depth)+1
      g_tx_fifo_use_logic  : boolean   := false;  -- leave set at this unless wont fit                                 
      g_rx_fifo_use_logic  : boolean   := false   -- leave set at this unless wont fit                                 
      
   );   
      
   port(
   
      arst                         : in   std_logic;  
      clk                          : in   std_logic; -- 125M or change reference_gen generics
      
      -- Interface to the Avalon fabfic for writing as master device     
                                                            
      avl_mstr_port_waitrequest    : in   std_logic;                    
      avl_mstr_port_byteenable     : out  std_logic_vector(3 downto 0);   
      avl_mstr_port_writedata      : out  std_logic_vector(31 downto 0);
      avl_mstr_port_address        : out  std_logic_vector(31 downto 0); -- This is a byte address
      avl_mstr_port_write          : out  std_logic;                    
      avl_mstr_port_read           : out  std_logic;                    
      avl_mstr_port_readdata       : in   std_logic_vector(31 downto 0);
      avl_mstr_port_readdatavalid  : in   std_logic;                     
                                                                                                                 
      -- The serial interface                                                                                                             
      ser_tx                       : out  std_logic;                     -- Serial transmit line used to receive commands from the outside world
      ser_rx                       : in   std_logic                      -- Serial receive line used to send responses to the outside world          
                                                           
   );                                                       
end entity tectonics_ser_debug;      
      
architecture rtl of tectonics_ser_debug is     

-- Components
component tectonics_com_intfc_core
   generic(
      g_vendor             : string    := "altera";                                                                         
      g_arst_pol           : std_logic := '1';   -- default to '1' being te polarity of arst input                          
      g_tx_fifo_depth      : positive  := 4096;  -- Support 16 for now                                                      
      g_tx_fifo_lev_width  : positive  := 13;    -- Set to the log2(g_tx_fifo_depth)+1 for one based                        
      g_rx_fifo_depth      : positive  := 4096;  -- Support 16 for now                                                      
      g_rx_fifo_lev_width  : positive  := 13;    -- Set to the log2(g_tx_fifo_depth)+1 for one based                        
                                                                                                                            
      g_serial_rate_width  : positive  := 9;   -- Set to minimum of 9 for serial rates 230400 to 300 Baud with 3.686Mz reference
                                                                                                                                  
      g_tx_fifo_use_logic  : boolean   := false;                                                                                  
      g_rx_fifo_use_logic  : boolean   := false                                                                                         
       
   );   
      

   port(
      arst           : in   std_logic;                    --  Async reset, polarity set by arst_pol
      clk            : in   std_logic;                    --  Clk. Pos edge active.
                                                          
      ser_ref_pls    : in   std_logic;                    -- This is a pulse, one clk wide, at 3.686Mz (or within 2%)
      

      ser_rate       : in   std_logic_vector(8 downto 0); -- This sets the bit rate 2 = 115200  -- serial rate = 3.686M/(ser_rate*16)
                                                          -- This sets the bit rate 4 = 57.6k
                                                          -- This sets the bit rate 8 = 28.8k
                                                          -- This sets the bit rate 16 = 14.4k
                                                          
      ser_stop_bits  : in std_logic_vector(1 downto 0);   -- 00 = 2 
                                                          -- 01 = 1
                                                          -- 10 = 2
                                                          -- 11 = 2
                                                          
      ser_parity     : in std_logic_vector(1 downto 0);   -- 00 = none
                                                          -- 01 = even
                                                          -- 10 = odd
                                                          -- 11 = none
                                                          
      data_size      : in std_logic_vector(1 downto 0);   -- 00 = 8                                                                  
                                                          -- 01 = 7                                                                  
                                                          -- 10 = reserved                                                           
                                                          -- 11 = reserved 
                                                                                                                                                                         
      tx_data        : in  std_logic_vector(7 downto 0);
      tx_wr          : in  std_logic;                                          -- One clock wide to write the data on tx_data() into the tx fifo
      tx_level       : out std_logic_vector(g_tx_fifo_lev_width-1 downto 0);   -- Use this as the LSBs of the tx FIFO level.
      tx_full        : out std_logic;                                          -- Use as the MSB of the level to represent complete level
      tx_empty       : out std_logic;                                          -- Active high TX FIFO empty signal
      
      rx_data        : out std_logic_vector(7 downto 0);
      rx_par_err     : out std_logic;                                          -- If the rx fifo is not empty then if this is set
                                                                               -- the data word about to be read has a parity error id this is '1'
      rx_rdack       : in  std_logic;
      rx_level       : out std_logic_vector(g_rx_fifo_lev_width-1 downto 0);   -- Use this as the LSBs of the rx FIFO level.
      rx_full        : out std_logic;                                          -- Use as the MSB of the level to represent complete level
      rx_empty       : out std_logic;                                          -- Active high RX FIFO empty signal
      
      ser_tx         : out std_logic;                                          -- Serial transmit line
      ser_rx         : in  std_logic;                                           -- Serial receive line 
      
      tx_en           : in  std_logic;                                          -- Uart will ignore writes to the TX fifo (and will flush the TX FIFO) if this is not set        
      rx_en           : in  std_logic;                                          -- Uart will ignore incoming serial traffic (and will flush the RX FIFO) if this is not set
      
      
      tx_busy         : out std_logic;                                          -- '1' when TX is enabled and either transmitting or FIFO is not empty
      
      rx_par_err_pls  : out std_logic;                                          -- Pulsed when data with a parity error is written to the rx fifo 
      
      rx_fifo_ovf_pls : out std_logic;                                          -- Pulsed when RX FIFO is full when a new char arrives.
      
      rx_idle_setting : in  std_logic_vector(5 downto 0);                       -- Sete the time in characters (for the set baud rate)
                                                                                -- for the rx_idle_pls to fire after a period of receive activity                 
      tx_pace_setting : in  std_logic_vector(5 downto 0);                       -- Sete the       
      
           
      rx_idle_pls    : out std_logic                                           -- Fire off after a period of inactivity of RX                                                           
                                                                                                                                                                        
      
   );
   
end component;   

component reference_gen
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
   
end component;     

   -- Constants
   
   -- Command from serial
   constant c_rd_cmd : std_logic_vector(7 downto 0) := X"01";
   constant c_wr_cmd : std_logic_vector(7 downto 0) := X"02";

   -- Types 
   -- This is the fsm states for getting command from 
   -- the serial bus and responding to them
   type cmd_dcd_fsm_states is (
                               s_get_cmd_byte,
                               s_get_addr_bytes,
                               s_get_len_byte,
                               s_get_wr_data_bytes,
                               s_send_rd_reqs_to_fabric,
                               s_wait_until_rd_data_bytes_sent,
                               s_err_wait_bus_idle,
                               s_timeout_err
                              ); 

        
   
   -- Signals
   signal all_zeros           : std_logic_vector(31 downto 0);
   
   signal cmd_dcd_fsm_state     : cmd_dcd_fsm_states;
   
   signal ser_rate            : std_logic_vector(8 downto 0);   -- This sets the bit rate 2 = 115200  -- serial rate = 3.686M/(ser_rate*16)   
                                                                -- This sets the bit rate 4 = 57.6k                                           
                                                                -- This sets the bit rate 8 = 28.8k                                           
                                                                -- This sets the bit rate 16 = 14.4k                                          
                                                                                                                                              
   signal ser_stop_bits       : std_logic_vector(1 downto 0);   -- 00 = 2                                                                     
                                                                -- 01 = 1                                                                     
                                                                -- 10 = 2                                                                     
                                                                -- 11 = 2                                                                     
                                                                                                                                              
   signal ser_parity          : std_logic_vector(1 downto 0);   -- 00 = none                                                                  
                                                                -- 01 = even                                                                  
                                                                -- 10 = odd                                                                   
                              
   signal tx_data             : std_logic_vector(7 downto 0);                    
   signal tx_wr               : std_logic;                                                                                                 
   signal tx_level            : std_logic_vector(g_tx_fifo_lev_width-1 downto 0);                                                          
   signal tx_full             : std_logic;                                                                                                 
   signal tx_empty            : std_logic;                                                                                                 
                                                                                                                                   
   signal rx_data             : std_logic_vector(7 downto 0);                                                                              
   signal rx_par_err          : std_logic;                                                                                                 
                                                                                                                               
   signal rx_rdack            : std_logic;                                                                                                 
   signal rx_level            : std_logic_vector(g_tx_fifo_lev_width-1 downto 0);                                                          
   signal rx_full             : std_logic;                                                                                                 
   signal rx_empty            : std_logic;                                                                                                 
                              
   signal rx_idle_pls         : std_logic;  
   signal addr_byte_cnt       : std_logic_vector(1 downto 0);                                                        
   signal data_byte_cnt       : std_logic_vector(9 downto 0); 
                              
   signal cap_cmd             : std_logic_vector(7 downto 0);                        
   signal cap_data_len        : std_logic_vector(7 downto 0);
   type   cap_addr_type       is array (0 to 3) of std_logic_vector(7 downto 0);
   signal cap_addr            : cap_addr_type;
                              
   type   cap_rx_data_type    is array (0 to 3) of std_logic_vector(7 downto 0);
   signal cap_rx_data         : cap_rx_data_type;
                              
   signal reg_wr_req_sig      : std_logic;
   
   
   signal sent_read_byte_cnt  : std_logic_vector(9 downto 0);
   signal rd_req_cnt          : std_logic_vector(11 downto 0);
   signal reg_rd_req_sig      : std_logic;
   signal reg_rd_data_cap     : std_logic_vector(31 downto 0);
   signal byte_demux_cnt      : std_logic_vector(2 downto 0);
   
   
   signal ser_ref_pls           :std_logic;                    -- This is a pulse, one clk wide, at 3.686Mz (or within 2%)
                               
   signal reg_addr              : std_logic_vector(31 downto 0); -- Register address of the data being requested or written                                                                                                                                                                                        
   signal reg_rd_req            : std_logic;                     -- This is the request for the data, it assert for one clock at the same time the addr    
   signal reg_rd_data_valid     : std_logic;                     -- Since the read data may be pipelined this allows the read data to show up after        
   signal reg_rd_data           : std_logic_vector(31 downto 0); -- the read data from the reg_addr location in the reister file                                                                                                                                                                                                                                                                                                                                                    
   signal reg_wr_data           : std_logic_vector(31 downto 0); -- The data to be written to the register file                                            
   signal reg_wr_req            : std_logic;                     -- The one clock wide write request to reg_addr in teh register file                      
   
   signal reg_rd_data_valid_sig : std_logic; 
   signal reg_rd_data_sig       : std_logic_vector(31 downto 0);        
   
   signal waiting_for_rd_resp   : std_logic;
      
   signal ms_tick               : std_logic; -- not used but could be used for a timeout counter

begin -- rtl   

all_zeros <= (others => '0');

--
-- Generate the refernce for the serial interface
--`
inst_reference_gen : reference_gen --fout = fin * n/2^k, need 3.686Mz (or within 2%). So fin is 125MHz 
   generic map(
      g_arst_pol  => g_arst_pol, -- default to '1' being te polarity of arst input
      
      g_n_main    => 524,  -- This is the n factor for to generate the ms and us tick refernce from clk in 
      g_k_main    => 16,    -- This is the k factor for to generate the ms and us tick refernce from clk in 
                            -- Make sure to set to create a 1 MHz clock from clk in.
                            -- 1 = 125M * n/2^16
      
      g_n_misc    => 1933*g_ser_debug_mult_sim,   -- This is the n factor for to generate misc_tick refernce from clk in
      g_k_misc    => 16,     -- This is the k factor for to generate misc_tick refernce from clk in. 
                             -- 3.686 = 125M * n/2^16,   so 125* 1933/2^16 = 3.687MHz so good
                           
      g_m_ms      => 1000,  -- One based these are divisors to create slower ticks from the ms and us ticks, max is 1024
      g_m_us      => 20     -- These are divisors to create slower ticks from the ms and us ticks. 1000 max
             
   )        

   port map(
      
      arst           => arst,
      clk            => clk, 
                     
      ms_tick        => ms_tick,       -- millisecond tick pulse (one clk wide)
      us_tick        => open,          -- microsecond tick pulse (one clk wide)
                     
      ms_tick_div_m  => open,
      us_tick_div_m  => open,
      
      misc_tick      => ser_ref_pls                                                            
      
   );

-- Connect to ports on the uart                                                                                         
ser_rate      <= g_ser_rate;                                                              
ser_stop_bits <= g_ser_stop_bits;                                                         
ser_parity    <= g_ser_parity;                                                            
                                                                                          
                                                                                          

inst_tectonics_com_intfc_core : tectonics_com_intfc_core
   generic map(
      g_vendor             => "altera",
      g_arst_pol           => g_arst_pol, 
      g_tx_fifo_depth      => g_tx_fifo_depth,          
      g_tx_fifo_lev_width  => g_tx_fifo_lev_width,      
      g_rx_fifo_depth      => g_rx_fifo_depth,          
      g_rx_fifo_lev_width  => g_rx_fifo_lev_width,      
      
      g_serial_rate_width  => 9,
      
      g_tx_fifo_use_logic  => g_tx_fifo_use_logic,
      g_rx_fifo_use_logic  => g_rx_fifo_use_logic    

   )   
      
   port map(
      
      arst           => arst,
      clk            => clk, 
                                                          
      ser_ref_pls    => ser_ref_pls,
      
      ser_rate       => ser_rate,                                                               
      ser_stop_bits  => ser_stop_bits,                                                                                    
      ser_parity     => ser_parity,   
      
      data_size      => "00",
                                                                                                                   
      tx_data        => tx_data,   
      tx_wr          => tx_wr,        
      tx_level       => tx_level,     
      tx_full        => tx_full,      
      tx_empty       => tx_empty,     
                                
      rx_data        => rx_data,   
      rx_par_err     => rx_par_err,   
                                   
      rx_rdack       => rx_rdack,  
      rx_level       => rx_level,     
      rx_full        => rx_full,      
      rx_empty       => rx_empty,  
      
      ser_tx         => ser_tx,                                        
      ser_rx         => ser_rx,   
      
      tx_en          => '1',                           
      rx_en          => '1',                           
                                                                 
                                                                 
      tx_busy         => open,                                                                              
      rx_par_err_pls  => open,                                                    
      rx_fifo_ovf_pls => open,                           
                                                                 
      rx_idle_setting => "100100", -- Set to 36 bit clocks        
                                                                 
      tx_pace_setting => "000000", -- Set to 0 bit clocks        
      
      rx_idle_pls    => rx_idle_pls                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
      
   );

-- Auto read the UART RX FIFO to get pop the data as it arrives. Dont read when in states not ready to consume data from the UART link  
rx_rdack <= '1' when (rx_empty = '0') and (cmd_dcd_fsm_state /= s_send_rd_reqs_to_fabric) and (cmd_dcd_fsm_state /= s_wait_until_rd_data_bytes_sent) else '0';
   
--
-- Counters used in the decoding of the message from the serial link
--
process(clk, arst)                   
variable cap_addr_vec : std_logic_vector(31 downto 0);
begin                                
   if arst = g_arst_pol then  
      cap_cmd        <= (others => '1');
      cap_data_len   <= (others => '0');
      cap_addr       <= (others => (others => '0'));
      cap_rx_data    <= (others => (others => '0'));     
                     
      addr_byte_cnt  <= (others => '0');
      data_byte_cnt  <= (others => '0');
      
      reg_wr_req_sig <= '0';
      
      rd_req_cnt     <= (others => '0');
      reg_rd_req_sig <= '0';
      
   elsif clk'event and clk = '1' then

      -- Capture the command byte
      if cmd_dcd_fsm_state = s_get_cmd_byte and rx_rdack = '1' then        
         cap_cmd <= rx_data;      
      end if;   
        
      -- Capture the data word length byte. Byte represents the number of 32-bit words to read or write based on the command.
      if cmd_dcd_fsm_state = s_get_len_byte and rx_rdack = '1' then        
         cap_data_len <= rx_data;      
      end if;
      
      -- Capture the 4 address bytes, MS Byte first. This is a byte address, must be aligned to 32-bit works to 0x00000000, 0x00000004, 0x00000008, etc.
      if cmd_dcd_fsm_state = s_get_addr_bytes then
         if rx_rdack = '1' then
           addr_byte_cnt <= addr_byte_cnt + 1;           
           cap_addr(conv_integer('0'&addr_byte_cnt)) <= rx_data;           
         end if;  
      elsif (reg_wr_req_sig = '1' or reg_rd_req_sig = '1') and (avl_mstr_port_waitrequest = '0') then -- advance the address in the case of a burst write or read 
         cap_addr_vec(31 downto 24) := cap_addr(0);
         cap_addr_vec(23 downto 16) := cap_addr(1);
         cap_addr_vec(15 downto 8)  := cap_addr(2);
         cap_addr_vec(7 downto 0)   := cap_addr(3);
         cap_addr_vec := cap_addr_vec + 4;   -- increment for next loc use, increment by 4 for 32-bit word address 
         
         cap_addr(0) <= cap_addr_vec(31 downto 24);
         cap_addr(1) <= cap_addr_vec(23 downto 16);
         cap_addr(2) <= cap_addr_vec(15 downto 8); 
         cap_addr(3) <= cap_addr_vec(7 downto 0);  
         
      else
         addr_byte_cnt <= (others => '0');
      end if; 
      
      -- Capture the data to be written to the fabric as it received over the serial link. 4 bytes per word, MS Byte first
      if cmd_dcd_fsm_state = s_get_wr_data_bytes then --todo: at some point work avl_mstr_port_waitrequest into this. but really its sooo slow with serial interaction so wont ever back up
          if rx_rdack = '1' then
           data_byte_cnt <= data_byte_cnt + 1;           
           cap_rx_data(conv_integer('0'&data_byte_cnt(1 downto 0))) <= rx_data;           
         end if;  
      else
         data_byte_cnt <= (others => '0');
      end if;       
  
      -- Generate the reg write request to write the 32 bit data word received to
      -- the register file register identified by the received address.
      -- This will end up delaying the pulse until the last data byte is actully in the cap_rx_data(3) rray position reg
      -- so every thing should be ligned up properly (data + address + write strobe) to the register file
      if (cmd_dcd_fsm_state = s_get_wr_data_bytes) and (conv_integer('0'&data_byte_cnt(1 downto 0)) = 3) and rx_rdack = '1' then
         reg_wr_req_sig <= '1';
      else
         if avl_mstr_port_waitrequest = '0' then
            reg_wr_req_sig <= '0';
         end if;
      end if; 
      
      
      --
      -- Generate the logic to request the reads to the avalon bus
      -- Basically the counter is larger than the number of words so that the
      -- 32-bit reads are spaced by the amount of time needed to demux the data returning to 
      -- 8-bit. So 4:1 demux. THis breaks down for multiple reads over the avalon bus if 
      -- the remote avalon device has long latency (more than 4 clock of this module). For single reads
      -- its fine. Updated: added in waiting_for_rd_resp and avl_mstr_port_waitrequest to stall until the read data is received from slow sources and also stop additoinal requests until fabric is ready   
        if cmd_dcd_fsm_state /= s_send_rd_reqs_to_fabric then
           rd_req_cnt <= (others => '0');
        else
           if conv_integer('0'&rd_req_cnt(rd_req_cnt'left downto 3)) /= conv_integer('0'&cap_data_len) then 
              if((waiting_for_rd_resp = '0') or (conv_integer('0'&rd_req_cnt(2 downto 0)) < 2)) then -- wait for the data to return, <2 so that the other pacing logic still works  
                 rd_req_cnt <= rd_req_cnt + 1;
              end if;
           end if;   
        end if;
        -- Generate the 32-bit read request every time the 3 lowest bit count = 1d. This way the reads are spread
        -- with enough time demux the bytes of the retruning data without needing to store the returning data
        -- This them makes the assumption that all reads have the same latency within 4 cycles.
        -- See above updates. This will stall at 2 when waiting for slow data source.
        if conv_integer('0'&rd_req_cnt(2 downto 0)) = 1 then
           reg_rd_req_sig <= '1';
        else
           if avl_mstr_port_waitrequest = '0' then
              reg_rd_req_sig <= '0';
           end if;
        end if;   
        
        
        if cmd_dcd_fsm_state = s_get_cmd_byte then
           sent_read_byte_cnt <= (others => '0');
        elsif tx_wr = '1' then 
           sent_read_byte_cnt <= sent_read_byte_cnt + 1;
        end if;   
      
   end if;
end process;   

reg_addr(31 downto 24) <= cap_addr(0);
reg_addr(23 downto 16) <= cap_addr(1);
reg_addr(15 downto 8)  <= cap_addr(2);
reg_addr(7 downto 0)   <= cap_addr(3);

reg_wr_data(31 downto 24) <= cap_rx_data(0);
reg_wr_data(23 downto 16) <= cap_rx_data(1);
reg_wr_data(15 downto 8)  <= cap_rx_data(2);
reg_wr_data(7 downto 0)   <= cap_rx_data(3);

reg_wr_req <= reg_wr_req_sig;  

reg_rd_req <= reg_rd_req_sig;

--
-- This logic will demux the data recieved from read source (local or avalon bus) and write it to the TX FIFO in the com port
--
process(clk, arst)                   
variable cap_addr_vec : std_logic_vector(31 downto 0);
begin                                
   if arst = g_arst_pol then  
      tx_wr           <= '0';
      byte_demux_cnt  <= "100";
      reg_rd_data_cap <= (others => '0');
   elsif clk'event and clk = '1' then   
      if reg_rd_data_valid = '1' then       
         reg_rd_data_cap <= reg_rd_data; -- latch in case future sources only have the data valid for a clock cycle
         tx_wr <= '1';
         byte_demux_cnt <= (others => '0'); -- sets the byte demux lane to 0              
      else
         if byte_demux_cnt(2) /= '1' then
            byte_demux_cnt <= byte_demux_cnt + 1;
         end if;
         
         if byte_demux_cnt(1 downto 0) = "11" then -- if at this count then disable the write signal to the FIFO the next clock since all bytes will have been demux'd and written
            tx_wr <= '0';
         end if;
      
      end if;
      
   end if;
end process;   

--tx_data <= reg_rd_data_cap(conv_integer('0'&(byte_demux_cnt(1 downto 0)&"000") + 8 - 1 downto conv_integer('0'&byte_demux_cnt(1 downto 0)&"000")))

process(byte_demux_cnt, reg_rd_data_cap)
begin
   case conv_integer('0'&byte_demux_cnt(1 downto 0)) is
      when 3 =>
         tx_data <= reg_rd_data_cap(7 downto 0);       -- MS byte sent first
      when 2 =>
         tx_data <= reg_rd_data_cap(15 downto 8);
      when 1 =>
         tx_data <= reg_rd_data_cap(23 downto 16);
      when 0 =>
         tx_data <= reg_rd_data_cap(31 downto 24);
      when others =>
         tx_data <= (others => '-');   
   end case;
   
end process;  


   
-- The Message structure is
-- 1 Command byte 0x01 = write, 0x02 = read
-- 4 byte address, MSByte first 
-- 1 byte length of 4-byte Data long words to be read starting at that address, So 0x00 = 256x4 bytes, 0x01 = 4 bytes to follow, Data is sent MSByte first 
-- 4*N bytes of data                                                                                                             
                                                                                                                                    
--
-- Generate the state machine to control the capture process
--   
process(clk,arst)
begin
   if arst = g_arst_pol then
      cmd_dcd_fsm_state <= s_get_cmd_byte; 
      
   elsif clk'event and clk = '1' then  
      case cmd_dcd_fsm_state is 
         when s_get_cmd_byte => -- wait here until a capture is requested
            if rx_rdack = '1' then
            
               case rx_data is
                  when c_wr_cmd =>
                     cmd_dcd_fsm_state <= s_get_addr_bytes;
                  when c_rd_cmd   =>
                     cmd_dcd_fsm_state <= s_get_addr_bytes;
                  when others =>
                     cmd_dcd_fsm_state <= s_err_wait_bus_idle;
               end case;
            end if;
                
         when s_get_addr_bytes => -- Wait for the first tick so that the duration can be properly tracked
            if rx_idle_pls = '1' then
               cmd_dcd_fsm_state <= s_timeout_err;
            else -- wait and grab the address bytes
               if conv_integer('0'&addr_byte_cnt) = 3 and rx_rdack = '1' then -- last address byte received
                  cmd_dcd_fsm_state <= s_get_len_byte;
               end if;
            end if;
             
         when s_get_len_byte =>
            if rx_idle_pls = '1' then                                                                         
               cmd_dcd_fsm_state <= s_timeout_err;                                                         
            else -- wait and grab the byte that contains number of 32-bit data word length byte for words to follow                                                        
               if rx_rdack = '1' then    
                  case cap_cmd is
                     when c_wr_cmd =>           
                        cmd_dcd_fsm_state <= s_get_wr_data_bytes;
                     when c_rd_cmd =>                                                               
                        cmd_dcd_fsm_state <= s_send_rd_reqs_to_fabric;                                 
                     when others =>
                        cmd_dcd_fsm_state <= s_err_wait_bus_idle;                       
                  end case;                                                        
               end if;                                                                                     
            end if;                                                                                                   
            
         when s_get_wr_data_bytes => -- In this state as the write data is received from the serial link it is saved and combined to create a 32-bit word to 
                                     -- be written to the register file interface
            if rx_idle_pls = '1' then
               cmd_dcd_fsm_state <= s_timeout_err;
            else -- wait and grab the data bytes while in this state demux into 32bit words (see other logic for that)
               if conv_integer('0'&data_byte_cnt(data_byte_cnt'left downto 2)) = cap_data_len then -- last data word received. Since they are 4 bytes per word dont look at (1:0) but rather the upper bits
                  cmd_dcd_fsm_state <= s_get_cmd_byte;
               end if;
            end if;  
         
         --
         -- Read section
         --   
         when s_send_rd_reqs_to_fabric =>
            if conv_integer('0'&rd_req_cnt(rd_req_cnt'left downto 3)) = conv_integer('0'&cap_data_len) then
               cmd_dcd_fsm_state <= s_wait_until_rd_data_bytes_sent;            
            end if;
       
         when s_wait_until_rd_data_bytes_sent => -- In this state 32-bit words are read from the avalon interface and seperated into bytes and written to the serial interface
            if sent_read_byte_cnt = (cap_data_len&"00") then -- The cap data length is in 32-bit words (one based). So when checking how many bytes have been sent in response
                                                             -- to see if complete, we need to compare to that 
               cmd_dcd_fsm_state <= s_get_cmd_byte;
            end if;                     
            
         when s_err_wait_bus_idle =>  -- Sent here is an improper command is received
            if rx_idle_pls = '1' then  -- Wait until the bus goes idle
               cmd_dcd_fsm_state <= s_get_cmd_byte;
            end if;
            
         when s_timeout_err => -- Perhaps dont need this state (could just go to the cmd decode state) but is good in case needing to decode off of it later.
            cmd_dcd_fsm_state <= s_get_cmd_byte;
                       
         when others => 
            null;
            
      end case;                                                                               
   end if;                                                                                    
end process;                                                                                  
                                                                                                           
--
-- Read mux for local registers
--

process(clk,arst)                                                                                    
begin                                                                                                                   
   if arst = g_arst_pol then                                                                  
                                                                                              
      reg_rd_data_valid_sig <= '0';                                                     
      reg_rd_data_sig       <= (others => '0');     
      
      waiting_for_rd_resp   <= '0';
                                              
   elsif clk'event and clk = '1' then                                                       
                                                                                            
      reg_rd_data_valid_sig <= '0';                                                   
      reg_rd_data_sig       <= (others => '0');
                                              
         
      if avl_mstr_port_readdatavalid = '1' then -- data returning on avalon bus avl_mstr_port_readdata is valid
         reg_rd_data_valid_sig <= '1';
         reg_rd_data_sig       <= avl_mstr_port_readdata;
      end if;    
        
      -- Signal to indicate waiting for data so that if needed (for avalon sources) we will wait for that
      -- data versus assuming it will show up withing 4 clk cycles. 
      if (reg_rd_req = '1') then
         waiting_for_rd_resp <= '1';
      elsif (reg_rd_data_valid_sig = '1') then  
         waiting_for_rd_resp <= '0';
      end if;   
      
      
   end if;                                                                                                       
end process;        


--
-- Avalon port connections
--
  

avl_mstr_port_byteenable <= "1111"; 
                        
avl_mstr_port_writedata  <= reg_wr_data;         
avl_mstr_port_address    <= reg_addr; -- this is a byte address on avalon
avl_mstr_port_write      <= reg_wr_req;                                                               
avl_mstr_port_read       <= reg_rd_req;                                                               
           
reg_rd_data_valid        <= reg_rd_data_valid_sig;
reg_rd_data              <= reg_rd_data_sig; 




end rtl;   