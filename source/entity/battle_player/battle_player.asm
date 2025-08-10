INCLUDE "hardware.inc/hardware.inc"
INCLUDE "entity/battle_player/battle_player.inc"
INCLUDE "gameloop/battle/vram.inc"
INCLUDE "macro/memcpy.inc"
INCLUDE "utils.inc"
INCLUDE "struct/battle_stats.inc"
INCLUDE "gameloop/battle/battle.inc"
INCLUDE "macro/farcall.inc"


SECTION "ENTITY BATTLE PLAYER DATA", ROMX

    ; Character palettes
    PalHerbert: INCBIN "entity/battle_player/sprites/herbert.gbc"
    PalMenja: INCBIN "entity/battle_player/sprites/menja.gbc"
    PalDuffin: INCBIN "entity/battle_player/sprites/duffin.gbc"

    ; Idle sprites, always loaded
    SprHerbertIdle: INCBIN "entity/battle_player/sprites/herbert_idle.2bpp"
    .end
    SprMenjaIdle: INCBIN "entity/battle_player/sprites/menja_idle.2bpp"
    .end
    SprDuffinIdle: INCBIN "entity/battle_player/sprites/duffin_idle.2bpp"
    .end



    ; Loads assets required for battle player.
    ; Currently just loads the idle frames for each character.  
    ; Assumes VRAM access.  
    ; Assumes palette access.
    ;
    ; Destroys: all
    EntityBattlePlayerLoad::
        xor a
        ldh [rVBK], a

        ; Copy sprites over
        memcpy_label SprHerbertIdle, VT_BATTLE_HERBERT_IDLE
        memcpy_label SprMenjaIdle, VT_BATTLE_MENJA_IDLE
        memcpy_label SprDuffinIdle, VT_BATTLE_DUFFIN_IDLE

        ; Copy palettes over
        ld hl, PalHerbert
        ld a, OBJPAL_BATTLE_HERBERT * 8
        call PaletteCopyOBJ
        ld hl, PalMenja
        ld a, OBJPAL_BATTLE_MENJA * 8
        call PaletteCopyOBJ
        ld hl, PalDuffin
        ld a, OBJPAL_BATTLE_DUFFIN * 8
        call PaletteCopyOBJ

        ; Ok, done
        ret
    ;
ENDSECTION



