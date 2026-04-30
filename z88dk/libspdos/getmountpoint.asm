; No Spectranet dispatch — same object linked into both libraries.
PUBLIC getmountpoint
.getmountpoint
	push	ix
	ld	hl, 0x3F6F
	ld	a, (hl)
	pop	ix
	ld	h, 0
	ld	l, a
	ret
