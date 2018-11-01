extern void kernel_main()
{
  char *VGA_mem = (char*) 0xb8000;
  *VGA_mem = 'H';
}
