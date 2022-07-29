
user/_mmtrace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char **argv){
   0:	7119                	addi	sp,sp,-128
   2:	fc86                	sd	ra,120(sp)
   4:	f8a2                	sd	s0,112(sp)
   6:	f4a6                	sd	s1,104(sp)
   8:	f0ca                	sd	s2,96(sp)
   a:	0100                	addi	s0,sp,128
   c:	737d                	lui	t1,0xfffff
   e:	911a                	add	sp,sp,t1
	fprintf(2, "tracing mem\n");
  10:	00001597          	auipc	a1,0x1
  14:	80858593          	addi	a1,a1,-2040 # 818 <malloc+0xe8>
  18:	4509                	li	a0,2
  1a:	00000097          	auipc	ra,0x0
  1e:	62a080e7          	jalr	1578(ra) # 644 <fprintf>
	char ch1[4096];
	char ch2[84];
	int last = 1;
  22:	74fd                	lui	s1,0xfffff
  24:	fe040793          	addi	a5,s0,-32
  28:	00978933          	add	s2,a5,s1
  2c:	4785                	li	a5,1
  2e:	faf92223          	sw	a5,-92(s2)
	fprintf(2, "awa...");
  32:	00000597          	auipc	a1,0x0
  36:	7f658593          	addi	a1,a1,2038 # 828 <malloc+0xf8>
  3a:	4509                	li	a0,2
  3c:	00000097          	auipc	ra,0x0
  40:	608080e7          	jalr	1544(ra) # 644 <fprintf>
	mmtrace(ch1);
  44:	854a                	mv	a0,s2
  46:	00000097          	auipc	ra,0x0
  4a:	34c080e7          	jalr	844(ra) # 392 <mmtrace>
	mmtrace(ch2);
  4e:	fa848513          	addi	a0,s1,-88 # ffffffffffffefa8 <__global_pointer$+0xffffffffffffdf5f>
  52:	fe040793          	addi	a5,s0,-32
  56:	953e                	add	a0,a0,a5
  58:	00000097          	auipc	ra,0x0
  5c:	33a080e7          	jalr	826(ra) # 392 <mmtrace>
	mmtrace(&last);
  60:	fa448513          	addi	a0,s1,-92
  64:	fe040793          	addi	a5,s0,-32
  68:	953e                	add	a0,a0,a5
  6a:	00000097          	auipc	ra,0x0
  6e:	328080e7          	jalr	808(ra) # 392 <mmtrace>
	exit(0);
  72:	4501                	li	a0,0
  74:	00000097          	auipc	ra,0x0
  78:	27e080e7          	jalr	638(ra) # 2f2 <exit>

000000000000007c <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  82:	87aa                	mv	a5,a0
  84:	0585                	addi	a1,a1,1
  86:	0785                	addi	a5,a5,1
  88:	fff5c703          	lbu	a4,-1(a1)
  8c:	fee78fa3          	sb	a4,-1(a5)
  90:	fb75                	bnez	a4,84 <strcpy+0x8>
    ;
  return os;
}
  92:	6422                	ld	s0,8(sp)
  94:	0141                	addi	sp,sp,16
  96:	8082                	ret

0000000000000098 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  98:	1141                	addi	sp,sp,-16
  9a:	e422                	sd	s0,8(sp)
  9c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  9e:	00054783          	lbu	a5,0(a0)
  a2:	cb91                	beqz	a5,b6 <strcmp+0x1e>
  a4:	0005c703          	lbu	a4,0(a1)
  a8:	00f71763          	bne	a4,a5,b6 <strcmp+0x1e>
    p++, q++;
  ac:	0505                	addi	a0,a0,1
  ae:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  b0:	00054783          	lbu	a5,0(a0)
  b4:	fbe5                	bnez	a5,a4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  b6:	0005c503          	lbu	a0,0(a1)
}
  ba:	40a7853b          	subw	a0,a5,a0
  be:	6422                	ld	s0,8(sp)
  c0:	0141                	addi	sp,sp,16
  c2:	8082                	ret

00000000000000c4 <strlen>:

