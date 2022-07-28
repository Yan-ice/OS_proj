
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
    80000068:	bdc78793          	addi	a5,a5,-1060 # 80005c40 <timervec>
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
    80000130:	45c080e7          	jalr	1116(ra) # 80002588 <either_copyin>
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
    800001c8:	8ea080e7          	jalr	-1814(ra) # 80001aae <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	fa6080e7          	jalr	-90(ra) # 8000217a <sleep>
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
    80000214:	322080e7          	jalr	802(ra) # 80002532 <either_copyout>
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
    800002f6:	2ec080e7          	jalr	748(ra) # 800025de <procdump>
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
    8000044a:	ed4080e7          	jalr	-300(ra) # 8000231a <wakeup>
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
    800008a4:	a7a080e7          	jalr	-1414(ra) # 8000231a <wakeup>
    
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
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	84e080e7          	jalr	-1970(ra) # 8000217a <sleep>
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
    80000b82:	f14080e7          	jalr	-236(ra) # 80001a92 <mycpu>
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
    80000bb4:	ee2080e7          	jalr	-286(ra) # 80001a92 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	ed6080e7          	jalr	-298(ra) # 80001a92 <mycpu>
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
    80000bd8:	ebe080e7          	jalr	-322(ra) # 80001a92 <mycpu>
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
    80000c18:	e7e080e7          	jalr	-386(ra) # 80001a92 <mycpu>
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
    80000c44:	e52080e7          	jalr	-430(ra) # 80001a92 <mycpu>
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
    80000e9a:	bec080e7          	jalr	-1044(ra) # 80001a82 <cpuid>
    __sync_synchronize();
    started = 1;
    printf("Init succeed\n");
  } else {
   // return;
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
    80000eb6:	bd0080e7          	jalr	-1072(ra) # 80001a82 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	27c50513          	addi	a0,a0,636 # 80008138 <digits+0xf8>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	128080e7          	jalr	296(ra) # 80000ff4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	84a080e7          	jalr	-1974(ra) # 8000271e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	da4080e7          	jalr	-604(ra) # 80005c80 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0e4080e7          	jalr	228(ra) # 80001fc8 <scheduler>
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
    80000f58:	400080e7          	jalr	1024(ra) # 80001354 <kvminit>
    printf("turning on paging...\n");
    80000f5c:	00007517          	auipc	a0,0x7
    80000f60:	19450513          	addi	a0,a0,404 # 800080f0 <digits+0xb0>
    80000f64:	fffff097          	auipc	ra,0xfffff
    80000f68:	624080e7          	jalr	1572(ra) # 80000588 <printf>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	088080e7          	jalr	136(ra) # 80000ff4 <kvminithart>
    printf("initing process table...\n");
    80000f74:	00007517          	auipc	a0,0x7
    80000f78:	19450513          	addi	a0,a0,404 # 80008108 <digits+0xc8>
    80000f7c:	fffff097          	auipc	ra,0xfffff
    80000f80:	60c080e7          	jalr	1548(ra) # 80000588 <printf>
    procinit();      // process table
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	a4e080e7          	jalr	-1458(ra) # 800019d2 <procinit>
    trapinit();      // trap vectors
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	76a080e7          	jalr	1898(ra) # 800026f6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	78a080e7          	jalr	1930(ra) # 8000271e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	cce080e7          	jalr	-818(ra) # 80005c6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa4:	00005097          	auipc	ra,0x5
    80000fa8:	cdc080e7          	jalr	-804(ra) # 80005c80 <plicinithart>
    binit();         // buffer cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	eb4080e7          	jalr	-332(ra) # 80002e60 <binit>
    iinit();         // inode table
    80000fb4:	00002097          	auipc	ra,0x2
    80000fb8:	544080e7          	jalr	1348(ra) # 800034f8 <iinit>
    fileinit();      // file table
    80000fbc:	00003097          	auipc	ra,0x3
    80000fc0:	4ee080e7          	jalr	1262(ra) # 800044aa <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc4:	00005097          	auipc	ra,0x5
    80000fc8:	dde080e7          	jalr	-546(ra) # 80005da2 <virtio_disk_init>
    userinit();      // first user process
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	dba080e7          	jalr	-582(ra) # 80001d86 <userinit>
    __sync_synchronize();
    80000fd4:	0ff0000f          	fence
    started = 1;
    80000fd8:	4785                	li	a5,1
    80000fda:	0000b717          	auipc	a4,0xb
    80000fde:	02f72f23          	sw	a5,62(a4) # 8000c018 <started>
    printf("Init succeed\n");
    80000fe2:	00007517          	auipc	a0,0x7
    80000fe6:	14650513          	addi	a0,a0,326 # 80008128 <digits+0xe8>
    80000fea:	fffff097          	auipc	ra,0xfffff
    80000fee:	59e080e7          	jalr	1438(ra) # 80000588 <printf>
    80000ff2:	bdcd                	j	80000ee4 <main+0x56>

0000000080000ff4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000ff4:	1101                	addi	sp,sp,-32
    80000ff6:	ec06                	sd	ra,24(sp)
    80000ff8:	e822                	sd	s0,16(sp)
    80000ffa:	e426                	sd	s1,8(sp)
    80000ffc:	1000                	addi	s0,sp,32
  printf("setting SATP to address %x...\n",kernel_pagetable);
    80000ffe:	0000b497          	auipc	s1,0xb
    80001002:	02248493          	addi	s1,s1,34 # 8000c020 <kernel_pagetable>
    80001006:	608c                	ld	a1,0(s1)
    80001008:	00007517          	auipc	a0,0x7
    8000100c:	14850513          	addi	a0,a0,328 # 80008150 <digits+0x110>
    80001010:	fffff097          	auipc	ra,0xfffff
    80001014:	578080e7          	jalr	1400(ra) # 80000588 <printf>
  w_satp(MAKE_SATP(kernel_pagetable));
    80001018:	609c                	ld	a5,0(s1)
    8000101a:	83b9                	srli	a5,a5,0xe
    8000101c:	577d                	li	a4,-1
    8000101e:	177e                	slli	a4,a4,0x3f
    80001020:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001022:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001026:	12000073          	sfence.vma
  sfence_vma();

}
    8000102a:	60e2                	ld	ra,24(sp)
    8000102c:	6442                	ld	s0,16(sp)
    8000102e:	64a2                	ld	s1,8(sp)
    80001030:	6105                	addi	sp,sp,32
    80001032:	8082                	ret

0000000080001034 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001034:	7139                	addi	sp,sp,-64
    80001036:	fc06                	sd	ra,56(sp)
    80001038:	f822                	sd	s0,48(sp)
    8000103a:	f426                	sd	s1,40(sp)
    8000103c:	f04a                	sd	s2,32(sp)
    8000103e:	ec4e                	sd	s3,24(sp)
    80001040:	e852                	sd	s4,16(sp)
    80001042:	e456                	sd	s5,8(sp)
    80001044:	e05a                	sd	s6,0(sp)
    80001046:	0080                	addi	s0,sp,64
    80001048:	84aa                	mv	s1,a0
    8000104a:	89ae                	mv	s3,a1
    8000104c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000104e:	57fd                	li	a5,-1
    80001050:	83ed                	srli	a5,a5,0x1b
    80001052:	02000a13          	li	s4,32
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001056:	4b39                	li	s6,14
  if(va >= MAXVA)
    80001058:	04b7f263          	bgeu	a5,a1,8000109c <walk+0x68>
    panic("walk");
    8000105c:	00007517          	auipc	a0,0x7
    80001060:	11450513          	addi	a0,a0,276 # 80008170 <digits+0x130>
    80001064:	fffff097          	auipc	ra,0xfffff
    80001068:	4da080e7          	jalr	1242(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000106c:	060a8663          	beqz	s5,800010d8 <walk+0xa4>
    80001070:	00000097          	auipc	ra,0x0
    80001074:	a84080e7          	jalr	-1404(ra) # 80000af4 <kalloc>
    80001078:	84aa                	mv	s1,a0
    8000107a:	c529                	beqz	a0,800010c4 <walk+0x90>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000107c:	6611                	lui	a2,0x4
    8000107e:	4581                	li	a1,0
    80001080:	00000097          	auipc	ra,0x0
    80001084:	c60080e7          	jalr	-928(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001088:	00e4d793          	srli	a5,s1,0xe
    8000108c:	07aa                	slli	a5,a5,0xa
    8000108e:	0017e793          	ori	a5,a5,1
    80001092:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001096:	3a5d                	addiw	s4,s4,-9
    80001098:	036a0063          	beq	s4,s6,800010b8 <walk+0x84>
    pte_t *pte = &pagetable[PX(level, va)];
    8000109c:	0149d933          	srl	s2,s3,s4
    800010a0:	1ff97913          	andi	s2,s2,511
    800010a4:	090e                	slli	s2,s2,0x3
    800010a6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a8:	00093483          	ld	s1,0(s2)
    800010ac:	0014f793          	andi	a5,s1,1
    800010b0:	dfd5                	beqz	a5,8000106c <walk+0x38>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010b2:	80a9                	srli	s1,s1,0xa
    800010b4:	04ba                	slli	s1,s1,0xe
    800010b6:	b7c5                	j	80001096 <walk+0x62>
    }
  }
 /// printf("get final PTE %x at %dth pte in pagetable %x for VA %x, which PA is %x \n",pagetable[PX(0,va)],PX(0,va),pagetable, va, PTE2PA(pagetable[PX(0,va)]));
  return &pagetable[PX(0, va)];
    800010b8:	00e9d513          	srli	a0,s3,0xe
    800010bc:	1ff57513          	andi	a0,a0,511
    800010c0:	050e                	slli	a0,a0,0x3
    800010c2:	9526                	add	a0,a0,s1
}
    800010c4:	70e2                	ld	ra,56(sp)
    800010c6:	7442                	ld	s0,48(sp)
    800010c8:	74a2                	ld	s1,40(sp)
    800010ca:	7902                	ld	s2,32(sp)
    800010cc:	69e2                	ld	s3,24(sp)
    800010ce:	6a42                	ld	s4,16(sp)
    800010d0:	6aa2                	ld	s5,8(sp)
    800010d2:	6b02                	ld	s6,0(sp)
    800010d4:	6121                	addi	sp,sp,64
    800010d6:	8082                	ret
        return 0;
    800010d8:	4501                	li	a0,0
    800010da:	b7ed                	j	800010c4 <walk+0x90>

00000000800010dc <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010dc:	57fd                	li	a5,-1
    800010de:	83ed                	srli	a5,a5,0x1b
    800010e0:	00b7f463          	bgeu	a5,a1,800010e8 <walkaddr+0xc>
    return 0;
    800010e4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010e6:	8082                	ret
{
    800010e8:	1141                	addi	sp,sp,-16
    800010ea:	e406                	sd	ra,8(sp)
    800010ec:	e022                	sd	s0,0(sp)
    800010ee:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010f0:	4601                	li	a2,0
    800010f2:	00000097          	auipc	ra,0x0
    800010f6:	f42080e7          	jalr	-190(ra) # 80001034 <walk>
  if(pte == 0)
    800010fa:	c105                	beqz	a0,8000111a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010fc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010fe:	0117f693          	andi	a3,a5,17
    80001102:	4745                	li	a4,17
    return 0;
    80001104:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001106:	00e68663          	beq	a3,a4,80001112 <walkaddr+0x36>
}
    8000110a:	60a2                	ld	ra,8(sp)
    8000110c:	6402                	ld	s0,0(sp)
    8000110e:	0141                	addi	sp,sp,16
    80001110:	8082                	ret
  pa = PTE2PA(*pte);
    80001112:	00a7d513          	srli	a0,a5,0xa
    80001116:	053a                	slli	a0,a0,0xe
  return pa;
    80001118:	bfcd                	j	8000110a <walkaddr+0x2e>
    return 0;
    8000111a:	4501                	li	a0,0
    8000111c:	b7fd                	j	8000110a <walkaddr+0x2e>

000000008000111e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000111e:	715d                	addi	sp,sp,-80
    80001120:	e486                	sd	ra,72(sp)
    80001122:	e0a2                	sd	s0,64(sp)
    80001124:	fc26                	sd	s1,56(sp)
    80001126:	f84a                	sd	s2,48(sp)
    80001128:	f44e                	sd	s3,40(sp)
    8000112a:	f052                	sd	s4,32(sp)
    8000112c:	ec56                	sd	s5,24(sp)
    8000112e:	e85a                	sd	s6,16(sp)
    80001130:	e45e                	sd	s7,8(sp)
    80001132:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;


  if(size == 0)
    80001134:	ce05                	beqz	a2,8000116c <mappages+0x4e>
    80001136:	8aaa                	mv	s5,a0
    80001138:	8a36                	mv	s4,a3
    8000113a:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    8000113c:	77f1                	lui	a5,0xffffc
    8000113e:	00f5f4b3          	and	s1,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001142:	15fd                	addi	a1,a1,-1
    80001144:	00c589b3          	add	s3,a1,a2
    80001148:	00f9f9b3          	and	s3,s3,a5
  printf("mapping VA %x to PA %x in pagetable %x\n",a,pa,pagetable);
    8000114c:	86aa                	mv	a3,a0
    8000114e:	8652                	mv	a2,s4
    80001150:	85a6                	mv	a1,s1
    80001152:	00007517          	auipc	a0,0x7
    80001156:	03650513          	addi	a0,a0,54 # 80008188 <digits+0x148>
    8000115a:	fffff097          	auipc	ra,0xfffff
    8000115e:	42e080e7          	jalr	1070(ra) # 80000588 <printf>
  a = PGROUNDDOWN(va);
    80001162:	8926                	mv	s2,s1
    80001164:	409a0a33          	sub	s4,s4,s1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001168:	6b91                	lui	s7,0x4
    8000116a:	a015                	j	8000118e <mappages+0x70>
    panic("mappages: size");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	00c50513          	addi	a0,a0,12 # 80008178 <digits+0x138>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	3ca080e7          	jalr	970(ra) # 8000053e <panic>
      panic("mappages: remap");
    8000117c:	00007517          	auipc	a0,0x7
    80001180:	03450513          	addi	a0,a0,52 # 800081b0 <digits+0x170>
    80001184:	fffff097          	auipc	ra,0xfffff
    80001188:	3ba080e7          	jalr	954(ra) # 8000053e <panic>
    a += PGSIZE;
    8000118c:	995e                	add	s2,s2,s7
  for(;;){
    8000118e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001192:	4605                	li	a2,1
    80001194:	85ca                	mv	a1,s2
    80001196:	8556                	mv	a0,s5
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	e9c080e7          	jalr	-356(ra) # 80001034 <walk>
    800011a0:	cd19                	beqz	a0,800011be <mappages+0xa0>
    if(*pte & PTE_V)
    800011a2:	611c                	ld	a5,0(a0)
    800011a4:	8b85                	andi	a5,a5,1
    800011a6:	fbf9                	bnez	a5,8000117c <mappages+0x5e>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011a8:	80b9                	srli	s1,s1,0xe
    800011aa:	04aa                	slli	s1,s1,0xa
    800011ac:	0164e4b3          	or	s1,s1,s6
    800011b0:	0014e493          	ori	s1,s1,1
    800011b4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011b6:	fd391be3          	bne	s2,s3,8000118c <mappages+0x6e>
    pa += PGSIZE;
  }
  return 0;
    800011ba:	4501                	li	a0,0
    800011bc:	a011                	j	800011c0 <mappages+0xa2>
      return -1;
    800011be:	557d                	li	a0,-1
}
    800011c0:	60a6                	ld	ra,72(sp)
    800011c2:	6406                	ld	s0,64(sp)
    800011c4:	74e2                	ld	s1,56(sp)
    800011c6:	7942                	ld	s2,48(sp)
    800011c8:	79a2                	ld	s3,40(sp)
    800011ca:	7a02                	ld	s4,32(sp)
    800011cc:	6ae2                	ld	s5,24(sp)
    800011ce:	6b42                	ld	s6,16(sp)
    800011d0:	6ba2                	ld	s7,8(sp)
    800011d2:	6161                	addi	sp,sp,80
    800011d4:	8082                	ret

00000000800011d6 <kvmmap>:
{
    800011d6:	1141                	addi	sp,sp,-16
    800011d8:	e406                	sd	ra,8(sp)
    800011da:	e022                	sd	s0,0(sp)
    800011dc:	0800                	addi	s0,sp,16
    800011de:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011e0:	86b2                	mv	a3,a2
    800011e2:	863e                	mv	a2,a5
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f3a080e7          	jalr	-198(ra) # 8000111e <mappages>
    800011ec:	e509                	bnez	a0,800011f6 <kvmmap+0x20>
}
    800011ee:	60a2                	ld	ra,8(sp)
    800011f0:	6402                	ld	s0,0(sp)
    800011f2:	0141                	addi	sp,sp,16
    800011f4:	8082                	ret
    panic("kvmmap");
    800011f6:	00007517          	auipc	a0,0x7
    800011fa:	fca50513          	addi	a0,a0,-54 # 800081c0 <digits+0x180>
    800011fe:	fffff097          	auipc	ra,0xfffff
    80001202:	340080e7          	jalr	832(ra) # 8000053e <panic>

0000000080001206 <kvmmake>:
{
    80001206:	7179                	addi	sp,sp,-48
    80001208:	f406                	sd	ra,40(sp)
    8000120a:	f022                	sd	s0,32(sp)
    8000120c:	ec26                	sd	s1,24(sp)
    8000120e:	e84a                	sd	s2,16(sp)
    80001210:	e44e                	sd	s3,8(sp)
    80001212:	1800                	addi	s0,sp,48
  kpgtbl = (pagetable_t) kalloc();
    80001214:	00000097          	auipc	ra,0x0
    80001218:	8e0080e7          	jalr	-1824(ra) # 80000af4 <kalloc>
    8000121c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000121e:	6611                	lui	a2,0x4
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	abe080e7          	jalr	-1346(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4719                	li	a4,6
    8000122c:	6691                	lui	a3,0x4
    8000122e:	10000637          	lui	a2,0x10000
    80001232:	100005b7          	lui	a1,0x10000
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f9e080e7          	jalr	-98(ra) # 800011d6 <kvmmap>
  printf("mapping uart in %x\n", UART0);
    80001240:	100005b7          	lui	a1,0x10000
    80001244:	00007517          	auipc	a0,0x7
    80001248:	f8450513          	addi	a0,a0,-124 # 800081c8 <digits+0x188>
    8000124c:	fffff097          	auipc	ra,0xfffff
    80001250:	33c080e7          	jalr	828(ra) # 80000588 <printf>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001254:	4719                	li	a4,6
    80001256:	6691                	lui	a3,0x4
    80001258:	10004637          	lui	a2,0x10004
    8000125c:	100045b7          	lui	a1,0x10004
    80001260:	8526                	mv	a0,s1
    80001262:	00000097          	auipc	ra,0x0
    80001266:	f74080e7          	jalr	-140(ra) # 800011d6 <kvmmap>
  printf("mapping virtio in %x\n", VIRTIO0);
    8000126a:	100045b7          	lui	a1,0x10004
    8000126e:	00007517          	auipc	a0,0x7
    80001272:	f7250513          	addi	a0,a0,-142 # 800081e0 <digits+0x1a0>
    80001276:	fffff097          	auipc	ra,0xfffff
    8000127a:	312080e7          	jalr	786(ra) # 80000588 <printf>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000127e:	4719                	li	a4,6
    80001280:	004006b7          	lui	a3,0x400
    80001284:	0c000637          	lui	a2,0xc000
    80001288:	0c0005b7          	lui	a1,0xc000
    8000128c:	8526                	mv	a0,s1
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f48080e7          	jalr	-184(ra) # 800011d6 <kvmmap>
  printf("mapping PLIC in %x\n", PLIC);
    80001296:	0c0005b7          	lui	a1,0xc000
    8000129a:	00007517          	auipc	a0,0x7
    8000129e:	f5e50513          	addi	a0,a0,-162 # 800081f8 <digits+0x1b8>
    800012a2:	fffff097          	auipc	ra,0xfffff
    800012a6:	2e6080e7          	jalr	742(ra) # 80000588 <printf>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012aa:	00007917          	auipc	s2,0x7
    800012ae:	d5690913          	addi	s2,s2,-682 # 80008000 <etext>
    800012b2:	4729                	li	a4,10
    800012b4:	80007697          	auipc	a3,0x80007
    800012b8:	d4c68693          	addi	a3,a3,-692 # 8000 <_entry-0x7fff8000>
    800012bc:	4985                	li	s3,1
    800012be:	01f99613          	slli	a2,s3,0x1f
    800012c2:	85b2                	mv	a1,a2
    800012c4:	8526                	mv	a0,s1
    800012c6:	00000097          	auipc	ra,0x0
    800012ca:	f10080e7          	jalr	-240(ra) # 800011d6 <kvmmap>
  printf("mapping kernel text in %x\n", KERNBASE);
    800012ce:	01f99593          	slli	a1,s3,0x1f
    800012d2:	00007517          	auipc	a0,0x7
    800012d6:	f3e50513          	addi	a0,a0,-194 # 80008210 <digits+0x1d0>
    800012da:	fffff097          	auipc	ra,0xfffff
    800012de:	2ae080e7          	jalr	686(ra) # 80000588 <printf>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e2:	4719                	li	a4,6
    800012e4:	46c5                	li	a3,17
    800012e6:	06ee                	slli	a3,a3,0x1b
    800012e8:	412686b3          	sub	a3,a3,s2
    800012ec:	864a                	mv	a2,s2
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8526                	mv	a0,s1
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	ee4080e7          	jalr	-284(ra) # 800011d6 <kvmmap>
  printf("mapping trampoline for trap\n");
    800012fa:	00007517          	auipc	a0,0x7
    800012fe:	f3650513          	addi	a0,a0,-202 # 80008230 <digits+0x1f0>
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	286080e7          	jalr	646(ra) # 80000588 <printf>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000130a:	4729                	li	a4,10
    8000130c:	6691                	lui	a3,0x4
    8000130e:	00006617          	auipc	a2,0x6
    80001312:	cf260613          	addi	a2,a2,-782 # 80007000 <_trampoline>
    80001316:	008005b7          	lui	a1,0x800
    8000131a:	15fd                	addi	a1,a1,-1
    8000131c:	05ba                	slli	a1,a1,0xe
    8000131e:	8526                	mv	a0,s1
    80001320:	00000097          	auipc	ra,0x0
    80001324:	eb6080e7          	jalr	-330(ra) # 800011d6 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001328:	8526                	mv	a0,s1
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	612080e7          	jalr	1554(ra) # 8000193c <proc_mapstacks>
  printf("kernel pagetable created with VA: %x.\n",kpgtbl);
    80001332:	85a6                	mv	a1,s1
    80001334:	00007517          	auipc	a0,0x7
    80001338:	f1c50513          	addi	a0,a0,-228 # 80008250 <digits+0x210>
    8000133c:	fffff097          	auipc	ra,0xfffff
    80001340:	24c080e7          	jalr	588(ra) # 80000588 <printf>
}
    80001344:	8526                	mv	a0,s1
    80001346:	70a2                	ld	ra,40(sp)
    80001348:	7402                	ld	s0,32(sp)
    8000134a:	64e2                	ld	s1,24(sp)
    8000134c:	6942                	ld	s2,16(sp)
    8000134e:	69a2                	ld	s3,8(sp)
    80001350:	6145                	addi	sp,sp,48
    80001352:	8082                	ret

0000000080001354 <kvminit>:
{
    80001354:	1141                	addi	sp,sp,-16
    80001356:	e406                	sd	ra,8(sp)
    80001358:	e022                	sd	s0,0(sp)
    8000135a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	eaa080e7          	jalr	-342(ra) # 80001206 <kvmmake>
    80001364:	0000b797          	auipc	a5,0xb
    80001368:	caa7be23          	sd	a0,-836(a5) # 8000c020 <kernel_pagetable>
}
    8000136c:	60a2                	ld	ra,8(sp)
    8000136e:	6402                	ld	s0,0(sp)
    80001370:	0141                	addi	sp,sp,16
    80001372:	8082                	ret

0000000080001374 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001374:	715d                	addi	sp,sp,-80
    80001376:	e486                	sd	ra,72(sp)
    80001378:	e0a2                	sd	s0,64(sp)
    8000137a:	fc26                	sd	s1,56(sp)
    8000137c:	f84a                	sd	s2,48(sp)
    8000137e:	f44e                	sd	s3,40(sp)
    80001380:	f052                	sd	s4,32(sp)
    80001382:	ec56                	sd	s5,24(sp)
    80001384:	e85a                	sd	s6,16(sp)
    80001386:	e45e                	sd	s7,8(sp)
    80001388:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000138a:	03259793          	slli	a5,a1,0x32
    8000138e:	e795                	bnez	a5,800013ba <uvmunmap+0x46>
    80001390:	8a2a                	mv	s4,a0
    80001392:	892e                	mv	s2,a1
    80001394:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001396:	063a                	slli	a2,a2,0xe
    80001398:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000139e:	6b11                	lui	s6,0x4
    800013a0:	0735e863          	bltu	a1,s3,80001410 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013a4:	60a6                	ld	ra,72(sp)
    800013a6:	6406                	ld	s0,64(sp)
    800013a8:	74e2                	ld	s1,56(sp)
    800013aa:	7942                	ld	s2,48(sp)
    800013ac:	79a2                	ld	s3,40(sp)
    800013ae:	7a02                	ld	s4,32(sp)
    800013b0:	6ae2                	ld	s5,24(sp)
    800013b2:	6b42                	ld	s6,16(sp)
    800013b4:	6ba2                	ld	s7,8(sp)
    800013b6:	6161                	addi	sp,sp,80
    800013b8:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ba:	00007517          	auipc	a0,0x7
    800013be:	ebe50513          	addi	a0,a0,-322 # 80008278 <digits+0x238>
    800013c2:	fffff097          	auipc	ra,0xfffff
    800013c6:	17c080e7          	jalr	380(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	ec650513          	addi	a0,a0,-314 # 80008290 <digits+0x250>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	ec650513          	addi	a0,a0,-314 # 800082a0 <digits+0x260>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800013ea:	00007517          	auipc	a0,0x7
    800013ee:	ece50513          	addi	a0,a0,-306 # 800082b8 <digits+0x278>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800013fa:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013fc:	053a                	slli	a0,a0,0xe
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	5fa080e7          	jalr	1530(ra) # 800009f8 <kfree>
    *pte = 0;
    80001406:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000140a:	995a                	add	s2,s2,s6
    8000140c:	f9397ce3          	bgeu	s2,s3,800013a4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001410:	4601                	li	a2,0
    80001412:	85ca                	mv	a1,s2
    80001414:	8552                	mv	a0,s4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	c1e080e7          	jalr	-994(ra) # 80001034 <walk>
    8000141e:	84aa                	mv	s1,a0
    80001420:	d54d                	beqz	a0,800013ca <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001422:	6108                	ld	a0,0(a0)
    80001424:	00157793          	andi	a5,a0,1
    80001428:	dbcd                	beqz	a5,800013da <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000142a:	3ff57793          	andi	a5,a0,1023
    8000142e:	fb778ee3          	beq	a5,s7,800013ea <uvmunmap+0x76>
    if(do_free){
    80001432:	fc0a8ae3          	beqz	s5,80001406 <uvmunmap+0x92>
    80001436:	b7d1                	j	800013fa <uvmunmap+0x86>

0000000080001438 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001438:	1101                	addi	sp,sp,-32
    8000143a:	ec06                	sd	ra,24(sp)
    8000143c:	e822                	sd	s0,16(sp)
    8000143e:	e426                	sd	s1,8(sp)
    80001440:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6b2080e7          	jalr	1714(ra) # 80000af4 <kalloc>
    8000144a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000144c:	c519                	beqz	a0,8000145a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000144e:	6611                	lui	a2,0x4
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	88e080e7          	jalr	-1906(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000145a:	8526                	mv	a0,s1
    8000145c:	60e2                	ld	ra,24(sp)
    8000145e:	6442                	ld	s0,16(sp)
    80001460:	64a2                	ld	s1,8(sp)
    80001462:	6105                	addi	sp,sp,32
    80001464:	8082                	ret

0000000080001466 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001466:	7179                	addi	sp,sp,-48
    80001468:	f406                	sd	ra,40(sp)
    8000146a:	f022                	sd	s0,32(sp)
    8000146c:	ec26                	sd	s1,24(sp)
    8000146e:	e84a                	sd	s2,16(sp)
    80001470:	e44e                	sd	s3,8(sp)
    80001472:	e052                	sd	s4,0(sp)
    80001474:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001476:	6791                	lui	a5,0x4
    80001478:	04f67863          	bgeu	a2,a5,800014c8 <uvminit+0x62>
    8000147c:	8a2a                	mv	s4,a0
    8000147e:	89ae                	mv	s3,a1
    80001480:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	672080e7          	jalr	1650(ra) # 80000af4 <kalloc>
    8000148a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000148c:	6611                	lui	a2,0x4
    8000148e:	4581                	li	a1,0
    80001490:	00000097          	auipc	ra,0x0
    80001494:	850080e7          	jalr	-1968(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001498:	4779                	li	a4,30
    8000149a:	86ca                	mv	a3,s2
    8000149c:	6611                	lui	a2,0x4
    8000149e:	4581                	li	a1,0
    800014a0:	8552                	mv	a0,s4
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	c7c080e7          	jalr	-900(ra) # 8000111e <mappages>
  memmove(mem, src, sz);
    800014aa:	8626                	mv	a2,s1
    800014ac:	85ce                	mv	a1,s3
    800014ae:	854a                	mv	a0,s2
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	890080e7          	jalr	-1904(ra) # 80000d40 <memmove>
}
    800014b8:	70a2                	ld	ra,40(sp)
    800014ba:	7402                	ld	s0,32(sp)
    800014bc:	64e2                	ld	s1,24(sp)
    800014be:	6942                	ld	s2,16(sp)
    800014c0:	69a2                	ld	s3,8(sp)
    800014c2:	6a02                	ld	s4,0(sp)
    800014c4:	6145                	addi	sp,sp,48
    800014c6:	8082                	ret
    panic("inituvm: more than a page");
    800014c8:	00007517          	auipc	a0,0x7
    800014cc:	e0850513          	addi	a0,a0,-504 # 800082d0 <digits+0x290>
    800014d0:	fffff097          	auipc	ra,0xfffff
    800014d4:	06e080e7          	jalr	110(ra) # 8000053e <panic>

00000000800014d8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d8:	1101                	addi	sp,sp,-32
    800014da:	ec06                	sd	ra,24(sp)
    800014dc:	e822                	sd	s0,16(sp)
    800014de:	e426                	sd	s1,8(sp)
    800014e0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014e2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014e4:	00b67d63          	bgeu	a2,a1,800014fe <uvmdealloc+0x26>
    800014e8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014ea:	6791                	lui	a5,0x4
    800014ec:	17fd                	addi	a5,a5,-1
    800014ee:	00f60733          	add	a4,a2,a5
    800014f2:	7671                	lui	a2,0xffffc
    800014f4:	8f71                	and	a4,a4,a2
    800014f6:	97ae                	add	a5,a5,a1
    800014f8:	8ff1                	and	a5,a5,a2
    800014fa:	00f76863          	bltu	a4,a5,8000150a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014fe:	8526                	mv	a0,s1
    80001500:	60e2                	ld	ra,24(sp)
    80001502:	6442                	ld	s0,16(sp)
    80001504:	64a2                	ld	s1,8(sp)
    80001506:	6105                	addi	sp,sp,32
    80001508:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000150a:	8f99                	sub	a5,a5,a4
    8000150c:	83b9                	srli	a5,a5,0xe
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000150e:	4685                	li	a3,1
    80001510:	0007861b          	sext.w	a2,a5
    80001514:	85ba                	mv	a1,a4
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	e5e080e7          	jalr	-418(ra) # 80001374 <uvmunmap>
    8000151e:	b7c5                	j	800014fe <uvmdealloc+0x26>

0000000080001520 <uvmalloc>:
  if(newsz < oldsz)
    80001520:	0ab66163          	bltu	a2,a1,800015c2 <uvmalloc+0xa2>
{
    80001524:	7139                	addi	sp,sp,-64
    80001526:	fc06                	sd	ra,56(sp)
    80001528:	f822                	sd	s0,48(sp)
    8000152a:	f426                	sd	s1,40(sp)
    8000152c:	f04a                	sd	s2,32(sp)
    8000152e:	ec4e                	sd	s3,24(sp)
    80001530:	e852                	sd	s4,16(sp)
    80001532:	e456                	sd	s5,8(sp)
    80001534:	0080                	addi	s0,sp,64
    80001536:	8aaa                	mv	s5,a0
    80001538:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000153a:	6991                	lui	s3,0x4
    8000153c:	19fd                	addi	s3,s3,-1
    8000153e:	95ce                	add	a1,a1,s3
    80001540:	79f1                	lui	s3,0xffffc
    80001542:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001546:	08c9f063          	bgeu	s3,a2,800015c6 <uvmalloc+0xa6>
    8000154a:	894e                	mv	s2,s3
    mem = kalloc();
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	5a8080e7          	jalr	1448(ra) # 80000af4 <kalloc>
    80001554:	84aa                	mv	s1,a0
    if(mem == 0){
    80001556:	c51d                	beqz	a0,80001584 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001558:	6611                	lui	a2,0x4
    8000155a:	4581                	li	a1,0
    8000155c:	fffff097          	auipc	ra,0xfffff
    80001560:	784080e7          	jalr	1924(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001564:	4779                	li	a4,30
    80001566:	86a6                	mv	a3,s1
    80001568:	6611                	lui	a2,0x4
    8000156a:	85ca                	mv	a1,s2
    8000156c:	8556                	mv	a0,s5
    8000156e:	00000097          	auipc	ra,0x0
    80001572:	bb0080e7          	jalr	-1104(ra) # 8000111e <mappages>
    80001576:	e905                	bnez	a0,800015a6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001578:	6791                	lui	a5,0x4
    8000157a:	993e                	add	s2,s2,a5
    8000157c:	fd4968e3          	bltu	s2,s4,8000154c <uvmalloc+0x2c>
  return newsz;
    80001580:	8552                	mv	a0,s4
    80001582:	a809                	j	80001594 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001584:	864e                	mv	a2,s3
    80001586:	85ca                	mv	a1,s2
    80001588:	8556                	mv	a0,s5
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	f4e080e7          	jalr	-178(ra) # 800014d8 <uvmdealloc>
      return 0;
    80001592:	4501                	li	a0,0
}
    80001594:	70e2                	ld	ra,56(sp)
    80001596:	7442                	ld	s0,48(sp)
    80001598:	74a2                	ld	s1,40(sp)
    8000159a:	7902                	ld	s2,32(sp)
    8000159c:	69e2                	ld	s3,24(sp)
    8000159e:	6a42                	ld	s4,16(sp)
    800015a0:	6aa2                	ld	s5,8(sp)
    800015a2:	6121                	addi	sp,sp,64
    800015a4:	8082                	ret
      kfree(mem);
    800015a6:	8526                	mv	a0,s1
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	450080e7          	jalr	1104(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015b0:	864e                	mv	a2,s3
    800015b2:	85ca                	mv	a1,s2
    800015b4:	8556                	mv	a0,s5
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f22080e7          	jalr	-222(ra) # 800014d8 <uvmdealloc>
      return 0;
    800015be:	4501                	li	a0,0
    800015c0:	bfd1                	j	80001594 <uvmalloc+0x74>
    return oldsz;
    800015c2:	852e                	mv	a0,a1
}
    800015c4:	8082                	ret
  return newsz;
    800015c6:	8532                	mv	a0,a2
    800015c8:	b7f1                	j	80001594 <uvmalloc+0x74>

00000000800015ca <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015ca:	7179                	addi	sp,sp,-48
    800015cc:	f406                	sd	ra,40(sp)
    800015ce:	f022                	sd	s0,32(sp)
    800015d0:	ec26                	sd	s1,24(sp)
    800015d2:	e84a                	sd	s2,16(sp)
    800015d4:	e44e                	sd	s3,8(sp)
    800015d6:	e052                	sd	s4,0(sp)
    800015d8:	1800                	addi	s0,sp,48
    800015da:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015dc:	84aa                	mv	s1,a0
    800015de:	6905                	lui	s2,0x1
    800015e0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015e2:	4985                	li	s3,1
    800015e4:	a821                	j	800015fc <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e6:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e8:	053a                	slli	a0,a0,0xe
    800015ea:	00000097          	auipc	ra,0x0
    800015ee:	fe0080e7          	jalr	-32(ra) # 800015ca <freewalk>
      pagetable[i] = 0;
    800015f2:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f6:	04a1                	addi	s1,s1,8
    800015f8:	03248163          	beq	s1,s2,8000161a <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015fc:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fe:	00f57793          	andi	a5,a0,15
    80001602:	ff3782e3          	beq	a5,s3,800015e6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001606:	8905                	andi	a0,a0,1
    80001608:	d57d                	beqz	a0,800015f6 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	ce650513          	addi	a0,a0,-794 # 800082f0 <digits+0x2b0>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000161a:	8552                	mv	a0,s4
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3dc080e7          	jalr	988(ra) # 800009f8 <kfree>
}
    80001624:	70a2                	ld	ra,40(sp)
    80001626:	7402                	ld	s0,32(sp)
    80001628:	64e2                	ld	s1,24(sp)
    8000162a:	6942                	ld	s2,16(sp)
    8000162c:	69a2                	ld	s3,8(sp)
    8000162e:	6a02                	ld	s4,0(sp)
    80001630:	6145                	addi	sp,sp,48
    80001632:	8082                	ret

0000000080001634 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001634:	1101                	addi	sp,sp,-32
    80001636:	ec06                	sd	ra,24(sp)
    80001638:	e822                	sd	s0,16(sp)
    8000163a:	e426                	sd	s1,8(sp)
    8000163c:	1000                	addi	s0,sp,32
    8000163e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001640:	e999                	bnez	a1,80001656 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001642:	8526                	mv	a0,s1
    80001644:	00000097          	auipc	ra,0x0
    80001648:	f86080e7          	jalr	-122(ra) # 800015ca <freewalk>
}
    8000164c:	60e2                	ld	ra,24(sp)
    8000164e:	6442                	ld	s0,16(sp)
    80001650:	64a2                	ld	s1,8(sp)
    80001652:	6105                	addi	sp,sp,32
    80001654:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001656:	6611                	lui	a2,0x4
    80001658:	167d                	addi	a2,a2,-1
    8000165a:	962e                	add	a2,a2,a1
    8000165c:	4685                	li	a3,1
    8000165e:	8239                	srli	a2,a2,0xe
    80001660:	4581                	li	a1,0
    80001662:	00000097          	auipc	ra,0x0
    80001666:	d12080e7          	jalr	-750(ra) # 80001374 <uvmunmap>
    8000166a:	bfe1                	j	80001642 <uvmfree+0xe>

000000008000166c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000166c:	c679                	beqz	a2,8000173a <uvmcopy+0xce>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	0880                	addi	s0,sp,80
    80001684:	8b2a                	mv	s6,a0
    80001686:	8aae                	mv	s5,a1
    80001688:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000168a:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000168c:	4601                	li	a2,0
    8000168e:	85ce                	mv	a1,s3
    80001690:	855a                	mv	a0,s6
    80001692:	00000097          	auipc	ra,0x0
    80001696:	9a2080e7          	jalr	-1630(ra) # 80001034 <walk>
    8000169a:	c531                	beqz	a0,800016e6 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000169c:	6118                	ld	a4,0(a0)
    8000169e:	00177793          	andi	a5,a4,1
    800016a2:	cbb1                	beqz	a5,800016f6 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016a4:	00a75593          	srli	a1,a4,0xa
    800016a8:	00e59b93          	slli	s7,a1,0xe
    flags = PTE_FLAGS(*pte);
    800016ac:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	444080e7          	jalr	1092(ra) # 80000af4 <kalloc>
    800016b8:	892a                	mv	s2,a0
    800016ba:	c939                	beqz	a0,80001710 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016bc:	6611                	lui	a2,0x4
    800016be:	85de                	mv	a1,s7
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	680080e7          	jalr	1664(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016c8:	8726                	mv	a4,s1
    800016ca:	86ca                	mv	a3,s2
    800016cc:	6611                	lui	a2,0x4
    800016ce:	85ce                	mv	a1,s3
    800016d0:	8556                	mv	a0,s5
    800016d2:	00000097          	auipc	ra,0x0
    800016d6:	a4c080e7          	jalr	-1460(ra) # 8000111e <mappages>
    800016da:	e515                	bnez	a0,80001706 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016dc:	6791                	lui	a5,0x4
    800016de:	99be                	add	s3,s3,a5
    800016e0:	fb49e6e3          	bltu	s3,s4,8000168c <uvmcopy+0x20>
    800016e4:	a081                	j	80001724 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	c1a50513          	addi	a0,a0,-998 # 80008300 <digits+0x2c0>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800016f6:	00007517          	auipc	a0,0x7
    800016fa:	c2a50513          	addi	a0,a0,-982 # 80008320 <digits+0x2e0>
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>
      kfree(mem);
    80001706:	854a                	mv	a0,s2
    80001708:	fffff097          	auipc	ra,0xfffff
    8000170c:	2f0080e7          	jalr	752(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001710:	4685                	li	a3,1
    80001712:	00e9d613          	srli	a2,s3,0xe
    80001716:	4581                	li	a1,0
    80001718:	8556                	mv	a0,s5
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	c5a080e7          	jalr	-934(ra) # 80001374 <uvmunmap>
  return -1;
    80001722:	557d                	li	a0,-1
}
    80001724:	60a6                	ld	ra,72(sp)
    80001726:	6406                	ld	s0,64(sp)
    80001728:	74e2                	ld	s1,56(sp)
    8000172a:	7942                	ld	s2,48(sp)
    8000172c:	79a2                	ld	s3,40(sp)
    8000172e:	7a02                	ld	s4,32(sp)
    80001730:	6ae2                	ld	s5,24(sp)
    80001732:	6b42                	ld	s6,16(sp)
    80001734:	6ba2                	ld	s7,8(sp)
    80001736:	6161                	addi	sp,sp,80
    80001738:	8082                	ret
  return 0;
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret

000000008000173e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000173e:	1141                	addi	sp,sp,-16
    80001740:	e406                	sd	ra,8(sp)
    80001742:	e022                	sd	s0,0(sp)
    80001744:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001746:	4601                	li	a2,0
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	8ec080e7          	jalr	-1812(ra) # 80001034 <walk>
  if(pte == 0)
    80001750:	c901                	beqz	a0,80001760 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001752:	611c                	ld	a5,0(a0)
    80001754:	9bbd                	andi	a5,a5,-17
    80001756:	e11c                	sd	a5,0(a0)
}
    80001758:	60a2                	ld	ra,8(sp)
    8000175a:	6402                	ld	s0,0(sp)
    8000175c:	0141                	addi	sp,sp,16
    8000175e:	8082                	ret
    panic("uvmclear");
    80001760:	00007517          	auipc	a0,0x7
    80001764:	be050513          	addi	a0,a0,-1056 # 80008340 <digits+0x300>
    80001768:	fffff097          	auipc	ra,0xfffff
    8000176c:	dd6080e7          	jalr	-554(ra) # 8000053e <panic>

0000000080001770 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	c6bd                	beqz	a3,800017de <copyout+0x6e>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8c2e                	mv	s8,a1
    8000178e:	8a32                	mv	s4,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001792:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001794:	6a91                	lui	s5,0x4
    80001796:	a015                	j	800017ba <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001798:	9562                	add	a0,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	85d2                	mv	a1,s4
    800017a0:	41250533          	sub	a0,a0,s2
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	59c080e7          	jalr	1436(ra) # 80000d40 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    src += n;
    800017b0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	91a080e7          	jalr	-1766(ra) # 800010dc <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f3e3          	bgeu	s3,s1,80001798 <copyout+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	b7c1                	j	80001798 <copyout+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyout+0x74>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017fc:	c6bd                	beqz	a3,8000186a <copyin+0x6e>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	e062                	sd	s8,0(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8b2a                	mv	s6,a0
    80001818:	8a2e                	mv	s4,a1
    8000181a:	8c32                	mv	s8,a2
    8000181c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7bf1                	lui	s7,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6a91                	lui	s5,0x4
    80001822:	a015                	j	80001846 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001824:	9562                	add	a0,a0,s8
    80001826:	0004861b          	sext.w	a2,s1
    8000182a:	412505b3          	sub	a1,a0,s2
    8000182e:	8552                	mv	a0,s4
    80001830:	fffff097          	auipc	ra,0xfffff
    80001834:	510080e7          	jalr	1296(ra) # 80000d40 <memmove>

    len -= n;
    80001838:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000183c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000183e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001842:	02098263          	beqz	s3,80001866 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001846:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000184a:	85ca                	mv	a1,s2
    8000184c:	855a                	mv	a0,s6
    8000184e:	00000097          	auipc	ra,0x0
    80001852:	88e080e7          	jalr	-1906(ra) # 800010dc <walkaddr>
    if(pa0 == 0)
    80001856:	cd01                	beqz	a0,8000186e <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001858:	418904b3          	sub	s1,s2,s8
    8000185c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000185e:	fc99f3e3          	bgeu	s3,s1,80001824 <copyin+0x28>
    80001862:	84ce                	mv	s1,s3
    80001864:	b7c1                	j	80001824 <copyin+0x28>
  }
  return 0;
    80001866:	4501                	li	a0,0
    80001868:	a021                	j	80001870 <copyin+0x74>
    8000186a:	4501                	li	a0,0
}
    8000186c:	8082                	ret
      return -1;
    8000186e:	557d                	li	a0,-1
}
    80001870:	60a6                	ld	ra,72(sp)
    80001872:	6406                	ld	s0,64(sp)
    80001874:	74e2                	ld	s1,56(sp)
    80001876:	7942                	ld	s2,48(sp)
    80001878:	79a2                	ld	s3,40(sp)
    8000187a:	7a02                	ld	s4,32(sp)
    8000187c:	6ae2                	ld	s5,24(sp)
    8000187e:	6b42                	ld	s6,16(sp)
    80001880:	6ba2                	ld	s7,8(sp)
    80001882:	6c02                	ld	s8,0(sp)
    80001884:	6161                	addi	sp,sp,80
    80001886:	8082                	ret

0000000080001888 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001888:	c6c5                	beqz	a3,80001930 <copyinstr+0xa8>
{
    8000188a:	715d                	addi	sp,sp,-80
    8000188c:	e486                	sd	ra,72(sp)
    8000188e:	e0a2                	sd	s0,64(sp)
    80001890:	fc26                	sd	s1,56(sp)
    80001892:	f84a                	sd	s2,48(sp)
    80001894:	f44e                	sd	s3,40(sp)
    80001896:	f052                	sd	s4,32(sp)
    80001898:	ec56                	sd	s5,24(sp)
    8000189a:	e85a                	sd	s6,16(sp)
    8000189c:	e45e                	sd	s7,8(sp)
    8000189e:	0880                	addi	s0,sp,80
    800018a0:	8a2a                	mv	s4,a0
    800018a2:	8b2e                	mv	s6,a1
    800018a4:	8bb2                	mv	s7,a2
    800018a6:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018a8:	7af1                	lui	s5,0xffffc
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018aa:	6991                	lui	s3,0x4
    800018ac:	a035                	j	800018d8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018ae:	00078023          	sb	zero,0(a5) # 4000 <_entry-0x7fffc000>
    800018b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018b4:	0017b793          	seqz	a5,a5
    800018b8:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018bc:	60a6                	ld	ra,72(sp)
    800018be:	6406                	ld	s0,64(sp)
    800018c0:	74e2                	ld	s1,56(sp)
    800018c2:	7942                	ld	s2,48(sp)
    800018c4:	79a2                	ld	s3,40(sp)
    800018c6:	7a02                	ld	s4,32(sp)
    800018c8:	6ae2                	ld	s5,24(sp)
    800018ca:	6b42                	ld	s6,16(sp)
    800018cc:	6ba2                	ld	s7,8(sp)
    800018ce:	6161                	addi	sp,sp,80
    800018d0:	8082                	ret
    srcva = va0 + PGSIZE;
    800018d2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018d6:	c8a9                	beqz	s1,80001928 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018d8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018dc:	85ca                	mv	a1,s2
    800018de:	8552                	mv	a0,s4
    800018e0:	fffff097          	auipc	ra,0xfffff
    800018e4:	7fc080e7          	jalr	2044(ra) # 800010dc <walkaddr>
    if(pa0 == 0)
    800018e8:	c131                	beqz	a0,8000192c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018ea:	41790833          	sub	a6,s2,s7
    800018ee:	984e                	add	a6,a6,s3
    if(n > max)
    800018f0:	0104f363          	bgeu	s1,a6,800018f6 <copyinstr+0x6e>
    800018f4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018f6:	955e                	add	a0,a0,s7
    800018f8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018fc:	fc080be3          	beqz	a6,800018d2 <copyinstr+0x4a>
    80001900:	985a                	add	a6,a6,s6
    80001902:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001904:	41650633          	sub	a2,a0,s6
    80001908:	14fd                	addi	s1,s1,-1
    8000190a:	9b26                	add	s6,s6,s1
    8000190c:	00f60733          	add	a4,a2,a5
    80001910:	00074703          	lbu	a4,0(a4)
    80001914:	df49                	beqz	a4,800018ae <copyinstr+0x26>
        *dst = *p;
    80001916:	00e78023          	sb	a4,0(a5)
      --max;
    8000191a:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000191e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001920:	ff0796e3          	bne	a5,a6,8000190c <copyinstr+0x84>
      dst++;
    80001924:	8b42                	mv	s6,a6
    80001926:	b775                	j	800018d2 <copyinstr+0x4a>
    80001928:	4781                	li	a5,0
    8000192a:	b769                	j	800018b4 <copyinstr+0x2c>
      return -1;
    8000192c:	557d                	li	a0,-1
    8000192e:	b779                	j	800018bc <copyinstr+0x34>
  int got_null = 0;
    80001930:	4781                	li	a5,0
  if(got_null){
    80001932:	0017b793          	seqz	a5,a5
    80001936:	40f00533          	neg	a0,a5
}
    8000193a:	8082                	ret

000000008000193c <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000193c:	7139                	addi	sp,sp,-64
    8000193e:	fc06                	sd	ra,56(sp)
    80001940:	f822                	sd	s0,48(sp)
    80001942:	f426                	sd	s1,40(sp)
    80001944:	f04a                	sd	s2,32(sp)
    80001946:	ec4e                	sd	s3,24(sp)
    80001948:	e852                	sd	s4,16(sp)
    8000194a:	e456                	sd	s5,8(sp)
    8000194c:	e05a                	sd	s6,0(sp)
    8000194e:	0080                	addi	s0,sp,64
    80001950:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001952:	00013497          	auipc	s1,0x13
    80001956:	d7e48493          	addi	s1,s1,-642 # 800146d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000195a:	8b26                	mv	s6,s1
    8000195c:	00006a97          	auipc	s5,0x6
    80001960:	6a4a8a93          	addi	s5,s5,1700 # 80008000 <etext>
    80001964:	00800937          	lui	s2,0x800
    80001968:	197d                	addi	s2,s2,-1
    8000196a:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00018a17          	auipc	s4,0x18
    80001970:	764a0a13          	addi	s4,s4,1892 # 8001a0d0 <tickslock>
    char *pa = kalloc();
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	180080e7          	jalr	384(ra) # 80000af4 <kalloc>
    8000197c:	862a                	mv	a2,a0
    if(pa == 0)
    8000197e:	c131                	beqz	a0,800019c2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001980:	416485b3          	sub	a1,s1,s6
    80001984:	858d                	srai	a1,a1,0x3
    80001986:	000ab783          	ld	a5,0(s5)
    8000198a:	02f585b3          	mul	a1,a1,a5
    8000198e:	2585                	addiw	a1,a1,1
    80001990:	00f5959b          	slliw	a1,a1,0xf
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001994:	4719                	li	a4,6
    80001996:	6691                	lui	a3,0x4
    80001998:	40b905b3          	sub	a1,s2,a1
    8000199c:	854e                	mv	a0,s3
    8000199e:	00000097          	auipc	ra,0x0
    800019a2:	838080e7          	jalr	-1992(ra) # 800011d6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	16848493          	addi	s1,s1,360
    800019aa:	fd4495e3          	bne	s1,s4,80001974 <proc_mapstacks+0x38>
  }
}
    800019ae:	70e2                	ld	ra,56(sp)
    800019b0:	7442                	ld	s0,48(sp)
    800019b2:	74a2                	ld	s1,40(sp)
    800019b4:	7902                	ld	s2,32(sp)
    800019b6:	69e2                	ld	s3,24(sp)
    800019b8:	6a42                	ld	s4,16(sp)
    800019ba:	6aa2                	ld	s5,8(sp)
    800019bc:	6b02                	ld	s6,0(sp)
    800019be:	6121                	addi	sp,sp,64
    800019c0:	8082                	ret
      panic("kalloc");
    800019c2:	00007517          	auipc	a0,0x7
    800019c6:	98e50513          	addi	a0,a0,-1650 # 80008350 <digits+0x310>
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	b74080e7          	jalr	-1164(ra) # 8000053e <panic>

00000000800019d2 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019d2:	7139                	addi	sp,sp,-64
    800019d4:	fc06                	sd	ra,56(sp)
    800019d6:	f822                	sd	s0,48(sp)
    800019d8:	f426                	sd	s1,40(sp)
    800019da:	f04a                	sd	s2,32(sp)
    800019dc:	ec4e                	sd	s3,24(sp)
    800019de:	e852                	sd	s4,16(sp)
    800019e0:	e456                	sd	s5,8(sp)
    800019e2:	e05a                	sd	s6,0(sp)
    800019e4:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019e6:	00007597          	auipc	a1,0x7
    800019ea:	97258593          	addi	a1,a1,-1678 # 80008358 <digits+0x318>
    800019ee:	00013517          	auipc	a0,0x13
    800019f2:	8b250513          	addi	a0,a0,-1870 # 800142a0 <pid_lock>
    800019f6:	fffff097          	auipc	ra,0xfffff
    800019fa:	15e080e7          	jalr	350(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019fe:	00007597          	auipc	a1,0x7
    80001a02:	96258593          	addi	a1,a1,-1694 # 80008360 <digits+0x320>
    80001a06:	00013517          	auipc	a0,0x13
    80001a0a:	8b250513          	addi	a0,a0,-1870 # 800142b8 <wait_lock>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	146080e7          	jalr	326(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a16:	00013497          	auipc	s1,0x13
    80001a1a:	cba48493          	addi	s1,s1,-838 # 800146d0 <proc>
      initlock(&p->lock, "proc");
    80001a1e:	00007b17          	auipc	s6,0x7
    80001a22:	952b0b13          	addi	s6,s6,-1710 # 80008370 <digits+0x330>
      p->kstack = KSTACK((int) (p - proc));
    80001a26:	8aa6                	mv	s5,s1
    80001a28:	00006a17          	auipc	s4,0x6
    80001a2c:	5d8a0a13          	addi	s4,s4,1496 # 80008000 <etext>
    80001a30:	00800937          	lui	s2,0x800
    80001a34:	197d                	addi	s2,s2,-1
    80001a36:	093a                	slli	s2,s2,0xe
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a38:	00018997          	auipc	s3,0x18
    80001a3c:	69898993          	addi	s3,s3,1688 # 8001a0d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a40:	85da                	mv	a1,s6
    80001a42:	8526                	mv	a0,s1
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	110080e7          	jalr	272(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a4c:	415487b3          	sub	a5,s1,s5
    80001a50:	878d                	srai	a5,a5,0x3
    80001a52:	000a3703          	ld	a4,0(s4)
    80001a56:	02e787b3          	mul	a5,a5,a4
    80001a5a:	2785                	addiw	a5,a5,1
    80001a5c:	00f7979b          	slliw	a5,a5,0xf
    80001a60:	40f907b3          	sub	a5,s2,a5
    80001a64:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a66:	16848493          	addi	s1,s1,360
    80001a6a:	fd349be3          	bne	s1,s3,80001a40 <procinit+0x6e>
  }
}
    80001a6e:	70e2                	ld	ra,56(sp)
    80001a70:	7442                	ld	s0,48(sp)
    80001a72:	74a2                	ld	s1,40(sp)
    80001a74:	7902                	ld	s2,32(sp)
    80001a76:	69e2                	ld	s3,24(sp)
    80001a78:	6a42                	ld	s4,16(sp)
    80001a7a:	6aa2                	ld	s5,8(sp)
    80001a7c:	6b02                	ld	s6,0(sp)
    80001a7e:	6121                	addi	sp,sp,64
    80001a80:	8082                	ret

0000000080001a82 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a82:	1141                	addi	sp,sp,-16
    80001a84:	e422                	sd	s0,8(sp)
    80001a86:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a88:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a8a:	2501                	sext.w	a0,a0
    80001a8c:	6422                	ld	s0,8(sp)
    80001a8e:	0141                	addi	sp,sp,16
    80001a90:	8082                	ret

0000000080001a92 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a92:	1141                	addi	sp,sp,-16
    80001a94:	e422                	sd	s0,8(sp)
    80001a96:	0800                	addi	s0,sp,16
    80001a98:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a9a:	2781                	sext.w	a5,a5
    80001a9c:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a9e:	00013517          	auipc	a0,0x13
    80001aa2:	83250513          	addi	a0,a0,-1998 # 800142d0 <cpus>
    80001aa6:	953e                	add	a0,a0,a5
    80001aa8:	6422                	ld	s0,8(sp)
    80001aaa:	0141                	addi	sp,sp,16
    80001aac:	8082                	ret

0000000080001aae <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001aae:	1101                	addi	sp,sp,-32
    80001ab0:	ec06                	sd	ra,24(sp)
    80001ab2:	e822                	sd	s0,16(sp)
    80001ab4:	e426                	sd	s1,8(sp)
    80001ab6:	1000                	addi	s0,sp,32
  push_off();
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	0e0080e7          	jalr	224(ra) # 80000b98 <push_off>
    80001ac0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac2:	2781                	sext.w	a5,a5
    80001ac4:	079e                	slli	a5,a5,0x7
    80001ac6:	00012717          	auipc	a4,0x12
    80001aca:	7da70713          	addi	a4,a4,2010 # 800142a0 <pid_lock>
    80001ace:	97ba                	add	a5,a5,a4
    80001ad0:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	166080e7          	jalr	358(ra) # 80000c38 <pop_off>
  return p;
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6105                	addi	sp,sp,32
    80001ae4:	8082                	ret

0000000080001ae6 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ae6:	1141                	addi	sp,sp,-16
    80001ae8:	e406                	sd	ra,8(sp)
    80001aea:	e022                	sd	s0,0(sp)
    80001aec:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	fc0080e7          	jalr	-64(ra) # 80001aae <myproc>
    80001af6:	fffff097          	auipc	ra,0xfffff
    80001afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>

  if (first) {
    80001afe:	00007797          	auipc	a5,0x7
    80001b02:	ec27a783          	lw	a5,-318(a5) # 800089c0 <first.1672>
    80001b06:	eb89                	bnez	a5,80001b18 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b08:	00001097          	auipc	ra,0x1
    80001b0c:	c2e080e7          	jalr	-978(ra) # 80002736 <usertrapret>
}
    80001b10:	60a2                	ld	ra,8(sp)
    80001b12:	6402                	ld	s0,0(sp)
    80001b14:	0141                	addi	sp,sp,16
    80001b16:	8082                	ret
    first = 0;
    80001b18:	00007797          	auipc	a5,0x7
    80001b1c:	ea07a423          	sw	zero,-344(a5) # 800089c0 <first.1672>
    fsinit(ROOTDEV);
    80001b20:	4505                	li	a0,1
    80001b22:	00002097          	auipc	ra,0x2
    80001b26:	956080e7          	jalr	-1706(ra) # 80003478 <fsinit>
    80001b2a:	bff9                	j	80001b08 <forkret+0x22>

0000000080001b2c <allocpid>:
allocpid() {
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	e04a                	sd	s2,0(sp)
    80001b36:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b38:	00012917          	auipc	s2,0x12
    80001b3c:	76890913          	addi	s2,s2,1896 # 800142a0 <pid_lock>
    80001b40:	854a                	mv	a0,s2
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	0a2080e7          	jalr	162(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b4a:	00007797          	auipc	a5,0x7
    80001b4e:	e7a78793          	addi	a5,a5,-390 # 800089c4 <nextpid>
    80001b52:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b54:	0014871b          	addiw	a4,s1,1
    80001b58:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b5a:	854a                	mv	a0,s2
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	13c080e7          	jalr	316(ra) # 80000c98 <release>
}
    80001b64:	8526                	mv	a0,s1
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <proc_pagetable>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	e04a                	sd	s2,0(sp)
    80001b7c:	1000                	addi	s0,sp,32
    80001b7e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	8b8080e7          	jalr	-1864(ra) # 80001438 <uvmcreate>
    80001b88:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b8a:	c121                	beqz	a0,80001bca <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b8c:	4729                	li	a4,10
    80001b8e:	00005697          	auipc	a3,0x5
    80001b92:	47268693          	addi	a3,a3,1138 # 80007000 <_trampoline>
    80001b96:	6611                	lui	a2,0x4
    80001b98:	008005b7          	lui	a1,0x800
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05ba                	slli	a1,a1,0xe
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	57e080e7          	jalr	1406(ra) # 8000111e <mappages>
    80001ba8:	02054863          	bltz	a0,80001bd8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bac:	4719                	li	a4,6
    80001bae:	05893683          	ld	a3,88(s2)
    80001bb2:	6611                	lui	a2,0x4
    80001bb4:	004005b7          	lui	a1,0x400
    80001bb8:	15fd                	addi	a1,a1,-1
    80001bba:	05be                	slli	a1,a1,0xf
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	560080e7          	jalr	1376(ra) # 8000111e <mappages>
    80001bc6:	02054163          	bltz	a0,80001be8 <proc_pagetable+0x76>
}
    80001bca:	8526                	mv	a0,s1
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret
    uvmfree(pagetable, 0);
    80001bd8:	4581                	li	a1,0
    80001bda:	8526                	mv	a0,s1
    80001bdc:	00000097          	auipc	ra,0x0
    80001be0:	a58080e7          	jalr	-1448(ra) # 80001634 <uvmfree>
    return 0;
    80001be4:	4481                	li	s1,0
    80001be6:	b7d5                	j	80001bca <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001be8:	4681                	li	a3,0
    80001bea:	4605                	li	a2,1
    80001bec:	008005b7          	lui	a1,0x800
    80001bf0:	15fd                	addi	a1,a1,-1
    80001bf2:	05ba                	slli	a1,a1,0xe
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	77e080e7          	jalr	1918(ra) # 80001374 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bfe:	4581                	li	a1,0
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	a32080e7          	jalr	-1486(ra) # 80001634 <uvmfree>
    return 0;
    80001c0a:	4481                	li	s1,0
    80001c0c:	bf7d                	j	80001bca <proc_pagetable+0x58>

0000000080001c0e <proc_freepagetable>:
{
    80001c0e:	1101                	addi	sp,sp,-32
    80001c10:	ec06                	sd	ra,24(sp)
    80001c12:	e822                	sd	s0,16(sp)
    80001c14:	e426                	sd	s1,8(sp)
    80001c16:	e04a                	sd	s2,0(sp)
    80001c18:	1000                	addi	s0,sp,32
    80001c1a:	84aa                	mv	s1,a0
    80001c1c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1e:	4681                	li	a3,0
    80001c20:	4605                	li	a2,1
    80001c22:	008005b7          	lui	a1,0x800
    80001c26:	15fd                	addi	a1,a1,-1
    80001c28:	05ba                	slli	a1,a1,0xe
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	74a080e7          	jalr	1866(ra) # 80001374 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c32:	4681                	li	a3,0
    80001c34:	4605                	li	a2,1
    80001c36:	004005b7          	lui	a1,0x400
    80001c3a:	15fd                	addi	a1,a1,-1
    80001c3c:	05be                	slli	a1,a1,0xf
    80001c3e:	8526                	mv	a0,s1
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	734080e7          	jalr	1844(ra) # 80001374 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c48:	85ca                	mv	a1,s2
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	9e8080e7          	jalr	-1560(ra) # 80001634 <uvmfree>
}
    80001c54:	60e2                	ld	ra,24(sp)
    80001c56:	6442                	ld	s0,16(sp)
    80001c58:	64a2                	ld	s1,8(sp)
    80001c5a:	6902                	ld	s2,0(sp)
    80001c5c:	6105                	addi	sp,sp,32
    80001c5e:	8082                	ret

0000000080001c60 <freeproc>:
{
    80001c60:	1101                	addi	sp,sp,-32
    80001c62:	ec06                	sd	ra,24(sp)
    80001c64:	e822                	sd	s0,16(sp)
    80001c66:	e426                	sd	s1,8(sp)
    80001c68:	1000                	addi	s0,sp,32
    80001c6a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c6c:	6d28                	ld	a0,88(a0)
    80001c6e:	c509                	beqz	a0,80001c78 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	d88080e7          	jalr	-632(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c78:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c7c:	68a8                	ld	a0,80(s1)
    80001c7e:	c511                	beqz	a0,80001c8a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c80:	64ac                	ld	a1,72(s1)
    80001c82:	00000097          	auipc	ra,0x0
    80001c86:	f8c080e7          	jalr	-116(ra) # 80001c0e <proc_freepagetable>
  p->pagetable = 0;
    80001c8a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c8e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c92:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c96:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c9a:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c9e:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ca2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ca6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001caa:	0004ac23          	sw	zero,24(s1)
}
    80001cae:	60e2                	ld	ra,24(sp)
    80001cb0:	6442                	ld	s0,16(sp)
    80001cb2:	64a2                	ld	s1,8(sp)
    80001cb4:	6105                	addi	sp,sp,32
    80001cb6:	8082                	ret

0000000080001cb8 <allocproc>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	e04a                	sd	s2,0(sp)
    80001cc2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc4:	00013497          	auipc	s1,0x13
    80001cc8:	a0c48493          	addi	s1,s1,-1524 # 800146d0 <proc>
    80001ccc:	00018917          	auipc	s2,0x18
    80001cd0:	40490913          	addi	s2,s2,1028 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	f0e080e7          	jalr	-242(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001cde:	4c9c                	lw	a5,24(s1)
    80001ce0:	cf81                	beqz	a5,80001cf8 <allocproc+0x40>
      release(&p->lock);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	fb4080e7          	jalr	-76(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cec:	16848493          	addi	s1,s1,360
    80001cf0:	ff2492e3          	bne	s1,s2,80001cd4 <allocproc+0x1c>
  return 0;
    80001cf4:	4481                	li	s1,0
    80001cf6:	a889                	j	80001d48 <allocproc+0x90>
  p->pid = allocpid();
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	e34080e7          	jalr	-460(ra) # 80001b2c <allocpid>
    80001d00:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d02:	4785                	li	a5,1
    80001d04:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	dee080e7          	jalr	-530(ra) # 80000af4 <kalloc>
    80001d0e:	892a                	mv	s2,a0
    80001d10:	eca8                	sd	a0,88(s1)
    80001d12:	c131                	beqz	a0,80001d56 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d14:	8526                	mv	a0,s1
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	e5c080e7          	jalr	-420(ra) # 80001b72 <proc_pagetable>
    80001d1e:	892a                	mv	s2,a0
    80001d20:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d22:	c531                	beqz	a0,80001d6e <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d24:	07000613          	li	a2,112
    80001d28:	4581                	li	a1,0
    80001d2a:	06048513          	addi	a0,s1,96
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	fb2080e7          	jalr	-78(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d36:	00000797          	auipc	a5,0x0
    80001d3a:	db078793          	addi	a5,a5,-592 # 80001ae6 <forkret>
    80001d3e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d40:	60bc                	ld	a5,64(s1)
    80001d42:	6711                	lui	a4,0x4
    80001d44:	97ba                	add	a5,a5,a4
    80001d46:	f4bc                	sd	a5,104(s1)
}
    80001d48:	8526                	mv	a0,s1
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret
    freeproc(p);
    80001d56:	8526                	mv	a0,s1
    80001d58:	00000097          	auipc	ra,0x0
    80001d5c:	f08080e7          	jalr	-248(ra) # 80001c60 <freeproc>
    release(&p->lock);
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	f36080e7          	jalr	-202(ra) # 80000c98 <release>
    return 0;
    80001d6a:	84ca                	mv	s1,s2
    80001d6c:	bff1                	j	80001d48 <allocproc+0x90>
    freeproc(p);
    80001d6e:	8526                	mv	a0,s1
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	ef0080e7          	jalr	-272(ra) # 80001c60 <freeproc>
    release(&p->lock);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	f1e080e7          	jalr	-226(ra) # 80000c98 <release>
    return 0;
    80001d82:	84ca                	mv	s1,s2
    80001d84:	b7d1                	j	80001d48 <allocproc+0x90>

0000000080001d86 <userinit>:
{
    80001d86:	1101                	addi	sp,sp,-32
    80001d88:	ec06                	sd	ra,24(sp)
    80001d8a:	e822                	sd	s0,16(sp)
    80001d8c:	e426                	sd	s1,8(sp)
    80001d8e:	1000                	addi	s0,sp,32
	printf("Starting user init\n");
    80001d90:	00006517          	auipc	a0,0x6
    80001d94:	5e850513          	addi	a0,a0,1512 # 80008378 <digits+0x338>
    80001d98:	ffffe097          	auipc	ra,0xffffe
    80001d9c:	7f0080e7          	jalr	2032(ra) # 80000588 <printf>
  p = allocproc();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	f18080e7          	jalr	-232(ra) # 80001cb8 <allocproc>
    80001da8:	84aa                	mv	s1,a0
  initproc = p;
    80001daa:	0000a797          	auipc	a5,0xa
    80001dae:	26a7bf23          	sd	a0,638(a5) # 8000c028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001db2:	03400613          	li	a2,52
    80001db6:	00007597          	auipc	a1,0x7
    80001dba:	c1a58593          	addi	a1,a1,-998 # 800089d0 <initcode>
    80001dbe:	6928                	ld	a0,80(a0)
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	6a6080e7          	jalr	1702(ra) # 80001466 <uvminit>
  p->sz = PGSIZE;
    80001dc8:	6791                	lui	a5,0x4
    80001dca:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dcc:	6cb8                	ld	a4,88(s1)
    80001dce:	00073c23          	sd	zero,24(a4) # 4018 <_entry-0x7fffbfe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dd2:	6cb8                	ld	a4,88(s1)
    80001dd4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dd6:	4641                	li	a2,16
    80001dd8:	00006597          	auipc	a1,0x6
    80001ddc:	5b858593          	addi	a1,a1,1464 # 80008390 <digits+0x350>
    80001de0:	15848513          	addi	a0,s1,344
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	04e080e7          	jalr	78(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001dec:	00006517          	auipc	a0,0x6
    80001df0:	5b450513          	addi	a0,a0,1460 # 800083a0 <digits+0x360>
    80001df4:	00002097          	auipc	ra,0x2
    80001df8:	0b2080e7          	jalr	178(ra) # 80003ea6 <namei>
    80001dfc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e00:	478d                	li	a5,3
    80001e02:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e04:	8526                	mv	a0,s1
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	e92080e7          	jalr	-366(ra) # 80000c98 <release>
}
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6105                	addi	sp,sp,32
    80001e16:	8082                	ret

0000000080001e18 <growproc>:
{
    80001e18:	1101                	addi	sp,sp,-32
    80001e1a:	ec06                	sd	ra,24(sp)
    80001e1c:	e822                	sd	s0,16(sp)
    80001e1e:	e426                	sd	s1,8(sp)
    80001e20:	e04a                	sd	s2,0(sp)
    80001e22:	1000                	addi	s0,sp,32
    80001e24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e26:	00000097          	auipc	ra,0x0
    80001e2a:	c88080e7          	jalr	-888(ra) # 80001aae <myproc>
    80001e2e:	892a                	mv	s2,a0
  sz = p->sz;
    80001e30:	652c                	ld	a1,72(a0)
    80001e32:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e36:	00904f63          	bgtz	s1,80001e54 <growproc+0x3c>
  } else if(n < 0){
    80001e3a:	0204cc63          	bltz	s1,80001e72 <growproc+0x5a>
  p->sz = sz;
    80001e3e:	1602                	slli	a2,a2,0x20
    80001e40:	9201                	srli	a2,a2,0x20
    80001e42:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e46:	4501                	li	a0,0
}
    80001e48:	60e2                	ld	ra,24(sp)
    80001e4a:	6442                	ld	s0,16(sp)
    80001e4c:	64a2                	ld	s1,8(sp)
    80001e4e:	6902                	ld	s2,0(sp)
    80001e50:	6105                	addi	sp,sp,32
    80001e52:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e54:	9e25                	addw	a2,a2,s1
    80001e56:	1602                	slli	a2,a2,0x20
    80001e58:	9201                	srli	a2,a2,0x20
    80001e5a:	1582                	slli	a1,a1,0x20
    80001e5c:	9181                	srli	a1,a1,0x20
    80001e5e:	6928                	ld	a0,80(a0)
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	6c0080e7          	jalr	1728(ra) # 80001520 <uvmalloc>
    80001e68:	0005061b          	sext.w	a2,a0
    80001e6c:	fa69                	bnez	a2,80001e3e <growproc+0x26>
      return -1;
    80001e6e:	557d                	li	a0,-1
    80001e70:	bfe1                	j	80001e48 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e72:	9e25                	addw	a2,a2,s1
    80001e74:	1602                	slli	a2,a2,0x20
    80001e76:	9201                	srli	a2,a2,0x20
    80001e78:	1582                	slli	a1,a1,0x20
    80001e7a:	9181                	srli	a1,a1,0x20
    80001e7c:	6928                	ld	a0,80(a0)
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	65a080e7          	jalr	1626(ra) # 800014d8 <uvmdealloc>
    80001e86:	0005061b          	sext.w	a2,a0
    80001e8a:	bf55                	j	80001e3e <growproc+0x26>

0000000080001e8c <fork>:
{
    80001e8c:	7179                	addi	sp,sp,-48
    80001e8e:	f406                	sd	ra,40(sp)
    80001e90:	f022                	sd	s0,32(sp)
    80001e92:	ec26                	sd	s1,24(sp)
    80001e94:	e84a                	sd	s2,16(sp)
    80001e96:	e44e                	sd	s3,8(sp)
    80001e98:	e052                	sd	s4,0(sp)
    80001e9a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	c12080e7          	jalr	-1006(ra) # 80001aae <myproc>
    80001ea4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ea6:	00000097          	auipc	ra,0x0
    80001eaa:	e12080e7          	jalr	-494(ra) # 80001cb8 <allocproc>
    80001eae:	10050b63          	beqz	a0,80001fc4 <fork+0x138>
    80001eb2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001eb4:	04893603          	ld	a2,72(s2)
    80001eb8:	692c                	ld	a1,80(a0)
    80001eba:	05093503          	ld	a0,80(s2)
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	7ae080e7          	jalr	1966(ra) # 8000166c <uvmcopy>
    80001ec6:	04054663          	bltz	a0,80001f12 <fork+0x86>
  np->sz = p->sz;
    80001eca:	04893783          	ld	a5,72(s2)
    80001ece:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ed2:	05893683          	ld	a3,88(s2)
    80001ed6:	87b6                	mv	a5,a3
    80001ed8:	0589b703          	ld	a4,88(s3)
    80001edc:	12068693          	addi	a3,a3,288
    80001ee0:	0007b803          	ld	a6,0(a5) # 4000 <_entry-0x7fffc000>
    80001ee4:	6788                	ld	a0,8(a5)
    80001ee6:	6b8c                	ld	a1,16(a5)
    80001ee8:	6f90                	ld	a2,24(a5)
    80001eea:	01073023          	sd	a6,0(a4)
    80001eee:	e708                	sd	a0,8(a4)
    80001ef0:	eb0c                	sd	a1,16(a4)
    80001ef2:	ef10                	sd	a2,24(a4)
    80001ef4:	02078793          	addi	a5,a5,32
    80001ef8:	02070713          	addi	a4,a4,32
    80001efc:	fed792e3          	bne	a5,a3,80001ee0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001f00:	0589b783          	ld	a5,88(s3)
    80001f04:	0607b823          	sd	zero,112(a5)
    80001f08:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f0c:	15000a13          	li	s4,336
    80001f10:	a03d                	j	80001f3e <fork+0xb2>
    freeproc(np);
    80001f12:	854e                	mv	a0,s3
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	d4c080e7          	jalr	-692(ra) # 80001c60 <freeproc>
    release(&np->lock);
    80001f1c:	854e                	mv	a0,s3
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d7a080e7          	jalr	-646(ra) # 80000c98 <release>
    return -1;
    80001f26:	5a7d                	li	s4,-1
    80001f28:	a069                	j	80001fb2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f2a:	00002097          	auipc	ra,0x2
    80001f2e:	612080e7          	jalr	1554(ra) # 8000453c <filedup>
    80001f32:	009987b3          	add	a5,s3,s1
    80001f36:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f38:	04a1                	addi	s1,s1,8
    80001f3a:	01448763          	beq	s1,s4,80001f48 <fork+0xbc>
    if(p->ofile[i])
    80001f3e:	009907b3          	add	a5,s2,s1
    80001f42:	6388                	ld	a0,0(a5)
    80001f44:	f17d                	bnez	a0,80001f2a <fork+0x9e>
    80001f46:	bfcd                	j	80001f38 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f48:	15093503          	ld	a0,336(s2)
    80001f4c:	00001097          	auipc	ra,0x1
    80001f50:	766080e7          	jalr	1894(ra) # 800036b2 <idup>
    80001f54:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f58:	4641                	li	a2,16
    80001f5a:	15890593          	addi	a1,s2,344
    80001f5e:	15898513          	addi	a0,s3,344
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	ed0080e7          	jalr	-304(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f6a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f6e:	854e                	mv	a0,s3
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	d28080e7          	jalr	-728(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f78:	00012497          	auipc	s1,0x12
    80001f7c:	34048493          	addi	s1,s1,832 # 800142b8 <wait_lock>
    80001f80:	8526                	mv	a0,s1
    80001f82:	fffff097          	auipc	ra,0xfffff
    80001f86:	c62080e7          	jalr	-926(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f8a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	d08080e7          	jalr	-760(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f98:	854e                	mv	a0,s3
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	c4a080e7          	jalr	-950(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001fa2:	478d                	li	a5,3
    80001fa4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fa8:	854e                	mv	a0,s3
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	cee080e7          	jalr	-786(ra) # 80000c98 <release>
}
    80001fb2:	8552                	mv	a0,s4
    80001fb4:	70a2                	ld	ra,40(sp)
    80001fb6:	7402                	ld	s0,32(sp)
    80001fb8:	64e2                	ld	s1,24(sp)
    80001fba:	6942                	ld	s2,16(sp)
    80001fbc:	69a2                	ld	s3,8(sp)
    80001fbe:	6a02                	ld	s4,0(sp)
    80001fc0:	6145                	addi	sp,sp,48
    80001fc2:	8082                	ret
    return -1;
    80001fc4:	5a7d                	li	s4,-1
    80001fc6:	b7f5                	j	80001fb2 <fork+0x126>

0000000080001fc8 <scheduler>:
{
    80001fc8:	7139                	addi	sp,sp,-64
    80001fca:	fc06                	sd	ra,56(sp)
    80001fcc:	f822                	sd	s0,48(sp)
    80001fce:	f426                	sd	s1,40(sp)
    80001fd0:	f04a                	sd	s2,32(sp)
    80001fd2:	ec4e                	sd	s3,24(sp)
    80001fd4:	e852                	sd	s4,16(sp)
    80001fd6:	e456                	sd	s5,8(sp)
    80001fd8:	e05a                	sd	s6,0(sp)
    80001fda:	0080                	addi	s0,sp,64
    80001fdc:	8792                	mv	a5,tp
  int id = r_tp();
    80001fde:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe0:	00779a93          	slli	s5,a5,0x7
    80001fe4:	00012717          	auipc	a4,0x12
    80001fe8:	2bc70713          	addi	a4,a4,700 # 800142a0 <pid_lock>
    80001fec:	9756                	add	a4,a4,s5
    80001fee:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ff2:	00012717          	auipc	a4,0x12
    80001ff6:	2e670713          	addi	a4,a4,742 # 800142d8 <cpus+0x8>
    80001ffa:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ffc:	498d                	li	s3,3
        p->state = RUNNING;
    80001ffe:	4b11                	li	s6,4
        c->proc = p;
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	00012a17          	auipc	s4,0x12
    80002006:	29ea0a13          	addi	s4,s4,670 # 800142a0 <pid_lock>
    8000200a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200c:	00018917          	auipc	s2,0x18
    80002010:	0c490913          	addi	s2,s2,196 # 8001a0d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002014:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002018:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201c:	10079073          	csrw	sstatus,a5
    80002020:	00012497          	auipc	s1,0x12
    80002024:	6b048493          	addi	s1,s1,1712 # 800146d0 <proc>
    80002028:	a03d                	j	80002056 <scheduler+0x8e>
        p->state = RUNNING;
    8000202a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000202e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002032:	06048593          	addi	a1,s1,96
    80002036:	8556                	mv	a0,s5
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	654080e7          	jalr	1620(ra) # 8000268c <swtch>
        c->proc = 0;
    80002040:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	c52080e7          	jalr	-942(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000204e:	16848493          	addi	s1,s1,360
    80002052:	fd2481e3          	beq	s1,s2,80002014 <scheduler+0x4c>
      acquire(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	b8c080e7          	jalr	-1140(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002060:	4c9c                	lw	a5,24(s1)
    80002062:	ff3791e3          	bne	a5,s3,80002044 <scheduler+0x7c>
    80002066:	b7d1                	j	8000202a <scheduler+0x62>

0000000080002068 <sched>:
{
    80002068:	7179                	addi	sp,sp,-48
    8000206a:	f406                	sd	ra,40(sp)
    8000206c:	f022                	sd	s0,32(sp)
    8000206e:	ec26                	sd	s1,24(sp)
    80002070:	e84a                	sd	s2,16(sp)
    80002072:	e44e                	sd	s3,8(sp)
    80002074:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	a38080e7          	jalr	-1480(ra) # 80001aae <myproc>
    8000207e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002080:	fffff097          	auipc	ra,0xfffff
    80002084:	aea080e7          	jalr	-1302(ra) # 80000b6a <holding>
    80002088:	c93d                	beqz	a0,800020fe <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000208c:	2781                	sext.w	a5,a5
    8000208e:	079e                	slli	a5,a5,0x7
    80002090:	00012717          	auipc	a4,0x12
    80002094:	21070713          	addi	a4,a4,528 # 800142a0 <pid_lock>
    80002098:	97ba                	add	a5,a5,a4
    8000209a:	0a87a703          	lw	a4,168(a5)
    8000209e:	4785                	li	a5,1
    800020a0:	06f71763          	bne	a4,a5,8000210e <sched+0xa6>
  if(p->state == RUNNING)
    800020a4:	4c98                	lw	a4,24(s1)
    800020a6:	4791                	li	a5,4
    800020a8:	06f70b63          	beq	a4,a5,8000211e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b2:	efb5                	bnez	a5,8000212e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020b4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020b6:	00012917          	auipc	s2,0x12
    800020ba:	1ea90913          	addi	s2,s2,490 # 800142a0 <pid_lock>
    800020be:	2781                	sext.w	a5,a5
    800020c0:	079e                	slli	a5,a5,0x7
    800020c2:	97ca                	add	a5,a5,s2
    800020c4:	0ac7a983          	lw	s3,172(a5)
    800020c8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ca:	2781                	sext.w	a5,a5
    800020cc:	079e                	slli	a5,a5,0x7
    800020ce:	00012597          	auipc	a1,0x12
    800020d2:	20a58593          	addi	a1,a1,522 # 800142d8 <cpus+0x8>
    800020d6:	95be                	add	a1,a1,a5
    800020d8:	06048513          	addi	a0,s1,96
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	5b0080e7          	jalr	1456(ra) # 8000268c <swtch>
    800020e4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020e6:	2781                	sext.w	a5,a5
    800020e8:	079e                	slli	a5,a5,0x7
    800020ea:	97ca                	add	a5,a5,s2
    800020ec:	0b37a623          	sw	s3,172(a5)
}
    800020f0:	70a2                	ld	ra,40(sp)
    800020f2:	7402                	ld	s0,32(sp)
    800020f4:	64e2                	ld	s1,24(sp)
    800020f6:	6942                	ld	s2,16(sp)
    800020f8:	69a2                	ld	s3,8(sp)
    800020fa:	6145                	addi	sp,sp,48
    800020fc:	8082                	ret
    panic("sched p->lock");
    800020fe:	00006517          	auipc	a0,0x6
    80002102:	2aa50513          	addi	a0,a0,682 # 800083a8 <digits+0x368>
    80002106:	ffffe097          	auipc	ra,0xffffe
    8000210a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    panic("sched locks");
    8000210e:	00006517          	auipc	a0,0x6
    80002112:	2aa50513          	addi	a0,a0,682 # 800083b8 <digits+0x378>
    80002116:	ffffe097          	auipc	ra,0xffffe
    8000211a:	428080e7          	jalr	1064(ra) # 8000053e <panic>
    panic("sched running");
    8000211e:	00006517          	auipc	a0,0x6
    80002122:	2aa50513          	addi	a0,a0,682 # 800083c8 <digits+0x388>
    80002126:	ffffe097          	auipc	ra,0xffffe
    8000212a:	418080e7          	jalr	1048(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000212e:	00006517          	auipc	a0,0x6
    80002132:	2aa50513          	addi	a0,a0,682 # 800083d8 <digits+0x398>
    80002136:	ffffe097          	auipc	ra,0xffffe
    8000213a:	408080e7          	jalr	1032(ra) # 8000053e <panic>

000000008000213e <yield>:
{
    8000213e:	1101                	addi	sp,sp,-32
    80002140:	ec06                	sd	ra,24(sp)
    80002142:	e822                	sd	s0,16(sp)
    80002144:	e426                	sd	s1,8(sp)
    80002146:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	966080e7          	jalr	-1690(ra) # 80001aae <myproc>
    80002150:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a92080e7          	jalr	-1390(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000215a:	478d                	li	a5,3
    8000215c:	cc9c                	sw	a5,24(s1)
  sched();
    8000215e:	00000097          	auipc	ra,0x0
    80002162:	f0a080e7          	jalr	-246(ra) # 80002068 <sched>
  release(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	b30080e7          	jalr	-1232(ra) # 80000c98 <release>
}
    80002170:	60e2                	ld	ra,24(sp)
    80002172:	6442                	ld	s0,16(sp)
    80002174:	64a2                	ld	s1,8(sp)
    80002176:	6105                	addi	sp,sp,32
    80002178:	8082                	ret

000000008000217a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000217a:	7179                	addi	sp,sp,-48
    8000217c:	f406                	sd	ra,40(sp)
    8000217e:	f022                	sd	s0,32(sp)
    80002180:	ec26                	sd	s1,24(sp)
    80002182:	e84a                	sd	s2,16(sp)
    80002184:	e44e                	sd	s3,8(sp)
    80002186:	1800                	addi	s0,sp,48
    80002188:	89aa                	mv	s3,a0
    8000218a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	922080e7          	jalr	-1758(ra) # 80001aae <myproc>
    80002194:	84aa                	mv	s1,a0
  printf("pid %d sleep.\n",p->pid);
    80002196:	590c                	lw	a1,48(a0)
    80002198:	00006517          	auipc	a0,0x6
    8000219c:	25850513          	addi	a0,a0,600 # 800083f0 <digits+0x3b0>
    800021a0:	ffffe097          	auipc	ra,0xffffe
    800021a4:	3e8080e7          	jalr	1000(ra) # 80000588 <printf>
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	a3a080e7          	jalr	-1478(ra) # 80000be4 <acquire>
  release(lk);
    800021b2:	854a                	mv	a0,s2
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    800021bc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021c0:	4789                	li	a5,2
    800021c2:	cc9c                	sw	a5,24(s1)

  sched();
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	ea4080e7          	jalr	-348(ra) # 80002068 <sched>

  // Tidy up.
  p->chan = 0;
    800021cc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
  acquire(lk);
    800021da:	854a                	mv	a0,s2
    800021dc:	fffff097          	auipc	ra,0xfffff
    800021e0:	a08080e7          	jalr	-1528(ra) # 80000be4 <acquire>
}
    800021e4:	70a2                	ld	ra,40(sp)
    800021e6:	7402                	ld	s0,32(sp)
    800021e8:	64e2                	ld	s1,24(sp)
    800021ea:	6942                	ld	s2,16(sp)
    800021ec:	69a2                	ld	s3,8(sp)
    800021ee:	6145                	addi	sp,sp,48
    800021f0:	8082                	ret

00000000800021f2 <wait>:
{
    800021f2:	715d                	addi	sp,sp,-80
    800021f4:	e486                	sd	ra,72(sp)
    800021f6:	e0a2                	sd	s0,64(sp)
    800021f8:	fc26                	sd	s1,56(sp)
    800021fa:	f84a                	sd	s2,48(sp)
    800021fc:	f44e                	sd	s3,40(sp)
    800021fe:	f052                	sd	s4,32(sp)
    80002200:	ec56                	sd	s5,24(sp)
    80002202:	e85a                	sd	s6,16(sp)
    80002204:	e45e                	sd	s7,8(sp)
    80002206:	e062                	sd	s8,0(sp)
    80002208:	0880                	addi	s0,sp,80
    8000220a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	8a2080e7          	jalr	-1886(ra) # 80001aae <myproc>
    80002214:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002216:	00012517          	auipc	a0,0x12
    8000221a:	0a250513          	addi	a0,a0,162 # 800142b8 <wait_lock>
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9c6080e7          	jalr	-1594(ra) # 80000be4 <acquire>
    havekids = 0;
    80002226:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002228:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000222a:	00018997          	auipc	s3,0x18
    8000222e:	ea698993          	addi	s3,s3,-346 # 8001a0d0 <tickslock>
        havekids = 1;
    80002232:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002234:	00012c17          	auipc	s8,0x12
    80002238:	084c0c13          	addi	s8,s8,132 # 800142b8 <wait_lock>
    havekids = 0;
    8000223c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000223e:	00012497          	auipc	s1,0x12
    80002242:	49248493          	addi	s1,s1,1170 # 800146d0 <proc>
    80002246:	a0bd                	j	800022b4 <wait+0xc2>
          pid = np->pid;
    80002248:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000224c:	000b0e63          	beqz	s6,80002268 <wait+0x76>
    80002250:	4691                	li	a3,4
    80002252:	02c48613          	addi	a2,s1,44
    80002256:	85da                	mv	a1,s6
    80002258:	05093503          	ld	a0,80(s2)
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	514080e7          	jalr	1300(ra) # 80001770 <copyout>
    80002264:	02054563          	bltz	a0,8000228e <wait+0x9c>
          freeproc(np);
    80002268:	8526                	mv	a0,s1
    8000226a:	00000097          	auipc	ra,0x0
    8000226e:	9f6080e7          	jalr	-1546(ra) # 80001c60 <freeproc>
          release(&np->lock);
    80002272:	8526                	mv	a0,s1
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
          release(&wait_lock);
    8000227c:	00012517          	auipc	a0,0x12
    80002280:	03c50513          	addi	a0,a0,60 # 800142b8 <wait_lock>
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a14080e7          	jalr	-1516(ra) # 80000c98 <release>
          return pid;
    8000228c:	a09d                	j	800022f2 <wait+0x100>
            release(&np->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	a08080e7          	jalr	-1528(ra) # 80000c98 <release>
            release(&wait_lock);
    80002298:	00012517          	auipc	a0,0x12
    8000229c:	02050513          	addi	a0,a0,32 # 800142b8 <wait_lock>
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	9f8080e7          	jalr	-1544(ra) # 80000c98 <release>
            return -1;
    800022a8:	59fd                	li	s3,-1
    800022aa:	a0a1                	j	800022f2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800022ac:	16848493          	addi	s1,s1,360
    800022b0:	03348463          	beq	s1,s3,800022d8 <wait+0xe6>
      if(np->parent == p){
    800022b4:	7c9c                	ld	a5,56(s1)
    800022b6:	ff279be3          	bne	a5,s2,800022ac <wait+0xba>
        acquire(&np->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	928080e7          	jalr	-1752(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800022c4:	4c9c                	lw	a5,24(s1)
    800022c6:	f94781e3          	beq	a5,s4,80002248 <wait+0x56>
        release(&np->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
        havekids = 1;
    800022d4:	8756                	mv	a4,s5
    800022d6:	bfd9                	j	800022ac <wait+0xba>
    if(!havekids || p->killed){
    800022d8:	c701                	beqz	a4,800022e0 <wait+0xee>
    800022da:	02892783          	lw	a5,40(s2)
    800022de:	c79d                	beqz	a5,8000230c <wait+0x11a>
      release(&wait_lock);
    800022e0:	00012517          	auipc	a0,0x12
    800022e4:	fd850513          	addi	a0,a0,-40 # 800142b8 <wait_lock>
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	9b0080e7          	jalr	-1616(ra) # 80000c98 <release>
      return -1;
    800022f0:	59fd                	li	s3,-1
}
    800022f2:	854e                	mv	a0,s3
    800022f4:	60a6                	ld	ra,72(sp)
    800022f6:	6406                	ld	s0,64(sp)
    800022f8:	74e2                	ld	s1,56(sp)
    800022fa:	7942                	ld	s2,48(sp)
    800022fc:	79a2                	ld	s3,40(sp)
    800022fe:	7a02                	ld	s4,32(sp)
    80002300:	6ae2                	ld	s5,24(sp)
    80002302:	6b42                	ld	s6,16(sp)
    80002304:	6ba2                	ld	s7,8(sp)
    80002306:	6c02                	ld	s8,0(sp)
    80002308:	6161                	addi	sp,sp,80
    8000230a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000230c:	85e2                	mv	a1,s8
    8000230e:	854a                	mv	a0,s2
    80002310:	00000097          	auipc	ra,0x0
    80002314:	e6a080e7          	jalr	-406(ra) # 8000217a <sleep>
    havekids = 0;
    80002318:	b715                	j	8000223c <wait+0x4a>

000000008000231a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000231a:	7139                	addi	sp,sp,-64
    8000231c:	fc06                	sd	ra,56(sp)
    8000231e:	f822                	sd	s0,48(sp)
    80002320:	f426                	sd	s1,40(sp)
    80002322:	f04a                	sd	s2,32(sp)
    80002324:	ec4e                	sd	s3,24(sp)
    80002326:	e852                	sd	s4,16(sp)
    80002328:	e456                	sd	s5,8(sp)
    8000232a:	0080                	addi	s0,sp,64
    8000232c:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000232e:	00012497          	auipc	s1,0x12
    80002332:	3a248493          	addi	s1,s1,930 # 800146d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002336:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002338:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000233a:	00018917          	auipc	s2,0x18
    8000233e:	d9690913          	addi	s2,s2,-618 # 8001a0d0 <tickslock>
    80002342:	a821                	j	8000235a <wakeup+0x40>
        p->state = RUNNABLE;
    80002344:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	94e080e7          	jalr	-1714(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002352:	16848493          	addi	s1,s1,360
    80002356:	03248463          	beq	s1,s2,8000237e <wakeup+0x64>
    if(p != myproc()){
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	754080e7          	jalr	1876(ra) # 80001aae <myproc>
    80002362:	fea488e3          	beq	s1,a0,80002352 <wakeup+0x38>
      acquire(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002370:	4c9c                	lw	a5,24(s1)
    80002372:	fd379be3          	bne	a5,s3,80002348 <wakeup+0x2e>
    80002376:	709c                	ld	a5,32(s1)
    80002378:	fd4798e3          	bne	a5,s4,80002348 <wakeup+0x2e>
    8000237c:	b7e1                	j	80002344 <wakeup+0x2a>
    }
  }
}
    8000237e:	70e2                	ld	ra,56(sp)
    80002380:	7442                	ld	s0,48(sp)
    80002382:	74a2                	ld	s1,40(sp)
    80002384:	7902                	ld	s2,32(sp)
    80002386:	69e2                	ld	s3,24(sp)
    80002388:	6a42                	ld	s4,16(sp)
    8000238a:	6aa2                	ld	s5,8(sp)
    8000238c:	6121                	addi	sp,sp,64
    8000238e:	8082                	ret

0000000080002390 <reparent>:
{
    80002390:	7179                	addi	sp,sp,-48
    80002392:	f406                	sd	ra,40(sp)
    80002394:	f022                	sd	s0,32(sp)
    80002396:	ec26                	sd	s1,24(sp)
    80002398:	e84a                	sd	s2,16(sp)
    8000239a:	e44e                	sd	s3,8(sp)
    8000239c:	e052                	sd	s4,0(sp)
    8000239e:	1800                	addi	s0,sp,48
    800023a0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a2:	00012497          	auipc	s1,0x12
    800023a6:	32e48493          	addi	s1,s1,814 # 800146d0 <proc>
      pp->parent = initproc;
    800023aa:	0000aa17          	auipc	s4,0xa
    800023ae:	c7ea0a13          	addi	s4,s4,-898 # 8000c028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b2:	00018997          	auipc	s3,0x18
    800023b6:	d1e98993          	addi	s3,s3,-738 # 8001a0d0 <tickslock>
    800023ba:	a029                	j	800023c4 <reparent+0x34>
    800023bc:	16848493          	addi	s1,s1,360
    800023c0:	01348d63          	beq	s1,s3,800023da <reparent+0x4a>
    if(pp->parent == p){
    800023c4:	7c9c                	ld	a5,56(s1)
    800023c6:	ff279be3          	bne	a5,s2,800023bc <reparent+0x2c>
      pp->parent = initproc;
    800023ca:	000a3503          	ld	a0,0(s4)
    800023ce:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800023d0:	00000097          	auipc	ra,0x0
    800023d4:	f4a080e7          	jalr	-182(ra) # 8000231a <wakeup>
    800023d8:	b7d5                	j	800023bc <reparent+0x2c>
}
    800023da:	70a2                	ld	ra,40(sp)
    800023dc:	7402                	ld	s0,32(sp)
    800023de:	64e2                	ld	s1,24(sp)
    800023e0:	6942                	ld	s2,16(sp)
    800023e2:	69a2                	ld	s3,8(sp)
    800023e4:	6a02                	ld	s4,0(sp)
    800023e6:	6145                	addi	sp,sp,48
    800023e8:	8082                	ret

00000000800023ea <exit>:
{
    800023ea:	7179                	addi	sp,sp,-48
    800023ec:	f406                	sd	ra,40(sp)
    800023ee:	f022                	sd	s0,32(sp)
    800023f0:	ec26                	sd	s1,24(sp)
    800023f2:	e84a                	sd	s2,16(sp)
    800023f4:	e44e                	sd	s3,8(sp)
    800023f6:	e052                	sd	s4,0(sp)
    800023f8:	1800                	addi	s0,sp,48
    800023fa:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	6b2080e7          	jalr	1714(ra) # 80001aae <myproc>
    80002404:	89aa                	mv	s3,a0
  if(p == initproc)
    80002406:	0000a797          	auipc	a5,0xa
    8000240a:	c227b783          	ld	a5,-990(a5) # 8000c028 <initproc>
    8000240e:	0d050493          	addi	s1,a0,208
    80002412:	15050913          	addi	s2,a0,336
    80002416:	02a79363          	bne	a5,a0,8000243c <exit+0x52>
    panic("init exiting");
    8000241a:	00006517          	auipc	a0,0x6
    8000241e:	fe650513          	addi	a0,a0,-26 # 80008400 <digits+0x3c0>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	11c080e7          	jalr	284(ra) # 8000053e <panic>
      fileclose(f);
    8000242a:	00002097          	auipc	ra,0x2
    8000242e:	164080e7          	jalr	356(ra) # 8000458e <fileclose>
      p->ofile[fd] = 0;
    80002432:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002436:	04a1                	addi	s1,s1,8
    80002438:	01248563          	beq	s1,s2,80002442 <exit+0x58>
    if(p->ofile[fd]){
    8000243c:	6088                	ld	a0,0(s1)
    8000243e:	f575                	bnez	a0,8000242a <exit+0x40>
    80002440:	bfdd                	j	80002436 <exit+0x4c>
  begin_op();
    80002442:	00002097          	auipc	ra,0x2
    80002446:	c80080e7          	jalr	-896(ra) # 800040c2 <begin_op>
  iput(p->cwd);
    8000244a:	1509b503          	ld	a0,336(s3)
    8000244e:	00001097          	auipc	ra,0x1
    80002452:	45c080e7          	jalr	1116(ra) # 800038aa <iput>
  end_op();
    80002456:	00002097          	auipc	ra,0x2
    8000245a:	cec080e7          	jalr	-788(ra) # 80004142 <end_op>
  p->cwd = 0;
    8000245e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002462:	00012497          	auipc	s1,0x12
    80002466:	e5648493          	addi	s1,s1,-426 # 800142b8 <wait_lock>
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	778080e7          	jalr	1912(ra) # 80000be4 <acquire>
  reparent(p);
    80002474:	854e                	mv	a0,s3
    80002476:	00000097          	auipc	ra,0x0
    8000247a:	f1a080e7          	jalr	-230(ra) # 80002390 <reparent>
  wakeup(p->parent);
    8000247e:	0389b503          	ld	a0,56(s3)
    80002482:	00000097          	auipc	ra,0x0
    80002486:	e98080e7          	jalr	-360(ra) # 8000231a <wakeup>
  acquire(&p->lock);
    8000248a:	854e                	mv	a0,s3
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	758080e7          	jalr	1880(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002494:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002498:	4795                	li	a5,5
    8000249a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
  sched();
    800024a8:	00000097          	auipc	ra,0x0
    800024ac:	bc0080e7          	jalr	-1088(ra) # 80002068 <sched>
  panic("zombie exit");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	f6050513          	addi	a0,a0,-160 # 80008410 <digits+0x3d0>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	086080e7          	jalr	134(ra) # 8000053e <panic>

00000000800024c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024d0:	00012497          	auipc	s1,0x12
    800024d4:	20048493          	addi	s1,s1,512 # 800146d0 <proc>
    800024d8:	00018997          	auipc	s3,0x18
    800024dc:	bf898993          	addi	s3,s3,-1032 # 8001a0d0 <tickslock>
    acquire(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	702080e7          	jalr	1794(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024ea:	589c                	lw	a5,48(s1)
    800024ec:	01278d63          	beq	a5,s2,80002506 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024f0:	8526                	mv	a0,s1
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	7a6080e7          	jalr	1958(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024fa:	16848493          	addi	s1,s1,360
    800024fe:	ff3491e3          	bne	s1,s3,800024e0 <kill+0x20>
  }
  return -1;
    80002502:	557d                	li	a0,-1
    80002504:	a829                	j	8000251e <kill+0x5e>
      p->killed = 1;
    80002506:	4785                	li	a5,1
    80002508:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000250a:	4c98                	lw	a4,24(s1)
    8000250c:	4789                	li	a5,2
    8000250e:	00f70f63          	beq	a4,a5,8000252c <kill+0x6c>
      release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
      return 0;
    8000251c:	4501                	li	a0,0
}
    8000251e:	70a2                	ld	ra,40(sp)
    80002520:	7402                	ld	s0,32(sp)
    80002522:	64e2                	ld	s1,24(sp)
    80002524:	6942                	ld	s2,16(sp)
    80002526:	69a2                	ld	s3,8(sp)
    80002528:	6145                	addi	sp,sp,48
    8000252a:	8082                	ret
        p->state = RUNNABLE;
    8000252c:	478d                	li	a5,3
    8000252e:	cc9c                	sw	a5,24(s1)
    80002530:	b7cd                	j	80002512 <kill+0x52>

0000000080002532 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002532:	7179                	addi	sp,sp,-48
    80002534:	f406                	sd	ra,40(sp)
    80002536:	f022                	sd	s0,32(sp)
    80002538:	ec26                	sd	s1,24(sp)
    8000253a:	e84a                	sd	s2,16(sp)
    8000253c:	e44e                	sd	s3,8(sp)
    8000253e:	e052                	sd	s4,0(sp)
    80002540:	1800                	addi	s0,sp,48
    80002542:	84aa                	mv	s1,a0
    80002544:	892e                	mv	s2,a1
    80002546:	89b2                	mv	s3,a2
    80002548:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	564080e7          	jalr	1380(ra) # 80001aae <myproc>
  if(user_dst){
    80002552:	c08d                	beqz	s1,80002574 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002554:	86d2                	mv	a3,s4
    80002556:	864e                	mv	a2,s3
    80002558:	85ca                	mv	a1,s2
    8000255a:	6928                	ld	a0,80(a0)
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	214080e7          	jalr	532(ra) # 80001770 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002564:	70a2                	ld	ra,40(sp)
    80002566:	7402                	ld	s0,32(sp)
    80002568:	64e2                	ld	s1,24(sp)
    8000256a:	6942                	ld	s2,16(sp)
    8000256c:	69a2                	ld	s3,8(sp)
    8000256e:	6a02                	ld	s4,0(sp)
    80002570:	6145                	addi	sp,sp,48
    80002572:	8082                	ret
    memmove((char *)dst, src, len);
    80002574:	000a061b          	sext.w	a2,s4
    80002578:	85ce                	mv	a1,s3
    8000257a:	854a                	mv	a0,s2
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	7c4080e7          	jalr	1988(ra) # 80000d40 <memmove>
    return 0;
    80002584:	8526                	mv	a0,s1
    80002586:	bff9                	j	80002564 <either_copyout+0x32>

0000000080002588 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002588:	7179                	addi	sp,sp,-48
    8000258a:	f406                	sd	ra,40(sp)
    8000258c:	f022                	sd	s0,32(sp)
    8000258e:	ec26                	sd	s1,24(sp)
    80002590:	e84a                	sd	s2,16(sp)
    80002592:	e44e                	sd	s3,8(sp)
    80002594:	e052                	sd	s4,0(sp)
    80002596:	1800                	addi	s0,sp,48
    80002598:	892a                	mv	s2,a0
    8000259a:	84ae                	mv	s1,a1
    8000259c:	89b2                	mv	s3,a2
    8000259e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	50e080e7          	jalr	1294(ra) # 80001aae <myproc>
  if(user_src){
    800025a8:	c08d                	beqz	s1,800025ca <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025aa:	86d2                	mv	a3,s4
    800025ac:	864e                	mv	a2,s3
    800025ae:	85ca                	mv	a1,s2
    800025b0:	6928                	ld	a0,80(a0)
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	24a080e7          	jalr	586(ra) # 800017fc <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025ba:	70a2                	ld	ra,40(sp)
    800025bc:	7402                	ld	s0,32(sp)
    800025be:	64e2                	ld	s1,24(sp)
    800025c0:	6942                	ld	s2,16(sp)
    800025c2:	69a2                	ld	s3,8(sp)
    800025c4:	6a02                	ld	s4,0(sp)
    800025c6:	6145                	addi	sp,sp,48
    800025c8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ca:	000a061b          	sext.w	a2,s4
    800025ce:	85ce                	mv	a1,s3
    800025d0:	854a                	mv	a0,s2
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	76e080e7          	jalr	1902(ra) # 80000d40 <memmove>
    return 0;
    800025da:	8526                	mv	a0,s1
    800025dc:	bff9                	j	800025ba <either_copyin+0x32>

00000000800025de <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025de:	715d                	addi	sp,sp,-80
    800025e0:	e486                	sd	ra,72(sp)
    800025e2:	e0a2                	sd	s0,64(sp)
    800025e4:	fc26                	sd	s1,56(sp)
    800025e6:	f84a                	sd	s2,48(sp)
    800025e8:	f44e                	sd	s3,40(sp)
    800025ea:	f052                	sd	s4,32(sp)
    800025ec:	ec56                	sd	s5,24(sp)
    800025ee:	e85a                	sd	s6,16(sp)
    800025f0:	e45e                	sd	s7,8(sp)
    800025f2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025f4:	00006517          	auipc	a0,0x6
    800025f8:	b2c50513          	addi	a0,a0,-1236 # 80008120 <digits+0xe0>
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	f8c080e7          	jalr	-116(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002604:	00012497          	auipc	s1,0x12
    80002608:	22448493          	addi	s1,s1,548 # 80014828 <proc+0x158>
    8000260c:	00018917          	auipc	s2,0x18
    80002610:	c1c90913          	addi	s2,s2,-996 # 8001a228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002614:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002616:	00006997          	auipc	s3,0x6
    8000261a:	e0a98993          	addi	s3,s3,-502 # 80008420 <digits+0x3e0>
    printf("%d %s %s", p->pid, state, p->name);
    8000261e:	00006a97          	auipc	s5,0x6
    80002622:	e0aa8a93          	addi	s5,s5,-502 # 80008428 <digits+0x3e8>
    printf("\n");
    80002626:	00006a17          	auipc	s4,0x6
    8000262a:	afaa0a13          	addi	s4,s4,-1286 # 80008120 <digits+0xe0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262e:	00006b97          	auipc	s7,0x6
    80002632:	e32b8b93          	addi	s7,s7,-462 # 80008460 <states.1709>
    80002636:	a00d                	j	80002658 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002638:	ed86a583          	lw	a1,-296(a3)
    8000263c:	8556                	mv	a0,s5
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	f4a080e7          	jalr	-182(ra) # 80000588 <printf>
    printf("\n");
    80002646:	8552                	mv	a0,s4
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	f40080e7          	jalr	-192(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002650:	16848493          	addi	s1,s1,360
    80002654:	03248163          	beq	s1,s2,80002676 <procdump+0x98>
    if(p->state == UNUSED)
    80002658:	86a6                	mv	a3,s1
    8000265a:	ec04a783          	lw	a5,-320(s1)
    8000265e:	dbed                	beqz	a5,80002650 <procdump+0x72>
      state = "???";
    80002660:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002662:	fcfb6be3          	bltu	s6,a5,80002638 <procdump+0x5a>
    80002666:	1782                	slli	a5,a5,0x20
    80002668:	9381                	srli	a5,a5,0x20
    8000266a:	078e                	slli	a5,a5,0x3
    8000266c:	97de                	add	a5,a5,s7
    8000266e:	6390                	ld	a2,0(a5)
    80002670:	f661                	bnez	a2,80002638 <procdump+0x5a>
      state = "???";
    80002672:	864e                	mv	a2,s3
    80002674:	b7d1                	j	80002638 <procdump+0x5a>
  }
}
    80002676:	60a6                	ld	ra,72(sp)
    80002678:	6406                	ld	s0,64(sp)
    8000267a:	74e2                	ld	s1,56(sp)
    8000267c:	7942                	ld	s2,48(sp)
    8000267e:	79a2                	ld	s3,40(sp)
    80002680:	7a02                	ld	s4,32(sp)
    80002682:	6ae2                	ld	s5,24(sp)
    80002684:	6b42                	ld	s6,16(sp)
    80002686:	6ba2                	ld	s7,8(sp)
    80002688:	6161                	addi	sp,sp,80
    8000268a:	8082                	ret

000000008000268c <swtch>:
    8000268c:	00153023          	sd	ra,0(a0)
    80002690:	00253423          	sd	sp,8(a0)
    80002694:	e900                	sd	s0,16(a0)
    80002696:	ed04                	sd	s1,24(a0)
    80002698:	03253023          	sd	s2,32(a0)
    8000269c:	03353423          	sd	s3,40(a0)
    800026a0:	03453823          	sd	s4,48(a0)
    800026a4:	03553c23          	sd	s5,56(a0)
    800026a8:	05653023          	sd	s6,64(a0)
    800026ac:	05753423          	sd	s7,72(a0)
    800026b0:	05853823          	sd	s8,80(a0)
    800026b4:	05953c23          	sd	s9,88(a0)
    800026b8:	07a53023          	sd	s10,96(a0)
    800026bc:	07b53423          	sd	s11,104(a0)
    800026c0:	0005b083          	ld	ra,0(a1)
    800026c4:	0085b103          	ld	sp,8(a1)
    800026c8:	6980                	ld	s0,16(a1)
    800026ca:	6d84                	ld	s1,24(a1)
    800026cc:	0205b903          	ld	s2,32(a1)
    800026d0:	0285b983          	ld	s3,40(a1)
    800026d4:	0305ba03          	ld	s4,48(a1)
    800026d8:	0385ba83          	ld	s5,56(a1)
    800026dc:	0405bb03          	ld	s6,64(a1)
    800026e0:	0485bb83          	ld	s7,72(a1)
    800026e4:	0505bc03          	ld	s8,80(a1)
    800026e8:	0585bc83          	ld	s9,88(a1)
    800026ec:	0605bd03          	ld	s10,96(a1)
    800026f0:	0685bd83          	ld	s11,104(a1)
    800026f4:	8082                	ret

00000000800026f6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f6:	1141                	addi	sp,sp,-16
    800026f8:	e406                	sd	ra,8(sp)
    800026fa:	e022                	sd	s0,0(sp)
    800026fc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fe:	00006597          	auipc	a1,0x6
    80002702:	d9258593          	addi	a1,a1,-622 # 80008490 <states.1709+0x30>
    80002706:	00018517          	auipc	a0,0x18
    8000270a:	9ca50513          	addi	a0,a0,-1590 # 8001a0d0 <tickslock>
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	446080e7          	jalr	1094(ra) # 80000b54 <initlock>
}
    80002716:	60a2                	ld	ra,8(sp)
    80002718:	6402                	ld	s0,0(sp)
    8000271a:	0141                	addi	sp,sp,16
    8000271c:	8082                	ret

000000008000271e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271e:	1141                	addi	sp,sp,-16
    80002720:	e422                	sd	s0,8(sp)
    80002722:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002724:	00003797          	auipc	a5,0x3
    80002728:	48c78793          	addi	a5,a5,1164 # 80005bb0 <kernelvec>
    8000272c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002730:	6422                	ld	s0,8(sp)
    80002732:	0141                	addi	sp,sp,16
    80002734:	8082                	ret

0000000080002736 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002736:	1141                	addi	sp,sp,-16
    80002738:	e406                	sd	ra,8(sp)
    8000273a:	e022                	sd	s0,0(sp)
    8000273c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273e:	fffff097          	auipc	ra,0xfffff
    80002742:	370080e7          	jalr	880(ra) # 80001aae <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002746:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000274a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002750:	00005617          	auipc	a2,0x5
    80002754:	8b060613          	addi	a2,a2,-1872 # 80007000 <_trampoline>
    80002758:	00005697          	auipc	a3,0x5
    8000275c:	8a868693          	addi	a3,a3,-1880 # 80007000 <_trampoline>
    80002760:	8e91                	sub	a3,a3,a2
    80002762:	008007b7          	lui	a5,0x800
    80002766:	17fd                	addi	a5,a5,-1
    80002768:	07ba                	slli	a5,a5,0xe
    8000276a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002770:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002772:	180026f3          	csrr	a3,satp
    80002776:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002778:	6d38                	ld	a4,88(a0)
    8000277a:	6134                	ld	a3,64(a0)
    8000277c:	6591                	lui	a1,0x4
    8000277e:	96ae                	add	a3,a3,a1
    80002780:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002782:	6d38                	ld	a4,88(a0)
    80002784:	00000697          	auipc	a3,0x0
    80002788:	13868693          	addi	a3,a3,312 # 800028bc <usertrap>
    8000278c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002790:	8692                	mv	a3,tp
    80002792:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002794:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002798:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027a0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a6:	6f18                	ld	a4,24(a4)
    800027a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027ac:	692c                	ld	a1,80(a0)
    800027ae:	81b9                	srli	a1,a1,0xe

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027b0:	00005717          	auipc	a4,0x5
    800027b4:	8e070713          	addi	a4,a4,-1824 # 80007090 <userret>
    800027b8:	8f11                	sub	a4,a4,a2
    800027ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027bc:	577d                	li	a4,-1
    800027be:	177e                	slli	a4,a4,0x3f
    800027c0:	8dd9                	or	a1,a1,a4
    800027c2:	00400537          	lui	a0,0x400
    800027c6:	157d                	addi	a0,a0,-1
    800027c8:	053e                	slli	a0,a0,0xf
    800027ca:	9782                	jalr	a5
}
    800027cc:	60a2                	ld	ra,8(sp)
    800027ce:	6402                	ld	s0,0(sp)
    800027d0:	0141                	addi	sp,sp,16
    800027d2:	8082                	ret

00000000800027d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d4:	1101                	addi	sp,sp,-32
    800027d6:	ec06                	sd	ra,24(sp)
    800027d8:	e822                	sd	s0,16(sp)
    800027da:	e426                	sd	s1,8(sp)
    800027dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027de:	00018497          	auipc	s1,0x18
    800027e2:	8f248493          	addi	s1,s1,-1806 # 8001a0d0 <tickslock>
    800027e6:	8526                	mv	a0,s1
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	3fc080e7          	jalr	1020(ra) # 80000be4 <acquire>
  ticks++;
    800027f0:	0000a517          	auipc	a0,0xa
    800027f4:	84050513          	addi	a0,a0,-1984 # 8000c030 <ticks>
    800027f8:	411c                	lw	a5,0(a0)
    800027fa:	2785                	addiw	a5,a5,1
    800027fc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	b1c080e7          	jalr	-1252(ra) # 8000231a <wakeup>
  release(&tickslock);
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	490080e7          	jalr	1168(ra) # 80000c98 <release>
}
    80002810:	60e2                	ld	ra,24(sp)
    80002812:	6442                	ld	s0,16(sp)
    80002814:	64a2                	ld	s1,8(sp)
    80002816:	6105                	addi	sp,sp,32
    80002818:	8082                	ret

000000008000281a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002824:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002828:	00074d63          	bltz	a4,80002842 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282c:	57fd                	li	a5,-1
    8000282e:	17fe                	slli	a5,a5,0x3f
    80002830:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002832:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002834:	06f70363          	beq	a4,a5,8000289a <devintr+0x80>
  }
}
    80002838:	60e2                	ld	ra,24(sp)
    8000283a:	6442                	ld	s0,16(sp)
    8000283c:	64a2                	ld	s1,8(sp)
    8000283e:	6105                	addi	sp,sp,32
    80002840:	8082                	ret
     (scause & 0xff) == 9){
    80002842:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002846:	46a5                	li	a3,9
    80002848:	fed792e3          	bne	a5,a3,8000282c <devintr+0x12>
    int irq = plic_claim();
    8000284c:	00003097          	auipc	ra,0x3
    80002850:	46c080e7          	jalr	1132(ra) # 80005cb8 <plic_claim>
    80002854:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002856:	47a9                	li	a5,10
    80002858:	02f50763          	beq	a0,a5,80002886 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285c:	4785                	li	a5,1
    8000285e:	02f50963          	beq	a0,a5,80002890 <devintr+0x76>
    return 1;
    80002862:	4505                	li	a0,1
    } else if(irq){
    80002864:	d8f1                	beqz	s1,80002838 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002866:	85a6                	mv	a1,s1
    80002868:	00006517          	auipc	a0,0x6
    8000286c:	c3050513          	addi	a0,a0,-976 # 80008498 <states.1709+0x38>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	d18080e7          	jalr	-744(ra) # 80000588 <printf>
      plic_complete(irq);
    80002878:	8526                	mv	a0,s1
    8000287a:	00003097          	auipc	ra,0x3
    8000287e:	462080e7          	jalr	1122(ra) # 80005cdc <plic_complete>
    return 1;
    80002882:	4505                	li	a0,1
    80002884:	bf55                	j	80002838 <devintr+0x1e>
      uartintr();
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	122080e7          	jalr	290(ra) # 800009a8 <uartintr>
    8000288e:	b7ed                	j	80002878 <devintr+0x5e>
      virtio_disk_intr();
    80002890:	00004097          	auipc	ra,0x4
    80002894:	95e080e7          	jalr	-1698(ra) # 800061ee <virtio_disk_intr>
    80002898:	b7c5                	j	80002878 <devintr+0x5e>
    if(cpuid() == 0){
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	1e8080e7          	jalr	488(ra) # 80001a82 <cpuid>
    800028a2:	c901                	beqz	a0,800028b2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028aa:	14479073          	csrw	sip,a5
    return 2;
    800028ae:	4509                	li	a0,2
    800028b0:	b761                	j	80002838 <devintr+0x1e>
      clockintr();
    800028b2:	00000097          	auipc	ra,0x0
    800028b6:	f22080e7          	jalr	-222(ra) # 800027d4 <clockintr>
    800028ba:	b7ed                	j	800028a4 <devintr+0x8a>

00000000800028bc <usertrap>:
{
    800028bc:	1101                	addi	sp,sp,-32
    800028be:	ec06                	sd	ra,24(sp)
    800028c0:	e822                	sd	s0,16(sp)
    800028c2:	e426                	sd	s1,8(sp)
    800028c4:	e04a                	sd	s2,0(sp)
    800028c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028cc:	1007f793          	andi	a5,a5,256
    800028d0:	e3ad                	bnez	a5,80002932 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	00003797          	auipc	a5,0x3
    800028d6:	2de78793          	addi	a5,a5,734 # 80005bb0 <kernelvec>
    800028da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	1d0080e7          	jalr	464(ra) # 80001aae <myproc>
    800028e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102773          	csrr	a4,sepc
    800028ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f4:	47a1                	li	a5,8
    800028f6:	04f71c63          	bne	a4,a5,8000294e <usertrap+0x92>
    if(p->killed)
    800028fa:	551c                	lw	a5,40(a0)
    800028fc:	e3b9                	bnez	a5,80002942 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028fe:	6cb8                	ld	a4,88(s1)
    80002900:	6f1c                	ld	a5,24(a4)
    80002902:	0791                	addi	a5,a5,4
    80002904:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10079073          	csrw	sstatus,a5
    syscall();
    80002912:	00000097          	auipc	ra,0x0
    80002916:	2e0080e7          	jalr	736(ra) # 80002bf2 <syscall>
  if(p->killed)
    8000291a:	549c                	lw	a5,40(s1)
    8000291c:	ebc1                	bnez	a5,800029ac <usertrap+0xf0>
  usertrapret();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	e18080e7          	jalr	-488(ra) # 80002736 <usertrapret>
}
    80002926:	60e2                	ld	ra,24(sp)
    80002928:	6442                	ld	s0,16(sp)
    8000292a:	64a2                	ld	s1,8(sp)
    8000292c:	6902                	ld	s2,0(sp)
    8000292e:	6105                	addi	sp,sp,32
    80002930:	8082                	ret
    panic("usertrap: not from user mode");
    80002932:	00006517          	auipc	a0,0x6
    80002936:	b8650513          	addi	a0,a0,-1146 # 800084b8 <states.1709+0x58>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	c04080e7          	jalr	-1020(ra) # 8000053e <panic>
      exit(-1);
    80002942:	557d                	li	a0,-1
    80002944:	00000097          	auipc	ra,0x0
    80002948:	aa6080e7          	jalr	-1370(ra) # 800023ea <exit>
    8000294c:	bf4d                	j	800028fe <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	ecc080e7          	jalr	-308(ra) # 8000281a <devintr>
    80002956:	892a                	mv	s2,a0
    80002958:	c501                	beqz	a0,80002960 <usertrap+0xa4>
  if(p->killed)
    8000295a:	549c                	lw	a5,40(s1)
    8000295c:	c3a1                	beqz	a5,8000299c <usertrap+0xe0>
    8000295e:	a815                	j	80002992 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002964:	5890                	lw	a2,48(s1)
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	b7250513          	addi	a0,a0,-1166 # 800084d8 <states.1709+0x78>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c1a080e7          	jalr	-998(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002976:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	b8a50513          	addi	a0,a0,-1142 # 80008508 <states.1709+0xa8>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	c02080e7          	jalr	-1022(ra) # 80000588 <printf>
    p->killed = 1;
    8000298e:	4785                	li	a5,1
    80002990:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002992:	557d                	li	a0,-1
    80002994:	00000097          	auipc	ra,0x0
    80002998:	a56080e7          	jalr	-1450(ra) # 800023ea <exit>
  if(which_dev == 2)
    8000299c:	4789                	li	a5,2
    8000299e:	f8f910e3          	bne	s2,a5,8000291e <usertrap+0x62>
    yield();
    800029a2:	fffff097          	auipc	ra,0xfffff
    800029a6:	79c080e7          	jalr	1948(ra) # 8000213e <yield>
    800029aa:	bf95                	j	8000291e <usertrap+0x62>
  int which_dev = 0;
    800029ac:	4901                	li	s2,0
    800029ae:	b7d5                	j	80002992 <usertrap+0xd6>

00000000800029b0 <kerneltrap>:
{
    800029b0:	7179                	addi	sp,sp,-48
    800029b2:	f406                	sd	ra,40(sp)
    800029b4:	f022                	sd	s0,32(sp)
    800029b6:	ec26                	sd	s1,24(sp)
    800029b8:	e84a                	sd	s2,16(sp)
    800029ba:	e44e                	sd	s3,8(sp)
    800029bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029be:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ca:	1004f793          	andi	a5,s1,256
    800029ce:	cb85                	beqz	a5,800029fe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029d6:	ef85                	bnez	a5,80002a0e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	e42080e7          	jalr	-446(ra) # 8000281a <devintr>
    800029e0:	cd1d                	beqz	a0,80002a1e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029e2:	4789                	li	a5,2
    800029e4:	06f50a63          	beq	a0,a5,80002a58 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ec:	10049073          	csrw	sstatus,s1
}
    800029f0:	70a2                	ld	ra,40(sp)
    800029f2:	7402                	ld	s0,32(sp)
    800029f4:	64e2                	ld	s1,24(sp)
    800029f6:	6942                	ld	s2,16(sp)
    800029f8:	69a2                	ld	s3,8(sp)
    800029fa:	6145                	addi	sp,sp,48
    800029fc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	b2a50513          	addi	a0,a0,-1238 # 80008528 <states.1709+0xc8>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b38080e7          	jalr	-1224(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	b4250513          	addi	a0,a0,-1214 # 80008550 <states.1709+0xf0>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b28080e7          	jalr	-1240(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002a1e:	85ce                	mv	a1,s3
    80002a20:	00006517          	auipc	a0,0x6
    80002a24:	b5050513          	addi	a0,a0,-1200 # 80008570 <states.1709+0x110>
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b60080e7          	jalr	-1184(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a34:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	b4850513          	addi	a0,a0,-1208 # 80008580 <states.1709+0x120>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	b5050513          	addi	a0,a0,-1200 # 80008598 <states.1709+0x138>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	aee080e7          	jalr	-1298(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	056080e7          	jalr	86(ra) # 80001aae <myproc>
    80002a60:	d541                	beqz	a0,800029e8 <kerneltrap+0x38>
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	04c080e7          	jalr	76(ra) # 80001aae <myproc>
    80002a6a:	4d18                	lw	a4,24(a0)
    80002a6c:	4791                	li	a5,4
    80002a6e:	f6f71de3          	bne	a4,a5,800029e8 <kerneltrap+0x38>
    yield();
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	6cc080e7          	jalr	1740(ra) # 8000213e <yield>
    80002a7a:	b7bd                	j	800029e8 <kerneltrap+0x38>

0000000080002a7c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a7c:	1101                	addi	sp,sp,-32
    80002a7e:	ec06                	sd	ra,24(sp)
    80002a80:	e822                	sd	s0,16(sp)
    80002a82:	e426                	sd	s1,8(sp)
    80002a84:	1000                	addi	s0,sp,32
    80002a86:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	026080e7          	jalr	38(ra) # 80001aae <myproc>
  switch (n) {
    80002a90:	4795                	li	a5,5
    80002a92:	0497e163          	bltu	a5,s1,80002ad4 <argraw+0x58>
    80002a96:	048a                	slli	s1,s1,0x2
    80002a98:	00006717          	auipc	a4,0x6
    80002a9c:	b3870713          	addi	a4,a4,-1224 # 800085d0 <states.1709+0x170>
    80002aa0:	94ba                	add	s1,s1,a4
    80002aa2:	409c                	lw	a5,0(s1)
    80002aa4:	97ba                	add	a5,a5,a4
    80002aa6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret
    return p->trapframe->a1;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	7fa8                	ld	a0,120(a5)
    80002aba:	bfcd                	j	80002aac <argraw+0x30>
    return p->trapframe->a2;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	63c8                	ld	a0,128(a5)
    80002ac0:	b7f5                	j	80002aac <argraw+0x30>
    return p->trapframe->a3;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	67c8                	ld	a0,136(a5)
    80002ac6:	b7dd                	j	80002aac <argraw+0x30>
    return p->trapframe->a4;
    80002ac8:	6d3c                	ld	a5,88(a0)
    80002aca:	6bc8                	ld	a0,144(a5)
    80002acc:	b7c5                	j	80002aac <argraw+0x30>
    return p->trapframe->a5;
    80002ace:	6d3c                	ld	a5,88(a0)
    80002ad0:	6fc8                	ld	a0,152(a5)
    80002ad2:	bfe9                	j	80002aac <argraw+0x30>
  panic("argraw");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	ad450513          	addi	a0,a0,-1324 # 800085a8 <states.1709+0x148>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a62080e7          	jalr	-1438(ra) # 8000053e <panic>

0000000080002ae4 <fetchaddr>:
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84aa                	mv	s1,a0
    80002af2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	fba080e7          	jalr	-70(ra) # 80001aae <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002afc:	653c                	ld	a5,72(a0)
    80002afe:	02f4f863          	bgeu	s1,a5,80002b2e <fetchaddr+0x4a>
    80002b02:	00848713          	addi	a4,s1,8
    80002b06:	02e7e663          	bltu	a5,a4,80002b32 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b0a:	46a1                	li	a3,8
    80002b0c:	8626                	mv	a2,s1
    80002b0e:	85ca                	mv	a1,s2
    80002b10:	6928                	ld	a0,80(a0)
    80002b12:	fffff097          	auipc	ra,0xfffff
    80002b16:	cea080e7          	jalr	-790(ra) # 800017fc <copyin>
    80002b1a:	00a03533          	snez	a0,a0
    80002b1e:	40a00533          	neg	a0,a0
}
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6902                	ld	s2,0(sp)
    80002b2a:	6105                	addi	sp,sp,32
    80002b2c:	8082                	ret
    return -1;
    80002b2e:	557d                	li	a0,-1
    80002b30:	bfcd                	j	80002b22 <fetchaddr+0x3e>
    80002b32:	557d                	li	a0,-1
    80002b34:	b7fd                	j	80002b22 <fetchaddr+0x3e>

0000000080002b36 <fetchstr>:
{
    80002b36:	7179                	addi	sp,sp,-48
    80002b38:	f406                	sd	ra,40(sp)
    80002b3a:	f022                	sd	s0,32(sp)
    80002b3c:	ec26                	sd	s1,24(sp)
    80002b3e:	e84a                	sd	s2,16(sp)
    80002b40:	e44e                	sd	s3,8(sp)
    80002b42:	1800                	addi	s0,sp,48
    80002b44:	892a                	mv	s2,a0
    80002b46:	84ae                	mv	s1,a1
    80002b48:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	f64080e7          	jalr	-156(ra) # 80001aae <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b52:	86ce                	mv	a3,s3
    80002b54:	864a                	mv	a2,s2
    80002b56:	85a6                	mv	a1,s1
    80002b58:	6928                	ld	a0,80(a0)
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	d2e080e7          	jalr	-722(ra) # 80001888 <copyinstr>
  if(err < 0)
    80002b62:	00054763          	bltz	a0,80002b70 <fetchstr+0x3a>
  return strlen(buf);
    80002b66:	8526                	mv	a0,s1
    80002b68:	ffffe097          	auipc	ra,0xffffe
    80002b6c:	2fc080e7          	jalr	764(ra) # 80000e64 <strlen>
}
    80002b70:	70a2                	ld	ra,40(sp)
    80002b72:	7402                	ld	s0,32(sp)
    80002b74:	64e2                	ld	s1,24(sp)
    80002b76:	6942                	ld	s2,16(sp)
    80002b78:	69a2                	ld	s3,8(sp)
    80002b7a:	6145                	addi	sp,sp,48
    80002b7c:	8082                	ret

0000000080002b7e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b7e:	1101                	addi	sp,sp,-32
    80002b80:	ec06                	sd	ra,24(sp)
    80002b82:	e822                	sd	s0,16(sp)
    80002b84:	e426                	sd	s1,8(sp)
    80002b86:	1000                	addi	s0,sp,32
    80002b88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	ef2080e7          	jalr	-270(ra) # 80002a7c <argraw>
    80002b92:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b94:	4501                	li	a0,0
    80002b96:	60e2                	ld	ra,24(sp)
    80002b98:	6442                	ld	s0,16(sp)
    80002b9a:	64a2                	ld	s1,8(sp)
    80002b9c:	6105                	addi	sp,sp,32
    80002b9e:	8082                	ret

0000000080002ba0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ba0:	1101                	addi	sp,sp,-32
    80002ba2:	ec06                	sd	ra,24(sp)
    80002ba4:	e822                	sd	s0,16(sp)
    80002ba6:	e426                	sd	s1,8(sp)
    80002ba8:	1000                	addi	s0,sp,32
    80002baa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	ed0080e7          	jalr	-304(ra) # 80002a7c <argraw>
    80002bb4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bb6:	4501                	li	a0,0
    80002bb8:	60e2                	ld	ra,24(sp)
    80002bba:	6442                	ld	s0,16(sp)
    80002bbc:	64a2                	ld	s1,8(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
    80002bce:	84ae                	mv	s1,a1
    80002bd0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	eaa080e7          	jalr	-342(ra) # 80002a7c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bda:	864a                	mv	a2,s2
    80002bdc:	85a6                	mv	a1,s1
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	f58080e7          	jalr	-168(ra) # 80002b36 <fetchstr>
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6902                	ld	s2,0(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bf2:	1101                	addi	sp,sp,-32
    80002bf4:	ec06                	sd	ra,24(sp)
    80002bf6:	e822                	sd	s0,16(sp)
    80002bf8:	e426                	sd	s1,8(sp)
    80002bfa:	e04a                	sd	s2,0(sp)
    80002bfc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	eb0080e7          	jalr	-336(ra) # 80001aae <myproc>
    80002c06:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c08:	05853903          	ld	s2,88(a0)
    80002c0c:	0a893783          	ld	a5,168(s2)
    80002c10:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c14:	37fd                	addiw	a5,a5,-1
    80002c16:	4751                	li	a4,20
    80002c18:	00f76f63          	bltu	a4,a5,80002c36 <syscall+0x44>
    80002c1c:	00369713          	slli	a4,a3,0x3
    80002c20:	00006797          	auipc	a5,0x6
    80002c24:	9c878793          	addi	a5,a5,-1592 # 800085e8 <syscalls>
    80002c28:	97ba                	add	a5,a5,a4
    80002c2a:	639c                	ld	a5,0(a5)
    80002c2c:	c789                	beqz	a5,80002c36 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c2e:	9782                	jalr	a5
    80002c30:	06a93823          	sd	a0,112(s2)
    80002c34:	a839                	j	80002c52 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c36:	15848613          	addi	a2,s1,344
    80002c3a:	588c                	lw	a1,48(s1)
    80002c3c:	00006517          	auipc	a0,0x6
    80002c40:	97450513          	addi	a0,a0,-1676 # 800085b0 <states.1709+0x150>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	944080e7          	jalr	-1724(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c4c:	6cbc                	ld	a5,88(s1)
    80002c4e:	577d                	li	a4,-1
    80002c50:	fbb8                	sd	a4,112(a5)
  }
}
    80002c52:	60e2                	ld	ra,24(sp)
    80002c54:	6442                	ld	s0,16(sp)
    80002c56:	64a2                	ld	s1,8(sp)
    80002c58:	6902                	ld	s2,0(sp)
    80002c5a:	6105                	addi	sp,sp,32
    80002c5c:	8082                	ret

0000000080002c5e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c66:	fec40593          	addi	a1,s0,-20
    80002c6a:	4501                	li	a0,0
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	f12080e7          	jalr	-238(ra) # 80002b7e <argint>
    return -1;
    80002c74:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c76:	00054963          	bltz	a0,80002c88 <sys_exit+0x2a>
  exit(n);
    80002c7a:	fec42503          	lw	a0,-20(s0)
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	76c080e7          	jalr	1900(ra) # 800023ea <exit>
  return 0;  // not reached
    80002c86:	4781                	li	a5,0
}
    80002c88:	853e                	mv	a0,a5
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	6105                	addi	sp,sp,32
    80002c90:	8082                	ret

0000000080002c92 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c92:	1141                	addi	sp,sp,-16
    80002c94:	e406                	sd	ra,8(sp)
    80002c96:	e022                	sd	s0,0(sp)
    80002c98:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	e14080e7          	jalr	-492(ra) # 80001aae <myproc>
}
    80002ca2:	5908                	lw	a0,48(a0)
    80002ca4:	60a2                	ld	ra,8(sp)
    80002ca6:	6402                	ld	s0,0(sp)
    80002ca8:	0141                	addi	sp,sp,16
    80002caa:	8082                	ret

0000000080002cac <sys_fork>:

uint64
sys_fork(void)
{
    80002cac:	1141                	addi	sp,sp,-16
    80002cae:	e406                	sd	ra,8(sp)
    80002cb0:	e022                	sd	s0,0(sp)
    80002cb2:	0800                	addi	s0,sp,16
  return fork();
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	1d8080e7          	jalr	472(ra) # 80001e8c <fork>
}
    80002cbc:	60a2                	ld	ra,8(sp)
    80002cbe:	6402                	ld	s0,0(sp)
    80002cc0:	0141                	addi	sp,sp,16
    80002cc2:	8082                	ret

0000000080002cc4 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ccc:	fe840593          	addi	a1,s0,-24
    80002cd0:	4501                	li	a0,0
    80002cd2:	00000097          	auipc	ra,0x0
    80002cd6:	ece080e7          	jalr	-306(ra) # 80002ba0 <argaddr>
    80002cda:	87aa                	mv	a5,a0
    return -1;
    80002cdc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cde:	0007c863          	bltz	a5,80002cee <sys_wait+0x2a>
  return wait(p);
    80002ce2:	fe843503          	ld	a0,-24(s0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	50c080e7          	jalr	1292(ra) # 800021f2 <wait>
}
    80002cee:	60e2                	ld	ra,24(sp)
    80002cf0:	6442                	ld	s0,16(sp)
    80002cf2:	6105                	addi	sp,sp,32
    80002cf4:	8082                	ret

0000000080002cf6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cf6:	7179                	addi	sp,sp,-48
    80002cf8:	f406                	sd	ra,40(sp)
    80002cfa:	f022                	sd	s0,32(sp)
    80002cfc:	ec26                	sd	s1,24(sp)
    80002cfe:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d00:	fdc40593          	addi	a1,s0,-36
    80002d04:	4501                	li	a0,0
    80002d06:	00000097          	auipc	ra,0x0
    80002d0a:	e78080e7          	jalr	-392(ra) # 80002b7e <argint>
    80002d0e:	87aa                	mv	a5,a0
    return -1;
    80002d10:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d12:	0207c063          	bltz	a5,80002d32 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	d98080e7          	jalr	-616(ra) # 80001aae <myproc>
    80002d1e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d20:	fdc42503          	lw	a0,-36(s0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	0f4080e7          	jalr	244(ra) # 80001e18 <growproc>
    80002d2c:	00054863          	bltz	a0,80002d3c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d30:	8526                	mv	a0,s1
}
    80002d32:	70a2                	ld	ra,40(sp)
    80002d34:	7402                	ld	s0,32(sp)
    80002d36:	64e2                	ld	s1,24(sp)
    80002d38:	6145                	addi	sp,sp,48
    80002d3a:	8082                	ret
    return -1;
    80002d3c:	557d                	li	a0,-1
    80002d3e:	bfd5                	j	80002d32 <sys_sbrk+0x3c>

0000000080002d40 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d40:	7139                	addi	sp,sp,-64
    80002d42:	fc06                	sd	ra,56(sp)
    80002d44:	f822                	sd	s0,48(sp)
    80002d46:	f426                	sd	s1,40(sp)
    80002d48:	f04a                	sd	s2,32(sp)
    80002d4a:	ec4e                	sd	s3,24(sp)
    80002d4c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d4e:	fcc40593          	addi	a1,s0,-52
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	e2a080e7          	jalr	-470(ra) # 80002b7e <argint>
    return -1;
    80002d5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d5e:	06054563          	bltz	a0,80002dc8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d62:	00017517          	auipc	a0,0x17
    80002d66:	36e50513          	addi	a0,a0,878 # 8001a0d0 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	e7a080e7          	jalr	-390(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d72:	00009917          	auipc	s2,0x9
    80002d76:	2be92903          	lw	s2,702(s2) # 8000c030 <ticks>
  while(ticks - ticks0 < n){
    80002d7a:	fcc42783          	lw	a5,-52(s0)
    80002d7e:	cf85                	beqz	a5,80002db6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d80:	00017997          	auipc	s3,0x17
    80002d84:	35098993          	addi	s3,s3,848 # 8001a0d0 <tickslock>
    80002d88:	00009497          	auipc	s1,0x9
    80002d8c:	2a848493          	addi	s1,s1,680 # 8000c030 <ticks>
    if(myproc()->killed){
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	d1e080e7          	jalr	-738(ra) # 80001aae <myproc>
    80002d98:	551c                	lw	a5,40(a0)
    80002d9a:	ef9d                	bnez	a5,80002dd8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d9c:	85ce                	mv	a1,s3
    80002d9e:	8526                	mv	a0,s1
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	3da080e7          	jalr	986(ra) # 8000217a <sleep>
  while(ticks - ticks0 < n){
    80002da8:	409c                	lw	a5,0(s1)
    80002daa:	412787bb          	subw	a5,a5,s2
    80002dae:	fcc42703          	lw	a4,-52(s0)
    80002db2:	fce7efe3          	bltu	a5,a4,80002d90 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002db6:	00017517          	auipc	a0,0x17
    80002dba:	31a50513          	addi	a0,a0,794 # 8001a0d0 <tickslock>
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	eda080e7          	jalr	-294(ra) # 80000c98 <release>
  return 0;
    80002dc6:	4781                	li	a5,0
}
    80002dc8:	853e                	mv	a0,a5
    80002dca:	70e2                	ld	ra,56(sp)
    80002dcc:	7442                	ld	s0,48(sp)
    80002dce:	74a2                	ld	s1,40(sp)
    80002dd0:	7902                	ld	s2,32(sp)
    80002dd2:	69e2                	ld	s3,24(sp)
    80002dd4:	6121                	addi	sp,sp,64
    80002dd6:	8082                	ret
      release(&tickslock);
    80002dd8:	00017517          	auipc	a0,0x17
    80002ddc:	2f850513          	addi	a0,a0,760 # 8001a0d0 <tickslock>
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	eb8080e7          	jalr	-328(ra) # 80000c98 <release>
      return -1;
    80002de8:	57fd                	li	a5,-1
    80002dea:	bff9                	j	80002dc8 <sys_sleep+0x88>

0000000080002dec <sys_kill>:

uint64
sys_kill(void)
{
    80002dec:	1101                	addi	sp,sp,-32
    80002dee:	ec06                	sd	ra,24(sp)
    80002df0:	e822                	sd	s0,16(sp)
    80002df2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002df4:	fec40593          	addi	a1,s0,-20
    80002df8:	4501                	li	a0,0
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	d84080e7          	jalr	-636(ra) # 80002b7e <argint>
    80002e02:	87aa                	mv	a5,a0
    return -1;
    80002e04:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e06:	0007c863          	bltz	a5,80002e16 <sys_kill+0x2a>
  return kill(pid);
    80002e0a:	fec42503          	lw	a0,-20(s0)
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	6b2080e7          	jalr	1714(ra) # 800024c0 <kill>
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	6105                	addi	sp,sp,32
    80002e1c:	8082                	ret

0000000080002e1e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e1e:	1101                	addi	sp,sp,-32
    80002e20:	ec06                	sd	ra,24(sp)
    80002e22:	e822                	sd	s0,16(sp)
    80002e24:	e426                	sd	s1,8(sp)
    80002e26:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e28:	00017517          	auipc	a0,0x17
    80002e2c:	2a850513          	addi	a0,a0,680 # 8001a0d0 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	db4080e7          	jalr	-588(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002e38:	00009497          	auipc	s1,0x9
    80002e3c:	1f84a483          	lw	s1,504(s1) # 8000c030 <ticks>
  release(&tickslock);
    80002e40:	00017517          	auipc	a0,0x17
    80002e44:	29050513          	addi	a0,a0,656 # 8001a0d0 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e50080e7          	jalr	-432(ra) # 80000c98 <release>
  return xticks;
}
    80002e50:	02049513          	slli	a0,s1,0x20
    80002e54:	9101                	srli	a0,a0,0x20
    80002e56:	60e2                	ld	ra,24(sp)
    80002e58:	6442                	ld	s0,16(sp)
    80002e5a:	64a2                	ld	s1,8(sp)
    80002e5c:	6105                	addi	sp,sp,32
    80002e5e:	8082                	ret

0000000080002e60 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e60:	7179                	addi	sp,sp,-48
    80002e62:	f406                	sd	ra,40(sp)
    80002e64:	f022                	sd	s0,32(sp)
    80002e66:	ec26                	sd	s1,24(sp)
    80002e68:	e84a                	sd	s2,16(sp)
    80002e6a:	e44e                	sd	s3,8(sp)
    80002e6c:	e052                	sd	s4,0(sp)
    80002e6e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e70:	00006597          	auipc	a1,0x6
    80002e74:	82858593          	addi	a1,a1,-2008 # 80008698 <syscalls+0xb0>
    80002e78:	00017517          	auipc	a0,0x17
    80002e7c:	27050513          	addi	a0,a0,624 # 8001a0e8 <bcache>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	cd4080e7          	jalr	-812(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e88:	0001f797          	auipc	a5,0x1f
    80002e8c:	26078793          	addi	a5,a5,608 # 800220e8 <bcache+0x8000>
    80002e90:	0001f717          	auipc	a4,0x1f
    80002e94:	4c070713          	addi	a4,a4,1216 # 80022350 <bcache+0x8268>
    80002e98:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e9c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ea0:	00017497          	auipc	s1,0x17
    80002ea4:	26048493          	addi	s1,s1,608 # 8001a100 <bcache+0x18>
    b->next = bcache.head.next;
    80002ea8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eaa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002eac:	00005a17          	auipc	s4,0x5
    80002eb0:	7f4a0a13          	addi	s4,s4,2036 # 800086a0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eb4:	2b893783          	ld	a5,696(s2)
    80002eb8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eba:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ebe:	85d2                	mv	a1,s4
    80002ec0:	01048513          	addi	a0,s1,16
    80002ec4:	00001097          	auipc	ra,0x1
    80002ec8:	4bc080e7          	jalr	1212(ra) # 80004380 <initsleeplock>
    bcache.head.next->prev = b;
    80002ecc:	2b893783          	ld	a5,696(s2)
    80002ed0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ed2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed6:	45848493          	addi	s1,s1,1112
    80002eda:	fd349de3          	bne	s1,s3,80002eb4 <binit+0x54>
  }
}
    80002ede:	70a2                	ld	ra,40(sp)
    80002ee0:	7402                	ld	s0,32(sp)
    80002ee2:	64e2                	ld	s1,24(sp)
    80002ee4:	6942                	ld	s2,16(sp)
    80002ee6:	69a2                	ld	s3,8(sp)
    80002ee8:	6a02                	ld	s4,0(sp)
    80002eea:	6145                	addi	sp,sp,48
    80002eec:	8082                	ret

0000000080002eee <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eee:	7179                	addi	sp,sp,-48
    80002ef0:	f406                	sd	ra,40(sp)
    80002ef2:	f022                	sd	s0,32(sp)
    80002ef4:	ec26                	sd	s1,24(sp)
    80002ef6:	e84a                	sd	s2,16(sp)
    80002ef8:	e44e                	sd	s3,8(sp)
    80002efa:	1800                	addi	s0,sp,48
    80002efc:	89aa                	mv	s3,a0
    80002efe:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f00:	00017517          	auipc	a0,0x17
    80002f04:	1e850513          	addi	a0,a0,488 # 8001a0e8 <bcache>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f10:	0001f497          	auipc	s1,0x1f
    80002f14:	4904b483          	ld	s1,1168(s1) # 800223a0 <bcache+0x82b8>
    80002f18:	0001f797          	auipc	a5,0x1f
    80002f1c:	43878793          	addi	a5,a5,1080 # 80022350 <bcache+0x8268>
    80002f20:	02f48f63          	beq	s1,a5,80002f5e <bread+0x70>
    80002f24:	873e                	mv	a4,a5
    80002f26:	a021                	j	80002f2e <bread+0x40>
    80002f28:	68a4                	ld	s1,80(s1)
    80002f2a:	02e48a63          	beq	s1,a4,80002f5e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f2e:	449c                	lw	a5,8(s1)
    80002f30:	ff379ce3          	bne	a5,s3,80002f28 <bread+0x3a>
    80002f34:	44dc                	lw	a5,12(s1)
    80002f36:	ff2799e3          	bne	a5,s2,80002f28 <bread+0x3a>
      b->refcnt++;
    80002f3a:	40bc                	lw	a5,64(s1)
    80002f3c:	2785                	addiw	a5,a5,1
    80002f3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f40:	00017517          	auipc	a0,0x17
    80002f44:	1a850513          	addi	a0,a0,424 # 8001a0e8 <bcache>
    80002f48:	ffffe097          	auipc	ra,0xffffe
    80002f4c:	d50080e7          	jalr	-688(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002f50:	01048513          	addi	a0,s1,16
    80002f54:	00001097          	auipc	ra,0x1
    80002f58:	466080e7          	jalr	1126(ra) # 800043ba <acquiresleep>
      return b;
    80002f5c:	a8b9                	j	80002fba <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f5e:	0001f497          	auipc	s1,0x1f
    80002f62:	43a4b483          	ld	s1,1082(s1) # 80022398 <bcache+0x82b0>
    80002f66:	0001f797          	auipc	a5,0x1f
    80002f6a:	3ea78793          	addi	a5,a5,1002 # 80022350 <bcache+0x8268>
    80002f6e:	00f48863          	beq	s1,a5,80002f7e <bread+0x90>
    80002f72:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f74:	40bc                	lw	a5,64(s1)
    80002f76:	cf81                	beqz	a5,80002f8e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f78:	64a4                	ld	s1,72(s1)
    80002f7a:	fee49de3          	bne	s1,a4,80002f74 <bread+0x86>
  panic("bget: no buffers");
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	72a50513          	addi	a0,a0,1834 # 800086a8 <syscalls+0xc0>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	5b8080e7          	jalr	1464(ra) # 8000053e <panic>
      b->dev = dev;
    80002f8e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f92:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f96:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f9a:	4785                	li	a5,1
    80002f9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f9e:	00017517          	auipc	a0,0x17
    80002fa2:	14a50513          	addi	a0,a0,330 # 8001a0e8 <bcache>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	cf2080e7          	jalr	-782(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002fae:	01048513          	addi	a0,s1,16
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	408080e7          	jalr	1032(ra) # 800043ba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fba:	409c                	lw	a5,0(s1)
    80002fbc:	cb89                	beqz	a5,80002fce <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fbe:	8526                	mv	a0,s1
    80002fc0:	70a2                	ld	ra,40(sp)
    80002fc2:	7402                	ld	s0,32(sp)
    80002fc4:	64e2                	ld	s1,24(sp)
    80002fc6:	6942                	ld	s2,16(sp)
    80002fc8:	69a2                	ld	s3,8(sp)
    80002fca:	6145                	addi	sp,sp,48
    80002fcc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fce:	4581                	li	a1,0
    80002fd0:	8526                	mv	a0,s1
    80002fd2:	00003097          	auipc	ra,0x3
    80002fd6:	f38080e7          	jalr	-200(ra) # 80005f0a <virtio_disk_rw>
    b->valid = 1;
    80002fda:	4785                	li	a5,1
    80002fdc:	c09c                	sw	a5,0(s1)
  return b;
    80002fde:	b7c5                	j	80002fbe <bread+0xd0>

0000000080002fe0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fe0:	1101                	addi	sp,sp,-32
    80002fe2:	ec06                	sd	ra,24(sp)
    80002fe4:	e822                	sd	s0,16(sp)
    80002fe6:	e426                	sd	s1,8(sp)
    80002fe8:	1000                	addi	s0,sp,32
    80002fea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fec:	0541                	addi	a0,a0,16
    80002fee:	00001097          	auipc	ra,0x1
    80002ff2:	466080e7          	jalr	1126(ra) # 80004454 <holdingsleep>
    80002ff6:	cd01                	beqz	a0,8000300e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ff8:	4585                	li	a1,1
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	00003097          	auipc	ra,0x3
    80003000:	f0e080e7          	jalr	-242(ra) # 80005f0a <virtio_disk_rw>
}
    80003004:	60e2                	ld	ra,24(sp)
    80003006:	6442                	ld	s0,16(sp)
    80003008:	64a2                	ld	s1,8(sp)
    8000300a:	6105                	addi	sp,sp,32
    8000300c:	8082                	ret
    panic("bwrite");
    8000300e:	00005517          	auipc	a0,0x5
    80003012:	6b250513          	addi	a0,a0,1714 # 800086c0 <syscalls+0xd8>
    80003016:	ffffd097          	auipc	ra,0xffffd
    8000301a:	528080e7          	jalr	1320(ra) # 8000053e <panic>

000000008000301e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000301e:	1101                	addi	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	e426                	sd	s1,8(sp)
    80003026:	e04a                	sd	s2,0(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000302c:	01050913          	addi	s2,a0,16
    80003030:	854a                	mv	a0,s2
    80003032:	00001097          	auipc	ra,0x1
    80003036:	422080e7          	jalr	1058(ra) # 80004454 <holdingsleep>
    8000303a:	c92d                	beqz	a0,800030ac <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000303c:	854a                	mv	a0,s2
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	3d2080e7          	jalr	978(ra) # 80004410 <releasesleep>

  acquire(&bcache.lock);
    80003046:	00017517          	auipc	a0,0x17
    8000304a:	0a250513          	addi	a0,a0,162 # 8001a0e8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	b96080e7          	jalr	-1130(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003056:	40bc                	lw	a5,64(s1)
    80003058:	37fd                	addiw	a5,a5,-1
    8000305a:	0007871b          	sext.w	a4,a5
    8000305e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003060:	eb05                	bnez	a4,80003090 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003062:	68bc                	ld	a5,80(s1)
    80003064:	64b8                	ld	a4,72(s1)
    80003066:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003068:	64bc                	ld	a5,72(s1)
    8000306a:	68b8                	ld	a4,80(s1)
    8000306c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000306e:	0001f797          	auipc	a5,0x1f
    80003072:	07a78793          	addi	a5,a5,122 # 800220e8 <bcache+0x8000>
    80003076:	2b87b703          	ld	a4,696(a5)
    8000307a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000307c:	0001f717          	auipc	a4,0x1f
    80003080:	2d470713          	addi	a4,a4,724 # 80022350 <bcache+0x8268>
    80003084:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003086:	2b87b703          	ld	a4,696(a5)
    8000308a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000308c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003090:	00017517          	auipc	a0,0x17
    80003094:	05850513          	addi	a0,a0,88 # 8001a0e8 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c00080e7          	jalr	-1024(ra) # 80000c98 <release>
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6902                	ld	s2,0(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret
    panic("brelse");
    800030ac:	00005517          	auipc	a0,0x5
    800030b0:	61c50513          	addi	a0,a0,1564 # 800086c8 <syscalls+0xe0>
    800030b4:	ffffd097          	auipc	ra,0xffffd
    800030b8:	48a080e7          	jalr	1162(ra) # 8000053e <panic>

00000000800030bc <bpin>:

void
bpin(struct buf *b) {
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	1000                	addi	s0,sp,32
    800030c6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030c8:	00017517          	auipc	a0,0x17
    800030cc:	02050513          	addi	a0,a0,32 # 8001a0e8 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	b14080e7          	jalr	-1260(ra) # 80000be4 <acquire>
  b->refcnt++;
    800030d8:	40bc                	lw	a5,64(s1)
    800030da:	2785                	addiw	a5,a5,1
    800030dc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030de:	00017517          	auipc	a0,0x17
    800030e2:	00a50513          	addi	a0,a0,10 # 8001a0e8 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	bb2080e7          	jalr	-1102(ra) # 80000c98 <release>
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	64a2                	ld	s1,8(sp)
    800030f4:	6105                	addi	sp,sp,32
    800030f6:	8082                	ret

00000000800030f8 <bunpin>:

void
bunpin(struct buf *b) {
    800030f8:	1101                	addi	sp,sp,-32
    800030fa:	ec06                	sd	ra,24(sp)
    800030fc:	e822                	sd	s0,16(sp)
    800030fe:	e426                	sd	s1,8(sp)
    80003100:	1000                	addi	s0,sp,32
    80003102:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003104:	00017517          	auipc	a0,0x17
    80003108:	fe450513          	addi	a0,a0,-28 # 8001a0e8 <bcache>
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	ad8080e7          	jalr	-1320(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003114:	40bc                	lw	a5,64(s1)
    80003116:	37fd                	addiw	a5,a5,-1
    80003118:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000311a:	00017517          	auipc	a0,0x17
    8000311e:	fce50513          	addi	a0,a0,-50 # 8001a0e8 <bcache>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	b76080e7          	jalr	-1162(ra) # 80000c98 <release>
}
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	64a2                	ld	s1,8(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret

0000000080003134 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	e04a                	sd	s2,0(sp)
    8000313e:	1000                	addi	s0,sp,32
    80003140:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003142:	00d5d59b          	srliw	a1,a1,0xd
    80003146:	0001f797          	auipc	a5,0x1f
    8000314a:	67e7a783          	lw	a5,1662(a5) # 800227c4 <sb+0x1c>
    8000314e:	9dbd                	addw	a1,a1,a5
    80003150:	00000097          	auipc	ra,0x0
    80003154:	d9e080e7          	jalr	-610(ra) # 80002eee <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003158:	0074f713          	andi	a4,s1,7
    8000315c:	4785                	li	a5,1
    8000315e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003162:	14ce                	slli	s1,s1,0x33
    80003164:	90d9                	srli	s1,s1,0x36
    80003166:	00950733          	add	a4,a0,s1
    8000316a:	05874703          	lbu	a4,88(a4)
    8000316e:	00e7f6b3          	and	a3,a5,a4
    80003172:	c69d                	beqz	a3,800031a0 <bfree+0x6c>
    80003174:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003176:	94aa                	add	s1,s1,a0
    80003178:	fff7c793          	not	a5,a5
    8000317c:	8ff9                	and	a5,a5,a4
    8000317e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003182:	00001097          	auipc	ra,0x1
    80003186:	118080e7          	jalr	280(ra) # 8000429a <log_write>
  brelse(bp);
    8000318a:	854a                	mv	a0,s2
    8000318c:	00000097          	auipc	ra,0x0
    80003190:	e92080e7          	jalr	-366(ra) # 8000301e <brelse>
}
    80003194:	60e2                	ld	ra,24(sp)
    80003196:	6442                	ld	s0,16(sp)
    80003198:	64a2                	ld	s1,8(sp)
    8000319a:	6902                	ld	s2,0(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret
    panic("freeing free block");
    800031a0:	00005517          	auipc	a0,0x5
    800031a4:	53050513          	addi	a0,a0,1328 # 800086d0 <syscalls+0xe8>
    800031a8:	ffffd097          	auipc	ra,0xffffd
    800031ac:	396080e7          	jalr	918(ra) # 8000053e <panic>

00000000800031b0 <balloc>:
{
    800031b0:	711d                	addi	sp,sp,-96
    800031b2:	ec86                	sd	ra,88(sp)
    800031b4:	e8a2                	sd	s0,80(sp)
    800031b6:	e4a6                	sd	s1,72(sp)
    800031b8:	e0ca                	sd	s2,64(sp)
    800031ba:	fc4e                	sd	s3,56(sp)
    800031bc:	f852                	sd	s4,48(sp)
    800031be:	f456                	sd	s5,40(sp)
    800031c0:	f05a                	sd	s6,32(sp)
    800031c2:	ec5e                	sd	s7,24(sp)
    800031c4:	e862                	sd	s8,16(sp)
    800031c6:	e466                	sd	s9,8(sp)
    800031c8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031ca:	0001f797          	auipc	a5,0x1f
    800031ce:	5e27a783          	lw	a5,1506(a5) # 800227ac <sb+0x4>
    800031d2:	cbd1                	beqz	a5,80003266 <balloc+0xb6>
    800031d4:	8baa                	mv	s7,a0
    800031d6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031d8:	0001fb17          	auipc	s6,0x1f
    800031dc:	5d0b0b13          	addi	s6,s6,1488 # 800227a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031e2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031e6:	6c89                	lui	s9,0x2
    800031e8:	a831                	j	80003204 <balloc+0x54>
    brelse(bp);
    800031ea:	854a                	mv	a0,s2
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	e32080e7          	jalr	-462(ra) # 8000301e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031f4:	015c87bb          	addw	a5,s9,s5
    800031f8:	00078a9b          	sext.w	s5,a5
    800031fc:	004b2703          	lw	a4,4(s6)
    80003200:	06eaf363          	bgeu	s5,a4,80003266 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003204:	41fad79b          	sraiw	a5,s5,0x1f
    80003208:	0137d79b          	srliw	a5,a5,0x13
    8000320c:	015787bb          	addw	a5,a5,s5
    80003210:	40d7d79b          	sraiw	a5,a5,0xd
    80003214:	01cb2583          	lw	a1,28(s6)
    80003218:	9dbd                	addw	a1,a1,a5
    8000321a:	855e                	mv	a0,s7
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	cd2080e7          	jalr	-814(ra) # 80002eee <bread>
    80003224:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003226:	004b2503          	lw	a0,4(s6)
    8000322a:	000a849b          	sext.w	s1,s5
    8000322e:	8662                	mv	a2,s8
    80003230:	faa4fde3          	bgeu	s1,a0,800031ea <balloc+0x3a>
      m = 1 << (bi % 8);
    80003234:	41f6579b          	sraiw	a5,a2,0x1f
    80003238:	01d7d69b          	srliw	a3,a5,0x1d
    8000323c:	00c6873b          	addw	a4,a3,a2
    80003240:	00777793          	andi	a5,a4,7
    80003244:	9f95                	subw	a5,a5,a3
    80003246:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000324a:	4037571b          	sraiw	a4,a4,0x3
    8000324e:	00e906b3          	add	a3,s2,a4
    80003252:	0586c683          	lbu	a3,88(a3)
    80003256:	00d7f5b3          	and	a1,a5,a3
    8000325a:	cd91                	beqz	a1,80003276 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325c:	2605                	addiw	a2,a2,1
    8000325e:	2485                	addiw	s1,s1,1
    80003260:	fd4618e3          	bne	a2,s4,80003230 <balloc+0x80>
    80003264:	b759                	j	800031ea <balloc+0x3a>
  panic("balloc: out of blocks");
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	48250513          	addi	a0,a0,1154 # 800086e8 <syscalls+0x100>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003276:	974a                	add	a4,a4,s2
    80003278:	8fd5                	or	a5,a5,a3
    8000327a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000327e:	854a                	mv	a0,s2
    80003280:	00001097          	auipc	ra,0x1
    80003284:	01a080e7          	jalr	26(ra) # 8000429a <log_write>
        brelse(bp);
    80003288:	854a                	mv	a0,s2
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	d94080e7          	jalr	-620(ra) # 8000301e <brelse>
  bp = bread(dev, bno);
    80003292:	85a6                	mv	a1,s1
    80003294:	855e                	mv	a0,s7
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	c58080e7          	jalr	-936(ra) # 80002eee <bread>
    8000329e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a0:	40000613          	li	a2,1024
    800032a4:	4581                	li	a1,0
    800032a6:	05850513          	addi	a0,a0,88
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a36080e7          	jalr	-1482(ra) # 80000ce0 <memset>
  log_write(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	fe6080e7          	jalr	-26(ra) # 8000429a <log_write>
  brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	d60080e7          	jalr	-672(ra) # 8000301e <brelse>
}
    800032c6:	8526                	mv	a0,s1
    800032c8:	60e6                	ld	ra,88(sp)
    800032ca:	6446                	ld	s0,80(sp)
    800032cc:	64a6                	ld	s1,72(sp)
    800032ce:	6906                	ld	s2,64(sp)
    800032d0:	79e2                	ld	s3,56(sp)
    800032d2:	7a42                	ld	s4,48(sp)
    800032d4:	7aa2                	ld	s5,40(sp)
    800032d6:	7b02                	ld	s6,32(sp)
    800032d8:	6be2                	ld	s7,24(sp)
    800032da:	6c42                	ld	s8,16(sp)
    800032dc:	6ca2                	ld	s9,8(sp)
    800032de:	6125                	addi	sp,sp,96
    800032e0:	8082                	ret

00000000800032e2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032e2:	7179                	addi	sp,sp,-48
    800032e4:	f406                	sd	ra,40(sp)
    800032e6:	f022                	sd	s0,32(sp)
    800032e8:	ec26                	sd	s1,24(sp)
    800032ea:	e84a                	sd	s2,16(sp)
    800032ec:	e44e                	sd	s3,8(sp)
    800032ee:	e052                	sd	s4,0(sp)
    800032f0:	1800                	addi	s0,sp,48
    800032f2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032f4:	47ad                	li	a5,11
    800032f6:	04b7fe63          	bgeu	a5,a1,80003352 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032fa:	ff45849b          	addiw	s1,a1,-12
    800032fe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003302:	0ff00793          	li	a5,255
    80003306:	0ae7e363          	bltu	a5,a4,800033ac <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000330a:	08052583          	lw	a1,128(a0)
    8000330e:	c5ad                	beqz	a1,80003378 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003310:	00092503          	lw	a0,0(s2)
    80003314:	00000097          	auipc	ra,0x0
    80003318:	bda080e7          	jalr	-1062(ra) # 80002eee <bread>
    8000331c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000331e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003322:	02049593          	slli	a1,s1,0x20
    80003326:	9181                	srli	a1,a1,0x20
    80003328:	058a                	slli	a1,a1,0x2
    8000332a:	00b784b3          	add	s1,a5,a1
    8000332e:	0004a983          	lw	s3,0(s1)
    80003332:	04098d63          	beqz	s3,8000338c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003336:	8552                	mv	a0,s4
    80003338:	00000097          	auipc	ra,0x0
    8000333c:	ce6080e7          	jalr	-794(ra) # 8000301e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003340:	854e                	mv	a0,s3
    80003342:	70a2                	ld	ra,40(sp)
    80003344:	7402                	ld	s0,32(sp)
    80003346:	64e2                	ld	s1,24(sp)
    80003348:	6942                	ld	s2,16(sp)
    8000334a:	69a2                	ld	s3,8(sp)
    8000334c:	6a02                	ld	s4,0(sp)
    8000334e:	6145                	addi	sp,sp,48
    80003350:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003352:	02059493          	slli	s1,a1,0x20
    80003356:	9081                	srli	s1,s1,0x20
    80003358:	048a                	slli	s1,s1,0x2
    8000335a:	94aa                	add	s1,s1,a0
    8000335c:	0504a983          	lw	s3,80(s1)
    80003360:	fe0990e3          	bnez	s3,80003340 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003364:	4108                	lw	a0,0(a0)
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	e4a080e7          	jalr	-438(ra) # 800031b0 <balloc>
    8000336e:	0005099b          	sext.w	s3,a0
    80003372:	0534a823          	sw	s3,80(s1)
    80003376:	b7e9                	j	80003340 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003378:	4108                	lw	a0,0(a0)
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	e36080e7          	jalr	-458(ra) # 800031b0 <balloc>
    80003382:	0005059b          	sext.w	a1,a0
    80003386:	08b92023          	sw	a1,128(s2)
    8000338a:	b759                	j	80003310 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000338c:	00092503          	lw	a0,0(s2)
    80003390:	00000097          	auipc	ra,0x0
    80003394:	e20080e7          	jalr	-480(ra) # 800031b0 <balloc>
    80003398:	0005099b          	sext.w	s3,a0
    8000339c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033a0:	8552                	mv	a0,s4
    800033a2:	00001097          	auipc	ra,0x1
    800033a6:	ef8080e7          	jalr	-264(ra) # 8000429a <log_write>
    800033aa:	b771                	j	80003336 <bmap+0x54>
  panic("bmap: out of range");
    800033ac:	00005517          	auipc	a0,0x5
    800033b0:	35450513          	addi	a0,a0,852 # 80008700 <syscalls+0x118>
    800033b4:	ffffd097          	auipc	ra,0xffffd
    800033b8:	18a080e7          	jalr	394(ra) # 8000053e <panic>

00000000800033bc <iget>:
{
    800033bc:	7179                	addi	sp,sp,-48
    800033be:	f406                	sd	ra,40(sp)
    800033c0:	f022                	sd	s0,32(sp)
    800033c2:	ec26                	sd	s1,24(sp)
    800033c4:	e84a                	sd	s2,16(sp)
    800033c6:	e44e                	sd	s3,8(sp)
    800033c8:	e052                	sd	s4,0(sp)
    800033ca:	1800                	addi	s0,sp,48
    800033cc:	89aa                	mv	s3,a0
    800033ce:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800033d0:	0001f517          	auipc	a0,0x1f
    800033d4:	3f850513          	addi	a0,a0,1016 # 800227c8 <itable>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	80c080e7          	jalr	-2036(ra) # 80000be4 <acquire>
  empty = 0;
    800033e0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033e2:	0001f497          	auipc	s1,0x1f
    800033e6:	3fe48493          	addi	s1,s1,1022 # 800227e0 <itable+0x18>
    800033ea:	00021697          	auipc	a3,0x21
    800033ee:	e8668693          	addi	a3,a3,-378 # 80024270 <log>
    800033f2:	a039                	j	80003400 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033f4:	02090b63          	beqz	s2,8000342a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033f8:	08848493          	addi	s1,s1,136
    800033fc:	02d48a63          	beq	s1,a3,80003430 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003400:	449c                	lw	a5,8(s1)
    80003402:	fef059e3          	blez	a5,800033f4 <iget+0x38>
    80003406:	4098                	lw	a4,0(s1)
    80003408:	ff3716e3          	bne	a4,s3,800033f4 <iget+0x38>
    8000340c:	40d8                	lw	a4,4(s1)
    8000340e:	ff4713e3          	bne	a4,s4,800033f4 <iget+0x38>
      ip->ref++;
    80003412:	2785                	addiw	a5,a5,1
    80003414:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003416:	0001f517          	auipc	a0,0x1f
    8000341a:	3b250513          	addi	a0,a0,946 # 800227c8 <itable>
    8000341e:	ffffe097          	auipc	ra,0xffffe
    80003422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
      return ip;
    80003426:	8926                	mv	s2,s1
    80003428:	a03d                	j	80003456 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000342a:	f7f9                	bnez	a5,800033f8 <iget+0x3c>
    8000342c:	8926                	mv	s2,s1
    8000342e:	b7e9                	j	800033f8 <iget+0x3c>
  if(empty == 0)
    80003430:	02090c63          	beqz	s2,80003468 <iget+0xac>
  ip->dev = dev;
    80003434:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003438:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000343c:	4785                	li	a5,1
    8000343e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003442:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003446:	0001f517          	auipc	a0,0x1f
    8000344a:	38250513          	addi	a0,a0,898 # 800227c8 <itable>
    8000344e:	ffffe097          	auipc	ra,0xffffe
    80003452:	84a080e7          	jalr	-1974(ra) # 80000c98 <release>
}
    80003456:	854a                	mv	a0,s2
    80003458:	70a2                	ld	ra,40(sp)
    8000345a:	7402                	ld	s0,32(sp)
    8000345c:	64e2                	ld	s1,24(sp)
    8000345e:	6942                	ld	s2,16(sp)
    80003460:	69a2                	ld	s3,8(sp)
    80003462:	6a02                	ld	s4,0(sp)
    80003464:	6145                	addi	sp,sp,48
    80003466:	8082                	ret
    panic("iget: no inodes");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	2b050513          	addi	a0,a0,688 # 80008718 <syscalls+0x130>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	0ce080e7          	jalr	206(ra) # 8000053e <panic>

0000000080003478 <fsinit>:
fsinit(int dev) {
    80003478:	7179                	addi	sp,sp,-48
    8000347a:	f406                	sd	ra,40(sp)
    8000347c:	f022                	sd	s0,32(sp)
    8000347e:	ec26                	sd	s1,24(sp)
    80003480:	e84a                	sd	s2,16(sp)
    80003482:	e44e                	sd	s3,8(sp)
    80003484:	1800                	addi	s0,sp,48
    80003486:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003488:	4585                	li	a1,1
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	a64080e7          	jalr	-1436(ra) # 80002eee <bread>
    80003492:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003494:	0001f997          	auipc	s3,0x1f
    80003498:	31498993          	addi	s3,s3,788 # 800227a8 <sb>
    8000349c:	02000613          	li	a2,32
    800034a0:	05850593          	addi	a1,a0,88
    800034a4:	854e                	mv	a0,s3
    800034a6:	ffffe097          	auipc	ra,0xffffe
    800034aa:	89a080e7          	jalr	-1894(ra) # 80000d40 <memmove>
  brelse(bp);
    800034ae:	8526                	mv	a0,s1
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	b6e080e7          	jalr	-1170(ra) # 8000301e <brelse>
  if(sb.magic != FSMAGIC)
    800034b8:	0009a703          	lw	a4,0(s3)
    800034bc:	102037b7          	lui	a5,0x10203
    800034c0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034c4:	02f71263          	bne	a4,a5,800034e8 <fsinit+0x70>
  initlog(dev, &sb);
    800034c8:	0001f597          	auipc	a1,0x1f
    800034cc:	2e058593          	addi	a1,a1,736 # 800227a8 <sb>
    800034d0:	854a                	mv	a0,s2
    800034d2:	00001097          	auipc	ra,0x1
    800034d6:	b4c080e7          	jalr	-1204(ra) # 8000401e <initlog>
}
    800034da:	70a2                	ld	ra,40(sp)
    800034dc:	7402                	ld	s0,32(sp)
    800034de:	64e2                	ld	s1,24(sp)
    800034e0:	6942                	ld	s2,16(sp)
    800034e2:	69a2                	ld	s3,8(sp)
    800034e4:	6145                	addi	sp,sp,48
    800034e6:	8082                	ret
    panic("invalid file system");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	24050513          	addi	a0,a0,576 # 80008728 <syscalls+0x140>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800034f8 <iinit>:
{
    800034f8:	7179                	addi	sp,sp,-48
    800034fa:	f406                	sd	ra,40(sp)
    800034fc:	f022                	sd	s0,32(sp)
    800034fe:	ec26                	sd	s1,24(sp)
    80003500:	e84a                	sd	s2,16(sp)
    80003502:	e44e                	sd	s3,8(sp)
    80003504:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003506:	00005597          	auipc	a1,0x5
    8000350a:	23a58593          	addi	a1,a1,570 # 80008740 <syscalls+0x158>
    8000350e:	0001f517          	auipc	a0,0x1f
    80003512:	2ba50513          	addi	a0,a0,698 # 800227c8 <itable>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	63e080e7          	jalr	1598(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000351e:	0001f497          	auipc	s1,0x1f
    80003522:	2d248493          	addi	s1,s1,722 # 800227f0 <itable+0x28>
    80003526:	00021997          	auipc	s3,0x21
    8000352a:	d5a98993          	addi	s3,s3,-678 # 80024280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000352e:	00005917          	auipc	s2,0x5
    80003532:	21a90913          	addi	s2,s2,538 # 80008748 <syscalls+0x160>
    80003536:	85ca                	mv	a1,s2
    80003538:	8526                	mv	a0,s1
    8000353a:	00001097          	auipc	ra,0x1
    8000353e:	e46080e7          	jalr	-442(ra) # 80004380 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003542:	08848493          	addi	s1,s1,136
    80003546:	ff3498e3          	bne	s1,s3,80003536 <iinit+0x3e>
}
    8000354a:	70a2                	ld	ra,40(sp)
    8000354c:	7402                	ld	s0,32(sp)
    8000354e:	64e2                	ld	s1,24(sp)
    80003550:	6942                	ld	s2,16(sp)
    80003552:	69a2                	ld	s3,8(sp)
    80003554:	6145                	addi	sp,sp,48
    80003556:	8082                	ret

0000000080003558 <ialloc>:
{
    80003558:	715d                	addi	sp,sp,-80
    8000355a:	e486                	sd	ra,72(sp)
    8000355c:	e0a2                	sd	s0,64(sp)
    8000355e:	fc26                	sd	s1,56(sp)
    80003560:	f84a                	sd	s2,48(sp)
    80003562:	f44e                	sd	s3,40(sp)
    80003564:	f052                	sd	s4,32(sp)
    80003566:	ec56                	sd	s5,24(sp)
    80003568:	e85a                	sd	s6,16(sp)
    8000356a:	e45e                	sd	s7,8(sp)
    8000356c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000356e:	0001f717          	auipc	a4,0x1f
    80003572:	24672703          	lw	a4,582(a4) # 800227b4 <sb+0xc>
    80003576:	4785                	li	a5,1
    80003578:	04e7fa63          	bgeu	a5,a4,800035cc <ialloc+0x74>
    8000357c:	8aaa                	mv	s5,a0
    8000357e:	8bae                	mv	s7,a1
    80003580:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003582:	0001fa17          	auipc	s4,0x1f
    80003586:	226a0a13          	addi	s4,s4,550 # 800227a8 <sb>
    8000358a:	00048b1b          	sext.w	s6,s1
    8000358e:	0044d593          	srli	a1,s1,0x4
    80003592:	018a2783          	lw	a5,24(s4)
    80003596:	9dbd                	addw	a1,a1,a5
    80003598:	8556                	mv	a0,s5
    8000359a:	00000097          	auipc	ra,0x0
    8000359e:	954080e7          	jalr	-1708(ra) # 80002eee <bread>
    800035a2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035a4:	05850993          	addi	s3,a0,88
    800035a8:	00f4f793          	andi	a5,s1,15
    800035ac:	079a                	slli	a5,a5,0x6
    800035ae:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035b0:	00099783          	lh	a5,0(s3)
    800035b4:	c785                	beqz	a5,800035dc <ialloc+0x84>
    brelse(bp);
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	a68080e7          	jalr	-1432(ra) # 8000301e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035be:	0485                	addi	s1,s1,1
    800035c0:	00ca2703          	lw	a4,12(s4)
    800035c4:	0004879b          	sext.w	a5,s1
    800035c8:	fce7e1e3          	bltu	a5,a4,8000358a <ialloc+0x32>
  panic("ialloc: no inodes");
    800035cc:	00005517          	auipc	a0,0x5
    800035d0:	18450513          	addi	a0,a0,388 # 80008750 <syscalls+0x168>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	f6a080e7          	jalr	-150(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800035dc:	04000613          	li	a2,64
    800035e0:	4581                	li	a1,0
    800035e2:	854e                	mv	a0,s3
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	6fc080e7          	jalr	1788(ra) # 80000ce0 <memset>
      dip->type = type;
    800035ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035f0:	854a                	mv	a0,s2
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	ca8080e7          	jalr	-856(ra) # 8000429a <log_write>
      brelse(bp);
    800035fa:	854a                	mv	a0,s2
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	a22080e7          	jalr	-1502(ra) # 8000301e <brelse>
      return iget(dev, inum);
    80003604:	85da                	mv	a1,s6
    80003606:	8556                	mv	a0,s5
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	db4080e7          	jalr	-588(ra) # 800033bc <iget>
}
    80003610:	60a6                	ld	ra,72(sp)
    80003612:	6406                	ld	s0,64(sp)
    80003614:	74e2                	ld	s1,56(sp)
    80003616:	7942                	ld	s2,48(sp)
    80003618:	79a2                	ld	s3,40(sp)
    8000361a:	7a02                	ld	s4,32(sp)
    8000361c:	6ae2                	ld	s5,24(sp)
    8000361e:	6b42                	ld	s6,16(sp)
    80003620:	6ba2                	ld	s7,8(sp)
    80003622:	6161                	addi	sp,sp,80
    80003624:	8082                	ret

0000000080003626 <iupdate>:
{
    80003626:	1101                	addi	sp,sp,-32
    80003628:	ec06                	sd	ra,24(sp)
    8000362a:	e822                	sd	s0,16(sp)
    8000362c:	e426                	sd	s1,8(sp)
    8000362e:	e04a                	sd	s2,0(sp)
    80003630:	1000                	addi	s0,sp,32
    80003632:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003634:	415c                	lw	a5,4(a0)
    80003636:	0047d79b          	srliw	a5,a5,0x4
    8000363a:	0001f597          	auipc	a1,0x1f
    8000363e:	1865a583          	lw	a1,390(a1) # 800227c0 <sb+0x18>
    80003642:	9dbd                	addw	a1,a1,a5
    80003644:	4108                	lw	a0,0(a0)
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	8a8080e7          	jalr	-1880(ra) # 80002eee <bread>
    8000364e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003650:	05850793          	addi	a5,a0,88
    80003654:	40c8                	lw	a0,4(s1)
    80003656:	893d                	andi	a0,a0,15
    80003658:	051a                	slli	a0,a0,0x6
    8000365a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000365c:	04449703          	lh	a4,68(s1)
    80003660:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003664:	04649703          	lh	a4,70(s1)
    80003668:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000366c:	04849703          	lh	a4,72(s1)
    80003670:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003674:	04a49703          	lh	a4,74(s1)
    80003678:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000367c:	44f8                	lw	a4,76(s1)
    8000367e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003680:	03400613          	li	a2,52
    80003684:	05048593          	addi	a1,s1,80
    80003688:	0531                	addi	a0,a0,12
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	6b6080e7          	jalr	1718(ra) # 80000d40 <memmove>
  log_write(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00001097          	auipc	ra,0x1
    80003698:	c06080e7          	jalr	-1018(ra) # 8000429a <log_write>
  brelse(bp);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	980080e7          	jalr	-1664(ra) # 8000301e <brelse>
}
    800036a6:	60e2                	ld	ra,24(sp)
    800036a8:	6442                	ld	s0,16(sp)
    800036aa:	64a2                	ld	s1,8(sp)
    800036ac:	6902                	ld	s2,0(sp)
    800036ae:	6105                	addi	sp,sp,32
    800036b0:	8082                	ret

00000000800036b2 <idup>:
{
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	e426                	sd	s1,8(sp)
    800036ba:	1000                	addi	s0,sp,32
    800036bc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036be:	0001f517          	auipc	a0,0x1f
    800036c2:	10a50513          	addi	a0,a0,266 # 800227c8 <itable>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	51e080e7          	jalr	1310(ra) # 80000be4 <acquire>
  ip->ref++;
    800036ce:	449c                	lw	a5,8(s1)
    800036d0:	2785                	addiw	a5,a5,1
    800036d2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800036d4:	0001f517          	auipc	a0,0x1f
    800036d8:	0f450513          	addi	a0,a0,244 # 800227c8 <itable>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5bc080e7          	jalr	1468(ra) # 80000c98 <release>
}
    800036e4:	8526                	mv	a0,s1
    800036e6:	60e2                	ld	ra,24(sp)
    800036e8:	6442                	ld	s0,16(sp)
    800036ea:	64a2                	ld	s1,8(sp)
    800036ec:	6105                	addi	sp,sp,32
    800036ee:	8082                	ret

00000000800036f0 <ilock>:
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	e426                	sd	s1,8(sp)
    800036f8:	e04a                	sd	s2,0(sp)
    800036fa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036fc:	c115                	beqz	a0,80003720 <ilock+0x30>
    800036fe:	84aa                	mv	s1,a0
    80003700:	451c                	lw	a5,8(a0)
    80003702:	00f05f63          	blez	a5,80003720 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003706:	0541                	addi	a0,a0,16
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	cb2080e7          	jalr	-846(ra) # 800043ba <acquiresleep>
  if(ip->valid == 0){
    80003710:	40bc                	lw	a5,64(s1)
    80003712:	cf99                	beqz	a5,80003730 <ilock+0x40>
}
    80003714:	60e2                	ld	ra,24(sp)
    80003716:	6442                	ld	s0,16(sp)
    80003718:	64a2                	ld	s1,8(sp)
    8000371a:	6902                	ld	s2,0(sp)
    8000371c:	6105                	addi	sp,sp,32
    8000371e:	8082                	ret
    panic("ilock");
    80003720:	00005517          	auipc	a0,0x5
    80003724:	04850513          	addi	a0,a0,72 # 80008768 <syscalls+0x180>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	e16080e7          	jalr	-490(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003730:	40dc                	lw	a5,4(s1)
    80003732:	0047d79b          	srliw	a5,a5,0x4
    80003736:	0001f597          	auipc	a1,0x1f
    8000373a:	08a5a583          	lw	a1,138(a1) # 800227c0 <sb+0x18>
    8000373e:	9dbd                	addw	a1,a1,a5
    80003740:	4088                	lw	a0,0(s1)
    80003742:	fffff097          	auipc	ra,0xfffff
    80003746:	7ac080e7          	jalr	1964(ra) # 80002eee <bread>
    8000374a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000374c:	05850593          	addi	a1,a0,88
    80003750:	40dc                	lw	a5,4(s1)
    80003752:	8bbd                	andi	a5,a5,15
    80003754:	079a                	slli	a5,a5,0x6
    80003756:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003758:	00059783          	lh	a5,0(a1)
    8000375c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003760:	00259783          	lh	a5,2(a1)
    80003764:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003768:	00459783          	lh	a5,4(a1)
    8000376c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003770:	00659783          	lh	a5,6(a1)
    80003774:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003778:	459c                	lw	a5,8(a1)
    8000377a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000377c:	03400613          	li	a2,52
    80003780:	05b1                	addi	a1,a1,12
    80003782:	05048513          	addi	a0,s1,80
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	5ba080e7          	jalr	1466(ra) # 80000d40 <memmove>
    brelse(bp);
    8000378e:	854a                	mv	a0,s2
    80003790:	00000097          	auipc	ra,0x0
    80003794:	88e080e7          	jalr	-1906(ra) # 8000301e <brelse>
    ip->valid = 1;
    80003798:	4785                	li	a5,1
    8000379a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000379c:	04449783          	lh	a5,68(s1)
    800037a0:	fbb5                	bnez	a5,80003714 <ilock+0x24>
      panic("ilock: no type");
    800037a2:	00005517          	auipc	a0,0x5
    800037a6:	fce50513          	addi	a0,a0,-50 # 80008770 <syscalls+0x188>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	d94080e7          	jalr	-620(ra) # 8000053e <panic>

00000000800037b2 <iunlock>:
{
    800037b2:	1101                	addi	sp,sp,-32
    800037b4:	ec06                	sd	ra,24(sp)
    800037b6:	e822                	sd	s0,16(sp)
    800037b8:	e426                	sd	s1,8(sp)
    800037ba:	e04a                	sd	s2,0(sp)
    800037bc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037be:	c905                	beqz	a0,800037ee <iunlock+0x3c>
    800037c0:	84aa                	mv	s1,a0
    800037c2:	01050913          	addi	s2,a0,16
    800037c6:	854a                	mv	a0,s2
    800037c8:	00001097          	auipc	ra,0x1
    800037cc:	c8c080e7          	jalr	-884(ra) # 80004454 <holdingsleep>
    800037d0:	cd19                	beqz	a0,800037ee <iunlock+0x3c>
    800037d2:	449c                	lw	a5,8(s1)
    800037d4:	00f05d63          	blez	a5,800037ee <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037d8:	854a                	mv	a0,s2
    800037da:	00001097          	auipc	ra,0x1
    800037de:	c36080e7          	jalr	-970(ra) # 80004410 <releasesleep>
}
    800037e2:	60e2                	ld	ra,24(sp)
    800037e4:	6442                	ld	s0,16(sp)
    800037e6:	64a2                	ld	s1,8(sp)
    800037e8:	6902                	ld	s2,0(sp)
    800037ea:	6105                	addi	sp,sp,32
    800037ec:	8082                	ret
    panic("iunlock");
    800037ee:	00005517          	auipc	a0,0x5
    800037f2:	f9250513          	addi	a0,a0,-110 # 80008780 <syscalls+0x198>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d48080e7          	jalr	-696(ra) # 8000053e <panic>

00000000800037fe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037fe:	7179                	addi	sp,sp,-48
    80003800:	f406                	sd	ra,40(sp)
    80003802:	f022                	sd	s0,32(sp)
    80003804:	ec26                	sd	s1,24(sp)
    80003806:	e84a                	sd	s2,16(sp)
    80003808:	e44e                	sd	s3,8(sp)
    8000380a:	e052                	sd	s4,0(sp)
    8000380c:	1800                	addi	s0,sp,48
    8000380e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003810:	05050493          	addi	s1,a0,80
    80003814:	08050913          	addi	s2,a0,128
    80003818:	a021                	j	80003820 <itrunc+0x22>
    8000381a:	0491                	addi	s1,s1,4
    8000381c:	01248d63          	beq	s1,s2,80003836 <itrunc+0x38>
    if(ip->addrs[i]){
    80003820:	408c                	lw	a1,0(s1)
    80003822:	dde5                	beqz	a1,8000381a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003824:	0009a503          	lw	a0,0(s3)
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	90c080e7          	jalr	-1780(ra) # 80003134 <bfree>
      ip->addrs[i] = 0;
    80003830:	0004a023          	sw	zero,0(s1)
    80003834:	b7dd                	j	8000381a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003836:	0809a583          	lw	a1,128(s3)
    8000383a:	e185                	bnez	a1,8000385a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000383c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003840:	854e                	mv	a0,s3
    80003842:	00000097          	auipc	ra,0x0
    80003846:	de4080e7          	jalr	-540(ra) # 80003626 <iupdate>
}
    8000384a:	70a2                	ld	ra,40(sp)
    8000384c:	7402                	ld	s0,32(sp)
    8000384e:	64e2                	ld	s1,24(sp)
    80003850:	6942                	ld	s2,16(sp)
    80003852:	69a2                	ld	s3,8(sp)
    80003854:	6a02                	ld	s4,0(sp)
    80003856:	6145                	addi	sp,sp,48
    80003858:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000385a:	0009a503          	lw	a0,0(s3)
    8000385e:	fffff097          	auipc	ra,0xfffff
    80003862:	690080e7          	jalr	1680(ra) # 80002eee <bread>
    80003866:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003868:	05850493          	addi	s1,a0,88
    8000386c:	45850913          	addi	s2,a0,1112
    80003870:	a811                	j	80003884 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003872:	0009a503          	lw	a0,0(s3)
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	8be080e7          	jalr	-1858(ra) # 80003134 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000387e:	0491                	addi	s1,s1,4
    80003880:	01248563          	beq	s1,s2,8000388a <itrunc+0x8c>
      if(a[j])
    80003884:	408c                	lw	a1,0(s1)
    80003886:	dde5                	beqz	a1,8000387e <itrunc+0x80>
    80003888:	b7ed                	j	80003872 <itrunc+0x74>
    brelse(bp);
    8000388a:	8552                	mv	a0,s4
    8000388c:	fffff097          	auipc	ra,0xfffff
    80003890:	792080e7          	jalr	1938(ra) # 8000301e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003894:	0809a583          	lw	a1,128(s3)
    80003898:	0009a503          	lw	a0,0(s3)
    8000389c:	00000097          	auipc	ra,0x0
    800038a0:	898080e7          	jalr	-1896(ra) # 80003134 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038a4:	0809a023          	sw	zero,128(s3)
    800038a8:	bf51                	j	8000383c <itrunc+0x3e>

00000000800038aa <iput>:
{
    800038aa:	1101                	addi	sp,sp,-32
    800038ac:	ec06                	sd	ra,24(sp)
    800038ae:	e822                	sd	s0,16(sp)
    800038b0:	e426                	sd	s1,8(sp)
    800038b2:	e04a                	sd	s2,0(sp)
    800038b4:	1000                	addi	s0,sp,32
    800038b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038b8:	0001f517          	auipc	a0,0x1f
    800038bc:	f1050513          	addi	a0,a0,-240 # 800227c8 <itable>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	324080e7          	jalr	804(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038c8:	4498                	lw	a4,8(s1)
    800038ca:	4785                	li	a5,1
    800038cc:	02f70363          	beq	a4,a5,800038f2 <iput+0x48>
  ip->ref--;
    800038d0:	449c                	lw	a5,8(s1)
    800038d2:	37fd                	addiw	a5,a5,-1
    800038d4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038d6:	0001f517          	auipc	a0,0x1f
    800038da:	ef250513          	addi	a0,a0,-270 # 800227c8 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	3ba080e7          	jalr	954(ra) # 80000c98 <release>
}
    800038e6:	60e2                	ld	ra,24(sp)
    800038e8:	6442                	ld	s0,16(sp)
    800038ea:	64a2                	ld	s1,8(sp)
    800038ec:	6902                	ld	s2,0(sp)
    800038ee:	6105                	addi	sp,sp,32
    800038f0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038f2:	40bc                	lw	a5,64(s1)
    800038f4:	dff1                	beqz	a5,800038d0 <iput+0x26>
    800038f6:	04a49783          	lh	a5,74(s1)
    800038fa:	fbf9                	bnez	a5,800038d0 <iput+0x26>
    acquiresleep(&ip->lock);
    800038fc:	01048913          	addi	s2,s1,16
    80003900:	854a                	mv	a0,s2
    80003902:	00001097          	auipc	ra,0x1
    80003906:	ab8080e7          	jalr	-1352(ra) # 800043ba <acquiresleep>
    release(&itable.lock);
    8000390a:	0001f517          	auipc	a0,0x1f
    8000390e:	ebe50513          	addi	a0,a0,-322 # 800227c8 <itable>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	386080e7          	jalr	902(ra) # 80000c98 <release>
    itrunc(ip);
    8000391a:	8526                	mv	a0,s1
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	ee2080e7          	jalr	-286(ra) # 800037fe <itrunc>
    ip->type = 0;
    80003924:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003928:	8526                	mv	a0,s1
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	cfc080e7          	jalr	-772(ra) # 80003626 <iupdate>
    ip->valid = 0;
    80003932:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003936:	854a                	mv	a0,s2
    80003938:	00001097          	auipc	ra,0x1
    8000393c:	ad8080e7          	jalr	-1320(ra) # 80004410 <releasesleep>
    acquire(&itable.lock);
    80003940:	0001f517          	auipc	a0,0x1f
    80003944:	e8850513          	addi	a0,a0,-376 # 800227c8 <itable>
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
    80003950:	b741                	j	800038d0 <iput+0x26>

0000000080003952 <iunlockput>:
{
    80003952:	1101                	addi	sp,sp,-32
    80003954:	ec06                	sd	ra,24(sp)
    80003956:	e822                	sd	s0,16(sp)
    80003958:	e426                	sd	s1,8(sp)
    8000395a:	1000                	addi	s0,sp,32
    8000395c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000395e:	00000097          	auipc	ra,0x0
    80003962:	e54080e7          	jalr	-428(ra) # 800037b2 <iunlock>
  iput(ip);
    80003966:	8526                	mv	a0,s1
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	f42080e7          	jalr	-190(ra) # 800038aa <iput>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret

000000008000397a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000397a:	1141                	addi	sp,sp,-16
    8000397c:	e422                	sd	s0,8(sp)
    8000397e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003980:	411c                	lw	a5,0(a0)
    80003982:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003984:	415c                	lw	a5,4(a0)
    80003986:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003988:	04451783          	lh	a5,68(a0)
    8000398c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003990:	04a51783          	lh	a5,74(a0)
    80003994:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003998:	04c56783          	lwu	a5,76(a0)
    8000399c:	e99c                	sd	a5,16(a1)
}
    8000399e:	6422                	ld	s0,8(sp)
    800039a0:	0141                	addi	sp,sp,16
    800039a2:	8082                	ret

00000000800039a4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039a4:	457c                	lw	a5,76(a0)
    800039a6:	0ed7e963          	bltu	a5,a3,80003a98 <readi+0xf4>
{
    800039aa:	7159                	addi	sp,sp,-112
    800039ac:	f486                	sd	ra,104(sp)
    800039ae:	f0a2                	sd	s0,96(sp)
    800039b0:	eca6                	sd	s1,88(sp)
    800039b2:	e8ca                	sd	s2,80(sp)
    800039b4:	e4ce                	sd	s3,72(sp)
    800039b6:	e0d2                	sd	s4,64(sp)
    800039b8:	fc56                	sd	s5,56(sp)
    800039ba:	f85a                	sd	s6,48(sp)
    800039bc:	f45e                	sd	s7,40(sp)
    800039be:	f062                	sd	s8,32(sp)
    800039c0:	ec66                	sd	s9,24(sp)
    800039c2:	e86a                	sd	s10,16(sp)
    800039c4:	e46e                	sd	s11,8(sp)
    800039c6:	1880                	addi	s0,sp,112
    800039c8:	8baa                	mv	s7,a0
    800039ca:	8c2e                	mv	s8,a1
    800039cc:	8ab2                	mv	s5,a2
    800039ce:	84b6                	mv	s1,a3
    800039d0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039d2:	9f35                	addw	a4,a4,a3
    return 0;
    800039d4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039d6:	0ad76063          	bltu	a4,a3,80003a76 <readi+0xd2>
  if(off + n > ip->size)
    800039da:	00e7f463          	bgeu	a5,a4,800039e2 <readi+0x3e>
    n = ip->size - off;
    800039de:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039e2:	0a0b0963          	beqz	s6,80003a94 <readi+0xf0>
    800039e6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039ec:	5cfd                	li	s9,-1
    800039ee:	a82d                	j	80003a28 <readi+0x84>
    800039f0:	020a1d93          	slli	s11,s4,0x20
    800039f4:	020ddd93          	srli	s11,s11,0x20
    800039f8:	05890613          	addi	a2,s2,88
    800039fc:	86ee                	mv	a3,s11
    800039fe:	963a                	add	a2,a2,a4
    80003a00:	85d6                	mv	a1,s5
    80003a02:	8562                	mv	a0,s8
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	b2e080e7          	jalr	-1234(ra) # 80002532 <either_copyout>
    80003a0c:	05950d63          	beq	a0,s9,80003a66 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	fffff097          	auipc	ra,0xfffff
    80003a16:	60c080e7          	jalr	1548(ra) # 8000301e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a1a:	013a09bb          	addw	s3,s4,s3
    80003a1e:	009a04bb          	addw	s1,s4,s1
    80003a22:	9aee                	add	s5,s5,s11
    80003a24:	0569f763          	bgeu	s3,s6,80003a72 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a28:	000ba903          	lw	s2,0(s7)
    80003a2c:	00a4d59b          	srliw	a1,s1,0xa
    80003a30:	855e                	mv	a0,s7
    80003a32:	00000097          	auipc	ra,0x0
    80003a36:	8b0080e7          	jalr	-1872(ra) # 800032e2 <bmap>
    80003a3a:	0005059b          	sext.w	a1,a0
    80003a3e:	854a                	mv	a0,s2
    80003a40:	fffff097          	auipc	ra,0xfffff
    80003a44:	4ae080e7          	jalr	1198(ra) # 80002eee <bread>
    80003a48:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4a:	3ff4f713          	andi	a4,s1,1023
    80003a4e:	40ed07bb          	subw	a5,s10,a4
    80003a52:	413b06bb          	subw	a3,s6,s3
    80003a56:	8a3e                	mv	s4,a5
    80003a58:	2781                	sext.w	a5,a5
    80003a5a:	0006861b          	sext.w	a2,a3
    80003a5e:	f8f679e3          	bgeu	a2,a5,800039f0 <readi+0x4c>
    80003a62:	8a36                	mv	s4,a3
    80003a64:	b771                	j	800039f0 <readi+0x4c>
      brelse(bp);
    80003a66:	854a                	mv	a0,s2
    80003a68:	fffff097          	auipc	ra,0xfffff
    80003a6c:	5b6080e7          	jalr	1462(ra) # 8000301e <brelse>
      tot = -1;
    80003a70:	59fd                	li	s3,-1
  }
  return tot;
    80003a72:	0009851b          	sext.w	a0,s3
}
    80003a76:	70a6                	ld	ra,104(sp)
    80003a78:	7406                	ld	s0,96(sp)
    80003a7a:	64e6                	ld	s1,88(sp)
    80003a7c:	6946                	ld	s2,80(sp)
    80003a7e:	69a6                	ld	s3,72(sp)
    80003a80:	6a06                	ld	s4,64(sp)
    80003a82:	7ae2                	ld	s5,56(sp)
    80003a84:	7b42                	ld	s6,48(sp)
    80003a86:	7ba2                	ld	s7,40(sp)
    80003a88:	7c02                	ld	s8,32(sp)
    80003a8a:	6ce2                	ld	s9,24(sp)
    80003a8c:	6d42                	ld	s10,16(sp)
    80003a8e:	6da2                	ld	s11,8(sp)
    80003a90:	6165                	addi	sp,sp,112
    80003a92:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a94:	89da                	mv	s3,s6
    80003a96:	bff1                	j	80003a72 <readi+0xce>
    return 0;
    80003a98:	4501                	li	a0,0
}
    80003a9a:	8082                	ret

0000000080003a9c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a9c:	457c                	lw	a5,76(a0)
    80003a9e:	10d7e863          	bltu	a5,a3,80003bae <writei+0x112>
{
    80003aa2:	7159                	addi	sp,sp,-112
    80003aa4:	f486                	sd	ra,104(sp)
    80003aa6:	f0a2                	sd	s0,96(sp)
    80003aa8:	eca6                	sd	s1,88(sp)
    80003aaa:	e8ca                	sd	s2,80(sp)
    80003aac:	e4ce                	sd	s3,72(sp)
    80003aae:	e0d2                	sd	s4,64(sp)
    80003ab0:	fc56                	sd	s5,56(sp)
    80003ab2:	f85a                	sd	s6,48(sp)
    80003ab4:	f45e                	sd	s7,40(sp)
    80003ab6:	f062                	sd	s8,32(sp)
    80003ab8:	ec66                	sd	s9,24(sp)
    80003aba:	e86a                	sd	s10,16(sp)
    80003abc:	e46e                	sd	s11,8(sp)
    80003abe:	1880                	addi	s0,sp,112
    80003ac0:	8b2a                	mv	s6,a0
    80003ac2:	8c2e                	mv	s8,a1
    80003ac4:	8ab2                	mv	s5,a2
    80003ac6:	8936                	mv	s2,a3
    80003ac8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003aca:	00e687bb          	addw	a5,a3,a4
    80003ace:	0ed7e263          	bltu	a5,a3,80003bb2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ad2:	00043737          	lui	a4,0x43
    80003ad6:	0ef76063          	bltu	a4,a5,80003bb6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ada:	0c0b8863          	beqz	s7,80003baa <writei+0x10e>
    80003ade:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ae4:	5cfd                	li	s9,-1
    80003ae6:	a091                	j	80003b2a <writei+0x8e>
    80003ae8:	02099d93          	slli	s11,s3,0x20
    80003aec:	020ddd93          	srli	s11,s11,0x20
    80003af0:	05848513          	addi	a0,s1,88
    80003af4:	86ee                	mv	a3,s11
    80003af6:	8656                	mv	a2,s5
    80003af8:	85e2                	mv	a1,s8
    80003afa:	953a                	add	a0,a0,a4
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	a8c080e7          	jalr	-1396(ra) # 80002588 <either_copyin>
    80003b04:	07950263          	beq	a0,s9,80003b68 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	790080e7          	jalr	1936(ra) # 8000429a <log_write>
    brelse(bp);
    80003b12:	8526                	mv	a0,s1
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	50a080e7          	jalr	1290(ra) # 8000301e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b1c:	01498a3b          	addw	s4,s3,s4
    80003b20:	0129893b          	addw	s2,s3,s2
    80003b24:	9aee                	add	s5,s5,s11
    80003b26:	057a7663          	bgeu	s4,s7,80003b72 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b2a:	000b2483          	lw	s1,0(s6)
    80003b2e:	00a9559b          	srliw	a1,s2,0xa
    80003b32:	855a                	mv	a0,s6
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	7ae080e7          	jalr	1966(ra) # 800032e2 <bmap>
    80003b3c:	0005059b          	sext.w	a1,a0
    80003b40:	8526                	mv	a0,s1
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	3ac080e7          	jalr	940(ra) # 80002eee <bread>
    80003b4a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4c:	3ff97713          	andi	a4,s2,1023
    80003b50:	40ed07bb          	subw	a5,s10,a4
    80003b54:	414b86bb          	subw	a3,s7,s4
    80003b58:	89be                	mv	s3,a5
    80003b5a:	2781                	sext.w	a5,a5
    80003b5c:	0006861b          	sext.w	a2,a3
    80003b60:	f8f674e3          	bgeu	a2,a5,80003ae8 <writei+0x4c>
    80003b64:	89b6                	mv	s3,a3
    80003b66:	b749                	j	80003ae8 <writei+0x4c>
      brelse(bp);
    80003b68:	8526                	mv	a0,s1
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	4b4080e7          	jalr	1204(ra) # 8000301e <brelse>
  }

  if(off > ip->size)
    80003b72:	04cb2783          	lw	a5,76(s6)
    80003b76:	0127f463          	bgeu	a5,s2,80003b7e <writei+0xe2>
    ip->size = off;
    80003b7a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b7e:	855a                	mv	a0,s6
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	aa6080e7          	jalr	-1370(ra) # 80003626 <iupdate>

  return tot;
    80003b88:	000a051b          	sext.w	a0,s4
}
    80003b8c:	70a6                	ld	ra,104(sp)
    80003b8e:	7406                	ld	s0,96(sp)
    80003b90:	64e6                	ld	s1,88(sp)
    80003b92:	6946                	ld	s2,80(sp)
    80003b94:	69a6                	ld	s3,72(sp)
    80003b96:	6a06                	ld	s4,64(sp)
    80003b98:	7ae2                	ld	s5,56(sp)
    80003b9a:	7b42                	ld	s6,48(sp)
    80003b9c:	7ba2                	ld	s7,40(sp)
    80003b9e:	7c02                	ld	s8,32(sp)
    80003ba0:	6ce2                	ld	s9,24(sp)
    80003ba2:	6d42                	ld	s10,16(sp)
    80003ba4:	6da2                	ld	s11,8(sp)
    80003ba6:	6165                	addi	sp,sp,112
    80003ba8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003baa:	8a5e                	mv	s4,s7
    80003bac:	bfc9                	j	80003b7e <writei+0xe2>
    return -1;
    80003bae:	557d                	li	a0,-1
}
    80003bb0:	8082                	ret
    return -1;
    80003bb2:	557d                	li	a0,-1
    80003bb4:	bfe1                	j	80003b8c <writei+0xf0>
    return -1;
    80003bb6:	557d                	li	a0,-1
    80003bb8:	bfd1                	j	80003b8c <writei+0xf0>

0000000080003bba <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bba:	1141                	addi	sp,sp,-16
    80003bbc:	e406                	sd	ra,8(sp)
    80003bbe:	e022                	sd	s0,0(sp)
    80003bc0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bc2:	4639                	li	a2,14
    80003bc4:	ffffd097          	auipc	ra,0xffffd
    80003bc8:	1f4080e7          	jalr	500(ra) # 80000db8 <strncmp>
}
    80003bcc:	60a2                	ld	ra,8(sp)
    80003bce:	6402                	ld	s0,0(sp)
    80003bd0:	0141                	addi	sp,sp,16
    80003bd2:	8082                	ret

0000000080003bd4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bd4:	7139                	addi	sp,sp,-64
    80003bd6:	fc06                	sd	ra,56(sp)
    80003bd8:	f822                	sd	s0,48(sp)
    80003bda:	f426                	sd	s1,40(sp)
    80003bdc:	f04a                	sd	s2,32(sp)
    80003bde:	ec4e                	sd	s3,24(sp)
    80003be0:	e852                	sd	s4,16(sp)
    80003be2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003be4:	04451703          	lh	a4,68(a0)
    80003be8:	4785                	li	a5,1
    80003bea:	00f71a63          	bne	a4,a5,80003bfe <dirlookup+0x2a>
    80003bee:	892a                	mv	s2,a0
    80003bf0:	89ae                	mv	s3,a1
    80003bf2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf4:	457c                	lw	a5,76(a0)
    80003bf6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bf8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bfa:	e79d                	bnez	a5,80003c28 <dirlookup+0x54>
    80003bfc:	a8a5                	j	80003c74 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bfe:	00005517          	auipc	a0,0x5
    80003c02:	b8a50513          	addi	a0,a0,-1142 # 80008788 <syscalls+0x1a0>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	938080e7          	jalr	-1736(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003c0e:	00005517          	auipc	a0,0x5
    80003c12:	b9250513          	addi	a0,a0,-1134 # 800087a0 <syscalls+0x1b8>
    80003c16:	ffffd097          	auipc	ra,0xffffd
    80003c1a:	928080e7          	jalr	-1752(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c1e:	24c1                	addiw	s1,s1,16
    80003c20:	04c92783          	lw	a5,76(s2)
    80003c24:	04f4f763          	bgeu	s1,a5,80003c72 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c28:	4741                	li	a4,16
    80003c2a:	86a6                	mv	a3,s1
    80003c2c:	fc040613          	addi	a2,s0,-64
    80003c30:	4581                	li	a1,0
    80003c32:	854a                	mv	a0,s2
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	d70080e7          	jalr	-656(ra) # 800039a4 <readi>
    80003c3c:	47c1                	li	a5,16
    80003c3e:	fcf518e3          	bne	a0,a5,80003c0e <dirlookup+0x3a>
    if(de.inum == 0)
    80003c42:	fc045783          	lhu	a5,-64(s0)
    80003c46:	dfe1                	beqz	a5,80003c1e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c48:	fc240593          	addi	a1,s0,-62
    80003c4c:	854e                	mv	a0,s3
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	f6c080e7          	jalr	-148(ra) # 80003bba <namecmp>
    80003c56:	f561                	bnez	a0,80003c1e <dirlookup+0x4a>
      if(poff)
    80003c58:	000a0463          	beqz	s4,80003c60 <dirlookup+0x8c>
        *poff = off;
    80003c5c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c60:	fc045583          	lhu	a1,-64(s0)
    80003c64:	00092503          	lw	a0,0(s2)
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	754080e7          	jalr	1876(ra) # 800033bc <iget>
    80003c70:	a011                	j	80003c74 <dirlookup+0xa0>
  return 0;
    80003c72:	4501                	li	a0,0
}
    80003c74:	70e2                	ld	ra,56(sp)
    80003c76:	7442                	ld	s0,48(sp)
    80003c78:	74a2                	ld	s1,40(sp)
    80003c7a:	7902                	ld	s2,32(sp)
    80003c7c:	69e2                	ld	s3,24(sp)
    80003c7e:	6a42                	ld	s4,16(sp)
    80003c80:	6121                	addi	sp,sp,64
    80003c82:	8082                	ret

0000000080003c84 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c84:	711d                	addi	sp,sp,-96
    80003c86:	ec86                	sd	ra,88(sp)
    80003c88:	e8a2                	sd	s0,80(sp)
    80003c8a:	e4a6                	sd	s1,72(sp)
    80003c8c:	e0ca                	sd	s2,64(sp)
    80003c8e:	fc4e                	sd	s3,56(sp)
    80003c90:	f852                	sd	s4,48(sp)
    80003c92:	f456                	sd	s5,40(sp)
    80003c94:	f05a                	sd	s6,32(sp)
    80003c96:	ec5e                	sd	s7,24(sp)
    80003c98:	e862                	sd	s8,16(sp)
    80003c9a:	e466                	sd	s9,8(sp)
    80003c9c:	1080                	addi	s0,sp,96
    80003c9e:	84aa                	mv	s1,a0
    80003ca0:	8b2e                	mv	s6,a1
    80003ca2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ca4:	00054703          	lbu	a4,0(a0)
    80003ca8:	02f00793          	li	a5,47
    80003cac:	02f70363          	beq	a4,a5,80003cd2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cb0:	ffffe097          	auipc	ra,0xffffe
    80003cb4:	dfe080e7          	jalr	-514(ra) # 80001aae <myproc>
    80003cb8:	15053503          	ld	a0,336(a0)
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	9f6080e7          	jalr	-1546(ra) # 800036b2 <idup>
    80003cc4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cc6:	02f00913          	li	s2,47
  len = path - s;
    80003cca:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ccc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cce:	4c05                	li	s8,1
    80003cd0:	a865                	j	80003d88 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003cd2:	4585                	li	a1,1
    80003cd4:	4505                	li	a0,1
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	6e6080e7          	jalr	1766(ra) # 800033bc <iget>
    80003cde:	89aa                	mv	s3,a0
    80003ce0:	b7dd                	j	80003cc6 <namex+0x42>
      iunlockput(ip);
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	c6e080e7          	jalr	-914(ra) # 80003952 <iunlockput>
      return 0;
    80003cec:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cee:	854e                	mv	a0,s3
    80003cf0:	60e6                	ld	ra,88(sp)
    80003cf2:	6446                	ld	s0,80(sp)
    80003cf4:	64a6                	ld	s1,72(sp)
    80003cf6:	6906                	ld	s2,64(sp)
    80003cf8:	79e2                	ld	s3,56(sp)
    80003cfa:	7a42                	ld	s4,48(sp)
    80003cfc:	7aa2                	ld	s5,40(sp)
    80003cfe:	7b02                	ld	s6,32(sp)
    80003d00:	6be2                	ld	s7,24(sp)
    80003d02:	6c42                	ld	s8,16(sp)
    80003d04:	6ca2                	ld	s9,8(sp)
    80003d06:	6125                	addi	sp,sp,96
    80003d08:	8082                	ret
      iunlock(ip);
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	aa6080e7          	jalr	-1370(ra) # 800037b2 <iunlock>
      return ip;
    80003d14:	bfe9                	j	80003cee <namex+0x6a>
      iunlockput(ip);
    80003d16:	854e                	mv	a0,s3
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	c3a080e7          	jalr	-966(ra) # 80003952 <iunlockput>
      return 0;
    80003d20:	89d2                	mv	s3,s4
    80003d22:	b7f1                	j	80003cee <namex+0x6a>
  len = path - s;
    80003d24:	40b48633          	sub	a2,s1,a1
    80003d28:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d2c:	094cd463          	bge	s9,s4,80003db4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d30:	4639                	li	a2,14
    80003d32:	8556                	mv	a0,s5
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	00c080e7          	jalr	12(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003d3c:	0004c783          	lbu	a5,0(s1)
    80003d40:	01279763          	bne	a5,s2,80003d4e <namex+0xca>
    path++;
    80003d44:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d46:	0004c783          	lbu	a5,0(s1)
    80003d4a:	ff278de3          	beq	a5,s2,80003d44 <namex+0xc0>
    ilock(ip);
    80003d4e:	854e                	mv	a0,s3
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	9a0080e7          	jalr	-1632(ra) # 800036f0 <ilock>
    if(ip->type != T_DIR){
    80003d58:	04499783          	lh	a5,68(s3)
    80003d5c:	f98793e3          	bne	a5,s8,80003ce2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d60:	000b0563          	beqz	s6,80003d6a <namex+0xe6>
    80003d64:	0004c783          	lbu	a5,0(s1)
    80003d68:	d3cd                	beqz	a5,80003d0a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d6a:	865e                	mv	a2,s7
    80003d6c:	85d6                	mv	a1,s5
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	e64080e7          	jalr	-412(ra) # 80003bd4 <dirlookup>
    80003d78:	8a2a                	mv	s4,a0
    80003d7a:	dd51                	beqz	a0,80003d16 <namex+0x92>
    iunlockput(ip);
    80003d7c:	854e                	mv	a0,s3
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	bd4080e7          	jalr	-1068(ra) # 80003952 <iunlockput>
    ip = next;
    80003d86:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d88:	0004c783          	lbu	a5,0(s1)
    80003d8c:	05279763          	bne	a5,s2,80003dda <namex+0x156>
    path++;
    80003d90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d92:	0004c783          	lbu	a5,0(s1)
    80003d96:	ff278de3          	beq	a5,s2,80003d90 <namex+0x10c>
  if(*path == 0)
    80003d9a:	c79d                	beqz	a5,80003dc8 <namex+0x144>
    path++;
    80003d9c:	85a6                	mv	a1,s1
  len = path - s;
    80003d9e:	8a5e                	mv	s4,s7
    80003da0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003da2:	01278963          	beq	a5,s2,80003db4 <namex+0x130>
    80003da6:	dfbd                	beqz	a5,80003d24 <namex+0xa0>
    path++;
    80003da8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003daa:	0004c783          	lbu	a5,0(s1)
    80003dae:	ff279ce3          	bne	a5,s2,80003da6 <namex+0x122>
    80003db2:	bf8d                	j	80003d24 <namex+0xa0>
    memmove(name, s, len);
    80003db4:	2601                	sext.w	a2,a2
    80003db6:	8556                	mv	a0,s5
    80003db8:	ffffd097          	auipc	ra,0xffffd
    80003dbc:	f88080e7          	jalr	-120(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003dc0:	9a56                	add	s4,s4,s5
    80003dc2:	000a0023          	sb	zero,0(s4)
    80003dc6:	bf9d                	j	80003d3c <namex+0xb8>
  if(nameiparent){
    80003dc8:	f20b03e3          	beqz	s6,80003cee <namex+0x6a>
    iput(ip);
    80003dcc:	854e                	mv	a0,s3
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	adc080e7          	jalr	-1316(ra) # 800038aa <iput>
    return 0;
    80003dd6:	4981                	li	s3,0
    80003dd8:	bf19                	j	80003cee <namex+0x6a>
  if(*path == 0)
    80003dda:	d7fd                	beqz	a5,80003dc8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	85a6                	mv	a1,s1
    80003de2:	b7d1                	j	80003da6 <namex+0x122>

0000000080003de4 <dirlink>:
{
    80003de4:	7139                	addi	sp,sp,-64
    80003de6:	fc06                	sd	ra,56(sp)
    80003de8:	f822                	sd	s0,48(sp)
    80003dea:	f426                	sd	s1,40(sp)
    80003dec:	f04a                	sd	s2,32(sp)
    80003dee:	ec4e                	sd	s3,24(sp)
    80003df0:	e852                	sd	s4,16(sp)
    80003df2:	0080                	addi	s0,sp,64
    80003df4:	892a                	mv	s2,a0
    80003df6:	8a2e                	mv	s4,a1
    80003df8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dfa:	4601                	li	a2,0
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	dd8080e7          	jalr	-552(ra) # 80003bd4 <dirlookup>
    80003e04:	e93d                	bnez	a0,80003e7a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e06:	04c92483          	lw	s1,76(s2)
    80003e0a:	c49d                	beqz	s1,80003e38 <dirlink+0x54>
    80003e0c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0e:	4741                	li	a4,16
    80003e10:	86a6                	mv	a3,s1
    80003e12:	fc040613          	addi	a2,s0,-64
    80003e16:	4581                	li	a1,0
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	b8a080e7          	jalr	-1142(ra) # 800039a4 <readi>
    80003e22:	47c1                	li	a5,16
    80003e24:	06f51163          	bne	a0,a5,80003e86 <dirlink+0xa2>
    if(de.inum == 0)
    80003e28:	fc045783          	lhu	a5,-64(s0)
    80003e2c:	c791                	beqz	a5,80003e38 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2e:	24c1                	addiw	s1,s1,16
    80003e30:	04c92783          	lw	a5,76(s2)
    80003e34:	fcf4ede3          	bltu	s1,a5,80003e0e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e38:	4639                	li	a2,14
    80003e3a:	85d2                	mv	a1,s4
    80003e3c:	fc240513          	addi	a0,s0,-62
    80003e40:	ffffd097          	auipc	ra,0xffffd
    80003e44:	fb4080e7          	jalr	-76(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003e48:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e4c:	4741                	li	a4,16
    80003e4e:	86a6                	mv	a3,s1
    80003e50:	fc040613          	addi	a2,s0,-64
    80003e54:	4581                	li	a1,0
    80003e56:	854a                	mv	a0,s2
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	c44080e7          	jalr	-956(ra) # 80003a9c <writei>
    80003e60:	872a                	mv	a4,a0
    80003e62:	47c1                	li	a5,16
  return 0;
    80003e64:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e66:	02f71863          	bne	a4,a5,80003e96 <dirlink+0xb2>
}
    80003e6a:	70e2                	ld	ra,56(sp)
    80003e6c:	7442                	ld	s0,48(sp)
    80003e6e:	74a2                	ld	s1,40(sp)
    80003e70:	7902                	ld	s2,32(sp)
    80003e72:	69e2                	ld	s3,24(sp)
    80003e74:	6a42                	ld	s4,16(sp)
    80003e76:	6121                	addi	sp,sp,64
    80003e78:	8082                	ret
    iput(ip);
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	a30080e7          	jalr	-1488(ra) # 800038aa <iput>
    return -1;
    80003e82:	557d                	li	a0,-1
    80003e84:	b7dd                	j	80003e6a <dirlink+0x86>
      panic("dirlink read");
    80003e86:	00005517          	auipc	a0,0x5
    80003e8a:	92a50513          	addi	a0,a0,-1750 # 800087b0 <syscalls+0x1c8>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6b0080e7          	jalr	1712(ra) # 8000053e <panic>
    panic("dirlink");
    80003e96:	00005517          	auipc	a0,0x5
    80003e9a:	a2a50513          	addi	a0,a0,-1494 # 800088c0 <syscalls+0x2d8>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6a0080e7          	jalr	1696(ra) # 8000053e <panic>

0000000080003ea6 <namei>:

struct inode*
namei(char *path)
{
    80003ea6:	1101                	addi	sp,sp,-32
    80003ea8:	ec06                	sd	ra,24(sp)
    80003eaa:	e822                	sd	s0,16(sp)
    80003eac:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eae:	fe040613          	addi	a2,s0,-32
    80003eb2:	4581                	li	a1,0
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	dd0080e7          	jalr	-560(ra) # 80003c84 <namex>
}
    80003ebc:	60e2                	ld	ra,24(sp)
    80003ebe:	6442                	ld	s0,16(sp)
    80003ec0:	6105                	addi	sp,sp,32
    80003ec2:	8082                	ret

0000000080003ec4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ec4:	1141                	addi	sp,sp,-16
    80003ec6:	e406                	sd	ra,8(sp)
    80003ec8:	e022                	sd	s0,0(sp)
    80003eca:	0800                	addi	s0,sp,16
    80003ecc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ece:	4585                	li	a1,1
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	db4080e7          	jalr	-588(ra) # 80003c84 <namex>
}
    80003ed8:	60a2                	ld	ra,8(sp)
    80003eda:	6402                	ld	s0,0(sp)
    80003edc:	0141                	addi	sp,sp,16
    80003ede:	8082                	ret

0000000080003ee0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ee0:	1101                	addi	sp,sp,-32
    80003ee2:	ec06                	sd	ra,24(sp)
    80003ee4:	e822                	sd	s0,16(sp)
    80003ee6:	e426                	sd	s1,8(sp)
    80003ee8:	e04a                	sd	s2,0(sp)
    80003eea:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003eec:	00020917          	auipc	s2,0x20
    80003ef0:	38490913          	addi	s2,s2,900 # 80024270 <log>
    80003ef4:	01892583          	lw	a1,24(s2)
    80003ef8:	02892503          	lw	a0,40(s2)
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	ff2080e7          	jalr	-14(ra) # 80002eee <bread>
    80003f04:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f06:	02c92683          	lw	a3,44(s2)
    80003f0a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f0c:	02d05763          	blez	a3,80003f3a <write_head+0x5a>
    80003f10:	00020797          	auipc	a5,0x20
    80003f14:	39078793          	addi	a5,a5,912 # 800242a0 <log+0x30>
    80003f18:	05c50713          	addi	a4,a0,92
    80003f1c:	36fd                	addiw	a3,a3,-1
    80003f1e:	1682                	slli	a3,a3,0x20
    80003f20:	9281                	srli	a3,a3,0x20
    80003f22:	068a                	slli	a3,a3,0x2
    80003f24:	00020617          	auipc	a2,0x20
    80003f28:	38060613          	addi	a2,a2,896 # 800242a4 <log+0x34>
    80003f2c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f2e:	4390                	lw	a2,0(a5)
    80003f30:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f32:	0791                	addi	a5,a5,4
    80003f34:	0711                	addi	a4,a4,4
    80003f36:	fed79ce3          	bne	a5,a3,80003f2e <write_head+0x4e>
  }
  bwrite(buf);
    80003f3a:	8526                	mv	a0,s1
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	0a4080e7          	jalr	164(ra) # 80002fe0 <bwrite>
  brelse(buf);
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	0d8080e7          	jalr	216(ra) # 8000301e <brelse>
}
    80003f4e:	60e2                	ld	ra,24(sp)
    80003f50:	6442                	ld	s0,16(sp)
    80003f52:	64a2                	ld	s1,8(sp)
    80003f54:	6902                	ld	s2,0(sp)
    80003f56:	6105                	addi	sp,sp,32
    80003f58:	8082                	ret

0000000080003f5a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f5a:	00020797          	auipc	a5,0x20
    80003f5e:	3427a783          	lw	a5,834(a5) # 8002429c <log+0x2c>
    80003f62:	0af05d63          	blez	a5,8000401c <install_trans+0xc2>
{
    80003f66:	7139                	addi	sp,sp,-64
    80003f68:	fc06                	sd	ra,56(sp)
    80003f6a:	f822                	sd	s0,48(sp)
    80003f6c:	f426                	sd	s1,40(sp)
    80003f6e:	f04a                	sd	s2,32(sp)
    80003f70:	ec4e                	sd	s3,24(sp)
    80003f72:	e852                	sd	s4,16(sp)
    80003f74:	e456                	sd	s5,8(sp)
    80003f76:	e05a                	sd	s6,0(sp)
    80003f78:	0080                	addi	s0,sp,64
    80003f7a:	8b2a                	mv	s6,a0
    80003f7c:	00020a97          	auipc	s5,0x20
    80003f80:	324a8a93          	addi	s5,s5,804 # 800242a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f84:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f86:	00020997          	auipc	s3,0x20
    80003f8a:	2ea98993          	addi	s3,s3,746 # 80024270 <log>
    80003f8e:	a035                	j	80003fba <install_trans+0x60>
      bunpin(dbuf);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	166080e7          	jalr	358(ra) # 800030f8 <bunpin>
    brelse(lbuf);
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	082080e7          	jalr	130(ra) # 8000301e <brelse>
    brelse(dbuf);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	078080e7          	jalr	120(ra) # 8000301e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fae:	2a05                	addiw	s4,s4,1
    80003fb0:	0a91                	addi	s5,s5,4
    80003fb2:	02c9a783          	lw	a5,44(s3)
    80003fb6:	04fa5963          	bge	s4,a5,80004008 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fba:	0189a583          	lw	a1,24(s3)
    80003fbe:	014585bb          	addw	a1,a1,s4
    80003fc2:	2585                	addiw	a1,a1,1
    80003fc4:	0289a503          	lw	a0,40(s3)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	f26080e7          	jalr	-218(ra) # 80002eee <bread>
    80003fd0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fd2:	000aa583          	lw	a1,0(s5)
    80003fd6:	0289a503          	lw	a0,40(s3)
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	f14080e7          	jalr	-236(ra) # 80002eee <bread>
    80003fe2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fe4:	40000613          	li	a2,1024
    80003fe8:	05890593          	addi	a1,s2,88
    80003fec:	05850513          	addi	a0,a0,88
    80003ff0:	ffffd097          	auipc	ra,0xffffd
    80003ff4:	d50080e7          	jalr	-688(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ff8:	8526                	mv	a0,s1
    80003ffa:	fffff097          	auipc	ra,0xfffff
    80003ffe:	fe6080e7          	jalr	-26(ra) # 80002fe0 <bwrite>
    if(recovering == 0)
    80004002:	f80b1ce3          	bnez	s6,80003f9a <install_trans+0x40>
    80004006:	b769                	j	80003f90 <install_trans+0x36>
}
    80004008:	70e2                	ld	ra,56(sp)
    8000400a:	7442                	ld	s0,48(sp)
    8000400c:	74a2                	ld	s1,40(sp)
    8000400e:	7902                	ld	s2,32(sp)
    80004010:	69e2                	ld	s3,24(sp)
    80004012:	6a42                	ld	s4,16(sp)
    80004014:	6aa2                	ld	s5,8(sp)
    80004016:	6b02                	ld	s6,0(sp)
    80004018:	6121                	addi	sp,sp,64
    8000401a:	8082                	ret
    8000401c:	8082                	ret

000000008000401e <initlog>:
{
    8000401e:	7179                	addi	sp,sp,-48
    80004020:	f406                	sd	ra,40(sp)
    80004022:	f022                	sd	s0,32(sp)
    80004024:	ec26                	sd	s1,24(sp)
    80004026:	e84a                	sd	s2,16(sp)
    80004028:	e44e                	sd	s3,8(sp)
    8000402a:	1800                	addi	s0,sp,48
    8000402c:	892a                	mv	s2,a0
    8000402e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004030:	00020497          	auipc	s1,0x20
    80004034:	24048493          	addi	s1,s1,576 # 80024270 <log>
    80004038:	00004597          	auipc	a1,0x4
    8000403c:	78858593          	addi	a1,a1,1928 # 800087c0 <syscalls+0x1d8>
    80004040:	8526                	mv	a0,s1
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	b12080e7          	jalr	-1262(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000404a:	0149a583          	lw	a1,20(s3)
    8000404e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004050:	0109a783          	lw	a5,16(s3)
    80004054:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004056:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000405a:	854a                	mv	a0,s2
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	e92080e7          	jalr	-366(ra) # 80002eee <bread>
  log.lh.n = lh->n;
    80004064:	4d3c                	lw	a5,88(a0)
    80004066:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004068:	02f05563          	blez	a5,80004092 <initlog+0x74>
    8000406c:	05c50713          	addi	a4,a0,92
    80004070:	00020697          	auipc	a3,0x20
    80004074:	23068693          	addi	a3,a3,560 # 800242a0 <log+0x30>
    80004078:	37fd                	addiw	a5,a5,-1
    8000407a:	1782                	slli	a5,a5,0x20
    8000407c:	9381                	srli	a5,a5,0x20
    8000407e:	078a                	slli	a5,a5,0x2
    80004080:	06050613          	addi	a2,a0,96
    80004084:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004086:	4310                	lw	a2,0(a4)
    80004088:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000408a:	0711                	addi	a4,a4,4
    8000408c:	0691                	addi	a3,a3,4
    8000408e:	fef71ce3          	bne	a4,a5,80004086 <initlog+0x68>
  brelse(buf);
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	f8c080e7          	jalr	-116(ra) # 8000301e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000409a:	4505                	li	a0,1
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	ebe080e7          	jalr	-322(ra) # 80003f5a <install_trans>
  log.lh.n = 0;
    800040a4:	00020797          	auipc	a5,0x20
    800040a8:	1e07ac23          	sw	zero,504(a5) # 8002429c <log+0x2c>
  write_head(); // clear the log
    800040ac:	00000097          	auipc	ra,0x0
    800040b0:	e34080e7          	jalr	-460(ra) # 80003ee0 <write_head>
}
    800040b4:	70a2                	ld	ra,40(sp)
    800040b6:	7402                	ld	s0,32(sp)
    800040b8:	64e2                	ld	s1,24(sp)
    800040ba:	6942                	ld	s2,16(sp)
    800040bc:	69a2                	ld	s3,8(sp)
    800040be:	6145                	addi	sp,sp,48
    800040c0:	8082                	ret

00000000800040c2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040c2:	1101                	addi	sp,sp,-32
    800040c4:	ec06                	sd	ra,24(sp)
    800040c6:	e822                	sd	s0,16(sp)
    800040c8:	e426                	sd	s1,8(sp)
    800040ca:	e04a                	sd	s2,0(sp)
    800040cc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040ce:	00020517          	auipc	a0,0x20
    800040d2:	1a250513          	addi	a0,a0,418 # 80024270 <log>
    800040d6:	ffffd097          	auipc	ra,0xffffd
    800040da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800040de:	00020497          	auipc	s1,0x20
    800040e2:	19248493          	addi	s1,s1,402 # 80024270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040e6:	4979                	li	s2,30
    800040e8:	a039                	j	800040f6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040ea:	85a6                	mv	a1,s1
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffe097          	auipc	ra,0xffffe
    800040f2:	08c080e7          	jalr	140(ra) # 8000217a <sleep>
    if(log.committing){
    800040f6:	50dc                	lw	a5,36(s1)
    800040f8:	fbed                	bnez	a5,800040ea <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040fa:	509c                	lw	a5,32(s1)
    800040fc:	0017871b          	addiw	a4,a5,1
    80004100:	0007069b          	sext.w	a3,a4
    80004104:	0027179b          	slliw	a5,a4,0x2
    80004108:	9fb9                	addw	a5,a5,a4
    8000410a:	0017979b          	slliw	a5,a5,0x1
    8000410e:	54d8                	lw	a4,44(s1)
    80004110:	9fb9                	addw	a5,a5,a4
    80004112:	00f95963          	bge	s2,a5,80004124 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004116:	85a6                	mv	a1,s1
    80004118:	8526                	mv	a0,s1
    8000411a:	ffffe097          	auipc	ra,0xffffe
    8000411e:	060080e7          	jalr	96(ra) # 8000217a <sleep>
    80004122:	bfd1                	j	800040f6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004124:	00020517          	auipc	a0,0x20
    80004128:	14c50513          	addi	a0,a0,332 # 80024270 <log>
    8000412c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	b6a080e7          	jalr	-1174(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	64a2                	ld	s1,8(sp)
    8000413c:	6902                	ld	s2,0(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004142:	7139                	addi	sp,sp,-64
    80004144:	fc06                	sd	ra,56(sp)
    80004146:	f822                	sd	s0,48(sp)
    80004148:	f426                	sd	s1,40(sp)
    8000414a:	f04a                	sd	s2,32(sp)
    8000414c:	ec4e                	sd	s3,24(sp)
    8000414e:	e852                	sd	s4,16(sp)
    80004150:	e456                	sd	s5,8(sp)
    80004152:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004154:	00020497          	auipc	s1,0x20
    80004158:	11c48493          	addi	s1,s1,284 # 80024270 <log>
    8000415c:	8526                	mv	a0,s1
    8000415e:	ffffd097          	auipc	ra,0xffffd
    80004162:	a86080e7          	jalr	-1402(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004166:	509c                	lw	a5,32(s1)
    80004168:	37fd                	addiw	a5,a5,-1
    8000416a:	0007891b          	sext.w	s2,a5
    8000416e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004170:	50dc                	lw	a5,36(s1)
    80004172:	efb9                	bnez	a5,800041d0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004174:	06091663          	bnez	s2,800041e0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004178:	00020497          	auipc	s1,0x20
    8000417c:	0f848493          	addi	s1,s1,248 # 80024270 <log>
    80004180:	4785                	li	a5,1
    80004182:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004184:	8526                	mv	a0,s1
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	b12080e7          	jalr	-1262(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000418e:	54dc                	lw	a5,44(s1)
    80004190:	06f04763          	bgtz	a5,800041fe <end_op+0xbc>
    acquire(&log.lock);
    80004194:	00020497          	auipc	s1,0x20
    80004198:	0dc48493          	addi	s1,s1,220 # 80024270 <log>
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
    log.committing = 0;
    800041a6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041aa:	8526                	mv	a0,s1
    800041ac:	ffffe097          	auipc	ra,0xffffe
    800041b0:	16e080e7          	jalr	366(ra) # 8000231a <wakeup>
    release(&log.lock);
    800041b4:	8526                	mv	a0,s1
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
}
    800041be:	70e2                	ld	ra,56(sp)
    800041c0:	7442                	ld	s0,48(sp)
    800041c2:	74a2                	ld	s1,40(sp)
    800041c4:	7902                	ld	s2,32(sp)
    800041c6:	69e2                	ld	s3,24(sp)
    800041c8:	6a42                	ld	s4,16(sp)
    800041ca:	6aa2                	ld	s5,8(sp)
    800041cc:	6121                	addi	sp,sp,64
    800041ce:	8082                	ret
    panic("log.committing");
    800041d0:	00004517          	auipc	a0,0x4
    800041d4:	5f850513          	addi	a0,a0,1528 # 800087c8 <syscalls+0x1e0>
    800041d8:	ffffc097          	auipc	ra,0xffffc
    800041dc:	366080e7          	jalr	870(ra) # 8000053e <panic>
    wakeup(&log);
    800041e0:	00020497          	auipc	s1,0x20
    800041e4:	09048493          	addi	s1,s1,144 # 80024270 <log>
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffe097          	auipc	ra,0xffffe
    800041ee:	130080e7          	jalr	304(ra) # 8000231a <wakeup>
  release(&log.lock);
    800041f2:	8526                	mv	a0,s1
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
  if(do_commit){
    800041fc:	b7c9                	j	800041be <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fe:	00020a97          	auipc	s5,0x20
    80004202:	0a2a8a93          	addi	s5,s5,162 # 800242a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004206:	00020a17          	auipc	s4,0x20
    8000420a:	06aa0a13          	addi	s4,s4,106 # 80024270 <log>
    8000420e:	018a2583          	lw	a1,24(s4)
    80004212:	012585bb          	addw	a1,a1,s2
    80004216:	2585                	addiw	a1,a1,1
    80004218:	028a2503          	lw	a0,40(s4)
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	cd2080e7          	jalr	-814(ra) # 80002eee <bread>
    80004224:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004226:	000aa583          	lw	a1,0(s5)
    8000422a:	028a2503          	lw	a0,40(s4)
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	cc0080e7          	jalr	-832(ra) # 80002eee <bread>
    80004236:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004238:	40000613          	li	a2,1024
    8000423c:	05850593          	addi	a1,a0,88
    80004240:	05848513          	addi	a0,s1,88
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	afc080e7          	jalr	-1284(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	d92080e7          	jalr	-622(ra) # 80002fe0 <bwrite>
    brelse(from);
    80004256:	854e                	mv	a0,s3
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	dc6080e7          	jalr	-570(ra) # 8000301e <brelse>
    brelse(to);
    80004260:	8526                	mv	a0,s1
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	dbc080e7          	jalr	-580(ra) # 8000301e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426a:	2905                	addiw	s2,s2,1
    8000426c:	0a91                	addi	s5,s5,4
    8000426e:	02ca2783          	lw	a5,44(s4)
    80004272:	f8f94ee3          	blt	s2,a5,8000420e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	c6a080e7          	jalr	-918(ra) # 80003ee0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000427e:	4501                	li	a0,0
    80004280:	00000097          	auipc	ra,0x0
    80004284:	cda080e7          	jalr	-806(ra) # 80003f5a <install_trans>
    log.lh.n = 0;
    80004288:	00020797          	auipc	a5,0x20
    8000428c:	0007aa23          	sw	zero,20(a5) # 8002429c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004290:	00000097          	auipc	ra,0x0
    80004294:	c50080e7          	jalr	-944(ra) # 80003ee0 <write_head>
    80004298:	bdf5                	j	80004194 <end_op+0x52>

000000008000429a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000429a:	1101                	addi	sp,sp,-32
    8000429c:	ec06                	sd	ra,24(sp)
    8000429e:	e822                	sd	s0,16(sp)
    800042a0:	e426                	sd	s1,8(sp)
    800042a2:	e04a                	sd	s2,0(sp)
    800042a4:	1000                	addi	s0,sp,32
    800042a6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042a8:	00020917          	auipc	s2,0x20
    800042ac:	fc890913          	addi	s2,s2,-56 # 80024270 <log>
    800042b0:	854a                	mv	a0,s2
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	932080e7          	jalr	-1742(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042ba:	02c92603          	lw	a2,44(s2)
    800042be:	47f5                	li	a5,29
    800042c0:	06c7c563          	blt	a5,a2,8000432a <log_write+0x90>
    800042c4:	00020797          	auipc	a5,0x20
    800042c8:	fc87a783          	lw	a5,-56(a5) # 8002428c <log+0x1c>
    800042cc:	37fd                	addiw	a5,a5,-1
    800042ce:	04f65e63          	bge	a2,a5,8000432a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042d2:	00020797          	auipc	a5,0x20
    800042d6:	fbe7a783          	lw	a5,-66(a5) # 80024290 <log+0x20>
    800042da:	06f05063          	blez	a5,8000433a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042de:	4781                	li	a5,0
    800042e0:	06c05563          	blez	a2,8000434a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042e4:	44cc                	lw	a1,12(s1)
    800042e6:	00020717          	auipc	a4,0x20
    800042ea:	fba70713          	addi	a4,a4,-70 # 800242a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042ee:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f0:	4314                	lw	a3,0(a4)
    800042f2:	04b68c63          	beq	a3,a1,8000434a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042f6:	2785                	addiw	a5,a5,1
    800042f8:	0711                	addi	a4,a4,4
    800042fa:	fef61be3          	bne	a2,a5,800042f0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042fe:	0621                	addi	a2,a2,8
    80004300:	060a                	slli	a2,a2,0x2
    80004302:	00020797          	auipc	a5,0x20
    80004306:	f6e78793          	addi	a5,a5,-146 # 80024270 <log>
    8000430a:	963e                	add	a2,a2,a5
    8000430c:	44dc                	lw	a5,12(s1)
    8000430e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004310:	8526                	mv	a0,s1
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	daa080e7          	jalr	-598(ra) # 800030bc <bpin>
    log.lh.n++;
    8000431a:	00020717          	auipc	a4,0x20
    8000431e:	f5670713          	addi	a4,a4,-170 # 80024270 <log>
    80004322:	575c                	lw	a5,44(a4)
    80004324:	2785                	addiw	a5,a5,1
    80004326:	d75c                	sw	a5,44(a4)
    80004328:	a835                	j	80004364 <log_write+0xca>
    panic("too big a transaction");
    8000432a:	00004517          	auipc	a0,0x4
    8000432e:	4ae50513          	addi	a0,a0,1198 # 800087d8 <syscalls+0x1f0>
    80004332:	ffffc097          	auipc	ra,0xffffc
    80004336:	20c080e7          	jalr	524(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000433a:	00004517          	auipc	a0,0x4
    8000433e:	4b650513          	addi	a0,a0,1206 # 800087f0 <syscalls+0x208>
    80004342:	ffffc097          	auipc	ra,0xffffc
    80004346:	1fc080e7          	jalr	508(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000434a:	00878713          	addi	a4,a5,8
    8000434e:	00271693          	slli	a3,a4,0x2
    80004352:	00020717          	auipc	a4,0x20
    80004356:	f1e70713          	addi	a4,a4,-226 # 80024270 <log>
    8000435a:	9736                	add	a4,a4,a3
    8000435c:	44d4                	lw	a3,12(s1)
    8000435e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004360:	faf608e3          	beq	a2,a5,80004310 <log_write+0x76>
  }
  release(&log.lock);
    80004364:	00020517          	auipc	a0,0x20
    80004368:	f0c50513          	addi	a0,a0,-244 # 80024270 <log>
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	92c080e7          	jalr	-1748(ra) # 80000c98 <release>
}
    80004374:	60e2                	ld	ra,24(sp)
    80004376:	6442                	ld	s0,16(sp)
    80004378:	64a2                	ld	s1,8(sp)
    8000437a:	6902                	ld	s2,0(sp)
    8000437c:	6105                	addi	sp,sp,32
    8000437e:	8082                	ret

0000000080004380 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
    8000438c:	84aa                	mv	s1,a0
    8000438e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004390:	00004597          	auipc	a1,0x4
    80004394:	48058593          	addi	a1,a1,1152 # 80008810 <syscalls+0x228>
    80004398:	0521                	addi	a0,a0,8
    8000439a:	ffffc097          	auipc	ra,0xffffc
    8000439e:	7ba080e7          	jalr	1978(ra) # 80000b54 <initlock>
  lk->name = name;
    800043a2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043aa:	0204a423          	sw	zero,40(s1)
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043c8:	00850913          	addi	s2,a0,8
    800043cc:	854a                	mv	a0,s2
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	816080e7          	jalr	-2026(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800043d6:	409c                	lw	a5,0(s1)
    800043d8:	cb89                	beqz	a5,800043ea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043da:	85ca                	mv	a1,s2
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffe097          	auipc	ra,0xffffe
    800043e2:	d9c080e7          	jalr	-612(ra) # 8000217a <sleep>
  while (lk->locked) {
    800043e6:	409c                	lw	a5,0(s1)
    800043e8:	fbed                	bnez	a5,800043da <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043ea:	4785                	li	a5,1
    800043ec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	6c0080e7          	jalr	1728(ra) # 80001aae <myproc>
    800043f6:	591c                	lw	a5,48(a0)
    800043f8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043fa:	854a                	mv	a0,s2
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	89c080e7          	jalr	-1892(ra) # 80000c98 <release>
}
    80004404:	60e2                	ld	ra,24(sp)
    80004406:	6442                	ld	s0,16(sp)
    80004408:	64a2                	ld	s1,8(sp)
    8000440a:	6902                	ld	s2,0(sp)
    8000440c:	6105                	addi	sp,sp,32
    8000440e:	8082                	ret

0000000080004410 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004410:	1101                	addi	sp,sp,-32
    80004412:	ec06                	sd	ra,24(sp)
    80004414:	e822                	sd	s0,16(sp)
    80004416:	e426                	sd	s1,8(sp)
    80004418:	e04a                	sd	s2,0(sp)
    8000441a:	1000                	addi	s0,sp,32
    8000441c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000441e:	00850913          	addi	s2,a0,8
    80004422:	854a                	mv	a0,s2
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7c0080e7          	jalr	1984(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000442c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004430:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffe097          	auipc	ra,0xffffe
    8000443a:	ee4080e7          	jalr	-284(ra) # 8000231a <wakeup>
  release(&lk->lk);
    8000443e:	854a                	mv	a0,s2
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004454:	7179                	addi	sp,sp,-48
    80004456:	f406                	sd	ra,40(sp)
    80004458:	f022                	sd	s0,32(sp)
    8000445a:	ec26                	sd	s1,24(sp)
    8000445c:	e84a                	sd	s2,16(sp)
    8000445e:	e44e                	sd	s3,8(sp)
    80004460:	1800                	addi	s0,sp,48
    80004462:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004464:	00850913          	addi	s2,a0,8
    80004468:	854a                	mv	a0,s2
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	77a080e7          	jalr	1914(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004472:	409c                	lw	a5,0(s1)
    80004474:	ef99                	bnez	a5,80004492 <holdingsleep+0x3e>
    80004476:	4481                	li	s1,0
  release(&lk->lk);
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	81e080e7          	jalr	-2018(ra) # 80000c98 <release>
  return r;
}
    80004482:	8526                	mv	a0,s1
    80004484:	70a2                	ld	ra,40(sp)
    80004486:	7402                	ld	s0,32(sp)
    80004488:	64e2                	ld	s1,24(sp)
    8000448a:	6942                	ld	s2,16(sp)
    8000448c:	69a2                	ld	s3,8(sp)
    8000448e:	6145                	addi	sp,sp,48
    80004490:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004492:	0284a983          	lw	s3,40(s1)
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	618080e7          	jalr	1560(ra) # 80001aae <myproc>
    8000449e:	5904                	lw	s1,48(a0)
    800044a0:	413484b3          	sub	s1,s1,s3
    800044a4:	0014b493          	seqz	s1,s1
    800044a8:	bfc1                	j	80004478 <holdingsleep+0x24>

00000000800044aa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044aa:	1141                	addi	sp,sp,-16
    800044ac:	e406                	sd	ra,8(sp)
    800044ae:	e022                	sd	s0,0(sp)
    800044b0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044b2:	00004597          	auipc	a1,0x4
    800044b6:	36e58593          	addi	a1,a1,878 # 80008820 <syscalls+0x238>
    800044ba:	00020517          	auipc	a0,0x20
    800044be:	efe50513          	addi	a0,a0,-258 # 800243b8 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	692080e7          	jalr	1682(ra) # 80000b54 <initlock>
}
    800044ca:	60a2                	ld	ra,8(sp)
    800044cc:	6402                	ld	s0,0(sp)
    800044ce:	0141                	addi	sp,sp,16
    800044d0:	8082                	ret

00000000800044d2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044dc:	00020517          	auipc	a0,0x20
    800044e0:	edc50513          	addi	a0,a0,-292 # 800243b8 <ftable>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	700080e7          	jalr	1792(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ec:	00020497          	auipc	s1,0x20
    800044f0:	ee448493          	addi	s1,s1,-284 # 800243d0 <ftable+0x18>
    800044f4:	00021717          	auipc	a4,0x21
    800044f8:	e7c70713          	addi	a4,a4,-388 # 80025370 <ftable+0xfb8>
    if(f->ref == 0){
    800044fc:	40dc                	lw	a5,4(s1)
    800044fe:	cf99                	beqz	a5,8000451c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004500:	02848493          	addi	s1,s1,40
    80004504:	fee49ce3          	bne	s1,a4,800044fc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004508:	00020517          	auipc	a0,0x20
    8000450c:	eb050513          	addi	a0,a0,-336 # 800243b8 <ftable>
    80004510:	ffffc097          	auipc	ra,0xffffc
    80004514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
  return 0;
    80004518:	4481                	li	s1,0
    8000451a:	a819                	j	80004530 <filealloc+0x5e>
      f->ref = 1;
    8000451c:	4785                	li	a5,1
    8000451e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004520:	00020517          	auipc	a0,0x20
    80004524:	e9850513          	addi	a0,a0,-360 # 800243b8 <ftable>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	770080e7          	jalr	1904(ra) # 80000c98 <release>
}
    80004530:	8526                	mv	a0,s1
    80004532:	60e2                	ld	ra,24(sp)
    80004534:	6442                	ld	s0,16(sp)
    80004536:	64a2                	ld	s1,8(sp)
    80004538:	6105                	addi	sp,sp,32
    8000453a:	8082                	ret

000000008000453c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000453c:	1101                	addi	sp,sp,-32
    8000453e:	ec06                	sd	ra,24(sp)
    80004540:	e822                	sd	s0,16(sp)
    80004542:	e426                	sd	s1,8(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004548:	00020517          	auipc	a0,0x20
    8000454c:	e7050513          	addi	a0,a0,-400 # 800243b8 <ftable>
    80004550:	ffffc097          	auipc	ra,0xffffc
    80004554:	694080e7          	jalr	1684(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004558:	40dc                	lw	a5,4(s1)
    8000455a:	02f05263          	blez	a5,8000457e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000455e:	2785                	addiw	a5,a5,1
    80004560:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004562:	00020517          	auipc	a0,0x20
    80004566:	e5650513          	addi	a0,a0,-426 # 800243b8 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
  return f;
}
    80004572:	8526                	mv	a0,s1
    80004574:	60e2                	ld	ra,24(sp)
    80004576:	6442                	ld	s0,16(sp)
    80004578:	64a2                	ld	s1,8(sp)
    8000457a:	6105                	addi	sp,sp,32
    8000457c:	8082                	ret
    panic("filedup");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	2aa50513          	addi	a0,a0,682 # 80008828 <syscalls+0x240>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fb8080e7          	jalr	-72(ra) # 8000053e <panic>

000000008000458e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000458e:	7139                	addi	sp,sp,-64
    80004590:	fc06                	sd	ra,56(sp)
    80004592:	f822                	sd	s0,48(sp)
    80004594:	f426                	sd	s1,40(sp)
    80004596:	f04a                	sd	s2,32(sp)
    80004598:	ec4e                	sd	s3,24(sp)
    8000459a:	e852                	sd	s4,16(sp)
    8000459c:	e456                	sd	s5,8(sp)
    8000459e:	0080                	addi	s0,sp,64
    800045a0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045a2:	00020517          	auipc	a0,0x20
    800045a6:	e1650513          	addi	a0,a0,-490 # 800243b8 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	63a080e7          	jalr	1594(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045b2:	40dc                	lw	a5,4(s1)
    800045b4:	06f05163          	blez	a5,80004616 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045b8:	37fd                	addiw	a5,a5,-1
    800045ba:	0007871b          	sext.w	a4,a5
    800045be:	c0dc                	sw	a5,4(s1)
    800045c0:	06e04363          	bgtz	a4,80004626 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045c4:	0004a903          	lw	s2,0(s1)
    800045c8:	0094ca83          	lbu	s5,9(s1)
    800045cc:	0104ba03          	ld	s4,16(s1)
    800045d0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045d4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045d8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045dc:	00020517          	auipc	a0,0x20
    800045e0:	ddc50513          	addi	a0,a0,-548 # 800243b8 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6b4080e7          	jalr	1716(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800045ec:	4785                	li	a5,1
    800045ee:	04f90d63          	beq	s2,a5,80004648 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045f2:	3979                	addiw	s2,s2,-2
    800045f4:	4785                	li	a5,1
    800045f6:	0527e063          	bltu	a5,s2,80004636 <fileclose+0xa8>
    begin_op();
    800045fa:	00000097          	auipc	ra,0x0
    800045fe:	ac8080e7          	jalr	-1336(ra) # 800040c2 <begin_op>
    iput(ff.ip);
    80004602:	854e                	mv	a0,s3
    80004604:	fffff097          	auipc	ra,0xfffff
    80004608:	2a6080e7          	jalr	678(ra) # 800038aa <iput>
    end_op();
    8000460c:	00000097          	auipc	ra,0x0
    80004610:	b36080e7          	jalr	-1226(ra) # 80004142 <end_op>
    80004614:	a00d                	j	80004636 <fileclose+0xa8>
    panic("fileclose");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	21a50513          	addi	a0,a0,538 # 80008830 <syscalls+0x248>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f20080e7          	jalr	-224(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004626:	00020517          	auipc	a0,0x20
    8000462a:	d9250513          	addi	a0,a0,-622 # 800243b8 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	66a080e7          	jalr	1642(ra) # 80000c98 <release>
  }
}
    80004636:	70e2                	ld	ra,56(sp)
    80004638:	7442                	ld	s0,48(sp)
    8000463a:	74a2                	ld	s1,40(sp)
    8000463c:	7902                	ld	s2,32(sp)
    8000463e:	69e2                	ld	s3,24(sp)
    80004640:	6a42                	ld	s4,16(sp)
    80004642:	6aa2                	ld	s5,8(sp)
    80004644:	6121                	addi	sp,sp,64
    80004646:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004648:	85d6                	mv	a1,s5
    8000464a:	8552                	mv	a0,s4
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	34c080e7          	jalr	844(ra) # 80004998 <pipeclose>
    80004654:	b7cd                	j	80004636 <fileclose+0xa8>

0000000080004656 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004656:	715d                	addi	sp,sp,-80
    80004658:	e486                	sd	ra,72(sp)
    8000465a:	e0a2                	sd	s0,64(sp)
    8000465c:	fc26                	sd	s1,56(sp)
    8000465e:	f84a                	sd	s2,48(sp)
    80004660:	f44e                	sd	s3,40(sp)
    80004662:	0880                	addi	s0,sp,80
    80004664:	84aa                	mv	s1,a0
    80004666:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	446080e7          	jalr	1094(ra) # 80001aae <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004670:	409c                	lw	a5,0(s1)
    80004672:	37f9                	addiw	a5,a5,-2
    80004674:	4705                	li	a4,1
    80004676:	04f76763          	bltu	a4,a5,800046c4 <filestat+0x6e>
    8000467a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	072080e7          	jalr	114(ra) # 800036f0 <ilock>
    stati(f->ip, &st);
    80004686:	fb840593          	addi	a1,s0,-72
    8000468a:	6c88                	ld	a0,24(s1)
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	2ee080e7          	jalr	750(ra) # 8000397a <stati>
    iunlock(f->ip);
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	11c080e7          	jalr	284(ra) # 800037b2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000469e:	46e1                	li	a3,24
    800046a0:	fb840613          	addi	a2,s0,-72
    800046a4:	85ce                	mv	a1,s3
    800046a6:	05093503          	ld	a0,80(s2)
    800046aa:	ffffd097          	auipc	ra,0xffffd
    800046ae:	0c6080e7          	jalr	198(ra) # 80001770 <copyout>
    800046b2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046b6:	60a6                	ld	ra,72(sp)
    800046b8:	6406                	ld	s0,64(sp)
    800046ba:	74e2                	ld	s1,56(sp)
    800046bc:	7942                	ld	s2,48(sp)
    800046be:	79a2                	ld	s3,40(sp)
    800046c0:	6161                	addi	sp,sp,80
    800046c2:	8082                	ret
  return -1;
    800046c4:	557d                	li	a0,-1
    800046c6:	bfc5                	j	800046b6 <filestat+0x60>

00000000800046c8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046c8:	7179                	addi	sp,sp,-48
    800046ca:	f406                	sd	ra,40(sp)
    800046cc:	f022                	sd	s0,32(sp)
    800046ce:	ec26                	sd	s1,24(sp)
    800046d0:	e84a                	sd	s2,16(sp)
    800046d2:	e44e                	sd	s3,8(sp)
    800046d4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046d6:	00854783          	lbu	a5,8(a0)
    800046da:	c3d5                	beqz	a5,8000477e <fileread+0xb6>
    800046dc:	84aa                	mv	s1,a0
    800046de:	89ae                	mv	s3,a1
    800046e0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046e2:	411c                	lw	a5,0(a0)
    800046e4:	4705                	li	a4,1
    800046e6:	04e78963          	beq	a5,a4,80004738 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046ea:	470d                	li	a4,3
    800046ec:	04e78d63          	beq	a5,a4,80004746 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046f0:	4709                	li	a4,2
    800046f2:	06e79e63          	bne	a5,a4,8000476e <fileread+0xa6>
    ilock(f->ip);
    800046f6:	6d08                	ld	a0,24(a0)
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	ff8080e7          	jalr	-8(ra) # 800036f0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004700:	874a                	mv	a4,s2
    80004702:	5094                	lw	a3,32(s1)
    80004704:	864e                	mv	a2,s3
    80004706:	4585                	li	a1,1
    80004708:	6c88                	ld	a0,24(s1)
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	29a080e7          	jalr	666(ra) # 800039a4 <readi>
    80004712:	892a                	mv	s2,a0
    80004714:	00a05563          	blez	a0,8000471e <fileread+0x56>
      f->off += r;
    80004718:	509c                	lw	a5,32(s1)
    8000471a:	9fa9                	addw	a5,a5,a0
    8000471c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000471e:	6c88                	ld	a0,24(s1)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	092080e7          	jalr	146(ra) # 800037b2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004728:	854a                	mv	a0,s2
    8000472a:	70a2                	ld	ra,40(sp)
    8000472c:	7402                	ld	s0,32(sp)
    8000472e:	64e2                	ld	s1,24(sp)
    80004730:	6942                	ld	s2,16(sp)
    80004732:	69a2                	ld	s3,8(sp)
    80004734:	6145                	addi	sp,sp,48
    80004736:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004738:	6908                	ld	a0,16(a0)
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	3c8080e7          	jalr	968(ra) # 80004b02 <piperead>
    80004742:	892a                	mv	s2,a0
    80004744:	b7d5                	j	80004728 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004746:	02451783          	lh	a5,36(a0)
    8000474a:	03079693          	slli	a3,a5,0x30
    8000474e:	92c1                	srli	a3,a3,0x30
    80004750:	4725                	li	a4,9
    80004752:	02d76863          	bltu	a4,a3,80004782 <fileread+0xba>
    80004756:	0792                	slli	a5,a5,0x4
    80004758:	00020717          	auipc	a4,0x20
    8000475c:	bc070713          	addi	a4,a4,-1088 # 80024318 <devsw>
    80004760:	97ba                	add	a5,a5,a4
    80004762:	639c                	ld	a5,0(a5)
    80004764:	c38d                	beqz	a5,80004786 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004766:	4505                	li	a0,1
    80004768:	9782                	jalr	a5
    8000476a:	892a                	mv	s2,a0
    8000476c:	bf75                	j	80004728 <fileread+0x60>
    panic("fileread");
    8000476e:	00004517          	auipc	a0,0x4
    80004772:	0d250513          	addi	a0,a0,210 # 80008840 <syscalls+0x258>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	dc8080e7          	jalr	-568(ra) # 8000053e <panic>
    return -1;
    8000477e:	597d                	li	s2,-1
    80004780:	b765                	j	80004728 <fileread+0x60>
      return -1;
    80004782:	597d                	li	s2,-1
    80004784:	b755                	j	80004728 <fileread+0x60>
    80004786:	597d                	li	s2,-1
    80004788:	b745                	j	80004728 <fileread+0x60>

000000008000478a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000478a:	715d                	addi	sp,sp,-80
    8000478c:	e486                	sd	ra,72(sp)
    8000478e:	e0a2                	sd	s0,64(sp)
    80004790:	fc26                	sd	s1,56(sp)
    80004792:	f84a                	sd	s2,48(sp)
    80004794:	f44e                	sd	s3,40(sp)
    80004796:	f052                	sd	s4,32(sp)
    80004798:	ec56                	sd	s5,24(sp)
    8000479a:	e85a                	sd	s6,16(sp)
    8000479c:	e45e                	sd	s7,8(sp)
    8000479e:	e062                	sd	s8,0(sp)
    800047a0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800047a2:	00954783          	lbu	a5,9(a0)
    800047a6:	10078663          	beqz	a5,800048b2 <filewrite+0x128>
    800047aa:	892a                	mv	s2,a0
    800047ac:	8aae                	mv	s5,a1
    800047ae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	02e78263          	beq	a5,a4,800047d8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	02e78663          	beq	a5,a4,800047e6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	0ee79163          	bne	a5,a4,800048a2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047c4:	0ac05d63          	blez	a2,8000487e <filewrite+0xf4>
    int i = 0;
    800047c8:	4981                	li	s3,0
    800047ca:	6b05                	lui	s6,0x1
    800047cc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047d0:	6b85                	lui	s7,0x1
    800047d2:	c00b8b9b          	addiw	s7,s7,-1024
    800047d6:	a861                	j	8000486e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800047d8:	6908                	ld	a0,16(a0)
    800047da:	00000097          	auipc	ra,0x0
    800047de:	22e080e7          	jalr	558(ra) # 80004a08 <pipewrite>
    800047e2:	8a2a                	mv	s4,a0
    800047e4:	a045                	j	80004884 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047e6:	02451783          	lh	a5,36(a0)
    800047ea:	03079693          	slli	a3,a5,0x30
    800047ee:	92c1                	srli	a3,a3,0x30
    800047f0:	4725                	li	a4,9
    800047f2:	0cd76263          	bltu	a4,a3,800048b6 <filewrite+0x12c>
    800047f6:	0792                	slli	a5,a5,0x4
    800047f8:	00020717          	auipc	a4,0x20
    800047fc:	b2070713          	addi	a4,a4,-1248 # 80024318 <devsw>
    80004800:	97ba                	add	a5,a5,a4
    80004802:	679c                	ld	a5,8(a5)
    80004804:	cbdd                	beqz	a5,800048ba <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004806:	4505                	li	a0,1
    80004808:	9782                	jalr	a5
    8000480a:	8a2a                	mv	s4,a0
    8000480c:	a8a5                	j	80004884 <filewrite+0xfa>
    8000480e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004812:	00000097          	auipc	ra,0x0
    80004816:	8b0080e7          	jalr	-1872(ra) # 800040c2 <begin_op>
      ilock(f->ip);
    8000481a:	01893503          	ld	a0,24(s2)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	ed2080e7          	jalr	-302(ra) # 800036f0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004826:	8762                	mv	a4,s8
    80004828:	02092683          	lw	a3,32(s2)
    8000482c:	01598633          	add	a2,s3,s5
    80004830:	4585                	li	a1,1
    80004832:	01893503          	ld	a0,24(s2)
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	266080e7          	jalr	614(ra) # 80003a9c <writei>
    8000483e:	84aa                	mv	s1,a0
    80004840:	00a05763          	blez	a0,8000484e <filewrite+0xc4>
        f->off += r;
    80004844:	02092783          	lw	a5,32(s2)
    80004848:	9fa9                	addw	a5,a5,a0
    8000484a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000484e:	01893503          	ld	a0,24(s2)
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	f60080e7          	jalr	-160(ra) # 800037b2 <iunlock>
      end_op();
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	8e8080e7          	jalr	-1816(ra) # 80004142 <end_op>

      if(r != n1){
    80004862:	009c1f63          	bne	s8,s1,80004880 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004866:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000486a:	0149db63          	bge	s3,s4,80004880 <filewrite+0xf6>
      int n1 = n - i;
    8000486e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004872:	84be                	mv	s1,a5
    80004874:	2781                	sext.w	a5,a5
    80004876:	f8fb5ce3          	bge	s6,a5,8000480e <filewrite+0x84>
    8000487a:	84de                	mv	s1,s7
    8000487c:	bf49                	j	8000480e <filewrite+0x84>
    int i = 0;
    8000487e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004880:	013a1f63          	bne	s4,s3,8000489e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004884:	8552                	mv	a0,s4
    80004886:	60a6                	ld	ra,72(sp)
    80004888:	6406                	ld	s0,64(sp)
    8000488a:	74e2                	ld	s1,56(sp)
    8000488c:	7942                	ld	s2,48(sp)
    8000488e:	79a2                	ld	s3,40(sp)
    80004890:	7a02                	ld	s4,32(sp)
    80004892:	6ae2                	ld	s5,24(sp)
    80004894:	6b42                	ld	s6,16(sp)
    80004896:	6ba2                	ld	s7,8(sp)
    80004898:	6c02                	ld	s8,0(sp)
    8000489a:	6161                	addi	sp,sp,80
    8000489c:	8082                	ret
    ret = (i == n ? n : -1);
    8000489e:	5a7d                	li	s4,-1
    800048a0:	b7d5                	j	80004884 <filewrite+0xfa>
    panic("filewrite");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	fae50513          	addi	a0,a0,-82 # 80008850 <syscalls+0x268>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c94080e7          	jalr	-876(ra) # 8000053e <panic>
    return -1;
    800048b2:	5a7d                	li	s4,-1
    800048b4:	bfc1                	j	80004884 <filewrite+0xfa>
      return -1;
    800048b6:	5a7d                	li	s4,-1
    800048b8:	b7f1                	j	80004884 <filewrite+0xfa>
    800048ba:	5a7d                	li	s4,-1
    800048bc:	b7e1                	j	80004884 <filewrite+0xfa>

00000000800048be <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048be:	7179                	addi	sp,sp,-48
    800048c0:	f406                	sd	ra,40(sp)
    800048c2:	f022                	sd	s0,32(sp)
    800048c4:	ec26                	sd	s1,24(sp)
    800048c6:	e84a                	sd	s2,16(sp)
    800048c8:	e44e                	sd	s3,8(sp)
    800048ca:	e052                	sd	s4,0(sp)
    800048cc:	1800                	addi	s0,sp,48
    800048ce:	84aa                	mv	s1,a0
    800048d0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048d2:	0005b023          	sd	zero,0(a1)
    800048d6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048da:	00000097          	auipc	ra,0x0
    800048de:	bf8080e7          	jalr	-1032(ra) # 800044d2 <filealloc>
    800048e2:	e088                	sd	a0,0(s1)
    800048e4:	c551                	beqz	a0,80004970 <pipealloc+0xb2>
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	bec080e7          	jalr	-1044(ra) # 800044d2 <filealloc>
    800048ee:	00aa3023          	sd	a0,0(s4)
    800048f2:	c92d                	beqz	a0,80004964 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	200080e7          	jalr	512(ra) # 80000af4 <kalloc>
    800048fc:	892a                	mv	s2,a0
    800048fe:	c125                	beqz	a0,8000495e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004900:	4985                	li	s3,1
    80004902:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004906:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000490a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000490e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004912:	00004597          	auipc	a1,0x4
    80004916:	f4e58593          	addi	a1,a1,-178 # 80008860 <syscalls+0x278>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	23a080e7          	jalr	570(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004922:	609c                	ld	a5,0(s1)
    80004924:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004928:	609c                	ld	a5,0(s1)
    8000492a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000492e:	609c                	ld	a5,0(s1)
    80004930:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000493a:	000a3783          	ld	a5,0(s4)
    8000493e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004942:	000a3783          	ld	a5,0(s4)
    80004946:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000494a:	000a3783          	ld	a5,0(s4)
    8000494e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	0127b823          	sd	s2,16(a5)
  return 0;
    8000495a:	4501                	li	a0,0
    8000495c:	a025                	j	80004984 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000495e:	6088                	ld	a0,0(s1)
    80004960:	e501                	bnez	a0,80004968 <pipealloc+0xaa>
    80004962:	a039                	j	80004970 <pipealloc+0xb2>
    80004964:	6088                	ld	a0,0(s1)
    80004966:	c51d                	beqz	a0,80004994 <pipealloc+0xd6>
    fileclose(*f0);
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	c26080e7          	jalr	-986(ra) # 8000458e <fileclose>
  if(*f1)
    80004970:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004974:	557d                	li	a0,-1
  if(*f1)
    80004976:	c799                	beqz	a5,80004984 <pipealloc+0xc6>
    fileclose(*f1);
    80004978:	853e                	mv	a0,a5
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	c14080e7          	jalr	-1004(ra) # 8000458e <fileclose>
  return -1;
    80004982:	557d                	li	a0,-1
}
    80004984:	70a2                	ld	ra,40(sp)
    80004986:	7402                	ld	s0,32(sp)
    80004988:	64e2                	ld	s1,24(sp)
    8000498a:	6942                	ld	s2,16(sp)
    8000498c:	69a2                	ld	s3,8(sp)
    8000498e:	6a02                	ld	s4,0(sp)
    80004990:	6145                	addi	sp,sp,48
    80004992:	8082                	ret
  return -1;
    80004994:	557d                	li	a0,-1
    80004996:	b7fd                	j	80004984 <pipealloc+0xc6>

0000000080004998 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004998:	1101                	addi	sp,sp,-32
    8000499a:	ec06                	sd	ra,24(sp)
    8000499c:	e822                	sd	s0,16(sp)
    8000499e:	e426                	sd	s1,8(sp)
    800049a0:	e04a                	sd	s2,0(sp)
    800049a2:	1000                	addi	s0,sp,32
    800049a4:	84aa                	mv	s1,a0
    800049a6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	23c080e7          	jalr	572(ra) # 80000be4 <acquire>
  if(writable){
    800049b0:	02090d63          	beqz	s2,800049ea <pipeclose+0x52>
    pi->writeopen = 0;
    800049b4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049b8:	21848513          	addi	a0,s1,536
    800049bc:	ffffe097          	auipc	ra,0xffffe
    800049c0:	95e080e7          	jalr	-1698(ra) # 8000231a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049c4:	2204b783          	ld	a5,544(s1)
    800049c8:	eb95                	bnez	a5,800049fc <pipeclose+0x64>
    release(&pi->lock);
    800049ca:	8526                	mv	a0,s1
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	2cc080e7          	jalr	716(ra) # 80000c98 <release>
    kfree((char*)pi);
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	022080e7          	jalr	34(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800049de:	60e2                	ld	ra,24(sp)
    800049e0:	6442                	ld	s0,16(sp)
    800049e2:	64a2                	ld	s1,8(sp)
    800049e4:	6902                	ld	s2,0(sp)
    800049e6:	6105                	addi	sp,sp,32
    800049e8:	8082                	ret
    pi->readopen = 0;
    800049ea:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049ee:	21c48513          	addi	a0,s1,540
    800049f2:	ffffe097          	auipc	ra,0xffffe
    800049f6:	928080e7          	jalr	-1752(ra) # 8000231a <wakeup>
    800049fa:	b7e9                	j	800049c4 <pipeclose+0x2c>
    release(&pi->lock);
    800049fc:	8526                	mv	a0,s1
    800049fe:	ffffc097          	auipc	ra,0xffffc
    80004a02:	29a080e7          	jalr	666(ra) # 80000c98 <release>
}
    80004a06:	bfe1                	j	800049de <pipeclose+0x46>

0000000080004a08 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a08:	7159                	addi	sp,sp,-112
    80004a0a:	f486                	sd	ra,104(sp)
    80004a0c:	f0a2                	sd	s0,96(sp)
    80004a0e:	eca6                	sd	s1,88(sp)
    80004a10:	e8ca                	sd	s2,80(sp)
    80004a12:	e4ce                	sd	s3,72(sp)
    80004a14:	e0d2                	sd	s4,64(sp)
    80004a16:	fc56                	sd	s5,56(sp)
    80004a18:	f85a                	sd	s6,48(sp)
    80004a1a:	f45e                	sd	s7,40(sp)
    80004a1c:	f062                	sd	s8,32(sp)
    80004a1e:	ec66                	sd	s9,24(sp)
    80004a20:	1880                	addi	s0,sp,112
    80004a22:	84aa                	mv	s1,a0
    80004a24:	8aae                	mv	s5,a1
    80004a26:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a28:	ffffd097          	auipc	ra,0xffffd
    80004a2c:	086080e7          	jalr	134(ra) # 80001aae <myproc>
    80004a30:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a32:	8526                	mv	a0,s1
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	1b0080e7          	jalr	432(ra) # 80000be4 <acquire>
  while(i < n){
    80004a3c:	0d405163          	blez	s4,80004afe <pipewrite+0xf6>
    80004a40:	8ba6                	mv	s7,s1
  int i = 0;
    80004a42:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a44:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a46:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a4a:	21c48c13          	addi	s8,s1,540
    80004a4e:	a08d                	j	80004ab0 <pipewrite+0xa8>
      release(&pi->lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	246080e7          	jalr	582(ra) # 80000c98 <release>
      return -1;
    80004a5a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a5c:	854a                	mv	a0,s2
    80004a5e:	70a6                	ld	ra,104(sp)
    80004a60:	7406                	ld	s0,96(sp)
    80004a62:	64e6                	ld	s1,88(sp)
    80004a64:	6946                	ld	s2,80(sp)
    80004a66:	69a6                	ld	s3,72(sp)
    80004a68:	6a06                	ld	s4,64(sp)
    80004a6a:	7ae2                	ld	s5,56(sp)
    80004a6c:	7b42                	ld	s6,48(sp)
    80004a6e:	7ba2                	ld	s7,40(sp)
    80004a70:	7c02                	ld	s8,32(sp)
    80004a72:	6ce2                	ld	s9,24(sp)
    80004a74:	6165                	addi	sp,sp,112
    80004a76:	8082                	ret
      wakeup(&pi->nread);
    80004a78:	8566                	mv	a0,s9
    80004a7a:	ffffe097          	auipc	ra,0xffffe
    80004a7e:	8a0080e7          	jalr	-1888(ra) # 8000231a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a82:	85de                	mv	a1,s7
    80004a84:	8562                	mv	a0,s8
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	6f4080e7          	jalr	1780(ra) # 8000217a <sleep>
    80004a8e:	a839                	j	80004aac <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a90:	21c4a783          	lw	a5,540(s1)
    80004a94:	0017871b          	addiw	a4,a5,1
    80004a98:	20e4ae23          	sw	a4,540(s1)
    80004a9c:	1ff7f793          	andi	a5,a5,511
    80004aa0:	97a6                	add	a5,a5,s1
    80004aa2:	f9f44703          	lbu	a4,-97(s0)
    80004aa6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004aaa:	2905                	addiw	s2,s2,1
  while(i < n){
    80004aac:	03495d63          	bge	s2,s4,80004ae6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004ab0:	2204a783          	lw	a5,544(s1)
    80004ab4:	dfd1                	beqz	a5,80004a50 <pipewrite+0x48>
    80004ab6:	0289a783          	lw	a5,40(s3)
    80004aba:	fbd9                	bnez	a5,80004a50 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004abc:	2184a783          	lw	a5,536(s1)
    80004ac0:	21c4a703          	lw	a4,540(s1)
    80004ac4:	2007879b          	addiw	a5,a5,512
    80004ac8:	faf708e3          	beq	a4,a5,80004a78 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004acc:	4685                	li	a3,1
    80004ace:	01590633          	add	a2,s2,s5
    80004ad2:	f9f40593          	addi	a1,s0,-97
    80004ad6:	0509b503          	ld	a0,80(s3)
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	d22080e7          	jalr	-734(ra) # 800017fc <copyin>
    80004ae2:	fb6517e3          	bne	a0,s6,80004a90 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ae6:	21848513          	addi	a0,s1,536
    80004aea:	ffffe097          	auipc	ra,0xffffe
    80004aee:	830080e7          	jalr	-2000(ra) # 8000231a <wakeup>
  release(&pi->lock);
    80004af2:	8526                	mv	a0,s1
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	1a4080e7          	jalr	420(ra) # 80000c98 <release>
  return i;
    80004afc:	b785                	j	80004a5c <pipewrite+0x54>
  int i = 0;
    80004afe:	4901                	li	s2,0
    80004b00:	b7dd                	j	80004ae6 <pipewrite+0xde>

0000000080004b02 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b02:	715d                	addi	sp,sp,-80
    80004b04:	e486                	sd	ra,72(sp)
    80004b06:	e0a2                	sd	s0,64(sp)
    80004b08:	fc26                	sd	s1,56(sp)
    80004b0a:	f84a                	sd	s2,48(sp)
    80004b0c:	f44e                	sd	s3,40(sp)
    80004b0e:	f052                	sd	s4,32(sp)
    80004b10:	ec56                	sd	s5,24(sp)
    80004b12:	e85a                	sd	s6,16(sp)
    80004b14:	0880                	addi	s0,sp,80
    80004b16:	84aa                	mv	s1,a0
    80004b18:	892e                	mv	s2,a1
    80004b1a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	f92080e7          	jalr	-110(ra) # 80001aae <myproc>
    80004b24:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b26:	8b26                	mv	s6,s1
    80004b28:	8526                	mv	a0,s1
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	0ba080e7          	jalr	186(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b32:	2184a703          	lw	a4,536(s1)
    80004b36:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b3a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3e:	02f71463          	bne	a4,a5,80004b66 <piperead+0x64>
    80004b42:	2244a783          	lw	a5,548(s1)
    80004b46:	c385                	beqz	a5,80004b66 <piperead+0x64>
    if(pr->killed){
    80004b48:	028a2783          	lw	a5,40(s4)
    80004b4c:	ebc1                	bnez	a5,80004bdc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b4e:	85da                	mv	a1,s6
    80004b50:	854e                	mv	a0,s3
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	628080e7          	jalr	1576(ra) # 8000217a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5a:	2184a703          	lw	a4,536(s1)
    80004b5e:	21c4a783          	lw	a5,540(s1)
    80004b62:	fef700e3          	beq	a4,a5,80004b42 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b66:	09505263          	blez	s5,80004bea <piperead+0xe8>
    80004b6a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b6e:	2184a783          	lw	a5,536(s1)
    80004b72:	21c4a703          	lw	a4,540(s1)
    80004b76:	02f70d63          	beq	a4,a5,80004bb0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b7a:	0017871b          	addiw	a4,a5,1
    80004b7e:	20e4ac23          	sw	a4,536(s1)
    80004b82:	1ff7f793          	andi	a5,a5,511
    80004b86:	97a6                	add	a5,a5,s1
    80004b88:	0187c783          	lbu	a5,24(a5)
    80004b8c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b90:	4685                	li	a3,1
    80004b92:	fbf40613          	addi	a2,s0,-65
    80004b96:	85ca                	mv	a1,s2
    80004b98:	050a3503          	ld	a0,80(s4)
    80004b9c:	ffffd097          	auipc	ra,0xffffd
    80004ba0:	bd4080e7          	jalr	-1068(ra) # 80001770 <copyout>
    80004ba4:	01650663          	beq	a0,s6,80004bb0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba8:	2985                	addiw	s3,s3,1
    80004baa:	0905                	addi	s2,s2,1
    80004bac:	fd3a91e3          	bne	s5,s3,80004b6e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bb0:	21c48513          	addi	a0,s1,540
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	766080e7          	jalr	1894(ra) # 8000231a <wakeup>
  release(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	0da080e7          	jalr	218(ra) # 80000c98 <release>
  return i;
}
    80004bc6:	854e                	mv	a0,s3
    80004bc8:	60a6                	ld	ra,72(sp)
    80004bca:	6406                	ld	s0,64(sp)
    80004bcc:	74e2                	ld	s1,56(sp)
    80004bce:	7942                	ld	s2,48(sp)
    80004bd0:	79a2                	ld	s3,40(sp)
    80004bd2:	7a02                	ld	s4,32(sp)
    80004bd4:	6ae2                	ld	s5,24(sp)
    80004bd6:	6b42                	ld	s6,16(sp)
    80004bd8:	6161                	addi	sp,sp,80
    80004bda:	8082                	ret
      release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0ba080e7          	jalr	186(ra) # 80000c98 <release>
      return -1;
    80004be6:	59fd                	li	s3,-1
    80004be8:	bff9                	j	80004bc6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bea:	4981                	li	s3,0
    80004bec:	b7d1                	j	80004bb0 <piperead+0xae>

0000000080004bee <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bee:	df010113          	addi	sp,sp,-528
    80004bf2:	20113423          	sd	ra,520(sp)
    80004bf6:	20813023          	sd	s0,512(sp)
    80004bfa:	ffa6                	sd	s1,504(sp)
    80004bfc:	fbca                	sd	s2,496(sp)
    80004bfe:	f7ce                	sd	s3,488(sp)
    80004c00:	f3d2                	sd	s4,480(sp)
    80004c02:	efd6                	sd	s5,472(sp)
    80004c04:	ebda                	sd	s6,464(sp)
    80004c06:	e7de                	sd	s7,456(sp)
    80004c08:	e3e2                	sd	s8,448(sp)
    80004c0a:	ff66                	sd	s9,440(sp)
    80004c0c:	fb6a                	sd	s10,432(sp)
    80004c0e:	f76e                	sd	s11,424(sp)
    80004c10:	0c00                	addi	s0,sp,528
    80004c12:	84aa                	mv	s1,a0
    80004c14:	dea43c23          	sd	a0,-520(s0)
    80004c18:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	e92080e7          	jalr	-366(ra) # 80001aae <myproc>
    80004c24:	892a                	mv	s2,a0

  begin_op();
    80004c26:	fffff097          	auipc	ra,0xfffff
    80004c2a:	49c080e7          	jalr	1180(ra) # 800040c2 <begin_op>

  if((ip = namei(path)) == 0){
    80004c2e:	8526                	mv	a0,s1
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	276080e7          	jalr	630(ra) # 80003ea6 <namei>
    80004c38:	c92d                	beqz	a0,80004caa <exec+0xbc>
    80004c3a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	ab4080e7          	jalr	-1356(ra) # 800036f0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c44:	04000713          	li	a4,64
    80004c48:	4681                	li	a3,0
    80004c4a:	e5040613          	addi	a2,s0,-432
    80004c4e:	4581                	li	a1,0
    80004c50:	8526                	mv	a0,s1
    80004c52:	fffff097          	auipc	ra,0xfffff
    80004c56:	d52080e7          	jalr	-686(ra) # 800039a4 <readi>
    80004c5a:	04000793          	li	a5,64
    80004c5e:	00f51a63          	bne	a0,a5,80004c72 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c62:	e5042703          	lw	a4,-432(s0)
    80004c66:	464c47b7          	lui	a5,0x464c4
    80004c6a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c6e:	04f70463          	beq	a4,a5,80004cb6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c72:	8526                	mv	a0,s1
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	cde080e7          	jalr	-802(ra) # 80003952 <iunlockput>
    end_op();
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	4c6080e7          	jalr	1222(ra) # 80004142 <end_op>
  }
  return -1;
    80004c84:	557d                	li	a0,-1
}
    80004c86:	20813083          	ld	ra,520(sp)
    80004c8a:	20013403          	ld	s0,512(sp)
    80004c8e:	74fe                	ld	s1,504(sp)
    80004c90:	795e                	ld	s2,496(sp)
    80004c92:	79be                	ld	s3,488(sp)
    80004c94:	7a1e                	ld	s4,480(sp)
    80004c96:	6afe                	ld	s5,472(sp)
    80004c98:	6b5e                	ld	s6,464(sp)
    80004c9a:	6bbe                	ld	s7,456(sp)
    80004c9c:	6c1e                	ld	s8,448(sp)
    80004c9e:	7cfa                	ld	s9,440(sp)
    80004ca0:	7d5a                	ld	s10,432(sp)
    80004ca2:	7dba                	ld	s11,424(sp)
    80004ca4:	21010113          	addi	sp,sp,528
    80004ca8:	8082                	ret
    end_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	498080e7          	jalr	1176(ra) # 80004142 <end_op>
    return -1;
    80004cb2:	557d                	li	a0,-1
    80004cb4:	bfc9                	j	80004c86 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cb6:	854a                	mv	a0,s2
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	eba080e7          	jalr	-326(ra) # 80001b72 <proc_pagetable>
    80004cc0:	8baa                	mv	s7,a0
    80004cc2:	d945                	beqz	a0,80004c72 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc4:	e7042983          	lw	s3,-400(s0)
    80004cc8:	e8845783          	lhu	a5,-376(s0)
    80004ccc:	c7ad                	beqz	a5,80004d36 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cce:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004cd2:	6c91                	lui	s9,0x4
    80004cd4:	fffc8793          	addi	a5,s9,-1 # 3fff <_entry-0x7fffc001>
    80004cd8:	def43823          	sd	a5,-528(s0)
    80004cdc:	a42d                	j	80004f06 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cde:	00004517          	auipc	a0,0x4
    80004ce2:	b8a50513          	addi	a0,a0,-1142 # 80008868 <syscalls+0x280>
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cee:	8756                	mv	a4,s5
    80004cf0:	012d86bb          	addw	a3,s11,s2
    80004cf4:	4581                	li	a1,0
    80004cf6:	8526                	mv	a0,s1
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	cac080e7          	jalr	-852(ra) # 800039a4 <readi>
    80004d00:	2501                	sext.w	a0,a0
    80004d02:	1aaa9963          	bne	s5,a0,80004eb4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d06:	6791                	lui	a5,0x4
    80004d08:	0127893b          	addw	s2,a5,s2
    80004d0c:	77f1                	lui	a5,0xffffc
    80004d0e:	01478a3b          	addw	s4,a5,s4
    80004d12:	1f897163          	bgeu	s2,s8,80004ef4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d16:	02091593          	slli	a1,s2,0x20
    80004d1a:	9181                	srli	a1,a1,0x20
    80004d1c:	95ea                	add	a1,a1,s10
    80004d1e:	855e                	mv	a0,s7
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	3bc080e7          	jalr	956(ra) # 800010dc <walkaddr>
    80004d28:	862a                	mv	a2,a0
    if(pa == 0)
    80004d2a:	d955                	beqz	a0,80004cde <exec+0xf0>
      n = PGSIZE;
    80004d2c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d2e:	fd9a70e3          	bgeu	s4,s9,80004cee <exec+0x100>
      n = sz - i;
    80004d32:	8ad2                	mv	s5,s4
    80004d34:	bf6d                	j	80004cee <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d36:	4901                	li	s2,0
  iunlockput(ip);
    80004d38:	8526                	mv	a0,s1
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	c18080e7          	jalr	-1000(ra) # 80003952 <iunlockput>
  end_op();
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	400080e7          	jalr	1024(ra) # 80004142 <end_op>
  p = myproc();
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	d64080e7          	jalr	-668(ra) # 80001aae <myproc>
    80004d52:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d54:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d58:	6791                	lui	a5,0x4
    80004d5a:	17fd                	addi	a5,a5,-1
    80004d5c:	993e                	add	s2,s2,a5
    80004d5e:	7571                	lui	a0,0xffffc
    80004d60:	00a977b3          	and	a5,s2,a0
    80004d64:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d68:	6621                	lui	a2,0x8
    80004d6a:	963e                	add	a2,a2,a5
    80004d6c:	85be                	mv	a1,a5
    80004d6e:	855e                	mv	a0,s7
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	7b0080e7          	jalr	1968(ra) # 80001520 <uvmalloc>
    80004d78:	8b2a                	mv	s6,a0
  ip = 0;
    80004d7a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d7c:	12050c63          	beqz	a0,80004eb4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d80:	75e1                	lui	a1,0xffff8
    80004d82:	95aa                	add	a1,a1,a0
    80004d84:	855e                	mv	a0,s7
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	9b8080e7          	jalr	-1608(ra) # 8000173e <uvmclear>
  stackbase = sp - PGSIZE;
    80004d8e:	7c71                	lui	s8,0xffffc
    80004d90:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d92:	e0043783          	ld	a5,-512(s0)
    80004d96:	6388                	ld	a0,0(a5)
    80004d98:	c535                	beqz	a0,80004e04 <exec+0x216>
    80004d9a:	e9040993          	addi	s3,s0,-368
    80004d9e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004da2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	0c0080e7          	jalr	192(ra) # 80000e64 <strlen>
    80004dac:	2505                	addiw	a0,a0,1
    80004dae:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004db2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004db6:	13896363          	bltu	s2,s8,80004edc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dba:	e0043d83          	ld	s11,-512(s0)
    80004dbe:	000dba03          	ld	s4,0(s11)
    80004dc2:	8552                	mv	a0,s4
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	0a0080e7          	jalr	160(ra) # 80000e64 <strlen>
    80004dcc:	0015069b          	addiw	a3,a0,1
    80004dd0:	8652                	mv	a2,s4
    80004dd2:	85ca                	mv	a1,s2
    80004dd4:	855e                	mv	a0,s7
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	99a080e7          	jalr	-1638(ra) # 80001770 <copyout>
    80004dde:	10054363          	bltz	a0,80004ee4 <exec+0x2f6>
    ustack[argc] = sp;
    80004de2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004de6:	0485                	addi	s1,s1,1
    80004de8:	008d8793          	addi	a5,s11,8
    80004dec:	e0f43023          	sd	a5,-512(s0)
    80004df0:	008db503          	ld	a0,8(s11)
    80004df4:	c911                	beqz	a0,80004e08 <exec+0x21a>
    if(argc >= MAXARG)
    80004df6:	09a1                	addi	s3,s3,8
    80004df8:	fb3c96e3          	bne	s9,s3,80004da4 <exec+0x1b6>
  sz = sz1;
    80004dfc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e00:	4481                	li	s1,0
    80004e02:	a84d                	j	80004eb4 <exec+0x2c6>
  sp = sz;
    80004e04:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e06:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e08:	00349793          	slli	a5,s1,0x3
    80004e0c:	f9040713          	addi	a4,s0,-112
    80004e10:	97ba                	add	a5,a5,a4
    80004e12:	f007b023          	sd	zero,-256(a5) # 3f00 <_entry-0x7fffc100>
  sp -= (argc+1) * sizeof(uint64);
    80004e16:	00148693          	addi	a3,s1,1
    80004e1a:	068e                	slli	a3,a3,0x3
    80004e1c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e20:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e24:	01897663          	bgeu	s2,s8,80004e30 <exec+0x242>
  sz = sz1;
    80004e28:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e2c:	4481                	li	s1,0
    80004e2e:	a059                	j	80004eb4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e30:	e9040613          	addi	a2,s0,-368
    80004e34:	85ca                	mv	a1,s2
    80004e36:	855e                	mv	a0,s7
    80004e38:	ffffd097          	auipc	ra,0xffffd
    80004e3c:	938080e7          	jalr	-1736(ra) # 80001770 <copyout>
    80004e40:	0a054663          	bltz	a0,80004eec <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e44:	058ab783          	ld	a5,88(s5)
    80004e48:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e4c:	df843783          	ld	a5,-520(s0)
    80004e50:	0007c703          	lbu	a4,0(a5)
    80004e54:	cf11                	beqz	a4,80004e70 <exec+0x282>
    80004e56:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e58:	02f00693          	li	a3,47
    80004e5c:	a039                	j	80004e6a <exec+0x27c>
      last = s+1;
    80004e5e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004e62:	0785                	addi	a5,a5,1
    80004e64:	fff7c703          	lbu	a4,-1(a5)
    80004e68:	c701                	beqz	a4,80004e70 <exec+0x282>
    if(*s == '/')
    80004e6a:	fed71ce3          	bne	a4,a3,80004e62 <exec+0x274>
    80004e6e:	bfc5                	j	80004e5e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e70:	4641                	li	a2,16
    80004e72:	df843583          	ld	a1,-520(s0)
    80004e76:	158a8513          	addi	a0,s5,344
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	fb8080e7          	jalr	-72(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e82:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e86:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e8a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e8e:	058ab783          	ld	a5,88(s5)
    80004e92:	e6843703          	ld	a4,-408(s0)
    80004e96:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e98:	058ab783          	ld	a5,88(s5)
    80004e9c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ea0:	85ea                	mv	a1,s10
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	d6c080e7          	jalr	-660(ra) # 80001c0e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eaa:	0004851b          	sext.w	a0,s1
    80004eae:	bbe1                	j	80004c86 <exec+0x98>
    80004eb0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004eb4:	e0843583          	ld	a1,-504(s0)
    80004eb8:	855e                	mv	a0,s7
    80004eba:	ffffd097          	auipc	ra,0xffffd
    80004ebe:	d54080e7          	jalr	-684(ra) # 80001c0e <proc_freepagetable>
  if(ip){
    80004ec2:	da0498e3          	bnez	s1,80004c72 <exec+0x84>
  return -1;
    80004ec6:	557d                	li	a0,-1
    80004ec8:	bb7d                	j	80004c86 <exec+0x98>
    80004eca:	e1243423          	sd	s2,-504(s0)
    80004ece:	b7dd                	j	80004eb4 <exec+0x2c6>
    80004ed0:	e1243423          	sd	s2,-504(s0)
    80004ed4:	b7c5                	j	80004eb4 <exec+0x2c6>
    80004ed6:	e1243423          	sd	s2,-504(s0)
    80004eda:	bfe9                	j	80004eb4 <exec+0x2c6>
  sz = sz1;
    80004edc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee0:	4481                	li	s1,0
    80004ee2:	bfc9                	j	80004eb4 <exec+0x2c6>
  sz = sz1;
    80004ee4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee8:	4481                	li	s1,0
    80004eea:	b7e9                	j	80004eb4 <exec+0x2c6>
  sz = sz1;
    80004eec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef0:	4481                	li	s1,0
    80004ef2:	b7c9                	j	80004eb4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ef4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef8:	2b05                	addiw	s6,s6,1
    80004efa:	0389899b          	addiw	s3,s3,56
    80004efe:	e8845783          	lhu	a5,-376(s0)
    80004f02:	e2fb5be3          	bge	s6,a5,80004d38 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f06:	2981                	sext.w	s3,s3
    80004f08:	03800713          	li	a4,56
    80004f0c:	86ce                	mv	a3,s3
    80004f0e:	e1840613          	addi	a2,s0,-488
    80004f12:	4581                	li	a1,0
    80004f14:	8526                	mv	a0,s1
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	a8e080e7          	jalr	-1394(ra) # 800039a4 <readi>
    80004f1e:	03800793          	li	a5,56
    80004f22:	f8f517e3          	bne	a0,a5,80004eb0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f26:	e1842783          	lw	a5,-488(s0)
    80004f2a:	4705                	li	a4,1
    80004f2c:	fce796e3          	bne	a5,a4,80004ef8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004f30:	e4043603          	ld	a2,-448(s0)
    80004f34:	e3843783          	ld	a5,-456(s0)
    80004f38:	f8f669e3          	bltu	a2,a5,80004eca <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f3c:	e2843783          	ld	a5,-472(s0)
    80004f40:	963e                	add	a2,a2,a5
    80004f42:	f8f667e3          	bltu	a2,a5,80004ed0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f46:	85ca                	mv	a1,s2
    80004f48:	855e                	mv	a0,s7
    80004f4a:	ffffc097          	auipc	ra,0xffffc
    80004f4e:	5d6080e7          	jalr	1494(ra) # 80001520 <uvmalloc>
    80004f52:	e0a43423          	sd	a0,-504(s0)
    80004f56:	d141                	beqz	a0,80004ed6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80004f58:	e2843d03          	ld	s10,-472(s0)
    80004f5c:	df043783          	ld	a5,-528(s0)
    80004f60:	00fd77b3          	and	a5,s10,a5
    80004f64:	fba1                	bnez	a5,80004eb4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f66:	e2042d83          	lw	s11,-480(s0)
    80004f6a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f6e:	f80c03e3          	beqz	s8,80004ef4 <exec+0x306>
    80004f72:	8a62                	mv	s4,s8
    80004f74:	4901                	li	s2,0
    80004f76:	b345                	j	80004d16 <exec+0x128>

0000000080004f78 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f78:	7179                	addi	sp,sp,-48
    80004f7a:	f406                	sd	ra,40(sp)
    80004f7c:	f022                	sd	s0,32(sp)
    80004f7e:	ec26                	sd	s1,24(sp)
    80004f80:	e84a                	sd	s2,16(sp)
    80004f82:	1800                	addi	s0,sp,48
    80004f84:	892e                	mv	s2,a1
    80004f86:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f88:	fdc40593          	addi	a1,s0,-36
    80004f8c:	ffffe097          	auipc	ra,0xffffe
    80004f90:	bf2080e7          	jalr	-1038(ra) # 80002b7e <argint>
    80004f94:	04054063          	bltz	a0,80004fd4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f98:	fdc42703          	lw	a4,-36(s0)
    80004f9c:	47bd                	li	a5,15
    80004f9e:	02e7ed63          	bltu	a5,a4,80004fd8 <argfd+0x60>
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	b0c080e7          	jalr	-1268(ra) # 80001aae <myproc>
    80004faa:	fdc42703          	lw	a4,-36(s0)
    80004fae:	01a70793          	addi	a5,a4,26
    80004fb2:	078e                	slli	a5,a5,0x3
    80004fb4:	953e                	add	a0,a0,a5
    80004fb6:	611c                	ld	a5,0(a0)
    80004fb8:	c395                	beqz	a5,80004fdc <argfd+0x64>
    return -1;
  if(pfd)
    80004fba:	00090463          	beqz	s2,80004fc2 <argfd+0x4a>
    *pfd = fd;
    80004fbe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fc2:	4501                	li	a0,0
  if(pf)
    80004fc4:	c091                	beqz	s1,80004fc8 <argfd+0x50>
    *pf = f;
    80004fc6:	e09c                	sd	a5,0(s1)
}
    80004fc8:	70a2                	ld	ra,40(sp)
    80004fca:	7402                	ld	s0,32(sp)
    80004fcc:	64e2                	ld	s1,24(sp)
    80004fce:	6942                	ld	s2,16(sp)
    80004fd0:	6145                	addi	sp,sp,48
    80004fd2:	8082                	ret
    return -1;
    80004fd4:	557d                	li	a0,-1
    80004fd6:	bfcd                	j	80004fc8 <argfd+0x50>
    return -1;
    80004fd8:	557d                	li	a0,-1
    80004fda:	b7fd                	j	80004fc8 <argfd+0x50>
    80004fdc:	557d                	li	a0,-1
    80004fde:	b7ed                	j	80004fc8 <argfd+0x50>

0000000080004fe0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fe0:	1101                	addi	sp,sp,-32
    80004fe2:	ec06                	sd	ra,24(sp)
    80004fe4:	e822                	sd	s0,16(sp)
    80004fe6:	e426                	sd	s1,8(sp)
    80004fe8:	1000                	addi	s0,sp,32
    80004fea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	ac2080e7          	jalr	-1342(ra) # 80001aae <myproc>
    80004ff4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ff6:	0d050793          	addi	a5,a0,208 # ffffffffffffc0d0 <end+0xffffffff7ffc80d0>
    80004ffa:	4501                	li	a0,0
    80004ffc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ffe:	6398                	ld	a4,0(a5)
    80005000:	cb19                	beqz	a4,80005016 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005002:	2505                	addiw	a0,a0,1
    80005004:	07a1                	addi	a5,a5,8
    80005006:	fed51ce3          	bne	a0,a3,80004ffe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000500a:	557d                	li	a0,-1
}
    8000500c:	60e2                	ld	ra,24(sp)
    8000500e:	6442                	ld	s0,16(sp)
    80005010:	64a2                	ld	s1,8(sp)
    80005012:	6105                	addi	sp,sp,32
    80005014:	8082                	ret
      p->ofile[fd] = f;
    80005016:	01a50793          	addi	a5,a0,26
    8000501a:	078e                	slli	a5,a5,0x3
    8000501c:	963e                	add	a2,a2,a5
    8000501e:	e204                	sd	s1,0(a2)
      return fd;
    80005020:	b7f5                	j	8000500c <fdalloc+0x2c>

0000000080005022 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005022:	715d                	addi	sp,sp,-80
    80005024:	e486                	sd	ra,72(sp)
    80005026:	e0a2                	sd	s0,64(sp)
    80005028:	fc26                	sd	s1,56(sp)
    8000502a:	f84a                	sd	s2,48(sp)
    8000502c:	f44e                	sd	s3,40(sp)
    8000502e:	f052                	sd	s4,32(sp)
    80005030:	ec56                	sd	s5,24(sp)
    80005032:	0880                	addi	s0,sp,80
    80005034:	89ae                	mv	s3,a1
    80005036:	8ab2                	mv	s5,a2
    80005038:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000503a:	fb040593          	addi	a1,s0,-80
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	e86080e7          	jalr	-378(ra) # 80003ec4 <nameiparent>
    80005046:	892a                	mv	s2,a0
    80005048:	12050f63          	beqz	a0,80005186 <create+0x164>
    return 0;

  ilock(dp);
    8000504c:	ffffe097          	auipc	ra,0xffffe
    80005050:	6a4080e7          	jalr	1700(ra) # 800036f0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005054:	4601                	li	a2,0
    80005056:	fb040593          	addi	a1,s0,-80
    8000505a:	854a                	mv	a0,s2
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	b78080e7          	jalr	-1160(ra) # 80003bd4 <dirlookup>
    80005064:	84aa                	mv	s1,a0
    80005066:	c921                	beqz	a0,800050b6 <create+0x94>
    iunlockput(dp);
    80005068:	854a                	mv	a0,s2
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	8e8080e7          	jalr	-1816(ra) # 80003952 <iunlockput>
    ilock(ip);
    80005072:	8526                	mv	a0,s1
    80005074:	ffffe097          	auipc	ra,0xffffe
    80005078:	67c080e7          	jalr	1660(ra) # 800036f0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000507c:	2981                	sext.w	s3,s3
    8000507e:	4789                	li	a5,2
    80005080:	02f99463          	bne	s3,a5,800050a8 <create+0x86>
    80005084:	0444d783          	lhu	a5,68(s1)
    80005088:	37f9                	addiw	a5,a5,-2
    8000508a:	17c2                	slli	a5,a5,0x30
    8000508c:	93c1                	srli	a5,a5,0x30
    8000508e:	4705                	li	a4,1
    80005090:	00f76c63          	bltu	a4,a5,800050a8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005094:	8526                	mv	a0,s1
    80005096:	60a6                	ld	ra,72(sp)
    80005098:	6406                	ld	s0,64(sp)
    8000509a:	74e2                	ld	s1,56(sp)
    8000509c:	7942                	ld	s2,48(sp)
    8000509e:	79a2                	ld	s3,40(sp)
    800050a0:	7a02                	ld	s4,32(sp)
    800050a2:	6ae2                	ld	s5,24(sp)
    800050a4:	6161                	addi	sp,sp,80
    800050a6:	8082                	ret
    iunlockput(ip);
    800050a8:	8526                	mv	a0,s1
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	8a8080e7          	jalr	-1880(ra) # 80003952 <iunlockput>
    return 0;
    800050b2:	4481                	li	s1,0
    800050b4:	b7c5                	j	80005094 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050b6:	85ce                	mv	a1,s3
    800050b8:	00092503          	lw	a0,0(s2)
    800050bc:	ffffe097          	auipc	ra,0xffffe
    800050c0:	49c080e7          	jalr	1180(ra) # 80003558 <ialloc>
    800050c4:	84aa                	mv	s1,a0
    800050c6:	c529                	beqz	a0,80005110 <create+0xee>
  ilock(ip);
    800050c8:	ffffe097          	auipc	ra,0xffffe
    800050cc:	628080e7          	jalr	1576(ra) # 800036f0 <ilock>
  ip->major = major;
    800050d0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050d4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050d8:	4785                	li	a5,1
    800050da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	546080e7          	jalr	1350(ra) # 80003626 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050e8:	2981                	sext.w	s3,s3
    800050ea:	4785                	li	a5,1
    800050ec:	02f98a63          	beq	s3,a5,80005120 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050f0:	40d0                	lw	a2,4(s1)
    800050f2:	fb040593          	addi	a1,s0,-80
    800050f6:	854a                	mv	a0,s2
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	cec080e7          	jalr	-788(ra) # 80003de4 <dirlink>
    80005100:	06054b63          	bltz	a0,80005176 <create+0x154>
  iunlockput(dp);
    80005104:	854a                	mv	a0,s2
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	84c080e7          	jalr	-1972(ra) # 80003952 <iunlockput>
  return ip;
    8000510e:	b759                	j	80005094 <create+0x72>
    panic("create: ialloc");
    80005110:	00003517          	auipc	a0,0x3
    80005114:	77850513          	addi	a0,a0,1912 # 80008888 <syscalls+0x2a0>
    80005118:	ffffb097          	auipc	ra,0xffffb
    8000511c:	426080e7          	jalr	1062(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005120:	04a95783          	lhu	a5,74(s2)
    80005124:	2785                	addiw	a5,a5,1
    80005126:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000512a:	854a                	mv	a0,s2
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	4fa080e7          	jalr	1274(ra) # 80003626 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005134:	40d0                	lw	a2,4(s1)
    80005136:	00003597          	auipc	a1,0x3
    8000513a:	76258593          	addi	a1,a1,1890 # 80008898 <syscalls+0x2b0>
    8000513e:	8526                	mv	a0,s1
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	ca4080e7          	jalr	-860(ra) # 80003de4 <dirlink>
    80005148:	00054f63          	bltz	a0,80005166 <create+0x144>
    8000514c:	00492603          	lw	a2,4(s2)
    80005150:	00003597          	auipc	a1,0x3
    80005154:	75058593          	addi	a1,a1,1872 # 800088a0 <syscalls+0x2b8>
    80005158:	8526                	mv	a0,s1
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	c8a080e7          	jalr	-886(ra) # 80003de4 <dirlink>
    80005162:	f80557e3          	bgez	a0,800050f0 <create+0xce>
      panic("create dots");
    80005166:	00003517          	auipc	a0,0x3
    8000516a:	74250513          	addi	a0,a0,1858 # 800088a8 <syscalls+0x2c0>
    8000516e:	ffffb097          	auipc	ra,0xffffb
    80005172:	3d0080e7          	jalr	976(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005176:	00003517          	auipc	a0,0x3
    8000517a:	74250513          	addi	a0,a0,1858 # 800088b8 <syscalls+0x2d0>
    8000517e:	ffffb097          	auipc	ra,0xffffb
    80005182:	3c0080e7          	jalr	960(ra) # 8000053e <panic>
    return 0;
    80005186:	84aa                	mv	s1,a0
    80005188:	b731                	j	80005094 <create+0x72>

000000008000518a <sys_dup>:
{
    8000518a:	7179                	addi	sp,sp,-48
    8000518c:	f406                	sd	ra,40(sp)
    8000518e:	f022                	sd	s0,32(sp)
    80005190:	ec26                	sd	s1,24(sp)
    80005192:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005194:	fd840613          	addi	a2,s0,-40
    80005198:	4581                	li	a1,0
    8000519a:	4501                	li	a0,0
    8000519c:	00000097          	auipc	ra,0x0
    800051a0:	ddc080e7          	jalr	-548(ra) # 80004f78 <argfd>
    return -1;
    800051a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051a6:	02054363          	bltz	a0,800051cc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051aa:	fd843503          	ld	a0,-40(s0)
    800051ae:	00000097          	auipc	ra,0x0
    800051b2:	e32080e7          	jalr	-462(ra) # 80004fe0 <fdalloc>
    800051b6:	84aa                	mv	s1,a0
    return -1;
    800051b8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051ba:	00054963          	bltz	a0,800051cc <sys_dup+0x42>
  filedup(f);
    800051be:	fd843503          	ld	a0,-40(s0)
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	37a080e7          	jalr	890(ra) # 8000453c <filedup>
  return fd;
    800051ca:	87a6                	mv	a5,s1
}
    800051cc:	853e                	mv	a0,a5
    800051ce:	70a2                	ld	ra,40(sp)
    800051d0:	7402                	ld	s0,32(sp)
    800051d2:	64e2                	ld	s1,24(sp)
    800051d4:	6145                	addi	sp,sp,48
    800051d6:	8082                	ret

00000000800051d8 <sys_read>:
{
    800051d8:	7179                	addi	sp,sp,-48
    800051da:	f406                	sd	ra,40(sp)
    800051dc:	f022                	sd	s0,32(sp)
    800051de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051e0:	fe840613          	addi	a2,s0,-24
    800051e4:	4581                	li	a1,0
    800051e6:	4501                	li	a0,0
    800051e8:	00000097          	auipc	ra,0x0
    800051ec:	d90080e7          	jalr	-624(ra) # 80004f78 <argfd>
    return -1;
    800051f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f2:	04054163          	bltz	a0,80005234 <sys_read+0x5c>
    800051f6:	fe440593          	addi	a1,s0,-28
    800051fa:	4509                	li	a0,2
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	982080e7          	jalr	-1662(ra) # 80002b7e <argint>
    return -1;
    80005204:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005206:	02054763          	bltz	a0,80005234 <sys_read+0x5c>
    8000520a:	fd840593          	addi	a1,s0,-40
    8000520e:	4505                	li	a0,1
    80005210:	ffffe097          	auipc	ra,0xffffe
    80005214:	990080e7          	jalr	-1648(ra) # 80002ba0 <argaddr>
    return -1;
    80005218:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521a:	00054d63          	bltz	a0,80005234 <sys_read+0x5c>
  return fileread(f, p, n);
    8000521e:	fe442603          	lw	a2,-28(s0)
    80005222:	fd843583          	ld	a1,-40(s0)
    80005226:	fe843503          	ld	a0,-24(s0)
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	49e080e7          	jalr	1182(ra) # 800046c8 <fileread>
    80005232:	87aa                	mv	a5,a0
}
    80005234:	853e                	mv	a0,a5
    80005236:	70a2                	ld	ra,40(sp)
    80005238:	7402                	ld	s0,32(sp)
    8000523a:	6145                	addi	sp,sp,48
    8000523c:	8082                	ret

000000008000523e <sys_write>:
{
    8000523e:	7179                	addi	sp,sp,-48
    80005240:	f406                	sd	ra,40(sp)
    80005242:	f022                	sd	s0,32(sp)
    80005244:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005246:	fe840613          	addi	a2,s0,-24
    8000524a:	4581                	li	a1,0
    8000524c:	4501                	li	a0,0
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	d2a080e7          	jalr	-726(ra) # 80004f78 <argfd>
    return -1;
    80005256:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005258:	04054163          	bltz	a0,8000529a <sys_write+0x5c>
    8000525c:	fe440593          	addi	a1,s0,-28
    80005260:	4509                	li	a0,2
    80005262:	ffffe097          	auipc	ra,0xffffe
    80005266:	91c080e7          	jalr	-1764(ra) # 80002b7e <argint>
    return -1;
    8000526a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	02054763          	bltz	a0,8000529a <sys_write+0x5c>
    80005270:	fd840593          	addi	a1,s0,-40
    80005274:	4505                	li	a0,1
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	92a080e7          	jalr	-1750(ra) # 80002ba0 <argaddr>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	00054d63          	bltz	a0,8000529a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005284:	fe442603          	lw	a2,-28(s0)
    80005288:	fd843583          	ld	a1,-40(s0)
    8000528c:	fe843503          	ld	a0,-24(s0)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	4fa080e7          	jalr	1274(ra) # 8000478a <filewrite>
    80005298:	87aa                	mv	a5,a0
}
    8000529a:	853e                	mv	a0,a5
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret

00000000800052a4 <sys_close>:
{
    800052a4:	1101                	addi	sp,sp,-32
    800052a6:	ec06                	sd	ra,24(sp)
    800052a8:	e822                	sd	s0,16(sp)
    800052aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052ac:	fe040613          	addi	a2,s0,-32
    800052b0:	fec40593          	addi	a1,s0,-20
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	cc2080e7          	jalr	-830(ra) # 80004f78 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052c0:	02054463          	bltz	a0,800052e8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	7ea080e7          	jalr	2026(ra) # 80001aae <myproc>
    800052cc:	fec42783          	lw	a5,-20(s0)
    800052d0:	07e9                	addi	a5,a5,26
    800052d2:	078e                	slli	a5,a5,0x3
    800052d4:	97aa                	add	a5,a5,a0
    800052d6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052da:	fe043503          	ld	a0,-32(s0)
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	2b0080e7          	jalr	688(ra) # 8000458e <fileclose>
  return 0;
    800052e6:	4781                	li	a5,0
}
    800052e8:	853e                	mv	a0,a5
    800052ea:	60e2                	ld	ra,24(sp)
    800052ec:	6442                	ld	s0,16(sp)
    800052ee:	6105                	addi	sp,sp,32
    800052f0:	8082                	ret

00000000800052f2 <sys_fstat>:
{
    800052f2:	1101                	addi	sp,sp,-32
    800052f4:	ec06                	sd	ra,24(sp)
    800052f6:	e822                	sd	s0,16(sp)
    800052f8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052fa:	fe840613          	addi	a2,s0,-24
    800052fe:	4581                	li	a1,0
    80005300:	4501                	li	a0,0
    80005302:	00000097          	auipc	ra,0x0
    80005306:	c76080e7          	jalr	-906(ra) # 80004f78 <argfd>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000530c:	02054563          	bltz	a0,80005336 <sys_fstat+0x44>
    80005310:	fe040593          	addi	a1,s0,-32
    80005314:	4505                	li	a0,1
    80005316:	ffffe097          	auipc	ra,0xffffe
    8000531a:	88a080e7          	jalr	-1910(ra) # 80002ba0 <argaddr>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005320:	00054b63          	bltz	a0,80005336 <sys_fstat+0x44>
  return filestat(f, st);
    80005324:	fe043583          	ld	a1,-32(s0)
    80005328:	fe843503          	ld	a0,-24(s0)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	32a080e7          	jalr	810(ra) # 80004656 <filestat>
    80005334:	87aa                	mv	a5,a0
}
    80005336:	853e                	mv	a0,a5
    80005338:	60e2                	ld	ra,24(sp)
    8000533a:	6442                	ld	s0,16(sp)
    8000533c:	6105                	addi	sp,sp,32
    8000533e:	8082                	ret

0000000080005340 <sys_link>:
{
    80005340:	7169                	addi	sp,sp,-304
    80005342:	f606                	sd	ra,296(sp)
    80005344:	f222                	sd	s0,288(sp)
    80005346:	ee26                	sd	s1,280(sp)
    80005348:	ea4a                	sd	s2,272(sp)
    8000534a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000534c:	08000613          	li	a2,128
    80005350:	ed040593          	addi	a1,s0,-304
    80005354:	4501                	li	a0,0
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	86c080e7          	jalr	-1940(ra) # 80002bc2 <argstr>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005360:	10054e63          	bltz	a0,8000547c <sys_link+0x13c>
    80005364:	08000613          	li	a2,128
    80005368:	f5040593          	addi	a1,s0,-176
    8000536c:	4505                	li	a0,1
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	854080e7          	jalr	-1964(ra) # 80002bc2 <argstr>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005378:	10054263          	bltz	a0,8000547c <sys_link+0x13c>
  begin_op();
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	d46080e7          	jalr	-698(ra) # 800040c2 <begin_op>
  if((ip = namei(old)) == 0){
    80005384:	ed040513          	addi	a0,s0,-304
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	b1e080e7          	jalr	-1250(ra) # 80003ea6 <namei>
    80005390:	84aa                	mv	s1,a0
    80005392:	c551                	beqz	a0,8000541e <sys_link+0xde>
  ilock(ip);
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	35c080e7          	jalr	860(ra) # 800036f0 <ilock>
  if(ip->type == T_DIR){
    8000539c:	04449703          	lh	a4,68(s1)
    800053a0:	4785                	li	a5,1
    800053a2:	08f70463          	beq	a4,a5,8000542a <sys_link+0xea>
  ip->nlink++;
    800053a6:	04a4d783          	lhu	a5,74(s1)
    800053aa:	2785                	addiw	a5,a5,1
    800053ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053b0:	8526                	mv	a0,s1
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	274080e7          	jalr	628(ra) # 80003626 <iupdate>
  iunlock(ip);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	3f6080e7          	jalr	1014(ra) # 800037b2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053c4:	fd040593          	addi	a1,s0,-48
    800053c8:	f5040513          	addi	a0,s0,-176
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	af8080e7          	jalr	-1288(ra) # 80003ec4 <nameiparent>
    800053d4:	892a                	mv	s2,a0
    800053d6:	c935                	beqz	a0,8000544a <sys_link+0x10a>
  ilock(dp);
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	318080e7          	jalr	792(ra) # 800036f0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053e0:	00092703          	lw	a4,0(s2)
    800053e4:	409c                	lw	a5,0(s1)
    800053e6:	04f71d63          	bne	a4,a5,80005440 <sys_link+0x100>
    800053ea:	40d0                	lw	a2,4(s1)
    800053ec:	fd040593          	addi	a1,s0,-48
    800053f0:	854a                	mv	a0,s2
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	9f2080e7          	jalr	-1550(ra) # 80003de4 <dirlink>
    800053fa:	04054363          	bltz	a0,80005440 <sys_link+0x100>
  iunlockput(dp);
    800053fe:	854a                	mv	a0,s2
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	552080e7          	jalr	1362(ra) # 80003952 <iunlockput>
  iput(ip);
    80005408:	8526                	mv	a0,s1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	4a0080e7          	jalr	1184(ra) # 800038aa <iput>
  end_op();
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	d30080e7          	jalr	-720(ra) # 80004142 <end_op>
  return 0;
    8000541a:	4781                	li	a5,0
    8000541c:	a085                	j	8000547c <sys_link+0x13c>
    end_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	d24080e7          	jalr	-732(ra) # 80004142 <end_op>
    return -1;
    80005426:	57fd                	li	a5,-1
    80005428:	a891                	j	8000547c <sys_link+0x13c>
    iunlockput(ip);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	526080e7          	jalr	1318(ra) # 80003952 <iunlockput>
    end_op();
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	d0e080e7          	jalr	-754(ra) # 80004142 <end_op>
    return -1;
    8000543c:	57fd                	li	a5,-1
    8000543e:	a83d                	j	8000547c <sys_link+0x13c>
    iunlockput(dp);
    80005440:	854a                	mv	a0,s2
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	510080e7          	jalr	1296(ra) # 80003952 <iunlockput>
  ilock(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	2a4080e7          	jalr	676(ra) # 800036f0 <ilock>
  ip->nlink--;
    80005454:	04a4d783          	lhu	a5,74(s1)
    80005458:	37fd                	addiw	a5,a5,-1
    8000545a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	1c6080e7          	jalr	454(ra) # 80003626 <iupdate>
  iunlockput(ip);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	4e8080e7          	jalr	1256(ra) # 80003952 <iunlockput>
  end_op();
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	cd0080e7          	jalr	-816(ra) # 80004142 <end_op>
  return -1;
    8000547a:	57fd                	li	a5,-1
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	70b2                	ld	ra,296(sp)
    80005480:	7412                	ld	s0,288(sp)
    80005482:	64f2                	ld	s1,280(sp)
    80005484:	6952                	ld	s2,272(sp)
    80005486:	6155                	addi	sp,sp,304
    80005488:	8082                	ret

000000008000548a <sys_unlink>:
{
    8000548a:	7151                	addi	sp,sp,-240
    8000548c:	f586                	sd	ra,232(sp)
    8000548e:	f1a2                	sd	s0,224(sp)
    80005490:	eda6                	sd	s1,216(sp)
    80005492:	e9ca                	sd	s2,208(sp)
    80005494:	e5ce                	sd	s3,200(sp)
    80005496:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005498:	08000613          	li	a2,128
    8000549c:	f3040593          	addi	a1,s0,-208
    800054a0:	4501                	li	a0,0
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	720080e7          	jalr	1824(ra) # 80002bc2 <argstr>
    800054aa:	18054163          	bltz	a0,8000562c <sys_unlink+0x1a2>
  begin_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c14080e7          	jalr	-1004(ra) # 800040c2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054b6:	fb040593          	addi	a1,s0,-80
    800054ba:	f3040513          	addi	a0,s0,-208
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	a06080e7          	jalr	-1530(ra) # 80003ec4 <nameiparent>
    800054c6:	84aa                	mv	s1,a0
    800054c8:	c979                	beqz	a0,8000559e <sys_unlink+0x114>
  ilock(dp);
    800054ca:	ffffe097          	auipc	ra,0xffffe
    800054ce:	226080e7          	jalr	550(ra) # 800036f0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054d2:	00003597          	auipc	a1,0x3
    800054d6:	3c658593          	addi	a1,a1,966 # 80008898 <syscalls+0x2b0>
    800054da:	fb040513          	addi	a0,s0,-80
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	6dc080e7          	jalr	1756(ra) # 80003bba <namecmp>
    800054e6:	14050a63          	beqz	a0,8000563a <sys_unlink+0x1b0>
    800054ea:	00003597          	auipc	a1,0x3
    800054ee:	3b658593          	addi	a1,a1,950 # 800088a0 <syscalls+0x2b8>
    800054f2:	fb040513          	addi	a0,s0,-80
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	6c4080e7          	jalr	1732(ra) # 80003bba <namecmp>
    800054fe:	12050e63          	beqz	a0,8000563a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005502:	f2c40613          	addi	a2,s0,-212
    80005506:	fb040593          	addi	a1,s0,-80
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	6c8080e7          	jalr	1736(ra) # 80003bd4 <dirlookup>
    80005514:	892a                	mv	s2,a0
    80005516:	12050263          	beqz	a0,8000563a <sys_unlink+0x1b0>
  ilock(ip);
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	1d6080e7          	jalr	470(ra) # 800036f0 <ilock>
  if(ip->nlink < 1)
    80005522:	04a91783          	lh	a5,74(s2)
    80005526:	08f05263          	blez	a5,800055aa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000552a:	04491703          	lh	a4,68(s2)
    8000552e:	4785                	li	a5,1
    80005530:	08f70563          	beq	a4,a5,800055ba <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005534:	4641                	li	a2,16
    80005536:	4581                	li	a1,0
    80005538:	fc040513          	addi	a0,s0,-64
    8000553c:	ffffb097          	auipc	ra,0xffffb
    80005540:	7a4080e7          	jalr	1956(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005544:	4741                	li	a4,16
    80005546:	f2c42683          	lw	a3,-212(s0)
    8000554a:	fc040613          	addi	a2,s0,-64
    8000554e:	4581                	li	a1,0
    80005550:	8526                	mv	a0,s1
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	54a080e7          	jalr	1354(ra) # 80003a9c <writei>
    8000555a:	47c1                	li	a5,16
    8000555c:	0af51563          	bne	a0,a5,80005606 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005560:	04491703          	lh	a4,68(s2)
    80005564:	4785                	li	a5,1
    80005566:	0af70863          	beq	a4,a5,80005616 <sys_unlink+0x18c>
  iunlockput(dp);
    8000556a:	8526                	mv	a0,s1
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	3e6080e7          	jalr	998(ra) # 80003952 <iunlockput>
  ip->nlink--;
    80005574:	04a95783          	lhu	a5,74(s2)
    80005578:	37fd                	addiw	a5,a5,-1
    8000557a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000557e:	854a                	mv	a0,s2
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	0a6080e7          	jalr	166(ra) # 80003626 <iupdate>
  iunlockput(ip);
    80005588:	854a                	mv	a0,s2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	3c8080e7          	jalr	968(ra) # 80003952 <iunlockput>
  end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	bb0080e7          	jalr	-1104(ra) # 80004142 <end_op>
  return 0;
    8000559a:	4501                	li	a0,0
    8000559c:	a84d                	j	8000564e <sys_unlink+0x1c4>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	ba4080e7          	jalr	-1116(ra) # 80004142 <end_op>
    return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	a05d                	j	8000564e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055aa:	00003517          	auipc	a0,0x3
    800055ae:	31e50513          	addi	a0,a0,798 # 800088c8 <syscalls+0x2e0>
    800055b2:	ffffb097          	auipc	ra,0xffffb
    800055b6:	f8c080e7          	jalr	-116(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ba:	04c92703          	lw	a4,76(s2)
    800055be:	02000793          	li	a5,32
    800055c2:	f6e7f9e3          	bgeu	a5,a4,80005534 <sys_unlink+0xaa>
    800055c6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ca:	4741                	li	a4,16
    800055cc:	86ce                	mv	a3,s3
    800055ce:	f1840613          	addi	a2,s0,-232
    800055d2:	4581                	li	a1,0
    800055d4:	854a                	mv	a0,s2
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	3ce080e7          	jalr	974(ra) # 800039a4 <readi>
    800055de:	47c1                	li	a5,16
    800055e0:	00f51b63          	bne	a0,a5,800055f6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055e4:	f1845783          	lhu	a5,-232(s0)
    800055e8:	e7a1                	bnez	a5,80005630 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ea:	29c1                	addiw	s3,s3,16
    800055ec:	04c92783          	lw	a5,76(s2)
    800055f0:	fcf9ede3          	bltu	s3,a5,800055ca <sys_unlink+0x140>
    800055f4:	b781                	j	80005534 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055f6:	00003517          	auipc	a0,0x3
    800055fa:	2ea50513          	addi	a0,a0,746 # 800088e0 <syscalls+0x2f8>
    800055fe:	ffffb097          	auipc	ra,0xffffb
    80005602:	f40080e7          	jalr	-192(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005606:	00003517          	auipc	a0,0x3
    8000560a:	2f250513          	addi	a0,a0,754 # 800088f8 <syscalls+0x310>
    8000560e:	ffffb097          	auipc	ra,0xffffb
    80005612:	f30080e7          	jalr	-208(ra) # 8000053e <panic>
    dp->nlink--;
    80005616:	04a4d783          	lhu	a5,74(s1)
    8000561a:	37fd                	addiw	a5,a5,-1
    8000561c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	004080e7          	jalr	4(ra) # 80003626 <iupdate>
    8000562a:	b781                	j	8000556a <sys_unlink+0xe0>
    return -1;
    8000562c:	557d                	li	a0,-1
    8000562e:	a005                	j	8000564e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005630:	854a                	mv	a0,s2
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	320080e7          	jalr	800(ra) # 80003952 <iunlockput>
  iunlockput(dp);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	316080e7          	jalr	790(ra) # 80003952 <iunlockput>
  end_op();
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	afe080e7          	jalr	-1282(ra) # 80004142 <end_op>
  return -1;
    8000564c:	557d                	li	a0,-1
}
    8000564e:	70ae                	ld	ra,232(sp)
    80005650:	740e                	ld	s0,224(sp)
    80005652:	64ee                	ld	s1,216(sp)
    80005654:	694e                	ld	s2,208(sp)
    80005656:	69ae                	ld	s3,200(sp)
    80005658:	616d                	addi	sp,sp,240
    8000565a:	8082                	ret

000000008000565c <sys_open>:

uint64
sys_open(void)
{
    8000565c:	7131                	addi	sp,sp,-192
    8000565e:	fd06                	sd	ra,184(sp)
    80005660:	f922                	sd	s0,176(sp)
    80005662:	f526                	sd	s1,168(sp)
    80005664:	f14a                	sd	s2,160(sp)
    80005666:	ed4e                	sd	s3,152(sp)
    80005668:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000566a:	08000613          	li	a2,128
    8000566e:	f5040593          	addi	a1,s0,-176
    80005672:	4501                	li	a0,0
    80005674:	ffffd097          	auipc	ra,0xffffd
    80005678:	54e080e7          	jalr	1358(ra) # 80002bc2 <argstr>
    return -1;
    8000567c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000567e:	0c054163          	bltz	a0,80005740 <sys_open+0xe4>
    80005682:	f4c40593          	addi	a1,s0,-180
    80005686:	4505                	li	a0,1
    80005688:	ffffd097          	auipc	ra,0xffffd
    8000568c:	4f6080e7          	jalr	1270(ra) # 80002b7e <argint>
    80005690:	0a054863          	bltz	a0,80005740 <sys_open+0xe4>

  begin_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	a2e080e7          	jalr	-1490(ra) # 800040c2 <begin_op>

  if(omode & O_CREATE){
    8000569c:	f4c42783          	lw	a5,-180(s0)
    800056a0:	2007f793          	andi	a5,a5,512
    800056a4:	cbdd                	beqz	a5,8000575a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056a6:	4681                	li	a3,0
    800056a8:	4601                	li	a2,0
    800056aa:	4589                	li	a1,2
    800056ac:	f5040513          	addi	a0,s0,-176
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	972080e7          	jalr	-1678(ra) # 80005022 <create>
    800056b8:	892a                	mv	s2,a0
    if(ip == 0){
    800056ba:	c959                	beqz	a0,80005750 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056bc:	04491703          	lh	a4,68(s2)
    800056c0:	478d                	li	a5,3
    800056c2:	00f71763          	bne	a4,a5,800056d0 <sys_open+0x74>
    800056c6:	04695703          	lhu	a4,70(s2)
    800056ca:	47a5                	li	a5,9
    800056cc:	0ce7ec63          	bltu	a5,a4,800057a4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	e02080e7          	jalr	-510(ra) # 800044d2 <filealloc>
    800056d8:	89aa                	mv	s3,a0
    800056da:	10050263          	beqz	a0,800057de <sys_open+0x182>
    800056de:	00000097          	auipc	ra,0x0
    800056e2:	902080e7          	jalr	-1790(ra) # 80004fe0 <fdalloc>
    800056e6:	84aa                	mv	s1,a0
    800056e8:	0e054663          	bltz	a0,800057d4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ec:	04491703          	lh	a4,68(s2)
    800056f0:	478d                	li	a5,3
    800056f2:	0cf70463          	beq	a4,a5,800057ba <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056f6:	4789                	li	a5,2
    800056f8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056fc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005700:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005704:	f4c42783          	lw	a5,-180(s0)
    80005708:	0017c713          	xori	a4,a5,1
    8000570c:	8b05                	andi	a4,a4,1
    8000570e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005712:	0037f713          	andi	a4,a5,3
    80005716:	00e03733          	snez	a4,a4
    8000571a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000571e:	4007f793          	andi	a5,a5,1024
    80005722:	c791                	beqz	a5,8000572e <sys_open+0xd2>
    80005724:	04491703          	lh	a4,68(s2)
    80005728:	4789                	li	a5,2
    8000572a:	08f70f63          	beq	a4,a5,800057c8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	082080e7          	jalr	130(ra) # 800037b2 <iunlock>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	a0a080e7          	jalr	-1526(ra) # 80004142 <end_op>

  return fd;
}
    80005740:	8526                	mv	a0,s1
    80005742:	70ea                	ld	ra,184(sp)
    80005744:	744a                	ld	s0,176(sp)
    80005746:	74aa                	ld	s1,168(sp)
    80005748:	790a                	ld	s2,160(sp)
    8000574a:	69ea                	ld	s3,152(sp)
    8000574c:	6129                	addi	sp,sp,192
    8000574e:	8082                	ret
      end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	9f2080e7          	jalr	-1550(ra) # 80004142 <end_op>
      return -1;
    80005758:	b7e5                	j	80005740 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000575a:	f5040513          	addi	a0,s0,-176
    8000575e:	ffffe097          	auipc	ra,0xffffe
    80005762:	748080e7          	jalr	1864(ra) # 80003ea6 <namei>
    80005766:	892a                	mv	s2,a0
    80005768:	c905                	beqz	a0,80005798 <sys_open+0x13c>
    ilock(ip);
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	f86080e7          	jalr	-122(ra) # 800036f0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005772:	04491703          	lh	a4,68(s2)
    80005776:	4785                	li	a5,1
    80005778:	f4f712e3          	bne	a4,a5,800056bc <sys_open+0x60>
    8000577c:	f4c42783          	lw	a5,-180(s0)
    80005780:	dba1                	beqz	a5,800056d0 <sys_open+0x74>
      iunlockput(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	1ce080e7          	jalr	462(ra) # 80003952 <iunlockput>
      end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9b6080e7          	jalr	-1610(ra) # 80004142 <end_op>
      return -1;
    80005794:	54fd                	li	s1,-1
    80005796:	b76d                	j	80005740 <sys_open+0xe4>
      end_op();
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	9aa080e7          	jalr	-1622(ra) # 80004142 <end_op>
      return -1;
    800057a0:	54fd                	li	s1,-1
    800057a2:	bf79                	j	80005740 <sys_open+0xe4>
    iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	1ac080e7          	jalr	428(ra) # 80003952 <iunlockput>
    end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	994080e7          	jalr	-1644(ra) # 80004142 <end_op>
    return -1;
    800057b6:	54fd                	li	s1,-1
    800057b8:	b761                	j	80005740 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057ba:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057be:	04691783          	lh	a5,70(s2)
    800057c2:	02f99223          	sh	a5,36(s3)
    800057c6:	bf2d                	j	80005700 <sys_open+0xa4>
    itrunc(ip);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	034080e7          	jalr	52(ra) # 800037fe <itrunc>
    800057d2:	bfb1                	j	8000572e <sys_open+0xd2>
      fileclose(f);
    800057d4:	854e                	mv	a0,s3
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	db8080e7          	jalr	-584(ra) # 8000458e <fileclose>
    iunlockput(ip);
    800057de:	854a                	mv	a0,s2
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	172080e7          	jalr	370(ra) # 80003952 <iunlockput>
    end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	95a080e7          	jalr	-1702(ra) # 80004142 <end_op>
    return -1;
    800057f0:	54fd                	li	s1,-1
    800057f2:	b7b9                	j	80005740 <sys_open+0xe4>

00000000800057f4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057f4:	7175                	addi	sp,sp,-144
    800057f6:	e506                	sd	ra,136(sp)
    800057f8:	e122                	sd	s0,128(sp)
    800057fa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	8c6080e7          	jalr	-1850(ra) # 800040c2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005804:	08000613          	li	a2,128
    80005808:	f7040593          	addi	a1,s0,-144
    8000580c:	4501                	li	a0,0
    8000580e:	ffffd097          	auipc	ra,0xffffd
    80005812:	3b4080e7          	jalr	948(ra) # 80002bc2 <argstr>
    80005816:	02054963          	bltz	a0,80005848 <sys_mkdir+0x54>
    8000581a:	4681                	li	a3,0
    8000581c:	4601                	li	a2,0
    8000581e:	4585                	li	a1,1
    80005820:	f7040513          	addi	a0,s0,-144
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	7fe080e7          	jalr	2046(ra) # 80005022 <create>
    8000582c:	cd11                	beqz	a0,80005848 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	124080e7          	jalr	292(ra) # 80003952 <iunlockput>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	90c080e7          	jalr	-1780(ra) # 80004142 <end_op>
  return 0;
    8000583e:	4501                	li	a0,0
}
    80005840:	60aa                	ld	ra,136(sp)
    80005842:	640a                	ld	s0,128(sp)
    80005844:	6149                	addi	sp,sp,144
    80005846:	8082                	ret
    end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	8fa080e7          	jalr	-1798(ra) # 80004142 <end_op>
    return -1;
    80005850:	557d                	li	a0,-1
    80005852:	b7fd                	j	80005840 <sys_mkdir+0x4c>

0000000080005854 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005854:	7135                	addi	sp,sp,-160
    80005856:	ed06                	sd	ra,152(sp)
    80005858:	e922                	sd	s0,144(sp)
    8000585a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	866080e7          	jalr	-1946(ra) # 800040c2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005864:	08000613          	li	a2,128
    80005868:	f7040593          	addi	a1,s0,-144
    8000586c:	4501                	li	a0,0
    8000586e:	ffffd097          	auipc	ra,0xffffd
    80005872:	354080e7          	jalr	852(ra) # 80002bc2 <argstr>
    80005876:	04054a63          	bltz	a0,800058ca <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000587a:	f6c40593          	addi	a1,s0,-148
    8000587e:	4505                	li	a0,1
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	2fe080e7          	jalr	766(ra) # 80002b7e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005888:	04054163          	bltz	a0,800058ca <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000588c:	f6840593          	addi	a1,s0,-152
    80005890:	4509                	li	a0,2
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	2ec080e7          	jalr	748(ra) # 80002b7e <argint>
     argint(1, &major) < 0 ||
    8000589a:	02054863          	bltz	a0,800058ca <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000589e:	f6841683          	lh	a3,-152(s0)
    800058a2:	f6c41603          	lh	a2,-148(s0)
    800058a6:	458d                	li	a1,3
    800058a8:	f7040513          	addi	a0,s0,-144
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	776080e7          	jalr	1910(ra) # 80005022 <create>
     argint(2, &minor) < 0 ||
    800058b4:	c919                	beqz	a0,800058ca <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	09c080e7          	jalr	156(ra) # 80003952 <iunlockput>
  end_op();
    800058be:	fffff097          	auipc	ra,0xfffff
    800058c2:	884080e7          	jalr	-1916(ra) # 80004142 <end_op>
  return 0;
    800058c6:	4501                	li	a0,0
    800058c8:	a031                	j	800058d4 <sys_mknod+0x80>
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	878080e7          	jalr	-1928(ra) # 80004142 <end_op>
    return -1;
    800058d2:	557d                	li	a0,-1
}
    800058d4:	60ea                	ld	ra,152(sp)
    800058d6:	644a                	ld	s0,144(sp)
    800058d8:	610d                	addi	sp,sp,160
    800058da:	8082                	ret

00000000800058dc <sys_chdir>:

uint64
sys_chdir(void)
{
    800058dc:	7135                	addi	sp,sp,-160
    800058de:	ed06                	sd	ra,152(sp)
    800058e0:	e922                	sd	s0,144(sp)
    800058e2:	e526                	sd	s1,136(sp)
    800058e4:	e14a                	sd	s2,128(sp)
    800058e6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058e8:	ffffc097          	auipc	ra,0xffffc
    800058ec:	1c6080e7          	jalr	454(ra) # 80001aae <myproc>
    800058f0:	892a                	mv	s2,a0
  
  begin_op();
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	7d0080e7          	jalr	2000(ra) # 800040c2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058fa:	08000613          	li	a2,128
    800058fe:	f6040593          	addi	a1,s0,-160
    80005902:	4501                	li	a0,0
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	2be080e7          	jalr	702(ra) # 80002bc2 <argstr>
    8000590c:	04054b63          	bltz	a0,80005962 <sys_chdir+0x86>
    80005910:	f6040513          	addi	a0,s0,-160
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	592080e7          	jalr	1426(ra) # 80003ea6 <namei>
    8000591c:	84aa                	mv	s1,a0
    8000591e:	c131                	beqz	a0,80005962 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	dd0080e7          	jalr	-560(ra) # 800036f0 <ilock>
  if(ip->type != T_DIR){
    80005928:	04449703          	lh	a4,68(s1)
    8000592c:	4785                	li	a5,1
    8000592e:	04f71063          	bne	a4,a5,8000596e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005932:	8526                	mv	a0,s1
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	e7e080e7          	jalr	-386(ra) # 800037b2 <iunlock>
  iput(p->cwd);
    8000593c:	15093503          	ld	a0,336(s2)
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	f6a080e7          	jalr	-150(ra) # 800038aa <iput>
  end_op();
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	7fa080e7          	jalr	2042(ra) # 80004142 <end_op>
  p->cwd = ip;
    80005950:	14993823          	sd	s1,336(s2)
  return 0;
    80005954:	4501                	li	a0,0
}
    80005956:	60ea                	ld	ra,152(sp)
    80005958:	644a                	ld	s0,144(sp)
    8000595a:	64aa                	ld	s1,136(sp)
    8000595c:	690a                	ld	s2,128(sp)
    8000595e:	610d                	addi	sp,sp,160
    80005960:	8082                	ret
    end_op();
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	7e0080e7          	jalr	2016(ra) # 80004142 <end_op>
    return -1;
    8000596a:	557d                	li	a0,-1
    8000596c:	b7ed                	j	80005956 <sys_chdir+0x7a>
    iunlockput(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	fe2080e7          	jalr	-30(ra) # 80003952 <iunlockput>
    end_op();
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	7ca080e7          	jalr	1994(ra) # 80004142 <end_op>
    return -1;
    80005980:	557d                	li	a0,-1
    80005982:	bfd1                	j	80005956 <sys_chdir+0x7a>

0000000080005984 <sys_exec>:

uint64
sys_exec(void)
{
    80005984:	7145                	addi	sp,sp,-464
    80005986:	e786                	sd	ra,456(sp)
    80005988:	e3a2                	sd	s0,448(sp)
    8000598a:	ff26                	sd	s1,440(sp)
    8000598c:	fb4a                	sd	s2,432(sp)
    8000598e:	f74e                	sd	s3,424(sp)
    80005990:	f352                	sd	s4,416(sp)
    80005992:	ef56                	sd	s5,408(sp)
    80005994:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005996:	08000613          	li	a2,128
    8000599a:	f4040593          	addi	a1,s0,-192
    8000599e:	4501                	li	a0,0
    800059a0:	ffffd097          	auipc	ra,0xffffd
    800059a4:	222080e7          	jalr	546(ra) # 80002bc2 <argstr>
    return -1;
    800059a8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059aa:	0c054a63          	bltz	a0,80005a7e <sys_exec+0xfa>
    800059ae:	e3840593          	addi	a1,s0,-456
    800059b2:	4505                	li	a0,1
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	1ec080e7          	jalr	492(ra) # 80002ba0 <argaddr>
    800059bc:	0c054163          	bltz	a0,80005a7e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059c0:	10000613          	li	a2,256
    800059c4:	4581                	li	a1,0
    800059c6:	e4040513          	addi	a0,s0,-448
    800059ca:	ffffb097          	auipc	ra,0xffffb
    800059ce:	316080e7          	jalr	790(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059d2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059d6:	89a6                	mv	s3,s1
    800059d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059da:	02000a13          	li	s4,32
    800059de:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059e2:	00391513          	slli	a0,s2,0x3
    800059e6:	e3040593          	addi	a1,s0,-464
    800059ea:	e3843783          	ld	a5,-456(s0)
    800059ee:	953e                	add	a0,a0,a5
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	0f4080e7          	jalr	244(ra) # 80002ae4 <fetchaddr>
    800059f8:	02054a63          	bltz	a0,80005a2c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059fc:	e3043783          	ld	a5,-464(s0)
    80005a00:	c3b9                	beqz	a5,80005a46 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a02:	ffffb097          	auipc	ra,0xffffb
    80005a06:	0f2080e7          	jalr	242(ra) # 80000af4 <kalloc>
    80005a0a:	85aa                	mv	a1,a0
    80005a0c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a10:	cd11                	beqz	a0,80005a2c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a12:	6611                	lui	a2,0x4
    80005a14:	e3043503          	ld	a0,-464(s0)
    80005a18:	ffffd097          	auipc	ra,0xffffd
    80005a1c:	11e080e7          	jalr	286(ra) # 80002b36 <fetchstr>
    80005a20:	00054663          	bltz	a0,80005a2c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a24:	0905                	addi	s2,s2,1
    80005a26:	09a1                	addi	s3,s3,8
    80005a28:	fb491be3          	bne	s2,s4,800059de <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a2c:	10048913          	addi	s2,s1,256
    80005a30:	6088                	ld	a0,0(s1)
    80005a32:	c529                	beqz	a0,80005a7c <sys_exec+0xf8>
    kfree(argv[i]);
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	fc4080e7          	jalr	-60(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a3c:	04a1                	addi	s1,s1,8
    80005a3e:	ff2499e3          	bne	s1,s2,80005a30 <sys_exec+0xac>
  return -1;
    80005a42:	597d                	li	s2,-1
    80005a44:	a82d                	j	80005a7e <sys_exec+0xfa>
      argv[i] = 0;
    80005a46:	0a8e                	slli	s5,s5,0x3
    80005a48:	fc040793          	addi	a5,s0,-64
    80005a4c:	9abe                	add	s5,s5,a5
    80005a4e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a52:	e4040593          	addi	a1,s0,-448
    80005a56:	f4040513          	addi	a0,s0,-192
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	194080e7          	jalr	404(ra) # 80004bee <exec>
    80005a62:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a64:	10048993          	addi	s3,s1,256
    80005a68:	6088                	ld	a0,0(s1)
    80005a6a:	c911                	beqz	a0,80005a7e <sys_exec+0xfa>
    kfree(argv[i]);
    80005a6c:	ffffb097          	auipc	ra,0xffffb
    80005a70:	f8c080e7          	jalr	-116(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a74:	04a1                	addi	s1,s1,8
    80005a76:	ff3499e3          	bne	s1,s3,80005a68 <sys_exec+0xe4>
    80005a7a:	a011                	j	80005a7e <sys_exec+0xfa>
  return -1;
    80005a7c:	597d                	li	s2,-1
}
    80005a7e:	854a                	mv	a0,s2
    80005a80:	60be                	ld	ra,456(sp)
    80005a82:	641e                	ld	s0,448(sp)
    80005a84:	74fa                	ld	s1,440(sp)
    80005a86:	795a                	ld	s2,432(sp)
    80005a88:	79ba                	ld	s3,424(sp)
    80005a8a:	7a1a                	ld	s4,416(sp)
    80005a8c:	6afa                	ld	s5,408(sp)
    80005a8e:	6179                	addi	sp,sp,464
    80005a90:	8082                	ret

0000000080005a92 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a92:	7139                	addi	sp,sp,-64
    80005a94:	fc06                	sd	ra,56(sp)
    80005a96:	f822                	sd	s0,48(sp)
    80005a98:	f426                	sd	s1,40(sp)
    80005a9a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a9c:	ffffc097          	auipc	ra,0xffffc
    80005aa0:	012080e7          	jalr	18(ra) # 80001aae <myproc>
    80005aa4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005aa6:	fd840593          	addi	a1,s0,-40
    80005aaa:	4501                	li	a0,0
    80005aac:	ffffd097          	auipc	ra,0xffffd
    80005ab0:	0f4080e7          	jalr	244(ra) # 80002ba0 <argaddr>
    return -1;
    80005ab4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ab6:	0e054063          	bltz	a0,80005b96 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005aba:	fc840593          	addi	a1,s0,-56
    80005abe:	fd040513          	addi	a0,s0,-48
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	dfc080e7          	jalr	-516(ra) # 800048be <pipealloc>
    return -1;
    80005aca:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005acc:	0c054563          	bltz	a0,80005b96 <sys_pipe+0x104>
  fd0 = -1;
    80005ad0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ad4:	fd043503          	ld	a0,-48(s0)
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	508080e7          	jalr	1288(ra) # 80004fe0 <fdalloc>
    80005ae0:	fca42223          	sw	a0,-60(s0)
    80005ae4:	08054c63          	bltz	a0,80005b7c <sys_pipe+0xea>
    80005ae8:	fc843503          	ld	a0,-56(s0)
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	4f4080e7          	jalr	1268(ra) # 80004fe0 <fdalloc>
    80005af4:	fca42023          	sw	a0,-64(s0)
    80005af8:	06054863          	bltz	a0,80005b68 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005afc:	4691                	li	a3,4
    80005afe:	fc440613          	addi	a2,s0,-60
    80005b02:	fd843583          	ld	a1,-40(s0)
    80005b06:	68a8                	ld	a0,80(s1)
    80005b08:	ffffc097          	auipc	ra,0xffffc
    80005b0c:	c68080e7          	jalr	-920(ra) # 80001770 <copyout>
    80005b10:	02054063          	bltz	a0,80005b30 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b14:	4691                	li	a3,4
    80005b16:	fc040613          	addi	a2,s0,-64
    80005b1a:	fd843583          	ld	a1,-40(s0)
    80005b1e:	0591                	addi	a1,a1,4
    80005b20:	68a8                	ld	a0,80(s1)
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	c4e080e7          	jalr	-946(ra) # 80001770 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b2a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b2c:	06055563          	bgez	a0,80005b96 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b30:	fc442783          	lw	a5,-60(s0)
    80005b34:	07e9                	addi	a5,a5,26
    80005b36:	078e                	slli	a5,a5,0x3
    80005b38:	97a6                	add	a5,a5,s1
    80005b3a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b3e:	fc042503          	lw	a0,-64(s0)
    80005b42:	0569                	addi	a0,a0,26
    80005b44:	050e                	slli	a0,a0,0x3
    80005b46:	9526                	add	a0,a0,s1
    80005b48:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b4c:	fd043503          	ld	a0,-48(s0)
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	a3e080e7          	jalr	-1474(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005b58:	fc843503          	ld	a0,-56(s0)
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	a32080e7          	jalr	-1486(ra) # 8000458e <fileclose>
    return -1;
    80005b64:	57fd                	li	a5,-1
    80005b66:	a805                	j	80005b96 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b68:	fc442783          	lw	a5,-60(s0)
    80005b6c:	0007c863          	bltz	a5,80005b7c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b70:	01a78513          	addi	a0,a5,26
    80005b74:	050e                	slli	a0,a0,0x3
    80005b76:	9526                	add	a0,a0,s1
    80005b78:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b7c:	fd043503          	ld	a0,-48(s0)
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	a0e080e7          	jalr	-1522(ra) # 8000458e <fileclose>
    fileclose(wf);
    80005b88:	fc843503          	ld	a0,-56(s0)
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	a02080e7          	jalr	-1534(ra) # 8000458e <fileclose>
    return -1;
    80005b94:	57fd                	li	a5,-1
}
    80005b96:	853e                	mv	a0,a5
    80005b98:	70e2                	ld	ra,56(sp)
    80005b9a:	7442                	ld	s0,48(sp)
    80005b9c:	74a2                	ld	s1,40(sp)
    80005b9e:	6121                	addi	sp,sp,64
    80005ba0:	8082                	ret
	...

0000000080005bb0 <kernelvec>:
    80005bb0:	7111                	addi	sp,sp,-256
    80005bb2:	e006                	sd	ra,0(sp)
    80005bb4:	e40a                	sd	sp,8(sp)
    80005bb6:	e80e                	sd	gp,16(sp)
    80005bb8:	ec12                	sd	tp,24(sp)
    80005bba:	f016                	sd	t0,32(sp)
    80005bbc:	f41a                	sd	t1,40(sp)
    80005bbe:	f81e                	sd	t2,48(sp)
    80005bc0:	fc22                	sd	s0,56(sp)
    80005bc2:	e0a6                	sd	s1,64(sp)
    80005bc4:	e4aa                	sd	a0,72(sp)
    80005bc6:	e8ae                	sd	a1,80(sp)
    80005bc8:	ecb2                	sd	a2,88(sp)
    80005bca:	f0b6                	sd	a3,96(sp)
    80005bcc:	f4ba                	sd	a4,104(sp)
    80005bce:	f8be                	sd	a5,112(sp)
    80005bd0:	fcc2                	sd	a6,120(sp)
    80005bd2:	e146                	sd	a7,128(sp)
    80005bd4:	e54a                	sd	s2,136(sp)
    80005bd6:	e94e                	sd	s3,144(sp)
    80005bd8:	ed52                	sd	s4,152(sp)
    80005bda:	f156                	sd	s5,160(sp)
    80005bdc:	f55a                	sd	s6,168(sp)
    80005bde:	f95e                	sd	s7,176(sp)
    80005be0:	fd62                	sd	s8,184(sp)
    80005be2:	e1e6                	sd	s9,192(sp)
    80005be4:	e5ea                	sd	s10,200(sp)
    80005be6:	e9ee                	sd	s11,208(sp)
    80005be8:	edf2                	sd	t3,216(sp)
    80005bea:	f1f6                	sd	t4,224(sp)
    80005bec:	f5fa                	sd	t5,232(sp)
    80005bee:	f9fe                	sd	t6,240(sp)
    80005bf0:	dc1fc0ef          	jal	ra,800029b0 <kerneltrap>
    80005bf4:	6082                	ld	ra,0(sp)
    80005bf6:	6122                	ld	sp,8(sp)
    80005bf8:	61c2                	ld	gp,16(sp)
    80005bfa:	7282                	ld	t0,32(sp)
    80005bfc:	7322                	ld	t1,40(sp)
    80005bfe:	73c2                	ld	t2,48(sp)
    80005c00:	7462                	ld	s0,56(sp)
    80005c02:	6486                	ld	s1,64(sp)
    80005c04:	6526                	ld	a0,72(sp)
    80005c06:	65c6                	ld	a1,80(sp)
    80005c08:	6666                	ld	a2,88(sp)
    80005c0a:	7686                	ld	a3,96(sp)
    80005c0c:	7726                	ld	a4,104(sp)
    80005c0e:	77c6                	ld	a5,112(sp)
    80005c10:	7866                	ld	a6,120(sp)
    80005c12:	688a                	ld	a7,128(sp)
    80005c14:	692a                	ld	s2,136(sp)
    80005c16:	69ca                	ld	s3,144(sp)
    80005c18:	6a6a                	ld	s4,152(sp)
    80005c1a:	7a8a                	ld	s5,160(sp)
    80005c1c:	7b2a                	ld	s6,168(sp)
    80005c1e:	7bca                	ld	s7,176(sp)
    80005c20:	7c6a                	ld	s8,184(sp)
    80005c22:	6c8e                	ld	s9,192(sp)
    80005c24:	6d2e                	ld	s10,200(sp)
    80005c26:	6dce                	ld	s11,208(sp)
    80005c28:	6e6e                	ld	t3,216(sp)
    80005c2a:	7e8e                	ld	t4,224(sp)
    80005c2c:	7f2e                	ld	t5,232(sp)
    80005c2e:	7fce                	ld	t6,240(sp)
    80005c30:	6111                	addi	sp,sp,256
    80005c32:	10200073          	sret
    80005c36:	00000013          	nop
    80005c3a:	00000013          	nop
    80005c3e:	0001                	nop

0000000080005c40 <timervec>:
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	e10c                	sd	a1,0(a0)
    80005c46:	e510                	sd	a2,8(a0)
    80005c48:	e914                	sd	a3,16(a0)
    80005c4a:	6d0c                	ld	a1,24(a0)
    80005c4c:	7110                	ld	a2,32(a0)
    80005c4e:	6194                	ld	a3,0(a1)
    80005c50:	96b2                	add	a3,a3,a2
    80005c52:	e194                	sd	a3,0(a1)
    80005c54:	4589                	li	a1,2
    80005c56:	14459073          	csrw	sip,a1
    80005c5a:	6914                	ld	a3,16(a0)
    80005c5c:	6510                	ld	a2,8(a0)
    80005c5e:	610c                	ld	a1,0(a0)
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	30200073          	mret
	...

0000000080005c6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c6a:	1141                	addi	sp,sp,-16
    80005c6c:	e422                	sd	s0,8(sp)
    80005c6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c70:	0c0007b7          	lui	a5,0xc000
    80005c74:	4705                	li	a4,1
    80005c76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c78:	c3d8                	sw	a4,4(a5)
}
    80005c7a:	6422                	ld	s0,8(sp)
    80005c7c:	0141                	addi	sp,sp,16
    80005c7e:	8082                	ret

0000000080005c80 <plicinithart>:

void
plicinithart(void)
{
    80005c80:	1141                	addi	sp,sp,-16
    80005c82:	e406                	sd	ra,8(sp)
    80005c84:	e022                	sd	s0,0(sp)
    80005c86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	dfa080e7          	jalr	-518(ra) # 80001a82 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c90:	0085171b          	slliw	a4,a0,0x8
    80005c94:	0c0027b7          	lui	a5,0xc002
    80005c98:	97ba                	add	a5,a5,a4
    80005c9a:	40200713          	li	a4,1026
    80005c9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ca2:	00d5151b          	slliw	a0,a0,0xd
    80005ca6:	0c2017b7          	lui	a5,0xc201
    80005caa:	953e                	add	a0,a0,a5
    80005cac:	00052023          	sw	zero,0(a0)
}
    80005cb0:	60a2                	ld	ra,8(sp)
    80005cb2:	6402                	ld	s0,0(sp)
    80005cb4:	0141                	addi	sp,sp,16
    80005cb6:	8082                	ret

0000000080005cb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cb8:	1141                	addi	sp,sp,-16
    80005cba:	e406                	sd	ra,8(sp)
    80005cbc:	e022                	sd	s0,0(sp)
    80005cbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc0:	ffffc097          	auipc	ra,0xffffc
    80005cc4:	dc2080e7          	jalr	-574(ra) # 80001a82 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cc8:	00d5179b          	slliw	a5,a0,0xd
    80005ccc:	0c201537          	lui	a0,0xc201
    80005cd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cd2:	4148                	lw	a0,4(a0)
    80005cd4:	60a2                	ld	ra,8(sp)
    80005cd6:	6402                	ld	s0,0(sp)
    80005cd8:	0141                	addi	sp,sp,16
    80005cda:	8082                	ret

0000000080005cdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cdc:	1101                	addi	sp,sp,-32
    80005cde:	ec06                	sd	ra,24(sp)
    80005ce0:	e822                	sd	s0,16(sp)
    80005ce2:	e426                	sd	s1,8(sp)
    80005ce4:	1000                	addi	s0,sp,32
    80005ce6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	d9a080e7          	jalr	-614(ra) # 80001a82 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cf0:	00d5151b          	slliw	a0,a0,0xd
    80005cf4:	0c2017b7          	lui	a5,0xc201
    80005cf8:	97aa                	add	a5,a5,a0
    80005cfa:	c3c4                	sw	s1,4(a5)
}
    80005cfc:	60e2                	ld	ra,24(sp)
    80005cfe:	6442                	ld	s0,16(sp)
    80005d00:	64a2                	ld	s1,8(sp)
    80005d02:	6105                	addi	sp,sp,32
    80005d04:	8082                	ret

0000000080005d06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d06:	1141                	addi	sp,sp,-16
    80005d08:	e406                	sd	ra,8(sp)
    80005d0a:	e022                	sd	s0,0(sp)
    80005d0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d0e:	479d                	li	a5,7
    80005d10:	06a7c963          	blt	a5,a0,80005d82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005d14:	00022797          	auipc	a5,0x22
    80005d18:	2ec78793          	addi	a5,a5,748 # 80028000 <disk>
    80005d1c:	00a78733          	add	a4,a5,a0
    80005d20:	67a1                	lui	a5,0x8
    80005d22:	97ba                	add	a5,a5,a4
    80005d24:	0187c783          	lbu	a5,24(a5) # 8018 <_entry-0x7fff7fe8>
    80005d28:	e7ad                	bnez	a5,80005d92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d2a:	00451793          	slli	a5,a0,0x4
    80005d2e:	0002a717          	auipc	a4,0x2a
    80005d32:	2d270713          	addi	a4,a4,722 # 80030000 <disk+0x8000>
    80005d36:	6314                	ld	a3,0(a4)
    80005d38:	96be                	add	a3,a3,a5
    80005d3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005d3e:	6314                	ld	a3,0(a4)
    80005d40:	96be                	add	a3,a3,a5
    80005d42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005d46:	6314                	ld	a3,0(a4)
    80005d48:	96be                	add	a3,a3,a5
    80005d4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005d4e:	6318                	ld	a4,0(a4)
    80005d50:	97ba                	add	a5,a5,a4
    80005d52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005d56:	00022797          	auipc	a5,0x22
    80005d5a:	2aa78793          	addi	a5,a5,682 # 80028000 <disk>
    80005d5e:	97aa                	add	a5,a5,a0
    80005d60:	6521                	lui	a0,0x8
    80005d62:	953e                	add	a0,a0,a5
    80005d64:	4785                	li	a5,1
    80005d66:	00f50c23          	sb	a5,24(a0) # 8018 <_entry-0x7fff7fe8>
  wakeup(&disk.free[0]);
    80005d6a:	0002a517          	auipc	a0,0x2a
    80005d6e:	2ae50513          	addi	a0,a0,686 # 80030018 <disk+0x8018>
    80005d72:	ffffc097          	auipc	ra,0xffffc
    80005d76:	5a8080e7          	jalr	1448(ra) # 8000231a <wakeup>
}
    80005d7a:	60a2                	ld	ra,8(sp)
    80005d7c:	6402                	ld	s0,0(sp)
    80005d7e:	0141                	addi	sp,sp,16
    80005d80:	8082                	ret
    panic("free_desc 1");
    80005d82:	00003517          	auipc	a0,0x3
    80005d86:	b8650513          	addi	a0,a0,-1146 # 80008908 <syscalls+0x320>
    80005d8a:	ffffa097          	auipc	ra,0xffffa
    80005d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005d92:	00003517          	auipc	a0,0x3
    80005d96:	b8650513          	addi	a0,a0,-1146 # 80008918 <syscalls+0x330>
    80005d9a:	ffffa097          	auipc	ra,0xffffa
    80005d9e:	7a4080e7          	jalr	1956(ra) # 8000053e <panic>

0000000080005da2 <virtio_disk_init>:
{
    80005da2:	1101                	addi	sp,sp,-32
    80005da4:	ec06                	sd	ra,24(sp)
    80005da6:	e822                	sd	s0,16(sp)
    80005da8:	e426                	sd	s1,8(sp)
    80005daa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dac:	00003597          	auipc	a1,0x3
    80005db0:	b7c58593          	addi	a1,a1,-1156 # 80008928 <syscalls+0x340>
    80005db4:	0002a517          	auipc	a0,0x2a
    80005db8:	37450513          	addi	a0,a0,884 # 80030128 <disk+0x8128>
    80005dbc:	ffffb097          	auipc	ra,0xffffb
    80005dc0:	d98080e7          	jalr	-616(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dc4:	100047b7          	lui	a5,0x10004
    80005dc8:	4398                	lw	a4,0(a5)
    80005dca:	2701                	sext.w	a4,a4
    80005dcc:	747277b7          	lui	a5,0x74727
    80005dd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dd4:	0ef71163          	bne	a4,a5,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dd8:	100047b7          	lui	a5,0x10004
    80005ddc:	43dc                	lw	a5,4(a5)
    80005dde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005de0:	4705                	li	a4,1
    80005de2:	0ce79a63          	bne	a5,a4,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005de6:	100047b7          	lui	a5,0x10004
    80005dea:	479c                	lw	a5,8(a5)
    80005dec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dee:	4709                	li	a4,2
    80005df0:	0ce79363          	bne	a5,a4,80005eb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005df4:	100047b7          	lui	a5,0x10004
    80005df8:	47d8                	lw	a4,12(a5)
    80005dfa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dfc:	554d47b7          	lui	a5,0x554d4
    80005e00:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e04:	0af71963          	bne	a4,a5,80005eb6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e08:	100047b7          	lui	a5,0x10004
    80005e0c:	4705                	li	a4,1
    80005e0e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e10:	470d                	li	a4,3
    80005e12:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e14:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e16:	c7ffe737          	lui	a4,0xc7ffe
    80005e1a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fca75f>
    80005e1e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e20:	2701                	sext.w	a4,a4
    80005e22:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e24:	472d                	li	a4,11
    80005e26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e28:	473d                	li	a4,15
    80005e2a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e2c:	6711                	lui	a4,0x4
    80005e2e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e30:	0207a823          	sw	zero,48(a5) # 10004030 <_entry-0x6fffbfd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e34:	5bdc                	lw	a5,52(a5)
    80005e36:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e38:	cbcd                	beqz	a5,80005eea <virtio_disk_init+0x148>
  if(max < NUM)
    80005e3a:	471d                	li	a4,7
    80005e3c:	0af77f63          	bgeu	a4,a5,80005efa <virtio_disk_init+0x158>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e40:	100044b7          	lui	s1,0x10004
    80005e44:	47a1                	li	a5,8
    80005e46:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e48:	6621                	lui	a2,0x8
    80005e4a:	4581                	li	a1,0
    80005e4c:	00022517          	auipc	a0,0x22
    80005e50:	1b450513          	addi	a0,a0,436 # 80028000 <disk>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	e8c080e7          	jalr	-372(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e5c:	00022717          	auipc	a4,0x22
    80005e60:	1a470713          	addi	a4,a4,420 # 80028000 <disk>
    80005e64:	00e75793          	srli	a5,a4,0xe
    80005e68:	2781                	sext.w	a5,a5
    80005e6a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005e6c:	0002a797          	auipc	a5,0x2a
    80005e70:	19478793          	addi	a5,a5,404 # 80030000 <disk+0x8000>
    80005e74:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005e76:	00022717          	auipc	a4,0x22
    80005e7a:	20a70713          	addi	a4,a4,522 # 80028080 <disk+0x80>
    80005e7e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005e80:	00026717          	auipc	a4,0x26
    80005e84:	18070713          	addi	a4,a4,384 # 8002c000 <disk+0x4000>
    80005e88:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e8a:	4705                	li	a4,1
    80005e8c:	00e78c23          	sb	a4,24(a5)
    80005e90:	00e78ca3          	sb	a4,25(a5)
    80005e94:	00e78d23          	sb	a4,26(a5)
    80005e98:	00e78da3          	sb	a4,27(a5)
    80005e9c:	00e78e23          	sb	a4,28(a5)
    80005ea0:	00e78ea3          	sb	a4,29(a5)
    80005ea4:	00e78f23          	sb	a4,30(a5)
    80005ea8:	00e78fa3          	sb	a4,31(a5)
}
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	64a2                	ld	s1,8(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret
	  printf("%x %x %x %x\n",
    80005eb6:	100047b7          	lui	a5,0x10004
    80005eba:	438c                	lw	a1,0(a5)
    80005ebc:	43d0                	lw	a2,4(a5)
    80005ebe:	4794                	lw	a3,8(a5)
    80005ec0:	47d8                	lw	a4,12(a5)
    80005ec2:	2701                	sext.w	a4,a4
    80005ec4:	2681                	sext.w	a3,a3
    80005ec6:	2601                	sext.w	a2,a2
    80005ec8:	2581                	sext.w	a1,a1
    80005eca:	00003517          	auipc	a0,0x3
    80005ece:	a6e50513          	addi	a0,a0,-1426 # 80008938 <syscalls+0x350>
    80005ed2:	ffffa097          	auipc	ra,0xffffa
    80005ed6:	6b6080e7          	jalr	1718(ra) # 80000588 <printf>
    panic("could not find virtio disk");
    80005eda:	00003517          	auipc	a0,0x3
    80005ede:	a6e50513          	addi	a0,a0,-1426 # 80008948 <syscalls+0x360>
    80005ee2:	ffffa097          	auipc	ra,0xffffa
    80005ee6:	65c080e7          	jalr	1628(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005eea:	00003517          	auipc	a0,0x3
    80005eee:	a7e50513          	addi	a0,a0,-1410 # 80008968 <syscalls+0x380>
    80005ef2:	ffffa097          	auipc	ra,0xffffa
    80005ef6:	64c080e7          	jalr	1612(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005efa:	00003517          	auipc	a0,0x3
    80005efe:	a8e50513          	addi	a0,a0,-1394 # 80008988 <syscalls+0x3a0>
    80005f02:	ffffa097          	auipc	ra,0xffffa
    80005f06:	63c080e7          	jalr	1596(ra) # 8000053e <panic>

0000000080005f0a <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f0a:	7159                	addi	sp,sp,-112
    80005f0c:	f486                	sd	ra,104(sp)
    80005f0e:	f0a2                	sd	s0,96(sp)
    80005f10:	eca6                	sd	s1,88(sp)
    80005f12:	e8ca                	sd	s2,80(sp)
    80005f14:	e4ce                	sd	s3,72(sp)
    80005f16:	e0d2                	sd	s4,64(sp)
    80005f18:	fc56                	sd	s5,56(sp)
    80005f1a:	f85a                	sd	s6,48(sp)
    80005f1c:	f45e                	sd	s7,40(sp)
    80005f1e:	f062                	sd	s8,32(sp)
    80005f20:	ec66                	sd	s9,24(sp)
    80005f22:	e86a                	sd	s10,16(sp)
    80005f24:	1880                	addi	s0,sp,112
    80005f26:	892a                	mv	s2,a0
    80005f28:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f2a:	00c52c83          	lw	s9,12(a0)
    80005f2e:	001c9c9b          	slliw	s9,s9,0x1
    80005f32:	1c82                	slli	s9,s9,0x20
    80005f34:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f38:	0002a517          	auipc	a0,0x2a
    80005f3c:	1f050513          	addi	a0,a0,496 # 80030128 <disk+0x8128>
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	ca4080e7          	jalr	-860(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005f48:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f4a:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f4c:	00022b97          	auipc	s7,0x22
    80005f50:	0b4b8b93          	addi	s7,s7,180 # 80028000 <disk>
    80005f54:	6b21                	lui	s6,0x8
  for(int i = 0; i < 3; i++){
    80005f56:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f58:	8a4e                	mv	s4,s3
    80005f5a:	a051                	j	80005fde <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f5c:	00fb86b3          	add	a3,s7,a5
    80005f60:	96da                	add	a3,a3,s6
    80005f62:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f66:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f68:	0207c563          	bltz	a5,80005f92 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f6c:	2485                	addiw	s1,s1,1
    80005f6e:	0711                	addi	a4,a4,4
    80005f70:	25548463          	beq	s1,s5,800061b8 <virtio_disk_rw+0x2ae>
    idx[i] = alloc_desc();
    80005f74:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005f76:	0002a697          	auipc	a3,0x2a
    80005f7a:	0a268693          	addi	a3,a3,162 # 80030018 <disk+0x8018>
    80005f7e:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f80:	0006c583          	lbu	a1,0(a3)
    80005f84:	fde1                	bnez	a1,80005f5c <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f86:	2785                	addiw	a5,a5,1
    80005f88:	0685                	addi	a3,a3,1
    80005f8a:	ff879be3          	bne	a5,s8,80005f80 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f8e:	57fd                	li	a5,-1
    80005f90:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f92:	02905a63          	blez	s1,80005fc6 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f96:	f9042503          	lw	a0,-112(s0)
    80005f9a:	00000097          	auipc	ra,0x0
    80005f9e:	d6c080e7          	jalr	-660(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005fa2:	4785                	li	a5,1
    80005fa4:	0297d163          	bge	a5,s1,80005fc6 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fa8:	f9442503          	lw	a0,-108(s0)
    80005fac:	00000097          	auipc	ra,0x0
    80005fb0:	d5a080e7          	jalr	-678(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005fb4:	4789                	li	a5,2
    80005fb6:	0097d863          	bge	a5,s1,80005fc6 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fba:	f9842503          	lw	a0,-104(s0)
    80005fbe:	00000097          	auipc	ra,0x0
    80005fc2:	d48080e7          	jalr	-696(ra) # 80005d06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fc6:	0002a597          	auipc	a1,0x2a
    80005fca:	16258593          	addi	a1,a1,354 # 80030128 <disk+0x8128>
    80005fce:	0002a517          	auipc	a0,0x2a
    80005fd2:	04a50513          	addi	a0,a0,74 # 80030018 <disk+0x8018>
    80005fd6:	ffffc097          	auipc	ra,0xffffc
    80005fda:	1a4080e7          	jalr	420(ra) # 8000217a <sleep>
  for(int i = 0; i < 3; i++){
    80005fde:	f9040713          	addi	a4,s0,-112
    80005fe2:	84ce                	mv	s1,s3
    80005fe4:	bf41                	j	80005f74 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005fe6:	6705                	lui	a4,0x1
    80005fe8:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80005fec:	972e                	add	a4,a4,a1
    80005fee:	0712                	slli	a4,a4,0x4
    80005ff0:	00022697          	auipc	a3,0x22
    80005ff4:	01068693          	addi	a3,a3,16 # 80028000 <disk>
    80005ff8:	9736                	add	a4,a4,a3
    80005ffa:	4685                	li	a3,1
    80005ffc:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006000:	6705                	lui	a4,0x1
    80006002:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80006006:	972e                	add	a4,a4,a1
    80006008:	0712                	slli	a4,a4,0x4
    8000600a:	00022697          	auipc	a3,0x22
    8000600e:	ff668693          	addi	a3,a3,-10 # 80028000 <disk>
    80006012:	9736                	add	a4,a4,a3
    80006014:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006018:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000601c:	7661                	lui	a2,0xffff8
    8000601e:	963e                	add	a2,a2,a5
    80006020:	0002a697          	auipc	a3,0x2a
    80006024:	fe068693          	addi	a3,a3,-32 # 80030000 <disk+0x8000>
    80006028:	6298                	ld	a4,0(a3)
    8000602a:	9732                	add	a4,a4,a2
    8000602c:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000602e:	6298                	ld	a4,0(a3)
    80006030:	9732                	add	a4,a4,a2
    80006032:	4541                	li	a0,16
    80006034:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006036:	6298                	ld	a4,0(a3)
    80006038:	9732                	add	a4,a4,a2
    8000603a:	4505                	li	a0,1
    8000603c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006040:	f9442703          	lw	a4,-108(s0)
    80006044:	6288                	ld	a0,0(a3)
    80006046:	962a                	add	a2,a2,a0
    80006048:	00e61723          	sh	a4,14(a2) # ffffffffffff800e <end+0xffffffff7ffc400e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000604c:	0712                	slli	a4,a4,0x4
    8000604e:	6290                	ld	a2,0(a3)
    80006050:	963a                	add	a2,a2,a4
    80006052:	05890513          	addi	a0,s2,88
    80006056:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006058:	6294                	ld	a3,0(a3)
    8000605a:	96ba                	add	a3,a3,a4
    8000605c:	40000613          	li	a2,1024
    80006060:	c690                	sw	a2,8(a3)
  if(write)
    80006062:	140d0263          	beqz	s10,800061a6 <virtio_disk_rw+0x29c>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006066:	0002a697          	auipc	a3,0x2a
    8000606a:	f9a6b683          	ld	a3,-102(a3) # 80030000 <disk+0x8000>
    8000606e:	96ba                	add	a3,a3,a4
    80006070:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006074:	00022817          	auipc	a6,0x22
    80006078:	f8c80813          	addi	a6,a6,-116 # 80028000 <disk>
    8000607c:	0002a697          	auipc	a3,0x2a
    80006080:	f8468693          	addi	a3,a3,-124 # 80030000 <disk+0x8000>
    80006084:	6290                	ld	a2,0(a3)
    80006086:	963a                	add	a2,a2,a4
    80006088:	00c65503          	lhu	a0,12(a2)
    8000608c:	00156513          	ori	a0,a0,1
    80006090:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006094:	f9842603          	lw	a2,-104(s0)
    80006098:	6288                	ld	a0,0(a3)
    8000609a:	972a                	add	a4,a4,a0
    8000609c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060a0:	6705                	lui	a4,0x1
    800060a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800060a6:	972e                	add	a4,a4,a1
    800060a8:	0712                	slli	a4,a4,0x4
    800060aa:	9742                	add	a4,a4,a6
    800060ac:	557d                	li	a0,-1
    800060ae:	02a70823          	sb	a0,48(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060b2:	0612                	slli	a2,a2,0x4
    800060b4:	6288                	ld	a0,0(a3)
    800060b6:	9532                	add	a0,a0,a2
    800060b8:	03078793          	addi	a5,a5,48 # 10004030 <_entry-0x6fffbfd0>
    800060bc:	97c2                	add	a5,a5,a6
    800060be:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800060c0:	629c                	ld	a5,0(a3)
    800060c2:	97b2                	add	a5,a5,a2
    800060c4:	4505                	li	a0,1
    800060c6:	c788                	sw	a0,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060c8:	629c                	ld	a5,0(a3)
    800060ca:	97b2                	add	a5,a5,a2
    800060cc:	4809                	li	a6,2
    800060ce:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800060d2:	629c                	ld	a5,0(a3)
    800060d4:	963e                	add	a2,a2,a5
    800060d6:	00061723          	sh	zero,14(a2)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060da:	00a92223          	sw	a0,4(s2)
  disk.info[idx[0]].b = b;
    800060de:	03273423          	sd	s2,40(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060e2:	6698                	ld	a4,8(a3)
    800060e4:	00275783          	lhu	a5,2(a4)
    800060e8:	8b9d                	andi	a5,a5,7
    800060ea:	0786                	slli	a5,a5,0x1
    800060ec:	97ba                	add	a5,a5,a4
    800060ee:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800060f2:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060f6:	6698                	ld	a4,8(a3)
    800060f8:	00275783          	lhu	a5,2(a4)
    800060fc:	2785                	addiw	a5,a5,1
    800060fe:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006102:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006106:	100047b7          	lui	a5,0x10004
    8000610a:	0407a823          	sw	zero,80(a5) # 10004050 <_entry-0x6fffbfb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000610e:	00492703          	lw	a4,4(s2)
    80006112:	4785                	li	a5,1
    80006114:	02f71163          	bne	a4,a5,80006136 <virtio_disk_rw+0x22c>
    sleep(b, &disk.vdisk_lock);
    80006118:	0002a997          	auipc	s3,0x2a
    8000611c:	01098993          	addi	s3,s3,16 # 80030128 <disk+0x8128>
  while(b->disk == 1) {
    80006120:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006122:	85ce                	mv	a1,s3
    80006124:	854a                	mv	a0,s2
    80006126:	ffffc097          	auipc	ra,0xffffc
    8000612a:	054080e7          	jalr	84(ra) # 8000217a <sleep>
  while(b->disk == 1) {
    8000612e:	00492783          	lw	a5,4(s2)
    80006132:	fe9788e3          	beq	a5,s1,80006122 <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    80006136:	f9042903          	lw	s2,-112(s0)
    8000613a:	6785                	lui	a5,0x1
    8000613c:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    80006140:	97ca                	add	a5,a5,s2
    80006142:	0792                	slli	a5,a5,0x4
    80006144:	00022717          	auipc	a4,0x22
    80006148:	ebc70713          	addi	a4,a4,-324 # 80028000 <disk>
    8000614c:	97ba                	add	a5,a5,a4
    8000614e:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006152:	0002a997          	auipc	s3,0x2a
    80006156:	eae98993          	addi	s3,s3,-338 # 80030000 <disk+0x8000>
    8000615a:	00491713          	slli	a4,s2,0x4
    8000615e:	0009b783          	ld	a5,0(s3)
    80006162:	97ba                	add	a5,a5,a4
    80006164:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006168:	854a                	mv	a0,s2
    8000616a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	b98080e7          	jalr	-1128(ra) # 80005d06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006176:	8885                	andi	s1,s1,1
    80006178:	f0ed                	bnez	s1,8000615a <virtio_disk_rw+0x250>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000617a:	0002a517          	auipc	a0,0x2a
    8000617e:	fae50513          	addi	a0,a0,-82 # 80030128 <disk+0x8128>
    80006182:	ffffb097          	auipc	ra,0xffffb
    80006186:	b16080e7          	jalr	-1258(ra) # 80000c98 <release>
}
    8000618a:	70a6                	ld	ra,104(sp)
    8000618c:	7406                	ld	s0,96(sp)
    8000618e:	64e6                	ld	s1,88(sp)
    80006190:	6946                	ld	s2,80(sp)
    80006192:	69a6                	ld	s3,72(sp)
    80006194:	6a06                	ld	s4,64(sp)
    80006196:	7ae2                	ld	s5,56(sp)
    80006198:	7b42                	ld	s6,48(sp)
    8000619a:	7ba2                	ld	s7,40(sp)
    8000619c:	7c02                	ld	s8,32(sp)
    8000619e:	6ce2                	ld	s9,24(sp)
    800061a0:	6d42                	ld	s10,16(sp)
    800061a2:	6165                	addi	sp,sp,112
    800061a4:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061a6:	0002a697          	auipc	a3,0x2a
    800061aa:	e5a6b683          	ld	a3,-422(a3) # 80030000 <disk+0x8000>
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	4609                	li	a2,2
    800061b2:	00c69623          	sh	a2,12(a3)
    800061b6:	bd7d                	j	80006074 <virtio_disk_rw+0x16a>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061b8:	f9042583          	lw	a1,-112(s0)
    800061bc:	6785                	lui	a5,0x1
    800061be:	80078793          	addi	a5,a5,-2048 # 800 <_entry-0x7ffff800>
    800061c2:	97ae                	add	a5,a5,a1
    800061c4:	0792                	slli	a5,a5,0x4
    800061c6:	00022517          	auipc	a0,0x22
    800061ca:	ee250513          	addi	a0,a0,-286 # 800280a8 <disk+0xa8>
    800061ce:	953e                	add	a0,a0,a5
  if(write)
    800061d0:	e00d1be3          	bnez	s10,80005fe6 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800061d4:	6705                	lui	a4,0x1
    800061d6:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800061da:	972e                	add	a4,a4,a1
    800061dc:	0712                	slli	a4,a4,0x4
    800061de:	00022697          	auipc	a3,0x22
    800061e2:	e2268693          	addi	a3,a3,-478 # 80028000 <disk>
    800061e6:	9736                	add	a4,a4,a3
    800061e8:	0a072423          	sw	zero,168(a4)
    800061ec:	bd11                	j	80006000 <virtio_disk_rw+0xf6>

00000000800061ee <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061ee:	7179                	addi	sp,sp,-48
    800061f0:	f406                	sd	ra,40(sp)
    800061f2:	f022                	sd	s0,32(sp)
    800061f4:	ec26                	sd	s1,24(sp)
    800061f6:	e84a                	sd	s2,16(sp)
    800061f8:	e44e                	sd	s3,8(sp)
    800061fa:	1800                	addi	s0,sp,48
  acquire(&disk.vdisk_lock);
    800061fc:	0002a517          	auipc	a0,0x2a
    80006200:	f2c50513          	addi	a0,a0,-212 # 80030128 <disk+0x8128>
    80006204:	ffffb097          	auipc	ra,0xffffb
    80006208:	9e0080e7          	jalr	-1568(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000620c:	10004737          	lui	a4,0x10004
    80006210:	533c                	lw	a5,96(a4)
    80006212:	8b8d                	andi	a5,a5,3
    80006214:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006216:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000621a:	0002a797          	auipc	a5,0x2a
    8000621e:	de678793          	addi	a5,a5,-538 # 80030000 <disk+0x8000>
    80006222:	6b94                	ld	a3,16(a5)
    80006224:	0207d703          	lhu	a4,32(a5)
    80006228:	0026d783          	lhu	a5,2(a3)
    8000622c:	06f70363          	beq	a4,a5,80006292 <virtio_disk_intr+0xa4>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006230:	00022997          	auipc	s3,0x22
    80006234:	dd098993          	addi	s3,s3,-560 # 80028000 <disk>
    80006238:	0002a497          	auipc	s1,0x2a
    8000623c:	dc848493          	addi	s1,s1,-568 # 80030000 <disk+0x8000>

    if(disk.info[id].status != 0)
    80006240:	6905                	lui	s2,0x1
    80006242:	80090913          	addi	s2,s2,-2048 # 800 <_entry-0x7ffff800>
    __sync_synchronize();
    80006246:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000624a:	6898                	ld	a4,16(s1)
    8000624c:	0204d783          	lhu	a5,32(s1)
    80006250:	8b9d                	andi	a5,a5,7
    80006252:	078e                	slli	a5,a5,0x3
    80006254:	97ba                	add	a5,a5,a4
    80006256:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006258:	01278733          	add	a4,a5,s2
    8000625c:	0712                	slli	a4,a4,0x4
    8000625e:	974e                	add	a4,a4,s3
    80006260:	03074703          	lbu	a4,48(a4) # 10004030 <_entry-0x6fffbfd0>
    80006264:	e731                	bnez	a4,800062b0 <virtio_disk_intr+0xc2>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006266:	97ca                	add	a5,a5,s2
    80006268:	0792                	slli	a5,a5,0x4
    8000626a:	97ce                	add	a5,a5,s3
    8000626c:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    8000626e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	0a8080e7          	jalr	168(ra) # 8000231a <wakeup>

    disk.used_idx += 1;
    8000627a:	0204d783          	lhu	a5,32(s1)
    8000627e:	2785                	addiw	a5,a5,1
    80006280:	17c2                	slli	a5,a5,0x30
    80006282:	93c1                	srli	a5,a5,0x30
    80006284:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006288:	6898                	ld	a4,16(s1)
    8000628a:	00275703          	lhu	a4,2(a4)
    8000628e:	faf71ce3          	bne	a4,a5,80006246 <virtio_disk_intr+0x58>
  }

  release(&disk.vdisk_lock);
    80006292:	0002a517          	auipc	a0,0x2a
    80006296:	e9650513          	addi	a0,a0,-362 # 80030128 <disk+0x8128>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	9fe080e7          	jalr	-1538(ra) # 80000c98 <release>
}
    800062a2:	70a2                	ld	ra,40(sp)
    800062a4:	7402                	ld	s0,32(sp)
    800062a6:	64e2                	ld	s1,24(sp)
    800062a8:	6942                	ld	s2,16(sp)
    800062aa:	69a2                	ld	s3,8(sp)
    800062ac:	6145                	addi	sp,sp,48
    800062ae:	8082                	ret
      panic("virtio_disk_intr status");
    800062b0:	00002517          	auipc	a0,0x2
    800062b4:	6f850513          	addi	a0,a0,1784 # 800089a8 <syscalls+0x3c0>
    800062b8:	ffffa097          	auipc	ra,0xffffa
    800062bc:	286080e7          	jalr	646(ra) # 8000053e <panic>
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
