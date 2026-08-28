; esxDOS F_FSTAT ($A1): obtain the 11-byte DOS stat record for an open file.
;
; Spectranet's VFS does not expose a handle-stat entry point. Derive the file
; length using LSEEK while restoring the original position before returning.
; This works for every existing XFS-backed engine and avoids reopening paths.

.include "errno.inc"
.include "fcntl.inc"
.include "spectranet.inc"
.include "sysvars.inc"

ESXDOS_FSTAT_OUT:      equ fs_scratchpad
ESXDOS_FSTAT_FD:       equ fs_scratchpad+2
ESXDOS_FSTAT_POS_LO:   equ fs_scratchpad+4
ESXDOS_FSTAT_POS_HI:   equ fs_scratchpad+6
ESXDOS_FSTAT_SIZE_LO:  equ fs_scratchpad+8
ESXDOS_FSTAT_SIZE_HI:  equ fs_scratchpad+10

.text
.globl F_esxdos_f_fstat
F_esxdos_f_fstat:
	call F_esxdos_restore_regs
	ld (ESXDOS_FSTAT_FD), a
	push ix
	pop hl
	ld (ESXDOS_FSTAT_OUT), hl

	; Capture the current position so F_FSTAT is observational, not a seek.
	ld de, 0
	ld hl, 0
	ld c, SEEK_CUR
	call LSEEK
	jr c, .error
	ld (ESXDOS_FSTAT_POS_LO), hl
	ld (ESXDOS_FSTAT_POS_HI), de

	; SEEK_END with offset zero returns the file size in DEHL.
	ld a, (ESXDOS_FSTAT_FD)
	ld de, 0
	ld hl, 0
	ld c, SEEK_END
	call LSEEK
	jr c, .error
	ld (ESXDOS_FSTAT_SIZE_LO), hl
	ld (ESXDOS_FSTAT_SIZE_HI), de

	; Put the handle precisely where the caller left it.
	ld a, (ESXDOS_FSTAT_FD)
	ld hl, (ESXDOS_FSTAT_POS_LO)
	ld de, (ESXDOS_FSTAT_POS_HI)
	ld c, SEEK_SET
	call LSEEK
	jr c, .error

	; esxDOS record: drive, device, attributes, DOS time/date, 32-bit size.
	; Attribute/timestamp information is unavailable through F_FSTAT for now;
	; callers such as .more require the size at offsets 7..10.
	ld ix, (ESXDOS_FSTAT_OUT)
	xor a
	ld (ix+0), a
	ld (ix+1), a
	ld (ix+2), a
	ld (ix+3), a
	ld (ix+4), a
	ld (ix+5), a
	ld (ix+6), a
	ld hl, (ESXDOS_FSTAT_SIZE_LO)
	ld (ix+7), l
	ld (ix+8), h
	ld hl, (ESXDOS_FSTAT_SIZE_HI)
	ld (ix+9), l
	ld (ix+10), h
	or a
	ret

.error:
	jp F_esxdos_error
