INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/color.inc"

SECTION "MAPVIEW DATA", ROMX, ALIGN[8]

pathLut:
    ; ...
    db 0, 0, 0, 0
    db 0, 0, 0, 0

    ; |..
    db 32, 0, 0, 0
    db 32, 0, 0, 0
    
    ; ./.
    db 0, 34, 30, 29
    db 29, 30, 34, 0

    ; |/.
    db 32, 34, 30, 29
    db 33, 30, 34, 0

    ; .\.
    db 29, 30, 34, 0
    db 0, 34, 30, 29

    ; |\.
    db 33, 30, 34, 0
    db 32, 34, 30, 29

    ; .X.
    db 29, 31, 30, 29
    db 29, 30, 31, 29

    ; |X.
    db 33, 31, 30, 29
    db 33, 30, 31, 29
    
    ; ..|
    db 0, 0, 0, 32
    db 0, 0, 0, 32

    ; |.|
    db 32, 0, 0, 32
    db 32, 0, 0, 32

    ; ./|
    db 0, 34, 30, 33
    db 29, 30, 34, 32

    ; |/|
    db 32, 34, 30, 33
    db 33, 30, 34, 32

    ; .\|
    db 29, 30, 34, 32
    db 0, 34, 30, 33

    ; |\|
    db 33, 30, 34, 32
    db 32, 34, 30, 33

    ; .X|
    db 29, 31, 30, 33
    db 29, 30, 31, 33

    ; |X|
    db 33, 31, 30, 33
    db 33, 30, 31, 33

GameloopMapviewInitTransfer::
    ld a, BANK(wGameStateMapRoomData)
    ld [rSMBK], a

    xor a, a
    ldh [rSCX], a
    ldh [rSCY], a

    ; Load palettes
    ld hl, Pallete
    xor a
    REPT 6
        call PaletteCopyBG
    ENDR

    xor a
    REPT 2
        call PaletteCopyOBJ
    ENDR

    ; Load tileset
    xor a
    ldh [rVBK], a

    ld bc, TilesetGridTiles
    ld hl, _VRAM9000
    ld d, 51
    call MemcpyTile2BPP

    ; Load sprite tileset
    ld bc, SpriteTiles
    ld hl, _VRAM8000
    ld d, 6
    call MemcpyTile2BPP
    
    ; Load pointer to tilemap
    ld hl, _SCRN0

    ld de, wGameStateMapRoomData

    call EmptyRow

    ld b, 7
    :
        call RoomIconRow
        ld a, e
        sub a, 5
        ld e, a
        call RoomIconRow

        ; Make two rows empty
        call PathRow
        ld a, e
        sub a, 5
        ld e, a
        call PathRow
        ld a, e
        sub a, 5
        ld e, a

        dec b
        jr nz, :-
    ;

    call RoomIconRow
    ld a, e
    sub a, 5
    ld e, a
    call RoomIconRow

    call EmptyRow

    ; Render HUD
    ld hl, _SCRN1
    
    xor a, a
    ldh [rVBK], a

    ; Top row
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

    ; Middle row
    call FillHudInfo

    ld a, l
    add a, 11
    ld l, a

    ; Bottom row
    ld a, 40
    ld c, 5
    :
        REPT 4
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ; Attributes

    ld a, 1
    ldh [rVBK], a
    
    ld hl, _SCRN1

    ; Top row
    ld a, 4
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

    ; Middle row
    ld a, 4
    ld c, 2
    :
        REPT 5
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld a, 5
    ld c, 2
    :
        REPT 5
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ld a, l
    add a, 11
    ld l, a

    ; Bottom row
    ld a, 5
    ld c, 5
    :
        REPT 4
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;
    ld [hl+], a

    ret

UpdateStatusHud::
    ld hl, _SCRN1 + 32

    xor a, a
    ldh [rVBK], a
    
    ; Fall through to FillHudInfo

