INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "macro/color.inc"
INCLUDE "macro/memcpy.inc"

; The Status Hud is a HUD that can be reused across gameloops.
; As the name implies, it displays various information about the
; player's status. Right now, that's each character's health and
; the players money.
;
; The Status HUD occupies the top 16 scanlines of the screen.
; As for resources, it reserves:
; - Tile IDs from 352 to 383 (within the background-only area)
; - The left 21 tiles of the bottom 2 rows of tilemap 1
; - Background palletes 6 and 7
; The HUD does not use any sprites or the window layer.
; 
; The HUD works by manipulating SCX, SCY, and LCDC, and by using
; scanline interrupts. A callback is made at the final scanline
; of the HUD and can be modified from the outside, allowing the
; gameloop to reclaim control of these features for the rest of
; the frame.

DEF HUD_BASE_TILE_ID EQU 96
DEF HUD_BASE_TILE_ROW_ADDRESS EQU _SCRN1 + (32 * 30)
DEF HUD_BASE_PALETTE_INDEX EQU 6

SECTION "STATUS HUD", ROM0

DisplayHud::
    ; Set scroll
    ld a, -12
    ldh [rSCY], a
    ld a, 4
    ldh [rSCX], a

    ; Set LCDC
    ld a, LCDCF_ON | LCDCF_BG9C00
    ldh [rLCDC], a
    
    ; Set Scanline Interrupt
    LYC_set_jumppoint LyEdge

    ld a, 12
    ldh [rLYC], a

    ld a, STATF_LYC
    ldh [rSTAT], a

    ; Reset and enable LYC + VBlank interrupts
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a

    ret
;

LyEdge:
    push af

    ; One may ask whether it is really neccesary to use a scanline
    ; interrupt just to save one row of the second tilemap. However,
    ; we (by which I mean I (who is tecanec)) counter that with the
    ; simple truth that the right question to ask is never whether
    ; or not we should, but rather, whether or not we can.

    ld a, -28
    ldh [rSCY], a ; This barely makes it in time.

    push hl

    ld a, 15
    ldh [rLYC], a

    ld hl, wStatusHudConfig.endOfHudHandler
    ld a, [hl+]
    ldh [hLYC + 1], a
    ld a, [hl]
    ldh [hLYC + 2], a

    xor a, a
    ldh [rIF], a

    pop hl
    pop af
    reti 
;


SECTION "STATUS HUD DATA", ROMX

LoadStatusHud::
    ; Load palettes
    ld a, HUD_BASE_PALETTE_INDEX * 8
    ld b, 2
    ld hl, StatusHudPalettes
    call PaletteCopyMultiBG

    ; Load tiles
    ld a, 1
    ldh [rVBK], a

    memcpy_label StatusHudTiles, _VRAM9000 + (HUD_BASE_TILE_ID * 16)

    ld hl, _VRAM9000 + ((HUD_BASE_TILE_ID + 31) * 16)
    xor a, a
    REPT 16
        ld [hl+], a
    ENDR

    ; Load tilemap
    xor a, a
    ldh [rVBK], a

    ld hl, HUD_BASE_TILE_ROW_ADDRESS

    ; Border row
    ld c, 5
    ld a, HUD_BASE_TILE_ID + 5
    :
        REPT 4
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ld a, l
    add a, 11
    ld l, a

    ; Info row
    call FillHudInfo

    ; Attributes

    ld a, 1
    ldh [rVBK], a
    
    ld hl, HUD_BASE_TILE_ROW_ADDRESS

    ; Border row
    ld a, OAMF_BANK1 | (HUD_BASE_PALETTE_INDEX + 1)
    ld c, 5
    :
        REPT 4
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ld a, l
    add a, 11
    ld l, a

    ; Info row
    ld a, OAMF_BANK1 | HUD_BASE_PALETTE_INDEX
    ld c, 2
    :
        REPT 5
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld a, OAMF_BANK1 | (HUD_BASE_PALETTE_INDEX + 1)
    ld c, 2
    :
        REPT 5
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ret
;

; Updates the HUD with current health and money.
;
; Saves: none
UpdateStatusHud::
    ld hl, _SCRN1 + 32

    xor a, a
    ldh [rVBK], a
    
    ; Fall through to FillHudInfo

; Generates the second row of tiles in the HUD. That is the row
; displaying the actual information shown in the HUD.
;
; Input:
; - hl: Pointer to the start of the row being filled
;
; Returns:
; - hl: Increased by 21
; 
; Saves: none
FillHudInfo:
    ld a, BANK(wGameStateCharacterHealth)
    ldh [rSVBK], a

    ld bc, wGameStateCharacterHealth

    ; Character health
    FOR I, 3
        ; Margin/Padding'
        ld a, $FF
        ld [hl+], a
        
        ; Character icon
        ld a, HUD_BASE_TILE_ID + I
        ld [hl+], a
        
        ; "HP:"
        ld a, HUD_BASE_TILE_ID + 3
        ld [hl+], a

        ; Tens' digit
        ld a, [bc]
        swap a
        and a, $0F
        add a, HUD_BASE_TILE_ID + 6
        ld [hl+], a

        ; Ones' digit
        ld a, [bc]
        and a, $0F
        add a, HUD_BASE_TILE_ID + 6
        ld [hl+], a

        ; Advance
        inc c
    ENDR

    ; Padding
    ld a, $FF
    ld [hl+], a

    ; Show money

    ; "$:"
    ld a, HUD_BASE_TILE_ID + 4
    ld [hl+], a

    ; Houndreds' digit
    ld a, [bc]
    add a, HUD_BASE_TILE_ID + 6
    ld [hl+], a
    
    inc c

    ; Tens' digit
    ld a, [bc]
    swap a
    and a, $0F
    add a, HUD_BASE_TILE_ID + 6
    ld [hl+], a

    ; Ones' digit
    ld a, [bc]
    and a, $0F
    add a, HUD_BASE_TILE_ID + 6
    ld [hl+], a

    ; Final margin tile
    ld a, $FF
    ld [hl+], a

    ret
;

StatusHudPalettes:
    ; Herbert's green and Menja's blue
    color_rgb8 $30, $4A, $58
    color_rgb8 $00, $00, $00
    color_rgb8 $20, $F0, $30
    color_rgb8 $40, $10, $E0

    ; Duffin's red and shading
    color_rgb8 $30, $4A, $58
    color_rgb8 $00, $00, $00
    color_rgb8 $F0, $10, $10
    color_rgb8 $20, $2A, $38
.end

StatusHudTiles:
    .char_icons: INCBIN "gamestate/char_icons.2bpp"
    .numbers: INCBIN "gamestate/numbers.2bpp"
.end

SECTION "STATUS HUD CONFIG", WRAM0
wStatusHudConfig::
    ; Pointer to the interrupt handler to be called on the
    ; final scanline of the HUD.
    ; 
    ; Should be used to start displaying the main body of the
    ; frame. This likely involves modifying `SCX`, `SCY`, and
    ; `LCDC`, as these are also modified while displaying the
    ; HUD.
    .endOfHudHandler:: ds 2
.end
