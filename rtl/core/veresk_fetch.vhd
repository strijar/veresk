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

entity veresk_fetch is
    port (
	clk		: in std_logic;
	rst		: in std_logic;

	fetch_in	: in fetch_in_type;
	ibus_in		: in ibus_in_type;

	fetch_out	: out fetch_out_type;
	ibus_out	: out ibus_out_type
    );
end veresk_fetch;

architecture rtl of veresk_fetch is

    signal pc, pc_next		: unsigned(CELL_BITS-1 downto 0) := (others => '0');
    signal ready, ready_next	: std_logic := '0';

begin
    ibus_out.addr <= std_logic_vector(pc_next);

    fetch_out.inst <= ibus_in.dat;
    fetch_out.pc <= pc;
    fetch_out.ready <= ready;

    process (fetch_in, pc) begin
	ready_next <= '0';
	pc_next <= pc;

	if fetch_in.target_en = '1' then
	    pc_next <= fetch_in.target;
	    ready_next <= '1';
	elsif fetch_in.step = '1' then
	    pc_next <= pc + 4;
	    ready_next <= '1';
	else
	    pc_next <= pc;
	    ready_next <= '1';
	end if;
    end process;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		pc <= unsigned(START_ADDR);
		ready <= '0';
	    else
		pc <= pc_next;
		ready <= ready_next;
	    end if;
	end if;
    end process;

end;
