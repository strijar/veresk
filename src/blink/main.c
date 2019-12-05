#include <io.h>

void delay(unsigned int n) {
    while (--n) {
	asm("nop");
    }
}

void main(void) {
    volatile unsigned int *gpio = ADDR_GPIO;

    while (1) {
	*gpio = 0;
	delay(10000000);
	*gpio = 1;
	delay(10000000);
    }
}
