	.text
	.align 2
	.global _start

_start:
	la	sp, _stack
	jal	ra, main

L1:
	j	L1
