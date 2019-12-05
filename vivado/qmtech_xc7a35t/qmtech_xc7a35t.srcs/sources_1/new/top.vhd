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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.veresk_pkg.all;

entity top is
    port (
	clk	: in std_logic;
	rst_n	: in std_logic;
	led	: out std_logic;
	uart_tx	: out std_logic;
	uart_rx	: in std_logic
    );
end top;

architecture Behavioral of top is

    signal rst		: std_logic;
    signal en		: std_logic;

    signal ibus_in	: ibus_in_type;
    signal ibus_out	: ibus_out_type;

    signal data_in	: dbus_in_type;
    signal data_out	: dbus_out_type;
    signal data_en	: std_logic;

    signal io_en	: std_logic;
    signal io_in	: dbus_in_type;
    signal io_out	: dbus_out_type;

    signal gpio_en	: std_logic;
    signal gpio		: cell_type;
    signal gpio_bus	: dbus_in_type;

    signal uart_en	: std_logic;
    signal uart_bus	: dbus_in_type;

begin

    rst <= not rst_n;
    led <= gpio(0);

    -- CPU --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		en <= '0';
	    else
		en <= '1';
	    end if;
	end if;
    end process;

    cpu: entity work.veresk
	port map(
	    clk		=> clk,
	    rst		=> rst,
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
	    rst 	=> rst,

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

    -- SOC --

    process (io_out, gpio_bus, uart_bus) begin
	gpio_en <= '0';
	uart_en <= '0';

	io_in.dat <= (others => '0');
	io_in.ready <= '0';

	if io_en = '1' then
	    case io_out.addr(9 downto 8) is
		when "00" => gpio_en <= '1';	io_in <= gpio_bus;
		when "01" => uart_en <= '1';	io_in <= uart_bus;
		when others =>
	    end case;
	end if;
    end process;

    gpio_i: entity work.gpio
	port map(
	    clk		=> clk,
	    rst		=> rst,

	    bus_en	=> gpio_en,
	    bus_in	=> io_out,
	    bus_out	=> gpio_bus,

	    gpio_out	=> gpio
	);

    uart_i: entity work.uart
	generic map(
	    clock_frequency => 50000000,
	    baud => 115200
	) port map(
	    clk		=> clk,
	    rst		=> rst,

	    bus_en	=> uart_en,
	    bus_in	=> io_out,
	    bus_out	=> uart_bus,

	    tx		=> uart_tx,
	    rx		=> uart_rx
	);

end Behavioral;
