.include	"errno.inc"
.include	"spectranet.inc"
.include	"sysvars.inc"

.text
.globl F_esxdos_f_opendir
F_esxdos_f_opendir:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error
	; OPENDIR backends may alter the global current-mount variable.  The
	; directory handle must retain the mount selected by its eSXDOS drive
	; argument, for subsequent READDIR metadata STATs and SEEKDIR replays.
	push af
	ld a, (v_vfs_curmount)
	ld (v_esxdos_dir_mount), a
	pop af
	ld a, b
	and 0x40
	jr nz, .einval
	push ix
	pop hl
	; VFS/module calls do not promise to preserve IX. Keep the original
	; pathname pointer so the SEEKDIR replay cache is populated from the path,
	; rather than from whatever the backend last left in IX.
	push ix
	call OPENDIR
	pop ix
	jr c, .error
	ld (v_esxdos_dir_handle), a
	call F_esxdos_dir_remember_path
	call F_esxdos_restore_curmount
	ret
.einval:
	ld a, EINVAL
.error:
	call F_esxdos_restore_curmount
	jp F_esxdos_error

; Keep one directory path for READDIR metadata lookups. The eSXDOS record
; contains attributes, size and timestamp while plain VFS READDIR returns
; only a filename.
F_esxdos_dir_remember_path:
	push af
	push ix
	pop hl
	ld de, buf_moduleworkspace
	ld b, 0xFF
.copy:
	ld a, (hl)
	ld (de), a
	inc hl
	inc de
	or a
	jr z, .done
	djnz .copy
	xor a
	ld (de), a
.done:
	pop af
	ret
