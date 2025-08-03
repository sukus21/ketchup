INCLUDE "macro/farcall.inc"
INCLUDE "macro/relpointer.inc"
INCLUDE "entity/battle_player/battle_player.inc"


SECTION "BATTLE ACTION NONE", ROMX

; Does nothing, and immediately goes back to the ticking action.
;
; Input:
; - `de`: Character entity pointer
;
; Destroys: all
BattleActionNone::
    farjump BattleChangeStateCountdown
;


; TODO: icon
BattleActionNoneIcon::
    FOR N, 64
        db N
    ENDR
;

BattleActionNoneName:: db "none", 0
BattleActionNoneDescription:: db "does nothing", 0
