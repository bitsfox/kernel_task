boot.img:boot.elf head.elf
	dd bs=512 if=boot.elf of=boot.img count=1
	dd bs=512 if=head.elf of=boot.img seek=1 count=16
	dd bs=512 if=/dev/zero of=boot.img seek=17 count=2863
head.elf:head.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary head.bin head.elf
boot.elf:boot.bin
	objcopy -R .pdr -R .comment -R .note -S -O binary boot.bin boot.elf
head.bin:head.o
	ld -o head.bin head.o -Ttext 0
boot.bin:boot.o
	ld -o boot.bin boot.o -Ttext 0
head.o:h01.s
	as -o head.o h01.s
boot.o:a01.s
	as -o boot.o a01.s
clean:
	rm boot.* head.*

