
user/_mmtrace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char **argv){
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
	printf("single process test:\n");
   e:	00001517          	auipc	a0,0x1
  12:	86250513          	addi	a0,a0,-1950 # 870 <malloc+0xe4>
  16:	00000097          	auipc	ra,0x0
  1a:	6b8080e7          	jalr	1720(ra) # 6ce <printf>
	char *ch1 = (char*)malloc(4096);
  1e:	6505                	lui	a0,0x1
  20:	00000097          	auipc	ra,0x0
  24:	76c080e7          	jalr	1900(ra) # 78c <malloc>
  28:	84aa                	mv	s1,a0
	char *ch2 = (char*)malloc(4096);
  2a:	6505                	lui	a0,0x1
  2c:	00000097          	auipc	ra,0x0
  30:	760080e7          	jalr	1888(ra) # 78c <malloc>
  34:	89aa                	mv	s3,a0
	int *i1 = (int*)malloc(4096*4);
  36:	6511                	lui	a0,0x4
  38:	00000097          	auipc	ra,0x0
  3c:	754080e7          	jalr	1876(ra) # 78c <malloc>
  40:	892a                	mv	s2,a0
	mmtrace(ch1);
  42:	8526                	mv	a0,s1
  44:	00000097          	auipc	ra,0x0
  48:	3aa080e7          	jalr	938(ra) # 3ee <mmtrace>
	mmtrace(ch2);
  4c:	854e                	mv	a0,s3
  4e:	00000097          	auipc	ra,0x0
  52:	3a0080e7          	jalr	928(ra) # 3ee <mmtrace>
	mmtrace(i1);
  56:	854a                	mv	a0,s2
  58:	00000097          	auipc	ra,0x0
  5c:	396080e7          	jalr	918(ra) # 3ee <mmtrace>

	printf("\nimulti process test:\n");
  60:	00001517          	auipc	a0,0x1
  64:	82850513          	addi	a0,a0,-2008 # 888 <malloc+0xfc>
  68:	00000097          	auipc	ra,0x0
  6c:	666080e7          	jalr	1638(ra) # 6ce <printf>
	if(fork()==0){
  70:	00000097          	auipc	ra,0x0
  74:	2d6080e7          	jalr	726(ra) # 346 <fork>
  78:	e905                	bnez	a0,a8 <main+0xa8>
		sleep(1);
  7a:	4505                	li	a0,1
  7c:	00000097          	auipc	ra,0x0
  80:	362080e7          	jalr	866(ra) # 3de <sleep>
		printf("proc0 - ");
  84:	00001517          	auipc	a0,0x1
  88:	81c50513          	addi	a0,a0,-2020 # 8a0 <malloc+0x114>
  8c:	00000097          	auipc	ra,0x0
  90:	642080e7          	jalr	1602(ra) # 6ce <printf>
		mmtrace(ch1);
  94:	8526                	mv	a0,s1
  96:	00000097          	auipc	ra,0x0
  9a:	358080e7          	jalr	856(ra) # 3ee <mmtrace>
		wait(0);
		sleep(1);
		printf("proc1 - ");
		mmtrace(ch1);
	}
	exit(0);
  9e:	4501                	li	a0,0
  a0:	00000097          	auipc	ra,0x0
  a4:	2ae080e7          	jalr	686(ra) # 34e <exit>
		wait(0);
  a8:	4501                	li	a0,0
  aa:	00000097          	auipc	ra,0x0
  ae:	2ac080e7          	jalr	684(ra) # 356 <wait>
		sleep(1);
  b2:	4505                	li	a0,1
  b4:	00000097          	auipc	ra,0x0
  b8:	32a080e7          	jalr	810(ra) # 3de <sleep>
		printf("proc1 - ");
  bc:	00000517          	auipc	a0,0x0
  c0:	7f450513          	addi	a0,a0,2036 # 8b0 <malloc+0x124>
  c4:	00000097          	auipc	ra,0x0
  c8:	60a080e7          	jalr	1546(ra) # 6ce <printf>
		mmtrace(ch1);
  cc:	8526                	mv	a0,s1
  ce:	00000097          	auipc	ra,0x0
  d2:	320080e7          	jalr	800(ra) # 3ee <mmtrace>
  d6:	b7e1                	j	9e <main+0x9e>

00000000000000d8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  d8:	1141                	addi	sp,sp,-16
  da:	e422                	sd	s0,8(sp)
  dc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  de:	87aa                	mv	a5,a0
  e0:	0585                	addi	a1,a1,1
  e2:	0785                	addi	a5,a5,1
  e4:	fff5c703          	lbu	a4,-1(a1)
  e8:	fee78fa3          	sb	a4,-1(a5)
  ec:	fb75                	bnez	a4,e0 <strcpy+0x8>
    ;
  return os;
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	addi	sp,sp,16
  f2:	8082                	ret

00000000000000f4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  f4:	1141                	addi	sp,sp,-16
  f6:	e422                	sd	s0,8(sp)
  f8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  fa:	00054783          	lbu	a5,0(a0)
  fe:	cb91                	beqz	a5,112 <strcmp+0x1e>
 100:	0005c703          	lbu	a4,0(a1)
 104:	00f71763          	bne	a4,a5,112 <strcmp+0x1e>
    p++, q++;
 108:	0505                	addi	a0,a0,1
 10a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 10c:	00054783          	lbu	a5,0(a0)
 110:	fbe5                	bnez	a5,100 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 112:	0005c503          	lbu	a0,0(a1)
}
 116:	40a7853b          	subw	a0,a5,a0
 11a:	6422                	ld	s0,8(sp)
 11c:	0141                	addi	sp,sp,16
 11e:	8082                	ret

