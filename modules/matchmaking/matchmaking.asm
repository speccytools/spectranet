; Blocking Spectranext matchmaking presentation module, ID F0.
; Controller owns discovery, pairing, transport and persistent settings.
;
; Called synchronously by the ROM CONNECT path for the synthetic matchmaking
; address. The controller drives the network state machine; this module polls
; snapshots, displays peers and sends user actions. No transport runs here.
;
; Entry: A = W5100 socket index (0..3), not a Spectranet file descriptor.
; Exit:  A = 0, carry clear on connection; A = 0xFC, carry set on cancel/error.
;        IX, IY, page A and the caller's interrupt-enable state are restored.
;        The visible screen, border and AY channel volumes are restored too.
;
; Request/snapshot byte offsets must match common/match_layout.h. Multi-byte
; fields are little endian. Commands 16..20 are MATCH, GET_PEER, CONNECT,
; SET_NAME and CODE respectively. Each command replaces the mailbox contents.
.include "spectranet.inc"
.include "sysvars.inc"
.include "page1.xinc"
; Private workspace remains mapped while page A is switched for controller
; commands or keyboard helpers. Module instructions live in page B.
; SNAP: 220-byte reply; REQ: 29-byte request. Request offsets are socket +0,
; action +1, peer slot +2, revision +3 (16-bit), text +5 (24 bytes).
SNAP equ 0x3900
REQ equ 0x3B00
; UI state: EDIT = 0 (peer list), 1 (name), 2 (joining code).
; SLOT is zero based; LENGTH excludes the terminating NUL; LASTKEY suppresses
; repeated actions until the key changes or all keys are released.
SOCK equ 0x3BE0
EDIT equ 0x3BE1
SLOT equ 0x3BE2
LENGTH equ 0x3BE3
LASTKEY equ 0x3BE4
BORDER equ 0x3BE5
VOLUME equ 0x3BE6
CODE_PENDING equ 0x3BE9
; Additional scratch locations used directly below:
; 0x3B20..0x3BA1 = last drawn snapshot prefix (bytes before the peer record).
; 0x3BB0..0x3BC7 = peer name frozen while entering a joining code.
; 0x3BEC = last drawn EDIT; 0x3BED = force redraw.
; SELECT_REV freezes the peer-table revision alongside SLOT during code entry.
ROW_INDEX equ 0x3BEA
SELECT_REV equ 0x3BEE
; Local asynchronous mailbox state. Borrow the BASIC extension table at
; 0x3A00 and scratch buffer at 0x3D00, saving/restoring both with the screen.
; Never touch the init marker at 0x3C18 or public jump table at 0x3E00.
; Each cache holds nine
; (present, name[24], requires_code) rows without exposing half-refreshed tables.
ACTIVE_CMD equ 0x3BF0
QUEUED_CMD equ 0x3BF1
FETCH_INDEX equ 0x3BF2
CACHE_COUNT equ 0x3BF3
CACHE_REV equ 0x3BF4
FETCH_COUNT equ 0x3BF6
FETCH_REV equ 0x3BF7
LOCAL_CONNECT equ 0x3BF9
CANCEL_PENDING equ 0x3BFA
WANT_CODE equ 0x3BFB
CACHE_VALID equ 0x3BFC
DONE_CMD equ 0x3BFD
KEY_HEAD equ 0x3BFE
KEY_COUNT equ 0x3BFF
KEY_BUFFER equ 0x3AF0
DISPLAY_PEERS equ 0x3A00
STAGED_PEERS equ 0x3D00
; Snapshot starts with stage, peer-slot count, then 16-bit table revision.
; Stage: 0 preparing, 1 waiting, 2 connecting, 3 connected, 4 cancelled, 5 error.
; Count is the highest occupied slot plus one; unused slots can occur within it.
REV equ SNAP+2
NAME equ SNAP+4
CODE equ SNAP+28
SERVICE equ SNAP+33
ERROR equ SNAP+98
; The peer record contains device ID[65], display name[24], requires_code.
; An empty device ID marks an unused slot. GET_PEER supplies the indexed record;
; other commands supply the currently selected peer.
PEER equ SNAP+130
PEERNAME equ SNAP+195
PEERCODE equ SNAP+219
SNAPSIZE equ 220
; Standard module header: signature, module ID F0, unused lifecycle vectors,
; identification string and the module-call entry jump.
.section vectors
    defb 0xAA, 0xF0
    defw 0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF,0xFFFF
    defw ident
    jp entry
