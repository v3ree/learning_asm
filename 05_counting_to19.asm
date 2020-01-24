; Compile with: nasm -f elf <filename>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <filename>.o -o <filename>

%include 			"str_lib0.asm"

SECTION .data
	str0	db 		`Counting to 10:\n\0`

SECTION .text
	global 	_start

;-------------------------------------------------------------------------------

_start:
	mov 	eax, str0
	call 	str_print

	xor 	ecx, ecx 			; zero out counter
	mov 	ebx, 0x200030		; '0' front digit and space char
	push 	0x00				; push zero to stack for string termination

count:
	cmp 	ecx, 0x1400			; compare counter to 20 (stop limit)
	je 		exit
	mov 	eax, ecx
	cmp 	ecx, 0x0A00			; compare counter to 10
	jl	 	skip_tens
tens:
	sub 	eax, 0x0A00			; remove 10 to stay in ascii digit bounds
	mov 	ebx, 0x200031		; '1' front digit and space char
skip_tens:
	add 	eax, 0x3000			; add 48 to get ascii digit
	add 	eax, ebx			; add space char & front digit
	push 	eax					; push to stack for printing
	mov 	eax, esp
	call 	str_print
	pop 	eax					; remove char from stack
	add 	ecx, 0x0100
	jmp 	count

