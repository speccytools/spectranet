; esxDOS compatibility module

.include	"errno.inc"
.include	"fcntl.inc"
.include	"spectranet.inc"
.include	"stdmodules.inc"
.include	"sysvars.inc"
.include	"sysdefs.inc"
.include	"zxsysvars.inc"
.include	"zxrom.inc"

ESX_ENOSYS	equ 20

.section vectors
sig:	defb 0xAA		; This is a ROM module
romid:	defb ESXDOS_ROM_ID	; ID = 0xF9
reset:	defw 0xFFFF		; no reset handler
mount:	defw 0xFFFF		; not a filesystem
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
	defw 0xFFFF
idstr:	defw STR_ident

J_esxdos_modcall:
	ld a, l
	and a
	jp z, F_esxdos_dot
	cp ESXDOS_DOT_SETUP_OUTPUT
	jp z, F_esxdos_dot_setup_output
	cp ESXDOS_M_GETSETDRV
	jp z, F_esxdos_m_getsetdrv
	cp ESXDOS_M_TAPEIN
	jp z, F_esxdos_m_tapein
	cp ESXDOS_F_OPEN
	jp z, F_esxdos_f_open
	cp ESXDOS_F_CLOSE
	jp z, F_esxdos_f_close
	cp ESXDOS_F_READ
	jp z, F_esxdos_f_read
	cp ESXDOS_F_WRITE
	jp z, F_esxdos_f_write
	cp ESXDOS_F_SEEK
	jp z, F_esxdos_f_seek
	cp ESXDOS_F_FSTAT
	jp z, F_esxdos_f_fstat
	cp ESXDOS_F_OPENDIR
	jp z, F_esxdos_f_opendir
	cp ESXDOS_F_READDIR
	jp z, F_esxdos_f_readdir
	cp ESXDOS_F_TELLDIR
	jp z, F_esxdos_f_telldir
	cp ESXDOS_F_SEEKDIR
	jp z, F_esxdos_f_seekdir
	cp ESXDOS_F_GETCWD
	jp z, F_esxdos_f_getcwd
	cp ESXDOS_F_CHDIR
	jp z, F_esxdos_f_chdir
	cp ESXDOS_F_MKDIR
	jp z, F_esxdos_f_mkdir
	cp ESXDOS_F_RMDIR
	jp z, F_esxdos_f_rmdir
	cp ESXDOS_F_STAT
	jp z, F_esxdos_f_stat
	cp ESXDOS_F_UNLINK
	jp z, F_esxdos_f_unlink
	cp ESXDOS_F_CHMOD
	jp z, F_esxdos_f_chmod
	cp ESXDOS_F_RENAME
	jp z, F_esxdos_f_rename
	cp ESXDOS_F_GETFREE
	jp z, F_esxdos_f_getfree

	ld hl, STR_unhandled
	call F_esxdos_stdout_op
	ld a, ENOSYS
	scf
	ret

F_esxdos_stdout_op:
	ld d, a
	call F_esxdos_stdout_string
	ld a, d
	ld hl, v_workspace
	call ITOH8
	ld hl, v_workspace
	call F_esxdos_stdout_string
	ld a, 0x0A
	ld bc, STDOUTREG
	out (c), a
	ret

F_esxdos_stdout_string:
	ld bc, STDOUTREG
F_esxdos_stdout_loop:
	ld a, (hl)
	or a
	ret z
	out (c), a
	inc hl
	jr F_esxdos_stdout_loop

;--------------------------------------------------------------------------
; Dot-command entry point. The BASIC parser invokes this for any command
; whose first character is '.'. The filename is built in the permanent RAM
; workspace before the dot image replaces sections B and 3.
.globl F_esxdos_dot
F_esxdos_dot:
	ld iy, (v_esxdos_basic_iy)
	call F_esxdos_dot_path
	call STATEMENT_END

	; Keep D9 visible in page A while the controller fills D8/D9 directly.
	; The argument tail is then written through page A below.
	ld a, 0xD9
	call PUSHPAGEA

	call F_esxdos_dot_xfs_read_request
	ld hl, fs_scratchpad
	ld a, CMD_XFS_READ
	call SPECTRANEXT
	jp c, .notfound

	; Page A still contains the second DOT image page. Copy the original BASIC
	; command line into its reserved tail, which appears at $3E00 to the DOT
	; after the kernel maps that page into section 3.
	call F_esxdos_dot_copy_args

    ; Select the main display stream before page 30 becomes section 0.
    ; CALLBAS is safe here: ordinary Spectranet ROM/RAM mappings are still live.
    ld iy, (v_esxdos_basic_iy)
    ld a, 2
    rst CALLBAS
    defw ZX_CHAN_OPEN

	; Section 0 becomes the dot kernel. RST $00 enters its loader/return
	; trampoline, which maps D8 at B and D9 at section 3.
	ld a, 0x1E
	ld bc, PAGE0REG
	out (c), a

	; execute dot command via kernel
	rst 0

	jr c, .doterror

	; The kernel has restored page B and section 3. Restore normal page 0
	; before returning to the standard BASIC extension exit path.
	; A DOT's carry/A response is part of its ABI; do not turn a failed
	; command such as .tapein with a missing TAP into EXIT_SUCCESS.
