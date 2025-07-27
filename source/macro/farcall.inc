    IF !DEF(MACRO_FARCALL_INC)
    DEF MACRO_FARCALL_INC EQU 1

; Encodes a 24-byte pointer to the given label.
; Specifically, this stores a one-byte bank index followed
; by a little-endian two-byte address.
; Useful for making jump tables that may jump to various banks.
;
; Input:
; - `1`: Label
MACRO pointer24
    db BANK(\1)
    dw \1
ENDM

; Switches banks, and jumps to the given symbol.
; `a` will be clobbered before the jump,
; and can therefore not be used as function arguments.
; Does not switch banks back when returning.
;
; Input (1):
; - `1`: Symbol to call (label)
;
; Input (2):
; - `1`: Condition code
; - `2`: Symbol to call (label)
;
; Destroys: `a`, unknown
MACRO farcall
    ASSERT bank(@) == 0, "farcall - can only do non-returning farcall from ROM0"
    IF _NARG == 1
        ld a, bank(\1)
        ld [rROMB0], a
        call \1
    ELSE
        ld a, bank(\2)
        ld [rROMB0], a
        call \1, \2
    ENDC
ENDM



; Switches banks, and jumps to the given symbol.
; `a` and `hl` will be clobbered before the jump,
; and can therefore not be used as function arguments.
; Switches banks back before returning.
;
; Input:
; - `1`: Symbol to call (label)
;
; Destroys: `a`, `hl`, unknown
MACRO farcall_x
    ASSERT bank(@) != 0, "farcall - should not use farcall_x from ROM0"
    ld a, bank(@)
    ldh [hBankNumber], a
    ld a, bank(\1)
    ld hl, \1
    call FarcallHandlerX
ENDM

; Switches banks and performs a one-way jump.
; `a` and `hl` will be clobbered before the jump,
; and can therefore not be used to pass data.
; Does not return.
;
; Input:
; - `1`: Symbol to call (label)
;
; Destroys: `a`, `hl`
MACRO farjump
    IF BANK(@) == 0
        ld a, BANK(\1)
        ld [hBankNumber], a
        jp \1
    ELSE
        ld a, BANK(\1)
        ld hl, \1
        jp Farjump
    ENDC
ENDM

    ENDC
