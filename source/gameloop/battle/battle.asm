INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "gameloop/battle/battle.inc"
INCLUDE "macro/farcall.inc"
INCLUDE "gameloop/battle/vram.inc"
INCLUDE "struct/battle_stats.inc"


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

    ; Reset camera position
    xor a
    ld hl, wBattleCameraX
    REPT 4
        ld [hl+], a
    ENDR

    ; Initialize state
    ld a, BATTLE_STATE_MOVEMENT
    ld [wBattleState], a

    ; Initialize battle states
    ; TODO: HP should be carried over from somewhere else
    ld hl, wBattleStats
    ld bc, $00_18
    call MemsetShort

    ; Clear OAM mirror
    ld h, high(wOAM)
    call SpriteInit

    ; Prepare this, just in case
    call OamDmaInit
    call EntsysInit

    ; Initialize player characters
    ld hl, wBattleStatsHerbert + BATTLE_STATS_X
    ld a, 2
    ld [hl+], a
    add a, 2
    ld [hl+], a
    ld bc, wBattleStatsHerbert
    ld d, CHARID_HERBERT
    farcall_x EntityBattlePlayerCreate

    ld hl, wBattleStatsMenja + BATTLE_STATS_X
    ld a, 1
    ld [hl+], a
    add a, 2
    ld [hl+], a
    ld bc, wBattleStatsMenja
    ld d, CHARID_MENJA
    farcall_x EntityBattlePlayerCreate

    ld hl, wBattleStatsDuffin + BATTLE_STATS_X
    ld a, 0
    ld [hl+], a
    add a, 2
    ld [hl+], a
    ld bc, wBattleStatsDuffin
    ld d, CHARID_DUFFIN
    farcall_x EntityBattlePlayerCreate

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
        farcall_x EntsysStep
        call UpdateWindowTarget
        call MoveWindow

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

    ; Camera X-position
    wBattleCameraX:: ds 2

    ; Camera Y-position
    wBattleCameraY:: ds 2

    ; Current state of battle
    wBattleState:: ds 1
ENDSECTION


SECTION "BATTLE STATS", WRAM0, ALIGN[3]

    ; Contains the battle state for player characters and enemies.
    wBattleStats::

    wBattleStatsHerbert:: ds BATTLE_STATS_T
    wBattleStatsMenja:: ds BATTLE_STATS_T
    wBattleStatsDuffin:: ds BATTLE_STATS_T

    wBattleStatsEnemy1:: ds BATTLE_STATS_T
    wBattleStatsEnemy2:: ds BATTLE_STATS_T
;
