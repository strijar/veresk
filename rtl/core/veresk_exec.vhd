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

entity veresk_exec is
    port (
	decode		: in decode_type;
	r1		: in cell_type;
	r2		: in cell_type;

	exec_out	: out exec_type
    );
end veresk_exec;

architecture rtl of veresk_exec is

    signal exec	: exec_type;

begin

    exec_out <= exec;

    process (decode, r1, r2) begin
	exec.wreg_en <= '0';
	exec.wreg <= (others => '0');
	exec.wdat <= (others => '0');

	case decode.op is
	    when RV32I_OP_LUI =>
		exec.wreg_en <= '1';
		exec.wreg <= decode.rd;
		exec.wdat <= decode.imm;

	    when RV32I_OP_IMM =>
		exec.wreg_en <= '1';
		exec.wreg <= decode.rd;

		case decode.fn3 is
		    when RV32_FN3_ADDI =>
		        exec.wdat <= std_logic_vector(unsigned(r1) + unsigned(decode.imm));

		when others =>
		    end case;

	    when others =>
	end case;
    end process;

end;
