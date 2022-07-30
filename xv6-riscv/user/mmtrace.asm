
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
  12:	8b250513          	addi	a0,a0,-1870 # 8c0 <malloc+0xe4>
  16:	00000097          	auipc	ra,0x0
  1a:	708080e7          	jalr	1800(ra) # 71e <printf>
	char *ch1 = (char*)malloc(4096);
  1e:	6505                	lui	a0,0x1
  20:	00000097          	auipc	ra,0x0
  24:	7bc080e7          	jalr	1980(ra) # 7dc <malloc>
  28:	84aa                	mv	s1,a0
	char *ch2 = (char*)malloc(4096);
  2a:	6505                	lui	a0,0x1
  2c:	00000097          	auipc	ra,0x0
  30:	7b0080e7          	jalr	1968(ra) # 7dc <malloc>
  34:	892a                	mv	s2,a0
  36:	4701                	li	a4,0
	for(int i = 0; i<4096;i++){
  38:	6605                	lui	a2,0x1
		ch1[i] = i%128;
  3a:	41f7579b          	sraiw	a5,a4,0x1f
  3e:	0197d69b          	srliw	a3,a5,0x19
  42:	00e687bb          	addw	a5,a3,a4
  46:	07f7f793          	andi	a5,a5,127
  4a:	9f95                	subw	a5,a5,a3
  4c:	0ff7f793          	andi	a5,a5,255
  50:	00e486b3          	add	a3,s1,a4
  54:	00f68023          	sb	a5,0(a3)
		ch2[i] = i%128;
  58:	00e906b3          	add	a3,s2,a4
  5c:	00f68023          	sb	a5,0(a3)
	for(int i = 0; i<4096;i++){
  60:	0705                	addi	a4,a4,1
  62:	fcc71ce3          	bne	a4,a2,3a <main+0x3a>
	}
	int *i1 = (int*)malloc(4096*4);
  66:	6511                	lui	a0,0x4
  68:	00000097          	auipc	ra,0x0
  6c:	774080e7          	jalr	1908(ra) # 7dc <malloc>
  70:	89aa                	mv	s3,a0
	for(int i = 0; i<4096; i++)
  72:	872a                	mv	a4,a0
  74:	4781                	li	a5,0
  76:	6685                	lui	a3,0x1
		i1[i] = i;
  78:	c31c                	sw	a5,0(a4)
	for(int i = 0; i<4096; i++)
  7a:	2785                	addiw	a5,a5,1
  7c:	0711                	addi	a4,a4,4
  7e:	fed79de3          	bne	a5,a3,78 <main+0x78>

	mmtrace(ch1);
  82:	8526                	mv	a0,s1
  84:	00000097          	auipc	ra,0x0
  88:	3ba080e7          	jalr	954(ra) # 43e <mmtrace>
	mmtrace(ch2);
  8c:	854a                	mv	a0,s2
  8e:	00000097          	auipc	ra,0x0
  92:	3b0080e7          	jalr	944(ra) # 43e <mmtrace>
	mmtrace(i1);
  96:	854e                	mv	a0,s3
  98:	00000097          	auipc	ra,0x0
  9c:	3a6080e7          	jalr	934(ra) # 43e <mmtrace>
	printf("\n");
  a0:	00001517          	auipc	a0,0x1
  a4:	83850513          	addi	a0,a0,-1992 # 8d8 <malloc+0xfc>
  a8:	00000097          	auipc	ra,0x0
  ac:	676080e7          	jalr	1654(ra) # 71e <printf>

	printf("multi process test:\n");
  b0:	00001517          	auipc	a0,0x1
  b4:	83050513          	addi	a0,a0,-2000 # 8e0 <malloc+0x104>
  b8:	00000097          	auipc	ra,0x0
  bc:	666080e7          	jalr	1638(ra) # 71e <printf>
	if(fork()==0){
  c0:	00000097          	auipc	ra,0x0
  c4:	2d6080e7          	jalr	726(ra) # 396 <fork>
  c8:	e905                	bnez	a0,f8 <main+0xf8>
		sleep(1);
  ca:	4505                	li	a0,1
  cc:	00000097          	auipc	ra,0x0
  d0:	362080e7          	jalr	866(ra) # 42e <sleep>
		printf("proc0 - ");
  d4:	00001517          	auipc	a0,0x1
  d8:	82450513          	addi	a0,a0,-2012 # 8f8 <malloc+0x11c>
  dc:	00000097          	auipc	ra,0x0
  e0:	642080e7          	jalr	1602(ra) # 71e <printf>
		mmtrace(ch1);
  e4:	8526                	mv	a0,s1
  e6:	00000097          	auipc	ra,0x0
  ea:	358080e7          	jalr	856(ra) # 43e <mmtrace>
		wait(0);
		sleep(1);
		printf("proc1 - ");
		mmtrace(ch1);
	}
	exit(0);
  ee:	4501                	li	a0,0
  f0:	00000097          	auipc	ra,0x0
  f4:	2ae080e7          	jalr	686(ra) # 39e <exit>
		wait(0);
  f8:	4501                	li	a0,0
  fa:	00000097          	auipc	ra,0x0
  fe:	2ac080e7          	jalr	684(ra) # 3a6 <wait>
		sleep(1);
 102:	4505                	li	a0,1
 104:	00000097          	auipc	ra,0x0
 108:	32a080e7          	jalr	810(ra) # 42e <sleep>
		printf("proc1 - ");
 10c:	00000517          	auipc	a0,0x0
 110:	7fc50513          	addi	a0,a0,2044 # 908 <malloc+0x12c>
 114:	00000097          	auipc	ra,0x0
 118:	60a080e7          	jalr	1546(ra) # 71e <printf>
		mmtrace(ch1);
 11c:	8526                	mv	a0,s1
 11e:	00000097          	auipc	ra,0x0
 122:	320080e7          	jalr	800(ra) # 43e <mmtrace>
 126:	b7e1                	j	ee <main+0xee>

0000000000000128 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 128:	1141                	addi	sp,sp,-16
 12a:	e422                	sd	s0,8(sp)
 12c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 12e:	87aa                	mv	a5,a0
 130:	0585                	addi	a1,a1,1
 132:	0785                	addi	a5,a5,1
 134:	fff5c703          	lbu	a4,-1(a1)
 138:	fee78fa3          	sb	a4,-1(a5)
 13c:	fb75                	bnez	a4,130 <strcpy+0x8>
    ;
  return os;
}
 13e:	6422                	ld	s0,8(sp)
 140:	0141                	addi	sp,sp,16
 142:	8082                	ret

