.include "errno.inc"
.include "spectranet.inc"
.include "sysvars.inc"

.text
.globl F_esxdos_f_telldir
F_esxdos_f_telldir:
	call F_esxdos_restore_regs
	ld c, a
	ld a, (v_esxdos_dir_handle)
	cp c
	jr nz, .badfd
	ld a, c
	ld de, 0			; READDIR control form: tell current position
	ld hl, v_esxdos_dir_position
	ld c, 0
	call READDIR
	jr c, .error
	ld de, (v_esxdos_dir_position)
	ld bc, (v_esxdos_dir_position+2)
	or a
	ret
.badfd:
	ld a, EBADF
.error:
	jp F_esxdos_error