SECTION "ENTITY BATTLE PLAYER", ROMX
    ; Create a new battle player entity.
    ;
    ; Input:
    ; - `bc`: `BATTLE_STATS_T` pointer
    ; - `d`: Character ID (`CHARID`)
    ;
    ; Returns:
    ; - `hl`: Entity pointer
    ;
    ; Destroys: all
    EntityBattlePlayerCreate::
        
        ; Allocate entity
        push bc
        push de
        entsys_new 32, EntityBattlePlayer, 0
        pop de
        pop bc

        ; Clear state
        relpointer_move ENTVAR_PLAYER_STATE
        ld [hl], PLAYER_STATE_IDLE

        ; Clear timer
        relpointer_move ENTVAR_PLAYER_TIMER
        ld [hl], 0

        ; Set battle stats pointer
        relpointer_move ENTVAR_PLAYER_STATS
        write_n16 bc
        relpointer_add 2

        ; Clear position
        relpointer_move ENTVAR_PLAYER_X
        xor a
        ld [hl+], a
        ld [hl+], a
        ld [hl+], a
        ld [hl+], a
        relpointer_add 4

        ; Write character ID
        relpointer_move ENTVAR_PLAYER_CHARID
        ld [hl], d

        ; Yup, that's all
        relpointer_move 0
        relpointer_destroy
        ret
    ;



    ; Battle player step function.
    ;
    ; Input:
    ; - `de`: Entity pointer
    EntityBattlePlayer:
        ld h, d
        ld l, e

        call PlayerUpdate
        call PlayerDraw

        ret
    ;



    ; Main update function for battle player.
    ;
    ; Input:
    ; - `hl`: Entity pointer (0)
    ;
    ; Saves: `hl`
    PlayerUpdate:
        push hl
        ld bc, .return
        push bc

        ; Read out state
        relpointer_init l
        relpointer_move ENTVAR_PLAYER_STATE
        ld a, [hl]
        relpointer_destroy

        ; Switch based on state
        cp a, PLAYER_STATE_IDLE
        jp z, PlayerStateIdle
        cp a, PLAYER_STATE_ACTION
        jp z, PlayerStateAction
        cp a, PLAYER_STATE_MOVEMENT
        jp z, PlayerStateMovement
        cp a, PLAYER_STATE_MENUING
        jp z, PlayerStateMenuing

        ; Invalid state
        ld hl, ErrorUnimplemented
        rst VecError

        ; Ok, that's all
        .return
        pop hl
        ret
    ;



    ; Player idle state.
    ;
    ; Input:
    ; - `hl`: Player entity @`ENTVAR_PLAYER_STATE`
    ;
    ; Saves: none
    PlayerStateIdle:
        relpointer_init l, ENTVAR_PLAYER_STATE

        ; Do we have to do anything else?
        ld a, [wBattleCurrentChar]
        ld b, a
        relpointer_push ENTVAR_PLAYER_CHARID
        ld a, [hl]
        relpointer_pop
        cp a, b
        jr nz, .doIdle
            ld a, [wBattleState]

            ; Are we supposed to enter the movement state?
            cp a, BATTLE_STATE_MOVEMENT
            jr nz, :+
                relpointer_push ENTVAR_PLAYER_STATE, 0
                ld [hl], PLAYER_STATE_MOVEMENT
                jp PlayerStateMovement
                relpointer_pop 0
            :

            ; Are we supposed to enter the action state?
            cp a, BATTLE_STATE_ACTION
            jr nz, :+
                relpointer_push ENTVAR_PLAYER_STATE, 0
                ld [hl], PLAYER_STATE_ACTION
                jp PlayerStateAction
                relpointer_pop 0
            :

        ; Get stats pointer -> DA (yes, A)
        .doIdle
        relpointer_move ENTVAR_PLAYER_STATS+1
        ld a, [hl-]
        ld d, a
        ld a, [hl+]

        ; Move stats pointer to X/Y position -> DE
        add a, BATTLE_STATS_X
        ld e, a

        ; Get X/Y grid position -> BC
        ld a, [de]
        ld b, a
        inc e
        ld a, [de]
        ld c, a

        ; Convert grid-space into screen-space
        call BattleGridspaceToScreenspace

        ; Store these back in player entity
        relpointer_move ENTVAR_PLAYER_X
        xor a
        ld [hl+], a
        ld a, b
        ld [hl-], a
        relpointer_move ENTVAR_PLAYER_Y
        xor a
        ld [hl+], a
        ld a, c
        ld [hl-], a

        relpointer_destroy
        ret
    ;



    ; Player menuing state.
    ; Wait for menu state to be over before doing something.
    ;
    ; Input:
    ; - `hl`: Player entity @`ENTVAR_PLAYER_STATE`
    ;
    ; Saves: none
    PlayerStateMenuing:
        relpointer_init l, ENTVAR_PLAYER_STATE

        ; Should we end the menu state?
        ld a, [wBattleState]

        ; Go back to schmooving
        cp a, BATTLE_STATE_MOVEMENT
        jr nz, :+
            relpointer_assert ENTVAR_PLAYER_STATE
            ld [hl], PLAYER_STATE_MOVEMENT
            ret
        :

        ; Is my turn done?
        relpointer_move ENTVAR_PLAYER_CHARID
        ld a, [wBattleCurrentChar]
        cp a, [hl]
        jr nz, :+
            relpointer_move ENTVAR_PLAYER_STATE
            ld [hl], PLAYER_STATE_IDLE
            ret
        :

        ; Nothing happened
        relpointer_destroy
        ret
    ;



    ; Player movement state.
    ;
    ; Input:
    ; - `hl`: Player entity @`ENTVAR_PLAYER_STATE`
    ;
    ; Saves: none
    PlayerStateMovement:
        ; Return early if no player input
        ld a, [wInputPressed]
        or a, a
        ret z
        ld e, a ; Save input in `e`

        ; Are we moving?
        and a, PADF_UP | PADF_DOWN | PADF_LEFT | PADF_RIGHT
        jr nz, .movement

        ; Nope, try opening a menu
        bit PADB_A, e
        jr nz, .openActionMenu

        ; Nothing
        ret

        .openActionMenu
            
            ; Set battle state
            ld a, BATTLE_STATE_MENU_ACTION
            ld [wBattleState], a

            ; Set entity state
            relpointer_init l, ENTVAR_PLAYER_STATE
            relpointer_move ENTVAR_PLAYER_STATE
            ld [hl], PLAYER_STATE_MENUING
            relpointer_destroy
            ret
        ;

        .movement
            relpointer_init l, ENTVAR_PLAYER_STATE

            ; Get grid position -> BC
            relpointer_move ENTVAR_PLAYER_CHARID
            ld a, [hl]
            battle_charid_to_statptr bc, BATTLE_STATS_X
            push bc
            ld a, [bc]
            ld d, a
            inc bc
            ld a, [bc]
            ld b, d ; X-position
            ld c, a ; Y-position

            ; Offset X or Y position
            bit PADB_UP, e
            jr z, :+
                dec c
                jr .foundDirection
            :
            bit PADB_DOWN, e
            jr z, :+
                inc c
                jr .foundDirection
            :
            bit PADB_LEFT, e
            jr z, :+
                dec b
                jr .foundDirection
            :
            bit PADB_RIGHT, e
            jr z, :+
                inc b
                jr .foundDirection
            :

            ; Start moving
            .foundDirection
            ld d, [hl]
            call BattleCanPlayerMoveTo
            pop de ; restore BATTLE_STATS pointer
            jr z, .notAllowed
                push hl

                ; Update AP
                dec e ; DE now points to AP
                battle_coords_to_movement_grid b, c, hl
                ld a, [de]
                cp a, [hl]
                jr c, :+
                    ; Tile is not a re-thread, do the thing
                    ld a, [de]
                    dec a
                    ld [de], a

                    ; Update movement grid value
                    ld [hl], a
                    
                    jr .doneUpdatingAP
                :
                    ; Tile IS a rethread, load value from movement grid
                    ld a, [hl]
                    ld [de], a
                .doneUpdatingAP


                ; Move character grid position
                inc e
                ld a, b
                ld [de], a
                inc e
                ld a, c
                ld [de], a

                ; Sync entity position with grid position
                call BattleGridspaceToScreenspace
                pop hl
                relpointer_move ENTVAR_PLAYER_X
                xor a
                ld [hl+], a
                ld a, b
                ld [hl+], a
                xor a
                ld [hl+], a
                ld [hl], c
                relpointer_add 3


            .notAllowed

            relpointer_destroy
            ret
    ;



    ; Player movement state.
    ;
    ; Input:
    ; - `hl`: Player entity @`ENTVAR_PLAYER_STATE`
    ;
    ; Saves: none
    PlayerStateAction:
        relpointer_init l, ENTVAR_PLAYER_STATE

        ; Oh wait hang on are we done?
        ld a, [wBattleState]
        cp a, BATTLE_STATE_ACTION
        jr z, :+
            ld [hl], PLAYER_STATE_MOVEMENT
            jp PlayerStateMovement
        :

        ; Find action and perform it
        relpointer_move ENTVAR_PLAYER_STATS
        ld a, [hl+]
        ld e, a
        ld a, [hl-]
        ld d, a
        ld a, [de]

        ; Set up arguments
        ld b, a
        relpointer_move 0
        ld d, h
        ld e, l
        farcall_x PerformAction

        relpointer_destroy
        ret
    ;



    ; Main draw function for battle player.
    ;
    ; Input:
    ; - `hl`: Entity pointer (0)
    ;
    ; Saves: `hl`
    PlayerDraw:
        push hl
        relpointer_init l

        ; Get X and Y position -> BC
        relpointer_move ENTVAR_PLAYER_X+1
        ld a, [wBattleCameraX+1]
        add a, [hl]
        ld b, a
        relpointer_move ENTVAR_PLAYER_Y+1
        ld a, [wBattleCameraY+1]
        add a, [hl]
        ld c, a

        ; Get character ID -> A
        relpointer_move ENTVAR_PLAYER_CHARID
        ld a, [hl]
        relpointer_destroy

        ; Get sprite template pointer -> DE
        ld hl, TmplsIdle
        add a, a
        add a, l
        ld l, a
        jr nc, @+3 :: inc h
        ld a, [hl+]
        ld d, [hl]
        ld e, a

        ; Set up remaining parameters for template drawing
        ld h, high(wOAM)
        xor a
        call SpriteDrawTemplate

        ; Ok, that's all
        pop hl
        ret
    ;

    ; Idle animation pointers for all characters.
    TmplsIdle:
        dw TmplHerbertIdle
        dw TmplMenjaIdle
        dw TmplDuffinIdle
    ;

    ; Herberts idle pose
    TmplHerbertIdle: db %0110_0110
        db VTI_BATTLE_HERBERT_IDLE + $00, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $04, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $02, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $06, OBJPAL_BATTLE_HERBERT
    ;

    ; Menjas idle pose
    TmplMenjaIdle: db %0110_0110
        db VTI_BATTLE_MENJA_IDLE + $00, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $04, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $02, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $06, OBJPAL_BATTLE_MENJA
    ;

    ; Duffins idle pose
    TmplDuffinIdle: db %0000_0110
        db VTI_BATTLE_DUFFIN_IDLE + $00, OBJPAL_BATTLE_DUFFIN, 
        db VTI_BATTLE_DUFFIN_IDLE + $02, OBJPAL_BATTLE_DUFFIN
    ;

ENDSECTION
