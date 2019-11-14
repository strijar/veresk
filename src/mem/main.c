int mem[] = { 1, 2, 3, 4, 5 };

void main(void) {
    for (int i = 0; i < 5; i++) {
	int a = mem[i];

	// asm("nop");
	// asm("nop");
	// asm("nop");

	mem[i] = a + 1;
    }
}
