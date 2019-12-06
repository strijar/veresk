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
    signal pc, pc_next		: pc_type;
    signal inst			: cell_type;

    signal dbus_in		: dbus_in_type;
    signal dbus_out		: dbus_out_type;

    signal stall, stall_r	: std_logic;
    signal fetch_rst		: std_logic;
    signal fetch_in		: fetch_in_type;

    signal decode_rst		: std_logic;
    signal decode, decode_r	: decode_type;

    signal exec, exec_r		: exec_type;
    signal wb, wb_r		: wb_type;

    signal rs1_out, rs2_out	: cell_type;
    signal rs1_in, rs2_in	: cell_type;
    signal rd_out, rd_out_r	: rd_type;

    signal mem_out		: rd_type;

begin

    ibus_out.addr <= std_logic_vector(pc_next);

    fetch_in.step <= en and not stall;
    fetch_in.target <= decode_r.target when decode_r.target.en = '1' else exec_r.target;

    fetch_rst <= fetch_in.target.en or exec.target.en;
    decode_rst <= stall;

    mem_out.sel <= wb_r.rd.sel;
    mem_out.en <= wb_r.load;

    rd_out <=
	decode_r.rd	when decode_r.rd.en = '1' else
	mem_out		when mem_out.en = '1' else
	wb_r.rd;

    rs1_in <=
	exec_r.rd.dat	when exec_r.rd.en = '1' and decode_r.rs1_req = '1' and decode_r.rs1_sel = exec_r.rd.sel else
	rd_out.dat	when rd_out.en = '1' and decode_r.rs1_req = '1' and decode_r.rs1_sel = rd_out.sel else
	rd_out_r.dat	when rd_out_r.en = '1' and decode_r.rs1_req = '1' and decode_r.rs1_sel = rd_out_r.sel else
	mem_out.dat	when mem_out.en = '1' and decode_r.rs1_req = '1' and decode_r.rs1_sel = mem_out.sel else
	rs1_out;

    rs2_in <=
	exec_r.rd.dat	when exec_r.rd.en = '1' and decode_r.rs2_req = '1' and decode_r.rs2_sel = exec_r.rd.sel else
	rd_out.dat	when rd_out.en = '1' and decode_r.rs2_req = '1' and decode_r.rs2_sel = rd_out.sel else
	rd_out_r.dat	when rd_out_r.en = '1' and decode_r.rs2_req = '1' and decode_r.rs2_sel = rd_out_r.sel else
	mem_out.dat	when mem_out.en = '1' and decode_r.rs2_req = '1' and decode_r.rs2_sel = mem_out.sel else
	rs2_out;

    stall <=
	'0' when stall_r = '1' else
	'1' when decode_r.load = '1' and decode.rs1_req = '1' and decode.rs1_sel = decode_r.rd.sel else
	'1' when decode_r.load = '1' and decode.rs2_req = '1' and decode.rs2_sel = decode_r.rd.sel else
	'0';

    -- PC and stall --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
	        pc <= START_ADDR;
	        stall_r <= '0';
	    else
		pc <= pc_next;
		stall_r <= stall;
	    end if;
	end if;
    end process;

    -- RD delay --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
	        rd_out_r.en <= '0';
	        rd_out_r.sel <= (others => '0');
	        rd_out_r.dat <= (others => '0');
	    else
		rd_out_r <= rd_out;
	    end if;
	end if;
    end process;

    -- Decode pipeline --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' or decode_rst = '1' then
		if rst = '1' then
		    decode_r.pc <= START_ADDR;
		end if;

		decode_r.fn3 <= (others => '0');
		decode_r.rs1_sel <= (others => '0');
		decode_r.rs2_sel <= (others => '0');
		decode_r.imm <= (others => '0');
		decode_r.fn7 <= (others => '0');
		decode_r.rs1_req <= '0';
		decode_r.rs2_req <= '0';
		decode_r.jal <= '0';
		decode_r.jalr <= '0';
		decode_r.branch <= '0';
		decode_r.alu <= '0';
		decode_r.alu_imm <= '0';
		decode_r.alu_reg <= '0';
		decode_r.load <= '0';
		decode_r.store <= '0';
		decode_r.lui <= '0';
		decode_r.auipc <= '0';

		decode_r.target.en <= '0';
		decode_r.target.addr <= (others => '0');

		decode_r.rd.en <= '0';
		decode_r.rd.sel <= (others => '0');
		decode_r.rd.dat <= (others => '0');
	    else
		decode_r <= decode;
	    end if;
	end if;
    end process;

    -- Decode/Exec pipeline --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		exec_r.pc <= START_ADDR;
		exec_r.rd.en <= '0';
		exec_r.rd.sel <= (others => '0');
		exec_r.rd.dat <= (others => '0');
		exec_r.target.en <= '0';
		exec_r.target.addr <= (others => '0');
		exec_r.mem_out.we <= '0';
		exec_r.mem_out.re <= '0';
		exec_r.mem_out.size <= (others => '0');
		exec_r.mem_out.dat <= (others => '0');
		exec_r.mem_out.addr <= (others => '0');
	    else
		exec_r.pc <= exec.pc;
		exec_r.rd <= exec.rd;
		exec_r.target <= exec.target;

		exec_r.mem_out.we <= exec.mem_out.we;
		exec_r.mem_out.re <= exec.mem_out.re;

		if exec.mem_out.we = '1' then
		    exec_r.mem_out.dat <= exec.mem_out.dat;
		end if;

		if exec.mem_out.we = '1' or exec.mem_out.re = '1' then
		    exec_r.mem_out.addr <= exec.mem_out.addr;
		    exec_r.mem_out.size <= exec.mem_out.size;
		end if;
	    end if;
	end if;
    end process;

    -- Exec/WB pipeline --

    process (clk, rst) begin
	if rising_edge(clk) then
	    if rst = '1' then
		wb_r.rd.en <= '0';
		wb_r.rd.sel <= (others => '0');
		wb_r.rd.dat <= (others => '0');
		wb_r.load <= '0';
	    else
		wb_r <= wb;
	    end if;
	end if;
    end process;

    ---

    fetch_i: entity work.veresk_fetch
	port map(
	    rst		=> fetch_rst,
	    pc		=> pc,
	    fetch_in	=> fetch_in,
	    ibus_in	=> ibus_in,

	    inst	=> inst,
	    pc_next	=> pc_next
	);

    regs_i: entity work.veresk_regs
	port map(
	    clk 	=> clk,
	    rst 	=> rst,

	    r1_in	=> decode.rs1_sel,
	    r2_in	=> decode.rs2_sel,

	    r1_out	=> rs1_out,
	    r2_out	=> rs2_out,

	    wreg_en	=> rd_out.en,
	    wreg_in	=> rd_out.sel,
	    wdat_in	=> rd_out.dat
	);

    decode_i: entity work.veresk_decode
	port map(
	    pc		=> pc,
	    inst	=> inst,
	    decode_out	=> decode
	);

    exec_i: entity work.veresk_exec
	port map(
	    r1		=> rs1_in,
	    r2		=> rs2_in,
	    decode	=> decode_r,

	    exec_out	=> exec
	);

    wb_i: entity work.veresk_wb
	port map(
	    exec	=> exec_r,
	    wb_out	=> wb
	);

    mem_i: entity work.veresk_mem
	port map(
	    clk		=> clk,
	    rst		=> rst,

	    mem_in	=> exec_r.mem_out,
	    mem_out	=> mem_out.dat,
	    dbus_in	=> dbus_in,
	    dbus_out	=> dbus_out
	);

    -- DBus mux --

    data_out.addr <= dbus_out.addr;
    data_out.dat <= dbus_out.dat;

    io_out.addr <= dbus_out.addr;
    io_out.dat <= dbus_out.dat;

    io_en <= exec_r.mem_out.addr(31);

    process (exec_r.mem_out.addr, data_in, io_in, dbus_out) begin
	if exec_r.mem_out.addr(31) = '0' then
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
