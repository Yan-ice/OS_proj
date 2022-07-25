
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000c117          	auipc	sp,0xc
    80000004:	18010113          	addi	sp,sp,384 # 8000c180 <stack0>
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
    80000052:	0000c717          	auipc	a4,0xc
    80000056:	fee70713          	addi	a4,a4,-18 # 8000c040 <timer_scratch>
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
    80000068:	b2c78793          	addi	a5,a5,-1236 # 80005b90 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffca7ff>
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
    80000130:	3ba080e7          	jalr	954(ra) # 800024e6 <either_copyin>
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
    8000018c:	00014517          	auipc	a0,0x14
    80000190:	ff450513          	addi	a0,a0,-12 # 80014180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00014497          	auipc	s1,0x14
    800001a0:	fe448493          	addi	s1,s1,-28 # 80014180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00014917          	auipc	s2,0x14
    800001aa:	07290913          	addi	s2,s2,114 # 80014218 <cons+0x98>
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
    800001c8:	86c080e7          	jalr	-1940(ra) # 80001a30 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f18080e7          	jalr	-232(ra) # 800020ec <sleep>
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
    80000214:	280080e7          	jalr	640(ra) # 80002490 <either_copyout>
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
    80000224:	00014517          	auipc	a0,0x14
    80000228:	f5c50513          	addi	a0,a0,-164 # 80014180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00014517          	auipc	a0,0x14
    8000023e:	f4650513          	addi	a0,a0,-186 # 80014180 <cons>
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
    80000272:	00014717          	auipc	a4,0x14
    80000276:	faf72323          	sw	a5,-90(a4) # 80014218 <cons+0x98>
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
    800002cc:	00014517          	auipc	a0,0x14
    800002d0:	eb450513          	addi	a0,a0,-332 # 80014180 <cons>
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
    800002f6:	24a080e7          	jalr	586(ra) # 8000253c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00014517          	auipc	a0,0x14
    800002fe:	e8650513          	addi	a0,a0,-378 # 80014180 <cons>
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
    8000031e:	00014717          	auipc	a4,0x14
    80000322:	e6270713          	addi	a4,a4,-414 # 80014180 <cons>
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
    80000348:	00014797          	auipc	a5,0x14
    8000034c:	e3878793          	addi	a5,a5,-456 # 80014180 <cons>
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
    80000376:	00014797          	auipc	a5,0x14
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80014218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00014717          	auipc	a4,0x14
    8000038e:	df670713          	addi	a4,a4,-522 # 80014180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00014497          	auipc	s1,0x14
    8000039e:	de648493          	addi	s1,s1,-538 # 80014180 <cons>
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
    800003d6:	00014717          	auipc	a4,0x14
    800003da:	daa70713          	addi	a4,a4,-598 # 80014180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00014717          	auipc	a4,0x14
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80014220 <cons+0xa0>
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
    80000412:	00014797          	auipc	a5,0x14
    80000416:	d6e78793          	addi	a5,a5,-658 # 80014180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00014797          	auipc	a5,0x14
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001421c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00014517          	auipc	a0,0x14
    80000442:	dda50513          	addi	a0,a0,-550 # 80014218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e32080e7          	jalr	-462(ra) # 80002278 <wakeup>
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
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00014517          	auipc	a0,0x14
    80000464:	d2050513          	addi	a0,a0,-736 # 80014180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00024797          	auipc	a5,0x24
    8000047c:	ea078793          	addi	a5,a5,-352 # 80024318 <devsw>
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
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
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
    8000054a:	00014797          	auipc	a5,0x14
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80014240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	bb450513          	addi	a0,a0,-1100 # 80008120 <digits+0xe0>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	0000c717          	auipc	a4,0xc
    80000582:	a8f72123          	sw	a5,-1406(a4) # 8000c000 <panicked>
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
    800005ba:	00014d97          	auipc	s11,0x14
    800005be:	c86dad83          	lw	s11,-890(s11) # 80014240 <pr+0x18>
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
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00014517          	auipc	a0,0x14
    800005fc:	c3050513          	addi	a0,a0,-976 # 80014228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
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
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
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
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
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
    8000075c:	00014517          	auipc	a0,0x14
    80000760:	acc50513          	addi	a0,a0,-1332 # 80014228 <pr>
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
    80000778:	00014497          	auipc	s1,0x14
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80014228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
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
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00014517          	auipc	a0,0x14
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80014248 <uart_tx_lock>
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
    80000804:	0000b797          	auipc	a5,0xb
    80000808:	7fc7a783          	lw	a5,2044(a5) # 8000c000 <panicked>
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
    80000840:	0000b717          	auipc	a4,0xb
    80000844:	7c873703          	ld	a4,1992(a4) # 8000c008 <uart_tx_r>
    80000848:	0000b797          	auipc	a5,0xb
    8000084c:	7c87b783          	ld	a5,1992(a5) # 8000c010 <uart_tx_w>
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
    8000086a:	00014a17          	auipc	s4,0x14
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80014248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	0000b497          	auipc	s1,0xb
    80000876:	79648493          	addi	s1,s1,1942 # 8000c008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	0000b997          	auipc	s3,0xb
    8000087e:	79698993          	addi	s3,s3,1942 # 8000c010 <uart_tx_w>
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
    800008a4:	9d8080e7          	jalr	-1576(ra) # 80002278 <wakeup>
    
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
    800008dc:	00014517          	auipc	a0,0x14
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80014248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	0000b797          	auipc	a5,0xb
    800008f0:	7147a783          	lw	a5,1812(a5) # 8000c000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	0000b797          	auipc	a5,0xb
    800008fc:	7187b783          	ld	a5,1816(a5) # 8000c010 <uart_tx_w>
    80000900:	0000b717          	auipc	a4,0xb
    80000904:	70873703          	ld	a4,1800(a4) # 8000c008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00014a17          	auipc	s4,0x14
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80014248 <uart_tx_lock>
    80000918:	0000b497          	auipc	s1,0xb
    8000091c:	6f048493          	addi	s1,s1,1776 # 8000c008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	0000b917          	auipc	s2,0xb
    80000924:	6f090913          	addi	s2,s2,1776 # 8000c010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	7c0080e7          	jalr	1984(ra) # 800020ec <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00014497          	auipc	s1,0x14
    80000946:	90648493          	addi	s1,s1,-1786 # 80014248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	0000b717          	auipc	a4,0xb
    8000095a:	6af73d23          	sd	a5,1722(a4) # 8000c010 <uart_tx_w>
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
    800009ca:	00014497          	auipc	s1,0x14
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80014248 <uart_tx_lock>
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
    80000a0c:	00033797          	auipc	a5,0x33
    80000a10:	5f478793          	addi	a5,a5,1524 # 80034000 <end>
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
    80000a2c:	00014917          	auipc	s2,0x14
    80000a30:	85490913          	addi	s2,s2,-1964 # 80014280 <kmem>
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
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
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
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00013517          	auipc	a0,0x13
    80000acc:	7b850513          	addi	a0,a0,1976 # 80014280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00033517          	auipc	a0,0x33
    80000ae0:	52450513          	addi	a0,a0,1316 # 80034000 <end>
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
    80000afe:	00013497          	auipc	s1,0x13
    80000b02:	78248493          	addi	s1,s1,1922 # 80014280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00013517          	auipc	a0,0x13
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80014280 <kmem>
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
    80000b42:	00013517          	auipc	a0,0x13
    80000b46:	73e50513          	addi	a0,a0,1854 # 80014280 <kmem>
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
    80000b82:	e96080e7          	jalr	-362(ra) # 80001a14 <mycpu>
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
    80000bb4:	e64080e7          	jalr	-412(ra) # 80001a14 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e58080e7          	jalr	-424(ra) # 80001a14 <mycpu>
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
    80000bd8:	e40080e7          	jalr	-448(ra) # 80001a14 <mycpu>
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
    80000c18:	e00080e7          	jalr	-512(ra) # 80001a14 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
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
    80000c44:	dd4080e7          	jalr	-556(ra) # 80001a14 <mycpu>
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
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
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
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
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
    80000e9a:	b6e080e7          	jalr	-1170(ra) # 80001a04 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	0000b717          	auipc	a4,0xb
    80000ea2:	17a70713          	addi	a4,a4,378 # 8000c018 <started>
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
    80000eb6:	b52080e7          	jalr	-1198(ra) # 80001a04 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	26c50513          	addi	a0,a0,620 # 80008128 <digits+0xe8>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	118080e7          	jalr	280(ra) # 80000fe4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	7a8080e7          	jalr	1960(ra) # 8000267c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	cf4080e7          	jalr	-780(ra) # 80005bd0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	056080e7          	jalr	86(ra) # 80001f3a <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	22450513          	addi	a0,a0,548 # 80008120 <digits+0xe0>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	20450513          	addi	a0,a0,516 # 80008120 <digits+0xe0>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    printf("starting kinit...\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	18c50513          	addi	a0,a0,396 # 800080b8 <digits+0x78>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	654080e7          	jalr	1620(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	b7c080e7          	jalr	-1156(ra) # 80000ab8 <kinit>
    printf("creating kernel page table...\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	18c50513          	addi	a0,a0,396 # 800080d0 <digits+0x90>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	63c080e7          	jalr	1596(ra) # 80000588 <printf>
    kvminit();       // create kernel page table
    80000f54:	00000097          	auipc	ra,0x0
    80000f58:	382080e7          	jalr	898(ra) # 800012d6 <kvminit>
    printf("turning on paging...\n");
    80000f5c:	00007517          	auipc	a0,0x7
    80000f60:	19450513          	addi	a0,a0,404 # 800080f0 <digits+0xb0>
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	624080e7          	jalr	1572(ra) # 80000588 <printf>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	078080e7          	jalr	120(ra) # 80000fe4 <kvminithart>
    printf("initing process table...\n");
    80000f74:	00007517          	auipc	a0,0x7
    80000f78:	19450513          	addi	a0,a0,404 # 80008108 <digits+0xc8>
    80000f7c:	fffff097          	auipc	ra,0xfffff
    80000f80:	60c080e7          	jalr	1548(ra) # 80000588 <printf>
    procinit();      // process table
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	9d0080e7          	jalr	-1584(ra) # 80001954 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	6c8080e7          	jalr	1736(ra) # 80002654 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	6e8080e7          	jalr	1768(ra) # 8000267c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	c1e080e7          	jalr	-994(ra) # 80005bba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	c2c080e7          	jalr	-980(ra) # 80005bd0 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	e12080e7          	jalr	-494(ra) # 80002dbe <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	4a2080e7          	jalr	1186(ra) # 80003456 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	44c080e7          	jalr	1100(ra) # 80004408 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	d2e080e7          	jalr	-722(ra) # 80005cf2 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	d3c080e7          	jalr	-708(ra) # 80001d08 <userinit>
    __sync_synchronize();
    80000fd4:	0ff0000f          	fence
    started = 1;
    80000fd8:	4785                	li	a5,1
    80000fda:	0000b717          	auipc	a4,0xb
    80000fde:	02f72f23          	sw	a5,62(a4) # 8000c018 <started>
    80000fe2:	b709                	j	80000ee4 <main+0x56>

0000000080000fe4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe4:	1141                	addi	sp,sp,-16
    80000fe6:	e406                	sd	ra,8(sp)
    80000fe8:	e022                	sd	s0,0(sp)
    80000fea:	0800                	addi	s0,sp,16
  printf("setting SATP...\n");
    80000fec:	00007517          	auipc	a0,0x7
    80000ff0:	15450513          	addi	a0,a0,340 # 80008140 <digits+0x100>
    80000ff4:	fffff097          	auipc	ra,0xfffff
    80000ff8:	594080e7          	jalr	1428(ra) # 80000588 <printf>
  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffc:	0000b797          	auipc	a5,0xb
    80001000:	0247b783          	ld	a5,36(a5) # 8000c020 <kernel_pagetable>
    80001004:	83b1                	srli	a5,a5,0xc
    80001006:	577d                	li	a4,-1
    80001008:	177e                	slli	a4,a4,0x3f
    8000100a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100c:	18079073          	csrw	satp,a5
  printf("flushing VMA...\n");
    80001010:	00007517          	auipc	a0,0x7
    80001014:	14850513          	addi	a0,a0,328 # 80008158 <digits+0x118>
    80001018:	fffff097          	auipc	ra,0xfffff
    8000101c:	570080e7          	jalr	1392(ra) # 80000588 <printf>
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001020:	12000073          	sfence.vma
  sfence_vma();

}
    80001024:	60a2                	ld	ra,8(sp)
    80001026:	6402                	ld	s0,0(sp)
    80001028:	0141                	addi	sp,sp,16
    8000102a:	8082                	ret

000000008000102c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102c:	7139                	addi	sp,sp,-64
    8000102e:	fc06                	sd	ra,56(sp)
    80001030:	f822                	sd	s0,48(sp)
    80001032:	f426                	sd	s1,40(sp)
    80001034:	f04a                	sd	s2,32(sp)
    80001036:	ec4e                	sd	s3,24(sp)
    80001038:	e852                	sd	s4,16(sp)
    8000103a:	e456                	sd	s5,8(sp)
    8000103c:	e05a                	sd	s6,0(sp)
    8000103e:	0080                	addi	s0,sp,64
    80001040:	84aa                	mv	s1,a0
    80001042:	89ae                	mv	s3,a1
    80001044:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001046:	57fd                	li	a5,-1
    80001048:	83ed                	srli	a5,a5,0x1b
    8000104a:	02000a13          	li	s4,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b39                	li	s6,14
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x68>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	11c50513          	addi	a0,a0,284 # 80008170 <digits+0x130>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e2080e7          	jalr	1250(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa4>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	a8c080e7          	jalr	-1396(ra) # 80000af4 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x90>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6611                	lui	a2,0x4
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	c68080e7          	jalr	-920(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00e4d793          	srli	a5,s1,0xe
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x38>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04ba                	slli	s1,s1,0xe
    800010ae:	b7c5                	j	8000108e <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00e9d513          	srli	a0,s3,0xe
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x90>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83ed                	srli	a5,a5,0x1b
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f42080e7          	jalr	-190(ra) # 8000102c <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	00a7d513          	srli	a0,a5,0xa
    8000110e:	053a                	slli	a0,a0,0xe
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
    8000112c:	8aaa                	mv	s5,a0
    8000112e:	892e                	mv	s2,a1
    80001130:	89b2                	mv	s3,a2
    80001132:	8a36                	mv	s4,a3
    80001134:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  printf("mapping VA %x to PA %x in PT %x\n",va,pa,pagetable);
    80001136:	86aa                	mv	a3,a0
    80001138:	8652                	mv	a2,s4
    8000113a:	00007517          	auipc	a0,0x7
    8000113e:	03e50513          	addi	a0,a0,62 # 80008178 <digits+0x138>
    80001142:	fffff097          	auipc	ra,0xfffff
    80001146:	446080e7          	jalr	1094(ra) # 80000588 <printf>
  if(size == 0)
    8000114a:	00098e63          	beqz	s3,80001166 <mappages+0x50>
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000114e:	77f1                	lui	a5,0xffffc
    80001150:	00f976b3          	and	a3,s2,a5
  last = PGROUNDDOWN(va + size - 1);
    80001154:	19fd                	addi	s3,s3,-1
    80001156:	99ca                	add	s3,s3,s2
    80001158:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000115c:	8936                	mv	s2,a3
    8000115e:	40da0a33          	sub	s4,s4,a3
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001162:	6b91                	lui	s7,0x4
    80001164:	a015                	j	80001188 <mappages+0x72>
    panic("mappages: size");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	03a50513          	addi	a0,a0,58 # 800081a0 <digits+0x160>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001176:	00007517          	auipc	a0,0x7
    8000117a:	03a50513          	addi	a0,a0,58 # 800081b0 <digits+0x170>
    8000117e:	fffff097          	auipc	ra,0xfffff
    80001182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>
    a += PGSIZE;
    80001186:	995e                	add	s2,s2,s7
  for(;;){
    80001188:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000118c:	4605                	li	a2,1
    8000118e:	85ca                	mv	a1,s2
    80001190:	8556                	mv	a0,s5
    80001192:	00000097          	auipc	ra,0x0
    80001196:	e9a080e7          	jalr	-358(ra) # 8000102c <walk>
    8000119a:	cd19                	beqz	a0,800011b8 <mappages+0xa2>
    if(*pte & PTE_V)
    8000119c:	611c                	ld	a5,0(a0)
    8000119e:	8b85                	andi	a5,a5,1
    800011a0:	fbf9                	bnez	a5,80001176 <mappages+0x60>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011a2:	80b9                	srli	s1,s1,0xe
    800011a4:	04aa                	slli	s1,s1,0xa
    800011a6:	0164e4b3          	or	s1,s1,s6
    800011aa:	0014e493          	ori	s1,s1,1
    800011ae:	e104                	sd	s1,0(a0)
    if(a == last)
    800011b0:	fd391be3          	bne	s2,s3,80001186 <mappages+0x70>
    pa += PGSIZE;
  }
  return 0;
    800011b4:	4501                	li	a0,0
    800011b6:	a011                	j	800011ba <mappages+0xa4>
      return -1;
    800011b8:	557d                	li	a0,-1
}
    800011ba:	60a6                	ld	ra,72(sp)
    800011bc:	6406                	ld	s0,64(sp)
    800011be:	74e2                	ld	s1,56(sp)
    800011c0:	7942                	ld	s2,48(sp)
    800011c2:	79a2                	ld	s3,40(sp)
    800011c4:	7a02                	ld	s4,32(sp)
    800011c6:	6ae2                	ld	s5,24(sp)
    800011c8:	6b42                	ld	s6,16(sp)
    800011ca:	6ba2                	ld	s7,8(sp)
    800011cc:	6161                	addi	sp,sp,80
    800011ce:	8082                	ret

00000000800011d0 <kvmmap>:
{
    800011d0:	1141                	addi	sp,sp,-16
    800011d2:	e406                	sd	ra,8(sp)
    800011d4:	e022                	sd	s0,0(sp)
    800011d6:	0800                	addi	s0,sp,16
    800011d8:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011da:	86b2                	mv	a3,a2
    800011dc:	863e                	mv	a2,a5
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f38080e7          	jalr	-200(ra) # 80001116 <mappages>
    800011e6:	e509                	bnez	a0,800011f0 <kvmmap+0x20>
}
    800011e8:	60a2                	ld	ra,8(sp)
    800011ea:	6402                	ld	s0,0(sp)
    800011ec:	0141                	addi	sp,sp,16
    800011ee:	8082                	ret
    panic("kvmmap");
    800011f0:	00007517          	auipc	a0,0x7
    800011f4:	fd050513          	addi	a0,a0,-48 # 800081c0 <digits+0x180>
    800011f8:	fffff097          	auipc	ra,0xfffff
    800011fc:	346080e7          	jalr	838(ra) # 8000053e <panic>

0000000080001200 <kvmmake>:
{
    80001200:	1101                	addi	sp,sp,-32
    80001202:	ec06                	sd	ra,24(sp)
    80001204:	e822                	sd	s0,16(sp)
    80001206:	e426                	sd	s1,8(sp)
    80001208:	e04a                	sd	s2,0(sp)
    8000120a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	8e8080e7          	jalr	-1816(ra) # 80000af4 <kalloc>
    80001214:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001216:	6611                	lui	a2,0x4
    80001218:	4581                	li	a1,0
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	ac6080e7          	jalr	-1338(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001222:	4719                	li	a4,6
    80001224:	6691                	lui	a3,0x4
    80001226:	10000637          	lui	a2,0x10000
    8000122a:	100005b7          	lui	a1,0x10000
    8000122e:	8526                	mv	a0,s1
    80001230:	00000097          	auipc	ra,0x0
    80001234:	fa0080e7          	jalr	-96(ra) # 800011d0 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001238:	4719                	li	a4,6
    8000123a:	6691                	lui	a3,0x4
    8000123c:	10004637          	lui	a2,0x10004
    80001240:	100045b7          	lui	a1,0x10004
    80001244:	8526                	mv	a0,s1
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	f8a080e7          	jalr	-118(ra) # 800011d0 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000124e:	4719                	li	a4,6
    80001250:	004006b7          	lui	a3,0x400
    80001254:	0c000637          	lui	a2,0xc000
    80001258:	0c0005b7          	lui	a1,0xc000
    8000125c:	8526                	mv	a0,s1
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f72080e7          	jalr	-142(ra) # 800011d0 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001266:	00007917          	auipc	s2,0x7
    8000126a:	d9a90913          	addi	s2,s2,-614 # 80008000 <etext>
    8000126e:	4729                	li	a4,10
    80001270:	80007697          	auipc	a3,0x80007
    80001274:	d9068693          	addi	a3,a3,-624 # 8000 <_entry-0x7fff8000>
    80001278:	4605                	li	a2,1
    8000127a:	067e                	slli	a2,a2,0x1f
    8000127c:	85b2                	mv	a1,a2
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f50080e7          	jalr	-176(ra) # 800011d0 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001288:	4719                	li	a4,6
    8000128a:	46c5                	li	a3,17
    8000128c:	06ee                	slli	a3,a3,0x1b
    8000128e:	412686b3          	sub	a3,a3,s2
    80001292:	864a                	mv	a2,s2
    80001294:	85ca                	mv	a1,s2
    80001296:	8526                	mv	a0,s1
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f38080e7          	jalr	-200(ra) # 800011d0 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012a0:	4729                	li	a4,10
    800012a2:	6691                	lui	a3,0x4
    800012a4:	00006617          	auipc	a2,0x6
    800012a8:	d5c60613          	addi	a2,a2,-676 # 80007000 <_trampoline>
    800012ac:	008005b7          	lui	a1,0x800
    800012b0:	15fd                	addi	a1,a1,-1
    800012b2:	05ba                	slli	a1,a1,0xe
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f1a080e7          	jalr	-230(ra) # 800011d0 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012be:	8526                	mv	a0,s1
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	5fe080e7          	jalr	1534(ra) # 800018be <proc_mapstacks>
}
    800012c8:	8526                	mv	a0,s1
    800012ca:	60e2                	ld	ra,24(sp)
    800012cc:	6442                	ld	s0,16(sp)
    800012ce:	64a2                	ld	s1,8(sp)
    800012d0:	6902                	ld	s2,0(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <kvminit>:
{
    800012d6:	1141                	addi	sp,sp,-16
    800012d8:	e406                	sd	ra,8(sp)
    800012da:	e022                	sd	s0,0(sp)
    800012dc:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	f22080e7          	jalr	-222(ra) # 80001200 <kvmmake>
    800012e6:	0000b797          	auipc	a5,0xb
    800012ea:	d2a7bd23          	sd	a0,-710(a5) # 8000c020 <kernel_pagetable>
}
    800012ee:	60a2                	ld	ra,8(sp)
    800012f0:	6402                	ld	s0,0(sp)
    800012f2:	0141                	addi	sp,sp,16
    800012f4:	8082                	ret

00000000800012f6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012f6:	715d                	addi	sp,sp,-80
    800012f8:	e486                	sd	ra,72(sp)
    800012fa:	e0a2                	sd	s0,64(sp)
    800012fc:	fc26                	sd	s1,56(sp)
    800012fe:	f84a                	sd	s2,48(sp)
    80001300:	f44e                	sd	s3,40(sp)
    80001302:	f052                	sd	s4,32(sp)
    80001304:	ec56                	sd	s5,24(sp)
    80001306:	e85a                	sd	s6,16(sp)
    80001308:	e45e                	sd	s7,8(sp)
    8000130a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000130c:	03259793          	slli	a5,a1,0x32
    80001310:	e795                	bnez	a5,8000133c <uvmunmap+0x46>
    80001312:	8a2a                	mv	s4,a0
    80001314:	892e                	mv	s2,a1
    80001316:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001318:	063a                	slli	a2,a2,0xe
    8000131a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000131e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001320:	6b11                	lui	s6,0x4
    80001322:	0735e863          	bltu	a1,s3,80001392 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001326:	60a6                	ld	ra,72(sp)
    80001328:	6406                	ld	s0,64(sp)
    8000132a:	74e2                	ld	s1,56(sp)
    8000132c:	7942                	ld	s2,48(sp)
    8000132e:	79a2                	ld	s3,40(sp)
    80001330:	7a02                	ld	s4,32(sp)
    80001332:	6ae2                	ld	s5,24(sp)
    80001334:	6b42                	ld	s6,16(sp)
    80001336:	6ba2                	ld	s7,8(sp)
    80001338:	6161                	addi	sp,sp,80
    8000133a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	e8c50513          	addi	a0,a0,-372 # 800081c8 <digits+0x188>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	1fa080e7          	jalr	506(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	e9450513          	addi	a0,a0,-364 # 800081e0 <digits+0x1a0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1ea080e7          	jalr	490(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000135c:	00007517          	auipc	a0,0x7
    80001360:	e9450513          	addi	a0,a0,-364 # 800081f0 <digits+0x1b0>
    80001364:	fffff097          	auipc	ra,0xfffff
    80001368:	1da080e7          	jalr	474(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000136c:	00007517          	auipc	a0,0x7
    80001370:	e9c50513          	addi	a0,a0,-356 # 80008208 <digits+0x1c8>
    80001374:	fffff097          	auipc	ra,0xfffff
    80001378:	1ca080e7          	jalr	458(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000137c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000137e:	053a                	slli	a0,a0,0xe
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	678080e7          	jalr	1656(ra) # 800009f8 <kfree>
    *pte = 0;
    80001388:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000138c:	995a                	add	s2,s2,s6
    8000138e:	f9397ce3          	bgeu	s2,s3,80001326 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001392:	4601                	li	a2,0
    80001394:	85ca                	mv	a1,s2
    80001396:	8552                	mv	a0,s4
    80001398:	00000097          	auipc	ra,0x0
    8000139c:	c94080e7          	jalr	-876(ra) # 8000102c <walk>
    800013a0:	84aa                	mv	s1,a0
    800013a2:	d54d                	beqz	a0,8000134c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013a4:	6108                	ld	a0,0(a0)
    800013a6:	00157793          	andi	a5,a0,1
    800013aa:	dbcd                	beqz	a5,8000135c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ac:	3ff57793          	andi	a5,a0,1023
    800013b0:	fb778ee3          	beq	a5,s7,8000136c <uvmunmap+0x76>
    if(do_free){
    800013b4:	fc0a8ae3          	beqz	s5,80001388 <uvmunmap+0x92>
    800013b8:	b7d1                	j	8000137c <uvmunmap+0x86>

00000000800013ba <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ba:	1101                	addi	sp,sp,-32
    800013bc:	ec06                	sd	ra,24(sp)
    800013be:	e822                	sd	s0,16(sp)
    800013c0:	e426                	sd	s1,8(sp)
    800013c2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013c4:	fffff097          	auipc	ra,0xfffff
    800013c8:	730080e7          	jalr	1840(ra) # 80000af4 <kalloc>
    800013cc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ce:	c519                	beqz	a0,800013dc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013d0:	6611                	lui	a2,0x4
    800013d2:	4581                	li	a1,0
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	90c080e7          	jalr	-1780(ra) # 80000ce0 <memset>
  return pagetable;
}
    800013dc:	8526                	mv	a0,s1
    800013de:	60e2                	ld	ra,24(sp)
    800013e0:	6442                	ld	s0,16(sp)
    800013e2:	64a2                	ld	s1,8(sp)
    800013e4:	6105                	addi	sp,sp,32
    800013e6:	8082                	ret

00000000800013e8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013e8:	7179                	addi	sp,sp,-48
    800013ea:	f406                	sd	ra,40(sp)
    800013ec:	f022                	sd	s0,32(sp)
    800013ee:	ec26                	sd	s1,24(sp)
    800013f0:	e84a                	sd	s2,16(sp)
    800013f2:	e44e                	sd	s3,8(sp)
    800013f4:	e052                	sd	s4,0(sp)
    800013f6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013f8:	6791                	lui	a5,0x4
    800013fa:	04f67863          	bgeu	a2,a5,8000144a <uvminit+0x62>
    800013fe:	8a2a                	mv	s4,a0
    80001400:	89ae                	mv	s3,a1
    80001402:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	6f0080e7          	jalr	1776(ra) # 80000af4 <kalloc>
    8000140c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000140e:	6611                	lui	a2,0x4
    80001410:	4581                	li	a1,0
    80001412:	00000097          	auipc	ra,0x0
    80001416:	8ce080e7          	jalr	-1842(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000141a:	4779                	li	a4,30
    8000141c:	86ca                	mv	a3,s2
    8000141e:	6611                	lui	a2,0x4
    80001420:	4581                	li	a1,0
    80001422:	8552                	mv	a0,s4
    80001424:	00000097          	auipc	ra,0x0
    80001428:	cf2080e7          	jalr	-782(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    8000142c:	8626                	mv	a2,s1
    8000142e:	85ce                	mv	a1,s3
    80001430:	854a                	mv	a0,s2
    80001432:	00000097          	auipc	ra,0x0
    80001436:	90e080e7          	jalr	-1778(ra) # 80000d40 <memmove>
}
    8000143a:	70a2                	ld	ra,40(sp)
    8000143c:	7402                	ld	s0,32(sp)
    8000143e:	64e2                	ld	s1,24(sp)
    80001440:	6942                	ld	s2,16(sp)
    80001442:	69a2                	ld	s3,8(sp)
    80001444:	6a02                	ld	s4,0(sp)
    80001446:	6145                	addi	sp,sp,48
    80001448:	8082                	ret
    panic("inituvm: more than a page");
    8000144a:	00007517          	auipc	a0,0x7
    8000144e:	dd650513          	addi	a0,a0,-554 # 80008220 <digits+0x1e0>
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	0ec080e7          	jalr	236(ra) # 8000053e <panic>

000000008000145a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000145a:	1101                	addi	sp,sp,-32
    8000145c:	ec06                	sd	ra,24(sp)
    8000145e:	e822                	sd	s0,16(sp)
    80001460:	e426                	sd	s1,8(sp)
    80001462:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001464:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001466:	00b67d63          	bgeu	a2,a1,80001480 <uvmdealloc+0x26>
    8000146a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000146c:	6791                	lui	a5,0x4
    8000146e:	17fd                	addi	a5,a5,-1
    80001470:	00f60733          	add	a4,a2,a5
    80001474:	7671                	lui	a2,0xffffc
    80001476:	8f71                	and	a4,a4,a2
    80001478:	97ae                	add	a5,a5,a1
    8000147a:	8ff1                	and	a5,a5,a2
    8000147c:	00f76863          	bltu	a4,a5,8000148c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001480:	8526                	mv	a0,s1
    80001482:	60e2                	ld	ra,24(sp)
    80001484:	6442                	ld	s0,16(sp)
    80001486:	64a2                	ld	s1,8(sp)
    80001488:	6105                	addi	sp,sp,32
    8000148a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000148c:	8f99                	sub	a5,a5,a4
    8000148e:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001490:	4685                	li	a3,1
    80001492:	0007861b          	sext.w	a2,a5
    80001496:	85ba                	mv	a1,a4
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	e5e080e7          	jalr	-418(ra) # 800012f6 <uvmunmap>
    800014a0:	b7c5                	j	80001480 <uvmdealloc+0x26>

00000000800014a2 <uvmalloc>:
  if(newsz < oldsz)
    800014a2:	0ab66163          	bltu	a2,a1,80001544 <uvmalloc+0xa2>
{
    800014a6:	7139                	addi	sp,sp,-64
    800014a8:	fc06                	sd	ra,56(sp)
    800014aa:	f822                	sd	s0,48(sp)
    800014ac:	f426                	sd	s1,40(sp)
    800014ae:	f04a                	sd	s2,32(sp)
    800014b0:	ec4e                	sd	s3,24(sp)
    800014b2:	e852                	sd	s4,16(sp)
    800014b4:	e456                	sd	s5,8(sp)
    800014b6:	0080                	addi	s0,sp,64
    800014b8:	8aaa                	mv	s5,a0
    800014ba:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014bc:	6991                	lui	s3,0x4
    800014be:	19fd                	addi	s3,s3,-1
    800014c0:	95ce                	add	a1,a1,s3
    800014c2:	79f1                	lui	s3,0xffffc
    800014c4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014c8:	08c9f063          	bgeu	s3,a2,80001548 <uvmalloc+0xa6>
    800014cc:	894e                	mv	s2,s3
    mem = kalloc();
    800014ce:	fffff097          	auipc	ra,0xfffff
    800014d2:	626080e7          	jalr	1574(ra) # 80000af4 <kalloc>
    800014d6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014d8:	c51d                	beqz	a0,80001506 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014da:	6611                	lui	a2,0x4
    800014dc:	4581                	li	a1,0
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	802080e7          	jalr	-2046(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014e6:	4779                	li	a4,30
    800014e8:	86a6                	mv	a3,s1
    800014ea:	6611                	lui	a2,0x4
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	c26080e7          	jalr	-986(ra) # 80001116 <mappages>
    800014f8:	e905                	bnez	a0,80001528 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fa:	6791                	lui	a5,0x4
    800014fc:	993e                	add	s2,s2,a5
    800014fe:	fd4968e3          	bltu	s2,s4,800014ce <uvmalloc+0x2c>
  return newsz;
    80001502:	8552                	mv	a0,s4
    80001504:	a809                	j	80001516 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001506:	864e                	mv	a2,s3
    80001508:	85ca                	mv	a1,s2
    8000150a:	8556                	mv	a0,s5
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	f4e080e7          	jalr	-178(ra) # 8000145a <uvmdealloc>
      return 0;
    80001514:	4501                	li	a0,0
}
    80001516:	70e2                	ld	ra,56(sp)
    80001518:	7442                	ld	s0,48(sp)
    8000151a:	74a2                	ld	s1,40(sp)
    8000151c:	7902                	ld	s2,32(sp)
    8000151e:	69e2                	ld	s3,24(sp)
    80001520:	6a42                	ld	s4,16(sp)
    80001522:	6aa2                	ld	s5,8(sp)
    80001524:	6121                	addi	sp,sp,64
    80001526:	8082                	ret
      kfree(mem);
    80001528:	8526                	mv	a0,s1
    8000152a:	fffff097          	auipc	ra,0xfffff
    8000152e:	4ce080e7          	jalr	1230(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001532:	864e                	mv	a2,s3
    80001534:	85ca                	mv	a1,s2
    80001536:	8556                	mv	a0,s5
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	f22080e7          	jalr	-222(ra) # 8000145a <uvmdealloc>
      return 0;
    80001540:	4501                	li	a0,0
    80001542:	bfd1                	j	80001516 <uvmalloc+0x74>
    return oldsz;
    80001544:	852e                	mv	a0,a1
}
    80001546:	8082                	ret
  return newsz;
    80001548:	8532                	mv	a0,a2
    8000154a:	b7f1                	j	80001516 <uvmalloc+0x74>

000000008000154c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000154c:	7179                	addi	sp,sp,-48
    8000154e:	f406                	sd	ra,40(sp)
    80001550:	f022                	sd	s0,32(sp)
    80001552:	ec26                	sd	s1,24(sp)
    80001554:	e84a                	sd	s2,16(sp)
    80001556:	e44e                	sd	s3,8(sp)
    80001558:	e052                	sd	s4,0(sp)
    8000155a:	1800                	addi	s0,sp,48
    8000155c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000155e:	84aa                	mv	s1,a0
    80001560:	6905                	lui	s2,0x1
    80001562:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001564:	4985                	li	s3,1
    80001566:	a821                	j	8000157e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001568:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000156a:	053a                	slli	a0,a0,0xe
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	fe0080e7          	jalr	-32(ra) # 8000154c <freewalk>
      pagetable[i] = 0;
    80001574:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001578:	04a1                	addi	s1,s1,8
    8000157a:	03248163          	beq	s1,s2,8000159c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000157e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001580:	00f57793          	andi	a5,a0,15
    80001584:	ff3782e3          	beq	a5,s3,80001568 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001588:	8905                	andi	a0,a0,1
    8000158a:	d57d                	beqz	a0,80001578 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000158c:	00007517          	auipc	a0,0x7
    80001590:	cb450513          	addi	a0,a0,-844 # 80008240 <digits+0x200>
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000159c:	8552                	mv	a0,s4
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	45a080e7          	jalr	1114(ra) # 800009f8 <kfree>
}
    800015a6:	70a2                	ld	ra,40(sp)
    800015a8:	7402                	ld	s0,32(sp)
    800015aa:	64e2                	ld	s1,24(sp)
    800015ac:	6942                	ld	s2,16(sp)
    800015ae:	69a2                	ld	s3,8(sp)
    800015b0:	6a02                	ld	s4,0(sp)
    800015b2:	6145                	addi	sp,sp,48
    800015b4:	8082                	ret

00000000800015b6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015b6:	1101                	addi	sp,sp,-32
    800015b8:	ec06                	sd	ra,24(sp)
    800015ba:	e822                	sd	s0,16(sp)
    800015bc:	e426                	sd	s1,8(sp)
    800015be:	1000                	addi	s0,sp,32
    800015c0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015c2:	e999                	bnez	a1,800015d8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015c4:	8526                	mv	a0,s1
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	f86080e7          	jalr	-122(ra) # 8000154c <freewalk>
}
    800015ce:	60e2                	ld	ra,24(sp)
    800015d0:	6442                	ld	s0,16(sp)
    800015d2:	64a2                	ld	s1,8(sp)
    800015d4:	6105                	addi	sp,sp,32
    800015d6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015d8:	6611                	lui	a2,0x4
    800015da:	167d                	addi	a2,a2,-1
    800015dc:	962e                	add	a2,a2,a1
    800015de:	4685                	li	a3,1
    800015e0:	8239                	srli	a2,a2,0xe
    800015e2:	4581                	li	a1,0
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	d12080e7          	jalr	-750(ra) # 800012f6 <uvmunmap>
    800015ec:	bfe1                	j	800015c4 <uvmfree+0xe>

00000000800015ee <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ee:	c679                	beqz	a2,800016bc <uvmcopy+0xce>
{
    800015f0:	715d                	addi	sp,sp,-80
    800015f2:	e486                	sd	ra,72(sp)
    800015f4:	e0a2                	sd	s0,64(sp)
    800015f6:	fc26                	sd	s1,56(sp)
    800015f8:	f84a                	sd	s2,48(sp)
    800015fa:	f44e                	sd	s3,40(sp)
    800015fc:	f052                	sd	s4,32(sp)
    800015fe:	ec56                	sd	s5,24(sp)
    80001600:	e85a                	sd	s6,16(sp)
    80001602:	e45e                	sd	s7,8(sp)
    80001604:	0880                	addi	s0,sp,80
    80001606:	8b2a                	mv	s6,a0
    80001608:	8aae                	mv	s5,a1
    8000160a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000160c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000160e:	4601                	li	a2,0
    80001610:	85ce                	mv	a1,s3
    80001612:	855a                	mv	a0,s6
    80001614:	00000097          	auipc	ra,0x0
    80001618:	a18080e7          	jalr	-1512(ra) # 8000102c <walk>
    8000161c:	c531                	beqz	a0,80001668 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000161e:	6118                	ld	a4,0(a0)
    80001620:	00177793          	andi	a5,a4,1
    80001624:	cbb1                	beqz	a5,80001678 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001626:	00a75593          	srli	a1,a4,0xa
    8000162a:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    8000162e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	4c2080e7          	jalr	1218(ra) # 80000af4 <kalloc>
    8000163a:	892a                	mv	s2,a0
    8000163c:	c939                	beqz	a0,80001692 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000163e:	6611                	lui	a2,0x4
    80001640:	85de                	mv	a1,s7
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	6fe080e7          	jalr	1790(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000164a:	8726                	mv	a4,s1
    8000164c:	86ca                	mv	a3,s2
    8000164e:	6611                	lui	a2,0x4
    80001650:	85ce                	mv	a1,s3
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	ac2080e7          	jalr	-1342(ra) # 80001116 <mappages>
    8000165c:	e515                	bnez	a0,80001688 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000165e:	6791                	lui	a5,0x4
    80001660:	99be                	add	s3,s3,a5
    80001662:	fb49e6e3          	bltu	s3,s4,8000160e <uvmcopy+0x20>
    80001666:	a081                	j	800016a6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	be850513          	addi	a0,a0,-1048 # 80008250 <digits+0x210>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ece080e7          	jalr	-306(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001678:	00007517          	auipc	a0,0x7
    8000167c:	bf850513          	addi	a0,a0,-1032 # 80008270 <digits+0x230>
    80001680:	fffff097          	auipc	ra,0xfffff
    80001684:	ebe080e7          	jalr	-322(ra) # 8000053e <panic>
      kfree(mem);
    80001688:	854a                	mv	a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	36e080e7          	jalr	878(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001692:	4685                	li	a3,1
    80001694:	00e9d613          	srli	a2,s3,0xe
    80001698:	4581                	li	a1,0
    8000169a:	8556                	mv	a0,s5
    8000169c:	00000097          	auipc	ra,0x0
    800016a0:	c5a080e7          	jalr	-934(ra) # 800012f6 <uvmunmap>
  return -1;
    800016a4:	557d                	li	a0,-1
}
    800016a6:	60a6                	ld	ra,72(sp)
    800016a8:	6406                	ld	s0,64(sp)
    800016aa:	74e2                	ld	s1,56(sp)
    800016ac:	7942                	ld	s2,48(sp)
    800016ae:	79a2                	ld	s3,40(sp)
    800016b0:	7a02                	ld	s4,32(sp)
    800016b2:	6ae2                	ld	s5,24(sp)
    800016b4:	6b42                	ld	s6,16(sp)
    800016b6:	6ba2                	ld	s7,8(sp)
    800016b8:	6161                	addi	sp,sp,80
    800016ba:	8082                	ret
  return 0;
    800016bc:	4501                	li	a0,0
}
    800016be:	8082                	ret

00000000800016c0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016c0:	1141                	addi	sp,sp,-16
    800016c2:	e406                	sd	ra,8(sp)
    800016c4:	e022                	sd	s0,0(sp)
    800016c6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016c8:	4601                	li	a2,0
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	962080e7          	jalr	-1694(ra) # 8000102c <walk>
  if(pte == 0)
    800016d2:	c901                	beqz	a0,800016e2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016d4:	611c                	ld	a5,0(a0)
    800016d6:	9bbd                	andi	a5,a5,-17
    800016d8:	e11c                	sd	a5,0(a0)
}
    800016da:	60a2                	ld	ra,8(sp)
    800016dc:	6402                	ld	s0,0(sp)
    800016de:	0141                	addi	sp,sp,16
    800016e0:	8082                	ret
    panic("uvmclear");
    800016e2:	00007517          	auipc	a0,0x7
    800016e6:	bae50513          	addi	a0,a0,-1106 # 80008290 <digits+0x250>
    800016ea:	fffff097          	auipc	ra,0xfffff
    800016ee:	e54080e7          	jalr	-428(ra) # 8000053e <panic>

00000000800016f2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f2:	c6bd                	beqz	a3,80001760 <copyout+0x6e>
{
    800016f4:	715d                	addi	sp,sp,-80
    800016f6:	e486                	sd	ra,72(sp)
    800016f8:	e0a2                	sd	s0,64(sp)
    800016fa:	fc26                	sd	s1,56(sp)
    800016fc:	f84a                	sd	s2,48(sp)
    800016fe:	f44e                	sd	s3,40(sp)
    80001700:	f052                	sd	s4,32(sp)
    80001702:	ec56                	sd	s5,24(sp)
    80001704:	e85a                	sd	s6,16(sp)
    80001706:	e45e                	sd	s7,8(sp)
    80001708:	e062                	sd	s8,0(sp)
    8000170a:	0880                	addi	s0,sp,80
    8000170c:	8b2a                	mv	s6,a0
    8000170e:	8c2e                	mv	s8,a1
    80001710:	8a32                	mv	s4,a2
    80001712:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001714:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001716:	6a91                	lui	s5,0x4
    80001718:	a015                	j	8000173c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000171a:	9562                	add	a0,a0,s8
    8000171c:	0004861b          	sext.w	a2,s1
    80001720:	85d2                	mv	a1,s4
    80001722:	41250533          	sub	a0,a0,s2
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	61a080e7          	jalr	1562(ra) # 80000d40 <memmove>

    len -= n;
    8000172e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001732:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001734:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001738:	02098263          	beqz	s3,8000175c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000173c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001740:	85ca                	mv	a1,s2
    80001742:	855a                	mv	a0,s6
    80001744:	00000097          	auipc	ra,0x0
    80001748:	990080e7          	jalr	-1648(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000174c:	cd01                	beqz	a0,80001764 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000174e:	418904b3          	sub	s1,s2,s8
    80001752:	94d6                	add	s1,s1,s5
    if(n > len)
    80001754:	fc99f3e3          	bgeu	s3,s1,8000171a <copyout+0x28>
    80001758:	84ce                	mv	s1,s3
    8000175a:	b7c1                	j	8000171a <copyout+0x28>
  }
  return 0;
    8000175c:	4501                	li	a0,0
    8000175e:	a021                	j	80001766 <copyout+0x74>
    80001760:	4501                	li	a0,0
}
    80001762:	8082                	ret
      return -1;
    80001764:	557d                	li	a0,-1
}
    80001766:	60a6                	ld	ra,72(sp)
    80001768:	6406                	ld	s0,64(sp)
    8000176a:	74e2                	ld	s1,56(sp)
    8000176c:	7942                	ld	s2,48(sp)
    8000176e:	79a2                	ld	s3,40(sp)
    80001770:	7a02                	ld	s4,32(sp)
    80001772:	6ae2                	ld	s5,24(sp)
    80001774:	6b42                	ld	s6,16(sp)
    80001776:	6ba2                	ld	s7,8(sp)
    80001778:	6c02                	ld	s8,0(sp)
    8000177a:	6161                	addi	sp,sp,80
    8000177c:	8082                	ret

000000008000177e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000177e:	c6bd                	beqz	a3,800017ec <copyin+0x6e>
{
    80001780:	715d                	addi	sp,sp,-80
    80001782:	e486                	sd	ra,72(sp)
    80001784:	e0a2                	sd	s0,64(sp)
    80001786:	fc26                	sd	s1,56(sp)
    80001788:	f84a                	sd	s2,48(sp)
    8000178a:	f44e                	sd	s3,40(sp)
    8000178c:	f052                	sd	s4,32(sp)
    8000178e:	ec56                	sd	s5,24(sp)
    80001790:	e85a                	sd	s6,16(sp)
    80001792:	e45e                	sd	s7,8(sp)
    80001794:	e062                	sd	s8,0(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8b2a                	mv	s6,a0
    8000179a:	8a2e                	mv	s4,a1
    8000179c:	8c32                	mv	s8,a2
    8000179e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017a0:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a2:	6a91                	lui	s5,0x4
    800017a4:	a015                	j	800017c8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017a6:	9562                	add	a0,a0,s8
    800017a8:	0004861b          	sext.w	a2,s1
    800017ac:	412505b3          	sub	a1,a0,s2
    800017b0:	8552                	mv	a0,s4
    800017b2:	fffff097          	auipc	ra,0xfffff
    800017b6:	58e080e7          	jalr	1422(ra) # 80000d40 <memmove>

    len -= n;
    800017ba:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017be:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017c0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017c4:	02098263          	beqz	s3,800017e8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017c8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017cc:	85ca                	mv	a1,s2
    800017ce:	855a                	mv	a0,s6
    800017d0:	00000097          	auipc	ra,0x0
    800017d4:	904080e7          	jalr	-1788(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017d8:	cd01                	beqz	a0,800017f0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017da:	418904b3          	sub	s1,s2,s8
    800017de:	94d6                	add	s1,s1,s5
    if(n > len)
    800017e0:	fc99f3e3          	bgeu	s3,s1,800017a6 <copyin+0x28>
    800017e4:	84ce                	mv	s1,s3
    800017e6:	b7c1                	j	800017a6 <copyin+0x28>
  }
  return 0;
    800017e8:	4501                	li	a0,0
    800017ea:	a021                	j	800017f2 <copyin+0x74>
    800017ec:	4501                	li	a0,0
}
    800017ee:	8082                	ret
      return -1;
    800017f0:	557d                	li	a0,-1
}
    800017f2:	60a6                	ld	ra,72(sp)
    800017f4:	6406                	ld	s0,64(sp)
    800017f6:	74e2                	ld	s1,56(sp)
    800017f8:	7942                	ld	s2,48(sp)
    800017fa:	79a2                	ld	s3,40(sp)
    800017fc:	7a02                	ld	s4,32(sp)
    800017fe:	6ae2                	ld	s5,24(sp)
    80001800:	6b42                	ld	s6,16(sp)
    80001802:	6ba2                	ld	s7,8(sp)
    80001804:	6c02                	ld	s8,0(sp)
    80001806:	6161                	addi	sp,sp,80
    80001808:	8082                	ret

000000008000180a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000180a:	c6c5                	beqz	a3,800018b2 <copyinstr+0xa8>
{
    8000180c:	715d                	addi	sp,sp,-80
    8000180e:	e486                	sd	ra,72(sp)
    80001810:	e0a2                	sd	s0,64(sp)
    80001812:	fc26                	sd	s1,56(sp)
    80001814:	f84a                	sd	s2,48(sp)
    80001816:	f44e                	sd	s3,40(sp)
    80001818:	f052                	sd	s4,32(sp)
    8000181a:	ec56                	sd	s5,24(sp)
    8000181c:	e85a                	sd	s6,16(sp)
    8000181e:	e45e                	sd	s7,8(sp)
    80001820:	0880                	addi	s0,sp,80
    80001822:	8a2a                	mv	s4,a0
    80001824:	8b2e                	mv	s6,a1
    80001826:	8bb2                	mv	s7,a2
    80001828:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000182a:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000182c:	6991                	lui	s3,0x4
    8000182e:	a035                	j	8000185a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001830:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    80001834:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001836:	0017b793          	seqz	a5,a5
    8000183a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000183e:	60a6                	ld	ra,72(sp)
    80001840:	6406                	ld	s0,64(sp)
    80001842:	74e2                	ld	s1,56(sp)
    80001844:	7942                	ld	s2,48(sp)
    80001846:	79a2                	ld	s3,40(sp)
    80001848:	7a02                	ld	s4,32(sp)
    8000184a:	6ae2                	ld	s5,24(sp)
    8000184c:	6b42                	ld	s6,16(sp)
    8000184e:	6ba2                	ld	s7,8(sp)
    80001850:	6161                	addi	sp,sp,80
    80001852:	8082                	ret
    srcva = va0 + PGSIZE;
    80001854:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001858:	c8a9                	beqz	s1,800018aa <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000185a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000185e:	85ca                	mv	a1,s2
    80001860:	8552                	mv	a0,s4
    80001862:	00000097          	auipc	ra,0x0
    80001866:	872080e7          	jalr	-1934(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000186a:	c131                	beqz	a0,800018ae <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000186c:	41790833          	sub	a6,s2,s7
    80001870:	984e                	add	a6,a6,s3
    if(n > max)
    80001872:	0104f363          	bgeu	s1,a6,80001878 <copyinstr+0x6e>
    80001876:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001878:	955e                	add	a0,a0,s7
    8000187a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000187e:	fc080be3          	beqz	a6,80001854 <copyinstr+0x4a>
    80001882:	985a                	add	a6,a6,s6
    80001884:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001886:	41650633          	sub	a2,a0,s6
    8000188a:	14fd                	addi	s1,s1,-1
    8000188c:	9b26                	add	s6,s6,s1
    8000188e:	00f60733          	add	a4,a2,a5
    80001892:	00074703          	lbu	a4,0(a4)
    80001896:	df49                	beqz	a4,80001830 <copyinstr+0x26>
        *dst = *p;
    80001898:	00e78023          	sb	a4,0(a5)
      --max;
    8000189c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018a0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018a2:	ff0796e3          	bne	a5,a6,8000188e <copyinstr+0x84>
      dst++;
    800018a6:	8b42                	mv	s6,a6
    800018a8:	b775                	j	80001854 <copyinstr+0x4a>
    800018aa:	4781                	li	a5,0
    800018ac:	b769                	j	80001836 <copyinstr+0x2c>
      return -1;
    800018ae:	557d                	li	a0,-1
    800018b0:	b779                	j	8000183e <copyinstr+0x34>
  int got_null = 0;
    800018b2:	4781                	li	a5,0
  if(got_null){
    800018b4:	0017b793          	seqz	a5,a5
    800018b8:	40f00533          	neg	a0,a5
}
    800018bc:	8082                	ret

00000000800018be <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    800018be:	7139                	addi	sp,sp,-64
    800018c0:	fc06                	sd	ra,56(sp)
    800018c2:	f822                	sd	s0,48(sp)
    800018c4:	f426                	sd	s1,40(sp)
    800018c6:	f04a                	sd	s2,32(sp)
    800018c8:	ec4e                	sd	s3,24(sp)
    800018ca:	e852                	sd	s4,16(sp)
    800018cc:	e456                	sd	s5,8(sp)
    800018ce:	e05a                	sd	s6,0(sp)
    800018d0:	0080                	addi	s0,sp,64
    800018d2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d4:	00013497          	auipc	s1,0x13
    800018d8:	dfc48493          	addi	s1,s1,-516 # 800146d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018dc:	8b26                	mv	s6,s1
    800018de:	00006a97          	auipc	s5,0x6
    800018e2:	722a8a93          	addi	s5,s5,1826 # 80008000 <etext>
    800018e6:	00800937          	lui	s2,0x800
    800018ea:	197d                	addi	s2,s2,-1
    800018ec:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ee:	00018a17          	auipc	s4,0x18
    800018f2:	7e2a0a13          	addi	s4,s4,2018 # 8001a0d0 <tickslock>
    char *pa = kalloc();
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	1fe080e7          	jalr	510(ra) # 80000af4 <kalloc>
    800018fe:	862a                	mv	a2,a0
    if(pa == 0)
    80001900:	c131                	beqz	a0,80001944 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001902:	416485b3          	sub	a1,s1,s6
    80001906:	858d                	srai	a1,a1,0x3
    80001908:	000ab783          	ld	a5,0(s5)
    8000190c:	02f585b3          	mul	a1,a1,a5
    80001910:	2585                	addiw	a1,a1,1
    80001912:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001916:	4719                	li	a4,6
    80001918:	6691                	lui	a3,0x4
    8000191a:	40b905b3          	sub	a1,s2,a1
    8000191e:	854e                	mv	a0,s3
    80001920:	00000097          	auipc	ra,0x0
    80001924:	8b0080e7          	jalr	-1872(ra) # 800011d0 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	16848493          	addi	s1,s1,360
    8000192c:	fd4495e3          	bne	s1,s4,800018f6 <proc_mapstacks+0x38>
  }
}
    80001930:	70e2                	ld	ra,56(sp)
    80001932:	7442                	ld	s0,48(sp)
    80001934:	74a2                	ld	s1,40(sp)
    80001936:	7902                	ld	s2,32(sp)
    80001938:	69e2                	ld	s3,24(sp)
    8000193a:	6a42                	ld	s4,16(sp)
    8000193c:	6aa2                	ld	s5,8(sp)
    8000193e:	6b02                	ld	s6,0(sp)
    80001940:	6121                	addi	sp,sp,64
    80001942:	8082                	ret
      panic("kalloc");
    80001944:	00007517          	auipc	a0,0x7
    80001948:	95c50513          	addi	a0,a0,-1700 # 800082a0 <digits+0x260>
    8000194c:	fffff097          	auipc	ra,0xfffff
    80001950:	bf2080e7          	jalr	-1038(ra) # 8000053e <panic>

0000000080001954 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001954:	7139                	addi	sp,sp,-64
    80001956:	fc06                	sd	ra,56(sp)
    80001958:	f822                	sd	s0,48(sp)
    8000195a:	f426                	sd	s1,40(sp)
    8000195c:	f04a                	sd	s2,32(sp)
    8000195e:	ec4e                	sd	s3,24(sp)
    80001960:	e852                	sd	s4,16(sp)
    80001962:	e456                	sd	s5,8(sp)
    80001964:	e05a                	sd	s6,0(sp)
    80001966:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001968:	00007597          	auipc	a1,0x7
    8000196c:	94058593          	addi	a1,a1,-1728 # 800082a8 <digits+0x268>
    80001970:	00013517          	auipc	a0,0x13
    80001974:	93050513          	addi	a0,a0,-1744 # 800142a0 <pid_lock>
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	1dc080e7          	jalr	476(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001980:	00007597          	auipc	a1,0x7
    80001984:	93058593          	addi	a1,a1,-1744 # 800082b0 <digits+0x270>
    80001988:	00013517          	auipc	a0,0x13
    8000198c:	93050513          	addi	a0,a0,-1744 # 800142b8 <wait_lock>
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	1c4080e7          	jalr	452(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	00013497          	auipc	s1,0x13
    8000199c:	d3848493          	addi	s1,s1,-712 # 800146d0 <proc>
      initlock(&p->lock, "proc");
    800019a0:	00007b17          	auipc	s6,0x7
    800019a4:	920b0b13          	addi	s6,s6,-1760 # 800082c0 <digits+0x280>
      p->kstack = KSTACK((int) (p - proc));
    800019a8:	8aa6                	mv	s5,s1
    800019aa:	00006a17          	auipc	s4,0x6
    800019ae:	656a0a13          	addi	s4,s4,1622 # 80008000 <etext>
    800019b2:	00800937          	lui	s2,0x800
    800019b6:	197d                	addi	s2,s2,-1
    800019b8:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ba:	00018997          	auipc	s3,0x18
    800019be:	71698993          	addi	s3,s3,1814 # 8001a0d0 <tickslock>
      initlock(&p->lock, "proc");
    800019c2:	85da                	mv	a1,s6
    800019c4:	8526                	mv	a0,s1
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	18e080e7          	jalr	398(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019ce:	415487b3          	sub	a5,s1,s5
    800019d2:	878d                	srai	a5,a5,0x3
    800019d4:	000a3703          	ld	a4,0(s4)
    800019d8:	02e787b3          	mul	a5,a5,a4
    800019dc:	2785                	addiw	a5,a5,1
    800019de:	00f7979b          	slliw	a5,a5,0xf
    800019e2:	40f907b3          	sub	a5,s2,a5
    800019e6:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e8:	16848493          	addi	s1,s1,360
    800019ec:	fd349be3          	bne	s1,s3,800019c2 <procinit+0x6e>
  }
}
    800019f0:	70e2                	ld	ra,56(sp)
    800019f2:	7442                	ld	s0,48(sp)
    800019f4:	74a2                	ld	s1,40(sp)
    800019f6:	7902                	ld	s2,32(sp)
    800019f8:	69e2                	ld	s3,24(sp)
    800019fa:	6a42                	ld	s4,16(sp)
    800019fc:	6aa2                	ld	s5,8(sp)
    800019fe:	6b02                	ld	s6,0(sp)
    80001a00:	6121                	addi	sp,sp,64
    80001a02:	8082                	ret

0000000080001a04 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e422                	sd	s0,8(sp)
    80001a08:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a0a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a0c:	2501                	sext.w	a0,a0
    80001a0e:	6422                	ld	s0,8(sp)
    80001a10:	0141                	addi	sp,sp,16
    80001a12:	8082                	ret

0000000080001a14 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a14:	1141                	addi	sp,sp,-16
    80001a16:	e422                	sd	s0,8(sp)
    80001a18:	0800                	addi	s0,sp,16
    80001a1a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a1c:	2781                	sext.w	a5,a5
    80001a1e:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a20:	00013517          	auipc	a0,0x13
    80001a24:	8b050513          	addi	a0,a0,-1872 # 800142d0 <cpus>
    80001a28:	953e                	add	a0,a0,a5
    80001a2a:	6422                	ld	s0,8(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret

0000000080001a30 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	1000                	addi	s0,sp,32
  push_off();
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	15e080e7          	jalr	350(ra) # 80000b98 <push_off>
    80001a42:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a44:	2781                	sext.w	a5,a5
    80001a46:	079e                	slli	a5,a5,0x7
    80001a48:	00013717          	auipc	a4,0x13
    80001a4c:	85870713          	addi	a4,a4,-1960 # 800142a0 <pid_lock>
    80001a50:	97ba                	add	a5,a5,a4
    80001a52:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	1e4080e7          	jalr	484(ra) # 80000c38 <pop_off>
  return p;
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6105                	addi	sp,sp,32
    80001a66:	8082                	ret

0000000080001a68 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a68:	1141                	addi	sp,sp,-16
    80001a6a:	e406                	sd	ra,8(sp)
    80001a6c:	e022                	sd	s0,0(sp)
    80001a6e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	fc0080e7          	jalr	-64(ra) # 80001a30 <myproc>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	220080e7          	jalr	544(ra) # 80000c98 <release>

  if (first) {
    80001a80:	00007797          	auipc	a5,0x7
    80001a84:	e607a783          	lw	a5,-416(a5) # 800088e0 <first.1672>
    80001a88:	eb89                	bnez	a5,80001a9a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	c0a080e7          	jalr	-1014(ra) # 80002694 <usertrapret>
}
    80001a92:	60a2                	ld	ra,8(sp)
    80001a94:	6402                	ld	s0,0(sp)
    80001a96:	0141                	addi	sp,sp,16
    80001a98:	8082                	ret
    first = 0;
    80001a9a:	00007797          	auipc	a5,0x7
    80001a9e:	e407a323          	sw	zero,-442(a5) # 800088e0 <first.1672>
    fsinit(ROOTDEV);
    80001aa2:	4505                	li	a0,1
    80001aa4:	00002097          	auipc	ra,0x2
    80001aa8:	932080e7          	jalr	-1742(ra) # 800033d6 <fsinit>
    80001aac:	bff9                	j	80001a8a <forkret+0x22>

0000000080001aae <allocpid>:
allocpid() {
    80001aae:	1101                	addi	sp,sp,-32
    80001ab0:	ec06                	sd	ra,24(sp)
    80001ab2:	e822                	sd	s0,16(sp)
    80001ab4:	e426                	sd	s1,8(sp)
    80001ab6:	e04a                	sd	s2,0(sp)
    80001ab8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aba:	00012917          	auipc	s2,0x12
    80001abe:	7e690913          	addi	s2,s2,2022 # 800142a0 <pid_lock>
    80001ac2:	854a                	mv	a0,s2
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	120080e7          	jalr	288(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001acc:	00007797          	auipc	a5,0x7
    80001ad0:	e1878793          	addi	a5,a5,-488 # 800088e4 <nextpid>
    80001ad4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad6:	0014871b          	addiw	a4,s1,1
    80001ada:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001adc:	854a                	mv	a0,s2
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
}
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	60e2                	ld	ra,24(sp)
    80001aea:	6442                	ld	s0,16(sp)
    80001aec:	64a2                	ld	s1,8(sp)
    80001aee:	6902                	ld	s2,0(sp)
    80001af0:	6105                	addi	sp,sp,32
    80001af2:	8082                	ret

0000000080001af4 <proc_pagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b02:	00000097          	auipc	ra,0x0
    80001b06:	8b8080e7          	jalr	-1864(ra) # 800013ba <uvmcreate>
    80001b0a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b0c:	c121                	beqz	a0,80001b4c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0e:	4729                	li	a4,10
    80001b10:	00005697          	auipc	a3,0x5
    80001b14:	4f068693          	addi	a3,a3,1264 # 80007000 <_trampoline>
    80001b18:	6611                	lui	a2,0x4
    80001b1a:	008005b7          	lui	a1,0x800
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05ba                	slli	a1,a1,0xe
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	5f4080e7          	jalr	1524(ra) # 80001116 <mappages>
    80001b2a:	02054863          	bltz	a0,80001b5a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2e:	4719                	li	a4,6
    80001b30:	05893683          	ld	a3,88(s2)
    80001b34:	6611                	lui	a2,0x4
    80001b36:	004005b7          	lui	a1,0x400
    80001b3a:	15fd                	addi	a1,a1,-1
    80001b3c:	05be                	slli	a1,a1,0xf
    80001b3e:	8526                	mv	a0,s1
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	5d6080e7          	jalr	1494(ra) # 80001116 <mappages>
    80001b48:	02054163          	bltz	a0,80001b6a <proc_pagetable+0x76>
}
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	60e2                	ld	ra,24(sp)
    80001b50:	6442                	ld	s0,16(sp)
    80001b52:	64a2                	ld	s1,8(sp)
    80001b54:	6902                	ld	s2,0(sp)
    80001b56:	6105                	addi	sp,sp,32
    80001b58:	8082                	ret
    uvmfree(pagetable, 0);
    80001b5a:	4581                	li	a1,0
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	a58080e7          	jalr	-1448(ra) # 800015b6 <uvmfree>
    return 0;
    80001b66:	4481                	li	s1,0
    80001b68:	b7d5                	j	80001b4c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6a:	4681                	li	a3,0
    80001b6c:	4605                	li	a2,1
    80001b6e:	008005b7          	lui	a1,0x800
    80001b72:	15fd                	addi	a1,a1,-1
    80001b74:	05ba                	slli	a1,a1,0xe
    80001b76:	8526                	mv	a0,s1
    80001b78:	fffff097          	auipc	ra,0xfffff
    80001b7c:	77e080e7          	jalr	1918(ra) # 800012f6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b80:	4581                	li	a1,0
    80001b82:	8526                	mv	a0,s1
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	a32080e7          	jalr	-1486(ra) # 800015b6 <uvmfree>
    return 0;
    80001b8c:	4481                	li	s1,0
    80001b8e:	bf7d                	j	80001b4c <proc_pagetable+0x58>

0000000080001b90 <proc_freepagetable>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
    80001b9c:	84aa                	mv	s1,a0
    80001b9e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ba0:	4681                	li	a3,0
    80001ba2:	4605                	li	a2,1
    80001ba4:	008005b7          	lui	a1,0x800
    80001ba8:	15fd                	addi	a1,a1,-1
    80001baa:	05ba                	slli	a1,a1,0xe
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	74a080e7          	jalr	1866(ra) # 800012f6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb4:	4681                	li	a3,0
    80001bb6:	4605                	li	a2,1
    80001bb8:	004005b7          	lui	a1,0x400
    80001bbc:	15fd                	addi	a1,a1,-1
    80001bbe:	05be                	slli	a1,a1,0xf
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	734080e7          	jalr	1844(ra) # 800012f6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bca:	85ca                	mv	a1,s2
    80001bcc:	8526                	mv	a0,s1
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	9e8080e7          	jalr	-1560(ra) # 800015b6 <uvmfree>
}
    80001bd6:	60e2                	ld	ra,24(sp)
    80001bd8:	6442                	ld	s0,16(sp)
    80001bda:	64a2                	ld	s1,8(sp)
    80001bdc:	6902                	ld	s2,0(sp)
    80001bde:	6105                	addi	sp,sp,32
    80001be0:	8082                	ret

0000000080001be2 <freeproc>:
{
    80001be2:	1101                	addi	sp,sp,-32
    80001be4:	ec06                	sd	ra,24(sp)
    80001be6:	e822                	sd	s0,16(sp)
    80001be8:	e426                	sd	s1,8(sp)
    80001bea:	1000                	addi	s0,sp,32
    80001bec:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bee:	6d28                	ld	a0,88(a0)
    80001bf0:	c509                	beqz	a0,80001bfa <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	e06080e7          	jalr	-506(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bfa:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bfe:	68a8                	ld	a0,80(s1)
    80001c00:	c511                	beqz	a0,80001c0c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c02:	64ac                	ld	a1,72(s1)
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	f8c080e7          	jalr	-116(ra) # 80001b90 <proc_freepagetable>
  p->pagetable = 0;
    80001c0c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c10:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c14:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c18:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c1c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c20:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c24:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c28:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c2c:	0004ac23          	sw	zero,24(s1)
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret

0000000080001c3a <allocproc>:
{
    80001c3a:	1101                	addi	sp,sp,-32
    80001c3c:	ec06                	sd	ra,24(sp)
    80001c3e:	e822                	sd	s0,16(sp)
    80001c40:	e426                	sd	s1,8(sp)
    80001c42:	e04a                	sd	s2,0(sp)
    80001c44:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c46:	00013497          	auipc	s1,0x13
    80001c4a:	a8a48493          	addi	s1,s1,-1398 # 800146d0 <proc>
    80001c4e:	00018917          	auipc	s2,0x18
    80001c52:	48290913          	addi	s2,s2,1154 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	f8c080e7          	jalr	-116(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c60:	4c9c                	lw	a5,24(s1)
    80001c62:	cf81                	beqz	a5,80001c7a <allocproc+0x40>
      release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	032080e7          	jalr	50(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6e:	16848493          	addi	s1,s1,360
    80001c72:	ff2492e3          	bne	s1,s2,80001c56 <allocproc+0x1c>
  return 0;
    80001c76:	4481                	li	s1,0
    80001c78:	a889                	j	80001cca <allocproc+0x90>
  p->pid = allocpid();
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	e34080e7          	jalr	-460(ra) # 80001aae <allocpid>
    80001c82:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c84:	4785                	li	a5,1
    80001c86:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	e6c080e7          	jalr	-404(ra) # 80000af4 <kalloc>
    80001c90:	892a                	mv	s2,a0
    80001c92:	eca8                	sd	a0,88(s1)
    80001c94:	c131                	beqz	a0,80001cd8 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c96:	8526                	mv	a0,s1
    80001c98:	00000097          	auipc	ra,0x0
    80001c9c:	e5c080e7          	jalr	-420(ra) # 80001af4 <proc_pagetable>
    80001ca0:	892a                	mv	s2,a0
    80001ca2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ca4:	c531                	beqz	a0,80001cf0 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001ca6:	07000613          	li	a2,112
    80001caa:	4581                	li	a1,0
    80001cac:	06048513          	addi	a0,s1,96
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	030080e7          	jalr	48(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cb8:	00000797          	auipc	a5,0x0
    80001cbc:	db078793          	addi	a5,a5,-592 # 80001a68 <forkret>
    80001cc0:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cc2:	60bc                	ld	a5,64(s1)
    80001cc4:	6711                	lui	a4,0x4
    80001cc6:	97ba                	add	a5,a5,a4
    80001cc8:	f4bc                	sd	a5,104(s1)
}
    80001cca:	8526                	mv	a0,s1
    80001ccc:	60e2                	ld	ra,24(sp)
    80001cce:	6442                	ld	s0,16(sp)
    80001cd0:	64a2                	ld	s1,8(sp)
    80001cd2:	6902                	ld	s2,0(sp)
    80001cd4:	6105                	addi	sp,sp,32
    80001cd6:	8082                	ret
    freeproc(p);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f08080e7          	jalr	-248(ra) # 80001be2 <freeproc>
    release(&p->lock);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>
    return 0;
    80001cec:	84ca                	mv	s1,s2
    80001cee:	bff1                	j	80001cca <allocproc+0x90>
    freeproc(p);
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	00000097          	auipc	ra,0x0
    80001cf6:	ef0080e7          	jalr	-272(ra) # 80001be2 <freeproc>
    release(&p->lock);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	f9c080e7          	jalr	-100(ra) # 80000c98 <release>
    return 0;
    80001d04:	84ca                	mv	s1,s2
    80001d06:	b7d1                	j	80001cca <allocproc+0x90>

0000000080001d08 <userinit>:
{
    80001d08:	1101                	addi	sp,sp,-32
    80001d0a:	ec06                	sd	ra,24(sp)
    80001d0c:	e822                	sd	s0,16(sp)
    80001d0e:	e426                	sd	s1,8(sp)
    80001d10:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	f28080e7          	jalr	-216(ra) # 80001c3a <allocproc>
    80001d1a:	84aa                	mv	s1,a0
  initproc = p;
    80001d1c:	0000a797          	auipc	a5,0xa
    80001d20:	30a7b623          	sd	a0,780(a5) # 8000c028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d24:	03400613          	li	a2,52
    80001d28:	00007597          	auipc	a1,0x7
    80001d2c:	bc858593          	addi	a1,a1,-1080 # 800088f0 <initcode>
    80001d30:	6928                	ld	a0,80(a0)
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	6b6080e7          	jalr	1718(ra) # 800013e8 <uvminit>
  p->sz = PGSIZE;
    80001d3a:	6791                	lui	a5,0x4
    80001d3c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d3e:	6cb8                	ld	a4,88(s1)
    80001d40:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d44:	6cb8                	ld	a4,88(s1)
    80001d46:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d48:	4641                	li	a2,16
    80001d4a:	00006597          	auipc	a1,0x6
    80001d4e:	57e58593          	addi	a1,a1,1406 # 800082c8 <digits+0x288>
    80001d52:	15848513          	addi	a0,s1,344
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	0dc080e7          	jalr	220(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d5e:	00006517          	auipc	a0,0x6
    80001d62:	57a50513          	addi	a0,a0,1402 # 800082d8 <digits+0x298>
    80001d66:	00002097          	auipc	ra,0x2
    80001d6a:	09e080e7          	jalr	158(ra) # 80003e04 <namei>
    80001d6e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d72:	478d                	li	a5,3
    80001d74:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	f20080e7          	jalr	-224(ra) # 80000c98 <release>
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret

0000000080001d8a <growproc>:
{
    80001d8a:	1101                	addi	sp,sp,-32
    80001d8c:	ec06                	sd	ra,24(sp)
    80001d8e:	e822                	sd	s0,16(sp)
    80001d90:	e426                	sd	s1,8(sp)
    80001d92:	e04a                	sd	s2,0(sp)
    80001d94:	1000                	addi	s0,sp,32
    80001d96:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	c98080e7          	jalr	-872(ra) # 80001a30 <myproc>
    80001da0:	892a                	mv	s2,a0
  sz = p->sz;
    80001da2:	652c                	ld	a1,72(a0)
    80001da4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001da8:	00904f63          	bgtz	s1,80001dc6 <growproc+0x3c>
  } else if(n < 0){
    80001dac:	0204cc63          	bltz	s1,80001de4 <growproc+0x5a>
  p->sz = sz;
    80001db0:	1602                	slli	a2,a2,0x20
    80001db2:	9201                	srli	a2,a2,0x20
    80001db4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001db8:	4501                	li	a0,0
}
    80001dba:	60e2                	ld	ra,24(sp)
    80001dbc:	6442                	ld	s0,16(sp)
    80001dbe:	64a2                	ld	s1,8(sp)
    80001dc0:	6902                	ld	s2,0(sp)
    80001dc2:	6105                	addi	sp,sp,32
    80001dc4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc6:	9e25                	addw	a2,a2,s1
    80001dc8:	1602                	slli	a2,a2,0x20
    80001dca:	9201                	srli	a2,a2,0x20
    80001dcc:	1582                	slli	a1,a1,0x20
    80001dce:	9181                	srli	a1,a1,0x20
    80001dd0:	6928                	ld	a0,80(a0)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	6d0080e7          	jalr	1744(ra) # 800014a2 <uvmalloc>
    80001dda:	0005061b          	sext.w	a2,a0
    80001dde:	fa69                	bnez	a2,80001db0 <growproc+0x26>
      return -1;
    80001de0:	557d                	li	a0,-1
    80001de2:	bfe1                	j	80001dba <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de4:	9e25                	addw	a2,a2,s1
    80001de6:	1602                	slli	a2,a2,0x20
    80001de8:	9201                	srli	a2,a2,0x20
    80001dea:	1582                	slli	a1,a1,0x20
    80001dec:	9181                	srli	a1,a1,0x20
    80001dee:	6928                	ld	a0,80(a0)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	66a080e7          	jalr	1642(ra) # 8000145a <uvmdealloc>
    80001df8:	0005061b          	sext.w	a2,a0
    80001dfc:	bf55                	j	80001db0 <growproc+0x26>

0000000080001dfe <fork>:
{
    80001dfe:	7179                	addi	sp,sp,-48
    80001e00:	f406                	sd	ra,40(sp)
    80001e02:	f022                	sd	s0,32(sp)
    80001e04:	ec26                	sd	s1,24(sp)
    80001e06:	e84a                	sd	s2,16(sp)
    80001e08:	e44e                	sd	s3,8(sp)
    80001e0a:	e052                	sd	s4,0(sp)
    80001e0c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e0e:	00000097          	auipc	ra,0x0
    80001e12:	c22080e7          	jalr	-990(ra) # 80001a30 <myproc>
    80001e16:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	e22080e7          	jalr	-478(ra) # 80001c3a <allocproc>
    80001e20:	10050b63          	beqz	a0,80001f36 <fork+0x138>
    80001e24:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e26:	04893603          	ld	a2,72(s2)
    80001e2a:	692c                	ld	a1,80(a0)
    80001e2c:	05093503          	ld	a0,80(s2)
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	7be080e7          	jalr	1982(ra) # 800015ee <uvmcopy>
    80001e38:	04054663          	bltz	a0,80001e84 <fork+0x86>
  np->sz = p->sz;
    80001e3c:	04893783          	ld	a5,72(s2)
    80001e40:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e44:	05893683          	ld	a3,88(s2)
    80001e48:	87b6                	mv	a5,a3
    80001e4a:	0589b703          	ld	a4,88(s3)
    80001e4e:	12068693          	addi	a3,a3,288
    80001e52:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001e56:	6788                	ld	a0,8(a5)
    80001e58:	6b8c                	ld	a1,16(a5)
    80001e5a:	6f90                	ld	a2,24(a5)
    80001e5c:	01073023          	sd	a6,0(a4)
    80001e60:	e708                	sd	a0,8(a4)
    80001e62:	eb0c                	sd	a1,16(a4)
    80001e64:	ef10                	sd	a2,24(a4)
    80001e66:	02078793          	addi	a5,a5,32
    80001e6a:	02070713          	addi	a4,a4,32
    80001e6e:	fed792e3          	bne	a5,a3,80001e52 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e72:	0589b783          	ld	a5,88(s3)
    80001e76:	0607b823          	sd	zero,112(a5)
    80001e7a:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e7e:	15000a13          	li	s4,336
    80001e82:	a03d                	j	80001eb0 <fork+0xb2>
    freeproc(np);
    80001e84:	854e                	mv	a0,s3
    80001e86:	00000097          	auipc	ra,0x0
    80001e8a:	d5c080e7          	jalr	-676(ra) # 80001be2 <freeproc>
    release(&np->lock);
    80001e8e:	854e                	mv	a0,s3
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	e08080e7          	jalr	-504(ra) # 80000c98 <release>
    return -1;
    80001e98:	5a7d                	li	s4,-1
    80001e9a:	a069                	j	80001f24 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e9c:	00002097          	auipc	ra,0x2
    80001ea0:	5fe080e7          	jalr	1534(ra) # 8000449a <filedup>
    80001ea4:	009987b3          	add	a5,s3,s1
    80001ea8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001eaa:	04a1                	addi	s1,s1,8
    80001eac:	01448763          	beq	s1,s4,80001eba <fork+0xbc>
    if(p->ofile[i])
    80001eb0:	009907b3          	add	a5,s2,s1
    80001eb4:	6388                	ld	a0,0(a5)
    80001eb6:	f17d                	bnez	a0,80001e9c <fork+0x9e>
    80001eb8:	bfcd                	j	80001eaa <fork+0xac>
  np->cwd = idup(p->cwd);
    80001eba:	15093503          	ld	a0,336(s2)
    80001ebe:	00001097          	auipc	ra,0x1
    80001ec2:	752080e7          	jalr	1874(ra) # 80003610 <idup>
    80001ec6:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eca:	4641                	li	a2,16
    80001ecc:	15890593          	addi	a1,s2,344
    80001ed0:	15898513          	addi	a0,s3,344
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	f5e080e7          	jalr	-162(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001edc:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ee0:	854e                	mv	a0,s3
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	db6080e7          	jalr	-586(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eea:	00012497          	auipc	s1,0x12
    80001eee:	3ce48493          	addi	s1,s1,974 # 800142b8 <wait_lock>
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	cf0080e7          	jalr	-784(ra) # 80000be4 <acquire>
  np->parent = p;
    80001efc:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f00:	8526                	mv	a0,s1
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	d96080e7          	jalr	-618(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f0a:	854e                	mv	a0,s3
    80001f0c:	fffff097          	auipc	ra,0xfffff
    80001f10:	cd8080e7          	jalr	-808(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f14:	478d                	li	a5,3
    80001f16:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f1a:	854e                	mv	a0,s3
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	d7c080e7          	jalr	-644(ra) # 80000c98 <release>
}
    80001f24:	8552                	mv	a0,s4
    80001f26:	70a2                	ld	ra,40(sp)
    80001f28:	7402                	ld	s0,32(sp)
    80001f2a:	64e2                	ld	s1,24(sp)
    80001f2c:	6942                	ld	s2,16(sp)
    80001f2e:	69a2                	ld	s3,8(sp)
    80001f30:	6a02                	ld	s4,0(sp)
    80001f32:	6145                	addi	sp,sp,48
    80001f34:	8082                	ret
    return -1;
    80001f36:	5a7d                	li	s4,-1
    80001f38:	b7f5                	j	80001f24 <fork+0x126>

0000000080001f3a <scheduler>:
{
    80001f3a:	7139                	addi	sp,sp,-64
    80001f3c:	fc06                	sd	ra,56(sp)
    80001f3e:	f822                	sd	s0,48(sp)
    80001f40:	f426                	sd	s1,40(sp)
    80001f42:	f04a                	sd	s2,32(sp)
    80001f44:	ec4e                	sd	s3,24(sp)
    80001f46:	e852                	sd	s4,16(sp)
    80001f48:	e456                	sd	s5,8(sp)
    80001f4a:	e05a                	sd	s6,0(sp)
    80001f4c:	0080                	addi	s0,sp,64
    80001f4e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f50:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f52:	00779a93          	slli	s5,a5,0x7
    80001f56:	00012717          	auipc	a4,0x12
    80001f5a:	34a70713          	addi	a4,a4,842 # 800142a0 <pid_lock>
    80001f5e:	9756                	add	a4,a4,s5
    80001f60:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f64:	00012717          	auipc	a4,0x12
    80001f68:	37470713          	addi	a4,a4,884 # 800142d8 <cpus+0x8>
    80001f6c:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f6e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f70:	4b11                	li	s6,4
        c->proc = p;
    80001f72:	079e                	slli	a5,a5,0x7
    80001f74:	00012a17          	auipc	s4,0x12
    80001f78:	32ca0a13          	addi	s4,s4,812 # 800142a0 <pid_lock>
    80001f7c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7e:	00018917          	auipc	s2,0x18
    80001f82:	15290913          	addi	s2,s2,338 # 8001a0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f8e:	10079073          	csrw	sstatus,a5
    80001f92:	00012497          	auipc	s1,0x12
    80001f96:	73e48493          	addi	s1,s1,1854 # 800146d0 <proc>
    80001f9a:	a03d                	j	80001fc8 <scheduler+0x8e>
        p->state = RUNNING;
    80001f9c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fa0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fa4:	06048593          	addi	a1,s1,96
    80001fa8:	8556                	mv	a0,s5
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	640080e7          	jalr	1600(ra) # 800025ea <swtch>
        c->proc = 0;
    80001fb2:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fb6:	8526                	mv	a0,s1
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc0:	16848493          	addi	s1,s1,360
    80001fc4:	fd2481e3          	beq	s1,s2,80001f86 <scheduler+0x4c>
      acquire(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	c1a080e7          	jalr	-998(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fd2:	4c9c                	lw	a5,24(s1)
    80001fd4:	ff3791e3          	bne	a5,s3,80001fb6 <scheduler+0x7c>
    80001fd8:	b7d1                	j	80001f9c <scheduler+0x62>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	a48080e7          	jalr	-1464(ra) # 80001a30 <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	b78080e7          	jalr	-1160(ra) # 80000b6a <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00012717          	auipc	a4,0x12
    80002006:	29e70713          	addi	a4,a4,670 # 800142a0 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0a87a703          	lw	a4,168(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	4791                	li	a5,4
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	00012917          	auipc	s2,0x12
    8000202c:	27890913          	addi	s2,s2,632 # 800142a0 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0ac7a983          	lw	s3,172(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	00012597          	auipc	a1,0x12
    80002044:	29858593          	addi	a1,a1,664 # 800142d8 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	06048513          	addi	a0,s1,96
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	59c080e7          	jalr	1436(ra) # 800025ea <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0b37a623          	sw	s3,172(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	27050513          	addi	a0,a0,624 # 800082e0 <digits+0x2a0>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4c6080e7          	jalr	1222(ra) # 8000053e <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	27050513          	addi	a0,a0,624 # 800082f0 <digits+0x2b0>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4b6080e7          	jalr	1206(ra) # 8000053e <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	27050513          	addi	a0,a0,624 # 80008300 <digits+0x2c0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4a6080e7          	jalr	1190(ra) # 8000053e <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	27050513          	addi	a0,a0,624 # 80008310 <digits+0x2d0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	496080e7          	jalr	1174(ra) # 8000053e <panic>

00000000800020b0 <yield>:
{
    800020b0:	1101                	addi	sp,sp,-32
    800020b2:	ec06                	sd	ra,24(sp)
    800020b4:	e822                	sd	s0,16(sp)
    800020b6:	e426                	sd	s1,8(sp)
    800020b8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	976080e7          	jalr	-1674(ra) # 80001a30 <myproc>
    800020c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b20080e7          	jalr	-1248(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	cc9c                	sw	a5,24(s1)
  sched();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	f0a080e7          	jalr	-246(ra) # 80001fda <sched>
  release(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bbe080e7          	jalr	-1090(ra) # 80000c98 <release>
}
    800020e2:	60e2                	ld	ra,24(sp)
    800020e4:	6442                	ld	s0,16(sp)
    800020e6:	64a2                	ld	s1,8(sp)
    800020e8:	6105                	addi	sp,sp,32
    800020ea:	8082                	ret

00000000800020ec <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ec:	7179                	addi	sp,sp,-48
    800020ee:	f406                	sd	ra,40(sp)
    800020f0:	f022                	sd	s0,32(sp)
    800020f2:	ec26                	sd	s1,24(sp)
    800020f4:	e84a                	sd	s2,16(sp)
    800020f6:	e44e                	sd	s3,8(sp)
    800020f8:	1800                	addi	s0,sp,48
    800020fa:	89aa                	mv	s3,a0
    800020fc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	932080e7          	jalr	-1742(ra) # 80001a30 <myproc>
    80002106:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
  release(lk);
    80002110:	854a                	mv	a0,s2
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b86080e7          	jalr	-1146(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000211a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000211e:	4789                	li	a5,2
    80002120:	cc9c                	sw	a5,24(s1)

  sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	eb8080e7          	jalr	-328(ra) # 80001fda <sched>

  // Tidy up.
  p->chan = 0;
    8000212a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b68080e7          	jalr	-1176(ra) # 80000c98 <release>
  acquire(lk);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	aaa080e7          	jalr	-1366(ra) # 80000be4 <acquire>
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret

0000000080002150 <wait>:
{
    80002150:	715d                	addi	sp,sp,-80
    80002152:	e486                	sd	ra,72(sp)
    80002154:	e0a2                	sd	s0,64(sp)
    80002156:	fc26                	sd	s1,56(sp)
    80002158:	f84a                	sd	s2,48(sp)
    8000215a:	f44e                	sd	s3,40(sp)
    8000215c:	f052                	sd	s4,32(sp)
    8000215e:	ec56                	sd	s5,24(sp)
    80002160:	e85a                	sd	s6,16(sp)
    80002162:	e45e                	sd	s7,8(sp)
    80002164:	e062                	sd	s8,0(sp)
    80002166:	0880                	addi	s0,sp,80
    80002168:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	8c6080e7          	jalr	-1850(ra) # 80001a30 <myproc>
    80002172:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002174:	00012517          	auipc	a0,0x12
    80002178:	14450513          	addi	a0,a0,324 # 800142b8 <wait_lock>
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
    havekids = 0;
    80002184:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002186:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002188:	00018997          	auipc	s3,0x18
    8000218c:	f4898993          	addi	s3,s3,-184 # 8001a0d0 <tickslock>
        havekids = 1;
    80002190:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002192:	00012c17          	auipc	s8,0x12
    80002196:	126c0c13          	addi	s8,s8,294 # 800142b8 <wait_lock>
    havekids = 0;
    8000219a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000219c:	00012497          	auipc	s1,0x12
    800021a0:	53448493          	addi	s1,s1,1332 # 800146d0 <proc>
    800021a4:	a0bd                	j	80002212 <wait+0xc2>
          pid = np->pid;
    800021a6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021aa:	000b0e63          	beqz	s6,800021c6 <wait+0x76>
    800021ae:	4691                	li	a3,4
    800021b0:	02c48613          	addi	a2,s1,44
    800021b4:	85da                	mv	a1,s6
    800021b6:	05093503          	ld	a0,80(s2)
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	538080e7          	jalr	1336(ra) # 800016f2 <copyout>
    800021c2:	02054563          	bltz	a0,800021ec <wait+0x9c>
          freeproc(np);
    800021c6:	8526                	mv	a0,s1
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	a1a080e7          	jalr	-1510(ra) # 80001be2 <freeproc>
          release(&np->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
          release(&wait_lock);
    800021da:	00012517          	auipc	a0,0x12
    800021de:	0de50513          	addi	a0,a0,222 # 800142b8 <wait_lock>
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	ab6080e7          	jalr	-1354(ra) # 80000c98 <release>
          return pid;
    800021ea:	a09d                	j	80002250 <wait+0x100>
            release(&np->lock);
    800021ec:	8526                	mv	a0,s1
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	aaa080e7          	jalr	-1366(ra) # 80000c98 <release>
            release(&wait_lock);
    800021f6:	00012517          	auipc	a0,0x12
    800021fa:	0c250513          	addi	a0,a0,194 # 800142b8 <wait_lock>
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
            return -1;
    80002206:	59fd                	li	s3,-1
    80002208:	a0a1                	j	80002250 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000220a:	16848493          	addi	s1,s1,360
    8000220e:	03348463          	beq	s1,s3,80002236 <wait+0xe6>
      if(np->parent == p){
    80002212:	7c9c                	ld	a5,56(s1)
    80002214:	ff279be3          	bne	a5,s2,8000220a <wait+0xba>
        acquire(&np->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	9ca080e7          	jalr	-1590(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002222:	4c9c                	lw	a5,24(s1)
    80002224:	f94781e3          	beq	a5,s4,800021a6 <wait+0x56>
        release(&np->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	a6e080e7          	jalr	-1426(ra) # 80000c98 <release>
        havekids = 1;
    80002232:	8756                	mv	a4,s5
    80002234:	bfd9                	j	8000220a <wait+0xba>
    if(!havekids || p->killed){
    80002236:	c701                	beqz	a4,8000223e <wait+0xee>
    80002238:	02892783          	lw	a5,40(s2)
    8000223c:	c79d                	beqz	a5,8000226a <wait+0x11a>
      release(&wait_lock);
    8000223e:	00012517          	auipc	a0,0x12
    80002242:	07a50513          	addi	a0,a0,122 # 800142b8 <wait_lock>
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
      return -1;
    8000224e:	59fd                	li	s3,-1
}
    80002250:	854e                	mv	a0,s3
    80002252:	60a6                	ld	ra,72(sp)
    80002254:	6406                	ld	s0,64(sp)
    80002256:	74e2                	ld	s1,56(sp)
    80002258:	7942                	ld	s2,48(sp)
    8000225a:	79a2                	ld	s3,40(sp)
    8000225c:	7a02                	ld	s4,32(sp)
    8000225e:	6ae2                	ld	s5,24(sp)
    80002260:	6b42                	ld	s6,16(sp)
    80002262:	6ba2                	ld	s7,8(sp)
    80002264:	6c02                	ld	s8,0(sp)
    80002266:	6161                	addi	sp,sp,80
    80002268:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000226a:	85e2                	mv	a1,s8
    8000226c:	854a                	mv	a0,s2
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	e7e080e7          	jalr	-386(ra) # 800020ec <sleep>
    havekids = 0;
    80002276:	b715                	j	8000219a <wait+0x4a>

0000000080002278 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002278:	7139                	addi	sp,sp,-64
    8000227a:	fc06                	sd	ra,56(sp)
    8000227c:	f822                	sd	s0,48(sp)
    8000227e:	f426                	sd	s1,40(sp)
    80002280:	f04a                	sd	s2,32(sp)
    80002282:	ec4e                	sd	s3,24(sp)
    80002284:	e852                	sd	s4,16(sp)
    80002286:	e456                	sd	s5,8(sp)
    80002288:	0080                	addi	s0,sp,64
    8000228a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000228c:	00012497          	auipc	s1,0x12
    80002290:	44448493          	addi	s1,s1,1092 # 800146d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002294:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002296:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002298:	00018917          	auipc	s2,0x18
    8000229c:	e3890913          	addi	s2,s2,-456 # 8001a0d0 <tickslock>
    800022a0:	a821                	j	800022b8 <wakeup+0x40>
        p->state = RUNNABLE;
    800022a2:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022a6:	8526                	mv	a0,s1
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022b0:	16848493          	addi	s1,s1,360
    800022b4:	03248463          	beq	s1,s2,800022dc <wakeup+0x64>
    if(p != myproc()){
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	778080e7          	jalr	1912(ra) # 80001a30 <myproc>
    800022c0:	fea488e3          	beq	s1,a0,800022b0 <wakeup+0x38>
      acquire(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	91e080e7          	jalr	-1762(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022ce:	4c9c                	lw	a5,24(s1)
    800022d0:	fd379be3          	bne	a5,s3,800022a6 <wakeup+0x2e>
    800022d4:	709c                	ld	a5,32(s1)
    800022d6:	fd4798e3          	bne	a5,s4,800022a6 <wakeup+0x2e>
    800022da:	b7e1                	j	800022a2 <wakeup+0x2a>
    }
  }
}
    800022dc:	70e2                	ld	ra,56(sp)
    800022de:	7442                	ld	s0,48(sp)
    800022e0:	74a2                	ld	s1,40(sp)
    800022e2:	7902                	ld	s2,32(sp)
    800022e4:	69e2                	ld	s3,24(sp)
    800022e6:	6a42                	ld	s4,16(sp)
    800022e8:	6aa2                	ld	s5,8(sp)
    800022ea:	6121                	addi	sp,sp,64
    800022ec:	8082                	ret

00000000800022ee <reparent>:
{
    800022ee:	7179                	addi	sp,sp,-48
    800022f0:	f406                	sd	ra,40(sp)
    800022f2:	f022                	sd	s0,32(sp)
    800022f4:	ec26                	sd	s1,24(sp)
    800022f6:	e84a                	sd	s2,16(sp)
    800022f8:	e44e                	sd	s3,8(sp)
    800022fa:	e052                	sd	s4,0(sp)
    800022fc:	1800                	addi	s0,sp,48
    800022fe:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002300:	00012497          	auipc	s1,0x12
    80002304:	3d048493          	addi	s1,s1,976 # 800146d0 <proc>
      pp->parent = initproc;
    80002308:	0000aa17          	auipc	s4,0xa
    8000230c:	d20a0a13          	addi	s4,s4,-736 # 8000c028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002310:	00018997          	auipc	s3,0x18
    80002314:	dc098993          	addi	s3,s3,-576 # 8001a0d0 <tickslock>
    80002318:	a029                	j	80002322 <reparent+0x34>
    8000231a:	16848493          	addi	s1,s1,360
    8000231e:	01348d63          	beq	s1,s3,80002338 <reparent+0x4a>
    if(pp->parent == p){
    80002322:	7c9c                	ld	a5,56(s1)
    80002324:	ff279be3          	bne	a5,s2,8000231a <reparent+0x2c>
      pp->parent = initproc;
    80002328:	000a3503          	ld	a0,0(s4)
    8000232c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	f4a080e7          	jalr	-182(ra) # 80002278 <wakeup>
    80002336:	b7d5                	j	8000231a <reparent+0x2c>
}
    80002338:	70a2                	ld	ra,40(sp)
    8000233a:	7402                	ld	s0,32(sp)
    8000233c:	64e2                	ld	s1,24(sp)
    8000233e:	6942                	ld	s2,16(sp)
    80002340:	69a2                	ld	s3,8(sp)
    80002342:	6a02                	ld	s4,0(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret

0000000080002348 <exit>:
{
    80002348:	7179                	addi	sp,sp,-48
    8000234a:	f406                	sd	ra,40(sp)
    8000234c:	f022                	sd	s0,32(sp)
    8000234e:	ec26                	sd	s1,24(sp)
    80002350:	e84a                	sd	s2,16(sp)
    80002352:	e44e                	sd	s3,8(sp)
    80002354:	e052                	sd	s4,0(sp)
    80002356:	1800                	addi	s0,sp,48
    80002358:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	6d6080e7          	jalr	1750(ra) # 80001a30 <myproc>
    80002362:	89aa                	mv	s3,a0
  if(p == initproc)
    80002364:	0000a797          	auipc	a5,0xa
    80002368:	cc47b783          	ld	a5,-828(a5) # 8000c028 <initproc>
    8000236c:	0d050493          	addi	s1,a0,208
    80002370:	15050913          	addi	s2,a0,336
    80002374:	02a79363          	bne	a5,a0,8000239a <exit+0x52>
    panic("init exiting");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	fb050513          	addi	a0,a0,-80 # 80008328 <digits+0x2e8>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1be080e7          	jalr	446(ra) # 8000053e <panic>
      fileclose(f);
    80002388:	00002097          	auipc	ra,0x2
    8000238c:	164080e7          	jalr	356(ra) # 800044ec <fileclose>
      p->ofile[fd] = 0;
    80002390:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002394:	04a1                	addi	s1,s1,8
    80002396:	01248563          	beq	s1,s2,800023a0 <exit+0x58>
    if(p->ofile[fd]){
    8000239a:	6088                	ld	a0,0(s1)
    8000239c:	f575                	bnez	a0,80002388 <exit+0x40>
    8000239e:	bfdd                	j	80002394 <exit+0x4c>
  begin_op();
    800023a0:	00002097          	auipc	ra,0x2
    800023a4:	c80080e7          	jalr	-896(ra) # 80004020 <begin_op>
  iput(p->cwd);
    800023a8:	1509b503          	ld	a0,336(s3)
    800023ac:	00001097          	auipc	ra,0x1
    800023b0:	45c080e7          	jalr	1116(ra) # 80003808 <iput>
  end_op();
    800023b4:	00002097          	auipc	ra,0x2
    800023b8:	cec080e7          	jalr	-788(ra) # 800040a0 <end_op>
  p->cwd = 0;
    800023bc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023c0:	00012497          	auipc	s1,0x12
    800023c4:	ef848493          	addi	s1,s1,-264 # 800142b8 <wait_lock>
    800023c8:	8526                	mv	a0,s1
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	81a080e7          	jalr	-2022(ra) # 80000be4 <acquire>
  reparent(p);
    800023d2:	854e                	mv	a0,s3
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	f1a080e7          	jalr	-230(ra) # 800022ee <reparent>
  wakeup(p->parent);
    800023dc:	0389b503          	ld	a0,56(s3)
    800023e0:	00000097          	auipc	ra,0x0
    800023e4:	e98080e7          	jalr	-360(ra) # 80002278 <wakeup>
  acquire(&p->lock);
    800023e8:	854e                	mv	a0,s3
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	7fa080e7          	jalr	2042(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023f2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023f6:	4795                	li	a5,5
    800023f8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	89a080e7          	jalr	-1894(ra) # 80000c98 <release>
  sched();
    80002406:	00000097          	auipc	ra,0x0
    8000240a:	bd4080e7          	jalr	-1068(ra) # 80001fda <sched>
  panic("zombie exit");
    8000240e:	00006517          	auipc	a0,0x6
    80002412:	f2a50513          	addi	a0,a0,-214 # 80008338 <digits+0x2f8>
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	128080e7          	jalr	296(ra) # 8000053e <panic>

000000008000241e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000241e:	7179                	addi	sp,sp,-48
    80002420:	f406                	sd	ra,40(sp)
    80002422:	f022                	sd	s0,32(sp)
    80002424:	ec26                	sd	s1,24(sp)
    80002426:	e84a                	sd	s2,16(sp)
    80002428:	e44e                	sd	s3,8(sp)
    8000242a:	1800                	addi	s0,sp,48
    8000242c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000242e:	00012497          	auipc	s1,0x12
    80002432:	2a248493          	addi	s1,s1,674 # 800146d0 <proc>
    80002436:	00018997          	auipc	s3,0x18
    8000243a:	c9a98993          	addi	s3,s3,-870 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	ffffe097          	auipc	ra,0xffffe
    80002444:	7a4080e7          	jalr	1956(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002448:	589c                	lw	a5,48(s1)
    8000244a:	01278d63          	beq	a5,s2,80002464 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	848080e7          	jalr	-1976(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002458:	16848493          	addi	s1,s1,360
    8000245c:	ff3491e3          	bne	s1,s3,8000243e <kill+0x20>
  }
  return -1;
    80002460:	557d                	li	a0,-1
    80002462:	a829                	j	8000247c <kill+0x5e>
      p->killed = 1;
    80002464:	4785                	li	a5,1
    80002466:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002468:	4c98                	lw	a4,24(s1)
    8000246a:	4789                	li	a5,2
    8000246c:	00f70f63          	beq	a4,a5,8000248a <kill+0x6c>
      release(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	826080e7          	jalr	-2010(ra) # 80000c98 <release>
      return 0;
    8000247a:	4501                	li	a0,0
}
    8000247c:	70a2                	ld	ra,40(sp)
    8000247e:	7402                	ld	s0,32(sp)
    80002480:	64e2                	ld	s1,24(sp)
    80002482:	6942                	ld	s2,16(sp)
    80002484:	69a2                	ld	s3,8(sp)
    80002486:	6145                	addi	sp,sp,48
    80002488:	8082                	ret
        p->state = RUNNABLE;
    8000248a:	478d                	li	a5,3
    8000248c:	cc9c                	sw	a5,24(s1)
    8000248e:	b7cd                	j	80002470 <kill+0x52>

0000000080002490 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002490:	7179                	addi	sp,sp,-48
    80002492:	f406                	sd	ra,40(sp)
    80002494:	f022                	sd	s0,32(sp)
    80002496:	ec26                	sd	s1,24(sp)
    80002498:	e84a                	sd	s2,16(sp)
    8000249a:	e44e                	sd	s3,8(sp)
    8000249c:	e052                	sd	s4,0(sp)
    8000249e:	1800                	addi	s0,sp,48
    800024a0:	84aa                	mv	s1,a0
    800024a2:	892e                	mv	s2,a1
    800024a4:	89b2                	mv	s3,a2
    800024a6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	588080e7          	jalr	1416(ra) # 80001a30 <myproc>
  if(user_dst){
    800024b0:	c08d                	beqz	s1,800024d2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024b2:	86d2                	mv	a3,s4
    800024b4:	864e                	mv	a2,s3
    800024b6:	85ca                	mv	a1,s2
    800024b8:	6928                	ld	a0,80(a0)
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	238080e7          	jalr	568(ra) # 800016f2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c2:	70a2                	ld	ra,40(sp)
    800024c4:	7402                	ld	s0,32(sp)
    800024c6:	64e2                	ld	s1,24(sp)
    800024c8:	6942                	ld	s2,16(sp)
    800024ca:	69a2                	ld	s3,8(sp)
    800024cc:	6a02                	ld	s4,0(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret
    memmove((char *)dst, src, len);
    800024d2:	000a061b          	sext.w	a2,s4
    800024d6:	85ce                	mv	a1,s3
    800024d8:	854a                	mv	a0,s2
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	866080e7          	jalr	-1946(ra) # 80000d40 <memmove>
    return 0;
    800024e2:	8526                	mv	a0,s1
    800024e4:	bff9                	j	800024c2 <either_copyout+0x32>

00000000800024e6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024e6:	7179                	addi	sp,sp,-48
    800024e8:	f406                	sd	ra,40(sp)
    800024ea:	f022                	sd	s0,32(sp)
    800024ec:	ec26                	sd	s1,24(sp)
    800024ee:	e84a                	sd	s2,16(sp)
    800024f0:	e44e                	sd	s3,8(sp)
    800024f2:	e052                	sd	s4,0(sp)
    800024f4:	1800                	addi	s0,sp,48
    800024f6:	892a                	mv	s2,a0
    800024f8:	84ae                	mv	s1,a1
    800024fa:	89b2                	mv	s3,a2
    800024fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	532080e7          	jalr	1330(ra) # 80001a30 <myproc>
  if(user_src){
    80002506:	c08d                	beqz	s1,80002528 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002508:	86d2                	mv	a3,s4
    8000250a:	864e                	mv	a2,s3
    8000250c:	85ca                	mv	a1,s2
    8000250e:	6928                	ld	a0,80(a0)
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	26e080e7          	jalr	622(ra) # 8000177e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002518:	70a2                	ld	ra,40(sp)
    8000251a:	7402                	ld	s0,32(sp)
    8000251c:	64e2                	ld	s1,24(sp)
    8000251e:	6942                	ld	s2,16(sp)
    80002520:	69a2                	ld	s3,8(sp)
    80002522:	6a02                	ld	s4,0(sp)
    80002524:	6145                	addi	sp,sp,48
    80002526:	8082                	ret
    memmove(dst, (char*)src, len);
    80002528:	000a061b          	sext.w	a2,s4
    8000252c:	85ce                	mv	a1,s3
    8000252e:	854a                	mv	a0,s2
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	810080e7          	jalr	-2032(ra) # 80000d40 <memmove>
    return 0;
    80002538:	8526                	mv	a0,s1
    8000253a:	bff9                	j	80002518 <either_copyin+0x32>

000000008000253c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000253c:	715d                	addi	sp,sp,-80
    8000253e:	e486                	sd	ra,72(sp)
    80002540:	e0a2                	sd	s0,64(sp)
    80002542:	fc26                	sd	s1,56(sp)
    80002544:	f84a                	sd	s2,48(sp)
    80002546:	f44e                	sd	s3,40(sp)
    80002548:	f052                	sd	s4,32(sp)
    8000254a:	ec56                	sd	s5,24(sp)
    8000254c:	e85a                	sd	s6,16(sp)
    8000254e:	e45e                	sd	s7,8(sp)
    80002550:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002552:	00006517          	auipc	a0,0x6
    80002556:	bce50513          	addi	a0,a0,-1074 # 80008120 <digits+0xe0>
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002562:	00012497          	auipc	s1,0x12
    80002566:	2c648493          	addi	s1,s1,710 # 80014828 <proc+0x158>
    8000256a:	00018917          	auipc	s2,0x18
    8000256e:	cbe90913          	addi	s2,s2,-834 # 8001a228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002572:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002574:	00006997          	auipc	s3,0x6
    80002578:	dd498993          	addi	s3,s3,-556 # 80008348 <digits+0x308>
    printf("%d %s %s", p->pid, state, p->name);
    8000257c:	00006a97          	auipc	s5,0x6
    80002580:	dd4a8a93          	addi	s5,s5,-556 # 80008350 <digits+0x310>
    printf("\n");
    80002584:	00006a17          	auipc	s4,0x6
    80002588:	b9ca0a13          	addi	s4,s4,-1124 # 80008120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	00006b97          	auipc	s7,0x6
    80002590:	dfcb8b93          	addi	s7,s7,-516 # 80008388 <states.1709>
    80002594:	a00d                	j	800025b6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002596:	ed86a583          	lw	a1,-296(a3)
    8000259a:	8556                	mv	a0,s5
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	fec080e7          	jalr	-20(ra) # 80000588 <printf>
    printf("\n");
    800025a4:	8552                	mv	a0,s4
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	fe2080e7          	jalr	-30(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ae:	16848493          	addi	s1,s1,360
    800025b2:	03248163          	beq	s1,s2,800025d4 <procdump+0x98>
    if(p->state == UNUSED)
    800025b6:	86a6                	mv	a3,s1
    800025b8:	ec04a783          	lw	a5,-320(s1)
    800025bc:	dbed                	beqz	a5,800025ae <procdump+0x72>
      state = "???";
    800025be:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c0:	fcfb6be3          	bltu	s6,a5,80002596 <procdump+0x5a>
    800025c4:	1782                	slli	a5,a5,0x20
    800025c6:	9381                	srli	a5,a5,0x20
    800025c8:	078e                	slli	a5,a5,0x3
    800025ca:	97de                	add	a5,a5,s7
    800025cc:	6390                	ld	a2,0(a5)
    800025ce:	f661                	bnez	a2,80002596 <procdump+0x5a>
      state = "???";
    800025d0:	864e                	mv	a2,s3
    800025d2:	b7d1                	j	80002596 <procdump+0x5a>
  }
}
    800025d4:	60a6                	ld	ra,72(sp)
    800025d6:	6406                	ld	s0,64(sp)
    800025d8:	74e2                	ld	s1,56(sp)
    800025da:	7942                	ld	s2,48(sp)
    800025dc:	79a2                	ld	s3,40(sp)
    800025de:	7a02                	ld	s4,32(sp)
    800025e0:	6ae2                	ld	s5,24(sp)
    800025e2:	6b42                	ld	s6,16(sp)
    800025e4:	6ba2                	ld	s7,8(sp)
    800025e6:	6161                	addi	sp,sp,80
    800025e8:	8082                	ret

00000000800025ea <swtch>:
    800025ea:	00153023          	sd	ra,0(a0)
    800025ee:	00253423          	sd	sp,8(a0)
    800025f2:	e900                	sd	s0,16(a0)
    800025f4:	ed04                	sd	s1,24(a0)
    800025f6:	03253023          	sd	s2,32(a0)
    800025fa:	03353423          	sd	s3,40(a0)
    800025fe:	03453823          	sd	s4,48(a0)
    80002602:	03553c23          	sd	s5,56(a0)
    80002606:	05653023          	sd	s6,64(a0)
    8000260a:	05753423          	sd	s7,72(a0)
    8000260e:	05853823          	sd	s8,80(a0)
    80002612:	05953c23          	sd	s9,88(a0)
    80002616:	07a53023          	sd	s10,96(a0)
    8000261a:	07b53423          	sd	s11,104(a0)
    8000261e:	0005b083          	ld	ra,0(a1)
    80002622:	0085b103          	ld	sp,8(a1)
    80002626:	6980                	ld	s0,16(a1)
    80002628:	6d84                	ld	s1,24(a1)
    8000262a:	0205b903          	ld	s2,32(a1)
    8000262e:	0285b983          	ld	s3,40(a1)
    80002632:	0305ba03          	ld	s4,48(a1)
    80002636:	0385ba83          	ld	s5,56(a1)
    8000263a:	0405bb03          	ld	s6,64(a1)
    8000263e:	0485bb83          	ld	s7,72(a1)
    80002642:	0505bc03          	ld	s8,80(a1)
    80002646:	0585bc83          	ld	s9,88(a1)
    8000264a:	0605bd03          	ld	s10,96(a1)
    8000264e:	0685bd83          	ld	s11,104(a1)
    80002652:	8082                	ret

0000000080002654 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002654:	1141                	addi	sp,sp,-16
    80002656:	e406                	sd	ra,8(sp)
    80002658:	e022                	sd	s0,0(sp)
    8000265a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000265c:	00006597          	auipc	a1,0x6
    80002660:	d5c58593          	addi	a1,a1,-676 # 800083b8 <states.1709+0x30>
    80002664:	00018517          	auipc	a0,0x18
    80002668:	a6c50513          	addi	a0,a0,-1428 # 8001a0d0 <tickslock>
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	4e8080e7          	jalr	1256(ra) # 80000b54 <initlock>
}
    80002674:	60a2                	ld	ra,8(sp)
    80002676:	6402                	ld	s0,0(sp)
    80002678:	0141                	addi	sp,sp,16
    8000267a:	8082                	ret

000000008000267c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000267c:	1141                	addi	sp,sp,-16
    8000267e:	e422                	sd	s0,8(sp)
    80002680:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002682:	00003797          	auipc	a5,0x3
    80002686:	47e78793          	addi	a5,a5,1150 # 80005b00 <kernelvec>
    8000268a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000268e:	6422                	ld	s0,8(sp)
    80002690:	0141                	addi	sp,sp,16
    80002692:	8082                	ret

0000000080002694 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e406                	sd	ra,8(sp)
    80002698:	e022                	sd	s0,0(sp)
    8000269a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	394080e7          	jalr	916(ra) # 80001a30 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026aa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ae:	00005617          	auipc	a2,0x5
    800026b2:	95260613          	addi	a2,a2,-1710 # 80007000 <_trampoline>
    800026b6:	00005697          	auipc	a3,0x5
    800026ba:	94a68693          	addi	a3,a3,-1718 # 80007000 <_trampoline>
    800026be:	8e91                	sub	a3,a3,a2
    800026c0:	008007b7          	lui	a5,0x800
    800026c4:	17fd                	addi	a5,a5,-1
    800026c6:	07ba                	slli	a5,a5,0xe
    800026c8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ca:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ce:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d0:	180026f3          	csrr	a3,satp
    800026d4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026d6:	6d38                	ld	a4,88(a0)
    800026d8:	6134                	ld	a3,64(a0)
    800026da:	6591                	lui	a1,0x4
    800026dc:	96ae                	add	a3,a3,a1
    800026de:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026e0:	6d38                	ld	a4,88(a0)
    800026e2:	00000697          	auipc	a3,0x0
    800026e6:	13868693          	addi	a3,a3,312 # 8000281a <usertrap>
    800026ea:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026ee:	8692                	mv	a3,tp
    800026f0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026f2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026f6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026fa:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026fe:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002702:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002704:	6f18                	ld	a4,24(a4)
    80002706:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000270a:	692c                	ld	a1,80(a0)
    8000270c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000270e:	00005717          	auipc	a4,0x5
    80002712:	98270713          	addi	a4,a4,-1662 # 80007090 <userret>
    80002716:	8f11                	sub	a4,a4,a2
    80002718:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000271a:	577d                	li	a4,-1
    8000271c:	177e                	slli	a4,a4,0x3f
    8000271e:	8dd9                	or	a1,a1,a4
    80002720:	00400537          	lui	a0,0x400
    80002724:	157d                	addi	a0,a0,-1
    80002726:	053e                	slli	a0,a0,0xf
    80002728:	9782                	jalr	a5
}
    8000272a:	60a2                	ld	ra,8(sp)
    8000272c:	6402                	ld	s0,0(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002732:	1101                	addi	sp,sp,-32
    80002734:	ec06                	sd	ra,24(sp)
    80002736:	e822                	sd	s0,16(sp)
    80002738:	e426                	sd	s1,8(sp)
    8000273a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000273c:	00018497          	auipc	s1,0x18
    80002740:	99448493          	addi	s1,s1,-1644 # 8001a0d0 <tickslock>
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	49e080e7          	jalr	1182(ra) # 80000be4 <acquire>
  ticks++;
    8000274e:	0000a517          	auipc	a0,0xa
    80002752:	8e250513          	addi	a0,a0,-1822 # 8000c030 <ticks>
    80002756:	411c                	lw	a5,0(a0)
    80002758:	2785                	addiw	a5,a5,1
    8000275a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	b1c080e7          	jalr	-1252(ra) # 80002278 <wakeup>
  release(&tickslock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	532080e7          	jalr	1330(ra) # 80000c98 <release>
}
    8000276e:	60e2                	ld	ra,24(sp)
    80002770:	6442                	ld	s0,16(sp)
    80002772:	64a2                	ld	s1,8(sp)
    80002774:	6105                	addi	sp,sp,32
    80002776:	8082                	ret

0000000080002778 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002778:	1101                	addi	sp,sp,-32
    8000277a:	ec06                	sd	ra,24(sp)
    8000277c:	e822                	sd	s0,16(sp)
    8000277e:	e426                	sd	s1,8(sp)
    80002780:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002782:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002786:	00074d63          	bltz	a4,800027a0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000278a:	57fd                	li	a5,-1
    8000278c:	17fe                	slli	a5,a5,0x3f
    8000278e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002790:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002792:	06f70363          	beq	a4,a5,800027f8 <devintr+0x80>
  }
}
    80002796:	60e2                	ld	ra,24(sp)
    80002798:	6442                	ld	s0,16(sp)
    8000279a:	64a2                	ld	s1,8(sp)
    8000279c:	6105                	addi	sp,sp,32
    8000279e:	8082                	ret
     (scause & 0xff) == 9){
    800027a0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027a4:	46a5                	li	a3,9
    800027a6:	fed792e3          	bne	a5,a3,8000278a <devintr+0x12>
    int irq = plic_claim();
    800027aa:	00003097          	auipc	ra,0x3
    800027ae:	45e080e7          	jalr	1118(ra) # 80005c08 <plic_claim>
    800027b2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027b4:	47a9                	li	a5,10
    800027b6:	02f50763          	beq	a0,a5,800027e4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ba:	4785                	li	a5,1
    800027bc:	02f50963          	beq	a0,a5,800027ee <devintr+0x76>
    return 1;
    800027c0:	4505                	li	a0,1
    } else if(irq){
    800027c2:	d8f1                	beqz	s1,80002796 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027c4:	85a6                	mv	a1,s1
    800027c6:	00006517          	auipc	a0,0x6
    800027ca:	bfa50513          	addi	a0,a0,-1030 # 800083c0 <states.1709+0x38>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	dba080e7          	jalr	-582(ra) # 80000588 <printf>
      plic_complete(irq);
    800027d6:	8526                	mv	a0,s1
    800027d8:	00003097          	auipc	ra,0x3
    800027dc:	454080e7          	jalr	1108(ra) # 80005c2c <plic_complete>
    return 1;
    800027e0:	4505                	li	a0,1
    800027e2:	bf55                	j	80002796 <devintr+0x1e>
      uartintr();
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	1c4080e7          	jalr	452(ra) # 800009a8 <uartintr>
    800027ec:	b7ed                	j	800027d6 <devintr+0x5e>
      virtio_disk_intr();
    800027ee:	00004097          	auipc	ra,0x4
    800027f2:	92c080e7          	jalr	-1748(ra) # 8000611a <virtio_disk_intr>
    800027f6:	b7c5                	j	800027d6 <devintr+0x5e>
    if(cpuid() == 0){
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	20c080e7          	jalr	524(ra) # 80001a04 <cpuid>
    80002800:	c901                	beqz	a0,80002810 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002802:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002806:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002808:	14479073          	csrw	sip,a5
    return 2;
    8000280c:	4509                	li	a0,2
    8000280e:	b761                	j	80002796 <devintr+0x1e>
      clockintr();
    80002810:	00000097          	auipc	ra,0x0
    80002814:	f22080e7          	jalr	-222(ra) # 80002732 <clockintr>
    80002818:	b7ed                	j	80002802 <devintr+0x8a>

000000008000281a <usertrap>:
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	e04a                	sd	s2,0(sp)
    80002824:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002826:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000282a:	1007f793          	andi	a5,a5,256
    8000282e:	e3ad                	bnez	a5,80002890 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002830:	00003797          	auipc	a5,0x3
    80002834:	2d078793          	addi	a5,a5,720 # 80005b00 <kernelvec>
    80002838:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	1f4080e7          	jalr	500(ra) # 80001a30 <myproc>
    80002844:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002846:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002848:	14102773          	csrr	a4,sepc
    8000284c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000284e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002852:	47a1                	li	a5,8
    80002854:	04f71c63          	bne	a4,a5,800028ac <usertrap+0x92>
    if(p->killed)
    80002858:	551c                	lw	a5,40(a0)
    8000285a:	e3b9                	bnez	a5,800028a0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000285c:	6cb8                	ld	a4,88(s1)
    8000285e:	6f1c                	ld	a5,24(a4)
    80002860:	0791                	addi	a5,a5,4
    80002862:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002864:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002868:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286c:	10079073          	csrw	sstatus,a5
    syscall();
    80002870:	00000097          	auipc	ra,0x0
    80002874:	2e0080e7          	jalr	736(ra) # 80002b50 <syscall>
  if(p->killed)
    80002878:	549c                	lw	a5,40(s1)
    8000287a:	ebc1                	bnez	a5,8000290a <usertrap+0xf0>
  usertrapret();
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	e18080e7          	jalr	-488(ra) # 80002694 <usertrapret>
}
    80002884:	60e2                	ld	ra,24(sp)
    80002886:	6442                	ld	s0,16(sp)
    80002888:	64a2                	ld	s1,8(sp)
    8000288a:	6902                	ld	s2,0(sp)
    8000288c:	6105                	addi	sp,sp,32
    8000288e:	8082                	ret
    panic("usertrap: not from user mode");
    80002890:	00006517          	auipc	a0,0x6
    80002894:	b5050513          	addi	a0,a0,-1200 # 800083e0 <states.1709+0x58>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	ca6080e7          	jalr	-858(ra) # 8000053e <panic>
      exit(-1);
    800028a0:	557d                	li	a0,-1
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	aa6080e7          	jalr	-1370(ra) # 80002348 <exit>
    800028aa:	bf4d                	j	8000285c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	ecc080e7          	jalr	-308(ra) # 80002778 <devintr>
    800028b4:	892a                	mv	s2,a0
    800028b6:	c501                	beqz	a0,800028be <usertrap+0xa4>
  if(p->killed)
    800028b8:	549c                	lw	a5,40(s1)
    800028ba:	c3a1                	beqz	a5,800028fa <usertrap+0xe0>
    800028bc:	a815                	j	800028f0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028c2:	5890                	lw	a2,48(s1)
    800028c4:	00006517          	auipc	a0,0x6
    800028c8:	b3c50513          	addi	a0,a0,-1220 # 80008400 <states.1709+0x78>
    800028cc:	ffffe097          	auipc	ra,0xffffe
    800028d0:	cbc080e7          	jalr	-836(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028d4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028d8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	b5450513          	addi	a0,a0,-1196 # 80008430 <states.1709+0xa8>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	ca4080e7          	jalr	-860(ra) # 80000588 <printf>
    p->killed = 1;
    800028ec:	4785                	li	a5,1
    800028ee:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028f0:	557d                	li	a0,-1
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	a56080e7          	jalr	-1450(ra) # 80002348 <exit>
  if(which_dev == 2)
    800028fa:	4789                	li	a5,2
    800028fc:	f8f910e3          	bne	s2,a5,8000287c <usertrap+0x62>
    yield();
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	7b0080e7          	jalr	1968(ra) # 800020b0 <yield>
    80002908:	bf95                	j	8000287c <usertrap+0x62>
  int which_dev = 0;
    8000290a:	4901                	li	s2,0
    8000290c:	b7d5                	j	800028f0 <usertrap+0xd6>

000000008000290e <kerneltrap>:
{
    8000290e:	7179                	addi	sp,sp,-48
    80002910:	f406                	sd	ra,40(sp)
    80002912:	f022                	sd	s0,32(sp)
    80002914:	ec26                	sd	s1,24(sp)
    80002916:	e84a                	sd	s2,16(sp)
    80002918:	e44e                	sd	s3,8(sp)
    8000291a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000291c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002924:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002928:	1004f793          	andi	a5,s1,256
    8000292c:	cb85                	beqz	a5,8000295c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002932:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002934:	ef85                	bnez	a5,8000296c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	e42080e7          	jalr	-446(ra) # 80002778 <devintr>
    8000293e:	cd1d                	beqz	a0,8000297c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002940:	4789                	li	a5,2
    80002942:	06f50a63          	beq	a0,a5,800029b6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002946:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294a:	10049073          	csrw	sstatus,s1
}
    8000294e:	70a2                	ld	ra,40(sp)
    80002950:	7402                	ld	s0,32(sp)
    80002952:	64e2                	ld	s1,24(sp)
    80002954:	6942                	ld	s2,16(sp)
    80002956:	69a2                	ld	s3,8(sp)
    80002958:	6145                	addi	sp,sp,48
    8000295a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	af450513          	addi	a0,a0,-1292 # 80008450 <states.1709+0xc8>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	bda080e7          	jalr	-1062(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	b0c50513          	addi	a0,a0,-1268 # 80008478 <states.1709+0xf0>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	bca080e7          	jalr	-1078(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000297c:	85ce                	mv	a1,s3
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	b1a50513          	addi	a0,a0,-1254 # 80008498 <states.1709+0x110>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	c02080e7          	jalr	-1022(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002992:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	b1250513          	addi	a0,a0,-1262 # 800084a8 <states.1709+0x120>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	bea080e7          	jalr	-1046(ra) # 80000588 <printf>
    panic("kerneltrap");
    800029a6:	00006517          	auipc	a0,0x6
    800029aa:	b1a50513          	addi	a0,a0,-1254 # 800084c0 <states.1709+0x138>
    800029ae:	ffffe097          	auipc	ra,0xffffe
    800029b2:	b90080e7          	jalr	-1136(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	07a080e7          	jalr	122(ra) # 80001a30 <myproc>
    800029be:	d541                	beqz	a0,80002946 <kerneltrap+0x38>
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	070080e7          	jalr	112(ra) # 80001a30 <myproc>
    800029c8:	4d18                	lw	a4,24(a0)
    800029ca:	4791                	li	a5,4
    800029cc:	f6f71de3          	bne	a4,a5,80002946 <kerneltrap+0x38>
    yield();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	6e0080e7          	jalr	1760(ra) # 800020b0 <yield>
    800029d8:	b7bd                	j	80002946 <kerneltrap+0x38>

00000000800029da <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029da:	1101                	addi	sp,sp,-32
    800029dc:	ec06                	sd	ra,24(sp)
    800029de:	e822                	sd	s0,16(sp)
    800029e0:	e426                	sd	s1,8(sp)
    800029e2:	1000                	addi	s0,sp,32
    800029e4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	04a080e7          	jalr	74(ra) # 80001a30 <myproc>
  switch (n) {
    800029ee:	4795                	li	a5,5
    800029f0:	0497e163          	bltu	a5,s1,80002a32 <argraw+0x58>
    800029f4:	048a                	slli	s1,s1,0x2
    800029f6:	00006717          	auipc	a4,0x6
    800029fa:	b0270713          	addi	a4,a4,-1278 # 800084f8 <states.1709+0x170>
    800029fe:	94ba                	add	s1,s1,a4
    80002a00:	409c                	lw	a5,0(s1)
    80002a02:	97ba                	add	a5,a5,a4
    80002a04:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a06:	6d3c                	ld	a5,88(a0)
    80002a08:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a0a:	60e2                	ld	ra,24(sp)
    80002a0c:	6442                	ld	s0,16(sp)
    80002a0e:	64a2                	ld	s1,8(sp)
    80002a10:	6105                	addi	sp,sp,32
    80002a12:	8082                	ret
    return p->trapframe->a1;
    80002a14:	6d3c                	ld	a5,88(a0)
    80002a16:	7fa8                	ld	a0,120(a5)
    80002a18:	bfcd                	j	80002a0a <argraw+0x30>
    return p->trapframe->a2;
    80002a1a:	6d3c                	ld	a5,88(a0)
    80002a1c:	63c8                	ld	a0,128(a5)
    80002a1e:	b7f5                	j	80002a0a <argraw+0x30>
    return p->trapframe->a3;
    80002a20:	6d3c                	ld	a5,88(a0)
    80002a22:	67c8                	ld	a0,136(a5)
    80002a24:	b7dd                	j	80002a0a <argraw+0x30>
    return p->trapframe->a4;
    80002a26:	6d3c                	ld	a5,88(a0)
    80002a28:	6bc8                	ld	a0,144(a5)
    80002a2a:	b7c5                	j	80002a0a <argraw+0x30>
    return p->trapframe->a5;
    80002a2c:	6d3c                	ld	a5,88(a0)
    80002a2e:	6fc8                	ld	a0,152(a5)
    80002a30:	bfe9                	j	80002a0a <argraw+0x30>
  panic("argraw");
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	a9e50513          	addi	a0,a0,-1378 # 800084d0 <states.1709+0x148>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b04080e7          	jalr	-1276(ra) # 8000053e <panic>

0000000080002a42 <fetchaddr>:
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	e426                	sd	s1,8(sp)
    80002a4a:	e04a                	sd	s2,0(sp)
    80002a4c:	1000                	addi	s0,sp,32
    80002a4e:	84aa                	mv	s1,a0
    80002a50:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	fde080e7          	jalr	-34(ra) # 80001a30 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a5a:	653c                	ld	a5,72(a0)
    80002a5c:	02f4f863          	bgeu	s1,a5,80002a8c <fetchaddr+0x4a>
    80002a60:	00848713          	addi	a4,s1,8
    80002a64:	02e7e663          	bltu	a5,a4,80002a90 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a68:	46a1                	li	a3,8
    80002a6a:	8626                	mv	a2,s1
    80002a6c:	85ca                	mv	a1,s2
    80002a6e:	6928                	ld	a0,80(a0)
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	d0e080e7          	jalr	-754(ra) # 8000177e <copyin>
    80002a78:	00a03533          	snez	a0,a0
    80002a7c:	40a00533          	neg	a0,a0
}
    80002a80:	60e2                	ld	ra,24(sp)
    80002a82:	6442                	ld	s0,16(sp)
    80002a84:	64a2                	ld	s1,8(sp)
    80002a86:	6902                	ld	s2,0(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    return -1;
    80002a8c:	557d                	li	a0,-1
    80002a8e:	bfcd                	j	80002a80 <fetchaddr+0x3e>
    80002a90:	557d                	li	a0,-1
    80002a92:	b7fd                	j	80002a80 <fetchaddr+0x3e>

0000000080002a94 <fetchstr>:
{
    80002a94:	7179                	addi	sp,sp,-48
    80002a96:	f406                	sd	ra,40(sp)
    80002a98:	f022                	sd	s0,32(sp)
    80002a9a:	ec26                	sd	s1,24(sp)
    80002a9c:	e84a                	sd	s2,16(sp)
    80002a9e:	e44e                	sd	s3,8(sp)
    80002aa0:	1800                	addi	s0,sp,48
    80002aa2:	892a                	mv	s2,a0
    80002aa4:	84ae                	mv	s1,a1
    80002aa6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aa8:	fffff097          	auipc	ra,0xfffff
    80002aac:	f88080e7          	jalr	-120(ra) # 80001a30 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ab0:	86ce                	mv	a3,s3
    80002ab2:	864a                	mv	a2,s2
    80002ab4:	85a6                	mv	a1,s1
    80002ab6:	6928                	ld	a0,80(a0)
    80002ab8:	fffff097          	auipc	ra,0xfffff
    80002abc:	d52080e7          	jalr	-686(ra) # 8000180a <copyinstr>
  if(err < 0)
    80002ac0:	00054763          	bltz	a0,80002ace <fetchstr+0x3a>
  return strlen(buf);
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	39e080e7          	jalr	926(ra) # 80000e64 <strlen>
}
    80002ace:	70a2                	ld	ra,40(sp)
    80002ad0:	7402                	ld	s0,32(sp)
    80002ad2:	64e2                	ld	s1,24(sp)
    80002ad4:	6942                	ld	s2,16(sp)
    80002ad6:	69a2                	ld	s3,8(sp)
    80002ad8:	6145                	addi	sp,sp,48
    80002ada:	8082                	ret

0000000080002adc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae8:	00000097          	auipc	ra,0x0
    80002aec:	ef2080e7          	jalr	-270(ra) # 800029da <argraw>
    80002af0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002af2:	4501                	li	a0,0
    80002af4:	60e2                	ld	ra,24(sp)
    80002af6:	6442                	ld	s0,16(sp)
    80002af8:	64a2                	ld	s1,8(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret

0000000080002afe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
    80002b08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	ed0080e7          	jalr	-304(ra) # 800029da <argraw>
    80002b12:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b14:	4501                	li	a0,0
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret

0000000080002b20 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	e426                	sd	s1,8(sp)
    80002b28:	e04a                	sd	s2,0(sp)
    80002b2a:	1000                	addi	s0,sp,32
    80002b2c:	84ae                	mv	s1,a1
    80002b2e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	eaa080e7          	jalr	-342(ra) # 800029da <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b38:	864a                	mv	a2,s2
    80002b3a:	85a6                	mv	a1,s1
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	f58080e7          	jalr	-168(ra) # 80002a94 <fetchstr>
}
    80002b44:	60e2                	ld	ra,24(sp)
    80002b46:	6442                	ld	s0,16(sp)
    80002b48:	64a2                	ld	s1,8(sp)
    80002b4a:	6902                	ld	s2,0(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret

0000000080002b50 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	e04a                	sd	s2,0(sp)
    80002b5a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	ed4080e7          	jalr	-300(ra) # 80001a30 <myproc>
    80002b64:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b66:	05853903          	ld	s2,88(a0)
    80002b6a:	0a893783          	ld	a5,168(s2)
    80002b6e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b72:	37fd                	addiw	a5,a5,-1
    80002b74:	4751                	li	a4,20
    80002b76:	00f76f63          	bltu	a4,a5,80002b94 <syscall+0x44>
    80002b7a:	00369713          	slli	a4,a3,0x3
    80002b7e:	00006797          	auipc	a5,0x6
    80002b82:	99278793          	addi	a5,a5,-1646 # 80008510 <syscalls>
    80002b86:	97ba                	add	a5,a5,a4
    80002b88:	639c                	ld	a5,0(a5)
    80002b8a:	c789                	beqz	a5,80002b94 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b8c:	9782                	jalr	a5
    80002b8e:	06a93823          	sd	a0,112(s2)
    80002b92:	a839                	j	80002bb0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b94:	15848613          	addi	a2,s1,344
    80002b98:	588c                	lw	a1,48(s1)
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	93e50513          	addi	a0,a0,-1730 # 800084d8 <states.1709+0x150>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	9e6080e7          	jalr	-1562(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002baa:	6cbc                	ld	a5,88(s1)
    80002bac:	577d                	li	a4,-1
    80002bae:	fbb8                	sd	a4,112(a5)
  }
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6902                	ld	s2,0(sp)
    80002bb8:	6105                	addi	sp,sp,32
    80002bba:	8082                	ret

0000000080002bbc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bbc:	1101                	addi	sp,sp,-32
    80002bbe:	ec06                	sd	ra,24(sp)
    80002bc0:	e822                	sd	s0,16(sp)
    80002bc2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bc4:	fec40593          	addi	a1,s0,-20
    80002bc8:	4501                	li	a0,0
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	f12080e7          	jalr	-238(ra) # 80002adc <argint>
    return -1;
    80002bd2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bd4:	00054963          	bltz	a0,80002be6 <sys_exit+0x2a>
  exit(n);
    80002bd8:	fec42503          	lw	a0,-20(s0)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	76c080e7          	jalr	1900(ra) # 80002348 <exit>
  return 0;  // not reached
    80002be4:	4781                	li	a5,0
}
    80002be6:	853e                	mv	a0,a5
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret

0000000080002bf0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf0:	1141                	addi	sp,sp,-16
    80002bf2:	e406                	sd	ra,8(sp)
    80002bf4:	e022                	sd	s0,0(sp)
    80002bf6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bf8:	fffff097          	auipc	ra,0xfffff
    80002bfc:	e38080e7          	jalr	-456(ra) # 80001a30 <myproc>
}
    80002c00:	5908                	lw	a0,48(a0)
    80002c02:	60a2                	ld	ra,8(sp)
    80002c04:	6402                	ld	s0,0(sp)
    80002c06:	0141                	addi	sp,sp,16
    80002c08:	8082                	ret

0000000080002c0a <sys_fork>:

uint64
sys_fork(void)
{
    80002c0a:	1141                	addi	sp,sp,-16
    80002c0c:	e406                	sd	ra,8(sp)
    80002c0e:	e022                	sd	s0,0(sp)
    80002c10:	0800                	addi	s0,sp,16
  return fork();
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	1ec080e7          	jalr	492(ra) # 80001dfe <fork>
}
    80002c1a:	60a2                	ld	ra,8(sp)
    80002c1c:	6402                	ld	s0,0(sp)
    80002c1e:	0141                	addi	sp,sp,16
    80002c20:	8082                	ret

0000000080002c22 <sys_wait>:

uint64
sys_wait(void)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c2a:	fe840593          	addi	a1,s0,-24
    80002c2e:	4501                	li	a0,0
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	ece080e7          	jalr	-306(ra) # 80002afe <argaddr>
    80002c38:	87aa                	mv	a5,a0
    return -1;
    80002c3a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c3c:	0007c863          	bltz	a5,80002c4c <sys_wait+0x2a>
  return wait(p);
    80002c40:	fe843503          	ld	a0,-24(s0)
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	50c080e7          	jalr	1292(ra) # 80002150 <wait>
}
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c54:	7179                	addi	sp,sp,-48
    80002c56:	f406                	sd	ra,40(sp)
    80002c58:	f022                	sd	s0,32(sp)
    80002c5a:	ec26                	sd	s1,24(sp)
    80002c5c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c5e:	fdc40593          	addi	a1,s0,-36
    80002c62:	4501                	li	a0,0
    80002c64:	00000097          	auipc	ra,0x0
    80002c68:	e78080e7          	jalr	-392(ra) # 80002adc <argint>
    80002c6c:	87aa                	mv	a5,a0
    return -1;
    80002c6e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c70:	0207c063          	bltz	a5,80002c90 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	dbc080e7          	jalr	-580(ra) # 80001a30 <myproc>
    80002c7c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c7e:	fdc42503          	lw	a0,-36(s0)
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	108080e7          	jalr	264(ra) # 80001d8a <growproc>
    80002c8a:	00054863          	bltz	a0,80002c9a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c8e:	8526                	mv	a0,s1
}
    80002c90:	70a2                	ld	ra,40(sp)
    80002c92:	7402                	ld	s0,32(sp)
    80002c94:	64e2                	ld	s1,24(sp)
    80002c96:	6145                	addi	sp,sp,48
    80002c98:	8082                	ret
    return -1;
    80002c9a:	557d                	li	a0,-1
    80002c9c:	bfd5                	j	80002c90 <sys_sbrk+0x3c>

0000000080002c9e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c9e:	7139                	addi	sp,sp,-64
    80002ca0:	fc06                	sd	ra,56(sp)
    80002ca2:	f822                	sd	s0,48(sp)
    80002ca4:	f426                	sd	s1,40(sp)
    80002ca6:	f04a                	sd	s2,32(sp)
    80002ca8:	ec4e                	sd	s3,24(sp)
    80002caa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cac:	fcc40593          	addi	a1,s0,-52
    80002cb0:	4501                	li	a0,0
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	e2a080e7          	jalr	-470(ra) # 80002adc <argint>
    return -1;
    80002cba:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cbc:	06054563          	bltz	a0,80002d26 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cc0:	00017517          	auipc	a0,0x17
    80002cc4:	41050513          	addi	a0,a0,1040 # 8001a0d0 <tickslock>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	f1c080e7          	jalr	-228(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002cd0:	00009917          	auipc	s2,0x9
    80002cd4:	36092903          	lw	s2,864(s2) # 8000c030 <ticks>
  while(ticks - ticks0 < n){
    80002cd8:	fcc42783          	lw	a5,-52(s0)
    80002cdc:	cf85                	beqz	a5,80002d14 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cde:	00017997          	auipc	s3,0x17
    80002ce2:	3f298993          	addi	s3,s3,1010 # 8001a0d0 <tickslock>
    80002ce6:	00009497          	auipc	s1,0x9
    80002cea:	34a48493          	addi	s1,s1,842 # 8000c030 <ticks>
    if(myproc()->killed){
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	d42080e7          	jalr	-702(ra) # 80001a30 <myproc>
    80002cf6:	551c                	lw	a5,40(a0)
    80002cf8:	ef9d                	bnez	a5,80002d36 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cfa:	85ce                	mv	a1,s3
    80002cfc:	8526                	mv	a0,s1
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	3ee080e7          	jalr	1006(ra) # 800020ec <sleep>
  while(ticks - ticks0 < n){
    80002d06:	409c                	lw	a5,0(s1)
    80002d08:	412787bb          	subw	a5,a5,s2
    80002d0c:	fcc42703          	lw	a4,-52(s0)
    80002d10:	fce7efe3          	bltu	a5,a4,80002cee <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d14:	00017517          	auipc	a0,0x17
    80002d18:	3bc50513          	addi	a0,a0,956 # 8001a0d0 <tickslock>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	f7c080e7          	jalr	-132(ra) # 80000c98 <release>
  return 0;
    80002d24:	4781                	li	a5,0
}
    80002d26:	853e                	mv	a0,a5
    80002d28:	70e2                	ld	ra,56(sp)
    80002d2a:	7442                	ld	s0,48(sp)
    80002d2c:	74a2                	ld	s1,40(sp)
    80002d2e:	7902                	ld	s2,32(sp)
    80002d30:	69e2                	ld	s3,24(sp)
    80002d32:	6121                	addi	sp,sp,64
    80002d34:	8082                	ret
      release(&tickslock);
    80002d36:	00017517          	auipc	a0,0x17
    80002d3a:	39a50513          	addi	a0,a0,922 # 8001a0d0 <tickslock>
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
      return -1;
    80002d46:	57fd                	li	a5,-1
    80002d48:	bff9                	j	80002d26 <sys_sleep+0x88>

0000000080002d4a <sys_kill>:

uint64
sys_kill(void)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d52:	fec40593          	addi	a1,s0,-20
    80002d56:	4501                	li	a0,0
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	d84080e7          	jalr	-636(ra) # 80002adc <argint>
    80002d60:	87aa                	mv	a5,a0
    return -1;
    80002d62:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d64:	0007c863          	bltz	a5,80002d74 <sys_kill+0x2a>
  return kill(pid);
    80002d68:	fec42503          	lw	a0,-20(s0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	6b2080e7          	jalr	1714(ra) # 8000241e <kill>
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	6105                	addi	sp,sp,32
    80002d7a:	8082                	ret

0000000080002d7c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d7c:	1101                	addi	sp,sp,-32
    80002d7e:	ec06                	sd	ra,24(sp)
    80002d80:	e822                	sd	s0,16(sp)
    80002d82:	e426                	sd	s1,8(sp)
    80002d84:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d86:	00017517          	auipc	a0,0x17
    80002d8a:	34a50513          	addi	a0,a0,842 # 8001a0d0 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	e56080e7          	jalr	-426(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d96:	00009497          	auipc	s1,0x9
    80002d9a:	29a4a483          	lw	s1,666(s1) # 8000c030 <ticks>
  release(&tickslock);
    80002d9e:	00017517          	auipc	a0,0x17
    80002da2:	33250513          	addi	a0,a0,818 # 8001a0d0 <tickslock>
    80002da6:	ffffe097          	auipc	ra,0xffffe
    80002daa:	ef2080e7          	jalr	-270(ra) # 80000c98 <release>
  return xticks;
}
    80002dae:	02049513          	slli	a0,s1,0x20
    80002db2:	9101                	srli	a0,a0,0x20
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	64a2                	ld	s1,8(sp)
    80002dba:	6105                	addi	sp,sp,32
    80002dbc:	8082                	ret

0000000080002dbe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002dbe:	7179                	addi	sp,sp,-48
    80002dc0:	f406                	sd	ra,40(sp)
    80002dc2:	f022                	sd	s0,32(sp)
    80002dc4:	ec26                	sd	s1,24(sp)
    80002dc6:	e84a                	sd	s2,16(sp)
    80002dc8:	e44e                	sd	s3,8(sp)
    80002dca:	e052                	sd	s4,0(sp)
    80002dcc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dce:	00005597          	auipc	a1,0x5
    80002dd2:	7f258593          	addi	a1,a1,2034 # 800085c0 <syscalls+0xb0>
    80002dd6:	00017517          	auipc	a0,0x17
    80002dda:	31250513          	addi	a0,a0,786 # 8001a0e8 <bcache>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	d76080e7          	jalr	-650(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002de6:	0001f797          	auipc	a5,0x1f
    80002dea:	30278793          	addi	a5,a5,770 # 800220e8 <bcache+0x8000>
    80002dee:	0001f717          	auipc	a4,0x1f
    80002df2:	56270713          	addi	a4,a4,1378 # 80022350 <bcache+0x8268>
    80002df6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dfa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dfe:	00017497          	auipc	s1,0x17
    80002e02:	30248493          	addi	s1,s1,770 # 8001a100 <bcache+0x18>
    b->next = bcache.head.next;
    80002e06:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e08:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e0a:	00005a17          	auipc	s4,0x5
    80002e0e:	7bea0a13          	addi	s4,s4,1982 # 800085c8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002e12:	2b893783          	ld	a5,696(s2)
    80002e16:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e18:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e1c:	85d2                	mv	a1,s4
    80002e1e:	01048513          	addi	a0,s1,16
    80002e22:	00001097          	auipc	ra,0x1
    80002e26:	4bc080e7          	jalr	1212(ra) # 800042de <initsleeplock>
    bcache.head.next->prev = b;
    80002e2a:	2b893783          	ld	a5,696(s2)
    80002e2e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e30:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e34:	45848493          	addi	s1,s1,1112
    80002e38:	fd349de3          	bne	s1,s3,80002e12 <binit+0x54>
  }
}
    80002e3c:	70a2                	ld	ra,40(sp)
    80002e3e:	7402                	ld	s0,32(sp)
    80002e40:	64e2                	ld	s1,24(sp)
    80002e42:	6942                	ld	s2,16(sp)
    80002e44:	69a2                	ld	s3,8(sp)
    80002e46:	6a02                	ld	s4,0(sp)
    80002e48:	6145                	addi	sp,sp,48
    80002e4a:	8082                	ret

0000000080002e4c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e4c:	7179                	addi	sp,sp,-48
    80002e4e:	f406                	sd	ra,40(sp)
    80002e50:	f022                	sd	s0,32(sp)
    80002e52:	ec26                	sd	s1,24(sp)
    80002e54:	e84a                	sd	s2,16(sp)
    80002e56:	e44e                	sd	s3,8(sp)
    80002e58:	1800                	addi	s0,sp,48
    80002e5a:	89aa                	mv	s3,a0
    80002e5c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e5e:	00017517          	auipc	a0,0x17
    80002e62:	28a50513          	addi	a0,a0,650 # 8001a0e8 <bcache>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	d7e080e7          	jalr	-642(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e6e:	0001f497          	auipc	s1,0x1f
    80002e72:	5324b483          	ld	s1,1330(s1) # 800223a0 <bcache+0x82b8>
    80002e76:	0001f797          	auipc	a5,0x1f
    80002e7a:	4da78793          	addi	a5,a5,1242 # 80022350 <bcache+0x8268>
    80002e7e:	02f48f63          	beq	s1,a5,80002ebc <bread+0x70>
    80002e82:	873e                	mv	a4,a5
    80002e84:	a021                	j	80002e8c <bread+0x40>
    80002e86:	68a4                	ld	s1,80(s1)
    80002e88:	02e48a63          	beq	s1,a4,80002ebc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e8c:	449c                	lw	a5,8(s1)
    80002e8e:	ff379ce3          	bne	a5,s3,80002e86 <bread+0x3a>
    80002e92:	44dc                	lw	a5,12(s1)
    80002e94:	ff2799e3          	bne	a5,s2,80002e86 <bread+0x3a>
      b->refcnt++;
    80002e98:	40bc                	lw	a5,64(s1)
    80002e9a:	2785                	addiw	a5,a5,1
    80002e9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e9e:	00017517          	auipc	a0,0x17
    80002ea2:	24a50513          	addi	a0,a0,586 # 8001a0e8 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	df2080e7          	jalr	-526(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002eae:	01048513          	addi	a0,s1,16
    80002eb2:	00001097          	auipc	ra,0x1
    80002eb6:	466080e7          	jalr	1126(ra) # 80004318 <acquiresleep>
      return b;
    80002eba:	a8b9                	j	80002f18 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ebc:	0001f497          	auipc	s1,0x1f
    80002ec0:	4dc4b483          	ld	s1,1244(s1) # 80022398 <bcache+0x82b0>
    80002ec4:	0001f797          	auipc	a5,0x1f
    80002ec8:	48c78793          	addi	a5,a5,1164 # 80022350 <bcache+0x8268>
    80002ecc:	00f48863          	beq	s1,a5,80002edc <bread+0x90>
    80002ed0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ed2:	40bc                	lw	a5,64(s1)
    80002ed4:	cf81                	beqz	a5,80002eec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ed6:	64a4                	ld	s1,72(s1)
    80002ed8:	fee49de3          	bne	s1,a4,80002ed2 <bread+0x86>
  panic("bget: no buffers");
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	6f450513          	addi	a0,a0,1780 # 800085d0 <syscalls+0xc0>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	65a080e7          	jalr	1626(ra) # 8000053e <panic>
      b->dev = dev;
    80002eec:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ef0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ef4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002ef8:	4785                	li	a5,1
    80002efa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002efc:	00017517          	auipc	a0,0x17
    80002f00:	1ec50513          	addi	a0,a0,492 # 8001a0e8 <bcache>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	d94080e7          	jalr	-620(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f0c:	01048513          	addi	a0,s1,16
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	408080e7          	jalr	1032(ra) # 80004318 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f18:	409c                	lw	a5,0(s1)
    80002f1a:	cb89                	beqz	a5,80002f2c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f1c:	8526                	mv	a0,s1
    80002f1e:	70a2                	ld	ra,40(sp)
    80002f20:	7402                	ld	s0,32(sp)
    80002f22:	64e2                	ld	s1,24(sp)
    80002f24:	6942                	ld	s2,16(sp)
    80002f26:	69a2                	ld	s3,8(sp)
    80002f28:	6145                	addi	sp,sp,48
    80002f2a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f2c:	4581                	li	a1,0
    80002f2e:	8526                	mv	a0,s1
    80002f30:	00003097          	auipc	ra,0x3
    80002f34:	f06080e7          	jalr	-250(ra) # 80005e36 <virtio_disk_rw>
    b->valid = 1;
    80002f38:	4785                	li	a5,1
    80002f3a:	c09c                	sw	a5,0(s1)
  return b;
    80002f3c:	b7c5                	j	80002f1c <bread+0xd0>

0000000080002f3e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
    80002f48:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4a:	0541                	addi	a0,a0,16
    80002f4c:	00001097          	auipc	ra,0x1
    80002f50:	466080e7          	jalr	1126(ra) # 800043b2 <holdingsleep>
    80002f54:	cd01                	beqz	a0,80002f6c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f56:	4585                	li	a1,1
    80002f58:	8526                	mv	a0,s1
    80002f5a:	00003097          	auipc	ra,0x3
    80002f5e:	edc080e7          	jalr	-292(ra) # 80005e36 <virtio_disk_rw>
}
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	64a2                	ld	s1,8(sp)
    80002f68:	6105                	addi	sp,sp,32
    80002f6a:	8082                	ret
    panic("bwrite");
    80002f6c:	00005517          	auipc	a0,0x5
    80002f70:	67c50513          	addi	a0,a0,1660 # 800085e8 <syscalls+0xd8>
    80002f74:	ffffd097          	auipc	ra,0xffffd
    80002f78:	5ca080e7          	jalr	1482(ra) # 8000053e <panic>

0000000080002f7c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	e426                	sd	s1,8(sp)
    80002f84:	e04a                	sd	s2,0(sp)
    80002f86:	1000                	addi	s0,sp,32
    80002f88:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f8a:	01050913          	addi	s2,a0,16
    80002f8e:	854a                	mv	a0,s2
    80002f90:	00001097          	auipc	ra,0x1
    80002f94:	422080e7          	jalr	1058(ra) # 800043b2 <holdingsleep>
    80002f98:	c92d                	beqz	a0,8000300a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f9a:	854a                	mv	a0,s2
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	3d2080e7          	jalr	978(ra) # 8000436e <releasesleep>

  acquire(&bcache.lock);
    80002fa4:	00017517          	auipc	a0,0x17
    80002fa8:	14450513          	addi	a0,a0,324 # 8001a0e8 <bcache>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	c38080e7          	jalr	-968(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002fb4:	40bc                	lw	a5,64(s1)
    80002fb6:	37fd                	addiw	a5,a5,-1
    80002fb8:	0007871b          	sext.w	a4,a5
    80002fbc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fbe:	eb05                	bnez	a4,80002fee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fc0:	68bc                	ld	a5,80(s1)
    80002fc2:	64b8                	ld	a4,72(s1)
    80002fc4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fc6:	64bc                	ld	a5,72(s1)
    80002fc8:	68b8                	ld	a4,80(s1)
    80002fca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fcc:	0001f797          	auipc	a5,0x1f
    80002fd0:	11c78793          	addi	a5,a5,284 # 800220e8 <bcache+0x8000>
    80002fd4:	2b87b703          	ld	a4,696(a5)
    80002fd8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fda:	0001f717          	auipc	a4,0x1f
    80002fde:	37670713          	addi	a4,a4,886 # 80022350 <bcache+0x8268>
    80002fe2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fe4:	2b87b703          	ld	a4,696(a5)
    80002fe8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fee:	00017517          	auipc	a0,0x17
    80002ff2:	0fa50513          	addi	a0,a0,250 # 8001a0e8 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	ca2080e7          	jalr	-862(ra) # 80000c98 <release>
}
    80002ffe:	60e2                	ld	ra,24(sp)
    80003000:	6442                	ld	s0,16(sp)
    80003002:	64a2                	ld	s1,8(sp)
    80003004:	6902                	ld	s2,0(sp)
    80003006:	6105                	addi	sp,sp,32
    80003008:	8082                	ret
    panic("brelse");
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	5e650513          	addi	a0,a0,1510 # 800085f0 <syscalls+0xe0>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	52c080e7          	jalr	1324(ra) # 8000053e <panic>

000000008000301a <bpin>:

void
bpin(struct buf *b) {
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003026:	00017517          	auipc	a0,0x17
    8000302a:	0c250513          	addi	a0,a0,194 # 8001a0e8 <bcache>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003036:	40bc                	lw	a5,64(s1)
    80003038:	2785                	addiw	a5,a5,1
    8000303a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303c:	00017517          	auipc	a0,0x17
    80003040:	0ac50513          	addi	a0,a0,172 # 8001a0e8 <bcache>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c54080e7          	jalr	-940(ra) # 80000c98 <release>
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <bunpin>:

void
bunpin(struct buf *b) {
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003062:	00017517          	auipc	a0,0x17
    80003066:	08650513          	addi	a0,a0,134 # 8001a0e8 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	b7a080e7          	jalr	-1158(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003072:	40bc                	lw	a5,64(s1)
    80003074:	37fd                	addiw	a5,a5,-1
    80003076:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003078:	00017517          	auipc	a0,0x17
    8000307c:	07050513          	addi	a0,a0,112 # 8001a0e8 <bcache>
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	c18080e7          	jalr	-1000(ra) # 80000c98 <release>
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	64a2                	ld	s1,8(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	e04a                	sd	s2,0(sp)
    8000309c:	1000                	addi	s0,sp,32
    8000309e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030a0:	00d5d59b          	srliw	a1,a1,0xd
    800030a4:	0001f797          	auipc	a5,0x1f
    800030a8:	7207a783          	lw	a5,1824(a5) # 800227c4 <sb+0x1c>
    800030ac:	9dbd                	addw	a1,a1,a5
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	d9e080e7          	jalr	-610(ra) # 80002e4c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030b6:	0074f713          	andi	a4,s1,7
    800030ba:	4785                	li	a5,1
    800030bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030c0:	14ce                	slli	s1,s1,0x33
    800030c2:	90d9                	srli	s1,s1,0x36
    800030c4:	00950733          	add	a4,a0,s1
    800030c8:	05874703          	lbu	a4,88(a4)
    800030cc:	00e7f6b3          	and	a3,a5,a4
    800030d0:	c69d                	beqz	a3,800030fe <bfree+0x6c>
    800030d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030d4:	94aa                	add	s1,s1,a0
    800030d6:	fff7c793          	not	a5,a5
    800030da:	8ff9                	and	a5,a5,a4
    800030dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	118080e7          	jalr	280(ra) # 800041f8 <log_write>
  brelse(bp);
    800030e8:	854a                	mv	a0,s2
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	e92080e7          	jalr	-366(ra) # 80002f7c <brelse>
}
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	64a2                	ld	s1,8(sp)
    800030f8:	6902                	ld	s2,0(sp)
    800030fa:	6105                	addi	sp,sp,32
    800030fc:	8082                	ret
    panic("freeing free block");
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	4fa50513          	addi	a0,a0,1274 # 800085f8 <syscalls+0xe8>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	438080e7          	jalr	1080(ra) # 8000053e <panic>

000000008000310e <balloc>:
{
    8000310e:	711d                	addi	sp,sp,-96
    80003110:	ec86                	sd	ra,88(sp)
    80003112:	e8a2                	sd	s0,80(sp)
    80003114:	e4a6                	sd	s1,72(sp)
    80003116:	e0ca                	sd	s2,64(sp)
    80003118:	fc4e                	sd	s3,56(sp)
    8000311a:	f852                	sd	s4,48(sp)
    8000311c:	f456                	sd	s5,40(sp)
    8000311e:	f05a                	sd	s6,32(sp)
    80003120:	ec5e                	sd	s7,24(sp)
    80003122:	e862                	sd	s8,16(sp)
    80003124:	e466                	sd	s9,8(sp)
    80003126:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003128:	0001f797          	auipc	a5,0x1f
    8000312c:	6847a783          	lw	a5,1668(a5) # 800227ac <sb+0x4>
    80003130:	cbd1                	beqz	a5,800031c4 <balloc+0xb6>
    80003132:	8baa                	mv	s7,a0
    80003134:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003136:	0001fb17          	auipc	s6,0x1f
    8000313a:	672b0b13          	addi	s6,s6,1650 # 800227a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000313e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003140:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003142:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003144:	6c89                	lui	s9,0x2
    80003146:	a831                	j	80003162 <balloc+0x54>
    brelse(bp);
    80003148:	854a                	mv	a0,s2
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	e32080e7          	jalr	-462(ra) # 80002f7c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003152:	015c87bb          	addw	a5,s9,s5
    80003156:	00078a9b          	sext.w	s5,a5
    8000315a:	004b2703          	lw	a4,4(s6)
    8000315e:	06eaf363          	bgeu	s5,a4,800031c4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003162:	41fad79b          	sraiw	a5,s5,0x1f
    80003166:	0137d79b          	srliw	a5,a5,0x13
    8000316a:	015787bb          	addw	a5,a5,s5
    8000316e:	40d7d79b          	sraiw	a5,a5,0xd
    80003172:	01cb2583          	lw	a1,28(s6)
    80003176:	9dbd                	addw	a1,a1,a5
    80003178:	855e                	mv	a0,s7
    8000317a:	00000097          	auipc	ra,0x0
    8000317e:	cd2080e7          	jalr	-814(ra) # 80002e4c <bread>
    80003182:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003184:	004b2503          	lw	a0,4(s6)
    80003188:	000a849b          	sext.w	s1,s5
    8000318c:	8662                	mv	a2,s8
    8000318e:	faa4fde3          	bgeu	s1,a0,80003148 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003192:	41f6579b          	sraiw	a5,a2,0x1f
    80003196:	01d7d69b          	srliw	a3,a5,0x1d
    8000319a:	00c6873b          	addw	a4,a3,a2
    8000319e:	00777793          	andi	a5,a4,7
    800031a2:	9f95                	subw	a5,a5,a3
    800031a4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031a8:	4037571b          	sraiw	a4,a4,0x3
    800031ac:	00e906b3          	add	a3,s2,a4
    800031b0:	0586c683          	lbu	a3,88(a3)
    800031b4:	00d7f5b3          	and	a1,a5,a3
    800031b8:	cd91                	beqz	a1,800031d4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031ba:	2605                	addiw	a2,a2,1
    800031bc:	2485                	addiw	s1,s1,1
    800031be:	fd4618e3          	bne	a2,s4,8000318e <balloc+0x80>
    800031c2:	b759                	j	80003148 <balloc+0x3a>
  panic("balloc: out of blocks");
    800031c4:	00005517          	auipc	a0,0x5
    800031c8:	44c50513          	addi	a0,a0,1100 # 80008610 <syscalls+0x100>
    800031cc:	ffffd097          	auipc	ra,0xffffd
    800031d0:	372080e7          	jalr	882(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031d4:	974a                	add	a4,a4,s2
    800031d6:	8fd5                	or	a5,a5,a3
    800031d8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800031dc:	854a                	mv	a0,s2
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	01a080e7          	jalr	26(ra) # 800041f8 <log_write>
        brelse(bp);
    800031e6:	854a                	mv	a0,s2
    800031e8:	00000097          	auipc	ra,0x0
    800031ec:	d94080e7          	jalr	-620(ra) # 80002f7c <brelse>
  bp = bread(dev, bno);
    800031f0:	85a6                	mv	a1,s1
    800031f2:	855e                	mv	a0,s7
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	c58080e7          	jalr	-936(ra) # 80002e4c <bread>
    800031fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031fe:	40000613          	li	a2,1024
    80003202:	4581                	li	a1,0
    80003204:	05850513          	addi	a0,a0,88
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	ad8080e7          	jalr	-1320(ra) # 80000ce0 <memset>
  log_write(bp);
    80003210:	854a                	mv	a0,s2
    80003212:	00001097          	auipc	ra,0x1
    80003216:	fe6080e7          	jalr	-26(ra) # 800041f8 <log_write>
  brelse(bp);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	d60080e7          	jalr	-672(ra) # 80002f7c <brelse>
}
    80003224:	8526                	mv	a0,s1
    80003226:	60e6                	ld	ra,88(sp)
    80003228:	6446                	ld	s0,80(sp)
    8000322a:	64a6                	ld	s1,72(sp)
    8000322c:	6906                	ld	s2,64(sp)
    8000322e:	79e2                	ld	s3,56(sp)
    80003230:	7a42                	ld	s4,48(sp)
    80003232:	7aa2                	ld	s5,40(sp)
    80003234:	7b02                	ld	s6,32(sp)
    80003236:	6be2                	ld	s7,24(sp)
    80003238:	6c42                	ld	s8,16(sp)
    8000323a:	6ca2                	ld	s9,8(sp)
    8000323c:	6125                	addi	sp,sp,96
    8000323e:	8082                	ret

0000000080003240 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003240:	7179                	addi	sp,sp,-48
    80003242:	f406                	sd	ra,40(sp)
    80003244:	f022                	sd	s0,32(sp)
    80003246:	ec26                	sd	s1,24(sp)
    80003248:	e84a                	sd	s2,16(sp)
    8000324a:	e44e                	sd	s3,8(sp)
    8000324c:	e052                	sd	s4,0(sp)
    8000324e:	1800                	addi	s0,sp,48
    80003250:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003252:	47ad                	li	a5,11
    80003254:	04b7fe63          	bgeu	a5,a1,800032b0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003258:	ff45849b          	addiw	s1,a1,-12
    8000325c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003260:	0ff00793          	li	a5,255
    80003264:	0ae7e363          	bltu	a5,a4,8000330a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003268:	08052583          	lw	a1,128(a0)
    8000326c:	c5ad                	beqz	a1,800032d6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000326e:	00092503          	lw	a0,0(s2)
    80003272:	00000097          	auipc	ra,0x0
    80003276:	bda080e7          	jalr	-1062(ra) # 80002e4c <bread>
    8000327a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000327c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003280:	02049593          	slli	a1,s1,0x20
    80003284:	9181                	srli	a1,a1,0x20
    80003286:	058a                	slli	a1,a1,0x2
    80003288:	00b784b3          	add	s1,a5,a1
    8000328c:	0004a983          	lw	s3,0(s1)
    80003290:	04098d63          	beqz	s3,800032ea <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003294:	8552                	mv	a0,s4
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	ce6080e7          	jalr	-794(ra) # 80002f7c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000329e:	854e                	mv	a0,s3
    800032a0:	70a2                	ld	ra,40(sp)
    800032a2:	7402                	ld	s0,32(sp)
    800032a4:	64e2                	ld	s1,24(sp)
    800032a6:	6942                	ld	s2,16(sp)
    800032a8:	69a2                	ld	s3,8(sp)
    800032aa:	6a02                	ld	s4,0(sp)
    800032ac:	6145                	addi	sp,sp,48
    800032ae:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032b0:	02059493          	slli	s1,a1,0x20
    800032b4:	9081                	srli	s1,s1,0x20
    800032b6:	048a                	slli	s1,s1,0x2
    800032b8:	94aa                	add	s1,s1,a0
    800032ba:	0504a983          	lw	s3,80(s1)
    800032be:	fe0990e3          	bnez	s3,8000329e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032c2:	4108                	lw	a0,0(a0)
    800032c4:	00000097          	auipc	ra,0x0
    800032c8:	e4a080e7          	jalr	-438(ra) # 8000310e <balloc>
    800032cc:	0005099b          	sext.w	s3,a0
    800032d0:	0534a823          	sw	s3,80(s1)
    800032d4:	b7e9                	j	8000329e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032d6:	4108                	lw	a0,0(a0)
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	e36080e7          	jalr	-458(ra) # 8000310e <balloc>
    800032e0:	0005059b          	sext.w	a1,a0
    800032e4:	08b92023          	sw	a1,128(s2)
    800032e8:	b759                	j	8000326e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032ea:	00092503          	lw	a0,0(s2)
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	e20080e7          	jalr	-480(ra) # 8000310e <balloc>
    800032f6:	0005099b          	sext.w	s3,a0
    800032fa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032fe:	8552                	mv	a0,s4
    80003300:	00001097          	auipc	ra,0x1
    80003304:	ef8080e7          	jalr	-264(ra) # 800041f8 <log_write>
    80003308:	b771                	j	80003294 <bmap+0x54>
  panic("bmap: out of range");
    8000330a:	00005517          	auipc	a0,0x5
    8000330e:	31e50513          	addi	a0,a0,798 # 80008628 <syscalls+0x118>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	22c080e7          	jalr	556(ra) # 8000053e <panic>

000000008000331a <iget>:
{
    8000331a:	7179                	addi	sp,sp,-48
    8000331c:	f406                	sd	ra,40(sp)
    8000331e:	f022                	sd	s0,32(sp)
    80003320:	ec26                	sd	s1,24(sp)
    80003322:	e84a                	sd	s2,16(sp)
    80003324:	e44e                	sd	s3,8(sp)
    80003326:	e052                	sd	s4,0(sp)
    80003328:	1800                	addi	s0,sp,48
    8000332a:	89aa                	mv	s3,a0
    8000332c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000332e:	0001f517          	auipc	a0,0x1f
    80003332:	49a50513          	addi	a0,a0,1178 # 800227c8 <itable>
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	8ae080e7          	jalr	-1874(ra) # 80000be4 <acquire>
  empty = 0;
    8000333e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003340:	0001f497          	auipc	s1,0x1f
    80003344:	4a048493          	addi	s1,s1,1184 # 800227e0 <itable+0x18>
    80003348:	00021697          	auipc	a3,0x21
    8000334c:	f2868693          	addi	a3,a3,-216 # 80024270 <log>
    80003350:	a039                	j	8000335e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003352:	02090b63          	beqz	s2,80003388 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003356:	08848493          	addi	s1,s1,136
    8000335a:	02d48a63          	beq	s1,a3,8000338e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000335e:	449c                	lw	a5,8(s1)
    80003360:	fef059e3          	blez	a5,80003352 <iget+0x38>
    80003364:	4098                	lw	a4,0(s1)
    80003366:	ff3716e3          	bne	a4,s3,80003352 <iget+0x38>
    8000336a:	40d8                	lw	a4,4(s1)
    8000336c:	ff4713e3          	bne	a4,s4,80003352 <iget+0x38>
      ip->ref++;
    80003370:	2785                	addiw	a5,a5,1
    80003372:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003374:	0001f517          	auipc	a0,0x1f
    80003378:	45450513          	addi	a0,a0,1108 # 800227c8 <itable>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	91c080e7          	jalr	-1764(ra) # 80000c98 <release>
      return ip;
    80003384:	8926                	mv	s2,s1
    80003386:	a03d                	j	800033b4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003388:	f7f9                	bnez	a5,80003356 <iget+0x3c>
    8000338a:	8926                	mv	s2,s1
    8000338c:	b7e9                	j	80003356 <iget+0x3c>
  if(empty == 0)
    8000338e:	02090c63          	beqz	s2,800033c6 <iget+0xac>
  ip->dev = dev;
    80003392:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003396:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000339a:	4785                	li	a5,1
    8000339c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033a0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800033a4:	0001f517          	auipc	a0,0x1f
    800033a8:	42450513          	addi	a0,a0,1060 # 800227c8 <itable>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	8ec080e7          	jalr	-1812(ra) # 80000c98 <release>
}
    800033b4:	854a                	mv	a0,s2
    800033b6:	70a2                	ld	ra,40(sp)
    800033b8:	7402                	ld	s0,32(sp)
    800033ba:	64e2                	ld	s1,24(sp)
    800033bc:	6942                	ld	s2,16(sp)
    800033be:	69a2                	ld	s3,8(sp)
    800033c0:	6a02                	ld	s4,0(sp)
    800033c2:	6145                	addi	sp,sp,48
    800033c4:	8082                	ret
    panic("iget: no inodes");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	27a50513          	addi	a0,a0,634 # 80008640 <syscalls+0x130>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	170080e7          	jalr	368(ra) # 8000053e <panic>

00000000800033d6 <fsinit>:
fsinit(int dev) {
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	1800                	addi	s0,sp,48
    800033e4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033e6:	4585                	li	a1,1
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	a64080e7          	jalr	-1436(ra) # 80002e4c <bread>
    800033f0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033f2:	0001f997          	auipc	s3,0x1f
    800033f6:	3b698993          	addi	s3,s3,950 # 800227a8 <sb>
    800033fa:	02000613          	li	a2,32
    800033fe:	05850593          	addi	a1,a0,88
    80003402:	854e                	mv	a0,s3
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	93c080e7          	jalr	-1732(ra) # 80000d40 <memmove>
  brelse(bp);
    8000340c:	8526                	mv	a0,s1
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	b6e080e7          	jalr	-1170(ra) # 80002f7c <brelse>
  if(sb.magic != FSMAGIC)
    80003416:	0009a703          	lw	a4,0(s3)
    8000341a:	102037b7          	lui	a5,0x10203
    8000341e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003422:	02f71263          	bne	a4,a5,80003446 <fsinit+0x70>
  initlog(dev, &sb);
    80003426:	0001f597          	auipc	a1,0x1f
    8000342a:	38258593          	addi	a1,a1,898 # 800227a8 <sb>
    8000342e:	854a                	mv	a0,s2
    80003430:	00001097          	auipc	ra,0x1
    80003434:	b4c080e7          	jalr	-1204(ra) # 80003f7c <initlog>
}
    80003438:	70a2                	ld	ra,40(sp)
    8000343a:	7402                	ld	s0,32(sp)
    8000343c:	64e2                	ld	s1,24(sp)
    8000343e:	6942                	ld	s2,16(sp)
    80003440:	69a2                	ld	s3,8(sp)
    80003442:	6145                	addi	sp,sp,48
    80003444:	8082                	ret
    panic("invalid file system");
    80003446:	00005517          	auipc	a0,0x5
    8000344a:	20a50513          	addi	a0,a0,522 # 80008650 <syscalls+0x140>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	0f0080e7          	jalr	240(ra) # 8000053e <panic>

0000000080003456 <iinit>:
{
    80003456:	7179                	addi	sp,sp,-48
    80003458:	f406                	sd	ra,40(sp)
    8000345a:	f022                	sd	s0,32(sp)
    8000345c:	ec26                	sd	s1,24(sp)
    8000345e:	e84a                	sd	s2,16(sp)
    80003460:	e44e                	sd	s3,8(sp)
    80003462:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003464:	00005597          	auipc	a1,0x5
    80003468:	20458593          	addi	a1,a1,516 # 80008668 <syscalls+0x158>
    8000346c:	0001f517          	auipc	a0,0x1f
    80003470:	35c50513          	addi	a0,a0,860 # 800227c8 <itable>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	6e0080e7          	jalr	1760(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000347c:	0001f497          	auipc	s1,0x1f
    80003480:	37448493          	addi	s1,s1,884 # 800227f0 <itable+0x28>
    80003484:	00021997          	auipc	s3,0x21
    80003488:	dfc98993          	addi	s3,s3,-516 # 80024280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000348c:	00005917          	auipc	s2,0x5
    80003490:	1e490913          	addi	s2,s2,484 # 80008670 <syscalls+0x160>
    80003494:	85ca                	mv	a1,s2
    80003496:	8526                	mv	a0,s1
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	e46080e7          	jalr	-442(ra) # 800042de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034a0:	08848493          	addi	s1,s1,136
    800034a4:	ff3498e3          	bne	s1,s3,80003494 <iinit+0x3e>
}
    800034a8:	70a2                	ld	ra,40(sp)
    800034aa:	7402                	ld	s0,32(sp)
    800034ac:	64e2                	ld	s1,24(sp)
    800034ae:	6942                	ld	s2,16(sp)
    800034b0:	69a2                	ld	s3,8(sp)
    800034b2:	6145                	addi	sp,sp,48
    800034b4:	8082                	ret

00000000800034b6 <ialloc>:
{
    800034b6:	715d                	addi	sp,sp,-80
    800034b8:	e486                	sd	ra,72(sp)
    800034ba:	e0a2                	sd	s0,64(sp)
    800034bc:	fc26                	sd	s1,56(sp)
    800034be:	f84a                	sd	s2,48(sp)
    800034c0:	f44e                	sd	s3,40(sp)
    800034c2:	f052                	sd	s4,32(sp)
    800034c4:	ec56                	sd	s5,24(sp)
    800034c6:	e85a                	sd	s6,16(sp)
    800034c8:	e45e                	sd	s7,8(sp)
    800034ca:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034cc:	0001f717          	auipc	a4,0x1f
    800034d0:	2e872703          	lw	a4,744(a4) # 800227b4 <sb+0xc>
    800034d4:	4785                	li	a5,1
    800034d6:	04e7fa63          	bgeu	a5,a4,8000352a <ialloc+0x74>
    800034da:	8aaa                	mv	s5,a0
    800034dc:	8bae                	mv	s7,a1
    800034de:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034e0:	0001fa17          	auipc	s4,0x1f
    800034e4:	2c8a0a13          	addi	s4,s4,712 # 800227a8 <sb>
    800034e8:	00048b1b          	sext.w	s6,s1
    800034ec:	0044d593          	srli	a1,s1,0x4
    800034f0:	018a2783          	lw	a5,24(s4)
    800034f4:	9dbd                	addw	a1,a1,a5
    800034f6:	8556                	mv	a0,s5
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	954080e7          	jalr	-1708(ra) # 80002e4c <bread>
    80003500:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003502:	05850993          	addi	s3,a0,88
    80003506:	00f4f793          	andi	a5,s1,15
    8000350a:	079a                	slli	a5,a5,0x6
    8000350c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000350e:	00099783          	lh	a5,0(s3)
    80003512:	c785                	beqz	a5,8000353a <ialloc+0x84>
    brelse(bp);
    80003514:	00000097          	auipc	ra,0x0
    80003518:	a68080e7          	jalr	-1432(ra) # 80002f7c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000351c:	0485                	addi	s1,s1,1
    8000351e:	00ca2703          	lw	a4,12(s4)
    80003522:	0004879b          	sext.w	a5,s1
    80003526:	fce7e1e3          	bltu	a5,a4,800034e8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000352a:	00005517          	auipc	a0,0x5
    8000352e:	14e50513          	addi	a0,a0,334 # 80008678 <syscalls+0x168>
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	00c080e7          	jalr	12(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000353a:	04000613          	li	a2,64
    8000353e:	4581                	li	a1,0
    80003540:	854e                	mv	a0,s3
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	79e080e7          	jalr	1950(ra) # 80000ce0 <memset>
      dip->type = type;
    8000354a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000354e:	854a                	mv	a0,s2
    80003550:	00001097          	auipc	ra,0x1
    80003554:	ca8080e7          	jalr	-856(ra) # 800041f8 <log_write>
      brelse(bp);
    80003558:	854a                	mv	a0,s2
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	a22080e7          	jalr	-1502(ra) # 80002f7c <brelse>
      return iget(dev, inum);
    80003562:	85da                	mv	a1,s6
    80003564:	8556                	mv	a0,s5
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	db4080e7          	jalr	-588(ra) # 8000331a <iget>
}
    8000356e:	60a6                	ld	ra,72(sp)
    80003570:	6406                	ld	s0,64(sp)
    80003572:	74e2                	ld	s1,56(sp)
    80003574:	7942                	ld	s2,48(sp)
    80003576:	79a2                	ld	s3,40(sp)
    80003578:	7a02                	ld	s4,32(sp)
    8000357a:	6ae2                	ld	s5,24(sp)
    8000357c:	6b42                	ld	s6,16(sp)
    8000357e:	6ba2                	ld	s7,8(sp)
    80003580:	6161                	addi	sp,sp,80
    80003582:	8082                	ret

0000000080003584 <iupdate>:
{
    80003584:	1101                	addi	sp,sp,-32
    80003586:	ec06                	sd	ra,24(sp)
    80003588:	e822                	sd	s0,16(sp)
    8000358a:	e426                	sd	s1,8(sp)
    8000358c:	e04a                	sd	s2,0(sp)
    8000358e:	1000                	addi	s0,sp,32
    80003590:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003592:	415c                	lw	a5,4(a0)
    80003594:	0047d79b          	srliw	a5,a5,0x4
    80003598:	0001f597          	auipc	a1,0x1f
    8000359c:	2285a583          	lw	a1,552(a1) # 800227c0 <sb+0x18>
    800035a0:	9dbd                	addw	a1,a1,a5
    800035a2:	4108                	lw	a0,0(a0)
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	8a8080e7          	jalr	-1880(ra) # 80002e4c <bread>
    800035ac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035ae:	05850793          	addi	a5,a0,88
    800035b2:	40c8                	lw	a0,4(s1)
    800035b4:	893d                	andi	a0,a0,15
    800035b6:	051a                	slli	a0,a0,0x6
    800035b8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035ba:	04449703          	lh	a4,68(s1)
    800035be:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035c2:	04649703          	lh	a4,70(s1)
    800035c6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035ca:	04849703          	lh	a4,72(s1)
    800035ce:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035d2:	04a49703          	lh	a4,74(s1)
    800035d6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035da:	44f8                	lw	a4,76(s1)
    800035dc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035de:	03400613          	li	a2,52
    800035e2:	05048593          	addi	a1,s1,80
    800035e6:	0531                	addi	a0,a0,12
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	758080e7          	jalr	1880(ra) # 80000d40 <memmove>
  log_write(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	c06080e7          	jalr	-1018(ra) # 800041f8 <log_write>
  brelse(bp);
    800035fa:	854a                	mv	a0,s2
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	980080e7          	jalr	-1664(ra) # 80002f7c <brelse>
}
    80003604:	60e2                	ld	ra,24(sp)
    80003606:	6442                	ld	s0,16(sp)
    80003608:	64a2                	ld	s1,8(sp)
    8000360a:	6902                	ld	s2,0(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret

0000000080003610 <idup>:
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	e426                	sd	s1,8(sp)
    80003618:	1000                	addi	s0,sp,32
    8000361a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000361c:	0001f517          	auipc	a0,0x1f
    80003620:	1ac50513          	addi	a0,a0,428 # 800227c8 <itable>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	5c0080e7          	jalr	1472(ra) # 80000be4 <acquire>
  ip->ref++;
    8000362c:	449c                	lw	a5,8(s1)
    8000362e:	2785                	addiw	a5,a5,1
    80003630:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003632:	0001f517          	auipc	a0,0x1f
    80003636:	19650513          	addi	a0,a0,406 # 800227c8 <itable>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	65e080e7          	jalr	1630(ra) # 80000c98 <release>
}
    80003642:	8526                	mv	a0,s1
    80003644:	60e2                	ld	ra,24(sp)
    80003646:	6442                	ld	s0,16(sp)
    80003648:	64a2                	ld	s1,8(sp)
    8000364a:	6105                	addi	sp,sp,32
    8000364c:	8082                	ret

000000008000364e <ilock>:
{
    8000364e:	1101                	addi	sp,sp,-32
    80003650:	ec06                	sd	ra,24(sp)
    80003652:	e822                	sd	s0,16(sp)
    80003654:	e426                	sd	s1,8(sp)
    80003656:	e04a                	sd	s2,0(sp)
    80003658:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000365a:	c115                	beqz	a0,8000367e <ilock+0x30>
    8000365c:	84aa                	mv	s1,a0
    8000365e:	451c                	lw	a5,8(a0)
    80003660:	00f05f63          	blez	a5,8000367e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003664:	0541                	addi	a0,a0,16
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	cb2080e7          	jalr	-846(ra) # 80004318 <acquiresleep>
  if(ip->valid == 0){
    8000366e:	40bc                	lw	a5,64(s1)
    80003670:	cf99                	beqz	a5,8000368e <ilock+0x40>
}
    80003672:	60e2                	ld	ra,24(sp)
    80003674:	6442                	ld	s0,16(sp)
    80003676:	64a2                	ld	s1,8(sp)
    80003678:	6902                	ld	s2,0(sp)
    8000367a:	6105                	addi	sp,sp,32
    8000367c:	8082                	ret
    panic("ilock");
    8000367e:	00005517          	auipc	a0,0x5
    80003682:	01250513          	addi	a0,a0,18 # 80008690 <syscalls+0x180>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	eb8080e7          	jalr	-328(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000368e:	40dc                	lw	a5,4(s1)
    80003690:	0047d79b          	srliw	a5,a5,0x4
    80003694:	0001f597          	auipc	a1,0x1f
    80003698:	12c5a583          	lw	a1,300(a1) # 800227c0 <sb+0x18>
    8000369c:	9dbd                	addw	a1,a1,a5
    8000369e:	4088                	lw	a0,0(s1)
    800036a0:	fffff097          	auipc	ra,0xfffff
    800036a4:	7ac080e7          	jalr	1964(ra) # 80002e4c <bread>
    800036a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036aa:	05850593          	addi	a1,a0,88
    800036ae:	40dc                	lw	a5,4(s1)
    800036b0:	8bbd                	andi	a5,a5,15
    800036b2:	079a                	slli	a5,a5,0x6
    800036b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036b6:	00059783          	lh	a5,0(a1)
    800036ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036be:	00259783          	lh	a5,2(a1)
    800036c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036c6:	00459783          	lh	a5,4(a1)
    800036ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036ce:	00659783          	lh	a5,6(a1)
    800036d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036d6:	459c                	lw	a5,8(a1)
    800036d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036da:	03400613          	li	a2,52
    800036de:	05b1                	addi	a1,a1,12
    800036e0:	05048513          	addi	a0,s1,80
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	65c080e7          	jalr	1628(ra) # 80000d40 <memmove>
    brelse(bp);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	88e080e7          	jalr	-1906(ra) # 80002f7c <brelse>
    ip->valid = 1;
    800036f6:	4785                	li	a5,1
    800036f8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036fa:	04449783          	lh	a5,68(s1)
    800036fe:	fbb5                	bnez	a5,80003672 <ilock+0x24>
      panic("ilock: no type");
    80003700:	00005517          	auipc	a0,0x5
    80003704:	f9850513          	addi	a0,a0,-104 # 80008698 <syscalls+0x188>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	e36080e7          	jalr	-458(ra) # 8000053e <panic>

0000000080003710 <iunlock>:
{
    80003710:	1101                	addi	sp,sp,-32
    80003712:	ec06                	sd	ra,24(sp)
    80003714:	e822                	sd	s0,16(sp)
    80003716:	e426                	sd	s1,8(sp)
    80003718:	e04a                	sd	s2,0(sp)
    8000371a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000371c:	c905                	beqz	a0,8000374c <iunlock+0x3c>
    8000371e:	84aa                	mv	s1,a0
    80003720:	01050913          	addi	s2,a0,16
    80003724:	854a                	mv	a0,s2
    80003726:	00001097          	auipc	ra,0x1
    8000372a:	c8c080e7          	jalr	-884(ra) # 800043b2 <holdingsleep>
    8000372e:	cd19                	beqz	a0,8000374c <iunlock+0x3c>
    80003730:	449c                	lw	a5,8(s1)
    80003732:	00f05d63          	blez	a5,8000374c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	c36080e7          	jalr	-970(ra) # 8000436e <releasesleep>
}
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6902                	ld	s2,0(sp)
    80003748:	6105                	addi	sp,sp,32
    8000374a:	8082                	ret
    panic("iunlock");
    8000374c:	00005517          	auipc	a0,0x5
    80003750:	f5c50513          	addi	a0,a0,-164 # 800086a8 <syscalls+0x198>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	dea080e7          	jalr	-534(ra) # 8000053e <panic>

000000008000375c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000375c:	7179                	addi	sp,sp,-48
    8000375e:	f406                	sd	ra,40(sp)
    80003760:	f022                	sd	s0,32(sp)
    80003762:	ec26                	sd	s1,24(sp)
    80003764:	e84a                	sd	s2,16(sp)
    80003766:	e44e                	sd	s3,8(sp)
    80003768:	e052                	sd	s4,0(sp)
    8000376a:	1800                	addi	s0,sp,48
    8000376c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000376e:	05050493          	addi	s1,a0,80
    80003772:	08050913          	addi	s2,a0,128
    80003776:	a021                	j	8000377e <itrunc+0x22>
    80003778:	0491                	addi	s1,s1,4
    8000377a:	01248d63          	beq	s1,s2,80003794 <itrunc+0x38>
    if(ip->addrs[i]){
    8000377e:	408c                	lw	a1,0(s1)
    80003780:	dde5                	beqz	a1,80003778 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003782:	0009a503          	lw	a0,0(s3)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	90c080e7          	jalr	-1780(ra) # 80003092 <bfree>
      ip->addrs[i] = 0;
    8000378e:	0004a023          	sw	zero,0(s1)
    80003792:	b7dd                	j	80003778 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003794:	0809a583          	lw	a1,128(s3)
    80003798:	e185                	bnez	a1,800037b8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000379a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000379e:	854e                	mv	a0,s3
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	de4080e7          	jalr	-540(ra) # 80003584 <iupdate>
}
    800037a8:	70a2                	ld	ra,40(sp)
    800037aa:	7402                	ld	s0,32(sp)
    800037ac:	64e2                	ld	s1,24(sp)
    800037ae:	6942                	ld	s2,16(sp)
    800037b0:	69a2                	ld	s3,8(sp)
    800037b2:	6a02                	ld	s4,0(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	690080e7          	jalr	1680(ra) # 80002e4c <bread>
    800037c4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037c6:	05850493          	addi	s1,a0,88
    800037ca:	45850913          	addi	s2,a0,1112
    800037ce:	a811                	j	800037e2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037d0:	0009a503          	lw	a0,0(s3)
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	8be080e7          	jalr	-1858(ra) # 80003092 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800037dc:	0491                	addi	s1,s1,4
    800037de:	01248563          	beq	s1,s2,800037e8 <itrunc+0x8c>
      if(a[j])
    800037e2:	408c                	lw	a1,0(s1)
    800037e4:	dde5                	beqz	a1,800037dc <itrunc+0x80>
    800037e6:	b7ed                	j	800037d0 <itrunc+0x74>
    brelse(bp);
    800037e8:	8552                	mv	a0,s4
    800037ea:	fffff097          	auipc	ra,0xfffff
    800037ee:	792080e7          	jalr	1938(ra) # 80002f7c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037f2:	0809a583          	lw	a1,128(s3)
    800037f6:	0009a503          	lw	a0,0(s3)
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	898080e7          	jalr	-1896(ra) # 80003092 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003802:	0809a023          	sw	zero,128(s3)
    80003806:	bf51                	j	8000379a <itrunc+0x3e>

0000000080003808 <iput>:
{
    80003808:	1101                	addi	sp,sp,-32
    8000380a:	ec06                	sd	ra,24(sp)
    8000380c:	e822                	sd	s0,16(sp)
    8000380e:	e426                	sd	s1,8(sp)
    80003810:	e04a                	sd	s2,0(sp)
    80003812:	1000                	addi	s0,sp,32
    80003814:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003816:	0001f517          	auipc	a0,0x1f
    8000381a:	fb250513          	addi	a0,a0,-78 # 800227c8 <itable>
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	3c6080e7          	jalr	966(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003826:	4498                	lw	a4,8(s1)
    80003828:	4785                	li	a5,1
    8000382a:	02f70363          	beq	a4,a5,80003850 <iput+0x48>
  ip->ref--;
    8000382e:	449c                	lw	a5,8(s1)
    80003830:	37fd                	addiw	a5,a5,-1
    80003832:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003834:	0001f517          	auipc	a0,0x1f
    80003838:	f9450513          	addi	a0,a0,-108 # 800227c8 <itable>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	45c080e7          	jalr	1116(ra) # 80000c98 <release>
}
    80003844:	60e2                	ld	ra,24(sp)
    80003846:	6442                	ld	s0,16(sp)
    80003848:	64a2                	ld	s1,8(sp)
    8000384a:	6902                	ld	s2,0(sp)
    8000384c:	6105                	addi	sp,sp,32
    8000384e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	dff1                	beqz	a5,8000382e <iput+0x26>
    80003854:	04a49783          	lh	a5,74(s1)
    80003858:	fbf9                	bnez	a5,8000382e <iput+0x26>
    acquiresleep(&ip->lock);
    8000385a:	01048913          	addi	s2,s1,16
    8000385e:	854a                	mv	a0,s2
    80003860:	00001097          	auipc	ra,0x1
    80003864:	ab8080e7          	jalr	-1352(ra) # 80004318 <acquiresleep>
    release(&itable.lock);
    80003868:	0001f517          	auipc	a0,0x1f
    8000386c:	f6050513          	addi	a0,a0,-160 # 800227c8 <itable>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	428080e7          	jalr	1064(ra) # 80000c98 <release>
    itrunc(ip);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	ee2080e7          	jalr	-286(ra) # 8000375c <itrunc>
    ip->type = 0;
    80003882:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003886:	8526                	mv	a0,s1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	cfc080e7          	jalr	-772(ra) # 80003584 <iupdate>
    ip->valid = 0;
    80003890:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	ad8080e7          	jalr	-1320(ra) # 8000436e <releasesleep>
    acquire(&itable.lock);
    8000389e:	0001f517          	auipc	a0,0x1f
    800038a2:	f2a50513          	addi	a0,a0,-214 # 800227c8 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	33e080e7          	jalr	830(ra) # 80000be4 <acquire>
    800038ae:	b741                	j	8000382e <iput+0x26>

00000000800038b0 <iunlockput>:
{
    800038b0:	1101                	addi	sp,sp,-32
    800038b2:	ec06                	sd	ra,24(sp)
    800038b4:	e822                	sd	s0,16(sp)
    800038b6:	e426                	sd	s1,8(sp)
    800038b8:	1000                	addi	s0,sp,32
    800038ba:	84aa                	mv	s1,a0
  iunlock(ip);
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	e54080e7          	jalr	-428(ra) # 80003710 <iunlock>
  iput(ip);
    800038c4:	8526                	mv	a0,s1
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	f42080e7          	jalr	-190(ra) # 80003808 <iput>
}
    800038ce:	60e2                	ld	ra,24(sp)
    800038d0:	6442                	ld	s0,16(sp)
    800038d2:	64a2                	ld	s1,8(sp)
    800038d4:	6105                	addi	sp,sp,32
    800038d6:	8082                	ret

00000000800038d8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038d8:	1141                	addi	sp,sp,-16
    800038da:	e422                	sd	s0,8(sp)
    800038dc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038de:	411c                	lw	a5,0(a0)
    800038e0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038e2:	415c                	lw	a5,4(a0)
    800038e4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038e6:	04451783          	lh	a5,68(a0)
    800038ea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038ee:	04a51783          	lh	a5,74(a0)
    800038f2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038f6:	04c56783          	lwu	a5,76(a0)
    800038fa:	e99c                	sd	a5,16(a1)
}
    800038fc:	6422                	ld	s0,8(sp)
    800038fe:	0141                	addi	sp,sp,16
    80003900:	8082                	ret

0000000080003902 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003902:	457c                	lw	a5,76(a0)
    80003904:	0ed7e963          	bltu	a5,a3,800039f6 <readi+0xf4>
{
    80003908:	7159                	addi	sp,sp,-112
    8000390a:	f486                	sd	ra,104(sp)
    8000390c:	f0a2                	sd	s0,96(sp)
    8000390e:	eca6                	sd	s1,88(sp)
    80003910:	e8ca                	sd	s2,80(sp)
    80003912:	e4ce                	sd	s3,72(sp)
    80003914:	e0d2                	sd	s4,64(sp)
    80003916:	fc56                	sd	s5,56(sp)
    80003918:	f85a                	sd	s6,48(sp)
    8000391a:	f45e                	sd	s7,40(sp)
    8000391c:	f062                	sd	s8,32(sp)
    8000391e:	ec66                	sd	s9,24(sp)
    80003920:	e86a                	sd	s10,16(sp)
    80003922:	e46e                	sd	s11,8(sp)
    80003924:	1880                	addi	s0,sp,112
    80003926:	8baa                	mv	s7,a0
    80003928:	8c2e                	mv	s8,a1
    8000392a:	8ab2                	mv	s5,a2
    8000392c:	84b6                	mv	s1,a3
    8000392e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003930:	9f35                	addw	a4,a4,a3
    return 0;
    80003932:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003934:	0ad76063          	bltu	a4,a3,800039d4 <readi+0xd2>
  if(off + n > ip->size)
    80003938:	00e7f463          	bgeu	a5,a4,80003940 <readi+0x3e>
    n = ip->size - off;
    8000393c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003940:	0a0b0963          	beqz	s6,800039f2 <readi+0xf0>
    80003944:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003946:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000394a:	5cfd                	li	s9,-1
    8000394c:	a82d                	j	80003986 <readi+0x84>
    8000394e:	020a1d93          	slli	s11,s4,0x20
    80003952:	020ddd93          	srli	s11,s11,0x20
    80003956:	05890613          	addi	a2,s2,88
    8000395a:	86ee                	mv	a3,s11
    8000395c:	963a                	add	a2,a2,a4
    8000395e:	85d6                	mv	a1,s5
    80003960:	8562                	mv	a0,s8
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	b2e080e7          	jalr	-1234(ra) # 80002490 <either_copyout>
    8000396a:	05950d63          	beq	a0,s9,800039c4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	fffff097          	auipc	ra,0xfffff
    80003974:	60c080e7          	jalr	1548(ra) # 80002f7c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003978:	013a09bb          	addw	s3,s4,s3
    8000397c:	009a04bb          	addw	s1,s4,s1
    80003980:	9aee                	add	s5,s5,s11
    80003982:	0569f763          	bgeu	s3,s6,800039d0 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003986:	000ba903          	lw	s2,0(s7)
    8000398a:	00a4d59b          	srliw	a1,s1,0xa
    8000398e:	855e                	mv	a0,s7
    80003990:	00000097          	auipc	ra,0x0
    80003994:	8b0080e7          	jalr	-1872(ra) # 80003240 <bmap>
    80003998:	0005059b          	sext.w	a1,a0
    8000399c:	854a                	mv	a0,s2
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	4ae080e7          	jalr	1198(ra) # 80002e4c <bread>
    800039a6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a8:	3ff4f713          	andi	a4,s1,1023
    800039ac:	40ed07bb          	subw	a5,s10,a4
    800039b0:	413b06bb          	subw	a3,s6,s3
    800039b4:	8a3e                	mv	s4,a5
    800039b6:	2781                	sext.w	a5,a5
    800039b8:	0006861b          	sext.w	a2,a3
    800039bc:	f8f679e3          	bgeu	a2,a5,8000394e <readi+0x4c>
    800039c0:	8a36                	mv	s4,a3
    800039c2:	b771                	j	8000394e <readi+0x4c>
      brelse(bp);
    800039c4:	854a                	mv	a0,s2
    800039c6:	fffff097          	auipc	ra,0xfffff
    800039ca:	5b6080e7          	jalr	1462(ra) # 80002f7c <brelse>
      tot = -1;
    800039ce:	59fd                	li	s3,-1
  }
  return tot;
    800039d0:	0009851b          	sext.w	a0,s3
}
    800039d4:	70a6                	ld	ra,104(sp)
    800039d6:	7406                	ld	s0,96(sp)
    800039d8:	64e6                	ld	s1,88(sp)
    800039da:	6946                	ld	s2,80(sp)
    800039dc:	69a6                	ld	s3,72(sp)
    800039de:	6a06                	ld	s4,64(sp)
    800039e0:	7ae2                	ld	s5,56(sp)
    800039e2:	7b42                	ld	s6,48(sp)
    800039e4:	7ba2                	ld	s7,40(sp)
    800039e6:	7c02                	ld	s8,32(sp)
    800039e8:	6ce2                	ld	s9,24(sp)
    800039ea:	6d42                	ld	s10,16(sp)
    800039ec:	6da2                	ld	s11,8(sp)
    800039ee:	6165                	addi	sp,sp,112
    800039f0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f2:	89da                	mv	s3,s6
    800039f4:	bff1                	j	800039d0 <readi+0xce>
    return 0;
    800039f6:	4501                	li	a0,0
}
    800039f8:	8082                	ret

00000000800039fa <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039fa:	457c                	lw	a5,76(a0)
    800039fc:	10d7e863          	bltu	a5,a3,80003b0c <writei+0x112>
{
    80003a00:	7159                	addi	sp,sp,-112
    80003a02:	f486                	sd	ra,104(sp)
    80003a04:	f0a2                	sd	s0,96(sp)
    80003a06:	eca6                	sd	s1,88(sp)
    80003a08:	e8ca                	sd	s2,80(sp)
    80003a0a:	e4ce                	sd	s3,72(sp)
    80003a0c:	e0d2                	sd	s4,64(sp)
    80003a0e:	fc56                	sd	s5,56(sp)
    80003a10:	f85a                	sd	s6,48(sp)
    80003a12:	f45e                	sd	s7,40(sp)
    80003a14:	f062                	sd	s8,32(sp)
    80003a16:	ec66                	sd	s9,24(sp)
    80003a18:	e86a                	sd	s10,16(sp)
    80003a1a:	e46e                	sd	s11,8(sp)
    80003a1c:	1880                	addi	s0,sp,112
    80003a1e:	8b2a                	mv	s6,a0
    80003a20:	8c2e                	mv	s8,a1
    80003a22:	8ab2                	mv	s5,a2
    80003a24:	8936                	mv	s2,a3
    80003a26:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003a28:	00e687bb          	addw	a5,a3,a4
    80003a2c:	0ed7e263          	bltu	a5,a3,80003b10 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a30:	00043737          	lui	a4,0x43
    80003a34:	0ef76063          	bltu	a4,a5,80003b14 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a38:	0c0b8863          	beqz	s7,80003b08 <writei+0x10e>
    80003a3c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a3e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a42:	5cfd                	li	s9,-1
    80003a44:	a091                	j	80003a88 <writei+0x8e>
    80003a46:	02099d93          	slli	s11,s3,0x20
    80003a4a:	020ddd93          	srli	s11,s11,0x20
    80003a4e:	05848513          	addi	a0,s1,88
    80003a52:	86ee                	mv	a3,s11
    80003a54:	8656                	mv	a2,s5
    80003a56:	85e2                	mv	a1,s8
    80003a58:	953a                	add	a0,a0,a4
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	a8c080e7          	jalr	-1396(ra) # 800024e6 <either_copyin>
    80003a62:	07950263          	beq	a0,s9,80003ac6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a66:	8526                	mv	a0,s1
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	790080e7          	jalr	1936(ra) # 800041f8 <log_write>
    brelse(bp);
    80003a70:	8526                	mv	a0,s1
    80003a72:	fffff097          	auipc	ra,0xfffff
    80003a76:	50a080e7          	jalr	1290(ra) # 80002f7c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a7a:	01498a3b          	addw	s4,s3,s4
    80003a7e:	0129893b          	addw	s2,s3,s2
    80003a82:	9aee                	add	s5,s5,s11
    80003a84:	057a7663          	bgeu	s4,s7,80003ad0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a88:	000b2483          	lw	s1,0(s6)
    80003a8c:	00a9559b          	srliw	a1,s2,0xa
    80003a90:	855a                	mv	a0,s6
    80003a92:	fffff097          	auipc	ra,0xfffff
    80003a96:	7ae080e7          	jalr	1966(ra) # 80003240 <bmap>
    80003a9a:	0005059b          	sext.w	a1,a0
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	3ac080e7          	jalr	940(ra) # 80002e4c <bread>
    80003aa8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aaa:	3ff97713          	andi	a4,s2,1023
    80003aae:	40ed07bb          	subw	a5,s10,a4
    80003ab2:	414b86bb          	subw	a3,s7,s4
    80003ab6:	89be                	mv	s3,a5
    80003ab8:	2781                	sext.w	a5,a5
    80003aba:	0006861b          	sext.w	a2,a3
    80003abe:	f8f674e3          	bgeu	a2,a5,80003a46 <writei+0x4c>
    80003ac2:	89b6                	mv	s3,a3
    80003ac4:	b749                	j	80003a46 <writei+0x4c>
      brelse(bp);
    80003ac6:	8526                	mv	a0,s1
    80003ac8:	fffff097          	auipc	ra,0xfffff
    80003acc:	4b4080e7          	jalr	1204(ra) # 80002f7c <brelse>
  }

  if(off > ip->size)
    80003ad0:	04cb2783          	lw	a5,76(s6)
    80003ad4:	0127f463          	bgeu	a5,s2,80003adc <writei+0xe2>
    ip->size = off;
    80003ad8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003adc:	855a                	mv	a0,s6
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	aa6080e7          	jalr	-1370(ra) # 80003584 <iupdate>

  return tot;
    80003ae6:	000a051b          	sext.w	a0,s4
}
    80003aea:	70a6                	ld	ra,104(sp)
    80003aec:	7406                	ld	s0,96(sp)
    80003aee:	64e6                	ld	s1,88(sp)
    80003af0:	6946                	ld	s2,80(sp)
    80003af2:	69a6                	ld	s3,72(sp)
    80003af4:	6a06                	ld	s4,64(sp)
    80003af6:	7ae2                	ld	s5,56(sp)
    80003af8:	7b42                	ld	s6,48(sp)
    80003afa:	7ba2                	ld	s7,40(sp)
    80003afc:	7c02                	ld	s8,32(sp)
    80003afe:	6ce2                	ld	s9,24(sp)
    80003b00:	6d42                	ld	s10,16(sp)
    80003b02:	6da2                	ld	s11,8(sp)
    80003b04:	6165                	addi	sp,sp,112
    80003b06:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b08:	8a5e                	mv	s4,s7
    80003b0a:	bfc9                	j	80003adc <writei+0xe2>
    return -1;
    80003b0c:	557d                	li	a0,-1
}
    80003b0e:	8082                	ret
    return -1;
    80003b10:	557d                	li	a0,-1
    80003b12:	bfe1                	j	80003aea <writei+0xf0>
    return -1;
    80003b14:	557d                	li	a0,-1
    80003b16:	bfd1                	j	80003aea <writei+0xf0>

0000000080003b18 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b18:	1141                	addi	sp,sp,-16
    80003b1a:	e406                	sd	ra,8(sp)
    80003b1c:	e022                	sd	s0,0(sp)
    80003b1e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b20:	4639                	li	a2,14
    80003b22:	ffffd097          	auipc	ra,0xffffd
    80003b26:	296080e7          	jalr	662(ra) # 80000db8 <strncmp>
}
    80003b2a:	60a2                	ld	ra,8(sp)
    80003b2c:	6402                	ld	s0,0(sp)
    80003b2e:	0141                	addi	sp,sp,16
    80003b30:	8082                	ret

0000000080003b32 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b32:	7139                	addi	sp,sp,-64
    80003b34:	fc06                	sd	ra,56(sp)
    80003b36:	f822                	sd	s0,48(sp)
    80003b38:	f426                	sd	s1,40(sp)
    80003b3a:	f04a                	sd	s2,32(sp)
    80003b3c:	ec4e                	sd	s3,24(sp)
    80003b3e:	e852                	sd	s4,16(sp)
    80003b40:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b42:	04451703          	lh	a4,68(a0)
    80003b46:	4785                	li	a5,1
    80003b48:	00f71a63          	bne	a4,a5,80003b5c <dirlookup+0x2a>
    80003b4c:	892a                	mv	s2,a0
    80003b4e:	89ae                	mv	s3,a1
    80003b50:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b52:	457c                	lw	a5,76(a0)
    80003b54:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b56:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b58:	e79d                	bnez	a5,80003b86 <dirlookup+0x54>
    80003b5a:	a8a5                	j	80003bd2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b5c:	00005517          	auipc	a0,0x5
    80003b60:	b5450513          	addi	a0,a0,-1196 # 800086b0 <syscalls+0x1a0>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	9da080e7          	jalr	-1574(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b6c:	00005517          	auipc	a0,0x5
    80003b70:	b5c50513          	addi	a0,a0,-1188 # 800086c8 <syscalls+0x1b8>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	9ca080e7          	jalr	-1590(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b7c:	24c1                	addiw	s1,s1,16
    80003b7e:	04c92783          	lw	a5,76(s2)
    80003b82:	04f4f763          	bgeu	s1,a5,80003bd0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b86:	4741                	li	a4,16
    80003b88:	86a6                	mv	a3,s1
    80003b8a:	fc040613          	addi	a2,s0,-64
    80003b8e:	4581                	li	a1,0
    80003b90:	854a                	mv	a0,s2
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	d70080e7          	jalr	-656(ra) # 80003902 <readi>
    80003b9a:	47c1                	li	a5,16
    80003b9c:	fcf518e3          	bne	a0,a5,80003b6c <dirlookup+0x3a>
    if(de.inum == 0)
    80003ba0:	fc045783          	lhu	a5,-64(s0)
    80003ba4:	dfe1                	beqz	a5,80003b7c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ba6:	fc240593          	addi	a1,s0,-62
    80003baa:	854e                	mv	a0,s3
    80003bac:	00000097          	auipc	ra,0x0
    80003bb0:	f6c080e7          	jalr	-148(ra) # 80003b18 <namecmp>
    80003bb4:	f561                	bnez	a0,80003b7c <dirlookup+0x4a>
      if(poff)
    80003bb6:	000a0463          	beqz	s4,80003bbe <dirlookup+0x8c>
        *poff = off;
    80003bba:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bbe:	fc045583          	lhu	a1,-64(s0)
    80003bc2:	00092503          	lw	a0,0(s2)
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	754080e7          	jalr	1876(ra) # 8000331a <iget>
    80003bce:	a011                	j	80003bd2 <dirlookup+0xa0>
  return 0;
    80003bd0:	4501                	li	a0,0
}
    80003bd2:	70e2                	ld	ra,56(sp)
    80003bd4:	7442                	ld	s0,48(sp)
    80003bd6:	74a2                	ld	s1,40(sp)
    80003bd8:	7902                	ld	s2,32(sp)
    80003bda:	69e2                	ld	s3,24(sp)
    80003bdc:	6a42                	ld	s4,16(sp)
    80003bde:	6121                	addi	sp,sp,64
    80003be0:	8082                	ret

0000000080003be2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003be2:	711d                	addi	sp,sp,-96
    80003be4:	ec86                	sd	ra,88(sp)
    80003be6:	e8a2                	sd	s0,80(sp)
    80003be8:	e4a6                	sd	s1,72(sp)
    80003bea:	e0ca                	sd	s2,64(sp)
    80003bec:	fc4e                	sd	s3,56(sp)
    80003bee:	f852                	sd	s4,48(sp)
    80003bf0:	f456                	sd	s5,40(sp)
    80003bf2:	f05a                	sd	s6,32(sp)
    80003bf4:	ec5e                	sd	s7,24(sp)
    80003bf6:	e862                	sd	s8,16(sp)
    80003bf8:	e466                	sd	s9,8(sp)
    80003bfa:	1080                	addi	s0,sp,96
    80003bfc:	84aa                	mv	s1,a0
    80003bfe:	8b2e                	mv	s6,a1
    80003c00:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c02:	00054703          	lbu	a4,0(a0)
    80003c06:	02f00793          	li	a5,47
    80003c0a:	02f70363          	beq	a4,a5,80003c30 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c0e:	ffffe097          	auipc	ra,0xffffe
    80003c12:	e22080e7          	jalr	-478(ra) # 80001a30 <myproc>
    80003c16:	15053503          	ld	a0,336(a0)
    80003c1a:	00000097          	auipc	ra,0x0
    80003c1e:	9f6080e7          	jalr	-1546(ra) # 80003610 <idup>
    80003c22:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c24:	02f00913          	li	s2,47
  len = path - s;
    80003c28:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c2a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c2c:	4c05                	li	s8,1
    80003c2e:	a865                	j	80003ce6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c30:	4585                	li	a1,1
    80003c32:	4505                	li	a0,1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	6e6080e7          	jalr	1766(ra) # 8000331a <iget>
    80003c3c:	89aa                	mv	s3,a0
    80003c3e:	b7dd                	j	80003c24 <namex+0x42>
      iunlockput(ip);
    80003c40:	854e                	mv	a0,s3
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	c6e080e7          	jalr	-914(ra) # 800038b0 <iunlockput>
      return 0;
    80003c4a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c4c:	854e                	mv	a0,s3
    80003c4e:	60e6                	ld	ra,88(sp)
    80003c50:	6446                	ld	s0,80(sp)
    80003c52:	64a6                	ld	s1,72(sp)
    80003c54:	6906                	ld	s2,64(sp)
    80003c56:	79e2                	ld	s3,56(sp)
    80003c58:	7a42                	ld	s4,48(sp)
    80003c5a:	7aa2                	ld	s5,40(sp)
    80003c5c:	7b02                	ld	s6,32(sp)
    80003c5e:	6be2                	ld	s7,24(sp)
    80003c60:	6c42                	ld	s8,16(sp)
    80003c62:	6ca2                	ld	s9,8(sp)
    80003c64:	6125                	addi	sp,sp,96
    80003c66:	8082                	ret
      iunlock(ip);
    80003c68:	854e                	mv	a0,s3
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	aa6080e7          	jalr	-1370(ra) # 80003710 <iunlock>
      return ip;
    80003c72:	bfe9                	j	80003c4c <namex+0x6a>
      iunlockput(ip);
    80003c74:	854e                	mv	a0,s3
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	c3a080e7          	jalr	-966(ra) # 800038b0 <iunlockput>
      return 0;
    80003c7e:	89d2                	mv	s3,s4
    80003c80:	b7f1                	j	80003c4c <namex+0x6a>
  len = path - s;
    80003c82:	40b48633          	sub	a2,s1,a1
    80003c86:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c8a:	094cd463          	bge	s9,s4,80003d12 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c8e:	4639                	li	a2,14
    80003c90:	8556                	mv	a0,s5
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	0ae080e7          	jalr	174(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c9a:	0004c783          	lbu	a5,0(s1)
    80003c9e:	01279763          	bne	a5,s2,80003cac <namex+0xca>
    path++;
    80003ca2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ca4:	0004c783          	lbu	a5,0(s1)
    80003ca8:	ff278de3          	beq	a5,s2,80003ca2 <namex+0xc0>
    ilock(ip);
    80003cac:	854e                	mv	a0,s3
    80003cae:	00000097          	auipc	ra,0x0
    80003cb2:	9a0080e7          	jalr	-1632(ra) # 8000364e <ilock>
    if(ip->type != T_DIR){
    80003cb6:	04499783          	lh	a5,68(s3)
    80003cba:	f98793e3          	bne	a5,s8,80003c40 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cbe:	000b0563          	beqz	s6,80003cc8 <namex+0xe6>
    80003cc2:	0004c783          	lbu	a5,0(s1)
    80003cc6:	d3cd                	beqz	a5,80003c68 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cc8:	865e                	mv	a2,s7
    80003cca:	85d6                	mv	a1,s5
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	e64080e7          	jalr	-412(ra) # 80003b32 <dirlookup>
    80003cd6:	8a2a                	mv	s4,a0
    80003cd8:	dd51                	beqz	a0,80003c74 <namex+0x92>
    iunlockput(ip);
    80003cda:	854e                	mv	a0,s3
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	bd4080e7          	jalr	-1068(ra) # 800038b0 <iunlockput>
    ip = next;
    80003ce4:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ce6:	0004c783          	lbu	a5,0(s1)
    80003cea:	05279763          	bne	a5,s2,80003d38 <namex+0x156>
    path++;
    80003cee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cf0:	0004c783          	lbu	a5,0(s1)
    80003cf4:	ff278de3          	beq	a5,s2,80003cee <namex+0x10c>
  if(*path == 0)
    80003cf8:	c79d                	beqz	a5,80003d26 <namex+0x144>
    path++;
    80003cfa:	85a6                	mv	a1,s1
  len = path - s;
    80003cfc:	8a5e                	mv	s4,s7
    80003cfe:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d00:	01278963          	beq	a5,s2,80003d12 <namex+0x130>
    80003d04:	dfbd                	beqz	a5,80003c82 <namex+0xa0>
    path++;
    80003d06:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	ff279ce3          	bne	a5,s2,80003d04 <namex+0x122>
    80003d10:	bf8d                	j	80003c82 <namex+0xa0>
    memmove(name, s, len);
    80003d12:	2601                	sext.w	a2,a2
    80003d14:	8556                	mv	a0,s5
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	02a080e7          	jalr	42(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003d1e:	9a56                	add	s4,s4,s5
    80003d20:	000a0023          	sb	zero,0(s4)
    80003d24:	bf9d                	j	80003c9a <namex+0xb8>
  if(nameiparent){
    80003d26:	f20b03e3          	beqz	s6,80003c4c <namex+0x6a>
    iput(ip);
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	adc080e7          	jalr	-1316(ra) # 80003808 <iput>
    return 0;
    80003d34:	4981                	li	s3,0
    80003d36:	bf19                	j	80003c4c <namex+0x6a>
  if(*path == 0)
    80003d38:	d7fd                	beqz	a5,80003d26 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	85a6                	mv	a1,s1
    80003d40:	b7d1                	j	80003d04 <namex+0x122>

0000000080003d42 <dirlink>:
{
    80003d42:	7139                	addi	sp,sp,-64
    80003d44:	fc06                	sd	ra,56(sp)
    80003d46:	f822                	sd	s0,48(sp)
    80003d48:	f426                	sd	s1,40(sp)
    80003d4a:	f04a                	sd	s2,32(sp)
    80003d4c:	ec4e                	sd	s3,24(sp)
    80003d4e:	e852                	sd	s4,16(sp)
    80003d50:	0080                	addi	s0,sp,64
    80003d52:	892a                	mv	s2,a0
    80003d54:	8a2e                	mv	s4,a1
    80003d56:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d58:	4601                	li	a2,0
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	dd8080e7          	jalr	-552(ra) # 80003b32 <dirlookup>
    80003d62:	e93d                	bnez	a0,80003dd8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d64:	04c92483          	lw	s1,76(s2)
    80003d68:	c49d                	beqz	s1,80003d96 <dirlink+0x54>
    80003d6a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6c:	4741                	li	a4,16
    80003d6e:	86a6                	mv	a3,s1
    80003d70:	fc040613          	addi	a2,s0,-64
    80003d74:	4581                	li	a1,0
    80003d76:	854a                	mv	a0,s2
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	b8a080e7          	jalr	-1142(ra) # 80003902 <readi>
    80003d80:	47c1                	li	a5,16
    80003d82:	06f51163          	bne	a0,a5,80003de4 <dirlink+0xa2>
    if(de.inum == 0)
    80003d86:	fc045783          	lhu	a5,-64(s0)
    80003d8a:	c791                	beqz	a5,80003d96 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8c:	24c1                	addiw	s1,s1,16
    80003d8e:	04c92783          	lw	a5,76(s2)
    80003d92:	fcf4ede3          	bltu	s1,a5,80003d6c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d96:	4639                	li	a2,14
    80003d98:	85d2                	mv	a1,s4
    80003d9a:	fc240513          	addi	a0,s0,-62
    80003d9e:	ffffd097          	auipc	ra,0xffffd
    80003da2:	056080e7          	jalr	86(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003da6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003daa:	4741                	li	a4,16
    80003dac:	86a6                	mv	a3,s1
    80003dae:	fc040613          	addi	a2,s0,-64
    80003db2:	4581                	li	a1,0
    80003db4:	854a                	mv	a0,s2
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	c44080e7          	jalr	-956(ra) # 800039fa <writei>
    80003dbe:	872a                	mv	a4,a0
    80003dc0:	47c1                	li	a5,16
  return 0;
    80003dc2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc4:	02f71863          	bne	a4,a5,80003df4 <dirlink+0xb2>
}
    80003dc8:	70e2                	ld	ra,56(sp)
    80003dca:	7442                	ld	s0,48(sp)
    80003dcc:	74a2                	ld	s1,40(sp)
    80003dce:	7902                	ld	s2,32(sp)
    80003dd0:	69e2                	ld	s3,24(sp)
    80003dd2:	6a42                	ld	s4,16(sp)
    80003dd4:	6121                	addi	sp,sp,64
    80003dd6:	8082                	ret
    iput(ip);
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	a30080e7          	jalr	-1488(ra) # 80003808 <iput>
    return -1;
    80003de0:	557d                	li	a0,-1
    80003de2:	b7dd                	j	80003dc8 <dirlink+0x86>
      panic("dirlink read");
    80003de4:	00005517          	auipc	a0,0x5
    80003de8:	8f450513          	addi	a0,a0,-1804 # 800086d8 <syscalls+0x1c8>
    80003dec:	ffffc097          	auipc	ra,0xffffc
    80003df0:	752080e7          	jalr	1874(ra) # 8000053e <panic>
    panic("dirlink");
    80003df4:	00005517          	auipc	a0,0x5
    80003df8:	9f450513          	addi	a0,a0,-1548 # 800087e8 <syscalls+0x2d8>
    80003dfc:	ffffc097          	auipc	ra,0xffffc
    80003e00:	742080e7          	jalr	1858(ra) # 8000053e <panic>

0000000080003e04 <namei>:

struct inode*
namei(char *path)
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e0c:	fe040613          	addi	a2,s0,-32
    80003e10:	4581                	li	a1,0
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	dd0080e7          	jalr	-560(ra) # 80003be2 <namex>
}
    80003e1a:	60e2                	ld	ra,24(sp)
    80003e1c:	6442                	ld	s0,16(sp)
    80003e1e:	6105                	addi	sp,sp,32
    80003e20:	8082                	ret

0000000080003e22 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e22:	1141                	addi	sp,sp,-16
    80003e24:	e406                	sd	ra,8(sp)
    80003e26:	e022                	sd	s0,0(sp)
    80003e28:	0800                	addi	s0,sp,16
    80003e2a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e2c:	4585                	li	a1,1
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	db4080e7          	jalr	-588(ra) # 80003be2 <namex>
}
    80003e36:	60a2                	ld	ra,8(sp)
    80003e38:	6402                	ld	s0,0(sp)
    80003e3a:	0141                	addi	sp,sp,16
    80003e3c:	8082                	ret

0000000080003e3e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e3e:	1101                	addi	sp,sp,-32
    80003e40:	ec06                	sd	ra,24(sp)
    80003e42:	e822                	sd	s0,16(sp)
    80003e44:	e426                	sd	s1,8(sp)
    80003e46:	e04a                	sd	s2,0(sp)
    80003e48:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e4a:	00020917          	auipc	s2,0x20
    80003e4e:	42690913          	addi	s2,s2,1062 # 80024270 <log>
    80003e52:	01892583          	lw	a1,24(s2)
    80003e56:	02892503          	lw	a0,40(s2)
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	ff2080e7          	jalr	-14(ra) # 80002e4c <bread>
    80003e62:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e64:	02c92683          	lw	a3,44(s2)
    80003e68:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e6a:	02d05763          	blez	a3,80003e98 <write_head+0x5a>
    80003e6e:	00020797          	auipc	a5,0x20
    80003e72:	43278793          	addi	a5,a5,1074 # 800242a0 <log+0x30>
    80003e76:	05c50713          	addi	a4,a0,92
    80003e7a:	36fd                	addiw	a3,a3,-1
    80003e7c:	1682                	slli	a3,a3,0x20
    80003e7e:	9281                	srli	a3,a3,0x20
    80003e80:	068a                	slli	a3,a3,0x2
    80003e82:	00020617          	auipc	a2,0x20
    80003e86:	42260613          	addi	a2,a2,1058 # 800242a4 <log+0x34>
    80003e8a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e8c:	4390                	lw	a2,0(a5)
    80003e8e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e90:	0791                	addi	a5,a5,4
    80003e92:	0711                	addi	a4,a4,4
    80003e94:	fed79ce3          	bne	a5,a3,80003e8c <write_head+0x4e>
  }
  bwrite(buf);
    80003e98:	8526                	mv	a0,s1
    80003e9a:	fffff097          	auipc	ra,0xfffff
    80003e9e:	0a4080e7          	jalr	164(ra) # 80002f3e <bwrite>
  brelse(buf);
    80003ea2:	8526                	mv	a0,s1
    80003ea4:	fffff097          	auipc	ra,0xfffff
    80003ea8:	0d8080e7          	jalr	216(ra) # 80002f7c <brelse>
}
    80003eac:	60e2                	ld	ra,24(sp)
    80003eae:	6442                	ld	s0,16(sp)
    80003eb0:	64a2                	ld	s1,8(sp)
    80003eb2:	6902                	ld	s2,0(sp)
    80003eb4:	6105                	addi	sp,sp,32
    80003eb6:	8082                	ret

0000000080003eb8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb8:	00020797          	auipc	a5,0x20
    80003ebc:	3e47a783          	lw	a5,996(a5) # 8002429c <log+0x2c>
    80003ec0:	0af05d63          	blez	a5,80003f7a <install_trans+0xc2>
{
    80003ec4:	7139                	addi	sp,sp,-64
    80003ec6:	fc06                	sd	ra,56(sp)
    80003ec8:	f822                	sd	s0,48(sp)
    80003eca:	f426                	sd	s1,40(sp)
    80003ecc:	f04a                	sd	s2,32(sp)
    80003ece:	ec4e                	sd	s3,24(sp)
    80003ed0:	e852                	sd	s4,16(sp)
    80003ed2:	e456                	sd	s5,8(sp)
    80003ed4:	e05a                	sd	s6,0(sp)
    80003ed6:	0080                	addi	s0,sp,64
    80003ed8:	8b2a                	mv	s6,a0
    80003eda:	00020a97          	auipc	s5,0x20
    80003ede:	3c6a8a93          	addi	s5,s5,966 # 800242a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ee2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ee4:	00020997          	auipc	s3,0x20
    80003ee8:	38c98993          	addi	s3,s3,908 # 80024270 <log>
    80003eec:	a035                	j	80003f18 <install_trans+0x60>
      bunpin(dbuf);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	fffff097          	auipc	ra,0xfffff
    80003ef4:	166080e7          	jalr	358(ra) # 80003056 <bunpin>
    brelse(lbuf);
    80003ef8:	854a                	mv	a0,s2
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	082080e7          	jalr	130(ra) # 80002f7c <brelse>
    brelse(dbuf);
    80003f02:	8526                	mv	a0,s1
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	078080e7          	jalr	120(ra) # 80002f7c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f0c:	2a05                	addiw	s4,s4,1
    80003f0e:	0a91                	addi	s5,s5,4
    80003f10:	02c9a783          	lw	a5,44(s3)
    80003f14:	04fa5963          	bge	s4,a5,80003f66 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f18:	0189a583          	lw	a1,24(s3)
    80003f1c:	014585bb          	addw	a1,a1,s4
    80003f20:	2585                	addiw	a1,a1,1
    80003f22:	0289a503          	lw	a0,40(s3)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	f26080e7          	jalr	-218(ra) # 80002e4c <bread>
    80003f2e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f30:	000aa583          	lw	a1,0(s5)
    80003f34:	0289a503          	lw	a0,40(s3)
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	f14080e7          	jalr	-236(ra) # 80002e4c <bread>
    80003f40:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f42:	40000613          	li	a2,1024
    80003f46:	05890593          	addi	a1,s2,88
    80003f4a:	05850513          	addi	a0,a0,88
    80003f4e:	ffffd097          	auipc	ra,0xffffd
    80003f52:	df2080e7          	jalr	-526(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f56:	8526                	mv	a0,s1
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	fe6080e7          	jalr	-26(ra) # 80002f3e <bwrite>
    if(recovering == 0)
    80003f60:	f80b1ce3          	bnez	s6,80003ef8 <install_trans+0x40>
    80003f64:	b769                	j	80003eee <install_trans+0x36>
}
    80003f66:	70e2                	ld	ra,56(sp)
    80003f68:	7442                	ld	s0,48(sp)
    80003f6a:	74a2                	ld	s1,40(sp)
    80003f6c:	7902                	ld	s2,32(sp)
    80003f6e:	69e2                	ld	s3,24(sp)
    80003f70:	6a42                	ld	s4,16(sp)
    80003f72:	6aa2                	ld	s5,8(sp)
    80003f74:	6b02                	ld	s6,0(sp)
    80003f76:	6121                	addi	sp,sp,64
    80003f78:	8082                	ret
    80003f7a:	8082                	ret

0000000080003f7c <initlog>:
{
    80003f7c:	7179                	addi	sp,sp,-48
    80003f7e:	f406                	sd	ra,40(sp)
    80003f80:	f022                	sd	s0,32(sp)
    80003f82:	ec26                	sd	s1,24(sp)
    80003f84:	e84a                	sd	s2,16(sp)
    80003f86:	e44e                	sd	s3,8(sp)
    80003f88:	1800                	addi	s0,sp,48
    80003f8a:	892a                	mv	s2,a0
    80003f8c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f8e:	00020497          	auipc	s1,0x20
    80003f92:	2e248493          	addi	s1,s1,738 # 80024270 <log>
    80003f96:	00004597          	auipc	a1,0x4
    80003f9a:	75258593          	addi	a1,a1,1874 # 800086e8 <syscalls+0x1d8>
    80003f9e:	8526                	mv	a0,s1
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	bb4080e7          	jalr	-1100(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003fa8:	0149a583          	lw	a1,20(s3)
    80003fac:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fae:	0109a783          	lw	a5,16(s3)
    80003fb2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fb4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fb8:	854a                	mv	a0,s2
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	e92080e7          	jalr	-366(ra) # 80002e4c <bread>
  log.lh.n = lh->n;
    80003fc2:	4d3c                	lw	a5,88(a0)
    80003fc4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fc6:	02f05563          	blez	a5,80003ff0 <initlog+0x74>
    80003fca:	05c50713          	addi	a4,a0,92
    80003fce:	00020697          	auipc	a3,0x20
    80003fd2:	2d268693          	addi	a3,a3,722 # 800242a0 <log+0x30>
    80003fd6:	37fd                	addiw	a5,a5,-1
    80003fd8:	1782                	slli	a5,a5,0x20
    80003fda:	9381                	srli	a5,a5,0x20
    80003fdc:	078a                	slli	a5,a5,0x2
    80003fde:	06050613          	addi	a2,a0,96
    80003fe2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fe4:	4310                	lw	a2,0(a4)
    80003fe6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003fe8:	0711                	addi	a4,a4,4
    80003fea:	0691                	addi	a3,a3,4
    80003fec:	fef71ce3          	bne	a4,a5,80003fe4 <initlog+0x68>
  brelse(buf);
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	f8c080e7          	jalr	-116(ra) # 80002f7c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003ff8:	4505                	li	a0,1
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	ebe080e7          	jalr	-322(ra) # 80003eb8 <install_trans>
  log.lh.n = 0;
    80004002:	00020797          	auipc	a5,0x20
    80004006:	2807ad23          	sw	zero,666(a5) # 8002429c <log+0x2c>
  write_head(); // clear the log
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	e34080e7          	jalr	-460(ra) # 80003e3e <write_head>
}
    80004012:	70a2                	ld	ra,40(sp)
    80004014:	7402                	ld	s0,32(sp)
    80004016:	64e2                	ld	s1,24(sp)
    80004018:	6942                	ld	s2,16(sp)
    8000401a:	69a2                	ld	s3,8(sp)
    8000401c:	6145                	addi	sp,sp,48
    8000401e:	8082                	ret

0000000080004020 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	e04a                	sd	s2,0(sp)
    8000402a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000402c:	00020517          	auipc	a0,0x20
    80004030:	24450513          	addi	a0,a0,580 # 80024270 <log>
    80004034:	ffffd097          	auipc	ra,0xffffd
    80004038:	bb0080e7          	jalr	-1104(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000403c:	00020497          	auipc	s1,0x20
    80004040:	23448493          	addi	s1,s1,564 # 80024270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004044:	4979                	li	s2,30
    80004046:	a039                	j	80004054 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004048:	85a6                	mv	a1,s1
    8000404a:	8526                	mv	a0,s1
    8000404c:	ffffe097          	auipc	ra,0xffffe
    80004050:	0a0080e7          	jalr	160(ra) # 800020ec <sleep>
    if(log.committing){
    80004054:	50dc                	lw	a5,36(s1)
    80004056:	fbed                	bnez	a5,80004048 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004058:	509c                	lw	a5,32(s1)
    8000405a:	0017871b          	addiw	a4,a5,1
    8000405e:	0007069b          	sext.w	a3,a4
    80004062:	0027179b          	slliw	a5,a4,0x2
    80004066:	9fb9                	addw	a5,a5,a4
    80004068:	0017979b          	slliw	a5,a5,0x1
    8000406c:	54d8                	lw	a4,44(s1)
    8000406e:	9fb9                	addw	a5,a5,a4
    80004070:	00f95963          	bge	s2,a5,80004082 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004074:	85a6                	mv	a1,s1
    80004076:	8526                	mv	a0,s1
    80004078:	ffffe097          	auipc	ra,0xffffe
    8000407c:	074080e7          	jalr	116(ra) # 800020ec <sleep>
    80004080:	bfd1                	j	80004054 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004082:	00020517          	auipc	a0,0x20
    80004086:	1ee50513          	addi	a0,a0,494 # 80024270 <log>
    8000408a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	c0c080e7          	jalr	-1012(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004094:	60e2                	ld	ra,24(sp)
    80004096:	6442                	ld	s0,16(sp)
    80004098:	64a2                	ld	s1,8(sp)
    8000409a:	6902                	ld	s2,0(sp)
    8000409c:	6105                	addi	sp,sp,32
    8000409e:	8082                	ret

00000000800040a0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040a0:	7139                	addi	sp,sp,-64
    800040a2:	fc06                	sd	ra,56(sp)
    800040a4:	f822                	sd	s0,48(sp)
    800040a6:	f426                	sd	s1,40(sp)
    800040a8:	f04a                	sd	s2,32(sp)
    800040aa:	ec4e                	sd	s3,24(sp)
    800040ac:	e852                	sd	s4,16(sp)
    800040ae:	e456                	sd	s5,8(sp)
    800040b0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040b2:	00020497          	auipc	s1,0x20
    800040b6:	1be48493          	addi	s1,s1,446 # 80024270 <log>
    800040ba:	8526                	mv	a0,s1
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	b28080e7          	jalr	-1240(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800040c4:	509c                	lw	a5,32(s1)
    800040c6:	37fd                	addiw	a5,a5,-1
    800040c8:	0007891b          	sext.w	s2,a5
    800040cc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040ce:	50dc                	lw	a5,36(s1)
    800040d0:	efb9                	bnez	a5,8000412e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040d2:	06091663          	bnez	s2,8000413e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040d6:	00020497          	auipc	s1,0x20
    800040da:	19a48493          	addi	s1,s1,410 # 80024270 <log>
    800040de:	4785                	li	a5,1
    800040e0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffd097          	auipc	ra,0xffffd
    800040e8:	bb4080e7          	jalr	-1100(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040ec:	54dc                	lw	a5,44(s1)
    800040ee:	06f04763          	bgtz	a5,8000415c <end_op+0xbc>
    acquire(&log.lock);
    800040f2:	00020497          	auipc	s1,0x20
    800040f6:	17e48493          	addi	s1,s1,382 # 80024270 <log>
    800040fa:	8526                	mv	a0,s1
    800040fc:	ffffd097          	auipc	ra,0xffffd
    80004100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004104:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	16e080e7          	jalr	366(ra) # 80002278 <wakeup>
    release(&log.lock);
    80004112:	8526                	mv	a0,s1
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	b84080e7          	jalr	-1148(ra) # 80000c98 <release>
}
    8000411c:	70e2                	ld	ra,56(sp)
    8000411e:	7442                	ld	s0,48(sp)
    80004120:	74a2                	ld	s1,40(sp)
    80004122:	7902                	ld	s2,32(sp)
    80004124:	69e2                	ld	s3,24(sp)
    80004126:	6a42                	ld	s4,16(sp)
    80004128:	6aa2                	ld	s5,8(sp)
    8000412a:	6121                	addi	sp,sp,64
    8000412c:	8082                	ret
    panic("log.committing");
    8000412e:	00004517          	auipc	a0,0x4
    80004132:	5c250513          	addi	a0,a0,1474 # 800086f0 <syscalls+0x1e0>
    80004136:	ffffc097          	auipc	ra,0xffffc
    8000413a:	408080e7          	jalr	1032(ra) # 8000053e <panic>
    wakeup(&log);
    8000413e:	00020497          	auipc	s1,0x20
    80004142:	13248493          	addi	s1,s1,306 # 80024270 <log>
    80004146:	8526                	mv	a0,s1
    80004148:	ffffe097          	auipc	ra,0xffffe
    8000414c:	130080e7          	jalr	304(ra) # 80002278 <wakeup>
  release(&log.lock);
    80004150:	8526                	mv	a0,s1
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	b46080e7          	jalr	-1210(ra) # 80000c98 <release>
  if(do_commit){
    8000415a:	b7c9                	j	8000411c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415c:	00020a97          	auipc	s5,0x20
    80004160:	144a8a93          	addi	s5,s5,324 # 800242a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004164:	00020a17          	auipc	s4,0x20
    80004168:	10ca0a13          	addi	s4,s4,268 # 80024270 <log>
    8000416c:	018a2583          	lw	a1,24(s4)
    80004170:	012585bb          	addw	a1,a1,s2
    80004174:	2585                	addiw	a1,a1,1
    80004176:	028a2503          	lw	a0,40(s4)
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	cd2080e7          	jalr	-814(ra) # 80002e4c <bread>
    80004182:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004184:	000aa583          	lw	a1,0(s5)
    80004188:	028a2503          	lw	a0,40(s4)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	cc0080e7          	jalr	-832(ra) # 80002e4c <bread>
    80004194:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004196:	40000613          	li	a2,1024
    8000419a:	05850593          	addi	a1,a0,88
    8000419e:	05848513          	addi	a0,s1,88
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	b9e080e7          	jalr	-1122(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800041aa:	8526                	mv	a0,s1
    800041ac:	fffff097          	auipc	ra,0xfffff
    800041b0:	d92080e7          	jalr	-622(ra) # 80002f3e <bwrite>
    brelse(from);
    800041b4:	854e                	mv	a0,s3
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	dc6080e7          	jalr	-570(ra) # 80002f7c <brelse>
    brelse(to);
    800041be:	8526                	mv	a0,s1
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	dbc080e7          	jalr	-580(ra) # 80002f7c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c8:	2905                	addiw	s2,s2,1
    800041ca:	0a91                	addi	s5,s5,4
    800041cc:	02ca2783          	lw	a5,44(s4)
    800041d0:	f8f94ee3          	blt	s2,a5,8000416c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	c6a080e7          	jalr	-918(ra) # 80003e3e <write_head>
    install_trans(0); // Now install writes to home locations
    800041dc:	4501                	li	a0,0
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	cda080e7          	jalr	-806(ra) # 80003eb8 <install_trans>
    log.lh.n = 0;
    800041e6:	00020797          	auipc	a5,0x20
    800041ea:	0a07ab23          	sw	zero,182(a5) # 8002429c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041ee:	00000097          	auipc	ra,0x0
    800041f2:	c50080e7          	jalr	-944(ra) # 80003e3e <write_head>
    800041f6:	bdf5                	j	800040f2 <end_op+0x52>

00000000800041f8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041f8:	1101                	addi	sp,sp,-32
    800041fa:	ec06                	sd	ra,24(sp)
    800041fc:	e822                	sd	s0,16(sp)
    800041fe:	e426                	sd	s1,8(sp)
    80004200:	e04a                	sd	s2,0(sp)
    80004202:	1000                	addi	s0,sp,32
    80004204:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004206:	00020917          	auipc	s2,0x20
    8000420a:	06a90913          	addi	s2,s2,106 # 80024270 <log>
    8000420e:	854a                	mv	a0,s2
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	9d4080e7          	jalr	-1580(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004218:	02c92603          	lw	a2,44(s2)
    8000421c:	47f5                	li	a5,29
    8000421e:	06c7c563          	blt	a5,a2,80004288 <log_write+0x90>
    80004222:	00020797          	auipc	a5,0x20
    80004226:	06a7a783          	lw	a5,106(a5) # 8002428c <log+0x1c>
    8000422a:	37fd                	addiw	a5,a5,-1
    8000422c:	04f65e63          	bge	a2,a5,80004288 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004230:	00020797          	auipc	a5,0x20
    80004234:	0607a783          	lw	a5,96(a5) # 80024290 <log+0x20>
    80004238:	06f05063          	blez	a5,80004298 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000423c:	4781                	li	a5,0
    8000423e:	06c05563          	blez	a2,800042a8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004242:	44cc                	lw	a1,12(s1)
    80004244:	00020717          	auipc	a4,0x20
    80004248:	05c70713          	addi	a4,a4,92 # 800242a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000424c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000424e:	4314                	lw	a3,0(a4)
    80004250:	04b68c63          	beq	a3,a1,800042a8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004254:	2785                	addiw	a5,a5,1
    80004256:	0711                	addi	a4,a4,4
    80004258:	fef61be3          	bne	a2,a5,8000424e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000425c:	0621                	addi	a2,a2,8
    8000425e:	060a                	slli	a2,a2,0x2
    80004260:	00020797          	auipc	a5,0x20
    80004264:	01078793          	addi	a5,a5,16 # 80024270 <log>
    80004268:	963e                	add	a2,a2,a5
    8000426a:	44dc                	lw	a5,12(s1)
    8000426c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	daa080e7          	jalr	-598(ra) # 8000301a <bpin>
    log.lh.n++;
    80004278:	00020717          	auipc	a4,0x20
    8000427c:	ff870713          	addi	a4,a4,-8 # 80024270 <log>
    80004280:	575c                	lw	a5,44(a4)
    80004282:	2785                	addiw	a5,a5,1
    80004284:	d75c                	sw	a5,44(a4)
    80004286:	a835                	j	800042c2 <log_write+0xca>
    panic("too big a transaction");
    80004288:	00004517          	auipc	a0,0x4
    8000428c:	47850513          	addi	a0,a0,1144 # 80008700 <syscalls+0x1f0>
    80004290:	ffffc097          	auipc	ra,0xffffc
    80004294:	2ae080e7          	jalr	686(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004298:	00004517          	auipc	a0,0x4
    8000429c:	48050513          	addi	a0,a0,1152 # 80008718 <syscalls+0x208>
    800042a0:	ffffc097          	auipc	ra,0xffffc
    800042a4:	29e080e7          	jalr	670(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800042a8:	00878713          	addi	a4,a5,8
    800042ac:	00271693          	slli	a3,a4,0x2
    800042b0:	00020717          	auipc	a4,0x20
    800042b4:	fc070713          	addi	a4,a4,-64 # 80024270 <log>
    800042b8:	9736                	add	a4,a4,a3
    800042ba:	44d4                	lw	a3,12(s1)
    800042bc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042be:	faf608e3          	beq	a2,a5,8000426e <log_write+0x76>
  }
  release(&log.lock);
    800042c2:	00020517          	auipc	a0,0x20
    800042c6:	fae50513          	addi	a0,a0,-82 # 80024270 <log>
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	9ce080e7          	jalr	-1586(ra) # 80000c98 <release>
}
    800042d2:	60e2                	ld	ra,24(sp)
    800042d4:	6442                	ld	s0,16(sp)
    800042d6:	64a2                	ld	s1,8(sp)
    800042d8:	6902                	ld	s2,0(sp)
    800042da:	6105                	addi	sp,sp,32
    800042dc:	8082                	ret

00000000800042de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042de:	1101                	addi	sp,sp,-32
    800042e0:	ec06                	sd	ra,24(sp)
    800042e2:	e822                	sd	s0,16(sp)
    800042e4:	e426                	sd	s1,8(sp)
    800042e6:	e04a                	sd	s2,0(sp)
    800042e8:	1000                	addi	s0,sp,32
    800042ea:	84aa                	mv	s1,a0
    800042ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042ee:	00004597          	auipc	a1,0x4
    800042f2:	44a58593          	addi	a1,a1,1098 # 80008738 <syscalls+0x228>
    800042f6:	0521                	addi	a0,a0,8
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	85c080e7          	jalr	-1956(ra) # 80000b54 <initlock>
  lk->name = name;
    80004300:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004304:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004308:	0204a423          	sw	zero,40(s1)
}
    8000430c:	60e2                	ld	ra,24(sp)
    8000430e:	6442                	ld	s0,16(sp)
    80004310:	64a2                	ld	s1,8(sp)
    80004312:	6902                	ld	s2,0(sp)
    80004314:	6105                	addi	sp,sp,32
    80004316:	8082                	ret

0000000080004318 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004318:	1101                	addi	sp,sp,-32
    8000431a:	ec06                	sd	ra,24(sp)
    8000431c:	e822                	sd	s0,16(sp)
    8000431e:	e426                	sd	s1,8(sp)
    80004320:	e04a                	sd	s2,0(sp)
    80004322:	1000                	addi	s0,sp,32
    80004324:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004326:	00850913          	addi	s2,a0,8
    8000432a:	854a                	mv	a0,s2
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	8b8080e7          	jalr	-1864(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004334:	409c                	lw	a5,0(s1)
    80004336:	cb89                	beqz	a5,80004348 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004338:	85ca                	mv	a1,s2
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffe097          	auipc	ra,0xffffe
    80004340:	db0080e7          	jalr	-592(ra) # 800020ec <sleep>
  while (lk->locked) {
    80004344:	409c                	lw	a5,0(s1)
    80004346:	fbed                	bnez	a5,80004338 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004348:	4785                	li	a5,1
    8000434a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	6e4080e7          	jalr	1764(ra) # 80001a30 <myproc>
    80004354:	591c                	lw	a5,48(a0)
    80004356:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004358:	854a                	mv	a0,s2
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	93e080e7          	jalr	-1730(ra) # 80000c98 <release>
}
    80004362:	60e2                	ld	ra,24(sp)
    80004364:	6442                	ld	s0,16(sp)
    80004366:	64a2                	ld	s1,8(sp)
    80004368:	6902                	ld	s2,0(sp)
    8000436a:	6105                	addi	sp,sp,32
    8000436c:	8082                	ret

000000008000436e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000436e:	1101                	addi	sp,sp,-32
    80004370:	ec06                	sd	ra,24(sp)
    80004372:	e822                	sd	s0,16(sp)
    80004374:	e426                	sd	s1,8(sp)
    80004376:	e04a                	sd	s2,0(sp)
    80004378:	1000                	addi	s0,sp,32
    8000437a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000437c:	00850913          	addi	s2,a0,8
    80004380:	854a                	mv	a0,s2
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	862080e7          	jalr	-1950(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000438a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000438e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004392:	8526                	mv	a0,s1
    80004394:	ffffe097          	auipc	ra,0xffffe
    80004398:	ee4080e7          	jalr	-284(ra) # 80002278 <wakeup>
  release(&lk->lk);
    8000439c:	854a                	mv	a0,s2
    8000439e:	ffffd097          	auipc	ra,0xffffd
    800043a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>
}
    800043a6:	60e2                	ld	ra,24(sp)
    800043a8:	6442                	ld	s0,16(sp)
    800043aa:	64a2                	ld	s1,8(sp)
    800043ac:	6902                	ld	s2,0(sp)
    800043ae:	6105                	addi	sp,sp,32
    800043b0:	8082                	ret

00000000800043b2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043b2:	7179                	addi	sp,sp,-48
    800043b4:	f406                	sd	ra,40(sp)
    800043b6:	f022                	sd	s0,32(sp)
    800043b8:	ec26                	sd	s1,24(sp)
    800043ba:	e84a                	sd	s2,16(sp)
    800043bc:	e44e                	sd	s3,8(sp)
    800043be:	1800                	addi	s0,sp,48
    800043c0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043c2:	00850913          	addi	s2,a0,8
    800043c6:	854a                	mv	a0,s2
    800043c8:	ffffd097          	auipc	ra,0xffffd
    800043cc:	81c080e7          	jalr	-2020(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043d0:	409c                	lw	a5,0(s1)
    800043d2:	ef99                	bnez	a5,800043f0 <holdingsleep+0x3e>
    800043d4:	4481                	li	s1,0
  release(&lk->lk);
    800043d6:	854a                	mv	a0,s2
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
  return r;
}
    800043e0:	8526                	mv	a0,s1
    800043e2:	70a2                	ld	ra,40(sp)
    800043e4:	7402                	ld	s0,32(sp)
    800043e6:	64e2                	ld	s1,24(sp)
    800043e8:	6942                	ld	s2,16(sp)
    800043ea:	69a2                	ld	s3,8(sp)
    800043ec:	6145                	addi	sp,sp,48
    800043ee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043f0:	0284a983          	lw	s3,40(s1)
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	63c080e7          	jalr	1596(ra) # 80001a30 <myproc>
    800043fc:	5904                	lw	s1,48(a0)
    800043fe:	413484b3          	sub	s1,s1,s3
    80004402:	0014b493          	seqz	s1,s1
    80004406:	bfc1                	j	800043d6 <holdingsleep+0x24>

0000000080004408 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004408:	1141                	addi	sp,sp,-16
    8000440a:	e406                	sd	ra,8(sp)
    8000440c:	e022                	sd	s0,0(sp)
    8000440e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004410:	00004597          	auipc	a1,0x4
    80004414:	33858593          	addi	a1,a1,824 # 80008748 <syscalls+0x238>
    80004418:	00020517          	auipc	a0,0x20
    8000441c:	fa050513          	addi	a0,a0,-96 # 800243b8 <ftable>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	734080e7          	jalr	1844(ra) # 80000b54 <initlock>
}
    80004428:	60a2                	ld	ra,8(sp)
    8000442a:	6402                	ld	s0,0(sp)
    8000442c:	0141                	addi	sp,sp,16
    8000442e:	8082                	ret

0000000080004430 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000443a:	00020517          	auipc	a0,0x20
    8000443e:	f7e50513          	addi	a0,a0,-130 # 800243b8 <ftable>
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	7a2080e7          	jalr	1954(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000444a:	00020497          	auipc	s1,0x20
    8000444e:	f8648493          	addi	s1,s1,-122 # 800243d0 <ftable+0x18>
    80004452:	00021717          	auipc	a4,0x21
    80004456:	f1e70713          	addi	a4,a4,-226 # 80025370 <ftable+0xfb8>
    if(f->ref == 0){
    8000445a:	40dc                	lw	a5,4(s1)
    8000445c:	cf99                	beqz	a5,8000447a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000445e:	02848493          	addi	s1,s1,40
    80004462:	fee49ce3          	bne	s1,a4,8000445a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004466:	00020517          	auipc	a0,0x20
    8000446a:	f5250513          	addi	a0,a0,-174 # 800243b8 <ftable>
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	82a080e7          	jalr	-2006(ra) # 80000c98 <release>
  return 0;
    80004476:	4481                	li	s1,0
    80004478:	a819                	j	8000448e <filealloc+0x5e>
      f->ref = 1;
    8000447a:	4785                	li	a5,1
    8000447c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000447e:	00020517          	auipc	a0,0x20
    80004482:	f3a50513          	addi	a0,a0,-198 # 800243b8 <ftable>
    80004486:	ffffd097          	auipc	ra,0xffffd
    8000448a:	812080e7          	jalr	-2030(ra) # 80000c98 <release>
}
    8000448e:	8526                	mv	a0,s1
    80004490:	60e2                	ld	ra,24(sp)
    80004492:	6442                	ld	s0,16(sp)
    80004494:	64a2                	ld	s1,8(sp)
    80004496:	6105                	addi	sp,sp,32
    80004498:	8082                	ret

000000008000449a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000449a:	1101                	addi	sp,sp,-32
    8000449c:	ec06                	sd	ra,24(sp)
    8000449e:	e822                	sd	s0,16(sp)
    800044a0:	e426                	sd	s1,8(sp)
    800044a2:	1000                	addi	s0,sp,32
    800044a4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044a6:	00020517          	auipc	a0,0x20
    800044aa:	f1250513          	addi	a0,a0,-238 # 800243b8 <ftable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044b6:	40dc                	lw	a5,4(s1)
    800044b8:	02f05263          	blez	a5,800044dc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044bc:	2785                	addiw	a5,a5,1
    800044be:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044c0:	00020517          	auipc	a0,0x20
    800044c4:	ef850513          	addi	a0,a0,-264 # 800243b8 <ftable>
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
  return f;
}
    800044d0:	8526                	mv	a0,s1
    800044d2:	60e2                	ld	ra,24(sp)
    800044d4:	6442                	ld	s0,16(sp)
    800044d6:	64a2                	ld	s1,8(sp)
    800044d8:	6105                	addi	sp,sp,32
    800044da:	8082                	ret
    panic("filedup");
    800044dc:	00004517          	auipc	a0,0x4
    800044e0:	27450513          	addi	a0,a0,628 # 80008750 <syscalls+0x240>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	05a080e7          	jalr	90(ra) # 8000053e <panic>

00000000800044ec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044ec:	7139                	addi	sp,sp,-64
    800044ee:	fc06                	sd	ra,56(sp)
    800044f0:	f822                	sd	s0,48(sp)
    800044f2:	f426                	sd	s1,40(sp)
    800044f4:	f04a                	sd	s2,32(sp)
    800044f6:	ec4e                	sd	s3,24(sp)
    800044f8:	e852                	sd	s4,16(sp)
    800044fa:	e456                	sd	s5,8(sp)
    800044fc:	0080                	addi	s0,sp,64
    800044fe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004500:	00020517          	auipc	a0,0x20
    80004504:	eb850513          	addi	a0,a0,-328 # 800243b8 <ftable>
    80004508:	ffffc097          	auipc	ra,0xffffc
    8000450c:	6dc080e7          	jalr	1756(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004510:	40dc                	lw	a5,4(s1)
    80004512:	06f05163          	blez	a5,80004574 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004516:	37fd                	addiw	a5,a5,-1
    80004518:	0007871b          	sext.w	a4,a5
    8000451c:	c0dc                	sw	a5,4(s1)
    8000451e:	06e04363          	bgtz	a4,80004584 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004522:	0004a903          	lw	s2,0(s1)
    80004526:	0094ca83          	lbu	s5,9(s1)
    8000452a:	0104ba03          	ld	s4,16(s1)
    8000452e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004532:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004536:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000453a:	00020517          	auipc	a0,0x20
    8000453e:	e7e50513          	addi	a0,a0,-386 # 800243b8 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	756080e7          	jalr	1878(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000454a:	4785                	li	a5,1
    8000454c:	04f90d63          	beq	s2,a5,800045a6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004550:	3979                	addiw	s2,s2,-2
    80004552:	4785                	li	a5,1
    80004554:	0527e063          	bltu	a5,s2,80004594 <fileclose+0xa8>
    begin_op();
    80004558:	00000097          	auipc	ra,0x0
    8000455c:	ac8080e7          	jalr	-1336(ra) # 80004020 <begin_op>
    iput(ff.ip);
    80004560:	854e                	mv	a0,s3
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	2a6080e7          	jalr	678(ra) # 80003808 <iput>
    end_op();
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	b36080e7          	jalr	-1226(ra) # 800040a0 <end_op>
    80004572:	a00d                	j	80004594 <fileclose+0xa8>
    panic("fileclose");
    80004574:	00004517          	auipc	a0,0x4
    80004578:	1e450513          	addi	a0,a0,484 # 80008758 <syscalls+0x248>
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	fc2080e7          	jalr	-62(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004584:	00020517          	auipc	a0,0x20
    80004588:	e3450513          	addi	a0,a0,-460 # 800243b8 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	70c080e7          	jalr	1804(ra) # 80000c98 <release>
  }
}
    80004594:	70e2                	ld	ra,56(sp)
    80004596:	7442                	ld	s0,48(sp)
    80004598:	74a2                	ld	s1,40(sp)
    8000459a:	7902                	ld	s2,32(sp)
    8000459c:	69e2                	ld	s3,24(sp)
    8000459e:	6a42                	ld	s4,16(sp)
    800045a0:	6aa2                	ld	s5,8(sp)
    800045a2:	6121                	addi	sp,sp,64
    800045a4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045a6:	85d6                	mv	a1,s5
    800045a8:	8552                	mv	a0,s4
    800045aa:	00000097          	auipc	ra,0x0
    800045ae:	34c080e7          	jalr	844(ra) # 800048f6 <pipeclose>
    800045b2:	b7cd                	j	80004594 <fileclose+0xa8>

00000000800045b4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045b4:	715d                	addi	sp,sp,-80
    800045b6:	e486                	sd	ra,72(sp)
    800045b8:	e0a2                	sd	s0,64(sp)
    800045ba:	fc26                	sd	s1,56(sp)
    800045bc:	f84a                	sd	s2,48(sp)
    800045be:	f44e                	sd	s3,40(sp)
    800045c0:	0880                	addi	s0,sp,80
    800045c2:	84aa                	mv	s1,a0
    800045c4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045c6:	ffffd097          	auipc	ra,0xffffd
    800045ca:	46a080e7          	jalr	1130(ra) # 80001a30 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045ce:	409c                	lw	a5,0(s1)
    800045d0:	37f9                	addiw	a5,a5,-2
    800045d2:	4705                	li	a4,1
    800045d4:	04f76763          	bltu	a4,a5,80004622 <filestat+0x6e>
    800045d8:	892a                	mv	s2,a0
    ilock(f->ip);
    800045da:	6c88                	ld	a0,24(s1)
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	072080e7          	jalr	114(ra) # 8000364e <ilock>
    stati(f->ip, &st);
    800045e4:	fb840593          	addi	a1,s0,-72
    800045e8:	6c88                	ld	a0,24(s1)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	2ee080e7          	jalr	750(ra) # 800038d8 <stati>
    iunlock(f->ip);
    800045f2:	6c88                	ld	a0,24(s1)
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	11c080e7          	jalr	284(ra) # 80003710 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045fc:	46e1                	li	a3,24
    800045fe:	fb840613          	addi	a2,s0,-72
    80004602:	85ce                	mv	a1,s3
    80004604:	05093503          	ld	a0,80(s2)
    80004608:	ffffd097          	auipc	ra,0xffffd
    8000460c:	0ea080e7          	jalr	234(ra) # 800016f2 <copyout>
    80004610:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004614:	60a6                	ld	ra,72(sp)
    80004616:	6406                	ld	s0,64(sp)
    80004618:	74e2                	ld	s1,56(sp)
    8000461a:	7942                	ld	s2,48(sp)
    8000461c:	79a2                	ld	s3,40(sp)
    8000461e:	6161                	addi	sp,sp,80
    80004620:	8082                	ret
  return -1;
    80004622:	557d                	li	a0,-1
    80004624:	bfc5                	j	80004614 <filestat+0x60>

0000000080004626 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004626:	7179                	addi	sp,sp,-48
    80004628:	f406                	sd	ra,40(sp)
    8000462a:	f022                	sd	s0,32(sp)
    8000462c:	ec26                	sd	s1,24(sp)
    8000462e:	e84a                	sd	s2,16(sp)
    80004630:	e44e                	sd	s3,8(sp)
    80004632:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004634:	00854783          	lbu	a5,8(a0)
    80004638:	c3d5                	beqz	a5,800046dc <fileread+0xb6>
    8000463a:	84aa                	mv	s1,a0
    8000463c:	89ae                	mv	s3,a1
    8000463e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004640:	411c                	lw	a5,0(a0)
    80004642:	4705                	li	a4,1
    80004644:	04e78963          	beq	a5,a4,80004696 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004648:	470d                	li	a4,3
    8000464a:	04e78d63          	beq	a5,a4,800046a4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000464e:	4709                	li	a4,2
    80004650:	06e79e63          	bne	a5,a4,800046cc <fileread+0xa6>
    ilock(f->ip);
    80004654:	6d08                	ld	a0,24(a0)
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	ff8080e7          	jalr	-8(ra) # 8000364e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000465e:	874a                	mv	a4,s2
    80004660:	5094                	lw	a3,32(s1)
    80004662:	864e                	mv	a2,s3
    80004664:	4585                	li	a1,1
    80004666:	6c88                	ld	a0,24(s1)
    80004668:	fffff097          	auipc	ra,0xfffff
    8000466c:	29a080e7          	jalr	666(ra) # 80003902 <readi>
    80004670:	892a                	mv	s2,a0
    80004672:	00a05563          	blez	a0,8000467c <fileread+0x56>
      f->off += r;
    80004676:	509c                	lw	a5,32(s1)
    80004678:	9fa9                	addw	a5,a5,a0
    8000467a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	092080e7          	jalr	146(ra) # 80003710 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004686:	854a                	mv	a0,s2
    80004688:	70a2                	ld	ra,40(sp)
    8000468a:	7402                	ld	s0,32(sp)
    8000468c:	64e2                	ld	s1,24(sp)
    8000468e:	6942                	ld	s2,16(sp)
    80004690:	69a2                	ld	s3,8(sp)
    80004692:	6145                	addi	sp,sp,48
    80004694:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004696:	6908                	ld	a0,16(a0)
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	3c8080e7          	jalr	968(ra) # 80004a60 <piperead>
    800046a0:	892a                	mv	s2,a0
    800046a2:	b7d5                	j	80004686 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046a4:	02451783          	lh	a5,36(a0)
    800046a8:	03079693          	slli	a3,a5,0x30
    800046ac:	92c1                	srli	a3,a3,0x30
    800046ae:	4725                	li	a4,9
    800046b0:	02d76863          	bltu	a4,a3,800046e0 <fileread+0xba>
    800046b4:	0792                	slli	a5,a5,0x4
    800046b6:	00020717          	auipc	a4,0x20
    800046ba:	c6270713          	addi	a4,a4,-926 # 80024318 <devsw>
    800046be:	97ba                	add	a5,a5,a4
    800046c0:	639c                	ld	a5,0(a5)
    800046c2:	c38d                	beqz	a5,800046e4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046c4:	4505                	li	a0,1
    800046c6:	9782                	jalr	a5
    800046c8:	892a                	mv	s2,a0
    800046ca:	bf75                	j	80004686 <fileread+0x60>
    panic("fileread");
    800046cc:	00004517          	auipc	a0,0x4
    800046d0:	09c50513          	addi	a0,a0,156 # 80008768 <syscalls+0x258>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	e6a080e7          	jalr	-406(ra) # 8000053e <panic>
    return -1;
    800046dc:	597d                	li	s2,-1
    800046de:	b765                	j	80004686 <fileread+0x60>
      return -1;
    800046e0:	597d                	li	s2,-1
    800046e2:	b755                	j	80004686 <fileread+0x60>
    800046e4:	597d                	li	s2,-1
    800046e6:	b745                	j	80004686 <fileread+0x60>

00000000800046e8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046e8:	715d                	addi	sp,sp,-80
    800046ea:	e486                	sd	ra,72(sp)
    800046ec:	e0a2                	sd	s0,64(sp)
    800046ee:	fc26                	sd	s1,56(sp)
    800046f0:	f84a                	sd	s2,48(sp)
    800046f2:	f44e                	sd	s3,40(sp)
    800046f4:	f052                	sd	s4,32(sp)
    800046f6:	ec56                	sd	s5,24(sp)
    800046f8:	e85a                	sd	s6,16(sp)
    800046fa:	e45e                	sd	s7,8(sp)
    800046fc:	e062                	sd	s8,0(sp)
    800046fe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004700:	00954783          	lbu	a5,9(a0)
    80004704:	10078663          	beqz	a5,80004810 <filewrite+0x128>
    80004708:	892a                	mv	s2,a0
    8000470a:	8aae                	mv	s5,a1
    8000470c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000470e:	411c                	lw	a5,0(a0)
    80004710:	4705                	li	a4,1
    80004712:	02e78263          	beq	a5,a4,80004736 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004716:	470d                	li	a4,3
    80004718:	02e78663          	beq	a5,a4,80004744 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000471c:	4709                	li	a4,2
    8000471e:	0ee79163          	bne	a5,a4,80004800 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004722:	0ac05d63          	blez	a2,800047dc <filewrite+0xf4>
    int i = 0;
    80004726:	4981                	li	s3,0
    80004728:	6b05                	lui	s6,0x1
    8000472a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000472e:	6b85                	lui	s7,0x1
    80004730:	c00b8b9b          	addiw	s7,s7,-1024
    80004734:	a861                	j	800047cc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004736:	6908                	ld	a0,16(a0)
    80004738:	00000097          	auipc	ra,0x0
    8000473c:	22e080e7          	jalr	558(ra) # 80004966 <pipewrite>
    80004740:	8a2a                	mv	s4,a0
    80004742:	a045                	j	800047e2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004744:	02451783          	lh	a5,36(a0)
    80004748:	03079693          	slli	a3,a5,0x30
    8000474c:	92c1                	srli	a3,a3,0x30
    8000474e:	4725                	li	a4,9
    80004750:	0cd76263          	bltu	a4,a3,80004814 <filewrite+0x12c>
    80004754:	0792                	slli	a5,a5,0x4
    80004756:	00020717          	auipc	a4,0x20
    8000475a:	bc270713          	addi	a4,a4,-1086 # 80024318 <devsw>
    8000475e:	97ba                	add	a5,a5,a4
    80004760:	679c                	ld	a5,8(a5)
    80004762:	cbdd                	beqz	a5,80004818 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004764:	4505                	li	a0,1
    80004766:	9782                	jalr	a5
    80004768:	8a2a                	mv	s4,a0
    8000476a:	a8a5                	j	800047e2 <filewrite+0xfa>
    8000476c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004770:	00000097          	auipc	ra,0x0
    80004774:	8b0080e7          	jalr	-1872(ra) # 80004020 <begin_op>
      ilock(f->ip);
    80004778:	01893503          	ld	a0,24(s2)
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	ed2080e7          	jalr	-302(ra) # 8000364e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004784:	8762                	mv	a4,s8
    80004786:	02092683          	lw	a3,32(s2)
    8000478a:	01598633          	add	a2,s3,s5
    8000478e:	4585                	li	a1,1
    80004790:	01893503          	ld	a0,24(s2)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	266080e7          	jalr	614(ra) # 800039fa <writei>
    8000479c:	84aa                	mv	s1,a0
    8000479e:	00a05763          	blez	a0,800047ac <filewrite+0xc4>
        f->off += r;
    800047a2:	02092783          	lw	a5,32(s2)
    800047a6:	9fa9                	addw	a5,a5,a0
    800047a8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047ac:	01893503          	ld	a0,24(s2)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	f60080e7          	jalr	-160(ra) # 80003710 <iunlock>
      end_op();
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	8e8080e7          	jalr	-1816(ra) # 800040a0 <end_op>

      if(r != n1){
    800047c0:	009c1f63          	bne	s8,s1,800047de <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800047c4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047c8:	0149db63          	bge	s3,s4,800047de <filewrite+0xf6>
      int n1 = n - i;
    800047cc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047d0:	84be                	mv	s1,a5
    800047d2:	2781                	sext.w	a5,a5
    800047d4:	f8fb5ce3          	bge	s6,a5,8000476c <filewrite+0x84>
    800047d8:	84de                	mv	s1,s7
    800047da:	bf49                	j	8000476c <filewrite+0x84>
    int i = 0;
    800047dc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047de:	013a1f63          	bne	s4,s3,800047fc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047e2:	8552                	mv	a0,s4
    800047e4:	60a6                	ld	ra,72(sp)
    800047e6:	6406                	ld	s0,64(sp)
    800047e8:	74e2                	ld	s1,56(sp)
    800047ea:	7942                	ld	s2,48(sp)
    800047ec:	79a2                	ld	s3,40(sp)
    800047ee:	7a02                	ld	s4,32(sp)
    800047f0:	6ae2                	ld	s5,24(sp)
    800047f2:	6b42                	ld	s6,16(sp)
    800047f4:	6ba2                	ld	s7,8(sp)
    800047f6:	6c02                	ld	s8,0(sp)
    800047f8:	6161                	addi	sp,sp,80
    800047fa:	8082                	ret
    ret = (i == n ? n : -1);
    800047fc:	5a7d                	li	s4,-1
    800047fe:	b7d5                	j	800047e2 <filewrite+0xfa>
    panic("filewrite");
    80004800:	00004517          	auipc	a0,0x4
    80004804:	f7850513          	addi	a0,a0,-136 # 80008778 <syscalls+0x268>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	d36080e7          	jalr	-714(ra) # 8000053e <panic>
    return -1;
    80004810:	5a7d                	li	s4,-1
    80004812:	bfc1                	j	800047e2 <filewrite+0xfa>
      return -1;
    80004814:	5a7d                	li	s4,-1
    80004816:	b7f1                	j	800047e2 <filewrite+0xfa>
    80004818:	5a7d                	li	s4,-1
    8000481a:	b7e1                	j	800047e2 <filewrite+0xfa>

000000008000481c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000481c:	7179                	addi	sp,sp,-48
    8000481e:	f406                	sd	ra,40(sp)
    80004820:	f022                	sd	s0,32(sp)
    80004822:	ec26                	sd	s1,24(sp)
    80004824:	e84a                	sd	s2,16(sp)
    80004826:	e44e                	sd	s3,8(sp)
    80004828:	e052                	sd	s4,0(sp)
    8000482a:	1800                	addi	s0,sp,48
    8000482c:	84aa                	mv	s1,a0
    8000482e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004830:	0005b023          	sd	zero,0(a1)
    80004834:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	bf8080e7          	jalr	-1032(ra) # 80004430 <filealloc>
    80004840:	e088                	sd	a0,0(s1)
    80004842:	c551                	beqz	a0,800048ce <pipealloc+0xb2>
    80004844:	00000097          	auipc	ra,0x0
    80004848:	bec080e7          	jalr	-1044(ra) # 80004430 <filealloc>
    8000484c:	00aa3023          	sd	a0,0(s4)
    80004850:	c92d                	beqz	a0,800048c2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	2a2080e7          	jalr	674(ra) # 80000af4 <kalloc>
    8000485a:	892a                	mv	s2,a0
    8000485c:	c125                	beqz	a0,800048bc <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000485e:	4985                	li	s3,1
    80004860:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004864:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004868:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000486c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004870:	00004597          	auipc	a1,0x4
    80004874:	f1858593          	addi	a1,a1,-232 # 80008788 <syscalls+0x278>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	2dc080e7          	jalr	732(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004880:	609c                	ld	a5,0(s1)
    80004882:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004886:	609c                	ld	a5,0(s1)
    80004888:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000488c:	609c                	ld	a5,0(s1)
    8000488e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004892:	609c                	ld	a5,0(s1)
    80004894:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004898:	000a3783          	ld	a5,0(s4)
    8000489c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048a0:	000a3783          	ld	a5,0(s4)
    800048a4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048a8:	000a3783          	ld	a5,0(s4)
    800048ac:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048b0:	000a3783          	ld	a5,0(s4)
    800048b4:	0127b823          	sd	s2,16(a5)
  return 0;
    800048b8:	4501                	li	a0,0
    800048ba:	a025                	j	800048e2 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048bc:	6088                	ld	a0,0(s1)
    800048be:	e501                	bnez	a0,800048c6 <pipealloc+0xaa>
    800048c0:	a039                	j	800048ce <pipealloc+0xb2>
    800048c2:	6088                	ld	a0,0(s1)
    800048c4:	c51d                	beqz	a0,800048f2 <pipealloc+0xd6>
    fileclose(*f0);
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	c26080e7          	jalr	-986(ra) # 800044ec <fileclose>
  if(*f1)
    800048ce:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048d2:	557d                	li	a0,-1
  if(*f1)
    800048d4:	c799                	beqz	a5,800048e2 <pipealloc+0xc6>
    fileclose(*f1);
    800048d6:	853e                	mv	a0,a5
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	c14080e7          	jalr	-1004(ra) # 800044ec <fileclose>
  return -1;
    800048e0:	557d                	li	a0,-1
}
    800048e2:	70a2                	ld	ra,40(sp)
    800048e4:	7402                	ld	s0,32(sp)
    800048e6:	64e2                	ld	s1,24(sp)
    800048e8:	6942                	ld	s2,16(sp)
    800048ea:	69a2                	ld	s3,8(sp)
    800048ec:	6a02                	ld	s4,0(sp)
    800048ee:	6145                	addi	sp,sp,48
    800048f0:	8082                	ret
  return -1;
    800048f2:	557d                	li	a0,-1
    800048f4:	b7fd                	j	800048e2 <pipealloc+0xc6>

00000000800048f6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	e04a                	sd	s2,0(sp)
    80004900:	1000                	addi	s0,sp,32
    80004902:	84aa                	mv	s1,a0
    80004904:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	2de080e7          	jalr	734(ra) # 80000be4 <acquire>
  if(writable){
    8000490e:	02090d63          	beqz	s2,80004948 <pipeclose+0x52>
    pi->writeopen = 0;
    80004912:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004916:	21848513          	addi	a0,s1,536
    8000491a:	ffffe097          	auipc	ra,0xffffe
    8000491e:	95e080e7          	jalr	-1698(ra) # 80002278 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004922:	2204b783          	ld	a5,544(s1)
    80004926:	eb95                	bnez	a5,8000495a <pipeclose+0x64>
    release(&pi->lock);
    80004928:	8526                	mv	a0,s1
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	36e080e7          	jalr	878(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004932:	8526                	mv	a0,s1
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	0c4080e7          	jalr	196(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    8000493c:	60e2                	ld	ra,24(sp)
    8000493e:	6442                	ld	s0,16(sp)
    80004940:	64a2                	ld	s1,8(sp)
    80004942:	6902                	ld	s2,0(sp)
    80004944:	6105                	addi	sp,sp,32
    80004946:	8082                	ret
    pi->readopen = 0;
    80004948:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000494c:	21c48513          	addi	a0,s1,540
    80004950:	ffffe097          	auipc	ra,0xffffe
    80004954:	928080e7          	jalr	-1752(ra) # 80002278 <wakeup>
    80004958:	b7e9                	j	80004922 <pipeclose+0x2c>
    release(&pi->lock);
    8000495a:	8526                	mv	a0,s1
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	33c080e7          	jalr	828(ra) # 80000c98 <release>
}
    80004964:	bfe1                	j	8000493c <pipeclose+0x46>

0000000080004966 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004966:	7159                	addi	sp,sp,-112
    80004968:	f486                	sd	ra,104(sp)
    8000496a:	f0a2                	sd	s0,96(sp)
    8000496c:	eca6                	sd	s1,88(sp)
    8000496e:	e8ca                	sd	s2,80(sp)
    80004970:	e4ce                	sd	s3,72(sp)
    80004972:	e0d2                	sd	s4,64(sp)
    80004974:	fc56                	sd	s5,56(sp)
    80004976:	f85a                	sd	s6,48(sp)
    80004978:	f45e                	sd	s7,40(sp)
    8000497a:	f062                	sd	s8,32(sp)
    8000497c:	ec66                	sd	s9,24(sp)
    8000497e:	1880                	addi	s0,sp,112
    80004980:	84aa                	mv	s1,a0
    80004982:	8aae                	mv	s5,a1
    80004984:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004986:	ffffd097          	auipc	ra,0xffffd
    8000498a:	0aa080e7          	jalr	170(ra) # 80001a30 <myproc>
    8000498e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004990:	8526                	mv	a0,s1
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	252080e7          	jalr	594(ra) # 80000be4 <acquire>
  while(i < n){
    8000499a:	0d405163          	blez	s4,80004a5c <pipewrite+0xf6>
    8000499e:	8ba6                	mv	s7,s1
  int i = 0;
    800049a0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049a2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049a4:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049a8:	21c48c13          	addi	s8,s1,540
    800049ac:	a08d                	j	80004a0e <pipewrite+0xa8>
      release(&pi->lock);
    800049ae:	8526                	mv	a0,s1
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	2e8080e7          	jalr	744(ra) # 80000c98 <release>
      return -1;
    800049b8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800049ba:	854a                	mv	a0,s2
    800049bc:	70a6                	ld	ra,104(sp)
    800049be:	7406                	ld	s0,96(sp)
    800049c0:	64e6                	ld	s1,88(sp)
    800049c2:	6946                	ld	s2,80(sp)
    800049c4:	69a6                	ld	s3,72(sp)
    800049c6:	6a06                	ld	s4,64(sp)
    800049c8:	7ae2                	ld	s5,56(sp)
    800049ca:	7b42                	ld	s6,48(sp)
    800049cc:	7ba2                	ld	s7,40(sp)
    800049ce:	7c02                	ld	s8,32(sp)
    800049d0:	6ce2                	ld	s9,24(sp)
    800049d2:	6165                	addi	sp,sp,112
    800049d4:	8082                	ret
      wakeup(&pi->nread);
    800049d6:	8566                	mv	a0,s9
    800049d8:	ffffe097          	auipc	ra,0xffffe
    800049dc:	8a0080e7          	jalr	-1888(ra) # 80002278 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049e0:	85de                	mv	a1,s7
    800049e2:	8562                	mv	a0,s8
    800049e4:	ffffd097          	auipc	ra,0xffffd
    800049e8:	708080e7          	jalr	1800(ra) # 800020ec <sleep>
    800049ec:	a839                	j	80004a0a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049ee:	21c4a783          	lw	a5,540(s1)
    800049f2:	0017871b          	addiw	a4,a5,1
    800049f6:	20e4ae23          	sw	a4,540(s1)
    800049fa:	1ff7f793          	andi	a5,a5,511
    800049fe:	97a6                	add	a5,a5,s1
    80004a00:	f9f44703          	lbu	a4,-97(s0)
    80004a04:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a08:	2905                	addiw	s2,s2,1
  while(i < n){
    80004a0a:	03495d63          	bge	s2,s4,80004a44 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004a0e:	2204a783          	lw	a5,544(s1)
    80004a12:	dfd1                	beqz	a5,800049ae <pipewrite+0x48>
    80004a14:	0289a783          	lw	a5,40(s3)
    80004a18:	fbd9                	bnez	a5,800049ae <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a1a:	2184a783          	lw	a5,536(s1)
    80004a1e:	21c4a703          	lw	a4,540(s1)
    80004a22:	2007879b          	addiw	a5,a5,512
    80004a26:	faf708e3          	beq	a4,a5,800049d6 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a2a:	4685                	li	a3,1
    80004a2c:	01590633          	add	a2,s2,s5
    80004a30:	f9f40593          	addi	a1,s0,-97
    80004a34:	0509b503          	ld	a0,80(s3)
    80004a38:	ffffd097          	auipc	ra,0xffffd
    80004a3c:	d46080e7          	jalr	-698(ra) # 8000177e <copyin>
    80004a40:	fb6517e3          	bne	a0,s6,800049ee <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a44:	21848513          	addi	a0,s1,536
    80004a48:	ffffe097          	auipc	ra,0xffffe
    80004a4c:	830080e7          	jalr	-2000(ra) # 80002278 <wakeup>
  release(&pi->lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
  return i;
    80004a5a:	b785                	j	800049ba <pipewrite+0x54>
  int i = 0;
    80004a5c:	4901                	li	s2,0
    80004a5e:	b7dd                	j	80004a44 <pipewrite+0xde>

0000000080004a60 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a60:	715d                	addi	sp,sp,-80
    80004a62:	e486                	sd	ra,72(sp)
    80004a64:	e0a2                	sd	s0,64(sp)
    80004a66:	fc26                	sd	s1,56(sp)
    80004a68:	f84a                	sd	s2,48(sp)
    80004a6a:	f44e                	sd	s3,40(sp)
    80004a6c:	f052                	sd	s4,32(sp)
    80004a6e:	ec56                	sd	s5,24(sp)
    80004a70:	e85a                	sd	s6,16(sp)
    80004a72:	0880                	addi	s0,sp,80
    80004a74:	84aa                	mv	s1,a0
    80004a76:	892e                	mv	s2,a1
    80004a78:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a7a:	ffffd097          	auipc	ra,0xffffd
    80004a7e:	fb6080e7          	jalr	-74(ra) # 80001a30 <myproc>
    80004a82:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a84:	8b26                	mv	s6,s1
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffc097          	auipc	ra,0xffffc
    80004a8c:	15c080e7          	jalr	348(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a90:	2184a703          	lw	a4,536(s1)
    80004a94:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a98:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a9c:	02f71463          	bne	a4,a5,80004ac4 <piperead+0x64>
    80004aa0:	2244a783          	lw	a5,548(s1)
    80004aa4:	c385                	beqz	a5,80004ac4 <piperead+0x64>
    if(pr->killed){
    80004aa6:	028a2783          	lw	a5,40(s4)
    80004aaa:	ebc1                	bnez	a5,80004b3a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aac:	85da                	mv	a1,s6
    80004aae:	854e                	mv	a0,s3
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	63c080e7          	jalr	1596(ra) # 800020ec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab8:	2184a703          	lw	a4,536(s1)
    80004abc:	21c4a783          	lw	a5,540(s1)
    80004ac0:	fef700e3          	beq	a4,a5,80004aa0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ac4:	09505263          	blez	s5,80004b48 <piperead+0xe8>
    80004ac8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aca:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004acc:	2184a783          	lw	a5,536(s1)
    80004ad0:	21c4a703          	lw	a4,540(s1)
    80004ad4:	02f70d63          	beq	a4,a5,80004b0e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ad8:	0017871b          	addiw	a4,a5,1
    80004adc:	20e4ac23          	sw	a4,536(s1)
    80004ae0:	1ff7f793          	andi	a5,a5,511
    80004ae4:	97a6                	add	a5,a5,s1
    80004ae6:	0187c783          	lbu	a5,24(a5)
    80004aea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004aee:	4685                	li	a3,1
    80004af0:	fbf40613          	addi	a2,s0,-65
    80004af4:	85ca                	mv	a1,s2
    80004af6:	050a3503          	ld	a0,80(s4)
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	bf8080e7          	jalr	-1032(ra) # 800016f2 <copyout>
    80004b02:	01650663          	beq	a0,s6,80004b0e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b06:	2985                	addiw	s3,s3,1
    80004b08:	0905                	addi	s2,s2,1
    80004b0a:	fd3a91e3          	bne	s5,s3,80004acc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b0e:	21c48513          	addi	a0,s1,540
    80004b12:	ffffd097          	auipc	ra,0xffffd
    80004b16:	766080e7          	jalr	1894(ra) # 80002278 <wakeup>
  release(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	17c080e7          	jalr	380(ra) # 80000c98 <release>
  return i;
}
    80004b24:	854e                	mv	a0,s3
    80004b26:	60a6                	ld	ra,72(sp)
    80004b28:	6406                	ld	s0,64(sp)
    80004b2a:	74e2                	ld	s1,56(sp)
    80004b2c:	7942                	ld	s2,48(sp)
    80004b2e:	79a2                	ld	s3,40(sp)
    80004b30:	7a02                	ld	s4,32(sp)
    80004b32:	6ae2                	ld	s5,24(sp)
    80004b34:	6b42                	ld	s6,16(sp)
    80004b36:	6161                	addi	sp,sp,80
    80004b38:	8082                	ret
      release(&pi->lock);
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	15c080e7          	jalr	348(ra) # 80000c98 <release>
      return -1;
    80004b44:	59fd                	li	s3,-1
    80004b46:	bff9                	j	80004b24 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b48:	4981                	li	s3,0
    80004b4a:	b7d1                	j	80004b0e <piperead+0xae>

0000000080004b4c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b4c:	df010113          	addi	sp,sp,-528
    80004b50:	20113423          	sd	ra,520(sp)
    80004b54:	20813023          	sd	s0,512(sp)
    80004b58:	ffa6                	sd	s1,504(sp)
    80004b5a:	fbca                	sd	s2,496(sp)
    80004b5c:	f7ce                	sd	s3,488(sp)
    80004b5e:	f3d2                	sd	s4,480(sp)
    80004b60:	efd6                	sd	s5,472(sp)
    80004b62:	ebda                	sd	s6,464(sp)
    80004b64:	e7de                	sd	s7,456(sp)
    80004b66:	e3e2                	sd	s8,448(sp)
    80004b68:	ff66                	sd	s9,440(sp)
    80004b6a:	fb6a                	sd	s10,432(sp)
    80004b6c:	f76e                	sd	s11,424(sp)
    80004b6e:	0c00                	addi	s0,sp,528
    80004b70:	84aa                	mv	s1,a0
    80004b72:	dea43c23          	sd	a0,-520(s0)
    80004b76:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	eb6080e7          	jalr	-330(ra) # 80001a30 <myproc>
    80004b82:	892a                	mv	s2,a0

  begin_op();
    80004b84:	fffff097          	auipc	ra,0xfffff
    80004b88:	49c080e7          	jalr	1180(ra) # 80004020 <begin_op>

  if((ip = namei(path)) == 0){
    80004b8c:	8526                	mv	a0,s1
    80004b8e:	fffff097          	auipc	ra,0xfffff
    80004b92:	276080e7          	jalr	630(ra) # 80003e04 <namei>
    80004b96:	c92d                	beqz	a0,80004c08 <exec+0xbc>
    80004b98:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	ab4080e7          	jalr	-1356(ra) # 8000364e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ba2:	04000713          	li	a4,64
    80004ba6:	4681                	li	a3,0
    80004ba8:	e5040613          	addi	a2,s0,-432
    80004bac:	4581                	li	a1,0
    80004bae:	8526                	mv	a0,s1
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	d52080e7          	jalr	-686(ra) # 80003902 <readi>
    80004bb8:	04000793          	li	a5,64
    80004bbc:	00f51a63          	bne	a0,a5,80004bd0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004bc0:	e5042703          	lw	a4,-432(s0)
    80004bc4:	464c47b7          	lui	a5,0x464c4
    80004bc8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004bcc:	04f70463          	beq	a4,a5,80004c14 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	fffff097          	auipc	ra,0xfffff
    80004bd6:	cde080e7          	jalr	-802(ra) # 800038b0 <iunlockput>
    end_op();
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	4c6080e7          	jalr	1222(ra) # 800040a0 <end_op>
  }
  return -1;
    80004be2:	557d                	li	a0,-1
}
    80004be4:	20813083          	ld	ra,520(sp)
    80004be8:	20013403          	ld	s0,512(sp)
    80004bec:	74fe                	ld	s1,504(sp)
    80004bee:	795e                	ld	s2,496(sp)
    80004bf0:	79be                	ld	s3,488(sp)
    80004bf2:	7a1e                	ld	s4,480(sp)
    80004bf4:	6afe                	ld	s5,472(sp)
    80004bf6:	6b5e                	ld	s6,464(sp)
    80004bf8:	6bbe                	ld	s7,456(sp)
    80004bfa:	6c1e                	ld	s8,448(sp)
    80004bfc:	7cfa                	ld	s9,440(sp)
    80004bfe:	7d5a                	ld	s10,432(sp)
    80004c00:	7dba                	ld	s11,424(sp)
    80004c02:	21010113          	addi	sp,sp,528
    80004c06:	8082                	ret
    end_op();
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	498080e7          	jalr	1176(ra) # 800040a0 <end_op>
    return -1;
    80004c10:	557d                	li	a0,-1
    80004c12:	bfc9                	j	80004be4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c14:	854a                	mv	a0,s2
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	ede080e7          	jalr	-290(ra) # 80001af4 <proc_pagetable>
    80004c1e:	8baa                	mv	s7,a0
    80004c20:	d945                	beqz	a0,80004bd0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c22:	e7042983          	lw	s3,-400(s0)
    80004c26:	e8845783          	lhu	a5,-376(s0)
    80004c2a:	c7ad                	beqz	a5,80004c94 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c2c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c2e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004c30:	6c91                	lui	s9,0x4
    80004c32:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004c36:	def43823          	sd	a5,-528(s0)
    80004c3a:	a42d                	j	80004e64 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004c3c:	00004517          	auipc	a0,0x4
    80004c40:	b5450513          	addi	a0,a0,-1196 # 80008790 <syscalls+0x280>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	8fa080e7          	jalr	-1798(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c4c:	8756                	mv	a4,s5
    80004c4e:	012d86bb          	addw	a3,s11,s2
    80004c52:	4581                	li	a1,0
    80004c54:	8526                	mv	a0,s1
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	cac080e7          	jalr	-852(ra) # 80003902 <readi>
    80004c5e:	2501                	sext.w	a0,a0
    80004c60:	1aaa9963          	bne	s5,a0,80004e12 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c64:	6791                	lui	a5,0x4
    80004c66:	0127893b          	addw	s2,a5,s2
    80004c6a:	77f1                	lui	a5,0xffffc
    80004c6c:	01478a3b          	addw	s4,a5,s4
    80004c70:	1f897163          	bgeu	s2,s8,80004e52 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c74:	02091593          	slli	a1,s2,0x20
    80004c78:	9181                	srli	a1,a1,0x20
    80004c7a:	95ea                	add	a1,a1,s10
    80004c7c:	855e                	mv	a0,s7
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	456080e7          	jalr	1110(ra) # 800010d4 <walkaddr>
    80004c86:	862a                	mv	a2,a0
    if(pa == 0)
    80004c88:	d955                	beqz	a0,80004c3c <exec+0xf0>
      n = PGSIZE;
    80004c8a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c8c:	fd9a70e3          	bgeu	s4,s9,80004c4c <exec+0x100>
      n = sz - i;
    80004c90:	8ad2                	mv	s5,s4
    80004c92:	bf6d                	j	80004c4c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c94:	4901                	li	s2,0
  iunlockput(ip);
    80004c96:	8526                	mv	a0,s1
    80004c98:	fffff097          	auipc	ra,0xfffff
    80004c9c:	c18080e7          	jalr	-1000(ra) # 800038b0 <iunlockput>
  end_op();
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	400080e7          	jalr	1024(ra) # 800040a0 <end_op>
  p = myproc();
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	d88080e7          	jalr	-632(ra) # 80001a30 <myproc>
    80004cb0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004cb2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004cb6:	6791                	lui	a5,0x4
    80004cb8:	17fd                	addi	a5,a5,-1
    80004cba:	993e                	add	s2,s2,a5
    80004cbc:	7571                	lui	a0,0xffffc
    80004cbe:	00a977b3          	and	a5,s2,a0
    80004cc2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cc6:	6621                	lui	a2,0x8
    80004cc8:	963e                	add	a2,a2,a5
    80004cca:	85be                	mv	a1,a5
    80004ccc:	855e                	mv	a0,s7
    80004cce:	ffffc097          	auipc	ra,0xffffc
    80004cd2:	7d4080e7          	jalr	2004(ra) # 800014a2 <uvmalloc>
    80004cd6:	8b2a                	mv	s6,a0
  ip = 0;
    80004cd8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004cda:	12050c63          	beqz	a0,80004e12 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004cde:	75e1                	lui	a1,0xffff8
    80004ce0:	95aa                	add	a1,a1,a0
    80004ce2:	855e                	mv	a0,s7
    80004ce4:	ffffd097          	auipc	ra,0xffffd
    80004ce8:	9dc080e7          	jalr	-1572(ra) # 800016c0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cec:	7c71                	lui	s8,0xffffc
    80004cee:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cf0:	e0043783          	ld	a5,-512(s0)
    80004cf4:	6388                	ld	a0,0(a5)
    80004cf6:	c535                	beqz	a0,80004d62 <exec+0x216>
    80004cf8:	e9040993          	addi	s3,s0,-368
    80004cfc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d00:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	162080e7          	jalr	354(ra) # 80000e64 <strlen>
    80004d0a:	2505                	addiw	a0,a0,1
    80004d0c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d10:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d14:	13896363          	bltu	s2,s8,80004e3a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d18:	e0043d83          	ld	s11,-512(s0)
    80004d1c:	000dba03          	ld	s4,0(s11)
    80004d20:	8552                	mv	a0,s4
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	142080e7          	jalr	322(ra) # 80000e64 <strlen>
    80004d2a:	0015069b          	addiw	a3,a0,1
    80004d2e:	8652                	mv	a2,s4
    80004d30:	85ca                	mv	a1,s2
    80004d32:	855e                	mv	a0,s7
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	9be080e7          	jalr	-1602(ra) # 800016f2 <copyout>
    80004d3c:	10054363          	bltz	a0,80004e42 <exec+0x2f6>
    ustack[argc] = sp;
    80004d40:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d44:	0485                	addi	s1,s1,1
    80004d46:	008d8793          	addi	a5,s11,8
    80004d4a:	e0f43023          	sd	a5,-512(s0)
    80004d4e:	008db503          	ld	a0,8(s11)
    80004d52:	c911                	beqz	a0,80004d66 <exec+0x21a>
    if(argc >= MAXARG)
    80004d54:	09a1                	addi	s3,s3,8
    80004d56:	fb3c96e3          	bne	s9,s3,80004d02 <exec+0x1b6>
  sz = sz1;
    80004d5a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d5e:	4481                	li	s1,0
    80004d60:	a84d                	j	80004e12 <exec+0x2c6>
  sp = sz;
    80004d62:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d64:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d66:	00349793          	slli	a5,s1,0x3
    80004d6a:	f9040713          	addi	a4,s0,-112
    80004d6e:	97ba                	add	a5,a5,a4
    80004d70:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004d74:	00148693          	addi	a3,s1,1
    80004d78:	068e                	slli	a3,a3,0x3
    80004d7a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d7e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d82:	01897663          	bgeu	s2,s8,80004d8e <exec+0x242>
  sz = sz1;
    80004d86:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d8a:	4481                	li	s1,0
    80004d8c:	a059                	j	80004e12 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d8e:	e9040613          	addi	a2,s0,-368
    80004d92:	85ca                	mv	a1,s2
    80004d94:	855e                	mv	a0,s7
    80004d96:	ffffd097          	auipc	ra,0xffffd
    80004d9a:	95c080e7          	jalr	-1700(ra) # 800016f2 <copyout>
    80004d9e:	0a054663          	bltz	a0,80004e4a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004da2:	058ab783          	ld	a5,88(s5)
    80004da6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004daa:	df843783          	ld	a5,-520(s0)
    80004dae:	0007c703          	lbu	a4,0(a5)
    80004db2:	cf11                	beqz	a4,80004dce <exec+0x282>
    80004db4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004db6:	02f00693          	li	a3,47
    80004dba:	a039                	j	80004dc8 <exec+0x27c>
      last = s+1;
    80004dbc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004dc0:	0785                	addi	a5,a5,1
    80004dc2:	fff7c703          	lbu	a4,-1(a5)
    80004dc6:	c701                	beqz	a4,80004dce <exec+0x282>
    if(*s == '/')
    80004dc8:	fed71ce3          	bne	a4,a3,80004dc0 <exec+0x274>
    80004dcc:	bfc5                	j	80004dbc <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004dce:	4641                	li	a2,16
    80004dd0:	df843583          	ld	a1,-520(s0)
    80004dd4:	158a8513          	addi	a0,s5,344
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	05a080e7          	jalr	90(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004de0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004de4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004de8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004dec:	058ab783          	ld	a5,88(s5)
    80004df0:	e6843703          	ld	a4,-408(s0)
    80004df4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004df6:	058ab783          	ld	a5,88(s5)
    80004dfa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004dfe:	85ea                	mv	a1,s10
    80004e00:	ffffd097          	auipc	ra,0xffffd
    80004e04:	d90080e7          	jalr	-624(ra) # 80001b90 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e08:	0004851b          	sext.w	a0,s1
    80004e0c:	bbe1                	j	80004be4 <exec+0x98>
    80004e0e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e12:	e0843583          	ld	a1,-504(s0)
    80004e16:	855e                	mv	a0,s7
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	d78080e7          	jalr	-648(ra) # 80001b90 <proc_freepagetable>
  if(ip){
    80004e20:	da0498e3          	bnez	s1,80004bd0 <exec+0x84>
  return -1;
    80004e24:	557d                	li	a0,-1
    80004e26:	bb7d                	j	80004be4 <exec+0x98>
    80004e28:	e1243423          	sd	s2,-504(s0)
    80004e2c:	b7dd                	j	80004e12 <exec+0x2c6>
    80004e2e:	e1243423          	sd	s2,-504(s0)
    80004e32:	b7c5                	j	80004e12 <exec+0x2c6>
    80004e34:	e1243423          	sd	s2,-504(s0)
    80004e38:	bfe9                	j	80004e12 <exec+0x2c6>
  sz = sz1;
    80004e3a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e3e:	4481                	li	s1,0
    80004e40:	bfc9                	j	80004e12 <exec+0x2c6>
  sz = sz1;
    80004e42:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e46:	4481                	li	s1,0
    80004e48:	b7e9                	j	80004e12 <exec+0x2c6>
  sz = sz1;
    80004e4a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e4e:	4481                	li	s1,0
    80004e50:	b7c9                	j	80004e12 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e52:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e56:	2b05                	addiw	s6,s6,1
    80004e58:	0389899b          	addiw	s3,s3,56
    80004e5c:	e8845783          	lhu	a5,-376(s0)
    80004e60:	e2fb5be3          	bge	s6,a5,80004c96 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e64:	2981                	sext.w	s3,s3
    80004e66:	03800713          	li	a4,56
    80004e6a:	86ce                	mv	a3,s3
    80004e6c:	e1840613          	addi	a2,s0,-488
    80004e70:	4581                	li	a1,0
    80004e72:	8526                	mv	a0,s1
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	a8e080e7          	jalr	-1394(ra) # 80003902 <readi>
    80004e7c:	03800793          	li	a5,56
    80004e80:	f8f517e3          	bne	a0,a5,80004e0e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e84:	e1842783          	lw	a5,-488(s0)
    80004e88:	4705                	li	a4,1
    80004e8a:	fce796e3          	bne	a5,a4,80004e56 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e8e:	e4043603          	ld	a2,-448(s0)
    80004e92:	e3843783          	ld	a5,-456(s0)
    80004e96:	f8f669e3          	bltu	a2,a5,80004e28 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e9a:	e2843783          	ld	a5,-472(s0)
    80004e9e:	963e                	add	a2,a2,a5
    80004ea0:	f8f667e3          	bltu	a2,a5,80004e2e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ea4:	85ca                	mv	a1,s2
    80004ea6:	855e                	mv	a0,s7
    80004ea8:	ffffc097          	auipc	ra,0xffffc
    80004eac:	5fa080e7          	jalr	1530(ra) # 800014a2 <uvmalloc>
    80004eb0:	e0a43423          	sd	a0,-504(s0)
    80004eb4:	d141                	beqz	a0,80004e34 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004eb6:	e2843d03          	ld	s10,-472(s0)
    80004eba:	df043783          	ld	a5,-528(s0)
    80004ebe:	00fd77b3          	and	a5,s10,a5
    80004ec2:	fba1                	bnez	a5,80004e12 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ec4:	e2042d83          	lw	s11,-480(s0)
    80004ec8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ecc:	f80c03e3          	beqz	s8,80004e52 <exec+0x306>
    80004ed0:	8a62                	mv	s4,s8
    80004ed2:	4901                	li	s2,0
    80004ed4:	b345                	j	80004c74 <exec+0x128>

0000000080004ed6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004ed6:	7179                	addi	sp,sp,-48
    80004ed8:	f406                	sd	ra,40(sp)
    80004eda:	f022                	sd	s0,32(sp)
    80004edc:	ec26                	sd	s1,24(sp)
    80004ede:	e84a                	sd	s2,16(sp)
    80004ee0:	1800                	addi	s0,sp,48
    80004ee2:	892e                	mv	s2,a1
    80004ee4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ee6:	fdc40593          	addi	a1,s0,-36
    80004eea:	ffffe097          	auipc	ra,0xffffe
    80004eee:	bf2080e7          	jalr	-1038(ra) # 80002adc <argint>
    80004ef2:	04054063          	bltz	a0,80004f32 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004ef6:	fdc42703          	lw	a4,-36(s0)
    80004efa:	47bd                	li	a5,15
    80004efc:	02e7ed63          	bltu	a5,a4,80004f36 <argfd+0x60>
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	b30080e7          	jalr	-1232(ra) # 80001a30 <myproc>
    80004f08:	fdc42703          	lw	a4,-36(s0)
    80004f0c:	01a70793          	addi	a5,a4,26
    80004f10:	078e                	slli	a5,a5,0x3
    80004f12:	953e                	add	a0,a0,a5
    80004f14:	611c                	ld	a5,0(a0)
    80004f16:	c395                	beqz	a5,80004f3a <argfd+0x64>
    return -1;
  if(pfd)
    80004f18:	00090463          	beqz	s2,80004f20 <argfd+0x4a>
    *pfd = fd;
    80004f1c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f20:	4501                	li	a0,0
  if(pf)
    80004f22:	c091                	beqz	s1,80004f26 <argfd+0x50>
    *pf = f;
    80004f24:	e09c                	sd	a5,0(s1)
}
    80004f26:	70a2                	ld	ra,40(sp)
    80004f28:	7402                	ld	s0,32(sp)
    80004f2a:	64e2                	ld	s1,24(sp)
    80004f2c:	6942                	ld	s2,16(sp)
    80004f2e:	6145                	addi	sp,sp,48
    80004f30:	8082                	ret
    return -1;
    80004f32:	557d                	li	a0,-1
    80004f34:	bfcd                	j	80004f26 <argfd+0x50>
    return -1;
    80004f36:	557d                	li	a0,-1
    80004f38:	b7fd                	j	80004f26 <argfd+0x50>
    80004f3a:	557d                	li	a0,-1
    80004f3c:	b7ed                	j	80004f26 <argfd+0x50>

0000000080004f3e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f3e:	1101                	addi	sp,sp,-32
    80004f40:	ec06                	sd	ra,24(sp)
    80004f42:	e822                	sd	s0,16(sp)
    80004f44:	e426                	sd	s1,8(sp)
    80004f46:	1000                	addi	s0,sp,32
    80004f48:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	ae6080e7          	jalr	-1306(ra) # 80001a30 <myproc>
    80004f52:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f54:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc80d0>
    80004f58:	4501                	li	a0,0
    80004f5a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f5c:	6398                	ld	a4,0(a5)
    80004f5e:	cb19                	beqz	a4,80004f74 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f60:	2505                	addiw	a0,a0,1
    80004f62:	07a1                	addi	a5,a5,8
    80004f64:	fed51ce3          	bne	a0,a3,80004f5c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f68:	557d                	li	a0,-1
}
    80004f6a:	60e2                	ld	ra,24(sp)
    80004f6c:	6442                	ld	s0,16(sp)
    80004f6e:	64a2                	ld	s1,8(sp)
    80004f70:	6105                	addi	sp,sp,32
    80004f72:	8082                	ret
      p->ofile[fd] = f;
    80004f74:	01a50793          	addi	a5,a0,26
    80004f78:	078e                	slli	a5,a5,0x3
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	e204                	sd	s1,0(a2)
      return fd;
    80004f7e:	b7f5                	j	80004f6a <fdalloc+0x2c>

0000000080004f80 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f80:	715d                	addi	sp,sp,-80
    80004f82:	e486                	sd	ra,72(sp)
    80004f84:	e0a2                	sd	s0,64(sp)
    80004f86:	fc26                	sd	s1,56(sp)
    80004f88:	f84a                	sd	s2,48(sp)
    80004f8a:	f44e                	sd	s3,40(sp)
    80004f8c:	f052                	sd	s4,32(sp)
    80004f8e:	ec56                	sd	s5,24(sp)
    80004f90:	0880                	addi	s0,sp,80
    80004f92:	89ae                	mv	s3,a1
    80004f94:	8ab2                	mv	s5,a2
    80004f96:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f98:	fb040593          	addi	a1,s0,-80
    80004f9c:	fffff097          	auipc	ra,0xfffff
    80004fa0:	e86080e7          	jalr	-378(ra) # 80003e22 <nameiparent>
    80004fa4:	892a                	mv	s2,a0
    80004fa6:	12050f63          	beqz	a0,800050e4 <create+0x164>
    return 0;

  ilock(dp);
    80004faa:	ffffe097          	auipc	ra,0xffffe
    80004fae:	6a4080e7          	jalr	1700(ra) # 8000364e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004fb2:	4601                	li	a2,0
    80004fb4:	fb040593          	addi	a1,s0,-80
    80004fb8:	854a                	mv	a0,s2
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	b78080e7          	jalr	-1160(ra) # 80003b32 <dirlookup>
    80004fc2:	84aa                	mv	s1,a0
    80004fc4:	c921                	beqz	a0,80005014 <create+0x94>
    iunlockput(dp);
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	8e8080e7          	jalr	-1816(ra) # 800038b0 <iunlockput>
    ilock(ip);
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ffffe097          	auipc	ra,0xffffe
    80004fd6:	67c080e7          	jalr	1660(ra) # 8000364e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004fda:	2981                	sext.w	s3,s3
    80004fdc:	4789                	li	a5,2
    80004fde:	02f99463          	bne	s3,a5,80005006 <create+0x86>
    80004fe2:	0444d783          	lhu	a5,68(s1)
    80004fe6:	37f9                	addiw	a5,a5,-2
    80004fe8:	17c2                	slli	a5,a5,0x30
    80004fea:	93c1                	srli	a5,a5,0x30
    80004fec:	4705                	li	a4,1
    80004fee:	00f76c63          	bltu	a4,a5,80005006 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	60a6                	ld	ra,72(sp)
    80004ff6:	6406                	ld	s0,64(sp)
    80004ff8:	74e2                	ld	s1,56(sp)
    80004ffa:	7942                	ld	s2,48(sp)
    80004ffc:	79a2                	ld	s3,40(sp)
    80004ffe:	7a02                	ld	s4,32(sp)
    80005000:	6ae2                	ld	s5,24(sp)
    80005002:	6161                	addi	sp,sp,80
    80005004:	8082                	ret
    iunlockput(ip);
    80005006:	8526                	mv	a0,s1
    80005008:	fffff097          	auipc	ra,0xfffff
    8000500c:	8a8080e7          	jalr	-1880(ra) # 800038b0 <iunlockput>
    return 0;
    80005010:	4481                	li	s1,0
    80005012:	b7c5                	j	80004ff2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005014:	85ce                	mv	a1,s3
    80005016:	00092503          	lw	a0,0(s2)
    8000501a:	ffffe097          	auipc	ra,0xffffe
    8000501e:	49c080e7          	jalr	1180(ra) # 800034b6 <ialloc>
    80005022:	84aa                	mv	s1,a0
    80005024:	c529                	beqz	a0,8000506e <create+0xee>
  ilock(ip);
    80005026:	ffffe097          	auipc	ra,0xffffe
    8000502a:	628080e7          	jalr	1576(ra) # 8000364e <ilock>
  ip->major = major;
    8000502e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005032:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005036:	4785                	li	a5,1
    80005038:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000503c:	8526                	mv	a0,s1
    8000503e:	ffffe097          	auipc	ra,0xffffe
    80005042:	546080e7          	jalr	1350(ra) # 80003584 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005046:	2981                	sext.w	s3,s3
    80005048:	4785                	li	a5,1
    8000504a:	02f98a63          	beq	s3,a5,8000507e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000504e:	40d0                	lw	a2,4(s1)
    80005050:	fb040593          	addi	a1,s0,-80
    80005054:	854a                	mv	a0,s2
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	cec080e7          	jalr	-788(ra) # 80003d42 <dirlink>
    8000505e:	06054b63          	bltz	a0,800050d4 <create+0x154>
  iunlockput(dp);
    80005062:	854a                	mv	a0,s2
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	84c080e7          	jalr	-1972(ra) # 800038b0 <iunlockput>
  return ip;
    8000506c:	b759                	j	80004ff2 <create+0x72>
    panic("create: ialloc");
    8000506e:	00003517          	auipc	a0,0x3
    80005072:	74250513          	addi	a0,a0,1858 # 800087b0 <syscalls+0x2a0>
    80005076:	ffffb097          	auipc	ra,0xffffb
    8000507a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    8000507e:	04a95783          	lhu	a5,74(s2)
    80005082:	2785                	addiw	a5,a5,1
    80005084:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005088:	854a                	mv	a0,s2
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	4fa080e7          	jalr	1274(ra) # 80003584 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005092:	40d0                	lw	a2,4(s1)
    80005094:	00003597          	auipc	a1,0x3
    80005098:	72c58593          	addi	a1,a1,1836 # 800087c0 <syscalls+0x2b0>
    8000509c:	8526                	mv	a0,s1
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	ca4080e7          	jalr	-860(ra) # 80003d42 <dirlink>
    800050a6:	00054f63          	bltz	a0,800050c4 <create+0x144>
    800050aa:	00492603          	lw	a2,4(s2)
    800050ae:	00003597          	auipc	a1,0x3
    800050b2:	71a58593          	addi	a1,a1,1818 # 800087c8 <syscalls+0x2b8>
    800050b6:	8526                	mv	a0,s1
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	c8a080e7          	jalr	-886(ra) # 80003d42 <dirlink>
    800050c0:	f80557e3          	bgez	a0,8000504e <create+0xce>
      panic("create dots");
    800050c4:	00003517          	auipc	a0,0x3
    800050c8:	70c50513          	addi	a0,a0,1804 # 800087d0 <syscalls+0x2c0>
    800050cc:	ffffb097          	auipc	ra,0xffffb
    800050d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    panic("create: dirlink");
    800050d4:	00003517          	auipc	a0,0x3
    800050d8:	70c50513          	addi	a0,a0,1804 # 800087e0 <syscalls+0x2d0>
    800050dc:	ffffb097          	auipc	ra,0xffffb
    800050e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>
    return 0;
    800050e4:	84aa                	mv	s1,a0
    800050e6:	b731                	j	80004ff2 <create+0x72>

00000000800050e8 <sys_dup>:
{
    800050e8:	7179                	addi	sp,sp,-48
    800050ea:	f406                	sd	ra,40(sp)
    800050ec:	f022                	sd	s0,32(sp)
    800050ee:	ec26                	sd	s1,24(sp)
    800050f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050f2:	fd840613          	addi	a2,s0,-40
    800050f6:	4581                	li	a1,0
    800050f8:	4501                	li	a0,0
    800050fa:	00000097          	auipc	ra,0x0
    800050fe:	ddc080e7          	jalr	-548(ra) # 80004ed6 <argfd>
    return -1;
    80005102:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005104:	02054363          	bltz	a0,8000512a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005108:	fd843503          	ld	a0,-40(s0)
    8000510c:	00000097          	auipc	ra,0x0
    80005110:	e32080e7          	jalr	-462(ra) # 80004f3e <fdalloc>
    80005114:	84aa                	mv	s1,a0
    return -1;
    80005116:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005118:	00054963          	bltz	a0,8000512a <sys_dup+0x42>
  filedup(f);
    8000511c:	fd843503          	ld	a0,-40(s0)
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	37a080e7          	jalr	890(ra) # 8000449a <filedup>
  return fd;
    80005128:	87a6                	mv	a5,s1
}
    8000512a:	853e                	mv	a0,a5
    8000512c:	70a2                	ld	ra,40(sp)
    8000512e:	7402                	ld	s0,32(sp)
    80005130:	64e2                	ld	s1,24(sp)
    80005132:	6145                	addi	sp,sp,48
    80005134:	8082                	ret

0000000080005136 <sys_read>:
{
    80005136:	7179                	addi	sp,sp,-48
    80005138:	f406                	sd	ra,40(sp)
    8000513a:	f022                	sd	s0,32(sp)
    8000513c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000513e:	fe840613          	addi	a2,s0,-24
    80005142:	4581                	li	a1,0
    80005144:	4501                	li	a0,0
    80005146:	00000097          	auipc	ra,0x0
    8000514a:	d90080e7          	jalr	-624(ra) # 80004ed6 <argfd>
    return -1;
    8000514e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005150:	04054163          	bltz	a0,80005192 <sys_read+0x5c>
    80005154:	fe440593          	addi	a1,s0,-28
    80005158:	4509                	li	a0,2
    8000515a:	ffffe097          	auipc	ra,0xffffe
    8000515e:	982080e7          	jalr	-1662(ra) # 80002adc <argint>
    return -1;
    80005162:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005164:	02054763          	bltz	a0,80005192 <sys_read+0x5c>
    80005168:	fd840593          	addi	a1,s0,-40
    8000516c:	4505                	li	a0,1
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	990080e7          	jalr	-1648(ra) # 80002afe <argaddr>
    return -1;
    80005176:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005178:	00054d63          	bltz	a0,80005192 <sys_read+0x5c>
  return fileread(f, p, n);
    8000517c:	fe442603          	lw	a2,-28(s0)
    80005180:	fd843583          	ld	a1,-40(s0)
    80005184:	fe843503          	ld	a0,-24(s0)
    80005188:	fffff097          	auipc	ra,0xfffff
    8000518c:	49e080e7          	jalr	1182(ra) # 80004626 <fileread>
    80005190:	87aa                	mv	a5,a0
}
    80005192:	853e                	mv	a0,a5
    80005194:	70a2                	ld	ra,40(sp)
    80005196:	7402                	ld	s0,32(sp)
    80005198:	6145                	addi	sp,sp,48
    8000519a:	8082                	ret

000000008000519c <sys_write>:
{
    8000519c:	7179                	addi	sp,sp,-48
    8000519e:	f406                	sd	ra,40(sp)
    800051a0:	f022                	sd	s0,32(sp)
    800051a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a4:	fe840613          	addi	a2,s0,-24
    800051a8:	4581                	li	a1,0
    800051aa:	4501                	li	a0,0
    800051ac:	00000097          	auipc	ra,0x0
    800051b0:	d2a080e7          	jalr	-726(ra) # 80004ed6 <argfd>
    return -1;
    800051b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b6:	04054163          	bltz	a0,800051f8 <sys_write+0x5c>
    800051ba:	fe440593          	addi	a1,s0,-28
    800051be:	4509                	li	a0,2
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	91c080e7          	jalr	-1764(ra) # 80002adc <argint>
    return -1;
    800051c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ca:	02054763          	bltz	a0,800051f8 <sys_write+0x5c>
    800051ce:	fd840593          	addi	a1,s0,-40
    800051d2:	4505                	li	a0,1
    800051d4:	ffffe097          	auipc	ra,0xffffe
    800051d8:	92a080e7          	jalr	-1750(ra) # 80002afe <argaddr>
    return -1;
    800051dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051de:	00054d63          	bltz	a0,800051f8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800051e2:	fe442603          	lw	a2,-28(s0)
    800051e6:	fd843583          	ld	a1,-40(s0)
    800051ea:	fe843503          	ld	a0,-24(s0)
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	4fa080e7          	jalr	1274(ra) # 800046e8 <filewrite>
    800051f6:	87aa                	mv	a5,a0
}
    800051f8:	853e                	mv	a0,a5
    800051fa:	70a2                	ld	ra,40(sp)
    800051fc:	7402                	ld	s0,32(sp)
    800051fe:	6145                	addi	sp,sp,48
    80005200:	8082                	ret

0000000080005202 <sys_close>:
{
    80005202:	1101                	addi	sp,sp,-32
    80005204:	ec06                	sd	ra,24(sp)
    80005206:	e822                	sd	s0,16(sp)
    80005208:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000520a:	fe040613          	addi	a2,s0,-32
    8000520e:	fec40593          	addi	a1,s0,-20
    80005212:	4501                	li	a0,0
    80005214:	00000097          	auipc	ra,0x0
    80005218:	cc2080e7          	jalr	-830(ra) # 80004ed6 <argfd>
    return -1;
    8000521c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000521e:	02054463          	bltz	a0,80005246 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005222:	ffffd097          	auipc	ra,0xffffd
    80005226:	80e080e7          	jalr	-2034(ra) # 80001a30 <myproc>
    8000522a:	fec42783          	lw	a5,-20(s0)
    8000522e:	07e9                	addi	a5,a5,26
    80005230:	078e                	slli	a5,a5,0x3
    80005232:	97aa                	add	a5,a5,a0
    80005234:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005238:	fe043503          	ld	a0,-32(s0)
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	2b0080e7          	jalr	688(ra) # 800044ec <fileclose>
  return 0;
    80005244:	4781                	li	a5,0
}
    80005246:	853e                	mv	a0,a5
    80005248:	60e2                	ld	ra,24(sp)
    8000524a:	6442                	ld	s0,16(sp)
    8000524c:	6105                	addi	sp,sp,32
    8000524e:	8082                	ret

0000000080005250 <sys_fstat>:
{
    80005250:	1101                	addi	sp,sp,-32
    80005252:	ec06                	sd	ra,24(sp)
    80005254:	e822                	sd	s0,16(sp)
    80005256:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005258:	fe840613          	addi	a2,s0,-24
    8000525c:	4581                	li	a1,0
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	c76080e7          	jalr	-906(ra) # 80004ed6 <argfd>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000526a:	02054563          	bltz	a0,80005294 <sys_fstat+0x44>
    8000526e:	fe040593          	addi	a1,s0,-32
    80005272:	4505                	li	a0,1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	88a080e7          	jalr	-1910(ra) # 80002afe <argaddr>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000527e:	00054b63          	bltz	a0,80005294 <sys_fstat+0x44>
  return filestat(f, st);
    80005282:	fe043583          	ld	a1,-32(s0)
    80005286:	fe843503          	ld	a0,-24(s0)
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	32a080e7          	jalr	810(ra) # 800045b4 <filestat>
    80005292:	87aa                	mv	a5,a0
}
    80005294:	853e                	mv	a0,a5
    80005296:	60e2                	ld	ra,24(sp)
    80005298:	6442                	ld	s0,16(sp)
    8000529a:	6105                	addi	sp,sp,32
    8000529c:	8082                	ret

000000008000529e <sys_link>:
{
    8000529e:	7169                	addi	sp,sp,-304
    800052a0:	f606                	sd	ra,296(sp)
    800052a2:	f222                	sd	s0,288(sp)
    800052a4:	ee26                	sd	s1,280(sp)
    800052a6:	ea4a                	sd	s2,272(sp)
    800052a8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052aa:	08000613          	li	a2,128
    800052ae:	ed040593          	addi	a1,s0,-304
    800052b2:	4501                	li	a0,0
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	86c080e7          	jalr	-1940(ra) # 80002b20 <argstr>
    return -1;
    800052bc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052be:	10054e63          	bltz	a0,800053da <sys_link+0x13c>
    800052c2:	08000613          	li	a2,128
    800052c6:	f5040593          	addi	a1,s0,-176
    800052ca:	4505                	li	a0,1
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	854080e7          	jalr	-1964(ra) # 80002b20 <argstr>
    return -1;
    800052d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800052d6:	10054263          	bltz	a0,800053da <sys_link+0x13c>
  begin_op();
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	d46080e7          	jalr	-698(ra) # 80004020 <begin_op>
  if((ip = namei(old)) == 0){
    800052e2:	ed040513          	addi	a0,s0,-304
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	b1e080e7          	jalr	-1250(ra) # 80003e04 <namei>
    800052ee:	84aa                	mv	s1,a0
    800052f0:	c551                	beqz	a0,8000537c <sys_link+0xde>
  ilock(ip);
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	35c080e7          	jalr	860(ra) # 8000364e <ilock>
  if(ip->type == T_DIR){
    800052fa:	04449703          	lh	a4,68(s1)
    800052fe:	4785                	li	a5,1
    80005300:	08f70463          	beq	a4,a5,80005388 <sys_link+0xea>
  ip->nlink++;
    80005304:	04a4d783          	lhu	a5,74(s1)
    80005308:	2785                	addiw	a5,a5,1
    8000530a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000530e:	8526                	mv	a0,s1
    80005310:	ffffe097          	auipc	ra,0xffffe
    80005314:	274080e7          	jalr	628(ra) # 80003584 <iupdate>
  iunlock(ip);
    80005318:	8526                	mv	a0,s1
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	3f6080e7          	jalr	1014(ra) # 80003710 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005322:	fd040593          	addi	a1,s0,-48
    80005326:	f5040513          	addi	a0,s0,-176
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	af8080e7          	jalr	-1288(ra) # 80003e22 <nameiparent>
    80005332:	892a                	mv	s2,a0
    80005334:	c935                	beqz	a0,800053a8 <sys_link+0x10a>
  ilock(dp);
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	318080e7          	jalr	792(ra) # 8000364e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000533e:	00092703          	lw	a4,0(s2)
    80005342:	409c                	lw	a5,0(s1)
    80005344:	04f71d63          	bne	a4,a5,8000539e <sys_link+0x100>
    80005348:	40d0                	lw	a2,4(s1)
    8000534a:	fd040593          	addi	a1,s0,-48
    8000534e:	854a                	mv	a0,s2
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	9f2080e7          	jalr	-1550(ra) # 80003d42 <dirlink>
    80005358:	04054363          	bltz	a0,8000539e <sys_link+0x100>
  iunlockput(dp);
    8000535c:	854a                	mv	a0,s2
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	552080e7          	jalr	1362(ra) # 800038b0 <iunlockput>
  iput(ip);
    80005366:	8526                	mv	a0,s1
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	4a0080e7          	jalr	1184(ra) # 80003808 <iput>
  end_op();
    80005370:	fffff097          	auipc	ra,0xfffff
    80005374:	d30080e7          	jalr	-720(ra) # 800040a0 <end_op>
  return 0;
    80005378:	4781                	li	a5,0
    8000537a:	a085                	j	800053da <sys_link+0x13c>
    end_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	d24080e7          	jalr	-732(ra) # 800040a0 <end_op>
    return -1;
    80005384:	57fd                	li	a5,-1
    80005386:	a891                	j	800053da <sys_link+0x13c>
    iunlockput(ip);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	526080e7          	jalr	1318(ra) # 800038b0 <iunlockput>
    end_op();
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	d0e080e7          	jalr	-754(ra) # 800040a0 <end_op>
    return -1;
    8000539a:	57fd                	li	a5,-1
    8000539c:	a83d                	j	800053da <sys_link+0x13c>
    iunlockput(dp);
    8000539e:	854a                	mv	a0,s2
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	510080e7          	jalr	1296(ra) # 800038b0 <iunlockput>
  ilock(ip);
    800053a8:	8526                	mv	a0,s1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	2a4080e7          	jalr	676(ra) # 8000364e <ilock>
  ip->nlink--;
    800053b2:	04a4d783          	lhu	a5,74(s1)
    800053b6:	37fd                	addiw	a5,a5,-1
    800053b8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	1c6080e7          	jalr	454(ra) # 80003584 <iupdate>
  iunlockput(ip);
    800053c6:	8526                	mv	a0,s1
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	4e8080e7          	jalr	1256(ra) # 800038b0 <iunlockput>
  end_op();
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	cd0080e7          	jalr	-816(ra) # 800040a0 <end_op>
  return -1;
    800053d8:	57fd                	li	a5,-1
}
    800053da:	853e                	mv	a0,a5
    800053dc:	70b2                	ld	ra,296(sp)
    800053de:	7412                	ld	s0,288(sp)
    800053e0:	64f2                	ld	s1,280(sp)
    800053e2:	6952                	ld	s2,272(sp)
    800053e4:	6155                	addi	sp,sp,304
    800053e6:	8082                	ret

00000000800053e8 <sys_unlink>:
{
    800053e8:	7151                	addi	sp,sp,-240
    800053ea:	f586                	sd	ra,232(sp)
    800053ec:	f1a2                	sd	s0,224(sp)
    800053ee:	eda6                	sd	s1,216(sp)
    800053f0:	e9ca                	sd	s2,208(sp)
    800053f2:	e5ce                	sd	s3,200(sp)
    800053f4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053f6:	08000613          	li	a2,128
    800053fa:	f3040593          	addi	a1,s0,-208
    800053fe:	4501                	li	a0,0
    80005400:	ffffd097          	auipc	ra,0xffffd
    80005404:	720080e7          	jalr	1824(ra) # 80002b20 <argstr>
    80005408:	18054163          	bltz	a0,8000558a <sys_unlink+0x1a2>
  begin_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c14080e7          	jalr	-1004(ra) # 80004020 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005414:	fb040593          	addi	a1,s0,-80
    80005418:	f3040513          	addi	a0,s0,-208
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	a06080e7          	jalr	-1530(ra) # 80003e22 <nameiparent>
    80005424:	84aa                	mv	s1,a0
    80005426:	c979                	beqz	a0,800054fc <sys_unlink+0x114>
  ilock(dp);
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	226080e7          	jalr	550(ra) # 8000364e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005430:	00003597          	auipc	a1,0x3
    80005434:	39058593          	addi	a1,a1,912 # 800087c0 <syscalls+0x2b0>
    80005438:	fb040513          	addi	a0,s0,-80
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	6dc080e7          	jalr	1756(ra) # 80003b18 <namecmp>
    80005444:	14050a63          	beqz	a0,80005598 <sys_unlink+0x1b0>
    80005448:	00003597          	auipc	a1,0x3
    8000544c:	38058593          	addi	a1,a1,896 # 800087c8 <syscalls+0x2b8>
    80005450:	fb040513          	addi	a0,s0,-80
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	6c4080e7          	jalr	1732(ra) # 80003b18 <namecmp>
    8000545c:	12050e63          	beqz	a0,80005598 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005460:	f2c40613          	addi	a2,s0,-212
    80005464:	fb040593          	addi	a1,s0,-80
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	6c8080e7          	jalr	1736(ra) # 80003b32 <dirlookup>
    80005472:	892a                	mv	s2,a0
    80005474:	12050263          	beqz	a0,80005598 <sys_unlink+0x1b0>
  ilock(ip);
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	1d6080e7          	jalr	470(ra) # 8000364e <ilock>
  if(ip->nlink < 1)
    80005480:	04a91783          	lh	a5,74(s2)
    80005484:	08f05263          	blez	a5,80005508 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005488:	04491703          	lh	a4,68(s2)
    8000548c:	4785                	li	a5,1
    8000548e:	08f70563          	beq	a4,a5,80005518 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005492:	4641                	li	a2,16
    80005494:	4581                	li	a1,0
    80005496:	fc040513          	addi	a0,s0,-64
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	846080e7          	jalr	-1978(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054a2:	4741                	li	a4,16
    800054a4:	f2c42683          	lw	a3,-212(s0)
    800054a8:	fc040613          	addi	a2,s0,-64
    800054ac:	4581                	li	a1,0
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	54a080e7          	jalr	1354(ra) # 800039fa <writei>
    800054b8:	47c1                	li	a5,16
    800054ba:	0af51563          	bne	a0,a5,80005564 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800054be:	04491703          	lh	a4,68(s2)
    800054c2:	4785                	li	a5,1
    800054c4:	0af70863          	beq	a4,a5,80005574 <sys_unlink+0x18c>
  iunlockput(dp);
    800054c8:	8526                	mv	a0,s1
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	3e6080e7          	jalr	998(ra) # 800038b0 <iunlockput>
  ip->nlink--;
    800054d2:	04a95783          	lhu	a5,74(s2)
    800054d6:	37fd                	addiw	a5,a5,-1
    800054d8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800054dc:	854a                	mv	a0,s2
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	0a6080e7          	jalr	166(ra) # 80003584 <iupdate>
  iunlockput(ip);
    800054e6:	854a                	mv	a0,s2
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	3c8080e7          	jalr	968(ra) # 800038b0 <iunlockput>
  end_op();
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	bb0080e7          	jalr	-1104(ra) # 800040a0 <end_op>
  return 0;
    800054f8:	4501                	li	a0,0
    800054fa:	a84d                	j	800055ac <sys_unlink+0x1c4>
    end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	ba4080e7          	jalr	-1116(ra) # 800040a0 <end_op>
    return -1;
    80005504:	557d                	li	a0,-1
    80005506:	a05d                	j	800055ac <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005508:	00003517          	auipc	a0,0x3
    8000550c:	2e850513          	addi	a0,a0,744 # 800087f0 <syscalls+0x2e0>
    80005510:	ffffb097          	auipc	ra,0xffffb
    80005514:	02e080e7          	jalr	46(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005518:	04c92703          	lw	a4,76(s2)
    8000551c:	02000793          	li	a5,32
    80005520:	f6e7f9e3          	bgeu	a5,a4,80005492 <sys_unlink+0xaa>
    80005524:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005528:	4741                	li	a4,16
    8000552a:	86ce                	mv	a3,s3
    8000552c:	f1840613          	addi	a2,s0,-232
    80005530:	4581                	li	a1,0
    80005532:	854a                	mv	a0,s2
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	3ce080e7          	jalr	974(ra) # 80003902 <readi>
    8000553c:	47c1                	li	a5,16
    8000553e:	00f51b63          	bne	a0,a5,80005554 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005542:	f1845783          	lhu	a5,-232(s0)
    80005546:	e7a1                	bnez	a5,8000558e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005548:	29c1                	addiw	s3,s3,16
    8000554a:	04c92783          	lw	a5,76(s2)
    8000554e:	fcf9ede3          	bltu	s3,a5,80005528 <sys_unlink+0x140>
    80005552:	b781                	j	80005492 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005554:	00003517          	auipc	a0,0x3
    80005558:	2b450513          	addi	a0,a0,692 # 80008808 <syscalls+0x2f8>
    8000555c:	ffffb097          	auipc	ra,0xffffb
    80005560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005564:	00003517          	auipc	a0,0x3
    80005568:	2bc50513          	addi	a0,a0,700 # 80008820 <syscalls+0x310>
    8000556c:	ffffb097          	auipc	ra,0xffffb
    80005570:	fd2080e7          	jalr	-46(ra) # 8000053e <panic>
    dp->nlink--;
    80005574:	04a4d783          	lhu	a5,74(s1)
    80005578:	37fd                	addiw	a5,a5,-1
    8000557a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	004080e7          	jalr	4(ra) # 80003584 <iupdate>
    80005588:	b781                	j	800054c8 <sys_unlink+0xe0>
    return -1;
    8000558a:	557d                	li	a0,-1
    8000558c:	a005                	j	800055ac <sys_unlink+0x1c4>
    iunlockput(ip);
    8000558e:	854a                	mv	a0,s2
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	320080e7          	jalr	800(ra) # 800038b0 <iunlockput>
  iunlockput(dp);
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	316080e7          	jalr	790(ra) # 800038b0 <iunlockput>
  end_op();
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	afe080e7          	jalr	-1282(ra) # 800040a0 <end_op>
  return -1;
    800055aa:	557d                	li	a0,-1
}
    800055ac:	70ae                	ld	ra,232(sp)
    800055ae:	740e                	ld	s0,224(sp)
    800055b0:	64ee                	ld	s1,216(sp)
    800055b2:	694e                	ld	s2,208(sp)
    800055b4:	69ae                	ld	s3,200(sp)
    800055b6:	616d                	addi	sp,sp,240
    800055b8:	8082                	ret

00000000800055ba <sys_open>:

uint64
sys_open(void)
{
    800055ba:	7131                	addi	sp,sp,-192
    800055bc:	fd06                	sd	ra,184(sp)
    800055be:	f922                	sd	s0,176(sp)
    800055c0:	f526                	sd	s1,168(sp)
    800055c2:	f14a                	sd	s2,160(sp)
    800055c4:	ed4e                	sd	s3,152(sp)
    800055c6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055c8:	08000613          	li	a2,128
    800055cc:	f5040593          	addi	a1,s0,-176
    800055d0:	4501                	li	a0,0
    800055d2:	ffffd097          	auipc	ra,0xffffd
    800055d6:	54e080e7          	jalr	1358(ra) # 80002b20 <argstr>
    return -1;
    800055da:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800055dc:	0c054163          	bltz	a0,8000569e <sys_open+0xe4>
    800055e0:	f4c40593          	addi	a1,s0,-180
    800055e4:	4505                	li	a0,1
    800055e6:	ffffd097          	auipc	ra,0xffffd
    800055ea:	4f6080e7          	jalr	1270(ra) # 80002adc <argint>
    800055ee:	0a054863          	bltz	a0,8000569e <sys_open+0xe4>

  begin_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	a2e080e7          	jalr	-1490(ra) # 80004020 <begin_op>

  if(omode & O_CREATE){
    800055fa:	f4c42783          	lw	a5,-180(s0)
    800055fe:	2007f793          	andi	a5,a5,512
    80005602:	cbdd                	beqz	a5,800056b8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005604:	4681                	li	a3,0
    80005606:	4601                	li	a2,0
    80005608:	4589                	li	a1,2
    8000560a:	f5040513          	addi	a0,s0,-176
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	972080e7          	jalr	-1678(ra) # 80004f80 <create>
    80005616:	892a                	mv	s2,a0
    if(ip == 0){
    80005618:	c959                	beqz	a0,800056ae <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000561a:	04491703          	lh	a4,68(s2)
    8000561e:	478d                	li	a5,3
    80005620:	00f71763          	bne	a4,a5,8000562e <sys_open+0x74>
    80005624:	04695703          	lhu	a4,70(s2)
    80005628:	47a5                	li	a5,9
    8000562a:	0ce7ec63          	bltu	a5,a4,80005702 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	e02080e7          	jalr	-510(ra) # 80004430 <filealloc>
    80005636:	89aa                	mv	s3,a0
    80005638:	10050263          	beqz	a0,8000573c <sys_open+0x182>
    8000563c:	00000097          	auipc	ra,0x0
    80005640:	902080e7          	jalr	-1790(ra) # 80004f3e <fdalloc>
    80005644:	84aa                	mv	s1,a0
    80005646:	0e054663          	bltz	a0,80005732 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000564a:	04491703          	lh	a4,68(s2)
    8000564e:	478d                	li	a5,3
    80005650:	0cf70463          	beq	a4,a5,80005718 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005654:	4789                	li	a5,2
    80005656:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000565a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000565e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005662:	f4c42783          	lw	a5,-180(s0)
    80005666:	0017c713          	xori	a4,a5,1
    8000566a:	8b05                	andi	a4,a4,1
    8000566c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005670:	0037f713          	andi	a4,a5,3
    80005674:	00e03733          	snez	a4,a4
    80005678:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000567c:	4007f793          	andi	a5,a5,1024
    80005680:	c791                	beqz	a5,8000568c <sys_open+0xd2>
    80005682:	04491703          	lh	a4,68(s2)
    80005686:	4789                	li	a5,2
    80005688:	08f70f63          	beq	a4,a5,80005726 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	082080e7          	jalr	130(ra) # 80003710 <iunlock>
  end_op();
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	a0a080e7          	jalr	-1526(ra) # 800040a0 <end_op>

  return fd;
}
    8000569e:	8526                	mv	a0,s1
    800056a0:	70ea                	ld	ra,184(sp)
    800056a2:	744a                	ld	s0,176(sp)
    800056a4:	74aa                	ld	s1,168(sp)
    800056a6:	790a                	ld	s2,160(sp)
    800056a8:	69ea                	ld	s3,152(sp)
    800056aa:	6129                	addi	sp,sp,192
    800056ac:	8082                	ret
      end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	9f2080e7          	jalr	-1550(ra) # 800040a0 <end_op>
      return -1;
    800056b6:	b7e5                	j	8000569e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800056b8:	f5040513          	addi	a0,s0,-176
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	748080e7          	jalr	1864(ra) # 80003e04 <namei>
    800056c4:	892a                	mv	s2,a0
    800056c6:	c905                	beqz	a0,800056f6 <sys_open+0x13c>
    ilock(ip);
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	f86080e7          	jalr	-122(ra) # 8000364e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800056d0:	04491703          	lh	a4,68(s2)
    800056d4:	4785                	li	a5,1
    800056d6:	f4f712e3          	bne	a4,a5,8000561a <sys_open+0x60>
    800056da:	f4c42783          	lw	a5,-180(s0)
    800056de:	dba1                	beqz	a5,8000562e <sys_open+0x74>
      iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	1ce080e7          	jalr	462(ra) # 800038b0 <iunlockput>
      end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	9b6080e7          	jalr	-1610(ra) # 800040a0 <end_op>
      return -1;
    800056f2:	54fd                	li	s1,-1
    800056f4:	b76d                	j	8000569e <sys_open+0xe4>
      end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	9aa080e7          	jalr	-1622(ra) # 800040a0 <end_op>
      return -1;
    800056fe:	54fd                	li	s1,-1
    80005700:	bf79                	j	8000569e <sys_open+0xe4>
    iunlockput(ip);
    80005702:	854a                	mv	a0,s2
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	1ac080e7          	jalr	428(ra) # 800038b0 <iunlockput>
    end_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	994080e7          	jalr	-1644(ra) # 800040a0 <end_op>
    return -1;
    80005714:	54fd                	li	s1,-1
    80005716:	b761                	j	8000569e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005718:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000571c:	04691783          	lh	a5,70(s2)
    80005720:	02f99223          	sh	a5,36(s3)
    80005724:	bf2d                	j	8000565e <sys_open+0xa4>
    itrunc(ip);
    80005726:	854a                	mv	a0,s2
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	034080e7          	jalr	52(ra) # 8000375c <itrunc>
    80005730:	bfb1                	j	8000568c <sys_open+0xd2>
      fileclose(f);
    80005732:	854e                	mv	a0,s3
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	db8080e7          	jalr	-584(ra) # 800044ec <fileclose>
    iunlockput(ip);
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	172080e7          	jalr	370(ra) # 800038b0 <iunlockput>
    end_op();
    80005746:	fffff097          	auipc	ra,0xfffff
    8000574a:	95a080e7          	jalr	-1702(ra) # 800040a0 <end_op>
    return -1;
    8000574e:	54fd                	li	s1,-1
    80005750:	b7b9                	j	8000569e <sys_open+0xe4>

0000000080005752 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005752:	7175                	addi	sp,sp,-144
    80005754:	e506                	sd	ra,136(sp)
    80005756:	e122                	sd	s0,128(sp)
    80005758:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	8c6080e7          	jalr	-1850(ra) # 80004020 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005762:	08000613          	li	a2,128
    80005766:	f7040593          	addi	a1,s0,-144
    8000576a:	4501                	li	a0,0
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	3b4080e7          	jalr	948(ra) # 80002b20 <argstr>
    80005774:	02054963          	bltz	a0,800057a6 <sys_mkdir+0x54>
    80005778:	4681                	li	a3,0
    8000577a:	4601                	li	a2,0
    8000577c:	4585                	li	a1,1
    8000577e:	f7040513          	addi	a0,s0,-144
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	7fe080e7          	jalr	2046(ra) # 80004f80 <create>
    8000578a:	cd11                	beqz	a0,800057a6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	124080e7          	jalr	292(ra) # 800038b0 <iunlockput>
  end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	90c080e7          	jalr	-1780(ra) # 800040a0 <end_op>
  return 0;
    8000579c:	4501                	li	a0,0
}
    8000579e:	60aa                	ld	ra,136(sp)
    800057a0:	640a                	ld	s0,128(sp)
    800057a2:	6149                	addi	sp,sp,144
    800057a4:	8082                	ret
    end_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	8fa080e7          	jalr	-1798(ra) # 800040a0 <end_op>
    return -1;
    800057ae:	557d                	li	a0,-1
    800057b0:	b7fd                	j	8000579e <sys_mkdir+0x4c>

00000000800057b2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800057b2:	7135                	addi	sp,sp,-160
    800057b4:	ed06                	sd	ra,152(sp)
    800057b6:	e922                	sd	s0,144(sp)
    800057b8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	866080e7          	jalr	-1946(ra) # 80004020 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057c2:	08000613          	li	a2,128
    800057c6:	f7040593          	addi	a1,s0,-144
    800057ca:	4501                	li	a0,0
    800057cc:	ffffd097          	auipc	ra,0xffffd
    800057d0:	354080e7          	jalr	852(ra) # 80002b20 <argstr>
    800057d4:	04054a63          	bltz	a0,80005828 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800057d8:	f6c40593          	addi	a1,s0,-148
    800057dc:	4505                	li	a0,1
    800057de:	ffffd097          	auipc	ra,0xffffd
    800057e2:	2fe080e7          	jalr	766(ra) # 80002adc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057e6:	04054163          	bltz	a0,80005828 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057ea:	f6840593          	addi	a1,s0,-152
    800057ee:	4509                	li	a0,2
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	2ec080e7          	jalr	748(ra) # 80002adc <argint>
     argint(1, &major) < 0 ||
    800057f8:	02054863          	bltz	a0,80005828 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057fc:	f6841683          	lh	a3,-152(s0)
    80005800:	f6c41603          	lh	a2,-148(s0)
    80005804:	458d                	li	a1,3
    80005806:	f7040513          	addi	a0,s0,-144
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	776080e7          	jalr	1910(ra) # 80004f80 <create>
     argint(2, &minor) < 0 ||
    80005812:	c919                	beqz	a0,80005828 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	09c080e7          	jalr	156(ra) # 800038b0 <iunlockput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	884080e7          	jalr	-1916(ra) # 800040a0 <end_op>
  return 0;
    80005824:	4501                	li	a0,0
    80005826:	a031                	j	80005832 <sys_mknod+0x80>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	878080e7          	jalr	-1928(ra) # 800040a0 <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
}
    80005832:	60ea                	ld	ra,152(sp)
    80005834:	644a                	ld	s0,144(sp)
    80005836:	610d                	addi	sp,sp,160
    80005838:	8082                	ret

000000008000583a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000583a:	7135                	addi	sp,sp,-160
    8000583c:	ed06                	sd	ra,152(sp)
    8000583e:	e922                	sd	s0,144(sp)
    80005840:	e526                	sd	s1,136(sp)
    80005842:	e14a                	sd	s2,128(sp)
    80005844:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005846:	ffffc097          	auipc	ra,0xffffc
    8000584a:	1ea080e7          	jalr	490(ra) # 80001a30 <myproc>
    8000584e:	892a                	mv	s2,a0
  
  begin_op();
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	7d0080e7          	jalr	2000(ra) # 80004020 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005858:	08000613          	li	a2,128
    8000585c:	f6040593          	addi	a1,s0,-160
    80005860:	4501                	li	a0,0
    80005862:	ffffd097          	auipc	ra,0xffffd
    80005866:	2be080e7          	jalr	702(ra) # 80002b20 <argstr>
    8000586a:	04054b63          	bltz	a0,800058c0 <sys_chdir+0x86>
    8000586e:	f6040513          	addi	a0,s0,-160
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	592080e7          	jalr	1426(ra) # 80003e04 <namei>
    8000587a:	84aa                	mv	s1,a0
    8000587c:	c131                	beqz	a0,800058c0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	dd0080e7          	jalr	-560(ra) # 8000364e <ilock>
  if(ip->type != T_DIR){
    80005886:	04449703          	lh	a4,68(s1)
    8000588a:	4785                	li	a5,1
    8000588c:	04f71063          	bne	a4,a5,800058cc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005890:	8526                	mv	a0,s1
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	e7e080e7          	jalr	-386(ra) # 80003710 <iunlock>
  iput(p->cwd);
    8000589a:	15093503          	ld	a0,336(s2)
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	f6a080e7          	jalr	-150(ra) # 80003808 <iput>
  end_op();
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	7fa080e7          	jalr	2042(ra) # 800040a0 <end_op>
  p->cwd = ip;
    800058ae:	14993823          	sd	s1,336(s2)
  return 0;
    800058b2:	4501                	li	a0,0
}
    800058b4:	60ea                	ld	ra,152(sp)
    800058b6:	644a                	ld	s0,144(sp)
    800058b8:	64aa                	ld	s1,136(sp)
    800058ba:	690a                	ld	s2,128(sp)
    800058bc:	610d                	addi	sp,sp,160
    800058be:	8082                	ret
    end_op();
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	7e0080e7          	jalr	2016(ra) # 800040a0 <end_op>
    return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	b7ed                	j	800058b4 <sys_chdir+0x7a>
    iunlockput(ip);
    800058cc:	8526                	mv	a0,s1
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	fe2080e7          	jalr	-30(ra) # 800038b0 <iunlockput>
    end_op();
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	7ca080e7          	jalr	1994(ra) # 800040a0 <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	bfd1                	j	800058b4 <sys_chdir+0x7a>

00000000800058e2 <sys_exec>:

uint64
sys_exec(void)
{
    800058e2:	7145                	addi	sp,sp,-464
    800058e4:	e786                	sd	ra,456(sp)
    800058e6:	e3a2                	sd	s0,448(sp)
    800058e8:	ff26                	sd	s1,440(sp)
    800058ea:	fb4a                	sd	s2,432(sp)
    800058ec:	f74e                	sd	s3,424(sp)
    800058ee:	f352                	sd	s4,416(sp)
    800058f0:	ef56                	sd	s5,408(sp)
    800058f2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058f4:	08000613          	li	a2,128
    800058f8:	f4040593          	addi	a1,s0,-192
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	222080e7          	jalr	546(ra) # 80002b20 <argstr>
    return -1;
    80005906:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005908:	0c054a63          	bltz	a0,800059dc <sys_exec+0xfa>
    8000590c:	e3840593          	addi	a1,s0,-456
    80005910:	4505                	li	a0,1
    80005912:	ffffd097          	auipc	ra,0xffffd
    80005916:	1ec080e7          	jalr	492(ra) # 80002afe <argaddr>
    8000591a:	0c054163          	bltz	a0,800059dc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000591e:	10000613          	li	a2,256
    80005922:	4581                	li	a1,0
    80005924:	e4040513          	addi	a0,s0,-448
    80005928:	ffffb097          	auipc	ra,0xffffb
    8000592c:	3b8080e7          	jalr	952(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005930:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005934:	89a6                	mv	s3,s1
    80005936:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005938:	02000a13          	li	s4,32
    8000593c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005940:	00391513          	slli	a0,s2,0x3
    80005944:	e3040593          	addi	a1,s0,-464
    80005948:	e3843783          	ld	a5,-456(s0)
    8000594c:	953e                	add	a0,a0,a5
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	0f4080e7          	jalr	244(ra) # 80002a42 <fetchaddr>
    80005956:	02054a63          	bltz	a0,8000598a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000595a:	e3043783          	ld	a5,-464(s0)
    8000595e:	c3b9                	beqz	a5,800059a4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	194080e7          	jalr	404(ra) # 80000af4 <kalloc>
    80005968:	85aa                	mv	a1,a0
    8000596a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000596e:	cd11                	beqz	a0,8000598a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005970:	6611                	lui	a2,0x4
    80005972:	e3043503          	ld	a0,-464(s0)
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	11e080e7          	jalr	286(ra) # 80002a94 <fetchstr>
    8000597e:	00054663          	bltz	a0,8000598a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005982:	0905                	addi	s2,s2,1
    80005984:	09a1                	addi	s3,s3,8
    80005986:	fb491be3          	bne	s2,s4,8000593c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000598a:	10048913          	addi	s2,s1,256
    8000598e:	6088                	ld	a0,0(s1)
    80005990:	c529                	beqz	a0,800059da <sys_exec+0xf8>
    kfree(argv[i]);
    80005992:	ffffb097          	auipc	ra,0xffffb
    80005996:	066080e7          	jalr	102(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000599a:	04a1                	addi	s1,s1,8
    8000599c:	ff2499e3          	bne	s1,s2,8000598e <sys_exec+0xac>
  return -1;
    800059a0:	597d                	li	s2,-1
    800059a2:	a82d                	j	800059dc <sys_exec+0xfa>
      argv[i] = 0;
    800059a4:	0a8e                	slli	s5,s5,0x3
    800059a6:	fc040793          	addi	a5,s0,-64
    800059aa:	9abe                	add	s5,s5,a5
    800059ac:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800059b0:	e4040593          	addi	a1,s0,-448
    800059b4:	f4040513          	addi	a0,s0,-192
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	194080e7          	jalr	404(ra) # 80004b4c <exec>
    800059c0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059c2:	10048993          	addi	s3,s1,256
    800059c6:	6088                	ld	a0,0(s1)
    800059c8:	c911                	beqz	a0,800059dc <sys_exec+0xfa>
    kfree(argv[i]);
    800059ca:	ffffb097          	auipc	ra,0xffffb
    800059ce:	02e080e7          	jalr	46(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059d2:	04a1                	addi	s1,s1,8
    800059d4:	ff3499e3          	bne	s1,s3,800059c6 <sys_exec+0xe4>
    800059d8:	a011                	j	800059dc <sys_exec+0xfa>
  return -1;
    800059da:	597d                	li	s2,-1
}
    800059dc:	854a                	mv	a0,s2
    800059de:	60be                	ld	ra,456(sp)
    800059e0:	641e                	ld	s0,448(sp)
    800059e2:	74fa                	ld	s1,440(sp)
    800059e4:	795a                	ld	s2,432(sp)
    800059e6:	79ba                	ld	s3,424(sp)
    800059e8:	7a1a                	ld	s4,416(sp)
    800059ea:	6afa                	ld	s5,408(sp)
    800059ec:	6179                	addi	sp,sp,464
    800059ee:	8082                	ret

00000000800059f0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059f0:	7139                	addi	sp,sp,-64
    800059f2:	fc06                	sd	ra,56(sp)
    800059f4:	f822                	sd	s0,48(sp)
    800059f6:	f426                	sd	s1,40(sp)
    800059f8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059fa:	ffffc097          	auipc	ra,0xffffc
    800059fe:	036080e7          	jalr	54(ra) # 80001a30 <myproc>
    80005a02:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a04:	fd840593          	addi	a1,s0,-40
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	0f4080e7          	jalr	244(ra) # 80002afe <argaddr>
    return -1;
    80005a12:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a14:	0e054063          	bltz	a0,80005af4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a18:	fc840593          	addi	a1,s0,-56
    80005a1c:	fd040513          	addi	a0,s0,-48
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	dfc080e7          	jalr	-516(ra) # 8000481c <pipealloc>
    return -1;
    80005a28:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a2a:	0c054563          	bltz	a0,80005af4 <sys_pipe+0x104>
  fd0 = -1;
    80005a2e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a32:	fd043503          	ld	a0,-48(s0)
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	508080e7          	jalr	1288(ra) # 80004f3e <fdalloc>
    80005a3e:	fca42223          	sw	a0,-60(s0)
    80005a42:	08054c63          	bltz	a0,80005ada <sys_pipe+0xea>
    80005a46:	fc843503          	ld	a0,-56(s0)
    80005a4a:	fffff097          	auipc	ra,0xfffff
    80005a4e:	4f4080e7          	jalr	1268(ra) # 80004f3e <fdalloc>
    80005a52:	fca42023          	sw	a0,-64(s0)
    80005a56:	06054863          	bltz	a0,80005ac6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a5a:	4691                	li	a3,4
    80005a5c:	fc440613          	addi	a2,s0,-60
    80005a60:	fd843583          	ld	a1,-40(s0)
    80005a64:	68a8                	ld	a0,80(s1)
    80005a66:	ffffc097          	auipc	ra,0xffffc
    80005a6a:	c8c080e7          	jalr	-884(ra) # 800016f2 <copyout>
    80005a6e:	02054063          	bltz	a0,80005a8e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a72:	4691                	li	a3,4
    80005a74:	fc040613          	addi	a2,s0,-64
    80005a78:	fd843583          	ld	a1,-40(s0)
    80005a7c:	0591                	addi	a1,a1,4
    80005a7e:	68a8                	ld	a0,80(s1)
    80005a80:	ffffc097          	auipc	ra,0xffffc
    80005a84:	c72080e7          	jalr	-910(ra) # 800016f2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a88:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a8a:	06055563          	bgez	a0,80005af4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a8e:	fc442783          	lw	a5,-60(s0)
    80005a92:	07e9                	addi	a5,a5,26
    80005a94:	078e                	slli	a5,a5,0x3
    80005a96:	97a6                	add	a5,a5,s1
    80005a98:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a9c:	fc042503          	lw	a0,-64(s0)
    80005aa0:	0569                	addi	a0,a0,26
    80005aa2:	050e                	slli	a0,a0,0x3
    80005aa4:	9526                	add	a0,a0,s1
    80005aa6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005aaa:	fd043503          	ld	a0,-48(s0)
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	a3e080e7          	jalr	-1474(ra) # 800044ec <fileclose>
    fileclose(wf);
    80005ab6:	fc843503          	ld	a0,-56(s0)
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	a32080e7          	jalr	-1486(ra) # 800044ec <fileclose>
    return -1;
    80005ac2:	57fd                	li	a5,-1
    80005ac4:	a805                	j	80005af4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ac6:	fc442783          	lw	a5,-60(s0)
    80005aca:	0007c863          	bltz	a5,80005ada <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ace:	01a78513          	addi	a0,a5,26
    80005ad2:	050e                	slli	a0,a0,0x3
    80005ad4:	9526                	add	a0,a0,s1
    80005ad6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ada:	fd043503          	ld	a0,-48(s0)
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	a0e080e7          	jalr	-1522(ra) # 800044ec <fileclose>
    fileclose(wf);
    80005ae6:	fc843503          	ld	a0,-56(s0)
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	a02080e7          	jalr	-1534(ra) # 800044ec <fileclose>
    return -1;
    80005af2:	57fd                	li	a5,-1
}
    80005af4:	853e                	mv	a0,a5
    80005af6:	70e2                	ld	ra,56(sp)
    80005af8:	7442                	ld	s0,48(sp)
    80005afa:	74a2                	ld	s1,40(sp)
    80005afc:	6121                	addi	sp,sp,64
    80005afe:	8082                	ret

0000000080005b00 <kernelvec>:
    80005b00:	7111                	addi	sp,sp,-256
    80005b02:	e006                	sd	ra,0(sp)
    80005b04:	e40a                	sd	sp,8(sp)
    80005b06:	e80e                	sd	gp,16(sp)
    80005b08:	ec12                	sd	tp,24(sp)
    80005b0a:	f016                	sd	t0,32(sp)
    80005b0c:	f41a                	sd	t1,40(sp)
    80005b0e:	f81e                	sd	t2,48(sp)
    80005b10:	fc22                	sd	s0,56(sp)
    80005b12:	e0a6                	sd	s1,64(sp)
    80005b14:	e4aa                	sd	a0,72(sp)
    80005b16:	e8ae                	sd	a1,80(sp)
    80005b18:	ecb2                	sd	a2,88(sp)
    80005b1a:	f0b6                	sd	a3,96(sp)
    80005b1c:	f4ba                	sd	a4,104(sp)
    80005b1e:	f8be                	sd	a5,112(sp)
    80005b20:	fcc2                	sd	a6,120(sp)
    80005b22:	e146                	sd	a7,128(sp)
    80005b24:	e54a                	sd	s2,136(sp)
    80005b26:	e94e                	sd	s3,144(sp)
    80005b28:	ed52                	sd	s4,152(sp)
    80005b2a:	f156                	sd	s5,160(sp)
    80005b2c:	f55a                	sd	s6,168(sp)
    80005b2e:	f95e                	sd	s7,176(sp)
    80005b30:	fd62                	sd	s8,184(sp)
    80005b32:	e1e6                	sd	s9,192(sp)
    80005b34:	e5ea                	sd	s10,200(sp)
    80005b36:	e9ee                	sd	s11,208(sp)
    80005b38:	edf2                	sd	t3,216(sp)
    80005b3a:	f1f6                	sd	t4,224(sp)
    80005b3c:	f5fa                	sd	t5,232(sp)
    80005b3e:	f9fe                	sd	t6,240(sp)
    80005b40:	dcffc0ef          	jal	ra,8000290e <kerneltrap>
    80005b44:	6082                	ld	ra,0(sp)
    80005b46:	6122                	ld	sp,8(sp)
    80005b48:	61c2                	ld	gp,16(sp)
    80005b4a:	7282                	ld	t0,32(sp)
    80005b4c:	7322                	ld	t1,40(sp)
    80005b4e:	73c2                	ld	t2,48(sp)
    80005b50:	7462                	ld	s0,56(sp)
    80005b52:	6486                	ld	s1,64(sp)
    80005b54:	6526                	ld	a0,72(sp)
    80005b56:	65c6                	ld	a1,80(sp)
    80005b58:	6666                	ld	a2,88(sp)
    80005b5a:	7686                	ld	a3,96(sp)
    80005b5c:	7726                	ld	a4,104(sp)
    80005b5e:	77c6                	ld	a5,112(sp)
    80005b60:	7866                	ld	a6,120(sp)
    80005b62:	688a                	ld	a7,128(sp)
    80005b64:	692a                	ld	s2,136(sp)
    80005b66:	69ca                	ld	s3,144(sp)
    80005b68:	6a6a                	ld	s4,152(sp)
    80005b6a:	7a8a                	ld	s5,160(sp)
    80005b6c:	7b2a                	ld	s6,168(sp)
    80005b6e:	7bca                	ld	s7,176(sp)
    80005b70:	7c6a                	ld	s8,184(sp)
    80005b72:	6c8e                	ld	s9,192(sp)
    80005b74:	6d2e                	ld	s10,200(sp)
    80005b76:	6dce                	ld	s11,208(sp)
    80005b78:	6e6e                	ld	t3,216(sp)
    80005b7a:	7e8e                	ld	t4,224(sp)
    80005b7c:	7f2e                	ld	t5,232(sp)
    80005b7e:	7fce                	ld	t6,240(sp)
    80005b80:	6111                	addi	sp,sp,256
    80005b82:	10200073          	sret
    80005b86:	00000013          	nop
    80005b8a:	00000013          	nop
    80005b8e:	0001                	nop

0000000080005b90 <timervec>:
    80005b90:	34051573          	csrrw	a0,mscratch,a0
    80005b94:	e10c                	sd	a1,0(a0)
    80005b96:	e510                	sd	a2,8(a0)
    80005b98:	e914                	sd	a3,16(a0)
    80005b9a:	6d0c                	ld	a1,24(a0)
    80005b9c:	7110                	ld	a2,32(a0)
    80005b9e:	6194                	ld	a3,0(a1)
    80005ba0:	96b2                	add	a3,a3,a2
    80005ba2:	e194                	sd	a3,0(a1)
    80005ba4:	4589                	li	a1,2
    80005ba6:	14459073          	csrw	sip,a1
    80005baa:	6914                	ld	a3,16(a0)
    80005bac:	6510                	ld	a2,8(a0)
    80005bae:	610c                	ld	a1,0(a0)
    80005bb0:	34051573          	csrrw	a0,mscratch,a0
    80005bb4:	30200073          	mret
	...

0000000080005bba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005bba:	1141                	addi	sp,sp,-16
    80005bbc:	e422                	sd	s0,8(sp)
    80005bbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005bc0:	0c0007b7          	lui	a5,0xc000
    80005bc4:	4705                	li	a4,1
    80005bc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005bc8:	c3d8                	sw	a4,4(a5)
}
    80005bca:	6422                	ld	s0,8(sp)
    80005bcc:	0141                	addi	sp,sp,16
    80005bce:	8082                	ret

0000000080005bd0 <plicinithart>:

void
plicinithart(void)
{
    80005bd0:	1141                	addi	sp,sp,-16
    80005bd2:	e406                	sd	ra,8(sp)
    80005bd4:	e022                	sd	s0,0(sp)
    80005bd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bd8:	ffffc097          	auipc	ra,0xffffc
    80005bdc:	e2c080e7          	jalr	-468(ra) # 80001a04 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005be0:	0085171b          	slliw	a4,a0,0x8
    80005be4:	0c0027b7          	lui	a5,0xc002
    80005be8:	97ba                	add	a5,a5,a4
    80005bea:	40200713          	li	a4,1026
    80005bee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bf2:	00d5151b          	slliw	a0,a0,0xd
    80005bf6:	0c2017b7          	lui	a5,0xc201
    80005bfa:	953e                	add	a0,a0,a5
    80005bfc:	00052023          	sw	zero,0(a0)
}
    80005c00:	60a2                	ld	ra,8(sp)
    80005c02:	6402                	ld	s0,0(sp)
    80005c04:	0141                	addi	sp,sp,16
    80005c06:	8082                	ret

0000000080005c08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c08:	1141                	addi	sp,sp,-16
    80005c0a:	e406                	sd	ra,8(sp)
    80005c0c:	e022                	sd	s0,0(sp)
    80005c0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c10:	ffffc097          	auipc	ra,0xffffc
    80005c14:	df4080e7          	jalr	-524(ra) # 80001a04 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c18:	00d5179b          	slliw	a5,a0,0xd
    80005c1c:	0c201537          	lui	a0,0xc201
    80005c20:	953e                	add	a0,a0,a5
  return irq;
}
    80005c22:	4148                	lw	a0,4(a0)
    80005c24:	60a2                	ld	ra,8(sp)
    80005c26:	6402                	ld	s0,0(sp)
    80005c28:	0141                	addi	sp,sp,16
    80005c2a:	8082                	ret

0000000080005c2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c2c:	1101                	addi	sp,sp,-32
    80005c2e:	ec06                	sd	ra,24(sp)
    80005c30:	e822                	sd	s0,16(sp)
    80005c32:	e426                	sd	s1,8(sp)
    80005c34:	1000                	addi	s0,sp,32
    80005c36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c38:	ffffc097          	auipc	ra,0xffffc
    80005c3c:	dcc080e7          	jalr	-564(ra) # 80001a04 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c40:	00d5151b          	slliw	a0,a0,0xd
    80005c44:	0c2017b7          	lui	a5,0xc201
    80005c48:	97aa                	add	a5,a5,a0
    80005c4a:	c3c4                	sw	s1,4(a5)
}
    80005c4c:	60e2                	ld	ra,24(sp)
    80005c4e:	6442                	ld	s0,16(sp)
    80005c50:	64a2                	ld	s1,8(sp)
    80005c52:	6105                	addi	sp,sp,32
    80005c54:	8082                	ret

0000000080005c56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c56:	1141                	addi	sp,sp,-16
    80005c58:	e406                	sd	ra,8(sp)
    80005c5a:	e022                	sd	s0,0(sp)
    80005c5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c5e:	479d                	li	a5,7
    80005c60:	06a7c963          	blt	a5,a0,80005cd2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c64:	00022797          	auipc	a5,0x22
    80005c68:	39c78793          	addi	a5,a5,924 # 80028000 <disk>
    80005c6c:	00a78733          	add	a4,a5,a0
    80005c70:	67a1                	lui	a5,0x8
    80005c72:	97ba                	add	a5,a5,a4
    80005c74:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005c78:	e7ad                	bnez	a5,80005ce2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c7a:	00451793          	slli	a5,a0,0x4
    80005c7e:	0002a717          	auipc	a4,0x2a
    80005c82:	38270713          	addi	a4,a4,898 # 80030000 <disk+0x8000>
    80005c86:	6314                	ld	a3,0(a4)
    80005c88:	96be                	add	a3,a3,a5
    80005c8a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c8e:	6314                	ld	a3,0(a4)
    80005c90:	96be                	add	a3,a3,a5
    80005c92:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c96:	6314                	ld	a3,0(a4)
    80005c98:	96be                	add	a3,a3,a5
    80005c9a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c9e:	6318                	ld	a4,0(a4)
    80005ca0:	97ba                	add	a5,a5,a4
    80005ca2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ca6:	00022797          	auipc	a5,0x22
    80005caa:	35a78793          	addi	a5,a5,858 # 80028000 <disk>
    80005cae:	97aa                	add	a5,a5,a0
    80005cb0:	6521                	lui	a0,0x8
    80005cb2:	953e                	add	a0,a0,a5
    80005cb4:	4785                	li	a5,1
    80005cb6:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005cba:	0002a517          	auipc	a0,0x2a
    80005cbe:	35e50513          	addi	a0,a0,862 # 80030018 <disk+0x8018>
    80005cc2:	ffffc097          	auipc	ra,0xffffc
    80005cc6:	5b6080e7          	jalr	1462(ra) # 80002278 <wakeup>
}
    80005cca:	60a2                	ld	ra,8(sp)
    80005ccc:	6402                	ld	s0,0(sp)
    80005cce:	0141                	addi	sp,sp,16
    80005cd0:	8082                	ret
    panic("free_desc 1");
    80005cd2:	00003517          	auipc	a0,0x3
    80005cd6:	b5e50513          	addi	a0,a0,-1186 # 80008830 <syscalls+0x320>
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	864080e7          	jalr	-1948(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ce2:	00003517          	auipc	a0,0x3
    80005ce6:	b5e50513          	addi	a0,a0,-1186 # 80008840 <syscalls+0x330>
    80005cea:	ffffb097          	auipc	ra,0xffffb
    80005cee:	854080e7          	jalr	-1964(ra) # 8000053e <panic>

0000000080005cf2 <virtio_disk_init>:
{
    80005cf2:	1101                	addi	sp,sp,-32
    80005cf4:	ec06                	sd	ra,24(sp)
    80005cf6:	e822                	sd	s0,16(sp)
    80005cf8:	e426                	sd	s1,8(sp)
    80005cfa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cfc:	00003597          	auipc	a1,0x3
    80005d00:	b5458593          	addi	a1,a1,-1196 # 80008850 <syscalls+0x340>
    80005d04:	0002a517          	auipc	a0,0x2a
    80005d08:	42450513          	addi	a0,a0,1060 # 80030128 <disk+0x8128>
    80005d0c:	ffffb097          	auipc	ra,0xffffb
    80005d10:	e48080e7          	jalr	-440(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d14:	100047b7          	lui	a5,0x10004
    80005d18:	4398                	lw	a4,0(a5)
    80005d1a:	2701                	sext.w	a4,a4
    80005d1c:	747277b7          	lui	a5,0x74727
    80005d20:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d24:	0ef71163          	bne	a4,a5,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d28:	100047b7          	lui	a5,0x10004
    80005d2c:	43dc                	lw	a5,4(a5)
    80005d2e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d30:	4705                	li	a4,1
    80005d32:	0ce79a63          	bne	a5,a4,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d36:	100047b7          	lui	a5,0x10004
    80005d3a:	479c                	lw	a5,8(a5)
    80005d3c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d3e:	4709                	li	a4,2
    80005d40:	0ce79363          	bne	a5,a4,80005e06 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d44:	100047b7          	lui	a5,0x10004
    80005d48:	47d8                	lw	a4,12(a5)
    80005d4a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d4c:	554d47b7          	lui	a5,0x554d4
    80005d50:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d54:	0af71963          	bne	a4,a5,80005e06 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d58:	100047b7          	lui	a5,0x10004
    80005d5c:	4705                	li	a4,1
    80005d5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d60:	470d                	li	a4,3
    80005d62:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d64:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d66:	c7ffe737          	lui	a4,0xc7ffe
    80005d6a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fca75f>
    80005d6e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d70:	2701                	sext.w	a4,a4
    80005d72:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d74:	472d                	li	a4,11
    80005d76:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d78:	473d                	li	a4,15
    80005d7a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d7c:	6711                	lui	a4,0x4
    80005d7e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d80:	0207a823          	sw	zero,48(a5) # 10004030 <_entry-0x6fffbfd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d84:	5bdc                	lw	a5,52(a5)
    80005d86:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d88:	c7d9                	beqz	a5,80005e16 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d8a:	471d                	li	a4,7
    80005d8c:	08f77d63          	bgeu	a4,a5,80005e26 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d90:	100044b7          	lui	s1,0x10004
    80005d94:	47a1                	li	a5,8
    80005d96:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d98:	6621                	lui	a2,0x8
    80005d9a:	4581                	li	a1,0
    80005d9c:	00022517          	auipc	a0,0x22
    80005da0:	26450513          	addi	a0,a0,612 # 80028000 <disk>
    80005da4:	ffffb097          	auipc	ra,0xffffb
    80005da8:	f3c080e7          	jalr	-196(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005dac:	00022717          	auipc	a4,0x22
    80005db0:	25470713          	addi	a4,a4,596 # 80028000 <disk>
    80005db4:	00e75793          	srli	a5,a4,0xe
    80005db8:	2781                	sext.w	a5,a5
    80005dba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005dbc:	0002a797          	auipc	a5,0x2a
    80005dc0:	24478793          	addi	a5,a5,580 # 80030000 <disk+0x8000>
    80005dc4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005dc6:	00022717          	auipc	a4,0x22
    80005dca:	2ba70713          	addi	a4,a4,698 # 80028080 <disk+0x80>
    80005dce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005dd0:	00026717          	auipc	a4,0x26
    80005dd4:	23070713          	addi	a4,a4,560 # 8002c000 <disk+0x4000>
    80005dd8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005dda:	4705                	li	a4,1
    80005ddc:	00e78c23          	sb	a4,24(a5)
    80005de0:	00e78ca3          	sb	a4,25(a5)
    80005de4:	00e78d23          	sb	a4,26(a5)
    80005de8:	00e78da3          	sb	a4,27(a5)
    80005dec:	00e78e23          	sb	a4,28(a5)
    80005df0:	00e78ea3          	sb	a4,29(a5)
    80005df4:	00e78f23          	sb	a4,30(a5)
    80005df8:	00e78fa3          	sb	a4,31(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret
    panic("could not find virtio disk");
    80005e06:	00003517          	auipc	a0,0x3
    80005e0a:	a5a50513          	addi	a0,a0,-1446 # 80008860 <syscalls+0x350>
    80005e0e:	ffffa097          	auipc	ra,0xffffa
    80005e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005e16:	00003517          	auipc	a0,0x3
    80005e1a:	a6a50513          	addi	a0,a0,-1430 # 80008880 <syscalls+0x370>
    80005e1e:	ffffa097          	auipc	ra,0xffffa
    80005e22:	720080e7          	jalr	1824(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005e26:	00003517          	auipc	a0,0x3
    80005e2a:	a7a50513          	addi	a0,a0,-1414 # 800088a0 <syscalls+0x390>
    80005e2e:	ffffa097          	auipc	ra,0xffffa
    80005e32:	710080e7          	jalr	1808(ra) # 8000053e <panic>

0000000080005e36 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e36:	7159                	addi	sp,sp,-112
    80005e38:	f486                	sd	ra,104(sp)
    80005e3a:	f0a2                	sd	s0,96(sp)
    80005e3c:	eca6                	sd	s1,88(sp)
    80005e3e:	e8ca                	sd	s2,80(sp)
    80005e40:	e4ce                	sd	s3,72(sp)
    80005e42:	e0d2                	sd	s4,64(sp)
    80005e44:	fc56                	sd	s5,56(sp)
    80005e46:	f85a                	sd	s6,48(sp)
    80005e48:	f45e                	sd	s7,40(sp)
    80005e4a:	f062                	sd	s8,32(sp)
    80005e4c:	ec66                	sd	s9,24(sp)
    80005e4e:	e86a                	sd	s10,16(sp)
    80005e50:	1880                	addi	s0,sp,112
    80005e52:	892a                	mv	s2,a0
    80005e54:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e56:	00c52c83          	lw	s9,12(a0)
    80005e5a:	001c9c9b          	slliw	s9,s9,0x1
    80005e5e:	1c82                	slli	s9,s9,0x20
    80005e60:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e64:	0002a517          	auipc	a0,0x2a
    80005e68:	2c450513          	addi	a0,a0,708 # 80030128 <disk+0x8128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e74:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e76:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e78:	00022b97          	auipc	s7,0x22
    80005e7c:	188b8b93          	addi	s7,s7,392 # 80028000 <disk>
    80005e80:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80005e82:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e84:	8a4e                	mv	s4,s3
    80005e86:	a051                	j	80005f0a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e88:	00fb86b3          	add	a3,s7,a5
    80005e8c:	96da                	add	a3,a3,s6
    80005e8e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e92:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e94:	0207c563          	bltz	a5,80005ebe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e98:	2485                	addiw	s1,s1,1
    80005e9a:	0711                	addi	a4,a4,4
    80005e9c:	25548463          	beq	s1,s5,800060e4 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80005ea0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ea2:	0002a697          	auipc	a3,0x2a
    80005ea6:	17668693          	addi	a3,a3,374 # 80030018 <disk+0x8018>
    80005eaa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005eac:	0006c583          	lbu	a1,0(a3)
    80005eb0:	fde1                	bnez	a1,80005e88 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005eb2:	2785                	addiw	a5,a5,1
    80005eb4:	0685                	addi	a3,a3,1
    80005eb6:	ff879be3          	bne	a5,s8,80005eac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005eba:	57fd                	li	a5,-1
    80005ebc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005ebe:	02905a63          	blez	s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ec2:	f9042503          	lw	a0,-112(s0)
    80005ec6:	00000097          	auipc	ra,0x0
    80005eca:	d90080e7          	jalr	-624(ra) # 80005c56 <free_desc>
      for(int j = 0; j < i; j++)
    80005ece:	4785                	li	a5,1
    80005ed0:	0297d163          	bge	a5,s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ed4:	f9442503          	lw	a0,-108(s0)
    80005ed8:	00000097          	auipc	ra,0x0
    80005edc:	d7e080e7          	jalr	-642(ra) # 80005c56 <free_desc>
      for(int j = 0; j < i; j++)
    80005ee0:	4789                	li	a5,2
    80005ee2:	0097d863          	bge	a5,s1,80005ef2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ee6:	f9842503          	lw	a0,-104(s0)
    80005eea:	00000097          	auipc	ra,0x0
    80005eee:	d6c080e7          	jalr	-660(ra) # 80005c56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ef2:	0002a597          	auipc	a1,0x2a
    80005ef6:	23658593          	addi	a1,a1,566 # 80030128 <disk+0x8128>
    80005efa:	0002a517          	auipc	a0,0x2a
    80005efe:	11e50513          	addi	a0,a0,286 # 80030018 <disk+0x8018>
    80005f02:	ffffc097          	auipc	ra,0xffffc
    80005f06:	1ea080e7          	jalr	490(ra) # 800020ec <sleep>
  for(int i = 0; i < 3; i++){
    80005f0a:	f9040713          	addi	a4,s0,-112
    80005f0e:	84ce                	mv	s1,s3
    80005f10:	bf41                	j	80005ea0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005f12:	6705                	lui	a4,0x1
    80005f14:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005f18:	972e                	add	a4,a4,a1
    80005f1a:	0712                	slli	a4,a4,0x4
    80005f1c:	00022697          	auipc	a3,0x22
    80005f20:	0e468693          	addi	a3,a3,228 # 80028000 <disk>
    80005f24:	9736                	add	a4,a4,a3
    80005f26:	4685                	li	a3,1
    80005f28:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005f2c:	6705                	lui	a4,0x1
    80005f2e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005f32:	972e                	add	a4,a4,a1
    80005f34:	0712                	slli	a4,a4,0x4
    80005f36:	00022697          	auipc	a3,0x22
    80005f3a:	0ca68693          	addi	a3,a3,202 # 80028000 <disk>
    80005f3e:	9736                	add	a4,a4,a3
    80005f40:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f44:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f48:	7661                	lui	a2,0xffff8
    80005f4a:	963e                	add	a2,a2,a5
    80005f4c:	0002a697          	auipc	a3,0x2a
    80005f50:	0b468693          	addi	a3,a3,180 # 80030000 <disk+0x8000>
    80005f54:	6298                	ld	a4,0(a3)
    80005f56:	9732                	add	a4,a4,a2
    80005f58:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f5a:	6298                	ld	a4,0(a3)
    80005f5c:	9732                	add	a4,a4,a2
    80005f5e:	4541                	li	a0,16
    80005f60:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f62:	6298                	ld	a4,0(a3)
    80005f64:	9732                	add	a4,a4,a2
    80005f66:	4505                	li	a0,1
    80005f68:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f6c:	f9442703          	lw	a4,-108(s0)
    80005f70:	6288                	ld	a0,0(a3)
    80005f72:	962a                	add	a2,a2,a0
    80005f74:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc400e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f78:	0712                	slli	a4,a4,0x4
    80005f7a:	6290                	ld	a2,0(a3)
    80005f7c:	963a                	add	a2,a2,a4
    80005f7e:	05890513          	addi	a0,s2,88
    80005f82:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f84:	6294                	ld	a3,0(a3)
    80005f86:	96ba                	add	a3,a3,a4
    80005f88:	40000613          	li	a2,1024
    80005f8c:	c690                	sw	a2,8(a3)
  if(write)
    80005f8e:	140d0263          	beqz	s10,800060d2 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f92:	0002a697          	auipc	a3,0x2a
    80005f96:	06e6b683          	ld	a3,110(a3) # 80030000 <disk+0x8000>
    80005f9a:	96ba                	add	a3,a3,a4
    80005f9c:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fa0:	00022817          	auipc	a6,0x22
    80005fa4:	06080813          	addi	a6,a6,96 # 80028000 <disk>
    80005fa8:	0002a697          	auipc	a3,0x2a
    80005fac:	05868693          	addi	a3,a3,88 # 80030000 <disk+0x8000>
    80005fb0:	6290                	ld	a2,0(a3)
    80005fb2:	963a                	add	a2,a2,a4
    80005fb4:	00c65503          	lhu	a0,12(a2)
    80005fb8:	00156513          	ori	a0,a0,1
    80005fbc:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005fc0:	f9842603          	lw	a2,-104(s0)
    80005fc4:	6288                	ld	a0,0(a3)
    80005fc6:	972a                	add	a4,a4,a0
    80005fc8:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005fcc:	6705                	lui	a4,0x1
    80005fce:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005fd2:	972e                	add	a4,a4,a1
    80005fd4:	0712                	slli	a4,a4,0x4
    80005fd6:	9742                	add	a4,a4,a6
    80005fd8:	557d                	li	a0,-1
    80005fda:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fde:	0612                	slli	a2,a2,0x4
    80005fe0:	6288                	ld	a0,0(a3)
    80005fe2:	9532                	add	a0,a0,a2
    80005fe4:	03078793          	addi	a5,a5,48
    80005fe8:	97c2                	add	a5,a5,a6
    80005fea:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005fec:	629c                	ld	a5,0(a3)
    80005fee:	97b2                	add	a5,a5,a2
    80005ff0:	4505                	li	a0,1
    80005ff2:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ff4:	629c                	ld	a5,0(a3)
    80005ff6:	97b2                	add	a5,a5,a2
    80005ff8:	4809                	li	a6,2
    80005ffa:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005ffe:	629c                	ld	a5,0(a3)
    80006000:	963e                	add	a2,a2,a5
    80006002:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006006:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    8000600a:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000600e:	6698                	ld	a4,8(a3)
    80006010:	00275783          	lhu	a5,2(a4)
    80006014:	8b9d                	andi	a5,a5,7
    80006016:	0786                	slli	a5,a5,0x1
    80006018:	97ba                	add	a5,a5,a4
    8000601a:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    8000601e:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006022:	6698                	ld	a4,8(a3)
    80006024:	00275783          	lhu	a5,2(a4)
    80006028:	2785                	addiw	a5,a5,1
    8000602a:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000602e:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006032:	100047b7          	lui	a5,0x10004
    80006036:	0407a823          	sw	zero,80(a5) # 10004050 <_entry-0x6fffbfb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000603a:	00492703          	lw	a4,4(s2)
    8000603e:	4785                	li	a5,1
    80006040:	02f71163          	bne	a4,a5,80006062 <virtio_disk_rw+0x22c>
    sleep(b, &disk.vdisk_lock);
    80006044:	0002a997          	auipc	s3,0x2a
    80006048:	0e498993          	addi	s3,s3,228 # 80030128 <disk+0x8128>
  while(b->disk == 1) {
    8000604c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000604e:	85ce                	mv	a1,s3
    80006050:	854a                	mv	a0,s2
    80006052:	ffffc097          	auipc	ra,0xffffc
    80006056:	09a080e7          	jalr	154(ra) # 800020ec <sleep>
  while(b->disk == 1) {
    8000605a:	00492783          	lw	a5,4(s2)
    8000605e:	fe9788e3          	beq	a5,s1,8000604e <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006062:	f9042903          	lw	s2,-112(s0)
    80006066:	6785                	lui	a5,0x1
    80006068:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000606c:	97ca                	add	a5,a5,s2
    8000606e:	0792                	slli	a5,a5,0x4
    80006070:	00022717          	auipc	a4,0x22
    80006074:	f9070713          	addi	a4,a4,-112 # 80028000 <disk>
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000607e:	0002a997          	auipc	s3,0x2a
    80006082:	f8298993          	addi	s3,s3,-126 # 80030000 <disk+0x8000>
    80006086:	00491713          	slli	a4,s2,0x4
    8000608a:	0009b783          	ld	a5,0(s3)
    8000608e:	97ba                	add	a5,a5,a4
    80006090:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006094:	854a                	mv	a0,s2
    80006096:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000609a:	00000097          	auipc	ra,0x0
    8000609e:	bbc080e7          	jalr	-1092(ra) # 80005c56 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800060a2:	8885                	andi	s1,s1,1
    800060a4:	f0ed                	bnez	s1,80006086 <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060a6:	0002a517          	auipc	a0,0x2a
    800060aa:	08250513          	addi	a0,a0,130 # 80030128 <disk+0x8128>
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
}
    800060b6:	70a6                	ld	ra,104(sp)
    800060b8:	7406                	ld	s0,96(sp)
    800060ba:	64e6                	ld	s1,88(sp)
    800060bc:	6946                	ld	s2,80(sp)
    800060be:	69a6                	ld	s3,72(sp)
    800060c0:	6a06                	ld	s4,64(sp)
    800060c2:	7ae2                	ld	s5,56(sp)
    800060c4:	7b42                	ld	s6,48(sp)
    800060c6:	7ba2                	ld	s7,40(sp)
    800060c8:	7c02                	ld	s8,32(sp)
    800060ca:	6ce2                	ld	s9,24(sp)
    800060cc:	6d42                	ld	s10,16(sp)
    800060ce:	6165                	addi	sp,sp,112
    800060d0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060d2:	0002a697          	auipc	a3,0x2a
    800060d6:	f2e6b683          	ld	a3,-210(a3) # 80030000 <disk+0x8000>
    800060da:	96ba                	add	a3,a3,a4
    800060dc:	4609                	li	a2,2
    800060de:	00c69623          	sh	a2,12(a3)
    800060e2:	bd7d                	j	80005fa0 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e4:	f9042583          	lw	a1,-112(s0)
    800060e8:	6785                	lui	a5,0x1
    800060ea:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800060ee:	97ae                	add	a5,a5,a1
    800060f0:	0792                	slli	a5,a5,0x4
    800060f2:	00022517          	auipc	a0,0x22
    800060f6:	fb650513          	addi	a0,a0,-74 # 800280a8 <disk+0xa8>
    800060fa:	953e                	add	a0,a0,a5
  if(write)
    800060fc:	e00d1be3          	bnez	s10,80005f12 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006100:	6705                	lui	a4,0x1
    80006102:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006106:	972e                	add	a4,a4,a1
    80006108:	0712                	slli	a4,a4,0x4
    8000610a:	00022697          	auipc	a3,0x22
    8000610e:	ef668693          	addi	a3,a3,-266 # 80028000 <disk>
    80006112:	9736                	add	a4,a4,a3
    80006114:	0a072423          	sw	zero,168(a4)
    80006118:	bd11                	j	80005f2c <virtio_disk_rw+0xf6>

000000008000611a <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000611a:	7179                	addi	sp,sp,-48
    8000611c:	f406                	sd	ra,40(sp)
    8000611e:	f022                	sd	s0,32(sp)
    80006120:	ec26                	sd	s1,24(sp)
    80006122:	e84a                	sd	s2,16(sp)
    80006124:	e44e                	sd	s3,8(sp)
    80006126:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    80006128:	0002a517          	auipc	a0,0x2a
    8000612c:	00050513          	mv	a0,a0
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	ab4080e7          	jalr	-1356(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006138:	10004737          	lui	a4,0x10004
    8000613c:	533c                	lw	a5,96(a4)
    8000613e:	8b8d                	andi	a5,a5,3
    80006140:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006142:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006146:	0002a797          	auipc	a5,0x2a
    8000614a:	eba78793          	addi	a5,a5,-326 # 80030000 <disk+0x8000>
    8000614e:	6b94                	ld	a3,16(a5)
    80006150:	0207d703          	lhu	a4,32(a5)
    80006154:	0026d783          	lhu	a5,2(a3)
    80006158:	06f70363          	beq	a4,a5,800061be <virtio_disk_intr+0xa4>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000615c:	00022997          	auipc	s3,0x22
    80006160:	ea498993          	addi	s3,s3,-348 # 80028000 <disk>
    80006164:	0002a497          	auipc	s1,0x2a
    80006168:	e9c48493          	addi	s1,s1,-356 # 80030000 <disk+0x8000>

    if(disk.info[id].status != 0)
    8000616c:	6905                	lui	s2,0x1
    8000616e:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    80006172:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006176:	6898                	ld	a4,16(s1)
    80006178:	0204d783          	lhu	a5,32(s1)
    8000617c:	8b9d                	andi	a5,a5,7
    8000617e:	078e                	slli	a5,a5,0x3
    80006180:	97ba                	add	a5,a5,a4
    80006182:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006184:	01278733          	add	a4,a5,s2
    80006188:	0712                	slli	a4,a4,0x4
    8000618a:	974e                	add	a4,a4,s3
    8000618c:	03074703          	lbu	a4,48(a4) # 10004030 <_entry-0x6fffbfd0>
    80006190:	e731                	bnez	a4,800061dc <virtio_disk_intr+0xc2>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006192:	97ca                	add	a5,a5,s2
    80006194:	0792                	slli	a5,a5,0x4
    80006196:	97ce                	add	a5,a5,s3
    80006198:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    8000619a:	00052223          	sw	zero,4(a0) # 8003012c <disk+0x812c>
    wakeup(b);
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	0da080e7          	jalr	218(ra) # 80002278 <wakeup>

    disk.used_idx += 1;
    800061a6:	0204d783          	lhu	a5,32(s1)
    800061aa:	2785                	addiw	a5,a5,1
    800061ac:	17c2                	slli	a5,a5,0x30
    800061ae:	93c1                	srli	a5,a5,0x30
    800061b0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800061b4:	6898                	ld	a4,16(s1)
    800061b6:	00275703          	lhu	a4,2(a4)
    800061ba:	faf71ce3          	bne	a4,a5,80006172 <virtio_disk_intr+0x58>
  }

  release(&disk.vdisk_lock);
    800061be:	0002a517          	auipc	a0,0x2a
    800061c2:	f6a50513          	addi	a0,a0,-150 # 80030128 <disk+0x8128>
    800061c6:	ffffb097          	auipc	ra,0xffffb
    800061ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
}
    800061ce:	70a2                	ld	ra,40(sp)
    800061d0:	7402                	ld	s0,32(sp)
    800061d2:	64e2                	ld	s1,24(sp)
    800061d4:	6942                	ld	s2,16(sp)
    800061d6:	69a2                	ld	s3,8(sp)
    800061d8:	6145                	addi	sp,sp,48
    800061da:	8082                	ret
      panic("virtio_disk_intr status");
    800061dc:	00002517          	auipc	a0,0x2
    800061e0:	6e450513          	addi	a0,a0,1764 # 800088c0 <syscalls+0x3b0>
    800061e4:	ffffa097          	auipc	ra,0xffffa
    800061e8:	35a080e7          	jalr	858(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