0000000000000120 <strlen>:

uint
strlen(const char *s)
{
 120:	1141                	addi	sp,sp,-16
 122:	e422                	sd	s0,8(sp)
 124:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 126:	00054783          	lbu	a5,0(a0)
 12a:	cf91                	beqz	a5,146 <strlen+0x26>
 12c:	0505                	addi	a0,a0,1
 12e:	87aa                	mv	a5,a0
 130:	4685                	li	a3,1
 132:	9e89                	subw	a3,a3,a0
 134:	00f6853b          	addw	a0,a3,a5
 138:	0785                	addi	a5,a5,1
 13a:	fff7c703          	lbu	a4,-1(a5)
 13e:	fb7d                	bnez	a4,134 <strlen+0x14>
    ;
  return n;
}
 140:	6422                	ld	s0,8(sp)
 142:	0141                	addi	sp,sp,16
 144:	8082                	ret
  for(n = 0; s[n]; n++)
 146:	4501                	li	a0,0
 148:	bfe5                	j	140 <strlen+0x20>

000000000000014a <memset>:

void*
memset(void *dst, int c, uint n)
{
 14a:	1141                	addi	sp,sp,-16
 14c:	e422                	sd	s0,8(sp)
 14e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 150:	ce09                	beqz	a2,16a <memset+0x20>
 152:	87aa                	mv	a5,a0
 154:	fff6071b          	addiw	a4,a2,-1
 158:	1702                	slli	a4,a4,0x20
 15a:	9301                	srli	a4,a4,0x20
 15c:	0705                	addi	a4,a4,1
 15e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 160:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 164:	0785                	addi	a5,a5,1
 166:	fee79de3          	bne	a5,a4,160 <memset+0x16>
  }
  return dst;
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret

0000000000000170 <strchr>:

char*
strchr(const char *s, char c)
{
 170:	1141                	addi	sp,sp,-16
 172:	e422                	sd	s0,8(sp)
 174:	0800                	addi	s0,sp,16
  for(; *s; s++)
 176:	00054783          	lbu	a5,0(a0)
 17a:	cb99                	beqz	a5,190 <strchr+0x20>
    if(*s == c)
 17c:	00f58763          	beq	a1,a5,18a <strchr+0x1a>
  for(; *s; s++)
 180:	0505                	addi	a0,a0,1
 182:	00054783          	lbu	a5,0(a0)
 186:	fbfd                	bnez	a5,17c <strchr+0xc>
      return (char*)s;
  return 0;
 188:	4501                	li	a0,0
}
 18a:	6422                	ld	s0,8(sp)
 18c:	0141                	addi	sp,sp,16
 18e:	8082                	ret
  return 0;
 190:	4501                	li	a0,0
 192:	bfe5                	j	18a <strchr+0x1a>

0000000000000194 <gets>:

