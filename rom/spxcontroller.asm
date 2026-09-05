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
	scf
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
