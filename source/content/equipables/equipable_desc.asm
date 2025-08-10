INCLUDE "hardware.inc/hardware.inc"
INCLUDE "content/equipables/equipables.inc"
INCLUDE "draw/font_test.inc"

; Set when text is being rendered and shown to the
; player.
;
; Clear when no text is being shown or rendered.
DEF TEXTBOX_STATEB_ENABLED EQU 0

; Set when the next character of text is allowed to be
; rendered.
;
; Clear when there is no more text to render, or when
; it is not safe to do so.
DEF TEXTBOX_STATEB_ADVANCE_READY EQU 1

; Set when there is data in the buffer that has yet to
; be uploaded to VRAM.
;
; Clear when all data has already been uploaded, or when
; the buffer does not contain data meant to be uploaded.
;
; While set, more data can be added to the buffer, but
; data already in the buffer should not be erased without
; or until the clearing of this flag, as some of it has
; not yet been uploaded.
DEF TEXTBOX_STATEB_UPLOAD_READY EQU 2

; Signals that all tiles in VRAM containing rendered text
; should be cleared.
;
; While set, the intermediate buffer must be filled with
; zeroes. This allows the clearing mechanism to use DRM
; transfers with the buffer as a source.
;
; Since that makes this flag mutually exclusive with
; `TEXTBOX_STATEB_ADVANCE_READY`, the latter will instead
; be set automatically after the clearing operation
; finishes if `TEXTBOX_STATEB_ENABLED` is also set.
DEF TEXTBOX_STATEB_CLEAR_TILES EQU 3

; Set when a page of text has been fully rendered.
;
; When set, `wCharPointer` points to the line footer of
; the final line of text on the current page, instead of
; pointing to a character to be rendered.
DEF TEXTBOX_STATEB_PAGE_END EQU 4

DEF TEXTBOX_STATEF_ENABLED EQU 1
DEF TEXTBOX_STATEF_ADVANCE_READY EQU 2
DEF TEXTBOX_STATEF_UPLOAD_READY EQU 4
DEF TEXTBOX_STATEF_CLEAR_TILES EQU 8
DEF TEXTBOX_STATEF_PAGE_END EQU 16

SECTION "EQUIPABLE DESCRIPTIONS", ROMX, ALIGN[8]

; A table of pointers to the descriptions of each item.
; Keyed by equipable type ID. Each entry is 2 bytes long.
;
; Each description is encoded as a series of strings, each
; containing one line of text. Each string are terminated by
; a `0` followed by a one-byte footer. This footer can have
; one of three values:
; - `0` indicates the end of a description.
; - `1` indicates that the following line belongs to the next page.
; - `2` indicates a line feed.
EquipableDescriptionsTable:
    dw EquipableDescFirstAidKit
    dw EquipableDescSpellBoy
    dw EquipableDescButterKnife
    dw EquipableDescDuckeeIdol
    dw EquipableDescSurstromming
    dw EquipableDescGoldBar
    dw EquipableDescPantoglove
    dw EquipableDescMagnet
    dw EquipableDescSupersoaker
    dw EquipableDescBoomerang
    dw EquipableDescAlarmClock
    dw EquipableDescLegalDocument

    REPT $80 - (EquipableDescriptionsTable - @) / 2
        dw EquipableDescDefault
    ENDR
.end

; Reset the text box and have it describe the specified equipable item.
;
; Input:
; - `b`: Equipable ID
;
; Saves: none
; Side effects: Switches WRAM banks
EquipableDescSetItem::
    ; Store which item is being described
    ld hl, wDescribedItem
    ld a, b
    ld [hl+], a ; Writes to `wDescribedItem`

    ; Update state flags
    ; We need to enable text rendering and to start by clearing the tiles
    ld [hl], TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_CLEAR_TILES ; Writes to `wStateFlags`
    inc hl

    ; Generate a pointer into the descriptions table
    add a, a
    ld e, a
    ld d, HIGH(EquipableDescriptionsTable)

    ; Copy the pointer found in the descriptions table
    ld a, [de]
    ld [hl+], a ; Writes to `wCharPointer`
    inc e
    ld a, [de]
    ld [hl+], a ; Writes to `wCharPointer + 1`

    ; Reset VRAM upload destination
    xor a, a
    ld [hl+], a ; Writes to `wVramDest`
    ld [hl], HIGH(_VRAM9000 + 64 * 16) ; Writes to `wVramDest + 1`

    jp ResetRendering ; Tail call
