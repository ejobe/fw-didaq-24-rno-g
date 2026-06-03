------
--simple coinc, 12-channel input // rev0p1 041726 EJO-UCHICAGO
------
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity coinc_trig is
	port(
		arstn        : in   std_logic; 
      clk			 : in   std_logic;  --clock for data							
		data0			 : in	  std_logic_Vector(63 downto 0);	--8 samples of 8 bit data
		data1			 : in	  std_logic_Vector(63 downto 0);					
		data2			 : in	  std_logic_Vector(63 downto 0);
		data3			 : in	  std_logic_Vector(63 downto 0);	
		data4			 : in	  std_logic_Vector(63 downto 0);					
		data5			 : in	  std_logic_Vector(63 downto 0);	
		data6			 : in	  std_logic_Vector(63 downto 0);	
		data7			 : in	  std_logic_Vector(63 downto 0);					
		data8			 : in	  std_logic_Vector(63 downto 0);
		data9			 : in	  std_logic_Vector(63 downto 0);	
		data10		 : in	  std_logic_Vector(63 downto 0);
		data11		 : in	  std_logic_Vector(63 downto 0);	
		--//following are assumed to be already registered on input clk domain to this module
		trig_en		 : in	  std_logic_vector(1 downto 0);
		trig_mask	 : in	  std_logic_vector(11 downto 0);
		trig_hit_rq	 : in	  std_logic_vector(2 downto 0);
		trig_window	 : in	  std_logic_vector(3 downto 0);
		thresh0	 	 : in	  std_logic_vector(7 downto 0);
		thresh1	 	 : in	  std_logic_vector(7 downto 0);
		thresh2	 	 : in	  std_logic_vector(7 downto 0);
		thresh3	 	 : in	  std_logic_vector(7 downto 0);
		thresh4	 	 : in	  std_logic_vector(7 downto 0);
		thresh5	 	 : in	  std_logic_vector(7 downto 0);
		thresh6	 	 : in	  std_logic_vector(7 downto 0);
		thresh7	 	 : in	  std_logic_vector(7 downto 0);
		thresh8	 	 : in	  std_logic_vector(7 downto 0);
		thresh9	 	 : in	  std_logic_vector(7 downto 0);
		thresh10	 	 : in	  std_logic_vector(7 downto 0);
		thresh11	 	 : in	  std_logic_vector(7 downto 0);
		
		last_trigger_hit_pattern_o : out std_logic_Vector(11 downto 0);
		singles_o	 : out  std_logic_Vector(11 downto 0); --for scalers, single-shot pulses on clk
		trig_o		 : out  std_logic --the trigger
);
end entity coinc_trig;
----------------------------------
architecture rtl of coinc_trig is
----------------------------------
type data_array_type is array(11 downto 0) of std_logic_vector(63 downto 0);
type thresh_array_type is array(11 downto 0) of std_logic_vector(7 downto 0);
type counter_array_type is array(11 downto 0) of std_logic_vector(3 downto 0);
type coinc_trig_stack_state_type is array(11 downto 0) of std_logic_vector(1 downto 0);

----------------------------------
signal internal_data0: data_array_type;
signal internal_data1: data_array_type;
signal internal_thresholds : thresh_array_type;
signal internal_coinc_trig : std_logic;

signal internal_L0_hilo_hi  : std_logic_Vector(11 downto 0); --generate singles from hi/lo coinc [dumb!!]
signal internal_L0_hilo_lo  : std_logic_Vector(11 downto 0);

signal internal_single_hits : std_logic_Vector(11 downto 0);
signal last_trig_single_hit_pattern : std_logic_Vector(11 downto 0);
signal internal_trig_clear	 : std_logic_Vector(11 downto 0);
signal trig_window_counter : counter_array_type;