FillHudInfo:
    ld bc, wGameStateCharacterHealth

    ; Character health
    FOR I, 3
        ; Margin/Padding
        xor a, a
        ld [hl+], a
        
        ; Character icon
        ld a, 35 + I
        ld [hl+], a
        
        ; "HP:"
        ld a, 38
        ld [hl+], a

        ; Tens' digit
        ld a, [bc]
        swap a
        and a, $0F
        add a, 41
        ld [hl+], a

        ; Ones' digit
        ld a, [bc]
        and a, $0F
        add a, 41
        ld [hl+], a

        ; Advance
        inc c
    ENDR

    ; Padding
    xor a, a
    ld [hl+], a

    ; Show money

    ; "$:"
    ld a, 39
    ld [hl+], a

    ; Houndreds' digit
    ld a, [bc]
    add a, 41
    ld [hl+], a
    
    inc c

    ; Tens' digit
    ld a, [bc]
    swap a
    and a, $0F
    add a, 41
    ld [hl+], a

    ; Ones' digit
    ld a, [bc]
    and a, $0F
    add a, 41
    ld [hl+], a

    ; Final margin tile
    xor a, a
    ld [hl+], a

    ret

EmptyRow:
    ; Set VRAM bank to 0
    xor a, a
    ldh [rVBK], a

    ; Set tile IDs
    ld c, 5
    :
        REPT 4
            ld [hl+], a
        ENDR

        dec c
        jr nz, :-
    ;

    ; Set VRAM bank to 1
    inc a
    ldh [rVBK], a

    ; Set tile attributes
    xor a, a
    dec hl
    ld c, 5
    :
        REPT 4
            ld [hl-], a
        ENDR

        dec c
        jr nz, :-
    ;
    inc hl

    ; Increase l to skip the off-screen part of the row
    ld a, l
    add a, 32
    ld l, a

    ; If l becomes zero, increase h before returning
    ret nz
    inc h
    ret

RoomIconRow:
    ; Set VRAM bank to 0
    xor a, a
    ldh [rVBK], a

    ; Set tile IDs
    ld c, 5
    .tileIdLoop:
        ; Empty tile to the left
        ld [hl+], a

        ; Get room type
        ld a, [de]
        and a, $0F

        ; Draw empty tiles if room is inaccessible
        jr z, .emptyIconTileId

        ; Adjust a so that the lower half of the icons are used on even rows
        bit 5, l
        jr nz, :+
            add a, 7
        :

        ; Calculate the ID of the left tile
        add a, a
        dec a

        ; Write the left and right tile
        ld [hl+], a
        inc a
        ld [hl+], a

        ; Empty tile to the right
        xor a, a
        ld [hl+], a

        ; Loop
        inc e
        dec c
        jr nz, .tileIdLoop
        jr .tileIdLoopEnd

        .emptyIconTileId:
        ; Just empty tiles
        ld [hl+], a
        ld [hl+], a
        ld [hl+], a
        
        ; Loop
        inc e
        dec c
        jr nz, .tileIdLoop
    .tileIdLoopEnd

    ; Set VRAM bank to 1
    inc a
    ldh [rVBK], a

    ; Put tile pointer back at collum 0
    ld a, l
    sub a, 20
    ld l, a

    ; Also bring back room info pointer
    ld a, e
    sub a, 5
    ld e, a

    ; Loop expects a = 0
    xor a, a

    ; Set tile attributes
    ld c, 5
    .tileAttribLoop:
        ; Empty tile to the left
        ld [hl+], a

        ; Set different tile attributes if this room is not inaccessible
        ld a, [de]
        or a, a
        ld a, 0
        jr z, :+
            ; Pallete 1, no other non-zero attributes
            ld a, 1
        :

        ; Set left and right tile attributes
        ld [hl+], a
        ld [hl+], a

        ; Empty tile to the right
        xor a, a
        ld [hl+], a

        ; Loop
        inc e
        dec c
        jr nz, .tileAttribLoop
    ;

    ; Increase l to skip the off-screen part of the row
    ld a, l
    add a, 12
    ld l, a

    ; If l becomes zero, increase h before returning
    ret nz
    inc h
    ret

