INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gamestate/gamestate.inc"
INCLUDE "macro/color.inc"

DEF HUD_HEIGHT EQU $10

DEF MAP_SCROLL_SPEED EQU $113
DEF MAP_SCROLL_OFFSET EQU $10
DEF MAP_SCROLL_LIMIT EQU 1<<8 + MAP_SCROLL_OFFSET - 144

SECTION "MAP VIEW", ROMX

; Begin a run and enter mapview.
; Does not return.
BeginRun::
    farcall_x InitRun
    ; Fall through to GameloopMapView

; Enter mapview.
; Does not return.
GameloopMapview::
    ; Set scroll
    ld a, BANK(wGameStateTravelProgress)
    ldh [rSVBK], a

    ld hl, wMapviewScroll
    xor a, a
    ld [hl+], a
    
    ld a, [wGameStateTravelProgress]
    swap a
    add a, a

    ; Offset + Upper limit
    sub a, 32
    jr nc, :+
        xor a, a
    :

    ; Lower limit
    cp a, MAP_SCROLL_LIMIT
    jr c, :+
        ld a, MAP_SCROLL_LIMIT
    :
    ld [hl+], a

    ; Prepare navigation-related data
    call ComputeTravelOptions

    ld a, [wMapviewAdvanceOptions]
    ld b, -1
    :
        inc b
        rrca
        jr nc, :-
    ;
    ld a, b
    ld [wMapviewAdvanceSelection], a

    ld a, 0
    ld [wMapviewAnimTime], a

    ; Clear OAM mirror
    ld bc, $00_10
    ld hl, wOAM
    call MemsetChunked

    ; Prepare this, just in case
    call OamDmaInit

    ; Transfer the required assets to VRAM
    vqueue_enqueue GameloopMapviewInitTransfer
    farcall_x GameloopLoading

    ; Do initial VBlank
    call WaitVBlank
    farcall_x GameloopBattleVBlank

    .loop:
        call ReadInput

        ; Scrolling

        ; Get pointer to scrolling variable
        ld hl, wMapviewScroll

        ; Scrolling up
        bit PADB_UP, b
        jr z, :+
            ; Lower byte
            ld a, [hl]
            sub a, LOW(MAP_SCROLL_SPEED)
            ld [hl+], a
            
            ; Upper byte
            ld a, [hl]
            sbc a, HIGH(MAP_SCROLL_SPEED)
            ld [hl-], a

            ; Enforce limit
            jr nc, :+
                xor a, a
                ld [hl+], a
                ld [hl-], a
            ;
        :

        ; Scrolling down
        bit PADB_DOWN, b
        jr z, :+
            ; Lower byte
            ld a, [hl]
            add a, LOW(MAP_SCROLL_SPEED)
            ld [hl+], a
            
            ; Upper byte
            ld a, [hl]
            adc a, HIGH(MAP_SCROLL_SPEED)
            ld [hl-], a

            ; Enforce limit
            cp a, MAP_SCROLL_LIMIT
            jr c, :+
                xor a, a
                ld [hl+], a
                ld a, MAP_SCROLL_LIMIT
                ld [hl-], a
            ;
        :

        ; Selection
        ld hl, wMapviewAdvanceOptions
        ld a, [hl+]
        ld d, [hl]
        ld e, d
        inc e

        :
            rra
            dec e
            jr nz, :-
        ;
        rla

        ; Select Left
        bit PADB_LEFT, c
        jr z, :++
        :
            inc d
            rra
            bit 0, a
            jr z, :-
        :

        ; Select Right
        bit PADB_RIGHT, c
        jr z, :++
        :
            dec d
            rla
            bit 0, a
            jr z, :-
        :

        ; Modulo 9 and save
        ld a, d
        add a, 18
        :
            sub a, 9
            jr nc, :-
        ;
        add a, 9
        ld [hl], a

        ; Room entering
        bit PADB_A, c
        jp nz, EnterRoom

        ; Draw cursors
        ld a, BANK(wGameStateTravelProgress)
        ldh [rSVBK], a

        ld hl, wGameStateTravelProgress
        ld d, [hl]

        ld a, d
        swap a
        add a, a
        and a, $E0
        ld e, a

        ld a, [wMapviewScroll + 1]
        cpl 
        add a, 28
        add a, e
        cp a, 160
        jr nc, .doneDrawingCursors
            ld c, a

            ; Get bitmask of available options
            ld a, [wMapviewAdvanceOptions]
            ld e, a

            ; Get current selection
            ld a, [wMapviewAdvanceSelection]
            ld d, a
            inc d

            ; X-coordinate of rightmost potential cursor
            ld a, 160 - 8

            .drawCursorLoop:
                ld b, a
                
                ; Add a little jumping animation
                res 0, c
                ld a, [wMapviewAnimTime]
                rra
                rra
                sub a, d
                and a, 7
                jr z, :+
                    inc c
                :

                ; Use bitshifts to see what cursors should be drawn
                srl e
                jr nc, :++
                    dec d
                    jr z, :+
                        ; Non-selected cursor
                        push bc

                        ld b, 4
                        ld h, HIGH(wOAM)
                        call SpriteGet

                        pop bc
                        ld a, b
                        sub a, 4

                        ld [hl], c
                        inc l
                        ld [hl+], a
                        ld [hl], 4
                        inc l
                        ld [hl], 1

                        sub a, 28
                        jr .drawCursorLoop
                    :

                    ; Selected cursor
                    push de
                    push bc

                    ld h, HIGH(wOAM)
                    ld de, CursorSprite
                    xor a, a
                    call SpriteDrawTemplate

                    pop bc
                    pop de
                    ld a, b

                    sub a, 32
                    
                    jr .drawCursorLoop
                :
                
                ; No cursor
                jr z, .doneDrawingCursors ; If z is set, then the bitmask of remaining cursors is empty
                ld a, b
                sub a, 32
                dec d
                
                jr .drawCursorLoop
            ;
        .doneDrawingCursors:

        ; Draw checkmarks at passed rooms
        ld a, [wGameStateTravelProgress]
        or a, a
        jr z, .doneDrawingCheckmarks
            ld d, a

            ; Get pointer to previous lane
            add a, LOW(wGameStatePathTaken) - 1
            ld l, a
            ld h, HIGH(wGameStatePathTaken)

            ; Store current scroll in e
            ld a, [wMapviewScroll + 1]
            ld e, a

            ; Calculate y-coordinate of lowest checkmark
            ld a, d
            swap a
            add a, a
            and a, $E0
            dec a

            ; Apply scroll to y-coordinate
            sub a, e
            jr c, .doneDrawingCheckmarks
        
            ; Skip checkmarks below view
            sub a, 160
            jr c, :++
            :
                dec l
                sub a, 32
                jr nc, :-
            :
            add a, 160

            ld b, 4
            .drawCheckmarkLoop:
                ld d, a

                ; Get lane at this row
                ld a, [hl-]

                ; Calculate x-coordinate
                swap a
                add a, a
                and a, $E0
                add a, 26
                ld c, a

                push hl

                ; Get sprite slot
                ld h, HIGH(wOAM)
                call SpriteGet

                ; Fill sprite slot
                ld a, d
                add a, 11
                ld [hl+], a
                ld [hl], c
                inc l
                ld [hl], 0
                inc l
                ld [hl], 0

                pop hl

                ; Advance; Stop when next checkmark is above view
                ld a, d
                sub a, 32
                jr nc, .drawCheckmarkLoop
            ;
        .doneDrawingCheckmarks:

        ; Done processing for this frame, finish things off
        ld h, high(wOAM)
        call SpriteFinish

        ld hl, wMapviewAnimTime
        inc [hl]

        ; Wait for Vblank
        .halting
            halt
            nop

            ; Ignore if this wasn't VBlank
            ldh a, [rSTAT]
            and a, STATF_LCD
            cp a, STATF_VBL
            jr nz, .halting
        ;

        call MapviewVBlank

        jp .loop
    ;
