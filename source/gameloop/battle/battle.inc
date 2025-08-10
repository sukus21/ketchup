    IF !DEF(GAMELOOP_BATTLE_INC)
    DEF GAMELOOP_BATTLE_INC EQU 1

INCLUDE "gameloop/battle/vram.inc"
INCLUDE "struct/battle_stats.inc"


; X-position for when the window is out of frame
DEF BATTLE_WINDOW_X_CLOSED EQU 159 + 7
DEF BATTLE_WINDOW_X_OPEN EQU 88 + 7

DEF BATTLE_WINDOW_Y_MENU EQU 90
DEF BATTLE_WINDOW_Y_DETAILS EQU 101

; Camera base offset
DEF BATTLE_CAMERA_X0 EQU VMI_BATTLE_BASE_X0*8
DEF BATTLE_CAMERA_Y0 EQU VMI_BATTLE_BASE_Y0*8

; Amount of AP to restore after every action
DEF BATTLE_AP_RESTORE EQU 3


; Battle states
RSRESET

; Battle just started, play entry animations and whatnot
DEF BATTLE_STATE_OPENING RB 1

; Tick down delay counters
DEF BATTLE_STATE_COUNTDOWN RB 1

; Play an action animation
DEF BATTLE_STATE_ACTION RB 1

; Enemies moving and chosing actions
DEF BATTLE_STATE_ENEMY RB 1

; Playable character movement
DEF BATTLE_STATE_MOVEMENT RB 1

; Playable character is selecting an item
DEF BATTLE_STATE_MENU_ITEM RB 1

; Playable character is selecting an action
DEF BATTLE_STATE_MENU_ACTION RB 1

; Player loses
DEF BATTLE_STATE_DEFEAT RB 1

; Player wins
DEF BATTLE_STATE_VICTORY RB 1



; Converts a character ID to a `BATTLE_STATS_T` pointer.
;
; Input:
; - `a`: `CHARID` item
; - `1`: Pointer destination (r16)
; - `2*`: Offset to low-pointer (n8, optional)
;
; Returns:
; - Register `1`: `BATTLE_STATS_T` pointer
;
; Destroys: `af`
MACRO battle_charid_to_statptr
    STATIC_ASSERT BATTLE_STATS_T == 8
    add a, a
    add a, a
    add a, a
    IF _NARG == 2
        add a, low(wBattleStats) + \2
    ELSE
        add a, low(wBattleStats)
    ENDC
    ld low(\1), a
    xor a
    adc a, high(wBattleStats)
    ld high(\1), a
ENDM



; Converts X/Y coordinates to a pointer to the thing.
;
; Input:
; - `1`: X-coordinate (r8/n8)
; - `2`: Y-coordinate (r8/n8)
; - `3`: Destination (r16)
;
; Returns:
; - `3`: `wBattleMovementGrid` + \2*3 + \1
MACRO battle_coords_to_movement_grid
    ASSERT wBattleMovementGrid & 0xF == 0
    ld a, \2
    add a, a
    add a, \2
    add a, \1
    add a, low(wBattleMovementGrid)
    ld low(\3), a
    ld high(\3), high(wBattleMovementGrid)
ENDM

    ENDC
