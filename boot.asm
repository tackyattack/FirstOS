[BITS 16]
org 0x7C00

times 510-($-$$) db 0 ; fill the rest with bytes of 0
dw 0xAA55             ; indicate boot sector
