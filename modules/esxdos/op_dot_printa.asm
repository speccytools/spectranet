; DOT-command RST $10 endpoint. The page-30 bridge has already restored the
; ordinary Spectranet ROM, so use the standard CALLBAS vector to invoke the
; Spectrum ROM's current-stream character printer.

.include "spectranet.inc"
.include "zxrom.inc"
.include "sysvars.inc"

.text
.globl F_esxdos_dot_setup_output
F_esxdos_dot_setup_output:
	call F_esxdos_restore_regs
	ld iy, (v_esxdos_basic_iy)
	ld a, 2
	rst CALLBAS
	defw ZX_CHAN_OPEN
	ret
