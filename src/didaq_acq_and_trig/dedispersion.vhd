------
--RNO-G deep system response dedispersion 
------
library ieee;        
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;

entity dedispersion is
generic(
	limited_bits : integer := 5;
	native_bits  : integer := 8);
port(
		arstn        : in   std_logic;  -- reset low
      clk			 : in   std_logic;  --clock for data		
      enable		 : in   std_logic;  --clock for data
		gain_sel		 : in	  std_logic;
		data_i		: in	  std_logic_Vector(255 downto 0);	--32 samples of 8 bit data
		data_o		: out	  std_logic_Vector(255 downto 0));
end entity dedispersion;

architecture rtl of dedispersion is

type filter_kernel_type is array (0 to 15) of integer range -7 to 8; --
constant kernel : filter_kernel_type := (0,-1,-3,-1,-1,3,2,5,0,-1,-7,8,-5,-2,2,0);

type filter_result_type is array(0 to 15) of integer range -127 to 128;
signal filter_result : filter_result_type;
signal filter_data : std_logic_Vector(255 downto 0);

begin

process(arstn, clk)
begin   		
	if arstn = '0' then
		for i in 0 to 15 loop
			filter_result(i) <= 0;
		end loop;

	elsif clk'event and clk = '1' then
		
		for i in 0 to 15 loop
			filter_result(i) <= 	(to_integer(signed(data_i((i+16)*native_bits+limited_bits-1 downto (i+16)*native_bits)))) * kernel(0) + 
										(to_integer(signed(data_i((i+15)*native_bits+limited_bits-1 downto (i+15)*native_bits))))  * kernel(1) + 
										(to_integer(signed(data_i((i+14)*native_bits+limited_bits-1 downto (i+14)*native_bits))))  * kernel(2) + 
										(to_integer(signed(data_i((i+13)*native_bits+limited_bits-1 downto (i+13)*native_bits)))) * kernel(3) + 
										(to_integer(signed(data_i((i+12)*native_bits+limited_bits-1 downto (i+12)*native_bits)))) * kernel(4) + 
										(to_integer(signed(data_i((i+11)*native_bits+limited_bits-1 downto (i+11)*native_bits)))) * kernel(5) + 
										(to_integer(signed(data_i((i+10)*native_bits+limited_bits-1 downto (i+10)*native_bits)))) * kernel(6) + 
										(to_integer(signed(data_i((i+9)*native_bits+limited_bits-1 downto (i+9)*native_bits)))) * kernel(7) + 
										(to_integer(signed(data_i((i+8)*native_bits+limited_bits-1 downto (i+8)*native_bits)))) * kernel(8) + 
										(to_integer(signed(data_i((i+7)*native_bits+limited_bits-1 downto (i+7)*native_bits)))) * kernel(9) + 
										(to_integer(signed(data_i((i+6)*native_bits+limited_bits-1 downto (i+6)*native_bits)))) * kernel(10) + 
										(to_integer(signed(data_i((i+5)*native_bits+limited_bits-1 downto (i+5)*native_bits)))) * kernel(11) + 
										(to_integer(signed(data_i((i+4)*native_bits+limited_bits-1 downto (i+4)*native_bits)))) * kernel(12) + 
										(to_integer(signed(data_i((i+3)*native_bits+limited_bits-1 downto (i+3)*native_bits)))) * kernel(13) + 
										(to_integer(signed(data_i((i+2)*native_bits+limited_bits-1 downto (i+2)*native_bits)))) * kernel(14) + 
										(to_integer(signed(data_i((i+1)*native_bits+limited_bits-1 downto (i+1)*native_bits)))) * kernel(15);
		end loop;
	end if;
end process;							
			


end rtl;