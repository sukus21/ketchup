INCLUDE "struct/battle_stats.inc"
INCLUDE "macro/relpointer.inc"


SECTION "BATTLE HELPER FUNCTIONS", ROM0

    ; Converts grid-space coordinates to screen-space coordinates.
    ; Returned coordinates can be used with sprite templates.  
    ; Lives in ROM0.
    ;
    ; Input:
    ; - `b`: Grid-space X-position
    ; - `c`: Grid-space Y-position
    ;
    ; Returns:
    ; - `b`: Screen-space X-position
    ; - `c`: Screen-space Y-position
    ;
    ; Saves: `de`, `hl`  
    ; Destroys: `af`
    BattleGridspaceToScreenspace::
        ; Transform X gridspace to screenspace
        ld a, b
        add a, a
        add a, a
        add a, a
        ld b, a
        add a, a
        add a, b
        add a, 8 + 11
        ld b, a
        
        ; Transform Y gridspace to screenspace
        ld a, c
        add a, a
        add a, a
        add a, a
        ld c, a
        add a, a
        add a, c

        ; Offset to account for gap between enemy and player grids
        cp a, 2*24
        jr c, :+
            add a, 8
        :
        add a, 8 + 2
        ld c, a

        ret
    ;



    ; Test if a player is allowed to move to the specified cell.
    ;
    ; Movement is allowed if:
    ; * Cell is not occupied by another character
    ; * Cell X < 3
    ; * Cell X < 5 and >= 2
    ;
    ; Lives in ROM0.
    ;
    ; Input:
    ; - `b`: Cell test X
    ; - `c`: Cell test Y
    ;
    ; Returns:
    ; - `a`: 0 if allowed
    ; - `fZ`: Set if allowed (z = allowed)
    ;
    ; Destroys: `af`
    BattleCanPlayerMoveTo::

        ; X must be below 3
        ld a, b
        cp a, 3
        jr c, :+
            or a, $FF ; reset Z flag
            ret
        :
        
        ; Y must be below 5
        ld a, c
        cp a, 5
        jr c, :+
            or a, $FF ; reset Z flag
            ret
        :

        ; Y must also be above 1
        cp a, 2
        jr nc, :+
            or a, $FF ; reset Z flag
            ret
        :

        ; Save these for later
        push hl

        ; Check overlap
        ld hl, wBattleStatsDuffin
        call .helper
        ld hl, wBattleStatsMenja
        call nz, .helper
        ld hl, wBattleStatsHerbert
        call nz, .helper

        ; Return
        xor a, $FF ; invert Z flag
        pop hl
        ret

        ; Input:
        ; - `bc`: Test coordinates
        ; - `hl`: `BATTLE_STATS_T` pointer
        ;
        ; Returns:
        ; - `a`: 0 if occupied
        ;
        ; Destroys: `hl`, `af`
        .helper
            relpointer_init l
            relpointer_move BATTLE_STATS_X
            ld a, b
            sub a, [hl]
            ret nz
            relpointer_move BATTLE_STATS_Y
            ld a, c
            sub a, [hl]
            relpointer_destroy
            ret
        ;
    ;

ENDSECTION
