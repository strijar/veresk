PREFIX ?= /usr/local/riscv/bin/riscv32-unknown-elf-
CC := $(PREFIX)gcc
LD := $(PREFIX)gcc
SIZE := $(PREFIX)size
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
HEXDUMP ?= hexdump

CFLAGS += -march=rv32i -Wall -fomit-frame-pointer \
	-ffreestanding -fno-builtin -std=gnu99 \
	-Wall -Werror=implicit-function-declaration -ffunction-sections -fdata-sections

LDFLAGS += -march=rv32i -nostartfiles -Wl,-m,elf32lriscv --specs=nosys.specs -Wl,--no-relax -Wl,--gc-sections

# Rule for converting an ELF file to a binary file:
%.bin: %.elf
	$(OBJCOPY) -j .text -j .data -j .rodata -O binary $< $@

# Rule for generating coefficient files for initializing block RAM resources
# from binary files:
%.coe: %.bin
	echo "memory_initialization_radix=16;" > $@
	echo "memory_initialization_vector=" >> $@
	$(HEXDUMP) -v -e '1/4 "%08x\n"' $< >> $@
	echo ";" >> $@

