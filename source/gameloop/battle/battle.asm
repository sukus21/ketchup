INCLUDE "hardware.inc/hardware.inc"
INCLUDE "vqueue/vqueue.inc"


SECTION "GAMELOOP BATTLE", ROMX

; Battle gameloop entrypoint.  
; Does not return.
;
; Destroys: all
GameloopBattle::

    ; Transfer the required assets to VRAM
    vqueue_enqueue GameloopBattleInitTransfer
    call GameloopLoading

    ; Endless loop for now
    jr @-2
;