;

; Switch to the next page of the description being shown.
;
; Saves: none
; Side effects: Switches WRAM banks
EquipableDescFlipPage::
    ; Load state flags into `b`
    ld hl, wStateFlags
    ld a, [hl+] ; Reads from `wStateFlags`
    ld b, a

    ; Load char pointer into `de`
    ld a, [hl+] ; Reads from `wCharPointer`
    ld e, a
    ld d, [hl] ; Reads from `wCharPointer + 1`

    ; Load the current char into `a`
    ld a, [de]

    ; Check if we're already at the end of a page
    bit TEXTBOX_STATEB_PAGE_END, b
    jr nz, .reachedEndOfPage
    :
        ; If not, then skip the rest of a page

        ; Loop until we've reached the end of the current line
        inc de
        ld a, [de]
        or a, a
        jr nz, :-

        ; Continue looping if it isn't the end of the current page
        inc de
        ld a, [de]
        cp a, 2
        jr z, :-

    .reachedEndOfPage:

    ; `de` now points to the final byte of the page.
    ; `a` contains the value of said byte, which specifies whether we're at the last page.

    ; We need a pointer to the start of the next page.

    or a, a
    jr z, :+
        ; If the final byte of the current page is not `0`, then we'll assume that it's `1`.
        ; If it's `1`, then we're not on the final page.

        ; The next page is stored right after the current one.
        inc de

        jr :++
    :
        ; If the final byte is `0`, then this is the final page of the description. We
        ; need to go back to the first page.

        ; Get the item being described
        ld a, [wDescribedItem]

        ; Generate a pointer into the descriptions table
        add a, a
        ld l, a
        ld h, HIGH(EquipableDescriptionsTable)

        ; Read pointer to first page from the descriptions table
        ld a, [hl+]
        ld e, a
        ld d, [hl]
    :

    ; `de` now contains a pointer to the start of the next page.

    ; Update state flags
    ; We need to enable text rendering and to clear the tiles of the previous page's contents
    ld hl, wStateFlags
    ld a, TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_CLEAR_TILES
    ld [hl+], a ; Writes to `wStateFlags`

    ; Set char pointer to start of next page
    ld a, e
    ld [hl+], a ; Writes to `wCharPointer`
    ld a, d
    ld [hl+], a ; Writes to `wCharPointer + 1`

    ; Reset VRAM upload destination
    xor a, a
    ld [hl+], a ; Writes to `wVramDest`
    ld [hl], HIGH(_VRAM9000 + 64 * 16) ; Writes to `wVramDest + 1`

    ; Fall through to `ResetRendering` for a free tail call
;

; Clear the rendering buffer and reset rendering to the start of the buffer.
ResetRendering:
    ; Let renderer use our most beloved font
    ld hl, wFontPointer
    ld a, HIGH(FontTest)
    ld [hl+], a ; Writes to `wFontPointer`

    ; Set renderer's head to the start of our buffer
    xor a, a
    ld [hl+], a ; Writes to `wFontDestChar`
    ld a, HIGH(wRenderBuffer)
    ld [hl+], a ; Writes to `wFontDestChar + 1`
    ld [hl], 0 ; Writes to `wFontDestPixel`

    ; Clear the buffer
    ld a, BANK(wRenderBuffer)
    ldh [rSVBK], a

    ld hl, wRenderBuffer
    ld bc, $0010
    call MemsetChunked

    ret
;

