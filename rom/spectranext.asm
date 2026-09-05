; Page-zero gateway for executable Spectranext controller page $48.
.include "spectranet.inc"

CONTROLLER_PAGE	equ 0x48
SPXCONTROLLER_ENTRY	equ 0x2000

.text
.globl F_spectranext_op
F_spectranext_op:
	ex af, af'
	ld a, CONTROLLER_PAGE
	call F_pushpageB
	ex af, af'
	call SPXCONTROLLER_ENTRY
	ex af, af'
	call F_poppageB
	ex af, af'
	ret

; F_dnsAquery retains this public page-zero entry point.
.globl F_spectranext_dns
F_spectranext_dns:
	ld a, CMD_DNS
	jp F_spectranext_op
