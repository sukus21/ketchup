INCLUDE "macro/farcall.inc"
INCLUDE "macro/relpointer.inc"
INCLUDE "entity/battle_player/battle_player.inc"


SECTION "BATTLE ACTION NONE", ROMX

; Does nothing, and immediately stops
;
; Input:
; - `de`: Character entity pointer
;
; Destroys: all
BattleActionNone::
    farjump BattleEndAction
;


; TODO: icon
BattleActionNoneIcon::
    FOR N, 64
        db N
    ENDR
;

BattleActionNoneName:: db "none", 0
BattleActionNoneDescription:: db "does nothing", 0