; Ticks the text box's internal mechanisms.
; Should be called once per frame.
;
; Saves: none
; Side effects: Switches WRAM banks
EquipableDescRenderStep::
    ; Switch to the right WRAM bank
    ld a, BANK(wRenderBuffer)
    ldh [rSVBK], a

    ; Load state flags into `b`
    ld hl, wStateFlags
    ld a, [hl+] ; Reads from `wStateFlags`
    ld b, a

    ; Load char pointer into `de`
    ld a, [hl+] ; Reads from `wCharPointer`
    ld e, a
    ld d, [hl] ; Reads from `wCharPointer + 1`

    ; Exit early if we aren't actually supposed to render any text right now
    bit TEXTBOX_STATEB_ADVANCE_READY, b
    ret z

    ; Get the next char to write
    ld a, [de]

    ; Check if the supposed "char" is actually an end-of-line marker
    or a, a
    jr z, .endOfLine
        ; Render the next character

        ; Offset char value
        dec a

        ; Free up register `a`
        ld c, a

        ; Store pointer to next char
        inc de
        ld a, d
        ld [hl-], a ; Writes to `wCharPointer + 1`
        ld a, e
        ld [hl-], a ; Writes to `wCharPointer`

        ; Update state flags
        ; Enable further rendering as well as uploading what's being rendered right now
        ld [hl], TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_ADVANCE_READY | TEXTBOX_STATEF_UPLOAD_READY ; Writes to `wStateFlags`

        ; Render the current char
        ld a, c
        call FontDrawGlyph

        ret 

    .endOfLine:
        ; End the current line of text.
        ; May be a line switch or the end of a page.

        ; Read line footer
        inc de
        ld a, [de]

        ; If this is something other than a line switch, then do something else
        cp a, 2
        jr nz, .endOfPage

        ; A line switch involves clearing the internal buffer. If VRAM isn't up to date,
        ; then we must postpone the line switch until the current line is fully uploaded.

        ; Exit early before making any changes if VRAM isn't up to date
        bit TEXTBOX_STATEB_UPLOAD_READY, b
        ret nz

        ; Store pointer to start of next line
        inc de
        ld a, d
        ld [hl-], a ; Writes to `wCharPointer + 1`
        ld a, e
        ld [hl-], a ; Writes to `wCharPointer`

        ; Update state flags
        ; Enable rendering the next line
        ld [hl], TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_ADVANCE_READY ; Writes to `wStateFlags`

        ; Set upload destination to first tile in next row
        ld hl, wVramDest
        xor a, a
        ld [hl+], a ; Writes to `wVramDest`
        inc [hl] ; Modifies `wVramDest + 1`

        call ResetRendering

        ret

    .endOfPage:
        ; End of the current page of text.
        ; Rendering must stop here for now.

        ; Store pointer to last byte of page
        ; State flags will specify that this isn't a char to be rendered.
        ld a, d
        ld [hl-], a ; Writes to `wCharPointer + 1`
        ld a, e
        ld [hl-], a ; Writes to `wCharPointer`

        ; Update state flags
        ; Specify that we're at the end of a page
        ld a, b
        and a, TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_UPLOAD_READY
        or a, TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_PAGE_END
        ld [hl], a ; Writes to `wStateFlags`

        ret
    ;
;

; Send the renderer's output to VRAM.
; Should be called once per frame during VBlank.
;
; Skipping a frame won't break anything, but it
; may pause rendering in some situations.
;
; Accesses VRAM.
;
; Saves: none
; Side effects: Switches VRAM and WRAM banks
EquipableDescUpload::
    ; Start off by reading state flags
    ld a, [wStateFlags]

    ; If the tiles in VRAM need to be cleared, then that's what we gotta do
    bit TEXTBOX_STATEB_CLEAR_TILES, a
    jr nz, .clearTiles

    ; Otherwise, if there's nothing to upload, return early
    bit TEXTBOX_STATEB_UPLOAD_READY, a
    ret z

    ; Clear the flag that says there's more data to upload
    res TEXTBOX_STATEB_UPLOAD_READY, a
    ld [wStateFlags], a

    ; Switch to the right banks
    xor a, a
    ldh [rVBK], a

    ld a, BANK(wRenderBuffer)
    ldh [rSVBK], a

    ; Load destination into `de`
    ld a, [wVramDest+1]
    ld d, a
    ld a, [wVramDest]
    ld e, a
    
    ; Load source into `hl`
    ld l, a
    ld h, HIGH(wRenderBuffer)

    ; Calculate number of bytes to be uploaded
    ld a, [wFontDestChar]
    add a, 16
    sub a, e
    ld b, a

    ; Copy dem bytes!
    :
        ld a, [hl+]
        ld [de], a
        inc e

        dec b
        jr nz, :-
    ;

    ; Store which tile we should start at next time we upload.
    ; The last tile we uploaded might have been modified next time,
    ; so that's where we'll have to start next time.
    ld a, e
    sub a, 16
    ld [wVramDest], a

    ret

    ; Getting here means we need to clear the tiles in VRAM containing
    ; rendered text. Like clearing out a blackboard before using it.
    .clearTiles:

    ; Store state flags in `b`
    ld b, a

    ; Switch to the right banks
    ld a, BANK(wRenderBuffer)
    ldh [rSVBK], a

    xor a, a
    ldh [rVBK], a

    ; Clear the tiles in VRAM with DMAs
    ; Use the render buffer as a source since it's currently all zeroes
    FOR I, 4
        xor a, a
        ldh [rHDMA2], a
        ldh [rHDMA4], a
        ld a, HIGH(wRenderBuffer)
        ldh [rHDMA1], a
        ld a, HIGH(_VRAM9000 + 64 * 16) + I
        ldh [rHDMA3], a

        ld a, 16
        ldh [rHDMA5], a
    ENDR

    ; Update state flags
    ; If the "enabled" flag is not set, then there's nothing more to do, and all flags should be clear.
    ; If the "enabled" flag is set, then we should start rendering some text.
    xor a, a
    bit TEXTBOX_STATEB_ENABLED, b
    jr z, :+
        ld a, TEXTBOX_STATEF_ENABLED | TEXTBOX_STATEF_ADVANCE_READY
    :
    ld [wStateFlags], a

    ret