0000000000000144 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 144:	1141                	addi	sp,sp,-16
 146:	e422                	sd	s0,8(sp)
 148:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 14a:	00054783          	lbu	a5,0(a0)
 14e:	cb91                	beqz	a5,162 <strcmp+0x1e>
 150:	0005c703          	lbu	a4,0(a1)
 154:	00f71763          	bne	a4,a5,162 <strcmp+0x1e>
    p++, q++;
 158:	0505                	addi	a0,a0,1
 15a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 15c:	00054783          	lbu	a5,0(a0)
 160:	fbe5                	bnez	a5,150 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 162:	0005c503          	lbu	a0,0(a1)
}
 166:	40a7853b          	subw	a0,a5,a0
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret

0000000000000170 <strlen>:

uint
strlen(const char *s)
{
 170:	1141                	addi	sp,sp,-16
 172:	e422                	sd	s0,8(sp)
 174:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 176:	00054783          	lbu	a5,0(a0)
 17a:	cf91                	beqz	a5,196 <strlen+0x26>
 17c:	0505                	addi	a0,a0,1
 17e:	87aa                	mv	a5,a0
 180:	4685                	li	a3,1
 182:	9e89                	subw	a3,a3,a0
 184:	00f6853b          	addw	a0,a3,a5
 188:	0785                	addi	a5,a5,1
 18a:	fff7c703          	lbu	a4,-1(a5)
 18e:	fb7d                	bnez	a4,184 <strlen+0x14>
    ;
  return n;
}
 190:	6422                	ld	s0,8(sp)
 192:	0141                	addi	sp,sp,16
 194:	8082                	ret
  for(n = 0; s[n]; n++)
 196:	4501                	li	a0,0
 198:	bfe5                	j	190 <strlen+0x20>

000000000000019a <memset>:

void*
memset(void *dst, int c, uint n)
{
 19a:	1141                	addi	sp,sp,-16
 19c:	e422                	sd	s0,8(sp)
 19e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1a0:	ce09                	beqz	a2,1ba <memset+0x20>
 1a2:	87aa                	mv	a5,a0
 1a4:	fff6071b          	addiw	a4,a2,-1
 1a8:	1702                	slli	a4,a4,0x20
 1aa:	9301                	srli	a4,a4,0x20
 1ac:	0705                	addi	a4,a4,1
 1ae:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1b0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1b4:	0785                	addi	a5,a5,1
 1b6:	fee79de3          	bne	a5,a4,1b0 <memset+0x16>
  }
  return dst;
}
 1ba:	6422                	ld	s0,8(sp)
 1bc:	0141                	addi	sp,sp,16
 1be:	8082                	ret

00000000000001c0 <strchr>:

char*
strchr(const char *s, char c)
{
 1c0:	1141                	addi	sp,sp,-16
 1c2:	e422                	sd	s0,8(sp)
 1c4:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1c6:	00054783          	lbu	a5,0(a0)
 1ca:	cb99                	beqz	a5,1e0 <strchr+0x20>
    if(*s == c)
 1cc:	00f58763          	beq	a1,a5,1da <strchr+0x1a>
  for(; *s; s++)
 1d0:	0505                	addi	a0,a0,1
 1d2:	00054783          	lbu	a5,0(a0)
 1d6:	fbfd                	bnez	a5,1cc <strchr+0xc>
      return (char*)s;
  return 0;
 1d8:	4501                	li	a0,0
}
 1da:	6422                	ld	s0,8(sp)
 1dc:	0141                	addi	sp,sp,16
 1de:	8082                	ret
  return 0;
 1e0:	4501                	li	a0,0
 1e2:	bfe5                	j	1da <strchr+0x1a>

00000000000001e4 <gets>:

