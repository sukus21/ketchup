    IF !DEF(BATTLE_VRAM_INC)
    DEF BATTLE_VRAM_INC EQU 1

INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/tilemap.inc"


; Palettes
RSRESET
    DEF PAL_BATTLE_ARENA RB 1
    DEF PAL_BATTLE_CELLS_DEFAULT RB 1
    DEF PAL_BATTLE_CELLS_EFFECT RB 1
    DEF PAL_BATTLE_MENU_DEFAULT RB 1
ASSERT _RS <= 8



; Block 0
RSSET $02
    DEF EQRB EQUS "$8000 + $10 * _RS"

    ; Test sprite region
    DEF VT_BATTLE_TESTSPRITES EQU EQRB
    DEF VTI_BATTLE_TESTSPRITES RB 0

    ; Test sprite 1
    DEF VT_BATTLE_TESTSPRITE_1 EQU EQRB
    DEF VTI_BATTLE_TESTSPRITE_1 RB 16

    ; Test sprite 2
    DEF VT_BATTLE_TESTSPRITE_2 EQU EQRB
    DEF VTI_BATTLE_TESTSPRITE_2 RB 16
ASSERT _RS <= $80



; Block 2
RSSET $01
    REDEF EQRB EQUS "$9000 + $10 * _RS"

    DEF VT_BATTLE_CELLS EQU EQRB
    DEF VTI_BATTLE_CELLS RB 0

    ; Player grid cell graphics
    DEF VT_BATTLE_CELLS_PLAYER EQU EQRB
    DEF VTI_BATTLE_CELLS_PLAYER RB 9

    ; Enemy grid cell graphics
    DEF VT_BATTLE_CELLS_ENEMY EQU EQRB
    DEF VTI_BATTLE_CELLS_ENEMY RB 9
ASSERT _RS <= $80



; Tilemap X-index of battle scene anchor
DEF VMI_BATTLE_BASE_X0 EQU 11

; Tilemap Y-index of battle scene anchor
DEF VMI_BATTLE_BASE_Y0 EQU 1

; SCRN 0
    DEF VMI_BATTLE_CELLS_ENEMY_X EQU VMI_BATTLE_BASE_X0 + 1
    DEF VMI_BATTLE_CELLS_ENEMY_Y EQU VMI_BATTLE_BASE_Y0 + 1
    tilemap_alloc _SCRN0, "VM_BATTLE_CELLS_ENEMY", VMI_BATTLE_CELLS_ENEMY_X, VMI_BATTLE_CELLS_ENEMY_Y, 9, 6
    ; Location of the enemy cells.  
    ; Occupies an 9x6 area.  
    ; Located on `SCRN0`.
    DEF VM_BATTLE_CELLS_ENEMY EQU tlmv_addr


    DEF VMI_BATTLE_CELLS_PLAYER_X EQU VMI_BATTLE_BASE_X0 + 1
    DEF VMI_BATTLE_CELLS_PLAYER_Y EQU VMI_BATTLE_BASE_Y0 + 8
    tilemap_alloc _SCRN0, "VM_BATTLE_CELLS_PLAYER", VMI_BATTLE_CELLS_PLAYER_X, VMI_BATTLE_CELLS_PLAYER_Y, 9, 9
    ; Location of the player cells.  
    ; Occupies an 9x9 area.  
    ; Located on `SCRN0`.
    DEF VM_BATTLE_CELLS_PLAYER EQU tlmv_addr
;

    ENDC
