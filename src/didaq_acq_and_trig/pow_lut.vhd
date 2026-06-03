---------------------------------------------------------------------------------
-- Univ. of Chicago  
--    --KICP--
--
-- PROJECT:      phased-array trigger board
-- FILE:         pow_lut.vhd
-- AUTHOR:       e.oberla
-- EMAIL         ejo@uchicago.edu
-- DATE:         3/2017
--
-- DESCRIPTION:  includes look-up-table for squaring data points for power calc.
--    updated for 7 bit coherent sums for didaq rno-g 4-ch phased array
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pow_lut is

constant lut_size  : integer := 2**7-1;
constant lut_range : integer := 2**7;

type power_lut_type is array(integer range<>) of integer range 0 to 2**(7*2);

function init_lut(size : integer) return power_lut_type;
constant lut_power : power_lut_type(-64 to 63) := init_lut(128);

end pow_lut;

package body pow_lut is

function init_lut(size : integer) return power_lut_type is
	variable j : power_lut_type(-size/2 to size/2-1);
begin
	for i in j'range loop
		j(i) := i*i;
	end loop;
	return j;
end function;


end package body;