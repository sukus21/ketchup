INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gamestate/gamestate.inc"
INCLUDE "macro/color.inc"
INCLUDE "macro/memcpy.inc"
INCLUDE "draw/font_test.inc"

SECTION "EQUIPMENT SCREEN DATA", ROMX

GameloopEquipmentScreenInitTransfer::
    ld b, 5 * 8
    farcall_x LoadEquipableIconPalettes

    ld hl, CharacterFacePalettes
    xor a, a
    REPT 3
        call PaletteCopyOBJ
    ENDR

    ld hl, GridPalettes
    xor a, a
    ld b, 6
    call PaletteCopyMultiBG

    memcpy_vdma_label CharacterFaceTiles, _VRAM8000
    memcpy_vdma_label GridTiles, _VRAM9000 + (16 * 8)

    ld b, 8
    ld de, $0303
    ld hl, _SCRN0 + (32 * 2 + 3)
    call DrawBarGrid

    ld b, 13
    ld de, $0301
    ld hl, _SCRN0 + (32 * 2 + 14)
    call DrawBarGrid

    ld hl, _SCRN0 + (32 * 3 + 4)
    ld bc, $0109
    call SetCellPalettes

    ld hl, _SCRN0 + (32 * 3 + 7)
    ld bc, $0209
    call SetCellPalettes

    ld hl, _SCRN0 + (32 * 3 + 10)
    ld bc, $0209
    call SetCellPalettes

    ld hl, _SCRN0 + (32 * 3 + 15)
    ld bc, $0309
    call SetCellPalettes

    xor a, a
    ldh [rVBK], a

    ld hl, _SCRN0 + (32 * 14 + 2)
    ld a, 64
    ld b, 4
    ld c, 16
    :
        ld [hl+], a
        inc a
        dec c
        jr nz, :-

        ld c, a

        ld a, l
        add a, 16
        ld l, a

        jr nc, :+
            inc h
        :

        ld a, c
        ld c, 16

        dec b
        jr nz, :--
    ;

    ret
;

; Input:
; - `b`: Tile ID offset
; - `d`: Number of rows
; - `e`: Number of columns
; - `hl`: Address of top left tile in tilemap
DrawBarGrid:
    xor a, a
    ldh [rVBK], a

    push hl
    push de

    ld a, e
    ldh [hDrawBarGridLocals.numCols], a

    ; Calculate number of tiles to skip after each row of the tilemap
    add a, a
    add a, e
    add a, 2 - 32 - 1
    cpl a
    ld c, a

    ; Top left corner tile
    ld a, b
    add a, 2
    ld [hl+], a

    ; First row of tiles, excluding corners
    ld a, b
    :
        REPT 3
            ld [hl+], a
        ENDR

        dec e
        jr nz, :-
    ;

    ; Top right corner tile
    add a, 2
    ld [hl+], a

    ; Advance to next row
    ld a, c
    add a, l
    ld l, a
    jr nc, :+
        inc h
    :

    ldh a, [hDrawBarGridLocals.numCols]
    ld e, a

    .rowLoop:
        ld a, b
        add a, 3
        ld [hl+], a

        add a, (1 - 3)
        :
            ld [hl+], a

            ld [hl], b
            inc l

            ld [hl+], a

            dec e
            jr nz, :-
        ;

        add a, (3 - 1)
        ld [hl+], a

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        ld a, b
        add a, 4
        ld [hl+], a

        :
            ld [hl+], a
            
            ld [hl], 0
            inc l

            ld [hl+], a

            dec e
            jr nz, :-
        ;

        ld [hl+], a

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        ld a, b
        add a, 3
        ld [hl+], a

        add a, (1 - 3)
        :
            ld [hl+], a

            ld [hl], b
            inc l

            ld [hl+], a

            dec e
            jr nz, :-
        ;

        add a, (3 - 1)
        ld [hl+], a

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        dec d
        jr nz, .rowLoop
    ;

    ; Top left corner tile
    ld a, b
    add a, 2
    ld [hl+], a

    ; First row of tiles, excluding corners
    ld a, b
    :
        REPT 3
            ld [hl+], a
        ENDR

        dec e
        jr nz, :-
    ;

    ; Top right corner tile
    add a, 2
    ld [hl+], a

    ; Set tile attributes
    ld a, 1
    ldh [rVBK], a

    pop de
    pop hl

    ld b, OAMF_XFLIP
    
    inc d
    .attribRowLoop:
        ld a, OAMF_XFLIP | OAMF_YFLIP
        :
            ld [hl+], a

            xor a, b
            ld [hl+], a

            xor a, b
            ld [hl+], a

            dec e
            jr nz, :-
        ;

        ld [hl+], a

        xor a, b
        ld [hl+], a

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        ld a, b
        :
            ld [hl+], a

            xor a, b
            ld [hl+], a

            xor a, b
            ld [hl+], a

            dec e
            jr nz, :-
        ;

        ld [hl+], a

        xor a, b
        ld [hl+], a
        
        dec d
        ret z

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        ld a, b
        :
            ld [hl+], a

            xor a, b
            ld [hl+], a

            xor a, b
            ld [hl+], a

            dec e
            jr nz, :-
        ;

        ld [hl+], a

        xor a, b
        ld [hl+], a

        ; Advance to next row
        ld a, c
        add a, l
        ld l, a
        jr nc, :+
            inc h
        :

        ldh a, [hDrawBarGridLocals.numCols]
        ld e, a

        jr .attribRowLoop
    ;

    ret
;

SetCellPalettes:
    :
        REPT 3
            ld a, [hl]
            or a, b
            ld [hl+], a
        ENDR

        dec c
        ret z

        ld a, l
        add a, 29
        ld l, a
        jr nc, :-

        inc h
        jr :-
    ;
;

    ds ALIGN[4]

CharacterFaceTiles:
    INCBIN "gameloop/equipment_screen/char_faces.2bpp"
.end

GridTiles:
    INCBIN "gameloop/equipment_screen/grid_bars.2bpp"
.end

CharacterFacePalettes:
    .herbert:
    color_rgb8 $00, $00, $00
    color_rgb8 $00, $00, $00
    color_rgb8 $6C, $DE, $27
    color_rgb8 $48, $7B, $31

    .menja:
    color_rgb8 $00, $00, $00
    color_rgb8 $00, $00, $00
    color_rgb8 $62, $37, $BA
    color_rgb8 $96, $6D, $4C

    .duffin:
    color_rgb8 $00, $00, $00
    color_rgb8 $00, $00, $00
    color_rgb8 $AA, $20, $20
    color_rgb8 $B6, $88, $7A
.end

GridPalettes:
    ; Background
    color_t 8, 8, 8
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6

    ; Primary slot
    color_t 9, 9, 5
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6

    ; Secondary slot
    color_t 7, 8, 8
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6

    ; Exchange slot
    color_t 7, 8, 8
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6

    ; Cursor
    color_t 14, 14, 14
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6

    ; Selection
    color_t 6, 15, 6
    color_t 2, 2, 3
    color_t 8, 10, 9
    color_t 4, 5, 6
.end

SECTION UNION "LOCALVARS", HRAM
hDrawBarGridLocals:
    .numCols: ds 1
.end
