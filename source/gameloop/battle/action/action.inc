    IF !DEF(BATTLE_ACTION_INC)
    DEF BATTLE_ACTION_INC EQU 1


; Action structure
RSRESET

    ; The action bank. Everything about the action is in this bank
    DEF ACTION_BANK RB 1

    ; Step pointer to step function, run every frame this action is executing for
    DEF ACTION_STEP RB 2

    ; 2BPP icon
    DEF ACTION_ICON RB 2

    ; Icon palette
    DEF ACTION_PALETTE RB 1

    ; Name pointer
    DEF ACTION_NAME RB 2

    ; Description pointer
    DEF ACTION_DESCRIPTION RB 2

    ; Targeting options.
    ; See `ACTION_TARGET_TYPEF_*` for options.
    DEF ACTION_TARGET_TYPE RB 1

    ; Number of targets
    DEF ACTION_NUM_TARGETS RB 1

    ; Contains an X and a Y componnent, one for every `ACTION_NUM_TARGETS`.  
    ; This is used to preview where a character will attack.
    DEF ACTION_TARGETS RB 0
;



; Targeting options bitfield
RSRESET

    ; If the X/Y positions are relative to the characters
    DEF ACTION_TARGET_TYPEF_RELATIVE EQU 1 << _RS
    DEF ACTION_TARGET_TYPEB_RELATIVE RB 1

    ; If the player is allowed to change the location (0,0) of targets
    DEF ACTION_TARGET_TYPEF_LOCATE EQU 1 << _RS
    DEF ACTION_TARGET_TYPEB_LOCATE RB 1
;



; Battle action enum
RSRESET

    ; No action, just end the action state immediately
    DEF BATTLE_ACTION_NONE RB 1
;

    ENDC
