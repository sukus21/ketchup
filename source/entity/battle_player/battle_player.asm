INCLUDE "hardware.inc/hardware.inc"
INCLUDE "entity/battle_player/battle_player.inc"
INCLUDE "gameloop/battle/vram.inc"
INCLUDE "macro/memcpy.inc"
INCLUDE "utils.inc"
INCLUDE "struct/battle_stats.inc"


SECTION "ENTITY BATTLE PLAYER DATA", ROMX

    ; Character palettes
    PalDuffin: INCBIN "entity/battle_player/sprites/duffin.gbc"
    PalMenja: INCBIN "entity/battle_player/sprites/menja.gbc"
    PalHerbert: INCBIN "entity/battle_player/sprites/herbert.gbc"

    ; Idle sprites, always loaded
    SprDuffinIdle: INCBIN "entity/battle_player/sprites/duffin_idle.2bpp"
    .end
    SprMenjaIdle: INCBIN "entity/battle_player/sprites/menja_idle.2bpp"
    .end
    SprHerbertIdle: INCBIN "entity/battle_player/sprites/herbert_idle.2bpp"
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
        memcpy_label SprDuffinIdle, VT_BATTLE_DUFFIN_IDLE
        memcpy_label SprMenjaIdle, VT_BATTLE_MENJA_IDLE
        memcpy_label SprHerbertIdle, VT_BATTLE_HERBERT_IDLE

        ; Copy palettes over
        ld hl, PalDuffin
        ld a, OBJPAL_BATTLE_DUFFIN * 8
        call PaletteCopyOBJ
        ld hl, PalMenja
        ld a, OBJPAL_BATTLE_MENJA * 8
        call PaletteCopyOBJ
        ld hl, PalHerbert
        ld a, OBJPAL_BATTLE_HERBERT * 8
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
        relpointer_init l

        ; Read out state
        relpointer_move ENTVAR_PLAYER_STATE
        ld a, [hl]

        ; Switch based on state
        cp a, PLAYER_STATE_IDLE
        jr nz, .notIdle

            ; Get stats pointer -> DA (yes, A)
            relpointer_push ENTVAR_PLAYER_STATS+1
            ld a, [hl-]
            ld d, a
            ld a, [hl+]

            ; Move stats pointer to X/Y position -> DE
            add a, BATTLE_STATS_X
            ld e, a

            ; Get X/Y position -> BC
            ld a, [de]
            ld b, a
            inc e
            ld a, [de]
            ld c, a

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

            relpointer_pop
        .notIdle

        ; Ok, that's all
        relpointer_destroy
        pop hl
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
        dw TmplDuffinIdle
        dw TmplMenjaIdle
        dw TmplHerbertIdle
    ;

    ; Duffins idle pose
    TmplDuffinIdle:: db %0000_0110
        db VTI_BATTLE_DUFFIN_IDLE + $00, OBJPAL_BATTLE_DUFFIN, 
        db VTI_BATTLE_DUFFIN_IDLE + $02, OBJPAL_BATTLE_DUFFIN
    ;

    ; Menjas idle pose
    TmplMenjaIdle:: db %0110_0110
        db VTI_BATTLE_MENJA_IDLE + $00, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $04, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $02, OBJPAL_BATTLE_MENJA
        db VTI_BATTLE_MENJA_IDLE + $06, OBJPAL_BATTLE_MENJA
    ;

    ; Herberts idle pose
    TmplHerbertIdle:: db %0110_0110
        db VTI_BATTLE_HERBERT_IDLE + $00, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $04, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $02, OBJPAL_BATTLE_HERBERT
        db VTI_BATTLE_HERBERT_IDLE + $06, OBJPAL_BATTLE_HERBERT
    ;

ENDSECTION
