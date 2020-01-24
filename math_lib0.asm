
%ifndef MATH_LIB
    %define MATH_LIB

;-------------------------------------------------------------------------------
	
SECTION .text

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; CHECK IF INTEGER IS NEGATIVE (1 as sign bit)

check_neg_bit:					; checks if the integer from eax has neg sign
	push 	edx					; returns in eax 1 if neg and 0 if positive
	cdq 						; (extends sign eax->edx)
	cmp 	edx, 0
	je 		.positive
	mov 	eax, 1
	jmp 	.done

.positive:
	mov 	eax, 0

.done:
	pop 	edx
	ret
;--------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; RETURN 1 IF EVEN NUMBER, 0 IF ODD

is_even:							; number is in eax, result returned in eax
	push 		ebx
	push 		edx

	xor 		edx, edx
	mov 		ebx, 2
	idiv 		ebx
	cmp 		edx, 0				; check remainder if division by 2
	je 			.even

.odd:
	mov 		eax, 0				; if odd return 0
	jmp 		.done

.even:
	mov 		eax, 1				; if even return 1

.done:
	pop 		edx
	pop 		ebx
	ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; RAISE TO POWER
									; raise eax to power in ecx, return in eax
raise_to_power:						; if error return ecx = -1, ecx = 0 if ok
	cmp 		ecx, 0
	jnz 		.not_zero_power
	mov 		eax, 1
	ret

.not_zero_power:
	push 		ebx
	push 		eax					; save number for processing if valid

	mov 		eax, edx
	call 		check_neg_bit		; check if negative integer
	cmp 		eax, 0
	je 			.valid

.invalid:
	pop 		eax
	pop 		ebx
	mov 		eax, 0
	mov 		ecx, -1
	ret

.valid:
	pop 		ebx					; restore number in ebx
	mov 		eax, 1				; 1 * n * n * ...

.loop:								; ecx holds power, loop uses it to count
	mul 		ebx
	loop 		.loop
	
.done:
	mov 		ecx, 0				; no error
	pop 		ebx
	ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; SQUARE ROOT AS INTEGER APPROXIMATION
									; square root of eax returned in eax
square_root:						; returns -1 if invalid negative number
	push 		eax					; loading stack with number
	call 		check_neg_bit		; check if negative integer
	cmp 		eax, 1
	jne 		.valid

.invalid:
	pop 		eax					; remove eax from stack
	push 		-1					; push -1 as result to be returned in eax
	jmp 		.done

.valid:
	fild 		DWORD [esp]         ; load the integer from stack to fstack(0)
	fsqrt             				; compute square root and store in fstack(0)
	fistp 		DWORD [esp] 		; store the result in eax and pop fstack(0)

.done:
	pop 		eax					; pop result from stack
	ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; FACTORIAL OF SIGNED INTEGER

factorial:							; eax for input and output
	cmp 		eax, 0
	jnz 		.not_zero_factorial
	mov 		eax, 1
	ret

.not_zero_factorial:
	push 		ebx					; save registers
	push 		ecx
	push 		edx
	push 		esi

	xor 		esi, esi 			; zero out esi so it can hold sign of integer
	mov 		ebx, eax			; save number in ebx for later use
	call 		check_neg_bit		; check if negative integer
	cmp 		eax, 0
	je 			.positive

.negative:
	mov 		eax, ebx			; check if integer is even
	call 		is_even
	cmp 		eax, 1
	je 			.even_negative

.odd_negative:
	mov 		esi, 1				; move sign to edx if odd number

.even_negative:
	neg 		ebx					; modulus of number

.positive:
	mov 		ecx, ebx			; factorial of modulus of first integer (ebx)
	mov 		eax, 1				; 1 * 2 * 3 * ... * n
	
.loop:
	mul 		ecx
	loop 		.loop
	cmp 		esi, 0				; check if result should be positive 
	je	 		.done	
	neg 		eax					; negate result if odd negative

.done:
	pop 		esi					; restore registers
	pop 		edx
	pop 		ecx
	pop 		ebx
	ret
;-------------------------------------------------------------------------------

%endif
