.include "errno.inc"
.include "spectranet.inc"

.text
.globl F_esxdos_f_getcwd
F_esxdos_f_getcwd:
	call F_esxdos_restore_regs
	; The API also accepts A=$ff plus DE=filespec, asking for the parent of
	; that arbitrary filespec.  VFS only exposes a mount working directory;
	; do not misinterpret $ff as a drive while that extension is unavailable.
	cp 0xff
	jp z, F_esxdos_enosys
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error
	push ix
	pop de
	call GETCWD
	push af
	call F_esxdos_restore_curmount
	pop af
	jp c, F_esxdos_error
	ret
.error:
	call F_esxdos_restore_curmount
	jp F_esxdos_error