.text
; Save caller state before taking over the display. The application CONNECT
; remains blocking; only the module's mailbox exchanges are asynchronous.
entry:
    push ix
    push iy
    ld (SOCK), a
    ld a, i
    push af
    di
    ; CONNECT dispatches directly from page zero. Own all display preparation
    ; here, including detection/restoration of the Spectrum's screen RAM bank.
    call F_detectpages
    ld a, (v_machinetype)
    cp 1
    jr nz, entry_screen_ready
    ld a, (v_port7ffd)
    res 3, a
    ld bc, 0x7FFD
    out (c), a
entry_screen_ready:
    ld hl, SNAP
    ld de, SNAP+1
    ld bc, SNAPSIZE-1
    ld (hl), 0
    ldir
    ld hl, ACTIVE_CMD
    ld de, ACTIVE_CMD+1
    ld bc, 15
    ld (hl), 0
    ldir
    xor a
    ld (EDIT), a
    ld (LASTKEY), a
    ld (CODE_PENDING), a
    ld a, 255
    ld (FETCH_INDEX), a
    inc a
    ld (SERVICE), a
    ld a, 1
    ld (0x3BED), a
    ld a, (v_pga)
    push af
    call save_screen
    call mute
    call KEYUP
; Collect a finished reply without waiting. The keyboard is scanned even
; while STUN/HTTP is running. REQ is private: a queued action can be edited
; while the previous request/reply occupies the controller mailbox.
loop:
    call command_poll
    jp nc, check_redraw
    ld a, (SNAP)
    cp 5
    jp z, failed
    cp 4
    jp z, cancelled
    ld a, (CANCEL_PENDING)
    or a
    jp nz, check_redraw
    ld a, (SNAP)
    cp 3
    jp z, success
    ld a, (DONE_CMD)
    cp 17
    jp z, fetched_peer
    ld a, (SNAP)
    cp 2
    jr nz, action_reply
    xor a
    ld (EDIT), a
    ld (LOCAL_CONNECT), a
    ld (QUEUED_CMD), a
    ld (CODE_PENDING), a
    ld a, 255
    ld (FETCH_INDEX), a
    jp check_redraw
action_reply:
    ld a, (DONE_CMD)
    cp 19
    jr nz, connect_reply
    ld a, (ERROR)
    cp 'N'
    jp z, retry_name
    xor a
    ld (EDIT), a
connect_reply:
    ld a, (DONE_CMD)
    cp 18
    jr nz, refresh_cache
    xor a
    ld (LOCAL_CONNECT), a
    ld a, (EDIT)
    cp 2
    jr nz, refresh_cache
    ld a, (ERROR)
    or a
    jr z, close_editor
    cp 'P'
    jp nz, retry_editor
close_editor:
    xor a
    ld (EDIT), a
; Fetch table changes into a separate small staging cache. Publish all rows
; together, so the visible names and their revision always describe one table.
refresh_cache:
    ld a, (CACHE_VALID)
    or a
    jr z, begin_fetch
    ld hl, (REV)
    ld de, (CACHE_REV)
    or a
    sbc hl, de
    jp z, check_redraw
begin_fetch:
    ld hl, (REV)
    ld (FETCH_REV), hl
    ld a, (SNAP+1)
    ld (FETCH_COUNT), a
    xor a
    ld (FETCH_INDEX), a
    ld hl, STAGED_PEERS
    ld de, STAGED_PEERS+1
    ld bc, 233
    ld (hl), a
    ldir
    ld a, (FETCH_COUNT)
    or a
    jp nz, check_redraw
    jr publish_peers
fetched_peer:
    ld a, (FETCH_INDEX)
    ld hl, STAGED_PEERS
    call peer_pointer
    ld a, (PEER)
    ld (hl), a
    inc hl
    ex de, hl
    ld hl, PEERNAME
    ld bc, 24
    ldir
    ld a, (PEERCODE)
    ld (de), a
    ld hl, FETCH_INDEX
    inc (hl)
    ld a, (FETCH_COUNT)
    cp (hl)
    jp nz, check_redraw
