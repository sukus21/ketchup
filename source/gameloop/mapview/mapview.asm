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

    ; Transfer the required assets to VRAM
    vqueue_enqueue GameloopMapviewInitTransfer
    farcall_x GameloopLoading

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

        jr .loop
    ;

MapviewVBlank:
    ; Set scroll for HUD
    ld a, 4
    ldh [rSCX], a
    ldh [rSCY], a

    ; Set LCD control
    ld a, $88
    ldh [rLCDC], a

    LYC_set_jumppoint EndHud

    ; Set STAT mode
    ld a, STATF_MODE00
    ldh [rSTAT], a

    ; Reset and enable LYC + VBlank interrupts
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a

    reti

EndHud:
    ; Skip if this is the wrong scanline
    ldh a, [rLY]
    cp a, HUD_HEIGHT
    jr z, .actuallyEndHud
        reti
    .actuallyEndHud

    ; Apply scroll
    xor a, a
    ldh [rSCX], a

    ld a, [wMapviewScroll + 1]
    sub a, MAP_SCROLL_OFFSET
    ldh [rSCY], a

    ; Set LCD control
    ld a, $82
    ldh [rLCDC], a

    reti

hudCol:
    color_rgb8 $50, $4A, $18

hudEdgeCol:
    color_rgb8 $40, $2A, $0F

mapCol:
    color_rgb8 $40, $50, $58

SECTION "GAMELOOP MAPVIEW VARIABLES", WRAM0

    wMapviewScroll: ds 2