;

; Calculate which rooms on the next lane can be reached and save result
; to `wMapviewAdvanceOptions`.
;
; Saves: none
ComputeTravelOptions:
    ; Set WRAM bank
    ld a, BANK(wGameStateTravelProgress)
    ldh [rSVBK], a

    ; Get current depth
    ld a, [wGameStateTravelProgress]

    ; Treat first row differently from the rest
    or a, a
    jr z, .optionBitmaskFromEntry
        ld d, a

        ld h, HIGH(wGameStatePathTaken)
    
        ; Get current lane
        add a, LOW(wGameStatePathTaken) - 1
        ld l, a
        ld a, [hl]
        ld e, a

        ; Get pointer to south-west room
        ld a, d
        add a, a
        add a, a
        add a, d ; a = d * 5
        add a, LOW(wGameStateMapRoomData) - 1
        add a, e
        ld l, a

        ; Find out which rooms can be reached from here
        ld a, [hl+]
        and a, $20
        ld b, a
        ld a, [hl+]
        and a, $40
        or a, b
        ld b, a
        ld a, [hl]
        and a, $80
        or a, b

        ; Reverse bitmask
        ld h, a
        xor a, a
        REPT 3
            sla h
            rra
        ENDR

        ; Shift paths depending on current lane
        ld h, a
        ld a, 6
        sub a, e
        ld l, a
        ld a, h
        :
            sla h
            rla
            dec l
            jr nz, :-
        ;

        ; Save result and return
        ld [wMapviewAdvanceOptions], a
        ret

    .optionBitmaskFromEntry:
        ; Set bitmask depending on what rooms are on the first row
        ld hl, wGameStateMapRoomData
        ld d, 1<<4
        ld e, 0
        :
            ld a, [hl+]
            or a, a
            jr z, :+
                ld a, e
                or a, d
                ld e, a
            :
            srl d
            jr nz, :--
        ;

        ; Save result and return
        ld a, e
        ld [wMapviewAdvanceOptions], a
        ret
    ;
;

