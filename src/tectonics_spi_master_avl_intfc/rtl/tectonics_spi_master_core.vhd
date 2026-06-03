--*----------------------------------------------------------------------------
--*                                VHDL RTL source file
--*                          Tectonic Innovation/Logic Tectonics
--*                                 All Rights Reserved
--*                                        2011-2018 
--*               Tectonics IP, licensed to end customer non-exclusively
--*               and royalty free, AS IS, with no other representations. 
--*                    This header must be included with
--*                the source code wherever used to be in compliance 
--*                         with the terms of this license.
--*               
--*
--*---------------------------------------------------------------------------- 
--*   Author : Logic Tectonics. www.logic-tectonics.com         
--*   Phone  : 847 725-0840
-------------------------------------------------------------------------------
--*
--*   Description: This file implements a core spi master funciton
--*                with additional usability features.
--*                                              
--*
--*----------------------------------------------------------------------------
--*
--*   Revisions:
--*
--*   Date           Author                Description
--*   -----------    --------------        -----------
--*   Sep/2011       Tectonics             
--*   Nov/2018       Same                  Added but reveral and 1024 byte 
--*                                        support
--*                                        Added pace = 8  = clk/25
--*   Dec/2018       Same                  Added pace = 9  = clk/50
--*                                        Added pace = 10 = clk/100
--*   Jan/2019       Same                  Added pace = 11 = clk/200
--*   Mar//2020      Same                  Updated the language to make it 
--*                                        that the module supports xfers
--*                                        up to 1024 bytes.
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


entity tectonics_spi_master_core is
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
                                                               -- 0  = clk/2 pace_factor = 2
                                                               -- 1  = clk/4 pace_factor = 4
                                                               -- 2  = clk/6
                                                               -- 3  = clk/8          
                                                               -- 4  = clk/10
                                                               -- 5  = clk/16
                                                               -- 6  = clk/18
                                                               -- 7  = clk/20
                                                               -- 8  = clk/25
                                                               -- 9  = clk/50
                                                               -- 10 = clk/100
                                                               -- 11 = clk/200
                                                               -- others = clk/20 pace_factor = 22
                                                                                                           -- 0 = ~1.5 SPI clocks         
      ss_to_clk_gap        : in std_logic_vector(3 downto 0):= "0001";  -- 0 = ~1.5 SPI clocks             -- 1 = 3 SPI clocks   -- todo: 
                                                                        -- 1 = 30 SPI clocks               -- 2 = 30 SPI clocks  -- todo: 
      clk_to_ss_gap        : in std_logic_vector(3 downto 0):= "0001";  -- 0 = ~1.5 SPI clocks             -- 0 = ~1.5 SPI clocks                                                               
                                                                        -- 1 = 60 SPI clocks               -- 1 = 3 spi clocks   -- todo:                                                       
                                                                                                           -- 2 = 60 SPI clocks  -- todo: 
      delay_enb            : in std_logic;                    -- If '1' then insert delay as defined below.
      delay_byte_pos       : in std_logic_vector(7 downto 0); -- After this byte (1 based) add a delay in the transfer to allow external device to have time to fetch data
                                                              -- If 0, then will insert delay after each byte
      delay_time_spi_clks  : in std_logic_vector(9 downto 0); -- Number of clocks (1 based) to delay after the delay byte before continuing with remaining bytes  
                                                              -- So delay would be 
                                                              -- clk/pace_factor * delay_time_spi_clks.
      tx_lsb_first         : in std_logic;                    -- '1' = lsb first for each byte. '0' = msb first.                                                
      rx_lsb_first         : in std_logic;                    -- '1' = lsb first for each byte. '0' = msb first.                                                          
                                                                                                                                                      
      spi_tx_msg_rdy       : in  std_logic;                    -- There is a message in the external message queue if this is '1';
      spi_tx_msg_len       : in  std_logic_vector(9 downto 0); -- One based, 1024 max (0=1024)
      spi_tx_msg_sent_pls  : out std_logic;                    -- Fired after the message is sent, this should be used by the external msg length manager to advance to the next 
                                                               -- MSG length value. So if there is a fifo out there for this then it is a look ahead type...                                                              
      
      spi_tx_msg_rd_ack    : out std_logic;                    -- 1 clk wide pulse that acks the data from the external message queue. Its an ack so
      spi_tx_msg_data      : in  std_logic_vector(7 downto 0); -- data is expected to stay stable until spi_tx_msg_rd_ack is pulsed (i.e. a look ahead FIFO rather than a request FIFO) 
                                                               -- Else its the data for the message that follows in bytes. Max message is 1024 bytes (mesage length of 0 = 1024 bytes)
      
      spi_rx_msg_wr_ack    : out std_logic;                     -- 1 clk wide pulse indicating that a data byte from the external device is valid. Pulses once per byte received.
                                                                -- Data byte on spi_rx_msg_data() is valid and new when this pulses '1'.
      spi_rx_msg_data      : out  std_logic_vector(7 downto 0); -- Data only valid spi_rx_msg_wr_ack is pulsed. External device needs to store the byte when this pulses
      
                                                               
                                                               
      -- SPI interface
      spi_sclk             : out std_logic;
      spi_ss_n             : out std_logic;
      spi_mosi             : out std_logic;
      spi_miso             : in  std_logic                      
                                                                                                                                                  
   );

