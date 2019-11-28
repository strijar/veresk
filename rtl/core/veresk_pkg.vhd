library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package veresk_pkg is

    -- Opcodes --

    subtype op_type is std_logic_vector(6 downto 0);

    constant RV32I_OP_LOAD:		op_type := b"00_000_11";
    constant RV32I_OP_STORE:		op_type := b"01_000_11";
    constant RV32I_OP_BRANCH:		op_type := b"11_000_11";
    constant RV32I_OP_JALR:		op_type := b"11_001_11";
    constant RV32I_OP_FENCE:		op_type := b"00_011_11";
    constant RV32I_OP_JAL:		op_type := b"11_011_11";
    constant RV32I_OP_IMM:		op_type := b"00_100_11";
    constant RV32I_OP_REG:		op_type := b"01_100_11";
    constant RV32I_OP_SYS:		op_type := b"11_100_11";
    constant RV32I_OP_AUIPC:		op_type := b"00_101_11";
    constant RV32I_OP_LUI:		op_type := b"01_101_11";

    subtype op_fn3_type is std_logic_vector(2 downto 0);

    constant RV32_FN3_ADDI:		op_fn3_type := "000";
    constant RV32_FN3_SLTI:		op_fn3_type := "010";
    constant RV32_FN3_SLTIU:		op_fn3_type := "011";
    constant RV32_FN3_XORI:		op_fn3_type := "100";
    constant RV32_FN3_ORI:		op_fn3_type := "110";
    constant RV32_FN3_ANDI:		op_fn3_type := "111";
    constant RV32_FN3_SLLI:		op_fn3_type := "001";
    constant RV32_FN3_SRLI:		op_fn3_type := "101";	-- SRAI

    constant RV32_FN3_ADD:		op_fn3_type := "000";	-- SUB
    constant RV32_FN3_SLL:		op_fn3_type := "001";
    constant RV32_FN3_SLT:		op_fn3_type := "010";
    constant RV32_FN3_SLTU:		op_fn3_type := "011";
    constant RV32_FN3_XOR:		op_fn3_type := "100";
    constant RV32_FN3_SRL:		op_fn3_type := "101";	-- SRA
    constant RV32_FN3_OR:		op_fn3_type := "110";
    constant RV32_FN3_AND:		op_fn3_type := "111";

    subtype op_fn7_type is std_logic_vector(6 downto 0);

    constant RV32_FN7_0:		op_fn7_type := "0000000";
    constant RV32_FN7_1:		op_fn7_type := "0100000";

    subtype op_sys_type is std_logic_vector(11 downto 0);

    constant RV32_SYS_SCALL:		op_sys_type := "000000000000";
    constant RV32_SYS_SBREAK:		op_sys_type := "000000000001";
    constant RV32_SYS_RDCYCLE:		op_sys_type := "110000000000";
    constant RV32_SYS_RDCYCLEH:		op_sys_type := "110010000000";
    constant RV32_SYS_RDTIME:		op_sys_type := "110000000001";
    constant RV32_SYS_RDTIMEH:		op_sys_type := "110010000001";
    constant RV32_SYS_RDINSTRET:	op_sys_type := "110000000010";
    constant RV32_SYS_RDINSTRETH:	op_sys_type := "110010000010";

    constant RV32_REG_ZERO:		std_logic_vector := "00000";

    subtype op_mem_type is std_logic_vector(2 downto 0);

    constant RV32_MEM_SIZE_B:		op_mem_type := "000";
    constant RV32_MEM_SIZE_H:		op_mem_type := "001";
    constant RV32_MEM_SIZE_W:		op_mem_type := "010";
    constant RV32_MEM_SIZE_D:		op_mem_type := "011";
    constant RV32_MEM_SIZE_BU:		op_mem_type := "100";
    constant RV32_MEM_SIZE_HU:		op_mem_type := "101";

    subtype op_test_type is std_logic_vector(2 downto 0);

    constant RV32_TEST_EQ:		op_test_type := "000";
    constant RV32_TEST_NE:		op_test_type := "001";
    constant RV32_TEST_LT:		op_test_type := "100";
    constant RV32_TEST_GE:		op_test_type := "101";
    constant RV32_TEST_LTU:		op_test_type := "110";
    constant RV32_TEST_GEU:		op_test_type := "111";

    constant CELL_BITS: 		integer := 32;

    subtype cell_type is std_logic_vector(CELL_BITS-1 downto 0);
    subtype pc_type is unsigned(CELL_BITS-1 downto 0);

    -- Instruction bus

    type ibus_out_type is record
	addr	: cell_type;
    end record;

    type ibus_in_type is record
	dat	: cell_type;
	ready	: std_logic;
    end record;

    -- Data/IO bus

    type dbus_out_type is record
	addr	: cell_type;
	dat	: cell_type;
	we	: std_logic_vector(3 downto 0);
	re	: std_logic;
    end record;

    type dbus_in_type is record
	dat	: cell_type;
	ready	: std_logic;
    end record;

    type target_type is record
	en		: std_logic;
	addr		: pc_type;
    end record;

    subtype reg_type is std_logic_vector(4 downto 0);

    constant REG0:		reg_type := b"00000";

    type rd_type is record
	en		: std_logic;
	sel		: reg_type;
	dat		: cell_type;
    end record;

    type fetch_in_type is record
	step		: std_logic;
	target		: target_type;
    end record;

    type decode_type is record
	pc		: pc_type;

	fn3		: op_fn3_type;
	fn7		: op_fn7_type;
	imm		: cell_type;

	rs1_sel		: reg_type;
	rs2_sel		: reg_type;

	rs1_req		: std_logic;
	rs2_req		: std_logic;

	jal		: std_logic;
	jalr		: std_logic;
	branch		: std_logic;
	alu		: std_logic;
	alu_imm		: std_logic;
	alu_reg		: std_logic;
	load		: std_logic;
	store		: std_logic;
	lui		: std_logic;
	auipc		: std_logic;

	rd		: rd_type;
	target		: target_type;
    end record;

    type mem_out_type is record
	addr	: cell_type;
	dat	: cell_type;
	we	: std_logic;
	size	: op_mem_type;
	re	: std_logic;
    end record;

    type exec_type is record
	pc		: pc_type;
	rd		: rd_type;
	target		: target_type;
	mem_out		: mem_out_type;
    end record;

    type wb_type is record
	rd		: rd_type;
    end record;

    type alu_type is record
	en		: std_logic;
	dat		: cell_type;
    end record;

    -- Vectors

    constant START_ADDR		: pc_type := x"0000_0000";

end package;
