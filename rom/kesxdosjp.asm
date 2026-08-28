; Page-B half of the dot-command esxDOS bridge. This image is installed in
; the final 256 bytes of ROM page 30: the module bridge is at $2F00 and the
; direct Spectrum character printer is at $2F80.

.include "sysvars.inc"
.include "sysdefs.inc"
.include "spectranet.inc"
.include "stdmodules.inc"
.include "kesxdos.inc"
.include "zxrom.inc"

.section modcall
.globl F_spectranet_module_bridge
F_spectranet_module_bridge:
	; Spectranet's module dispatcher needs its permanent sysvars in section 3.
	xor a
	ld bc, PAGE0REG
	out (c), a
	ld a, 0xC0
	ld bc, PAGE3REG
	out (c), a

	; Recreate the register-save convention used by the normal RST $08 path.
	ld a, (DOT_ESX_A)
	ld (v_asave), a
	ld hl, (DOT_ESX_HL)
	ld (v_hl2save), hl
	ld de, (DOT_ESX_DE)
	ld (v_de2save), de
	ld bc, (DOT_ESX_BC)
	ld ix, (DOT_ESX_CALL_IX)

	; The dispatcher must restore this bridge page on return, not the dot page.
	ld a, 0x1E
	ld (v_pgb), a
	ld h, ESXDOS_ROM_ID
	ld a, (DOT_ESX_OP)
	ld l, a
	rst MODULECALL_NOPAGE

	; Preserve the complete esxDOS result before returning to the section-0
	; kernel, which will remap the dot command and copy any staged output.
	ld (DOT_ESX_RETBC), bc
	ld (DOT_ESX_RETDE), de
	ld (DOT_ESX_RETHL), hl
	push af
	pop hl
	ld (DOT_ESX_RETAF), hl

	ld a, 0x1E
	ld bc, PAGE0REG
	out (c), a
	ret

; Direct character-output bridge. Unlike F_spectranet_module_bridge this
; does not invoke esxdos.module: it just restores the normal ROM/RAM view
; required by CALLBAS, prints A, then reinstates the dot kernel page.
.section chara
.globl F_spectranet_chara_bridge
F_spectranet_chara_bridge:
	push af
	xor a
	ld bc, PAGE0REG
	out (c), a
	ld a, 0xC0
	ld bc, PAGE3REG
	out (c), a
	pop af

	rst CALLBAS
	defw ZX_PRINT_A_1

	ld a, 0x1E
	ld bc, PAGE0REG
	out (c), a
	ret
