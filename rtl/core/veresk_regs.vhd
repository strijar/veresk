--
--  Copyright 2019 Oleg Belousov <belousov.oleg@gmail.com>,
--
--  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
-- 
--    1. Redistributions of source code must retain the above copyright notice,
--       this list of conditions and the following disclaimer.
-- 
--    2. Redistributions in binary form must reproduce the above copyright
--       notice, this list of conditions and the following disclaimer in the
--       documentation and/or other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER ``AS IS'' AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
-- NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation are
-- those of the authors and should not be interpreted as representing official
-- policies, either expressed or implied, of the copyright holder.
-- 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.veresk_pkg.all;

entity veresk_regs is
    port (
	clk		: in std_logic;
	rst		: in std_logic;

	r1_in		: in reg_type;
	r2_in		: in reg_type;

	r1_out		: out cell_type;
	r2_out		: out cell_type;

	wreg_en		: in std_logic;
	wreg_in		: in reg_type;
	wdat_in		: in cell_type
    );
end veresk_regs;

architecture rtl of veresk_regs is

    type regs_type is array(natural range 0 to 31) of cell_type;

    signal regs	: regs_type := (
	others => x"00000000"
    );

begin

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		r1_out <= (others => '0');
		r2_out <= (others => '0');
	    else
		if (wreg_en = '1' and wreg_in /= x"0") then
		    regs(to_integer(unsigned(wreg_in))) <= wdat_in;
		end if;

		r1_out <= regs(to_integer(unsigned(r1_in)));
		r2_out <= regs(to_integer(unsigned(r2_in)));

	    end if;
	end if;
    end process;

end;
