.include	"errno.inc"

.text
.globl F_esxdos_m_getsetdrv
F_esxdos_m_getsetdrv:
	call F_esxdos_restore_regs
	cp 0
	jr z, .current
	cp '*'
	jr z, .current
	cp '$'
	jr z, .current
	call F_esxdos_set_current_drive
	jp c, F_esxdos_error
	inc a
	ret
.current:
	call F_esxdos_current_drive
	jp c, F_esxdos_error
	ret
