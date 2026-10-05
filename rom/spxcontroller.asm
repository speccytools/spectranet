; Executable half of Spectranext controller page $48.
; Page B is already mapped to $48 by F_spectranext_op.
; $2000-$27FF: code, $2800-$2FFD: workspace, $2FFE: command, $2FFF: status.
.include "spectranet.inc"

WORKSPACE	equ 0x2800
CMD_REG		equ 0x2FFE
STATUS_REG	equ 0x2FFF

WS_controller_status	equ WORKSPACE + 0
WS_wifi_connection	equ WORKSPACE + 1
WS_ipv4			equ WORKSPACE + 2
WS_scan_count		equ WORKSPACE + 0
WS_ap_index		equ WORKSPACE + 0
WS_ap_name		equ WORKSPACE + 0
WS_ap_bssid		equ WORKSPACE + 64
WS_ap_rssi		equ WORKSPACE + 70
WS_wifi_ssid		equ WORKSPACE + 0
WS_wifi_password	equ WORKSPACE + 64
WS_wifi_bssid		equ WORKSPACE + 128
WS_dns_host		equ WORKSPACE + 0
WS_dns_ipv4_out	equ WORKSPACE + 0
WS_enginecall_input	equ WORKSPACE + 0
WS_enginecall_output	equ WORKSPACE + 128
WS_enginecall_op	equ WORKSPACE + 256
WS_enginecall_result	equ WORKSPACE + 512
WS_get_message_ouput equ WORKSPACE + 0
WS_get_message_pending equ WORKSPACE + 128
WS_xfs_read_filename		equ WORKSPACE + 0
WS_xfs_read_source_offset	equ WORKSPACE + 128
WS_xfs_read_target_page		equ WORKSPACE + 132
WS_xfs_read_target_offset	equ WORKSPACE + 133
WS_xfs_read_maximum_data	equ WORKSPACE + 135
WS_xfs_read_bytes_read		equ WORKSPACE + 139

STATUS_IN_PROGRESS	equ 0xFF
.text

F_spxcontroller_dispatch:
    cp CMD_GET_VERSION
    jp z, op_get_version
    cp CMD_SYS_DOT_DISPATCH
    jp z, op_sys_dot_dispatch
    cp CMD_SYS_SETTINGS_READ
    jp z, op_settings_read
    cp CMD_SYS_SETTINGS_WRITE
    jp z, op_settings_write
    cp CMD_SYS_UPGRADE
    jp z, op_sys_upgrade
    cp CMD_SYS_DIAGNOSTICS
    jp z, op_sys_diagnostics
    cp CMD_SYS_JOYSTICK_STATUS
    jp z, op_sys_joystick_status
	cp		CMD_GET_STATUS
	jr		z, op_get_status
	cp		CMD_WIFI_SCAN
	jr		z, op_wifi_scan
	cp		CMD_WIFI_GET_AP
	jr		z, op_wifi_get_ap
	cp		CMD_WIFI_CONNECT
	jp		z, op_wifi_connect
	cp		CMD_WIFI_DISCONNECT
	jp		z, op_wifi_disconnect
	cp		CMD_DNS
	jp		z, op_dns
	cp		CMD_ENGINECALL
	jp		z, op_enginecall
	cp		CMD_GET_MESSAGE
	jp		z, op_get_message
	cp		CMD_XFS_READ
	jp		z, op_xfs_read
	ld a, 1
	scf
	ret

; CMD_GET_VERSION (15) — copy the build's NUL-terminated version to HL.
; This runs entirely in the shared controller ROM, on hardware and Fuse.
; The caller provides 32 writable bytes outside page B.
op_get_version:
    push hl
    pop de
    ld hl, spx_version
op_get_version_copy:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    or a
    jr nz, op_get_version_copy
    xor a
    ret

; CMD_GET_STATUS (0) — issue command, then read results from workspace.
op_get_status:

	ld		a, CMD_GET_STATUS
	call	issue_out_poll
	jr		nz, op_get_status_error

	push	hl

	ld		hl, WS_ipv4
	ld		bc, 4
	ldir

	ld		a, (WS_wifi_connection)
	ld		c, a

	ld		a, (WS_controller_status)
	ld		b, a

	pop		hl

	xor		a
	ret

op_get_status_error:
	scf
	ret

; CMD_WIFI_SCAN (1) — A = count only.
op_wifi_scan:

	ld		a, CMD_WIFI_SCAN
	call	issue_out_poll
	jp		nz, generic_error

	ld		a, (WS_scan_count)
	or		a
	ret

