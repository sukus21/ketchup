    IF !DEF(BATTLE_ACTOR_INC)
    DEF BATTLE_ACTOR_INC EQU 1


; Character battle state
RSRESET

; Character health
DEF BATTLE_STATS_HP RB 1

; Current number of action points
DEF BATTLE_STATS_AP RB 1

; Grid X-position
DEF BATTLE_STATS_X RB 1

; Grid Y-position
DEF BATTLE_STATS_Y RB 1

; Current delay time
DEF BATTLE_STATS_ACTION_DELAY RB 1

; ROM Bank of action routine
DEF BATTLE_STATS_ACTION_BANK RB 1

; Action routine pointer
DEF BATTLE_STATS_ACTION RB 2

; Keeps track of stats and state of battle objects.
; HP, AP, grid position, action/delay state etc. is all stored here.
DEF BATTLE_STATS_T RB 0



; Character IDs
RSRESET

DEF CHARID_HERBERT RB 1
DEF CHARID_MENJA RB 1
DEF CHARID_DUFFIN RB 1

    ENDC
