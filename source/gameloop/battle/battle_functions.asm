INCLUDE "gameloop/battle/battle.inc"
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
        ld hl, wBattleStatsHerbert
        call .helper
        ld hl, wBattleStatsMenja
        call nz, .helper
        ld hl, wBattleStatsDuffin
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



    ; Insert a character ID into the turn order.  
    ; Lives in ROM0.
    ;
    ; Input:
    ; - `a`: `CHARID` item
    BattleAddToQueue::
        ld c, a
        call BattleRemoveFromQueue

        ; Get this actors delay -> B
        ld a, c
        battle_charid_to_statptr hl, BATTLE_STATS_ACTION_DELAY
        ld b, [hl]

        ; Loop through current queue to find existing entry
        ld de, wBattleTurnOrder
        .loop
            ld a, [de]
            inc a ; cp a, $FF
            jr z, .found
            dec a

            ; If new entry has lower delay, insert here
            battle_charid_to_statptr hl, BATTLE_STATS_ACTION_DELAY
            ld a, c
            cp a, [hl]
            jr c, .found

            ; Nope, try the next entry
            inc de
            jr .loop
        ;

        ; We found an entry!
        .found
        ld h, d
        ld l, e

        ; Replace things
        .foundLoop
            ld b, [hl]
            ld a, c
            ld [hl+], a

            ld c, b
            inc b ; cp b, $FF
            jr nz, .foundLoop
            ret
        ;
    ;



    ; Removes a character from the turn order.
    ; If character is not in the turn order, nothing happens.  
    ; Lives in ROM0.
    ;
    ; Input:
    ; - `a`: `CHARID` item
    ;
    ; Destroys: `hl`, `af`, `b`  
    ; Saves: `c`, `de`
    BattleRemoveFromQueue::
        ld b, a
        ld hl, wBattleTurnOrder

        ; Find entry matching
        .loop
            ld a, [hl+]
            cp a, b
            jr z, .found

            ; Loop if ID != $FF
            inc a
            jr nz, .loop
            ret
        ;

        ; Move queue entries forwards until $FF is hit
        .found
            ld a, [hl-]
            ld [hl+], a
            inc a
            ret z

            inc hl
            jr .found
        ;
    ;

ENDSECTION
