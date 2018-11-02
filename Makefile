ASM=nasm
CC=i386-elf-gcc
LD=i386-elf-ld

# make the target
all: os.img

# link the objects
# boot.o MUST come first
os.img: boot.o interrupts.o kernel.o
	$(LD) -o os.img -Ttext 0x7C00 $^ --oformat binary

kernel.o: kernel.c
	$(CC) -ffreestanding -c $< -o $@

interrupts.o: interrupts.asm
	nasm $< -f elf -o $@

boot.o: boot.asm
	nasm $< -f elf -o $@

clean:
	rm -fr *.img *.o *.bin
