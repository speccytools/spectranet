; int __FASTCALL__ spectranext_detect(void);
; int __FASTCALL__ spectranet_detect(void);
;
; spectranext_detect: returns HL=1 if Spectranext (CTRLREG bit 7 readback inverted on write).
; Otherwise restores CTRLREG and falls through to spectranet_detect (returns 0 if Spectranet present, -1 if not).

PUBLIC spectranext_detect
PUBLIC spectranet_detect
EXTERN libspectranet

	include "spectranet.asm"

spectranext_detect:
	push bc
	ld bc, CTRLREG
	in a, (c)
	ld d, a			; original CTRLREG

	; Clear bit 7, write, read back — on Spectranext, written 0 appears as 1 when read
	and 0x7F
	out (c), a
	in a, (c)
	bit 7, a
	jr z, spectranext_detect_fail

	; Set bit 7 (other bits from original), write, read back — written 1 appears as 0
	ld a, d
	and 0x7F
	or 0x80
	out (c), a
	in a, (c)
	bit 7, a
	jr nz, spectranext_detect_fail

	; Restore original register before reporting success
	ld a, d
	out (c), a

	ld hl, 1
	pop bc
	ret

spectranext_detect_fail:
	ld a, d
	out (c), a
	pop bc
	; fall through to spectranet_detect

spectranet_detect:
	push bc
	ld bc,CTRLREG
	ld a,5	;cyan
	ei
	halt
	out (0xFE),a
	in a,(c)
	and 0x07	;mask off bits
	pop bc
	and a
	ld hl, 0
	cp 5
	ret z
	ld hl, -1
	ret
