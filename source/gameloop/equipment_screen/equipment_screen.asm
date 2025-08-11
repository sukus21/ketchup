; The equipment screen is implemented as a returning gameloop,
; allowing it to be incorporated into various scenes.

INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gamestate/gamestate.inc"
INCLUDE "macro/color.inc"
INCLUDE "macro/memcpy.inc"

DEF HARDCODED_INVENTORY EQU 1

SECTION "EQUIPMENT SCREEN", ROM0

GameloopEquipmentScreen::
    ld b, KEY1F_DBLSPEED | KEY1F_PREPARE
    call SetCPUSpeed

    IF HARDCODED_INVENTORY
        ld hl, wEquipmentScreenVars
        xor a
        REPT 12
            ld [hl+], a
            inc a
        ENDR
    ELSE
        ld hl, wEquipmentScreenVars
        ld de, wGameStatePlayerEquipment
        ld c, 9
        :
            ld a, [de]
            ld [hl+], a
            inc e

            dec c
            jr nz, :-
        ;

        FOR I, 3
            ldh a, [hEquipmentScreenVars.offers + I]
            ld [hl+], a
        ENDR
    ENDC

    xor a, a
    ldh [hEquipmentScreenVars.flags], a
    ldh [hEquipmentScreenVars.clear], a
    ldh [hEquipmentScreenVars.cursor], a
    cpl 
    ldh [hEquipmentScreenVars.select], a

    ld hl, wStatusHudConfig.endOfHudHandler
    ld a, LOW(EquipmentScreenEndHud)
    ld [hl+], a
    ld [hl], HIGH(EquipmentScreenEndHud)

    ld a, [wEquipmentScreenVars.slotShuffle + 0]
    ld b, a
    call EquipableDescSetItem

    vqueue_enqueue GameloopEquipmentScreenInitTransfer
    vqueue_enqueue LoadEquipables
    call GameloopLoading

    ; Do initial VBlank
    call WaitVBlank
    call GameloopBattleVBlank

    ld b, KEY1F_PREPARE
    call SetCPUSpeed

    .loop:
        call ReadInput
        call AcceptControls

        ld hl, wEquipmentScreenVars.slotShuffle
        ld b, 5
        ld de, (44 << 8) + 44
        .inventorySpriteLoop
            ld a, [hl+]
            ld c, a

            add a, a
            add a, a
            add a, 64

            push hl
            ld h, HIGH(wOAM)
            call DrawEquipableIcon
            pop hl

            ld a, e
            add a, 24
            ld e, a
            cp a, 44 + 24 * 3
            jr nz, .inventorySpriteLoop

            ld e, 44
            ld a, d
            add a, 24
            ld d, a
            cp a, 44 + 24 * 3
            jr nz, .inventorySpriteLoop
        ;

        ld de, (44 << 8) | 132
        .offerSpriteLoop
            ld a, [hl+]
            ld c, a

            add a, a
            add a, a
            add a, 64

            ld b, 5
            
            push hl
            ld h, HIGH(wOAM)
            call DrawEquipableIcon
            pop hl

            ld a, d
            add a, 24
            ld d, a
            cp a, 44 + 24 * 3
            jr nz, .offerSpriteLoop
        ;

        ld h, HIGH(wOAM)
        ld de, (43 + 2 * 24) << 8 | 16
        ld c, 2
        :
            call DrawCharacterFace

            dec c

            ld a, d
            sub a, 24
            ld d, a

            cp a, 43
            jr nc, :-
        ;

        ld h, high(wOAM)
        call SpriteFinish

        call EquipableDescRenderStep

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

        ; Do OAM DMA
        ld a, high(wOAM)
        call hDMA

        ldh a, [hEquipmentScreenVars.flags]
        bit 0, a
        jr z, :+

            ldh a, [hEquipmentScreenVars.clear]
            call ResetCellPalette

            ldh a, [hEquipmentScreenVars.cursor]
            ld b, a
            ld d, 4
            call SetCellPalette

            ldh a, [hEquipmentScreenVars.select]
            ld b, a
            ld d, 5
            call SetCellPalette

            jr :++
        :
            call EquipableDescUpload
        :

        call DisplayHud

        ei 

        jp .loop
    ;
;

LoadEquipables:
    xor a, a
    ldh [rVBK], a

    ld bc, _VRAM8000 + 16 * 64
    ld hl, wEquipmentScreenVars
    .loop
        ld a, [hl+]
        ld e, a
        push hl
        farcall LoadEquipableIconTiles
        pop hl

        ld a, l
        cp a, LOW(wEquipmentScreenVars + 12)
        jr nz, .loop
    ;

    ret
;

