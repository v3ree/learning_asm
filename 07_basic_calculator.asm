; nasm -f elf -F dwarf -g 07_basic_calculator.asm && ld -m elf_i386 07_basic_calculator.o -o 07_basic_calculator && ./07_basic_calculator 2 pow 32

%include        "str_lib0.asm"
%include        "math_lib0.asm"

SECTION .data
    usage_msg   db      "Usage (as program argument): (-)<integer> <operation (+ - x / pow sqrt fact)> (-)<integer>", 0x00
    error_op    db      "Error - invalid operation!", 0x00
    error_int   db      "Error - invalid integer!", 0x00
    error_div   db      "Error - cannot divide by 0!", 0x00
    error_pow   db      "Error - cannot raise to negative power!", 0x00
    error_sqrt  db      "Error - cannot take square root of negative integer!", 0x00
    remainder   db      " R ", 0x00

SECTION .bss
    number      resb    255

SECTION .text
    global      _start

;-------------------------------------------------------------------------------
_start:
    pop         esi                 ; number of arguments in esi
    cmp         esi, 4
    jg          usage
    cmp         esi, 3
    jl          usage

    pop         ebx                 ; program name (discarded)

    pop         eax                 ; the first integer
    call        validate_int
    mov         ebx, eax            ; save value for calculation

    pop         eax                 ; the operation
    call        validate_op         ; checks if [eax] is one of + - x / pow sqrt
    mov         ecx, eax
    cmp         BYTE [eax], 115     ; if op = sqrt skip second int (if any)
    je          .skip_second_int
    cmp         BYTE [eax], 102     ; if op = factorial skip second int (if any)
    je          .skip_second_int

    pop         eax                 ; the second integer
    call        validate_int
    mov         edx, eax            ; save value for calculation

.skip_second_int:
    call        calculate           ; int <ebx> op <ecx> int <edx>
    jmp         exit
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
calculate:
    cmp BYTE    [ecx], 43           ; check if +
    je          .add
    cmp BYTE    [ecx], 45           ; check if -
    je          .sub
    cmp BYTE    [ecx], 120          ; check if x
    je          .mul
    cmp BYTE    [ecx], 47           ; check if / 
    je          .div
    cmp BYTE    [ecx], 112          ; check if p (pow operation already validated)
    je          .pow
    cmp BYTE    [ecx], 115          ; check if s (sqrt operation already validated)
    je          .sqrt
    cmp BYTE    [ecx], 102          ; check if f (factorial operation already validated)
    je          .fact

.add:
    mov         eax, ebx
    add         eax, edx
    jmp         .done

.sub:
    mov         eax, ebx
    sub         eax, edx
    jmp         .done

.mul:
    mov         eax, ebx
    mul         edx
    jmp         .done

.div:
    cmp         edx, 0
    jz          .invalid_div
    push        edx
    mov         eax, ebx
    xor         edx, edx
    pop         ebx
    cdq                             ; extends the sign bit of eax into edx 
    idiv        ebx                 ; edx:eax / ebx -> Q(eax) R(edx)
    call        print_sig_int       ; print quotient
    mov         eax, remainder
    call        print_str           ; print 'R'
    mov         eax, edx            ; print remainder
    jmp         .done

.pow:
    mov         eax, ebx            ; prepare to call power function
    mov         ecx, edx
    call        raise_to_power
    cmp         ecx, -1             ; check for error
    je          .invalid_pow
    jmp         .done               ; no error, result in eax

.sqrt:                              ; square root of first integer (ebx)
    mov         eax, ebx
    call        square_root
    cmp         eax, -1             ; check if negative integer was used
    je          .invalid_sqrt
    jmp         .done

.fact:
    mov         eax, ebx
    call        factorial
    jmp         .done

.done:
    call        print_sig_int
    call        print_newline_char
    ret

.invalid_div:
    mov         eax, error_div
    call        print_str
    call        print_newline_char
    jmp         usage
    
.invalid_sqrt:
    mov         eax, error_sqrt
    call        print_str
    call        print_newline_char
    jmp         usage

.invalid_pow:
    mov         eax, error_pow
    call        print_str
    call        print_newline_char
    jmp         usage
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
usage:                              ; print the usage string and exit
    mov         eax, usage_msg
    call        print_str
    call        print_newline_char
    call        exit
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
validate_int:
    push        ebx
    call        check_minus         ; ebx is 1 if [eax] is negative int

.start:
    push        eax
    call        valid_int_string
    cmp         eax, 0              ; if string is invalid
    jz          .invalid
    pop         eax

    call        str_to_int
    cmp         ebx, 1              ; if ebx = 1 int is negative
    jne         .done
    neg         eax
.done:
    pop         ebx
    ret

.invalid:
    mov         eax, error_int
    call        print_str
    call        print_newline_char
    jmp         usage

check_minus:
    cmp         BYTE [eax], 45
    jne         .done
    mov         ebx, 1              ; number is negative
    inc         eax                 ; remove '-' character
    ret
.done:
    mov         ebx, 0              ; number is positive
    ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
validate_op:
    push        eax

    push        eax                 ; check if operation is more than 4 chars
    call        get_str_len
    cmp         eax, 4
    jg          .invalid
    pop         eax

    cmp BYTE    [eax], 43           ; check if +
    je          .valid
    cmp BYTE    [eax], 45           ; check if -
    je          .valid
    cmp BYTE    [eax], 120          ; check if x
    je          .valid
    cmp BYTE    [eax], 47           ; check if / 
    je          .valid
    cmp BYTE    [eax], 112          ; check if p(ow)
    je          .pow
    cmp BYTE    [eax], 115          ; check if s(qrt)
    je          .sqrt
    cmp BYTE    [eax], 102          ; check if f(act)
    je          .fact

.pow:
    cmp BYTE    [eax+1], 111        ; check if o
    jne         .invalid
    cmp BYTE    [eax+2], 119        ; check if w
    jne         .invalid
    jmp         .valid
    
.sqrt:
    cmp BYTE    [eax+1], 113        ; check if q
    jne         .invalid
    cmp BYTE    [eax+2], 114        ; check if r
    jne         .invalid
    cmp BYTE    [eax+3], 116        ; check if t
    jne         .invalid
    jmp         .valid

.fact:
    cmp BYTE    [eax+1], 97         ; check if a
    jne         .invalid
    cmp BYTE    [eax+2], 99         ; check if c
    jne         .invalid
    cmp BYTE    [eax+3], 116        ; check if t
    jne         .invalid
    jmp         .valid


.valid:
    pop         eax
    ret

.invalid:
    mov         eax, error_op
    call        print_str
    call        print_newline_char
    jmp         usage
