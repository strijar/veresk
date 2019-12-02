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
    signal alu_out	: cell_type;
    signal branch_en	: std_logic;
    signal rd_en	: std_logic;

    signal pc_4		: cell_type;
    signal pc_imm	: cell_type;
    signal r1_imm	: cell_type;

begin

    exec_out <= exec;
    exec.pc <= decode.pc;

    alu_i: entity work.veresk_alu
	port map(
	    r1		=> r1,
	    r2		=> r2,
	    decode	=> decode,

	    alu_out	=> alu_out
	);

    branch_i: entity work.veresk_branch
	port map(
	    r1		=> r1,
	    r2		=> r2,
	    decode	=> decode,

	    branch_en	=> branch_en
	);

    pc_4 <= std_logic_vector(unsigned(decode.pc) + 4);
    pc_imm <= std_logic_vector(unsigned(decode.pc) + unsigned(decode.imm));
    r1_imm <= std_logic_vector(unsigned(r1) + unsigned(decode.imm));

    rd_en <= decode.lui or decode.auipc or decode.alu or decode.jalr;

    exec.rd.sel <= decode.rd.sel;
    exec.rd.en <= rd_en when decode.rd.sel /= REG0 else '0';

    exec.rd.dat <=
	decode.imm when decode.lui = '1' else
	alu_out when decode.alu = '1' else
	pc_imm when decode.auipc = '1' else
	pc_4 when decode.jalr = '1' else (others => '0');

    exec.mem_out.addr <= std_logic_vector(unsigned(signed(r1) + signed(decode.imm)));
    exec.mem_out.size <= decode.fn3;
    exec.mem_out.we <= decode.store;
    exec.mem_out.re <= decode.load;
    exec.mem_out.dat <= r2;

    exec.target.en <= decode.jalr or (decode.branch and branch_en);
    exec.target.addr <= unsigned(r1_imm) when decode.jalr = '1' else unsigned(pc_imm);

end;
