INCLUDE "utils.inc"

SECTION "FONT RENDERER", ROM0

; Draw a font character somewhere.
; Assumes that destinatio is 0-filled.  
; Lives in ROM0.
;
; Input:
; - `a`: Glyph ID
;
; Returns:
; - `c`: Destination pixel offset (0-7)
; - `de`: Destination tile pointer
;
; Saves: `af`, `hl`
FontDrawGlyph::
    push hl
    push af

    ; Get glyph size -> D
    ld l, a
    ld a, [wFontPointer]
    ld h, a

    ; We can take a faster path, if we only need to render onto a single tile
    ld a, [wFontDestPixel]
    ld c, a
    add a, [hl]
    cp a, 9
    jp c, FontDrawGlyphFast
    jp FontDrawGlyphSlow
;



; Optimized path, when we only need to write to one destination tile.  
; Lives in ROM0.
;
; Input:
; - `c`: `wFontDestPixel`
; - `h`: `wFontPointer`
; - `l`: Glyph ID
; - `hl`: Pointer to glyph width
;
; Returns:
; - `c`: New destination pixel offset (0-7)
; - `de`: New destination tile pointer
;
; Saves: `af`, `hl`
FontDrawGlyphFast:

    ; Read glyph width -> stack
    ld e, [hl]
    push de
    
    ; Build pointer to glyph data -> DE
    xor a
    sla l
    rla
    sla l
    rla
    sla l
    rla
    add a, h
    ld d, a
    ld e, l
    inc d

    ; Read destination poiner -> HL
    ld hl, wFontDestChar
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ; Begin pasting glyph at destination
    ld b, 8
    .loop
        ; Read pixels
        push bc
        ld a, [de]
        inc de

        ; Shift pixel data over -> A
        inc c
        .shiftLoop
            dec c
            jr z, .shifted
            rrca
            jr .shiftLoop
        .shifted

        ; Or pixel data with existing data
        ld b, a
        or a, [hl]
        ld [hl+], a
        ld a, b
        or a, [hl]
        ld [hl+], a

        ; Repeat the loop?
        pop bc
        dec b
        jr nz, .loop
    ;

    ; Update pixel offset -> C
    pop de
    ld a, e
    add a, c
    and a, %00000111
    ld c, a

    ; Move destination pointer back one tile -> DE
    jr z, :+
        ld a, l
        sub a, 16
        ld l, a
        jr nc, :+
        dec h
    :
    ld d, h
    ld e, l

    ; Write all of this to memory as well
    ld hl, wFontDestChar
    write_n16 de
    ld [hl], c

    ; Yea, we done
    pop af
    pop hl
    ret
;



; Optimized path, when we only need to write to one destination tile.  
; Lives in ROM0.
;
; Input:
; - `c`: `wFontDestPixel`
; - `h`: `wFontPointer`
; - `l`: Glyph ID
; - `hl`: Pointer to glyph width
;
; Returns:
; - `c`: New destination pixel offset (0-7)
; - `de`: New destination tile pointer
;
; Saves: `af`, `hl`
FontDrawGlyphSlow:
    
    ; Build pointer to glyph data -> DE
    xor a
    ld e, l
    sla e
    rla
    sla e
    rla
    sla e
    rla
    add a, h
    ld d, a
    inc d
    push de

    ; Read glyph width -> stack
    ld a, [hl]
    push af

    ; Read destination poiner -> HL
    ld hl, wFontDestChar
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ; Begin pasting glyph at destination
    ld b, 8
    .loopLeft
        ; Read pixels
        push bc
        ld a, [de]
        inc de

        ; Shift pixel data over -> A
        inc c
        .shiftLoopLeft
            dec c
            jr z, .shiftedLeft
            srl a
            jr .shiftLoopLeft
        .shiftedLeft

        ; Or pixel data with existing data
        ld b, a
        or a, [hl]
        ld [hl+], a
        ld a, b
        or a, [hl]
        ld [hl+], a

        ; Repeat the loop?
        pop bc
        dec b
        jr nz, .loopLeft
    ;

    ; Get new pixel destination -> C
    pop de
    ld a, d
    add a, c
    and a, %00000111
    ld c, a

    ; Get number of pixels drawn -> B
    ld a, d
    sub a, c
    ld b, a
    
    ; Write destination to memory
    ld d, h
    ld e, l
    ld hl, wFontDestChar
    write_n16 de
    ld [hl], c
    ld h, d
    ld l, e

    ; Restore glyph data pointer
    pop de
    push hl
    push bc
    ld c, b

    ; Begin pasting glyph at destination
    ld b, 8
    .loopRight
        ; Read pixels
        push bc
        ld a, [de]
        inc de

        ; Shift pixel data over -> A
        inc c
        .shiftLoopRight
            dec c
            jr z, .shiftedRight
            sla a
            jr .shiftLoopRight
        .shiftedRight

        ; This is at offset 0, just overwrite destination
        ld [hl+], a
        ld [hl+], a

        ; Repeat the loop?
        pop bc
        dec b
        jr nz, .loopRight
    ;

    ; Yea, we done
    pop bc
    pop de
    pop af
    pop hl
    ret
;



SECTION "FONT VARIABLES", WRAM0

    ; High-pointer to font data
    wFontPointer:: ds 1

    ; Font destination character
    wFontDestChar:: ds 2

    ; Font destination pixel offset (0-7)
    wFontDestPixel:: ds 1
;