char*
gets(char *buf, int max)
{
 194:	711d                	addi	sp,sp,-96
 196:	ec86                	sd	ra,88(sp)
 198:	e8a2                	sd	s0,80(sp)
 19a:	e4a6                	sd	s1,72(sp)
 19c:	e0ca                	sd	s2,64(sp)
 19e:	fc4e                	sd	s3,56(sp)
 1a0:	f852                	sd	s4,48(sp)
 1a2:	f456                	sd	s5,40(sp)
 1a4:	f05a                	sd	s6,32(sp)
 1a6:	ec5e                	sd	s7,24(sp)
 1a8:	1080                	addi	s0,sp,96
 1aa:	8baa                	mv	s7,a0
 1ac:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ae:	892a                	mv	s2,a0
 1b0:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1b2:	4aa9                	li	s5,10
 1b4:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1b6:	89a6                	mv	s3,s1
 1b8:	2485                	addiw	s1,s1,1
 1ba:	0344d863          	bge	s1,s4,1ea <gets+0x56>
    cc = read(0, &c, 1);
 1be:	4605                	li	a2,1
 1c0:	faf40593          	addi	a1,s0,-81
 1c4:	4501                	li	a0,0
 1c6:	00000097          	auipc	ra,0x0
 1ca:	1a0080e7          	jalr	416(ra) # 366 <read>
    if(cc < 1)
 1ce:	00a05e63          	blez	a0,1ea <gets+0x56>
    buf[i++] = c;
 1d2:	faf44783          	lbu	a5,-81(s0)
 1d6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1da:	01578763          	beq	a5,s5,1e8 <gets+0x54>
 1de:	0905                	addi	s2,s2,1
 1e0:	fd679be3          	bne	a5,s6,1b6 <gets+0x22>
  for(i=0; i+1 < max; ){
 1e4:	89a6                	mv	s3,s1
 1e6:	a011                	j	1ea <gets+0x56>
 1e8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ea:	99de                	add	s3,s3,s7
 1ec:	00098023          	sb	zero,0(s3)
  return buf;
}
 1f0:	855e                	mv	a0,s7
 1f2:	60e6                	ld	ra,88(sp)
 1f4:	6446                	ld	s0,80(sp)
 1f6:	64a6                	ld	s1,72(sp)
 1f8:	6906                	ld	s2,64(sp)
 1fa:	79e2                	ld	s3,56(sp)
 1fc:	7a42                	ld	s4,48(sp)
 1fe:	7aa2                	ld	s5,40(sp)
 200:	7b02                	ld	s6,32(sp)
 202:	6be2                	ld	s7,24(sp)
 204:	6125                	addi	sp,sp,96
 206:	8082                	ret

0000000000000208 <stat>:

int
stat(const char *n, struct stat *st)
{
 208:	1101                	addi	sp,sp,-32
 20a:	ec06                	sd	ra,24(sp)
 20c:	e822                	sd	s0,16(sp)
 20e:	e426                	sd	s1,8(sp)
 210:	e04a                	sd	s2,0(sp)
 212:	1000                	addi	s0,sp,32
 214:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 216:	4581                	li	a1,0
 218:	00000097          	auipc	ra,0x0
 21c:	176080e7          	jalr	374(ra) # 38e <open>
  if(fd < 0)
 220:	02054563          	bltz	a0,24a <stat+0x42>
 224:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 226:	85ca                	mv	a1,s2
 228:	00000097          	auipc	ra,0x0
 22c:	17e080e7          	jalr	382(ra) # 3a6 <fstat>
 230:	892a                	mv	s2,a0
  close(fd);
 232:	8526                	mv	a0,s1
 234:	00000097          	auipc	ra,0x0
 238:	142080e7          	jalr	322(ra) # 376 <close>
  return r;
}
 23c:	854a                	mv	a0,s2
 23e:	60e2                	ld	ra,24(sp)
 240:	6442                	ld	s0,16(sp)
 242:	64a2                	ld	s1,8(sp)
 244:	6902                	ld	s2,0(sp)
 246:	6105                	addi	sp,sp,32
 248:	8082                	ret
    return -1;
 24a:	597d                	li	s2,-1
 24c:	bfc5                	j	23c <stat+0x34>

000000000000024e <atoi>:

int
atoi(const char *s)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e422                	sd	s0,8(sp)
 252:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 254:	00054603          	lbu	a2,0(a0)
 258:	fd06079b          	addiw	a5,a2,-48
 25c:	0ff7f793          	andi	a5,a5,255
 260:	4725                	li	a4,9
 262:	02f76963          	bltu	a4,a5,294 <atoi+0x46>
 266:	86aa                	mv	a3,a0
  n = 0;
 268:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 26a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 26c:	0685                	addi	a3,a3,1
 26e:	0025179b          	slliw	a5,a0,0x2
 272:	9fa9                	addw	a5,a5,a0
 274:	0017979b          	slliw	a5,a5,0x1
 278:	9fb1                	addw	a5,a5,a2
 27a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 27e:	0006c603          	lbu	a2,0(a3)
 282:	fd06071b          	addiw	a4,a2,-48
 286:	0ff77713          	andi	a4,a4,255
 28a:	fee5f1e3          	bgeu	a1,a4,26c <atoi+0x1e>
  return n;
}
 28e:	6422                	ld	s0,8(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret
  n = 0;
 294:	4501                	li	a0,0
 296:	bfe5                	j	28e <atoi+0x40>

0000000000000298 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 29e:	02b57663          	bgeu	a0,a1,2ca <memmove+0x32>
    while(n-- > 0)
 2a2:	02c05163          	blez	a2,2c4 <memmove+0x2c>
 2a6:	fff6079b          	addiw	a5,a2,-1
 2aa:	1782                	slli	a5,a5,0x20
 2ac:	9381                	srli	a5,a5,0x20
 2ae:	0785                	addi	a5,a5,1
 2b0:	97aa                	add	a5,a5,a0
  dst = vdst;
 2b2:	872a                	mv	a4,a0
      *dst++ = *src++;
 2b4:	0585                	addi	a1,a1,1
 2b6:	0705                	addi	a4,a4,1
 2b8:	fff5c683          	lbu	a3,-1(a1)
 2bc:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2c0:	fee79ae3          	bne	a5,a4,2b4 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2c4:	6422                	ld	s0,8(sp)
 2c6:	0141                	addi	sp,sp,16
 2c8:	8082                	ret
    dst += n;
 2ca:	00c50733          	add	a4,a0,a2
    src += n;
 2ce:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2d0:	fec05ae3          	blez	a2,2c4 <memmove+0x2c>
 2d4:	fff6079b          	addiw	a5,a2,-1
 2d8:	1782                	slli	a5,a5,0x20
 2da:	9381                	srli	a5,a5,0x20
 2dc:	fff7c793          	not	a5,a5
 2e0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2e2:	15fd                	addi	a1,a1,-1
 2e4:	177d                	addi	a4,a4,-1
 2e6:	0005c683          	lbu	a3,0(a1)
 2ea:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ee:	fee79ae3          	bne	a5,a4,2e2 <memmove+0x4a>
 2f2:	bfc9                	j	2c4 <memmove+0x2c>

00000000000002f4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2f4:	1141                	addi	sp,sp,-16
 2f6:	e422                	sd	s0,8(sp)
 2f8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2fa:	ca05                	beqz	a2,32a <memcmp+0x36>
 2fc:	fff6069b          	addiw	a3,a2,-1
 300:	1682                	slli	a3,a3,0x20
 302:	9281                	srli	a3,a3,0x20
 304:	0685                	addi	a3,a3,1
 306:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 308:	00054783          	lbu	a5,0(a0)
 30c:	0005c703          	lbu	a4,0(a1)
 310:	00e79863          	bne	a5,a4,320 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 314:	0505                	addi	a0,a0,1
    p2++;
 316:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 318:	fed518e3          	bne	a0,a3,308 <memcmp+0x14>
  }
  return 0;
 31c:	4501                	li	a0,0
 31e:	a019                	j	324 <memcmp+0x30>
      return *p1 - *p2;
 320:	40e7853b          	subw	a0,a5,a4
}
 324:	6422                	ld	s0,8(sp)
 326:	0141                	addi	sp,sp,16
 328:	8082                	ret
  return 0;
 32a:	4501                	li	a0,0
 32c:	bfe5                	j	324 <memcmp+0x30>

