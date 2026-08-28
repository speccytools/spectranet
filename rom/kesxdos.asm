; Dot-command esxDOS kernel.
;
; This image is mapped into section 0 while a dot command is active.  It owns
; the restart vectors required by the dot-command ABI; the handlers below are
; placeholders until the dot bridge and ROM-transition code are implemented.

.include	"sysvars.inc"
.include	"sysdefs.inc"
.include	"stdmodules.inc"
.include	"kesxdos.inc"
.include	"zxsysvars.inc"

.section rst0
	jp F_dot_entry

.section rst8
	jp F_rst08_handler

.section rst10
	jp F_rst10_handler

.section rst18
	jp F_rst18_handler

.section rst20
	jp F_rst20_handler

; While page 30 owns section 0, a normal IM1 interrupt cannot run the
; Spectrum ROM handler. Acknowledge it locally, then restore IFF1. DOTs such
; as .paper use HALT for UI timing and keyboard debounce, so leaving IFF1
; cleared after the first interrupt would make their next HALT permanent.
.section isr
	ei
	reti

.text
; RST $00: enter a loaded dot command.  The caller is esxdos.module in
; page B; preserve that page on the Spectrum stack so a normal RET from the
; dot command returns to its loader.
F_dot_entry:
	ld a, (v_pgb)
	push af

	ld a, 0xD8
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a

	; Update v_pga before section 3 stops exposing Spectranet sysvars.
	ld a, 0xC0
	ld bc, PAGEA
	out (c), a
	ld (v_pga), a

	; A DOT is not required to preserve the alternate register bank. BASIC's
	; continuation does use HL', however, so retain its pre-DOT value. Page A
	; now exposes RAM page 0, where the kernel workspace is valid.
	call F_dot_save_alt_hl

	ld a, 0xD9
	ld bc, PAGE3REG
	out (c), a

	; A DOT writes through the Spectrum's normal RST $10 printer. Unlike the
	; built-in %cat command it has not passed through the extension's listing
	; setup, so initialise the ROM scroll budget explicitly. Otherwise a stale
	; zero/one value makes the first newline enter the "Scroll?" path.
	ld a, 22
	ld (ZX_SCR_CT), a

	; BC sees the complete line without its leading dot; HL points immediately
	; after the command name and spaces, or is zero for a command without args.
	call F_dot_command_line
	call 0x2000

	; Dot code may have changed page A/B or section 3. Restore the normal
	; Spectranet mapping before returning to the esxdos module.
	ld a, 0xC0
	ld bc, PAGE3REG
	out (c), a

	ld bc, PAGEA
	out (c), a
	ld (v_pga), a

	; The word on the stack is the page-B value saved on entry. Do not POP AF:
	; that would replace the DOT command's returned A/carry and make every
	; failed command appear successful to F_esxdos_dot. Keep the DOT result in
	; the alternate AF while obtaining the saved page, then restore both it and
	; the DOT's returned HL before returning.
	ex af, af'
	ex (sp), hl
	ld a, h
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a
	pop hl
	ex af, af'
	call F_dot_restore_alt_hl
	ei
	ret

; Page A is RAM page 0 while a DOT executes, so this workspace remains
; available without depending on the dot image mapped into section 3.
F_dot_save_alt_hl:
	exx
	ld (DOT_DOT_ALT_HL), hl
	exx
	ret

F_dot_restore_alt_hl:
	exx
	ld hl, (DOT_DOT_ALT_HL)
	exx
	ret

; Prepare the classic esxDOS DOT ABI command-line registers. The loader has
; placed the NUL-terminated line in the tail of the second DOT page.
F_dot_command_line:
	ld bc, DOT_COMMAND_LINE
	push bc
	pop hl
.name:
	ld a, (hl)
	or a
	jr z, .noargs
	cp ' '
	jr z, .args
	inc hl
	jr .name
.args:
	inc hl
.skipspaces:
	ld a, (hl)
	or a
	jr z, .noargs
	cp ' '
	ret nz
	inc hl
	jr .skipspaces
.noargs:
	ld hl, 0
	ret

; RST $08: esxDOS ABI adapter. The byte after RST is the esxDOS operation.
F_rst08_handler:
	; RST pushes the address of the function byte. Consume it so RET returns
	; directly after the byte, exactly as the native esxDOS ABI requires.
	call F_spectranet_save_regs

    ; advance past defb <opcode> and obtain it
	pop hl
	ld a, (hl)
	inc hl
	push hl

	ld (DOT_ESX_OP), a
	; convert arguments from esxdos
	call F_spectranet_stage

	; execute MODULECALL 0xF9<a>
	jp F_spectranet_invoke_module

