------
--didaq simple beamformer/trigger | EJO
--// assume vpol string looks like this (maybe make this mux-able)
--//  ch3  |<-
--//  ch2    |<-
--//  ch1      |<-
--//  ch0        |<-  
------
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
use work.pow_lut.all;

entity beamforming_trig is
	port(
		arstn        : in   std_logic;  -- reset low
      clk			 : in   std_logic;  --clock for data							
		data0			 : in	  std_logic_Vector(63 downto 0);	--8 samples of 8 bit data
		data1			 : in	  std_logic_Vector(63 downto 0);					
		data2			 : in	  std_logic_Vector(63 downto 0);
		data3			 : in	  std_logic_Vector(63 downto 0);	
		--//following are assumed to be already registered on input clk domain to this module
		beamform_en	 : in	  std_logic_vector(1 downto 0);
		chan_mask	 : in	  std_logic_vector(3 downto 0);
		beam_mask	 : in	  std_logic_vector(11 downto 0);
		gain_ctrl_sel: in	  std_logic;
		pow_width_sel: in	  std_logic;	 
		thresh0	 	 : in	  std_logic_vector(31 downto 0); --combine servo and trigger thresholds into same port
		thresh1	 	 : in	  std_logic_vector(31 downto 0);
		thresh2	 	 : in	  std_logic_vector(31 downto 0);
		thresh3	 	 : in	  std_logic_vector(31 downto 0);
		thresh4	 	 : in	  std_logic_vector(31 downto 0);
		thresh5	 	 : in	  std_logic_vector(31 downto 0);
		thresh6	 	 : in	  std_logic_vector(31 downto 0);
		thresh7	 	 : in	  std_logic_vector(31 downto 0);
		thresh8	 	 : in	  std_logic_vector(31 downto 0);
		thresh9	 	 : in	  std_logic_vector(31 downto 0);

		last_trigger_beam_power : std_logic_vector(15 downto 0);
		last_trigger_hit_pattern_o : out std_logic_Vector(9 downto 0);
		beamtrigs_o	 : out  std_logic_Vector(9 downto 0); --for scalers, single-shot pulses on clk
		beamservos_o :	out  std_logic_Vector(9 downto 0); 
		trig_o		 : out  std_logic --the trigger
);
end entity beamforming_trig;
---------------------
architecture rtl of beamforming_trig is
---------------------
constant limited_bits : integer := 5;
constant native_bits		: integer := 8;
constant coh_sum_bits	: integer := 7;
constant slice_offset : integer := 128; 
constant samples_per_clock : integer := 8;
constant num_beams : integer := 10;
constant masked_data : std_logic_Vector(63 downto 0) := x"8080808080808080";
-----
type streaming_data_type is array(0 to 3) of std_logic_vector(48*native_bits-1 downto 0); --8 bit sample width, but info limited to 5 bits/sample
type input_data_type is array(0 to 3) of std_logic_vector(63 downto 0);
type coherent_sum_data_type is array(0 to num_beams-1) of std_logic_vector(55 downto 0); --7 bits/sample
type coherent_sum_pipeline_type is array(0 to num_beams-1) of std_logic_vector(111 downto 0); --7 bits/sample
type instantaneous_power_type is array(0 to num_beams-1, 0 to 7) of std_logic_vector(2*coh_sum_bits-1 downto 0);
type summed_power_type is array(0 to num_beams-1) of std_logic_Vector(15 downto 0);
type summed_power_pipeline_type is array(0 to num_beams-1) of std_logic_Vector(3 downto 0); 
type threshold_array_type is array(0 to num_beams-1) of std_logic_Vector(15 downto 0);
type beam_trig_state_reg_type is array(0 to num_beams-1) of std_logic_Vector(1 downto 0);
-----
signal streaming_data : streaming_data_type;
signal limited_bit_data : input_data_type;
signal input_data : input_data_type;
signal coherent_sums : coherent_sum_data_type;
signal coherent_sums_pipeline : coherent_sum_pipeline_type;
signal instantaneous_beam_power : instantaneous_power_type;
signal summed_power_0 : summed_power_type;
signal summed_power_1 : summed_power_type;
signal trig_tracker : summed_power_pipeline_type;  -- keeps track of the sums-over-threshold 
signal servo_tracker : summed_power_pipeline_type; -- keeps track of the sums-over-threshold
signal trig_thresh : threshold_array_type;
signal servo_thresh : threshold_array_type;
-----
signal beam_trig_state_reg : beam_trig_state_reg_type; --fsm for handling triggers/holdoffs
signal beam_servo_state_reg : beam_trig_state_reg_type; --fsm for handling triggers/holdoffs
-----
signal beam_trigs 	: std_logic_Vector(0 to num_beams-1);
signal beam_servos 	: std_logic_Vector(0 to num_beams-1);
signal beam_trigs_to_output 	: std_logic_Vector(0 to num_beams-1);
signal beam_servos_to_output 	: std_logic_Vector(0 to num_beams-1);
signal internal_beam_mask : std_logic_Vector(0 to num_beams-1);
signal trig_beam_pattern : std_logic_Vector(0 to num_beams-1);
signal trig_beam_pattern_pipe : std_logic_Vector(0 to num_beams-1);
signal holdoff_beam_trigs : std_logic_Vector(0 to num_beams-1); --don't allow other beams to trig in small hold-off period (2 clk cycles)
signal holdoff_beam_servos : std_logic_Vector(0 to num_beams-1); 

