#include <fcntl.h>

int readbyte(int fd) __naked
{
#asm
    include "spectranet.asm"
    
    pop     bc      ; return address
    pop     hl      ; fd
    push    hl
    push    bc
    
    push    ix
    ld      a,l     ; fd in A
    push    hl      ; Reserve space on stack for byte (fd value, will be overwritten)
    ld      hl,0
    add     hl,sp   ; HL points to buffer on stack
    ex      de,hl   ; DE = buffer
    ld      bc,1    ; Read 1 byte
    call    READ
    pop     hl      ; Get byte from stack (byte is in L)
    pop     ix
    
    jr      c,error
    ; BC contains bytes read (should be 1)
    ; Byte value is in L register (from pop hl)
    ld      h,0
    ret
    
error:
    ld      hl,-1
    ret
#endasm
}

