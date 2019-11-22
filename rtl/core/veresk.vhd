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

	io_en		: out std_logic;
	io_in		: in dbus_in_type;
	io_out		: out dbus_out_type
    );
end veresk;

architecture rtl of veresk is
    signal pc			: pc_type;

    signal dbus_in		: dbus_in_type;
    signal dbus_out		: dbus_out_type;

    type stall_type is (none, jump, delay);

    signal stall, stall_reg	: stall_type;

    signal fetch_in		: fetch_in_type;
    signal fetch		: fetch_out_type;

    signal decode_stall		: std_logic := '0';
    signal decode, decode_reg	: decode_type;

    signal exec, exec_reg	: exec_type;

    signal wb			: wreg_type;
    signal mem_out		: cell_type;

    signal wreg, wreg_reg	: wreg_type;

    signal rs1			: reg_type;
    signal rs1_dat, rs1_out	: cell_type;

    signal rs2			: reg_type;
    signal rs2_dat, rs2_out	: cell_type;

    signal rs1_wreg, rs1_load, rs1_alu	: std_logic;
    signal rs2_wreg, rs2_load, rs2_alu	: std_logic;

begin

    fetch_in.target_en <= exec_reg.target_taken;
    fetch_in.target <= exec_reg.target;

    wreg <= wb when wb.en = '1' else exec.wreg;

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

    -- Forwarding --

    rs1_dat <=
	exec_reg.wreg.dat when rs1_alu = '1' else
	wreg_reg.dat when rs1_wreg = '1' else
	mem_out when rs1_load = '1'
	else rs1_out;

    rs2_dat <=
	exec_reg.wreg.dat when rs2_alu = '1' else
	wreg_reg.dat when rs2_wreg = '1' else
	mem_out when rs2_load = '1'
	else rs2_out;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		rs1_wreg <= '0';
		rs2_wreg <= '0';
	    else
		rs1_wreg <= '0';
		rs2_wreg <= '0';

		if wreg.en = '1' then
		    if decode.req_rs1 = '1' then
			if wreg.rd = decode.rs1 then
			    rs1_wreg <= '1';
			end if;
		    end if;

		    if decode.req_rs2 = '1' then
			if wreg.rd = decode.rs2 then
			    rs2_wreg <= '1';
			end if;
		    end if;

		end if;
	    end if;
	end if;
    end process;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		rs1_alu <= '0';
		rs2_alu <= '0';
	    else
		rs1_alu <= '0';
		rs2_alu <= '0';

		if wreg.en = '1' then
		    if decode.req_rs1 = '1' then
			if exec.wreg.rd = decode.rs1 then
			    rs1_alu <= '1';
			end if;
		    end if;

		    if decode.req_rs2 = '1' then
			if exec.wreg.rd = decode.rs2 then
			    rs2_alu <= '1';
			end if;
		    end if;

		end if;
	    end if;
	end if;
    end process;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		rs1_load <= '0';
		rs2_load <= '0';
	    else
		rs1_load <= '0';
		rs2_load <= '0';

		if exec.mem_out.re = '1' then
		    if exec.wreg.rd = decode.rs1 and decode.req_rs1 = '1' then
			rs1_load <= '1';
		    end if;

		    if exec.wreg.rd = decode.rs2 and decode.req_rs2 = '1' then
			rs2_load <= '1';
		    end if;
		end if;

		if exec_reg.mem_out.re = '1' then
		    if exec_reg.wreg.rd = decode.rs1 and decode.req_rs1 = '1' then
--			rs1_load <= '1';
		    end if;

		    if exec_reg.wreg.rd = decode.rs2 and decode.req_rs2 = '1' then
--			rs2_load <= '1';
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

    -- Registers --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		wreg_reg.en <= '0';
		wreg_reg.rd <= (others => '0');
		wreg_reg.dat <= (others => '0');
	    else
		wreg_reg <= wreg;
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
		exec_reg.mem_out.re <= '0';
		exec_reg.mem_out.size <= (others => '0');
		exec_reg.mem_out.dat <= (others => '0');
		exec_reg.mem_out.addr <= (others => '0');
	    else
		exec_reg.wreg <= exec.wreg;

		exec_reg.target_taken <= exec.target_taken;
		exec_reg.target <= exec.target;

		exec_reg.mem_out.we <= exec.mem_out.we;
		exec_reg.mem_out.re <= exec.mem_out.re;

		if exec.mem_out.we = '1' then
		    exec_reg.mem_out.dat <= exec.mem_out.dat;
		end if;

		if exec.mem_out.we = '1' or exec.mem_out.re = '1' then
		    exec_reg.mem_out.addr <= exec.mem_out.addr;
		    exec_reg.mem_out.size <= exec.mem_out.size;
		end if;
	    end if;
	end if;
    end process;

    -- WB pipeline --

    wb.dat <= mem_out;

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		wb.en <= '0';
		wb.rd <= (others => '0');
	    else
		wb.en <= exec_reg.mem_out.re;

		if exec_reg.mem_out.re = '1' then
		    wb.rd <= exec_reg.wreg.rd;
		end if;
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
	    clk		=> clk,
	    rst		=> rst,
	
	    mem_in	=> exec_reg.mem_out,
	    mem_out	=> mem_out,
	    dbus_in	=> dbus_in,
	    dbus_out	=> dbus_out
	);

    -- DBus mux --

    data_out.addr <= dbus_out.addr;
    data_out.dat <= dbus_out.dat;

    io_out.addr <= dbus_out.addr;
    io_out.dat <= dbus_out.dat;

    io_en <= exec_reg.mem_out.addr(31);

    process (exec_reg.mem_out.addr, data_in, io_in, dbus_out) begin
	if exec_reg.mem_out.addr(31) = '0' then
	    dbus_in <= data_in;

	    data_out.re <= dbus_out.re;
	    data_out.we <= dbus_out.we;

	    io_out.re <= '0';
	    io_out.we <= (others => '0');
	else
	    dbus_in <= io_in;

	    data_out.re <= '0';
	    data_out.we <= (others => '0');

	    io_out.re <= dbus_out.re;
	    io_out.we <= dbus_out.we;
	end if;
    end process;

end;
