;The MIT License
;
;Copyright (c) 2008 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.
;
; Functions for querying DNS.
;
.include	"sysvars.inc"
.include	"dnsdefs.inc"
.include	"w5100_defs.inc"	
.include	"sockdefs.inc"

;========================================================================
; F_gethostbyname
; Subset of the Unix 'gethostbyname' call. It returns only a list of
; addresses (currently, either zero or one entries long). The parameter
; can either be an IP address in dotted decimal format, or a hostname.
; No lookup is performed if an IP address is detected; the address is
; simply converted to a 4-byte big endian representation of the address.
; Carry flag is set on error, and A contains the return code when an
; error occurs.
; 
; Parameters: HL = pointer to null-terminated string containing address
;             DE = pointer to a buffer in which to return the result
.text
.globl F_gethostbyname
F_gethostbyname:
	push hl
	push de
	call F_ipstring2long	; Was a dotted decimal IP address passed?
	pop de
	pop hl
	ld a, 0			; ensure status is 0 (flags unchanged)
	ret nc			; was an IP - so it's now in the buffer.
	call F_dnsAquery	; no - so try a DNS lookup instead.
	ret

;========================================================================
; F_dnsAquery
; Queries a DNS server for an A record, using the servers enumerated
; in system variables v_nameserver1 and v_nameserver2
;
; Parameters: HL = pointer to null-terminated string containing address
;                  to query
;             DE = pointer to a 4 byte buffer in which to return result
; Returns   : A  = Status (carry is set on error)
;
.globl F_dnsAquery
F_dnsAquery:
	jp F_spectranext_dns
