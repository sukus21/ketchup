    IF !DEF(BATTLE_PLAYER_INC)
    DEF BATTLE_PLAYER_INC EQU 1

INCLUDE "entsys/entsys.inc"


; Entity variables
RSSET ENTVAR_VAR

; Current player entity state
DEF ENTVAR_PLAYER_STATE RB 1

; Timer for various animations and stuff.
DEF ENTVAR_PLAYER_TIMER RB 1

; Pointer to hard facts about this character.
; Points to a BATTLE_STATS_T.
DEF ENTVAR_PLAYER_STATS RB 2

; Current X-position of this player entity.
; Not the logical position on the grid, just for visuals.
DEF ENTVAR_PLAYER_X RB 2

; Current Y-position of this player entity.
; Not the logical position on the grid, just for animations and stuff.
DEF ENTVAR_PLAYER_Y RB 2

; Entry in CHARID enum.
DEF ENTVAR_PLAYER_CHARID RB 1



; Player states
RSRESET

; Character is idle, waiting for game state to change
DEF PLAYER_STATE_IDLE RB 1

; Character is performing an action
DEF PLAYER_STATE_ACTION RB 1

; Player character is currently being moved
DEF PLAYER_STATE_MOVEMENT RB 1

; Action selected, action/item is being selected for character
DEF PLAYER_STATE_MENUING RB 1

    ENDC