---------------------------------------------------------------------------
begin
process(arstn, clk)
begin
	if arstn = '0' then
		for i in 0 to num_beams-1 loop
			trig_thresh(i) 	<= x"FFFF";
			servo_thresh(i)	<= x"FFFF";
		end loop;
	elsif clk'event and clk = '1' then
		trig_thresh(0) <= thresh0(15 downto 0);
		trig_thresh(1) <= thresh1(15 downto 0);
		trig_thresh(2) <= thresh2(15 downto 0);
		trig_thresh(3) <= thresh3(15 downto 0);
		trig_thresh(4) <= thresh4(15 downto 0);
		trig_thresh(5) <= thresh5(15 downto 0);
		trig_thresh(6) <= thresh6(15 downto 0);
		trig_thresh(7) <= thresh7(15 downto 0);
		trig_thresh(8) <= thresh8(15 downto 0);
		trig_thresh(9) <= thresh9(15 downto 0);
		servo_thresh(0) <= thresh0(31 downto 16);
		servo_thresh(1) <= thresh1(31 downto 16);
		servo_thresh(2) <= thresh2(31 downto 16);
		servo_thresh(3) <= thresh3(31 downto 16);
		servo_thresh(4) <= thresh4(31 downto 16);
		servo_thresh(5) <= thresh5(31 downto 16);
		servo_thresh(6) <= thresh6(31 downto 16);
		servo_thresh(7) <= thresh7(31 downto 16);
		servo_thresh(8) <= thresh8(31 downto 16);
		servo_thresh(9) <= thresh9(31 downto 16);
	end if;
