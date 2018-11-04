ASM=nasm
CC=i386-elf-gcc
LD=i386-elf-ld

# make the target
all: os.img

# link the objects
# boot.o MUST come first
os.img: boot.o kernel_asm.o kernel.o
	$(LD) -o os.img -Ttext 0x7C00 $^ --oformat binary
	python sector_pad.py os.img

kernel.o: kernel.c
	$(CC) -ffreestanding -c $< -o $@

kernel_asm.o: kernel_asm.asm
	nasm $< -f elf -o $@

boot.o: boot.asm
	nasm $< -f elf -o $@

clean:
	rm -fr *.img *.o *.bin
