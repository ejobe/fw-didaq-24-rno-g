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
--*     Single use/project License. Addition use requires written permission.
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
--*   .........      Same                  Added 1024 length transfer mode      
--*                                        Added 16 bit reg addres mode
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity tectonics_i2c_master_core is
  generic(
     g_arst_pol        : std_logic := '0';
     g_input_clk_hz    : integer   := 50_000_000;  --input clock speed from user logic in hz
     g_bus_clk_hz      : integer   := 400_000;     --speed the i2c bus (scl) will run at in hz
     --g_rd_stp_strt     : boolean   := false;       -- If true then insert real stop start in between read phases. For some devices
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
     
     reg_addr              : in     std_logic_vector(15 downto 0); -- Register Address. Use low byte when in 8b reg addr mode
     rwn                   : in     std_logic;                    -- '0' is write, '1' is read
     xfer_len              : in     std_logic_vector(9 downto 0); -- 0 based transfer length. up to 1023 (1024)
     fast_rd               : in     std_logic;                    -- If '1' and a read, will skip writing the register address.
     rd_stp_strt           : in     std_logic;                    -- '1' = insert real stop start in between read addr and first data phase. '0' = just repeated start bit 
                           
     data_wr               : in     std_logic_vector(7 downto 0); -- Data to write to slave
     data_wr_ack           : out    std_logic;                    -- one clock wide puilse to advance the write data for multi byte transfers
                           
                           
     busy                  : out    std_logic;                    -- indicates transaction in progress
     data_rd               : out    std_logic_vector(7 downto 0); -- Data read from slave
     data_rd_valid         : out    std_logic;                    -- Pulse one clock wide for each data value read.
     ack_error             : out    std_logic;                    -- Flag if improper acknowledge from slave
                           
     --sda                 : inout  std_logic;                    -- Serial data output of i2c bus , uncomment if wanting to do tristate in this module level 
     --scl                 : inout  std_logic                     -- Serial clock output of i2c bus, uncomment if wanting to do tristate in this module level 
                           
                           
     sda                   : in   std_logic;                      -- serial data input of i2c bus 
     scl                   : in   std_logic;                      -- serial clock input of i2c bus
                                                                  
                                                                  -- Connect at top level to open collector tristate 
                                                                  -- logic. So if these are high, drive the signal low
                                                                  -- and if these are high then drive 'Z'.
     sda_oe                : out  std_logic;                      -- Active high serial data output  enable 
     scl_oe                : out  std_logic                       -- Active high serial clock output enable 
                           
  );                   
    
    
end tectonics_i2c_master_core;

