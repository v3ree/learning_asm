
%ifndef STR_LIB
    %define STR_LIB

%include        "math_lib0.asm"

;-------------------------------------------------------------------------------

SECTION .bss
    lib_buffer  resb    255

SECTION .text

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; PRINT STRING

print_str:                      ; prints the string with address in eax
    push    edx                 ; saves the registers
    push    ecx
    push    ebx
    push    eax                 ; saves the string address

    call    get_str_len         ; puts str length in edx
    mov     edx, eax            ; number of bytes of string for sys_write call
    pop     eax                 ; gets the string address

    mov     ecx, eax            ; the address of the string
    mov     ebx, 1              ; the STDOUT file descriptor
    mov     eax, 4              ; the sys_write syscall
    int     80h

    pop     ebx
    pop     ecx
    pop     edx
    ret
;--------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; PRINT UNSIGNED INTEGER

print_int:                      ; prints the integer from eax
    push    eax
    push    ebx

    mov     ebx, lib_buffer
    call    int_to_str          ; puts str length in edx

    mov     eax, lib_buffer
    call    print_str

    pop     ebx
    pop     eax
    ret
;--------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; PRINT SIGNED INTEGER

print_sig_int:                  ; prints the integer from eax
    push    eax
    push    eax
    call    check_neg_bit
    cmp     eax, 1
    jne     .print_uint

.print_sint:
    call    print_neg_char
    pop     eax
    neg     eax
    jmp     .done

.print_uint:
    pop     eax

.done:
    call    print_int
    pop     eax
    ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; READ INPUT

read_input:                     ; reads input in variable from eax
    push    edx                 ; saves the registers
    push    ecx
    push    ebx
    push    eax

    mov     edx, 255            ; number of bytes of string for sys_read call
    mov     ecx, eax            ; the address of the variable for input
    mov     ebx, 0              ; the STDIN file descriptor
    mov     eax, 3              ; the sys_read syscall
    int     80h

    mov     eax, ecx
    call    remove_nl_char

    pop     eax
    pop     ebx
    pop     ecx
    pop     edx
    ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; PRINT NEWLINE CHARACTER

print_newline_char:
    push    eax
    push    0x000A
    mov     eax, esp
    call    print_str
    pop     eax                  ; remove newline char from stack
    pop     eax
    ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; PRINT NEGATIVE CHARACTER '-'

print_neg_char:
    push    eax
    push    45
    mov     eax, esp
    call    print_str
    pop     eax                  ; remove '-' char from stack
    pop     eax
    ret
;--------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; STRING TO INTEGER

str_to_int:                      ; convert string (eax addr) to integer (in eax)
    push    ebx
    push    ecx
    xor     ecx, ecx             ; ecx used to store result

.process_char:
    cmp     byte [eax], 0        ; check for null string termination
    jz      .done

    xor     ebx, ebx
    mov     bl, byte [eax]       ; convert char to digit
    sub     ebx, 48              ; sub 0 to get digit
    cmp     ebx, 0               ; if result < 0 invalid digit do not add
    jl      .repeat
    cmp     ebx, 10
    jge     .repeat              ; if result > 10 invalid digit do not add
    imul    ecx, 10              ; go to next digit
    add     ecx, ebx             ; add to result

.repeat:
    inc     eax
    jmp     .process_char

.done:
    mov     eax, ecx
    pop     ecx
    pop     ebx
    ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; INTEGER TO STRING

int_to_str:                     ; convert int (eax) to str (ebx holds buf addr)
    push    ecx
    push    edx
    push    esi
    push    ebx
    mov     dword [ebx], 0
    xor     edx, edx
    cmp     eax, 0
    jz      .zero

.append_digit:
    cmp     eax, 0
    jz      .done
    mov     esi, 10
    xor     edx, edx
    idiv    esi                 ; divide eax by esi (get remainder digit in edx)

.zero:
    add     edx, 48
    mov     byte [ebx], dl      ; copy char to buffer by adding value to 0
    inc     ebx                 ; go to next char space in buffer
    jmp     .append_digit

.done:
    pop     ebx
    mov     eax, ebx
    call    reverse_string
    pop     esi
    pop     edx
    pop     ecx
    ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; REVERSE STRING

reverse_string:                 ; takes string in eax
    push    ecx
    push    ebx
    mov     ebx, eax            ; ebx saves address of string
    xor     eax, eax
    push    eax                 ; push a zero char to the stack
    mov     eax, ebx 

.loop:
    xor     ecx, ecx
    mov     cl, byte [eax]

    cmp     ecx, 0
    jz      .pop_chars
    push    ecx                 ; push characters to stack
    inc     eax
    jmp     .loop

.pop_chars:
    pop     eax                 ; pop chars in reverse order
    mov     byte [ebx], al
    cmp     eax, 0
    jz      .done
    inc     ebx
    jmp     .pop_chars

.done:
    pop     ebx
    pop     ecx
    ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; GET STRING LENGTH

get_str_len:                    ; string address is in eax, returns lenth in eax
    push    ecx                 ; save ecx for return
    mov     ecx, eax            ; save address for pointer arithmetics

.count_chars:
    cmp     byte [eax], 0       ; check for null string termination
    jz      .done
    inc     eax
    jmp     .count_chars

.done:                          ; calculate the string length
    sub     eax, ecx
    pop     ecx
    ret
;-------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; REMOVE NEWLINE CHARACTER FROM END OF STRING

remove_nl_char:                 ; removes new line char from end of string in eax
    cmp     byte [eax], 0
    jz      .done

    cmp     byte [eax], 10
    jnz     .skip_remove

    mov     byte [eax], 0       ; removes new line char if found

.skip_remove:
    inc     eax
    jmp     remove_nl_char

.done:
    ret
    
;--------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; RETURN BOOLEAN IF STRING HAS CORRECT INTEGER FORMAT

valid_int_string:                   ; check if string [eax] is a valid int format
    push        ebx                 ; returns in eax 1 if valid, 0 if invalid
    push        ecx
    push        eax
    xor         ecx, ecx            ; ecx used to store result
    call        get_str_len         ; check if string at [eax] is empty
    cmp         eax, 0
    jz          .error
    pop         eax                 ; restore address of string

.process_char:
    cmp         byte [eax], 0       ; check for null string termination
    jz          .valid

    xor         ebx, ebx
    mov         bl, byte [eax]      ; convert char to digit
    sub         ebx, 48             ; sub 0 to get digit
    cmp         ebx, 0              ; if result < 0 invalid digit do not add
    jl          .error
    cmp         ebx, 10
    jge         .error              ; if result > 10 invalid digit do not add
    inc         eax
    jmp         .process_char

.valid:
    mov         eax, 1
    jmp         .end
.error:
    mov         eax, 0
.end:
    pop         ecx
    pop         ebx
    ret
;-------------------------------------------------------------------------------

;--------------------------------------------------------------------------------
; EXIT PROGRAM

exit:
    mov         ebx, 0              ; 0 STATUS (NO ERRORS) for sys_exit
    mov         eax, 1              ; sys_exit syscall
    int         80h
    ret
;-------------------------------------------------------------------------------

%endif