F_spectranet_save_regs:
	ld (DOT_ESX_A), a
	ld (DOT_ESX_BC), bc
	ld (DOT_ESX_DE), de
	ld (DOT_ESX_HL), hl
	ld (DOT_ESX_IX), ix
	ret

; Invoke one Spectranet module call. The bridge returns to the kernel with
; section 3 on RAM page 0, allowing transfer calls to prepare another chunk.
F_spectranet_invoke_module:
	; The bridge is the last 256 bytes of this same ROM page, but seen through
	; page B at $2F00. Section 0 stays mapped to this kernel until the bridge
	; switches to the ordinary Spectranet section-0 page.
	ld a, 0x1E
	ld bc, PAGEB
	out (c), a
	ld hl, F_spectranet_return
	push hl
	jp 0x2F00

; The bridge returns with section 0 back on this ROM page, section 3 on
; Spectranet RAM page 0, and page B still holding its own ROM page.
F_spectranet_return:
	; Keep an esxDOS READ/WRITE in the protected page-A workspace until its
	; result has been handled. Those calls may be larger than the workspace and
	; are therefore completed by F_spectranet_transfer_return in several trips.
	ld hl, (DOT_ESX_RETAF)
	push hl
	pop af
	jr c, F_spectranet_restore_dot
	ld a, (DOT_ESX_OP)
	cp ESXDOS_F_READ
	jr z, F_spectranet_transfer_return
	cp ESXDOS_F_WRITE
	jr z, F_spectranet_transfer_return
F_spectranet_restore_dot:
	; Restore the dot mapping before touching a caller-owned output buffer.
	ld a, 0xC0
	ld bc, PAGEA
	out (c), a
	ld a, 0xD8
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a
	ld a, 0xD9
	ld bc, PAGE3REG
	out (c), a

	; Copy a staged result only when the module reported success.
	ld hl, (DOT_ESX_RETAF)
	push hl
	pop af
	jr c, .restore_result
	ld a, (DOT_ESX_OUTLEN)
	or a
	jr z, .restore_result
	ld c, a
	ld b, 0
	ld hl, DOT_ESX_WORKSPACE
	ld de, (DOT_ESX_OUTPTR)
	ldir
.restore_result:
	ld bc, (DOT_ESX_RETBC)
	ld de, (DOT_ESX_RETDE)
	ld hl, (DOT_ESX_RETHL)
	ld ix, (DOT_ESX_IX)
	ld hl, (DOT_ESX_RETAF)
	push hl
	pop af
	ret

; Complete one staged READ/WRITE chunk. For READ, copy VFS output from page A
; back into the DOT image. For WRITE, F_spectranet_stage_transfer already
; copied the input in the opposite direction. A short transfer terminates the
; esxDOS request; otherwise invoke the module again for the next chunk.
F_spectranet_transfer_return:
	ld a, (DOT_ESX_OP)
	cp ESXDOS_F_READ
	jr nz, .account

	; The bridge has section 3 on C0 and page A on C0. Map the DOT image only
	; while copying the completed bytes to its caller-supplied destination.
	ld a, 0xD8
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a
	ld a, 0xD9
	ld bc, PAGE3REG
	out (c), a
	ld hl, DOT_ESX_XFER_WORKSPACE
	ld de, (DOT_ESX_XFERPTR)
	ld bc, (DOT_ESX_RETBC)
	ld a, b
	or c
	jr z, .account
	ldir

.account:
	; Advance destination/source, outstanding count and total byte count by
	; the number the VFS actually transferred.
	ld de, (DOT_ESX_RETBC)
	ld hl, (DOT_ESX_XFERPTR)
	add hl, de
	ld (DOT_ESX_XFERPTR), hl
	ld hl, (DOT_ESX_XFERLEFT)
	or a
	sbc hl, de
	ld (DOT_ESX_XFERLEFT), hl
	ld hl, (DOT_ESX_XFERDONE)
	add hl, de
	ld (DOT_ESX_XFERDONE), hl

	; A zero or short completion is the normal end of a read (and avoids an
	; infinite loop for a short write). Return the accumulated count in BC.
	ld a, d
	or e
	jr z, .finish
	ld hl, (DOT_ESX_RETBC)
	ld de, (DOT_ESX_XFERCHUNK)
	or a
	sbc hl, de
	jr nz, .finish
	ld hl, (DOT_ESX_XFERLEFT)
	ld a, h
	or l
	jr z, .finish

	; A further chunk is needed. Section 3 must be permanent RAM for the
	; bridge, and WRITE must refill the staging buffer from the DOT image first.
	ld a, (DOT_ESX_OP)
	cp ESXDOS_F_WRITE
	jr nz, .map_spectranet
	ld a, 0xD8
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a
	ld a, 0xD9
	ld bc, PAGE3REG
	out (c), a
	call F_spectranet_stage_transfer_input