architecture rtl of tectonics_i2c_master_core is
  constant c_divider  :  integer := (g_input_clk_hz/g_bus_clk_hz)/4; --number of clocks in 1/4 cycle of scl
  type t_i2c_fsm_states is (s_ready, 
                            s_start, 
                            s_chip_addr, 
                            s_slv_chip_addr_ack, 
                            s_wr_reg_addr_or_data, 
                            s_rd, 
                            s_slv_ack_rd,
                            s_slv_ack2, 
                            s_mstr_ack,
                            s_mid_rd_stop,
                            s_mid_rd_stop_end,
                            s_stop);
  
  function hto1(sig : std_logic) return std_logic is
     begin
        if sig = '0' then
           return '0';
        else
           return '1';   
        end if;    
     end function hto1;

  
                            
  signal  i2c_fsm_state    :  t_i2c_fsm_states;                 -- State machine
  signal  data_clk         :  std_logic;                        -- Clock edges for sda
  signal  scl_clk          :  std_logic;                        -- Constantly running internal scl
  signal  scl_ena          :  std_logic;                        -- Enables internal scl to output
  signal  sda_int          :  std_logic;                        -- Internal sda
                        
  signal  chip_addr_rw_lat :  std_logic_vector(7 downto 0);     -- latched in address and read/write, RWN in lowest bit
  signal  reg_addr_lat     :  std_logic_vector(15 downto 0);    -- Latched register address of the location to access in the i2c device 
  signal  data_wr_lat      :  std_logic_vector(7 downto 0);     -- Lateched data to write to the i2c device (if its a write command)
  
  --signal  fast_rd_lat      :  std_logic;
  signal  data_rx          :  std_logic_vector(15 downto 0);     -- Data received from slave
  signal  bit_cnt          :  integer range 0 to 15;             -- Tracks bit number in transaction
  signal  stretch          :  std_logic;                        -- Identifies if slave is stretching scl
                           
  signal ack_error_reg     : std_logic;
                           
                           
  signal scl_io_ena        : std_logic;
  signal sda_io_ena        : std_logic;
                           
  signal scl_clk_r         : std_logic;
  signal data_clk_r        : std_logic;
                           
  --signal scl_clk_ped       : std_logic;                           
  signal data_clk_ped      : std_logic;
  signal data_clk_fed      : std_logic;
                           
  signal scl_in_mr         : std_logic; -- meta register
  signal scl_in_rr         : std_logic;
  
  signal scl_clk_1st_qtr   : std_logic;
  signal scl_clk_1st_qtr_r : std_logic;

  signal scl_clk_2nd_qtr   : std_logic;  
  signal scl_clk_2nd_qtr_r : std_logic;    
  
  type   data_xfer_states  is (s_snd_chp_addr,s_snd_reg_addr,s_snd_wr_data);
  signal data_xfer_state   : data_xfer_states;
                           
  signal rwn_lat           : std_logic;
  
  signal count             : integer range 0 to c_divider*4;
  
  signal ena_lat           : std_logic;
  signal busy_sig          : std_logic;
  
  signal first_start       : std_logic;
  
  signal bytes_left_cnt    : natural range 0 to 1024;   
  
  --signal data_rd_reg       : std_logic_vector(7 downto 0);
  
