INCLUDE "hardware.inc/hardware.inc"
INCLUDE "gamestate/gamestate.inc"

DEF MAP_DEPTH EQU 8
DEF MAP_LANES EQU 5

DEF NUM_STRONG_ENCOUNTERS EQU 4

SECTION "GAME STATE MANAGEMENT", ROMX, ALIGN[4]

; Lookup and probabillity tables for map gen:

; Lookup table of potential path configurations from a given room such that all three paths have 50%
; probabillity and at least one will always be included.
pathGenLookup:
    ds 3, GAMESTATE_ROOM_PATH_FLAGS_L
    ds 6, GAMESTATE_ROOM_PATH_FLAGS_S
    ds 3, GAMESTATE_ROOM_PATH_FLAGS_R
    ds 1, GAMESTATE_ROOM_PATH_FLAGS_L | GAMESTATE_ROOM_PATH_FLAGS_S
    ds 1, GAMESTATE_ROOM_PATH_FLAGS_L | GAMESTATE_ROOM_PATH_FLAGS_R
    ds 1, GAMESTATE_ROOM_PATH_FLAGS_S | GAMESTATE_ROOM_PATH_FLAGS_R
    ds 1, GAMESTATE_ROOM_PATH_FLAGS_L | GAMESTATE_ROOM_PATH_FLAGS_S | GAMESTATE_ROOM_PATH_FLAGS_R

; Probabillity tables for room types per layer, except the final layer.
; Stores probabillities of treasures, secrets, camps, and merchants, in that order.
; The remainder is the probabillity of an encounter.
; All probabillities are out of 128.
layerRoomTypeProbabillities:
    db 15, 15, 0, 0
    db 20, 10, 3, 6
    db 8, 10, 6, 11
    db 6, 16, 18, 6
    db 5, 6, 8, 9
    db 29, 4, 0, 21
    db 0, 0, 128, 0

; Actual functions

initRun::
    ; Set RNG seed (for testing)
    ld a, $37
    ldh [hRNGSeed], a
    ld a, $EA
    ldh [hRNGSeed + 1], a

    ; Set the right WRAM bank
    ld a, BANK(wRunSeed)
    ldh [rSMBK], a

    ; Store the seed
    ld hl, wRunSeed
    ldh a, [hRNGSeed]
    ld [hl+], a
    ldh a, [hRNGSeed + 1]
    ld [hl+], a
    xor a, a
    ld [hl+], a

    ; Set initial player funds to zero
    ld [hl+], a ; a is already zero
    ld [hl+], a

    ; Set character equipment
    ld [hl], 1;EQUIPMENT_ID_FIRST_AID_KIT ; Herbert's starter item
    inc l
    ld [hl+], a
    ld [hl+], a
    ld [hl], 2;EQUIPMENT_ID_POT_LID_SHIELD ; Menja's starter item
    inc l
    ld [hl+], a
    ld [hl+], a
    ld [hl], 3;EQUIPMENT_ID_BUTTER_KNIFE ; Duffin's starter item
    inc l
    ld [hl+], a
    ld [hl+], a

    ; Clear travel progress
    ld [hl+], a

    ; Path taken won't be read until the game progresses, so we skip that

    ; And now, it's time to generate a map!

    ; Maps are generated starting at the deepest layer, which has a fixed configuration.
    ld hl, wGameStateMapRoomData.end - 1
    ld [hl-], a
    ld [hl-], a
    ld [hl], GAMESTATE_ROOM_PATH_FLAGS_L | GAMESTATE_ROOM_PATH_FLAGS_R | GAMESTATE_ROOM_TYPE_BOSS
    dec hl
    ld [hl-], a
    ld [hl-], a

    ld d, $0A
    ld e, MAP_DEPTH - 2

    .LevelLoop:
        FOR I, MAP_LANES
            ; If the boss can not be reached from this room, generate an empty room with no paths
            xor a, a ; Encodes an inaccessible room
            srl d
            jr nc, .skip\@

                call GenerateRandomRoom

                ; Remove paths that go outside of the allowed lanes
                IF I == 0
                    and a, ~GAMESTATE_ROOM_PATH_FLAGS_L
                    cp a, 32
                    jr nc, :+
                        or a, GAMESTATE_ROOM_PATH_FLAGS_S
                    :
                ELIF I == MAP_LANES - 1
                    and a, ~GAMESTATE_ROOM_PATH_FLAGS_R
                    cp a, 32
                    jr nc, :+
                        or a, GAMESTATE_ROOM_PATH_FLAGS_S
                    :
                ENDC

            .skip\@:

            ; Store the generated room
            ld [hl-], a

            ; Update accessible rooms bitfield
            and a, $E0
            or a, d
            ld d, a
        ENDR

        REPT 7 - MAP_LANES
            srl d
        ENDR

        dec e
        jr nz, .LevelLoop
    ;

    ret

