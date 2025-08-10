    IF !DEF(GAMELOOP_EQUIPMENT_SCREEN_INC)
    DEF GAMELOOP_EQUIPMENT_SCREEN_INC EQU 1

; Player can see their current equipment, but can not make any changes.
; Serves purely to let players know what they have equipped and what it does.
DEF EQUIPMENT_SCREEN_MODE_REVIEW EQU 0
; Player can see their current equipment and reorganize it.
; Serves to let players make changes even when new items aren't offered.
DEF EQUIPMENT_SCREEN_MODE_REORGANIZE EQU 1
; Player can see and reorganize their current equipment. In addition, a few
; slots are present that may contain items outside the player's inventory.
; Used to let players accept specific items, such as from a purchase.
DEF EQUIPMENT_SCREEN_MODE_OFFER_SPECIFIC EQU 2
; Player can see and reorganize their current equipment. In addition, a few
; slots are present that may contain items outside the player's inventory.
; If conditions are met, players are also allowed to reroll these extra items.
; Used to let players accept random items, such as from treasures.
DEF EQUIPMENT_SCREEN_MODE_OFFER_RANDOM EQU 3

    ENDC