uint
strlen(const char *s)
{
  c4:	1141                	addi	sp,sp,-16
  c6:	e422                	sd	s0,8(sp)
  c8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  ca:	00054783          	lbu	a5,0(a0)
  ce:	cf91                	beqz	a5,ea <strlen+0x26>
  d0:	0505                	addi	a0,a0,1
  d2:	87aa                	mv	a5,a0
  d4:	4685                	li	a3,1
  d6:	9e89                	subw	a3,a3,a0
  d8:	00f6853b          	addw	a0,a3,a5
  dc:	0785                	addi	a5,a5,1
  de:	fff7c703          	lbu	a4,-1(a5)
  e2:	fb7d                	bnez	a4,d8 <strlen+0x14>
    ;
  return n;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret
  for(n = 0; s[n]; n++)
  ea:	4501                	li	a0,0
  ec:	bfe5                	j	e4 <strlen+0x20>

00000000000000ee <memset>:

void*
memset(void *dst, int c, uint n)
{
  ee:	1141                	addi	sp,sp,-16
  f0:	e422                	sd	s0,8(sp)
  f2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  f4:	ce09                	beqz	a2,10e <memset+0x20>
  f6:	87aa                	mv	a5,a0
  f8:	fff6071b          	addiw	a4,a2,-1
  fc:	1702                	slli	a4,a4,0x20
  fe:	9301                	srli	a4,a4,0x20
 100:	0705                	addi	a4,a4,1
 102:	972a                	add	a4,a4,a0
    cdst[i] = c;
 104:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 108:	0785                	addi	a5,a5,1
 10a:	fee79de3          	bne	a5,a4,104 <memset+0x16>
  }
  return dst;
}
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strchr>:

char*
strchr(const char *s, char c)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  for(; *s; s++)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cb99                	beqz	a5,134 <strchr+0x20>
    if(*s == c)
 120:	00f58763          	beq	a1,a5,12e <strchr+0x1a>
  for(; *s; s++)
 124:	0505                	addi	a0,a0,1
 126:	00054783          	lbu	a5,0(a0)
 12a:	fbfd                	bnez	a5,120 <strchr+0xc>
      return (char*)s;
  return 0;
 12c:	4501                	li	a0,0
}
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret
  return 0;
 134:	4501                	li	a0,0
 136:	bfe5                	j	12e <strchr+0x1a>

0000000000000138 <gets>:

