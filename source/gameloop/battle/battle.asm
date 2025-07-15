INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"
INCLUDE "macro/lyc.inc"
INCLUDE "gameloop/battle/battle.inc"


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

    ; Transfer the required assets to VRAM
    vqueue_enqueue GameloopBattleInitTransfer
    call GameloopLoading

    ; Do initial VBlank
    call WaitVBlank
    call GameloopBattleVBlank

    ; Endless loop for now
    .loop
        ; Do things on the CPU
        call ReadInput

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



SECTION "GAMELOOP BATTLE VARIABLES", WRAM0

; X-position of the top part of the menu
wBattleMenuX:: ds 1

; X-position 
wBattleDetailsX:: ds 1

; Determines if battle menu is ready to be shown.
wBattleMenuReady:: ds 1