char*
gets(char *buf, int max)
{
 1e4:	711d                	addi	sp,sp,-96
 1e6:	ec86                	sd	ra,88(sp)
 1e8:	e8a2                	sd	s0,80(sp)
 1ea:	e4a6                	sd	s1,72(sp)
 1ec:	e0ca                	sd	s2,64(sp)
 1ee:	fc4e                	sd	s3,56(sp)
 1f0:	f852                	sd	s4,48(sp)
 1f2:	f456                	sd	s5,40(sp)
 1f4:	f05a                	sd	s6,32(sp)
 1f6:	ec5e                	sd	s7,24(sp)
 1f8:	1080                	addi	s0,sp,96
 1fa:	8baa                	mv	s7,a0
 1fc:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1fe:	892a                	mv	s2,a0
 200:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 202:	4aa9                	li	s5,10
 204:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 206:	89a6                	mv	s3,s1
 208:	2485                	addiw	s1,s1,1
 20a:	0344d863          	bge	s1,s4,23a <gets+0x56>
    cc = read(0, &c, 1);
 20e:	4605                	li	a2,1
 210:	faf40593          	addi	a1,s0,-81
 214:	4501                	li	a0,0
 216:	00000097          	auipc	ra,0x0
 21a:	1a0080e7          	jalr	416(ra) # 3b6 <read>
    if(cc < 1)
 21e:	00a05e63          	blez	a0,23a <gets+0x56>
    buf[i++] = c;
 222:	faf44783          	lbu	a5,-81(s0)
 226:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 22a:	01578763          	beq	a5,s5,238 <gets+0x54>
 22e:	0905                	addi	s2,s2,1
 230:	fd679be3          	bne	a5,s6,206 <gets+0x22>
  for(i=0; i+1 < max; ){
 234:	89a6                	mv	s3,s1
 236:	a011                	j	23a <gets+0x56>
 238:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 23a:	99de                	add	s3,s3,s7
 23c:	00098023          	sb	zero,0(s3)
  return buf;
}
 240:	855e                	mv	a0,s7
 242:	60e6                	ld	ra,88(sp)
 244:	6446                	ld	s0,80(sp)
 246:	64a6                	ld	s1,72(sp)
 248:	6906                	ld	s2,64(sp)
 24a:	79e2                	ld	s3,56(sp)
 24c:	7a42                	ld	s4,48(sp)
 24e:	7aa2                	ld	s5,40(sp)
 250:	7b02                	ld	s6,32(sp)
 252:	6be2                	ld	s7,24(sp)
 254:	6125                	addi	sp,sp,96
 256:	8082                	ret

0000000000000258 <stat>:

int
stat(const char *n, struct stat *st)
{
 258:	1101                	addi	sp,sp,-32
 25a:	ec06                	sd	ra,24(sp)
 25c:	e822                	sd	s0,16(sp)
 25e:	e426                	sd	s1,8(sp)
 260:	e04a                	sd	s2,0(sp)
 262:	1000                	addi	s0,sp,32
 264:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 266:	4581                	li	a1,0
 268:	00000097          	auipc	ra,0x0
 26c:	176080e7          	jalr	374(ra) # 3de <open>
  if(fd < 0)
 270:	02054563          	bltz	a0,29a <stat+0x42>
 274:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 276:	85ca                	mv	a1,s2
 278:	00000097          	auipc	ra,0x0
 27c:	17e080e7          	jalr	382(ra) # 3f6 <fstat>
 280:	892a                	mv	s2,a0
  close(fd);
 282:	8526                	mv	a0,s1
 284:	00000097          	auipc	ra,0x0
 288:	142080e7          	jalr	322(ra) # 3c6 <close>
  return r;
}
 28c:	854a                	mv	a0,s2
 28e:	60e2                	ld	ra,24(sp)
 290:	6442                	ld	s0,16(sp)
 292:	64a2                	ld	s1,8(sp)
 294:	6902                	ld	s2,0(sp)
 296:	6105                	addi	sp,sp,32
 298:	8082                	ret
    return -1;
 29a:	597d                	li	s2,-1
 29c:	bfc5                	j	28c <stat+0x34>

000000000000029e <atoi>:

int
atoi(const char *s)
{
 29e:	1141                	addi	sp,sp,-16
 2a0:	e422                	sd	s0,8(sp)
 2a2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2a4:	00054603          	lbu	a2,0(a0)
 2a8:	fd06079b          	addiw	a5,a2,-48
 2ac:	0ff7f793          	andi	a5,a5,255
 2b0:	4725                	li	a4,9
 2b2:	02f76963          	bltu	a4,a5,2e4 <atoi+0x46>
 2b6:	86aa                	mv	a3,a0
  n = 0;
 2b8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2ba:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2bc:	0685                	addi	a3,a3,1
 2be:	0025179b          	slliw	a5,a0,0x2
 2c2:	9fa9                	addw	a5,a5,a0
 2c4:	0017979b          	slliw	a5,a5,0x1
 2c8:	9fb1                	addw	a5,a5,a2
 2ca:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2ce:	0006c603          	lbu	a2,0(a3) # 1000 <__BSS_END__+0x6b0>
 2d2:	fd06071b          	addiw	a4,a2,-48
 2d6:	0ff77713          	andi	a4,a4,255
 2da:	fee5f1e3          	bgeu	a1,a4,2bc <atoi+0x1e>
  return n;
}
 2de:	6422                	ld	s0,8(sp)
 2e0:	0141                	addi	sp,sp,16
 2e2:	8082                	ret
  n = 0;
 2e4:	4501                	li	a0,0
 2e6:	bfe5                	j	2de <atoi+0x40>

00000000000002e8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2e8:	1141                	addi	sp,sp,-16
 2ea:	e422                	sd	s0,8(sp)
 2ec:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2ee:	02b57663          	bgeu	a0,a1,31a <memmove+0x32>
    while(n-- > 0)
 2f2:	02c05163          	blez	a2,314 <memmove+0x2c>
 2f6:	fff6079b          	addiw	a5,a2,-1
 2fa:	1782                	slli	a5,a5,0x20
 2fc:	9381                	srli	a5,a5,0x20
 2fe:	0785                	addi	a5,a5,1
 300:	97aa                	add	a5,a5,a0
  dst = vdst;
 302:	872a                	mv	a4,a0
      *dst++ = *src++;
 304:	0585                	addi	a1,a1,1
 306:	0705                	addi	a4,a4,1
 308:	fff5c683          	lbu	a3,-1(a1)
 30c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 310:	fee79ae3          	bne	a5,a4,304 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 314:	6422                	ld	s0,8(sp)
 316:	0141                	addi	sp,sp,16
 318:	8082                	ret
    dst += n;
 31a:	00c50733          	add	a4,a0,a2
    src += n;
 31e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 320:	fec05ae3          	blez	a2,314 <memmove+0x2c>
 324:	fff6079b          	addiw	a5,a2,-1
 328:	1782                	slli	a5,a5,0x20
 32a:	9381                	srli	a5,a5,0x20
 32c:	fff7c793          	not	a5,a5
 330:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 332:	15fd                	addi	a1,a1,-1
 334:	177d                	addi	a4,a4,-1
 336:	0005c683          	lbu	a3,0(a1)
 33a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 33e:	fee79ae3          	bne	a5,a4,332 <memmove+0x4a>
 342:	bfc9                	j	314 <memmove+0x2c>

0000000000000344 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 344:	1141                	addi	sp,sp,-16
 346:	e422                	sd	s0,8(sp)
 348:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 34a:	ca05                	beqz	a2,37a <memcmp+0x36>
 34c:	fff6069b          	addiw	a3,a2,-1
 350:	1682                	slli	a3,a3,0x20
 352:	9281                	srli	a3,a3,0x20
 354:	0685                	addi	a3,a3,1
 356:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 358:	00054783          	lbu	a5,0(a0)
 35c:	0005c703          	lbu	a4,0(a1)
 360:	00e79863          	bne	a5,a4,370 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 364:	0505                	addi	a0,a0,1
    p2++;
 366:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 368:	fed518e3          	bne	a0,a3,358 <memcmp+0x14>
  }
  return 0;
 36c:	4501                	li	a0,0
 36e:	a019                	j	374 <memcmp+0x30>
      return *p1 - *p2;
 370:	40e7853b          	subw	a0,a5,a4
}
 374:	6422                	ld	s0,8(sp)
 376:	0141                	addi	sp,sp,16
 378:	8082                	ret
  return 0;
 37a:	4501                	li	a0,0
 37c:	bfe5                	j	374 <memcmp+0x30>

