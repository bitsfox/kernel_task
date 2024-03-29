.include"/workarea/cprogram/kernel/include/defconst.inc"
.data
.text
.org 0
	movl $0x28,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%gs
	movl $0x18,%eax
	movw %ax,%fs
	lss stk,%esp
	lgdt l_gdt
	movl $0x28,%eax
	movw %ax,%ds
	movw %ax,%es
	movw %ax,%gs
	movl $0x18,%eax
	movw %ax,%fs
	call reset_8253
	call setup_idt
	lidt l_idt
	push %fs
	pop %es
	leal msg1,%esi
	movl $160,%edi
	movl $len,%ecx
	movb $0x0c,%ah
1:
	lodsb
	stosw
	loop 1b
	pushfl
	andl $0xffffbfff,(%esp)
	popfl
	movl $0x30,%eax
	ltr %ax
	movl $0x38,%eax
	lldt %ax
	movl $0,%eax
	movl %eax,count
	sti
	pushl $0x17
	pushl $stk
	pushfl 
	pushl $0x0f
	pushl $task0
	iret
	jmp .

#{{{ reset_8253
reset_8253:
	movl $0x36,%eax
	movl $0x43,%edx
	outb %al,%dx
	xorl %eax,%eax
	movl $0x40,%edx
	movw $11930,%ax
	outb %al,%dx
	movb %ah,%al
	outb %al,%dx
	ret
#}}}
#{{{ setup_idt	
setup_idt:
	leal idt,%edi
	movl $nor_int,%edx
	movl $0x00200000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $256,%ecx
1:
	movl %eax,(%edi)
	movl %edx,4(%edi)
	addl $8,%edi
	loop 1b
	#set int 8
	movl $time_int,%edx
	movl $0x00200000,%eax
	movw %dx,%ax
	movw $0x8e00,%dx
	movl $8,%ebx
	leal idt(,%ebx,8),%edi
	movl %eax,(%edi)
	movl %edx,4(%edi)
	#set int 0x80
	movl $disp_int,%edx
	movl $0x00200000,%eax
	movw %dx,%ax
	movw $0xef00,%dx
	movl $0x80,%ebx
	leal idt(,%ebx,8),%edi
	movl %eax,(%edi)
	movl %edx,4(%edi)
	ret
#}}}
#{{{ nor_int
nor_int:
	pusha
	push %ds
	push %es
	push %fs
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x18,%eax
	movw %ax,%fs
	push %fs
	pop  %es
	movl $450,%edi
	movl $0x0e41,%eax
	stosw
#movl $1,%eax
#	movl %eax,count
	push %ds
	pop  %es
	pop %fs
	pop %es
	pop %ds
	popa
	iret
#}}}	
#{{{ time_int
time_int:
	push %ds
	pushl %eax
	movl $0x28,%eax
	movw %ax,%ds
	movl $0x20,%eax
	outb %al,$0x20
	movl $1,%eax
	cmpl %eax,count
	je  1f
	movl %eax,count
	ljmp $0x40,$0
	jmp 2f
1:
	movl $0,%eax
	movl %eax,count
	ljmp $0x30,$0 
2:
	popl %eax
	pop %ds
	iret
#}}}
#{{{ disp_int
disp_int:
	pusha
	
	popa
	iret
#}}}	
#{{{task0
task0:
	movl $0x17,%eax
	movw %ax,%ds
	movw %ax,%fs
	movl $0x1f,%eax
	movw %ax,%es
	movl $800,%edi
	movl $0x0720,%ebx
	movl $0x0e41,%eax
1:
	movw %bx,%es:(%edi)
	addl $2,%edi
	cmpl $960,%edi
	jb	 2f
	movl $800,%edi
2:
#stosw
	movw %ax,%es:(%edi)
	incl %eax
	cmpb $'Z,%al
	jbe 3f
	movl $0x0e41,%eax
3:
	movl $0x010fffff,%ecx
	loop .
	jmp 1b
	ret
#}}}
#{{{task1
task1:
	movl $0x17,%eax
	movw %ax,%ds
	movw %ax,%fs
	movl $0x1f,%eax
	movw %ax,%es
	movl $960,%edi
	movl $0x0720,%ebx
	movl $0x0d41,%eax
1:
	movw %bx,%es:(%edi)
	addl $2,%edi
	cmpl $1120,%edi
	jb	 2f
	movl $960,%edi
2:
#stosw
	movw %ax,%es:(%edi)
	incl %eax
	cmpb $'Z,%al
	jbe 3f
	movl $0x0d41,%eax
3:
	movl $0x010fffff,%ecx
	loop . 
	jmp 1b
	ret
#}}}
	
.space 0x200,0
stk:	.long stk,0x28
l_idt:	.word 2048,HEAD_BASEADDR+idt,0
idt:	.space 2048,0
l_gdt:	.word 80,HEAD_BASEADDR+gdt,0
gdt:	.word 0,0,0,0
		.word 1,BOOT_BASEADDR,0x9a00,0x00c0		# 0x08
		.word 1,BOOT_BASEADDR,0x9200,0x00c0		# 0x10
		.word 2,0x8000,0x920b,0x00c0			# 0x18
		.word 2,HEAD_BASEADDR,0x9a00,0x00c0		# 0x20
		.word 2,HEAD_BASEADDR,0x9200,0x00c0		# 0x28
		.word 0x68,HEAD_BASEADDR+tss0,0xe900,0  # 0x30  tss0
		.word 0x20,HEAD_BASEADDR+ldt0,0xe200,0  # 0x38  ldt0
		.word 0x68,HEAD_BASEADDR+tss1,0xe900,0  # 0x40  tss1
		.word 0x20,HEAD_BASEADDR+ldt1,0xe200,0  # 0x48  ldt1
tss0:	.long 0						#back link
		.long stk0,0x28				#esp0,ss0
		.long 0,0,0,0,0				#esp1,ss1,esp2,ss2,cr3
		.long 0,0,0,0,0				#eip,eflags,eax,ecx,edx
		.long 0,0,0,0,0				#ebx,esp,ebp,esi,edi
		.long 0,0,0,0,0,0			#es,cs,ss,ds,fs,gs
		.long 0x38,0x8000000		#ldt,io-map
ldt0:	.word 0,0,0,0
		.word 2,HEAD_BASEADDR,0xfa00,0x0c0  #0xf
		.word 2,HEAD_BASEADDR,0xf200,0x0c0  #0x17
		.word 2,0x8000,0xf20b,0x0c0		   #0x1f user model disp	
tss1:
		.long 0
		.long stk1,0x28
		.long 0,0,0,0,0
		.long task1,0x200,0,0,0
		.long 0,ustk1,0,0,0
		.long 0x17,0x0f,0x17,0x17,0x17,0x17
		.long 0x48,0x8000000
ldt1:	.word 0,0,0,0
		.word 2,HEAD_BASEADDR,0xfa00,0x0c0  #0xf
		.word 2,HEAD_BASEADDR,0xf200,0x0c0  #0x17
		.word 2,0x8000,0xf20b,0x0c0		   #0x1f user model disp	
.space  0x100
.space  0x100
stk0:
.space  0x100
stk1:
.space  0x100
ustk1:
msg1:	.ascii "booting: reset gdt/idt.........................[ok]"
len=.-msg1
msg2:	.ascii "heading: ready to enter user model.............[ok]"
count:	.long 0
pos:	.long 0

.org 8188
.ascii "ttyy"





