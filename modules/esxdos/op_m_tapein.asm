; esxDOS M_TAPEIN ($8B): Spectrum tape-input redirection.
;
; Spectranet already owns the implementation behind %tapein: a TAP file is
; opened and the ROM LOAD entry is redirected through the existing NMI trap.
; Expose that implementation through the standard esxDOS API so ordinary DOT
; commands can use it as well.

.include "errno.inc"
.include "spectranet.inc"
.include "stdmodules.inc"

.text
.globl F_esxdos_m_tapein
F_esxdos_m_tapein:
	call F_esxdos_restore_regs
	ld a, b
	or a
	jr z, .open
	dec a
	jr z, .close
	ld a, ENOSYS
	scf
	ret

.open:
	; M_TAPEIN receives its filename in IX. Keep %tapein unchanged: its
	; F_settrap_path contract is the basext interpreter workspace at $3003.
	; Copy the string there, then expose it as IX at the basext boundary.
	push ix
	pop hl
	ld de, 0x3003		; INTERPWKSPC (basext-private workspace)
.copy_path:
	ld a, (hl)
	ld (de), a
	inc hl
	inc de
	or a
	jr nz, .copy_path
	ld ix, 0x3003
	ld hl, 0xFD01
	rst MODULECALL_NOPAGE
	ret nc
	jp F_esxdos_error

.close:
	ld hl, 0xFD02
	rst MODULECALL_NOPAGE
	ret nc
	jp F_esxdos_error
