.include	"errno.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"

.text
.globl F_esxdos_f_seek
F_esxdos_f_seek:
	call F_esxdos_restore_regs
	push af
	ld a, ixl
	push bc
	push de
	pop hl
	pop de
	cp 0
	jr z, .set
	cp 1
	jr z, .cur
	cp 2
	jr z, .back
	pop af
	jp F_esxdos_einval
.set:
	ld c, SEEK_SET
	jr .callseek
.cur:
	ld c, SEEK_CUR
	jr .callseek
.back:
	call .neg_dehl
	ld c, SEEK_CUR
.callseek:
	pop af
	call LSEEK
	jp c, F_esxdos_error
	ret

.neg_dehl:
	ld a, l
	cpl
	ld l, a
	ld a, h
	cpl
	ld h, a
	ld a, e
	cpl
	ld e, a
	ld a, d
	cpl
	ld d, a
	inc hl
	ld a, h
	or l
	ret nz
	inc de
	ret
