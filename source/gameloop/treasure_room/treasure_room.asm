INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gamestate/gamestate.inc"
INCLUDE "macro/color.inc"
INCLUDE "macro/memcpy.inc"

SECTION "TREASURE ROOM", ROMX, ALIGN[8]

ChestLockSpriteInfo:
    FOR I, 20
        db 144 - 56 - I * 3 / 2 - 2
        db ((I + 4) * I) / 32
    ENDR
.end

ChestOpenScanlineOffsets:
    FOR CHEST_OPENNESS, 20
        .op{d:CHEST_OPENNESS}:

        DEF CHEST_OPENNESS += CHEST_OPENNESS / 2
        
        DEF CHEST_OPENNESS_EARLY = 2 * CHEST_OPENNESS / 3

        FOR I, 19 - CHEST_OPENNESS_EARLY
            db 64 - I
        ENDR

        FOR I, 19 - (CHEST_OPENNESS - CHEST_OPENNESS_EARLY), 0, -1
            DEF T = (I * 16) / (20 - CHEST_OPENNESS / 2)
            DEF T *= T
            DEF V = (CHEST_OPENNESS / 2) * T
            db CHEST_OPENNESS - 20 - (V / 256)
        ENDR

        db CHEST_OPENNESS - 19

        IF CHEST_OPENNESS > 10
            ; Inside of lid
            FOR I, CHEST_OPENNESS - 10
                DEF T = (I * 256) / (CHEST_OPENNESS - 10)
                DEF V = -(20 - CHEST_OPENNESS) * (256 - T)
                db (V + 128) / 256
            ENDR

            ds 10, 0
        ELSE
            ds CHEST_OPENNESS, 0
        ENDC

        ds 1, 0
    ENDR
.end

GameloopTreasureRoom::
    xor a, a
    ldh [hTreasureRoomVars.animTime], a
    ldh [hTreasureRoomVars.animTime + 1], a
    ldh [hTreasureRoomVars.state], a
    ld [wTreasureRoomVars.currBuffer], a

    ld hl, wTreasureRoomVars.scanlineOffsetBuffer
    ld bc, ChestOpenScanlineOffsets.op0
    ld de, 40
    call Memcpy

    ; Clear OAM mirror
    ld bc, $00_10
    ld hl, wOAM
    call MemsetChunked

    ; Prepare this, just in case
    call OamDmaInit

    vqueue_enqueue GameloopTreasureRoomInitTransfer
    farcall_x GameloopLoading

    ; Do initial VBlank
    call WaitVBlank
    farcall_x GameloopBattleVBlank

    .loop:
        ldh a, [hTreasureRoomVars.state]
        
        or a, a
        jp nz, :++
            call ReadInput

            bit PADB_A, c
            jr z, :+
                xor a, a
                ldh [hTreasureRoomVars.animTime + 1], a
                inc a
                ldh [hTreasureRoomVars.state], a
            :

            jp .stateEnd
        :

        dec a
        jp nz, :+
            call AdvanceChestAnim
        :
        
        .stateEnd:

        ld b, 4
        ld h, HIGH(wOAM)
        call SpriteGet

        ld b, HIGH(ChestLockSpriteInfo)
        ldh a, [hTreasureRoomVars.animTime + 1]
        add a, a
        ld c, a

        ld a, [bc]
        inc bc
        ld [hl+], a
        ld a, 160 / 2 - 4 + 8
        ld [hl+], a
        ld a, [bc]
        ld [hl+], a
        xor a
        ld [hl+], a

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

        ; Do OAM DMA
        ld a, high(wOAM)
        call hDMA

        xor a, a
        ldh [rSCY], a
        ld a, -48
        ldh [hTreasureRoomVars.scanlineOffset], a

        ld a, [wTreasureRoomVars.currBuffer]
        ldh [hTreasureRoomVars.bufferOffset], a

        ld a, LCDCF_ON | LCDCF_OBJON | LCDCF_OBJ16
        ldh [rLCDC], a

        ld a, 5 * 8 - 1
        ldh [rLYC], a

        ld a, STATF_LYC
        ldh [rSTAT], a

        LYC_set_jumppoint TreasureRoomChestTop

        ei

        jp .loop
    ;
;

AdvanceChestAnim:
    ldh a, [hTreasureRoomVars.animTime]
    add a, $67
    ;add a, $27
    ldh [hTreasureRoomVars.animTime], a

    ret nc

    ldh a, [hTreasureRoomVars.animTime + 1]
    inc a
    cp a, 20
    jr nz, :+
        xor a, a
        ldh [hTreasureRoomVars.state], a
        ret
    :
    ldh [hTreasureRoomVars.animTime + 1], a

    ; Multiply animTime by 40 and store result in bc
    ld b, a
    ld c, a
    xor a, a
    sla c
    rla 
    sla c
    rla 
    ld e, a
    ld a, c
    add a, b
    jr nc, :+
        inc e
    :
    ld c, a
    ld a, e
    REPT 3
        sla c
        rla 
    ENDR
    ld b, a

    ld a, c
    add a, LOW(ChestOpenScanlineOffsets)
    ld c, a
    ld a, b
    adc a, HIGH(ChestOpenScanlineOffsets)
    ld b, a

    ld hl, wTreasureRoomVars.currBuffer
    ld a, [hl]
    xor a, 40
    ld [hl], a
    ld l, a

    ld de, 40
    jp Memcpy ; Tail call
;

SECTION "TREASURE ROOM INTERRUPTS", ROM0

TreasureRoomChestTop:
    push af

    ld a, STATF_MODE00
    ldh [rSTAT], a

    LYC_set_jumppoint TreasureRoomHBlank

    pop af
    reti 
;

TreasureRoomHBlank:
    push af
    
    ldh a, [hTreasureRoomVars.scanlineOffset]
    ldh [rSCY], a

    ldh a, [rLY]
    cp a, 39 + 5 * 8
    jr nz, :+
        xor a, a
        ldh [rSTAT], a

        pop af
        reti
    :

    push hl

    sub a, 5 * 8 - 1
    ld l, a
    ldh a, [hTreasureRoomVars.bufferOffset]
    add a, l
    ld l, a
    ld h, HIGH(wTreasureRoomVars.scanlineOffsetBuffer)

    ld a, [hl]
    ldh [hTreasureRoomVars.scanlineOffset], a

    pop hl
    pop af
    reti
;

SECTION UNION "GAMELOOP VARS", WRAM0, ALIGN[8]
wTreasureRoomVars:
    .scanlineOffsetBuffer:
    FOR I, 2
        .{d:I}: ds 40
    ENDR
    .currBuffer: ds 1
.end

SECTION UNION "GAMELOOP HRAM VARS", HRAM
hTreasureRoomVars:
    .scanlineOffset: ds 1

    .bufferOffset: ds 1

    .animTime: ds 2

    .state: ds 1
.end