publish_peers:
    ld hl, STAGED_PEERS
    ld de, DISPLAY_PEERS
    ld bc, 234
    ldir
    ld hl, (FETCH_REV)
    ld (CACHE_REV), hl
    ld a, (FETCH_COUNT)
    ld (CACHE_COUNT), a
    ld a, 255
    ld (FETCH_INDEX), a
    ld a, 1
    ld (CACHE_VALID), a
    ld (0x3BED), a
; Redraw only for changed state or a local action. draw reads cached rows;
; it never sends commands or waits for the controller.
check_redraw:
    ld a, (0x3BED)
    or a
    jr nz, redraw
    ld a, (EDIT)
    ld hl, 0x3BEC
    cp (hl)
    jr nz, redraw
    ld hl, SNAP
    ld de, 0x3B20
    ld b, 130
compare_snapshot:
    ld a, (de)
    cp (hl)
    jr nz, redraw
    inc de
    inc hl
    djnz compare_snapshot
    jr read_key
redraw:
    call draw
    ld hl, SNAP
    ld de, 0x3B20
    ld bc, 130
    ldir
    ld a, (EDIT)
    ld (0x3BEC), a
    xor a
    ld (0x3BED), a
read_key:
    call next_key
    or a
    jp z, service_command
    ld b, a
    ld a, (CANCEL_PENDING)
    or a
    jp nz, service_command
    ld a, b
    cp 13
    jp z, enter_key
    ld a, (SNAP)
    cp 2
    jp z, service_command
    ld a, (LOCAL_CONNECT)
    or a
    jp nz, service_command
    ld a, b
    cp 'c'
    jp z, toggle_code
    cp 'C'
    jp z, toggle_code
    ; One pending action owns REQ. Do not overwrite a staged name/selection.
    ld a, (QUEUED_CMD)
    or a
    jp nz, service_command
    ld a, b
    cp 'n'
    jp z, change_name
    cp 'N'
    jp z, change_name
    sub '1'
    cp 9
    jp nc, service_command
    ld (SLOT), a
    ld b, a
    ld a, (CACHE_COUNT)
    cp b
    jp z, service_command
    jp c, service_command
    ld a, (CACHE_VALID)
    or a
    jp z, service_command
    ld a, b
    ld hl, DISPLAY_PEERS
    call peer_pointer
    ld a, (hl)
    or a
    jp z, service_command
    inc hl
    ld de, 0x3BB0
    ld bc, 24
    ldir
    ld a, (hl)
    push af
    ld hl, (CACHE_REV)
    ld (SELECT_REV), hl
    call request_init
    xor a
    ld (REQ+5), a
    pop af
    or a
    jp nz, code_edit
    xor a
    ld (EDIT), a
    call select_peer
    jp service_command
change_name:
    call request_init
retry_name:
    ld a, 1
    jr start_edit
code_edit:
    ld a, 2
start_edit:
    ld (EDIT), a
retry_editor:
    xor a
    ld (LENGTH), a
    ld (REQ+5), a
    call draw
; The standard blocking editor remains unchanged. An in-flight response
; stays in the mailbox until input finishes; it cannot overwrite REQ or SNAP.
read_editor:
    ld bc, 0x0607
    call position
    ld de, REQ+5
    ld c, 24
    ld a, (EDIT)
    cp 2
    jr nz, read_system_input
    ld c, 5
read_system_input:
    call INPUTSTRING
    ; Do not replay the editor's terminating ENTER as a menu cancellation.
    ld a, 13
    ld (LASTKEY), a
    ld a, (v_stringlen+1)
    ld b, a
    ld a, (v_stringlen)
    ld c, a
    ld a, b
    sub c
    ld (LENGTH), a
    ld a, (EDIT)
    cp 1
    jp z, save_name
    jp submit_code
; Remember the desired setting across repeated C presses, including a
; second toggle while the first is in flight. The real generated code is
; displayed only after its controller reply, never invented by the module.
toggle_code:
    ld a, (WANT_CODE)
    xor 1
    ld (WANT_CODE), a
    ld a, 1
    ld (CODE_PENDING), a
    ld (0x3BED), a
    jp service_command

