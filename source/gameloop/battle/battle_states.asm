INCLUDE "gameloop/battle/battle.inc"
INCLUDE "struct/battle_stats.inc"


SECTION "BATTLE STATES", ROMX

    ; Handle the battle state.
    ;
    ; Destroys: all
    BattleStep::
        ld a, [wBattleState]

        ; Beeg switch-case statement
        cp a, BATTLE_STATE_OPENING
        jp z, BattleStateOpening
        cp a, BATTLE_STATE_COUNTDOWN
        jp z, BattleStateCountdown
        cp a, BATTLE_STATE_ACTION
        jp z, BattleStateAction

        ; No known state found :(
        rst VecError
    ;



    ; Handles the battle opening state.
    BattleStateOpening:
        rst VecError
    ;



    ; How many delay frames between each delay tick
    DEF BATTLE_COUNTDOWN_TIMER EQU 4

    ; Changes battle state to the countdown state.
    ;
    ; Destroys: `a`
    BattleChangeStateCountdown::
        ld a, BATTLE_COUNTDOWN_TIMER
        ld [wBattleTimer], a
        ld a, BATTLE_STATE_COUNTDOWN
        ld [wBattleState], a
        ret
    ;

    ; Handles the battle opening state.
    BattleStateCountdown:

        ; Do we tick timers down?
        ld hl, wBattleTimer
        dec [hl]
        ret nz
        ld [hl], BATTLE_COUNTDOWN_TIMER

        ; Is first entry at 0 delays?
        ld a, [wBattleTurnOrder]
        inc a ; cp a, $FF
        jr z, @+1 ; rst z, VecError
        dec a
        battle_charid_to_statptr hl, BATTLE_STATS_ACTION_DELAY
        ld a, [hl]
        or a, a ; cp a, 0
        jr z, BattleChangeStateAction
        
        ; Loop through all characters in the turn order, and decrement their delay timer
        ld de, wBattleTurnOrder
        .loop

            ; Get stats pointer -> DE
            ld a, [de]
            inc de
            inc a ; cp a, $FF
            ret z
            dec a
            battle_charid_to_statptr hl, BATTLE_STATS_ACTION_DELAY

            ; Decrement delay
            dec [hl]
            jr nz, .loop

            ; If counter hits 0, set B to 1
            ld b, 1
            jr .loop
        ;
    ;



    ; Begin the action state.
    ;
    ; 
    BattleChangeStateAction::
        ld a, BATTLE_STATE_ACTION
        ld [wBattleState], a

        ; Set current char and remove them from list
        ld a, [wBattleTurnOrder]
        ld [wBattleCurrentChar], a
        call BattleRemoveFromQueue

        ret
    ;

    ; Action battle state, waiting for character entity to hijack execution.
    BattleStateAction:
        ret
    ;

ENDSECTION
