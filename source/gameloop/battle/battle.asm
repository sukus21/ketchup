INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "gameloop/battle/battle.inc"
INCLUDE "macro/farcall.inc"


SECTION "GAMELOOP BATTLE", ROMX

; Battle gameloop entrypoint.  
; Does not return.
;
; Destroys: all
GameloopBattle::

    ; Set default menu positions
    ld a, BATTLE_WINDOW_X_OPEN
    ld [wBattleDetailsX], a
    ld [wBattleMenuX], a
    ld [wBattleDetailsXTarget], a
    ld [wBattleMenuXTarget], a

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



SECTION "GAMELOOP BATTLE VARIABLES", WRAM0

; X-position of the top part of the menu
wBattleMenuX:: ds 1
wBattleMenuXTarget:: ds 1

; X-position 
wBattleDetailsX:: ds 1
wBattleDetailsXTarget:: ds 1

; Determines if battle menu is ready to be shown.
wBattleMenuReady:: ds 1

