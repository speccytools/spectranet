; Spectranext multiplex / engine-call gateway: page B = CONTROLLER_PAGE,
; CMD/STATUS at WORKSPACE+0/+1, payload at +2+
; (RP2350: spectranet memory_set_page maps that page to spectranext_controller).
;
; Register summary for F_spectranext_op (after IXCALL/HLCALL dispatch returns here):
;   IX    Preserved (dispatcher used IX to reach this ROM).
;   IY    Preserved by these routines (not used here).
;   issue_out_poll clobbers A, flags; leaves BC, DE, HL, IX, IY as they were on entry.
;
.include "spectranet.inc"

CONTROLLER_PAGE	equ 0x48
WORKSPACE	equ 0x2000

CMD_REG		equ WORKSPACE + 0
STATUS_REG	equ WORKSPACE + 1

; --- Workspace payload (matches spectranext_workspace_t after CMD/STATUS in spectranext_controller) ---

; get_controller_status.out
WS_controller_status	equ WORKSPACE + 2
WS_wifi_connection	equ WORKSPACE + 3
WS_ipv4			equ WORKSPACE + 4

; wifi_scan.io.out
WS_scan_count		equ WORKSPACE + 2

; wifi_get_ap.io.in / io.out
WS_ap_index		equ WORKSPACE + 2
WS_ap_name		equ WORKSPACE + 2

; wifi_connect.io.in (ssid 0..63, password 64..127)
WS_wifi_ssid		equ WORKSPACE + 2
WS_wifi_password	equ WORKSPACE + 66

; dns.io.in.host / dns.io.out.ipv4 (host 0..63; ipv4 uint32 at 0..3 of dns view)
WS_dns_host		equ WORKSPACE + 2
WS_dns_ipv4_out	equ WORKSPACE + 2

; enginecall.io (input 128, output 128, operation 256)
WS_enginecall_input	equ WORKSPACE + 2
WS_enginecall_output	equ WORKSPACE + 130
WS_enginecall_op	equ WORKSPACE + 258
WS_enginecall_result	equ WORKSPACE + 514

WS_get_message_ouput equ WORKSPACE + 2
WS_get_message_pending equ WORKSPACE + 130

; xfs_read.in (path 128, source offset u32, target page u8, target offset
; u16, maximum data u32) and xfs_read.out.bytes_read (u32).
WS_xfs_read_filename		equ WORKSPACE + 2
WS_xfs_read_source_offset	equ WORKSPACE + 130
WS_xfs_read_target_page	equ WORKSPACE + 134
WS_xfs_read_target_offset	equ WORKSPACE + 135
WS_xfs_read_maximum_data	equ WORKSPACE + 137
WS_xfs_read_bytes_read	equ WORKSPACE + 141

; STATUS_REG: 0xFF = busy; when done A=0 success (carry clear), A!=0 failure (carry set)
STATUS_IN_PROGRESS	equ 0xFF

.text

; -----------------------------------------------------------------------------
; F_spectranext_op — ROM 0x3EF0 (jumptable).
; On entry: A = opcode (0..8). Other registers per command below (set before CALL).
;
; issue_out_poll: sets STATUS=$FF, writes CMD, polls STATUS until byte != $FF.
; Final byte in A: $0 = success, non-zero = failure (Z set if success). Each op then maps
; failure -> SCF before RET, success -> OR A before RET (carry clear).
;
; CMD_GET_STATUS (0)
;   in:  DE = caller buffer for 4-byte IPv4 (host order), written by ROM on success.
;   out: B = controller_status, C = wifi_connection (int8 wire value); carry=0 success.
;   mod: DE += 4; HL used; BC used; A,C,F clobbered.
;
; CMD_WIFI_SCAN (1)
;   in:  (none besides A=opcode on entry to F_spectranext_op)
;   out: A = scan_count; carry=0 success.
;   mod: A, F (stack holds A briefly); DE, HL, BC, IX, IY preserved from routine entry.
;
; CMD_WIFI_GET_AP (2)
;   in:  C = AP index; DE = caller buffer for AP name (up to 64 bytes, NUL-terminated from device).
;   out: carry=0 success; (DE..) filled via LDIR from staging.
;   mod: BC=0 after LDIR; HL advanced; DE += 64; A,F clobbered.
;
; CMD_WIFI_CONNECT (3)
;   in:  HL = SSID string; DE = password string (each up to 64 bytes read via LDIR into staging).
;   out: carry=0 success / carry=1 failure; A indeterminate on success path (0 from poll).
;   mod: HL, DE, BC destroyed by LDIR; stack clean.
;
; CMD_WIFI_DISCONNECT (4)
;   in:  —
;   out: A = last status byte if failure path; carry=0 iff status returned $00.
;   mod: A, F.
;
; CMD_DNS (5)
;   in:  HL = hostname; DE = caller buffer for 4-byte IPv4 result.
;   out: carry=0 success; (DE..DE+3) filled from staging on success.
;   mod: HL, DE, BC from LDIRs; DE += 4 on success exit.
;
; CMD_ENGINECALL (6)
;   in:  HL = input path, DE = output path, BC = operation string.
;   out: carry=0 success; carry=1 failure with status byte in A (engine result/status).
;   mod: HL, DE, BC destroyed by LDIR.
;
; CMD_GET_MESSAGE (7)
;   in:  HL = caller buffer for message copy (128-byte staging copied out; NUL-terminated by controller).
;   out: A = WS_get_message_pending (pending count/flag from controller); carry=0 success.
;   mod: HL, DE, BC clobbered by LDIR; B briefly holds pending across POPPAGEB; DE += 128 on success.
;
; CMD_XFS_READ (8)
;   in:  HL = pointer to packed descriptor: source filename (128 bytes,
;        including NUL), source offset (u32), target first RAM page (u8),
;        target page offset (u16), maximum read size (u32).
;   out: DEHL = bytes read; carry=0 success, carry=1 failure.
;   mod: HL, DE, BC destroyed by LDIR.
; -----------------------------------------------------------------------------