000000000000037e <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 37e:	1141                	addi	sp,sp,-16
 380:	e406                	sd	ra,8(sp)
 382:	e022                	sd	s0,0(sp)
 384:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 386:	00000097          	auipc	ra,0x0
 38a:	f62080e7          	jalr	-158(ra) # 2e8 <memmove>
}
 38e:	60a2                	ld	ra,8(sp)
 390:	6402                	ld	s0,0(sp)
 392:	0141                	addi	sp,sp,16
 394:	8082                	ret

0000000000000396 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 396:	4885                	li	a7,1
 ecall
 398:	00000073          	ecall
 ret
 39c:	8082                	ret

000000000000039e <exit>:
.global exit
exit:
 li a7, SYS_exit
 39e:	4889                	li	a7,2
 ecall
 3a0:	00000073          	ecall
 ret
 3a4:	8082                	ret

00000000000003a6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3a6:	488d                	li	a7,3
 ecall
 3a8:	00000073          	ecall
 ret
 3ac:	8082                	ret

00000000000003ae <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3ae:	4891                	li	a7,4
 ecall
 3b0:	00000073          	ecall
 ret
 3b4:	8082                	ret

00000000000003b6 <read>:
.global read
read:
 li a7, SYS_read
 3b6:	4895                	li	a7,5
 ecall
 3b8:	00000073          	ecall
 ret
 3bc:	8082                	ret

00000000000003be <write>:
.global write
write:
 li a7, SYS_write
 3be:	48c1                	li	a7,16
 ecall
 3c0:	00000073          	ecall
 ret
 3c4:	8082                	ret

00000000000003c6 <close>:
.global close
close:
 li a7, SYS_close
 3c6:	48d5                	li	a7,21
 ecall
 3c8:	00000073          	ecall
 ret
 3cc:	8082                	ret

00000000000003ce <kill>:
.global kill
kill:
 li a7, SYS_kill
 3ce:	4899                	li	a7,6
 ecall
 3d0:	00000073          	ecall
 ret
 3d4:	8082                	ret

00000000000003d6 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3d6:	489d                	li	a7,7
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <open>:
.global open
open:
 li a7, SYS_open
 3de:	48bd                	li	a7,15
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3e6:	48c5                	li	a7,17
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3ee:	48c9                	li	a7,18
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3f6:	48a1                	li	a7,8
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <link>:
.global link
link:
 li a7, SYS_link
 3fe:	48cd                	li	a7,19
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 406:	48d1                	li	a7,20
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 40e:	48a5                	li	a7,9
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <dup>:
.global dup
dup:
 li a7, SYS_dup
 416:	48a9                	li	a7,10
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 41e:	48ad                	li	a7,11
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 426:	48b1                	li	a7,12
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 42e:	48b5                	li	a7,13
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 436:	48b9                	li	a7,14
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <mmtrace>:
.global mmtrace
mmtrace:
 li a7, SYS_mmtrace
 43e:	48d9                	li	a7,22
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 446:	1101                	addi	sp,sp,-32
 448:	ec06                	sd	ra,24(sp)
 44a:	e822                	sd	s0,16(sp)
 44c:	1000                	addi	s0,sp,32
 44e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 452:	4605                	li	a2,1
 454:	fef40593          	addi	a1,s0,-17
 458:	00000097          	auipc	ra,0x0
 45c:	f66080e7          	jalr	-154(ra) # 3be <write>
}
 460:	60e2                	ld	ra,24(sp)
 462:	6442                	ld	s0,16(sp)
 464:	6105                	addi	sp,sp,32
 466:	8082                	ret

