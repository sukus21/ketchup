INCLUDE "gameloop/battle/battle.inc"
INCLUDE "struct/battle_stats.inc"
INCLUDE "macro/relpointer.inc"


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



    ; Ends the current action.
    ; Depending on which character performed the action, different things will happen.
    ;
    ; Destroys: all
    BattleEndAction::
        ld a, [wBattleCurrentChar]
        ld b, a
        battle_charid_to_statptr hl
        relpointer_init l, 0

        ; Increase characters AP
        relpointer_move BATTLE_STATS_AP
        ld a, [hl]
        add a, BATTLE_AP_RESTORE
        ld [hl], a

        ; Change battle state depending on character
        ld a, b
        cp a, CHARID_ENEMY1
        jp c, BattleChangeStateMovement
        jp nc, BattleChangeStateEnemy
        relpointer_destroy
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

    ; Action battle state.
    ; Waiting for character entity to hijack execution.
    BattleStateAction:
        ret
    ;



    ; Begin the movement state.
    ;
    ; Destroys: all
    BattleChangeStateMovement::
        ld a, BATTLE_STATE_MOVEMENT
        ld [wBattleState], a
        ret
    ;

    ; Player movement state.
    ; Waiting for player entity to hijack execution.
    BattleStateMovement:
        ret
    ;



    ; Begin the enemy state.
    ;
    ; Destroys: all
    BattleChangeStateEnemy::
        ld a, BATTLE_STATE_ENEMY
        ld [wBattleState], a
        ret
    ;

    ; Enemy decision and movement state.
    ; Waiting for enemy entity to hijack execution.
    BattleStateEnemy:
        ret
    ;

ENDSECTION