enter_key:
    call request_init
    ld a, 2
    ld (REQ+1), a
    ld a, 1
    ld (CANCEL_PENDING), a
    ld a, 16
    jp queue_action
save_name:
    xor a
    ld (EDIT), a
    ld a, 19
    jp queue_action
submit_code:
    ld a, (LENGTH)
    or a
    jp z, end_edit
    cp 4
    jr nz, invalid_code
    ld hl, REQ+5
    ld b, 4
check_code_digit:
    ld a, (hl)
    cp '0'
    jr c, invalid_code
    cp '9'+1
    jr nc, invalid_code
    inc hl
    djnz check_code_digit
    call select_peer
    jp service_command
invalid_code:
    ld hl, digits_text
    ld de, ERROR
    ld bc, 23
    ldir
    jp retry_editor
end_edit:
    xor a
    ld (EDIT), a
    inc a
    ld (0x3BED), a
    jp service_command
; Freeze the visible row's revision before any refresh result is collected.
; The controller rejects a stale selection rather than choosing another peer.
select_peer:
    ld a, (SLOT)
    ld (REQ+2), a
    ld hl, (SELECT_REV)
    ld (REQ+3), hl
    ld a, 1
    ld (LOCAL_CONNECT), a
    ld a, 18
    ld (QUEUED_CMD), a
    ld a, 1
    ld (0x3BED), a
    ret
queue_action:
    ld (QUEUED_CMD), a
    ld a, 1
    ld (0x3BED), a
; Never overwrite an in-flight mailbox. User actions take priority over
; fetching table rows or starting another discovery refresh.
service_command:
    ld a, (ACTIVE_CMD)
    or a
    jp nz, loop
    ld a, (QUEUED_CMD)
    or a
    jr z, service_fetch
    ld b, a
    xor a
    ld (QUEUED_CMD), a
    ld a, b
    call command_start
    jp loop
service_fetch:
    ; Code toggles are a separate desired-state flag, leaving REQ free for
    ; an immediate name editor or selection while a refresh is in flight.
    ld a, (CODE_PENDING)
    or a
    jr z, service_peer_fetch
    xor a
    ld (CODE_PENDING), a
    call request_init
    ld a, (WANT_CODE)
    ld (REQ+1), a
    ld a, 20
    call command_start
    jp loop
service_peer_fetch:
    ld a, (FETCH_INDEX)
    cp 255
    jr z, service_refresh
    ld (REQ+2), a
    call request_init
    ld hl, (FETCH_REV)
    ld (REQ+3), hl
    ld a, 17
    call command_start
    jp loop
service_refresh:
    call request_init
    ld a, 16
    call command_start
    jp loop
request_init:
    ld a, (SOCK)
    ld (REQ), a
    xor a
    ld (REQ+1), a
    ld hl, (REV)
    ld (REQ+3), hl
    ret
; In: A=row 0..8, HL=cache base. Out: HL=26-byte row (present, name[24], code).
peer_pointer:
    or a
    ret z
    ld de, 26
peer_pointer_loop:
    add hl, de
    dec a
    jr nz, peer_pointer_loop
    ret
; Start a command, restoring page A immediately. REQ can be reused once its
; bytes have been copied. Caller guarantees ACTIVE_CMD=0 before entering.
command_start:
    ld (ACTIVE_CMD), a
    ld a, 0x48
    call PUSHPAGEA
    ld hl, REQ
    ld de, 0x1800
    ld bc, 29
    ldir
    ld a, 255
    ld (0x1FFF), a
    ld a, (ACTIVE_CMD)
    ld (0x1FFE), a
    call POPPAGEA
    ret
; Return carry set only when a complete reply was copied into SNAP. Busy
; returns immediately with carry clear. No keyboard press is hidden by a
; controller/network wait, and page A is restored before every return.
command_poll:
    ld a, (ACTIVE_CMD)
    or a
    ret z
    ld a, 0x48
    call PUSHPAGEA
    ld a, (0x1FFF)
    inc a
    jr nz, command_finished
    call POPPAGEA
    or a
    ret
