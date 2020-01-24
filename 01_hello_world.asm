; Compile with: nasm -f elf <filename>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <filename>.o -o <filename>

SECTION .data
	str1 	db 		"Hello, cruel world!", 0x0A, 0x00
	str2 	db 		"How are you today?", 0x0A, 0x00

SECTION .text
	global _start

;--------------------------------------------------------------------------------
_start:
	mov 	eax, str1
	call 	str_print
	mov 	eax, str2
	call 	str_print
	jmp 	exit
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
get_str_len: 				; string address is in eax
	push 	ecx				; save ecx for return
	mov 	ecx, eax		; save address for pointer arithmetics

count_char:
	cmp 	byte [eax], 0	; check for null string termination
	jz 		save_str_len
	inc 	eax
	jmp 	count_char

save_str_len:				; calculate the string length
	sub 	eax, ecx
	pop 	ecx
	ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
str_print:					; prints the string with address in eax
	push 	edx				; saves the registers
	push 	ecx
	push 	ebx
	push 	eax				; saves the string address

	call 	get_str_len		; puts str length in edx
	mov 	edx, eax		; number of bytes of string for sys_write call
	pop 	eax				; gets the string address

	mov 	ecx, eax 		; the address of the string
	mov 	ebx, 1			; the STDOUT file descriptor
	mov 	eax, 4			; the sys_write syscall
	int 	80h

	pop 	ebx
	pop 	ecx
	pop 	edx
	ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
exit:
	mov 	ebx, 0			; 0 STATUS (NO ERRORS) for sys_exit
	mov 	eax, 1			; sys_exit syscall
	int 	80h