end process;
---------------------
process(arstn, clk)
begin   		--//streaming data vector has 32 samples, or ~32 ns width
	if arstn = '0' then
		streaming_data 	<= (others=>(others=>'0'));
		limited_bit_data 	<= (others=>(others=>'0'));
	
	elsif clk'event and clk = '1' and beamform_en(0) = '0' then
		streaming_data 	<= (others=>(others=>'0'));
		limited_bit_data 	<= (others=>(others=>'0'));
		
	elsif clk'event and clk = '1' then
		for i in 0 to 3 loop
			--------------------
			-->> pipelining: input 8 samples/clock, streaming_data buffer has 48 samples to access per clock--> 
			streaming_data(i)(383 downto 320) <= streaming_data(i)(319 downto 256); --oldest data (access to DELAY)
			streaming_data(i)(319 downto 256) <= streaming_data(i)(255 downto 192); 
			streaming_data(i)(255 downto 192) <= streaming_data(i)(191 downto 128); 
			streaming_data(i)(191 downto 128) <= streaming_data(i)(127 downto 64);
			streaming_data(i)(127 downto 64)  <= streaming_data(i)(63 downto 0); 
			streaming_data(i)(63 downto 0)    <= limited_bit_data(i); --newest data (access to ADVANCE)
			--------------------
			--slice off lower 5 bits [4..0]
			if gain_ctrl_sel = '0' then
				for j in 0 to 7 loop			
					if input_data(i)((j+1)*native_bits-1 downto j*native_bits) < 112 then
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= "01110000";
					elsif input_data(i)((j+1)*native_bits-1 downto j*native_bits) > 143 then
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= "10001111";
					else 
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= input_data(i)((j+1)*native_bits-1 downto j*native_bits);
					end if;
				end loop;	
			--slice off [5..1] bits [divide-by-two]
			else
				for j in 0 to 7 loop			
					if '0' & input_data(i)((j+1)*native_bits-1 downto j*native_bits+1) < 48 then
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= "00110000";
					elsif '0' & input_data(i)((j+1)*native_bits-1 downto j*native_bits+1) > 79 then
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= "01001111";
					else 
						limited_bit_data(i)((j+1)*native_bits-1 downto j*native_bits) <= '0' & input_data(i)((j+1)*native_bits-1 downto j*native_bits+1);
					end if;
				end loop;
			end if;
		end loop;
		----------------------------------
		-- reorder data based on mapping into ADC chip, maybe make this mux-able in the future //|| double check generic set in didaq_acq_and_trig ||
		----------------------------------
		if chan_mask(1) = '1' then
			input_data(0) <= data1;		--bottom antenna
		else
			input_data(0) <= masked_data;
		end if;
		---
		if chan_mask(0) = '1' then
			input_data(1) <= data0;		
		else
			input_data(1) <= masked_data;
		end if;		
		---
		if chan_mask(3) = '1' then
			input_data(2) <= data3;		
		else
			input_data(2) <= masked_data;
		end if;	
		---
		if chan_mask(2) = '1' then
			input_data(3) <= data2;	  --top antenna	
		else
			input_data(3) <= masked_data;
		end if;	
		---
	end if;
