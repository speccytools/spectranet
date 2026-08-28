; Shared helpers for the esxDOS compatibility module.

.include	"errno.inc"
.include	"sysvars.inc"

ESX_EOK		equ 0
ESX_ENOENT	equ 5
ESX_EIO		equ 6
ESX_EINVAL	equ 7
ESX_EACCES	equ 8
ESX_ENOSPC	equ 9
ESX_ENXIO	equ 10
ESX_ENODRV	equ 11
ESX_ENFILE	equ 12
ESX_EBADF	equ 13
ESX_ENODEV	equ 14
ESX_EOVERFLOW	equ 15
ESX_EISDIR	equ 16
ESX_ENOTDIR	equ 17
ESX_EEXIST	equ 18
ESX_ENOSYS	equ 20
ESX_ENAMETOOLONG equ 21
ESX_EINUSE	equ 23
ESX_ERDONLY	equ 24
ESX_EDIRINUSE	equ 27
ESX_EDRIVEBUSY	equ 29
ESXDOS_TIME_TMP equ fs_scratchpad + 64
ESXDOS_TIME_YEAR equ fs_scratchpad + 68
ESXDOS_TIME_DOY equ fs_scratchpad + 70
ESXDOS_TIME_OUT equ fs_scratchpad + 72
ESXDOS_TIME_MONTH equ fs_scratchpad + 74
ESXDOS_TIME_DAY equ fs_scratchpad + 75
ESXDOS_TIME_HOUR equ fs_scratchpad + 76
ESXDOS_TIME_MINUTE equ fs_scratchpad + 77
ESXDOS_TIME_YEAROFF equ fs_scratchpad + 78

.text
.globl F_esxdos_restore_regs
F_esxdos_restore_regs:
	ld a, (v_asave)
	ld hl, (v_hl2save)
	ld de, (v_de2save)
	; IX is deliberately not restored.  The native esxDOS ABI carries all
	; pathname and transfer-buffer pointers in IX, and the RST $08 bridge
	; leaves that caller register live for the operation handler.
	ret

.globl F_esxdos_current_drive
F_esxdos_current_drive:
	xor a
	call F_esxdos_drive_to_mount
	ret c
	inc a
	ret

.globl F_esxdos_select_drive
F_esxdos_select_drive:
	call F_esxdos_drive_to_mount
	ret c
	ld (v_vfs_curmount), a
	or a
	ret

.globl F_esxdos_set_current_drive
F_esxdos_set_current_drive:
	call F_esxdos_drive_to_mount
	ret c
	ld (v_vfs_curmount), a
	or a
	ret

.globl F_esxdos_save_curmount
F_esxdos_save_curmount:
	push af
	ld a, (v_vfs_curmount)
	ld (v_esxdos_savedmount), a
	pop af
	ret

.globl F_esxdos_restore_curmount
F_esxdos_restore_curmount:
	push af
	ld a, (v_esxdos_savedmount)
	ld (v_vfs_curmount), a
	pop af
	ret

.globl F_esxdos_drive_to_mount
F_esxdos_drive_to_mount:
	cp '*'
	jr z, .current
	cp '$'
	jr z, .current
	or a
	jr z, .current
	dec a
	cp 4
	jr nc, .notmounted
	jr .checkmounted
.current:
	ld a, (v_vfs_curmount)
.checkmounted:
	push af
	add a, VFSVECBASE % 256
	ld l, a
	ld h, 0x3F
	ld a, (hl)
	and a
	jr z, .notmounted_pop
	pop af
	or a
	ret
.notmounted_pop:
	pop af
.notmounted:
	ld a, TNOTMOUNTED
	scf
	ret

.globl F_esxdos_error
F_esxdos_error:
	cp SUCCESS
	jr z, .ok
	cp ENOENT
	jr z, .enoent
	cp EIO
	jr z, .eio
	cp ENXIO
	jr z, .enxio
	cp EBADF
	jr z, .ebadf
	cp EACCES
	jr z, .eacces
	cp EBUSY
	jr z, .ebusy
	cp EEXIST
	jr z, .eexist
	cp ENOTDIR
	jr z, .enotdir
	cp EISDIR
	jr z, .eisdir
	cp EINVAL
	jr z, .einval
	cp ENFILE
	jr z, .enfile
	cp EMFILE
	jr z, .enfile
	cp EFBIG
	jr z, .eoverflow
	cp ENOSPC
	jr z, .enospc
	cp EROFS
	jr z, .erdonly
	cp ENAMETOOLONG
	jr z, .enametoolong
	cp ENOSYS
	jr z, .enosys
	cp ENOTEMPTY
	jr z, .edirinuse
	cp EBADFD
	jr z, .ebadf
	cp TNOTMOUNTED
	jr z, .enodrv
	ld a, ESX_EIO
	scf
	ret