000000000000032e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 32e:	1141                	addi	sp,sp,-16
 330:	e406                	sd	ra,8(sp)
 332:	e022                	sd	s0,0(sp)
 334:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 336:	00000097          	auipc	ra,0x0
 33a:	f62080e7          	jalr	-158(ra) # 298 <memmove>
}
 33e:	60a2                	ld	ra,8(sp)
 340:	6402                	ld	s0,0(sp)
 342:	0141                	addi	sp,sp,16
 344:	8082                	ret

0000000000000346 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 346:	4885                	li	a7,1
 ecall
 348:	00000073          	ecall
 ret
 34c:	8082                	ret

000000000000034e <exit>:
.global exit
exit:
 li a7, SYS_exit
 34e:	4889                	li	a7,2
 ecall
 350:	00000073          	ecall
 ret
 354:	8082                	ret

0000000000000356 <wait>:
.global wait
wait:
 li a7, SYS_wait
 356:	488d                	li	a7,3
 ecall
 358:	00000073          	ecall
 ret
 35c:	8082                	ret

000000000000035e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 35e:	4891                	li	a7,4
 ecall
 360:	00000073          	ecall
 ret
 364:	8082                	ret

0000000000000366 <read>:
.global read
read:
 li a7, SYS_read
 366:	4895                	li	a7,5
 ecall
 368:	00000073          	ecall
 ret
 36c:	8082                	ret

000000000000036e <write>:
.global write
write:
 li a7, SYS_write
 36e:	48c1                	li	a7,16
 ecall
 370:	00000073          	ecall
 ret
 374:	8082                	ret

0000000000000376 <close>:
.global close
close:
 li a7, SYS_close
 376:	48d5                	li	a7,21
 ecall
 378:	00000073          	ecall
 ret
 37c:	8082                	ret

000000000000037e <kill>:
.global kill
kill:
 li a7, SYS_kill
 37e:	4899                	li	a7,6
 ecall
 380:	00000073          	ecall
 ret
 384:	8082                	ret

0000000000000386 <exec>:
.global exec
exec:
 li a7, SYS_exec
 386:	489d                	li	a7,7
 ecall
 388:	00000073          	ecall
 ret
 38c:	8082                	ret

000000000000038e <open>:
.global open
open:
 li a7, SYS_open
 38e:	48bd                	li	a7,15
 ecall
 390:	00000073          	ecall
 ret
 394:	8082                	ret

0000000000000396 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 396:	48c5                	li	a7,17
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 39e:	48c9                	li	a7,18
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3a6:	48a1                	li	a7,8
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <link>:
.global link
link:
 li a7, SYS_link
 3ae:	48cd                	li	a7,19
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3b6:	48d1                	li	a7,20
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3be:	48a5                	li	a7,9
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3c6:	48a9                	li	a7,10
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3ce:	48ad                	li	a7,11
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3d6:	48b1                	li	a7,12
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3de:	48b5                	li	a7,13
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3e6:	48b9                	li	a7,14
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <mmtrace>:
.global mmtrace
mmtrace:
 li a7, SYS_mmtrace
 3ee:	48d9                	li	a7,22
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f6:	1101                	addi	sp,sp,-32
 3f8:	ec06                	sd	ra,24(sp)
 3fa:	e822                	sd	s0,16(sp)
 3fc:	1000                	addi	s0,sp,32
 3fe:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 402:	4605                	li	a2,1
 404:	fef40593          	addi	a1,s0,-17
 408:	00000097          	auipc	ra,0x0
 40c:	f66080e7          	jalr	-154(ra) # 36e <write>
}
 410:	60e2                	ld	ra,24(sp)
 412:	6442                	ld	s0,16(sp)
 414:	6105                	addi	sp,sp,32
 416:	8082                	ret