end process;
---------------------
-- delay-and-sum here --
--     due to staggered fibers, ch(0) will inherently have extra delay (~1m fiber -> 5ns) than ch(1), and so-on
--     As such, a beam made from 0-delays from all channels will actually appear as an up-going impulse
--                [delays from extra fiber will null out delays from impacting wave, which hits lowest antenna first]
--
--              to delay, access higher-side of streaming_data relative to offset (oldest data)
--              to advance, access lower-side of streaming_data relative to offset (newest data)
---------------------
process(arstn, clk)
begin
	if arstn = '0' then
		coherent_sums <= (others=>(others=>'0'));
		coherent_sums_pipeline <= (others=>(others=>'0'));
	elsif clk'event and clk = '1' and beamform_en(0) = '0' then
		coherent_sums <= (others=>(others=>'0'));
		coherent_sums_pipeline <= (others=>(others=>'0'));
	elsif clk'event and clk = '1' then
		------------------
		for j in 0 to num_beams-1 loop
			--pipeline, make available 16 samples in coherent sums / clk
			coherent_sums_pipeline(j)(coh_sum_bits*16-1 downto coh_sum_bits*8) <= coherent_sums_pipeline(j)(coh_sum_bits*8-1 downto 0);
			coherent_sums_pipeline(j)(coh_sum_bits*8-1 downto 0) <= coherent_sums(j); 
		end loop;
		------------------
		for i in 0 to samples_per_clock-1 loop
			------------------
			--coherent sums is array of beams, each with 8 samples / clk [64 bits total / clk]
			------------------
			------0 delay (steepest up-going-event receptive beam) ~ -57 degree elevation
			coherent_sums(0)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits));
			------+1 delay ~ -42 degree elevation
			coherent_sums(1)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-1)*native_bits+limited_bits+slice_offset-1 downto (i-1)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+1)*native_bits+limited_bits+slice_offset-1 downto (i+1)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+2)*native_bits+limited_bits+slice_offset-1 downto (i+2)*native_bits+slice_offset)), coh_sum_bits));
			------+2 delay ~ -30 degree elevation
			coherent_sums(2)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-2)*native_bits+limited_bits+slice_offset-1 downto (i-2)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+2)*native_bits+limited_bits+slice_offset-1 downto (i+2)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+4)*native_bits+limited_bits+slice_offset-1 downto (i+4)*native_bits+slice_offset)), coh_sum_bits));
			------+3 delay ~ -20 degree elevation
			coherent_sums(3)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-3)*native_bits+limited_bits+slice_offset-1 downto (i-3)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+3)*native_bits+limited_bits+slice_offset-1 downto (i+3)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+6)*native_bits+limited_bits+slice_offset-1 downto (i+6)*native_bits+slice_offset)), coh_sum_bits));
			------+4 delay ~ -10 degree elevation
			coherent_sums(4)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-4)*native_bits+limited_bits+slice_offset-1 downto (i-4)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+4)*native_bits+limited_bits+slice_offset-1 downto (i+4)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+8)*native_bits+limited_bits+slice_offset-1 downto (i+8)*native_bits+slice_offset)), coh_sum_bits));
			------+5 delay --> this should roughly be the on-boresight beam
			coherent_sums(5)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-5)*native_bits+limited_bits+slice_offset-1 downto (i-5)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+5)*native_bits+limited_bits+slice_offset-1 downto (i+5)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+10)*native_bits+limited_bits+slice_offset-1 downto (i+10)*native_bits+slice_offset)), coh_sum_bits));
			------+6 delay 
			coherent_sums(6)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-6)*native_bits+limited_bits+slice_offset-1 downto (i-6)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+6)*native_bits+limited_bits+slice_offset-1 downto (i+6)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+12)*native_bits+limited_bits+slice_offset-1 downto (i+12)*native_bits+slice_offset)), coh_sum_bits));
			------+7 delay 
			coherent_sums(7)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-7)*native_bits+limited_bits+slice_offset-1 downto (i-7)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+7)*native_bits+limited_bits+slice_offset-1 downto (i+7)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+14)*native_bits+limited_bits+slice_offset-1 downto (i+14)*native_bits+slice_offset)), coh_sum_bits));
			------+8 delay 
			coherent_sums(8)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-8)*native_bits+limited_bits+slice_offset-1 downto (i-8)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+8)*native_bits+limited_bits+slice_offset-1 downto (i+8)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+16)*native_bits+limited_bits+slice_offset-1 downto (i+16)*native_bits+slice_offset)), coh_sum_bits));
			------+9 delay (steepest down-going-event receptive beam)
			coherent_sums(9)((i+1)*coh_sum_bits-1 downto i*coh_sum_bits) <= 	
				std_logic_vector(resize(signed(streaming_data(0)((i-9)*native_bits+limited_bits+slice_offset-1 downto (i-9)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(1)((i+0)*native_bits+limited_bits+slice_offset-1 downto (i+0)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(2)((i+9)*native_bits+limited_bits+slice_offset-1 downto (i+9)*native_bits+slice_offset)), coh_sum_bits)) + 
				std_logic_vector(resize(signed(streaming_data(3)((i+18)*native_bits+limited_bits+slice_offset-1 downto (i+18)*native_bits+slice_offset)), coh_sum_bits));
		end loop;				
	end if;
end process;
-----------------------------
--power calculation / thresholding
process(arstn, clk)
begin
	if arstn = '0' then
		instantaneous_beam_power 	<= (others=>(others=>((others=>'0'))));
		summed_power_0 				<= (others=>(others=>'0'));
		summed_power_1 				<= (others=>(others=>'0'));
		trig_tracker					<= (others=>(others=>'0'));
		servo_tracker					<= (others=>(others=>'0'));
		beam_trigs 						<= (others=>'0');
		beam_servos 					<= (others=>'0');
	elsif clk'event and clk = '1' and beamform_en(0) = '0' then
		instantaneous_beam_power <= (others=>(others=>((others=>'0'))));
		summed_power_0 				<= (others=>(others=>'0'));
		summed_power_1 				<= (others=>(others=>'0'));
		trig_tracker					<= (others=>(others=>'0'));
		servo_tracker					<= (others=>(others=>'0'));
		beam_trigs 						<= (others=>'0');
		beam_servos 					<= (others=>'0');
	elsif clk'event and clk = '1' then
	
		for i in 0 to num_beams-1 loop
			--------------------- 
			--generate trigger outputs for trigger state machine, if trigger conditions are met in successive 4ns windows
			---------------------
			--require two consecutive 4ns windows above threshold (+ overlap to next clock cycle to avoid misses)
			if pow_width_sel = '1' and (trig_tracker(i)(3 downto 2) = "11" or trig_tracker(i)(2 downto 1) > "11") then	
				beam_trigs(i) <= '1';
			--simply require a single 4ns bin above threshold (no need for overlap)
			elsif pow_width_sel = '0' and trig_tracker(i)(3 downto 2) > 0 then
				beam_trigs(i) <= '1';
			else
				beam_trigs(i) <= '0';
			end if;
			---
			--same as above for servos
			if pow_width_sel = '1' and (servo_tracker(i)(3 downto 2) = "11" or servo_tracker(i)(2 downto 1) = "11") then
				beam_servos(i) <= '1';
			elsif pow_width_sel = '0' and servo_tracker(i)(3 downto 2) > 0 then
				beam_servos(i) <= '1';
			else
				beam_servos(i) <= '0';
			end if;
			--------------------------------------------------------------------------
			trig_tracker(i)(3 downto 2)  <= trig_tracker(i)(1 downto 0); 
			servo_tracker(i)(3 downto 2) <= servo_tracker(i)(1 downto 0); 
			--------------------------------------------------------------------------
			if summed_power_0(i) > trig_thresh(i) then
				trig_tracker(i)(0) <= '1';
			else
				trig_tracker(i)(0) <= '0';
			end if;
			---
			if summed_power_1(i) > trig_thresh(i) then
				trig_tracker(i)(1) <= '1';
			else
				trig_tracker(i)(1) <= '0';
			end if;
			---
			if summed_power_0(i) > servo_thresh(i) then
				servo_tracker(i)(0) <= '1';
			else
				servo_tracker(i)(0) <= '0';
			end if;
			---
			if summed_power_1(i) > servo_thresh(i) then
				servo_tracker(i)(1) <= '1';
			else
				servo_tracker(i)(1) <= '0';
			end if;
			--------------------------------------------------------------------------
			--summed power in 4 samples, first and last in 8-sample / clk
			--------------------------------------------------------------------------
			summed_power_1(i) <= std_logic_vector(resize(unsigned(instantaneous_beam_power(i,7)), 16)) + std_logic_vector(resize(unsigned(instantaneous_beam_power(i,6)), 16)) +
										std_logic_vector(resize(unsigned(instantaneous_beam_power(i,5)), 16)) + std_logic_vector(resize(unsigned(instantaneous_beam_power(i,4)), 16));
										
			summed_power_0(i) <= std_logic_vector(resize(unsigned(instantaneous_beam_power(i,3)), 16)) + std_logic_vector(resize(unsigned(instantaneous_beam_power(i,2)), 16)) +
										std_logic_vector(resize(unsigned(instantaneous_beam_power(i,1)), 16)) + std_logic_vector(resize(unsigned(instantaneous_beam_power(i,0)), 16));
			--------------------------------------------------------------------------
			for j in 0 to 7 loop
				instantaneous_beam_power(i,j) <= --//this is 14 bits (2*coh_sum_bits)
					std_logic_vector(to_unsigned(lut_power(to_integer(signed(coherent_sums_pipeline(i)(coh_sum_bits*(j+1)-1 downto coh_sum_bits*j)))),2*coh_sum_bits));
			end loop;
			-------------------------------------
		end loop;
	end if;
end process;
-------------------------------------
--- make trigger
proc_beam_trig : process(clk,arstn)
begin
   if arstn = '0' then
		beam_trigs_to_output <= (others=>'0'); --one shots on clk for scalers (mask does NOT apply)
		beam_servos_to_output <= (others=>'0'); --one shots on clk for scalers  (mask does NOT apply)
		trig_o <= '0';                        --the phased trigger for data capture, mask DOES apply to this
		trig_beam_pattern <= (others=>'0');
		trig_beam_pattern_pipe <= (others=>'0');
		last_trigger_hit_pattern_o <= (others=>'0');
		internal_beam_mask <= (others=>'0');
		beam_trig_state_reg <= (others=>(others=>'0'));
		beam_servo_state_reg <= (others=>(others=>'0'));
		holdoff_beam_trigs <= (others=>'0'); --these prevent one beam from triggering within ~2 clk cycles of another beam triggering
		holdoff_beam_servos <= (others=>'0');
		
	elsif clk'event and clk = '1' then

		internal_beam_mask <= beam_mask(num_beams-1 downto 0);
		trig_beam_pattern_pipe <= trig_beam_pattern;
		
		if trig_beam_pattern > 0 and beamform_en(1) = '1' then
			trig_o <= '1';
			last_trigger_hit_pattern_o <= trig_beam_pattern; --trig_beam_pattern_pipe;
		else
			trig_o <= '0';
		end if;
		------------------------
		for i in 0 to num_beams-1 loop
			------------------------
			trig_beam_pattern(i) <= beam_trigs_to_output(i); -- and internal_beam_mask(i);
			------------------------
			-- NOTE: apply beam mask within, so that masked beam isn't constantly re-triggering
			------------------------
			case beam_trig_state_reg(i) is
				when "00" => 
					beam_trigs_to_output(i) <= '0';
					holdoff_beam_trigs(i) <= '0';
					if beam_trigs(i) = '1' and holdoff_beam_trigs < 1 and internal_beam_mask(i) = '1' then
						beam_trig_state_reg(i) <= "01";
					else
						beam_trig_state_reg(i) <= "00";
					end if;
				when "01" =>
					beam_trigs_to_output(i) <= '1'; --pulse trig for one clk cycle
					holdoff_beam_trigs(i) <= '1';
					beam_trig_state_reg(i) <= "10";
				when "10" => --small holdoff
					beam_trigs_to_output(i) <= '0';
					holdoff_beam_trigs(i) <= '1';
					beam_trig_state_reg(i) <= "11";
				when "11" => --small holdoff (2), total of 2x clk_trig cycles
					beam_trigs_to_output(i) <= '0';
					holdoff_beam_trigs(i) <= '1';
					beam_trig_state_reg(i) <= "00";
				when others=>
					beam_trigs_to_output(i) <= '0';
					holdoff_beam_trigs(i) <= '0';
					beam_trig_state_reg(i) <= "00";
			end case;
			------------------------
			case beam_servo_state_reg(i) is
				when "00" => 
					beam_servos_to_output(i) <= '0';
					holdoff_beam_servos(i) <= '0';
					if beam_servos(i) = '1' and holdoff_beam_servos < 1 then
						beam_servo_state_reg(i) <= "01";
					else
						beam_servo_state_reg(i) <= "00";
					end if;
				when "01" =>
					beam_servos_to_output(i) <= '1'; --pulse trig for one clk cycle
					holdoff_beam_servos(i) <= '1';
					beam_servo_state_reg(i) <= "10";
				when "10" => --small holdoff
					beam_servos_to_output(i) <= '0';
					holdoff_beam_servos(i) <= '1';
					beam_servo_state_reg(i) <= "11";
				when "11" => --small holdoff (2), total of 2x clk_trig cycles
					beam_servos_to_output(i) <= '0';
					holdoff_beam_servos(i) <= '1';
					beam_servo_state_reg(i) <= "00";
				when others=>
					beam_servos_to_output(i) <= '0';
					holdoff_beam_servos(i) <= '0';
					beam_servo_state_reg(i) <= "00";
			end case;			
			
		end loop;
	end if;
end process;

beamtrigs_o	 <= beam_trigs_to_output;
beamservos_o <= beam_servos_to_output;

end rtl;