command_finished:
    dec a
    or a
    jr nz, controller_error
    ld hl, 0x1800
    ld de, SNAP
    ld bc, SNAPSIZE
    ldir
    jr command_collected
controller_error:
    ld hl, SNAP
    ld de, SNAP+1
    ld bc, SNAPSIZE-1
    ld (hl), 0
    ldir
    ld a, 5
    ld (SNAP), a
command_collected:
    call POPPAGEA
    ld a, (ACTIVE_CMD)
    ld (DONE_CMD), a
    xor a
    ld (ACTIVE_CMD), a
    scf
    ret
; Poll ROM page-1 keyboard helpers without changing the module's page B.
; Return a decoded key once per change; a release resets LASTKEY. C carries
; the result across POPPAGEA. This helper does not wait for a key press.
key:
    ld a, 1
    call PUSHPAGEA
    call F_key_scan
    call F_key_test
    jr nc, released
    ld e, a
    ld d, 8
    ld c, 0
    call F_key_code
    ld c, a
    ld a, (LASTKEY)
    cp c
    jr z, same_key
    ld a, c
    ld (LASTKEY), a
    jr key_done
released:
    xor a
    ld (LASTKEY), a
same_key:
    xor a
key_done:
    ld c, a
    call POPPAGEA
    ld a, c
    ret
; Position PRINT42 using the renderer's framebuffer pointer, not a line advance.
position:
    ; B=row, C=column
    push hl
    ld a, c
    ld (v_column), a
    ; Convert character row to Spectrum bitmap address: low three row bits
    ; select bits 5..7 of L; row bits 3..4 select the 0x4000/0x4800/0x5000 band.
    ld a, b
    and 7
    rrca
    rrca
    rrca
    ld l, a
    ld a, b
    and 24
    or 0x40
    ld h, a
    ld (v_row), hl
    pop hl
    ret
; In: B=row, C=42-column text column, HL=NUL-terminated text.
; position preserves HL; PRINT42 advances the renderer cursor.
print:
    call position
    jp text
; Buffer key edges while drawing, between short blocks/characters. The
; standard editor owns input exclusively whenever EDIT is nonzero.
capture_key:
    push af
    ld a, (EDIT)
    or a
    jr nz, capture_done
    push bc
    push de
    push hl
    call key
    or a
    jr z, capture_restore
    ld e, a
    ld a, (KEY_COUNT)
    cp 16
    jr nc, capture_restore
    ld b, a
    ld a, (KEY_HEAD)
    add a, b
    and 15
    ld c, a
    ld b, 0
    ld hl, KEY_BUFFER
    add hl, bc
    ld (hl), e
    ld hl, KEY_COUNT
    inc (hl)
capture_restore:
    pop hl
    pop de
    pop bc
capture_done:
    pop af
    ret
next_key:
    ld a, (KEY_COUNT)
    or a
    jp z, key
    dec a
    ld (KEY_COUNT), a
    ld a, (KEY_HEAD)
    ld c, a
    inc a
    and 15
    ld (KEY_HEAD), a
    ld b, 0
    ld hl, KEY_BUFFER
    add hl, bc
    ld a, (hl)
    ret
; Same 42-column renderer, with a keyboard scan between characters.
putchar:
    call PUTCHAR42
    jp capture_key
text:
    ld a, (hl)
    or a
    ret z
    call putchar
    inc hl
    jr text
; Match CLEAR42's display and cursor state, scanning every 256 bytes.
clear_screen:
    ld a, 1
    out (254), a
    ld hl, 0x4000
    ld b, 24
clear_bitmap:
    push bc
    xor a
    call clear_block
    pop bc
    djnz clear_bitmap
    ld b, 3
clear_attributes:
    push bc
    ld a, 15
    call clear_block
    pop bc
    djnz clear_attributes
    xor a
    ld (v_column), a
    ld (v_rowcount), a
    ld hl, 0x4000
    ld (v_row), hl
    ret
clear_block:
    ld (hl), a
    ld d, h
    ld e, l
    inc de
    ld bc, 255
    ldir
    inc hl
    jp capture_key
; Rebuild from the last snapshot and published peer cache; never wait here.
draw:
    call clear_screen
    ld hl, 0x5800
    ld b, 32