.ok:
	ld a, ESX_EOK
	or a
	ret
.enoent:
	ld a, ESX_ENOENT
	scf
	ret
.eio:
	ld a, ESX_EIO
	scf
	ret
.enxio:
	ld a, ESX_ENXIO
	scf
	ret
.ebadf:
	ld a, ESX_EBADF
	scf
	ret
.eacces:
	ld a, ESX_EACCES
	scf
	ret
.ebusy:
	ld a, ESX_EDRIVEBUSY
	scf
	ret
.eexist:
	ld a, ESX_EEXIST
	scf
	ret
.enotdir:
	ld a, ESX_ENOTDIR
	scf
	ret
.eisdir:
	ld a, ESX_EISDIR
	scf
	ret
.einval:
	ld a, ESX_EINVAL
	scf
	ret
.enfile:
	ld a, ESX_ENFILE
	scf
	ret
.eoverflow:
	ld a, ESX_EOVERFLOW
	scf
	ret
.enospc:
	ld a, ESX_ENOSPC
	scf
	ret
.erdonly:
	ld a, ESX_ERDONLY
	scf
	ret
.enametoolong:
	ld a, ESX_ENAMETOOLONG
	scf
	ret
.enosys:
	ld a, ESX_ENOSYS
	scf
	ret
.edirinuse:
	ld a, ESX_EDIRINUSE
	scf
	ret
.enodrv:
	ld a, ESX_ENODRV
	scf
	ret

.globl F_esxdos_einval
F_esxdos_einval:
	ld a, EINVAL
	jp F_esxdos_error

.globl F_esxdos_enosys
F_esxdos_enosys:
	ld a, ENOSYS
	jp F_esxdos_error

.globl F_esxdos_unix_to_dos
F_esxdos_unix_to_dos:
	ld (ESXDOS_TIME_OUT), de
	ld de, ESXDOS_TIME_TMP
	ld bc, 4
	ldir
	ld hl, (ESXDOS_TIME_TMP)
	ld a, h
	or l
	ld hl, (ESXDOS_TIME_TMP+2)
	or h
	or l
	jp z, F_esxdos_time_zero
	ld hl, 1970
	ld (ESXDOS_TIME_YEAR), hl
.year_loop:
	call F_esxdos_year_const
	push hl
	call F_esxdos_time_ge_const
	pop hl
	jr c, .year_done
	call F_esxdos_time_sub_const
	ld hl, (ESXDOS_TIME_YEAR)
	inc hl
	ld (ESXDOS_TIME_YEAR), hl
	jr .year_loop
.year_done:
	ld hl, (ESXDOS_TIME_YEAR)
	ld de, 1980
	or a
	sbc hl, de
	jp c, F_esxdos_time_min
	ld hl, (ESXDOS_TIME_YEAR)
	ld de, 2108
	or a
	sbc hl, de
	jp nc, F_esxdos_time_max
	ld hl, 0
	ld (ESXDOS_TIME_DOY), hl
.day_loop:
	ld hl, ESXDOS_SEC_DAY
	call F_esxdos_time_ge_const
	jr c, .days_done
	ld hl, ESXDOS_SEC_DAY
	call F_esxdos_time_sub_const
	ld hl, (ESXDOS_TIME_DOY)
	inc hl
	ld (ESXDOS_TIME_DOY), hl
	jr .day_loop
.days_done:
	ld a, 1
	ld (ESXDOS_TIME_MONTH), a
.month_loop:
	call F_esxdos_month_days
	ld e, a
	ld d, 0
	ld hl, (ESXDOS_TIME_DOY)
	or a
	sbc hl, de
	jr c, .month_done
	ld (ESXDOS_TIME_DOY), hl
	ld a, (ESXDOS_TIME_MONTH)
	inc a
	ld (ESXDOS_TIME_MONTH), a
	jr .month_loop
.month_done:
	ld hl, (ESXDOS_TIME_DOY)
	ld a, l
	inc a
	ld (ESXDOS_TIME_DAY), a
	xor a
	ld (ESXDOS_TIME_HOUR), a
.hour_loop:
	ld hl, ESXDOS_SEC_HOUR
	call F_esxdos_time_ge_const
	jr c, .hours_done
	ld hl, ESXDOS_SEC_HOUR
	call F_esxdos_time_sub_const
	ld a, (ESXDOS_TIME_HOUR)
	inc a
	ld (ESXDOS_TIME_HOUR), a
	jr .hour_loop
.hours_done:
	xor a
	ld (ESXDOS_TIME_MINUTE), a
