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

    signal fetch_en		: std_logic := '0';
    signal fetch_in		: fetch_in_type;
    signal fetch, fetch_reg	: fetch_out_type;
    signal fetch_stall		: std_logic := '0';
    signal fetch_ready          : std_logic := '0';

    signal decode_en		: std_logic := '0';
    signal decode, decode_reg	: decode_type;
    signal decode_ready         : std_logic := '0';

    signal exec_en		: std_logic := '0';
    signal exec, exec_reg	: exec_type;
    signal exec_ready           : std_logic := '0';

    signal rs1_dat, rs2_dat	: cell_type;
    signal rs1, rs2		: reg_type;

begin

    fetch_en <= '1' when rst = '0' else '0';
    decode_en <= '1' when rst = '0' and fetch_ready = '1' else '0';
    exec_en <= '1' when rst = '0' and decode_ready = '1' else '0';

    fetch_in.pc <= fetch_reg.pc;
    fetch_in.step <= '1' when fetch_ready = '1' else '0';

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
	        fetch_reg.pc <= (others => '0');
	        fetch_reg.inst <= (others => '0');
	        fetch_ready <= '0';

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
	        decode_ready <= '0';

		exec_reg.wreg_en <= '0';
		exec_reg.wreg <= (others => '0');
		exec_reg.wdat <= (others => '0');
	        exec_ready <= '0';
	    else
	        fetch_ready <= fetch_en;
	        decode_ready <= decode_en;
	        exec_ready <= exec_en;

	        if fetch_en = '1' then
		    fetch_reg <= fetch;
		end if;

	        if decode_en = '1' then
		    decode_reg <= decode;
		end if;

	        if exec_en = '1' then
		    exec_reg <= exec;
	        end if;

	    end if;
	end if;
    end process;

    ---

    fetch_i: entity work.veresk_fetch
	port map(
	    fetch_in	=> fetch_in,
	    fetch_out	=> fetch,
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
	    fetch	=> fetch_reg,
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