signal coinc_trig_stack_reg : coinc_trig_stack_state_type;
signal coinc_trig_sum_reg : std_logic_vector(1 downto 0);
----------------------------------
constant baseline : std_logic_vector(7 downto 0) := x"80"; --8-bit adc in offset binary coding
----------------------------------
begin
----------------------------------
singles_o <= internal_single_hits;
trig_o <= internal_coinc_trig and trig_en(1);
last_trigger_hit_pattern_o <= last_trig_single_hit_pattern;
----------------------------------
proc_coinc_singles : process(clk,arstn)
begin
   if arstn = '0' then
		for i in 0 to 11 loop
			internal_data0(i) <= (others=>'0');
			internal_data1(i) <= (others=>'0');
			internal_thresholds(i) <= (others=>'0');
		end loop;
	
		internal_L0_hilo_hi  <= (others=>'0');
		internal_L0_hilo_lo  <= (others=>'0');
		internal_single_hits <= (others=>'0');

	elsif clk'event and clk = '1' and trig_en(0) = '0' then
		for i in 0 to 11 loop
			internal_data0(i) <= (others=>'0');
			internal_data1(i) <= (others=>'0');
			internal_thresholds(i) <= (others=>'0');
		end loop;
	
		internal_L0_hilo_hi  <= (others=>'0');
		internal_L0_hilo_lo  <= (others=>'0');
		internal_single_hits <= (others=>'0');
	----------------------------------	
	elsif clk'event and clk = '1' then
		for i in 0 to 11 loop
			--low condition [~12ns at 1GSPS, overlapping every 8ns]
			if internal_data1(i)(63 downto 56) <= (baseline - internal_thresholds(i)) or 
				internal_data1(i)(55 downto 48) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)(47 downto 40) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)(39 downto 32) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)(31 downto 24) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)(23 downto 16) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)(15 downto  8) <= (baseline - internal_thresholds(i)) or
				internal_data1(i)( 7 downto  0) <= (baseline - internal_thresholds(i)) or
				internal_data0(i)(63 downto 56) <= (baseline - internal_thresholds(i)) or
				internal_data0(i)(55 downto 48) <= (baseline - internal_thresholds(i)) or
				internal_data0(i)(47 downto 40) <= (baseline - internal_thresholds(i)) or
				internal_data0(i)(39 downto 32) <= (baseline - internal_thresholds(i)) then
				------------------
				internal_L0_hilo_lo(i) <= '1';
			else
				internal_L0_hilo_lo(i) <= '0';
			end if;
			----------------------------------
			--high condition [~12ns at 1GSPS, overlapping every 8ns]
			if internal_data1(i)(63 downto 56) >= (baseline + internal_thresholds(i)) or 
				internal_data1(i)(55 downto 48) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)(47 downto 40) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)(39 downto 32) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)(31 downto 24) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)(23 downto 16) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)(15 downto  8) >= (baseline + internal_thresholds(i)) or
				internal_data1(i)( 7 downto  0) >= (baseline + internal_thresholds(i)) or
				internal_data0(i)(63 downto 56) >= (baseline + internal_thresholds(i)) or
				internal_data0(i)(55 downto 48) >= (baseline + internal_thresholds(i)) or
				internal_data0(i)(47 downto 40) >= (baseline + internal_thresholds(i)) or
				internal_data0(i)(39 downto 32) >= (baseline + internal_thresholds(i)) then
				------------------
				internal_L0_hilo_hi(i) <= '1';
			else
				internal_L0_hilo_hi(i) <= '0';
			end if;	
			----------------------------------
			if internal_L0_hilo_hi(i) = '1' and internal_L0_hilo_lo(i) = '1' then
				internal_single_hits(i) <= '1';
			else
				internal_single_hits(i) <= '0';
			end if;
			----------------------------------
			internal_data1(i) <= internal_data0(i);
		end loop;
		----------------------------------
		internal_data0(0) <= data0;
		internal_data0(1) <= data1;
		internal_data0(2) <= data2;
		internal_data0(3) <= data3;
		internal_data0(4) <= data4;
		internal_data0(5) <= data5;
		internal_data0(6) <= data6;
		internal_data0(7) <= data7;
		internal_data0(8) <= data8;
		internal_data0(9) <= data9;
		internal_data0(10) <= data10;
		internal_data0(11) <= data11;
		
		internal_thresholds(0) <= thresh0;
		internal_thresholds(1) <= thresh1;
		internal_thresholds(2) <= thresh2;
		internal_thresholds(3) <= thresh3;
		internal_thresholds(4) <= thresh4;
		internal_thresholds(5) <= thresh5;
		internal_thresholds(6) <= thresh6;
		internal_thresholds(7) <= thresh7;
		internal_thresholds(8) <= thresh8;
		internal_thresholds(9) <= thresh9;
		internal_thresholds(10) <= thresh10;
		internal_thresholds(11) <= thresh11;
	end if;
