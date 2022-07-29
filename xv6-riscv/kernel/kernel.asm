
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
    80000068:	c1c78793          	addi	a5,a5,-996 # 80005c80 <timervec>
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
    80000130:	44e080e7          	jalr	1102(ra) # 8000257a <either_copyin>
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
    800001c8:	8cc080e7          	jalr	-1844(ra) # 80001a90 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fac080e7          	jalr	-84(ra) # 80002180 <sleep>
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
    80000214:	314080e7          	jalr	788(ra) # 80002524 <either_copyout>
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
    800002f6:	2de080e7          	jalr	734(ra) # 800025d0 <procdump>
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
    8000044a:	ec6080e7          	jalr	-314(ra) # 8000230c <wakeup>
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
    800008a4:	a6c080e7          	jalr	-1428(ra) # 8000230c <wakeup>
    
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
    80000930:	854080e7          	jalr	-1964(ra) # 80002180 <sleep>
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
    80000b82:	ef6080e7          	jalr	-266(ra) # 80001a74 <mycpu>
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
    80000bb4:	ec4080e7          	jalr	-316(ra) # 80001a74 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	eb8080e7          	jalr	-328(ra) # 80001a74 <mycpu>
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
    80000bd8:	ea0080e7          	jalr	-352(ra) # 80001a74 <mycpu>
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
    80000c18:	e60080e7          	jalr	-416(ra) # 80001a74 <mycpu>
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
    80000c44:	e34080e7          	jalr	-460(ra) # 80001a74 <mycpu>
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
    80000e9a:	bce080e7          	jalr	-1074(ra) # 80001a64 <cpuid>
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
    80000eb6:	bb2080e7          	jalr	-1102(ra) # 80001a64 <cpuid>
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
    80000ed8:	83c080e7          	jalr	-1988(ra) # 80002710 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	de4080e7          	jalr	-540(ra) # 80005cc0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0ea080e7          	jalr	234(ra) # 80001fce <scheduler>
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
    80000f58:	3cc080e7          	jalr	972(ra) # 80001320 <kvminit>
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
    80000f88:	a30080e7          	jalr	-1488(ra) # 800019b4 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	75c080e7          	jalr	1884(ra) # 800026e8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	77c080e7          	jalr	1916(ra) # 80002710 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	d0e080e7          	jalr	-754(ra) # 80005caa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	d1c080e7          	jalr	-740(ra) # 80005cc0 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	ec2080e7          	jalr	-318(ra) # 80002e6e <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	564080e7          	jalr	1380(ra) # 80003518 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	50e080e7          	jalr	1294(ra) # 800044ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	e1e080e7          	jalr	-482(ra) # 80005de2 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	d9c080e7          	jalr	-612(ra) # 80001d68 <userinit>
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
kvminithart()
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
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001018:	7139                	addi	sp,sp,-64
    8000101a:	fc06                	sd	ra,56(sp)
    8000101c:	f822                	sd	s0,48(sp)
    8000101e:	f426                	sd	s1,40(sp)
    80001020:	f04a                	sd	s2,32(sp)
    80001022:	ec4e                	sd	s3,24(sp)
    80001024:	e852                	sd	s4,16(sp)
    80001026:	e456                	sd	s5,8(sp)
    80001028:	e05a                	sd	s6,0(sp)
    8000102a:	0080                	addi	s0,sp,64
    8000102c:	84aa                	mv	s1,a0
    8000102e:	89ae                	mv	s3,a1
    80001030:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001032:	57fd                	li	a5,-1
    80001034:	83ed                	srli	a5,a5,0x1b
    80001036:	02000a13          	li	s4,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000103a:	4b39                	li	s6,14
  if(va >= MAXVA)
    8000103c:	04b7f263          	bgeu	a5,a1,80001080 <walk+0x68>
    panic("walk");
    80001040:	0000b517          	auipc	a0,0xb
    80001044:	11050513          	addi	a0,a0,272 # 8000c150 <digits+0x110>
    80001048:	fffff097          	auipc	ra,0xfffff
    8000104c:	4f6080e7          	jalr	1270(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001050:	060a8663          	beqz	s5,800010bc <walk+0xa4>
    80001054:	00000097          	auipc	ra,0x0
    80001058:	aa0080e7          	jalr	-1376(ra) # 80000af4 <kalloc>
    8000105c:	84aa                	mv	s1,a0
    8000105e:	c529                	beqz	a0,800010a8 <walk+0x90>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001060:	6611                	lui	a2,0x4
    80001062:	4581                	li	a1,0
    80001064:	00000097          	auipc	ra,0x0
    80001068:	c7c080e7          	jalr	-900(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106c:	00e4d793          	srli	a5,s1,0xe
    80001070:	07aa                	slli	a5,a5,0xa
    80001072:	0017e793          	ori	a5,a5,1
    80001076:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000107a:	3a5d                	addiw	s4,s4,-9
    8000107c:	036a0063          	beq	s4,s6,8000109c <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)];
    80001080:	0149d933          	srl	s2,s3,s4
    80001084:	1ff97913          	andi	s2,s2,511
    80001088:	090e                	slli	s2,s2,0x3
    8000108a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000108c:	00093483          	ld	s1,0(s2)
    80001090:	0014f793          	andi	a5,s1,1
    80001094:	dfd5                	beqz	a5,80001050 <walk+0x38>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001096:	80a9                	srli	s1,s1,0xa
    80001098:	04ba                	slli	s1,s1,0xe
    8000109a:	b7c5                	j	8000107a <walk+0x62>
    }
  }
 /// printf("get final PTE %x at %dth pte in pagetable %x for VA %x, which PA is %x \n",pagetable[PX(0,va)],PX(0,va),pagetable, va, PTE2PA(pagetable[PX(0,va)]));
  return &pagetable[PX(0, va)];
    8000109c:	00e9d513          	srli	a0,s3,0xe
    800010a0:	1ff57513          	andi	a0,a0,511
    800010a4:	050e                	slli	a0,a0,0x3
    800010a6:	9526                	add	a0,a0,s1
}
    800010a8:	70e2                	ld	ra,56(sp)
    800010aa:	7442                	ld	s0,48(sp)
    800010ac:	74a2                	ld	s1,40(sp)
    800010ae:	7902                	ld	s2,32(sp)
    800010b0:	69e2                	ld	s3,24(sp)
    800010b2:	6a42                	ld	s4,16(sp)
    800010b4:	6aa2                	ld	s5,8(sp)
    800010b6:	6b02                	ld	s6,0(sp)
    800010b8:	6121                	addi	sp,sp,64
    800010ba:	8082                	ret
        return 0;
    800010bc:	4501                	li	a0,0
    800010be:	b7ed                	j	800010a8 <walk+0x90>

00000000800010c0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010c0:	57fd                	li	a5,-1
    800010c2:	83ed                	srli	a5,a5,0x1b
    800010c4:	00b7f463          	bgeu	a5,a1,800010cc <walkaddr+0xc>
    return 0;
    800010c8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ca:	8082                	ret
{
    800010cc:	1141                	addi	sp,sp,-16
    800010ce:	e406                	sd	ra,8(sp)
    800010d0:	e022                	sd	s0,0(sp)
    800010d2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d4:	4601                	li	a2,0
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	f42080e7          	jalr	-190(ra) # 80001018 <walk>
  if(pte == 0)
    800010de:	c105                	beqz	a0,800010fe <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010e0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010e2:	0117f693          	andi	a3,a5,17
    800010e6:	4745                	li	a4,17
    return 0;
    800010e8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ea:	00e68663          	beq	a3,a4,800010f6 <walkaddr+0x36>
}
    800010ee:	60a2                	ld	ra,8(sp)
    800010f0:	6402                	ld	s0,0(sp)
    800010f2:	0141                	addi	sp,sp,16
    800010f4:	8082                	ret
  pa = PTE2PA(*pte);
    800010f6:	00a7d513          	srli	a0,a5,0xa
    800010fa:	053a                	slli	a0,a0,0xe
  return pa;
    800010fc:	bfcd                	j	800010ee <walkaddr+0x2e>
    return 0;
    800010fe:	4501                	li	a0,0
    80001100:	b7fd                	j	800010ee <walkaddr+0x2e>

0000000080001102 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001102:	715d                	addi	sp,sp,-80
    80001104:	e486                	sd	ra,72(sp)
    80001106:	e0a2                	sd	s0,64(sp)
    80001108:	fc26                	sd	s1,56(sp)
    8000110a:	f84a                	sd	s2,48(sp)
    8000110c:	f44e                	sd	s3,40(sp)
    8000110e:	f052                	sd	s4,32(sp)
    80001110:	ec56                	sd	s5,24(sp)
    80001112:	e85a                	sd	s6,16(sp)
    80001114:	e45e                	sd	s7,8(sp)
    80001116:	e062                	sd	s8,0(sp)
    80001118:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;


  if(size == 0)
    8000111a:	ce05                	beqz	a2,80001152 <mappages+0x50>
    8000111c:	8aaa                	mv	s5,a0
    8000111e:	89ae                	mv	s3,a1
    80001120:	8932                	mv	s2,a2
    80001122:	8a36                	mv	s4,a3
    80001124:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001126:	7c71                	lui	s8,0xffffc
    80001128:	0185fbb3          	and	s7,a1,s8
  printf("mapping VA %x to PA %x in size %x..\n",va,pa,size);
    8000112c:	86b2                	mv	a3,a2
    8000112e:	8652                	mv	a2,s4
    80001130:	0000b517          	auipc	a0,0xb
    80001134:	03850513          	addi	a0,a0,56 # 8000c168 <digits+0x128>
    80001138:	fffff097          	auipc	ra,0xfffff
    8000113c:	450080e7          	jalr	1104(ra) # 80000588 <printf>
  last = PGROUNDDOWN(va + size - 1);
    80001140:	19fd                	addi	s3,s3,-1
    80001142:	99ca                	add	s3,s3,s2
    80001144:	0189f9b3          	and	s3,s3,s8
  a = PGROUNDDOWN(va);
    80001148:	895e                	mv	s2,s7
    8000114a:	417a0a33          	sub	s4,s4,s7
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000114e:	6b91                	lui	s7,0x4
    80001150:	a015                	j	80001174 <mappages+0x72>
    panic("mappages: size");
    80001152:	0000b517          	auipc	a0,0xb
    80001156:	00650513          	addi	a0,a0,6 # 8000c158 <digits+0x118>
    8000115a:	fffff097          	auipc	ra,0xfffff
    8000115e:	3e4080e7          	jalr	996(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001162:	0000b517          	auipc	a0,0xb
    80001166:	02e50513          	addi	a0,a0,46 # 8000c190 <digits+0x150>
    8000116a:	fffff097          	auipc	ra,0xfffff
    8000116e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>
    a += PGSIZE;
    80001172:	995e                	add	s2,s2,s7
  for(;;){
    80001174:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	4605                	li	a2,1
    8000117a:	85ca                	mv	a1,s2
    8000117c:	8556                	mv	a0,s5
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	e9a080e7          	jalr	-358(ra) # 80001018 <walk>
    80001186:	cd19                	beqz	a0,800011a4 <mappages+0xa2>
    if(*pte & PTE_V)
    80001188:	611c                	ld	a5,0(a0)
    8000118a:	8b85                	andi	a5,a5,1
    8000118c:	fbf9                	bnez	a5,80001162 <mappages+0x60>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118e:	80b9                	srli	s1,s1,0xe
    80001190:	04aa                	slli	s1,s1,0xa
    80001192:	0164e4b3          	or	s1,s1,s6
    80001196:	0014e493          	ori	s1,s1,1
    8000119a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000119c:	fd391be3          	bne	s2,s3,80001172 <mappages+0x70>
    pa += PGSIZE;
  }
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	a011                	j	800011a6 <mappages+0xa4>
      return -1;
    800011a4:	557d                	li	a0,-1
}
    800011a6:	60a6                	ld	ra,72(sp)
    800011a8:	6406                	ld	s0,64(sp)
    800011aa:	74e2                	ld	s1,56(sp)
    800011ac:	7942                	ld	s2,48(sp)
    800011ae:	79a2                	ld	s3,40(sp)
    800011b0:	7a02                	ld	s4,32(sp)
    800011b2:	6ae2                	ld	s5,24(sp)
    800011b4:	6b42                	ld	s6,16(sp)
    800011b6:	6ba2                	ld	s7,8(sp)
    800011b8:	6c02                	ld	s8,0(sp)
    800011ba:	6161                	addi	sp,sp,80
    800011bc:	8082                	ret

00000000800011be <kvmmap>:
{
    800011be:	1141                	addi	sp,sp,-16
    800011c0:	e406                	sd	ra,8(sp)
    800011c2:	e022                	sd	s0,0(sp)
    800011c4:	0800                	addi	s0,sp,16
    800011c6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c8:	86b2                	mv	a3,a2
    800011ca:	863e                	mv	a2,a5
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f36080e7          	jalr	-202(ra) # 80001102 <mappages>
    800011d4:	e509                	bnez	a0,800011de <kvmmap+0x20>
}
    800011d6:	60a2                	ld	ra,8(sp)
    800011d8:	6402                	ld	s0,0(sp)
    800011da:	0141                	addi	sp,sp,16
    800011dc:	8082                	ret
    panic("kvmmap");
    800011de:	0000b517          	auipc	a0,0xb
    800011e2:	fc250513          	addi	a0,a0,-62 # 8000c1a0 <digits+0x160>
    800011e6:	fffff097          	auipc	ra,0xfffff
    800011ea:	358080e7          	jalr	856(ra) # 8000053e <panic>

00000000800011ee <kvmmake>:
{
    800011ee:	7179                	addi	sp,sp,-48
    800011f0:	f406                	sd	ra,40(sp)
    800011f2:	f022                	sd	s0,32(sp)
    800011f4:	ec26                	sd	s1,24(sp)
    800011f6:	e84a                	sd	s2,16(sp)
    800011f8:	e44e                	sd	s3,8(sp)
    800011fa:	1800                	addi	s0,sp,48
  kpgtbl = (pagetable_t) kalloc();
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	8f8080e7          	jalr	-1800(ra) # 80000af4 <kalloc>
    80001204:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001206:	6611                	lui	a2,0x4
    80001208:	4581                	li	a1,0
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	ad6080e7          	jalr	-1322(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	6691                	lui	a3,0x4
    80001216:	10000637          	lui	a2,0x10000
    8000121a:	100005b7          	lui	a1,0x10000
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f9e080e7          	jalr	-98(ra) # 800011be <kvmmap>
  printf("mapping uart in %x\n", UART0);
    80001228:	100005b7          	lui	a1,0x10000
    8000122c:	0000b517          	auipc	a0,0xb
    80001230:	f7c50513          	addi	a0,a0,-132 # 8000c1a8 <digits+0x168>
    80001234:	fffff097          	auipc	ra,0xfffff
    80001238:	354080e7          	jalr	852(ra) # 80000588 <printf>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123c:	4719                	li	a4,6
    8000123e:	004006b7          	lui	a3,0x400
    80001242:	0c000637          	lui	a2,0xc000
    80001246:	0c0005b7          	lui	a1,0xc000
    8000124a:	8526                	mv	a0,s1
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f72080e7          	jalr	-142(ra) # 800011be <kvmmap>
  printf("mapping PLIC in %x\n", PLIC);
    80001254:	0c0005b7          	lui	a1,0xc000
    80001258:	0000b517          	auipc	a0,0xb
    8000125c:	f6850513          	addi	a0,a0,-152 # 8000c1c0 <digits+0x180>
    80001260:	fffff097          	auipc	ra,0xfffff
    80001264:	328080e7          	jalr	808(ra) # 80000588 <printf>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001268:	0000b917          	auipc	s2,0xb
    8000126c:	d9890913          	addi	s2,s2,-616 # 8000c000 <etext>
    80001270:	4729                	li	a4,10
    80001272:	8000b697          	auipc	a3,0x8000b
    80001276:	d8e68693          	addi	a3,a3,-626 # c000 <_entry-0x7fff4000>
    8000127a:	4985                	li	s3,1
    8000127c:	01f99613          	slli	a2,s3,0x1f
    80001280:	85b2                	mv	a1,a2
    80001282:	8526                	mv	a0,s1
    80001284:	00000097          	auipc	ra,0x0
    80001288:	f3a080e7          	jalr	-198(ra) # 800011be <kvmmap>
  printf("mapping kernel text in %x\n", KERNBASE);
    8000128c:	01f99593          	slli	a1,s3,0x1f
    80001290:	0000b517          	auipc	a0,0xb
    80001294:	f4850513          	addi	a0,a0,-184 # 8000c1d8 <digits+0x198>
    80001298:	fffff097          	auipc	ra,0xfffff
    8000129c:	2f0080e7          	jalr	752(ra) # 80000588 <printf>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a0:	4719                	li	a4,6
    800012a2:	46c5                	li	a3,17
    800012a4:	06ee                	slli	a3,a3,0x1b
    800012a6:	412686b3          	sub	a3,a3,s2
    800012aa:	864a                	mv	a2,s2
    800012ac:	85ca                	mv	a1,s2
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f0e080e7          	jalr	-242(ra) # 800011be <kvmmap>
  printf("mapping trampoline for trap from %x to %x.\n",TRAMPOLINE, trampoline);
    800012b8:	00007617          	auipc	a2,0x7
    800012bc:	d4860613          	addi	a2,a2,-696 # 80008000 <_trampoline>
    800012c0:	00800937          	lui	s2,0x800
    800012c4:	197d                	addi	s2,s2,-1
    800012c6:	00e91593          	slli	a1,s2,0xe
    800012ca:	0000b517          	auipc	a0,0xb
    800012ce:	f2e50513          	addi	a0,a0,-210 # 8000c1f8 <digits+0x1b8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	2b6080e7          	jalr	694(ra) # 80000588 <printf>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012da:	4729                	li	a4,10
    800012dc:	6691                	lui	a3,0x4
    800012de:	00007617          	auipc	a2,0x7
    800012e2:	d2260613          	addi	a2,a2,-734 # 80008000 <_trampoline>
    800012e6:	00e91593          	slli	a1,s2,0xe
    800012ea:	8526                	mv	a0,s1
    800012ec:	00000097          	auipc	ra,0x0
    800012f0:	ed2080e7          	jalr	-302(ra) # 800011be <kvmmap>
  proc_mapstacks(kpgtbl);
    800012f4:	8526                	mv	a0,s1
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	628080e7          	jalr	1576(ra) # 8000191e <proc_mapstacks>
  printf("kernel pagetable created with VA: %x.\n",kpgtbl);
    800012fe:	85a6                	mv	a1,s1
    80001300:	0000b517          	auipc	a0,0xb
    80001304:	f2850513          	addi	a0,a0,-216 # 8000c228 <digits+0x1e8>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	280080e7          	jalr	640(ra) # 80000588 <printf>
}
    80001310:	8526                	mv	a0,s1
    80001312:	70a2                	ld	ra,40(sp)
    80001314:	7402                	ld	s0,32(sp)
    80001316:	64e2                	ld	s1,24(sp)
    80001318:	6942                	ld	s2,16(sp)
    8000131a:	69a2                	ld	s3,8(sp)
    8000131c:	6145                	addi	sp,sp,48
    8000131e:	8082                	ret

0000000080001320 <kvminit>:
{
    80001320:	1141                	addi	sp,sp,-16
    80001322:	e406                	sd	ra,8(sp)
    80001324:	e022                	sd	s0,0(sp)
    80001326:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001328:	00000097          	auipc	ra,0x0
    8000132c:	ec6080e7          	jalr	-314(ra) # 800011ee <kvmmake>
    80001330:	0000f797          	auipc	a5,0xf
    80001334:	cea7b823          	sd	a0,-784(a5) # 80010020 <kernel_pagetable>
}
    80001338:	60a2                	ld	ra,8(sp)
    8000133a:	6402                	ld	s0,0(sp)
    8000133c:	0141                	addi	sp,sp,16
    8000133e:	8082                	ret

0000000080001340 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001340:	715d                	addi	sp,sp,-80
    80001342:	e486                	sd	ra,72(sp)
    80001344:	e0a2                	sd	s0,64(sp)
    80001346:	fc26                	sd	s1,56(sp)
    80001348:	f84a                	sd	s2,48(sp)
    8000134a:	f44e                	sd	s3,40(sp)
    8000134c:	f052                	sd	s4,32(sp)
    8000134e:	ec56                	sd	s5,24(sp)
    80001350:	e85a                	sd	s6,16(sp)
    80001352:	e45e                	sd	s7,8(sp)
    80001354:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001356:	03259793          	slli	a5,a1,0x32
    8000135a:	e795                	bnez	a5,80001386 <uvmunmap+0x46>
    8000135c:	8a2a                	mv	s4,a0
    8000135e:	892e                	mv	s2,a1
    80001360:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001362:	063a                	slli	a2,a2,0xe
    80001364:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001368:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136a:	6b11                	lui	s6,0x4
    8000136c:	0735e863          	bltu	a1,s3,800013dc <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001370:	60a6                	ld	ra,72(sp)
    80001372:	6406                	ld	s0,64(sp)
    80001374:	74e2                	ld	s1,56(sp)
    80001376:	7942                	ld	s2,48(sp)
    80001378:	79a2                	ld	s3,40(sp)
    8000137a:	7a02                	ld	s4,32(sp)
    8000137c:	6ae2                	ld	s5,24(sp)
    8000137e:	6b42                	ld	s6,16(sp)
    80001380:	6ba2                	ld	s7,8(sp)
    80001382:	6161                	addi	sp,sp,80
    80001384:	8082                	ret
    panic("uvmunmap: not aligned");
    80001386:	0000b517          	auipc	a0,0xb
    8000138a:	eca50513          	addi	a0,a0,-310 # 8000c250 <digits+0x210>
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	1b0080e7          	jalr	432(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001396:	0000b517          	auipc	a0,0xb
    8000139a:	ed250513          	addi	a0,a0,-302 # 8000c268 <digits+0x228>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	1a0080e7          	jalr	416(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013a6:	0000b517          	auipc	a0,0xb
    800013aa:	ed250513          	addi	a0,a0,-302 # 8000c278 <digits+0x238>
    800013ae:	fffff097          	auipc	ra,0xfffff
    800013b2:	190080e7          	jalr	400(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013b6:	0000b517          	auipc	a0,0xb
    800013ba:	eda50513          	addi	a0,a0,-294 # 8000c290 <digits+0x250>
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800013c6:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013c8:	053a                	slli	a0,a0,0xe
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	62e080e7          	jalr	1582(ra) # 800009f8 <kfree>
    *pte = 0;
    800013d2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d6:	995a                	add	s2,s2,s6
    800013d8:	f9397ce3          	bgeu	s2,s3,80001370 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013dc:	4601                	li	a2,0
    800013de:	85ca                	mv	a1,s2
    800013e0:	8552                	mv	a0,s4
    800013e2:	00000097          	auipc	ra,0x0
    800013e6:	c36080e7          	jalr	-970(ra) # 80001018 <walk>
    800013ea:	84aa                	mv	s1,a0
    800013ec:	d54d                	beqz	a0,80001396 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013ee:	6108                	ld	a0,0(a0)
    800013f0:	00157793          	andi	a5,a0,1
    800013f4:	dbcd                	beqz	a5,800013a6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f6:	3ff57793          	andi	a5,a0,1023
    800013fa:	fb778ee3          	beq	a5,s7,800013b6 <uvmunmap+0x76>
    if(do_free){
    800013fe:	fc0a8ae3          	beqz	s5,800013d2 <uvmunmap+0x92>
    80001402:	b7d1                	j	800013c6 <uvmunmap+0x86>

0000000080001404 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001404:	1101                	addi	sp,sp,-32
    80001406:	ec06                	sd	ra,24(sp)
    80001408:	e822                	sd	s0,16(sp)
    8000140a:	e426                	sd	s1,8(sp)
    8000140c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000140e:	fffff097          	auipc	ra,0xfffff
    80001412:	6e6080e7          	jalr	1766(ra) # 80000af4 <kalloc>
    80001416:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001418:	c519                	beqz	a0,80001426 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000141a:	6611                	lui	a2,0x4
    8000141c:	4581                	li	a1,0
    8000141e:	00000097          	auipc	ra,0x0
    80001422:	8c2080e7          	jalr	-1854(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001426:	8526                	mv	a0,s1
    80001428:	60e2                	ld	ra,24(sp)
    8000142a:	6442                	ld	s0,16(sp)
    8000142c:	64a2                	ld	s1,8(sp)
    8000142e:	6105                	addi	sp,sp,32
    80001430:	8082                	ret

0000000080001432 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001432:	7179                	addi	sp,sp,-48
    80001434:	f406                	sd	ra,40(sp)
    80001436:	f022                	sd	s0,32(sp)
    80001438:	ec26                	sd	s1,24(sp)
    8000143a:	e84a                	sd	s2,16(sp)
    8000143c:	e44e                	sd	s3,8(sp)
    8000143e:	e052                	sd	s4,0(sp)
    80001440:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001442:	6791                	lui	a5,0x4
    80001444:	06f67363          	bgeu	a2,a5,800014aa <uvminit+0x78>
    80001448:	89aa                	mv	s3,a0
    8000144a:	8a2e                	mv	s4,a1
    8000144c:	8932                	mv	s2,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
  memset(mem, 0, PGSIZE);
    80001458:	6611                	lui	a2,0x4
    8000145a:	4581                	li	a1,0
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	884080e7          	jalr	-1916(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001464:	4779                	li	a4,30
    80001466:	86a6                	mv	a3,s1
    80001468:	6611                	lui	a2,0x4
    8000146a:	4581                	li	a1,0
    8000146c:	854e                	mv	a0,s3
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	c94080e7          	jalr	-876(ra) # 80001102 <mappages>
  memmove(mem, src, sz);
    80001476:	864a                	mv	a2,s2
    80001478:	85d2                	mv	a1,s4
    8000147a:	8526                	mv	a0,s1
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	8c4080e7          	jalr	-1852(ra) # 80000d40 <memmove>

  printf("use a page %d in loc %x in pagetable %x to store codes.\n", PGSIZE, mem, pagetable);
    80001484:	86ce                	mv	a3,s3
    80001486:	8626                	mv	a2,s1
    80001488:	6591                	lui	a1,0x4
    8000148a:	0000b517          	auipc	a0,0xb
    8000148e:	e3e50513          	addi	a0,a0,-450 # 8000c2c8 <digits+0x288>
    80001492:	fffff097          	auipc	ra,0xfffff
    80001496:	0f6080e7          	jalr	246(ra) # 80000588 <printf>
}
    8000149a:	70a2                	ld	ra,40(sp)
    8000149c:	7402                	ld	s0,32(sp)
    8000149e:	64e2                	ld	s1,24(sp)
    800014a0:	6942                	ld	s2,16(sp)
    800014a2:	69a2                	ld	s3,8(sp)
    800014a4:	6a02                	ld	s4,0(sp)
    800014a6:	6145                	addi	sp,sp,48
    800014a8:	8082                	ret
    panic("inituvm: more than a page");
    800014aa:	0000b517          	auipc	a0,0xb
    800014ae:	dfe50513          	addi	a0,a0,-514 # 8000c2a8 <digits+0x268>
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	08c080e7          	jalr	140(ra) # 8000053e <panic>

00000000800014ba <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ba:	1101                	addi	sp,sp,-32
    800014bc:	ec06                	sd	ra,24(sp)
    800014be:	e822                	sd	s0,16(sp)
    800014c0:	e426                	sd	s1,8(sp)
    800014c2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014c4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014c6:	00b67d63          	bgeu	a2,a1,800014e0 <uvmdealloc+0x26>
    800014ca:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014cc:	6791                	lui	a5,0x4
    800014ce:	17fd                	addi	a5,a5,-1
    800014d0:	00f60733          	add	a4,a2,a5
    800014d4:	7671                	lui	a2,0xffffc
    800014d6:	8f71                	and	a4,a4,a2
    800014d8:	97ae                	add	a5,a5,a1
    800014da:	8ff1                	and	a5,a5,a2
    800014dc:	00f76863          	bltu	a4,a5,800014ec <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014e0:	8526                	mv	a0,s1
    800014e2:	60e2                	ld	ra,24(sp)
    800014e4:	6442                	ld	s0,16(sp)
    800014e6:	64a2                	ld	s1,8(sp)
    800014e8:	6105                	addi	sp,sp,32
    800014ea:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014ec:	8f99                	sub	a5,a5,a4
    800014ee:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014f0:	4685                	li	a3,1
    800014f2:	0007861b          	sext.w	a2,a5
    800014f6:	85ba                	mv	a1,a4
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	e48080e7          	jalr	-440(ra) # 80001340 <uvmunmap>
    80001500:	b7c5                	j	800014e0 <uvmdealloc+0x26>

0000000080001502 <uvmalloc>:
  if(newsz < oldsz)
    80001502:	0ab66163          	bltu	a2,a1,800015a4 <uvmalloc+0xa2>
{
    80001506:	7139                	addi	sp,sp,-64
    80001508:	fc06                	sd	ra,56(sp)
    8000150a:	f822                	sd	s0,48(sp)
    8000150c:	f426                	sd	s1,40(sp)
    8000150e:	f04a                	sd	s2,32(sp)
    80001510:	ec4e                	sd	s3,24(sp)
    80001512:	e852                	sd	s4,16(sp)
    80001514:	e456                	sd	s5,8(sp)
    80001516:	0080                	addi	s0,sp,64
    80001518:	8aaa                	mv	s5,a0
    8000151a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000151c:	6991                	lui	s3,0x4
    8000151e:	19fd                	addi	s3,s3,-1
    80001520:	95ce                	add	a1,a1,s3
    80001522:	79f1                	lui	s3,0xffffc
    80001524:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001528:	08c9f063          	bgeu	s3,a2,800015a8 <uvmalloc+0xa6>
    8000152c:	894e                	mv	s2,s3
    mem = kalloc();
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	5c6080e7          	jalr	1478(ra) # 80000af4 <kalloc>
    80001536:	84aa                	mv	s1,a0
    if(mem == 0){
    80001538:	c51d                	beqz	a0,80001566 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000153a:	6611                	lui	a2,0x4
    8000153c:	4581                	li	a1,0
    8000153e:	fffff097          	auipc	ra,0xfffff
    80001542:	7a2080e7          	jalr	1954(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001546:	4779                	li	a4,30
    80001548:	86a6                	mv	a3,s1
    8000154a:	6611                	lui	a2,0x4
    8000154c:	85ca                	mv	a1,s2
    8000154e:	8556                	mv	a0,s5
    80001550:	00000097          	auipc	ra,0x0
    80001554:	bb2080e7          	jalr	-1102(ra) # 80001102 <mappages>
    80001558:	e905                	bnez	a0,80001588 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000155a:	6791                	lui	a5,0x4
    8000155c:	993e                	add	s2,s2,a5
    8000155e:	fd4968e3          	bltu	s2,s4,8000152e <uvmalloc+0x2c>
  return newsz;
    80001562:	8552                	mv	a0,s4
    80001564:	a809                	j	80001576 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001566:	864e                	mv	a2,s3
    80001568:	85ca                	mv	a1,s2
    8000156a:	8556                	mv	a0,s5
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	f4e080e7          	jalr	-178(ra) # 800014ba <uvmdealloc>
      return 0;
    80001574:	4501                	li	a0,0
}
    80001576:	70e2                	ld	ra,56(sp)
    80001578:	7442                	ld	s0,48(sp)
    8000157a:	74a2                	ld	s1,40(sp)
    8000157c:	7902                	ld	s2,32(sp)
    8000157e:	69e2                	ld	s3,24(sp)
    80001580:	6a42                	ld	s4,16(sp)
    80001582:	6aa2                	ld	s5,8(sp)
    80001584:	6121                	addi	sp,sp,64
    80001586:	8082                	ret
      kfree(mem);
    80001588:	8526                	mv	a0,s1
    8000158a:	fffff097          	auipc	ra,0xfffff
    8000158e:	46e080e7          	jalr	1134(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001592:	864e                	mv	a2,s3
    80001594:	85ca                	mv	a1,s2
    80001596:	8556                	mv	a0,s5
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	f22080e7          	jalr	-222(ra) # 800014ba <uvmdealloc>
      return 0;
    800015a0:	4501                	li	a0,0
    800015a2:	bfd1                	j	80001576 <uvmalloc+0x74>
    return oldsz;
    800015a4:	852e                	mv	a0,a1
}
    800015a6:	8082                	ret
  return newsz;
    800015a8:	8532                	mv	a0,a2
    800015aa:	b7f1                	j	80001576 <uvmalloc+0x74>

00000000800015ac <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015ac:	7179                	addi	sp,sp,-48
    800015ae:	f406                	sd	ra,40(sp)
    800015b0:	f022                	sd	s0,32(sp)
    800015b2:	ec26                	sd	s1,24(sp)
    800015b4:	e84a                	sd	s2,16(sp)
    800015b6:	e44e                	sd	s3,8(sp)
    800015b8:	e052                	sd	s4,0(sp)
    800015ba:	1800                	addi	s0,sp,48
    800015bc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015be:	84aa                	mv	s1,a0
    800015c0:	6905                	lui	s2,0x1
    800015c2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015c4:	4985                	li	s3,1
    800015c6:	a821                	j	800015de <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015c8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015ca:	053a                	slli	a0,a0,0xe
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	fe0080e7          	jalr	-32(ra) # 800015ac <freewalk>
      pagetable[i] = 0;
    800015d4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015d8:	04a1                	addi	s1,s1,8
    800015da:	03248163          	beq	s1,s2,800015fc <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015de:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e0:	00f57793          	andi	a5,a0,15
    800015e4:	ff3782e3          	beq	a5,s3,800015c8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015e8:	8905                	andi	a0,a0,1
    800015ea:	d57d                	beqz	a0,800015d8 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015ec:	0000b517          	auipc	a0,0xb
    800015f0:	d1c50513          	addi	a0,a0,-740 # 8000c308 <digits+0x2c8>
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	f4a080e7          	jalr	-182(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    800015fc:	8552                	mv	a0,s4
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	3fa080e7          	jalr	1018(ra) # 800009f8 <kfree>
}
    80001606:	70a2                	ld	ra,40(sp)
    80001608:	7402                	ld	s0,32(sp)
    8000160a:	64e2                	ld	s1,24(sp)
    8000160c:	6942                	ld	s2,16(sp)
    8000160e:	69a2                	ld	s3,8(sp)
    80001610:	6a02                	ld	s4,0(sp)
    80001612:	6145                	addi	sp,sp,48
    80001614:	8082                	ret

0000000080001616 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001616:	1101                	addi	sp,sp,-32
    80001618:	ec06                	sd	ra,24(sp)
    8000161a:	e822                	sd	s0,16(sp)
    8000161c:	e426                	sd	s1,8(sp)
    8000161e:	1000                	addi	s0,sp,32
    80001620:	84aa                	mv	s1,a0
  if(sz > 0)
    80001622:	e999                	bnez	a1,80001638 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001624:	8526                	mv	a0,s1
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	f86080e7          	jalr	-122(ra) # 800015ac <freewalk>
}
    8000162e:	60e2                	ld	ra,24(sp)
    80001630:	6442                	ld	s0,16(sp)
    80001632:	64a2                	ld	s1,8(sp)
    80001634:	6105                	addi	sp,sp,32
    80001636:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001638:	6611                	lui	a2,0x4
    8000163a:	167d                	addi	a2,a2,-1
    8000163c:	962e                	add	a2,a2,a1
    8000163e:	4685                	li	a3,1
    80001640:	8239                	srli	a2,a2,0xe
    80001642:	4581                	li	a1,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	cfc080e7          	jalr	-772(ra) # 80001340 <uvmunmap>
    8000164c:	bfe1                	j	80001624 <uvmfree+0xe>

000000008000164e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	c679                	beqz	a2,8000171c <uvmcopy+0xce>
{
    80001650:	715d                	addi	sp,sp,-80
    80001652:	e486                	sd	ra,72(sp)
    80001654:	e0a2                	sd	s0,64(sp)
    80001656:	fc26                	sd	s1,56(sp)
    80001658:	f84a                	sd	s2,48(sp)
    8000165a:	f44e                	sd	s3,40(sp)
    8000165c:	f052                	sd	s4,32(sp)
    8000165e:	ec56                	sd	s5,24(sp)
    80001660:	e85a                	sd	s6,16(sp)
    80001662:	e45e                	sd	s7,8(sp)
    80001664:	0880                	addi	s0,sp,80
    80001666:	8b2a                	mv	s6,a0
    80001668:	8aae                	mv	s5,a1
    8000166a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000166c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000166e:	4601                	li	a2,0
    80001670:	85ce                	mv	a1,s3
    80001672:	855a                	mv	a0,s6
    80001674:	00000097          	auipc	ra,0x0
    80001678:	9a4080e7          	jalr	-1628(ra) # 80001018 <walk>
    8000167c:	c531                	beqz	a0,800016c8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000167e:	6118                	ld	a4,0(a0)
    80001680:	00177793          	andi	a5,a4,1
    80001684:	cbb1                	beqz	a5,800016d8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001686:	00a75593          	srli	a1,a4,0xa
    8000168a:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    8000168e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	462080e7          	jalr	1122(ra) # 80000af4 <kalloc>
    8000169a:	892a                	mv	s2,a0
    8000169c:	c939                	beqz	a0,800016f2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000169e:	6611                	lui	a2,0x4
    800016a0:	85de                	mv	a1,s7
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	69e080e7          	jalr	1694(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016aa:	8726                	mv	a4,s1
    800016ac:	86ca                	mv	a3,s2
    800016ae:	6611                	lui	a2,0x4
    800016b0:	85ce                	mv	a1,s3
    800016b2:	8556                	mv	a0,s5
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	a4e080e7          	jalr	-1458(ra) # 80001102 <mappages>
    800016bc:	e515                	bnez	a0,800016e8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016be:	6791                	lui	a5,0x4
    800016c0:	99be                	add	s3,s3,a5
    800016c2:	fb49e6e3          	bltu	s3,s4,8000166e <uvmcopy+0x20>
    800016c6:	a081                	j	80001706 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016c8:	0000b517          	auipc	a0,0xb
    800016cc:	c5050513          	addi	a0,a0,-944 # 8000c318 <digits+0x2d8>
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800016d8:	0000b517          	auipc	a0,0xb
    800016dc:	c6050513          	addi	a0,a0,-928 # 8000c338 <digits+0x2f8>
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	e5e080e7          	jalr	-418(ra) # 8000053e <panic>
      kfree(mem);
    800016e8:	854a                	mv	a0,s2
    800016ea:	fffff097          	auipc	ra,0xfffff
    800016ee:	30e080e7          	jalr	782(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016f2:	4685                	li	a3,1
    800016f4:	00e9d613          	srli	a2,s3,0xe
    800016f8:	4581                	li	a1,0
    800016fa:	8556                	mv	a0,s5
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	c44080e7          	jalr	-956(ra) # 80001340 <uvmunmap>
  return -1;
    80001704:	557d                	li	a0,-1
}
    80001706:	60a6                	ld	ra,72(sp)
    80001708:	6406                	ld	s0,64(sp)
    8000170a:	74e2                	ld	s1,56(sp)
    8000170c:	7942                	ld	s2,48(sp)
    8000170e:	79a2                	ld	s3,40(sp)
    80001710:	7a02                	ld	s4,32(sp)
    80001712:	6ae2                	ld	s5,24(sp)
    80001714:	6b42                	ld	s6,16(sp)
    80001716:	6ba2                	ld	s7,8(sp)
    80001718:	6161                	addi	sp,sp,80
    8000171a:	8082                	ret
  return 0;
    8000171c:	4501                	li	a0,0
}
    8000171e:	8082                	ret

0000000080001720 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001720:	1141                	addi	sp,sp,-16
    80001722:	e406                	sd	ra,8(sp)
    80001724:	e022                	sd	s0,0(sp)
    80001726:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001728:	4601                	li	a2,0
    8000172a:	00000097          	auipc	ra,0x0
    8000172e:	8ee080e7          	jalr	-1810(ra) # 80001018 <walk>
  if(pte == 0)
    80001732:	c901                	beqz	a0,80001742 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001734:	611c                	ld	a5,0(a0)
    80001736:	9bbd                	andi	a5,a5,-17
    80001738:	e11c                	sd	a5,0(a0)
}
    8000173a:	60a2                	ld	ra,8(sp)
    8000173c:	6402                	ld	s0,0(sp)
    8000173e:	0141                	addi	sp,sp,16
    80001740:	8082                	ret
    panic("uvmclear");
    80001742:	0000b517          	auipc	a0,0xb
    80001746:	c1650513          	addi	a0,a0,-1002 # 8000c358 <digits+0x318>
    8000174a:	fffff097          	auipc	ra,0xfffff
    8000174e:	df4080e7          	jalr	-524(ra) # 8000053e <panic>

0000000080001752 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001752:	c6bd                	beqz	a3,800017c0 <copyout+0x6e>
{
    80001754:	715d                	addi	sp,sp,-80
    80001756:	e486                	sd	ra,72(sp)
    80001758:	e0a2                	sd	s0,64(sp)
    8000175a:	fc26                	sd	s1,56(sp)
    8000175c:	f84a                	sd	s2,48(sp)
    8000175e:	f44e                	sd	s3,40(sp)
    80001760:	f052                	sd	s4,32(sp)
    80001762:	ec56                	sd	s5,24(sp)
    80001764:	e85a                	sd	s6,16(sp)
    80001766:	e45e                	sd	s7,8(sp)
    80001768:	e062                	sd	s8,0(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8b2a                	mv	s6,a0
    8000176e:	8c2e                	mv	s8,a1
    80001770:	8a32                	mv	s4,a2
    80001772:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001774:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001776:	6a91                	lui	s5,0x4
    80001778:	a015                	j	8000179c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000177a:	9562                	add	a0,a0,s8
    8000177c:	0004861b          	sext.w	a2,s1
    80001780:	85d2                	mv	a1,s4
    80001782:	41250533          	sub	a0,a0,s2
    80001786:	fffff097          	auipc	ra,0xfffff
    8000178a:	5ba080e7          	jalr	1466(ra) # 80000d40 <memmove>

    len -= n;
    8000178e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001792:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001794:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001798:	02098263          	beqz	s3,800017bc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000179c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a0:	85ca                	mv	a1,s2
    800017a2:	855a                	mv	a0,s6
    800017a4:	00000097          	auipc	ra,0x0
    800017a8:	91c080e7          	jalr	-1764(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    800017ac:	cd01                	beqz	a0,800017c4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017ae:	418904b3          	sub	s1,s2,s8
    800017b2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017b4:	fc99f3e3          	bgeu	s3,s1,8000177a <copyout+0x28>
    800017b8:	84ce                	mv	s1,s3
    800017ba:	b7c1                	j	8000177a <copyout+0x28>
  }
  return 0;
    800017bc:	4501                	li	a0,0
    800017be:	a021                	j	800017c6 <copyout+0x74>
    800017c0:	4501                	li	a0,0
}
    800017c2:	8082                	ret
      return -1;
    800017c4:	557d                	li	a0,-1
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6c02                	ld	s8,0(sp)
    800017da:	6161                	addi	sp,sp,80
    800017dc:	8082                	ret

00000000800017de <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017de:	c6bd                	beqz	a3,8000184c <copyin+0x6e>
{
    800017e0:	715d                	addi	sp,sp,-80
    800017e2:	e486                	sd	ra,72(sp)
    800017e4:	e0a2                	sd	s0,64(sp)
    800017e6:	fc26                	sd	s1,56(sp)
    800017e8:	f84a                	sd	s2,48(sp)
    800017ea:	f44e                	sd	s3,40(sp)
    800017ec:	f052                	sd	s4,32(sp)
    800017ee:	ec56                	sd	s5,24(sp)
    800017f0:	e85a                	sd	s6,16(sp)
    800017f2:	e45e                	sd	s7,8(sp)
    800017f4:	e062                	sd	s8,0(sp)
    800017f6:	0880                	addi	s0,sp,80
    800017f8:	8b2a                	mv	s6,a0
    800017fa:	8a2e                	mv	s4,a1
    800017fc:	8c32                	mv	s8,a2
    800017fe:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001800:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001802:	6a91                	lui	s5,0x4
    80001804:	a015                	j	80001828 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001806:	9562                	add	a0,a0,s8
    80001808:	0004861b          	sext.w	a2,s1
    8000180c:	412505b3          	sub	a1,a0,s2
    80001810:	8552                	mv	a0,s4
    80001812:	fffff097          	auipc	ra,0xfffff
    80001816:	52e080e7          	jalr	1326(ra) # 80000d40 <memmove>

    len -= n;
    8000181a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000181e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001820:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001824:	02098263          	beqz	s3,80001848 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001828:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000182c:	85ca                	mv	a1,s2
    8000182e:	855a                	mv	a0,s6
    80001830:	00000097          	auipc	ra,0x0
    80001834:	890080e7          	jalr	-1904(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    80001838:	cd01                	beqz	a0,80001850 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000183a:	418904b3          	sub	s1,s2,s8
    8000183e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001840:	fc99f3e3          	bgeu	s3,s1,80001806 <copyin+0x28>
    80001844:	84ce                	mv	s1,s3
    80001846:	b7c1                	j	80001806 <copyin+0x28>
  }
  return 0;
    80001848:	4501                	li	a0,0
    8000184a:	a021                	j	80001852 <copyin+0x74>
    8000184c:	4501                	li	a0,0
}
    8000184e:	8082                	ret
      return -1;
    80001850:	557d                	li	a0,-1
}
    80001852:	60a6                	ld	ra,72(sp)
    80001854:	6406                	ld	s0,64(sp)
    80001856:	74e2                	ld	s1,56(sp)
    80001858:	7942                	ld	s2,48(sp)
    8000185a:	79a2                	ld	s3,40(sp)
    8000185c:	7a02                	ld	s4,32(sp)
    8000185e:	6ae2                	ld	s5,24(sp)
    80001860:	6b42                	ld	s6,16(sp)
    80001862:	6ba2                	ld	s7,8(sp)
    80001864:	6c02                	ld	s8,0(sp)
    80001866:	6161                	addi	sp,sp,80
    80001868:	8082                	ret

000000008000186a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000186a:	c6c5                	beqz	a3,80001912 <copyinstr+0xa8>
{
    8000186c:	715d                	addi	sp,sp,-80
    8000186e:	e486                	sd	ra,72(sp)
    80001870:	e0a2                	sd	s0,64(sp)
    80001872:	fc26                	sd	s1,56(sp)
    80001874:	f84a                	sd	s2,48(sp)
    80001876:	f44e                	sd	s3,40(sp)
    80001878:	f052                	sd	s4,32(sp)
    8000187a:	ec56                	sd	s5,24(sp)
    8000187c:	e85a                	sd	s6,16(sp)
    8000187e:	e45e                	sd	s7,8(sp)
    80001880:	0880                	addi	s0,sp,80
    80001882:	8a2a                	mv	s4,a0
    80001884:	8b2e                	mv	s6,a1
    80001886:	8bb2                	mv	s7,a2
    80001888:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000188a:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000188c:	6991                	lui	s3,0x4
    8000188e:	a035                	j	800018ba <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001890:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    80001894:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001896:	0017b793          	seqz	a5,a5
    8000189a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000189e:	60a6                	ld	ra,72(sp)
    800018a0:	6406                	ld	s0,64(sp)
    800018a2:	74e2                	ld	s1,56(sp)
    800018a4:	7942                	ld	s2,48(sp)
    800018a6:	79a2                	ld	s3,40(sp)
    800018a8:	7a02                	ld	s4,32(sp)
    800018aa:	6ae2                	ld	s5,24(sp)
    800018ac:	6b42                	ld	s6,16(sp)
    800018ae:	6ba2                	ld	s7,8(sp)
    800018b0:	6161                	addi	sp,sp,80
    800018b2:	8082                	ret
    srcva = va0 + PGSIZE;
    800018b4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018b8:	c8a9                	beqz	s1,8000190a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018ba:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018be:	85ca                	mv	a1,s2
    800018c0:	8552                	mv	a0,s4
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	7fe080e7          	jalr	2046(ra) # 800010c0 <walkaddr>
    if(pa0 == 0)
    800018ca:	c131                	beqz	a0,8000190e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018cc:	41790833          	sub	a6,s2,s7
    800018d0:	984e                	add	a6,a6,s3
    if(n > max)
    800018d2:	0104f363          	bgeu	s1,a6,800018d8 <copyinstr+0x6e>
    800018d6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018d8:	955e                	add	a0,a0,s7
    800018da:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018de:	fc080be3          	beqz	a6,800018b4 <copyinstr+0x4a>
    800018e2:	985a                	add	a6,a6,s6
    800018e4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018e6:	41650633          	sub	a2,a0,s6
    800018ea:	14fd                	addi	s1,s1,-1
    800018ec:	9b26                	add	s6,s6,s1
    800018ee:	00f60733          	add	a4,a2,a5
    800018f2:	00074703          	lbu	a4,0(a4)
    800018f6:	df49                	beqz	a4,80001890 <copyinstr+0x26>
        *dst = *p;
    800018f8:	00e78023          	sb	a4,0(a5)
      --max;
    800018fc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001900:	0785                	addi	a5,a5,1
    while(n > 0){
    80001902:	ff0796e3          	bne	a5,a6,800018ee <copyinstr+0x84>
      dst++;
    80001906:	8b42                	mv	s6,a6
    80001908:	b775                	j	800018b4 <copyinstr+0x4a>
    8000190a:	4781                	li	a5,0
    8000190c:	b769                	j	80001896 <copyinstr+0x2c>
      return -1;
    8000190e:	557d                	li	a0,-1
    80001910:	b779                	j	8000189e <copyinstr+0x34>
  int got_null = 0;
    80001912:	4781                	li	a5,0
  if(got_null){
    80001914:	0017b793          	seqz	a5,a5
    80001918:	40f00533          	neg	a0,a5
}
    8000191c:	8082                	ret

000000008000191e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000191e:	7139                	addi	sp,sp,-64
    80001920:	fc06                	sd	ra,56(sp)
    80001922:	f822                	sd	s0,48(sp)
    80001924:	f426                	sd	s1,40(sp)
    80001926:	f04a                	sd	s2,32(sp)
    80001928:	ec4e                	sd	s3,24(sp)
    8000192a:	e852                	sd	s4,16(sp)
    8000192c:	e456                	sd	s5,8(sp)
    8000192e:	e05a                	sd	s6,0(sp)
    80001930:	0080                	addi	s0,sp,64
    80001932:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001934:	00017497          	auipc	s1,0x17
    80001938:	d9c48493          	addi	s1,s1,-612 # 800186d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000193c:	8b26                	mv	s6,s1
    8000193e:	0000aa97          	auipc	s5,0xa
    80001942:	6c2a8a93          	addi	s5,s5,1730 # 8000c000 <etext>
    80001946:	00800937          	lui	s2,0x800
    8000194a:	197d                	addi	s2,s2,-1
    8000194c:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	0001ca17          	auipc	s4,0x1c
    80001952:	782a0a13          	addi	s4,s4,1922 # 8001e0d0 <tickslock>
    char *pa = kalloc();
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	19e080e7          	jalr	414(ra) # 80000af4 <kalloc>
    8000195e:	862a                	mv	a2,a0
    if(pa == 0)
    80001960:	c131                	beqz	a0,800019a4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001962:	416485b3          	sub	a1,s1,s6
    80001966:	858d                	srai	a1,a1,0x3
    80001968:	000ab783          	ld	a5,0(s5)
    8000196c:	02f585b3          	mul	a1,a1,a5
    80001970:	2585                	addiw	a1,a1,1
    80001972:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001976:	4719                	li	a4,6
    80001978:	6691                	lui	a3,0x4
    8000197a:	40b905b3          	sub	a1,s2,a1
    8000197e:	854e                	mv	a0,s3
    80001980:	00000097          	auipc	ra,0x0
    80001984:	83e080e7          	jalr	-1986(ra) # 800011be <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	16848493          	addi	s1,s1,360
    8000198c:	fd4495e3          	bne	s1,s4,80001956 <proc_mapstacks+0x38>
  }
}
    80001990:	70e2                	ld	ra,56(sp)
    80001992:	7442                	ld	s0,48(sp)
    80001994:	74a2                	ld	s1,40(sp)
    80001996:	7902                	ld	s2,32(sp)
    80001998:	69e2                	ld	s3,24(sp)
    8000199a:	6a42                	ld	s4,16(sp)
    8000199c:	6aa2                	ld	s5,8(sp)
    8000199e:	6b02                	ld	s6,0(sp)
    800019a0:	6121                	addi	sp,sp,64
    800019a2:	8082                	ret
      panic("kalloc");
    800019a4:	0000b517          	auipc	a0,0xb
    800019a8:	9c450513          	addi	a0,a0,-1596 # 8000c368 <digits+0x328>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>

00000000800019b4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019b4:	7139                	addi	sp,sp,-64
    800019b6:	fc06                	sd	ra,56(sp)
    800019b8:	f822                	sd	s0,48(sp)
    800019ba:	f426                	sd	s1,40(sp)
    800019bc:	f04a                	sd	s2,32(sp)
    800019be:	ec4e                	sd	s3,24(sp)
    800019c0:	e852                	sd	s4,16(sp)
    800019c2:	e456                	sd	s5,8(sp)
    800019c4:	e05a                	sd	s6,0(sp)
    800019c6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019c8:	0000b597          	auipc	a1,0xb
    800019cc:	9a858593          	addi	a1,a1,-1624 # 8000c370 <digits+0x330>
    800019d0:	00017517          	auipc	a0,0x17
    800019d4:	8d050513          	addi	a0,a0,-1840 # 800182a0 <pid_lock>
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	17c080e7          	jalr	380(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019e0:	0000b597          	auipc	a1,0xb
    800019e4:	99858593          	addi	a1,a1,-1640 # 8000c378 <digits+0x338>
    800019e8:	00017517          	auipc	a0,0x17
    800019ec:	8d050513          	addi	a0,a0,-1840 # 800182b8 <wait_lock>
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	164080e7          	jalr	356(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f8:	00017497          	auipc	s1,0x17
    800019fc:	cd848493          	addi	s1,s1,-808 # 800186d0 <proc>
      initlock(&p->lock, "proc");
    80001a00:	0000bb17          	auipc	s6,0xb
    80001a04:	988b0b13          	addi	s6,s6,-1656 # 8000c388 <digits+0x348>
      p->kstack = KSTACK((int) (p - proc));
    80001a08:	8aa6                	mv	s5,s1
    80001a0a:	0000aa17          	auipc	s4,0xa
    80001a0e:	5f6a0a13          	addi	s4,s4,1526 # 8000c000 <etext>
    80001a12:	00800937          	lui	s2,0x800
    80001a16:	197d                	addi	s2,s2,-1
    80001a18:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a1a:	0001c997          	auipc	s3,0x1c
    80001a1e:	6b698993          	addi	s3,s3,1718 # 8001e0d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a22:	85da                	mv	a1,s6
    80001a24:	8526                	mv	a0,s1
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	12e080e7          	jalr	302(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a2e:	415487b3          	sub	a5,s1,s5
    80001a32:	878d                	srai	a5,a5,0x3
    80001a34:	000a3703          	ld	a4,0(s4)
    80001a38:	02e787b3          	mul	a5,a5,a4
    80001a3c:	2785                	addiw	a5,a5,1
    80001a3e:	00f7979b          	slliw	a5,a5,0xf
    80001a42:	40f907b3          	sub	a5,s2,a5
    80001a46:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a48:	16848493          	addi	s1,s1,360
    80001a4c:	fd349be3          	bne	s1,s3,80001a22 <procinit+0x6e>
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

0000000080001a64 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a64:	1141                	addi	sp,sp,-16
    80001a66:	e422                	sd	s0,8(sp)
    80001a68:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a6a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a6c:	2501                	sext.w	a0,a0
    80001a6e:	6422                	ld	s0,8(sp)
    80001a70:	0141                	addi	sp,sp,16
    80001a72:	8082                	ret

0000000080001a74 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a74:	1141                	addi	sp,sp,-16
    80001a76:	e422                	sd	s0,8(sp)
    80001a78:	0800                	addi	s0,sp,16
    80001a7a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a7c:	2781                	sext.w	a5,a5
    80001a7e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a80:	00017517          	auipc	a0,0x17
    80001a84:	85050513          	addi	a0,a0,-1968 # 800182d0 <cpus>
    80001a88:	953e                	add	a0,a0,a5
    80001a8a:	6422                	ld	s0,8(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret

0000000080001a90 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	1000                	addi	s0,sp,32
  push_off();
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	0fe080e7          	jalr	254(ra) # 80000b98 <push_off>
    80001aa2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa4:	2781                	sext.w	a5,a5
    80001aa6:	079e                	slli	a5,a5,0x7
    80001aa8:	00016717          	auipc	a4,0x16
    80001aac:	7f870713          	addi	a4,a4,2040 # 800182a0 <pid_lock>
    80001ab0:	97ba                	add	a5,a5,a4
    80001ab2:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	184080e7          	jalr	388(ra) # 80000c38 <pop_off>
  return p;
}
    80001abc:	8526                	mv	a0,s1
    80001abe:	60e2                	ld	ra,24(sp)
    80001ac0:	6442                	ld	s0,16(sp)
    80001ac2:	64a2                	ld	s1,8(sp)
    80001ac4:	6105                	addi	sp,sp,32
    80001ac6:	8082                	ret

0000000080001ac8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ac8:	1141                	addi	sp,sp,-16
    80001aca:	e406                	sd	ra,8(sp)
    80001acc:	e022                	sd	s0,0(sp)
    80001ace:	0800                	addi	s0,sp,16
  static int first = 1;
  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	fc0080e7          	jalr	-64(ra) # 80001a90 <myproc>
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	1c0080e7          	jalr	448(ra) # 80000c98 <release>

  if (first) {
    80001ae0:	0000b797          	auipc	a5,0xb
    80001ae4:	f407a783          	lw	a5,-192(a5) # 8000ca20 <first.1672>
    80001ae8:	eb89                	bnez	a5,80001afa <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV); //12010320;
  }

  usertrapret();
    80001aea:	00001097          	auipc	ra,0x1
    80001aee:	c5a080e7          	jalr	-934(ra) # 80002744 <usertrapret>
}
    80001af2:	60a2                	ld	ra,8(sp)
    80001af4:	6402                	ld	s0,0(sp)
    80001af6:	0141                	addi	sp,sp,16
    80001af8:	8082                	ret
    first = 0;
    80001afa:	0000b797          	auipc	a5,0xb
    80001afe:	f207a323          	sw	zero,-218(a5) # 8000ca20 <first.1672>
    fsinit(ROOTDEV); //12010320;
    80001b02:	4505                	li	a0,1
    80001b04:	00002097          	auipc	ra,0x2
    80001b08:	982080e7          	jalr	-1662(ra) # 80003486 <fsinit>
    80001b0c:	bff9                	j	80001aea <forkret+0x22>

0000000080001b0e <allocpid>:
allocpid() {
    80001b0e:	1101                	addi	sp,sp,-32
    80001b10:	ec06                	sd	ra,24(sp)
    80001b12:	e822                	sd	s0,16(sp)
    80001b14:	e426                	sd	s1,8(sp)
    80001b16:	e04a                	sd	s2,0(sp)
    80001b18:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1a:	00016917          	auipc	s2,0x16
    80001b1e:	78690913          	addi	s2,s2,1926 # 800182a0 <pid_lock>
    80001b22:	854a                	mv	a0,s2
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	0c0080e7          	jalr	192(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b2c:	0000b797          	auipc	a5,0xb
    80001b30:	ef878793          	addi	a5,a5,-264 # 8000ca24 <nextpid>
    80001b34:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b36:	0014871b          	addiw	a4,s1,1
    80001b3a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3c:	854a                	mv	a0,s2
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	15a080e7          	jalr	346(ra) # 80000c98 <release>
}
    80001b46:	8526                	mv	a0,s1
    80001b48:	60e2                	ld	ra,24(sp)
    80001b4a:	6442                	ld	s0,16(sp)
    80001b4c:	64a2                	ld	s1,8(sp)
    80001b4e:	6902                	ld	s2,0(sp)
    80001b50:	6105                	addi	sp,sp,32
    80001b52:	8082                	ret

0000000080001b54 <proc_pagetable>:
{
    80001b54:	1101                	addi	sp,sp,-32
    80001b56:	ec06                	sd	ra,24(sp)
    80001b58:	e822                	sd	s0,16(sp)
    80001b5a:	e426                	sd	s1,8(sp)
    80001b5c:	e04a                	sd	s2,0(sp)
    80001b5e:	1000                	addi	s0,sp,32
    80001b60:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	8a2080e7          	jalr	-1886(ra) # 80001404 <uvmcreate>
    80001b6a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b6c:	c121                	beqz	a0,80001bac <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b6e:	4729                	li	a4,10
    80001b70:	00006697          	auipc	a3,0x6
    80001b74:	49068693          	addi	a3,a3,1168 # 80008000 <_trampoline>
    80001b78:	6611                	lui	a2,0x4
    80001b7a:	008005b7          	lui	a1,0x800
    80001b7e:	15fd                	addi	a1,a1,-1
    80001b80:	05ba                	slli	a1,a1,0xe
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	580080e7          	jalr	1408(ra) # 80001102 <mappages>
    80001b8a:	02054863          	bltz	a0,80001bba <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b8e:	4719                	li	a4,6
    80001b90:	05893683          	ld	a3,88(s2)
    80001b94:	6611                	lui	a2,0x4
    80001b96:	004005b7          	lui	a1,0x400
    80001b9a:	15fd                	addi	a1,a1,-1
    80001b9c:	05be                	slli	a1,a1,0xf
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	562080e7          	jalr	1378(ra) # 80001102 <mappages>
    80001ba8:	02054163          	bltz	a0,80001bca <proc_pagetable+0x76>
}
    80001bac:	8526                	mv	a0,s1
    80001bae:	60e2                	ld	ra,24(sp)
    80001bb0:	6442                	ld	s0,16(sp)
    80001bb2:	64a2                	ld	s1,8(sp)
    80001bb4:	6902                	ld	s2,0(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret
    uvmfree(pagetable, 0);
    80001bba:	4581                	li	a1,0
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	00000097          	auipc	ra,0x0
    80001bc2:	a58080e7          	jalr	-1448(ra) # 80001616 <uvmfree>
    return 0;
    80001bc6:	4481                	li	s1,0
    80001bc8:	b7d5                	j	80001bac <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bca:	4681                	li	a3,0
    80001bcc:	4605                	li	a2,1
    80001bce:	008005b7          	lui	a1,0x800
    80001bd2:	15fd                	addi	a1,a1,-1
    80001bd4:	05ba                	slli	a1,a1,0xe
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	768080e7          	jalr	1896(ra) # 80001340 <uvmunmap>
    uvmfree(pagetable, 0);
    80001be0:	4581                	li	a1,0
    80001be2:	8526                	mv	a0,s1
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	a32080e7          	jalr	-1486(ra) # 80001616 <uvmfree>
    return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	bf7d                	j	80001bac <proc_pagetable+0x58>

0000000080001bf0 <proc_freepagetable>:
{
    80001bf0:	1101                	addi	sp,sp,-32
    80001bf2:	ec06                	sd	ra,24(sp)
    80001bf4:	e822                	sd	s0,16(sp)
    80001bf6:	e426                	sd	s1,8(sp)
    80001bf8:	e04a                	sd	s2,0(sp)
    80001bfa:	1000                	addi	s0,sp,32
    80001bfc:	84aa                	mv	s1,a0
    80001bfe:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c00:	4681                	li	a3,0
    80001c02:	4605                	li	a2,1
    80001c04:	008005b7          	lui	a1,0x800
    80001c08:	15fd                	addi	a1,a1,-1
    80001c0a:	05ba                	slli	a1,a1,0xe
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	734080e7          	jalr	1844(ra) # 80001340 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c14:	4681                	li	a3,0
    80001c16:	4605                	li	a2,1
    80001c18:	004005b7          	lui	a1,0x400
    80001c1c:	15fd                	addi	a1,a1,-1
    80001c1e:	05be                	slli	a1,a1,0xf
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	71e080e7          	jalr	1822(ra) # 80001340 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c2a:	85ca                	mv	a1,s2
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	9e8080e7          	jalr	-1560(ra) # 80001616 <uvmfree>
}
    80001c36:	60e2                	ld	ra,24(sp)
    80001c38:	6442                	ld	s0,16(sp)
    80001c3a:	64a2                	ld	s1,8(sp)
    80001c3c:	6902                	ld	s2,0(sp)
    80001c3e:	6105                	addi	sp,sp,32
    80001c40:	8082                	ret

0000000080001c42 <freeproc>:
{
    80001c42:	1101                	addi	sp,sp,-32
    80001c44:	ec06                	sd	ra,24(sp)
    80001c46:	e822                	sd	s0,16(sp)
    80001c48:	e426                	sd	s1,8(sp)
    80001c4a:	1000                	addi	s0,sp,32
    80001c4c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c4e:	6d28                	ld	a0,88(a0)
    80001c50:	c509                	beqz	a0,80001c5a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	da6080e7          	jalr	-602(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c5a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c5e:	68a8                	ld	a0,80(s1)
    80001c60:	c511                	beqz	a0,80001c6c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c62:	64ac                	ld	a1,72(s1)
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	f8c080e7          	jalr	-116(ra) # 80001bf0 <proc_freepagetable>
  p->pagetable = 0;
    80001c6c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c70:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c74:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c78:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c7c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c80:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c84:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c88:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c8c:	0004ac23          	sw	zero,24(s1)
}
    80001c90:	60e2                	ld	ra,24(sp)
    80001c92:	6442                	ld	s0,16(sp)
    80001c94:	64a2                	ld	s1,8(sp)
    80001c96:	6105                	addi	sp,sp,32
    80001c98:	8082                	ret

0000000080001c9a <allocproc>:
{
    80001c9a:	1101                	addi	sp,sp,-32
    80001c9c:	ec06                	sd	ra,24(sp)
    80001c9e:	e822                	sd	s0,16(sp)
    80001ca0:	e426                	sd	s1,8(sp)
    80001ca2:	e04a                	sd	s2,0(sp)
    80001ca4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca6:	00017497          	auipc	s1,0x17
    80001caa:	a2a48493          	addi	s1,s1,-1494 # 800186d0 <proc>
    80001cae:	0001c917          	auipc	s2,0x1c
    80001cb2:	42290913          	addi	s2,s2,1058 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	f2c080e7          	jalr	-212(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001cc0:	4c9c                	lw	a5,24(s1)
    80001cc2:	cf81                	beqz	a5,80001cda <allocproc+0x40>
      release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fd2080e7          	jalr	-46(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cce:	16848493          	addi	s1,s1,360
    80001cd2:	ff2492e3          	bne	s1,s2,80001cb6 <allocproc+0x1c>
  return 0;
    80001cd6:	4481                	li	s1,0
    80001cd8:	a889                	j	80001d2a <allocproc+0x90>
  p->pid = allocpid();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	e34080e7          	jalr	-460(ra) # 80001b0e <allocpid>
    80001ce2:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ce4:	4785                	li	a5,1
    80001ce6:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	e0c080e7          	jalr	-500(ra) # 80000af4 <kalloc>
    80001cf0:	892a                	mv	s2,a0
    80001cf2:	eca8                	sd	a0,88(s1)
    80001cf4:	c131                	beqz	a0,80001d38 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	e5c080e7          	jalr	-420(ra) # 80001b54 <proc_pagetable>
    80001d00:	892a                	mv	s2,a0
    80001d02:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d04:	c531                	beqz	a0,80001d50 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d06:	07000613          	li	a2,112
    80001d0a:	4581                	li	a1,0
    80001d0c:	06048513          	addi	a0,s1,96
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	fd0080e7          	jalr	-48(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d18:	00000797          	auipc	a5,0x0
    80001d1c:	db078793          	addi	a5,a5,-592 # 80001ac8 <forkret>
    80001d20:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d22:	60bc                	ld	a5,64(s1)
    80001d24:	6711                	lui	a4,0x4
    80001d26:	97ba                	add	a5,a5,a4
    80001d28:	f4bc                	sd	a5,104(s1)
}
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    freeproc(p);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	f08080e7          	jalr	-248(ra) # 80001c42 <freeproc>
    release(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	f54080e7          	jalr	-172(ra) # 80000c98 <release>
    return 0;
    80001d4c:	84ca                	mv	s1,s2
    80001d4e:	bff1                	j	80001d2a <allocproc+0x90>
    freeproc(p);
    80001d50:	8526                	mv	a0,s1
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	ef0080e7          	jalr	-272(ra) # 80001c42 <freeproc>
    release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f3c080e7          	jalr	-196(ra) # 80000c98 <release>
    return 0;
    80001d64:	84ca                	mv	s1,s2
    80001d66:	b7d1                	j	80001d2a <allocproc+0x90>

0000000080001d68 <userinit>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	f28080e7          	jalr	-216(ra) # 80001c9a <allocproc>
    80001d7a:	84aa                	mv	s1,a0
  initproc = p;
    80001d7c:	0000e797          	auipc	a5,0xe
    80001d80:	2aa7b623          	sd	a0,684(a5) # 80010028 <initproc>
  printf("user proc with id %d create.\n",p->pid);
    80001d84:	590c                	lw	a1,48(a0)
    80001d86:	0000a517          	auipc	a0,0xa
    80001d8a:	60a50513          	addi	a0,a0,1546 # 8000c390 <digits+0x350>
    80001d8e:	ffffe097          	auipc	ra,0xffffe
    80001d92:	7fa080e7          	jalr	2042(ra) # 80000588 <printf>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d96:	03400613          	li	a2,52
    80001d9a:	0000b597          	auipc	a1,0xb
    80001d9e:	c9658593          	addi	a1,a1,-874 # 8000ca30 <initcode>
    80001da2:	68a8                	ld	a0,80(s1)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	68e080e7          	jalr	1678(ra) # 80001432 <uvminit>
  p->sz = PGSIZE;
    80001dac:	6791                	lui	a5,0x4
    80001dae:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001db0:	6cb8                	ld	a4,88(s1)
    80001db2:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001db6:	6cb8                	ld	a4,88(s1)
    80001db8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dba:	4641                	li	a2,16
    80001dbc:	0000a597          	auipc	a1,0xa
    80001dc0:	5f458593          	addi	a1,a1,1524 # 8000c3b0 <digits+0x370>
    80001dc4:	15848513          	addi	a0,s1,344
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	06a080e7          	jalr	106(ra) # 80000e32 <safestrcpy>
  printf("path: %s\n",namei("/"));
    80001dd0:	0000a517          	auipc	a0,0xa
    80001dd4:	5f050513          	addi	a0,a0,1520 # 8000c3c0 <digits+0x380>
    80001dd8:	00002097          	auipc	ra,0x2
    80001ddc:	0ee080e7          	jalr	238(ra) # 80003ec6 <namei>
    80001de0:	85aa                	mv	a1,a0
    80001de2:	0000a517          	auipc	a0,0xa
    80001de6:	5e650513          	addi	a0,a0,1510 # 8000c3c8 <digits+0x388>
    80001dea:	ffffe097          	auipc	ra,0xffffe
    80001dee:	79e080e7          	jalr	1950(ra) # 80000588 <printf>
  p->cwd = namei("/");
    80001df2:	0000a517          	auipc	a0,0xa
    80001df6:	5ce50513          	addi	a0,a0,1486 # 8000c3c0 <digits+0x380>
    80001dfa:	00002097          	auipc	ra,0x2
    80001dfe:	0cc080e7          	jalr	204(ra) # 80003ec6 <namei>
    80001e02:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e06:	478d                	li	a5,3
    80001e08:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	e8c080e7          	jalr	-372(ra) # 80000c98 <release>
}
    80001e14:	60e2                	ld	ra,24(sp)
    80001e16:	6442                	ld	s0,16(sp)
    80001e18:	64a2                	ld	s1,8(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret

0000000080001e1e <growproc>:
{
    80001e1e:	1101                	addi	sp,sp,-32
    80001e20:	ec06                	sd	ra,24(sp)
    80001e22:	e822                	sd	s0,16(sp)
    80001e24:	e426                	sd	s1,8(sp)
    80001e26:	e04a                	sd	s2,0(sp)
    80001e28:	1000                	addi	s0,sp,32
    80001e2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	c64080e7          	jalr	-924(ra) # 80001a90 <myproc>
    80001e34:	892a                	mv	s2,a0
  sz = p->sz;
    80001e36:	652c                	ld	a1,72(a0)
    80001e38:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e3c:	00904f63          	bgtz	s1,80001e5a <growproc+0x3c>
  } else if(n < 0){
    80001e40:	0204cc63          	bltz	s1,80001e78 <growproc+0x5a>
  p->sz = sz;
    80001e44:	1602                	slli	a2,a2,0x20
    80001e46:	9201                	srli	a2,a2,0x20
    80001e48:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e4c:	4501                	li	a0,0
}
    80001e4e:	60e2                	ld	ra,24(sp)
    80001e50:	6442                	ld	s0,16(sp)
    80001e52:	64a2                	ld	s1,8(sp)
    80001e54:	6902                	ld	s2,0(sp)
    80001e56:	6105                	addi	sp,sp,32
    80001e58:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e5a:	9e25                	addw	a2,a2,s1
    80001e5c:	1602                	slli	a2,a2,0x20
    80001e5e:	9201                	srli	a2,a2,0x20
    80001e60:	1582                	slli	a1,a1,0x20
    80001e62:	9181                	srli	a1,a1,0x20
    80001e64:	6928                	ld	a0,80(a0)
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	69c080e7          	jalr	1692(ra) # 80001502 <uvmalloc>
    80001e6e:	0005061b          	sext.w	a2,a0
    80001e72:	fa69                	bnez	a2,80001e44 <growproc+0x26>
      return -1;
    80001e74:	557d                	li	a0,-1
    80001e76:	bfe1                	j	80001e4e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e78:	9e25                	addw	a2,a2,s1
    80001e7a:	1602                	slli	a2,a2,0x20
    80001e7c:	9201                	srli	a2,a2,0x20
    80001e7e:	1582                	slli	a1,a1,0x20
    80001e80:	9181                	srli	a1,a1,0x20
    80001e82:	6928                	ld	a0,80(a0)
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	636080e7          	jalr	1590(ra) # 800014ba <uvmdealloc>
    80001e8c:	0005061b          	sext.w	a2,a0
    80001e90:	bf55                	j	80001e44 <growproc+0x26>

0000000080001e92 <fork>:
{
    80001e92:	7179                	addi	sp,sp,-48
    80001e94:	f406                	sd	ra,40(sp)
    80001e96:	f022                	sd	s0,32(sp)
    80001e98:	ec26                	sd	s1,24(sp)
    80001e9a:	e84a                	sd	s2,16(sp)
    80001e9c:	e44e                	sd	s3,8(sp)
    80001e9e:	e052                	sd	s4,0(sp)
    80001ea0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	bee080e7          	jalr	-1042(ra) # 80001a90 <myproc>
    80001eaa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	dee080e7          	jalr	-530(ra) # 80001c9a <allocproc>
    80001eb4:	10050b63          	beqz	a0,80001fca <fork+0x138>
    80001eb8:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eba:	04893603          	ld	a2,72(s2)
    80001ebe:	692c                	ld	a1,80(a0)
    80001ec0:	05093503          	ld	a0,80(s2)
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	78a080e7          	jalr	1930(ra) # 8000164e <uvmcopy>
    80001ecc:	04054663          	bltz	a0,80001f18 <fork+0x86>
  np->sz = p->sz;
    80001ed0:	04893783          	ld	a5,72(s2)
    80001ed4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ed8:	05893683          	ld	a3,88(s2)
    80001edc:	87b6                	mv	a5,a3
    80001ede:	0589b703          	ld	a4,88(s3)
    80001ee2:	12068693          	addi	a3,a3,288
    80001ee6:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001eea:	6788                	ld	a0,8(a5)
    80001eec:	6b8c                	ld	a1,16(a5)
    80001eee:	6f90                	ld	a2,24(a5)
    80001ef0:	01073023          	sd	a6,0(a4)
    80001ef4:	e708                	sd	a0,8(a4)
    80001ef6:	eb0c                	sd	a1,16(a4)
    80001ef8:	ef10                	sd	a2,24(a4)
    80001efa:	02078793          	addi	a5,a5,32
    80001efe:	02070713          	addi	a4,a4,32
    80001f02:	fed792e3          	bne	a5,a3,80001ee6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f06:	0589b783          	ld	a5,88(s3)
    80001f0a:	0607b823          	sd	zero,112(a5)
    80001f0e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f12:	15000a13          	li	s4,336
    80001f16:	a03d                	j	80001f44 <fork+0xb2>
    freeproc(np);
    80001f18:	854e                	mv	a0,s3
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	d28080e7          	jalr	-728(ra) # 80001c42 <freeproc>
    release(&np->lock);
    80001f22:	854e                	mv	a0,s3
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d74080e7          	jalr	-652(ra) # 80000c98 <release>
    return -1;
    80001f2c:	5a7d                	li	s4,-1
    80001f2e:	a069                	j	80001fb8 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f30:	00002097          	auipc	ra,0x2
    80001f34:	62c080e7          	jalr	1580(ra) # 8000455c <filedup>
    80001f38:	009987b3          	add	a5,s3,s1
    80001f3c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f3e:	04a1                	addi	s1,s1,8
    80001f40:	01448763          	beq	s1,s4,80001f4e <fork+0xbc>
    if(p->ofile[i])
    80001f44:	009907b3          	add	a5,s2,s1
    80001f48:	6388                	ld	a0,0(a5)
    80001f4a:	f17d                	bnez	a0,80001f30 <fork+0x9e>
    80001f4c:	bfcd                	j	80001f3e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f4e:	15093503          	ld	a0,336(s2)
    80001f52:	00001097          	auipc	ra,0x1
    80001f56:	780080e7          	jalr	1920(ra) # 800036d2 <idup>
    80001f5a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f5e:	4641                	li	a2,16
    80001f60:	15890593          	addi	a1,s2,344
    80001f64:	15898513          	addi	a0,s3,344
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	eca080e7          	jalr	-310(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f70:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f74:	854e                	mv	a0,s3
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f7e:	00016497          	auipc	s1,0x16
    80001f82:	33a48493          	addi	s1,s1,826 # 800182b8 <wait_lock>
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	c5c080e7          	jalr	-932(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f90:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	d02080e7          	jalr	-766(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f9e:	854e                	mv	a0,s3
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	c44080e7          	jalr	-956(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fa8:	478d                	li	a5,3
    80001faa:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fae:	854e                	mv	a0,s3
    80001fb0:	fffff097          	auipc	ra,0xfffff
    80001fb4:	ce8080e7          	jalr	-792(ra) # 80000c98 <release>
}
    80001fb8:	8552                	mv	a0,s4
    80001fba:	70a2                	ld	ra,40(sp)
    80001fbc:	7402                	ld	s0,32(sp)
    80001fbe:	64e2                	ld	s1,24(sp)
    80001fc0:	6942                	ld	s2,16(sp)
    80001fc2:	69a2                	ld	s3,8(sp)
    80001fc4:	6a02                	ld	s4,0(sp)
    80001fc6:	6145                	addi	sp,sp,48
    80001fc8:	8082                	ret
    return -1;
    80001fca:	5a7d                	li	s4,-1
    80001fcc:	b7f5                	j	80001fb8 <fork+0x126>

0000000080001fce <scheduler>:
{
    80001fce:	7139                	addi	sp,sp,-64
    80001fd0:	fc06                	sd	ra,56(sp)
    80001fd2:	f822                	sd	s0,48(sp)
    80001fd4:	f426                	sd	s1,40(sp)
    80001fd6:	f04a                	sd	s2,32(sp)
    80001fd8:	ec4e                	sd	s3,24(sp)
    80001fda:	e852                	sd	s4,16(sp)
    80001fdc:	e456                	sd	s5,8(sp)
    80001fde:	e05a                	sd	s6,0(sp)
    80001fe0:	0080                	addi	s0,sp,64
    80001fe2:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe6:	00779a93          	slli	s5,a5,0x7
    80001fea:	00016717          	auipc	a4,0x16
    80001fee:	2b670713          	addi	a4,a4,694 # 800182a0 <pid_lock>
    80001ff2:	9756                	add	a4,a4,s5
    80001ff4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ff8:	00016717          	auipc	a4,0x16
    80001ffc:	2e070713          	addi	a4,a4,736 # 800182d8 <cpus+0x8>
    80002000:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002002:	498d                	li	s3,3
        p->state = RUNNING;
    80002004:	4b11                	li	s6,4
        c->proc = p;
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	00016a17          	auipc	s4,0x16
    8000200c:	298a0a13          	addi	s4,s4,664 # 800182a0 <pid_lock>
    80002010:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002012:	0001c917          	auipc	s2,0x1c
    80002016:	0be90913          	addi	s2,s2,190 # 8001e0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002022:	10079073          	csrw	sstatus,a5
    80002026:	00016497          	auipc	s1,0x16
    8000202a:	6aa48493          	addi	s1,s1,1706 # 800186d0 <proc>
    8000202e:	a03d                	j	8000205c <scheduler+0x8e>
        p->state = RUNNING;
    80002030:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002034:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002038:	06048593          	addi	a1,s1,96
    8000203c:	8556                	mv	a0,s5
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	640080e7          	jalr	1600(ra) # 8000267e <swtch>
	c->proc = 0;
    80002046:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000204a:	8526                	mv	a0,s1
    8000204c:	fffff097          	auipc	ra,0xfffff
    80002050:	c4c080e7          	jalr	-948(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002054:	16848493          	addi	s1,s1,360
    80002058:	fd2481e3          	beq	s1,s2,8000201a <scheduler+0x4c>
      acquire(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	b86080e7          	jalr	-1146(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002066:	4c9c                	lw	a5,24(s1)
    80002068:	ff3791e3          	bne	a5,s3,8000204a <scheduler+0x7c>
    8000206c:	b7d1                	j	80002030 <scheduler+0x62>

000000008000206e <sched>:
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	a14080e7          	jalr	-1516(ra) # 80001a90 <myproc>
    80002084:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	ae4080e7          	jalr	-1308(ra) # 80000b6a <holding>
    8000208e:	c93d                	beqz	a0,80002104 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	00016717          	auipc	a4,0x16
    8000209a:	20a70713          	addi	a4,a4,522 # 800182a0 <pid_lock>
    8000209e:	97ba                	add	a5,a5,a4
    800020a0:	0a87a703          	lw	a4,168(a5)
    800020a4:	4785                	li	a5,1
    800020a6:	06f71763          	bne	a4,a5,80002114 <sched+0xa6>
  if(p->state == RUNNING)
    800020aa:	4c98                	lw	a4,24(s1)
    800020ac:	4791                	li	a5,4
    800020ae:	06f70b63          	beq	a4,a5,80002124 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b8:	efb5                	bnez	a5,80002134 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020bc:	00016917          	auipc	s2,0x16
    800020c0:	1e490913          	addi	s2,s2,484 # 800182a0 <pid_lock>
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0ac7a983          	lw	s3,172(a5)
    800020ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	00016597          	auipc	a1,0x16
    800020d8:	20458593          	addi	a1,a1,516 # 800182d8 <cpus+0x8>
    800020dc:	95be                	add	a1,a1,a5
    800020de:	06048513          	addi	a0,s1,96
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	59c080e7          	jalr	1436(ra) # 8000267e <swtch>
    800020ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	97ca                	add	a5,a5,s2
    800020f2:	0b37a623          	sw	s3,172(a5)
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret
    panic("sched p->lock");
    80002104:	0000a517          	auipc	a0,0xa
    80002108:	2d450513          	addi	a0,a0,724 # 8000c3d8 <digits+0x398>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	432080e7          	jalr	1074(ra) # 8000053e <panic>
    panic("sched locks");
    80002114:	0000a517          	auipc	a0,0xa
    80002118:	2d450513          	addi	a0,a0,724 # 8000c3e8 <digits+0x3a8>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	422080e7          	jalr	1058(ra) # 8000053e <panic>
    panic("sched running");
    80002124:	0000a517          	auipc	a0,0xa
    80002128:	2d450513          	addi	a0,a0,724 # 8000c3f8 <digits+0x3b8>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	412080e7          	jalr	1042(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002134:	0000a517          	auipc	a0,0xa
    80002138:	2d450513          	addi	a0,a0,724 # 8000c408 <digits+0x3c8>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	402080e7          	jalr	1026(ra) # 8000053e <panic>

0000000080002144 <yield>:
{
    80002144:	1101                	addi	sp,sp,-32
    80002146:	ec06                	sd	ra,24(sp)
    80002148:	e822                	sd	s0,16(sp)
    8000214a:	e426                	sd	s1,8(sp)
    8000214c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	942080e7          	jalr	-1726(ra) # 80001a90 <myproc>
    80002156:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a8c080e7          	jalr	-1396(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002160:	478d                	li	a5,3
    80002162:	cc9c                	sw	a5,24(s1)
  sched();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	f0a080e7          	jalr	-246(ra) # 8000206e <sched>
  release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b2a080e7          	jalr	-1238(ra) # 80000c98 <release>
}
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6105                	addi	sp,sp,32
    8000217e:	8082                	ret

0000000080002180 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	89aa                	mv	s3,a0
    80002190:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	8fe080e7          	jalr	-1794(ra) # 80001a90 <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
  release(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	af2080e7          	jalr	-1294(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b2:	4789                	li	a5,2
    800021b4:	cc9c                	sw	a5,24(s1)

  sched();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	eb8080e7          	jalr	-328(ra) # 8000206e <sched>

  // Tidy up.
  p->chan = 0;
    800021be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ad4080e7          	jalr	-1324(ra) # 80000c98 <release>
  acquire(lk);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a16080e7          	jalr	-1514(ra) # 80000be4 <acquire>
}
    800021d6:	70a2                	ld	ra,40(sp)
    800021d8:	7402                	ld	s0,32(sp)
    800021da:	64e2                	ld	s1,24(sp)
    800021dc:	6942                	ld	s2,16(sp)
    800021de:	69a2                	ld	s3,8(sp)
    800021e0:	6145                	addi	sp,sp,48
    800021e2:	8082                	ret

00000000800021e4 <wait>:
{
    800021e4:	715d                	addi	sp,sp,-80
    800021e6:	e486                	sd	ra,72(sp)
    800021e8:	e0a2                	sd	s0,64(sp)
    800021ea:	fc26                	sd	s1,56(sp)
    800021ec:	f84a                	sd	s2,48(sp)
    800021ee:	f44e                	sd	s3,40(sp)
    800021f0:	f052                	sd	s4,32(sp)
    800021f2:	ec56                	sd	s5,24(sp)
    800021f4:	e85a                	sd	s6,16(sp)
    800021f6:	e45e                	sd	s7,8(sp)
    800021f8:	e062                	sd	s8,0(sp)
    800021fa:	0880                	addi	s0,sp,80
    800021fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	892080e7          	jalr	-1902(ra) # 80001a90 <myproc>
    80002206:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002208:	00016517          	auipc	a0,0x16
    8000220c:	0b050513          	addi	a0,a0,176 # 800182b8 <wait_lock>
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	9d4080e7          	jalr	-1580(ra) # 80000be4 <acquire>
    havekids = 0;
    80002218:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000221a:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000221c:	0001c997          	auipc	s3,0x1c
    80002220:	eb498993          	addi	s3,s3,-332 # 8001e0d0 <tickslock>
        havekids = 1;
    80002224:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002226:	00016c17          	auipc	s8,0x16
    8000222a:	092c0c13          	addi	s8,s8,146 # 800182b8 <wait_lock>
    havekids = 0;
    8000222e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002230:	00016497          	auipc	s1,0x16
    80002234:	4a048493          	addi	s1,s1,1184 # 800186d0 <proc>
    80002238:	a0bd                	j	800022a6 <wait+0xc2>
          pid = np->pid;
    8000223a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000223e:	000b0e63          	beqz	s6,8000225a <wait+0x76>
    80002242:	4691                	li	a3,4
    80002244:	02c48613          	addi	a2,s1,44
    80002248:	85da                	mv	a1,s6
    8000224a:	05093503          	ld	a0,80(s2)
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	504080e7          	jalr	1284(ra) # 80001752 <copyout>
    80002256:	02054563          	bltz	a0,80002280 <wait+0x9c>
          freeproc(np);
    8000225a:	8526                	mv	a0,s1
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	9e6080e7          	jalr	-1562(ra) # 80001c42 <freeproc>
          release(&np->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a32080e7          	jalr	-1486(ra) # 80000c98 <release>
          release(&wait_lock);
    8000226e:	00016517          	auipc	a0,0x16
    80002272:	04a50513          	addi	a0,a0,74 # 800182b8 <wait_lock>
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
          return pid;
    8000227e:	a09d                	j	800022e4 <wait+0x100>
            release(&np->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	a16080e7          	jalr	-1514(ra) # 80000c98 <release>
            release(&wait_lock);
    8000228a:	00016517          	auipc	a0,0x16
    8000228e:	02e50513          	addi	a0,a0,46 # 800182b8 <wait_lock>
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	a06080e7          	jalr	-1530(ra) # 80000c98 <release>
            return -1;
    8000229a:	59fd                	li	s3,-1
    8000229c:	a0a1                	j	800022e4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000229e:	16848493          	addi	s1,s1,360
    800022a2:	03348463          	beq	s1,s3,800022ca <wait+0xe6>
      if(np->parent == p){
    800022a6:	7c9c                	ld	a5,56(s1)
    800022a8:	ff279be3          	bne	a5,s2,8000229e <wait+0xba>
        acquire(&np->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022b6:	4c9c                	lw	a5,24(s1)
    800022b8:	f94781e3          	beq	a5,s4,8000223a <wait+0x56>
        release(&np->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9da080e7          	jalr	-1574(ra) # 80000c98 <release>
        havekids = 1;
    800022c6:	8756                	mv	a4,s5
    800022c8:	bfd9                	j	8000229e <wait+0xba>
    if(!havekids || p->killed){
    800022ca:	c701                	beqz	a4,800022d2 <wait+0xee>
    800022cc:	02892783          	lw	a5,40(s2)
    800022d0:	c79d                	beqz	a5,800022fe <wait+0x11a>
      release(&wait_lock);
    800022d2:	00016517          	auipc	a0,0x16
    800022d6:	fe650513          	addi	a0,a0,-26 # 800182b8 <wait_lock>
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9be080e7          	jalr	-1602(ra) # 80000c98 <release>
      return -1;
    800022e2:	59fd                	li	s3,-1
}
    800022e4:	854e                	mv	a0,s3
    800022e6:	60a6                	ld	ra,72(sp)
    800022e8:	6406                	ld	s0,64(sp)
    800022ea:	74e2                	ld	s1,56(sp)
    800022ec:	7942                	ld	s2,48(sp)
    800022ee:	79a2                	ld	s3,40(sp)
    800022f0:	7a02                	ld	s4,32(sp)
    800022f2:	6ae2                	ld	s5,24(sp)
    800022f4:	6b42                	ld	s6,16(sp)
    800022f6:	6ba2                	ld	s7,8(sp)
    800022f8:	6c02                	ld	s8,0(sp)
    800022fa:	6161                	addi	sp,sp,80
    800022fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022fe:	85e2                	mv	a1,s8
    80002300:	854a                	mv	a0,s2
    80002302:	00000097          	auipc	ra,0x0
    80002306:	e7e080e7          	jalr	-386(ra) # 80002180 <sleep>
    havekids = 0;
    8000230a:	b715                	j	8000222e <wait+0x4a>

000000008000230c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000230c:	7139                	addi	sp,sp,-64
    8000230e:	fc06                	sd	ra,56(sp)
    80002310:	f822                	sd	s0,48(sp)
    80002312:	f426                	sd	s1,40(sp)
    80002314:	f04a                	sd	s2,32(sp)
    80002316:	ec4e                	sd	s3,24(sp)
    80002318:	e852                	sd	s4,16(sp)
    8000231a:	e456                	sd	s5,8(sp)
    8000231c:	0080                	addi	s0,sp,64
    8000231e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002320:	00016497          	auipc	s1,0x16
    80002324:	3b048493          	addi	s1,s1,944 # 800186d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002328:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000232a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000232c:	0001c917          	auipc	s2,0x1c
    80002330:	da490913          	addi	s2,s2,-604 # 8001e0d0 <tickslock>
    80002334:	a821                	j	8000234c <wakeup+0x40>
        p->state = RUNNABLE;
    80002336:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	95c080e7          	jalr	-1700(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002344:	16848493          	addi	s1,s1,360
    80002348:	03248463          	beq	s1,s2,80002370 <wakeup+0x64>
    if(p != myproc()){
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	744080e7          	jalr	1860(ra) # 80001a90 <myproc>
    80002354:	fea488e3          	beq	s1,a0,80002344 <wakeup+0x38>
      acquire(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	88a080e7          	jalr	-1910(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002362:	4c9c                	lw	a5,24(s1)
    80002364:	fd379be3          	bne	a5,s3,8000233a <wakeup+0x2e>
    80002368:	709c                	ld	a5,32(s1)
    8000236a:	fd4798e3          	bne	a5,s4,8000233a <wakeup+0x2e>
    8000236e:	b7e1                	j	80002336 <wakeup+0x2a>
    }
  }
}
    80002370:	70e2                	ld	ra,56(sp)
    80002372:	7442                	ld	s0,48(sp)
    80002374:	74a2                	ld	s1,40(sp)
    80002376:	7902                	ld	s2,32(sp)
    80002378:	69e2                	ld	s3,24(sp)
    8000237a:	6a42                	ld	s4,16(sp)
    8000237c:	6aa2                	ld	s5,8(sp)
    8000237e:	6121                	addi	sp,sp,64
    80002380:	8082                	ret

0000000080002382 <reparent>:
{
    80002382:	7179                	addi	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	e052                	sd	s4,0(sp)
    80002390:	1800                	addi	s0,sp,48
    80002392:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002394:	00016497          	auipc	s1,0x16
    80002398:	33c48493          	addi	s1,s1,828 # 800186d0 <proc>
      pp->parent = initproc;
    8000239c:	0000ea17          	auipc	s4,0xe
    800023a0:	c8ca0a13          	addi	s4,s4,-884 # 80010028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a4:	0001c997          	auipc	s3,0x1c
    800023a8:	d2c98993          	addi	s3,s3,-724 # 8001e0d0 <tickslock>
    800023ac:	a029                	j	800023b6 <reparent+0x34>
    800023ae:	16848493          	addi	s1,s1,360
    800023b2:	01348d63          	beq	s1,s3,800023cc <reparent+0x4a>
    if(pp->parent == p){
    800023b6:	7c9c                	ld	a5,56(s1)
    800023b8:	ff279be3          	bne	a5,s2,800023ae <reparent+0x2c>
      pp->parent = initproc;
    800023bc:	000a3503          	ld	a0,0(s4)
    800023c0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	f4a080e7          	jalr	-182(ra) # 8000230c <wakeup>
    800023ca:	b7d5                	j	800023ae <reparent+0x2c>
}
    800023cc:	70a2                	ld	ra,40(sp)
    800023ce:	7402                	ld	s0,32(sp)
    800023d0:	64e2                	ld	s1,24(sp)
    800023d2:	6942                	ld	s2,16(sp)
    800023d4:	69a2                	ld	s3,8(sp)
    800023d6:	6a02                	ld	s4,0(sp)
    800023d8:	6145                	addi	sp,sp,48
    800023da:	8082                	ret

00000000800023dc <exit>:
{
    800023dc:	7179                	addi	sp,sp,-48
    800023de:	f406                	sd	ra,40(sp)
    800023e0:	f022                	sd	s0,32(sp)
    800023e2:	ec26                	sd	s1,24(sp)
    800023e4:	e84a                	sd	s2,16(sp)
    800023e6:	e44e                	sd	s3,8(sp)
    800023e8:	e052                	sd	s4,0(sp)
    800023ea:	1800                	addi	s0,sp,48
    800023ec:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	6a2080e7          	jalr	1698(ra) # 80001a90 <myproc>
    800023f6:	89aa                	mv	s3,a0
  if(p == initproc)
    800023f8:	0000e797          	auipc	a5,0xe
    800023fc:	c307b783          	ld	a5,-976(a5) # 80010028 <initproc>
    80002400:	0d050493          	addi	s1,a0,208
    80002404:	15050913          	addi	s2,a0,336
    80002408:	02a79363          	bne	a5,a0,8000242e <exit+0x52>
    panic("init exiting");
    8000240c:	0000a517          	auipc	a0,0xa
    80002410:	01450513          	addi	a0,a0,20 # 8000c420 <digits+0x3e0>
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	12a080e7          	jalr	298(ra) # 8000053e <panic>
      fileclose(f);
    8000241c:	00002097          	auipc	ra,0x2
    80002420:	192080e7          	jalr	402(ra) # 800045ae <fileclose>
      p->ofile[fd] = 0;
    80002424:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002428:	04a1                	addi	s1,s1,8
    8000242a:	01248563          	beq	s1,s2,80002434 <exit+0x58>
    if(p->ofile[fd]){
    8000242e:	6088                	ld	a0,0(s1)
    80002430:	f575                	bnez	a0,8000241c <exit+0x40>
    80002432:	bfdd                	j	80002428 <exit+0x4c>
  begin_op();
    80002434:	00002097          	auipc	ra,0x2
    80002438:	cae080e7          	jalr	-850(ra) # 800040e2 <begin_op>
  iput(p->cwd);
    8000243c:	1509b503          	ld	a0,336(s3)
    80002440:	00001097          	auipc	ra,0x1
    80002444:	48a080e7          	jalr	1162(ra) # 800038ca <iput>
  end_op();
    80002448:	00002097          	auipc	ra,0x2
    8000244c:	d1a080e7          	jalr	-742(ra) # 80004162 <end_op>
  p->cwd = 0;
    80002450:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002454:	00016497          	auipc	s1,0x16
    80002458:	e6448493          	addi	s1,s1,-412 # 800182b8 <wait_lock>
    8000245c:	8526                	mv	a0,s1
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	786080e7          	jalr	1926(ra) # 80000be4 <acquire>
  reparent(p);
    80002466:	854e                	mv	a0,s3
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	f1a080e7          	jalr	-230(ra) # 80002382 <reparent>
  wakeup(p->parent);
    80002470:	0389b503          	ld	a0,56(s3)
    80002474:	00000097          	auipc	ra,0x0
    80002478:	e98080e7          	jalr	-360(ra) # 8000230c <wakeup>
  acquire(&p->lock);
    8000247c:	854e                	mv	a0,s3
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	766080e7          	jalr	1894(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002486:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000248a:	4795                	li	a5,5
    8000248c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	806080e7          	jalr	-2042(ra) # 80000c98 <release>
  sched();
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	bd4080e7          	jalr	-1068(ra) # 8000206e <sched>
  panic("zombie exit");
    800024a2:	0000a517          	auipc	a0,0xa
    800024a6:	f8e50513          	addi	a0,a0,-114 # 8000c430 <digits+0x3f0>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	094080e7          	jalr	148(ra) # 8000053e <panic>

00000000800024b2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	1800                	addi	s0,sp,48
    800024c0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024c2:	00016497          	auipc	s1,0x16
    800024c6:	20e48493          	addi	s1,s1,526 # 800186d0 <proc>
    800024ca:	0001c997          	auipc	s3,0x1c
    800024ce:	c0698993          	addi	s3,s3,-1018 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	710080e7          	jalr	1808(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024dc:	589c                	lw	a5,48(s1)
    800024de:	01278d63          	beq	a5,s2,800024f8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7b4080e7          	jalr	1972(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ec:	16848493          	addi	s1,s1,360
    800024f0:	ff3491e3          	bne	s1,s3,800024d2 <kill+0x20>
  }
  return -1;
    800024f4:	557d                	li	a0,-1
    800024f6:	a829                	j	80002510 <kill+0x5e>
      p->killed = 1;
    800024f8:	4785                	li	a5,1
    800024fa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024fc:	4c98                	lw	a4,24(s1)
    800024fe:	4789                	li	a5,2
    80002500:	00f70f63          	beq	a4,a5,8000251e <kill+0x6c>
      release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
      return 0;
    8000250e:	4501                	li	a0,0
}
    80002510:	70a2                	ld	ra,40(sp)
    80002512:	7402                	ld	s0,32(sp)
    80002514:	64e2                	ld	s1,24(sp)
    80002516:	6942                	ld	s2,16(sp)
    80002518:	69a2                	ld	s3,8(sp)
    8000251a:	6145                	addi	sp,sp,48
    8000251c:	8082                	ret
        p->state = RUNNABLE;
    8000251e:	478d                	li	a5,3
    80002520:	cc9c                	sw	a5,24(s1)
    80002522:	b7cd                	j	80002504 <kill+0x52>

0000000080002524 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002524:	7179                	addi	sp,sp,-48
    80002526:	f406                	sd	ra,40(sp)
    80002528:	f022                	sd	s0,32(sp)
    8000252a:	ec26                	sd	s1,24(sp)
    8000252c:	e84a                	sd	s2,16(sp)
    8000252e:	e44e                	sd	s3,8(sp)
    80002530:	e052                	sd	s4,0(sp)
    80002532:	1800                	addi	s0,sp,48
    80002534:	84aa                	mv	s1,a0
    80002536:	892e                	mv	s2,a1
    80002538:	89b2                	mv	s3,a2
    8000253a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	554080e7          	jalr	1364(ra) # 80001a90 <myproc>
  if(user_dst){
    80002544:	c08d                	beqz	s1,80002566 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002546:	86d2                	mv	a3,s4
    80002548:	864e                	mv	a2,s3
    8000254a:	85ca                	mv	a1,s2
    8000254c:	6928                	ld	a0,80(a0)
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	204080e7          	jalr	516(ra) # 80001752 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002556:	70a2                	ld	ra,40(sp)
    80002558:	7402                	ld	s0,32(sp)
    8000255a:	64e2                	ld	s1,24(sp)
    8000255c:	6942                	ld	s2,16(sp)
    8000255e:	69a2                	ld	s3,8(sp)
    80002560:	6a02                	ld	s4,0(sp)
    80002562:	6145                	addi	sp,sp,48
    80002564:	8082                	ret
    memmove((char *)dst, src, len);
    80002566:	000a061b          	sext.w	a2,s4
    8000256a:	85ce                	mv	a1,s3
    8000256c:	854a                	mv	a0,s2
    8000256e:	ffffe097          	auipc	ra,0xffffe
    80002572:	7d2080e7          	jalr	2002(ra) # 80000d40 <memmove>
    return 0;
    80002576:	8526                	mv	a0,s1
    80002578:	bff9                	j	80002556 <either_copyout+0x32>

000000008000257a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000257a:	7179                	addi	sp,sp,-48
    8000257c:	f406                	sd	ra,40(sp)
    8000257e:	f022                	sd	s0,32(sp)
    80002580:	ec26                	sd	s1,24(sp)
    80002582:	e84a                	sd	s2,16(sp)
    80002584:	e44e                	sd	s3,8(sp)
    80002586:	e052                	sd	s4,0(sp)
    80002588:	1800                	addi	s0,sp,48
    8000258a:	892a                	mv	s2,a0
    8000258c:	84ae                	mv	s1,a1
    8000258e:	89b2                	mv	s3,a2
    80002590:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	4fe080e7          	jalr	1278(ra) # 80001a90 <myproc>
  if(user_src){
    8000259a:	c08d                	beqz	s1,800025bc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000259c:	86d2                	mv	a3,s4
    8000259e:	864e                	mv	a2,s3
    800025a0:	85ca                	mv	a1,s2
    800025a2:	6928                	ld	a0,80(a0)
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	23a080e7          	jalr	570(ra) # 800017de <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ac:	70a2                	ld	ra,40(sp)
    800025ae:	7402                	ld	s0,32(sp)
    800025b0:	64e2                	ld	s1,24(sp)
    800025b2:	6942                	ld	s2,16(sp)
    800025b4:	69a2                	ld	s3,8(sp)
    800025b6:	6a02                	ld	s4,0(sp)
    800025b8:	6145                	addi	sp,sp,48
    800025ba:	8082                	ret
    memmove(dst, (char*)src, len);
    800025bc:	000a061b          	sext.w	a2,s4
    800025c0:	85ce                	mv	a1,s3
    800025c2:	854a                	mv	a0,s2
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	77c080e7          	jalr	1916(ra) # 80000d40 <memmove>
    return 0;
    800025cc:	8526                	mv	a0,s1
    800025ce:	bff9                	j	800025ac <either_copyin+0x32>

00000000800025d0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025d0:	715d                	addi	sp,sp,-80
    800025d2:	e486                	sd	ra,72(sp)
    800025d4:	e0a2                	sd	s0,64(sp)
    800025d6:	fc26                	sd	s1,56(sp)
    800025d8:	f84a                	sd	s2,48(sp)
    800025da:	f44e                	sd	s3,40(sp)
    800025dc:	f052                	sd	s4,32(sp)
    800025de:	ec56                	sd	s5,24(sp)
    800025e0:	e85a                	sd	s6,16(sp)
    800025e2:	e45e                	sd	s7,8(sp)
    800025e4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e6:	0000a517          	auipc	a0,0xa
    800025ea:	b3a50513          	addi	a0,a0,-1222 # 8000c120 <digits+0xe0>
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	f9a080e7          	jalr	-102(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f6:	00016497          	auipc	s1,0x16
    800025fa:	23248493          	addi	s1,s1,562 # 80018828 <proc+0x158>
    800025fe:	0001c917          	auipc	s2,0x1c
    80002602:	c2a90913          	addi	s2,s2,-982 # 8001e228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002606:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002608:	0000a997          	auipc	s3,0xa
    8000260c:	e3898993          	addi	s3,s3,-456 # 8000c440 <digits+0x400>
    printf("%d %s %s", p->pid, state, p->name);
    80002610:	0000aa97          	auipc	s5,0xa
    80002614:	e38a8a93          	addi	s5,s5,-456 # 8000c448 <digits+0x408>
    printf("\n");
    80002618:	0000aa17          	auipc	s4,0xa
    8000261c:	b08a0a13          	addi	s4,s4,-1272 # 8000c120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002620:	0000ab97          	auipc	s7,0xa
    80002624:	e60b8b93          	addi	s7,s7,-416 # 8000c480 <states.1709>
    80002628:	a00d                	j	8000264a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000262a:	ed86a583          	lw	a1,-296(a3)
    8000262e:	8556                	mv	a0,s5
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f58080e7          	jalr	-168(ra) # 80000588 <printf>
    printf("\n");
    80002638:	8552                	mv	a0,s4
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f4e080e7          	jalr	-178(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002642:	16848493          	addi	s1,s1,360
    80002646:	03248163          	beq	s1,s2,80002668 <procdump+0x98>
    if(p->state == UNUSED)
    8000264a:	86a6                	mv	a3,s1
    8000264c:	ec04a783          	lw	a5,-320(s1)
    80002650:	dbed                	beqz	a5,80002642 <procdump+0x72>
      state = "???";
    80002652:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002654:	fcfb6be3          	bltu	s6,a5,8000262a <procdump+0x5a>
    80002658:	1782                	slli	a5,a5,0x20
    8000265a:	9381                	srli	a5,a5,0x20
    8000265c:	078e                	slli	a5,a5,0x3
    8000265e:	97de                	add	a5,a5,s7
    80002660:	6390                	ld	a2,0(a5)
    80002662:	f661                	bnez	a2,8000262a <procdump+0x5a>
      state = "???";
    80002664:	864e                	mv	a2,s3
    80002666:	b7d1                	j	8000262a <procdump+0x5a>
  }
}
    80002668:	60a6                	ld	ra,72(sp)
    8000266a:	6406                	ld	s0,64(sp)
    8000266c:	74e2                	ld	s1,56(sp)
    8000266e:	7942                	ld	s2,48(sp)
    80002670:	79a2                	ld	s3,40(sp)
    80002672:	7a02                	ld	s4,32(sp)
    80002674:	6ae2                	ld	s5,24(sp)
    80002676:	6b42                	ld	s6,16(sp)
    80002678:	6ba2                	ld	s7,8(sp)
    8000267a:	6161                	addi	sp,sp,80
    8000267c:	8082                	ret

000000008000267e <swtch>:
    8000267e:	00153023          	sd	ra,0(a0)
    80002682:	00253423          	sd	sp,8(a0)
    80002686:	e900                	sd	s0,16(a0)
    80002688:	ed04                	sd	s1,24(a0)
    8000268a:	03253023          	sd	s2,32(a0)
    8000268e:	03353423          	sd	s3,40(a0)
    80002692:	03453823          	sd	s4,48(a0)
    80002696:	03553c23          	sd	s5,56(a0)
    8000269a:	05653023          	sd	s6,64(a0)
    8000269e:	05753423          	sd	s7,72(a0)
    800026a2:	05853823          	sd	s8,80(a0)
    800026a6:	05953c23          	sd	s9,88(a0)
    800026aa:	07a53023          	sd	s10,96(a0)
    800026ae:	07b53423          	sd	s11,104(a0)
    800026b2:	0005b083          	ld	ra,0(a1)
    800026b6:	0085b103          	ld	sp,8(a1)
    800026ba:	6980                	ld	s0,16(a1)
    800026bc:	6d84                	ld	s1,24(a1)
    800026be:	0205b903          	ld	s2,32(a1)
    800026c2:	0285b983          	ld	s3,40(a1)
    800026c6:	0305ba03          	ld	s4,48(a1)
    800026ca:	0385ba83          	ld	s5,56(a1)
    800026ce:	0405bb03          	ld	s6,64(a1)
    800026d2:	0485bb83          	ld	s7,72(a1)
    800026d6:	0505bc03          	ld	s8,80(a1)
    800026da:	0585bc83          	ld	s9,88(a1)
    800026de:	0605bd03          	ld	s10,96(a1)
    800026e2:	0685bd83          	ld	s11,104(a1)
    800026e6:	8082                	ret

00000000800026e8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026e8:	1141                	addi	sp,sp,-16
    800026ea:	e406                	sd	ra,8(sp)
    800026ec:	e022                	sd	s0,0(sp)
    800026ee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026f0:	0000a597          	auipc	a1,0xa
    800026f4:	dc058593          	addi	a1,a1,-576 # 8000c4b0 <states.1709+0x30>
    800026f8:	0001c517          	auipc	a0,0x1c
    800026fc:	9d850513          	addi	a0,a0,-1576 # 8001e0d0 <tickslock>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	454080e7          	jalr	1108(ra) # 80000b54 <initlock>
}
    80002708:	60a2                	ld	ra,8(sp)
    8000270a:	6402                	ld	s0,0(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  printf("kernelvec: %x\n",kernelvec);
    80002718:	00003597          	auipc	a1,0x3
    8000271c:	4d858593          	addi	a1,a1,1240 # 80005bf0 <kernelvec>
    80002720:	0000a517          	auipc	a0,0xa
    80002724:	d9850513          	addi	a0,a0,-616 # 8000c4b8 <states.1709+0x38>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	e60080e7          	jalr	-416(ra) # 80000588 <printf>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002730:	00003797          	auipc	a5,0x3
    80002734:	4c078793          	addi	a5,a5,1216 # 80005bf0 <kernelvec>
    80002738:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000273c:	60a2                	ld	ra,8(sp)
    8000273e:	6402                	ld	s0,0(sp)
    80002740:	0141                	addi	sp,sp,16
    80002742:	8082                	ret

0000000080002744 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002744:	1141                	addi	sp,sp,-16
    80002746:	e406                	sd	ra,8(sp)
    80002748:	e022                	sd	s0,0(sp)
    8000274a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000274c:	fffff097          	auipc	ra,0xfffff
    80002750:	344080e7          	jalr	836(ra) # 80001a90 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002754:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002758:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000275a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000275e:	00006617          	auipc	a2,0x6
    80002762:	8a260613          	addi	a2,a2,-1886 # 80008000 <_trampoline>
    80002766:	00006697          	auipc	a3,0x6
    8000276a:	89a68693          	addi	a3,a3,-1894 # 80008000 <_trampoline>
    8000276e:	8e91                	sub	a3,a3,a2
    80002770:	008007b7          	lui	a5,0x800
    80002774:	17fd                	addi	a5,a5,-1
    80002776:	07ba                	slli	a5,a5,0xe
    80002778:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000277a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000277e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002780:	180026f3          	csrr	a3,satp
    80002784:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002786:	6d38                	ld	a4,88(a0)
    80002788:	6134                	ld	a3,64(a0)
    8000278a:	6591                	lui	a1,0x4
    8000278c:	96ae                	add	a3,a3,a1
    8000278e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002790:	6d38                	ld	a4,88(a0)
    80002792:	00000697          	auipc	a3,0x0
    80002796:	13868693          	addi	a3,a3,312 # 800028ca <usertrap>
    8000279a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000279c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000279e:	8692                	mv	a3,tp
    800027a0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027a2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027a6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027aa:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ae:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027b2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027b4:	6f18                	ld	a4,24(a4)
    800027b6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ba:	692c                	ld	a1,80(a0)
    800027bc:	81b9                	srli	a1,a1,0xe

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027be:	00006717          	auipc	a4,0x6
    800027c2:	8d270713          	addi	a4,a4,-1838 # 80008090 <userret>
    800027c6:	8f11                	sub	a4,a4,a2
    800027c8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ca:	577d                	li	a4,-1
    800027cc:	177e                	slli	a4,a4,0x3f
    800027ce:	8dd9                	or	a1,a1,a4
    800027d0:	00400537          	lui	a0,0x400
    800027d4:	157d                	addi	a0,a0,-1
    800027d6:	053e                	slli	a0,a0,0xf
    800027d8:	9782                	jalr	a5
}
    800027da:	60a2                	ld	ra,8(sp)
    800027dc:	6402                	ld	s0,0(sp)
    800027de:	0141                	addi	sp,sp,16
    800027e0:	8082                	ret

00000000800027e2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027e2:	1101                	addi	sp,sp,-32
    800027e4:	ec06                	sd	ra,24(sp)
    800027e6:	e822                	sd	s0,16(sp)
    800027e8:	e426                	sd	s1,8(sp)
    800027ea:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ec:	0001c497          	auipc	s1,0x1c
    800027f0:	8e448493          	addi	s1,s1,-1820 # 8001e0d0 <tickslock>
    800027f4:	8526                	mv	a0,s1
    800027f6:	ffffe097          	auipc	ra,0xffffe
    800027fa:	3ee080e7          	jalr	1006(ra) # 80000be4 <acquire>
  ticks++;
    800027fe:	0000e517          	auipc	a0,0xe
    80002802:	83250513          	addi	a0,a0,-1998 # 80010030 <ticks>
    80002806:	411c                	lw	a5,0(a0)
    80002808:	2785                	addiw	a5,a5,1
    8000280a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	b00080e7          	jalr	-1280(ra) # 8000230c <wakeup>
  release(&tickslock);
    80002814:	8526                	mv	a0,s1
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	482080e7          	jalr	1154(ra) # 80000c98 <release>
}
    8000281e:	60e2                	ld	ra,24(sp)
    80002820:	6442                	ld	s0,16(sp)
    80002822:	64a2                	ld	s1,8(sp)
    80002824:	6105                	addi	sp,sp,32
    80002826:	8082                	ret

0000000080002828 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002828:	1101                	addi	sp,sp,-32
    8000282a:	ec06                	sd	ra,24(sp)
    8000282c:	e822                	sd	s0,16(sp)
    8000282e:	e426                	sd	s1,8(sp)
    80002830:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002832:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002836:	00074d63          	bltz	a4,80002850 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000283a:	57fd                	li	a5,-1
    8000283c:	17fe                	slli	a5,a5,0x3f
    8000283e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002840:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002842:	06f70363          	beq	a4,a5,800028a8 <devintr+0x80>
  }
}
    80002846:	60e2                	ld	ra,24(sp)
    80002848:	6442                	ld	s0,16(sp)
    8000284a:	64a2                	ld	s1,8(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret
     (scause & 0xff) == 9){
    80002850:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002854:	46a5                	li	a3,9
    80002856:	fed792e3          	bne	a5,a3,8000283a <devintr+0x12>
    int irq = plic_claim();
    8000285a:	00003097          	auipc	ra,0x3
    8000285e:	49e080e7          	jalr	1182(ra) # 80005cf8 <plic_claim>
    80002862:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002864:	47a9                	li	a5,10
    80002866:	02f50763          	beq	a0,a5,80002894 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000286a:	4785                	li	a5,1
    8000286c:	02f50963          	beq	a0,a5,8000289e <devintr+0x76>
    return 1;
    80002870:	4505                	li	a0,1
    } else if(irq){
    80002872:	d8f1                	beqz	s1,80002846 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002874:	85a6                	mv	a1,s1
    80002876:	0000a517          	auipc	a0,0xa
    8000287a:	c5250513          	addi	a0,a0,-942 # 8000c4c8 <states.1709+0x48>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	d0a080e7          	jalr	-758(ra) # 80000588 <printf>
      plic_complete(irq);
    80002886:	8526                	mv	a0,s1
    80002888:	00003097          	auipc	ra,0x3
    8000288c:	494080e7          	jalr	1172(ra) # 80005d1c <plic_complete>
    return 1;
    80002890:	4505                	li	a0,1
    80002892:	bf55                	j	80002846 <devintr+0x1e>
      uartintr();
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	114080e7          	jalr	276(ra) # 800009a8 <uartintr>
    8000289c:	b7ed                	j	80002886 <devintr+0x5e>
      virtio_disk_intr();
    8000289e:	00004097          	auipc	ra,0x4
    800028a2:	98c080e7          	jalr	-1652(ra) # 8000622a <virtio_disk_intr>
    800028a6:	b7c5                	j	80002886 <devintr+0x5e>
    if(cpuid() == 0){
    800028a8:	fffff097          	auipc	ra,0xfffff
    800028ac:	1bc080e7          	jalr	444(ra) # 80001a64 <cpuid>
    800028b0:	c901                	beqz	a0,800028c0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028b2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028b8:	14479073          	csrw	sip,a5
    return 2;
    800028bc:	4509                	li	a0,2
    800028be:	b761                	j	80002846 <devintr+0x1e>
      clockintr();
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	f22080e7          	jalr	-222(ra) # 800027e2 <clockintr>
    800028c8:	b7ed                	j	800028b2 <devintr+0x8a>

00000000800028ca <usertrap>:
{
    800028ca:	1101                	addi	sp,sp,-32
    800028cc:	ec06                	sd	ra,24(sp)
    800028ce:	e822                	sd	s0,16(sp)
    800028d0:	e426                	sd	s1,8(sp)
    800028d2:	e04a                	sd	s2,0(sp)
    800028d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028da:	1007f793          	andi	a5,a5,256
    800028de:	e3ad                	bnez	a5,80002940 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028e0:	00003797          	auipc	a5,0x3
    800028e4:	31078793          	addi	a5,a5,784 # 80005bf0 <kernelvec>
    800028e8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ec:	fffff097          	auipc	ra,0xfffff
    800028f0:	1a4080e7          	jalr	420(ra) # 80001a90 <myproc>
    800028f4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028f6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f8:	14102773          	csrr	a4,sepc
    800028fc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fe:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002902:	47a1                	li	a5,8
    80002904:	04f71c63          	bne	a4,a5,8000295c <usertrap+0x92>
    if(p->killed)
    80002908:	551c                	lw	a5,40(a0)
    8000290a:	e3b9                	bnez	a5,80002950 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000290c:	6cb8                	ld	a4,88(s1)
    8000290e:	6f1c                	ld	a5,24(a4)
    80002910:	0791                	addi	a5,a5,4
    80002912:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002914:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002918:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291c:	10079073          	csrw	sstatus,a5
    syscall();
    80002920:	00000097          	auipc	ra,0x0
    80002924:	2e0080e7          	jalr	736(ra) # 80002c00 <syscall>
  if(p->killed)
    80002928:	549c                	lw	a5,40(s1)
    8000292a:	ebc1                	bnez	a5,800029ba <usertrap+0xf0>
  usertrapret();
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	e18080e7          	jalr	-488(ra) # 80002744 <usertrapret>
}
    80002934:	60e2                	ld	ra,24(sp)
    80002936:	6442                	ld	s0,16(sp)
    80002938:	64a2                	ld	s1,8(sp)
    8000293a:	6902                	ld	s2,0(sp)
    8000293c:	6105                	addi	sp,sp,32
    8000293e:	8082                	ret
    panic("usertrap: not from user mode");
    80002940:	0000a517          	auipc	a0,0xa
    80002944:	ba850513          	addi	a0,a0,-1112 # 8000c4e8 <states.1709+0x68>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	bf6080e7          	jalr	-1034(ra) # 8000053e <panic>
      exit(-1);
    80002950:	557d                	li	a0,-1
    80002952:	00000097          	auipc	ra,0x0
    80002956:	a8a080e7          	jalr	-1398(ra) # 800023dc <exit>
    8000295a:	bf4d                	j	8000290c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	ecc080e7          	jalr	-308(ra) # 80002828 <devintr>
    80002964:	892a                	mv	s2,a0
    80002966:	c501                	beqz	a0,8000296e <usertrap+0xa4>
  if(p->killed)
    80002968:	549c                	lw	a5,40(s1)
    8000296a:	c3a1                	beqz	a5,800029aa <usertrap+0xe0>
    8000296c:	a815                	j	800029a0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002972:	5890                	lw	a2,48(s1)
    80002974:	0000a517          	auipc	a0,0xa
    80002978:	b9450513          	addi	a0,a0,-1132 # 8000c508 <states.1709+0x88>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	c0c080e7          	jalr	-1012(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002984:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002988:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000298c:	0000a517          	auipc	a0,0xa
    80002990:	bac50513          	addi	a0,a0,-1108 # 8000c538 <states.1709+0xb8>
    80002994:	ffffe097          	auipc	ra,0xffffe
    80002998:	bf4080e7          	jalr	-1036(ra) # 80000588 <printf>
    p->killed = 1;
    8000299c:	4785                	li	a5,1
    8000299e:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029a0:	557d                	li	a0,-1
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	a3a080e7          	jalr	-1478(ra) # 800023dc <exit>
  if(which_dev == 2)
    800029aa:	4789                	li	a5,2
    800029ac:	f8f910e3          	bne	s2,a5,8000292c <usertrap+0x62>
    yield();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	794080e7          	jalr	1940(ra) # 80002144 <yield>
    800029b8:	bf95                	j	8000292c <usertrap+0x62>
  int which_dev = 0;
    800029ba:	4901                	li	s2,0
    800029bc:	b7d5                	j	800029a0 <usertrap+0xd6>

00000000800029be <kerneltrap>:
{
    800029be:	7179                	addi	sp,sp,-48
    800029c0:	f406                	sd	ra,40(sp)
    800029c2:	f022                	sd	s0,32(sp)
    800029c4:	ec26                	sd	s1,24(sp)
    800029c6:	e84a                	sd	s2,16(sp)
    800029c8:	e44e                	sd	s3,8(sp)
    800029ca:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029cc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029d8:	1004f793          	andi	a5,s1,256
    800029dc:	cb85                	beqz	a5,80002a0c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029de:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029e2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029e4:	ef85                	bnez	a5,80002a1c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	e42080e7          	jalr	-446(ra) # 80002828 <devintr>
    800029ee:	cd1d                	beqz	a0,80002a2c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029f0:	4789                	li	a5,2
    800029f2:	06f50a63          	beq	a0,a5,80002a66 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029f6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029fa:	10049073          	csrw	sstatus,s1
}
    800029fe:	70a2                	ld	ra,40(sp)
    80002a00:	7402                	ld	s0,32(sp)
    80002a02:	64e2                	ld	s1,24(sp)
    80002a04:	6942                	ld	s2,16(sp)
    80002a06:	69a2                	ld	s3,8(sp)
    80002a08:	6145                	addi	sp,sp,48
    80002a0a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a0c:	0000a517          	auipc	a0,0xa
    80002a10:	b4c50513          	addi	a0,a0,-1204 # 8000c558 <states.1709+0xd8>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a1c:	0000a517          	auipc	a0,0xa
    80002a20:	b6450513          	addi	a0,a0,-1180 # 8000c580 <states.1709+0x100>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b1a080e7          	jalr	-1254(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a2c:	85ce                	mv	a1,s3
    80002a2e:	0000a517          	auipc	a0,0xa
    80002a32:	b7250513          	addi	a0,a0,-1166 # 8000c5a0 <states.1709+0x120>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a42:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a46:	0000a517          	auipc	a0,0xa
    80002a4a:	b6a50513          	addi	a0,a0,-1174 # 8000c5b0 <states.1709+0x130>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b3a080e7          	jalr	-1222(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a56:	0000a517          	auipc	a0,0xa
    80002a5a:	b7250513          	addi	a0,a0,-1166 # 8000c5c8 <states.1709+0x148>
    80002a5e:	ffffe097          	auipc	ra,0xffffe
    80002a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	02a080e7          	jalr	42(ra) # 80001a90 <myproc>
    80002a6e:	d541                	beqz	a0,800029f6 <kerneltrap+0x38>
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	020080e7          	jalr	32(ra) # 80001a90 <myproc>
    80002a78:	4d18                	lw	a4,24(a0)
    80002a7a:	4791                	li	a5,4
    80002a7c:	f6f71de3          	bne	a4,a5,800029f6 <kerneltrap+0x38>
    yield();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	6c4080e7          	jalr	1732(ra) # 80002144 <yield>
    80002a88:	b7bd                	j	800029f6 <kerneltrap+0x38>

0000000080002a8a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a8a:	1101                	addi	sp,sp,-32
    80002a8c:	ec06                	sd	ra,24(sp)
    80002a8e:	e822                	sd	s0,16(sp)
    80002a90:	e426                	sd	s1,8(sp)
    80002a92:	1000                	addi	s0,sp,32
    80002a94:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	ffa080e7          	jalr	-6(ra) # 80001a90 <myproc>
  switch (n) {
    80002a9e:	4795                	li	a5,5
    80002aa0:	0497e163          	bltu	a5,s1,80002ae2 <argraw+0x58>
    80002aa4:	048a                	slli	s1,s1,0x2
    80002aa6:	0000a717          	auipc	a4,0xa
    80002aaa:	b5a70713          	addi	a4,a4,-1190 # 8000c600 <states.1709+0x180>
    80002aae:	94ba                	add	s1,s1,a4
    80002ab0:	409c                	lw	a5,0(s1)
    80002ab2:	97ba                	add	a5,a5,a4
    80002ab4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aba:	60e2                	ld	ra,24(sp)
    80002abc:	6442                	ld	s0,16(sp)
    80002abe:	64a2                	ld	s1,8(sp)
    80002ac0:	6105                	addi	sp,sp,32
    80002ac2:	8082                	ret
    return p->trapframe->a1;
    80002ac4:	6d3c                	ld	a5,88(a0)
    80002ac6:	7fa8                	ld	a0,120(a5)
    80002ac8:	bfcd                	j	80002aba <argraw+0x30>
    return p->trapframe->a2;
    80002aca:	6d3c                	ld	a5,88(a0)
    80002acc:	63c8                	ld	a0,128(a5)
    80002ace:	b7f5                	j	80002aba <argraw+0x30>
    return p->trapframe->a3;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	67c8                	ld	a0,136(a5)
    80002ad4:	b7dd                	j	80002aba <argraw+0x30>
    return p->trapframe->a4;
    80002ad6:	6d3c                	ld	a5,88(a0)
    80002ad8:	6bc8                	ld	a0,144(a5)
    80002ada:	b7c5                	j	80002aba <argraw+0x30>
    return p->trapframe->a5;
    80002adc:	6d3c                	ld	a5,88(a0)
    80002ade:	6fc8                	ld	a0,152(a5)
    80002ae0:	bfe9                	j	80002aba <argraw+0x30>
  panic("argraw");
    80002ae2:	0000a517          	auipc	a0,0xa
    80002ae6:	af650513          	addi	a0,a0,-1290 # 8000c5d8 <states.1709+0x158>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	a54080e7          	jalr	-1452(ra) # 8000053e <panic>

0000000080002af2 <fetchaddr>:
{
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	e04a                	sd	s2,0(sp)
    80002afc:	1000                	addi	s0,sp,32
    80002afe:	84aa                	mv	s1,a0
    80002b00:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	f8e080e7          	jalr	-114(ra) # 80001a90 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b0a:	653c                	ld	a5,72(a0)
    80002b0c:	02f4f863          	bgeu	s1,a5,80002b3c <fetchaddr+0x4a>
    80002b10:	00848713          	addi	a4,s1,8
    80002b14:	02e7e663          	bltu	a5,a4,80002b40 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b18:	46a1                	li	a3,8
    80002b1a:	8626                	mv	a2,s1
    80002b1c:	85ca                	mv	a1,s2
    80002b1e:	6928                	ld	a0,80(a0)
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	cbe080e7          	jalr	-834(ra) # 800017de <copyin>
    80002b28:	00a03533          	snez	a0,a0
    80002b2c:	40a00533          	neg	a0,a0
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6902                	ld	s2,0(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret
    return -1;
    80002b3c:	557d                	li	a0,-1
    80002b3e:	bfcd                	j	80002b30 <fetchaddr+0x3e>
    80002b40:	557d                	li	a0,-1
    80002b42:	b7fd                	j	80002b30 <fetchaddr+0x3e>

0000000080002b44 <fetchstr>:
{
    80002b44:	7179                	addi	sp,sp,-48
    80002b46:	f406                	sd	ra,40(sp)
    80002b48:	f022                	sd	s0,32(sp)
    80002b4a:	ec26                	sd	s1,24(sp)
    80002b4c:	e84a                	sd	s2,16(sp)
    80002b4e:	e44e                	sd	s3,8(sp)
    80002b50:	1800                	addi	s0,sp,48
    80002b52:	892a                	mv	s2,a0
    80002b54:	84ae                	mv	s1,a1
    80002b56:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	f38080e7          	jalr	-200(ra) # 80001a90 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b60:	86ce                	mv	a3,s3
    80002b62:	864a                	mv	a2,s2
    80002b64:	85a6                	mv	a1,s1
    80002b66:	6928                	ld	a0,80(a0)
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	d02080e7          	jalr	-766(ra) # 8000186a <copyinstr>
  if(err < 0)
    80002b70:	00054763          	bltz	a0,80002b7e <fetchstr+0x3a>
  return strlen(buf);
    80002b74:	8526                	mv	a0,s1
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	2ee080e7          	jalr	750(ra) # 80000e64 <strlen>
}
    80002b7e:	70a2                	ld	ra,40(sp)
    80002b80:	7402                	ld	s0,32(sp)
    80002b82:	64e2                	ld	s1,24(sp)
    80002b84:	6942                	ld	s2,16(sp)
    80002b86:	69a2                	ld	s3,8(sp)
    80002b88:	6145                	addi	sp,sp,48
    80002b8a:	8082                	ret

0000000080002b8c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b8c:	1101                	addi	sp,sp,-32
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e822                	sd	s0,16(sp)
    80002b92:	e426                	sd	s1,8(sp)
    80002b94:	1000                	addi	s0,sp,32
    80002b96:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	ef2080e7          	jalr	-270(ra) # 80002a8a <argraw>
    80002ba0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ba2:	4501                	li	a0,0
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6105                	addi	sp,sp,32
    80002bac:	8082                	ret

0000000080002bae <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bae:	1101                	addi	sp,sp,-32
    80002bb0:	ec06                	sd	ra,24(sp)
    80002bb2:	e822                	sd	s0,16(sp)
    80002bb4:	e426                	sd	s1,8(sp)
    80002bb6:	1000                	addi	s0,sp,32
    80002bb8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	ed0080e7          	jalr	-304(ra) # 80002a8a <argraw>
    80002bc2:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bc4:	4501                	li	a0,0
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	64a2                	ld	s1,8(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret

0000000080002bd0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	e04a                	sd	s2,0(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
    80002bde:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	eaa080e7          	jalr	-342(ra) # 80002a8a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002be8:	864a                	mv	a2,s2
    80002bea:	85a6                	mv	a1,s1
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	f58080e7          	jalr	-168(ra) # 80002b44 <fetchstr>
}
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6902                	ld	s2,0(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret

0000000080002c00 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	e04a                	sd	s2,0(sp)
    80002c0a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	e84080e7          	jalr	-380(ra) # 80001a90 <myproc>
    80002c14:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002c16:	05853903          	ld	s2,88(a0)
    80002c1a:	0a893783          	ld	a5,168(s2)
    80002c1e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c22:	37fd                	addiw	a5,a5,-1
    80002c24:	4751                	li	a4,20
    80002c26:	00f76f63          	bltu	a4,a5,80002c44 <syscall+0x44>
    80002c2a:	00369713          	slli	a4,a3,0x3
    80002c2e:	0000a797          	auipc	a5,0xa
    80002c32:	9ea78793          	addi	a5,a5,-1558 # 8000c618 <syscalls>
    80002c36:	97ba                	add	a5,a5,a4
    80002c38:	639c                	ld	a5,0(a5)
    80002c3a:	c789                	beqz	a5,80002c44 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c3c:	9782                	jalr	a5
    80002c3e:	06a93823          	sd	a0,112(s2)
    80002c42:	a839                	j	80002c60 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c44:	15848613          	addi	a2,s1,344
    80002c48:	588c                	lw	a1,48(s1)
    80002c4a:	0000a517          	auipc	a0,0xa
    80002c4e:	99650513          	addi	a0,a0,-1642 # 8000c5e0 <states.1709+0x160>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	936080e7          	jalr	-1738(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c5a:	6cbc                	ld	a5,88(s1)
    80002c5c:	577d                	li	a4,-1
    80002c5e:	fbb8                	sd	a4,112(a5)
  }
}
    80002c60:	60e2                	ld	ra,24(sp)
    80002c62:	6442                	ld	s0,16(sp)
    80002c64:	64a2                	ld	s1,8(sp)
    80002c66:	6902                	ld	s2,0(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret

0000000080002c6c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c6c:	1101                	addi	sp,sp,-32
    80002c6e:	ec06                	sd	ra,24(sp)
    80002c70:	e822                	sd	s0,16(sp)
    80002c72:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c74:	fec40593          	addi	a1,s0,-20
    80002c78:	4501                	li	a0,0
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	f12080e7          	jalr	-238(ra) # 80002b8c <argint>
    return -1;
    80002c82:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c84:	00054963          	bltz	a0,80002c96 <sys_exit+0x2a>
  exit(n);
    80002c88:	fec42503          	lw	a0,-20(s0)
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	750080e7          	jalr	1872(ra) # 800023dc <exit>
  return 0;  // not reached
    80002c94:	4781                	li	a5,0
}
    80002c96:	853e                	mv	a0,a5
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ca0:	1141                	addi	sp,sp,-16
    80002ca2:	e406                	sd	ra,8(sp)
    80002ca4:	e022                	sd	s0,0(sp)
    80002ca6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	de8080e7          	jalr	-536(ra) # 80001a90 <myproc>
}
    80002cb0:	5908                	lw	a0,48(a0)
    80002cb2:	60a2                	ld	ra,8(sp)
    80002cb4:	6402                	ld	s0,0(sp)
    80002cb6:	0141                	addi	sp,sp,16
    80002cb8:	8082                	ret

0000000080002cba <sys_fork>:

uint64
sys_fork(void)
{
    80002cba:	1141                	addi	sp,sp,-16
    80002cbc:	e406                	sd	ra,8(sp)
    80002cbe:	e022                	sd	s0,0(sp)
    80002cc0:	0800                	addi	s0,sp,16
  return fork();
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	1d0080e7          	jalr	464(ra) # 80001e92 <fork>
}
    80002cca:	60a2                	ld	ra,8(sp)
    80002ccc:	6402                	ld	s0,0(sp)
    80002cce:	0141                	addi	sp,sp,16
    80002cd0:	8082                	ret

0000000080002cd2 <sys_wait>:

uint64
sys_wait(void)
{
    80002cd2:	1101                	addi	sp,sp,-32
    80002cd4:	ec06                	sd	ra,24(sp)
    80002cd6:	e822                	sd	s0,16(sp)
    80002cd8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cda:	fe840593          	addi	a1,s0,-24
    80002cde:	4501                	li	a0,0
    80002ce0:	00000097          	auipc	ra,0x0
    80002ce4:	ece080e7          	jalr	-306(ra) # 80002bae <argaddr>
    80002ce8:	87aa                	mv	a5,a0
    return -1;
    80002cea:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cec:	0007c863          	bltz	a5,80002cfc <sys_wait+0x2a>
  return wait(p);
    80002cf0:	fe843503          	ld	a0,-24(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	4f0080e7          	jalr	1264(ra) # 800021e4 <wait>
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d04:	7179                	addi	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d0e:	fdc40593          	addi	a1,s0,-36
    80002d12:	4501                	li	a0,0
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	e78080e7          	jalr	-392(ra) # 80002b8c <argint>
    80002d1c:	87aa                	mv	a5,a0
    return -1;
    80002d1e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d20:	0207c063          	bltz	a5,80002d40 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	d6c080e7          	jalr	-660(ra) # 80001a90 <myproc>
    80002d2c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d2e:	fdc42503          	lw	a0,-36(s0)
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	0ec080e7          	jalr	236(ra) # 80001e1e <growproc>
    80002d3a:	00054863          	bltz	a0,80002d4a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d3e:	8526                	mv	a0,s1
}
    80002d40:	70a2                	ld	ra,40(sp)
    80002d42:	7402                	ld	s0,32(sp)
    80002d44:	64e2                	ld	s1,24(sp)
    80002d46:	6145                	addi	sp,sp,48
    80002d48:	8082                	ret
    return -1;
    80002d4a:	557d                	li	a0,-1
    80002d4c:	bfd5                	j	80002d40 <sys_sbrk+0x3c>

0000000080002d4e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d4e:	7139                	addi	sp,sp,-64
    80002d50:	fc06                	sd	ra,56(sp)
    80002d52:	f822                	sd	s0,48(sp)
    80002d54:	f426                	sd	s1,40(sp)
    80002d56:	f04a                	sd	s2,32(sp)
    80002d58:	ec4e                	sd	s3,24(sp)
    80002d5a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d5c:	fcc40593          	addi	a1,s0,-52
    80002d60:	4501                	li	a0,0
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	e2a080e7          	jalr	-470(ra) # 80002b8c <argint>
    return -1;
    80002d6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6c:	06054563          	bltz	a0,80002dd6 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d70:	0001b517          	auipc	a0,0x1b
    80002d74:	36050513          	addi	a0,a0,864 # 8001e0d0 <tickslock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	e6c080e7          	jalr	-404(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d80:	0000d917          	auipc	s2,0xd
    80002d84:	2b092903          	lw	s2,688(s2) # 80010030 <ticks>
  while(ticks - ticks0 < n){
    80002d88:	fcc42783          	lw	a5,-52(s0)
    80002d8c:	cf85                	beqz	a5,80002dc4 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d8e:	0001b997          	auipc	s3,0x1b
    80002d92:	34298993          	addi	s3,s3,834 # 8001e0d0 <tickslock>
    80002d96:	0000d497          	auipc	s1,0xd
    80002d9a:	29a48493          	addi	s1,s1,666 # 80010030 <ticks>
    if(myproc()->killed){
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	cf2080e7          	jalr	-782(ra) # 80001a90 <myproc>
    80002da6:	551c                	lw	a5,40(a0)
    80002da8:	ef9d                	bnez	a5,80002de6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002daa:	85ce                	mv	a1,s3
    80002dac:	8526                	mv	a0,s1
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	3d2080e7          	jalr	978(ra) # 80002180 <sleep>
  while(ticks - ticks0 < n){
    80002db6:	409c                	lw	a5,0(s1)
    80002db8:	412787bb          	subw	a5,a5,s2
    80002dbc:	fcc42703          	lw	a4,-52(s0)
    80002dc0:	fce7efe3          	bltu	a5,a4,80002d9e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dc4:	0001b517          	auipc	a0,0x1b
    80002dc8:	30c50513          	addi	a0,a0,780 # 8001e0d0 <tickslock>
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	ecc080e7          	jalr	-308(ra) # 80000c98 <release>
  return 0;
    80002dd4:	4781                	li	a5,0
}
    80002dd6:	853e                	mv	a0,a5
    80002dd8:	70e2                	ld	ra,56(sp)
    80002dda:	7442                	ld	s0,48(sp)
    80002ddc:	74a2                	ld	s1,40(sp)
    80002dde:	7902                	ld	s2,32(sp)
    80002de0:	69e2                	ld	s3,24(sp)
    80002de2:	6121                	addi	sp,sp,64
    80002de4:	8082                	ret
      release(&tickslock);
    80002de6:	0001b517          	auipc	a0,0x1b
    80002dea:	2ea50513          	addi	a0,a0,746 # 8001e0d0 <tickslock>
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	eaa080e7          	jalr	-342(ra) # 80000c98 <release>
      return -1;
    80002df6:	57fd                	li	a5,-1
    80002df8:	bff9                	j	80002dd6 <sys_sleep+0x88>

0000000080002dfa <sys_kill>:

uint64
sys_kill(void)
{
    80002dfa:	1101                	addi	sp,sp,-32
    80002dfc:	ec06                	sd	ra,24(sp)
    80002dfe:	e822                	sd	s0,16(sp)
    80002e00:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e02:	fec40593          	addi	a1,s0,-20
    80002e06:	4501                	li	a0,0
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	d84080e7          	jalr	-636(ra) # 80002b8c <argint>
    80002e10:	87aa                	mv	a5,a0
    return -1;
    80002e12:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e14:	0007c863          	bltz	a5,80002e24 <sys_kill+0x2a>
  return kill(pid);
    80002e18:	fec42503          	lw	a0,-20(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	696080e7          	jalr	1686(ra) # 800024b2 <kill>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret

0000000080002e2c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	e426                	sd	s1,8(sp)
    80002e34:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e36:	0001b517          	auipc	a0,0x1b
    80002e3a:	29a50513          	addi	a0,a0,666 # 8001e0d0 <tickslock>
    80002e3e:	ffffe097          	auipc	ra,0xffffe
    80002e42:	da6080e7          	jalr	-602(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e46:	0000d497          	auipc	s1,0xd
    80002e4a:	1ea4a483          	lw	s1,490(s1) # 80010030 <ticks>
  release(&tickslock);
    80002e4e:	0001b517          	auipc	a0,0x1b
    80002e52:	28250513          	addi	a0,a0,642 # 8001e0d0 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
  return xticks;
}
    80002e5e:	02049513          	slli	a0,s1,0x20
    80002e62:	9101                	srli	a0,a0,0x20
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6105                	addi	sp,sp,32
    80002e6c:	8082                	ret

0000000080002e6e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e6e:	7179                	addi	sp,sp,-48
    80002e70:	f406                	sd	ra,40(sp)
    80002e72:	f022                	sd	s0,32(sp)
    80002e74:	ec26                	sd	s1,24(sp)
    80002e76:	e84a                	sd	s2,16(sp)
    80002e78:	e44e                	sd	s3,8(sp)
    80002e7a:	e052                	sd	s4,0(sp)
    80002e7c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e7e:	0000a597          	auipc	a1,0xa
    80002e82:	84a58593          	addi	a1,a1,-1974 # 8000c6c8 <syscalls+0xb0>
    80002e86:	0001b517          	auipc	a0,0x1b
    80002e8a:	26250513          	addi	a0,a0,610 # 8001e0e8 <bcache>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	cc6080e7          	jalr	-826(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e96:	00023797          	auipc	a5,0x23
    80002e9a:	25278793          	addi	a5,a5,594 # 800260e8 <bcache+0x8000>
    80002e9e:	00023717          	auipc	a4,0x23
    80002ea2:	4b270713          	addi	a4,a4,1202 # 80026350 <bcache+0x8268>
    80002ea6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eaa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eae:	0001b497          	auipc	s1,0x1b
    80002eb2:	25248493          	addi	s1,s1,594 # 8001e100 <bcache+0x18>
    b->next = bcache.head.next;
    80002eb6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eb8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eba:	0000aa17          	auipc	s4,0xa
    80002ebe:	816a0a13          	addi	s4,s4,-2026 # 8000c6d0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ec2:	2b893783          	ld	a5,696(s2)
    80002ec6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ec8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ecc:	85d2                	mv	a1,s4
    80002ece:	01048513          	addi	a0,s1,16
    80002ed2:	00001097          	auipc	ra,0x1
    80002ed6:	4ce080e7          	jalr	1230(ra) # 800043a0 <initsleeplock>
    bcache.head.next->prev = b;
    80002eda:	2b893783          	ld	a5,696(s2)
    80002ede:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ee0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee4:	45848493          	addi	s1,s1,1112
    80002ee8:	fd349de3          	bne	s1,s3,80002ec2 <binit+0x54>
  }
}
    80002eec:	70a2                	ld	ra,40(sp)
    80002eee:	7402                	ld	s0,32(sp)
    80002ef0:	64e2                	ld	s1,24(sp)
    80002ef2:	6942                	ld	s2,16(sp)
    80002ef4:	69a2                	ld	s3,8(sp)
    80002ef6:	6a02                	ld	s4,0(sp)
    80002ef8:	6145                	addi	sp,sp,48
    80002efa:	8082                	ret

0000000080002efc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002efc:	7179                	addi	sp,sp,-48
    80002efe:	f406                	sd	ra,40(sp)
    80002f00:	f022                	sd	s0,32(sp)
    80002f02:	ec26                	sd	s1,24(sp)
    80002f04:	e84a                	sd	s2,16(sp)
    80002f06:	e44e                	sd	s3,8(sp)
    80002f08:	1800                	addi	s0,sp,48
    80002f0a:	89aa                	mv	s3,a0
    80002f0c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f0e:	0001b517          	auipc	a0,0x1b
    80002f12:	1da50513          	addi	a0,a0,474 # 8001e0e8 <bcache>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	cce080e7          	jalr	-818(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f1e:	00023497          	auipc	s1,0x23
    80002f22:	4824b483          	ld	s1,1154(s1) # 800263a0 <bcache+0x82b8>
    80002f26:	00023797          	auipc	a5,0x23
    80002f2a:	42a78793          	addi	a5,a5,1066 # 80026350 <bcache+0x8268>
    80002f2e:	02f48f63          	beq	s1,a5,80002f6c <bread+0x70>
    80002f32:	873e                	mv	a4,a5
    80002f34:	a021                	j	80002f3c <bread+0x40>
    80002f36:	68a4                	ld	s1,80(s1)
    80002f38:	02e48a63          	beq	s1,a4,80002f6c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f3c:	449c                	lw	a5,8(s1)
    80002f3e:	ff379ce3          	bne	a5,s3,80002f36 <bread+0x3a>
    80002f42:	44dc                	lw	a5,12(s1)
    80002f44:	ff2799e3          	bne	a5,s2,80002f36 <bread+0x3a>
      b->refcnt++;
    80002f48:	40bc                	lw	a5,64(s1)
    80002f4a:	2785                	addiw	a5,a5,1
    80002f4c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4e:	0001b517          	auipc	a0,0x1b
    80002f52:	19a50513          	addi	a0,a0,410 # 8001e0e8 <bcache>
    80002f56:	ffffe097          	auipc	ra,0xffffe
    80002f5a:	d42080e7          	jalr	-702(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f5e:	01048513          	addi	a0,s1,16
    80002f62:	00001097          	auipc	ra,0x1
    80002f66:	478080e7          	jalr	1144(ra) # 800043da <acquiresleep>
      return b;
    80002f6a:	a8b9                	j	80002fc8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f6c:	00023497          	auipc	s1,0x23
    80002f70:	42c4b483          	ld	s1,1068(s1) # 80026398 <bcache+0x82b0>
    80002f74:	00023797          	auipc	a5,0x23
    80002f78:	3dc78793          	addi	a5,a5,988 # 80026350 <bcache+0x8268>
    80002f7c:	00f48863          	beq	s1,a5,80002f8c <bread+0x90>
    80002f80:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f82:	40bc                	lw	a5,64(s1)
    80002f84:	cf81                	beqz	a5,80002f9c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f86:	64a4                	ld	s1,72(s1)
    80002f88:	fee49de3          	bne	s1,a4,80002f82 <bread+0x86>
  panic("bget: no buffers");
    80002f8c:	00009517          	auipc	a0,0x9
    80002f90:	74c50513          	addi	a0,a0,1868 # 8000c6d8 <syscalls+0xc0>
    80002f94:	ffffd097          	auipc	ra,0xffffd
    80002f98:	5aa080e7          	jalr	1450(ra) # 8000053e <panic>
      b->dev = dev;
    80002f9c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fa0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fa4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fa8:	4785                	li	a5,1
    80002faa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fac:	0001b517          	auipc	a0,0x1b
    80002fb0:	13c50513          	addi	a0,a0,316 # 8001e0e8 <bcache>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fbc:	01048513          	addi	a0,s1,16
    80002fc0:	00001097          	auipc	ra,0x1
    80002fc4:	41a080e7          	jalr	1050(ra) # 800043da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fc8:	409c                	lw	a5,0(s1)
    80002fca:	cb89                	beqz	a5,80002fdc <bread+0xe0>
    virtio_disk_rw(b, 0);

    b->valid = 1;
  }
  return b;
}
    80002fcc:	8526                	mv	a0,s1
    80002fce:	70a2                	ld	ra,40(sp)
    80002fd0:	7402                	ld	s0,32(sp)
    80002fd2:	64e2                	ld	s1,24(sp)
    80002fd4:	6942                	ld	s2,16(sp)
    80002fd6:	69a2                	ld	s3,8(sp)
    80002fd8:	6145                	addi	sp,sp,48
    80002fda:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fdc:	4581                	li	a1,0
    80002fde:	8526                	mv	a0,s1
    80002fe0:	00003097          	auipc	ra,0x3
    80002fe4:	f66080e7          	jalr	-154(ra) # 80005f46 <virtio_disk_rw>
    b->valid = 1;
    80002fe8:	4785                	li	a5,1
    80002fea:	c09c                	sw	a5,0(s1)
  return b;
    80002fec:	b7c5                	j	80002fcc <bread+0xd0>

0000000080002fee <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fee:	1101                	addi	sp,sp,-32
    80002ff0:	ec06                	sd	ra,24(sp)
    80002ff2:	e822                	sd	s0,16(sp)
    80002ff4:	e426                	sd	s1,8(sp)
    80002ff6:	1000                	addi	s0,sp,32
    80002ff8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ffa:	0541                	addi	a0,a0,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	478080e7          	jalr	1144(ra) # 80004474 <holdingsleep>
    80003004:	cd01                	beqz	a0,8000301c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003006:	4585                	li	a1,1
    80003008:	8526                	mv	a0,s1
    8000300a:	00003097          	auipc	ra,0x3
    8000300e:	f3c080e7          	jalr	-196(ra) # 80005f46 <virtio_disk_rw>
}
    80003012:	60e2                	ld	ra,24(sp)
    80003014:	6442                	ld	s0,16(sp)
    80003016:	64a2                	ld	s1,8(sp)
    80003018:	6105                	addi	sp,sp,32
    8000301a:	8082                	ret
    panic("bwrite");
    8000301c:	00009517          	auipc	a0,0x9
    80003020:	6d450513          	addi	a0,a0,1748 # 8000c6f0 <syscalls+0xd8>
    80003024:	ffffd097          	auipc	ra,0xffffd
    80003028:	51a080e7          	jalr	1306(ra) # 8000053e <panic>

000000008000302c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000302c:	1101                	addi	sp,sp,-32
    8000302e:	ec06                	sd	ra,24(sp)
    80003030:	e822                	sd	s0,16(sp)
    80003032:	e426                	sd	s1,8(sp)
    80003034:	e04a                	sd	s2,0(sp)
    80003036:	1000                	addi	s0,sp,32
    80003038:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303a:	01050913          	addi	s2,a0,16
    8000303e:	854a                	mv	a0,s2
    80003040:	00001097          	auipc	ra,0x1
    80003044:	434080e7          	jalr	1076(ra) # 80004474 <holdingsleep>
    80003048:	c92d                	beqz	a0,800030ba <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000304a:	854a                	mv	a0,s2
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	3e4080e7          	jalr	996(ra) # 80004430 <releasesleep>

  acquire(&bcache.lock);
    80003054:	0001b517          	auipc	a0,0x1b
    80003058:	09450513          	addi	a0,a0,148 # 8001e0e8 <bcache>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	b88080e7          	jalr	-1144(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	37fd                	addiw	a5,a5,-1
    80003068:	0007871b          	sext.w	a4,a5
    8000306c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000306e:	eb05                	bnez	a4,8000309e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003070:	68bc                	ld	a5,80(s1)
    80003072:	64b8                	ld	a4,72(s1)
    80003074:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003076:	64bc                	ld	a5,72(s1)
    80003078:	68b8                	ld	a4,80(s1)
    8000307a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000307c:	00023797          	auipc	a5,0x23
    80003080:	06c78793          	addi	a5,a5,108 # 800260e8 <bcache+0x8000>
    80003084:	2b87b703          	ld	a4,696(a5)
    80003088:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000308a:	00023717          	auipc	a4,0x23
    8000308e:	2c670713          	addi	a4,a4,710 # 80026350 <bcache+0x8268>
    80003092:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003094:	2b87b703          	ld	a4,696(a5)
    80003098:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000309a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000309e:	0001b517          	auipc	a0,0x1b
    800030a2:	04a50513          	addi	a0,a0,74 # 8001e0e8 <bcache>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	bf2080e7          	jalr	-1038(ra) # 80000c98 <release>
}
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6902                	ld	s2,0(sp)
    800030b6:	6105                	addi	sp,sp,32
    800030b8:	8082                	ret
    panic("brelse");
    800030ba:	00009517          	auipc	a0,0x9
    800030be:	63e50513          	addi	a0,a0,1598 # 8000c6f8 <syscalls+0xe0>
    800030c2:	ffffd097          	auipc	ra,0xffffd
    800030c6:	47c080e7          	jalr	1148(ra) # 8000053e <panic>

00000000800030ca <bpin>:

void
bpin(struct buf *b) {
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d6:	0001b517          	auipc	a0,0x1b
    800030da:	01250513          	addi	a0,a0,18 # 8001e0e8 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	b06080e7          	jalr	-1274(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030e6:	40bc                	lw	a5,64(s1)
    800030e8:	2785                	addiw	a5,a5,1
    800030ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ec:	0001b517          	auipc	a0,0x1b
    800030f0:	ffc50513          	addi	a0,a0,-4 # 8001e0e8 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	ba4080e7          	jalr	-1116(ra) # 80000c98 <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <bunpin>:

void
bunpin(struct buf *b) {
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003112:	0001b517          	auipc	a0,0x1b
    80003116:	fd650513          	addi	a0,a0,-42 # 8001e0e8 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	aca080e7          	jalr	-1334(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	37fd                	addiw	a5,a5,-1
    80003126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003128:	0001b517          	auipc	a0,0x1b
    8000312c:	fc050513          	addi	a0,a0,-64 # 8001e0e8 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	e04a                	sd	s2,0(sp)
    8000314c:	1000                	addi	s0,sp,32
    8000314e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003150:	00d5d59b          	srliw	a1,a1,0xd
    80003154:	00023797          	auipc	a5,0x23
    80003158:	6707a783          	lw	a5,1648(a5) # 800267c4 <sb+0x1c>
    8000315c:	9dbd                	addw	a1,a1,a5
    8000315e:	00000097          	auipc	ra,0x0
    80003162:	d9e080e7          	jalr	-610(ra) # 80002efc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003166:	0074f713          	andi	a4,s1,7
    8000316a:	4785                	li	a5,1
    8000316c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003170:	14ce                	slli	s1,s1,0x33
    80003172:	90d9                	srli	s1,s1,0x36
    80003174:	00950733          	add	a4,a0,s1
    80003178:	05874703          	lbu	a4,88(a4)
    8000317c:	00e7f6b3          	and	a3,a5,a4
    80003180:	c69d                	beqz	a3,800031ae <bfree+0x6c>
    80003182:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003184:	94aa                	add	s1,s1,a0
    80003186:	fff7c793          	not	a5,a5
    8000318a:	8ff9                	and	a5,a5,a4
    8000318c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003190:	00001097          	auipc	ra,0x1
    80003194:	12a080e7          	jalr	298(ra) # 800042ba <log_write>
  brelse(bp);
    80003198:	854a                	mv	a0,s2
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	e92080e7          	jalr	-366(ra) # 8000302c <brelse>
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6902                	ld	s2,0(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret
    panic("freeing free block");
    800031ae:	00009517          	auipc	a0,0x9
    800031b2:	55250513          	addi	a0,a0,1362 # 8000c700 <syscalls+0xe8>
    800031b6:	ffffd097          	auipc	ra,0xffffd
    800031ba:	388080e7          	jalr	904(ra) # 8000053e <panic>

00000000800031be <balloc>:
{
    800031be:	711d                	addi	sp,sp,-96
    800031c0:	ec86                	sd	ra,88(sp)
    800031c2:	e8a2                	sd	s0,80(sp)
    800031c4:	e4a6                	sd	s1,72(sp)
    800031c6:	e0ca                	sd	s2,64(sp)
    800031c8:	fc4e                	sd	s3,56(sp)
    800031ca:	f852                	sd	s4,48(sp)
    800031cc:	f456                	sd	s5,40(sp)
    800031ce:	f05a                	sd	s6,32(sp)
    800031d0:	ec5e                	sd	s7,24(sp)
    800031d2:	e862                	sd	s8,16(sp)
    800031d4:	e466                	sd	s9,8(sp)
    800031d6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031d8:	00023797          	auipc	a5,0x23
    800031dc:	5d47a783          	lw	a5,1492(a5) # 800267ac <sb+0x4>
    800031e0:	cbd1                	beqz	a5,80003274 <balloc+0xb6>
    800031e2:	8baa                	mv	s7,a0
    800031e4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031e6:	00023b17          	auipc	s6,0x23
    800031ea:	5c2b0b13          	addi	s6,s6,1474 # 800267a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ee:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031f0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031f4:	6c89                	lui	s9,0x2
    800031f6:	a831                	j	80003212 <balloc+0x54>
    brelse(bp);
    800031f8:	854a                	mv	a0,s2
    800031fa:	00000097          	auipc	ra,0x0
    800031fe:	e32080e7          	jalr	-462(ra) # 8000302c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003202:	015c87bb          	addw	a5,s9,s5
    80003206:	00078a9b          	sext.w	s5,a5
    8000320a:	004b2703          	lw	a4,4(s6)
    8000320e:	06eaf363          	bgeu	s5,a4,80003274 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003212:	41fad79b          	sraiw	a5,s5,0x1f
    80003216:	0137d79b          	srliw	a5,a5,0x13
    8000321a:	015787bb          	addw	a5,a5,s5
    8000321e:	40d7d79b          	sraiw	a5,a5,0xd
    80003222:	01cb2583          	lw	a1,28(s6)
    80003226:	9dbd                	addw	a1,a1,a5
    80003228:	855e                	mv	a0,s7
    8000322a:	00000097          	auipc	ra,0x0
    8000322e:	cd2080e7          	jalr	-814(ra) # 80002efc <bread>
    80003232:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003234:	004b2503          	lw	a0,4(s6)
    80003238:	000a849b          	sext.w	s1,s5
    8000323c:	8662                	mv	a2,s8
    8000323e:	faa4fde3          	bgeu	s1,a0,800031f8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003242:	41f6579b          	sraiw	a5,a2,0x1f
    80003246:	01d7d69b          	srliw	a3,a5,0x1d
    8000324a:	00c6873b          	addw	a4,a3,a2
    8000324e:	00777793          	andi	a5,a4,7
    80003252:	9f95                	subw	a5,a5,a3
    80003254:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003258:	4037571b          	sraiw	a4,a4,0x3
    8000325c:	00e906b3          	add	a3,s2,a4
    80003260:	0586c683          	lbu	a3,88(a3)
    80003264:	00d7f5b3          	and	a1,a5,a3
    80003268:	cd91                	beqz	a1,80003284 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326a:	2605                	addiw	a2,a2,1
    8000326c:	2485                	addiw	s1,s1,1
    8000326e:	fd4618e3          	bne	a2,s4,8000323e <balloc+0x80>
    80003272:	b759                	j	800031f8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003274:	00009517          	auipc	a0,0x9
    80003278:	4a450513          	addi	a0,a0,1188 # 8000c718 <syscalls+0x100>
    8000327c:	ffffd097          	auipc	ra,0xffffd
    80003280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003284:	974a                	add	a4,a4,s2
    80003286:	8fd5                	or	a5,a5,a3
    80003288:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000328c:	854a                	mv	a0,s2
    8000328e:	00001097          	auipc	ra,0x1
    80003292:	02c080e7          	jalr	44(ra) # 800042ba <log_write>
        brelse(bp);
    80003296:	854a                	mv	a0,s2
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	d94080e7          	jalr	-620(ra) # 8000302c <brelse>
  bp = bread(dev, bno);
    800032a0:	85a6                	mv	a1,s1
    800032a2:	855e                	mv	a0,s7
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	c58080e7          	jalr	-936(ra) # 80002efc <bread>
    800032ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ae:	40000613          	li	a2,1024
    800032b2:	4581                	li	a1,0
    800032b4:	05850513          	addi	a0,a0,88
    800032b8:	ffffe097          	auipc	ra,0xffffe
    800032bc:	a28080e7          	jalr	-1496(ra) # 80000ce0 <memset>
  log_write(bp);
    800032c0:	854a                	mv	a0,s2
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	ff8080e7          	jalr	-8(ra) # 800042ba <log_write>
  brelse(bp);
    800032ca:	854a                	mv	a0,s2
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	d60080e7          	jalr	-672(ra) # 8000302c <brelse>
}
    800032d4:	8526                	mv	a0,s1
    800032d6:	60e6                	ld	ra,88(sp)
    800032d8:	6446                	ld	s0,80(sp)
    800032da:	64a6                	ld	s1,72(sp)
    800032dc:	6906                	ld	s2,64(sp)
    800032de:	79e2                	ld	s3,56(sp)
    800032e0:	7a42                	ld	s4,48(sp)
    800032e2:	7aa2                	ld	s5,40(sp)
    800032e4:	7b02                	ld	s6,32(sp)
    800032e6:	6be2                	ld	s7,24(sp)
    800032e8:	6c42                	ld	s8,16(sp)
    800032ea:	6ca2                	ld	s9,8(sp)
    800032ec:	6125                	addi	sp,sp,96
    800032ee:	8082                	ret

00000000800032f0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032f0:	7179                	addi	sp,sp,-48
    800032f2:	f406                	sd	ra,40(sp)
    800032f4:	f022                	sd	s0,32(sp)
    800032f6:	ec26                	sd	s1,24(sp)
    800032f8:	e84a                	sd	s2,16(sp)
    800032fa:	e44e                	sd	s3,8(sp)
    800032fc:	e052                	sd	s4,0(sp)
    800032fe:	1800                	addi	s0,sp,48
    80003300:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003302:	47ad                	li	a5,11
    80003304:	04b7fe63          	bgeu	a5,a1,80003360 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003308:	ff45849b          	addiw	s1,a1,-12
    8000330c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003310:	0ff00793          	li	a5,255
    80003314:	0ae7e363          	bltu	a5,a4,800033ba <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003318:	08052583          	lw	a1,128(a0)
    8000331c:	c5ad                	beqz	a1,80003386 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000331e:	00092503          	lw	a0,0(s2)
    80003322:	00000097          	auipc	ra,0x0
    80003326:	bda080e7          	jalr	-1062(ra) # 80002efc <bread>
    8000332a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000332c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003330:	02049593          	slli	a1,s1,0x20
    80003334:	9181                	srli	a1,a1,0x20
    80003336:	058a                	slli	a1,a1,0x2
    80003338:	00b784b3          	add	s1,a5,a1
    8000333c:	0004a983          	lw	s3,0(s1)
    80003340:	04098d63          	beqz	s3,8000339a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003344:	8552                	mv	a0,s4
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	ce6080e7          	jalr	-794(ra) # 8000302c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000334e:	854e                	mv	a0,s3
    80003350:	70a2                	ld	ra,40(sp)
    80003352:	7402                	ld	s0,32(sp)
    80003354:	64e2                	ld	s1,24(sp)
    80003356:	6942                	ld	s2,16(sp)
    80003358:	69a2                	ld	s3,8(sp)
    8000335a:	6a02                	ld	s4,0(sp)
    8000335c:	6145                	addi	sp,sp,48
    8000335e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003360:	02059493          	slli	s1,a1,0x20
    80003364:	9081                	srli	s1,s1,0x20
    80003366:	048a                	slli	s1,s1,0x2
    80003368:	94aa                	add	s1,s1,a0
    8000336a:	0504a983          	lw	s3,80(s1)
    8000336e:	fe0990e3          	bnez	s3,8000334e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003372:	4108                	lw	a0,0(a0)
    80003374:	00000097          	auipc	ra,0x0
    80003378:	e4a080e7          	jalr	-438(ra) # 800031be <balloc>
    8000337c:	0005099b          	sext.w	s3,a0
    80003380:	0534a823          	sw	s3,80(s1)
    80003384:	b7e9                	j	8000334e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003386:	4108                	lw	a0,0(a0)
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	e36080e7          	jalr	-458(ra) # 800031be <balloc>
    80003390:	0005059b          	sext.w	a1,a0
    80003394:	08b92023          	sw	a1,128(s2)
    80003398:	b759                	j	8000331e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000339a:	00092503          	lw	a0,0(s2)
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	e20080e7          	jalr	-480(ra) # 800031be <balloc>
    800033a6:	0005099b          	sext.w	s3,a0
    800033aa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ae:	8552                	mv	a0,s4
    800033b0:	00001097          	auipc	ra,0x1
    800033b4:	f0a080e7          	jalr	-246(ra) # 800042ba <log_write>
    800033b8:	b771                	j	80003344 <bmap+0x54>
  panic("bmap: out of range");
    800033ba:	00009517          	auipc	a0,0x9
    800033be:	37650513          	addi	a0,a0,886 # 8000c730 <syscalls+0x118>
    800033c2:	ffffd097          	auipc	ra,0xffffd
    800033c6:	17c080e7          	jalr	380(ra) # 8000053e <panic>

00000000800033ca <iget>:
{
    800033ca:	7179                	addi	sp,sp,-48
    800033cc:	f406                	sd	ra,40(sp)
    800033ce:	f022                	sd	s0,32(sp)
    800033d0:	ec26                	sd	s1,24(sp)
    800033d2:	e84a                	sd	s2,16(sp)
    800033d4:	e44e                	sd	s3,8(sp)
    800033d6:	e052                	sd	s4,0(sp)
    800033d8:	1800                	addi	s0,sp,48
    800033da:	89aa                	mv	s3,a0
    800033dc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033de:	00023517          	auipc	a0,0x23
    800033e2:	3ea50513          	addi	a0,a0,1002 # 800267c8 <itable>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	7fe080e7          	jalr	2046(ra) # 80000be4 <acquire>
  empty = 0;
    800033ee:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033f0:	00023497          	auipc	s1,0x23
    800033f4:	3f048493          	addi	s1,s1,1008 # 800267e0 <itable+0x18>
    800033f8:	00025697          	auipc	a3,0x25
    800033fc:	e7868693          	addi	a3,a3,-392 # 80028270 <log>
    80003400:	a039                	j	8000340e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003402:	02090b63          	beqz	s2,80003438 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003406:	08848493          	addi	s1,s1,136
    8000340a:	02d48a63          	beq	s1,a3,8000343e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000340e:	449c                	lw	a5,8(s1)
    80003410:	fef059e3          	blez	a5,80003402 <iget+0x38>
    80003414:	4098                	lw	a4,0(s1)
    80003416:	ff3716e3          	bne	a4,s3,80003402 <iget+0x38>
    8000341a:	40d8                	lw	a4,4(s1)
    8000341c:	ff4713e3          	bne	a4,s4,80003402 <iget+0x38>
      ip->ref++;
    80003420:	2785                	addiw	a5,a5,1
    80003422:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003424:	00023517          	auipc	a0,0x23
    80003428:	3a450513          	addi	a0,a0,932 # 800267c8 <itable>
    8000342c:	ffffe097          	auipc	ra,0xffffe
    80003430:	86c080e7          	jalr	-1940(ra) # 80000c98 <release>
      return ip;
    80003434:	8926                	mv	s2,s1
    80003436:	a03d                	j	80003464 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003438:	f7f9                	bnez	a5,80003406 <iget+0x3c>
    8000343a:	8926                	mv	s2,s1
    8000343c:	b7e9                	j	80003406 <iget+0x3c>
  if(empty == 0)
    8000343e:	02090c63          	beqz	s2,80003476 <iget+0xac>
  ip->dev = dev;
    80003442:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003446:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000344a:	4785                	li	a5,1
    8000344c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003450:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003454:	00023517          	auipc	a0,0x23
    80003458:	37450513          	addi	a0,a0,884 # 800267c8 <itable>
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	83c080e7          	jalr	-1988(ra) # 80000c98 <release>
}
    80003464:	854a                	mv	a0,s2
    80003466:	70a2                	ld	ra,40(sp)
    80003468:	7402                	ld	s0,32(sp)
    8000346a:	64e2                	ld	s1,24(sp)
    8000346c:	6942                	ld	s2,16(sp)
    8000346e:	69a2                	ld	s3,8(sp)
    80003470:	6a02                	ld	s4,0(sp)
    80003472:	6145                	addi	sp,sp,48
    80003474:	8082                	ret
    panic("iget: no inodes");
    80003476:	00009517          	auipc	a0,0x9
    8000347a:	2d250513          	addi	a0,a0,722 # 8000c748 <syscalls+0x130>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	0c0080e7          	jalr	192(ra) # 8000053e <panic>

0000000080003486 <fsinit>:
fsinit(int dev) {
    80003486:	7179                	addi	sp,sp,-48
    80003488:	f406                	sd	ra,40(sp)
    8000348a:	f022                	sd	s0,32(sp)
    8000348c:	ec26                	sd	s1,24(sp)
    8000348e:	e84a                	sd	s2,16(sp)
    80003490:	e44e                	sd	s3,8(sp)
    80003492:	1800                	addi	s0,sp,48
    80003494:	892a                	mv	s2,a0
  printf("fsinit \n");
    80003496:	00009517          	auipc	a0,0x9
    8000349a:	2c250513          	addi	a0,a0,706 # 8000c758 <syscalls+0x140>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	0ea080e7          	jalr	234(ra) # 80000588 <printf>
  bp = bread(dev, 1);
    800034a6:	4585                	li	a1,1
    800034a8:	854a                	mv	a0,s2
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	a52080e7          	jalr	-1454(ra) # 80002efc <bread>
    800034b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034b4:	00023997          	auipc	s3,0x23
    800034b8:	2f498993          	addi	s3,s3,756 # 800267a8 <sb>
    800034bc:	02000613          	li	a2,32
    800034c0:	05850593          	addi	a1,a0,88
    800034c4:	854e                	mv	a0,s3
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	87a080e7          	jalr	-1926(ra) # 80000d40 <memmove>
  brelse(bp);
    800034ce:	8526                	mv	a0,s1
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	b5c080e7          	jalr	-1188(ra) # 8000302c <brelse>
  if(sb.magic != FSMAGIC)
    800034d8:	0009a703          	lw	a4,0(s3)
    800034dc:	102037b7          	lui	a5,0x10203
    800034e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034e4:	02f71263          	bne	a4,a5,80003508 <fsinit+0x82>
  initlog(dev, &sb);
    800034e8:	00023597          	auipc	a1,0x23
    800034ec:	2c058593          	addi	a1,a1,704 # 800267a8 <sb>
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	b4c080e7          	jalr	-1204(ra) # 8000403e <initlog>
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6145                	addi	sp,sp,48
    80003506:	8082                	ret
    panic("invalid file system");
    80003508:	00009517          	auipc	a0,0x9
    8000350c:	26050513          	addi	a0,a0,608 # 8000c768 <syscalls+0x150>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	02e080e7          	jalr	46(ra) # 8000053e <panic>

0000000080003518 <iinit>:
{
    80003518:	7179                	addi	sp,sp,-48
    8000351a:	f406                	sd	ra,40(sp)
    8000351c:	f022                	sd	s0,32(sp)
    8000351e:	ec26                	sd	s1,24(sp)
    80003520:	e84a                	sd	s2,16(sp)
    80003522:	e44e                	sd	s3,8(sp)
    80003524:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003526:	00009597          	auipc	a1,0x9
    8000352a:	25a58593          	addi	a1,a1,602 # 8000c780 <syscalls+0x168>
    8000352e:	00023517          	auipc	a0,0x23
    80003532:	29a50513          	addi	a0,a0,666 # 800267c8 <itable>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	61e080e7          	jalr	1566(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000353e:	00023497          	auipc	s1,0x23
    80003542:	2b248493          	addi	s1,s1,690 # 800267f0 <itable+0x28>
    80003546:	00025997          	auipc	s3,0x25
    8000354a:	d3a98993          	addi	s3,s3,-710 # 80028280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000354e:	00009917          	auipc	s2,0x9
    80003552:	23a90913          	addi	s2,s2,570 # 8000c788 <syscalls+0x170>
    80003556:	85ca                	mv	a1,s2
    80003558:	8526                	mv	a0,s1
    8000355a:	00001097          	auipc	ra,0x1
    8000355e:	e46080e7          	jalr	-442(ra) # 800043a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003562:	08848493          	addi	s1,s1,136
    80003566:	ff3498e3          	bne	s1,s3,80003556 <iinit+0x3e>
}
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6145                	addi	sp,sp,48
    80003576:	8082                	ret

0000000080003578 <ialloc>:
{
    80003578:	715d                	addi	sp,sp,-80
    8000357a:	e486                	sd	ra,72(sp)
    8000357c:	e0a2                	sd	s0,64(sp)
    8000357e:	fc26                	sd	s1,56(sp)
    80003580:	f84a                	sd	s2,48(sp)
    80003582:	f44e                	sd	s3,40(sp)
    80003584:	f052                	sd	s4,32(sp)
    80003586:	ec56                	sd	s5,24(sp)
    80003588:	e85a                	sd	s6,16(sp)
    8000358a:	e45e                	sd	s7,8(sp)
    8000358c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000358e:	00023717          	auipc	a4,0x23
    80003592:	22672703          	lw	a4,550(a4) # 800267b4 <sb+0xc>
    80003596:	4785                	li	a5,1
    80003598:	04e7fa63          	bgeu	a5,a4,800035ec <ialloc+0x74>
    8000359c:	8aaa                	mv	s5,a0
    8000359e:	8bae                	mv	s7,a1
    800035a0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035a2:	00023a17          	auipc	s4,0x23
    800035a6:	206a0a13          	addi	s4,s4,518 # 800267a8 <sb>
    800035aa:	00048b1b          	sext.w	s6,s1
    800035ae:	0044d593          	srli	a1,s1,0x4
    800035b2:	018a2783          	lw	a5,24(s4)
    800035b6:	9dbd                	addw	a1,a1,a5
    800035b8:	8556                	mv	a0,s5
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	942080e7          	jalr	-1726(ra) # 80002efc <bread>
    800035c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035c4:	05850993          	addi	s3,a0,88
    800035c8:	00f4f793          	andi	a5,s1,15
    800035cc:	079a                	slli	a5,a5,0x6
    800035ce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035d0:	00099783          	lh	a5,0(s3)
    800035d4:	c785                	beqz	a5,800035fc <ialloc+0x84>
    brelse(bp);
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	a56080e7          	jalr	-1450(ra) # 8000302c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035de:	0485                	addi	s1,s1,1
    800035e0:	00ca2703          	lw	a4,12(s4)
    800035e4:	0004879b          	sext.w	a5,s1
    800035e8:	fce7e1e3          	bltu	a5,a4,800035aa <ialloc+0x32>
  panic("ialloc: no inodes");
    800035ec:	00009517          	auipc	a0,0x9
    800035f0:	1a450513          	addi	a0,a0,420 # 8000c790 <syscalls+0x178>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	f4a080e7          	jalr	-182(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035fc:	04000613          	li	a2,64
    80003600:	4581                	li	a1,0
    80003602:	854e                	mv	a0,s3
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	6dc080e7          	jalr	1756(ra) # 80000ce0 <memset>
      dip->type = type;
    8000360c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003610:	854a                	mv	a0,s2
    80003612:	00001097          	auipc	ra,0x1
    80003616:	ca8080e7          	jalr	-856(ra) # 800042ba <log_write>
      brelse(bp);
    8000361a:	854a                	mv	a0,s2
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	a10080e7          	jalr	-1520(ra) # 8000302c <brelse>
      return iget(dev, inum);
    80003624:	85da                	mv	a1,s6
    80003626:	8556                	mv	a0,s5
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	da2080e7          	jalr	-606(ra) # 800033ca <iget>
}
    80003630:	60a6                	ld	ra,72(sp)
    80003632:	6406                	ld	s0,64(sp)
    80003634:	74e2                	ld	s1,56(sp)
    80003636:	7942                	ld	s2,48(sp)
    80003638:	79a2                	ld	s3,40(sp)
    8000363a:	7a02                	ld	s4,32(sp)
    8000363c:	6ae2                	ld	s5,24(sp)
    8000363e:	6b42                	ld	s6,16(sp)
    80003640:	6ba2                	ld	s7,8(sp)
    80003642:	6161                	addi	sp,sp,80
    80003644:	8082                	ret

0000000080003646 <iupdate>:
{
    80003646:	1101                	addi	sp,sp,-32
    80003648:	ec06                	sd	ra,24(sp)
    8000364a:	e822                	sd	s0,16(sp)
    8000364c:	e426                	sd	s1,8(sp)
    8000364e:	e04a                	sd	s2,0(sp)
    80003650:	1000                	addi	s0,sp,32
    80003652:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003654:	415c                	lw	a5,4(a0)
    80003656:	0047d79b          	srliw	a5,a5,0x4
    8000365a:	00023597          	auipc	a1,0x23
    8000365e:	1665a583          	lw	a1,358(a1) # 800267c0 <sb+0x18>
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	4108                	lw	a0,0(a0)
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	896080e7          	jalr	-1898(ra) # 80002efc <bread>
    8000366e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003670:	05850793          	addi	a5,a0,88
    80003674:	40c8                	lw	a0,4(s1)
    80003676:	893d                	andi	a0,a0,15
    80003678:	051a                	slli	a0,a0,0x6
    8000367a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000367c:	04449703          	lh	a4,68(s1)
    80003680:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003684:	04649703          	lh	a4,70(s1)
    80003688:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000368c:	04849703          	lh	a4,72(s1)
    80003690:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003694:	04a49703          	lh	a4,74(s1)
    80003698:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000369c:	44f8                	lw	a4,76(s1)
    8000369e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036a0:	03400613          	li	a2,52
    800036a4:	05048593          	addi	a1,s1,80
    800036a8:	0531                	addi	a0,a0,12
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	696080e7          	jalr	1686(ra) # 80000d40 <memmove>
  log_write(bp);
    800036b2:	854a                	mv	a0,s2
    800036b4:	00001097          	auipc	ra,0x1
    800036b8:	c06080e7          	jalr	-1018(ra) # 800042ba <log_write>
  brelse(bp);
    800036bc:	854a                	mv	a0,s2
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	96e080e7          	jalr	-1682(ra) # 8000302c <brelse>
}
    800036c6:	60e2                	ld	ra,24(sp)
    800036c8:	6442                	ld	s0,16(sp)
    800036ca:	64a2                	ld	s1,8(sp)
    800036cc:	6902                	ld	s2,0(sp)
    800036ce:	6105                	addi	sp,sp,32
    800036d0:	8082                	ret

00000000800036d2 <idup>:
{
    800036d2:	1101                	addi	sp,sp,-32
    800036d4:	ec06                	sd	ra,24(sp)
    800036d6:	e822                	sd	s0,16(sp)
    800036d8:	e426                	sd	s1,8(sp)
    800036da:	1000                	addi	s0,sp,32
    800036dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036de:	00023517          	auipc	a0,0x23
    800036e2:	0ea50513          	addi	a0,a0,234 # 800267c8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	4fe080e7          	jalr	1278(ra) # 80000be4 <acquire>
  ip->ref++;
    800036ee:	449c                	lw	a5,8(s1)
    800036f0:	2785                	addiw	a5,a5,1
    800036f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036f4:	00023517          	auipc	a0,0x23
    800036f8:	0d450513          	addi	a0,a0,212 # 800267c8 <itable>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	59c080e7          	jalr	1436(ra) # 80000c98 <release>
}
    80003704:	8526                	mv	a0,s1
    80003706:	60e2                	ld	ra,24(sp)
    80003708:	6442                	ld	s0,16(sp)
    8000370a:	64a2                	ld	s1,8(sp)
    8000370c:	6105                	addi	sp,sp,32
    8000370e:	8082                	ret

0000000080003710 <ilock>:
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	e04a                	sd	s2,0(sp)
    8000371a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000371c:	c115                	beqz	a0,80003740 <ilock+0x30>
    8000371e:	84aa                	mv	s1,a0
    80003720:	451c                	lw	a5,8(a0)
    80003722:	00f05f63          	blez	a5,80003740 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003726:	0541                	addi	a0,a0,16
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	cb2080e7          	jalr	-846(ra) # 800043da <acquiresleep>
  if(ip->valid == 0){
    80003730:	40bc                	lw	a5,64(s1)
    80003732:	cf99                	beqz	a5,80003750 <ilock+0x40>
}
    80003734:	60e2                	ld	ra,24(sp)
    80003736:	6442                	ld	s0,16(sp)
    80003738:	64a2                	ld	s1,8(sp)
    8000373a:	6902                	ld	s2,0(sp)
    8000373c:	6105                	addi	sp,sp,32
    8000373e:	8082                	ret
    panic("ilock");
    80003740:	00009517          	auipc	a0,0x9
    80003744:	06850513          	addi	a0,a0,104 # 8000c7a8 <syscalls+0x190>
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	df6080e7          	jalr	-522(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003750:	40dc                	lw	a5,4(s1)
    80003752:	0047d79b          	srliw	a5,a5,0x4
    80003756:	00023597          	auipc	a1,0x23
    8000375a:	06a5a583          	lw	a1,106(a1) # 800267c0 <sb+0x18>
    8000375e:	9dbd                	addw	a1,a1,a5
    80003760:	4088                	lw	a0,0(s1)
    80003762:	fffff097          	auipc	ra,0xfffff
    80003766:	79a080e7          	jalr	1946(ra) # 80002efc <bread>
    8000376a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000376c:	05850593          	addi	a1,a0,88
    80003770:	40dc                	lw	a5,4(s1)
    80003772:	8bbd                	andi	a5,a5,15
    80003774:	079a                	slli	a5,a5,0x6
    80003776:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003778:	00059783          	lh	a5,0(a1)
    8000377c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003780:	00259783          	lh	a5,2(a1)
    80003784:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003788:	00459783          	lh	a5,4(a1)
    8000378c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003790:	00659783          	lh	a5,6(a1)
    80003794:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003798:	459c                	lw	a5,8(a1)
    8000379a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000379c:	03400613          	li	a2,52
    800037a0:	05b1                	addi	a1,a1,12
    800037a2:	05048513          	addi	a0,s1,80
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	59a080e7          	jalr	1434(ra) # 80000d40 <memmove>
    brelse(bp);
    800037ae:	854a                	mv	a0,s2
    800037b0:	00000097          	auipc	ra,0x0
    800037b4:	87c080e7          	jalr	-1924(ra) # 8000302c <brelse>
    ip->valid = 1;
    800037b8:	4785                	li	a5,1
    800037ba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037bc:	04449783          	lh	a5,68(s1)
    800037c0:	fbb5                	bnez	a5,80003734 <ilock+0x24>
      panic("ilock: no type");
    800037c2:	00009517          	auipc	a0,0x9
    800037c6:	fee50513          	addi	a0,a0,-18 # 8000c7b0 <syscalls+0x198>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d74080e7          	jalr	-652(ra) # 8000053e <panic>

00000000800037d2 <iunlock>:
{
    800037d2:	1101                	addi	sp,sp,-32
    800037d4:	ec06                	sd	ra,24(sp)
    800037d6:	e822                	sd	s0,16(sp)
    800037d8:	e426                	sd	s1,8(sp)
    800037da:	e04a                	sd	s2,0(sp)
    800037dc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037de:	c905                	beqz	a0,8000380e <iunlock+0x3c>
    800037e0:	84aa                	mv	s1,a0
    800037e2:	01050913          	addi	s2,a0,16
    800037e6:	854a                	mv	a0,s2
    800037e8:	00001097          	auipc	ra,0x1
    800037ec:	c8c080e7          	jalr	-884(ra) # 80004474 <holdingsleep>
    800037f0:	cd19                	beqz	a0,8000380e <iunlock+0x3c>
    800037f2:	449c                	lw	a5,8(s1)
    800037f4:	00f05d63          	blez	a5,8000380e <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037f8:	854a                	mv	a0,s2
    800037fa:	00001097          	auipc	ra,0x1
    800037fe:	c36080e7          	jalr	-970(ra) # 80004430 <releasesleep>
}
    80003802:	60e2                	ld	ra,24(sp)
    80003804:	6442                	ld	s0,16(sp)
    80003806:	64a2                	ld	s1,8(sp)
    80003808:	6902                	ld	s2,0(sp)
    8000380a:	6105                	addi	sp,sp,32
    8000380c:	8082                	ret
    panic("iunlock");
    8000380e:	00009517          	auipc	a0,0x9
    80003812:	fb250513          	addi	a0,a0,-78 # 8000c7c0 <syscalls+0x1a8>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d28080e7          	jalr	-728(ra) # 8000053e <panic>

000000008000381e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000381e:	7179                	addi	sp,sp,-48
    80003820:	f406                	sd	ra,40(sp)
    80003822:	f022                	sd	s0,32(sp)
    80003824:	ec26                	sd	s1,24(sp)
    80003826:	e84a                	sd	s2,16(sp)
    80003828:	e44e                	sd	s3,8(sp)
    8000382a:	e052                	sd	s4,0(sp)
    8000382c:	1800                	addi	s0,sp,48
    8000382e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003830:	05050493          	addi	s1,a0,80
    80003834:	08050913          	addi	s2,a0,128
    80003838:	a021                	j	80003840 <itrunc+0x22>
    8000383a:	0491                	addi	s1,s1,4
    8000383c:	01248d63          	beq	s1,s2,80003856 <itrunc+0x38>
    if(ip->addrs[i]){
    80003840:	408c                	lw	a1,0(s1)
    80003842:	dde5                	beqz	a1,8000383a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003844:	0009a503          	lw	a0,0(s3)
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	8fa080e7          	jalr	-1798(ra) # 80003142 <bfree>
      ip->addrs[i] = 0;
    80003850:	0004a023          	sw	zero,0(s1)
    80003854:	b7dd                	j	8000383a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003856:	0809a583          	lw	a1,128(s3)
    8000385a:	e185                	bnez	a1,8000387a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000385c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003860:	854e                	mv	a0,s3
    80003862:	00000097          	auipc	ra,0x0
    80003866:	de4080e7          	jalr	-540(ra) # 80003646 <iupdate>
}
    8000386a:	70a2                	ld	ra,40(sp)
    8000386c:	7402                	ld	s0,32(sp)
    8000386e:	64e2                	ld	s1,24(sp)
    80003870:	6942                	ld	s2,16(sp)
    80003872:	69a2                	ld	s3,8(sp)
    80003874:	6a02                	ld	s4,0(sp)
    80003876:	6145                	addi	sp,sp,48
    80003878:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000387a:	0009a503          	lw	a0,0(s3)
    8000387e:	fffff097          	auipc	ra,0xfffff
    80003882:	67e080e7          	jalr	1662(ra) # 80002efc <bread>
    80003886:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003888:	05850493          	addi	s1,a0,88
    8000388c:	45850913          	addi	s2,a0,1112
    80003890:	a811                	j	800038a4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003892:	0009a503          	lw	a0,0(s3)
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	8ac080e7          	jalr	-1876(ra) # 80003142 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000389e:	0491                	addi	s1,s1,4
    800038a0:	01248563          	beq	s1,s2,800038aa <itrunc+0x8c>
      if(a[j])
    800038a4:	408c                	lw	a1,0(s1)
    800038a6:	dde5                	beqz	a1,8000389e <itrunc+0x80>
    800038a8:	b7ed                	j	80003892 <itrunc+0x74>
    brelse(bp);
    800038aa:	8552                	mv	a0,s4
    800038ac:	fffff097          	auipc	ra,0xfffff
    800038b0:	780080e7          	jalr	1920(ra) # 8000302c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038b4:	0809a583          	lw	a1,128(s3)
    800038b8:	0009a503          	lw	a0,0(s3)
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	886080e7          	jalr	-1914(ra) # 80003142 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038c4:	0809a023          	sw	zero,128(s3)
    800038c8:	bf51                	j	8000385c <itrunc+0x3e>

00000000800038ca <iput>:
{
    800038ca:	1101                	addi	sp,sp,-32
    800038cc:	ec06                	sd	ra,24(sp)
    800038ce:	e822                	sd	s0,16(sp)
    800038d0:	e426                	sd	s1,8(sp)
    800038d2:	e04a                	sd	s2,0(sp)
    800038d4:	1000                	addi	s0,sp,32
    800038d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038d8:	00023517          	auipc	a0,0x23
    800038dc:	ef050513          	addi	a0,a0,-272 # 800267c8 <itable>
    800038e0:	ffffd097          	auipc	ra,0xffffd
    800038e4:	304080e7          	jalr	772(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e8:	4498                	lw	a4,8(s1)
    800038ea:	4785                	li	a5,1
    800038ec:	02f70363          	beq	a4,a5,80003912 <iput+0x48>
  ip->ref--;
    800038f0:	449c                	lw	a5,8(s1)
    800038f2:	37fd                	addiw	a5,a5,-1
    800038f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038f6:	00023517          	auipc	a0,0x23
    800038fa:	ed250513          	addi	a0,a0,-302 # 800267c8 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	39a080e7          	jalr	922(ra) # 80000c98 <release>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6902                	ld	s2,0(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003912:	40bc                	lw	a5,64(s1)
    80003914:	dff1                	beqz	a5,800038f0 <iput+0x26>
    80003916:	04a49783          	lh	a5,74(s1)
    8000391a:	fbf9                	bnez	a5,800038f0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000391c:	01048913          	addi	s2,s1,16
    80003920:	854a                	mv	a0,s2
    80003922:	00001097          	auipc	ra,0x1
    80003926:	ab8080e7          	jalr	-1352(ra) # 800043da <acquiresleep>
    release(&itable.lock);
    8000392a:	00023517          	auipc	a0,0x23
    8000392e:	e9e50513          	addi	a0,a0,-354 # 800267c8 <itable>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	366080e7          	jalr	870(ra) # 80000c98 <release>
    itrunc(ip);
    8000393a:	8526                	mv	a0,s1
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	ee2080e7          	jalr	-286(ra) # 8000381e <itrunc>
    ip->type = 0;
    80003944:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003948:	8526                	mv	a0,s1
    8000394a:	00000097          	auipc	ra,0x0
    8000394e:	cfc080e7          	jalr	-772(ra) # 80003646 <iupdate>
    ip->valid = 0;
    80003952:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	ad8080e7          	jalr	-1320(ra) # 80004430 <releasesleep>
    acquire(&itable.lock);
    80003960:	00023517          	auipc	a0,0x23
    80003964:	e6850513          	addi	a0,a0,-408 # 800267c8 <itable>
    80003968:	ffffd097          	auipc	ra,0xffffd
    8000396c:	27c080e7          	jalr	636(ra) # 80000be4 <acquire>
    80003970:	b741                	j	800038f0 <iput+0x26>

0000000080003972 <iunlockput>:
{
    80003972:	1101                	addi	sp,sp,-32
    80003974:	ec06                	sd	ra,24(sp)
    80003976:	e822                	sd	s0,16(sp)
    80003978:	e426                	sd	s1,8(sp)
    8000397a:	1000                	addi	s0,sp,32
    8000397c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	e54080e7          	jalr	-428(ra) # 800037d2 <iunlock>
  iput(ip);
    80003986:	8526                	mv	a0,s1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	f42080e7          	jalr	-190(ra) # 800038ca <iput>
}
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	64a2                	ld	s1,8(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret

000000008000399a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000399a:	1141                	addi	sp,sp,-16
    8000399c:	e422                	sd	s0,8(sp)
    8000399e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039a0:	411c                	lw	a5,0(a0)
    800039a2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039a4:	415c                	lw	a5,4(a0)
    800039a6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a8:	04451783          	lh	a5,68(a0)
    800039ac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039b0:	04a51783          	lh	a5,74(a0)
    800039b4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b8:	04c56783          	lwu	a5,76(a0)
    800039bc:	e99c                	sd	a5,16(a1)
}
    800039be:	6422                	ld	s0,8(sp)
    800039c0:	0141                	addi	sp,sp,16
    800039c2:	8082                	ret

00000000800039c4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039c4:	457c                	lw	a5,76(a0)
    800039c6:	0ed7e963          	bltu	a5,a3,80003ab8 <readi+0xf4>
{
    800039ca:	7159                	addi	sp,sp,-112
    800039cc:	f486                	sd	ra,104(sp)
    800039ce:	f0a2                	sd	s0,96(sp)
    800039d0:	eca6                	sd	s1,88(sp)
    800039d2:	e8ca                	sd	s2,80(sp)
    800039d4:	e4ce                	sd	s3,72(sp)
    800039d6:	e0d2                	sd	s4,64(sp)
    800039d8:	fc56                	sd	s5,56(sp)
    800039da:	f85a                	sd	s6,48(sp)
    800039dc:	f45e                	sd	s7,40(sp)
    800039de:	f062                	sd	s8,32(sp)
    800039e0:	ec66                	sd	s9,24(sp)
    800039e2:	e86a                	sd	s10,16(sp)
    800039e4:	e46e                	sd	s11,8(sp)
    800039e6:	1880                	addi	s0,sp,112
    800039e8:	8baa                	mv	s7,a0
    800039ea:	8c2e                	mv	s8,a1
    800039ec:	8ab2                	mv	s5,a2
    800039ee:	84b6                	mv	s1,a3
    800039f0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039f2:	9f35                	addw	a4,a4,a3
    return 0;
    800039f4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f6:	0ad76063          	bltu	a4,a3,80003a96 <readi+0xd2>
  if(off + n > ip->size)
    800039fa:	00e7f463          	bgeu	a5,a4,80003a02 <readi+0x3e>
    n = ip->size - off;
    800039fe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a02:	0a0b0963          	beqz	s6,80003ab4 <readi+0xf0>
    80003a06:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a08:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a0c:	5cfd                	li	s9,-1
    80003a0e:	a82d                	j	80003a48 <readi+0x84>
    80003a10:	020a1d93          	slli	s11,s4,0x20
    80003a14:	020ddd93          	srli	s11,s11,0x20
    80003a18:	05890613          	addi	a2,s2,88
    80003a1c:	86ee                	mv	a3,s11
    80003a1e:	963a                	add	a2,a2,a4
    80003a20:	85d6                	mv	a1,s5
    80003a22:	8562                	mv	a0,s8
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	b00080e7          	jalr	-1280(ra) # 80002524 <either_copyout>
    80003a2c:	05950d63          	beq	a0,s9,80003a86 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a30:	854a                	mv	a0,s2
    80003a32:	fffff097          	auipc	ra,0xfffff
    80003a36:	5fa080e7          	jalr	1530(ra) # 8000302c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a3a:	013a09bb          	addw	s3,s4,s3
    80003a3e:	009a04bb          	addw	s1,s4,s1
    80003a42:	9aee                	add	s5,s5,s11
    80003a44:	0569f763          	bgeu	s3,s6,80003a92 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a48:	000ba903          	lw	s2,0(s7)
    80003a4c:	00a4d59b          	srliw	a1,s1,0xa
    80003a50:	855e                	mv	a0,s7
    80003a52:	00000097          	auipc	ra,0x0
    80003a56:	89e080e7          	jalr	-1890(ra) # 800032f0 <bmap>
    80003a5a:	0005059b          	sext.w	a1,a0
    80003a5e:	854a                	mv	a0,s2
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	49c080e7          	jalr	1180(ra) # 80002efc <bread>
    80003a68:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6a:	3ff4f713          	andi	a4,s1,1023
    80003a6e:	40ed07bb          	subw	a5,s10,a4
    80003a72:	413b06bb          	subw	a3,s6,s3
    80003a76:	8a3e                	mv	s4,a5
    80003a78:	2781                	sext.w	a5,a5
    80003a7a:	0006861b          	sext.w	a2,a3
    80003a7e:	f8f679e3          	bgeu	a2,a5,80003a10 <readi+0x4c>
    80003a82:	8a36                	mv	s4,a3
    80003a84:	b771                	j	80003a10 <readi+0x4c>
      brelse(bp);
    80003a86:	854a                	mv	a0,s2
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	5a4080e7          	jalr	1444(ra) # 8000302c <brelse>
      tot = -1;
    80003a90:	59fd                	li	s3,-1
  }
  return tot;
    80003a92:	0009851b          	sext.w	a0,s3
}
    80003a96:	70a6                	ld	ra,104(sp)
    80003a98:	7406                	ld	s0,96(sp)
    80003a9a:	64e6                	ld	s1,88(sp)
    80003a9c:	6946                	ld	s2,80(sp)
    80003a9e:	69a6                	ld	s3,72(sp)
    80003aa0:	6a06                	ld	s4,64(sp)
    80003aa2:	7ae2                	ld	s5,56(sp)
    80003aa4:	7b42                	ld	s6,48(sp)
    80003aa6:	7ba2                	ld	s7,40(sp)
    80003aa8:	7c02                	ld	s8,32(sp)
    80003aaa:	6ce2                	ld	s9,24(sp)
    80003aac:	6d42                	ld	s10,16(sp)
    80003aae:	6da2                	ld	s11,8(sp)
    80003ab0:	6165                	addi	sp,sp,112
    80003ab2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab4:	89da                	mv	s3,s6
    80003ab6:	bff1                	j	80003a92 <readi+0xce>
    return 0;
    80003ab8:	4501                	li	a0,0
}
    80003aba:	8082                	ret

0000000080003abc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003abc:	457c                	lw	a5,76(a0)
    80003abe:	10d7e863          	bltu	a5,a3,80003bce <writei+0x112>
{
    80003ac2:	7159                	addi	sp,sp,-112
    80003ac4:	f486                	sd	ra,104(sp)
    80003ac6:	f0a2                	sd	s0,96(sp)
    80003ac8:	eca6                	sd	s1,88(sp)
    80003aca:	e8ca                	sd	s2,80(sp)
    80003acc:	e4ce                	sd	s3,72(sp)
    80003ace:	e0d2                	sd	s4,64(sp)
    80003ad0:	fc56                	sd	s5,56(sp)
    80003ad2:	f85a                	sd	s6,48(sp)
    80003ad4:	f45e                	sd	s7,40(sp)
    80003ad6:	f062                	sd	s8,32(sp)
    80003ad8:	ec66                	sd	s9,24(sp)
    80003ada:	e86a                	sd	s10,16(sp)
    80003adc:	e46e                	sd	s11,8(sp)
    80003ade:	1880                	addi	s0,sp,112
    80003ae0:	8b2a                	mv	s6,a0
    80003ae2:	8c2e                	mv	s8,a1
    80003ae4:	8ab2                	mv	s5,a2
    80003ae6:	8936                	mv	s2,a3
    80003ae8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003aea:	00e687bb          	addw	a5,a3,a4
    80003aee:	0ed7e263          	bltu	a5,a3,80003bd2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003af2:	00043737          	lui	a4,0x43
    80003af6:	0ef76063          	bltu	a4,a5,80003bd6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003afa:	0c0b8863          	beqz	s7,80003bca <writei+0x10e>
    80003afe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b00:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b04:	5cfd                	li	s9,-1
    80003b06:	a091                	j	80003b4a <writei+0x8e>
    80003b08:	02099d93          	slli	s11,s3,0x20
    80003b0c:	020ddd93          	srli	s11,s11,0x20
    80003b10:	05848513          	addi	a0,s1,88
    80003b14:	86ee                	mv	a3,s11
    80003b16:	8656                	mv	a2,s5
    80003b18:	85e2                	mv	a1,s8
    80003b1a:	953a                	add	a0,a0,a4
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	a5e080e7          	jalr	-1442(ra) # 8000257a <either_copyin>
    80003b24:	07950263          	beq	a0,s9,80003b88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b28:	8526                	mv	a0,s1
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	790080e7          	jalr	1936(ra) # 800042ba <log_write>
    brelse(bp);
    80003b32:	8526                	mv	a0,s1
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	4f8080e7          	jalr	1272(ra) # 8000302c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b3c:	01498a3b          	addw	s4,s3,s4
    80003b40:	0129893b          	addw	s2,s3,s2
    80003b44:	9aee                	add	s5,s5,s11
    80003b46:	057a7663          	bgeu	s4,s7,80003b92 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b4a:	000b2483          	lw	s1,0(s6)
    80003b4e:	00a9559b          	srliw	a1,s2,0xa
    80003b52:	855a                	mv	a0,s6
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	79c080e7          	jalr	1948(ra) # 800032f0 <bmap>
    80003b5c:	0005059b          	sext.w	a1,a0
    80003b60:	8526                	mv	a0,s1
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	39a080e7          	jalr	922(ra) # 80002efc <bread>
    80003b6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6c:	3ff97713          	andi	a4,s2,1023
    80003b70:	40ed07bb          	subw	a5,s10,a4
    80003b74:	414b86bb          	subw	a3,s7,s4
    80003b78:	89be                	mv	s3,a5
    80003b7a:	2781                	sext.w	a5,a5
    80003b7c:	0006861b          	sext.w	a2,a3
    80003b80:	f8f674e3          	bgeu	a2,a5,80003b08 <writei+0x4c>
    80003b84:	89b6                	mv	s3,a3
    80003b86:	b749                	j	80003b08 <writei+0x4c>
      brelse(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	4a2080e7          	jalr	1186(ra) # 8000302c <brelse>
  }

  if(off > ip->size)
    80003b92:	04cb2783          	lw	a5,76(s6)
    80003b96:	0127f463          	bgeu	a5,s2,80003b9e <writei+0xe2>
    ip->size = off;
    80003b9a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b9e:	855a                	mv	a0,s6
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	aa6080e7          	jalr	-1370(ra) # 80003646 <iupdate>

  return tot;
    80003ba8:	000a051b          	sext.w	a0,s4
}
    80003bac:	70a6                	ld	ra,104(sp)
    80003bae:	7406                	ld	s0,96(sp)
    80003bb0:	64e6                	ld	s1,88(sp)
    80003bb2:	6946                	ld	s2,80(sp)
    80003bb4:	69a6                	ld	s3,72(sp)
    80003bb6:	6a06                	ld	s4,64(sp)
    80003bb8:	7ae2                	ld	s5,56(sp)
    80003bba:	7b42                	ld	s6,48(sp)
    80003bbc:	7ba2                	ld	s7,40(sp)
    80003bbe:	7c02                	ld	s8,32(sp)
    80003bc0:	6ce2                	ld	s9,24(sp)
    80003bc2:	6d42                	ld	s10,16(sp)
    80003bc4:	6da2                	ld	s11,8(sp)
    80003bc6:	6165                	addi	sp,sp,112
    80003bc8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bca:	8a5e                	mv	s4,s7
    80003bcc:	bfc9                	j	80003b9e <writei+0xe2>
    return -1;
    80003bce:	557d                	li	a0,-1
}
    80003bd0:	8082                	ret
    return -1;
    80003bd2:	557d                	li	a0,-1
    80003bd4:	bfe1                	j	80003bac <writei+0xf0>
    return -1;
    80003bd6:	557d                	li	a0,-1
    80003bd8:	bfd1                	j	80003bac <writei+0xf0>

0000000080003bda <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bda:	1141                	addi	sp,sp,-16
    80003bdc:	e406                	sd	ra,8(sp)
    80003bde:	e022                	sd	s0,0(sp)
    80003be0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003be2:	4639                	li	a2,14
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	1d4080e7          	jalr	468(ra) # 80000db8 <strncmp>
}
    80003bec:	60a2                	ld	ra,8(sp)
    80003bee:	6402                	ld	s0,0(sp)
    80003bf0:	0141                	addi	sp,sp,16
    80003bf2:	8082                	ret

0000000080003bf4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bf4:	7139                	addi	sp,sp,-64
    80003bf6:	fc06                	sd	ra,56(sp)
    80003bf8:	f822                	sd	s0,48(sp)
    80003bfa:	f426                	sd	s1,40(sp)
    80003bfc:	f04a                	sd	s2,32(sp)
    80003bfe:	ec4e                	sd	s3,24(sp)
    80003c00:	e852                	sd	s4,16(sp)
    80003c02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c04:	04451703          	lh	a4,68(a0)
    80003c08:	4785                	li	a5,1
    80003c0a:	00f71a63          	bne	a4,a5,80003c1e <dirlookup+0x2a>
    80003c0e:	892a                	mv	s2,a0
    80003c10:	89ae                	mv	s3,a1
    80003c12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	457c                	lw	a5,76(a0)
    80003c16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1a:	e79d                	bnez	a5,80003c48 <dirlookup+0x54>
    80003c1c:	a8a5                	j	80003c94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c1e:	00009517          	auipc	a0,0x9
    80003c22:	baa50513          	addi	a0,a0,-1110 # 8000c7c8 <syscalls+0x1b0>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	918080e7          	jalr	-1768(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c2e:	00009517          	auipc	a0,0x9
    80003c32:	bb250513          	addi	a0,a0,-1102 # 8000c7e0 <syscalls+0x1c8>
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	908080e7          	jalr	-1784(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3e:	24c1                	addiw	s1,s1,16
    80003c40:	04c92783          	lw	a5,76(s2)
    80003c44:	04f4f763          	bgeu	s1,a5,80003c92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c48:	4741                	li	a4,16
    80003c4a:	86a6                	mv	a3,s1
    80003c4c:	fc040613          	addi	a2,s0,-64
    80003c50:	4581                	li	a1,0
    80003c52:	854a                	mv	a0,s2
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	d70080e7          	jalr	-656(ra) # 800039c4 <readi>
    80003c5c:	47c1                	li	a5,16
    80003c5e:	fcf518e3          	bne	a0,a5,80003c2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c62:	fc045783          	lhu	a5,-64(s0)
    80003c66:	dfe1                	beqz	a5,80003c3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c68:	fc240593          	addi	a1,s0,-62
    80003c6c:	854e                	mv	a0,s3
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	f6c080e7          	jalr	-148(ra) # 80003bda <namecmp>
    80003c76:	f561                	bnez	a0,80003c3e <dirlookup+0x4a>
      if(poff)
    80003c78:	000a0463          	beqz	s4,80003c80 <dirlookup+0x8c>
        *poff = off;
    80003c7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c80:	fc045583          	lhu	a1,-64(s0)
    80003c84:	00092503          	lw	a0,0(s2)
    80003c88:	fffff097          	auipc	ra,0xfffff
    80003c8c:	742080e7          	jalr	1858(ra) # 800033ca <iget>
    80003c90:	a011                	j	80003c94 <dirlookup+0xa0>
  return 0;
    80003c92:	4501                	li	a0,0
}
    80003c94:	70e2                	ld	ra,56(sp)
    80003c96:	7442                	ld	s0,48(sp)
    80003c98:	74a2                	ld	s1,40(sp)
    80003c9a:	7902                	ld	s2,32(sp)
    80003c9c:	69e2                	ld	s3,24(sp)
    80003c9e:	6a42                	ld	s4,16(sp)
    80003ca0:	6121                	addi	sp,sp,64
    80003ca2:	8082                	ret

0000000080003ca4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ca4:	711d                	addi	sp,sp,-96
    80003ca6:	ec86                	sd	ra,88(sp)
    80003ca8:	e8a2                	sd	s0,80(sp)
    80003caa:	e4a6                	sd	s1,72(sp)
    80003cac:	e0ca                	sd	s2,64(sp)
    80003cae:	fc4e                	sd	s3,56(sp)
    80003cb0:	f852                	sd	s4,48(sp)
    80003cb2:	f456                	sd	s5,40(sp)
    80003cb4:	f05a                	sd	s6,32(sp)
    80003cb6:	ec5e                	sd	s7,24(sp)
    80003cb8:	e862                	sd	s8,16(sp)
    80003cba:	e466                	sd	s9,8(sp)
    80003cbc:	1080                	addi	s0,sp,96
    80003cbe:	84aa                	mv	s1,a0
    80003cc0:	8b2e                	mv	s6,a1
    80003cc2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cc4:	00054703          	lbu	a4,0(a0)
    80003cc8:	02f00793          	li	a5,47
    80003ccc:	02f70363          	beq	a4,a5,80003cf2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cd0:	ffffe097          	auipc	ra,0xffffe
    80003cd4:	dc0080e7          	jalr	-576(ra) # 80001a90 <myproc>
    80003cd8:	15053503          	ld	a0,336(a0)
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	9f6080e7          	jalr	-1546(ra) # 800036d2 <idup>
    80003ce4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ce6:	02f00913          	li	s2,47
  len = path - s;
    80003cea:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003cec:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cee:	4c05                	li	s8,1
    80003cf0:	a865                	j	80003da8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cf2:	4585                	li	a1,1
    80003cf4:	4505                	li	a0,1
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	6d4080e7          	jalr	1748(ra) # 800033ca <iget>
    80003cfe:	89aa                	mv	s3,a0
    80003d00:	b7dd                	j	80003ce6 <namex+0x42>
      iunlockput(ip);
    80003d02:	854e                	mv	a0,s3
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	c6e080e7          	jalr	-914(ra) # 80003972 <iunlockput>
      return 0;
    80003d0c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d0e:	854e                	mv	a0,s3
    80003d10:	60e6                	ld	ra,88(sp)
    80003d12:	6446                	ld	s0,80(sp)
    80003d14:	64a6                	ld	s1,72(sp)
    80003d16:	6906                	ld	s2,64(sp)
    80003d18:	79e2                	ld	s3,56(sp)
    80003d1a:	7a42                	ld	s4,48(sp)
    80003d1c:	7aa2                	ld	s5,40(sp)
    80003d1e:	7b02                	ld	s6,32(sp)
    80003d20:	6be2                	ld	s7,24(sp)
    80003d22:	6c42                	ld	s8,16(sp)
    80003d24:	6ca2                	ld	s9,8(sp)
    80003d26:	6125                	addi	sp,sp,96
    80003d28:	8082                	ret
      iunlock(ip);
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	aa6080e7          	jalr	-1370(ra) # 800037d2 <iunlock>
      return ip;
    80003d34:	bfe9                	j	80003d0e <namex+0x6a>
      iunlockput(ip);
    80003d36:	854e                	mv	a0,s3
    80003d38:	00000097          	auipc	ra,0x0
    80003d3c:	c3a080e7          	jalr	-966(ra) # 80003972 <iunlockput>
      return 0;
    80003d40:	89d2                	mv	s3,s4
    80003d42:	b7f1                	j	80003d0e <namex+0x6a>
  len = path - s;
    80003d44:	40b48633          	sub	a2,s1,a1
    80003d48:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d4c:	094cd463          	bge	s9,s4,80003dd4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d50:	4639                	li	a2,14
    80003d52:	8556                	mv	a0,s5
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	fec080e7          	jalr	-20(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d5c:	0004c783          	lbu	a5,0(s1)
    80003d60:	01279763          	bne	a5,s2,80003d6e <namex+0xca>
    path++;
    80003d64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d66:	0004c783          	lbu	a5,0(s1)
    80003d6a:	ff278de3          	beq	a5,s2,80003d64 <namex+0xc0>
    ilock(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	9a0080e7          	jalr	-1632(ra) # 80003710 <ilock>
    if(ip->type != T_DIR){
    80003d78:	04499783          	lh	a5,68(s3)
    80003d7c:	f98793e3          	bne	a5,s8,80003d02 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d80:	000b0563          	beqz	s6,80003d8a <namex+0xe6>
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	d3cd                	beqz	a5,80003d2a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d8a:	865e                	mv	a2,s7
    80003d8c:	85d6                	mv	a1,s5
    80003d8e:	854e                	mv	a0,s3
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	e64080e7          	jalr	-412(ra) # 80003bf4 <dirlookup>
    80003d98:	8a2a                	mv	s4,a0
    80003d9a:	dd51                	beqz	a0,80003d36 <namex+0x92>
    iunlockput(ip);
    80003d9c:	854e                	mv	a0,s3
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	bd4080e7          	jalr	-1068(ra) # 80003972 <iunlockput>
    ip = next;
    80003da6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	05279763          	bne	a5,s2,80003dfa <namex+0x156>
    path++;
    80003db0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db2:	0004c783          	lbu	a5,0(s1)
    80003db6:	ff278de3          	beq	a5,s2,80003db0 <namex+0x10c>
  if(*path == 0)
    80003dba:	c79d                	beqz	a5,80003de8 <namex+0x144>
    path++;
    80003dbc:	85a6                	mv	a1,s1
  len = path - s;
    80003dbe:	8a5e                	mv	s4,s7
    80003dc0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dc2:	01278963          	beq	a5,s2,80003dd4 <namex+0x130>
    80003dc6:	dfbd                	beqz	a5,80003d44 <namex+0xa0>
    path++;
    80003dc8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dca:	0004c783          	lbu	a5,0(s1)
    80003dce:	ff279ce3          	bne	a5,s2,80003dc6 <namex+0x122>
    80003dd2:	bf8d                	j	80003d44 <namex+0xa0>
    memmove(name, s, len);
    80003dd4:	2601                	sext.w	a2,a2
    80003dd6:	8556                	mv	a0,s5
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	f68080e7          	jalr	-152(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003de0:	9a56                	add	s4,s4,s5
    80003de2:	000a0023          	sb	zero,0(s4)
    80003de6:	bf9d                	j	80003d5c <namex+0xb8>
  if(nameiparent){
    80003de8:	f20b03e3          	beqz	s6,80003d0e <namex+0x6a>
    iput(ip);
    80003dec:	854e                	mv	a0,s3
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	adc080e7          	jalr	-1316(ra) # 800038ca <iput>
    return 0;
    80003df6:	4981                	li	s3,0
    80003df8:	bf19                	j	80003d0e <namex+0x6a>
  if(*path == 0)
    80003dfa:	d7fd                	beqz	a5,80003de8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	85a6                	mv	a1,s1
    80003e02:	b7d1                	j	80003dc6 <namex+0x122>

0000000080003e04 <dirlink>:
{
    80003e04:	7139                	addi	sp,sp,-64
    80003e06:	fc06                	sd	ra,56(sp)
    80003e08:	f822                	sd	s0,48(sp)
    80003e0a:	f426                	sd	s1,40(sp)
    80003e0c:	f04a                	sd	s2,32(sp)
    80003e0e:	ec4e                	sd	s3,24(sp)
    80003e10:	e852                	sd	s4,16(sp)
    80003e12:	0080                	addi	s0,sp,64
    80003e14:	892a                	mv	s2,a0
    80003e16:	8a2e                	mv	s4,a1
    80003e18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e1a:	4601                	li	a2,0
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	dd8080e7          	jalr	-552(ra) # 80003bf4 <dirlookup>
    80003e24:	e93d                	bnez	a0,80003e9a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e26:	04c92483          	lw	s1,76(s2)
    80003e2a:	c49d                	beqz	s1,80003e58 <dirlink+0x54>
    80003e2c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e2e:	4741                	li	a4,16
    80003e30:	86a6                	mv	a3,s1
    80003e32:	fc040613          	addi	a2,s0,-64
    80003e36:	4581                	li	a1,0
    80003e38:	854a                	mv	a0,s2
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	b8a080e7          	jalr	-1142(ra) # 800039c4 <readi>
    80003e42:	47c1                	li	a5,16
    80003e44:	06f51163          	bne	a0,a5,80003ea6 <dirlink+0xa2>
    if(de.inum == 0)
    80003e48:	fc045783          	lhu	a5,-64(s0)
    80003e4c:	c791                	beqz	a5,80003e58 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4e:	24c1                	addiw	s1,s1,16
    80003e50:	04c92783          	lw	a5,76(s2)
    80003e54:	fcf4ede3          	bltu	s1,a5,80003e2e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e58:	4639                	li	a2,14
    80003e5a:	85d2                	mv	a1,s4
    80003e5c:	fc240513          	addi	a0,s0,-62
    80003e60:	ffffd097          	auipc	ra,0xffffd
    80003e64:	f94080e7          	jalr	-108(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e68:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e6c:	4741                	li	a4,16
    80003e6e:	86a6                	mv	a3,s1
    80003e70:	fc040613          	addi	a2,s0,-64
    80003e74:	4581                	li	a1,0
    80003e76:	854a                	mv	a0,s2
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	c44080e7          	jalr	-956(ra) # 80003abc <writei>
    80003e80:	872a                	mv	a4,a0
    80003e82:	47c1                	li	a5,16
  return 0;
    80003e84:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e86:	02f71863          	bne	a4,a5,80003eb6 <dirlink+0xb2>
}
    80003e8a:	70e2                	ld	ra,56(sp)
    80003e8c:	7442                	ld	s0,48(sp)
    80003e8e:	74a2                	ld	s1,40(sp)
    80003e90:	7902                	ld	s2,32(sp)
    80003e92:	69e2                	ld	s3,24(sp)
    80003e94:	6a42                	ld	s4,16(sp)
    80003e96:	6121                	addi	sp,sp,64
    80003e98:	8082                	ret
    iput(ip);
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	a30080e7          	jalr	-1488(ra) # 800038ca <iput>
    return -1;
    80003ea2:	557d                	li	a0,-1
    80003ea4:	b7dd                	j	80003e8a <dirlink+0x86>
      panic("dirlink read");
    80003ea6:	00009517          	auipc	a0,0x9
    80003eaa:	94a50513          	addi	a0,a0,-1718 # 8000c7f0 <syscalls+0x1d8>
    80003eae:	ffffc097          	auipc	ra,0xffffc
    80003eb2:	690080e7          	jalr	1680(ra) # 8000053e <panic>
    panic("dirlink");
    80003eb6:	00009517          	auipc	a0,0x9
    80003eba:	a5a50513          	addi	a0,a0,-1446 # 8000c910 <syscalls+0x2f8>
    80003ebe:	ffffc097          	auipc	ra,0xffffc
    80003ec2:	680080e7          	jalr	1664(ra) # 8000053e <panic>

0000000080003ec6 <namei>:

struct inode*
namei(char *path)
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ece:	fe040613          	addi	a2,s0,-32
    80003ed2:	4581                	li	a1,0
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	dd0080e7          	jalr	-560(ra) # 80003ca4 <namex>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ee4:	1141                	addi	sp,sp,-16
    80003ee6:	e406                	sd	ra,8(sp)
    80003ee8:	e022                	sd	s0,0(sp)
    80003eea:	0800                	addi	s0,sp,16
    80003eec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eee:	4585                	li	a1,1
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	db4080e7          	jalr	-588(ra) # 80003ca4 <namex>
}
    80003ef8:	60a2                	ld	ra,8(sp)
    80003efa:	6402                	ld	s0,0(sp)
    80003efc:	0141                	addi	sp,sp,16
    80003efe:	8082                	ret

0000000080003f00 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f00:	1101                	addi	sp,sp,-32
    80003f02:	ec06                	sd	ra,24(sp)
    80003f04:	e822                	sd	s0,16(sp)
    80003f06:	e426                	sd	s1,8(sp)
    80003f08:	e04a                	sd	s2,0(sp)
    80003f0a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f0c:	00024917          	auipc	s2,0x24
    80003f10:	36490913          	addi	s2,s2,868 # 80028270 <log>
    80003f14:	01892583          	lw	a1,24(s2)
    80003f18:	02892503          	lw	a0,40(s2)
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	fe0080e7          	jalr	-32(ra) # 80002efc <bread>
    80003f24:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f26:	02c92683          	lw	a3,44(s2)
    80003f2a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f2c:	02d05763          	blez	a3,80003f5a <write_head+0x5a>
    80003f30:	00024797          	auipc	a5,0x24
    80003f34:	37078793          	addi	a5,a5,880 # 800282a0 <log+0x30>
    80003f38:	05c50713          	addi	a4,a0,92
    80003f3c:	36fd                	addiw	a3,a3,-1
    80003f3e:	1682                	slli	a3,a3,0x20
    80003f40:	9281                	srli	a3,a3,0x20
    80003f42:	068a                	slli	a3,a3,0x2
    80003f44:	00024617          	auipc	a2,0x24
    80003f48:	36060613          	addi	a2,a2,864 # 800282a4 <log+0x34>
    80003f4c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f4e:	4390                	lw	a2,0(a5)
    80003f50:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f52:	0791                	addi	a5,a5,4
    80003f54:	0711                	addi	a4,a4,4
    80003f56:	fed79ce3          	bne	a5,a3,80003f4e <write_head+0x4e>
  }
  bwrite(buf);
    80003f5a:	8526                	mv	a0,s1
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	092080e7          	jalr	146(ra) # 80002fee <bwrite>
  brelse(buf);
    80003f64:	8526                	mv	a0,s1
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	0c6080e7          	jalr	198(ra) # 8000302c <brelse>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	64a2                	ld	s1,8(sp)
    80003f74:	6902                	ld	s2,0(sp)
    80003f76:	6105                	addi	sp,sp,32
    80003f78:	8082                	ret

0000000080003f7a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f7a:	00024797          	auipc	a5,0x24
    80003f7e:	3227a783          	lw	a5,802(a5) # 8002829c <log+0x2c>
    80003f82:	0af05d63          	blez	a5,8000403c <install_trans+0xc2>
{
    80003f86:	7139                	addi	sp,sp,-64
    80003f88:	fc06                	sd	ra,56(sp)
    80003f8a:	f822                	sd	s0,48(sp)
    80003f8c:	f426                	sd	s1,40(sp)
    80003f8e:	f04a                	sd	s2,32(sp)
    80003f90:	ec4e                	sd	s3,24(sp)
    80003f92:	e852                	sd	s4,16(sp)
    80003f94:	e456                	sd	s5,8(sp)
    80003f96:	e05a                	sd	s6,0(sp)
    80003f98:	0080                	addi	s0,sp,64
    80003f9a:	8b2a                	mv	s6,a0
    80003f9c:	00024a97          	auipc	s5,0x24
    80003fa0:	304a8a93          	addi	s5,s5,772 # 800282a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fa6:	00024997          	auipc	s3,0x24
    80003faa:	2ca98993          	addi	s3,s3,714 # 80028270 <log>
    80003fae:	a035                	j	80003fda <install_trans+0x60>
      bunpin(dbuf);
    80003fb0:	8526                	mv	a0,s1
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	154080e7          	jalr	340(ra) # 80003106 <bunpin>
    brelse(lbuf);
    80003fba:	854a                	mv	a0,s2
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	070080e7          	jalr	112(ra) # 8000302c <brelse>
    brelse(dbuf);
    80003fc4:	8526                	mv	a0,s1
    80003fc6:	fffff097          	auipc	ra,0xfffff
    80003fca:	066080e7          	jalr	102(ra) # 8000302c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fce:	2a05                	addiw	s4,s4,1
    80003fd0:	0a91                	addi	s5,s5,4
    80003fd2:	02c9a783          	lw	a5,44(s3)
    80003fd6:	04fa5963          	bge	s4,a5,80004028 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fda:	0189a583          	lw	a1,24(s3)
    80003fde:	014585bb          	addw	a1,a1,s4
    80003fe2:	2585                	addiw	a1,a1,1
    80003fe4:	0289a503          	lw	a0,40(s3)
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	f14080e7          	jalr	-236(ra) # 80002efc <bread>
    80003ff0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ff2:	000aa583          	lw	a1,0(s5)
    80003ff6:	0289a503          	lw	a0,40(s3)
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	f02080e7          	jalr	-254(ra) # 80002efc <bread>
    80004002:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004004:	40000613          	li	a2,1024
    80004008:	05890593          	addi	a1,s2,88
    8000400c:	05850513          	addi	a0,a0,88
    80004010:	ffffd097          	auipc	ra,0xffffd
    80004014:	d30080e7          	jalr	-720(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	fd4080e7          	jalr	-44(ra) # 80002fee <bwrite>
    if(recovering == 0)
    80004022:	f80b1ce3          	bnez	s6,80003fba <install_trans+0x40>
    80004026:	b769                	j	80003fb0 <install_trans+0x36>
}
    80004028:	70e2                	ld	ra,56(sp)
    8000402a:	7442                	ld	s0,48(sp)
    8000402c:	74a2                	ld	s1,40(sp)
    8000402e:	7902                	ld	s2,32(sp)
    80004030:	69e2                	ld	s3,24(sp)
    80004032:	6a42                	ld	s4,16(sp)
    80004034:	6aa2                	ld	s5,8(sp)
    80004036:	6b02                	ld	s6,0(sp)
    80004038:	6121                	addi	sp,sp,64
    8000403a:	8082                	ret
    8000403c:	8082                	ret

000000008000403e <initlog>:
{
    8000403e:	7179                	addi	sp,sp,-48
    80004040:	f406                	sd	ra,40(sp)
    80004042:	f022                	sd	s0,32(sp)
    80004044:	ec26                	sd	s1,24(sp)
    80004046:	e84a                	sd	s2,16(sp)
    80004048:	e44e                	sd	s3,8(sp)
    8000404a:	1800                	addi	s0,sp,48
    8000404c:	892a                	mv	s2,a0
    8000404e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004050:	00024497          	auipc	s1,0x24
    80004054:	22048493          	addi	s1,s1,544 # 80028270 <log>
    80004058:	00008597          	auipc	a1,0x8
    8000405c:	7a858593          	addi	a1,a1,1960 # 8000c800 <syscalls+0x1e8>
    80004060:	8526                	mv	a0,s1
    80004062:	ffffd097          	auipc	ra,0xffffd
    80004066:	af2080e7          	jalr	-1294(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000406a:	0149a583          	lw	a1,20(s3)
    8000406e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004070:	0109a783          	lw	a5,16(s3)
    80004074:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004076:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000407a:	854a                	mv	a0,s2
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	e80080e7          	jalr	-384(ra) # 80002efc <bread>
  log.lh.n = lh->n;
    80004084:	4d3c                	lw	a5,88(a0)
    80004086:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004088:	02f05563          	blez	a5,800040b2 <initlog+0x74>
    8000408c:	05c50713          	addi	a4,a0,92
    80004090:	00024697          	auipc	a3,0x24
    80004094:	21068693          	addi	a3,a3,528 # 800282a0 <log+0x30>
    80004098:	37fd                	addiw	a5,a5,-1
    8000409a:	1782                	slli	a5,a5,0x20
    8000409c:	9381                	srli	a5,a5,0x20
    8000409e:	078a                	slli	a5,a5,0x2
    800040a0:	06050613          	addi	a2,a0,96
    800040a4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040a6:	4310                	lw	a2,0(a4)
    800040a8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040aa:	0711                	addi	a4,a4,4
    800040ac:	0691                	addi	a3,a3,4
    800040ae:	fef71ce3          	bne	a4,a5,800040a6 <initlog+0x68>
  brelse(buf);
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	f7a080e7          	jalr	-134(ra) # 8000302c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040ba:	4505                	li	a0,1
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	ebe080e7          	jalr	-322(ra) # 80003f7a <install_trans>
  log.lh.n = 0;
    800040c4:	00024797          	auipc	a5,0x24
    800040c8:	1c07ac23          	sw	zero,472(a5) # 8002829c <log+0x2c>
  write_head(); // clear the log
    800040cc:	00000097          	auipc	ra,0x0
    800040d0:	e34080e7          	jalr	-460(ra) # 80003f00 <write_head>
}
    800040d4:	70a2                	ld	ra,40(sp)
    800040d6:	7402                	ld	s0,32(sp)
    800040d8:	64e2                	ld	s1,24(sp)
    800040da:	6942                	ld	s2,16(sp)
    800040dc:	69a2                	ld	s3,8(sp)
    800040de:	6145                	addi	sp,sp,48
    800040e0:	8082                	ret

00000000800040e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040e2:	1101                	addi	sp,sp,-32
    800040e4:	ec06                	sd	ra,24(sp)
    800040e6:	e822                	sd	s0,16(sp)
    800040e8:	e426                	sd	s1,8(sp)
    800040ea:	e04a                	sd	s2,0(sp)
    800040ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040ee:	00024517          	auipc	a0,0x24
    800040f2:	18250513          	addi	a0,a0,386 # 80028270 <log>
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	aee080e7          	jalr	-1298(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040fe:	00024497          	auipc	s1,0x24
    80004102:	17248493          	addi	s1,s1,370 # 80028270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004106:	4979                	li	s2,30
    80004108:	a039                	j	80004116 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000410a:	85a6                	mv	a1,s1
    8000410c:	8526                	mv	a0,s1
    8000410e:	ffffe097          	auipc	ra,0xffffe
    80004112:	072080e7          	jalr	114(ra) # 80002180 <sleep>
    if(log.committing){
    80004116:	50dc                	lw	a5,36(s1)
    80004118:	fbed                	bnez	a5,8000410a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411a:	509c                	lw	a5,32(s1)
    8000411c:	0017871b          	addiw	a4,a5,1
    80004120:	0007069b          	sext.w	a3,a4
    80004124:	0027179b          	slliw	a5,a4,0x2
    80004128:	9fb9                	addw	a5,a5,a4
    8000412a:	0017979b          	slliw	a5,a5,0x1
    8000412e:	54d8                	lw	a4,44(s1)
    80004130:	9fb9                	addw	a5,a5,a4
    80004132:	00f95963          	bge	s2,a5,80004144 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004136:	85a6                	mv	a1,s1
    80004138:	8526                	mv	a0,s1
    8000413a:	ffffe097          	auipc	ra,0xffffe
    8000413e:	046080e7          	jalr	70(ra) # 80002180 <sleep>
    80004142:	bfd1                	j	80004116 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004144:	00024517          	auipc	a0,0x24
    80004148:	12c50513          	addi	a0,a0,300 # 80028270 <log>
    8000414c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	b4a080e7          	jalr	-1206(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004156:	60e2                	ld	ra,24(sp)
    80004158:	6442                	ld	s0,16(sp)
    8000415a:	64a2                	ld	s1,8(sp)
    8000415c:	6902                	ld	s2,0(sp)
    8000415e:	6105                	addi	sp,sp,32
    80004160:	8082                	ret

0000000080004162 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004162:	7139                	addi	sp,sp,-64
    80004164:	fc06                	sd	ra,56(sp)
    80004166:	f822                	sd	s0,48(sp)
    80004168:	f426                	sd	s1,40(sp)
    8000416a:	f04a                	sd	s2,32(sp)
    8000416c:	ec4e                	sd	s3,24(sp)
    8000416e:	e852                	sd	s4,16(sp)
    80004170:	e456                	sd	s5,8(sp)
    80004172:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004174:	00024497          	auipc	s1,0x24
    80004178:	0fc48493          	addi	s1,s1,252 # 80028270 <log>
    8000417c:	8526                	mv	a0,s1
    8000417e:	ffffd097          	auipc	ra,0xffffd
    80004182:	a66080e7          	jalr	-1434(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004186:	509c                	lw	a5,32(s1)
    80004188:	37fd                	addiw	a5,a5,-1
    8000418a:	0007891b          	sext.w	s2,a5
    8000418e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004190:	50dc                	lw	a5,36(s1)
    80004192:	efb9                	bnez	a5,800041f0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004194:	06091663          	bnez	s2,80004200 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004198:	00024497          	auipc	s1,0x24
    8000419c:	0d848493          	addi	s1,s1,216 # 80028270 <log>
    800041a0:	4785                	li	a5,1
    800041a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	af2080e7          	jalr	-1294(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041ae:	54dc                	lw	a5,44(s1)
    800041b0:	06f04763          	bgtz	a5,8000421e <end_op+0xbc>
    acquire(&log.lock);
    800041b4:	00024497          	auipc	s1,0x24
    800041b8:	0bc48493          	addi	s1,s1,188 # 80028270 <log>
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	a26080e7          	jalr	-1498(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffe097          	auipc	ra,0xffffe
    800041d0:	140080e7          	jalr	320(ra) # 8000230c <wakeup>
    release(&log.lock);
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	ac2080e7          	jalr	-1342(ra) # 80000c98 <release>
}
    800041de:	70e2                	ld	ra,56(sp)
    800041e0:	7442                	ld	s0,48(sp)
    800041e2:	74a2                	ld	s1,40(sp)
    800041e4:	7902                	ld	s2,32(sp)
    800041e6:	69e2                	ld	s3,24(sp)
    800041e8:	6a42                	ld	s4,16(sp)
    800041ea:	6aa2                	ld	s5,8(sp)
    800041ec:	6121                	addi	sp,sp,64
    800041ee:	8082                	ret
    panic("log.committing");
    800041f0:	00008517          	auipc	a0,0x8
    800041f4:	61850513          	addi	a0,a0,1560 # 8000c808 <syscalls+0x1f0>
    800041f8:	ffffc097          	auipc	ra,0xffffc
    800041fc:	346080e7          	jalr	838(ra) # 8000053e <panic>
    wakeup(&log);
    80004200:	00024497          	auipc	s1,0x24
    80004204:	07048493          	addi	s1,s1,112 # 80028270 <log>
    80004208:	8526                	mv	a0,s1
    8000420a:	ffffe097          	auipc	ra,0xffffe
    8000420e:	102080e7          	jalr	258(ra) # 8000230c <wakeup>
  release(&log.lock);
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	a84080e7          	jalr	-1404(ra) # 80000c98 <release>
  if(do_commit){
    8000421c:	b7c9                	j	800041de <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421e:	00024a97          	auipc	s5,0x24
    80004222:	082a8a93          	addi	s5,s5,130 # 800282a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004226:	00024a17          	auipc	s4,0x24
    8000422a:	04aa0a13          	addi	s4,s4,74 # 80028270 <log>
    8000422e:	018a2583          	lw	a1,24(s4)
    80004232:	012585bb          	addw	a1,a1,s2
    80004236:	2585                	addiw	a1,a1,1
    80004238:	028a2503          	lw	a0,40(s4)
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	cc0080e7          	jalr	-832(ra) # 80002efc <bread>
    80004244:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004246:	000aa583          	lw	a1,0(s5)
    8000424a:	028a2503          	lw	a0,40(s4)
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	cae080e7          	jalr	-850(ra) # 80002efc <bread>
    80004256:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004258:	40000613          	li	a2,1024
    8000425c:	05850593          	addi	a1,a0,88
    80004260:	05848513          	addi	a0,s1,88
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	adc080e7          	jalr	-1316(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	d80080e7          	jalr	-640(ra) # 80002fee <bwrite>
    brelse(from);
    80004276:	854e                	mv	a0,s3
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	db4080e7          	jalr	-588(ra) # 8000302c <brelse>
    brelse(to);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	daa080e7          	jalr	-598(ra) # 8000302c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428a:	2905                	addiw	s2,s2,1
    8000428c:	0a91                	addi	s5,s5,4
    8000428e:	02ca2783          	lw	a5,44(s4)
    80004292:	f8f94ee3          	blt	s2,a5,8000422e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	c6a080e7          	jalr	-918(ra) # 80003f00 <write_head>
    install_trans(0); // Now install writes to home locations
    8000429e:	4501                	li	a0,0
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	cda080e7          	jalr	-806(ra) # 80003f7a <install_trans>
    log.lh.n = 0;
    800042a8:	00024797          	auipc	a5,0x24
    800042ac:	fe07aa23          	sw	zero,-12(a5) # 8002829c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	c50080e7          	jalr	-944(ra) # 80003f00 <write_head>
    800042b8:	bdf5                	j	800041b4 <end_op+0x52>

00000000800042ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ba:	1101                	addi	sp,sp,-32
    800042bc:	ec06                	sd	ra,24(sp)
    800042be:	e822                	sd	s0,16(sp)
    800042c0:	e426                	sd	s1,8(sp)
    800042c2:	e04a                	sd	s2,0(sp)
    800042c4:	1000                	addi	s0,sp,32
    800042c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042c8:	00024917          	auipc	s2,0x24
    800042cc:	fa890913          	addi	s2,s2,-88 # 80028270 <log>
    800042d0:	854a                	mv	a0,s2
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	912080e7          	jalr	-1774(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042da:	02c92603          	lw	a2,44(s2)
    800042de:	47f5                	li	a5,29
    800042e0:	06c7c563          	blt	a5,a2,8000434a <log_write+0x90>
    800042e4:	00024797          	auipc	a5,0x24
    800042e8:	fa87a783          	lw	a5,-88(a5) # 8002828c <log+0x1c>
    800042ec:	37fd                	addiw	a5,a5,-1
    800042ee:	04f65e63          	bge	a2,a5,8000434a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f2:	00024797          	auipc	a5,0x24
    800042f6:	f9e7a783          	lw	a5,-98(a5) # 80028290 <log+0x20>
    800042fa:	06f05063          	blez	a5,8000435a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042fe:	4781                	li	a5,0
    80004300:	06c05563          	blez	a2,8000436a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004304:	44cc                	lw	a1,12(s1)
    80004306:	00024717          	auipc	a4,0x24
    8000430a:	f9a70713          	addi	a4,a4,-102 # 800282a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000430e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004310:	4314                	lw	a3,0(a4)
    80004312:	04b68c63          	beq	a3,a1,8000436a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004316:	2785                	addiw	a5,a5,1
    80004318:	0711                	addi	a4,a4,4
    8000431a:	fef61be3          	bne	a2,a5,80004310 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000431e:	0621                	addi	a2,a2,8
    80004320:	060a                	slli	a2,a2,0x2
    80004322:	00024797          	auipc	a5,0x24
    80004326:	f4e78793          	addi	a5,a5,-178 # 80028270 <log>
    8000432a:	963e                	add	a2,a2,a5
    8000432c:	44dc                	lw	a5,12(s1)
    8000432e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004330:	8526                	mv	a0,s1
    80004332:	fffff097          	auipc	ra,0xfffff
    80004336:	d98080e7          	jalr	-616(ra) # 800030ca <bpin>
    log.lh.n++;
    8000433a:	00024717          	auipc	a4,0x24
    8000433e:	f3670713          	addi	a4,a4,-202 # 80028270 <log>
    80004342:	575c                	lw	a5,44(a4)
    80004344:	2785                	addiw	a5,a5,1
    80004346:	d75c                	sw	a5,44(a4)
    80004348:	a835                	j	80004384 <log_write+0xca>
    panic("too big a transaction");
    8000434a:	00008517          	auipc	a0,0x8
    8000434e:	4ce50513          	addi	a0,a0,1230 # 8000c818 <syscalls+0x200>
    80004352:	ffffc097          	auipc	ra,0xffffc
    80004356:	1ec080e7          	jalr	492(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000435a:	00008517          	auipc	a0,0x8
    8000435e:	4d650513          	addi	a0,a0,1238 # 8000c830 <syscalls+0x218>
    80004362:	ffffc097          	auipc	ra,0xffffc
    80004366:	1dc080e7          	jalr	476(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000436a:	00878713          	addi	a4,a5,8
    8000436e:	00271693          	slli	a3,a4,0x2
    80004372:	00024717          	auipc	a4,0x24
    80004376:	efe70713          	addi	a4,a4,-258 # 80028270 <log>
    8000437a:	9736                	add	a4,a4,a3
    8000437c:	44d4                	lw	a3,12(s1)
    8000437e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004380:	faf608e3          	beq	a2,a5,80004330 <log_write+0x76>
  }
  release(&log.lock);
    80004384:	00024517          	auipc	a0,0x24
    80004388:	eec50513          	addi	a0,a0,-276 # 80028270 <log>
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
}
    80004394:	60e2                	ld	ra,24(sp)
    80004396:	6442                	ld	s0,16(sp)
    80004398:	64a2                	ld	s1,8(sp)
    8000439a:	6902                	ld	s2,0(sp)
    8000439c:	6105                	addi	sp,sp,32
    8000439e:	8082                	ret

00000000800043a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043a0:	1101                	addi	sp,sp,-32
    800043a2:	ec06                	sd	ra,24(sp)
    800043a4:	e822                	sd	s0,16(sp)
    800043a6:	e426                	sd	s1,8(sp)
    800043a8:	e04a                	sd	s2,0(sp)
    800043aa:	1000                	addi	s0,sp,32
    800043ac:	84aa                	mv	s1,a0
    800043ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043b0:	00008597          	auipc	a1,0x8
    800043b4:	4a058593          	addi	a1,a1,1184 # 8000c850 <syscalls+0x238>
    800043b8:	0521                	addi	a0,a0,8
    800043ba:	ffffc097          	auipc	ra,0xffffc
    800043be:	79a080e7          	jalr	1946(ra) # 80000b54 <initlock>
  lk->name = name;
    800043c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ca:	0204a423          	sw	zero,40(s1)
}
    800043ce:	60e2                	ld	ra,24(sp)
    800043d0:	6442                	ld	s0,16(sp)
    800043d2:	64a2                	ld	s1,8(sp)
    800043d4:	6902                	ld	s2,0(sp)
    800043d6:	6105                	addi	sp,sp,32
    800043d8:	8082                	ret

00000000800043da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043da:	1101                	addi	sp,sp,-32
    800043dc:	ec06                	sd	ra,24(sp)
    800043de:	e822                	sd	s0,16(sp)
    800043e0:	e426                	sd	s1,8(sp)
    800043e2:	e04a                	sd	s2,0(sp)
    800043e4:	1000                	addi	s0,sp,32
    800043e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043e8:	00850913          	addi	s2,a0,8
    800043ec:	854a                	mv	a0,s2
    800043ee:	ffffc097          	auipc	ra,0xffffc
    800043f2:	7f6080e7          	jalr	2038(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043f6:	409c                	lw	a5,0(s1)
    800043f8:	cb89                	beqz	a5,8000440a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043fa:	85ca                	mv	a1,s2
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffe097          	auipc	ra,0xffffe
    80004402:	d82080e7          	jalr	-638(ra) # 80002180 <sleep>
  while (lk->locked) {
    80004406:	409c                	lw	a5,0(s1)
    80004408:	fbed                	bnez	a5,800043fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000440a:	4785                	li	a5,1
    8000440c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000440e:	ffffd097          	auipc	ra,0xffffd
    80004412:	682080e7          	jalr	1666(ra) # 80001a90 <myproc>
    80004416:	591c                	lw	a5,48(a0)
    80004418:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000441a:	854a                	mv	a0,s2
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	87c080e7          	jalr	-1924(ra) # 80000c98 <release>
}
    80004424:	60e2                	ld	ra,24(sp)
    80004426:	6442                	ld	s0,16(sp)
    80004428:	64a2                	ld	s1,8(sp)
    8000442a:	6902                	ld	s2,0(sp)
    8000442c:	6105                	addi	sp,sp,32
    8000442e:	8082                	ret

0000000080004430 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000443e:	00850913          	addi	s2,a0,8
    80004442:	854a                	mv	a0,s2
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	7a0080e7          	jalr	1952(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000444c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004450:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004454:	8526                	mv	a0,s1
    80004456:	ffffe097          	auipc	ra,0xffffe
    8000445a:	eb6080e7          	jalr	-330(ra) # 8000230c <wakeup>
  release(&lk->lk);
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
}
    80004468:	60e2                	ld	ra,24(sp)
    8000446a:	6442                	ld	s0,16(sp)
    8000446c:	64a2                	ld	s1,8(sp)
    8000446e:	6902                	ld	s2,0(sp)
    80004470:	6105                	addi	sp,sp,32
    80004472:	8082                	ret

0000000080004474 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004474:	7179                	addi	sp,sp,-48
    80004476:	f406                	sd	ra,40(sp)
    80004478:	f022                	sd	s0,32(sp)
    8000447a:	ec26                	sd	s1,24(sp)
    8000447c:	e84a                	sd	s2,16(sp)
    8000447e:	e44e                	sd	s3,8(sp)
    80004480:	1800                	addi	s0,sp,48
    80004482:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004484:	00850913          	addi	s2,a0,8
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	75a080e7          	jalr	1882(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004492:	409c                	lw	a5,0(s1)
    80004494:	ef99                	bnez	a5,800044b2 <holdingsleep+0x3e>
    80004496:	4481                	li	s1,0
  release(&lk->lk);
    80004498:	854a                	mv	a0,s2
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	7fe080e7          	jalr	2046(ra) # 80000c98 <release>
  return r;
}
    800044a2:	8526                	mv	a0,s1
    800044a4:	70a2                	ld	ra,40(sp)
    800044a6:	7402                	ld	s0,32(sp)
    800044a8:	64e2                	ld	s1,24(sp)
    800044aa:	6942                	ld	s2,16(sp)
    800044ac:	69a2                	ld	s3,8(sp)
    800044ae:	6145                	addi	sp,sp,48
    800044b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b2:	0284a983          	lw	s3,40(s1)
    800044b6:	ffffd097          	auipc	ra,0xffffd
    800044ba:	5da080e7          	jalr	1498(ra) # 80001a90 <myproc>
    800044be:	5904                	lw	s1,48(a0)
    800044c0:	413484b3          	sub	s1,s1,s3
    800044c4:	0014b493          	seqz	s1,s1
    800044c8:	bfc1                	j	80004498 <holdingsleep+0x24>

00000000800044ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044ca:	1141                	addi	sp,sp,-16
    800044cc:	e406                	sd	ra,8(sp)
    800044ce:	e022                	sd	s0,0(sp)
    800044d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044d2:	00008597          	auipc	a1,0x8
    800044d6:	38e58593          	addi	a1,a1,910 # 8000c860 <syscalls+0x248>
    800044da:	00024517          	auipc	a0,0x24
    800044de:	ede50513          	addi	a0,a0,-290 # 800283b8 <ftable>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	672080e7          	jalr	1650(ra) # 80000b54 <initlock>
}
    800044ea:	60a2                	ld	ra,8(sp)
    800044ec:	6402                	ld	s0,0(sp)
    800044ee:	0141                	addi	sp,sp,16
    800044f0:	8082                	ret

00000000800044f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044f2:	1101                	addi	sp,sp,-32
    800044f4:	ec06                	sd	ra,24(sp)
    800044f6:	e822                	sd	s0,16(sp)
    800044f8:	e426                	sd	s1,8(sp)
    800044fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044fc:	00024517          	auipc	a0,0x24
    80004500:	ebc50513          	addi	a0,a0,-324 # 800283b8 <ftable>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450c:	00024497          	auipc	s1,0x24
    80004510:	ec448493          	addi	s1,s1,-316 # 800283d0 <ftable+0x18>
    80004514:	00025717          	auipc	a4,0x25
    80004518:	e5c70713          	addi	a4,a4,-420 # 80029370 <ftable+0xfb8>
    if(f->ref == 0){
    8000451c:	40dc                	lw	a5,4(s1)
    8000451e:	cf99                	beqz	a5,8000453c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004520:	02848493          	addi	s1,s1,40
    80004524:	fee49ce3          	bne	s1,a4,8000451c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004528:	00024517          	auipc	a0,0x24
    8000452c:	e9050513          	addi	a0,a0,-368 # 800283b8 <ftable>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	768080e7          	jalr	1896(ra) # 80000c98 <release>
  return 0;
    80004538:	4481                	li	s1,0
    8000453a:	a819                	j	80004550 <filealloc+0x5e>
      f->ref = 1;
    8000453c:	4785                	li	a5,1
    8000453e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004540:	00024517          	auipc	a0,0x24
    80004544:	e7850513          	addi	a0,a0,-392 # 800283b8 <ftable>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	750080e7          	jalr	1872(ra) # 80000c98 <release>
}
    80004550:	8526                	mv	a0,s1
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6105                	addi	sp,sp,32
    8000455a:	8082                	ret

000000008000455c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000455c:	1101                	addi	sp,sp,-32
    8000455e:	ec06                	sd	ra,24(sp)
    80004560:	e822                	sd	s0,16(sp)
    80004562:	e426                	sd	s1,8(sp)
    80004564:	1000                	addi	s0,sp,32
    80004566:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004568:	00024517          	auipc	a0,0x24
    8000456c:	e5050513          	addi	a0,a0,-432 # 800283b8 <ftable>
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	674080e7          	jalr	1652(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004578:	40dc                	lw	a5,4(s1)
    8000457a:	02f05263          	blez	a5,8000459e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000457e:	2785                	addiw	a5,a5,1
    80004580:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004582:	00024517          	auipc	a0,0x24
    80004586:	e3650513          	addi	a0,a0,-458 # 800283b8 <ftable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	70e080e7          	jalr	1806(ra) # 80000c98 <release>
  return f;
}
    80004592:	8526                	mv	a0,s1
    80004594:	60e2                	ld	ra,24(sp)
    80004596:	6442                	ld	s0,16(sp)
    80004598:	64a2                	ld	s1,8(sp)
    8000459a:	6105                	addi	sp,sp,32
    8000459c:	8082                	ret
    panic("filedup");
    8000459e:	00008517          	auipc	a0,0x8
    800045a2:	2ca50513          	addi	a0,a0,714 # 8000c868 <syscalls+0x250>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	f98080e7          	jalr	-104(ra) # 8000053e <panic>

00000000800045ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045ae:	7139                	addi	sp,sp,-64
    800045b0:	fc06                	sd	ra,56(sp)
    800045b2:	f822                	sd	s0,48(sp)
    800045b4:	f426                	sd	s1,40(sp)
    800045b6:	f04a                	sd	s2,32(sp)
    800045b8:	ec4e                	sd	s3,24(sp)
    800045ba:	e852                	sd	s4,16(sp)
    800045bc:	e456                	sd	s5,8(sp)
    800045be:	0080                	addi	s0,sp,64
    800045c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045c2:	00024517          	auipc	a0,0x24
    800045c6:	df650513          	addi	a0,a0,-522 # 800283b8 <ftable>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	61a080e7          	jalr	1562(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045d2:	40dc                	lw	a5,4(s1)
    800045d4:	06f05163          	blez	a5,80004636 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045d8:	37fd                	addiw	a5,a5,-1
    800045da:	0007871b          	sext.w	a4,a5
    800045de:	c0dc                	sw	a5,4(s1)
    800045e0:	06e04363          	bgtz	a4,80004646 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045e4:	0004a903          	lw	s2,0(s1)
    800045e8:	0094ca83          	lbu	s5,9(s1)
    800045ec:	0104ba03          	ld	s4,16(s1)
    800045f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045fc:	00024517          	auipc	a0,0x24
    80004600:	dbc50513          	addi	a0,a0,-580 # 800283b8 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	694080e7          	jalr	1684(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000460c:	4785                	li	a5,1
    8000460e:	04f90d63          	beq	s2,a5,80004668 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004612:	3979                	addiw	s2,s2,-2
    80004614:	4785                	li	a5,1
    80004616:	0527e063          	bltu	a5,s2,80004656 <fileclose+0xa8>
    begin_op();
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	ac8080e7          	jalr	-1336(ra) # 800040e2 <begin_op>
    iput(ff.ip);
    80004622:	854e                	mv	a0,s3
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	2a6080e7          	jalr	678(ra) # 800038ca <iput>
    end_op();
    8000462c:	00000097          	auipc	ra,0x0
    80004630:	b36080e7          	jalr	-1226(ra) # 80004162 <end_op>
    80004634:	a00d                	j	80004656 <fileclose+0xa8>
    panic("fileclose");
    80004636:	00008517          	auipc	a0,0x8
    8000463a:	23a50513          	addi	a0,a0,570 # 8000c870 <syscalls+0x258>
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	f00080e7          	jalr	-256(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004646:	00024517          	auipc	a0,0x24
    8000464a:	d7250513          	addi	a0,a0,-654 # 800283b8 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	64a080e7          	jalr	1610(ra) # 80000c98 <release>
  }
}
    80004656:	70e2                	ld	ra,56(sp)
    80004658:	7442                	ld	s0,48(sp)
    8000465a:	74a2                	ld	s1,40(sp)
    8000465c:	7902                	ld	s2,32(sp)
    8000465e:	69e2                	ld	s3,24(sp)
    80004660:	6a42                	ld	s4,16(sp)
    80004662:	6aa2                	ld	s5,8(sp)
    80004664:	6121                	addi	sp,sp,64
    80004666:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004668:	85d6                	mv	a1,s5
    8000466a:	8552                	mv	a0,s4
    8000466c:	00000097          	auipc	ra,0x0
    80004670:	34c080e7          	jalr	844(ra) # 800049b8 <pipeclose>
    80004674:	b7cd                	j	80004656 <fileclose+0xa8>

0000000080004676 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004676:	715d                	addi	sp,sp,-80
    80004678:	e486                	sd	ra,72(sp)
    8000467a:	e0a2                	sd	s0,64(sp)
    8000467c:	fc26                	sd	s1,56(sp)
    8000467e:	f84a                	sd	s2,48(sp)
    80004680:	f44e                	sd	s3,40(sp)
    80004682:	0880                	addi	s0,sp,80
    80004684:	84aa                	mv	s1,a0
    80004686:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004688:	ffffd097          	auipc	ra,0xffffd
    8000468c:	408080e7          	jalr	1032(ra) # 80001a90 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004690:	409c                	lw	a5,0(s1)
    80004692:	37f9                	addiw	a5,a5,-2
    80004694:	4705                	li	a4,1
    80004696:	04f76763          	bltu	a4,a5,800046e4 <filestat+0x6e>
    8000469a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000469c:	6c88                	ld	a0,24(s1)
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	072080e7          	jalr	114(ra) # 80003710 <ilock>
    stati(f->ip, &st);
    800046a6:	fb840593          	addi	a1,s0,-72
    800046aa:	6c88                	ld	a0,24(s1)
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	2ee080e7          	jalr	750(ra) # 8000399a <stati>
    iunlock(f->ip);
    800046b4:	6c88                	ld	a0,24(s1)
    800046b6:	fffff097          	auipc	ra,0xfffff
    800046ba:	11c080e7          	jalr	284(ra) # 800037d2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046be:	46e1                	li	a3,24
    800046c0:	fb840613          	addi	a2,s0,-72
    800046c4:	85ce                	mv	a1,s3
    800046c6:	05093503          	ld	a0,80(s2)
    800046ca:	ffffd097          	auipc	ra,0xffffd
    800046ce:	088080e7          	jalr	136(ra) # 80001752 <copyout>
    800046d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046d6:	60a6                	ld	ra,72(sp)
    800046d8:	6406                	ld	s0,64(sp)
    800046da:	74e2                	ld	s1,56(sp)
    800046dc:	7942                	ld	s2,48(sp)
    800046de:	79a2                	ld	s3,40(sp)
    800046e0:	6161                	addi	sp,sp,80
    800046e2:	8082                	ret
  return -1;
    800046e4:	557d                	li	a0,-1
    800046e6:	bfc5                	j	800046d6 <filestat+0x60>

00000000800046e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046e8:	7179                	addi	sp,sp,-48
    800046ea:	f406                	sd	ra,40(sp)
    800046ec:	f022                	sd	s0,32(sp)
    800046ee:	ec26                	sd	s1,24(sp)
    800046f0:	e84a                	sd	s2,16(sp)
    800046f2:	e44e                	sd	s3,8(sp)
    800046f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046f6:	00854783          	lbu	a5,8(a0)
    800046fa:	c3d5                	beqz	a5,8000479e <fileread+0xb6>
    800046fc:	84aa                	mv	s1,a0
    800046fe:	89ae                	mv	s3,a1
    80004700:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004702:	411c                	lw	a5,0(a0)
    80004704:	4705                	li	a4,1
    80004706:	04e78963          	beq	a5,a4,80004758 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000470a:	470d                	li	a4,3
    8000470c:	04e78d63          	beq	a5,a4,80004766 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004710:	4709                	li	a4,2
    80004712:	06e79e63          	bne	a5,a4,8000478e <fileread+0xa6>
    ilock(f->ip);
    80004716:	6d08                	ld	a0,24(a0)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	ff8080e7          	jalr	-8(ra) # 80003710 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004720:	874a                	mv	a4,s2
    80004722:	5094                	lw	a3,32(s1)
    80004724:	864e                	mv	a2,s3
    80004726:	4585                	li	a1,1
    80004728:	6c88                	ld	a0,24(s1)
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	29a080e7          	jalr	666(ra) # 800039c4 <readi>
    80004732:	892a                	mv	s2,a0
    80004734:	00a05563          	blez	a0,8000473e <fileread+0x56>
      f->off += r;
    80004738:	509c                	lw	a5,32(s1)
    8000473a:	9fa9                	addw	a5,a5,a0
    8000473c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	092080e7          	jalr	146(ra) # 800037d2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004748:	854a                	mv	a0,s2
    8000474a:	70a2                	ld	ra,40(sp)
    8000474c:	7402                	ld	s0,32(sp)
    8000474e:	64e2                	ld	s1,24(sp)
    80004750:	6942                	ld	s2,16(sp)
    80004752:	69a2                	ld	s3,8(sp)
    80004754:	6145                	addi	sp,sp,48
    80004756:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004758:	6908                	ld	a0,16(a0)
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	3c8080e7          	jalr	968(ra) # 80004b22 <piperead>
    80004762:	892a                	mv	s2,a0
    80004764:	b7d5                	j	80004748 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004766:	02451783          	lh	a5,36(a0)
    8000476a:	03079693          	slli	a3,a5,0x30
    8000476e:	92c1                	srli	a3,a3,0x30
    80004770:	4725                	li	a4,9
    80004772:	02d76863          	bltu	a4,a3,800047a2 <fileread+0xba>
    80004776:	0792                	slli	a5,a5,0x4
    80004778:	00024717          	auipc	a4,0x24
    8000477c:	ba070713          	addi	a4,a4,-1120 # 80028318 <devsw>
    80004780:	97ba                	add	a5,a5,a4
    80004782:	639c                	ld	a5,0(a5)
    80004784:	c38d                	beqz	a5,800047a6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004786:	4505                	li	a0,1
    80004788:	9782                	jalr	a5
    8000478a:	892a                	mv	s2,a0
    8000478c:	bf75                	j	80004748 <fileread+0x60>
    panic("fileread");
    8000478e:	00008517          	auipc	a0,0x8
    80004792:	0f250513          	addi	a0,a0,242 # 8000c880 <syscalls+0x268>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	da8080e7          	jalr	-600(ra) # 8000053e <panic>
    return -1;
    8000479e:	597d                	li	s2,-1
    800047a0:	b765                	j	80004748 <fileread+0x60>
      return -1;
    800047a2:	597d                	li	s2,-1
    800047a4:	b755                	j	80004748 <fileread+0x60>
    800047a6:	597d                	li	s2,-1
    800047a8:	b745                	j	80004748 <fileread+0x60>

00000000800047aa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800047aa:	715d                	addi	sp,sp,-80
    800047ac:	e486                	sd	ra,72(sp)
    800047ae:	e0a2                	sd	s0,64(sp)
    800047b0:	fc26                	sd	s1,56(sp)
    800047b2:	f84a                	sd	s2,48(sp)
    800047b4:	f44e                	sd	s3,40(sp)
    800047b6:	f052                	sd	s4,32(sp)
    800047b8:	ec56                	sd	s5,24(sp)
    800047ba:	e85a                	sd	s6,16(sp)
    800047bc:	e45e                	sd	s7,8(sp)
    800047be:	e062                	sd	s8,0(sp)
    800047c0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047c2:	00954783          	lbu	a5,9(a0)
    800047c6:	10078663          	beqz	a5,800048d2 <filewrite+0x128>
    800047ca:	892a                	mv	s2,a0
    800047cc:	8aae                	mv	s5,a1
    800047ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d0:	411c                	lw	a5,0(a0)
    800047d2:	4705                	li	a4,1
    800047d4:	02e78263          	beq	a5,a4,800047f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047d8:	470d                	li	a4,3
    800047da:	02e78663          	beq	a5,a4,80004806 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047de:	4709                	li	a4,2
    800047e0:	0ee79163          	bne	a5,a4,800048c2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047e4:	0ac05d63          	blez	a2,8000489e <filewrite+0xf4>
    int i = 0;
    800047e8:	4981                	li	s3,0
    800047ea:	6b05                	lui	s6,0x1
    800047ec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047f0:	6b85                	lui	s7,0x1
    800047f2:	c00b8b9b          	addiw	s7,s7,-1024
    800047f6:	a861                	j	8000488e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047f8:	6908                	ld	a0,16(a0)
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	22e080e7          	jalr	558(ra) # 80004a28 <pipewrite>
    80004802:	8a2a                	mv	s4,a0
    80004804:	a045                	j	800048a4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004806:	02451783          	lh	a5,36(a0)
    8000480a:	03079693          	slli	a3,a5,0x30
    8000480e:	92c1                	srli	a3,a3,0x30
    80004810:	4725                	li	a4,9
    80004812:	0cd76263          	bltu	a4,a3,800048d6 <filewrite+0x12c>
    80004816:	0792                	slli	a5,a5,0x4
    80004818:	00024717          	auipc	a4,0x24
    8000481c:	b0070713          	addi	a4,a4,-1280 # 80028318 <devsw>
    80004820:	97ba                	add	a5,a5,a4
    80004822:	679c                	ld	a5,8(a5)
    80004824:	cbdd                	beqz	a5,800048da <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004826:	4505                	li	a0,1
    80004828:	9782                	jalr	a5
    8000482a:	8a2a                	mv	s4,a0
    8000482c:	a8a5                	j	800048a4 <filewrite+0xfa>
    8000482e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004832:	00000097          	auipc	ra,0x0
    80004836:	8b0080e7          	jalr	-1872(ra) # 800040e2 <begin_op>
      ilock(f->ip);
    8000483a:	01893503          	ld	a0,24(s2)
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	ed2080e7          	jalr	-302(ra) # 80003710 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004846:	8762                	mv	a4,s8
    80004848:	02092683          	lw	a3,32(s2)
    8000484c:	01598633          	add	a2,s3,s5
    80004850:	4585                	li	a1,1
    80004852:	01893503          	ld	a0,24(s2)
    80004856:	fffff097          	auipc	ra,0xfffff
    8000485a:	266080e7          	jalr	614(ra) # 80003abc <writei>
    8000485e:	84aa                	mv	s1,a0
    80004860:	00a05763          	blez	a0,8000486e <filewrite+0xc4>
        f->off += r;
    80004864:	02092783          	lw	a5,32(s2)
    80004868:	9fa9                	addw	a5,a5,a0
    8000486a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000486e:	01893503          	ld	a0,24(s2)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	f60080e7          	jalr	-160(ra) # 800037d2 <iunlock>
      end_op();
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	8e8080e7          	jalr	-1816(ra) # 80004162 <end_op>

      if(r != n1){
    80004882:	009c1f63          	bne	s8,s1,800048a0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004886:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000488a:	0149db63          	bge	s3,s4,800048a0 <filewrite+0xf6>
      int n1 = n - i;
    8000488e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004892:	84be                	mv	s1,a5
    80004894:	2781                	sext.w	a5,a5
    80004896:	f8fb5ce3          	bge	s6,a5,8000482e <filewrite+0x84>
    8000489a:	84de                	mv	s1,s7
    8000489c:	bf49                	j	8000482e <filewrite+0x84>
    int i = 0;
    8000489e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048a0:	013a1f63          	bne	s4,s3,800048be <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048a4:	8552                	mv	a0,s4
    800048a6:	60a6                	ld	ra,72(sp)
    800048a8:	6406                	ld	s0,64(sp)
    800048aa:	74e2                	ld	s1,56(sp)
    800048ac:	7942                	ld	s2,48(sp)
    800048ae:	79a2                	ld	s3,40(sp)
    800048b0:	7a02                	ld	s4,32(sp)
    800048b2:	6ae2                	ld	s5,24(sp)
    800048b4:	6b42                	ld	s6,16(sp)
    800048b6:	6ba2                	ld	s7,8(sp)
    800048b8:	6c02                	ld	s8,0(sp)
    800048ba:	6161                	addi	sp,sp,80
    800048bc:	8082                	ret
    ret = (i == n ? n : -1);
    800048be:	5a7d                	li	s4,-1
    800048c0:	b7d5                	j	800048a4 <filewrite+0xfa>
    panic("filewrite");
    800048c2:	00008517          	auipc	a0,0x8
    800048c6:	fce50513          	addi	a0,a0,-50 # 8000c890 <syscalls+0x278>
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	c74080e7          	jalr	-908(ra) # 8000053e <panic>
    return -1;
    800048d2:	5a7d                	li	s4,-1
    800048d4:	bfc1                	j	800048a4 <filewrite+0xfa>
      return -1;
    800048d6:	5a7d                	li	s4,-1
    800048d8:	b7f1                	j	800048a4 <filewrite+0xfa>
    800048da:	5a7d                	li	s4,-1
    800048dc:	b7e1                	j	800048a4 <filewrite+0xfa>

00000000800048de <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048de:	7179                	addi	sp,sp,-48
    800048e0:	f406                	sd	ra,40(sp)
    800048e2:	f022                	sd	s0,32(sp)
    800048e4:	ec26                	sd	s1,24(sp)
    800048e6:	e84a                	sd	s2,16(sp)
    800048e8:	e44e                	sd	s3,8(sp)
    800048ea:	e052                	sd	s4,0(sp)
    800048ec:	1800                	addi	s0,sp,48
    800048ee:	84aa                	mv	s1,a0
    800048f0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048f2:	0005b023          	sd	zero,0(a1)
    800048f6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	bf8080e7          	jalr	-1032(ra) # 800044f2 <filealloc>
    80004902:	e088                	sd	a0,0(s1)
    80004904:	c551                	beqz	a0,80004990 <pipealloc+0xb2>
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	bec080e7          	jalr	-1044(ra) # 800044f2 <filealloc>
    8000490e:	00aa3023          	sd	a0,0(s4)
    80004912:	c92d                	beqz	a0,80004984 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	1e0080e7          	jalr	480(ra) # 80000af4 <kalloc>
    8000491c:	892a                	mv	s2,a0
    8000491e:	c125                	beqz	a0,8000497e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004920:	4985                	li	s3,1
    80004922:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004926:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000492a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000492e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004932:	00008597          	auipc	a1,0x8
    80004936:	f6e58593          	addi	a1,a1,-146 # 8000c8a0 <syscalls+0x288>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	21a080e7          	jalr	538(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004942:	609c                	ld	a5,0(s1)
    80004944:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004948:	609c                	ld	a5,0(s1)
    8000494a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000494e:	609c                	ld	a5,0(s1)
    80004950:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004954:	609c                	ld	a5,0(s1)
    80004956:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000495a:	000a3783          	ld	a5,0(s4)
    8000495e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004962:	000a3783          	ld	a5,0(s4)
    80004966:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000496a:	000a3783          	ld	a5,0(s4)
    8000496e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004972:	000a3783          	ld	a5,0(s4)
    80004976:	0127b823          	sd	s2,16(a5)
  return 0;
    8000497a:	4501                	li	a0,0
    8000497c:	a025                	j	800049a4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000497e:	6088                	ld	a0,0(s1)
    80004980:	e501                	bnez	a0,80004988 <pipealloc+0xaa>
    80004982:	a039                	j	80004990 <pipealloc+0xb2>
    80004984:	6088                	ld	a0,0(s1)
    80004986:	c51d                	beqz	a0,800049b4 <pipealloc+0xd6>
    fileclose(*f0);
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	c26080e7          	jalr	-986(ra) # 800045ae <fileclose>
  if(*f1)
    80004990:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004994:	557d                	li	a0,-1
  if(*f1)
    80004996:	c799                	beqz	a5,800049a4 <pipealloc+0xc6>
    fileclose(*f1);
    80004998:	853e                	mv	a0,a5
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	c14080e7          	jalr	-1004(ra) # 800045ae <fileclose>
  return -1;
    800049a2:	557d                	li	a0,-1
}
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6a02                	ld	s4,0(sp)
    800049b0:	6145                	addi	sp,sp,48
    800049b2:	8082                	ret
  return -1;
    800049b4:	557d                	li	a0,-1
    800049b6:	b7fd                	j	800049a4 <pipealloc+0xc6>

00000000800049b8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049b8:	1101                	addi	sp,sp,-32
    800049ba:	ec06                	sd	ra,24(sp)
    800049bc:	e822                	sd	s0,16(sp)
    800049be:	e426                	sd	s1,8(sp)
    800049c0:	e04a                	sd	s2,0(sp)
    800049c2:	1000                	addi	s0,sp,32
    800049c4:	84aa                	mv	s1,a0
    800049c6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	21c080e7          	jalr	540(ra) # 80000be4 <acquire>
  if(writable){
    800049d0:	02090d63          	beqz	s2,80004a0a <pipeclose+0x52>
    pi->writeopen = 0;
    800049d4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049d8:	21848513          	addi	a0,s1,536
    800049dc:	ffffe097          	auipc	ra,0xffffe
    800049e0:	930080e7          	jalr	-1744(ra) # 8000230c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049e4:	2204b783          	ld	a5,544(s1)
    800049e8:	eb95                	bnez	a5,80004a1c <pipeclose+0x64>
    release(&pi->lock);
    800049ea:	8526                	mv	a0,s1
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	2ac080e7          	jalr	684(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049f4:	8526                	mv	a0,s1
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	002080e7          	jalr	2(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6902                	ld	s2,0(sp)
    80004a06:	6105                	addi	sp,sp,32
    80004a08:	8082                	ret
    pi->readopen = 0;
    80004a0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a0e:	21c48513          	addi	a0,s1,540
    80004a12:	ffffe097          	auipc	ra,0xffffe
    80004a16:	8fa080e7          	jalr	-1798(ra) # 8000230c <wakeup>
    80004a1a:	b7e9                	j	800049e4 <pipeclose+0x2c>
    release(&pi->lock);
    80004a1c:	8526                	mv	a0,s1
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	27a080e7          	jalr	634(ra) # 80000c98 <release>
}
    80004a26:	bfe1                	j	800049fe <pipeclose+0x46>

0000000080004a28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a28:	7159                	addi	sp,sp,-112
    80004a2a:	f486                	sd	ra,104(sp)
    80004a2c:	f0a2                	sd	s0,96(sp)
    80004a2e:	eca6                	sd	s1,88(sp)
    80004a30:	e8ca                	sd	s2,80(sp)
    80004a32:	e4ce                	sd	s3,72(sp)
    80004a34:	e0d2                	sd	s4,64(sp)
    80004a36:	fc56                	sd	s5,56(sp)
    80004a38:	f85a                	sd	s6,48(sp)
    80004a3a:	f45e                	sd	s7,40(sp)
    80004a3c:	f062                	sd	s8,32(sp)
    80004a3e:	ec66                	sd	s9,24(sp)
    80004a40:	1880                	addi	s0,sp,112
    80004a42:	84aa                	mv	s1,a0
    80004a44:	8aae                	mv	s5,a1
    80004a46:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	048080e7          	jalr	72(ra) # 80001a90 <myproc>
    80004a50:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
  while(i < n){
    80004a5c:	0d405163          	blez	s4,80004b1e <pipewrite+0xf6>
    80004a60:	8ba6                	mv	s7,s1
  int i = 0;
    80004a62:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a64:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a66:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a6a:	21c48c13          	addi	s8,s1,540
    80004a6e:	a08d                	j	80004ad0 <pipewrite+0xa8>
      release(&pi->lock);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	226080e7          	jalr	550(ra) # 80000c98 <release>
      return -1;
    80004a7a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a7c:	854a                	mv	a0,s2
    80004a7e:	70a6                	ld	ra,104(sp)
    80004a80:	7406                	ld	s0,96(sp)
    80004a82:	64e6                	ld	s1,88(sp)
    80004a84:	6946                	ld	s2,80(sp)
    80004a86:	69a6                	ld	s3,72(sp)
    80004a88:	6a06                	ld	s4,64(sp)
    80004a8a:	7ae2                	ld	s5,56(sp)
    80004a8c:	7b42                	ld	s6,48(sp)
    80004a8e:	7ba2                	ld	s7,40(sp)
    80004a90:	7c02                	ld	s8,32(sp)
    80004a92:	6ce2                	ld	s9,24(sp)
    80004a94:	6165                	addi	sp,sp,112
    80004a96:	8082                	ret
      wakeup(&pi->nread);
    80004a98:	8566                	mv	a0,s9
    80004a9a:	ffffe097          	auipc	ra,0xffffe
    80004a9e:	872080e7          	jalr	-1934(ra) # 8000230c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aa2:	85de                	mv	a1,s7
    80004aa4:	8562                	mv	a0,s8
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	6da080e7          	jalr	1754(ra) # 80002180 <sleep>
    80004aae:	a839                	j	80004acc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ab0:	21c4a783          	lw	a5,540(s1)
    80004ab4:	0017871b          	addiw	a4,a5,1
    80004ab8:	20e4ae23          	sw	a4,540(s1)
    80004abc:	1ff7f793          	andi	a5,a5,511
    80004ac0:	97a6                	add	a5,a5,s1
    80004ac2:	f9f44703          	lbu	a4,-97(s0)
    80004ac6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aca:	2905                	addiw	s2,s2,1
  while(i < n){
    80004acc:	03495d63          	bge	s2,s4,80004b06 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ad0:	2204a783          	lw	a5,544(s1)
    80004ad4:	dfd1                	beqz	a5,80004a70 <pipewrite+0x48>
    80004ad6:	0289a783          	lw	a5,40(s3)
    80004ada:	fbd9                	bnez	a5,80004a70 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004adc:	2184a783          	lw	a5,536(s1)
    80004ae0:	21c4a703          	lw	a4,540(s1)
    80004ae4:	2007879b          	addiw	a5,a5,512
    80004ae8:	faf708e3          	beq	a4,a5,80004a98 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aec:	4685                	li	a3,1
    80004aee:	01590633          	add	a2,s2,s5
    80004af2:	f9f40593          	addi	a1,s0,-97
    80004af6:	0509b503          	ld	a0,80(s3)
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	ce4080e7          	jalr	-796(ra) # 800017de <copyin>
    80004b02:	fb6517e3          	bne	a0,s6,80004ab0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b06:	21848513          	addi	a0,s1,536
    80004b0a:	ffffe097          	auipc	ra,0xffffe
    80004b0e:	802080e7          	jalr	-2046(ra) # 8000230c <wakeup>
  release(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	184080e7          	jalr	388(ra) # 80000c98 <release>
  return i;
    80004b1c:	b785                	j	80004a7c <pipewrite+0x54>
  int i = 0;
    80004b1e:	4901                	li	s2,0
    80004b20:	b7dd                	j	80004b06 <pipewrite+0xde>

0000000080004b22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b22:	715d                	addi	sp,sp,-80
    80004b24:	e486                	sd	ra,72(sp)
    80004b26:	e0a2                	sd	s0,64(sp)
    80004b28:	fc26                	sd	s1,56(sp)
    80004b2a:	f84a                	sd	s2,48(sp)
    80004b2c:	f44e                	sd	s3,40(sp)
    80004b2e:	f052                	sd	s4,32(sp)
    80004b30:	ec56                	sd	s5,24(sp)
    80004b32:	e85a                	sd	s6,16(sp)
    80004b34:	0880                	addi	s0,sp,80
    80004b36:	84aa                	mv	s1,a0
    80004b38:	892e                	mv	s2,a1
    80004b3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	f54080e7          	jalr	-172(ra) # 80001a90 <myproc>
    80004b44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b46:	8b26                	mv	s6,s1
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b52:	2184a703          	lw	a4,536(s1)
    80004b56:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b5a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5e:	02f71463          	bne	a4,a5,80004b86 <piperead+0x64>
    80004b62:	2244a783          	lw	a5,548(s1)
    80004b66:	c385                	beqz	a5,80004b86 <piperead+0x64>
    if(pr->killed){
    80004b68:	028a2783          	lw	a5,40(s4)
    80004b6c:	ebc1                	bnez	a5,80004bfc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b6e:	85da                	mv	a1,s6
    80004b70:	854e                	mv	a0,s3
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	60e080e7          	jalr	1550(ra) # 80002180 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b7a:	2184a703          	lw	a4,536(s1)
    80004b7e:	21c4a783          	lw	a5,540(s1)
    80004b82:	fef700e3          	beq	a4,a5,80004b62 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b86:	09505263          	blez	s5,80004c0a <piperead+0xe8>
    80004b8a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b8c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b8e:	2184a783          	lw	a5,536(s1)
    80004b92:	21c4a703          	lw	a4,540(s1)
    80004b96:	02f70d63          	beq	a4,a5,80004bd0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b9a:	0017871b          	addiw	a4,a5,1
    80004b9e:	20e4ac23          	sw	a4,536(s1)
    80004ba2:	1ff7f793          	andi	a5,a5,511
    80004ba6:	97a6                	add	a5,a5,s1
    80004ba8:	0187c783          	lbu	a5,24(a5)
    80004bac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bb0:	4685                	li	a3,1
    80004bb2:	fbf40613          	addi	a2,s0,-65
    80004bb6:	85ca                	mv	a1,s2
    80004bb8:	050a3503          	ld	a0,80(s4)
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	b96080e7          	jalr	-1130(ra) # 80001752 <copyout>
    80004bc4:	01650663          	beq	a0,s6,80004bd0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc8:	2985                	addiw	s3,s3,1
    80004bca:	0905                	addi	s2,s2,1
    80004bcc:	fd3a91e3          	bne	s5,s3,80004b8e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bd0:	21c48513          	addi	a0,s1,540
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	738080e7          	jalr	1848(ra) # 8000230c <wakeup>
  release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
  return i;
}
    80004be6:	854e                	mv	a0,s3
    80004be8:	60a6                	ld	ra,72(sp)
    80004bea:	6406                	ld	s0,64(sp)
    80004bec:	74e2                	ld	s1,56(sp)
    80004bee:	7942                	ld	s2,48(sp)
    80004bf0:	79a2                	ld	s3,40(sp)
    80004bf2:	7a02                	ld	s4,32(sp)
    80004bf4:	6ae2                	ld	s5,24(sp)
    80004bf6:	6b42                	ld	s6,16(sp)
    80004bf8:	6161                	addi	sp,sp,80
    80004bfa:	8082                	ret
      release(&pi->lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
      return -1;
    80004c06:	59fd                	li	s3,-1
    80004c08:	bff9                	j	80004be6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0a:	4981                	li	s3,0
    80004c0c:	b7d1                	j	80004bd0 <piperead+0xae>

0000000080004c0e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c0e:	df010113          	addi	sp,sp,-528
    80004c12:	20113423          	sd	ra,520(sp)
    80004c16:	20813023          	sd	s0,512(sp)
    80004c1a:	ffa6                	sd	s1,504(sp)
    80004c1c:	fbca                	sd	s2,496(sp)
    80004c1e:	f7ce                	sd	s3,488(sp)
    80004c20:	f3d2                	sd	s4,480(sp)
    80004c22:	efd6                	sd	s5,472(sp)
    80004c24:	ebda                	sd	s6,464(sp)
    80004c26:	e7de                	sd	s7,456(sp)
    80004c28:	e3e2                	sd	s8,448(sp)
    80004c2a:	ff66                	sd	s9,440(sp)
    80004c2c:	fb6a                	sd	s10,432(sp)
    80004c2e:	f76e                	sd	s11,424(sp)
    80004c30:	0c00                	addi	s0,sp,528
    80004c32:	84aa                	mv	s1,a0
    80004c34:	dea43c23          	sd	a0,-520(s0)
    80004c38:	e0b43023          	sd	a1,-512(s0)
  printf("exec %s , %s\n",path, argv[0]);
    80004c3c:	6190                	ld	a2,0(a1)
    80004c3e:	85aa                	mv	a1,a0
    80004c40:	00008517          	auipc	a0,0x8
    80004c44:	c6850513          	addi	a0,a0,-920 # 8000c8a8 <syscalls+0x290>
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	940080e7          	jalr	-1728(ra) # 80000588 <printf>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	e40080e7          	jalr	-448(ra) # 80001a90 <myproc>
    80004c58:	892a                	mv	s2,a0

  begin_op();
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	488080e7          	jalr	1160(ra) # 800040e2 <begin_op>

  if((ip = namei(path)) == 0){
    80004c62:	8526                	mv	a0,s1
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	262080e7          	jalr	610(ra) # 80003ec6 <namei>
    80004c6c:	c92d                	beqz	a0,80004cde <exec+0xd0>
    80004c6e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	aa0080e7          	jalr	-1376(ra) # 80003710 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c78:	04000713          	li	a4,64
    80004c7c:	4681                	li	a3,0
    80004c7e:	e5040613          	addi	a2,s0,-432
    80004c82:	4581                	li	a1,0
    80004c84:	8526                	mv	a0,s1
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	d3e080e7          	jalr	-706(ra) # 800039c4 <readi>
    80004c8e:	04000793          	li	a5,64
    80004c92:	00f51a63          	bne	a0,a5,80004ca6 <exec+0x98>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c96:	e5042703          	lw	a4,-432(s0)
    80004c9a:	464c47b7          	lui	a5,0x464c4
    80004c9e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ca2:	04f70463          	beq	a4,a5,80004cea <exec+0xdc>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ca6:	8526                	mv	a0,s1
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	cca080e7          	jalr	-822(ra) # 80003972 <iunlockput>
    end_op();
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	4b2080e7          	jalr	1202(ra) # 80004162 <end_op>
  }
  return -1;
    80004cb8:	557d                	li	a0,-1
}
    80004cba:	20813083          	ld	ra,520(sp)
    80004cbe:	20013403          	ld	s0,512(sp)
    80004cc2:	74fe                	ld	s1,504(sp)
    80004cc4:	795e                	ld	s2,496(sp)
    80004cc6:	79be                	ld	s3,488(sp)
    80004cc8:	7a1e                	ld	s4,480(sp)
    80004cca:	6afe                	ld	s5,472(sp)
    80004ccc:	6b5e                	ld	s6,464(sp)
    80004cce:	6bbe                	ld	s7,456(sp)
    80004cd0:	6c1e                	ld	s8,448(sp)
    80004cd2:	7cfa                	ld	s9,440(sp)
    80004cd4:	7d5a                	ld	s10,432(sp)
    80004cd6:	7dba                	ld	s11,424(sp)
    80004cd8:	21010113          	addi	sp,sp,528
    80004cdc:	8082                	ret
    end_op();
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	484080e7          	jalr	1156(ra) # 80004162 <end_op>
    return -1;
    80004ce6:	557d                	li	a0,-1
    80004ce8:	bfc9                	j	80004cba <exec+0xac>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cea:	854a                	mv	a0,s2
    80004cec:	ffffd097          	auipc	ra,0xffffd
    80004cf0:	e68080e7          	jalr	-408(ra) # 80001b54 <proc_pagetable>
    80004cf4:	8baa                	mv	s7,a0
    80004cf6:	d945                	beqz	a0,80004ca6 <exec+0x98>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf8:	e7042983          	lw	s3,-400(s0)
    80004cfc:	e8845783          	lhu	a5,-376(s0)
    80004d00:	c7ad                	beqz	a5,80004d6a <exec+0x15c>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d02:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d04:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d06:	6c91                	lui	s9,0x4
    80004d08:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004d0c:	def43823          	sd	a5,-528(s0)
    80004d10:	a42d                	j	80004f3a <exec+0x32c>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d12:	00008517          	auipc	a0,0x8
    80004d16:	ba650513          	addi	a0,a0,-1114 # 8000c8b8 <syscalls+0x2a0>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	824080e7          	jalr	-2012(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d22:	8756                	mv	a4,s5
    80004d24:	012d86bb          	addw	a3,s11,s2
    80004d28:	4581                	li	a1,0
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	c98080e7          	jalr	-872(ra) # 800039c4 <readi>
    80004d34:	2501                	sext.w	a0,a0
    80004d36:	1aaa9963          	bne	s5,a0,80004ee8 <exec+0x2da>
  for(i = 0; i < sz; i += PGSIZE){
    80004d3a:	6791                	lui	a5,0x4
    80004d3c:	0127893b          	addw	s2,a5,s2
    80004d40:	77f1                	lui	a5,0xffffc
    80004d42:	01478a3b          	addw	s4,a5,s4
    80004d46:	1f897163          	bgeu	s2,s8,80004f28 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004d4a:	02091593          	slli	a1,s2,0x20
    80004d4e:	9181                	srli	a1,a1,0x20
    80004d50:	95ea                	add	a1,a1,s10
    80004d52:	855e                	mv	a0,s7
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	36c080e7          	jalr	876(ra) # 800010c0 <walkaddr>
    80004d5c:	862a                	mv	a2,a0
    if(pa == 0)
    80004d5e:	d955                	beqz	a0,80004d12 <exec+0x104>
      n = PGSIZE;
    80004d60:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d62:	fd9a70e3          	bgeu	s4,s9,80004d22 <exec+0x114>
      n = sz - i;
    80004d66:	8ad2                	mv	s5,s4
    80004d68:	bf6d                	j	80004d22 <exec+0x114>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d6a:	4901                	li	s2,0
  iunlockput(ip);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	c04080e7          	jalr	-1020(ra) # 80003972 <iunlockput>
  end_op();
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	3ec080e7          	jalr	1004(ra) # 80004162 <end_op>
  p = myproc();
    80004d7e:	ffffd097          	auipc	ra,0xffffd
    80004d82:	d12080e7          	jalr	-750(ra) # 80001a90 <myproc>
    80004d86:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d88:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d8c:	6791                	lui	a5,0x4
    80004d8e:	17fd                	addi	a5,a5,-1
    80004d90:	993e                	add	s2,s2,a5
    80004d92:	7571                	lui	a0,0xffffc
    80004d94:	00a977b3          	and	a5,s2,a0
    80004d98:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d9c:	6621                	lui	a2,0x8
    80004d9e:	963e                	add	a2,a2,a5
    80004da0:	85be                	mv	a1,a5
    80004da2:	855e                	mv	a0,s7
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	75e080e7          	jalr	1886(ra) # 80001502 <uvmalloc>
    80004dac:	8b2a                	mv	s6,a0
  ip = 0;
    80004dae:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004db0:	12050c63          	beqz	a0,80004ee8 <exec+0x2da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004db4:	75e1                	lui	a1,0xffff8
    80004db6:	95aa                	add	a1,a1,a0
    80004db8:	855e                	mv	a0,s7
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	966080e7          	jalr	-1690(ra) # 80001720 <uvmclear>
  stackbase = sp - PGSIZE;
    80004dc2:	7c71                	lui	s8,0xffffc
    80004dc4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dc6:	e0043783          	ld	a5,-512(s0)
    80004dca:	6388                	ld	a0,0(a5)
    80004dcc:	c535                	beqz	a0,80004e38 <exec+0x22a>
    80004dce:	e9040993          	addi	s3,s0,-368
    80004dd2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004dd6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	08c080e7          	jalr	140(ra) # 80000e64 <strlen>
    80004de0:	2505                	addiw	a0,a0,1
    80004de2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004de6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004dea:	13896363          	bltu	s2,s8,80004f10 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dee:	e0043d83          	ld	s11,-512(s0)
    80004df2:	000dba03          	ld	s4,0(s11)
    80004df6:	8552                	mv	a0,s4
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	06c080e7          	jalr	108(ra) # 80000e64 <strlen>
    80004e00:	0015069b          	addiw	a3,a0,1
    80004e04:	8652                	mv	a2,s4
    80004e06:	85ca                	mv	a1,s2
    80004e08:	855e                	mv	a0,s7
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	948080e7          	jalr	-1720(ra) # 80001752 <copyout>
    80004e12:	10054363          	bltz	a0,80004f18 <exec+0x30a>
    ustack[argc] = sp;
    80004e16:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e1a:	0485                	addi	s1,s1,1
    80004e1c:	008d8793          	addi	a5,s11,8
    80004e20:	e0f43023          	sd	a5,-512(s0)
    80004e24:	008db503          	ld	a0,8(s11)
    80004e28:	c911                	beqz	a0,80004e3c <exec+0x22e>
    if(argc >= MAXARG)
    80004e2a:	09a1                	addi	s3,s3,8
    80004e2c:	fb3c96e3          	bne	s9,s3,80004dd8 <exec+0x1ca>
  sz = sz1;
    80004e30:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e34:	4481                	li	s1,0
    80004e36:	a84d                	j	80004ee8 <exec+0x2da>
  sp = sz;
    80004e38:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e3a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e3c:	00349793          	slli	a5,s1,0x3
    80004e40:	f9040713          	addi	a4,s0,-112
    80004e44:	97ba                	add	a5,a5,a4
    80004e46:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004e4a:	00148693          	addi	a3,s1,1
    80004e4e:	068e                	slli	a3,a3,0x3
    80004e50:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e54:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e58:	01897663          	bgeu	s2,s8,80004e64 <exec+0x256>
  sz = sz1;
    80004e5c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e60:	4481                	li	s1,0
    80004e62:	a059                	j	80004ee8 <exec+0x2da>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e64:	e9040613          	addi	a2,s0,-368
    80004e68:	85ca                	mv	a1,s2
    80004e6a:	855e                	mv	a0,s7
    80004e6c:	ffffd097          	auipc	ra,0xffffd
    80004e70:	8e6080e7          	jalr	-1818(ra) # 80001752 <copyout>
    80004e74:	0a054663          	bltz	a0,80004f20 <exec+0x312>
  p->trapframe->a1 = sp;
    80004e78:	058ab783          	ld	a5,88(s5)
    80004e7c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e80:	df843783          	ld	a5,-520(s0)
    80004e84:	0007c703          	lbu	a4,0(a5)
    80004e88:	cf11                	beqz	a4,80004ea4 <exec+0x296>
    80004e8a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e8c:	02f00693          	li	a3,47
    80004e90:	a039                	j	80004e9e <exec+0x290>
      last = s+1;
    80004e92:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e96:	0785                	addi	a5,a5,1
    80004e98:	fff7c703          	lbu	a4,-1(a5)
    80004e9c:	c701                	beqz	a4,80004ea4 <exec+0x296>
    if(*s == '/')
    80004e9e:	fed71ce3          	bne	a4,a3,80004e96 <exec+0x288>
    80004ea2:	bfc5                	j	80004e92 <exec+0x284>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ea4:	4641                	li	a2,16
    80004ea6:	df843583          	ld	a1,-520(s0)
    80004eaa:	158a8513          	addi	a0,s5,344
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	f84080e7          	jalr	-124(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004eb6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004eba:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ebe:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ec2:	058ab783          	ld	a5,88(s5)
    80004ec6:	e6843703          	ld	a4,-408(s0)
    80004eca:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ecc:	058ab783          	ld	a5,88(s5)
    80004ed0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ed4:	85ea                	mv	a1,s10
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	d1a080e7          	jalr	-742(ra) # 80001bf0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ede:	0004851b          	sext.w	a0,s1
    80004ee2:	bbe1                	j	80004cba <exec+0xac>
    80004ee4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004ee8:	e0843583          	ld	a1,-504(s0)
    80004eec:	855e                	mv	a0,s7
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	d02080e7          	jalr	-766(ra) # 80001bf0 <proc_freepagetable>
  if(ip){
    80004ef6:	da0498e3          	bnez	s1,80004ca6 <exec+0x98>
  return -1;
    80004efa:	557d                	li	a0,-1
    80004efc:	bb7d                	j	80004cba <exec+0xac>
    80004efe:	e1243423          	sd	s2,-504(s0)
    80004f02:	b7dd                	j	80004ee8 <exec+0x2da>
    80004f04:	e1243423          	sd	s2,-504(s0)
    80004f08:	b7c5                	j	80004ee8 <exec+0x2da>
    80004f0a:	e1243423          	sd	s2,-504(s0)
    80004f0e:	bfe9                	j	80004ee8 <exec+0x2da>
  sz = sz1;
    80004f10:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f14:	4481                	li	s1,0
    80004f16:	bfc9                	j	80004ee8 <exec+0x2da>
  sz = sz1;
    80004f18:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f1c:	4481                	li	s1,0
    80004f1e:	b7e9                	j	80004ee8 <exec+0x2da>
  sz = sz1;
    80004f20:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f24:	4481                	li	s1,0
    80004f26:	b7c9                	j	80004ee8 <exec+0x2da>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f28:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f2c:	2b05                	addiw	s6,s6,1
    80004f2e:	0389899b          	addiw	s3,s3,56
    80004f32:	e8845783          	lhu	a5,-376(s0)
    80004f36:	e2fb5be3          	bge	s6,a5,80004d6c <exec+0x15e>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f3a:	2981                	sext.w	s3,s3
    80004f3c:	03800713          	li	a4,56
    80004f40:	86ce                	mv	a3,s3
    80004f42:	e1840613          	addi	a2,s0,-488
    80004f46:	4581                	li	a1,0
    80004f48:	8526                	mv	a0,s1
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	a7a080e7          	jalr	-1414(ra) # 800039c4 <readi>
    80004f52:	03800793          	li	a5,56
    80004f56:	f8f517e3          	bne	a0,a5,80004ee4 <exec+0x2d6>
    if(ph.type != ELF_PROG_LOAD)
    80004f5a:	e1842783          	lw	a5,-488(s0)
    80004f5e:	4705                	li	a4,1
    80004f60:	fce796e3          	bne	a5,a4,80004f2c <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004f64:	e4043603          	ld	a2,-448(s0)
    80004f68:	e3843783          	ld	a5,-456(s0)
    80004f6c:	f8f669e3          	bltu	a2,a5,80004efe <exec+0x2f0>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f70:	e2843783          	ld	a5,-472(s0)
    80004f74:	963e                	add	a2,a2,a5
    80004f76:	f8f667e3          	bltu	a2,a5,80004f04 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f7a:	85ca                	mv	a1,s2
    80004f7c:	855e                	mv	a0,s7
    80004f7e:	ffffc097          	auipc	ra,0xffffc
    80004f82:	584080e7          	jalr	1412(ra) # 80001502 <uvmalloc>
    80004f86:	e0a43423          	sd	a0,-504(s0)
    80004f8a:	d141                	beqz	a0,80004f0a <exec+0x2fc>
    if((ph.vaddr % PGSIZE) != 0)
    80004f8c:	e2843d03          	ld	s10,-472(s0)
    80004f90:	df043783          	ld	a5,-528(s0)
    80004f94:	00fd77b3          	and	a5,s10,a5
    80004f98:	fba1                	bnez	a5,80004ee8 <exec+0x2da>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f9a:	e2042d83          	lw	s11,-480(s0)
    80004f9e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa2:	f80c03e3          	beqz	s8,80004f28 <exec+0x31a>
    80004fa6:	8a62                	mv	s4,s8
    80004fa8:	4901                	li	s2,0
    80004faa:	b345                	j	80004d4a <exec+0x13c>

0000000080004fac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fac:	7179                	addi	sp,sp,-48
    80004fae:	f406                	sd	ra,40(sp)
    80004fb0:	f022                	sd	s0,32(sp)
    80004fb2:	ec26                	sd	s1,24(sp)
    80004fb4:	e84a                	sd	s2,16(sp)
    80004fb6:	1800                	addi	s0,sp,48
    80004fb8:	892e                	mv	s2,a1
    80004fba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fbc:	fdc40593          	addi	a1,s0,-36
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	bcc080e7          	jalr	-1076(ra) # 80002b8c <argint>
    80004fc8:	04054063          	bltz	a0,80005008 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fcc:	fdc42703          	lw	a4,-36(s0)
    80004fd0:	47bd                	li	a5,15
    80004fd2:	02e7ed63          	bltu	a5,a4,8000500c <argfd+0x60>
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	aba080e7          	jalr	-1350(ra) # 80001a90 <myproc>
    80004fde:	fdc42703          	lw	a4,-36(s0)
    80004fe2:	01a70793          	addi	a5,a4,26
    80004fe6:	078e                	slli	a5,a5,0x3
    80004fe8:	953e                	add	a0,a0,a5
    80004fea:	611c                	ld	a5,0(a0)
    80004fec:	c395                	beqz	a5,80005010 <argfd+0x64>
    return -1;
  if(pfd)
    80004fee:	00090463          	beqz	s2,80004ff6 <argfd+0x4a>
    *pfd = fd;
    80004ff2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ff6:	4501                	li	a0,0
  if(pf)
    80004ff8:	c091                	beqz	s1,80004ffc <argfd+0x50>
    *pf = f;
    80004ffa:	e09c                	sd	a5,0(s1)
}
    80004ffc:	70a2                	ld	ra,40(sp)
    80004ffe:	7402                	ld	s0,32(sp)
    80005000:	64e2                	ld	s1,24(sp)
    80005002:	6942                	ld	s2,16(sp)
    80005004:	6145                	addi	sp,sp,48
    80005006:	8082                	ret
    return -1;
    80005008:	557d                	li	a0,-1
    8000500a:	bfcd                	j	80004ffc <argfd+0x50>
    return -1;
    8000500c:	557d                	li	a0,-1
    8000500e:	b7fd                	j	80004ffc <argfd+0x50>
    80005010:	557d                	li	a0,-1
    80005012:	b7ed                	j	80004ffc <argfd+0x50>

0000000080005014 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005014:	1101                	addi	sp,sp,-32
    80005016:	ec06                	sd	ra,24(sp)
    80005018:	e822                	sd	s0,16(sp)
    8000501a:	e426                	sd	s1,8(sp)
    8000501c:	1000                	addi	s0,sp,32
    8000501e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	a70080e7          	jalr	-1424(ra) # 80001a90 <myproc>
    80005028:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000502a:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc40d0>
    8000502e:	4501                	li	a0,0
    80005030:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005032:	6398                	ld	a4,0(a5)
    80005034:	cb19                	beqz	a4,8000504a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005036:	2505                	addiw	a0,a0,1
    80005038:	07a1                	addi	a5,a5,8
    8000503a:	fed51ce3          	bne	a0,a3,80005032 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000503e:	557d                	li	a0,-1
}
    80005040:	60e2                	ld	ra,24(sp)
    80005042:	6442                	ld	s0,16(sp)
    80005044:	64a2                	ld	s1,8(sp)
    80005046:	6105                	addi	sp,sp,32
    80005048:	8082                	ret
      p->ofile[fd] = f;
    8000504a:	01a50793          	addi	a5,a0,26
    8000504e:	078e                	slli	a5,a5,0x3
    80005050:	963e                	add	a2,a2,a5
    80005052:	e204                	sd	s1,0(a2)
      return fd;
    80005054:	b7f5                	j	80005040 <fdalloc+0x2c>

0000000080005056 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005056:	715d                	addi	sp,sp,-80
    80005058:	e486                	sd	ra,72(sp)
    8000505a:	e0a2                	sd	s0,64(sp)
    8000505c:	fc26                	sd	s1,56(sp)
    8000505e:	f84a                	sd	s2,48(sp)
    80005060:	f44e                	sd	s3,40(sp)
    80005062:	f052                	sd	s4,32(sp)
    80005064:	ec56                	sd	s5,24(sp)
    80005066:	0880                	addi	s0,sp,80
    80005068:	89ae                	mv	s3,a1
    8000506a:	8ab2                	mv	s5,a2
    8000506c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000506e:	fb040593          	addi	a1,s0,-80
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	e72080e7          	jalr	-398(ra) # 80003ee4 <nameiparent>
    8000507a:	892a                	mv	s2,a0
    8000507c:	12050f63          	beqz	a0,800051ba <create+0x164>
    return 0;

  ilock(dp);
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	690080e7          	jalr	1680(ra) # 80003710 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005088:	4601                	li	a2,0
    8000508a:	fb040593          	addi	a1,s0,-80
    8000508e:	854a                	mv	a0,s2
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	b64080e7          	jalr	-1180(ra) # 80003bf4 <dirlookup>
    80005098:	84aa                	mv	s1,a0
    8000509a:	c921                	beqz	a0,800050ea <create+0x94>
    iunlockput(dp);
    8000509c:	854a                	mv	a0,s2
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	8d4080e7          	jalr	-1836(ra) # 80003972 <iunlockput>
    ilock(ip);
    800050a6:	8526                	mv	a0,s1
    800050a8:	ffffe097          	auipc	ra,0xffffe
    800050ac:	668080e7          	jalr	1640(ra) # 80003710 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050b0:	2981                	sext.w	s3,s3
    800050b2:	4789                	li	a5,2
    800050b4:	02f99463          	bne	s3,a5,800050dc <create+0x86>
    800050b8:	0444d783          	lhu	a5,68(s1)
    800050bc:	37f9                	addiw	a5,a5,-2
    800050be:	17c2                	slli	a5,a5,0x30
    800050c0:	93c1                	srli	a5,a5,0x30
    800050c2:	4705                	li	a4,1
    800050c4:	00f76c63          	bltu	a4,a5,800050dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050c8:	8526                	mv	a0,s1
    800050ca:	60a6                	ld	ra,72(sp)
    800050cc:	6406                	ld	s0,64(sp)
    800050ce:	74e2                	ld	s1,56(sp)
    800050d0:	7942                	ld	s2,48(sp)
    800050d2:	79a2                	ld	s3,40(sp)
    800050d4:	7a02                	ld	s4,32(sp)
    800050d6:	6ae2                	ld	s5,24(sp)
    800050d8:	6161                	addi	sp,sp,80
    800050da:	8082                	ret
    iunlockput(ip);
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	894080e7          	jalr	-1900(ra) # 80003972 <iunlockput>
    return 0;
    800050e6:	4481                	li	s1,0
    800050e8:	b7c5                	j	800050c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050ea:	85ce                	mv	a1,s3
    800050ec:	00092503          	lw	a0,0(s2)
    800050f0:	ffffe097          	auipc	ra,0xffffe
    800050f4:	488080e7          	jalr	1160(ra) # 80003578 <ialloc>
    800050f8:	84aa                	mv	s1,a0
    800050fa:	c529                	beqz	a0,80005144 <create+0xee>
  ilock(ip);
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	614080e7          	jalr	1556(ra) # 80003710 <ilock>
  ip->major = major;
    80005104:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005108:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000510c:	4785                	li	a5,1
    8000510e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	532080e7          	jalr	1330(ra) # 80003646 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000511c:	2981                	sext.w	s3,s3
    8000511e:	4785                	li	a5,1
    80005120:	02f98a63          	beq	s3,a5,80005154 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005124:	40d0                	lw	a2,4(s1)
    80005126:	fb040593          	addi	a1,s0,-80
    8000512a:	854a                	mv	a0,s2
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	cd8080e7          	jalr	-808(ra) # 80003e04 <dirlink>
    80005134:	06054b63          	bltz	a0,800051aa <create+0x154>
  iunlockput(dp);
    80005138:	854a                	mv	a0,s2
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	838080e7          	jalr	-1992(ra) # 80003972 <iunlockput>
  return ip;
    80005142:	b759                	j	800050c8 <create+0x72>
    panic("create: ialloc");
    80005144:	00007517          	auipc	a0,0x7
    80005148:	79450513          	addi	a0,a0,1940 # 8000c8d8 <syscalls+0x2c0>
    8000514c:	ffffb097          	auipc	ra,0xffffb
    80005150:	3f2080e7          	jalr	1010(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005154:	04a95783          	lhu	a5,74(s2)
    80005158:	2785                	addiw	a5,a5,1
    8000515a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000515e:	854a                	mv	a0,s2
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	4e6080e7          	jalr	1254(ra) # 80003646 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005168:	40d0                	lw	a2,4(s1)
    8000516a:	00007597          	auipc	a1,0x7
    8000516e:	77e58593          	addi	a1,a1,1918 # 8000c8e8 <syscalls+0x2d0>
    80005172:	8526                	mv	a0,s1
    80005174:	fffff097          	auipc	ra,0xfffff
    80005178:	c90080e7          	jalr	-880(ra) # 80003e04 <dirlink>
    8000517c:	00054f63          	bltz	a0,8000519a <create+0x144>
    80005180:	00492603          	lw	a2,4(s2)
    80005184:	00007597          	auipc	a1,0x7
    80005188:	76c58593          	addi	a1,a1,1900 # 8000c8f0 <syscalls+0x2d8>
    8000518c:	8526                	mv	a0,s1
    8000518e:	fffff097          	auipc	ra,0xfffff
    80005192:	c76080e7          	jalr	-906(ra) # 80003e04 <dirlink>
    80005196:	f80557e3          	bgez	a0,80005124 <create+0xce>
      panic("create dots");
    8000519a:	00007517          	auipc	a0,0x7
    8000519e:	75e50513          	addi	a0,a0,1886 # 8000c8f8 <syscalls+0x2e0>
    800051a2:	ffffb097          	auipc	ra,0xffffb
    800051a6:	39c080e7          	jalr	924(ra) # 8000053e <panic>
    panic("create: dirlink");
    800051aa:	00007517          	auipc	a0,0x7
    800051ae:	75e50513          	addi	a0,a0,1886 # 8000c908 <syscalls+0x2f0>
    800051b2:	ffffb097          	auipc	ra,0xffffb
    800051b6:	38c080e7          	jalr	908(ra) # 8000053e <panic>
    return 0;
    800051ba:	84aa                	mv	s1,a0
    800051bc:	b731                	j	800050c8 <create+0x72>

00000000800051be <sys_dup>:
{
    800051be:	7179                	addi	sp,sp,-48
    800051c0:	f406                	sd	ra,40(sp)
    800051c2:	f022                	sd	s0,32(sp)
    800051c4:	ec26                	sd	s1,24(sp)
    800051c6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051c8:	fd840613          	addi	a2,s0,-40
    800051cc:	4581                	li	a1,0
    800051ce:	4501                	li	a0,0
    800051d0:	00000097          	auipc	ra,0x0
    800051d4:	ddc080e7          	jalr	-548(ra) # 80004fac <argfd>
    return -1;
    800051d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051da:	02054363          	bltz	a0,80005200 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051de:	fd843503          	ld	a0,-40(s0)
    800051e2:	00000097          	auipc	ra,0x0
    800051e6:	e32080e7          	jalr	-462(ra) # 80005014 <fdalloc>
    800051ea:	84aa                	mv	s1,a0
    return -1;
    800051ec:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ee:	00054963          	bltz	a0,80005200 <sys_dup+0x42>
  filedup(f);
    800051f2:	fd843503          	ld	a0,-40(s0)
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	366080e7          	jalr	870(ra) # 8000455c <filedup>
  return fd;
    800051fe:	87a6                	mv	a5,s1
}
    80005200:	853e                	mv	a0,a5
    80005202:	70a2                	ld	ra,40(sp)
    80005204:	7402                	ld	s0,32(sp)
    80005206:	64e2                	ld	s1,24(sp)
    80005208:	6145                	addi	sp,sp,48
    8000520a:	8082                	ret

000000008000520c <sys_read>:
{
    8000520c:	7179                	addi	sp,sp,-48
    8000520e:	f406                	sd	ra,40(sp)
    80005210:	f022                	sd	s0,32(sp)
    80005212:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005214:	fe840613          	addi	a2,s0,-24
    80005218:	4581                	li	a1,0
    8000521a:	4501                	li	a0,0
    8000521c:	00000097          	auipc	ra,0x0
    80005220:	d90080e7          	jalr	-624(ra) # 80004fac <argfd>
    return -1;
    80005224:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005226:	04054163          	bltz	a0,80005268 <sys_read+0x5c>
    8000522a:	fe440593          	addi	a1,s0,-28
    8000522e:	4509                	li	a0,2
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	95c080e7          	jalr	-1700(ra) # 80002b8c <argint>
    return -1;
    80005238:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000523a:	02054763          	bltz	a0,80005268 <sys_read+0x5c>
    8000523e:	fd840593          	addi	a1,s0,-40
    80005242:	4505                	li	a0,1
    80005244:	ffffe097          	auipc	ra,0xffffe
    80005248:	96a080e7          	jalr	-1686(ra) # 80002bae <argaddr>
    return -1;
    8000524c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000524e:	00054d63          	bltz	a0,80005268 <sys_read+0x5c>
  return fileread(f, p, n);
    80005252:	fe442603          	lw	a2,-28(s0)
    80005256:	fd843583          	ld	a1,-40(s0)
    8000525a:	fe843503          	ld	a0,-24(s0)
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	48a080e7          	jalr	1162(ra) # 800046e8 <fileread>
    80005266:	87aa                	mv	a5,a0
}
    80005268:	853e                	mv	a0,a5
    8000526a:	70a2                	ld	ra,40(sp)
    8000526c:	7402                	ld	s0,32(sp)
    8000526e:	6145                	addi	sp,sp,48
    80005270:	8082                	ret

0000000080005272 <sys_write>:
{
    80005272:	7179                	addi	sp,sp,-48
    80005274:	f406                	sd	ra,40(sp)
    80005276:	f022                	sd	s0,32(sp)
    80005278:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527a:	fe840613          	addi	a2,s0,-24
    8000527e:	4581                	li	a1,0
    80005280:	4501                	li	a0,0
    80005282:	00000097          	auipc	ra,0x0
    80005286:	d2a080e7          	jalr	-726(ra) # 80004fac <argfd>
    return -1;
    8000528a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528c:	04054163          	bltz	a0,800052ce <sys_write+0x5c>
    80005290:	fe440593          	addi	a1,s0,-28
    80005294:	4509                	li	a0,2
    80005296:	ffffe097          	auipc	ra,0xffffe
    8000529a:	8f6080e7          	jalr	-1802(ra) # 80002b8c <argint>
    return -1;
    8000529e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a0:	02054763          	bltz	a0,800052ce <sys_write+0x5c>
    800052a4:	fd840593          	addi	a1,s0,-40
    800052a8:	4505                	li	a0,1
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	904080e7          	jalr	-1788(ra) # 80002bae <argaddr>
    return -1;
    800052b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b4:	00054d63          	bltz	a0,800052ce <sys_write+0x5c>
  return filewrite(f, p, n);
    800052b8:	fe442603          	lw	a2,-28(s0)
    800052bc:	fd843583          	ld	a1,-40(s0)
    800052c0:	fe843503          	ld	a0,-24(s0)
    800052c4:	fffff097          	auipc	ra,0xfffff
    800052c8:	4e6080e7          	jalr	1254(ra) # 800047aa <filewrite>
    800052cc:	87aa                	mv	a5,a0
}
    800052ce:	853e                	mv	a0,a5
    800052d0:	70a2                	ld	ra,40(sp)
    800052d2:	7402                	ld	s0,32(sp)
    800052d4:	6145                	addi	sp,sp,48
    800052d6:	8082                	ret

00000000800052d8 <sys_close>:
{
    800052d8:	1101                	addi	sp,sp,-32
    800052da:	ec06                	sd	ra,24(sp)
    800052dc:	e822                	sd	s0,16(sp)
    800052de:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052e0:	fe040613          	addi	a2,s0,-32
    800052e4:	fec40593          	addi	a1,s0,-20
    800052e8:	4501                	li	a0,0
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	cc2080e7          	jalr	-830(ra) # 80004fac <argfd>
    return -1;
    800052f2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052f4:	02054463          	bltz	a0,8000531c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052f8:	ffffc097          	auipc	ra,0xffffc
    800052fc:	798080e7          	jalr	1944(ra) # 80001a90 <myproc>
    80005300:	fec42783          	lw	a5,-20(s0)
    80005304:	07e9                	addi	a5,a5,26
    80005306:	078e                	slli	a5,a5,0x3
    80005308:	97aa                	add	a5,a5,a0
    8000530a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000530e:	fe043503          	ld	a0,-32(s0)
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	29c080e7          	jalr	668(ra) # 800045ae <fileclose>
  return 0;
    8000531a:	4781                	li	a5,0
}
    8000531c:	853e                	mv	a0,a5
    8000531e:	60e2                	ld	ra,24(sp)
    80005320:	6442                	ld	s0,16(sp)
    80005322:	6105                	addi	sp,sp,32
    80005324:	8082                	ret

0000000080005326 <sys_fstat>:
{
    80005326:	1101                	addi	sp,sp,-32
    80005328:	ec06                	sd	ra,24(sp)
    8000532a:	e822                	sd	s0,16(sp)
    8000532c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000532e:	fe840613          	addi	a2,s0,-24
    80005332:	4581                	li	a1,0
    80005334:	4501                	li	a0,0
    80005336:	00000097          	auipc	ra,0x0
    8000533a:	c76080e7          	jalr	-906(ra) # 80004fac <argfd>
    return -1;
    8000533e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005340:	02054563          	bltz	a0,8000536a <sys_fstat+0x44>
    80005344:	fe040593          	addi	a1,s0,-32
    80005348:	4505                	li	a0,1
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	864080e7          	jalr	-1948(ra) # 80002bae <argaddr>
    return -1;
    80005352:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005354:	00054b63          	bltz	a0,8000536a <sys_fstat+0x44>
  return filestat(f, st);
    80005358:	fe043583          	ld	a1,-32(s0)
    8000535c:	fe843503          	ld	a0,-24(s0)
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	316080e7          	jalr	790(ra) # 80004676 <filestat>
    80005368:	87aa                	mv	a5,a0
}
    8000536a:	853e                	mv	a0,a5
    8000536c:	60e2                	ld	ra,24(sp)
    8000536e:	6442                	ld	s0,16(sp)
    80005370:	6105                	addi	sp,sp,32
    80005372:	8082                	ret

0000000080005374 <sys_link>:
{
    80005374:	7169                	addi	sp,sp,-304
    80005376:	f606                	sd	ra,296(sp)
    80005378:	f222                	sd	s0,288(sp)
    8000537a:	ee26                	sd	s1,280(sp)
    8000537c:	ea4a                	sd	s2,272(sp)
    8000537e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005380:	08000613          	li	a2,128
    80005384:	ed040593          	addi	a1,s0,-304
    80005388:	4501                	li	a0,0
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	846080e7          	jalr	-1978(ra) # 80002bd0 <argstr>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005394:	10054e63          	bltz	a0,800054b0 <sys_link+0x13c>
    80005398:	08000613          	li	a2,128
    8000539c:	f5040593          	addi	a1,s0,-176
    800053a0:	4505                	li	a0,1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	82e080e7          	jalr	-2002(ra) # 80002bd0 <argstr>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ac:	10054263          	bltz	a0,800054b0 <sys_link+0x13c>
  begin_op();
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	d32080e7          	jalr	-718(ra) # 800040e2 <begin_op>
  if((ip = namei(old)) == 0){
    800053b8:	ed040513          	addi	a0,s0,-304
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	b0a080e7          	jalr	-1270(ra) # 80003ec6 <namei>
    800053c4:	84aa                	mv	s1,a0
    800053c6:	c551                	beqz	a0,80005452 <sys_link+0xde>
  ilock(ip);
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	348080e7          	jalr	840(ra) # 80003710 <ilock>
  if(ip->type == T_DIR){
    800053d0:	04449703          	lh	a4,68(s1)
    800053d4:	4785                	li	a5,1
    800053d6:	08f70463          	beq	a4,a5,8000545e <sys_link+0xea>
  ip->nlink++;
    800053da:	04a4d783          	lhu	a5,74(s1)
    800053de:	2785                	addiw	a5,a5,1
    800053e0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053e4:	8526                	mv	a0,s1
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	260080e7          	jalr	608(ra) # 80003646 <iupdate>
  iunlock(ip);
    800053ee:	8526                	mv	a0,s1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	3e2080e7          	jalr	994(ra) # 800037d2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053f8:	fd040593          	addi	a1,s0,-48
    800053fc:	f5040513          	addi	a0,s0,-176
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	ae4080e7          	jalr	-1308(ra) # 80003ee4 <nameiparent>
    80005408:	892a                	mv	s2,a0
    8000540a:	c935                	beqz	a0,8000547e <sys_link+0x10a>
  ilock(dp);
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	304080e7          	jalr	772(ra) # 80003710 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005414:	00092703          	lw	a4,0(s2)
    80005418:	409c                	lw	a5,0(s1)
    8000541a:	04f71d63          	bne	a4,a5,80005474 <sys_link+0x100>
    8000541e:	40d0                	lw	a2,4(s1)
    80005420:	fd040593          	addi	a1,s0,-48
    80005424:	854a                	mv	a0,s2
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	9de080e7          	jalr	-1570(ra) # 80003e04 <dirlink>
    8000542e:	04054363          	bltz	a0,80005474 <sys_link+0x100>
  iunlockput(dp);
    80005432:	854a                	mv	a0,s2
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	53e080e7          	jalr	1342(ra) # 80003972 <iunlockput>
  iput(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	48c080e7          	jalr	1164(ra) # 800038ca <iput>
  end_op();
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	d1c080e7          	jalr	-740(ra) # 80004162 <end_op>
  return 0;
    8000544e:	4781                	li	a5,0
    80005450:	a085                	j	800054b0 <sys_link+0x13c>
    end_op();
    80005452:	fffff097          	auipc	ra,0xfffff
    80005456:	d10080e7          	jalr	-752(ra) # 80004162 <end_op>
    return -1;
    8000545a:	57fd                	li	a5,-1
    8000545c:	a891                	j	800054b0 <sys_link+0x13c>
    iunlockput(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	512080e7          	jalr	1298(ra) # 80003972 <iunlockput>
    end_op();
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	cfa080e7          	jalr	-774(ra) # 80004162 <end_op>
    return -1;
    80005470:	57fd                	li	a5,-1
    80005472:	a83d                	j	800054b0 <sys_link+0x13c>
    iunlockput(dp);
    80005474:	854a                	mv	a0,s2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	4fc080e7          	jalr	1276(ra) # 80003972 <iunlockput>
  ilock(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	290080e7          	jalr	656(ra) # 80003710 <ilock>
  ip->nlink--;
    80005488:	04a4d783          	lhu	a5,74(s1)
    8000548c:	37fd                	addiw	a5,a5,-1
    8000548e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	1b2080e7          	jalr	434(ra) # 80003646 <iupdate>
  iunlockput(ip);
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	4d4080e7          	jalr	1236(ra) # 80003972 <iunlockput>
  end_op();
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	cbc080e7          	jalr	-836(ra) # 80004162 <end_op>
  return -1;
    800054ae:	57fd                	li	a5,-1
}
    800054b0:	853e                	mv	a0,a5
    800054b2:	70b2                	ld	ra,296(sp)
    800054b4:	7412                	ld	s0,288(sp)
    800054b6:	64f2                	ld	s1,280(sp)
    800054b8:	6952                	ld	s2,272(sp)
    800054ba:	6155                	addi	sp,sp,304
    800054bc:	8082                	ret

00000000800054be <sys_unlink>:
{
    800054be:	7151                	addi	sp,sp,-240
    800054c0:	f586                	sd	ra,232(sp)
    800054c2:	f1a2                	sd	s0,224(sp)
    800054c4:	eda6                	sd	s1,216(sp)
    800054c6:	e9ca                	sd	s2,208(sp)
    800054c8:	e5ce                	sd	s3,200(sp)
    800054ca:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054cc:	08000613          	li	a2,128
    800054d0:	f3040593          	addi	a1,s0,-208
    800054d4:	4501                	li	a0,0
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	6fa080e7          	jalr	1786(ra) # 80002bd0 <argstr>
    800054de:	18054163          	bltz	a0,80005660 <sys_unlink+0x1a2>
  begin_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	c00080e7          	jalr	-1024(ra) # 800040e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054ea:	fb040593          	addi	a1,s0,-80
    800054ee:	f3040513          	addi	a0,s0,-208
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	9f2080e7          	jalr	-1550(ra) # 80003ee4 <nameiparent>
    800054fa:	84aa                	mv	s1,a0
    800054fc:	c979                	beqz	a0,800055d2 <sys_unlink+0x114>
  ilock(dp);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	212080e7          	jalr	530(ra) # 80003710 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005506:	00007597          	auipc	a1,0x7
    8000550a:	3e258593          	addi	a1,a1,994 # 8000c8e8 <syscalls+0x2d0>
    8000550e:	fb040513          	addi	a0,s0,-80
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	6c8080e7          	jalr	1736(ra) # 80003bda <namecmp>
    8000551a:	14050a63          	beqz	a0,8000566e <sys_unlink+0x1b0>
    8000551e:	00007597          	auipc	a1,0x7
    80005522:	3d258593          	addi	a1,a1,978 # 8000c8f0 <syscalls+0x2d8>
    80005526:	fb040513          	addi	a0,s0,-80
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	6b0080e7          	jalr	1712(ra) # 80003bda <namecmp>
    80005532:	12050e63          	beqz	a0,8000566e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005536:	f2c40613          	addi	a2,s0,-212
    8000553a:	fb040593          	addi	a1,s0,-80
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	6b4080e7          	jalr	1716(ra) # 80003bf4 <dirlookup>
    80005548:	892a                	mv	s2,a0
    8000554a:	12050263          	beqz	a0,8000566e <sys_unlink+0x1b0>
  ilock(ip);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	1c2080e7          	jalr	450(ra) # 80003710 <ilock>
  if(ip->nlink < 1)
    80005556:	04a91783          	lh	a5,74(s2)
    8000555a:	08f05263          	blez	a5,800055de <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000555e:	04491703          	lh	a4,68(s2)
    80005562:	4785                	li	a5,1
    80005564:	08f70563          	beq	a4,a5,800055ee <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005568:	4641                	li	a2,16
    8000556a:	4581                	li	a1,0
    8000556c:	fc040513          	addi	a0,s0,-64
    80005570:	ffffb097          	auipc	ra,0xffffb
    80005574:	770080e7          	jalr	1904(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005578:	4741                	li	a4,16
    8000557a:	f2c42683          	lw	a3,-212(s0)
    8000557e:	fc040613          	addi	a2,s0,-64
    80005582:	4581                	li	a1,0
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	536080e7          	jalr	1334(ra) # 80003abc <writei>
    8000558e:	47c1                	li	a5,16
    80005590:	0af51563          	bne	a0,a5,8000563a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005594:	04491703          	lh	a4,68(s2)
    80005598:	4785                	li	a5,1
    8000559a:	0af70863          	beq	a4,a5,8000564a <sys_unlink+0x18c>
  iunlockput(dp);
    8000559e:	8526                	mv	a0,s1
    800055a0:	ffffe097          	auipc	ra,0xffffe
    800055a4:	3d2080e7          	jalr	978(ra) # 80003972 <iunlockput>
  ip->nlink--;
    800055a8:	04a95783          	lhu	a5,74(s2)
    800055ac:	37fd                	addiw	a5,a5,-1
    800055ae:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	092080e7          	jalr	146(ra) # 80003646 <iupdate>
  iunlockput(ip);
    800055bc:	854a                	mv	a0,s2
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	3b4080e7          	jalr	948(ra) # 80003972 <iunlockput>
  end_op();
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	b9c080e7          	jalr	-1124(ra) # 80004162 <end_op>
  return 0;
    800055ce:	4501                	li	a0,0
    800055d0:	a84d                	j	80005682 <sys_unlink+0x1c4>
    end_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	b90080e7          	jalr	-1136(ra) # 80004162 <end_op>
    return -1;
    800055da:	557d                	li	a0,-1
    800055dc:	a05d                	j	80005682 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055de:	00007517          	auipc	a0,0x7
    800055e2:	33a50513          	addi	a0,a0,826 # 8000c918 <syscalls+0x300>
    800055e6:	ffffb097          	auipc	ra,0xffffb
    800055ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ee:	04c92703          	lw	a4,76(s2)
    800055f2:	02000793          	li	a5,32
    800055f6:	f6e7f9e3          	bgeu	a5,a4,80005568 <sys_unlink+0xaa>
    800055fa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055fe:	4741                	li	a4,16
    80005600:	86ce                	mv	a3,s3
    80005602:	f1840613          	addi	a2,s0,-232
    80005606:	4581                	li	a1,0
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	3ba080e7          	jalr	954(ra) # 800039c4 <readi>
    80005612:	47c1                	li	a5,16
    80005614:	00f51b63          	bne	a0,a5,8000562a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005618:	f1845783          	lhu	a5,-232(s0)
    8000561c:	e7a1                	bnez	a5,80005664 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000561e:	29c1                	addiw	s3,s3,16
    80005620:	04c92783          	lw	a5,76(s2)
    80005624:	fcf9ede3          	bltu	s3,a5,800055fe <sys_unlink+0x140>
    80005628:	b781                	j	80005568 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000562a:	00007517          	auipc	a0,0x7
    8000562e:	30650513          	addi	a0,a0,774 # 8000c930 <syscalls+0x318>
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
    panic("unlink: writei");
    8000563a:	00007517          	auipc	a0,0x7
    8000563e:	30e50513          	addi	a0,a0,782 # 8000c948 <syscalls+0x330>
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>
    dp->nlink--;
    8000564a:	04a4d783          	lhu	a5,74(s1)
    8000564e:	37fd                	addiw	a5,a5,-1
    80005650:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	ff0080e7          	jalr	-16(ra) # 80003646 <iupdate>
    8000565e:	b781                	j	8000559e <sys_unlink+0xe0>
    return -1;
    80005660:	557d                	li	a0,-1
    80005662:	a005                	j	80005682 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	30c080e7          	jalr	780(ra) # 80003972 <iunlockput>
  iunlockput(dp);
    8000566e:	8526                	mv	a0,s1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	302080e7          	jalr	770(ra) # 80003972 <iunlockput>
  end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	aea080e7          	jalr	-1302(ra) # 80004162 <end_op>
  return -1;
    80005680:	557d                	li	a0,-1
}
    80005682:	70ae                	ld	ra,232(sp)
    80005684:	740e                	ld	s0,224(sp)
    80005686:	64ee                	ld	s1,216(sp)
    80005688:	694e                	ld	s2,208(sp)
    8000568a:	69ae                	ld	s3,200(sp)
    8000568c:	616d                	addi	sp,sp,240
    8000568e:	8082                	ret

0000000080005690 <sys_open>:

uint64
sys_open(void)
{
    80005690:	7131                	addi	sp,sp,-192
    80005692:	fd06                	sd	ra,184(sp)
    80005694:	f922                	sd	s0,176(sp)
    80005696:	f526                	sd	s1,168(sp)
    80005698:	f14a                	sd	s2,160(sp)
    8000569a:	ed4e                	sd	s3,152(sp)
    8000569c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000569e:	08000613          	li	a2,128
    800056a2:	f5040593          	addi	a1,s0,-176
    800056a6:	4501                	li	a0,0
    800056a8:	ffffd097          	auipc	ra,0xffffd
    800056ac:	528080e7          	jalr	1320(ra) # 80002bd0 <argstr>
    return -1;
    800056b0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056b2:	0c054163          	bltz	a0,80005774 <sys_open+0xe4>
    800056b6:	f4c40593          	addi	a1,s0,-180
    800056ba:	4505                	li	a0,1
    800056bc:	ffffd097          	auipc	ra,0xffffd
    800056c0:	4d0080e7          	jalr	1232(ra) # 80002b8c <argint>
    800056c4:	0a054863          	bltz	a0,80005774 <sys_open+0xe4>

  begin_op();
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	a1a080e7          	jalr	-1510(ra) # 800040e2 <begin_op>

  if(omode & O_CREATE){
    800056d0:	f4c42783          	lw	a5,-180(s0)
    800056d4:	2007f793          	andi	a5,a5,512
    800056d8:	cbdd                	beqz	a5,8000578e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056da:	4681                	li	a3,0
    800056dc:	4601                	li	a2,0
    800056de:	4589                	li	a1,2
    800056e0:	f5040513          	addi	a0,s0,-176
    800056e4:	00000097          	auipc	ra,0x0
    800056e8:	972080e7          	jalr	-1678(ra) # 80005056 <create>
    800056ec:	892a                	mv	s2,a0
    if(ip == 0){
    800056ee:	c959                	beqz	a0,80005784 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056f0:	04491703          	lh	a4,68(s2)
    800056f4:	478d                	li	a5,3
    800056f6:	00f71763          	bne	a4,a5,80005704 <sys_open+0x74>
    800056fa:	04695703          	lhu	a4,70(s2)
    800056fe:	47a5                	li	a5,9
    80005700:	0ce7ec63          	bltu	a5,a4,800057d8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	dee080e7          	jalr	-530(ra) # 800044f2 <filealloc>
    8000570c:	89aa                	mv	s3,a0
    8000570e:	10050263          	beqz	a0,80005812 <sys_open+0x182>
    80005712:	00000097          	auipc	ra,0x0
    80005716:	902080e7          	jalr	-1790(ra) # 80005014 <fdalloc>
    8000571a:	84aa                	mv	s1,a0
    8000571c:	0e054663          	bltz	a0,80005808 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005720:	04491703          	lh	a4,68(s2)
    80005724:	478d                	li	a5,3
    80005726:	0cf70463          	beq	a4,a5,800057ee <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000572a:	4789                	li	a5,2
    8000572c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005730:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005734:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005738:	f4c42783          	lw	a5,-180(s0)
    8000573c:	0017c713          	xori	a4,a5,1
    80005740:	8b05                	andi	a4,a4,1
    80005742:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005746:	0037f713          	andi	a4,a5,3
    8000574a:	00e03733          	snez	a4,a4
    8000574e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005752:	4007f793          	andi	a5,a5,1024
    80005756:	c791                	beqz	a5,80005762 <sys_open+0xd2>
    80005758:	04491703          	lh	a4,68(s2)
    8000575c:	4789                	li	a5,2
    8000575e:	08f70f63          	beq	a4,a5,800057fc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005762:	854a                	mv	a0,s2
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	06e080e7          	jalr	110(ra) # 800037d2 <iunlock>
  end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	9f6080e7          	jalr	-1546(ra) # 80004162 <end_op>

  return fd;
}
    80005774:	8526                	mv	a0,s1
    80005776:	70ea                	ld	ra,184(sp)
    80005778:	744a                	ld	s0,176(sp)
    8000577a:	74aa                	ld	s1,168(sp)
    8000577c:	790a                	ld	s2,160(sp)
    8000577e:	69ea                	ld	s3,152(sp)
    80005780:	6129                	addi	sp,sp,192
    80005782:	8082                	ret
      end_op();
    80005784:	fffff097          	auipc	ra,0xfffff
    80005788:	9de080e7          	jalr	-1570(ra) # 80004162 <end_op>
      return -1;
    8000578c:	b7e5                	j	80005774 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000578e:	f5040513          	addi	a0,s0,-176
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	734080e7          	jalr	1844(ra) # 80003ec6 <namei>
    8000579a:	892a                	mv	s2,a0
    8000579c:	c905                	beqz	a0,800057cc <sys_open+0x13c>
    ilock(ip);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	f72080e7          	jalr	-142(ra) # 80003710 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057a6:	04491703          	lh	a4,68(s2)
    800057aa:	4785                	li	a5,1
    800057ac:	f4f712e3          	bne	a4,a5,800056f0 <sys_open+0x60>
    800057b0:	f4c42783          	lw	a5,-180(s0)
    800057b4:	dba1                	beqz	a5,80005704 <sys_open+0x74>
      iunlockput(ip);
    800057b6:	854a                	mv	a0,s2
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	1ba080e7          	jalr	442(ra) # 80003972 <iunlockput>
      end_op();
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	9a2080e7          	jalr	-1630(ra) # 80004162 <end_op>
      return -1;
    800057c8:	54fd                	li	s1,-1
    800057ca:	b76d                	j	80005774 <sys_open+0xe4>
      end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	996080e7          	jalr	-1642(ra) # 80004162 <end_op>
      return -1;
    800057d4:	54fd                	li	s1,-1
    800057d6:	bf79                	j	80005774 <sys_open+0xe4>
    iunlockput(ip);
    800057d8:	854a                	mv	a0,s2
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	198080e7          	jalr	408(ra) # 80003972 <iunlockput>
    end_op();
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	980080e7          	jalr	-1664(ra) # 80004162 <end_op>
    return -1;
    800057ea:	54fd                	li	s1,-1
    800057ec:	b761                	j	80005774 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057ee:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057f2:	04691783          	lh	a5,70(s2)
    800057f6:	02f99223          	sh	a5,36(s3)
    800057fa:	bf2d                	j	80005734 <sys_open+0xa4>
    itrunc(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	020080e7          	jalr	32(ra) # 8000381e <itrunc>
    80005806:	bfb1                	j	80005762 <sys_open+0xd2>
      fileclose(f);
    80005808:	854e                	mv	a0,s3
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	da4080e7          	jalr	-604(ra) # 800045ae <fileclose>
    iunlockput(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	15e080e7          	jalr	350(ra) # 80003972 <iunlockput>
    end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	946080e7          	jalr	-1722(ra) # 80004162 <end_op>
    return -1;
    80005824:	54fd                	li	s1,-1
    80005826:	b7b9                	j	80005774 <sys_open+0xe4>

0000000080005828 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005828:	7175                	addi	sp,sp,-144
    8000582a:	e506                	sd	ra,136(sp)
    8000582c:	e122                	sd	s0,128(sp)
    8000582e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	8b2080e7          	jalr	-1870(ra) # 800040e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005838:	08000613          	li	a2,128
    8000583c:	f7040593          	addi	a1,s0,-144
    80005840:	4501                	li	a0,0
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	38e080e7          	jalr	910(ra) # 80002bd0 <argstr>
    8000584a:	02054963          	bltz	a0,8000587c <sys_mkdir+0x54>
    8000584e:	4681                	li	a3,0
    80005850:	4601                	li	a2,0
    80005852:	4585                	li	a1,1
    80005854:	f7040513          	addi	a0,s0,-144
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	7fe080e7          	jalr	2046(ra) # 80005056 <create>
    80005860:	cd11                	beqz	a0,8000587c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	110080e7          	jalr	272(ra) # 80003972 <iunlockput>
  end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	8f8080e7          	jalr	-1800(ra) # 80004162 <end_op>
  return 0;
    80005872:	4501                	li	a0,0
}
    80005874:	60aa                	ld	ra,136(sp)
    80005876:	640a                	ld	s0,128(sp)
    80005878:	6149                	addi	sp,sp,144
    8000587a:	8082                	ret
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	8e6080e7          	jalr	-1818(ra) # 80004162 <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	b7fd                	j	80005874 <sys_mkdir+0x4c>

0000000080005888 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005888:	7135                	addi	sp,sp,-160
    8000588a:	ed06                	sd	ra,152(sp)
    8000588c:	e922                	sd	s0,144(sp)
    8000588e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005890:	fffff097          	auipc	ra,0xfffff
    80005894:	852080e7          	jalr	-1966(ra) # 800040e2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005898:	08000613          	li	a2,128
    8000589c:	f7040593          	addi	a1,s0,-144
    800058a0:	4501                	li	a0,0
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	32e080e7          	jalr	814(ra) # 80002bd0 <argstr>
    800058aa:	04054a63          	bltz	a0,800058fe <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058ae:	f6c40593          	addi	a1,s0,-148
    800058b2:	4505                	li	a0,1
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	2d8080e7          	jalr	728(ra) # 80002b8c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058bc:	04054163          	bltz	a0,800058fe <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058c0:	f6840593          	addi	a1,s0,-152
    800058c4:	4509                	li	a0,2
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	2c6080e7          	jalr	710(ra) # 80002b8c <argint>
     argint(1, &major) < 0 ||
    800058ce:	02054863          	bltz	a0,800058fe <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058d2:	f6841683          	lh	a3,-152(s0)
    800058d6:	f6c41603          	lh	a2,-148(s0)
    800058da:	458d                	li	a1,3
    800058dc:	f7040513          	addi	a0,s0,-144
    800058e0:	fffff097          	auipc	ra,0xfffff
    800058e4:	776080e7          	jalr	1910(ra) # 80005056 <create>
     argint(2, &minor) < 0 ||
    800058e8:	c919                	beqz	a0,800058fe <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	088080e7          	jalr	136(ra) # 80003972 <iunlockput>
  end_op();
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	870080e7          	jalr	-1936(ra) # 80004162 <end_op>
  return 0;
    800058fa:	4501                	li	a0,0
    800058fc:	a031                	j	80005908 <sys_mknod+0x80>
    end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	864080e7          	jalr	-1948(ra) # 80004162 <end_op>
    return -1;
    80005906:	557d                	li	a0,-1
}
    80005908:	60ea                	ld	ra,152(sp)
    8000590a:	644a                	ld	s0,144(sp)
    8000590c:	610d                	addi	sp,sp,160
    8000590e:	8082                	ret

0000000080005910 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005910:	7135                	addi	sp,sp,-160
    80005912:	ed06                	sd	ra,152(sp)
    80005914:	e922                	sd	s0,144(sp)
    80005916:	e526                	sd	s1,136(sp)
    80005918:	e14a                	sd	s2,128(sp)
    8000591a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000591c:	ffffc097          	auipc	ra,0xffffc
    80005920:	174080e7          	jalr	372(ra) # 80001a90 <myproc>
    80005924:	892a                	mv	s2,a0
  
  begin_op();
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	7bc080e7          	jalr	1980(ra) # 800040e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000592e:	08000613          	li	a2,128
    80005932:	f6040593          	addi	a1,s0,-160
    80005936:	4501                	li	a0,0
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	298080e7          	jalr	664(ra) # 80002bd0 <argstr>
    80005940:	04054b63          	bltz	a0,80005996 <sys_chdir+0x86>
    80005944:	f6040513          	addi	a0,s0,-160
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	57e080e7          	jalr	1406(ra) # 80003ec6 <namei>
    80005950:	84aa                	mv	s1,a0
    80005952:	c131                	beqz	a0,80005996 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	dbc080e7          	jalr	-580(ra) # 80003710 <ilock>
  if(ip->type != T_DIR){
    8000595c:	04449703          	lh	a4,68(s1)
    80005960:	4785                	li	a5,1
    80005962:	04f71063          	bne	a4,a5,800059a2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005966:	8526                	mv	a0,s1
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	e6a080e7          	jalr	-406(ra) # 800037d2 <iunlock>
  iput(p->cwd);
    80005970:	15093503          	ld	a0,336(s2)
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	f56080e7          	jalr	-170(ra) # 800038ca <iput>
  end_op();
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	7e6080e7          	jalr	2022(ra) # 80004162 <end_op>
  p->cwd = ip;
    80005984:	14993823          	sd	s1,336(s2)
  return 0;
    80005988:	4501                	li	a0,0
}
    8000598a:	60ea                	ld	ra,152(sp)
    8000598c:	644a                	ld	s0,144(sp)
    8000598e:	64aa                	ld	s1,136(sp)
    80005990:	690a                	ld	s2,128(sp)
    80005992:	610d                	addi	sp,sp,160
    80005994:	8082                	ret
    end_op();
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	7cc080e7          	jalr	1996(ra) # 80004162 <end_op>
    return -1;
    8000599e:	557d                	li	a0,-1
    800059a0:	b7ed                	j	8000598a <sys_chdir+0x7a>
    iunlockput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	fce080e7          	jalr	-50(ra) # 80003972 <iunlockput>
    end_op();
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	7b6080e7          	jalr	1974(ra) # 80004162 <end_op>
    return -1;
    800059b4:	557d                	li	a0,-1
    800059b6:	bfd1                	j	8000598a <sys_chdir+0x7a>

00000000800059b8 <sys_exec>:

uint64
sys_exec(void)
{
    800059b8:	7145                	addi	sp,sp,-464
    800059ba:	e786                	sd	ra,456(sp)
    800059bc:	e3a2                	sd	s0,448(sp)
    800059be:	ff26                	sd	s1,440(sp)
    800059c0:	fb4a                	sd	s2,432(sp)
    800059c2:	f74e                	sd	s3,424(sp)
    800059c4:	f352                	sd	s4,416(sp)
    800059c6:	ef56                	sd	s5,408(sp)
    800059c8:	0b80                	addi	s0,sp,464
	printf("sysexec\n");
    800059ca:	00007517          	auipc	a0,0x7
    800059ce:	f8e50513          	addi	a0,a0,-114 # 8000c958 <syscalls+0x340>
    800059d2:	ffffb097          	auipc	ra,0xffffb
    800059d6:	bb6080e7          	jalr	-1098(ra) # 80000588 <printf>
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059da:	08000613          	li	a2,128
    800059de:	f4040593          	addi	a1,s0,-192
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	1ec080e7          	jalr	492(ra) # 80002bd0 <argstr>
    return -1;
    800059ec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ee:	0c054a63          	bltz	a0,80005ac2 <sys_exec+0x10a>
    800059f2:	e3840593          	addi	a1,s0,-456
    800059f6:	4505                	li	a0,1
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	1b6080e7          	jalr	438(ra) # 80002bae <argaddr>
    80005a00:	0c054163          	bltz	a0,80005ac2 <sys_exec+0x10a>
  }
  memset(argv, 0, sizeof(argv));
    80005a04:	10000613          	li	a2,256
    80005a08:	4581                	li	a1,0
    80005a0a:	e4040513          	addi	a0,s0,-448
    80005a0e:	ffffb097          	auipc	ra,0xffffb
    80005a12:	2d2080e7          	jalr	722(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a16:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a1a:	89a6                	mv	s3,s1
    80005a1c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a1e:	02000a13          	li	s4,32
    80005a22:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a26:	00391513          	slli	a0,s2,0x3
    80005a2a:	e3040593          	addi	a1,s0,-464
    80005a2e:	e3843783          	ld	a5,-456(s0)
    80005a32:	953e                	add	a0,a0,a5
    80005a34:	ffffd097          	auipc	ra,0xffffd
    80005a38:	0be080e7          	jalr	190(ra) # 80002af2 <fetchaddr>
    80005a3c:	02054a63          	bltz	a0,80005a70 <sys_exec+0xb8>
      goto bad;
    }
    if(uarg == 0){
    80005a40:	e3043783          	ld	a5,-464(s0)
    80005a44:	c3b9                	beqz	a5,80005a8a <sys_exec+0xd2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	0ae080e7          	jalr	174(ra) # 80000af4 <kalloc>
    80005a4e:	85aa                	mv	a1,a0
    80005a50:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a54:	cd11                	beqz	a0,80005a70 <sys_exec+0xb8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a56:	6611                	lui	a2,0x4
    80005a58:	e3043503          	ld	a0,-464(s0)
    80005a5c:	ffffd097          	auipc	ra,0xffffd
    80005a60:	0e8080e7          	jalr	232(ra) # 80002b44 <fetchstr>
    80005a64:	00054663          	bltz	a0,80005a70 <sys_exec+0xb8>
    if(i >= NELEM(argv)){
    80005a68:	0905                	addi	s2,s2,1
    80005a6a:	09a1                	addi	s3,s3,8
    80005a6c:	fb491be3          	bne	s2,s4,80005a22 <sys_exec+0x6a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a70:	10048913          	addi	s2,s1,256
    80005a74:	6088                	ld	a0,0(s1)
    80005a76:	c529                	beqz	a0,80005ac0 <sys_exec+0x108>
    kfree(argv[i]);
    80005a78:	ffffb097          	auipc	ra,0xffffb
    80005a7c:	f80080e7          	jalr	-128(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a80:	04a1                	addi	s1,s1,8
    80005a82:	ff2499e3          	bne	s1,s2,80005a74 <sys_exec+0xbc>
  return -1;
    80005a86:	597d                	li	s2,-1
    80005a88:	a82d                	j	80005ac2 <sys_exec+0x10a>
      argv[i] = 0;
    80005a8a:	0a8e                	slli	s5,s5,0x3
    80005a8c:	fc040793          	addi	a5,s0,-64
    80005a90:	9abe                	add	s5,s5,a5
    80005a92:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a96:	e4040593          	addi	a1,s0,-448
    80005a9a:	f4040513          	addi	a0,s0,-192
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	170080e7          	jalr	368(ra) # 80004c0e <exec>
    80005aa6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa8:	10048993          	addi	s3,s1,256
    80005aac:	6088                	ld	a0,0(s1)
    80005aae:	c911                	beqz	a0,80005ac2 <sys_exec+0x10a>
    kfree(argv[i]);
    80005ab0:	ffffb097          	auipc	ra,0xffffb
    80005ab4:	f48080e7          	jalr	-184(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab8:	04a1                	addi	s1,s1,8
    80005aba:	ff3499e3          	bne	s1,s3,80005aac <sys_exec+0xf4>
    80005abe:	a011                	j	80005ac2 <sys_exec+0x10a>
  return -1;
    80005ac0:	597d                	li	s2,-1
}
    80005ac2:	854a                	mv	a0,s2
    80005ac4:	60be                	ld	ra,456(sp)
    80005ac6:	641e                	ld	s0,448(sp)
    80005ac8:	74fa                	ld	s1,440(sp)
    80005aca:	795a                	ld	s2,432(sp)
    80005acc:	79ba                	ld	s3,424(sp)
    80005ace:	7a1a                	ld	s4,416(sp)
    80005ad0:	6afa                	ld	s5,408(sp)
    80005ad2:	6179                	addi	sp,sp,464
    80005ad4:	8082                	ret

0000000080005ad6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ad6:	7139                	addi	sp,sp,-64
    80005ad8:	fc06                	sd	ra,56(sp)
    80005ada:	f822                	sd	s0,48(sp)
    80005adc:	f426                	sd	s1,40(sp)
    80005ade:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ae0:	ffffc097          	auipc	ra,0xffffc
    80005ae4:	fb0080e7          	jalr	-80(ra) # 80001a90 <myproc>
    80005ae8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005aea:	fd840593          	addi	a1,s0,-40
    80005aee:	4501                	li	a0,0
    80005af0:	ffffd097          	auipc	ra,0xffffd
    80005af4:	0be080e7          	jalr	190(ra) # 80002bae <argaddr>
    return -1;
    80005af8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005afa:	0e054063          	bltz	a0,80005bda <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005afe:	fc840593          	addi	a1,s0,-56
    80005b02:	fd040513          	addi	a0,s0,-48
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	dd8080e7          	jalr	-552(ra) # 800048de <pipealloc>
    return -1;
    80005b0e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b10:	0c054563          	bltz	a0,80005bda <sys_pipe+0x104>
  fd0 = -1;
    80005b14:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b18:	fd043503          	ld	a0,-48(s0)
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	4f8080e7          	jalr	1272(ra) # 80005014 <fdalloc>
    80005b24:	fca42223          	sw	a0,-60(s0)
    80005b28:	08054c63          	bltz	a0,80005bc0 <sys_pipe+0xea>
    80005b2c:	fc843503          	ld	a0,-56(s0)
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	4e4080e7          	jalr	1252(ra) # 80005014 <fdalloc>
    80005b38:	fca42023          	sw	a0,-64(s0)
    80005b3c:	06054863          	bltz	a0,80005bac <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b40:	4691                	li	a3,4
    80005b42:	fc440613          	addi	a2,s0,-60
    80005b46:	fd843583          	ld	a1,-40(s0)
    80005b4a:	68a8                	ld	a0,80(s1)
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	c06080e7          	jalr	-1018(ra) # 80001752 <copyout>
    80005b54:	02054063          	bltz	a0,80005b74 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b58:	4691                	li	a3,4
    80005b5a:	fc040613          	addi	a2,s0,-64
    80005b5e:	fd843583          	ld	a1,-40(s0)
    80005b62:	0591                	addi	a1,a1,4
    80005b64:	68a8                	ld	a0,80(s1)
    80005b66:	ffffc097          	auipc	ra,0xffffc
    80005b6a:	bec080e7          	jalr	-1044(ra) # 80001752 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b6e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b70:	06055563          	bgez	a0,80005bda <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b74:	fc442783          	lw	a5,-60(s0)
    80005b78:	07e9                	addi	a5,a5,26
    80005b7a:	078e                	slli	a5,a5,0x3
    80005b7c:	97a6                	add	a5,a5,s1
    80005b7e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b82:	fc042503          	lw	a0,-64(s0)
    80005b86:	0569                	addi	a0,a0,26
    80005b88:	050e                	slli	a0,a0,0x3
    80005b8a:	9526                	add	a0,a0,s1
    80005b8c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b90:	fd043503          	ld	a0,-48(s0)
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	a1a080e7          	jalr	-1510(ra) # 800045ae <fileclose>
    fileclose(wf);
    80005b9c:	fc843503          	ld	a0,-56(s0)
    80005ba0:	fffff097          	auipc	ra,0xfffff
    80005ba4:	a0e080e7          	jalr	-1522(ra) # 800045ae <fileclose>
    return -1;
    80005ba8:	57fd                	li	a5,-1
    80005baa:	a805                	j	80005bda <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bac:	fc442783          	lw	a5,-60(s0)
    80005bb0:	0007c863          	bltz	a5,80005bc0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bb4:	01a78513          	addi	a0,a5,26
    80005bb8:	050e                	slli	a0,a0,0x3
    80005bba:	9526                	add	a0,a0,s1
    80005bbc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bc0:	fd043503          	ld	a0,-48(s0)
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	9ea080e7          	jalr	-1558(ra) # 800045ae <fileclose>
    fileclose(wf);
    80005bcc:	fc843503          	ld	a0,-56(s0)
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	9de080e7          	jalr	-1570(ra) # 800045ae <fileclose>
    return -1;
    80005bd8:	57fd                	li	a5,-1
}
    80005bda:	853e                	mv	a0,a5
    80005bdc:	70e2                	ld	ra,56(sp)
    80005bde:	7442                	ld	s0,48(sp)
    80005be0:	74a2                	ld	s1,40(sp)
    80005be2:	6121                	addi	sp,sp,64
    80005be4:	8082                	ret
	...

0000000080005bf0 <kernelvec>:
    80005bf0:	7111                	addi	sp,sp,-256
    80005bf2:	e006                	sd	ra,0(sp)
    80005bf4:	e40a                	sd	sp,8(sp)
    80005bf6:	e80e                	sd	gp,16(sp)
    80005bf8:	ec12                	sd	tp,24(sp)
    80005bfa:	f016                	sd	t0,32(sp)
    80005bfc:	f41a                	sd	t1,40(sp)
    80005bfe:	f81e                	sd	t2,48(sp)
    80005c00:	fc22                	sd	s0,56(sp)
    80005c02:	e0a6                	sd	s1,64(sp)
    80005c04:	e4aa                	sd	a0,72(sp)
    80005c06:	e8ae                	sd	a1,80(sp)
    80005c08:	ecb2                	sd	a2,88(sp)
    80005c0a:	f0b6                	sd	a3,96(sp)
    80005c0c:	f4ba                	sd	a4,104(sp)
    80005c0e:	f8be                	sd	a5,112(sp)
    80005c10:	fcc2                	sd	a6,120(sp)
    80005c12:	e146                	sd	a7,128(sp)
    80005c14:	e54a                	sd	s2,136(sp)
    80005c16:	e94e                	sd	s3,144(sp)
    80005c18:	ed52                	sd	s4,152(sp)
    80005c1a:	f156                	sd	s5,160(sp)
    80005c1c:	f55a                	sd	s6,168(sp)
    80005c1e:	f95e                	sd	s7,176(sp)
    80005c20:	fd62                	sd	s8,184(sp)
    80005c22:	e1e6                	sd	s9,192(sp)
    80005c24:	e5ea                	sd	s10,200(sp)
    80005c26:	e9ee                	sd	s11,208(sp)
    80005c28:	edf2                	sd	t3,216(sp)
    80005c2a:	f1f6                	sd	t4,224(sp)
    80005c2c:	f5fa                	sd	t5,232(sp)
    80005c2e:	f9fe                	sd	t6,240(sp)
    80005c30:	d8ffc0ef          	jal	ra,800029be <kerneltrap>
    80005c34:	6082                	ld	ra,0(sp)
    80005c36:	6122                	ld	sp,8(sp)
    80005c38:	61c2                	ld	gp,16(sp)
    80005c3a:	7282                	ld	t0,32(sp)
    80005c3c:	7322                	ld	t1,40(sp)
    80005c3e:	73c2                	ld	t2,48(sp)
    80005c40:	7462                	ld	s0,56(sp)
    80005c42:	6486                	ld	s1,64(sp)
    80005c44:	6526                	ld	a0,72(sp)
    80005c46:	65c6                	ld	a1,80(sp)
    80005c48:	6666                	ld	a2,88(sp)
    80005c4a:	7686                	ld	a3,96(sp)
    80005c4c:	7726                	ld	a4,104(sp)
    80005c4e:	77c6                	ld	a5,112(sp)
    80005c50:	7866                	ld	a6,120(sp)
    80005c52:	688a                	ld	a7,128(sp)
    80005c54:	692a                	ld	s2,136(sp)
    80005c56:	69ca                	ld	s3,144(sp)
    80005c58:	6a6a                	ld	s4,152(sp)
    80005c5a:	7a8a                	ld	s5,160(sp)
    80005c5c:	7b2a                	ld	s6,168(sp)
    80005c5e:	7bca                	ld	s7,176(sp)
    80005c60:	7c6a                	ld	s8,184(sp)
    80005c62:	6c8e                	ld	s9,192(sp)
    80005c64:	6d2e                	ld	s10,200(sp)
    80005c66:	6dce                	ld	s11,208(sp)
    80005c68:	6e6e                	ld	t3,216(sp)
    80005c6a:	7e8e                	ld	t4,224(sp)
    80005c6c:	7f2e                	ld	t5,232(sp)
    80005c6e:	7fce                	ld	t6,240(sp)
    80005c70:	6111                	addi	sp,sp,256
    80005c72:	10200073          	sret
    80005c76:	00000013          	nop
    80005c7a:	00000013          	nop
    80005c7e:	0001                	nop

0000000080005c80 <timervec>:
    80005c80:	34051573          	csrrw	a0,mscratch,a0
    80005c84:	e10c                	sd	a1,0(a0)
    80005c86:	e510                	sd	a2,8(a0)
    80005c88:	e914                	sd	a3,16(a0)
    80005c8a:	6d0c                	ld	a1,24(a0)
    80005c8c:	7110                	ld	a2,32(a0)
    80005c8e:	6194                	ld	a3,0(a1)
    80005c90:	96b2                	add	a3,a3,a2
    80005c92:	e194                	sd	a3,0(a1)
    80005c94:	4589                	li	a1,2
    80005c96:	14459073          	csrw	sip,a1
    80005c9a:	6914                	ld	a3,16(a0)
    80005c9c:	6510                	ld	a2,8(a0)
    80005c9e:	610c                	ld	a1,0(a0)
    80005ca0:	34051573          	csrrw	a0,mscratch,a0
    80005ca4:	30200073          	mret
	...

0000000080005caa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005caa:	1141                	addi	sp,sp,-16
    80005cac:	e422                	sd	s0,8(sp)
    80005cae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cb0:	0c0007b7          	lui	a5,0xc000
    80005cb4:	4705                	li	a4,1
    80005cb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cb8:	c3d8                	sw	a4,4(a5)
}
    80005cba:	6422                	ld	s0,8(sp)
    80005cbc:	0141                	addi	sp,sp,16
    80005cbe:	8082                	ret

0000000080005cc0 <plicinithart>:

void
plicinithart(void)
{
    80005cc0:	1141                	addi	sp,sp,-16
    80005cc2:	e406                	sd	ra,8(sp)
    80005cc4:	e022                	sd	s0,0(sp)
    80005cc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	d9c080e7          	jalr	-612(ra) # 80001a64 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cd0:	0085171b          	slliw	a4,a0,0x8
    80005cd4:	0c0027b7          	lui	a5,0xc002
    80005cd8:	97ba                	add	a5,a5,a4
    80005cda:	40200713          	li	a4,1026
    80005cde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ce2:	00d5151b          	slliw	a0,a0,0xd
    80005ce6:	0c2017b7          	lui	a5,0xc201
    80005cea:	953e                	add	a0,a0,a5
    80005cec:	00052023          	sw	zero,0(a0)
}
    80005cf0:	60a2                	ld	ra,8(sp)
    80005cf2:	6402                	ld	s0,0(sp)
    80005cf4:	0141                	addi	sp,sp,16
    80005cf6:	8082                	ret

0000000080005cf8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cf8:	1141                	addi	sp,sp,-16
    80005cfa:	e406                	sd	ra,8(sp)
    80005cfc:	e022                	sd	s0,0(sp)
    80005cfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	d64080e7          	jalr	-668(ra) # 80001a64 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d08:	00d5179b          	slliw	a5,a0,0xd
    80005d0c:	0c201537          	lui	a0,0xc201
    80005d10:	953e                	add	a0,a0,a5
  return irq;
}
    80005d12:	4148                	lw	a0,4(a0)
    80005d14:	60a2                	ld	ra,8(sp)
    80005d16:	6402                	ld	s0,0(sp)
    80005d18:	0141                	addi	sp,sp,16
    80005d1a:	8082                	ret

0000000080005d1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d1c:	1101                	addi	sp,sp,-32
    80005d1e:	ec06                	sd	ra,24(sp)
    80005d20:	e822                	sd	s0,16(sp)
    80005d22:	e426                	sd	s1,8(sp)
    80005d24:	1000                	addi	s0,sp,32
    80005d26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d28:	ffffc097          	auipc	ra,0xffffc
    80005d2c:	d3c080e7          	jalr	-708(ra) # 80001a64 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d30:	00d5151b          	slliw	a0,a0,0xd
    80005d34:	0c2017b7          	lui	a5,0xc201
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	c3c4                	sw	s1,4(a5)
}
    80005d3c:	60e2                	ld	ra,24(sp)
    80005d3e:	6442                	ld	s0,16(sp)
    80005d40:	64a2                	ld	s1,8(sp)
    80005d42:	6105                	addi	sp,sp,32
    80005d44:	8082                	ret

0000000080005d46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d46:	1141                	addi	sp,sp,-16
    80005d48:	e406                	sd	ra,8(sp)
    80005d4a:	e022                	sd	s0,0(sp)
    80005d4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d4e:	479d                	li	a5,7
    80005d50:	06a7c963          	blt	a5,a0,80005dc2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d54:	00026797          	auipc	a5,0x26
    80005d58:	2ac78793          	addi	a5,a5,684 # 8002c000 <disk>
    80005d5c:	00a78733          	add	a4,a5,a0
    80005d60:	67a1                	lui	a5,0x8
    80005d62:	97ba                	add	a5,a5,a4
    80005d64:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005d68:	e7ad                	bnez	a5,80005dd2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d6a:	00451793          	slli	a5,a0,0x4
    80005d6e:	0002e717          	auipc	a4,0x2e
    80005d72:	29270713          	addi	a4,a4,658 # 80034000 <disk+0x8000>
    80005d76:	6314                	ld	a3,0(a4)
    80005d78:	96be                	add	a3,a3,a5
    80005d7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d7e:	6314                	ld	a3,0(a4)
    80005d80:	96be                	add	a3,a3,a5
    80005d82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d86:	6314                	ld	a3,0(a4)
    80005d88:	96be                	add	a3,a3,a5
    80005d8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d8e:	6318                	ld	a4,0(a4)
    80005d90:	97ba                	add	a5,a5,a4
    80005d92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d96:	00026797          	auipc	a5,0x26
    80005d9a:	26a78793          	addi	a5,a5,618 # 8002c000 <disk>
    80005d9e:	97aa                	add	a5,a5,a0
    80005da0:	6521                	lui	a0,0x8
    80005da2:	953e                	add	a0,a0,a5
    80005da4:	4785                	li	a5,1
    80005da6:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005daa:	0002e517          	auipc	a0,0x2e
    80005dae:	26e50513          	addi	a0,a0,622 # 80034018 <disk+0x8018>
    80005db2:	ffffc097          	auipc	ra,0xffffc
    80005db6:	55a080e7          	jalr	1370(ra) # 8000230c <wakeup>
}
    80005dba:	60a2                	ld	ra,8(sp)
    80005dbc:	6402                	ld	s0,0(sp)
    80005dbe:	0141                	addi	sp,sp,16
    80005dc0:	8082                	ret
    panic("free_desc 1");
    80005dc2:	00007517          	auipc	a0,0x7
    80005dc6:	ba650513          	addi	a0,a0,-1114 # 8000c968 <syscalls+0x350>
    80005dca:	ffffa097          	auipc	ra,0xffffa
    80005dce:	774080e7          	jalr	1908(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005dd2:	00007517          	auipc	a0,0x7
    80005dd6:	ba650513          	addi	a0,a0,-1114 # 8000c978 <syscalls+0x360>
    80005dda:	ffffa097          	auipc	ra,0xffffa
    80005dde:	764080e7          	jalr	1892(ra) # 8000053e <panic>

0000000080005de2 <virtio_disk_init>:
{
    80005de2:	1101                	addi	sp,sp,-32
    80005de4:	ec06                	sd	ra,24(sp)
    80005de6:	e822                	sd	s0,16(sp)
    80005de8:	e426                	sd	s1,8(sp)
    80005dea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dec:	00007597          	auipc	a1,0x7
    80005df0:	b9c58593          	addi	a1,a1,-1124 # 8000c988 <syscalls+0x370>
    80005df4:	0002e517          	auipc	a0,0x2e
    80005df8:	33450513          	addi	a0,a0,820 # 80034128 <disk+0x8128>
    80005dfc:	ffffb097          	auipc	ra,0xffffb
    80005e00:	d58080e7          	jalr	-680(ra) # 80000b54 <initlock>
	  printf("%x %x %x %x\n",
    80005e04:	100014b7          	lui	s1,0x10001
    80005e08:	408c                	lw	a1,0(s1)
    80005e0a:	40d0                	lw	a2,4(s1)
    80005e0c:	4494                	lw	a3,8(s1)
    80005e0e:	44d8                	lw	a4,12(s1)
    80005e10:	2701                	sext.w	a4,a4
    80005e12:	2681                	sext.w	a3,a3
    80005e14:	2601                	sext.w	a2,a2
    80005e16:	2581                	sext.w	a1,a1
    80005e18:	00007517          	auipc	a0,0x7
    80005e1c:	b8050513          	addi	a0,a0,-1152 # 8000c998 <syscalls+0x380>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	768080e7          	jalr	1896(ra) # 80000588 <printf>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e28:	4098                	lw	a4,0(s1)
    80005e2a:	2701                	sext.w	a4,a4
    80005e2c:	747277b7          	lui	a5,0x74727
    80005e30:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e34:	0ef71163          	bne	a4,a5,80005f16 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e38:	100017b7          	lui	a5,0x10001
    80005e3c:	43dc                	lw	a5,4(a5)
    80005e3e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e40:	4705                	li	a4,1
    80005e42:	0ce79a63          	bne	a5,a4,80005f16 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e46:	100017b7          	lui	a5,0x10001
    80005e4a:	479c                	lw	a5,8(a5)
    80005e4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e4e:	4709                	li	a4,2
    80005e50:	0ce79363          	bne	a5,a4,80005f16 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e54:	100017b7          	lui	a5,0x10001
    80005e58:	47d8                	lw	a4,12(a5)
    80005e5a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5c:	554d47b7          	lui	a5,0x554d4
    80005e60:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e64:	0af71963          	bne	a4,a5,80005f16 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e68:	100017b7          	lui	a5,0x10001
    80005e6c:	4705                	li	a4,1
    80005e6e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e70:	470d                	li	a4,3
    80005e72:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e74:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e76:	c7ffe737          	lui	a4,0xc7ffe
    80005e7a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc675f>
    80005e7e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e80:	2701                	sext.w	a4,a4
    80005e82:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e84:	472d                	li	a4,11
    80005e86:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e88:	473d                	li	a4,15
    80005e8a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e8c:	6711                	lui	a4,0x4
    80005e8e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e94:	5bdc                	lw	a5,52(a5)
    80005e96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e98:	c7d9                	beqz	a5,80005f26 <virtio_disk_init+0x144>
  if(max < NUM)
    80005e9a:	471d                	li	a4,7
    80005e9c:	08f77d63          	bgeu	a4,a5,80005f36 <virtio_disk_init+0x154>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ea0:	100014b7          	lui	s1,0x10001
    80005ea4:	47a1                	li	a5,8
    80005ea6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ea8:	6621                	lui	a2,0x8
    80005eaa:	4581                	li	a1,0
    80005eac:	00026517          	auipc	a0,0x26
    80005eb0:	15450513          	addi	a0,a0,340 # 8002c000 <disk>
    80005eb4:	ffffb097          	auipc	ra,0xffffb
    80005eb8:	e2c080e7          	jalr	-468(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ebc:	00026717          	auipc	a4,0x26
    80005ec0:	14470713          	addi	a4,a4,324 # 8002c000 <disk>
    80005ec4:	00e75793          	srli	a5,a4,0xe
    80005ec8:	2781                	sext.w	a5,a5
    80005eca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005ecc:	0002e797          	auipc	a5,0x2e
    80005ed0:	13478793          	addi	a5,a5,308 # 80034000 <disk+0x8000>
    80005ed4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005ed6:	00026717          	auipc	a4,0x26
    80005eda:	1aa70713          	addi	a4,a4,426 # 8002c080 <disk+0x80>
    80005ede:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005ee0:	0002a717          	auipc	a4,0x2a
    80005ee4:	12070713          	addi	a4,a4,288 # 80030000 <disk+0x4000>
    80005ee8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005eea:	4705                	li	a4,1
    80005eec:	00e78c23          	sb	a4,24(a5)
    80005ef0:	00e78ca3          	sb	a4,25(a5)
    80005ef4:	00e78d23          	sb	a4,26(a5)
    80005ef8:	00e78da3          	sb	a4,27(a5)
    80005efc:	00e78e23          	sb	a4,28(a5)
    80005f00:	00e78ea3          	sb	a4,29(a5)
    80005f04:	00e78f23          	sb	a4,30(a5)
    80005f08:	00e78fa3          	sb	a4,31(a5)
}
    80005f0c:	60e2                	ld	ra,24(sp)
    80005f0e:	6442                	ld	s0,16(sp)
    80005f10:	64a2                	ld	s1,8(sp)
    80005f12:	6105                	addi	sp,sp,32
    80005f14:	8082                	ret
    panic("could not find virtio disk");
    80005f16:	00007517          	auipc	a0,0x7
    80005f1a:	a9250513          	addi	a0,a0,-1390 # 8000c9a8 <syscalls+0x390>
    80005f1e:	ffffa097          	auipc	ra,0xffffa
    80005f22:	620080e7          	jalr	1568(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f26:	00007517          	auipc	a0,0x7
    80005f2a:	aa250513          	addi	a0,a0,-1374 # 8000c9c8 <syscalls+0x3b0>
    80005f2e:	ffffa097          	auipc	ra,0xffffa
    80005f32:	610080e7          	jalr	1552(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f36:	00007517          	auipc	a0,0x7
    80005f3a:	ab250513          	addi	a0,a0,-1358 # 8000c9e8 <syscalls+0x3d0>
    80005f3e:	ffffa097          	auipc	ra,0xffffa
    80005f42:	600080e7          	jalr	1536(ra) # 8000053e <panic>

0000000080005f46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f46:	7159                	addi	sp,sp,-112
    80005f48:	f486                	sd	ra,104(sp)
    80005f4a:	f0a2                	sd	s0,96(sp)
    80005f4c:	eca6                	sd	s1,88(sp)
    80005f4e:	e8ca                	sd	s2,80(sp)
    80005f50:	e4ce                	sd	s3,72(sp)
    80005f52:	e0d2                	sd	s4,64(sp)
    80005f54:	fc56                	sd	s5,56(sp)
    80005f56:	f85a                	sd	s6,48(sp)
    80005f58:	f45e                	sd	s7,40(sp)
    80005f5a:	f062                	sd	s8,32(sp)
    80005f5c:	ec66                	sd	s9,24(sp)
    80005f5e:	e86a                	sd	s10,16(sp)
    80005f60:	1880                	addi	s0,sp,112
    80005f62:	892a                	mv	s2,a0
    80005f64:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f66:	00c52c83          	lw	s9,12(a0)
    80005f6a:	001c9c9b          	slliw	s9,s9,0x1
    80005f6e:	1c82                	slli	s9,s9,0x20
    80005f70:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f74:	0002e517          	auipc	a0,0x2e
    80005f78:	1b450513          	addi	a0,a0,436 # 80034128 <disk+0x8128>
    80005f7c:	ffffb097          	auipc	ra,0xffffb
    80005f80:	c68080e7          	jalr	-920(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f84:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f86:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f88:	00026b97          	auipc	s7,0x26
    80005f8c:	078b8b93          	addi	s7,s7,120 # 8002c000 <disk>
    80005f90:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80005f92:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f94:	8a4e                	mv	s4,s3
    80005f96:	a051                	j	8000601a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f98:	00fb86b3          	add	a3,s7,a5
    80005f9c:	96da                	add	a3,a3,s6
    80005f9e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fa4:	0207c563          	bltz	a5,80005fce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fa8:	2485                	addiw	s1,s1,1
    80005faa:	0711                	addi	a4,a4,4
    80005fac:	25548463          	beq	s1,s5,800061f4 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80005fb0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb2:	0002e697          	auipc	a3,0x2e
    80005fb6:	06668693          	addi	a3,a3,102 # 80034018 <disk+0x8018>
    80005fba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fbc:	0006c583          	lbu	a1,0(a3)
    80005fc0:	fde1                	bnez	a1,80005f98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fc2:	2785                	addiw	a5,a5,1
    80005fc4:	0685                	addi	a3,a3,1
    80005fc6:	ff879be3          	bne	a5,s8,80005fbc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fca:	57fd                	li	a5,-1
    80005fcc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fce:	02905a63          	blez	s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd2:	f9042503          	lw	a0,-112(s0)
    80005fd6:	00000097          	auipc	ra,0x0
    80005fda:	d70080e7          	jalr	-656(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005fde:	4785                	li	a5,1
    80005fe0:	0297d163          	bge	a5,s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fe4:	f9442503          	lw	a0,-108(s0)
    80005fe8:	00000097          	auipc	ra,0x0
    80005fec:	d5e080e7          	jalr	-674(ra) # 80005d46 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff0:	4789                	li	a5,2
    80005ff2:	0097d863          	bge	a5,s1,80006002 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ff6:	f9842503          	lw	a0,-104(s0)
    80005ffa:	00000097          	auipc	ra,0x0
    80005ffe:	d4c080e7          	jalr	-692(ra) # 80005d46 <free_desc>
  while(1){

    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006002:	0002e597          	auipc	a1,0x2e
    80006006:	12658593          	addi	a1,a1,294 # 80034128 <disk+0x8128>
    8000600a:	0002e517          	auipc	a0,0x2e
    8000600e:	00e50513          	addi	a0,a0,14 # 80034018 <disk+0x8018>
    80006012:	ffffc097          	auipc	ra,0xffffc
    80006016:	16e080e7          	jalr	366(ra) # 80002180 <sleep>
  for(int i = 0; i < 3; i++){
    8000601a:	f9040713          	addi	a4,s0,-112
    8000601e:	84ce                	mv	s1,s3
    80006020:	bf41                	j	80005fb0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006022:	6705                	lui	a4,0x1
    80006024:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006028:	972e                	add	a4,a4,a1
    8000602a:	0712                	slli	a4,a4,0x4
    8000602c:	00026697          	auipc	a3,0x26
    80006030:	fd468693          	addi	a3,a3,-44 # 8002c000 <disk>
    80006034:	9736                	add	a4,a4,a3
    80006036:	4685                	li	a3,1
    80006038:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000603c:	6705                	lui	a4,0x1
    8000603e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006042:	972e                	add	a4,a4,a1
    80006044:	0712                	slli	a4,a4,0x4
    80006046:	00026697          	auipc	a3,0x26
    8000604a:	fba68693          	addi	a3,a3,-70 # 8002c000 <disk>
    8000604e:	9736                	add	a4,a4,a3
    80006050:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006054:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006058:	7661                	lui	a2,0xffff8
    8000605a:	963e                	add	a2,a2,a5
    8000605c:	0002e697          	auipc	a3,0x2e
    80006060:	fa468693          	addi	a3,a3,-92 # 80034000 <disk+0x8000>
    80006064:	6298                	ld	a4,0(a3)
    80006066:	9732                	add	a4,a4,a2
    80006068:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000606a:	6298                	ld	a4,0(a3)
    8000606c:	9732                	add	a4,a4,a2
    8000606e:	4541                	li	a0,16
    80006070:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006072:	6298                	ld	a4,0(a3)
    80006074:	9732                	add	a4,a4,a2
    80006076:	4505                	li	a0,1
    80006078:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    8000607c:	f9442703          	lw	a4,-108(s0)
    80006080:	6288                	ld	a0,0(a3)
    80006082:	962a                	add	a2,a2,a0
    80006084:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc000e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006088:	0712                	slli	a4,a4,0x4
    8000608a:	6290                	ld	a2,0(a3)
    8000608c:	963a                	add	a2,a2,a4
    8000608e:	05890513          	addi	a0,s2,88
    80006092:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006094:	6294                	ld	a3,0(a3)
    80006096:	96ba                	add	a3,a3,a4
    80006098:	40000613          	li	a2,1024
    8000609c:	c690                	sw	a2,8(a3)
  if(write)
    8000609e:	140d0263          	beqz	s10,800061e2 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060a2:	0002e697          	auipc	a3,0x2e
    800060a6:	f5e6b683          	ld	a3,-162(a3) # 80034000 <disk+0x8000>
    800060aa:	96ba                	add	a3,a3,a4
    800060ac:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060b0:	00026817          	auipc	a6,0x26
    800060b4:	f5080813          	addi	a6,a6,-176 # 8002c000 <disk>
    800060b8:	0002e697          	auipc	a3,0x2e
    800060bc:	f4868693          	addi	a3,a3,-184 # 80034000 <disk+0x8000>
    800060c0:	6290                	ld	a2,0(a3)
    800060c2:	963a                	add	a2,a2,a4
    800060c4:	00c65503          	lhu	a0,12(a2)
    800060c8:	00156513          	ori	a0,a0,1
    800060cc:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800060d0:	f9842603          	lw	a2,-104(s0)
    800060d4:	6288                	ld	a0,0(a3)
    800060d6:	972a                	add	a4,a4,a0
    800060d8:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060dc:	6705                	lui	a4,0x1
    800060de:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060e2:	972e                	add	a4,a4,a1
    800060e4:	0712                	slli	a4,a4,0x4
    800060e6:	9742                	add	a4,a4,a6
    800060e8:	557d                	li	a0,-1
    800060ea:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060ee:	0612                	slli	a2,a2,0x4
    800060f0:	6288                	ld	a0,0(a3)
    800060f2:	9532                	add	a0,a0,a2
    800060f4:	03078793          	addi	a5,a5,48
    800060f8:	97c2                	add	a5,a5,a6
    800060fa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800060fc:	629c                	ld	a5,0(a3)
    800060fe:	97b2                	add	a5,a5,a2
    80006100:	4505                	li	a0,1
    80006102:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006104:	629c                	ld	a5,0(a3)
    80006106:	97b2                	add	a5,a5,a2
    80006108:	4809                	li	a6,2
    8000610a:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    8000610e:	629c                	ld	a5,0(a3)
    80006110:	963e                	add	a2,a2,a5
    80006112:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006116:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    8000611a:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000611e:	6698                	ld	a4,8(a3)
    80006120:	00275783          	lhu	a5,2(a4)
    80006124:	8b9d                	andi	a5,a5,7
    80006126:	0786                	slli	a5,a5,0x1
    80006128:	97ba                	add	a5,a5,a4
    8000612a:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    8000612e:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006132:	6698                	ld	a4,8(a3)
    80006134:	00275783          	lhu	a5,2(a4)
    80006138:	2785                	addiw	a5,a5,1
    8000613a:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000613e:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006142:	100017b7          	lui	a5,0x10001
    80006146:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000614a:	00492703          	lw	a4,4(s2)
    8000614e:	4785                	li	a5,1
    80006150:	02f71163          	bne	a4,a5,80006172 <virtio_disk_rw+0x22c>
	  
    sleep(b, &disk.vdisk_lock);
    80006154:	0002e997          	auipc	s3,0x2e
    80006158:	fd498993          	addi	s3,s3,-44 # 80034128 <disk+0x8128>
  while(b->disk == 1) {
    8000615c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000615e:	85ce                	mv	a1,s3
    80006160:	854a                	mv	a0,s2
    80006162:	ffffc097          	auipc	ra,0xffffc
    80006166:	01e080e7          	jalr	30(ra) # 80002180 <sleep>
  while(b->disk == 1) {
    8000616a:	00492783          	lw	a5,4(s2)
    8000616e:	fe9788e3          	beq	a5,s1,8000615e <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006172:	f9042903          	lw	s2,-112(s0)
    80006176:	6785                	lui	a5,0x1
    80006178:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000617c:	97ca                	add	a5,a5,s2
    8000617e:	0792                	slli	a5,a5,0x4
    80006180:	00026717          	auipc	a4,0x26
    80006184:	e8070713          	addi	a4,a4,-384 # 8002c000 <disk>
    80006188:	97ba                	add	a5,a5,a4
    8000618a:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000618e:	0002e997          	auipc	s3,0x2e
    80006192:	e7298993          	addi	s3,s3,-398 # 80034000 <disk+0x8000>
    80006196:	00491713          	slli	a4,s2,0x4
    8000619a:	0009b783          	ld	a5,0(s3)
    8000619e:	97ba                	add	a5,a5,a4
    800061a0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061a4:	854a                	mv	a0,s2
    800061a6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061aa:	00000097          	auipc	ra,0x0
    800061ae:	b9c080e7          	jalr	-1124(ra) # 80005d46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061b2:	8885                	andi	s1,s1,1
    800061b4:	f0ed                	bnez	s1,80006196 <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061b6:	0002e517          	auipc	a0,0x2e
    800061ba:	f7250513          	addi	a0,a0,-142 # 80034128 <disk+0x8128>
    800061be:	ffffb097          	auipc	ra,0xffffb
    800061c2:	ada080e7          	jalr	-1318(ra) # 80000c98 <release>
}
    800061c6:	70a6                	ld	ra,104(sp)
    800061c8:	7406                	ld	s0,96(sp)
    800061ca:	64e6                	ld	s1,88(sp)
    800061cc:	6946                	ld	s2,80(sp)
    800061ce:	69a6                	ld	s3,72(sp)
    800061d0:	6a06                	ld	s4,64(sp)
    800061d2:	7ae2                	ld	s5,56(sp)
    800061d4:	7b42                	ld	s6,48(sp)
    800061d6:	7ba2                	ld	s7,40(sp)
    800061d8:	7c02                	ld	s8,32(sp)
    800061da:	6ce2                	ld	s9,24(sp)
    800061dc:	6d42                	ld	s10,16(sp)
    800061de:	6165                	addi	sp,sp,112
    800061e0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061e2:	0002e697          	auipc	a3,0x2e
    800061e6:	e1e6b683          	ld	a3,-482(a3) # 80034000 <disk+0x8000>
    800061ea:	96ba                	add	a3,a3,a4
    800061ec:	4609                	li	a2,2
    800061ee:	00c69623          	sh	a2,12(a3)
    800061f2:	bd7d                	j	800060b0 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061f4:	f9042583          	lw	a1,-112(s0)
    800061f8:	6785                	lui	a5,0x1
    800061fa:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800061fe:	97ae                	add	a5,a5,a1
    80006200:	0792                	slli	a5,a5,0x4
    80006202:	00026517          	auipc	a0,0x26
    80006206:	ea650513          	addi	a0,a0,-346 # 8002c0a8 <disk+0xa8>
    8000620a:	953e                	add	a0,a0,a5
  if(write)
    8000620c:	e00d1be3          	bnez	s10,80006022 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006210:	6705                	lui	a4,0x1
    80006212:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006216:	972e                	add	a4,a4,a1
    80006218:	0712                	slli	a4,a4,0x4
    8000621a:	00026697          	auipc	a3,0x26
    8000621e:	de668693          	addi	a3,a3,-538 # 8002c000 <disk>
    80006222:	9736                	add	a4,a4,a3
    80006224:	0a072423          	sw	zero,168(a4)
    80006228:	bd11                	j	8000603c <virtio_disk_rw+0xf6>

000000008000622a <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000622a:	7179                	addi	sp,sp,-48
    8000622c:	f406                	sd	ra,40(sp)
    8000622e:	f022                	sd	s0,32(sp)
    80006230:	ec26                	sd	s1,24(sp)
    80006232:	e84a                	sd	s2,16(sp)
    80006234:	e44e                	sd	s3,8(sp)
    80006236:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    80006238:	0002e517          	auipc	a0,0x2e
    8000623c:	ef050513          	addi	a0,a0,-272 # 80034128 <disk+0x8128>
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	9a4080e7          	jalr	-1628(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006248:	10001737          	lui	a4,0x10001
    8000624c:	533c                	lw	a5,96(a4)
    8000624e:	8b8d                	andi	a5,a5,3
    80006250:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006252:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.
      disk.used->idx++;
    80006256:	0002e797          	auipc	a5,0x2e
    8000625a:	daa78793          	addi	a5,a5,-598 # 80034000 <disk+0x8000>
    8000625e:	6b94                	ld	a3,16(a5)
    80006260:	0026d703          	lhu	a4,2(a3)
    80006264:	2705                	addiw	a4,a4,1
    80006266:	00e69123          	sh	a4,2(a3)
  while(disk.used_idx != disk.used->idx){
    8000626a:	6b94                	ld	a3,16(a5)
    8000626c:	0207d703          	lhu	a4,32(a5)
    80006270:	0026d783          	lhu	a5,2(a3)
    80006274:	06f70363          	beq	a4,a5,800062da <virtio_disk_intr+0xb0>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006278:	00026997          	auipc	s3,0x26
    8000627c:	d8898993          	addi	s3,s3,-632 # 8002c000 <disk>
    80006280:	0002e497          	auipc	s1,0x2e
    80006284:	d8048493          	addi	s1,s1,-640 # 80034000 <disk+0x8000>

    if(disk.info[id].status != 0)
    80006288:	6905                	lui	s2,0x1
    8000628a:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    8000628e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006292:	6898                	ld	a4,16(s1)
    80006294:	0204d783          	lhu	a5,32(s1)
    80006298:	8b9d                	andi	a5,a5,7
    8000629a:	078e                	slli	a5,a5,0x3
    8000629c:	97ba                	add	a5,a5,a4
    8000629e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062a0:	01278733          	add	a4,a5,s2
    800062a4:	0712                	slli	a4,a4,0x4
    800062a6:	974e                	add	a4,a4,s3
    800062a8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062ac:	e731                	bnez	a4,800062f8 <virtio_disk_intr+0xce>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062ae:	97ca                	add	a5,a5,s2
    800062b0:	0792                	slli	a5,a5,0x4
    800062b2:	97ce                	add	a5,a5,s3
    800062b4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062b6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ba:	ffffc097          	auipc	ra,0xffffc
    800062be:	052080e7          	jalr	82(ra) # 8000230c <wakeup>

    disk.used_idx += 1;
    800062c2:	0204d783          	lhu	a5,32(s1)
    800062c6:	2785                	addiw	a5,a5,1
    800062c8:	17c2                	slli	a5,a5,0x30
    800062ca:	93c1                	srli	a5,a5,0x30
    800062cc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062d0:	6898                	ld	a4,16(s1)
    800062d2:	00275703          	lhu	a4,2(a4)
    800062d6:	faf71ce3          	bne	a4,a5,8000628e <virtio_disk_intr+0x64>
  }

  release(&disk.vdisk_lock);
    800062da:	0002e517          	auipc	a0,0x2e
    800062de:	e4e50513          	addi	a0,a0,-434 # 80034128 <disk+0x8128>
    800062e2:	ffffb097          	auipc	ra,0xffffb
    800062e6:	9b6080e7          	jalr	-1610(ra) # 80000c98 <release>
}
    800062ea:	70a2                	ld	ra,40(sp)
    800062ec:	7402                	ld	s0,32(sp)
    800062ee:	64e2                	ld	s1,24(sp)
    800062f0:	6942                	ld	s2,16(sp)
    800062f2:	69a2                	ld	s3,8(sp)
    800062f4:	6145                	addi	sp,sp,48
    800062f6:	8082                	ret
      panic("virtio_disk_intr status");
    800062f8:	00006517          	auipc	a0,0x6
    800062fc:	71050513          	addi	a0,a0,1808 # 8000ca08 <syscalls+0x3f0>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	23e080e7          	jalr	574(ra) # 8000053e <panic>
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