.map_spectranet:
	ld a, 0xC0
	ld bc, PAGE3REG
	out (c), a
	call F_spectranet_stage_transfer_chunk
	jp F_spectranet_invoke_module

.finish:
	ld hl, (DOT_ESX_XFERDONE)
	ld (DOT_ESX_RETBC), hl
	jp F_spectranet_restore_dot

; Stage pointer arguments for esxDOS calls. Other modules see their original
; registers and no staging by default.
F_spectranet_stage:
	ld hl, (DOT_ESX_IX)
	ld (DOT_ESX_CALL_IX), hl
	xor a
	ld (DOT_ESX_OUTLEN), a
	ld a, (DOT_ESX_OP)
	cp ESXDOS_M_TAPEIN
	jr z, .tapein
	cp ESXDOS_F_OPEN
	jr z, .path
	cp ESXDOS_F_OPENDIR
	jr z, .path
	cp ESXDOS_F_MKDIR
	jr z, .path
	cp ESXDOS_F_RMDIR
	jr z, .path
	cp ESXDOS_F_STAT
	jr z, .stat
	cp ESXDOS_F_FSTAT
	jr z, .fstat
	cp ESXDOS_F_UNLINK
	jr z, .path
	cp ESXDOS_F_CHMOD
	jr z, .path
	cp ESXDOS_F_RENAME
	jp z, .rename
	cp ESXDOS_F_GETCWD
	jr z, .getcwd
	cp ESXDOS_F_CHDIR
	jr z, .path
	cp ESXDOS_F_READDIR
	jp z, .readdir
	cp ESXDOS_F_READ
	jp z, .transfer
	cp ESXDOS_F_WRITE
	jp z, .transfer
	; TELLDIR/SEEKDIR carry only A and BCDE.  The generic register save and
	; bridge already preserve both, so they require no address staging.
	cp ESXDOS_F_TELLDIR
	jr z, .dirposition
	cp ESXDOS_F_SEEKDIR
	jr z, .dirposition
	ret
.tapein:
	; Native NextZXOS documents the in_open filename at IX. Stock esxDOS 0.8.6
	; TAPEIN instead leaves its parsed filename in HL when it calls its simple
	; RST $08 wrapper, exactly like its F_* wrappers. This kernel's job is to
	; adapt that legacy DOT convention to the module's IX ABI.
	ld hl, (DOT_ESX_BC)
	ld a, h
	or a
	ret nz			; in_close and later controls have no pathname.
	call F_spectranet_copy_path
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ret
.dirposition:
	ret
.transfer:
	jp F_spectranet_stage_transfer
.path:
	call F_spectranet_copy_path
	ret
.rename:
	; F_RENAME supplies the old pathname in HL and the new pathname in DE.
	; Both dot pointers disappear when the bridge restores section 3 to C0.
	ld hl, (DOT_ESX_HL)
	ld de, DOT_ESX_WORKSPACE
	ld b, DOT_ESX_RENAME_PATHSIZE
	call F_spectranet_copy_path_hl
	ld hl, (DOT_ESX_DE)
	ld de, DOT_ESX_RENAME_NEW
	ld b, DOT_ESX_RENAME_PATHSIZE
	call F_spectranet_copy_path_hl
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ld hl, DOT_ESX_RENAME_NEW_SECTION3
	ld (DOT_ESX_DE), hl
	ret
.stat:
	call F_spectranet_copy_path
	ld hl, (DOT_ESX_DE)
	ld (DOT_ESX_OUTPTR), hl
	; F_STAT uses IX for the pathname and DE for its 11-byte DOS stat result.
	; The copied pathname remains in CALL_IX; its original output pointer is
	; staged through DE and copied back after the module returns.
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_DE), hl
	ld a, 11
	ld (DOT_ESX_OUTLEN), a
	ret
.fstat:
	call F_spectranet_dot_ptr
	ld (DOT_ESX_OUTPTR), hl
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ld a, 11
	ld (DOT_ESX_OUTLEN), a
	ret
.getcwd:
	ld hl, (DOT_ESX_HL)
	ld (DOT_ESX_OUTPTR), hl
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ld a, 0x2A
	ld (DOT_ESX_OUTLEN), a
	ret
.readdir:
	; READDIR implementations can page their own private RAM into page A.
	; Hand the esxDOS module the section-3 alias of RAM page 0, which remains
	; visible throughout the VFS call. F_spectranet_return later reads the
	; same physical RAM through its page-A alias at DOT_ESX_WORKSPACE.
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	call F_spectranet_dot_ptr
	ld (DOT_ESX_OUTPTR), hl
	ld a, 0x20
	ld (DOT_ESX_OUTLEN), a
	ret