title_attr:
    ld (hl), 57
    inc hl
    djnz title_attr
    ld bc, 1
    ld hl, title
    call print
    ld hl, SERVICE
    ld b, 12
service_title:
    ld a, (hl)
    or a
    jr z, end_title
    call putchar
    inc hl
    djnz service_title
end_title:
    ld a, '"'
    call putchar
    ld a, (CANCEL_PENDING)
    or a
    jp nz, draw_cancelled
    ld a, (SNAP)
    cp 3
    jp nc, draw_transition
    ld a, (LOCAL_CONNECT)
    or a
    jp nz, draw_connecting
    ld a, (EDIT)
    or a
    jp nz, draw_editor
    ld a, (SNAP)
    cp 2
    jp z, draw_connecting
    ld bc, 0x0101
    ld hl, waiting
    ld a, (SNAP)
    or a
    jr nz, waiting_text
    ld hl, preparing
waiting_text:
    call print
    call own_name
    ld bc, 0x0401
    ld hl, available
    call print
    ld bc, 0x041D
    ld hl, access
    call print
    xor a
    ld (ROW_INDEX), a
; Rendering never touches the mailbox. All rows belong to CACHE_REV.
peer_rows:
    ld a, (ROW_INDEX)
    ld b, a
    ld a, (CACHE_COUNT)
    cp b
    jr z, peers_done
    ld a, b
    ld hl, DISPLAY_PEERS
    call peer_pointer
    ld a, (hl)
    or a
    jr z, next_peer
    inc hl
    push hl
    ld a, (ROW_INDEX)
    add a, 6
    ld b, a
    ld c, 1
    call position
    ld a, '['
    call putchar
    ld a, (ROW_INDEX)
    add a, '1'
    call putchar
    ld a, ']'
    call putchar
    ld a, ' '
    call putchar
    pop hl
    push hl
    call text
    pop hl
    ld de, 24
    add hl, de
    ld a, (hl)
    push af
    ld a, (ROW_INDEX)
    add a, 6
    ld b, a
    ld c, 29
    ld hl, open_text
    pop af
    or a
    jr z, peer_access
    ld hl, code_text
peer_access:
    call print
next_peer:
    ld hl, ROW_INDEX
    inc (hl)
    jr peer_rows
peers_done:
    ld a, (CACHE_COUNT)
    or a
    jr nz, code_line
    ld bc, 0x0601
    ld hl, empty
    call print
; Bottom rows show our code requirement, context-sensitive number-key help,
; global actions and the latest controller error.
code_line:
    ld bc, 0x1501
    ld hl, require
    call print
    ld a, (CODE_PENDING)
    or a
    jr nz, show_code_pending
    ld a, (ACTIVE_CMD)
    cp 20
    jr z, show_code_pending
    ld a, (CODE)
    or a
    jr z, show_off
    ld hl, on_text
    call text
    ld hl, CODE
    call text
    ld a, '>'
    call putchar
    jr legend
show_code_pending:
    ld hl, updating_text
    call text
    jr legend
show_off:
    ld hl, off_text
    call text
legend:
    ld bc, 0x1601
    call position
    ld a, (CACHE_COUNT)
    or a
    jr z, empty_legend
    push af
    ld hl, legend_prefix
    call text
    pop af
    cp 1
    jr z, legend_suffix
    push af
    ld a, '-'
    call putchar
    pop af
    add a, '0'
    call putchar
legend_suffix:
    ld hl, legend1
    call text
    jr bottom_legend
empty_legend:
    ld hl, waiting_legend
    call text
bottom_legend:
    ld bc, 0x1701
    ld hl, legend2
    call print
    ld bc, 0x1401
    ld hl, ERROR
    ld a, (QUEUED_CMD)
    cp 19
    jr z, saving_name
    ld a, (ACTIVE_CMD)
    cp 19
    jr nz, status_text
saving_name:
    ld hl, saving_text
status_text:
    jp print
; Shared name line for the waiting screen; NAME includes its terminating NUL.
own_name:
    ld bc, 0x0201
    ld hl, your_name
    call print
    ld hl, NAME
    jp text