; Advance the player's position to their selected destination on the next
; row and switch to a different gameloop depending on the room they enter.
; Does not return.
EnterRoom:
    ; Save progress
    ld a, BANK(wGameStatePathTaken)
    ldh [rSVBK], a

    ld hl, wGameStateTravelProgress
    ld a, [hl]
    inc [hl]
    ld d, a ; Store progress in d
    add a, LOW(wGameStatePathTaken)
    ld l, a
    ld h, HIGH(wGameStatePathTaken)

    ld a, [wMapviewAdvanceSelection]
    cpl a
    add a, 5
    ld [hl], a
    ld e, a ; Store lane in e

    ; Find out what kind of room we're entering
    ; Get pointer to room
    ld a, d
    add a, a
    add a, a
    add a, d ; a = d * 5
    add a, e
    add a, LOW(wGameStateMapRoomData)
    ld l, a
    
    ; Extract room type
    ld a, [hl]
    and a, $07

    ; Get pointer into jump table
    ld e, a
    add a, a
    add a, e
    ld e, a
    ld d, 0
    ld hl, RoomTypeJumpTable
    add hl, de

    ; Get jump destination
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, b

    ; LESGOOO!!!
    jp farjump
;

; VBlank routine for the mapview gameloop.
;
; Saves: none
MapviewVBlank:
    ; Do OAM DMA
    ld a, high(wOAM)
    call hDMA
    
    ; Set scroll for HUD
    ld a, 4
    ldh [rSCX], a
    ldh [rSCY], a

    ; Set LCD control
    ld a, LCDCF_ON | LCDCF_BG9C00
    ldh [rLCDC], a

    LYC_set_jumppoint EndHud

    ld a, HUD_HEIGHT
    ldh [rLYC], a

    ; Set STAT mode
    ld a, STATF_LYC
    ldh [rSTAT], a

    ; Reset and enable LYC + VBlank interrupts
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a

    ; Buffer scrolling to synchronize it with sprites.
    ld hl, wMapviewScroll
    ld a, [hl+]
    ld b, a
    ld a, [hl+]
    ld c, a
    ld a, b
    ld [hl+], a
    ld [hl], c

    reti
;

; HBlank routine to be called at the bottom of the HUD.
;
; Saves: all
EndHud:
    push af

    LYC_wait_hblank

    ; Skip if this is the wrong scanline
    ; ldh a, [rLY]
    ; cp a, HUD_HEIGHT
    ; jr z, .actuallyEndHud
    ;     pop af
    ;     reti
    ; .actuallyEndHud

    ; Apply scroll
    xor a, a
    ldh [rSCX], a

    ld a, [wMapviewScrollBuffered + 1]
    sub a, MAP_SCROLL_OFFSET
    ldh [rSCY], a

    ; Set LCD control
    ld a, LCDCF_ON | LCDCF_OBJ16 | LCDCF_OBJON
    ldh [rLCDC], a

    pop af

    reti
;

CheckmarkSprite:
    db %10000000
    db $00, 0
;

CursorSprite:
    db %11000000
    db $02, 0
    db $02, OAMF_XFLIP
;

MACRO pointer24
    db BANK(\1)
    dw \1
ENDM

RoomTypeJumpTable:
    pointer24 InvalidRoomType ; GAMESTATE_ROOM_TYPE_INACCESSIBLE
    pointer24 GameloopBattle ; GAMESTATE_ROOM_TYPE_BOSS
    pointer24 GameloopMapview ; GAMESTATE_ROOM_TYPE_TREASURE
    pointer24 GameloopMapview ; GAMESTATE_ROOM_TYPE_SECRET
    pointer24 GameloopMapview ; GAMESTATE_ROOM_TYPE_CAMP
    pointer24 GameloopMapview ; GAMESTATE_ROOM_TYPE_MERCHANT
    pointer24 GameloopMapview ; GAMESTATE_ROOM_TYPE_WEAK_ENCOUNTER
    pointer24 InvalidRoomType ; GAMESTATE_ROOM_TYPE_STRONG_ENCOUNTER
;

InvalidRoomType:
    rst VecError
;

SECTION "VARIABLE FARJUMP", ROM0
; Switch banks and jump to the specified destination.
; 
; Input:
; - `a`: Bank
; - `hl`: Address
;
; Saves: all
farjump:
    ld [$2000], a
    jp hl
;

SECTION "GAMELOOP MAPVIEW VARIABLES", WRAM0
    ; How far the view is scrolled up or down.
    ; Increasing value means the view is moving downwards.
    ; Little-endian 16-bit value; Low 8 bits are subpixel.
    wMapviewScroll: ds 2

    ; Copy of `wMapviewScroll` made at the start of VBlank to avoid
    ; scroll desynchronization between sprites and tilemaps.
    wMapviewScrollBuffered: ds 2

    ; Bitmask of currently available travel destinations on next row.
    wMapviewAdvanceOptions: ds 1

    ; Lane index of currently selected destination.
    wMapviewAdvanceSelection: ds 1

    ; Increased by 1 every frame. Use for animations.
    wMapviewAnimTime: ds 1
;