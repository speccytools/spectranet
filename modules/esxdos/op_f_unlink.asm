.include	"errno.inc"
.include	"spectranet.inc"

.text
.globl F_esxdos_f_unlink
F_esxdos_f_unlink:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error
	push ix
	pop hl
	call UNLINK
	call F_esxdos_restore_curmount
	jp c, F_esxdos_error
	ret
.error:
	call F_esxdos_restore_curmount
	jp F_esxdos_error
