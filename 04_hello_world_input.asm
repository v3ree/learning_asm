; Compile with: nasm -f elf <filename>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <filename>.o -o <filename>

%include 			"str_lib0.asm"

SECTION .data
	str0	db 		"Please write your name: ", 0x00
	str1 	db 		"Hello, ", 0x00

SECTION .bss
	name 	resb 	255

SECTION .text
	global 	_start

;-------------------------------------------------------------------------------

_start:
	mov 	eax, str0
	call 	str_print

	mov 	eax, name
	call 	read_input

	mov 	eax, str1
	call 	str_print

	mov 	eax, name
	call 	str_print

	jmp exit
