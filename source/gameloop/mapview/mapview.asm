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

GameloopMapview::
    farcall_x initRun

    ld hl, wMapviewScroll
    xor a, a
    ld [hl+], a
    ld [hl+], a

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
        add a, 32
        add a, e
        jr c, .doneDrawingCursors
        cp a, 160
        jr nc, .doneDrawingCursors
            ld c, a

            ld a, d
            or a, a
            jr z, .optionBitmaskFromEntry
                ; Get pointer to current lane
                add a, LOW(wGameStatePathTaken)
                ld l, a

                ; Get pointer to current room
                ld a, d
                add a, a
                add a, a
                add a, d ; a = d * 5
                add a, LOW(wGameStateMapRoomData)

                ; Get current room paths
                ld a, [hl]
                and a, $E0

                ; Shift paths depending on current lane
                ld l, d
                ld h, a
                xor a, a
                :
                    sla h
                    rla
                    dec l
                    jr nz, :-
                ;

                ld e, a
                jr .gotOptionBitmask
            .optionBitmaskFromEntry:
                ld l, LOW(wGameStateMapRoomData)
                ld b, 1<<4
                ld e, 0
                :
                    ld a, [hl+]
                    or a, a
                    jr z, :+
                        ld a, e
                        or a, b
                        ld e, a
                    :
                    srl b
                    jr nz, :--
                ;
            .gotOptionBitmask:

            ld a, 160 - 8

            .drawCursorLoop:
                srl e
                jr nc, :+
                    ld d, a
                    push de

                    ld b, a
                    ld h, HIGH(wOAM)
                    ld de, CursorSprite
                    xor a, a
                    call SpriteDrawTemplate

                    pop de
                    ld a, d

                    sub a, 32
                    
                    jr .drawCursorLoop
                :
                
                jr z, .doneDrawingCursors
                sub a, 32
                
                jr .drawCursorLoop
            ;
        .doneDrawingCursors:

        ; Done processing for this frame, finish things off
        ld h, high(wOAM)
        call SpriteFinish

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

MapviewVBlank:
    ; Do OAM DMA
    ld a, high(wOAM)
    call hDMA
    
    ; Set scroll for HUD
    ld a, 4
    ldh [rSCX], a
    ldh [rSCY], a

    ; Set LCD control
    ld a, $88
    ldh [rLCDC], a

    LYC_set_jumppoint EndHud

    ld a, HUD_HEIGHT
    ldh [rLYC], a

    ; Set STAT mode
    ld a, STATF_LYC | STATF_MODE00
    ldh [rSTAT], a

    ; Reset and enable LYC + VBlank interrupts
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a

    reti

EndHud:
    push af

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

    ld a, [wMapviewScroll + 1]
    sub a, MAP_SCROLL_OFFSET
    ldh [rSCY], a

    ; Set LCD control
    ld a, LCDCF_ON | LCDCF_OBJ16 | LCDCF_OBJON
    ldh [rLCDC], a

    pop af

    reti

hudCol:
    color_rgb8 $50, $4A, $18

hudEdgeCol:
    color_rgb8 $40, $2A, $0F

mapCol:
    color_rgb8 $40, $50, $58

CheckmarkSprite:
    db %10000000
    db $00, 0
;

CursorSprite:
    db %11000000
    db $02, 0
    db $02, OAMF_XFLIP
;

SECTION "GAMELOOP MAPVIEW VARIABLES", WRAM0

    wMapviewScroll: ds 2
