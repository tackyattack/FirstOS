extern char read_port(unsigned short port);
extern void write_port(unsigned short port, unsigned char data);

char QWERTY[] = {'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p',
                 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l',
                  'z', 'x', 'c', 'v', 'b', 'n', 'm'};

char key_map_OSX(char scancode)
{
  char ret = 0;
  if(scancode >= 2 && scancode <= 10)
  {
    scancode = scancode - 2;
    ret = scancode + 49;
  }
  else if(scancode == 11)
  {
    ret = 48;
  }
  else if(scancode >= 16 && scancode <= 25)
  {
    scancode = scancode - 16;
    ret = QWERTY[scancode];
  }
  else if(scancode >= 30 && scancode <= 38)
  {
    scancode = scancode - 30;
    ret = QWERTY[scancode + 10];
  }
  else if(scancode >= 44 && scancode <= 50)
  {
    scancode = scancode - 44;
    ret = QWERTY[scancode + 19];
  }
  else if(scancode == 57)
  {
    ret = 32; // space bar
  }
  else if(scancode == 14 || scancode == 15)
  {
    ret = 127; // delete
  }
  return ret;
}

void textedit(char ascii_val)
{
  char *VGA_mem = (char*) 0xb8000;
  static int text_pos = 0;
  if((ascii_val >= 'a' && ascii_val <= 'z' || ascii_val == ' ')
    && (text_pos < 80*25))
  {
    VGA_mem[text_pos*2] = ascii_val;
    VGA_mem[text_pos*2 + 1] = 0x0A;
    text_pos++;
  }
  else if(ascii_val == 127 && text_pos >= 0)
  {
    if(text_pos > 0) text_pos--;
    VGA_mem[text_pos*2] = 0x00;
    VGA_mem[text_pos*2 + 1] = 0x0A;
  }
}

struct IDT_entry{
	unsigned short int offset_lowerbits;
	unsigned short int selector;
	unsigned char zero;
	unsigned char type_attr;
	unsigned short int offset_higherbits;
};

struct IDT_entry IDT[286]; // 255 + 31

void idt_init(void)
 {
   extern int KERNEL_CODE_SEGMENT_OFFSET;
   extern int load_idt();
   extern int irq1();
   unsigned long irq1_address;
   unsigned long idt_address;
   unsigned long idt_ptr[2];

  /* remapping the PIC */

  // Usually modern systems have 2 PICs -- each with 8 lines
  // PIC1 gets IRQ0-IRQ7 and PIC2 gets IRQ8 to IRQ15
  // PIC1: port 0x20 is command
  //       port 0x21 is data
  // PIC2: port 0xA0 is command
  //       port 0xA1 is data

  // ICW : initial command word -- commands used to setup PICS

  // ICW1: init
  // PIC1 and PIC2 now expect three more ICWs
  write_port(0x20, 0x11);
  write_port(0xA0, 0x11);

  // ICW2: vector offset
  // remap offset addr of IDT
  // (must be beyond first 32 since Intel reserves those)
  write_port(0x21, 0x20);
  write_port(0xA1, 0x28);

  // ICW3: how the PICs are wired as master/slave
  // cascading -- set to 0 since we don't need this
	write_port(0x21 , 0x00);
	write_port(0xA1 , 0x00);

	// ICW4: information about environment
  // set lower bits to tell them to run in 80x86 mode
	write_port(0x21 , 0x01);
	write_port(0xA1 , 0x01);

  // end of init

	// mask interrupts
  // setting a bit disables IRQ
  // turn them all off for now
	write_port(0x21 , 0xff);
	write_port(0xA1 , 0xff);

	irq1_address = (unsigned long)irq1;
	IDT[33].offset_lowerbits = irq1_address & 0xffff;
	IDT[33].selector = KERNEL_CODE_SEGMENT_OFFSET; // segment offset to the Kernel code
	IDT[33].zero = 0;
	IDT[33].type_attr = 0x8e; // interrupt gate
	IDT[33].offset_higherbits = (irq1_address & 0xffff0000) >> 16;

	/* fill the IDT descriptor */
	idt_address = (unsigned long)IDT ;
	idt_ptr[0] = (sizeof (struct IDT_entry) * 286) + ((idt_address & 0xffff) << 16);
	idt_ptr[1] = idt_address >> 16 ;

	load_idt(idt_ptr);

  // 0xFD is 11111101 - enables only IRQ1 -- which is the keyboard
	write_port(0x21 , 0xFD);

}

void irq1_handler(void) {

  char c = read_port(0x60);
  if(c > 0)
  {
    textedit(key_map_OSX(c));
  }

  write_port(0x20, 0x20); //EOI
}

extern void kernel_main()
{
  idt_init();
  char x = 0;
  while(1)
  {
    x = x + 1;
  }
}
