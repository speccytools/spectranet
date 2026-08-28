; Scratch state shared by the section-0 dot kernel and its page-B bridge.
; Input context occupies the unused DHCP sysvar tail. It must not live at
; $1E00: with page A = RAM $C0, that aliases the executable jump table at
; $3E00. The remaining private state starts in the unallocated $3C00 RAM
; window, seen through page A below.

; The kernel runs with RAM $C0 in page A while section 3 contains the DOT's
; D9 image. Translate permanent-RAM sysvar addresses to their page-A aliases.
DOT_ESX_A         equ v_dot_esx_a-0x2000
DOT_ESX_OP        equ v_dot_esx_op-0x2000
DOT_ESX_BC        equ v_dot_esx_bc-0x2000
DOT_ESX_DE        equ v_dot_esx_de-0x2000
DOT_ESX_HL        equ v_dot_esx_hl-0x2000
DOT_ESX_IX        equ v_dot_esx_ix-0x2000
DOT_ESX_CALL_IX   equ v_dot_esx_call_ix-0x2000
DOT_ESX_OUTPTR    equ v_dot_esx_outptr-0x2000
DOT_ESX_OUTLEN    equ v_dot_esx_outlen-0x2000
DOT_ESX_RETAF     equ 0x1C00
DOT_ESX_RETBC     equ 0x1C02
DOT_ESX_RETDE     equ 0x1C04
DOT_ESX_RETHL     equ 0x1C06
DOT_ESX_XFERPTR   equ 0x1C08
DOT_ESX_XFERLEFT  equ 0x1C0A
DOT_ESX_XFERDONE  equ 0x1C0C
DOT_ESX_XFERCHUNK equ 0x1C0E
DOT_DOT_ALT_HL    equ 0x1C10

; General pointer argument staging. This remains intentionally bounded because
; path-oriented VFS calls are allowed to use buf_workspace themselves.
DOT_ESX_WORKSPACE equ 0x1C20
DOT_ESX_WORKSIZE  equ 0xE0
DOT_ESX_RENAME_PATHSIZE equ DOT_ESX_WORKSIZE/2
DOT_ESX_RENAME_NEW equ DOT_ESX_WORKSPACE+DOT_ESX_RENAME_PATHSIZE

; The same physical RAM page is available through section 3 while the
; Spectranet module dispatcher runs. Use this alias for VFS-visible pointers:
; backends are free to page their private RAM into page A.
DOT_ESX_WORKSPACE_SECTION3 equ DOT_ESX_WORKSPACE+0x2000
DOT_ESX_RENAME_NEW_SECTION3 equ DOT_ESX_RENAME_NEW+0x2000

; READ/WRITE share the path window after the path operation has completed.
; $1C20-$1D1F is permanent RAM $3C20-$3D1F, below the jump table. A 256-byte
; chunk keeps the transfer arithmetic simple and never reaches $3E00.
DOT_ESX_XFER_WORKSPACE equ 0x1C20
DOT_ESX_XFER_WORKSIZE  equ 0x0100
DOT_ESX_XFER_WORKSPACE_SECTION3 equ DOT_ESX_XFER_WORKSPACE+0x2000