end entity;


architecture rtl of tectonics_spi_master_core is

-- Components

-- Constants
   
-- Types
   type spi_state_type is    (      s_spi_wait_for_msg_rdy,
                                    s_wait_ss_to_clk_gap,
   			                        s_spi_assert_ss,
   			                        s_spi_send_data,
   			                        s_wait_clk_to_ss_gap,
   			                        s_spi_done   			                    
                                    );                              
                                    
-- Signals                         
   signal spi_state                : spi_state_type;                                                            
                                                                                                           
   signal bit_pos_cnt              : std_logic_vector(2 downto 0);
   signal tx_data_sr               : std_logic_vector(7 downto 0);
   signal msg_byte_ptr             : std_logic_vector(10 downto 0);
                                   
   signal load_cnts_pls            : std_logic; 
   signal load_data_pls            : std_logic;
                                   
   signal spi_tx_msg_rd_ack_sig    : std_logic;
                                   
   signal spi_clk_en               : std_logic;
                                   
   signal pace_cnt                 : natural range 0 to 255;
   signal pace_tick                : std_logic;  
   signal pace_clk_wave            : std_logic;               
                                   
   --signal spi_clk_en_r             : std_logic;
   signal spi_sclk_sig             : std_logic;
                                   
   signal dly_byte_count           : natural range 0 to 1024; -- 1 based
                                   
   signal stall                    : std_Logic;
   signal stall_cnt                : natural range 0 to (2**(delay_time_spi_clks'length)) -1;
                                   
   signal samp_miso_pls            : std_logic;
                                   
   signal miso_shift_reg           : std_logic_vector(7 downto 0);
   signal miso_bit_cnt             : natural range 0 to 7;                             
                                                                                       
   signal spi_rx_msg_wr_ack_sig    : std_logic;
                                   
   signal ss_to_clk_gap_cnt        : natural range 0 to 255;
   signal clk_to_ss_gap_cnt        : natural range 0 to 255;
   signal spi_ss_n_sig             : std_logic;
   
   signal spi_tx_msg_data_remapped : std_logic_vector(7 downto 0);
   signal spi_rx_msg_data_remapped : std_logic_vector(7 downto 0);
   
   --signal low                   : std_logic;
   --signal high                  : std_logic;
begin

--low  <= '0';
--high <= '1';

--
-- Create a counters from the main clock that can be used to pace the 
-- SPI TX data if necessary. This pace_tick will insert a dead cycle
-- in the SPI clock every so often to basically cause a throttling of the 
-- SPI transfer data rate. 
--
process(clk,arst)
variable cycle_term  : natural range 0 to 255;
variable clk_h2l_pnt : natural range 0 to 255; -- point that the clock changes from h2l 
variable clk_l2h_pnt : natural range 0 to 255; -- point that the clock changes from l2h
begin
   if arst = g_arst_pol then
      pace_tick     <= '0'; 
      pace_cnt      <= 0;
      pace_clk_wave <= '0';
      samp_miso_pls <= '0';
   elsif clk'event and clk = '1' then                                                           
  
      
      if conv_integer('0'&pace) = 0 then 
         pace_cnt  <= 0;
         pace_tick <= not pace_tick; -- fastest rate is 1/2 clk
      else   
         case conv_integer('0'&pace) is
            when 1 =>
               cycle_term  := 4-1;
               clk_h2l_pnt := 4/2 - 1; --3;      --  4/2 - 1;
               clk_l2h_pnt := 4-1;     --1;      --  4-1;
            when 2 => 
               cycle_term  := 6-1;
               clk_h2l_pnt := 6/2 - 1;
               clk_l2h_pnt := 6-1;
            when 3 => 
               cycle_term  := 8-1;
               clk_h2l_pnt := 8/2 - 1;
               clk_l2h_pnt := 8-1;
            when 4 => 
               cycle_term  := 10-1;
               clk_h2l_pnt := 10/2 - 1;
               clk_l2h_pnt := 10-1;
            when 5 =>
               cycle_term  := 16-1;
               clk_h2l_pnt := 16/2 - 1;
               clk_l2h_pnt := 16-1;
            when 6 =>
               cycle_term  := 18-1;
               clk_h2l_pnt := 18/2 - 1;
               clk_l2h_pnt := 18-1;               
            when 7 =>
               cycle_term  := 20-1;
               clk_h2l_pnt := 20/2 - 1;
               clk_l2h_pnt := 20-1;   
               
            when 8 =>
               cycle_term  := 25-1;
               clk_h2l_pnt := 25/2 - 1;
               clk_l2h_pnt := 25-1;         
               
            when 9 =>
               cycle_term  := 50-1;
               clk_h2l_pnt := 50/2 - 1;
               clk_l2h_pnt := 50-1; 
                   
            when 10 =>
               cycle_term  := 100-1;
               clk_h2l_pnt := 100/2 - 1;
               clk_l2h_pnt := 100-1;  
                 
            when 11 =>
               cycle_term  := 200-1;
               clk_h2l_pnt := 200/2 - 1;
               clk_l2h_pnt := 200-1;                                                                                          
                                          
            when others =>
               cycle_term  := 22-1;
               clk_h2l_pnt := 22/2 - 1;
               clk_l2h_pnt := 22-1;
         end case;
         
         samp_miso_pls <= '0';  -- Used to sample the incoming MISO data line 
         if conv_integer('0'&pace) = 0 then       
            samp_miso_pls <= pace_tick; -- todo: fix for capture on pos or neg edge when pace = 0 
         else      
            if miso_samp_clk_edge = '0' then  -- sample MISO on falling edge of SPI clock
               if pace_cnt = (clk_h2l_pnt + g_delay_miso_samp_val) and spi_clk_en = '1' and stall = '0' then
                  samp_miso_pls <= '1'; 
               end if;
            else   -- sample MISO on rising edge of SPI clock
               if pace_cnt = (clk_l2h_pnt + g_delay_miso_samp_val) and spi_clk_en = '1' and stall = '0' then
                  samp_miso_pls <= '1';
               end if;                                                                                
            end if;
         end if;
         
         
         pace_tick     <= '0';            
         if pace_cnt = clk_h2l_pnt then -- time this such that the timing for bit position lineup of SPI clock is correct
            pace_tick     <= '1';
         end if;
            
         if pace_cnt >= cycle_term then
            pace_cnt  <= 0;
         else
            pace_cnt <= pace_cnt + 1;
         end if; 
         
         if stall = '0' then -- only update the waveform if not stalling
            if pace_cnt = clk_l2h_pnt then 
               pace_clk_wave <= '1';
            elsif pace_cnt = clk_h2l_pnt then 
               pace_clk_wave <= '0';   
            end if;
         end if;  
      end if;      
      
   end if;
end process;   



--
-- SPI stall logic. Some devices require a stall at a certain byte position
-- for a certain duration in clocks. This logic supports that.
--

process(clk,arst)
begin
   if arst = g_arst_pol then          
      stall     <= '0';
      stall_cnt <= 0;
   elsif clk'event and clk = '1' then
      if (delay_enb = '1') and (load_data_pls = '1') and             -- Qualify when to start the count to line up correctly with inactive clock state
         (((conv_integer('0'&delay_byte_pos) = dly_byte_count) and (conv_integer('0'&delay_byte_pos) /= 0)) or
          (conv_integer('0'&delay_byte_pos) = 0)) and
         (conv_integer('0'&bit_pos_cnt) = 7) and (conv_integer('0'&delay_time_spi_clks) /= 0) 
      then
         stall <= '1';
         stall_cnt <= conv_integer('0'&(delay_time_spi_clks-1));      
      elsif pace_tick = '1' and stall_cnt = 0 then
         stall <= '0';
      elsif pace_tick = '1' and stall_cnt > 0 then
         stall_cnt <= stall_cnt - 1;
      end if;                                           
   end if;
end process;   
   

--
-- SPI Slave fsm. This could be reduced to 3 state but this makes it explicit so easy expand later.
--
process(clk,arst)
begin
   if arst = g_arst_pol then    
   
      spi_ss_n_sig <= '1';           
      spi_state    <= s_spi_wait_for_msg_rdy;                          
                                                                   
   elsif clk'event and clk = '1' then
      if pace_tick = '1' and stall = '0' then
   
         case spi_state is 
            when s_spi_wait_for_msg_rdy =>
               if spi_tx_msg_rdy = '1' then     
                  if ss_to_clk_gap = "0001" then 
                     ss_to_clk_gap_cnt <= 30;    -- add more later as needed                  
                  else
                     ss_to_clk_gap_cnt <= 0;                    
                  end if;        
                  spi_ss_n_sig   <= '0';
                  spi_state      <=  s_wait_ss_to_clk_gap;                 
               end if;
            
            when s_wait_ss_to_clk_gap =>
               if ss_to_clk_gap_cnt > 0 then
                  ss_to_clk_gap_cnt <= ss_to_clk_gap_cnt - 1;
               end if;
               if ss_to_clk_gap_cnt = 0 then                                             
                  spi_state <= s_spi_assert_ss;
               end if;                                     
            
            when s_spi_assert_ss =>
               spi_state <= s_spi_send_data;
            
            when s_spi_send_data => 
               if (conv_integer('0'&bit_pos_cnt) = 7 and conv_integer('0'&msg_byte_ptr) = 1) then -- last data bit of last byte shifted out                 
                  if clk_to_ss_gap = "0001" then 
                      clk_to_ss_gap_cnt <= 60;    -- add more later as needed                  
                  else
                      clk_to_ss_gap_cnt <= 0;                      
                  end if;                          
                  spi_state <= s_wait_clk_to_ss_gap;                               
               end if;
               
            when s_wait_clk_to_ss_gap =>
               if clk_to_ss_gap_cnt > 0 then
                  clk_to_ss_gap_cnt <= clk_to_ss_gap_cnt - 1;
               end if;
               if clk_to_ss_gap_cnt = 0 then  
                  spi_ss_n_sig <= '1'; 
                  spi_state    <= s_spi_done;   
               end if;   
                               
            
            when s_spi_done =>
               spi_state <= s_spi_wait_for_msg_rdy;
                  
            when others =>
               null;
                     
         end case;                                                                                                  
      end if;   
   end if;
   
end process;

   
spi_ss_n <= spi_ss_n_sig;

--
-- Manage the data shift register and bit counters
-- 
-- Request a data byte at approproate times to load the SPI TX shift register            
spi_tx_msg_rd_ack_sig <= '1' when --((spi_state = s_spi_load_first_byte) or
                                   ((spi_state = s_wait_ss_to_clk_gap and ss_to_clk_gap_cnt = 0) or    
                                    (spi_state = s_spi_send_data and (conv_integer('0'&bit_pos_cnt) = 7) and conv_integer('0'&msg_byte_ptr) /= 1)) and pace_tick = '1' and stall = '0' else '0';
                                  
spi_tx_msg_rd_ack     <= spi_tx_msg_rd_ack_sig;

-- Send pulse after the message is sent
spi_tx_msg_sent_pls <= '1' when spi_state = s_spi_done and pace_tick = '1' and stall = '0' else '0';

-- Send either MSB or LSB first based on port setting
spi_tx_msg_data_remapped <= spi_tx_msg_data when tx_lsb_first = '0' else spi_tx_msg_data(0)&
                                                                         spi_tx_msg_data(1)&
                                                                         spi_tx_msg_data(2)&
                                                                         spi_tx_msg_data(3)&
                                                                         spi_tx_msg_data(4)&
                                                                         spi_tx_msg_data(5)&
                                                                         spi_tx_msg_data(6)&
                                                                         spi_tx_msg_data(7);

process(clk,arst)
begin
   if arst = g_arst_pol then
      tx_data_sr      <= (others => '0');
      bit_pos_cnt     <= (others => '0');
      msg_byte_ptr    <= (others => '0');  
      dly_byte_count  <= 0;
      
      load_cnts_pls   <= '0';
      spi_clk_en      <= '0';
      --spi_clk_en_r    <= '0';
   elsif clk'event and clk = '1' then
      if pace_tick = '1' and stall = '0' then        
         load_cnts_pls   <= '0';     
         if spi_state = s_spi_wait_for_msg_rdy and spi_tx_msg_rdy = '1' then -- create a delayed version to align with data from a request based fifo      
            load_cnts_pls   <= '1';     
         end if;
         
         if load_cnts_pls = '1' then 
            dly_byte_count <= 1;
            bit_pos_cnt  <= (others => '0');
            if conv_integer('0'&spi_tx_msg_len) = 0 then -- Okay, 0 means 1024 bytes so set the count to 1024.
               msg_byte_ptr <= conv_std_logic_vector(1024,msg_byte_ptr'length);
            else   
               msg_byte_ptr <= '0'&spi_tx_msg_len;
            end if;                  
         else
            if spi_state = s_spi_send_data then
               bit_pos_cnt <= bit_pos_cnt + 1;
               if conv_integer('0'&bit_pos_cnt) = 7 then
                  msg_byte_ptr   <= msg_byte_ptr - 1;
                  dly_byte_count <= dly_byte_count +1;
               end if; 
            end if;            
         end if;           
         --
         -- Setup and control the TX data shift register
         --
         if load_data_pls = '1' then
            tx_data_sr <= spi_tx_msg_data_remapped;
         elsif spi_state = s_spi_send_data then
            tx_data_sr <= tx_data_sr(6 downto 0)&'0'; 
         end if;
         
         if (spi_state = s_spi_assert_ss) or ((spi_state = s_spi_send_data) and not(conv_integer('0'&bit_pos_cnt) = 7 and conv_integer('0'&msg_byte_ptr) = 1)) then
            spi_clk_en <= '1';
         else
            spi_clk_en <= '0';
         end if; 
         
         --spi_clk_en_r <= spi_clk_en;
      end if;
              
   end if;
end process;

--
-- Data gets loaded into the shift register initally at the start 
-- and then after the current byte is shifted out.
-- 
load_data_pls <= '1' when spi_tx_msg_rd_ack_sig = '1' and (spi_state /= s_spi_wait_for_msg_rdy) else '0';   

spi_mosi <= tx_data_sr(tx_data_sr'left);


--
-- Process output clock control
--
process(clk,arst)
begin
   if arst = g_arst_pol then
      spi_sclk_sig <= '0';
   elsif clk'event and clk = '1' then
      if stall = '0' then
         if spi_clk_en = '1' then
            case conv_integer('0'&pace) is 
               when 0 =>
                  if spi_clk_pol = '1' then
                     spi_sclk_sig <= not(pace_tick);
                  else
                     spi_sclk_sig <= pace_tick;
                  end if;
               when others =>
                  if spi_clk_pol = '1' then
                     spi_sclk_sig <= pace_clk_wave;
                  else
                     spi_sclk_sig <= not(pace_clk_wave);
                  end if;                                                
            end case;       
         
         else
            case conv_integer('0'&pace) is 
               when others =>
                  if spi_clk_pol = '1' then
                     spi_sclk_sig <= '0';
                  else
                     spi_sclk_sig <= '1';
                  end if;
            end case;       
         end if;
      end if;   
   end if;
end process;  

spi_sclk <= spi_sclk_sig;


--
-- Shift in the MISO data and send pulses to higher layers for every byte recived
--
process(clk,arst)
begin
   if arst = g_arst_pol then
      miso_shift_reg        <= (others => '0');
      miso_bit_cnt          <= 0;     
      spi_rx_msg_wr_ack_sig <= '0';
   elsif clk'event and clk = '1' then
   
      spi_rx_msg_wr_ack_sig <= '0'; 
      
      if load_cnts_pls = '1' then -- reset the bit pointer befor each xfer
         miso_bit_cnt <= 0;
      else
         if conv_integer('0'&pace) /= 0 then
            if samp_miso_pls = '1' then  
               miso_shift_reg <= miso_shift_reg(miso_shift_reg'left-1 downto 0)&spi_miso; -- left shift in, at end of bits the MSB will be the MSB of byte
               if miso_bit_cnt >= 7 then 
                  spi_rx_msg_wr_ack_sig <= '1';
                  miso_bit_cnt          <= 0;
               else
                  miso_bit_cnt <= miso_bit_cnt + 1;
               end if; 
            end if;
         else -- special case for 1/2 clk rate
            if spi_sclk_sig = spi_clk_pol then                                                                                                                  
               miso_shift_reg <= miso_shift_reg(miso_shift_reg'left-1 downto 0)&spi_miso; -- left shift in, at end of bits the MSB will be the MSB of byte
               if miso_bit_cnt >= 7 then                                                                                                                  
                  spi_rx_msg_wr_ack_sig <= '1';                                                                                                           
                  miso_bit_cnt          <= 0;                                                                                                             
               else                                                                                                                                       
                  miso_bit_cnt <= miso_bit_cnt + 1;                                                                                                       
               end if;                                                                                                                                                
            end if;           
         end if;
      end if;         
   end if;
end process;
   
-- Now assign the outputs
spi_rx_msg_wr_ack <= spi_rx_msg_wr_ack_sig;

-- Mapp to the rx data port. Apply bit reversal is directed to do so                 
spi_rx_msg_data   <= miso_shift_reg when rx_lsb_first = '0' else  miso_shift_reg(0)&
                                                                  miso_shift_reg(1)&
                                                                  miso_shift_reg(2)&
                                                                  miso_shift_reg(3)&
                                                                  miso_shift_reg(4)&
                                                                  miso_shift_reg(5)&
                                                                  miso_shift_reg(6)&
                                                                  miso_shift_reg(7);
                                                                   
 
end; -- rtl


