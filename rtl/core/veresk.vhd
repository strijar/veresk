library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.veresk_pkg.all;

entity veresk is
    port (
	clk		: in std_logic;
	rst		: in std_logic;
	en		: in std_logic;

	ibus_in		: in ibus_in_type;
	ibus_out	: out ibus_out_type;

	data_in		: in dbus_in_type;
	data_out	: out dbus_out_type;

	trace_out	: out trace_type
    );
end veresk;

architecture rtl of veresk is

    signal idle			: std_logic;

    signal fetch_in		: fetch_in_type;
    signal fetch_out		: fetch_out_type;
    signal fetch_stall		: std_logic;

    signal decode_en		: std_logic;
    signal decode, decode_reg	: decode_type;
    signal decode_hazard	: std_logic;

    signal exec_en		: std_logic;
    signal exec, exec_reg	: exec_type;

    signal rs1_dat, rs2_dat	: cell_type;
    signal rs1, rs2		: reg_type;

begin

    fetch_in.target_en <= '0';
    fetch_in.target <= (others => '0');

    decode_en <= '1';
    exec_en <= '1';

    process (clk, rst) begin
    	if rising_edge(clk) then
	    if rst = '1' then
		idle <= '1';
		fetch_stall <= '0';
	    else
		idle <= '0';

		if fetch_stall = '1' then
		    fetch_stall <= '0';
		elsif decode_hazard = '1' then
		    fetch_stall <= '1';
		end if;
	    end if;
	end if;
    end process;

    process (idle, decode_hazard, fetch_stall) begin
	fetch_in.step <= not idle;

	if fetch_stall = '0' then
	    if decode_hazard = '1' then
		fetch_in.step <= '0';
	    end if;
	end if;
    end process;

    process (exec, decode) begin
	decode_hazard <= '0';

	if fetch_stall = '0' then
	    if exec.wreg_en = '1' then
		if exec.wreg = decode.rs1 and decode.hazard_rs1 = '1' then
		    decode_hazard <= '1';
		end if;

		if exec.wreg = decode.rs2 and decode.hazard_rs2 = '1' then
		    decode_hazard <= '1';
		end if;
	    end if;
	end if;
    end process;

    --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		decode_reg.subset <= none;
		decode_reg.op <= (others => '0');
		decode_reg.rd <= (others => '0');
		decode_reg.fn3 <= (others => '0');
		decode_reg.rs1 <= (others => '0');
		decode_reg.rs2 <= (others => '0');
		decode_reg.imm <= (others => '0');
		decode_reg.fn7 <= (others => '0');
		decode_reg.hazard_rs1 <= '0';
		decode_reg.hazard_rs2 <= '0';
	    elsif decode_en = '1' then
		decode_reg <= decode;
	    end if;
	end if;
    end process;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		exec_reg.wreg_en <= '0';
		exec_reg.wreg <= (others => '0');
		exec_reg.wdat <= (others => '0');
	    elsif exec_en = '1' then
		exec_reg <= exec;
	    end if;
	end if;
    end process;

    ---

    fetch_i: entity work.veresk_fetch
	port map(
	    clk 	=> clk,
	    rst 	=> rst,

	    fetch_in	=> fetch_in,
	    fetch_out	=> fetch_out,
	    ibus_in	=> ibus_in,
	    ibus_out	=> ibus_out
	);

    regs_i: entity work.veresk_regs
	port map(
	    clk 	=> clk,
	    rst 	=> rst,

	    r1_in	=> decode.rs1,
	    r2_in	=> decode.rs2,

	    dat1_out	=> rs1_dat,
	    dat2_out	=> rs2_dat,

	    wreg_en	=> exec.wreg_en,
	    wreg_in	=> exec.wreg,
	    wdat_in	=> exec.wdat
	);

    decode_i: entity work.veresk_decode
	port map(
	    fetch	=> fetch_out,
	    decode_out	=> decode
	);

    exec_i: entity work.veresk_exec
	port map(
	    r1		=> rs1_dat,
	    r2		=> rs2_dat,
	    decode	=> decode_reg,

	    exec_out	=> exec
	);

end;
