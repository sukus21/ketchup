    IF !DEF(HUD_VRAM_INC)
    DEF HUD_VRAM_INC EQU 1

INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/tilemap.inc"


; Background palettes
RSSET 6
    DEF BGPAL_HUD RB 2
    DEF BGPAL_HUD_HERBERT_AND_MENJA EQU BGPAL_HUD + 0
    DEF BGPAL_HUD_DUFFIN_AND_SHADING EQU BGPAL_HUD + 1
STATIC_ASSERT _RS <= 8


; Block 2-1
RSSET $60
    DEF EQRB EQUS "$9000 + $10 * _RS"

    ; HUD tileset address
    DEF VT_HUD EQU EQRB
    DEF VTI_HUD RB 16

    DEF VTI_HUD_ICON_HERBERT EQU VTI_HUD + 0
    DEF VTI_HUD_ICON_MENJA EQU VTI_HUD + 1
    DEF VTI_HUD_ICON_DUFFIN EQU VTI_HUD + 2
    DEF VTI_HUD_HP EQU VTI_HUD + 3
    DEF VTI_HUD_DOLLAR EQU VTI_HUD + 4
    DEF VTI_HUD_BORDER EQU VTI_HUD + 5
    DEF VTI_HUD_NUMBERS EQU VTI_HUD + 6
STATIC_ASSERT _RS <= $80


; SCRN1
    tilemap_alloc _SCRN1, "VM_HUD", 0, 30, 20, 2
    ; Location of HUD on SCRN1.
    ; To use the HUD in multiple gameloops, keep this region clear.
    ; Occupies a 20x2 area.
    DEF VM_HUD EQU tlmv_addr
tilemap_alloc_finish

    ENDC
