    IF !DEF(GAMELOOP_BATTLE_INC)
    DEF GAMELOOP_BATTLE_INC EQU 1

INCLUDE "gameloop/battle/vram.inc"

; X-position for when the window is out of frame
DEF BATTLE_WINDOW_X_CLOSED EQU 159 + 7
DEF BATTLE_WINDOW_X_OPEN EQU 88 + 7

DEF BATTLE_WINDOW_Y_MENU EQU 90
DEF BATTLE_WINDOW_Y_DETAILS EQU 101

; Camera base offset
DEF BATTLE_CAMERA_X0 EQU VMI_BATTLE_BASE_X0*8
DEF BATTLE_CAMERA_Y0 EQU VMI_BATTLE_BASE_Y0*8


; Battle states
RSRESET

; Battle just started, play entry animations and whatnot
DEF BATTLE_STATE_OPENING RB 1

; Tick down delay counters
DEF BATTLE_STATE_TICK RB 1

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

    ENDC