; Copy a NUL-terminated pathname to the protected workspace. The command
; ABI permits paths in either half of the dot image, both of which disappear
; while Spectranet page 0 is temporarily restored into section 3.
F_spectranet_copy_path:
	call F_spectranet_dot_ptr
	; Staging happens while section 3 is still the DOT's D9 page. Page A is
	; already permanent RAM page 0, so write through its $1C20 alias; once the
	; bridge maps section 3 to C0, the esxDOS module sees these same bytes at
	; $3C20.
	ld de, DOT_ESX_WORKSPACE
	ld b, DOT_ESX_WORKSIZE
	jp F_spectranet_copy_path_hl

; Copy the NUL-terminated path at HL to DE. The caller chooses the target
; half of the protected workspace; this is used by F_RENAME for two paths.
F_spectranet_copy_path_hl:
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
	ld hl, DOT_ESX_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ret

; The DOT-command esxDOS ABI deliberately substitutes HL for IX for pointer
; arguments. The normal (non-DOT) ABI uses IX, but every RST $08 call entering
; this kernel originates from a DOT and must therefore use its saved HL.
F_spectranet_dot_ptr:
	ld hl, (DOT_ESX_HL)
	ret

; Initialise a potentially large READ/WRITE transfer. esxDOS supplies the
; data pointer in HL for both operations; the module receives the section-3
; alias of the protected workspace. The original count is returned in
; aggregate.
F_spectranet_stage_transfer:
	ld hl, (DOT_ESX_HL)
	ld (DOT_ESX_XFERPTR), hl
	ld hl, (DOT_ESX_BC)
	ld (DOT_ESX_XFERLEFT), hl
	xor a
	ld h, a
	ld l, a
	ld (DOT_ESX_XFERDONE), hl
	ld a, (DOT_ESX_OP)
	cp ESXDOS_F_WRITE
	call z, F_spectranet_stage_transfer_input
	jp F_spectranet_stage_transfer_chunk

; Copy the next WRITE input chunk from the currently mapped DOT image into
; page A. READ does its inverse copy after the module call completes.
F_spectranet_stage_transfer_input:
	call F_spectranet_stage_transfer_size
	ld hl, (DOT_ESX_XFERPTR)
	ld de, DOT_ESX_XFER_WORKSPACE
	ld bc, (DOT_ESX_XFERCHUNK)
	ldir
	ret

; Select the next chunk and present the workspace to esxdos.module as IX.
F_spectranet_stage_transfer_chunk:
	call F_spectranet_stage_transfer_size
	ld hl, DOT_ESX_XFER_WORKSPACE_SECTION3
	ld (DOT_ESX_CALL_IX), hl
	ret

F_spectranet_stage_transfer_size:
	ld hl, (DOT_ESX_XFERLEFT)
	ld a, h
	cp DOT_ESX_XFER_WORKSIZE / 256
	jr c, .selected
	jr nz, .maximum
	ld a, l
	or a
	jr z, .selected
.maximum:
	ld hl, DOT_ESX_XFER_WORKSIZE
.selected:
	ld (DOT_ESX_XFERCHUNK), hl
	ld (DOT_ESX_BC), hl
	ret

; RST $10: call the standard 48K ROM character-output routine.
F_rst10_handler:
	; esxDOS DOTs commonly keep a string pointer in HL while issuing one RST
	; $10 per character. The Spectrum printer is allowed to clobber working
	; registers, but the esxDOS-facing restart must not leak that clobber back
	; into the DOT command.
	ex af, af'
	push af
	ex af, af'
	exx
	push bc
	push de
	push hl
	exx
	push af
	push bc
	push de
	push hl
	push ix

	push af
	; Page B exposes the character bridge at $2F80. CALL leaves the return
	; address directly on the Spectrum stack, so execution resumes below once
	; the bridge has reinstated this kernel in section 0.
	ld a, 0x1E
	ld bc, PAGEB
	out (c), a

	pop af

	call 0x2F80

	; Restore the DOT mapping before restoring the caller's registers.
	ld a, 0xC0
	ld bc, PAGEA
	out (c), a
	ld a, 0xD8
	ld bc, PAGEB
	out (c), a
	ld (v_pgb), a
	ld a, 0xD9
	ld bc, PAGE3REG
	out (c), a
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	exx
	pop hl
	pop de
	pop bc
	exx
	ex af, af'
	pop af
	ex af, af'
	ret

; RST $18: call the 48K ROM address supplied by the following DEFW.
F_rst18_handler:
	ret

; RST $20: leave dot mode and transfer to HL. This will be non-returning.
F_rst20_handler:
	ret