; Pairing has selected a peer; show both identities and only the cancel key.
draw_connecting:
    ld bc, 0x0101
    ld hl, your_name
    call print
    ld hl, NAME
    call text
    ld bc, 0x0201
    ld hl, peer_text
    call print
    ld hl, PEERNAME
    ld a, (LOCAL_CONNECT)
    or a
    jr z, connecting_name
    ld hl, 0x3BB0
connecting_name:
    call text
    ld bc, 0x0401
    ld hl, connecting
    call print
    ld bc, 0x1701
    ld hl, cancel_text
    jp print
; A is the EDIT mode supplied by draw. Preserve it across name rendering
; before choosing name input or the frozen peer/code prompt.
draw_editor:
    push af
    ld bc, 0x0101
    ld hl, your_name
    call print
    ld hl, NAME
    call text
    pop af
    cp 2
    jr z, draw_code
    ld bc, 0x0301
    ld hl, change1
    call print
    ld bc, 0x0401
    ld hl, change2
    call print
    ld bc, 0x0601
    ld hl, name_prompt
    call print
    ld bc, 0x1701
    ld hl, save_text
    call print
    ld bc, 0x0801
    ld hl, ERROR
    call print
    jr draw_value
draw_code:
    ld bc, 0x0201
    ld hl, peer_text
    call print
    ld hl, 0x3BB0
    call text
    ld bc, 0x0401
    ld hl, requires
    call print
    ld bc, 0x0601
    ld hl, code_prompt
    call print
    ld bc, 0x0701
    ld hl, ERROR
    call print
    ld bc, 0x1601
    ld hl, join_text
    call print
    ld bc, 0x1701
    ld hl, back_text
    call print
; Display the current staged text at the same position used by INPUTSTRING.
draw_value:
    ld b, 6
    ld c, 7
    call position
    ld hl, REQ+5
    jp text
; Terminal-stage presentation. Success/error include the selected peer;
; cancellation has no peer line. Error acknowledgement is handled by failed.
draw_transition:
    ld bc, 0x0101
    ld hl, your_name
    call print
    ld hl, NAME
    call text
    ld a, (SNAP)
    cp 3
    jr z, transition_peer
    cp 5
    jr nz, draw_cancelled
transition_peer:
    ld bc, 0x0201
    ld hl, peer_text
    call print
    ld hl, PEERNAME
    call text
    ld a, (SNAP)
    cp 5
    jr z, draw_failed
    ld bc, 0x0401
    ld hl, connected_text
    call print
    ld bc, 0x0501
    jr draw_returning
draw_failed:
    ld bc, 0x0401
    ld hl, failed_text
    call print
    ld bc, 0x0501
    ld hl, ERROR
    call print
    ld bc, 0x1701
    ld hl, failure_back
    jp print
draw_cancelled:
    ld bc, 0x0301
    ld hl, cancelled_text
    call print
    ld bc, 0x0401
draw_returning:
    ld hl, returning_text
    jp print
; Brief busy-wait so success/cancellation is visible before restoring the
; application. Do not use HALT: this module runs with interrupts disabled.
transition_delay:
    ld hl, 0x1000
transition_wait:
    dec hl
    ld a, h
    or l
    jr nz, transition_wait
    ret

; Save all 6912 display bytes (6144 bitmap + 768 attributes) into scratch
; pages DA/DB, split at the 4 KiB page-A window boundary. Save the border
; colour reported by CTRLREG; the entry page mapping is saved on the stack.
save_screen:
    ld bc, CTRLREG
    in a, (c)
    and 7
    ld (BORDER), a
    ld a, 0xDA
    call SETPAGEA
    ld hl, 0x4000
    ld de, 0x1000
    ld bc, 0x1000
    ldir
    ld a, 0xDB
    call SETPAGEA
    ld hl, 0x5000
    ld de, 0x1000
    ld bc, 0xB00
    ldir
    ; Page DB's unused tail holds the two borrowed 256-byte work areas.
    ld hl, 0x3A00
    ld de, 0x1B00
    ld bc, 0x100
    ldir
    ld hl, 0x3D00
    ld de, 0x1C00
    ld bc, 0x100
    ldir
    ret
; Save and zero AY amplitude registers 8..10 for all three channels. Tone
; and envelope registers are left alone; finish restores the saved amplitudes.
mute:
    ld hl, VOLUME
    ld e, 8
    ld d, 3