0000000000000468 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 468:	7139                	addi	sp,sp,-64
 46a:	fc06                	sd	ra,56(sp)
 46c:	f822                	sd	s0,48(sp)
 46e:	f426                	sd	s1,40(sp)
 470:	f04a                	sd	s2,32(sp)
 472:	ec4e                	sd	s3,24(sp)
 474:	0080                	addi	s0,sp,64
 476:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 478:	c299                	beqz	a3,47e <printint+0x16>
 47a:	0805c863          	bltz	a1,50a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 47e:	2581                	sext.w	a1,a1
  neg = 0;
 480:	4881                	li	a7,0
 482:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 486:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 488:	2601                	sext.w	a2,a2
 48a:	00000517          	auipc	a0,0x0
 48e:	49650513          	addi	a0,a0,1174 # 920 <digits>
 492:	883a                	mv	a6,a4
 494:	2705                	addiw	a4,a4,1
 496:	02c5f7bb          	remuw	a5,a1,a2
 49a:	1782                	slli	a5,a5,0x20
 49c:	9381                	srli	a5,a5,0x20
 49e:	97aa                	add	a5,a5,a0
 4a0:	0007c783          	lbu	a5,0(a5)
 4a4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4a8:	0005879b          	sext.w	a5,a1
 4ac:	02c5d5bb          	divuw	a1,a1,a2
 4b0:	0685                	addi	a3,a3,1
 4b2:	fec7f0e3          	bgeu	a5,a2,492 <printint+0x2a>
  if(neg)
 4b6:	00088b63          	beqz	a7,4cc <printint+0x64>
    buf[i++] = '-';
 4ba:	fd040793          	addi	a5,s0,-48
 4be:	973e                	add	a4,a4,a5
 4c0:	02d00793          	li	a5,45
 4c4:	fef70823          	sb	a5,-16(a4)
 4c8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4cc:	02e05863          	blez	a4,4fc <printint+0x94>
 4d0:	fc040793          	addi	a5,s0,-64
 4d4:	00e78933          	add	s2,a5,a4
 4d8:	fff78993          	addi	s3,a5,-1
 4dc:	99ba                	add	s3,s3,a4
 4de:	377d                	addiw	a4,a4,-1
 4e0:	1702                	slli	a4,a4,0x20
 4e2:	9301                	srli	a4,a4,0x20
 4e4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4e8:	fff94583          	lbu	a1,-1(s2)
 4ec:	8526                	mv	a0,s1
 4ee:	00000097          	auipc	ra,0x0
 4f2:	f58080e7          	jalr	-168(ra) # 446 <putc>
  while(--i >= 0)
 4f6:	197d                	addi	s2,s2,-1
 4f8:	ff3918e3          	bne	s2,s3,4e8 <printint+0x80>
}
 4fc:	70e2                	ld	ra,56(sp)
 4fe:	7442                	ld	s0,48(sp)
 500:	74a2                	ld	s1,40(sp)
 502:	7902                	ld	s2,32(sp)
 504:	69e2                	ld	s3,24(sp)
 506:	6121                	addi	sp,sp,64
 508:	8082                	ret
    x = -xx;
 50a:	40b005bb          	negw	a1,a1
    neg = 1;
 50e:	4885                	li	a7,1
    x = -xx;
 510:	bf8d                	j	482 <printint+0x1a>

