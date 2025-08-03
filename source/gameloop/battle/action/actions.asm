INCLUDE "macro/farcall.inc"
INCLUDE "macro/relpointer.inc"
INCLUDE "entity/battle_player/battle_player.inc"
INCLUDE "gameloop/battle/action/action.inc"


SECTION "ACTIONS", ROMX

    ; Perform an action.
    ;
    ; Input:
    ; - `b`: Action ID
    ; - `de`: Entity pointer
    PerformAction::
        
        ; Get action pointer -> HL
        ld a, b
        add a, a
        add a, low(BattleActionTable)
        ld l, a
        ld h, high(BattleActionTable)
        jr nc, :+
            inc h
        :
        ld a, [hl+]
        ld h, [hl]
        ld l, a

        ; Ok, now jump to that routine
        ld a, [hl+]
        ld b, a
        ld a, [hl+]
        ld h, [hl]
        ld l, a
        jp Farcall0
    ;


    ; Table of pointers to all actions
    BattleActionTable::
        dw .none
        dw 
        
        .none
            db bank(BattleActionNone)       ; action ROMX bank
            dw BattleActionNone             ; step routine pointer
            dw BattleActionNoneIcon         ; icon
            db 0                            ; palette index
            dw BattleActionNoneName         ; Name
            dw BattleActionNoneDescription  ; Description
            dw 0                            ; Target type
            dw 0                            ; Number of targets
        ;
    ;

ENDSECTION
