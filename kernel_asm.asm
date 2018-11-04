[BITS 32]

; ---- functions for port IO ----
global read_port
global write_port
read_port:
	mov edx, [esp + 4]
  ; al is the lower 8 bits of eax
  ; dx is the lower 16 bits of edx
	in al, dx
	ret

write_port:
	mov   edx, [esp + 4]
	mov   al, [esp + 4 + 4]
	out   dx, al
	ret

; --------- interrupts --------
global irq1
global load_idt
global irq1_handler

extern irq1_handler

irq1:
  pusha
  call irq1_handler
  popa
  iret


load_idt:
	mov edx, [esp + 4]
	lidt [edx]
	sti
	ret
