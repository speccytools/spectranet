.include "errno.inc"
.include "spectranet.inc"
.include "sysvars.inc"

.text
.globl F_esxdos_f_seekdir
F_esxdos_f_seekdir:
	call F_esxdos_restore_regs
	push af
	ld (v_esxdos_dir_position), de
	ld (v_esxdos_dir_position+2), bc
	pop af
	ld d, a
	ld a, (v_esxdos_dir_handle)
	cp d
	jr nz, .badfd
	ld a, d
	ld de, 0			; READDIR control form: seek to HL
	ld hl, v_esxdos_dir_position
	ld c, 1
	call READDIR
	jr c, .error
	or a
	ret
.badfd:
	ld a, EBADF
	jr .error
.error:
	jp F_esxdos_error