char*
gets(char *buf, int max)
{
 138:	711d                	addi	sp,sp,-96
 13a:	ec86                	sd	ra,88(sp)
 13c:	e8a2                	sd	s0,80(sp)
 13e:	e4a6                	sd	s1,72(sp)
 140:	e0ca                	sd	s2,64(sp)
 142:	fc4e                	sd	s3,56(sp)
 144:	f852                	sd	s4,48(sp)
 146:	f456                	sd	s5,40(sp)
 148:	f05a                	sd	s6,32(sp)
 14a:	ec5e                	sd	s7,24(sp)
 14c:	1080                	addi	s0,sp,96
 14e:	8baa                	mv	s7,a0
 150:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 152:	892a                	mv	s2,a0
 154:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 156:	4aa9                	li	s5,10
 158:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 15a:	89a6                	mv	s3,s1
 15c:	2485                	addiw	s1,s1,1
 15e:	0344d863          	bge	s1,s4,18e <gets+0x56>
    cc = read(0, &c, 1);
 162:	4605                	li	a2,1
 164:	faf40593          	addi	a1,s0,-81
 168:	4501                	li	a0,0
 16a:	00000097          	auipc	ra,0x0
 16e:	1a0080e7          	jalr	416(ra) # 30a <read>
    if(cc < 1)
 172:	00a05e63          	blez	a0,18e <gets+0x56>
    buf[i++] = c;
 176:	faf44783          	lbu	a5,-81(s0)
 17a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 17e:	01578763          	beq	a5,s5,18c <gets+0x54>
 182:	0905                	addi	s2,s2,1
 184:	fd679be3          	bne	a5,s6,15a <gets+0x22>
  for(i=0; i+1 < max; ){
 188:	89a6                	mv	s3,s1
 18a:	a011                	j	18e <gets+0x56>
 18c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 18e:	99de                	add	s3,s3,s7
 190:	00098023          	sb	zero,0(s3)
  return buf;
}
 194:	855e                	mv	a0,s7
 196:	60e6                	ld	ra,88(sp)
 198:	6446                	ld	s0,80(sp)
 19a:	64a6                	ld	s1,72(sp)
 19c:	6906                	ld	s2,64(sp)
 19e:	79e2                	ld	s3,56(sp)
 1a0:	7a42                	ld	s4,48(sp)
 1a2:	7aa2                	ld	s5,40(sp)
 1a4:	7b02                	ld	s6,32(sp)
 1a6:	6be2                	ld	s7,24(sp)
 1a8:	6125                	addi	sp,sp,96
 1aa:	8082                	ret

00000000000001ac <stat>:

int
stat(const char *n, struct stat *st)
{
 1ac:	1101                	addi	sp,sp,-32
 1ae:	ec06                	sd	ra,24(sp)
 1b0:	e822                	sd	s0,16(sp)
 1b2:	e426                	sd	s1,8(sp)
 1b4:	e04a                	sd	s2,0(sp)
 1b6:	1000                	addi	s0,sp,32
 1b8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1ba:	4581                	li	a1,0
 1bc:	00000097          	auipc	ra,0x0
 1c0:	176080e7          	jalr	374(ra) # 332 <open>
  if(fd < 0)
 1c4:	02054563          	bltz	a0,1ee <stat+0x42>
 1c8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ca:	85ca                	mv	a1,s2
 1cc:	00000097          	auipc	ra,0x0
 1d0:	17e080e7          	jalr	382(ra) # 34a <fstat>
 1d4:	892a                	mv	s2,a0
  close(fd);
 1d6:	8526                	mv	a0,s1
 1d8:	00000097          	auipc	ra,0x0
 1dc:	142080e7          	jalr	322(ra) # 31a <close>
  return r;
}
 1e0:	854a                	mv	a0,s2
 1e2:	60e2                	ld	ra,24(sp)
 1e4:	6442                	ld	s0,16(sp)
 1e6:	64a2                	ld	s1,8(sp)
 1e8:	6902                	ld	s2,0(sp)
 1ea:	6105                	addi	sp,sp,32
 1ec:	8082                	ret
    return -1;
 1ee:	597d                	li	s2,-1
 1f0:	bfc5                	j	1e0 <stat+0x34>

00000000000001f2 <atoi>:

int
atoi(const char *s)
{
 1f2:	1141                	addi	sp,sp,-16
 1f4:	e422                	sd	s0,8(sp)
 1f6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1f8:	00054603          	lbu	a2,0(a0)
 1fc:	fd06079b          	addiw	a5,a2,-48
 200:	0ff7f793          	andi	a5,a5,255
 204:	4725                	li	a4,9
 206:	02f76963          	bltu	a4,a5,238 <atoi+0x46>
 20a:	86aa                	mv	a3,a0
  n = 0;
 20c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 20e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 210:	0685                	addi	a3,a3,1
 212:	0025179b          	slliw	a5,a0,0x2
 216:	9fa9                	addw	a5,a5,a0
 218:	0017979b          	slliw	a5,a5,0x1
 21c:	9fb1                	addw	a5,a5,a2
 21e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 222:	0006c603          	lbu	a2,0(a3)
 226:	fd06071b          	addiw	a4,a2,-48
 22a:	0ff77713          	andi	a4,a4,255
 22e:	fee5f1e3          	bgeu	a1,a4,210 <atoi+0x1e>
  return n;
}
 232:	6422                	ld	s0,8(sp)
 234:	0141                	addi	sp,sp,16
 236:	8082                	ret
  n = 0;
 238:	4501                	li	a0,0
 23a:	bfe5                	j	232 <atoi+0x40>

000000000000023c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 23c:	1141                	addi	sp,sp,-16
 23e:	e422                	sd	s0,8(sp)
 240:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 242:	02b57663          	bgeu	a0,a1,26e <memmove+0x32>
    while(n-- > 0)
 246:	02c05163          	blez	a2,268 <memmove+0x2c>
 24a:	fff6079b          	addiw	a5,a2,-1
 24e:	1782                	slli	a5,a5,0x20
 250:	9381                	srli	a5,a5,0x20
 252:	0785                	addi	a5,a5,1
 254:	97aa                	add	a5,a5,a0
  dst = vdst;
 256:	872a                	mv	a4,a0
      *dst++ = *src++;
 258:	0585                	addi	a1,a1,1
 25a:	0705                	addi	a4,a4,1
 25c:	fff5c683          	lbu	a3,-1(a1)
 260:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 264:	fee79ae3          	bne	a5,a4,258 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 268:	6422                	ld	s0,8(sp)
 26a:	0141                	addi	sp,sp,16
 26c:	8082                	ret
    dst += n;
 26e:	00c50733          	add	a4,a0,a2
    src += n;
 272:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 274:	fec05ae3          	blez	a2,268 <memmove+0x2c>
 278:	fff6079b          	addiw	a5,a2,-1
 27c:	1782                	slli	a5,a5,0x20
 27e:	9381                	srli	a5,a5,0x20
 280:	fff7c793          	not	a5,a5
 284:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 286:	15fd                	addi	a1,a1,-1
 288:	177d                	addi	a4,a4,-1
 28a:	0005c683          	lbu	a3,0(a1)
 28e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 292:	fee79ae3          	bne	a5,a4,286 <memmove+0x4a>
 296:	bfc9                	j	268 <memmove+0x2c>

0000000000000298 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 29e:	ca05                	beqz	a2,2ce <memcmp+0x36>
 2a0:	fff6069b          	addiw	a3,a2,-1
 2a4:	1682                	slli	a3,a3,0x20
 2a6:	9281                	srli	a3,a3,0x20
 2a8:	0685                	addi	a3,a3,1
 2aa:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ac:	00054783          	lbu	a5,0(a0)
 2b0:	0005c703          	lbu	a4,0(a1)
 2b4:	00e79863          	bne	a5,a4,2c4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2b8:	0505                	addi	a0,a0,1
    p2++;
 2ba:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2bc:	fed518e3          	bne	a0,a3,2ac <memcmp+0x14>
  }
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	a019                	j	2c8 <memcmp+0x30>
      return *p1 - *p2;
 2c4:	40e7853b          	subw	a0,a5,a4
}
 2c8:	6422                	ld	s0,8(sp)
 2ca:	0141                	addi	sp,sp,16
 2cc:	8082                	ret
  return 0;
 2ce:	4501                	li	a0,0
 2d0:	bfe5                	j	2c8 <memcmp+0x30>

