; Compile with: nasm -f elf <filename>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <filename>.o -o <filename>

%include 			"str_lib0.asm"

SECTION .data
	str1 	db 		`Hello, cruel world!\n\0`
	str2 	db 		`Look on my works, ye mighty, and despair!\n\0`

SECTION .text
	global _start

;--------------------------------------------------------------------------------
_start:
	mov 	eax, str1
	call 	str_print

	mov 	eax, str2
	call 	str_print

	pop ecx 			; save number of arguments
	pop eax 			; pop program name
	dec ecx

print_args:
	cmp ecx, 0
	jz exit
	pop eax				; pop and print the arg
	call str_print

	call print_newline_char

	dec ecx
	jmp print_args