.globl F_spectranext_op
F_spectranext_op:
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
	; Unknown opcode: fail without touching staging.
	scf
	ret

F_spectranext_page_in:
	ld		a, CONTROLLER_PAGE
	jp		PUSHPAGEB

F_spectranext_success:
	call	POPPAGEB
	xor		a
	ret

; CMD_GET_STATUS (0) — issue command, then read results from workspace.
op_get_status:
	call	F_spectranext_page_in

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

	jp		F_spectranext_success

op_get_status_error:
	ld		b, a
	call	POPPAGEB
	ld		a, b
	scf
	ret

; CMD_WIFI_SCAN (1) — A = count only.
op_wifi_scan:
	call	F_spectranext_page_in

	ld		a, CMD_WIFI_SCAN
	call	issue_out_poll
	jp		nz, generic_error

	ld		a, (WS_scan_count)
	ld		ixl, a
	call	POPPAGEB
	ld		a, ixl
	or		a
	ret

; CMD_WIFI_GET_AP (2) — write index, issue command, read name.
op_wifi_get_ap:
	call	F_spectranext_page_in

	ld		a, c
	ld		(WS_ap_index), a

	ld		a, CMD_WIFI_GET_AP
	call	issue_out_poll
	jr		nz, op_wifi_get_ap_err

	ld		bc, 64
	ld		hl, WS_ap_name
	ldir

	jp		F_spectranext_success

op_wifi_get_ap_err:
	jp		generic_error

; CMD_WIFI_CONNECT (3) — copy SSID+password to workspace, then issue command.
op_wifi_connect:
	call	F_spectranext_page_in

	push	de
	ld		de, WS_wifi_ssid
	ld		bc, 64
	ldir

	pop		hl
	ld		de, WS_wifi_password
	ld		bc, 64
	ldir

	ld		a, CMD_WIFI_CONNECT
	call	issue_out_poll
	jr		nz, op_wifi_connect_error

	jp		F_spectranext_success

op_wifi_connect_error:
	jp		generic_error

; CMD_WIFI_DISCONNECT (4)
op_wifi_disconnect:
	call	F_spectranext_page_in

	ld		a, CMD_WIFI_DISCONNECT
	call	issue_out_poll
	jp		nz, generic_error

	jp		F_spectranext_success

; CMD_DNS (5) — hostname from HL to staging; on success, 4-byte IPv4 copied to caller buffer DE.
.globl F_spectranext_dns
F_spectranext_dns:

op_dns:
	call	F_spectranext_page_in

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

	jp		F_spectranext_success

op_dns_error:
	pop		de
	jp		generic_error

; CMD_ENGINECALL (6) — HL=input path, DE=output path, BC=operation string (each copied into staging).
op_enginecall:
	call	F_spectranext_page_in

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
	jp		F_spectranext_success

; CMD_GET_MESSAGE (7) — copy controller-posted message to caller buffer from staging.
op_get_message:
	call	F_spectranext_page_in

	push	hl

	ld		a, CMD_GET_MESSAGE
	call	issue_out_poll
	jp		nz, op_get_message_error

	pop		de

	ld		hl, WS_get_message_ouput
	ld		bc, 128
	ldir

	ld		a, (WS_get_message_pending)
	ld		ixl, a
	call	POPPAGEB
	ld		a, ixl
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
	call	F_spectranext_page_in

	ld		de, WS_xfs_read_filename
	ld		bc, 139
	ldir

	ld		a, CMD_XFS_READ
	call	issue_out_poll
	jp		nz, generic_error

	ld		hl, (WS_xfs_read_bytes_read)
	ld		de, (WS_xfs_read_bytes_read + 2)
	jp		F_spectranext_success

generic_error:
	ex		af, af'
	call	POPPAGEB
	ex		af, af'
	scf
	ret

; CALLBAS ends with an absolute jump, leaving this part of the restart-vector
; reservation available for the shared GET_MESSAGE failure epilogue.
.section rst10
op_get_message_error:
	pop		hl
	jp		generic_error
