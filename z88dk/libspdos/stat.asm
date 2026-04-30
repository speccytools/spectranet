; process
; int stat(const char* path, struct stat* buf);
PUBLIC stat
	include "spectranet.asm"
.stat
	; sccz80 RTL: push buf, push path → stack under ret is path then buf.
	pop	bc
	pop	hl	; path
	pop	de	; buf
	push	de
	push	hl
	push	bc

	push	ix
	; ROM STAT: HL=path, DE=stat buffer
	IXCALL STAT

	pop	ix
	jr	c, stat_error
	jr	z, stat_error
	ld	hl, 0
	ret

stat_error:
	ld	hl, -1
	ret
