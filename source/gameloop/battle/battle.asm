INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "gameloop/battle/battle.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gameloop/battle/vram.inc"


SECTION "GAMELOOP BATTLE", ROMX

; Battle gameloop entrypoint.  
; Does not return.
;
; Destroys: all
GameloopBattle::
    farcall_x initRun

    ; Set default menu positions
    ld a, BATTLE_WINDOW_X_OPEN
    ld [wBattleDetailsX], a
    ld [wBattleMenuX], a
    ld [wBattleDetailsXTarget], a
    ld [wBattleMenuXTarget], a

    ; Set default sprite positions
    ld hl, wBattleSprite1X
    ld a, 40
    ld [hl+], a
    ld a, 60
    ld [hl+], a
    ld a, 80
    ld [hl+], a
    ld a, 90
    ld [hl+], a

    ; Clear OAM mirror
    ld bc, $00_10
    ld hl, wOAM
    call MemsetChunked

    ; Prepare this, just in case
    call OamDmaInit

    ; Transfer the required assets to VRAM
    vqueue_enqueue GameloopBattleInitTransfer
    farcall_x GameloopLoading

    ; Do initial VBlank
    call WaitVBlank
    farcall_x GameloopBattleVBlank

    ; Endless loop for now
    .loop
        ; Do things on the CPU
        call ReadInput
        call UpdateWindowTarget
        call MoveWindow
        call UpdateSpritePositions

        ; Draw test sprite 1
        ld hl, wBattleSprite1X
        ld a, [hl+]
        ld c, [hl]
        ld b, a
        ld hl, wOAM
        ld de, TemplateTestSprite1
        xor a
        call SpriteDrawTemplate

        ; Draw test sprite 2
        ld hl, wBattleSprite2X
        ld a, [hl+]
        ld c, [hl]
        ld b, a
        ld hl, wOAM
        ld de, TemplateTestSprite2
        xor a
        call SpriteDrawTemplate

        ; Done processing for this frame, finish things off
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

        ; Now in VBlank
        call GameloopBattleVBlank

        ; Repeat gameloop
        jr .loop
    ;
;



; Update sprite positions based on keys.
UpdateSpritePositions:
    ld a, [wInput]
    ld b, a

    bit PADB_A, b
    ld hl, wBattleSprite1X
    call nz, .update

    bit PADB_B, b
    ld hl, wBattleSprite2X
    call nz, .update

    ret

    .update
        bit PADB_LEFT, b
        jr z, :+
            dec [hl]
        :
        bit PADB_RIGHT, b
        jr z, :+
            inc [hl]
        :
        inc hl

        bit PADB_UP, b
        jr z, :+
            dec [hl]
        :
        bit PADB_DOWN, b
        jr z, :+
            inc [hl]
        :

        ret
    ;
;



; Updates the target positions for the menu and details.
UpdateWindowTarget:
    ld a, [wInput]

    ; Set menu X-target
    ld hl, wBattleMenuXTarget
    ld [hl], BATTLE_WINDOW_X_OPEN
    bit PADB_A, a
    jr z, :+
        ; have to add 10 or interpolation looks weird...
        ; Clamp result after interpolation
        ld [hl], BATTLE_WINDOW_X_CLOSED + 10
    :

    ; Set details X-target
    ld hl, wBattleDetailsXTarget
    ld [hl], BATTLE_WINDOW_X_OPEN
    bit PADB_B, a
    jr z, :+
        ; have to add 10 or interpolation looks weird...
        ; Clamp result after interpolation
        ld [hl], BATTLE_WINDOW_X_CLOSED + 10
    :

    ; Yup, that's all
    ret
;



; Moves the window layer using interpolation.
MoveWindow:
    ld hl, wBattleMenuX
    ld c, 2

    .loop
        ; Read current X -> D, target X -> A
        ld a, [hl+]
        ld d, a
        ld a, [hl-]

        ; Find amount to interpolate by
        sub a, d
        jr z, :+
            sra a
            sra a
            sra a
        :

        ; Add difference, with clamping
        add a, d
        cp a, BATTLE_WINDOW_X_CLOSED
        jr c, :+
            ld a, BATTLE_WINDOW_X_CLOSED
        :

        ; Store new X-position
        ld [hl+], a
        inc hl

        ; Do we loop?
        dec c
        jr nz, .loop
    ;

    ret
;


; Sprite template for battle loop
TemplateTestSprite1:
    db %11111111
    db VTI_BATTLE_TESTSPRITE_1 + $00, 0
    db VTI_BATTLE_TESTSPRITE_1 + $04, 0
    db VTI_BATTLE_TESTSPRITE_1 + $08, 0
    db VTI_BATTLE_TESTSPRITE_1 + $0C, 0
    db VTI_BATTLE_TESTSPRITE_1 + $02, 0
    db VTI_BATTLE_TESTSPRITE_1 + $06, 0
    db VTI_BATTLE_TESTSPRITE_1 + $0A, 0
    db VTI_BATTLE_TESTSPRITE_1 + $0E, 0
;

; Sprite template for battle loop
TemplateTestSprite2:
    db %11111111
    db VTI_BATTLE_TESTSPRITE_2 + $00, 0
    db VTI_BATTLE_TESTSPRITE_2 + $04, 0
    db VTI_BATTLE_TESTSPRITE_2 + $08, 0
    db VTI_BATTLE_TESTSPRITE_2 + $0C, 0
    db VTI_BATTLE_TESTSPRITE_2 + $02, 0
    db VTI_BATTLE_TESTSPRITE_2 + $06, 0
    db VTI_BATTLE_TESTSPRITE_2 + $0A, 0
    db VTI_BATTLE_TESTSPRITE_2 + $0E, 0
;



SECTION "GAMELOOP BATTLE VARIABLES", WRAM0

; X-position of the top part of the menu
wBattleMenuX:: ds 1
wBattleMenuXTarget:: ds 1

; X-position 
wBattleDetailsX:: ds 1
wBattleDetailsXTarget:: ds 1

; Determines if battle menu is ready to be shown.
wBattleMenuReady:: ds 1

wBattleSprite1X:: ds 1
wBattleSprite1Y:: ds 1
wBattleSprite2X:: ds 1
wBattleSprite2Y:: ds 1
