; DivMMC-safe interception of the 48K ROM LD-BYTES prologue.
;
; In Spectranet+DivMMC mode the paging hardware exposes the JP at $055C.
; Its two operand reads consume $055D-$055E; neither the classic $0562
; DivMMC tape entry nor the Next's additional $056A entry is fetched on M1.
; This replaces the 48K ROM's OUT ($FE),A at $055C. Skipping that OUT changes
; the border/MIC output but not the CPU state needed by LD-BYTES.

.include "sysdefs.inc"
.include "sysvars.inc"
.include "spectranet.inc"

.section ldtrap
    jp J_ldbytes_direct

.text
.globl J_ldbytes_direct
.globl NMI2
J_ldbytes_direct:
    ; Reproduce the stock ROM from $055E through the trap at $0562.
    ld hl, 0x053F
    push hl
    in a, (0xFE)

    ; The control-register bit remains software-visible in dual mode even
    ; though the hardware/emulator programmable NMI trap itself is suppressed.
    ; Only the known $0562/$0564 LD-BYTES trap is dispatched here.
    push af
    push bc
    ld bc, CTRLREG
    in a, (c)
    and MASK_PROGTRAP_EN
    pop bc
    jr z, .physical_tape
    ld a, (v_trapcomefrom)
    cp 0x64
    jr nz, .physical_tape
    ld a, (v_trapcomefrom+1)
    cp 0x05
    jr nz, .physical_tape

    pop af

    ; Construct exactly the original stack shape: the real NMI would have
    ; pushed $0564 above LD-BYTES' existing $053F return address.
    push hl
    ld hl, 0x0564
    ex (sp), hl
    ld (NMISTACK), sp
    ld sp, NMISTACK-8
    push hl
    push de
    push bc
    push af
    ex af, af'
    push af
    ld hl, (NMISTACK)
    jp NMI2

.physical_tape:
    pop af

    ; No Spectranet tape redirect is armed. Reproduce $0564-$056A as well,
    ; then re-enter the host ROM after both DivMMC tape automap addresses.
    rra
    and 0x20
    or 0x02
    ld c, a
    cp a
    push hl
    ld hl, 0x056B
    ex (sp), hl
    jp PAGEOUT