PathRow:
    push bc

    ; Set VRAM bank to 0
    xor a, a
    ldh [rVBK], a

    xor a, a
    ld [hl+], a

    xor a, a
    ld b, a

    ld a, [de]
    inc e
    REPT 3
        sla a
        rr b
    ENDR
    
    xor a
    bit 6, b
    jr z, :+
        ld a, 32
    :
    ld [hl+], a

    ld c, 4
    .idLoop:
        ld a, [de]
        REPT 3
            sla a
            rr b
        ENDR

        ld a, b
        and a, $78

        push de

        ld d, HIGH(pathLut)

        ld e, a

        bit 5, l
        jr nz, :+
            set 2, e
        :

        res 7, e

        REPT 4
            ld a, [de]
            ld [hl+], a
            inc e
        ENDR

        pop de

        inc e
        dec c
        jr nz, .idLoop
    ;

    xor a, a
    bit 6, b
    jr z, :+
        ld a, 32
    :
    ld [hl+], a

    xor a, a
    ld [hl+], a

    ; Set VRAM bank to 0
    inc a
    ldh [rVBK], a

    ld a, l
    sub a, 20
    ld l, a

    ; Set tile attributes
    ld c, 5
    .tileAttribLoop:
        ld a, $60
        bit 5, l
        jr z, :+
            res 6, a
        :

        ld b, $20
        ld [hl+], a
        xor a, b
        ld [hl+], a
        xor a, b
        ld [hl+], a
        xor a, b
        ld [hl+], a

        ; Loop
        dec c
        jr nz, .tileAttribLoop
    ;

    ld bc, 12
    add hl, bc

    pop bc
    ret

; Tile data
TilesetGridTiles:
    .empty: ds 16, 0
    .room_icons: INCBIN "gameloop/mapview/room_icons.2bpp"
    .paths: INCBIN "gameloop/mapview/paths.2bpp"
    .char_icons: INCBIN "gameloop/mapview/char_icons.2bpp"
    .numbers: INCBIN "gameloop/mapview/numbers.2bpp"
.end

SpriteTiles:
    INCBIN "gameloop/mapview/sprites.2bpp"
.end

Pallete:
    ; Background + Default path
    color_rgb8 $30, $28, $28
    color_rgb8 $00, $00, $10
    color_rgb8 $60, $40, $20
    color_rgb8 $40, $C0, $90

    ; Background + Icon
    color_rgb8 $30, $28, $28
    color_rgb8 $00, $00, $10
    color_rgb8 $80, $72, $1a
    color_rgb8 $d3, $ca, $00

    ; Select path A
    color_rgb8 $40, $38, $30
    color_rgb8 $00, $00, $10
    color_rgb8 $40, $C0, $90
    color_rgb8 $50, $F0, $A0

    ; Select path B
    color_rgb8 $40, $38, $30
    color_rgb8 $00, $00, $10
    color_rgb8 $50, $F0, $A0
    color_rgb8 $40, $C0, $90

    ; Menu with Green and Blue
    color_rgb8 $30, $4A, $58
    color_rgb8 $00, $00, $00
    color_rgb8 $20, $F0, $30
    color_rgb8 $40, $10, $E0

    ; Menu with Red and Shade
    color_rgb8 $30, $4A, $58
    color_rgb8 $00, $00, $00
    color_rgb8 $F0, $10, $10
    color_rgb8 $20, $2A, $38
;

SpritePalette:
    ; Green
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_t 5, 28, 4
    color_t 3, 20, 2

    ; Grey
    color_t 0, 0, 0
    color_t 0, 0, 0
    color_t 10, 10, 10
    color_t 3, 3, 3
;
