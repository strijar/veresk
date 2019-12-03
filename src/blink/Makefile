.PHONY: all clean
include ../common.mk

LDFLAGS += -Wl,-T../veresk.ld
CFLAGS += -Os -I..

OBJECTS := start.o main.o

all: main.elf start.o main.bin main.coe

main.elf: $(OBJECTS)
	$(LD) -o main.elf $(LDFLAGS) $(OBJECTS)
	$(SIZE) main.elf
	$(OBJDUMP) -d main.elf > main.lst

clean:
	-$(RM) $(OBJECTS)
	-$(RM) *.elf *.bin *.coe *.lst

# Object file rules:

main.o: main.c
	$(CC) -c -o $@ $(CFLAGS) $<

start.o: ../start.S
	$(CC) -c -o $@ $(CFLAGS) $<
