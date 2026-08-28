.include	"errno.inc"
.include	"spectranet.inc"

ESXDOS_FD_FIRST:	equ 0x9B
ESXDOS_DIR_FIRST:	equ 0xA4
ESXDOS_DIR_LAST:		equ 0xAC

.text
.globl F_esxdos_f_close
F_esxdos_f_close:
	call F_esxdos_restore_regs
	cp ESXDOS_DIR_FIRST
	jr c, .file
	cp ESXDOS_DIR_LAST + 1
	jr c, .dir
.file:
	call VCLOSE
	jp c, F_esxdos_error
	ret
.dir:
	call CLOSEDIR
	jp c, F_esxdos_error
	ret
