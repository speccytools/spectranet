.include	"errno.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"
.include	"sysvars.inc"

ESXDOS_OPEN_PATH_TMP: equ fs_scratchpad+96

.text
.globl F_esxdos_f_open
F_esxdos_f_open:
	call F_esxdos_restore_regs
	call F_esxdos_save_curmount
	call F_esxdos_select_drive
	jr c, .error
	ld a, b
	and 0x40
	jr nz, .einval

	ld a, b
	and 0x03
	cp 0x01
	jr z, .read
	cp 0x02
	jr z, .write
	cp 0x03
	jr z, .rdwr
	jr .einval
.read:
	ld de, O_RDONLY
	jr .createmode
.write:
	ld de, O_WRONLY
	jr .createmode
.rdwr:
	ld de, O_RDWR
.createmode:
	ld a, b
	and 0x0c
	push af
	ld bc, 0x0000
	pop af
	jr z, .callopen
	cp 0x08
	jr z, .opencreat
	cp 0x04
	jr z, .creatnoexist
	cp 0x0c
	jr z, .creattrunc
	jr .einval
.opencreat:
	ld a, d
	or 0x01
	ld d, a
	ld bc, 0x01A4
	jr .callopen
.creatnoexist:
	ld a, d
	or 0x05
	ld d, a
	ld bc, 0x01A4
	jr .callopen
.creattrunc:
	ld a, d
	or 0x03
	ld d, a
	ld bc, 0x01A4
.callopen:
	push de
	push bc
	push ix
	pop hl
	call F_esxdos_open_normalize_83
	pop bc
	pop de
	call OPEN
	call F_esxdos_restore_curmount
	jp c, F_esxdos_error
	ret
.einval:
	ld a, EINVAL
.error:
	call F_esxdos_restore_curmount
	jp F_esxdos_error

F_esxdos_open_normalize_83:
	push hl
	ld de, 8
	add hl, de
	ld a, (hl)
	cp '.'
	jr nz, .original_pop
	inc hl
	ld b, 3
.check_ext:
	ld a, (hl)
	or a
	jr z, .original_pop
	cp ' '
	jr z, .original_pop
	inc hl
	djnz .check_ext
	ld a, (hl)
	or a
	jr nz, .original_pop
	pop hl
	push hl
	ld de, ESXDOS_OPEN_PATH_TMP
	ld b, 8
.copy_base:
	ld a, (hl)
	cp ' '
	jr z, .base_done
	or a
	jr z, .original_copy_pop
	ld (de), a
	inc de
	inc hl
	djnz .copy_base
.base_done:
	ld a, '.'
	ld (de), a
	inc de
	pop hl
	ld bc, 9
	add hl, bc
	ld b, 3
.copy_ext:
	ld a, (hl)
	cp ' '
	jr z, .ext_done
	or a
	jr z, .ext_done
	ld (de), a
	inc de
	inc hl
	djnz .copy_ext
.ext_done:
	xor a
	ld (de), a
	ld hl, ESXDOS_OPEN_PATH_TMP
	ret
.original_pop:
	pop hl
.original:
	ret
.original_copy_pop:
	pop hl
	ret