;

SETCHARMAP TEST_FONT_CHARMAP

EquipableDescDefault:
    db "[No item]", 0, 0
.end

EquipableDescFirstAidKit:
    db "Name: First-aid Kit", 0, 2
    db "Valid users: Herbert", 0, 1

    db "A container for basic", 0, 2
    db "medical items to treat", 0, 2
    db "minor injuries with.", 0, 1

    db "Cmn Abil: Treat (Act)", 0, 2
    db "Allied target recovers 3", 0, 2
    db "HP. Can't heal above 10 HP.", 0, 1

    db "Ex Abil: Smack (Act)", 0, 2
    db "Target suffers 3 dmg.", 0, 0
.end

EquipableDescSpellBoy:
    db "Name: Spellboy", 0, 2
    db "Valid users: Menja", 0, 1

    db "A gaming hanheld with", 0, 2
    db "spellcasting features to", 0, 2
    db "eliminate disturbances.", 0, 1

    db "Cmn Abil: Focus (Act)", 0, 2
    db "Focus on gaming. Take half", 0, 2
    db "damage until next turn.", 0, 1
    
    db "Ex Abil: Fireball (Act)", 0, 2
    db "Target suffers 4 dmg.", 0, 0
.end

EquipableDescButterKnife:
    db "Name: Butter Knife", 0, 2
    db "Valid users: Duffin", 0, 1

    db "A common cutlery item that", 0, 2
    db "Duffin uses as a dagger to", 0, 2
    db "surpricing effectiveness.", 0, 1

    db "Cmn Abil: Stab (Act)", 0, 2
    db "Target suffers 5 dmg.", 0, 2
    db "Very short range.", 0, 1

    db "Ex Abil: Thrust (Act)", 0, 2
    db "Target suffers 4 dmg.", 0, 0
.end

EquipableDescDuckeeIdol:
    db "Name: Duckee Idol", 0, 2
    db "Export value: $8", 0, 1

    db "Small statue depicting a", 0, 2
    db "terrible god. It's boyant", 0, 2
    db "and made of rubber.", 0, 1

    db "Cmn Abil: Terror (Psv)", 0, 2
    db "Enemies hit by user", 0, 2
    db "suffer +1 delay.", 0, 1

    db "Ex Abil: Jumpscare (Act)", 0, 2
    db "Targets suffer +3 delay as", 0, 2
    db "they pee their pants.", 0, 0
.end

EquipableDescSurstromming:
    db "Name: Surströmming", 0, 2
    db "Export value $2", 0, 1

    db "Rotten fish considered", 0, 2
    db "\"food\" to a certain", 0, 2
    db "people.", 0, 1

    db "Cmn Abil: Stinky (Psv)", 0, 2
    db "50% chance for attacking", 0, 2
    db "enemies to focus on user.", 0, 1

    db "Ex Abil: Stink Bomb (Act)", 0, 2
    db "All enemies suffer 3 dmg.", 0, 0
.end

EquipableDescGoldBar:
    db "Name: Gold Bar", 0, 2
    db "Export value: $24", 0, 1

    db "A valuable export that is", 0, 2
    db "very hard to carry. Worse", 0, 2
    db "than useless in combat.", 0, 1

    db "Cmn Abil: Heavy (Psv)", 0, 2
    db "Recieve -1 AP per turn.", 0, 1

    db "Ex Abil: Bling (Act)", 0, 2
    db "Brag to your enemies, to", 0, 2
    db "absolutely no effect.", 0, 0
.end