0000000000000418 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 418:	7139                	addi	sp,sp,-64
 41a:	fc06                	sd	ra,56(sp)
 41c:	f822                	sd	s0,48(sp)
 41e:	f426                	sd	s1,40(sp)
 420:	f04a                	sd	s2,32(sp)
 422:	ec4e                	sd	s3,24(sp)
 424:	0080                	addi	s0,sp,64
 426:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 428:	c299                	beqz	a3,42e <printint+0x16>
 42a:	0805c863          	bltz	a1,4ba <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42e:	2581                	sext.w	a1,a1
  neg = 0;
 430:	4881                	li	a7,0
 432:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 436:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 438:	2601                	sext.w	a2,a2
 43a:	00000517          	auipc	a0,0x0
 43e:	48e50513          	addi	a0,a0,1166 # 8c8 <digits>
 442:	883a                	mv	a6,a4
 444:	2705                	addiw	a4,a4,1
 446:	02c5f7bb          	remuw	a5,a1,a2
 44a:	1782                	slli	a5,a5,0x20
 44c:	9381                	srli	a5,a5,0x20
 44e:	97aa                	add	a5,a5,a0
 450:	0007c783          	lbu	a5,0(a5)
 454:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 458:	0005879b          	sext.w	a5,a1
 45c:	02c5d5bb          	divuw	a1,a1,a2
 460:	0685                	addi	a3,a3,1
 462:	fec7f0e3          	bgeu	a5,a2,442 <printint+0x2a>
  if(neg)
 466:	00088b63          	beqz	a7,47c <printint+0x64>
    buf[i++] = '-';
 46a:	fd040793          	addi	a5,s0,-48
 46e:	973e                	add	a4,a4,a5
 470:	02d00793          	li	a5,45
 474:	fef70823          	sb	a5,-16(a4)
 478:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 47c:	02e05863          	blez	a4,4ac <printint+0x94>
 480:	fc040793          	addi	a5,s0,-64
 484:	00e78933          	add	s2,a5,a4
 488:	fff78993          	addi	s3,a5,-1
 48c:	99ba                	add	s3,s3,a4
 48e:	377d                	addiw	a4,a4,-1
 490:	1702                	slli	a4,a4,0x20
 492:	9301                	srli	a4,a4,0x20
 494:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 498:	fff94583          	lbu	a1,-1(s2)
 49c:	8526                	mv	a0,s1
 49e:	00000097          	auipc	ra,0x0
 4a2:	f58080e7          	jalr	-168(ra) # 3f6 <putc>
  while(--i >= 0)
 4a6:	197d                	addi	s2,s2,-1
 4a8:	ff3918e3          	bne	s2,s3,498 <printint+0x80>
}
 4ac:	70e2                	ld	ra,56(sp)
 4ae:	7442                	ld	s0,48(sp)
 4b0:	74a2                	ld	s1,40(sp)
 4b2:	7902                	ld	s2,32(sp)
 4b4:	69e2                	ld	s3,24(sp)
 4b6:	6121                	addi	sp,sp,64
 4b8:	8082                	ret
    x = -xx;
 4ba:	40b005bb          	negw	a1,a1
    neg = 1;
 4be:	4885                	li	a7,1
    x = -xx;
 4c0:	bf8d                	j	432 <printint+0x1a>

