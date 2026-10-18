;The MIT License
;
;Copyright (c) 2009 Dylan Smith
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

; File/directory handle allocation in utility page 2. Only fixed RAM is
; accessed: input is in A/C, and descriptor pointers returned in HL remain
; valid after the page-zero F_resalloc gateway restores the caller's bank.
; Keep this implementation a leaf: do not map pages or call ROM modules.
.include "sysvars.inc"
.include "sysdefs.inc"
.include "sockdefs.inc"
.text
.globl F_resalloc_u_impl
F_resalloc_u_impl:
	bit 1, c
	jr nz, F_allocdirhnd
;--------------------------------------------------------------------------
; F_allocfd
; Allocates a file descriptor. 
; Parameters:	A = ROM number for the fd
; On return HL = address of fd. Functions that use this should set this
; to a value that means something (and bit 7 must be reset). L = actual
; fd number.
.globl F_allocfd
F_allocfd:
	bit 0, c
	jr z, F_freefd
	push bc
	ld hl, v_fd1hwsock	; lowest address in fd table
	ld b, MAX_FDS
.findloop13:
	bit 7, (hl)		; not allocated yet?
	jr nz, .alloc13
	inc l
	djnz .findloop13		; keep looking until none left
	scf			; out of free file descriptors
	pop bc
	ret
.alloc13:
	res 7, (hl)		; basic allocation
	push hl			; save FD address and FD number
	ld b, a			; save parameter
	ld a, l
	add a, VECOFFS		; find the address of the vector table
	ld l, a			; and make HL point to it
	ld a, b			; retrieve param
	ld (hl), a		; set vector table page address
	pop hl
	pop bc
	ret			; FD is returned in L, address in HL

;-------------------------------------------------------------------------
; F_freefd
; Frees the file descriptor passed in A.
.globl F_freefd
F_freefd:
	push hl
	push af
	ld h, v_fd1hwsock / 256
	ld l, a
	ld (hl), 0x80		; Set bit 7 to mark the fd as freed.
	add a, VECOFFS		; add the vector table offset
	ld l, a			; and point HL to it
	ld (hl), 0x00		; clear it down
	pop af
	pop hl
	ret

;------------------------------------------------------------------------
; F_allocdirhnd
; Allocates a directory handle.
; Parameters	A = ROM number for the handle
; On return HL = address of the handle, L is the handle itself
.globl F_allocdirhnd
F_allocdirhnd:
	bit 0, c
	jr z, F_freedirhnd
	push bc
	ld hl, v_dhnd1page
	ld b, MAX_DIRHNDS
	ex af, af'
.findloop15:
	ld a, (hl)
	and a			; 0 = free
	jr z, .alloc15
	inc l
	djnz .findloop15
	scf			; all are used up
	pop bc
	ret
.alloc15:
	ex af, af'
	ld (hl), a		; allocate it by setting the page number
	pop bc
	ret

;-----------------------------------------------------------------------
; F_freedirhnd
; Frees the directory handle passed in A
.globl F_freedirhnd
F_freedirhnd:
	push hl
	ld h, v_dhnd1page / 256
	ld l, a
	ld (hl), 0
	pop hl
	ret