0000000000000512 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 512:	7119                	addi	sp,sp,-128
 514:	fc86                	sd	ra,120(sp)
 516:	f8a2                	sd	s0,112(sp)
 518:	f4a6                	sd	s1,104(sp)
 51a:	f0ca                	sd	s2,96(sp)
 51c:	ecce                	sd	s3,88(sp)
 51e:	e8d2                	sd	s4,80(sp)
 520:	e4d6                	sd	s5,72(sp)
 522:	e0da                	sd	s6,64(sp)
 524:	fc5e                	sd	s7,56(sp)
 526:	f862                	sd	s8,48(sp)
 528:	f466                	sd	s9,40(sp)
 52a:	f06a                	sd	s10,32(sp)
 52c:	ec6e                	sd	s11,24(sp)
 52e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 530:	0005c903          	lbu	s2,0(a1)
 534:	18090f63          	beqz	s2,6d2 <vprintf+0x1c0>
 538:	8aaa                	mv	s5,a0
 53a:	8b32                	mv	s6,a2
 53c:	00158493          	addi	s1,a1,1
  state = 0;
 540:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 542:	02500a13          	li	s4,37
      if(c == 'd'){
 546:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 54a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 54e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 552:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 556:	00000b97          	auipc	s7,0x0
 55a:	3cab8b93          	addi	s7,s7,970 # 920 <digits>
 55e:	a839                	j	57c <vprintf+0x6a>
        putc(fd, c);
 560:	85ca                	mv	a1,s2
 562:	8556                	mv	a0,s5
 564:	00000097          	auipc	ra,0x0
 568:	ee2080e7          	jalr	-286(ra) # 446 <putc>
 56c:	a019                	j	572 <vprintf+0x60>
    } else if(state == '%'){
 56e:	01498f63          	beq	s3,s4,58c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 572:	0485                	addi	s1,s1,1
 574:	fff4c903          	lbu	s2,-1(s1)
 578:	14090d63          	beqz	s2,6d2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 57c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 580:	fe0997e3          	bnez	s3,56e <vprintf+0x5c>
      if(c == '%'){
 584:	fd479ee3          	bne	a5,s4,560 <vprintf+0x4e>
        state = '%';
 588:	89be                	mv	s3,a5
 58a:	b7e5                	j	572 <vprintf+0x60>
      if(c == 'd'){
 58c:	05878063          	beq	a5,s8,5cc <vprintf+0xba>
      } else if(c == 'l') {
 590:	05978c63          	beq	a5,s9,5e8 <vprintf+0xd6>
      } else if(c == 'x') {
 594:	07a78863          	beq	a5,s10,604 <vprintf+0xf2>
      } else if(c == 'p') {
 598:	09b78463          	beq	a5,s11,620 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 59c:	07300713          	li	a4,115
 5a0:	0ce78663          	beq	a5,a4,66c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5a4:	06300713          	li	a4,99
 5a8:	0ee78e63          	beq	a5,a4,6a4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5ac:	11478863          	beq	a5,s4,6bc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5b0:	85d2                	mv	a1,s4
 5b2:	8556                	mv	a0,s5
 5b4:	00000097          	auipc	ra,0x0
 5b8:	e92080e7          	jalr	-366(ra) # 446 <putc>
        putc(fd, c);
 5bc:	85ca                	mv	a1,s2
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e86080e7          	jalr	-378(ra) # 446 <putc>
      }
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b765                	j	572 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5cc:	008b0913          	addi	s2,s6,8
 5d0:	4685                	li	a3,1
 5d2:	4629                	li	a2,10
 5d4:	000b2583          	lw	a1,0(s6)
 5d8:	8556                	mv	a0,s5
 5da:	00000097          	auipc	ra,0x0
 5de:	e8e080e7          	jalr	-370(ra) # 468 <printint>
 5e2:	8b4a                	mv	s6,s2
      state = 0;
 5e4:	4981                	li	s3,0
 5e6:	b771                	j	572 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5e8:	008b0913          	addi	s2,s6,8
 5ec:	4681                	li	a3,0
 5ee:	4629                	li	a2,10
 5f0:	000b2583          	lw	a1,0(s6)
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	e72080e7          	jalr	-398(ra) # 468 <printint>
 5fe:	8b4a                	mv	s6,s2
      state = 0;
 600:	4981                	li	s3,0
 602:	bf85                	j	572 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 604:	008b0913          	addi	s2,s6,8
 608:	4681                	li	a3,0
 60a:	4641                	li	a2,16
 60c:	000b2583          	lw	a1,0(s6)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e56080e7          	jalr	-426(ra) # 468 <printint>
 61a:	8b4a                	mv	s6,s2
      state = 0;
 61c:	4981                	li	s3,0
 61e:	bf91                	j	572 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 620:	008b0793          	addi	a5,s6,8
 624:	f8f43423          	sd	a5,-120(s0)
 628:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 62c:	03000593          	li	a1,48
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	e14080e7          	jalr	-492(ra) # 446 <putc>
  putc(fd, 'x');
 63a:	85ea                	mv	a1,s10
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	e08080e7          	jalr	-504(ra) # 446 <putc>
 646:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 648:	03c9d793          	srli	a5,s3,0x3c
 64c:	97de                	add	a5,a5,s7
 64e:	0007c583          	lbu	a1,0(a5)
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	df2080e7          	jalr	-526(ra) # 446 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 65c:	0992                	slli	s3,s3,0x4
 65e:	397d                	addiw	s2,s2,-1
 660:	fe0914e3          	bnez	s2,648 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 664:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 668:	4981                	li	s3,0
 66a:	b721                	j	572 <vprintf+0x60>
        s = va_arg(ap, char*);
 66c:	008b0993          	addi	s3,s6,8
 670:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 674:	02090163          	beqz	s2,696 <vprintf+0x184>
        while(*s != 0){
 678:	00094583          	lbu	a1,0(s2)
 67c:	c9a1                	beqz	a1,6cc <vprintf+0x1ba>
          putc(fd, *s);
 67e:	8556                	mv	a0,s5
 680:	00000097          	auipc	ra,0x0
 684:	dc6080e7          	jalr	-570(ra) # 446 <putc>
          s++;
 688:	0905                	addi	s2,s2,1
        while(*s != 0){
 68a:	00094583          	lbu	a1,0(s2)
 68e:	f9e5                	bnez	a1,67e <vprintf+0x16c>
        s = va_arg(ap, char*);
 690:	8b4e                	mv	s6,s3
      state = 0;
 692:	4981                	li	s3,0
 694:	bdf9                	j	572 <vprintf+0x60>
          s = "(null)";
 696:	00000917          	auipc	s2,0x0
 69a:	28290913          	addi	s2,s2,642 # 918 <malloc+0x13c>
        while(*s != 0){
 69e:	02800593          	li	a1,40
 6a2:	bff1                	j	67e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6a4:	008b0913          	addi	s2,s6,8
 6a8:	000b4583          	lbu	a1,0(s6)
 6ac:	8556                	mv	a0,s5
 6ae:	00000097          	auipc	ra,0x0
 6b2:	d98080e7          	jalr	-616(ra) # 446 <putc>
 6b6:	8b4a                	mv	s6,s2
      state = 0;
 6b8:	4981                	li	s3,0
 6ba:	bd65                	j	572 <vprintf+0x60>
        putc(fd, c);
 6bc:	85d2                	mv	a1,s4
 6be:	8556                	mv	a0,s5
 6c0:	00000097          	auipc	ra,0x0
 6c4:	d86080e7          	jalr	-634(ra) # 446 <putc>
      state = 0;
 6c8:	4981                	li	s3,0
 6ca:	b565                	j	572 <vprintf+0x60>
        s = va_arg(ap, char*);
 6cc:	8b4e                	mv	s6,s3
      state = 0;
 6ce:	4981                	li	s3,0
 6d0:	b54d                	j	572 <vprintf+0x60>
    }
  }
}
 6d2:	70e6                	ld	ra,120(sp)
 6d4:	7446                	ld	s0,112(sp)
 6d6:	74a6                	ld	s1,104(sp)
 6d8:	7906                	ld	s2,96(sp)
 6da:	69e6                	ld	s3,88(sp)
 6dc:	6a46                	ld	s4,80(sp)
 6de:	6aa6                	ld	s5,72(sp)
 6e0:	6b06                	ld	s6,64(sp)
 6e2:	7be2                	ld	s7,56(sp)
 6e4:	7c42                	ld	s8,48(sp)
 6e6:	7ca2                	ld	s9,40(sp)
 6e8:	7d02                	ld	s10,32(sp)
 6ea:	6de2                	ld	s11,24(sp)
 6ec:	6109                	addi	sp,sp,128
 6ee:	8082                	ret

00000000000006f0 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6f0:	715d                	addi	sp,sp,-80
 6f2:	ec06                	sd	ra,24(sp)
 6f4:	e822                	sd	s0,16(sp)
 6f6:	1000                	addi	s0,sp,32
 6f8:	e010                	sd	a2,0(s0)
 6fa:	e414                	sd	a3,8(s0)
 6fc:	e818                	sd	a4,16(s0)
 6fe:	ec1c                	sd	a5,24(s0)
 700:	03043023          	sd	a6,32(s0)
 704:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 708:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 70c:	8622                	mv	a2,s0
 70e:	00000097          	auipc	ra,0x0
 712:	e04080e7          	jalr	-508(ra) # 512 <vprintf>
}
 716:	60e2                	ld	ra,24(sp)
 718:	6442                	ld	s0,16(sp)
 71a:	6161                	addi	sp,sp,80
 71c:	8082                	ret

000000000000071e <printf>:

void
printf(const char *fmt, ...)
{
 71e:	711d                	addi	sp,sp,-96
 720:	ec06                	sd	ra,24(sp)
 722:	e822                	sd	s0,16(sp)
 724:	1000                	addi	s0,sp,32
 726:	e40c                	sd	a1,8(s0)
 728:	e810                	sd	a2,16(s0)
 72a:	ec14                	sd	a3,24(s0)
 72c:	f018                	sd	a4,32(s0)
 72e:	f41c                	sd	a5,40(s0)
 730:	03043823          	sd	a6,48(s0)
 734:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 738:	00840613          	addi	a2,s0,8
 73c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 740:	85aa                	mv	a1,a0
 742:	4505                	li	a0,1
 744:	00000097          	auipc	ra,0x0
 748:	dce080e7          	jalr	-562(ra) # 512 <vprintf>
}
 74c:	60e2                	ld	ra,24(sp)
 74e:	6442                	ld	s0,16(sp)
 750:	6125                	addi	sp,sp,96
 752:	8082                	ret

0000000000000754 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 754:	1141                	addi	sp,sp,-16
 756:	e422                	sd	s0,8(sp)
 758:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 75a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 75e:	00000797          	auipc	a5,0x0
 762:	1da7b783          	ld	a5,474(a5) # 938 <freep>
 766:	a805                	j	796 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 768:	4618                	lw	a4,8(a2)
 76a:	9db9                	addw	a1,a1,a4
 76c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 770:	6398                	ld	a4,0(a5)
 772:	6318                	ld	a4,0(a4)
 774:	fee53823          	sd	a4,-16(a0)
 778:	a091                	j	7bc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 77a:	ff852703          	lw	a4,-8(a0)
 77e:	9e39                	addw	a2,a2,a4
 780:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 782:	ff053703          	ld	a4,-16(a0)
 786:	e398                	sd	a4,0(a5)
 788:	a099                	j	7ce <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 78a:	6398                	ld	a4,0(a5)
 78c:	00e7e463          	bltu	a5,a4,794 <free+0x40>
 790:	00e6ea63          	bltu	a3,a4,7a4 <free+0x50>
{
 794:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 796:	fed7fae3          	bgeu	a5,a3,78a <free+0x36>
 79a:	6398                	ld	a4,0(a5)
 79c:	00e6e463          	bltu	a3,a4,7a4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7a0:	fee7eae3          	bltu	a5,a4,794 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7a4:	ff852583          	lw	a1,-8(a0)
 7a8:	6390                	ld	a2,0(a5)
 7aa:	02059713          	slli	a4,a1,0x20
 7ae:	9301                	srli	a4,a4,0x20
 7b0:	0712                	slli	a4,a4,0x4
 7b2:	9736                	add	a4,a4,a3
 7b4:	fae60ae3          	beq	a2,a4,768 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7b8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7bc:	4790                	lw	a2,8(a5)
 7be:	02061713          	slli	a4,a2,0x20
 7c2:	9301                	srli	a4,a4,0x20
 7c4:	0712                	slli	a4,a4,0x4
 7c6:	973e                	add	a4,a4,a5
 7c8:	fae689e3          	beq	a3,a4,77a <free+0x26>
  } else
    p->s.ptr = bp;
 7cc:	e394                	sd	a3,0(a5)
  freep = p;
 7ce:	00000717          	auipc	a4,0x0
 7d2:	16f73523          	sd	a5,362(a4) # 938 <freep>
}
 7d6:	6422                	ld	s0,8(sp)
 7d8:	0141                	addi	sp,sp,16
 7da:	8082                	ret