00000000000002d2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e406                	sd	ra,8(sp)
 2d6:	e022                	sd	s0,0(sp)
 2d8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2da:	00000097          	auipc	ra,0x0
 2de:	f62080e7          	jalr	-158(ra) # 23c <memmove>
}
 2e2:	60a2                	ld	ra,8(sp)
 2e4:	6402                	ld	s0,0(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret

00000000000002ea <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2ea:	4885                	li	a7,1
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2f2:	4889                	li	a7,2
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <wait>:
.global wait
wait:
 li a7, SYS_wait
 2fa:	488d                	li	a7,3
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 302:	4891                	li	a7,4
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <read>:
.global read
read:
 li a7, SYS_read
 30a:	4895                	li	a7,5
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <write>:
.global write
write:
 li a7, SYS_write
 312:	48c1                	li	a7,16
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <close>:
.global close
close:
 li a7, SYS_close
 31a:	48d5                	li	a7,21
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <kill>:
.global kill
kill:
 li a7, SYS_kill
 322:	4899                	li	a7,6
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <exec>:
.global exec
exec:
 li a7, SYS_exec
 32a:	489d                	li	a7,7
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <open>:
.global open
open:
 li a7, SYS_open
 332:	48bd                	li	a7,15
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 33a:	48c5                	li	a7,17
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 342:	48c9                	li	a7,18
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 34a:	48a1                	li	a7,8
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <link>:
.global link
link:
 li a7, SYS_link
 352:	48cd                	li	a7,19
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 35a:	48d1                	li	a7,20
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 362:	48a5                	li	a7,9
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <dup>:
.global dup
dup:
 li a7, SYS_dup
 36a:	48a9                	li	a7,10
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 372:	48ad                	li	a7,11
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 37a:	48b1                	li	a7,12
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 382:	48b5                	li	a7,13
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 38a:	48b9                	li	a7,14
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <mmtrace>:
.global mmtrace
mmtrace:
 li a7, SYS_mmtrace
 392:	48d9                	li	a7,22
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 39a:	1101                	addi	sp,sp,-32
 39c:	ec06                	sd	ra,24(sp)
 39e:	e822                	sd	s0,16(sp)
 3a0:	1000                	addi	s0,sp,32
 3a2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3a6:	4605                	li	a2,1
 3a8:	fef40593          	addi	a1,s0,-17
 3ac:	00000097          	auipc	ra,0x0
 3b0:	f66080e7          	jalr	-154(ra) # 312 <write>
}
 3b4:	60e2                	ld	ra,24(sp)
 3b6:	6442                	ld	s0,16(sp)
 3b8:	6105                	addi	sp,sp,32
 3ba:	8082                	ret

00000000000003bc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3bc:	7139                	addi	sp,sp,-64
 3be:	fc06                	sd	ra,56(sp)
 3c0:	f822                	sd	s0,48(sp)
 3c2:	f426                	sd	s1,40(sp)
 3c4:	f04a                	sd	s2,32(sp)
 3c6:	ec4e                	sd	s3,24(sp)
 3c8:	0080                	addi	s0,sp,64
 3ca:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3cc:	c299                	beqz	a3,3d2 <printint+0x16>
 3ce:	0805c863          	bltz	a1,45e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3d2:	2581                	sext.w	a1,a1
  neg = 0;
 3d4:	4881                	li	a7,0
 3d6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3da:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3dc:	2601                	sext.w	a2,a2
 3de:	00000517          	auipc	a0,0x0
 3e2:	45a50513          	addi	a0,a0,1114 # 838 <digits>
 3e6:	883a                	mv	a6,a4
 3e8:	2705                	addiw	a4,a4,1
 3ea:	02c5f7bb          	remuw	a5,a1,a2
 3ee:	1782                	slli	a5,a5,0x20
 3f0:	9381                	srli	a5,a5,0x20
 3f2:	97aa                	add	a5,a5,a0
 3f4:	0007c783          	lbu	a5,0(a5)
 3f8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3fc:	0005879b          	sext.w	a5,a1
 400:	02c5d5bb          	divuw	a1,a1,a2
 404:	0685                	addi	a3,a3,1
 406:	fec7f0e3          	bgeu	a5,a2,3e6 <printint+0x2a>
  if(neg)
 40a:	00088b63          	beqz	a7,420 <printint+0x64>
    buf[i++] = '-';
 40e:	fd040793          	addi	a5,s0,-48
 412:	973e                	add	a4,a4,a5
 414:	02d00793          	li	a5,45
 418:	fef70823          	sb	a5,-16(a4)
 41c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 420:	02e05863          	blez	a4,450 <printint+0x94>
 424:	fc040793          	addi	a5,s0,-64
 428:	00e78933          	add	s2,a5,a4
 42c:	fff78993          	addi	s3,a5,-1
 430:	99ba                	add	s3,s3,a4
 432:	377d                	addiw	a4,a4,-1
 434:	1702                	slli	a4,a4,0x20
 436:	9301                	srli	a4,a4,0x20
 438:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 43c:	fff94583          	lbu	a1,-1(s2)
 440:	8526                	mv	a0,s1
 442:	00000097          	auipc	ra,0x0
 446:	f58080e7          	jalr	-168(ra) # 39a <putc>
  while(--i >= 0)
 44a:	197d                	addi	s2,s2,-1
 44c:	ff3918e3          	bne	s2,s3,43c <printint+0x80>
}
 450:	70e2                	ld	ra,56(sp)
 452:	7442                	ld	s0,48(sp)
 454:	74a2                	ld	s1,40(sp)
 456:	7902                	ld	s2,32(sp)
 458:	69e2                	ld	s3,24(sp)
 45a:	6121                	addi	sp,sp,64
 45c:	8082                	ret
    x = -xx;
 45e:	40b005bb          	negw	a1,a1
    neg = 1;
 462:	4885                	li	a7,1
    x = -xx;
 464:	bf8d                	j	3d6 <printint+0x1a>