end process;
----------------------------------		
proc_coinc_trig : process(clk,arstn)
begin
   if arstn = '0' then
		for i in 0 to 11 loop
			trig_window_counter(i) <= (others=>'0');
			coinc_trig_stack_reg(i) <= "00";
		end loop;
		coinc_trig_sum_reg <= (others=>'0');
		internal_coinc_trig <= '0';
		last_trig_single_hit_pattern <= (others=>'0');
		
	elsif clk'event and clk = '1' then
		----------------------------------
		for i in 0 to 11 loop
			case coinc_trig_stack_reg(i) is
				when "00" =>
					trig_window_counter(i) <= (others=>'0');
					if internal_single_hits(i) = '1' and trig_mask(i) = '1' then
						coinc_trig_stack_reg(i) <= "01";
					else
						coinc_trig_stack_reg(i) <= "00";
					end if;
					
				when "01" =>
					trig_window_counter(i) <= trig_window_counter(i) + 1;
					if trig_window_counter(i) = trig_window or coinc_trig_sum_reg = "01" then
						coinc_trig_stack_reg(i) <= "00";
					else
						coinc_trig_stack_reg(i) <= "01";
					end if;
				when others=>
					coinc_trig_stack_reg(i) <= "00";
			end case;
		end loop;
		----------------------------------
		case coinc_trig_sum_reg is
			when "00" => 
				last_trig_single_hit_pattern <= 	coinc_trig_stack_reg(11)(0) & coinc_trig_stack_reg(10)(0) & 
															coinc_trig_stack_reg(9)(0) & coinc_trig_stack_reg(8)(0) & 
															coinc_trig_stack_reg(7)(0) & coinc_trig_stack_reg(6)(0) & 
															coinc_trig_stack_reg(5)(0) & coinc_trig_stack_reg(4)(0) & 
															coinc_trig_stack_reg(3)(0) & coinc_trig_stack_reg(2)(0) & 
															coinc_trig_stack_reg(1)(0) & coinc_trig_stack_reg(0)(0);

				internal_coinc_trig <= '0';
				if (to_integer(unsigned(coinc_trig_stack_reg(0))) + to_integer(unsigned(coinc_trig_stack_reg(1))) + 
					to_integer(unsigned(coinc_trig_stack_reg(2))) + to_integer(unsigned(coinc_trig_stack_reg(3))) +
					to_integer(unsigned(coinc_trig_stack_reg(4))) + to_integer(unsigned(coinc_trig_stack_reg(5))) +
					to_integer(unsigned(coinc_trig_stack_reg(6))) + to_integer(unsigned(coinc_trig_stack_reg(7))) +
					to_integer(unsigned(coinc_trig_stack_reg(8))) + to_integer(unsigned(coinc_trig_stack_reg(9))) +
					to_integer(unsigned(coinc_trig_stack_reg(10))) + to_integer(unsigned(coinc_trig_stack_reg(11)))) > to_integer(unsigned(trig_hit_rq)) then
					----------------------------------
					coinc_trig_sum_reg <= "01";
				else
					coinc_trig_sum_reg <= "00";
				end if;
			when "01" =>
				last_trig_single_hit_pattern <= 	last_trig_single_hit_pattern; --register trig hit pattern
				internal_coinc_trig <= '1'; --pulse coinc trig for one clk cycle
				coinc_trig_sum_reg <= "10";
			when "10" => --small holdoff
				last_trig_single_hit_pattern <= last_trig_single_hit_pattern;
				internal_coinc_trig <= '0';
				coinc_trig_sum_reg <= "11";
			when "11" => --small holdoff (2), total of 2x clk_trig cycles
				last_trig_single_hit_pattern <= last_trig_single_hit_pattern;
				internal_coinc_trig <= '0';
				coinc_trig_sum_reg <= "00";
			when others=>
				last_trig_single_hit_pattern <= last_trig_single_hit_pattern;
				internal_coinc_trig <= '0';
				coinc_trig_sum_reg <= "00";
		end case;
	end if;
end process;
----------------------------------
end rtl;	