#include <io.h>

int putchar(int c) {
    volatile *uart_data = ADDR_UART_DATA;
    volatile *uart_stat = ADDR_UART_STAT;

    while (*uart_stat & UART_TX_BUSY);
    *uart_data = c;
}

static char *str = "Hello, World!";

void main(void) {
    char		*c = str;

    while (*c) {
	putchar(*c);
	c++;
    }
}