; Generates a room with random type and paths.
; Room types are weighted based on depth.
;
; Input:
; - `e`: Depth where room is placed
;
; Output:
; - `a`: Generated room
; 
; Destroys: `f`
; Saves: `bc`, `de`, `hl`
;
; Side effects: Advances PRNG by two bytes
GenerateRandomRoom:
    push hl
    push de
    
    ld h, e

    ; Get random bytes
    call GetDoubleRNG
    ld d, a

    ld a, h

    ; a = depth * 4
    add a, a
    add a, a

    ; Load pointer to row of layerRoomTypeProbabillities
    add a, LOW(layerRoomTypeProbabillities)
    ld l, a
    ld h, HIGH(layerRoomTypeProbabillities)

    ; Get random value for room type
    ld a, e
    and a, $7F

    ; Select room type based on random value
    REPT 4
        sub a, [hl]
        jr c, .NonEncounterSelected
        inc l
    ENDR

    ; If nothing from the probabillity table was chosen, then this is an encounter room
    ld e, GAMESTATE_ROOM_TYPE_WEAK_ENCOUNTER
    jr .RoomTypeSelected
    
    .NonEncounterSelected:
    ; Use pointer to calculate room type
    ld a, l
    and a, 3
    add a, GAMESTATE_ROOM_TYPE_TREASURE
    ld e, a

    .RoomTypeSelected:
    
    ; Use random value to generate pointer to random entry in pathGenLookup
    ld a, d
    and a, $0F
    add a, LOW(pathGenLookup)
    ld l, a
    ld h, HIGH(pathGenLookup)

    ; Get selected set of paths
    ld a, [hl]

    ; Combine room type with path flags
    or a, e

    ; Restore registers and return
    pop de
    pop hl
    ret


SECTION "PLAYER STATS", SRAM
    ; Expected to match a pre-defined signature.
    ; If it doesn't, then SRAM is uninitialized.
    ; This is the method recommended by the Pandocs.
    ; We define the signature to be the title of the game stored in the ROM header.
    sSramSignature:: ds 16

    ; The best score that the player has ever had at the end of a run.
    ; Encoded as BCD.
    sHighScore:: ds 2

    ; The sum of all scores the player has ever had at the end of a run.
    ; Encoded as BCD.
    sAccumulatedScore:: ds 4

SECTION "GAME STATE", WRAMX
    ; The initial seed set at the start of the run.
    ; Will not be updated over the course of a run.
    wRunSeed:: ds 3

    ; The amount of money that the player currently has.
    ; Encoded as BCD.
    wGameStatePlayerFunds:: ds 2

    ; The equipment that the player's characters have.
    ; Stored as the IDs of the equipables.
    ; Slots 0-2 belong to Herbert, slots 3-5 to Menja, and slots 6-8 to Duffin.
    ; Slots 0, 3, and 6 are the slots that enable extra effects.
    wGameStatePlayerEquipment:: ds 9

    ; The number of levels that the player has traversed this run.
    ; In other words, it's how far the player has traveled along the map.
    wGameStateTravelProgress:: ds 1

    ; Array tracking the lanes on the map that the player was visiting on each level.
    wGameStatePathTaken:: ds MAP_DEPTH

    wGameStateMapRoomData:: ds MAP_DEPTH * MAP_LANES
        .end:
