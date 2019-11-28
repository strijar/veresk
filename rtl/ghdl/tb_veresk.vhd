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
use ieee.std_logic_textio.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library std;
use work.veresk_pkg.all;

entity tb_veresk is
end tb_veresk;

architecture rtl of tb_veresk is

    signal clk 		: std_logic := '1';
    signal reset 	: std_logic := '1';

    signal en		: std_logic;

    signal ibus_in	: ibus_in_type;
    signal ibus_out	: ibus_out_type;

    signal data_in	: dbus_in_type;
    signal data_out	: dbus_out_type;
    signal data_en	: std_logic;

    signal io_en	: std_logic;
    signal io_in	: dbus_in_type;
    signal io_out	: dbus_out_type;

begin

    -- 100 MHz clock

    process begin
	wait for 5 ns; clk  <= not clk;
    end process;

    -- Reset

    process begin
	wait for 15 ns;
	reset <= '0';
	wait;
    end process;

    -- CPU --

    process (clk, reset) begin
	if rising_edge(clk) then
	    if reset = '1' then
		en <= '0';
	    else
		en <= '1';
	    end if;
	end if;
    end process;

    cpu: entity work.veresk
	port map(
	    clk		=> clk,
	    rst		=> reset,
	    en		=> en,

	    ibus_in	=> ibus_in,
	    ibus_out	=> ibus_out,

	    data_in	=> data_in,
	    data_out	=> data_out,

	    io_en	=> io_en,
	    io_in	=> io_in,
	    io_out	=> io_out
	);

    ram_i: entity work.ram
	generic map(
	    addr_bits	=> 13,
	    data_bits	=> 32
	)
	port map(
	    clk 	=> clk,
	    rst 	=> reset,

	    a_addr	=> ibus_out.addr(12 downto 0),
	    a_dout	=> ibus_in.dat,
	    a_we	=> '0',
	    a_din	=> (others => '0'),

	    b_en	=> data_en,
	    b_addr	=> data_out.addr(12 downto 0),
	    b_dout	=> data_in.dat,
	    b_we	=> data_out.we,
	    b_din	=> data_out.dat
	);

end rtl;