.minute_loop:
	ld hl, ESXDOS_SEC_MIN
	call F_esxdos_time_ge_const
	jr c, .minutes_done
	ld hl, ESXDOS_SEC_MIN
	call F_esxdos_time_sub_const
	ld a, (ESXDOS_TIME_MINUTE)
	inc a
	ld (ESXDOS_TIME_MINUTE), a
	jr .minute_loop
.minutes_done:
	ld hl, (ESXDOS_TIME_YEAR)
	ld de, 1980
	or a
	sbc hl, de
	ld a, l
	ld (ESXDOS_TIME_YEAROFF), a
	jp F_esxdos_time_pack

F_esxdos_time_zero:
	ld hl, (ESXDOS_TIME_OUT)
	xor a
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), a
	ret

F_esxdos_time_min:
	ld hl, (ESXDOS_TIME_OUT)
	xor a
	ld (hl), a
	inc hl
	ld (hl), a
	inc hl
	ld (hl), 0x21
	inc hl
	ld (hl), a
	ret

F_esxdos_time_max:
	ld hl, (ESXDOS_TIME_OUT)
	ld (hl), 0x7d
	inc hl
	ld (hl), 0xbf
	inc hl
	ld (hl), 0x9f
	inc hl
	ld (hl), 0xff
	ret

F_esxdos_time_pack:
	ld hl, (ESXDOS_TIME_OUT)
	ld a, (ESXDOS_TIME_MINUTE)
	and 7
	add a, a
	add a, a
	add a, a
	add a, a
	add a, a
	ld b, a
	ld a, (ESXDOS_TIME_TMP)
	srl a
	or b
	ld (hl), a
	inc hl
	ld a, (ESXDOS_TIME_HOUR)
	add a, a
	add a, a
	add a, a
	ld b, a
	ld a, (ESXDOS_TIME_MINUTE)
	srl a
	srl a
	srl a
	or b
	ld (hl), a
	inc hl
	ld a, (ESXDOS_TIME_MONTH)
	and 7
	add a, a
	add a, a
	add a, a
	add a, a
	add a, a
	ld b, a
	ld a, (ESXDOS_TIME_DAY)
	or b
	ld (hl), a
	inc hl
	ld a, (ESXDOS_TIME_YEAROFF)
	add a, a
	ld b, a
	ld a, (ESXDOS_TIME_MONTH)
	srl a
	srl a
	srl a
	or b
	ld (hl), a
	ret

F_esxdos_year_const:
	call F_esxdos_is_leap
	or a
	ld hl, ESXDOS_SEC_YEAR_COMMON
	ret z
	ld hl, ESXDOS_SEC_YEAR_LEAP
	ret

F_esxdos_is_leap:
	ld hl, (ESXDOS_TIME_YEAR)
	ld a, l
	and 3
	jr nz, .common
	ld a, h
	cp 0x08
	jr nz, .leap
	ld a, l
	cp 0x34
	jr z, .common
.leap:
	ld a, 1
	ret
.common:
	xor a
	ret

F_esxdos_month_days:
	ld a, (ESXDOS_TIME_MONTH)
	dec a
	ld e, a
	ld d, 0
	call F_esxdos_is_leap
	or a
	ld hl, ESXDOS_MONTH_DAYS_COMMON
	jr z, .table
	ld hl, ESXDOS_MONTH_DAYS_LEAP
.table:
	add hl, de
	ld a, (hl)
	ret

F_esxdos_time_ge_const:
	ld de, ESXDOS_TIME_TMP+3
	ld bc, 3
	add hl, bc
	ld b, 4
.compare:
	ld a, (de)
	cp (hl)
	ret nz
	dec de
	dec hl
	djnz .compare
	or a
	ret

F_esxdos_time_sub_const:
	ld de, ESXDOS_TIME_TMP
	ld b, 4
	or a
.subtract:
	ld a, (de)
	sbc a, (hl)
	ld (de), a
	inc de
	inc hl
	djnz .subtract
	ret

ESXDOS_SEC_YEAR_COMMON:	defb 0x80,0x33,0xe1,0x01
ESXDOS_SEC_YEAR_LEAP:	defb 0x00,0x85,0xe2,0x01
ESXDOS_SEC_DAY:	defb 0x80,0x51,0x01,0x00
ESXDOS_SEC_HOUR:	defb 0x10,0x0e,0x00,0x00
ESXDOS_SEC_MIN:	defb 0x3c,0x00,0x00,0x00
ESXDOS_MONTH_DAYS_COMMON:	defb 31,28,31,30,31,30,31,31,30,31,30,31
ESXDOS_MONTH_DAYS_LEAP:	defb 31,29,31,30,31,30,31,31,30,31,30,31
