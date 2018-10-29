[BITS 16]
org 0x7C00

boot:
  mov ax, 0x3 ; set VGA to text mode
  int 0x10    ; set palette register interrupt

; The Global Descriptor Table
; make two overlapping segments (code and data)
; so they reside in the same place

; note that intel x86 is little endian
gdt_start:

gdt_null:   ; must have a null entry according to the intel manual
  dd 0x0
  dd 0x0
gdt_code:   ; segment descriptor for code space
  dw 0xffff ; first word of segment limit
  dw 0x0    ; base address first word
  db 0x0    ; base address last byte

  ; type: 1010b -> code/Execute|Read
  ; flags 1001b => P(1) DPL(00) S(1)
  ; P   : segment is present
  ; DPL : Descriptor privilege level
  ; S   : descriptor type (0 = system | 1 = code/data)
  db 10011010b

  ; rest of limit bits: 1111b
  ; flags 1100b => G(1) D/B(1) L(0) AVL(0)
  ; G   : Granularity (multiplying limit to allow 4GB)
  ; D/B : Default operation size (0 = 16b | 1 = 32b)
  ; L   : 64b code segment
  ; AVL : Available for system software
  db 11001111b

  db 0x0 ; rest of base bits

gdt_data:   ; segment descriptor for data space
  dw 0xffff ; first word of segment limit
  dw 0x0    ; base address first word
  db 0x0    ; base address last byte

  ; type: 0010b -> data/read|write
  ; flags 1001b => P(1) DPL(00) S(1)
  ; P   : segment is present
  ; DPL : Descriptor privilege level
  ; S   : descriptor type (0 = system | 1 = code/data)
  db 10010010b

  ; rest of limit bits: 1111b
  ; flags 1100b => G(1) D/B(1) L(0) AVL(0)
  ; G   : Granularity (multiplying limit to allow 4GB)
  ; D/B : Default operation size (0 = 16b | 1 = 32b)
  ; L   : 64b code segment
  ; AVL : Available for system software
  db 11001111b

  db 0x0 ; rest of base bits

gdt_end: ; marker to let the asm do the math

gdt_descriptor:
  dw gdt_end - gdt_start - 1 ; size - 1
  dd  gdt_start              ; start address of GDT table

CODE_SEGMENT equ gdt_code - gdt_start
DATA_SEGMENT equ gdt_data - gdt_start

times 510-($-$$) db 0 ; fill the rest with bytes of 0
dw 0xAA55             ; indicate boot sector
