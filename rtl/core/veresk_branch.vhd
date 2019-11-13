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

entity veresk_branch is
    port (
	decode		: in decode_type;
	r1		: in cell_type;
	r2		: in cell_type;

	branch_out	: out branch_type
    );
end veresk_branch;

architecture rtl of veresk_branch is

    signal taken	: std_logic;

begin

    branch_out.addr <= unsigned(signed(decode.pc) + signed(decode.imm));
    branch_out.taken <= taken;

    process (decode.fn3, r1, r2) begin
	taken <= '0';

	case decode.fn3 is
	    when RV32_TEST_EQ =>
		if r1 = r2 then
		    taken <= '1';
		end if;

	    when RV32_TEST_NE =>
		if r1 /= r2 then
		    taken <= '1';
		end if;

	    when RV32_TEST_LT =>
		if signed(r1) < signed(r2) then
		    taken <= '1';
		end if;

	    when RV32_TEST_GE =>
		if signed(r1) > signed(r2) then
		    taken <= '1';
		end if;

	    when RV32_TEST_LTU =>
		if unsigned(r1) < unsigned(r2) then
		    taken <= '1';
		end if;

	    when RV32_TEST_GEU =>
		if unsigned(r1) > unsigned(r2) then
		    taken <= '1';
		end if;

	    when others =>
	end case;
    end process;

end;
