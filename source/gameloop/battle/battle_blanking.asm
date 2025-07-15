INCLUDE "hardware.inc/hardware.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "gameloop/battle/battle.inc"


SECTION "GAMELOOP BATTLE HBLANK+VBLANK", ROM0

; VBlank routine for the tower gameloop.  
; Lives in ROM0.
;
; Saves: none
GameloopBattleVBlank::

    ; Reset window position
    ld a, [wBattleMenuX]
    ldh [rWX], a
    xor a
    ldh [rWY], a

    ; Do OAM DMA
    ; TODO: sprites

    ; Process VQueue jobs
    call VQueueExecute

    ; Oh, is it over?
    ; Set LYC interrupt handler
    LYC_set_jumppoint GameloopBattleHBlankMenu
    ld a, BATTLE_WINDOW_Y_MENU
    ldh [rLYC], a

    ; Set STAT mode
    ld a, STATF_LYC
    ldh [rSTAT], a

    ; Reset and enable LYC + VBlank interrupts
    ld a, IEF_STAT | IEF_VBLANK
    ldh [rIE], a
    xor a
    ldh [rIF], a

    ; Yeah, I think that about does it
    reti
;



; HBlank routine for hiding the menu from view.  
; Lives in ROM0.
;
; Saves: all
GameloopBattleHBlankMenu::
    push af

    ; Set window position
    ld a, BATTLE_WINDOW_X_CLOSED
    ldh [rWX], a

    ; Prepare next interrupt
    LYC_set_jumppoint GameloopBattleHBlankDetails
    ld a, BATTLE_WINDOW_Y_DETAILS
    ldh [rLYC], a

    ; Return
    pop af
    reti
;



; HBlank routine responsible for bringing the details pane back into view.  
; Lives in ROM0.
;
; Saves: all
GameloopBattleHBlankDetails::
    push af

    ; Set window position
    ld a, [wBattleDetailsX]
    ldh [rWX], a
    
    ; Yup, that's all
    pop af
    reti
;
