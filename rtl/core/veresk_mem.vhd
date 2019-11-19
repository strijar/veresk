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

entity veresk_mem is
    port (
	clk		: in std_logic;
	rst		: in std_logic;

	mem_in		: in mem_out_type;
	mem_out		: out cell_type;
	data_in		: in dbus_in_type;
	data_out	: out dbus_out_type
    );
end veresk_mem;

architecture rtl of veresk_mem is

    signal read_size	: op_mem_type;
    signal read_addr	: std_logic_vector(1 downto 0);

begin

    data_out.addr <= mem_in.addr;

    -- Read data mux

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		read_size <= (others => '0');
		read_addr <= (others => '0');
	    else
		read_size <= mem_in.size;
		read_addr <= mem_in.addr(1 downto 0);
	    end if;
	end if;
    end process;

    process (data_in, read_size, read_addr) begin
	mem_out <= (others => '0');

	case read_size is
	    when RV32_MEM_SIZE_B | RV32_MEM_SIZE_BU =>
		if read_size = RV32_MEM_SIZE_B then
		    mem_out(31 downto 8) <= (others => data_in.dat(7));
		end if;

		case read_addr is
		    when b"00" => mem_out(7 downto 0) <= data_in.dat(7 downto 0);
		    when b"01" => mem_out(7 downto 0) <= data_in.dat(15 downto 8);
		    when b"10" => mem_out(7 downto 0) <= data_in.dat(23 downto 16);
		    when b"11" => mem_out(7 downto 0) <= data_in.dat(31 downto 24);
		    when others =>
		end case;

	    when RV32_MEM_SIZE_H | RV32_MEM_SIZE_HU =>
		if read_size = RV32_MEM_SIZE_H then
		    mem_out(31 downto 16) <= (others => data_in.dat(15));
		end if;

		case read_addr is
		    when b"00" => mem_out(15 downto 0) <= data_in.dat(15 downto 0);
		    when b"10" => mem_out(15 downto 0) <= data_in.dat(31 downto 16);
		    when others =>
		end case;

	    when RV32_MEM_SIZE_W =>
		mem_out <= data_in.dat;

	    when others =>
	end case;
    end process;

    -- Write data mux

    process (mem_in) begin
	data_out.we <= (others => '0');
	data_out.dat <= (others => '0');

	if mem_in.we = '1' then
	    case mem_in.size is
		when RV32_MEM_SIZE_B =>
		    case mem_in.addr(1 downto 0) is
			when b"00" =>
			    data_out.we <= b"0001";
			    data_out.dat(7 downto 0) <= mem_in.dat(7 downto 0);

			when b"01" =>
			    data_out.we <= b"0010";
			    data_out.dat(15 downto 8) <= mem_in.dat(7 downto 0);

			when b"10" =>
			    data_out.we <= b"0100";
			    data_out.dat(23 downto 16) <= mem_in.dat(7 downto 0);

			when b"11" =>
			    data_out.we <= b"1000";
			    data_out.dat(31 downto 24) <= mem_in.dat(7 downto 0);

			when others =>
		    end case;

		when RV32_MEM_SIZE_H =>
		    case mem_in.addr(1 downto 0) is
			when b"00" =>
			    data_out.we <= b"0011";
			    data_out.dat(15 downto 0) <= mem_in.dat(15 downto 0);

			when b"10" =>
			    data_out.we <= b"1100";
			    data_out.dat(31 downto 16) <= mem_in.dat(15 downto 0);

			when others =>
		    end case;

		when RV32_MEM_SIZE_W =>
		    data_out.we <= b"1111";
		    data_out.dat <= mem_in.dat;

		when others =>
	    end case;
	end if;
    end process;

end;
