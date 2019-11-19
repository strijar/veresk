static char *mem = "Hello, World!";

void main(void) {
    char		*c = mem;
    volatile char	*io = 0x8000000;

    while (*c) {
	*io = *c;
	c++;
    }
}