00000000000004c2 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4c2:	7119                	addi	sp,sp,-128
 4c4:	fc86                	sd	ra,120(sp)
 4c6:	f8a2                	sd	s0,112(sp)
 4c8:	f4a6                	sd	s1,104(sp)
 4ca:	f0ca                	sd	s2,96(sp)
 4cc:	ecce                	sd	s3,88(sp)
 4ce:	e8d2                	sd	s4,80(sp)
 4d0:	e4d6                	sd	s5,72(sp)
 4d2:	e0da                	sd	s6,64(sp)
 4d4:	fc5e                	sd	s7,56(sp)
 4d6:	f862                	sd	s8,48(sp)
 4d8:	f466                	sd	s9,40(sp)
 4da:	f06a                	sd	s10,32(sp)
 4dc:	ec6e                	sd	s11,24(sp)
 4de:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4e0:	0005c903          	lbu	s2,0(a1)
 4e4:	18090f63          	beqz	s2,682 <vprintf+0x1c0>
 4e8:	8aaa                	mv	s5,a0
 4ea:	8b32                	mv	s6,a2
 4ec:	00158493          	addi	s1,a1,1
  state = 0;
 4f0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4f2:	02500a13          	li	s4,37
      if(c == 'd'){
 4f6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4fa:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4fe:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 502:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 506:	00000b97          	auipc	s7,0x0
 50a:	3c2b8b93          	addi	s7,s7,962 # 8c8 <digits>
 50e:	a839                	j	52c <vprintf+0x6a>
        putc(fd, c);
 510:	85ca                	mv	a1,s2
 512:	8556                	mv	a0,s5
 514:	00000097          	auipc	ra,0x0
 518:	ee2080e7          	jalr	-286(ra) # 3f6 <putc>
 51c:	a019                	j	522 <vprintf+0x60>
    } else if(state == '%'){
 51e:	01498f63          	beq	s3,s4,53c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 522:	0485                	addi	s1,s1,1
 524:	fff4c903          	lbu	s2,-1(s1)
 528:	14090d63          	beqz	s2,682 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 52c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 530:	fe0997e3          	bnez	s3,51e <vprintf+0x5c>
      if(c == '%'){
 534:	fd479ee3          	bne	a5,s4,510 <vprintf+0x4e>
        state = '%';
 538:	89be                	mv	s3,a5
 53a:	b7e5                	j	522 <vprintf+0x60>
      if(c == 'd'){
 53c:	05878063          	beq	a5,s8,57c <vprintf+0xba>
      } else if(c == 'l') {
 540:	05978c63          	beq	a5,s9,598 <vprintf+0xd6>
      } else if(c == 'x') {
 544:	07a78863          	beq	a5,s10,5b4 <vprintf+0xf2>
      } else if(c == 'p') {
 548:	09b78463          	beq	a5,s11,5d0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 54c:	07300713          	li	a4,115
 550:	0ce78663          	beq	a5,a4,61c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 554:	06300713          	li	a4,99
 558:	0ee78e63          	beq	a5,a4,654 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 55c:	11478863          	beq	a5,s4,66c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 560:	85d2                	mv	a1,s4
 562:	8556                	mv	a0,s5
 564:	00000097          	auipc	ra,0x0
 568:	e92080e7          	jalr	-366(ra) # 3f6 <putc>
        putc(fd, c);
 56c:	85ca                	mv	a1,s2
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e86080e7          	jalr	-378(ra) # 3f6 <putc>
      }
      state = 0;
 578:	4981                	li	s3,0
 57a:	b765                	j	522 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 57c:	008b0913          	addi	s2,s6,8
 580:	4685                	li	a3,1
 582:	4629                	li	a2,10
 584:	000b2583          	lw	a1,0(s6)
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e8e080e7          	jalr	-370(ra) # 418 <printint>
 592:	8b4a                	mv	s6,s2
      state = 0;
 594:	4981                	li	s3,0
 596:	b771                	j	522 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 598:	008b0913          	addi	s2,s6,8
 59c:	4681                	li	a3,0
 59e:	4629                	li	a2,10
 5a0:	000b2583          	lw	a1,0(s6)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e72080e7          	jalr	-398(ra) # 418 <printint>
 5ae:	8b4a                	mv	s6,s2
      state = 0;
 5b0:	4981                	li	s3,0
 5b2:	bf85                	j	522 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b4:	008b0913          	addi	s2,s6,8
 5b8:	4681                	li	a3,0
 5ba:	4641                	li	a2,16
 5bc:	000b2583          	lw	a1,0(s6)
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	e56080e7          	jalr	-426(ra) # 418 <printint>
 5ca:	8b4a                	mv	s6,s2
      state = 0;
 5cc:	4981                	li	s3,0
 5ce:	bf91                	j	522 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5d0:	008b0793          	addi	a5,s6,8
 5d4:	f8f43423          	sd	a5,-120(s0)
 5d8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5dc:	03000593          	li	a1,48
 5e0:	8556                	mv	a0,s5
 5e2:	00000097          	auipc	ra,0x0
 5e6:	e14080e7          	jalr	-492(ra) # 3f6 <putc>
  putc(fd, 'x');
 5ea:	85ea                	mv	a1,s10
 5ec:	8556                	mv	a0,s5
 5ee:	00000097          	auipc	ra,0x0
 5f2:	e08080e7          	jalr	-504(ra) # 3f6 <putc>
 5f6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f8:	03c9d793          	srli	a5,s3,0x3c
 5fc:	97de                	add	a5,a5,s7
 5fe:	0007c583          	lbu	a1,0(a5)
 602:	8556                	mv	a0,s5
 604:	00000097          	auipc	ra,0x0
 608:	df2080e7          	jalr	-526(ra) # 3f6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 60c:	0992                	slli	s3,s3,0x4
 60e:	397d                	addiw	s2,s2,-1
 610:	fe0914e3          	bnez	s2,5f8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 614:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 618:	4981                	li	s3,0
 61a:	b721                	j	522 <vprintf+0x60>
        s = va_arg(ap, char*);
 61c:	008b0993          	addi	s3,s6,8
 620:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 624:	02090163          	beqz	s2,646 <vprintf+0x184>
        while(*s != 0){
 628:	00094583          	lbu	a1,0(s2)
 62c:	c9a1                	beqz	a1,67c <vprintf+0x1ba>
          putc(fd, *s);
 62e:	8556                	mv	a0,s5
 630:	00000097          	auipc	ra,0x0
 634:	dc6080e7          	jalr	-570(ra) # 3f6 <putc>
          s++;
 638:	0905                	addi	s2,s2,1
        while(*s != 0){
 63a:	00094583          	lbu	a1,0(s2)
 63e:	f9e5                	bnez	a1,62e <vprintf+0x16c>
        s = va_arg(ap, char*);
 640:	8b4e                	mv	s6,s3
      state = 0;
 642:	4981                	li	s3,0
 644:	bdf9                	j	522 <vprintf+0x60>
          s = "(null)";
 646:	00000917          	auipc	s2,0x0
 64a:	27a90913          	addi	s2,s2,634 # 8c0 <malloc+0x134>
        while(*s != 0){
 64e:	02800593          	li	a1,40
 652:	bff1                	j	62e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 654:	008b0913          	addi	s2,s6,8
 658:	000b4583          	lbu	a1,0(s6)
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	d98080e7          	jalr	-616(ra) # 3f6 <putc>
 666:	8b4a                	mv	s6,s2
      state = 0;
 668:	4981                	li	s3,0
 66a:	bd65                	j	522 <vprintf+0x60>
        putc(fd, c);
 66c:	85d2                	mv	a1,s4
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	d86080e7          	jalr	-634(ra) # 3f6 <putc>
      state = 0;
 678:	4981                	li	s3,0
 67a:	b565                	j	522 <vprintf+0x60>
        s = va_arg(ap, char*);
 67c:	8b4e                	mv	s6,s3
      state = 0;
 67e:	4981                	li	s3,0
 680:	b54d                	j	522 <vprintf+0x60>
    }
  }
}
 682:	70e6                	ld	ra,120(sp)
 684:	7446                	ld	s0,112(sp)
 686:	74a6                	ld	s1,104(sp)
 688:	7906                	ld	s2,96(sp)
 68a:	69e6                	ld	s3,88(sp)
 68c:	6a46                	ld	s4,80(sp)
 68e:	6aa6                	ld	s5,72(sp)
 690:	6b06                	ld	s6,64(sp)
 692:	7be2                	ld	s7,56(sp)
 694:	7c42                	ld	s8,48(sp)
 696:	7ca2                	ld	s9,40(sp)
 698:	7d02                	ld	s10,32(sp)
 69a:	6de2                	ld	s11,24(sp)
 69c:	6109                	addi	sp,sp,128
 69e:	8082                	ret

00000000000006a0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6a0:	715d                	addi	sp,sp,-80
 6a2:	ec06                	sd	ra,24(sp)
 6a4:	e822                	sd	s0,16(sp)
 6a6:	1000                	addi	s0,sp,32
 6a8:	e010                	sd	a2,0(s0)
 6aa:	e414                	sd	a3,8(s0)
 6ac:	e818                	sd	a4,16(s0)
 6ae:	ec1c                	sd	a5,24(s0)
 6b0:	03043023          	sd	a6,32(s0)
 6b4:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b8:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6bc:	8622                	mv	a2,s0
 6be:	00000097          	auipc	ra,0x0
 6c2:	e04080e7          	jalr	-508(ra) # 4c2 <vprintf>
}
 6c6:	60e2                	ld	ra,24(sp)
 6c8:	6442                	ld	s0,16(sp)
 6ca:	6161                	addi	sp,sp,80
 6cc:	8082                	ret

00000000000006ce <printf>:

void
printf(const char *fmt, ...)
{
 6ce:	711d                	addi	sp,sp,-96
 6d0:	ec06                	sd	ra,24(sp)
 6d2:	e822                	sd	s0,16(sp)
 6d4:	1000                	addi	s0,sp,32
 6d6:	e40c                	sd	a1,8(s0)
 6d8:	e810                	sd	a2,16(s0)
 6da:	ec14                	sd	a3,24(s0)
 6dc:	f018                	sd	a4,32(s0)
 6de:	f41c                	sd	a5,40(s0)
 6e0:	03043823          	sd	a6,48(s0)
 6e4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e8:	00840613          	addi	a2,s0,8
 6ec:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6f0:	85aa                	mv	a1,a0
 6f2:	4505                	li	a0,1
 6f4:	00000097          	auipc	ra,0x0
 6f8:	dce080e7          	jalr	-562(ra) # 4c2 <vprintf>
}
 6fc:	60e2                	ld	ra,24(sp)
 6fe:	6442                	ld	s0,16(sp)
 700:	6125                	addi	sp,sp,96
 702:	8082                	ret

0000000000000704 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 704:	1141                	addi	sp,sp,-16
 706:	e422                	sd	s0,8(sp)
 708:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 70a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70e:	00000797          	auipc	a5,0x0
 712:	1d27b783          	ld	a5,466(a5) # 8e0 <freep>
 716:	a805                	j	746 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 718:	4618                	lw	a4,8(a2)
 71a:	9db9                	addw	a1,a1,a4
 71c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 720:	6398                	ld	a4,0(a5)
 722:	6318                	ld	a4,0(a4)
 724:	fee53823          	sd	a4,-16(a0)
 728:	a091                	j	76c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 72a:	ff852703          	lw	a4,-8(a0)
 72e:	9e39                	addw	a2,a2,a4
 730:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 732:	ff053703          	ld	a4,-16(a0)
 736:	e398                	sd	a4,0(a5)
 738:	a099                	j	77e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 73a:	6398                	ld	a4,0(a5)
 73c:	00e7e463          	bltu	a5,a4,744 <free+0x40>
 740:	00e6ea63          	bltu	a3,a4,754 <free+0x50>
{
 744:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 746:	fed7fae3          	bgeu	a5,a3,73a <free+0x36>
 74a:	6398                	ld	a4,0(a5)
 74c:	00e6e463          	bltu	a3,a4,754 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 750:	fee7eae3          	bltu	a5,a4,744 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 754:	ff852583          	lw	a1,-8(a0)
 758:	6390                	ld	a2,0(a5)
 75a:	02059713          	slli	a4,a1,0x20
 75e:	9301                	srli	a4,a4,0x20
 760:	0712                	slli	a4,a4,0x4
 762:	9736                	add	a4,a4,a3
 764:	fae60ae3          	beq	a2,a4,718 <free+0x14>
    bp->s.ptr = p->s.ptr;
 768:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 76c:	4790                	lw	a2,8(a5)
 76e:	02061713          	slli	a4,a2,0x20
 772:	9301                	srli	a4,a4,0x20
 774:	0712                	slli	a4,a4,0x4
 776:	973e                	add	a4,a4,a5
 778:	fae689e3          	beq	a3,a4,72a <free+0x26>
  } else
    p->s.ptr = bp;
 77c:	e394                	sd	a3,0(a5)
  freep = p;
 77e:	00000717          	auipc	a4,0x0
 782:	16f73123          	sd	a5,354(a4) # 8e0 <freep>
}
 786:	6422                	ld	s0,8(sp)
 788:	0141                	addi	sp,sp,16
 78a:	8082                	ret

