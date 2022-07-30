
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00010117          	auipc	sp,0x10
    80000004:	18010113          	addi	sp,sp,384 # 80010180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00010717          	auipc	a4,0x10
    80000056:	fee70713          	addi	a4,a4,-18 # 80010040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	cec78793          	addi	a5,a5,-788 # 80005d50 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffc67ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	50e080e7          	jalr	1294(ra) # 8000263a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00018517          	auipc	a0,0x18
    80000190:	ff450513          	addi	a0,a0,-12 # 80018180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00018497          	auipc	s1,0x18
    800001a0:	fe448493          	addi	s1,s1,-28 # 80018180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00018917          	auipc	s2,0x18
    800001aa:	07290913          	addi	s2,s2,114 # 80018218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	98c080e7          	jalr	-1652(ra) # 80001b50 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	06c080e7          	jalr	108(ra) # 80002240 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	3d4080e7          	jalr	980(ra) # 800025e4 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00018517          	auipc	a0,0x18
    80000228:	f5c50513          	addi	a0,a0,-164 # 80018180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00018517          	auipc	a0,0x18
    8000023e:	f4650513          	addi	a0,a0,-186 # 80018180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00018717          	auipc	a4,0x18
    80000276:	faf72323          	sw	a5,-90(a4) # 80018218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00018517          	auipc	a0,0x18
    800002d0:	eb450513          	addi	a0,a0,-332 # 80018180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	39e080e7          	jalr	926(ra) # 80002690 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00018517          	auipc	a0,0x18
    800002fe:	e8650513          	addi	a0,a0,-378 # 80018180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00018717          	auipc	a4,0x18
    80000322:	e6270713          	addi	a4,a4,-414 # 80018180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00018797          	auipc	a5,0x18
    8000034c:	e3878793          	addi	a5,a5,-456 # 80018180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00018797          	auipc	a5,0x18
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80018218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00018717          	auipc	a4,0x18
    8000038e:	df670713          	addi	a4,a4,-522 # 80018180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00018497          	auipc	s1,0x18
    8000039e:	de648493          	addi	s1,s1,-538 # 80018180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00018717          	auipc	a4,0x18
    800003da:	daa70713          	addi	a4,a4,-598 # 80018180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00018717          	auipc	a4,0x18
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80018220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00018797          	auipc	a5,0x18
    80000416:	d6e78793          	addi	a5,a5,-658 # 80018180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00018797          	auipc	a5,0x18
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001821c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00018517          	auipc	a0,0x18
    80000442:	dda50513          	addi	a0,a0,-550 # 80018218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	f86080e7          	jalr	-122(ra) # 800023cc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	0000c597          	auipc	a1,0xc
    8000045c:	bb858593          	addi	a1,a1,-1096 # 8000c010 <etext+0x10>
    80000460:	00018517          	auipc	a0,0x18
    80000464:	d2050513          	addi	a0,a0,-736 # 80018180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00028797          	auipc	a5,0x28
    8000047c:	ea078793          	addi	a5,a5,-352 # 80028318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	0000c617          	auipc	a2,0xc
    800004be:	b8660613          	addi	a2,a2,-1146 # 8000c040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00018797          	auipc	a5,0x18
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80018240 <pr+0x18>
  printf("panic: ");
    80000552:	0000c517          	auipc	a0,0xc
    80000556:	ac650513          	addi	a0,a0,-1338 # 8000c018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	0000c517          	auipc	a0,0xc
    80000570:	bb450513          	addi	a0,a0,-1100 # 8000c120 <digits+0xe0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00010717          	auipc	a4,0x10
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80010000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00018d97          	auipc	s11,0x18
    800005be:	c86dad83          	lw	s11,-890(s11) # 80018240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	0000cb97          	auipc	s7,0xc
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 8000c040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00018517          	auipc	a0,0x18
    800005fc:	c3050513          	addi	a0,a0,-976 # 80018228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	0000c517          	auipc	a0,0xc
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 8000c028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 0);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4601                	li	a2,0
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	0000c917          	auipc	s2,0xc
    8000070e:	91690913          	addi	s2,s2,-1770 # 8000c020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00018517          	auipc	a0,0x18
    80000760:	acc50513          	addi	a0,a0,-1332 # 80018228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00018497          	auipc	s1,0x18
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80018228 <pr>
    80000780:	0000c597          	auipc	a1,0xc
    80000784:	8b858593          	addi	a1,a1,-1864 # 8000c038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	0000c597          	auipc	a1,0xc
    800007d4:	88858593          	addi	a1,a1,-1912 # 8000c058 <digits+0x18>
    800007d8:	00018517          	auipc	a0,0x18
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80018248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	0000f797          	auipc	a5,0xf
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80010000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	0000f717          	auipc	a4,0xf
    80000844:	7c873703          	ld	a4,1992(a4) # 80010008 <uart_tx_r>
    80000848:	0000f797          	auipc	a5,0xf
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80010010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00018a17          	auipc	s4,0x18
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80018248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	0000f497          	auipc	s1,0xf
    80000876:	79648493          	addi	s1,s1,1942 # 80010008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	0000f997          	auipc	s3,0xf
    8000087e:	79698993          	addi	s3,s3,1942 # 80010010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b2c080e7          	jalr	-1236(ra) # 800023cc <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00018517          	auipc	a0,0x18
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80018248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	0000f797          	auipc	a5,0xf
    800008f0:	7147a783          	lw	a5,1812(a5) # 80010000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	0000f797          	auipc	a5,0xf
    800008fc:	7187b783          	ld	a5,1816(a5) # 80010010 <uart_tx_w>
    80000900:	0000f717          	auipc	a4,0xf
    80000904:	70873703          	ld	a4,1800(a4) # 80010008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00018a17          	auipc	s4,0x18
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80018248 <uart_tx_lock>
    80000918:	0000f497          	auipc	s1,0xf
    8000091c:	6f048493          	addi	s1,s1,1776 # 80010008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	0000f917          	auipc	s2,0xf
    80000924:	6f090913          	addi	s2,s2,1776 # 80010010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	914080e7          	jalr	-1772(ra) # 80002240 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00018497          	auipc	s1,0x18
    80000946:	90648493          	addi	s1,s1,-1786 # 80018248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	0000f717          	auipc	a4,0xf
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80010010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00018497          	auipc	s1,0x18
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80018248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03251793          	slli	a5,a0,0x32
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00037797          	auipc	a5,0x37
    80000a10:	5f478793          	addi	a5,a5,1524 # 80038000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6611                	lui	a2,0x4
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00018917          	auipc	s2,0x18
    80000a30:	85490913          	addi	s2,s2,-1964 # 80018280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	0000b517          	auipc	a0,0xb
    80000a62:	60250513          	addi	a0,a0,1538 # 8000c060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6791                	lui	a5,0x4
    80000a80:	fff78493          	addi	s1,a5,-1 # 3fff <_entry-0x7fffc001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	7571                	lui	a0,0xffffc
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a71                	lui	s4,0xffffc
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6991                	lui	s3,0x4
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	0000b597          	auipc	a1,0xb
    80000ac4:	5a858593          	addi	a1,a1,1448 # 8000c068 <digits+0x28>
    80000ac8:	00017517          	auipc	a0,0x17
    80000acc:	7b850513          	addi	a0,a0,1976 # 80018280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00037517          	auipc	a0,0x37
    80000ae0:	52450513          	addi	a0,a0,1316 # 80038000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00017497          	auipc	s1,0x17
    80000b02:	78248493          	addi	s1,s1,1922 # 80018280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00017517          	auipc	a0,0x17
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80018280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6611                	lui	a2,0x4
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00017517          	auipc	a0,0x17
    80000b46:	73e50513          	addi	a0,a0,1854 # 80018280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	fb6080e7          	jalr	-74(ra) # 80001b34 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	f84080e7          	jalr	-124(ra) # 80001b34 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f78080e7          	jalr	-136(ra) # 80001b34 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f60080e7          	jalr	-160(ra) # 80001b34 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	f20080e7          	jalr	-224(ra) # 80001b34 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	0000b517          	auipc	a0,0xb
    80000c2c:	44850513          	addi	a0,a0,1096 # 8000c070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ef4080e7          	jalr	-268(ra) # 80001b34 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	0000b517          	auipc	a0,0xb
    80000c7c:	40050513          	addi	a0,a0,1024 # 8000c078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	0000b517          	auipc	a0,0xb
    80000c8c:	40850513          	addi	a0,a0,1032 # 8000c090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	0000b517          	auipc	a0,0xb
    80000cd4:	3c850513          	addi	a0,a0,968 # 8000c098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	c8e080e7          	jalr	-882(ra) # 80001b24 <cpuid>
    __sync_synchronize();
    started = 1;
    printf("Init succeed\n");
  } else {
   // return;
    while(started == 0)
    80000e9e:	0000f717          	auipc	a4,0xf
    80000ea2:	17a70713          	addi	a4,a4,378 # 80010018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	c72080e7          	jalr	-910(ra) # 80001b24 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	0000b517          	auipc	a0,0xb
    80000ec0:	27c50513          	addi	a0,a0,636 # 8000c138 <digits+0xf8>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	128080e7          	jalr	296(ra) # 80000ff4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	8fc080e7          	jalr	-1796(ra) # 800027d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	eb4080e7          	jalr	-332(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1aa080e7          	jalr	426(ra) # 8000208e <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	0000b517          	auipc	a0,0xb
    80000f00:	22450513          	addi	a0,a0,548 # 8000c120 <digits+0xe0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	0000b517          	auipc	a0,0xb
    80000f10:	19450513          	addi	a0,a0,404 # 8000c0a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	0000b517          	auipc	a0,0xb
    80000f20:	20450513          	addi	a0,a0,516 # 8000c120 <digits+0xe0>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    printf("starting kinit...\n");
    80000f2c:	0000b517          	auipc	a0,0xb
    80000f30:	18c50513          	addi	a0,a0,396 # 8000c0b8 <digits+0x78>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	654080e7          	jalr	1620(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	b7c080e7          	jalr	-1156(ra) # 80000ab8 <kinit>
    printf("creating kernel page table...\n");
    80000f44:	0000b517          	auipc	a0,0xb
    80000f48:	18c50513          	addi	a0,a0,396 # 8000c0d0 <digits+0x90>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	63c080e7          	jalr	1596(ra) # 80000588 <printf>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	486080e7          	jalr	1158(ra) # 800013da <kvminit>
    printf("turning on paging...\n");
    80000f5c:	0000b517          	auipc	a0,0xb
    80000f60:	19450513          	addi	a0,a0,404 # 8000c0f0 <digits+0xb0>
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	624080e7          	jalr	1572(ra) # 80000588 <printf>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	088080e7          	jalr	136(ra) # 80000ff4 <kvminithart>
    printf("initing process table...\n");
    80000f74:	0000b517          	auipc	a0,0xb
    80000f78:	19450513          	addi	a0,a0,404 # 8000c108 <digits+0xc8>
    80000f7c:	fffff097          	auipc	ra,0xfffff
    80000f80:	60c080e7          	jalr	1548(ra) # 80000588 <printf>
    procinit();      // process table
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	af0080e7          	jalr	-1296(ra) # 80001a74 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	81c080e7          	jalr	-2020(ra) # 800027a8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00002097          	auipc	ra,0x2
    80000f98:	83c080e7          	jalr	-1988(ra) # 800027d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	dde080e7          	jalr	-546(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	dec080e7          	jalr	-532(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	f82080e7          	jalr	-126(ra) # 80002f2e <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	624080e7          	jalr	1572(ra) # 800035d8 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	5ce080e7          	jalr	1486(ra) # 8000458a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	eee080e7          	jalr	-274(ra) # 80005eb2 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	e5c080e7          	jalr	-420(ra) # 80001e28 <userinit>
    __sync_synchronize();
    80000fd4:	0ff0000f          	fence
    started = 1;
    80000fd8:	4785                	li	a5,1
    80000fda:	0000f717          	auipc	a4,0xf
    80000fde:	02f72f23          	sw	a5,62(a4) # 80010018 <started>
    printf("Init succeed\n");
    80000fe2:	0000b517          	auipc	a0,0xb
    80000fe6:	14650513          	addi	a0,a0,326 # 8000c128 <digits+0xe8>
    80000fea:	fffff097          	auipc	ra,0xfffff
    80000fee:	59e080e7          	jalr	1438(ra) # 80000588 <printf>
    80000ff2:	bdcd                	j	80000ee4 <main+0x56>

0000000080000ff4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart(void)
{
    80000ff4:	1141                	addi	sp,sp,-16
    80000ff6:	e422                	sd	s0,8(sp)
    80000ff8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffa:	0000f797          	auipc	a5,0xf
    80000ffe:	0267b783          	ld	a5,38(a5) # 80010020 <kernel_pagetable>
    80001002:	83b9                	srli	a5,a5,0xe
    80001004:	577d                	li	a4,-1
    80001006:	177e                	slli	a4,a4,0x3f
    80001008:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100e:	12000073          	sfence.vma
  sfence_vma();

}
    80001012:	6422                	ld	s0,8(sp)
    80001014:	0141                	addi	sp,sp,16
    80001016:	8082                	ret

0000000080001018 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc, int print)
{
    80001018:	711d                	addi	sp,sp,-96
    8000101a:	ec86                	sd	ra,88(sp)
    8000101c:	e8a2                	sd	s0,80(sp)
    8000101e:	e4a6                	sd	s1,72(sp)
    80001020:	e0ca                	sd	s2,64(sp)
    80001022:	fc4e                	sd	s3,56(sp)
    80001024:	f852                	sd	s4,48(sp)
    80001026:	f456                	sd	s5,40(sp)
    80001028:	f05a                	sd	s6,32(sp)
    8000102a:	ec5e                	sd	s7,24(sp)
    8000102c:	e862                	sd	s8,16(sp)
    8000102e:	e466                	sd	s9,8(sp)
    80001030:	1080                	addi	s0,sp,96
    80001032:	84aa                	mv	s1,a0
    80001034:	892e                	mv	s2,a1
    80001036:	8b32                	mv	s6,a2
    80001038:	8a36                	mv	s4,a3
  if(print){
    8000103a:	e68d                	bnez	a3,80001064 <walk+0x4c>
	  printf("tracing virtual address %x:\n",va);
  }
  if(va >= MAXVA)
    8000103c:	57fd                	li	a5,-1
    8000103e:	83ed                	srli	a5,a5,0x1b
    80001040:	02000a93          	li	s5,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001044:	4989                	li	s3,2
    pte_t *pte = &pagetable[PX(level, va)];
	  if(print){
		  printf("[lv%d] table %x, entry %d >> PA %x (PTE%x)\n",
    80001046:	4c09                	li	s8,2
    80001048:	0000bb97          	auipc	s7,0xb
    8000104c:	130b8b93          	addi	s7,s7,304 # 8000c178 <digits+0x138>
  if(va >= MAXVA)
    80001050:	0727fa63          	bgeu	a5,s2,800010c4 <walk+0xac>
    panic("walk");
    80001054:	0000b517          	auipc	a0,0xb
    80001058:	11c50513          	addi	a0,a0,284 # 8000c170 <digits+0x130>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
	  printf("tracing virtual address %x:\n",va);
    80001064:	0000b517          	auipc	a0,0xb
    80001068:	0ec50513          	addi	a0,a0,236 # 8000c150 <digits+0x110>
    8000106c:	fffff097          	auipc	ra,0xfffff
    80001070:	51c080e7          	jalr	1308(ra) # 80000588 <printf>
    80001074:	b7e1                	j	8000103c <walk+0x24>
				  2-level, pagetable, PX(level,va), PTE2PA(*pte), *pte);
    80001076:	000cb783          	ld	a5,0(s9)
    8000107a:	00a7d713          	srli	a4,a5,0xa
		  printf("[lv%d] table %x, entry %d >> PA %x (PTE%x)\n",
    8000107e:	073a                	slli	a4,a4,0xe
    80001080:	8626                	mv	a2,s1
    80001082:	413c05bb          	subw	a1,s8,s3
    80001086:	855e                	mv	a0,s7
    80001088:	fffff097          	auipc	ra,0xfffff
    8000108c:	500080e7          	jalr	1280(ra) # 80000588 <printf>
    80001090:	a099                	j	800010d6 <walk+0xbe>
	  }
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001092:	0c0b0e63          	beqz	s6,8000116e <walk+0x156>
    80001096:	00000097          	auipc	ra,0x0
    8000109a:	a5e080e7          	jalr	-1442(ra) # 80000af4 <kalloc>
    8000109e:	84aa                	mv	s1,a0
    800010a0:	c969                	beqz	a0,80001172 <walk+0x15a>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010a2:	6611                	lui	a2,0x4
    800010a4:	4581                	li	a1,0
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	c3a080e7          	jalr	-966(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ae:	00e4d793          	srli	a5,s1,0xe
    800010b2:	07aa                	slli	a5,a5,0xa
    800010b4:	0017e793          	ori	a5,a5,1
    800010b8:	00fcb023          	sd	a5,0(s9)
  for(int level = 2; level > 0; level--) {
    800010bc:	39fd                	addiw	s3,s3,-1
    800010be:	3add                	addiw	s5,s5,-9
    800010c0:	02098363          	beqz	s3,800010e6 <walk+0xce>
    pte_t *pte = &pagetable[PX(level, va)];
    800010c4:	015956b3          	srl	a3,s2,s5
    800010c8:	1ff6f693          	andi	a3,a3,511
    800010cc:	00369c93          	slli	s9,a3,0x3
    800010d0:	9ca6                	add	s9,s9,s1
	  if(print){
    800010d2:	fa0a12e3          	bnez	s4,80001076 <walk+0x5e>
    if(*pte & PTE_V) {
    800010d6:	000cb483          	ld	s1,0(s9)
    800010da:	0014f793          	andi	a5,s1,1
    800010de:	dbd5                	beqz	a5,80001092 <walk+0x7a>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e0:	80a9                	srli	s1,s1,0xa
    800010e2:	04ba                	slli	s1,s1,0xe
    800010e4:	bfe1                	j	800010bc <walk+0xa4>
    }
  }
  pte_t final_pte = pagetable[PX(0,va)];
    800010e6:	00e95613          	srli	a2,s2,0xe
    800010ea:	1ff67613          	andi	a2,a2,511
    800010ee:	00361993          	slli	s3,a2,0x3
    800010f2:	99a6                	add	s3,s3,s1
  if(print){
    800010f4:	020a1063          	bnez	s4,80001114 <walk+0xfc>
	  }else{
		  printf("[value] stored in pageframe %x, entry %d >> PA %x.\n",pageframe, va & 0x3FFF,(pageframe+(va&0x3FF)));
	  }
  }
  return &pagetable[PX(0, va)];
}
    800010f8:	854e                	mv	a0,s3
    800010fa:	60e6                	ld	ra,88(sp)
    800010fc:	6446                	ld	s0,80(sp)
    800010fe:	64a6                	ld	s1,72(sp)
    80001100:	6906                	ld	s2,64(sp)
    80001102:	79e2                	ld	s3,56(sp)
    80001104:	7a42                	ld	s4,48(sp)
    80001106:	7aa2                	ld	s5,40(sp)
    80001108:	7b02                	ld	s6,32(sp)
    8000110a:	6be2                	ld	s7,24(sp)
    8000110c:	6c42                	ld	s8,16(sp)
    8000110e:	6ca2                	ld	s9,8(sp)
    80001110:	6125                	addi	sp,sp,96
    80001112:	8082                	ret
  pte_t final_pte = pagetable[PX(0,va)];
    80001114:	0009ba03          	ld	s4,0(s3) # 4000 <_entry-0x7fffc000>
          printf("[lv2] table %x, entry %d >> PA %x (PTE%x)\n",pagetable, PX(0,va), PTE2PA(final_pte),final_pte );
    80001118:	00aa5a93          	srli	s5,s4,0xa
    8000111c:	0aba                	slli	s5,s5,0xe
    8000111e:	8752                	mv	a4,s4
    80001120:	86d6                	mv	a3,s5
    80001122:	85a6                	mv	a1,s1
    80001124:	0000b517          	auipc	a0,0xb
    80001128:	08450513          	addi	a0,a0,132 # 8000c1a8 <digits+0x168>
    8000112c:	fffff097          	auipc	ra,0xfffff
    80001130:	45c080e7          	jalr	1116(ra) # 80000588 <printf>
	  if((final_pte & PTE_V) == 0){
    80001134:	001a7a13          	andi	s4,s4,1
    80001138:	000a1b63          	bnez	s4,8000114e <walk+0x136>
		  printf("[value] pagetable is invalid.");
    8000113c:	0000b517          	auipc	a0,0xb
    80001140:	09c50513          	addi	a0,a0,156 # 8000c1d8 <digits+0x198>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	444080e7          	jalr	1092(ra) # 80000588 <printf>
    8000114c:	b775                	j	800010f8 <walk+0xe0>
		  printf("[value] stored in pageframe %x, entry %d >> PA %x.\n",pageframe, va & 0x3FFF,(pageframe+(va&0x3FF)));
    8000114e:	3ff97693          	andi	a3,s2,1023
    80001152:	03291613          	slli	a2,s2,0x32
    80001156:	96d6                	add	a3,a3,s5
    80001158:	9249                	srli	a2,a2,0x32
    8000115a:	85d6                	mv	a1,s5
    8000115c:	0000b517          	auipc	a0,0xb
    80001160:	09c50513          	addi	a0,a0,156 # 8000c1f8 <digits+0x1b8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	424080e7          	jalr	1060(ra) # 80000588 <printf>
    8000116c:	b771                	j	800010f8 <walk+0xe0>
        return 0;
    8000116e:	4981                	li	s3,0
    80001170:	b761                	j	800010f8 <walk+0xe0>
    80001172:	89aa                	mv	s3,a0
    80001174:	b751                	j	800010f8 <walk+0xe0>

0000000080001176 <trace_mem>:

void trace_mem(pagetable_t pagetable, uint64 va){
    80001176:	1141                	addi	sp,sp,-16
    80001178:	e406                	sd	ra,8(sp)
    8000117a:	e022                	sd	s0,0(sp)
    8000117c:	0800                	addi	s0,sp,16
	walk(pagetable,va,0,1);
    8000117e:	4685                	li	a3,1
    80001180:	4601                	li	a2,0
    80001182:	00000097          	auipc	ra,0x0
    80001186:	e96080e7          	jalr	-362(ra) # 80001018 <walk>
}
    8000118a:	60a2                	ld	ra,8(sp)
    8000118c:	6402                	ld	s0,0(sp)
    8000118e:	0141                	addi	sp,sp,16
    80001190:	8082                	ret

0000000080001192 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001192:	57fd                	li	a5,-1
    80001194:	83ed                	srli	a5,a5,0x1b
    80001196:	00b7f463          	bgeu	a5,a1,8000119e <walkaddr+0xc>
    return 0;
    8000119a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000119c:	8082                	ret
{
    8000119e:	1141                	addi	sp,sp,-16
    800011a0:	e406                	sd	ra,8(sp)
    800011a2:	e022                	sd	s0,0(sp)
    800011a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0, 0);
    800011a6:	4681                	li	a3,0
    800011a8:	4601                	li	a2,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	e6e080e7          	jalr	-402(ra) # 80001018 <walk>
  if(pte == 0)
    800011b2:	c105                	beqz	a0,800011d2 <walkaddr+0x40>
  if((*pte & PTE_V) == 0)
    800011b4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011b6:	0117f693          	andi	a3,a5,17
    800011ba:	4745                	li	a4,17
    return 0;
    800011bc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011be:	00e68663          	beq	a3,a4,800011ca <walkaddr+0x38>
}
    800011c2:	60a2                	ld	ra,8(sp)
    800011c4:	6402                	ld	s0,0(sp)
    800011c6:	0141                	addi	sp,sp,16
    800011c8:	8082                	ret
  pa = PTE2PA(*pte);
    800011ca:	00a7d513          	srli	a0,a5,0xa
    800011ce:	053a                	slli	a0,a0,0xe
  return pa;
    800011d0:	bfcd                	j	800011c2 <walkaddr+0x30>
    return 0;
    800011d2:	4501                	li	a0,0
    800011d4:	b7fd                	j	800011c2 <walkaddr+0x30>

00000000800011d6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011d6:	715d                	addi	sp,sp,-80
    800011d8:	e486                	sd	ra,72(sp)
    800011da:	e0a2                	sd	s0,64(sp)
    800011dc:	fc26                	sd	s1,56(sp)
    800011de:	f84a                	sd	s2,48(sp)
    800011e0:	f44e                	sd	s3,40(sp)
    800011e2:	f052                	sd	s4,32(sp)
    800011e4:	ec56                	sd	s5,24(sp)
    800011e6:	e85a                	sd	s6,16(sp)
    800011e8:	e45e                	sd	s7,8(sp)
    800011ea:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;


  if(size == 0)
    800011ec:	c205                	beqz	a2,8000120c <mappages+0x36>
    800011ee:	8aaa                	mv	s5,a0
    800011f0:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011f2:	77f1                	lui	a5,0xffffc
    800011f4:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011f8:	15fd                	addi	a1,a1,-1
    800011fa:	00c589b3          	add	s3,a1,a2
    800011fe:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001202:	8952                	mv	s2,s4
    80001204:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001208:	6b91                	lui	s7,0x4
    8000120a:	a015                	j	8000122e <mappages+0x58>
    panic("mappages: size");
    8000120c:	0000b517          	auipc	a0,0xb
    80001210:	02450513          	addi	a0,a0,36 # 8000c230 <digits+0x1f0>
    80001214:	fffff097          	auipc	ra,0xfffff
    80001218:	32a080e7          	jalr	810(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000121c:	0000b517          	auipc	a0,0xb
    80001220:	02450513          	addi	a0,a0,36 # 8000c240 <digits+0x200>
    80001224:	fffff097          	auipc	ra,0xfffff
    80001228:	31a080e7          	jalr	794(ra) # 8000053e <panic>
    a += PGSIZE;
    8000122c:	995e                	add	s2,s2,s7
  for(;;){
    8000122e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1, 0)) == 0)
    80001232:	4681                	li	a3,0
    80001234:	4605                	li	a2,1
    80001236:	85ca                	mv	a1,s2
    80001238:	8556                	mv	a0,s5
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	dde080e7          	jalr	-546(ra) # 80001018 <walk>
    80001242:	cd19                	beqz	a0,80001260 <mappages+0x8a>
    if(*pte & PTE_V)
    80001244:	611c                	ld	a5,0(a0)
    80001246:	8b85                	andi	a5,a5,1
    80001248:	fbf1                	bnez	a5,8000121c <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000124a:	80b9                	srli	s1,s1,0xe
    8000124c:	04aa                	slli	s1,s1,0xa
    8000124e:	0164e4b3          	or	s1,s1,s6
    80001252:	0014e493          	ori	s1,s1,1
    80001256:	e104                	sd	s1,0(a0)
    if(a == last)
    80001258:	fd391ae3          	bne	s2,s3,8000122c <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000125c:	4501                	li	a0,0
    8000125e:	a011                	j	80001262 <mappages+0x8c>
      return -1;
    80001260:	557d                	li	a0,-1
}
    80001262:	60a6                	ld	ra,72(sp)
    80001264:	6406                	ld	s0,64(sp)
    80001266:	74e2                	ld	s1,56(sp)
    80001268:	7942                	ld	s2,48(sp)
    8000126a:	79a2                	ld	s3,40(sp)
    8000126c:	7a02                	ld	s4,32(sp)
    8000126e:	6ae2                	ld	s5,24(sp)
    80001270:	6b42                	ld	s6,16(sp)
    80001272:	6ba2                	ld	s7,8(sp)
    80001274:	6161                	addi	sp,sp,80
    80001276:	8082                	ret

0000000080001278 <kvmmap>:
{
    80001278:	1141                	addi	sp,sp,-16
    8000127a:	e406                	sd	ra,8(sp)
    8000127c:	e022                	sd	s0,0(sp)
    8000127e:	0800                	addi	s0,sp,16
    80001280:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001282:	86b2                	mv	a3,a2
    80001284:	863e                	mv	a2,a5
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f50080e7          	jalr	-176(ra) # 800011d6 <mappages>
    8000128e:	e509                	bnez	a0,80001298 <kvmmap+0x20>
}
    80001290:	60a2                	ld	ra,8(sp)
    80001292:	6402                	ld	s0,0(sp)
    80001294:	0141                	addi	sp,sp,16
    80001296:	8082                	ret
    panic("kvmmap");
    80001298:	0000b517          	auipc	a0,0xb
    8000129c:	fb850513          	addi	a0,a0,-72 # 8000c250 <digits+0x210>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>

00000000800012a8 <kvmmake>:
{
    800012a8:	7179                	addi	sp,sp,-48
    800012aa:	f406                	sd	ra,40(sp)
    800012ac:	f022                	sd	s0,32(sp)
    800012ae:	ec26                	sd	s1,24(sp)
    800012b0:	e84a                	sd	s2,16(sp)
    800012b2:	e44e                	sd	s3,8(sp)
    800012b4:	1800                	addi	s0,sp,48
  kpgtbl = (pagetable_t) kalloc();
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	83e080e7          	jalr	-1986(ra) # 80000af4 <kalloc>
    800012be:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012c0:	6611                	lui	a2,0x4
    800012c2:	4581                	li	a1,0
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	a1c080e7          	jalr	-1508(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012cc:	4719                	li	a4,6
    800012ce:	6691                	lui	a3,0x4
    800012d0:	10000637          	lui	a2,0x10000
    800012d4:	100005b7          	lui	a1,0x10000
    800012d8:	8526                	mv	a0,s1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f9e080e7          	jalr	-98(ra) # 80001278 <kvmmap>
  printf("mapping uart in %x\n", UART0);
    800012e2:	100005b7          	lui	a1,0x10000
    800012e6:	0000b517          	auipc	a0,0xb
    800012ea:	f7250513          	addi	a0,a0,-142 # 8000c258 <digits+0x218>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	29a080e7          	jalr	666(ra) # 80000588 <printf>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f6:	4719                	li	a4,6
    800012f8:	004006b7          	lui	a3,0x400
    800012fc:	0c000637          	lui	a2,0xc000
    80001300:	0c0005b7          	lui	a1,0xc000
    80001304:	8526                	mv	a0,s1
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	f72080e7          	jalr	-142(ra) # 80001278 <kvmmap>
  printf("mapping PLIC in %x\n", PLIC);
    8000130e:	0c0005b7          	lui	a1,0xc000
    80001312:	0000b517          	auipc	a0,0xb
    80001316:	f5e50513          	addi	a0,a0,-162 # 8000c270 <digits+0x230>
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	26e080e7          	jalr	622(ra) # 80000588 <printf>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001322:	0000b917          	auipc	s2,0xb
    80001326:	cde90913          	addi	s2,s2,-802 # 8000c000 <etext>
    8000132a:	4729                	li	a4,10
    8000132c:	8000b697          	auipc	a3,0x8000b
    80001330:	cd468693          	addi	a3,a3,-812 # c000 <_entry-0x7fff4000>
    80001334:	4985                	li	s3,1
    80001336:	01f99613          	slli	a2,s3,0x1f
    8000133a:	85b2                	mv	a1,a2
    8000133c:	8526                	mv	a0,s1
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	f3a080e7          	jalr	-198(ra) # 80001278 <kvmmap>
  printf("mapping kernel text in %x\n", KERNBASE);
    80001346:	01f99593          	slli	a1,s3,0x1f
    8000134a:	0000b517          	auipc	a0,0xb
    8000134e:	f3e50513          	addi	a0,a0,-194 # 8000c288 <digits+0x248>
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	236080e7          	jalr	566(ra) # 80000588 <printf>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000135a:	4719                	li	a4,6
    8000135c:	46c5                	li	a3,17
    8000135e:	06ee                	slli	a3,a3,0x1b
    80001360:	412686b3          	sub	a3,a3,s2
    80001364:	864a                	mv	a2,s2
    80001366:	85ca                	mv	a1,s2
    80001368:	8526                	mv	a0,s1
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	f0e080e7          	jalr	-242(ra) # 80001278 <kvmmap>
  printf("mapping trampoline for trap from %x to %x.\n",TRAMPOLINE, trampoline);
    80001372:	00007617          	auipc	a2,0x7
    80001376:	c8e60613          	addi	a2,a2,-882 # 80008000 <_trampoline>
    8000137a:	00800937          	lui	s2,0x800
    8000137e:	197d                	addi	s2,s2,-1
    80001380:	00e91593          	slli	a1,s2,0xe
    80001384:	0000b517          	auipc	a0,0xb
    80001388:	f2450513          	addi	a0,a0,-220 # 8000c2a8 <digits+0x268>
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	1fc080e7          	jalr	508(ra) # 80000588 <printf>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001394:	4729                	li	a4,10
    80001396:	6691                	lui	a3,0x4
    80001398:	00007617          	auipc	a2,0x7
    8000139c:	c6860613          	addi	a2,a2,-920 # 80008000 <_trampoline>
    800013a0:	00e91593          	slli	a1,s2,0xe
    800013a4:	8526                	mv	a0,s1
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	ed2080e7          	jalr	-302(ra) # 80001278 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013ae:	8526                	mv	a0,s1
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	62e080e7          	jalr	1582(ra) # 800019de <proc_mapstacks>
  printf("kernel pagetable created with VA: %x.\n",kpgtbl);
    800013b8:	85a6                	mv	a1,s1
    800013ba:	0000b517          	auipc	a0,0xb
    800013be:	f1e50513          	addi	a0,a0,-226 # 8000c2d8 <digits+0x298>
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	1c6080e7          	jalr	454(ra) # 80000588 <printf>
}
    800013ca:	8526                	mv	a0,s1
    800013cc:	70a2                	ld	ra,40(sp)
    800013ce:	7402                	ld	s0,32(sp)
    800013d0:	64e2                	ld	s1,24(sp)
    800013d2:	6942                	ld	s2,16(sp)
    800013d4:	69a2                	ld	s3,8(sp)
    800013d6:	6145                	addi	sp,sp,48
    800013d8:	8082                	ret

00000000800013da <kvminit>:
{
    800013da:	1141                	addi	sp,sp,-16
    800013dc:	e406                	sd	ra,8(sp)
    800013de:	e022                	sd	s0,0(sp)
    800013e0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013e2:	00000097          	auipc	ra,0x0
    800013e6:	ec6080e7          	jalr	-314(ra) # 800012a8 <kvmmake>
    800013ea:	0000f797          	auipc	a5,0xf
    800013ee:	c2a7bb23          	sd	a0,-970(a5) # 80010020 <kernel_pagetable>
}
    800013f2:	60a2                	ld	ra,8(sp)
    800013f4:	6402                	ld	s0,0(sp)
    800013f6:	0141                	addi	sp,sp,16
    800013f8:	8082                	ret

00000000800013fa <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013fa:	715d                	addi	sp,sp,-80
    800013fc:	e486                	sd	ra,72(sp)
    800013fe:	e0a2                	sd	s0,64(sp)
    80001400:	fc26                	sd	s1,56(sp)
    80001402:	f84a                	sd	s2,48(sp)
    80001404:	f44e                	sd	s3,40(sp)
    80001406:	f052                	sd	s4,32(sp)
    80001408:	ec56                	sd	s5,24(sp)
    8000140a:	e85a                	sd	s6,16(sp)
    8000140c:	e45e                	sd	s7,8(sp)
    8000140e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001410:	03259793          	slli	a5,a1,0x32
    80001414:	e795                	bnez	a5,80001440 <uvmunmap+0x46>
    80001416:	8a2a                	mv	s4,a0
    80001418:	892e                	mv	s2,a1
    8000141a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000141c:	063a                	slli	a2,a2,0xe
    8000141e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001422:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001424:	6b11                	lui	s6,0x4
    80001426:	0735e863          	bltu	a1,s3,80001496 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000142a:	60a6                	ld	ra,72(sp)
    8000142c:	6406                	ld	s0,64(sp)
    8000142e:	74e2                	ld	s1,56(sp)
    80001430:	7942                	ld	s2,48(sp)
    80001432:	79a2                	ld	s3,40(sp)
    80001434:	7a02                	ld	s4,32(sp)
    80001436:	6ae2                	ld	s5,24(sp)
    80001438:	6b42                	ld	s6,16(sp)
    8000143a:	6ba2                	ld	s7,8(sp)
    8000143c:	6161                	addi	sp,sp,80
    8000143e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001440:	0000b517          	auipc	a0,0xb
    80001444:	ec050513          	addi	a0,a0,-320 # 8000c300 <digits+0x2c0>
    80001448:	fffff097          	auipc	ra,0xfffff
    8000144c:	0f6080e7          	jalr	246(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001450:	0000b517          	auipc	a0,0xb
    80001454:	ec850513          	addi	a0,a0,-312 # 8000c318 <digits+0x2d8>
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	0e6080e7          	jalr	230(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001460:	0000b517          	auipc	a0,0xb
    80001464:	ec850513          	addi	a0,a0,-312 # 8000c328 <digits+0x2e8>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	0d6080e7          	jalr	214(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001470:	0000b517          	auipc	a0,0xb
    80001474:	ed050513          	addi	a0,a0,-304 # 8000c340 <digits+0x300>
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	0c6080e7          	jalr	198(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001480:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001482:	053a                	slli	a0,a0,0xe
    80001484:	fffff097          	auipc	ra,0xfffff
    80001488:	574080e7          	jalr	1396(ra) # 800009f8 <kfree>
    *pte = 0;
    8000148c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001490:	995a                	add	s2,s2,s6
    80001492:	f9397ce3          	bgeu	s2,s3,8000142a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0, 0)) == 0)
    80001496:	4681                	li	a3,0
    80001498:	4601                	li	a2,0
    8000149a:	85ca                	mv	a1,s2
    8000149c:	8552                	mv	a0,s4
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	b7a080e7          	jalr	-1158(ra) # 80001018 <walk>
    800014a6:	84aa                	mv	s1,a0
    800014a8:	d545                	beqz	a0,80001450 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014aa:	6108                	ld	a0,0(a0)
    800014ac:	00157793          	andi	a5,a0,1
    800014b0:	dbc5                	beqz	a5,80001460 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014b2:	3ff57793          	andi	a5,a0,1023
    800014b6:	fb778de3          	beq	a5,s7,80001470 <uvmunmap+0x76>
    if(do_free){
    800014ba:	fc0a89e3          	beqz	s5,8000148c <uvmunmap+0x92>
    800014be:	b7c9                	j	80001480 <uvmunmap+0x86>

00000000800014c0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014c0:	1101                	addi	sp,sp,-32
    800014c2:	ec06                	sd	ra,24(sp)
    800014c4:	e822                	sd	s0,16(sp)
    800014c6:	e426                	sd	s1,8(sp)
    800014c8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	62a080e7          	jalr	1578(ra) # 80000af4 <kalloc>
    800014d2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014d4:	c519                	beqz	a0,800014e2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014d6:	6611                	lui	a2,0x4
    800014d8:	4581                	li	a1,0
    800014da:	00000097          	auipc	ra,0x0
    800014de:	806080e7          	jalr	-2042(ra) # 80000ce0 <memset>
  return pagetable;
}
    800014e2:	8526                	mv	a0,s1
    800014e4:	60e2                	ld	ra,24(sp)
    800014e6:	6442                	ld	s0,16(sp)
    800014e8:	64a2                	ld	s1,8(sp)
    800014ea:	6105                	addi	sp,sp,32
    800014ec:	8082                	ret

00000000800014ee <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014ee:	7179                	addi	sp,sp,-48
    800014f0:	f406                	sd	ra,40(sp)
    800014f2:	f022                	sd	s0,32(sp)
    800014f4:	ec26                	sd	s1,24(sp)
    800014f6:	e84a                	sd	s2,16(sp)
    800014f8:	e44e                	sd	s3,8(sp)
    800014fa:	e052                	sd	s4,0(sp)
    800014fc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014fe:	6791                	lui	a5,0x4
    80001500:	06f67363          	bgeu	a2,a5,80001566 <uvminit+0x78>
    80001504:	89aa                	mv	s3,a0
    80001506:	8a2e                	mv	s4,a1
    80001508:	8932                	mv	s2,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	5ea080e7          	jalr	1514(ra) # 80000af4 <kalloc>
    80001512:	84aa                	mv	s1,a0
  memset(mem, 0, PGSIZE);
    80001514:	6611                	lui	a2,0x4
    80001516:	4581                	li	a1,0
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	7c8080e7          	jalr	1992(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001520:	4779                	li	a4,30
    80001522:	86a6                	mv	a3,s1
    80001524:	6611                	lui	a2,0x4
    80001526:	4581                	li	a1,0
    80001528:	854e                	mv	a0,s3
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	cac080e7          	jalr	-852(ra) # 800011d6 <mappages>
  memmove(mem, src, sz);
    80001532:	864a                	mv	a2,s2
    80001534:	85d2                	mv	a1,s4
    80001536:	8526                	mv	a0,s1
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	808080e7          	jalr	-2040(ra) # 80000d40 <memmove>

  printf("use a page %d in loc %x in pagetable %x to store codes.\n", PGSIZE, mem, pagetable);
    80001540:	86ce                	mv	a3,s3
    80001542:	8626                	mv	a2,s1
    80001544:	6591                	lui	a1,0x4
    80001546:	0000b517          	auipc	a0,0xb
    8000154a:	e3250513          	addi	a0,a0,-462 # 8000c378 <digits+0x338>
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	03a080e7          	jalr	58(ra) # 80000588 <printf>
}
    80001556:	70a2                	ld	ra,40(sp)
    80001558:	7402                	ld	s0,32(sp)
    8000155a:	64e2                	ld	s1,24(sp)
    8000155c:	6942                	ld	s2,16(sp)
    8000155e:	69a2                	ld	s3,8(sp)
    80001560:	6a02                	ld	s4,0(sp)
    80001562:	6145                	addi	sp,sp,48
    80001564:	8082                	ret
    panic("inituvm: more than a page");
    80001566:	0000b517          	auipc	a0,0xb
    8000156a:	df250513          	addi	a0,a0,-526 # 8000c358 <digits+0x318>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fd0080e7          	jalr	-48(ra) # 8000053e <panic>

0000000080001576 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001576:	1101                	addi	sp,sp,-32
    80001578:	ec06                	sd	ra,24(sp)
    8000157a:	e822                	sd	s0,16(sp)
    8000157c:	e426                	sd	s1,8(sp)
    8000157e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001580:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001582:	00b67d63          	bgeu	a2,a1,8000159c <uvmdealloc+0x26>
    80001586:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001588:	6791                	lui	a5,0x4
    8000158a:	17fd                	addi	a5,a5,-1
    8000158c:	00f60733          	add	a4,a2,a5
    80001590:	7671                	lui	a2,0xffffc
    80001592:	8f71                	and	a4,a4,a2
    80001594:	97ae                	add	a5,a5,a1
    80001596:	8ff1                	and	a5,a5,a2
    80001598:	00f76863          	bltu	a4,a5,800015a8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000159c:	8526                	mv	a0,s1
    8000159e:	60e2                	ld	ra,24(sp)
    800015a0:	6442                	ld	s0,16(sp)
    800015a2:	64a2                	ld	s1,8(sp)
    800015a4:	6105                	addi	sp,sp,32
    800015a6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a8:	8f99                	sub	a5,a5,a4
    800015aa:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015ac:	4685                	li	a3,1
    800015ae:	0007861b          	sext.w	a2,a5
    800015b2:	85ba                	mv	a1,a4
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	e46080e7          	jalr	-442(ra) # 800013fa <uvmunmap>
    800015bc:	b7c5                	j	8000159c <uvmdealloc+0x26>

00000000800015be <uvmalloc>:
  if(newsz < oldsz)
    800015be:	0ab66163          	bltu	a2,a1,80001660 <uvmalloc+0xa2>
{
    800015c2:	7139                	addi	sp,sp,-64
    800015c4:	fc06                	sd	ra,56(sp)
    800015c6:	f822                	sd	s0,48(sp)
    800015c8:	f426                	sd	s1,40(sp)
    800015ca:	f04a                	sd	s2,32(sp)
    800015cc:	ec4e                	sd	s3,24(sp)
    800015ce:	e852                	sd	s4,16(sp)
    800015d0:	e456                	sd	s5,8(sp)
    800015d2:	0080                	addi	s0,sp,64
    800015d4:	8aaa                	mv	s5,a0
    800015d6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d8:	6991                	lui	s3,0x4
    800015da:	19fd                	addi	s3,s3,-1
    800015dc:	95ce                	add	a1,a1,s3
    800015de:	79f1                	lui	s3,0xffffc
    800015e0:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015e4:	08c9f063          	bgeu	s3,a2,80001664 <uvmalloc+0xa6>
    800015e8:	894e                	mv	s2,s3
    mem = kalloc();
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	50a080e7          	jalr	1290(ra) # 80000af4 <kalloc>
    800015f2:	84aa                	mv	s1,a0
    if(mem == 0){
    800015f4:	c51d                	beqz	a0,80001622 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015f6:	6611                	lui	a2,0x4
    800015f8:	4581                	li	a1,0
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	6e6080e7          	jalr	1766(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001602:	4779                	li	a4,30
    80001604:	86a6                	mv	a3,s1
    80001606:	6611                	lui	a2,0x4
    80001608:	85ca                	mv	a1,s2
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	bca080e7          	jalr	-1078(ra) # 800011d6 <mappages>
    80001614:	e905                	bnez	a0,80001644 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001616:	6791                	lui	a5,0x4
    80001618:	993e                	add	s2,s2,a5
    8000161a:	fd4968e3          	bltu	s2,s4,800015ea <uvmalloc+0x2c>
  return newsz;
    8000161e:	8552                	mv	a0,s4
    80001620:	a809                	j	80001632 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001622:	864e                	mv	a2,s3
    80001624:	85ca                	mv	a1,s2
    80001626:	8556                	mv	a0,s5
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	f4e080e7          	jalr	-178(ra) # 80001576 <uvmdealloc>
      return 0;
    80001630:	4501                	li	a0,0
}
    80001632:	70e2                	ld	ra,56(sp)
    80001634:	7442                	ld	s0,48(sp)
    80001636:	74a2                	ld	s1,40(sp)
    80001638:	7902                	ld	s2,32(sp)
    8000163a:	69e2                	ld	s3,24(sp)
    8000163c:	6a42                	ld	s4,16(sp)
    8000163e:	6aa2                	ld	s5,8(sp)
    80001640:	6121                	addi	sp,sp,64
    80001642:	8082                	ret
      kfree(mem);
    80001644:	8526                	mv	a0,s1
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	3b2080e7          	jalr	946(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000164e:	864e                	mv	a2,s3
    80001650:	85ca                	mv	a1,s2
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	f22080e7          	jalr	-222(ra) # 80001576 <uvmdealloc>
      return 0;
    8000165c:	4501                	li	a0,0
    8000165e:	bfd1                	j	80001632 <uvmalloc+0x74>
    return oldsz;
    80001660:	852e                	mv	a0,a1
}
    80001662:	8082                	ret
  return newsz;
    80001664:	8532                	mv	a0,a2
    80001666:	b7f1                	j	80001632 <uvmalloc+0x74>

0000000080001668 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001668:	7179                	addi	sp,sp,-48
    8000166a:	f406                	sd	ra,40(sp)
    8000166c:	f022                	sd	s0,32(sp)
    8000166e:	ec26                	sd	s1,24(sp)
    80001670:	e84a                	sd	s2,16(sp)
    80001672:	e44e                	sd	s3,8(sp)
    80001674:	e052                	sd	s4,0(sp)
    80001676:	1800                	addi	s0,sp,48
    80001678:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000167a:	84aa                	mv	s1,a0
    8000167c:	6905                	lui	s2,0x1
    8000167e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001680:	4985                	li	s3,1
    80001682:	a821                	j	8000169a <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001684:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001686:	053a                	slli	a0,a0,0xe
    80001688:	00000097          	auipc	ra,0x0
    8000168c:	fe0080e7          	jalr	-32(ra) # 80001668 <freewalk>
      pagetable[i] = 0;
    80001690:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001694:	04a1                	addi	s1,s1,8
    80001696:	03248163          	beq	s1,s2,800016b8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000169a:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000169c:	00f57793          	andi	a5,a0,15
    800016a0:	ff3782e3          	beq	a5,s3,80001684 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016a4:	8905                	andi	a0,a0,1
    800016a6:	d57d                	beqz	a0,80001694 <freewalk+0x2c>
      panic("freewalk: leaf");
    800016a8:	0000b517          	auipc	a0,0xb
    800016ac:	d1050513          	addi	a0,a0,-752 # 8000c3b8 <digits+0x378>
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	e8e080e7          	jalr	-370(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800016b8:	8552                	mv	a0,s4
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	33e080e7          	jalr	830(ra) # 800009f8 <kfree>
}
    800016c2:	70a2                	ld	ra,40(sp)
    800016c4:	7402                	ld	s0,32(sp)
    800016c6:	64e2                	ld	s1,24(sp)
    800016c8:	6942                	ld	s2,16(sp)
    800016ca:	69a2                	ld	s3,8(sp)
    800016cc:	6a02                	ld	s4,0(sp)
    800016ce:	6145                	addi	sp,sp,48
    800016d0:	8082                	ret

00000000800016d2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016d2:	1101                	addi	sp,sp,-32
    800016d4:	ec06                	sd	ra,24(sp)
    800016d6:	e822                	sd	s0,16(sp)
    800016d8:	e426                	sd	s1,8(sp)
    800016da:	1000                	addi	s0,sp,32
    800016dc:	84aa                	mv	s1,a0
  if(sz > 0)
    800016de:	e999                	bnez	a1,800016f4 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016e0:	8526                	mv	a0,s1
    800016e2:	00000097          	auipc	ra,0x0
    800016e6:	f86080e7          	jalr	-122(ra) # 80001668 <freewalk>
}
    800016ea:	60e2                	ld	ra,24(sp)
    800016ec:	6442                	ld	s0,16(sp)
    800016ee:	64a2                	ld	s1,8(sp)
    800016f0:	6105                	addi	sp,sp,32
    800016f2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016f4:	6611                	lui	a2,0x4
    800016f6:	167d                	addi	a2,a2,-1
    800016f8:	962e                	add	a2,a2,a1
    800016fa:	4685                	li	a3,1
    800016fc:	8239                	srli	a2,a2,0xe
    800016fe:	4581                	li	a1,0
    80001700:	00000097          	auipc	ra,0x0
    80001704:	cfa080e7          	jalr	-774(ra) # 800013fa <uvmunmap>
    80001708:	bfe1                	j	800016e0 <uvmfree+0xe>

000000008000170a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000170a:	ca61                	beqz	a2,800017da <uvmcopy+0xd0>
{
    8000170c:	715d                	addi	sp,sp,-80
    8000170e:	e486                	sd	ra,72(sp)
    80001710:	e0a2                	sd	s0,64(sp)
    80001712:	fc26                	sd	s1,56(sp)
    80001714:	f84a                	sd	s2,48(sp)
    80001716:	f44e                	sd	s3,40(sp)
    80001718:	f052                	sd	s4,32(sp)
    8000171a:	ec56                	sd	s5,24(sp)
    8000171c:	e85a                	sd	s6,16(sp)
    8000171e:	e45e                	sd	s7,8(sp)
    80001720:	0880                	addi	s0,sp,80
    80001722:	8b2a                	mv	s6,a0
    80001724:	8aae                	mv	s5,a1
    80001726:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001728:	4981                	li	s3,0
    if((pte = walk(old, i, 0, 0)) == 0)
    8000172a:	4681                	li	a3,0
    8000172c:	4601                	li	a2,0
    8000172e:	85ce                	mv	a1,s3
    80001730:	855a                	mv	a0,s6
    80001732:	00000097          	auipc	ra,0x0
    80001736:	8e6080e7          	jalr	-1818(ra) # 80001018 <walk>
    8000173a:	c531                	beqz	a0,80001786 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000173c:	6118                	ld	a4,0(a0)
    8000173e:	00177793          	andi	a5,a4,1
    80001742:	cbb1                	beqz	a5,80001796 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001744:	00a75593          	srli	a1,a4,0xa
    80001748:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    8000174c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	3a4080e7          	jalr	932(ra) # 80000af4 <kalloc>
    80001758:	892a                	mv	s2,a0
    8000175a:	c939                	beqz	a0,800017b0 <uvmcopy+0xa6>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000175c:	6611                	lui	a2,0x4
    8000175e:	85de                	mv	a1,s7
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	5e0080e7          	jalr	1504(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001768:	8726                	mv	a4,s1
    8000176a:	86ca                	mv	a3,s2
    8000176c:	6611                	lui	a2,0x4
    8000176e:	85ce                	mv	a1,s3
    80001770:	8556                	mv	a0,s5
    80001772:	00000097          	auipc	ra,0x0
    80001776:	a64080e7          	jalr	-1436(ra) # 800011d6 <mappages>
    8000177a:	e515                	bnez	a0,800017a6 <uvmcopy+0x9c>
  for(i = 0; i < sz; i += PGSIZE){
    8000177c:	6791                	lui	a5,0x4
    8000177e:	99be                	add	s3,s3,a5
    80001780:	fb49e5e3          	bltu	s3,s4,8000172a <uvmcopy+0x20>
    80001784:	a081                	j	800017c4 <uvmcopy+0xba>
      panic("uvmcopy: pte should exist");
    80001786:	0000b517          	auipc	a0,0xb
    8000178a:	c4250513          	addi	a0,a0,-958 # 8000c3c8 <digits+0x388>
    8000178e:	fffff097          	auipc	ra,0xfffff
    80001792:	db0080e7          	jalr	-592(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001796:	0000b517          	auipc	a0,0xb
    8000179a:	c5250513          	addi	a0,a0,-942 # 8000c3e8 <digits+0x3a8>
    8000179e:	fffff097          	auipc	ra,0xfffff
    800017a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
      kfree(mem);
    800017a6:	854a                	mv	a0,s2
    800017a8:	fffff097          	auipc	ra,0xfffff
    800017ac:	250080e7          	jalr	592(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017b0:	4685                	li	a3,1
    800017b2:	00e9d613          	srli	a2,s3,0xe
    800017b6:	4581                	li	a1,0
    800017b8:	8556                	mv	a0,s5
    800017ba:	00000097          	auipc	ra,0x0
    800017be:	c40080e7          	jalr	-960(ra) # 800013fa <uvmunmap>
  return -1;
    800017c2:	557d                	li	a0,-1
}
    800017c4:	60a6                	ld	ra,72(sp)
    800017c6:	6406                	ld	s0,64(sp)
    800017c8:	74e2                	ld	s1,56(sp)
    800017ca:	7942                	ld	s2,48(sp)
    800017cc:	79a2                	ld	s3,40(sp)
    800017ce:	7a02                	ld	s4,32(sp)
    800017d0:	6ae2                	ld	s5,24(sp)
    800017d2:	6b42                	ld	s6,16(sp)
    800017d4:	6ba2                	ld	s7,8(sp)
    800017d6:	6161                	addi	sp,sp,80
    800017d8:	8082                	ret
  return 0;
    800017da:	4501                	li	a0,0
}
    800017dc:	8082                	ret

00000000800017de <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017de:	1141                	addi	sp,sp,-16
    800017e0:	e406                	sd	ra,8(sp)
    800017e2:	e022                	sd	s0,0(sp)
    800017e4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0, 0);
    800017e6:	4681                	li	a3,0
    800017e8:	4601                	li	a2,0
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	82e080e7          	jalr	-2002(ra) # 80001018 <walk>
  if(pte == 0)
    800017f2:	c901                	beqz	a0,80001802 <uvmclear+0x24>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017f4:	611c                	ld	a5,0(a0)
    800017f6:	9bbd                	andi	a5,a5,-17
    800017f8:	e11c                	sd	a5,0(a0)
}
    800017fa:	60a2                	ld	ra,8(sp)
    800017fc:	6402                	ld	s0,0(sp)
    800017fe:	0141                	addi	sp,sp,16
    80001800:	8082                	ret
    panic("uvmclear");
    80001802:	0000b517          	auipc	a0,0xb
    80001806:	c0650513          	addi	a0,a0,-1018 # 8000c408 <digits+0x3c8>
    8000180a:	fffff097          	auipc	ra,0xfffff
    8000180e:	d34080e7          	jalr	-716(ra) # 8000053e <panic>

0000000080001812 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001812:	c6bd                	beqz	a3,80001880 <copyout+0x6e>
{
    80001814:	715d                	addi	sp,sp,-80
    80001816:	e486                	sd	ra,72(sp)
    80001818:	e0a2                	sd	s0,64(sp)
    8000181a:	fc26                	sd	s1,56(sp)
    8000181c:	f84a                	sd	s2,48(sp)
    8000181e:	f44e                	sd	s3,40(sp)
    80001820:	f052                	sd	s4,32(sp)
    80001822:	ec56                	sd	s5,24(sp)
    80001824:	e85a                	sd	s6,16(sp)
    80001826:	e45e                	sd	s7,8(sp)
    80001828:	e062                	sd	s8,0(sp)
    8000182a:	0880                	addi	s0,sp,80
    8000182c:	8b2a                	mv	s6,a0
    8000182e:	8c2e                	mv	s8,a1
    80001830:	8a32                	mv	s4,a2
    80001832:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001834:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001836:	6a91                	lui	s5,0x4
    80001838:	a015                	j	8000185c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000183a:	9562                	add	a0,a0,s8
    8000183c:	0004861b          	sext.w	a2,s1
    80001840:	85d2                	mv	a1,s4
    80001842:	41250533          	sub	a0,a0,s2
    80001846:	fffff097          	auipc	ra,0xfffff
    8000184a:	4fa080e7          	jalr	1274(ra) # 80000d40 <memmove>

    len -= n;
    8000184e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001852:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001854:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001858:	02098263          	beqz	s3,8000187c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000185c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001860:	85ca                	mv	a1,s2
    80001862:	855a                	mv	a0,s6
    80001864:	00000097          	auipc	ra,0x0
    80001868:	92e080e7          	jalr	-1746(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    8000186c:	cd01                	beqz	a0,80001884 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000186e:	418904b3          	sub	s1,s2,s8
    80001872:	94d6                	add	s1,s1,s5
    if(n > len)
    80001874:	fc99f3e3          	bgeu	s3,s1,8000183a <copyout+0x28>
    80001878:	84ce                	mv	s1,s3
    8000187a:	b7c1                	j	8000183a <copyout+0x28>
  }
  return 0;
    8000187c:	4501                	li	a0,0
    8000187e:	a021                	j	80001886 <copyout+0x74>
    80001880:	4501                	li	a0,0
}
    80001882:	8082                	ret
      return -1;
    80001884:	557d                	li	a0,-1
}
    80001886:	60a6                	ld	ra,72(sp)
    80001888:	6406                	ld	s0,64(sp)
    8000188a:	74e2                	ld	s1,56(sp)
    8000188c:	7942                	ld	s2,48(sp)
    8000188e:	79a2                	ld	s3,40(sp)
    80001890:	7a02                	ld	s4,32(sp)
    80001892:	6ae2                	ld	s5,24(sp)
    80001894:	6b42                	ld	s6,16(sp)
    80001896:	6ba2                	ld	s7,8(sp)
    80001898:	6c02                	ld	s8,0(sp)
    8000189a:	6161                	addi	sp,sp,80
    8000189c:	8082                	ret

000000008000189e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000189e:	c6bd                	beqz	a3,8000190c <copyin+0x6e>
{
    800018a0:	715d                	addi	sp,sp,-80
    800018a2:	e486                	sd	ra,72(sp)
    800018a4:	e0a2                	sd	s0,64(sp)
    800018a6:	fc26                	sd	s1,56(sp)
    800018a8:	f84a                	sd	s2,48(sp)
    800018aa:	f44e                	sd	s3,40(sp)
    800018ac:	f052                	sd	s4,32(sp)
    800018ae:	ec56                	sd	s5,24(sp)
    800018b0:	e85a                	sd	s6,16(sp)
    800018b2:	e45e                	sd	s7,8(sp)
    800018b4:	e062                	sd	s8,0(sp)
    800018b6:	0880                	addi	s0,sp,80
    800018b8:	8b2a                	mv	s6,a0
    800018ba:	8a2e                	mv	s4,a1
    800018bc:	8c32                	mv	s8,a2
    800018be:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018c0:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018c2:	6a91                	lui	s5,0x4
    800018c4:	a015                	j	800018e8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018c6:	9562                	add	a0,a0,s8
    800018c8:	0004861b          	sext.w	a2,s1
    800018cc:	412505b3          	sub	a1,a0,s2
    800018d0:	8552                	mv	a0,s4
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	46e080e7          	jalr	1134(ra) # 80000d40 <memmove>

    len -= n;
    800018da:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018de:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018e0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018e4:	02098263          	beqz	s3,80001908 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018e8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018ec:	85ca                	mv	a1,s2
    800018ee:	855a                	mv	a0,s6
    800018f0:	00000097          	auipc	ra,0x0
    800018f4:	8a2080e7          	jalr	-1886(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    800018f8:	cd01                	beqz	a0,80001910 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018fa:	418904b3          	sub	s1,s2,s8
    800018fe:	94d6                	add	s1,s1,s5
    if(n > len)
    80001900:	fc99f3e3          	bgeu	s3,s1,800018c6 <copyin+0x28>
    80001904:	84ce                	mv	s1,s3
    80001906:	b7c1                	j	800018c6 <copyin+0x28>
  }
  return 0;
    80001908:	4501                	li	a0,0
    8000190a:	a021                	j	80001912 <copyin+0x74>
    8000190c:	4501                	li	a0,0
}
    8000190e:	8082                	ret
      return -1;
    80001910:	557d                	li	a0,-1
}
    80001912:	60a6                	ld	ra,72(sp)
    80001914:	6406                	ld	s0,64(sp)
    80001916:	74e2                	ld	s1,56(sp)
    80001918:	7942                	ld	s2,48(sp)
    8000191a:	79a2                	ld	s3,40(sp)
    8000191c:	7a02                	ld	s4,32(sp)
    8000191e:	6ae2                	ld	s5,24(sp)
    80001920:	6b42                	ld	s6,16(sp)
    80001922:	6ba2                	ld	s7,8(sp)
    80001924:	6c02                	ld	s8,0(sp)
    80001926:	6161                	addi	sp,sp,80
    80001928:	8082                	ret

000000008000192a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000192a:	c6c5                	beqz	a3,800019d2 <copyinstr+0xa8>
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
    80001942:	8a2a                	mv	s4,a0
    80001944:	8b2e                	mv	s6,a1
    80001946:	8bb2                	mv	s7,a2
    80001948:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000194a:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000194c:	6991                	lui	s3,0x4
    8000194e:	a035                	j	8000197a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001950:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    80001954:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001956:	0017b793          	seqz	a5,a5
    8000195a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000195e:	60a6                	ld	ra,72(sp)
    80001960:	6406                	ld	s0,64(sp)
    80001962:	74e2                	ld	s1,56(sp)
    80001964:	7942                	ld	s2,48(sp)
    80001966:	79a2                	ld	s3,40(sp)
    80001968:	7a02                	ld	s4,32(sp)
    8000196a:	6ae2                	ld	s5,24(sp)
    8000196c:	6b42                	ld	s6,16(sp)
    8000196e:	6ba2                	ld	s7,8(sp)
    80001970:	6161                	addi	sp,sp,80
    80001972:	8082                	ret
    srcva = va0 + PGSIZE;
    80001974:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001978:	c8a9                	beqz	s1,800019ca <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000197a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000197e:	85ca                	mv	a1,s2
    80001980:	8552                	mv	a0,s4
    80001982:	00000097          	auipc	ra,0x0
    80001986:	810080e7          	jalr	-2032(ra) # 80001192 <walkaddr>
    if(pa0 == 0)
    8000198a:	c131                	beqz	a0,800019ce <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000198c:	41790833          	sub	a6,s2,s7
    80001990:	984e                	add	a6,a6,s3
    if(n > max)
    80001992:	0104f363          	bgeu	s1,a6,80001998 <copyinstr+0x6e>
    80001996:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001998:	955e                	add	a0,a0,s7
    8000199a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000199e:	fc080be3          	beqz	a6,80001974 <copyinstr+0x4a>
    800019a2:	985a                	add	a6,a6,s6
    800019a4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019a6:	41650633          	sub	a2,a0,s6
    800019aa:	14fd                	addi	s1,s1,-1
    800019ac:	9b26                	add	s6,s6,s1
    800019ae:	00f60733          	add	a4,a2,a5
    800019b2:	00074703          	lbu	a4,0(a4)
    800019b6:	df49                	beqz	a4,80001950 <copyinstr+0x26>
        *dst = *p;
    800019b8:	00e78023          	sb	a4,0(a5)
      --max;
    800019bc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800019c0:	0785                	addi	a5,a5,1
    while(n > 0){
    800019c2:	ff0796e3          	bne	a5,a6,800019ae <copyinstr+0x84>
      dst++;
    800019c6:	8b42                	mv	s6,a6
    800019c8:	b775                	j	80001974 <copyinstr+0x4a>
    800019ca:	4781                	li	a5,0
    800019cc:	b769                	j	80001956 <copyinstr+0x2c>
      return -1;
    800019ce:	557d                	li	a0,-1
    800019d0:	b779                	j	8000195e <copyinstr+0x34>
  int got_null = 0;
    800019d2:	4781                	li	a5,0
  if(got_null){
    800019d4:	0017b793          	seqz	a5,a5
    800019d8:	40f00533          	neg	a0,a5
}
    800019dc:	8082                	ret

00000000800019de <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800019de:	7139                	addi	sp,sp,-64
    800019e0:	fc06                	sd	ra,56(sp)
    800019e2:	f822                	sd	s0,48(sp)
    800019e4:	f426                	sd	s1,40(sp)
    800019e6:	f04a                	sd	s2,32(sp)
    800019e8:	ec4e                	sd	s3,24(sp)
    800019ea:	e852                	sd	s4,16(sp)
    800019ec:	e456                	sd	s5,8(sp)
    800019ee:	e05a                	sd	s6,0(sp)
    800019f0:	0080                	addi	s0,sp,64
    800019f2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f4:	00017497          	auipc	s1,0x17
    800019f8:	cdc48493          	addi	s1,s1,-804 # 800186d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019fc:	8b26                	mv	s6,s1
    800019fe:	0000aa97          	auipc	s5,0xa
    80001a02:	602a8a93          	addi	s5,s5,1538 # 8000c000 <etext>
    80001a06:	00800937          	lui	s2,0x800
    80001a0a:	197d                	addi	s2,s2,-1
    80001a0c:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a0e:	0001ca17          	auipc	s4,0x1c
    80001a12:	6c2a0a13          	addi	s4,s4,1730 # 8001e0d0 <tickslock>
    char *pa = kalloc();
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	0de080e7          	jalr	222(ra) # 80000af4 <kalloc>
    80001a1e:	862a                	mv	a2,a0
    if(pa == 0)
    80001a20:	c131                	beqz	a0,80001a64 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001a22:	416485b3          	sub	a1,s1,s6
    80001a26:	858d                	srai	a1,a1,0x3
    80001a28:	000ab783          	ld	a5,0(s5)
    80001a2c:	02f585b3          	mul	a1,a1,a5
    80001a30:	2585                	addiw	a1,a1,1
    80001a32:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a36:	4719                	li	a4,6
    80001a38:	6691                	lui	a3,0x4
    80001a3a:	40b905b3          	sub	a1,s2,a1
    80001a3e:	854e                	mv	a0,s3
    80001a40:	00000097          	auipc	ra,0x0
    80001a44:	838080e7          	jalr	-1992(ra) # 80001278 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a48:	16848493          	addi	s1,s1,360
    80001a4c:	fd4495e3          	bne	s1,s4,80001a16 <proc_mapstacks+0x38>
  }
}
    80001a50:	70e2                	ld	ra,56(sp)
    80001a52:	7442                	ld	s0,48(sp)
    80001a54:	74a2                	ld	s1,40(sp)
    80001a56:	7902                	ld	s2,32(sp)
    80001a58:	69e2                	ld	s3,24(sp)
    80001a5a:	6a42                	ld	s4,16(sp)
    80001a5c:	6aa2                	ld	s5,8(sp)
    80001a5e:	6b02                	ld	s6,0(sp)
    80001a60:	6121                	addi	sp,sp,64
    80001a62:	8082                	ret
      panic("kalloc");
    80001a64:	0000b517          	auipc	a0,0xb
    80001a68:	9b450513          	addi	a0,a0,-1612 # 8000c418 <digits+0x3d8>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	ad2080e7          	jalr	-1326(ra) # 8000053e <panic>

0000000080001a74 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a74:	7139                	addi	sp,sp,-64
    80001a76:	fc06                	sd	ra,56(sp)
    80001a78:	f822                	sd	s0,48(sp)
    80001a7a:	f426                	sd	s1,40(sp)
    80001a7c:	f04a                	sd	s2,32(sp)
    80001a7e:	ec4e                	sd	s3,24(sp)
    80001a80:	e852                	sd	s4,16(sp)
    80001a82:	e456                	sd	s5,8(sp)
    80001a84:	e05a                	sd	s6,0(sp)
    80001a86:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a88:	0000b597          	auipc	a1,0xb
    80001a8c:	99858593          	addi	a1,a1,-1640 # 8000c420 <digits+0x3e0>
    80001a90:	00017517          	auipc	a0,0x17
    80001a94:	81050513          	addi	a0,a0,-2032 # 800182a0 <pid_lock>
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	0bc080e7          	jalr	188(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001aa0:	0000b597          	auipc	a1,0xb
    80001aa4:	98858593          	addi	a1,a1,-1656 # 8000c428 <digits+0x3e8>
    80001aa8:	00017517          	auipc	a0,0x17
    80001aac:	81050513          	addi	a0,a0,-2032 # 800182b8 <wait_lock>
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	0a4080e7          	jalr	164(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab8:	00017497          	auipc	s1,0x17
    80001abc:	c1848493          	addi	s1,s1,-1000 # 800186d0 <proc>
      initlock(&p->lock, "proc");
    80001ac0:	0000bb17          	auipc	s6,0xb
    80001ac4:	978b0b13          	addi	s6,s6,-1672 # 8000c438 <digits+0x3f8>
      p->kstack = KSTACK((int) (p - proc));
    80001ac8:	8aa6                	mv	s5,s1
    80001aca:	0000aa17          	auipc	s4,0xa
    80001ace:	536a0a13          	addi	s4,s4,1334 # 8000c000 <etext>
    80001ad2:	00800937          	lui	s2,0x800
    80001ad6:	197d                	addi	s2,s2,-1
    80001ad8:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ada:	0001c997          	auipc	s3,0x1c
    80001ade:	5f698993          	addi	s3,s3,1526 # 8001e0d0 <tickslock>
      initlock(&p->lock, "proc");
    80001ae2:	85da                	mv	a1,s6
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	06e080e7          	jalr	110(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001aee:	415487b3          	sub	a5,s1,s5
    80001af2:	878d                	srai	a5,a5,0x3
    80001af4:	000a3703          	ld	a4,0(s4)
    80001af8:	02e787b3          	mul	a5,a5,a4
    80001afc:	2785                	addiw	a5,a5,1
    80001afe:	00f7979b          	slliw	a5,a5,0xf
    80001b02:	40f907b3          	sub	a5,s2,a5
    80001b06:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b08:	16848493          	addi	s1,s1,360
    80001b0c:	fd349be3          	bne	s1,s3,80001ae2 <procinit+0x6e>
  }
}
    80001b10:	70e2                	ld	ra,56(sp)
    80001b12:	7442                	ld	s0,48(sp)
    80001b14:	74a2                	ld	s1,40(sp)
    80001b16:	7902                	ld	s2,32(sp)
    80001b18:	69e2                	ld	s3,24(sp)
    80001b1a:	6a42                	ld	s4,16(sp)
    80001b1c:	6aa2                	ld	s5,8(sp)
    80001b1e:	6b02                	ld	s6,0(sp)
    80001b20:	6121                	addi	sp,sp,64
    80001b22:	8082                	ret

0000000080001b24 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001b24:	1141                	addi	sp,sp,-16
    80001b26:	e422                	sd	s0,8(sp)
    80001b28:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b2a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001b2c:	2501                	sext.w	a0,a0
    80001b2e:	6422                	ld	s0,8(sp)
    80001b30:	0141                	addi	sp,sp,16
    80001b32:	8082                	ret

0000000080001b34 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001b34:	1141                	addi	sp,sp,-16
    80001b36:	e422                	sd	s0,8(sp)
    80001b38:	0800                	addi	s0,sp,16
    80001b3a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b3c:	2781                	sext.w	a5,a5
    80001b3e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b40:	00016517          	auipc	a0,0x16
    80001b44:	79050513          	addi	a0,a0,1936 # 800182d0 <cpus>
    80001b48:	953e                	add	a0,a0,a5
    80001b4a:	6422                	ld	s0,8(sp)
    80001b4c:	0141                	addi	sp,sp,16
    80001b4e:	8082                	ret

0000000080001b50 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b50:	1101                	addi	sp,sp,-32
    80001b52:	ec06                	sd	ra,24(sp)
    80001b54:	e822                	sd	s0,16(sp)
    80001b56:	e426                	sd	s1,8(sp)
    80001b58:	1000                	addi	s0,sp,32
  push_off();
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	03e080e7          	jalr	62(ra) # 80000b98 <push_off>
    80001b62:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b64:	2781                	sext.w	a5,a5
    80001b66:	079e                	slli	a5,a5,0x7
    80001b68:	00016717          	auipc	a4,0x16
    80001b6c:	73870713          	addi	a4,a4,1848 # 800182a0 <pid_lock>
    80001b70:	97ba                	add	a5,a5,a4
    80001b72:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	0c4080e7          	jalr	196(ra) # 80000c38 <pop_off>
  return p;
}
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6105                	addi	sp,sp,32
    80001b86:	8082                	ret

0000000080001b88 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e406                	sd	ra,8(sp)
    80001b8c:	e022                	sd	s0,0(sp)
    80001b8e:	0800                	addi	s0,sp,16
  static int first = 1;
  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	fc0080e7          	jalr	-64(ra) # 80001b50 <myproc>
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	100080e7          	jalr	256(ra) # 80000c98 <release>

  if (first) {
    80001ba0:	0000b797          	auipc	a5,0xb
    80001ba4:	f207a783          	lw	a5,-224(a5) # 8000cac0 <first.1672>
    80001ba8:	eb89                	bnez	a5,80001bba <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV); //12010320;
  }

  usertrapret();
    80001baa:	00001097          	auipc	ra,0x1
    80001bae:	c5a080e7          	jalr	-934(ra) # 80002804 <usertrapret>
}
    80001bb2:	60a2                	ld	ra,8(sp)
    80001bb4:	6402                	ld	s0,0(sp)
    80001bb6:	0141                	addi	sp,sp,16
    80001bb8:	8082                	ret
    first = 0;
    80001bba:	0000b797          	auipc	a5,0xb
    80001bbe:	f007a323          	sw	zero,-250(a5) # 8000cac0 <first.1672>
    fsinit(ROOTDEV); //12010320;
    80001bc2:	4505                	li	a0,1
    80001bc4:	00002097          	auipc	ra,0x2
    80001bc8:	982080e7          	jalr	-1662(ra) # 80003546 <fsinit>
    80001bcc:	bff9                	j	80001baa <forkret+0x22>

0000000080001bce <allocpid>:
allocpid() {
    80001bce:	1101                	addi	sp,sp,-32
    80001bd0:	ec06                	sd	ra,24(sp)
    80001bd2:	e822                	sd	s0,16(sp)
    80001bd4:	e426                	sd	s1,8(sp)
    80001bd6:	e04a                	sd	s2,0(sp)
    80001bd8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bda:	00016917          	auipc	s2,0x16
    80001bde:	6c690913          	addi	s2,s2,1734 # 800182a0 <pid_lock>
    80001be2:	854a                	mv	a0,s2
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	000080e7          	jalr	ra # 80000be4 <acquire>
  pid = nextpid;
    80001bec:	0000b797          	auipc	a5,0xb
    80001bf0:	ed878793          	addi	a5,a5,-296 # 8000cac4 <nextpid>
    80001bf4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bf6:	0014871b          	addiw	a4,s1,1
    80001bfa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bfc:	854a                	mv	a0,s2
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
}
    80001c06:	8526                	mv	a0,s1
    80001c08:	60e2                	ld	ra,24(sp)
    80001c0a:	6442                	ld	s0,16(sp)
    80001c0c:	64a2                	ld	s1,8(sp)
    80001c0e:	6902                	ld	s2,0(sp)
    80001c10:	6105                	addi	sp,sp,32
    80001c12:	8082                	ret

0000000080001c14 <proc_pagetable>:
{
    80001c14:	1101                	addi	sp,sp,-32
    80001c16:	ec06                	sd	ra,24(sp)
    80001c18:	e822                	sd	s0,16(sp)
    80001c1a:	e426                	sd	s1,8(sp)
    80001c1c:	e04a                	sd	s2,0(sp)
    80001c1e:	1000                	addi	s0,sp,32
    80001c20:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c22:	00000097          	auipc	ra,0x0
    80001c26:	89e080e7          	jalr	-1890(ra) # 800014c0 <uvmcreate>
    80001c2a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c2c:	c121                	beqz	a0,80001c6c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c2e:	4729                	li	a4,10
    80001c30:	00006697          	auipc	a3,0x6
    80001c34:	3d068693          	addi	a3,a3,976 # 80008000 <_trampoline>
    80001c38:	6611                	lui	a2,0x4
    80001c3a:	008005b7          	lui	a1,0x800
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05ba                	slli	a1,a1,0xe
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	594080e7          	jalr	1428(ra) # 800011d6 <mappages>
    80001c4a:	02054863          	bltz	a0,80001c7a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c4e:	4719                	li	a4,6
    80001c50:	05893683          	ld	a3,88(s2)
    80001c54:	6611                	lui	a2,0x4
    80001c56:	004005b7          	lui	a1,0x400
    80001c5a:	15fd                	addi	a1,a1,-1
    80001c5c:	05be                	slli	a1,a1,0xf
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	576080e7          	jalr	1398(ra) # 800011d6 <mappages>
    80001c68:	02054163          	bltz	a0,80001c8a <proc_pagetable+0x76>
}
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	60e2                	ld	ra,24(sp)
    80001c70:	6442                	ld	s0,16(sp)
    80001c72:	64a2                	ld	s1,8(sp)
    80001c74:	6902                	ld	s2,0(sp)
    80001c76:	6105                	addi	sp,sp,32
    80001c78:	8082                	ret
    uvmfree(pagetable, 0);
    80001c7a:	4581                	li	a1,0
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	a54080e7          	jalr	-1452(ra) # 800016d2 <uvmfree>
    return 0;
    80001c86:	4481                	li	s1,0
    80001c88:	b7d5                	j	80001c6c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c8a:	4681                	li	a3,0
    80001c8c:	4605                	li	a2,1
    80001c8e:	008005b7          	lui	a1,0x800
    80001c92:	15fd                	addi	a1,a1,-1
    80001c94:	05ba                	slli	a1,a1,0xe
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	762080e7          	jalr	1890(ra) # 800013fa <uvmunmap>
    uvmfree(pagetable, 0);
    80001ca0:	4581                	li	a1,0
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	a2e080e7          	jalr	-1490(ra) # 800016d2 <uvmfree>
    return 0;
    80001cac:	4481                	li	s1,0
    80001cae:	bf7d                	j	80001c6c <proc_pagetable+0x58>

0000000080001cb0 <proc_freepagetable>:
{
    80001cb0:	1101                	addi	sp,sp,-32
    80001cb2:	ec06                	sd	ra,24(sp)
    80001cb4:	e822                	sd	s0,16(sp)
    80001cb6:	e426                	sd	s1,8(sp)
    80001cb8:	e04a                	sd	s2,0(sp)
    80001cba:	1000                	addi	s0,sp,32
    80001cbc:	84aa                	mv	s1,a0
    80001cbe:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc0:	4681                	li	a3,0
    80001cc2:	4605                	li	a2,1
    80001cc4:	008005b7          	lui	a1,0x800
    80001cc8:	15fd                	addi	a1,a1,-1
    80001cca:	05ba                	slli	a1,a1,0xe
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	72e080e7          	jalr	1838(ra) # 800013fa <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cd4:	4681                	li	a3,0
    80001cd6:	4605                	li	a2,1
    80001cd8:	004005b7          	lui	a1,0x400
    80001cdc:	15fd                	addi	a1,a1,-1
    80001cde:	05be                	slli	a1,a1,0xf
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	718080e7          	jalr	1816(ra) # 800013fa <uvmunmap>
  uvmfree(pagetable, sz);
    80001cea:	85ca                	mv	a1,s2
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	9e4080e7          	jalr	-1564(ra) # 800016d2 <uvmfree>
}
    80001cf6:	60e2                	ld	ra,24(sp)
    80001cf8:	6442                	ld	s0,16(sp)
    80001cfa:	64a2                	ld	s1,8(sp)
    80001cfc:	6902                	ld	s2,0(sp)
    80001cfe:	6105                	addi	sp,sp,32
    80001d00:	8082                	ret

0000000080001d02 <freeproc>:
{
    80001d02:	1101                	addi	sp,sp,-32
    80001d04:	ec06                	sd	ra,24(sp)
    80001d06:	e822                	sd	s0,16(sp)
    80001d08:	e426                	sd	s1,8(sp)
    80001d0a:	1000                	addi	s0,sp,32
    80001d0c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d0e:	6d28                	ld	a0,88(a0)
    80001d10:	c509                	beqz	a0,80001d1a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	ce6080e7          	jalr	-794(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001d1a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d1e:	68a8                	ld	a0,80(s1)
    80001d20:	c511                	beqz	a0,80001d2c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d22:	64ac                	ld	a1,72(s1)
    80001d24:	00000097          	auipc	ra,0x0
    80001d28:	f8c080e7          	jalr	-116(ra) # 80001cb0 <proc_freepagetable>
  p->pagetable = 0;
    80001d2c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d30:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d34:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001d38:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d3c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d40:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d44:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d48:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d4c:	0004ac23          	sw	zero,24(s1)
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret

0000000080001d5a <allocproc>:
{
    80001d5a:	1101                	addi	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	e04a                	sd	s2,0(sp)
    80001d64:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d66:	00017497          	auipc	s1,0x17
    80001d6a:	96a48493          	addi	s1,s1,-1686 # 800186d0 <proc>
    80001d6e:	0001c917          	auipc	s2,0x1c
    80001d72:	36290913          	addi	s2,s2,866 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	e6c080e7          	jalr	-404(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d80:	4c9c                	lw	a5,24(s1)
    80001d82:	cf81                	beqz	a5,80001d9a <allocproc+0x40>
      release(&p->lock);
    80001d84:	8526                	mv	a0,s1
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	f12080e7          	jalr	-238(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d8e:	16848493          	addi	s1,s1,360
    80001d92:	ff2492e3          	bne	s1,s2,80001d76 <allocproc+0x1c>
  return 0;
    80001d96:	4481                	li	s1,0
    80001d98:	a889                	j	80001dea <allocproc+0x90>
  p->pid = allocpid();
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	e34080e7          	jalr	-460(ra) # 80001bce <allocpid>
    80001da2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001da4:	4785                	li	a5,1
    80001da6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	d4c080e7          	jalr	-692(ra) # 80000af4 <kalloc>
    80001db0:	892a                	mv	s2,a0
    80001db2:	eca8                	sd	a0,88(s1)
    80001db4:	c131                	beqz	a0,80001df8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001db6:	8526                	mv	a0,s1
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	e5c080e7          	jalr	-420(ra) # 80001c14 <proc_pagetable>
    80001dc0:	892a                	mv	s2,a0
    80001dc2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dc4:	c531                	beqz	a0,80001e10 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001dc6:	07000613          	li	a2,112
    80001dca:	4581                	li	a1,0
    80001dcc:	06048513          	addi	a0,s1,96
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	f10080e7          	jalr	-240(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001dd8:	00000797          	auipc	a5,0x0
    80001ddc:	db078793          	addi	a5,a5,-592 # 80001b88 <forkret>
    80001de0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001de2:	60bc                	ld	a5,64(s1)
    80001de4:	6711                	lui	a4,0x4
    80001de6:	97ba                	add	a5,a5,a4
    80001de8:	f4bc                	sd	a5,104(s1)
}
    80001dea:	8526                	mv	a0,s1
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6902                	ld	s2,0(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret
    freeproc(p);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	f08080e7          	jalr	-248(ra) # 80001d02 <freeproc>
    release(&p->lock);
    80001e02:	8526                	mv	a0,s1
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	e94080e7          	jalr	-364(ra) # 80000c98 <release>
    return 0;
    80001e0c:	84ca                	mv	s1,s2
    80001e0e:	bff1                	j	80001dea <allocproc+0x90>
    freeproc(p);
    80001e10:	8526                	mv	a0,s1
    80001e12:	00000097          	auipc	ra,0x0
    80001e16:	ef0080e7          	jalr	-272(ra) # 80001d02 <freeproc>
    release(&p->lock);
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	e7c080e7          	jalr	-388(ra) # 80000c98 <release>
    return 0;
    80001e24:	84ca                	mv	s1,s2
    80001e26:	b7d1                	j	80001dea <allocproc+0x90>

0000000080001e28 <userinit>:
{
    80001e28:	1101                	addi	sp,sp,-32
    80001e2a:	ec06                	sd	ra,24(sp)
    80001e2c:	e822                	sd	s0,16(sp)
    80001e2e:	e426                	sd	s1,8(sp)
    80001e30:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	f28080e7          	jalr	-216(ra) # 80001d5a <allocproc>
    80001e3a:	84aa                	mv	s1,a0
  initproc = p;
    80001e3c:	0000e797          	auipc	a5,0xe
    80001e40:	1ea7b623          	sd	a0,492(a5) # 80010028 <initproc>
  printf("user proc with id %d create.\n",p->pid);
    80001e44:	590c                	lw	a1,48(a0)
    80001e46:	0000a517          	auipc	a0,0xa
    80001e4a:	5fa50513          	addi	a0,a0,1530 # 8000c440 <digits+0x400>
    80001e4e:	ffffe097          	auipc	ra,0xffffe
    80001e52:	73a080e7          	jalr	1850(ra) # 80000588 <printf>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e56:	03400613          	li	a2,52
    80001e5a:	0000b597          	auipc	a1,0xb
    80001e5e:	c7658593          	addi	a1,a1,-906 # 8000cad0 <initcode>
    80001e62:	68a8                	ld	a0,80(s1)
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	68a080e7          	jalr	1674(ra) # 800014ee <uvminit>
  p->sz = PGSIZE;
    80001e6c:	6791                	lui	a5,0x4
    80001e6e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e70:	6cb8                	ld	a4,88(s1)
    80001e72:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e76:	6cb8                	ld	a4,88(s1)
    80001e78:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e7a:	4641                	li	a2,16
    80001e7c:	0000a597          	auipc	a1,0xa
    80001e80:	5e458593          	addi	a1,a1,1508 # 8000c460 <digits+0x420>
    80001e84:	15848513          	addi	a0,s1,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	faa080e7          	jalr	-86(ra) # 80000e32 <safestrcpy>
  printf("path: %s\n",namei("/"));
    80001e90:	0000a517          	auipc	a0,0xa
    80001e94:	5e050513          	addi	a0,a0,1504 # 8000c470 <digits+0x430>
    80001e98:	00002097          	auipc	ra,0x2
    80001e9c:	0ee080e7          	jalr	238(ra) # 80003f86 <namei>
    80001ea0:	85aa                	mv	a1,a0
    80001ea2:	0000a517          	auipc	a0,0xa
    80001ea6:	5d650513          	addi	a0,a0,1494 # 8000c478 <digits+0x438>
    80001eaa:	ffffe097          	auipc	ra,0xffffe
    80001eae:	6de080e7          	jalr	1758(ra) # 80000588 <printf>
  p->cwd = namei("/");
    80001eb2:	0000a517          	auipc	a0,0xa
    80001eb6:	5be50513          	addi	a0,a0,1470 # 8000c470 <digits+0x430>
    80001eba:	00002097          	auipc	ra,0x2
    80001ebe:	0cc080e7          	jalr	204(ra) # 80003f86 <namei>
    80001ec2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec6:	478d                	li	a5,3
    80001ec8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dcc080e7          	jalr	-564(ra) # 80000c98 <release>
}
    80001ed4:	60e2                	ld	ra,24(sp)
    80001ed6:	6442                	ld	s0,16(sp)
    80001ed8:	64a2                	ld	s1,8(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret

0000000080001ede <growproc>:
{
    80001ede:	1101                	addi	sp,sp,-32
    80001ee0:	ec06                	sd	ra,24(sp)
    80001ee2:	e822                	sd	s0,16(sp)
    80001ee4:	e426                	sd	s1,8(sp)
    80001ee6:	e04a                	sd	s2,0(sp)
    80001ee8:	1000                	addi	s0,sp,32
    80001eea:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	c64080e7          	jalr	-924(ra) # 80001b50 <myproc>
    80001ef4:	892a                	mv	s2,a0
  sz = p->sz;
    80001ef6:	652c                	ld	a1,72(a0)
    80001ef8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001efc:	00904f63          	bgtz	s1,80001f1a <growproc+0x3c>
  } else if(n < 0){
    80001f00:	0204cc63          	bltz	s1,80001f38 <growproc+0x5a>
  p->sz = sz;
    80001f04:	1602                	slli	a2,a2,0x20
    80001f06:	9201                	srli	a2,a2,0x20
    80001f08:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f0c:	4501                	li	a0,0
}
    80001f0e:	60e2                	ld	ra,24(sp)
    80001f10:	6442                	ld	s0,16(sp)
    80001f12:	64a2                	ld	s1,8(sp)
    80001f14:	6902                	ld	s2,0(sp)
    80001f16:	6105                	addi	sp,sp,32
    80001f18:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f1a:	9e25                	addw	a2,a2,s1
    80001f1c:	1602                	slli	a2,a2,0x20
    80001f1e:	9201                	srli	a2,a2,0x20
    80001f20:	1582                	slli	a1,a1,0x20
    80001f22:	9181                	srli	a1,a1,0x20
    80001f24:	6928                	ld	a0,80(a0)
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	698080e7          	jalr	1688(ra) # 800015be <uvmalloc>
    80001f2e:	0005061b          	sext.w	a2,a0
    80001f32:	fa69                	bnez	a2,80001f04 <growproc+0x26>
      return -1;
    80001f34:	557d                	li	a0,-1
    80001f36:	bfe1                	j	80001f0e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f38:	9e25                	addw	a2,a2,s1
    80001f3a:	1602                	slli	a2,a2,0x20
    80001f3c:	9201                	srli	a2,a2,0x20
    80001f3e:	1582                	slli	a1,a1,0x20
    80001f40:	9181                	srli	a1,a1,0x20
    80001f42:	6928                	ld	a0,80(a0)
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	632080e7          	jalr	1586(ra) # 80001576 <uvmdealloc>
    80001f4c:	0005061b          	sext.w	a2,a0
    80001f50:	bf55                	j	80001f04 <growproc+0x26>

0000000080001f52 <fork>:
{
    80001f52:	7179                	addi	sp,sp,-48
    80001f54:	f406                	sd	ra,40(sp)
    80001f56:	f022                	sd	s0,32(sp)
    80001f58:	ec26                	sd	s1,24(sp)
    80001f5a:	e84a                	sd	s2,16(sp)
    80001f5c:	e44e                	sd	s3,8(sp)
    80001f5e:	e052                	sd	s4,0(sp)
    80001f60:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f62:	00000097          	auipc	ra,0x0
    80001f66:	bee080e7          	jalr	-1042(ra) # 80001b50 <myproc>
    80001f6a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	dee080e7          	jalr	-530(ra) # 80001d5a <allocproc>
    80001f74:	10050b63          	beqz	a0,8000208a <fork+0x138>
    80001f78:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f7a:	04893603          	ld	a2,72(s2)
    80001f7e:	692c                	ld	a1,80(a0)
    80001f80:	05093503          	ld	a0,80(s2)
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	786080e7          	jalr	1926(ra) # 8000170a <uvmcopy>
    80001f8c:	04054663          	bltz	a0,80001fd8 <fork+0x86>
  np->sz = p->sz;
    80001f90:	04893783          	ld	a5,72(s2)
    80001f94:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f98:	05893683          	ld	a3,88(s2)
    80001f9c:	87b6                	mv	a5,a3
    80001f9e:	0589b703          	ld	a4,88(s3)
    80001fa2:	12068693          	addi	a3,a3,288
    80001fa6:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001faa:	6788                	ld	a0,8(a5)
    80001fac:	6b8c                	ld	a1,16(a5)
    80001fae:	6f90                	ld	a2,24(a5)
    80001fb0:	01073023          	sd	a6,0(a4)
    80001fb4:	e708                	sd	a0,8(a4)
    80001fb6:	eb0c                	sd	a1,16(a4)
    80001fb8:	ef10                	sd	a2,24(a4)
    80001fba:	02078793          	addi	a5,a5,32
    80001fbe:	02070713          	addi	a4,a4,32
    80001fc2:	fed792e3          	bne	a5,a3,80001fa6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001fc6:	0589b783          	ld	a5,88(s3)
    80001fca:	0607b823          	sd	zero,112(a5)
    80001fce:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fd2:	15000a13          	li	s4,336
    80001fd6:	a03d                	j	80002004 <fork+0xb2>
    freeproc(np);
    80001fd8:	854e                	mv	a0,s3
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	d28080e7          	jalr	-728(ra) # 80001d02 <freeproc>
    release(&np->lock);
    80001fe2:	854e                	mv	a0,s3
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	cb4080e7          	jalr	-844(ra) # 80000c98 <release>
    return -1;
    80001fec:	5a7d                	li	s4,-1
    80001fee:	a069                	j	80002078 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ff0:	00002097          	auipc	ra,0x2
    80001ff4:	62c080e7          	jalr	1580(ra) # 8000461c <filedup>
    80001ff8:	009987b3          	add	a5,s3,s1
    80001ffc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ffe:	04a1                	addi	s1,s1,8
    80002000:	01448763          	beq	s1,s4,8000200e <fork+0xbc>
    if(p->ofile[i])
    80002004:	009907b3          	add	a5,s2,s1
    80002008:	6388                	ld	a0,0(a5)
    8000200a:	f17d                	bnez	a0,80001ff0 <fork+0x9e>
    8000200c:	bfcd                	j	80001ffe <fork+0xac>
  np->cwd = idup(p->cwd);
    8000200e:	15093503          	ld	a0,336(s2)
    80002012:	00001097          	auipc	ra,0x1
    80002016:	780080e7          	jalr	1920(ra) # 80003792 <idup>
    8000201a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000201e:	4641                	li	a2,16
    80002020:	15890593          	addi	a1,s2,344
    80002024:	15898513          	addi	a0,s3,344
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	e0a080e7          	jalr	-502(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80002030:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002034:	854e                	mv	a0,s3
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	c62080e7          	jalr	-926(ra) # 80000c98 <release>
  acquire(&wait_lock);
    8000203e:	00016497          	auipc	s1,0x16
    80002042:	27a48493          	addi	s1,s1,634 # 800182b8 <wait_lock>
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	b9c080e7          	jalr	-1124(ra) # 80000be4 <acquire>
  np->parent = p;
    80002050:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002054:	8526                	mv	a0,s1
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	c42080e7          	jalr	-958(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000205e:	854e                	mv	a0,s3
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	b84080e7          	jalr	-1148(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002068:	478d                	li	a5,3
    8000206a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000206e:	854e                	mv	a0,s3
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c28080e7          	jalr	-984(ra) # 80000c98 <release>
}
    80002078:	8552                	mv	a0,s4
    8000207a:	70a2                	ld	ra,40(sp)
    8000207c:	7402                	ld	s0,32(sp)
    8000207e:	64e2                	ld	s1,24(sp)
    80002080:	6942                	ld	s2,16(sp)
    80002082:	69a2                	ld	s3,8(sp)
    80002084:	6a02                	ld	s4,0(sp)
    80002086:	6145                	addi	sp,sp,48
    80002088:	8082                	ret
    return -1;
    8000208a:	5a7d                	li	s4,-1
    8000208c:	b7f5                	j	80002078 <fork+0x126>

000000008000208e <scheduler>:
{
    8000208e:	7139                	addi	sp,sp,-64
    80002090:	fc06                	sd	ra,56(sp)
    80002092:	f822                	sd	s0,48(sp)
    80002094:	f426                	sd	s1,40(sp)
    80002096:	f04a                	sd	s2,32(sp)
    80002098:	ec4e                	sd	s3,24(sp)
    8000209a:	e852                	sd	s4,16(sp)
    8000209c:	e456                	sd	s5,8(sp)
    8000209e:	e05a                	sd	s6,0(sp)
    800020a0:	0080                	addi	s0,sp,64
    800020a2:	8792                	mv	a5,tp
  int id = r_tp();
    800020a4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020a6:	00779a93          	slli	s5,a5,0x7
    800020aa:	00016717          	auipc	a4,0x16
    800020ae:	1f670713          	addi	a4,a4,502 # 800182a0 <pid_lock>
    800020b2:	9756                	add	a4,a4,s5
    800020b4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800020b8:	00016717          	auipc	a4,0x16
    800020bc:	22070713          	addi	a4,a4,544 # 800182d8 <cpus+0x8>
    800020c0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020c2:	498d                	li	s3,3
        p->state = RUNNING;
    800020c4:	4b11                	li	s6,4
        c->proc = p;
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	00016a17          	auipc	s4,0x16
    800020cc:	1d8a0a13          	addi	s4,s4,472 # 800182a0 <pid_lock>
    800020d0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020d2:	0001c917          	auipc	s2,0x1c
    800020d6:	ffe90913          	addi	s2,s2,-2 # 8001e0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020de:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020e2:	10079073          	csrw	sstatus,a5
    800020e6:	00016497          	auipc	s1,0x16
    800020ea:	5ea48493          	addi	s1,s1,1514 # 800186d0 <proc>
    800020ee:	a03d                	j	8000211c <scheduler+0x8e>
        p->state = RUNNING;
    800020f0:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020f4:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020f8:	06048593          	addi	a1,s1,96
    800020fc:	8556                	mv	a0,s5
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	640080e7          	jalr	1600(ra) # 8000273e <swtch>
	c->proc = 0;
    80002106:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002114:	16848493          	addi	s1,s1,360
    80002118:	fd2481e3          	beq	s1,s2,800020da <scheduler+0x4c>
      acquire(&p->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	ac6080e7          	jalr	-1338(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002126:	4c9c                	lw	a5,24(s1)
    80002128:	ff3791e3          	bne	a5,s3,8000210a <scheduler+0x7c>
    8000212c:	b7d1                	j	800020f0 <scheduler+0x62>

000000008000212e <sched>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000213c:	00000097          	auipc	ra,0x0
    80002140:	a14080e7          	jalr	-1516(ra) # 80001b50 <myproc>
    80002144:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	a24080e7          	jalr	-1500(ra) # 80000b6a <holding>
    8000214e:	c93d                	beqz	a0,800021c4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002150:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002152:	2781                	sext.w	a5,a5
    80002154:	079e                	slli	a5,a5,0x7
    80002156:	00016717          	auipc	a4,0x16
    8000215a:	14a70713          	addi	a4,a4,330 # 800182a0 <pid_lock>
    8000215e:	97ba                	add	a5,a5,a4
    80002160:	0a87a703          	lw	a4,168(a5)
    80002164:	4785                	li	a5,1
    80002166:	06f71763          	bne	a4,a5,800021d4 <sched+0xa6>
  if(p->state == RUNNING)
    8000216a:	4c98                	lw	a4,24(s1)
    8000216c:	4791                	li	a5,4
    8000216e:	06f70b63          	beq	a4,a5,800021e4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002172:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002176:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002178:	efb5                	bnez	a5,800021f4 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000217a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000217c:	00016917          	auipc	s2,0x16
    80002180:	12490913          	addi	s2,s2,292 # 800182a0 <pid_lock>
    80002184:	2781                	sext.w	a5,a5
    80002186:	079e                	slli	a5,a5,0x7
    80002188:	97ca                	add	a5,a5,s2
    8000218a:	0ac7a983          	lw	s3,172(a5)
    8000218e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	00016597          	auipc	a1,0x16
    80002198:	14458593          	addi	a1,a1,324 # 800182d8 <cpus+0x8>
    8000219c:	95be                	add	a1,a1,a5
    8000219e:	06048513          	addi	a0,s1,96
    800021a2:	00000097          	auipc	ra,0x0
    800021a6:	59c080e7          	jalr	1436(ra) # 8000273e <swtch>
    800021aa:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021ac:	2781                	sext.w	a5,a5
    800021ae:	079e                	slli	a5,a5,0x7
    800021b0:	97ca                	add	a5,a5,s2
    800021b2:	0b37a623          	sw	s3,172(a5)
}
    800021b6:	70a2                	ld	ra,40(sp)
    800021b8:	7402                	ld	s0,32(sp)
    800021ba:	64e2                	ld	s1,24(sp)
    800021bc:	6942                	ld	s2,16(sp)
    800021be:	69a2                	ld	s3,8(sp)
    800021c0:	6145                	addi	sp,sp,48
    800021c2:	8082                	ret
    panic("sched p->lock");
    800021c4:	0000a517          	auipc	a0,0xa
    800021c8:	2c450513          	addi	a0,a0,708 # 8000c488 <digits+0x448>
    800021cc:	ffffe097          	auipc	ra,0xffffe
    800021d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
    panic("sched locks");
    800021d4:	0000a517          	auipc	a0,0xa
    800021d8:	2c450513          	addi	a0,a0,708 # 8000c498 <digits+0x458>
    800021dc:	ffffe097          	auipc	ra,0xffffe
    800021e0:	362080e7          	jalr	866(ra) # 8000053e <panic>
    panic("sched running");
    800021e4:	0000a517          	auipc	a0,0xa
    800021e8:	2c450513          	addi	a0,a0,708 # 8000c4a8 <digits+0x468>
    800021ec:	ffffe097          	auipc	ra,0xffffe
    800021f0:	352080e7          	jalr	850(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021f4:	0000a517          	auipc	a0,0xa
    800021f8:	2c450513          	addi	a0,a0,708 # 8000c4b8 <digits+0x478>
    800021fc:	ffffe097          	auipc	ra,0xffffe
    80002200:	342080e7          	jalr	834(ra) # 8000053e <panic>

0000000080002204 <yield>:
{
    80002204:	1101                	addi	sp,sp,-32
    80002206:	ec06                	sd	ra,24(sp)
    80002208:	e822                	sd	s0,16(sp)
    8000220a:	e426                	sd	s1,8(sp)
    8000220c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	942080e7          	jalr	-1726(ra) # 80001b50 <myproc>
    80002216:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9cc080e7          	jalr	-1588(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002220:	478d                	li	a5,3
    80002222:	cc9c                	sw	a5,24(s1)
  sched();
    80002224:	00000097          	auipc	ra,0x0
    80002228:	f0a080e7          	jalr	-246(ra) # 8000212e <sched>
  release(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	a6a080e7          	jalr	-1430(ra) # 80000c98 <release>
}
    80002236:	60e2                	ld	ra,24(sp)
    80002238:	6442                	ld	s0,16(sp)
    8000223a:	64a2                	ld	s1,8(sp)
    8000223c:	6105                	addi	sp,sp,32
    8000223e:	8082                	ret

0000000080002240 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002240:	7179                	addi	sp,sp,-48
    80002242:	f406                	sd	ra,40(sp)
    80002244:	f022                	sd	s0,32(sp)
    80002246:	ec26                	sd	s1,24(sp)
    80002248:	e84a                	sd	s2,16(sp)
    8000224a:	e44e                	sd	s3,8(sp)
    8000224c:	1800                	addi	s0,sp,48
    8000224e:	89aa                	mv	s3,a0
    80002250:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	8fe080e7          	jalr	-1794(ra) # 80001b50 <myproc>
    8000225a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	988080e7          	jalr	-1656(ra) # 80000be4 <acquire>
  release(lk);
    80002264:	854a                	mv	a0,s2
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000226e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002272:	4789                	li	a5,2
    80002274:	cc9c                	sw	a5,24(s1)

  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	eb8080e7          	jalr	-328(ra) # 8000212e <sched>

  // Tidy up.
  p->chan = 0;
    8000227e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
  acquire(lk);
    8000228c:	854a                	mv	a0,s2
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	956080e7          	jalr	-1706(ra) # 80000be4 <acquire>
}
    80002296:	70a2                	ld	ra,40(sp)
    80002298:	7402                	ld	s0,32(sp)
    8000229a:	64e2                	ld	s1,24(sp)
    8000229c:	6942                	ld	s2,16(sp)
    8000229e:	69a2                	ld	s3,8(sp)
    800022a0:	6145                	addi	sp,sp,48
    800022a2:	8082                	ret

00000000800022a4 <wait>:
{
    800022a4:	715d                	addi	sp,sp,-80
    800022a6:	e486                	sd	ra,72(sp)
    800022a8:	e0a2                	sd	s0,64(sp)
    800022aa:	fc26                	sd	s1,56(sp)
    800022ac:	f84a                	sd	s2,48(sp)
    800022ae:	f44e                	sd	s3,40(sp)
    800022b0:	f052                	sd	s4,32(sp)
    800022b2:	ec56                	sd	s5,24(sp)
    800022b4:	e85a                	sd	s6,16(sp)
    800022b6:	e45e                	sd	s7,8(sp)
    800022b8:	e062                	sd	s8,0(sp)
    800022ba:	0880                	addi	s0,sp,80
    800022bc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	892080e7          	jalr	-1902(ra) # 80001b50 <myproc>
    800022c6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800022c8:	00016517          	auipc	a0,0x16
    800022cc:	ff050513          	addi	a0,a0,-16 # 800182b8 <wait_lock>
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	914080e7          	jalr	-1772(ra) # 80000be4 <acquire>
    havekids = 0;
    800022d8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022da:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800022dc:	0001c997          	auipc	s3,0x1c
    800022e0:	df498993          	addi	s3,s3,-524 # 8001e0d0 <tickslock>
        havekids = 1;
    800022e4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022e6:	00016c17          	auipc	s8,0x16
    800022ea:	fd2c0c13          	addi	s8,s8,-46 # 800182b8 <wait_lock>
    havekids = 0;
    800022ee:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00016497          	auipc	s1,0x16
    800022f4:	3e048493          	addi	s1,s1,992 # 800186d0 <proc>
    800022f8:	a0bd                	j	80002366 <wait+0xc2>
          pid = np->pid;
    800022fa:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022fe:	000b0e63          	beqz	s6,8000231a <wait+0x76>
    80002302:	4691                	li	a3,4
    80002304:	02c48613          	addi	a2,s1,44
    80002308:	85da                	mv	a1,s6
    8000230a:	05093503          	ld	a0,80(s2)
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	504080e7          	jalr	1284(ra) # 80001812 <copyout>
    80002316:	02054563          	bltz	a0,80002340 <wait+0x9c>
          freeproc(np);
    8000231a:	8526                	mv	a0,s1
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	9e6080e7          	jalr	-1562(ra) # 80001d02 <freeproc>
          release(&np->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	972080e7          	jalr	-1678(ra) # 80000c98 <release>
          release(&wait_lock);
    8000232e:	00016517          	auipc	a0,0x16
    80002332:	f8a50513          	addi	a0,a0,-118 # 800182b8 <wait_lock>
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	962080e7          	jalr	-1694(ra) # 80000c98 <release>
          return pid;
    8000233e:	a09d                	j	800023a4 <wait+0x100>
            release(&np->lock);
    80002340:	8526                	mv	a0,s1
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	956080e7          	jalr	-1706(ra) # 80000c98 <release>
            release(&wait_lock);
    8000234a:	00016517          	auipc	a0,0x16
    8000234e:	f6e50513          	addi	a0,a0,-146 # 800182b8 <wait_lock>
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	946080e7          	jalr	-1722(ra) # 80000c98 <release>
            return -1;
    8000235a:	59fd                	li	s3,-1
    8000235c:	a0a1                	j	800023a4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235e:	16848493          	addi	s1,s1,360
    80002362:	03348463          	beq	s1,s3,8000238a <wait+0xe6>
      if(np->parent == p){
    80002366:	7c9c                	ld	a5,56(s1)
    80002368:	ff279be3          	bne	a5,s2,8000235e <wait+0xba>
        acquire(&np->lock);
    8000236c:	8526                	mv	a0,s1
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	876080e7          	jalr	-1930(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002376:	4c9c                	lw	a5,24(s1)
    80002378:	f94781e3          	beq	a5,s4,800022fa <wait+0x56>
        release(&np->lock);
    8000237c:	8526                	mv	a0,s1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	91a080e7          	jalr	-1766(ra) # 80000c98 <release>
        havekids = 1;
    80002386:	8756                	mv	a4,s5
    80002388:	bfd9                	j	8000235e <wait+0xba>
    if(!havekids || p->killed){
    8000238a:	c701                	beqz	a4,80002392 <wait+0xee>
    8000238c:	02892783          	lw	a5,40(s2)
    80002390:	c79d                	beqz	a5,800023be <wait+0x11a>
      release(&wait_lock);
    80002392:	00016517          	auipc	a0,0x16
    80002396:	f2650513          	addi	a0,a0,-218 # 800182b8 <wait_lock>
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
      return -1;
    800023a2:	59fd                	li	s3,-1
}
    800023a4:	854e                	mv	a0,s3
    800023a6:	60a6                	ld	ra,72(sp)
    800023a8:	6406                	ld	s0,64(sp)
    800023aa:	74e2                	ld	s1,56(sp)
    800023ac:	7942                	ld	s2,48(sp)
    800023ae:	79a2                	ld	s3,40(sp)
    800023b0:	7a02                	ld	s4,32(sp)
    800023b2:	6ae2                	ld	s5,24(sp)
    800023b4:	6b42                	ld	s6,16(sp)
    800023b6:	6ba2                	ld	s7,8(sp)
    800023b8:	6c02                	ld	s8,0(sp)
    800023ba:	6161                	addi	sp,sp,80
    800023bc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023be:	85e2                	mv	a1,s8
    800023c0:	854a                	mv	a0,s2
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	e7e080e7          	jalr	-386(ra) # 80002240 <sleep>
    havekids = 0;
    800023ca:	b715                	j	800022ee <wait+0x4a>

00000000800023cc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800023cc:	7139                	addi	sp,sp,-64
    800023ce:	fc06                	sd	ra,56(sp)
    800023d0:	f822                	sd	s0,48(sp)
    800023d2:	f426                	sd	s1,40(sp)
    800023d4:	f04a                	sd	s2,32(sp)
    800023d6:	ec4e                	sd	s3,24(sp)
    800023d8:	e852                	sd	s4,16(sp)
    800023da:	e456                	sd	s5,8(sp)
    800023dc:	0080                	addi	s0,sp,64
    800023de:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800023e0:	00016497          	auipc	s1,0x16
    800023e4:	2f048493          	addi	s1,s1,752 # 800186d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023e8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023ea:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ec:	0001c917          	auipc	s2,0x1c
    800023f0:	ce490913          	addi	s2,s2,-796 # 8001e0d0 <tickslock>
    800023f4:	a821                	j	8000240c <wakeup+0x40>
        p->state = RUNNABLE;
    800023f6:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002404:	16848493          	addi	s1,s1,360
    80002408:	03248463          	beq	s1,s2,80002430 <wakeup+0x64>
    if(p != myproc()){
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	744080e7          	jalr	1860(ra) # 80001b50 <myproc>
    80002414:	fea488e3          	beq	s1,a0,80002404 <wakeup+0x38>
      acquire(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7ca080e7          	jalr	1994(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002422:	4c9c                	lw	a5,24(s1)
    80002424:	fd379be3          	bne	a5,s3,800023fa <wakeup+0x2e>
    80002428:	709c                	ld	a5,32(s1)
    8000242a:	fd4798e3          	bne	a5,s4,800023fa <wakeup+0x2e>
    8000242e:	b7e1                	j	800023f6 <wakeup+0x2a>
    }
  }
}
    80002430:	70e2                	ld	ra,56(sp)
    80002432:	7442                	ld	s0,48(sp)
    80002434:	74a2                	ld	s1,40(sp)
    80002436:	7902                	ld	s2,32(sp)
    80002438:	69e2                	ld	s3,24(sp)
    8000243a:	6a42                	ld	s4,16(sp)
    8000243c:	6aa2                	ld	s5,8(sp)
    8000243e:	6121                	addi	sp,sp,64
    80002440:	8082                	ret

0000000080002442 <reparent>:
{
    80002442:	7179                	addi	sp,sp,-48
    80002444:	f406                	sd	ra,40(sp)
    80002446:	f022                	sd	s0,32(sp)
    80002448:	ec26                	sd	s1,24(sp)
    8000244a:	e84a                	sd	s2,16(sp)
    8000244c:	e44e                	sd	s3,8(sp)
    8000244e:	e052                	sd	s4,0(sp)
    80002450:	1800                	addi	s0,sp,48
    80002452:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002454:	00016497          	auipc	s1,0x16
    80002458:	27c48493          	addi	s1,s1,636 # 800186d0 <proc>
      pp->parent = initproc;
    8000245c:	0000ea17          	auipc	s4,0xe
    80002460:	bcca0a13          	addi	s4,s4,-1076 # 80010028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002464:	0001c997          	auipc	s3,0x1c
    80002468:	c6c98993          	addi	s3,s3,-916 # 8001e0d0 <tickslock>
    8000246c:	a029                	j	80002476 <reparent+0x34>
    8000246e:	16848493          	addi	s1,s1,360
    80002472:	01348d63          	beq	s1,s3,8000248c <reparent+0x4a>
    if(pp->parent == p){
    80002476:	7c9c                	ld	a5,56(s1)
    80002478:	ff279be3          	bne	a5,s2,8000246e <reparent+0x2c>
      pp->parent = initproc;
    8000247c:	000a3503          	ld	a0,0(s4)
    80002480:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002482:	00000097          	auipc	ra,0x0
    80002486:	f4a080e7          	jalr	-182(ra) # 800023cc <wakeup>
    8000248a:	b7d5                	j	8000246e <reparent+0x2c>
}
    8000248c:	70a2                	ld	ra,40(sp)
    8000248e:	7402                	ld	s0,32(sp)
    80002490:	64e2                	ld	s1,24(sp)
    80002492:	6942                	ld	s2,16(sp)
    80002494:	69a2                	ld	s3,8(sp)
    80002496:	6a02                	ld	s4,0(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret

000000008000249c <exit>:
{
    8000249c:	7179                	addi	sp,sp,-48
    8000249e:	f406                	sd	ra,40(sp)
    800024a0:	f022                	sd	s0,32(sp)
    800024a2:	ec26                	sd	s1,24(sp)
    800024a4:	e84a                	sd	s2,16(sp)
    800024a6:	e44e                	sd	s3,8(sp)
    800024a8:	e052                	sd	s4,0(sp)
    800024aa:	1800                	addi	s0,sp,48
    800024ac:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	6a2080e7          	jalr	1698(ra) # 80001b50 <myproc>
    800024b6:	89aa                	mv	s3,a0
  if(p == initproc)
    800024b8:	0000e797          	auipc	a5,0xe
    800024bc:	b707b783          	ld	a5,-1168(a5) # 80010028 <initproc>
    800024c0:	0d050493          	addi	s1,a0,208
    800024c4:	15050913          	addi	s2,a0,336
    800024c8:	02a79363          	bne	a5,a0,800024ee <exit+0x52>
    panic("init exiting");
    800024cc:	0000a517          	auipc	a0,0xa
    800024d0:	00450513          	addi	a0,a0,4 # 8000c4d0 <digits+0x490>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	06a080e7          	jalr	106(ra) # 8000053e <panic>
      fileclose(f);
    800024dc:	00002097          	auipc	ra,0x2
    800024e0:	192080e7          	jalr	402(ra) # 8000466e <fileclose>
      p->ofile[fd] = 0;
    800024e4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024e8:	04a1                	addi	s1,s1,8
    800024ea:	01248563          	beq	s1,s2,800024f4 <exit+0x58>
    if(p->ofile[fd]){
    800024ee:	6088                	ld	a0,0(s1)
    800024f0:	f575                	bnez	a0,800024dc <exit+0x40>
    800024f2:	bfdd                	j	800024e8 <exit+0x4c>
  begin_op();
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	cae080e7          	jalr	-850(ra) # 800041a2 <begin_op>
  iput(p->cwd);
    800024fc:	1509b503          	ld	a0,336(s3)
    80002500:	00001097          	auipc	ra,0x1
    80002504:	48a080e7          	jalr	1162(ra) # 8000398a <iput>
  end_op();
    80002508:	00002097          	auipc	ra,0x2
    8000250c:	d1a080e7          	jalr	-742(ra) # 80004222 <end_op>
  p->cwd = 0;
    80002510:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002514:	00016497          	auipc	s1,0x16
    80002518:	da448493          	addi	s1,s1,-604 # 800182b8 <wait_lock>
    8000251c:	8526                	mv	a0,s1
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	6c6080e7          	jalr	1734(ra) # 80000be4 <acquire>
  reparent(p);
    80002526:	854e                	mv	a0,s3
    80002528:	00000097          	auipc	ra,0x0
    8000252c:	f1a080e7          	jalr	-230(ra) # 80002442 <reparent>
  wakeup(p->parent);
    80002530:	0389b503          	ld	a0,56(s3)
    80002534:	00000097          	auipc	ra,0x0
    80002538:	e98080e7          	jalr	-360(ra) # 800023cc <wakeup>
  acquire(&p->lock);
    8000253c:	854e                	mv	a0,s3
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	6a6080e7          	jalr	1702(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002546:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000254a:	4795                	li	a5,5
    8000254c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002550:	8526                	mv	a0,s1
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	746080e7          	jalr	1862(ra) # 80000c98 <release>
  sched();
    8000255a:	00000097          	auipc	ra,0x0
    8000255e:	bd4080e7          	jalr	-1068(ra) # 8000212e <sched>
  panic("zombie exit");
    80002562:	0000a517          	auipc	a0,0xa
    80002566:	f7e50513          	addi	a0,a0,-130 # 8000c4e0 <digits+0x4a0>
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	fd4080e7          	jalr	-44(ra) # 8000053e <panic>

0000000080002572 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002572:	7179                	addi	sp,sp,-48
    80002574:	f406                	sd	ra,40(sp)
    80002576:	f022                	sd	s0,32(sp)
    80002578:	ec26                	sd	s1,24(sp)
    8000257a:	e84a                	sd	s2,16(sp)
    8000257c:	e44e                	sd	s3,8(sp)
    8000257e:	1800                	addi	s0,sp,48
    80002580:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002582:	00016497          	auipc	s1,0x16
    80002586:	14e48493          	addi	s1,s1,334 # 800186d0 <proc>
    8000258a:	0001c997          	auipc	s3,0x1c
    8000258e:	b4698993          	addi	s3,s3,-1210 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    80002592:	8526                	mv	a0,s1
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	650080e7          	jalr	1616(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000259c:	589c                	lw	a5,48(s1)
    8000259e:	01278d63          	beq	a5,s2,800025b8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6f4080e7          	jalr	1780(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ac:	16848493          	addi	s1,s1,360
    800025b0:	ff3491e3          	bne	s1,s3,80002592 <kill+0x20>
  }
  return -1;
    800025b4:	557d                	li	a0,-1
    800025b6:	a829                	j	800025d0 <kill+0x5e>
      p->killed = 1;
    800025b8:	4785                	li	a5,1
    800025ba:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025bc:	4c98                	lw	a4,24(s1)
    800025be:	4789                	li	a5,2
    800025c0:	00f70f63          	beq	a4,a5,800025de <kill+0x6c>
      release(&p->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	6d2080e7          	jalr	1746(ra) # 80000c98 <release>
      return 0;
    800025ce:	4501                	li	a0,0
}
    800025d0:	70a2                	ld	ra,40(sp)
    800025d2:	7402                	ld	s0,32(sp)
    800025d4:	64e2                	ld	s1,24(sp)
    800025d6:	6942                	ld	s2,16(sp)
    800025d8:	69a2                	ld	s3,8(sp)
    800025da:	6145                	addi	sp,sp,48
    800025dc:	8082                	ret
        p->state = RUNNABLE;
    800025de:	478d                	li	a5,3
    800025e0:	cc9c                	sw	a5,24(s1)
    800025e2:	b7cd                	j	800025c4 <kill+0x52>

00000000800025e4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e4:	7179                	addi	sp,sp,-48
    800025e6:	f406                	sd	ra,40(sp)
    800025e8:	f022                	sd	s0,32(sp)
    800025ea:	ec26                	sd	s1,24(sp)
    800025ec:	e84a                	sd	s2,16(sp)
    800025ee:	e44e                	sd	s3,8(sp)
    800025f0:	e052                	sd	s4,0(sp)
    800025f2:	1800                	addi	s0,sp,48
    800025f4:	84aa                	mv	s1,a0
    800025f6:	892e                	mv	s2,a1
    800025f8:	89b2                	mv	s3,a2
    800025fa:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	554080e7          	jalr	1364(ra) # 80001b50 <myproc>
  if(user_dst){
    80002604:	c08d                	beqz	s1,80002626 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002606:	86d2                	mv	a3,s4
    80002608:	864e                	mv	a2,s3
    8000260a:	85ca                	mv	a1,s2
    8000260c:	6928                	ld	a0,80(a0)
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	204080e7          	jalr	516(ra) # 80001812 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6a02                	ld	s4,0(sp)
    80002622:	6145                	addi	sp,sp,48
    80002624:	8082                	ret
    memmove((char *)dst, src, len);
    80002626:	000a061b          	sext.w	a2,s4
    8000262a:	85ce                	mv	a1,s3
    8000262c:	854a                	mv	a0,s2
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	712080e7          	jalr	1810(ra) # 80000d40 <memmove>
    return 0;
    80002636:	8526                	mv	a0,s1
    80002638:	bff9                	j	80002616 <either_copyout+0x32>

000000008000263a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000263a:	7179                	addi	sp,sp,-48
    8000263c:	f406                	sd	ra,40(sp)
    8000263e:	f022                	sd	s0,32(sp)
    80002640:	ec26                	sd	s1,24(sp)
    80002642:	e84a                	sd	s2,16(sp)
    80002644:	e44e                	sd	s3,8(sp)
    80002646:	e052                	sd	s4,0(sp)
    80002648:	1800                	addi	s0,sp,48
    8000264a:	892a                	mv	s2,a0
    8000264c:	84ae                	mv	s1,a1
    8000264e:	89b2                	mv	s3,a2
    80002650:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	4fe080e7          	jalr	1278(ra) # 80001b50 <myproc>
  if(user_src){
    8000265a:	c08d                	beqz	s1,8000267c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000265c:	86d2                	mv	a3,s4
    8000265e:	864e                	mv	a2,s3
    80002660:	85ca                	mv	a1,s2
    80002662:	6928                	ld	a0,80(a0)
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	23a080e7          	jalr	570(ra) # 8000189e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000266c:	70a2                	ld	ra,40(sp)
    8000266e:	7402                	ld	s0,32(sp)
    80002670:	64e2                	ld	s1,24(sp)
    80002672:	6942                	ld	s2,16(sp)
    80002674:	69a2                	ld	s3,8(sp)
    80002676:	6a02                	ld	s4,0(sp)
    80002678:	6145                	addi	sp,sp,48
    8000267a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000267c:	000a061b          	sext.w	a2,s4
    80002680:	85ce                	mv	a1,s3
    80002682:	854a                	mv	a0,s2
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	6bc080e7          	jalr	1724(ra) # 80000d40 <memmove>
    return 0;
    8000268c:	8526                	mv	a0,s1
    8000268e:	bff9                	j	8000266c <either_copyin+0x32>

0000000080002690 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002690:	715d                	addi	sp,sp,-80
    80002692:	e486                	sd	ra,72(sp)
    80002694:	e0a2                	sd	s0,64(sp)
    80002696:	fc26                	sd	s1,56(sp)
    80002698:	f84a                	sd	s2,48(sp)
    8000269a:	f44e                	sd	s3,40(sp)
    8000269c:	f052                	sd	s4,32(sp)
    8000269e:	ec56                	sd	s5,24(sp)
    800026a0:	e85a                	sd	s6,16(sp)
    800026a2:	e45e                	sd	s7,8(sp)
    800026a4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026a6:	0000a517          	auipc	a0,0xa
    800026aa:	a7a50513          	addi	a0,a0,-1414 # 8000c120 <digits+0xe0>
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	eda080e7          	jalr	-294(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b6:	00016497          	auipc	s1,0x16
    800026ba:	17248493          	addi	s1,s1,370 # 80018828 <proc+0x158>
    800026be:	0001c917          	auipc	s2,0x1c
    800026c2:	b6a90913          	addi	s2,s2,-1174 # 8001e228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026c8:	0000a997          	auipc	s3,0xa
    800026cc:	e2898993          	addi	s3,s3,-472 # 8000c4f0 <digits+0x4b0>
    printf("%d %s %s", p->pid, state, p->name);
    800026d0:	0000aa97          	auipc	s5,0xa
    800026d4:	e28a8a93          	addi	s5,s5,-472 # 8000c4f8 <digits+0x4b8>
    printf("\n");
    800026d8:	0000aa17          	auipc	s4,0xa
    800026dc:	a48a0a13          	addi	s4,s4,-1464 # 8000c120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e0:	0000ab97          	auipc	s7,0xa
    800026e4:	e50b8b93          	addi	s7,s7,-432 # 8000c530 <states.1709>
    800026e8:	a00d                	j	8000270a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026ea:	ed86a583          	lw	a1,-296(a3)
    800026ee:	8556                	mv	a0,s5
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	e98080e7          	jalr	-360(ra) # 80000588 <printf>
    printf("\n");
    800026f8:	8552                	mv	a0,s4
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	e8e080e7          	jalr	-370(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002702:	16848493          	addi	s1,s1,360
    80002706:	03248163          	beq	s1,s2,80002728 <procdump+0x98>
    if(p->state == UNUSED)
    8000270a:	86a6                	mv	a3,s1
    8000270c:	ec04a783          	lw	a5,-320(s1)
    80002710:	dbed                	beqz	a5,80002702 <procdump+0x72>
      state = "???";
    80002712:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002714:	fcfb6be3          	bltu	s6,a5,800026ea <procdump+0x5a>
    80002718:	1782                	slli	a5,a5,0x20
    8000271a:	9381                	srli	a5,a5,0x20
    8000271c:	078e                	slli	a5,a5,0x3
    8000271e:	97de                	add	a5,a5,s7
    80002720:	6390                	ld	a2,0(a5)
    80002722:	f661                	bnez	a2,800026ea <procdump+0x5a>
      state = "???";
    80002724:	864e                	mv	a2,s3
    80002726:	b7d1                	j	800026ea <procdump+0x5a>
  }
}
    80002728:	60a6                	ld	ra,72(sp)
    8000272a:	6406                	ld	s0,64(sp)
    8000272c:	74e2                	ld	s1,56(sp)
    8000272e:	7942                	ld	s2,48(sp)
    80002730:	79a2                	ld	s3,40(sp)
    80002732:	7a02                	ld	s4,32(sp)
    80002734:	6ae2                	ld	s5,24(sp)
    80002736:	6b42                	ld	s6,16(sp)
    80002738:	6ba2                	ld	s7,8(sp)
    8000273a:	6161                	addi	sp,sp,80
    8000273c:	8082                	ret

000000008000273e <swtch>:
    8000273e:	00153023          	sd	ra,0(a0)
    80002742:	00253423          	sd	sp,8(a0)
    80002746:	e900                	sd	s0,16(a0)
    80002748:	ed04                	sd	s1,24(a0)
    8000274a:	03253023          	sd	s2,32(a0)
    8000274e:	03353423          	sd	s3,40(a0)
    80002752:	03453823          	sd	s4,48(a0)
    80002756:	03553c23          	sd	s5,56(a0)
    8000275a:	05653023          	sd	s6,64(a0)
    8000275e:	05753423          	sd	s7,72(a0)
    80002762:	05853823          	sd	s8,80(a0)
    80002766:	05953c23          	sd	s9,88(a0)
    8000276a:	07a53023          	sd	s10,96(a0)
    8000276e:	07b53423          	sd	s11,104(a0)
    80002772:	0005b083          	ld	ra,0(a1)
    80002776:	0085b103          	ld	sp,8(a1)
    8000277a:	6980                	ld	s0,16(a1)
    8000277c:	6d84                	ld	s1,24(a1)
    8000277e:	0205b903          	ld	s2,32(a1)
    80002782:	0285b983          	ld	s3,40(a1)
    80002786:	0305ba03          	ld	s4,48(a1)
    8000278a:	0385ba83          	ld	s5,56(a1)
    8000278e:	0405bb03          	ld	s6,64(a1)
    80002792:	0485bb83          	ld	s7,72(a1)
    80002796:	0505bc03          	ld	s8,80(a1)
    8000279a:	0585bc83          	ld	s9,88(a1)
    8000279e:	0605bd03          	ld	s10,96(a1)
    800027a2:	0685bd83          	ld	s11,104(a1)
    800027a6:	8082                	ret

00000000800027a8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027a8:	1141                	addi	sp,sp,-16
    800027aa:	e406                	sd	ra,8(sp)
    800027ac:	e022                	sd	s0,0(sp)
    800027ae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027b0:	0000a597          	auipc	a1,0xa
    800027b4:	db058593          	addi	a1,a1,-592 # 8000c560 <states.1709+0x30>
    800027b8:	0001c517          	auipc	a0,0x1c
    800027bc:	91850513          	addi	a0,a0,-1768 # 8001e0d0 <tickslock>
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	394080e7          	jalr	916(ra) # 80000b54 <initlock>
}
    800027c8:	60a2                	ld	ra,8(sp)
    800027ca:	6402                	ld	s0,0(sp)
    800027cc:	0141                	addi	sp,sp,16
    800027ce:	8082                	ret

00000000800027d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027d0:	1141                	addi	sp,sp,-16
    800027d2:	e406                	sd	ra,8(sp)
    800027d4:	e022                	sd	s0,0(sp)
    800027d6:	0800                	addi	s0,sp,16
  printf("kernelvec: %x\n",kernelvec);
    800027d8:	00003597          	auipc	a1,0x3
    800027dc:	4e858593          	addi	a1,a1,1256 # 80005cc0 <kernelvec>
    800027e0:	0000a517          	auipc	a0,0xa
    800027e4:	d8850513          	addi	a0,a0,-632 # 8000c568 <states.1709+0x38>
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	da0080e7          	jalr	-608(ra) # 80000588 <printf>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f0:	00003797          	auipc	a5,0x3
    800027f4:	4d078793          	addi	a5,a5,1232 # 80005cc0 <kernelvec>
    800027f8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027fc:	60a2                	ld	ra,8(sp)
    800027fe:	6402                	ld	s0,0(sp)
    80002800:	0141                	addi	sp,sp,16
    80002802:	8082                	ret

0000000080002804 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002804:	1141                	addi	sp,sp,-16
    80002806:	e406                	sd	ra,8(sp)
    80002808:	e022                	sd	s0,0(sp)
    8000280a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	344080e7          	jalr	836(ra) # 80001b50 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002814:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002818:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000281a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000281e:	00005617          	auipc	a2,0x5
    80002822:	7e260613          	addi	a2,a2,2018 # 80008000 <_trampoline>
    80002826:	00005697          	auipc	a3,0x5
    8000282a:	7da68693          	addi	a3,a3,2010 # 80008000 <_trampoline>
    8000282e:	8e91                	sub	a3,a3,a2
    80002830:	008007b7          	lui	a5,0x800
    80002834:	17fd                	addi	a5,a5,-1
    80002836:	07ba                	slli	a5,a5,0xe
    80002838:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000283a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000283e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002840:	180026f3          	csrr	a3,satp
    80002844:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002846:	6d38                	ld	a4,88(a0)
    80002848:	6134                	ld	a3,64(a0)
    8000284a:	6591                	lui	a1,0x4
    8000284c:	96ae                	add	a3,a3,a1
    8000284e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002850:	6d38                	ld	a4,88(a0)
    80002852:	00000697          	auipc	a3,0x0
    80002856:	13868693          	addi	a3,a3,312 # 8000298a <usertrap>
    8000285a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000285c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000285e:	8692                	mv	a3,tp
    80002860:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002862:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002866:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000286a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002872:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002874:	6f18                	ld	a4,24(a4)
    80002876:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000287a:	692c                	ld	a1,80(a0)
    8000287c:	81b9                	srli	a1,a1,0xe

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000287e:	00006717          	auipc	a4,0x6
    80002882:	81270713          	addi	a4,a4,-2030 # 80008090 <userret>
    80002886:	8f11                	sub	a4,a4,a2
    80002888:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000288a:	577d                	li	a4,-1
    8000288c:	177e                	slli	a4,a4,0x3f
    8000288e:	8dd9                	or	a1,a1,a4
    80002890:	00400537          	lui	a0,0x400
    80002894:	157d                	addi	a0,a0,-1
    80002896:	053e                	slli	a0,a0,0xf
    80002898:	9782                	jalr	a5
}
    8000289a:	60a2                	ld	ra,8(sp)
    8000289c:	6402                	ld	s0,0(sp)
    8000289e:	0141                	addi	sp,sp,16
    800028a0:	8082                	ret

00000000800028a2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028a2:	1101                	addi	sp,sp,-32
    800028a4:	ec06                	sd	ra,24(sp)
    800028a6:	e822                	sd	s0,16(sp)
    800028a8:	e426                	sd	s1,8(sp)
    800028aa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028ac:	0001c497          	auipc	s1,0x1c
    800028b0:	82448493          	addi	s1,s1,-2012 # 8001e0d0 <tickslock>
    800028b4:	8526                	mv	a0,s1
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	32e080e7          	jalr	814(ra) # 80000be4 <acquire>
  ticks++;
    800028be:	0000d517          	auipc	a0,0xd
    800028c2:	77250513          	addi	a0,a0,1906 # 80010030 <ticks>
    800028c6:	411c                	lw	a5,0(a0)
    800028c8:	2785                	addiw	a5,a5,1
    800028ca:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	b00080e7          	jalr	-1280(ra) # 800023cc <wakeup>
  release(&tickslock);
    800028d4:	8526                	mv	a0,s1
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	3c2080e7          	jalr	962(ra) # 80000c98 <release>
}
    800028de:	60e2                	ld	ra,24(sp)
    800028e0:	6442                	ld	s0,16(sp)
    800028e2:	64a2                	ld	s1,8(sp)
    800028e4:	6105                	addi	sp,sp,32
    800028e6:	8082                	ret

00000000800028e8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028e8:	1101                	addi	sp,sp,-32
    800028ea:	ec06                	sd	ra,24(sp)
    800028ec:	e822                	sd	s0,16(sp)
    800028ee:	e426                	sd	s1,8(sp)
    800028f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028f6:	00074d63          	bltz	a4,80002910 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028fa:	57fd                	li	a5,-1
    800028fc:	17fe                	slli	a5,a5,0x3f
    800028fe:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002900:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002902:	06f70363          	beq	a4,a5,80002968 <devintr+0x80>
  }
}
    80002906:	60e2                	ld	ra,24(sp)
    80002908:	6442                	ld	s0,16(sp)
    8000290a:	64a2                	ld	s1,8(sp)
    8000290c:	6105                	addi	sp,sp,32
    8000290e:	8082                	ret
     (scause & 0xff) == 9){
    80002910:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002914:	46a5                	li	a3,9
    80002916:	fed792e3          	bne	a5,a3,800028fa <devintr+0x12>
    int irq = plic_claim();
    8000291a:	00003097          	auipc	ra,0x3
    8000291e:	4ae080e7          	jalr	1198(ra) # 80005dc8 <plic_claim>
    80002922:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002924:	47a9                	li	a5,10
    80002926:	02f50763          	beq	a0,a5,80002954 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000292a:	4785                	li	a5,1
    8000292c:	02f50963          	beq	a0,a5,8000295e <devintr+0x76>
    return 1;
    80002930:	4505                	li	a0,1
    } else if(irq){
    80002932:	d8f1                	beqz	s1,80002906 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002934:	85a6                	mv	a1,s1
    80002936:	0000a517          	auipc	a0,0xa
    8000293a:	c4250513          	addi	a0,a0,-958 # 8000c578 <states.1709+0x48>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c4a080e7          	jalr	-950(ra) # 80000588 <printf>
      plic_complete(irq);
    80002946:	8526                	mv	a0,s1
    80002948:	00003097          	auipc	ra,0x3
    8000294c:	4a4080e7          	jalr	1188(ra) # 80005dec <plic_complete>
    return 1;
    80002950:	4505                	li	a0,1
    80002952:	bf55                	j	80002906 <devintr+0x1e>
      uartintr();
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	054080e7          	jalr	84(ra) # 800009a8 <uartintr>
    8000295c:	b7ed                	j	80002946 <devintr+0x5e>
      virtio_disk_intr();
    8000295e:	00004097          	auipc	ra,0x4
    80002962:	99c080e7          	jalr	-1636(ra) # 800062fa <virtio_disk_intr>
    80002966:	b7c5                	j	80002946 <devintr+0x5e>
    if(cpuid() == 0){
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	1bc080e7          	jalr	444(ra) # 80001b24 <cpuid>
    80002970:	c901                	beqz	a0,80002980 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002972:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002976:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002978:	14479073          	csrw	sip,a5
    return 2;
    8000297c:	4509                	li	a0,2
    8000297e:	b761                	j	80002906 <devintr+0x1e>
      clockintr();
    80002980:	00000097          	auipc	ra,0x0
    80002984:	f22080e7          	jalr	-222(ra) # 800028a2 <clockintr>
    80002988:	b7ed                	j	80002972 <devintr+0x8a>

000000008000298a <usertrap>:
{
    8000298a:	1101                	addi	sp,sp,-32
    8000298c:	ec06                	sd	ra,24(sp)
    8000298e:	e822                	sd	s0,16(sp)
    80002990:	e426                	sd	s1,8(sp)
    80002992:	e04a                	sd	s2,0(sp)
    80002994:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000299a:	1007f793          	andi	a5,a5,256
    8000299e:	e3ad                	bnez	a5,80002a00 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a0:	00003797          	auipc	a5,0x3
    800029a4:	32078793          	addi	a5,a5,800 # 80005cc0 <kernelvec>
    800029a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	1a4080e7          	jalr	420(ra) # 80001b50 <myproc>
    800029b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b8:	14102773          	csrr	a4,sepc
    800029bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029c2:	47a1                	li	a5,8
    800029c4:	04f71c63          	bne	a4,a5,80002a1c <usertrap+0x92>
    if(p->killed)
    800029c8:	551c                	lw	a5,40(a0)
    800029ca:	e3b9                	bnez	a5,80002a10 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029cc:	6cb8                	ld	a4,88(s1)
    800029ce:	6f1c                	ld	a5,24(a4)
    800029d0:	0791                	addi	a5,a5,4
    800029d2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029dc:	10079073          	csrw	sstatus,a5
    syscall();
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	2e0080e7          	jalr	736(ra) # 80002cc0 <syscall>
  if(p->killed)
    800029e8:	549c                	lw	a5,40(s1)
    800029ea:	ebc1                	bnez	a5,80002a7a <usertrap+0xf0>
  usertrapret();
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	e18080e7          	jalr	-488(ra) # 80002804 <usertrapret>
}
    800029f4:	60e2                	ld	ra,24(sp)
    800029f6:	6442                	ld	s0,16(sp)
    800029f8:	64a2                	ld	s1,8(sp)
    800029fa:	6902                	ld	s2,0(sp)
    800029fc:	6105                	addi	sp,sp,32
    800029fe:	8082                	ret
    panic("usertrap: not from user mode");
    80002a00:	0000a517          	auipc	a0,0xa
    80002a04:	b9850513          	addi	a0,a0,-1128 # 8000c598 <states.1709+0x68>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b36080e7          	jalr	-1226(ra) # 8000053e <panic>
      exit(-1);
    80002a10:	557d                	li	a0,-1
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	a8a080e7          	jalr	-1398(ra) # 8000249c <exit>
    80002a1a:	bf4d                	j	800029cc <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a1c:	00000097          	auipc	ra,0x0
    80002a20:	ecc080e7          	jalr	-308(ra) # 800028e8 <devintr>
    80002a24:	892a                	mv	s2,a0
    80002a26:	c501                	beqz	a0,80002a2e <usertrap+0xa4>
  if(p->killed)
    80002a28:	549c                	lw	a5,40(s1)
    80002a2a:	c3a1                	beqz	a5,80002a6a <usertrap+0xe0>
    80002a2c:	a815                	j	80002a60 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a32:	5890                	lw	a2,48(s1)
    80002a34:	0000a517          	auipc	a0,0xa
    80002a38:	b8450513          	addi	a0,a0,-1148 # 8000c5b8 <states.1709+0x88>
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	b4c080e7          	jalr	-1204(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a44:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a48:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a4c:	0000a517          	auipc	a0,0xa
    80002a50:	b9c50513          	addi	a0,a0,-1124 # 8000c5e8 <states.1709+0xb8>
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	b34080e7          	jalr	-1228(ra) # 80000588 <printf>
    p->killed = 1;
    80002a5c:	4785                	li	a5,1
    80002a5e:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a60:	557d                	li	a0,-1
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	a3a080e7          	jalr	-1478(ra) # 8000249c <exit>
  if(which_dev == 2)
    80002a6a:	4789                	li	a5,2
    80002a6c:	f8f910e3          	bne	s2,a5,800029ec <usertrap+0x62>
    yield();
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	794080e7          	jalr	1940(ra) # 80002204 <yield>
    80002a78:	bf95                	j	800029ec <usertrap+0x62>
  int which_dev = 0;
    80002a7a:	4901                	li	s2,0
    80002a7c:	b7d5                	j	80002a60 <usertrap+0xd6>

0000000080002a7e <kerneltrap>:
{
    80002a7e:	7179                	addi	sp,sp,-48
    80002a80:	f406                	sd	ra,40(sp)
    80002a82:	f022                	sd	s0,32(sp)
    80002a84:	ec26                	sd	s1,24(sp)
    80002a86:	e84a                	sd	s2,16(sp)
    80002a88:	e44e                	sd	s3,8(sp)
    80002a8a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a90:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a98:	1004f793          	andi	a5,s1,256
    80002a9c:	cb85                	beqz	a5,80002acc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aa2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aa4:	ef85                	bnez	a5,80002adc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	e42080e7          	jalr	-446(ra) # 800028e8 <devintr>
    80002aae:	cd1d                	beqz	a0,80002aec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab0:	4789                	li	a5,2
    80002ab2:	06f50a63          	beq	a0,a5,80002b26 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ab6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aba:	10049073          	csrw	sstatus,s1
}
    80002abe:	70a2                	ld	ra,40(sp)
    80002ac0:	7402                	ld	s0,32(sp)
    80002ac2:	64e2                	ld	s1,24(sp)
    80002ac4:	6942                	ld	s2,16(sp)
    80002ac6:	69a2                	ld	s3,8(sp)
    80002ac8:	6145                	addi	sp,sp,48
    80002aca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002acc:	0000a517          	auipc	a0,0xa
    80002ad0:	b3c50513          	addi	a0,a0,-1220 # 8000c608 <states.1709+0xd8>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a6a080e7          	jalr	-1430(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002adc:	0000a517          	auipc	a0,0xa
    80002ae0:	b5450513          	addi	a0,a0,-1196 # 8000c630 <states.1709+0x100>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a5a080e7          	jalr	-1446(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002aec:	85ce                	mv	a1,s3
    80002aee:	0000a517          	auipc	a0,0xa
    80002af2:	b6250513          	addi	a0,a0,-1182 # 8000c650 <states.1709+0x120>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a92080e7          	jalr	-1390(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b02:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b06:	0000a517          	auipc	a0,0xa
    80002b0a:	b5a50513          	addi	a0,a0,-1190 # 8000c660 <states.1709+0x130>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a7a080e7          	jalr	-1414(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002b16:	0000a517          	auipc	a0,0xa
    80002b1a:	b6250513          	addi	a0,a0,-1182 # 8000c678 <states.1709+0x148>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a20080e7          	jalr	-1504(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	02a080e7          	jalr	42(ra) # 80001b50 <myproc>
    80002b2e:	d541                	beqz	a0,80002ab6 <kerneltrap+0x38>
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	020080e7          	jalr	32(ra) # 80001b50 <myproc>
    80002b38:	4d18                	lw	a4,24(a0)
    80002b3a:	4791                	li	a5,4
    80002b3c:	f6f71de3          	bne	a4,a5,80002ab6 <kerneltrap+0x38>
    yield();
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	6c4080e7          	jalr	1732(ra) # 80002204 <yield>
    80002b48:	b7bd                	j	80002ab6 <kerneltrap+0x38>

0000000080002b4a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	ffa080e7          	jalr	-6(ra) # 80001b50 <myproc>
  switch (n) {
    80002b5e:	4795                	li	a5,5
    80002b60:	0497e163          	bltu	a5,s1,80002ba2 <argraw+0x58>
    80002b64:	048a                	slli	s1,s1,0x2
    80002b66:	0000a717          	auipc	a4,0xa
    80002b6a:	b4a70713          	addi	a4,a4,-1206 # 8000c6b0 <states.1709+0x180>
    80002b6e:	94ba                	add	s1,s1,a4
    80002b70:	409c                	lw	a5,0(s1)
    80002b72:	97ba                	add	a5,a5,a4
    80002b74:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b76:	6d3c                	ld	a5,88(a0)
    80002b78:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
    return p->trapframe->a1;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	7fa8                	ld	a0,120(a5)
    80002b88:	bfcd                	j	80002b7a <argraw+0x30>
    return p->trapframe->a2;
    80002b8a:	6d3c                	ld	a5,88(a0)
    80002b8c:	63c8                	ld	a0,128(a5)
    80002b8e:	b7f5                	j	80002b7a <argraw+0x30>
    return p->trapframe->a3;
    80002b90:	6d3c                	ld	a5,88(a0)
    80002b92:	67c8                	ld	a0,136(a5)
    80002b94:	b7dd                	j	80002b7a <argraw+0x30>
    return p->trapframe->a4;
    80002b96:	6d3c                	ld	a5,88(a0)
    80002b98:	6bc8                	ld	a0,144(a5)
    80002b9a:	b7c5                	j	80002b7a <argraw+0x30>
    return p->trapframe->a5;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	6fc8                	ld	a0,152(a5)
    80002ba0:	bfe9                	j	80002b7a <argraw+0x30>
  panic("argraw");
    80002ba2:	0000a517          	auipc	a0,0xa
    80002ba6:	ae650513          	addi	a0,a0,-1306 # 8000c688 <states.1709+0x158>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	994080e7          	jalr	-1644(ra) # 8000053e <panic>

0000000080002bb2 <fetchaddr>:
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	e04a                	sd	s2,0(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84aa                	mv	s1,a0
    80002bc0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	f8e080e7          	jalr	-114(ra) # 80001b50 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bca:	653c                	ld	a5,72(a0)
    80002bcc:	02f4f863          	bgeu	s1,a5,80002bfc <fetchaddr+0x4a>
    80002bd0:	00848713          	addi	a4,s1,8
    80002bd4:	02e7e663          	bltu	a5,a4,80002c00 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bd8:	46a1                	li	a3,8
    80002bda:	8626                	mv	a2,s1
    80002bdc:	85ca                	mv	a1,s2
    80002bde:	6928                	ld	a0,80(a0)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	cbe080e7          	jalr	-834(ra) # 8000189e <copyin>
    80002be8:	00a03533          	snez	a0,a0
    80002bec:	40a00533          	neg	a0,a0
}
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6902                	ld	s2,0(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret
    return -1;
    80002bfc:	557d                	li	a0,-1
    80002bfe:	bfcd                	j	80002bf0 <fetchaddr+0x3e>
    80002c00:	557d                	li	a0,-1
    80002c02:	b7fd                	j	80002bf0 <fetchaddr+0x3e>

0000000080002c04 <fetchstr>:
{
    80002c04:	7179                	addi	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	e44e                	sd	s3,8(sp)
    80002c10:	1800                	addi	s0,sp,48
    80002c12:	892a                	mv	s2,a0
    80002c14:	84ae                	mv	s1,a1
    80002c16:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	f38080e7          	jalr	-200(ra) # 80001b50 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c20:	86ce                	mv	a3,s3
    80002c22:	864a                	mv	a2,s2
    80002c24:	85a6                	mv	a1,s1
    80002c26:	6928                	ld	a0,80(a0)
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	d02080e7          	jalr	-766(ra) # 8000192a <copyinstr>
  if(err < 0)
    80002c30:	00054763          	bltz	a0,80002c3e <fetchstr+0x3a>
  return strlen(buf);
    80002c34:	8526                	mv	a0,s1
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	22e080e7          	jalr	558(ra) # 80000e64 <strlen>
}
    80002c3e:	70a2                	ld	ra,40(sp)
    80002c40:	7402                	ld	s0,32(sp)
    80002c42:	64e2                	ld	s1,24(sp)
    80002c44:	6942                	ld	s2,16(sp)
    80002c46:	69a2                	ld	s3,8(sp)
    80002c48:	6145                	addi	sp,sp,48
    80002c4a:	8082                	ret

0000000080002c4c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	ef2080e7          	jalr	-270(ra) # 80002b4a <argraw>
    80002c60:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c62:	4501                	li	a0,0
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6105                	addi	sp,sp,32
    80002c6c:	8082                	ret

0000000080002c6e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	ed0080e7          	jalr	-304(ra) # 80002b4a <argraw>
    80002c82:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c84:	4501                	li	a0,0
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	64a2                	ld	s1,8(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	e426                	sd	s1,8(sp)
    80002c98:	e04a                	sd	s2,0(sp)
    80002c9a:	1000                	addi	s0,sp,32
    80002c9c:	84ae                	mv	s1,a1
    80002c9e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	eaa080e7          	jalr	-342(ra) # 80002b4a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ca8:	864a                	mv	a2,s2
    80002caa:	85a6                	mv	a1,s1
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	f58080e7          	jalr	-168(ra) # 80002c04 <fetchstr>
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6902                	ld	s2,0(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret

0000000080002cc0 <syscall>:
[SYS_mmtrace] sys_mmtrace 
};

void
syscall(void)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	e04a                	sd	s2,0(sp)
    80002cca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	e84080e7          	jalr	-380(ra) # 80001b50 <myproc>
    80002cd4:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002cd6:	05853903          	ld	s2,88(a0)
    80002cda:	0a893783          	ld	a5,168(s2)
    80002cde:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ce2:	37fd                	addiw	a5,a5,-1
    80002ce4:	4755                	li	a4,21
    80002ce6:	00f76f63          	bltu	a4,a5,80002d04 <syscall+0x44>
    80002cea:	00369713          	slli	a4,a3,0x3
    80002cee:	0000a797          	auipc	a5,0xa
    80002cf2:	9da78793          	addi	a5,a5,-1574 # 8000c6c8 <syscalls>
    80002cf6:	97ba                	add	a5,a5,a4
    80002cf8:	639c                	ld	a5,0(a5)
    80002cfa:	c789                	beqz	a5,80002d04 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cfc:	9782                	jalr	a5
    80002cfe:	06a93823          	sd	a0,112(s2)
    80002d02:	a839                	j	80002d20 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d04:	15848613          	addi	a2,s1,344
    80002d08:	588c                	lw	a1,48(s1)
    80002d0a:	0000a517          	auipc	a0,0xa
    80002d0e:	98650513          	addi	a0,a0,-1658 # 8000c690 <states.1709+0x160>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	876080e7          	jalr	-1930(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d1a:	6cbc                	ld	a5,88(s1)
    80002d1c:	577d                	li	a4,-1
    80002d1e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6902                	ld	s2,0(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d34:	fec40593          	addi	a1,s0,-20
    80002d38:	4501                	li	a0,0
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	f12080e7          	jalr	-238(ra) # 80002c4c <argint>
    return -1;
    80002d42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d44:	00054963          	bltz	a0,80002d56 <sys_exit+0x2a>
  exit(n);
    80002d48:	fec42503          	lw	a0,-20(s0)
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	750080e7          	jalr	1872(ra) # 8000249c <exit>
  return 0;  // not reached
    80002d54:	4781                	li	a5,0
}
    80002d56:	853e                	mv	a0,a5
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d60:	1141                	addi	sp,sp,-16
    80002d62:	e406                	sd	ra,8(sp)
    80002d64:	e022                	sd	s0,0(sp)
    80002d66:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	de8080e7          	jalr	-536(ra) # 80001b50 <myproc>
}
    80002d70:	5908                	lw	a0,48(a0)
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <sys_fork>:

uint64
sys_fork(void)
{
    80002d7a:	1141                	addi	sp,sp,-16
    80002d7c:	e406                	sd	ra,8(sp)
    80002d7e:	e022                	sd	s0,0(sp)
    80002d80:	0800                	addi	s0,sp,16
  return fork();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	1d0080e7          	jalr	464(ra) # 80001f52 <fork>
}
    80002d8a:	60a2                	ld	ra,8(sp)
    80002d8c:	6402                	ld	s0,0(sp)
    80002d8e:	0141                	addi	sp,sp,16
    80002d90:	8082                	ret

0000000080002d92 <sys_wait>:

uint64
sys_wait(void)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d9a:	fe840593          	addi	a1,s0,-24
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ece080e7          	jalr	-306(ra) # 80002c6e <argaddr>
    80002da8:	87aa                	mv	a5,a0
    return -1;
    80002daa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dac:	0007c863          	bltz	a5,80002dbc <sys_wait+0x2a>
  return wait(p);
    80002db0:	fe843503          	ld	a0,-24(s0)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	4f0080e7          	jalr	1264(ra) # 800022a4 <wait>
}
    80002dbc:	60e2                	ld	ra,24(sp)
    80002dbe:	6442                	ld	s0,16(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dc4:	7179                	addi	sp,sp,-48
    80002dc6:	f406                	sd	ra,40(sp)
    80002dc8:	f022                	sd	s0,32(sp)
    80002dca:	ec26                	sd	s1,24(sp)
    80002dcc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dce:	fdc40593          	addi	a1,s0,-36
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	e78080e7          	jalr	-392(ra) # 80002c4c <argint>
    80002ddc:	87aa                	mv	a5,a0
    return -1;
    80002dde:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002de0:	0207c063          	bltz	a5,80002e00 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	d6c080e7          	jalr	-660(ra) # 80001b50 <myproc>
    80002dec:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dee:	fdc42503          	lw	a0,-36(s0)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	0ec080e7          	jalr	236(ra) # 80001ede <growproc>
    80002dfa:	00054863          	bltz	a0,80002e0a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dfe:	8526                	mv	a0,s1
}
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6145                	addi	sp,sp,48
    80002e08:	8082                	ret
    return -1;
    80002e0a:	557d                	li	a0,-1
    80002e0c:	bfd5                	j	80002e00 <sys_sbrk+0x3c>

0000000080002e0e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0e:	7139                	addi	sp,sp,-64
    80002e10:	fc06                	sd	ra,56(sp)
    80002e12:	f822                	sd	s0,48(sp)
    80002e14:	f426                	sd	s1,40(sp)
    80002e16:	f04a                	sd	s2,32(sp)
    80002e18:	ec4e                	sd	s3,24(sp)
    80002e1a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e1c:	fcc40593          	addi	a1,s0,-52
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	e2a080e7          	jalr	-470(ra) # 80002c4c <argint>
    return -1;
    80002e2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e2c:	06054563          	bltz	a0,80002e96 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e30:	0001b517          	auipc	a0,0x1b
    80002e34:	2a050513          	addi	a0,a0,672 # 8001e0d0 <tickslock>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	dac080e7          	jalr	-596(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002e40:	0000d917          	auipc	s2,0xd
    80002e44:	1f092903          	lw	s2,496(s2) # 80010030 <ticks>
  while(ticks - ticks0 < n){
    80002e48:	fcc42783          	lw	a5,-52(s0)
    80002e4c:	cf85                	beqz	a5,80002e84 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e4e:	0001b997          	auipc	s3,0x1b
    80002e52:	28298993          	addi	s3,s3,642 # 8001e0d0 <tickslock>
    80002e56:	0000d497          	auipc	s1,0xd
    80002e5a:	1da48493          	addi	s1,s1,474 # 80010030 <ticks>
    if(myproc()->killed){
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	cf2080e7          	jalr	-782(ra) # 80001b50 <myproc>
    80002e66:	551c                	lw	a5,40(a0)
    80002e68:	ef9d                	bnez	a5,80002ea6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e6a:	85ce                	mv	a1,s3
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	3d2080e7          	jalr	978(ra) # 80002240 <sleep>
  while(ticks - ticks0 < n){
    80002e76:	409c                	lw	a5,0(s1)
    80002e78:	412787bb          	subw	a5,a5,s2
    80002e7c:	fcc42703          	lw	a4,-52(s0)
    80002e80:	fce7efe3          	bltu	a5,a4,80002e5e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e84:	0001b517          	auipc	a0,0x1b
    80002e88:	24c50513          	addi	a0,a0,588 # 8001e0d0 <tickslock>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
  return 0;
    80002e94:	4781                	li	a5,0
}
    80002e96:	853e                	mv	a0,a5
    80002e98:	70e2                	ld	ra,56(sp)
    80002e9a:	7442                	ld	s0,48(sp)
    80002e9c:	74a2                	ld	s1,40(sp)
    80002e9e:	7902                	ld	s2,32(sp)
    80002ea0:	69e2                	ld	s3,24(sp)
    80002ea2:	6121                	addi	sp,sp,64
    80002ea4:	8082                	ret
      release(&tickslock);
    80002ea6:	0001b517          	auipc	a0,0x1b
    80002eaa:	22a50513          	addi	a0,a0,554 # 8001e0d0 <tickslock>
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
      return -1;
    80002eb6:	57fd                	li	a5,-1
    80002eb8:	bff9                	j	80002e96 <sys_sleep+0x88>

0000000080002eba <sys_kill>:

uint64
sys_kill(void)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ec2:	fec40593          	addi	a1,s0,-20
    80002ec6:	4501                	li	a0,0
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	d84080e7          	jalr	-636(ra) # 80002c4c <argint>
    80002ed0:	87aa                	mv	a5,a0
    return -1;
    80002ed2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ed4:	0007c863          	bltz	a5,80002ee4 <sys_kill+0x2a>
  return kill(pid);
    80002ed8:	fec42503          	lw	a0,-20(s0)
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	696080e7          	jalr	1686(ra) # 80002572 <kill>
}
    80002ee4:	60e2                	ld	ra,24(sp)
    80002ee6:	6442                	ld	s0,16(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret

0000000080002eec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eec:	1101                	addi	sp,sp,-32
    80002eee:	ec06                	sd	ra,24(sp)
    80002ef0:	e822                	sd	s0,16(sp)
    80002ef2:	e426                	sd	s1,8(sp)
    80002ef4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ef6:	0001b517          	auipc	a0,0x1b
    80002efa:	1da50513          	addi	a0,a0,474 # 8001e0d0 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	ce6080e7          	jalr	-794(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002f06:	0000d497          	auipc	s1,0xd
    80002f0a:	12a4a483          	lw	s1,298(s1) # 80010030 <ticks>
  release(&tickslock);
    80002f0e:	0001b517          	auipc	a0,0x1b
    80002f12:	1c250513          	addi	a0,a0,450 # 8001e0d0 <tickslock>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	d82080e7          	jalr	-638(ra) # 80000c98 <release>
  return xticks;
}
    80002f1e:	02049513          	slli	a0,s1,0x20
    80002f22:	9101                	srli	a0,a0,0x20
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f2e:	7179                	addi	sp,sp,-48
    80002f30:	f406                	sd	ra,40(sp)
    80002f32:	f022                	sd	s0,32(sp)
    80002f34:	ec26                	sd	s1,24(sp)
    80002f36:	e84a                	sd	s2,16(sp)
    80002f38:	e44e                	sd	s3,8(sp)
    80002f3a:	e052                	sd	s4,0(sp)
    80002f3c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f3e:	0000a597          	auipc	a1,0xa
    80002f42:	84258593          	addi	a1,a1,-1982 # 8000c780 <syscalls+0xb8>
    80002f46:	0001b517          	auipc	a0,0x1b
    80002f4a:	1a250513          	addi	a0,a0,418 # 8001e0e8 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	c06080e7          	jalr	-1018(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f56:	00023797          	auipc	a5,0x23
    80002f5a:	19278793          	addi	a5,a5,402 # 800260e8 <bcache+0x8000>
    80002f5e:	00023717          	auipc	a4,0x23
    80002f62:	3f270713          	addi	a4,a4,1010 # 80026350 <bcache+0x8268>
    80002f66:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f6a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f6e:	0001b497          	auipc	s1,0x1b
    80002f72:	19248493          	addi	s1,s1,402 # 8001e100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f76:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f78:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f7a:	0000aa17          	auipc	s4,0xa
    80002f7e:	80ea0a13          	addi	s4,s4,-2034 # 8000c788 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f82:	2b893783          	ld	a5,696(s2)
    80002f86:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f88:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f8c:	85d2                	mv	a1,s4
    80002f8e:	01048513          	addi	a0,s1,16
    80002f92:	00001097          	auipc	ra,0x1
    80002f96:	4ce080e7          	jalr	1230(ra) # 80004460 <initsleeplock>
    bcache.head.next->prev = b;
    80002f9a:	2b893783          	ld	a5,696(s2)
    80002f9e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fa0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fa4:	45848493          	addi	s1,s1,1112
    80002fa8:	fd349de3          	bne	s1,s3,80002f82 <binit+0x54>
  }
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6942                	ld	s2,16(sp)
    80002fb4:	69a2                	ld	s3,8(sp)
    80002fb6:	6a02                	ld	s4,0(sp)
    80002fb8:	6145                	addi	sp,sp,48
    80002fba:	8082                	ret

0000000080002fbc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fbc:	7179                	addi	sp,sp,-48
    80002fbe:	f406                	sd	ra,40(sp)
    80002fc0:	f022                	sd	s0,32(sp)
    80002fc2:	ec26                	sd	s1,24(sp)
    80002fc4:	e84a                	sd	s2,16(sp)
    80002fc6:	e44e                	sd	s3,8(sp)
    80002fc8:	1800                	addi	s0,sp,48
    80002fca:	89aa                	mv	s3,a0
    80002fcc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fce:	0001b517          	auipc	a0,0x1b
    80002fd2:	11a50513          	addi	a0,a0,282 # 8001e0e8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c0e080e7          	jalr	-1010(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fde:	00023497          	auipc	s1,0x23
    80002fe2:	3c24b483          	ld	s1,962(s1) # 800263a0 <bcache+0x82b8>
    80002fe6:	00023797          	auipc	a5,0x23
    80002fea:	36a78793          	addi	a5,a5,874 # 80026350 <bcache+0x8268>
    80002fee:	02f48f63          	beq	s1,a5,8000302c <bread+0x70>
    80002ff2:	873e                	mv	a4,a5
    80002ff4:	a021                	j	80002ffc <bread+0x40>
    80002ff6:	68a4                	ld	s1,80(s1)
    80002ff8:	02e48a63          	beq	s1,a4,8000302c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ffc:	449c                	lw	a5,8(s1)
    80002ffe:	ff379ce3          	bne	a5,s3,80002ff6 <bread+0x3a>
    80003002:	44dc                	lw	a5,12(s1)
    80003004:	ff2799e3          	bne	a5,s2,80002ff6 <bread+0x3a>
      b->refcnt++;
    80003008:	40bc                	lw	a5,64(s1)
    8000300a:	2785                	addiw	a5,a5,1
    8000300c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300e:	0001b517          	auipc	a0,0x1b
    80003012:	0da50513          	addi	a0,a0,218 # 8001e0e8 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	c82080e7          	jalr	-894(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000301e:	01048513          	addi	a0,s1,16
    80003022:	00001097          	auipc	ra,0x1
    80003026:	478080e7          	jalr	1144(ra) # 8000449a <acquiresleep>
      return b;
    8000302a:	a8b9                	j	80003088 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302c:	00023497          	auipc	s1,0x23
    80003030:	36c4b483          	ld	s1,876(s1) # 80026398 <bcache+0x82b0>
    80003034:	00023797          	auipc	a5,0x23
    80003038:	31c78793          	addi	a5,a5,796 # 80026350 <bcache+0x8268>
    8000303c:	00f48863          	beq	s1,a5,8000304c <bread+0x90>
    80003040:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003042:	40bc                	lw	a5,64(s1)
    80003044:	cf81                	beqz	a5,8000305c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003046:	64a4                	ld	s1,72(s1)
    80003048:	fee49de3          	bne	s1,a4,80003042 <bread+0x86>
  panic("bget: no buffers");
    8000304c:	00009517          	auipc	a0,0x9
    80003050:	74450513          	addi	a0,a0,1860 # 8000c790 <syscalls+0xc8>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	4ea080e7          	jalr	1258(ra) # 8000053e <panic>
      b->dev = dev;
    8000305c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003060:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003064:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003068:	4785                	li	a5,1
    8000306a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306c:	0001b517          	auipc	a0,0x1b
    80003070:	07c50513          	addi	a0,a0,124 # 8001e0e8 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c24080e7          	jalr	-988(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000307c:	01048513          	addi	a0,s1,16
    80003080:	00001097          	auipc	ra,0x1
    80003084:	41a080e7          	jalr	1050(ra) # 8000449a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003088:	409c                	lw	a5,0(s1)
    8000308a:	cb89                	beqz	a5,8000309c <bread+0xe0>
    virtio_disk_rw(b, 0);

    b->valid = 1;
  }
  return b;
}
    8000308c:	8526                	mv	a0,s1
    8000308e:	70a2                	ld	ra,40(sp)
    80003090:	7402                	ld	s0,32(sp)
    80003092:	64e2                	ld	s1,24(sp)
    80003094:	6942                	ld	s2,16(sp)
    80003096:	69a2                	ld	s3,8(sp)
    80003098:	6145                	addi	sp,sp,48
    8000309a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000309c:	4581                	li	a1,0
    8000309e:	8526                	mv	a0,s1
    800030a0:	00003097          	auipc	ra,0x3
    800030a4:	f76080e7          	jalr	-138(ra) # 80006016 <virtio_disk_rw>
    b->valid = 1;
    800030a8:	4785                	li	a5,1
    800030aa:	c09c                	sw	a5,0(s1)
  return b;
    800030ac:	b7c5                	j	8000308c <bread+0xd0>

00000000800030ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	1000                	addi	s0,sp,32
    800030b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ba:	0541                	addi	a0,a0,16
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	478080e7          	jalr	1144(ra) # 80004534 <holdingsleep>
    800030c4:	cd01                	beqz	a0,800030dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c6:	4585                	li	a1,1
    800030c8:	8526                	mv	a0,s1
    800030ca:	00003097          	auipc	ra,0x3
    800030ce:	f4c080e7          	jalr	-180(ra) # 80006016 <virtio_disk_rw>
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("bwrite");
    800030dc:	00009517          	auipc	a0,0x9
    800030e0:	6cc50513          	addi	a0,a0,1740 # 8000c7a8 <syscalls+0xe0>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	45a080e7          	jalr	1114(ra) # 8000053e <panic>

00000000800030ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	e04a                	sd	s2,0(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030fa:	01050913          	addi	s2,a0,16
    800030fe:	854a                	mv	a0,s2
    80003100:	00001097          	auipc	ra,0x1
    80003104:	434080e7          	jalr	1076(ra) # 80004534 <holdingsleep>
    80003108:	c92d                	beqz	a0,8000317a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000310a:	854a                	mv	a0,s2
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	3e4080e7          	jalr	996(ra) # 800044f0 <releasesleep>

  acquire(&bcache.lock);
    80003114:	0001b517          	auipc	a0,0x1b
    80003118:	fd450513          	addi	a0,a0,-44 # 8001e0e8 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	ac8080e7          	jalr	-1336(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	37fd                	addiw	a5,a5,-1
    80003128:	0007871b          	sext.w	a4,a5
    8000312c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000312e:	eb05                	bnez	a4,8000315e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003130:	68bc                	ld	a5,80(s1)
    80003132:	64b8                	ld	a4,72(s1)
    80003134:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003136:	64bc                	ld	a5,72(s1)
    80003138:	68b8                	ld	a4,80(s1)
    8000313a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000313c:	00023797          	auipc	a5,0x23
    80003140:	fac78793          	addi	a5,a5,-84 # 800260e8 <bcache+0x8000>
    80003144:	2b87b703          	ld	a4,696(a5)
    80003148:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000314a:	00023717          	auipc	a4,0x23
    8000314e:	20670713          	addi	a4,a4,518 # 80026350 <bcache+0x8268>
    80003152:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003154:	2b87b703          	ld	a4,696(a5)
    80003158:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000315a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000315e:	0001b517          	auipc	a0,0x1b
    80003162:	f8a50513          	addi	a0,a0,-118 # 8001e0e8 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b32080e7          	jalr	-1230(ra) # 80000c98 <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6902                	ld	s2,0(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret
    panic("brelse");
    8000317a:	00009517          	auipc	a0,0x9
    8000317e:	63650513          	addi	a0,a0,1590 # 8000c7b0 <syscalls+0xe8>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3bc080e7          	jalr	956(ra) # 8000053e <panic>

000000008000318a <bpin>:

void
bpin(struct buf *b) {
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003196:	0001b517          	auipc	a0,0x1b
    8000319a:	f5250513          	addi	a0,a0,-174 # 8001e0e8 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
  b->refcnt++;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ac:	0001b517          	auipc	a0,0x1b
    800031b0:	f3c50513          	addi	a0,a0,-196 # 8001e0e8 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <bunpin>:

void
bunpin(struct buf *b) {
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d2:	0001b517          	auipc	a0,0x1b
    800031d6:	f1650513          	addi	a0,a0,-234 # 8001e0e8 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	a0a080e7          	jalr	-1526(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031e2:	40bc                	lw	a5,64(s1)
    800031e4:	37fd                	addiw	a5,a5,-1
    800031e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e8:	0001b517          	auipc	a0,0x1b
    800031ec:	f0050513          	addi	a0,a0,-256 # 8001e0e8 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	aa8080e7          	jalr	-1368(ra) # 80000c98 <release>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	e04a                	sd	s2,0(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003210:	00d5d59b          	srliw	a1,a1,0xd
    80003214:	00023797          	auipc	a5,0x23
    80003218:	5b07a783          	lw	a5,1456(a5) # 800267c4 <sb+0x1c>
    8000321c:	9dbd                	addw	a1,a1,a5
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	d9e080e7          	jalr	-610(ra) # 80002fbc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003226:	0074f713          	andi	a4,s1,7
    8000322a:	4785                	li	a5,1
    8000322c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003230:	14ce                	slli	s1,s1,0x33
    80003232:	90d9                	srli	s1,s1,0x36
    80003234:	00950733          	add	a4,a0,s1
    80003238:	05874703          	lbu	a4,88(a4)
    8000323c:	00e7f6b3          	and	a3,a5,a4
    80003240:	c69d                	beqz	a3,8000326e <bfree+0x6c>
    80003242:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003244:	94aa                	add	s1,s1,a0
    80003246:	fff7c793          	not	a5,a5
    8000324a:	8ff9                	and	a5,a5,a4
    8000324c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003250:	00001097          	auipc	ra,0x1
    80003254:	12a080e7          	jalr	298(ra) # 8000437a <log_write>
  brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	e92080e7          	jalr	-366(ra) # 800030ec <brelse>
}
    80003262:	60e2                	ld	ra,24(sp)
    80003264:	6442                	ld	s0,16(sp)
    80003266:	64a2                	ld	s1,8(sp)
    80003268:	6902                	ld	s2,0(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret
    panic("freeing free block");
    8000326e:	00009517          	auipc	a0,0x9
    80003272:	54a50513          	addi	a0,a0,1354 # 8000c7b8 <syscalls+0xf0>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000327e <balloc>:
{
    8000327e:	711d                	addi	sp,sp,-96
    80003280:	ec86                	sd	ra,88(sp)
    80003282:	e8a2                	sd	s0,80(sp)
    80003284:	e4a6                	sd	s1,72(sp)
    80003286:	e0ca                	sd	s2,64(sp)
    80003288:	fc4e                	sd	s3,56(sp)
    8000328a:	f852                	sd	s4,48(sp)
    8000328c:	f456                	sd	s5,40(sp)
    8000328e:	f05a                	sd	s6,32(sp)
    80003290:	ec5e                	sd	s7,24(sp)
    80003292:	e862                	sd	s8,16(sp)
    80003294:	e466                	sd	s9,8(sp)
    80003296:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003298:	00023797          	auipc	a5,0x23
    8000329c:	5147a783          	lw	a5,1300(a5) # 800267ac <sb+0x4>
    800032a0:	cbd1                	beqz	a5,80003334 <balloc+0xb6>
    800032a2:	8baa                	mv	s7,a0
    800032a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a6:	00023b17          	auipc	s6,0x23
    800032aa:	502b0b13          	addi	s6,s6,1282 # 800267a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b4:	6c89                	lui	s9,0x2
    800032b6:	a831                	j	800032d2 <balloc+0x54>
    brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	e32080e7          	jalr	-462(ra) # 800030ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	015c87bb          	addw	a5,s9,s5
    800032c6:	00078a9b          	sext.w	s5,a5
    800032ca:	004b2703          	lw	a4,4(s6)
    800032ce:	06eaf363          	bgeu	s5,a4,80003334 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032d2:	41fad79b          	sraiw	a5,s5,0x1f
    800032d6:	0137d79b          	srliw	a5,a5,0x13
    800032da:	015787bb          	addw	a5,a5,s5
    800032de:	40d7d79b          	sraiw	a5,a5,0xd
    800032e2:	01cb2583          	lw	a1,28(s6)
    800032e6:	9dbd                	addw	a1,a1,a5
    800032e8:	855e                	mv	a0,s7
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	cd2080e7          	jalr	-814(ra) # 80002fbc <bread>
    800032f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f4:	004b2503          	lw	a0,4(s6)
    800032f8:	000a849b          	sext.w	s1,s5
    800032fc:	8662                	mv	a2,s8
    800032fe:	faa4fde3          	bgeu	s1,a0,800032b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003302:	41f6579b          	sraiw	a5,a2,0x1f
    80003306:	01d7d69b          	srliw	a3,a5,0x1d
    8000330a:	00c6873b          	addw	a4,a3,a2
    8000330e:	00777793          	andi	a5,a4,7
    80003312:	9f95                	subw	a5,a5,a3
    80003314:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003318:	4037571b          	sraiw	a4,a4,0x3
    8000331c:	00e906b3          	add	a3,s2,a4
    80003320:	0586c683          	lbu	a3,88(a3)
    80003324:	00d7f5b3          	and	a1,a5,a3
    80003328:	cd91                	beqz	a1,80003344 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332a:	2605                	addiw	a2,a2,1
    8000332c:	2485                	addiw	s1,s1,1
    8000332e:	fd4618e3          	bne	a2,s4,800032fe <balloc+0x80>
    80003332:	b759                	j	800032b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003334:	00009517          	auipc	a0,0x9
    80003338:	49c50513          	addi	a0,a0,1180 # 8000c7d0 <syscalls+0x108>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	202080e7          	jalr	514(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003344:	974a                	add	a4,a4,s2
    80003346:	8fd5                	or	a5,a5,a3
    80003348:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	02c080e7          	jalr	44(ra) # 8000437a <log_write>
        brelse(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	d94080e7          	jalr	-620(ra) # 800030ec <brelse>
  bp = bread(dev, bno);
    80003360:	85a6                	mv	a1,s1
    80003362:	855e                	mv	a0,s7
    80003364:	00000097          	auipc	ra,0x0
    80003368:	c58080e7          	jalr	-936(ra) # 80002fbc <bread>
    8000336c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000336e:	40000613          	li	a2,1024
    80003372:	4581                	li	a1,0
    80003374:	05850513          	addi	a0,a0,88
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	968080e7          	jalr	-1688(ra) # 80000ce0 <memset>
  log_write(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00001097          	auipc	ra,0x1
    80003386:	ff8080e7          	jalr	-8(ra) # 8000437a <log_write>
  brelse(bp);
    8000338a:	854a                	mv	a0,s2
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	d60080e7          	jalr	-672(ra) # 800030ec <brelse>
}
    80003394:	8526                	mv	a0,s1
    80003396:	60e6                	ld	ra,88(sp)
    80003398:	6446                	ld	s0,80(sp)
    8000339a:	64a6                	ld	s1,72(sp)
    8000339c:	6906                	ld	s2,64(sp)
    8000339e:	79e2                	ld	s3,56(sp)
    800033a0:	7a42                	ld	s4,48(sp)
    800033a2:	7aa2                	ld	s5,40(sp)
    800033a4:	7b02                	ld	s6,32(sp)
    800033a6:	6be2                	ld	s7,24(sp)
    800033a8:	6c42                	ld	s8,16(sp)
    800033aa:	6ca2                	ld	s9,8(sp)
    800033ac:	6125                	addi	sp,sp,96
    800033ae:	8082                	ret

00000000800033b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033b0:	7179                	addi	sp,sp,-48
    800033b2:	f406                	sd	ra,40(sp)
    800033b4:	f022                	sd	s0,32(sp)
    800033b6:	ec26                	sd	s1,24(sp)
    800033b8:	e84a                	sd	s2,16(sp)
    800033ba:	e44e                	sd	s3,8(sp)
    800033bc:	e052                	sd	s4,0(sp)
    800033be:	1800                	addi	s0,sp,48
    800033c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c2:	47ad                	li	a5,11
    800033c4:	04b7fe63          	bgeu	a5,a1,80003420 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c8:	ff45849b          	addiw	s1,a1,-12
    800033cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d0:	0ff00793          	li	a5,255
    800033d4:	0ae7e363          	bltu	a5,a4,8000347a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d8:	08052583          	lw	a1,128(a0)
    800033dc:	c5ad                	beqz	a1,80003446 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033de:	00092503          	lw	a0,0(s2)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	bda080e7          	jalr	-1062(ra) # 80002fbc <bread>
    800033ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033f0:	02049593          	slli	a1,s1,0x20
    800033f4:	9181                	srli	a1,a1,0x20
    800033f6:	058a                	slli	a1,a1,0x2
    800033f8:	00b784b3          	add	s1,a5,a1
    800033fc:	0004a983          	lw	s3,0(s1)
    80003400:	04098d63          	beqz	s3,8000345a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003404:	8552                	mv	a0,s4
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	ce6080e7          	jalr	-794(ra) # 800030ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000340e:	854e                	mv	a0,s3
    80003410:	70a2                	ld	ra,40(sp)
    80003412:	7402                	ld	s0,32(sp)
    80003414:	64e2                	ld	s1,24(sp)
    80003416:	6942                	ld	s2,16(sp)
    80003418:	69a2                	ld	s3,8(sp)
    8000341a:	6a02                	ld	s4,0(sp)
    8000341c:	6145                	addi	sp,sp,48
    8000341e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003420:	02059493          	slli	s1,a1,0x20
    80003424:	9081                	srli	s1,s1,0x20
    80003426:	048a                	slli	s1,s1,0x2
    80003428:	94aa                	add	s1,s1,a0
    8000342a:	0504a983          	lw	s3,80(s1)
    8000342e:	fe0990e3          	bnez	s3,8000340e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003432:	4108                	lw	a0,0(a0)
    80003434:	00000097          	auipc	ra,0x0
    80003438:	e4a080e7          	jalr	-438(ra) # 8000327e <balloc>
    8000343c:	0005099b          	sext.w	s3,a0
    80003440:	0534a823          	sw	s3,80(s1)
    80003444:	b7e9                	j	8000340e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003446:	4108                	lw	a0,0(a0)
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	e36080e7          	jalr	-458(ra) # 8000327e <balloc>
    80003450:	0005059b          	sext.w	a1,a0
    80003454:	08b92023          	sw	a1,128(s2)
    80003458:	b759                	j	800033de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000345a:	00092503          	lw	a0,0(s2)
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	e20080e7          	jalr	-480(ra) # 8000327e <balloc>
    80003466:	0005099b          	sext.w	s3,a0
    8000346a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000346e:	8552                	mv	a0,s4
    80003470:	00001097          	auipc	ra,0x1
    80003474:	f0a080e7          	jalr	-246(ra) # 8000437a <log_write>
    80003478:	b771                	j	80003404 <bmap+0x54>
  panic("bmap: out of range");
    8000347a:	00009517          	auipc	a0,0x9
    8000347e:	36e50513          	addi	a0,a0,878 # 8000c7e8 <syscalls+0x120>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0bc080e7          	jalr	188(ra) # 8000053e <panic>

000000008000348a <iget>:
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	e052                	sd	s4,0(sp)
    80003498:	1800                	addi	s0,sp,48
    8000349a:	89aa                	mv	s3,a0
    8000349c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000349e:	00023517          	auipc	a0,0x23
    800034a2:	32a50513          	addi	a0,a0,810 # 800267c8 <itable>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	73e080e7          	jalr	1854(ra) # 80000be4 <acquire>
  empty = 0;
    800034ae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b0:	00023497          	auipc	s1,0x23
    800034b4:	33048493          	addi	s1,s1,816 # 800267e0 <itable+0x18>
    800034b8:	00025697          	auipc	a3,0x25
    800034bc:	db868693          	addi	a3,a3,-584 # 80028270 <log>
    800034c0:	a039                	j	800034ce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c2:	02090b63          	beqz	s2,800034f8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034c6:	08848493          	addi	s1,s1,136
    800034ca:	02d48a63          	beq	s1,a3,800034fe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ce:	449c                	lw	a5,8(s1)
    800034d0:	fef059e3          	blez	a5,800034c2 <iget+0x38>
    800034d4:	4098                	lw	a4,0(s1)
    800034d6:	ff3716e3          	bne	a4,s3,800034c2 <iget+0x38>
    800034da:	40d8                	lw	a4,4(s1)
    800034dc:	ff4713e3          	bne	a4,s4,800034c2 <iget+0x38>
      ip->ref++;
    800034e0:	2785                	addiw	a5,a5,1
    800034e2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034e4:	00023517          	auipc	a0,0x23
    800034e8:	2e450513          	addi	a0,a0,740 # 800267c8 <itable>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	7ac080e7          	jalr	1964(ra) # 80000c98 <release>
      return ip;
    800034f4:	8926                	mv	s2,s1
    800034f6:	a03d                	j	80003524 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f8:	f7f9                	bnez	a5,800034c6 <iget+0x3c>
    800034fa:	8926                	mv	s2,s1
    800034fc:	b7e9                	j	800034c6 <iget+0x3c>
  if(empty == 0)
    800034fe:	02090c63          	beqz	s2,80003536 <iget+0xac>
  ip->dev = dev;
    80003502:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003506:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000350a:	4785                	li	a5,1
    8000350c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003510:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003514:	00023517          	auipc	a0,0x23
    80003518:	2b450513          	addi	a0,a0,692 # 800267c8 <itable>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	77c080e7          	jalr	1916(ra) # 80000c98 <release>
}
    80003524:	854a                	mv	a0,s2
    80003526:	70a2                	ld	ra,40(sp)
    80003528:	7402                	ld	s0,32(sp)
    8000352a:	64e2                	ld	s1,24(sp)
    8000352c:	6942                	ld	s2,16(sp)
    8000352e:	69a2                	ld	s3,8(sp)
    80003530:	6a02                	ld	s4,0(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    panic("iget: no inodes");
    80003536:	00009517          	auipc	a0,0x9
    8000353a:	2ca50513          	addi	a0,a0,714 # 8000c800 <syscalls+0x138>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	000080e7          	jalr	ra # 8000053e <panic>

0000000080003546 <fsinit>:
fsinit(int dev) {
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	1800                	addi	s0,sp,48
    80003554:	892a                	mv	s2,a0
  printf("fsinit \n");
    80003556:	00009517          	auipc	a0,0x9
    8000355a:	2ba50513          	addi	a0,a0,698 # 8000c810 <syscalls+0x148>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	02a080e7          	jalr	42(ra) # 80000588 <printf>
  bp = bread(dev, 1);
    80003566:	4585                	li	a1,1
    80003568:	854a                	mv	a0,s2
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	a52080e7          	jalr	-1454(ra) # 80002fbc <bread>
    80003572:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003574:	00023997          	auipc	s3,0x23
    80003578:	23498993          	addi	s3,s3,564 # 800267a8 <sb>
    8000357c:	02000613          	li	a2,32
    80003580:	05850593          	addi	a1,a0,88
    80003584:	854e                	mv	a0,s3
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	7ba080e7          	jalr	1978(ra) # 80000d40 <memmove>
  brelse(bp);
    8000358e:	8526                	mv	a0,s1
    80003590:	00000097          	auipc	ra,0x0
    80003594:	b5c080e7          	jalr	-1188(ra) # 800030ec <brelse>
  if(sb.magic != FSMAGIC)
    80003598:	0009a703          	lw	a4,0(s3)
    8000359c:	102037b7          	lui	a5,0x10203
    800035a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035a4:	02f71263          	bne	a4,a5,800035c8 <fsinit+0x82>
  initlog(dev, &sb);
    800035a8:	00023597          	auipc	a1,0x23
    800035ac:	20058593          	addi	a1,a1,512 # 800267a8 <sb>
    800035b0:	854a                	mv	a0,s2
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	b4c080e7          	jalr	-1204(ra) # 800040fe <initlog>
}
    800035ba:	70a2                	ld	ra,40(sp)
    800035bc:	7402                	ld	s0,32(sp)
    800035be:	64e2                	ld	s1,24(sp)
    800035c0:	6942                	ld	s2,16(sp)
    800035c2:	69a2                	ld	s3,8(sp)
    800035c4:	6145                	addi	sp,sp,48
    800035c6:	8082                	ret
    panic("invalid file system");
    800035c8:	00009517          	auipc	a0,0x9
    800035cc:	25850513          	addi	a0,a0,600 # 8000c820 <syscalls+0x158>
    800035d0:	ffffd097          	auipc	ra,0xffffd
    800035d4:	f6e080e7          	jalr	-146(ra) # 8000053e <panic>

00000000800035d8 <iinit>:
{
    800035d8:	7179                	addi	sp,sp,-48
    800035da:	f406                	sd	ra,40(sp)
    800035dc:	f022                	sd	s0,32(sp)
    800035de:	ec26                	sd	s1,24(sp)
    800035e0:	e84a                	sd	s2,16(sp)
    800035e2:	e44e                	sd	s3,8(sp)
    800035e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035e6:	00009597          	auipc	a1,0x9
    800035ea:	25258593          	addi	a1,a1,594 # 8000c838 <syscalls+0x170>
    800035ee:	00023517          	auipc	a0,0x23
    800035f2:	1da50513          	addi	a0,a0,474 # 800267c8 <itable>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	55e080e7          	jalr	1374(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035fe:	00023497          	auipc	s1,0x23
    80003602:	1f248493          	addi	s1,s1,498 # 800267f0 <itable+0x28>
    80003606:	00025997          	auipc	s3,0x25
    8000360a:	c7a98993          	addi	s3,s3,-902 # 80028280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000360e:	00009917          	auipc	s2,0x9
    80003612:	23290913          	addi	s2,s2,562 # 8000c840 <syscalls+0x178>
    80003616:	85ca                	mv	a1,s2
    80003618:	8526                	mv	a0,s1
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	e46080e7          	jalr	-442(ra) # 80004460 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003622:	08848493          	addi	s1,s1,136
    80003626:	ff3498e3          	bne	s1,s3,80003616 <iinit+0x3e>
}
    8000362a:	70a2                	ld	ra,40(sp)
    8000362c:	7402                	ld	s0,32(sp)
    8000362e:	64e2                	ld	s1,24(sp)
    80003630:	6942                	ld	s2,16(sp)
    80003632:	69a2                	ld	s3,8(sp)
    80003634:	6145                	addi	sp,sp,48
    80003636:	8082                	ret

0000000080003638 <ialloc>:
{
    80003638:	715d                	addi	sp,sp,-80
    8000363a:	e486                	sd	ra,72(sp)
    8000363c:	e0a2                	sd	s0,64(sp)
    8000363e:	fc26                	sd	s1,56(sp)
    80003640:	f84a                	sd	s2,48(sp)
    80003642:	f44e                	sd	s3,40(sp)
    80003644:	f052                	sd	s4,32(sp)
    80003646:	ec56                	sd	s5,24(sp)
    80003648:	e85a                	sd	s6,16(sp)
    8000364a:	e45e                	sd	s7,8(sp)
    8000364c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364e:	00023717          	auipc	a4,0x23
    80003652:	16672703          	lw	a4,358(a4) # 800267b4 <sb+0xc>
    80003656:	4785                	li	a5,1
    80003658:	04e7fa63          	bgeu	a5,a4,800036ac <ialloc+0x74>
    8000365c:	8aaa                	mv	s5,a0
    8000365e:	8bae                	mv	s7,a1
    80003660:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003662:	00023a17          	auipc	s4,0x23
    80003666:	146a0a13          	addi	s4,s4,326 # 800267a8 <sb>
    8000366a:	00048b1b          	sext.w	s6,s1
    8000366e:	0044d593          	srli	a1,s1,0x4
    80003672:	018a2783          	lw	a5,24(s4)
    80003676:	9dbd                	addw	a1,a1,a5
    80003678:	8556                	mv	a0,s5
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	942080e7          	jalr	-1726(ra) # 80002fbc <bread>
    80003682:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003684:	05850993          	addi	s3,a0,88
    80003688:	00f4f793          	andi	a5,s1,15
    8000368c:	079a                	slli	a5,a5,0x6
    8000368e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003690:	00099783          	lh	a5,0(s3)
    80003694:	c785                	beqz	a5,800036bc <ialloc+0x84>
    brelse(bp);
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	a56080e7          	jalr	-1450(ra) # 800030ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000369e:	0485                	addi	s1,s1,1
    800036a0:	00ca2703          	lw	a4,12(s4)
    800036a4:	0004879b          	sext.w	a5,s1
    800036a8:	fce7e1e3          	bltu	a5,a4,8000366a <ialloc+0x32>
  panic("ialloc: no inodes");
    800036ac:	00009517          	auipc	a0,0x9
    800036b0:	19c50513          	addi	a0,a0,412 # 8000c848 <syscalls+0x180>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	e8a080e7          	jalr	-374(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800036bc:	04000613          	li	a2,64
    800036c0:	4581                	li	a1,0
    800036c2:	854e                	mv	a0,s3
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	61c080e7          	jalr	1564(ra) # 80000ce0 <memset>
      dip->type = type;
    800036cc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	ca8080e7          	jalr	-856(ra) # 8000437a <log_write>
      brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	a10080e7          	jalr	-1520(ra) # 800030ec <brelse>
      return iget(dev, inum);
    800036e4:	85da                	mv	a1,s6
    800036e6:	8556                	mv	a0,s5
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	da2080e7          	jalr	-606(ra) # 8000348a <iget>
}
    800036f0:	60a6                	ld	ra,72(sp)
    800036f2:	6406                	ld	s0,64(sp)
    800036f4:	74e2                	ld	s1,56(sp)
    800036f6:	7942                	ld	s2,48(sp)
    800036f8:	79a2                	ld	s3,40(sp)
    800036fa:	7a02                	ld	s4,32(sp)
    800036fc:	6ae2                	ld	s5,24(sp)
    800036fe:	6b42                	ld	s6,16(sp)
    80003700:	6ba2                	ld	s7,8(sp)
    80003702:	6161                	addi	sp,sp,80
    80003704:	8082                	ret

0000000080003706 <iupdate>:
{
    80003706:	1101                	addi	sp,sp,-32
    80003708:	ec06                	sd	ra,24(sp)
    8000370a:	e822                	sd	s0,16(sp)
    8000370c:	e426                	sd	s1,8(sp)
    8000370e:	e04a                	sd	s2,0(sp)
    80003710:	1000                	addi	s0,sp,32
    80003712:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003714:	415c                	lw	a5,4(a0)
    80003716:	0047d79b          	srliw	a5,a5,0x4
    8000371a:	00023597          	auipc	a1,0x23
    8000371e:	0a65a583          	lw	a1,166(a1) # 800267c0 <sb+0x18>
    80003722:	9dbd                	addw	a1,a1,a5
    80003724:	4108                	lw	a0,0(a0)
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	896080e7          	jalr	-1898(ra) # 80002fbc <bread>
    8000372e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003730:	05850793          	addi	a5,a0,88
    80003734:	40c8                	lw	a0,4(s1)
    80003736:	893d                	andi	a0,a0,15
    80003738:	051a                	slli	a0,a0,0x6
    8000373a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000373c:	04449703          	lh	a4,68(s1)
    80003740:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003744:	04649703          	lh	a4,70(s1)
    80003748:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000374c:	04849703          	lh	a4,72(s1)
    80003750:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003754:	04a49703          	lh	a4,74(s1)
    80003758:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000375c:	44f8                	lw	a4,76(s1)
    8000375e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003760:	03400613          	li	a2,52
    80003764:	05048593          	addi	a1,s1,80
    80003768:	0531                	addi	a0,a0,12
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	5d6080e7          	jalr	1494(ra) # 80000d40 <memmove>
  log_write(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00001097          	auipc	ra,0x1
    80003778:	c06080e7          	jalr	-1018(ra) # 8000437a <log_write>
  brelse(bp);
    8000377c:	854a                	mv	a0,s2
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	96e080e7          	jalr	-1682(ra) # 800030ec <brelse>
}
    80003786:	60e2                	ld	ra,24(sp)
    80003788:	6442                	ld	s0,16(sp)
    8000378a:	64a2                	ld	s1,8(sp)
    8000378c:	6902                	ld	s2,0(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <idup>:
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	1000                	addi	s0,sp,32
    8000379c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000379e:	00023517          	auipc	a0,0x23
    800037a2:	02a50513          	addi	a0,a0,42 # 800267c8 <itable>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	43e080e7          	jalr	1086(ra) # 80000be4 <acquire>
  ip->ref++;
    800037ae:	449c                	lw	a5,8(s1)
    800037b0:	2785                	addiw	a5,a5,1
    800037b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037b4:	00023517          	auipc	a0,0x23
    800037b8:	01450513          	addi	a0,a0,20 # 800267c8 <itable>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	4dc080e7          	jalr	1244(ra) # 80000c98 <release>
}
    800037c4:	8526                	mv	a0,s1
    800037c6:	60e2                	ld	ra,24(sp)
    800037c8:	6442                	ld	s0,16(sp)
    800037ca:	64a2                	ld	s1,8(sp)
    800037cc:	6105                	addi	sp,sp,32
    800037ce:	8082                	ret

00000000800037d0 <ilock>:
{
    800037d0:	1101                	addi	sp,sp,-32
    800037d2:	ec06                	sd	ra,24(sp)
    800037d4:	e822                	sd	s0,16(sp)
    800037d6:	e426                	sd	s1,8(sp)
    800037d8:	e04a                	sd	s2,0(sp)
    800037da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037dc:	c115                	beqz	a0,80003800 <ilock+0x30>
    800037de:	84aa                	mv	s1,a0
    800037e0:	451c                	lw	a5,8(a0)
    800037e2:	00f05f63          	blez	a5,80003800 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037e6:	0541                	addi	a0,a0,16
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	cb2080e7          	jalr	-846(ra) # 8000449a <acquiresleep>
  if(ip->valid == 0){
    800037f0:	40bc                	lw	a5,64(s1)
    800037f2:	cf99                	beqz	a5,80003810 <ilock+0x40>
}
    800037f4:	60e2                	ld	ra,24(sp)
    800037f6:	6442                	ld	s0,16(sp)
    800037f8:	64a2                	ld	s1,8(sp)
    800037fa:	6902                	ld	s2,0(sp)
    800037fc:	6105                	addi	sp,sp,32
    800037fe:	8082                	ret
    panic("ilock");
    80003800:	00009517          	auipc	a0,0x9
    80003804:	06050513          	addi	a0,a0,96 # 8000c860 <syscalls+0x198>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003810:	40dc                	lw	a5,4(s1)
    80003812:	0047d79b          	srliw	a5,a5,0x4
    80003816:	00023597          	auipc	a1,0x23
    8000381a:	faa5a583          	lw	a1,-86(a1) # 800267c0 <sb+0x18>
    8000381e:	9dbd                	addw	a1,a1,a5
    80003820:	4088                	lw	a0,0(s1)
    80003822:	fffff097          	auipc	ra,0xfffff
    80003826:	79a080e7          	jalr	1946(ra) # 80002fbc <bread>
    8000382a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382c:	05850593          	addi	a1,a0,88
    80003830:	40dc                	lw	a5,4(s1)
    80003832:	8bbd                	andi	a5,a5,15
    80003834:	079a                	slli	a5,a5,0x6
    80003836:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003838:	00059783          	lh	a5,0(a1)
    8000383c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003840:	00259783          	lh	a5,2(a1)
    80003844:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003848:	00459783          	lh	a5,4(a1)
    8000384c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003850:	00659783          	lh	a5,6(a1)
    80003854:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003858:	459c                	lw	a5,8(a1)
    8000385a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000385c:	03400613          	li	a2,52
    80003860:	05b1                	addi	a1,a1,12
    80003862:	05048513          	addi	a0,s1,80
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	4da080e7          	jalr	1242(ra) # 80000d40 <memmove>
    brelse(bp);
    8000386e:	854a                	mv	a0,s2
    80003870:	00000097          	auipc	ra,0x0
    80003874:	87c080e7          	jalr	-1924(ra) # 800030ec <brelse>
    ip->valid = 1;
    80003878:	4785                	li	a5,1
    8000387a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000387c:	04449783          	lh	a5,68(s1)
    80003880:	fbb5                	bnez	a5,800037f4 <ilock+0x24>
      panic("ilock: no type");
    80003882:	00009517          	auipc	a0,0x9
    80003886:	fe650513          	addi	a0,a0,-26 # 8000c868 <syscalls+0x1a0>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>

0000000080003892 <iunlock>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	e04a                	sd	s2,0(sp)
    8000389c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000389e:	c905                	beqz	a0,800038ce <iunlock+0x3c>
    800038a0:	84aa                	mv	s1,a0
    800038a2:	01050913          	addi	s2,a0,16
    800038a6:	854a                	mv	a0,s2
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	c8c080e7          	jalr	-884(ra) # 80004534 <holdingsleep>
    800038b0:	cd19                	beqz	a0,800038ce <iunlock+0x3c>
    800038b2:	449c                	lw	a5,8(s1)
    800038b4:	00f05d63          	blez	a5,800038ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	c36080e7          	jalr	-970(ra) # 800044f0 <releasesleep>
}
    800038c2:	60e2                	ld	ra,24(sp)
    800038c4:	6442                	ld	s0,16(sp)
    800038c6:	64a2                	ld	s1,8(sp)
    800038c8:	6902                	ld	s2,0(sp)
    800038ca:	6105                	addi	sp,sp,32
    800038cc:	8082                	ret
    panic("iunlock");
    800038ce:	00009517          	auipc	a0,0x9
    800038d2:	faa50513          	addi	a0,a0,-86 # 8000c878 <syscalls+0x1b0>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>

00000000800038de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038de:	7179                	addi	sp,sp,-48
    800038e0:	f406                	sd	ra,40(sp)
    800038e2:	f022                	sd	s0,32(sp)
    800038e4:	ec26                	sd	s1,24(sp)
    800038e6:	e84a                	sd	s2,16(sp)
    800038e8:	e44e                	sd	s3,8(sp)
    800038ea:	e052                	sd	s4,0(sp)
    800038ec:	1800                	addi	s0,sp,48
    800038ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038f0:	05050493          	addi	s1,a0,80
    800038f4:	08050913          	addi	s2,a0,128
    800038f8:	a021                	j	80003900 <itrunc+0x22>
    800038fa:	0491                	addi	s1,s1,4
    800038fc:	01248d63          	beq	s1,s2,80003916 <itrunc+0x38>
    if(ip->addrs[i]){
    80003900:	408c                	lw	a1,0(s1)
    80003902:	dde5                	beqz	a1,800038fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	8fa080e7          	jalr	-1798(ra) # 80003202 <bfree>
      ip->addrs[i] = 0;
    80003910:	0004a023          	sw	zero,0(s1)
    80003914:	b7dd                	j	800038fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003916:	0809a583          	lw	a1,128(s3)
    8000391a:	e185                	bnez	a1,8000393a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000391c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003920:	854e                	mv	a0,s3
    80003922:	00000097          	auipc	ra,0x0
    80003926:	de4080e7          	jalr	-540(ra) # 80003706 <iupdate>
}
    8000392a:	70a2                	ld	ra,40(sp)
    8000392c:	7402                	ld	s0,32(sp)
    8000392e:	64e2                	ld	s1,24(sp)
    80003930:	6942                	ld	s2,16(sp)
    80003932:	69a2                	ld	s3,8(sp)
    80003934:	6a02                	ld	s4,0(sp)
    80003936:	6145                	addi	sp,sp,48
    80003938:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	fffff097          	auipc	ra,0xfffff
    80003942:	67e080e7          	jalr	1662(ra) # 80002fbc <bread>
    80003946:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003948:	05850493          	addi	s1,a0,88
    8000394c:	45850913          	addi	s2,a0,1112
    80003950:	a811                	j	80003964 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003952:	0009a503          	lw	a0,0(s3)
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	8ac080e7          	jalr	-1876(ra) # 80003202 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000395e:	0491                	addi	s1,s1,4
    80003960:	01248563          	beq	s1,s2,8000396a <itrunc+0x8c>
      if(a[j])
    80003964:	408c                	lw	a1,0(s1)
    80003966:	dde5                	beqz	a1,8000395e <itrunc+0x80>
    80003968:	b7ed                	j	80003952 <itrunc+0x74>
    brelse(bp);
    8000396a:	8552                	mv	a0,s4
    8000396c:	fffff097          	auipc	ra,0xfffff
    80003970:	780080e7          	jalr	1920(ra) # 800030ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003974:	0809a583          	lw	a1,128(s3)
    80003978:	0009a503          	lw	a0,0(s3)
    8000397c:	00000097          	auipc	ra,0x0
    80003980:	886080e7          	jalr	-1914(ra) # 80003202 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003984:	0809a023          	sw	zero,128(s3)
    80003988:	bf51                	j	8000391c <itrunc+0x3e>

000000008000398a <iput>:
{
    8000398a:	1101                	addi	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	e426                	sd	s1,8(sp)
    80003992:	e04a                	sd	s2,0(sp)
    80003994:	1000                	addi	s0,sp,32
    80003996:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003998:	00023517          	auipc	a0,0x23
    8000399c:	e3050513          	addi	a0,a0,-464 # 800267c8 <itable>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	244080e7          	jalr	580(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039a8:	4498                	lw	a4,8(s1)
    800039aa:	4785                	li	a5,1
    800039ac:	02f70363          	beq	a4,a5,800039d2 <iput+0x48>
  ip->ref--;
    800039b0:	449c                	lw	a5,8(s1)
    800039b2:	37fd                	addiw	a5,a5,-1
    800039b4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b6:	00023517          	auipc	a0,0x23
    800039ba:	e1250513          	addi	a0,a0,-494 # 800267c8 <itable>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	2da080e7          	jalr	730(ra) # 80000c98 <release>
}
    800039c6:	60e2                	ld	ra,24(sp)
    800039c8:	6442                	ld	s0,16(sp)
    800039ca:	64a2                	ld	s1,8(sp)
    800039cc:	6902                	ld	s2,0(sp)
    800039ce:	6105                	addi	sp,sp,32
    800039d0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039d2:	40bc                	lw	a5,64(s1)
    800039d4:	dff1                	beqz	a5,800039b0 <iput+0x26>
    800039d6:	04a49783          	lh	a5,74(s1)
    800039da:	fbf9                	bnez	a5,800039b0 <iput+0x26>
    acquiresleep(&ip->lock);
    800039dc:	01048913          	addi	s2,s1,16
    800039e0:	854a                	mv	a0,s2
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	ab8080e7          	jalr	-1352(ra) # 8000449a <acquiresleep>
    release(&itable.lock);
    800039ea:	00023517          	auipc	a0,0x23
    800039ee:	dde50513          	addi	a0,a0,-546 # 800267c8 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	2a6080e7          	jalr	678(ra) # 80000c98 <release>
    itrunc(ip);
    800039fa:	8526                	mv	a0,s1
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	ee2080e7          	jalr	-286(ra) # 800038de <itrunc>
    ip->type = 0;
    80003a04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	cfc080e7          	jalr	-772(ra) # 80003706 <iupdate>
    ip->valid = 0;
    80003a12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	ad8080e7          	jalr	-1320(ra) # 800044f0 <releasesleep>
    acquire(&itable.lock);
    80003a20:	00023517          	auipc	a0,0x23
    80003a24:	da850513          	addi	a0,a0,-600 # 800267c8 <itable>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	1bc080e7          	jalr	444(ra) # 80000be4 <acquire>
    80003a30:	b741                	j	800039b0 <iput+0x26>

0000000080003a32 <iunlockput>:
{
    80003a32:	1101                	addi	sp,sp,-32
    80003a34:	ec06                	sd	ra,24(sp)
    80003a36:	e822                	sd	s0,16(sp)
    80003a38:	e426                	sd	s1,8(sp)
    80003a3a:	1000                	addi	s0,sp,32
    80003a3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	e54080e7          	jalr	-428(ra) # 80003892 <iunlock>
  iput(ip);
    80003a46:	8526                	mv	a0,s1
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	f42080e7          	jalr	-190(ra) # 8000398a <iput>
}
    80003a50:	60e2                	ld	ra,24(sp)
    80003a52:	6442                	ld	s0,16(sp)
    80003a54:	64a2                	ld	s1,8(sp)
    80003a56:	6105                	addi	sp,sp,32
    80003a58:	8082                	ret

0000000080003a5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a5a:	1141                	addi	sp,sp,-16
    80003a5c:	e422                	sd	s0,8(sp)
    80003a5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a60:	411c                	lw	a5,0(a0)
    80003a62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a64:	415c                	lw	a5,4(a0)
    80003a66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a68:	04451783          	lh	a5,68(a0)
    80003a6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a70:	04a51783          	lh	a5,74(a0)
    80003a74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a78:	04c56783          	lwu	a5,76(a0)
    80003a7c:	e99c                	sd	a5,16(a1)
}
    80003a7e:	6422                	ld	s0,8(sp)
    80003a80:	0141                	addi	sp,sp,16
    80003a82:	8082                	ret

0000000080003a84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a84:	457c                	lw	a5,76(a0)
    80003a86:	0ed7e963          	bltu	a5,a3,80003b78 <readi+0xf4>
{
    80003a8a:	7159                	addi	sp,sp,-112
    80003a8c:	f486                	sd	ra,104(sp)
    80003a8e:	f0a2                	sd	s0,96(sp)
    80003a90:	eca6                	sd	s1,88(sp)
    80003a92:	e8ca                	sd	s2,80(sp)
    80003a94:	e4ce                	sd	s3,72(sp)
    80003a96:	e0d2                	sd	s4,64(sp)
    80003a98:	fc56                	sd	s5,56(sp)
    80003a9a:	f85a                	sd	s6,48(sp)
    80003a9c:	f45e                	sd	s7,40(sp)
    80003a9e:	f062                	sd	s8,32(sp)
    80003aa0:	ec66                	sd	s9,24(sp)
    80003aa2:	e86a                	sd	s10,16(sp)
    80003aa4:	e46e                	sd	s11,8(sp)
    80003aa6:	1880                	addi	s0,sp,112
    80003aa8:	8baa                	mv	s7,a0
    80003aaa:	8c2e                	mv	s8,a1
    80003aac:	8ab2                	mv	s5,a2
    80003aae:	84b6                	mv	s1,a3
    80003ab0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ab2:	9f35                	addw	a4,a4,a3
    return 0;
    80003ab4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ab6:	0ad76063          	bltu	a4,a3,80003b56 <readi+0xd2>
  if(off + n > ip->size)
    80003aba:	00e7f463          	bgeu	a5,a4,80003ac2 <readi+0x3e>
    n = ip->size - off;
    80003abe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac2:	0a0b0963          	beqz	s6,80003b74 <readi+0xf0>
    80003ac6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003acc:	5cfd                	li	s9,-1
    80003ace:	a82d                	j	80003b08 <readi+0x84>
    80003ad0:	020a1d93          	slli	s11,s4,0x20
    80003ad4:	020ddd93          	srli	s11,s11,0x20
    80003ad8:	05890613          	addi	a2,s2,88
    80003adc:	86ee                	mv	a3,s11
    80003ade:	963a                	add	a2,a2,a4
    80003ae0:	85d6                	mv	a1,s5
    80003ae2:	8562                	mv	a0,s8
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	b00080e7          	jalr	-1280(ra) # 800025e4 <either_copyout>
    80003aec:	05950d63          	beq	a0,s9,80003b46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003af0:	854a                	mv	a0,s2
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	5fa080e7          	jalr	1530(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003afa:	013a09bb          	addw	s3,s4,s3
    80003afe:	009a04bb          	addw	s1,s4,s1
    80003b02:	9aee                	add	s5,s5,s11
    80003b04:	0569f763          	bgeu	s3,s6,80003b52 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b08:	000ba903          	lw	s2,0(s7)
    80003b0c:	00a4d59b          	srliw	a1,s1,0xa
    80003b10:	855e                	mv	a0,s7
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	89e080e7          	jalr	-1890(ra) # 800033b0 <bmap>
    80003b1a:	0005059b          	sext.w	a1,a0
    80003b1e:	854a                	mv	a0,s2
    80003b20:	fffff097          	auipc	ra,0xfffff
    80003b24:	49c080e7          	jalr	1180(ra) # 80002fbc <bread>
    80003b28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2a:	3ff4f713          	andi	a4,s1,1023
    80003b2e:	40ed07bb          	subw	a5,s10,a4
    80003b32:	413b06bb          	subw	a3,s6,s3
    80003b36:	8a3e                	mv	s4,a5
    80003b38:	2781                	sext.w	a5,a5
    80003b3a:	0006861b          	sext.w	a2,a3
    80003b3e:	f8f679e3          	bgeu	a2,a5,80003ad0 <readi+0x4c>
    80003b42:	8a36                	mv	s4,a3
    80003b44:	b771                	j	80003ad0 <readi+0x4c>
      brelse(bp);
    80003b46:	854a                	mv	a0,s2
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	5a4080e7          	jalr	1444(ra) # 800030ec <brelse>
      tot = -1;
    80003b50:	59fd                	li	s3,-1
  }
  return tot;
    80003b52:	0009851b          	sext.w	a0,s3
}
    80003b56:	70a6                	ld	ra,104(sp)
    80003b58:	7406                	ld	s0,96(sp)
    80003b5a:	64e6                	ld	s1,88(sp)
    80003b5c:	6946                	ld	s2,80(sp)
    80003b5e:	69a6                	ld	s3,72(sp)
    80003b60:	6a06                	ld	s4,64(sp)
    80003b62:	7ae2                	ld	s5,56(sp)
    80003b64:	7b42                	ld	s6,48(sp)
    80003b66:	7ba2                	ld	s7,40(sp)
    80003b68:	7c02                	ld	s8,32(sp)
    80003b6a:	6ce2                	ld	s9,24(sp)
    80003b6c:	6d42                	ld	s10,16(sp)
    80003b6e:	6da2                	ld	s11,8(sp)
    80003b70:	6165                	addi	sp,sp,112
    80003b72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b74:	89da                	mv	s3,s6
    80003b76:	bff1                	j	80003b52 <readi+0xce>
    return 0;
    80003b78:	4501                	li	a0,0
}
    80003b7a:	8082                	ret

0000000080003b7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b7c:	457c                	lw	a5,76(a0)
    80003b7e:	10d7e863          	bltu	a5,a3,80003c8e <writei+0x112>
{
    80003b82:	7159                	addi	sp,sp,-112
    80003b84:	f486                	sd	ra,104(sp)
    80003b86:	f0a2                	sd	s0,96(sp)
    80003b88:	eca6                	sd	s1,88(sp)
    80003b8a:	e8ca                	sd	s2,80(sp)
    80003b8c:	e4ce                	sd	s3,72(sp)
    80003b8e:	e0d2                	sd	s4,64(sp)
    80003b90:	fc56                	sd	s5,56(sp)
    80003b92:	f85a                	sd	s6,48(sp)
    80003b94:	f45e                	sd	s7,40(sp)
    80003b96:	f062                	sd	s8,32(sp)
    80003b98:	ec66                	sd	s9,24(sp)
    80003b9a:	e86a                	sd	s10,16(sp)
    80003b9c:	e46e                	sd	s11,8(sp)
    80003b9e:	1880                	addi	s0,sp,112
    80003ba0:	8b2a                	mv	s6,a0
    80003ba2:	8c2e                	mv	s8,a1
    80003ba4:	8ab2                	mv	s5,a2
    80003ba6:	8936                	mv	s2,a3
    80003ba8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003baa:	00e687bb          	addw	a5,a3,a4
    80003bae:	0ed7e263          	bltu	a5,a3,80003c92 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bb2:	00043737          	lui	a4,0x43
    80003bb6:	0ef76063          	bltu	a4,a5,80003c96 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bba:	0c0b8863          	beqz	s7,80003c8a <writei+0x10e>
    80003bbe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bc4:	5cfd                	li	s9,-1
    80003bc6:	a091                	j	80003c0a <writei+0x8e>
    80003bc8:	02099d93          	slli	s11,s3,0x20
    80003bcc:	020ddd93          	srli	s11,s11,0x20
    80003bd0:	05848513          	addi	a0,s1,88
    80003bd4:	86ee                	mv	a3,s11
    80003bd6:	8656                	mv	a2,s5
    80003bd8:	85e2                	mv	a1,s8
    80003bda:	953a                	add	a0,a0,a4
    80003bdc:	fffff097          	auipc	ra,0xfffff
    80003be0:	a5e080e7          	jalr	-1442(ra) # 8000263a <either_copyin>
    80003be4:	07950263          	beq	a0,s9,80003c48 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	790080e7          	jalr	1936(ra) # 8000437a <log_write>
    brelse(bp);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	4f8080e7          	jalr	1272(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bfc:	01498a3b          	addw	s4,s3,s4
    80003c00:	0129893b          	addw	s2,s3,s2
    80003c04:	9aee                	add	s5,s5,s11
    80003c06:	057a7663          	bgeu	s4,s7,80003c52 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c0a:	000b2483          	lw	s1,0(s6)
    80003c0e:	00a9559b          	srliw	a1,s2,0xa
    80003c12:	855a                	mv	a0,s6
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	79c080e7          	jalr	1948(ra) # 800033b0 <bmap>
    80003c1c:	0005059b          	sext.w	a1,a0
    80003c20:	8526                	mv	a0,s1
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	39a080e7          	jalr	922(ra) # 80002fbc <bread>
    80003c2a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2c:	3ff97713          	andi	a4,s2,1023
    80003c30:	40ed07bb          	subw	a5,s10,a4
    80003c34:	414b86bb          	subw	a3,s7,s4
    80003c38:	89be                	mv	s3,a5
    80003c3a:	2781                	sext.w	a5,a5
    80003c3c:	0006861b          	sext.w	a2,a3
    80003c40:	f8f674e3          	bgeu	a2,a5,80003bc8 <writei+0x4c>
    80003c44:	89b6                	mv	s3,a3
    80003c46:	b749                	j	80003bc8 <writei+0x4c>
      brelse(bp);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	fffff097          	auipc	ra,0xfffff
    80003c4e:	4a2080e7          	jalr	1186(ra) # 800030ec <brelse>
  }

  if(off > ip->size)
    80003c52:	04cb2783          	lw	a5,76(s6)
    80003c56:	0127f463          	bgeu	a5,s2,80003c5e <writei+0xe2>
    ip->size = off;
    80003c5a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c5e:	855a                	mv	a0,s6
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	aa6080e7          	jalr	-1370(ra) # 80003706 <iupdate>

  return tot;
    80003c68:	000a051b          	sext.w	a0,s4
}
    80003c6c:	70a6                	ld	ra,104(sp)
    80003c6e:	7406                	ld	s0,96(sp)
    80003c70:	64e6                	ld	s1,88(sp)
    80003c72:	6946                	ld	s2,80(sp)
    80003c74:	69a6                	ld	s3,72(sp)
    80003c76:	6a06                	ld	s4,64(sp)
    80003c78:	7ae2                	ld	s5,56(sp)
    80003c7a:	7b42                	ld	s6,48(sp)
    80003c7c:	7ba2                	ld	s7,40(sp)
    80003c7e:	7c02                	ld	s8,32(sp)
    80003c80:	6ce2                	ld	s9,24(sp)
    80003c82:	6d42                	ld	s10,16(sp)
    80003c84:	6da2                	ld	s11,8(sp)
    80003c86:	6165                	addi	sp,sp,112
    80003c88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c8a:	8a5e                	mv	s4,s7
    80003c8c:	bfc9                	j	80003c5e <writei+0xe2>
    return -1;
    80003c8e:	557d                	li	a0,-1
}
    80003c90:	8082                	ret
    return -1;
    80003c92:	557d                	li	a0,-1
    80003c94:	bfe1                	j	80003c6c <writei+0xf0>
    return -1;
    80003c96:	557d                	li	a0,-1
    80003c98:	bfd1                	j	80003c6c <writei+0xf0>

0000000080003c9a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c9a:	1141                	addi	sp,sp,-16
    80003c9c:	e406                	sd	ra,8(sp)
    80003c9e:	e022                	sd	s0,0(sp)
    80003ca0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ca2:	4639                	li	a2,14
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	114080e7          	jalr	276(ra) # 80000db8 <strncmp>
}
    80003cac:	60a2                	ld	ra,8(sp)
    80003cae:	6402                	ld	s0,0(sp)
    80003cb0:	0141                	addi	sp,sp,16
    80003cb2:	8082                	ret

0000000080003cb4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cb4:	7139                	addi	sp,sp,-64
    80003cb6:	fc06                	sd	ra,56(sp)
    80003cb8:	f822                	sd	s0,48(sp)
    80003cba:	f426                	sd	s1,40(sp)
    80003cbc:	f04a                	sd	s2,32(sp)
    80003cbe:	ec4e                	sd	s3,24(sp)
    80003cc0:	e852                	sd	s4,16(sp)
    80003cc2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cc4:	04451703          	lh	a4,68(a0)
    80003cc8:	4785                	li	a5,1
    80003cca:	00f71a63          	bne	a4,a5,80003cde <dirlookup+0x2a>
    80003cce:	892a                	mv	s2,a0
    80003cd0:	89ae                	mv	s3,a1
    80003cd2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd4:	457c                	lw	a5,76(a0)
    80003cd6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cd8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cda:	e79d                	bnez	a5,80003d08 <dirlookup+0x54>
    80003cdc:	a8a5                	j	80003d54 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cde:	00009517          	auipc	a0,0x9
    80003ce2:	ba250513          	addi	a0,a0,-1118 # 8000c880 <syscalls+0x1b8>
    80003ce6:	ffffd097          	auipc	ra,0xffffd
    80003cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cee:	00009517          	auipc	a0,0x9
    80003cf2:	baa50513          	addi	a0,a0,-1110 # 8000c898 <syscalls+0x1d0>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cfe:	24c1                	addiw	s1,s1,16
    80003d00:	04c92783          	lw	a5,76(s2)
    80003d04:	04f4f763          	bgeu	s1,a5,80003d52 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d08:	4741                	li	a4,16
    80003d0a:	86a6                	mv	a3,s1
    80003d0c:	fc040613          	addi	a2,s0,-64
    80003d10:	4581                	li	a1,0
    80003d12:	854a                	mv	a0,s2
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	d70080e7          	jalr	-656(ra) # 80003a84 <readi>
    80003d1c:	47c1                	li	a5,16
    80003d1e:	fcf518e3          	bne	a0,a5,80003cee <dirlookup+0x3a>
    if(de.inum == 0)
    80003d22:	fc045783          	lhu	a5,-64(s0)
    80003d26:	dfe1                	beqz	a5,80003cfe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d28:	fc240593          	addi	a1,s0,-62
    80003d2c:	854e                	mv	a0,s3
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	f6c080e7          	jalr	-148(ra) # 80003c9a <namecmp>
    80003d36:	f561                	bnez	a0,80003cfe <dirlookup+0x4a>
      if(poff)
    80003d38:	000a0463          	beqz	s4,80003d40 <dirlookup+0x8c>
        *poff = off;
    80003d3c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d40:	fc045583          	lhu	a1,-64(s0)
    80003d44:	00092503          	lw	a0,0(s2)
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	742080e7          	jalr	1858(ra) # 8000348a <iget>
    80003d50:	a011                	j	80003d54 <dirlookup+0xa0>
  return 0;
    80003d52:	4501                	li	a0,0
}
    80003d54:	70e2                	ld	ra,56(sp)
    80003d56:	7442                	ld	s0,48(sp)
    80003d58:	74a2                	ld	s1,40(sp)
    80003d5a:	7902                	ld	s2,32(sp)
    80003d5c:	69e2                	ld	s3,24(sp)
    80003d5e:	6a42                	ld	s4,16(sp)
    80003d60:	6121                	addi	sp,sp,64
    80003d62:	8082                	ret

0000000080003d64 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d64:	711d                	addi	sp,sp,-96
    80003d66:	ec86                	sd	ra,88(sp)
    80003d68:	e8a2                	sd	s0,80(sp)
    80003d6a:	e4a6                	sd	s1,72(sp)
    80003d6c:	e0ca                	sd	s2,64(sp)
    80003d6e:	fc4e                	sd	s3,56(sp)
    80003d70:	f852                	sd	s4,48(sp)
    80003d72:	f456                	sd	s5,40(sp)
    80003d74:	f05a                	sd	s6,32(sp)
    80003d76:	ec5e                	sd	s7,24(sp)
    80003d78:	e862                	sd	s8,16(sp)
    80003d7a:	e466                	sd	s9,8(sp)
    80003d7c:	1080                	addi	s0,sp,96
    80003d7e:	84aa                	mv	s1,a0
    80003d80:	8b2e                	mv	s6,a1
    80003d82:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d84:	00054703          	lbu	a4,0(a0)
    80003d88:	02f00793          	li	a5,47
    80003d8c:	02f70363          	beq	a4,a5,80003db2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d90:	ffffe097          	auipc	ra,0xffffe
    80003d94:	dc0080e7          	jalr	-576(ra) # 80001b50 <myproc>
    80003d98:	15053503          	ld	a0,336(a0)
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	9f6080e7          	jalr	-1546(ra) # 80003792 <idup>
    80003da4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003da6:	02f00913          	li	s2,47
  len = path - s;
    80003daa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dae:	4c05                	li	s8,1
    80003db0:	a865                	j	80003e68 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003db2:	4585                	li	a1,1
    80003db4:	4505                	li	a0,1
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	6d4080e7          	jalr	1748(ra) # 8000348a <iget>
    80003dbe:	89aa                	mv	s3,a0
    80003dc0:	b7dd                	j	80003da6 <namex+0x42>
      iunlockput(ip);
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	c6e080e7          	jalr	-914(ra) # 80003a32 <iunlockput>
      return 0;
    80003dcc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dce:	854e                	mv	a0,s3
    80003dd0:	60e6                	ld	ra,88(sp)
    80003dd2:	6446                	ld	s0,80(sp)
    80003dd4:	64a6                	ld	s1,72(sp)
    80003dd6:	6906                	ld	s2,64(sp)
    80003dd8:	79e2                	ld	s3,56(sp)
    80003dda:	7a42                	ld	s4,48(sp)
    80003ddc:	7aa2                	ld	s5,40(sp)
    80003dde:	7b02                	ld	s6,32(sp)
    80003de0:	6be2                	ld	s7,24(sp)
    80003de2:	6c42                	ld	s8,16(sp)
    80003de4:	6ca2                	ld	s9,8(sp)
    80003de6:	6125                	addi	sp,sp,96
    80003de8:	8082                	ret
      iunlock(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	aa6080e7          	jalr	-1370(ra) # 80003892 <iunlock>
      return ip;
    80003df4:	bfe9                	j	80003dce <namex+0x6a>
      iunlockput(ip);
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	c3a080e7          	jalr	-966(ra) # 80003a32 <iunlockput>
      return 0;
    80003e00:	89d2                	mv	s3,s4
    80003e02:	b7f1                	j	80003dce <namex+0x6a>
  len = path - s;
    80003e04:	40b48633          	sub	a2,s1,a1
    80003e08:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e0c:	094cd463          	bge	s9,s4,80003e94 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e10:	4639                	li	a2,14
    80003e12:	8556                	mv	a0,s5
    80003e14:	ffffd097          	auipc	ra,0xffffd
    80003e18:	f2c080e7          	jalr	-212(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003e1c:	0004c783          	lbu	a5,0(s1)
    80003e20:	01279763          	bne	a5,s2,80003e2e <namex+0xca>
    path++;
    80003e24:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	ff278de3          	beq	a5,s2,80003e24 <namex+0xc0>
    ilock(ip);
    80003e2e:	854e                	mv	a0,s3
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	9a0080e7          	jalr	-1632(ra) # 800037d0 <ilock>
    if(ip->type != T_DIR){
    80003e38:	04499783          	lh	a5,68(s3)
    80003e3c:	f98793e3          	bne	a5,s8,80003dc2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e40:	000b0563          	beqz	s6,80003e4a <namex+0xe6>
    80003e44:	0004c783          	lbu	a5,0(s1)
    80003e48:	d3cd                	beqz	a5,80003dea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e4a:	865e                	mv	a2,s7
    80003e4c:	85d6                	mv	a1,s5
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	e64080e7          	jalr	-412(ra) # 80003cb4 <dirlookup>
    80003e58:	8a2a                	mv	s4,a0
    80003e5a:	dd51                	beqz	a0,80003df6 <namex+0x92>
    iunlockput(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	bd4080e7          	jalr	-1068(ra) # 80003a32 <iunlockput>
    ip = next;
    80003e66:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e68:	0004c783          	lbu	a5,0(s1)
    80003e6c:	05279763          	bne	a5,s2,80003eba <namex+0x156>
    path++;
    80003e70:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e72:	0004c783          	lbu	a5,0(s1)
    80003e76:	ff278de3          	beq	a5,s2,80003e70 <namex+0x10c>
  if(*path == 0)
    80003e7a:	c79d                	beqz	a5,80003ea8 <namex+0x144>
    path++;
    80003e7c:	85a6                	mv	a1,s1
  len = path - s;
    80003e7e:	8a5e                	mv	s4,s7
    80003e80:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e82:	01278963          	beq	a5,s2,80003e94 <namex+0x130>
    80003e86:	dfbd                	beqz	a5,80003e04 <namex+0xa0>
    path++;
    80003e88:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	ff279ce3          	bne	a5,s2,80003e86 <namex+0x122>
    80003e92:	bf8d                	j	80003e04 <namex+0xa0>
    memmove(name, s, len);
    80003e94:	2601                	sext.w	a2,a2
    80003e96:	8556                	mv	a0,s5
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	ea8080e7          	jalr	-344(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003ea0:	9a56                	add	s4,s4,s5
    80003ea2:	000a0023          	sb	zero,0(s4)
    80003ea6:	bf9d                	j	80003e1c <namex+0xb8>
  if(nameiparent){
    80003ea8:	f20b03e3          	beqz	s6,80003dce <namex+0x6a>
    iput(ip);
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	adc080e7          	jalr	-1316(ra) # 8000398a <iput>
    return 0;
    80003eb6:	4981                	li	s3,0
    80003eb8:	bf19                	j	80003dce <namex+0x6a>
  if(*path == 0)
    80003eba:	d7fd                	beqz	a5,80003ea8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	85a6                	mv	a1,s1
    80003ec2:	b7d1                	j	80003e86 <namex+0x122>

0000000080003ec4 <dirlink>:
{
    80003ec4:	7139                	addi	sp,sp,-64
    80003ec6:	fc06                	sd	ra,56(sp)
    80003ec8:	f822                	sd	s0,48(sp)
    80003eca:	f426                	sd	s1,40(sp)
    80003ecc:	f04a                	sd	s2,32(sp)
    80003ece:	ec4e                	sd	s3,24(sp)
    80003ed0:	e852                	sd	s4,16(sp)
    80003ed2:	0080                	addi	s0,sp,64
    80003ed4:	892a                	mv	s2,a0
    80003ed6:	8a2e                	mv	s4,a1
    80003ed8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eda:	4601                	li	a2,0
    80003edc:	00000097          	auipc	ra,0x0
    80003ee0:	dd8080e7          	jalr	-552(ra) # 80003cb4 <dirlookup>
    80003ee4:	e93d                	bnez	a0,80003f5a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	04c92483          	lw	s1,76(s2)
    80003eea:	c49d                	beqz	s1,80003f18 <dirlink+0x54>
    80003eec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eee:	4741                	li	a4,16
    80003ef0:	86a6                	mv	a3,s1
    80003ef2:	fc040613          	addi	a2,s0,-64
    80003ef6:	4581                	li	a1,0
    80003ef8:	854a                	mv	a0,s2
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	b8a080e7          	jalr	-1142(ra) # 80003a84 <readi>
    80003f02:	47c1                	li	a5,16
    80003f04:	06f51163          	bne	a0,a5,80003f66 <dirlink+0xa2>
    if(de.inum == 0)
    80003f08:	fc045783          	lhu	a5,-64(s0)
    80003f0c:	c791                	beqz	a5,80003f18 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0e:	24c1                	addiw	s1,s1,16
    80003f10:	04c92783          	lw	a5,76(s2)
    80003f14:	fcf4ede3          	bltu	s1,a5,80003eee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f18:	4639                	li	a2,14
    80003f1a:	85d2                	mv	a1,s4
    80003f1c:	fc240513          	addi	a0,s0,-62
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	ed4080e7          	jalr	-300(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003f28:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2c:	4741                	li	a4,16
    80003f2e:	86a6                	mv	a3,s1
    80003f30:	fc040613          	addi	a2,s0,-64
    80003f34:	4581                	li	a1,0
    80003f36:	854a                	mv	a0,s2
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	c44080e7          	jalr	-956(ra) # 80003b7c <writei>
    80003f40:	872a                	mv	a4,a0
    80003f42:	47c1                	li	a5,16
  return 0;
    80003f44:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f46:	02f71863          	bne	a4,a5,80003f76 <dirlink+0xb2>
}
    80003f4a:	70e2                	ld	ra,56(sp)
    80003f4c:	7442                	ld	s0,48(sp)
    80003f4e:	74a2                	ld	s1,40(sp)
    80003f50:	7902                	ld	s2,32(sp)
    80003f52:	69e2                	ld	s3,24(sp)
    80003f54:	6a42                	ld	s4,16(sp)
    80003f56:	6121                	addi	sp,sp,64
    80003f58:	8082                	ret
    iput(ip);
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	a30080e7          	jalr	-1488(ra) # 8000398a <iput>
    return -1;
    80003f62:	557d                	li	a0,-1
    80003f64:	b7dd                	j	80003f4a <dirlink+0x86>
      panic("dirlink read");
    80003f66:	00009517          	auipc	a0,0x9
    80003f6a:	94250513          	addi	a0,a0,-1726 # 8000c8a8 <syscalls+0x1e0>
    80003f6e:	ffffc097          	auipc	ra,0xffffc
    80003f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>
    panic("dirlink");
    80003f76:	00009517          	auipc	a0,0x9
    80003f7a:	a4250513          	addi	a0,a0,-1470 # 8000c9b8 <syscalls+0x2f0>
    80003f7e:	ffffc097          	auipc	ra,0xffffc
    80003f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>

0000000080003f86 <namei>:

struct inode*
namei(char *path)
{
    80003f86:	1101                	addi	sp,sp,-32
    80003f88:	ec06                	sd	ra,24(sp)
    80003f8a:	e822                	sd	s0,16(sp)
    80003f8c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f8e:	fe040613          	addi	a2,s0,-32
    80003f92:	4581                	li	a1,0
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	dd0080e7          	jalr	-560(ra) # 80003d64 <namex>
}
    80003f9c:	60e2                	ld	ra,24(sp)
    80003f9e:	6442                	ld	s0,16(sp)
    80003fa0:	6105                	addi	sp,sp,32
    80003fa2:	8082                	ret

0000000080003fa4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fa4:	1141                	addi	sp,sp,-16
    80003fa6:	e406                	sd	ra,8(sp)
    80003fa8:	e022                	sd	s0,0(sp)
    80003faa:	0800                	addi	s0,sp,16
    80003fac:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fae:	4585                	li	a1,1
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	db4080e7          	jalr	-588(ra) # 80003d64 <namex>
}
    80003fb8:	60a2                	ld	ra,8(sp)
    80003fba:	6402                	ld	s0,0(sp)
    80003fbc:	0141                	addi	sp,sp,16
    80003fbe:	8082                	ret

0000000080003fc0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fc0:	1101                	addi	sp,sp,-32
    80003fc2:	ec06                	sd	ra,24(sp)
    80003fc4:	e822                	sd	s0,16(sp)
    80003fc6:	e426                	sd	s1,8(sp)
    80003fc8:	e04a                	sd	s2,0(sp)
    80003fca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fcc:	00024917          	auipc	s2,0x24
    80003fd0:	2a490913          	addi	s2,s2,676 # 80028270 <log>
    80003fd4:	01892583          	lw	a1,24(s2)
    80003fd8:	02892503          	lw	a0,40(s2)
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	fe0080e7          	jalr	-32(ra) # 80002fbc <bread>
    80003fe4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fe6:	02c92683          	lw	a3,44(s2)
    80003fea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fec:	02d05763          	blez	a3,8000401a <write_head+0x5a>
    80003ff0:	00024797          	auipc	a5,0x24
    80003ff4:	2b078793          	addi	a5,a5,688 # 800282a0 <log+0x30>
    80003ff8:	05c50713          	addi	a4,a0,92
    80003ffc:	36fd                	addiw	a3,a3,-1
    80003ffe:	1682                	slli	a3,a3,0x20
    80004000:	9281                	srli	a3,a3,0x20
    80004002:	068a                	slli	a3,a3,0x2
    80004004:	00024617          	auipc	a2,0x24
    80004008:	2a060613          	addi	a2,a2,672 # 800282a4 <log+0x34>
    8000400c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000400e:	4390                	lw	a2,0(a5)
    80004010:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004012:	0791                	addi	a5,a5,4
    80004014:	0711                	addi	a4,a4,4
    80004016:	fed79ce3          	bne	a5,a3,8000400e <write_head+0x4e>
  }
  bwrite(buf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	092080e7          	jalr	146(ra) # 800030ae <bwrite>
  brelse(buf);
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	0c6080e7          	jalr	198(ra) # 800030ec <brelse>
}
    8000402e:	60e2                	ld	ra,24(sp)
    80004030:	6442                	ld	s0,16(sp)
    80004032:	64a2                	ld	s1,8(sp)
    80004034:	6902                	ld	s2,0(sp)
    80004036:	6105                	addi	sp,sp,32
    80004038:	8082                	ret

000000008000403a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403a:	00024797          	auipc	a5,0x24
    8000403e:	2627a783          	lw	a5,610(a5) # 8002829c <log+0x2c>
    80004042:	0af05d63          	blez	a5,800040fc <install_trans+0xc2>
{
    80004046:	7139                	addi	sp,sp,-64
    80004048:	fc06                	sd	ra,56(sp)
    8000404a:	f822                	sd	s0,48(sp)
    8000404c:	f426                	sd	s1,40(sp)
    8000404e:	f04a                	sd	s2,32(sp)
    80004050:	ec4e                	sd	s3,24(sp)
    80004052:	e852                	sd	s4,16(sp)
    80004054:	e456                	sd	s5,8(sp)
    80004056:	e05a                	sd	s6,0(sp)
    80004058:	0080                	addi	s0,sp,64
    8000405a:	8b2a                	mv	s6,a0
    8000405c:	00024a97          	auipc	s5,0x24
    80004060:	244a8a93          	addi	s5,s5,580 # 800282a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004064:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004066:	00024997          	auipc	s3,0x24
    8000406a:	20a98993          	addi	s3,s3,522 # 80028270 <log>
    8000406e:	a035                	j	8000409a <install_trans+0x60>
      bunpin(dbuf);
    80004070:	8526                	mv	a0,s1
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	154080e7          	jalr	340(ra) # 800031c6 <bunpin>
    brelse(lbuf);
    8000407a:	854a                	mv	a0,s2
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	070080e7          	jalr	112(ra) # 800030ec <brelse>
    brelse(dbuf);
    80004084:	8526                	mv	a0,s1
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	066080e7          	jalr	102(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408e:	2a05                	addiw	s4,s4,1
    80004090:	0a91                	addi	s5,s5,4
    80004092:	02c9a783          	lw	a5,44(s3)
    80004096:	04fa5963          	bge	s4,a5,800040e8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000409a:	0189a583          	lw	a1,24(s3)
    8000409e:	014585bb          	addw	a1,a1,s4
    800040a2:	2585                	addiw	a1,a1,1
    800040a4:	0289a503          	lw	a0,40(s3)
    800040a8:	fffff097          	auipc	ra,0xfffff
    800040ac:	f14080e7          	jalr	-236(ra) # 80002fbc <bread>
    800040b0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040b2:	000aa583          	lw	a1,0(s5)
    800040b6:	0289a503          	lw	a0,40(s3)
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	f02080e7          	jalr	-254(ra) # 80002fbc <bread>
    800040c2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040c4:	40000613          	li	a2,1024
    800040c8:	05890593          	addi	a1,s2,88
    800040cc:	05850513          	addi	a0,a0,88
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	c70080e7          	jalr	-912(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040d8:	8526                	mv	a0,s1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	fd4080e7          	jalr	-44(ra) # 800030ae <bwrite>
    if(recovering == 0)
    800040e2:	f80b1ce3          	bnez	s6,8000407a <install_trans+0x40>
    800040e6:	b769                	j	80004070 <install_trans+0x36>
}
    800040e8:	70e2                	ld	ra,56(sp)
    800040ea:	7442                	ld	s0,48(sp)
    800040ec:	74a2                	ld	s1,40(sp)
    800040ee:	7902                	ld	s2,32(sp)
    800040f0:	69e2                	ld	s3,24(sp)
    800040f2:	6a42                	ld	s4,16(sp)
    800040f4:	6aa2                	ld	s5,8(sp)
    800040f6:	6b02                	ld	s6,0(sp)
    800040f8:	6121                	addi	sp,sp,64
    800040fa:	8082                	ret
    800040fc:	8082                	ret

00000000800040fe <initlog>:
{
    800040fe:	7179                	addi	sp,sp,-48
    80004100:	f406                	sd	ra,40(sp)
    80004102:	f022                	sd	s0,32(sp)
    80004104:	ec26                	sd	s1,24(sp)
    80004106:	e84a                	sd	s2,16(sp)
    80004108:	e44e                	sd	s3,8(sp)
    8000410a:	1800                	addi	s0,sp,48
    8000410c:	892a                	mv	s2,a0
    8000410e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004110:	00024497          	auipc	s1,0x24
    80004114:	16048493          	addi	s1,s1,352 # 80028270 <log>
    80004118:	00008597          	auipc	a1,0x8
    8000411c:	7a058593          	addi	a1,a1,1952 # 8000c8b8 <syscalls+0x1f0>
    80004120:	8526                	mv	a0,s1
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	a32080e7          	jalr	-1486(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000412a:	0149a583          	lw	a1,20(s3)
    8000412e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004130:	0109a783          	lw	a5,16(s3)
    80004134:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004136:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000413a:	854a                	mv	a0,s2
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	e80080e7          	jalr	-384(ra) # 80002fbc <bread>
  log.lh.n = lh->n;
    80004144:	4d3c                	lw	a5,88(a0)
    80004146:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004148:	02f05563          	blez	a5,80004172 <initlog+0x74>
    8000414c:	05c50713          	addi	a4,a0,92
    80004150:	00024697          	auipc	a3,0x24
    80004154:	15068693          	addi	a3,a3,336 # 800282a0 <log+0x30>
    80004158:	37fd                	addiw	a5,a5,-1
    8000415a:	1782                	slli	a5,a5,0x20
    8000415c:	9381                	srli	a5,a5,0x20
    8000415e:	078a                	slli	a5,a5,0x2
    80004160:	06050613          	addi	a2,a0,96
    80004164:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004166:	4310                	lw	a2,0(a4)
    80004168:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000416a:	0711                	addi	a4,a4,4
    8000416c:	0691                	addi	a3,a3,4
    8000416e:	fef71ce3          	bne	a4,a5,80004166 <initlog+0x68>
  brelse(buf);
    80004172:	fffff097          	auipc	ra,0xfffff
    80004176:	f7a080e7          	jalr	-134(ra) # 800030ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000417a:	4505                	li	a0,1
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	ebe080e7          	jalr	-322(ra) # 8000403a <install_trans>
  log.lh.n = 0;
    80004184:	00024797          	auipc	a5,0x24
    80004188:	1007ac23          	sw	zero,280(a5) # 8002829c <log+0x2c>
  write_head(); // clear the log
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	e34080e7          	jalr	-460(ra) # 80003fc0 <write_head>
}
    80004194:	70a2                	ld	ra,40(sp)
    80004196:	7402                	ld	s0,32(sp)
    80004198:	64e2                	ld	s1,24(sp)
    8000419a:	6942                	ld	s2,16(sp)
    8000419c:	69a2                	ld	s3,8(sp)
    8000419e:	6145                	addi	sp,sp,48
    800041a0:	8082                	ret

00000000800041a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041a2:	1101                	addi	sp,sp,-32
    800041a4:	ec06                	sd	ra,24(sp)
    800041a6:	e822                	sd	s0,16(sp)
    800041a8:	e426                	sd	s1,8(sp)
    800041aa:	e04a                	sd	s2,0(sp)
    800041ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ae:	00024517          	auipc	a0,0x24
    800041b2:	0c250513          	addi	a0,a0,194 # 80028270 <log>
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a2e080e7          	jalr	-1490(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800041be:	00024497          	auipc	s1,0x24
    800041c2:	0b248493          	addi	s1,s1,178 # 80028270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c6:	4979                	li	s2,30
    800041c8:	a039                	j	800041d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ca:	85a6                	mv	a1,s1
    800041cc:	8526                	mv	a0,s1
    800041ce:	ffffe097          	auipc	ra,0xffffe
    800041d2:	072080e7          	jalr	114(ra) # 80002240 <sleep>
    if(log.committing){
    800041d6:	50dc                	lw	a5,36(s1)
    800041d8:	fbed                	bnez	a5,800041ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041da:	509c                	lw	a5,32(s1)
    800041dc:	0017871b          	addiw	a4,a5,1
    800041e0:	0007069b          	sext.w	a3,a4
    800041e4:	0027179b          	slliw	a5,a4,0x2
    800041e8:	9fb9                	addw	a5,a5,a4
    800041ea:	0017979b          	slliw	a5,a5,0x1
    800041ee:	54d8                	lw	a4,44(s1)
    800041f0:	9fb9                	addw	a5,a5,a4
    800041f2:	00f95963          	bge	s2,a5,80004204 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041f6:	85a6                	mv	a1,s1
    800041f8:	8526                	mv	a0,s1
    800041fa:	ffffe097          	auipc	ra,0xffffe
    800041fe:	046080e7          	jalr	70(ra) # 80002240 <sleep>
    80004202:	bfd1                	j	800041d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004204:	00024517          	auipc	a0,0x24
    80004208:	06c50513          	addi	a0,a0,108 # 80028270 <log>
    8000420c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	a8a080e7          	jalr	-1398(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004216:	60e2                	ld	ra,24(sp)
    80004218:	6442                	ld	s0,16(sp)
    8000421a:	64a2                	ld	s1,8(sp)
    8000421c:	6902                	ld	s2,0(sp)
    8000421e:	6105                	addi	sp,sp,32
    80004220:	8082                	ret

0000000080004222 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004222:	7139                	addi	sp,sp,-64
    80004224:	fc06                	sd	ra,56(sp)
    80004226:	f822                	sd	s0,48(sp)
    80004228:	f426                	sd	s1,40(sp)
    8000422a:	f04a                	sd	s2,32(sp)
    8000422c:	ec4e                	sd	s3,24(sp)
    8000422e:	e852                	sd	s4,16(sp)
    80004230:	e456                	sd	s5,8(sp)
    80004232:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004234:	00024497          	auipc	s1,0x24
    80004238:	03c48493          	addi	s1,s1,60 # 80028270 <log>
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	9a6080e7          	jalr	-1626(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004246:	509c                	lw	a5,32(s1)
    80004248:	37fd                	addiw	a5,a5,-1
    8000424a:	0007891b          	sext.w	s2,a5
    8000424e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004250:	50dc                	lw	a5,36(s1)
    80004252:	efb9                	bnez	a5,800042b0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004254:	06091663          	bnez	s2,800042c0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004258:	00024497          	auipc	s1,0x24
    8000425c:	01848493          	addi	s1,s1,24 # 80028270 <log>
    80004260:	4785                	li	a5,1
    80004262:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000426e:	54dc                	lw	a5,44(s1)
    80004270:	06f04763          	bgtz	a5,800042de <end_op+0xbc>
    acquire(&log.lock);
    80004274:	00024497          	auipc	s1,0x24
    80004278:	ffc48493          	addi	s1,s1,-4 # 80028270 <log>
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	966080e7          	jalr	-1690(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004286:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000428a:	8526                	mv	a0,s1
    8000428c:	ffffe097          	auipc	ra,0xffffe
    80004290:	140080e7          	jalr	320(ra) # 800023cc <wakeup>
    release(&log.lock);
    80004294:	8526                	mv	a0,s1
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	a02080e7          	jalr	-1534(ra) # 80000c98 <release>
}
    8000429e:	70e2                	ld	ra,56(sp)
    800042a0:	7442                	ld	s0,48(sp)
    800042a2:	74a2                	ld	s1,40(sp)
    800042a4:	7902                	ld	s2,32(sp)
    800042a6:	69e2                	ld	s3,24(sp)
    800042a8:	6a42                	ld	s4,16(sp)
    800042aa:	6aa2                	ld	s5,8(sp)
    800042ac:	6121                	addi	sp,sp,64
    800042ae:	8082                	ret
    panic("log.committing");
    800042b0:	00008517          	auipc	a0,0x8
    800042b4:	61050513          	addi	a0,a0,1552 # 8000c8c0 <syscalls+0x1f8>
    800042b8:	ffffc097          	auipc	ra,0xffffc
    800042bc:	286080e7          	jalr	646(ra) # 8000053e <panic>
    wakeup(&log);
    800042c0:	00024497          	auipc	s1,0x24
    800042c4:	fb048493          	addi	s1,s1,-80 # 80028270 <log>
    800042c8:	8526                	mv	a0,s1
    800042ca:	ffffe097          	auipc	ra,0xffffe
    800042ce:	102080e7          	jalr	258(ra) # 800023cc <wakeup>
  release(&log.lock);
    800042d2:	8526                	mv	a0,s1
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9c4080e7          	jalr	-1596(ra) # 80000c98 <release>
  if(do_commit){
    800042dc:	b7c9                	j	8000429e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042de:	00024a97          	auipc	s5,0x24
    800042e2:	fc2a8a93          	addi	s5,s5,-62 # 800282a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042e6:	00024a17          	auipc	s4,0x24
    800042ea:	f8aa0a13          	addi	s4,s4,-118 # 80028270 <log>
    800042ee:	018a2583          	lw	a1,24(s4)
    800042f2:	012585bb          	addw	a1,a1,s2
    800042f6:	2585                	addiw	a1,a1,1
    800042f8:	028a2503          	lw	a0,40(s4)
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	cc0080e7          	jalr	-832(ra) # 80002fbc <bread>
    80004304:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004306:	000aa583          	lw	a1,0(s5)
    8000430a:	028a2503          	lw	a0,40(s4)
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	cae080e7          	jalr	-850(ra) # 80002fbc <bread>
    80004316:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004318:	40000613          	li	a2,1024
    8000431c:	05850593          	addi	a1,a0,88
    80004320:	05848513          	addi	a0,s1,88
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	a1c080e7          	jalr	-1508(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000432c:	8526                	mv	a0,s1
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	d80080e7          	jalr	-640(ra) # 800030ae <bwrite>
    brelse(from);
    80004336:	854e                	mv	a0,s3
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	db4080e7          	jalr	-588(ra) # 800030ec <brelse>
    brelse(to);
    80004340:	8526                	mv	a0,s1
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	daa080e7          	jalr	-598(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000434a:	2905                	addiw	s2,s2,1
    8000434c:	0a91                	addi	s5,s5,4
    8000434e:	02ca2783          	lw	a5,44(s4)
    80004352:	f8f94ee3          	blt	s2,a5,800042ee <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c6a080e7          	jalr	-918(ra) # 80003fc0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000435e:	4501                	li	a0,0
    80004360:	00000097          	auipc	ra,0x0
    80004364:	cda080e7          	jalr	-806(ra) # 8000403a <install_trans>
    log.lh.n = 0;
    80004368:	00024797          	auipc	a5,0x24
    8000436c:	f207aa23          	sw	zero,-204(a5) # 8002829c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004370:	00000097          	auipc	ra,0x0
    80004374:	c50080e7          	jalr	-944(ra) # 80003fc0 <write_head>
    80004378:	bdf5                	j	80004274 <end_op+0x52>

000000008000437a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000437a:	1101                	addi	sp,sp,-32
    8000437c:	ec06                	sd	ra,24(sp)
    8000437e:	e822                	sd	s0,16(sp)
    80004380:	e426                	sd	s1,8(sp)
    80004382:	e04a                	sd	s2,0(sp)
    80004384:	1000                	addi	s0,sp,32
    80004386:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004388:	00024917          	auipc	s2,0x24
    8000438c:	ee890913          	addi	s2,s2,-280 # 80028270 <log>
    80004390:	854a                	mv	a0,s2
    80004392:	ffffd097          	auipc	ra,0xffffd
    80004396:	852080e7          	jalr	-1966(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000439a:	02c92603          	lw	a2,44(s2)
    8000439e:	47f5                	li	a5,29
    800043a0:	06c7c563          	blt	a5,a2,8000440a <log_write+0x90>
    800043a4:	00024797          	auipc	a5,0x24
    800043a8:	ee87a783          	lw	a5,-280(a5) # 8002828c <log+0x1c>
    800043ac:	37fd                	addiw	a5,a5,-1
    800043ae:	04f65e63          	bge	a2,a5,8000440a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043b2:	00024797          	auipc	a5,0x24
    800043b6:	ede7a783          	lw	a5,-290(a5) # 80028290 <log+0x20>
    800043ba:	06f05063          	blez	a5,8000441a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043be:	4781                	li	a5,0
    800043c0:	06c05563          	blez	a2,8000442a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043c4:	44cc                	lw	a1,12(s1)
    800043c6:	00024717          	auipc	a4,0x24
    800043ca:	eda70713          	addi	a4,a4,-294 # 800282a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043d0:	4314                	lw	a3,0(a4)
    800043d2:	04b68c63          	beq	a3,a1,8000442a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043d6:	2785                	addiw	a5,a5,1
    800043d8:	0711                	addi	a4,a4,4
    800043da:	fef61be3          	bne	a2,a5,800043d0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043de:	0621                	addi	a2,a2,8
    800043e0:	060a                	slli	a2,a2,0x2
    800043e2:	00024797          	auipc	a5,0x24
    800043e6:	e8e78793          	addi	a5,a5,-370 # 80028270 <log>
    800043ea:	963e                	add	a2,a2,a5
    800043ec:	44dc                	lw	a5,12(s1)
    800043ee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043f0:	8526                	mv	a0,s1
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	d98080e7          	jalr	-616(ra) # 8000318a <bpin>
    log.lh.n++;
    800043fa:	00024717          	auipc	a4,0x24
    800043fe:	e7670713          	addi	a4,a4,-394 # 80028270 <log>
    80004402:	575c                	lw	a5,44(a4)
    80004404:	2785                	addiw	a5,a5,1
    80004406:	d75c                	sw	a5,44(a4)
    80004408:	a835                	j	80004444 <log_write+0xca>
    panic("too big a transaction");
    8000440a:	00008517          	auipc	a0,0x8
    8000440e:	4c650513          	addi	a0,a0,1222 # 8000c8d0 <syscalls+0x208>
    80004412:	ffffc097          	auipc	ra,0xffffc
    80004416:	12c080e7          	jalr	300(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000441a:	00008517          	auipc	a0,0x8
    8000441e:	4ce50513          	addi	a0,a0,1230 # 8000c8e8 <syscalls+0x220>
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	11c080e7          	jalr	284(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000442a:	00878713          	addi	a4,a5,8
    8000442e:	00271693          	slli	a3,a4,0x2
    80004432:	00024717          	auipc	a4,0x24
    80004436:	e3e70713          	addi	a4,a4,-450 # 80028270 <log>
    8000443a:	9736                	add	a4,a4,a3
    8000443c:	44d4                	lw	a3,12(s1)
    8000443e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004440:	faf608e3          	beq	a2,a5,800043f0 <log_write+0x76>
  }
  release(&log.lock);
    80004444:	00024517          	auipc	a0,0x24
    80004448:	e2c50513          	addi	a0,a0,-468 # 80028270 <log>
    8000444c:	ffffd097          	auipc	ra,0xffffd
    80004450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
}
    80004454:	60e2                	ld	ra,24(sp)
    80004456:	6442                	ld	s0,16(sp)
    80004458:	64a2                	ld	s1,8(sp)
    8000445a:	6902                	ld	s2,0(sp)
    8000445c:	6105                	addi	sp,sp,32
    8000445e:	8082                	ret

0000000080004460 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004460:	1101                	addi	sp,sp,-32
    80004462:	ec06                	sd	ra,24(sp)
    80004464:	e822                	sd	s0,16(sp)
    80004466:	e426                	sd	s1,8(sp)
    80004468:	e04a                	sd	s2,0(sp)
    8000446a:	1000                	addi	s0,sp,32
    8000446c:	84aa                	mv	s1,a0
    8000446e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004470:	00008597          	auipc	a1,0x8
    80004474:	49858593          	addi	a1,a1,1176 # 8000c908 <syscalls+0x240>
    80004478:	0521                	addi	a0,a0,8
    8000447a:	ffffc097          	auipc	ra,0xffffc
    8000447e:	6da080e7          	jalr	1754(ra) # 80000b54 <initlock>
  lk->name = name;
    80004482:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004486:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000448a:	0204a423          	sw	zero,40(s1)
}
    8000448e:	60e2                	ld	ra,24(sp)
    80004490:	6442                	ld	s0,16(sp)
    80004492:	64a2                	ld	s1,8(sp)
    80004494:	6902                	ld	s2,0(sp)
    80004496:	6105                	addi	sp,sp,32
    80004498:	8082                	ret

000000008000449a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000449a:	1101                	addi	sp,sp,-32
    8000449c:	ec06                	sd	ra,24(sp)
    8000449e:	e822                	sd	s0,16(sp)
    800044a0:	e426                	sd	s1,8(sp)
    800044a2:	e04a                	sd	s2,0(sp)
    800044a4:	1000                	addi	s0,sp,32
    800044a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a8:	00850913          	addi	s2,a0,8
    800044ac:	854a                	mv	a0,s2
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800044b6:	409c                	lw	a5,0(s1)
    800044b8:	cb89                	beqz	a5,800044ca <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044ba:	85ca                	mv	a1,s2
    800044bc:	8526                	mv	a0,s1
    800044be:	ffffe097          	auipc	ra,0xffffe
    800044c2:	d82080e7          	jalr	-638(ra) # 80002240 <sleep>
  while (lk->locked) {
    800044c6:	409c                	lw	a5,0(s1)
    800044c8:	fbed                	bnez	a5,800044ba <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ca:	4785                	li	a5,1
    800044cc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ce:	ffffd097          	auipc	ra,0xffffd
    800044d2:	682080e7          	jalr	1666(ra) # 80001b50 <myproc>
    800044d6:	591c                	lw	a5,48(a0)
    800044d8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044da:	854a                	mv	a0,s2
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7bc080e7          	jalr	1980(ra) # 80000c98 <release>
}
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6902                	ld	s2,0(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret

00000000800044f0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044f0:	1101                	addi	sp,sp,-32
    800044f2:	ec06                	sd	ra,24(sp)
    800044f4:	e822                	sd	s0,16(sp)
    800044f6:	e426                	sd	s1,8(sp)
    800044f8:	e04a                	sd	s2,0(sp)
    800044fa:	1000                	addi	s0,sp,32
    800044fc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044fe:	00850913          	addi	s2,a0,8
    80004502:	854a                	mv	a0,s2
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000450c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004510:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004514:	8526                	mv	a0,s1
    80004516:	ffffe097          	auipc	ra,0xffffe
    8000451a:	eb6080e7          	jalr	-330(ra) # 800023cc <wakeup>
  release(&lk->lk);
    8000451e:	854a                	mv	a0,s2
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	778080e7          	jalr	1912(ra) # 80000c98 <release>
}
    80004528:	60e2                	ld	ra,24(sp)
    8000452a:	6442                	ld	s0,16(sp)
    8000452c:	64a2                	ld	s1,8(sp)
    8000452e:	6902                	ld	s2,0(sp)
    80004530:	6105                	addi	sp,sp,32
    80004532:	8082                	ret

0000000080004534 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004534:	7179                	addi	sp,sp,-48
    80004536:	f406                	sd	ra,40(sp)
    80004538:	f022                	sd	s0,32(sp)
    8000453a:	ec26                	sd	s1,24(sp)
    8000453c:	e84a                	sd	s2,16(sp)
    8000453e:	e44e                	sd	s3,8(sp)
    80004540:	1800                	addi	s0,sp,48
    80004542:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004544:	00850913          	addi	s2,a0,8
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	69a080e7          	jalr	1690(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004552:	409c                	lw	a5,0(s1)
    80004554:	ef99                	bnez	a5,80004572 <holdingsleep+0x3e>
    80004556:	4481                	li	s1,0
  release(&lk->lk);
    80004558:	854a                	mv	a0,s2
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	73e080e7          	jalr	1854(ra) # 80000c98 <release>
  return r;
}
    80004562:	8526                	mv	a0,s1
    80004564:	70a2                	ld	ra,40(sp)
    80004566:	7402                	ld	s0,32(sp)
    80004568:	64e2                	ld	s1,24(sp)
    8000456a:	6942                	ld	s2,16(sp)
    8000456c:	69a2                	ld	s3,8(sp)
    8000456e:	6145                	addi	sp,sp,48
    80004570:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004572:	0284a983          	lw	s3,40(s1)
    80004576:	ffffd097          	auipc	ra,0xffffd
    8000457a:	5da080e7          	jalr	1498(ra) # 80001b50 <myproc>
    8000457e:	5904                	lw	s1,48(a0)
    80004580:	413484b3          	sub	s1,s1,s3
    80004584:	0014b493          	seqz	s1,s1
    80004588:	bfc1                	j	80004558 <holdingsleep+0x24>

000000008000458a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000458a:	1141                	addi	sp,sp,-16
    8000458c:	e406                	sd	ra,8(sp)
    8000458e:	e022                	sd	s0,0(sp)
    80004590:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004592:	00008597          	auipc	a1,0x8
    80004596:	38658593          	addi	a1,a1,902 # 8000c918 <syscalls+0x250>
    8000459a:	00024517          	auipc	a0,0x24
    8000459e:	e1e50513          	addi	a0,a0,-482 # 800283b8 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	5b2080e7          	jalr	1458(ra) # 80000b54 <initlock>
}
    800045aa:	60a2                	ld	ra,8(sp)
    800045ac:	6402                	ld	s0,0(sp)
    800045ae:	0141                	addi	sp,sp,16
    800045b0:	8082                	ret

00000000800045b2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045bc:	00024517          	auipc	a0,0x24
    800045c0:	dfc50513          	addi	a0,a0,-516 # 800283b8 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	620080e7          	jalr	1568(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045cc:	00024497          	auipc	s1,0x24
    800045d0:	e0448493          	addi	s1,s1,-508 # 800283d0 <ftable+0x18>
    800045d4:	00025717          	auipc	a4,0x25
    800045d8:	d9c70713          	addi	a4,a4,-612 # 80029370 <ftable+0xfb8>
    if(f->ref == 0){
    800045dc:	40dc                	lw	a5,4(s1)
    800045de:	cf99                	beqz	a5,800045fc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045e0:	02848493          	addi	s1,s1,40
    800045e4:	fee49ce3          	bne	s1,a4,800045dc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045e8:	00024517          	auipc	a0,0x24
    800045ec:	dd050513          	addi	a0,a0,-560 # 800283b8 <ftable>
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	6a8080e7          	jalr	1704(ra) # 80000c98 <release>
  return 0;
    800045f8:	4481                	li	s1,0
    800045fa:	a819                	j	80004610 <filealloc+0x5e>
      f->ref = 1;
    800045fc:	4785                	li	a5,1
    800045fe:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004600:	00024517          	auipc	a0,0x24
    80004604:	db850513          	addi	a0,a0,-584 # 800283b8 <ftable>
    80004608:	ffffc097          	auipc	ra,0xffffc
    8000460c:	690080e7          	jalr	1680(ra) # 80000c98 <release>
}
    80004610:	8526                	mv	a0,s1
    80004612:	60e2                	ld	ra,24(sp)
    80004614:	6442                	ld	s0,16(sp)
    80004616:	64a2                	ld	s1,8(sp)
    80004618:	6105                	addi	sp,sp,32
    8000461a:	8082                	ret

000000008000461c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000461c:	1101                	addi	sp,sp,-32
    8000461e:	ec06                	sd	ra,24(sp)
    80004620:	e822                	sd	s0,16(sp)
    80004622:	e426                	sd	s1,8(sp)
    80004624:	1000                	addi	s0,sp,32
    80004626:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004628:	00024517          	auipc	a0,0x24
    8000462c:	d9050513          	addi	a0,a0,-624 # 800283b8 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004638:	40dc                	lw	a5,4(s1)
    8000463a:	02f05263          	blez	a5,8000465e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000463e:	2785                	addiw	a5,a5,1
    80004640:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004642:	00024517          	auipc	a0,0x24
    80004646:	d7650513          	addi	a0,a0,-650 # 800283b8 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	64e080e7          	jalr	1614(ra) # 80000c98 <release>
  return f;
}
    80004652:	8526                	mv	a0,s1
    80004654:	60e2                	ld	ra,24(sp)
    80004656:	6442                	ld	s0,16(sp)
    80004658:	64a2                	ld	s1,8(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret
    panic("filedup");
    8000465e:	00008517          	auipc	a0,0x8
    80004662:	2c250513          	addi	a0,a0,706 # 8000c920 <syscalls+0x258>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>

000000008000466e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000466e:	7139                	addi	sp,sp,-64
    80004670:	fc06                	sd	ra,56(sp)
    80004672:	f822                	sd	s0,48(sp)
    80004674:	f426                	sd	s1,40(sp)
    80004676:	f04a                	sd	s2,32(sp)
    80004678:	ec4e                	sd	s3,24(sp)
    8000467a:	e852                	sd	s4,16(sp)
    8000467c:	e456                	sd	s5,8(sp)
    8000467e:	0080                	addi	s0,sp,64
    80004680:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004682:	00024517          	auipc	a0,0x24
    80004686:	d3650513          	addi	a0,a0,-714 # 800283b8 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	55a080e7          	jalr	1370(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004692:	40dc                	lw	a5,4(s1)
    80004694:	06f05163          	blez	a5,800046f6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004698:	37fd                	addiw	a5,a5,-1
    8000469a:	0007871b          	sext.w	a4,a5
    8000469e:	c0dc                	sw	a5,4(s1)
    800046a0:	06e04363          	bgtz	a4,80004706 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046a4:	0004a903          	lw	s2,0(s1)
    800046a8:	0094ca83          	lbu	s5,9(s1)
    800046ac:	0104ba03          	ld	s4,16(s1)
    800046b0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046b4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046bc:	00024517          	auipc	a0,0x24
    800046c0:	cfc50513          	addi	a0,a0,-772 # 800283b8 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	5d4080e7          	jalr	1492(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800046cc:	4785                	li	a5,1
    800046ce:	04f90d63          	beq	s2,a5,80004728 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046d2:	3979                	addiw	s2,s2,-2
    800046d4:	4785                	li	a5,1
    800046d6:	0527e063          	bltu	a5,s2,80004716 <fileclose+0xa8>
    begin_op();
    800046da:	00000097          	auipc	ra,0x0
    800046de:	ac8080e7          	jalr	-1336(ra) # 800041a2 <begin_op>
    iput(ff.ip);
    800046e2:	854e                	mv	a0,s3
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	2a6080e7          	jalr	678(ra) # 8000398a <iput>
    end_op();
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	b36080e7          	jalr	-1226(ra) # 80004222 <end_op>
    800046f4:	a00d                	j	80004716 <fileclose+0xa8>
    panic("fileclose");
    800046f6:	00008517          	auipc	a0,0x8
    800046fa:	23250513          	addi	a0,a0,562 # 8000c928 <syscalls+0x260>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004706:	00024517          	auipc	a0,0x24
    8000470a:	cb250513          	addi	a0,a0,-846 # 800283b8 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	58a080e7          	jalr	1418(ra) # 80000c98 <release>
  }
}
    80004716:	70e2                	ld	ra,56(sp)
    80004718:	7442                	ld	s0,48(sp)
    8000471a:	74a2                	ld	s1,40(sp)
    8000471c:	7902                	ld	s2,32(sp)
    8000471e:	69e2                	ld	s3,24(sp)
    80004720:	6a42                	ld	s4,16(sp)
    80004722:	6aa2                	ld	s5,8(sp)
    80004724:	6121                	addi	sp,sp,64
    80004726:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004728:	85d6                	mv	a1,s5
    8000472a:	8552                	mv	a0,s4
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	34c080e7          	jalr	844(ra) # 80004a78 <pipeclose>
    80004734:	b7cd                	j	80004716 <fileclose+0xa8>

0000000080004736 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004736:	715d                	addi	sp,sp,-80
    80004738:	e486                	sd	ra,72(sp)
    8000473a:	e0a2                	sd	s0,64(sp)
    8000473c:	fc26                	sd	s1,56(sp)
    8000473e:	f84a                	sd	s2,48(sp)
    80004740:	f44e                	sd	s3,40(sp)
    80004742:	0880                	addi	s0,sp,80
    80004744:	84aa                	mv	s1,a0
    80004746:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004748:	ffffd097          	auipc	ra,0xffffd
    8000474c:	408080e7          	jalr	1032(ra) # 80001b50 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004750:	409c                	lw	a5,0(s1)
    80004752:	37f9                	addiw	a5,a5,-2
    80004754:	4705                	li	a4,1
    80004756:	04f76763          	bltu	a4,a5,800047a4 <filestat+0x6e>
    8000475a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000475c:	6c88                	ld	a0,24(s1)
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	072080e7          	jalr	114(ra) # 800037d0 <ilock>
    stati(f->ip, &st);
    80004766:	fb840593          	addi	a1,s0,-72
    8000476a:	6c88                	ld	a0,24(s1)
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	2ee080e7          	jalr	750(ra) # 80003a5a <stati>
    iunlock(f->ip);
    80004774:	6c88                	ld	a0,24(s1)
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	11c080e7          	jalr	284(ra) # 80003892 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000477e:	46e1                	li	a3,24
    80004780:	fb840613          	addi	a2,s0,-72
    80004784:	85ce                	mv	a1,s3
    80004786:	05093503          	ld	a0,80(s2)
    8000478a:	ffffd097          	auipc	ra,0xffffd
    8000478e:	088080e7          	jalr	136(ra) # 80001812 <copyout>
    80004792:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004796:	60a6                	ld	ra,72(sp)
    80004798:	6406                	ld	s0,64(sp)
    8000479a:	74e2                	ld	s1,56(sp)
    8000479c:	7942                	ld	s2,48(sp)
    8000479e:	79a2                	ld	s3,40(sp)
    800047a0:	6161                	addi	sp,sp,80
    800047a2:	8082                	ret
  return -1;
    800047a4:	557d                	li	a0,-1
    800047a6:	bfc5                	j	80004796 <filestat+0x60>

00000000800047a8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a8:	7179                	addi	sp,sp,-48
    800047aa:	f406                	sd	ra,40(sp)
    800047ac:	f022                	sd	s0,32(sp)
    800047ae:	ec26                	sd	s1,24(sp)
    800047b0:	e84a                	sd	s2,16(sp)
    800047b2:	e44e                	sd	s3,8(sp)
    800047b4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b6:	00854783          	lbu	a5,8(a0)
    800047ba:	c3d5                	beqz	a5,8000485e <fileread+0xb6>
    800047bc:	84aa                	mv	s1,a0
    800047be:	89ae                	mv	s3,a1
    800047c0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c2:	411c                	lw	a5,0(a0)
    800047c4:	4705                	li	a4,1
    800047c6:	04e78963          	beq	a5,a4,80004818 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ca:	470d                	li	a4,3
    800047cc:	04e78d63          	beq	a5,a4,80004826 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d0:	4709                	li	a4,2
    800047d2:	06e79e63          	bne	a5,a4,8000484e <fileread+0xa6>
    ilock(f->ip);
    800047d6:	6d08                	ld	a0,24(a0)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	ff8080e7          	jalr	-8(ra) # 800037d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047e0:	874a                	mv	a4,s2
    800047e2:	5094                	lw	a3,32(s1)
    800047e4:	864e                	mv	a2,s3
    800047e6:	4585                	li	a1,1
    800047e8:	6c88                	ld	a0,24(s1)
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	29a080e7          	jalr	666(ra) # 80003a84 <readi>
    800047f2:	892a                	mv	s2,a0
    800047f4:	00a05563          	blez	a0,800047fe <fileread+0x56>
      f->off += r;
    800047f8:	509c                	lw	a5,32(s1)
    800047fa:	9fa9                	addw	a5,a5,a0
    800047fc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047fe:	6c88                	ld	a0,24(s1)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	092080e7          	jalr	146(ra) # 80003892 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004808:	854a                	mv	a0,s2
    8000480a:	70a2                	ld	ra,40(sp)
    8000480c:	7402                	ld	s0,32(sp)
    8000480e:	64e2                	ld	s1,24(sp)
    80004810:	6942                	ld	s2,16(sp)
    80004812:	69a2                	ld	s3,8(sp)
    80004814:	6145                	addi	sp,sp,48
    80004816:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004818:	6908                	ld	a0,16(a0)
    8000481a:	00000097          	auipc	ra,0x0
    8000481e:	3c8080e7          	jalr	968(ra) # 80004be2 <piperead>
    80004822:	892a                	mv	s2,a0
    80004824:	b7d5                	j	80004808 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004826:	02451783          	lh	a5,36(a0)
    8000482a:	03079693          	slli	a3,a5,0x30
    8000482e:	92c1                	srli	a3,a3,0x30
    80004830:	4725                	li	a4,9
    80004832:	02d76863          	bltu	a4,a3,80004862 <fileread+0xba>
    80004836:	0792                	slli	a5,a5,0x4
    80004838:	00024717          	auipc	a4,0x24
    8000483c:	ae070713          	addi	a4,a4,-1312 # 80028318 <devsw>
    80004840:	97ba                	add	a5,a5,a4
    80004842:	639c                	ld	a5,0(a5)
    80004844:	c38d                	beqz	a5,80004866 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004846:	4505                	li	a0,1
    80004848:	9782                	jalr	a5
    8000484a:	892a                	mv	s2,a0
    8000484c:	bf75                	j	80004808 <fileread+0x60>
    panic("fileread");
    8000484e:	00008517          	auipc	a0,0x8
    80004852:	0ea50513          	addi	a0,a0,234 # 8000c938 <syscalls+0x270>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
    return -1;
    8000485e:	597d                	li	s2,-1
    80004860:	b765                	j	80004808 <fileread+0x60>
      return -1;
    80004862:	597d                	li	s2,-1
    80004864:	b755                	j	80004808 <fileread+0x60>
    80004866:	597d                	li	s2,-1
    80004868:	b745                	j	80004808 <fileread+0x60>

000000008000486a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000486a:	715d                	addi	sp,sp,-80
    8000486c:	e486                	sd	ra,72(sp)
    8000486e:	e0a2                	sd	s0,64(sp)
    80004870:	fc26                	sd	s1,56(sp)
    80004872:	f84a                	sd	s2,48(sp)
    80004874:	f44e                	sd	s3,40(sp)
    80004876:	f052                	sd	s4,32(sp)
    80004878:	ec56                	sd	s5,24(sp)
    8000487a:	e85a                	sd	s6,16(sp)
    8000487c:	e45e                	sd	s7,8(sp)
    8000487e:	e062                	sd	s8,0(sp)
    80004880:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004882:	00954783          	lbu	a5,9(a0)
    80004886:	10078663          	beqz	a5,80004992 <filewrite+0x128>
    8000488a:	892a                	mv	s2,a0
    8000488c:	8aae                	mv	s5,a1
    8000488e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004890:	411c                	lw	a5,0(a0)
    80004892:	4705                	li	a4,1
    80004894:	02e78263          	beq	a5,a4,800048b8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004898:	470d                	li	a4,3
    8000489a:	02e78663          	beq	a5,a4,800048c6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000489e:	4709                	li	a4,2
    800048a0:	0ee79163          	bne	a5,a4,80004982 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048a4:	0ac05d63          	blez	a2,8000495e <filewrite+0xf4>
    int i = 0;
    800048a8:	4981                	li	s3,0
    800048aa:	6b05                	lui	s6,0x1
    800048ac:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048b0:	6b85                	lui	s7,0x1
    800048b2:	c00b8b9b          	addiw	s7,s7,-1024
    800048b6:	a861                	j	8000494e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048b8:	6908                	ld	a0,16(a0)
    800048ba:	00000097          	auipc	ra,0x0
    800048be:	22e080e7          	jalr	558(ra) # 80004ae8 <pipewrite>
    800048c2:	8a2a                	mv	s4,a0
    800048c4:	a045                	j	80004964 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048c6:	02451783          	lh	a5,36(a0)
    800048ca:	03079693          	slli	a3,a5,0x30
    800048ce:	92c1                	srli	a3,a3,0x30
    800048d0:	4725                	li	a4,9
    800048d2:	0cd76263          	bltu	a4,a3,80004996 <filewrite+0x12c>
    800048d6:	0792                	slli	a5,a5,0x4
    800048d8:	00024717          	auipc	a4,0x24
    800048dc:	a4070713          	addi	a4,a4,-1472 # 80028318 <devsw>
    800048e0:	97ba                	add	a5,a5,a4
    800048e2:	679c                	ld	a5,8(a5)
    800048e4:	cbdd                	beqz	a5,8000499a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048e6:	4505                	li	a0,1
    800048e8:	9782                	jalr	a5
    800048ea:	8a2a                	mv	s4,a0
    800048ec:	a8a5                	j	80004964 <filewrite+0xfa>
    800048ee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	8b0080e7          	jalr	-1872(ra) # 800041a2 <begin_op>
      ilock(f->ip);
    800048fa:	01893503          	ld	a0,24(s2)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	ed2080e7          	jalr	-302(ra) # 800037d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004906:	8762                	mv	a4,s8
    80004908:	02092683          	lw	a3,32(s2)
    8000490c:	01598633          	add	a2,s3,s5
    80004910:	4585                	li	a1,1
    80004912:	01893503          	ld	a0,24(s2)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	266080e7          	jalr	614(ra) # 80003b7c <writei>
    8000491e:	84aa                	mv	s1,a0
    80004920:	00a05763          	blez	a0,8000492e <filewrite+0xc4>
        f->off += r;
    80004924:	02092783          	lw	a5,32(s2)
    80004928:	9fa9                	addw	a5,a5,a0
    8000492a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000492e:	01893503          	ld	a0,24(s2)
    80004932:	fffff097          	auipc	ra,0xfffff
    80004936:	f60080e7          	jalr	-160(ra) # 80003892 <iunlock>
      end_op();
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	8e8080e7          	jalr	-1816(ra) # 80004222 <end_op>

      if(r != n1){
    80004942:	009c1f63          	bne	s8,s1,80004960 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004946:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000494a:	0149db63          	bge	s3,s4,80004960 <filewrite+0xf6>
      int n1 = n - i;
    8000494e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004952:	84be                	mv	s1,a5
    80004954:	2781                	sext.w	a5,a5
    80004956:	f8fb5ce3          	bge	s6,a5,800048ee <filewrite+0x84>
    8000495a:	84de                	mv	s1,s7
    8000495c:	bf49                	j	800048ee <filewrite+0x84>
    int i = 0;
    8000495e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004960:	013a1f63          	bne	s4,s3,8000497e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004964:	8552                	mv	a0,s4
    80004966:	60a6                	ld	ra,72(sp)
    80004968:	6406                	ld	s0,64(sp)
    8000496a:	74e2                	ld	s1,56(sp)
    8000496c:	7942                	ld	s2,48(sp)
    8000496e:	79a2                	ld	s3,40(sp)
    80004970:	7a02                	ld	s4,32(sp)
    80004972:	6ae2                	ld	s5,24(sp)
    80004974:	6b42                	ld	s6,16(sp)
    80004976:	6ba2                	ld	s7,8(sp)
    80004978:	6c02                	ld	s8,0(sp)
    8000497a:	6161                	addi	sp,sp,80
    8000497c:	8082                	ret
    ret = (i == n ? n : -1);
    8000497e:	5a7d                	li	s4,-1
    80004980:	b7d5                	j	80004964 <filewrite+0xfa>
    panic("filewrite");
    80004982:	00008517          	auipc	a0,0x8
    80004986:	fc650513          	addi	a0,a0,-58 # 8000c948 <syscalls+0x280>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>
    return -1;
    80004992:	5a7d                	li	s4,-1
    80004994:	bfc1                	j	80004964 <filewrite+0xfa>
      return -1;
    80004996:	5a7d                	li	s4,-1
    80004998:	b7f1                	j	80004964 <filewrite+0xfa>
    8000499a:	5a7d                	li	s4,-1
    8000499c:	b7e1                	j	80004964 <filewrite+0xfa>

000000008000499e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000499e:	7179                	addi	sp,sp,-48
    800049a0:	f406                	sd	ra,40(sp)
    800049a2:	f022                	sd	s0,32(sp)
    800049a4:	ec26                	sd	s1,24(sp)
    800049a6:	e84a                	sd	s2,16(sp)
    800049a8:	e44e                	sd	s3,8(sp)
    800049aa:	e052                	sd	s4,0(sp)
    800049ac:	1800                	addi	s0,sp,48
    800049ae:	84aa                	mv	s1,a0
    800049b0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049b2:	0005b023          	sd	zero,0(a1)
    800049b6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	bf8080e7          	jalr	-1032(ra) # 800045b2 <filealloc>
    800049c2:	e088                	sd	a0,0(s1)
    800049c4:	c551                	beqz	a0,80004a50 <pipealloc+0xb2>
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	bec080e7          	jalr	-1044(ra) # 800045b2 <filealloc>
    800049ce:	00aa3023          	sd	a0,0(s4)
    800049d2:	c92d                	beqz	a0,80004a44 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	120080e7          	jalr	288(ra) # 80000af4 <kalloc>
    800049dc:	892a                	mv	s2,a0
    800049de:	c125                	beqz	a0,80004a3e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049e0:	4985                	li	s3,1
    800049e2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049e6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049ee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049f2:	00008597          	auipc	a1,0x8
    800049f6:	f6658593          	addi	a1,a1,-154 # 8000c958 <syscalls+0x290>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	15a080e7          	jalr	346(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004a02:	609c                	ld	a5,0(s1)
    80004a04:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a08:	609c                	ld	a5,0(s1)
    80004a0a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a0e:	609c                	ld	a5,0(s1)
    80004a10:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a14:	609c                	ld	a5,0(s1)
    80004a16:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a1a:	000a3783          	ld	a5,0(s4)
    80004a1e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a22:	000a3783          	ld	a5,0(s4)
    80004a26:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a2a:	000a3783          	ld	a5,0(s4)
    80004a2e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a32:	000a3783          	ld	a5,0(s4)
    80004a36:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a3a:	4501                	li	a0,0
    80004a3c:	a025                	j	80004a64 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a3e:	6088                	ld	a0,0(s1)
    80004a40:	e501                	bnez	a0,80004a48 <pipealloc+0xaa>
    80004a42:	a039                	j	80004a50 <pipealloc+0xb2>
    80004a44:	6088                	ld	a0,0(s1)
    80004a46:	c51d                	beqz	a0,80004a74 <pipealloc+0xd6>
    fileclose(*f0);
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	c26080e7          	jalr	-986(ra) # 8000466e <fileclose>
  if(*f1)
    80004a50:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a54:	557d                	li	a0,-1
  if(*f1)
    80004a56:	c799                	beqz	a5,80004a64 <pipealloc+0xc6>
    fileclose(*f1);
    80004a58:	853e                	mv	a0,a5
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	c14080e7          	jalr	-1004(ra) # 8000466e <fileclose>
  return -1;
    80004a62:	557d                	li	a0,-1
}
    80004a64:	70a2                	ld	ra,40(sp)
    80004a66:	7402                	ld	s0,32(sp)
    80004a68:	64e2                	ld	s1,24(sp)
    80004a6a:	6942                	ld	s2,16(sp)
    80004a6c:	69a2                	ld	s3,8(sp)
    80004a6e:	6a02                	ld	s4,0(sp)
    80004a70:	6145                	addi	sp,sp,48
    80004a72:	8082                	ret
  return -1;
    80004a74:	557d                	li	a0,-1
    80004a76:	b7fd                	j	80004a64 <pipealloc+0xc6>

0000000080004a78 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a78:	1101                	addi	sp,sp,-32
    80004a7a:	ec06                	sd	ra,24(sp)
    80004a7c:	e822                	sd	s0,16(sp)
    80004a7e:	e426                	sd	s1,8(sp)
    80004a80:	e04a                	sd	s2,0(sp)
    80004a82:	1000                	addi	s0,sp,32
    80004a84:	84aa                	mv	s1,a0
    80004a86:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	15c080e7          	jalr	348(ra) # 80000be4 <acquire>
  if(writable){
    80004a90:	02090d63          	beqz	s2,80004aca <pipeclose+0x52>
    pi->writeopen = 0;
    80004a94:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a98:	21848513          	addi	a0,s1,536
    80004a9c:	ffffe097          	auipc	ra,0xffffe
    80004aa0:	930080e7          	jalr	-1744(ra) # 800023cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aa4:	2204b783          	ld	a5,544(s1)
    80004aa8:	eb95                	bnez	a5,80004adc <pipeclose+0x64>
    release(&pi->lock);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1ec080e7          	jalr	492(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ab4:	8526                	mv	a0,s1
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	f42080e7          	jalr	-190(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004abe:	60e2                	ld	ra,24(sp)
    80004ac0:	6442                	ld	s0,16(sp)
    80004ac2:	64a2                	ld	s1,8(sp)
    80004ac4:	6902                	ld	s2,0(sp)
    80004ac6:	6105                	addi	sp,sp,32
    80004ac8:	8082                	ret
    pi->readopen = 0;
    80004aca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ace:	21c48513          	addi	a0,s1,540
    80004ad2:	ffffe097          	auipc	ra,0xffffe
    80004ad6:	8fa080e7          	jalr	-1798(ra) # 800023cc <wakeup>
    80004ada:	b7e9                	j	80004aa4 <pipeclose+0x2c>
    release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
}
    80004ae6:	bfe1                	j	80004abe <pipeclose+0x46>

0000000080004ae8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae8:	7159                	addi	sp,sp,-112
    80004aea:	f486                	sd	ra,104(sp)
    80004aec:	f0a2                	sd	s0,96(sp)
    80004aee:	eca6                	sd	s1,88(sp)
    80004af0:	e8ca                	sd	s2,80(sp)
    80004af2:	e4ce                	sd	s3,72(sp)
    80004af4:	e0d2                	sd	s4,64(sp)
    80004af6:	fc56                	sd	s5,56(sp)
    80004af8:	f85a                	sd	s6,48(sp)
    80004afa:	f45e                	sd	s7,40(sp)
    80004afc:	f062                	sd	s8,32(sp)
    80004afe:	ec66                	sd	s9,24(sp)
    80004b00:	1880                	addi	s0,sp,112
    80004b02:	84aa                	mv	s1,a0
    80004b04:	8aae                	mv	s5,a1
    80004b06:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	048080e7          	jalr	72(ra) # 80001b50 <myproc>
    80004b10:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	0d0080e7          	jalr	208(ra) # 80000be4 <acquire>
  while(i < n){
    80004b1c:	0d405163          	blez	s4,80004bde <pipewrite+0xf6>
    80004b20:	8ba6                	mv	s7,s1
  int i = 0;
    80004b22:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b24:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b26:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b2a:	21c48c13          	addi	s8,s1,540
    80004b2e:	a08d                	j	80004b90 <pipewrite+0xa8>
      release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
      return -1;
    80004b3a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b3c:	854a                	mv	a0,s2
    80004b3e:	70a6                	ld	ra,104(sp)
    80004b40:	7406                	ld	s0,96(sp)
    80004b42:	64e6                	ld	s1,88(sp)
    80004b44:	6946                	ld	s2,80(sp)
    80004b46:	69a6                	ld	s3,72(sp)
    80004b48:	6a06                	ld	s4,64(sp)
    80004b4a:	7ae2                	ld	s5,56(sp)
    80004b4c:	7b42                	ld	s6,48(sp)
    80004b4e:	7ba2                	ld	s7,40(sp)
    80004b50:	7c02                	ld	s8,32(sp)
    80004b52:	6ce2                	ld	s9,24(sp)
    80004b54:	6165                	addi	sp,sp,112
    80004b56:	8082                	ret
      wakeup(&pi->nread);
    80004b58:	8566                	mv	a0,s9
    80004b5a:	ffffe097          	auipc	ra,0xffffe
    80004b5e:	872080e7          	jalr	-1934(ra) # 800023cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b62:	85de                	mv	a1,s7
    80004b64:	8562                	mv	a0,s8
    80004b66:	ffffd097          	auipc	ra,0xffffd
    80004b6a:	6da080e7          	jalr	1754(ra) # 80002240 <sleep>
    80004b6e:	a839                	j	80004b8c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	20e4ae23          	sw	a4,540(s1)
    80004b7c:	1ff7f793          	andi	a5,a5,511
    80004b80:	97a6                	add	a5,a5,s1
    80004b82:	f9f44703          	lbu	a4,-97(s0)
    80004b86:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b8a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b8c:	03495d63          	bge	s2,s4,80004bc6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b90:	2204a783          	lw	a5,544(s1)
    80004b94:	dfd1                	beqz	a5,80004b30 <pipewrite+0x48>
    80004b96:	0289a783          	lw	a5,40(s3)
    80004b9a:	fbd9                	bnez	a5,80004b30 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b9c:	2184a783          	lw	a5,536(s1)
    80004ba0:	21c4a703          	lw	a4,540(s1)
    80004ba4:	2007879b          	addiw	a5,a5,512
    80004ba8:	faf708e3          	beq	a4,a5,80004b58 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bac:	4685                	li	a3,1
    80004bae:	01590633          	add	a2,s2,s5
    80004bb2:	f9f40593          	addi	a1,s0,-97
    80004bb6:	0509b503          	ld	a0,80(s3)
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	ce4080e7          	jalr	-796(ra) # 8000189e <copyin>
    80004bc2:	fb6517e3          	bne	a0,s6,80004b70 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bc6:	21848513          	addi	a0,s1,536
    80004bca:	ffffe097          	auipc	ra,0xffffe
    80004bce:	802080e7          	jalr	-2046(ra) # 800023cc <wakeup>
  release(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	0c4080e7          	jalr	196(ra) # 80000c98 <release>
  return i;
    80004bdc:	b785                	j	80004b3c <pipewrite+0x54>
  int i = 0;
    80004bde:	4901                	li	s2,0
    80004be0:	b7dd                	j	80004bc6 <pipewrite+0xde>

0000000080004be2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004be2:	715d                	addi	sp,sp,-80
    80004be4:	e486                	sd	ra,72(sp)
    80004be6:	e0a2                	sd	s0,64(sp)
    80004be8:	fc26                	sd	s1,56(sp)
    80004bea:	f84a                	sd	s2,48(sp)
    80004bec:	f44e                	sd	s3,40(sp)
    80004bee:	f052                	sd	s4,32(sp)
    80004bf0:	ec56                	sd	s5,24(sp)
    80004bf2:	e85a                	sd	s6,16(sp)
    80004bf4:	0880                	addi	s0,sp,80
    80004bf6:	84aa                	mv	s1,a0
    80004bf8:	892e                	mv	s2,a1
    80004bfa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	f54080e7          	jalr	-172(ra) # 80001b50 <myproc>
    80004c04:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c06:	8b26                	mv	s6,s1
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	fda080e7          	jalr	-38(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	2184a703          	lw	a4,536(s1)
    80004c16:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1e:	02f71463          	bne	a4,a5,80004c46 <piperead+0x64>
    80004c22:	2244a783          	lw	a5,548(s1)
    80004c26:	c385                	beqz	a5,80004c46 <piperead+0x64>
    if(pr->killed){
    80004c28:	028a2783          	lw	a5,40(s4)
    80004c2c:	ebc1                	bnez	a5,80004cbc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c2e:	85da                	mv	a1,s6
    80004c30:	854e                	mv	a0,s3
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	60e080e7          	jalr	1550(ra) # 80002240 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3a:	2184a703          	lw	a4,536(s1)
    80004c3e:	21c4a783          	lw	a5,540(s1)
    80004c42:	fef700e3          	beq	a4,a5,80004c22 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c46:	09505263          	blez	s5,80004cca <piperead+0xe8>
    80004c4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c4e:	2184a783          	lw	a5,536(s1)
    80004c52:	21c4a703          	lw	a4,540(s1)
    80004c56:	02f70d63          	beq	a4,a5,80004c90 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c5a:	0017871b          	addiw	a4,a5,1
    80004c5e:	20e4ac23          	sw	a4,536(s1)
    80004c62:	1ff7f793          	andi	a5,a5,511
    80004c66:	97a6                	add	a5,a5,s1
    80004c68:	0187c783          	lbu	a5,24(a5)
    80004c6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c70:	4685                	li	a3,1
    80004c72:	fbf40613          	addi	a2,s0,-65
    80004c76:	85ca                	mv	a1,s2
    80004c78:	050a3503          	ld	a0,80(s4)
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	b96080e7          	jalr	-1130(ra) # 80001812 <copyout>
    80004c84:	01650663          	beq	a0,s6,80004c90 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c88:	2985                	addiw	s3,s3,1
    80004c8a:	0905                	addi	s2,s2,1
    80004c8c:	fd3a91e3          	bne	s5,s3,80004c4e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c90:	21c48513          	addi	a0,s1,540
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	738080e7          	jalr	1848(ra) # 800023cc <wakeup>
  release(&pi->lock);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	ffa080e7          	jalr	-6(ra) # 80000c98 <release>
  return i;
}
    80004ca6:	854e                	mv	a0,s3
    80004ca8:	60a6                	ld	ra,72(sp)
    80004caa:	6406                	ld	s0,64(sp)
    80004cac:	74e2                	ld	s1,56(sp)
    80004cae:	7942                	ld	s2,48(sp)
    80004cb0:	79a2                	ld	s3,40(sp)
    80004cb2:	7a02                	ld	s4,32(sp)
    80004cb4:	6ae2                	ld	s5,24(sp)
    80004cb6:	6b42                	ld	s6,16(sp)
    80004cb8:	6161                	addi	sp,sp,80
    80004cba:	8082                	ret
      release(&pi->lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
      return -1;
    80004cc6:	59fd                	li	s3,-1
    80004cc8:	bff9                	j	80004ca6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cca:	4981                	li	s3,0
    80004ccc:	b7d1                	j	80004c90 <piperead+0xae>

0000000080004cce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cce:	df010113          	addi	sp,sp,-528
    80004cd2:	20113423          	sd	ra,520(sp)
    80004cd6:	20813023          	sd	s0,512(sp)
    80004cda:	ffa6                	sd	s1,504(sp)
    80004cdc:	fbca                	sd	s2,496(sp)
    80004cde:	f7ce                	sd	s3,488(sp)
    80004ce0:	f3d2                	sd	s4,480(sp)
    80004ce2:	efd6                	sd	s5,472(sp)
    80004ce4:	ebda                	sd	s6,464(sp)
    80004ce6:	e7de                	sd	s7,456(sp)
    80004ce8:	e3e2                	sd	s8,448(sp)
    80004cea:	ff66                	sd	s9,440(sp)
    80004cec:	fb6a                	sd	s10,432(sp)
    80004cee:	f76e                	sd	s11,424(sp)
    80004cf0:	0c00                	addi	s0,sp,528
    80004cf2:	84aa                	mv	s1,a0
    80004cf4:	dea43c23          	sd	a0,-520(s0)
    80004cf8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	e54080e7          	jalr	-428(ra) # 80001b50 <myproc>
    80004d04:	892a                	mv	s2,a0

  begin_op();
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	49c080e7          	jalr	1180(ra) # 800041a2 <begin_op>

  if((ip = namei(path)) == 0){
    80004d0e:	8526                	mv	a0,s1
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	276080e7          	jalr	630(ra) # 80003f86 <namei>
    80004d18:	c92d                	beqz	a0,80004d8a <exec+0xbc>
    80004d1a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	ab4080e7          	jalr	-1356(ra) # 800037d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d24:	04000713          	li	a4,64
    80004d28:	4681                	li	a3,0
    80004d2a:	e5040613          	addi	a2,s0,-432
    80004d2e:	4581                	li	a1,0
    80004d30:	8526                	mv	a0,s1
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	d52080e7          	jalr	-686(ra) # 80003a84 <readi>
    80004d3a:	04000793          	li	a5,64
    80004d3e:	00f51a63          	bne	a0,a5,80004d52 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d42:	e5042703          	lw	a4,-432(s0)
    80004d46:	464c47b7          	lui	a5,0x464c4
    80004d4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d4e:	04f70463          	beq	a4,a5,80004d96 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d52:	8526                	mv	a0,s1
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	cde080e7          	jalr	-802(ra) # 80003a32 <iunlockput>
    end_op();
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	4c6080e7          	jalr	1222(ra) # 80004222 <end_op>
  }
  return -1;
    80004d64:	557d                	li	a0,-1
}
    80004d66:	20813083          	ld	ra,520(sp)
    80004d6a:	20013403          	ld	s0,512(sp)
    80004d6e:	74fe                	ld	s1,504(sp)
    80004d70:	795e                	ld	s2,496(sp)
    80004d72:	79be                	ld	s3,488(sp)
    80004d74:	7a1e                	ld	s4,480(sp)
    80004d76:	6afe                	ld	s5,472(sp)
    80004d78:	6b5e                	ld	s6,464(sp)
    80004d7a:	6bbe                	ld	s7,456(sp)
    80004d7c:	6c1e                	ld	s8,448(sp)
    80004d7e:	7cfa                	ld	s9,440(sp)
    80004d80:	7d5a                	ld	s10,432(sp)
    80004d82:	7dba                	ld	s11,424(sp)
    80004d84:	21010113          	addi	sp,sp,528
    80004d88:	8082                	ret
    end_op();
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	498080e7          	jalr	1176(ra) # 80004222 <end_op>
    return -1;
    80004d92:	557d                	li	a0,-1
    80004d94:	bfc9                	j	80004d66 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d96:	854a                	mv	a0,s2
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	e7c080e7          	jalr	-388(ra) # 80001c14 <proc_pagetable>
    80004da0:	8baa                	mv	s7,a0
    80004da2:	d945                	beqz	a0,80004d52 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da4:	e7042983          	lw	s3,-400(s0)
    80004da8:	e8845783          	lhu	a5,-376(s0)
    80004dac:	c7ad                	beqz	a5,80004e16 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004db2:	6c91                	lui	s9,0x4
    80004db4:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004db8:	def43823          	sd	a5,-528(s0)
    80004dbc:	a42d                	j	80004fe6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dbe:	00008517          	auipc	a0,0x8
    80004dc2:	ba250513          	addi	a0,a0,-1118 # 8000c960 <syscalls+0x298>
    80004dc6:	ffffb097          	auipc	ra,0xffffb
    80004dca:	778080e7          	jalr	1912(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dce:	8756                	mv	a4,s5
    80004dd0:	012d86bb          	addw	a3,s11,s2
    80004dd4:	4581                	li	a1,0
    80004dd6:	8526                	mv	a0,s1
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	cac080e7          	jalr	-852(ra) # 80003a84 <readi>
    80004de0:	2501                	sext.w	a0,a0
    80004de2:	1aaa9963          	bne	s5,a0,80004f94 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004de6:	6791                	lui	a5,0x4
    80004de8:	0127893b          	addw	s2,a5,s2
    80004dec:	77f1                	lui	a5,0xffffc
    80004dee:	01478a3b          	addw	s4,a5,s4
    80004df2:	1f897163          	bgeu	s2,s8,80004fd4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004df6:	02091593          	slli	a1,s2,0x20
    80004dfa:	9181                	srli	a1,a1,0x20
    80004dfc:	95ea                	add	a1,a1,s10
    80004dfe:	855e                	mv	a0,s7
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	392080e7          	jalr	914(ra) # 80001192 <walkaddr>
    80004e08:	862a                	mv	a2,a0
    if(pa == 0)
    80004e0a:	d955                	beqz	a0,80004dbe <exec+0xf0>
      n = PGSIZE;
    80004e0c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e0e:	fd9a70e3          	bgeu	s4,s9,80004dce <exec+0x100>
      n = sz - i;
    80004e12:	8ad2                	mv	s5,s4
    80004e14:	bf6d                	j	80004dce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e16:	4901                	li	s2,0
  iunlockput(ip);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	c18080e7          	jalr	-1000(ra) # 80003a32 <iunlockput>
  end_op();
    80004e22:	fffff097          	auipc	ra,0xfffff
    80004e26:	400080e7          	jalr	1024(ra) # 80004222 <end_op>
  p = myproc();
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	d26080e7          	jalr	-730(ra) # 80001b50 <myproc>
    80004e32:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e34:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e38:	6791                	lui	a5,0x4
    80004e3a:	17fd                	addi	a5,a5,-1
    80004e3c:	993e                	add	s2,s2,a5
    80004e3e:	7571                	lui	a0,0xffffc
    80004e40:	00a977b3          	and	a5,s2,a0
    80004e44:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e48:	6621                	lui	a2,0x8
    80004e4a:	963e                	add	a2,a2,a5
    80004e4c:	85be                	mv	a1,a5
    80004e4e:	855e                	mv	a0,s7
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	76e080e7          	jalr	1902(ra) # 800015be <uvmalloc>
    80004e58:	8b2a                	mv	s6,a0
  ip = 0;
    80004e5a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e5c:	12050c63          	beqz	a0,80004f94 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e60:	75e1                	lui	a1,0xffff8
    80004e62:	95aa                	add	a1,a1,a0
    80004e64:	855e                	mv	a0,s7
    80004e66:	ffffd097          	auipc	ra,0xffffd
    80004e6a:	978080e7          	jalr	-1672(ra) # 800017de <uvmclear>
  stackbase = sp - PGSIZE;
    80004e6e:	7c71                	lui	s8,0xffffc
    80004e70:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e72:	e0043783          	ld	a5,-512(s0)
    80004e76:	6388                	ld	a0,0(a5)
    80004e78:	c535                	beqz	a0,80004ee4 <exec+0x216>
    80004e7a:	e9040993          	addi	s3,s0,-368
    80004e7e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e82:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	fe0080e7          	jalr	-32(ra) # 80000e64 <strlen>
    80004e8c:	2505                	addiw	a0,a0,1
    80004e8e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e92:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e96:	13896363          	bltu	s2,s8,80004fbc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e9a:	e0043d83          	ld	s11,-512(s0)
    80004e9e:	000dba03          	ld	s4,0(s11)
    80004ea2:	8552                	mv	a0,s4
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	fc0080e7          	jalr	-64(ra) # 80000e64 <strlen>
    80004eac:	0015069b          	addiw	a3,a0,1
    80004eb0:	8652                	mv	a2,s4
    80004eb2:	85ca                	mv	a1,s2
    80004eb4:	855e                	mv	a0,s7
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	95c080e7          	jalr	-1700(ra) # 80001812 <copyout>
    80004ebe:	10054363          	bltz	a0,80004fc4 <exec+0x2f6>
    ustack[argc] = sp;
    80004ec2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec6:	0485                	addi	s1,s1,1
    80004ec8:	008d8793          	addi	a5,s11,8
    80004ecc:	e0f43023          	sd	a5,-512(s0)
    80004ed0:	008db503          	ld	a0,8(s11)
    80004ed4:	c911                	beqz	a0,80004ee8 <exec+0x21a>
    if(argc >= MAXARG)
    80004ed6:	09a1                	addi	s3,s3,8
    80004ed8:	fb3c96e3          	bne	s9,s3,80004e84 <exec+0x1b6>
  sz = sz1;
    80004edc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee0:	4481                	li	s1,0
    80004ee2:	a84d                	j	80004f94 <exec+0x2c6>
  sp = sz;
    80004ee4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee6:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee8:	00349793          	slli	a5,s1,0x3
    80004eec:	f9040713          	addi	a4,s0,-112
    80004ef0:	97ba                	add	a5,a5,a4
    80004ef2:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004ef6:	00148693          	addi	a3,s1,1
    80004efa:	068e                	slli	a3,a3,0x3
    80004efc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f00:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f04:	01897663          	bgeu	s2,s8,80004f10 <exec+0x242>
  sz = sz1;
    80004f08:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f0c:	4481                	li	s1,0
    80004f0e:	a059                	j	80004f94 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f10:	e9040613          	addi	a2,s0,-368
    80004f14:	85ca                	mv	a1,s2
    80004f16:	855e                	mv	a0,s7
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	8fa080e7          	jalr	-1798(ra) # 80001812 <copyout>
    80004f20:	0a054663          	bltz	a0,80004fcc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f24:	058ab783          	ld	a5,88(s5)
    80004f28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f2c:	df843783          	ld	a5,-520(s0)
    80004f30:	0007c703          	lbu	a4,0(a5)
    80004f34:	cf11                	beqz	a4,80004f50 <exec+0x282>
    80004f36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f38:	02f00693          	li	a3,47
    80004f3c:	a039                	j	80004f4a <exec+0x27c>
      last = s+1;
    80004f3e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f42:	0785                	addi	a5,a5,1
    80004f44:	fff7c703          	lbu	a4,-1(a5)
    80004f48:	c701                	beqz	a4,80004f50 <exec+0x282>
    if(*s == '/')
    80004f4a:	fed71ce3          	bne	a4,a3,80004f42 <exec+0x274>
    80004f4e:	bfc5                	j	80004f3e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f50:	4641                	li	a2,16
    80004f52:	df843583          	ld	a1,-520(s0)
    80004f56:	158a8513          	addi	a0,s5,344
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	ed8080e7          	jalr	-296(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f62:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f66:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f6a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6e:	058ab783          	ld	a5,88(s5)
    80004f72:	e6843703          	ld	a4,-408(s0)
    80004f76:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f78:	058ab783          	ld	a5,88(s5)
    80004f7c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f80:	85ea                	mv	a1,s10
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	d2e080e7          	jalr	-722(ra) # 80001cb0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f8a:	0004851b          	sext.w	a0,s1
    80004f8e:	bbe1                	j	80004d66 <exec+0x98>
    80004f90:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f94:	e0843583          	ld	a1,-504(s0)
    80004f98:	855e                	mv	a0,s7
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	d16080e7          	jalr	-746(ra) # 80001cb0 <proc_freepagetable>
  if(ip){
    80004fa2:	da0498e3          	bnez	s1,80004d52 <exec+0x84>
  return -1;
    80004fa6:	557d                	li	a0,-1
    80004fa8:	bb7d                	j	80004d66 <exec+0x98>
    80004faa:	e1243423          	sd	s2,-504(s0)
    80004fae:	b7dd                	j	80004f94 <exec+0x2c6>
    80004fb0:	e1243423          	sd	s2,-504(s0)
    80004fb4:	b7c5                	j	80004f94 <exec+0x2c6>
    80004fb6:	e1243423          	sd	s2,-504(s0)
    80004fba:	bfe9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	bfc9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fc4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc8:	4481                	li	s1,0
    80004fca:	b7e9                	j	80004f94 <exec+0x2c6>
  sz = sz1;
    80004fcc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fd0:	4481                	li	s1,0
    80004fd2:	b7c9                	j	80004f94 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	2b05                	addiw	s6,s6,1
    80004fda:	0389899b          	addiw	s3,s3,56
    80004fde:	e8845783          	lhu	a5,-376(s0)
    80004fe2:	e2fb5be3          	bge	s6,a5,80004e18 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe6:	2981                	sext.w	s3,s3
    80004fe8:	03800713          	li	a4,56
    80004fec:	86ce                	mv	a3,s3
    80004fee:	e1840613          	addi	a2,s0,-488
    80004ff2:	4581                	li	a1,0
    80004ff4:	8526                	mv	a0,s1
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	a8e080e7          	jalr	-1394(ra) # 80003a84 <readi>
    80004ffe:	03800793          	li	a5,56
    80005002:	f8f517e3          	bne	a0,a5,80004f90 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005006:	e1842783          	lw	a5,-488(s0)
    8000500a:	4705                	li	a4,1
    8000500c:	fce796e3          	bne	a5,a4,80004fd8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005010:	e4043603          	ld	a2,-448(s0)
    80005014:	e3843783          	ld	a5,-456(s0)
    80005018:	f8f669e3          	bltu	a2,a5,80004faa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000501c:	e2843783          	ld	a5,-472(s0)
    80005020:	963e                	add	a2,a2,a5
    80005022:	f8f667e3          	bltu	a2,a5,80004fb0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005026:	85ca                	mv	a1,s2
    80005028:	855e                	mv	a0,s7
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	594080e7          	jalr	1428(ra) # 800015be <uvmalloc>
    80005032:	e0a43423          	sd	a0,-504(s0)
    80005036:	d141                	beqz	a0,80004fb6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005038:	e2843d03          	ld	s10,-472(s0)
    8000503c:	df043783          	ld	a5,-528(s0)
    80005040:	00fd77b3          	and	a5,s10,a5
    80005044:	fba1                	bnez	a5,80004f94 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005046:	e2042d83          	lw	s11,-480(s0)
    8000504a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000504e:	f80c03e3          	beqz	s8,80004fd4 <exec+0x306>
    80005052:	8a62                	mv	s4,s8
    80005054:	4901                	li	s2,0
    80005056:	b345                	j	80004df6 <exec+0x128>

0000000080005058 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005058:	7179                	addi	sp,sp,-48
    8000505a:	f406                	sd	ra,40(sp)
    8000505c:	f022                	sd	s0,32(sp)
    8000505e:	ec26                	sd	s1,24(sp)
    80005060:	e84a                	sd	s2,16(sp)
    80005062:	1800                	addi	s0,sp,48
    80005064:	892e                	mv	s2,a1
    80005066:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005068:	fdc40593          	addi	a1,s0,-36
    8000506c:	ffffe097          	auipc	ra,0xffffe
    80005070:	be0080e7          	jalr	-1056(ra) # 80002c4c <argint>
    80005074:	04054063          	bltz	a0,800050b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005078:	fdc42703          	lw	a4,-36(s0)
    8000507c:	47bd                	li	a5,15
    8000507e:	02e7ed63          	bltu	a5,a4,800050b8 <argfd+0x60>
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	ace080e7          	jalr	-1330(ra) # 80001b50 <myproc>
    8000508a:	fdc42703          	lw	a4,-36(s0)
    8000508e:	01a70793          	addi	a5,a4,26
    80005092:	078e                	slli	a5,a5,0x3
    80005094:	953e                	add	a0,a0,a5
    80005096:	611c                	ld	a5,0(a0)
    80005098:	c395                	beqz	a5,800050bc <argfd+0x64>
    return -1;
  if(pfd)
    8000509a:	00090463          	beqz	s2,800050a2 <argfd+0x4a>
    *pfd = fd;
    8000509e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050a2:	4501                	li	a0,0
  if(pf)
    800050a4:	c091                	beqz	s1,800050a8 <argfd+0x50>
    *pf = f;
    800050a6:	e09c                	sd	a5,0(s1)
}
    800050a8:	70a2                	ld	ra,40(sp)
    800050aa:	7402                	ld	s0,32(sp)
    800050ac:	64e2                	ld	s1,24(sp)
    800050ae:	6942                	ld	s2,16(sp)
    800050b0:	6145                	addi	sp,sp,48
    800050b2:	8082                	ret
    return -1;
    800050b4:	557d                	li	a0,-1
    800050b6:	bfcd                	j	800050a8 <argfd+0x50>
    return -1;
    800050b8:	557d                	li	a0,-1
    800050ba:	b7fd                	j	800050a8 <argfd+0x50>
    800050bc:	557d                	li	a0,-1
    800050be:	b7ed                	j	800050a8 <argfd+0x50>

00000000800050c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c0:	1101                	addi	sp,sp,-32
    800050c2:	ec06                	sd	ra,24(sp)
    800050c4:	e822                	sd	s0,16(sp)
    800050c6:	e426                	sd	s1,8(sp)
    800050c8:	1000                	addi	s0,sp,32
    800050ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	a84080e7          	jalr	-1404(ra) # 80001b50 <myproc>
    800050d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d6:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc40d0>
    800050da:	4501                	li	a0,0
    800050dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050de:	6398                	ld	a4,0(a5)
    800050e0:	cb19                	beqz	a4,800050f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050e2:	2505                	addiw	a0,a0,1
    800050e4:	07a1                	addi	a5,a5,8
    800050e6:	fed51ce3          	bne	a0,a3,800050de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ea:	557d                	li	a0,-1
}
    800050ec:	60e2                	ld	ra,24(sp)
    800050ee:	6442                	ld	s0,16(sp)
    800050f0:	64a2                	ld	s1,8(sp)
    800050f2:	6105                	addi	sp,sp,32
    800050f4:	8082                	ret
      p->ofile[fd] = f;
    800050f6:	01a50793          	addi	a5,a0,26
    800050fa:	078e                	slli	a5,a5,0x3
    800050fc:	963e                	add	a2,a2,a5
    800050fe:	e204                	sd	s1,0(a2)
      return fd;
    80005100:	b7f5                	j	800050ec <fdalloc+0x2c>

0000000080005102 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005102:	715d                	addi	sp,sp,-80
    80005104:	e486                	sd	ra,72(sp)
    80005106:	e0a2                	sd	s0,64(sp)
    80005108:	fc26                	sd	s1,56(sp)
    8000510a:	f84a                	sd	s2,48(sp)
    8000510c:	f44e                	sd	s3,40(sp)
    8000510e:	f052                	sd	s4,32(sp)
    80005110:	ec56                	sd	s5,24(sp)
    80005112:	0880                	addi	s0,sp,80
    80005114:	89ae                	mv	s3,a1
    80005116:	8ab2                	mv	s5,a2
    80005118:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000511a:	fb040593          	addi	a1,s0,-80
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	e86080e7          	jalr	-378(ra) # 80003fa4 <nameiparent>
    80005126:	892a                	mv	s2,a0
    80005128:	12050f63          	beqz	a0,80005266 <create+0x164>
    return 0;

  ilock(dp);
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	6a4080e7          	jalr	1700(ra) # 800037d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005134:	4601                	li	a2,0
    80005136:	fb040593          	addi	a1,s0,-80
    8000513a:	854a                	mv	a0,s2
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	b78080e7          	jalr	-1160(ra) # 80003cb4 <dirlookup>
    80005144:	84aa                	mv	s1,a0
    80005146:	c921                	beqz	a0,80005196 <create+0x94>
    iunlockput(dp);
    80005148:	854a                	mv	a0,s2
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	8e8080e7          	jalr	-1816(ra) # 80003a32 <iunlockput>
    ilock(ip);
    80005152:	8526                	mv	a0,s1
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	67c080e7          	jalr	1660(ra) # 800037d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000515c:	2981                	sext.w	s3,s3
    8000515e:	4789                	li	a5,2
    80005160:	02f99463          	bne	s3,a5,80005188 <create+0x86>
    80005164:	0444d783          	lhu	a5,68(s1)
    80005168:	37f9                	addiw	a5,a5,-2
    8000516a:	17c2                	slli	a5,a5,0x30
    8000516c:	93c1                	srli	a5,a5,0x30
    8000516e:	4705                	li	a4,1
    80005170:	00f76c63          	bltu	a4,a5,80005188 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005174:	8526                	mv	a0,s1
    80005176:	60a6                	ld	ra,72(sp)
    80005178:	6406                	ld	s0,64(sp)
    8000517a:	74e2                	ld	s1,56(sp)
    8000517c:	7942                	ld	s2,48(sp)
    8000517e:	79a2                	ld	s3,40(sp)
    80005180:	7a02                	ld	s4,32(sp)
    80005182:	6ae2                	ld	s5,24(sp)
    80005184:	6161                	addi	sp,sp,80
    80005186:	8082                	ret
    iunlockput(ip);
    80005188:	8526                	mv	a0,s1
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	8a8080e7          	jalr	-1880(ra) # 80003a32 <iunlockput>
    return 0;
    80005192:	4481                	li	s1,0
    80005194:	b7c5                	j	80005174 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005196:	85ce                	mv	a1,s3
    80005198:	00092503          	lw	a0,0(s2)
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	49c080e7          	jalr	1180(ra) # 80003638 <ialloc>
    800051a4:	84aa                	mv	s1,a0
    800051a6:	c529                	beqz	a0,800051f0 <create+0xee>
  ilock(ip);
    800051a8:	ffffe097          	auipc	ra,0xffffe
    800051ac:	628080e7          	jalr	1576(ra) # 800037d0 <ilock>
  ip->major = major;
    800051b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051b8:	4785                	li	a5,1
    800051ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051be:	8526                	mv	a0,s1
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	546080e7          	jalr	1350(ra) # 80003706 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051c8:	2981                	sext.w	s3,s3
    800051ca:	4785                	li	a5,1
    800051cc:	02f98a63          	beq	s3,a5,80005200 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051d0:	40d0                	lw	a2,4(s1)
    800051d2:	fb040593          	addi	a1,s0,-80
    800051d6:	854a                	mv	a0,s2
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	cec080e7          	jalr	-788(ra) # 80003ec4 <dirlink>
    800051e0:	06054b63          	bltz	a0,80005256 <create+0x154>
  iunlockput(dp);
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	84c080e7          	jalr	-1972(ra) # 80003a32 <iunlockput>
  return ip;
    800051ee:	b759                	j	80005174 <create+0x72>
    panic("create: ialloc");
    800051f0:	00007517          	auipc	a0,0x7
    800051f4:	79050513          	addi	a0,a0,1936 # 8000c980 <syscalls+0x2b8>
    800051f8:	ffffb097          	auipc	ra,0xffffb
    800051fc:	346080e7          	jalr	838(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005200:	04a95783          	lhu	a5,74(s2)
    80005204:	2785                	addiw	a5,a5,1
    80005206:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000520a:	854a                	mv	a0,s2
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	4fa080e7          	jalr	1274(ra) # 80003706 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005214:	40d0                	lw	a2,4(s1)
    80005216:	00007597          	auipc	a1,0x7
    8000521a:	77a58593          	addi	a1,a1,1914 # 8000c990 <syscalls+0x2c8>
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	ca4080e7          	jalr	-860(ra) # 80003ec4 <dirlink>
    80005228:	00054f63          	bltz	a0,80005246 <create+0x144>
    8000522c:	00492603          	lw	a2,4(s2)
    80005230:	00007597          	auipc	a1,0x7
    80005234:	76858593          	addi	a1,a1,1896 # 8000c998 <syscalls+0x2d0>
    80005238:	8526                	mv	a0,s1
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	c8a080e7          	jalr	-886(ra) # 80003ec4 <dirlink>
    80005242:	f80557e3          	bgez	a0,800051d0 <create+0xce>
      panic("create dots");
    80005246:	00007517          	auipc	a0,0x7
    8000524a:	75a50513          	addi	a0,a0,1882 # 8000c9a0 <syscalls+0x2d8>
    8000524e:	ffffb097          	auipc	ra,0xffffb
    80005252:	2f0080e7          	jalr	752(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005256:	00007517          	auipc	a0,0x7
    8000525a:	75a50513          	addi	a0,a0,1882 # 8000c9b0 <syscalls+0x2e8>
    8000525e:	ffffb097          	auipc	ra,0xffffb
    80005262:	2e0080e7          	jalr	736(ra) # 8000053e <panic>
    return 0;
    80005266:	84aa                	mv	s1,a0
    80005268:	b731                	j	80005174 <create+0x72>

000000008000526a <sys_dup>:
{
    8000526a:	7179                	addi	sp,sp,-48
    8000526c:	f406                	sd	ra,40(sp)
    8000526e:	f022                	sd	s0,32(sp)
    80005270:	ec26                	sd	s1,24(sp)
    80005272:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005274:	fd840613          	addi	a2,s0,-40
    80005278:	4581                	li	a1,0
    8000527a:	4501                	li	a0,0
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	ddc080e7          	jalr	-548(ra) # 80005058 <argfd>
    return -1;
    80005284:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005286:	02054363          	bltz	a0,800052ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000528a:	fd843503          	ld	a0,-40(s0)
    8000528e:	00000097          	auipc	ra,0x0
    80005292:	e32080e7          	jalr	-462(ra) # 800050c0 <fdalloc>
    80005296:	84aa                	mv	s1,a0
    return -1;
    80005298:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000529a:	00054963          	bltz	a0,800052ac <sys_dup+0x42>
  filedup(f);
    8000529e:	fd843503          	ld	a0,-40(s0)
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	37a080e7          	jalr	890(ra) # 8000461c <filedup>
  return fd;
    800052aa:	87a6                	mv	a5,s1
}
    800052ac:	853e                	mv	a0,a5
    800052ae:	70a2                	ld	ra,40(sp)
    800052b0:	7402                	ld	s0,32(sp)
    800052b2:	64e2                	ld	s1,24(sp)
    800052b4:	6145                	addi	sp,sp,48
    800052b6:	8082                	ret

00000000800052b8 <sys_read>:
{
    800052b8:	7179                	addi	sp,sp,-48
    800052ba:	f406                	sd	ra,40(sp)
    800052bc:	f022                	sd	s0,32(sp)
    800052be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	fe840613          	addi	a2,s0,-24
    800052c4:	4581                	li	a1,0
    800052c6:	4501                	li	a0,0
    800052c8:	00000097          	auipc	ra,0x0
    800052cc:	d90080e7          	jalr	-624(ra) # 80005058 <argfd>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	04054163          	bltz	a0,80005314 <sys_read+0x5c>
    800052d6:	fe440593          	addi	a1,s0,-28
    800052da:	4509                	li	a0,2
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	970080e7          	jalr	-1680(ra) # 80002c4c <argint>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	02054763          	bltz	a0,80005314 <sys_read+0x5c>
    800052ea:	fd840593          	addi	a1,s0,-40
    800052ee:	4505                	li	a0,1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	97e080e7          	jalr	-1666(ra) # 80002c6e <argaddr>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	00054d63          	bltz	a0,80005314 <sys_read+0x5c>
  return fileread(f, p, n);
    800052fe:	fe442603          	lw	a2,-28(s0)
    80005302:	fd843583          	ld	a1,-40(s0)
    80005306:	fe843503          	ld	a0,-24(s0)
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	49e080e7          	jalr	1182(ra) # 800047a8 <fileread>
    80005312:	87aa                	mv	a5,a0
}
    80005314:	853e                	mv	a0,a5
    80005316:	70a2                	ld	ra,40(sp)
    80005318:	7402                	ld	s0,32(sp)
    8000531a:	6145                	addi	sp,sp,48
    8000531c:	8082                	ret

000000008000531e <sys_write>:
{
    8000531e:	7179                	addi	sp,sp,-48
    80005320:	f406                	sd	ra,40(sp)
    80005322:	f022                	sd	s0,32(sp)
    80005324:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	fe840613          	addi	a2,s0,-24
    8000532a:	4581                	li	a1,0
    8000532c:	4501                	li	a0,0
    8000532e:	00000097          	auipc	ra,0x0
    80005332:	d2a080e7          	jalr	-726(ra) # 80005058 <argfd>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	04054163          	bltz	a0,8000537a <sys_write+0x5c>
    8000533c:	fe440593          	addi	a1,s0,-28
    80005340:	4509                	li	a0,2
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	90a080e7          	jalr	-1782(ra) # 80002c4c <argint>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	02054763          	bltz	a0,8000537a <sys_write+0x5c>
    80005350:	fd840593          	addi	a1,s0,-40
    80005354:	4505                	li	a0,1
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	918080e7          	jalr	-1768(ra) # 80002c6e <argaddr>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	00054d63          	bltz	a0,8000537a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005364:	fe442603          	lw	a2,-28(s0)
    80005368:	fd843583          	ld	a1,-40(s0)
    8000536c:	fe843503          	ld	a0,-24(s0)
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	4fa080e7          	jalr	1274(ra) # 8000486a <filewrite>
    80005378:	87aa                	mv	a5,a0
}
    8000537a:	853e                	mv	a0,a5
    8000537c:	70a2                	ld	ra,40(sp)
    8000537e:	7402                	ld	s0,32(sp)
    80005380:	6145                	addi	sp,sp,48
    80005382:	8082                	ret

0000000080005384 <sys_close>:
{
    80005384:	1101                	addi	sp,sp,-32
    80005386:	ec06                	sd	ra,24(sp)
    80005388:	e822                	sd	s0,16(sp)
    8000538a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000538c:	fe040613          	addi	a2,s0,-32
    80005390:	fec40593          	addi	a1,s0,-20
    80005394:	4501                	li	a0,0
    80005396:	00000097          	auipc	ra,0x0
    8000539a:	cc2080e7          	jalr	-830(ra) # 80005058 <argfd>
    return -1;
    8000539e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053a0:	02054463          	bltz	a0,800053c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	7ac080e7          	jalr	1964(ra) # 80001b50 <myproc>
    800053ac:	fec42783          	lw	a5,-20(s0)
    800053b0:	07e9                	addi	a5,a5,26
    800053b2:	078e                	slli	a5,a5,0x3
    800053b4:	97aa                	add	a5,a5,a0
    800053b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053ba:	fe043503          	ld	a0,-32(s0)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	2b0080e7          	jalr	688(ra) # 8000466e <fileclose>
  return 0;
    800053c6:	4781                	li	a5,0
}
    800053c8:	853e                	mv	a0,a5
    800053ca:	60e2                	ld	ra,24(sp)
    800053cc:	6442                	ld	s0,16(sp)
    800053ce:	6105                	addi	sp,sp,32
    800053d0:	8082                	ret

00000000800053d2 <sys_fstat>:
{
    800053d2:	1101                	addi	sp,sp,-32
    800053d4:	ec06                	sd	ra,24(sp)
    800053d6:	e822                	sd	s0,16(sp)
    800053d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053da:	fe840613          	addi	a2,s0,-24
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	c76080e7          	jalr	-906(ra) # 80005058 <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ec:	02054563          	bltz	a0,80005416 <sys_fstat+0x44>
    800053f0:	fe040593          	addi	a1,s0,-32
    800053f4:	4505                	li	a0,1
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	878080e7          	jalr	-1928(ra) # 80002c6e <argaddr>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005400:	00054b63          	bltz	a0,80005416 <sys_fstat+0x44>
  return filestat(f, st);
    80005404:	fe043583          	ld	a1,-32(s0)
    80005408:	fe843503          	ld	a0,-24(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	32a080e7          	jalr	810(ra) # 80004736 <filestat>
    80005414:	87aa                	mv	a5,a0
}
    80005416:	853e                	mv	a0,a5
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	addi	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_link>:
{
    80005420:	7169                	addi	sp,sp,-304
    80005422:	f606                	sd	ra,296(sp)
    80005424:	f222                	sd	s0,288(sp)
    80005426:	ee26                	sd	s1,280(sp)
    80005428:	ea4a                	sd	s2,272(sp)
    8000542a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542c:	08000613          	li	a2,128
    80005430:	ed040593          	addi	a1,s0,-304
    80005434:	4501                	li	a0,0
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	85a080e7          	jalr	-1958(ra) # 80002c90 <argstr>
    return -1;
    8000543e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005440:	10054e63          	bltz	a0,8000555c <sys_link+0x13c>
    80005444:	08000613          	li	a2,128
    80005448:	f5040593          	addi	a1,s0,-176
    8000544c:	4505                	li	a0,1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	842080e7          	jalr	-1982(ra) # 80002c90 <argstr>
    return -1;
    80005456:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005458:	10054263          	bltz	a0,8000555c <sys_link+0x13c>
  begin_op();
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	d46080e7          	jalr	-698(ra) # 800041a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005464:	ed040513          	addi	a0,s0,-304
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	b1e080e7          	jalr	-1250(ra) # 80003f86 <namei>
    80005470:	84aa                	mv	s1,a0
    80005472:	c551                	beqz	a0,800054fe <sys_link+0xde>
  ilock(ip);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	35c080e7          	jalr	860(ra) # 800037d0 <ilock>
  if(ip->type == T_DIR){
    8000547c:	04449703          	lh	a4,68(s1)
    80005480:	4785                	li	a5,1
    80005482:	08f70463          	beq	a4,a5,8000550a <sys_link+0xea>
  ip->nlink++;
    80005486:	04a4d783          	lhu	a5,74(s1)
    8000548a:	2785                	addiw	a5,a5,1
    8000548c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	274080e7          	jalr	628(ra) # 80003706 <iupdate>
  iunlock(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	3f6080e7          	jalr	1014(ra) # 80003892 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054a4:	fd040593          	addi	a1,s0,-48
    800054a8:	f5040513          	addi	a0,s0,-176
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	af8080e7          	jalr	-1288(ra) # 80003fa4 <nameiparent>
    800054b4:	892a                	mv	s2,a0
    800054b6:	c935                	beqz	a0,8000552a <sys_link+0x10a>
  ilock(dp);
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	318080e7          	jalr	792(ra) # 800037d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054c0:	00092703          	lw	a4,0(s2)
    800054c4:	409c                	lw	a5,0(s1)
    800054c6:	04f71d63          	bne	a4,a5,80005520 <sys_link+0x100>
    800054ca:	40d0                	lw	a2,4(s1)
    800054cc:	fd040593          	addi	a1,s0,-48
    800054d0:	854a                	mv	a0,s2
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	9f2080e7          	jalr	-1550(ra) # 80003ec4 <dirlink>
    800054da:	04054363          	bltz	a0,80005520 <sys_link+0x100>
  iunlockput(dp);
    800054de:	854a                	mv	a0,s2
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	552080e7          	jalr	1362(ra) # 80003a32 <iunlockput>
  iput(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	4a0080e7          	jalr	1184(ra) # 8000398a <iput>
  end_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	d30080e7          	jalr	-720(ra) # 80004222 <end_op>
  return 0;
    800054fa:	4781                	li	a5,0
    800054fc:	a085                	j	8000555c <sys_link+0x13c>
    end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	d24080e7          	jalr	-732(ra) # 80004222 <end_op>
    return -1;
    80005506:	57fd                	li	a5,-1
    80005508:	a891                	j	8000555c <sys_link+0x13c>
    iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	526080e7          	jalr	1318(ra) # 80003a32 <iunlockput>
    end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	d0e080e7          	jalr	-754(ra) # 80004222 <end_op>
    return -1;
    8000551c:	57fd                	li	a5,-1
    8000551e:	a83d                	j	8000555c <sys_link+0x13c>
    iunlockput(dp);
    80005520:	854a                	mv	a0,s2
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	510080e7          	jalr	1296(ra) # 80003a32 <iunlockput>
  ilock(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	2a4080e7          	jalr	676(ra) # 800037d0 <ilock>
  ip->nlink--;
    80005534:	04a4d783          	lhu	a5,74(s1)
    80005538:	37fd                	addiw	a5,a5,-1
    8000553a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	1c6080e7          	jalr	454(ra) # 80003706 <iupdate>
  iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	4e8080e7          	jalr	1256(ra) # 80003a32 <iunlockput>
  end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	cd0080e7          	jalr	-816(ra) # 80004222 <end_op>
  return -1;
    8000555a:	57fd                	li	a5,-1
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	70b2                	ld	ra,296(sp)
    80005560:	7412                	ld	s0,288(sp)
    80005562:	64f2                	ld	s1,280(sp)
    80005564:	6952                	ld	s2,272(sp)
    80005566:	6155                	addi	sp,sp,304
    80005568:	8082                	ret

000000008000556a <sys_unlink>:
{
    8000556a:	7151                	addi	sp,sp,-240
    8000556c:	f586                	sd	ra,232(sp)
    8000556e:	f1a2                	sd	s0,224(sp)
    80005570:	eda6                	sd	s1,216(sp)
    80005572:	e9ca                	sd	s2,208(sp)
    80005574:	e5ce                	sd	s3,200(sp)
    80005576:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005578:	08000613          	li	a2,128
    8000557c:	f3040593          	addi	a1,s0,-208
    80005580:	4501                	li	a0,0
    80005582:	ffffd097          	auipc	ra,0xffffd
    80005586:	70e080e7          	jalr	1806(ra) # 80002c90 <argstr>
    8000558a:	18054163          	bltz	a0,8000570c <sys_unlink+0x1a2>
  begin_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	c14080e7          	jalr	-1004(ra) # 800041a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005596:	fb040593          	addi	a1,s0,-80
    8000559a:	f3040513          	addi	a0,s0,-208
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	a06080e7          	jalr	-1530(ra) # 80003fa4 <nameiparent>
    800055a6:	84aa                	mv	s1,a0
    800055a8:	c979                	beqz	a0,8000567e <sys_unlink+0x114>
  ilock(dp);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	226080e7          	jalr	550(ra) # 800037d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055b2:	00007597          	auipc	a1,0x7
    800055b6:	3de58593          	addi	a1,a1,990 # 8000c990 <syscalls+0x2c8>
    800055ba:	fb040513          	addi	a0,s0,-80
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	6dc080e7          	jalr	1756(ra) # 80003c9a <namecmp>
    800055c6:	14050a63          	beqz	a0,8000571a <sys_unlink+0x1b0>
    800055ca:	00007597          	auipc	a1,0x7
    800055ce:	3ce58593          	addi	a1,a1,974 # 8000c998 <syscalls+0x2d0>
    800055d2:	fb040513          	addi	a0,s0,-80
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	6c4080e7          	jalr	1732(ra) # 80003c9a <namecmp>
    800055de:	12050e63          	beqz	a0,8000571a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055e2:	f2c40613          	addi	a2,s0,-212
    800055e6:	fb040593          	addi	a1,s0,-80
    800055ea:	8526                	mv	a0,s1
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	6c8080e7          	jalr	1736(ra) # 80003cb4 <dirlookup>
    800055f4:	892a                	mv	s2,a0
    800055f6:	12050263          	beqz	a0,8000571a <sys_unlink+0x1b0>
  ilock(ip);
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	1d6080e7          	jalr	470(ra) # 800037d0 <ilock>
  if(ip->nlink < 1)
    80005602:	04a91783          	lh	a5,74(s2)
    80005606:	08f05263          	blez	a5,8000568a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000560a:	04491703          	lh	a4,68(s2)
    8000560e:	4785                	li	a5,1
    80005610:	08f70563          	beq	a4,a5,8000569a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005614:	4641                	li	a2,16
    80005616:	4581                	li	a1,0
    80005618:	fc040513          	addi	a0,s0,-64
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	6c4080e7          	jalr	1732(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005624:	4741                	li	a4,16
    80005626:	f2c42683          	lw	a3,-212(s0)
    8000562a:	fc040613          	addi	a2,s0,-64
    8000562e:	4581                	li	a1,0
    80005630:	8526                	mv	a0,s1
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	54a080e7          	jalr	1354(ra) # 80003b7c <writei>
    8000563a:	47c1                	li	a5,16
    8000563c:	0af51563          	bne	a0,a5,800056e6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005640:	04491703          	lh	a4,68(s2)
    80005644:	4785                	li	a5,1
    80005646:	0af70863          	beq	a4,a5,800056f6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000564a:	8526                	mv	a0,s1
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	3e6080e7          	jalr	998(ra) # 80003a32 <iunlockput>
  ip->nlink--;
    80005654:	04a95783          	lhu	a5,74(s2)
    80005658:	37fd                	addiw	a5,a5,-1
    8000565a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	0a6080e7          	jalr	166(ra) # 80003706 <iupdate>
  iunlockput(ip);
    80005668:	854a                	mv	a0,s2
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	3c8080e7          	jalr	968(ra) # 80003a32 <iunlockput>
  end_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	bb0080e7          	jalr	-1104(ra) # 80004222 <end_op>
  return 0;
    8000567a:	4501                	li	a0,0
    8000567c:	a84d                	j	8000572e <sys_unlink+0x1c4>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	ba4080e7          	jalr	-1116(ra) # 80004222 <end_op>
    return -1;
    80005686:	557d                	li	a0,-1
    80005688:	a05d                	j	8000572e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000568a:	00007517          	auipc	a0,0x7
    8000568e:	33650513          	addi	a0,a0,822 # 8000c9c0 <syscalls+0x2f8>
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569a:	04c92703          	lw	a4,76(s2)
    8000569e:	02000793          	li	a5,32
    800056a2:	f6e7f9e3          	bgeu	a5,a4,80005614 <sys_unlink+0xaa>
    800056a6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056aa:	4741                	li	a4,16
    800056ac:	86ce                	mv	a3,s3
    800056ae:	f1840613          	addi	a2,s0,-232
    800056b2:	4581                	li	a1,0
    800056b4:	854a                	mv	a0,s2
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	3ce080e7          	jalr	974(ra) # 80003a84 <readi>
    800056be:	47c1                	li	a5,16
    800056c0:	00f51b63          	bne	a0,a5,800056d6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056c4:	f1845783          	lhu	a5,-232(s0)
    800056c8:	e7a1                	bnez	a5,80005710 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ca:	29c1                	addiw	s3,s3,16
    800056cc:	04c92783          	lw	a5,76(s2)
    800056d0:	fcf9ede3          	bltu	s3,a5,800056aa <sys_unlink+0x140>
    800056d4:	b781                	j	80005614 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056d6:	00007517          	auipc	a0,0x7
    800056da:	30250513          	addi	a0,a0,770 # 8000c9d8 <syscalls+0x310>
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056e6:	00007517          	auipc	a0,0x7
    800056ea:	30a50513          	addi	a0,a0,778 # 8000c9f0 <syscalls+0x328>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
    dp->nlink--;
    800056f6:	04a4d783          	lhu	a5,74(s1)
    800056fa:	37fd                	addiw	a5,a5,-1
    800056fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	004080e7          	jalr	4(ra) # 80003706 <iupdate>
    8000570a:	b781                	j	8000564a <sys_unlink+0xe0>
    return -1;
    8000570c:	557d                	li	a0,-1
    8000570e:	a005                	j	8000572e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005710:	854a                	mv	a0,s2
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	320080e7          	jalr	800(ra) # 80003a32 <iunlockput>
  iunlockput(dp);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	316080e7          	jalr	790(ra) # 80003a32 <iunlockput>
  end_op();
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	afe080e7          	jalr	-1282(ra) # 80004222 <end_op>
  return -1;
    8000572c:	557d                	li	a0,-1
}
    8000572e:	70ae                	ld	ra,232(sp)
    80005730:	740e                	ld	s0,224(sp)
    80005732:	64ee                	ld	s1,216(sp)
    80005734:	694e                	ld	s2,208(sp)
    80005736:	69ae                	ld	s3,200(sp)
    80005738:	616d                	addi	sp,sp,240
    8000573a:	8082                	ret

000000008000573c <sys_open>:

uint64
sys_open(void)
{
    8000573c:	7131                	addi	sp,sp,-192
    8000573e:	fd06                	sd	ra,184(sp)
    80005740:	f922                	sd	s0,176(sp)
    80005742:	f526                	sd	s1,168(sp)
    80005744:	f14a                	sd	s2,160(sp)
    80005746:	ed4e                	sd	s3,152(sp)
    80005748:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000574a:	08000613          	li	a2,128
    8000574e:	f5040593          	addi	a1,s0,-176
    80005752:	4501                	li	a0,0
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	53c080e7          	jalr	1340(ra) # 80002c90 <argstr>
    return -1;
    8000575c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000575e:	0c054163          	bltz	a0,80005820 <sys_open+0xe4>
    80005762:	f4c40593          	addi	a1,s0,-180
    80005766:	4505                	li	a0,1
    80005768:	ffffd097          	auipc	ra,0xffffd
    8000576c:	4e4080e7          	jalr	1252(ra) # 80002c4c <argint>
    80005770:	0a054863          	bltz	a0,80005820 <sys_open+0xe4>

  begin_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	a2e080e7          	jalr	-1490(ra) # 800041a2 <begin_op>

  if(omode & O_CREATE){
    8000577c:	f4c42783          	lw	a5,-180(s0)
    80005780:	2007f793          	andi	a5,a5,512
    80005784:	cbdd                	beqz	a5,8000583a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005786:	4681                	li	a3,0
    80005788:	4601                	li	a2,0
    8000578a:	4589                	li	a1,2
    8000578c:	f5040513          	addi	a0,s0,-176
    80005790:	00000097          	auipc	ra,0x0
    80005794:	972080e7          	jalr	-1678(ra) # 80005102 <create>
    80005798:	892a                	mv	s2,a0
    if(ip == 0){
    8000579a:	c959                	beqz	a0,80005830 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000579c:	04491703          	lh	a4,68(s2)
    800057a0:	478d                	li	a5,3
    800057a2:	00f71763          	bne	a4,a5,800057b0 <sys_open+0x74>
    800057a6:	04695703          	lhu	a4,70(s2)
    800057aa:	47a5                	li	a5,9
    800057ac:	0ce7ec63          	bltu	a5,a4,80005884 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	e02080e7          	jalr	-510(ra) # 800045b2 <filealloc>
    800057b8:	89aa                	mv	s3,a0
    800057ba:	10050263          	beqz	a0,800058be <sys_open+0x182>
    800057be:	00000097          	auipc	ra,0x0
    800057c2:	902080e7          	jalr	-1790(ra) # 800050c0 <fdalloc>
    800057c6:	84aa                	mv	s1,a0
    800057c8:	0e054663          	bltz	a0,800058b4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057cc:	04491703          	lh	a4,68(s2)
    800057d0:	478d                	li	a5,3
    800057d2:	0cf70463          	beq	a4,a5,8000589a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d6:	4789                	li	a5,2
    800057d8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057dc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057e0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e4:	f4c42783          	lw	a5,-180(s0)
    800057e8:	0017c713          	xori	a4,a5,1
    800057ec:	8b05                	andi	a4,a4,1
    800057ee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057f2:	0037f713          	andi	a4,a5,3
    800057f6:	00e03733          	snez	a4,a4
    800057fa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057fe:	4007f793          	andi	a5,a5,1024
    80005802:	c791                	beqz	a5,8000580e <sys_open+0xd2>
    80005804:	04491703          	lh	a4,68(s2)
    80005808:	4789                	li	a5,2
    8000580a:	08f70f63          	beq	a4,a5,800058a8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	082080e7          	jalr	130(ra) # 80003892 <iunlock>
  end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	a0a080e7          	jalr	-1526(ra) # 80004222 <end_op>

  return fd;
}
    80005820:	8526                	mv	a0,s1
    80005822:	70ea                	ld	ra,184(sp)
    80005824:	744a                	ld	s0,176(sp)
    80005826:	74aa                	ld	s1,168(sp)
    80005828:	790a                	ld	s2,160(sp)
    8000582a:	69ea                	ld	s3,152(sp)
    8000582c:	6129                	addi	sp,sp,192
    8000582e:	8082                	ret
      end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	9f2080e7          	jalr	-1550(ra) # 80004222 <end_op>
      return -1;
    80005838:	b7e5                	j	80005820 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000583a:	f5040513          	addi	a0,s0,-176
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	748080e7          	jalr	1864(ra) # 80003f86 <namei>
    80005846:	892a                	mv	s2,a0
    80005848:	c905                	beqz	a0,80005878 <sys_open+0x13c>
    ilock(ip);
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	f86080e7          	jalr	-122(ra) # 800037d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	4785                	li	a5,1
    80005858:	f4f712e3          	bne	a4,a5,8000579c <sys_open+0x60>
    8000585c:	f4c42783          	lw	a5,-180(s0)
    80005860:	dba1                	beqz	a5,800057b0 <sys_open+0x74>
      iunlockput(ip);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	1ce080e7          	jalr	462(ra) # 80003a32 <iunlockput>
      end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	9b6080e7          	jalr	-1610(ra) # 80004222 <end_op>
      return -1;
    80005874:	54fd                	li	s1,-1
    80005876:	b76d                	j	80005820 <sys_open+0xe4>
      end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	9aa080e7          	jalr	-1622(ra) # 80004222 <end_op>
      return -1;
    80005880:	54fd                	li	s1,-1
    80005882:	bf79                	j	80005820 <sys_open+0xe4>
    iunlockput(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	1ac080e7          	jalr	428(ra) # 80003a32 <iunlockput>
    end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	994080e7          	jalr	-1644(ra) # 80004222 <end_op>
    return -1;
    80005896:	54fd                	li	s1,-1
    80005898:	b761                	j	80005820 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000589a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000589e:	04691783          	lh	a5,70(s2)
    800058a2:	02f99223          	sh	a5,36(s3)
    800058a6:	bf2d                	j	800057e0 <sys_open+0xa4>
    itrunc(ip);
    800058a8:	854a                	mv	a0,s2
    800058aa:	ffffe097          	auipc	ra,0xffffe
    800058ae:	034080e7          	jalr	52(ra) # 800038de <itrunc>
    800058b2:	bfb1                	j	8000580e <sys_open+0xd2>
      fileclose(f);
    800058b4:	854e                	mv	a0,s3
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	db8080e7          	jalr	-584(ra) # 8000466e <fileclose>
    iunlockput(ip);
    800058be:	854a                	mv	a0,s2
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	172080e7          	jalr	370(ra) # 80003a32 <iunlockput>
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	95a080e7          	jalr	-1702(ra) # 80004222 <end_op>
    return -1;
    800058d0:	54fd                	li	s1,-1
    800058d2:	b7b9                	j	80005820 <sys_open+0xe4>

00000000800058d4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058d4:	7175                	addi	sp,sp,-144
    800058d6:	e506                	sd	ra,136(sp)
    800058d8:	e122                	sd	s0,128(sp)
    800058da:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	8c6080e7          	jalr	-1850(ra) # 800041a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058e4:	08000613          	li	a2,128
    800058e8:	f7040593          	addi	a1,s0,-144
    800058ec:	4501                	li	a0,0
    800058ee:	ffffd097          	auipc	ra,0xffffd
    800058f2:	3a2080e7          	jalr	930(ra) # 80002c90 <argstr>
    800058f6:	02054963          	bltz	a0,80005928 <sys_mkdir+0x54>
    800058fa:	4681                	li	a3,0
    800058fc:	4601                	li	a2,0
    800058fe:	4585                	li	a1,1
    80005900:	f7040513          	addi	a0,s0,-144
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	7fe080e7          	jalr	2046(ra) # 80005102 <create>
    8000590c:	cd11                	beqz	a0,80005928 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	124080e7          	jalr	292(ra) # 80003a32 <iunlockput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	90c080e7          	jalr	-1780(ra) # 80004222 <end_op>
  return 0;
    8000591e:	4501                	li	a0,0
}
    80005920:	60aa                	ld	ra,136(sp)
    80005922:	640a                	ld	s0,128(sp)
    80005924:	6149                	addi	sp,sp,144
    80005926:	8082                	ret
    end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	8fa080e7          	jalr	-1798(ra) # 80004222 <end_op>
    return -1;
    80005930:	557d                	li	a0,-1
    80005932:	b7fd                	j	80005920 <sys_mkdir+0x4c>

0000000080005934 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005934:	7135                	addi	sp,sp,-160
    80005936:	ed06                	sd	ra,152(sp)
    80005938:	e922                	sd	s0,144(sp)
    8000593a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	866080e7          	jalr	-1946(ra) # 800041a2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005944:	08000613          	li	a2,128
    80005948:	f7040593          	addi	a1,s0,-144
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	342080e7          	jalr	834(ra) # 80002c90 <argstr>
    80005956:	04054a63          	bltz	a0,800059aa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000595a:	f6c40593          	addi	a1,s0,-148
    8000595e:	4505                	li	a0,1
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	2ec080e7          	jalr	748(ra) # 80002c4c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005968:	04054163          	bltz	a0,800059aa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000596c:	f6840593          	addi	a1,s0,-152
    80005970:	4509                	li	a0,2
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	2da080e7          	jalr	730(ra) # 80002c4c <argint>
     argint(1, &major) < 0 ||
    8000597a:	02054863          	bltz	a0,800059aa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000597e:	f6841683          	lh	a3,-152(s0)
    80005982:	f6c41603          	lh	a2,-148(s0)
    80005986:	458d                	li	a1,3
    80005988:	f7040513          	addi	a0,s0,-144
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	776080e7          	jalr	1910(ra) # 80005102 <create>
     argint(2, &minor) < 0 ||
    80005994:	c919                	beqz	a0,800059aa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	09c080e7          	jalr	156(ra) # 80003a32 <iunlockput>
  end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	884080e7          	jalr	-1916(ra) # 80004222 <end_op>
  return 0;
    800059a6:	4501                	li	a0,0
    800059a8:	a031                	j	800059b4 <sys_mknod+0x80>
    end_op();
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	878080e7          	jalr	-1928(ra) # 80004222 <end_op>
    return -1;
    800059b2:	557d                	li	a0,-1
}
    800059b4:	60ea                	ld	ra,152(sp)
    800059b6:	644a                	ld	s0,144(sp)
    800059b8:	610d                	addi	sp,sp,160
    800059ba:	8082                	ret

00000000800059bc <sys_chdir>:

uint64
sys_chdir(void)
{
    800059bc:	7135                	addi	sp,sp,-160
    800059be:	ed06                	sd	ra,152(sp)
    800059c0:	e922                	sd	s0,144(sp)
    800059c2:	e526                	sd	s1,136(sp)
    800059c4:	e14a                	sd	s2,128(sp)
    800059c6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c8:	ffffc097          	auipc	ra,0xffffc
    800059cc:	188080e7          	jalr	392(ra) # 80001b50 <myproc>
    800059d0:	892a                	mv	s2,a0
  
  begin_op();
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	7d0080e7          	jalr	2000(ra) # 800041a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059da:	08000613          	li	a2,128
    800059de:	f6040593          	addi	a1,s0,-160
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	2ac080e7          	jalr	684(ra) # 80002c90 <argstr>
    800059ec:	04054b63          	bltz	a0,80005a42 <sys_chdir+0x86>
    800059f0:	f6040513          	addi	a0,s0,-160
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	592080e7          	jalr	1426(ra) # 80003f86 <namei>
    800059fc:	84aa                	mv	s1,a0
    800059fe:	c131                	beqz	a0,80005a42 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	dd0080e7          	jalr	-560(ra) # 800037d0 <ilock>
  if(ip->type != T_DIR){
    80005a08:	04449703          	lh	a4,68(s1)
    80005a0c:	4785                	li	a5,1
    80005a0e:	04f71063          	bne	a4,a5,80005a4e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a12:	8526                	mv	a0,s1
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	e7e080e7          	jalr	-386(ra) # 80003892 <iunlock>
  iput(p->cwd);
    80005a1c:	15093503          	ld	a0,336(s2)
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	f6a080e7          	jalr	-150(ra) # 8000398a <iput>
  end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	7fa080e7          	jalr	2042(ra) # 80004222 <end_op>
  p->cwd = ip;
    80005a30:	14993823          	sd	s1,336(s2)
  return 0;
    80005a34:	4501                	li	a0,0
}
    80005a36:	60ea                	ld	ra,152(sp)
    80005a38:	644a                	ld	s0,144(sp)
    80005a3a:	64aa                	ld	s1,136(sp)
    80005a3c:	690a                	ld	s2,128(sp)
    80005a3e:	610d                	addi	sp,sp,160
    80005a40:	8082                	ret
    end_op();
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	7e0080e7          	jalr	2016(ra) # 80004222 <end_op>
    return -1;
    80005a4a:	557d                	li	a0,-1
    80005a4c:	b7ed                	j	80005a36 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	fe2080e7          	jalr	-30(ra) # 80003a32 <iunlockput>
    end_op();
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	7ca080e7          	jalr	1994(ra) # 80004222 <end_op>
    return -1;
    80005a60:	557d                	li	a0,-1
    80005a62:	bfd1                	j	80005a36 <sys_chdir+0x7a>

0000000080005a64 <sys_exec>:

uint64
sys_exec(void)
{
    80005a64:	7145                	addi	sp,sp,-464
    80005a66:	e786                	sd	ra,456(sp)
    80005a68:	e3a2                	sd	s0,448(sp)
    80005a6a:	ff26                	sd	s1,440(sp)
    80005a6c:	fb4a                	sd	s2,432(sp)
    80005a6e:	f74e                	sd	s3,424(sp)
    80005a70:	f352                	sd	s4,416(sp)
    80005a72:	ef56                	sd	s5,408(sp)
    80005a74:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
 
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a76:	08000613          	li	a2,128
    80005a7a:	f4040593          	addi	a1,s0,-192
    80005a7e:	4501                	li	a0,0
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	210080e7          	jalr	528(ra) # 80002c90 <argstr>
    return -1;
    80005a88:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a8a:	0c054a63          	bltz	a0,80005b5e <sys_exec+0xfa>
    80005a8e:	e3840593          	addi	a1,s0,-456
    80005a92:	4505                	li	a0,1
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	1da080e7          	jalr	474(ra) # 80002c6e <argaddr>
    80005a9c:	0c054163          	bltz	a0,80005b5e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aa0:	10000613          	li	a2,256
    80005aa4:	4581                	li	a1,0
    80005aa6:	e4040513          	addi	a0,s0,-448
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	236080e7          	jalr	566(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ab2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab6:	89a6                	mv	s3,s1
    80005ab8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aba:	02000a13          	li	s4,32
    80005abe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ac2:	00391513          	slli	a0,s2,0x3
    80005ac6:	e3040593          	addi	a1,s0,-464
    80005aca:	e3843783          	ld	a5,-456(s0)
    80005ace:	953e                	add	a0,a0,a5
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	0e2080e7          	jalr	226(ra) # 80002bb2 <fetchaddr>
    80005ad8:	02054a63          	bltz	a0,80005b0c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005adc:	e3043783          	ld	a5,-464(s0)
    80005ae0:	c3b9                	beqz	a5,80005b26 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ae2:	ffffb097          	auipc	ra,0xffffb
    80005ae6:	012080e7          	jalr	18(ra) # 80000af4 <kalloc>
    80005aea:	85aa                	mv	a1,a0
    80005aec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005af0:	cd11                	beqz	a0,80005b0c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005af2:	6611                	lui	a2,0x4
    80005af4:	e3043503          	ld	a0,-464(s0)
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	10c080e7          	jalr	268(ra) # 80002c04 <fetchstr>
    80005b00:	00054663          	bltz	a0,80005b0c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b04:	0905                	addi	s2,s2,1
    80005b06:	09a1                	addi	s3,s3,8
    80005b08:	fb491be3          	bne	s2,s4,80005abe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0c:	10048913          	addi	s2,s1,256
    80005b10:	6088                	ld	a0,0(s1)
    80005b12:	c529                	beqz	a0,80005b5c <sys_exec+0xf8>
    kfree(argv[i]);
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	ee4080e7          	jalr	-284(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1c:	04a1                	addi	s1,s1,8
    80005b1e:	ff2499e3          	bne	s1,s2,80005b10 <sys_exec+0xac>
  return -1;
    80005b22:	597d                	li	s2,-1
    80005b24:	a82d                	j	80005b5e <sys_exec+0xfa>
      argv[i] = 0;
    80005b26:	0a8e                	slli	s5,s5,0x3
    80005b28:	fc040793          	addi	a5,s0,-64
    80005b2c:	9abe                	add	s5,s5,a5
    80005b2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b32:	e4040593          	addi	a1,s0,-448
    80005b36:	f4040513          	addi	a0,s0,-192
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	194080e7          	jalr	404(ra) # 80004cce <exec>
    80005b42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b44:	10048993          	addi	s3,s1,256
    80005b48:	6088                	ld	a0,0(s1)
    80005b4a:	c911                	beqz	a0,80005b5e <sys_exec+0xfa>
    kfree(argv[i]);
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	eac080e7          	jalr	-340(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b54:	04a1                	addi	s1,s1,8
    80005b56:	ff3499e3          	bne	s1,s3,80005b48 <sys_exec+0xe4>
    80005b5a:	a011                	j	80005b5e <sys_exec+0xfa>
  return -1;
    80005b5c:	597d                	li	s2,-1
}
    80005b5e:	854a                	mv	a0,s2
    80005b60:	60be                	ld	ra,456(sp)
    80005b62:	641e                	ld	s0,448(sp)
    80005b64:	74fa                	ld	s1,440(sp)
    80005b66:	795a                	ld	s2,432(sp)
    80005b68:	79ba                	ld	s3,424(sp)
    80005b6a:	7a1a                	ld	s4,416(sp)
    80005b6c:	6afa                	ld	s5,408(sp)
    80005b6e:	6179                	addi	sp,sp,464
    80005b70:	8082                	ret

0000000080005b72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b72:	7139                	addi	sp,sp,-64
    80005b74:	fc06                	sd	ra,56(sp)
    80005b76:	f822                	sd	s0,48(sp)
    80005b78:	f426                	sd	s1,40(sp)
    80005b7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b7c:	ffffc097          	auipc	ra,0xffffc
    80005b80:	fd4080e7          	jalr	-44(ra) # 80001b50 <myproc>
    80005b84:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b86:	fd840593          	addi	a1,s0,-40
    80005b8a:	4501                	li	a0,0
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	0e2080e7          	jalr	226(ra) # 80002c6e <argaddr>
    return -1;
    80005b94:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b96:	0e054063          	bltz	a0,80005c76 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b9a:	fc840593          	addi	a1,s0,-56
    80005b9e:	fd040513          	addi	a0,s0,-48
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	dfc080e7          	jalr	-516(ra) # 8000499e <pipealloc>
    return -1;
    80005baa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bac:	0c054563          	bltz	a0,80005c76 <sys_pipe+0x104>
  fd0 = -1;
    80005bb0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bb4:	fd043503          	ld	a0,-48(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	508080e7          	jalr	1288(ra) # 800050c0 <fdalloc>
    80005bc0:	fca42223          	sw	a0,-60(s0)
    80005bc4:	08054c63          	bltz	a0,80005c5c <sys_pipe+0xea>
    80005bc8:	fc843503          	ld	a0,-56(s0)
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	4f4080e7          	jalr	1268(ra) # 800050c0 <fdalloc>
    80005bd4:	fca42023          	sw	a0,-64(s0)
    80005bd8:	06054863          	bltz	a0,80005c48 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bdc:	4691                	li	a3,4
    80005bde:	fc440613          	addi	a2,s0,-60
    80005be2:	fd843583          	ld	a1,-40(s0)
    80005be6:	68a8                	ld	a0,80(s1)
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	c2a080e7          	jalr	-982(ra) # 80001812 <copyout>
    80005bf0:	02054063          	bltz	a0,80005c10 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bf4:	4691                	li	a3,4
    80005bf6:	fc040613          	addi	a2,s0,-64
    80005bfa:	fd843583          	ld	a1,-40(s0)
    80005bfe:	0591                	addi	a1,a1,4
    80005c00:	68a8                	ld	a0,80(s1)
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	c10080e7          	jalr	-1008(ra) # 80001812 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c0a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0c:	06055563          	bgez	a0,80005c76 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c10:	fc442783          	lw	a5,-60(s0)
    80005c14:	07e9                	addi	a5,a5,26
    80005c16:	078e                	slli	a5,a5,0x3
    80005c18:	97a6                	add	a5,a5,s1
    80005c1a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c1e:	fc042503          	lw	a0,-64(s0)
    80005c22:	0569                	addi	a0,a0,26
    80005c24:	050e                	slli	a0,a0,0x3
    80005c26:	9526                	add	a0,a0,s1
    80005c28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c2c:	fd043503          	ld	a0,-48(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	a3e080e7          	jalr	-1474(ra) # 8000466e <fileclose>
    fileclose(wf);
    80005c38:	fc843503          	ld	a0,-56(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a32080e7          	jalr	-1486(ra) # 8000466e <fileclose>
    return -1;
    80005c44:	57fd                	li	a5,-1
    80005c46:	a805                	j	80005c76 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c48:	fc442783          	lw	a5,-60(s0)
    80005c4c:	0007c863          	bltz	a5,80005c5c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c50:	01a78513          	addi	a0,a5,26
    80005c54:	050e                	slli	a0,a0,0x3
    80005c56:	9526                	add	a0,a0,s1
    80005c58:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c5c:	fd043503          	ld	a0,-48(s0)
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	a0e080e7          	jalr	-1522(ra) # 8000466e <fileclose>
    fileclose(wf);
    80005c68:	fc843503          	ld	a0,-56(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	a02080e7          	jalr	-1534(ra) # 8000466e <fileclose>
    return -1;
    80005c74:	57fd                	li	a5,-1
}
    80005c76:	853e                	mv	a0,a5
    80005c78:	70e2                	ld	ra,56(sp)
    80005c7a:	7442                	ld	s0,48(sp)
    80005c7c:	74a2                	ld	s1,40(sp)
    80005c7e:	6121                	addi	sp,sp,64
    80005c80:	8082                	ret

0000000080005c82 <sys_mmtrace>:

uint64 sys_mmtrace(void){
    80005c82:	1101                	addi	sp,sp,-32
    80005c84:	ec06                	sd	ra,24(sp)
    80005c86:	e822                	sd	s0,16(sp)
    80005c88:	1000                	addi	s0,sp,32
	uint64 va;
	argaddr(0,&va);
    80005c8a:	fe840593          	addi	a1,s0,-24
    80005c8e:	4501                	li	a0,0
    80005c90:	ffffd097          	auipc	ra,0xffffd
    80005c94:	fde080e7          	jalr	-34(ra) # 80002c6e <argaddr>
	struct proc *p = myproc();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	eb8080e7          	jalr	-328(ra) # 80001b50 <myproc>
	trace_mem(p->pagetable,va);
    80005ca0:	fe843583          	ld	a1,-24(s0)
    80005ca4:	6928                	ld	a0,80(a0)
    80005ca6:	ffffb097          	auipc	ra,0xffffb
    80005caa:	4d0080e7          	jalr	1232(ra) # 80001176 <trace_mem>
	return 0;
}
    80005cae:	4501                	li	a0,0
    80005cb0:	60e2                	ld	ra,24(sp)
    80005cb2:	6442                	ld	s0,16(sp)
    80005cb4:	6105                	addi	sp,sp,32
    80005cb6:	8082                	ret
	...

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	d7ffc0ef          	jal	ra,80002a7e <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	6d0c                	ld	a1,24(a0)
    80005d5c:	7110                	ld	a2,32(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	d8c080e7          	jalr	-628(ra) # 80001b24 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	d54080e7          	jalr	-684(ra) # 80001b24 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	d2c080e7          	jalr	-724(ra) # 80001b24 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	06a7c963          	blt	a5,a0,80005e92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e24:	00026797          	auipc	a5,0x26
    80005e28:	1dc78793          	addi	a5,a5,476 # 8002c000 <disk>
    80005e2c:	00a78733          	add	a4,a5,a0
    80005e30:	67a1                	lui	a5,0x8
    80005e32:	97ba                	add	a5,a5,a4
    80005e34:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005e38:	e7ad                	bnez	a5,80005ea2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e3a:	00451793          	slli	a5,a0,0x4
    80005e3e:	0002e717          	auipc	a4,0x2e
    80005e42:	1c270713          	addi	a4,a4,450 # 80034000 <disk+0x8000>
    80005e46:	6314                	ld	a3,0(a4)
    80005e48:	96be                	add	a3,a3,a5
    80005e4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e4e:	6314                	ld	a3,0(a4)
    80005e50:	96be                	add	a3,a3,a5
    80005e52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e56:	6314                	ld	a3,0(a4)
    80005e58:	96be                	add	a3,a3,a5
    80005e5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e5e:	6318                	ld	a4,0(a4)
    80005e60:	97ba                	add	a5,a5,a4
    80005e62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e66:	00026797          	auipc	a5,0x26
    80005e6a:	19a78793          	addi	a5,a5,410 # 8002c000 <disk>
    80005e6e:	97aa                	add	a5,a5,a0
    80005e70:	6521                	lui	a0,0x8
    80005e72:	953e                	add	a0,a0,a5
    80005e74:	4785                	li	a5,1
    80005e76:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005e7a:	0002e517          	auipc	a0,0x2e
    80005e7e:	19e50513          	addi	a0,a0,414 # 80034018 <disk+0x8018>
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	54a080e7          	jalr	1354(ra) # 800023cc <wakeup>
}
    80005e8a:	60a2                	ld	ra,8(sp)
    80005e8c:	6402                	ld	s0,0(sp)
    80005e8e:	0141                	addi	sp,sp,16
    80005e90:	8082                	ret
    panic("free_desc 1");
    80005e92:	00007517          	auipc	a0,0x7
    80005e96:	b6e50513          	addi	a0,a0,-1170 # 8000ca00 <syscalls+0x338>
    80005e9a:	ffffa097          	auipc	ra,0xffffa
    80005e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ea2:	00007517          	auipc	a0,0x7
    80005ea6:	b6e50513          	addi	a0,a0,-1170 # 8000ca10 <syscalls+0x348>
    80005eaa:	ffffa097          	auipc	ra,0xffffa
    80005eae:	694080e7          	jalr	1684(ra) # 8000053e <panic>

0000000080005eb2 <virtio_disk_init>:
{
    80005eb2:	1101                	addi	sp,sp,-32
    80005eb4:	ec06                	sd	ra,24(sp)
    80005eb6:	e822                	sd	s0,16(sp)
    80005eb8:	e426                	sd	s1,8(sp)
    80005eba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ebc:	00007597          	auipc	a1,0x7
    80005ec0:	b6458593          	addi	a1,a1,-1180 # 8000ca20 <syscalls+0x358>
    80005ec4:	0002e517          	auipc	a0,0x2e
    80005ec8:	26450513          	addi	a0,a0,612 # 80034128 <disk+0x8128>
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	c88080e7          	jalr	-888(ra) # 80000b54 <initlock>
	  printf("%x %x %x %x\n",
    80005ed4:	100014b7          	lui	s1,0x10001
    80005ed8:	408c                	lw	a1,0(s1)
    80005eda:	40d0                	lw	a2,4(s1)
    80005edc:	4494                	lw	a3,8(s1)
    80005ede:	44d8                	lw	a4,12(s1)
    80005ee0:	2701                	sext.w	a4,a4
    80005ee2:	2681                	sext.w	a3,a3
    80005ee4:	2601                	sext.w	a2,a2
    80005ee6:	2581                	sext.w	a1,a1
    80005ee8:	00007517          	auipc	a0,0x7
    80005eec:	b4850513          	addi	a0,a0,-1208 # 8000ca30 <syscalls+0x368>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	698080e7          	jalr	1688(ra) # 80000588 <printf>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ef8:	4098                	lw	a4,0(s1)
    80005efa:	2701                	sext.w	a4,a4
    80005efc:	747277b7          	lui	a5,0x74727
    80005f00:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f04:	0ef71163          	bne	a4,a5,80005fe6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	43dc                	lw	a5,4(a5)
    80005f0e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f10:	4705                	li	a4,1
    80005f12:	0ce79a63          	bne	a5,a4,80005fe6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f16:	100017b7          	lui	a5,0x10001
    80005f1a:	479c                	lw	a5,8(a5)
    80005f1c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f1e:	4709                	li	a4,2
    80005f20:	0ce79363          	bne	a5,a4,80005fe6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f24:	100017b7          	lui	a5,0x10001
    80005f28:	47d8                	lw	a4,12(a5)
    80005f2a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f2c:	554d47b7          	lui	a5,0x554d4
    80005f30:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f34:	0af71963          	bne	a4,a5,80005fe6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	4705                	li	a4,1
    80005f3e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f40:	470d                	li	a4,3
    80005f42:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f44:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f46:	c7ffe737          	lui	a4,0xc7ffe
    80005f4a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc675f>
    80005f4e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f50:	2701                	sext.w	a4,a4
    80005f52:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f54:	472d                	li	a4,11
    80005f56:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f58:	473d                	li	a4,15
    80005f5a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f5c:	6711                	lui	a4,0x4
    80005f5e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f60:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f64:	5bdc                	lw	a5,52(a5)
    80005f66:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f68:	c7d9                	beqz	a5,80005ff6 <virtio_disk_init+0x144>
  if(max < NUM)
    80005f6a:	471d                	li	a4,7
    80005f6c:	08f77d63          	bgeu	a4,a5,80006006 <virtio_disk_init+0x154>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f70:	100014b7          	lui	s1,0x10001
    80005f74:	47a1                	li	a5,8
    80005f76:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f78:	6621                	lui	a2,0x8
    80005f7a:	4581                	li	a1,0
    80005f7c:	00026517          	auipc	a0,0x26
    80005f80:	08450513          	addi	a0,a0,132 # 8002c000 <disk>
    80005f84:	ffffb097          	auipc	ra,0xffffb
    80005f88:	d5c080e7          	jalr	-676(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f8c:	00026717          	auipc	a4,0x26
    80005f90:	07470713          	addi	a4,a4,116 # 8002c000 <disk>
    80005f94:	00e75793          	srli	a5,a4,0xe
    80005f98:	2781                	sext.w	a5,a5
    80005f9a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f9c:	0002e797          	auipc	a5,0x2e
    80005fa0:	06478793          	addi	a5,a5,100 # 80034000 <disk+0x8000>
    80005fa4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fa6:	00026717          	auipc	a4,0x26
    80005faa:	0da70713          	addi	a4,a4,218 # 8002c080 <disk+0x80>
    80005fae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fb0:	0002a717          	auipc	a4,0x2a
    80005fb4:	05070713          	addi	a4,a4,80 # 80030000 <disk+0x4000>
    80005fb8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fba:	4705                	li	a4,1
    80005fbc:	00e78c23          	sb	a4,24(a5)
    80005fc0:	00e78ca3          	sb	a4,25(a5)
    80005fc4:	00e78d23          	sb	a4,26(a5)
    80005fc8:	00e78da3          	sb	a4,27(a5)
    80005fcc:	00e78e23          	sb	a4,28(a5)
    80005fd0:	00e78ea3          	sb	a4,29(a5)
    80005fd4:	00e78f23          	sb	a4,30(a5)
    80005fd8:	00e78fa3          	sb	a4,31(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret
    panic("could not find virtio disk");
    80005fe6:	00007517          	auipc	a0,0x7
    80005fea:	a5a50513          	addi	a0,a0,-1446 # 8000ca40 <syscalls+0x378>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	550080e7          	jalr	1360(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005ff6:	00007517          	auipc	a0,0x7
    80005ffa:	a6a50513          	addi	a0,a0,-1430 # 8000ca60 <syscalls+0x398>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006006:	00007517          	auipc	a0,0x7
    8000600a:	a7a50513          	addi	a0,a0,-1414 # 8000ca80 <syscalls+0x3b8>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	530080e7          	jalr	1328(ra) # 8000053e <panic>

0000000080006016 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006016:	7159                	addi	sp,sp,-112
    80006018:	f486                	sd	ra,104(sp)
    8000601a:	f0a2                	sd	s0,96(sp)
    8000601c:	eca6                	sd	s1,88(sp)
    8000601e:	e8ca                	sd	s2,80(sp)
    80006020:	e4ce                	sd	s3,72(sp)
    80006022:	e0d2                	sd	s4,64(sp)
    80006024:	fc56                	sd	s5,56(sp)
    80006026:	f85a                	sd	s6,48(sp)
    80006028:	f45e                	sd	s7,40(sp)
    8000602a:	f062                	sd	s8,32(sp)
    8000602c:	ec66                	sd	s9,24(sp)
    8000602e:	e86a                	sd	s10,16(sp)
    80006030:	1880                	addi	s0,sp,112
    80006032:	892a                	mv	s2,a0
    80006034:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006036:	00c52c83          	lw	s9,12(a0)
    8000603a:	001c9c9b          	slliw	s9,s9,0x1
    8000603e:	1c82                	slli	s9,s9,0x20
    80006040:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006044:	0002e517          	auipc	a0,0x2e
    80006048:	0e450513          	addi	a0,a0,228 # 80034128 <disk+0x8128>
    8000604c:	ffffb097          	auipc	ra,0xffffb
    80006050:	b98080e7          	jalr	-1128(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006054:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006056:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006058:	00026b97          	auipc	s7,0x26
    8000605c:	fa8b8b93          	addi	s7,s7,-88 # 8002c000 <disk>
    80006060:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80006062:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006064:	8a4e                	mv	s4,s3
    80006066:	a051                	j	800060ea <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006068:	00fb86b3          	add	a3,s7,a5
    8000606c:	96da                	add	a3,a3,s6
    8000606e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006072:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006074:	0207c563          	bltz	a5,8000609e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006078:	2485                	addiw	s1,s1,1
    8000607a:	0711                	addi	a4,a4,4
    8000607c:	25548463          	beq	s1,s5,800062c4 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80006080:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006082:	0002e697          	auipc	a3,0x2e
    80006086:	f9668693          	addi	a3,a3,-106 # 80034018 <disk+0x8018>
    8000608a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000608c:	0006c583          	lbu	a1,0(a3)
    80006090:	fde1                	bnez	a1,80006068 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006092:	2785                	addiw	a5,a5,1
    80006094:	0685                	addi	a3,a3,1
    80006096:	ff879be3          	bne	a5,s8,8000608c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000609a:	57fd                	li	a5,-1
    8000609c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000609e:	02905a63          	blez	s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060a2:	f9042503          	lw	a0,-112(s0)
    800060a6:	00000097          	auipc	ra,0x0
    800060aa:	d70080e7          	jalr	-656(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    800060ae:	4785                	li	a5,1
    800060b0:	0297d163          	bge	a5,s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060b4:	f9442503          	lw	a0,-108(s0)
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	d5e080e7          	jalr	-674(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    800060c0:	4789                	li	a5,2
    800060c2:	0097d863          	bge	a5,s1,800060d2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c6:	f9842503          	lw	a0,-104(s0)
    800060ca:	00000097          	auipc	ra,0x0
    800060ce:	d4c080e7          	jalr	-692(ra) # 80005e16 <free_desc>
  while(1){

    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060d2:	0002e597          	auipc	a1,0x2e
    800060d6:	05658593          	addi	a1,a1,86 # 80034128 <disk+0x8128>
    800060da:	0002e517          	auipc	a0,0x2e
    800060de:	f3e50513          	addi	a0,a0,-194 # 80034018 <disk+0x8018>
    800060e2:	ffffc097          	auipc	ra,0xffffc
    800060e6:	15e080e7          	jalr	350(ra) # 80002240 <sleep>
  for(int i = 0; i < 3; i++){
    800060ea:	f9040713          	addi	a4,s0,-112
    800060ee:	84ce                	mv	s1,s3
    800060f0:	bf41                	j	80006080 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060f2:	6705                	lui	a4,0x1
    800060f4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060f8:	972e                	add	a4,a4,a1
    800060fa:	0712                	slli	a4,a4,0x4
    800060fc:	00026697          	auipc	a3,0x26
    80006100:	f0468693          	addi	a3,a3,-252 # 8002c000 <disk>
    80006104:	9736                	add	a4,a4,a3
    80006106:	4685                	li	a3,1
    80006108:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000610c:	6705                	lui	a4,0x1
    8000610e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006112:	972e                	add	a4,a4,a1
    80006114:	0712                	slli	a4,a4,0x4
    80006116:	00026697          	auipc	a3,0x26
    8000611a:	eea68693          	addi	a3,a3,-278 # 8002c000 <disk>
    8000611e:	9736                	add	a4,a4,a3
    80006120:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006124:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006128:	7661                	lui	a2,0xffff8
    8000612a:	963e                	add	a2,a2,a5
    8000612c:	0002e697          	auipc	a3,0x2e
    80006130:	ed468693          	addi	a3,a3,-300 # 80034000 <disk+0x8000>
    80006134:	6298                	ld	a4,0(a3)
    80006136:	9732                	add	a4,a4,a2
    80006138:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000613a:	6298                	ld	a4,0(a3)
    8000613c:	9732                	add	a4,a4,a2
    8000613e:	4541                	li	a0,16
    80006140:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006142:	6298                	ld	a4,0(a3)
    80006144:	9732                	add	a4,a4,a2
    80006146:	4505                	li	a0,1
    80006148:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    8000614c:	f9442703          	lw	a4,-108(s0)
    80006150:	6288                	ld	a0,0(a3)
    80006152:	962a                	add	a2,a2,a0
    80006154:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc000e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006158:	0712                	slli	a4,a4,0x4
    8000615a:	6290                	ld	a2,0(a3)
    8000615c:	963a                	add	a2,a2,a4
    8000615e:	05890513          	addi	a0,s2,88
    80006162:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006164:	6294                	ld	a3,0(a3)
    80006166:	96ba                	add	a3,a3,a4
    80006168:	40000613          	li	a2,1024
    8000616c:	c690                	sw	a2,8(a3)
  if(write)
    8000616e:	140d0263          	beqz	s10,800062b2 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006172:	0002e697          	auipc	a3,0x2e
    80006176:	e8e6b683          	ld	a3,-370(a3) # 80034000 <disk+0x8000>
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006180:	00026817          	auipc	a6,0x26
    80006184:	e8080813          	addi	a6,a6,-384 # 8002c000 <disk>
    80006188:	0002e697          	auipc	a3,0x2e
    8000618c:	e7868693          	addi	a3,a3,-392 # 80034000 <disk+0x8000>
    80006190:	6290                	ld	a2,0(a3)
    80006192:	963a                	add	a2,a2,a4
    80006194:	00c65503          	lhu	a0,12(a2)
    80006198:	00156513          	ori	a0,a0,1
    8000619c:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800061a0:	f9842603          	lw	a2,-104(s0)
    800061a4:	6288                	ld	a0,0(a3)
    800061a6:	972a                	add	a4,a4,a0
    800061a8:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061ac:	6705                	lui	a4,0x1
    800061ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800061b2:	972e                	add	a4,a4,a1
    800061b4:	0712                	slli	a4,a4,0x4
    800061b6:	9742                	add	a4,a4,a6
    800061b8:	557d                	li	a0,-1
    800061ba:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061be:	0612                	slli	a2,a2,0x4
    800061c0:	6288                	ld	a0,0(a3)
    800061c2:	9532                	add	a0,a0,a2
    800061c4:	03078793          	addi	a5,a5,48
    800061c8:	97c2                	add	a5,a5,a6
    800061ca:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800061cc:	629c                	ld	a5,0(a3)
    800061ce:	97b2                	add	a5,a5,a2
    800061d0:	4505                	li	a0,1
    800061d2:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d4:	629c                	ld	a5,0(a3)
    800061d6:	97b2                	add	a5,a5,a2
    800061d8:	4809                	li	a6,2
    800061da:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061de:	629c                	ld	a5,0(a3)
    800061e0:	963e                	add	a2,a2,a5
    800061e2:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061e6:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    800061ea:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061ee:	6698                	ld	a4,8(a3)
    800061f0:	00275783          	lhu	a5,2(a4)
    800061f4:	8b9d                	andi	a5,a5,7
    800061f6:	0786                	slli	a5,a5,0x1
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061fe:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006202:	6698                	ld	a4,8(a3)
    80006204:	00275783          	lhu	a5,2(a4)
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000620e:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006212:	100017b7          	lui	a5,0x10001
    80006216:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000621a:	00492703          	lw	a4,4(s2)
    8000621e:	4785                	li	a5,1
    80006220:	02f71163          	bne	a4,a5,80006242 <virtio_disk_rw+0x22c>
	  
    sleep(b, &disk.vdisk_lock);
    80006224:	0002e997          	auipc	s3,0x2e
    80006228:	f0498993          	addi	s3,s3,-252 # 80034128 <disk+0x8128>
  while(b->disk == 1) {
    8000622c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000622e:	85ce                	mv	a1,s3
    80006230:	854a                	mv	a0,s2
    80006232:	ffffc097          	auipc	ra,0xffffc
    80006236:	00e080e7          	jalr	14(ra) # 80002240 <sleep>
  while(b->disk == 1) {
    8000623a:	00492783          	lw	a5,4(s2)
    8000623e:	fe9788e3          	beq	a5,s1,8000622e <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006242:	f9042903          	lw	s2,-112(s0)
    80006246:	6785                	lui	a5,0x1
    80006248:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000624c:	97ca                	add	a5,a5,s2
    8000624e:	0792                	slli	a5,a5,0x4
    80006250:	00026717          	auipc	a4,0x26
    80006254:	db070713          	addi	a4,a4,-592 # 8002c000 <disk>
    80006258:	97ba                	add	a5,a5,a4
    8000625a:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000625e:	0002e997          	auipc	s3,0x2e
    80006262:	da298993          	addi	s3,s3,-606 # 80034000 <disk+0x8000>
    80006266:	00491713          	slli	a4,s2,0x4
    8000626a:	0009b783          	ld	a5,0(s3)
    8000626e:	97ba                	add	a5,a5,a4
    80006270:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006274:	854a                	mv	a0,s2
    80006276:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000627a:	00000097          	auipc	ra,0x0
    8000627e:	b9c080e7          	jalr	-1124(ra) # 80005e16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006282:	8885                	andi	s1,s1,1
    80006284:	f0ed                	bnez	s1,80006266 <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006286:	0002e517          	auipc	a0,0x2e
    8000628a:	ea250513          	addi	a0,a0,-350 # 80034128 <disk+0x8128>
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
}
    80006296:	70a6                	ld	ra,104(sp)
    80006298:	7406                	ld	s0,96(sp)
    8000629a:	64e6                	ld	s1,88(sp)
    8000629c:	6946                	ld	s2,80(sp)
    8000629e:	69a6                	ld	s3,72(sp)
    800062a0:	6a06                	ld	s4,64(sp)
    800062a2:	7ae2                	ld	s5,56(sp)
    800062a4:	7b42                	ld	s6,48(sp)
    800062a6:	7ba2                	ld	s7,40(sp)
    800062a8:	7c02                	ld	s8,32(sp)
    800062aa:	6ce2                	ld	s9,24(sp)
    800062ac:	6d42                	ld	s10,16(sp)
    800062ae:	6165                	addi	sp,sp,112
    800062b0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062b2:	0002e697          	auipc	a3,0x2e
    800062b6:	d4e6b683          	ld	a3,-690(a3) # 80034000 <disk+0x8000>
    800062ba:	96ba                	add	a3,a3,a4
    800062bc:	4609                	li	a2,2
    800062be:	00c69623          	sh	a2,12(a3)
    800062c2:	bd7d                	j	80006180 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800062c4:	f9042583          	lw	a1,-112(s0)
    800062c8:	6785                	lui	a5,0x1
    800062ca:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800062ce:	97ae                	add	a5,a5,a1
    800062d0:	0792                	slli	a5,a5,0x4
    800062d2:	00026517          	auipc	a0,0x26
    800062d6:	dd650513          	addi	a0,a0,-554 # 8002c0a8 <disk+0xa8>
    800062da:	953e                	add	a0,a0,a5
  if(write)
    800062dc:	e00d1be3          	bnez	s10,800060f2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062e0:	6705                	lui	a4,0x1
    800062e2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800062e6:	972e                	add	a4,a4,a1
    800062e8:	0712                	slli	a4,a4,0x4
    800062ea:	00026697          	auipc	a3,0x26
    800062ee:	d1668693          	addi	a3,a3,-746 # 8002c000 <disk>
    800062f2:	9736                	add	a4,a4,a3
    800062f4:	0a072423          	sw	zero,168(a4)
    800062f8:	bd11                	j	8000610c <virtio_disk_rw+0xf6>

00000000800062fa <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062fa:	7179                	addi	sp,sp,-48
    800062fc:	f406                	sd	ra,40(sp)
    800062fe:	f022                	sd	s0,32(sp)
    80006300:	ec26                	sd	s1,24(sp)
    80006302:	e84a                	sd	s2,16(sp)
    80006304:	e44e                	sd	s3,8(sp)
    80006306:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    80006308:	0002e517          	auipc	a0,0x2e
    8000630c:	e2050513          	addi	a0,a0,-480 # 80034128 <disk+0x8128>
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	8d4080e7          	jalr	-1836(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006318:	10001737          	lui	a4,0x10001
    8000631c:	533c                	lw	a5,96(a4)
    8000631e:	8b8d                	andi	a5,a5,3
    80006320:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006322:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.
      disk.used->idx++;
    80006326:	0002e797          	auipc	a5,0x2e
    8000632a:	cda78793          	addi	a5,a5,-806 # 80034000 <disk+0x8000>
    8000632e:	6b94                	ld	a3,16(a5)
    80006330:	0026d703          	lhu	a4,2(a3)
    80006334:	2705                	addiw	a4,a4,1
    80006336:	00e69123          	sh	a4,2(a3)
  while(disk.used_idx != disk.used->idx){
    8000633a:	6b94                	ld	a3,16(a5)
    8000633c:	0207d703          	lhu	a4,32(a5)
    80006340:	0026d783          	lhu	a5,2(a3)
    80006344:	06f70363          	beq	a4,a5,800063aa <virtio_disk_intr+0xb0>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006348:	00026997          	auipc	s3,0x26
    8000634c:	cb898993          	addi	s3,s3,-840 # 8002c000 <disk>
    80006350:	0002e497          	auipc	s1,0x2e
    80006354:	cb048493          	addi	s1,s1,-848 # 80034000 <disk+0x8000>

    if(disk.info[id].status != 0)
    80006358:	6905                	lui	s2,0x1
    8000635a:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    8000635e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006362:	6898                	ld	a4,16(s1)
    80006364:	0204d783          	lhu	a5,32(s1)
    80006368:	8b9d                	andi	a5,a5,7
    8000636a:	078e                	slli	a5,a5,0x3
    8000636c:	97ba                	add	a5,a5,a4
    8000636e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006370:	01278733          	add	a4,a5,s2
    80006374:	0712                	slli	a4,a4,0x4
    80006376:	974e                	add	a4,a4,s3
    80006378:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000637c:	e731                	bnez	a4,800063c8 <virtio_disk_intr+0xce>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000637e:	97ca                	add	a5,a5,s2
    80006380:	0792                	slli	a5,a5,0x4
    80006382:	97ce                	add	a5,a5,s3
    80006384:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006386:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	042080e7          	jalr	66(ra) # 800023cc <wakeup>

    disk.used_idx += 1;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	17c2                	slli	a5,a5,0x30
    8000639a:	93c1                	srli	a5,a5,0x30
    8000639c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063a0:	6898                	ld	a4,16(s1)
    800063a2:	00275703          	lhu	a4,2(a4)
    800063a6:	faf71ce3          	bne	a4,a5,8000635e <virtio_disk_intr+0x64>
  }

  release(&disk.vdisk_lock);
    800063aa:	0002e517          	auipc	a0,0x2e
    800063ae:	d7e50513          	addi	a0,a0,-642 # 80034128 <disk+0x8128>
    800063b2:	ffffb097          	auipc	ra,0xffffb
    800063b6:	8e6080e7          	jalr	-1818(ra) # 80000c98 <release>
}
    800063ba:	70a2                	ld	ra,40(sp)
    800063bc:	7402                	ld	s0,32(sp)
    800063be:	64e2                	ld	s1,24(sp)
    800063c0:	6942                	ld	s2,16(sp)
    800063c2:	69a2                	ld	s3,8(sp)
    800063c4:	6145                	addi	sp,sp,48
    800063c6:	8082                	ret
      panic("virtio_disk_intr status");
    800063c8:	00006517          	auipc	a0,0x6
    800063cc:	6d850513          	addi	a0,a0,1752 # 8000caa0 <syscalls+0x3d8>
    800063d0:	ffffa097          	auipc	ra,0xffffa
    800063d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
