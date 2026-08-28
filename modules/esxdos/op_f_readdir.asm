.include	"errno.inc"
.include	"spectranet.inc"
.include	"stat.inc"
.include	"sysvars.inc"

ESXDOS_READDIR_DOS_TIME: equ fs_scratchpad+80
ESXDOS_READDIR_STAT: equ fs_scratchpad
ESXDOS_READDIR_STAT_PATH: equ fs_scratchpad+96

.text
.globl F_esxdos_f_readdir
F_esxdos_f_readdir:
	call F_esxdos_restore_regs
	push ix
	pop de
	push af
	xor a
	ld (de), a
	inc de
	ld (de), a
	pop af
	push de
	push ix
	call READDIR
	pop ix
	jr c, .error_pop
	pop hl
.find_nul:
	ld a, (hl)
	inc hl
	or a
	jr nz, .find_nul
	call F_esxdos_readdir_stat
	jr c, .no_metadata
	ld a, (ESXDOS_READDIR_STAT+STAT_MODE+1)
	and 0x40
	jr nz, .directory
	ld a, 0x20
	jr .attribute
.directory:
	ld a, 0x10
.attribute:
	ld (ix+0), a
	ld de, (ESXDOS_READDIR_STAT+STAT_SIZE)
	ld bc, (ESXDOS_READDIR_STAT+STAT_SIZE+2)
	push bc
	push de
	ld hl, ESXDOS_READDIR_STAT+STAT_MTIME
	ld de, ESXDOS_READDIR_DOS_TIME
	call F_esxdos_unix_to_dos
	jr .copy_name
.no_metadata:
	ld a, 0x20
	ld (ix+0), a
	ld hl, ESXDOS_READDIR_DOS_TIME
	xor a
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	ld bc, 0
	ld de, 0
	push bc
	push de
.copy_name:
	push ix
	pop hl
	inc hl
	ld b, 12
.cap_name:
	ld a, (hl)
	or a
	jr z, .name_done
	inc hl
	djnz .cap_name
	xor a
	ld (hl), a
.name_done:
	inc hl
	ex de, hl
	ld hl, ESXDOS_READDIR_DOS_TIME
	ld bc, 4
	ldir
	ex de, hl
	pop de
	pop bc
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl
	ld (hl), c
	inc hl
	ld (hl), b
	ld a, 1
	or a
	ret
.error:
	cp EOF
	jr z, .eod
	jp F_esxdos_error
.error_pop:
	pop hl
	jr .error
.eod:
	xor a
	ret

; Build the full pathname from the directory path cached by OPENDIR and the
; filename just returned at IX+1, then obtain the metadata required by the
; esxDOS READDIR record. Plain TNFS READDIR returns only a filename.
;
; The temporary pathname may share the TNFS receive area: the backend consumes
; it while constructing the request before receiving STAT into the same area.
; Carry is set when the joined path is too long or STAT fails.
F_esxdos_readdir_stat:
	ld hl, buf_moduleworkspace
	ld de, ESXDOS_READDIR_STAT_PATH
	ld c, 0xFF
	ld b, 0
.copy_directory:
	ld a, (hl)
	or a
	jr z, .directory_copied
	ld b, a
	ld (de), a
	inc hl
	inc de
	dec c
	jr z, .path_too_long
	jr .copy_directory
.directory_copied:
	ld a, b
	cp '/'
	jr z, .copy_filename
	ld a, '/'
	ld (de), a
	inc de
	dec c
	jr z, .path_too_long
.copy_filename:
	push ix
	pop hl
	inc hl
.copy_filename_byte:
	ld a, (hl)
	ld (de), a
	or a
	jr z, .stat
	inc hl
	inc de
	dec c
	jr nz, .copy_filename_byte
.path_too_long:
	scf
	ret
.stat:
	call F_esxdos_save_curmount
	ld a, (v_esxdos_dir_mount)
	ld (v_vfs_curmount), a
	push ix
	ld hl, ESXDOS_READDIR_STAT_PATH
	ld de, ESXDOS_READDIR_STAT
	call STAT
	pop ix
	call F_esxdos_restore_curmount
	ret
