INCLUDE "hardware.inc/hardware.inc"



SECTION "FARCALL", ROM0

; Switches bank and calls a given address.
; Usefull when bankjumping from a non-bankable area.  
; Does NOT switch banks back after returning.  
; Lives in ROM0.
;
; Input:
; - `b`: ROM bank number
; - `hl`: Address to jump to
;
; Destroys: `a`, unknown
Farcall0::

    ; Switch banks
    ld a, b
    ld [rROMB0], a

    ; Jump
    jp hl
;



; Switches bank and calls a given address.  
; Switches banks back after returning.  
; Lives in ROM0.
;
; Input:
; - `b`: ROM bank number
; - `hl`: Address to jump to
;
; Destroys: `a`, unknown
; Saves: `rROMB0`
FarcallX::

    ; Set up things for returning
    ld a, [rRomXBank]
    push af

    ; Switch banks
    ld a, b
    ld [rROMB0], a

    ; Jump
    rst VecHL

    ; Returning after jump, reset bank number
    pop af
    ld [rROMB0], a

    ; Return
    ret
;



; Switches bank and calls a given address.  
; Switches banks back after returning.  
; Lives in ROM0.
;
; Input:
; - `d`: ROM bank number
; - `hl`: Address to jump to
;
; Destroys: `a`, unknown
; Saves: `rROMB0`
FarcallXD::

    ; Store current bank number
    ld a, [rRomXBank]
    push af

    ; Switch banks
    ld a, d
    ld [rROMB0], a

    ; Jump
    rst VecHL

    ; Returning after jump, reset banks
    pop af
    ld [rROMB0], a

    ; Return
    ret 
;



; Call anything from anywhere.  
; Use with `farcall_x` macro in `macro/farcall.inc`.  
; Lives in ROM0.
;
; Input:
; - `a`: Bank to switch to
; - `hl`: Address in bank
;
; Destroys: `a`, unknown
FarcallHandlerX::
    ldh [hBankNumber], a
    ld a, [rRomXBank]
    push af
    ldh a, [hBankNumber]
    ld [rROMB0], a
    rst VecHL
    pop af
    ld [rROMB0], a
    ret
;



; Switches ROM bank and performs a one-way jump to the given address.
; Can be used with `farjump` macro in `macro/farcall.inc`.
; Lives in ROM0.
;
; Input:
; - `a`: Bank to switch to
; - `hl`: Address in bank
;
; Saves: all
Farjump::
    ld [rROMB0], a
    jp hl
;



SECTION "FARCALL VARIABLES", HRAM

    ; Which ROM-bank is currently switched in.
    hBankNumber: ds 1
;