; CMD_WIFI_GET_AP (2) — write index, issue command, read extended scan result.
; DE points to a 71-byte buffer: SSID[64], BSSID[6], signed RSSI.
op_wifi_get_ap:

	ld		a, c
	ld		(WS_ap_index), a

	ld		a, CMD_WIFI_GET_AP
	call	issue_out_poll
	jr		nz, op_wifi_get_ap_err

	ld		bc, 71
	ld		hl, WS_ap_name
	ldir

	xor		a
	ret

op_wifi_get_ap_err:
	jp		generic_error

; CMD_WIFI_CONNECT (3) — copy SSID+password+BSSID to workspace, then issue command.
; BC points to the optional 6-byte BSSID; BC=0 means unavailable.
op_wifi_connect:

	push	bc
	push	de
	ld		de, WS_wifi_ssid
	ld		bc, 64
	ldir

	pop		hl
	ld		de, WS_wifi_password
	ld		bc, 64
	ldir

	pop		hl
	ld		de, WS_wifi_bssid
	ld		a, h
	or		l
	jr		z, op_wifi_connect_no_bssid
	ld		bc, 6
	ldir
	jr		op_wifi_connect_issue

op_wifi_connect_no_bssid:
	xor		a
	ld		b, 6
op_wifi_connect_clear_bssid:
	ld		(de), a
	inc		de
	djnz	op_wifi_connect_clear_bssid

op_wifi_connect_issue:
	ld		a, CMD_WIFI_CONNECT
	call	issue_out_poll
	jr		nz, op_wifi_connect_error

	xor		a
	ret

op_wifi_connect_error:
	jp		generic_error

; CMD_WIFI_DISCONNECT (4)
op_wifi_disconnect:

	ld		a, CMD_WIFI_DISCONNECT
	call	issue_out_poll
	jp		nz, generic_error

	xor		a
	ret

; CMD_DNS (5) — hostname from HL to staging; on success, 4-byte IPv4 copied to caller buffer DE.
op_dns:

	push	de

	ld		de, WS_dns_host
	ld		bc, 64
	ldir

	ld		a, CMD_DNS
	call	issue_out_poll
	jr		nz, op_dns_error

	pop		de

	ld		hl, WS_dns_ipv4_out
	ld		bc, 4
	ldir

	xor		a
	ret

op_dns_error:
	pop		de
	jp		generic_error

; CMD_ENGINECALL (6) — HL=input path, DE=output path, BC=operation string (each copied into staging).
op_enginecall:

	push	bc
	push	de

	ld		de, WS_enginecall_input
	ld		bc, 128
	ldir

	pop	hl
	ld		de, WS_enginecall_output
	ld		bc, 128
	ldir

	pop	hl
	ld		de, WS_enginecall_op
	ld		bc, 256
	ldir

	ld		a, CMD_ENGINECALL
	call	issue_out_poll
	jr		z, .enginecall_ok
	ld		a, (WS_enginecall_result)
	jp		generic_error

.enginecall_ok:
	xor		a
	ret

; CMD_GET_MESSAGE (7) — copy controller-posted message to caller buffer from staging.
op_get_message:

	push	hl

	ld		a, CMD_GET_MESSAGE
	call	issue_out_poll
	jp		nz, op_get_message_error

	pop		de

	ld		hl, WS_get_message_ouput
	ld		bc, 128
	ldir

	ld		a, (WS_get_message_pending)
	or		a
	ret


; Set STATUS busy, write command byte from A, poll STATUS until != $FF. Returns final status in A.
; Clobbers: A, F
issue_out_poll:
	push	af
	ld		a, STATUS_IN_PROGRESS
	ld		(STATUS_REG), a
	pop		af
	ld		(CMD_REG), a
pollrom:
	ld		a, (STATUS_REG)
	cp		STATUS_IN_PROGRESS
	jr		z, pollrom
	or		a
	ret

; CMD_XFS_READ (8) — copy descriptor and source filename to staging.
op_xfs_read:

	ld		de, WS_xfs_read_filename
	ld		bc, 139
	ldir

	ld		a, CMD_XFS_READ
	call	issue_out_poll
	jp		nz, generic_error

	ld		hl, (WS_xfs_read_bytes_read)
	ld		de, (WS_xfs_read_bytes_read + 2)
	xor		a
	ret

generic_error:
	scf
	ret

op_get_message_error:
	pop		hl
	jp		generic_error

; Settings ABI: A=operation, HL=buffer outside page B, BC=capacity/exact
; length. BC returns required length (16) on READ. Carry/A return error.
; WS+0=u16 length, WS+2=error, WS+16=raw payload only.
op_settings_read:
    call settings_validate_buffer
    ret c
    ld (WORKSPACE), bc
    push hl
    ld a, CMD_SYS_SETTINGS_READ
    call issue_out_poll
    pop de
    ld bc, (WORKSPACE)
    jp nz, op_settings_error
    ld hl, WORKSPACE+16
    ldir
    ld bc, SYS_SETTINGS_SIZE
    xor a
    ret
