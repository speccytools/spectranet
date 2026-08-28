.include	"errno.inc"
.include	"spectranet.inc"

.text
.globl F_esxdos_f_read
F_esxdos_f_read:
	call F_esxdos_restore_regs
	push ix
	pop de
	call READ
	jr c, .error
	; eSXDOS returns the count in both BC and DE, with HL immediately after
	; the bytes read. VFS READ already returns BC.
	push bc
	push ix
	pop hl
	pop de
	add hl, de
	or a
	ret
.error:
	cp EOF
	jp nz, F_esxdos_error
	ld bc, 0
	or a
	ret