begin

  --
  -- Generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  --
  process(clk, arst)
    --variable count : integer range 0 to c_divider*4; --timing for clock generation
  begin
    if(arst = g_arst_pol) then               --reset asserted
      stretch    <= '0';
      count      <=   0;
      scl_clk    <= '0';
      data_clk   <= '0';
      
      scl_clk_r  <= '0';
      data_clk_r <= '0';
      
      scl_in_mr  <= '0';
      scl_in_rr  <= '0';
      
      scl_clk_1st_qtr   <= '0';
      scl_clk_1st_qtr_r <= '0';
      
      scl_clk_2nd_qtr   <= '0';
      scl_clk_2nd_qtr_r <= '0';
      
      
    elsif(clk'event and clk = '1') then
    
      scl_in_mr  <= hto1(scl);                     -- sample with first stage, the meta stage (mr)
      scl_in_rr  <= scl_in_mr;               -- This should be in the proper domain without metastability
                                             
                                             
      if(count = c_divider*4-1) then         -- end of timing cycle
        count <= 0;                          -- reset timer
      elsif(stretch = '0') then              -- clock stretching from slave not detected
        count <= count + 1;                  -- continue clock generation timing
      end if;   
      
      scl_clk_1st_qtr <= '0';
      scl_clk_2nd_qtr <= '0';
                                   
      case count is                          
        when 0 to c_divider-1 =>             -- first 1/4 cycle of clocking
          scl_clk <= '0';                       
          data_clk <= '0';  
          scl_clk_1st_qtr <= '1';                    
        when c_divider to c_divider*2-1 =>   -- second 1/4 cycle of clocking
          scl_clk <= '0';                       
          data_clk <= '1';  
          scl_clk_2nd_qtr <= '1';                    
        when c_divider*2 to c_divider*3-1 => -- third 1/4 cycle of clocking
          scl_clk   <= '1';                  -- dk just drive the internal one high, use proper tristate eqn later
          
          if(scl_in_rr = '0') then
            stretch <= '1';
          else
            stretch <= '0';
          end if;
          data_clk <= '1';
        when others =>                   --last 1/4 cycle of clocking          
          scl_clk <= '1';                --just drive the internal one high, use proper tristate eqn later
          data_clk <= '0';
      end case;
      
      scl_clk_r  <= scl_clk;
      data_clk_r <= data_clk;
      scl_clk_1st_qtr_r <= scl_clk_1st_qtr;
      
      scl_clk_2nd_qtr_r <= scl_clk_2nd_qtr;
      
    end if;
  end process;
  
  -- detect rising edges
  --scl_clk_ped  <= not(scl_clk_r)  and     scl_clk;
  data_clk_ped <= not(data_clk_r) and     data_clk;   -- positive edge detect
  data_clk_fed <=     data_clk_r  and not(data_clk);  -- negative edge detect
  
  busy <= busy_sig or ena_lat;
  --
  -- State machine to capture the data from the processor interface and
  -- control the transaction in the I2C bus. 
  -- It captures and deserializes the received data and serializes the TX data
  --
  data_wr_lat <= data_wr; 
  
  process(clk, arst)
  begin
    if(arst = g_arst_pol) then                    -- reset asserted
      i2c_fsm_state    <= s_ready;                   -- return to initial state
      busy_sig         <= '1';                       -- indicate not available
      scl_ena          <= '0';                       -- sets scl high impedance
      sda_int          <= '1';                       -- sets sda high impedance
      bit_cnt          <=  7;                        -- restarts data bit counter
      data_rd          <= (others => '0');           -- clear data read port
      ack_error_reg    <= '0';  
      rwn_lat          <= '0';            
      reg_addr_lat     <= (others => '0');      
     -- data_wr_lat      <= (others => '0');           
      chip_addr_rw_lat <= (others => '0');    
      --fast_rd_lat      <= '0';  
      data_xfer_state  <= s_snd_chp_addr;   --(s_snd_chp_addr,s_snd_reg_addr,s_snd_wr_data)      
      data_rx          <= (others => '0');
      
      ena_lat          <= '0'; 
      
      first_start      <= '0'; 
      
      data_rd_valid    <= '0';          
      
    elsif(clk'event and clk = '1') then  
       if (ena_pls = '1') then
          first_start <= '1';  --11/12/2015
          ena_lat     <= '1';
       elsif i2c_fsm_state = s_stop then
           ena_lat <= '0';       
       end if;
       data_rd_valid <= '0';  
                                        
       if data_clk_ped = '1' then
       
          case i2c_fsm_state is
            when s_ready =>               -- idle state
            
               busy_sig         <= '0';   -- unflag busy
               scl_ena          <= '0';   -- DK added feb/2014
               sda_int          <= '1';   -- DK added feb/2014
               bit_cnt          <=  7;    -- DK added feb/2014               
               
               if(ena_lat = '1') then            -- transaction requested
                  busy_sig         <= '1';                    -- flag busy
                  ack_error_reg    <= '0';
                  rwn_lat          <= rwn; 
                  if (reg_addr_msbyte_first = '1') or (reg_addr_16b_enb = '0') then                                      
                     reg_addr_lat     <= reg_addr;
                  else
                     reg_addr_lat <= reg_addr(7 downto 0) &  reg_addr(15 downto 8);
                  end if;
                  --data_wr_lat      <= data_wr;  
                  if rwn = '1' then --check if fast read, if so setup to skip the register address write phase                                           
                     chip_addr_rw_lat <= chip_addr & ('0' or fast_rd); -- Fast read will force he logic to not preform a register loc write phase
                  else
                     chip_addr_rw_lat <= chip_addr & '0'; 
                  end if;
                  --fast_rd_lat      <= fast_rd;
                  data_xfer_state  <= s_snd_chp_addr;
                  i2c_fsm_state    <= s_start;    -- go to start bit
               --else                              -- remain idle
               --   busy_sig <= '0';                    -- unflag busy
               --   i2c_fsm_state <= s_ready;       -- remain idle
               end if;
              
            when s_start =>                     -- start bit of transaction
              scl_ena <= '1';                   -- enable scl output
              sda_int <= chip_addr_rw_lat(bit_cnt);      -- set first address bit to bus
              i2c_fsm_state <= s_chip_addr;       -- go to command
              first_start   <= '0';
              
            when s_chip_addr =>                   -- address and command byte of transaction
              if(bit_cnt = 0) then              -- command transmit finished
                sda_int <= '1';                 -- release sda for slave acknowledge
                if reg_addr_16b_enb = '1' then -- 16-bit reg address so set to 15
                   bit_cnt <= 15;                   -- reset bit counter for "word" send 
                else
                   bit_cnt <= 7;                   -- reset bit counter for "byte" send
                end if;   
               
                i2c_fsm_state <= s_slv_chip_addr_ack;    -- go to slave acknowledge (command)
              else                              -- next clock cycle of command state
                bit_cnt <= bit_cnt - 1;         -- keep track of transaction bits
                sda_int <= chip_addr_rw_lat(bit_cnt-1);  -- write address/command bit to bus
                i2c_fsm_state <= s_chip_addr;     -- continue with command
              end if;
              
            when s_slv_chip_addr_ack =>                    -- slave acknowledge bit (command)
              if rwn_lat = '0' or (rwn_lat = '1' and chip_addr_rw_lat(0) = '0') then  -- write command or read but still needing to send the reg addr
                sda_int         <= reg_addr_lat(bit_cnt); -- write first bit of i2C device register address, could be 16 bit or 8 bit
                data_xfer_state <= s_snd_reg_addr;  
                i2c_fsm_state   <= s_wr_reg_addr_or_data;            -- go to write byte
              else                                -- read command
                sda_int <= '1';                   -- release sda from incoming data 
                bit_cnt <= 7;
                i2c_fsm_state <= s_rd;            -- go to read byte
              end if;
              
            when s_wr_reg_addr_or_data =>       -- write byte (or last byte of addr if 16b mode) of transaction, could be a register address or actual write data
            
              if ((bit_cnt = 8) and (reg_addr_16b_enb = '1')) then -- first byte of the 16 reg addr has been sent 
                 sda_int <= '1'; -- release sda for slave acknowledge
                 bit_cnt <= 7;   -- set for the msbit of last byte of the register address
                 i2c_fsm_state <= s_slv_chip_addr_ack; -- reuse this state as if its the first address byte in order to send the second
                 
              elsif (bit_cnt = 0) then             -- write byte transmit finished
                sda_int <= '1';                 -- release sda for slave acknowledge
                bit_cnt <= 7;                   -- reset bit counter for "byte" states
                               
                case data_xfer_state is
                   when s_snd_reg_addr =>
                      if rwn_lat = '1' then  -- finished sending the register address for a read, need to restart after the ack
                         data_xfer_state <= s_snd_chp_addr;
                         chip_addr_rw_lat(0) <= '1';
                      else
                         data_xfer_state <= s_snd_wr_data;   -- okay, the register address was sent now send the data
                      end if;
                         
                   when s_snd_wr_data =>
                      if bytes_left_cnt = 0 then --if no more to send then leave the s_snd_wr_data, esle stay in this transfer state
                         data_xfer_state <= s_snd_chp_addr;    -- okay, the data to write to the register was sent now back to start
                      end if;   
                   when others =>
                      data_xfer_state <= s_snd_chp_addr;    -- Done with sending reg address and data to write to that address
                end case;                
                
                i2c_fsm_state <= s_slv_ack2;    -- go to slave acknowledge (write)
                
              else                              -- next clock cycle of write state
                bit_cnt <= bit_cnt - 1;         -- keep track of transaction bits
                
                -- Select what data it sent during the write phases
                case data_xfer_state is
                   when s_snd_reg_addr =>
                      sda_int <= reg_addr_lat(bit_cnt-1);  -- write next bit to bus
                   when s_snd_wr_data =>
                      sda_int <= data_wr_lat(bit_cnt-1);  -- write next bit to bus
                   when others =>
                      sda_int <= '0';                 -- should never happen
                end case;   
                                   
              end if;
              
              
            when s_rd =>                        -- read byte of transaction

              if(bit_cnt = 0) then              -- read byte receive finished
                if(ena_lat = '1' and rwn = '1') and g_assert_mstr_ack then -- continuing with another read                 
                  sda_int <= '0';               -- acknowledge the byte has been received
                else                            -- stopping or continuing with a write
                  sda_int <= '1';               -- send a no-acknowledge (before stop or repeated start)
                end if;
                bit_cnt <= 7;                   -- reset bit counter for "byte" states
                data_rd <= data_rx(7 downto 0);  -- output received data
                data_rd_valid <= '1';
                if bytes_left_cnt > 0 then -- this is a multibyte transfer
                   i2c_fsm_state <= s_slv_ack_rd;
                   sda_int       <= '0';           -- Need to ack all but the last transfer in a multi byte transfer
                else
                   i2c_fsm_state <= s_mstr_ack;    -- go to master acknowledge
                end if;   
              else                              -- next clock cycle of read state
                bit_cnt <= bit_cnt - 1;         -- keep track of transaction bits
                i2c_fsm_state <= s_rd;          -- continue reading
              end if;
              
            when s_slv_ack_rd =>                -- Ack in a continued read of multiple bytes without restart    
               sda_int       <= '1';            -- Release the ack   
               i2c_fsm_state <= s_rd;           -- Back to read the next byte. If last byte then nack
              
              
            when s_slv_ack2 =>                  -- slave acknowledge bit (write)
                  
               -- write first bit of data for the data phase currently in
               case data_xfer_state is
                  when s_snd_reg_addr =>
                     sda_int       <= reg_addr_lat(bit_cnt);  -- write next bit to bus
                     i2c_fsm_state <= s_wr_reg_addr_or_data; 
                  when s_snd_wr_data =>
                     sda_int       <= data_wr_lat(bit_cnt);  -- write next bit to bus
                     i2c_fsm_state <= s_wr_reg_addr_or_data; 
                  when s_snd_chp_addr =>
                     if rwn_lat = '0' then -- was a write, sent the data, finish up.
                        scl_ena <= '0';                 -- disable scl      
                        i2c_fsm_state <= s_stop;        -- go to stop bit 
                     else  -- was a read, need to resend the start bit
                        --if not(g_rd_stp_strt) then
                        if rd_stp_strt = '0' then -- just send repeated start (not a stop first then start) 
                           scl_ena <= '0';         
                           i2c_fsm_state <= s_start;
                        else -- need to send stop first then start
                           scl_ena <= '0';
                           i2c_fsm_state <= s_mid_rd_stop;
                        
                        end if;   
                     end if;                   
               end case;                   
            
            when s_mid_rd_stop => --DK new to insert stop/start in for some devies
               sda_int <= '1'; 
               i2c_fsm_state <= s_mid_rd_stop_end;
            when s_mid_rd_stop_end =>           
               i2c_fsm_state <= s_start;
            
              
            when s_mstr_ack =>                  -- master acknowledge bit after a read

               sda_int <= '1';                  -- DK added apr/11/2015 complete transaction
               scl_ena <= '0';                  -- disable scl
               i2c_fsm_state <= s_stop;         -- go to stop bit
              

            when s_stop =>                      -- stop bit of transaction
              busy_sig <= '0';                      -- unflag busy
              sda_int  <= '1';                   -- DK apr/05/2015, clean this up a little more
              i2c_fsm_state <= s_ready;         -- go to ready state

          end case;    
       end if;

       if data_clk_fed = '1' then
          case i2c_fsm_state is
            when s_start =>                          -- starting new transaction
              ack_error_reg <= '0';                  -- reset acknowledge error flag
            when s_slv_chip_addr_ack =>                       -- receiving slave acknowledge (command)
              ack_error_reg <= hto1(sda) or ack_error_reg; -- set error output if no-acknowledge
            when s_rd =>                             -- receiving slave data
              data_rx(bit_cnt) <= hto1(sda);               -- receive current slave data bit
            when s_slv_ack2 =>                       -- receiving slave acknowledge (write)
              ack_error_reg <= hto1(sda) or ack_error_reg; -- set error output if no-acknowledge
            when others =>
              null;
          end case;
       end if;
    end if;
    
  end process;  

  -- Assign the ack error output
  ack_error <= ack_error_reg; 
  
  --
  -- Counter to track the number bytes processed
  --                                     
  process(clk, arst)
  begin
     if(arst = g_arst_pol) then
        bytes_left_cnt <= 0;    
        data_wr_ack <= '0';                                              
     elsif(clk'event and clk = '1') then      
        data_wr_ack   <= '0';
        
        if (ena_pls = '1') and i2c_fsm_state = s_ready then
           bytes_left_cnt <= conv_integer('0'&xfer_len) + 1; -- latch the requested data count
        else
           
           if (((i2c_fsm_state  = s_wr_reg_addr_or_data) and (data_xfer_state = s_snd_wr_data) and (data_clk_ped = '1') and (bit_cnt = 1)) or
              ((i2c_fsm_state = s_rd) and (bit_cnt = 1) and (data_clk_ped = '1'))) then -- dec counter one earlier to make successive byte pending easier to detect earier 
              if bytes_left_cnt > 0 then
                 bytes_left_cnt <= bytes_left_cnt - 1;
              end if; 
           end if;
           
           if (i2c_fsm_state  = s_wr_reg_addr_or_data) and (data_xfer_state = s_snd_wr_data) and (data_clk_ped = '1') and (bit_cnt = 0) then
              data_wr_ack <= '1';
           end if;     
                                                          
        end if;
     end if;
  end process;     
    
  
   
  
  --
  -- Control the outputs
  --
  
  process(clk,arst)
  begin
     if arst = g_arst_pol then
        scl_io_ena <= '0';
        sda_io_ena <= '0';
        
     elsif clk'event and clk = '1' then
        --if (scl_ena = '1' and scl_clk_r = '0') or (scl_clk_1st_qtr_r = '1' and i2c_fsm_state = s_start) or (scl_clk_2nd_qtr_r = '1' and ((i2c_fsm_state = s_stop) or(i2c_fsm_state = s_mid_rd_stop)))   then
        -- 11/12/2015 added (scl_clk_2nd_qtr_r = '1' and i2c_fsm_state = s_start)
        if (scl_ena = '1' and scl_clk_r = '0') or (scl_clk_1st_qtr_r = '1' and i2c_fsm_state = s_start) or (scl_clk_2nd_qtr_r = '1' and i2c_fsm_state = s_start and first_start = '0') or (scl_clk_2nd_qtr_r = '1' and ((i2c_fsm_state = s_stop) or(i2c_fsm_state = s_mid_rd_stop)))   then

           scl_io_ena <= '1';
        else
           scl_io_ena <= '0';
        end if;   
        
        if (i2c_fsm_state = s_start and data_clk_r = '0') or ((i2c_fsm_state = s_stop or i2c_fsm_state = s_mid_rd_stop) and data_clk_r = '1') or sda_int = '0' then
           sda_io_ena <= '1';
        else 
           sda_io_ena <= '0';
        end if;                 
     end if;         
  end process;
  
  -- Tristate control if internal tristate control to this module
  --scl <= '0' when scl_io_ena = '1' else 'Z'; 
  --sda <= '0' when sda_io_ena = '1' else 'Z';
  
  -- For external (to the level of this module) tristate control
  scl_oe <= scl_io_ena;
  sda_oe <= sda_io_ena;
  
end rtl;
