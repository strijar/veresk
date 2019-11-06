ENTRY(_start)

MEMORY
{
	RAM (rwx)    : ORIGIN = 0x00000000, LENGTH = 0x00001000
}

_stack_size = 256;

SECTIONS
{
	.text :
	{
		*(.init)

		__text_begin = .;
		*(.text*)
		__text_end = .;
	} > RAM

	.rodata :
	{
		__rodata_begin = .;
		*(.rodata*)
		__rodata_end = .;
	} > RAM

	.data :
	{
		__data_begin = .;
		*(.data*)
		*(.eh_frame*)
		__data_end = .;
	} > RAM

	.bss ALIGN(4) :
	{
		__bss_begin = .;
		*(.bss*)
		*(.sbss*)
		__bss_end = ALIGN(4);
	} > RAM

	.stack ALIGN(4) :
	{
		. = . + _stack_size;
		_stack = .;
	} > RAM

	/* Set the start of the stack to the top of RAM: */

	/DISCARD/ :
	{
		*(.comment)
	}
}
