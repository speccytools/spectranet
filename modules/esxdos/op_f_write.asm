.include	"errno.inc"
.include	"spectranet.inc"

.text
.globl F_esxdos_f_write
F_esxdos_f_write:
	call F_esxdos_restore_regs
	push ix
	; eSXDOS supplies the source address in IX; the Spectranet VFS WRITE
	; contract takes that source address in HL (unlike READ, which uses DE).
	pop hl
	call WRITE
	jp c, F_esxdos_error
	ret