0000000000000466 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 466:	7119                	addi	sp,sp,-128
 468:	fc86                	sd	ra,120(sp)
 46a:	f8a2                	sd	s0,112(sp)
 46c:	f4a6                	sd	s1,104(sp)
 46e:	f0ca                	sd	s2,96(sp)
 470:	ecce                	sd	s3,88(sp)
 472:	e8d2                	sd	s4,80(sp)
 474:	e4d6                	sd	s5,72(sp)
 476:	e0da                	sd	s6,64(sp)
 478:	fc5e                	sd	s7,56(sp)
 47a:	f862                	sd	s8,48(sp)
 47c:	f466                	sd	s9,40(sp)
 47e:	f06a                	sd	s10,32(sp)
 480:	ec6e                	sd	s11,24(sp)
 482:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 484:	0005c903          	lbu	s2,0(a1)
 488:	18090f63          	beqz	s2,626 <vprintf+0x1c0>
 48c:	8aaa                	mv	s5,a0
 48e:	8b32                	mv	s6,a2
 490:	00158493          	addi	s1,a1,1
  state = 0;
 494:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 496:	02500a13          	li	s4,37
      if(c == 'd'){
 49a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 49e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4a2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4a6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4aa:	00000b97          	auipc	s7,0x0
 4ae:	38eb8b93          	addi	s7,s7,910 # 838 <digits>
 4b2:	a839                	j	4d0 <vprintf+0x6a>
        putc(fd, c);
 4b4:	85ca                	mv	a1,s2
 4b6:	8556                	mv	a0,s5
 4b8:	00000097          	auipc	ra,0x0
 4bc:	ee2080e7          	jalr	-286(ra) # 39a <putc>
 4c0:	a019                	j	4c6 <vprintf+0x60>
    } else if(state == '%'){
 4c2:	01498f63          	beq	s3,s4,4e0 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4c6:	0485                	addi	s1,s1,1
 4c8:	fff4c903          	lbu	s2,-1(s1)
 4cc:	14090d63          	beqz	s2,626 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4d0:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4d4:	fe0997e3          	bnez	s3,4c2 <vprintf+0x5c>
      if(c == '%'){
 4d8:	fd479ee3          	bne	a5,s4,4b4 <vprintf+0x4e>
        state = '%';
 4dc:	89be                	mv	s3,a5
 4de:	b7e5                	j	4c6 <vprintf+0x60>
      if(c == 'd'){
 4e0:	05878063          	beq	a5,s8,520 <vprintf+0xba>
      } else if(c == 'l') {
 4e4:	05978c63          	beq	a5,s9,53c <vprintf+0xd6>
      } else if(c == 'x') {
 4e8:	07a78863          	beq	a5,s10,558 <vprintf+0xf2>
      } else if(c == 'p') {
 4ec:	09b78463          	beq	a5,s11,574 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4f0:	07300713          	li	a4,115
 4f4:	0ce78663          	beq	a5,a4,5c0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4f8:	06300713          	li	a4,99
 4fc:	0ee78e63          	beq	a5,a4,5f8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 500:	11478863          	beq	a5,s4,610 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 504:	85d2                	mv	a1,s4
 506:	8556                	mv	a0,s5
 508:	00000097          	auipc	ra,0x0
 50c:	e92080e7          	jalr	-366(ra) # 39a <putc>
        putc(fd, c);
 510:	85ca                	mv	a1,s2
 512:	8556                	mv	a0,s5
 514:	00000097          	auipc	ra,0x0
 518:	e86080e7          	jalr	-378(ra) # 39a <putc>
      }
      state = 0;
 51c:	4981                	li	s3,0
 51e:	b765                	j	4c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 520:	008b0913          	addi	s2,s6,8
 524:	4685                	li	a3,1
 526:	4629                	li	a2,10
 528:	000b2583          	lw	a1,0(s6)
 52c:	8556                	mv	a0,s5
 52e:	00000097          	auipc	ra,0x0
 532:	e8e080e7          	jalr	-370(ra) # 3bc <printint>
 536:	8b4a                	mv	s6,s2
      state = 0;
 538:	4981                	li	s3,0
 53a:	b771                	j	4c6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 53c:	008b0913          	addi	s2,s6,8
 540:	4681                	li	a3,0
 542:	4629                	li	a2,10
 544:	000b2583          	lw	a1,0(s6)
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	e72080e7          	jalr	-398(ra) # 3bc <printint>
 552:	8b4a                	mv	s6,s2
      state = 0;
 554:	4981                	li	s3,0
 556:	bf85                	j	4c6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 558:	008b0913          	addi	s2,s6,8
 55c:	4681                	li	a3,0
 55e:	4641                	li	a2,16
 560:	000b2583          	lw	a1,0(s6)
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	e56080e7          	jalr	-426(ra) # 3bc <printint>
 56e:	8b4a                	mv	s6,s2
      state = 0;
 570:	4981                	li	s3,0
 572:	bf91                	j	4c6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 574:	008b0793          	addi	a5,s6,8
 578:	f8f43423          	sd	a5,-120(s0)
 57c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 580:	03000593          	li	a1,48
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e14080e7          	jalr	-492(ra) # 39a <putc>
  putc(fd, 'x');
 58e:	85ea                	mv	a1,s10
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e08080e7          	jalr	-504(ra) # 39a <putc>
 59a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 59c:	03c9d793          	srli	a5,s3,0x3c
 5a0:	97de                	add	a5,a5,s7
 5a2:	0007c583          	lbu	a1,0(a5)
 5a6:	8556                	mv	a0,s5
 5a8:	00000097          	auipc	ra,0x0
 5ac:	df2080e7          	jalr	-526(ra) # 39a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5b0:	0992                	slli	s3,s3,0x4
 5b2:	397d                	addiw	s2,s2,-1
 5b4:	fe0914e3          	bnez	s2,59c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5b8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	b721                	j	4c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 5c0:	008b0993          	addi	s3,s6,8
 5c4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5c8:	02090163          	beqz	s2,5ea <vprintf+0x184>
        while(*s != 0){
 5cc:	00094583          	lbu	a1,0(s2)
 5d0:	c9a1                	beqz	a1,620 <vprintf+0x1ba>
          putc(fd, *s);
 5d2:	8556                	mv	a0,s5
 5d4:	00000097          	auipc	ra,0x0
 5d8:	dc6080e7          	jalr	-570(ra) # 39a <putc>
          s++;
 5dc:	0905                	addi	s2,s2,1
        while(*s != 0){
 5de:	00094583          	lbu	a1,0(s2)
 5e2:	f9e5                	bnez	a1,5d2 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5e4:	8b4e                	mv	s6,s3
      state = 0;
 5e6:	4981                	li	s3,0
 5e8:	bdf9                	j	4c6 <vprintf+0x60>
          s = "(null)";
 5ea:	00000917          	auipc	s2,0x0
 5ee:	24690913          	addi	s2,s2,582 # 830 <malloc+0x100>
        while(*s != 0){
 5f2:	02800593          	li	a1,40
 5f6:	bff1                	j	5d2 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5f8:	008b0913          	addi	s2,s6,8
 5fc:	000b4583          	lbu	a1,0(s6)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	d98080e7          	jalr	-616(ra) # 39a <putc>
 60a:	8b4a                	mv	s6,s2
      state = 0;
 60c:	4981                	li	s3,0
 60e:	bd65                	j	4c6 <vprintf+0x60>
        putc(fd, c);
 610:	85d2                	mv	a1,s4
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	d86080e7          	jalr	-634(ra) # 39a <putc>
      state = 0;
 61c:	4981                	li	s3,0
 61e:	b565                	j	4c6 <vprintf+0x60>
        s = va_arg(ap, char*);
 620:	8b4e                	mv	s6,s3
      state = 0;
 622:	4981                	li	s3,0
 624:	b54d                	j	4c6 <vprintf+0x60>
    }
  }
}
 626:	70e6                	ld	ra,120(sp)
 628:	7446                	ld	s0,112(sp)
 62a:	74a6                	ld	s1,104(sp)
 62c:	7906                	ld	s2,96(sp)
 62e:	69e6                	ld	s3,88(sp)
 630:	6a46                	ld	s4,80(sp)
 632:	6aa6                	ld	s5,72(sp)
 634:	6b06                	ld	s6,64(sp)
 636:	7be2                	ld	s7,56(sp)
 638:	7c42                	ld	s8,48(sp)
 63a:	7ca2                	ld	s9,40(sp)
 63c:	7d02                	ld	s10,32(sp)
 63e:	6de2                	ld	s11,24(sp)
 640:	6109                	addi	sp,sp,128
 642:	8082                	ret

0000000000000644 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 644:	715d                	addi	sp,sp,-80
 646:	ec06                	sd	ra,24(sp)
 648:	e822                	sd	s0,16(sp)
 64a:	1000                	addi	s0,sp,32
 64c:	e010                	sd	a2,0(s0)
 64e:	e414                	sd	a3,8(s0)
 650:	e818                	sd	a4,16(s0)
 652:	ec1c                	sd	a5,24(s0)
 654:	03043023          	sd	a6,32(s0)
 658:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 65c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 660:	8622                	mv	a2,s0
 662:	00000097          	auipc	ra,0x0
 666:	e04080e7          	jalr	-508(ra) # 466 <vprintf>
}
 66a:	60e2                	ld	ra,24(sp)
 66c:	6442                	ld	s0,16(sp)
 66e:	6161                	addi	sp,sp,80
 670:	8082                	ret

0000000000000672 <printf>:

void
printf(const char *fmt, ...)
{
 672:	711d                	addi	sp,sp,-96
 674:	ec06                	sd	ra,24(sp)
 676:	e822                	sd	s0,16(sp)
 678:	1000                	addi	s0,sp,32
 67a:	e40c                	sd	a1,8(s0)
 67c:	e810                	sd	a2,16(s0)
 67e:	ec14                	sd	a3,24(s0)
 680:	f018                	sd	a4,32(s0)
 682:	f41c                	sd	a5,40(s0)
 684:	03043823          	sd	a6,48(s0)
 688:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 68c:	00840613          	addi	a2,s0,8
 690:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 694:	85aa                	mv	a1,a0
 696:	4505                	li	a0,1
 698:	00000097          	auipc	ra,0x0
 69c:	dce080e7          	jalr	-562(ra) # 466 <vprintf>
}
 6a0:	60e2                	ld	ra,24(sp)
 6a2:	6442                	ld	s0,16(sp)
 6a4:	6125                	addi	sp,sp,96
 6a6:	8082                	ret

00000000000006a8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6a8:	1141                	addi	sp,sp,-16
 6aa:	e422                	sd	s0,8(sp)
 6ac:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ae:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b2:	00000797          	auipc	a5,0x0
 6b6:	19e7b783          	ld	a5,414(a5) # 850 <freep>
 6ba:	a805                	j	6ea <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6bc:	4618                	lw	a4,8(a2)
 6be:	9db9                	addw	a1,a1,a4
 6c0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6c4:	6398                	ld	a4,0(a5)
 6c6:	6318                	ld	a4,0(a4)
 6c8:	fee53823          	sd	a4,-16(a0)
 6cc:	a091                	j	710 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6ce:	ff852703          	lw	a4,-8(a0)
 6d2:	9e39                	addw	a2,a2,a4
 6d4:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6d6:	ff053703          	ld	a4,-16(a0)
 6da:	e398                	sd	a4,0(a5)
 6dc:	a099                	j	722 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6de:	6398                	ld	a4,0(a5)
 6e0:	00e7e463          	bltu	a5,a4,6e8 <free+0x40>
 6e4:	00e6ea63          	bltu	a3,a4,6f8 <free+0x50>
{
 6e8:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ea:	fed7fae3          	bgeu	a5,a3,6de <free+0x36>
 6ee:	6398                	ld	a4,0(a5)
 6f0:	00e6e463          	bltu	a3,a4,6f8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6f4:	fee7eae3          	bltu	a5,a4,6e8 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6f8:	ff852583          	lw	a1,-8(a0)
 6fc:	6390                	ld	a2,0(a5)
 6fe:	02059713          	slli	a4,a1,0x20
 702:	9301                	srli	a4,a4,0x20
 704:	0712                	slli	a4,a4,0x4
 706:	9736                	add	a4,a4,a3
 708:	fae60ae3          	beq	a2,a4,6bc <free+0x14>
    bp->s.ptr = p->s.ptr;
 70c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 710:	4790                	lw	a2,8(a5)
 712:	02061713          	slli	a4,a2,0x20
 716:	9301                	srli	a4,a4,0x20
 718:	0712                	slli	a4,a4,0x4
 71a:	973e                	add	a4,a4,a5
 71c:	fae689e3          	beq	a3,a4,6ce <free+0x26>
  } else
    p->s.ptr = bp;
 720:	e394                	sd	a3,0(a5)
  freep = p;
 722:	00000717          	auipc	a4,0x0
 726:	12f73723          	sd	a5,302(a4) # 850 <freep>
}
 72a:	6422                	ld	s0,8(sp)
 72c:	0141                	addi	sp,sp,16
 72e:	8082                	ret

