INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/color.inc"
INCLUDE "gameloop/battle/vram.inc"


SECTION "GAMELOOP BATTLE DATA", ROMX

    ; Initial VQUEUE transfer for battle gameloop
    GameloopBattleInitTransfer::
        ; Clear tilemaps
        xor a
        ldh [rVBK], a
        ld hl, _SCRN0
        ld bc, $00_80
        call MemsetChunked

        ; Clear attribute maps
        ld a, 1
        ldh [rVBK], a
        ld hl, _SCRN0
        ld bc, $00_80
        call MemsetChunked

        ; Load tileset
        xor a
        ldh [rVBK], a
        ld bc, TilesetGridTiles
        ld hl, VT_BATTLE_CELLS
        ld d, 18
        call MemcpyTile2BPP

        ; Load sprites
        ld bc, TilesetSprites
        ld hl, VT_BATTLE_TESTSPRITES
        ld d, 32
        call MemcpyTile2BPP

        ; Build enemy cell tilemaps
        ld hl, VM_BATTLE_CELLS_ENEMY
        ld a, VTI_BATTLE_CELLS_ENEMY
        call GameloopBattleInitCellHelper
        ld a, VTI_BATTLE_CELLS_ENEMY
        call GameloopBattleInitCellHelper

        ; Build player cell tilemaps
        ld hl, VM_BATTLE_CELLS_PLAYER
        ld a, VTI_BATTLE_CELLS_PLAYER
        call GameloopBattleInitCellHelper
        ld a, VTI_BATTLE_CELLS_PLAYER
        call GameloopBattleInitCellHelper
        ld a, VTI_BATTLE_CELLS_PLAYER
        call GameloopBattleInitCellHelper

        ; Set some stuff up for debugging the window
        xor a
        ldh [rVBK], a
        ld hl, _SCRN0
        ld e, l
        ld b, VTI_BATTLE_CELLS_ENEMY + 3
        ld c, 32
        .windowLoop
            ld [hl], b
            inc l
            ld a, VTI_BATTLE_CELLS_ENEMY + 4
            REPT 6
                ld [hl+], a
            ENDR

            ld a, e
            add a, 32
            ld l, a
            ld e, a
            jr nc, @+3 :: inc h
            
            dec c
            jr nz, .windowLoop
        ;

        ; Set window attributes
        ld a, 1
        ldh [rVBK], a
        ld d, 32
        ld hl, _SCRN0
        .windowAttrLoop
            ld a, PAL_BATTLE_MENU_DEFAULT
            REPT 9
                ld [hl+], a
            ENDR
            ld a, l
            add a, 32 - 9
            ld l, a
            jr nc, @+3 :: inc h
            
            dec d
            jr nz, .windowAttrLoop
        ;

        ; Lastly, transfer palettes
        ld hl, PaletteArena
        xor a
        call PaletteCopyBG
        call PaletteCopyBG
        call PaletteCopyBG
        call PaletteCopyBG
        xor a
        call PaletteCopyOBJ

        ; Set all the hardware registers
        ld a, VMI_BATTLE_BASE_X0*8
        ldh [rSCX], a
        ld a, VMI_BATTLE_BASE_Y0*8
        ldh [rSCY], a
        ld a, LCDCF_BLK21 | LCDCF_BGON | LCDCF_ON | LCDCF_WINON | LCDCF_WIN9800 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ16
        ldh [rLCDC], a

        ; Yeah, we are done here
        ret
    ;

    ; Draws a row of grid cells.
    ; Helper routine for `GameloopBattleInitTransfer`.
    ;
    ; Input:
    ; - `a`: Tile index to use (top-left corner)
    ; - `hl`: Address to build cell (top-left corner)
    ;
    ; Returns:
    ; - `hl`: Input `hl` + 96 (3 rows down)
    ;
    ; Saves: none
    GameloopBattleInitCellHelper:
        push hl
        ld b, a
        xor a
        ldh [rVBK], a
        ld a, b

        ; First set the tile
        ld de, $0303
        .tileLoop
            REPT 3
                ld [hl+], a
                inc a
            ENDR
            sub a, 3
            dec d
            jr nz, .tileLoop

            ; Are we done?
            dec e
            jr z, .tileLoopEnd

            ; Offset counters and stuff a little...
            ld d, 3
            add a, d

            ; Move one row down and go again
            ld b, a
            ld a, l
            add a, 32 - 9
            ld l, a
            ld a, b
            jr nc, .tileLoop
            inc h
            jr .tileLoop
        .tileLoopEnd

        ; Now set the attributes
        pop hl
        ld a, 1
        ldh [rVBK], a

        ld d, 4
        .attrLoop

            ; If we are done, return
            dec d
            ret z

            ; Paste attributes all over the place
            ld a, OAMF_BANK0 | PAL_BATTLE_CELLS_DEFAULT
            REPT 9
                ld [hl+], a
            ENDR

            ; Move one row down and go again
            ld a, l
            add a, 32 - 9
            ld l, a
            jr nc, .attrLoop
            inc h
            jr .attrLoop
        ;
    ;



    ; Tile data for the grid
    TilesetGridTiles: INCBIN "gameloop/battle/tiles.2bpp"
    .end

    ; Sprite data, for testing
    TilesetSprites:
        INCBIN "gameloop/battle/testsprite1.2bpp"
        INCBIN "gameloop/battle/testsprite2.2bpp"
    .end

    ; Default arena background palette
    PaletteArena:
        color_rgb8 $22, $20, $34
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
    ;

    ; Default palette for grid tiles
    PaletteTilesDefault:
        color_rgb8 $D9, $57, $63
        color_rgb8 $AC, $32, $32
        color_rgb8 $63, $9B, $FF
        color_rgb8 $3F, $3F, $74
    ;

    ; Palette for poisoned grid tiles
    ; TODO: define palette for this
    PaletteTilesPoisoned:
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
    ;

    ; Base menu palette, with text and stuff
    PaletteMenuBase:
        color_rgb8 $9B, $AD, $B7
        color_rgb8 $84, $7E, $87
        color_rgb8 $00, $00, $00
        color_rgb8 $00, $00, $00
    ;

    ; Palette for testing sprites
    PaletteSprites:
        color_t 0, 0, 0
        color_t 31, 0, 0
        color_t 0, 31, 0
        color_t 0, 0, 31
    ;
;