00000000000007dc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7dc:	7139                	addi	sp,sp,-64
 7de:	fc06                	sd	ra,56(sp)
 7e0:	f822                	sd	s0,48(sp)
 7e2:	f426                	sd	s1,40(sp)
 7e4:	f04a                	sd	s2,32(sp)
 7e6:	ec4e                	sd	s3,24(sp)
 7e8:	e852                	sd	s4,16(sp)
 7ea:	e456                	sd	s5,8(sp)
 7ec:	e05a                	sd	s6,0(sp)
 7ee:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7f0:	02051493          	slli	s1,a0,0x20
 7f4:	9081                	srli	s1,s1,0x20
 7f6:	04bd                	addi	s1,s1,15
 7f8:	8091                	srli	s1,s1,0x4
 7fa:	0014899b          	addiw	s3,s1,1
 7fe:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 800:	00000517          	auipc	a0,0x0
 804:	13853503          	ld	a0,312(a0) # 938 <freep>
 808:	c515                	beqz	a0,834 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 80a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 80c:	4798                	lw	a4,8(a5)
 80e:	02977f63          	bgeu	a4,s1,84c <malloc+0x70>
 812:	8a4e                	mv	s4,s3
 814:	0009871b          	sext.w	a4,s3
 818:	6685                	lui	a3,0x1
 81a:	00d77363          	bgeu	a4,a3,820 <malloc+0x44>
 81e:	6a05                	lui	s4,0x1
 820:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 824:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 828:	00000917          	auipc	s2,0x0
 82c:	11090913          	addi	s2,s2,272 # 938 <freep>
  if(p == (char*)-1)
 830:	5afd                	li	s5,-1
 832:	a88d                	j	8a4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 834:	00000797          	auipc	a5,0x0
 838:	10c78793          	addi	a5,a5,268 # 940 <base>
 83c:	00000717          	auipc	a4,0x0
 840:	0ef73e23          	sd	a5,252(a4) # 938 <freep>
 844:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 846:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 84a:	b7e1                	j	812 <malloc+0x36>
      if(p->s.size == nunits)
 84c:	02e48b63          	beq	s1,a4,882 <malloc+0xa6>
        p->s.size -= nunits;
 850:	4137073b          	subw	a4,a4,s3
 854:	c798                	sw	a4,8(a5)
        p += p->s.size;
 856:	1702                	slli	a4,a4,0x20
 858:	9301                	srli	a4,a4,0x20
 85a:	0712                	slli	a4,a4,0x4
 85c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 85e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 862:	00000717          	auipc	a4,0x0
 866:	0ca73b23          	sd	a0,214(a4) # 938 <freep>
      return (void*)(p + 1);
 86a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 86e:	70e2                	ld	ra,56(sp)
 870:	7442                	ld	s0,48(sp)
 872:	74a2                	ld	s1,40(sp)
 874:	7902                	ld	s2,32(sp)
 876:	69e2                	ld	s3,24(sp)
 878:	6a42                	ld	s4,16(sp)
 87a:	6aa2                	ld	s5,8(sp)
 87c:	6b02                	ld	s6,0(sp)
 87e:	6121                	addi	sp,sp,64
 880:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 882:	6398                	ld	a4,0(a5)
 884:	e118                	sd	a4,0(a0)
 886:	bff1                	j	862 <malloc+0x86>
  hp->s.size = nu;
 888:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 88c:	0541                	addi	a0,a0,16
 88e:	00000097          	auipc	ra,0x0
 892:	ec6080e7          	jalr	-314(ra) # 754 <free>
  return freep;
 896:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 89a:	d971                	beqz	a0,86e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 89c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 89e:	4798                	lw	a4,8(a5)
 8a0:	fa9776e3          	bgeu	a4,s1,84c <malloc+0x70>
    if(p == freep)
 8a4:	00093703          	ld	a4,0(s2)
 8a8:	853e                	mv	a0,a5
 8aa:	fef719e3          	bne	a4,a5,89c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8ae:	8552                	mv	a0,s4
 8b0:	00000097          	auipc	ra,0x0
 8b4:	b76080e7          	jalr	-1162(ra) # 426 <sbrk>
  if(p == (char*)-1)
 8b8:	fd5518e3          	bne	a0,s5,888 <malloc+0xac>
        return 0;
 8bc:	4501                	li	a0,0
 8be:	bf45                	j	86e <malloc+0x92>
