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

	alu_out		: out alu_type
    );
end veresk_alu;

architecture rtl of veresk_alu is

    signal alu		: alu_type;

begin

    alu_out <= alu;

    process (decode, r1, r2) begin
	alu.en <= '0';
	alu.dat <= (others => '0');

	case decode.op is
	    when RV32I_OP_IMM =>
		alu.en <= '1';

		case decode.fn3 is
		    when RV32_FN3_ADDI =>
		        alu.dat <= std_logic_vector(unsigned(r1) + unsigned(decode.imm));

		    when RV32_FN3_SLTI =>
			if signed(r1) < signed(decode.imm) then
			    alu.dat <= x"00000001";
			else
			    alu.dat <= x"00000000";
			end if;

		    when RV32_FN3_SLTIU =>
			if unsigned(r1) < unsigned(decode.imm) then
			    alu.dat <= x"00000001";
			else
			    alu.dat <= x"00000000";
			end if;

		    when RV32_FN3_ANDI =>
		        alu.dat <= r1 and decode.imm;

		    when RV32_FN3_ORI =>
		        alu.dat <= r1 or decode.imm;

		    when RV32_FN3_XORI =>
		        alu.dat <= r1 xor decode.imm;

		    when others =>
		end case;

	    when RV32I_OP_REG =>
		alu.en <= '1';

		case decode.fn3 is
		    when RV32_FN3_ADD =>
			if decode.fn7 = RV32_FN7_0 then
		    	    alu.dat <= std_logic_vector(signed(r1) + signed(r2));
		    	else
		    	    alu.dat <= std_logic_vector(signed(r1) - signed(r2));
		    	end if;

		    when RV32_FN3_SLT =>
			if signed(r1) < signed(r2) then
			    alu.dat <= x"00000001";
			else
			    alu.dat <= x"00000000";
			end if;

		    when RV32_FN3_SLTU =>
			if unsigned(r1) < unsigned(r2) then
			    alu.dat <= x"00000001";
			else
			    alu.dat <= x"00000000";
			end if;

		    when RV32_FN3_AND =>
		        alu.dat <= r1 and r2;

		    when RV32_FN3_OR =>
		        alu.dat <= r1 or r2;

		    when RV32_FN3_XOR =>
		        alu.dat <= r1 xor r2;

		    when others =>
		end case;

	    when others =>
	end case;
    end process;

end;
