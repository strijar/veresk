.PHONY: all clean
include ../common.mk

LDFLAGS += -Wl,-T../veresk.ld
CFLAGS += -Os

OBJECTS := start.o test.o

all: test.elf start.o test.bin test.coe

test.elf: $(OBJECTS)
	$(LD) -o test.elf $(LDFLAGS) $(OBJECTS)
	$(SIZE) test.elf
	$(OBJDUMP) -d test.elf > test.lst

clean:
	-$(RM) $(OBJECTS)
	-$(RM) *.elf *.bin *.coe *.lst

# Object file rules:

test.o: test.c
	$(CC) -c -o $@ $(CFLAGS) $<

start.o: ../start.S
	$(CC) -c -o $@ $(CFLAGS) $<