mute_loop:
    ld bc, 0xFFFD
    out (c), e
    in a, (c)
    ld (hl), a
    inc hl
    ld b, 0xBF
    xor a
    out (c), a
    inc e
    dec d
    jr nz, mute_loop
    ret
; Successful controller completion returns A=0/carry clear after a short
; status display. The controller owns the now-connected application socket.
success:
    call draw
    call transition_delay
    xor a
    jr finish
; Keep the failure reason visible until a fresh ENTER press. KEYUP prevents
; the key that initiated the failed attempt from dismissing the message.
failed:
    call draw
    call KEYUP
failure_key:
    call GETKEY
    cp 13
    jr z, failure_done
    call KEYUP
    jr failure_key
failure_done:
    ld a, 0xFC
    scf
    jr finish
; Cancellation and failure both return the module-specific error 0xFC.
cancelled:
    call draw
    call transition_delay
    ld a, 0xFC
    scf
; Preserve result AF while restoring display and sound. After PUSH AF the
; stack is (top first): result AF, page A, IFF flags, saved IY, saved IX.
; Result AF is temporarily held in BC while paging and IFF flags are restored.
finish:
    push af
    call KEYUP
    ld a, 0xDA
    call SETPAGEA
    ld hl, 0x1000
    ld de, 0x4000
    ld bc, 0x1000
    ldir
    ld a, 0xDB
    call SETPAGEA
    ld hl, 0x1000
    ld de, 0x5000
    ld bc, 0xB00
    ldir
    ld hl, 0x1B00
    ld de, 0x3A00
    ld bc, 0x100
    ldir
    ld hl, 0x1C00
    ld de, 0x3D00
    ld bc, 0x100
    ldir
    ld hl, VOLUME
    ld e, 8
    ld d, 3
restore_music:
    ld bc, 0xFFFD
    out (c), e
    ld b, 0xBF
    ld a, (hl)
    out (c), a
    inc hl
    inc e
    dec d
    jr nz, restore_music
    ld a, (BORDER)
    out (254), a
    ld a, (v_port7ffd)
    ld bc, 0x7FFD
    out (c), a
    pop bc
    pop af
    call SETPAGEA
    pop af
    ; P/V comes from entry's LD A,I, not from the result flags. Restore the
    ; result afterwards; EI's delayed effect allows RET before interrupts run.
    jp po, return_disabled
    push bc
    pop af
    pop iy
    pop ix
    ei
    ret
return_disabled:
    push bc
    pop af
    pop iy
    pop ix
    ret
; All UI strings are NUL terminated. Error-prefix checks above also depend
; on the controller's English messages; these local labels are display text.
.data
ident: asciz "Connection matchmaking"
title: defb "Connection matchmaking for ",34,0
waiting: asciz "Waiting for connection..."
preparing: asciz "Preparing connection..."
your_name: asciz "Your name: "
available: asciz "Available peers"
access: asciz "Access"
empty: asciz "No peers available."
require: asciz "Require code: "
updating_text: asciz "Updating..."
saving_text: asciz "Saving name..."
on_text: asciz "On <"
off_text: asciz "Off"
open_text: asciz "Open"
code_text: asciz "Code"
legend_prefix: asciz "[1"
legend1: asciz "] Connect    [N] Change name"
waiting_legend: asciz "Waiting for peers    [N] Change name"
legend2: asciz "[C] Toggle code    [ENTER] Exit"
change1: asciz "Change your name. Leave blank to use"
change2: asciz "your serial."
name_prompt: asciz "Name: "
code_prompt: asciz "Code: "
peer_text: asciz "Peer: "
requires: asciz "This peer requires a code"
save_text: asciz "[ENTER] Save and go back"
join_text: asciz "[ENTER] Connect"
back_text: asciz "Leave blank and press ENTER to go back"
connecting: asciz "Connecting..."
cancel_text: asciz "[ENTER] Cancel"

connected_text: asciz "Connected."
cancelled_text: asciz "Connection cancelled."
failed_text: asciz "Connection failed."
returning_text: asciz "Returning to application."

failure_back: asciz "[ENTER] Return to program"

digits_text: asciz "Enter four digits only"