0000000000000730 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 730:	7139                	addi	sp,sp,-64
 732:	fc06                	sd	ra,56(sp)
 734:	f822                	sd	s0,48(sp)
 736:	f426                	sd	s1,40(sp)
 738:	f04a                	sd	s2,32(sp)
 73a:	ec4e                	sd	s3,24(sp)
 73c:	e852                	sd	s4,16(sp)
 73e:	e456                	sd	s5,8(sp)
 740:	e05a                	sd	s6,0(sp)
 742:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 744:	02051493          	slli	s1,a0,0x20
 748:	9081                	srli	s1,s1,0x20
 74a:	04bd                	addi	s1,s1,15
 74c:	8091                	srli	s1,s1,0x4
 74e:	0014899b          	addiw	s3,s1,1
 752:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 754:	00000517          	auipc	a0,0x0
 758:	0fc53503          	ld	a0,252(a0) # 850 <freep>
 75c:	c515                	beqz	a0,788 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 75e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 760:	4798                	lw	a4,8(a5)
 762:	02977f63          	bgeu	a4,s1,7a0 <malloc+0x70>
 766:	8a4e                	mv	s4,s3
 768:	0009871b          	sext.w	a4,s3
 76c:	6685                	lui	a3,0x1
 76e:	00d77363          	bgeu	a4,a3,774 <malloc+0x44>
 772:	6a05                	lui	s4,0x1
 774:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 778:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 77c:	00000917          	auipc	s2,0x0
 780:	0d490913          	addi	s2,s2,212 # 850 <freep>
  if(p == (char*)-1)
 784:	5afd                	li	s5,-1
 786:	a88d                	j	7f8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 788:	00000797          	auipc	a5,0x0
 78c:	0d078793          	addi	a5,a5,208 # 858 <base>
 790:	00000717          	auipc	a4,0x0
 794:	0cf73023          	sd	a5,192(a4) # 850 <freep>
 798:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 79a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 79e:	b7e1                	j	766 <malloc+0x36>
      if(p->s.size == nunits)
 7a0:	02e48b63          	beq	s1,a4,7d6 <malloc+0xa6>
        p->s.size -= nunits;
 7a4:	4137073b          	subw	a4,a4,s3
 7a8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7aa:	1702                	slli	a4,a4,0x20
 7ac:	9301                	srli	a4,a4,0x20
 7ae:	0712                	slli	a4,a4,0x4
 7b0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7b2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7b6:	00000717          	auipc	a4,0x0
 7ba:	08a73d23          	sd	a0,154(a4) # 850 <freep>
      return (void*)(p + 1);
 7be:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7c2:	70e2                	ld	ra,56(sp)
 7c4:	7442                	ld	s0,48(sp)
 7c6:	74a2                	ld	s1,40(sp)
 7c8:	7902                	ld	s2,32(sp)
 7ca:	69e2                	ld	s3,24(sp)
 7cc:	6a42                	ld	s4,16(sp)
 7ce:	6aa2                	ld	s5,8(sp)
 7d0:	6b02                	ld	s6,0(sp)
 7d2:	6121                	addi	sp,sp,64
 7d4:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7d6:	6398                	ld	a4,0(a5)
 7d8:	e118                	sd	a4,0(a0)
 7da:	bff1                	j	7b6 <malloc+0x86>
  hp->s.size = nu;
 7dc:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7e0:	0541                	addi	a0,a0,16
 7e2:	00000097          	auipc	ra,0x0
 7e6:	ec6080e7          	jalr	-314(ra) # 6a8 <free>
  return freep;
 7ea:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ee:	d971                	beqz	a0,7c2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7f0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7f2:	4798                	lw	a4,8(a5)
 7f4:	fa9776e3          	bgeu	a4,s1,7a0 <malloc+0x70>
    if(p == freep)
 7f8:	00093703          	ld	a4,0(s2)
 7fc:	853e                	mv	a0,a5
 7fe:	fef719e3          	bne	a4,a5,7f0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 802:	8552                	mv	a0,s4
 804:	00000097          	auipc	ra,0x0
 808:	b76080e7          	jalr	-1162(ra) # 37a <sbrk>
  if(p == (char*)-1)
 80c:	fd5518e3          	bne	a0,s5,7dc <malloc+0xac>
        return 0;
 810:	4501                	li	a0,0
 812:	bf45                	j	7c2 <malloc+0x92>
