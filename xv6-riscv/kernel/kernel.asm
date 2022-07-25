
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
    80000068:	afc78793          	addi	a5,a5,-1284 # 80005b60 <timervec>
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
    80000130:	37c080e7          	jalr	892(ra) # 800024a8 <either_copyin>
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
    800001c8:	82e080e7          	jalr	-2002(ra) # 800019f2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	eda080e7          	jalr	-294(ra) # 800020ae <sleep>
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
    80000214:	242080e7          	jalr	578(ra) # 80002452 <either_copyout>
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
    800002f6:	20c080e7          	jalr	524(ra) # 800024fe <procdump>
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
    8000044a:	df4080e7          	jalr	-524(ra) # 8000223a <wakeup>
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
    800008a4:	99a080e7          	jalr	-1638(ra) # 8000223a <wakeup>
    
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
    80000930:	782080e7          	jalr	1922(ra) # 800020ae <sleep>
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
    80000b82:	e58080e7          	jalr	-424(ra) # 800019d6 <mycpu>
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
    80000bb4:	e26080e7          	jalr	-474(ra) # 800019d6 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e1a080e7          	jalr	-486(ra) # 800019d6 <mycpu>
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
    80000bd8:	e02080e7          	jalr	-510(ra) # 800019d6 <mycpu>
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
    80000c18:	dc2080e7          	jalr	-574(ra) # 800019d6 <mycpu>
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
    80000c44:	d96080e7          	jalr	-618(ra) # 800019d6 <mycpu>
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
    80000e9a:	b30080e7          	jalr	-1232(ra) # 800019c6 <cpuid>
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
    80000eb6:	b14080e7          	jalr	-1260(ra) # 800019c6 <cpuid>
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
    80000ed8:	76a080e7          	jalr	1898(ra) # 8000263e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	cc4080e7          	jalr	-828(ra) # 80005ba0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	018080e7          	jalr	24(ra) # 80001efc <scheduler>
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
    80000f58:	344080e7          	jalr	836(ra) # 80001298 <kvminit>
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
    80000f88:	992080e7          	jalr	-1646(ra) # 80001916 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	68a080e7          	jalr	1674(ra) # 80002616 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	6aa080e7          	jalr	1706(ra) # 8000263e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	bee080e7          	jalr	-1042(ra) # 80005b8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	bfc080e7          	jalr	-1028(ra) # 80005ba0 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	dd4080e7          	jalr	-556(ra) # 80002d80 <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	464080e7          	jalr	1124(ra) # 80003418 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	40e080e7          	jalr	1038(ra) # 800043ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	cfe080e7          	jalr	-770(ra) # 80005cc2 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	cfe080e7          	jalr	-770(ra) # 80001cca <userinit>
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
    80000fe6:	e422                	sd	s0,8(sp)
    80000fe8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fea:	0000b797          	auipc	a5,0xb
    80000fee:	0367b783          	ld	a5,54(a5) # 8000c020 <kernel_pagetable>
    80000ff2:	83b1                	srli	a5,a5,0xc
    80000ff4:	577d                	li	a4,-1
    80000ff6:	177e                	slli	a4,a4,0x3f
    80000ff8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ffa:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ffe:	12000073          	sfence.vma
  sfence_vma();
}
    80001002:	6422                	ld	s0,8(sp)
    80001004:	0141                	addi	sp,sp,16
    80001006:	8082                	ret

0000000080001008 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001008:	7139                	addi	sp,sp,-64
    8000100a:	fc06                	sd	ra,56(sp)
    8000100c:	f822                	sd	s0,48(sp)
    8000100e:	f426                	sd	s1,40(sp)
    80001010:	f04a                	sd	s2,32(sp)
    80001012:	ec4e                	sd	s3,24(sp)
    80001014:	e852                	sd	s4,16(sp)
    80001016:	e456                	sd	s5,8(sp)
    80001018:	e05a                	sd	s6,0(sp)
    8000101a:	0080                	addi	s0,sp,64
    8000101c:	84aa                	mv	s1,a0
    8000101e:	89ae                	mv	s3,a1
    80001020:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001022:	57fd                	li	a5,-1
    80001024:	83e9                	srli	a5,a5,0x1a
    80001026:	02000a13          	li	s4,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000102a:	4b39                	li	s6,14
  if(va >= MAXVA)
    8000102c:	04b7f263          	bgeu	a5,a1,80001070 <walk+0x68>
    panic("walk");
    80001030:	00007517          	auipc	a0,0x7
    80001034:	11050513          	addi	a0,a0,272 # 80008140 <digits+0x100>
    80001038:	fffff097          	auipc	ra,0xfffff
    8000103c:	506080e7          	jalr	1286(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001040:	060a8663          	beqz	s5,800010ac <walk+0xa4>
    80001044:	00000097          	auipc	ra,0x0
    80001048:	ab0080e7          	jalr	-1360(ra) # 80000af4 <kalloc>
    8000104c:	84aa                	mv	s1,a0
    8000104e:	c529                	beqz	a0,80001098 <walk+0x90>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001050:	6611                	lui	a2,0x4
    80001052:	4581                	li	a1,0
    80001054:	00000097          	auipc	ra,0x0
    80001058:	c8c080e7          	jalr	-884(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000105c:	00e4d793          	srli	a5,s1,0xe
    80001060:	07aa                	slli	a5,a5,0xa
    80001062:	0017e793          	ori	a5,a5,1
    80001066:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000106a:	3a5d                	addiw	s4,s4,-9
    8000106c:	036a0063          	beq	s4,s6,8000108c <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)];
    80001070:	0149d933          	srl	s2,s3,s4
    80001074:	1ff97913          	andi	s2,s2,511
    80001078:	090e                	slli	s2,s2,0x3
    8000107a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000107c:	00093483          	ld	s1,0(s2)
    80001080:	0014f793          	andi	a5,s1,1
    80001084:	dfd5                	beqz	a5,80001040 <walk+0x38>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001086:	80a9                	srli	s1,s1,0xa
    80001088:	04ba                	slli	s1,s1,0xe
    8000108a:	b7c5                	j	8000106a <walk+0x62>
    }
  }
  return &pagetable[PX(0, va)];
    8000108c:	00e9d513          	srli	a0,s3,0xe
    80001090:	1ff57513          	andi	a0,a0,511
    80001094:	050e                	slli	a0,a0,0x3
    80001096:	9526                	add	a0,a0,s1
}
    80001098:	70e2                	ld	ra,56(sp)
    8000109a:	7442                	ld	s0,48(sp)
    8000109c:	74a2                	ld	s1,40(sp)
    8000109e:	7902                	ld	s2,32(sp)
    800010a0:	69e2                	ld	s3,24(sp)
    800010a2:	6a42                	ld	s4,16(sp)
    800010a4:	6aa2                	ld	s5,8(sp)
    800010a6:	6b02                	ld	s6,0(sp)
    800010a8:	6121                	addi	sp,sp,64
    800010aa:	8082                	ret
        return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7ed                	j	80001098 <walk+0x90>

00000000800010b0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b0:	57fd                	li	a5,-1
    800010b2:	83e9                	srli	a5,a5,0x1a
    800010b4:	00b7f463          	bgeu	a5,a1,800010bc <walkaddr+0xc>
    return 0;
    800010b8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ba:	8082                	ret
{
    800010bc:	1141                	addi	sp,sp,-16
    800010be:	e406                	sd	ra,8(sp)
    800010c0:	e022                	sd	s0,0(sp)
    800010c2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010c4:	4601                	li	a2,0
    800010c6:	00000097          	auipc	ra,0x0
    800010ca:	f42080e7          	jalr	-190(ra) # 80001008 <walk>
  if(pte == 0)
    800010ce:	c105                	beqz	a0,800010ee <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d0:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d2:	0117f693          	andi	a3,a5,17
    800010d6:	4745                	li	a4,17
    return 0;
    800010d8:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010da:	00e68663          	beq	a3,a4,800010e6 <walkaddr+0x36>
}
    800010de:	60a2                	ld	ra,8(sp)
    800010e0:	6402                	ld	s0,0(sp)
    800010e2:	0141                	addi	sp,sp,16
    800010e4:	8082                	ret
  pa = PTE2PA(*pte);
    800010e6:	00a7d513          	srli	a0,a5,0xa
    800010ea:	053a                	slli	a0,a0,0xe
  return pa;
    800010ec:	bfcd                	j	800010de <walkaddr+0x2e>
    return 0;
    800010ee:	4501                	li	a0,0
    800010f0:	b7fd                	j	800010de <walkaddr+0x2e>

00000000800010f2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f2:	715d                	addi	sp,sp,-80
    800010f4:	e486                	sd	ra,72(sp)
    800010f6:	e0a2                	sd	s0,64(sp)
    800010f8:	fc26                	sd	s1,56(sp)
    800010fa:	f84a                	sd	s2,48(sp)
    800010fc:	f44e                	sd	s3,40(sp)
    800010fe:	f052                	sd	s4,32(sp)
    80001100:	ec56                	sd	s5,24(sp)
    80001102:	e85a                	sd	s6,16(sp)
    80001104:	e45e                	sd	s7,8(sp)
    80001106:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001108:	c205                	beqz	a2,80001128 <mappages+0x36>
    8000110a:	8aaa                	mv	s5,a0
    8000110c:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000110e:	77f1                	lui	a5,0xffffc
    80001110:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001114:	15fd                	addi	a1,a1,-1
    80001116:	00c589b3          	add	s3,a1,a2
    8000111a:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000111e:	8952                	mv	s2,s4
    80001120:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001124:	6b91                	lui	s7,0x4
    80001126:	a015                	j	8000114a <mappages+0x58>
    panic("mappages: size");
    80001128:	00007517          	auipc	a0,0x7
    8000112c:	02050513          	addi	a0,a0,32 # 80008148 <digits+0x108>
    80001130:	fffff097          	auipc	ra,0xfffff
    80001134:	40e080e7          	jalr	1038(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001138:	00007517          	auipc	a0,0x7
    8000113c:	02050513          	addi	a0,a0,32 # 80008158 <digits+0x118>
    80001140:	fffff097          	auipc	ra,0xfffff
    80001144:	3fe080e7          	jalr	1022(ra) # 8000053e <panic>
    a += PGSIZE;
    80001148:	995e                	add	s2,s2,s7
  for(;;){
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eb4080e7          	jalr	-332(ra) # 80001008 <walk>
    8000115c:	cd19                	beqz	a0,8000117a <mappages+0x88>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	fbf9                	bnez	a5,80001138 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b9                	srli	s1,s1,0xe
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	fd391be3          	bne	s2,s3,80001148 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001176:	4501                	li	a0,0
    80001178:	a011                	j	8000117c <mappages+0x8a>
      return -1;
    8000117a:	557d                	li	a0,-1
}
    8000117c:	60a6                	ld	ra,72(sp)
    8000117e:	6406                	ld	s0,64(sp)
    80001180:	74e2                	ld	s1,56(sp)
    80001182:	7942                	ld	s2,48(sp)
    80001184:	79a2                	ld	s3,40(sp)
    80001186:	7a02                	ld	s4,32(sp)
    80001188:	6ae2                	ld	s5,24(sp)
    8000118a:	6b42                	ld	s6,16(sp)
    8000118c:	6ba2                	ld	s7,8(sp)
    8000118e:	6161                	addi	sp,sp,80
    80001190:	8082                	ret

0000000080001192 <kvmmap>:
{
    80001192:	1141                	addi	sp,sp,-16
    80001194:	e406                	sd	ra,8(sp)
    80001196:	e022                	sd	s0,0(sp)
    80001198:	0800                	addi	s0,sp,16
    8000119a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000119c:	86b2                	mv	a3,a2
    8000119e:	863e                	mv	a2,a5
    800011a0:	00000097          	auipc	ra,0x0
    800011a4:	f52080e7          	jalr	-174(ra) # 800010f2 <mappages>
    800011a8:	e509                	bnez	a0,800011b2 <kvmmap+0x20>
}
    800011aa:	60a2                	ld	ra,8(sp)
    800011ac:	6402                	ld	s0,0(sp)
    800011ae:	0141                	addi	sp,sp,16
    800011b0:	8082                	ret
    panic("kvmmap");
    800011b2:	00007517          	auipc	a0,0x7
    800011b6:	fb650513          	addi	a0,a0,-74 # 80008168 <digits+0x128>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	384080e7          	jalr	900(ra) # 8000053e <panic>

00000000800011c2 <kvmmake>:
{
    800011c2:	1101                	addi	sp,sp,-32
    800011c4:	ec06                	sd	ra,24(sp)
    800011c6:	e822                	sd	s0,16(sp)
    800011c8:	e426                	sd	s1,8(sp)
    800011ca:	e04a                	sd	s2,0(sp)
    800011cc:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	926080e7          	jalr	-1754(ra) # 80000af4 <kalloc>
    800011d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011d8:	6611                	lui	a2,0x4
    800011da:	4581                	li	a1,0
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	b04080e7          	jalr	-1276(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011e4:	4719                	li	a4,6
    800011e6:	6691                	lui	a3,0x4
    800011e8:	10000637          	lui	a2,0x10000
    800011ec:	100005b7          	lui	a1,0x10000
    800011f0:	8526                	mv	a0,s1
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	fa0080e7          	jalr	-96(ra) # 80001192 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011fa:	4719                	li	a4,6
    800011fc:	6691                	lui	a3,0x4
    800011fe:	10001637          	lui	a2,0x10001
    80001202:	100015b7          	lui	a1,0x10001
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f8a080e7          	jalr	-118(ra) # 80001192 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	004006b7          	lui	a3,0x400
    80001216:	0c000637          	lui	a2,0xc000
    8000121a:	0c0005b7          	lui	a1,0xc000
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f72080e7          	jalr	-142(ra) # 80001192 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001228:	00007917          	auipc	s2,0x7
    8000122c:	dd890913          	addi	s2,s2,-552 # 80008000 <etext>
    80001230:	4729                	li	a4,10
    80001232:	80007697          	auipc	a3,0x80007
    80001236:	dce68693          	addi	a3,a3,-562 # 8000 <_entry-0x7fff8000>
    8000123a:	4605                	li	a2,1
    8000123c:	067e                	slli	a2,a2,0x1f
    8000123e:	85b2                	mv	a1,a2
    80001240:	8526                	mv	a0,s1
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f50080e7          	jalr	-176(ra) # 80001192 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000124a:	4719                	li	a4,6
    8000124c:	46c5                	li	a3,17
    8000124e:	06ee                	slli	a3,a3,0x1b
    80001250:	412686b3          	sub	a3,a3,s2
    80001254:	864a                	mv	a2,s2
    80001256:	85ca                	mv	a1,s2
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f38080e7          	jalr	-200(ra) # 80001192 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001262:	4729                	li	a4,10
    80001264:	6691                	lui	a3,0x4
    80001266:	00006617          	auipc	a2,0x6
    8000126a:	d9a60613          	addi	a2,a2,-614 # 80007000 <_trampoline>
    8000126e:	010005b7          	lui	a1,0x1000
    80001272:	15fd                	addi	a1,a1,-1
    80001274:	05ba                	slli	a1,a1,0xe
    80001276:	8526                	mv	a0,s1
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	f1a080e7          	jalr	-230(ra) # 80001192 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001280:	8526                	mv	a0,s1
    80001282:	00000097          	auipc	ra,0x0
    80001286:	5fe080e7          	jalr	1534(ra) # 80001880 <proc_mapstacks>
}
    8000128a:	8526                	mv	a0,s1
    8000128c:	60e2                	ld	ra,24(sp)
    8000128e:	6442                	ld	s0,16(sp)
    80001290:	64a2                	ld	s1,8(sp)
    80001292:	6902                	ld	s2,0(sp)
    80001294:	6105                	addi	sp,sp,32
    80001296:	8082                	ret

0000000080001298 <kvminit>:
{
    80001298:	1141                	addi	sp,sp,-16
    8000129a:	e406                	sd	ra,8(sp)
    8000129c:	e022                	sd	s0,0(sp)
    8000129e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a0:	00000097          	auipc	ra,0x0
    800012a4:	f22080e7          	jalr	-222(ra) # 800011c2 <kvmmake>
    800012a8:	0000b797          	auipc	a5,0xb
    800012ac:	d6a7bc23          	sd	a0,-648(a5) # 8000c020 <kernel_pagetable>
}
    800012b0:	60a2                	ld	ra,8(sp)
    800012b2:	6402                	ld	s0,0(sp)
    800012b4:	0141                	addi	sp,sp,16
    800012b6:	8082                	ret

00000000800012b8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b8:	715d                	addi	sp,sp,-80
    800012ba:	e486                	sd	ra,72(sp)
    800012bc:	e0a2                	sd	s0,64(sp)
    800012be:	fc26                	sd	s1,56(sp)
    800012c0:	f84a                	sd	s2,48(sp)
    800012c2:	f44e                	sd	s3,40(sp)
    800012c4:	f052                	sd	s4,32(sp)
    800012c6:	ec56                	sd	s5,24(sp)
    800012c8:	e85a                	sd	s6,16(sp)
    800012ca:	e45e                	sd	s7,8(sp)
    800012cc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ce:	03259793          	slli	a5,a1,0x32
    800012d2:	e795                	bnez	a5,800012fe <uvmunmap+0x46>
    800012d4:	8a2a                	mv	s4,a0
    800012d6:	892e                	mv	s2,a1
    800012d8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012da:	063a                	slli	a2,a2,0xe
    800012dc:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	6b11                	lui	s6,0x4
    800012e4:	0735e863          	bltu	a1,s3,80001354 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e8:	60a6                	ld	ra,72(sp)
    800012ea:	6406                	ld	s0,64(sp)
    800012ec:	74e2                	ld	s1,56(sp)
    800012ee:	7942                	ld	s2,48(sp)
    800012f0:	79a2                	ld	s3,40(sp)
    800012f2:	7a02                	ld	s4,32(sp)
    800012f4:	6ae2                	ld	s5,24(sp)
    800012f6:	6b42                	ld	s6,16(sp)
    800012f8:	6ba2                	ld	s7,8(sp)
    800012fa:	6161                	addi	sp,sp,80
    800012fc:	8082                	ret
    panic("uvmunmap: not aligned");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	e7250513          	addi	a0,a0,-398 # 80008170 <digits+0x130>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	238080e7          	jalr	568(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	e7a50513          	addi	a0,a0,-390 # 80008188 <digits+0x148>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	228080e7          	jalr	552(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	e7a50513          	addi	a0,a0,-390 # 80008198 <digits+0x158>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	218080e7          	jalr	536(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	e8250513          	addi	a0,a0,-382 # 800081b0 <digits+0x170>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	208080e7          	jalr	520(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    8000133e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001340:	053a                	slli	a0,a0,0xe
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	6b6080e7          	jalr	1718(ra) # 800009f8 <kfree>
    *pte = 0;
    8000134a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134e:	995a                	add	s2,s2,s6
    80001350:	f9397ce3          	bgeu	s2,s3,800012e8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001354:	4601                	li	a2,0
    80001356:	85ca                	mv	a1,s2
    80001358:	8552                	mv	a0,s4
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	cae080e7          	jalr	-850(ra) # 80001008 <walk>
    80001362:	84aa                	mv	s1,a0
    80001364:	d54d                	beqz	a0,8000130e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001366:	6108                	ld	a0,0(a0)
    80001368:	00157793          	andi	a5,a0,1
    8000136c:	dbcd                	beqz	a5,8000131e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136e:	3ff57793          	andi	a5,a0,1023
    80001372:	fb778ee3          	beq	a5,s7,8000132e <uvmunmap+0x76>
    if(do_free){
    80001376:	fc0a8ae3          	beqz	s5,8000134a <uvmunmap+0x92>
    8000137a:	b7d1                	j	8000133e <uvmunmap+0x86>

000000008000137c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000137c:	1101                	addi	sp,sp,-32
    8000137e:	ec06                	sd	ra,24(sp)
    80001380:	e822                	sd	s0,16(sp)
    80001382:	e426                	sd	s1,8(sp)
    80001384:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	76e080e7          	jalr	1902(ra) # 80000af4 <kalloc>
    8000138e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001390:	c519                	beqz	a0,8000139e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001392:	6611                	lui	a2,0x4
    80001394:	4581                	li	a1,0
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	94a080e7          	jalr	-1718(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000139e:	8526                	mv	a0,s1
    800013a0:	60e2                	ld	ra,24(sp)
    800013a2:	6442                	ld	s0,16(sp)
    800013a4:	64a2                	ld	s1,8(sp)
    800013a6:	6105                	addi	sp,sp,32
    800013a8:	8082                	ret

00000000800013aa <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013aa:	7179                	addi	sp,sp,-48
    800013ac:	f406                	sd	ra,40(sp)
    800013ae:	f022                	sd	s0,32(sp)
    800013b0:	ec26                	sd	s1,24(sp)
    800013b2:	e84a                	sd	s2,16(sp)
    800013b4:	e44e                	sd	s3,8(sp)
    800013b6:	e052                	sd	s4,0(sp)
    800013b8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ba:	6791                	lui	a5,0x4
    800013bc:	04f67863          	bgeu	a2,a5,8000140c <uvminit+0x62>
    800013c0:	8a2a                	mv	s4,a0
    800013c2:	89ae                	mv	s3,a1
    800013c4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	72e080e7          	jalr	1838(ra) # 80000af4 <kalloc>
    800013ce:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d0:	6611                	lui	a2,0x4
    800013d2:	4581                	li	a1,0
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	90c080e7          	jalr	-1780(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013dc:	4779                	li	a4,30
    800013de:	86ca                	mv	a3,s2
    800013e0:	6611                	lui	a2,0x4
    800013e2:	4581                	li	a1,0
    800013e4:	8552                	mv	a0,s4
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	d0c080e7          	jalr	-756(ra) # 800010f2 <mappages>
  memmove(mem, src, sz);
    800013ee:	8626                	mv	a2,s1
    800013f0:	85ce                	mv	a1,s3
    800013f2:	854a                	mv	a0,s2
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	94c080e7          	jalr	-1716(ra) # 80000d40 <memmove>
}
    800013fc:	70a2                	ld	ra,40(sp)
    800013fe:	7402                	ld	s0,32(sp)
    80001400:	64e2                	ld	s1,24(sp)
    80001402:	6942                	ld	s2,16(sp)
    80001404:	69a2                	ld	s3,8(sp)
    80001406:	6a02                	ld	s4,0(sp)
    80001408:	6145                	addi	sp,sp,48
    8000140a:	8082                	ret
    panic("inituvm: more than a page");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	dbc50513          	addi	a0,a0,-580 # 800081c8 <digits+0x188>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	12a080e7          	jalr	298(ra) # 8000053e <panic>

000000008000141c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000141c:	1101                	addi	sp,sp,-32
    8000141e:	ec06                	sd	ra,24(sp)
    80001420:	e822                	sd	s0,16(sp)
    80001422:	e426                	sd	s1,8(sp)
    80001424:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001426:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001428:	00b67d63          	bgeu	a2,a1,80001442 <uvmdealloc+0x26>
    8000142c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000142e:	6791                	lui	a5,0x4
    80001430:	17fd                	addi	a5,a5,-1
    80001432:	00f60733          	add	a4,a2,a5
    80001436:	7671                	lui	a2,0xffffc
    80001438:	8f71                	and	a4,a4,a2
    8000143a:	97ae                	add	a5,a5,a1
    8000143c:	8ff1                	and	a5,a5,a2
    8000143e:	00f76863          	bltu	a4,a5,8000144e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001442:	8526                	mv	a0,s1
    80001444:	60e2                	ld	ra,24(sp)
    80001446:	6442                	ld	s0,16(sp)
    80001448:	64a2                	ld	s1,8(sp)
    8000144a:	6105                	addi	sp,sp,32
    8000144c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000144e:	8f99                	sub	a5,a5,a4
    80001450:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001452:	4685                	li	a3,1
    80001454:	0007861b          	sext.w	a2,a5
    80001458:	85ba                	mv	a1,a4
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	e5e080e7          	jalr	-418(ra) # 800012b8 <uvmunmap>
    80001462:	b7c5                	j	80001442 <uvmdealloc+0x26>

0000000080001464 <uvmalloc>:
  if(newsz < oldsz)
    80001464:	0ab66163          	bltu	a2,a1,80001506 <uvmalloc+0xa2>
{
    80001468:	7139                	addi	sp,sp,-64
    8000146a:	fc06                	sd	ra,56(sp)
    8000146c:	f822                	sd	s0,48(sp)
    8000146e:	f426                	sd	s1,40(sp)
    80001470:	f04a                	sd	s2,32(sp)
    80001472:	ec4e                	sd	s3,24(sp)
    80001474:	e852                	sd	s4,16(sp)
    80001476:	e456                	sd	s5,8(sp)
    80001478:	0080                	addi	s0,sp,64
    8000147a:	8aaa                	mv	s5,a0
    8000147c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000147e:	6991                	lui	s3,0x4
    80001480:	19fd                	addi	s3,s3,-1
    80001482:	95ce                	add	a1,a1,s3
    80001484:	79f1                	lui	s3,0xffffc
    80001486:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	08c9f063          	bgeu	s3,a2,8000150a <uvmalloc+0xa6>
    8000148e:	894e                	mv	s2,s3
    mem = kalloc();
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	664080e7          	jalr	1636(ra) # 80000af4 <kalloc>
    80001498:	84aa                	mv	s1,a0
    if(mem == 0){
    8000149a:	c51d                	beqz	a0,800014c8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000149c:	6611                	lui	a2,0x4
    8000149e:	4581                	li	a1,0
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	840080e7          	jalr	-1984(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014a8:	4779                	li	a4,30
    800014aa:	86a6                	mv	a3,s1
    800014ac:	6611                	lui	a2,0x4
    800014ae:	85ca                	mv	a1,s2
    800014b0:	8556                	mv	a0,s5
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	c40080e7          	jalr	-960(ra) # 800010f2 <mappages>
    800014ba:	e905                	bnez	a0,800014ea <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014bc:	6791                	lui	a5,0x4
    800014be:	993e                	add	s2,s2,a5
    800014c0:	fd4968e3          	bltu	s2,s4,80001490 <uvmalloc+0x2c>
  return newsz;
    800014c4:	8552                	mv	a0,s4
    800014c6:	a809                	j	800014d8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014c8:	864e                	mv	a2,s3
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	f4e080e7          	jalr	-178(ra) # 8000141c <uvmdealloc>
      return 0;
    800014d6:	4501                	li	a0,0
}
    800014d8:	70e2                	ld	ra,56(sp)
    800014da:	7442                	ld	s0,48(sp)
    800014dc:	74a2                	ld	s1,40(sp)
    800014de:	7902                	ld	s2,32(sp)
    800014e0:	69e2                	ld	s3,24(sp)
    800014e2:	6a42                	ld	s4,16(sp)
    800014e4:	6aa2                	ld	s5,8(sp)
    800014e6:	6121                	addi	sp,sp,64
    800014e8:	8082                	ret
      kfree(mem);
    800014ea:	8526                	mv	a0,s1
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	50c080e7          	jalr	1292(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f4:	864e                	mv	a2,s3
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8556                	mv	a0,s5
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	f22080e7          	jalr	-222(ra) # 8000141c <uvmdealloc>
      return 0;
    80001502:	4501                	li	a0,0
    80001504:	bfd1                	j	800014d8 <uvmalloc+0x74>
    return oldsz;
    80001506:	852e                	mv	a0,a1
}
    80001508:	8082                	ret
  return newsz;
    8000150a:	8532                	mv	a0,a2
    8000150c:	b7f1                	j	800014d8 <uvmalloc+0x74>

000000008000150e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000150e:	7179                	addi	sp,sp,-48
    80001510:	f406                	sd	ra,40(sp)
    80001512:	f022                	sd	s0,32(sp)
    80001514:	ec26                	sd	s1,24(sp)
    80001516:	e84a                	sd	s2,16(sp)
    80001518:	e44e                	sd	s3,8(sp)
    8000151a:	e052                	sd	s4,0(sp)
    8000151c:	1800                	addi	s0,sp,48
    8000151e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001520:	84aa                	mv	s1,a0
    80001522:	6905                	lui	s2,0x1
    80001524:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001526:	4985                	li	s3,1
    80001528:	a821                	j	80001540 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000152a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000152c:	053a                	slli	a0,a0,0xe
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	fe0080e7          	jalr	-32(ra) # 8000150e <freewalk>
      pagetable[i] = 0;
    80001536:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000153a:	04a1                	addi	s1,s1,8
    8000153c:	03248163          	beq	s1,s2,8000155e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001540:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	00f57793          	andi	a5,a0,15
    80001546:	ff3782e3          	beq	a5,s3,8000152a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000154a:	8905                	andi	a0,a0,1
    8000154c:	d57d                	beqz	a0,8000153a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000154e:	00007517          	auipc	a0,0x7
    80001552:	c9a50513          	addi	a0,a0,-870 # 800081e8 <digits+0x1a8>
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	fe8080e7          	jalr	-24(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000155e:	8552                	mv	a0,s4
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	498080e7          	jalr	1176(ra) # 800009f8 <kfree>
}
    80001568:	70a2                	ld	ra,40(sp)
    8000156a:	7402                	ld	s0,32(sp)
    8000156c:	64e2                	ld	s1,24(sp)
    8000156e:	6942                	ld	s2,16(sp)
    80001570:	69a2                	ld	s3,8(sp)
    80001572:	6a02                	ld	s4,0(sp)
    80001574:	6145                	addi	sp,sp,48
    80001576:	8082                	ret

0000000080001578 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001578:	1101                	addi	sp,sp,-32
    8000157a:	ec06                	sd	ra,24(sp)
    8000157c:	e822                	sd	s0,16(sp)
    8000157e:	e426                	sd	s1,8(sp)
    80001580:	1000                	addi	s0,sp,32
    80001582:	84aa                	mv	s1,a0
  if(sz > 0)
    80001584:	e999                	bnez	a1,8000159a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001586:	8526                	mv	a0,s1
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f86080e7          	jalr	-122(ra) # 8000150e <freewalk>
}
    80001590:	60e2                	ld	ra,24(sp)
    80001592:	6442                	ld	s0,16(sp)
    80001594:	64a2                	ld	s1,8(sp)
    80001596:	6105                	addi	sp,sp,32
    80001598:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000159a:	6611                	lui	a2,0x4
    8000159c:	167d                	addi	a2,a2,-1
    8000159e:	962e                	add	a2,a2,a1
    800015a0:	4685                	li	a3,1
    800015a2:	8239                	srli	a2,a2,0xe
    800015a4:	4581                	li	a1,0
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	d12080e7          	jalr	-750(ra) # 800012b8 <uvmunmap>
    800015ae:	bfe1                	j	80001586 <uvmfree+0xe>

00000000800015b0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	c679                	beqz	a2,8000167e <uvmcopy+0xce>
{
    800015b2:	715d                	addi	sp,sp,-80
    800015b4:	e486                	sd	ra,72(sp)
    800015b6:	e0a2                	sd	s0,64(sp)
    800015b8:	fc26                	sd	s1,56(sp)
    800015ba:	f84a                	sd	s2,48(sp)
    800015bc:	f44e                	sd	s3,40(sp)
    800015be:	f052                	sd	s4,32(sp)
    800015c0:	ec56                	sd	s5,24(sp)
    800015c2:	e85a                	sd	s6,16(sp)
    800015c4:	e45e                	sd	s7,8(sp)
    800015c6:	0880                	addi	s0,sp,80
    800015c8:	8b2a                	mv	s6,a0
    800015ca:	8aae                	mv	s5,a1
    800015cc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015d0:	4601                	li	a2,0
    800015d2:	85ce                	mv	a1,s3
    800015d4:	855a                	mv	a0,s6
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	a32080e7          	jalr	-1486(ra) # 80001008 <walk>
    800015de:	c531                	beqz	a0,8000162a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015e0:	6118                	ld	a4,0(a0)
    800015e2:	00177793          	andi	a5,a4,1
    800015e6:	cbb1                	beqz	a5,8000163a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015e8:	00a75593          	srli	a1,a4,0xa
    800015ec:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    800015f0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015f4:	fffff097          	auipc	ra,0xfffff
    800015f8:	500080e7          	jalr	1280(ra) # 80000af4 <kalloc>
    800015fc:	892a                	mv	s2,a0
    800015fe:	c939                	beqz	a0,80001654 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001600:	6611                	lui	a2,0x4
    80001602:	85de                	mv	a1,s7
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	73c080e7          	jalr	1852(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000160c:	8726                	mv	a4,s1
    8000160e:	86ca                	mv	a3,s2
    80001610:	6611                	lui	a2,0x4
    80001612:	85ce                	mv	a1,s3
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	adc080e7          	jalr	-1316(ra) # 800010f2 <mappages>
    8000161e:	e515                	bnez	a0,8000164a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001620:	6791                	lui	a5,0x4
    80001622:	99be                	add	s3,s3,a5
    80001624:	fb49e6e3          	bltu	s3,s4,800015d0 <uvmcopy+0x20>
    80001628:	a081                	j	80001668 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000162a:	00007517          	auipc	a0,0x7
    8000162e:	bce50513          	addi	a0,a0,-1074 # 800081f8 <digits+0x1b8>
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	f0c080e7          	jalr	-244(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	bde50513          	addi	a0,a0,-1058 # 80008218 <digits+0x1d8>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>
      kfree(mem);
    8000164a:	854a                	mv	a0,s2
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	3ac080e7          	jalr	940(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001654:	4685                	li	a3,1
    80001656:	00e9d613          	srli	a2,s3,0xe
    8000165a:	4581                	li	a1,0
    8000165c:	8556                	mv	a0,s5
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	c5a080e7          	jalr	-934(ra) # 800012b8 <uvmunmap>
  return -1;
    80001666:	557d                	li	a0,-1
}
    80001668:	60a6                	ld	ra,72(sp)
    8000166a:	6406                	ld	s0,64(sp)
    8000166c:	74e2                	ld	s1,56(sp)
    8000166e:	7942                	ld	s2,48(sp)
    80001670:	79a2                	ld	s3,40(sp)
    80001672:	7a02                	ld	s4,32(sp)
    80001674:	6ae2                	ld	s5,24(sp)
    80001676:	6b42                	ld	s6,16(sp)
    80001678:	6ba2                	ld	s7,8(sp)
    8000167a:	6161                	addi	sp,sp,80
    8000167c:	8082                	ret
  return 0;
    8000167e:	4501                	li	a0,0
}
    80001680:	8082                	ret

0000000080001682 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001682:	1141                	addi	sp,sp,-16
    80001684:	e406                	sd	ra,8(sp)
    80001686:	e022                	sd	s0,0(sp)
    80001688:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000168a:	4601                	li	a2,0
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	97c080e7          	jalr	-1668(ra) # 80001008 <walk>
  if(pte == 0)
    80001694:	c901                	beqz	a0,800016a4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001696:	611c                	ld	a5,0(a0)
    80001698:	9bbd                	andi	a5,a5,-17
    8000169a:	e11c                	sd	a5,0(a0)
}
    8000169c:	60a2                	ld	ra,8(sp)
    8000169e:	6402                	ld	s0,0(sp)
    800016a0:	0141                	addi	sp,sp,16
    800016a2:	8082                	ret
    panic("uvmclear");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	b9450513          	addi	a0,a0,-1132 # 80008238 <digits+0x1f8>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e92080e7          	jalr	-366(ra) # 8000053e <panic>

00000000800016b4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016b4:	c6bd                	beqz	a3,80001722 <copyout+0x6e>
{
    800016b6:	715d                	addi	sp,sp,-80
    800016b8:	e486                	sd	ra,72(sp)
    800016ba:	e0a2                	sd	s0,64(sp)
    800016bc:	fc26                	sd	s1,56(sp)
    800016be:	f84a                	sd	s2,48(sp)
    800016c0:	f44e                	sd	s3,40(sp)
    800016c2:	f052                	sd	s4,32(sp)
    800016c4:	ec56                	sd	s5,24(sp)
    800016c6:	e85a                	sd	s6,16(sp)
    800016c8:	e45e                	sd	s7,8(sp)
    800016ca:	e062                	sd	s8,0(sp)
    800016cc:	0880                	addi	s0,sp,80
    800016ce:	8b2a                	mv	s6,a0
    800016d0:	8c2e                	mv	s8,a1
    800016d2:	8a32                	mv	s4,a2
    800016d4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016d6:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d8:	6a91                	lui	s5,0x4
    800016da:	a015                	j	800016fe <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016dc:	9562                	add	a0,a0,s8
    800016de:	0004861b          	sext.w	a2,s1
    800016e2:	85d2                	mv	a1,s4
    800016e4:	41250533          	sub	a0,a0,s2
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	658080e7          	jalr	1624(ra) # 80000d40 <memmove>

    len -= n;
    800016f0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016f4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016f6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016fa:	02098263          	beqz	s3,8000171e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016fe:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001702:	85ca                	mv	a1,s2
    80001704:	855a                	mv	a0,s6
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	9aa080e7          	jalr	-1622(ra) # 800010b0 <walkaddr>
    if(pa0 == 0)
    8000170e:	cd01                	beqz	a0,80001726 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001710:	418904b3          	sub	s1,s2,s8
    80001714:	94d6                	add	s1,s1,s5
    if(n > len)
    80001716:	fc99f3e3          	bgeu	s3,s1,800016dc <copyout+0x28>
    8000171a:	84ce                	mv	s1,s3
    8000171c:	b7c1                	j	800016dc <copyout+0x28>
  }
  return 0;
    8000171e:	4501                	li	a0,0
    80001720:	a021                	j	80001728 <copyout+0x74>
    80001722:	4501                	li	a0,0
}
    80001724:	8082                	ret
      return -1;
    80001726:	557d                	li	a0,-1
}
    80001728:	60a6                	ld	ra,72(sp)
    8000172a:	6406                	ld	s0,64(sp)
    8000172c:	74e2                	ld	s1,56(sp)
    8000172e:	7942                	ld	s2,48(sp)
    80001730:	79a2                	ld	s3,40(sp)
    80001732:	7a02                	ld	s4,32(sp)
    80001734:	6ae2                	ld	s5,24(sp)
    80001736:	6b42                	ld	s6,16(sp)
    80001738:	6ba2                	ld	s7,8(sp)
    8000173a:	6c02                	ld	s8,0(sp)
    8000173c:	6161                	addi	sp,sp,80
    8000173e:	8082                	ret

0000000080001740 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001740:	c6bd                	beqz	a3,800017ae <copyin+0x6e>
{
    80001742:	715d                	addi	sp,sp,-80
    80001744:	e486                	sd	ra,72(sp)
    80001746:	e0a2                	sd	s0,64(sp)
    80001748:	fc26                	sd	s1,56(sp)
    8000174a:	f84a                	sd	s2,48(sp)
    8000174c:	f44e                	sd	s3,40(sp)
    8000174e:	f052                	sd	s4,32(sp)
    80001750:	ec56                	sd	s5,24(sp)
    80001752:	e85a                	sd	s6,16(sp)
    80001754:	e45e                	sd	s7,8(sp)
    80001756:	e062                	sd	s8,0(sp)
    80001758:	0880                	addi	s0,sp,80
    8000175a:	8b2a                	mv	s6,a0
    8000175c:	8a2e                	mv	s4,a1
    8000175e:	8c32                	mv	s8,a2
    80001760:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001762:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001764:	6a91                	lui	s5,0x4
    80001766:	a015                	j	8000178a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001768:	9562                	add	a0,a0,s8
    8000176a:	0004861b          	sext.w	a2,s1
    8000176e:	412505b3          	sub	a1,a0,s2
    80001772:	8552                	mv	a0,s4
    80001774:	fffff097          	auipc	ra,0xfffff
    80001778:	5cc080e7          	jalr	1484(ra) # 80000d40 <memmove>

    len -= n;
    8000177c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001780:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001782:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001786:	02098263          	beqz	s3,800017aa <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000178a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000178e:	85ca                	mv	a1,s2
    80001790:	855a                	mv	a0,s6
    80001792:	00000097          	auipc	ra,0x0
    80001796:	91e080e7          	jalr	-1762(ra) # 800010b0 <walkaddr>
    if(pa0 == 0)
    8000179a:	cd01                	beqz	a0,800017b2 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000179c:	418904b3          	sub	s1,s2,s8
    800017a0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a2:	fc99f3e3          	bgeu	s3,s1,80001768 <copyin+0x28>
    800017a6:	84ce                	mv	s1,s3
    800017a8:	b7c1                	j	80001768 <copyin+0x28>
  }
  return 0;
    800017aa:	4501                	li	a0,0
    800017ac:	a021                	j	800017b4 <copyin+0x74>
    800017ae:	4501                	li	a0,0
}
    800017b0:	8082                	ret
      return -1;
    800017b2:	557d                	li	a0,-1
}
    800017b4:	60a6                	ld	ra,72(sp)
    800017b6:	6406                	ld	s0,64(sp)
    800017b8:	74e2                	ld	s1,56(sp)
    800017ba:	7942                	ld	s2,48(sp)
    800017bc:	79a2                	ld	s3,40(sp)
    800017be:	7a02                	ld	s4,32(sp)
    800017c0:	6ae2                	ld	s5,24(sp)
    800017c2:	6b42                	ld	s6,16(sp)
    800017c4:	6ba2                	ld	s7,8(sp)
    800017c6:	6c02                	ld	s8,0(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret

00000000800017cc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017cc:	c6c5                	beqz	a3,80001874 <copyinstr+0xa8>
{
    800017ce:	715d                	addi	sp,sp,-80
    800017d0:	e486                	sd	ra,72(sp)
    800017d2:	e0a2                	sd	s0,64(sp)
    800017d4:	fc26                	sd	s1,56(sp)
    800017d6:	f84a                	sd	s2,48(sp)
    800017d8:	f44e                	sd	s3,40(sp)
    800017da:	f052                	sd	s4,32(sp)
    800017dc:	ec56                	sd	s5,24(sp)
    800017de:	e85a                	sd	s6,16(sp)
    800017e0:	e45e                	sd	s7,8(sp)
    800017e2:	0880                	addi	s0,sp,80
    800017e4:	8a2a                	mv	s4,a0
    800017e6:	8b2e                	mv	s6,a1
    800017e8:	8bb2                	mv	s7,a2
    800017ea:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ec:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ee:	6991                	lui	s3,0x4
    800017f0:	a035                	j	8000181c <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017f2:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    800017f6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f8:	0017b793          	seqz	a5,a5
    800017fc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001800:	60a6                	ld	ra,72(sp)
    80001802:	6406                	ld	s0,64(sp)
    80001804:	74e2                	ld	s1,56(sp)
    80001806:	7942                	ld	s2,48(sp)
    80001808:	79a2                	ld	s3,40(sp)
    8000180a:	7a02                	ld	s4,32(sp)
    8000180c:	6ae2                	ld	s5,24(sp)
    8000180e:	6b42                	ld	s6,16(sp)
    80001810:	6ba2                	ld	s7,8(sp)
    80001812:	6161                	addi	sp,sp,80
    80001814:	8082                	ret
    srcva = va0 + PGSIZE;
    80001816:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000181a:	c8a9                	beqz	s1,8000186c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000181c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	8552                	mv	a0,s4
    80001824:	00000097          	auipc	ra,0x0
    80001828:	88c080e7          	jalr	-1908(ra) # 800010b0 <walkaddr>
    if(pa0 == 0)
    8000182c:	c131                	beqz	a0,80001870 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000182e:	41790833          	sub	a6,s2,s7
    80001832:	984e                	add	a6,a6,s3
    if(n > max)
    80001834:	0104f363          	bgeu	s1,a6,8000183a <copyinstr+0x6e>
    80001838:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000183a:	955e                	add	a0,a0,s7
    8000183c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001840:	fc080be3          	beqz	a6,80001816 <copyinstr+0x4a>
    80001844:	985a                	add	a6,a6,s6
    80001846:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001848:	41650633          	sub	a2,a0,s6
    8000184c:	14fd                	addi	s1,s1,-1
    8000184e:	9b26                	add	s6,s6,s1
    80001850:	00f60733          	add	a4,a2,a5
    80001854:	00074703          	lbu	a4,0(a4)
    80001858:	df49                	beqz	a4,800017f2 <copyinstr+0x26>
        *dst = *p;
    8000185a:	00e78023          	sb	a4,0(a5)
      --max;
    8000185e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001862:	0785                	addi	a5,a5,1
    while(n > 0){
    80001864:	ff0796e3          	bne	a5,a6,80001850 <copyinstr+0x84>
      dst++;
    80001868:	8b42                	mv	s6,a6
    8000186a:	b775                	j	80001816 <copyinstr+0x4a>
    8000186c:	4781                	li	a5,0
    8000186e:	b769                	j	800017f8 <copyinstr+0x2c>
      return -1;
    80001870:	557d                	li	a0,-1
    80001872:	b779                	j	80001800 <copyinstr+0x34>
  int got_null = 0;
    80001874:	4781                	li	a5,0
  if(got_null){
    80001876:	0017b793          	seqz	a5,a5
    8000187a:	40f00533          	neg	a0,a5
}
    8000187e:	8082                	ret

0000000080001880 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001880:	7139                	addi	sp,sp,-64
    80001882:	fc06                	sd	ra,56(sp)
    80001884:	f822                	sd	s0,48(sp)
    80001886:	f426                	sd	s1,40(sp)
    80001888:	f04a                	sd	s2,32(sp)
    8000188a:	ec4e                	sd	s3,24(sp)
    8000188c:	e852                	sd	s4,16(sp)
    8000188e:	e456                	sd	s5,8(sp)
    80001890:	e05a                	sd	s6,0(sp)
    80001892:	0080                	addi	s0,sp,64
    80001894:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	00013497          	auipc	s1,0x13
    8000189a:	e3a48493          	addi	s1,s1,-454 # 800146d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000189e:	8b26                	mv	s6,s1
    800018a0:	00006a97          	auipc	s5,0x6
    800018a4:	760a8a93          	addi	s5,s5,1888 # 80008000 <etext>
    800018a8:	01000937          	lui	s2,0x1000
    800018ac:	197d                	addi	s2,s2,-1
    800018ae:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	00019a17          	auipc	s4,0x19
    800018b4:	820a0a13          	addi	s4,s4,-2016 # 8001a0d0 <tickslock>
    char *pa = kalloc();
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	23c080e7          	jalr	572(ra) # 80000af4 <kalloc>
    800018c0:	862a                	mv	a2,a0
    if(pa == 0)
    800018c2:	c131                	beqz	a0,80001906 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018c4:	416485b3          	sub	a1,s1,s6
    800018c8:	858d                	srai	a1,a1,0x3
    800018ca:	000ab783          	ld	a5,0(s5)
    800018ce:	02f585b3          	mul	a1,a1,a5
    800018d2:	2585                	addiw	a1,a1,1
    800018d4:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018d8:	4719                	li	a4,6
    800018da:	6691                	lui	a3,0x4
    800018dc:	40b905b3          	sub	a1,s2,a1
    800018e0:	854e                	mv	a0,s3
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	8b0080e7          	jalr	-1872(ra) # 80001192 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ea:	16848493          	addi	s1,s1,360
    800018ee:	fd4495e3          	bne	s1,s4,800018b8 <proc_mapstacks+0x38>
  }
}
    800018f2:	70e2                	ld	ra,56(sp)
    800018f4:	7442                	ld	s0,48(sp)
    800018f6:	74a2                	ld	s1,40(sp)
    800018f8:	7902                	ld	s2,32(sp)
    800018fa:	69e2                	ld	s3,24(sp)
    800018fc:	6a42                	ld	s4,16(sp)
    800018fe:	6aa2                	ld	s5,8(sp)
    80001900:	6b02                	ld	s6,0(sp)
    80001902:	6121                	addi	sp,sp,64
    80001904:	8082                	ret
      panic("kalloc");
    80001906:	00007517          	auipc	a0,0x7
    8000190a:	94250513          	addi	a0,a0,-1726 # 80008248 <digits+0x208>
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	c30080e7          	jalr	-976(ra) # 8000053e <panic>

0000000080001916 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001916:	7139                	addi	sp,sp,-64
    80001918:	fc06                	sd	ra,56(sp)
    8000191a:	f822                	sd	s0,48(sp)
    8000191c:	f426                	sd	s1,40(sp)
    8000191e:	f04a                	sd	s2,32(sp)
    80001920:	ec4e                	sd	s3,24(sp)
    80001922:	e852                	sd	s4,16(sp)
    80001924:	e456                	sd	s5,8(sp)
    80001926:	e05a                	sd	s6,0(sp)
    80001928:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000192a:	00007597          	auipc	a1,0x7
    8000192e:	92658593          	addi	a1,a1,-1754 # 80008250 <digits+0x210>
    80001932:	00013517          	auipc	a0,0x13
    80001936:	96e50513          	addi	a0,a0,-1682 # 800142a0 <pid_lock>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	21a080e7          	jalr	538(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	91658593          	addi	a1,a1,-1770 # 80008258 <digits+0x218>
    8000194a:	00013517          	auipc	a0,0x13
    8000194e:	96e50513          	addi	a0,a0,-1682 # 800142b8 <wait_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	202080e7          	jalr	514(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00013497          	auipc	s1,0x13
    8000195e:	d7648493          	addi	s1,s1,-650 # 800146d0 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b17          	auipc	s6,0x7
    80001966:	906b0b13          	addi	s6,s6,-1786 # 80008268 <digits+0x228>
      p->kstack = KSTACK((int) (p - proc));
    8000196a:	8aa6                	mv	s5,s1
    8000196c:	00006a17          	auipc	s4,0x6
    80001970:	694a0a13          	addi	s4,s4,1684 # 80008000 <etext>
    80001974:	01000937          	lui	s2,0x1000
    80001978:	197d                	addi	s2,s2,-1
    8000197a:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00018997          	auipc	s3,0x18
    80001980:	75498993          	addi	s3,s3,1876 # 8001a0d0 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85da                	mv	a1,s6
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1cc080e7          	jalr	460(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001990:	415487b3          	sub	a5,s1,s5
    80001994:	878d                	srai	a5,a5,0x3
    80001996:	000a3703          	ld	a4,0(s4)
    8000199a:	02e787b3          	mul	a5,a5,a4
    8000199e:	2785                	addiw	a5,a5,1
    800019a0:	00f7979b          	slliw	a5,a5,0xf
    800019a4:	40f907b3          	sub	a5,s2,a5
    800019a8:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	16848493          	addi	s1,s1,360
    800019ae:	fd349be3          	bne	s1,s3,80001984 <procinit+0x6e>
  }
}
    800019b2:	70e2                	ld	ra,56(sp)
    800019b4:	7442                	ld	s0,48(sp)
    800019b6:	74a2                	ld	s1,40(sp)
    800019b8:	7902                	ld	s2,32(sp)
    800019ba:	69e2                	ld	s3,24(sp)
    800019bc:	6a42                	ld	s4,16(sp)
    800019be:	6aa2                	ld	s5,8(sp)
    800019c0:	6b02                	ld	s6,0(sp)
    800019c2:	6121                	addi	sp,sp,64
    800019c4:	8082                	ret

00000000800019c6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019c6:	1141                	addi	sp,sp,-16
    800019c8:	e422                	sd	s0,8(sp)
    800019ca:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019cc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ce:	2501                	sext.w	a0,a0
    800019d0:	6422                	ld	s0,8(sp)
    800019d2:	0141                	addi	sp,sp,16
    800019d4:	8082                	ret

00000000800019d6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
    800019dc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019de:	2781                	sext.w	a5,a5
    800019e0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e2:	00013517          	auipc	a0,0x13
    800019e6:	8ee50513          	addi	a0,a0,-1810 # 800142d0 <cpus>
    800019ea:	953e                	add	a0,a0,a5
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019f2:	1101                	addi	sp,sp,-32
    800019f4:	ec06                	sd	ra,24(sp)
    800019f6:	e822                	sd	s0,16(sp)
    800019f8:	e426                	sd	s1,8(sp)
    800019fa:	1000                	addi	s0,sp,32
  push_off();
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	19c080e7          	jalr	412(ra) # 80000b98 <push_off>
    80001a04:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a06:	2781                	sext.w	a5,a5
    80001a08:	079e                	slli	a5,a5,0x7
    80001a0a:	00013717          	auipc	a4,0x13
    80001a0e:	89670713          	addi	a4,a4,-1898 # 800142a0 <pid_lock>
    80001a12:	97ba                	add	a5,a5,a4
    80001a14:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	222080e7          	jalr	546(ra) # 80000c38 <pop_off>
  return p;
}
    80001a1e:	8526                	mv	a0,s1
    80001a20:	60e2                	ld	ra,24(sp)
    80001a22:	6442                	ld	s0,16(sp)
    80001a24:	64a2                	ld	s1,8(sp)
    80001a26:	6105                	addi	sp,sp,32
    80001a28:	8082                	ret

0000000080001a2a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a2a:	1141                	addi	sp,sp,-16
    80001a2c:	e406                	sd	ra,8(sp)
    80001a2e:	e022                	sd	s0,0(sp)
    80001a30:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a32:	00000097          	auipc	ra,0x0
    80001a36:	fc0080e7          	jalr	-64(ra) # 800019f2 <myproc>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	25e080e7          	jalr	606(ra) # 80000c98 <release>

  if (first) {
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	e3e7a783          	lw	a5,-450(a5) # 80008880 <first.1672>
    80001a4a:	eb89                	bnez	a5,80001a5c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a4c:	00001097          	auipc	ra,0x1
    80001a50:	c0a080e7          	jalr	-1014(ra) # 80002656 <usertrapret>
}
    80001a54:	60a2                	ld	ra,8(sp)
    80001a56:	6402                	ld	s0,0(sp)
    80001a58:	0141                	addi	sp,sp,16
    80001a5a:	8082                	ret
    first = 0;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	e207a223          	sw	zero,-476(a5) # 80008880 <first.1672>
    fsinit(ROOTDEV);
    80001a64:	4505                	li	a0,1
    80001a66:	00002097          	auipc	ra,0x2
    80001a6a:	932080e7          	jalr	-1742(ra) # 80003398 <fsinit>
    80001a6e:	bff9                	j	80001a4c <forkret+0x22>

0000000080001a70 <allocpid>:
allocpid() {
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a7c:	00013917          	auipc	s2,0x13
    80001a80:	82490913          	addi	s2,s2,-2012 # 800142a0 <pid_lock>
    80001a84:	854a                	mv	a0,s2
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	15e080e7          	jalr	350(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	df678793          	addi	a5,a5,-522 # 80008884 <nextpid>
    80001a96:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a98:	0014871b          	addiw	a4,s1,1
    80001a9c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a9e:	854a                	mv	a0,s2
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	1f8080e7          	jalr	504(ra) # 80000c98 <release>
}
    80001aa8:	8526                	mv	a0,s1
    80001aaa:	60e2                	ld	ra,24(sp)
    80001aac:	6442                	ld	s0,16(sp)
    80001aae:	64a2                	ld	s1,8(sp)
    80001ab0:	6902                	ld	s2,0(sp)
    80001ab2:	6105                	addi	sp,sp,32
    80001ab4:	8082                	ret

0000000080001ab6 <proc_pagetable>:
{
    80001ab6:	1101                	addi	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	e04a                	sd	s2,0(sp)
    80001ac0:	1000                	addi	s0,sp,32
    80001ac2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	8b8080e7          	jalr	-1864(ra) # 8000137c <uvmcreate>
    80001acc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ace:	c121                	beqz	a0,80001b0e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad0:	4729                	li	a4,10
    80001ad2:	00005697          	auipc	a3,0x5
    80001ad6:	52e68693          	addi	a3,a3,1326 # 80007000 <_trampoline>
    80001ada:	6611                	lui	a2,0x4
    80001adc:	010005b7          	lui	a1,0x1000
    80001ae0:	15fd                	addi	a1,a1,-1
    80001ae2:	05ba                	slli	a1,a1,0xe
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	60e080e7          	jalr	1550(ra) # 800010f2 <mappages>
    80001aec:	02054863          	bltz	a0,80001b1c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af0:	4719                	li	a4,6
    80001af2:	05893683          	ld	a3,88(s2)
    80001af6:	6611                	lui	a2,0x4
    80001af8:	008005b7          	lui	a1,0x800
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05be                	slli	a1,a1,0xf
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	5f0080e7          	jalr	1520(ra) # 800010f2 <mappages>
    80001b0a:	02054163          	bltz	a0,80001b2c <proc_pagetable+0x76>
}
    80001b0e:	8526                	mv	a0,s1
    80001b10:	60e2                	ld	ra,24(sp)
    80001b12:	6442                	ld	s0,16(sp)
    80001b14:	64a2                	ld	s1,8(sp)
    80001b16:	6902                	ld	s2,0(sp)
    80001b18:	6105                	addi	sp,sp,32
    80001b1a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b1c:	4581                	li	a1,0
    80001b1e:	8526                	mv	a0,s1
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	a58080e7          	jalr	-1448(ra) # 80001578 <uvmfree>
    return 0;
    80001b28:	4481                	li	s1,0
    80001b2a:	b7d5                	j	80001b0e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2c:	4681                	li	a3,0
    80001b2e:	4605                	li	a2,1
    80001b30:	010005b7          	lui	a1,0x1000
    80001b34:	15fd                	addi	a1,a1,-1
    80001b36:	05ba                	slli	a1,a1,0xe
    80001b38:	8526                	mv	a0,s1
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	77e080e7          	jalr	1918(ra) # 800012b8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b42:	4581                	li	a1,0
    80001b44:	8526                	mv	a0,s1
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	a32080e7          	jalr	-1486(ra) # 80001578 <uvmfree>
    return 0;
    80001b4e:	4481                	li	s1,0
    80001b50:	bf7d                	j	80001b0e <proc_pagetable+0x58>

0000000080001b52 <proc_freepagetable>:
{
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
    80001b5e:	84aa                	mv	s1,a0
    80001b60:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	010005b7          	lui	a1,0x1000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05ba                	slli	a1,a1,0xe
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	74a080e7          	jalr	1866(ra) # 800012b8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b76:	4681                	li	a3,0
    80001b78:	4605                	li	a2,1
    80001b7a:	008005b7          	lui	a1,0x800
    80001b7e:	15fd                	addi	a1,a1,-1
    80001b80:	05be                	slli	a1,a1,0xf
    80001b82:	8526                	mv	a0,s1
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	734080e7          	jalr	1844(ra) # 800012b8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b8c:	85ca                	mv	a1,s2
    80001b8e:	8526                	mv	a0,s1
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	9e8080e7          	jalr	-1560(ra) # 80001578 <uvmfree>
}
    80001b98:	60e2                	ld	ra,24(sp)
    80001b9a:	6442                	ld	s0,16(sp)
    80001b9c:	64a2                	ld	s1,8(sp)
    80001b9e:	6902                	ld	s2,0(sp)
    80001ba0:	6105                	addi	sp,sp,32
    80001ba2:	8082                	ret

0000000080001ba4 <freeproc>:
{
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb0:	6d28                	ld	a0,88(a0)
    80001bb2:	c509                	beqz	a0,80001bbc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	e44080e7          	jalr	-444(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bbc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc0:	68a8                	ld	a0,80(s1)
    80001bc2:	c511                	beqz	a0,80001bce <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc4:	64ac                	ld	a1,72(s1)
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	f8c080e7          	jalr	-116(ra) # 80001b52 <proc_freepagetable>
  p->pagetable = 0;
    80001bce:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bda:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bde:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001be6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bea:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bee:	0004ac23          	sw	zero,24(s1)
}
    80001bf2:	60e2                	ld	ra,24(sp)
    80001bf4:	6442                	ld	s0,16(sp)
    80001bf6:	64a2                	ld	s1,8(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <allocproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	e04a                	sd	s2,0(sp)
    80001c06:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c08:	00013497          	auipc	s1,0x13
    80001c0c:	ac848493          	addi	s1,s1,-1336 # 800146d0 <proc>
    80001c10:	00018917          	auipc	s2,0x18
    80001c14:	4c090913          	addi	s2,s2,1216 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fca080e7          	jalr	-54(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c22:	4c9c                	lw	a5,24(s1)
    80001c24:	cf81                	beqz	a5,80001c3c <allocproc+0x40>
      release(&p->lock);
    80001c26:	8526                	mv	a0,s1
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	070080e7          	jalr	112(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c30:	16848493          	addi	s1,s1,360
    80001c34:	ff2492e3          	bne	s1,s2,80001c18 <allocproc+0x1c>
  return 0;
    80001c38:	4481                	li	s1,0
    80001c3a:	a889                	j	80001c8c <allocproc+0x90>
  p->pid = allocpid();
    80001c3c:	00000097          	auipc	ra,0x0
    80001c40:	e34080e7          	jalr	-460(ra) # 80001a70 <allocpid>
    80001c44:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c46:	4785                	li	a5,1
    80001c48:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	eaa080e7          	jalr	-342(ra) # 80000af4 <kalloc>
    80001c52:	892a                	mv	s2,a0
    80001c54:	eca8                	sd	a0,88(s1)
    80001c56:	c131                	beqz	a0,80001c9a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	e5c080e7          	jalr	-420(ra) # 80001ab6 <proc_pagetable>
    80001c62:	892a                	mv	s2,a0
    80001c64:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c66:	c531                	beqz	a0,80001cb2 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c68:	07000613          	li	a2,112
    80001c6c:	4581                	li	a1,0
    80001c6e:	06048513          	addi	a0,s1,96
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	06e080e7          	jalr	110(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c7a:	00000797          	auipc	a5,0x0
    80001c7e:	db078793          	addi	a5,a5,-592 # 80001a2a <forkret>
    80001c82:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c84:	60bc                	ld	a5,64(s1)
    80001c86:	6711                	lui	a4,0x4
    80001c88:	97ba                	add	a5,a5,a4
    80001c8a:	f4bc                	sd	a5,104(s1)
}
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	60e2                	ld	ra,24(sp)
    80001c90:	6442                	ld	s0,16(sp)
    80001c92:	64a2                	ld	s1,8(sp)
    80001c94:	6902                	ld	s2,0(sp)
    80001c96:	6105                	addi	sp,sp,32
    80001c98:	8082                	ret
    freeproc(p);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	f08080e7          	jalr	-248(ra) # 80001ba4 <freeproc>
    release(&p->lock);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	ff2080e7          	jalr	-14(ra) # 80000c98 <release>
    return 0;
    80001cae:	84ca                	mv	s1,s2
    80001cb0:	bff1                	j	80001c8c <allocproc+0x90>
    freeproc(p);
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	ef0080e7          	jalr	-272(ra) # 80001ba4 <freeproc>
    release(&p->lock);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
    return 0;
    80001cc6:	84ca                	mv	s1,s2
    80001cc8:	b7d1                	j	80001c8c <allocproc+0x90>

0000000080001cca <userinit>:
{
    80001cca:	1101                	addi	sp,sp,-32
    80001ccc:	ec06                	sd	ra,24(sp)
    80001cce:	e822                	sd	s0,16(sp)
    80001cd0:	e426                	sd	s1,8(sp)
    80001cd2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	f28080e7          	jalr	-216(ra) # 80001bfc <allocproc>
    80001cdc:	84aa                	mv	s1,a0
  initproc = p;
    80001cde:	0000a797          	auipc	a5,0xa
    80001ce2:	34a7b523          	sd	a0,842(a5) # 8000c028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce6:	03400613          	li	a2,52
    80001cea:	00007597          	auipc	a1,0x7
    80001cee:	ba658593          	addi	a1,a1,-1114 # 80008890 <initcode>
    80001cf2:	6928                	ld	a0,80(a0)
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	6b6080e7          	jalr	1718(ra) # 800013aa <uvminit>
  p->sz = PGSIZE;
    80001cfc:	6791                	lui	a5,0x4
    80001cfe:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d00:	6cb8                	ld	a4,88(s1)
    80001d02:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0a:	4641                	li	a2,16
    80001d0c:	00006597          	auipc	a1,0x6
    80001d10:	56458593          	addi	a1,a1,1380 # 80008270 <digits+0x230>
    80001d14:	15848513          	addi	a0,s1,344
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	11a080e7          	jalr	282(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d20:	00006517          	auipc	a0,0x6
    80001d24:	56050513          	addi	a0,a0,1376 # 80008280 <digits+0x240>
    80001d28:	00002097          	auipc	ra,0x2
    80001d2c:	09e080e7          	jalr	158(ra) # 80003dc6 <namei>
    80001d30:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d34:	478d                	li	a5,3
    80001d36:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	f5e080e7          	jalr	-162(ra) # 80000c98 <release>
}
    80001d42:	60e2                	ld	ra,24(sp)
    80001d44:	6442                	ld	s0,16(sp)
    80001d46:	64a2                	ld	s1,8(sp)
    80001d48:	6105                	addi	sp,sp,32
    80001d4a:	8082                	ret

0000000080001d4c <growproc>:
{
    80001d4c:	1101                	addi	sp,sp,-32
    80001d4e:	ec06                	sd	ra,24(sp)
    80001d50:	e822                	sd	s0,16(sp)
    80001d52:	e426                	sd	s1,8(sp)
    80001d54:	e04a                	sd	s2,0(sp)
    80001d56:	1000                	addi	s0,sp,32
    80001d58:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5a:	00000097          	auipc	ra,0x0
    80001d5e:	c98080e7          	jalr	-872(ra) # 800019f2 <myproc>
    80001d62:	892a                	mv	s2,a0
  sz = p->sz;
    80001d64:	652c                	ld	a1,72(a0)
    80001d66:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d6a:	00904f63          	bgtz	s1,80001d88 <growproc+0x3c>
  } else if(n < 0){
    80001d6e:	0204cc63          	bltz	s1,80001da6 <growproc+0x5a>
  p->sz = sz;
    80001d72:	1602                	slli	a2,a2,0x20
    80001d74:	9201                	srli	a2,a2,0x20
    80001d76:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d7a:	4501                	li	a0,0
}
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6902                	ld	s2,0(sp)
    80001d84:	6105                	addi	sp,sp,32
    80001d86:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	6928                	ld	a0,80(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	6d0080e7          	jalr	1744(ra) # 80001464 <uvmalloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	fa69                	bnez	a2,80001d72 <growproc+0x26>
      return -1;
    80001da2:	557d                	li	a0,-1
    80001da4:	bfe1                	j	80001d7c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da6:	9e25                	addw	a2,a2,s1
    80001da8:	1602                	slli	a2,a2,0x20
    80001daa:	9201                	srli	a2,a2,0x20
    80001dac:	1582                	slli	a1,a1,0x20
    80001dae:	9181                	srli	a1,a1,0x20
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	66a080e7          	jalr	1642(ra) # 8000141c <uvmdealloc>
    80001dba:	0005061b          	sext.w	a2,a0
    80001dbe:	bf55                	j	80001d72 <growproc+0x26>

0000000080001dc0 <fork>:
{
    80001dc0:	7179                	addi	sp,sp,-48
    80001dc2:	f406                	sd	ra,40(sp)
    80001dc4:	f022                	sd	s0,32(sp)
    80001dc6:	ec26                	sd	s1,24(sp)
    80001dc8:	e84a                	sd	s2,16(sp)
    80001dca:	e44e                	sd	s3,8(sp)
    80001dcc:	e052                	sd	s4,0(sp)
    80001dce:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	c22080e7          	jalr	-990(ra) # 800019f2 <myproc>
    80001dd8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	e22080e7          	jalr	-478(ra) # 80001bfc <allocproc>
    80001de2:	10050b63          	beqz	a0,80001ef8 <fork+0x138>
    80001de6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de8:	04893603          	ld	a2,72(s2)
    80001dec:	692c                	ld	a1,80(a0)
    80001dee:	05093503          	ld	a0,80(s2)
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	7be080e7          	jalr	1982(ra) # 800015b0 <uvmcopy>
    80001dfa:	04054663          	bltz	a0,80001e46 <fork+0x86>
  np->sz = p->sz;
    80001dfe:	04893783          	ld	a5,72(s2)
    80001e02:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e06:	05893683          	ld	a3,88(s2)
    80001e0a:	87b6                	mv	a5,a3
    80001e0c:	0589b703          	ld	a4,88(s3)
    80001e10:	12068693          	addi	a3,a3,288
    80001e14:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001e18:	6788                	ld	a0,8(a5)
    80001e1a:	6b8c                	ld	a1,16(a5)
    80001e1c:	6f90                	ld	a2,24(a5)
    80001e1e:	01073023          	sd	a6,0(a4)
    80001e22:	e708                	sd	a0,8(a4)
    80001e24:	eb0c                	sd	a1,16(a4)
    80001e26:	ef10                	sd	a2,24(a4)
    80001e28:	02078793          	addi	a5,a5,32
    80001e2c:	02070713          	addi	a4,a4,32
    80001e30:	fed792e3          	bne	a5,a3,80001e14 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e34:	0589b783          	ld	a5,88(s3)
    80001e38:	0607b823          	sd	zero,112(a5)
    80001e3c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e40:	15000a13          	li	s4,336
    80001e44:	a03d                	j	80001e72 <fork+0xb2>
    freeproc(np);
    80001e46:	854e                	mv	a0,s3
    80001e48:	00000097          	auipc	ra,0x0
    80001e4c:	d5c080e7          	jalr	-676(ra) # 80001ba4 <freeproc>
    release(&np->lock);
    80001e50:	854e                	mv	a0,s3
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e46080e7          	jalr	-442(ra) # 80000c98 <release>
    return -1;
    80001e5a:	5a7d                	li	s4,-1
    80001e5c:	a069                	j	80001ee6 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e5e:	00002097          	auipc	ra,0x2
    80001e62:	5fe080e7          	jalr	1534(ra) # 8000445c <filedup>
    80001e66:	009987b3          	add	a5,s3,s1
    80001e6a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e6c:	04a1                	addi	s1,s1,8
    80001e6e:	01448763          	beq	s1,s4,80001e7c <fork+0xbc>
    if(p->ofile[i])
    80001e72:	009907b3          	add	a5,s2,s1
    80001e76:	6388                	ld	a0,0(a5)
    80001e78:	f17d                	bnez	a0,80001e5e <fork+0x9e>
    80001e7a:	bfcd                	j	80001e6c <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e7c:	15093503          	ld	a0,336(s2)
    80001e80:	00001097          	auipc	ra,0x1
    80001e84:	752080e7          	jalr	1874(ra) # 800035d2 <idup>
    80001e88:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8c:	4641                	li	a2,16
    80001e8e:	15890593          	addi	a1,s2,344
    80001e92:	15898513          	addi	a0,s3,344
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f9c080e7          	jalr	-100(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001e9e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001ea2:	854e                	mv	a0,s3
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	df4080e7          	jalr	-524(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eac:	00012497          	auipc	s1,0x12
    80001eb0:	40c48493          	addi	s1,s1,1036 # 800142b8 <wait_lock>
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	d2e080e7          	jalr	-722(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ebe:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	dd4080e7          	jalr	-556(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ecc:	854e                	mv	a0,s3
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	d16080e7          	jalr	-746(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ed6:	478d                	li	a5,3
    80001ed8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
}
    80001ee6:	8552                	mv	a0,s4
    80001ee8:	70a2                	ld	ra,40(sp)
    80001eea:	7402                	ld	s0,32(sp)
    80001eec:	64e2                	ld	s1,24(sp)
    80001eee:	6942                	ld	s2,16(sp)
    80001ef0:	69a2                	ld	s3,8(sp)
    80001ef2:	6a02                	ld	s4,0(sp)
    80001ef4:	6145                	addi	sp,sp,48
    80001ef6:	8082                	ret
    return -1;
    80001ef8:	5a7d                	li	s4,-1
    80001efa:	b7f5                	j	80001ee6 <fork+0x126>

0000000080001efc <scheduler>:
{
    80001efc:	7139                	addi	sp,sp,-64
    80001efe:	fc06                	sd	ra,56(sp)
    80001f00:	f822                	sd	s0,48(sp)
    80001f02:	f426                	sd	s1,40(sp)
    80001f04:	f04a                	sd	s2,32(sp)
    80001f06:	ec4e                	sd	s3,24(sp)
    80001f08:	e852                	sd	s4,16(sp)
    80001f0a:	e456                	sd	s5,8(sp)
    80001f0c:	e05a                	sd	s6,0(sp)
    80001f0e:	0080                	addi	s0,sp,64
    80001f10:	8792                	mv	a5,tp
  int id = r_tp();
    80001f12:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f14:	00779a93          	slli	s5,a5,0x7
    80001f18:	00012717          	auipc	a4,0x12
    80001f1c:	38870713          	addi	a4,a4,904 # 800142a0 <pid_lock>
    80001f20:	9756                	add	a4,a4,s5
    80001f22:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f26:	00012717          	auipc	a4,0x12
    80001f2a:	3b270713          	addi	a4,a4,946 # 800142d8 <cpus+0x8>
    80001f2e:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f30:	498d                	li	s3,3
        p->state = RUNNING;
    80001f32:	4b11                	li	s6,4
        c->proc = p;
    80001f34:	079e                	slli	a5,a5,0x7
    80001f36:	00012a17          	auipc	s4,0x12
    80001f3a:	36aa0a13          	addi	s4,s4,874 # 800142a0 <pid_lock>
    80001f3e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f40:	00018917          	auipc	s2,0x18
    80001f44:	19090913          	addi	s2,s2,400 # 8001a0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f50:	10079073          	csrw	sstatus,a5
    80001f54:	00012497          	auipc	s1,0x12
    80001f58:	77c48493          	addi	s1,s1,1916 # 800146d0 <proc>
    80001f5c:	a03d                	j	80001f8a <scheduler+0x8e>
        p->state = RUNNING;
    80001f5e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f62:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f66:	06048593          	addi	a1,s1,96
    80001f6a:	8556                	mv	a0,s5
    80001f6c:	00000097          	auipc	ra,0x0
    80001f70:	640080e7          	jalr	1600(ra) # 800025ac <swtch>
        c->proc = 0;
    80001f74:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f78:	8526                	mv	a0,s1
    80001f7a:	fffff097          	auipc	ra,0xfffff
    80001f7e:	d1e080e7          	jalr	-738(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	16848493          	addi	s1,s1,360
    80001f86:	fd2481e3          	beq	s1,s2,80001f48 <scheduler+0x4c>
      acquire(&p->lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	c58080e7          	jalr	-936(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001f94:	4c9c                	lw	a5,24(s1)
    80001f96:	ff3791e3          	bne	a5,s3,80001f78 <scheduler+0x7c>
    80001f9a:	b7d1                	j	80001f5e <scheduler+0x62>

0000000080001f9c <sched>:
{
    80001f9c:	7179                	addi	sp,sp,-48
    80001f9e:	f406                	sd	ra,40(sp)
    80001fa0:	f022                	sd	s0,32(sp)
    80001fa2:	ec26                	sd	s1,24(sp)
    80001fa4:	e84a                	sd	s2,16(sp)
    80001fa6:	e44e                	sd	s3,8(sp)
    80001fa8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001faa:	00000097          	auipc	ra,0x0
    80001fae:	a48080e7          	jalr	-1464(ra) # 800019f2 <myproc>
    80001fb2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	bb6080e7          	jalr	-1098(ra) # 80000b6a <holding>
    80001fbc:	c93d                	beqz	a0,80002032 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbe:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	00012717          	auipc	a4,0x12
    80001fc8:	2dc70713          	addi	a4,a4,732 # 800142a0 <pid_lock>
    80001fcc:	97ba                	add	a5,a5,a4
    80001fce:	0a87a703          	lw	a4,168(a5)
    80001fd2:	4785                	li	a5,1
    80001fd4:	06f71763          	bne	a4,a5,80002042 <sched+0xa6>
  if(p->state == RUNNING)
    80001fd8:	4c98                	lw	a4,24(s1)
    80001fda:	4791                	li	a5,4
    80001fdc:	06f70b63          	beq	a4,a5,80002052 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fe6:	efb5                	bnez	a5,80002062 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fea:	00012917          	auipc	s2,0x12
    80001fee:	2b690913          	addi	s2,s2,694 # 800142a0 <pid_lock>
    80001ff2:	2781                	sext.w	a5,a5
    80001ff4:	079e                	slli	a5,a5,0x7
    80001ff6:	97ca                	add	a5,a5,s2
    80001ff8:	0ac7a983          	lw	s3,172(a5)
    80001ffc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00012597          	auipc	a1,0x12
    80002006:	2d658593          	addi	a1,a1,726 # 800142d8 <cpus+0x8>
    8000200a:	95be                	add	a1,a1,a5
    8000200c:	06048513          	addi	a0,s1,96
    80002010:	00000097          	auipc	ra,0x0
    80002014:	59c080e7          	jalr	1436(ra) # 800025ac <swtch>
    80002018:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	97ca                	add	a5,a5,s2
    80002020:	0b37a623          	sw	s3,172(a5)
}
    80002024:	70a2                	ld	ra,40(sp)
    80002026:	7402                	ld	s0,32(sp)
    80002028:	64e2                	ld	s1,24(sp)
    8000202a:	6942                	ld	s2,16(sp)
    8000202c:	69a2                	ld	s3,8(sp)
    8000202e:	6145                	addi	sp,sp,48
    80002030:	8082                	ret
    panic("sched p->lock");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	25650513          	addi	a0,a0,598 # 80008288 <digits+0x248>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	504080e7          	jalr	1284(ra) # 8000053e <panic>
    panic("sched locks");
    80002042:	00006517          	auipc	a0,0x6
    80002046:	25650513          	addi	a0,a0,598 # 80008298 <digits+0x258>
    8000204a:	ffffe097          	auipc	ra,0xffffe
    8000204e:	4f4080e7          	jalr	1268(ra) # 8000053e <panic>
    panic("sched running");
    80002052:	00006517          	auipc	a0,0x6
    80002056:	25650513          	addi	a0,a0,598 # 800082a8 <digits+0x268>
    8000205a:	ffffe097          	auipc	ra,0xffffe
    8000205e:	4e4080e7          	jalr	1252(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	25650513          	addi	a0,a0,598 # 800082b8 <digits+0x278>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	4d4080e7          	jalr	1236(ra) # 8000053e <panic>

0000000080002072 <yield>:
{
    80002072:	1101                	addi	sp,sp,-32
    80002074:	ec06                	sd	ra,24(sp)
    80002076:	e822                	sd	s0,16(sp)
    80002078:	e426                	sd	s1,8(sp)
    8000207a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	976080e7          	jalr	-1674(ra) # 800019f2 <myproc>
    80002084:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000208e:	478d                	li	a5,3
    80002090:	cc9c                	sw	a5,24(s1)
  sched();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	f0a080e7          	jalr	-246(ra) # 80001f9c <sched>
  release(&p->lock);
    8000209a:	8526                	mv	a0,s1
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	bfc080e7          	jalr	-1028(ra) # 80000c98 <release>
}
    800020a4:	60e2                	ld	ra,24(sp)
    800020a6:	6442                	ld	s0,16(sp)
    800020a8:	64a2                	ld	s1,8(sp)
    800020aa:	6105                	addi	sp,sp,32
    800020ac:	8082                	ret

00000000800020ae <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ae:	7179                	addi	sp,sp,-48
    800020b0:	f406                	sd	ra,40(sp)
    800020b2:	f022                	sd	s0,32(sp)
    800020b4:	ec26                	sd	s1,24(sp)
    800020b6:	e84a                	sd	s2,16(sp)
    800020b8:	e44e                	sd	s3,8(sp)
    800020ba:	1800                	addi	s0,sp,48
    800020bc:	89aa                	mv	s3,a0
    800020be:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	932080e7          	jalr	-1742(ra) # 800019f2 <myproc>
    800020c8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	b1a080e7          	jalr	-1254(ra) # 80000be4 <acquire>
  release(lk);
    800020d2:	854a                	mv	a0,s2
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	bc4080e7          	jalr	-1084(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800020dc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020e0:	4789                	li	a5,2
    800020e2:	cc9c                	sw	a5,24(s1)

  sched();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	eb8080e7          	jalr	-328(ra) # 80001f9c <sched>

  // Tidy up.
  p->chan = 0;
    800020ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	ba6080e7          	jalr	-1114(ra) # 80000c98 <release>
  acquire(lk);
    800020fa:	854a                	mv	a0,s2
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	ae8080e7          	jalr	-1304(ra) # 80000be4 <acquire>
}
    80002104:	70a2                	ld	ra,40(sp)
    80002106:	7402                	ld	s0,32(sp)
    80002108:	64e2                	ld	s1,24(sp)
    8000210a:	6942                	ld	s2,16(sp)
    8000210c:	69a2                	ld	s3,8(sp)
    8000210e:	6145                	addi	sp,sp,48
    80002110:	8082                	ret

0000000080002112 <wait>:
{
    80002112:	715d                	addi	sp,sp,-80
    80002114:	e486                	sd	ra,72(sp)
    80002116:	e0a2                	sd	s0,64(sp)
    80002118:	fc26                	sd	s1,56(sp)
    8000211a:	f84a                	sd	s2,48(sp)
    8000211c:	f44e                	sd	s3,40(sp)
    8000211e:	f052                	sd	s4,32(sp)
    80002120:	ec56                	sd	s5,24(sp)
    80002122:	e85a                	sd	s6,16(sp)
    80002124:	e45e                	sd	s7,8(sp)
    80002126:	e062                	sd	s8,0(sp)
    80002128:	0880                	addi	s0,sp,80
    8000212a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	8c6080e7          	jalr	-1850(ra) # 800019f2 <myproc>
    80002134:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002136:	00012517          	auipc	a0,0x12
    8000213a:	18250513          	addi	a0,a0,386 # 800142b8 <wait_lock>
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	aa6080e7          	jalr	-1370(ra) # 80000be4 <acquire>
    havekids = 0;
    80002146:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002148:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000214a:	00018997          	auipc	s3,0x18
    8000214e:	f8698993          	addi	s3,s3,-122 # 8001a0d0 <tickslock>
        havekids = 1;
    80002152:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002154:	00012c17          	auipc	s8,0x12
    80002158:	164c0c13          	addi	s8,s8,356 # 800142b8 <wait_lock>
    havekids = 0;
    8000215c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000215e:	00012497          	auipc	s1,0x12
    80002162:	57248493          	addi	s1,s1,1394 # 800146d0 <proc>
    80002166:	a0bd                	j	800021d4 <wait+0xc2>
          pid = np->pid;
    80002168:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000216c:	000b0e63          	beqz	s6,80002188 <wait+0x76>
    80002170:	4691                	li	a3,4
    80002172:	02c48613          	addi	a2,s1,44
    80002176:	85da                	mv	a1,s6
    80002178:	05093503          	ld	a0,80(s2)
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	538080e7          	jalr	1336(ra) # 800016b4 <copyout>
    80002184:	02054563          	bltz	a0,800021ae <wait+0x9c>
          freeproc(np);
    80002188:	8526                	mv	a0,s1
    8000218a:	00000097          	auipc	ra,0x0
    8000218e:	a1a080e7          	jalr	-1510(ra) # 80001ba4 <freeproc>
          release(&np->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
          release(&wait_lock);
    8000219c:	00012517          	auipc	a0,0x12
    800021a0:	11c50513          	addi	a0,a0,284 # 800142b8 <wait_lock>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	af4080e7          	jalr	-1292(ra) # 80000c98 <release>
          return pid;
    800021ac:	a09d                	j	80002212 <wait+0x100>
            release(&np->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ae8080e7          	jalr	-1304(ra) # 80000c98 <release>
            release(&wait_lock);
    800021b8:	00012517          	auipc	a0,0x12
    800021bc:	10050513          	addi	a0,a0,256 # 800142b8 <wait_lock>
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	ad8080e7          	jalr	-1320(ra) # 80000c98 <release>
            return -1;
    800021c8:	59fd                	li	s3,-1
    800021ca:	a0a1                	j	80002212 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021cc:	16848493          	addi	s1,s1,360
    800021d0:	03348463          	beq	s1,s3,800021f8 <wait+0xe6>
      if(np->parent == p){
    800021d4:	7c9c                	ld	a5,56(s1)
    800021d6:	ff279be3          	bne	a5,s2,800021cc <wait+0xba>
        acquire(&np->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a08080e7          	jalr	-1528(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021e4:	4c9c                	lw	a5,24(s1)
    800021e6:	f94781e3          	beq	a5,s4,80002168 <wait+0x56>
        release(&np->lock);
    800021ea:	8526                	mv	a0,s1
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	aac080e7          	jalr	-1364(ra) # 80000c98 <release>
        havekids = 1;
    800021f4:	8756                	mv	a4,s5
    800021f6:	bfd9                	j	800021cc <wait+0xba>
    if(!havekids || p->killed){
    800021f8:	c701                	beqz	a4,80002200 <wait+0xee>
    800021fa:	02892783          	lw	a5,40(s2)
    800021fe:	c79d                	beqz	a5,8000222c <wait+0x11a>
      release(&wait_lock);
    80002200:	00012517          	auipc	a0,0x12
    80002204:	0b850513          	addi	a0,a0,184 # 800142b8 <wait_lock>
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	a90080e7          	jalr	-1392(ra) # 80000c98 <release>
      return -1;
    80002210:	59fd                	li	s3,-1
}
    80002212:	854e                	mv	a0,s3
    80002214:	60a6                	ld	ra,72(sp)
    80002216:	6406                	ld	s0,64(sp)
    80002218:	74e2                	ld	s1,56(sp)
    8000221a:	7942                	ld	s2,48(sp)
    8000221c:	79a2                	ld	s3,40(sp)
    8000221e:	7a02                	ld	s4,32(sp)
    80002220:	6ae2                	ld	s5,24(sp)
    80002222:	6b42                	ld	s6,16(sp)
    80002224:	6ba2                	ld	s7,8(sp)
    80002226:	6c02                	ld	s8,0(sp)
    80002228:	6161                	addi	sp,sp,80
    8000222a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000222c:	85e2                	mv	a1,s8
    8000222e:	854a                	mv	a0,s2
    80002230:	00000097          	auipc	ra,0x0
    80002234:	e7e080e7          	jalr	-386(ra) # 800020ae <sleep>
    havekids = 0;
    80002238:	b715                	j	8000215c <wait+0x4a>

000000008000223a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000223a:	7139                	addi	sp,sp,-64
    8000223c:	fc06                	sd	ra,56(sp)
    8000223e:	f822                	sd	s0,48(sp)
    80002240:	f426                	sd	s1,40(sp)
    80002242:	f04a                	sd	s2,32(sp)
    80002244:	ec4e                	sd	s3,24(sp)
    80002246:	e852                	sd	s4,16(sp)
    80002248:	e456                	sd	s5,8(sp)
    8000224a:	0080                	addi	s0,sp,64
    8000224c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000224e:	00012497          	auipc	s1,0x12
    80002252:	48248493          	addi	s1,s1,1154 # 800146d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002256:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002258:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000225a:	00018917          	auipc	s2,0x18
    8000225e:	e7690913          	addi	s2,s2,-394 # 8001a0d0 <tickslock>
    80002262:	a821                	j	8000227a <wakeup+0x40>
        p->state = RUNNABLE;
    80002264:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002268:	8526                	mv	a0,s1
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	a2e080e7          	jalr	-1490(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002272:	16848493          	addi	s1,s1,360
    80002276:	03248463          	beq	s1,s2,8000229e <wakeup+0x64>
    if(p != myproc()){
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	778080e7          	jalr	1912(ra) # 800019f2 <myproc>
    80002282:	fea488e3          	beq	s1,a0,80002272 <wakeup+0x38>
      acquire(&p->lock);
    80002286:	8526                	mv	a0,s1
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	95c080e7          	jalr	-1700(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002290:	4c9c                	lw	a5,24(s1)
    80002292:	fd379be3          	bne	a5,s3,80002268 <wakeup+0x2e>
    80002296:	709c                	ld	a5,32(s1)
    80002298:	fd4798e3          	bne	a5,s4,80002268 <wakeup+0x2e>
    8000229c:	b7e1                	j	80002264 <wakeup+0x2a>
    }
  }
}
    8000229e:	70e2                	ld	ra,56(sp)
    800022a0:	7442                	ld	s0,48(sp)
    800022a2:	74a2                	ld	s1,40(sp)
    800022a4:	7902                	ld	s2,32(sp)
    800022a6:	69e2                	ld	s3,24(sp)
    800022a8:	6a42                	ld	s4,16(sp)
    800022aa:	6aa2                	ld	s5,8(sp)
    800022ac:	6121                	addi	sp,sp,64
    800022ae:	8082                	ret

00000000800022b0 <reparent>:
{
    800022b0:	7179                	addi	sp,sp,-48
    800022b2:	f406                	sd	ra,40(sp)
    800022b4:	f022                	sd	s0,32(sp)
    800022b6:	ec26                	sd	s1,24(sp)
    800022b8:	e84a                	sd	s2,16(sp)
    800022ba:	e44e                	sd	s3,8(sp)
    800022bc:	e052                	sd	s4,0(sp)
    800022be:	1800                	addi	s0,sp,48
    800022c0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022c2:	00012497          	auipc	s1,0x12
    800022c6:	40e48493          	addi	s1,s1,1038 # 800146d0 <proc>
      pp->parent = initproc;
    800022ca:	0000aa17          	auipc	s4,0xa
    800022ce:	d5ea0a13          	addi	s4,s4,-674 # 8000c028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022d2:	00018997          	auipc	s3,0x18
    800022d6:	dfe98993          	addi	s3,s3,-514 # 8001a0d0 <tickslock>
    800022da:	a029                	j	800022e4 <reparent+0x34>
    800022dc:	16848493          	addi	s1,s1,360
    800022e0:	01348d63          	beq	s1,s3,800022fa <reparent+0x4a>
    if(pp->parent == p){
    800022e4:	7c9c                	ld	a5,56(s1)
    800022e6:	ff279be3          	bne	a5,s2,800022dc <reparent+0x2c>
      pp->parent = initproc;
    800022ea:	000a3503          	ld	a0,0(s4)
    800022ee:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022f0:	00000097          	auipc	ra,0x0
    800022f4:	f4a080e7          	jalr	-182(ra) # 8000223a <wakeup>
    800022f8:	b7d5                	j	800022dc <reparent+0x2c>
}
    800022fa:	70a2                	ld	ra,40(sp)
    800022fc:	7402                	ld	s0,32(sp)
    800022fe:	64e2                	ld	s1,24(sp)
    80002300:	6942                	ld	s2,16(sp)
    80002302:	69a2                	ld	s3,8(sp)
    80002304:	6a02                	ld	s4,0(sp)
    80002306:	6145                	addi	sp,sp,48
    80002308:	8082                	ret

000000008000230a <exit>:
{
    8000230a:	7179                	addi	sp,sp,-48
    8000230c:	f406                	sd	ra,40(sp)
    8000230e:	f022                	sd	s0,32(sp)
    80002310:	ec26                	sd	s1,24(sp)
    80002312:	e84a                	sd	s2,16(sp)
    80002314:	e44e                	sd	s3,8(sp)
    80002316:	e052                	sd	s4,0(sp)
    80002318:	1800                	addi	s0,sp,48
    8000231a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	6d6080e7          	jalr	1750(ra) # 800019f2 <myproc>
    80002324:	89aa                	mv	s3,a0
  if(p == initproc)
    80002326:	0000a797          	auipc	a5,0xa
    8000232a:	d027b783          	ld	a5,-766(a5) # 8000c028 <initproc>
    8000232e:	0d050493          	addi	s1,a0,208
    80002332:	15050913          	addi	s2,a0,336
    80002336:	02a79363          	bne	a5,a0,8000235c <exit+0x52>
    panic("init exiting");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	f9650513          	addi	a0,a0,-106 # 800082d0 <digits+0x290>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>
      fileclose(f);
    8000234a:	00002097          	auipc	ra,0x2
    8000234e:	164080e7          	jalr	356(ra) # 800044ae <fileclose>
      p->ofile[fd] = 0;
    80002352:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002356:	04a1                	addi	s1,s1,8
    80002358:	01248563          	beq	s1,s2,80002362 <exit+0x58>
    if(p->ofile[fd]){
    8000235c:	6088                	ld	a0,0(s1)
    8000235e:	f575                	bnez	a0,8000234a <exit+0x40>
    80002360:	bfdd                	j	80002356 <exit+0x4c>
  begin_op();
    80002362:	00002097          	auipc	ra,0x2
    80002366:	c80080e7          	jalr	-896(ra) # 80003fe2 <begin_op>
  iput(p->cwd);
    8000236a:	1509b503          	ld	a0,336(s3)
    8000236e:	00001097          	auipc	ra,0x1
    80002372:	45c080e7          	jalr	1116(ra) # 800037ca <iput>
  end_op();
    80002376:	00002097          	auipc	ra,0x2
    8000237a:	cec080e7          	jalr	-788(ra) # 80004062 <end_op>
  p->cwd = 0;
    8000237e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002382:	00012497          	auipc	s1,0x12
    80002386:	f3648493          	addi	s1,s1,-202 # 800142b8 <wait_lock>
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	858080e7          	jalr	-1960(ra) # 80000be4 <acquire>
  reparent(p);
    80002394:	854e                	mv	a0,s3
    80002396:	00000097          	auipc	ra,0x0
    8000239a:	f1a080e7          	jalr	-230(ra) # 800022b0 <reparent>
  wakeup(p->parent);
    8000239e:	0389b503          	ld	a0,56(s3)
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	e98080e7          	jalr	-360(ra) # 8000223a <wakeup>
  acquire(&p->lock);
    800023aa:	854e                	mv	a0,s3
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023b4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023b8:	4795                	li	a5,5
    800023ba:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8d8080e7          	jalr	-1832(ra) # 80000c98 <release>
  sched();
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	bd4080e7          	jalr	-1068(ra) # 80001f9c <sched>
  panic("zombie exit");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	f1050513          	addi	a0,a0,-240 # 800082e0 <digits+0x2a0>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	166080e7          	jalr	358(ra) # 8000053e <panic>

00000000800023e0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e0:	7179                	addi	sp,sp,-48
    800023e2:	f406                	sd	ra,40(sp)
    800023e4:	f022                	sd	s0,32(sp)
    800023e6:	ec26                	sd	s1,24(sp)
    800023e8:	e84a                	sd	s2,16(sp)
    800023ea:	e44e                	sd	s3,8(sp)
    800023ec:	1800                	addi	s0,sp,48
    800023ee:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f0:	00012497          	auipc	s1,0x12
    800023f4:	2e048493          	addi	s1,s1,736 # 800146d0 <proc>
    800023f8:	00018997          	auipc	s3,0x18
    800023fc:	cd898993          	addi	s3,s3,-808 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    80002400:	8526                	mv	a0,s1
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	7e2080e7          	jalr	2018(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000240a:	589c                	lw	a5,48(s1)
    8000240c:	01278d63          	beq	a5,s2,80002426 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	886080e7          	jalr	-1914(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000241a:	16848493          	addi	s1,s1,360
    8000241e:	ff3491e3          	bne	s1,s3,80002400 <kill+0x20>
  }
  return -1;
    80002422:	557d                	li	a0,-1
    80002424:	a829                	j	8000243e <kill+0x5e>
      p->killed = 1;
    80002426:	4785                	li	a5,1
    80002428:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000242a:	4c98                	lw	a4,24(s1)
    8000242c:	4789                	li	a5,2
    8000242e:	00f70f63          	beq	a4,a5,8000244c <kill+0x6c>
      release(&p->lock);
    80002432:	8526                	mv	a0,s1
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	864080e7          	jalr	-1948(ra) # 80000c98 <release>
      return 0;
    8000243c:	4501                	li	a0,0
}
    8000243e:	70a2                	ld	ra,40(sp)
    80002440:	7402                	ld	s0,32(sp)
    80002442:	64e2                	ld	s1,24(sp)
    80002444:	6942                	ld	s2,16(sp)
    80002446:	69a2                	ld	s3,8(sp)
    80002448:	6145                	addi	sp,sp,48
    8000244a:	8082                	ret
        p->state = RUNNABLE;
    8000244c:	478d                	li	a5,3
    8000244e:	cc9c                	sw	a5,24(s1)
    80002450:	b7cd                	j	80002432 <kill+0x52>

0000000080002452 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	84aa                	mv	s1,a0
    80002464:	892e                	mv	s2,a1
    80002466:	89b2                	mv	s3,a2
    80002468:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	588080e7          	jalr	1416(ra) # 800019f2 <myproc>
  if(user_dst){
    80002472:	c08d                	beqz	s1,80002494 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002474:	86d2                	mv	a3,s4
    80002476:	864e                	mv	a2,s3
    80002478:	85ca                	mv	a1,s2
    8000247a:	6928                	ld	a0,80(a0)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	238080e7          	jalr	568(ra) # 800016b4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6a02                	ld	s4,0(sp)
    80002490:	6145                	addi	sp,sp,48
    80002492:	8082                	ret
    memmove((char *)dst, src, len);
    80002494:	000a061b          	sext.w	a2,s4
    80002498:	85ce                	mv	a1,s3
    8000249a:	854a                	mv	a0,s2
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	8a4080e7          	jalr	-1884(ra) # 80000d40 <memmove>
    return 0;
    800024a4:	8526                	mv	a0,s1
    800024a6:	bff9                	j	80002484 <either_copyout+0x32>

00000000800024a8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	e052                	sd	s4,0(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	892a                	mv	s2,a0
    800024ba:	84ae                	mv	s1,a1
    800024bc:	89b2                	mv	s3,a2
    800024be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	532080e7          	jalr	1330(ra) # 800019f2 <myproc>
  if(user_src){
    800024c8:	c08d                	beqz	s1,800024ea <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024ca:	86d2                	mv	a3,s4
    800024cc:	864e                	mv	a2,s3
    800024ce:	85ca                	mv	a1,s2
    800024d0:	6928                	ld	a0,80(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	26e080e7          	jalr	622(ra) # 80001740 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ea:	000a061b          	sext.w	a2,s4
    800024ee:	85ce                	mv	a1,s3
    800024f0:	854a                	mv	a0,s2
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	84e080e7          	jalr	-1970(ra) # 80000d40 <memmove>
    return 0;
    800024fa:	8526                	mv	a0,s1
    800024fc:	bff9                	j	800024da <either_copyin+0x32>

00000000800024fe <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024fe:	715d                	addi	sp,sp,-80
    80002500:	e486                	sd	ra,72(sp)
    80002502:	e0a2                	sd	s0,64(sp)
    80002504:	fc26                	sd	s1,56(sp)
    80002506:	f84a                	sd	s2,48(sp)
    80002508:	f44e                	sd	s3,40(sp)
    8000250a:	f052                	sd	s4,32(sp)
    8000250c:	ec56                	sd	s5,24(sp)
    8000250e:	e85a                	sd	s6,16(sp)
    80002510:	e45e                	sd	s7,8(sp)
    80002512:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002514:	00006517          	auipc	a0,0x6
    80002518:	c0c50513          	addi	a0,a0,-1012 # 80008120 <digits+0xe0>
    8000251c:	ffffe097          	auipc	ra,0xffffe
    80002520:	06c080e7          	jalr	108(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002524:	00012497          	auipc	s1,0x12
    80002528:	30448493          	addi	s1,s1,772 # 80014828 <proc+0x158>
    8000252c:	00018917          	auipc	s2,0x18
    80002530:	cfc90913          	addi	s2,s2,-772 # 8001a228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002534:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002536:	00006997          	auipc	s3,0x6
    8000253a:	dba98993          	addi	s3,s3,-582 # 800082f0 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    8000253e:	00006a97          	auipc	s5,0x6
    80002542:	dbaa8a93          	addi	s5,s5,-582 # 800082f8 <digits+0x2b8>
    printf("\n");
    80002546:	00006a17          	auipc	s4,0x6
    8000254a:	bdaa0a13          	addi	s4,s4,-1062 # 80008120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254e:	00006b97          	auipc	s7,0x6
    80002552:	de2b8b93          	addi	s7,s7,-542 # 80008330 <states.1709>
    80002556:	a00d                	j	80002578 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002558:	ed86a583          	lw	a1,-296(a3)
    8000255c:	8556                	mv	a0,s5
    8000255e:	ffffe097          	auipc	ra,0xffffe
    80002562:	02a080e7          	jalr	42(ra) # 80000588 <printf>
    printf("\n");
    80002566:	8552                	mv	a0,s4
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	020080e7          	jalr	32(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002570:	16848493          	addi	s1,s1,360
    80002574:	03248163          	beq	s1,s2,80002596 <procdump+0x98>
    if(p->state == UNUSED)
    80002578:	86a6                	mv	a3,s1
    8000257a:	ec04a783          	lw	a5,-320(s1)
    8000257e:	dbed                	beqz	a5,80002570 <procdump+0x72>
      state = "???";
    80002580:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002582:	fcfb6be3          	bltu	s6,a5,80002558 <procdump+0x5a>
    80002586:	1782                	slli	a5,a5,0x20
    80002588:	9381                	srli	a5,a5,0x20
    8000258a:	078e                	slli	a5,a5,0x3
    8000258c:	97de                	add	a5,a5,s7
    8000258e:	6390                	ld	a2,0(a5)
    80002590:	f661                	bnez	a2,80002558 <procdump+0x5a>
      state = "???";
    80002592:	864e                	mv	a2,s3
    80002594:	b7d1                	j	80002558 <procdump+0x5a>
  }
}
    80002596:	60a6                	ld	ra,72(sp)
    80002598:	6406                	ld	s0,64(sp)
    8000259a:	74e2                	ld	s1,56(sp)
    8000259c:	7942                	ld	s2,48(sp)
    8000259e:	79a2                	ld	s3,40(sp)
    800025a0:	7a02                	ld	s4,32(sp)
    800025a2:	6ae2                	ld	s5,24(sp)
    800025a4:	6b42                	ld	s6,16(sp)
    800025a6:	6ba2                	ld	s7,8(sp)
    800025a8:	6161                	addi	sp,sp,80
    800025aa:	8082                	ret

00000000800025ac <swtch>:
    800025ac:	00153023          	sd	ra,0(a0)
    800025b0:	00253423          	sd	sp,8(a0)
    800025b4:	e900                	sd	s0,16(a0)
    800025b6:	ed04                	sd	s1,24(a0)
    800025b8:	03253023          	sd	s2,32(a0)
    800025bc:	03353423          	sd	s3,40(a0)
    800025c0:	03453823          	sd	s4,48(a0)
    800025c4:	03553c23          	sd	s5,56(a0)
    800025c8:	05653023          	sd	s6,64(a0)
    800025cc:	05753423          	sd	s7,72(a0)
    800025d0:	05853823          	sd	s8,80(a0)
    800025d4:	05953c23          	sd	s9,88(a0)
    800025d8:	07a53023          	sd	s10,96(a0)
    800025dc:	07b53423          	sd	s11,104(a0)
    800025e0:	0005b083          	ld	ra,0(a1)
    800025e4:	0085b103          	ld	sp,8(a1)
    800025e8:	6980                	ld	s0,16(a1)
    800025ea:	6d84                	ld	s1,24(a1)
    800025ec:	0205b903          	ld	s2,32(a1)
    800025f0:	0285b983          	ld	s3,40(a1)
    800025f4:	0305ba03          	ld	s4,48(a1)
    800025f8:	0385ba83          	ld	s5,56(a1)
    800025fc:	0405bb03          	ld	s6,64(a1)
    80002600:	0485bb83          	ld	s7,72(a1)
    80002604:	0505bc03          	ld	s8,80(a1)
    80002608:	0585bc83          	ld	s9,88(a1)
    8000260c:	0605bd03          	ld	s10,96(a1)
    80002610:	0685bd83          	ld	s11,104(a1)
    80002614:	8082                	ret

0000000080002616 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002616:	1141                	addi	sp,sp,-16
    80002618:	e406                	sd	ra,8(sp)
    8000261a:	e022                	sd	s0,0(sp)
    8000261c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000261e:	00006597          	auipc	a1,0x6
    80002622:	d4258593          	addi	a1,a1,-702 # 80008360 <states.1709+0x30>
    80002626:	00018517          	auipc	a0,0x18
    8000262a:	aaa50513          	addi	a0,a0,-1366 # 8001a0d0 <tickslock>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	526080e7          	jalr	1318(ra) # 80000b54 <initlock>
}
    80002636:	60a2                	ld	ra,8(sp)
    80002638:	6402                	ld	s0,0(sp)
    8000263a:	0141                	addi	sp,sp,16
    8000263c:	8082                	ret

000000008000263e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000263e:	1141                	addi	sp,sp,-16
    80002640:	e422                	sd	s0,8(sp)
    80002642:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002644:	00003797          	auipc	a5,0x3
    80002648:	48c78793          	addi	a5,a5,1164 # 80005ad0 <kernelvec>
    8000264c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002650:	6422                	ld	s0,8(sp)
    80002652:	0141                	addi	sp,sp,16
    80002654:	8082                	ret

0000000080002656 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002656:	1141                	addi	sp,sp,-16
    80002658:	e406                	sd	ra,8(sp)
    8000265a:	e022                	sd	s0,0(sp)
    8000265c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000265e:	fffff097          	auipc	ra,0xfffff
    80002662:	394080e7          	jalr	916(ra) # 800019f2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002666:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000266a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002670:	00005617          	auipc	a2,0x5
    80002674:	99060613          	addi	a2,a2,-1648 # 80007000 <_trampoline>
    80002678:	00005697          	auipc	a3,0x5
    8000267c:	98868693          	addi	a3,a3,-1656 # 80007000 <_trampoline>
    80002680:	8e91                	sub	a3,a3,a2
    80002682:	010007b7          	lui	a5,0x1000
    80002686:	17fd                	addi	a5,a5,-1
    80002688:	07ba                	slli	a5,a5,0xe
    8000268a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002690:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002692:	180026f3          	csrr	a3,satp
    80002696:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002698:	6d38                	ld	a4,88(a0)
    8000269a:	6134                	ld	a3,64(a0)
    8000269c:	6591                	lui	a1,0x4
    8000269e:	96ae                	add	a3,a3,a1
    800026a0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a2:	6d38                	ld	a4,88(a0)
    800026a4:	00000697          	auipc	a3,0x0
    800026a8:	13868693          	addi	a3,a3,312 # 800027dc <usertrap>
    800026ac:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026ae:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b0:	8692                	mv	a3,tp
    800026b2:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b4:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026b8:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026bc:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c6:	6f18                	ld	a4,24(a4)
    800026c8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026cc:	692c                	ld	a1,80(a0)
    800026ce:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026d0:	00005717          	auipc	a4,0x5
    800026d4:	9c070713          	addi	a4,a4,-1600 # 80007090 <userret>
    800026d8:	8f11                	sub	a4,a4,a2
    800026da:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026dc:	577d                	li	a4,-1
    800026de:	177e                	slli	a4,a4,0x3f
    800026e0:	8dd9                	or	a1,a1,a4
    800026e2:	00800537          	lui	a0,0x800
    800026e6:	157d                	addi	a0,a0,-1
    800026e8:	053e                	slli	a0,a0,0xf
    800026ea:	9782                	jalr	a5
}
    800026ec:	60a2                	ld	ra,8(sp)
    800026ee:	6402                	ld	s0,0(sp)
    800026f0:	0141                	addi	sp,sp,16
    800026f2:	8082                	ret

00000000800026f4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f4:	1101                	addi	sp,sp,-32
    800026f6:	ec06                	sd	ra,24(sp)
    800026f8:	e822                	sd	s0,16(sp)
    800026fa:	e426                	sd	s1,8(sp)
    800026fc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026fe:	00018497          	auipc	s1,0x18
    80002702:	9d248493          	addi	s1,s1,-1582 # 8001a0d0 <tickslock>
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	4dc080e7          	jalr	1244(ra) # 80000be4 <acquire>
  ticks++;
    80002710:	0000a517          	auipc	a0,0xa
    80002714:	92050513          	addi	a0,a0,-1760 # 8000c030 <ticks>
    80002718:	411c                	lw	a5,0(a0)
    8000271a:	2785                	addiw	a5,a5,1
    8000271c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000271e:	00000097          	auipc	ra,0x0
    80002722:	b1c080e7          	jalr	-1252(ra) # 8000223a <wakeup>
  release(&tickslock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	570080e7          	jalr	1392(ra) # 80000c98 <release>
}
    80002730:	60e2                	ld	ra,24(sp)
    80002732:	6442                	ld	s0,16(sp)
    80002734:	64a2                	ld	s1,8(sp)
    80002736:	6105                	addi	sp,sp,32
    80002738:	8082                	ret

000000008000273a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273a:	1101                	addi	sp,sp,-32
    8000273c:	ec06                	sd	ra,24(sp)
    8000273e:	e822                	sd	s0,16(sp)
    80002740:	e426                	sd	s1,8(sp)
    80002742:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002744:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002748:	00074d63          	bltz	a4,80002762 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274c:	57fd                	li	a5,-1
    8000274e:	17fe                	slli	a5,a5,0x3f
    80002750:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002752:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002754:	06f70363          	beq	a4,a5,800027ba <devintr+0x80>
  }
}
    80002758:	60e2                	ld	ra,24(sp)
    8000275a:	6442                	ld	s0,16(sp)
    8000275c:	64a2                	ld	s1,8(sp)
    8000275e:	6105                	addi	sp,sp,32
    80002760:	8082                	ret
     (scause & 0xff) == 9){
    80002762:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002766:	46a5                	li	a3,9
    80002768:	fed792e3          	bne	a5,a3,8000274c <devintr+0x12>
    int irq = plic_claim();
    8000276c:	00003097          	auipc	ra,0x3
    80002770:	46c080e7          	jalr	1132(ra) # 80005bd8 <plic_claim>
    80002774:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002776:	47a9                	li	a5,10
    80002778:	02f50763          	beq	a0,a5,800027a6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277c:	4785                	li	a5,1
    8000277e:	02f50963          	beq	a0,a5,800027b0 <devintr+0x76>
    return 1;
    80002782:	4505                	li	a0,1
    } else if(irq){
    80002784:	d8f1                	beqz	s1,80002758 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002786:	85a6                	mv	a1,s1
    80002788:	00006517          	auipc	a0,0x6
    8000278c:	be050513          	addi	a0,a0,-1056 # 80008368 <states.1709+0x38>
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	df8080e7          	jalr	-520(ra) # 80000588 <printf>
      plic_complete(irq);
    80002798:	8526                	mv	a0,s1
    8000279a:	00003097          	auipc	ra,0x3
    8000279e:	462080e7          	jalr	1122(ra) # 80005bfc <plic_complete>
    return 1;
    800027a2:	4505                	li	a0,1
    800027a4:	bf55                	j	80002758 <devintr+0x1e>
      uartintr();
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	202080e7          	jalr	514(ra) # 800009a8 <uartintr>
    800027ae:	b7ed                	j	80002798 <devintr+0x5e>
      virtio_disk_intr();
    800027b0:	00004097          	auipc	ra,0x4
    800027b4:	93a080e7          	jalr	-1734(ra) # 800060ea <virtio_disk_intr>
    800027b8:	b7c5                	j	80002798 <devintr+0x5e>
    if(cpuid() == 0){
    800027ba:	fffff097          	auipc	ra,0xfffff
    800027be:	20c080e7          	jalr	524(ra) # 800019c6 <cpuid>
    800027c2:	c901                	beqz	a0,800027d2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027c8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027ca:	14479073          	csrw	sip,a5
    return 2;
    800027ce:	4509                	li	a0,2
    800027d0:	b761                	j	80002758 <devintr+0x1e>
      clockintr();
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	f22080e7          	jalr	-222(ra) # 800026f4 <clockintr>
    800027da:	b7ed                	j	800027c4 <devintr+0x8a>

00000000800027dc <usertrap>:
{
    800027dc:	1101                	addi	sp,sp,-32
    800027de:	ec06                	sd	ra,24(sp)
    800027e0:	e822                	sd	s0,16(sp)
    800027e2:	e426                	sd	s1,8(sp)
    800027e4:	e04a                	sd	s2,0(sp)
    800027e6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ec:	1007f793          	andi	a5,a5,256
    800027f0:	e3ad                	bnez	a5,80002852 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f2:	00003797          	auipc	a5,0x3
    800027f6:	2de78793          	addi	a5,a5,734 # 80005ad0 <kernelvec>
    800027fa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027fe:	fffff097          	auipc	ra,0xfffff
    80002802:	1f4080e7          	jalr	500(ra) # 800019f2 <myproc>
    80002806:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002808:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280a:	14102773          	csrr	a4,sepc
    8000280e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002810:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002814:	47a1                	li	a5,8
    80002816:	04f71c63          	bne	a4,a5,8000286e <usertrap+0x92>
    if(p->killed)
    8000281a:	551c                	lw	a5,40(a0)
    8000281c:	e3b9                	bnez	a5,80002862 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000281e:	6cb8                	ld	a4,88(s1)
    80002820:	6f1c                	ld	a5,24(a4)
    80002822:	0791                	addi	a5,a5,4
    80002824:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002826:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000282a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282e:	10079073          	csrw	sstatus,a5
    syscall();
    80002832:	00000097          	auipc	ra,0x0
    80002836:	2e0080e7          	jalr	736(ra) # 80002b12 <syscall>
  if(p->killed)
    8000283a:	549c                	lw	a5,40(s1)
    8000283c:	ebc1                	bnez	a5,800028cc <usertrap+0xf0>
  usertrapret();
    8000283e:	00000097          	auipc	ra,0x0
    80002842:	e18080e7          	jalr	-488(ra) # 80002656 <usertrapret>
}
    80002846:	60e2                	ld	ra,24(sp)
    80002848:	6442                	ld	s0,16(sp)
    8000284a:	64a2                	ld	s1,8(sp)
    8000284c:	6902                	ld	s2,0(sp)
    8000284e:	6105                	addi	sp,sp,32
    80002850:	8082                	ret
    panic("usertrap: not from user mode");
    80002852:	00006517          	auipc	a0,0x6
    80002856:	b3650513          	addi	a0,a0,-1226 # 80008388 <states.1709+0x58>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>
      exit(-1);
    80002862:	557d                	li	a0,-1
    80002864:	00000097          	auipc	ra,0x0
    80002868:	aa6080e7          	jalr	-1370(ra) # 8000230a <exit>
    8000286c:	bf4d                	j	8000281e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000286e:	00000097          	auipc	ra,0x0
    80002872:	ecc080e7          	jalr	-308(ra) # 8000273a <devintr>
    80002876:	892a                	mv	s2,a0
    80002878:	c501                	beqz	a0,80002880 <usertrap+0xa4>
  if(p->killed)
    8000287a:	549c                	lw	a5,40(s1)
    8000287c:	c3a1                	beqz	a5,800028bc <usertrap+0xe0>
    8000287e:	a815                	j	800028b2 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002880:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002884:	5890                	lw	a2,48(s1)
    80002886:	00006517          	auipc	a0,0x6
    8000288a:	b2250513          	addi	a0,a0,-1246 # 800083a8 <states.1709+0x78>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	cfa080e7          	jalr	-774(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002896:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000289a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	b3a50513          	addi	a0,a0,-1222 # 800083d8 <states.1709+0xa8>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
    p->killed = 1;
    800028ae:	4785                	li	a5,1
    800028b0:	d49c                	sw	a5,40(s1)
    exit(-1);
    800028b2:	557d                	li	a0,-1
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	a56080e7          	jalr	-1450(ra) # 8000230a <exit>
  if(which_dev == 2)
    800028bc:	4789                	li	a5,2
    800028be:	f8f910e3          	bne	s2,a5,8000283e <usertrap+0x62>
    yield();
    800028c2:	fffff097          	auipc	ra,0xfffff
    800028c6:	7b0080e7          	jalr	1968(ra) # 80002072 <yield>
    800028ca:	bf95                	j	8000283e <usertrap+0x62>
  int which_dev = 0;
    800028cc:	4901                	li	s2,0
    800028ce:	b7d5                	j	800028b2 <usertrap+0xd6>

00000000800028d0 <kerneltrap>:
{
    800028d0:	7179                	addi	sp,sp,-48
    800028d2:	f406                	sd	ra,40(sp)
    800028d4:	f022                	sd	s0,32(sp)
    800028d6:	ec26                	sd	s1,24(sp)
    800028d8:	e84a                	sd	s2,16(sp)
    800028da:	e44e                	sd	s3,8(sp)
    800028dc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028de:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ea:	1004f793          	andi	a5,s1,256
    800028ee:	cb85                	beqz	a5,8000291e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f6:	ef85                	bnez	a5,8000292e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	e42080e7          	jalr	-446(ra) # 8000273a <devintr>
    80002900:	cd1d                	beqz	a0,8000293e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002902:	4789                	li	a5,2
    80002904:	06f50a63          	beq	a0,a5,80002978 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002908:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290c:	10049073          	csrw	sstatus,s1
}
    80002910:	70a2                	ld	ra,40(sp)
    80002912:	7402                	ld	s0,32(sp)
    80002914:	64e2                	ld	s1,24(sp)
    80002916:	6942                	ld	s2,16(sp)
    80002918:	69a2                	ld	s3,8(sp)
    8000291a:	6145                	addi	sp,sp,48
    8000291c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000291e:	00006517          	auipc	a0,0x6
    80002922:	ada50513          	addi	a0,a0,-1318 # 800083f8 <states.1709+0xc8>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	c18080e7          	jalr	-1000(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	af250513          	addi	a0,a0,-1294 # 80008420 <states.1709+0xf0>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c08080e7          	jalr	-1016(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    8000293e:	85ce                	mv	a1,s3
    80002940:	00006517          	auipc	a0,0x6
    80002944:	b0050513          	addi	a0,a0,-1280 # 80008440 <states.1709+0x110>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002950:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002954:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	af850513          	addi	a0,a0,-1288 # 80008450 <states.1709+0x120>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c28080e7          	jalr	-984(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	b0050513          	addi	a0,a0,-1280 # 80008468 <states.1709+0x138>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bce080e7          	jalr	-1074(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	07a080e7          	jalr	122(ra) # 800019f2 <myproc>
    80002980:	d541                	beqz	a0,80002908 <kerneltrap+0x38>
    80002982:	fffff097          	auipc	ra,0xfffff
    80002986:	070080e7          	jalr	112(ra) # 800019f2 <myproc>
    8000298a:	4d18                	lw	a4,24(a0)
    8000298c:	4791                	li	a5,4
    8000298e:	f6f71de3          	bne	a4,a5,80002908 <kerneltrap+0x38>
    yield();
    80002992:	fffff097          	auipc	ra,0xfffff
    80002996:	6e0080e7          	jalr	1760(ra) # 80002072 <yield>
    8000299a:	b7bd                	j	80002908 <kerneltrap+0x38>

000000008000299c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000299c:	1101                	addi	sp,sp,-32
    8000299e:	ec06                	sd	ra,24(sp)
    800029a0:	e822                	sd	s0,16(sp)
    800029a2:	e426                	sd	s1,8(sp)
    800029a4:	1000                	addi	s0,sp,32
    800029a6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	04a080e7          	jalr	74(ra) # 800019f2 <myproc>
  switch (n) {
    800029b0:	4795                	li	a5,5
    800029b2:	0497e163          	bltu	a5,s1,800029f4 <argraw+0x58>
    800029b6:	048a                	slli	s1,s1,0x2
    800029b8:	00006717          	auipc	a4,0x6
    800029bc:	ae870713          	addi	a4,a4,-1304 # 800084a0 <states.1709+0x170>
    800029c0:	94ba                	add	s1,s1,a4
    800029c2:	409c                	lw	a5,0(s1)
    800029c4:	97ba                	add	a5,a5,a4
    800029c6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029c8:	6d3c                	ld	a5,88(a0)
    800029ca:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029cc:	60e2                	ld	ra,24(sp)
    800029ce:	6442                	ld	s0,16(sp)
    800029d0:	64a2                	ld	s1,8(sp)
    800029d2:	6105                	addi	sp,sp,32
    800029d4:	8082                	ret
    return p->trapframe->a1;
    800029d6:	6d3c                	ld	a5,88(a0)
    800029d8:	7fa8                	ld	a0,120(a5)
    800029da:	bfcd                	j	800029cc <argraw+0x30>
    return p->trapframe->a2;
    800029dc:	6d3c                	ld	a5,88(a0)
    800029de:	63c8                	ld	a0,128(a5)
    800029e0:	b7f5                	j	800029cc <argraw+0x30>
    return p->trapframe->a3;
    800029e2:	6d3c                	ld	a5,88(a0)
    800029e4:	67c8                	ld	a0,136(a5)
    800029e6:	b7dd                	j	800029cc <argraw+0x30>
    return p->trapframe->a4;
    800029e8:	6d3c                	ld	a5,88(a0)
    800029ea:	6bc8                	ld	a0,144(a5)
    800029ec:	b7c5                	j	800029cc <argraw+0x30>
    return p->trapframe->a5;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	6fc8                	ld	a0,152(a5)
    800029f2:	bfe9                	j	800029cc <argraw+0x30>
  panic("argraw");
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	a8450513          	addi	a0,a0,-1404 # 80008478 <states.1709+0x148>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b42080e7          	jalr	-1214(ra) # 8000053e <panic>

0000000080002a04 <fetchaddr>:
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	e04a                	sd	s2,0(sp)
    80002a0e:	1000                	addi	s0,sp,32
    80002a10:	84aa                	mv	s1,a0
    80002a12:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a14:	fffff097          	auipc	ra,0xfffff
    80002a18:	fde080e7          	jalr	-34(ra) # 800019f2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a1c:	653c                	ld	a5,72(a0)
    80002a1e:	02f4f863          	bgeu	s1,a5,80002a4e <fetchaddr+0x4a>
    80002a22:	00848713          	addi	a4,s1,8
    80002a26:	02e7e663          	bltu	a5,a4,80002a52 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a2a:	46a1                	li	a3,8
    80002a2c:	8626                	mv	a2,s1
    80002a2e:	85ca                	mv	a1,s2
    80002a30:	6928                	ld	a0,80(a0)
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	d0e080e7          	jalr	-754(ra) # 80001740 <copyin>
    80002a3a:	00a03533          	snez	a0,a0
    80002a3e:	40a00533          	neg	a0,a0
}
    80002a42:	60e2                	ld	ra,24(sp)
    80002a44:	6442                	ld	s0,16(sp)
    80002a46:	64a2                	ld	s1,8(sp)
    80002a48:	6902                	ld	s2,0(sp)
    80002a4a:	6105                	addi	sp,sp,32
    80002a4c:	8082                	ret
    return -1;
    80002a4e:	557d                	li	a0,-1
    80002a50:	bfcd                	j	80002a42 <fetchaddr+0x3e>
    80002a52:	557d                	li	a0,-1
    80002a54:	b7fd                	j	80002a42 <fetchaddr+0x3e>

0000000080002a56 <fetchstr>:
{
    80002a56:	7179                	addi	sp,sp,-48
    80002a58:	f406                	sd	ra,40(sp)
    80002a5a:	f022                	sd	s0,32(sp)
    80002a5c:	ec26                	sd	s1,24(sp)
    80002a5e:	e84a                	sd	s2,16(sp)
    80002a60:	e44e                	sd	s3,8(sp)
    80002a62:	1800                	addi	s0,sp,48
    80002a64:	892a                	mv	s2,a0
    80002a66:	84ae                	mv	s1,a1
    80002a68:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	f88080e7          	jalr	-120(ra) # 800019f2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a72:	86ce                	mv	a3,s3
    80002a74:	864a                	mv	a2,s2
    80002a76:	85a6                	mv	a1,s1
    80002a78:	6928                	ld	a0,80(a0)
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	d52080e7          	jalr	-686(ra) # 800017cc <copyinstr>
  if(err < 0)
    80002a82:	00054763          	bltz	a0,80002a90 <fetchstr+0x3a>
  return strlen(buf);
    80002a86:	8526                	mv	a0,s1
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	3dc080e7          	jalr	988(ra) # 80000e64 <strlen>
}
    80002a90:	70a2                	ld	ra,40(sp)
    80002a92:	7402                	ld	s0,32(sp)
    80002a94:	64e2                	ld	s1,24(sp)
    80002a96:	6942                	ld	s2,16(sp)
    80002a98:	69a2                	ld	s3,8(sp)
    80002a9a:	6145                	addi	sp,sp,48
    80002a9c:	8082                	ret

0000000080002a9e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a9e:	1101                	addi	sp,sp,-32
    80002aa0:	ec06                	sd	ra,24(sp)
    80002aa2:	e822                	sd	s0,16(sp)
    80002aa4:	e426                	sd	s1,8(sp)
    80002aa6:	1000                	addi	s0,sp,32
    80002aa8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	ef2080e7          	jalr	-270(ra) # 8000299c <argraw>
    80002ab2:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab4:	4501                	li	a0,0
    80002ab6:	60e2                	ld	ra,24(sp)
    80002ab8:	6442                	ld	s0,16(sp)
    80002aba:	64a2                	ld	s1,8(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret

0000000080002ac0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ac0:	1101                	addi	sp,sp,-32
    80002ac2:	ec06                	sd	ra,24(sp)
    80002ac4:	e822                	sd	s0,16(sp)
    80002ac6:	e426                	sd	s1,8(sp)
    80002ac8:	1000                	addi	s0,sp,32
    80002aca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	ed0080e7          	jalr	-304(ra) # 8000299c <argraw>
    80002ad4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad6:	4501                	li	a0,0
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret

0000000080002ae2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	e04a                	sd	s2,0(sp)
    80002aec:	1000                	addi	s0,sp,32
    80002aee:	84ae                	mv	s1,a1
    80002af0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	eaa080e7          	jalr	-342(ra) # 8000299c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002afa:	864a                	mv	a2,s2
    80002afc:	85a6                	mv	a1,s1
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	f58080e7          	jalr	-168(ra) # 80002a56 <fetchstr>
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6902                	ld	s2,0(sp)
    80002b0e:	6105                	addi	sp,sp,32
    80002b10:	8082                	ret

0000000080002b12 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002b12:	1101                	addi	sp,sp,-32
    80002b14:	ec06                	sd	ra,24(sp)
    80002b16:	e822                	sd	s0,16(sp)
    80002b18:	e426                	sd	s1,8(sp)
    80002b1a:	e04a                	sd	s2,0(sp)
    80002b1c:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	ed4080e7          	jalr	-300(ra) # 800019f2 <myproc>
    80002b26:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b28:	05853903          	ld	s2,88(a0)
    80002b2c:	0a893783          	ld	a5,168(s2)
    80002b30:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b34:	37fd                	addiw	a5,a5,-1
    80002b36:	4751                	li	a4,20
    80002b38:	00f76f63          	bltu	a4,a5,80002b56 <syscall+0x44>
    80002b3c:	00369713          	slli	a4,a3,0x3
    80002b40:	00006797          	auipc	a5,0x6
    80002b44:	97878793          	addi	a5,a5,-1672 # 800084b8 <syscalls>
    80002b48:	97ba                	add	a5,a5,a4
    80002b4a:	639c                	ld	a5,0(a5)
    80002b4c:	c789                	beqz	a5,80002b56 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b4e:	9782                	jalr	a5
    80002b50:	06a93823          	sd	a0,112(s2)
    80002b54:	a839                	j	80002b72 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b56:	15848613          	addi	a2,s1,344
    80002b5a:	588c                	lw	a1,48(s1)
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	92450513          	addi	a0,a0,-1756 # 80008480 <states.1709+0x150>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a24080e7          	jalr	-1500(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b6c:	6cbc                	ld	a5,88(s1)
    80002b6e:	577d                	li	a4,-1
    80002b70:	fbb8                	sd	a4,112(a5)
  }
}
    80002b72:	60e2                	ld	ra,24(sp)
    80002b74:	6442                	ld	s0,16(sp)
    80002b76:	64a2                	ld	s1,8(sp)
    80002b78:	6902                	ld	s2,0(sp)
    80002b7a:	6105                	addi	sp,sp,32
    80002b7c:	8082                	ret

0000000080002b7e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b86:	fec40593          	addi	a1,s0,-20
    80002b8a:	4501                	li	a0,0
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	f12080e7          	jalr	-238(ra) # 80002a9e <argint>
    return -1;
    80002b94:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b96:	00054963          	bltz	a0,80002ba8 <sys_exit+0x2a>
  exit(n);
    80002b9a:	fec42503          	lw	a0,-20(s0)
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	76c080e7          	jalr	1900(ra) # 8000230a <exit>
  return 0;  // not reached
    80002ba6:	4781                	li	a5,0
}
    80002ba8:	853e                	mv	a0,a5
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret

0000000080002bb2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bb2:	1141                	addi	sp,sp,-16
    80002bb4:	e406                	sd	ra,8(sp)
    80002bb6:	e022                	sd	s0,0(sp)
    80002bb8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	e38080e7          	jalr	-456(ra) # 800019f2 <myproc>
}
    80002bc2:	5908                	lw	a0,48(a0)
    80002bc4:	60a2                	ld	ra,8(sp)
    80002bc6:	6402                	ld	s0,0(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret

0000000080002bcc <sys_fork>:

uint64
sys_fork(void)
{
    80002bcc:	1141                	addi	sp,sp,-16
    80002bce:	e406                	sd	ra,8(sp)
    80002bd0:	e022                	sd	s0,0(sp)
    80002bd2:	0800                	addi	s0,sp,16
  return fork();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	1ec080e7          	jalr	492(ra) # 80001dc0 <fork>
}
    80002bdc:	60a2                	ld	ra,8(sp)
    80002bde:	6402                	ld	s0,0(sp)
    80002be0:	0141                	addi	sp,sp,16
    80002be2:	8082                	ret

0000000080002be4 <sys_wait>:

uint64
sys_wait(void)
{
    80002be4:	1101                	addi	sp,sp,-32
    80002be6:	ec06                	sd	ra,24(sp)
    80002be8:	e822                	sd	s0,16(sp)
    80002bea:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bec:	fe840593          	addi	a1,s0,-24
    80002bf0:	4501                	li	a0,0
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	ece080e7          	jalr	-306(ra) # 80002ac0 <argaddr>
    80002bfa:	87aa                	mv	a5,a0
    return -1;
    80002bfc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bfe:	0007c863          	bltz	a5,80002c0e <sys_wait+0x2a>
  return wait(p);
    80002c02:	fe843503          	ld	a0,-24(s0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	50c080e7          	jalr	1292(ra) # 80002112 <wait>
}
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c20:	fdc40593          	addi	a1,s0,-36
    80002c24:	4501                	li	a0,0
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	e78080e7          	jalr	-392(ra) # 80002a9e <argint>
    80002c2e:	87aa                	mv	a5,a0
    return -1;
    80002c30:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c32:	0207c063          	bltz	a5,80002c52 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c36:	fffff097          	auipc	ra,0xfffff
    80002c3a:	dbc080e7          	jalr	-580(ra) # 800019f2 <myproc>
    80002c3e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c40:	fdc42503          	lw	a0,-36(s0)
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	108080e7          	jalr	264(ra) # 80001d4c <growproc>
    80002c4c:	00054863          	bltz	a0,80002c5c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c50:	8526                	mv	a0,s1
}
    80002c52:	70a2                	ld	ra,40(sp)
    80002c54:	7402                	ld	s0,32(sp)
    80002c56:	64e2                	ld	s1,24(sp)
    80002c58:	6145                	addi	sp,sp,48
    80002c5a:	8082                	ret
    return -1;
    80002c5c:	557d                	li	a0,-1
    80002c5e:	bfd5                	j	80002c52 <sys_sbrk+0x3c>

0000000080002c60 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c60:	7139                	addi	sp,sp,-64
    80002c62:	fc06                	sd	ra,56(sp)
    80002c64:	f822                	sd	s0,48(sp)
    80002c66:	f426                	sd	s1,40(sp)
    80002c68:	f04a                	sd	s2,32(sp)
    80002c6a:	ec4e                	sd	s3,24(sp)
    80002c6c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c6e:	fcc40593          	addi	a1,s0,-52
    80002c72:	4501                	li	a0,0
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	e2a080e7          	jalr	-470(ra) # 80002a9e <argint>
    return -1;
    80002c7c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c7e:	06054563          	bltz	a0,80002ce8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c82:	00017517          	auipc	a0,0x17
    80002c86:	44e50513          	addi	a0,a0,1102 # 8001a0d0 <tickslock>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	f5a080e7          	jalr	-166(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002c92:	00009917          	auipc	s2,0x9
    80002c96:	39e92903          	lw	s2,926(s2) # 8000c030 <ticks>
  while(ticks - ticks0 < n){
    80002c9a:	fcc42783          	lw	a5,-52(s0)
    80002c9e:	cf85                	beqz	a5,80002cd6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ca0:	00017997          	auipc	s3,0x17
    80002ca4:	43098993          	addi	s3,s3,1072 # 8001a0d0 <tickslock>
    80002ca8:	00009497          	auipc	s1,0x9
    80002cac:	38848493          	addi	s1,s1,904 # 8000c030 <ticks>
    if(myproc()->killed){
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	d42080e7          	jalr	-702(ra) # 800019f2 <myproc>
    80002cb8:	551c                	lw	a5,40(a0)
    80002cba:	ef9d                	bnez	a5,80002cf8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cbc:	85ce                	mv	a1,s3
    80002cbe:	8526                	mv	a0,s1
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	3ee080e7          	jalr	1006(ra) # 800020ae <sleep>
  while(ticks - ticks0 < n){
    80002cc8:	409c                	lw	a5,0(s1)
    80002cca:	412787bb          	subw	a5,a5,s2
    80002cce:	fcc42703          	lw	a4,-52(s0)
    80002cd2:	fce7efe3          	bltu	a5,a4,80002cb0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cd6:	00017517          	auipc	a0,0x17
    80002cda:	3fa50513          	addi	a0,a0,1018 # 8001a0d0 <tickslock>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	fba080e7          	jalr	-70(ra) # 80000c98 <release>
  return 0;
    80002ce6:	4781                	li	a5,0
}
    80002ce8:	853e                	mv	a0,a5
    80002cea:	70e2                	ld	ra,56(sp)
    80002cec:	7442                	ld	s0,48(sp)
    80002cee:	74a2                	ld	s1,40(sp)
    80002cf0:	7902                	ld	s2,32(sp)
    80002cf2:	69e2                	ld	s3,24(sp)
    80002cf4:	6121                	addi	sp,sp,64
    80002cf6:	8082                	ret
      release(&tickslock);
    80002cf8:	00017517          	auipc	a0,0x17
    80002cfc:	3d850513          	addi	a0,a0,984 # 8001a0d0 <tickslock>
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	f98080e7          	jalr	-104(ra) # 80000c98 <release>
      return -1;
    80002d08:	57fd                	li	a5,-1
    80002d0a:	bff9                	j	80002ce8 <sys_sleep+0x88>

0000000080002d0c <sys_kill>:

uint64
sys_kill(void)
{
    80002d0c:	1101                	addi	sp,sp,-32
    80002d0e:	ec06                	sd	ra,24(sp)
    80002d10:	e822                	sd	s0,16(sp)
    80002d12:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d14:	fec40593          	addi	a1,s0,-20
    80002d18:	4501                	li	a0,0
    80002d1a:	00000097          	auipc	ra,0x0
    80002d1e:	d84080e7          	jalr	-636(ra) # 80002a9e <argint>
    80002d22:	87aa                	mv	a5,a0
    return -1;
    80002d24:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d26:	0007c863          	bltz	a5,80002d36 <sys_kill+0x2a>
  return kill(pid);
    80002d2a:	fec42503          	lw	a0,-20(s0)
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	6b2080e7          	jalr	1714(ra) # 800023e0 <kill>
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d48:	00017517          	auipc	a0,0x17
    80002d4c:	38850513          	addi	a0,a0,904 # 8001a0d0 <tickslock>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	e94080e7          	jalr	-364(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002d58:	00009497          	auipc	s1,0x9
    80002d5c:	2d84a483          	lw	s1,728(s1) # 8000c030 <ticks>
  release(&tickslock);
    80002d60:	00017517          	auipc	a0,0x17
    80002d64:	37050513          	addi	a0,a0,880 # 8001a0d0 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	f30080e7          	jalr	-208(ra) # 80000c98 <release>
  return xticks;
}
    80002d70:	02049513          	slli	a0,s1,0x20
    80002d74:	9101                	srli	a0,a0,0x20
    80002d76:	60e2                	ld	ra,24(sp)
    80002d78:	6442                	ld	s0,16(sp)
    80002d7a:	64a2                	ld	s1,8(sp)
    80002d7c:	6105                	addi	sp,sp,32
    80002d7e:	8082                	ret

0000000080002d80 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d80:	7179                	addi	sp,sp,-48
    80002d82:	f406                	sd	ra,40(sp)
    80002d84:	f022                	sd	s0,32(sp)
    80002d86:	ec26                	sd	s1,24(sp)
    80002d88:	e84a                	sd	s2,16(sp)
    80002d8a:	e44e                	sd	s3,8(sp)
    80002d8c:	e052                	sd	s4,0(sp)
    80002d8e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d90:	00005597          	auipc	a1,0x5
    80002d94:	7d858593          	addi	a1,a1,2008 # 80008568 <syscalls+0xb0>
    80002d98:	00017517          	auipc	a0,0x17
    80002d9c:	35050513          	addi	a0,a0,848 # 8001a0e8 <bcache>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	db4080e7          	jalr	-588(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002da8:	0001f797          	auipc	a5,0x1f
    80002dac:	34078793          	addi	a5,a5,832 # 800220e8 <bcache+0x8000>
    80002db0:	0001f717          	auipc	a4,0x1f
    80002db4:	5a070713          	addi	a4,a4,1440 # 80022350 <bcache+0x8268>
    80002db8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dbc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dc0:	00017497          	auipc	s1,0x17
    80002dc4:	34048493          	addi	s1,s1,832 # 8001a100 <bcache+0x18>
    b->next = bcache.head.next;
    80002dc8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dca:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dcc:	00005a17          	auipc	s4,0x5
    80002dd0:	7a4a0a13          	addi	s4,s4,1956 # 80008570 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002dd4:	2b893783          	ld	a5,696(s2)
    80002dd8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dda:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dde:	85d2                	mv	a1,s4
    80002de0:	01048513          	addi	a0,s1,16
    80002de4:	00001097          	auipc	ra,0x1
    80002de8:	4bc080e7          	jalr	1212(ra) # 800042a0 <initsleeplock>
    bcache.head.next->prev = b;
    80002dec:	2b893783          	ld	a5,696(s2)
    80002df0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002df2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df6:	45848493          	addi	s1,s1,1112
    80002dfa:	fd349de3          	bne	s1,s3,80002dd4 <binit+0x54>
  }
}
    80002dfe:	70a2                	ld	ra,40(sp)
    80002e00:	7402                	ld	s0,32(sp)
    80002e02:	64e2                	ld	s1,24(sp)
    80002e04:	6942                	ld	s2,16(sp)
    80002e06:	69a2                	ld	s3,8(sp)
    80002e08:	6a02                	ld	s4,0(sp)
    80002e0a:	6145                	addi	sp,sp,48
    80002e0c:	8082                	ret

0000000080002e0e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	e84a                	sd	s2,16(sp)
    80002e18:	e44e                	sd	s3,8(sp)
    80002e1a:	1800                	addi	s0,sp,48
    80002e1c:	89aa                	mv	s3,a0
    80002e1e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e20:	00017517          	auipc	a0,0x17
    80002e24:	2c850513          	addi	a0,a0,712 # 8001a0e8 <bcache>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	dbc080e7          	jalr	-580(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e30:	0001f497          	auipc	s1,0x1f
    80002e34:	5704b483          	ld	s1,1392(s1) # 800223a0 <bcache+0x82b8>
    80002e38:	0001f797          	auipc	a5,0x1f
    80002e3c:	51878793          	addi	a5,a5,1304 # 80022350 <bcache+0x8268>
    80002e40:	02f48f63          	beq	s1,a5,80002e7e <bread+0x70>
    80002e44:	873e                	mv	a4,a5
    80002e46:	a021                	j	80002e4e <bread+0x40>
    80002e48:	68a4                	ld	s1,80(s1)
    80002e4a:	02e48a63          	beq	s1,a4,80002e7e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e4e:	449c                	lw	a5,8(s1)
    80002e50:	ff379ce3          	bne	a5,s3,80002e48 <bread+0x3a>
    80002e54:	44dc                	lw	a5,12(s1)
    80002e56:	ff2799e3          	bne	a5,s2,80002e48 <bread+0x3a>
      b->refcnt++;
    80002e5a:	40bc                	lw	a5,64(s1)
    80002e5c:	2785                	addiw	a5,a5,1
    80002e5e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e60:	00017517          	auipc	a0,0x17
    80002e64:	28850513          	addi	a0,a0,648 # 8001a0e8 <bcache>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	e30080e7          	jalr	-464(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002e70:	01048513          	addi	a0,s1,16
    80002e74:	00001097          	auipc	ra,0x1
    80002e78:	466080e7          	jalr	1126(ra) # 800042da <acquiresleep>
      return b;
    80002e7c:	a8b9                	j	80002eda <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e7e:	0001f497          	auipc	s1,0x1f
    80002e82:	51a4b483          	ld	s1,1306(s1) # 80022398 <bcache+0x82b0>
    80002e86:	0001f797          	auipc	a5,0x1f
    80002e8a:	4ca78793          	addi	a5,a5,1226 # 80022350 <bcache+0x8268>
    80002e8e:	00f48863          	beq	s1,a5,80002e9e <bread+0x90>
    80002e92:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e94:	40bc                	lw	a5,64(s1)
    80002e96:	cf81                	beqz	a5,80002eae <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e98:	64a4                	ld	s1,72(s1)
    80002e9a:	fee49de3          	bne	s1,a4,80002e94 <bread+0x86>
  panic("bget: no buffers");
    80002e9e:	00005517          	auipc	a0,0x5
    80002ea2:	6da50513          	addi	a0,a0,1754 # 80008578 <syscalls+0xc0>
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	698080e7          	jalr	1688(ra) # 8000053e <panic>
      b->dev = dev;
    80002eae:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002eb2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002eb6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002eba:	4785                	li	a5,1
    80002ebc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ebe:	00017517          	auipc	a0,0x17
    80002ec2:	22a50513          	addi	a0,a0,554 # 8001a0e8 <bcache>
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	dd2080e7          	jalr	-558(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ece:	01048513          	addi	a0,s1,16
    80002ed2:	00001097          	auipc	ra,0x1
    80002ed6:	408080e7          	jalr	1032(ra) # 800042da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eda:	409c                	lw	a5,0(s1)
    80002edc:	cb89                	beqz	a5,80002eee <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ede:	8526                	mv	a0,s1
    80002ee0:	70a2                	ld	ra,40(sp)
    80002ee2:	7402                	ld	s0,32(sp)
    80002ee4:	64e2                	ld	s1,24(sp)
    80002ee6:	6942                	ld	s2,16(sp)
    80002ee8:	69a2                	ld	s3,8(sp)
    80002eea:	6145                	addi	sp,sp,48
    80002eec:	8082                	ret
    virtio_disk_rw(b, 0);
    80002eee:	4581                	li	a1,0
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	00003097          	auipc	ra,0x3
    80002ef6:	f14080e7          	jalr	-236(ra) # 80005e06 <virtio_disk_rw>
    b->valid = 1;
    80002efa:	4785                	li	a5,1
    80002efc:	c09c                	sw	a5,0(s1)
  return b;
    80002efe:	b7c5                	j	80002ede <bread+0xd0>

0000000080002f00 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	e426                	sd	s1,8(sp)
    80002f08:	1000                	addi	s0,sp,32
    80002f0a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f0c:	0541                	addi	a0,a0,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	466080e7          	jalr	1126(ra) # 80004374 <holdingsleep>
    80002f16:	cd01                	beqz	a0,80002f2e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f18:	4585                	li	a1,1
    80002f1a:	8526                	mv	a0,s1
    80002f1c:	00003097          	auipc	ra,0x3
    80002f20:	eea080e7          	jalr	-278(ra) # 80005e06 <virtio_disk_rw>
}
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret
    panic("bwrite");
    80002f2e:	00005517          	auipc	a0,0x5
    80002f32:	66250513          	addi	a0,a0,1634 # 80008590 <syscalls+0xd8>
    80002f36:	ffffd097          	auipc	ra,0xffffd
    80002f3a:	608080e7          	jalr	1544(ra) # 8000053e <panic>

0000000080002f3e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	e04a                	sd	s2,0(sp)
    80002f48:	1000                	addi	s0,sp,32
    80002f4a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f4c:	01050913          	addi	s2,a0,16
    80002f50:	854a                	mv	a0,s2
    80002f52:	00001097          	auipc	ra,0x1
    80002f56:	422080e7          	jalr	1058(ra) # 80004374 <holdingsleep>
    80002f5a:	c92d                	beqz	a0,80002fcc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f5c:	854a                	mv	a0,s2
    80002f5e:	00001097          	auipc	ra,0x1
    80002f62:	3d2080e7          	jalr	978(ra) # 80004330 <releasesleep>

  acquire(&bcache.lock);
    80002f66:	00017517          	auipc	a0,0x17
    80002f6a:	18250513          	addi	a0,a0,386 # 8001a0e8 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	c76080e7          	jalr	-906(ra) # 80000be4 <acquire>
  b->refcnt--;
    80002f76:	40bc                	lw	a5,64(s1)
    80002f78:	37fd                	addiw	a5,a5,-1
    80002f7a:	0007871b          	sext.w	a4,a5
    80002f7e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f80:	eb05                	bnez	a4,80002fb0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f82:	68bc                	ld	a5,80(s1)
    80002f84:	64b8                	ld	a4,72(s1)
    80002f86:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f88:	64bc                	ld	a5,72(s1)
    80002f8a:	68b8                	ld	a4,80(s1)
    80002f8c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f8e:	0001f797          	auipc	a5,0x1f
    80002f92:	15a78793          	addi	a5,a5,346 # 800220e8 <bcache+0x8000>
    80002f96:	2b87b703          	ld	a4,696(a5)
    80002f9a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f9c:	0001f717          	auipc	a4,0x1f
    80002fa0:	3b470713          	addi	a4,a4,948 # 80022350 <bcache+0x8268>
    80002fa4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fa6:	2b87b703          	ld	a4,696(a5)
    80002faa:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fac:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fb0:	00017517          	auipc	a0,0x17
    80002fb4:	13850513          	addi	a0,a0,312 # 8001a0e8 <bcache>
    80002fb8:	ffffe097          	auipc	ra,0xffffe
    80002fbc:	ce0080e7          	jalr	-800(ra) # 80000c98 <release>
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6902                	ld	s2,0(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret
    panic("brelse");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	5cc50513          	addi	a0,a0,1484 # 80008598 <syscalls+0xe0>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	56a080e7          	jalr	1386(ra) # 8000053e <panic>

0000000080002fdc <bpin>:

void
bpin(struct buf *b) {
    80002fdc:	1101                	addi	sp,sp,-32
    80002fde:	ec06                	sd	ra,24(sp)
    80002fe0:	e822                	sd	s0,16(sp)
    80002fe2:	e426                	sd	s1,8(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fe8:	00017517          	auipc	a0,0x17
    80002fec:	10050513          	addi	a0,a0,256 # 8001a0e8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	bf4080e7          	jalr	-1036(ra) # 80000be4 <acquire>
  b->refcnt++;
    80002ff8:	40bc                	lw	a5,64(s1)
    80002ffa:	2785                	addiw	a5,a5,1
    80002ffc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002ffe:	00017517          	auipc	a0,0x17
    80003002:	0ea50513          	addi	a0,a0,234 # 8001a0e8 <bcache>
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	c92080e7          	jalr	-878(ra) # 80000c98 <release>
}
    8000300e:	60e2                	ld	ra,24(sp)
    80003010:	6442                	ld	s0,16(sp)
    80003012:	64a2                	ld	s1,8(sp)
    80003014:	6105                	addi	sp,sp,32
    80003016:	8082                	ret

0000000080003018 <bunpin>:

void
bunpin(struct buf *b) {
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003024:	00017517          	auipc	a0,0x17
    80003028:	0c450513          	addi	a0,a0,196 # 8001a0e8 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	bb8080e7          	jalr	-1096(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003034:	40bc                	lw	a5,64(s1)
    80003036:	37fd                	addiw	a5,a5,-1
    80003038:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303a:	00017517          	auipc	a0,0x17
    8000303e:	0ae50513          	addi	a0,a0,174 # 8001a0e8 <bcache>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	c56080e7          	jalr	-938(ra) # 80000c98 <release>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	e04a                	sd	s2,0(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003062:	00d5d59b          	srliw	a1,a1,0xd
    80003066:	0001f797          	auipc	a5,0x1f
    8000306a:	75e7a783          	lw	a5,1886(a5) # 800227c4 <sb+0x1c>
    8000306e:	9dbd                	addw	a1,a1,a5
    80003070:	00000097          	auipc	ra,0x0
    80003074:	d9e080e7          	jalr	-610(ra) # 80002e0e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003078:	0074f713          	andi	a4,s1,7
    8000307c:	4785                	li	a5,1
    8000307e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003082:	14ce                	slli	s1,s1,0x33
    80003084:	90d9                	srli	s1,s1,0x36
    80003086:	00950733          	add	a4,a0,s1
    8000308a:	05874703          	lbu	a4,88(a4)
    8000308e:	00e7f6b3          	and	a3,a5,a4
    80003092:	c69d                	beqz	a3,800030c0 <bfree+0x6c>
    80003094:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003096:	94aa                	add	s1,s1,a0
    80003098:	fff7c793          	not	a5,a5
    8000309c:	8ff9                	and	a5,a5,a4
    8000309e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	118080e7          	jalr	280(ra) # 800041ba <log_write>
  brelse(bp);
    800030aa:	854a                	mv	a0,s2
    800030ac:	00000097          	auipc	ra,0x0
    800030b0:	e92080e7          	jalr	-366(ra) # 80002f3e <brelse>
}
    800030b4:	60e2                	ld	ra,24(sp)
    800030b6:	6442                	ld	s0,16(sp)
    800030b8:	64a2                	ld	s1,8(sp)
    800030ba:	6902                	ld	s2,0(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret
    panic("freeing free block");
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	4e050513          	addi	a0,a0,1248 # 800085a0 <syscalls+0xe8>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	476080e7          	jalr	1142(ra) # 8000053e <panic>

00000000800030d0 <balloc>:
{
    800030d0:	711d                	addi	sp,sp,-96
    800030d2:	ec86                	sd	ra,88(sp)
    800030d4:	e8a2                	sd	s0,80(sp)
    800030d6:	e4a6                	sd	s1,72(sp)
    800030d8:	e0ca                	sd	s2,64(sp)
    800030da:	fc4e                	sd	s3,56(sp)
    800030dc:	f852                	sd	s4,48(sp)
    800030de:	f456                	sd	s5,40(sp)
    800030e0:	f05a                	sd	s6,32(sp)
    800030e2:	ec5e                	sd	s7,24(sp)
    800030e4:	e862                	sd	s8,16(sp)
    800030e6:	e466                	sd	s9,8(sp)
    800030e8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ea:	0001f797          	auipc	a5,0x1f
    800030ee:	6c27a783          	lw	a5,1730(a5) # 800227ac <sb+0x4>
    800030f2:	cbd1                	beqz	a5,80003186 <balloc+0xb6>
    800030f4:	8baa                	mv	s7,a0
    800030f6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030f8:	0001fb17          	auipc	s6,0x1f
    800030fc:	6b0b0b13          	addi	s6,s6,1712 # 800227a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003100:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003102:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003104:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003106:	6c89                	lui	s9,0x2
    80003108:	a831                	j	80003124 <balloc+0x54>
    brelse(bp);
    8000310a:	854a                	mv	a0,s2
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	e32080e7          	jalr	-462(ra) # 80002f3e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003114:	015c87bb          	addw	a5,s9,s5
    80003118:	00078a9b          	sext.w	s5,a5
    8000311c:	004b2703          	lw	a4,4(s6)
    80003120:	06eaf363          	bgeu	s5,a4,80003186 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003124:	41fad79b          	sraiw	a5,s5,0x1f
    80003128:	0137d79b          	srliw	a5,a5,0x13
    8000312c:	015787bb          	addw	a5,a5,s5
    80003130:	40d7d79b          	sraiw	a5,a5,0xd
    80003134:	01cb2583          	lw	a1,28(s6)
    80003138:	9dbd                	addw	a1,a1,a5
    8000313a:	855e                	mv	a0,s7
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	cd2080e7          	jalr	-814(ra) # 80002e0e <bread>
    80003144:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003146:	004b2503          	lw	a0,4(s6)
    8000314a:	000a849b          	sext.w	s1,s5
    8000314e:	8662                	mv	a2,s8
    80003150:	faa4fde3          	bgeu	s1,a0,8000310a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003154:	41f6579b          	sraiw	a5,a2,0x1f
    80003158:	01d7d69b          	srliw	a3,a5,0x1d
    8000315c:	00c6873b          	addw	a4,a3,a2
    80003160:	00777793          	andi	a5,a4,7
    80003164:	9f95                	subw	a5,a5,a3
    80003166:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000316a:	4037571b          	sraiw	a4,a4,0x3
    8000316e:	00e906b3          	add	a3,s2,a4
    80003172:	0586c683          	lbu	a3,88(a3)
    80003176:	00d7f5b3          	and	a1,a5,a3
    8000317a:	cd91                	beqz	a1,80003196 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000317c:	2605                	addiw	a2,a2,1
    8000317e:	2485                	addiw	s1,s1,1
    80003180:	fd4618e3          	bne	a2,s4,80003150 <balloc+0x80>
    80003184:	b759                	j	8000310a <balloc+0x3a>
  panic("balloc: out of blocks");
    80003186:	00005517          	auipc	a0,0x5
    8000318a:	43250513          	addi	a0,a0,1074 # 800085b8 <syscalls+0x100>
    8000318e:	ffffd097          	auipc	ra,0xffffd
    80003192:	3b0080e7          	jalr	944(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003196:	974a                	add	a4,a4,s2
    80003198:	8fd5                	or	a5,a5,a3
    8000319a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000319e:	854a                	mv	a0,s2
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	01a080e7          	jalr	26(ra) # 800041ba <log_write>
        brelse(bp);
    800031a8:	854a                	mv	a0,s2
    800031aa:	00000097          	auipc	ra,0x0
    800031ae:	d94080e7          	jalr	-620(ra) # 80002f3e <brelse>
  bp = bread(dev, bno);
    800031b2:	85a6                	mv	a1,s1
    800031b4:	855e                	mv	a0,s7
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	c58080e7          	jalr	-936(ra) # 80002e0e <bread>
    800031be:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031c0:	40000613          	li	a2,1024
    800031c4:	4581                	li	a1,0
    800031c6:	05850513          	addi	a0,a0,88
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	b16080e7          	jalr	-1258(ra) # 80000ce0 <memset>
  log_write(bp);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00001097          	auipc	ra,0x1
    800031d8:	fe6080e7          	jalr	-26(ra) # 800041ba <log_write>
  brelse(bp);
    800031dc:	854a                	mv	a0,s2
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	d60080e7          	jalr	-672(ra) # 80002f3e <brelse>
}
    800031e6:	8526                	mv	a0,s1
    800031e8:	60e6                	ld	ra,88(sp)
    800031ea:	6446                	ld	s0,80(sp)
    800031ec:	64a6                	ld	s1,72(sp)
    800031ee:	6906                	ld	s2,64(sp)
    800031f0:	79e2                	ld	s3,56(sp)
    800031f2:	7a42                	ld	s4,48(sp)
    800031f4:	7aa2                	ld	s5,40(sp)
    800031f6:	7b02                	ld	s6,32(sp)
    800031f8:	6be2                	ld	s7,24(sp)
    800031fa:	6c42                	ld	s8,16(sp)
    800031fc:	6ca2                	ld	s9,8(sp)
    800031fe:	6125                	addi	sp,sp,96
    80003200:	8082                	ret

0000000080003202 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003202:	7179                	addi	sp,sp,-48
    80003204:	f406                	sd	ra,40(sp)
    80003206:	f022                	sd	s0,32(sp)
    80003208:	ec26                	sd	s1,24(sp)
    8000320a:	e84a                	sd	s2,16(sp)
    8000320c:	e44e                	sd	s3,8(sp)
    8000320e:	e052                	sd	s4,0(sp)
    80003210:	1800                	addi	s0,sp,48
    80003212:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003214:	47ad                	li	a5,11
    80003216:	04b7fe63          	bgeu	a5,a1,80003272 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000321a:	ff45849b          	addiw	s1,a1,-12
    8000321e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003222:	0ff00793          	li	a5,255
    80003226:	0ae7e363          	bltu	a5,a4,800032cc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000322a:	08052583          	lw	a1,128(a0)
    8000322e:	c5ad                	beqz	a1,80003298 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003230:	00092503          	lw	a0,0(s2)
    80003234:	00000097          	auipc	ra,0x0
    80003238:	bda080e7          	jalr	-1062(ra) # 80002e0e <bread>
    8000323c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000323e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003242:	02049593          	slli	a1,s1,0x20
    80003246:	9181                	srli	a1,a1,0x20
    80003248:	058a                	slli	a1,a1,0x2
    8000324a:	00b784b3          	add	s1,a5,a1
    8000324e:	0004a983          	lw	s3,0(s1)
    80003252:	04098d63          	beqz	s3,800032ac <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003256:	8552                	mv	a0,s4
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	ce6080e7          	jalr	-794(ra) # 80002f3e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003260:	854e                	mv	a0,s3
    80003262:	70a2                	ld	ra,40(sp)
    80003264:	7402                	ld	s0,32(sp)
    80003266:	64e2                	ld	s1,24(sp)
    80003268:	6942                	ld	s2,16(sp)
    8000326a:	69a2                	ld	s3,8(sp)
    8000326c:	6a02                	ld	s4,0(sp)
    8000326e:	6145                	addi	sp,sp,48
    80003270:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003272:	02059493          	slli	s1,a1,0x20
    80003276:	9081                	srli	s1,s1,0x20
    80003278:	048a                	slli	s1,s1,0x2
    8000327a:	94aa                	add	s1,s1,a0
    8000327c:	0504a983          	lw	s3,80(s1)
    80003280:	fe0990e3          	bnez	s3,80003260 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003284:	4108                	lw	a0,0(a0)
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	e4a080e7          	jalr	-438(ra) # 800030d0 <balloc>
    8000328e:	0005099b          	sext.w	s3,a0
    80003292:	0534a823          	sw	s3,80(s1)
    80003296:	b7e9                	j	80003260 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003298:	4108                	lw	a0,0(a0)
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	e36080e7          	jalr	-458(ra) # 800030d0 <balloc>
    800032a2:	0005059b          	sext.w	a1,a0
    800032a6:	08b92023          	sw	a1,128(s2)
    800032aa:	b759                	j	80003230 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032ac:	00092503          	lw	a0,0(s2)
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	e20080e7          	jalr	-480(ra) # 800030d0 <balloc>
    800032b8:	0005099b          	sext.w	s3,a0
    800032bc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032c0:	8552                	mv	a0,s4
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	ef8080e7          	jalr	-264(ra) # 800041ba <log_write>
    800032ca:	b771                	j	80003256 <bmap+0x54>
  panic("bmap: out of range");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	30450513          	addi	a0,a0,772 # 800085d0 <syscalls+0x118>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>

00000000800032dc <iget>:
{
    800032dc:	7179                	addi	sp,sp,-48
    800032de:	f406                	sd	ra,40(sp)
    800032e0:	f022                	sd	s0,32(sp)
    800032e2:	ec26                	sd	s1,24(sp)
    800032e4:	e84a                	sd	s2,16(sp)
    800032e6:	e44e                	sd	s3,8(sp)
    800032e8:	e052                	sd	s4,0(sp)
    800032ea:	1800                	addi	s0,sp,48
    800032ec:	89aa                	mv	s3,a0
    800032ee:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032f0:	0001f517          	auipc	a0,0x1f
    800032f4:	4d850513          	addi	a0,a0,1240 # 800227c8 <itable>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	8ec080e7          	jalr	-1812(ra) # 80000be4 <acquire>
  empty = 0;
    80003300:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003302:	0001f497          	auipc	s1,0x1f
    80003306:	4de48493          	addi	s1,s1,1246 # 800227e0 <itable+0x18>
    8000330a:	00021697          	auipc	a3,0x21
    8000330e:	f6668693          	addi	a3,a3,-154 # 80024270 <log>
    80003312:	a039                	j	80003320 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003314:	02090b63          	beqz	s2,8000334a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003318:	08848493          	addi	s1,s1,136
    8000331c:	02d48a63          	beq	s1,a3,80003350 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003320:	449c                	lw	a5,8(s1)
    80003322:	fef059e3          	blez	a5,80003314 <iget+0x38>
    80003326:	4098                	lw	a4,0(s1)
    80003328:	ff3716e3          	bne	a4,s3,80003314 <iget+0x38>
    8000332c:	40d8                	lw	a4,4(s1)
    8000332e:	ff4713e3          	bne	a4,s4,80003314 <iget+0x38>
      ip->ref++;
    80003332:	2785                	addiw	a5,a5,1
    80003334:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003336:	0001f517          	auipc	a0,0x1f
    8000333a:	49250513          	addi	a0,a0,1170 # 800227c8 <itable>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	95a080e7          	jalr	-1702(ra) # 80000c98 <release>
      return ip;
    80003346:	8926                	mv	s2,s1
    80003348:	a03d                	j	80003376 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334a:	f7f9                	bnez	a5,80003318 <iget+0x3c>
    8000334c:	8926                	mv	s2,s1
    8000334e:	b7e9                	j	80003318 <iget+0x3c>
  if(empty == 0)
    80003350:	02090c63          	beqz	s2,80003388 <iget+0xac>
  ip->dev = dev;
    80003354:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003358:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000335c:	4785                	li	a5,1
    8000335e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003362:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003366:	0001f517          	auipc	a0,0x1f
    8000336a:	46250513          	addi	a0,a0,1122 # 800227c8 <itable>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	92a080e7          	jalr	-1750(ra) # 80000c98 <release>
}
    80003376:	854a                	mv	a0,s2
    80003378:	70a2                	ld	ra,40(sp)
    8000337a:	7402                	ld	s0,32(sp)
    8000337c:	64e2                	ld	s1,24(sp)
    8000337e:	6942                	ld	s2,16(sp)
    80003380:	69a2                	ld	s3,8(sp)
    80003382:	6a02                	ld	s4,0(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret
    panic("iget: no inodes");
    80003388:	00005517          	auipc	a0,0x5
    8000338c:	26050513          	addi	a0,a0,608 # 800085e8 <syscalls+0x130>
    80003390:	ffffd097          	auipc	ra,0xffffd
    80003394:	1ae080e7          	jalr	430(ra) # 8000053e <panic>

0000000080003398 <fsinit>:
fsinit(int dev) {
    80003398:	7179                	addi	sp,sp,-48
    8000339a:	f406                	sd	ra,40(sp)
    8000339c:	f022                	sd	s0,32(sp)
    8000339e:	ec26                	sd	s1,24(sp)
    800033a0:	e84a                	sd	s2,16(sp)
    800033a2:	e44e                	sd	s3,8(sp)
    800033a4:	1800                	addi	s0,sp,48
    800033a6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033a8:	4585                	li	a1,1
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	a64080e7          	jalr	-1436(ra) # 80002e0e <bread>
    800033b2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033b4:	0001f997          	auipc	s3,0x1f
    800033b8:	3f498993          	addi	s3,s3,1012 # 800227a8 <sb>
    800033bc:	02000613          	li	a2,32
    800033c0:	05850593          	addi	a1,a0,88
    800033c4:	854e                	mv	a0,s3
    800033c6:	ffffe097          	auipc	ra,0xffffe
    800033ca:	97a080e7          	jalr	-1670(ra) # 80000d40 <memmove>
  brelse(bp);
    800033ce:	8526                	mv	a0,s1
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	b6e080e7          	jalr	-1170(ra) # 80002f3e <brelse>
  if(sb.magic != FSMAGIC)
    800033d8:	0009a703          	lw	a4,0(s3)
    800033dc:	102037b7          	lui	a5,0x10203
    800033e0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033e4:	02f71263          	bne	a4,a5,80003408 <fsinit+0x70>
  initlog(dev, &sb);
    800033e8:	0001f597          	auipc	a1,0x1f
    800033ec:	3c058593          	addi	a1,a1,960 # 800227a8 <sb>
    800033f0:	854a                	mv	a0,s2
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	b4c080e7          	jalr	-1204(ra) # 80003f3e <initlog>
}
    800033fa:	70a2                	ld	ra,40(sp)
    800033fc:	7402                	ld	s0,32(sp)
    800033fe:	64e2                	ld	s1,24(sp)
    80003400:	6942                	ld	s2,16(sp)
    80003402:	69a2                	ld	s3,8(sp)
    80003404:	6145                	addi	sp,sp,48
    80003406:	8082                	ret
    panic("invalid file system");
    80003408:	00005517          	auipc	a0,0x5
    8000340c:	1f050513          	addi	a0,a0,496 # 800085f8 <syscalls+0x140>
    80003410:	ffffd097          	auipc	ra,0xffffd
    80003414:	12e080e7          	jalr	302(ra) # 8000053e <panic>

0000000080003418 <iinit>:
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003426:	00005597          	auipc	a1,0x5
    8000342a:	1ea58593          	addi	a1,a1,490 # 80008610 <syscalls+0x158>
    8000342e:	0001f517          	auipc	a0,0x1f
    80003432:	39a50513          	addi	a0,a0,922 # 800227c8 <itable>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	71e080e7          	jalr	1822(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000343e:	0001f497          	auipc	s1,0x1f
    80003442:	3b248493          	addi	s1,s1,946 # 800227f0 <itable+0x28>
    80003446:	00021997          	auipc	s3,0x21
    8000344a:	e3a98993          	addi	s3,s3,-454 # 80024280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000344e:	00005917          	auipc	s2,0x5
    80003452:	1ca90913          	addi	s2,s2,458 # 80008618 <syscalls+0x160>
    80003456:	85ca                	mv	a1,s2
    80003458:	8526                	mv	a0,s1
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	e46080e7          	jalr	-442(ra) # 800042a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003462:	08848493          	addi	s1,s1,136
    80003466:	ff3498e3          	bne	s1,s3,80003456 <iinit+0x3e>
}
    8000346a:	70a2                	ld	ra,40(sp)
    8000346c:	7402                	ld	s0,32(sp)
    8000346e:	64e2                	ld	s1,24(sp)
    80003470:	6942                	ld	s2,16(sp)
    80003472:	69a2                	ld	s3,8(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret

0000000080003478 <ialloc>:
{
    80003478:	715d                	addi	sp,sp,-80
    8000347a:	e486                	sd	ra,72(sp)
    8000347c:	e0a2                	sd	s0,64(sp)
    8000347e:	fc26                	sd	s1,56(sp)
    80003480:	f84a                	sd	s2,48(sp)
    80003482:	f44e                	sd	s3,40(sp)
    80003484:	f052                	sd	s4,32(sp)
    80003486:	ec56                	sd	s5,24(sp)
    80003488:	e85a                	sd	s6,16(sp)
    8000348a:	e45e                	sd	s7,8(sp)
    8000348c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000348e:	0001f717          	auipc	a4,0x1f
    80003492:	32672703          	lw	a4,806(a4) # 800227b4 <sb+0xc>
    80003496:	4785                	li	a5,1
    80003498:	04e7fa63          	bgeu	a5,a4,800034ec <ialloc+0x74>
    8000349c:	8aaa                	mv	s5,a0
    8000349e:	8bae                	mv	s7,a1
    800034a0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034a2:	0001fa17          	auipc	s4,0x1f
    800034a6:	306a0a13          	addi	s4,s4,774 # 800227a8 <sb>
    800034aa:	00048b1b          	sext.w	s6,s1
    800034ae:	0044d593          	srli	a1,s1,0x4
    800034b2:	018a2783          	lw	a5,24(s4)
    800034b6:	9dbd                	addw	a1,a1,a5
    800034b8:	8556                	mv	a0,s5
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	954080e7          	jalr	-1708(ra) # 80002e0e <bread>
    800034c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034c4:	05850993          	addi	s3,a0,88
    800034c8:	00f4f793          	andi	a5,s1,15
    800034cc:	079a                	slli	a5,a5,0x6
    800034ce:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034d0:	00099783          	lh	a5,0(s3)
    800034d4:	c785                	beqz	a5,800034fc <ialloc+0x84>
    brelse(bp);
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	a68080e7          	jalr	-1432(ra) # 80002f3e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034de:	0485                	addi	s1,s1,1
    800034e0:	00ca2703          	lw	a4,12(s4)
    800034e4:	0004879b          	sext.w	a5,s1
    800034e8:	fce7e1e3          	bltu	a5,a4,800034aa <ialloc+0x32>
  panic("ialloc: no inodes");
    800034ec:	00005517          	auipc	a0,0x5
    800034f0:	13450513          	addi	a0,a0,308 # 80008620 <syscalls+0x168>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	04a080e7          	jalr	74(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800034fc:	04000613          	li	a2,64
    80003500:	4581                	li	a1,0
    80003502:	854e                	mv	a0,s3
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	7dc080e7          	jalr	2012(ra) # 80000ce0 <memset>
      dip->type = type;
    8000350c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003510:	854a                	mv	a0,s2
    80003512:	00001097          	auipc	ra,0x1
    80003516:	ca8080e7          	jalr	-856(ra) # 800041ba <log_write>
      brelse(bp);
    8000351a:	854a                	mv	a0,s2
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	a22080e7          	jalr	-1502(ra) # 80002f3e <brelse>
      return iget(dev, inum);
    80003524:	85da                	mv	a1,s6
    80003526:	8556                	mv	a0,s5
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	db4080e7          	jalr	-588(ra) # 800032dc <iget>
}
    80003530:	60a6                	ld	ra,72(sp)
    80003532:	6406                	ld	s0,64(sp)
    80003534:	74e2                	ld	s1,56(sp)
    80003536:	7942                	ld	s2,48(sp)
    80003538:	79a2                	ld	s3,40(sp)
    8000353a:	7a02                	ld	s4,32(sp)
    8000353c:	6ae2                	ld	s5,24(sp)
    8000353e:	6b42                	ld	s6,16(sp)
    80003540:	6ba2                	ld	s7,8(sp)
    80003542:	6161                	addi	sp,sp,80
    80003544:	8082                	ret

0000000080003546 <iupdate>:
{
    80003546:	1101                	addi	sp,sp,-32
    80003548:	ec06                	sd	ra,24(sp)
    8000354a:	e822                	sd	s0,16(sp)
    8000354c:	e426                	sd	s1,8(sp)
    8000354e:	e04a                	sd	s2,0(sp)
    80003550:	1000                	addi	s0,sp,32
    80003552:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003554:	415c                	lw	a5,4(a0)
    80003556:	0047d79b          	srliw	a5,a5,0x4
    8000355a:	0001f597          	auipc	a1,0x1f
    8000355e:	2665a583          	lw	a1,614(a1) # 800227c0 <sb+0x18>
    80003562:	9dbd                	addw	a1,a1,a5
    80003564:	4108                	lw	a0,0(a0)
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	8a8080e7          	jalr	-1880(ra) # 80002e0e <bread>
    8000356e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003570:	05850793          	addi	a5,a0,88
    80003574:	40c8                	lw	a0,4(s1)
    80003576:	893d                	andi	a0,a0,15
    80003578:	051a                	slli	a0,a0,0x6
    8000357a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000357c:	04449703          	lh	a4,68(s1)
    80003580:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003584:	04649703          	lh	a4,70(s1)
    80003588:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000358c:	04849703          	lh	a4,72(s1)
    80003590:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003594:	04a49703          	lh	a4,74(s1)
    80003598:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000359c:	44f8                	lw	a4,76(s1)
    8000359e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035a0:	03400613          	li	a2,52
    800035a4:	05048593          	addi	a1,s1,80
    800035a8:	0531                	addi	a0,a0,12
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	796080e7          	jalr	1942(ra) # 80000d40 <memmove>
  log_write(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	c06080e7          	jalr	-1018(ra) # 800041ba <log_write>
  brelse(bp);
    800035bc:	854a                	mv	a0,s2
    800035be:	00000097          	auipc	ra,0x0
    800035c2:	980080e7          	jalr	-1664(ra) # 80002f3e <brelse>
}
    800035c6:	60e2                	ld	ra,24(sp)
    800035c8:	6442                	ld	s0,16(sp)
    800035ca:	64a2                	ld	s1,8(sp)
    800035cc:	6902                	ld	s2,0(sp)
    800035ce:	6105                	addi	sp,sp,32
    800035d0:	8082                	ret

00000000800035d2 <idup>:
{
    800035d2:	1101                	addi	sp,sp,-32
    800035d4:	ec06                	sd	ra,24(sp)
    800035d6:	e822                	sd	s0,16(sp)
    800035d8:	e426                	sd	s1,8(sp)
    800035da:	1000                	addi	s0,sp,32
    800035dc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035de:	0001f517          	auipc	a0,0x1f
    800035e2:	1ea50513          	addi	a0,a0,490 # 800227c8 <itable>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	5fe080e7          	jalr	1534(ra) # 80000be4 <acquire>
  ip->ref++;
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	2785                	addiw	a5,a5,1
    800035f2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035f4:	0001f517          	auipc	a0,0x1f
    800035f8:	1d450513          	addi	a0,a0,468 # 800227c8 <itable>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	69c080e7          	jalr	1692(ra) # 80000c98 <release>
}
    80003604:	8526                	mv	a0,s1
    80003606:	60e2                	ld	ra,24(sp)
    80003608:	6442                	ld	s0,16(sp)
    8000360a:	64a2                	ld	s1,8(sp)
    8000360c:	6105                	addi	sp,sp,32
    8000360e:	8082                	ret

0000000080003610 <ilock>:
{
    80003610:	1101                	addi	sp,sp,-32
    80003612:	ec06                	sd	ra,24(sp)
    80003614:	e822                	sd	s0,16(sp)
    80003616:	e426                	sd	s1,8(sp)
    80003618:	e04a                	sd	s2,0(sp)
    8000361a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000361c:	c115                	beqz	a0,80003640 <ilock+0x30>
    8000361e:	84aa                	mv	s1,a0
    80003620:	451c                	lw	a5,8(a0)
    80003622:	00f05f63          	blez	a5,80003640 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003626:	0541                	addi	a0,a0,16
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	cb2080e7          	jalr	-846(ra) # 800042da <acquiresleep>
  if(ip->valid == 0){
    80003630:	40bc                	lw	a5,64(s1)
    80003632:	cf99                	beqz	a5,80003650 <ilock+0x40>
}
    80003634:	60e2                	ld	ra,24(sp)
    80003636:	6442                	ld	s0,16(sp)
    80003638:	64a2                	ld	s1,8(sp)
    8000363a:	6902                	ld	s2,0(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret
    panic("ilock");
    80003640:	00005517          	auipc	a0,0x5
    80003644:	ff850513          	addi	a0,a0,-8 # 80008638 <syscalls+0x180>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	ef6080e7          	jalr	-266(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003650:	40dc                	lw	a5,4(s1)
    80003652:	0047d79b          	srliw	a5,a5,0x4
    80003656:	0001f597          	auipc	a1,0x1f
    8000365a:	16a5a583          	lw	a1,362(a1) # 800227c0 <sb+0x18>
    8000365e:	9dbd                	addw	a1,a1,a5
    80003660:	4088                	lw	a0,0(s1)
    80003662:	fffff097          	auipc	ra,0xfffff
    80003666:	7ac080e7          	jalr	1964(ra) # 80002e0e <bread>
    8000366a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366c:	05850593          	addi	a1,a0,88
    80003670:	40dc                	lw	a5,4(s1)
    80003672:	8bbd                	andi	a5,a5,15
    80003674:	079a                	slli	a5,a5,0x6
    80003676:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003678:	00059783          	lh	a5,0(a1)
    8000367c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003680:	00259783          	lh	a5,2(a1)
    80003684:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003688:	00459783          	lh	a5,4(a1)
    8000368c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003690:	00659783          	lh	a5,6(a1)
    80003694:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003698:	459c                	lw	a5,8(a1)
    8000369a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000369c:	03400613          	li	a2,52
    800036a0:	05b1                	addi	a1,a1,12
    800036a2:	05048513          	addi	a0,s1,80
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>
    brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	88e080e7          	jalr	-1906(ra) # 80002f3e <brelse>
    ip->valid = 1;
    800036b8:	4785                	li	a5,1
    800036ba:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036bc:	04449783          	lh	a5,68(s1)
    800036c0:	fbb5                	bnez	a5,80003634 <ilock+0x24>
      panic("ilock: no type");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	f7e50513          	addi	a0,a0,-130 # 80008640 <syscalls+0x188>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e74080e7          	jalr	-396(ra) # 8000053e <panic>

00000000800036d2 <iunlock>:
{
    800036d2:	1101                	addi	sp,sp,-32
    800036d4:	ec06                	sd	ra,24(sp)
    800036d6:	e822                	sd	s0,16(sp)
    800036d8:	e426                	sd	s1,8(sp)
    800036da:	e04a                	sd	s2,0(sp)
    800036dc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036de:	c905                	beqz	a0,8000370e <iunlock+0x3c>
    800036e0:	84aa                	mv	s1,a0
    800036e2:	01050913          	addi	s2,a0,16
    800036e6:	854a                	mv	a0,s2
    800036e8:	00001097          	auipc	ra,0x1
    800036ec:	c8c080e7          	jalr	-884(ra) # 80004374 <holdingsleep>
    800036f0:	cd19                	beqz	a0,8000370e <iunlock+0x3c>
    800036f2:	449c                	lw	a5,8(s1)
    800036f4:	00f05d63          	blez	a5,8000370e <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036f8:	854a                	mv	a0,s2
    800036fa:	00001097          	auipc	ra,0x1
    800036fe:	c36080e7          	jalr	-970(ra) # 80004330 <releasesleep>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6902                	ld	s2,0(sp)
    8000370a:	6105                	addi	sp,sp,32
    8000370c:	8082                	ret
    panic("iunlock");
    8000370e:	00005517          	auipc	a0,0x5
    80003712:	f4250513          	addi	a0,a0,-190 # 80008650 <syscalls+0x198>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>

000000008000371e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000371e:	7179                	addi	sp,sp,-48
    80003720:	f406                	sd	ra,40(sp)
    80003722:	f022                	sd	s0,32(sp)
    80003724:	ec26                	sd	s1,24(sp)
    80003726:	e84a                	sd	s2,16(sp)
    80003728:	e44e                	sd	s3,8(sp)
    8000372a:	e052                	sd	s4,0(sp)
    8000372c:	1800                	addi	s0,sp,48
    8000372e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003730:	05050493          	addi	s1,a0,80
    80003734:	08050913          	addi	s2,a0,128
    80003738:	a021                	j	80003740 <itrunc+0x22>
    8000373a:	0491                	addi	s1,s1,4
    8000373c:	01248d63          	beq	s1,s2,80003756 <itrunc+0x38>
    if(ip->addrs[i]){
    80003740:	408c                	lw	a1,0(s1)
    80003742:	dde5                	beqz	a1,8000373a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003744:	0009a503          	lw	a0,0(s3)
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	90c080e7          	jalr	-1780(ra) # 80003054 <bfree>
      ip->addrs[i] = 0;
    80003750:	0004a023          	sw	zero,0(s1)
    80003754:	b7dd                	j	8000373a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003756:	0809a583          	lw	a1,128(s3)
    8000375a:	e185                	bnez	a1,8000377a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000375c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003760:	854e                	mv	a0,s3
    80003762:	00000097          	auipc	ra,0x0
    80003766:	de4080e7          	jalr	-540(ra) # 80003546 <iupdate>
}
    8000376a:	70a2                	ld	ra,40(sp)
    8000376c:	7402                	ld	s0,32(sp)
    8000376e:	64e2                	ld	s1,24(sp)
    80003770:	6942                	ld	s2,16(sp)
    80003772:	69a2                	ld	s3,8(sp)
    80003774:	6a02                	ld	s4,0(sp)
    80003776:	6145                	addi	sp,sp,48
    80003778:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000377a:	0009a503          	lw	a0,0(s3)
    8000377e:	fffff097          	auipc	ra,0xfffff
    80003782:	690080e7          	jalr	1680(ra) # 80002e0e <bread>
    80003786:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003788:	05850493          	addi	s1,a0,88
    8000378c:	45850913          	addi	s2,a0,1112
    80003790:	a811                	j	800037a4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003792:	0009a503          	lw	a0,0(s3)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	8be080e7          	jalr	-1858(ra) # 80003054 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000379e:	0491                	addi	s1,s1,4
    800037a0:	01248563          	beq	s1,s2,800037aa <itrunc+0x8c>
      if(a[j])
    800037a4:	408c                	lw	a1,0(s1)
    800037a6:	dde5                	beqz	a1,8000379e <itrunc+0x80>
    800037a8:	b7ed                	j	80003792 <itrunc+0x74>
    brelse(bp);
    800037aa:	8552                	mv	a0,s4
    800037ac:	fffff097          	auipc	ra,0xfffff
    800037b0:	792080e7          	jalr	1938(ra) # 80002f3e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037b4:	0809a583          	lw	a1,128(s3)
    800037b8:	0009a503          	lw	a0,0(s3)
    800037bc:	00000097          	auipc	ra,0x0
    800037c0:	898080e7          	jalr	-1896(ra) # 80003054 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037c4:	0809a023          	sw	zero,128(s3)
    800037c8:	bf51                	j	8000375c <itrunc+0x3e>

00000000800037ca <iput>:
{
    800037ca:	1101                	addi	sp,sp,-32
    800037cc:	ec06                	sd	ra,24(sp)
    800037ce:	e822                	sd	s0,16(sp)
    800037d0:	e426                	sd	s1,8(sp)
    800037d2:	e04a                	sd	s2,0(sp)
    800037d4:	1000                	addi	s0,sp,32
    800037d6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037d8:	0001f517          	auipc	a0,0x1f
    800037dc:	ff050513          	addi	a0,a0,-16 # 800227c8 <itable>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	404080e7          	jalr	1028(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037e8:	4498                	lw	a4,8(s1)
    800037ea:	4785                	li	a5,1
    800037ec:	02f70363          	beq	a4,a5,80003812 <iput+0x48>
  ip->ref--;
    800037f0:	449c                	lw	a5,8(s1)
    800037f2:	37fd                	addiw	a5,a5,-1
    800037f4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037f6:	0001f517          	auipc	a0,0x1f
    800037fa:	fd250513          	addi	a0,a0,-46 # 800227c8 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	49a080e7          	jalr	1178(ra) # 80000c98 <release>
}
    80003806:	60e2                	ld	ra,24(sp)
    80003808:	6442                	ld	s0,16(sp)
    8000380a:	64a2                	ld	s1,8(sp)
    8000380c:	6902                	ld	s2,0(sp)
    8000380e:	6105                	addi	sp,sp,32
    80003810:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003812:	40bc                	lw	a5,64(s1)
    80003814:	dff1                	beqz	a5,800037f0 <iput+0x26>
    80003816:	04a49783          	lh	a5,74(s1)
    8000381a:	fbf9                	bnez	a5,800037f0 <iput+0x26>
    acquiresleep(&ip->lock);
    8000381c:	01048913          	addi	s2,s1,16
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	ab8080e7          	jalr	-1352(ra) # 800042da <acquiresleep>
    release(&itable.lock);
    8000382a:	0001f517          	auipc	a0,0x1f
    8000382e:	f9e50513          	addi	a0,a0,-98 # 800227c8 <itable>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
    itrunc(ip);
    8000383a:	8526                	mv	a0,s1
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	ee2080e7          	jalr	-286(ra) # 8000371e <itrunc>
    ip->type = 0;
    80003844:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003848:	8526                	mv	a0,s1
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	cfc080e7          	jalr	-772(ra) # 80003546 <iupdate>
    ip->valid = 0;
    80003852:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	ad8080e7          	jalr	-1320(ra) # 80004330 <releasesleep>
    acquire(&itable.lock);
    80003860:	0001f517          	auipc	a0,0x1f
    80003864:	f6850513          	addi	a0,a0,-152 # 800227c8 <itable>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	37c080e7          	jalr	892(ra) # 80000be4 <acquire>
    80003870:	b741                	j	800037f0 <iput+0x26>

0000000080003872 <iunlockput>:
{
    80003872:	1101                	addi	sp,sp,-32
    80003874:	ec06                	sd	ra,24(sp)
    80003876:	e822                	sd	s0,16(sp)
    80003878:	e426                	sd	s1,8(sp)
    8000387a:	1000                	addi	s0,sp,32
    8000387c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	e54080e7          	jalr	-428(ra) # 800036d2 <iunlock>
  iput(ip);
    80003886:	8526                	mv	a0,s1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	f42080e7          	jalr	-190(ra) # 800037ca <iput>
}
    80003890:	60e2                	ld	ra,24(sp)
    80003892:	6442                	ld	s0,16(sp)
    80003894:	64a2                	ld	s1,8(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret

000000008000389a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000389a:	1141                	addi	sp,sp,-16
    8000389c:	e422                	sd	s0,8(sp)
    8000389e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038a0:	411c                	lw	a5,0(a0)
    800038a2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038a4:	415c                	lw	a5,4(a0)
    800038a6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038a8:	04451783          	lh	a5,68(a0)
    800038ac:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038b0:	04a51783          	lh	a5,74(a0)
    800038b4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038b8:	04c56783          	lwu	a5,76(a0)
    800038bc:	e99c                	sd	a5,16(a1)
}
    800038be:	6422                	ld	s0,8(sp)
    800038c0:	0141                	addi	sp,sp,16
    800038c2:	8082                	ret

00000000800038c4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038c4:	457c                	lw	a5,76(a0)
    800038c6:	0ed7e963          	bltu	a5,a3,800039b8 <readi+0xf4>
{
    800038ca:	7159                	addi	sp,sp,-112
    800038cc:	f486                	sd	ra,104(sp)
    800038ce:	f0a2                	sd	s0,96(sp)
    800038d0:	eca6                	sd	s1,88(sp)
    800038d2:	e8ca                	sd	s2,80(sp)
    800038d4:	e4ce                	sd	s3,72(sp)
    800038d6:	e0d2                	sd	s4,64(sp)
    800038d8:	fc56                	sd	s5,56(sp)
    800038da:	f85a                	sd	s6,48(sp)
    800038dc:	f45e                	sd	s7,40(sp)
    800038de:	f062                	sd	s8,32(sp)
    800038e0:	ec66                	sd	s9,24(sp)
    800038e2:	e86a                	sd	s10,16(sp)
    800038e4:	e46e                	sd	s11,8(sp)
    800038e6:	1880                	addi	s0,sp,112
    800038e8:	8baa                	mv	s7,a0
    800038ea:	8c2e                	mv	s8,a1
    800038ec:	8ab2                	mv	s5,a2
    800038ee:	84b6                	mv	s1,a3
    800038f0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038f2:	9f35                	addw	a4,a4,a3
    return 0;
    800038f4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038f6:	0ad76063          	bltu	a4,a3,80003996 <readi+0xd2>
  if(off + n > ip->size)
    800038fa:	00e7f463          	bgeu	a5,a4,80003902 <readi+0x3e>
    n = ip->size - off;
    800038fe:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003902:	0a0b0963          	beqz	s6,800039b4 <readi+0xf0>
    80003906:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003908:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000390c:	5cfd                	li	s9,-1
    8000390e:	a82d                	j	80003948 <readi+0x84>
    80003910:	020a1d93          	slli	s11,s4,0x20
    80003914:	020ddd93          	srli	s11,s11,0x20
    80003918:	05890613          	addi	a2,s2,88
    8000391c:	86ee                	mv	a3,s11
    8000391e:	963a                	add	a2,a2,a4
    80003920:	85d6                	mv	a1,s5
    80003922:	8562                	mv	a0,s8
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	b2e080e7          	jalr	-1234(ra) # 80002452 <either_copyout>
    8000392c:	05950d63          	beq	a0,s9,80003986 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003930:	854a                	mv	a0,s2
    80003932:	fffff097          	auipc	ra,0xfffff
    80003936:	60c080e7          	jalr	1548(ra) # 80002f3e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000393a:	013a09bb          	addw	s3,s4,s3
    8000393e:	009a04bb          	addw	s1,s4,s1
    80003942:	9aee                	add	s5,s5,s11
    80003944:	0569f763          	bgeu	s3,s6,80003992 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003948:	000ba903          	lw	s2,0(s7)
    8000394c:	00a4d59b          	srliw	a1,s1,0xa
    80003950:	855e                	mv	a0,s7
    80003952:	00000097          	auipc	ra,0x0
    80003956:	8b0080e7          	jalr	-1872(ra) # 80003202 <bmap>
    8000395a:	0005059b          	sext.w	a1,a0
    8000395e:	854a                	mv	a0,s2
    80003960:	fffff097          	auipc	ra,0xfffff
    80003964:	4ae080e7          	jalr	1198(ra) # 80002e0e <bread>
    80003968:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000396a:	3ff4f713          	andi	a4,s1,1023
    8000396e:	40ed07bb          	subw	a5,s10,a4
    80003972:	413b06bb          	subw	a3,s6,s3
    80003976:	8a3e                	mv	s4,a5
    80003978:	2781                	sext.w	a5,a5
    8000397a:	0006861b          	sext.w	a2,a3
    8000397e:	f8f679e3          	bgeu	a2,a5,80003910 <readi+0x4c>
    80003982:	8a36                	mv	s4,a3
    80003984:	b771                	j	80003910 <readi+0x4c>
      brelse(bp);
    80003986:	854a                	mv	a0,s2
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	5b6080e7          	jalr	1462(ra) # 80002f3e <brelse>
      tot = -1;
    80003990:	59fd                	li	s3,-1
  }
  return tot;
    80003992:	0009851b          	sext.w	a0,s3
}
    80003996:	70a6                	ld	ra,104(sp)
    80003998:	7406                	ld	s0,96(sp)
    8000399a:	64e6                	ld	s1,88(sp)
    8000399c:	6946                	ld	s2,80(sp)
    8000399e:	69a6                	ld	s3,72(sp)
    800039a0:	6a06                	ld	s4,64(sp)
    800039a2:	7ae2                	ld	s5,56(sp)
    800039a4:	7b42                	ld	s6,48(sp)
    800039a6:	7ba2                	ld	s7,40(sp)
    800039a8:	7c02                	ld	s8,32(sp)
    800039aa:	6ce2                	ld	s9,24(sp)
    800039ac:	6d42                	ld	s10,16(sp)
    800039ae:	6da2                	ld	s11,8(sp)
    800039b0:	6165                	addi	sp,sp,112
    800039b2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039b4:	89da                	mv	s3,s6
    800039b6:	bff1                	j	80003992 <readi+0xce>
    return 0;
    800039b8:	4501                	li	a0,0
}
    800039ba:	8082                	ret

00000000800039bc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039bc:	457c                	lw	a5,76(a0)
    800039be:	10d7e863          	bltu	a5,a3,80003ace <writei+0x112>
{
    800039c2:	7159                	addi	sp,sp,-112
    800039c4:	f486                	sd	ra,104(sp)
    800039c6:	f0a2                	sd	s0,96(sp)
    800039c8:	eca6                	sd	s1,88(sp)
    800039ca:	e8ca                	sd	s2,80(sp)
    800039cc:	e4ce                	sd	s3,72(sp)
    800039ce:	e0d2                	sd	s4,64(sp)
    800039d0:	fc56                	sd	s5,56(sp)
    800039d2:	f85a                	sd	s6,48(sp)
    800039d4:	f45e                	sd	s7,40(sp)
    800039d6:	f062                	sd	s8,32(sp)
    800039d8:	ec66                	sd	s9,24(sp)
    800039da:	e86a                	sd	s10,16(sp)
    800039dc:	e46e                	sd	s11,8(sp)
    800039de:	1880                	addi	s0,sp,112
    800039e0:	8b2a                	mv	s6,a0
    800039e2:	8c2e                	mv	s8,a1
    800039e4:	8ab2                	mv	s5,a2
    800039e6:	8936                	mv	s2,a3
    800039e8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039ea:	00e687bb          	addw	a5,a3,a4
    800039ee:	0ed7e263          	bltu	a5,a3,80003ad2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039f2:	00043737          	lui	a4,0x43
    800039f6:	0ef76063          	bltu	a4,a5,80003ad6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039fa:	0c0b8863          	beqz	s7,80003aca <writei+0x10e>
    800039fe:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a00:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a04:	5cfd                	li	s9,-1
    80003a06:	a091                	j	80003a4a <writei+0x8e>
    80003a08:	02099d93          	slli	s11,s3,0x20
    80003a0c:	020ddd93          	srli	s11,s11,0x20
    80003a10:	05848513          	addi	a0,s1,88
    80003a14:	86ee                	mv	a3,s11
    80003a16:	8656                	mv	a2,s5
    80003a18:	85e2                	mv	a1,s8
    80003a1a:	953a                	add	a0,a0,a4
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	a8c080e7          	jalr	-1396(ra) # 800024a8 <either_copyin>
    80003a24:	07950263          	beq	a0,s9,80003a88 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a28:	8526                	mv	a0,s1
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	790080e7          	jalr	1936(ra) # 800041ba <log_write>
    brelse(bp);
    80003a32:	8526                	mv	a0,s1
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	50a080e7          	jalr	1290(ra) # 80002f3e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a3c:	01498a3b          	addw	s4,s3,s4
    80003a40:	0129893b          	addw	s2,s3,s2
    80003a44:	9aee                	add	s5,s5,s11
    80003a46:	057a7663          	bgeu	s4,s7,80003a92 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a4a:	000b2483          	lw	s1,0(s6)
    80003a4e:	00a9559b          	srliw	a1,s2,0xa
    80003a52:	855a                	mv	a0,s6
    80003a54:	fffff097          	auipc	ra,0xfffff
    80003a58:	7ae080e7          	jalr	1966(ra) # 80003202 <bmap>
    80003a5c:	0005059b          	sext.w	a1,a0
    80003a60:	8526                	mv	a0,s1
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	3ac080e7          	jalr	940(ra) # 80002e0e <bread>
    80003a6a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a6c:	3ff97713          	andi	a4,s2,1023
    80003a70:	40ed07bb          	subw	a5,s10,a4
    80003a74:	414b86bb          	subw	a3,s7,s4
    80003a78:	89be                	mv	s3,a5
    80003a7a:	2781                	sext.w	a5,a5
    80003a7c:	0006861b          	sext.w	a2,a3
    80003a80:	f8f674e3          	bgeu	a2,a5,80003a08 <writei+0x4c>
    80003a84:	89b6                	mv	s3,a3
    80003a86:	b749                	j	80003a08 <writei+0x4c>
      brelse(bp);
    80003a88:	8526                	mv	a0,s1
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	4b4080e7          	jalr	1204(ra) # 80002f3e <brelse>
  }

  if(off > ip->size)
    80003a92:	04cb2783          	lw	a5,76(s6)
    80003a96:	0127f463          	bgeu	a5,s2,80003a9e <writei+0xe2>
    ip->size = off;
    80003a9a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a9e:	855a                	mv	a0,s6
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	aa6080e7          	jalr	-1370(ra) # 80003546 <iupdate>

  return tot;
    80003aa8:	000a051b          	sext.w	a0,s4
}
    80003aac:	70a6                	ld	ra,104(sp)
    80003aae:	7406                	ld	s0,96(sp)
    80003ab0:	64e6                	ld	s1,88(sp)
    80003ab2:	6946                	ld	s2,80(sp)
    80003ab4:	69a6                	ld	s3,72(sp)
    80003ab6:	6a06                	ld	s4,64(sp)
    80003ab8:	7ae2                	ld	s5,56(sp)
    80003aba:	7b42                	ld	s6,48(sp)
    80003abc:	7ba2                	ld	s7,40(sp)
    80003abe:	7c02                	ld	s8,32(sp)
    80003ac0:	6ce2                	ld	s9,24(sp)
    80003ac2:	6d42                	ld	s10,16(sp)
    80003ac4:	6da2                	ld	s11,8(sp)
    80003ac6:	6165                	addi	sp,sp,112
    80003ac8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aca:	8a5e                	mv	s4,s7
    80003acc:	bfc9                	j	80003a9e <writei+0xe2>
    return -1;
    80003ace:	557d                	li	a0,-1
}
    80003ad0:	8082                	ret
    return -1;
    80003ad2:	557d                	li	a0,-1
    80003ad4:	bfe1                	j	80003aac <writei+0xf0>
    return -1;
    80003ad6:	557d                	li	a0,-1
    80003ad8:	bfd1                	j	80003aac <writei+0xf0>

0000000080003ada <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ada:	1141                	addi	sp,sp,-16
    80003adc:	e406                	sd	ra,8(sp)
    80003ade:	e022                	sd	s0,0(sp)
    80003ae0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ae2:	4639                	li	a2,14
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	2d4080e7          	jalr	724(ra) # 80000db8 <strncmp>
}
    80003aec:	60a2                	ld	ra,8(sp)
    80003aee:	6402                	ld	s0,0(sp)
    80003af0:	0141                	addi	sp,sp,16
    80003af2:	8082                	ret

0000000080003af4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003af4:	7139                	addi	sp,sp,-64
    80003af6:	fc06                	sd	ra,56(sp)
    80003af8:	f822                	sd	s0,48(sp)
    80003afa:	f426                	sd	s1,40(sp)
    80003afc:	f04a                	sd	s2,32(sp)
    80003afe:	ec4e                	sd	s3,24(sp)
    80003b00:	e852                	sd	s4,16(sp)
    80003b02:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b04:	04451703          	lh	a4,68(a0)
    80003b08:	4785                	li	a5,1
    80003b0a:	00f71a63          	bne	a4,a5,80003b1e <dirlookup+0x2a>
    80003b0e:	892a                	mv	s2,a0
    80003b10:	89ae                	mv	s3,a1
    80003b12:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b14:	457c                	lw	a5,76(a0)
    80003b16:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b18:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b1a:	e79d                	bnez	a5,80003b48 <dirlookup+0x54>
    80003b1c:	a8a5                	j	80003b94 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b1e:	00005517          	auipc	a0,0x5
    80003b22:	b3a50513          	addi	a0,a0,-1222 # 80008658 <syscalls+0x1a0>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	a18080e7          	jalr	-1512(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003b2e:	00005517          	auipc	a0,0x5
    80003b32:	b4250513          	addi	a0,a0,-1214 # 80008670 <syscalls+0x1b8>
    80003b36:	ffffd097          	auipc	ra,0xffffd
    80003b3a:	a08080e7          	jalr	-1528(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b3e:	24c1                	addiw	s1,s1,16
    80003b40:	04c92783          	lw	a5,76(s2)
    80003b44:	04f4f763          	bgeu	s1,a5,80003b92 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b48:	4741                	li	a4,16
    80003b4a:	86a6                	mv	a3,s1
    80003b4c:	fc040613          	addi	a2,s0,-64
    80003b50:	4581                	li	a1,0
    80003b52:	854a                	mv	a0,s2
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	d70080e7          	jalr	-656(ra) # 800038c4 <readi>
    80003b5c:	47c1                	li	a5,16
    80003b5e:	fcf518e3          	bne	a0,a5,80003b2e <dirlookup+0x3a>
    if(de.inum == 0)
    80003b62:	fc045783          	lhu	a5,-64(s0)
    80003b66:	dfe1                	beqz	a5,80003b3e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b68:	fc240593          	addi	a1,s0,-62
    80003b6c:	854e                	mv	a0,s3
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	f6c080e7          	jalr	-148(ra) # 80003ada <namecmp>
    80003b76:	f561                	bnez	a0,80003b3e <dirlookup+0x4a>
      if(poff)
    80003b78:	000a0463          	beqz	s4,80003b80 <dirlookup+0x8c>
        *poff = off;
    80003b7c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b80:	fc045583          	lhu	a1,-64(s0)
    80003b84:	00092503          	lw	a0,0(s2)
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	754080e7          	jalr	1876(ra) # 800032dc <iget>
    80003b90:	a011                	j	80003b94 <dirlookup+0xa0>
  return 0;
    80003b92:	4501                	li	a0,0
}
    80003b94:	70e2                	ld	ra,56(sp)
    80003b96:	7442                	ld	s0,48(sp)
    80003b98:	74a2                	ld	s1,40(sp)
    80003b9a:	7902                	ld	s2,32(sp)
    80003b9c:	69e2                	ld	s3,24(sp)
    80003b9e:	6a42                	ld	s4,16(sp)
    80003ba0:	6121                	addi	sp,sp,64
    80003ba2:	8082                	ret

0000000080003ba4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ba4:	711d                	addi	sp,sp,-96
    80003ba6:	ec86                	sd	ra,88(sp)
    80003ba8:	e8a2                	sd	s0,80(sp)
    80003baa:	e4a6                	sd	s1,72(sp)
    80003bac:	e0ca                	sd	s2,64(sp)
    80003bae:	fc4e                	sd	s3,56(sp)
    80003bb0:	f852                	sd	s4,48(sp)
    80003bb2:	f456                	sd	s5,40(sp)
    80003bb4:	f05a                	sd	s6,32(sp)
    80003bb6:	ec5e                	sd	s7,24(sp)
    80003bb8:	e862                	sd	s8,16(sp)
    80003bba:	e466                	sd	s9,8(sp)
    80003bbc:	1080                	addi	s0,sp,96
    80003bbe:	84aa                	mv	s1,a0
    80003bc0:	8b2e                	mv	s6,a1
    80003bc2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bc4:	00054703          	lbu	a4,0(a0)
    80003bc8:	02f00793          	li	a5,47
    80003bcc:	02f70363          	beq	a4,a5,80003bf2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bd0:	ffffe097          	auipc	ra,0xffffe
    80003bd4:	e22080e7          	jalr	-478(ra) # 800019f2 <myproc>
    80003bd8:	15053503          	ld	a0,336(a0)
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	9f6080e7          	jalr	-1546(ra) # 800035d2 <idup>
    80003be4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003be6:	02f00913          	li	s2,47
  len = path - s;
    80003bea:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003bec:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bee:	4c05                	li	s8,1
    80003bf0:	a865                	j	80003ca8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bf2:	4585                	li	a1,1
    80003bf4:	4505                	li	a0,1
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	6e6080e7          	jalr	1766(ra) # 800032dc <iget>
    80003bfe:	89aa                	mv	s3,a0
    80003c00:	b7dd                	j	80003be6 <namex+0x42>
      iunlockput(ip);
    80003c02:	854e                	mv	a0,s3
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	c6e080e7          	jalr	-914(ra) # 80003872 <iunlockput>
      return 0;
    80003c0c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c0e:	854e                	mv	a0,s3
    80003c10:	60e6                	ld	ra,88(sp)
    80003c12:	6446                	ld	s0,80(sp)
    80003c14:	64a6                	ld	s1,72(sp)
    80003c16:	6906                	ld	s2,64(sp)
    80003c18:	79e2                	ld	s3,56(sp)
    80003c1a:	7a42                	ld	s4,48(sp)
    80003c1c:	7aa2                	ld	s5,40(sp)
    80003c1e:	7b02                	ld	s6,32(sp)
    80003c20:	6be2                	ld	s7,24(sp)
    80003c22:	6c42                	ld	s8,16(sp)
    80003c24:	6ca2                	ld	s9,8(sp)
    80003c26:	6125                	addi	sp,sp,96
    80003c28:	8082                	ret
      iunlock(ip);
    80003c2a:	854e                	mv	a0,s3
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	aa6080e7          	jalr	-1370(ra) # 800036d2 <iunlock>
      return ip;
    80003c34:	bfe9                	j	80003c0e <namex+0x6a>
      iunlockput(ip);
    80003c36:	854e                	mv	a0,s3
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	c3a080e7          	jalr	-966(ra) # 80003872 <iunlockput>
      return 0;
    80003c40:	89d2                	mv	s3,s4
    80003c42:	b7f1                	j	80003c0e <namex+0x6a>
  len = path - s;
    80003c44:	40b48633          	sub	a2,s1,a1
    80003c48:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c4c:	094cd463          	bge	s9,s4,80003cd4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c50:	4639                	li	a2,14
    80003c52:	8556                	mv	a0,s5
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	0ec080e7          	jalr	236(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003c5c:	0004c783          	lbu	a5,0(s1)
    80003c60:	01279763          	bne	a5,s2,80003c6e <namex+0xca>
    path++;
    80003c64:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c66:	0004c783          	lbu	a5,0(s1)
    80003c6a:	ff278de3          	beq	a5,s2,80003c64 <namex+0xc0>
    ilock(ip);
    80003c6e:	854e                	mv	a0,s3
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	9a0080e7          	jalr	-1632(ra) # 80003610 <ilock>
    if(ip->type != T_DIR){
    80003c78:	04499783          	lh	a5,68(s3)
    80003c7c:	f98793e3          	bne	a5,s8,80003c02 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c80:	000b0563          	beqz	s6,80003c8a <namex+0xe6>
    80003c84:	0004c783          	lbu	a5,0(s1)
    80003c88:	d3cd                	beqz	a5,80003c2a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c8a:	865e                	mv	a2,s7
    80003c8c:	85d6                	mv	a1,s5
    80003c8e:	854e                	mv	a0,s3
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	e64080e7          	jalr	-412(ra) # 80003af4 <dirlookup>
    80003c98:	8a2a                	mv	s4,a0
    80003c9a:	dd51                	beqz	a0,80003c36 <namex+0x92>
    iunlockput(ip);
    80003c9c:	854e                	mv	a0,s3
    80003c9e:	00000097          	auipc	ra,0x0
    80003ca2:	bd4080e7          	jalr	-1068(ra) # 80003872 <iunlockput>
    ip = next;
    80003ca6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ca8:	0004c783          	lbu	a5,0(s1)
    80003cac:	05279763          	bne	a5,s2,80003cfa <namex+0x156>
    path++;
    80003cb0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cb2:	0004c783          	lbu	a5,0(s1)
    80003cb6:	ff278de3          	beq	a5,s2,80003cb0 <namex+0x10c>
  if(*path == 0)
    80003cba:	c79d                	beqz	a5,80003ce8 <namex+0x144>
    path++;
    80003cbc:	85a6                	mv	a1,s1
  len = path - s;
    80003cbe:	8a5e                	mv	s4,s7
    80003cc0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cc2:	01278963          	beq	a5,s2,80003cd4 <namex+0x130>
    80003cc6:	dfbd                	beqz	a5,80003c44 <namex+0xa0>
    path++;
    80003cc8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003cca:	0004c783          	lbu	a5,0(s1)
    80003cce:	ff279ce3          	bne	a5,s2,80003cc6 <namex+0x122>
    80003cd2:	bf8d                	j	80003c44 <namex+0xa0>
    memmove(name, s, len);
    80003cd4:	2601                	sext.w	a2,a2
    80003cd6:	8556                	mv	a0,s5
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	068080e7          	jalr	104(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003ce0:	9a56                	add	s4,s4,s5
    80003ce2:	000a0023          	sb	zero,0(s4)
    80003ce6:	bf9d                	j	80003c5c <namex+0xb8>
  if(nameiparent){
    80003ce8:	f20b03e3          	beqz	s6,80003c0e <namex+0x6a>
    iput(ip);
    80003cec:	854e                	mv	a0,s3
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	adc080e7          	jalr	-1316(ra) # 800037ca <iput>
    return 0;
    80003cf6:	4981                	li	s3,0
    80003cf8:	bf19                	j	80003c0e <namex+0x6a>
  if(*path == 0)
    80003cfa:	d7fd                	beqz	a5,80003ce8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cfc:	0004c783          	lbu	a5,0(s1)
    80003d00:	85a6                	mv	a1,s1
    80003d02:	b7d1                	j	80003cc6 <namex+0x122>

0000000080003d04 <dirlink>:
{
    80003d04:	7139                	addi	sp,sp,-64
    80003d06:	fc06                	sd	ra,56(sp)
    80003d08:	f822                	sd	s0,48(sp)
    80003d0a:	f426                	sd	s1,40(sp)
    80003d0c:	f04a                	sd	s2,32(sp)
    80003d0e:	ec4e                	sd	s3,24(sp)
    80003d10:	e852                	sd	s4,16(sp)
    80003d12:	0080                	addi	s0,sp,64
    80003d14:	892a                	mv	s2,a0
    80003d16:	8a2e                	mv	s4,a1
    80003d18:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d1a:	4601                	li	a2,0
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	dd8080e7          	jalr	-552(ra) # 80003af4 <dirlookup>
    80003d24:	e93d                	bnez	a0,80003d9a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d26:	04c92483          	lw	s1,76(s2)
    80003d2a:	c49d                	beqz	s1,80003d58 <dirlink+0x54>
    80003d2c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d2e:	4741                	li	a4,16
    80003d30:	86a6                	mv	a3,s1
    80003d32:	fc040613          	addi	a2,s0,-64
    80003d36:	4581                	li	a1,0
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	b8a080e7          	jalr	-1142(ra) # 800038c4 <readi>
    80003d42:	47c1                	li	a5,16
    80003d44:	06f51163          	bne	a0,a5,80003da6 <dirlink+0xa2>
    if(de.inum == 0)
    80003d48:	fc045783          	lhu	a5,-64(s0)
    80003d4c:	c791                	beqz	a5,80003d58 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4e:	24c1                	addiw	s1,s1,16
    80003d50:	04c92783          	lw	a5,76(s2)
    80003d54:	fcf4ede3          	bltu	s1,a5,80003d2e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d58:	4639                	li	a2,14
    80003d5a:	85d2                	mv	a1,s4
    80003d5c:	fc240513          	addi	a0,s0,-62
    80003d60:	ffffd097          	auipc	ra,0xffffd
    80003d64:	094080e7          	jalr	148(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003d68:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6c:	4741                	li	a4,16
    80003d6e:	86a6                	mv	a3,s1
    80003d70:	fc040613          	addi	a2,s0,-64
    80003d74:	4581                	li	a1,0
    80003d76:	854a                	mv	a0,s2
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	c44080e7          	jalr	-956(ra) # 800039bc <writei>
    80003d80:	872a                	mv	a4,a0
    80003d82:	47c1                	li	a5,16
  return 0;
    80003d84:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d86:	02f71863          	bne	a4,a5,80003db6 <dirlink+0xb2>
}
    80003d8a:	70e2                	ld	ra,56(sp)
    80003d8c:	7442                	ld	s0,48(sp)
    80003d8e:	74a2                	ld	s1,40(sp)
    80003d90:	7902                	ld	s2,32(sp)
    80003d92:	69e2                	ld	s3,24(sp)
    80003d94:	6a42                	ld	s4,16(sp)
    80003d96:	6121                	addi	sp,sp,64
    80003d98:	8082                	ret
    iput(ip);
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	a30080e7          	jalr	-1488(ra) # 800037ca <iput>
    return -1;
    80003da2:	557d                	li	a0,-1
    80003da4:	b7dd                	j	80003d8a <dirlink+0x86>
      panic("dirlink read");
    80003da6:	00005517          	auipc	a0,0x5
    80003daa:	8da50513          	addi	a0,a0,-1830 # 80008680 <syscalls+0x1c8>
    80003dae:	ffffc097          	auipc	ra,0xffffc
    80003db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>
    panic("dirlink");
    80003db6:	00005517          	auipc	a0,0x5
    80003dba:	9da50513          	addi	a0,a0,-1574 # 80008790 <syscalls+0x2d8>
    80003dbe:	ffffc097          	auipc	ra,0xffffc
    80003dc2:	780080e7          	jalr	1920(ra) # 8000053e <panic>

0000000080003dc6 <namei>:

struct inode*
namei(char *path)
{
    80003dc6:	1101                	addi	sp,sp,-32
    80003dc8:	ec06                	sd	ra,24(sp)
    80003dca:	e822                	sd	s0,16(sp)
    80003dcc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dce:	fe040613          	addi	a2,s0,-32
    80003dd2:	4581                	li	a1,0
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	dd0080e7          	jalr	-560(ra) # 80003ba4 <namex>
}
    80003ddc:	60e2                	ld	ra,24(sp)
    80003dde:	6442                	ld	s0,16(sp)
    80003de0:	6105                	addi	sp,sp,32
    80003de2:	8082                	ret

0000000080003de4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003de4:	1141                	addi	sp,sp,-16
    80003de6:	e406                	sd	ra,8(sp)
    80003de8:	e022                	sd	s0,0(sp)
    80003dea:	0800                	addi	s0,sp,16
    80003dec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dee:	4585                	li	a1,1
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	db4080e7          	jalr	-588(ra) # 80003ba4 <namex>
}
    80003df8:	60a2                	ld	ra,8(sp)
    80003dfa:	6402                	ld	s0,0(sp)
    80003dfc:	0141                	addi	sp,sp,16
    80003dfe:	8082                	ret

0000000080003e00 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e00:	1101                	addi	sp,sp,-32
    80003e02:	ec06                	sd	ra,24(sp)
    80003e04:	e822                	sd	s0,16(sp)
    80003e06:	e426                	sd	s1,8(sp)
    80003e08:	e04a                	sd	s2,0(sp)
    80003e0a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e0c:	00020917          	auipc	s2,0x20
    80003e10:	46490913          	addi	s2,s2,1124 # 80024270 <log>
    80003e14:	01892583          	lw	a1,24(s2)
    80003e18:	02892503          	lw	a0,40(s2)
    80003e1c:	fffff097          	auipc	ra,0xfffff
    80003e20:	ff2080e7          	jalr	-14(ra) # 80002e0e <bread>
    80003e24:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e26:	02c92683          	lw	a3,44(s2)
    80003e2a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e2c:	02d05763          	blez	a3,80003e5a <write_head+0x5a>
    80003e30:	00020797          	auipc	a5,0x20
    80003e34:	47078793          	addi	a5,a5,1136 # 800242a0 <log+0x30>
    80003e38:	05c50713          	addi	a4,a0,92
    80003e3c:	36fd                	addiw	a3,a3,-1
    80003e3e:	1682                	slli	a3,a3,0x20
    80003e40:	9281                	srli	a3,a3,0x20
    80003e42:	068a                	slli	a3,a3,0x2
    80003e44:	00020617          	auipc	a2,0x20
    80003e48:	46060613          	addi	a2,a2,1120 # 800242a4 <log+0x34>
    80003e4c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e4e:	4390                	lw	a2,0(a5)
    80003e50:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e52:	0791                	addi	a5,a5,4
    80003e54:	0711                	addi	a4,a4,4
    80003e56:	fed79ce3          	bne	a5,a3,80003e4e <write_head+0x4e>
  }
  bwrite(buf);
    80003e5a:	8526                	mv	a0,s1
    80003e5c:	fffff097          	auipc	ra,0xfffff
    80003e60:	0a4080e7          	jalr	164(ra) # 80002f00 <bwrite>
  brelse(buf);
    80003e64:	8526                	mv	a0,s1
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	0d8080e7          	jalr	216(ra) # 80002f3e <brelse>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret

0000000080003e7a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e7a:	00020797          	auipc	a5,0x20
    80003e7e:	4227a783          	lw	a5,1058(a5) # 8002429c <log+0x2c>
    80003e82:	0af05d63          	blez	a5,80003f3c <install_trans+0xc2>
{
    80003e86:	7139                	addi	sp,sp,-64
    80003e88:	fc06                	sd	ra,56(sp)
    80003e8a:	f822                	sd	s0,48(sp)
    80003e8c:	f426                	sd	s1,40(sp)
    80003e8e:	f04a                	sd	s2,32(sp)
    80003e90:	ec4e                	sd	s3,24(sp)
    80003e92:	e852                	sd	s4,16(sp)
    80003e94:	e456                	sd	s5,8(sp)
    80003e96:	e05a                	sd	s6,0(sp)
    80003e98:	0080                	addi	s0,sp,64
    80003e9a:	8b2a                	mv	s6,a0
    80003e9c:	00020a97          	auipc	s5,0x20
    80003ea0:	404a8a93          	addi	s5,s5,1028 # 800242a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ea4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ea6:	00020997          	auipc	s3,0x20
    80003eaa:	3ca98993          	addi	s3,s3,970 # 80024270 <log>
    80003eae:	a035                	j	80003eda <install_trans+0x60>
      bunpin(dbuf);
    80003eb0:	8526                	mv	a0,s1
    80003eb2:	fffff097          	auipc	ra,0xfffff
    80003eb6:	166080e7          	jalr	358(ra) # 80003018 <bunpin>
    brelse(lbuf);
    80003eba:	854a                	mv	a0,s2
    80003ebc:	fffff097          	auipc	ra,0xfffff
    80003ec0:	082080e7          	jalr	130(ra) # 80002f3e <brelse>
    brelse(dbuf);
    80003ec4:	8526                	mv	a0,s1
    80003ec6:	fffff097          	auipc	ra,0xfffff
    80003eca:	078080e7          	jalr	120(ra) # 80002f3e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ece:	2a05                	addiw	s4,s4,1
    80003ed0:	0a91                	addi	s5,s5,4
    80003ed2:	02c9a783          	lw	a5,44(s3)
    80003ed6:	04fa5963          	bge	s4,a5,80003f28 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eda:	0189a583          	lw	a1,24(s3)
    80003ede:	014585bb          	addw	a1,a1,s4
    80003ee2:	2585                	addiw	a1,a1,1
    80003ee4:	0289a503          	lw	a0,40(s3)
    80003ee8:	fffff097          	auipc	ra,0xfffff
    80003eec:	f26080e7          	jalr	-218(ra) # 80002e0e <bread>
    80003ef0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ef2:	000aa583          	lw	a1,0(s5)
    80003ef6:	0289a503          	lw	a0,40(s3)
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	f14080e7          	jalr	-236(ra) # 80002e0e <bread>
    80003f02:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f04:	40000613          	li	a2,1024
    80003f08:	05890593          	addi	a1,s2,88
    80003f0c:	05850513          	addi	a0,a0,88
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	e30080e7          	jalr	-464(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f18:	8526                	mv	a0,s1
    80003f1a:	fffff097          	auipc	ra,0xfffff
    80003f1e:	fe6080e7          	jalr	-26(ra) # 80002f00 <bwrite>
    if(recovering == 0)
    80003f22:	f80b1ce3          	bnez	s6,80003eba <install_trans+0x40>
    80003f26:	b769                	j	80003eb0 <install_trans+0x36>
}
    80003f28:	70e2                	ld	ra,56(sp)
    80003f2a:	7442                	ld	s0,48(sp)
    80003f2c:	74a2                	ld	s1,40(sp)
    80003f2e:	7902                	ld	s2,32(sp)
    80003f30:	69e2                	ld	s3,24(sp)
    80003f32:	6a42                	ld	s4,16(sp)
    80003f34:	6aa2                	ld	s5,8(sp)
    80003f36:	6b02                	ld	s6,0(sp)
    80003f38:	6121                	addi	sp,sp,64
    80003f3a:	8082                	ret
    80003f3c:	8082                	ret

0000000080003f3e <initlog>:
{
    80003f3e:	7179                	addi	sp,sp,-48
    80003f40:	f406                	sd	ra,40(sp)
    80003f42:	f022                	sd	s0,32(sp)
    80003f44:	ec26                	sd	s1,24(sp)
    80003f46:	e84a                	sd	s2,16(sp)
    80003f48:	e44e                	sd	s3,8(sp)
    80003f4a:	1800                	addi	s0,sp,48
    80003f4c:	892a                	mv	s2,a0
    80003f4e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f50:	00020497          	auipc	s1,0x20
    80003f54:	32048493          	addi	s1,s1,800 # 80024270 <log>
    80003f58:	00004597          	auipc	a1,0x4
    80003f5c:	73858593          	addi	a1,a1,1848 # 80008690 <syscalls+0x1d8>
    80003f60:	8526                	mv	a0,s1
    80003f62:	ffffd097          	auipc	ra,0xffffd
    80003f66:	bf2080e7          	jalr	-1038(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80003f6a:	0149a583          	lw	a1,20(s3)
    80003f6e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f70:	0109a783          	lw	a5,16(s3)
    80003f74:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f76:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	fffff097          	auipc	ra,0xfffff
    80003f80:	e92080e7          	jalr	-366(ra) # 80002e0e <bread>
  log.lh.n = lh->n;
    80003f84:	4d3c                	lw	a5,88(a0)
    80003f86:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f88:	02f05563          	blez	a5,80003fb2 <initlog+0x74>
    80003f8c:	05c50713          	addi	a4,a0,92
    80003f90:	00020697          	auipc	a3,0x20
    80003f94:	31068693          	addi	a3,a3,784 # 800242a0 <log+0x30>
    80003f98:	37fd                	addiw	a5,a5,-1
    80003f9a:	1782                	slli	a5,a5,0x20
    80003f9c:	9381                	srli	a5,a5,0x20
    80003f9e:	078a                	slli	a5,a5,0x2
    80003fa0:	06050613          	addi	a2,a0,96
    80003fa4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003fa6:	4310                	lw	a2,0(a4)
    80003fa8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003faa:	0711                	addi	a4,a4,4
    80003fac:	0691                	addi	a3,a3,4
    80003fae:	fef71ce3          	bne	a4,a5,80003fa6 <initlog+0x68>
  brelse(buf);
    80003fb2:	fffff097          	auipc	ra,0xfffff
    80003fb6:	f8c080e7          	jalr	-116(ra) # 80002f3e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003fba:	4505                	li	a0,1
    80003fbc:	00000097          	auipc	ra,0x0
    80003fc0:	ebe080e7          	jalr	-322(ra) # 80003e7a <install_trans>
  log.lh.n = 0;
    80003fc4:	00020797          	auipc	a5,0x20
    80003fc8:	2c07ac23          	sw	zero,728(a5) # 8002429c <log+0x2c>
  write_head(); // clear the log
    80003fcc:	00000097          	auipc	ra,0x0
    80003fd0:	e34080e7          	jalr	-460(ra) # 80003e00 <write_head>
}
    80003fd4:	70a2                	ld	ra,40(sp)
    80003fd6:	7402                	ld	s0,32(sp)
    80003fd8:	64e2                	ld	s1,24(sp)
    80003fda:	6942                	ld	s2,16(sp)
    80003fdc:	69a2                	ld	s3,8(sp)
    80003fde:	6145                	addi	sp,sp,48
    80003fe0:	8082                	ret

0000000080003fe2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fe2:	1101                	addi	sp,sp,-32
    80003fe4:	ec06                	sd	ra,24(sp)
    80003fe6:	e822                	sd	s0,16(sp)
    80003fe8:	e426                	sd	s1,8(sp)
    80003fea:	e04a                	sd	s2,0(sp)
    80003fec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fee:	00020517          	auipc	a0,0x20
    80003ff2:	28250513          	addi	a0,a0,642 # 80024270 <log>
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	bee080e7          	jalr	-1042(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80003ffe:	00020497          	auipc	s1,0x20
    80004002:	27248493          	addi	s1,s1,626 # 80024270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004006:	4979                	li	s2,30
    80004008:	a039                	j	80004016 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000400a:	85a6                	mv	a1,s1
    8000400c:	8526                	mv	a0,s1
    8000400e:	ffffe097          	auipc	ra,0xffffe
    80004012:	0a0080e7          	jalr	160(ra) # 800020ae <sleep>
    if(log.committing){
    80004016:	50dc                	lw	a5,36(s1)
    80004018:	fbed                	bnez	a5,8000400a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000401a:	509c                	lw	a5,32(s1)
    8000401c:	0017871b          	addiw	a4,a5,1
    80004020:	0007069b          	sext.w	a3,a4
    80004024:	0027179b          	slliw	a5,a4,0x2
    80004028:	9fb9                	addw	a5,a5,a4
    8000402a:	0017979b          	slliw	a5,a5,0x1
    8000402e:	54d8                	lw	a4,44(s1)
    80004030:	9fb9                	addw	a5,a5,a4
    80004032:	00f95963          	bge	s2,a5,80004044 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004036:	85a6                	mv	a1,s1
    80004038:	8526                	mv	a0,s1
    8000403a:	ffffe097          	auipc	ra,0xffffe
    8000403e:	074080e7          	jalr	116(ra) # 800020ae <sleep>
    80004042:	bfd1                	j	80004016 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004044:	00020517          	auipc	a0,0x20
    80004048:	22c50513          	addi	a0,a0,556 # 80024270 <log>
    8000404c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000404e:	ffffd097          	auipc	ra,0xffffd
    80004052:	c4a080e7          	jalr	-950(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004056:	60e2                	ld	ra,24(sp)
    80004058:	6442                	ld	s0,16(sp)
    8000405a:	64a2                	ld	s1,8(sp)
    8000405c:	6902                	ld	s2,0(sp)
    8000405e:	6105                	addi	sp,sp,32
    80004060:	8082                	ret

0000000080004062 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	e852                	sd	s4,16(sp)
    80004070:	e456                	sd	s5,8(sp)
    80004072:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004074:	00020497          	auipc	s1,0x20
    80004078:	1fc48493          	addi	s1,s1,508 # 80024270 <log>
    8000407c:	8526                	mv	a0,s1
    8000407e:	ffffd097          	auipc	ra,0xffffd
    80004082:	b66080e7          	jalr	-1178(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004086:	509c                	lw	a5,32(s1)
    80004088:	37fd                	addiw	a5,a5,-1
    8000408a:	0007891b          	sext.w	s2,a5
    8000408e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004090:	50dc                	lw	a5,36(s1)
    80004092:	efb9                	bnez	a5,800040f0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004094:	06091663          	bnez	s2,80004100 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004098:	00020497          	auipc	s1,0x20
    8000409c:	1d848493          	addi	s1,s1,472 # 80024270 <log>
    800040a0:	4785                	li	a5,1
    800040a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040a4:	8526                	mv	a0,s1
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	bf2080e7          	jalr	-1038(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040ae:	54dc                	lw	a5,44(s1)
    800040b0:	06f04763          	bgtz	a5,8000411e <end_op+0xbc>
    acquire(&log.lock);
    800040b4:	00020497          	auipc	s1,0x20
    800040b8:	1bc48493          	addi	s1,s1,444 # 80024270 <log>
    800040bc:	8526                	mv	a0,s1
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	b26080e7          	jalr	-1242(ra) # 80000be4 <acquire>
    log.committing = 0;
    800040c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040ca:	8526                	mv	a0,s1
    800040cc:	ffffe097          	auipc	ra,0xffffe
    800040d0:	16e080e7          	jalr	366(ra) # 8000223a <wakeup>
    release(&log.lock);
    800040d4:	8526                	mv	a0,s1
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	bc2080e7          	jalr	-1086(ra) # 80000c98 <release>
}
    800040de:	70e2                	ld	ra,56(sp)
    800040e0:	7442                	ld	s0,48(sp)
    800040e2:	74a2                	ld	s1,40(sp)
    800040e4:	7902                	ld	s2,32(sp)
    800040e6:	69e2                	ld	s3,24(sp)
    800040e8:	6a42                	ld	s4,16(sp)
    800040ea:	6aa2                	ld	s5,8(sp)
    800040ec:	6121                	addi	sp,sp,64
    800040ee:	8082                	ret
    panic("log.committing");
    800040f0:	00004517          	auipc	a0,0x4
    800040f4:	5a850513          	addi	a0,a0,1448 # 80008698 <syscalls+0x1e0>
    800040f8:	ffffc097          	auipc	ra,0xffffc
    800040fc:	446080e7          	jalr	1094(ra) # 8000053e <panic>
    wakeup(&log);
    80004100:	00020497          	auipc	s1,0x20
    80004104:	17048493          	addi	s1,s1,368 # 80024270 <log>
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	130080e7          	jalr	304(ra) # 8000223a <wakeup>
  release(&log.lock);
    80004112:	8526                	mv	a0,s1
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	b84080e7          	jalr	-1148(ra) # 80000c98 <release>
  if(do_commit){
    8000411c:	b7c9                	j	800040de <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411e:	00020a97          	auipc	s5,0x20
    80004122:	182a8a93          	addi	s5,s5,386 # 800242a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004126:	00020a17          	auipc	s4,0x20
    8000412a:	14aa0a13          	addi	s4,s4,330 # 80024270 <log>
    8000412e:	018a2583          	lw	a1,24(s4)
    80004132:	012585bb          	addw	a1,a1,s2
    80004136:	2585                	addiw	a1,a1,1
    80004138:	028a2503          	lw	a0,40(s4)
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	cd2080e7          	jalr	-814(ra) # 80002e0e <bread>
    80004144:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004146:	000aa583          	lw	a1,0(s5)
    8000414a:	028a2503          	lw	a0,40(s4)
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	cc0080e7          	jalr	-832(ra) # 80002e0e <bread>
    80004156:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004158:	40000613          	li	a2,1024
    8000415c:	05850593          	addi	a1,a0,88
    80004160:	05848513          	addi	a0,s1,88
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	bdc080e7          	jalr	-1060(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000416c:	8526                	mv	a0,s1
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	d92080e7          	jalr	-622(ra) # 80002f00 <bwrite>
    brelse(from);
    80004176:	854e                	mv	a0,s3
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	dc6080e7          	jalr	-570(ra) # 80002f3e <brelse>
    brelse(to);
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	dbc080e7          	jalr	-580(ra) # 80002f3e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418a:	2905                	addiw	s2,s2,1
    8000418c:	0a91                	addi	s5,s5,4
    8000418e:	02ca2783          	lw	a5,44(s4)
    80004192:	f8f94ee3          	blt	s2,a5,8000412e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	c6a080e7          	jalr	-918(ra) # 80003e00 <write_head>
    install_trans(0); // Now install writes to home locations
    8000419e:	4501                	li	a0,0
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	cda080e7          	jalr	-806(ra) # 80003e7a <install_trans>
    log.lh.n = 0;
    800041a8:	00020797          	auipc	a5,0x20
    800041ac:	0e07aa23          	sw	zero,244(a5) # 8002429c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	c50080e7          	jalr	-944(ra) # 80003e00 <write_head>
    800041b8:	bdf5                	j	800040b4 <end_op+0x52>

00000000800041ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041ba:	1101                	addi	sp,sp,-32
    800041bc:	ec06                	sd	ra,24(sp)
    800041be:	e822                	sd	s0,16(sp)
    800041c0:	e426                	sd	s1,8(sp)
    800041c2:	e04a                	sd	s2,0(sp)
    800041c4:	1000                	addi	s0,sp,32
    800041c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041c8:	00020917          	auipc	s2,0x20
    800041cc:	0a890913          	addi	s2,s2,168 # 80024270 <log>
    800041d0:	854a                	mv	a0,s2
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	a12080e7          	jalr	-1518(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041da:	02c92603          	lw	a2,44(s2)
    800041de:	47f5                	li	a5,29
    800041e0:	06c7c563          	blt	a5,a2,8000424a <log_write+0x90>
    800041e4:	00020797          	auipc	a5,0x20
    800041e8:	0a87a783          	lw	a5,168(a5) # 8002428c <log+0x1c>
    800041ec:	37fd                	addiw	a5,a5,-1
    800041ee:	04f65e63          	bge	a2,a5,8000424a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041f2:	00020797          	auipc	a5,0x20
    800041f6:	09e7a783          	lw	a5,158(a5) # 80024290 <log+0x20>
    800041fa:	06f05063          	blez	a5,8000425a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041fe:	4781                	li	a5,0
    80004200:	06c05563          	blez	a2,8000426a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004204:	44cc                	lw	a1,12(s1)
    80004206:	00020717          	auipc	a4,0x20
    8000420a:	09a70713          	addi	a4,a4,154 # 800242a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000420e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004210:	4314                	lw	a3,0(a4)
    80004212:	04b68c63          	beq	a3,a1,8000426a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004216:	2785                	addiw	a5,a5,1
    80004218:	0711                	addi	a4,a4,4
    8000421a:	fef61be3          	bne	a2,a5,80004210 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000421e:	0621                	addi	a2,a2,8
    80004220:	060a                	slli	a2,a2,0x2
    80004222:	00020797          	auipc	a5,0x20
    80004226:	04e78793          	addi	a5,a5,78 # 80024270 <log>
    8000422a:	963e                	add	a2,a2,a5
    8000422c:	44dc                	lw	a5,12(s1)
    8000422e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	daa080e7          	jalr	-598(ra) # 80002fdc <bpin>
    log.lh.n++;
    8000423a:	00020717          	auipc	a4,0x20
    8000423e:	03670713          	addi	a4,a4,54 # 80024270 <log>
    80004242:	575c                	lw	a5,44(a4)
    80004244:	2785                	addiw	a5,a5,1
    80004246:	d75c                	sw	a5,44(a4)
    80004248:	a835                	j	80004284 <log_write+0xca>
    panic("too big a transaction");
    8000424a:	00004517          	auipc	a0,0x4
    8000424e:	45e50513          	addi	a0,a0,1118 # 800086a8 <syscalls+0x1f0>
    80004252:	ffffc097          	auipc	ra,0xffffc
    80004256:	2ec080e7          	jalr	748(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000425a:	00004517          	auipc	a0,0x4
    8000425e:	46650513          	addi	a0,a0,1126 # 800086c0 <syscalls+0x208>
    80004262:	ffffc097          	auipc	ra,0xffffc
    80004266:	2dc080e7          	jalr	732(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000426a:	00878713          	addi	a4,a5,8
    8000426e:	00271693          	slli	a3,a4,0x2
    80004272:	00020717          	auipc	a4,0x20
    80004276:	ffe70713          	addi	a4,a4,-2 # 80024270 <log>
    8000427a:	9736                	add	a4,a4,a3
    8000427c:	44d4                	lw	a3,12(s1)
    8000427e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004280:	faf608e3          	beq	a2,a5,80004230 <log_write+0x76>
  }
  release(&log.lock);
    80004284:	00020517          	auipc	a0,0x20
    80004288:	fec50513          	addi	a0,a0,-20 # 80024270 <log>
    8000428c:	ffffd097          	auipc	ra,0xffffd
    80004290:	a0c080e7          	jalr	-1524(ra) # 80000c98 <release>
}
    80004294:	60e2                	ld	ra,24(sp)
    80004296:	6442                	ld	s0,16(sp)
    80004298:	64a2                	ld	s1,8(sp)
    8000429a:	6902                	ld	s2,0(sp)
    8000429c:	6105                	addi	sp,sp,32
    8000429e:	8082                	ret

00000000800042a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	e426                	sd	s1,8(sp)
    800042a8:	e04a                	sd	s2,0(sp)
    800042aa:	1000                	addi	s0,sp,32
    800042ac:	84aa                	mv	s1,a0
    800042ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042b0:	00004597          	auipc	a1,0x4
    800042b4:	43058593          	addi	a1,a1,1072 # 800086e0 <syscalls+0x228>
    800042b8:	0521                	addi	a0,a0,8
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	89a080e7          	jalr	-1894(ra) # 80000b54 <initlock>
  lk->name = name;
    800042c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042ca:	0204a423          	sw	zero,40(s1)
}
    800042ce:	60e2                	ld	ra,24(sp)
    800042d0:	6442                	ld	s0,16(sp)
    800042d2:	64a2                	ld	s1,8(sp)
    800042d4:	6902                	ld	s2,0(sp)
    800042d6:	6105                	addi	sp,sp,32
    800042d8:	8082                	ret

00000000800042da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	e04a                	sd	s2,0(sp)
    800042e4:	1000                	addi	s0,sp,32
    800042e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042e8:	00850913          	addi	s2,a0,8
    800042ec:	854a                	mv	a0,s2
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	8f6080e7          	jalr	-1802(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800042f6:	409c                	lw	a5,0(s1)
    800042f8:	cb89                	beqz	a5,8000430a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042fa:	85ca                	mv	a1,s2
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffe097          	auipc	ra,0xffffe
    80004302:	db0080e7          	jalr	-592(ra) # 800020ae <sleep>
  while (lk->locked) {
    80004306:	409c                	lw	a5,0(s1)
    80004308:	fbed                	bnez	a5,800042fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000430a:	4785                	li	a5,1
    8000430c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	6e4080e7          	jalr	1764(ra) # 800019f2 <myproc>
    80004316:	591c                	lw	a5,48(a0)
    80004318:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000431a:	854a                	mv	a0,s2
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	97c080e7          	jalr	-1668(ra) # 80000c98 <release>
}
    80004324:	60e2                	ld	ra,24(sp)
    80004326:	6442                	ld	s0,16(sp)
    80004328:	64a2                	ld	s1,8(sp)
    8000432a:	6902                	ld	s2,0(sp)
    8000432c:	6105                	addi	sp,sp,32
    8000432e:	8082                	ret

0000000080004330 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004330:	1101                	addi	sp,sp,-32
    80004332:	ec06                	sd	ra,24(sp)
    80004334:	e822                	sd	s0,16(sp)
    80004336:	e426                	sd	s1,8(sp)
    80004338:	e04a                	sd	s2,0(sp)
    8000433a:	1000                	addi	s0,sp,32
    8000433c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000433e:	00850913          	addi	s2,a0,8
    80004342:	854a                	mv	a0,s2
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	8a0080e7          	jalr	-1888(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000434c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004350:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004354:	8526                	mv	a0,s1
    80004356:	ffffe097          	auipc	ra,0xffffe
    8000435a:	ee4080e7          	jalr	-284(ra) # 8000223a <wakeup>
  release(&lk->lk);
    8000435e:	854a                	mv	a0,s2
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6902                	ld	s2,0(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret

0000000080004374 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004374:	7179                	addi	sp,sp,-48
    80004376:	f406                	sd	ra,40(sp)
    80004378:	f022                	sd	s0,32(sp)
    8000437a:	ec26                	sd	s1,24(sp)
    8000437c:	e84a                	sd	s2,16(sp)
    8000437e:	e44e                	sd	s3,8(sp)
    80004380:	1800                	addi	s0,sp,48
    80004382:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004384:	00850913          	addi	s2,a0,8
    80004388:	854a                	mv	a0,s2
    8000438a:	ffffd097          	auipc	ra,0xffffd
    8000438e:	85a080e7          	jalr	-1958(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004392:	409c                	lw	a5,0(s1)
    80004394:	ef99                	bnez	a5,800043b2 <holdingsleep+0x3e>
    80004396:	4481                	li	s1,0
  release(&lk->lk);
    80004398:	854a                	mv	a0,s2
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	8fe080e7          	jalr	-1794(ra) # 80000c98 <release>
  return r;
}
    800043a2:	8526                	mv	a0,s1
    800043a4:	70a2                	ld	ra,40(sp)
    800043a6:	7402                	ld	s0,32(sp)
    800043a8:	64e2                	ld	s1,24(sp)
    800043aa:	6942                	ld	s2,16(sp)
    800043ac:	69a2                	ld	s3,8(sp)
    800043ae:	6145                	addi	sp,sp,48
    800043b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043b2:	0284a983          	lw	s3,40(s1)
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	63c080e7          	jalr	1596(ra) # 800019f2 <myproc>
    800043be:	5904                	lw	s1,48(a0)
    800043c0:	413484b3          	sub	s1,s1,s3
    800043c4:	0014b493          	seqz	s1,s1
    800043c8:	bfc1                	j	80004398 <holdingsleep+0x24>

00000000800043ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043ca:	1141                	addi	sp,sp,-16
    800043cc:	e406                	sd	ra,8(sp)
    800043ce:	e022                	sd	s0,0(sp)
    800043d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043d2:	00004597          	auipc	a1,0x4
    800043d6:	31e58593          	addi	a1,a1,798 # 800086f0 <syscalls+0x238>
    800043da:	00020517          	auipc	a0,0x20
    800043de:	fde50513          	addi	a0,a0,-34 # 800243b8 <ftable>
    800043e2:	ffffc097          	auipc	ra,0xffffc
    800043e6:	772080e7          	jalr	1906(ra) # 80000b54 <initlock>
}
    800043ea:	60a2                	ld	ra,8(sp)
    800043ec:	6402                	ld	s0,0(sp)
    800043ee:	0141                	addi	sp,sp,16
    800043f0:	8082                	ret

00000000800043f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043f2:	1101                	addi	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043fc:	00020517          	auipc	a0,0x20
    80004400:	fbc50513          	addi	a0,a0,-68 # 800243b8 <ftable>
    80004404:	ffffc097          	auipc	ra,0xffffc
    80004408:	7e0080e7          	jalr	2016(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000440c:	00020497          	auipc	s1,0x20
    80004410:	fc448493          	addi	s1,s1,-60 # 800243d0 <ftable+0x18>
    80004414:	00021717          	auipc	a4,0x21
    80004418:	f5c70713          	addi	a4,a4,-164 # 80025370 <ftable+0xfb8>
    if(f->ref == 0){
    8000441c:	40dc                	lw	a5,4(s1)
    8000441e:	cf99                	beqz	a5,8000443c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004420:	02848493          	addi	s1,s1,40
    80004424:	fee49ce3          	bne	s1,a4,8000441c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004428:	00020517          	auipc	a0,0x20
    8000442c:	f9050513          	addi	a0,a0,-112 # 800243b8 <ftable>
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
  return 0;
    80004438:	4481                	li	s1,0
    8000443a:	a819                	j	80004450 <filealloc+0x5e>
      f->ref = 1;
    8000443c:	4785                	li	a5,1
    8000443e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004440:	00020517          	auipc	a0,0x20
    80004444:	f7850513          	addi	a0,a0,-136 # 800243b8 <ftable>
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	850080e7          	jalr	-1968(ra) # 80000c98 <release>
}
    80004450:	8526                	mv	a0,s1
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6105                	addi	sp,sp,32
    8000445a:	8082                	ret

000000008000445c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000445c:	1101                	addi	sp,sp,-32
    8000445e:	ec06                	sd	ra,24(sp)
    80004460:	e822                	sd	s0,16(sp)
    80004462:	e426                	sd	s1,8(sp)
    80004464:	1000                	addi	s0,sp,32
    80004466:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004468:	00020517          	auipc	a0,0x20
    8000446c:	f5050513          	addi	a0,a0,-176 # 800243b8 <ftable>
    80004470:	ffffc097          	auipc	ra,0xffffc
    80004474:	774080e7          	jalr	1908(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004478:	40dc                	lw	a5,4(s1)
    8000447a:	02f05263          	blez	a5,8000449e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000447e:	2785                	addiw	a5,a5,1
    80004480:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004482:	00020517          	auipc	a0,0x20
    80004486:	f3650513          	addi	a0,a0,-202 # 800243b8 <ftable>
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	80e080e7          	jalr	-2034(ra) # 80000c98 <release>
  return f;
}
    80004492:	8526                	mv	a0,s1
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret
    panic("filedup");
    8000449e:	00004517          	auipc	a0,0x4
    800044a2:	25a50513          	addi	a0,a0,602 # 800086f8 <syscalls+0x240>
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	098080e7          	jalr	152(ra) # 8000053e <panic>

00000000800044ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044ae:	7139                	addi	sp,sp,-64
    800044b0:	fc06                	sd	ra,56(sp)
    800044b2:	f822                	sd	s0,48(sp)
    800044b4:	f426                	sd	s1,40(sp)
    800044b6:	f04a                	sd	s2,32(sp)
    800044b8:	ec4e                	sd	s3,24(sp)
    800044ba:	e852                	sd	s4,16(sp)
    800044bc:	e456                	sd	s5,8(sp)
    800044be:	0080                	addi	s0,sp,64
    800044c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044c2:	00020517          	auipc	a0,0x20
    800044c6:	ef650513          	addi	a0,a0,-266 # 800243b8 <ftable>
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	71a080e7          	jalr	1818(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800044d2:	40dc                	lw	a5,4(s1)
    800044d4:	06f05163          	blez	a5,80004536 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044d8:	37fd                	addiw	a5,a5,-1
    800044da:	0007871b          	sext.w	a4,a5
    800044de:	c0dc                	sw	a5,4(s1)
    800044e0:	06e04363          	bgtz	a4,80004546 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044e4:	0004a903          	lw	s2,0(s1)
    800044e8:	0094ca83          	lbu	s5,9(s1)
    800044ec:	0104ba03          	ld	s4,16(s1)
    800044f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044fc:	00020517          	auipc	a0,0x20
    80004500:	ebc50513          	addi	a0,a0,-324 # 800243b8 <ftable>
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	794080e7          	jalr	1940(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000450c:	4785                	li	a5,1
    8000450e:	04f90d63          	beq	s2,a5,80004568 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004512:	3979                	addiw	s2,s2,-2
    80004514:	4785                	li	a5,1
    80004516:	0527e063          	bltu	a5,s2,80004556 <fileclose+0xa8>
    begin_op();
    8000451a:	00000097          	auipc	ra,0x0
    8000451e:	ac8080e7          	jalr	-1336(ra) # 80003fe2 <begin_op>
    iput(ff.ip);
    80004522:	854e                	mv	a0,s3
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	2a6080e7          	jalr	678(ra) # 800037ca <iput>
    end_op();
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	b36080e7          	jalr	-1226(ra) # 80004062 <end_op>
    80004534:	a00d                	j	80004556 <fileclose+0xa8>
    panic("fileclose");
    80004536:	00004517          	auipc	a0,0x4
    8000453a:	1ca50513          	addi	a0,a0,458 # 80008700 <syscalls+0x248>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	000080e7          	jalr	ra # 8000053e <panic>
    release(&ftable.lock);
    80004546:	00020517          	auipc	a0,0x20
    8000454a:	e7250513          	addi	a0,a0,-398 # 800243b8 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	74a080e7          	jalr	1866(ra) # 80000c98 <release>
  }
}
    80004556:	70e2                	ld	ra,56(sp)
    80004558:	7442                	ld	s0,48(sp)
    8000455a:	74a2                	ld	s1,40(sp)
    8000455c:	7902                	ld	s2,32(sp)
    8000455e:	69e2                	ld	s3,24(sp)
    80004560:	6a42                	ld	s4,16(sp)
    80004562:	6aa2                	ld	s5,8(sp)
    80004564:	6121                	addi	sp,sp,64
    80004566:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004568:	85d6                	mv	a1,s5
    8000456a:	8552                	mv	a0,s4
    8000456c:	00000097          	auipc	ra,0x0
    80004570:	34c080e7          	jalr	844(ra) # 800048b8 <pipeclose>
    80004574:	b7cd                	j	80004556 <fileclose+0xa8>

0000000080004576 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004576:	715d                	addi	sp,sp,-80
    80004578:	e486                	sd	ra,72(sp)
    8000457a:	e0a2                	sd	s0,64(sp)
    8000457c:	fc26                	sd	s1,56(sp)
    8000457e:	f84a                	sd	s2,48(sp)
    80004580:	f44e                	sd	s3,40(sp)
    80004582:	0880                	addi	s0,sp,80
    80004584:	84aa                	mv	s1,a0
    80004586:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004588:	ffffd097          	auipc	ra,0xffffd
    8000458c:	46a080e7          	jalr	1130(ra) # 800019f2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004590:	409c                	lw	a5,0(s1)
    80004592:	37f9                	addiw	a5,a5,-2
    80004594:	4705                	li	a4,1
    80004596:	04f76763          	bltu	a4,a5,800045e4 <filestat+0x6e>
    8000459a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000459c:	6c88                	ld	a0,24(s1)
    8000459e:	fffff097          	auipc	ra,0xfffff
    800045a2:	072080e7          	jalr	114(ra) # 80003610 <ilock>
    stati(f->ip, &st);
    800045a6:	fb840593          	addi	a1,s0,-72
    800045aa:	6c88                	ld	a0,24(s1)
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	2ee080e7          	jalr	750(ra) # 8000389a <stati>
    iunlock(f->ip);
    800045b4:	6c88                	ld	a0,24(s1)
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	11c080e7          	jalr	284(ra) # 800036d2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045be:	46e1                	li	a3,24
    800045c0:	fb840613          	addi	a2,s0,-72
    800045c4:	85ce                	mv	a1,s3
    800045c6:	05093503          	ld	a0,80(s2)
    800045ca:	ffffd097          	auipc	ra,0xffffd
    800045ce:	0ea080e7          	jalr	234(ra) # 800016b4 <copyout>
    800045d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045d6:	60a6                	ld	ra,72(sp)
    800045d8:	6406                	ld	s0,64(sp)
    800045da:	74e2                	ld	s1,56(sp)
    800045dc:	7942                	ld	s2,48(sp)
    800045de:	79a2                	ld	s3,40(sp)
    800045e0:	6161                	addi	sp,sp,80
    800045e2:	8082                	ret
  return -1;
    800045e4:	557d                	li	a0,-1
    800045e6:	bfc5                	j	800045d6 <filestat+0x60>

00000000800045e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045e8:	7179                	addi	sp,sp,-48
    800045ea:	f406                	sd	ra,40(sp)
    800045ec:	f022                	sd	s0,32(sp)
    800045ee:	ec26                	sd	s1,24(sp)
    800045f0:	e84a                	sd	s2,16(sp)
    800045f2:	e44e                	sd	s3,8(sp)
    800045f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045f6:	00854783          	lbu	a5,8(a0)
    800045fa:	c3d5                	beqz	a5,8000469e <fileread+0xb6>
    800045fc:	84aa                	mv	s1,a0
    800045fe:	89ae                	mv	s3,a1
    80004600:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004602:	411c                	lw	a5,0(a0)
    80004604:	4705                	li	a4,1
    80004606:	04e78963          	beq	a5,a4,80004658 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000460a:	470d                	li	a4,3
    8000460c:	04e78d63          	beq	a5,a4,80004666 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004610:	4709                	li	a4,2
    80004612:	06e79e63          	bne	a5,a4,8000468e <fileread+0xa6>
    ilock(f->ip);
    80004616:	6d08                	ld	a0,24(a0)
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	ff8080e7          	jalr	-8(ra) # 80003610 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004620:	874a                	mv	a4,s2
    80004622:	5094                	lw	a3,32(s1)
    80004624:	864e                	mv	a2,s3
    80004626:	4585                	li	a1,1
    80004628:	6c88                	ld	a0,24(s1)
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	29a080e7          	jalr	666(ra) # 800038c4 <readi>
    80004632:	892a                	mv	s2,a0
    80004634:	00a05563          	blez	a0,8000463e <fileread+0x56>
      f->off += r;
    80004638:	509c                	lw	a5,32(s1)
    8000463a:	9fa9                	addw	a5,a5,a0
    8000463c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000463e:	6c88                	ld	a0,24(s1)
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	092080e7          	jalr	146(ra) # 800036d2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004648:	854a                	mv	a0,s2
    8000464a:	70a2                	ld	ra,40(sp)
    8000464c:	7402                	ld	s0,32(sp)
    8000464e:	64e2                	ld	s1,24(sp)
    80004650:	6942                	ld	s2,16(sp)
    80004652:	69a2                	ld	s3,8(sp)
    80004654:	6145                	addi	sp,sp,48
    80004656:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004658:	6908                	ld	a0,16(a0)
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	3c8080e7          	jalr	968(ra) # 80004a22 <piperead>
    80004662:	892a                	mv	s2,a0
    80004664:	b7d5                	j	80004648 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004666:	02451783          	lh	a5,36(a0)
    8000466a:	03079693          	slli	a3,a5,0x30
    8000466e:	92c1                	srli	a3,a3,0x30
    80004670:	4725                	li	a4,9
    80004672:	02d76863          	bltu	a4,a3,800046a2 <fileread+0xba>
    80004676:	0792                	slli	a5,a5,0x4
    80004678:	00020717          	auipc	a4,0x20
    8000467c:	ca070713          	addi	a4,a4,-864 # 80024318 <devsw>
    80004680:	97ba                	add	a5,a5,a4
    80004682:	639c                	ld	a5,0(a5)
    80004684:	c38d                	beqz	a5,800046a6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004686:	4505                	li	a0,1
    80004688:	9782                	jalr	a5
    8000468a:	892a                	mv	s2,a0
    8000468c:	bf75                	j	80004648 <fileread+0x60>
    panic("fileread");
    8000468e:	00004517          	auipc	a0,0x4
    80004692:	08250513          	addi	a0,a0,130 # 80008710 <syscalls+0x258>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	ea8080e7          	jalr	-344(ra) # 8000053e <panic>
    return -1;
    8000469e:	597d                	li	s2,-1
    800046a0:	b765                	j	80004648 <fileread+0x60>
      return -1;
    800046a2:	597d                	li	s2,-1
    800046a4:	b755                	j	80004648 <fileread+0x60>
    800046a6:	597d                	li	s2,-1
    800046a8:	b745                	j	80004648 <fileread+0x60>

00000000800046aa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800046aa:	715d                	addi	sp,sp,-80
    800046ac:	e486                	sd	ra,72(sp)
    800046ae:	e0a2                	sd	s0,64(sp)
    800046b0:	fc26                	sd	s1,56(sp)
    800046b2:	f84a                	sd	s2,48(sp)
    800046b4:	f44e                	sd	s3,40(sp)
    800046b6:	f052                	sd	s4,32(sp)
    800046b8:	ec56                	sd	s5,24(sp)
    800046ba:	e85a                	sd	s6,16(sp)
    800046bc:	e45e                	sd	s7,8(sp)
    800046be:	e062                	sd	s8,0(sp)
    800046c0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046c2:	00954783          	lbu	a5,9(a0)
    800046c6:	10078663          	beqz	a5,800047d2 <filewrite+0x128>
    800046ca:	892a                	mv	s2,a0
    800046cc:	8aae                	mv	s5,a1
    800046ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d0:	411c                	lw	a5,0(a0)
    800046d2:	4705                	li	a4,1
    800046d4:	02e78263          	beq	a5,a4,800046f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046d8:	470d                	li	a4,3
    800046da:	02e78663          	beq	a5,a4,80004706 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046de:	4709                	li	a4,2
    800046e0:	0ee79163          	bne	a5,a4,800047c2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046e4:	0ac05d63          	blez	a2,8000479e <filewrite+0xf4>
    int i = 0;
    800046e8:	4981                	li	s3,0
    800046ea:	6b05                	lui	s6,0x1
    800046ec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046f0:	6b85                	lui	s7,0x1
    800046f2:	c00b8b9b          	addiw	s7,s7,-1024
    800046f6:	a861                	j	8000478e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046f8:	6908                	ld	a0,16(a0)
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	22e080e7          	jalr	558(ra) # 80004928 <pipewrite>
    80004702:	8a2a                	mv	s4,a0
    80004704:	a045                	j	800047a4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004706:	02451783          	lh	a5,36(a0)
    8000470a:	03079693          	slli	a3,a5,0x30
    8000470e:	92c1                	srli	a3,a3,0x30
    80004710:	4725                	li	a4,9
    80004712:	0cd76263          	bltu	a4,a3,800047d6 <filewrite+0x12c>
    80004716:	0792                	slli	a5,a5,0x4
    80004718:	00020717          	auipc	a4,0x20
    8000471c:	c0070713          	addi	a4,a4,-1024 # 80024318 <devsw>
    80004720:	97ba                	add	a5,a5,a4
    80004722:	679c                	ld	a5,8(a5)
    80004724:	cbdd                	beqz	a5,800047da <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004726:	4505                	li	a0,1
    80004728:	9782                	jalr	a5
    8000472a:	8a2a                	mv	s4,a0
    8000472c:	a8a5                	j	800047a4 <filewrite+0xfa>
    8000472e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004732:	00000097          	auipc	ra,0x0
    80004736:	8b0080e7          	jalr	-1872(ra) # 80003fe2 <begin_op>
      ilock(f->ip);
    8000473a:	01893503          	ld	a0,24(s2)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	ed2080e7          	jalr	-302(ra) # 80003610 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004746:	8762                	mv	a4,s8
    80004748:	02092683          	lw	a3,32(s2)
    8000474c:	01598633          	add	a2,s3,s5
    80004750:	4585                	li	a1,1
    80004752:	01893503          	ld	a0,24(s2)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	266080e7          	jalr	614(ra) # 800039bc <writei>
    8000475e:	84aa                	mv	s1,a0
    80004760:	00a05763          	blez	a0,8000476e <filewrite+0xc4>
        f->off += r;
    80004764:	02092783          	lw	a5,32(s2)
    80004768:	9fa9                	addw	a5,a5,a0
    8000476a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000476e:	01893503          	ld	a0,24(s2)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	f60080e7          	jalr	-160(ra) # 800036d2 <iunlock>
      end_op();
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	8e8080e7          	jalr	-1816(ra) # 80004062 <end_op>

      if(r != n1){
    80004782:	009c1f63          	bne	s8,s1,800047a0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004786:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000478a:	0149db63          	bge	s3,s4,800047a0 <filewrite+0xf6>
      int n1 = n - i;
    8000478e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004792:	84be                	mv	s1,a5
    80004794:	2781                	sext.w	a5,a5
    80004796:	f8fb5ce3          	bge	s6,a5,8000472e <filewrite+0x84>
    8000479a:	84de                	mv	s1,s7
    8000479c:	bf49                	j	8000472e <filewrite+0x84>
    int i = 0;
    8000479e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800047a0:	013a1f63          	bne	s4,s3,800047be <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047a4:	8552                	mv	a0,s4
    800047a6:	60a6                	ld	ra,72(sp)
    800047a8:	6406                	ld	s0,64(sp)
    800047aa:	74e2                	ld	s1,56(sp)
    800047ac:	7942                	ld	s2,48(sp)
    800047ae:	79a2                	ld	s3,40(sp)
    800047b0:	7a02                	ld	s4,32(sp)
    800047b2:	6ae2                	ld	s5,24(sp)
    800047b4:	6b42                	ld	s6,16(sp)
    800047b6:	6ba2                	ld	s7,8(sp)
    800047b8:	6c02                	ld	s8,0(sp)
    800047ba:	6161                	addi	sp,sp,80
    800047bc:	8082                	ret
    ret = (i == n ? n : -1);
    800047be:	5a7d                	li	s4,-1
    800047c0:	b7d5                	j	800047a4 <filewrite+0xfa>
    panic("filewrite");
    800047c2:	00004517          	auipc	a0,0x4
    800047c6:	f5e50513          	addi	a0,a0,-162 # 80008720 <syscalls+0x268>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	d74080e7          	jalr	-652(ra) # 8000053e <panic>
    return -1;
    800047d2:	5a7d                	li	s4,-1
    800047d4:	bfc1                	j	800047a4 <filewrite+0xfa>
      return -1;
    800047d6:	5a7d                	li	s4,-1
    800047d8:	b7f1                	j	800047a4 <filewrite+0xfa>
    800047da:	5a7d                	li	s4,-1
    800047dc:	b7e1                	j	800047a4 <filewrite+0xfa>

00000000800047de <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047de:	7179                	addi	sp,sp,-48
    800047e0:	f406                	sd	ra,40(sp)
    800047e2:	f022                	sd	s0,32(sp)
    800047e4:	ec26                	sd	s1,24(sp)
    800047e6:	e84a                	sd	s2,16(sp)
    800047e8:	e44e                	sd	s3,8(sp)
    800047ea:	e052                	sd	s4,0(sp)
    800047ec:	1800                	addi	s0,sp,48
    800047ee:	84aa                	mv	s1,a0
    800047f0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047f2:	0005b023          	sd	zero,0(a1)
    800047f6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047fa:	00000097          	auipc	ra,0x0
    800047fe:	bf8080e7          	jalr	-1032(ra) # 800043f2 <filealloc>
    80004802:	e088                	sd	a0,0(s1)
    80004804:	c551                	beqz	a0,80004890 <pipealloc+0xb2>
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	bec080e7          	jalr	-1044(ra) # 800043f2 <filealloc>
    8000480e:	00aa3023          	sd	a0,0(s4)
    80004812:	c92d                	beqz	a0,80004884 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	2e0080e7          	jalr	736(ra) # 80000af4 <kalloc>
    8000481c:	892a                	mv	s2,a0
    8000481e:	c125                	beqz	a0,8000487e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004820:	4985                	li	s3,1
    80004822:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004826:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000482a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000482e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004832:	00004597          	auipc	a1,0x4
    80004836:	efe58593          	addi	a1,a1,-258 # 80008730 <syscalls+0x278>
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	31a080e7          	jalr	794(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004842:	609c                	ld	a5,0(s1)
    80004844:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004848:	609c                	ld	a5,0(s1)
    8000484a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000484e:	609c                	ld	a5,0(s1)
    80004850:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004854:	609c                	ld	a5,0(s1)
    80004856:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000485a:	000a3783          	ld	a5,0(s4)
    8000485e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004862:	000a3783          	ld	a5,0(s4)
    80004866:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000486a:	000a3783          	ld	a5,0(s4)
    8000486e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004872:	000a3783          	ld	a5,0(s4)
    80004876:	0127b823          	sd	s2,16(a5)
  return 0;
    8000487a:	4501                	li	a0,0
    8000487c:	a025                	j	800048a4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000487e:	6088                	ld	a0,0(s1)
    80004880:	e501                	bnez	a0,80004888 <pipealloc+0xaa>
    80004882:	a039                	j	80004890 <pipealloc+0xb2>
    80004884:	6088                	ld	a0,0(s1)
    80004886:	c51d                	beqz	a0,800048b4 <pipealloc+0xd6>
    fileclose(*f0);
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	c26080e7          	jalr	-986(ra) # 800044ae <fileclose>
  if(*f1)
    80004890:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004894:	557d                	li	a0,-1
  if(*f1)
    80004896:	c799                	beqz	a5,800048a4 <pipealloc+0xc6>
    fileclose(*f1);
    80004898:	853e                	mv	a0,a5
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	c14080e7          	jalr	-1004(ra) # 800044ae <fileclose>
  return -1;
    800048a2:	557d                	li	a0,-1
}
    800048a4:	70a2                	ld	ra,40(sp)
    800048a6:	7402                	ld	s0,32(sp)
    800048a8:	64e2                	ld	s1,24(sp)
    800048aa:	6942                	ld	s2,16(sp)
    800048ac:	69a2                	ld	s3,8(sp)
    800048ae:	6a02                	ld	s4,0(sp)
    800048b0:	6145                	addi	sp,sp,48
    800048b2:	8082                	ret
  return -1;
    800048b4:	557d                	li	a0,-1
    800048b6:	b7fd                	j	800048a4 <pipealloc+0xc6>

00000000800048b8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	e04a                	sd	s2,0(sp)
    800048c2:	1000                	addi	s0,sp,32
    800048c4:	84aa                	mv	s1,a0
    800048c6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  if(writable){
    800048d0:	02090d63          	beqz	s2,8000490a <pipeclose+0x52>
    pi->writeopen = 0;
    800048d4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048d8:	21848513          	addi	a0,s1,536
    800048dc:	ffffe097          	auipc	ra,0xffffe
    800048e0:	95e080e7          	jalr	-1698(ra) # 8000223a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048e4:	2204b783          	ld	a5,544(s1)
    800048e8:	eb95                	bnez	a5,8000491c <pipeclose+0x64>
    release(&pi->lock);
    800048ea:	8526                	mv	a0,s1
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
    kfree((char*)pi);
    800048f4:	8526                	mv	a0,s1
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	102080e7          	jalr	258(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800048fe:	60e2                	ld	ra,24(sp)
    80004900:	6442                	ld	s0,16(sp)
    80004902:	64a2                	ld	s1,8(sp)
    80004904:	6902                	ld	s2,0(sp)
    80004906:	6105                	addi	sp,sp,32
    80004908:	8082                	ret
    pi->readopen = 0;
    8000490a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000490e:	21c48513          	addi	a0,s1,540
    80004912:	ffffe097          	auipc	ra,0xffffe
    80004916:	928080e7          	jalr	-1752(ra) # 8000223a <wakeup>
    8000491a:	b7e9                	j	800048e4 <pipeclose+0x2c>
    release(&pi->lock);
    8000491c:	8526                	mv	a0,s1
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	37a080e7          	jalr	890(ra) # 80000c98 <release>
}
    80004926:	bfe1                	j	800048fe <pipeclose+0x46>

0000000080004928 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004928:	7159                	addi	sp,sp,-112
    8000492a:	f486                	sd	ra,104(sp)
    8000492c:	f0a2                	sd	s0,96(sp)
    8000492e:	eca6                	sd	s1,88(sp)
    80004930:	e8ca                	sd	s2,80(sp)
    80004932:	e4ce                	sd	s3,72(sp)
    80004934:	e0d2                	sd	s4,64(sp)
    80004936:	fc56                	sd	s5,56(sp)
    80004938:	f85a                	sd	s6,48(sp)
    8000493a:	f45e                	sd	s7,40(sp)
    8000493c:	f062                	sd	s8,32(sp)
    8000493e:	ec66                	sd	s9,24(sp)
    80004940:	1880                	addi	s0,sp,112
    80004942:	84aa                	mv	s1,a0
    80004944:	8aae                	mv	s5,a1
    80004946:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004948:	ffffd097          	auipc	ra,0xffffd
    8000494c:	0aa080e7          	jalr	170(ra) # 800019f2 <myproc>
    80004950:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004952:	8526                	mv	a0,s1
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
  while(i < n){
    8000495c:	0d405163          	blez	s4,80004a1e <pipewrite+0xf6>
    80004960:	8ba6                	mv	s7,s1
  int i = 0;
    80004962:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004964:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004966:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000496a:	21c48c13          	addi	s8,s1,540
    8000496e:	a08d                	j	800049d0 <pipewrite+0xa8>
      release(&pi->lock);
    80004970:	8526                	mv	a0,s1
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	326080e7          	jalr	806(ra) # 80000c98 <release>
      return -1;
    8000497a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000497c:	854a                	mv	a0,s2
    8000497e:	70a6                	ld	ra,104(sp)
    80004980:	7406                	ld	s0,96(sp)
    80004982:	64e6                	ld	s1,88(sp)
    80004984:	6946                	ld	s2,80(sp)
    80004986:	69a6                	ld	s3,72(sp)
    80004988:	6a06                	ld	s4,64(sp)
    8000498a:	7ae2                	ld	s5,56(sp)
    8000498c:	7b42                	ld	s6,48(sp)
    8000498e:	7ba2                	ld	s7,40(sp)
    80004990:	7c02                	ld	s8,32(sp)
    80004992:	6ce2                	ld	s9,24(sp)
    80004994:	6165                	addi	sp,sp,112
    80004996:	8082                	ret
      wakeup(&pi->nread);
    80004998:	8566                	mv	a0,s9
    8000499a:	ffffe097          	auipc	ra,0xffffe
    8000499e:	8a0080e7          	jalr	-1888(ra) # 8000223a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049a2:	85de                	mv	a1,s7
    800049a4:	8562                	mv	a0,s8
    800049a6:	ffffd097          	auipc	ra,0xffffd
    800049aa:	708080e7          	jalr	1800(ra) # 800020ae <sleep>
    800049ae:	a839                	j	800049cc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800049b0:	21c4a783          	lw	a5,540(s1)
    800049b4:	0017871b          	addiw	a4,a5,1
    800049b8:	20e4ae23          	sw	a4,540(s1)
    800049bc:	1ff7f793          	andi	a5,a5,511
    800049c0:	97a6                	add	a5,a5,s1
    800049c2:	f9f44703          	lbu	a4,-97(s0)
    800049c6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049ca:	2905                	addiw	s2,s2,1
  while(i < n){
    800049cc:	03495d63          	bge	s2,s4,80004a06 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800049d0:	2204a783          	lw	a5,544(s1)
    800049d4:	dfd1                	beqz	a5,80004970 <pipewrite+0x48>
    800049d6:	0289a783          	lw	a5,40(s3)
    800049da:	fbd9                	bnez	a5,80004970 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049dc:	2184a783          	lw	a5,536(s1)
    800049e0:	21c4a703          	lw	a4,540(s1)
    800049e4:	2007879b          	addiw	a5,a5,512
    800049e8:	faf708e3          	beq	a4,a5,80004998 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049ec:	4685                	li	a3,1
    800049ee:	01590633          	add	a2,s2,s5
    800049f2:	f9f40593          	addi	a1,s0,-97
    800049f6:	0509b503          	ld	a0,80(s3)
    800049fa:	ffffd097          	auipc	ra,0xffffd
    800049fe:	d46080e7          	jalr	-698(ra) # 80001740 <copyin>
    80004a02:	fb6517e3          	bne	a0,s6,800049b0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004a06:	21848513          	addi	a0,s1,536
    80004a0a:	ffffe097          	auipc	ra,0xffffe
    80004a0e:	830080e7          	jalr	-2000(ra) # 8000223a <wakeup>
  release(&pi->lock);
    80004a12:	8526                	mv	a0,s1
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	284080e7          	jalr	644(ra) # 80000c98 <release>
  return i;
    80004a1c:	b785                	j	8000497c <pipewrite+0x54>
  int i = 0;
    80004a1e:	4901                	li	s2,0
    80004a20:	b7dd                	j	80004a06 <pipewrite+0xde>

0000000080004a22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a22:	715d                	addi	sp,sp,-80
    80004a24:	e486                	sd	ra,72(sp)
    80004a26:	e0a2                	sd	s0,64(sp)
    80004a28:	fc26                	sd	s1,56(sp)
    80004a2a:	f84a                	sd	s2,48(sp)
    80004a2c:	f44e                	sd	s3,40(sp)
    80004a2e:	f052                	sd	s4,32(sp)
    80004a30:	ec56                	sd	s5,24(sp)
    80004a32:	e85a                	sd	s6,16(sp)
    80004a34:	0880                	addi	s0,sp,80
    80004a36:	84aa                	mv	s1,a0
    80004a38:	892e                	mv	s2,a1
    80004a3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a3c:	ffffd097          	auipc	ra,0xffffd
    80004a40:	fb6080e7          	jalr	-74(ra) # 800019f2 <myproc>
    80004a44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a46:	8b26                	mv	s6,s1
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	19a080e7          	jalr	410(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a52:	2184a703          	lw	a4,536(s1)
    80004a56:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a5a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a5e:	02f71463          	bne	a4,a5,80004a86 <piperead+0x64>
    80004a62:	2244a783          	lw	a5,548(s1)
    80004a66:	c385                	beqz	a5,80004a86 <piperead+0x64>
    if(pr->killed){
    80004a68:	028a2783          	lw	a5,40(s4)
    80004a6c:	ebc1                	bnez	a5,80004afc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a6e:	85da                	mv	a1,s6
    80004a70:	854e                	mv	a0,s3
    80004a72:	ffffd097          	auipc	ra,0xffffd
    80004a76:	63c080e7          	jalr	1596(ra) # 800020ae <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a7a:	2184a703          	lw	a4,536(s1)
    80004a7e:	21c4a783          	lw	a5,540(s1)
    80004a82:	fef700e3          	beq	a4,a5,80004a62 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a86:	09505263          	blez	s5,80004b0a <piperead+0xe8>
    80004a8a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a8c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004a8e:	2184a783          	lw	a5,536(s1)
    80004a92:	21c4a703          	lw	a4,540(s1)
    80004a96:	02f70d63          	beq	a4,a5,80004ad0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a9a:	0017871b          	addiw	a4,a5,1
    80004a9e:	20e4ac23          	sw	a4,536(s1)
    80004aa2:	1ff7f793          	andi	a5,a5,511
    80004aa6:	97a6                	add	a5,a5,s1
    80004aa8:	0187c783          	lbu	a5,24(a5)
    80004aac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ab0:	4685                	li	a3,1
    80004ab2:	fbf40613          	addi	a2,s0,-65
    80004ab6:	85ca                	mv	a1,s2
    80004ab8:	050a3503          	ld	a0,80(s4)
    80004abc:	ffffd097          	auipc	ra,0xffffd
    80004ac0:	bf8080e7          	jalr	-1032(ra) # 800016b4 <copyout>
    80004ac4:	01650663          	beq	a0,s6,80004ad0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ac8:	2985                	addiw	s3,s3,1
    80004aca:	0905                	addi	s2,s2,1
    80004acc:	fd3a91e3          	bne	s5,s3,80004a8e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ad0:	21c48513          	addi	a0,s1,540
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	766080e7          	jalr	1894(ra) # 8000223a <wakeup>
  release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ba080e7          	jalr	442(ra) # 80000c98 <release>
  return i;
}
    80004ae6:	854e                	mv	a0,s3
    80004ae8:	60a6                	ld	ra,72(sp)
    80004aea:	6406                	ld	s0,64(sp)
    80004aec:	74e2                	ld	s1,56(sp)
    80004aee:	7942                	ld	s2,48(sp)
    80004af0:	79a2                	ld	s3,40(sp)
    80004af2:	7a02                	ld	s4,32(sp)
    80004af4:	6ae2                	ld	s5,24(sp)
    80004af6:	6b42                	ld	s6,16(sp)
    80004af8:	6161                	addi	sp,sp,80
    80004afa:	8082                	ret
      release(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	19a080e7          	jalr	410(ra) # 80000c98 <release>
      return -1;
    80004b06:	59fd                	li	s3,-1
    80004b08:	bff9                	j	80004ae6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b0a:	4981                	li	s3,0
    80004b0c:	b7d1                	j	80004ad0 <piperead+0xae>

0000000080004b0e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004b0e:	df010113          	addi	sp,sp,-528
    80004b12:	20113423          	sd	ra,520(sp)
    80004b16:	20813023          	sd	s0,512(sp)
    80004b1a:	ffa6                	sd	s1,504(sp)
    80004b1c:	fbca                	sd	s2,496(sp)
    80004b1e:	f7ce                	sd	s3,488(sp)
    80004b20:	f3d2                	sd	s4,480(sp)
    80004b22:	efd6                	sd	s5,472(sp)
    80004b24:	ebda                	sd	s6,464(sp)
    80004b26:	e7de                	sd	s7,456(sp)
    80004b28:	e3e2                	sd	s8,448(sp)
    80004b2a:	ff66                	sd	s9,440(sp)
    80004b2c:	fb6a                	sd	s10,432(sp)
    80004b2e:	f76e                	sd	s11,424(sp)
    80004b30:	0c00                	addi	s0,sp,528
    80004b32:	84aa                	mv	s1,a0
    80004b34:	dea43c23          	sd	a0,-520(s0)
    80004b38:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	eb6080e7          	jalr	-330(ra) # 800019f2 <myproc>
    80004b44:	892a                	mv	s2,a0

  begin_op();
    80004b46:	fffff097          	auipc	ra,0xfffff
    80004b4a:	49c080e7          	jalr	1180(ra) # 80003fe2 <begin_op>

  if((ip = namei(path)) == 0){
    80004b4e:	8526                	mv	a0,s1
    80004b50:	fffff097          	auipc	ra,0xfffff
    80004b54:	276080e7          	jalr	630(ra) # 80003dc6 <namei>
    80004b58:	c92d                	beqz	a0,80004bca <exec+0xbc>
    80004b5a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b5c:	fffff097          	auipc	ra,0xfffff
    80004b60:	ab4080e7          	jalr	-1356(ra) # 80003610 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b64:	04000713          	li	a4,64
    80004b68:	4681                	li	a3,0
    80004b6a:	e5040613          	addi	a2,s0,-432
    80004b6e:	4581                	li	a1,0
    80004b70:	8526                	mv	a0,s1
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	d52080e7          	jalr	-686(ra) # 800038c4 <readi>
    80004b7a:	04000793          	li	a5,64
    80004b7e:	00f51a63          	bne	a0,a5,80004b92 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b82:	e5042703          	lw	a4,-432(s0)
    80004b86:	464c47b7          	lui	a5,0x464c4
    80004b8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b8e:	04f70463          	beq	a4,a5,80004bd6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b92:	8526                	mv	a0,s1
    80004b94:	fffff097          	auipc	ra,0xfffff
    80004b98:	cde080e7          	jalr	-802(ra) # 80003872 <iunlockput>
    end_op();
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	4c6080e7          	jalr	1222(ra) # 80004062 <end_op>
  }
  return -1;
    80004ba4:	557d                	li	a0,-1
}
    80004ba6:	20813083          	ld	ra,520(sp)
    80004baa:	20013403          	ld	s0,512(sp)
    80004bae:	74fe                	ld	s1,504(sp)
    80004bb0:	795e                	ld	s2,496(sp)
    80004bb2:	79be                	ld	s3,488(sp)
    80004bb4:	7a1e                	ld	s4,480(sp)
    80004bb6:	6afe                	ld	s5,472(sp)
    80004bb8:	6b5e                	ld	s6,464(sp)
    80004bba:	6bbe                	ld	s7,456(sp)
    80004bbc:	6c1e                	ld	s8,448(sp)
    80004bbe:	7cfa                	ld	s9,440(sp)
    80004bc0:	7d5a                	ld	s10,432(sp)
    80004bc2:	7dba                	ld	s11,424(sp)
    80004bc4:	21010113          	addi	sp,sp,528
    80004bc8:	8082                	ret
    end_op();
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	498080e7          	jalr	1176(ra) # 80004062 <end_op>
    return -1;
    80004bd2:	557d                	li	a0,-1
    80004bd4:	bfc9                	j	80004ba6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bd6:	854a                	mv	a0,s2
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	ede080e7          	jalr	-290(ra) # 80001ab6 <proc_pagetable>
    80004be0:	8baa                	mv	s7,a0
    80004be2:	d945                	beqz	a0,80004b92 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004be4:	e7042983          	lw	s3,-400(s0)
    80004be8:	e8845783          	lhu	a5,-376(s0)
    80004bec:	c7ad                	beqz	a5,80004c56 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004bee:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bf0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004bf2:	6c91                	lui	s9,0x4
    80004bf4:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004bf8:	def43823          	sd	a5,-528(s0)
    80004bfc:	a42d                	j	80004e26 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bfe:	00004517          	auipc	a0,0x4
    80004c02:	b3a50513          	addi	a0,a0,-1222 # 80008738 <syscalls+0x280>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	938080e7          	jalr	-1736(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004c0e:	8756                	mv	a4,s5
    80004c10:	012d86bb          	addw	a3,s11,s2
    80004c14:	4581                	li	a1,0
    80004c16:	8526                	mv	a0,s1
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	cac080e7          	jalr	-852(ra) # 800038c4 <readi>
    80004c20:	2501                	sext.w	a0,a0
    80004c22:	1aaa9963          	bne	s5,a0,80004dd4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c26:	6791                	lui	a5,0x4
    80004c28:	0127893b          	addw	s2,a5,s2
    80004c2c:	77f1                	lui	a5,0xffffc
    80004c2e:	01478a3b          	addw	s4,a5,s4
    80004c32:	1f897163          	bgeu	s2,s8,80004e14 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c36:	02091593          	slli	a1,s2,0x20
    80004c3a:	9181                	srli	a1,a1,0x20
    80004c3c:	95ea                	add	a1,a1,s10
    80004c3e:	855e                	mv	a0,s7
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	470080e7          	jalr	1136(ra) # 800010b0 <walkaddr>
    80004c48:	862a                	mv	a2,a0
    if(pa == 0)
    80004c4a:	d955                	beqz	a0,80004bfe <exec+0xf0>
      n = PGSIZE;
    80004c4c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c4e:	fd9a70e3          	bgeu	s4,s9,80004c0e <exec+0x100>
      n = sz - i;
    80004c52:	8ad2                	mv	s5,s4
    80004c54:	bf6d                	j	80004c0e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004c56:	4901                	li	s2,0
  iunlockput(ip);
    80004c58:	8526                	mv	a0,s1
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	c18080e7          	jalr	-1000(ra) # 80003872 <iunlockput>
  end_op();
    80004c62:	fffff097          	auipc	ra,0xfffff
    80004c66:	400080e7          	jalr	1024(ra) # 80004062 <end_op>
  p = myproc();
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	d88080e7          	jalr	-632(ra) # 800019f2 <myproc>
    80004c72:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c74:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c78:	6791                	lui	a5,0x4
    80004c7a:	17fd                	addi	a5,a5,-1
    80004c7c:	993e                	add	s2,s2,a5
    80004c7e:	7571                	lui	a0,0xffffc
    80004c80:	00a977b3          	and	a5,s2,a0
    80004c84:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c88:	6621                	lui	a2,0x8
    80004c8a:	963e                	add	a2,a2,a5
    80004c8c:	85be                	mv	a1,a5
    80004c8e:	855e                	mv	a0,s7
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	7d4080e7          	jalr	2004(ra) # 80001464 <uvmalloc>
    80004c98:	8b2a                	mv	s6,a0
  ip = 0;
    80004c9a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c9c:	12050c63          	beqz	a0,80004dd4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ca0:	75e1                	lui	a1,0xffff8
    80004ca2:	95aa                	add	a1,a1,a0
    80004ca4:	855e                	mv	a0,s7
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	9dc080e7          	jalr	-1572(ra) # 80001682 <uvmclear>
  stackbase = sp - PGSIZE;
    80004cae:	7c71                	lui	s8,0xffffc
    80004cb0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004cb2:	e0043783          	ld	a5,-512(s0)
    80004cb6:	6388                	ld	a0,0(a5)
    80004cb8:	c535                	beqz	a0,80004d24 <exec+0x216>
    80004cba:	e9040993          	addi	s3,s0,-368
    80004cbe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004cc2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	1a0080e7          	jalr	416(ra) # 80000e64 <strlen>
    80004ccc:	2505                	addiw	a0,a0,1
    80004cce:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cd2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cd6:	13896363          	bltu	s2,s8,80004dfc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cda:	e0043d83          	ld	s11,-512(s0)
    80004cde:	000dba03          	ld	s4,0(s11)
    80004ce2:	8552                	mv	a0,s4
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	180080e7          	jalr	384(ra) # 80000e64 <strlen>
    80004cec:	0015069b          	addiw	a3,a0,1
    80004cf0:	8652                	mv	a2,s4
    80004cf2:	85ca                	mv	a1,s2
    80004cf4:	855e                	mv	a0,s7
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	9be080e7          	jalr	-1602(ra) # 800016b4 <copyout>
    80004cfe:	10054363          	bltz	a0,80004e04 <exec+0x2f6>
    ustack[argc] = sp;
    80004d02:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004d06:	0485                	addi	s1,s1,1
    80004d08:	008d8793          	addi	a5,s11,8
    80004d0c:	e0f43023          	sd	a5,-512(s0)
    80004d10:	008db503          	ld	a0,8(s11)
    80004d14:	c911                	beqz	a0,80004d28 <exec+0x21a>
    if(argc >= MAXARG)
    80004d16:	09a1                	addi	s3,s3,8
    80004d18:	fb3c96e3          	bne	s9,s3,80004cc4 <exec+0x1b6>
  sz = sz1;
    80004d1c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d20:	4481                	li	s1,0
    80004d22:	a84d                	j	80004dd4 <exec+0x2c6>
  sp = sz;
    80004d24:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d26:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d28:	00349793          	slli	a5,s1,0x3
    80004d2c:	f9040713          	addi	a4,s0,-112
    80004d30:	97ba                	add	a5,a5,a4
    80004d32:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004d36:	00148693          	addi	a3,s1,1
    80004d3a:	068e                	slli	a3,a3,0x3
    80004d3c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d40:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d44:	01897663          	bgeu	s2,s8,80004d50 <exec+0x242>
  sz = sz1;
    80004d48:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d4c:	4481                	li	s1,0
    80004d4e:	a059                	j	80004dd4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d50:	e9040613          	addi	a2,s0,-368
    80004d54:	85ca                	mv	a1,s2
    80004d56:	855e                	mv	a0,s7
    80004d58:	ffffd097          	auipc	ra,0xffffd
    80004d5c:	95c080e7          	jalr	-1700(ra) # 800016b4 <copyout>
    80004d60:	0a054663          	bltz	a0,80004e0c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d64:	058ab783          	ld	a5,88(s5)
    80004d68:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d6c:	df843783          	ld	a5,-520(s0)
    80004d70:	0007c703          	lbu	a4,0(a5)
    80004d74:	cf11                	beqz	a4,80004d90 <exec+0x282>
    80004d76:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d78:	02f00693          	li	a3,47
    80004d7c:	a039                	j	80004d8a <exec+0x27c>
      last = s+1;
    80004d7e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004d82:	0785                	addi	a5,a5,1
    80004d84:	fff7c703          	lbu	a4,-1(a5)
    80004d88:	c701                	beqz	a4,80004d90 <exec+0x282>
    if(*s == '/')
    80004d8a:	fed71ce3          	bne	a4,a3,80004d82 <exec+0x274>
    80004d8e:	bfc5                	j	80004d7e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d90:	4641                	li	a2,16
    80004d92:	df843583          	ld	a1,-520(s0)
    80004d96:	158a8513          	addi	a0,s5,344
    80004d9a:	ffffc097          	auipc	ra,0xffffc
    80004d9e:	098080e7          	jalr	152(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004da2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004da6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004daa:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004dae:	058ab783          	ld	a5,88(s5)
    80004db2:	e6843703          	ld	a4,-408(s0)
    80004db6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004db8:	058ab783          	ld	a5,88(s5)
    80004dbc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004dc0:	85ea                	mv	a1,s10
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	d90080e7          	jalr	-624(ra) # 80001b52 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004dca:	0004851b          	sext.w	a0,s1
    80004dce:	bbe1                	j	80004ba6 <exec+0x98>
    80004dd0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004dd4:	e0843583          	ld	a1,-504(s0)
    80004dd8:	855e                	mv	a0,s7
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	d78080e7          	jalr	-648(ra) # 80001b52 <proc_freepagetable>
  if(ip){
    80004de2:	da0498e3          	bnez	s1,80004b92 <exec+0x84>
  return -1;
    80004de6:	557d                	li	a0,-1
    80004de8:	bb7d                	j	80004ba6 <exec+0x98>
    80004dea:	e1243423          	sd	s2,-504(s0)
    80004dee:	b7dd                	j	80004dd4 <exec+0x2c6>
    80004df0:	e1243423          	sd	s2,-504(s0)
    80004df4:	b7c5                	j	80004dd4 <exec+0x2c6>
    80004df6:	e1243423          	sd	s2,-504(s0)
    80004dfa:	bfe9                	j	80004dd4 <exec+0x2c6>
  sz = sz1;
    80004dfc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e00:	4481                	li	s1,0
    80004e02:	bfc9                	j	80004dd4 <exec+0x2c6>
  sz = sz1;
    80004e04:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e08:	4481                	li	s1,0
    80004e0a:	b7e9                	j	80004dd4 <exec+0x2c6>
  sz = sz1;
    80004e0c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e10:	4481                	li	s1,0
    80004e12:	b7c9                	j	80004dd4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e14:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e18:	2b05                	addiw	s6,s6,1
    80004e1a:	0389899b          	addiw	s3,s3,56
    80004e1e:	e8845783          	lhu	a5,-376(s0)
    80004e22:	e2fb5be3          	bge	s6,a5,80004c58 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e26:	2981                	sext.w	s3,s3
    80004e28:	03800713          	li	a4,56
    80004e2c:	86ce                	mv	a3,s3
    80004e2e:	e1840613          	addi	a2,s0,-488
    80004e32:	4581                	li	a1,0
    80004e34:	8526                	mv	a0,s1
    80004e36:	fffff097          	auipc	ra,0xfffff
    80004e3a:	a8e080e7          	jalr	-1394(ra) # 800038c4 <readi>
    80004e3e:	03800793          	li	a5,56
    80004e42:	f8f517e3          	bne	a0,a5,80004dd0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e46:	e1842783          	lw	a5,-488(s0)
    80004e4a:	4705                	li	a4,1
    80004e4c:	fce796e3          	bne	a5,a4,80004e18 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e50:	e4043603          	ld	a2,-448(s0)
    80004e54:	e3843783          	ld	a5,-456(s0)
    80004e58:	f8f669e3          	bltu	a2,a5,80004dea <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e5c:	e2843783          	ld	a5,-472(s0)
    80004e60:	963e                	add	a2,a2,a5
    80004e62:	f8f667e3          	bltu	a2,a5,80004df0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e66:	85ca                	mv	a1,s2
    80004e68:	855e                	mv	a0,s7
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	5fa080e7          	jalr	1530(ra) # 80001464 <uvmalloc>
    80004e72:	e0a43423          	sd	a0,-504(s0)
    80004e76:	d141                	beqz	a0,80004df6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004e78:	e2843d03          	ld	s10,-472(s0)
    80004e7c:	df043783          	ld	a5,-528(s0)
    80004e80:	00fd77b3          	and	a5,s10,a5
    80004e84:	fba1                	bnez	a5,80004dd4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e86:	e2042d83          	lw	s11,-480(s0)
    80004e8a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e8e:	f80c03e3          	beqz	s8,80004e14 <exec+0x306>
    80004e92:	8a62                	mv	s4,s8
    80004e94:	4901                	li	s2,0
    80004e96:	b345                	j	80004c36 <exec+0x128>

0000000080004e98 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e98:	7179                	addi	sp,sp,-48
    80004e9a:	f406                	sd	ra,40(sp)
    80004e9c:	f022                	sd	s0,32(sp)
    80004e9e:	ec26                	sd	s1,24(sp)
    80004ea0:	e84a                	sd	s2,16(sp)
    80004ea2:	1800                	addi	s0,sp,48
    80004ea4:	892e                	mv	s2,a1
    80004ea6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ea8:	fdc40593          	addi	a1,s0,-36
    80004eac:	ffffe097          	auipc	ra,0xffffe
    80004eb0:	bf2080e7          	jalr	-1038(ra) # 80002a9e <argint>
    80004eb4:	04054063          	bltz	a0,80004ef4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004eb8:	fdc42703          	lw	a4,-36(s0)
    80004ebc:	47bd                	li	a5,15
    80004ebe:	02e7ed63          	bltu	a5,a4,80004ef8 <argfd+0x60>
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	b30080e7          	jalr	-1232(ra) # 800019f2 <myproc>
    80004eca:	fdc42703          	lw	a4,-36(s0)
    80004ece:	01a70793          	addi	a5,a4,26
    80004ed2:	078e                	slli	a5,a5,0x3
    80004ed4:	953e                	add	a0,a0,a5
    80004ed6:	611c                	ld	a5,0(a0)
    80004ed8:	c395                	beqz	a5,80004efc <argfd+0x64>
    return -1;
  if(pfd)
    80004eda:	00090463          	beqz	s2,80004ee2 <argfd+0x4a>
    *pfd = fd;
    80004ede:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ee2:	4501                	li	a0,0
  if(pf)
    80004ee4:	c091                	beqz	s1,80004ee8 <argfd+0x50>
    *pf = f;
    80004ee6:	e09c                	sd	a5,0(s1)
}
    80004ee8:	70a2                	ld	ra,40(sp)
    80004eea:	7402                	ld	s0,32(sp)
    80004eec:	64e2                	ld	s1,24(sp)
    80004eee:	6942                	ld	s2,16(sp)
    80004ef0:	6145                	addi	sp,sp,48
    80004ef2:	8082                	ret
    return -1;
    80004ef4:	557d                	li	a0,-1
    80004ef6:	bfcd                	j	80004ee8 <argfd+0x50>
    return -1;
    80004ef8:	557d                	li	a0,-1
    80004efa:	b7fd                	j	80004ee8 <argfd+0x50>
    80004efc:	557d                	li	a0,-1
    80004efe:	b7ed                	j	80004ee8 <argfd+0x50>

0000000080004f00 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004f00:	1101                	addi	sp,sp,-32
    80004f02:	ec06                	sd	ra,24(sp)
    80004f04:	e822                	sd	s0,16(sp)
    80004f06:	e426                	sd	s1,8(sp)
    80004f08:	1000                	addi	s0,sp,32
    80004f0a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	ae6080e7          	jalr	-1306(ra) # 800019f2 <myproc>
    80004f14:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004f16:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc80d0>
    80004f1a:	4501                	li	a0,0
    80004f1c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f1e:	6398                	ld	a4,0(a5)
    80004f20:	cb19                	beqz	a4,80004f36 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f22:	2505                	addiw	a0,a0,1
    80004f24:	07a1                	addi	a5,a5,8
    80004f26:	fed51ce3          	bne	a0,a3,80004f1e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f2a:	557d                	li	a0,-1
}
    80004f2c:	60e2                	ld	ra,24(sp)
    80004f2e:	6442                	ld	s0,16(sp)
    80004f30:	64a2                	ld	s1,8(sp)
    80004f32:	6105                	addi	sp,sp,32
    80004f34:	8082                	ret
      p->ofile[fd] = f;
    80004f36:	01a50793          	addi	a5,a0,26
    80004f3a:	078e                	slli	a5,a5,0x3
    80004f3c:	963e                	add	a2,a2,a5
    80004f3e:	e204                	sd	s1,0(a2)
      return fd;
    80004f40:	b7f5                	j	80004f2c <fdalloc+0x2c>

0000000080004f42 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f42:	715d                	addi	sp,sp,-80
    80004f44:	e486                	sd	ra,72(sp)
    80004f46:	e0a2                	sd	s0,64(sp)
    80004f48:	fc26                	sd	s1,56(sp)
    80004f4a:	f84a                	sd	s2,48(sp)
    80004f4c:	f44e                	sd	s3,40(sp)
    80004f4e:	f052                	sd	s4,32(sp)
    80004f50:	ec56                	sd	s5,24(sp)
    80004f52:	0880                	addi	s0,sp,80
    80004f54:	89ae                	mv	s3,a1
    80004f56:	8ab2                	mv	s5,a2
    80004f58:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f5a:	fb040593          	addi	a1,s0,-80
    80004f5e:	fffff097          	auipc	ra,0xfffff
    80004f62:	e86080e7          	jalr	-378(ra) # 80003de4 <nameiparent>
    80004f66:	892a                	mv	s2,a0
    80004f68:	12050f63          	beqz	a0,800050a6 <create+0x164>
    return 0;

  ilock(dp);
    80004f6c:	ffffe097          	auipc	ra,0xffffe
    80004f70:	6a4080e7          	jalr	1700(ra) # 80003610 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f74:	4601                	li	a2,0
    80004f76:	fb040593          	addi	a1,s0,-80
    80004f7a:	854a                	mv	a0,s2
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	b78080e7          	jalr	-1160(ra) # 80003af4 <dirlookup>
    80004f84:	84aa                	mv	s1,a0
    80004f86:	c921                	beqz	a0,80004fd6 <create+0x94>
    iunlockput(dp);
    80004f88:	854a                	mv	a0,s2
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	8e8080e7          	jalr	-1816(ra) # 80003872 <iunlockput>
    ilock(ip);
    80004f92:	8526                	mv	a0,s1
    80004f94:	ffffe097          	auipc	ra,0xffffe
    80004f98:	67c080e7          	jalr	1660(ra) # 80003610 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f9c:	2981                	sext.w	s3,s3
    80004f9e:	4789                	li	a5,2
    80004fa0:	02f99463          	bne	s3,a5,80004fc8 <create+0x86>
    80004fa4:	0444d783          	lhu	a5,68(s1)
    80004fa8:	37f9                	addiw	a5,a5,-2
    80004faa:	17c2                	slli	a5,a5,0x30
    80004fac:	93c1                	srli	a5,a5,0x30
    80004fae:	4705                	li	a4,1
    80004fb0:	00f76c63          	bltu	a4,a5,80004fc8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	60a6                	ld	ra,72(sp)
    80004fb8:	6406                	ld	s0,64(sp)
    80004fba:	74e2                	ld	s1,56(sp)
    80004fbc:	7942                	ld	s2,48(sp)
    80004fbe:	79a2                	ld	s3,40(sp)
    80004fc0:	7a02                	ld	s4,32(sp)
    80004fc2:	6ae2                	ld	s5,24(sp)
    80004fc4:	6161                	addi	sp,sp,80
    80004fc6:	8082                	ret
    iunlockput(ip);
    80004fc8:	8526                	mv	a0,s1
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	8a8080e7          	jalr	-1880(ra) # 80003872 <iunlockput>
    return 0;
    80004fd2:	4481                	li	s1,0
    80004fd4:	b7c5                	j	80004fb4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fd6:	85ce                	mv	a1,s3
    80004fd8:	00092503          	lw	a0,0(s2)
    80004fdc:	ffffe097          	auipc	ra,0xffffe
    80004fe0:	49c080e7          	jalr	1180(ra) # 80003478 <ialloc>
    80004fe4:	84aa                	mv	s1,a0
    80004fe6:	c529                	beqz	a0,80005030 <create+0xee>
  ilock(ip);
    80004fe8:	ffffe097          	auipc	ra,0xffffe
    80004fec:	628080e7          	jalr	1576(ra) # 80003610 <ilock>
  ip->major = major;
    80004ff0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004ff4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004ff8:	4785                	li	a5,1
    80004ffa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffe097          	auipc	ra,0xffffe
    80005004:	546080e7          	jalr	1350(ra) # 80003546 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005008:	2981                	sext.w	s3,s3
    8000500a:	4785                	li	a5,1
    8000500c:	02f98a63          	beq	s3,a5,80005040 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005010:	40d0                	lw	a2,4(s1)
    80005012:	fb040593          	addi	a1,s0,-80
    80005016:	854a                	mv	a0,s2
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	cec080e7          	jalr	-788(ra) # 80003d04 <dirlink>
    80005020:	06054b63          	bltz	a0,80005096 <create+0x154>
  iunlockput(dp);
    80005024:	854a                	mv	a0,s2
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	84c080e7          	jalr	-1972(ra) # 80003872 <iunlockput>
  return ip;
    8000502e:	b759                	j	80004fb4 <create+0x72>
    panic("create: ialloc");
    80005030:	00003517          	auipc	a0,0x3
    80005034:	72850513          	addi	a0,a0,1832 # 80008758 <syscalls+0x2a0>
    80005038:	ffffb097          	auipc	ra,0xffffb
    8000503c:	506080e7          	jalr	1286(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005040:	04a95783          	lhu	a5,74(s2)
    80005044:	2785                	addiw	a5,a5,1
    80005046:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000504a:	854a                	mv	a0,s2
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	4fa080e7          	jalr	1274(ra) # 80003546 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005054:	40d0                	lw	a2,4(s1)
    80005056:	00003597          	auipc	a1,0x3
    8000505a:	71258593          	addi	a1,a1,1810 # 80008768 <syscalls+0x2b0>
    8000505e:	8526                	mv	a0,s1
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	ca4080e7          	jalr	-860(ra) # 80003d04 <dirlink>
    80005068:	00054f63          	bltz	a0,80005086 <create+0x144>
    8000506c:	00492603          	lw	a2,4(s2)
    80005070:	00003597          	auipc	a1,0x3
    80005074:	70058593          	addi	a1,a1,1792 # 80008770 <syscalls+0x2b8>
    80005078:	8526                	mv	a0,s1
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	c8a080e7          	jalr	-886(ra) # 80003d04 <dirlink>
    80005082:	f80557e3          	bgez	a0,80005010 <create+0xce>
      panic("create dots");
    80005086:	00003517          	auipc	a0,0x3
    8000508a:	6f250513          	addi	a0,a0,1778 # 80008778 <syscalls+0x2c0>
    8000508e:	ffffb097          	auipc	ra,0xffffb
    80005092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005096:	00003517          	auipc	a0,0x3
    8000509a:	6f250513          	addi	a0,a0,1778 # 80008788 <syscalls+0x2d0>
    8000509e:	ffffb097          	auipc	ra,0xffffb
    800050a2:	4a0080e7          	jalr	1184(ra) # 8000053e <panic>
    return 0;
    800050a6:	84aa                	mv	s1,a0
    800050a8:	b731                	j	80004fb4 <create+0x72>

00000000800050aa <sys_dup>:
{
    800050aa:	7179                	addi	sp,sp,-48
    800050ac:	f406                	sd	ra,40(sp)
    800050ae:	f022                	sd	s0,32(sp)
    800050b0:	ec26                	sd	s1,24(sp)
    800050b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800050b4:	fd840613          	addi	a2,s0,-40
    800050b8:	4581                	li	a1,0
    800050ba:	4501                	li	a0,0
    800050bc:	00000097          	auipc	ra,0x0
    800050c0:	ddc080e7          	jalr	-548(ra) # 80004e98 <argfd>
    return -1;
    800050c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050c6:	02054363          	bltz	a0,800050ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050ca:	fd843503          	ld	a0,-40(s0)
    800050ce:	00000097          	auipc	ra,0x0
    800050d2:	e32080e7          	jalr	-462(ra) # 80004f00 <fdalloc>
    800050d6:	84aa                	mv	s1,a0
    return -1;
    800050d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050da:	00054963          	bltz	a0,800050ec <sys_dup+0x42>
  filedup(f);
    800050de:	fd843503          	ld	a0,-40(s0)
    800050e2:	fffff097          	auipc	ra,0xfffff
    800050e6:	37a080e7          	jalr	890(ra) # 8000445c <filedup>
  return fd;
    800050ea:	87a6                	mv	a5,s1
}
    800050ec:	853e                	mv	a0,a5
    800050ee:	70a2                	ld	ra,40(sp)
    800050f0:	7402                	ld	s0,32(sp)
    800050f2:	64e2                	ld	s1,24(sp)
    800050f4:	6145                	addi	sp,sp,48
    800050f6:	8082                	ret

00000000800050f8 <sys_read>:
{
    800050f8:	7179                	addi	sp,sp,-48
    800050fa:	f406                	sd	ra,40(sp)
    800050fc:	f022                	sd	s0,32(sp)
    800050fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005100:	fe840613          	addi	a2,s0,-24
    80005104:	4581                	li	a1,0
    80005106:	4501                	li	a0,0
    80005108:	00000097          	auipc	ra,0x0
    8000510c:	d90080e7          	jalr	-624(ra) # 80004e98 <argfd>
    return -1;
    80005110:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005112:	04054163          	bltz	a0,80005154 <sys_read+0x5c>
    80005116:	fe440593          	addi	a1,s0,-28
    8000511a:	4509                	li	a0,2
    8000511c:	ffffe097          	auipc	ra,0xffffe
    80005120:	982080e7          	jalr	-1662(ra) # 80002a9e <argint>
    return -1;
    80005124:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005126:	02054763          	bltz	a0,80005154 <sys_read+0x5c>
    8000512a:	fd840593          	addi	a1,s0,-40
    8000512e:	4505                	li	a0,1
    80005130:	ffffe097          	auipc	ra,0xffffe
    80005134:	990080e7          	jalr	-1648(ra) # 80002ac0 <argaddr>
    return -1;
    80005138:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000513a:	00054d63          	bltz	a0,80005154 <sys_read+0x5c>
  return fileread(f, p, n);
    8000513e:	fe442603          	lw	a2,-28(s0)
    80005142:	fd843583          	ld	a1,-40(s0)
    80005146:	fe843503          	ld	a0,-24(s0)
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	49e080e7          	jalr	1182(ra) # 800045e8 <fileread>
    80005152:	87aa                	mv	a5,a0
}
    80005154:	853e                	mv	a0,a5
    80005156:	70a2                	ld	ra,40(sp)
    80005158:	7402                	ld	s0,32(sp)
    8000515a:	6145                	addi	sp,sp,48
    8000515c:	8082                	ret

000000008000515e <sys_write>:
{
    8000515e:	7179                	addi	sp,sp,-48
    80005160:	f406                	sd	ra,40(sp)
    80005162:	f022                	sd	s0,32(sp)
    80005164:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005166:	fe840613          	addi	a2,s0,-24
    8000516a:	4581                	li	a1,0
    8000516c:	4501                	li	a0,0
    8000516e:	00000097          	auipc	ra,0x0
    80005172:	d2a080e7          	jalr	-726(ra) # 80004e98 <argfd>
    return -1;
    80005176:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005178:	04054163          	bltz	a0,800051ba <sys_write+0x5c>
    8000517c:	fe440593          	addi	a1,s0,-28
    80005180:	4509                	li	a0,2
    80005182:	ffffe097          	auipc	ra,0xffffe
    80005186:	91c080e7          	jalr	-1764(ra) # 80002a9e <argint>
    return -1;
    8000518a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000518c:	02054763          	bltz	a0,800051ba <sys_write+0x5c>
    80005190:	fd840593          	addi	a1,s0,-40
    80005194:	4505                	li	a0,1
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	92a080e7          	jalr	-1750(ra) # 80002ac0 <argaddr>
    return -1;
    8000519e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a0:	00054d63          	bltz	a0,800051ba <sys_write+0x5c>
  return filewrite(f, p, n);
    800051a4:	fe442603          	lw	a2,-28(s0)
    800051a8:	fd843583          	ld	a1,-40(s0)
    800051ac:	fe843503          	ld	a0,-24(s0)
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	4fa080e7          	jalr	1274(ra) # 800046aa <filewrite>
    800051b8:	87aa                	mv	a5,a0
}
    800051ba:	853e                	mv	a0,a5
    800051bc:	70a2                	ld	ra,40(sp)
    800051be:	7402                	ld	s0,32(sp)
    800051c0:	6145                	addi	sp,sp,48
    800051c2:	8082                	ret

00000000800051c4 <sys_close>:
{
    800051c4:	1101                	addi	sp,sp,-32
    800051c6:	ec06                	sd	ra,24(sp)
    800051c8:	e822                	sd	s0,16(sp)
    800051ca:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051cc:	fe040613          	addi	a2,s0,-32
    800051d0:	fec40593          	addi	a1,s0,-20
    800051d4:	4501                	li	a0,0
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	cc2080e7          	jalr	-830(ra) # 80004e98 <argfd>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051e0:	02054463          	bltz	a0,80005208 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	80e080e7          	jalr	-2034(ra) # 800019f2 <myproc>
    800051ec:	fec42783          	lw	a5,-20(s0)
    800051f0:	07e9                	addi	a5,a5,26
    800051f2:	078e                	slli	a5,a5,0x3
    800051f4:	97aa                	add	a5,a5,a0
    800051f6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051fa:	fe043503          	ld	a0,-32(s0)
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	2b0080e7          	jalr	688(ra) # 800044ae <fileclose>
  return 0;
    80005206:	4781                	li	a5,0
}
    80005208:	853e                	mv	a0,a5
    8000520a:	60e2                	ld	ra,24(sp)
    8000520c:	6442                	ld	s0,16(sp)
    8000520e:	6105                	addi	sp,sp,32
    80005210:	8082                	ret

0000000080005212 <sys_fstat>:
{
    80005212:	1101                	addi	sp,sp,-32
    80005214:	ec06                	sd	ra,24(sp)
    80005216:	e822                	sd	s0,16(sp)
    80005218:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000521a:	fe840613          	addi	a2,s0,-24
    8000521e:	4581                	li	a1,0
    80005220:	4501                	li	a0,0
    80005222:	00000097          	auipc	ra,0x0
    80005226:	c76080e7          	jalr	-906(ra) # 80004e98 <argfd>
    return -1;
    8000522a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000522c:	02054563          	bltz	a0,80005256 <sys_fstat+0x44>
    80005230:	fe040593          	addi	a1,s0,-32
    80005234:	4505                	li	a0,1
    80005236:	ffffe097          	auipc	ra,0xffffe
    8000523a:	88a080e7          	jalr	-1910(ra) # 80002ac0 <argaddr>
    return -1;
    8000523e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005240:	00054b63          	bltz	a0,80005256 <sys_fstat+0x44>
  return filestat(f, st);
    80005244:	fe043583          	ld	a1,-32(s0)
    80005248:	fe843503          	ld	a0,-24(s0)
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	32a080e7          	jalr	810(ra) # 80004576 <filestat>
    80005254:	87aa                	mv	a5,a0
}
    80005256:	853e                	mv	a0,a5
    80005258:	60e2                	ld	ra,24(sp)
    8000525a:	6442                	ld	s0,16(sp)
    8000525c:	6105                	addi	sp,sp,32
    8000525e:	8082                	ret

0000000080005260 <sys_link>:
{
    80005260:	7169                	addi	sp,sp,-304
    80005262:	f606                	sd	ra,296(sp)
    80005264:	f222                	sd	s0,288(sp)
    80005266:	ee26                	sd	s1,280(sp)
    80005268:	ea4a                	sd	s2,272(sp)
    8000526a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000526c:	08000613          	li	a2,128
    80005270:	ed040593          	addi	a1,s0,-304
    80005274:	4501                	li	a0,0
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	86c080e7          	jalr	-1940(ra) # 80002ae2 <argstr>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005280:	10054e63          	bltz	a0,8000539c <sys_link+0x13c>
    80005284:	08000613          	li	a2,128
    80005288:	f5040593          	addi	a1,s0,-176
    8000528c:	4505                	li	a0,1
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	854080e7          	jalr	-1964(ra) # 80002ae2 <argstr>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005298:	10054263          	bltz	a0,8000539c <sys_link+0x13c>
  begin_op();
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	d46080e7          	jalr	-698(ra) # 80003fe2 <begin_op>
  if((ip = namei(old)) == 0){
    800052a4:	ed040513          	addi	a0,s0,-304
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	b1e080e7          	jalr	-1250(ra) # 80003dc6 <namei>
    800052b0:	84aa                	mv	s1,a0
    800052b2:	c551                	beqz	a0,8000533e <sys_link+0xde>
  ilock(ip);
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	35c080e7          	jalr	860(ra) # 80003610 <ilock>
  if(ip->type == T_DIR){
    800052bc:	04449703          	lh	a4,68(s1)
    800052c0:	4785                	li	a5,1
    800052c2:	08f70463          	beq	a4,a5,8000534a <sys_link+0xea>
  ip->nlink++;
    800052c6:	04a4d783          	lhu	a5,74(s1)
    800052ca:	2785                	addiw	a5,a5,1
    800052cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052d0:	8526                	mv	a0,s1
    800052d2:	ffffe097          	auipc	ra,0xffffe
    800052d6:	274080e7          	jalr	628(ra) # 80003546 <iupdate>
  iunlock(ip);
    800052da:	8526                	mv	a0,s1
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	3f6080e7          	jalr	1014(ra) # 800036d2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052e4:	fd040593          	addi	a1,s0,-48
    800052e8:	f5040513          	addi	a0,s0,-176
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	af8080e7          	jalr	-1288(ra) # 80003de4 <nameiparent>
    800052f4:	892a                	mv	s2,a0
    800052f6:	c935                	beqz	a0,8000536a <sys_link+0x10a>
  ilock(dp);
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	318080e7          	jalr	792(ra) # 80003610 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005300:	00092703          	lw	a4,0(s2)
    80005304:	409c                	lw	a5,0(s1)
    80005306:	04f71d63          	bne	a4,a5,80005360 <sys_link+0x100>
    8000530a:	40d0                	lw	a2,4(s1)
    8000530c:	fd040593          	addi	a1,s0,-48
    80005310:	854a                	mv	a0,s2
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	9f2080e7          	jalr	-1550(ra) # 80003d04 <dirlink>
    8000531a:	04054363          	bltz	a0,80005360 <sys_link+0x100>
  iunlockput(dp);
    8000531e:	854a                	mv	a0,s2
    80005320:	ffffe097          	auipc	ra,0xffffe
    80005324:	552080e7          	jalr	1362(ra) # 80003872 <iunlockput>
  iput(ip);
    80005328:	8526                	mv	a0,s1
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	4a0080e7          	jalr	1184(ra) # 800037ca <iput>
  end_op();
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	d30080e7          	jalr	-720(ra) # 80004062 <end_op>
  return 0;
    8000533a:	4781                	li	a5,0
    8000533c:	a085                	j	8000539c <sys_link+0x13c>
    end_op();
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	d24080e7          	jalr	-732(ra) # 80004062 <end_op>
    return -1;
    80005346:	57fd                	li	a5,-1
    80005348:	a891                	j	8000539c <sys_link+0x13c>
    iunlockput(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	526080e7          	jalr	1318(ra) # 80003872 <iunlockput>
    end_op();
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	d0e080e7          	jalr	-754(ra) # 80004062 <end_op>
    return -1;
    8000535c:	57fd                	li	a5,-1
    8000535e:	a83d                	j	8000539c <sys_link+0x13c>
    iunlockput(dp);
    80005360:	854a                	mv	a0,s2
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	510080e7          	jalr	1296(ra) # 80003872 <iunlockput>
  ilock(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	ffffe097          	auipc	ra,0xffffe
    80005370:	2a4080e7          	jalr	676(ra) # 80003610 <ilock>
  ip->nlink--;
    80005374:	04a4d783          	lhu	a5,74(s1)
    80005378:	37fd                	addiw	a5,a5,-1
    8000537a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	1c6080e7          	jalr	454(ra) # 80003546 <iupdate>
  iunlockput(ip);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	4e8080e7          	jalr	1256(ra) # 80003872 <iunlockput>
  end_op();
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	cd0080e7          	jalr	-816(ra) # 80004062 <end_op>
  return -1;
    8000539a:	57fd                	li	a5,-1
}
    8000539c:	853e                	mv	a0,a5
    8000539e:	70b2                	ld	ra,296(sp)
    800053a0:	7412                	ld	s0,288(sp)
    800053a2:	64f2                	ld	s1,280(sp)
    800053a4:	6952                	ld	s2,272(sp)
    800053a6:	6155                	addi	sp,sp,304
    800053a8:	8082                	ret

00000000800053aa <sys_unlink>:
{
    800053aa:	7151                	addi	sp,sp,-240
    800053ac:	f586                	sd	ra,232(sp)
    800053ae:	f1a2                	sd	s0,224(sp)
    800053b0:	eda6                	sd	s1,216(sp)
    800053b2:	e9ca                	sd	s2,208(sp)
    800053b4:	e5ce                	sd	s3,200(sp)
    800053b6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800053b8:	08000613          	li	a2,128
    800053bc:	f3040593          	addi	a1,s0,-208
    800053c0:	4501                	li	a0,0
    800053c2:	ffffd097          	auipc	ra,0xffffd
    800053c6:	720080e7          	jalr	1824(ra) # 80002ae2 <argstr>
    800053ca:	18054163          	bltz	a0,8000554c <sys_unlink+0x1a2>
  begin_op();
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	c14080e7          	jalr	-1004(ra) # 80003fe2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053d6:	fb040593          	addi	a1,s0,-80
    800053da:	f3040513          	addi	a0,s0,-208
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	a06080e7          	jalr	-1530(ra) # 80003de4 <nameiparent>
    800053e6:	84aa                	mv	s1,a0
    800053e8:	c979                	beqz	a0,800054be <sys_unlink+0x114>
  ilock(dp);
    800053ea:	ffffe097          	auipc	ra,0xffffe
    800053ee:	226080e7          	jalr	550(ra) # 80003610 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053f2:	00003597          	auipc	a1,0x3
    800053f6:	37658593          	addi	a1,a1,886 # 80008768 <syscalls+0x2b0>
    800053fa:	fb040513          	addi	a0,s0,-80
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	6dc080e7          	jalr	1756(ra) # 80003ada <namecmp>
    80005406:	14050a63          	beqz	a0,8000555a <sys_unlink+0x1b0>
    8000540a:	00003597          	auipc	a1,0x3
    8000540e:	36658593          	addi	a1,a1,870 # 80008770 <syscalls+0x2b8>
    80005412:	fb040513          	addi	a0,s0,-80
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	6c4080e7          	jalr	1732(ra) # 80003ada <namecmp>
    8000541e:	12050e63          	beqz	a0,8000555a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005422:	f2c40613          	addi	a2,s0,-212
    80005426:	fb040593          	addi	a1,s0,-80
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	6c8080e7          	jalr	1736(ra) # 80003af4 <dirlookup>
    80005434:	892a                	mv	s2,a0
    80005436:	12050263          	beqz	a0,8000555a <sys_unlink+0x1b0>
  ilock(ip);
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	1d6080e7          	jalr	470(ra) # 80003610 <ilock>
  if(ip->nlink < 1)
    80005442:	04a91783          	lh	a5,74(s2)
    80005446:	08f05263          	blez	a5,800054ca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000544a:	04491703          	lh	a4,68(s2)
    8000544e:	4785                	li	a5,1
    80005450:	08f70563          	beq	a4,a5,800054da <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005454:	4641                	li	a2,16
    80005456:	4581                	li	a1,0
    80005458:	fc040513          	addi	a0,s0,-64
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	884080e7          	jalr	-1916(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005464:	4741                	li	a4,16
    80005466:	f2c42683          	lw	a3,-212(s0)
    8000546a:	fc040613          	addi	a2,s0,-64
    8000546e:	4581                	li	a1,0
    80005470:	8526                	mv	a0,s1
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	54a080e7          	jalr	1354(ra) # 800039bc <writei>
    8000547a:	47c1                	li	a5,16
    8000547c:	0af51563          	bne	a0,a5,80005526 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005480:	04491703          	lh	a4,68(s2)
    80005484:	4785                	li	a5,1
    80005486:	0af70863          	beq	a4,a5,80005536 <sys_unlink+0x18c>
  iunlockput(dp);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	3e6080e7          	jalr	998(ra) # 80003872 <iunlockput>
  ip->nlink--;
    80005494:	04a95783          	lhu	a5,74(s2)
    80005498:	37fd                	addiw	a5,a5,-1
    8000549a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000549e:	854a                	mv	a0,s2
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	0a6080e7          	jalr	166(ra) # 80003546 <iupdate>
  iunlockput(ip);
    800054a8:	854a                	mv	a0,s2
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	3c8080e7          	jalr	968(ra) # 80003872 <iunlockput>
  end_op();
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	bb0080e7          	jalr	-1104(ra) # 80004062 <end_op>
  return 0;
    800054ba:	4501                	li	a0,0
    800054bc:	a84d                	j	8000556e <sys_unlink+0x1c4>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	ba4080e7          	jalr	-1116(ra) # 80004062 <end_op>
    return -1;
    800054c6:	557d                	li	a0,-1
    800054c8:	a05d                	j	8000556e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ca:	00003517          	auipc	a0,0x3
    800054ce:	2ce50513          	addi	a0,a0,718 # 80008798 <syscalls+0x2e0>
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054da:	04c92703          	lw	a4,76(s2)
    800054de:	02000793          	li	a5,32
    800054e2:	f6e7f9e3          	bgeu	a5,a4,80005454 <sys_unlink+0xaa>
    800054e6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ea:	4741                	li	a4,16
    800054ec:	86ce                	mv	a3,s3
    800054ee:	f1840613          	addi	a2,s0,-232
    800054f2:	4581                	li	a1,0
    800054f4:	854a                	mv	a0,s2
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	3ce080e7          	jalr	974(ra) # 800038c4 <readi>
    800054fe:	47c1                	li	a5,16
    80005500:	00f51b63          	bne	a0,a5,80005516 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005504:	f1845783          	lhu	a5,-232(s0)
    80005508:	e7a1                	bnez	a5,80005550 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000550a:	29c1                	addiw	s3,s3,16
    8000550c:	04c92783          	lw	a5,76(s2)
    80005510:	fcf9ede3          	bltu	s3,a5,800054ea <sys_unlink+0x140>
    80005514:	b781                	j	80005454 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005516:	00003517          	auipc	a0,0x3
    8000551a:	29a50513          	addi	a0,a0,666 # 800087b0 <syscalls+0x2f8>
    8000551e:	ffffb097          	auipc	ra,0xffffb
    80005522:	020080e7          	jalr	32(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005526:	00003517          	auipc	a0,0x3
    8000552a:	2a250513          	addi	a0,a0,674 # 800087c8 <syscalls+0x310>
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	010080e7          	jalr	16(ra) # 8000053e <panic>
    dp->nlink--;
    80005536:	04a4d783          	lhu	a5,74(s1)
    8000553a:	37fd                	addiw	a5,a5,-1
    8000553c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005540:	8526                	mv	a0,s1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	004080e7          	jalr	4(ra) # 80003546 <iupdate>
    8000554a:	b781                	j	8000548a <sys_unlink+0xe0>
    return -1;
    8000554c:	557d                	li	a0,-1
    8000554e:	a005                	j	8000556e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005550:	854a                	mv	a0,s2
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	320080e7          	jalr	800(ra) # 80003872 <iunlockput>
  iunlockput(dp);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	316080e7          	jalr	790(ra) # 80003872 <iunlockput>
  end_op();
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	afe080e7          	jalr	-1282(ra) # 80004062 <end_op>
  return -1;
    8000556c:	557d                	li	a0,-1
}
    8000556e:	70ae                	ld	ra,232(sp)
    80005570:	740e                	ld	s0,224(sp)
    80005572:	64ee                	ld	s1,216(sp)
    80005574:	694e                	ld	s2,208(sp)
    80005576:	69ae                	ld	s3,200(sp)
    80005578:	616d                	addi	sp,sp,240
    8000557a:	8082                	ret

000000008000557c <sys_open>:

uint64
sys_open(void)
{
    8000557c:	7131                	addi	sp,sp,-192
    8000557e:	fd06                	sd	ra,184(sp)
    80005580:	f922                	sd	s0,176(sp)
    80005582:	f526                	sd	s1,168(sp)
    80005584:	f14a                	sd	s2,160(sp)
    80005586:	ed4e                	sd	s3,152(sp)
    80005588:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000558a:	08000613          	li	a2,128
    8000558e:	f5040593          	addi	a1,s0,-176
    80005592:	4501                	li	a0,0
    80005594:	ffffd097          	auipc	ra,0xffffd
    80005598:	54e080e7          	jalr	1358(ra) # 80002ae2 <argstr>
    return -1;
    8000559c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000559e:	0c054163          	bltz	a0,80005660 <sys_open+0xe4>
    800055a2:	f4c40593          	addi	a1,s0,-180
    800055a6:	4505                	li	a0,1
    800055a8:	ffffd097          	auipc	ra,0xffffd
    800055ac:	4f6080e7          	jalr	1270(ra) # 80002a9e <argint>
    800055b0:	0a054863          	bltz	a0,80005660 <sys_open+0xe4>

  begin_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	a2e080e7          	jalr	-1490(ra) # 80003fe2 <begin_op>

  if(omode & O_CREATE){
    800055bc:	f4c42783          	lw	a5,-180(s0)
    800055c0:	2007f793          	andi	a5,a5,512
    800055c4:	cbdd                	beqz	a5,8000567a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055c6:	4681                	li	a3,0
    800055c8:	4601                	li	a2,0
    800055ca:	4589                	li	a1,2
    800055cc:	f5040513          	addi	a0,s0,-176
    800055d0:	00000097          	auipc	ra,0x0
    800055d4:	972080e7          	jalr	-1678(ra) # 80004f42 <create>
    800055d8:	892a                	mv	s2,a0
    if(ip == 0){
    800055da:	c959                	beqz	a0,80005670 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055dc:	04491703          	lh	a4,68(s2)
    800055e0:	478d                	li	a5,3
    800055e2:	00f71763          	bne	a4,a5,800055f0 <sys_open+0x74>
    800055e6:	04695703          	lhu	a4,70(s2)
    800055ea:	47a5                	li	a5,9
    800055ec:	0ce7ec63          	bltu	a5,a4,800056c4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	e02080e7          	jalr	-510(ra) # 800043f2 <filealloc>
    800055f8:	89aa                	mv	s3,a0
    800055fa:	10050263          	beqz	a0,800056fe <sys_open+0x182>
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	902080e7          	jalr	-1790(ra) # 80004f00 <fdalloc>
    80005606:	84aa                	mv	s1,a0
    80005608:	0e054663          	bltz	a0,800056f4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000560c:	04491703          	lh	a4,68(s2)
    80005610:	478d                	li	a5,3
    80005612:	0cf70463          	beq	a4,a5,800056da <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005616:	4789                	li	a5,2
    80005618:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000561c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005620:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005624:	f4c42783          	lw	a5,-180(s0)
    80005628:	0017c713          	xori	a4,a5,1
    8000562c:	8b05                	andi	a4,a4,1
    8000562e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005632:	0037f713          	andi	a4,a5,3
    80005636:	00e03733          	snez	a4,a4
    8000563a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000563e:	4007f793          	andi	a5,a5,1024
    80005642:	c791                	beqz	a5,8000564e <sys_open+0xd2>
    80005644:	04491703          	lh	a4,68(s2)
    80005648:	4789                	li	a5,2
    8000564a:	08f70f63          	beq	a4,a5,800056e8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	082080e7          	jalr	130(ra) # 800036d2 <iunlock>
  end_op();
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	a0a080e7          	jalr	-1526(ra) # 80004062 <end_op>

  return fd;
}
    80005660:	8526                	mv	a0,s1
    80005662:	70ea                	ld	ra,184(sp)
    80005664:	744a                	ld	s0,176(sp)
    80005666:	74aa                	ld	s1,168(sp)
    80005668:	790a                	ld	s2,160(sp)
    8000566a:	69ea                	ld	s3,152(sp)
    8000566c:	6129                	addi	sp,sp,192
    8000566e:	8082                	ret
      end_op();
    80005670:	fffff097          	auipc	ra,0xfffff
    80005674:	9f2080e7          	jalr	-1550(ra) # 80004062 <end_op>
      return -1;
    80005678:	b7e5                	j	80005660 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000567a:	f5040513          	addi	a0,s0,-176
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	748080e7          	jalr	1864(ra) # 80003dc6 <namei>
    80005686:	892a                	mv	s2,a0
    80005688:	c905                	beqz	a0,800056b8 <sys_open+0x13c>
    ilock(ip);
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	f86080e7          	jalr	-122(ra) # 80003610 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005692:	04491703          	lh	a4,68(s2)
    80005696:	4785                	li	a5,1
    80005698:	f4f712e3          	bne	a4,a5,800055dc <sys_open+0x60>
    8000569c:	f4c42783          	lw	a5,-180(s0)
    800056a0:	dba1                	beqz	a5,800055f0 <sys_open+0x74>
      iunlockput(ip);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	1ce080e7          	jalr	462(ra) # 80003872 <iunlockput>
      end_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	9b6080e7          	jalr	-1610(ra) # 80004062 <end_op>
      return -1;
    800056b4:	54fd                	li	s1,-1
    800056b6:	b76d                	j	80005660 <sys_open+0xe4>
      end_op();
    800056b8:	fffff097          	auipc	ra,0xfffff
    800056bc:	9aa080e7          	jalr	-1622(ra) # 80004062 <end_op>
      return -1;
    800056c0:	54fd                	li	s1,-1
    800056c2:	bf79                	j	80005660 <sys_open+0xe4>
    iunlockput(ip);
    800056c4:	854a                	mv	a0,s2
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	1ac080e7          	jalr	428(ra) # 80003872 <iunlockput>
    end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	994080e7          	jalr	-1644(ra) # 80004062 <end_op>
    return -1;
    800056d6:	54fd                	li	s1,-1
    800056d8:	b761                	j	80005660 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056da:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056de:	04691783          	lh	a5,70(s2)
    800056e2:	02f99223          	sh	a5,36(s3)
    800056e6:	bf2d                	j	80005620 <sys_open+0xa4>
    itrunc(ip);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	034080e7          	jalr	52(ra) # 8000371e <itrunc>
    800056f2:	bfb1                	j	8000564e <sys_open+0xd2>
      fileclose(f);
    800056f4:	854e                	mv	a0,s3
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	db8080e7          	jalr	-584(ra) # 800044ae <fileclose>
    iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	172080e7          	jalr	370(ra) # 80003872 <iunlockput>
    end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	95a080e7          	jalr	-1702(ra) # 80004062 <end_op>
    return -1;
    80005710:	54fd                	li	s1,-1
    80005712:	b7b9                	j	80005660 <sys_open+0xe4>

0000000080005714 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005714:	7175                	addi	sp,sp,-144
    80005716:	e506                	sd	ra,136(sp)
    80005718:	e122                	sd	s0,128(sp)
    8000571a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	8c6080e7          	jalr	-1850(ra) # 80003fe2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005724:	08000613          	li	a2,128
    80005728:	f7040593          	addi	a1,s0,-144
    8000572c:	4501                	li	a0,0
    8000572e:	ffffd097          	auipc	ra,0xffffd
    80005732:	3b4080e7          	jalr	948(ra) # 80002ae2 <argstr>
    80005736:	02054963          	bltz	a0,80005768 <sys_mkdir+0x54>
    8000573a:	4681                	li	a3,0
    8000573c:	4601                	li	a2,0
    8000573e:	4585                	li	a1,1
    80005740:	f7040513          	addi	a0,s0,-144
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	7fe080e7          	jalr	2046(ra) # 80004f42 <create>
    8000574c:	cd11                	beqz	a0,80005768 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	124080e7          	jalr	292(ra) # 80003872 <iunlockput>
  end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	90c080e7          	jalr	-1780(ra) # 80004062 <end_op>
  return 0;
    8000575e:	4501                	li	a0,0
}
    80005760:	60aa                	ld	ra,136(sp)
    80005762:	640a                	ld	s0,128(sp)
    80005764:	6149                	addi	sp,sp,144
    80005766:	8082                	ret
    end_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	8fa080e7          	jalr	-1798(ra) # 80004062 <end_op>
    return -1;
    80005770:	557d                	li	a0,-1
    80005772:	b7fd                	j	80005760 <sys_mkdir+0x4c>

0000000080005774 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005774:	7135                	addi	sp,sp,-160
    80005776:	ed06                	sd	ra,152(sp)
    80005778:	e922                	sd	s0,144(sp)
    8000577a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	866080e7          	jalr	-1946(ra) # 80003fe2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005784:	08000613          	li	a2,128
    80005788:	f7040593          	addi	a1,s0,-144
    8000578c:	4501                	li	a0,0
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	354080e7          	jalr	852(ra) # 80002ae2 <argstr>
    80005796:	04054a63          	bltz	a0,800057ea <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000579a:	f6c40593          	addi	a1,s0,-148
    8000579e:	4505                	li	a0,1
    800057a0:	ffffd097          	auipc	ra,0xffffd
    800057a4:	2fe080e7          	jalr	766(ra) # 80002a9e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800057a8:	04054163          	bltz	a0,800057ea <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800057ac:	f6840593          	addi	a1,s0,-152
    800057b0:	4509                	li	a0,2
    800057b2:	ffffd097          	auipc	ra,0xffffd
    800057b6:	2ec080e7          	jalr	748(ra) # 80002a9e <argint>
     argint(1, &major) < 0 ||
    800057ba:	02054863          	bltz	a0,800057ea <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057be:	f6841683          	lh	a3,-152(s0)
    800057c2:	f6c41603          	lh	a2,-148(s0)
    800057c6:	458d                	li	a1,3
    800057c8:	f7040513          	addi	a0,s0,-144
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	776080e7          	jalr	1910(ra) # 80004f42 <create>
     argint(2, &minor) < 0 ||
    800057d4:	c919                	beqz	a0,800057ea <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057d6:	ffffe097          	auipc	ra,0xffffe
    800057da:	09c080e7          	jalr	156(ra) # 80003872 <iunlockput>
  end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	884080e7          	jalr	-1916(ra) # 80004062 <end_op>
  return 0;
    800057e6:	4501                	li	a0,0
    800057e8:	a031                	j	800057f4 <sys_mknod+0x80>
    end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	878080e7          	jalr	-1928(ra) # 80004062 <end_op>
    return -1;
    800057f2:	557d                	li	a0,-1
}
    800057f4:	60ea                	ld	ra,152(sp)
    800057f6:	644a                	ld	s0,144(sp)
    800057f8:	610d                	addi	sp,sp,160
    800057fa:	8082                	ret

00000000800057fc <sys_chdir>:

uint64
sys_chdir(void)
{
    800057fc:	7135                	addi	sp,sp,-160
    800057fe:	ed06                	sd	ra,152(sp)
    80005800:	e922                	sd	s0,144(sp)
    80005802:	e526                	sd	s1,136(sp)
    80005804:	e14a                	sd	s2,128(sp)
    80005806:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005808:	ffffc097          	auipc	ra,0xffffc
    8000580c:	1ea080e7          	jalr	490(ra) # 800019f2 <myproc>
    80005810:	892a                	mv	s2,a0
  
  begin_op();
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	7d0080e7          	jalr	2000(ra) # 80003fe2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000581a:	08000613          	li	a2,128
    8000581e:	f6040593          	addi	a1,s0,-160
    80005822:	4501                	li	a0,0
    80005824:	ffffd097          	auipc	ra,0xffffd
    80005828:	2be080e7          	jalr	702(ra) # 80002ae2 <argstr>
    8000582c:	04054b63          	bltz	a0,80005882 <sys_chdir+0x86>
    80005830:	f6040513          	addi	a0,s0,-160
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	592080e7          	jalr	1426(ra) # 80003dc6 <namei>
    8000583c:	84aa                	mv	s1,a0
    8000583e:	c131                	beqz	a0,80005882 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	dd0080e7          	jalr	-560(ra) # 80003610 <ilock>
  if(ip->type != T_DIR){
    80005848:	04449703          	lh	a4,68(s1)
    8000584c:	4785                	li	a5,1
    8000584e:	04f71063          	bne	a4,a5,8000588e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	e7e080e7          	jalr	-386(ra) # 800036d2 <iunlock>
  iput(p->cwd);
    8000585c:	15093503          	ld	a0,336(s2)
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	f6a080e7          	jalr	-150(ra) # 800037ca <iput>
  end_op();
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	7fa080e7          	jalr	2042(ra) # 80004062 <end_op>
  p->cwd = ip;
    80005870:	14993823          	sd	s1,336(s2)
  return 0;
    80005874:	4501                	li	a0,0
}
    80005876:	60ea                	ld	ra,152(sp)
    80005878:	644a                	ld	s0,144(sp)
    8000587a:	64aa                	ld	s1,136(sp)
    8000587c:	690a                	ld	s2,128(sp)
    8000587e:	610d                	addi	sp,sp,160
    80005880:	8082                	ret
    end_op();
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	7e0080e7          	jalr	2016(ra) # 80004062 <end_op>
    return -1;
    8000588a:	557d                	li	a0,-1
    8000588c:	b7ed                	j	80005876 <sys_chdir+0x7a>
    iunlockput(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	fe2080e7          	jalr	-30(ra) # 80003872 <iunlockput>
    end_op();
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	7ca080e7          	jalr	1994(ra) # 80004062 <end_op>
    return -1;
    800058a0:	557d                	li	a0,-1
    800058a2:	bfd1                	j	80005876 <sys_chdir+0x7a>

00000000800058a4 <sys_exec>:

uint64
sys_exec(void)
{
    800058a4:	7145                	addi	sp,sp,-464
    800058a6:	e786                	sd	ra,456(sp)
    800058a8:	e3a2                	sd	s0,448(sp)
    800058aa:	ff26                	sd	s1,440(sp)
    800058ac:	fb4a                	sd	s2,432(sp)
    800058ae:	f74e                	sd	s3,424(sp)
    800058b0:	f352                	sd	s4,416(sp)
    800058b2:	ef56                	sd	s5,408(sp)
    800058b4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058b6:	08000613          	li	a2,128
    800058ba:	f4040593          	addi	a1,s0,-192
    800058be:	4501                	li	a0,0
    800058c0:	ffffd097          	auipc	ra,0xffffd
    800058c4:	222080e7          	jalr	546(ra) # 80002ae2 <argstr>
    return -1;
    800058c8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058ca:	0c054a63          	bltz	a0,8000599e <sys_exec+0xfa>
    800058ce:	e3840593          	addi	a1,s0,-456
    800058d2:	4505                	li	a0,1
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	1ec080e7          	jalr	492(ra) # 80002ac0 <argaddr>
    800058dc:	0c054163          	bltz	a0,8000599e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058e0:	10000613          	li	a2,256
    800058e4:	4581                	li	a1,0
    800058e6:	e4040513          	addi	a0,s0,-448
    800058ea:	ffffb097          	auipc	ra,0xffffb
    800058ee:	3f6080e7          	jalr	1014(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058f2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058f6:	89a6                	mv	s3,s1
    800058f8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058fa:	02000a13          	li	s4,32
    800058fe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005902:	00391513          	slli	a0,s2,0x3
    80005906:	e3040593          	addi	a1,s0,-464
    8000590a:	e3843783          	ld	a5,-456(s0)
    8000590e:	953e                	add	a0,a0,a5
    80005910:	ffffd097          	auipc	ra,0xffffd
    80005914:	0f4080e7          	jalr	244(ra) # 80002a04 <fetchaddr>
    80005918:	02054a63          	bltz	a0,8000594c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000591c:	e3043783          	ld	a5,-464(s0)
    80005920:	c3b9                	beqz	a5,80005966 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	1d2080e7          	jalr	466(ra) # 80000af4 <kalloc>
    8000592a:	85aa                	mv	a1,a0
    8000592c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005930:	cd11                	beqz	a0,8000594c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005932:	6611                	lui	a2,0x4
    80005934:	e3043503          	ld	a0,-464(s0)
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	11e080e7          	jalr	286(ra) # 80002a56 <fetchstr>
    80005940:	00054663          	bltz	a0,8000594c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005944:	0905                	addi	s2,s2,1
    80005946:	09a1                	addi	s3,s3,8
    80005948:	fb491be3          	bne	s2,s4,800058fe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000594c:	10048913          	addi	s2,s1,256
    80005950:	6088                	ld	a0,0(s1)
    80005952:	c529                	beqz	a0,8000599c <sys_exec+0xf8>
    kfree(argv[i]);
    80005954:	ffffb097          	auipc	ra,0xffffb
    80005958:	0a4080e7          	jalr	164(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000595c:	04a1                	addi	s1,s1,8
    8000595e:	ff2499e3          	bne	s1,s2,80005950 <sys_exec+0xac>
  return -1;
    80005962:	597d                	li	s2,-1
    80005964:	a82d                	j	8000599e <sys_exec+0xfa>
      argv[i] = 0;
    80005966:	0a8e                	slli	s5,s5,0x3
    80005968:	fc040793          	addi	a5,s0,-64
    8000596c:	9abe                	add	s5,s5,a5
    8000596e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005972:	e4040593          	addi	a1,s0,-448
    80005976:	f4040513          	addi	a0,s0,-192
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	194080e7          	jalr	404(ra) # 80004b0e <exec>
    80005982:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005984:	10048993          	addi	s3,s1,256
    80005988:	6088                	ld	a0,0(s1)
    8000598a:	c911                	beqz	a0,8000599e <sys_exec+0xfa>
    kfree(argv[i]);
    8000598c:	ffffb097          	auipc	ra,0xffffb
    80005990:	06c080e7          	jalr	108(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005994:	04a1                	addi	s1,s1,8
    80005996:	ff3499e3          	bne	s1,s3,80005988 <sys_exec+0xe4>
    8000599a:	a011                	j	8000599e <sys_exec+0xfa>
  return -1;
    8000599c:	597d                	li	s2,-1
}
    8000599e:	854a                	mv	a0,s2
    800059a0:	60be                	ld	ra,456(sp)
    800059a2:	641e                	ld	s0,448(sp)
    800059a4:	74fa                	ld	s1,440(sp)
    800059a6:	795a                	ld	s2,432(sp)
    800059a8:	79ba                	ld	s3,424(sp)
    800059aa:	7a1a                	ld	s4,416(sp)
    800059ac:	6afa                	ld	s5,408(sp)
    800059ae:	6179                	addi	sp,sp,464
    800059b0:	8082                	ret

00000000800059b2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800059b2:	7139                	addi	sp,sp,-64
    800059b4:	fc06                	sd	ra,56(sp)
    800059b6:	f822                	sd	s0,48(sp)
    800059b8:	f426                	sd	s1,40(sp)
    800059ba:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059bc:	ffffc097          	auipc	ra,0xffffc
    800059c0:	036080e7          	jalr	54(ra) # 800019f2 <myproc>
    800059c4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059c6:	fd840593          	addi	a1,s0,-40
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	0f4080e7          	jalr	244(ra) # 80002ac0 <argaddr>
    return -1;
    800059d4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059d6:	0e054063          	bltz	a0,80005ab6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059da:	fc840593          	addi	a1,s0,-56
    800059de:	fd040513          	addi	a0,s0,-48
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	dfc080e7          	jalr	-516(ra) # 800047de <pipealloc>
    return -1;
    800059ea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059ec:	0c054563          	bltz	a0,80005ab6 <sys_pipe+0x104>
  fd0 = -1;
    800059f0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059f4:	fd043503          	ld	a0,-48(s0)
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	508080e7          	jalr	1288(ra) # 80004f00 <fdalloc>
    80005a00:	fca42223          	sw	a0,-60(s0)
    80005a04:	08054c63          	bltz	a0,80005a9c <sys_pipe+0xea>
    80005a08:	fc843503          	ld	a0,-56(s0)
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	4f4080e7          	jalr	1268(ra) # 80004f00 <fdalloc>
    80005a14:	fca42023          	sw	a0,-64(s0)
    80005a18:	06054863          	bltz	a0,80005a88 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a1c:	4691                	li	a3,4
    80005a1e:	fc440613          	addi	a2,s0,-60
    80005a22:	fd843583          	ld	a1,-40(s0)
    80005a26:	68a8                	ld	a0,80(s1)
    80005a28:	ffffc097          	auipc	ra,0xffffc
    80005a2c:	c8c080e7          	jalr	-884(ra) # 800016b4 <copyout>
    80005a30:	02054063          	bltz	a0,80005a50 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a34:	4691                	li	a3,4
    80005a36:	fc040613          	addi	a2,s0,-64
    80005a3a:	fd843583          	ld	a1,-40(s0)
    80005a3e:	0591                	addi	a1,a1,4
    80005a40:	68a8                	ld	a0,80(s1)
    80005a42:	ffffc097          	auipc	ra,0xffffc
    80005a46:	c72080e7          	jalr	-910(ra) # 800016b4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a4a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a4c:	06055563          	bgez	a0,80005ab6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a50:	fc442783          	lw	a5,-60(s0)
    80005a54:	07e9                	addi	a5,a5,26
    80005a56:	078e                	slli	a5,a5,0x3
    80005a58:	97a6                	add	a5,a5,s1
    80005a5a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a5e:	fc042503          	lw	a0,-64(s0)
    80005a62:	0569                	addi	a0,a0,26
    80005a64:	050e                	slli	a0,a0,0x3
    80005a66:	9526                	add	a0,a0,s1
    80005a68:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a6c:	fd043503          	ld	a0,-48(s0)
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	a3e080e7          	jalr	-1474(ra) # 800044ae <fileclose>
    fileclose(wf);
    80005a78:	fc843503          	ld	a0,-56(s0)
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	a32080e7          	jalr	-1486(ra) # 800044ae <fileclose>
    return -1;
    80005a84:	57fd                	li	a5,-1
    80005a86:	a805                	j	80005ab6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a88:	fc442783          	lw	a5,-60(s0)
    80005a8c:	0007c863          	bltz	a5,80005a9c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a90:	01a78513          	addi	a0,a5,26
    80005a94:	050e                	slli	a0,a0,0x3
    80005a96:	9526                	add	a0,a0,s1
    80005a98:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a9c:	fd043503          	ld	a0,-48(s0)
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	a0e080e7          	jalr	-1522(ra) # 800044ae <fileclose>
    fileclose(wf);
    80005aa8:	fc843503          	ld	a0,-56(s0)
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	a02080e7          	jalr	-1534(ra) # 800044ae <fileclose>
    return -1;
    80005ab4:	57fd                	li	a5,-1
}
    80005ab6:	853e                	mv	a0,a5
    80005ab8:	70e2                	ld	ra,56(sp)
    80005aba:	7442                	ld	s0,48(sp)
    80005abc:	74a2                	ld	s1,40(sp)
    80005abe:	6121                	addi	sp,sp,64
    80005ac0:	8082                	ret
	...

0000000080005ad0 <kernelvec>:
    80005ad0:	7111                	addi	sp,sp,-256
    80005ad2:	e006                	sd	ra,0(sp)
    80005ad4:	e40a                	sd	sp,8(sp)
    80005ad6:	e80e                	sd	gp,16(sp)
    80005ad8:	ec12                	sd	tp,24(sp)
    80005ada:	f016                	sd	t0,32(sp)
    80005adc:	f41a                	sd	t1,40(sp)
    80005ade:	f81e                	sd	t2,48(sp)
    80005ae0:	fc22                	sd	s0,56(sp)
    80005ae2:	e0a6                	sd	s1,64(sp)
    80005ae4:	e4aa                	sd	a0,72(sp)
    80005ae6:	e8ae                	sd	a1,80(sp)
    80005ae8:	ecb2                	sd	a2,88(sp)
    80005aea:	f0b6                	sd	a3,96(sp)
    80005aec:	f4ba                	sd	a4,104(sp)
    80005aee:	f8be                	sd	a5,112(sp)
    80005af0:	fcc2                	sd	a6,120(sp)
    80005af2:	e146                	sd	a7,128(sp)
    80005af4:	e54a                	sd	s2,136(sp)
    80005af6:	e94e                	sd	s3,144(sp)
    80005af8:	ed52                	sd	s4,152(sp)
    80005afa:	f156                	sd	s5,160(sp)
    80005afc:	f55a                	sd	s6,168(sp)
    80005afe:	f95e                	sd	s7,176(sp)
    80005b00:	fd62                	sd	s8,184(sp)
    80005b02:	e1e6                	sd	s9,192(sp)
    80005b04:	e5ea                	sd	s10,200(sp)
    80005b06:	e9ee                	sd	s11,208(sp)
    80005b08:	edf2                	sd	t3,216(sp)
    80005b0a:	f1f6                	sd	t4,224(sp)
    80005b0c:	f5fa                	sd	t5,232(sp)
    80005b0e:	f9fe                	sd	t6,240(sp)
    80005b10:	dc1fc0ef          	jal	ra,800028d0 <kerneltrap>
    80005b14:	6082                	ld	ra,0(sp)
    80005b16:	6122                	ld	sp,8(sp)
    80005b18:	61c2                	ld	gp,16(sp)
    80005b1a:	7282                	ld	t0,32(sp)
    80005b1c:	7322                	ld	t1,40(sp)
    80005b1e:	73c2                	ld	t2,48(sp)
    80005b20:	7462                	ld	s0,56(sp)
    80005b22:	6486                	ld	s1,64(sp)
    80005b24:	6526                	ld	a0,72(sp)
    80005b26:	65c6                	ld	a1,80(sp)
    80005b28:	6666                	ld	a2,88(sp)
    80005b2a:	7686                	ld	a3,96(sp)
    80005b2c:	7726                	ld	a4,104(sp)
    80005b2e:	77c6                	ld	a5,112(sp)
    80005b30:	7866                	ld	a6,120(sp)
    80005b32:	688a                	ld	a7,128(sp)
    80005b34:	692a                	ld	s2,136(sp)
    80005b36:	69ca                	ld	s3,144(sp)
    80005b38:	6a6a                	ld	s4,152(sp)
    80005b3a:	7a8a                	ld	s5,160(sp)
    80005b3c:	7b2a                	ld	s6,168(sp)
    80005b3e:	7bca                	ld	s7,176(sp)
    80005b40:	7c6a                	ld	s8,184(sp)
    80005b42:	6c8e                	ld	s9,192(sp)
    80005b44:	6d2e                	ld	s10,200(sp)
    80005b46:	6dce                	ld	s11,208(sp)
    80005b48:	6e6e                	ld	t3,216(sp)
    80005b4a:	7e8e                	ld	t4,224(sp)
    80005b4c:	7f2e                	ld	t5,232(sp)
    80005b4e:	7fce                	ld	t6,240(sp)
    80005b50:	6111                	addi	sp,sp,256
    80005b52:	10200073          	sret
    80005b56:	00000013          	nop
    80005b5a:	00000013          	nop
    80005b5e:	0001                	nop

0000000080005b60 <timervec>:
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	e10c                	sd	a1,0(a0)
    80005b66:	e510                	sd	a2,8(a0)
    80005b68:	e914                	sd	a3,16(a0)
    80005b6a:	6d0c                	ld	a1,24(a0)
    80005b6c:	7110                	ld	a2,32(a0)
    80005b6e:	6194                	ld	a3,0(a1)
    80005b70:	96b2                	add	a3,a3,a2
    80005b72:	e194                	sd	a3,0(a1)
    80005b74:	4589                	li	a1,2
    80005b76:	14459073          	csrw	sip,a1
    80005b7a:	6914                	ld	a3,16(a0)
    80005b7c:	6510                	ld	a2,8(a0)
    80005b7e:	610c                	ld	a1,0(a0)
    80005b80:	34051573          	csrrw	a0,mscratch,a0
    80005b84:	30200073          	mret
	...

0000000080005b8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b8a:	1141                	addi	sp,sp,-16
    80005b8c:	e422                	sd	s0,8(sp)
    80005b8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b90:	0c0007b7          	lui	a5,0xc000
    80005b94:	4705                	li	a4,1
    80005b96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b98:	c3d8                	sw	a4,4(a5)
}
    80005b9a:	6422                	ld	s0,8(sp)
    80005b9c:	0141                	addi	sp,sp,16
    80005b9e:	8082                	ret

0000000080005ba0 <plicinithart>:

void
plicinithart(void)
{
    80005ba0:	1141                	addi	sp,sp,-16
    80005ba2:	e406                	sd	ra,8(sp)
    80005ba4:	e022                	sd	s0,0(sp)
    80005ba6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	e1e080e7          	jalr	-482(ra) # 800019c6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005bb0:	0085171b          	slliw	a4,a0,0x8
    80005bb4:	0c0027b7          	lui	a5,0xc002
    80005bb8:	97ba                	add	a5,a5,a4
    80005bba:	40200713          	li	a4,1026
    80005bbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005bc2:	00d5151b          	slliw	a0,a0,0xd
    80005bc6:	0c2017b7          	lui	a5,0xc201
    80005bca:	953e                	add	a0,a0,a5
    80005bcc:	00052023          	sw	zero,0(a0)
}
    80005bd0:	60a2                	ld	ra,8(sp)
    80005bd2:	6402                	ld	s0,0(sp)
    80005bd4:	0141                	addi	sp,sp,16
    80005bd6:	8082                	ret

0000000080005bd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bd8:	1141                	addi	sp,sp,-16
    80005bda:	e406                	sd	ra,8(sp)
    80005bdc:	e022                	sd	s0,0(sp)
    80005bde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005be0:	ffffc097          	auipc	ra,0xffffc
    80005be4:	de6080e7          	jalr	-538(ra) # 800019c6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005be8:	00d5179b          	slliw	a5,a0,0xd
    80005bec:	0c201537          	lui	a0,0xc201
    80005bf0:	953e                	add	a0,a0,a5
  return irq;
}
    80005bf2:	4148                	lw	a0,4(a0)
    80005bf4:	60a2                	ld	ra,8(sp)
    80005bf6:	6402                	ld	s0,0(sp)
    80005bf8:	0141                	addi	sp,sp,16
    80005bfa:	8082                	ret

0000000080005bfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bfc:	1101                	addi	sp,sp,-32
    80005bfe:	ec06                	sd	ra,24(sp)
    80005c00:	e822                	sd	s0,16(sp)
    80005c02:	e426                	sd	s1,8(sp)
    80005c04:	1000                	addi	s0,sp,32
    80005c06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	dbe080e7          	jalr	-578(ra) # 800019c6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005c10:	00d5151b          	slliw	a0,a0,0xd
    80005c14:	0c2017b7          	lui	a5,0xc201
    80005c18:	97aa                	add	a5,a5,a0
    80005c1a:	c3c4                	sw	s1,4(a5)
}
    80005c1c:	60e2                	ld	ra,24(sp)
    80005c1e:	6442                	ld	s0,16(sp)
    80005c20:	64a2                	ld	s1,8(sp)
    80005c22:	6105                	addi	sp,sp,32
    80005c24:	8082                	ret

0000000080005c26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c26:	1141                	addi	sp,sp,-16
    80005c28:	e406                	sd	ra,8(sp)
    80005c2a:	e022                	sd	s0,0(sp)
    80005c2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c2e:	479d                	li	a5,7
    80005c30:	06a7c963          	blt	a5,a0,80005ca2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c34:	00022797          	auipc	a5,0x22
    80005c38:	3cc78793          	addi	a5,a5,972 # 80028000 <disk>
    80005c3c:	00a78733          	add	a4,a5,a0
    80005c40:	67a1                	lui	a5,0x8
    80005c42:	97ba                	add	a5,a5,a4
    80005c44:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005c48:	e7ad                	bnez	a5,80005cb2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c4a:	00451793          	slli	a5,a0,0x4
    80005c4e:	0002a717          	auipc	a4,0x2a
    80005c52:	3b270713          	addi	a4,a4,946 # 80030000 <disk+0x8000>
    80005c56:	6314                	ld	a3,0(a4)
    80005c58:	96be                	add	a3,a3,a5
    80005c5a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c5e:	6314                	ld	a3,0(a4)
    80005c60:	96be                	add	a3,a3,a5
    80005c62:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c66:	6314                	ld	a3,0(a4)
    80005c68:	96be                	add	a3,a3,a5
    80005c6a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c6e:	6318                	ld	a4,0(a4)
    80005c70:	97ba                	add	a5,a5,a4
    80005c72:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c76:	00022797          	auipc	a5,0x22
    80005c7a:	38a78793          	addi	a5,a5,906 # 80028000 <disk>
    80005c7e:	97aa                	add	a5,a5,a0
    80005c80:	6521                	lui	a0,0x8
    80005c82:	953e                	add	a0,a0,a5
    80005c84:	4785                	li	a5,1
    80005c86:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005c8a:	0002a517          	auipc	a0,0x2a
    80005c8e:	38e50513          	addi	a0,a0,910 # 80030018 <disk+0x8018>
    80005c92:	ffffc097          	auipc	ra,0xffffc
    80005c96:	5a8080e7          	jalr	1448(ra) # 8000223a <wakeup>
}
    80005c9a:	60a2                	ld	ra,8(sp)
    80005c9c:	6402                	ld	s0,0(sp)
    80005c9e:	0141                	addi	sp,sp,16
    80005ca0:	8082                	ret
    panic("free_desc 1");
    80005ca2:	00003517          	auipc	a0,0x3
    80005ca6:	b3650513          	addi	a0,a0,-1226 # 800087d8 <syscalls+0x320>
    80005caa:	ffffb097          	auipc	ra,0xffffb
    80005cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005cb2:	00003517          	auipc	a0,0x3
    80005cb6:	b3650513          	addi	a0,a0,-1226 # 800087e8 <syscalls+0x330>
    80005cba:	ffffb097          	auipc	ra,0xffffb
    80005cbe:	884080e7          	jalr	-1916(ra) # 8000053e <panic>

0000000080005cc2 <virtio_disk_init>:
{
    80005cc2:	1101                	addi	sp,sp,-32
    80005cc4:	ec06                	sd	ra,24(sp)
    80005cc6:	e822                	sd	s0,16(sp)
    80005cc8:	e426                	sd	s1,8(sp)
    80005cca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ccc:	00003597          	auipc	a1,0x3
    80005cd0:	b2c58593          	addi	a1,a1,-1236 # 800087f8 <syscalls+0x340>
    80005cd4:	0002a517          	auipc	a0,0x2a
    80005cd8:	45450513          	addi	a0,a0,1108 # 80030128 <disk+0x8128>
    80005cdc:	ffffb097          	auipc	ra,0xffffb
    80005ce0:	e78080e7          	jalr	-392(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ce4:	100017b7          	lui	a5,0x10001
    80005ce8:	4398                	lw	a4,0(a5)
    80005cea:	2701                	sext.w	a4,a4
    80005cec:	747277b7          	lui	a5,0x74727
    80005cf0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cf4:	0ef71163          	bne	a4,a5,80005dd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cf8:	100017b7          	lui	a5,0x10001
    80005cfc:	43dc                	lw	a5,4(a5)
    80005cfe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d00:	4705                	li	a4,1
    80005d02:	0ce79a63          	bne	a5,a4,80005dd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d06:	100017b7          	lui	a5,0x10001
    80005d0a:	479c                	lw	a5,8(a5)
    80005d0c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d0e:	4709                	li	a4,2
    80005d10:	0ce79363          	bne	a5,a4,80005dd6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d14:	100017b7          	lui	a5,0x10001
    80005d18:	47d8                	lw	a4,12(a5)
    80005d1a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d1c:	554d47b7          	lui	a5,0x554d4
    80005d20:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d24:	0af71963          	bne	a4,a5,80005dd6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d28:	100017b7          	lui	a5,0x10001
    80005d2c:	4705                	li	a4,1
    80005d2e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d30:	470d                	li	a4,3
    80005d32:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d34:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d36:	c7ffe737          	lui	a4,0xc7ffe
    80005d3a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fca75f>
    80005d3e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d40:	2701                	sext.w	a4,a4
    80005d42:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d44:	472d                	li	a4,11
    80005d46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d48:	473d                	li	a4,15
    80005d4a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d4c:	6711                	lui	a4,0x4
    80005d4e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d50:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d54:	5bdc                	lw	a5,52(a5)
    80005d56:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d58:	c7d9                	beqz	a5,80005de6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d5a:	471d                	li	a4,7
    80005d5c:	08f77d63          	bgeu	a4,a5,80005df6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d60:	100014b7          	lui	s1,0x10001
    80005d64:	47a1                	li	a5,8
    80005d66:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d68:	6621                	lui	a2,0x8
    80005d6a:	4581                	li	a1,0
    80005d6c:	00022517          	auipc	a0,0x22
    80005d70:	29450513          	addi	a0,a0,660 # 80028000 <disk>
    80005d74:	ffffb097          	auipc	ra,0xffffb
    80005d78:	f6c080e7          	jalr	-148(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d7c:	00022717          	auipc	a4,0x22
    80005d80:	28470713          	addi	a4,a4,644 # 80028000 <disk>
    80005d84:	00e75793          	srli	a5,a4,0xe
    80005d88:	2781                	sext.w	a5,a5
    80005d8a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d8c:	0002a797          	auipc	a5,0x2a
    80005d90:	27478793          	addi	a5,a5,628 # 80030000 <disk+0x8000>
    80005d94:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d96:	00022717          	auipc	a4,0x22
    80005d9a:	2ea70713          	addi	a4,a4,746 # 80028080 <disk+0x80>
    80005d9e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005da0:	00026717          	auipc	a4,0x26
    80005da4:	26070713          	addi	a4,a4,608 # 8002c000 <disk+0x4000>
    80005da8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005daa:	4705                	li	a4,1
    80005dac:	00e78c23          	sb	a4,24(a5)
    80005db0:	00e78ca3          	sb	a4,25(a5)
    80005db4:	00e78d23          	sb	a4,26(a5)
    80005db8:	00e78da3          	sb	a4,27(a5)
    80005dbc:	00e78e23          	sb	a4,28(a5)
    80005dc0:	00e78ea3          	sb	a4,29(a5)
    80005dc4:	00e78f23          	sb	a4,30(a5)
    80005dc8:	00e78fa3          	sb	a4,31(a5)
}
    80005dcc:	60e2                	ld	ra,24(sp)
    80005dce:	6442                	ld	s0,16(sp)
    80005dd0:	64a2                	ld	s1,8(sp)
    80005dd2:	6105                	addi	sp,sp,32
    80005dd4:	8082                	ret
    panic("could not find virtio disk");
    80005dd6:	00003517          	auipc	a0,0x3
    80005dda:	a3250513          	addi	a0,a0,-1486 # 80008808 <syscalls+0x350>
    80005dde:	ffffa097          	auipc	ra,0xffffa
    80005de2:	760080e7          	jalr	1888(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005de6:	00003517          	auipc	a0,0x3
    80005dea:	a4250513          	addi	a0,a0,-1470 # 80008828 <syscalls+0x370>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	750080e7          	jalr	1872(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005df6:	00003517          	auipc	a0,0x3
    80005dfa:	a5250513          	addi	a0,a0,-1454 # 80008848 <syscalls+0x390>
    80005dfe:	ffffa097          	auipc	ra,0xffffa
    80005e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>

0000000080005e06 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e06:	7159                	addi	sp,sp,-112
    80005e08:	f486                	sd	ra,104(sp)
    80005e0a:	f0a2                	sd	s0,96(sp)
    80005e0c:	eca6                	sd	s1,88(sp)
    80005e0e:	e8ca                	sd	s2,80(sp)
    80005e10:	e4ce                	sd	s3,72(sp)
    80005e12:	e0d2                	sd	s4,64(sp)
    80005e14:	fc56                	sd	s5,56(sp)
    80005e16:	f85a                	sd	s6,48(sp)
    80005e18:	f45e                	sd	s7,40(sp)
    80005e1a:	f062                	sd	s8,32(sp)
    80005e1c:	ec66                	sd	s9,24(sp)
    80005e1e:	e86a                	sd	s10,16(sp)
    80005e20:	1880                	addi	s0,sp,112
    80005e22:	892a                	mv	s2,a0
    80005e24:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e26:	00c52c83          	lw	s9,12(a0)
    80005e2a:	001c9c9b          	slliw	s9,s9,0x1
    80005e2e:	1c82                	slli	s9,s9,0x20
    80005e30:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e34:	0002a517          	auipc	a0,0x2a
    80005e38:	2f450513          	addi	a0,a0,756 # 80030128 <disk+0x8128>
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	da8080e7          	jalr	-600(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005e44:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e46:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e48:	00022b97          	auipc	s7,0x22
    80005e4c:	1b8b8b93          	addi	s7,s7,440 # 80028000 <disk>
    80005e50:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80005e52:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e54:	8a4e                	mv	s4,s3
    80005e56:	a051                	j	80005eda <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e58:	00fb86b3          	add	a3,s7,a5
    80005e5c:	96da                	add	a3,a3,s6
    80005e5e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e62:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e64:	0207c563          	bltz	a5,80005e8e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e68:	2485                	addiw	s1,s1,1
    80005e6a:	0711                	addi	a4,a4,4
    80005e6c:	25548463          	beq	s1,s5,800060b4 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80005e70:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005e72:	0002a697          	auipc	a3,0x2a
    80005e76:	1a668693          	addi	a3,a3,422 # 80030018 <disk+0x8018>
    80005e7a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005e7c:	0006c583          	lbu	a1,0(a3)
    80005e80:	fde1                	bnez	a1,80005e58 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e82:	2785                	addiw	a5,a5,1
    80005e84:	0685                	addi	a3,a3,1
    80005e86:	ff879be3          	bne	a5,s8,80005e7c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e8a:	57fd                	li	a5,-1
    80005e8c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005e8e:	02905a63          	blez	s1,80005ec2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e92:	f9042503          	lw	a0,-112(s0)
    80005e96:	00000097          	auipc	ra,0x0
    80005e9a:	d90080e7          	jalr	-624(ra) # 80005c26 <free_desc>
      for(int j = 0; j < i; j++)
    80005e9e:	4785                	li	a5,1
    80005ea0:	0297d163          	bge	a5,s1,80005ec2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ea4:	f9442503          	lw	a0,-108(s0)
    80005ea8:	00000097          	auipc	ra,0x0
    80005eac:	d7e080e7          	jalr	-642(ra) # 80005c26 <free_desc>
      for(int j = 0; j < i; j++)
    80005eb0:	4789                	li	a5,2
    80005eb2:	0097d863          	bge	a5,s1,80005ec2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005eb6:	f9842503          	lw	a0,-104(s0)
    80005eba:	00000097          	auipc	ra,0x0
    80005ebe:	d6c080e7          	jalr	-660(ra) # 80005c26 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ec2:	0002a597          	auipc	a1,0x2a
    80005ec6:	26658593          	addi	a1,a1,614 # 80030128 <disk+0x8128>
    80005eca:	0002a517          	auipc	a0,0x2a
    80005ece:	14e50513          	addi	a0,a0,334 # 80030018 <disk+0x8018>
    80005ed2:	ffffc097          	auipc	ra,0xffffc
    80005ed6:	1dc080e7          	jalr	476(ra) # 800020ae <sleep>
  for(int i = 0; i < 3; i++){
    80005eda:	f9040713          	addi	a4,s0,-112
    80005ede:	84ce                	mv	s1,s3
    80005ee0:	bf41                	j	80005e70 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005ee2:	6705                	lui	a4,0x1
    80005ee4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005ee8:	972e                	add	a4,a4,a1
    80005eea:	0712                	slli	a4,a4,0x4
    80005eec:	00022697          	auipc	a3,0x22
    80005ef0:	11468693          	addi	a3,a3,276 # 80028000 <disk>
    80005ef4:	9736                	add	a4,a4,a3
    80005ef6:	4685                	li	a3,1
    80005ef8:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005efc:	6705                	lui	a4,0x1
    80005efe:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005f02:	972e                	add	a4,a4,a1
    80005f04:	0712                	slli	a4,a4,0x4
    80005f06:	00022697          	auipc	a3,0x22
    80005f0a:	0fa68693          	addi	a3,a3,250 # 80028000 <disk>
    80005f0e:	9736                	add	a4,a4,a3
    80005f10:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005f14:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005f18:	7661                	lui	a2,0xffff8
    80005f1a:	963e                	add	a2,a2,a5
    80005f1c:	0002a697          	auipc	a3,0x2a
    80005f20:	0e468693          	addi	a3,a3,228 # 80030000 <disk+0x8000>
    80005f24:	6298                	ld	a4,0(a3)
    80005f26:	9732                	add	a4,a4,a2
    80005f28:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f2a:	6298                	ld	a4,0(a3)
    80005f2c:	9732                	add	a4,a4,a2
    80005f2e:	4541                	li	a0,16
    80005f30:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f32:	6298                	ld	a4,0(a3)
    80005f34:	9732                	add	a4,a4,a2
    80005f36:	4505                	li	a0,1
    80005f38:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f3c:	f9442703          	lw	a4,-108(s0)
    80005f40:	6288                	ld	a0,0(a3)
    80005f42:	962a                	add	a2,a2,a0
    80005f44:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc400e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f48:	0712                	slli	a4,a4,0x4
    80005f4a:	6290                	ld	a2,0(a3)
    80005f4c:	963a                	add	a2,a2,a4
    80005f4e:	05890513          	addi	a0,s2,88
    80005f52:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f54:	6294                	ld	a3,0(a3)
    80005f56:	96ba                	add	a3,a3,a4
    80005f58:	40000613          	li	a2,1024
    80005f5c:	c690                	sw	a2,8(a3)
  if(write)
    80005f5e:	140d0263          	beqz	s10,800060a2 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f62:	0002a697          	auipc	a3,0x2a
    80005f66:	09e6b683          	ld	a3,158(a3) # 80030000 <disk+0x8000>
    80005f6a:	96ba                	add	a3,a3,a4
    80005f6c:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f70:	00022817          	auipc	a6,0x22
    80005f74:	09080813          	addi	a6,a6,144 # 80028000 <disk>
    80005f78:	0002a697          	auipc	a3,0x2a
    80005f7c:	08868693          	addi	a3,a3,136 # 80030000 <disk+0x8000>
    80005f80:	6290                	ld	a2,0(a3)
    80005f82:	963a                	add	a2,a2,a4
    80005f84:	00c65503          	lhu	a0,12(a2)
    80005f88:	00156513          	ori	a0,a0,1
    80005f8c:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80005f90:	f9842603          	lw	a2,-104(s0)
    80005f94:	6288                	ld	a0,0(a3)
    80005f96:	972a                	add	a4,a4,a0
    80005f98:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f9c:	6705                	lui	a4,0x1
    80005f9e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005fa2:	972e                	add	a4,a4,a1
    80005fa4:	0712                	slli	a4,a4,0x4
    80005fa6:	9742                	add	a4,a4,a6
    80005fa8:	557d                	li	a0,-1
    80005faa:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fae:	0612                	slli	a2,a2,0x4
    80005fb0:	6288                	ld	a0,0(a3)
    80005fb2:	9532                	add	a0,a0,a2
    80005fb4:	03078793          	addi	a5,a5,48
    80005fb8:	97c2                	add	a5,a5,a6
    80005fba:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    80005fbc:	629c                	ld	a5,0(a3)
    80005fbe:	97b2                	add	a5,a5,a2
    80005fc0:	4505                	li	a0,1
    80005fc2:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fc4:	629c                	ld	a5,0(a3)
    80005fc6:	97b2                	add	a5,a5,a2
    80005fc8:	4809                	li	a6,2
    80005fca:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fce:	629c                	ld	a5,0(a3)
    80005fd0:	963e                	add	a2,a2,a5
    80005fd2:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fd6:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    80005fda:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fde:	6698                	ld	a4,8(a3)
    80005fe0:	00275783          	lhu	a5,2(a4)
    80005fe4:	8b9d                	andi	a5,a5,7
    80005fe6:	0786                	slli	a5,a5,0x1
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005fee:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005ff2:	6698                	ld	a4,8(a3)
    80005ff4:	00275783          	lhu	a5,2(a4)
    80005ff8:	2785                	addiw	a5,a5,1
    80005ffa:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005ffe:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006002:	100017b7          	lui	a5,0x10001
    80006006:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000600a:	00492703          	lw	a4,4(s2)
    8000600e:	4785                	li	a5,1
    80006010:	02f71163          	bne	a4,a5,80006032 <virtio_disk_rw+0x22c>
    sleep(b, &disk.vdisk_lock);
    80006014:	0002a997          	auipc	s3,0x2a
    80006018:	11498993          	addi	s3,s3,276 # 80030128 <disk+0x8128>
  while(b->disk == 1) {
    8000601c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000601e:	85ce                	mv	a1,s3
    80006020:	854a                	mv	a0,s2
    80006022:	ffffc097          	auipc	ra,0xffffc
    80006026:	08c080e7          	jalr	140(ra) # 800020ae <sleep>
  while(b->disk == 1) {
    8000602a:	00492783          	lw	a5,4(s2)
    8000602e:	fe9788e3          	beq	a5,s1,8000601e <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006032:	f9042903          	lw	s2,-112(s0)
    80006036:	6785                	lui	a5,0x1
    80006038:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    8000603c:	97ca                	add	a5,a5,s2
    8000603e:	0792                	slli	a5,a5,0x4
    80006040:	00022717          	auipc	a4,0x22
    80006044:	fc070713          	addi	a4,a4,-64 # 80028000 <disk>
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000604e:	0002a997          	auipc	s3,0x2a
    80006052:	fb298993          	addi	s3,s3,-78 # 80030000 <disk+0x8000>
    80006056:	00491713          	slli	a4,s2,0x4
    8000605a:	0009b783          	ld	a5,0(s3)
    8000605e:	97ba                	add	a5,a5,a4
    80006060:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006064:	854a                	mv	a0,s2
    80006066:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000606a:	00000097          	auipc	ra,0x0
    8000606e:	bbc080e7          	jalr	-1092(ra) # 80005c26 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006072:	8885                	andi	s1,s1,1
    80006074:	f0ed                	bnez	s1,80006056 <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006076:	0002a517          	auipc	a0,0x2a
    8000607a:	0b250513          	addi	a0,a0,178 # 80030128 <disk+0x8128>
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	c1a080e7          	jalr	-998(ra) # 80000c98 <release>
}
    80006086:	70a6                	ld	ra,104(sp)
    80006088:	7406                	ld	s0,96(sp)
    8000608a:	64e6                	ld	s1,88(sp)
    8000608c:	6946                	ld	s2,80(sp)
    8000608e:	69a6                	ld	s3,72(sp)
    80006090:	6a06                	ld	s4,64(sp)
    80006092:	7ae2                	ld	s5,56(sp)
    80006094:	7b42                	ld	s6,48(sp)
    80006096:	7ba2                	ld	s7,40(sp)
    80006098:	7c02                	ld	s8,32(sp)
    8000609a:	6ce2                	ld	s9,24(sp)
    8000609c:	6d42                	ld	s10,16(sp)
    8000609e:	6165                	addi	sp,sp,112
    800060a0:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060a2:	0002a697          	auipc	a3,0x2a
    800060a6:	f5e6b683          	ld	a3,-162(a3) # 80030000 <disk+0x8000>
    800060aa:	96ba                	add	a3,a3,a4
    800060ac:	4609                	li	a2,2
    800060ae:	00c69623          	sh	a2,12(a3)
    800060b2:	bd7d                	j	80005f70 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060b4:	f9042583          	lw	a1,-112(s0)
    800060b8:	6785                	lui	a5,0x1
    800060ba:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800060be:	97ae                	add	a5,a5,a1
    800060c0:	0792                	slli	a5,a5,0x4
    800060c2:	00022517          	auipc	a0,0x22
    800060c6:	fe650513          	addi	a0,a0,-26 # 800280a8 <disk+0xa8>
    800060ca:	953e                	add	a0,a0,a5
  if(write)
    800060cc:	e00d1be3          	bnez	s10,80005ee2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060d0:	6705                	lui	a4,0x1
    800060d2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060d6:	972e                	add	a4,a4,a1
    800060d8:	0712                	slli	a4,a4,0x4
    800060da:	00022697          	auipc	a3,0x22
    800060de:	f2668693          	addi	a3,a3,-218 # 80028000 <disk>
    800060e2:	9736                	add	a4,a4,a3
    800060e4:	0a072423          	sw	zero,168(a4)
    800060e8:	bd11                	j	80005efc <virtio_disk_rw+0xf6>

00000000800060ea <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060ea:	7179                	addi	sp,sp,-48
    800060ec:	f406                	sd	ra,40(sp)
    800060ee:	f022                	sd	s0,32(sp)
    800060f0:	ec26                	sd	s1,24(sp)
    800060f2:	e84a                	sd	s2,16(sp)
    800060f4:	e44e                	sd	s3,8(sp)
    800060f6:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    800060f8:	0002a517          	auipc	a0,0x2a
    800060fc:	03050513          	addi	a0,a0,48 # 80030128 <disk+0x8128>
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	ae4080e7          	jalr	-1308(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006108:	10001737          	lui	a4,0x10001
    8000610c:	533c                	lw	a5,96(a4)
    8000610e:	8b8d                	andi	a5,a5,3
    80006110:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006112:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006116:	0002a797          	auipc	a5,0x2a
    8000611a:	eea78793          	addi	a5,a5,-278 # 80030000 <disk+0x8000>
    8000611e:	6b94                	ld	a3,16(a5)
    80006120:	0207d703          	lhu	a4,32(a5)
    80006124:	0026d783          	lhu	a5,2(a3)
    80006128:	06f70363          	beq	a4,a5,8000618e <virtio_disk_intr+0xa4>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000612c:	00022997          	auipc	s3,0x22
    80006130:	ed498993          	addi	s3,s3,-300 # 80028000 <disk>
    80006134:	0002a497          	auipc	s1,0x2a
    80006138:	ecc48493          	addi	s1,s1,-308 # 80030000 <disk+0x8000>

    if(disk.info[id].status != 0)
    8000613c:	6905                	lui	s2,0x1
    8000613e:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    80006142:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006146:	6898                	ld	a4,16(s1)
    80006148:	0204d783          	lhu	a5,32(s1)
    8000614c:	8b9d                	andi	a5,a5,7
    8000614e:	078e                	slli	a5,a5,0x3
    80006150:	97ba                	add	a5,a5,a4
    80006152:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006154:	01278733          	add	a4,a5,s2
    80006158:	0712                	slli	a4,a4,0x4
    8000615a:	974e                	add	a4,a4,s3
    8000615c:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006160:	e731                	bnez	a4,800061ac <virtio_disk_intr+0xc2>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006162:	97ca                	add	a5,a5,s2
    80006164:	0792                	slli	a5,a5,0x4
    80006166:	97ce                	add	a5,a5,s3
    80006168:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    8000616a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000616e:	ffffc097          	auipc	ra,0xffffc
    80006172:	0cc080e7          	jalr	204(ra) # 8000223a <wakeup>

    disk.used_idx += 1;
    80006176:	0204d783          	lhu	a5,32(s1)
    8000617a:	2785                	addiw	a5,a5,1
    8000617c:	17c2                	slli	a5,a5,0x30
    8000617e:	93c1                	srli	a5,a5,0x30
    80006180:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006184:	6898                	ld	a4,16(s1)
    80006186:	00275703          	lhu	a4,2(a4)
    8000618a:	faf71ce3          	bne	a4,a5,80006142 <virtio_disk_intr+0x58>
  }

  release(&disk.vdisk_lock);
    8000618e:	0002a517          	auipc	a0,0x2a
    80006192:	f9a50513          	addi	a0,a0,-102 # 80030128 <disk+0x8128>
    80006196:	ffffb097          	auipc	ra,0xffffb
    8000619a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
}
    8000619e:	70a2                	ld	ra,40(sp)
    800061a0:	7402                	ld	s0,32(sp)
    800061a2:	64e2                	ld	s1,24(sp)
    800061a4:	6942                	ld	s2,16(sp)
    800061a6:	69a2                	ld	s3,8(sp)
    800061a8:	6145                	addi	sp,sp,48
    800061aa:	8082                	ret
      panic("virtio_disk_intr status");
    800061ac:	00002517          	auipc	a0,0x2
    800061b0:	6bc50513          	addi	a0,a0,1724 # 80008868 <syscalls+0x3b0>
    800061b4:	ffffa097          	auipc	ra,0xffffa
    800061b8:	38a080e7          	jalr	906(ra) # 8000053e <panic>
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
