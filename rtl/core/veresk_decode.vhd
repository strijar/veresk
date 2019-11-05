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
	fetch		: in fetch_out_type;
	decode_out	: out decode_type
    );
end veresk_decode;

architecture rtl of veresk_decode is

    signal decode	: decode_type;
    signal inst		: cell_type;
    signal op		: op_type;

begin
    decode_out <= decode;

    inst <= fetch.inst;
    decode.op <= inst(6 downto 0);

    with decode.op select decode.subset <=
	utype	when RV32I_OP_LUI,
	itype	when RV32I_OP_IMM,

	rtype	when RV32I_OP_REG,
	itype	when RV32I_OP_JALR,
	itype	when RV32I_OP_LOAD,
	itype	when RV32I_OP_SYS,
	itype	when RV32I_OP_FENCE,
	stype	when RV32I_OP_STORE,
	btype	when RV32I_OP_BRANCH,
	utype	when RV32I_OP_AUIPC,
	jtype	when RV32I_OP_JAL,
	none	when others;

    process (inst, decode.subset) begin
	decode.rd <= (others => '0');
	decode.fn3 <= (others => '0');
	decode.rs1 <= (others => '0');
	decode.rs2 <= (others => '0');
	decode.fn7 <= (others => '0');
	decode.imm <= (others => '0');
	decode.hazard_rs1 <= '0';
	decode.hazard_rs2 <= '0';

	case decode.subset is
	    when rtype =>
		decode.rd <= inst(11 downto 7);
		decode.fn3 <= inst(14 downto 12);
		decode.rs1 <= inst(19 downto 15);
		decode.rs2 <= inst(24 downto 20);
		decode.fn7 <= inst(31 downto 25);
		decode.hazard_rs1 <= '1';
		decode.hazard_rs1 <= '1';

	    when itype =>
		decode.rd <= inst(11 downto 7);
		decode.fn3 <= inst(14 downto 12);
		decode.rs1 <= inst(19 downto 15);
		decode.hazard_rs1 <= '1';

		decode.imm(11 downto 0) <= inst(31 downto 20);
		decode.imm(31 downto 12) <= (others => inst(31));

	    when stype =>
		decode.fn3 <= inst(14 downto 12);
		decode.rs1 <= inst(19 downto 15);
		decode.hazard_rs1 <= '1';

		decode.imm(4 downto 0) <= inst(11 downto 7);
		decode.imm(11 downto 5) <= inst(31 downto 25);
		decode.imm(31 downto 12) <= (others => inst(31));

	    when btype =>
		decode.fn3 <= inst(14 downto 12);
		decode.rs1 <= inst(19 downto 15);
		decode.rs2 <= inst(24 downto 20);
		decode.hazard_rs1 <= '1';
		decode.hazard_rs2 <= '1';

		decode.imm(12) <= inst(31);
		decode.imm(10 downto 5) <= inst(30 downto 25);
		decode.imm(4 downto 1) <= inst(11 downto 8);
		decode.imm(11) <= inst(7);

	    when utype =>
		decode.rd <= inst(11 downto 7);
		decode.imm(31 downto 12) <= inst(31 downto 12);

	    when jtype =>
		decode.rd <= inst(11 downto 7);

		decode.imm(20) <= inst(31);
		decode.imm(10 downto 1) <= inst(30 downto 21);
		decode.imm(11 downto 11) <= inst(20 downto 20);
		decode.imm(19 downto 12) <= inst(19 downto 12);

	    when others =>
		end case;
    end process;

end;