AcceptControls:
    ldh a, [hEquipmentScreenVars.cursor]
    ld d, a
    ldh [hEquipmentScreenVars.clear], a

    bit PADB_LEFT, c
    jr z, :+
        dec a
    :
    bit PADB_RIGHT, c
    jr z, :+
        inc a
    :

    bit 3, a
    jr z, :+
        inc a
    :
    swap a
    cp a, 16 * 4
    jr c, :+
        sub a, 16
    :

    bit PADB_UP, c
    jr z, :+
        dec a
    :
    bit PADB_DOWN, c
    jr z, :+
        inc a
    :

    bit 3, a
    jr z, :+
        inc a
    :
    swap a
    cp a, 16 * 3
    jr c, :+
        sub a, 16
    :

    ldh [hEquipmentScreenVars.cursor], a

    cp a, d
    call nz, ChangeDesc

    bit PADB_A, c
    jr z, .promoteEnd
        push bc
        ld b, a

        ldh a, [hEquipmentScreenVars.select]
        cp a, $FF
        jr z, :+
            call MoveSlots

            ldh a, [hEquipmentScreenVars.select]
            ldh [hEquipmentScreenVars.clear], a

            ld a, $FF
            ldh [hEquipmentScreenVars.select], a

            pop bc
            jr .promoteEnd
        :
        
        ld a, b
        and a, $0F
        cp a, 3
        jr z, :+
            xor a, b
            ldh [hEquipmentScreenVars.cursor], a

            call SwapSlots

            pop bc
            jr .promoteEnd
        :

        ld a, b
        call SlotVecToIndex
        ld h, HIGH(wEquipmentScreenVars.slotShuffle)
        ld l, a
        
        ld a, [hl]
        inc a
        jr z, :+
            ld a, b
            ldh [hEquipmentScreenVars.select], a
        :
        pop bc
    .promoteEnd

    ld a, c
    or a, a
    jr z, :+
        ld a, 1
    :
    ldh [hEquipmentScreenVars.flags], a

    bit PADB_SELECT, c
    jr z, :+
        call EquipableDescFlipPage
    :

    ret
;

DrawCharacterFace:
    ld b, 8
    call SpriteGet

    ld b, c
    sla b
    sla b

    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, c
    ld [hl+], a

    inc b
    inc b

    ld a, d
    ld [hl+], a
    ld a, e
    add a, 8
    ld [hl+], a
    ld a, b
    ld [hl+], a
    ld a, c
    ld [hl+], a
    
    ret
;

ResetCellPalette:
    ld b, a
    ld d, 1
    and a, $0F
    jr z, :+
        inc d
        cp a, 3
        jr nz, :+
        inc d
    :

    ; Fallthrough to SetCellPalette
;

SetCellPalette:
    ld a, 1
    ldh [rVBK], a

    ld hl, _SCRN0 + (32 * 3 + 4)

    ld a, b
    add a, a
    add a, b

    ld b, a
    and a, $0F
    ld c, a

    cp a, 3 * 3
    jr c, :+
        inc c
        inc c
    :

    xor a, b
    add a, a
    jr nc, :+
        inc h
    :
    or a, c

    add a, l
    ld l, a
    jr nc, :+
        inc h
    :

    ld a, [hl]
    and a, $7
    xor a, d
    ld d, a

    ld c, 3
    :
        REPT 3
            ld a, [hl]
            xor a, d
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

SlotVecToIndex:
    ld d, a

    and a, $0F
    cp a, 3
    jr nz, :+
        xor a, d
        swap a
        add a, 9
        ret
    :

    ld e, a
    xor a, d
    swap a
    ld d, a
    add a, a
    add a, d
    add a, e
    
    ret
;

SwapSlots:
    call SlotVecToIndex
    ld c, a

    ld a, b
    call SlotVecToIndex
    ld b, a

    ld h, HIGH(wEquipmentScreenVars)

    ld l, b
    ld a, [hl]

    ld l, c
    ld c, [hl]
    ld [hl], a

    ld l, b
    ld [hl], c

    ret
;

MoveSlots:
    call SlotVecToIndex
    ld c, a

    ld a, b
    call SlotVecToIndex
    ld b, a

    ld h, HIGH(wEquipmentScreenVars)
    
    ld l, c
    ld a, [hl]
    ld [hl], $FF

    ld l, b
    ld [hl], a

    ret
;

ChangeDesc:
    push bc
    push af

    call SlotVecToIndex
    ld c, a
    ld b, HIGH(wEquipmentScreenVars)
    ld a, [bc]

    ld b, a
    call EquipableDescSetItem

    pop af
    pop bc
    ret
;

EquipmentScreenEndHud:
    push af

    LYC_wait_hblank

    xor a, a
    ldh [rSCX], a
    ldh [rSCY], a

    ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    pop af
    reti 
;

SECTION UNION "LEAF GAMELOOP VARS", WRAM0, ALIGN[8]
wEquipmentScreenVars:
    .slotShuffle: ds 12
.end

SECTION UNION "LEAF GAMELOOP HRAM VARS", HRAM
hEquipmentScreenVars:

    ; Enum specifying the purpose for which the menu was opened,
    ; and what players should be allowed to do with it, such as
    ; allowing players to recieve items or only allowing them to
    ; view their current inventory.
    .mode: ds 1

    ; Up to 3 equipable IDs specifying items that players are
    ; allowed to recieve.
    .offers: ds 3

    .flags: ds 1

    ; Packed coordinates of cursor.
    ; Bits 0-3 identify column (left to right)
    ; Bits 4-7 identify row (top to bottom).
    .cursor: ds 1
    
    ; Packed coordinates of selected item slot.
    ; Bits 0-3 identify column (left to right)
    ; Bits 4-7 identify row (top to bottom).
    .select: ds 1

    ; Packed coordinates of a slot in which to switch palettes back to normal.
    ; Bits 0-3 identify column (left to right)
    ; Bits 4-7 identify row (top to bottom).
    .clear: ds 1
.end
