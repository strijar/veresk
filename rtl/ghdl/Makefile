GHDL=ghdl
GHDLFLAGS= --std=93 --ieee=synopsys --workdir=work
GHDLRUNFLAGS=--wave=tb_veresk.ghw --stop-time=8us

RAM = ram_hello

SRC = \
    ../core/veresk_pkg.vhd\
    ../core/veresk_fetch.vhd\
    ../core/veresk_decode.vhd\
    ../core/veresk_regs.vhd\
    ../core/veresk_alu.vhd\
    ../core/veresk_branch.vhd\
    ../core/veresk_exec.vhd\
    ../core/veresk_mem.vhd\
    ../core/veresk_wb.vhd\
    ../core/veresk.vhd\
    ../soc/gpio.vhd\
    ../soc/uart.vhd\
    $(RAM).vhd\
    tb_veresk.vhd

OBJS = \
    work/veresk_pkg.o \
    work/veresk_fetch.o \
    work/veresk_decode.o \
    work/veresk_regs.o \
    work/veresk_alu.o \
    work/veresk_branch.o \
    work/veresk_exec.o \
    work/veresk_mem.o \
    work/veresk_wb.o \
    work/veresk.o \
    work/gpio.o \
    work/uart.o \
    work/$(RAM).o \
    work/tb_veresk.o

all: tb_veresk

tb_veresk: work/work-obj93.cf $(OBJS)
	$(GHDL) -e $(GHDLFLAGS) $@

work/work-obj93.cf: work $(SRC)
	$(GHDL) -i $(GHDLFLAGS) $(SRC)

work:
	mkdir work

run: tb_veresk
	$(GHDL) -r tb_veresk $(GHDLRUNFLAGS)

clean:
	rm -rf work tb_veresk *.o *.ghw *.log

# Targets to analyze files

$(OBJS): $(SRC)

work/%.o: %.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

work/%.o: ../core/%.vhd
	$(GHDL) -a $(GHDLFLAGS) $<

work/%.o: ../soc/%.vhd
	$(GHDL) -a $(GHDLFLAGS) $<
