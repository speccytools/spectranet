.include	"errno.inc"
.include	"spectranet.inc"
.include	"stat.inc"
.include	"sysvars.inc"

ESXDOS_ATTR_DIRECTORY:	equ 0x10
ESXDOS_ATTR_ARCHIVE:	equ 0x20
ESXDOS_STAT_TMP:	equ fs_scratchpad

.text
.globl F_esxdos_f_stat
F_esxdos_f_stat:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	push af
	call F_esxdos_select_drive
	jr c, .select_error
	push de
	push ix
	pop hl
	ld de, ESXDOS_STAT_TMP
	call STAT
	jr c, .error
	call F_esxdos_restore_curmount
	pop de
	pop af
	ld (de), a
	inc de
	xor a
	ld (de), a
	inc de
	ld a, (ESXDOS_STAT_TMP+STAT_MODE+1)
	and 0x40
	jr z, .file
	ld a, ESXDOS_ATTR_DIRECTORY
	jr .attr
.file:
	ld a, ESXDOS_ATTR_ARCHIVE
.attr:
	ld (de), a
	inc de
	ld hl, ESXDOS_STAT_TMP+STAT_MTIME
	push de
	call F_esxdos_unix_to_dos
	pop de
	; The timestamp conversion writes four bytes at DE+0..3.
	inc de
	inc de
	inc de
	inc de
	ld a, (ESXDOS_STAT_TMP+STAT_SIZE)
	ld (de), a
	inc de
	ld a, (ESXDOS_STAT_TMP+STAT_SIZE+1)
	ld (de), a
	inc de
	ld a, (ESXDOS_STAT_TMP+STAT_SIZE+2)
	ld (de), a
	inc de
	ld a, (ESXDOS_STAT_TMP+STAT_SIZE+3)
	ld (de), a
	or a
	ret
.error:
	ld b, a
	call F_esxdos_restore_curmount
	pop de
	pop af
	ld a, b
	jp F_esxdos_error
.select_error:
	ld b, a
	call F_esxdos_restore_curmount
	pop af
	ld a, b
	jp F_esxdos_error
