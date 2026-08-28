.include	"errno.inc"
.include	"spectranet.inc"

; esxDOS F_CHMOD ($AF):
;   A  = drive
;   IX = pathname
;   B  = attributes to set
;   C  = attribute mask
;
; SpectraNext's local XFS overlay uses CHMOD mode $8000 to commit a RAM
; override into flash. This is deliberately an esxDOS shim convention.
;
; The stock CHMOD dot command encodes +a as bit 5 in both B (set) and C
; (mask).  That is the one attribute with a useful local equivalent.
ESXDOS_ATTR_ARCHIVE:	equ 0x20
XFS_CHMOD_COMMIT_FLASH:	equ 0x8000
ESXDOS_ENOSYS:	equ 20

.text
.globl F_esxdos_f_chmod
F_esxdos_f_chmod:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error

	; Only +a is meaningful here.  In particular, -a must not accidentally
	; commit a file, and unrelated FAT attribute changes are unsupported.
	ld a, c
	and ESXDOS_ATTR_ARCHIVE
	jr z, .unsupported
	ld a, b
	and ESXDOS_ATTR_ARCHIVE
	jr z, .unsupported

	ld de, XFS_CHMOD_COMMIT_FLASH
	push ix
	pop hl
	call CHMOD
	jr c, .error
.success:
	call F_esxdos_restore_curmount
	or a
	ret
.unsupported:
	ld a, ESXDOS_ENOSYS
.error:
	ld b, a
	call F_esxdos_restore_curmount
	ld a, b
	jp F_esxdos_error
