[BITS 16]
;this will now be implied by the linker
;org 0x7C00

boot:
  mov [BOOT_DRIVE_NUMBER], dl ; store the boot drive

  ;mov ax, 0x2401 do we actually need A20?
  ;int 0x15

  mov ax, 0x3 ; set VGA to text mode
  int 0x10    ; set palette register interrupt

  mov bx, boot_sector_end ; where to load the sectors
  mov dh, 15              ; number of sectors to read
  mov dl, [BOOT_DRIVE_NUMBER]
  call load_from_disk

  jmp switch_pmode ; switch to protected mode

;-------------------------------------------------------------------------------
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

; constants that will be given to segment registers
; to indicate the offset in the GDT for the segment
; we want to use
CODE_SEGMENT equ gdt_code - gdt_start
DATA_SEGMENT equ gdt_data - gdt_start
;-------------------------------------------------------------------------------

BOOT_DRIVE_NUMBER:
	db 0x0

load_from_disk:
  mov ah, 0x2   ; read sector BIOS func
  mov al, dh    ; read dh amount of sectors (passed in)
  mov ch, 0x00  ; cylinder 0
  mov dh, 0x00  ; head 0
  mov cl, 0x02  ; sector 2 (skip boot sector since it's already loaded)
  int 0x13      ; interrupt the BIOS function
  ret

; switch the CPU to protected mode
switch_pmode:
  cli ; turn off interrupts so that no weird behavior happens
      ; since we're about to execute critical instructions

  lgdt [gdt_descriptor] ; load in the GDT

  mov eax, cr0  ; copy the control register
  or eax, 0x1   ; set the first bit to make the switch to PM
  mov cr0, eax

  jmp CODE_SEGMENT:boot_p ; do a long jump into the PM setup
                          ; to flush the pipeline of any
                          ; instructions

times 510-($-$$) db 0 ; fill the rest with bytes of 0
dw 0xAA55             ; indicate boot sector
boot_sector_end:

[BITS 32]
boot_p:
  mov ax, DATA_SEGMENT ; update segment registers to the proper GDT selector
  mov ds, ax           ; data
  mov ss, ax           ; stack
  mov es, ax           ; extra data
  mov fs, ax           ; more extra data
  mov gs, ax           ; still more extra data

  ;mov esp, stack_bottom ; move the stack pointer to the new spot
  ; free space -- give it 65KB (grows down) 
  mov ebp, 0x10ffff
  mov esp , ebp

  extern kernel_main
  call kernel_main
  jmp $ ; if kernel returns, stay here forever

; don't think you need this since the stack pointer
; doesn't need to have any data loaded -- it can just go
; on up to the free space since the OS will be after the boot sector
;stack_bottom:
;    times 16000-($-$$) db 0 ; setup the stack for the kernel (16KB)
;stack_top:
