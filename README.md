Learning how to create an OS from scratch to better understand the boot process.
Also, note that for it to work on VirtualBox using just the .img file generated
from the Makefile, you must append bytes of 0 until it reaches a multiple of 512
for it to read as a valid floppy image. This is because the sector size is 512...
Banged my head into the desk after spending hours wondering why VB wouldn't take
the image.
