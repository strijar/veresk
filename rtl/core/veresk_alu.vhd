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

entity veresk_alu is
    port (
	decode		: in decode_type;
	r1		: in cell_type;
	r2		: in cell_type;

	alu_out		: out cell_type
    );
end veresk_alu;

architecture rtl of veresk_alu is

    signal second	: cell_type;

    signal shift_arith	: std_logic;
    signal shift_right	: std_logic;
    signal shift_out	: cell_type;

begin

    second <= r2 when decode.alu_reg = '1' else decode.imm;

    shift_i: entity work.veresk_shift
	port map(
	    shift_in	=> r1,
	    count	=> second(4 downto 0),
	    arith	=> shift_arith,
	    right	=> shift_right,

	    shift_out	=> shift_out
	);

    process (decode, r1, r2, second, shift_out) begin
	alu_out <= (others => '0');
        shift_right <= '0';
        shift_arith <= '0';

	if decode.alu = '1' then
	    case decode.fn3 is
		when RV32_FN3_ADD =>
		    if decode.alu_reg = '1' then
			if decode.fn7(5) = '0' then
		    	    alu_out <= std_logic_vector(signed(r1) + signed(r2));
			else
		    	    alu_out <= std_logic_vector(signed(r1) - signed(r2));
			end if;
		    else
		    	alu_out <= std_logic_vector(signed(r1) + signed(decode.imm));
		    end if;

		when RV32_FN3_SLT =>
		    if signed(r1) < signed(second) then
			alu_out <= x"00000001";
		    else
			alu_out <= x"00000000";
		    end if;

		when RV32_FN3_SLTU =>
		    if unsigned(r1) < unsigned(second) then
			alu_out <= x"00000001";
		    else
			alu_out <= x"00000000";
		    end if;

		when RV32_FN3_AND =>
		    alu_out <= r1 and second;

		when RV32_FN3_OR =>
		    alu_out <= r1 or second;

		when RV32_FN3_XOR =>
		    alu_out <= r1 xor second;

		when RV32_FN3_SLL =>
		    alu_out <= shift_out;

		when RV32_FN3_SRL =>
		    shift_arith <= decode.fn7(5);
		    shift_right <= '1';
		    alu_out <= shift_out;

		when others =>
	    end case;
	end if;
    end process;

end;
