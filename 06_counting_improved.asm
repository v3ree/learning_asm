; Compile with: nasm -f elf -F dwarf -g <filename>.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 <filename>.o -o <filename>

%include            "str_lib0.asm"

SECTION .data
    str0    db      "Give me a number: ", 0x00
    str1    db      "Counting to ", 0x00
    str2    db      ": ", 0x00
    err_int db      " is invalid input - please use non-negative integer!"
    space   db      " ", 0x00

SECTION .bss
    number  resb    255

SECTION .text
    global  _start

;-------------------------------------------------------------------------------

_start:
    mov     eax, str0
    call    print_str

    mov     eax, number             ; read input
    call    read_input
    call    valid_int_string
    cmp     eax, 1
    je      .valid
.invalid:
    jmp     .usage

.valid:
    mov     eax, str1               ; "Counting to..."
    call    print_str
    mov     eax, number             ; print #
    call    print_str
    mov     eax, str2               ; ':' char
    call    print_str
    call    print_newline_char

    mov     eax, number             ; change string to uint
    call    str_to_int
    mov     edx, eax                ; save integer for later use
    call    check_neg_bit
    cmp     eax, 1                  ; if negative integer print error
    je      .usage

    mov     eax, edx;               ; recover number
    call    count_to_number
    call    exit

.usage:
    mov     eax, number             ; have to not print line ending here
    call    print_str
    mov     eax, err_int
    call    print_str
    call    print_newline_char
    jmp     _start
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
count_to_number:                    ; counts to number in eax
    push    ebx
    push    ecx
    push    edx
    mov     edx, eax                ; edx holds max number
    xor     ecx, ecx
    xor     eax, eax

.loop:
    cmp     ecx, edx
    jg      .done

    mov     eax, ecx
    call    print_int

    mov     eax, space
    call    print_str

    inc     ecx
    jmp     .loop

.done:
    call    print_newline_char
    pop     edx
    pop     ecx
    pop     ebx
    ret
