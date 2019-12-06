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

entity veresk_shift is
    port (
	shift_in	: in cell_type;
	count		: in std_logic_vector(4 downto 0);

	arith		: in std_logic;
	right		: in std_logic;

	shift_out	: out cell_type
    );
end veresk_shift;

architecture rtl of veresk_shift is

    signal sign			: std_logic;
    signal fill			: std_logic_vector(31 downto 16);

    signal l1, l2, l4, l8, l16	: cell_type;
    signal r1, r2, r4, r8, r16	: cell_type;

begin

    sign <= arith and shift_in(31);
    fill <= (others => sign);

    l1 <= shift_in(30 downto 0) & '0' when count(0) = '1' else shift_in;
    l2 <= shift_in(29 downto 0) & "00" when count(1) = '1' else l1;
    l4 <= shift_in(27 downto 0) & "0000" when count(2) = '1' else l2;
    l8 <= shift_in(23 downto 0) & "00000000" when count(3) = '1' else l4;
    l16 <= shift_in(15 downto 0) & "0000000000000000" when count(4) = '1' else l8;

    r1 <= fill(31) & shift_in(31 downto 1) when count(0) = '1' else shift_in;
    r2 <= fill(31 downto 30) & r1(31 downto 2) when count(1) = '1' else r1;
    r4 <= fill(31 downto 28) & r2(31 downto 4) when count(2) = '1' else r2;
    r8 <= fill(31 downto 24) & r4(31 downto 8) when count(3) = '1' else r4;
    r16 <= fill(31 downto 16) & r8(31 downto 16) when count(4) = '1' else r8;

    shift_out <= r16 when right = '1' else l16;

end;
