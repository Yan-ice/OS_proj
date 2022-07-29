	.file	"main.c"
	.option nopic
	.attribute arch, "rv64i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.local	started
	.comm	started,4,4
	.section	.rodata
	.align	3
.LC0:
	.string	"\n"
	.align	3
.LC1:
	.string	"xv6 kernel is booting\n"
	.align	3
.LC2:
	.string	"starting kinit...\n"
	.align	3
.LC3:
	.string	"creating kernel page table...\n"
	.align	3
.LC4:
	.string	"turning on paging...\n"
	.align	3
.LC5:
	.string	"initing process table...\n"
	.align	3
.LC6:
	.string	"Init succeed\n"
	.align	3
.LC7:
	.string	"hart %d starting\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-16
	sd	ra,8(sp)
	sd	s0,0(sp)
	addi	s0,sp,16
	call	cpuid
	mv	a5,a0
	bnez	a5,.L5
	call	consoleinit
	call	printfinit
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	printf
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	printf
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	printf
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	printf
	call	kinit
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	printf
	call	kvminit
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	printf
	call	kvminithart
	lui	a5,%hi(.LC5)
	addi	a0,a5,%lo(.LC5)
	call	printf
	call	procinit
	call	trapinit
	call	trapinithart
	call	plicinit
	call	plicinithart
	call	binit
	call	iinit
	call	fileinit
	call	virtio_disk_init
	call	userinit
	fence	iorw,iorw
	lui	a5,%hi(started)
	li	a4,1
	sw	a4,%lo(started)(a5)
	lui	a5,%hi(.LC6)
	addi	a0,a5,%lo(.LC6)
	call	printf
	j	.L3
.L5:
	nop
.L4:
	lui	a5,%hi(started)
	lw	a5,%lo(started)(a5)
	sext.w	a5,a5
	beqz	a5,.L4
	fence	iorw,iorw
	call	cpuid
	mv	a5,a0
	mv	a1,a5
	lui	a5,%hi(.LC7)
	addi	a0,a5,%lo(.LC7)
	call	printf
	call	kvminithart
	call	trapinithart
	call	plicinithart
.L3:
	call	scheduler
	.size	main, .-main
	.ident	"GCC: () 9.3.0"
