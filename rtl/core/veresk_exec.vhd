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

    signal exec		: exec_type;
    signal alu		: alu_type;
    signal branch	: branch_type;
    signal wreg_en	: std_logic;

begin

    exec_out <= exec;
    exec.wreg.en <= wreg_en when decode.rd /= REG0 else '0';

    alu_i: entity work.veresk_alu
	port map(
	    r1		=> r1,
	    r2		=> r2,
	    decode	=> decode,

	    alu_out	=> alu
	);

    branch_i: entity work.veresk_branch
	port map(
	    r1		=> r1,
	    r2		=> r2,
	    decode	=> decode,

	    branch_out	=> branch
	);

    process (decode, alu, r1, r2) begin
	wreg_en <= '0';

	exec.wreg.rd <= (others => '0');
	exec.wreg.dat <= (others => '0');

	exec.target_taken <= '0';
	exec.target_ignore <= '0';
	exec.target <= (others => '0');

	exec.dbus_out.addr <= (others => '0');
	exec.dbus_out.dat <= (others => '0');
	exec.dbus_out.we <= b"0000";

	case decode.op is
	    when RV32I_OP_LUI =>
		wreg_en <= '1';
		exec.wreg.rd <= decode.rd;
		exec.wreg.dat <= decode.imm;

	    when RV32I_OP_IMM | RV32I_OP_REG =>
		wreg_en <= alu.en;
		exec.wreg.rd <= decode.rd;
		exec.wreg.dat <= alu.dat;

	    when RV32I_OP_AUIPC =>
		wreg_en <= '1';
		exec.wreg.rd <= decode.rd;
		exec.wreg.dat <= std_logic_vector(unsigned(decode.pc) + unsigned(decode.imm));

	    when RV32I_OP_JAL =>
		wreg_en <= '1';
		exec.wreg.rd <= decode.rd;
		exec.wreg.dat <= std_logic_vector(unsigned(decode.pc) + 4);
		exec.target_taken <= '1';
		exec.target <= unsigned(signed(decode.pc) + signed(decode.imm));

	    when RV32I_OP_JALR =>
		wreg_en <= '1';
		exec.wreg.rd <= decode.rd;
		exec.wreg.dat <= std_logic_vector(unsigned(decode.pc) + 4);
		exec.target_taken <= '1';
		exec.target <= unsigned(signed(r1) + signed(decode.imm));

	    when RV32I_OP_STORE =>
		exec.dbus_out.addr <= std_logic_vector(unsigned(signed(r1) + signed(decode.imm)));
		exec.dbus_out.dat <= r2;

		case decode.fn3 is
		    when RV32_MEM_SIZE_B => exec.dbus_out.we <= b"0001";
		    when RV32_MEM_SIZE_H => exec.dbus_out.we <= b"0011";
		    when RV32_MEM_SIZE_W => exec.dbus_out.we <= b"1111";

		    when others =>
		end case;

	    when RV32I_OP_BRANCH =>
		exec.target <= branch.addr;
		exec.target_taken <= branch.taken;
		exec.target_ignore <= branch.ignore;

	    when others =>
	end case;
    end process;

end;
