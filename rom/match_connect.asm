; Page-2 implementation of the public F_connect socket operation.
;
; The page-zero gateway in w5100_sockctrl.asm resolves the hardware socket,
; maps this ROM page and later restores it. This routine either performs a
; conventional W5100 CONNECT or invokes the blocking matchmaking UI for the
; synthetic destination 198.18.0.1 (SPX_MATCH_IP in common/match_layout.h).
;
; Entry: H = socket-register page MSB (0x14..0x17), DE -> four IPv4 octets,
;        BC = destination port in host register order (B high, C low).
; Exit:  A=0/carry clear on success; A=error/carry set on failure.
;        Other working registers may be clobbered. The matchmaking branch
;        restores the caller's interrupt-enable state and Spectrum paging.
;
.include "spectranet.inc"
.include "sysvars.inc"
.include "w5100_defs.inc"
.include "sockdefs.inc"
.text
.globl F_connect_impl
; Probe the marker byte by byte, saving the original DE and HL because a
; mismatch at any octet must resume ordinary CONNECT with intact arguments.
F_connect_impl:
    push hl
    push de
    ld a, (de)
    cp 198
    jr nz, normal_connect
    inc de
    ld a, (de)
    cp 18
    jr nz, normal_connect
    inc de
    ld a, (de)
    or a
    jr nz, normal_connect
    inc de
    ld a, (de)
    cp 1
    jr nz, normal_connect
    pop de
    pop hl
    ; Convert the register-page MSB to the controller's socket index 0..3.
    ; Save it outside registers before machine/paging detection clobbers them.
    ld a, h
    sub 0x14
    ld (buf_workspace+127), a
    ; Save IFF2 in P/V and disable interrupts throughout paging and the UI.
    ; Detection records machine type and the paging value to restore later.
    ld a, i
    push af
    di
    call F_detectpages
    ld a, (v_machinetype)
    cp 1
    jr nz, match_enter_module
    ld a, (v_port7ffd)
    ; On a detected 128K machine force the normal screen (bank 5 at 0x4000)
    ; while the UI uses it; keep the original screen bit in v_port7ffd.
    res 3, a
    ld bc, 0x7FFD
    out (c), a
; MODULECALL_NOPAGE takes H=module ID F0, L=entry selector 0 and A=socket
; index. The UI/controller finish connection setup before returning; do not
; issue a second W5100 CONNECT after a successful matchmaking result.
match_enter_module:
    ld a, (buf_workspace+127)
    ld hl, 0xf000
    rst MODULECALL_NOPAGE
    ; Keep module result AF on the stack while restoring Spectrum paging.
    ; Then hold that result in BC while recovering the saved IFF flags.
    push af
    ld a, (v_port7ffd)
    ld bc, 0x7FFD
    out (c), a
    pop bc
    pop af
    ; Test the caller's saved IFF2, then restore the module's result flags.
    ; EI takes effect after RET, once control has left this implementation.
    jp po, match_return_disabled
    push bc
    pop af
    ei
    ret
match_return_disabled:
    push bc
    pop af
    ret
; Ordinary destination: restore the arguments saved before the marker probe.
; Program destination port/address and allocate the next local source port.
; LDI leaves DE in the socket register page, so the later EX DE,HL recovers
; that page before selecting the command and interrupt registers.
normal_connect:
    pop de
    pop hl
	ld l, Sn_DPORT0 % 256	; destination port register
	ld (hl), b		; high order of port
	inc l
	ld (hl), c		; low order of port
	ld l, Sn_DIPR0 % 256	; destination IP address register
	ex de, hl		; passed buffer value now in hl
	ldi
	ldi
	ldi
	ldi
    ; v_localport is little endian in RAM; W5100 port registers are big
    ; endian, so copy the low byte to PORT1 and the high byte to PORT0.
	ld hl, v_localport
	ld e, Sn_PORT1 % 256	; set local port LSB
	ldi
	ld e, Sn_PORT0 % 256	; set local port MSB
	ldi
	ld hl, (v_localport)	; update the local port number
	inc hl
	ld (v_localport), hl

	ex de, hl
	ld l, Sn_CR % 256	; command register
	ld (hl), S_CR_CONNECT	; instruction to connect to remote host

	ld l, Sn_IR % 256	; interrupt register
; Poll interrupt flags until connection completion or an error. Completion
; takes precedence; DISCON maps to refusal and any other nonzero flags map
; to timeout. There is no software deadline in this polling loop.
.waitforconn3:
	ld a, (hl)
	bit BIT_IR_CON, a
	jr nz, .connected3
	and a			; if not, is it zero (no flags set?)
	jr z, .waitforconn3
	and S_IR_DISCON		; connection refused?
	jr nz, .refused3
	ld a, ETIMEDOUT		; connection timed out
	scf
	ret
.refused3:
	ld a, ECONNREFUSED
	scf
	ret
; W5100 interrupt bits are write-one-to-clear. Acknowledge CON, then XOR A
; returns both a zero status and carry clear to the page-zero gateway.
.connected3:
	set BIT_IR_CON, (hl)	; reset interrupt bit
	xor a			; connection OK
	ret
