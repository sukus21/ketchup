

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

ENDSECTION
