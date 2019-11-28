void delay(int n) {
    while (n--) {
	asm("nop");
    }
}

void main(void) {
    volatile int *io;

    io = 0x80000000;

    while (1) {
	*io = 0;
	delay(10);
	*io = 1;
	delay(10);
    }
}
