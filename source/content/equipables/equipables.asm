INCLUDE "content/equipables/equipables.inc"
INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/memcpy.inc"
INCLUDE "macro/color.inc"

SECTION "EQUIPABLES DATA", ROMX, ALIGN[8]

; Input:
; - `e`: Equipable ID
; - `bc`: Pointer to destination in VRAM (Should be aligned by 32)
;
; Returns:
; - `bc`: Pointer to byte following newly-loaded tile data (which may have size 0)
;
; Saves: `e`
LoadEquipableIconTiles::
    ld a, e
    ld h, b
    ld l, c

    cp a, EQUIPABLE_ID_NULL
    ret z

    ; Multiply equipable ID by 64
    ld b, a
    xor a, a
    REPT 2
        srl b
        rra
    ENDR

    ; Get pointer to icon tile data
    add a, LOW(EquipableIconTiles)
    ld c, a
    ld a, b
    adc a, HIGH(EquipableIconTiles)
    ld b, a

    ; Copy tile data to destination
    ld d, 4
    call MemcpyTile2BPP

    ld b, h
    ld c, l

    ret
;

; Input:
; - `b`: First palette index * 8
;
; Returns:
; - `b`: Last palette index + 8
;
; Saves: none
LoadEquipableIconPalettes::
    ld a, b
    ld hl, EquipableIconPalettes
    REPT 3
        call PaletteCopyOBJ
    ENDR
    ld b, a
    ret 
;

EquipableIconTiles:
    INCBIN "content/equipables/icons.2bpp"
.end

EquipableIconPalettes:
    ; Rusty and red
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_rgb8 $91, $7f, $7f
    color_rgb8 $c6, $25, $08

    ; Blue and steel
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_rgb8 $50, $5d, $8e
    color_rgb8 $74, $8e, $84

    ; Yellow and green
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_rgb8 $ff, $d2, $00
    color_rgb8 $44, $87, $34
.end

SECTION "EQUIPABLES", ROM0, ALIGN[8]

; Encodes the palette of the left side of the icon in bits 0-2 and the
; palette of the right side in bits 4-6. (Most icons use the same
; palette on both sides, but they don't have to.)
EquipableIconPaletteIndices:
    db $00 ; First-Aid Kit
    db $00 ; SpellBoy
    db $11 ; Butter Knife
    db $22 ; Duckee Idol
    db $00 ; Surstromming
    db $22 ; Gold Bar
    db $00 ; Pantoglove
    db $01 ; Magnet
    db $22 ; Supersoaker
    db $22 ; Boomerang
    db $11 ; Alarm Clock
    db $00 ; Legal Document
.end

; Assumes that the equipable is not null.
;
; Input:
; - `a`: Base tile index
; - `b`: Attributes (Supports horizontal flip; Palette ID is added to icon's own values)
; - `c`: Equipable ID
; - `d`: Vertical sprite coordinate
; - `e`: Horizontal sprite coordinate
; - `h`: High-pointer to `OAMMIRROR_T` struct
;
; Destroys: `af`, `c`, `l`
; Saves: `b`, `de`, `h`
DrawEquipableIcon::
    ; Spill parameters to HRAM to save registers
    ldh [hDrawEquipableIconLocals.baseTileIndex], a
    ld a, b
    ldh [hDrawEquipableIconLocals.attributes], a

    ; Get palettes
    ld b, HIGH(EquipableIconPaletteIndices)
    ld a, [bc]
    ld c, a

    ; Allocate sprites
    ld b, 2 * 4
    call SpriteGet

    ; Unspill attributes
    ldh a, [hDrawEquipableIconLocals.attributes]
    ld b, a

    ; Write position of left half
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a

    ; Write tile ID of left half
    ldh a, [hDrawEquipableIconLocals.baseTileIndex]
    bit OAMB_XFLIP, b
    jr z, :+
        add a, 2
        ld [hl+], a
        jr :++
    :
        ld [hl+], a
        add a, 2
        ldh [hDrawEquipableIconLocals.baseTileIndex], a
    :

    ; Write attributes of left half
    ld a, c
    and a, 7
    add a, b
    ld [hl+], a

    ; Write position of right half
    ld a, d
    ld [hl+], a
    ld a, e
    add a, 8
    ld [hl+], a

    ; Write tile ID of right half
    ldh a, [hDrawEquipableIconLocals.baseTileIndex]
    ld [hl+], a

    ; Write attributes of right half
    ld a, c
    swap a
    and a, 7
    add a, b
    ld [hl+], a
    
    ret
;

SECTION UNION "LOCALVARS", HRAM
hDrawEquipableIconLocals:
    .attributes: ds 1
    .baseTileIndex: ds 1
.end