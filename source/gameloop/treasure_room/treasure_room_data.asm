INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/color.inc"
INCLUDE "macro/memcpy.inc"
INCLUDE "macro/farcall.inc"

SECTION "TREASURE ROOM DATA", ROMX

GameloopTreasureRoomInitTransfer::
    xor a
    ldh [rVBK], a

    memcpy_label BgTileSet, _VRAM9000
    memcpy_label ObjTileSet, _VRAM8000

    ld hl, BgPalettes
    xor a, a
    ld b, 2
    call PaletteCopyMultiBG

    ld hl, ObjPalettes
    xor a, a
    call PaletteCopyOBJ

    ; Draw wall
    ld bc, $1204
    ld de, 12
    ld hl, _SCRN0
    ld a, 0

    :
        REPT 5
            ld [hl+], a
        ENDR
        
        dec c
        jr nz, :-

        add hl, de
        ld c, 4
        dec b
        jr nz, :-
    ;

    ld bc, $1204
    ld de, 12
    ld hl, _SCRN0
    ld a, 1
    ldh [rVBK], a
    xor a, a

    :
        REPT 5
            ld [hl+], a
        ENDR
        
        dec c
        jr nz, :-

        add hl, de
        ld c, 4
        dec b
        jr nz, :-
    ;

    ; Draw treasure chest

    ld hl, _SCRN0 + (7 + 5 * 32)
    
    call DrawChest
    REPT 3
        ld de, 32
        add hl, de

    ENDR

    ret
;

DrawChest:
    ld bc, BgTileMap

    call DrawBgStamp

    ret
;

; Places background tiles within a rectangular area based on a pre-defined pattern.
; Does not support placing tiles at the border of a tilemap.
; 
; Patterns must be encoded in a specific format:
; - Height (1 byte)
; - Width (1 byte)
; - Tile IDs (Height * Width bytes)
; - Tile Attributes (Height * Width bytes)
;
; Input:
; - `bc`: Pointer to first byte of pattern data
; - `hl`: Pointer to top-left tile within the destination tilemap
;
; Saves: none
DrawBgStamp::
    push hl

    ; Load size
    ld a, [bc]
    inc bc
    ld d, a

    ld a, [bc]
    inc bc
    ldh [hDrawBgStampLocals.width], a
    ld e, a

    push de

    xor a, a
    ldh [rVBK], a

    .tileLoop
        ld a, [bc]
        ld [hl+], a
        inc bc

        dec e
        jr nz, .tileLoop

        dec d
        jp z, .tileLoopEnd

        ldh a, [hDrawBgStampLocals.width]
        ld e, a

        ld a, l
        sub a, e
        add a, 32
        ld l, a

        jr nc, .tileLoop
        inc h
        jr .tileLoop
    .tileLoopEnd:

    pop de
    pop hl

    ld a, 1
    ldh [rVBK], a

    .attribLoop
        ld a, [bc]
        ld [hl+], a
        inc bc

        dec e
        jr nz, .attribLoop

        dec d
        ret z

        ldh a, [hDrawBgStampLocals.width]
        ld e, a

        ld a, l
        sub a, e
        add a, 32
        ld l, a

        jr nc, .attribLoop
        inc h
        jp .attribLoop
    ;
;

ObjPalettes:
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_rgb8 $a4, $b0, $00
    color_rgb8 $ee, $ff, $00
.end

BgPalettes:
    color_t 8, 3, 11
    color_rgb8 0, 0, 0
    color_rgb8 $84, $7b, $81
    color_rgb8 $7e, $46, $3c

    color_t 20, 7, 2
    color_t 20, 7, 2
    color_t 20, 7, 2
    color_t 20, 7, 2
.end

BgTileSet:
    ; Empty tile
    ds 16, 0

    ; Treasure chest
    INCBIN "gameloop/treasure_room/treasure_chest.2bpp"

    ; Walls
    REPT 8
        db $06, $06
    ENDR

.end

ObjTileSet:
    INCBIN "gameloop/treasure_room/lock.2bpp", 0, 7 * 32
.end

BgTileMap:
    db 8, 6
    INCBIN "gameloop/treasure_room/treasure_chest.tilemap"
    INCBIN "gameloop/treasure_room/treasure_chest.attrmap"
.end

SECTION UNION "LOCALVARS", HRAM
hDrawBgStampLocals:
    .width: ds 1
.end
