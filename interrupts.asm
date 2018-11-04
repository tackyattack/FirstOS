[BITS 32]
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