op_settings_write:
    call settings_validate_buffer
    ret c
    ld a, b
    or a
    jr nz, op_settings_bad_payload
    ld a, c
    cp SYS_SETTINGS_SIZE
    jr nz, op_settings_bad_payload
    ld (WORKSPACE), bc
    ld de, WORKSPACE+16
    ldir
    ld a, CMD_SYS_SETTINGS_WRITE
    call issue_out_poll
    jp nz, op_settings_error
    xor a
    ret
op_settings_bad_payload:
    ld a, 3
    scf
    ret
op_settings_error:
    ld a, (WORKSPACE+2)
    scf
    ret
; HL=9-byte diagnostics buffer: LE installed bootloader u32, active policy
; u8, LE lockout reason u32. Never writable through settings.
op_sys_diagnostics:
    push hl
    ld a, CMD_SYS_DIAGNOSTICS
    call issue_out_poll
    pop de
    jp nz, generic_error
    ld hl, WORKSPACE
    ld bc, 10
    ldir
    xor a
    ret

; HL=8-byte output: state, enabled, Kempston bits, device address, VID, PID.
op_sys_joystick_status:
    push hl
    ld a, CMD_SYS_JOYSTICK_STATUS
    call issue_out_poll
    pop de
    jp nz, generic_error
    ld hl, WORKSPACE
    ld bc, 8
    ldir
    xor a
    ret

op_sys_upgrade:
    ld a, CMD_SYS_UPGRADE
    call issue_out_poll
    jp nz, op_settings_error
    xor a
    ret

; Reject buffers aliasing the gateway-mapped page B, or wrapping address space.
settings_validate_buffer:
    push hl
    ld de, SYS_SETTINGS_SIZE
    add hl, de
    jr c, settings_buffer_pop_error
    dec hl
    ld a, h
    pop hl
    ld d, a
    ld a, h
    cp 0x20
    jr nc, settings_buffer_above
    ld a, d
    cp 0x20
    jp nc, op_settings_bad_payload
    xor a
    ret
settings_buffer_above:
    cp 0x30
    jp c, op_settings_bad_payload
    xor a
    ret
settings_buffer_pop_error:
    pop hl
    jp op_settings_bad_payload

SPX_HANDOFF equ 0x8080
op_sys_dot_dispatch:
    ld de, SPX_HANDOFF
    or a
    sbc hl, de
    jp nz, .no_spx_command
    ld a, (SPX_HANDOFF+4)
    cp 1
    jp nz, .no_spx_command
    ld a, (SPX_HANDOFF+5)
    ld c, a
    ld hl, SPX_HANDOFF+8
.skip_spx_space:
    ld a, c
    cp 7
    jp c, .no_spx_command
    ld a, (hl)
    cp ' '
    jr nz, .match_spx_begin
    inc hl
    dec c
    jr .skip_spx_space
.match_spx_begin:
    ld de, STR_spx_upgrade
    ld b, 7
.match_spx_upgrade:
    ld a, (de)
    cp (hl)
    jp nz, .no_spx_command
    inc hl
    inc de
    dec c
    djnz .match_spx_upgrade
.trailing_spx_space:
    ld a, c
    or a
    jr z, .prepare_spx_upgrade
    ld a, (hl)
    cp ' '
    jp nz, .no_spx_command
    inc hl
    dec c
    jr .trailing_spx_space
.prepare_spx_upgrade:
    call op_sys_upgrade
    jr c, .spx_upgrade_error
    jr .spx_upgrade_return
.spx_upgrade_error:
    ; The upper print vectors may not exist before delayed initialization.
    ; Copy the message into host RAM; zeropage prints using direct ROM helpers
    ; after the gateway has restored page B. Preserve the controller error.
    ld hl, STR_spx_upgrade_failed
    cp 5
    jr nz, .copy_spx_upgrade_error
    ld hl, STR_spx_bootloader_required
.copy_spx_upgrade_error:
    push af
    ld de, 0x8200
.copy_spx_error_char:
    ld a, (hl)
    ld (de), a
    inc hl
    inc de
    or a
    jr nz, .copy_spx_error_char
    pop af
.spx_upgrade_return:
    ; Carry means handled; A=0 returns normally for reset after page-out.
    ; Errors return normally to the caller without deferred initialization.
    scf
    ret
.no_spx_command:
    xor a
    ret
STR_spx_upgrade:
    .ascii "upgrade"
STR_spx_bootloader_required:
    .asciz "Bootloader update required for .spx upgrade.\nUpdate the bootloader, then try again.\n"
STR_spx_upgrade_failed:
    .asciz "Upgrade preparation failed. Update was not started.\n"
.include "spxver.xinc"
