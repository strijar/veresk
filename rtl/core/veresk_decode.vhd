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

entity veresk_decode is
    port (
	inst		: in cell_type;
	pc		: in pc_type;
	decode_out	: out decode_type
    );
end veresk_decode;

architecture rtl of veresk_decode is

    type subset_type is (none, rtype, itype, stype, btype, utype, jtype);

    signal op		: op_type;
    signal decode	: decode_type;
    signal subset	: subset_type;

begin
    decode_out <= decode;

    decode.pc <= pc;
    decode.fn3 <= inst(14 downto 12);
    decode.rs1_sel <= inst(19 downto 15);
    decode.rs2_sel <= inst(24 downto 20);
    decode.fn7 <= inst(31 downto 25);

    op <= inst(6 downto 0);

    decode.jal <= '1' when op = RV32I_OP_JAL else '0';
    decode.jalr <= '1' when op = RV32I_OP_JALR else '0';
    decode.branch <= '1' when op = RV32I_OP_BRANCH else '0';
    decode.load <= '1' when op = RV32I_OP_LOAD else '0';
    decode.store <= '1' when op = RV32I_OP_STORE else '0';
    decode.lui <= '1' when op = RV32I_OP_LUI else '0';
    decode.auipc <= '1' when op = RV32I_OP_AUIPC else '0';

    decode.alu_imm <= '1' when op = RV32I_OP_IMM else '0';
    decode.alu_reg <= '1' when op = RV32I_OP_REG else '0';
    decode.alu <= decode.alu_imm or decode.alu_reg;

    with op select subset <=
	itype	when RV32I_OP_IMM,
	itype	when RV32I_OP_JALR,
	itype	when RV32I_OP_LOAD,
	rtype	when RV32I_OP_REG,
	stype	when RV32I_OP_STORE,
	btype	when RV32I_OP_BRANCH,
	utype	when RV32I_OP_LUI,
	utype	when RV32I_OP_AUIPC,
	jtype	when RV32I_OP_JAL,
	none	when others;

    decode.rs1_req <= '1' when
	(subset = rtype or subset = itype or subset = stype or subset = btype)
	and decode.rs1_sel /= REG0 else '0';

    decode.rs2_req <= '1' when
	(subset = rtype or subset = stype or subset = btype)
	and decode.rs2_sel /= REG0 else '0';

    decode.target.en <= decode.jal or decode.jalr;
    decode.target.addr <= unsigned(decode.pc) + unsigned(decode.imm);

    decode.rd.sel <= inst(11 downto 7);
    decode.rd.en <= decode.jalr;
    decode.rd.dat <= std_logic_vector(unsigned(pc) + 4);

    process (inst, subset) begin
	decode.imm <= (others => '0');

	case subset is
	    when itype =>
		decode.imm(11 downto 0) <= inst(31 downto 20);
		decode.imm(31 downto 12) <= (others => inst(31));

	    when stype =>
		decode.imm(4 downto 0) <= inst(11 downto 7);
		decode.imm(11 downto 5) <= inst(31 downto 25);
		decode.imm(31 downto 12) <= (others => inst(31));

	    when btype =>
		decode.imm(31 downto 12) <= (others => inst(31));
		decode.imm(10 downto 5) <= inst(30 downto 25);
		decode.imm(4 downto 1) <= inst(11 downto 8);
		decode.imm(11) <= inst(7);
		decode.imm(0) <= '0';

	    when utype =>
		decode.imm(31 downto 12) <= inst(31 downto 12);

	    when jtype =>
		decode.imm(31 downto 20) <= (others => inst(31));
		decode.imm(10 downto 1) <= inst(30 downto 21);
		decode.imm(11 downto 11) <= inst(20 downto 20);
		decode.imm(19 downto 12) <= inst(19 downto 12);
		decode.imm(0) <= '0';

	    when others =>
	end case;
    end process;

end;
