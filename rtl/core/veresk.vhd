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
    signal pc			: pc_type;

    type stall_type is (none, jump, delay);

    signal stall, stall_reg	: stall_type;

    signal fetch_in		: fetch_in_type;
    signal fetch		: fetch_out_type;

    signal decode_stall		: std_logic := '0';
    signal decode, decode_reg	: decode_type;

    signal exec, exec_reg	: exec_type;

    signal wreg			: wreg_type;

    signal rs1			: reg_type;
    signal rs1_bypass		: std_logic;
    signal rs1_dat, rs1_out	: cell_type;

    signal rs2			: reg_type;
    signal rs2_bypass		: std_logic;
    signal rs2_dat, rs2_out	: cell_type;

begin

    fetch_in.target_en <= exec_reg.target_taken;
    fetch_in.target <= exec_reg.target;

    wreg <= exec.wreg;

    -- Control --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		stall_reg <= none;
	    else
		stall_reg <= stall;
	    end if;
	end if;
    end process;

    process (decode_reg, exec, stall_reg) begin
	case stall_reg is
	    when none =>
		if exec.target_taken = '1' then
		    stall <= jump;
		else
		    stall <= none;
		end if;

	    when jump =>
		stall <= delay;

	    when delay =>
		stall <= none;
	end case;
    end process;

    with stall select fetch_in.step <=
	'1' when none,
	'1' when delay,
	'0' when others;

    with stall select decode_stall <=
	'0' when none,
	'1' when others;

    -- Bypass --

    rs1_dat <= exec_reg.wreg.dat when rs1_bypass = '1' else rs1_out;
    rs2_dat <= exec_reg.wreg.dat when rs2_bypass = '1' else rs2_out;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		rs1_bypass <= '0';
		rs2_bypass <= '0';
	    else
		rs1_bypass <= '0';
		rs2_bypass <= '0';

		if wreg.en = '1' then
		    if wreg.rd = decode.rs1 and decode.req_rs1 = '1' then
			rs1_bypass <= '1';
		    end if;

		    if wreg.rd = decode.rs2 and decode.req_rs2 = '1' then
			rs2_bypass <= '1';
		    end if;
		end if;
	    end if;
	end if;
    end process;

    -- PC --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
	        pc <= (others => '0');
	    else
		pc <= fetch.pc_next;
	    end if;
	end if;
    end process;

    -- Decode pipeline --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' or decode_stall = '1' then
		if rst = '1' then
		    decode_reg.pc <= (others => '0');
		end if;

		decode_reg.op <= (others => '0');
		decode_reg.rd <= (others => '0');
		decode_reg.fn3 <= (others => '0');
		decode_reg.rs1 <= (others => '0');
		decode_reg.rs2 <= (others => '0');
		decode_reg.imm <= (others => '0');
		decode_reg.fn7 <= (others => '0');
		decode_reg.req_rs1 <= '0';
		decode_reg.req_rs2 <= '0';
	    else
		decode_reg <= decode;
	    end if;
	end if;
    end process;

    -- Exec pipeline --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		exec_reg.wreg.en <= '0';
		exec_reg.wreg.rd <= (others => '0');
		exec_reg.wreg.dat <= (others => '0');
		exec_reg.target_taken <= '0';
		exec_reg.target <= (others => '0');
		exec_reg.mem_out.we <= '0';
		exec_reg.mem_out.size <= (others => '0');
		exec_reg.mem_out.dat <= (others => '0');
		exec_reg.mem_out.addr <= (others => '0');
	    else
		exec_reg <= exec;
	    end if;
	end if;
    end process;

    ---

    fetch_i: entity work.veresk_fetch
	port map(
	    pc		=> pc,
	    fetch_in	=> fetch_in,
	    ibus_in	=> ibus_in,

	    fetch_out	=> fetch,
	    ibus_out	=> ibus_out
	);

    regs_i: entity work.veresk_regs
	port map(
	    clk 	=> clk,
	    rst 	=> rst,

	    r1_in	=> decode.rs1,
	    r2_in	=> decode.rs2,

	    dat1_out	=> rs1_out,
	    dat2_out	=> rs2_out,

	    wreg_en	=> wreg.en,
	    wreg_in	=> wreg.rd,
	    wdat_in	=> wreg.dat
	);

    decode_i: entity work.veresk_decode
	port map(
	    pc		=> fetch.pc,
	    inst	=> fetch.inst,
	    decode_out	=> decode
	);

    exec_i: entity work.veresk_exec
	port map(
	    r1		=> rs1_dat,
	    r2		=> rs2_dat,
	    decode	=> decode_reg,

	    exec_out	=> exec
	);

    mem_i: entity work.veresk_mem
	port map(
	    mem_in	=> exec_reg.mem_out,
	    data_out	=> data_out
	);

end;
