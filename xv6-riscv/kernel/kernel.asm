
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
    80000068:	cbc78793          	addi	a5,a5,-836 # 80005d20 <timervec>
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
    80000130:	4ca080e7          	jalr	1226(ra) # 800025f6 <either_copyin>
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
    800001c8:	948080e7          	jalr	-1720(ra) # 80001b0c <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	028080e7          	jalr	40(ra) # 800021fc <sleep>
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
    80000214:	390080e7          	jalr	912(ra) # 800025a0 <either_copyout>
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
    800002f6:	35a080e7          	jalr	858(ra) # 8000264c <procdump>
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
    8000044a:	f42080e7          	jalr	-190(ra) # 80002388 <wakeup>
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
    800008a4:	ae8080e7          	jalr	-1304(ra) # 80002388 <wakeup>
    
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
    80000930:	8d0080e7          	jalr	-1840(ra) # 800021fc <sleep>
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
    80000b82:	f72080e7          	jalr	-142(ra) # 80001af0 <mycpu>
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
    80000bb4:	f40080e7          	jalr	-192(ra) # 80001af0 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f34080e7          	jalr	-204(ra) # 80001af0 <mycpu>
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
    80000bd8:	f1c080e7          	jalr	-228(ra) # 80001af0 <mycpu>
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
    80000c18:	edc080e7          	jalr	-292(ra) # 80001af0 <mycpu>
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
    80000c44:	eb0080e7          	jalr	-336(ra) # 80001af0 <mycpu>
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
    80000e9a:	c4a080e7          	jalr	-950(ra) # 80001ae0 <cpuid>
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
    80000eb6:	c2e080e7          	jalr	-978(ra) # 80001ae0 <cpuid>
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
    80000ed8:	8b8080e7          	jalr	-1864(ra) # 8000278c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e84080e7          	jalr	-380(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	166080e7          	jalr	358(ra) # 8000204a <scheduler>
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
    80000f58:	442080e7          	jalr	1090(ra) # 80001396 <kvminit>
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
    80000f88:	aac080e7          	jalr	-1364(ra) # 80001a30 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	7d8080e7          	jalr	2008(ra) # 80002764 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	7f8080e7          	jalr	2040(ra) # 8000278c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	dae080e7          	jalr	-594(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	dbc080e7          	jalr	-580(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	f3e080e7          	jalr	-194(ra) # 80002eea <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	5e0080e7          	jalr	1504(ra) # 80003594 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	58a080e7          	jalr	1418(ra) # 80004546 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	ebe080e7          	jalr	-322(ra) # 80005e82 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	e18080e7          	jalr	-488(ra) # 80001de4 <userinit>
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
    80001036:	8bb2                	mv	s7,a2
    80001038:	8ab6                	mv	s5,a3
  if(va >= MAXVA)
    8000103a:	57fd                	li	a5,-1
    8000103c:	83ed                	srli	a5,a5,0x1b
    8000103e:	02000b13          	li	s6,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001042:	4a09                	li	s4,2
    pte_t *pte = &pagetable[PX(level, va)];
	  if(print){
		  printf("[lv%d] table %x, entry %d >> PA %x (PTE%x)\n",
    80001044:	4c89                	li	s9,2
    80001046:	0000bc17          	auipc	s8,0xb
    8000104a:	112c0c13          	addi	s8,s8,274 # 8000c158 <digits+0x118>
  if(va >= MAXVA)
    8000104e:	06b7f163          	bgeu	a5,a1,800010b0 <walk+0x98>
    panic("walk");
    80001052:	0000b517          	auipc	a0,0xb
    80001056:	0fe50513          	addi	a0,a0,254 # 8000c150 <digits+0x110>
    8000105a:	fffff097          	auipc	ra,0xfffff
    8000105e:	4e4080e7          	jalr	1252(ra) # 8000053e <panic>
				  2-level, pagetable, PX(level,va), PTE2PA(*pte), pte);
    80001062:	0009b703          	ld	a4,0(s3) # 4000 <_entry-0x7fffc000>
    80001066:	8329                	srli	a4,a4,0xa
		  printf("[lv%d] table %x, entry %d >> PA %x (PTE%x)\n",
    80001068:	87ce                	mv	a5,s3
    8000106a:	073a                	slli	a4,a4,0xe
    8000106c:	8626                	mv	a2,s1
    8000106e:	414c85bb          	subw	a1,s9,s4
    80001072:	8562                	mv	a0,s8
    80001074:	fffff097          	auipc	ra,0xfffff
    80001078:	514080e7          	jalr	1300(ra) # 80000588 <printf>
    8000107c:	a099                	j	800010c2 <walk+0xaa>
	  }
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000107e:	0a0b8863          	beqz	s7,8000112e <walk+0x116>
    80001082:	00000097          	auipc	ra,0x0
    80001086:	a72080e7          	jalr	-1422(ra) # 80000af4 <kalloc>
    8000108a:	84aa                	mv	s1,a0
    8000108c:	c53d                	beqz	a0,800010fa <walk+0xe2>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000108e:	6611                	lui	a2,0x4
    80001090:	4581                	li	a1,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	c4e080e7          	jalr	-946(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000109a:	00e4d793          	srli	a5,s1,0xe
    8000109e:	07aa                	slli	a5,a5,0xa
    800010a0:	0017e793          	ori	a5,a5,1
    800010a4:	00f9b023          	sd	a5,0(s3)
  for(int level = 2; level > 0; level--) {
    800010a8:	3a7d                	addiw	s4,s4,-1
    800010aa:	3b5d                	addiw	s6,s6,-9
    800010ac:	020a0363          	beqz	s4,800010d2 <walk+0xba>
    pte_t *pte = &pagetable[PX(level, va)];
    800010b0:	016956b3          	srl	a3,s2,s6
    800010b4:	1ff6f693          	andi	a3,a3,511
    800010b8:	00369993          	slli	s3,a3,0x3
    800010bc:	99a6                	add	s3,s3,s1
	  if(print){
    800010be:	fa0a92e3          	bnez	s5,80001062 <walk+0x4a>
    if(*pte & PTE_V) {
    800010c2:	0009b483          	ld	s1,0(s3)
    800010c6:	0014f793          	andi	a5,s1,1
    800010ca:	dbd5                	beqz	a5,8000107e <walk+0x66>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010cc:	80a9                	srli	s1,s1,0xa
    800010ce:	04ba                	slli	s1,s1,0xe
    800010d0:	bfe1                	j	800010a8 <walk+0x90>
    }
  }
  pte_t final_pte = pagetable[PX(0,va)];
    800010d2:	00e95513          	srli	a0,s2,0xe
    800010d6:	1ff57513          	andi	a0,a0,511
    800010da:	050e                	slli	a0,a0,0x3
    800010dc:	94aa                	add	s1,s1,a0
  if(print){
    800010de:	000a8e63          	beqz	s5,800010fa <walk+0xe2>
  pte_t final_pte = pagetable[PX(0,va)];
    800010e2:	608c                	ld	a1,0(s1)
	  if((final_pte & PTE_V) == 0){
    800010e4:	0015f793          	andi	a5,a1,1
    800010e8:	e79d                	bnez	a5,80001116 <walk+0xfe>
		  printf("[lv2] value in PTE %x is invalid.\n",final_pte);
    800010ea:	0000b517          	auipc	a0,0xb
    800010ee:	09e50513          	addi	a0,a0,158 # 8000c188 <digits+0x148>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	496080e7          	jalr	1174(ra) # 80000588 <printf>
	  }else{
            	  printf("[lv2] final PA in PTE %x: %x\n",final_pte, PTE2PA(final_pte));
	  }
  }
  return &pagetable[PX(0, va)];
}
    800010fa:	8526                	mv	a0,s1
    800010fc:	60e6                	ld	ra,88(sp)
    800010fe:	6446                	ld	s0,80(sp)
    80001100:	64a6                	ld	s1,72(sp)
    80001102:	6906                	ld	s2,64(sp)
    80001104:	79e2                	ld	s3,56(sp)
    80001106:	7a42                	ld	s4,48(sp)
    80001108:	7aa2                	ld	s5,40(sp)
    8000110a:	7b02                	ld	s6,32(sp)
    8000110c:	6be2                	ld	s7,24(sp)
    8000110e:	6c42                	ld	s8,16(sp)
    80001110:	6ca2                	ld	s9,8(sp)
    80001112:	6125                	addi	sp,sp,96
    80001114:	8082                	ret
            	  printf("[lv2] final PA in PTE %x: %x\n",final_pte, PTE2PA(final_pte));
    80001116:	00a5d613          	srli	a2,a1,0xa
    8000111a:	063a                	slli	a2,a2,0xe
    8000111c:	0000b517          	auipc	a0,0xb
    80001120:	09450513          	addi	a0,a0,148 # 8000c1b0 <digits+0x170>
    80001124:	fffff097          	auipc	ra,0xfffff
    80001128:	464080e7          	jalr	1124(ra) # 80000588 <printf>
    8000112c:	b7f9                	j	800010fa <walk+0xe2>
        return 0;
    8000112e:	4481                	li	s1,0
    80001130:	b7e9                	j	800010fa <walk+0xe2>

0000000080001132 <trace_mem>:

void trace_mem(pagetable_t pagetable, uint64 va){
    80001132:	1141                	addi	sp,sp,-16
    80001134:	e406                	sd	ra,8(sp)
    80001136:	e022                	sd	s0,0(sp)
    80001138:	0800                	addi	s0,sp,16
	walk(pagetable,va,0,1);
    8000113a:	4685                	li	a3,1
    8000113c:	4601                	li	a2,0
    8000113e:	00000097          	auipc	ra,0x0
    80001142:	eda080e7          	jalr	-294(ra) # 80001018 <walk>
}
    80001146:	60a2                	ld	ra,8(sp)
    80001148:	6402                	ld	s0,0(sp)
    8000114a:	0141                	addi	sp,sp,16
    8000114c:	8082                	ret

000000008000114e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000114e:	57fd                	li	a5,-1
    80001150:	83ed                	srli	a5,a5,0x1b
    80001152:	00b7f463          	bgeu	a5,a1,8000115a <walkaddr+0xc>
    return 0;
    80001156:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001158:	8082                	ret
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0, 0);
    80001162:	4681                	li	a3,0
    80001164:	4601                	li	a2,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	eb2080e7          	jalr	-334(ra) # 80001018 <walk>
  if(pte == 0)
    8000116e:	c105                	beqz	a0,8000118e <walkaddr+0x40>
  if((*pte & PTE_V) == 0)
    80001170:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001172:	0117f693          	andi	a3,a5,17
    80001176:	4745                	li	a4,17
    return 0;
    80001178:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000117a:	00e68663          	beq	a3,a4,80001186 <walkaddr+0x38>
}
    8000117e:	60a2                	ld	ra,8(sp)
    80001180:	6402                	ld	s0,0(sp)
    80001182:	0141                	addi	sp,sp,16
    80001184:	8082                	ret
  pa = PTE2PA(*pte);
    80001186:	00a7d513          	srli	a0,a5,0xa
    8000118a:	053a                	slli	a0,a0,0xe
  return pa;
    8000118c:	bfcd                	j	8000117e <walkaddr+0x30>
    return 0;
    8000118e:	4501                	li	a0,0
    80001190:	b7fd                	j	8000117e <walkaddr+0x30>

0000000080001192 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001192:	715d                	addi	sp,sp,-80
    80001194:	e486                	sd	ra,72(sp)
    80001196:	e0a2                	sd	s0,64(sp)
    80001198:	fc26                	sd	s1,56(sp)
    8000119a:	f84a                	sd	s2,48(sp)
    8000119c:	f44e                	sd	s3,40(sp)
    8000119e:	f052                	sd	s4,32(sp)
    800011a0:	ec56                	sd	s5,24(sp)
    800011a2:	e85a                	sd	s6,16(sp)
    800011a4:	e45e                	sd	s7,8(sp)
    800011a6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;


  if(size == 0)
    800011a8:	c205                	beqz	a2,800011c8 <mappages+0x36>
    800011aa:	8aaa                	mv	s5,a0
    800011ac:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011ae:	77f1                	lui	a5,0xffffc
    800011b0:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011b4:	15fd                	addi	a1,a1,-1
    800011b6:	00c589b3          	add	s3,a1,a2
    800011ba:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011be:	8952                	mv	s2,s4
    800011c0:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011c4:	6b91                	lui	s7,0x4
    800011c6:	a015                	j	800011ea <mappages+0x58>
    panic("mappages: size");
    800011c8:	0000b517          	auipc	a0,0xb
    800011cc:	00850513          	addi	a0,a0,8 # 8000c1d0 <digits+0x190>
    800011d0:	fffff097          	auipc	ra,0xfffff
    800011d4:	36e080e7          	jalr	878(ra) # 8000053e <panic>
      panic("mappages: remap");
    800011d8:	0000b517          	auipc	a0,0xb
    800011dc:	00850513          	addi	a0,a0,8 # 8000c1e0 <digits+0x1a0>
    800011e0:	fffff097          	auipc	ra,0xfffff
    800011e4:	35e080e7          	jalr	862(ra) # 8000053e <panic>
    a += PGSIZE;
    800011e8:	995e                	add	s2,s2,s7
  for(;;){
    800011ea:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1, 0)) == 0)
    800011ee:	4681                	li	a3,0
    800011f0:	4605                	li	a2,1
    800011f2:	85ca                	mv	a1,s2
    800011f4:	8556                	mv	a0,s5
    800011f6:	00000097          	auipc	ra,0x0
    800011fa:	e22080e7          	jalr	-478(ra) # 80001018 <walk>
    800011fe:	cd19                	beqz	a0,8000121c <mappages+0x8a>
    if(*pte & PTE_V)
    80001200:	611c                	ld	a5,0(a0)
    80001202:	8b85                	andi	a5,a5,1
    80001204:	fbf1                	bnez	a5,800011d8 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001206:	80b9                	srli	s1,s1,0xe
    80001208:	04aa                	slli	s1,s1,0xa
    8000120a:	0164e4b3          	or	s1,s1,s6
    8000120e:	0014e493          	ori	s1,s1,1
    80001212:	e104                	sd	s1,0(a0)
    if(a == last)
    80001214:	fd391ae3          	bne	s2,s3,800011e8 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001218:	4501                	li	a0,0
    8000121a:	a011                	j	8000121e <mappages+0x8c>
      return -1;
    8000121c:	557d                	li	a0,-1
}
    8000121e:	60a6                	ld	ra,72(sp)
    80001220:	6406                	ld	s0,64(sp)
    80001222:	74e2                	ld	s1,56(sp)
    80001224:	7942                	ld	s2,48(sp)
    80001226:	79a2                	ld	s3,40(sp)
    80001228:	7a02                	ld	s4,32(sp)
    8000122a:	6ae2                	ld	s5,24(sp)
    8000122c:	6b42                	ld	s6,16(sp)
    8000122e:	6ba2                	ld	s7,8(sp)
    80001230:	6161                	addi	sp,sp,80
    80001232:	8082                	ret

0000000080001234 <kvmmap>:
{
    80001234:	1141                	addi	sp,sp,-16
    80001236:	e406                	sd	ra,8(sp)
    80001238:	e022                	sd	s0,0(sp)
    8000123a:	0800                	addi	s0,sp,16
    8000123c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000123e:	86b2                	mv	a3,a2
    80001240:	863e                	mv	a2,a5
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f50080e7          	jalr	-176(ra) # 80001192 <mappages>
    8000124a:	e509                	bnez	a0,80001254 <kvmmap+0x20>
}
    8000124c:	60a2                	ld	ra,8(sp)
    8000124e:	6402                	ld	s0,0(sp)
    80001250:	0141                	addi	sp,sp,16
    80001252:	8082                	ret
    panic("kvmmap");
    80001254:	0000b517          	auipc	a0,0xb
    80001258:	f9c50513          	addi	a0,a0,-100 # 8000c1f0 <digits+0x1b0>
    8000125c:	fffff097          	auipc	ra,0xfffff
    80001260:	2e2080e7          	jalr	738(ra) # 8000053e <panic>

0000000080001264 <kvmmake>:
{
    80001264:	7179                	addi	sp,sp,-48
    80001266:	f406                	sd	ra,40(sp)
    80001268:	f022                	sd	s0,32(sp)
    8000126a:	ec26                	sd	s1,24(sp)
    8000126c:	e84a                	sd	s2,16(sp)
    8000126e:	e44e                	sd	s3,8(sp)
    80001270:	1800                	addi	s0,sp,48
  kpgtbl = (pagetable_t) kalloc();
    80001272:	00000097          	auipc	ra,0x0
    80001276:	882080e7          	jalr	-1918(ra) # 80000af4 <kalloc>
    8000127a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000127c:	6611                	lui	a2,0x4
    8000127e:	4581                	li	a1,0
    80001280:	00000097          	auipc	ra,0x0
    80001284:	a60080e7          	jalr	-1440(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001288:	4719                	li	a4,6
    8000128a:	6691                	lui	a3,0x4
    8000128c:	10000637          	lui	a2,0x10000
    80001290:	100005b7          	lui	a1,0x10000
    80001294:	8526                	mv	a0,s1
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	f9e080e7          	jalr	-98(ra) # 80001234 <kvmmap>
  printf("mapping uart in %x\n", UART0);
    8000129e:	100005b7          	lui	a1,0x10000
    800012a2:	0000b517          	auipc	a0,0xb
    800012a6:	f5650513          	addi	a0,a0,-170 # 8000c1f8 <digits+0x1b8>
    800012aa:	fffff097          	auipc	ra,0xfffff
    800012ae:	2de080e7          	jalr	734(ra) # 80000588 <printf>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b2:	4719                	li	a4,6
    800012b4:	004006b7          	lui	a3,0x400
    800012b8:	0c000637          	lui	a2,0xc000
    800012bc:	0c0005b7          	lui	a1,0xc000
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f72080e7          	jalr	-142(ra) # 80001234 <kvmmap>
  printf("mapping PLIC in %x\n", PLIC);
    800012ca:	0c0005b7          	lui	a1,0xc000
    800012ce:	0000b517          	auipc	a0,0xb
    800012d2:	f4250513          	addi	a0,a0,-190 # 8000c210 <digits+0x1d0>
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	2b2080e7          	jalr	690(ra) # 80000588 <printf>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012de:	0000b917          	auipc	s2,0xb
    800012e2:	d2290913          	addi	s2,s2,-734 # 8000c000 <etext>
    800012e6:	4729                	li	a4,10
    800012e8:	8000b697          	auipc	a3,0x8000b
    800012ec:	d1868693          	addi	a3,a3,-744 # c000 <_entry-0x7fff4000>
    800012f0:	4985                	li	s3,1
    800012f2:	01f99613          	slli	a2,s3,0x1f
    800012f6:	85b2                	mv	a1,a2
    800012f8:	8526                	mv	a0,s1
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	f3a080e7          	jalr	-198(ra) # 80001234 <kvmmap>
  printf("mapping kernel text in %x\n", KERNBASE);
    80001302:	01f99593          	slli	a1,s3,0x1f
    80001306:	0000b517          	auipc	a0,0xb
    8000130a:	f2250513          	addi	a0,a0,-222 # 8000c228 <digits+0x1e8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	27a080e7          	jalr	634(ra) # 80000588 <printf>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001316:	4719                	li	a4,6
    80001318:	46c5                	li	a3,17
    8000131a:	06ee                	slli	a3,a3,0x1b
    8000131c:	412686b3          	sub	a3,a3,s2
    80001320:	864a                	mv	a2,s2
    80001322:	85ca                	mv	a1,s2
    80001324:	8526                	mv	a0,s1
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	f0e080e7          	jalr	-242(ra) # 80001234 <kvmmap>
  printf("mapping trampoline for trap from %x to %x.\n",TRAMPOLINE, trampoline);
    8000132e:	00007617          	auipc	a2,0x7
    80001332:	cd260613          	addi	a2,a2,-814 # 80008000 <_trampoline>
    80001336:	00800937          	lui	s2,0x800
    8000133a:	197d                	addi	s2,s2,-1
    8000133c:	00e91593          	slli	a1,s2,0xe
    80001340:	0000b517          	auipc	a0,0xb
    80001344:	f0850513          	addi	a0,a0,-248 # 8000c248 <digits+0x208>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	240080e7          	jalr	576(ra) # 80000588 <printf>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001350:	4729                	li	a4,10
    80001352:	6691                	lui	a3,0x4
    80001354:	00007617          	auipc	a2,0x7
    80001358:	cac60613          	addi	a2,a2,-852 # 80008000 <_trampoline>
    8000135c:	00e91593          	slli	a1,s2,0xe
    80001360:	8526                	mv	a0,s1
    80001362:	00000097          	auipc	ra,0x0
    80001366:	ed2080e7          	jalr	-302(ra) # 80001234 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000136a:	8526                	mv	a0,s1
    8000136c:	00000097          	auipc	ra,0x0
    80001370:	62e080e7          	jalr	1582(ra) # 8000199a <proc_mapstacks>
  printf("kernel pagetable created with VA: %x.\n",kpgtbl);
    80001374:	85a6                	mv	a1,s1
    80001376:	0000b517          	auipc	a0,0xb
    8000137a:	f0250513          	addi	a0,a0,-254 # 8000c278 <digits+0x238>
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	20a080e7          	jalr	522(ra) # 80000588 <printf>
}
    80001386:	8526                	mv	a0,s1
    80001388:	70a2                	ld	ra,40(sp)
    8000138a:	7402                	ld	s0,32(sp)
    8000138c:	64e2                	ld	s1,24(sp)
    8000138e:	6942                	ld	s2,16(sp)
    80001390:	69a2                	ld	s3,8(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret

0000000080001396 <kvminit>:
{
    80001396:	1141                	addi	sp,sp,-16
    80001398:	e406                	sd	ra,8(sp)
    8000139a:	e022                	sd	s0,0(sp)
    8000139c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	ec6080e7          	jalr	-314(ra) # 80001264 <kvmmake>
    800013a6:	0000f797          	auipc	a5,0xf
    800013aa:	c6a7bd23          	sd	a0,-902(a5) # 80010020 <kernel_pagetable>
}
    800013ae:	60a2                	ld	ra,8(sp)
    800013b0:	6402                	ld	s0,0(sp)
    800013b2:	0141                	addi	sp,sp,16
    800013b4:	8082                	ret

00000000800013b6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013b6:	715d                	addi	sp,sp,-80
    800013b8:	e486                	sd	ra,72(sp)
    800013ba:	e0a2                	sd	s0,64(sp)
    800013bc:	fc26                	sd	s1,56(sp)
    800013be:	f84a                	sd	s2,48(sp)
    800013c0:	f44e                	sd	s3,40(sp)
    800013c2:	f052                	sd	s4,32(sp)
    800013c4:	ec56                	sd	s5,24(sp)
    800013c6:	e85a                	sd	s6,16(sp)
    800013c8:	e45e                	sd	s7,8(sp)
    800013ca:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013cc:	03259793          	slli	a5,a1,0x32
    800013d0:	e795                	bnez	a5,800013fc <uvmunmap+0x46>
    800013d2:	8a2a                	mv	s4,a0
    800013d4:	892e                	mv	s2,a1
    800013d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d8:	063a                	slli	a2,a2,0xe
    800013da:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013de:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e0:	6b11                	lui	s6,0x4
    800013e2:	0735e863          	bltu	a1,s3,80001452 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013e6:	60a6                	ld	ra,72(sp)
    800013e8:	6406                	ld	s0,64(sp)
    800013ea:	74e2                	ld	s1,56(sp)
    800013ec:	7942                	ld	s2,48(sp)
    800013ee:	79a2                	ld	s3,40(sp)
    800013f0:	7a02                	ld	s4,32(sp)
    800013f2:	6ae2                	ld	s5,24(sp)
    800013f4:	6b42                	ld	s6,16(sp)
    800013f6:	6ba2                	ld	s7,8(sp)
    800013f8:	6161                	addi	sp,sp,80
    800013fa:	8082                	ret
    panic("uvmunmap: not aligned");
    800013fc:	0000b517          	auipc	a0,0xb
    80001400:	ea450513          	addi	a0,a0,-348 # 8000c2a0 <digits+0x260>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	13a080e7          	jalr	314(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000140c:	0000b517          	auipc	a0,0xb
    80001410:	eac50513          	addi	a0,a0,-340 # 8000c2b8 <digits+0x278>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	12a080e7          	jalr	298(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000141c:	0000b517          	auipc	a0,0xb
    80001420:	eac50513          	addi	a0,a0,-340 # 8000c2c8 <digits+0x288>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	11a080e7          	jalr	282(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000142c:	0000b517          	auipc	a0,0xb
    80001430:	eb450513          	addi	a0,a0,-332 # 8000c2e0 <digits+0x2a0>
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	10a080e7          	jalr	266(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000143c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000143e:	053a                	slli	a0,a0,0xe
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	5b8080e7          	jalr	1464(ra) # 800009f8 <kfree>
    *pte = 0;
    80001448:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000144c:	995a                	add	s2,s2,s6
    8000144e:	f9397ce3          	bgeu	s2,s3,800013e6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0, 0)) == 0)
    80001452:	4681                	li	a3,0
    80001454:	4601                	li	a2,0
    80001456:	85ca                	mv	a1,s2
    80001458:	8552                	mv	a0,s4
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	bbe080e7          	jalr	-1090(ra) # 80001018 <walk>
    80001462:	84aa                	mv	s1,a0
    80001464:	d545                	beqz	a0,8000140c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001466:	6108                	ld	a0,0(a0)
    80001468:	00157793          	andi	a5,a0,1
    8000146c:	dbc5                	beqz	a5,8000141c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000146e:	3ff57793          	andi	a5,a0,1023
    80001472:	fb778de3          	beq	a5,s7,8000142c <uvmunmap+0x76>
    if(do_free){
    80001476:	fc0a89e3          	beqz	s5,80001448 <uvmunmap+0x92>
    8000147a:	b7c9                	j	8000143c <uvmunmap+0x86>

000000008000147c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000147c:	1101                	addi	sp,sp,-32
    8000147e:	ec06                	sd	ra,24(sp)
    80001480:	e822                	sd	s0,16(sp)
    80001482:	e426                	sd	s1,8(sp)
    80001484:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	66e080e7          	jalr	1646(ra) # 80000af4 <kalloc>
    8000148e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001490:	c519                	beqz	a0,8000149e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001492:	6611                	lui	a2,0x4
    80001494:	4581                	li	a1,0
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	84a080e7          	jalr	-1974(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000149e:	8526                	mv	a0,s1
    800014a0:	60e2                	ld	ra,24(sp)
    800014a2:	6442                	ld	s0,16(sp)
    800014a4:	64a2                	ld	s1,8(sp)
    800014a6:	6105                	addi	sp,sp,32
    800014a8:	8082                	ret

00000000800014aa <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014aa:	7179                	addi	sp,sp,-48
    800014ac:	f406                	sd	ra,40(sp)
    800014ae:	f022                	sd	s0,32(sp)
    800014b0:	ec26                	sd	s1,24(sp)
    800014b2:	e84a                	sd	s2,16(sp)
    800014b4:	e44e                	sd	s3,8(sp)
    800014b6:	e052                	sd	s4,0(sp)
    800014b8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014ba:	6791                	lui	a5,0x4
    800014bc:	06f67363          	bgeu	a2,a5,80001522 <uvminit+0x78>
    800014c0:	89aa                	mv	s3,a0
    800014c2:	8a2e                	mv	s4,a1
    800014c4:	8932                	mv	s2,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	62e080e7          	jalr	1582(ra) # 80000af4 <kalloc>
    800014ce:	84aa                	mv	s1,a0
  memset(mem, 0, PGSIZE);
    800014d0:	6611                	lui	a2,0x4
    800014d2:	4581                	li	a1,0
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	80c080e7          	jalr	-2036(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014dc:	4779                	li	a4,30
    800014de:	86a6                	mv	a3,s1
    800014e0:	6611                	lui	a2,0x4
    800014e2:	4581                	li	a1,0
    800014e4:	854e                	mv	a0,s3
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	cac080e7          	jalr	-852(ra) # 80001192 <mappages>
  memmove(mem, src, sz);
    800014ee:	864a                	mv	a2,s2
    800014f0:	85d2                	mv	a1,s4
    800014f2:	8526                	mv	a0,s1
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	84c080e7          	jalr	-1972(ra) # 80000d40 <memmove>

  printf("use a page %d in loc %x in pagetable %x to store codes.\n", PGSIZE, mem, pagetable);
    800014fc:	86ce                	mv	a3,s3
    800014fe:	8626                	mv	a2,s1
    80001500:	6591                	lui	a1,0x4
    80001502:	0000b517          	auipc	a0,0xb
    80001506:	e1650513          	addi	a0,a0,-490 # 8000c318 <digits+0x2d8>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	07e080e7          	jalr	126(ra) # 80000588 <printf>
}
    80001512:	70a2                	ld	ra,40(sp)
    80001514:	7402                	ld	s0,32(sp)
    80001516:	64e2                	ld	s1,24(sp)
    80001518:	6942                	ld	s2,16(sp)
    8000151a:	69a2                	ld	s3,8(sp)
    8000151c:	6a02                	ld	s4,0(sp)
    8000151e:	6145                	addi	sp,sp,48
    80001520:	8082                	ret
    panic("inituvm: more than a page");
    80001522:	0000b517          	auipc	a0,0xb
    80001526:	dd650513          	addi	a0,a0,-554 # 8000c2f8 <digits+0x2b8>
    8000152a:	fffff097          	auipc	ra,0xfffff
    8000152e:	014080e7          	jalr	20(ra) # 8000053e <panic>

0000000080001532 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001532:	1101                	addi	sp,sp,-32
    80001534:	ec06                	sd	ra,24(sp)
    80001536:	e822                	sd	s0,16(sp)
    80001538:	e426                	sd	s1,8(sp)
    8000153a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000153c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000153e:	00b67d63          	bgeu	a2,a1,80001558 <uvmdealloc+0x26>
    80001542:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001544:	6791                	lui	a5,0x4
    80001546:	17fd                	addi	a5,a5,-1
    80001548:	00f60733          	add	a4,a2,a5
    8000154c:	7671                	lui	a2,0xffffc
    8000154e:	8f71                	and	a4,a4,a2
    80001550:	97ae                	add	a5,a5,a1
    80001552:	8ff1                	and	a5,a5,a2
    80001554:	00f76863          	bltu	a4,a5,80001564 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001558:	8526                	mv	a0,s1
    8000155a:	60e2                	ld	ra,24(sp)
    8000155c:	6442                	ld	s0,16(sp)
    8000155e:	64a2                	ld	s1,8(sp)
    80001560:	6105                	addi	sp,sp,32
    80001562:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001564:	8f99                	sub	a5,a5,a4
    80001566:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001568:	4685                	li	a3,1
    8000156a:	0007861b          	sext.w	a2,a5
    8000156e:	85ba                	mv	a1,a4
    80001570:	00000097          	auipc	ra,0x0
    80001574:	e46080e7          	jalr	-442(ra) # 800013b6 <uvmunmap>
    80001578:	b7c5                	j	80001558 <uvmdealloc+0x26>

000000008000157a <uvmalloc>:
  if(newsz < oldsz)
    8000157a:	0ab66163          	bltu	a2,a1,8000161c <uvmalloc+0xa2>
{
    8000157e:	7139                	addi	sp,sp,-64
    80001580:	fc06                	sd	ra,56(sp)
    80001582:	f822                	sd	s0,48(sp)
    80001584:	f426                	sd	s1,40(sp)
    80001586:	f04a                	sd	s2,32(sp)
    80001588:	ec4e                	sd	s3,24(sp)
    8000158a:	e852                	sd	s4,16(sp)
    8000158c:	e456                	sd	s5,8(sp)
    8000158e:	0080                	addi	s0,sp,64
    80001590:	8aaa                	mv	s5,a0
    80001592:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001594:	6991                	lui	s3,0x4
    80001596:	19fd                	addi	s3,s3,-1
    80001598:	95ce                	add	a1,a1,s3
    8000159a:	79f1                	lui	s3,0xffffc
    8000159c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a0:	08c9f063          	bgeu	s3,a2,80001620 <uvmalloc+0xa6>
    800015a4:	894e                	mv	s2,s3
    mem = kalloc();
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	54e080e7          	jalr	1358(ra) # 80000af4 <kalloc>
    800015ae:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b0:	c51d                	beqz	a0,800015de <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015b2:	6611                	lui	a2,0x4
    800015b4:	4581                	li	a1,0
    800015b6:	fffff097          	auipc	ra,0xfffff
    800015ba:	72a080e7          	jalr	1834(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015be:	4779                	li	a4,30
    800015c0:	86a6                	mv	a3,s1
    800015c2:	6611                	lui	a2,0x4
    800015c4:	85ca                	mv	a1,s2
    800015c6:	8556                	mv	a0,s5
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	bca080e7          	jalr	-1078(ra) # 80001192 <mappages>
    800015d0:	e905                	bnez	a0,80001600 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015d2:	6791                	lui	a5,0x4
    800015d4:	993e                	add	s2,s2,a5
    800015d6:	fd4968e3          	bltu	s2,s4,800015a6 <uvmalloc+0x2c>
  return newsz;
    800015da:	8552                	mv	a0,s4
    800015dc:	a809                	j	800015ee <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015de:	864e                	mv	a2,s3
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8556                	mv	a0,s5
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	f4e080e7          	jalr	-178(ra) # 80001532 <uvmdealloc>
      return 0;
    800015ec:	4501                	li	a0,0
}
    800015ee:	70e2                	ld	ra,56(sp)
    800015f0:	7442                	ld	s0,48(sp)
    800015f2:	74a2                	ld	s1,40(sp)
    800015f4:	7902                	ld	s2,32(sp)
    800015f6:	69e2                	ld	s3,24(sp)
    800015f8:	6a42                	ld	s4,16(sp)
    800015fa:	6aa2                	ld	s5,8(sp)
    800015fc:	6121                	addi	sp,sp,64
    800015fe:	8082                	ret
      kfree(mem);
    80001600:	8526                	mv	a0,s1
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	3f6080e7          	jalr	1014(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000160a:	864e                	mv	a2,s3
    8000160c:	85ca                	mv	a1,s2
    8000160e:	8556                	mv	a0,s5
    80001610:	00000097          	auipc	ra,0x0
    80001614:	f22080e7          	jalr	-222(ra) # 80001532 <uvmdealloc>
      return 0;
    80001618:	4501                	li	a0,0
    8000161a:	bfd1                	j	800015ee <uvmalloc+0x74>
    return oldsz;
    8000161c:	852e                	mv	a0,a1
}
    8000161e:	8082                	ret
  return newsz;
    80001620:	8532                	mv	a0,a2
    80001622:	b7f1                	j	800015ee <uvmalloc+0x74>

0000000080001624 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001624:	7179                	addi	sp,sp,-48
    80001626:	f406                	sd	ra,40(sp)
    80001628:	f022                	sd	s0,32(sp)
    8000162a:	ec26                	sd	s1,24(sp)
    8000162c:	e84a                	sd	s2,16(sp)
    8000162e:	e44e                	sd	s3,8(sp)
    80001630:	e052                	sd	s4,0(sp)
    80001632:	1800                	addi	s0,sp,48
    80001634:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001636:	84aa                	mv	s1,a0
    80001638:	6905                	lui	s2,0x1
    8000163a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000163c:	4985                	li	s3,1
    8000163e:	a821                	j	80001656 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001640:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001642:	053a                	slli	a0,a0,0xe
    80001644:	00000097          	auipc	ra,0x0
    80001648:	fe0080e7          	jalr	-32(ra) # 80001624 <freewalk>
      pagetable[i] = 0;
    8000164c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001650:	04a1                	addi	s1,s1,8
    80001652:	03248163          	beq	s1,s2,80001674 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001656:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001658:	00f57793          	andi	a5,a0,15
    8000165c:	ff3782e3          	beq	a5,s3,80001640 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001660:	8905                	andi	a0,a0,1
    80001662:	d57d                	beqz	a0,80001650 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001664:	0000b517          	auipc	a0,0xb
    80001668:	cf450513          	addi	a0,a0,-780 # 8000c358 <digits+0x318>
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	ed2080e7          	jalr	-302(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001674:	8552                	mv	a0,s4
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	382080e7          	jalr	898(ra) # 800009f8 <kfree>
}
    8000167e:	70a2                	ld	ra,40(sp)
    80001680:	7402                	ld	s0,32(sp)
    80001682:	64e2                	ld	s1,24(sp)
    80001684:	6942                	ld	s2,16(sp)
    80001686:	69a2                	ld	s3,8(sp)
    80001688:	6a02                	ld	s4,0(sp)
    8000168a:	6145                	addi	sp,sp,48
    8000168c:	8082                	ret

000000008000168e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000168e:	1101                	addi	sp,sp,-32
    80001690:	ec06                	sd	ra,24(sp)
    80001692:	e822                	sd	s0,16(sp)
    80001694:	e426                	sd	s1,8(sp)
    80001696:	1000                	addi	s0,sp,32
    80001698:	84aa                	mv	s1,a0
  if(sz > 0)
    8000169a:	e999                	bnez	a1,800016b0 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000169c:	8526                	mv	a0,s1
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	f86080e7          	jalr	-122(ra) # 80001624 <freewalk>
}
    800016a6:	60e2                	ld	ra,24(sp)
    800016a8:	6442                	ld	s0,16(sp)
    800016aa:	64a2                	ld	s1,8(sp)
    800016ac:	6105                	addi	sp,sp,32
    800016ae:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016b0:	6611                	lui	a2,0x4
    800016b2:	167d                	addi	a2,a2,-1
    800016b4:	962e                	add	a2,a2,a1
    800016b6:	4685                	li	a3,1
    800016b8:	8239                	srli	a2,a2,0xe
    800016ba:	4581                	li	a1,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	cfa080e7          	jalr	-774(ra) # 800013b6 <uvmunmap>
    800016c4:	bfe1                	j	8000169c <uvmfree+0xe>

00000000800016c6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016c6:	ca61                	beqz	a2,80001796 <uvmcopy+0xd0>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	0880                	addi	s0,sp,80
    800016de:	8b2a                	mv	s6,a0
    800016e0:	8aae                	mv	s5,a1
    800016e2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016e4:	4981                	li	s3,0
    if((pte = walk(old, i, 0, 0)) == 0)
    800016e6:	4681                	li	a3,0
    800016e8:	4601                	li	a2,0
    800016ea:	85ce                	mv	a1,s3
    800016ec:	855a                	mv	a0,s6
    800016ee:	00000097          	auipc	ra,0x0
    800016f2:	92a080e7          	jalr	-1750(ra) # 80001018 <walk>
    800016f6:	c531                	beqz	a0,80001742 <uvmcopy+0x7c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016f8:	6118                	ld	a4,0(a0)
    800016fa:	00177793          	andi	a5,a4,1
    800016fe:	cbb1                	beqz	a5,80001752 <uvmcopy+0x8c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001700:	00a75593          	srli	a1,a4,0xa
    80001704:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    80001708:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	3e8080e7          	jalr	1000(ra) # 80000af4 <kalloc>
    80001714:	892a                	mv	s2,a0
    80001716:	c939                	beqz	a0,8000176c <uvmcopy+0xa6>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001718:	6611                	lui	a2,0x4
    8000171a:	85de                	mv	a1,s7
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	624080e7          	jalr	1572(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001724:	8726                	mv	a4,s1
    80001726:	86ca                	mv	a3,s2
    80001728:	6611                	lui	a2,0x4
    8000172a:	85ce                	mv	a1,s3
    8000172c:	8556                	mv	a0,s5
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	a64080e7          	jalr	-1436(ra) # 80001192 <mappages>
    80001736:	e515                	bnez	a0,80001762 <uvmcopy+0x9c>
  for(i = 0; i < sz; i += PGSIZE){
    80001738:	6791                	lui	a5,0x4
    8000173a:	99be                	add	s3,s3,a5
    8000173c:	fb49e5e3          	bltu	s3,s4,800016e6 <uvmcopy+0x20>
    80001740:	a081                	j	80001780 <uvmcopy+0xba>
      panic("uvmcopy: pte should exist");
    80001742:	0000b517          	auipc	a0,0xb
    80001746:	c2650513          	addi	a0,a0,-986 # 8000c368 <digits+0x328>
    8000174a:	fffff097          	auipc	ra,0xfffff
    8000174e:	df4080e7          	jalr	-524(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001752:	0000b517          	auipc	a0,0xb
    80001756:	c3650513          	addi	a0,a0,-970 # 8000c388 <digits+0x348>
    8000175a:	fffff097          	auipc	ra,0xfffff
    8000175e:	de4080e7          	jalr	-540(ra) # 8000053e <panic>
      kfree(mem);
    80001762:	854a                	mv	a0,s2
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	294080e7          	jalr	660(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000176c:	4685                	li	a3,1
    8000176e:	00e9d613          	srli	a2,s3,0xe
    80001772:	4581                	li	a1,0
    80001774:	8556                	mv	a0,s5
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	c40080e7          	jalr	-960(ra) # 800013b6 <uvmunmap>
  return -1;
    8000177e:	557d                	li	a0,-1
}
    80001780:	60a6                	ld	ra,72(sp)
    80001782:	6406                	ld	s0,64(sp)
    80001784:	74e2                	ld	s1,56(sp)
    80001786:	7942                	ld	s2,48(sp)
    80001788:	79a2                	ld	s3,40(sp)
    8000178a:	7a02                	ld	s4,32(sp)
    8000178c:	6ae2                	ld	s5,24(sp)
    8000178e:	6b42                	ld	s6,16(sp)
    80001790:	6ba2                	ld	s7,8(sp)
    80001792:	6161                	addi	sp,sp,80
    80001794:	8082                	ret
  return 0;
    80001796:	4501                	li	a0,0
}
    80001798:	8082                	ret

000000008000179a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000179a:	1141                	addi	sp,sp,-16
    8000179c:	e406                	sd	ra,8(sp)
    8000179e:	e022                	sd	s0,0(sp)
    800017a0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0, 0);
    800017a2:	4681                	li	a3,0
    800017a4:	4601                	li	a2,0
    800017a6:	00000097          	auipc	ra,0x0
    800017aa:	872080e7          	jalr	-1934(ra) # 80001018 <walk>
  if(pte == 0)
    800017ae:	c901                	beqz	a0,800017be <uvmclear+0x24>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017b0:	611c                	ld	a5,0(a0)
    800017b2:	9bbd                	andi	a5,a5,-17
    800017b4:	e11c                	sd	a5,0(a0)
}
    800017b6:	60a2                	ld	ra,8(sp)
    800017b8:	6402                	ld	s0,0(sp)
    800017ba:	0141                	addi	sp,sp,16
    800017bc:	8082                	ret
    panic("uvmclear");
    800017be:	0000b517          	auipc	a0,0xb
    800017c2:	bea50513          	addi	a0,a0,-1046 # 8000c3a8 <digits+0x368>
    800017c6:	fffff097          	auipc	ra,0xfffff
    800017ca:	d78080e7          	jalr	-648(ra) # 8000053e <panic>

00000000800017ce <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ce:	c6bd                	beqz	a3,8000183c <copyout+0x6e>
{
    800017d0:	715d                	addi	sp,sp,-80
    800017d2:	e486                	sd	ra,72(sp)
    800017d4:	e0a2                	sd	s0,64(sp)
    800017d6:	fc26                	sd	s1,56(sp)
    800017d8:	f84a                	sd	s2,48(sp)
    800017da:	f44e                	sd	s3,40(sp)
    800017dc:	f052                	sd	s4,32(sp)
    800017de:	ec56                	sd	s5,24(sp)
    800017e0:	e85a                	sd	s6,16(sp)
    800017e2:	e45e                	sd	s7,8(sp)
    800017e4:	e062                	sd	s8,0(sp)
    800017e6:	0880                	addi	s0,sp,80
    800017e8:	8b2a                	mv	s6,a0
    800017ea:	8c2e                	mv	s8,a1
    800017ec:	8a32                	mv	s4,a2
    800017ee:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017f0:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017f2:	6a91                	lui	s5,0x4
    800017f4:	a015                	j	80001818 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017f6:	9562                	add	a0,a0,s8
    800017f8:	0004861b          	sext.w	a2,s1
    800017fc:	85d2                	mv	a1,s4
    800017fe:	41250533          	sub	a0,a0,s2
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	53e080e7          	jalr	1342(ra) # 80000d40 <memmove>

    len -= n;
    8000180a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000180e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001810:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001814:	02098263          	beqz	s3,80001838 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001818:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000181c:	85ca                	mv	a1,s2
    8000181e:	855a                	mv	a0,s6
    80001820:	00000097          	auipc	ra,0x0
    80001824:	92e080e7          	jalr	-1746(ra) # 8000114e <walkaddr>
    if(pa0 == 0)
    80001828:	cd01                	beqz	a0,80001840 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000182a:	418904b3          	sub	s1,s2,s8
    8000182e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001830:	fc99f3e3          	bgeu	s3,s1,800017f6 <copyout+0x28>
    80001834:	84ce                	mv	s1,s3
    80001836:	b7c1                	j	800017f6 <copyout+0x28>
  }
  return 0;
    80001838:	4501                	li	a0,0
    8000183a:	a021                	j	80001842 <copyout+0x74>
    8000183c:	4501                	li	a0,0
}
    8000183e:	8082                	ret
      return -1;
    80001840:	557d                	li	a0,-1
}
    80001842:	60a6                	ld	ra,72(sp)
    80001844:	6406                	ld	s0,64(sp)
    80001846:	74e2                	ld	s1,56(sp)
    80001848:	7942                	ld	s2,48(sp)
    8000184a:	79a2                	ld	s3,40(sp)
    8000184c:	7a02                	ld	s4,32(sp)
    8000184e:	6ae2                	ld	s5,24(sp)
    80001850:	6b42                	ld	s6,16(sp)
    80001852:	6ba2                	ld	s7,8(sp)
    80001854:	6c02                	ld	s8,0(sp)
    80001856:	6161                	addi	sp,sp,80
    80001858:	8082                	ret

000000008000185a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000185a:	c6bd                	beqz	a3,800018c8 <copyin+0x6e>
{
    8000185c:	715d                	addi	sp,sp,-80
    8000185e:	e486                	sd	ra,72(sp)
    80001860:	e0a2                	sd	s0,64(sp)
    80001862:	fc26                	sd	s1,56(sp)
    80001864:	f84a                	sd	s2,48(sp)
    80001866:	f44e                	sd	s3,40(sp)
    80001868:	f052                	sd	s4,32(sp)
    8000186a:	ec56                	sd	s5,24(sp)
    8000186c:	e85a                	sd	s6,16(sp)
    8000186e:	e45e                	sd	s7,8(sp)
    80001870:	e062                	sd	s8,0(sp)
    80001872:	0880                	addi	s0,sp,80
    80001874:	8b2a                	mv	s6,a0
    80001876:	8a2e                	mv	s4,a1
    80001878:	8c32                	mv	s8,a2
    8000187a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000187c:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000187e:	6a91                	lui	s5,0x4
    80001880:	a015                	j	800018a4 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001882:	9562                	add	a0,a0,s8
    80001884:	0004861b          	sext.w	a2,s1
    80001888:	412505b3          	sub	a1,a0,s2
    8000188c:	8552                	mv	a0,s4
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	4b2080e7          	jalr	1202(ra) # 80000d40 <memmove>

    len -= n;
    80001896:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000189a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000189c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018a0:	02098263          	beqz	s3,800018c4 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018a4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018a8:	85ca                	mv	a1,s2
    800018aa:	855a                	mv	a0,s6
    800018ac:	00000097          	auipc	ra,0x0
    800018b0:	8a2080e7          	jalr	-1886(ra) # 8000114e <walkaddr>
    if(pa0 == 0)
    800018b4:	cd01                	beqz	a0,800018cc <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018b6:	418904b3          	sub	s1,s2,s8
    800018ba:	94d6                	add	s1,s1,s5
    if(n > len)
    800018bc:	fc99f3e3          	bgeu	s3,s1,80001882 <copyin+0x28>
    800018c0:	84ce                	mv	s1,s3
    800018c2:	b7c1                	j	80001882 <copyin+0x28>
  }
  return 0;
    800018c4:	4501                	li	a0,0
    800018c6:	a021                	j	800018ce <copyin+0x74>
    800018c8:	4501                	li	a0,0
}
    800018ca:	8082                	ret
      return -1;
    800018cc:	557d                	li	a0,-1
}
    800018ce:	60a6                	ld	ra,72(sp)
    800018d0:	6406                	ld	s0,64(sp)
    800018d2:	74e2                	ld	s1,56(sp)
    800018d4:	7942                	ld	s2,48(sp)
    800018d6:	79a2                	ld	s3,40(sp)
    800018d8:	7a02                	ld	s4,32(sp)
    800018da:	6ae2                	ld	s5,24(sp)
    800018dc:	6b42                	ld	s6,16(sp)
    800018de:	6ba2                	ld	s7,8(sp)
    800018e0:	6c02                	ld	s8,0(sp)
    800018e2:	6161                	addi	sp,sp,80
    800018e4:	8082                	ret

00000000800018e6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018e6:	c6c5                	beqz	a3,8000198e <copyinstr+0xa8>
{
    800018e8:	715d                	addi	sp,sp,-80
    800018ea:	e486                	sd	ra,72(sp)
    800018ec:	e0a2                	sd	s0,64(sp)
    800018ee:	fc26                	sd	s1,56(sp)
    800018f0:	f84a                	sd	s2,48(sp)
    800018f2:	f44e                	sd	s3,40(sp)
    800018f4:	f052                	sd	s4,32(sp)
    800018f6:	ec56                	sd	s5,24(sp)
    800018f8:	e85a                	sd	s6,16(sp)
    800018fa:	e45e                	sd	s7,8(sp)
    800018fc:	0880                	addi	s0,sp,80
    800018fe:	8a2a                	mv	s4,a0
    80001900:	8b2e                	mv	s6,a1
    80001902:	8bb2                	mv	s7,a2
    80001904:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001906:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001908:	6991                	lui	s3,0x4
    8000190a:	a035                	j	80001936 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000190c:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    80001910:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001912:	0017b793          	seqz	a5,a5
    80001916:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000191a:	60a6                	ld	ra,72(sp)
    8000191c:	6406                	ld	s0,64(sp)
    8000191e:	74e2                	ld	s1,56(sp)
    80001920:	7942                	ld	s2,48(sp)
    80001922:	79a2                	ld	s3,40(sp)
    80001924:	7a02                	ld	s4,32(sp)
    80001926:	6ae2                	ld	s5,24(sp)
    80001928:	6b42                	ld	s6,16(sp)
    8000192a:	6ba2                	ld	s7,8(sp)
    8000192c:	6161                	addi	sp,sp,80
    8000192e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001930:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001934:	c8a9                	beqz	s1,80001986 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001936:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000193a:	85ca                	mv	a1,s2
    8000193c:	8552                	mv	a0,s4
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	810080e7          	jalr	-2032(ra) # 8000114e <walkaddr>
    if(pa0 == 0)
    80001946:	c131                	beqz	a0,8000198a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001948:	41790833          	sub	a6,s2,s7
    8000194c:	984e                	add	a6,a6,s3
    if(n > max)
    8000194e:	0104f363          	bgeu	s1,a6,80001954 <copyinstr+0x6e>
    80001952:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001954:	955e                	add	a0,a0,s7
    80001956:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000195a:	fc080be3          	beqz	a6,80001930 <copyinstr+0x4a>
    8000195e:	985a                	add	a6,a6,s6
    80001960:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001962:	41650633          	sub	a2,a0,s6
    80001966:	14fd                	addi	s1,s1,-1
    80001968:	9b26                	add	s6,s6,s1
    8000196a:	00f60733          	add	a4,a2,a5
    8000196e:	00074703          	lbu	a4,0(a4)
    80001972:	df49                	beqz	a4,8000190c <copyinstr+0x26>
        *dst = *p;
    80001974:	00e78023          	sb	a4,0(a5)
      --max;
    80001978:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000197c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000197e:	ff0796e3          	bne	a5,a6,8000196a <copyinstr+0x84>
      dst++;
    80001982:	8b42                	mv	s6,a6
    80001984:	b775                	j	80001930 <copyinstr+0x4a>
    80001986:	4781                	li	a5,0
    80001988:	b769                	j	80001912 <copyinstr+0x2c>
      return -1;
    8000198a:	557d                	li	a0,-1
    8000198c:	b779                	j	8000191a <copyinstr+0x34>
  int got_null = 0;
    8000198e:	4781                	li	a5,0
  if(got_null){
    80001990:	0017b793          	seqz	a5,a5
    80001994:	40f00533          	neg	a0,a5
}
    80001998:	8082                	ret

000000008000199a <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000199a:	7139                	addi	sp,sp,-64
    8000199c:	fc06                	sd	ra,56(sp)
    8000199e:	f822                	sd	s0,48(sp)
    800019a0:	f426                	sd	s1,40(sp)
    800019a2:	f04a                	sd	s2,32(sp)
    800019a4:	ec4e                	sd	s3,24(sp)
    800019a6:	e852                	sd	s4,16(sp)
    800019a8:	e456                	sd	s5,8(sp)
    800019aa:	e05a                	sd	s6,0(sp)
    800019ac:	0080                	addi	s0,sp,64
    800019ae:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b0:	00017497          	auipc	s1,0x17
    800019b4:	d2048493          	addi	s1,s1,-736 # 800186d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019b8:	8b26                	mv	s6,s1
    800019ba:	0000aa97          	auipc	s5,0xa
    800019be:	646a8a93          	addi	s5,s5,1606 # 8000c000 <etext>
    800019c2:	00800937          	lui	s2,0x800
    800019c6:	197d                	addi	s2,s2,-1
    800019c8:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ca:	0001ca17          	auipc	s4,0x1c
    800019ce:	706a0a13          	addi	s4,s4,1798 # 8001e0d0 <tickslock>
    char *pa = kalloc();
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	122080e7          	jalr	290(ra) # 80000af4 <kalloc>
    800019da:	862a                	mv	a2,a0
    if(pa == 0)
    800019dc:	c131                	beqz	a0,80001a20 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019de:	416485b3          	sub	a1,s1,s6
    800019e2:	858d                	srai	a1,a1,0x3
    800019e4:	000ab783          	ld	a5,0(s5)
    800019e8:	02f585b3          	mul	a1,a1,a5
    800019ec:	2585                	addiw	a1,a1,1
    800019ee:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f2:	4719                	li	a4,6
    800019f4:	6691                	lui	a3,0x4
    800019f6:	40b905b3          	sub	a1,s2,a1
    800019fa:	854e                	mv	a0,s3
    800019fc:	00000097          	auipc	ra,0x0
    80001a00:	838080e7          	jalr	-1992(ra) # 80001234 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a04:	16848493          	addi	s1,s1,360
    80001a08:	fd4495e3          	bne	s1,s4,800019d2 <proc_mapstacks+0x38>
  }
}
    80001a0c:	70e2                	ld	ra,56(sp)
    80001a0e:	7442                	ld	s0,48(sp)
    80001a10:	74a2                	ld	s1,40(sp)
    80001a12:	7902                	ld	s2,32(sp)
    80001a14:	69e2                	ld	s3,24(sp)
    80001a16:	6a42                	ld	s4,16(sp)
    80001a18:	6aa2                	ld	s5,8(sp)
    80001a1a:	6b02                	ld	s6,0(sp)
    80001a1c:	6121                	addi	sp,sp,64
    80001a1e:	8082                	ret
      panic("kalloc");
    80001a20:	0000b517          	auipc	a0,0xb
    80001a24:	99850513          	addi	a0,a0,-1640 # 8000c3b8 <digits+0x378>
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	b16080e7          	jalr	-1258(ra) # 8000053e <panic>

0000000080001a30 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001a30:	7139                	addi	sp,sp,-64
    80001a32:	fc06                	sd	ra,56(sp)
    80001a34:	f822                	sd	s0,48(sp)
    80001a36:	f426                	sd	s1,40(sp)
    80001a38:	f04a                	sd	s2,32(sp)
    80001a3a:	ec4e                	sd	s3,24(sp)
    80001a3c:	e852                	sd	s4,16(sp)
    80001a3e:	e456                	sd	s5,8(sp)
    80001a40:	e05a                	sd	s6,0(sp)
    80001a42:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a44:	0000b597          	auipc	a1,0xb
    80001a48:	97c58593          	addi	a1,a1,-1668 # 8000c3c0 <digits+0x380>
    80001a4c:	00017517          	auipc	a0,0x17
    80001a50:	85450513          	addi	a0,a0,-1964 # 800182a0 <pid_lock>
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	100080e7          	jalr	256(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a5c:	0000b597          	auipc	a1,0xb
    80001a60:	96c58593          	addi	a1,a1,-1684 # 8000c3c8 <digits+0x388>
    80001a64:	00017517          	auipc	a0,0x17
    80001a68:	85450513          	addi	a0,a0,-1964 # 800182b8 <wait_lock>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	0e8080e7          	jalr	232(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a74:	00017497          	auipc	s1,0x17
    80001a78:	c5c48493          	addi	s1,s1,-932 # 800186d0 <proc>
      initlock(&p->lock, "proc");
    80001a7c:	0000bb17          	auipc	s6,0xb
    80001a80:	95cb0b13          	addi	s6,s6,-1700 # 8000c3d8 <digits+0x398>
      p->kstack = KSTACK((int) (p - proc));
    80001a84:	8aa6                	mv	s5,s1
    80001a86:	0000aa17          	auipc	s4,0xa
    80001a8a:	57aa0a13          	addi	s4,s4,1402 # 8000c000 <etext>
    80001a8e:	00800937          	lui	s2,0x800
    80001a92:	197d                	addi	s2,s2,-1
    80001a94:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a96:	0001c997          	auipc	s3,0x1c
    80001a9a:	63a98993          	addi	s3,s3,1594 # 8001e0d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a9e:	85da                	mv	a1,s6
    80001aa0:	8526                	mv	a0,s1
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	0b2080e7          	jalr	178(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001aaa:	415487b3          	sub	a5,s1,s5
    80001aae:	878d                	srai	a5,a5,0x3
    80001ab0:	000a3703          	ld	a4,0(s4)
    80001ab4:	02e787b3          	mul	a5,a5,a4
    80001ab8:	2785                	addiw	a5,a5,1
    80001aba:	00f7979b          	slliw	a5,a5,0xf
    80001abe:	40f907b3          	sub	a5,s2,a5
    80001ac2:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ac4:	16848493          	addi	s1,s1,360
    80001ac8:	fd349be3          	bne	s1,s3,80001a9e <procinit+0x6e>
  }
}
    80001acc:	70e2                	ld	ra,56(sp)
    80001ace:	7442                	ld	s0,48(sp)
    80001ad0:	74a2                	ld	s1,40(sp)
    80001ad2:	7902                	ld	s2,32(sp)
    80001ad4:	69e2                	ld	s3,24(sp)
    80001ad6:	6a42                	ld	s4,16(sp)
    80001ad8:	6aa2                	ld	s5,8(sp)
    80001ada:	6b02                	ld	s6,0(sp)
    80001adc:	6121                	addi	sp,sp,64
    80001ade:	8082                	ret

0000000080001ae0 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ae0:	1141                	addi	sp,sp,-16
    80001ae2:	e422                	sd	s0,8(sp)
    80001ae4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ae6:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001ae8:	2501                	sext.w	a0,a0
    80001aea:	6422                	ld	s0,8(sp)
    80001aec:	0141                	addi	sp,sp,16
    80001aee:	8082                	ret

0000000080001af0 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001af0:	1141                	addi	sp,sp,-16
    80001af2:	e422                	sd	s0,8(sp)
    80001af4:	0800                	addi	s0,sp,16
    80001af6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001af8:	2781                	sext.w	a5,a5
    80001afa:	079e                	slli	a5,a5,0x7
  return c;
}
    80001afc:	00016517          	auipc	a0,0x16
    80001b00:	7d450513          	addi	a0,a0,2004 # 800182d0 <cpus>
    80001b04:	953e                	add	a0,a0,a5
    80001b06:	6422                	ld	s0,8(sp)
    80001b08:	0141                	addi	sp,sp,16
    80001b0a:	8082                	ret

0000000080001b0c <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	1000                	addi	s0,sp,32
  push_off();
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	082080e7          	jalr	130(ra) # 80000b98 <push_off>
    80001b1e:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b20:	2781                	sext.w	a5,a5
    80001b22:	079e                	slli	a5,a5,0x7
    80001b24:	00016717          	auipc	a4,0x16
    80001b28:	77c70713          	addi	a4,a4,1916 # 800182a0 <pid_lock>
    80001b2c:	97ba                	add	a5,a5,a4
    80001b2e:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	108080e7          	jalr	264(ra) # 80000c38 <pop_off>
  return p;
}
    80001b38:	8526                	mv	a0,s1
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6105                	addi	sp,sp,32
    80001b42:	8082                	ret

0000000080001b44 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b44:	1141                	addi	sp,sp,-16
    80001b46:	e406                	sd	ra,8(sp)
    80001b48:	e022                	sd	s0,0(sp)
    80001b4a:	0800                	addi	s0,sp,16
  static int first = 1;
  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b4c:	00000097          	auipc	ra,0x0
    80001b50:	fc0080e7          	jalr	-64(ra) # 80001b0c <myproc>
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	144080e7          	jalr	324(ra) # 80000c98 <release>

  if (first) {
    80001b5c:	0000b797          	auipc	a5,0xb
    80001b60:	f247a783          	lw	a5,-220(a5) # 8000ca80 <first.1672>
    80001b64:	eb89                	bnez	a5,80001b76 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV); //12010320;
  }

  usertrapret();
    80001b66:	00001097          	auipc	ra,0x1
    80001b6a:	c5a080e7          	jalr	-934(ra) # 800027c0 <usertrapret>
}
    80001b6e:	60a2                	ld	ra,8(sp)
    80001b70:	6402                	ld	s0,0(sp)
    80001b72:	0141                	addi	sp,sp,16
    80001b74:	8082                	ret
    first = 0;
    80001b76:	0000b797          	auipc	a5,0xb
    80001b7a:	f007a523          	sw	zero,-246(a5) # 8000ca80 <first.1672>
    fsinit(ROOTDEV); //12010320;
    80001b7e:	4505                	li	a0,1
    80001b80:	00002097          	auipc	ra,0x2
    80001b84:	982080e7          	jalr	-1662(ra) # 80003502 <fsinit>
    80001b88:	bff9                	j	80001b66 <forkret+0x22>

0000000080001b8a <allocpid>:
allocpid() {
    80001b8a:	1101                	addi	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	e04a                	sd	s2,0(sp)
    80001b94:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b96:	00016917          	auipc	s2,0x16
    80001b9a:	70a90913          	addi	s2,s2,1802 # 800182a0 <pid_lock>
    80001b9e:	854a                	mv	a0,s2
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	044080e7          	jalr	68(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001ba8:	0000b797          	auipc	a5,0xb
    80001bac:	edc78793          	addi	a5,a5,-292 # 8000ca84 <nextpid>
    80001bb0:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bb2:	0014871b          	addiw	a4,s1,1
    80001bb6:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bb8:	854a                	mv	a0,s2
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	0de080e7          	jalr	222(ra) # 80000c98 <release>
}
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	60e2                	ld	ra,24(sp)
    80001bc6:	6442                	ld	s0,16(sp)
    80001bc8:	64a2                	ld	s1,8(sp)
    80001bca:	6902                	ld	s2,0(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <proc_pagetable>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
    80001bdc:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	89e080e7          	jalr	-1890(ra) # 8000147c <uvmcreate>
    80001be6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001be8:	c121                	beqz	a0,80001c28 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bea:	4729                	li	a4,10
    80001bec:	00006697          	auipc	a3,0x6
    80001bf0:	41468693          	addi	a3,a3,1044 # 80008000 <_trampoline>
    80001bf4:	6611                	lui	a2,0x4
    80001bf6:	008005b7          	lui	a1,0x800
    80001bfa:	15fd                	addi	a1,a1,-1
    80001bfc:	05ba                	slli	a1,a1,0xe
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	594080e7          	jalr	1428(ra) # 80001192 <mappages>
    80001c06:	02054863          	bltz	a0,80001c36 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c0a:	4719                	li	a4,6
    80001c0c:	05893683          	ld	a3,88(s2)
    80001c10:	6611                	lui	a2,0x4
    80001c12:	004005b7          	lui	a1,0x400
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05be                	slli	a1,a1,0xf
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	576080e7          	jalr	1398(ra) # 80001192 <mappages>
    80001c24:	02054163          	bltz	a0,80001c46 <proc_pagetable+0x76>
}
    80001c28:	8526                	mv	a0,s1
    80001c2a:	60e2                	ld	ra,24(sp)
    80001c2c:	6442                	ld	s0,16(sp)
    80001c2e:	64a2                	ld	s1,8(sp)
    80001c30:	6902                	ld	s2,0(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret
    uvmfree(pagetable, 0);
    80001c36:	4581                	li	a1,0
    80001c38:	8526                	mv	a0,s1
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	a54080e7          	jalr	-1452(ra) # 8000168e <uvmfree>
    return 0;
    80001c42:	4481                	li	s1,0
    80001c44:	b7d5                	j	80001c28 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	4605                	li	a2,1
    80001c4a:	008005b7          	lui	a1,0x800
    80001c4e:	15fd                	addi	a1,a1,-1
    80001c50:	05ba                	slli	a1,a1,0xe
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	762080e7          	jalr	1890(ra) # 800013b6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c5c:	4581                	li	a1,0
    80001c5e:	8526                	mv	a0,s1
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	a2e080e7          	jalr	-1490(ra) # 8000168e <uvmfree>
    return 0;
    80001c68:	4481                	li	s1,0
    80001c6a:	bf7d                	j	80001c28 <proc_pagetable+0x58>

0000000080001c6c <proc_freepagetable>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	e04a                	sd	s2,0(sp)
    80001c76:	1000                	addi	s0,sp,32
    80001c78:	84aa                	mv	s1,a0
    80001c7a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c7c:	4681                	li	a3,0
    80001c7e:	4605                	li	a2,1
    80001c80:	008005b7          	lui	a1,0x800
    80001c84:	15fd                	addi	a1,a1,-1
    80001c86:	05ba                	slli	a1,a1,0xe
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	72e080e7          	jalr	1838(ra) # 800013b6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c90:	4681                	li	a3,0
    80001c92:	4605                	li	a2,1
    80001c94:	004005b7          	lui	a1,0x400
    80001c98:	15fd                	addi	a1,a1,-1
    80001c9a:	05be                	slli	a1,a1,0xf
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	718080e7          	jalr	1816(ra) # 800013b6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001ca6:	85ca                	mv	a1,s2
    80001ca8:	8526                	mv	a0,s1
    80001caa:	00000097          	auipc	ra,0x0
    80001cae:	9e4080e7          	jalr	-1564(ra) # 8000168e <uvmfree>
}
    80001cb2:	60e2                	ld	ra,24(sp)
    80001cb4:	6442                	ld	s0,16(sp)
    80001cb6:	64a2                	ld	s1,8(sp)
    80001cb8:	6902                	ld	s2,0(sp)
    80001cba:	6105                	addi	sp,sp,32
    80001cbc:	8082                	ret

0000000080001cbe <freeproc>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	1000                	addi	s0,sp,32
    80001cc8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cca:	6d28                	ld	a0,88(a0)
    80001ccc:	c509                	beqz	a0,80001cd6 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	d2a080e7          	jalr	-726(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001cd6:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cda:	68a8                	ld	a0,80(s1)
    80001cdc:	c511                	beqz	a0,80001ce8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cde:	64ac                	ld	a1,72(s1)
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	f8c080e7          	jalr	-116(ra) # 80001c6c <proc_freepagetable>
  p->pagetable = 0;
    80001ce8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cec:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cf0:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cf4:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cf8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cfc:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d00:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d04:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d08:	0004ac23          	sw	zero,24(s1)
}
    80001d0c:	60e2                	ld	ra,24(sp)
    80001d0e:	6442                	ld	s0,16(sp)
    80001d10:	64a2                	ld	s1,8(sp)
    80001d12:	6105                	addi	sp,sp,32
    80001d14:	8082                	ret

0000000080001d16 <allocproc>:
{
    80001d16:	1101                	addi	sp,sp,-32
    80001d18:	ec06                	sd	ra,24(sp)
    80001d1a:	e822                	sd	s0,16(sp)
    80001d1c:	e426                	sd	s1,8(sp)
    80001d1e:	e04a                	sd	s2,0(sp)
    80001d20:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d22:	00017497          	auipc	s1,0x17
    80001d26:	9ae48493          	addi	s1,s1,-1618 # 800186d0 <proc>
    80001d2a:	0001c917          	auipc	s2,0x1c
    80001d2e:	3a690913          	addi	s2,s2,934 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	eb0080e7          	jalr	-336(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001d3c:	4c9c                	lw	a5,24(s1)
    80001d3e:	cf81                	beqz	a5,80001d56 <allocproc+0x40>
      release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f56080e7          	jalr	-170(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d4a:	16848493          	addi	s1,s1,360
    80001d4e:	ff2492e3          	bne	s1,s2,80001d32 <allocproc+0x1c>
  return 0;
    80001d52:	4481                	li	s1,0
    80001d54:	a889                	j	80001da6 <allocproc+0x90>
  p->pid = allocpid();
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	e34080e7          	jalr	-460(ra) # 80001b8a <allocpid>
    80001d5e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d60:	4785                	li	a5,1
    80001d62:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	d90080e7          	jalr	-624(ra) # 80000af4 <kalloc>
    80001d6c:	892a                	mv	s2,a0
    80001d6e:	eca8                	sd	a0,88(s1)
    80001d70:	c131                	beqz	a0,80001db4 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d72:	8526                	mv	a0,s1
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	e5c080e7          	jalr	-420(ra) # 80001bd0 <proc_pagetable>
    80001d7c:	892a                	mv	s2,a0
    80001d7e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d80:	c531                	beqz	a0,80001dcc <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d82:	07000613          	li	a2,112
    80001d86:	4581                	li	a1,0
    80001d88:	06048513          	addi	a0,s1,96
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	f54080e7          	jalr	-172(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d94:	00000797          	auipc	a5,0x0
    80001d98:	db078793          	addi	a5,a5,-592 # 80001b44 <forkret>
    80001d9c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d9e:	60bc                	ld	a5,64(s1)
    80001da0:	6711                	lui	a4,0x4
    80001da2:	97ba                	add	a5,a5,a4
    80001da4:	f4bc                	sd	a5,104(s1)
}
    80001da6:	8526                	mv	a0,s1
    80001da8:	60e2                	ld	ra,24(sp)
    80001daa:	6442                	ld	s0,16(sp)
    80001dac:	64a2                	ld	s1,8(sp)
    80001dae:	6902                	ld	s2,0(sp)
    80001db0:	6105                	addi	sp,sp,32
    80001db2:	8082                	ret
    freeproc(p);
    80001db4:	8526                	mv	a0,s1
    80001db6:	00000097          	auipc	ra,0x0
    80001dba:	f08080e7          	jalr	-248(ra) # 80001cbe <freeproc>
    release(&p->lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	ed8080e7          	jalr	-296(ra) # 80000c98 <release>
    return 0;
    80001dc8:	84ca                	mv	s1,s2
    80001dca:	bff1                	j	80001da6 <allocproc+0x90>
    freeproc(p);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	ef0080e7          	jalr	-272(ra) # 80001cbe <freeproc>
    release(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	ec0080e7          	jalr	-320(ra) # 80000c98 <release>
    return 0;
    80001de0:	84ca                	mv	s1,s2
    80001de2:	b7d1                	j	80001da6 <allocproc+0x90>

0000000080001de4 <userinit>:
{
    80001de4:	1101                	addi	sp,sp,-32
    80001de6:	ec06                	sd	ra,24(sp)
    80001de8:	e822                	sd	s0,16(sp)
    80001dea:	e426                	sd	s1,8(sp)
    80001dec:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	f28080e7          	jalr	-216(ra) # 80001d16 <allocproc>
    80001df6:	84aa                	mv	s1,a0
  initproc = p;
    80001df8:	0000e797          	auipc	a5,0xe
    80001dfc:	22a7b823          	sd	a0,560(a5) # 80010028 <initproc>
  printf("user proc with id %d create.\n",p->pid);
    80001e00:	590c                	lw	a1,48(a0)
    80001e02:	0000a517          	auipc	a0,0xa
    80001e06:	5de50513          	addi	a0,a0,1502 # 8000c3e0 <digits+0x3a0>
    80001e0a:	ffffe097          	auipc	ra,0xffffe
    80001e0e:	77e080e7          	jalr	1918(ra) # 80000588 <printf>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e12:	03400613          	li	a2,52
    80001e16:	0000b597          	auipc	a1,0xb
    80001e1a:	c7a58593          	addi	a1,a1,-902 # 8000ca90 <initcode>
    80001e1e:	68a8                	ld	a0,80(s1)
    80001e20:	fffff097          	auipc	ra,0xfffff
    80001e24:	68a080e7          	jalr	1674(ra) # 800014aa <uvminit>
  p->sz = PGSIZE;
    80001e28:	6791                	lui	a5,0x4
    80001e2a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e2c:	6cb8                	ld	a4,88(s1)
    80001e2e:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e32:	6cb8                	ld	a4,88(s1)
    80001e34:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e36:	4641                	li	a2,16
    80001e38:	0000a597          	auipc	a1,0xa
    80001e3c:	5c858593          	addi	a1,a1,1480 # 8000c400 <digits+0x3c0>
    80001e40:	15848513          	addi	a0,s1,344
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	fee080e7          	jalr	-18(ra) # 80000e32 <safestrcpy>
  printf("path: %s\n",namei("/"));
    80001e4c:	0000a517          	auipc	a0,0xa
    80001e50:	5c450513          	addi	a0,a0,1476 # 8000c410 <digits+0x3d0>
    80001e54:	00002097          	auipc	ra,0x2
    80001e58:	0ee080e7          	jalr	238(ra) # 80003f42 <namei>
    80001e5c:	85aa                	mv	a1,a0
    80001e5e:	0000a517          	auipc	a0,0xa
    80001e62:	5ba50513          	addi	a0,a0,1466 # 8000c418 <digits+0x3d8>
    80001e66:	ffffe097          	auipc	ra,0xffffe
    80001e6a:	722080e7          	jalr	1826(ra) # 80000588 <printf>
  p->cwd = namei("/");
    80001e6e:	0000a517          	auipc	a0,0xa
    80001e72:	5a250513          	addi	a0,a0,1442 # 8000c410 <digits+0x3d0>
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	0cc080e7          	jalr	204(ra) # 80003f42 <namei>
    80001e7e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e82:	478d                	li	a5,3
    80001e84:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	e10080e7          	jalr	-496(ra) # 80000c98 <release>
}
    80001e90:	60e2                	ld	ra,24(sp)
    80001e92:	6442                	ld	s0,16(sp)
    80001e94:	64a2                	ld	s1,8(sp)
    80001e96:	6105                	addi	sp,sp,32
    80001e98:	8082                	ret

0000000080001e9a <growproc>:
{
    80001e9a:	1101                	addi	sp,sp,-32
    80001e9c:	ec06                	sd	ra,24(sp)
    80001e9e:	e822                	sd	s0,16(sp)
    80001ea0:	e426                	sd	s1,8(sp)
    80001ea2:	e04a                	sd	s2,0(sp)
    80001ea4:	1000                	addi	s0,sp,32
    80001ea6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ea8:	00000097          	auipc	ra,0x0
    80001eac:	c64080e7          	jalr	-924(ra) # 80001b0c <myproc>
    80001eb0:	892a                	mv	s2,a0
  sz = p->sz;
    80001eb2:	652c                	ld	a1,72(a0)
    80001eb4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001eb8:	00904f63          	bgtz	s1,80001ed6 <growproc+0x3c>
  } else if(n < 0){
    80001ebc:	0204cc63          	bltz	s1,80001ef4 <growproc+0x5a>
  p->sz = sz;
    80001ec0:	1602                	slli	a2,a2,0x20
    80001ec2:	9201                	srli	a2,a2,0x20
    80001ec4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ec8:	4501                	li	a0,0
}
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6902                	ld	s2,0(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ed6:	9e25                	addw	a2,a2,s1
    80001ed8:	1602                	slli	a2,a2,0x20
    80001eda:	9201                	srli	a2,a2,0x20
    80001edc:	1582                	slli	a1,a1,0x20
    80001ede:	9181                	srli	a1,a1,0x20
    80001ee0:	6928                	ld	a0,80(a0)
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	698080e7          	jalr	1688(ra) # 8000157a <uvmalloc>
    80001eea:	0005061b          	sext.w	a2,a0
    80001eee:	fa69                	bnez	a2,80001ec0 <growproc+0x26>
      return -1;
    80001ef0:	557d                	li	a0,-1
    80001ef2:	bfe1                	j	80001eca <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ef4:	9e25                	addw	a2,a2,s1
    80001ef6:	1602                	slli	a2,a2,0x20
    80001ef8:	9201                	srli	a2,a2,0x20
    80001efa:	1582                	slli	a1,a1,0x20
    80001efc:	9181                	srli	a1,a1,0x20
    80001efe:	6928                	ld	a0,80(a0)
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	632080e7          	jalr	1586(ra) # 80001532 <uvmdealloc>
    80001f08:	0005061b          	sext.w	a2,a0
    80001f0c:	bf55                	j	80001ec0 <growproc+0x26>

0000000080001f0e <fork>:
{
    80001f0e:	7179                	addi	sp,sp,-48
    80001f10:	f406                	sd	ra,40(sp)
    80001f12:	f022                	sd	s0,32(sp)
    80001f14:	ec26                	sd	s1,24(sp)
    80001f16:	e84a                	sd	s2,16(sp)
    80001f18:	e44e                	sd	s3,8(sp)
    80001f1a:	e052                	sd	s4,0(sp)
    80001f1c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	bee080e7          	jalr	-1042(ra) # 80001b0c <myproc>
    80001f26:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	dee080e7          	jalr	-530(ra) # 80001d16 <allocproc>
    80001f30:	10050b63          	beqz	a0,80002046 <fork+0x138>
    80001f34:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f36:	04893603          	ld	a2,72(s2)
    80001f3a:	692c                	ld	a1,80(a0)
    80001f3c:	05093503          	ld	a0,80(s2)
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	786080e7          	jalr	1926(ra) # 800016c6 <uvmcopy>
    80001f48:	04054663          	bltz	a0,80001f94 <fork+0x86>
  np->sz = p->sz;
    80001f4c:	04893783          	ld	a5,72(s2)
    80001f50:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f54:	05893683          	ld	a3,88(s2)
    80001f58:	87b6                	mv	a5,a3
    80001f5a:	0589b703          	ld	a4,88(s3)
    80001f5e:	12068693          	addi	a3,a3,288
    80001f62:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001f66:	6788                	ld	a0,8(a5)
    80001f68:	6b8c                	ld	a1,16(a5)
    80001f6a:	6f90                	ld	a2,24(a5)
    80001f6c:	01073023          	sd	a6,0(a4)
    80001f70:	e708                	sd	a0,8(a4)
    80001f72:	eb0c                	sd	a1,16(a4)
    80001f74:	ef10                	sd	a2,24(a4)
    80001f76:	02078793          	addi	a5,a5,32
    80001f7a:	02070713          	addi	a4,a4,32
    80001f7e:	fed792e3          	bne	a5,a3,80001f62 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f82:	0589b783          	ld	a5,88(s3)
    80001f86:	0607b823          	sd	zero,112(a5)
    80001f8a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f8e:	15000a13          	li	s4,336
    80001f92:	a03d                	j	80001fc0 <fork+0xb2>
    freeproc(np);
    80001f94:	854e                	mv	a0,s3
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	d28080e7          	jalr	-728(ra) # 80001cbe <freeproc>
    release(&np->lock);
    80001f9e:	854e                	mv	a0,s3
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	cf8080e7          	jalr	-776(ra) # 80000c98 <release>
    return -1;
    80001fa8:	5a7d                	li	s4,-1
    80001faa:	a069                	j	80002034 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fac:	00002097          	auipc	ra,0x2
    80001fb0:	62c080e7          	jalr	1580(ra) # 800045d8 <filedup>
    80001fb4:	009987b3          	add	a5,s3,s1
    80001fb8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fba:	04a1                	addi	s1,s1,8
    80001fbc:	01448763          	beq	s1,s4,80001fca <fork+0xbc>
    if(p->ofile[i])
    80001fc0:	009907b3          	add	a5,s2,s1
    80001fc4:	6388                	ld	a0,0(a5)
    80001fc6:	f17d                	bnez	a0,80001fac <fork+0x9e>
    80001fc8:	bfcd                	j	80001fba <fork+0xac>
  np->cwd = idup(p->cwd);
    80001fca:	15093503          	ld	a0,336(s2)
    80001fce:	00001097          	auipc	ra,0x1
    80001fd2:	780080e7          	jalr	1920(ra) # 8000374e <idup>
    80001fd6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fda:	4641                	li	a2,16
    80001fdc:	15890593          	addi	a1,s2,344
    80001fe0:	15898513          	addi	a0,s3,344
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	e4e080e7          	jalr	-434(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001fec:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ff0:	854e                	mv	a0,s3
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ffa:	00016497          	auipc	s1,0x16
    80001ffe:	2be48493          	addi	s1,s1,702 # 800182b8 <wait_lock>
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	be0080e7          	jalr	-1056(ra) # 80000be4 <acquire>
  np->parent = p;
    8000200c:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002010:	8526                	mv	a0,s1
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	c86080e7          	jalr	-890(ra) # 80000c98 <release>
  acquire(&np->lock);
    8000201a:	854e                	mv	a0,s3
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	bc8080e7          	jalr	-1080(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002024:	478d                	li	a5,3
    80002026:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000202a:	854e                	mv	a0,s3
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c6c080e7          	jalr	-916(ra) # 80000c98 <release>
}
    80002034:	8552                	mv	a0,s4
    80002036:	70a2                	ld	ra,40(sp)
    80002038:	7402                	ld	s0,32(sp)
    8000203a:	64e2                	ld	s1,24(sp)
    8000203c:	6942                	ld	s2,16(sp)
    8000203e:	69a2                	ld	s3,8(sp)
    80002040:	6a02                	ld	s4,0(sp)
    80002042:	6145                	addi	sp,sp,48
    80002044:	8082                	ret
    return -1;
    80002046:	5a7d                	li	s4,-1
    80002048:	b7f5                	j	80002034 <fork+0x126>

000000008000204a <scheduler>:
{
    8000204a:	7139                	addi	sp,sp,-64
    8000204c:	fc06                	sd	ra,56(sp)
    8000204e:	f822                	sd	s0,48(sp)
    80002050:	f426                	sd	s1,40(sp)
    80002052:	f04a                	sd	s2,32(sp)
    80002054:	ec4e                	sd	s3,24(sp)
    80002056:	e852                	sd	s4,16(sp)
    80002058:	e456                	sd	s5,8(sp)
    8000205a:	e05a                	sd	s6,0(sp)
    8000205c:	0080                	addi	s0,sp,64
    8000205e:	8792                	mv	a5,tp
  int id = r_tp();
    80002060:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002062:	00779a93          	slli	s5,a5,0x7
    80002066:	00016717          	auipc	a4,0x16
    8000206a:	23a70713          	addi	a4,a4,570 # 800182a0 <pid_lock>
    8000206e:	9756                	add	a4,a4,s5
    80002070:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002074:	00016717          	auipc	a4,0x16
    80002078:	26470713          	addi	a4,a4,612 # 800182d8 <cpus+0x8>
    8000207c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    8000207e:	498d                	li	s3,3
        p->state = RUNNING;
    80002080:	4b11                	li	s6,4
        c->proc = p;
    80002082:	079e                	slli	a5,a5,0x7
    80002084:	00016a17          	auipc	s4,0x16
    80002088:	21ca0a13          	addi	s4,s4,540 # 800182a0 <pid_lock>
    8000208c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000208e:	0001c917          	auipc	s2,0x1c
    80002092:	04290913          	addi	s2,s2,66 # 8001e0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002096:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000209e:	10079073          	csrw	sstatus,a5
    800020a2:	00016497          	auipc	s1,0x16
    800020a6:	62e48493          	addi	s1,s1,1582 # 800186d0 <proc>
    800020aa:	a03d                	j	800020d8 <scheduler+0x8e>
        p->state = RUNNING;
    800020ac:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020b0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020b4:	06048593          	addi	a1,s1,96
    800020b8:	8556                	mv	a0,s5
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	640080e7          	jalr	1600(ra) # 800026fa <swtch>
	c->proc = 0;
    800020c2:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bd0080e7          	jalr	-1072(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020d0:	16848493          	addi	s1,s1,360
    800020d4:	fd2481e3          	beq	s1,s2,80002096 <scheduler+0x4c>
      acquire(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	b0a080e7          	jalr	-1270(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    800020e2:	4c9c                	lw	a5,24(s1)
    800020e4:	ff3791e3          	bne	a5,s3,800020c6 <scheduler+0x7c>
    800020e8:	b7d1                	j	800020ac <scheduler+0x62>

00000000800020ea <sched>:
{
    800020ea:	7179                	addi	sp,sp,-48
    800020ec:	f406                	sd	ra,40(sp)
    800020ee:	f022                	sd	s0,32(sp)
    800020f0:	ec26                	sd	s1,24(sp)
    800020f2:	e84a                	sd	s2,16(sp)
    800020f4:	e44e                	sd	s3,8(sp)
    800020f6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	a14080e7          	jalr	-1516(ra) # 80001b0c <myproc>
    80002100:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	a68080e7          	jalr	-1432(ra) # 80000b6a <holding>
    8000210a:	c93d                	beqz	a0,80002180 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000210c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000210e:	2781                	sext.w	a5,a5
    80002110:	079e                	slli	a5,a5,0x7
    80002112:	00016717          	auipc	a4,0x16
    80002116:	18e70713          	addi	a4,a4,398 # 800182a0 <pid_lock>
    8000211a:	97ba                	add	a5,a5,a4
    8000211c:	0a87a703          	lw	a4,168(a5)
    80002120:	4785                	li	a5,1
    80002122:	06f71763          	bne	a4,a5,80002190 <sched+0xa6>
  if(p->state == RUNNING)
    80002126:	4c98                	lw	a4,24(s1)
    80002128:	4791                	li	a5,4
    8000212a:	06f70b63          	beq	a4,a5,800021a0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000212e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002132:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002134:	efb5                	bnez	a5,800021b0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002136:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002138:	00016917          	auipc	s2,0x16
    8000213c:	16890913          	addi	s2,s2,360 # 800182a0 <pid_lock>
    80002140:	2781                	sext.w	a5,a5
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	97ca                	add	a5,a5,s2
    80002146:	0ac7a983          	lw	s3,172(a5)
    8000214a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	00016597          	auipc	a1,0x16
    80002154:	18858593          	addi	a1,a1,392 # 800182d8 <cpus+0x8>
    80002158:	95be                	add	a1,a1,a5
    8000215a:	06048513          	addi	a0,s1,96
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	59c080e7          	jalr	1436(ra) # 800026fa <swtch>
    80002166:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002168:	2781                	sext.w	a5,a5
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	97ca                	add	a5,a5,s2
    8000216e:	0b37a623          	sw	s3,172(a5)
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6145                	addi	sp,sp,48
    8000217e:	8082                	ret
    panic("sched p->lock");
    80002180:	0000a517          	auipc	a0,0xa
    80002184:	2a850513          	addi	a0,a0,680 # 8000c428 <digits+0x3e8>
    80002188:	ffffe097          	auipc	ra,0xffffe
    8000218c:	3b6080e7          	jalr	950(ra) # 8000053e <panic>
    panic("sched locks");
    80002190:	0000a517          	auipc	a0,0xa
    80002194:	2a850513          	addi	a0,a0,680 # 8000c438 <digits+0x3f8>
    80002198:	ffffe097          	auipc	ra,0xffffe
    8000219c:	3a6080e7          	jalr	934(ra) # 8000053e <panic>
    panic("sched running");
    800021a0:	0000a517          	auipc	a0,0xa
    800021a4:	2a850513          	addi	a0,a0,680 # 8000c448 <digits+0x408>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	396080e7          	jalr	918(ra) # 8000053e <panic>
    panic("sched interruptible");
    800021b0:	0000a517          	auipc	a0,0xa
    800021b4:	2a850513          	addi	a0,a0,680 # 8000c458 <digits+0x418>
    800021b8:	ffffe097          	auipc	ra,0xffffe
    800021bc:	386080e7          	jalr	902(ra) # 8000053e <panic>

00000000800021c0 <yield>:
{
    800021c0:	1101                	addi	sp,sp,-32
    800021c2:	ec06                	sd	ra,24(sp)
    800021c4:	e822                	sd	s0,16(sp)
    800021c6:	e426                	sd	s1,8(sp)
    800021c8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	942080e7          	jalr	-1726(ra) # 80001b0c <myproc>
    800021d2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	a10080e7          	jalr	-1520(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800021dc:	478d                	li	a5,3
    800021de:	cc9c                	sw	a5,24(s1)
  sched();
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	f0a080e7          	jalr	-246(ra) # 800020ea <sched>
  release(&p->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	aae080e7          	jalr	-1362(ra) # 80000c98 <release>
}
    800021f2:	60e2                	ld	ra,24(sp)
    800021f4:	6442                	ld	s0,16(sp)
    800021f6:	64a2                	ld	s1,8(sp)
    800021f8:	6105                	addi	sp,sp,32
    800021fa:	8082                	ret

00000000800021fc <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021fc:	7179                	addi	sp,sp,-48
    800021fe:	f406                	sd	ra,40(sp)
    80002200:	f022                	sd	s0,32(sp)
    80002202:	ec26                	sd	s1,24(sp)
    80002204:	e84a                	sd	s2,16(sp)
    80002206:	e44e                	sd	s3,8(sp)
    80002208:	1800                	addi	s0,sp,48
    8000220a:	89aa                	mv	s3,a0
    8000220c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	8fe080e7          	jalr	-1794(ra) # 80001b0c <myproc>
    80002216:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	9cc080e7          	jalr	-1588(ra) # 80000be4 <acquire>
  release(lk);
    80002220:	854a                	mv	a0,s2
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000222a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000222e:	4789                	li	a5,2
    80002230:	cc9c                	sw	a5,24(s1)

  sched();
    80002232:	00000097          	auipc	ra,0x0
    80002236:	eb8080e7          	jalr	-328(ra) # 800020ea <sched>

  // Tidy up.
  p->chan = 0;
    8000223a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
  acquire(lk);
    80002248:	854a                	mv	a0,s2
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	99a080e7          	jalr	-1638(ra) # 80000be4 <acquire>
}
    80002252:	70a2                	ld	ra,40(sp)
    80002254:	7402                	ld	s0,32(sp)
    80002256:	64e2                	ld	s1,24(sp)
    80002258:	6942                	ld	s2,16(sp)
    8000225a:	69a2                	ld	s3,8(sp)
    8000225c:	6145                	addi	sp,sp,48
    8000225e:	8082                	ret

0000000080002260 <wait>:
{
    80002260:	715d                	addi	sp,sp,-80
    80002262:	e486                	sd	ra,72(sp)
    80002264:	e0a2                	sd	s0,64(sp)
    80002266:	fc26                	sd	s1,56(sp)
    80002268:	f84a                	sd	s2,48(sp)
    8000226a:	f44e                	sd	s3,40(sp)
    8000226c:	f052                	sd	s4,32(sp)
    8000226e:	ec56                	sd	s5,24(sp)
    80002270:	e85a                	sd	s6,16(sp)
    80002272:	e45e                	sd	s7,8(sp)
    80002274:	e062                	sd	s8,0(sp)
    80002276:	0880                	addi	s0,sp,80
    80002278:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	892080e7          	jalr	-1902(ra) # 80001b0c <myproc>
    80002282:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002284:	00016517          	auipc	a0,0x16
    80002288:	03450513          	addi	a0,a0,52 # 800182b8 <wait_lock>
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	958080e7          	jalr	-1704(ra) # 80000be4 <acquire>
    havekids = 0;
    80002294:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002296:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002298:	0001c997          	auipc	s3,0x1c
    8000229c:	e3898993          	addi	s3,s3,-456 # 8001e0d0 <tickslock>
        havekids = 1;
    800022a0:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022a2:	00016c17          	auipc	s8,0x16
    800022a6:	016c0c13          	addi	s8,s8,22 # 800182b8 <wait_lock>
    havekids = 0;
    800022aa:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022ac:	00016497          	auipc	s1,0x16
    800022b0:	42448493          	addi	s1,s1,1060 # 800186d0 <proc>
    800022b4:	a0bd                	j	80002322 <wait+0xc2>
          pid = np->pid;
    800022b6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ba:	000b0e63          	beqz	s6,800022d6 <wait+0x76>
    800022be:	4691                	li	a3,4
    800022c0:	02c48613          	addi	a2,s1,44
    800022c4:	85da                	mv	a1,s6
    800022c6:	05093503          	ld	a0,80(s2)
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	504080e7          	jalr	1284(ra) # 800017ce <copyout>
    800022d2:	02054563          	bltz	a0,800022fc <wait+0x9c>
          freeproc(np);
    800022d6:	8526                	mv	a0,s1
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	9e6080e7          	jalr	-1562(ra) # 80001cbe <freeproc>
          release(&np->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9b6080e7          	jalr	-1610(ra) # 80000c98 <release>
          release(&wait_lock);
    800022ea:	00016517          	auipc	a0,0x16
    800022ee:	fce50513          	addi	a0,a0,-50 # 800182b8 <wait_lock>
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9a6080e7          	jalr	-1626(ra) # 80000c98 <release>
          return pid;
    800022fa:	a09d                	j	80002360 <wait+0x100>
            release(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>
            release(&wait_lock);
    80002306:	00016517          	auipc	a0,0x16
    8000230a:	fb250513          	addi	a0,a0,-78 # 800182b8 <wait_lock>
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	98a080e7          	jalr	-1654(ra) # 80000c98 <release>
            return -1;
    80002316:	59fd                	li	s3,-1
    80002318:	a0a1                	j	80002360 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000231a:	16848493          	addi	s1,s1,360
    8000231e:	03348463          	beq	s1,s3,80002346 <wait+0xe6>
      if(np->parent == p){
    80002322:	7c9c                	ld	a5,56(s1)
    80002324:	ff279be3          	bne	a5,s2,8000231a <wait+0xba>
        acquire(&np->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ba080e7          	jalr	-1862(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002332:	4c9c                	lw	a5,24(s1)
    80002334:	f94781e3          	beq	a5,s4,800022b6 <wait+0x56>
        release(&np->lock);
    80002338:	8526                	mv	a0,s1
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	95e080e7          	jalr	-1698(ra) # 80000c98 <release>
        havekids = 1;
    80002342:	8756                	mv	a4,s5
    80002344:	bfd9                	j	8000231a <wait+0xba>
    if(!havekids || p->killed){
    80002346:	c701                	beqz	a4,8000234e <wait+0xee>
    80002348:	02892783          	lw	a5,40(s2)
    8000234c:	c79d                	beqz	a5,8000237a <wait+0x11a>
      release(&wait_lock);
    8000234e:	00016517          	auipc	a0,0x16
    80002352:	f6a50513          	addi	a0,a0,-150 # 800182b8 <wait_lock>
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	942080e7          	jalr	-1726(ra) # 80000c98 <release>
      return -1;
    8000235e:	59fd                	li	s3,-1
}
    80002360:	854e                	mv	a0,s3
    80002362:	60a6                	ld	ra,72(sp)
    80002364:	6406                	ld	s0,64(sp)
    80002366:	74e2                	ld	s1,56(sp)
    80002368:	7942                	ld	s2,48(sp)
    8000236a:	79a2                	ld	s3,40(sp)
    8000236c:	7a02                	ld	s4,32(sp)
    8000236e:	6ae2                	ld	s5,24(sp)
    80002370:	6b42                	ld	s6,16(sp)
    80002372:	6ba2                	ld	s7,8(sp)
    80002374:	6c02                	ld	s8,0(sp)
    80002376:	6161                	addi	sp,sp,80
    80002378:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000237a:	85e2                	mv	a1,s8
    8000237c:	854a                	mv	a0,s2
    8000237e:	00000097          	auipc	ra,0x0
    80002382:	e7e080e7          	jalr	-386(ra) # 800021fc <sleep>
    havekids = 0;
    80002386:	b715                	j	800022aa <wait+0x4a>

0000000080002388 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002388:	7139                	addi	sp,sp,-64
    8000238a:	fc06                	sd	ra,56(sp)
    8000238c:	f822                	sd	s0,48(sp)
    8000238e:	f426                	sd	s1,40(sp)
    80002390:	f04a                	sd	s2,32(sp)
    80002392:	ec4e                	sd	s3,24(sp)
    80002394:	e852                	sd	s4,16(sp)
    80002396:	e456                	sd	s5,8(sp)
    80002398:	0080                	addi	s0,sp,64
    8000239a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	00016497          	auipc	s1,0x16
    800023a0:	33448493          	addi	s1,s1,820 # 800186d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023a4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800023a6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800023a8:	0001c917          	auipc	s2,0x1c
    800023ac:	d2890913          	addi	s2,s2,-728 # 8001e0d0 <tickslock>
    800023b0:	a821                	j	800023c8 <wakeup+0x40>
        p->state = RUNNABLE;
    800023b2:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8e0080e7          	jalr	-1824(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c0:	16848493          	addi	s1,s1,360
    800023c4:	03248463          	beq	s1,s2,800023ec <wakeup+0x64>
    if(p != myproc()){
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	744080e7          	jalr	1860(ra) # 80001b0c <myproc>
    800023d0:	fea488e3          	beq	s1,a0,800023c0 <wakeup+0x38>
      acquire(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	80e080e7          	jalr	-2034(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4c9c                	lw	a5,24(s1)
    800023e0:	fd379be3          	bne	a5,s3,800023b6 <wakeup+0x2e>
    800023e4:	709c                	ld	a5,32(s1)
    800023e6:	fd4798e3          	bne	a5,s4,800023b6 <wakeup+0x2e>
    800023ea:	b7e1                	j	800023b2 <wakeup+0x2a>
    }
  }
}
    800023ec:	70e2                	ld	ra,56(sp)
    800023ee:	7442                	ld	s0,48(sp)
    800023f0:	74a2                	ld	s1,40(sp)
    800023f2:	7902                	ld	s2,32(sp)
    800023f4:	69e2                	ld	s3,24(sp)
    800023f6:	6a42                	ld	s4,16(sp)
    800023f8:	6aa2                	ld	s5,8(sp)
    800023fa:	6121                	addi	sp,sp,64
    800023fc:	8082                	ret

00000000800023fe <reparent>:
{
    800023fe:	7179                	addi	sp,sp,-48
    80002400:	f406                	sd	ra,40(sp)
    80002402:	f022                	sd	s0,32(sp)
    80002404:	ec26                	sd	s1,24(sp)
    80002406:	e84a                	sd	s2,16(sp)
    80002408:	e44e                	sd	s3,8(sp)
    8000240a:	e052                	sd	s4,0(sp)
    8000240c:	1800                	addi	s0,sp,48
    8000240e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002410:	00016497          	auipc	s1,0x16
    80002414:	2c048493          	addi	s1,s1,704 # 800186d0 <proc>
      pp->parent = initproc;
    80002418:	0000ea17          	auipc	s4,0xe
    8000241c:	c10a0a13          	addi	s4,s4,-1008 # 80010028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002420:	0001c997          	auipc	s3,0x1c
    80002424:	cb098993          	addi	s3,s3,-848 # 8001e0d0 <tickslock>
    80002428:	a029                	j	80002432 <reparent+0x34>
    8000242a:	16848493          	addi	s1,s1,360
    8000242e:	01348d63          	beq	s1,s3,80002448 <reparent+0x4a>
    if(pp->parent == p){
    80002432:	7c9c                	ld	a5,56(s1)
    80002434:	ff279be3          	bne	a5,s2,8000242a <reparent+0x2c>
      pp->parent = initproc;
    80002438:	000a3503          	ld	a0,0(s4)
    8000243c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	f4a080e7          	jalr	-182(ra) # 80002388 <wakeup>
    80002446:	b7d5                	j	8000242a <reparent+0x2c>
}
    80002448:	70a2                	ld	ra,40(sp)
    8000244a:	7402                	ld	s0,32(sp)
    8000244c:	64e2                	ld	s1,24(sp)
    8000244e:	6942                	ld	s2,16(sp)
    80002450:	69a2                	ld	s3,8(sp)
    80002452:	6a02                	ld	s4,0(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret

0000000080002458 <exit>:
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	e052                	sd	s4,0(sp)
    80002466:	1800                	addi	s0,sp,48
    80002468:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	6a2080e7          	jalr	1698(ra) # 80001b0c <myproc>
    80002472:	89aa                	mv	s3,a0
  if(p == initproc)
    80002474:	0000e797          	auipc	a5,0xe
    80002478:	bb47b783          	ld	a5,-1100(a5) # 80010028 <initproc>
    8000247c:	0d050493          	addi	s1,a0,208
    80002480:	15050913          	addi	s2,a0,336
    80002484:	02a79363          	bne	a5,a0,800024aa <exit+0x52>
    panic("init exiting");
    80002488:	0000a517          	auipc	a0,0xa
    8000248c:	fe850513          	addi	a0,a0,-24 # 8000c470 <digits+0x430>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0ae080e7          	jalr	174(ra) # 8000053e <panic>
      fileclose(f);
    80002498:	00002097          	auipc	ra,0x2
    8000249c:	192080e7          	jalr	402(ra) # 8000462a <fileclose>
      p->ofile[fd] = 0;
    800024a0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024a4:	04a1                	addi	s1,s1,8
    800024a6:	01248563          	beq	s1,s2,800024b0 <exit+0x58>
    if(p->ofile[fd]){
    800024aa:	6088                	ld	a0,0(s1)
    800024ac:	f575                	bnez	a0,80002498 <exit+0x40>
    800024ae:	bfdd                	j	800024a4 <exit+0x4c>
  begin_op();
    800024b0:	00002097          	auipc	ra,0x2
    800024b4:	cae080e7          	jalr	-850(ra) # 8000415e <begin_op>
  iput(p->cwd);
    800024b8:	1509b503          	ld	a0,336(s3)
    800024bc:	00001097          	auipc	ra,0x1
    800024c0:	48a080e7          	jalr	1162(ra) # 80003946 <iput>
  end_op();
    800024c4:	00002097          	auipc	ra,0x2
    800024c8:	d1a080e7          	jalr	-742(ra) # 800041de <end_op>
  p->cwd = 0;
    800024cc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800024d0:	00016497          	auipc	s1,0x16
    800024d4:	de848493          	addi	s1,s1,-536 # 800182b8 <wait_lock>
    800024d8:	8526                	mv	a0,s1
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  reparent(p);
    800024e2:	854e                	mv	a0,s3
    800024e4:	00000097          	auipc	ra,0x0
    800024e8:	f1a080e7          	jalr	-230(ra) # 800023fe <reparent>
  wakeup(p->parent);
    800024ec:	0389b503          	ld	a0,56(s3)
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	e98080e7          	jalr	-360(ra) # 80002388 <wakeup>
  acquire(&p->lock);
    800024f8:	854e                	mv	a0,s3
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6ea080e7          	jalr	1770(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002502:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002506:	4795                	li	a5,5
    80002508:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	ffffe097          	auipc	ra,0xffffe
    80002512:	78a080e7          	jalr	1930(ra) # 80000c98 <release>
  sched();
    80002516:	00000097          	auipc	ra,0x0
    8000251a:	bd4080e7          	jalr	-1068(ra) # 800020ea <sched>
  panic("zombie exit");
    8000251e:	0000a517          	auipc	a0,0xa
    80002522:	f6250513          	addi	a0,a0,-158 # 8000c480 <digits+0x440>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	018080e7          	jalr	24(ra) # 8000053e <panic>

000000008000252e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000252e:	7179                	addi	sp,sp,-48
    80002530:	f406                	sd	ra,40(sp)
    80002532:	f022                	sd	s0,32(sp)
    80002534:	ec26                	sd	s1,24(sp)
    80002536:	e84a                	sd	s2,16(sp)
    80002538:	e44e                	sd	s3,8(sp)
    8000253a:	1800                	addi	s0,sp,48
    8000253c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000253e:	00016497          	auipc	s1,0x16
    80002542:	19248493          	addi	s1,s1,402 # 800186d0 <proc>
    80002546:	0001c997          	auipc	s3,0x1c
    8000254a:	b8a98993          	addi	s3,s3,-1142 # 8001e0d0 <tickslock>
    acquire(&p->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002558:	589c                	lw	a5,48(s1)
    8000255a:	01278d63          	beq	a5,s2,80002574 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	738080e7          	jalr	1848(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002568:	16848493          	addi	s1,s1,360
    8000256c:	ff3491e3          	bne	s1,s3,8000254e <kill+0x20>
  }
  return -1;
    80002570:	557d                	li	a0,-1
    80002572:	a829                	j	8000258c <kill+0x5e>
      p->killed = 1;
    80002574:	4785                	li	a5,1
    80002576:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002578:	4c98                	lw	a4,24(s1)
    8000257a:	4789                	li	a5,2
    8000257c:	00f70f63          	beq	a4,a5,8000259a <kill+0x6c>
      release(&p->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
      return 0;
    8000258a:	4501                	li	a0,0
}
    8000258c:	70a2                	ld	ra,40(sp)
    8000258e:	7402                	ld	s0,32(sp)
    80002590:	64e2                	ld	s1,24(sp)
    80002592:	6942                	ld	s2,16(sp)
    80002594:	69a2                	ld	s3,8(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
        p->state = RUNNABLE;
    8000259a:	478d                	li	a5,3
    8000259c:	cc9c                	sw	a5,24(s1)
    8000259e:	b7cd                	j	80002580 <kill+0x52>

00000000800025a0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025a0:	7179                	addi	sp,sp,-48
    800025a2:	f406                	sd	ra,40(sp)
    800025a4:	f022                	sd	s0,32(sp)
    800025a6:	ec26                	sd	s1,24(sp)
    800025a8:	e84a                	sd	s2,16(sp)
    800025aa:	e44e                	sd	s3,8(sp)
    800025ac:	e052                	sd	s4,0(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	84aa                	mv	s1,a0
    800025b2:	892e                	mv	s2,a1
    800025b4:	89b2                	mv	s3,a2
    800025b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b8:	fffff097          	auipc	ra,0xfffff
    800025bc:	554080e7          	jalr	1364(ra) # 80001b0c <myproc>
  if(user_dst){
    800025c0:	c08d                	beqz	s1,800025e2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025c2:	86d2                	mv	a3,s4
    800025c4:	864e                	mv	a2,s3
    800025c6:	85ca                	mv	a1,s2
    800025c8:	6928                	ld	a0,80(a0)
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	204080e7          	jalr	516(ra) # 800017ce <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025d2:	70a2                	ld	ra,40(sp)
    800025d4:	7402                	ld	s0,32(sp)
    800025d6:	64e2                	ld	s1,24(sp)
    800025d8:	6942                	ld	s2,16(sp)
    800025da:	69a2                	ld	s3,8(sp)
    800025dc:	6a02                	ld	s4,0(sp)
    800025de:	6145                	addi	sp,sp,48
    800025e0:	8082                	ret
    memmove((char *)dst, src, len);
    800025e2:	000a061b          	sext.w	a2,s4
    800025e6:	85ce                	mv	a1,s3
    800025e8:	854a                	mv	a0,s2
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	756080e7          	jalr	1878(ra) # 80000d40 <memmove>
    return 0;
    800025f2:	8526                	mv	a0,s1
    800025f4:	bff9                	j	800025d2 <either_copyout+0x32>

00000000800025f6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025f6:	7179                	addi	sp,sp,-48
    800025f8:	f406                	sd	ra,40(sp)
    800025fa:	f022                	sd	s0,32(sp)
    800025fc:	ec26                	sd	s1,24(sp)
    800025fe:	e84a                	sd	s2,16(sp)
    80002600:	e44e                	sd	s3,8(sp)
    80002602:	e052                	sd	s4,0(sp)
    80002604:	1800                	addi	s0,sp,48
    80002606:	892a                	mv	s2,a0
    80002608:	84ae                	mv	s1,a1
    8000260a:	89b2                	mv	s3,a2
    8000260c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000260e:	fffff097          	auipc	ra,0xfffff
    80002612:	4fe080e7          	jalr	1278(ra) # 80001b0c <myproc>
  if(user_src){
    80002616:	c08d                	beqz	s1,80002638 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002618:	86d2                	mv	a3,s4
    8000261a:	864e                	mv	a2,s3
    8000261c:	85ca                	mv	a1,s2
    8000261e:	6928                	ld	a0,80(a0)
    80002620:	fffff097          	auipc	ra,0xfffff
    80002624:	23a080e7          	jalr	570(ra) # 8000185a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002628:	70a2                	ld	ra,40(sp)
    8000262a:	7402                	ld	s0,32(sp)
    8000262c:	64e2                	ld	s1,24(sp)
    8000262e:	6942                	ld	s2,16(sp)
    80002630:	69a2                	ld	s3,8(sp)
    80002632:	6a02                	ld	s4,0(sp)
    80002634:	6145                	addi	sp,sp,48
    80002636:	8082                	ret
    memmove(dst, (char*)src, len);
    80002638:	000a061b          	sext.w	a2,s4
    8000263c:	85ce                	mv	a1,s3
    8000263e:	854a                	mv	a0,s2
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	700080e7          	jalr	1792(ra) # 80000d40 <memmove>
    return 0;
    80002648:	8526                	mv	a0,s1
    8000264a:	bff9                	j	80002628 <either_copyin+0x32>

000000008000264c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000264c:	715d                	addi	sp,sp,-80
    8000264e:	e486                	sd	ra,72(sp)
    80002650:	e0a2                	sd	s0,64(sp)
    80002652:	fc26                	sd	s1,56(sp)
    80002654:	f84a                	sd	s2,48(sp)
    80002656:	f44e                	sd	s3,40(sp)
    80002658:	f052                	sd	s4,32(sp)
    8000265a:	ec56                	sd	s5,24(sp)
    8000265c:	e85a                	sd	s6,16(sp)
    8000265e:	e45e                	sd	s7,8(sp)
    80002660:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002662:	0000a517          	auipc	a0,0xa
    80002666:	abe50513          	addi	a0,a0,-1346 # 8000c120 <digits+0xe0>
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	f1e080e7          	jalr	-226(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002672:	00016497          	auipc	s1,0x16
    80002676:	1b648493          	addi	s1,s1,438 # 80018828 <proc+0x158>
    8000267a:	0001c917          	auipc	s2,0x1c
    8000267e:	bae90913          	addi	s2,s2,-1106 # 8001e228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002682:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002684:	0000a997          	auipc	s3,0xa
    80002688:	e0c98993          	addi	s3,s3,-500 # 8000c490 <digits+0x450>
    printf("%d %s %s", p->pid, state, p->name);
    8000268c:	0000aa97          	auipc	s5,0xa
    80002690:	e0ca8a93          	addi	s5,s5,-500 # 8000c498 <digits+0x458>
    printf("\n");
    80002694:	0000aa17          	auipc	s4,0xa
    80002698:	a8ca0a13          	addi	s4,s4,-1396 # 8000c120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000269c:	0000ab97          	auipc	s7,0xa
    800026a0:	e34b8b93          	addi	s7,s7,-460 # 8000c4d0 <states.1709>
    800026a4:	a00d                	j	800026c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026a6:	ed86a583          	lw	a1,-296(a3)
    800026aa:	8556                	mv	a0,s5
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	edc080e7          	jalr	-292(ra) # 80000588 <printf>
    printf("\n");
    800026b4:	8552                	mv	a0,s4
    800026b6:	ffffe097          	auipc	ra,0xffffe
    800026ba:	ed2080e7          	jalr	-302(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026be:	16848493          	addi	s1,s1,360
    800026c2:	03248163          	beq	s1,s2,800026e4 <procdump+0x98>
    if(p->state == UNUSED)
    800026c6:	86a6                	mv	a3,s1
    800026c8:	ec04a783          	lw	a5,-320(s1)
    800026cc:	dbed                	beqz	a5,800026be <procdump+0x72>
      state = "???";
    800026ce:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d0:	fcfb6be3          	bltu	s6,a5,800026a6 <procdump+0x5a>
    800026d4:	1782                	slli	a5,a5,0x20
    800026d6:	9381                	srli	a5,a5,0x20
    800026d8:	078e                	slli	a5,a5,0x3
    800026da:	97de                	add	a5,a5,s7
    800026dc:	6390                	ld	a2,0(a5)
    800026de:	f661                	bnez	a2,800026a6 <procdump+0x5a>
      state = "???";
    800026e0:	864e                	mv	a2,s3
    800026e2:	b7d1                	j	800026a6 <procdump+0x5a>
  }
}
    800026e4:	60a6                	ld	ra,72(sp)
    800026e6:	6406                	ld	s0,64(sp)
    800026e8:	74e2                	ld	s1,56(sp)
    800026ea:	7942                	ld	s2,48(sp)
    800026ec:	79a2                	ld	s3,40(sp)
    800026ee:	7a02                	ld	s4,32(sp)
    800026f0:	6ae2                	ld	s5,24(sp)
    800026f2:	6b42                	ld	s6,16(sp)
    800026f4:	6ba2                	ld	s7,8(sp)
    800026f6:	6161                	addi	sp,sp,80
    800026f8:	8082                	ret

00000000800026fa <swtch>:
    800026fa:	00153023          	sd	ra,0(a0)
    800026fe:	00253423          	sd	sp,8(a0)
    80002702:	e900                	sd	s0,16(a0)
    80002704:	ed04                	sd	s1,24(a0)
    80002706:	03253023          	sd	s2,32(a0)
    8000270a:	03353423          	sd	s3,40(a0)
    8000270e:	03453823          	sd	s4,48(a0)
    80002712:	03553c23          	sd	s5,56(a0)
    80002716:	05653023          	sd	s6,64(a0)
    8000271a:	05753423          	sd	s7,72(a0)
    8000271e:	05853823          	sd	s8,80(a0)
    80002722:	05953c23          	sd	s9,88(a0)
    80002726:	07a53023          	sd	s10,96(a0)
    8000272a:	07b53423          	sd	s11,104(a0)
    8000272e:	0005b083          	ld	ra,0(a1)
    80002732:	0085b103          	ld	sp,8(a1)
    80002736:	6980                	ld	s0,16(a1)
    80002738:	6d84                	ld	s1,24(a1)
    8000273a:	0205b903          	ld	s2,32(a1)
    8000273e:	0285b983          	ld	s3,40(a1)
    80002742:	0305ba03          	ld	s4,48(a1)
    80002746:	0385ba83          	ld	s5,56(a1)
    8000274a:	0405bb03          	ld	s6,64(a1)
    8000274e:	0485bb83          	ld	s7,72(a1)
    80002752:	0505bc03          	ld	s8,80(a1)
    80002756:	0585bc83          	ld	s9,88(a1)
    8000275a:	0605bd03          	ld	s10,96(a1)
    8000275e:	0685bd83          	ld	s11,104(a1)
    80002762:	8082                	ret

0000000080002764 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002764:	1141                	addi	sp,sp,-16
    80002766:	e406                	sd	ra,8(sp)
    80002768:	e022                	sd	s0,0(sp)
    8000276a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000276c:	0000a597          	auipc	a1,0xa
    80002770:	d9458593          	addi	a1,a1,-620 # 8000c500 <states.1709+0x30>
    80002774:	0001c517          	auipc	a0,0x1c
    80002778:	95c50513          	addi	a0,a0,-1700 # 8001e0d0 <tickslock>
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	3d8080e7          	jalr	984(ra) # 80000b54 <initlock>
}
    80002784:	60a2                	ld	ra,8(sp)
    80002786:	6402                	ld	s0,0(sp)
    80002788:	0141                	addi	sp,sp,16
    8000278a:	8082                	ret

000000008000278c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000278c:	1141                	addi	sp,sp,-16
    8000278e:	e406                	sd	ra,8(sp)
    80002790:	e022                	sd	s0,0(sp)
    80002792:	0800                	addi	s0,sp,16
  printf("kernelvec: %x\n",kernelvec);
    80002794:	00003597          	auipc	a1,0x3
    80002798:	4fc58593          	addi	a1,a1,1276 # 80005c90 <kernelvec>
    8000279c:	0000a517          	auipc	a0,0xa
    800027a0:	d6c50513          	addi	a0,a0,-660 # 8000c508 <states.1709+0x38>
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	de4080e7          	jalr	-540(ra) # 80000588 <printf>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027ac:	00003797          	auipc	a5,0x3
    800027b0:	4e478793          	addi	a5,a5,1252 # 80005c90 <kernelvec>
    800027b4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027b8:	60a2                	ld	ra,8(sp)
    800027ba:	6402                	ld	s0,0(sp)
    800027bc:	0141                	addi	sp,sp,16
    800027be:	8082                	ret

00000000800027c0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027c0:	1141                	addi	sp,sp,-16
    800027c2:	e406                	sd	ra,8(sp)
    800027c4:	e022                	sd	s0,0(sp)
    800027c6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	344080e7          	jalr	836(ra) # 80001b0c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027da:	00006617          	auipc	a2,0x6
    800027de:	82660613          	addi	a2,a2,-2010 # 80008000 <_trampoline>
    800027e2:	00006697          	auipc	a3,0x6
    800027e6:	81e68693          	addi	a3,a3,-2018 # 80008000 <_trampoline>
    800027ea:	8e91                	sub	a3,a3,a2
    800027ec:	008007b7          	lui	a5,0x800
    800027f0:	17fd                	addi	a5,a5,-1
    800027f2:	07ba                	slli	a5,a5,0xe
    800027f4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027fa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027fc:	180026f3          	csrr	a3,satp
    80002800:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002802:	6d38                	ld	a4,88(a0)
    80002804:	6134                	ld	a3,64(a0)
    80002806:	6591                	lui	a1,0x4
    80002808:	96ae                	add	a3,a3,a1
    8000280a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000280c:	6d38                	ld	a4,88(a0)
    8000280e:	00000697          	auipc	a3,0x0
    80002812:	13868693          	addi	a3,a3,312 # 80002946 <usertrap>
    80002816:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002818:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000281a:	8692                	mv	a3,tp
    8000281c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002822:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002826:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000282e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002830:	6f18                	ld	a4,24(a4)
    80002832:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002836:	692c                	ld	a1,80(a0)
    80002838:	81b9                	srli	a1,a1,0xe

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000283a:	00006717          	auipc	a4,0x6
    8000283e:	85670713          	addi	a4,a4,-1962 # 80008090 <userret>
    80002842:	8f11                	sub	a4,a4,a2
    80002844:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002846:	577d                	li	a4,-1
    80002848:	177e                	slli	a4,a4,0x3f
    8000284a:	8dd9                	or	a1,a1,a4
    8000284c:	00400537          	lui	a0,0x400
    80002850:	157d                	addi	a0,a0,-1
    80002852:	053e                	slli	a0,a0,0xf
    80002854:	9782                	jalr	a5
}
    80002856:	60a2                	ld	ra,8(sp)
    80002858:	6402                	ld	s0,0(sp)
    8000285a:	0141                	addi	sp,sp,16
    8000285c:	8082                	ret

000000008000285e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000285e:	1101                	addi	sp,sp,-32
    80002860:	ec06                	sd	ra,24(sp)
    80002862:	e822                	sd	s0,16(sp)
    80002864:	e426                	sd	s1,8(sp)
    80002866:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002868:	0001c497          	auipc	s1,0x1c
    8000286c:	86848493          	addi	s1,s1,-1944 # 8001e0d0 <tickslock>
    80002870:	8526                	mv	a0,s1
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	372080e7          	jalr	882(ra) # 80000be4 <acquire>
  ticks++;
    8000287a:	0000d517          	auipc	a0,0xd
    8000287e:	7b650513          	addi	a0,a0,1974 # 80010030 <ticks>
    80002882:	411c                	lw	a5,0(a0)
    80002884:	2785                	addiw	a5,a5,1
    80002886:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	b00080e7          	jalr	-1280(ra) # 80002388 <wakeup>
  release(&tickslock);
    80002890:	8526                	mv	a0,s1
    80002892:	ffffe097          	auipc	ra,0xffffe
    80002896:	406080e7          	jalr	1030(ra) # 80000c98 <release>
}
    8000289a:	60e2                	ld	ra,24(sp)
    8000289c:	6442                	ld	s0,16(sp)
    8000289e:	64a2                	ld	s1,8(sp)
    800028a0:	6105                	addi	sp,sp,32
    800028a2:	8082                	ret

00000000800028a4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028a4:	1101                	addi	sp,sp,-32
    800028a6:	ec06                	sd	ra,24(sp)
    800028a8:	e822                	sd	s0,16(sp)
    800028aa:	e426                	sd	s1,8(sp)
    800028ac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028b2:	00074d63          	bltz	a4,800028cc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028b6:	57fd                	li	a5,-1
    800028b8:	17fe                	slli	a5,a5,0x3f
    800028ba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028bc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028be:	06f70363          	beq	a4,a5,80002924 <devintr+0x80>
  }
}
    800028c2:	60e2                	ld	ra,24(sp)
    800028c4:	6442                	ld	s0,16(sp)
    800028c6:	64a2                	ld	s1,8(sp)
    800028c8:	6105                	addi	sp,sp,32
    800028ca:	8082                	ret
     (scause & 0xff) == 9){
    800028cc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028d0:	46a5                	li	a3,9
    800028d2:	fed792e3          	bne	a5,a3,800028b6 <devintr+0x12>
    int irq = plic_claim();
    800028d6:	00003097          	auipc	ra,0x3
    800028da:	4c2080e7          	jalr	1218(ra) # 80005d98 <plic_claim>
    800028de:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028e0:	47a9                	li	a5,10
    800028e2:	02f50763          	beq	a0,a5,80002910 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028e6:	4785                	li	a5,1
    800028e8:	02f50963          	beq	a0,a5,8000291a <devintr+0x76>
    return 1;
    800028ec:	4505                	li	a0,1
    } else if(irq){
    800028ee:	d8f1                	beqz	s1,800028c2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f0:	85a6                	mv	a1,s1
    800028f2:	0000a517          	auipc	a0,0xa
    800028f6:	c2650513          	addi	a0,a0,-986 # 8000c518 <states.1709+0x48>
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	c8e080e7          	jalr	-882(ra) # 80000588 <printf>
      plic_complete(irq);
    80002902:	8526                	mv	a0,s1
    80002904:	00003097          	auipc	ra,0x3
    80002908:	4b8080e7          	jalr	1208(ra) # 80005dbc <plic_complete>
    return 1;
    8000290c:	4505                	li	a0,1
    8000290e:	bf55                	j	800028c2 <devintr+0x1e>
      uartintr();
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	098080e7          	jalr	152(ra) # 800009a8 <uartintr>
    80002918:	b7ed                	j	80002902 <devintr+0x5e>
      virtio_disk_intr();
    8000291a:	00004097          	auipc	ra,0x4
    8000291e:	9b0080e7          	jalr	-1616(ra) # 800062ca <virtio_disk_intr>
    80002922:	b7c5                	j	80002902 <devintr+0x5e>
    if(cpuid() == 0){
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	1bc080e7          	jalr	444(ra) # 80001ae0 <cpuid>
    8000292c:	c901                	beqz	a0,8000293c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000292e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002932:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002934:	14479073          	csrw	sip,a5
    return 2;
    80002938:	4509                	li	a0,2
    8000293a:	b761                	j	800028c2 <devintr+0x1e>
      clockintr();
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	f22080e7          	jalr	-222(ra) # 8000285e <clockintr>
    80002944:	b7ed                	j	8000292e <devintr+0x8a>

0000000080002946 <usertrap>:
{
    80002946:	1101                	addi	sp,sp,-32
    80002948:	ec06                	sd	ra,24(sp)
    8000294a:	e822                	sd	s0,16(sp)
    8000294c:	e426                	sd	s1,8(sp)
    8000294e:	e04a                	sd	s2,0(sp)
    80002950:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002952:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002956:	1007f793          	andi	a5,a5,256
    8000295a:	e3ad                	bnez	a5,800029bc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000295c:	00003797          	auipc	a5,0x3
    80002960:	33478793          	addi	a5,a5,820 # 80005c90 <kernelvec>
    80002964:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	1a4080e7          	jalr	420(ra) # 80001b0c <myproc>
    80002970:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002972:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002974:	14102773          	csrr	a4,sepc
    80002978:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000297e:	47a1                	li	a5,8
    80002980:	04f71c63          	bne	a4,a5,800029d8 <usertrap+0x92>
    if(p->killed)
    80002984:	551c                	lw	a5,40(a0)
    80002986:	e3b9                	bnez	a5,800029cc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002988:	6cb8                	ld	a4,88(s1)
    8000298a:	6f1c                	ld	a5,24(a4)
    8000298c:	0791                	addi	a5,a5,4
    8000298e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002990:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002994:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002998:	10079073          	csrw	sstatus,a5
    syscall();
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	2e0080e7          	jalr	736(ra) # 80002c7c <syscall>
  if(p->killed)
    800029a4:	549c                	lw	a5,40(s1)
    800029a6:	ebc1                	bnez	a5,80002a36 <usertrap+0xf0>
  usertrapret();
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	e18080e7          	jalr	-488(ra) # 800027c0 <usertrapret>
}
    800029b0:	60e2                	ld	ra,24(sp)
    800029b2:	6442                	ld	s0,16(sp)
    800029b4:	64a2                	ld	s1,8(sp)
    800029b6:	6902                	ld	s2,0(sp)
    800029b8:	6105                	addi	sp,sp,32
    800029ba:	8082                	ret
    panic("usertrap: not from user mode");
    800029bc:	0000a517          	auipc	a0,0xa
    800029c0:	b7c50513          	addi	a0,a0,-1156 # 8000c538 <states.1709+0x68>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	b7a080e7          	jalr	-1158(ra) # 8000053e <panic>
      exit(-1);
    800029cc:	557d                	li	a0,-1
    800029ce:	00000097          	auipc	ra,0x0
    800029d2:	a8a080e7          	jalr	-1398(ra) # 80002458 <exit>
    800029d6:	bf4d                	j	80002988 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	ecc080e7          	jalr	-308(ra) # 800028a4 <devintr>
    800029e0:	892a                	mv	s2,a0
    800029e2:	c501                	beqz	a0,800029ea <usertrap+0xa4>
  if(p->killed)
    800029e4:	549c                	lw	a5,40(s1)
    800029e6:	c3a1                	beqz	a5,80002a26 <usertrap+0xe0>
    800029e8:	a815                	j	80002a1c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ea:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ee:	5890                	lw	a2,48(s1)
    800029f0:	0000a517          	auipc	a0,0xa
    800029f4:	b6850513          	addi	a0,a0,-1176 # 8000c558 <states.1709+0x88>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b90080e7          	jalr	-1136(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a04:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a08:	0000a517          	auipc	a0,0xa
    80002a0c:	b8050513          	addi	a0,a0,-1152 # 8000c588 <states.1709+0xb8>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b78080e7          	jalr	-1160(ra) # 80000588 <printf>
    p->killed = 1;
    80002a18:	4785                	li	a5,1
    80002a1a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002a1c:	557d                	li	a0,-1
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	a3a080e7          	jalr	-1478(ra) # 80002458 <exit>
  if(which_dev == 2)
    80002a26:	4789                	li	a5,2
    80002a28:	f8f910e3          	bne	s2,a5,800029a8 <usertrap+0x62>
    yield();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	794080e7          	jalr	1940(ra) # 800021c0 <yield>
    80002a34:	bf95                	j	800029a8 <usertrap+0x62>
  int which_dev = 0;
    80002a36:	4901                	li	s2,0
    80002a38:	b7d5                	j	80002a1c <usertrap+0xd6>

0000000080002a3a <kerneltrap>:
{
    80002a3a:	7179                	addi	sp,sp,-48
    80002a3c:	f406                	sd	ra,40(sp)
    80002a3e:	f022                	sd	s0,32(sp)
    80002a40:	ec26                	sd	s1,24(sp)
    80002a42:	e84a                	sd	s2,16(sp)
    80002a44:	e44e                	sd	s3,8(sp)
    80002a46:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a48:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a4c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a50:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a54:	1004f793          	andi	a5,s1,256
    80002a58:	cb85                	beqz	a5,80002a88 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a5e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a60:	ef85                	bnez	a5,80002a98 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	e42080e7          	jalr	-446(ra) # 800028a4 <devintr>
    80002a6a:	cd1d                	beqz	a0,80002aa8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a6c:	4789                	li	a5,2
    80002a6e:	06f50a63          	beq	a0,a5,80002ae2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a72:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a76:	10049073          	csrw	sstatus,s1
}
    80002a7a:	70a2                	ld	ra,40(sp)
    80002a7c:	7402                	ld	s0,32(sp)
    80002a7e:	64e2                	ld	s1,24(sp)
    80002a80:	6942                	ld	s2,16(sp)
    80002a82:	69a2                	ld	s3,8(sp)
    80002a84:	6145                	addi	sp,sp,48
    80002a86:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a88:	0000a517          	auipc	a0,0xa
    80002a8c:	b2050513          	addi	a0,a0,-1248 # 8000c5a8 <states.1709+0xd8>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	aae080e7          	jalr	-1362(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a98:	0000a517          	auipc	a0,0xa
    80002a9c:	b3850513          	addi	a0,a0,-1224 # 8000c5d0 <states.1709+0x100>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	a9e080e7          	jalr	-1378(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002aa8:	85ce                	mv	a1,s3
    80002aaa:	0000a517          	auipc	a0,0xa
    80002aae:	b4650513          	addi	a0,a0,-1210 # 8000c5f0 <states.1709+0x120>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ad6080e7          	jalr	-1322(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002abe:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac2:	0000a517          	auipc	a0,0xa
    80002ac6:	b3e50513          	addi	a0,a0,-1218 # 8000c600 <states.1709+0x130>
    80002aca:	ffffe097          	auipc	ra,0xffffe
    80002ace:	abe080e7          	jalr	-1346(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ad2:	0000a517          	auipc	a0,0xa
    80002ad6:	b4650513          	addi	a0,a0,-1210 # 8000c618 <states.1709+0x148>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	a64080e7          	jalr	-1436(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	02a080e7          	jalr	42(ra) # 80001b0c <myproc>
    80002aea:	d541                	beqz	a0,80002a72 <kerneltrap+0x38>
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	020080e7          	jalr	32(ra) # 80001b0c <myproc>
    80002af4:	4d18                	lw	a4,24(a0)
    80002af6:	4791                	li	a5,4
    80002af8:	f6f71de3          	bne	a4,a5,80002a72 <kerneltrap+0x38>
    yield();
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	6c4080e7          	jalr	1732(ra) # 800021c0 <yield>
    80002b04:	b7bd                	j	80002a72 <kerneltrap+0x38>

0000000080002b06 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b06:	1101                	addi	sp,sp,-32
    80002b08:	ec06                	sd	ra,24(sp)
    80002b0a:	e822                	sd	s0,16(sp)
    80002b0c:	e426                	sd	s1,8(sp)
    80002b0e:	1000                	addi	s0,sp,32
    80002b10:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	ffa080e7          	jalr	-6(ra) # 80001b0c <myproc>
  switch (n) {
    80002b1a:	4795                	li	a5,5
    80002b1c:	0497e163          	bltu	a5,s1,80002b5e <argraw+0x58>
    80002b20:	048a                	slli	s1,s1,0x2
    80002b22:	0000a717          	auipc	a4,0xa
    80002b26:	b2e70713          	addi	a4,a4,-1234 # 8000c650 <states.1709+0x180>
    80002b2a:	94ba                	add	s1,s1,a4
    80002b2c:	409c                	lw	a5,0(s1)
    80002b2e:	97ba                	add	a5,a5,a4
    80002b30:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b32:	6d3c                	ld	a5,88(a0)
    80002b34:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b36:	60e2                	ld	ra,24(sp)
    80002b38:	6442                	ld	s0,16(sp)
    80002b3a:	64a2                	ld	s1,8(sp)
    80002b3c:	6105                	addi	sp,sp,32
    80002b3e:	8082                	ret
    return p->trapframe->a1;
    80002b40:	6d3c                	ld	a5,88(a0)
    80002b42:	7fa8                	ld	a0,120(a5)
    80002b44:	bfcd                	j	80002b36 <argraw+0x30>
    return p->trapframe->a2;
    80002b46:	6d3c                	ld	a5,88(a0)
    80002b48:	63c8                	ld	a0,128(a5)
    80002b4a:	b7f5                	j	80002b36 <argraw+0x30>
    return p->trapframe->a3;
    80002b4c:	6d3c                	ld	a5,88(a0)
    80002b4e:	67c8                	ld	a0,136(a5)
    80002b50:	b7dd                	j	80002b36 <argraw+0x30>
    return p->trapframe->a4;
    80002b52:	6d3c                	ld	a5,88(a0)
    80002b54:	6bc8                	ld	a0,144(a5)
    80002b56:	b7c5                	j	80002b36 <argraw+0x30>
    return p->trapframe->a5;
    80002b58:	6d3c                	ld	a5,88(a0)
    80002b5a:	6fc8                	ld	a0,152(a5)
    80002b5c:	bfe9                	j	80002b36 <argraw+0x30>
  panic("argraw");
    80002b5e:	0000a517          	auipc	a0,0xa
    80002b62:	aca50513          	addi	a0,a0,-1334 # 8000c628 <states.1709+0x158>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9d8080e7          	jalr	-1576(ra) # 8000053e <panic>

0000000080002b6e <fetchaddr>:
{
    80002b6e:	1101                	addi	sp,sp,-32
    80002b70:	ec06                	sd	ra,24(sp)
    80002b72:	e822                	sd	s0,16(sp)
    80002b74:	e426                	sd	s1,8(sp)
    80002b76:	e04a                	sd	s2,0(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84aa                	mv	s1,a0
    80002b7c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	f8e080e7          	jalr	-114(ra) # 80001b0c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b86:	653c                	ld	a5,72(a0)
    80002b88:	02f4f863          	bgeu	s1,a5,80002bb8 <fetchaddr+0x4a>
    80002b8c:	00848713          	addi	a4,s1,8
    80002b90:	02e7e663          	bltu	a5,a4,80002bbc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b94:	46a1                	li	a3,8
    80002b96:	8626                	mv	a2,s1
    80002b98:	85ca                	mv	a1,s2
    80002b9a:	6928                	ld	a0,80(a0)
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	cbe080e7          	jalr	-834(ra) # 8000185a <copyin>
    80002ba4:	00a03533          	snez	a0,a0
    80002ba8:	40a00533          	neg	a0,a0
}
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	64a2                	ld	s1,8(sp)
    80002bb2:	6902                	ld	s2,0(sp)
    80002bb4:	6105                	addi	sp,sp,32
    80002bb6:	8082                	ret
    return -1;
    80002bb8:	557d                	li	a0,-1
    80002bba:	bfcd                	j	80002bac <fetchaddr+0x3e>
    80002bbc:	557d                	li	a0,-1
    80002bbe:	b7fd                	j	80002bac <fetchaddr+0x3e>

0000000080002bc0 <fetchstr>:
{
    80002bc0:	7179                	addi	sp,sp,-48
    80002bc2:	f406                	sd	ra,40(sp)
    80002bc4:	f022                	sd	s0,32(sp)
    80002bc6:	ec26                	sd	s1,24(sp)
    80002bc8:	e84a                	sd	s2,16(sp)
    80002bca:	e44e                	sd	s3,8(sp)
    80002bcc:	1800                	addi	s0,sp,48
    80002bce:	892a                	mv	s2,a0
    80002bd0:	84ae                	mv	s1,a1
    80002bd2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	f38080e7          	jalr	-200(ra) # 80001b0c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bdc:	86ce                	mv	a3,s3
    80002bde:	864a                	mv	a2,s2
    80002be0:	85a6                	mv	a1,s1
    80002be2:	6928                	ld	a0,80(a0)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	d02080e7          	jalr	-766(ra) # 800018e6 <copyinstr>
  if(err < 0)
    80002bec:	00054763          	bltz	a0,80002bfa <fetchstr+0x3a>
  return strlen(buf);
    80002bf0:	8526                	mv	a0,s1
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	272080e7          	jalr	626(ra) # 80000e64 <strlen>
}
    80002bfa:	70a2                	ld	ra,40(sp)
    80002bfc:	7402                	ld	s0,32(sp)
    80002bfe:	64e2                	ld	s1,24(sp)
    80002c00:	6942                	ld	s2,16(sp)
    80002c02:	69a2                	ld	s3,8(sp)
    80002c04:	6145                	addi	sp,sp,48
    80002c06:	8082                	ret

0000000080002c08 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c08:	1101                	addi	sp,sp,-32
    80002c0a:	ec06                	sd	ra,24(sp)
    80002c0c:	e822                	sd	s0,16(sp)
    80002c0e:	e426                	sd	s1,8(sp)
    80002c10:	1000                	addi	s0,sp,32
    80002c12:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	ef2080e7          	jalr	-270(ra) # 80002b06 <argraw>
    80002c1c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c1e:	4501                	li	a0,0
    80002c20:	60e2                	ld	ra,24(sp)
    80002c22:	6442                	ld	s0,16(sp)
    80002c24:	64a2                	ld	s1,8(sp)
    80002c26:	6105                	addi	sp,sp,32
    80002c28:	8082                	ret

0000000080002c2a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	1000                	addi	s0,sp,32
    80002c34:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	ed0080e7          	jalr	-304(ra) # 80002b06 <argraw>
    80002c3e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c40:	4501                	li	a0,0
    80002c42:	60e2                	ld	ra,24(sp)
    80002c44:	6442                	ld	s0,16(sp)
    80002c46:	64a2                	ld	s1,8(sp)
    80002c48:	6105                	addi	sp,sp,32
    80002c4a:	8082                	ret

0000000080002c4c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	e04a                	sd	s2,0(sp)
    80002c56:	1000                	addi	s0,sp,32
    80002c58:	84ae                	mv	s1,a1
    80002c5a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	eaa080e7          	jalr	-342(ra) # 80002b06 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c64:	864a                	mv	a2,s2
    80002c66:	85a6                	mv	a1,s1
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	f58080e7          	jalr	-168(ra) # 80002bc0 <fetchstr>
}
    80002c70:	60e2                	ld	ra,24(sp)
    80002c72:	6442                	ld	s0,16(sp)
    80002c74:	64a2                	ld	s1,8(sp)
    80002c76:	6902                	ld	s2,0(sp)
    80002c78:	6105                	addi	sp,sp,32
    80002c7a:	8082                	ret

0000000080002c7c <syscall>:
[SYS_mmtrace] sys_mmtrace 
};

void
syscall(void)
{
    80002c7c:	1101                	addi	sp,sp,-32
    80002c7e:	ec06                	sd	ra,24(sp)
    80002c80:	e822                	sd	s0,16(sp)
    80002c82:	e426                	sd	s1,8(sp)
    80002c84:	e04a                	sd	s2,0(sp)
    80002c86:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	e84080e7          	jalr	-380(ra) # 80001b0c <myproc>
    80002c90:	84aa                	mv	s1,a0
  num = p->trapframe->a7;
    80002c92:	05853903          	ld	s2,88(a0)
    80002c96:	0a893783          	ld	a5,168(s2)
    80002c9a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c9e:	37fd                	addiw	a5,a5,-1
    80002ca0:	4755                	li	a4,21
    80002ca2:	00f76f63          	bltu	a4,a5,80002cc0 <syscall+0x44>
    80002ca6:	00369713          	slli	a4,a3,0x3
    80002caa:	0000a797          	auipc	a5,0xa
    80002cae:	9be78793          	addi	a5,a5,-1602 # 8000c668 <syscalls>
    80002cb2:	97ba                	add	a5,a5,a4
    80002cb4:	639c                	ld	a5,0(a5)
    80002cb6:	c789                	beqz	a5,80002cc0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cb8:	9782                	jalr	a5
    80002cba:	06a93823          	sd	a0,112(s2)
    80002cbe:	a839                	j	80002cdc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cc0:	15848613          	addi	a2,s1,344
    80002cc4:	588c                	lw	a1,48(s1)
    80002cc6:	0000a517          	auipc	a0,0xa
    80002cca:	96a50513          	addi	a0,a0,-1686 # 8000c630 <states.1709+0x160>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8ba080e7          	jalr	-1862(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cd6:	6cbc                	ld	a5,88(s1)
    80002cd8:	577d                	li	a4,-1
    80002cda:	fbb8                	sd	a4,112(a5)
  }
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6902                	ld	s2,0(sp)
    80002ce4:	6105                	addi	sp,sp,32
    80002ce6:	8082                	ret

0000000080002ce8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce8:	1101                	addi	sp,sp,-32
    80002cea:	ec06                	sd	ra,24(sp)
    80002cec:	e822                	sd	s0,16(sp)
    80002cee:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002cf0:	fec40593          	addi	a1,s0,-20
    80002cf4:	4501                	li	a0,0
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	f12080e7          	jalr	-238(ra) # 80002c08 <argint>
    return -1;
    80002cfe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d00:	00054963          	bltz	a0,80002d12 <sys_exit+0x2a>
  exit(n);
    80002d04:	fec42503          	lw	a0,-20(s0)
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	750080e7          	jalr	1872(ra) # 80002458 <exit>
  return 0;  // not reached
    80002d10:	4781                	li	a5,0
}
    80002d12:	853e                	mv	a0,a5
    80002d14:	60e2                	ld	ra,24(sp)
    80002d16:	6442                	ld	s0,16(sp)
    80002d18:	6105                	addi	sp,sp,32
    80002d1a:	8082                	ret

0000000080002d1c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d1c:	1141                	addi	sp,sp,-16
    80002d1e:	e406                	sd	ra,8(sp)
    80002d20:	e022                	sd	s0,0(sp)
    80002d22:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	de8080e7          	jalr	-536(ra) # 80001b0c <myproc>
}
    80002d2c:	5908                	lw	a0,48(a0)
    80002d2e:	60a2                	ld	ra,8(sp)
    80002d30:	6402                	ld	s0,0(sp)
    80002d32:	0141                	addi	sp,sp,16
    80002d34:	8082                	ret

0000000080002d36 <sys_fork>:

uint64
sys_fork(void)
{
    80002d36:	1141                	addi	sp,sp,-16
    80002d38:	e406                	sd	ra,8(sp)
    80002d3a:	e022                	sd	s0,0(sp)
    80002d3c:	0800                	addi	s0,sp,16
  return fork();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	1d0080e7          	jalr	464(ra) # 80001f0e <fork>
}
    80002d46:	60a2                	ld	ra,8(sp)
    80002d48:	6402                	ld	s0,0(sp)
    80002d4a:	0141                	addi	sp,sp,16
    80002d4c:	8082                	ret

0000000080002d4e <sys_wait>:

uint64
sys_wait(void)
{
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d56:	fe840593          	addi	a1,s0,-24
    80002d5a:	4501                	li	a0,0
    80002d5c:	00000097          	auipc	ra,0x0
    80002d60:	ece080e7          	jalr	-306(ra) # 80002c2a <argaddr>
    80002d64:	87aa                	mv	a5,a0
    return -1;
    80002d66:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d68:	0007c863          	bltz	a5,80002d78 <sys_wait+0x2a>
  return wait(p);
    80002d6c:	fe843503          	ld	a0,-24(s0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	4f0080e7          	jalr	1264(ra) # 80002260 <wait>
}
    80002d78:	60e2                	ld	ra,24(sp)
    80002d7a:	6442                	ld	s0,16(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d80:	7179                	addi	sp,sp,-48
    80002d82:	f406                	sd	ra,40(sp)
    80002d84:	f022                	sd	s0,32(sp)
    80002d86:	ec26                	sd	s1,24(sp)
    80002d88:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d8a:	fdc40593          	addi	a1,s0,-36
    80002d8e:	4501                	li	a0,0
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	e78080e7          	jalr	-392(ra) # 80002c08 <argint>
    80002d98:	87aa                	mv	a5,a0
    return -1;
    80002d9a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d9c:	0207c063          	bltz	a5,80002dbc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	d6c080e7          	jalr	-660(ra) # 80001b0c <myproc>
    80002da8:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002daa:	fdc42503          	lw	a0,-36(s0)
    80002dae:	fffff097          	auipc	ra,0xfffff
    80002db2:	0ec080e7          	jalr	236(ra) # 80001e9a <growproc>
    80002db6:	00054863          	bltz	a0,80002dc6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dba:	8526                	mv	a0,s1
}
    80002dbc:	70a2                	ld	ra,40(sp)
    80002dbe:	7402                	ld	s0,32(sp)
    80002dc0:	64e2                	ld	s1,24(sp)
    80002dc2:	6145                	addi	sp,sp,48
    80002dc4:	8082                	ret
    return -1;
    80002dc6:	557d                	li	a0,-1
    80002dc8:	bfd5                	j	80002dbc <sys_sbrk+0x3c>

0000000080002dca <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dca:	7139                	addi	sp,sp,-64
    80002dcc:	fc06                	sd	ra,56(sp)
    80002dce:	f822                	sd	s0,48(sp)
    80002dd0:	f426                	sd	s1,40(sp)
    80002dd2:	f04a                	sd	s2,32(sp)
    80002dd4:	ec4e                	sd	s3,24(sp)
    80002dd6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002dd8:	fcc40593          	addi	a1,s0,-52
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	e2a080e7          	jalr	-470(ra) # 80002c08 <argint>
    return -1;
    80002de6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002de8:	06054563          	bltz	a0,80002e52 <sys_sleep+0x88>
  acquire(&tickslock);
    80002dec:	0001b517          	auipc	a0,0x1b
    80002df0:	2e450513          	addi	a0,a0,740 # 8001e0d0 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	df0080e7          	jalr	-528(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002dfc:	0000d917          	auipc	s2,0xd
    80002e00:	23492903          	lw	s2,564(s2) # 80010030 <ticks>
  while(ticks - ticks0 < n){
    80002e04:	fcc42783          	lw	a5,-52(s0)
    80002e08:	cf85                	beqz	a5,80002e40 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e0a:	0001b997          	auipc	s3,0x1b
    80002e0e:	2c698993          	addi	s3,s3,710 # 8001e0d0 <tickslock>
    80002e12:	0000d497          	auipc	s1,0xd
    80002e16:	21e48493          	addi	s1,s1,542 # 80010030 <ticks>
    if(myproc()->killed){
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	cf2080e7          	jalr	-782(ra) # 80001b0c <myproc>
    80002e22:	551c                	lw	a5,40(a0)
    80002e24:	ef9d                	bnez	a5,80002e62 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e26:	85ce                	mv	a1,s3
    80002e28:	8526                	mv	a0,s1
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	3d2080e7          	jalr	978(ra) # 800021fc <sleep>
  while(ticks - ticks0 < n){
    80002e32:	409c                	lw	a5,0(s1)
    80002e34:	412787bb          	subw	a5,a5,s2
    80002e38:	fcc42703          	lw	a4,-52(s0)
    80002e3c:	fce7efe3          	bltu	a5,a4,80002e1a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e40:	0001b517          	auipc	a0,0x1b
    80002e44:	29050513          	addi	a0,a0,656 # 8001e0d0 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
  return 0;
    80002e50:	4781                	li	a5,0
}
    80002e52:	853e                	mv	a0,a5
    80002e54:	70e2                	ld	ra,56(sp)
    80002e56:	7442                	ld	s0,48(sp)
    80002e58:	74a2                	ld	s1,40(sp)
    80002e5a:	7902                	ld	s2,32(sp)
    80002e5c:	69e2                	ld	s3,24(sp)
    80002e5e:	6121                	addi	sp,sp,64
    80002e60:	8082                	ret
      release(&tickslock);
    80002e62:	0001b517          	auipc	a0,0x1b
    80002e66:	26e50513          	addi	a0,a0,622 # 8001e0d0 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	e2e080e7          	jalr	-466(ra) # 80000c98 <release>
      return -1;
    80002e72:	57fd                	li	a5,-1
    80002e74:	bff9                	j	80002e52 <sys_sleep+0x88>

0000000080002e76 <sys_kill>:

uint64
sys_kill(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e7e:	fec40593          	addi	a1,s0,-20
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	d84080e7          	jalr	-636(ra) # 80002c08 <argint>
    80002e8c:	87aa                	mv	a5,a0
    return -1;
    80002e8e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e90:	0007c863          	bltz	a5,80002ea0 <sys_kill+0x2a>
  return kill(pid);
    80002e94:	fec42503          	lw	a0,-20(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	696080e7          	jalr	1686(ra) # 8000252e <kill>
}
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	e426                	sd	s1,8(sp)
    80002eb0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eb2:	0001b517          	auipc	a0,0x1b
    80002eb6:	21e50513          	addi	a0,a0,542 # 8001e0d0 <tickslock>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	d2a080e7          	jalr	-726(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002ec2:	0000d497          	auipc	s1,0xd
    80002ec6:	16e4a483          	lw	s1,366(s1) # 80010030 <ticks>
  release(&tickslock);
    80002eca:	0001b517          	auipc	a0,0x1b
    80002ece:	20650513          	addi	a0,a0,518 # 8001e0d0 <tickslock>
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	dc6080e7          	jalr	-570(ra) # 80000c98 <release>
  return xticks;
}
    80002eda:	02049513          	slli	a0,s1,0x20
    80002ede:	9101                	srli	a0,a0,0x20
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eea:	7179                	addi	sp,sp,-48
    80002eec:	f406                	sd	ra,40(sp)
    80002eee:	f022                	sd	s0,32(sp)
    80002ef0:	ec26                	sd	s1,24(sp)
    80002ef2:	e84a                	sd	s2,16(sp)
    80002ef4:	e44e                	sd	s3,8(sp)
    80002ef6:	e052                	sd	s4,0(sp)
    80002ef8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002efa:	0000a597          	auipc	a1,0xa
    80002efe:	82658593          	addi	a1,a1,-2010 # 8000c720 <syscalls+0xb8>
    80002f02:	0001b517          	auipc	a0,0x1b
    80002f06:	1e650513          	addi	a0,a0,486 # 8001e0e8 <bcache>
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	c4a080e7          	jalr	-950(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f12:	00023797          	auipc	a5,0x23
    80002f16:	1d678793          	addi	a5,a5,470 # 800260e8 <bcache+0x8000>
    80002f1a:	00023717          	auipc	a4,0x23
    80002f1e:	43670713          	addi	a4,a4,1078 # 80026350 <bcache+0x8268>
    80002f22:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f26:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f2a:	0001b497          	auipc	s1,0x1b
    80002f2e:	1d648493          	addi	s1,s1,470 # 8001e100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f32:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f34:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f36:	00009a17          	auipc	s4,0x9
    80002f3a:	7f2a0a13          	addi	s4,s4,2034 # 8000c728 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f3e:	2b893783          	ld	a5,696(s2)
    80002f42:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f44:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f48:	85d2                	mv	a1,s4
    80002f4a:	01048513          	addi	a0,s1,16
    80002f4e:	00001097          	auipc	ra,0x1
    80002f52:	4ce080e7          	jalr	1230(ra) # 8000441c <initsleeplock>
    bcache.head.next->prev = b;
    80002f56:	2b893783          	ld	a5,696(s2)
    80002f5a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f5c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f60:	45848493          	addi	s1,s1,1112
    80002f64:	fd349de3          	bne	s1,s3,80002f3e <binit+0x54>
  }
}
    80002f68:	70a2                	ld	ra,40(sp)
    80002f6a:	7402                	ld	s0,32(sp)
    80002f6c:	64e2                	ld	s1,24(sp)
    80002f6e:	6942                	ld	s2,16(sp)
    80002f70:	69a2                	ld	s3,8(sp)
    80002f72:	6a02                	ld	s4,0(sp)
    80002f74:	6145                	addi	sp,sp,48
    80002f76:	8082                	ret

0000000080002f78 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f78:	7179                	addi	sp,sp,-48
    80002f7a:	f406                	sd	ra,40(sp)
    80002f7c:	f022                	sd	s0,32(sp)
    80002f7e:	ec26                	sd	s1,24(sp)
    80002f80:	e84a                	sd	s2,16(sp)
    80002f82:	e44e                	sd	s3,8(sp)
    80002f84:	1800                	addi	s0,sp,48
    80002f86:	89aa                	mv	s3,a0
    80002f88:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f8a:	0001b517          	auipc	a0,0x1b
    80002f8e:	15e50513          	addi	a0,a0,350 # 8001e0e8 <bcache>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	c52080e7          	jalr	-942(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f9a:	00023497          	auipc	s1,0x23
    80002f9e:	4064b483          	ld	s1,1030(s1) # 800263a0 <bcache+0x82b8>
    80002fa2:	00023797          	auipc	a5,0x23
    80002fa6:	3ae78793          	addi	a5,a5,942 # 80026350 <bcache+0x8268>
    80002faa:	02f48f63          	beq	s1,a5,80002fe8 <bread+0x70>
    80002fae:	873e                	mv	a4,a5
    80002fb0:	a021                	j	80002fb8 <bread+0x40>
    80002fb2:	68a4                	ld	s1,80(s1)
    80002fb4:	02e48a63          	beq	s1,a4,80002fe8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fb8:	449c                	lw	a5,8(s1)
    80002fba:	ff379ce3          	bne	a5,s3,80002fb2 <bread+0x3a>
    80002fbe:	44dc                	lw	a5,12(s1)
    80002fc0:	ff2799e3          	bne	a5,s2,80002fb2 <bread+0x3a>
      b->refcnt++;
    80002fc4:	40bc                	lw	a5,64(s1)
    80002fc6:	2785                	addiw	a5,a5,1
    80002fc8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fca:	0001b517          	auipc	a0,0x1b
    80002fce:	11e50513          	addi	a0,a0,286 # 8001e0e8 <bcache>
    80002fd2:	ffffe097          	auipc	ra,0xffffe
    80002fd6:	cc6080e7          	jalr	-826(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fda:	01048513          	addi	a0,s1,16
    80002fde:	00001097          	auipc	ra,0x1
    80002fe2:	478080e7          	jalr	1144(ra) # 80004456 <acquiresleep>
      return b;
    80002fe6:	a8b9                	j	80003044 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe8:	00023497          	auipc	s1,0x23
    80002fec:	3b04b483          	ld	s1,944(s1) # 80026398 <bcache+0x82b0>
    80002ff0:	00023797          	auipc	a5,0x23
    80002ff4:	36078793          	addi	a5,a5,864 # 80026350 <bcache+0x8268>
    80002ff8:	00f48863          	beq	s1,a5,80003008 <bread+0x90>
    80002ffc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ffe:	40bc                	lw	a5,64(s1)
    80003000:	cf81                	beqz	a5,80003018 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003002:	64a4                	ld	s1,72(s1)
    80003004:	fee49de3          	bne	s1,a4,80002ffe <bread+0x86>
  panic("bget: no buffers");
    80003008:	00009517          	auipc	a0,0x9
    8000300c:	72850513          	addi	a0,a0,1832 # 8000c730 <syscalls+0xc8>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>
      b->dev = dev;
    80003018:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000301c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003020:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003024:	4785                	li	a5,1
    80003026:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003028:	0001b517          	auipc	a0,0x1b
    8000302c:	0c050513          	addi	a0,a0,192 # 8001e0e8 <bcache>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003038:	01048513          	addi	a0,s1,16
    8000303c:	00001097          	auipc	ra,0x1
    80003040:	41a080e7          	jalr	1050(ra) # 80004456 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003044:	409c                	lw	a5,0(s1)
    80003046:	cb89                	beqz	a5,80003058 <bread+0xe0>
    virtio_disk_rw(b, 0);

    b->valid = 1;
  }
  return b;
}
    80003048:	8526                	mv	a0,s1
    8000304a:	70a2                	ld	ra,40(sp)
    8000304c:	7402                	ld	s0,32(sp)
    8000304e:	64e2                	ld	s1,24(sp)
    80003050:	6942                	ld	s2,16(sp)
    80003052:	69a2                	ld	s3,8(sp)
    80003054:	6145                	addi	sp,sp,48
    80003056:	8082                	ret
    virtio_disk_rw(b, 0);
    80003058:	4581                	li	a1,0
    8000305a:	8526                	mv	a0,s1
    8000305c:	00003097          	auipc	ra,0x3
    80003060:	f8a080e7          	jalr	-118(ra) # 80005fe6 <virtio_disk_rw>
    b->valid = 1;
    80003064:	4785                	li	a5,1
    80003066:	c09c                	sw	a5,0(s1)
  return b;
    80003068:	b7c5                	j	80003048 <bread+0xd0>

000000008000306a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003076:	0541                	addi	a0,a0,16
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	478080e7          	jalr	1144(ra) # 800044f0 <holdingsleep>
    80003080:	cd01                	beqz	a0,80003098 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003082:	4585                	li	a1,1
    80003084:	8526                	mv	a0,s1
    80003086:	00003097          	auipc	ra,0x3
    8000308a:	f60080e7          	jalr	-160(ra) # 80005fe6 <virtio_disk_rw>
}
    8000308e:	60e2                	ld	ra,24(sp)
    80003090:	6442                	ld	s0,16(sp)
    80003092:	64a2                	ld	s1,8(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret
    panic("bwrite");
    80003098:	00009517          	auipc	a0,0x9
    8000309c:	6b050513          	addi	a0,a0,1712 # 8000c748 <syscalls+0xe0>
    800030a0:	ffffd097          	auipc	ra,0xffffd
    800030a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>

00000000800030a8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	e04a                	sd	s2,0(sp)
    800030b2:	1000                	addi	s0,sp,32
    800030b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b6:	01050913          	addi	s2,a0,16
    800030ba:	854a                	mv	a0,s2
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	434080e7          	jalr	1076(ra) # 800044f0 <holdingsleep>
    800030c4:	c92d                	beqz	a0,80003136 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c6:	854a                	mv	a0,s2
    800030c8:	00001097          	auipc	ra,0x1
    800030cc:	3e4080e7          	jalr	996(ra) # 800044ac <releasesleep>

  acquire(&bcache.lock);
    800030d0:	0001b517          	auipc	a0,0x1b
    800030d4:	01850513          	addi	a0,a0,24 # 8001e0e8 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	b0c080e7          	jalr	-1268(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030e0:	40bc                	lw	a5,64(s1)
    800030e2:	37fd                	addiw	a5,a5,-1
    800030e4:	0007871b          	sext.w	a4,a5
    800030e8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ea:	eb05                	bnez	a4,8000311a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ec:	68bc                	ld	a5,80(s1)
    800030ee:	64b8                	ld	a4,72(s1)
    800030f0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f2:	64bc                	ld	a5,72(s1)
    800030f4:	68b8                	ld	a4,80(s1)
    800030f6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030f8:	00023797          	auipc	a5,0x23
    800030fc:	ff078793          	addi	a5,a5,-16 # 800260e8 <bcache+0x8000>
    80003100:	2b87b703          	ld	a4,696(a5)
    80003104:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003106:	00023717          	auipc	a4,0x23
    8000310a:	24a70713          	addi	a4,a4,586 # 80026350 <bcache+0x8268>
    8000310e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003110:	2b87b703          	ld	a4,696(a5)
    80003114:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003116:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000311a:	0001b517          	auipc	a0,0x1b
    8000311e:	fce50513          	addi	a0,a0,-50 # 8001e0e8 <bcache>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	b76080e7          	jalr	-1162(ra) # 80000c98 <release>
}
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	64a2                	ld	s1,8(sp)
    80003130:	6902                	ld	s2,0(sp)
    80003132:	6105                	addi	sp,sp,32
    80003134:	8082                	ret
    panic("brelse");
    80003136:	00009517          	auipc	a0,0x9
    8000313a:	61a50513          	addi	a0,a0,1562 # 8000c750 <syscalls+0xe8>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	400080e7          	jalr	1024(ra) # 8000053e <panic>

0000000080003146 <bpin>:

void
bpin(struct buf *b) {
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	1000                	addi	s0,sp,32
    80003150:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003152:	0001b517          	auipc	a0,0x1b
    80003156:	f9650513          	addi	a0,a0,-106 # 8001e0e8 <bcache>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	a8a080e7          	jalr	-1398(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003162:	40bc                	lw	a5,64(s1)
    80003164:	2785                	addiw	a5,a5,1
    80003166:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003168:	0001b517          	auipc	a0,0x1b
    8000316c:	f8050513          	addi	a0,a0,-128 # 8001e0e8 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b28080e7          	jalr	-1240(ra) # 80000c98 <release>
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	64a2                	ld	s1,8(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <bunpin>:

void
bunpin(struct buf *b) {
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318e:	0001b517          	auipc	a0,0x1b
    80003192:	f5a50513          	addi	a0,a0,-166 # 8001e0e8 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a4e080e7          	jalr	-1458(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	37fd                	addiw	a5,a5,-1
    800031a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a4:	0001b517          	auipc	a0,0x1b
    800031a8:	f4450513          	addi	a0,a0,-188 # 8001e0e8 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	aec080e7          	jalr	-1300(ra) # 80000c98 <release>
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	e04a                	sd	s2,0(sp)
    800031c8:	1000                	addi	s0,sp,32
    800031ca:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031cc:	00d5d59b          	srliw	a1,a1,0xd
    800031d0:	00023797          	auipc	a5,0x23
    800031d4:	5f47a783          	lw	a5,1524(a5) # 800267c4 <sb+0x1c>
    800031d8:	9dbd                	addw	a1,a1,a5
    800031da:	00000097          	auipc	ra,0x0
    800031de:	d9e080e7          	jalr	-610(ra) # 80002f78 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e2:	0074f713          	andi	a4,s1,7
    800031e6:	4785                	li	a5,1
    800031e8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ec:	14ce                	slli	s1,s1,0x33
    800031ee:	90d9                	srli	s1,s1,0x36
    800031f0:	00950733          	add	a4,a0,s1
    800031f4:	05874703          	lbu	a4,88(a4)
    800031f8:	00e7f6b3          	and	a3,a5,a4
    800031fc:	c69d                	beqz	a3,8000322a <bfree+0x6c>
    800031fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003200:	94aa                	add	s1,s1,a0
    80003202:	fff7c793          	not	a5,a5
    80003206:	8ff9                	and	a5,a5,a4
    80003208:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	12a080e7          	jalr	298(ra) # 80004336 <log_write>
  brelse(bp);
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	e92080e7          	jalr	-366(ra) # 800030a8 <brelse>
}
    8000321e:	60e2                	ld	ra,24(sp)
    80003220:	6442                	ld	s0,16(sp)
    80003222:	64a2                	ld	s1,8(sp)
    80003224:	6902                	ld	s2,0(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret
    panic("freeing free block");
    8000322a:	00009517          	auipc	a0,0x9
    8000322e:	52e50513          	addi	a0,a0,1326 # 8000c758 <syscalls+0xf0>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	30c080e7          	jalr	780(ra) # 8000053e <panic>

000000008000323a <balloc>:
{
    8000323a:	711d                	addi	sp,sp,-96
    8000323c:	ec86                	sd	ra,88(sp)
    8000323e:	e8a2                	sd	s0,80(sp)
    80003240:	e4a6                	sd	s1,72(sp)
    80003242:	e0ca                	sd	s2,64(sp)
    80003244:	fc4e                	sd	s3,56(sp)
    80003246:	f852                	sd	s4,48(sp)
    80003248:	f456                	sd	s5,40(sp)
    8000324a:	f05a                	sd	s6,32(sp)
    8000324c:	ec5e                	sd	s7,24(sp)
    8000324e:	e862                	sd	s8,16(sp)
    80003250:	e466                	sd	s9,8(sp)
    80003252:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003254:	00023797          	auipc	a5,0x23
    80003258:	5587a783          	lw	a5,1368(a5) # 800267ac <sb+0x4>
    8000325c:	cbd1                	beqz	a5,800032f0 <balloc+0xb6>
    8000325e:	8baa                	mv	s7,a0
    80003260:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003262:	00023b17          	auipc	s6,0x23
    80003266:	546b0b13          	addi	s6,s6,1350 # 800267a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000326c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003270:	6c89                	lui	s9,0x2
    80003272:	a831                	j	8000328e <balloc+0x54>
    brelse(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	e32080e7          	jalr	-462(ra) # 800030a8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000327e:	015c87bb          	addw	a5,s9,s5
    80003282:	00078a9b          	sext.w	s5,a5
    80003286:	004b2703          	lw	a4,4(s6)
    8000328a:	06eaf363          	bgeu	s5,a4,800032f0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000328e:	41fad79b          	sraiw	a5,s5,0x1f
    80003292:	0137d79b          	srliw	a5,a5,0x13
    80003296:	015787bb          	addw	a5,a5,s5
    8000329a:	40d7d79b          	sraiw	a5,a5,0xd
    8000329e:	01cb2583          	lw	a1,28(s6)
    800032a2:	9dbd                	addw	a1,a1,a5
    800032a4:	855e                	mv	a0,s7
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	cd2080e7          	jalr	-814(ra) # 80002f78 <bread>
    800032ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b0:	004b2503          	lw	a0,4(s6)
    800032b4:	000a849b          	sext.w	s1,s5
    800032b8:	8662                	mv	a2,s8
    800032ba:	faa4fde3          	bgeu	s1,a0,80003274 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032be:	41f6579b          	sraiw	a5,a2,0x1f
    800032c2:	01d7d69b          	srliw	a3,a5,0x1d
    800032c6:	00c6873b          	addw	a4,a3,a2
    800032ca:	00777793          	andi	a5,a4,7
    800032ce:	9f95                	subw	a5,a5,a3
    800032d0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d4:	4037571b          	sraiw	a4,a4,0x3
    800032d8:	00e906b3          	add	a3,s2,a4
    800032dc:	0586c683          	lbu	a3,88(a3)
    800032e0:	00d7f5b3          	and	a1,a5,a3
    800032e4:	cd91                	beqz	a1,80003300 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e6:	2605                	addiw	a2,a2,1
    800032e8:	2485                	addiw	s1,s1,1
    800032ea:	fd4618e3          	bne	a2,s4,800032ba <balloc+0x80>
    800032ee:	b759                	j	80003274 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032f0:	00009517          	auipc	a0,0x9
    800032f4:	48050513          	addi	a0,a0,1152 # 8000c770 <syscalls+0x108>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	246080e7          	jalr	582(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003300:	974a                	add	a4,a4,s2
    80003302:	8fd5                	or	a5,a5,a3
    80003304:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003308:	854a                	mv	a0,s2
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	02c080e7          	jalr	44(ra) # 80004336 <log_write>
        brelse(bp);
    80003312:	854a                	mv	a0,s2
    80003314:	00000097          	auipc	ra,0x0
    80003318:	d94080e7          	jalr	-620(ra) # 800030a8 <brelse>
  bp = bread(dev, bno);
    8000331c:	85a6                	mv	a1,s1
    8000331e:	855e                	mv	a0,s7
    80003320:	00000097          	auipc	ra,0x0
    80003324:	c58080e7          	jalr	-936(ra) # 80002f78 <bread>
    80003328:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000332a:	40000613          	li	a2,1024
    8000332e:	4581                	li	a1,0
    80003330:	05850513          	addi	a0,a0,88
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	9ac080e7          	jalr	-1620(ra) # 80000ce0 <memset>
  log_write(bp);
    8000333c:	854a                	mv	a0,s2
    8000333e:	00001097          	auipc	ra,0x1
    80003342:	ff8080e7          	jalr	-8(ra) # 80004336 <log_write>
  brelse(bp);
    80003346:	854a                	mv	a0,s2
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	d60080e7          	jalr	-672(ra) # 800030a8 <brelse>
}
    80003350:	8526                	mv	a0,s1
    80003352:	60e6                	ld	ra,88(sp)
    80003354:	6446                	ld	s0,80(sp)
    80003356:	64a6                	ld	s1,72(sp)
    80003358:	6906                	ld	s2,64(sp)
    8000335a:	79e2                	ld	s3,56(sp)
    8000335c:	7a42                	ld	s4,48(sp)
    8000335e:	7aa2                	ld	s5,40(sp)
    80003360:	7b02                	ld	s6,32(sp)
    80003362:	6be2                	ld	s7,24(sp)
    80003364:	6c42                	ld	s8,16(sp)
    80003366:	6ca2                	ld	s9,8(sp)
    80003368:	6125                	addi	sp,sp,96
    8000336a:	8082                	ret

000000008000336c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000336c:	7179                	addi	sp,sp,-48
    8000336e:	f406                	sd	ra,40(sp)
    80003370:	f022                	sd	s0,32(sp)
    80003372:	ec26                	sd	s1,24(sp)
    80003374:	e84a                	sd	s2,16(sp)
    80003376:	e44e                	sd	s3,8(sp)
    80003378:	e052                	sd	s4,0(sp)
    8000337a:	1800                	addi	s0,sp,48
    8000337c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000337e:	47ad                	li	a5,11
    80003380:	04b7fe63          	bgeu	a5,a1,800033dc <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003384:	ff45849b          	addiw	s1,a1,-12
    80003388:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000338c:	0ff00793          	li	a5,255
    80003390:	0ae7e363          	bltu	a5,a4,80003436 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003394:	08052583          	lw	a1,128(a0)
    80003398:	c5ad                	beqz	a1,80003402 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000339a:	00092503          	lw	a0,0(s2)
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	bda080e7          	jalr	-1062(ra) # 80002f78 <bread>
    800033a6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033a8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ac:	02049593          	slli	a1,s1,0x20
    800033b0:	9181                	srli	a1,a1,0x20
    800033b2:	058a                	slli	a1,a1,0x2
    800033b4:	00b784b3          	add	s1,a5,a1
    800033b8:	0004a983          	lw	s3,0(s1)
    800033bc:	04098d63          	beqz	s3,80003416 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033c0:	8552                	mv	a0,s4
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	ce6080e7          	jalr	-794(ra) # 800030a8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ca:	854e                	mv	a0,s3
    800033cc:	70a2                	ld	ra,40(sp)
    800033ce:	7402                	ld	s0,32(sp)
    800033d0:	64e2                	ld	s1,24(sp)
    800033d2:	6942                	ld	s2,16(sp)
    800033d4:	69a2                	ld	s3,8(sp)
    800033d6:	6a02                	ld	s4,0(sp)
    800033d8:	6145                	addi	sp,sp,48
    800033da:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033dc:	02059493          	slli	s1,a1,0x20
    800033e0:	9081                	srli	s1,s1,0x20
    800033e2:	048a                	slli	s1,s1,0x2
    800033e4:	94aa                	add	s1,s1,a0
    800033e6:	0504a983          	lw	s3,80(s1)
    800033ea:	fe0990e3          	bnez	s3,800033ca <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ee:	4108                	lw	a0,0(a0)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e4a080e7          	jalr	-438(ra) # 8000323a <balloc>
    800033f8:	0005099b          	sext.w	s3,a0
    800033fc:	0534a823          	sw	s3,80(s1)
    80003400:	b7e9                	j	800033ca <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003402:	4108                	lw	a0,0(a0)
    80003404:	00000097          	auipc	ra,0x0
    80003408:	e36080e7          	jalr	-458(ra) # 8000323a <balloc>
    8000340c:	0005059b          	sext.w	a1,a0
    80003410:	08b92023          	sw	a1,128(s2)
    80003414:	b759                	j	8000339a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003416:	00092503          	lw	a0,0(s2)
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	e20080e7          	jalr	-480(ra) # 8000323a <balloc>
    80003422:	0005099b          	sext.w	s3,a0
    80003426:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000342a:	8552                	mv	a0,s4
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	f0a080e7          	jalr	-246(ra) # 80004336 <log_write>
    80003434:	b771                	j	800033c0 <bmap+0x54>
  panic("bmap: out of range");
    80003436:	00009517          	auipc	a0,0x9
    8000343a:	35250513          	addi	a0,a0,850 # 8000c788 <syscalls+0x120>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	100080e7          	jalr	256(ra) # 8000053e <panic>

0000000080003446 <iget>:
{
    80003446:	7179                	addi	sp,sp,-48
    80003448:	f406                	sd	ra,40(sp)
    8000344a:	f022                	sd	s0,32(sp)
    8000344c:	ec26                	sd	s1,24(sp)
    8000344e:	e84a                	sd	s2,16(sp)
    80003450:	e44e                	sd	s3,8(sp)
    80003452:	e052                	sd	s4,0(sp)
    80003454:	1800                	addi	s0,sp,48
    80003456:	89aa                	mv	s3,a0
    80003458:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000345a:	00023517          	auipc	a0,0x23
    8000345e:	36e50513          	addi	a0,a0,878 # 800267c8 <itable>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	782080e7          	jalr	1922(ra) # 80000be4 <acquire>
  empty = 0;
    8000346a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346c:	00023497          	auipc	s1,0x23
    80003470:	37448493          	addi	s1,s1,884 # 800267e0 <itable+0x18>
    80003474:	00025697          	auipc	a3,0x25
    80003478:	dfc68693          	addi	a3,a3,-516 # 80028270 <log>
    8000347c:	a039                	j	8000348a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000347e:	02090b63          	beqz	s2,800034b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003482:	08848493          	addi	s1,s1,136
    80003486:	02d48a63          	beq	s1,a3,800034ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348a:	449c                	lw	a5,8(s1)
    8000348c:	fef059e3          	blez	a5,8000347e <iget+0x38>
    80003490:	4098                	lw	a4,0(s1)
    80003492:	ff3716e3          	bne	a4,s3,8000347e <iget+0x38>
    80003496:	40d8                	lw	a4,4(s1)
    80003498:	ff4713e3          	bne	a4,s4,8000347e <iget+0x38>
      ip->ref++;
    8000349c:	2785                	addiw	a5,a5,1
    8000349e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034a0:	00023517          	auipc	a0,0x23
    800034a4:	32850513          	addi	a0,a0,808 # 800267c8 <itable>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	7f0080e7          	jalr	2032(ra) # 80000c98 <release>
      return ip;
    800034b0:	8926                	mv	s2,s1
    800034b2:	a03d                	j	800034e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b4:	f7f9                	bnez	a5,80003482 <iget+0x3c>
    800034b6:	8926                	mv	s2,s1
    800034b8:	b7e9                	j	80003482 <iget+0x3c>
  if(empty == 0)
    800034ba:	02090c63          	beqz	s2,800034f2 <iget+0xac>
  ip->dev = dev;
    800034be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c6:	4785                	li	a5,1
    800034c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034d0:	00023517          	auipc	a0,0x23
    800034d4:	2f850513          	addi	a0,a0,760 # 800267c8 <itable>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7c0080e7          	jalr	1984(ra) # 80000c98 <release>
}
    800034e0:	854a                	mv	a0,s2
    800034e2:	70a2                	ld	ra,40(sp)
    800034e4:	7402                	ld	s0,32(sp)
    800034e6:	64e2                	ld	s1,24(sp)
    800034e8:	6942                	ld	s2,16(sp)
    800034ea:	69a2                	ld	s3,8(sp)
    800034ec:	6a02                	ld	s4,0(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    panic("iget: no inodes");
    800034f2:	00009517          	auipc	a0,0x9
    800034f6:	2ae50513          	addi	a0,a0,686 # 8000c7a0 <syscalls+0x138>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	044080e7          	jalr	68(ra) # 8000053e <panic>

0000000080003502 <fsinit>:
fsinit(int dev) {
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	1800                	addi	s0,sp,48
    80003510:	892a                	mv	s2,a0
  printf("fsinit \n");
    80003512:	00009517          	auipc	a0,0x9
    80003516:	29e50513          	addi	a0,a0,670 # 8000c7b0 <syscalls+0x148>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	06e080e7          	jalr	110(ra) # 80000588 <printf>
  bp = bread(dev, 1);
    80003522:	4585                	li	a1,1
    80003524:	854a                	mv	a0,s2
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	a52080e7          	jalr	-1454(ra) # 80002f78 <bread>
    8000352e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003530:	00023997          	auipc	s3,0x23
    80003534:	27898993          	addi	s3,s3,632 # 800267a8 <sb>
    80003538:	02000613          	li	a2,32
    8000353c:	05850593          	addi	a1,a0,88
    80003540:	854e                	mv	a0,s3
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	7fe080e7          	jalr	2046(ra) # 80000d40 <memmove>
  brelse(bp);
    8000354a:	8526                	mv	a0,s1
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	b5c080e7          	jalr	-1188(ra) # 800030a8 <brelse>
  if(sb.magic != FSMAGIC)
    80003554:	0009a703          	lw	a4,0(s3)
    80003558:	102037b7          	lui	a5,0x10203
    8000355c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003560:	02f71263          	bne	a4,a5,80003584 <fsinit+0x82>
  initlog(dev, &sb);
    80003564:	00023597          	auipc	a1,0x23
    80003568:	24458593          	addi	a1,a1,580 # 800267a8 <sb>
    8000356c:	854a                	mv	a0,s2
    8000356e:	00001097          	auipc	ra,0x1
    80003572:	b4c080e7          	jalr	-1204(ra) # 800040ba <initlog>
}
    80003576:	70a2                	ld	ra,40(sp)
    80003578:	7402                	ld	s0,32(sp)
    8000357a:	64e2                	ld	s1,24(sp)
    8000357c:	6942                	ld	s2,16(sp)
    8000357e:	69a2                	ld	s3,8(sp)
    80003580:	6145                	addi	sp,sp,48
    80003582:	8082                	ret
    panic("invalid file system");
    80003584:	00009517          	auipc	a0,0x9
    80003588:	23c50513          	addi	a0,a0,572 # 8000c7c0 <syscalls+0x158>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>

0000000080003594 <iinit>:
{
    80003594:	7179                	addi	sp,sp,-48
    80003596:	f406                	sd	ra,40(sp)
    80003598:	f022                	sd	s0,32(sp)
    8000359a:	ec26                	sd	s1,24(sp)
    8000359c:	e84a                	sd	s2,16(sp)
    8000359e:	e44e                	sd	s3,8(sp)
    800035a0:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035a2:	00009597          	auipc	a1,0x9
    800035a6:	23658593          	addi	a1,a1,566 # 8000c7d8 <syscalls+0x170>
    800035aa:	00023517          	auipc	a0,0x23
    800035ae:	21e50513          	addi	a0,a0,542 # 800267c8 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	5a2080e7          	jalr	1442(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ba:	00023497          	auipc	s1,0x23
    800035be:	23648493          	addi	s1,s1,566 # 800267f0 <itable+0x28>
    800035c2:	00025997          	auipc	s3,0x25
    800035c6:	cbe98993          	addi	s3,s3,-834 # 80028280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ca:	00009917          	auipc	s2,0x9
    800035ce:	21690913          	addi	s2,s2,534 # 8000c7e0 <syscalls+0x178>
    800035d2:	85ca                	mv	a1,s2
    800035d4:	8526                	mv	a0,s1
    800035d6:	00001097          	auipc	ra,0x1
    800035da:	e46080e7          	jalr	-442(ra) # 8000441c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035de:	08848493          	addi	s1,s1,136
    800035e2:	ff3498e3          	bne	s1,s3,800035d2 <iinit+0x3e>
}
    800035e6:	70a2                	ld	ra,40(sp)
    800035e8:	7402                	ld	s0,32(sp)
    800035ea:	64e2                	ld	s1,24(sp)
    800035ec:	6942                	ld	s2,16(sp)
    800035ee:	69a2                	ld	s3,8(sp)
    800035f0:	6145                	addi	sp,sp,48
    800035f2:	8082                	ret

00000000800035f4 <ialloc>:
{
    800035f4:	715d                	addi	sp,sp,-80
    800035f6:	e486                	sd	ra,72(sp)
    800035f8:	e0a2                	sd	s0,64(sp)
    800035fa:	fc26                	sd	s1,56(sp)
    800035fc:	f84a                	sd	s2,48(sp)
    800035fe:	f44e                	sd	s3,40(sp)
    80003600:	f052                	sd	s4,32(sp)
    80003602:	ec56                	sd	s5,24(sp)
    80003604:	e85a                	sd	s6,16(sp)
    80003606:	e45e                	sd	s7,8(sp)
    80003608:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360a:	00023717          	auipc	a4,0x23
    8000360e:	1aa72703          	lw	a4,426(a4) # 800267b4 <sb+0xc>
    80003612:	4785                	li	a5,1
    80003614:	04e7fa63          	bgeu	a5,a4,80003668 <ialloc+0x74>
    80003618:	8aaa                	mv	s5,a0
    8000361a:	8bae                	mv	s7,a1
    8000361c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000361e:	00023a17          	auipc	s4,0x23
    80003622:	18aa0a13          	addi	s4,s4,394 # 800267a8 <sb>
    80003626:	00048b1b          	sext.w	s6,s1
    8000362a:	0044d593          	srli	a1,s1,0x4
    8000362e:	018a2783          	lw	a5,24(s4)
    80003632:	9dbd                	addw	a1,a1,a5
    80003634:	8556                	mv	a0,s5
    80003636:	00000097          	auipc	ra,0x0
    8000363a:	942080e7          	jalr	-1726(ra) # 80002f78 <bread>
    8000363e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003640:	05850993          	addi	s3,a0,88
    80003644:	00f4f793          	andi	a5,s1,15
    80003648:	079a                	slli	a5,a5,0x6
    8000364a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000364c:	00099783          	lh	a5,0(s3)
    80003650:	c785                	beqz	a5,80003678 <ialloc+0x84>
    brelse(bp);
    80003652:	00000097          	auipc	ra,0x0
    80003656:	a56080e7          	jalr	-1450(ra) # 800030a8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365a:	0485                	addi	s1,s1,1
    8000365c:	00ca2703          	lw	a4,12(s4)
    80003660:	0004879b          	sext.w	a5,s1
    80003664:	fce7e1e3          	bltu	a5,a4,80003626 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003668:	00009517          	auipc	a0,0x9
    8000366c:	18050513          	addi	a0,a0,384 # 8000c7e8 <syscalls+0x180>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003678:	04000613          	li	a2,64
    8000367c:	4581                	li	a1,0
    8000367e:	854e                	mv	a0,s3
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	660080e7          	jalr	1632(ra) # 80000ce0 <memset>
      dip->type = type;
    80003688:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000368c:	854a                	mv	a0,s2
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	ca8080e7          	jalr	-856(ra) # 80004336 <log_write>
      brelse(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	a10080e7          	jalr	-1520(ra) # 800030a8 <brelse>
      return iget(dev, inum);
    800036a0:	85da                	mv	a1,s6
    800036a2:	8556                	mv	a0,s5
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	da2080e7          	jalr	-606(ra) # 80003446 <iget>
}
    800036ac:	60a6                	ld	ra,72(sp)
    800036ae:	6406                	ld	s0,64(sp)
    800036b0:	74e2                	ld	s1,56(sp)
    800036b2:	7942                	ld	s2,48(sp)
    800036b4:	79a2                	ld	s3,40(sp)
    800036b6:	7a02                	ld	s4,32(sp)
    800036b8:	6ae2                	ld	s5,24(sp)
    800036ba:	6b42                	ld	s6,16(sp)
    800036bc:	6ba2                	ld	s7,8(sp)
    800036be:	6161                	addi	sp,sp,80
    800036c0:	8082                	ret

00000000800036c2 <iupdate>:
{
    800036c2:	1101                	addi	sp,sp,-32
    800036c4:	ec06                	sd	ra,24(sp)
    800036c6:	e822                	sd	s0,16(sp)
    800036c8:	e426                	sd	s1,8(sp)
    800036ca:	e04a                	sd	s2,0(sp)
    800036cc:	1000                	addi	s0,sp,32
    800036ce:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d0:	415c                	lw	a5,4(a0)
    800036d2:	0047d79b          	srliw	a5,a5,0x4
    800036d6:	00023597          	auipc	a1,0x23
    800036da:	0ea5a583          	lw	a1,234(a1) # 800267c0 <sb+0x18>
    800036de:	9dbd                	addw	a1,a1,a5
    800036e0:	4108                	lw	a0,0(a0)
    800036e2:	00000097          	auipc	ra,0x0
    800036e6:	896080e7          	jalr	-1898(ra) # 80002f78 <bread>
    800036ea:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ec:	05850793          	addi	a5,a0,88
    800036f0:	40c8                	lw	a0,4(s1)
    800036f2:	893d                	andi	a0,a0,15
    800036f4:	051a                	slli	a0,a0,0x6
    800036f6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036f8:	04449703          	lh	a4,68(s1)
    800036fc:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003700:	04649703          	lh	a4,70(s1)
    80003704:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003708:	04849703          	lh	a4,72(s1)
    8000370c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003710:	04a49703          	lh	a4,74(s1)
    80003714:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003718:	44f8                	lw	a4,76(s1)
    8000371a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000371c:	03400613          	li	a2,52
    80003720:	05048593          	addi	a1,s1,80
    80003724:	0531                	addi	a0,a0,12
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	61a080e7          	jalr	1562(ra) # 80000d40 <memmove>
  log_write(bp);
    8000372e:	854a                	mv	a0,s2
    80003730:	00001097          	auipc	ra,0x1
    80003734:	c06080e7          	jalr	-1018(ra) # 80004336 <log_write>
  brelse(bp);
    80003738:	854a                	mv	a0,s2
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	96e080e7          	jalr	-1682(ra) # 800030a8 <brelse>
}
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	64a2                	ld	s1,8(sp)
    80003748:	6902                	ld	s2,0(sp)
    8000374a:	6105                	addi	sp,sp,32
    8000374c:	8082                	ret

000000008000374e <idup>:
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	e426                	sd	s1,8(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000375a:	00023517          	auipc	a0,0x23
    8000375e:	06e50513          	addi	a0,a0,110 # 800267c8 <itable>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	482080e7          	jalr	1154(ra) # 80000be4 <acquire>
  ip->ref++;
    8000376a:	449c                	lw	a5,8(s1)
    8000376c:	2785                	addiw	a5,a5,1
    8000376e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003770:	00023517          	auipc	a0,0x23
    80003774:	05850513          	addi	a0,a0,88 # 800267c8 <itable>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	520080e7          	jalr	1312(ra) # 80000c98 <release>
}
    80003780:	8526                	mv	a0,s1
    80003782:	60e2                	ld	ra,24(sp)
    80003784:	6442                	ld	s0,16(sp)
    80003786:	64a2                	ld	s1,8(sp)
    80003788:	6105                	addi	sp,sp,32
    8000378a:	8082                	ret

000000008000378c <ilock>:
{
    8000378c:	1101                	addi	sp,sp,-32
    8000378e:	ec06                	sd	ra,24(sp)
    80003790:	e822                	sd	s0,16(sp)
    80003792:	e426                	sd	s1,8(sp)
    80003794:	e04a                	sd	s2,0(sp)
    80003796:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003798:	c115                	beqz	a0,800037bc <ilock+0x30>
    8000379a:	84aa                	mv	s1,a0
    8000379c:	451c                	lw	a5,8(a0)
    8000379e:	00f05f63          	blez	a5,800037bc <ilock+0x30>
  acquiresleep(&ip->lock);
    800037a2:	0541                	addi	a0,a0,16
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	cb2080e7          	jalr	-846(ra) # 80004456 <acquiresleep>
  if(ip->valid == 0){
    800037ac:	40bc                	lw	a5,64(s1)
    800037ae:	cf99                	beqz	a5,800037cc <ilock+0x40>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6902                	ld	s2,0(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret
    panic("ilock");
    800037bc:	00009517          	auipc	a0,0x9
    800037c0:	04450513          	addi	a0,a0,68 # 8000c800 <syscalls+0x198>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d7a080e7          	jalr	-646(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037cc:	40dc                	lw	a5,4(s1)
    800037ce:	0047d79b          	srliw	a5,a5,0x4
    800037d2:	00023597          	auipc	a1,0x23
    800037d6:	fee5a583          	lw	a1,-18(a1) # 800267c0 <sb+0x18>
    800037da:	9dbd                	addw	a1,a1,a5
    800037dc:	4088                	lw	a0,0(s1)
    800037de:	fffff097          	auipc	ra,0xfffff
    800037e2:	79a080e7          	jalr	1946(ra) # 80002f78 <bread>
    800037e6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e8:	05850593          	addi	a1,a0,88
    800037ec:	40dc                	lw	a5,4(s1)
    800037ee:	8bbd                	andi	a5,a5,15
    800037f0:	079a                	slli	a5,a5,0x6
    800037f2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037f4:	00059783          	lh	a5,0(a1)
    800037f8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037fc:	00259783          	lh	a5,2(a1)
    80003800:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003804:	00459783          	lh	a5,4(a1)
    80003808:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000380c:	00659783          	lh	a5,6(a1)
    80003810:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003814:	459c                	lw	a5,8(a1)
    80003816:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003818:	03400613          	li	a2,52
    8000381c:	05b1                	addi	a1,a1,12
    8000381e:	05048513          	addi	a0,s1,80
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	51e080e7          	jalr	1310(ra) # 80000d40 <memmove>
    brelse(bp);
    8000382a:	854a                	mv	a0,s2
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	87c080e7          	jalr	-1924(ra) # 800030a8 <brelse>
    ip->valid = 1;
    80003834:	4785                	li	a5,1
    80003836:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003838:	04449783          	lh	a5,68(s1)
    8000383c:	fbb5                	bnez	a5,800037b0 <ilock+0x24>
      panic("ilock: no type");
    8000383e:	00009517          	auipc	a0,0x9
    80003842:	fca50513          	addi	a0,a0,-54 # 8000c808 <syscalls+0x1a0>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	cf8080e7          	jalr	-776(ra) # 8000053e <panic>

000000008000384e <iunlock>:
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	e04a                	sd	s2,0(sp)
    80003858:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000385a:	c905                	beqz	a0,8000388a <iunlock+0x3c>
    8000385c:	84aa                	mv	s1,a0
    8000385e:	01050913          	addi	s2,a0,16
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	c8c080e7          	jalr	-884(ra) # 800044f0 <holdingsleep>
    8000386c:	cd19                	beqz	a0,8000388a <iunlock+0x3c>
    8000386e:	449c                	lw	a5,8(s1)
    80003870:	00f05d63          	blez	a5,8000388a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003874:	854a                	mv	a0,s2
    80003876:	00001097          	auipc	ra,0x1
    8000387a:	c36080e7          	jalr	-970(ra) # 800044ac <releasesleep>
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6902                	ld	s2,0(sp)
    80003886:	6105                	addi	sp,sp,32
    80003888:	8082                	ret
    panic("iunlock");
    8000388a:	00009517          	auipc	a0,0x9
    8000388e:	f8e50513          	addi	a0,a0,-114 # 8000c818 <syscalls+0x1b0>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	cac080e7          	jalr	-852(ra) # 8000053e <panic>

000000008000389a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000389a:	7179                	addi	sp,sp,-48
    8000389c:	f406                	sd	ra,40(sp)
    8000389e:	f022                	sd	s0,32(sp)
    800038a0:	ec26                	sd	s1,24(sp)
    800038a2:	e84a                	sd	s2,16(sp)
    800038a4:	e44e                	sd	s3,8(sp)
    800038a6:	e052                	sd	s4,0(sp)
    800038a8:	1800                	addi	s0,sp,48
    800038aa:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ac:	05050493          	addi	s1,a0,80
    800038b0:	08050913          	addi	s2,a0,128
    800038b4:	a021                	j	800038bc <itrunc+0x22>
    800038b6:	0491                	addi	s1,s1,4
    800038b8:	01248d63          	beq	s1,s2,800038d2 <itrunc+0x38>
    if(ip->addrs[i]){
    800038bc:	408c                	lw	a1,0(s1)
    800038be:	dde5                	beqz	a1,800038b6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038c0:	0009a503          	lw	a0,0(s3)
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	8fa080e7          	jalr	-1798(ra) # 800031be <bfree>
      ip->addrs[i] = 0;
    800038cc:	0004a023          	sw	zero,0(s1)
    800038d0:	b7dd                	j	800038b6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038d2:	0809a583          	lw	a1,128(s3)
    800038d6:	e185                	bnez	a1,800038f6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038d8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038dc:	854e                	mv	a0,s3
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	de4080e7          	jalr	-540(ra) # 800036c2 <iupdate>
}
    800038e6:	70a2                	ld	ra,40(sp)
    800038e8:	7402                	ld	s0,32(sp)
    800038ea:	64e2                	ld	s1,24(sp)
    800038ec:	6942                	ld	s2,16(sp)
    800038ee:	69a2                	ld	s3,8(sp)
    800038f0:	6a02                	ld	s4,0(sp)
    800038f2:	6145                	addi	sp,sp,48
    800038f4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038f6:	0009a503          	lw	a0,0(s3)
    800038fa:	fffff097          	auipc	ra,0xfffff
    800038fe:	67e080e7          	jalr	1662(ra) # 80002f78 <bread>
    80003902:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003904:	05850493          	addi	s1,a0,88
    80003908:	45850913          	addi	s2,a0,1112
    8000390c:	a811                	j	80003920 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000390e:	0009a503          	lw	a0,0(s3)
    80003912:	00000097          	auipc	ra,0x0
    80003916:	8ac080e7          	jalr	-1876(ra) # 800031be <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000391a:	0491                	addi	s1,s1,4
    8000391c:	01248563          	beq	s1,s2,80003926 <itrunc+0x8c>
      if(a[j])
    80003920:	408c                	lw	a1,0(s1)
    80003922:	dde5                	beqz	a1,8000391a <itrunc+0x80>
    80003924:	b7ed                	j	8000390e <itrunc+0x74>
    brelse(bp);
    80003926:	8552                	mv	a0,s4
    80003928:	fffff097          	auipc	ra,0xfffff
    8000392c:	780080e7          	jalr	1920(ra) # 800030a8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003930:	0809a583          	lw	a1,128(s3)
    80003934:	0009a503          	lw	a0,0(s3)
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	886080e7          	jalr	-1914(ra) # 800031be <bfree>
    ip->addrs[NDIRECT] = 0;
    80003940:	0809a023          	sw	zero,128(s3)
    80003944:	bf51                	j	800038d8 <itrunc+0x3e>

0000000080003946 <iput>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	e04a                	sd	s2,0(sp)
    80003950:	1000                	addi	s0,sp,32
    80003952:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003954:	00023517          	auipc	a0,0x23
    80003958:	e7450513          	addi	a0,a0,-396 # 800267c8 <itable>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	288080e7          	jalr	648(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003964:	4498                	lw	a4,8(s1)
    80003966:	4785                	li	a5,1
    80003968:	02f70363          	beq	a4,a5,8000398e <iput+0x48>
  ip->ref--;
    8000396c:	449c                	lw	a5,8(s1)
    8000396e:	37fd                	addiw	a5,a5,-1
    80003970:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003972:	00023517          	auipc	a0,0x23
    80003976:	e5650513          	addi	a0,a0,-426 # 800267c8 <itable>
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	31e080e7          	jalr	798(ra) # 80000c98 <release>
}
    80003982:	60e2                	ld	ra,24(sp)
    80003984:	6442                	ld	s0,16(sp)
    80003986:	64a2                	ld	s1,8(sp)
    80003988:	6902                	ld	s2,0(sp)
    8000398a:	6105                	addi	sp,sp,32
    8000398c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398e:	40bc                	lw	a5,64(s1)
    80003990:	dff1                	beqz	a5,8000396c <iput+0x26>
    80003992:	04a49783          	lh	a5,74(s1)
    80003996:	fbf9                	bnez	a5,8000396c <iput+0x26>
    acquiresleep(&ip->lock);
    80003998:	01048913          	addi	s2,s1,16
    8000399c:	854a                	mv	a0,s2
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	ab8080e7          	jalr	-1352(ra) # 80004456 <acquiresleep>
    release(&itable.lock);
    800039a6:	00023517          	auipc	a0,0x23
    800039aa:	e2250513          	addi	a0,a0,-478 # 800267c8 <itable>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	2ea080e7          	jalr	746(ra) # 80000c98 <release>
    itrunc(ip);
    800039b6:	8526                	mv	a0,s1
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	ee2080e7          	jalr	-286(ra) # 8000389a <itrunc>
    ip->type = 0;
    800039c0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039c4:	8526                	mv	a0,s1
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	cfc080e7          	jalr	-772(ra) # 800036c2 <iupdate>
    ip->valid = 0;
    800039ce:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	ad8080e7          	jalr	-1320(ra) # 800044ac <releasesleep>
    acquire(&itable.lock);
    800039dc:	00023517          	auipc	a0,0x23
    800039e0:	dec50513          	addi	a0,a0,-532 # 800267c8 <itable>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	200080e7          	jalr	512(ra) # 80000be4 <acquire>
    800039ec:	b741                	j	8000396c <iput+0x26>

00000000800039ee <iunlockput>:
{
    800039ee:	1101                	addi	sp,sp,-32
    800039f0:	ec06                	sd	ra,24(sp)
    800039f2:	e822                	sd	s0,16(sp)
    800039f4:	e426                	sd	s1,8(sp)
    800039f6:	1000                	addi	s0,sp,32
    800039f8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e54080e7          	jalr	-428(ra) # 8000384e <iunlock>
  iput(ip);
    80003a02:	8526                	mv	a0,s1
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	f42080e7          	jalr	-190(ra) # 80003946 <iput>
}
    80003a0c:	60e2                	ld	ra,24(sp)
    80003a0e:	6442                	ld	s0,16(sp)
    80003a10:	64a2                	ld	s1,8(sp)
    80003a12:	6105                	addi	sp,sp,32
    80003a14:	8082                	ret

0000000080003a16 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a16:	1141                	addi	sp,sp,-16
    80003a18:	e422                	sd	s0,8(sp)
    80003a1a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a1c:	411c                	lw	a5,0(a0)
    80003a1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a20:	415c                	lw	a5,4(a0)
    80003a22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a24:	04451783          	lh	a5,68(a0)
    80003a28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a2c:	04a51783          	lh	a5,74(a0)
    80003a30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a34:	04c56783          	lwu	a5,76(a0)
    80003a38:	e99c                	sd	a5,16(a1)
}
    80003a3a:	6422                	ld	s0,8(sp)
    80003a3c:	0141                	addi	sp,sp,16
    80003a3e:	8082                	ret

0000000080003a40 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a40:	457c                	lw	a5,76(a0)
    80003a42:	0ed7e963          	bltu	a5,a3,80003b34 <readi+0xf4>
{
    80003a46:	7159                	addi	sp,sp,-112
    80003a48:	f486                	sd	ra,104(sp)
    80003a4a:	f0a2                	sd	s0,96(sp)
    80003a4c:	eca6                	sd	s1,88(sp)
    80003a4e:	e8ca                	sd	s2,80(sp)
    80003a50:	e4ce                	sd	s3,72(sp)
    80003a52:	e0d2                	sd	s4,64(sp)
    80003a54:	fc56                	sd	s5,56(sp)
    80003a56:	f85a                	sd	s6,48(sp)
    80003a58:	f45e                	sd	s7,40(sp)
    80003a5a:	f062                	sd	s8,32(sp)
    80003a5c:	ec66                	sd	s9,24(sp)
    80003a5e:	e86a                	sd	s10,16(sp)
    80003a60:	e46e                	sd	s11,8(sp)
    80003a62:	1880                	addi	s0,sp,112
    80003a64:	8baa                	mv	s7,a0
    80003a66:	8c2e                	mv	s8,a1
    80003a68:	8ab2                	mv	s5,a2
    80003a6a:	84b6                	mv	s1,a3
    80003a6c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a6e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a70:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a72:	0ad76063          	bltu	a4,a3,80003b12 <readi+0xd2>
  if(off + n > ip->size)
    80003a76:	00e7f463          	bgeu	a5,a4,80003a7e <readi+0x3e>
    n = ip->size - off;
    80003a7a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a7e:	0a0b0963          	beqz	s6,80003b30 <readi+0xf0>
    80003a82:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a84:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a88:	5cfd                	li	s9,-1
    80003a8a:	a82d                	j	80003ac4 <readi+0x84>
    80003a8c:	020a1d93          	slli	s11,s4,0x20
    80003a90:	020ddd93          	srli	s11,s11,0x20
    80003a94:	05890613          	addi	a2,s2,88
    80003a98:	86ee                	mv	a3,s11
    80003a9a:	963a                	add	a2,a2,a4
    80003a9c:	85d6                	mv	a1,s5
    80003a9e:	8562                	mv	a0,s8
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	b00080e7          	jalr	-1280(ra) # 800025a0 <either_copyout>
    80003aa8:	05950d63          	beq	a0,s9,80003b02 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	5fa080e7          	jalr	1530(ra) # 800030a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab6:	013a09bb          	addw	s3,s4,s3
    80003aba:	009a04bb          	addw	s1,s4,s1
    80003abe:	9aee                	add	s5,s5,s11
    80003ac0:	0569f763          	bgeu	s3,s6,80003b0e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ac4:	000ba903          	lw	s2,0(s7)
    80003ac8:	00a4d59b          	srliw	a1,s1,0xa
    80003acc:	855e                	mv	a0,s7
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	89e080e7          	jalr	-1890(ra) # 8000336c <bmap>
    80003ad6:	0005059b          	sext.w	a1,a0
    80003ada:	854a                	mv	a0,s2
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	49c080e7          	jalr	1180(ra) # 80002f78 <bread>
    80003ae4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae6:	3ff4f713          	andi	a4,s1,1023
    80003aea:	40ed07bb          	subw	a5,s10,a4
    80003aee:	413b06bb          	subw	a3,s6,s3
    80003af2:	8a3e                	mv	s4,a5
    80003af4:	2781                	sext.w	a5,a5
    80003af6:	0006861b          	sext.w	a2,a3
    80003afa:	f8f679e3          	bgeu	a2,a5,80003a8c <readi+0x4c>
    80003afe:	8a36                	mv	s4,a3
    80003b00:	b771                	j	80003a8c <readi+0x4c>
      brelse(bp);
    80003b02:	854a                	mv	a0,s2
    80003b04:	fffff097          	auipc	ra,0xfffff
    80003b08:	5a4080e7          	jalr	1444(ra) # 800030a8 <brelse>
      tot = -1;
    80003b0c:	59fd                	li	s3,-1
  }
  return tot;
    80003b0e:	0009851b          	sext.w	a0,s3
}
    80003b12:	70a6                	ld	ra,104(sp)
    80003b14:	7406                	ld	s0,96(sp)
    80003b16:	64e6                	ld	s1,88(sp)
    80003b18:	6946                	ld	s2,80(sp)
    80003b1a:	69a6                	ld	s3,72(sp)
    80003b1c:	6a06                	ld	s4,64(sp)
    80003b1e:	7ae2                	ld	s5,56(sp)
    80003b20:	7b42                	ld	s6,48(sp)
    80003b22:	7ba2                	ld	s7,40(sp)
    80003b24:	7c02                	ld	s8,32(sp)
    80003b26:	6ce2                	ld	s9,24(sp)
    80003b28:	6d42                	ld	s10,16(sp)
    80003b2a:	6da2                	ld	s11,8(sp)
    80003b2c:	6165                	addi	sp,sp,112
    80003b2e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b30:	89da                	mv	s3,s6
    80003b32:	bff1                	j	80003b0e <readi+0xce>
    return 0;
    80003b34:	4501                	li	a0,0
}
    80003b36:	8082                	ret

0000000080003b38 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b38:	457c                	lw	a5,76(a0)
    80003b3a:	10d7e863          	bltu	a5,a3,80003c4a <writei+0x112>
{
    80003b3e:	7159                	addi	sp,sp,-112
    80003b40:	f486                	sd	ra,104(sp)
    80003b42:	f0a2                	sd	s0,96(sp)
    80003b44:	eca6                	sd	s1,88(sp)
    80003b46:	e8ca                	sd	s2,80(sp)
    80003b48:	e4ce                	sd	s3,72(sp)
    80003b4a:	e0d2                	sd	s4,64(sp)
    80003b4c:	fc56                	sd	s5,56(sp)
    80003b4e:	f85a                	sd	s6,48(sp)
    80003b50:	f45e                	sd	s7,40(sp)
    80003b52:	f062                	sd	s8,32(sp)
    80003b54:	ec66                	sd	s9,24(sp)
    80003b56:	e86a                	sd	s10,16(sp)
    80003b58:	e46e                	sd	s11,8(sp)
    80003b5a:	1880                	addi	s0,sp,112
    80003b5c:	8b2a                	mv	s6,a0
    80003b5e:	8c2e                	mv	s8,a1
    80003b60:	8ab2                	mv	s5,a2
    80003b62:	8936                	mv	s2,a3
    80003b64:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b66:	00e687bb          	addw	a5,a3,a4
    80003b6a:	0ed7e263          	bltu	a5,a3,80003c4e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b6e:	00043737          	lui	a4,0x43
    80003b72:	0ef76063          	bltu	a4,a5,80003c52 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b76:	0c0b8863          	beqz	s7,80003c46 <writei+0x10e>
    80003b7a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b80:	5cfd                	li	s9,-1
    80003b82:	a091                	j	80003bc6 <writei+0x8e>
    80003b84:	02099d93          	slli	s11,s3,0x20
    80003b88:	020ddd93          	srli	s11,s11,0x20
    80003b8c:	05848513          	addi	a0,s1,88
    80003b90:	86ee                	mv	a3,s11
    80003b92:	8656                	mv	a2,s5
    80003b94:	85e2                	mv	a1,s8
    80003b96:	953a                	add	a0,a0,a4
    80003b98:	fffff097          	auipc	ra,0xfffff
    80003b9c:	a5e080e7          	jalr	-1442(ra) # 800025f6 <either_copyin>
    80003ba0:	07950263          	beq	a0,s9,80003c04 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	790080e7          	jalr	1936(ra) # 80004336 <log_write>
    brelse(bp);
    80003bae:	8526                	mv	a0,s1
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	4f8080e7          	jalr	1272(ra) # 800030a8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb8:	01498a3b          	addw	s4,s3,s4
    80003bbc:	0129893b          	addw	s2,s3,s2
    80003bc0:	9aee                	add	s5,s5,s11
    80003bc2:	057a7663          	bgeu	s4,s7,80003c0e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bc6:	000b2483          	lw	s1,0(s6)
    80003bca:	00a9559b          	srliw	a1,s2,0xa
    80003bce:	855a                	mv	a0,s6
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	79c080e7          	jalr	1948(ra) # 8000336c <bmap>
    80003bd8:	0005059b          	sext.w	a1,a0
    80003bdc:	8526                	mv	a0,s1
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	39a080e7          	jalr	922(ra) # 80002f78 <bread>
    80003be6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be8:	3ff97713          	andi	a4,s2,1023
    80003bec:	40ed07bb          	subw	a5,s10,a4
    80003bf0:	414b86bb          	subw	a3,s7,s4
    80003bf4:	89be                	mv	s3,a5
    80003bf6:	2781                	sext.w	a5,a5
    80003bf8:	0006861b          	sext.w	a2,a3
    80003bfc:	f8f674e3          	bgeu	a2,a5,80003b84 <writei+0x4c>
    80003c00:	89b6                	mv	s3,a3
    80003c02:	b749                	j	80003b84 <writei+0x4c>
      brelse(bp);
    80003c04:	8526                	mv	a0,s1
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	4a2080e7          	jalr	1186(ra) # 800030a8 <brelse>
  }

  if(off > ip->size)
    80003c0e:	04cb2783          	lw	a5,76(s6)
    80003c12:	0127f463          	bgeu	a5,s2,80003c1a <writei+0xe2>
    ip->size = off;
    80003c16:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c1a:	855a                	mv	a0,s6
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	aa6080e7          	jalr	-1370(ra) # 800036c2 <iupdate>

  return tot;
    80003c24:	000a051b          	sext.w	a0,s4
}
    80003c28:	70a6                	ld	ra,104(sp)
    80003c2a:	7406                	ld	s0,96(sp)
    80003c2c:	64e6                	ld	s1,88(sp)
    80003c2e:	6946                	ld	s2,80(sp)
    80003c30:	69a6                	ld	s3,72(sp)
    80003c32:	6a06                	ld	s4,64(sp)
    80003c34:	7ae2                	ld	s5,56(sp)
    80003c36:	7b42                	ld	s6,48(sp)
    80003c38:	7ba2                	ld	s7,40(sp)
    80003c3a:	7c02                	ld	s8,32(sp)
    80003c3c:	6ce2                	ld	s9,24(sp)
    80003c3e:	6d42                	ld	s10,16(sp)
    80003c40:	6da2                	ld	s11,8(sp)
    80003c42:	6165                	addi	sp,sp,112
    80003c44:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c46:	8a5e                	mv	s4,s7
    80003c48:	bfc9                	j	80003c1a <writei+0xe2>
    return -1;
    80003c4a:	557d                	li	a0,-1
}
    80003c4c:	8082                	ret
    return -1;
    80003c4e:	557d                	li	a0,-1
    80003c50:	bfe1                	j	80003c28 <writei+0xf0>
    return -1;
    80003c52:	557d                	li	a0,-1
    80003c54:	bfd1                	j	80003c28 <writei+0xf0>

0000000080003c56 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c56:	1141                	addi	sp,sp,-16
    80003c58:	e406                	sd	ra,8(sp)
    80003c5a:	e022                	sd	s0,0(sp)
    80003c5c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c5e:	4639                	li	a2,14
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	158080e7          	jalr	344(ra) # 80000db8 <strncmp>
}
    80003c68:	60a2                	ld	ra,8(sp)
    80003c6a:	6402                	ld	s0,0(sp)
    80003c6c:	0141                	addi	sp,sp,16
    80003c6e:	8082                	ret

0000000080003c70 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c70:	7139                	addi	sp,sp,-64
    80003c72:	fc06                	sd	ra,56(sp)
    80003c74:	f822                	sd	s0,48(sp)
    80003c76:	f426                	sd	s1,40(sp)
    80003c78:	f04a                	sd	s2,32(sp)
    80003c7a:	ec4e                	sd	s3,24(sp)
    80003c7c:	e852                	sd	s4,16(sp)
    80003c7e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c80:	04451703          	lh	a4,68(a0)
    80003c84:	4785                	li	a5,1
    80003c86:	00f71a63          	bne	a4,a5,80003c9a <dirlookup+0x2a>
    80003c8a:	892a                	mv	s2,a0
    80003c8c:	89ae                	mv	s3,a1
    80003c8e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c90:	457c                	lw	a5,76(a0)
    80003c92:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c94:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c96:	e79d                	bnez	a5,80003cc4 <dirlookup+0x54>
    80003c98:	a8a5                	j	80003d10 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c9a:	00009517          	auipc	a0,0x9
    80003c9e:	b8650513          	addi	a0,a0,-1146 # 8000c820 <syscalls+0x1b8>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	89c080e7          	jalr	-1892(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003caa:	00009517          	auipc	a0,0x9
    80003cae:	b8e50513          	addi	a0,a0,-1138 # 8000c838 <syscalls+0x1d0>
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	88c080e7          	jalr	-1908(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	24c1                	addiw	s1,s1,16
    80003cbc:	04c92783          	lw	a5,76(s2)
    80003cc0:	04f4f763          	bgeu	s1,a5,80003d0e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cc4:	4741                	li	a4,16
    80003cc6:	86a6                	mv	a3,s1
    80003cc8:	fc040613          	addi	a2,s0,-64
    80003ccc:	4581                	li	a1,0
    80003cce:	854a                	mv	a0,s2
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	d70080e7          	jalr	-656(ra) # 80003a40 <readi>
    80003cd8:	47c1                	li	a5,16
    80003cda:	fcf518e3          	bne	a0,a5,80003caa <dirlookup+0x3a>
    if(de.inum == 0)
    80003cde:	fc045783          	lhu	a5,-64(s0)
    80003ce2:	dfe1                	beqz	a5,80003cba <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ce4:	fc240593          	addi	a1,s0,-62
    80003ce8:	854e                	mv	a0,s3
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	f6c080e7          	jalr	-148(ra) # 80003c56 <namecmp>
    80003cf2:	f561                	bnez	a0,80003cba <dirlookup+0x4a>
      if(poff)
    80003cf4:	000a0463          	beqz	s4,80003cfc <dirlookup+0x8c>
        *poff = off;
    80003cf8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cfc:	fc045583          	lhu	a1,-64(s0)
    80003d00:	00092503          	lw	a0,0(s2)
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	742080e7          	jalr	1858(ra) # 80003446 <iget>
    80003d0c:	a011                	j	80003d10 <dirlookup+0xa0>
  return 0;
    80003d0e:	4501                	li	a0,0
}
    80003d10:	70e2                	ld	ra,56(sp)
    80003d12:	7442                	ld	s0,48(sp)
    80003d14:	74a2                	ld	s1,40(sp)
    80003d16:	7902                	ld	s2,32(sp)
    80003d18:	69e2                	ld	s3,24(sp)
    80003d1a:	6a42                	ld	s4,16(sp)
    80003d1c:	6121                	addi	sp,sp,64
    80003d1e:	8082                	ret

0000000080003d20 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d20:	711d                	addi	sp,sp,-96
    80003d22:	ec86                	sd	ra,88(sp)
    80003d24:	e8a2                	sd	s0,80(sp)
    80003d26:	e4a6                	sd	s1,72(sp)
    80003d28:	e0ca                	sd	s2,64(sp)
    80003d2a:	fc4e                	sd	s3,56(sp)
    80003d2c:	f852                	sd	s4,48(sp)
    80003d2e:	f456                	sd	s5,40(sp)
    80003d30:	f05a                	sd	s6,32(sp)
    80003d32:	ec5e                	sd	s7,24(sp)
    80003d34:	e862                	sd	s8,16(sp)
    80003d36:	e466                	sd	s9,8(sp)
    80003d38:	1080                	addi	s0,sp,96
    80003d3a:	84aa                	mv	s1,a0
    80003d3c:	8b2e                	mv	s6,a1
    80003d3e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d40:	00054703          	lbu	a4,0(a0)
    80003d44:	02f00793          	li	a5,47
    80003d48:	02f70363          	beq	a4,a5,80003d6e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d4c:	ffffe097          	auipc	ra,0xffffe
    80003d50:	dc0080e7          	jalr	-576(ra) # 80001b0c <myproc>
    80003d54:	15053503          	ld	a0,336(a0)
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	9f6080e7          	jalr	-1546(ra) # 8000374e <idup>
    80003d60:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d62:	02f00913          	li	s2,47
  len = path - s;
    80003d66:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d68:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d6a:	4c05                	li	s8,1
    80003d6c:	a865                	j	80003e24 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d6e:	4585                	li	a1,1
    80003d70:	4505                	li	a0,1
    80003d72:	fffff097          	auipc	ra,0xfffff
    80003d76:	6d4080e7          	jalr	1748(ra) # 80003446 <iget>
    80003d7a:	89aa                	mv	s3,a0
    80003d7c:	b7dd                	j	80003d62 <namex+0x42>
      iunlockput(ip);
    80003d7e:	854e                	mv	a0,s3
    80003d80:	00000097          	auipc	ra,0x0
    80003d84:	c6e080e7          	jalr	-914(ra) # 800039ee <iunlockput>
      return 0;
    80003d88:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d8a:	854e                	mv	a0,s3
    80003d8c:	60e6                	ld	ra,88(sp)
    80003d8e:	6446                	ld	s0,80(sp)
    80003d90:	64a6                	ld	s1,72(sp)
    80003d92:	6906                	ld	s2,64(sp)
    80003d94:	79e2                	ld	s3,56(sp)
    80003d96:	7a42                	ld	s4,48(sp)
    80003d98:	7aa2                	ld	s5,40(sp)
    80003d9a:	7b02                	ld	s6,32(sp)
    80003d9c:	6be2                	ld	s7,24(sp)
    80003d9e:	6c42                	ld	s8,16(sp)
    80003da0:	6ca2                	ld	s9,8(sp)
    80003da2:	6125                	addi	sp,sp,96
    80003da4:	8082                	ret
      iunlock(ip);
    80003da6:	854e                	mv	a0,s3
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	aa6080e7          	jalr	-1370(ra) # 8000384e <iunlock>
      return ip;
    80003db0:	bfe9                	j	80003d8a <namex+0x6a>
      iunlockput(ip);
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	c3a080e7          	jalr	-966(ra) # 800039ee <iunlockput>
      return 0;
    80003dbc:	89d2                	mv	s3,s4
    80003dbe:	b7f1                	j	80003d8a <namex+0x6a>
  len = path - s;
    80003dc0:	40b48633          	sub	a2,s1,a1
    80003dc4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dc8:	094cd463          	bge	s9,s4,80003e50 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dcc:	4639                	li	a2,14
    80003dce:	8556                	mv	a0,s5
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	f70080e7          	jalr	-144(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003dd8:	0004c783          	lbu	a5,0(s1)
    80003ddc:	01279763          	bne	a5,s2,80003dea <namex+0xca>
    path++;
    80003de0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003de2:	0004c783          	lbu	a5,0(s1)
    80003de6:	ff278de3          	beq	a5,s2,80003de0 <namex+0xc0>
    ilock(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	9a0080e7          	jalr	-1632(ra) # 8000378c <ilock>
    if(ip->type != T_DIR){
    80003df4:	04499783          	lh	a5,68(s3)
    80003df8:	f98793e3          	bne	a5,s8,80003d7e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dfc:	000b0563          	beqz	s6,80003e06 <namex+0xe6>
    80003e00:	0004c783          	lbu	a5,0(s1)
    80003e04:	d3cd                	beqz	a5,80003da6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e06:	865e                	mv	a2,s7
    80003e08:	85d6                	mv	a1,s5
    80003e0a:	854e                	mv	a0,s3
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	e64080e7          	jalr	-412(ra) # 80003c70 <dirlookup>
    80003e14:	8a2a                	mv	s4,a0
    80003e16:	dd51                	beqz	a0,80003db2 <namex+0x92>
    iunlockput(ip);
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	bd4080e7          	jalr	-1068(ra) # 800039ee <iunlockput>
    ip = next;
    80003e22:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	05279763          	bne	a5,s2,80003e76 <namex+0x156>
    path++;
    80003e2c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e2e:	0004c783          	lbu	a5,0(s1)
    80003e32:	ff278de3          	beq	a5,s2,80003e2c <namex+0x10c>
  if(*path == 0)
    80003e36:	c79d                	beqz	a5,80003e64 <namex+0x144>
    path++;
    80003e38:	85a6                	mv	a1,s1
  len = path - s;
    80003e3a:	8a5e                	mv	s4,s7
    80003e3c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e3e:	01278963          	beq	a5,s2,80003e50 <namex+0x130>
    80003e42:	dfbd                	beqz	a5,80003dc0 <namex+0xa0>
    path++;
    80003e44:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e46:	0004c783          	lbu	a5,0(s1)
    80003e4a:	ff279ce3          	bne	a5,s2,80003e42 <namex+0x122>
    80003e4e:	bf8d                	j	80003dc0 <namex+0xa0>
    memmove(name, s, len);
    80003e50:	2601                	sext.w	a2,a2
    80003e52:	8556                	mv	a0,s5
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	eec080e7          	jalr	-276(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e5c:	9a56                	add	s4,s4,s5
    80003e5e:	000a0023          	sb	zero,0(s4)
    80003e62:	bf9d                	j	80003dd8 <namex+0xb8>
  if(nameiparent){
    80003e64:	f20b03e3          	beqz	s6,80003d8a <namex+0x6a>
    iput(ip);
    80003e68:	854e                	mv	a0,s3
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	adc080e7          	jalr	-1316(ra) # 80003946 <iput>
    return 0;
    80003e72:	4981                	li	s3,0
    80003e74:	bf19                	j	80003d8a <namex+0x6a>
  if(*path == 0)
    80003e76:	d7fd                	beqz	a5,80003e64 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e78:	0004c783          	lbu	a5,0(s1)
    80003e7c:	85a6                	mv	a1,s1
    80003e7e:	b7d1                	j	80003e42 <namex+0x122>

0000000080003e80 <dirlink>:
{
    80003e80:	7139                	addi	sp,sp,-64
    80003e82:	fc06                	sd	ra,56(sp)
    80003e84:	f822                	sd	s0,48(sp)
    80003e86:	f426                	sd	s1,40(sp)
    80003e88:	f04a                	sd	s2,32(sp)
    80003e8a:	ec4e                	sd	s3,24(sp)
    80003e8c:	e852                	sd	s4,16(sp)
    80003e8e:	0080                	addi	s0,sp,64
    80003e90:	892a                	mv	s2,a0
    80003e92:	8a2e                	mv	s4,a1
    80003e94:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e96:	4601                	li	a2,0
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	dd8080e7          	jalr	-552(ra) # 80003c70 <dirlookup>
    80003ea0:	e93d                	bnez	a0,80003f16 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea2:	04c92483          	lw	s1,76(s2)
    80003ea6:	c49d                	beqz	s1,80003ed4 <dirlink+0x54>
    80003ea8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eaa:	4741                	li	a4,16
    80003eac:	86a6                	mv	a3,s1
    80003eae:	fc040613          	addi	a2,s0,-64
    80003eb2:	4581                	li	a1,0
    80003eb4:	854a                	mv	a0,s2
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	b8a080e7          	jalr	-1142(ra) # 80003a40 <readi>
    80003ebe:	47c1                	li	a5,16
    80003ec0:	06f51163          	bne	a0,a5,80003f22 <dirlink+0xa2>
    if(de.inum == 0)
    80003ec4:	fc045783          	lhu	a5,-64(s0)
    80003ec8:	c791                	beqz	a5,80003ed4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	24c1                	addiw	s1,s1,16
    80003ecc:	04c92783          	lw	a5,76(s2)
    80003ed0:	fcf4ede3          	bltu	s1,a5,80003eaa <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ed4:	4639                	li	a2,14
    80003ed6:	85d2                	mv	a1,s4
    80003ed8:	fc240513          	addi	a0,s0,-62
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	f18080e7          	jalr	-232(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003ee4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee8:	4741                	li	a4,16
    80003eea:	86a6                	mv	a3,s1
    80003eec:	fc040613          	addi	a2,s0,-64
    80003ef0:	4581                	li	a1,0
    80003ef2:	854a                	mv	a0,s2
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	c44080e7          	jalr	-956(ra) # 80003b38 <writei>
    80003efc:	872a                	mv	a4,a0
    80003efe:	47c1                	li	a5,16
  return 0;
    80003f00:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f02:	02f71863          	bne	a4,a5,80003f32 <dirlink+0xb2>
}
    80003f06:	70e2                	ld	ra,56(sp)
    80003f08:	7442                	ld	s0,48(sp)
    80003f0a:	74a2                	ld	s1,40(sp)
    80003f0c:	7902                	ld	s2,32(sp)
    80003f0e:	69e2                	ld	s3,24(sp)
    80003f10:	6a42                	ld	s4,16(sp)
    80003f12:	6121                	addi	sp,sp,64
    80003f14:	8082                	ret
    iput(ip);
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	a30080e7          	jalr	-1488(ra) # 80003946 <iput>
    return -1;
    80003f1e:	557d                	li	a0,-1
    80003f20:	b7dd                	j	80003f06 <dirlink+0x86>
      panic("dirlink read");
    80003f22:	00009517          	auipc	a0,0x9
    80003f26:	92650513          	addi	a0,a0,-1754 # 8000c848 <syscalls+0x1e0>
    80003f2a:	ffffc097          	auipc	ra,0xffffc
    80003f2e:	614080e7          	jalr	1556(ra) # 8000053e <panic>
    panic("dirlink");
    80003f32:	00009517          	auipc	a0,0x9
    80003f36:	a2650513          	addi	a0,a0,-1498 # 8000c958 <syscalls+0x2f0>
    80003f3a:	ffffc097          	auipc	ra,0xffffc
    80003f3e:	604080e7          	jalr	1540(ra) # 8000053e <panic>

0000000080003f42 <namei>:

struct inode*
namei(char *path)
{
    80003f42:	1101                	addi	sp,sp,-32
    80003f44:	ec06                	sd	ra,24(sp)
    80003f46:	e822                	sd	s0,16(sp)
    80003f48:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f4a:	fe040613          	addi	a2,s0,-32
    80003f4e:	4581                	li	a1,0
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	dd0080e7          	jalr	-560(ra) # 80003d20 <namex>
}
    80003f58:	60e2                	ld	ra,24(sp)
    80003f5a:	6442                	ld	s0,16(sp)
    80003f5c:	6105                	addi	sp,sp,32
    80003f5e:	8082                	ret

0000000080003f60 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f60:	1141                	addi	sp,sp,-16
    80003f62:	e406                	sd	ra,8(sp)
    80003f64:	e022                	sd	s0,0(sp)
    80003f66:	0800                	addi	s0,sp,16
    80003f68:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f6a:	4585                	li	a1,1
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	db4080e7          	jalr	-588(ra) # 80003d20 <namex>
}
    80003f74:	60a2                	ld	ra,8(sp)
    80003f76:	6402                	ld	s0,0(sp)
    80003f78:	0141                	addi	sp,sp,16
    80003f7a:	8082                	ret

0000000080003f7c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f7c:	1101                	addi	sp,sp,-32
    80003f7e:	ec06                	sd	ra,24(sp)
    80003f80:	e822                	sd	s0,16(sp)
    80003f82:	e426                	sd	s1,8(sp)
    80003f84:	e04a                	sd	s2,0(sp)
    80003f86:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f88:	00024917          	auipc	s2,0x24
    80003f8c:	2e890913          	addi	s2,s2,744 # 80028270 <log>
    80003f90:	01892583          	lw	a1,24(s2)
    80003f94:	02892503          	lw	a0,40(s2)
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	fe0080e7          	jalr	-32(ra) # 80002f78 <bread>
    80003fa0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fa2:	02c92683          	lw	a3,44(s2)
    80003fa6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa8:	02d05763          	blez	a3,80003fd6 <write_head+0x5a>
    80003fac:	00024797          	auipc	a5,0x24
    80003fb0:	2f478793          	addi	a5,a5,756 # 800282a0 <log+0x30>
    80003fb4:	05c50713          	addi	a4,a0,92
    80003fb8:	36fd                	addiw	a3,a3,-1
    80003fba:	1682                	slli	a3,a3,0x20
    80003fbc:	9281                	srli	a3,a3,0x20
    80003fbe:	068a                	slli	a3,a3,0x2
    80003fc0:	00024617          	auipc	a2,0x24
    80003fc4:	2e460613          	addi	a2,a2,740 # 800282a4 <log+0x34>
    80003fc8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fca:	4390                	lw	a2,0(a5)
    80003fcc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fce:	0791                	addi	a5,a5,4
    80003fd0:	0711                	addi	a4,a4,4
    80003fd2:	fed79ce3          	bne	a5,a3,80003fca <write_head+0x4e>
  }
  bwrite(buf);
    80003fd6:	8526                	mv	a0,s1
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	092080e7          	jalr	146(ra) # 8000306a <bwrite>
  brelse(buf);
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	fffff097          	auipc	ra,0xfffff
    80003fe6:	0c6080e7          	jalr	198(ra) # 800030a8 <brelse>
}
    80003fea:	60e2                	ld	ra,24(sp)
    80003fec:	6442                	ld	s0,16(sp)
    80003fee:	64a2                	ld	s1,8(sp)
    80003ff0:	6902                	ld	s2,0(sp)
    80003ff2:	6105                	addi	sp,sp,32
    80003ff4:	8082                	ret

0000000080003ff6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff6:	00024797          	auipc	a5,0x24
    80003ffa:	2a67a783          	lw	a5,678(a5) # 8002829c <log+0x2c>
    80003ffe:	0af05d63          	blez	a5,800040b8 <install_trans+0xc2>
{
    80004002:	7139                	addi	sp,sp,-64
    80004004:	fc06                	sd	ra,56(sp)
    80004006:	f822                	sd	s0,48(sp)
    80004008:	f426                	sd	s1,40(sp)
    8000400a:	f04a                	sd	s2,32(sp)
    8000400c:	ec4e                	sd	s3,24(sp)
    8000400e:	e852                	sd	s4,16(sp)
    80004010:	e456                	sd	s5,8(sp)
    80004012:	e05a                	sd	s6,0(sp)
    80004014:	0080                	addi	s0,sp,64
    80004016:	8b2a                	mv	s6,a0
    80004018:	00024a97          	auipc	s5,0x24
    8000401c:	288a8a93          	addi	s5,s5,648 # 800282a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004020:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004022:	00024997          	auipc	s3,0x24
    80004026:	24e98993          	addi	s3,s3,590 # 80028270 <log>
    8000402a:	a035                	j	80004056 <install_trans+0x60>
      bunpin(dbuf);
    8000402c:	8526                	mv	a0,s1
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	154080e7          	jalr	340(ra) # 80003182 <bunpin>
    brelse(lbuf);
    80004036:	854a                	mv	a0,s2
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	070080e7          	jalr	112(ra) # 800030a8 <brelse>
    brelse(dbuf);
    80004040:	8526                	mv	a0,s1
    80004042:	fffff097          	auipc	ra,0xfffff
    80004046:	066080e7          	jalr	102(ra) # 800030a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404a:	2a05                	addiw	s4,s4,1
    8000404c:	0a91                	addi	s5,s5,4
    8000404e:	02c9a783          	lw	a5,44(s3)
    80004052:	04fa5963          	bge	s4,a5,800040a4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004056:	0189a583          	lw	a1,24(s3)
    8000405a:	014585bb          	addw	a1,a1,s4
    8000405e:	2585                	addiw	a1,a1,1
    80004060:	0289a503          	lw	a0,40(s3)
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	f14080e7          	jalr	-236(ra) # 80002f78 <bread>
    8000406c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000406e:	000aa583          	lw	a1,0(s5)
    80004072:	0289a503          	lw	a0,40(s3)
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	f02080e7          	jalr	-254(ra) # 80002f78 <bread>
    8000407e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004080:	40000613          	li	a2,1024
    80004084:	05890593          	addi	a1,s2,88
    80004088:	05850513          	addi	a0,a0,88
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	cb4080e7          	jalr	-844(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	fd4080e7          	jalr	-44(ra) # 8000306a <bwrite>
    if(recovering == 0)
    8000409e:	f80b1ce3          	bnez	s6,80004036 <install_trans+0x40>
    800040a2:	b769                	j	8000402c <install_trans+0x36>
}
    800040a4:	70e2                	ld	ra,56(sp)
    800040a6:	7442                	ld	s0,48(sp)
    800040a8:	74a2                	ld	s1,40(sp)
    800040aa:	7902                	ld	s2,32(sp)
    800040ac:	69e2                	ld	s3,24(sp)
    800040ae:	6a42                	ld	s4,16(sp)
    800040b0:	6aa2                	ld	s5,8(sp)
    800040b2:	6b02                	ld	s6,0(sp)
    800040b4:	6121                	addi	sp,sp,64
    800040b6:	8082                	ret
    800040b8:	8082                	ret

00000000800040ba <initlog>:
{
    800040ba:	7179                	addi	sp,sp,-48
    800040bc:	f406                	sd	ra,40(sp)
    800040be:	f022                	sd	s0,32(sp)
    800040c0:	ec26                	sd	s1,24(sp)
    800040c2:	e84a                	sd	s2,16(sp)
    800040c4:	e44e                	sd	s3,8(sp)
    800040c6:	1800                	addi	s0,sp,48
    800040c8:	892a                	mv	s2,a0
    800040ca:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040cc:	00024497          	auipc	s1,0x24
    800040d0:	1a448493          	addi	s1,s1,420 # 80028270 <log>
    800040d4:	00008597          	auipc	a1,0x8
    800040d8:	78458593          	addi	a1,a1,1924 # 8000c858 <syscalls+0x1f0>
    800040dc:	8526                	mv	a0,s1
    800040de:	ffffd097          	auipc	ra,0xffffd
    800040e2:	a76080e7          	jalr	-1418(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040e6:	0149a583          	lw	a1,20(s3)
    800040ea:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040ec:	0109a783          	lw	a5,16(s3)
    800040f0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040f6:	854a                	mv	a0,s2
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	e80080e7          	jalr	-384(ra) # 80002f78 <bread>
  log.lh.n = lh->n;
    80004100:	4d3c                	lw	a5,88(a0)
    80004102:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004104:	02f05563          	blez	a5,8000412e <initlog+0x74>
    80004108:	05c50713          	addi	a4,a0,92
    8000410c:	00024697          	auipc	a3,0x24
    80004110:	19468693          	addi	a3,a3,404 # 800282a0 <log+0x30>
    80004114:	37fd                	addiw	a5,a5,-1
    80004116:	1782                	slli	a5,a5,0x20
    80004118:	9381                	srli	a5,a5,0x20
    8000411a:	078a                	slli	a5,a5,0x2
    8000411c:	06050613          	addi	a2,a0,96
    80004120:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004122:	4310                	lw	a2,0(a4)
    80004124:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004126:	0711                	addi	a4,a4,4
    80004128:	0691                	addi	a3,a3,4
    8000412a:	fef71ce3          	bne	a4,a5,80004122 <initlog+0x68>
  brelse(buf);
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	f7a080e7          	jalr	-134(ra) # 800030a8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004136:	4505                	li	a0,1
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	ebe080e7          	jalr	-322(ra) # 80003ff6 <install_trans>
  log.lh.n = 0;
    80004140:	00024797          	auipc	a5,0x24
    80004144:	1407ae23          	sw	zero,348(a5) # 8002829c <log+0x2c>
  write_head(); // clear the log
    80004148:	00000097          	auipc	ra,0x0
    8000414c:	e34080e7          	jalr	-460(ra) # 80003f7c <write_head>
}
    80004150:	70a2                	ld	ra,40(sp)
    80004152:	7402                	ld	s0,32(sp)
    80004154:	64e2                	ld	s1,24(sp)
    80004156:	6942                	ld	s2,16(sp)
    80004158:	69a2                	ld	s3,8(sp)
    8000415a:	6145                	addi	sp,sp,48
    8000415c:	8082                	ret

000000008000415e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	e04a                	sd	s2,0(sp)
    80004168:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000416a:	00024517          	auipc	a0,0x24
    8000416e:	10650513          	addi	a0,a0,262 # 80028270 <log>
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	a72080e7          	jalr	-1422(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000417a:	00024497          	auipc	s1,0x24
    8000417e:	0f648493          	addi	s1,s1,246 # 80028270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004182:	4979                	li	s2,30
    80004184:	a039                	j	80004192 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004186:	85a6                	mv	a1,s1
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffe097          	auipc	ra,0xffffe
    8000418e:	072080e7          	jalr	114(ra) # 800021fc <sleep>
    if(log.committing){
    80004192:	50dc                	lw	a5,36(s1)
    80004194:	fbed                	bnez	a5,80004186 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004196:	509c                	lw	a5,32(s1)
    80004198:	0017871b          	addiw	a4,a5,1
    8000419c:	0007069b          	sext.w	a3,a4
    800041a0:	0027179b          	slliw	a5,a4,0x2
    800041a4:	9fb9                	addw	a5,a5,a4
    800041a6:	0017979b          	slliw	a5,a5,0x1
    800041aa:	54d8                	lw	a4,44(s1)
    800041ac:	9fb9                	addw	a5,a5,a4
    800041ae:	00f95963          	bge	s2,a5,800041c0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041b2:	85a6                	mv	a1,s1
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffe097          	auipc	ra,0xffffe
    800041ba:	046080e7          	jalr	70(ra) # 800021fc <sleep>
    800041be:	bfd1                	j	80004192 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041c0:	00024517          	auipc	a0,0x24
    800041c4:	0b050513          	addi	a0,a0,176 # 80028270 <log>
    800041c8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	ace080e7          	jalr	-1330(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041d2:	60e2                	ld	ra,24(sp)
    800041d4:	6442                	ld	s0,16(sp)
    800041d6:	64a2                	ld	s1,8(sp)
    800041d8:	6902                	ld	s2,0(sp)
    800041da:	6105                	addi	sp,sp,32
    800041dc:	8082                	ret

00000000800041de <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041de:	7139                	addi	sp,sp,-64
    800041e0:	fc06                	sd	ra,56(sp)
    800041e2:	f822                	sd	s0,48(sp)
    800041e4:	f426                	sd	s1,40(sp)
    800041e6:	f04a                	sd	s2,32(sp)
    800041e8:	ec4e                	sd	s3,24(sp)
    800041ea:	e852                	sd	s4,16(sp)
    800041ec:	e456                	sd	s5,8(sp)
    800041ee:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041f0:	00024497          	auipc	s1,0x24
    800041f4:	08048493          	addi	s1,s1,128 # 80028270 <log>
    800041f8:	8526                	mv	a0,s1
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	9ea080e7          	jalr	-1558(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004202:	509c                	lw	a5,32(s1)
    80004204:	37fd                	addiw	a5,a5,-1
    80004206:	0007891b          	sext.w	s2,a5
    8000420a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000420c:	50dc                	lw	a5,36(s1)
    8000420e:	efb9                	bnez	a5,8000426c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004210:	06091663          	bnez	s2,8000427c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004214:	00024497          	auipc	s1,0x24
    80004218:	05c48493          	addi	s1,s1,92 # 80028270 <log>
    8000421c:	4785                	li	a5,1
    8000421e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004220:	8526                	mv	a0,s1
    80004222:	ffffd097          	auipc	ra,0xffffd
    80004226:	a76080e7          	jalr	-1418(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000422a:	54dc                	lw	a5,44(s1)
    8000422c:	06f04763          	bgtz	a5,8000429a <end_op+0xbc>
    acquire(&log.lock);
    80004230:	00024497          	auipc	s1,0x24
    80004234:	04048493          	addi	s1,s1,64 # 80028270 <log>
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffd097          	auipc	ra,0xffffd
    8000423e:	9aa080e7          	jalr	-1622(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004242:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004246:	8526                	mv	a0,s1
    80004248:	ffffe097          	auipc	ra,0xffffe
    8000424c:	140080e7          	jalr	320(ra) # 80002388 <wakeup>
    release(&log.lock);
    80004250:	8526                	mv	a0,s1
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
}
    8000425a:	70e2                	ld	ra,56(sp)
    8000425c:	7442                	ld	s0,48(sp)
    8000425e:	74a2                	ld	s1,40(sp)
    80004260:	7902                	ld	s2,32(sp)
    80004262:	69e2                	ld	s3,24(sp)
    80004264:	6a42                	ld	s4,16(sp)
    80004266:	6aa2                	ld	s5,8(sp)
    80004268:	6121                	addi	sp,sp,64
    8000426a:	8082                	ret
    panic("log.committing");
    8000426c:	00008517          	auipc	a0,0x8
    80004270:	5f450513          	addi	a0,a0,1524 # 8000c860 <syscalls+0x1f8>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>
    wakeup(&log);
    8000427c:	00024497          	auipc	s1,0x24
    80004280:	ff448493          	addi	s1,s1,-12 # 80028270 <log>
    80004284:	8526                	mv	a0,s1
    80004286:	ffffe097          	auipc	ra,0xffffe
    8000428a:	102080e7          	jalr	258(ra) # 80002388 <wakeup>
  release(&log.lock);
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	a08080e7          	jalr	-1528(ra) # 80000c98 <release>
  if(do_commit){
    80004298:	b7c9                	j	8000425a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429a:	00024a97          	auipc	s5,0x24
    8000429e:	006a8a93          	addi	s5,s5,6 # 800282a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042a2:	00024a17          	auipc	s4,0x24
    800042a6:	fcea0a13          	addi	s4,s4,-50 # 80028270 <log>
    800042aa:	018a2583          	lw	a1,24(s4)
    800042ae:	012585bb          	addw	a1,a1,s2
    800042b2:	2585                	addiw	a1,a1,1
    800042b4:	028a2503          	lw	a0,40(s4)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	cc0080e7          	jalr	-832(ra) # 80002f78 <bread>
    800042c0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042c2:	000aa583          	lw	a1,0(s5)
    800042c6:	028a2503          	lw	a0,40(s4)
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	cae080e7          	jalr	-850(ra) # 80002f78 <bread>
    800042d2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042d4:	40000613          	li	a2,1024
    800042d8:	05850593          	addi	a1,a0,88
    800042dc:	05848513          	addi	a0,s1,88
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	a60080e7          	jalr	-1440(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042e8:	8526                	mv	a0,s1
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	d80080e7          	jalr	-640(ra) # 8000306a <bwrite>
    brelse(from);
    800042f2:	854e                	mv	a0,s3
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	db4080e7          	jalr	-588(ra) # 800030a8 <brelse>
    brelse(to);
    800042fc:	8526                	mv	a0,s1
    800042fe:	fffff097          	auipc	ra,0xfffff
    80004302:	daa080e7          	jalr	-598(ra) # 800030a8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004306:	2905                	addiw	s2,s2,1
    80004308:	0a91                	addi	s5,s5,4
    8000430a:	02ca2783          	lw	a5,44(s4)
    8000430e:	f8f94ee3          	blt	s2,a5,800042aa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004312:	00000097          	auipc	ra,0x0
    80004316:	c6a080e7          	jalr	-918(ra) # 80003f7c <write_head>
    install_trans(0); // Now install writes to home locations
    8000431a:	4501                	li	a0,0
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	cda080e7          	jalr	-806(ra) # 80003ff6 <install_trans>
    log.lh.n = 0;
    80004324:	00024797          	auipc	a5,0x24
    80004328:	f607ac23          	sw	zero,-136(a5) # 8002829c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c50080e7          	jalr	-944(ra) # 80003f7c <write_head>
    80004334:	bdf5                	j	80004230 <end_op+0x52>

0000000080004336 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004336:	1101                	addi	sp,sp,-32
    80004338:	ec06                	sd	ra,24(sp)
    8000433a:	e822                	sd	s0,16(sp)
    8000433c:	e426                	sd	s1,8(sp)
    8000433e:	e04a                	sd	s2,0(sp)
    80004340:	1000                	addi	s0,sp,32
    80004342:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004344:	00024917          	auipc	s2,0x24
    80004348:	f2c90913          	addi	s2,s2,-212 # 80028270 <log>
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	896080e7          	jalr	-1898(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004356:	02c92603          	lw	a2,44(s2)
    8000435a:	47f5                	li	a5,29
    8000435c:	06c7c563          	blt	a5,a2,800043c6 <log_write+0x90>
    80004360:	00024797          	auipc	a5,0x24
    80004364:	f2c7a783          	lw	a5,-212(a5) # 8002828c <log+0x1c>
    80004368:	37fd                	addiw	a5,a5,-1
    8000436a:	04f65e63          	bge	a2,a5,800043c6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000436e:	00024797          	auipc	a5,0x24
    80004372:	f227a783          	lw	a5,-222(a5) # 80028290 <log+0x20>
    80004376:	06f05063          	blez	a5,800043d6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000437a:	4781                	li	a5,0
    8000437c:	06c05563          	blez	a2,800043e6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004380:	44cc                	lw	a1,12(s1)
    80004382:	00024717          	auipc	a4,0x24
    80004386:	f1e70713          	addi	a4,a4,-226 # 800282a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000438a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438c:	4314                	lw	a3,0(a4)
    8000438e:	04b68c63          	beq	a3,a1,800043e6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004392:	2785                	addiw	a5,a5,1
    80004394:	0711                	addi	a4,a4,4
    80004396:	fef61be3          	bne	a2,a5,8000438c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000439a:	0621                	addi	a2,a2,8
    8000439c:	060a                	slli	a2,a2,0x2
    8000439e:	00024797          	auipc	a5,0x24
    800043a2:	ed278793          	addi	a5,a5,-302 # 80028270 <log>
    800043a6:	963e                	add	a2,a2,a5
    800043a8:	44dc                	lw	a5,12(s1)
    800043aa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ac:	8526                	mv	a0,s1
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	d98080e7          	jalr	-616(ra) # 80003146 <bpin>
    log.lh.n++;
    800043b6:	00024717          	auipc	a4,0x24
    800043ba:	eba70713          	addi	a4,a4,-326 # 80028270 <log>
    800043be:	575c                	lw	a5,44(a4)
    800043c0:	2785                	addiw	a5,a5,1
    800043c2:	d75c                	sw	a5,44(a4)
    800043c4:	a835                	j	80004400 <log_write+0xca>
    panic("too big a transaction");
    800043c6:	00008517          	auipc	a0,0x8
    800043ca:	4aa50513          	addi	a0,a0,1194 # 8000c870 <syscalls+0x208>
    800043ce:	ffffc097          	auipc	ra,0xffffc
    800043d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043d6:	00008517          	auipc	a0,0x8
    800043da:	4b250513          	addi	a0,a0,1202 # 8000c888 <syscalls+0x220>
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043e6:	00878713          	addi	a4,a5,8
    800043ea:	00271693          	slli	a3,a4,0x2
    800043ee:	00024717          	auipc	a4,0x24
    800043f2:	e8270713          	addi	a4,a4,-382 # 80028270 <log>
    800043f6:	9736                	add	a4,a4,a3
    800043f8:	44d4                	lw	a3,12(s1)
    800043fa:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043fc:	faf608e3          	beq	a2,a5,800043ac <log_write+0x76>
  }
  release(&log.lock);
    80004400:	00024517          	auipc	a0,0x24
    80004404:	e7050513          	addi	a0,a0,-400 # 80028270 <log>
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	890080e7          	jalr	-1904(ra) # 80000c98 <release>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret

000000008000441c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000441c:	1101                	addi	sp,sp,-32
    8000441e:	ec06                	sd	ra,24(sp)
    80004420:	e822                	sd	s0,16(sp)
    80004422:	e426                	sd	s1,8(sp)
    80004424:	e04a                	sd	s2,0(sp)
    80004426:	1000                	addi	s0,sp,32
    80004428:	84aa                	mv	s1,a0
    8000442a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000442c:	00008597          	auipc	a1,0x8
    80004430:	47c58593          	addi	a1,a1,1148 # 8000c8a8 <syscalls+0x240>
    80004434:	0521                	addi	a0,a0,8
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	71e080e7          	jalr	1822(ra) # 80000b54 <initlock>
  lk->name = name;
    8000443e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004442:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004446:	0204a423          	sw	zero,40(s1)
}
    8000444a:	60e2                	ld	ra,24(sp)
    8000444c:	6442                	ld	s0,16(sp)
    8000444e:	64a2                	ld	s1,8(sp)
    80004450:	6902                	ld	s2,0(sp)
    80004452:	6105                	addi	sp,sp,32
    80004454:	8082                	ret

0000000080004456 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004456:	1101                	addi	sp,sp,-32
    80004458:	ec06                	sd	ra,24(sp)
    8000445a:	e822                	sd	s0,16(sp)
    8000445c:	e426                	sd	s1,8(sp)
    8000445e:	e04a                	sd	s2,0(sp)
    80004460:	1000                	addi	s0,sp,32
    80004462:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004464:	00850913          	addi	s2,a0,8
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	77a080e7          	jalr	1914(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004472:	409c                	lw	a5,0(s1)
    80004474:	cb89                	beqz	a5,80004486 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004476:	85ca                	mv	a1,s2
    80004478:	8526                	mv	a0,s1
    8000447a:	ffffe097          	auipc	ra,0xffffe
    8000447e:	d82080e7          	jalr	-638(ra) # 800021fc <sleep>
  while (lk->locked) {
    80004482:	409c                	lw	a5,0(s1)
    80004484:	fbed                	bnez	a5,80004476 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004486:	4785                	li	a5,1
    80004488:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	682080e7          	jalr	1666(ra) # 80001b0c <myproc>
    80004492:	591c                	lw	a5,48(a0)
    80004494:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004496:	854a                	mv	a0,s2
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	800080e7          	jalr	-2048(ra) # 80000c98 <release>
}
    800044a0:	60e2                	ld	ra,24(sp)
    800044a2:	6442                	ld	s0,16(sp)
    800044a4:	64a2                	ld	s1,8(sp)
    800044a6:	6902                	ld	s2,0(sp)
    800044a8:	6105                	addi	sp,sp,32
    800044aa:	8082                	ret

00000000800044ac <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ac:	1101                	addi	sp,sp,-32
    800044ae:	ec06                	sd	ra,24(sp)
    800044b0:	e822                	sd	s0,16(sp)
    800044b2:	e426                	sd	s1,8(sp)
    800044b4:	e04a                	sd	s2,0(sp)
    800044b6:	1000                	addi	s0,sp,32
    800044b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ba:	00850913          	addi	s2,a0,8
    800044be:	854a                	mv	a0,s2
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	724080e7          	jalr	1828(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044cc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffe097          	auipc	ra,0xffffe
    800044d6:	eb6080e7          	jalr	-330(ra) # 80002388 <wakeup>
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

00000000800044f0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044f0:	7179                	addi	sp,sp,-48
    800044f2:	f406                	sd	ra,40(sp)
    800044f4:	f022                	sd	s0,32(sp)
    800044f6:	ec26                	sd	s1,24(sp)
    800044f8:	e84a                	sd	s2,16(sp)
    800044fa:	e44e                	sd	s3,8(sp)
    800044fc:	1800                	addi	s0,sp,48
    800044fe:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004500:	00850913          	addi	s2,a0,8
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	6de080e7          	jalr	1758(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450e:	409c                	lw	a5,0(s1)
    80004510:	ef99                	bnez	a5,8000452e <holdingsleep+0x3e>
    80004512:	4481                	li	s1,0
  release(&lk->lk);
    80004514:	854a                	mv	a0,s2
    80004516:	ffffc097          	auipc	ra,0xffffc
    8000451a:	782080e7          	jalr	1922(ra) # 80000c98 <release>
  return r;
}
    8000451e:	8526                	mv	a0,s1
    80004520:	70a2                	ld	ra,40(sp)
    80004522:	7402                	ld	s0,32(sp)
    80004524:	64e2                	ld	s1,24(sp)
    80004526:	6942                	ld	s2,16(sp)
    80004528:	69a2                	ld	s3,8(sp)
    8000452a:	6145                	addi	sp,sp,48
    8000452c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452e:	0284a983          	lw	s3,40(s1)
    80004532:	ffffd097          	auipc	ra,0xffffd
    80004536:	5da080e7          	jalr	1498(ra) # 80001b0c <myproc>
    8000453a:	5904                	lw	s1,48(a0)
    8000453c:	413484b3          	sub	s1,s1,s3
    80004540:	0014b493          	seqz	s1,s1
    80004544:	bfc1                	j	80004514 <holdingsleep+0x24>

0000000080004546 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004546:	1141                	addi	sp,sp,-16
    80004548:	e406                	sd	ra,8(sp)
    8000454a:	e022                	sd	s0,0(sp)
    8000454c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000454e:	00008597          	auipc	a1,0x8
    80004552:	36a58593          	addi	a1,a1,874 # 8000c8b8 <syscalls+0x250>
    80004556:	00024517          	auipc	a0,0x24
    8000455a:	e6250513          	addi	a0,a0,-414 # 800283b8 <ftable>
    8000455e:	ffffc097          	auipc	ra,0xffffc
    80004562:	5f6080e7          	jalr	1526(ra) # 80000b54 <initlock>
}
    80004566:	60a2                	ld	ra,8(sp)
    80004568:	6402                	ld	s0,0(sp)
    8000456a:	0141                	addi	sp,sp,16
    8000456c:	8082                	ret

000000008000456e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004578:	00024517          	auipc	a0,0x24
    8000457c:	e4050513          	addi	a0,a0,-448 # 800283b8 <ftable>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	664080e7          	jalr	1636(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004588:	00024497          	auipc	s1,0x24
    8000458c:	e4848493          	addi	s1,s1,-440 # 800283d0 <ftable+0x18>
    80004590:	00025717          	auipc	a4,0x25
    80004594:	de070713          	addi	a4,a4,-544 # 80029370 <ftable+0xfb8>
    if(f->ref == 0){
    80004598:	40dc                	lw	a5,4(s1)
    8000459a:	cf99                	beqz	a5,800045b8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459c:	02848493          	addi	s1,s1,40
    800045a0:	fee49ce3          	bne	s1,a4,80004598 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045a4:	00024517          	auipc	a0,0x24
    800045a8:	e1450513          	addi	a0,a0,-492 # 800283b8 <ftable>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	6ec080e7          	jalr	1772(ra) # 80000c98 <release>
  return 0;
    800045b4:	4481                	li	s1,0
    800045b6:	a819                	j	800045cc <filealloc+0x5e>
      f->ref = 1;
    800045b8:	4785                	li	a5,1
    800045ba:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045bc:	00024517          	auipc	a0,0x24
    800045c0:	dfc50513          	addi	a0,a0,-516 # 800283b8 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6d4080e7          	jalr	1748(ra) # 80000c98 <release>
}
    800045cc:	8526                	mv	a0,s1
    800045ce:	60e2                	ld	ra,24(sp)
    800045d0:	6442                	ld	s0,16(sp)
    800045d2:	64a2                	ld	s1,8(sp)
    800045d4:	6105                	addi	sp,sp,32
    800045d6:	8082                	ret

00000000800045d8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045d8:	1101                	addi	sp,sp,-32
    800045da:	ec06                	sd	ra,24(sp)
    800045dc:	e822                	sd	s0,16(sp)
    800045de:	e426                	sd	s1,8(sp)
    800045e0:	1000                	addi	s0,sp,32
    800045e2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045e4:	00024517          	auipc	a0,0x24
    800045e8:	dd450513          	addi	a0,a0,-556 # 800283b8 <ftable>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	5f8080e7          	jalr	1528(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045f4:	40dc                	lw	a5,4(s1)
    800045f6:	02f05263          	blez	a5,8000461a <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045fa:	2785                	addiw	a5,a5,1
    800045fc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045fe:	00024517          	auipc	a0,0x24
    80004602:	dba50513          	addi	a0,a0,-582 # 800283b8 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	692080e7          	jalr	1682(ra) # 80000c98 <release>
  return f;
}
    8000460e:	8526                	mv	a0,s1
    80004610:	60e2                	ld	ra,24(sp)
    80004612:	6442                	ld	s0,16(sp)
    80004614:	64a2                	ld	s1,8(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret
    panic("filedup");
    8000461a:	00008517          	auipc	a0,0x8
    8000461e:	2a650513          	addi	a0,a0,678 # 8000c8c0 <syscalls+0x258>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	f1c080e7          	jalr	-228(ra) # 8000053e <panic>

000000008000462a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000462a:	7139                	addi	sp,sp,-64
    8000462c:	fc06                	sd	ra,56(sp)
    8000462e:	f822                	sd	s0,48(sp)
    80004630:	f426                	sd	s1,40(sp)
    80004632:	f04a                	sd	s2,32(sp)
    80004634:	ec4e                	sd	s3,24(sp)
    80004636:	e852                	sd	s4,16(sp)
    80004638:	e456                	sd	s5,8(sp)
    8000463a:	0080                	addi	s0,sp,64
    8000463c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000463e:	00024517          	auipc	a0,0x24
    80004642:	d7a50513          	addi	a0,a0,-646 # 800283b8 <ftable>
    80004646:	ffffc097          	auipc	ra,0xffffc
    8000464a:	59e080e7          	jalr	1438(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000464e:	40dc                	lw	a5,4(s1)
    80004650:	06f05163          	blez	a5,800046b2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004654:	37fd                	addiw	a5,a5,-1
    80004656:	0007871b          	sext.w	a4,a5
    8000465a:	c0dc                	sw	a5,4(s1)
    8000465c:	06e04363          	bgtz	a4,800046c2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004660:	0004a903          	lw	s2,0(s1)
    80004664:	0094ca83          	lbu	s5,9(s1)
    80004668:	0104ba03          	ld	s4,16(s1)
    8000466c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004670:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004674:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004678:	00024517          	auipc	a0,0x24
    8000467c:	d4050513          	addi	a0,a0,-704 # 800283b8 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	618080e7          	jalr	1560(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004688:	4785                	li	a5,1
    8000468a:	04f90d63          	beq	s2,a5,800046e4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000468e:	3979                	addiw	s2,s2,-2
    80004690:	4785                	li	a5,1
    80004692:	0527e063          	bltu	a5,s2,800046d2 <fileclose+0xa8>
    begin_op();
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	ac8080e7          	jalr	-1336(ra) # 8000415e <begin_op>
    iput(ff.ip);
    8000469e:	854e                	mv	a0,s3
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	2a6080e7          	jalr	678(ra) # 80003946 <iput>
    end_op();
    800046a8:	00000097          	auipc	ra,0x0
    800046ac:	b36080e7          	jalr	-1226(ra) # 800041de <end_op>
    800046b0:	a00d                	j	800046d2 <fileclose+0xa8>
    panic("fileclose");
    800046b2:	00008517          	auipc	a0,0x8
    800046b6:	21650513          	addi	a0,a0,534 # 8000c8c8 <syscalls+0x260>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	e84080e7          	jalr	-380(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046c2:	00024517          	auipc	a0,0x24
    800046c6:	cf650513          	addi	a0,a0,-778 # 800283b8 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5ce080e7          	jalr	1486(ra) # 80000c98 <release>
  }
}
    800046d2:	70e2                	ld	ra,56(sp)
    800046d4:	7442                	ld	s0,48(sp)
    800046d6:	74a2                	ld	s1,40(sp)
    800046d8:	7902                	ld	s2,32(sp)
    800046da:	69e2                	ld	s3,24(sp)
    800046dc:	6a42                	ld	s4,16(sp)
    800046de:	6aa2                	ld	s5,8(sp)
    800046e0:	6121                	addi	sp,sp,64
    800046e2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046e4:	85d6                	mv	a1,s5
    800046e6:	8552                	mv	a0,s4
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	34c080e7          	jalr	844(ra) # 80004a34 <pipeclose>
    800046f0:	b7cd                	j	800046d2 <fileclose+0xa8>

00000000800046f2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046f2:	715d                	addi	sp,sp,-80
    800046f4:	e486                	sd	ra,72(sp)
    800046f6:	e0a2                	sd	s0,64(sp)
    800046f8:	fc26                	sd	s1,56(sp)
    800046fa:	f84a                	sd	s2,48(sp)
    800046fc:	f44e                	sd	s3,40(sp)
    800046fe:	0880                	addi	s0,sp,80
    80004700:	84aa                	mv	s1,a0
    80004702:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004704:	ffffd097          	auipc	ra,0xffffd
    80004708:	408080e7          	jalr	1032(ra) # 80001b0c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000470c:	409c                	lw	a5,0(s1)
    8000470e:	37f9                	addiw	a5,a5,-2
    80004710:	4705                	li	a4,1
    80004712:	04f76763          	bltu	a4,a5,80004760 <filestat+0x6e>
    80004716:	892a                	mv	s2,a0
    ilock(f->ip);
    80004718:	6c88                	ld	a0,24(s1)
    8000471a:	fffff097          	auipc	ra,0xfffff
    8000471e:	072080e7          	jalr	114(ra) # 8000378c <ilock>
    stati(f->ip, &st);
    80004722:	fb840593          	addi	a1,s0,-72
    80004726:	6c88                	ld	a0,24(s1)
    80004728:	fffff097          	auipc	ra,0xfffff
    8000472c:	2ee080e7          	jalr	750(ra) # 80003a16 <stati>
    iunlock(f->ip);
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	11c080e7          	jalr	284(ra) # 8000384e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000473a:	46e1                	li	a3,24
    8000473c:	fb840613          	addi	a2,s0,-72
    80004740:	85ce                	mv	a1,s3
    80004742:	05093503          	ld	a0,80(s2)
    80004746:	ffffd097          	auipc	ra,0xffffd
    8000474a:	088080e7          	jalr	136(ra) # 800017ce <copyout>
    8000474e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004752:	60a6                	ld	ra,72(sp)
    80004754:	6406                	ld	s0,64(sp)
    80004756:	74e2                	ld	s1,56(sp)
    80004758:	7942                	ld	s2,48(sp)
    8000475a:	79a2                	ld	s3,40(sp)
    8000475c:	6161                	addi	sp,sp,80
    8000475e:	8082                	ret
  return -1;
    80004760:	557d                	li	a0,-1
    80004762:	bfc5                	j	80004752 <filestat+0x60>

0000000080004764 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004764:	7179                	addi	sp,sp,-48
    80004766:	f406                	sd	ra,40(sp)
    80004768:	f022                	sd	s0,32(sp)
    8000476a:	ec26                	sd	s1,24(sp)
    8000476c:	e84a                	sd	s2,16(sp)
    8000476e:	e44e                	sd	s3,8(sp)
    80004770:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004772:	00854783          	lbu	a5,8(a0)
    80004776:	c3d5                	beqz	a5,8000481a <fileread+0xb6>
    80004778:	84aa                	mv	s1,a0
    8000477a:	89ae                	mv	s3,a1
    8000477c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477e:	411c                	lw	a5,0(a0)
    80004780:	4705                	li	a4,1
    80004782:	04e78963          	beq	a5,a4,800047d4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004786:	470d                	li	a4,3
    80004788:	04e78d63          	beq	a5,a4,800047e2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000478c:	4709                	li	a4,2
    8000478e:	06e79e63          	bne	a5,a4,8000480a <fileread+0xa6>
    ilock(f->ip);
    80004792:	6d08                	ld	a0,24(a0)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	ff8080e7          	jalr	-8(ra) # 8000378c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000479c:	874a                	mv	a4,s2
    8000479e:	5094                	lw	a3,32(s1)
    800047a0:	864e                	mv	a2,s3
    800047a2:	4585                	li	a1,1
    800047a4:	6c88                	ld	a0,24(s1)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	29a080e7          	jalr	666(ra) # 80003a40 <readi>
    800047ae:	892a                	mv	s2,a0
    800047b0:	00a05563          	blez	a0,800047ba <fileread+0x56>
      f->off += r;
    800047b4:	509c                	lw	a5,32(s1)
    800047b6:	9fa9                	addw	a5,a5,a0
    800047b8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	092080e7          	jalr	146(ra) # 8000384e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047c4:	854a                	mv	a0,s2
    800047c6:	70a2                	ld	ra,40(sp)
    800047c8:	7402                	ld	s0,32(sp)
    800047ca:	64e2                	ld	s1,24(sp)
    800047cc:	6942                	ld	s2,16(sp)
    800047ce:	69a2                	ld	s3,8(sp)
    800047d0:	6145                	addi	sp,sp,48
    800047d2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047d4:	6908                	ld	a0,16(a0)
    800047d6:	00000097          	auipc	ra,0x0
    800047da:	3c8080e7          	jalr	968(ra) # 80004b9e <piperead>
    800047de:	892a                	mv	s2,a0
    800047e0:	b7d5                	j	800047c4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047e2:	02451783          	lh	a5,36(a0)
    800047e6:	03079693          	slli	a3,a5,0x30
    800047ea:	92c1                	srli	a3,a3,0x30
    800047ec:	4725                	li	a4,9
    800047ee:	02d76863          	bltu	a4,a3,8000481e <fileread+0xba>
    800047f2:	0792                	slli	a5,a5,0x4
    800047f4:	00024717          	auipc	a4,0x24
    800047f8:	b2470713          	addi	a4,a4,-1244 # 80028318 <devsw>
    800047fc:	97ba                	add	a5,a5,a4
    800047fe:	639c                	ld	a5,0(a5)
    80004800:	c38d                	beqz	a5,80004822 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004802:	4505                	li	a0,1
    80004804:	9782                	jalr	a5
    80004806:	892a                	mv	s2,a0
    80004808:	bf75                	j	800047c4 <fileread+0x60>
    panic("fileread");
    8000480a:	00008517          	auipc	a0,0x8
    8000480e:	0ce50513          	addi	a0,a0,206 # 8000c8d8 <syscalls+0x270>
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
    return -1;
    8000481a:	597d                	li	s2,-1
    8000481c:	b765                	j	800047c4 <fileread+0x60>
      return -1;
    8000481e:	597d                	li	s2,-1
    80004820:	b755                	j	800047c4 <fileread+0x60>
    80004822:	597d                	li	s2,-1
    80004824:	b745                	j	800047c4 <fileread+0x60>

0000000080004826 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004826:	715d                	addi	sp,sp,-80
    80004828:	e486                	sd	ra,72(sp)
    8000482a:	e0a2                	sd	s0,64(sp)
    8000482c:	fc26                	sd	s1,56(sp)
    8000482e:	f84a                	sd	s2,48(sp)
    80004830:	f44e                	sd	s3,40(sp)
    80004832:	f052                	sd	s4,32(sp)
    80004834:	ec56                	sd	s5,24(sp)
    80004836:	e85a                	sd	s6,16(sp)
    80004838:	e45e                	sd	s7,8(sp)
    8000483a:	e062                	sd	s8,0(sp)
    8000483c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000483e:	00954783          	lbu	a5,9(a0)
    80004842:	10078663          	beqz	a5,8000494e <filewrite+0x128>
    80004846:	892a                	mv	s2,a0
    80004848:	8aae                	mv	s5,a1
    8000484a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484c:	411c                	lw	a5,0(a0)
    8000484e:	4705                	li	a4,1
    80004850:	02e78263          	beq	a5,a4,80004874 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004854:	470d                	li	a4,3
    80004856:	02e78663          	beq	a5,a4,80004882 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000485a:	4709                	li	a4,2
    8000485c:	0ee79163          	bne	a5,a4,8000493e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004860:	0ac05d63          	blez	a2,8000491a <filewrite+0xf4>
    int i = 0;
    80004864:	4981                	li	s3,0
    80004866:	6b05                	lui	s6,0x1
    80004868:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000486c:	6b85                	lui	s7,0x1
    8000486e:	c00b8b9b          	addiw	s7,s7,-1024
    80004872:	a861                	j	8000490a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004874:	6908                	ld	a0,16(a0)
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	22e080e7          	jalr	558(ra) # 80004aa4 <pipewrite>
    8000487e:	8a2a                	mv	s4,a0
    80004880:	a045                	j	80004920 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004882:	02451783          	lh	a5,36(a0)
    80004886:	03079693          	slli	a3,a5,0x30
    8000488a:	92c1                	srli	a3,a3,0x30
    8000488c:	4725                	li	a4,9
    8000488e:	0cd76263          	bltu	a4,a3,80004952 <filewrite+0x12c>
    80004892:	0792                	slli	a5,a5,0x4
    80004894:	00024717          	auipc	a4,0x24
    80004898:	a8470713          	addi	a4,a4,-1404 # 80028318 <devsw>
    8000489c:	97ba                	add	a5,a5,a4
    8000489e:	679c                	ld	a5,8(a5)
    800048a0:	cbdd                	beqz	a5,80004956 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048a2:	4505                	li	a0,1
    800048a4:	9782                	jalr	a5
    800048a6:	8a2a                	mv	s4,a0
    800048a8:	a8a5                	j	80004920 <filewrite+0xfa>
    800048aa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	8b0080e7          	jalr	-1872(ra) # 8000415e <begin_op>
      ilock(f->ip);
    800048b6:	01893503          	ld	a0,24(s2)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	ed2080e7          	jalr	-302(ra) # 8000378c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048c2:	8762                	mv	a4,s8
    800048c4:	02092683          	lw	a3,32(s2)
    800048c8:	01598633          	add	a2,s3,s5
    800048cc:	4585                	li	a1,1
    800048ce:	01893503          	ld	a0,24(s2)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	266080e7          	jalr	614(ra) # 80003b38 <writei>
    800048da:	84aa                	mv	s1,a0
    800048dc:	00a05763          	blez	a0,800048ea <filewrite+0xc4>
        f->off += r;
    800048e0:	02092783          	lw	a5,32(s2)
    800048e4:	9fa9                	addw	a5,a5,a0
    800048e6:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048ea:	01893503          	ld	a0,24(s2)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	f60080e7          	jalr	-160(ra) # 8000384e <iunlock>
      end_op();
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	8e8080e7          	jalr	-1816(ra) # 800041de <end_op>

      if(r != n1){
    800048fe:	009c1f63          	bne	s8,s1,8000491c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004902:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004906:	0149db63          	bge	s3,s4,8000491c <filewrite+0xf6>
      int n1 = n - i;
    8000490a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000490e:	84be                	mv	s1,a5
    80004910:	2781                	sext.w	a5,a5
    80004912:	f8fb5ce3          	bge	s6,a5,800048aa <filewrite+0x84>
    80004916:	84de                	mv	s1,s7
    80004918:	bf49                	j	800048aa <filewrite+0x84>
    int i = 0;
    8000491a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000491c:	013a1f63          	bne	s4,s3,8000493a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004920:	8552                	mv	a0,s4
    80004922:	60a6                	ld	ra,72(sp)
    80004924:	6406                	ld	s0,64(sp)
    80004926:	74e2                	ld	s1,56(sp)
    80004928:	7942                	ld	s2,48(sp)
    8000492a:	79a2                	ld	s3,40(sp)
    8000492c:	7a02                	ld	s4,32(sp)
    8000492e:	6ae2                	ld	s5,24(sp)
    80004930:	6b42                	ld	s6,16(sp)
    80004932:	6ba2                	ld	s7,8(sp)
    80004934:	6c02                	ld	s8,0(sp)
    80004936:	6161                	addi	sp,sp,80
    80004938:	8082                	ret
    ret = (i == n ? n : -1);
    8000493a:	5a7d                	li	s4,-1
    8000493c:	b7d5                	j	80004920 <filewrite+0xfa>
    panic("filewrite");
    8000493e:	00008517          	auipc	a0,0x8
    80004942:	faa50513          	addi	a0,a0,-86 # 8000c8e8 <syscalls+0x280>
    80004946:	ffffc097          	auipc	ra,0xffffc
    8000494a:	bf8080e7          	jalr	-1032(ra) # 8000053e <panic>
    return -1;
    8000494e:	5a7d                	li	s4,-1
    80004950:	bfc1                	j	80004920 <filewrite+0xfa>
      return -1;
    80004952:	5a7d                	li	s4,-1
    80004954:	b7f1                	j	80004920 <filewrite+0xfa>
    80004956:	5a7d                	li	s4,-1
    80004958:	b7e1                	j	80004920 <filewrite+0xfa>

000000008000495a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000495a:	7179                	addi	sp,sp,-48
    8000495c:	f406                	sd	ra,40(sp)
    8000495e:	f022                	sd	s0,32(sp)
    80004960:	ec26                	sd	s1,24(sp)
    80004962:	e84a                	sd	s2,16(sp)
    80004964:	e44e                	sd	s3,8(sp)
    80004966:	e052                	sd	s4,0(sp)
    80004968:	1800                	addi	s0,sp,48
    8000496a:	84aa                	mv	s1,a0
    8000496c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496e:	0005b023          	sd	zero,0(a1)
    80004972:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	bf8080e7          	jalr	-1032(ra) # 8000456e <filealloc>
    8000497e:	e088                	sd	a0,0(s1)
    80004980:	c551                	beqz	a0,80004a0c <pipealloc+0xb2>
    80004982:	00000097          	auipc	ra,0x0
    80004986:	bec080e7          	jalr	-1044(ra) # 8000456e <filealloc>
    8000498a:	00aa3023          	sd	a0,0(s4)
    8000498e:	c92d                	beqz	a0,80004a00 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	164080e7          	jalr	356(ra) # 80000af4 <kalloc>
    80004998:	892a                	mv	s2,a0
    8000499a:	c125                	beqz	a0,800049fa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000499c:	4985                	li	s3,1
    8000499e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049aa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ae:	00008597          	auipc	a1,0x8
    800049b2:	f4a58593          	addi	a1,a1,-182 # 8000c8f8 <syscalls+0x290>
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	19e080e7          	jalr	414(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049be:	609c                	ld	a5,0(s1)
    800049c0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c4:	609c                	ld	a5,0(s1)
    800049c6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049ca:	609c                	ld	a5,0(s1)
    800049cc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d6:	000a3783          	ld	a5,0(s4)
    800049da:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049de:	000a3783          	ld	a5,0(s4)
    800049e2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e6:	000a3783          	ld	a5,0(s4)
    800049ea:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ee:	000a3783          	ld	a5,0(s4)
    800049f2:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f6:	4501                	li	a0,0
    800049f8:	a025                	j	80004a20 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049fa:	6088                	ld	a0,0(s1)
    800049fc:	e501                	bnez	a0,80004a04 <pipealloc+0xaa>
    800049fe:	a039                	j	80004a0c <pipealloc+0xb2>
    80004a00:	6088                	ld	a0,0(s1)
    80004a02:	c51d                	beqz	a0,80004a30 <pipealloc+0xd6>
    fileclose(*f0);
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	c26080e7          	jalr	-986(ra) # 8000462a <fileclose>
  if(*f1)
    80004a0c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a10:	557d                	li	a0,-1
  if(*f1)
    80004a12:	c799                	beqz	a5,80004a20 <pipealloc+0xc6>
    fileclose(*f1);
    80004a14:	853e                	mv	a0,a5
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	c14080e7          	jalr	-1004(ra) # 8000462a <fileclose>
  return -1;
    80004a1e:	557d                	li	a0,-1
}
    80004a20:	70a2                	ld	ra,40(sp)
    80004a22:	7402                	ld	s0,32(sp)
    80004a24:	64e2                	ld	s1,24(sp)
    80004a26:	6942                	ld	s2,16(sp)
    80004a28:	69a2                	ld	s3,8(sp)
    80004a2a:	6a02                	ld	s4,0(sp)
    80004a2c:	6145                	addi	sp,sp,48
    80004a2e:	8082                	ret
  return -1;
    80004a30:	557d                	li	a0,-1
    80004a32:	b7fd                	j	80004a20 <pipealloc+0xc6>

0000000080004a34 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a34:	1101                	addi	sp,sp,-32
    80004a36:	ec06                	sd	ra,24(sp)
    80004a38:	e822                	sd	s0,16(sp)
    80004a3a:	e426                	sd	s1,8(sp)
    80004a3c:	e04a                	sd	s2,0(sp)
    80004a3e:	1000                	addi	s0,sp,32
    80004a40:	84aa                	mv	s1,a0
    80004a42:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  if(writable){
    80004a4c:	02090d63          	beqz	s2,80004a86 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a50:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a54:	21848513          	addi	a0,s1,536
    80004a58:	ffffe097          	auipc	ra,0xffffe
    80004a5c:	930080e7          	jalr	-1744(ra) # 80002388 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a60:	2204b783          	ld	a5,544(s1)
    80004a64:	eb95                	bnez	a5,80004a98 <pipeclose+0x64>
    release(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	230080e7          	jalr	560(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a70:	8526                	mv	a0,s1
    80004a72:	ffffc097          	auipc	ra,0xffffc
    80004a76:	f86080e7          	jalr	-122(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a7a:	60e2                	ld	ra,24(sp)
    80004a7c:	6442                	ld	s0,16(sp)
    80004a7e:	64a2                	ld	s1,8(sp)
    80004a80:	6902                	ld	s2,0(sp)
    80004a82:	6105                	addi	sp,sp,32
    80004a84:	8082                	ret
    pi->readopen = 0;
    80004a86:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a8a:	21c48513          	addi	a0,s1,540
    80004a8e:	ffffe097          	auipc	ra,0xffffe
    80004a92:	8fa080e7          	jalr	-1798(ra) # 80002388 <wakeup>
    80004a96:	b7e9                	j	80004a60 <pipeclose+0x2c>
    release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1fe080e7          	jalr	510(ra) # 80000c98 <release>
}
    80004aa2:	bfe1                	j	80004a7a <pipeclose+0x46>

0000000080004aa4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa4:	7159                	addi	sp,sp,-112
    80004aa6:	f486                	sd	ra,104(sp)
    80004aa8:	f0a2                	sd	s0,96(sp)
    80004aaa:	eca6                	sd	s1,88(sp)
    80004aac:	e8ca                	sd	s2,80(sp)
    80004aae:	e4ce                	sd	s3,72(sp)
    80004ab0:	e0d2                	sd	s4,64(sp)
    80004ab2:	fc56                	sd	s5,56(sp)
    80004ab4:	f85a                	sd	s6,48(sp)
    80004ab6:	f45e                	sd	s7,40(sp)
    80004ab8:	f062                	sd	s8,32(sp)
    80004aba:	ec66                	sd	s9,24(sp)
    80004abc:	1880                	addi	s0,sp,112
    80004abe:	84aa                	mv	s1,a0
    80004ac0:	8aae                	mv	s5,a1
    80004ac2:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	048080e7          	jalr	72(ra) # 80001b0c <myproc>
    80004acc:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	114080e7          	jalr	276(ra) # 80000be4 <acquire>
  while(i < n){
    80004ad8:	0d405163          	blez	s4,80004b9a <pipewrite+0xf6>
    80004adc:	8ba6                	mv	s7,s1
  int i = 0;
    80004ade:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae0:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ae2:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ae6:	21c48c13          	addi	s8,s1,540
    80004aea:	a08d                	j	80004b4c <pipewrite+0xa8>
      release(&pi->lock);
    80004aec:	8526                	mv	a0,s1
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	1aa080e7          	jalr	426(ra) # 80000c98 <release>
      return -1;
    80004af6:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004af8:	854a                	mv	a0,s2
    80004afa:	70a6                	ld	ra,104(sp)
    80004afc:	7406                	ld	s0,96(sp)
    80004afe:	64e6                	ld	s1,88(sp)
    80004b00:	6946                	ld	s2,80(sp)
    80004b02:	69a6                	ld	s3,72(sp)
    80004b04:	6a06                	ld	s4,64(sp)
    80004b06:	7ae2                	ld	s5,56(sp)
    80004b08:	7b42                	ld	s6,48(sp)
    80004b0a:	7ba2                	ld	s7,40(sp)
    80004b0c:	7c02                	ld	s8,32(sp)
    80004b0e:	6ce2                	ld	s9,24(sp)
    80004b10:	6165                	addi	sp,sp,112
    80004b12:	8082                	ret
      wakeup(&pi->nread);
    80004b14:	8566                	mv	a0,s9
    80004b16:	ffffe097          	auipc	ra,0xffffe
    80004b1a:	872080e7          	jalr	-1934(ra) # 80002388 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b1e:	85de                	mv	a1,s7
    80004b20:	8562                	mv	a0,s8
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	6da080e7          	jalr	1754(ra) # 800021fc <sleep>
    80004b2a:	a839                	j	80004b48 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b2c:	21c4a783          	lw	a5,540(s1)
    80004b30:	0017871b          	addiw	a4,a5,1
    80004b34:	20e4ae23          	sw	a4,540(s1)
    80004b38:	1ff7f793          	andi	a5,a5,511
    80004b3c:	97a6                	add	a5,a5,s1
    80004b3e:	f9f44703          	lbu	a4,-97(s0)
    80004b42:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b46:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b48:	03495d63          	bge	s2,s4,80004b82 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b4c:	2204a783          	lw	a5,544(s1)
    80004b50:	dfd1                	beqz	a5,80004aec <pipewrite+0x48>
    80004b52:	0289a783          	lw	a5,40(s3)
    80004b56:	fbd9                	bnez	a5,80004aec <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b58:	2184a783          	lw	a5,536(s1)
    80004b5c:	21c4a703          	lw	a4,540(s1)
    80004b60:	2007879b          	addiw	a5,a5,512
    80004b64:	faf708e3          	beq	a4,a5,80004b14 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b68:	4685                	li	a3,1
    80004b6a:	01590633          	add	a2,s2,s5
    80004b6e:	f9f40593          	addi	a1,s0,-97
    80004b72:	0509b503          	ld	a0,80(s3)
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	ce4080e7          	jalr	-796(ra) # 8000185a <copyin>
    80004b7e:	fb6517e3          	bne	a0,s6,80004b2c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b82:	21848513          	addi	a0,s1,536
    80004b86:	ffffe097          	auipc	ra,0xffffe
    80004b8a:	802080e7          	jalr	-2046(ra) # 80002388 <wakeup>
  release(&pi->lock);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	108080e7          	jalr	264(ra) # 80000c98 <release>
  return i;
    80004b98:	b785                	j	80004af8 <pipewrite+0x54>
  int i = 0;
    80004b9a:	4901                	li	s2,0
    80004b9c:	b7dd                	j	80004b82 <pipewrite+0xde>

0000000080004b9e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b9e:	715d                	addi	sp,sp,-80
    80004ba0:	e486                	sd	ra,72(sp)
    80004ba2:	e0a2                	sd	s0,64(sp)
    80004ba4:	fc26                	sd	s1,56(sp)
    80004ba6:	f84a                	sd	s2,48(sp)
    80004ba8:	f44e                	sd	s3,40(sp)
    80004baa:	f052                	sd	s4,32(sp)
    80004bac:	ec56                	sd	s5,24(sp)
    80004bae:	e85a                	sd	s6,16(sp)
    80004bb0:	0880                	addi	s0,sp,80
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	892e                	mv	s2,a1
    80004bb6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	f54080e7          	jalr	-172(ra) # 80001b0c <myproc>
    80004bc0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc2:	8b26                	mv	s6,s1
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	01e080e7          	jalr	30(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bce:	2184a703          	lw	a4,536(s1)
    80004bd2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bd6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bda:	02f71463          	bne	a4,a5,80004c02 <piperead+0x64>
    80004bde:	2244a783          	lw	a5,548(s1)
    80004be2:	c385                	beqz	a5,80004c02 <piperead+0x64>
    if(pr->killed){
    80004be4:	028a2783          	lw	a5,40(s4)
    80004be8:	ebc1                	bnez	a5,80004c78 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bea:	85da                	mv	a1,s6
    80004bec:	854e                	mv	a0,s3
    80004bee:	ffffd097          	auipc	ra,0xffffd
    80004bf2:	60e080e7          	jalr	1550(ra) # 800021fc <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf6:	2184a703          	lw	a4,536(s1)
    80004bfa:	21c4a783          	lw	a5,540(s1)
    80004bfe:	fef700e3          	beq	a4,a5,80004bde <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c02:	09505263          	blez	s5,80004c86 <piperead+0xe8>
    80004c06:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c08:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c0a:	2184a783          	lw	a5,536(s1)
    80004c0e:	21c4a703          	lw	a4,540(s1)
    80004c12:	02f70d63          	beq	a4,a5,80004c4c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c16:	0017871b          	addiw	a4,a5,1
    80004c1a:	20e4ac23          	sw	a4,536(s1)
    80004c1e:	1ff7f793          	andi	a5,a5,511
    80004c22:	97a6                	add	a5,a5,s1
    80004c24:	0187c783          	lbu	a5,24(a5)
    80004c28:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c2c:	4685                	li	a3,1
    80004c2e:	fbf40613          	addi	a2,s0,-65
    80004c32:	85ca                	mv	a1,s2
    80004c34:	050a3503          	ld	a0,80(s4)
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	b96080e7          	jalr	-1130(ra) # 800017ce <copyout>
    80004c40:	01650663          	beq	a0,s6,80004c4c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c44:	2985                	addiw	s3,s3,1
    80004c46:	0905                	addi	s2,s2,1
    80004c48:	fd3a91e3          	bne	s5,s3,80004c0a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c4c:	21c48513          	addi	a0,s1,540
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	738080e7          	jalr	1848(ra) # 80002388 <wakeup>
  release(&pi->lock);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	ffffc097          	auipc	ra,0xffffc
    80004c5e:	03e080e7          	jalr	62(ra) # 80000c98 <release>
  return i;
}
    80004c62:	854e                	mv	a0,s3
    80004c64:	60a6                	ld	ra,72(sp)
    80004c66:	6406                	ld	s0,64(sp)
    80004c68:	74e2                	ld	s1,56(sp)
    80004c6a:	7942                	ld	s2,48(sp)
    80004c6c:	79a2                	ld	s3,40(sp)
    80004c6e:	7a02                	ld	s4,32(sp)
    80004c70:	6ae2                	ld	s5,24(sp)
    80004c72:	6b42                	ld	s6,16(sp)
    80004c74:	6161                	addi	sp,sp,80
    80004c76:	8082                	ret
      release(&pi->lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	01e080e7          	jalr	30(ra) # 80000c98 <release>
      return -1;
    80004c82:	59fd                	li	s3,-1
    80004c84:	bff9                	j	80004c62 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c86:	4981                	li	s3,0
    80004c88:	b7d1                	j	80004c4c <piperead+0xae>

0000000080004c8a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c8a:	df010113          	addi	sp,sp,-528
    80004c8e:	20113423          	sd	ra,520(sp)
    80004c92:	20813023          	sd	s0,512(sp)
    80004c96:	ffa6                	sd	s1,504(sp)
    80004c98:	fbca                	sd	s2,496(sp)
    80004c9a:	f7ce                	sd	s3,488(sp)
    80004c9c:	f3d2                	sd	s4,480(sp)
    80004c9e:	efd6                	sd	s5,472(sp)
    80004ca0:	ebda                	sd	s6,464(sp)
    80004ca2:	e7de                	sd	s7,456(sp)
    80004ca4:	e3e2                	sd	s8,448(sp)
    80004ca6:	ff66                	sd	s9,440(sp)
    80004ca8:	fb6a                	sd	s10,432(sp)
    80004caa:	f76e                	sd	s11,424(sp)
    80004cac:	0c00                	addi	s0,sp,528
    80004cae:	84aa                	mv	s1,a0
    80004cb0:	dea43c23          	sd	a0,-520(s0)
    80004cb4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	e54080e7          	jalr	-428(ra) # 80001b0c <myproc>
    80004cc0:	892a                	mv	s2,a0

  begin_op();
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	49c080e7          	jalr	1180(ra) # 8000415e <begin_op>

  if((ip = namei(path)) == 0){
    80004cca:	8526                	mv	a0,s1
    80004ccc:	fffff097          	auipc	ra,0xfffff
    80004cd0:	276080e7          	jalr	630(ra) # 80003f42 <namei>
    80004cd4:	c92d                	beqz	a0,80004d46 <exec+0xbc>
    80004cd6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	ab4080e7          	jalr	-1356(ra) # 8000378c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce0:	04000713          	li	a4,64
    80004ce4:	4681                	li	a3,0
    80004ce6:	e5040613          	addi	a2,s0,-432
    80004cea:	4581                	li	a1,0
    80004cec:	8526                	mv	a0,s1
    80004cee:	fffff097          	auipc	ra,0xfffff
    80004cf2:	d52080e7          	jalr	-686(ra) # 80003a40 <readi>
    80004cf6:	04000793          	li	a5,64
    80004cfa:	00f51a63          	bne	a0,a5,80004d0e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cfe:	e5042703          	lw	a4,-432(s0)
    80004d02:	464c47b7          	lui	a5,0x464c4
    80004d06:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d0a:	04f70463          	beq	a4,a5,80004d52 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	cde080e7          	jalr	-802(ra) # 800039ee <iunlockput>
    end_op();
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	4c6080e7          	jalr	1222(ra) # 800041de <end_op>
  }
  return -1;
    80004d20:	557d                	li	a0,-1
}
    80004d22:	20813083          	ld	ra,520(sp)
    80004d26:	20013403          	ld	s0,512(sp)
    80004d2a:	74fe                	ld	s1,504(sp)
    80004d2c:	795e                	ld	s2,496(sp)
    80004d2e:	79be                	ld	s3,488(sp)
    80004d30:	7a1e                	ld	s4,480(sp)
    80004d32:	6afe                	ld	s5,472(sp)
    80004d34:	6b5e                	ld	s6,464(sp)
    80004d36:	6bbe                	ld	s7,456(sp)
    80004d38:	6c1e                	ld	s8,448(sp)
    80004d3a:	7cfa                	ld	s9,440(sp)
    80004d3c:	7d5a                	ld	s10,432(sp)
    80004d3e:	7dba                	ld	s11,424(sp)
    80004d40:	21010113          	addi	sp,sp,528
    80004d44:	8082                	ret
    end_op();
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	498080e7          	jalr	1176(ra) # 800041de <end_op>
    return -1;
    80004d4e:	557d                	li	a0,-1
    80004d50:	bfc9                	j	80004d22 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d52:	854a                	mv	a0,s2
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	e7c080e7          	jalr	-388(ra) # 80001bd0 <proc_pagetable>
    80004d5c:	8baa                	mv	s7,a0
    80004d5e:	d945                	beqz	a0,80004d0e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d60:	e7042983          	lw	s3,-400(s0)
    80004d64:	e8845783          	lhu	a5,-376(s0)
    80004d68:	c7ad                	beqz	a5,80004dd2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d6a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6c:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d6e:	6c91                	lui	s9,0x4
    80004d70:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004d74:	def43823          	sd	a5,-528(s0)
    80004d78:	a42d                	j	80004fa2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d7a:	00008517          	auipc	a0,0x8
    80004d7e:	b8650513          	addi	a0,a0,-1146 # 8000c900 <syscalls+0x298>
    80004d82:	ffffb097          	auipc	ra,0xffffb
    80004d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d8a:	8756                	mv	a4,s5
    80004d8c:	012d86bb          	addw	a3,s11,s2
    80004d90:	4581                	li	a1,0
    80004d92:	8526                	mv	a0,s1
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	cac080e7          	jalr	-852(ra) # 80003a40 <readi>
    80004d9c:	2501                	sext.w	a0,a0
    80004d9e:	1aaa9963          	bne	s5,a0,80004f50 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004da2:	6791                	lui	a5,0x4
    80004da4:	0127893b          	addw	s2,a5,s2
    80004da8:	77f1                	lui	a5,0xffffc
    80004daa:	01478a3b          	addw	s4,a5,s4
    80004dae:	1f897163          	bgeu	s2,s8,80004f90 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004db2:	02091593          	slli	a1,s2,0x20
    80004db6:	9181                	srli	a1,a1,0x20
    80004db8:	95ea                	add	a1,a1,s10
    80004dba:	855e                	mv	a0,s7
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	392080e7          	jalr	914(ra) # 8000114e <walkaddr>
    80004dc4:	862a                	mv	a2,a0
    if(pa == 0)
    80004dc6:	d955                	beqz	a0,80004d7a <exec+0xf0>
      n = PGSIZE;
    80004dc8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dca:	fd9a70e3          	bgeu	s4,s9,80004d8a <exec+0x100>
      n = sz - i;
    80004dce:	8ad2                	mv	s5,s4
    80004dd0:	bf6d                	j	80004d8a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dd2:	4901                	li	s2,0
  iunlockput(ip);
    80004dd4:	8526                	mv	a0,s1
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	c18080e7          	jalr	-1000(ra) # 800039ee <iunlockput>
  end_op();
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	400080e7          	jalr	1024(ra) # 800041de <end_op>
  p = myproc();
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	d26080e7          	jalr	-730(ra) # 80001b0c <myproc>
    80004dee:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004df4:	6791                	lui	a5,0x4
    80004df6:	17fd                	addi	a5,a5,-1
    80004df8:	993e                	add	s2,s2,a5
    80004dfa:	7571                	lui	a0,0xffffc
    80004dfc:	00a977b3          	and	a5,s2,a0
    80004e00:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e04:	6621                	lui	a2,0x8
    80004e06:	963e                	add	a2,a2,a5
    80004e08:	85be                	mv	a1,a5
    80004e0a:	855e                	mv	a0,s7
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	76e080e7          	jalr	1902(ra) # 8000157a <uvmalloc>
    80004e14:	8b2a                	mv	s6,a0
  ip = 0;
    80004e16:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e18:	12050c63          	beqz	a0,80004f50 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e1c:	75e1                	lui	a1,0xffff8
    80004e1e:	95aa                	add	a1,a1,a0
    80004e20:	855e                	mv	a0,s7
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	978080e7          	jalr	-1672(ra) # 8000179a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e2a:	7c71                	lui	s8,0xffffc
    80004e2c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e2e:	e0043783          	ld	a5,-512(s0)
    80004e32:	6388                	ld	a0,0(a5)
    80004e34:	c535                	beqz	a0,80004ea0 <exec+0x216>
    80004e36:	e9040993          	addi	s3,s0,-368
    80004e3a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e3e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	024080e7          	jalr	36(ra) # 80000e64 <strlen>
    80004e48:	2505                	addiw	a0,a0,1
    80004e4a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e4e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e52:	13896363          	bltu	s2,s8,80004f78 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e56:	e0043d83          	ld	s11,-512(s0)
    80004e5a:	000dba03          	ld	s4,0(s11)
    80004e5e:	8552                	mv	a0,s4
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	004080e7          	jalr	4(ra) # 80000e64 <strlen>
    80004e68:	0015069b          	addiw	a3,a0,1
    80004e6c:	8652                	mv	a2,s4
    80004e6e:	85ca                	mv	a1,s2
    80004e70:	855e                	mv	a0,s7
    80004e72:	ffffd097          	auipc	ra,0xffffd
    80004e76:	95c080e7          	jalr	-1700(ra) # 800017ce <copyout>
    80004e7a:	10054363          	bltz	a0,80004f80 <exec+0x2f6>
    ustack[argc] = sp;
    80004e7e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e82:	0485                	addi	s1,s1,1
    80004e84:	008d8793          	addi	a5,s11,8
    80004e88:	e0f43023          	sd	a5,-512(s0)
    80004e8c:	008db503          	ld	a0,8(s11)
    80004e90:	c911                	beqz	a0,80004ea4 <exec+0x21a>
    if(argc >= MAXARG)
    80004e92:	09a1                	addi	s3,s3,8
    80004e94:	fb3c96e3          	bne	s9,s3,80004e40 <exec+0x1b6>
  sz = sz1;
    80004e98:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e9c:	4481                	li	s1,0
    80004e9e:	a84d                	j	80004f50 <exec+0x2c6>
  sp = sz;
    80004ea0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ea4:	00349793          	slli	a5,s1,0x3
    80004ea8:	f9040713          	addi	a4,s0,-112
    80004eac:	97ba                	add	a5,a5,a4
    80004eae:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004eb2:	00148693          	addi	a3,s1,1
    80004eb6:	068e                	slli	a3,a3,0x3
    80004eb8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ebc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec0:	01897663          	bgeu	s2,s8,80004ecc <exec+0x242>
  sz = sz1;
    80004ec4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec8:	4481                	li	s1,0
    80004eca:	a059                	j	80004f50 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ecc:	e9040613          	addi	a2,s0,-368
    80004ed0:	85ca                	mv	a1,s2
    80004ed2:	855e                	mv	a0,s7
    80004ed4:	ffffd097          	auipc	ra,0xffffd
    80004ed8:	8fa080e7          	jalr	-1798(ra) # 800017ce <copyout>
    80004edc:	0a054663          	bltz	a0,80004f88 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ee0:	058ab783          	ld	a5,88(s5)
    80004ee4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ee8:	df843783          	ld	a5,-520(s0)
    80004eec:	0007c703          	lbu	a4,0(a5)
    80004ef0:	cf11                	beqz	a4,80004f0c <exec+0x282>
    80004ef2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ef4:	02f00693          	li	a3,47
    80004ef8:	a039                	j	80004f06 <exec+0x27c>
      last = s+1;
    80004efa:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004efe:	0785                	addi	a5,a5,1
    80004f00:	fff7c703          	lbu	a4,-1(a5)
    80004f04:	c701                	beqz	a4,80004f0c <exec+0x282>
    if(*s == '/')
    80004f06:	fed71ce3          	bne	a4,a3,80004efe <exec+0x274>
    80004f0a:	bfc5                	j	80004efa <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f0c:	4641                	li	a2,16
    80004f0e:	df843583          	ld	a1,-520(s0)
    80004f12:	158a8513          	addi	a0,s5,344
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	f1c080e7          	jalr	-228(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f1e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f22:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f26:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f2a:	058ab783          	ld	a5,88(s5)
    80004f2e:	e6843703          	ld	a4,-408(s0)
    80004f32:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f34:	058ab783          	ld	a5,88(s5)
    80004f38:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f3c:	85ea                	mv	a1,s10
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	d2e080e7          	jalr	-722(ra) # 80001c6c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f46:	0004851b          	sext.w	a0,s1
    80004f4a:	bbe1                	j	80004d22 <exec+0x98>
    80004f4c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f50:	e0843583          	ld	a1,-504(s0)
    80004f54:	855e                	mv	a0,s7
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	d16080e7          	jalr	-746(ra) # 80001c6c <proc_freepagetable>
  if(ip){
    80004f5e:	da0498e3          	bnez	s1,80004d0e <exec+0x84>
  return -1;
    80004f62:	557d                	li	a0,-1
    80004f64:	bb7d                	j	80004d22 <exec+0x98>
    80004f66:	e1243423          	sd	s2,-504(s0)
    80004f6a:	b7dd                	j	80004f50 <exec+0x2c6>
    80004f6c:	e1243423          	sd	s2,-504(s0)
    80004f70:	b7c5                	j	80004f50 <exec+0x2c6>
    80004f72:	e1243423          	sd	s2,-504(s0)
    80004f76:	bfe9                	j	80004f50 <exec+0x2c6>
  sz = sz1;
    80004f78:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7c:	4481                	li	s1,0
    80004f7e:	bfc9                	j	80004f50 <exec+0x2c6>
  sz = sz1;
    80004f80:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f84:	4481                	li	s1,0
    80004f86:	b7e9                	j	80004f50 <exec+0x2c6>
  sz = sz1;
    80004f88:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f8c:	4481                	li	s1,0
    80004f8e:	b7c9                	j	80004f50 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f90:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f94:	2b05                	addiw	s6,s6,1
    80004f96:	0389899b          	addiw	s3,s3,56
    80004f9a:	e8845783          	lhu	a5,-376(s0)
    80004f9e:	e2fb5be3          	bge	s6,a5,80004dd4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fa2:	2981                	sext.w	s3,s3
    80004fa4:	03800713          	li	a4,56
    80004fa8:	86ce                	mv	a3,s3
    80004faa:	e1840613          	addi	a2,s0,-488
    80004fae:	4581                	li	a1,0
    80004fb0:	8526                	mv	a0,s1
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	a8e080e7          	jalr	-1394(ra) # 80003a40 <readi>
    80004fba:	03800793          	li	a5,56
    80004fbe:	f8f517e3          	bne	a0,a5,80004f4c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fc2:	e1842783          	lw	a5,-488(s0)
    80004fc6:	4705                	li	a4,1
    80004fc8:	fce796e3          	bne	a5,a4,80004f94 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fcc:	e4043603          	ld	a2,-448(s0)
    80004fd0:	e3843783          	ld	a5,-456(s0)
    80004fd4:	f8f669e3          	bltu	a2,a5,80004f66 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fd8:	e2843783          	ld	a5,-472(s0)
    80004fdc:	963e                	add	a2,a2,a5
    80004fde:	f8f667e3          	bltu	a2,a5,80004f6c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe2:	85ca                	mv	a1,s2
    80004fe4:	855e                	mv	a0,s7
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	594080e7          	jalr	1428(ra) # 8000157a <uvmalloc>
    80004fee:	e0a43423          	sd	a0,-504(s0)
    80004ff2:	d141                	beqz	a0,80004f72 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004ff4:	e2843d03          	ld	s10,-472(s0)
    80004ff8:	df043783          	ld	a5,-528(s0)
    80004ffc:	00fd77b3          	and	a5,s10,a5
    80005000:	fba1                	bnez	a5,80004f50 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005002:	e2042d83          	lw	s11,-480(s0)
    80005006:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000500a:	f80c03e3          	beqz	s8,80004f90 <exec+0x306>
    8000500e:	8a62                	mv	s4,s8
    80005010:	4901                	li	s2,0
    80005012:	b345                	j	80004db2 <exec+0x128>

0000000080005014 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005014:	7179                	addi	sp,sp,-48
    80005016:	f406                	sd	ra,40(sp)
    80005018:	f022                	sd	s0,32(sp)
    8000501a:	ec26                	sd	s1,24(sp)
    8000501c:	e84a                	sd	s2,16(sp)
    8000501e:	1800                	addi	s0,sp,48
    80005020:	892e                	mv	s2,a1
    80005022:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005024:	fdc40593          	addi	a1,s0,-36
    80005028:	ffffe097          	auipc	ra,0xffffe
    8000502c:	be0080e7          	jalr	-1056(ra) # 80002c08 <argint>
    80005030:	04054063          	bltz	a0,80005070 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005034:	fdc42703          	lw	a4,-36(s0)
    80005038:	47bd                	li	a5,15
    8000503a:	02e7ed63          	bltu	a5,a4,80005074 <argfd+0x60>
    8000503e:	ffffd097          	auipc	ra,0xffffd
    80005042:	ace080e7          	jalr	-1330(ra) # 80001b0c <myproc>
    80005046:	fdc42703          	lw	a4,-36(s0)
    8000504a:	01a70793          	addi	a5,a4,26
    8000504e:	078e                	slli	a5,a5,0x3
    80005050:	953e                	add	a0,a0,a5
    80005052:	611c                	ld	a5,0(a0)
    80005054:	c395                	beqz	a5,80005078 <argfd+0x64>
    return -1;
  if(pfd)
    80005056:	00090463          	beqz	s2,8000505e <argfd+0x4a>
    *pfd = fd;
    8000505a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000505e:	4501                	li	a0,0
  if(pf)
    80005060:	c091                	beqz	s1,80005064 <argfd+0x50>
    *pf = f;
    80005062:	e09c                	sd	a5,0(s1)
}
    80005064:	70a2                	ld	ra,40(sp)
    80005066:	7402                	ld	s0,32(sp)
    80005068:	64e2                	ld	s1,24(sp)
    8000506a:	6942                	ld	s2,16(sp)
    8000506c:	6145                	addi	sp,sp,48
    8000506e:	8082                	ret
    return -1;
    80005070:	557d                	li	a0,-1
    80005072:	bfcd                	j	80005064 <argfd+0x50>
    return -1;
    80005074:	557d                	li	a0,-1
    80005076:	b7fd                	j	80005064 <argfd+0x50>
    80005078:	557d                	li	a0,-1
    8000507a:	b7ed                	j	80005064 <argfd+0x50>

000000008000507c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000507c:	1101                	addi	sp,sp,-32
    8000507e:	ec06                	sd	ra,24(sp)
    80005080:	e822                	sd	s0,16(sp)
    80005082:	e426                	sd	s1,8(sp)
    80005084:	1000                	addi	s0,sp,32
    80005086:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005088:	ffffd097          	auipc	ra,0xffffd
    8000508c:	a84080e7          	jalr	-1404(ra) # 80001b0c <myproc>
    80005090:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005092:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc40d0>
    80005096:	4501                	li	a0,0
    80005098:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000509a:	6398                	ld	a4,0(a5)
    8000509c:	cb19                	beqz	a4,800050b2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000509e:	2505                	addiw	a0,a0,1
    800050a0:	07a1                	addi	a5,a5,8
    800050a2:	fed51ce3          	bne	a0,a3,8000509a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050a6:	557d                	li	a0,-1
}
    800050a8:	60e2                	ld	ra,24(sp)
    800050aa:	6442                	ld	s0,16(sp)
    800050ac:	64a2                	ld	s1,8(sp)
    800050ae:	6105                	addi	sp,sp,32
    800050b0:	8082                	ret
      p->ofile[fd] = f;
    800050b2:	01a50793          	addi	a5,a0,26
    800050b6:	078e                	slli	a5,a5,0x3
    800050b8:	963e                	add	a2,a2,a5
    800050ba:	e204                	sd	s1,0(a2)
      return fd;
    800050bc:	b7f5                	j	800050a8 <fdalloc+0x2c>

00000000800050be <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050be:	715d                	addi	sp,sp,-80
    800050c0:	e486                	sd	ra,72(sp)
    800050c2:	e0a2                	sd	s0,64(sp)
    800050c4:	fc26                	sd	s1,56(sp)
    800050c6:	f84a                	sd	s2,48(sp)
    800050c8:	f44e                	sd	s3,40(sp)
    800050ca:	f052                	sd	s4,32(sp)
    800050cc:	ec56                	sd	s5,24(sp)
    800050ce:	0880                	addi	s0,sp,80
    800050d0:	89ae                	mv	s3,a1
    800050d2:	8ab2                	mv	s5,a2
    800050d4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050d6:	fb040593          	addi	a1,s0,-80
    800050da:	fffff097          	auipc	ra,0xfffff
    800050de:	e86080e7          	jalr	-378(ra) # 80003f60 <nameiparent>
    800050e2:	892a                	mv	s2,a0
    800050e4:	12050f63          	beqz	a0,80005222 <create+0x164>
    return 0;

  ilock(dp);
    800050e8:	ffffe097          	auipc	ra,0xffffe
    800050ec:	6a4080e7          	jalr	1700(ra) # 8000378c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050f0:	4601                	li	a2,0
    800050f2:	fb040593          	addi	a1,s0,-80
    800050f6:	854a                	mv	a0,s2
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	b78080e7          	jalr	-1160(ra) # 80003c70 <dirlookup>
    80005100:	84aa                	mv	s1,a0
    80005102:	c921                	beqz	a0,80005152 <create+0x94>
    iunlockput(dp);
    80005104:	854a                	mv	a0,s2
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	8e8080e7          	jalr	-1816(ra) # 800039ee <iunlockput>
    ilock(ip);
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	67c080e7          	jalr	1660(ra) # 8000378c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005118:	2981                	sext.w	s3,s3
    8000511a:	4789                	li	a5,2
    8000511c:	02f99463          	bne	s3,a5,80005144 <create+0x86>
    80005120:	0444d783          	lhu	a5,68(s1)
    80005124:	37f9                	addiw	a5,a5,-2
    80005126:	17c2                	slli	a5,a5,0x30
    80005128:	93c1                	srli	a5,a5,0x30
    8000512a:	4705                	li	a4,1
    8000512c:	00f76c63          	bltu	a4,a5,80005144 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005130:	8526                	mv	a0,s1
    80005132:	60a6                	ld	ra,72(sp)
    80005134:	6406                	ld	s0,64(sp)
    80005136:	74e2                	ld	s1,56(sp)
    80005138:	7942                	ld	s2,48(sp)
    8000513a:	79a2                	ld	s3,40(sp)
    8000513c:	7a02                	ld	s4,32(sp)
    8000513e:	6ae2                	ld	s5,24(sp)
    80005140:	6161                	addi	sp,sp,80
    80005142:	8082                	ret
    iunlockput(ip);
    80005144:	8526                	mv	a0,s1
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	8a8080e7          	jalr	-1880(ra) # 800039ee <iunlockput>
    return 0;
    8000514e:	4481                	li	s1,0
    80005150:	b7c5                	j	80005130 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005152:	85ce                	mv	a1,s3
    80005154:	00092503          	lw	a0,0(s2)
    80005158:	ffffe097          	auipc	ra,0xffffe
    8000515c:	49c080e7          	jalr	1180(ra) # 800035f4 <ialloc>
    80005160:	84aa                	mv	s1,a0
    80005162:	c529                	beqz	a0,800051ac <create+0xee>
  ilock(ip);
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	628080e7          	jalr	1576(ra) # 8000378c <ilock>
  ip->major = major;
    8000516c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005170:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005174:	4785                	li	a5,1
    80005176:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000517a:	8526                	mv	a0,s1
    8000517c:	ffffe097          	auipc	ra,0xffffe
    80005180:	546080e7          	jalr	1350(ra) # 800036c2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005184:	2981                	sext.w	s3,s3
    80005186:	4785                	li	a5,1
    80005188:	02f98a63          	beq	s3,a5,800051bc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000518c:	40d0                	lw	a2,4(s1)
    8000518e:	fb040593          	addi	a1,s0,-80
    80005192:	854a                	mv	a0,s2
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	cec080e7          	jalr	-788(ra) # 80003e80 <dirlink>
    8000519c:	06054b63          	bltz	a0,80005212 <create+0x154>
  iunlockput(dp);
    800051a0:	854a                	mv	a0,s2
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	84c080e7          	jalr	-1972(ra) # 800039ee <iunlockput>
  return ip;
    800051aa:	b759                	j	80005130 <create+0x72>
    panic("create: ialloc");
    800051ac:	00007517          	auipc	a0,0x7
    800051b0:	77450513          	addi	a0,a0,1908 # 8000c920 <syscalls+0x2b8>
    800051b4:	ffffb097          	auipc	ra,0xffffb
    800051b8:	38a080e7          	jalr	906(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051bc:	04a95783          	lhu	a5,74(s2)
    800051c0:	2785                	addiw	a5,a5,1
    800051c2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051c6:	854a                	mv	a0,s2
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	4fa080e7          	jalr	1274(ra) # 800036c2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051d0:	40d0                	lw	a2,4(s1)
    800051d2:	00007597          	auipc	a1,0x7
    800051d6:	75e58593          	addi	a1,a1,1886 # 8000c930 <syscalls+0x2c8>
    800051da:	8526                	mv	a0,s1
    800051dc:	fffff097          	auipc	ra,0xfffff
    800051e0:	ca4080e7          	jalr	-860(ra) # 80003e80 <dirlink>
    800051e4:	00054f63          	bltz	a0,80005202 <create+0x144>
    800051e8:	00492603          	lw	a2,4(s2)
    800051ec:	00007597          	auipc	a1,0x7
    800051f0:	74c58593          	addi	a1,a1,1868 # 8000c938 <syscalls+0x2d0>
    800051f4:	8526                	mv	a0,s1
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	c8a080e7          	jalr	-886(ra) # 80003e80 <dirlink>
    800051fe:	f80557e3          	bgez	a0,8000518c <create+0xce>
      panic("create dots");
    80005202:	00007517          	auipc	a0,0x7
    80005206:	73e50513          	addi	a0,a0,1854 # 8000c940 <syscalls+0x2d8>
    8000520a:	ffffb097          	auipc	ra,0xffffb
    8000520e:	334080e7          	jalr	820(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005212:	00007517          	auipc	a0,0x7
    80005216:	73e50513          	addi	a0,a0,1854 # 8000c950 <syscalls+0x2e8>
    8000521a:	ffffb097          	auipc	ra,0xffffb
    8000521e:	324080e7          	jalr	804(ra) # 8000053e <panic>
    return 0;
    80005222:	84aa                	mv	s1,a0
    80005224:	b731                	j	80005130 <create+0x72>

0000000080005226 <sys_dup>:
{
    80005226:	7179                	addi	sp,sp,-48
    80005228:	f406                	sd	ra,40(sp)
    8000522a:	f022                	sd	s0,32(sp)
    8000522c:	ec26                	sd	s1,24(sp)
    8000522e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005230:	fd840613          	addi	a2,s0,-40
    80005234:	4581                	li	a1,0
    80005236:	4501                	li	a0,0
    80005238:	00000097          	auipc	ra,0x0
    8000523c:	ddc080e7          	jalr	-548(ra) # 80005014 <argfd>
    return -1;
    80005240:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005242:	02054363          	bltz	a0,80005268 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005246:	fd843503          	ld	a0,-40(s0)
    8000524a:	00000097          	auipc	ra,0x0
    8000524e:	e32080e7          	jalr	-462(ra) # 8000507c <fdalloc>
    80005252:	84aa                	mv	s1,a0
    return -1;
    80005254:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005256:	00054963          	bltz	a0,80005268 <sys_dup+0x42>
  filedup(f);
    8000525a:	fd843503          	ld	a0,-40(s0)
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	37a080e7          	jalr	890(ra) # 800045d8 <filedup>
  return fd;
    80005266:	87a6                	mv	a5,s1
}
    80005268:	853e                	mv	a0,a5
    8000526a:	70a2                	ld	ra,40(sp)
    8000526c:	7402                	ld	s0,32(sp)
    8000526e:	64e2                	ld	s1,24(sp)
    80005270:	6145                	addi	sp,sp,48
    80005272:	8082                	ret

0000000080005274 <sys_read>:
{
    80005274:	7179                	addi	sp,sp,-48
    80005276:	f406                	sd	ra,40(sp)
    80005278:	f022                	sd	s0,32(sp)
    8000527a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527c:	fe840613          	addi	a2,s0,-24
    80005280:	4581                	li	a1,0
    80005282:	4501                	li	a0,0
    80005284:	00000097          	auipc	ra,0x0
    80005288:	d90080e7          	jalr	-624(ra) # 80005014 <argfd>
    return -1;
    8000528c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528e:	04054163          	bltz	a0,800052d0 <sys_read+0x5c>
    80005292:	fe440593          	addi	a1,s0,-28
    80005296:	4509                	li	a0,2
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	970080e7          	jalr	-1680(ra) # 80002c08 <argint>
    return -1;
    800052a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	02054763          	bltz	a0,800052d0 <sys_read+0x5c>
    800052a6:	fd840593          	addi	a1,s0,-40
    800052aa:	4505                	li	a0,1
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	97e080e7          	jalr	-1666(ra) # 80002c2a <argaddr>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b6:	00054d63          	bltz	a0,800052d0 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ba:	fe442603          	lw	a2,-28(s0)
    800052be:	fd843583          	ld	a1,-40(s0)
    800052c2:	fe843503          	ld	a0,-24(s0)
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	49e080e7          	jalr	1182(ra) # 80004764 <fileread>
    800052ce:	87aa                	mv	a5,a0
}
    800052d0:	853e                	mv	a0,a5
    800052d2:	70a2                	ld	ra,40(sp)
    800052d4:	7402                	ld	s0,32(sp)
    800052d6:	6145                	addi	sp,sp,48
    800052d8:	8082                	ret

00000000800052da <sys_write>:
{
    800052da:	7179                	addi	sp,sp,-48
    800052dc:	f406                	sd	ra,40(sp)
    800052de:	f022                	sd	s0,32(sp)
    800052e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e2:	fe840613          	addi	a2,s0,-24
    800052e6:	4581                	li	a1,0
    800052e8:	4501                	li	a0,0
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	d2a080e7          	jalr	-726(ra) # 80005014 <argfd>
    return -1;
    800052f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f4:	04054163          	bltz	a0,80005336 <sys_write+0x5c>
    800052f8:	fe440593          	addi	a1,s0,-28
    800052fc:	4509                	li	a0,2
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	90a080e7          	jalr	-1782(ra) # 80002c08 <argint>
    return -1;
    80005306:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005308:	02054763          	bltz	a0,80005336 <sys_write+0x5c>
    8000530c:	fd840593          	addi	a1,s0,-40
    80005310:	4505                	li	a0,1
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	918080e7          	jalr	-1768(ra) # 80002c2a <argaddr>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	00054d63          	bltz	a0,80005336 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005320:	fe442603          	lw	a2,-28(s0)
    80005324:	fd843583          	ld	a1,-40(s0)
    80005328:	fe843503          	ld	a0,-24(s0)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	4fa080e7          	jalr	1274(ra) # 80004826 <filewrite>
    80005334:	87aa                	mv	a5,a0
}
    80005336:	853e                	mv	a0,a5
    80005338:	70a2                	ld	ra,40(sp)
    8000533a:	7402                	ld	s0,32(sp)
    8000533c:	6145                	addi	sp,sp,48
    8000533e:	8082                	ret

0000000080005340 <sys_close>:
{
    80005340:	1101                	addi	sp,sp,-32
    80005342:	ec06                	sd	ra,24(sp)
    80005344:	e822                	sd	s0,16(sp)
    80005346:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005348:	fe040613          	addi	a2,s0,-32
    8000534c:	fec40593          	addi	a1,s0,-20
    80005350:	4501                	li	a0,0
    80005352:	00000097          	auipc	ra,0x0
    80005356:	cc2080e7          	jalr	-830(ra) # 80005014 <argfd>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000535c:	02054463          	bltz	a0,80005384 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	7ac080e7          	jalr	1964(ra) # 80001b0c <myproc>
    80005368:	fec42783          	lw	a5,-20(s0)
    8000536c:	07e9                	addi	a5,a5,26
    8000536e:	078e                	slli	a5,a5,0x3
    80005370:	97aa                	add	a5,a5,a0
    80005372:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005376:	fe043503          	ld	a0,-32(s0)
    8000537a:	fffff097          	auipc	ra,0xfffff
    8000537e:	2b0080e7          	jalr	688(ra) # 8000462a <fileclose>
  return 0;
    80005382:	4781                	li	a5,0
}
    80005384:	853e                	mv	a0,a5
    80005386:	60e2                	ld	ra,24(sp)
    80005388:	6442                	ld	s0,16(sp)
    8000538a:	6105                	addi	sp,sp,32
    8000538c:	8082                	ret

000000008000538e <sys_fstat>:
{
    8000538e:	1101                	addi	sp,sp,-32
    80005390:	ec06                	sd	ra,24(sp)
    80005392:	e822                	sd	s0,16(sp)
    80005394:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005396:	fe840613          	addi	a2,s0,-24
    8000539a:	4581                	li	a1,0
    8000539c:	4501                	li	a0,0
    8000539e:	00000097          	auipc	ra,0x0
    800053a2:	c76080e7          	jalr	-906(ra) # 80005014 <argfd>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a8:	02054563          	bltz	a0,800053d2 <sys_fstat+0x44>
    800053ac:	fe040593          	addi	a1,s0,-32
    800053b0:	4505                	li	a0,1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	878080e7          	jalr	-1928(ra) # 80002c2a <argaddr>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053bc:	00054b63          	bltz	a0,800053d2 <sys_fstat+0x44>
  return filestat(f, st);
    800053c0:	fe043583          	ld	a1,-32(s0)
    800053c4:	fe843503          	ld	a0,-24(s0)
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	32a080e7          	jalr	810(ra) # 800046f2 <filestat>
    800053d0:	87aa                	mv	a5,a0
}
    800053d2:	853e                	mv	a0,a5
    800053d4:	60e2                	ld	ra,24(sp)
    800053d6:	6442                	ld	s0,16(sp)
    800053d8:	6105                	addi	sp,sp,32
    800053da:	8082                	ret

00000000800053dc <sys_link>:
{
    800053dc:	7169                	addi	sp,sp,-304
    800053de:	f606                	sd	ra,296(sp)
    800053e0:	f222                	sd	s0,288(sp)
    800053e2:	ee26                	sd	s1,280(sp)
    800053e4:	ea4a                	sd	s2,272(sp)
    800053e6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e8:	08000613          	li	a2,128
    800053ec:	ed040593          	addi	a1,s0,-304
    800053f0:	4501                	li	a0,0
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	85a080e7          	jalr	-1958(ra) # 80002c4c <argstr>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053fc:	10054e63          	bltz	a0,80005518 <sys_link+0x13c>
    80005400:	08000613          	li	a2,128
    80005404:	f5040593          	addi	a1,s0,-176
    80005408:	4505                	li	a0,1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	842080e7          	jalr	-1982(ra) # 80002c4c <argstr>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005414:	10054263          	bltz	a0,80005518 <sys_link+0x13c>
  begin_op();
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	d46080e7          	jalr	-698(ra) # 8000415e <begin_op>
  if((ip = namei(old)) == 0){
    80005420:	ed040513          	addi	a0,s0,-304
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	b1e080e7          	jalr	-1250(ra) # 80003f42 <namei>
    8000542c:	84aa                	mv	s1,a0
    8000542e:	c551                	beqz	a0,800054ba <sys_link+0xde>
  ilock(ip);
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	35c080e7          	jalr	860(ra) # 8000378c <ilock>
  if(ip->type == T_DIR){
    80005438:	04449703          	lh	a4,68(s1)
    8000543c:	4785                	li	a5,1
    8000543e:	08f70463          	beq	a4,a5,800054c6 <sys_link+0xea>
  ip->nlink++;
    80005442:	04a4d783          	lhu	a5,74(s1)
    80005446:	2785                	addiw	a5,a5,1
    80005448:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	274080e7          	jalr	628(ra) # 800036c2 <iupdate>
  iunlock(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	3f6080e7          	jalr	1014(ra) # 8000384e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005460:	fd040593          	addi	a1,s0,-48
    80005464:	f5040513          	addi	a0,s0,-176
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	af8080e7          	jalr	-1288(ra) # 80003f60 <nameiparent>
    80005470:	892a                	mv	s2,a0
    80005472:	c935                	beqz	a0,800054e6 <sys_link+0x10a>
  ilock(dp);
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	318080e7          	jalr	792(ra) # 8000378c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000547c:	00092703          	lw	a4,0(s2)
    80005480:	409c                	lw	a5,0(s1)
    80005482:	04f71d63          	bne	a4,a5,800054dc <sys_link+0x100>
    80005486:	40d0                	lw	a2,4(s1)
    80005488:	fd040593          	addi	a1,s0,-48
    8000548c:	854a                	mv	a0,s2
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	9f2080e7          	jalr	-1550(ra) # 80003e80 <dirlink>
    80005496:	04054363          	bltz	a0,800054dc <sys_link+0x100>
  iunlockput(dp);
    8000549a:	854a                	mv	a0,s2
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	552080e7          	jalr	1362(ra) # 800039ee <iunlockput>
  iput(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	4a0080e7          	jalr	1184(ra) # 80003946 <iput>
  end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	d30080e7          	jalr	-720(ra) # 800041de <end_op>
  return 0;
    800054b6:	4781                	li	a5,0
    800054b8:	a085                	j	80005518 <sys_link+0x13c>
    end_op();
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	d24080e7          	jalr	-732(ra) # 800041de <end_op>
    return -1;
    800054c2:	57fd                	li	a5,-1
    800054c4:	a891                	j	80005518 <sys_link+0x13c>
    iunlockput(ip);
    800054c6:	8526                	mv	a0,s1
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	526080e7          	jalr	1318(ra) # 800039ee <iunlockput>
    end_op();
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	d0e080e7          	jalr	-754(ra) # 800041de <end_op>
    return -1;
    800054d8:	57fd                	li	a5,-1
    800054da:	a83d                	j	80005518 <sys_link+0x13c>
    iunlockput(dp);
    800054dc:	854a                	mv	a0,s2
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	510080e7          	jalr	1296(ra) # 800039ee <iunlockput>
  ilock(ip);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	2a4080e7          	jalr	676(ra) # 8000378c <ilock>
  ip->nlink--;
    800054f0:	04a4d783          	lhu	a5,74(s1)
    800054f4:	37fd                	addiw	a5,a5,-1
    800054f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	1c6080e7          	jalr	454(ra) # 800036c2 <iupdate>
  iunlockput(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	4e8080e7          	jalr	1256(ra) # 800039ee <iunlockput>
  end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	cd0080e7          	jalr	-816(ra) # 800041de <end_op>
  return -1;
    80005516:	57fd                	li	a5,-1
}
    80005518:	853e                	mv	a0,a5
    8000551a:	70b2                	ld	ra,296(sp)
    8000551c:	7412                	ld	s0,288(sp)
    8000551e:	64f2                	ld	s1,280(sp)
    80005520:	6952                	ld	s2,272(sp)
    80005522:	6155                	addi	sp,sp,304
    80005524:	8082                	ret

0000000080005526 <sys_unlink>:
{
    80005526:	7151                	addi	sp,sp,-240
    80005528:	f586                	sd	ra,232(sp)
    8000552a:	f1a2                	sd	s0,224(sp)
    8000552c:	eda6                	sd	s1,216(sp)
    8000552e:	e9ca                	sd	s2,208(sp)
    80005530:	e5ce                	sd	s3,200(sp)
    80005532:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005534:	08000613          	li	a2,128
    80005538:	f3040593          	addi	a1,s0,-208
    8000553c:	4501                	li	a0,0
    8000553e:	ffffd097          	auipc	ra,0xffffd
    80005542:	70e080e7          	jalr	1806(ra) # 80002c4c <argstr>
    80005546:	18054163          	bltz	a0,800056c8 <sys_unlink+0x1a2>
  begin_op();
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	c14080e7          	jalr	-1004(ra) # 8000415e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005552:	fb040593          	addi	a1,s0,-80
    80005556:	f3040513          	addi	a0,s0,-208
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	a06080e7          	jalr	-1530(ra) # 80003f60 <nameiparent>
    80005562:	84aa                	mv	s1,a0
    80005564:	c979                	beqz	a0,8000563a <sys_unlink+0x114>
  ilock(dp);
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	226080e7          	jalr	550(ra) # 8000378c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000556e:	00007597          	auipc	a1,0x7
    80005572:	3c258593          	addi	a1,a1,962 # 8000c930 <syscalls+0x2c8>
    80005576:	fb040513          	addi	a0,s0,-80
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	6dc080e7          	jalr	1756(ra) # 80003c56 <namecmp>
    80005582:	14050a63          	beqz	a0,800056d6 <sys_unlink+0x1b0>
    80005586:	00007597          	auipc	a1,0x7
    8000558a:	3b258593          	addi	a1,a1,946 # 8000c938 <syscalls+0x2d0>
    8000558e:	fb040513          	addi	a0,s0,-80
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	6c4080e7          	jalr	1732(ra) # 80003c56 <namecmp>
    8000559a:	12050e63          	beqz	a0,800056d6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000559e:	f2c40613          	addi	a2,s0,-212
    800055a2:	fb040593          	addi	a1,s0,-80
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	6c8080e7          	jalr	1736(ra) # 80003c70 <dirlookup>
    800055b0:	892a                	mv	s2,a0
    800055b2:	12050263          	beqz	a0,800056d6 <sys_unlink+0x1b0>
  ilock(ip);
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	1d6080e7          	jalr	470(ra) # 8000378c <ilock>
  if(ip->nlink < 1)
    800055be:	04a91783          	lh	a5,74(s2)
    800055c2:	08f05263          	blez	a5,80005646 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055c6:	04491703          	lh	a4,68(s2)
    800055ca:	4785                	li	a5,1
    800055cc:	08f70563          	beq	a4,a5,80005656 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d0:	4641                	li	a2,16
    800055d2:	4581                	li	a1,0
    800055d4:	fc040513          	addi	a0,s0,-64
    800055d8:	ffffb097          	auipc	ra,0xffffb
    800055dc:	708080e7          	jalr	1800(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e0:	4741                	li	a4,16
    800055e2:	f2c42683          	lw	a3,-212(s0)
    800055e6:	fc040613          	addi	a2,s0,-64
    800055ea:	4581                	li	a1,0
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	54a080e7          	jalr	1354(ra) # 80003b38 <writei>
    800055f6:	47c1                	li	a5,16
    800055f8:	0af51563          	bne	a0,a5,800056a2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055fc:	04491703          	lh	a4,68(s2)
    80005600:	4785                	li	a5,1
    80005602:	0af70863          	beq	a4,a5,800056b2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	3e6080e7          	jalr	998(ra) # 800039ee <iunlockput>
  ip->nlink--;
    80005610:	04a95783          	lhu	a5,74(s2)
    80005614:	37fd                	addiw	a5,a5,-1
    80005616:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000561a:	854a                	mv	a0,s2
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	0a6080e7          	jalr	166(ra) # 800036c2 <iupdate>
  iunlockput(ip);
    80005624:	854a                	mv	a0,s2
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	3c8080e7          	jalr	968(ra) # 800039ee <iunlockput>
  end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	bb0080e7          	jalr	-1104(ra) # 800041de <end_op>
  return 0;
    80005636:	4501                	li	a0,0
    80005638:	a84d                	j	800056ea <sys_unlink+0x1c4>
    end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	ba4080e7          	jalr	-1116(ra) # 800041de <end_op>
    return -1;
    80005642:	557d                	li	a0,-1
    80005644:	a05d                	j	800056ea <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005646:	00007517          	auipc	a0,0x7
    8000564a:	31a50513          	addi	a0,a0,794 # 8000c960 <syscalls+0x2f8>
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	ef0080e7          	jalr	-272(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005656:	04c92703          	lw	a4,76(s2)
    8000565a:	02000793          	li	a5,32
    8000565e:	f6e7f9e3          	bgeu	a5,a4,800055d0 <sys_unlink+0xaa>
    80005662:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005666:	4741                	li	a4,16
    80005668:	86ce                	mv	a3,s3
    8000566a:	f1840613          	addi	a2,s0,-232
    8000566e:	4581                	li	a1,0
    80005670:	854a                	mv	a0,s2
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	3ce080e7          	jalr	974(ra) # 80003a40 <readi>
    8000567a:	47c1                	li	a5,16
    8000567c:	00f51b63          	bne	a0,a5,80005692 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005680:	f1845783          	lhu	a5,-232(s0)
    80005684:	e7a1                	bnez	a5,800056cc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005686:	29c1                	addiw	s3,s3,16
    80005688:	04c92783          	lw	a5,76(s2)
    8000568c:	fcf9ede3          	bltu	s3,a5,80005666 <sys_unlink+0x140>
    80005690:	b781                	j	800055d0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005692:	00007517          	auipc	a0,0x7
    80005696:	2e650513          	addi	a0,a0,742 # 8000c978 <syscalls+0x310>
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	ea4080e7          	jalr	-348(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056a2:	00007517          	auipc	a0,0x7
    800056a6:	2ee50513          	addi	a0,a0,750 # 8000c990 <syscalls+0x328>
    800056aa:	ffffb097          	auipc	ra,0xffffb
    800056ae:	e94080e7          	jalr	-364(ra) # 8000053e <panic>
    dp->nlink--;
    800056b2:	04a4d783          	lhu	a5,74(s1)
    800056b6:	37fd                	addiw	a5,a5,-1
    800056b8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056bc:	8526                	mv	a0,s1
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	004080e7          	jalr	4(ra) # 800036c2 <iupdate>
    800056c6:	b781                	j	80005606 <sys_unlink+0xe0>
    return -1;
    800056c8:	557d                	li	a0,-1
    800056ca:	a005                	j	800056ea <sys_unlink+0x1c4>
    iunlockput(ip);
    800056cc:	854a                	mv	a0,s2
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	320080e7          	jalr	800(ra) # 800039ee <iunlockput>
  iunlockput(dp);
    800056d6:	8526                	mv	a0,s1
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	316080e7          	jalr	790(ra) # 800039ee <iunlockput>
  end_op();
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	afe080e7          	jalr	-1282(ra) # 800041de <end_op>
  return -1;
    800056e8:	557d                	li	a0,-1
}
    800056ea:	70ae                	ld	ra,232(sp)
    800056ec:	740e                	ld	s0,224(sp)
    800056ee:	64ee                	ld	s1,216(sp)
    800056f0:	694e                	ld	s2,208(sp)
    800056f2:	69ae                	ld	s3,200(sp)
    800056f4:	616d                	addi	sp,sp,240
    800056f6:	8082                	ret

00000000800056f8 <sys_open>:

uint64
sys_open(void)
{
    800056f8:	7131                	addi	sp,sp,-192
    800056fa:	fd06                	sd	ra,184(sp)
    800056fc:	f922                	sd	s0,176(sp)
    800056fe:	f526                	sd	s1,168(sp)
    80005700:	f14a                	sd	s2,160(sp)
    80005702:	ed4e                	sd	s3,152(sp)
    80005704:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005706:	08000613          	li	a2,128
    8000570a:	f5040593          	addi	a1,s0,-176
    8000570e:	4501                	li	a0,0
    80005710:	ffffd097          	auipc	ra,0xffffd
    80005714:	53c080e7          	jalr	1340(ra) # 80002c4c <argstr>
    return -1;
    80005718:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000571a:	0c054163          	bltz	a0,800057dc <sys_open+0xe4>
    8000571e:	f4c40593          	addi	a1,s0,-180
    80005722:	4505                	li	a0,1
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	4e4080e7          	jalr	1252(ra) # 80002c08 <argint>
    8000572c:	0a054863          	bltz	a0,800057dc <sys_open+0xe4>

  begin_op();
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	a2e080e7          	jalr	-1490(ra) # 8000415e <begin_op>

  if(omode & O_CREATE){
    80005738:	f4c42783          	lw	a5,-180(s0)
    8000573c:	2007f793          	andi	a5,a5,512
    80005740:	cbdd                	beqz	a5,800057f6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005742:	4681                	li	a3,0
    80005744:	4601                	li	a2,0
    80005746:	4589                	li	a1,2
    80005748:	f5040513          	addi	a0,s0,-176
    8000574c:	00000097          	auipc	ra,0x0
    80005750:	972080e7          	jalr	-1678(ra) # 800050be <create>
    80005754:	892a                	mv	s2,a0
    if(ip == 0){
    80005756:	c959                	beqz	a0,800057ec <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005758:	04491703          	lh	a4,68(s2)
    8000575c:	478d                	li	a5,3
    8000575e:	00f71763          	bne	a4,a5,8000576c <sys_open+0x74>
    80005762:	04695703          	lhu	a4,70(s2)
    80005766:	47a5                	li	a5,9
    80005768:	0ce7ec63          	bltu	a5,a4,80005840 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	e02080e7          	jalr	-510(ra) # 8000456e <filealloc>
    80005774:	89aa                	mv	s3,a0
    80005776:	10050263          	beqz	a0,8000587a <sys_open+0x182>
    8000577a:	00000097          	auipc	ra,0x0
    8000577e:	902080e7          	jalr	-1790(ra) # 8000507c <fdalloc>
    80005782:	84aa                	mv	s1,a0
    80005784:	0e054663          	bltz	a0,80005870 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005788:	04491703          	lh	a4,68(s2)
    8000578c:	478d                	li	a5,3
    8000578e:	0cf70463          	beq	a4,a5,80005856 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005792:	4789                	li	a5,2
    80005794:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005798:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000579c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057a0:	f4c42783          	lw	a5,-180(s0)
    800057a4:	0017c713          	xori	a4,a5,1
    800057a8:	8b05                	andi	a4,a4,1
    800057aa:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ae:	0037f713          	andi	a4,a5,3
    800057b2:	00e03733          	snez	a4,a4
    800057b6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ba:	4007f793          	andi	a5,a5,1024
    800057be:	c791                	beqz	a5,800057ca <sys_open+0xd2>
    800057c0:	04491703          	lh	a4,68(s2)
    800057c4:	4789                	li	a5,2
    800057c6:	08f70f63          	beq	a4,a5,80005864 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ca:	854a                	mv	a0,s2
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	082080e7          	jalr	130(ra) # 8000384e <iunlock>
  end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	a0a080e7          	jalr	-1526(ra) # 800041de <end_op>

  return fd;
}
    800057dc:	8526                	mv	a0,s1
    800057de:	70ea                	ld	ra,184(sp)
    800057e0:	744a                	ld	s0,176(sp)
    800057e2:	74aa                	ld	s1,168(sp)
    800057e4:	790a                	ld	s2,160(sp)
    800057e6:	69ea                	ld	s3,152(sp)
    800057e8:	6129                	addi	sp,sp,192
    800057ea:	8082                	ret
      end_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	9f2080e7          	jalr	-1550(ra) # 800041de <end_op>
      return -1;
    800057f4:	b7e5                	j	800057dc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057f6:	f5040513          	addi	a0,s0,-176
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	748080e7          	jalr	1864(ra) # 80003f42 <namei>
    80005802:	892a                	mv	s2,a0
    80005804:	c905                	beqz	a0,80005834 <sys_open+0x13c>
    ilock(ip);
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	f86080e7          	jalr	-122(ra) # 8000378c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000580e:	04491703          	lh	a4,68(s2)
    80005812:	4785                	li	a5,1
    80005814:	f4f712e3          	bne	a4,a5,80005758 <sys_open+0x60>
    80005818:	f4c42783          	lw	a5,-180(s0)
    8000581c:	dba1                	beqz	a5,8000576c <sys_open+0x74>
      iunlockput(ip);
    8000581e:	854a                	mv	a0,s2
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	1ce080e7          	jalr	462(ra) # 800039ee <iunlockput>
      end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	9b6080e7          	jalr	-1610(ra) # 800041de <end_op>
      return -1;
    80005830:	54fd                	li	s1,-1
    80005832:	b76d                	j	800057dc <sys_open+0xe4>
      end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	9aa080e7          	jalr	-1622(ra) # 800041de <end_op>
      return -1;
    8000583c:	54fd                	li	s1,-1
    8000583e:	bf79                	j	800057dc <sys_open+0xe4>
    iunlockput(ip);
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	1ac080e7          	jalr	428(ra) # 800039ee <iunlockput>
    end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	994080e7          	jalr	-1644(ra) # 800041de <end_op>
    return -1;
    80005852:	54fd                	li	s1,-1
    80005854:	b761                	j	800057dc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005856:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000585a:	04691783          	lh	a5,70(s2)
    8000585e:	02f99223          	sh	a5,36(s3)
    80005862:	bf2d                	j	8000579c <sys_open+0xa4>
    itrunc(ip);
    80005864:	854a                	mv	a0,s2
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	034080e7          	jalr	52(ra) # 8000389a <itrunc>
    8000586e:	bfb1                	j	800057ca <sys_open+0xd2>
      fileclose(f);
    80005870:	854e                	mv	a0,s3
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	db8080e7          	jalr	-584(ra) # 8000462a <fileclose>
    iunlockput(ip);
    8000587a:	854a                	mv	a0,s2
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	172080e7          	jalr	370(ra) # 800039ee <iunlockput>
    end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	95a080e7          	jalr	-1702(ra) # 800041de <end_op>
    return -1;
    8000588c:	54fd                	li	s1,-1
    8000588e:	b7b9                	j	800057dc <sys_open+0xe4>

0000000080005890 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005890:	7175                	addi	sp,sp,-144
    80005892:	e506                	sd	ra,136(sp)
    80005894:	e122                	sd	s0,128(sp)
    80005896:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	8c6080e7          	jalr	-1850(ra) # 8000415e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a0:	08000613          	li	a2,128
    800058a4:	f7040593          	addi	a1,s0,-144
    800058a8:	4501                	li	a0,0
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	3a2080e7          	jalr	930(ra) # 80002c4c <argstr>
    800058b2:	02054963          	bltz	a0,800058e4 <sys_mkdir+0x54>
    800058b6:	4681                	li	a3,0
    800058b8:	4601                	li	a2,0
    800058ba:	4585                	li	a1,1
    800058bc:	f7040513          	addi	a0,s0,-144
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	7fe080e7          	jalr	2046(ra) # 800050be <create>
    800058c8:	cd11                	beqz	a0,800058e4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	124080e7          	jalr	292(ra) # 800039ee <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	90c080e7          	jalr	-1780(ra) # 800041de <end_op>
  return 0;
    800058da:	4501                	li	a0,0
}
    800058dc:	60aa                	ld	ra,136(sp)
    800058de:	640a                	ld	s0,128(sp)
    800058e0:	6149                	addi	sp,sp,144
    800058e2:	8082                	ret
    end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	8fa080e7          	jalr	-1798(ra) # 800041de <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	b7fd                	j	800058dc <sys_mkdir+0x4c>

00000000800058f0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f0:	7135                	addi	sp,sp,-160
    800058f2:	ed06                	sd	ra,152(sp)
    800058f4:	e922                	sd	s0,144(sp)
    800058f6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	866080e7          	jalr	-1946(ra) # 8000415e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005900:	08000613          	li	a2,128
    80005904:	f7040593          	addi	a1,s0,-144
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	342080e7          	jalr	834(ra) # 80002c4c <argstr>
    80005912:	04054a63          	bltz	a0,80005966 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005916:	f6c40593          	addi	a1,s0,-148
    8000591a:	4505                	li	a0,1
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	2ec080e7          	jalr	748(ra) # 80002c08 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005924:	04054163          	bltz	a0,80005966 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005928:	f6840593          	addi	a1,s0,-152
    8000592c:	4509                	li	a0,2
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	2da080e7          	jalr	730(ra) # 80002c08 <argint>
     argint(1, &major) < 0 ||
    80005936:	02054863          	bltz	a0,80005966 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000593a:	f6841683          	lh	a3,-152(s0)
    8000593e:	f6c41603          	lh	a2,-148(s0)
    80005942:	458d                	li	a1,3
    80005944:	f7040513          	addi	a0,s0,-144
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	776080e7          	jalr	1910(ra) # 800050be <create>
     argint(2, &minor) < 0 ||
    80005950:	c919                	beqz	a0,80005966 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	09c080e7          	jalr	156(ra) # 800039ee <iunlockput>
  end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	884080e7          	jalr	-1916(ra) # 800041de <end_op>
  return 0;
    80005962:	4501                	li	a0,0
    80005964:	a031                	j	80005970 <sys_mknod+0x80>
    end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	878080e7          	jalr	-1928(ra) # 800041de <end_op>
    return -1;
    8000596e:	557d                	li	a0,-1
}
    80005970:	60ea                	ld	ra,152(sp)
    80005972:	644a                	ld	s0,144(sp)
    80005974:	610d                	addi	sp,sp,160
    80005976:	8082                	ret

0000000080005978 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005978:	7135                	addi	sp,sp,-160
    8000597a:	ed06                	sd	ra,152(sp)
    8000597c:	e922                	sd	s0,144(sp)
    8000597e:	e526                	sd	s1,136(sp)
    80005980:	e14a                	sd	s2,128(sp)
    80005982:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005984:	ffffc097          	auipc	ra,0xffffc
    80005988:	188080e7          	jalr	392(ra) # 80001b0c <myproc>
    8000598c:	892a                	mv	s2,a0
  
  begin_op();
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	7d0080e7          	jalr	2000(ra) # 8000415e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005996:	08000613          	li	a2,128
    8000599a:	f6040593          	addi	a1,s0,-160
    8000599e:	4501                	li	a0,0
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	2ac080e7          	jalr	684(ra) # 80002c4c <argstr>
    800059a8:	04054b63          	bltz	a0,800059fe <sys_chdir+0x86>
    800059ac:	f6040513          	addi	a0,s0,-160
    800059b0:	ffffe097          	auipc	ra,0xffffe
    800059b4:	592080e7          	jalr	1426(ra) # 80003f42 <namei>
    800059b8:	84aa                	mv	s1,a0
    800059ba:	c131                	beqz	a0,800059fe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	dd0080e7          	jalr	-560(ra) # 8000378c <ilock>
  if(ip->type != T_DIR){
    800059c4:	04449703          	lh	a4,68(s1)
    800059c8:	4785                	li	a5,1
    800059ca:	04f71063          	bne	a4,a5,80005a0a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ce:	8526                	mv	a0,s1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	e7e080e7          	jalr	-386(ra) # 8000384e <iunlock>
  iput(p->cwd);
    800059d8:	15093503          	ld	a0,336(s2)
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	f6a080e7          	jalr	-150(ra) # 80003946 <iput>
  end_op();
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	7fa080e7          	jalr	2042(ra) # 800041de <end_op>
  p->cwd = ip;
    800059ec:	14993823          	sd	s1,336(s2)
  return 0;
    800059f0:	4501                	li	a0,0
}
    800059f2:	60ea                	ld	ra,152(sp)
    800059f4:	644a                	ld	s0,144(sp)
    800059f6:	64aa                	ld	s1,136(sp)
    800059f8:	690a                	ld	s2,128(sp)
    800059fa:	610d                	addi	sp,sp,160
    800059fc:	8082                	ret
    end_op();
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	7e0080e7          	jalr	2016(ra) # 800041de <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	b7ed                	j	800059f2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a0a:	8526                	mv	a0,s1
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	fe2080e7          	jalr	-30(ra) # 800039ee <iunlockput>
    end_op();
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	7ca080e7          	jalr	1994(ra) # 800041de <end_op>
    return -1;
    80005a1c:	557d                	li	a0,-1
    80005a1e:	bfd1                	j	800059f2 <sys_chdir+0x7a>

0000000080005a20 <sys_exec>:

uint64
sys_exec(void)
{
    80005a20:	7145                	addi	sp,sp,-464
    80005a22:	e786                	sd	ra,456(sp)
    80005a24:	e3a2                	sd	s0,448(sp)
    80005a26:	ff26                	sd	s1,440(sp)
    80005a28:	fb4a                	sd	s2,432(sp)
    80005a2a:	f74e                	sd	s3,424(sp)
    80005a2c:	f352                	sd	s4,416(sp)
    80005a2e:	ef56                	sd	s5,408(sp)
    80005a30:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
 
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a32:	08000613          	li	a2,128
    80005a36:	f4040593          	addi	a1,s0,-192
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	210080e7          	jalr	528(ra) # 80002c4c <argstr>
    return -1;
    80005a44:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a46:	0c054a63          	bltz	a0,80005b1a <sys_exec+0xfa>
    80005a4a:	e3840593          	addi	a1,s0,-456
    80005a4e:	4505                	li	a0,1
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	1da080e7          	jalr	474(ra) # 80002c2a <argaddr>
    80005a58:	0c054163          	bltz	a0,80005b1a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a5c:	10000613          	li	a2,256
    80005a60:	4581                	li	a1,0
    80005a62:	e4040513          	addi	a0,s0,-448
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	27a080e7          	jalr	634(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a6e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a72:	89a6                	mv	s3,s1
    80005a74:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a76:	02000a13          	li	s4,32
    80005a7a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a7e:	00391513          	slli	a0,s2,0x3
    80005a82:	e3040593          	addi	a1,s0,-464
    80005a86:	e3843783          	ld	a5,-456(s0)
    80005a8a:	953e                	add	a0,a0,a5
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	0e2080e7          	jalr	226(ra) # 80002b6e <fetchaddr>
    80005a94:	02054a63          	bltz	a0,80005ac8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a98:	e3043783          	ld	a5,-464(s0)
    80005a9c:	c3b9                	beqz	a5,80005ae2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a9e:	ffffb097          	auipc	ra,0xffffb
    80005aa2:	056080e7          	jalr	86(ra) # 80000af4 <kalloc>
    80005aa6:	85aa                	mv	a1,a0
    80005aa8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aac:	cd11                	beqz	a0,80005ac8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aae:	6611                	lui	a2,0x4
    80005ab0:	e3043503          	ld	a0,-464(s0)
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	10c080e7          	jalr	268(ra) # 80002bc0 <fetchstr>
    80005abc:	00054663          	bltz	a0,80005ac8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ac0:	0905                	addi	s2,s2,1
    80005ac2:	09a1                	addi	s3,s3,8
    80005ac4:	fb491be3          	bne	s2,s4,80005a7a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac8:	10048913          	addi	s2,s1,256
    80005acc:	6088                	ld	a0,0(s1)
    80005ace:	c529                	beqz	a0,80005b18 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	f28080e7          	jalr	-216(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad8:	04a1                	addi	s1,s1,8
    80005ada:	ff2499e3          	bne	s1,s2,80005acc <sys_exec+0xac>
  return -1;
    80005ade:	597d                	li	s2,-1
    80005ae0:	a82d                	j	80005b1a <sys_exec+0xfa>
      argv[i] = 0;
    80005ae2:	0a8e                	slli	s5,s5,0x3
    80005ae4:	fc040793          	addi	a5,s0,-64
    80005ae8:	9abe                	add	s5,s5,a5
    80005aea:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005aee:	e4040593          	addi	a1,s0,-448
    80005af2:	f4040513          	addi	a0,s0,-192
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	194080e7          	jalr	404(ra) # 80004c8a <exec>
    80005afe:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b00:	10048993          	addi	s3,s1,256
    80005b04:	6088                	ld	a0,0(s1)
    80005b06:	c911                	beqz	a0,80005b1a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b08:	ffffb097          	auipc	ra,0xffffb
    80005b0c:	ef0080e7          	jalr	-272(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b10:	04a1                	addi	s1,s1,8
    80005b12:	ff3499e3          	bne	s1,s3,80005b04 <sys_exec+0xe4>
    80005b16:	a011                	j	80005b1a <sys_exec+0xfa>
  return -1;
    80005b18:	597d                	li	s2,-1
}
    80005b1a:	854a                	mv	a0,s2
    80005b1c:	60be                	ld	ra,456(sp)
    80005b1e:	641e                	ld	s0,448(sp)
    80005b20:	74fa                	ld	s1,440(sp)
    80005b22:	795a                	ld	s2,432(sp)
    80005b24:	79ba                	ld	s3,424(sp)
    80005b26:	7a1a                	ld	s4,416(sp)
    80005b28:	6afa                	ld	s5,408(sp)
    80005b2a:	6179                	addi	sp,sp,464
    80005b2c:	8082                	ret

0000000080005b2e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b2e:	7139                	addi	sp,sp,-64
    80005b30:	fc06                	sd	ra,56(sp)
    80005b32:	f822                	sd	s0,48(sp)
    80005b34:	f426                	sd	s1,40(sp)
    80005b36:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b38:	ffffc097          	auipc	ra,0xffffc
    80005b3c:	fd4080e7          	jalr	-44(ra) # 80001b0c <myproc>
    80005b40:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b42:	fd840593          	addi	a1,s0,-40
    80005b46:	4501                	li	a0,0
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	0e2080e7          	jalr	226(ra) # 80002c2a <argaddr>
    return -1;
    80005b50:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b52:	0e054063          	bltz	a0,80005c32 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b56:	fc840593          	addi	a1,s0,-56
    80005b5a:	fd040513          	addi	a0,s0,-48
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	dfc080e7          	jalr	-516(ra) # 8000495a <pipealloc>
    return -1;
    80005b66:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b68:	0c054563          	bltz	a0,80005c32 <sys_pipe+0x104>
  fd0 = -1;
    80005b6c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b70:	fd043503          	ld	a0,-48(s0)
    80005b74:	fffff097          	auipc	ra,0xfffff
    80005b78:	508080e7          	jalr	1288(ra) # 8000507c <fdalloc>
    80005b7c:	fca42223          	sw	a0,-60(s0)
    80005b80:	08054c63          	bltz	a0,80005c18 <sys_pipe+0xea>
    80005b84:	fc843503          	ld	a0,-56(s0)
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	4f4080e7          	jalr	1268(ra) # 8000507c <fdalloc>
    80005b90:	fca42023          	sw	a0,-64(s0)
    80005b94:	06054863          	bltz	a0,80005c04 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b98:	4691                	li	a3,4
    80005b9a:	fc440613          	addi	a2,s0,-60
    80005b9e:	fd843583          	ld	a1,-40(s0)
    80005ba2:	68a8                	ld	a0,80(s1)
    80005ba4:	ffffc097          	auipc	ra,0xffffc
    80005ba8:	c2a080e7          	jalr	-982(ra) # 800017ce <copyout>
    80005bac:	02054063          	bltz	a0,80005bcc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bb0:	4691                	li	a3,4
    80005bb2:	fc040613          	addi	a2,s0,-64
    80005bb6:	fd843583          	ld	a1,-40(s0)
    80005bba:	0591                	addi	a1,a1,4
    80005bbc:	68a8                	ld	a0,80(s1)
    80005bbe:	ffffc097          	auipc	ra,0xffffc
    80005bc2:	c10080e7          	jalr	-1008(ra) # 800017ce <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bc6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc8:	06055563          	bgez	a0,80005c32 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bcc:	fc442783          	lw	a5,-60(s0)
    80005bd0:	07e9                	addi	a5,a5,26
    80005bd2:	078e                	slli	a5,a5,0x3
    80005bd4:	97a6                	add	a5,a5,s1
    80005bd6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bda:	fc042503          	lw	a0,-64(s0)
    80005bde:	0569                	addi	a0,a0,26
    80005be0:	050e                	slli	a0,a0,0x3
    80005be2:	9526                	add	a0,a0,s1
    80005be4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005be8:	fd043503          	ld	a0,-48(s0)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	a3e080e7          	jalr	-1474(ra) # 8000462a <fileclose>
    fileclose(wf);
    80005bf4:	fc843503          	ld	a0,-56(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	a32080e7          	jalr	-1486(ra) # 8000462a <fileclose>
    return -1;
    80005c00:	57fd                	li	a5,-1
    80005c02:	a805                	j	80005c32 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c04:	fc442783          	lw	a5,-60(s0)
    80005c08:	0007c863          	bltz	a5,80005c18 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c0c:	01a78513          	addi	a0,a5,26
    80005c10:	050e                	slli	a0,a0,0x3
    80005c12:	9526                	add	a0,a0,s1
    80005c14:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c18:	fd043503          	ld	a0,-48(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	a0e080e7          	jalr	-1522(ra) # 8000462a <fileclose>
    fileclose(wf);
    80005c24:	fc843503          	ld	a0,-56(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	a02080e7          	jalr	-1534(ra) # 8000462a <fileclose>
    return -1;
    80005c30:	57fd                	li	a5,-1
}
    80005c32:	853e                	mv	a0,a5
    80005c34:	70e2                	ld	ra,56(sp)
    80005c36:	7442                	ld	s0,48(sp)
    80005c38:	74a2                	ld	s1,40(sp)
    80005c3a:	6121                	addi	sp,sp,64
    80005c3c:	8082                	ret

0000000080005c3e <sys_mmtrace>:

uint64 sys_mmtrace(void){
    80005c3e:	1101                	addi	sp,sp,-32
    80005c40:	ec06                	sd	ra,24(sp)
    80005c42:	e822                	sd	s0,16(sp)
    80005c44:	1000                	addi	s0,sp,32
	uint64 va;
	argaddr(0,&va);
    80005c46:	fe840593          	addi	a1,s0,-24
    80005c4a:	4501                	li	a0,0
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	fde080e7          	jalr	-34(ra) # 80002c2a <argaddr>

	printf("tracing virtual address %x:\n",va);
    80005c54:	fe843583          	ld	a1,-24(s0)
    80005c58:	00007517          	auipc	a0,0x7
    80005c5c:	d4850513          	addi	a0,a0,-696 # 8000c9a0 <syscalls+0x338>
    80005c60:	ffffb097          	auipc	ra,0xffffb
    80005c64:	928080e7          	jalr	-1752(ra) # 80000588 <printf>
	struct proc *p = myproc();
    80005c68:	ffffc097          	auipc	ra,0xffffc
    80005c6c:	ea4080e7          	jalr	-348(ra) # 80001b0c <myproc>
	trace_mem(p->pagetable,va);
    80005c70:	fe843583          	ld	a1,-24(s0)
    80005c74:	6928                	ld	a0,80(a0)
    80005c76:	ffffb097          	auipc	ra,0xffffb
    80005c7a:	4bc080e7          	jalr	1212(ra) # 80001132 <trace_mem>
	return 0;
}
    80005c7e:	4501                	li	a0,0
    80005c80:	60e2                	ld	ra,24(sp)
    80005c82:	6442                	ld	s0,16(sp)
    80005c84:	6105                	addi	sp,sp,32
    80005c86:	8082                	ret
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	d6bfc0ef          	jal	ra,80002a3a <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	6d0c                	ld	a1,24(a0)
    80005d2c:	7110                	ld	a2,32(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	d78080e7          	jalr	-648(ra) # 80001ae0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	953e                	add	a0,a0,a5
    80005d8c:	00052023          	sw	zero,0(a0)
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	d40080e7          	jalr	-704(ra) # 80001ae0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5179b          	slliw	a5,a0,0xd
    80005dac:	0c201537          	lui	a0,0xc201
    80005db0:	953e                	add	a0,a0,a5
  return irq;
}
    80005db2:	4148                	lw	a0,4(a0)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	d18080e7          	jalr	-744(ra) # 80001ae0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	06a7c963          	blt	a5,a0,80005e62 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005df4:	00026797          	auipc	a5,0x26
    80005df8:	20c78793          	addi	a5,a5,524 # 8002c000 <disk>
    80005dfc:	00a78733          	add	a4,a5,a0
    80005e00:	67a1                	lui	a5,0x8
    80005e02:	97ba                	add	a5,a5,a4
    80005e04:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005e08:	e7ad                	bnez	a5,80005e72 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e0a:	00451793          	slli	a5,a0,0x4
    80005e0e:	0002e717          	auipc	a4,0x2e
    80005e12:	1f270713          	addi	a4,a4,498 # 80034000 <disk+0x8000>
    80005e16:	6314                	ld	a3,0(a4)
    80005e18:	96be                	add	a3,a3,a5
    80005e1a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e1e:	6314                	ld	a3,0(a4)
    80005e20:	96be                	add	a3,a3,a5
    80005e22:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e26:	6314                	ld	a3,0(a4)
    80005e28:	96be                	add	a3,a3,a5
    80005e2a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e2e:	6318                	ld	a4,0(a4)
    80005e30:	97ba                	add	a5,a5,a4
    80005e32:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e36:	00026797          	auipc	a5,0x26
    80005e3a:	1ca78793          	addi	a5,a5,458 # 8002c000 <disk>
    80005e3e:	97aa                	add	a5,a5,a0
    80005e40:	6521                	lui	a0,0x8
    80005e42:	953e                	add	a0,a0,a5
    80005e44:	4785                	li	a5,1
    80005e46:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005e4a:	0002e517          	auipc	a0,0x2e
    80005e4e:	1ce50513          	addi	a0,a0,462 # 80034018 <disk+0x8018>
    80005e52:	ffffc097          	auipc	ra,0xffffc
    80005e56:	536080e7          	jalr	1334(ra) # 80002388 <wakeup>
}
    80005e5a:	60a2                	ld	ra,8(sp)
    80005e5c:	6402                	ld	s0,0(sp)
    80005e5e:	0141                	addi	sp,sp,16
    80005e60:	8082                	ret
    panic("free_desc 1");
    80005e62:	00007517          	auipc	a0,0x7
    80005e66:	b5e50513          	addi	a0,a0,-1186 # 8000c9c0 <syscalls+0x358>
    80005e6a:	ffffa097          	auipc	ra,0xffffa
    80005e6e:	6d4080e7          	jalr	1748(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e72:	00007517          	auipc	a0,0x7
    80005e76:	b5e50513          	addi	a0,a0,-1186 # 8000c9d0 <syscalls+0x368>
    80005e7a:	ffffa097          	auipc	ra,0xffffa
    80005e7e:	6c4080e7          	jalr	1732(ra) # 8000053e <panic>

0000000080005e82 <virtio_disk_init>:
{
    80005e82:	1101                	addi	sp,sp,-32
    80005e84:	ec06                	sd	ra,24(sp)
    80005e86:	e822                	sd	s0,16(sp)
    80005e88:	e426                	sd	s1,8(sp)
    80005e8a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e8c:	00007597          	auipc	a1,0x7
    80005e90:	b5458593          	addi	a1,a1,-1196 # 8000c9e0 <syscalls+0x378>
    80005e94:	0002e517          	auipc	a0,0x2e
    80005e98:	29450513          	addi	a0,a0,660 # 80034128 <disk+0x8128>
    80005e9c:	ffffb097          	auipc	ra,0xffffb
    80005ea0:	cb8080e7          	jalr	-840(ra) # 80000b54 <initlock>
	  printf("%x %x %x %x\n",
    80005ea4:	100014b7          	lui	s1,0x10001
    80005ea8:	408c                	lw	a1,0(s1)
    80005eaa:	40d0                	lw	a2,4(s1)
    80005eac:	4494                	lw	a3,8(s1)
    80005eae:	44d8                	lw	a4,12(s1)
    80005eb0:	2701                	sext.w	a4,a4
    80005eb2:	2681                	sext.w	a3,a3
    80005eb4:	2601                	sext.w	a2,a2
    80005eb6:	2581                	sext.w	a1,a1
    80005eb8:	00007517          	auipc	a0,0x7
    80005ebc:	b3850513          	addi	a0,a0,-1224 # 8000c9f0 <syscalls+0x388>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	6c8080e7          	jalr	1736(ra) # 80000588 <printf>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec8:	4098                	lw	a4,0(s1)
    80005eca:	2701                	sext.w	a4,a4
    80005ecc:	747277b7          	lui	a5,0x74727
    80005ed0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ed4:	0ef71163          	bne	a4,a5,80005fb6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ed8:	100017b7          	lui	a5,0x10001
    80005edc:	43dc                	lw	a5,4(a5)
    80005ede:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee0:	4705                	li	a4,1
    80005ee2:	0ce79a63          	bne	a5,a4,80005fb6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee6:	100017b7          	lui	a5,0x10001
    80005eea:	479c                	lw	a5,8(a5)
    80005eec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eee:	4709                	li	a4,2
    80005ef0:	0ce79363          	bne	a5,a4,80005fb6 <virtio_disk_init+0x134>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ef4:	100017b7          	lui	a5,0x10001
    80005ef8:	47d8                	lw	a4,12(a5)
    80005efa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005efc:	554d47b7          	lui	a5,0x554d4
    80005f00:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f04:	0af71963          	bne	a4,a5,80005fb6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	4705                	li	a4,1
    80005f0e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f10:	470d                	li	a4,3
    80005f12:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f14:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f16:	c7ffe737          	lui	a4,0xc7ffe
    80005f1a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fc675f>
    80005f1e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f20:	2701                	sext.w	a4,a4
    80005f22:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f24:	472d                	li	a4,11
    80005f26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f28:	473d                	li	a4,15
    80005f2a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f2c:	6711                	lui	a4,0x4
    80005f2e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f30:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f34:	5bdc                	lw	a5,52(a5)
    80005f36:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f38:	c7d9                	beqz	a5,80005fc6 <virtio_disk_init+0x144>
  if(max < NUM)
    80005f3a:	471d                	li	a4,7
    80005f3c:	08f77d63          	bgeu	a4,a5,80005fd6 <virtio_disk_init+0x154>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f40:	100014b7          	lui	s1,0x10001
    80005f44:	47a1                	li	a5,8
    80005f46:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f48:	6621                	lui	a2,0x8
    80005f4a:	4581                	li	a1,0
    80005f4c:	00026517          	auipc	a0,0x26
    80005f50:	0b450513          	addi	a0,a0,180 # 8002c000 <disk>
    80005f54:	ffffb097          	auipc	ra,0xffffb
    80005f58:	d8c080e7          	jalr	-628(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f5c:	00026717          	auipc	a4,0x26
    80005f60:	0a470713          	addi	a4,a4,164 # 8002c000 <disk>
    80005f64:	00e75793          	srli	a5,a4,0xe
    80005f68:	2781                	sext.w	a5,a5
    80005f6a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f6c:	0002e797          	auipc	a5,0x2e
    80005f70:	09478793          	addi	a5,a5,148 # 80034000 <disk+0x8000>
    80005f74:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f76:	00026717          	auipc	a4,0x26
    80005f7a:	10a70713          	addi	a4,a4,266 # 8002c080 <disk+0x80>
    80005f7e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f80:	0002a717          	auipc	a4,0x2a
    80005f84:	08070713          	addi	a4,a4,128 # 80030000 <disk+0x4000>
    80005f88:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f8a:	4705                	li	a4,1
    80005f8c:	00e78c23          	sb	a4,24(a5)
    80005f90:	00e78ca3          	sb	a4,25(a5)
    80005f94:	00e78d23          	sb	a4,26(a5)
    80005f98:	00e78da3          	sb	a4,27(a5)
    80005f9c:	00e78e23          	sb	a4,28(a5)
    80005fa0:	00e78ea3          	sb	a4,29(a5)
    80005fa4:	00e78f23          	sb	a4,30(a5)
    80005fa8:	00e78fa3          	sb	a4,31(a5)
}
    80005fac:	60e2                	ld	ra,24(sp)
    80005fae:	6442                	ld	s0,16(sp)
    80005fb0:	64a2                	ld	s1,8(sp)
    80005fb2:	6105                	addi	sp,sp,32
    80005fb4:	8082                	ret
    panic("could not find virtio disk");
    80005fb6:	00007517          	auipc	a0,0x7
    80005fba:	a4a50513          	addi	a0,a0,-1462 # 8000ca00 <syscalls+0x398>
    80005fbe:	ffffa097          	auipc	ra,0xffffa
    80005fc2:	580080e7          	jalr	1408(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005fc6:	00007517          	auipc	a0,0x7
    80005fca:	a5a50513          	addi	a0,a0,-1446 # 8000ca20 <syscalls+0x3b8>
    80005fce:	ffffa097          	auipc	ra,0xffffa
    80005fd2:	570080e7          	jalr	1392(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005fd6:	00007517          	auipc	a0,0x7
    80005fda:	a6a50513          	addi	a0,a0,-1430 # 8000ca40 <syscalls+0x3d8>
    80005fde:	ffffa097          	auipc	ra,0xffffa
    80005fe2:	560080e7          	jalr	1376(ra) # 8000053e <panic>

0000000080005fe6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fe6:	7159                	addi	sp,sp,-112
    80005fe8:	f486                	sd	ra,104(sp)
    80005fea:	f0a2                	sd	s0,96(sp)
    80005fec:	eca6                	sd	s1,88(sp)
    80005fee:	e8ca                	sd	s2,80(sp)
    80005ff0:	e4ce                	sd	s3,72(sp)
    80005ff2:	e0d2                	sd	s4,64(sp)
    80005ff4:	fc56                	sd	s5,56(sp)
    80005ff6:	f85a                	sd	s6,48(sp)
    80005ff8:	f45e                	sd	s7,40(sp)
    80005ffa:	f062                	sd	s8,32(sp)
    80005ffc:	ec66                	sd	s9,24(sp)
    80005ffe:	e86a                	sd	s10,16(sp)
    80006000:	1880                	addi	s0,sp,112
    80006002:	892a                	mv	s2,a0
    80006004:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006006:	00c52c83          	lw	s9,12(a0)
    8000600a:	001c9c9b          	slliw	s9,s9,0x1
    8000600e:	1c82                	slli	s9,s9,0x20
    80006010:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006014:	0002e517          	auipc	a0,0x2e
    80006018:	11450513          	addi	a0,a0,276 # 80034128 <disk+0x8128>
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	bc8080e7          	jalr	-1080(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006024:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006026:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006028:	00026b97          	auipc	s7,0x26
    8000602c:	fd8b8b93          	addi	s7,s7,-40 # 8002c000 <disk>
    80006030:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80006032:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006034:	8a4e                	mv	s4,s3
    80006036:	a051                	j	800060ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006038:	00fb86b3          	add	a3,s7,a5
    8000603c:	96da                	add	a3,a3,s6
    8000603e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006042:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006044:	0207c563          	bltz	a5,8000606e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006048:	2485                	addiw	s1,s1,1
    8000604a:	0711                	addi	a4,a4,4
    8000604c:	25548463          	beq	s1,s5,80006294 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80006050:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006052:	0002e697          	auipc	a3,0x2e
    80006056:	fc668693          	addi	a3,a3,-58 # 80034018 <disk+0x8018>
    8000605a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000605c:	0006c583          	lbu	a1,0(a3)
    80006060:	fde1                	bnez	a1,80006038 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006062:	2785                	addiw	a5,a5,1
    80006064:	0685                	addi	a3,a3,1
    80006066:	ff879be3          	bne	a5,s8,8000605c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000606a:	57fd                	li	a5,-1
    8000606c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000606e:	02905a63          	blez	s1,800060a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006072:	f9042503          	lw	a0,-112(s0)
    80006076:	00000097          	auipc	ra,0x0
    8000607a:	d70080e7          	jalr	-656(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    8000607e:	4785                	li	a5,1
    80006080:	0297d163          	bge	a5,s1,800060a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006084:	f9442503          	lw	a0,-108(s0)
    80006088:	00000097          	auipc	ra,0x0
    8000608c:	d5e080e7          	jalr	-674(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    80006090:	4789                	li	a5,2
    80006092:	0097d863          	bge	a5,s1,800060a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006096:	f9842503          	lw	a0,-104(s0)
    8000609a:	00000097          	auipc	ra,0x0
    8000609e:	d4c080e7          	jalr	-692(ra) # 80005de6 <free_desc>
  while(1){

    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a2:	0002e597          	auipc	a1,0x2e
    800060a6:	08658593          	addi	a1,a1,134 # 80034128 <disk+0x8128>
    800060aa:	0002e517          	auipc	a0,0x2e
    800060ae:	f6e50513          	addi	a0,a0,-146 # 80034018 <disk+0x8018>
    800060b2:	ffffc097          	auipc	ra,0xffffc
    800060b6:	14a080e7          	jalr	330(ra) # 800021fc <sleep>
  for(int i = 0; i < 3; i++){
    800060ba:	f9040713          	addi	a4,s0,-112
    800060be:	84ce                	mv	s1,s3
    800060c0:	bf41                	j	80006050 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800060c2:	6705                	lui	a4,0x1
    800060c4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060c8:	972e                	add	a4,a4,a1
    800060ca:	0712                	slli	a4,a4,0x4
    800060cc:	00026697          	auipc	a3,0x26
    800060d0:	f3468693          	addi	a3,a3,-204 # 8002c000 <disk>
    800060d4:	9736                	add	a4,a4,a3
    800060d6:	4685                	li	a3,1
    800060d8:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800060dc:	6705                	lui	a4,0x1
    800060de:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060e2:	972e                	add	a4,a4,a1
    800060e4:	0712                	slli	a4,a4,0x4
    800060e6:	00026697          	auipc	a3,0x26
    800060ea:	f1a68693          	addi	a3,a3,-230 # 8002c000 <disk>
    800060ee:	9736                	add	a4,a4,a3
    800060f0:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060f4:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060f8:	7661                	lui	a2,0xffff8
    800060fa:	963e                	add	a2,a2,a5
    800060fc:	0002e697          	auipc	a3,0x2e
    80006100:	f0468693          	addi	a3,a3,-252 # 80034000 <disk+0x8000>
    80006104:	6298                	ld	a4,0(a3)
    80006106:	9732                	add	a4,a4,a2
    80006108:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000610a:	6298                	ld	a4,0(a3)
    8000610c:	9732                	add	a4,a4,a2
    8000610e:	4541                	li	a0,16
    80006110:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006112:	6298                	ld	a4,0(a3)
    80006114:	9732                	add	a4,a4,a2
    80006116:	4505                	li	a0,1
    80006118:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    8000611c:	f9442703          	lw	a4,-108(s0)
    80006120:	6288                	ld	a0,0(a3)
    80006122:	962a                	add	a2,a2,a0
    80006124:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc000e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006128:	0712                	slli	a4,a4,0x4
    8000612a:	6290                	ld	a2,0(a3)
    8000612c:	963a                	add	a2,a2,a4
    8000612e:	05890513          	addi	a0,s2,88
    80006132:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006134:	6294                	ld	a3,0(a3)
    80006136:	96ba                	add	a3,a3,a4
    80006138:	40000613          	li	a2,1024
    8000613c:	c690                	sw	a2,8(a3)
  if(write)
    8000613e:	140d0263          	beqz	s10,80006282 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006142:	0002e697          	auipc	a3,0x2e
    80006146:	ebe6b683          	ld	a3,-322(a3) # 80034000 <disk+0x8000>
    8000614a:	96ba                	add	a3,a3,a4
    8000614c:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006150:	00026817          	auipc	a6,0x26
    80006154:	eb080813          	addi	a6,a6,-336 # 8002c000 <disk>
    80006158:	0002e697          	auipc	a3,0x2e
    8000615c:	ea868693          	addi	a3,a3,-344 # 80034000 <disk+0x8000>
    80006160:	6290                	ld	a2,0(a3)
    80006162:	963a                	add	a2,a2,a4
    80006164:	00c65503          	lhu	a0,12(a2)
    80006168:	00156513          	ori	a0,a0,1
    8000616c:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006170:	f9842603          	lw	a2,-104(s0)
    80006174:	6288                	ld	a0,0(a3)
    80006176:	972a                	add	a4,a4,a0
    80006178:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000617c:	6705                	lui	a4,0x1
    8000617e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006182:	972e                	add	a4,a4,a1
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	9742                	add	a4,a4,a6
    80006188:	557d                	li	a0,-1
    8000618a:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000618e:	0612                	slli	a2,a2,0x4
    80006190:	6288                	ld	a0,0(a3)
    80006192:	9532                	add	a0,a0,a2
    80006194:	03078793          	addi	a5,a5,48
    80006198:	97c2                	add	a5,a5,a6
    8000619a:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    8000619c:	629c                	ld	a5,0(a3)
    8000619e:	97b2                	add	a5,a5,a2
    800061a0:	4505                	li	a0,1
    800061a2:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061a4:	629c                	ld	a5,0(a3)
    800061a6:	97b2                	add	a5,a5,a2
    800061a8:	4809                	li	a6,2
    800061aa:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800061ae:	629c                	ld	a5,0(a3)
    800061b0:	963e                	add	a2,a2,a5
    800061b2:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061b6:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    800061ba:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061be:	6698                	ld	a4,8(a3)
    800061c0:	00275783          	lhu	a5,2(a4)
    800061c4:	8b9d                	andi	a5,a5,7
    800061c6:	0786                	slli	a5,a5,0x1
    800061c8:	97ba                	add	a5,a5,a4
    800061ca:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800061ce:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061d2:	6698                	ld	a4,8(a3)
    800061d4:	00275783          	lhu	a5,2(a4)
    800061d8:	2785                	addiw	a5,a5,1
    800061da:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061de:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061e2:	100017b7          	lui	a5,0x10001
    800061e6:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061ea:	00492703          	lw	a4,4(s2)
    800061ee:	4785                	li	a5,1
    800061f0:	02f71163          	bne	a4,a5,80006212 <virtio_disk_rw+0x22c>
	  
    sleep(b, &disk.vdisk_lock);
    800061f4:	0002e997          	auipc	s3,0x2e
    800061f8:	f3498993          	addi	s3,s3,-204 # 80034128 <disk+0x8128>
  while(b->disk == 1) {
    800061fc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061fe:	85ce                	mv	a1,s3
    80006200:	854a                	mv	a0,s2
    80006202:	ffffc097          	auipc	ra,0xffffc
    80006206:	ffa080e7          	jalr	-6(ra) # 800021fc <sleep>
  while(b->disk == 1) {
    8000620a:	00492783          	lw	a5,4(s2)
    8000620e:	fe9788e3          	beq	a5,s1,800061fe <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006212:	f9042903          	lw	s2,-112(s0)
    80006216:	6785                	lui	a5,0x1
    80006218:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000621c:	97ca                	add	a5,a5,s2
    8000621e:	0792                	slli	a5,a5,0x4
    80006220:	00026717          	auipc	a4,0x26
    80006224:	de070713          	addi	a4,a4,-544 # 8002c000 <disk>
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000622e:	0002e997          	auipc	s3,0x2e
    80006232:	dd298993          	addi	s3,s3,-558 # 80034000 <disk+0x8000>
    80006236:	00491713          	slli	a4,s2,0x4
    8000623a:	0009b783          	ld	a5,0(s3)
    8000623e:	97ba                	add	a5,a5,a4
    80006240:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006244:	854a                	mv	a0,s2
    80006246:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000624a:	00000097          	auipc	ra,0x0
    8000624e:	b9c080e7          	jalr	-1124(ra) # 80005de6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006252:	8885                	andi	s1,s1,1
    80006254:	f0ed                	bnez	s1,80006236 <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006256:	0002e517          	auipc	a0,0x2e
    8000625a:	ed250513          	addi	a0,a0,-302 # 80034128 <disk+0x8128>
    8000625e:	ffffb097          	auipc	ra,0xffffb
    80006262:	a3a080e7          	jalr	-1478(ra) # 80000c98 <release>
}
    80006266:	70a6                	ld	ra,104(sp)
    80006268:	7406                	ld	s0,96(sp)
    8000626a:	64e6                	ld	s1,88(sp)
    8000626c:	6946                	ld	s2,80(sp)
    8000626e:	69a6                	ld	s3,72(sp)
    80006270:	6a06                	ld	s4,64(sp)
    80006272:	7ae2                	ld	s5,56(sp)
    80006274:	7b42                	ld	s6,48(sp)
    80006276:	7ba2                	ld	s7,40(sp)
    80006278:	7c02                	ld	s8,32(sp)
    8000627a:	6ce2                	ld	s9,24(sp)
    8000627c:	6d42                	ld	s10,16(sp)
    8000627e:	6165                	addi	sp,sp,112
    80006280:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006282:	0002e697          	auipc	a3,0x2e
    80006286:	d7e6b683          	ld	a3,-642(a3) # 80034000 <disk+0x8000>
    8000628a:	96ba                	add	a3,a3,a4
    8000628c:	4609                	li	a2,2
    8000628e:	00c69623          	sh	a2,12(a3)
    80006292:	bd7d                	j	80006150 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006294:	f9042583          	lw	a1,-112(s0)
    80006298:	6785                	lui	a5,0x1
    8000629a:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000629e:	97ae                	add	a5,a5,a1
    800062a0:	0792                	slli	a5,a5,0x4
    800062a2:	00026517          	auipc	a0,0x26
    800062a6:	e0650513          	addi	a0,a0,-506 # 8002c0a8 <disk+0xa8>
    800062aa:	953e                	add	a0,a0,a5
  if(write)
    800062ac:	e00d1be3          	bnez	s10,800060c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800062b0:	6705                	lui	a4,0x1
    800062b2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800062b6:	972e                	add	a4,a4,a1
    800062b8:	0712                	slli	a4,a4,0x4
    800062ba:	00026697          	auipc	a3,0x26
    800062be:	d4668693          	addi	a3,a3,-698 # 8002c000 <disk>
    800062c2:	9736                	add	a4,a4,a3
    800062c4:	0a072423          	sw	zero,168(a4)
    800062c8:	bd11                	j	800060dc <virtio_disk_rw+0xf6>

00000000800062ca <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062ca:	7179                	addi	sp,sp,-48
    800062cc:	f406                	sd	ra,40(sp)
    800062ce:	f022                	sd	s0,32(sp)
    800062d0:	ec26                	sd	s1,24(sp)
    800062d2:	e84a                	sd	s2,16(sp)
    800062d4:	e44e                	sd	s3,8(sp)
    800062d6:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    800062d8:	0002e517          	auipc	a0,0x2e
    800062dc:	e5050513          	addi	a0,a0,-432 # 80034128 <disk+0x8128>
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	904080e7          	jalr	-1788(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062e8:	10001737          	lui	a4,0x10001
    800062ec:	533c                	lw	a5,96(a4)
    800062ee:	8b8d                	andi	a5,a5,3
    800062f0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062f2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.
      disk.used->idx++;
    800062f6:	0002e797          	auipc	a5,0x2e
    800062fa:	d0a78793          	addi	a5,a5,-758 # 80034000 <disk+0x8000>
    800062fe:	6b94                	ld	a3,16(a5)
    80006300:	0026d703          	lhu	a4,2(a3)
    80006304:	2705                	addiw	a4,a4,1
    80006306:	00e69123          	sh	a4,2(a3)
  while(disk.used_idx != disk.used->idx){
    8000630a:	6b94                	ld	a3,16(a5)
    8000630c:	0207d703          	lhu	a4,32(a5)
    80006310:	0026d783          	lhu	a5,2(a3)
    80006314:	06f70363          	beq	a4,a5,8000637a <virtio_disk_intr+0xb0>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006318:	00026997          	auipc	s3,0x26
    8000631c:	ce898993          	addi	s3,s3,-792 # 8002c000 <disk>
    80006320:	0002e497          	auipc	s1,0x2e
    80006324:	ce048493          	addi	s1,s1,-800 # 80034000 <disk+0x8000>

    if(disk.info[id].status != 0)
    80006328:	6905                	lui	s2,0x1
    8000632a:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    8000632e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006332:	6898                	ld	a4,16(s1)
    80006334:	0204d783          	lhu	a5,32(s1)
    80006338:	8b9d                	andi	a5,a5,7
    8000633a:	078e                	slli	a5,a5,0x3
    8000633c:	97ba                	add	a5,a5,a4
    8000633e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006340:	01278733          	add	a4,a5,s2
    80006344:	0712                	slli	a4,a4,0x4
    80006346:	974e                	add	a4,a4,s3
    80006348:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000634c:	e731                	bnez	a4,80006398 <virtio_disk_intr+0xce>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000634e:	97ca                	add	a5,a5,s2
    80006350:	0792                	slli	a5,a5,0x4
    80006352:	97ce                	add	a5,a5,s3
    80006354:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006356:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000635a:	ffffc097          	auipc	ra,0xffffc
    8000635e:	02e080e7          	jalr	46(ra) # 80002388 <wakeup>

    disk.used_idx += 1;
    80006362:	0204d783          	lhu	a5,32(s1)
    80006366:	2785                	addiw	a5,a5,1
    80006368:	17c2                	slli	a5,a5,0x30
    8000636a:	93c1                	srli	a5,a5,0x30
    8000636c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006370:	6898                	ld	a4,16(s1)
    80006372:	00275703          	lhu	a4,2(a4)
    80006376:	faf71ce3          	bne	a4,a5,8000632e <virtio_disk_intr+0x64>
  }

  release(&disk.vdisk_lock);
    8000637a:	0002e517          	auipc	a0,0x2e
    8000637e:	dae50513          	addi	a0,a0,-594 # 80034128 <disk+0x8128>
    80006382:	ffffb097          	auipc	ra,0xffffb
    80006386:	916080e7          	jalr	-1770(ra) # 80000c98 <release>
}
    8000638a:	70a2                	ld	ra,40(sp)
    8000638c:	7402                	ld	s0,32(sp)
    8000638e:	64e2                	ld	s1,24(sp)
    80006390:	6942                	ld	s2,16(sp)
    80006392:	69a2                	ld	s3,8(sp)
    80006394:	6145                	addi	sp,sp,48
    80006396:	8082                	ret
      panic("virtio_disk_intr status");
    80006398:	00006517          	auipc	a0,0x6
    8000639c:	6c850513          	addi	a0,a0,1736 # 8000ca60 <syscalls+0x3f8>
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	19e080e7          	jalr	414(ra) # 8000053e <panic>
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