000000000000078c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 78c:	7139                	addi	sp,sp,-64
 78e:	fc06                	sd	ra,56(sp)
 790:	f822                	sd	s0,48(sp)
 792:	f426                	sd	s1,40(sp)
 794:	f04a                	sd	s2,32(sp)
 796:	ec4e                	sd	s3,24(sp)
 798:	e852                	sd	s4,16(sp)
 79a:	e456                	sd	s5,8(sp)
 79c:	e05a                	sd	s6,0(sp)
 79e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7a0:	02051493          	slli	s1,a0,0x20
 7a4:	9081                	srli	s1,s1,0x20
 7a6:	04bd                	addi	s1,s1,15
 7a8:	8091                	srli	s1,s1,0x4
 7aa:	0014899b          	addiw	s3,s1,1
 7ae:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7b0:	00000517          	auipc	a0,0x0
 7b4:	13053503          	ld	a0,304(a0) # 8e0 <freep>
 7b8:	c515                	beqz	a0,7e4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7ba:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7bc:	4798                	lw	a4,8(a5)
 7be:	02977f63          	bgeu	a4,s1,7fc <malloc+0x70>
 7c2:	8a4e                	mv	s4,s3
 7c4:	0009871b          	sext.w	a4,s3
 7c8:	6685                	lui	a3,0x1
 7ca:	00d77363          	bgeu	a4,a3,7d0 <malloc+0x44>
 7ce:	6a05                	lui	s4,0x1
 7d0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d8:	00000917          	auipc	s2,0x0
 7dc:	10890913          	addi	s2,s2,264 # 8e0 <freep>
  if(p == (char*)-1)
 7e0:	5afd                	li	s5,-1
 7e2:	a88d                	j	854 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7e4:	00000797          	auipc	a5,0x0
 7e8:	10478793          	addi	a5,a5,260 # 8e8 <base>
 7ec:	00000717          	auipc	a4,0x0
 7f0:	0ef73a23          	sd	a5,244(a4) # 8e0 <freep>
 7f4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7fa:	b7e1                	j	7c2 <malloc+0x36>
      if(p->s.size == nunits)
 7fc:	02e48b63          	beq	s1,a4,832 <malloc+0xa6>
        p->s.size -= nunits;
 800:	4137073b          	subw	a4,a4,s3
 804:	c798                	sw	a4,8(a5)
        p += p->s.size;
 806:	1702                	slli	a4,a4,0x20
 808:	9301                	srli	a4,a4,0x20
 80a:	0712                	slli	a4,a4,0x4
 80c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 812:	00000717          	auipc	a4,0x0
 816:	0ca73723          	sd	a0,206(a4) # 8e0 <freep>
      return (void*)(p + 1);
 81a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81e:	70e2                	ld	ra,56(sp)
 820:	7442                	ld	s0,48(sp)
 822:	74a2                	ld	s1,40(sp)
 824:	7902                	ld	s2,32(sp)
 826:	69e2                	ld	s3,24(sp)
 828:	6a42                	ld	s4,16(sp)
 82a:	6aa2                	ld	s5,8(sp)
 82c:	6b02                	ld	s6,0(sp)
 82e:	6121                	addi	sp,sp,64
 830:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 832:	6398                	ld	a4,0(a5)
 834:	e118                	sd	a4,0(a0)
 836:	bff1                	j	812 <malloc+0x86>
  hp->s.size = nu;
 838:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 83c:	0541                	addi	a0,a0,16
 83e:	00000097          	auipc	ra,0x0
 842:	ec6080e7          	jalr	-314(ra) # 704 <free>
  return freep;
 846:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 84a:	d971                	beqz	a0,81e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84e:	4798                	lw	a4,8(a5)
 850:	fa9776e3          	bgeu	a4,s1,7fc <malloc+0x70>
    if(p == freep)
 854:	00093703          	ld	a4,0(s2)
 858:	853e                	mv	a0,a5
 85a:	fef719e3          	bne	a4,a5,84c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 85e:	8552                	mv	a0,s4
 860:	00000097          	auipc	ra,0x0
 864:	b76080e7          	jalr	-1162(ra) # 3d6 <sbrk>
  if(p == (char*)-1)
 868:	fd5518e3          	bne	a0,s5,838 <malloc+0xac>
        return 0;
 86c:	4501                	li	a0,0
 86e:	bf45                	j	81e <malloc+0x92>