.dotsuccess:
	xor a
	ld bc, PAGE0REG
	out (c), a
	call POPPAGEA
	ld iy, (v_esxdos_basic_iy)
	; A normal BASIC extension finishes with basext in page B. The DOT fallback
	; may have entered with a stale esxdos page already selected, so v_origpageb
	; is not a suitable return target here. Return directly into the fixed exit
	; routine after selecting basext, because code at $2000 is no longer valid.
	ld a, BAS_EXT_ROM_PAGE
	ld hl, EXIT_SUCCESS
	push hl
	jp SETPAGEB

.doterror:
	; The dot kernel has already restored page B and section 3, but page 0 is
	; still the kernel. Preserve the esxDOS result while returning to ordinary
	; Spectranet before using REPORTERR. Convert the common no-file result;
	; other esxDOS-only errors get a safe generic VFS error with a clear text.
	push af
	xor a
	ld bc, PAGE0REG
	out (c), a
	pop af
	push af
	call POPPAGEA
	pop af
	cp 5				; esxDOS ENOENT
	jr z, .dotenoent
	ld a, EIO
	ld hl, STR_dot_failed
	jr .dotreport
.dotenoent:
	ld a, ENOENT
	ld hl, STR_dot_notfound
.dotreport:
	ld iy, (v_esxdos_basic_iy)
	jp REPORTERR

.notfound:
	call POPPAGEA
	ld a, ENOENT
	ld hl, STR_dot_notfound
	jp REPORTERR

; Build the full XFS_READ descriptor in fs_scratchpad. CH_ADD originally points to
; the byte before '.', so skip the dot and leave BASIC positioned at the next
; statement delimiter. Save the raw line without the dot: its Spectrum-RAM
; source remains valid while the command image is loaded into D8/D9.
F_esxdos_dot_path:
	ld hl, (ZX_CH_ADD)
	inc hl
	inc hl
	ld (v_esxdos_dot_line), hl
	ld de, fs_scratchpad
	ld a, '/'
	ld (de), a
	inc de
	ld a, 'b'
	ld (de), a
	inc de
	ld a, 'i'
	ld (de), a
	inc de
	ld a, 'n'
	ld (de), a
	inc de
	ld a, '/'
	ld (de), a
	inc de
	ld b, 122		; 127 path characters including /bin/, plus a terminator
.copyname:
	ld a, (hl)
	cp ' '
	jr z, .endname
	cp ':'
	jr z, .endname
	cp 0x0D
	jr z, .endname
	ld (de), a
	inc de
	inc hl
	djnz .copyname
.skipname:
	ld a, (hl)
	cp ' '
	jr z, .endname
	cp ':'
	jr z, .endname
	cp 0x0D
	jr z, .endname
	inc hl
	jr .skipname
.endname:
	xor a
	ld (de), a
.findstatementend:
	ld a, (hl)
	cp ':'
	jr z, .statementend
	cp 0x0D
	jr z, .statementend
	inc hl
	jr .findstatementend
.statementend:
	ld (ZX_CH_ADD), hl
	ret

; Complete the fixed-size XFS_READ descriptor after its 128-byte path field.
F_esxdos_dot_xfs_read_request:
	xor a
	ld hl, fs_scratchpad + 128	; source offset = 0
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld a, 0xD8			; target first page
	ld (hl), a
	inc hl
	xor a				; target page offset = 0
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld a, 0x00			; maximum data = $00001E00 (7.5 KiB)
	ld (hl), a
	inc hl
	ld a, 0x1E
	ld (hl), a
	inc hl
	xor a
	ld (hl), a
	inc hl
	ld (hl), a
	ret

; Copy the complete dot command line (without the leading '.') into the tail
; of the D9 page. Dots own $2000-$3DFF, so the ABI reserves $3E00-$3FFF for
; this NUL-terminated line. ':' and CR terminate the BASIC statement.
F_esxdos_dot_copy_args:
	ld hl, (v_esxdos_dot_line)
	ld de, DOT_COMMAND_LINE_PAGE_A
	ld bc, 0x01FF		; 511 characters plus a NUL terminator
.copyarg:
	ld a, (hl)
	cp ':'
	jr z, .endargs
	cp 0x0D
	jr z, .endargs
	ld (de), a
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .copyarg
.endargs:
	xor a
	ld (de), a
	ret

.data
STR_ident:
	defb "esxDOS shim 0.01",0
STR_unhandled:
	defb "esx-unhandled ",0
STR_dot_notfound:
	defb "No such file",0
STR_dot_read_failed:
	defb "Unable to load dot command",0
STR_dot_failed:
	defb "Dot command failed",0
