PUBLIC  spectranext_fputc_cons
PUBLIC  _spectranext_fputc_cons

spectranext_fputc_cons:
_spectranext_fputc_cons:
    ld      hl, 2
    add     hl, sp
    ld      a, (hl)        

    ld      bc, $073B
    out     (c), a

    ret
