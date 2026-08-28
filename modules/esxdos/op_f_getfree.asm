.include	"errno.inc"

.text
.globl F_esxdos_f_getfree
F_esxdos_f_getfree:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error
	ld a, ENOSYS
.error:
	call F_esxdos_restore_curmount
	jp F_esxdos_error