EquipableDescPantoglove:
    db "Name: Pantoglove", 0, 2
    db "Export value: $6", 0, 1

    db "A boxing glove mounted at", 0, 2
    db "the end of a pantograph", 0, 2
    db "structure. Classic!", 0, 1

    db "Cmn Abil: Punch (Act)", 0, 2
    db "Target suffers 7 dmg.", 0, 1

    db "Ex Abil: Megapunch (Act)", 0, 2
    db "Target suffers 12 dmg.", 0, 0
.end

EquipableDescMagnet:
    db "Name: Magnet", 0, 2
    db "Export value: $9", 0, 1

    db "A horseshoe magnet that", 0, 2
    db "somehow works on non-", 0, 2
    db "metallic objects.", 0, 1

    db "Cmn Abil: Attact (Act)", 0, 2
    db "Move target to closest", 0, 2
    db "rank.", 0, 1

    db "Ex Abil: Repel (Act)", 0, 2
    db "Move target to farest", 0, 2
    db "rank.", 0, 0
.end

EquipableDescSupersoaker:
    db "Name: Supersoaker", 0, 2
    db "Export value: $7", 0, 1

    db "A toy that shoots water.", 0, 2
    db "Menja won't let Duffin", 0, 2
    db "use it outside of combat.", 0, 1

    db "Cmn Abil: Soak (Act)", 0, 2
    db "Target takes 8 dmg if it's", 0, 2
    db "robotic, otherwise 3 dmg.", 0, 1

    db "Ex Abil: Push (Act)", 0, 2
    db "Move target to farest rank", 0, 2
    db "and deal 5 dmg.", 0, 0
.end

EquipableDescBoomerang:
    db "Name: Boomerang", 0, 2
    db "Export value: $6", 0, 1

    db "A stick that returns when", 0, 2
    db "thrown, assuming you know", 0, 2
    db "how to throw it.", 0, 1

    db "Cmn Abil: Arc (Act)", 0, 2
    db "Targets suffer 4 dmg.", 0, 2
    db "Can hit multiple targets.", 0, 1

    db "Ex Abil: Far Arc (Act)", 0, 2
    db "Targets suffer 4 dmg.", 0, 2
    db "Can hit multiple targets.", 0, 0
.end

EquipableDescAlarmClock:
    db "Name: Alarm Clock", 0, 2
    db "Export value: $6", 0, 1

    db "A very anoying device that", 0, 2
    db "nonlethess serves its role", 0, 2
    db "in waking you up.", 0, 1

    db "Cmn Abil: Tick Tock (Psv)", 0, 2
    db "Action delays above 2 are", 0, 2
    db "decreased by 1.", 0, 1

    db "Ex Abil: Wake-Up (Act)", 0, 2
    db "Allies' delays are", 0, 2
    db "decreased by 2.", 0, 0
.end

EquipableDescLegalDocument:
    db "Name: Legal Document", 0, 2
    db "Export value: $3", 0, 1

    db "A paper no one's gonna read,", 0, 2
    db "which means you can lie", 0, 2
    db "about its contents.", 0, 1

    db "Cmn Abil: Demand (Act)", 0, 2
    db "Recieve $4. Only works once", 0, 2
    db "per unique target.", 0, 1

    db "Ex Abil: Takedown (Act)", 0, 2
    db "50% chance to cancel", 0, 2
    db "target's action.", 0, 0
.end


SECTION "EQUIPABLE DESCRIPTION VARIABLES", WRAM0
    ; Equipable ID of the item currently being described.
    wDescribedItem: ds 1

    ; Packed booleans describing the internal state of the
    ; text system.
    wStateFlags: ds 1

    ; Pointer to the next character or line terminator to be
    ; rendered.
    ;
    ; If the `TEXTBOX_STATEB_PAGE_END` flag is set, it instead
    ; points to the footer byte of the last line of the current
    ; page.
    wCharPtr: ds 2

    ; Pointer into VRAM to the tile currently being updated.
    ; 
    ; Notably, the low 8 bits of this pointer also happen to
    ; be the index into `wRenderBuffer` from which the uploaded
    ; data is sourced, as both the buffer and the tiles for one
    ; line of text in VRAM share a size and alignment of 256
    ; bytes. The upload mechanism currenly relies on this
    ; observation.
    wVramDest: ds 2
;

SECTION "EQUIPABLE DESCRIPTION RENDER BUFFER", WRAMX, ALIGN[8]
    ; Buffer storing up to 16 tiles of rendered text before
    ; uploading to VRAM.
    ;
    ; This allows text to be rendered outside of VBlank.
    wRenderBuffer: ds 256
;
