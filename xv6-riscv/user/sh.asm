
user/_sh:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <getcmd>:
  exit(0);
}

int
getcmd(char *buf, int nbuf)
{
       0:	1101                	addi	sp,sp,-32
       2:	ec06                	sd	ra,24(sp)
       4:	e822                	sd	s0,16(sp)
       6:	e426                	sd	s1,8(sp)
       8:	e04a                	sd	s2,0(sp)
       a:	1000                	addi	s0,sp,32
       c:	84aa                	mv	s1,a0
       e:	892e                	mv	s2,a1
  fprintf(2, "$ ");
      10:	00001597          	auipc	a1,0x1
      14:	2f058593          	addi	a1,a1,752 # 1300 <malloc+0xe4>
      18:	4509                	li	a0,2
      1a:	00001097          	auipc	ra,0x1
      1e:	116080e7          	jalr	278(ra) # 1130 <fprintf>
  memset(buf, 0, nbuf);
      22:	864a                	mv	a2,s2
      24:	4581                	li	a1,0
      26:	8526                	mv	a0,s1
      28:	00001097          	auipc	ra,0x1
      2c:	bb2080e7          	jalr	-1102(ra) # bda <memset>
  gets(buf, nbuf);
      30:	85ca                	mv	a1,s2
      32:	8526                	mv	a0,s1
      34:	00001097          	auipc	ra,0x1
      38:	bf0080e7          	jalr	-1040(ra) # c24 <gets>
  if(buf[0] == 0) // EOF
      3c:	0004c503          	lbu	a0,0(s1)
      40:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
      44:	40a00533          	neg	a0,a0
      48:	60e2                	ld	ra,24(sp)
      4a:	6442                	ld	s0,16(sp)
      4c:	64a2                	ld	s1,8(sp)
      4e:	6902                	ld	s2,0(sp)
      50:	6105                	addi	sp,sp,32
      52:	8082                	ret

0000000000000054 <panic>:
  exit(0);
}

void
panic(char *s)
{
      54:	1141                	addi	sp,sp,-16
      56:	e406                	sd	ra,8(sp)
      58:	e022                	sd	s0,0(sp)
      5a:	0800                	addi	s0,sp,16
      5c:	862a                	mv	a2,a0
  fprintf(2, "%s\n", s);
      5e:	00001597          	auipc	a1,0x1
      62:	2aa58593          	addi	a1,a1,682 # 1308 <malloc+0xec>
      66:	4509                	li	a0,2
      68:	00001097          	auipc	ra,0x1
      6c:	0c8080e7          	jalr	200(ra) # 1130 <fprintf>
  exit(1);
      70:	4505                	li	a0,1
      72:	00001097          	auipc	ra,0x1
      76:	d6c080e7          	jalr	-660(ra) # dde <exit>

000000000000007a <fork1>:
}

int
fork1(void)
{
      7a:	1141                	addi	sp,sp,-16
      7c:	e406                	sd	ra,8(sp)
      7e:	e022                	sd	s0,0(sp)
      80:	0800                	addi	s0,sp,16
  int pid;

  pid = fork();
      82:	00001097          	auipc	ra,0x1
      86:	d54080e7          	jalr	-684(ra) # dd6 <fork>
  if(pid == -1)
      8a:	57fd                	li	a5,-1
      8c:	00f50663          	beq	a0,a5,98 <fork1+0x1e>
    panic("fork");
  return pid;
}
      90:	60a2                	ld	ra,8(sp)
      92:	6402                	ld	s0,0(sp)
      94:	0141                	addi	sp,sp,16
      96:	8082                	ret
    panic("fork");
      98:	00001517          	auipc	a0,0x1
      9c:	27850513          	addi	a0,a0,632 # 1310 <malloc+0xf4>
      a0:	00000097          	auipc	ra,0x0
      a4:	fb4080e7          	jalr	-76(ra) # 54 <panic>

00000000000000a8 <runcmd>:
{
      a8:	7179                	addi	sp,sp,-48
      aa:	f406                	sd	ra,40(sp)
      ac:	f022                	sd	s0,32(sp)
      ae:	ec26                	sd	s1,24(sp)
      b0:	1800                	addi	s0,sp,48
  if(cmd == 0)
      b2:	c10d                	beqz	a0,d4 <runcmd+0x2c>
      b4:	84aa                	mv	s1,a0
  switch(cmd->type){
      b6:	4118                	lw	a4,0(a0)
      b8:	4795                	li	a5,5
      ba:	02e7e263          	bltu	a5,a4,de <runcmd+0x36>
      be:	00056783          	lwu	a5,0(a0)
      c2:	078a                	slli	a5,a5,0x2
      c4:	00001717          	auipc	a4,0x1
      c8:	35c70713          	addi	a4,a4,860 # 1420 <malloc+0x204>
      cc:	97ba                	add	a5,a5,a4
      ce:	439c                	lw	a5,0(a5)
      d0:	97ba                	add	a5,a5,a4
      d2:	8782                	jr	a5
    exit(1);
      d4:	4505                	li	a0,1
      d6:	00001097          	auipc	ra,0x1
      da:	d08080e7          	jalr	-760(ra) # dde <exit>
    panic("runcmd");
      de:	00001517          	auipc	a0,0x1
      e2:	23a50513          	addi	a0,a0,570 # 1318 <malloc+0xfc>
      e6:	00000097          	auipc	ra,0x0
      ea:	f6e080e7          	jalr	-146(ra) # 54 <panic>
    if(ecmd->argv[0] == 0)
      ee:	6510                	ld	a2,8(a0)
      f0:	c221                	beqz	a2,130 <runcmd+0x88>
    fprintf(2, "executing %s\n",ecmd->argv[0]);
      f2:	00001597          	auipc	a1,0x1
      f6:	22e58593          	addi	a1,a1,558 # 1320 <malloc+0x104>
      fa:	4509                	li	a0,2
      fc:	00001097          	auipc	ra,0x1
     100:	034080e7          	jalr	52(ra) # 1130 <fprintf>
    exec(ecmd->argv[0], ecmd->argv);
     104:	00848593          	addi	a1,s1,8
     108:	6488                	ld	a0,8(s1)
     10a:	00001097          	auipc	ra,0x1
     10e:	d0c080e7          	jalr	-756(ra) # e16 <exec>
    fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     112:	6490                	ld	a2,8(s1)
     114:	00001597          	auipc	a1,0x1
     118:	21c58593          	addi	a1,a1,540 # 1330 <malloc+0x114>
     11c:	4509                	li	a0,2
     11e:	00001097          	auipc	ra,0x1
     122:	012080e7          	jalr	18(ra) # 1130 <fprintf>
  exit(0);
     126:	4501                	li	a0,0
     128:	00001097          	auipc	ra,0x1
     12c:	cb6080e7          	jalr	-842(ra) # dde <exit>
      exit(1);
     130:	4505                	li	a0,1
     132:	00001097          	auipc	ra,0x1
     136:	cac080e7          	jalr	-852(ra) # dde <exit>
    close(rcmd->fd);
     13a:	5148                	lw	a0,36(a0)
     13c:	00001097          	auipc	ra,0x1
     140:	cca080e7          	jalr	-822(ra) # e06 <close>
    if(open(rcmd->file, rcmd->mode) < 0){
     144:	508c                	lw	a1,32(s1)
     146:	6888                	ld	a0,16(s1)
     148:	00001097          	auipc	ra,0x1
     14c:	cd6080e7          	jalr	-810(ra) # e1e <open>
     150:	00054763          	bltz	a0,15e <runcmd+0xb6>
    runcmd(rcmd->cmd);
     154:	6488                	ld	a0,8(s1)
     156:	00000097          	auipc	ra,0x0
     15a:	f52080e7          	jalr	-174(ra) # a8 <runcmd>
      fprintf(2, "open %s failed\n", rcmd->file);
     15e:	6890                	ld	a2,16(s1)
     160:	00001597          	auipc	a1,0x1
     164:	1e058593          	addi	a1,a1,480 # 1340 <malloc+0x124>
     168:	4509                	li	a0,2
     16a:	00001097          	auipc	ra,0x1
     16e:	fc6080e7          	jalr	-58(ra) # 1130 <fprintf>
      exit(1);
     172:	4505                	li	a0,1
     174:	00001097          	auipc	ra,0x1
     178:	c6a080e7          	jalr	-918(ra) # dde <exit>
    if(fork1() == 0)
     17c:	00000097          	auipc	ra,0x0
     180:	efe080e7          	jalr	-258(ra) # 7a <fork1>
     184:	c919                	beqz	a0,19a <runcmd+0xf2>
    wait(0);
     186:	4501                	li	a0,0
     188:	00001097          	auipc	ra,0x1
     18c:	c5e080e7          	jalr	-930(ra) # de6 <wait>
    runcmd(lcmd->right);
     190:	6888                	ld	a0,16(s1)
     192:	00000097          	auipc	ra,0x0
     196:	f16080e7          	jalr	-234(ra) # a8 <runcmd>
      runcmd(lcmd->left);
     19a:	6488                	ld	a0,8(s1)
     19c:	00000097          	auipc	ra,0x0
     1a0:	f0c080e7          	jalr	-244(ra) # a8 <runcmd>
    if(pipe(p) < 0)
     1a4:	fd840513          	addi	a0,s0,-40
     1a8:	00001097          	auipc	ra,0x1
     1ac:	c46080e7          	jalr	-954(ra) # dee <pipe>
     1b0:	04054363          	bltz	a0,1f6 <runcmd+0x14e>
    if(fork1() == 0){
     1b4:	00000097          	auipc	ra,0x0
     1b8:	ec6080e7          	jalr	-314(ra) # 7a <fork1>
     1bc:	c529                	beqz	a0,206 <runcmd+0x15e>
    if(fork1() == 0){
     1be:	00000097          	auipc	ra,0x0
     1c2:	ebc080e7          	jalr	-324(ra) # 7a <fork1>
     1c6:	cd25                	beqz	a0,23e <runcmd+0x196>
    close(p[0]);
     1c8:	fd842503          	lw	a0,-40(s0)
     1cc:	00001097          	auipc	ra,0x1
     1d0:	c3a080e7          	jalr	-966(ra) # e06 <close>
    close(p[1]);
     1d4:	fdc42503          	lw	a0,-36(s0)
     1d8:	00001097          	auipc	ra,0x1
     1dc:	c2e080e7          	jalr	-978(ra) # e06 <close>
    wait(0);
     1e0:	4501                	li	a0,0
     1e2:	00001097          	auipc	ra,0x1
     1e6:	c04080e7          	jalr	-1020(ra) # de6 <wait>
    wait(0);
     1ea:	4501                	li	a0,0
     1ec:	00001097          	auipc	ra,0x1
     1f0:	bfa080e7          	jalr	-1030(ra) # de6 <wait>
    break;
     1f4:	bf0d                	j	126 <runcmd+0x7e>
      panic("pipe");
     1f6:	00001517          	auipc	a0,0x1
     1fa:	15a50513          	addi	a0,a0,346 # 1350 <malloc+0x134>
     1fe:	00000097          	auipc	ra,0x0
     202:	e56080e7          	jalr	-426(ra) # 54 <panic>
      close(1);
     206:	4505                	li	a0,1
     208:	00001097          	auipc	ra,0x1
     20c:	bfe080e7          	jalr	-1026(ra) # e06 <close>
      dup(p[1]);
     210:	fdc42503          	lw	a0,-36(s0)
     214:	00001097          	auipc	ra,0x1
     218:	c42080e7          	jalr	-958(ra) # e56 <dup>
      close(p[0]);
     21c:	fd842503          	lw	a0,-40(s0)
     220:	00001097          	auipc	ra,0x1
     224:	be6080e7          	jalr	-1050(ra) # e06 <close>
      close(p[1]);
     228:	fdc42503          	lw	a0,-36(s0)
     22c:	00001097          	auipc	ra,0x1
     230:	bda080e7          	jalr	-1062(ra) # e06 <close>
      runcmd(pcmd->left);
     234:	6488                	ld	a0,8(s1)
     236:	00000097          	auipc	ra,0x0
     23a:	e72080e7          	jalr	-398(ra) # a8 <runcmd>
      close(0);
     23e:	00001097          	auipc	ra,0x1
     242:	bc8080e7          	jalr	-1080(ra) # e06 <close>
      dup(p[0]);
     246:	fd842503          	lw	a0,-40(s0)
     24a:	00001097          	auipc	ra,0x1
     24e:	c0c080e7          	jalr	-1012(ra) # e56 <dup>
      close(p[0]);
     252:	fd842503          	lw	a0,-40(s0)
     256:	00001097          	auipc	ra,0x1
     25a:	bb0080e7          	jalr	-1104(ra) # e06 <close>
      close(p[1]);
     25e:	fdc42503          	lw	a0,-36(s0)
     262:	00001097          	auipc	ra,0x1
     266:	ba4080e7          	jalr	-1116(ra) # e06 <close>
      runcmd(pcmd->right);
     26a:	6888                	ld	a0,16(s1)
     26c:	00000097          	auipc	ra,0x0
     270:	e3c080e7          	jalr	-452(ra) # a8 <runcmd>
    if(fork1() == 0)
     274:	00000097          	auipc	ra,0x0
     278:	e06080e7          	jalr	-506(ra) # 7a <fork1>
     27c:	ea0515e3          	bnez	a0,126 <runcmd+0x7e>
      runcmd(bcmd->cmd);
     280:	6488                	ld	a0,8(s1)
     282:	00000097          	auipc	ra,0x0
     286:	e26080e7          	jalr	-474(ra) # a8 <runcmd>

000000000000028a <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd*
execcmd(void)
{
     28a:	1101                	addi	sp,sp,-32
     28c:	ec06                	sd	ra,24(sp)
     28e:	e822                	sd	s0,16(sp)
     290:	e426                	sd	s1,8(sp)
     292:	1000                	addi	s0,sp,32
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     294:	0a800513          	li	a0,168
     298:	00001097          	auipc	ra,0x1
     29c:	f84080e7          	jalr	-124(ra) # 121c <malloc>
     2a0:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     2a2:	0a800613          	li	a2,168
     2a6:	4581                	li	a1,0
     2a8:	00001097          	auipc	ra,0x1
     2ac:	932080e7          	jalr	-1742(ra) # bda <memset>
  cmd->type = EXEC;
     2b0:	4785                	li	a5,1
     2b2:	c09c                	sw	a5,0(s1)
  return (struct cmd*)cmd;
}
     2b4:	8526                	mv	a0,s1
     2b6:	60e2                	ld	ra,24(sp)
     2b8:	6442                	ld	s0,16(sp)
     2ba:	64a2                	ld	s1,8(sp)
     2bc:	6105                	addi	sp,sp,32
     2be:	8082                	ret

00000000000002c0 <redircmd>:

struct cmd*
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     2c0:	7139                	addi	sp,sp,-64
     2c2:	fc06                	sd	ra,56(sp)
     2c4:	f822                	sd	s0,48(sp)
     2c6:	f426                	sd	s1,40(sp)
     2c8:	f04a                	sd	s2,32(sp)
     2ca:	ec4e                	sd	s3,24(sp)
     2cc:	e852                	sd	s4,16(sp)
     2ce:	e456                	sd	s5,8(sp)
     2d0:	e05a                	sd	s6,0(sp)
     2d2:	0080                	addi	s0,sp,64
     2d4:	8b2a                	mv	s6,a0
     2d6:	8aae                	mv	s5,a1
     2d8:	8a32                	mv	s4,a2
     2da:	89b6                	mv	s3,a3
     2dc:	893a                	mv	s2,a4
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     2de:	02800513          	li	a0,40
     2e2:	00001097          	auipc	ra,0x1
     2e6:	f3a080e7          	jalr	-198(ra) # 121c <malloc>
     2ea:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     2ec:	02800613          	li	a2,40
     2f0:	4581                	li	a1,0
     2f2:	00001097          	auipc	ra,0x1
     2f6:	8e8080e7          	jalr	-1816(ra) # bda <memset>
  cmd->type = REDIR;
     2fa:	4789                	li	a5,2
     2fc:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     2fe:	0164b423          	sd	s6,8(s1)
  cmd->file = file;
     302:	0154b823          	sd	s5,16(s1)
  cmd->efile = efile;
     306:	0144bc23          	sd	s4,24(s1)
  cmd->mode = mode;
     30a:	0334a023          	sw	s3,32(s1)
  cmd->fd = fd;
     30e:	0324a223          	sw	s2,36(s1)
  return (struct cmd*)cmd;
}
     312:	8526                	mv	a0,s1
     314:	70e2                	ld	ra,56(sp)
     316:	7442                	ld	s0,48(sp)
     318:	74a2                	ld	s1,40(sp)
     31a:	7902                	ld	s2,32(sp)
     31c:	69e2                	ld	s3,24(sp)
     31e:	6a42                	ld	s4,16(sp)
     320:	6aa2                	ld	s5,8(sp)
     322:	6b02                	ld	s6,0(sp)
     324:	6121                	addi	sp,sp,64
     326:	8082                	ret

0000000000000328 <pipecmd>:

struct cmd*
pipecmd(struct cmd *left, struct cmd *right)
{
     328:	7179                	addi	sp,sp,-48
     32a:	f406                	sd	ra,40(sp)
     32c:	f022                	sd	s0,32(sp)
     32e:	ec26                	sd	s1,24(sp)
     330:	e84a                	sd	s2,16(sp)
     332:	e44e                	sd	s3,8(sp)
     334:	1800                	addi	s0,sp,48
     336:	89aa                	mv	s3,a0
     338:	892e                	mv	s2,a1
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     33a:	4561                	li	a0,24
     33c:	00001097          	auipc	ra,0x1
     340:	ee0080e7          	jalr	-288(ra) # 121c <malloc>
     344:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     346:	4661                	li	a2,24
     348:	4581                	li	a1,0
     34a:	00001097          	auipc	ra,0x1
     34e:	890080e7          	jalr	-1904(ra) # bda <memset>
  cmd->type = PIPE;
     352:	478d                	li	a5,3
     354:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     356:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     35a:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     35e:	8526                	mv	a0,s1
     360:	70a2                	ld	ra,40(sp)
     362:	7402                	ld	s0,32(sp)
     364:	64e2                	ld	s1,24(sp)
     366:	6942                	ld	s2,16(sp)
     368:	69a2                	ld	s3,8(sp)
     36a:	6145                	addi	sp,sp,48
     36c:	8082                	ret

000000000000036e <listcmd>:

struct cmd*
listcmd(struct cmd *left, struct cmd *right)
{
     36e:	7179                	addi	sp,sp,-48
     370:	f406                	sd	ra,40(sp)
     372:	f022                	sd	s0,32(sp)
     374:	ec26                	sd	s1,24(sp)
     376:	e84a                	sd	s2,16(sp)
     378:	e44e                	sd	s3,8(sp)
     37a:	1800                	addi	s0,sp,48
     37c:	89aa                	mv	s3,a0
     37e:	892e                	mv	s2,a1
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     380:	4561                	li	a0,24
     382:	00001097          	auipc	ra,0x1
     386:	e9a080e7          	jalr	-358(ra) # 121c <malloc>
     38a:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     38c:	4661                	li	a2,24
     38e:	4581                	li	a1,0
     390:	00001097          	auipc	ra,0x1
     394:	84a080e7          	jalr	-1974(ra) # bda <memset>
  cmd->type = LIST;
     398:	4791                	li	a5,4
     39a:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     39c:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     3a0:	0124b823          	sd	s2,16(s1)
  return (struct cmd*)cmd;
}
     3a4:	8526                	mv	a0,s1
     3a6:	70a2                	ld	ra,40(sp)
     3a8:	7402                	ld	s0,32(sp)
     3aa:	64e2                	ld	s1,24(sp)
     3ac:	6942                	ld	s2,16(sp)
     3ae:	69a2                	ld	s3,8(sp)
     3b0:	6145                	addi	sp,sp,48
     3b2:	8082                	ret

00000000000003b4 <backcmd>:

struct cmd*
backcmd(struct cmd *subcmd)
{
     3b4:	1101                	addi	sp,sp,-32
     3b6:	ec06                	sd	ra,24(sp)
     3b8:	e822                	sd	s0,16(sp)
     3ba:	e426                	sd	s1,8(sp)
     3bc:	e04a                	sd	s2,0(sp)
     3be:	1000                	addi	s0,sp,32
     3c0:	892a                	mv	s2,a0
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3c2:	4541                	li	a0,16
     3c4:	00001097          	auipc	ra,0x1
     3c8:	e58080e7          	jalr	-424(ra) # 121c <malloc>
     3cc:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3ce:	4641                	li	a2,16
     3d0:	4581                	li	a1,0
     3d2:	00001097          	auipc	ra,0x1
     3d6:	808080e7          	jalr	-2040(ra) # bda <memset>
  cmd->type = BACK;
     3da:	4795                	li	a5,5
     3dc:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     3de:	0124b423          	sd	s2,8(s1)
  return (struct cmd*)cmd;
}
     3e2:	8526                	mv	a0,s1
     3e4:	60e2                	ld	ra,24(sp)
     3e6:	6442                	ld	s0,16(sp)
     3e8:	64a2                	ld	s1,8(sp)
     3ea:	6902                	ld	s2,0(sp)
     3ec:	6105                	addi	sp,sp,32
     3ee:	8082                	ret

00000000000003f0 <gettoken>:
char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int
gettoken(char **ps, char *es, char **q, char **eq)
{
     3f0:	7139                	addi	sp,sp,-64
     3f2:	fc06                	sd	ra,56(sp)
     3f4:	f822                	sd	s0,48(sp)
     3f6:	f426                	sd	s1,40(sp)
     3f8:	f04a                	sd	s2,32(sp)
     3fa:	ec4e                	sd	s3,24(sp)
     3fc:	e852                	sd	s4,16(sp)
     3fe:	e456                	sd	s5,8(sp)
     400:	e05a                	sd	s6,0(sp)
     402:	0080                	addi	s0,sp,64
     404:	8a2a                	mv	s4,a0
     406:	892e                	mv	s2,a1
     408:	8ab2                	mv	s5,a2
     40a:	8b36                	mv	s6,a3
  char *s;
  int ret;

  s = *ps;
     40c:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     40e:	00001997          	auipc	s3,0x1
     412:	06a98993          	addi	s3,s3,106 # 1478 <whitespace>
     416:	00b4fd63          	bgeu	s1,a1,430 <gettoken+0x40>
     41a:	0004c583          	lbu	a1,0(s1)
     41e:	854e                	mv	a0,s3
     420:	00000097          	auipc	ra,0x0
     424:	7e0080e7          	jalr	2016(ra) # c00 <strchr>
     428:	c501                	beqz	a0,430 <gettoken+0x40>
    s++;
     42a:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     42c:	fe9917e3          	bne	s2,s1,41a <gettoken+0x2a>
  if(q)
     430:	000a8463          	beqz	s5,438 <gettoken+0x48>
    *q = s;
     434:	009ab023          	sd	s1,0(s5)
  ret = *s;
     438:	0004c783          	lbu	a5,0(s1)
     43c:	00078a9b          	sext.w	s5,a5
  switch(*s){
     440:	03c00713          	li	a4,60
     444:	06f76563          	bltu	a4,a5,4ae <gettoken+0xbe>
     448:	03a00713          	li	a4,58
     44c:	00f76e63          	bltu	a4,a5,468 <gettoken+0x78>
     450:	cf89                	beqz	a5,46a <gettoken+0x7a>
     452:	02600713          	li	a4,38
     456:	00e78963          	beq	a5,a4,468 <gettoken+0x78>
     45a:	fd87879b          	addiw	a5,a5,-40
     45e:	0ff7f793          	andi	a5,a5,255
     462:	4705                	li	a4,1
     464:	06f76c63          	bltu	a4,a5,4dc <gettoken+0xec>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     468:	0485                	addi	s1,s1,1
    ret = 'a';
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if(eq)
     46a:	000b0463          	beqz	s6,472 <gettoken+0x82>
    *eq = s;
     46e:	009b3023          	sd	s1,0(s6)

  while(s < es && strchr(whitespace, *s))
     472:	00001997          	auipc	s3,0x1
     476:	00698993          	addi	s3,s3,6 # 1478 <whitespace>
     47a:	0124fd63          	bgeu	s1,s2,494 <gettoken+0xa4>
     47e:	0004c583          	lbu	a1,0(s1)
     482:	854e                	mv	a0,s3
     484:	00000097          	auipc	ra,0x0
     488:	77c080e7          	jalr	1916(ra) # c00 <strchr>
     48c:	c501                	beqz	a0,494 <gettoken+0xa4>
    s++;
     48e:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     490:	fe9917e3          	bne	s2,s1,47e <gettoken+0x8e>
  *ps = s;
     494:	009a3023          	sd	s1,0(s4)
  return ret;
}
     498:	8556                	mv	a0,s5
     49a:	70e2                	ld	ra,56(sp)
     49c:	7442                	ld	s0,48(sp)
     49e:	74a2                	ld	s1,40(sp)
     4a0:	7902                	ld	s2,32(sp)
     4a2:	69e2                	ld	s3,24(sp)
     4a4:	6a42                	ld	s4,16(sp)
     4a6:	6aa2                	ld	s5,8(sp)
     4a8:	6b02                	ld	s6,0(sp)
     4aa:	6121                	addi	sp,sp,64
     4ac:	8082                	ret
  switch(*s){
     4ae:	03e00713          	li	a4,62
     4b2:	02e79163          	bne	a5,a4,4d4 <gettoken+0xe4>
    s++;
     4b6:	00148693          	addi	a3,s1,1
    if(*s == '>'){
     4ba:	0014c703          	lbu	a4,1(s1)
     4be:	03e00793          	li	a5,62
      s++;
     4c2:	0489                	addi	s1,s1,2
      ret = '+';
     4c4:	02b00a93          	li	s5,43
    if(*s == '>'){
     4c8:	faf701e3          	beq	a4,a5,46a <gettoken+0x7a>
    s++;
     4cc:	84b6                	mv	s1,a3
  ret = *s;
     4ce:	03e00a93          	li	s5,62
     4d2:	bf61                	j	46a <gettoken+0x7a>
  switch(*s){
     4d4:	07c00713          	li	a4,124
     4d8:	f8e788e3          	beq	a5,a4,468 <gettoken+0x78>
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     4dc:	00001997          	auipc	s3,0x1
     4e0:	f9c98993          	addi	s3,s3,-100 # 1478 <whitespace>
     4e4:	00001a97          	auipc	s5,0x1
     4e8:	f8ca8a93          	addi	s5,s5,-116 # 1470 <symbols>
     4ec:	0324f563          	bgeu	s1,s2,516 <gettoken+0x126>
     4f0:	0004c583          	lbu	a1,0(s1)
     4f4:	854e                	mv	a0,s3
     4f6:	00000097          	auipc	ra,0x0
     4fa:	70a080e7          	jalr	1802(ra) # c00 <strchr>
     4fe:	e505                	bnez	a0,526 <gettoken+0x136>
     500:	0004c583          	lbu	a1,0(s1)
     504:	8556                	mv	a0,s5
     506:	00000097          	auipc	ra,0x0
     50a:	6fa080e7          	jalr	1786(ra) # c00 <strchr>
     50e:	e909                	bnez	a0,520 <gettoken+0x130>
      s++;
     510:	0485                	addi	s1,s1,1
    while(s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     512:	fc991fe3          	bne	s2,s1,4f0 <gettoken+0x100>
  if(eq)
     516:	06100a93          	li	s5,97
     51a:	f40b1ae3          	bnez	s6,46e <gettoken+0x7e>
     51e:	bf9d                	j	494 <gettoken+0xa4>
    ret = 'a';
     520:	06100a93          	li	s5,97
     524:	b799                	j	46a <gettoken+0x7a>
     526:	06100a93          	li	s5,97
     52a:	b781                	j	46a <gettoken+0x7a>

000000000000052c <peek>:

int
peek(char **ps, char *es, char *toks)
{
     52c:	7139                	addi	sp,sp,-64
     52e:	fc06                	sd	ra,56(sp)
     530:	f822                	sd	s0,48(sp)
     532:	f426                	sd	s1,40(sp)
     534:	f04a                	sd	s2,32(sp)
     536:	ec4e                	sd	s3,24(sp)
     538:	e852                	sd	s4,16(sp)
     53a:	e456                	sd	s5,8(sp)
     53c:	0080                	addi	s0,sp,64
     53e:	8a2a                	mv	s4,a0
     540:	892e                	mv	s2,a1
     542:	8ab2                	mv	s5,a2
  char *s;

  s = *ps;
     544:	6104                	ld	s1,0(a0)
  while(s < es && strchr(whitespace, *s))
     546:	00001997          	auipc	s3,0x1
     54a:	f3298993          	addi	s3,s3,-206 # 1478 <whitespace>
     54e:	00b4fd63          	bgeu	s1,a1,568 <peek+0x3c>
     552:	0004c583          	lbu	a1,0(s1)
     556:	854e                	mv	a0,s3
     558:	00000097          	auipc	ra,0x0
     55c:	6a8080e7          	jalr	1704(ra) # c00 <strchr>
     560:	c501                	beqz	a0,568 <peek+0x3c>
    s++;
     562:	0485                	addi	s1,s1,1
  while(s < es && strchr(whitespace, *s))
     564:	fe9917e3          	bne	s2,s1,552 <peek+0x26>
  *ps = s;
     568:	009a3023          	sd	s1,0(s4)
  return *s && strchr(toks, *s);
     56c:	0004c583          	lbu	a1,0(s1)
     570:	4501                	li	a0,0
     572:	e991                	bnez	a1,586 <peek+0x5a>
}
     574:	70e2                	ld	ra,56(sp)
     576:	7442                	ld	s0,48(sp)
     578:	74a2                	ld	s1,40(sp)
     57a:	7902                	ld	s2,32(sp)
     57c:	69e2                	ld	s3,24(sp)
     57e:	6a42                	ld	s4,16(sp)
     580:	6aa2                	ld	s5,8(sp)
     582:	6121                	addi	sp,sp,64
     584:	8082                	ret
  return *s && strchr(toks, *s);
     586:	8556                	mv	a0,s5
     588:	00000097          	auipc	ra,0x0
     58c:	678080e7          	jalr	1656(ra) # c00 <strchr>
     590:	00a03533          	snez	a0,a0
     594:	b7c5                	j	574 <peek+0x48>

0000000000000596 <parseredirs>:
  return cmd;
}

struct cmd*
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     596:	7159                	addi	sp,sp,-112
     598:	f486                	sd	ra,104(sp)
     59a:	f0a2                	sd	s0,96(sp)
     59c:	eca6                	sd	s1,88(sp)
     59e:	e8ca                	sd	s2,80(sp)
     5a0:	e4ce                	sd	s3,72(sp)
     5a2:	e0d2                	sd	s4,64(sp)
     5a4:	fc56                	sd	s5,56(sp)
     5a6:	f85a                	sd	s6,48(sp)
     5a8:	f45e                	sd	s7,40(sp)
     5aa:	f062                	sd	s8,32(sp)
     5ac:	ec66                	sd	s9,24(sp)
     5ae:	1880                	addi	s0,sp,112
     5b0:	8a2a                	mv	s4,a0
     5b2:	89ae                	mv	s3,a1
     5b4:	8932                	mv	s2,a2
  int tok;
  char *q, *eq;

  while(peek(ps, es, "<>")){
     5b6:	00001b97          	auipc	s7,0x1
     5ba:	dc2b8b93          	addi	s7,s7,-574 # 1378 <malloc+0x15c>
    tok = gettoken(ps, es, 0, 0);
    if(gettoken(ps, es, &q, &eq) != 'a')
     5be:	06100c13          	li	s8,97
      panic("missing file for redirection");
    switch(tok){
     5c2:	03c00c93          	li	s9,60
  while(peek(ps, es, "<>")){
     5c6:	a02d                	j	5f0 <parseredirs+0x5a>
      panic("missing file for redirection");
     5c8:	00001517          	auipc	a0,0x1
     5cc:	d9050513          	addi	a0,a0,-624 # 1358 <malloc+0x13c>
     5d0:	00000097          	auipc	ra,0x0
     5d4:	a84080e7          	jalr	-1404(ra) # 54 <panic>
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     5d8:	4701                	li	a4,0
     5da:	4681                	li	a3,0
     5dc:	f9043603          	ld	a2,-112(s0)
     5e0:	f9843583          	ld	a1,-104(s0)
     5e4:	8552                	mv	a0,s4
     5e6:	00000097          	auipc	ra,0x0
     5ea:	cda080e7          	jalr	-806(ra) # 2c0 <redircmd>
     5ee:	8a2a                	mv	s4,a0
    switch(tok){
     5f0:	03e00b13          	li	s6,62
     5f4:	02b00a93          	li	s5,43
  while(peek(ps, es, "<>")){
     5f8:	865e                	mv	a2,s7
     5fa:	85ca                	mv	a1,s2
     5fc:	854e                	mv	a0,s3
     5fe:	00000097          	auipc	ra,0x0
     602:	f2e080e7          	jalr	-210(ra) # 52c <peek>
     606:	c925                	beqz	a0,676 <parseredirs+0xe0>
    tok = gettoken(ps, es, 0, 0);
     608:	4681                	li	a3,0
     60a:	4601                	li	a2,0
     60c:	85ca                	mv	a1,s2
     60e:	854e                	mv	a0,s3
     610:	00000097          	auipc	ra,0x0
     614:	de0080e7          	jalr	-544(ra) # 3f0 <gettoken>
     618:	84aa                	mv	s1,a0
    if(gettoken(ps, es, &q, &eq) != 'a')
     61a:	f9040693          	addi	a3,s0,-112
     61e:	f9840613          	addi	a2,s0,-104
     622:	85ca                	mv	a1,s2
     624:	854e                	mv	a0,s3
     626:	00000097          	auipc	ra,0x0
     62a:	dca080e7          	jalr	-566(ra) # 3f0 <gettoken>
     62e:	f9851de3          	bne	a0,s8,5c8 <parseredirs+0x32>
    switch(tok){
     632:	fb9483e3          	beq	s1,s9,5d8 <parseredirs+0x42>
     636:	03648263          	beq	s1,s6,65a <parseredirs+0xc4>
     63a:	fb549fe3          	bne	s1,s5,5f8 <parseredirs+0x62>
      break;
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
      break;
    case '+':  // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE, 1);
     63e:	4705                	li	a4,1
     640:	20100693          	li	a3,513
     644:	f9043603          	ld	a2,-112(s0)
     648:	f9843583          	ld	a1,-104(s0)
     64c:	8552                	mv	a0,s4
     64e:	00000097          	auipc	ra,0x0
     652:	c72080e7          	jalr	-910(ra) # 2c0 <redircmd>
     656:	8a2a                	mv	s4,a0
      break;
     658:	bf61                	j	5f0 <parseredirs+0x5a>
      cmd = redircmd(cmd, q, eq, O_WRONLY|O_CREATE|O_TRUNC, 1);
     65a:	4705                	li	a4,1
     65c:	60100693          	li	a3,1537
     660:	f9043603          	ld	a2,-112(s0)
     664:	f9843583          	ld	a1,-104(s0)
     668:	8552                	mv	a0,s4
     66a:	00000097          	auipc	ra,0x0
     66e:	c56080e7          	jalr	-938(ra) # 2c0 <redircmd>
     672:	8a2a                	mv	s4,a0
      break;
     674:	bfb5                	j	5f0 <parseredirs+0x5a>
    }
  }
  return cmd;
}
     676:	8552                	mv	a0,s4
     678:	70a6                	ld	ra,104(sp)
     67a:	7406                	ld	s0,96(sp)
     67c:	64e6                	ld	s1,88(sp)
     67e:	6946                	ld	s2,80(sp)
     680:	69a6                	ld	s3,72(sp)
     682:	6a06                	ld	s4,64(sp)
     684:	7ae2                	ld	s5,56(sp)
     686:	7b42                	ld	s6,48(sp)
     688:	7ba2                	ld	s7,40(sp)
     68a:	7c02                	ld	s8,32(sp)
     68c:	6ce2                	ld	s9,24(sp)
     68e:	6165                	addi	sp,sp,112
     690:	8082                	ret

0000000000000692 <parseexec>:
  return cmd;
}

struct cmd*
parseexec(char **ps, char *es)
{
     692:	7159                	addi	sp,sp,-112
     694:	f486                	sd	ra,104(sp)
     696:	f0a2                	sd	s0,96(sp)
     698:	eca6                	sd	s1,88(sp)
     69a:	e8ca                	sd	s2,80(sp)
     69c:	e4ce                	sd	s3,72(sp)
     69e:	e0d2                	sd	s4,64(sp)
     6a0:	fc56                	sd	s5,56(sp)
     6a2:	f85a                	sd	s6,48(sp)
     6a4:	f45e                	sd	s7,40(sp)
     6a6:	f062                	sd	s8,32(sp)
     6a8:	ec66                	sd	s9,24(sp)
     6aa:	1880                	addi	s0,sp,112
     6ac:	8a2a                	mv	s4,a0
     6ae:	8aae                	mv	s5,a1
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;

  if(peek(ps, es, "("))
     6b0:	00001617          	auipc	a2,0x1
     6b4:	cd060613          	addi	a2,a2,-816 # 1380 <malloc+0x164>
     6b8:	00000097          	auipc	ra,0x0
     6bc:	e74080e7          	jalr	-396(ra) # 52c <peek>
     6c0:	e905                	bnez	a0,6f0 <parseexec+0x5e>
     6c2:	89aa                	mv	s3,a0
    return parseblock(ps, es);

  ret = execcmd();
     6c4:	00000097          	auipc	ra,0x0
     6c8:	bc6080e7          	jalr	-1082(ra) # 28a <execcmd>
     6cc:	8c2a                	mv	s8,a0
  cmd = (struct execcmd*)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
     6ce:	8656                	mv	a2,s5
     6d0:	85d2                	mv	a1,s4
     6d2:	00000097          	auipc	ra,0x0
     6d6:	ec4080e7          	jalr	-316(ra) # 596 <parseredirs>
     6da:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     6dc:	008c0913          	addi	s2,s8,8
     6e0:	00001b17          	auipc	s6,0x1
     6e4:	cc0b0b13          	addi	s6,s6,-832 # 13a0 <malloc+0x184>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
      break;
    if(tok != 'a')
     6e8:	06100c93          	li	s9,97
      panic("syntax");
    cmd->argv[argc] = q;
    cmd->eargv[argc] = eq;
    argc++;
    if(argc >= MAXARGS)
     6ec:	4ba9                	li	s7,10
  while(!peek(ps, es, "|)&;")){
     6ee:	a0b1                	j	73a <parseexec+0xa8>
    return parseblock(ps, es);
     6f0:	85d6                	mv	a1,s5
     6f2:	8552                	mv	a0,s4
     6f4:	00000097          	auipc	ra,0x0
     6f8:	1bc080e7          	jalr	444(ra) # 8b0 <parseblock>
     6fc:	84aa                	mv	s1,a0
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
  cmd->eargv[argc] = 0;
  return ret;
}
     6fe:	8526                	mv	a0,s1
     700:	70a6                	ld	ra,104(sp)
     702:	7406                	ld	s0,96(sp)
     704:	64e6                	ld	s1,88(sp)
     706:	6946                	ld	s2,80(sp)
     708:	69a6                	ld	s3,72(sp)
     70a:	6a06                	ld	s4,64(sp)
     70c:	7ae2                	ld	s5,56(sp)
     70e:	7b42                	ld	s6,48(sp)
     710:	7ba2                	ld	s7,40(sp)
     712:	7c02                	ld	s8,32(sp)
     714:	6ce2                	ld	s9,24(sp)
     716:	6165                	addi	sp,sp,112
     718:	8082                	ret
      panic("syntax");
     71a:	00001517          	auipc	a0,0x1
     71e:	c6e50513          	addi	a0,a0,-914 # 1388 <malloc+0x16c>
     722:	00000097          	auipc	ra,0x0
     726:	932080e7          	jalr	-1742(ra) # 54 <panic>
    ret = parseredirs(ret, ps, es);
     72a:	8656                	mv	a2,s5
     72c:	85d2                	mv	a1,s4
     72e:	8526                	mv	a0,s1
     730:	00000097          	auipc	ra,0x0
     734:	e66080e7          	jalr	-410(ra) # 596 <parseredirs>
     738:	84aa                	mv	s1,a0
  while(!peek(ps, es, "|)&;")){
     73a:	865a                	mv	a2,s6
     73c:	85d6                	mv	a1,s5
     73e:	8552                	mv	a0,s4
     740:	00000097          	auipc	ra,0x0
     744:	dec080e7          	jalr	-532(ra) # 52c <peek>
     748:	e131                	bnez	a0,78c <parseexec+0xfa>
    if((tok=gettoken(ps, es, &q, &eq)) == 0)
     74a:	f9040693          	addi	a3,s0,-112
     74e:	f9840613          	addi	a2,s0,-104
     752:	85d6                	mv	a1,s5
     754:	8552                	mv	a0,s4
     756:	00000097          	auipc	ra,0x0
     75a:	c9a080e7          	jalr	-870(ra) # 3f0 <gettoken>
     75e:	c51d                	beqz	a0,78c <parseexec+0xfa>
    if(tok != 'a')
     760:	fb951de3          	bne	a0,s9,71a <parseexec+0x88>
    cmd->argv[argc] = q;
     764:	f9843783          	ld	a5,-104(s0)
     768:	00f93023          	sd	a5,0(s2)
    cmd->eargv[argc] = eq;
     76c:	f9043783          	ld	a5,-112(s0)
     770:	04f93823          	sd	a5,80(s2)
    argc++;
     774:	2985                	addiw	s3,s3,1
    if(argc >= MAXARGS)
     776:	0921                	addi	s2,s2,8
     778:	fb7999e3          	bne	s3,s7,72a <parseexec+0x98>
      panic("too many args");
     77c:	00001517          	auipc	a0,0x1
     780:	c1450513          	addi	a0,a0,-1004 # 1390 <malloc+0x174>
     784:	00000097          	auipc	ra,0x0
     788:	8d0080e7          	jalr	-1840(ra) # 54 <panic>
  cmd->argv[argc] = 0;
     78c:	098e                	slli	s3,s3,0x3
     78e:	99e2                	add	s3,s3,s8
     790:	0009b423          	sd	zero,8(s3)
  cmd->eargv[argc] = 0;
     794:	0409bc23          	sd	zero,88(s3)
  return ret;
     798:	b79d                	j	6fe <parseexec+0x6c>

000000000000079a <parsepipe>:
{
     79a:	7179                	addi	sp,sp,-48
     79c:	f406                	sd	ra,40(sp)
     79e:	f022                	sd	s0,32(sp)
     7a0:	ec26                	sd	s1,24(sp)
     7a2:	e84a                	sd	s2,16(sp)
     7a4:	e44e                	sd	s3,8(sp)
     7a6:	1800                	addi	s0,sp,48
     7a8:	892a                	mv	s2,a0
     7aa:	89ae                	mv	s3,a1
  cmd = parseexec(ps, es);
     7ac:	00000097          	auipc	ra,0x0
     7b0:	ee6080e7          	jalr	-282(ra) # 692 <parseexec>
     7b4:	84aa                	mv	s1,a0
  if(peek(ps, es, "|")){
     7b6:	00001617          	auipc	a2,0x1
     7ba:	bf260613          	addi	a2,a2,-1038 # 13a8 <malloc+0x18c>
     7be:	85ce                	mv	a1,s3
     7c0:	854a                	mv	a0,s2
     7c2:	00000097          	auipc	ra,0x0
     7c6:	d6a080e7          	jalr	-662(ra) # 52c <peek>
     7ca:	e909                	bnez	a0,7dc <parsepipe+0x42>
}
     7cc:	8526                	mv	a0,s1
     7ce:	70a2                	ld	ra,40(sp)
     7d0:	7402                	ld	s0,32(sp)
     7d2:	64e2                	ld	s1,24(sp)
     7d4:	6942                	ld	s2,16(sp)
     7d6:	69a2                	ld	s3,8(sp)
     7d8:	6145                	addi	sp,sp,48
     7da:	8082                	ret
    gettoken(ps, es, 0, 0);
     7dc:	4681                	li	a3,0
     7de:	4601                	li	a2,0
     7e0:	85ce                	mv	a1,s3
     7e2:	854a                	mv	a0,s2
     7e4:	00000097          	auipc	ra,0x0
     7e8:	c0c080e7          	jalr	-1012(ra) # 3f0 <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     7ec:	85ce                	mv	a1,s3
     7ee:	854a                	mv	a0,s2
     7f0:	00000097          	auipc	ra,0x0
     7f4:	faa080e7          	jalr	-86(ra) # 79a <parsepipe>
     7f8:	85aa                	mv	a1,a0
     7fa:	8526                	mv	a0,s1
     7fc:	00000097          	auipc	ra,0x0
     800:	b2c080e7          	jalr	-1236(ra) # 328 <pipecmd>
     804:	84aa                	mv	s1,a0
  return cmd;
     806:	b7d9                	j	7cc <parsepipe+0x32>

0000000000000808 <parseline>:
{
     808:	7179                	addi	sp,sp,-48
     80a:	f406                	sd	ra,40(sp)
     80c:	f022                	sd	s0,32(sp)
     80e:	ec26                	sd	s1,24(sp)
     810:	e84a                	sd	s2,16(sp)
     812:	e44e                	sd	s3,8(sp)
     814:	e052                	sd	s4,0(sp)
     816:	1800                	addi	s0,sp,48
     818:	892a                	mv	s2,a0
     81a:	89ae                	mv	s3,a1
  cmd = parsepipe(ps, es);
     81c:	00000097          	auipc	ra,0x0
     820:	f7e080e7          	jalr	-130(ra) # 79a <parsepipe>
     824:	84aa                	mv	s1,a0
  while(peek(ps, es, "&")){
     826:	00001a17          	auipc	s4,0x1
     82a:	b8aa0a13          	addi	s4,s4,-1142 # 13b0 <malloc+0x194>
     82e:	8652                	mv	a2,s4
     830:	85ce                	mv	a1,s3
     832:	854a                	mv	a0,s2
     834:	00000097          	auipc	ra,0x0
     838:	cf8080e7          	jalr	-776(ra) # 52c <peek>
     83c:	c105                	beqz	a0,85c <parseline+0x54>
    gettoken(ps, es, 0, 0);
     83e:	4681                	li	a3,0
     840:	4601                	li	a2,0
     842:	85ce                	mv	a1,s3
     844:	854a                	mv	a0,s2
     846:	00000097          	auipc	ra,0x0
     84a:	baa080e7          	jalr	-1110(ra) # 3f0 <gettoken>
    cmd = backcmd(cmd);
     84e:	8526                	mv	a0,s1
     850:	00000097          	auipc	ra,0x0
     854:	b64080e7          	jalr	-1180(ra) # 3b4 <backcmd>
     858:	84aa                	mv	s1,a0
     85a:	bfd1                	j	82e <parseline+0x26>
  if(peek(ps, es, ";")){
     85c:	00001617          	auipc	a2,0x1
     860:	b5c60613          	addi	a2,a2,-1188 # 13b8 <malloc+0x19c>
     864:	85ce                	mv	a1,s3
     866:	854a                	mv	a0,s2
     868:	00000097          	auipc	ra,0x0
     86c:	cc4080e7          	jalr	-828(ra) # 52c <peek>
     870:	e911                	bnez	a0,884 <parseline+0x7c>
}
     872:	8526                	mv	a0,s1
     874:	70a2                	ld	ra,40(sp)
     876:	7402                	ld	s0,32(sp)
     878:	64e2                	ld	s1,24(sp)
     87a:	6942                	ld	s2,16(sp)
     87c:	69a2                	ld	s3,8(sp)
     87e:	6a02                	ld	s4,0(sp)
     880:	6145                	addi	sp,sp,48
     882:	8082                	ret
    gettoken(ps, es, 0, 0);
     884:	4681                	li	a3,0
     886:	4601                	li	a2,0
     888:	85ce                	mv	a1,s3
     88a:	854a                	mv	a0,s2
     88c:	00000097          	auipc	ra,0x0
     890:	b64080e7          	jalr	-1180(ra) # 3f0 <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     894:	85ce                	mv	a1,s3
     896:	854a                	mv	a0,s2
     898:	00000097          	auipc	ra,0x0
     89c:	f70080e7          	jalr	-144(ra) # 808 <parseline>
     8a0:	85aa                	mv	a1,a0
     8a2:	8526                	mv	a0,s1
     8a4:	00000097          	auipc	ra,0x0
     8a8:	aca080e7          	jalr	-1334(ra) # 36e <listcmd>
     8ac:	84aa                	mv	s1,a0
  return cmd;
     8ae:	b7d1                	j	872 <parseline+0x6a>

00000000000008b0 <parseblock>:
{
     8b0:	7179                	addi	sp,sp,-48
     8b2:	f406                	sd	ra,40(sp)
     8b4:	f022                	sd	s0,32(sp)
     8b6:	ec26                	sd	s1,24(sp)
     8b8:	e84a                	sd	s2,16(sp)
     8ba:	e44e                	sd	s3,8(sp)
     8bc:	1800                	addi	s0,sp,48
     8be:	84aa                	mv	s1,a0
     8c0:	892e                	mv	s2,a1
  if(!peek(ps, es, "("))
     8c2:	00001617          	auipc	a2,0x1
     8c6:	abe60613          	addi	a2,a2,-1346 # 1380 <malloc+0x164>
     8ca:	00000097          	auipc	ra,0x0
     8ce:	c62080e7          	jalr	-926(ra) # 52c <peek>
     8d2:	c12d                	beqz	a0,934 <parseblock+0x84>
  gettoken(ps, es, 0, 0);
     8d4:	4681                	li	a3,0
     8d6:	4601                	li	a2,0
     8d8:	85ca                	mv	a1,s2
     8da:	8526                	mv	a0,s1
     8dc:	00000097          	auipc	ra,0x0
     8e0:	b14080e7          	jalr	-1260(ra) # 3f0 <gettoken>
  cmd = parseline(ps, es);
     8e4:	85ca                	mv	a1,s2
     8e6:	8526                	mv	a0,s1
     8e8:	00000097          	auipc	ra,0x0
     8ec:	f20080e7          	jalr	-224(ra) # 808 <parseline>
     8f0:	89aa                	mv	s3,a0
  if(!peek(ps, es, ")"))
     8f2:	00001617          	auipc	a2,0x1
     8f6:	ade60613          	addi	a2,a2,-1314 # 13d0 <malloc+0x1b4>
     8fa:	85ca                	mv	a1,s2
     8fc:	8526                	mv	a0,s1
     8fe:	00000097          	auipc	ra,0x0
     902:	c2e080e7          	jalr	-978(ra) # 52c <peek>
     906:	cd1d                	beqz	a0,944 <parseblock+0x94>
  gettoken(ps, es, 0, 0);
     908:	4681                	li	a3,0
     90a:	4601                	li	a2,0
     90c:	85ca                	mv	a1,s2
     90e:	8526                	mv	a0,s1
     910:	00000097          	auipc	ra,0x0
     914:	ae0080e7          	jalr	-1312(ra) # 3f0 <gettoken>
  cmd = parseredirs(cmd, ps, es);
     918:	864a                	mv	a2,s2
     91a:	85a6                	mv	a1,s1
     91c:	854e                	mv	a0,s3
     91e:	00000097          	auipc	ra,0x0
     922:	c78080e7          	jalr	-904(ra) # 596 <parseredirs>
}
     926:	70a2                	ld	ra,40(sp)
     928:	7402                	ld	s0,32(sp)
     92a:	64e2                	ld	s1,24(sp)
     92c:	6942                	ld	s2,16(sp)
     92e:	69a2                	ld	s3,8(sp)
     930:	6145                	addi	sp,sp,48
     932:	8082                	ret
    panic("parseblock");
     934:	00001517          	auipc	a0,0x1
     938:	a8c50513          	addi	a0,a0,-1396 # 13c0 <malloc+0x1a4>
     93c:	fffff097          	auipc	ra,0xfffff
     940:	718080e7          	jalr	1816(ra) # 54 <panic>
    panic("syntax - missing )");
     944:	00001517          	auipc	a0,0x1
     948:	a9450513          	addi	a0,a0,-1388 # 13d8 <malloc+0x1bc>
     94c:	fffff097          	auipc	ra,0xfffff
     950:	708080e7          	jalr	1800(ra) # 54 <panic>

0000000000000954 <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd*
nulterminate(struct cmd *cmd)
{
     954:	1101                	addi	sp,sp,-32
     956:	ec06                	sd	ra,24(sp)
     958:	e822                	sd	s0,16(sp)
     95a:	e426                	sd	s1,8(sp)
     95c:	1000                	addi	s0,sp,32
     95e:	84aa                	mv	s1,a0
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if(cmd == 0)
     960:	c521                	beqz	a0,9a8 <nulterminate+0x54>
    return 0;

  switch(cmd->type){
     962:	4118                	lw	a4,0(a0)
     964:	4795                	li	a5,5
     966:	04e7e163          	bltu	a5,a4,9a8 <nulterminate+0x54>
     96a:	00056783          	lwu	a5,0(a0)
     96e:	078a                	slli	a5,a5,0x2
     970:	00001717          	auipc	a4,0x1
     974:	ac870713          	addi	a4,a4,-1336 # 1438 <malloc+0x21c>
     978:	97ba                	add	a5,a5,a4
     97a:	439c                	lw	a5,0(a5)
     97c:	97ba                	add	a5,a5,a4
     97e:	8782                	jr	a5
  case EXEC:
    ecmd = (struct execcmd*)cmd;
    for(i=0; ecmd->argv[i]; i++)
     980:	651c                	ld	a5,8(a0)
     982:	c39d                	beqz	a5,9a8 <nulterminate+0x54>
     984:	01050793          	addi	a5,a0,16
      *ecmd->eargv[i] = 0;
     988:	67b8                	ld	a4,72(a5)
     98a:	00070023          	sb	zero,0(a4)
    for(i=0; ecmd->argv[i]; i++)
     98e:	07a1                	addi	a5,a5,8
     990:	ff87b703          	ld	a4,-8(a5)
     994:	fb75                	bnez	a4,988 <nulterminate+0x34>
     996:	a809                	j	9a8 <nulterminate+0x54>
    break;

  case REDIR:
    rcmd = (struct redircmd*)cmd;
    nulterminate(rcmd->cmd);
     998:	6508                	ld	a0,8(a0)
     99a:	00000097          	auipc	ra,0x0
     99e:	fba080e7          	jalr	-70(ra) # 954 <nulterminate>
    *rcmd->efile = 0;
     9a2:	6c9c                	ld	a5,24(s1)
     9a4:	00078023          	sb	zero,0(a5)
    bcmd = (struct backcmd*)cmd;
    nulterminate(bcmd->cmd);
    break;
  }
  return cmd;
}
     9a8:	8526                	mv	a0,s1
     9aa:	60e2                	ld	ra,24(sp)
     9ac:	6442                	ld	s0,16(sp)
     9ae:	64a2                	ld	s1,8(sp)
     9b0:	6105                	addi	sp,sp,32
     9b2:	8082                	ret
    nulterminate(pcmd->left);
     9b4:	6508                	ld	a0,8(a0)
     9b6:	00000097          	auipc	ra,0x0
     9ba:	f9e080e7          	jalr	-98(ra) # 954 <nulterminate>
    nulterminate(pcmd->right);
     9be:	6888                	ld	a0,16(s1)
     9c0:	00000097          	auipc	ra,0x0
     9c4:	f94080e7          	jalr	-108(ra) # 954 <nulterminate>
    break;
     9c8:	b7c5                	j	9a8 <nulterminate+0x54>
    nulterminate(lcmd->left);
     9ca:	6508                	ld	a0,8(a0)
     9cc:	00000097          	auipc	ra,0x0
     9d0:	f88080e7          	jalr	-120(ra) # 954 <nulterminate>
    nulterminate(lcmd->right);
     9d4:	6888                	ld	a0,16(s1)
     9d6:	00000097          	auipc	ra,0x0
     9da:	f7e080e7          	jalr	-130(ra) # 954 <nulterminate>
    break;
     9de:	b7e9                	j	9a8 <nulterminate+0x54>
    nulterminate(bcmd->cmd);
     9e0:	6508                	ld	a0,8(a0)
     9e2:	00000097          	auipc	ra,0x0
     9e6:	f72080e7          	jalr	-142(ra) # 954 <nulterminate>
    break;
     9ea:	bf7d                	j	9a8 <nulterminate+0x54>

00000000000009ec <parsecmd>:
{
     9ec:	7179                	addi	sp,sp,-48
     9ee:	f406                	sd	ra,40(sp)
     9f0:	f022                	sd	s0,32(sp)
     9f2:	ec26                	sd	s1,24(sp)
     9f4:	e84a                	sd	s2,16(sp)
     9f6:	1800                	addi	s0,sp,48
     9f8:	fca43c23          	sd	a0,-40(s0)
  es = s + strlen(s);
     9fc:	84aa                	mv	s1,a0
     9fe:	00000097          	auipc	ra,0x0
     a02:	1b2080e7          	jalr	434(ra) # bb0 <strlen>
     a06:	1502                	slli	a0,a0,0x20
     a08:	9101                	srli	a0,a0,0x20
     a0a:	94aa                	add	s1,s1,a0
  cmd = parseline(&s, es);
     a0c:	85a6                	mv	a1,s1
     a0e:	fd840513          	addi	a0,s0,-40
     a12:	00000097          	auipc	ra,0x0
     a16:	df6080e7          	jalr	-522(ra) # 808 <parseline>
     a1a:	892a                	mv	s2,a0
  peek(&s, es, "");
     a1c:	00001617          	auipc	a2,0x1
     a20:	9d460613          	addi	a2,a2,-1580 # 13f0 <malloc+0x1d4>
     a24:	85a6                	mv	a1,s1
     a26:	fd840513          	addi	a0,s0,-40
     a2a:	00000097          	auipc	ra,0x0
     a2e:	b02080e7          	jalr	-1278(ra) # 52c <peek>
  if(s != es){
     a32:	fd843603          	ld	a2,-40(s0)
     a36:	00961e63          	bne	a2,s1,a52 <parsecmd+0x66>
  nulterminate(cmd);
     a3a:	854a                	mv	a0,s2
     a3c:	00000097          	auipc	ra,0x0
     a40:	f18080e7          	jalr	-232(ra) # 954 <nulterminate>
}
     a44:	854a                	mv	a0,s2
     a46:	70a2                	ld	ra,40(sp)
     a48:	7402                	ld	s0,32(sp)
     a4a:	64e2                	ld	s1,24(sp)
     a4c:	6942                	ld	s2,16(sp)
     a4e:	6145                	addi	sp,sp,48
     a50:	8082                	ret
    fprintf(2, "leftovers: %s\n", s);
     a52:	00001597          	auipc	a1,0x1
     a56:	9a658593          	addi	a1,a1,-1626 # 13f8 <malloc+0x1dc>
     a5a:	4509                	li	a0,2
     a5c:	00000097          	auipc	ra,0x0
     a60:	6d4080e7          	jalr	1748(ra) # 1130 <fprintf>
    panic("syntax");
     a64:	00001517          	auipc	a0,0x1
     a68:	92450513          	addi	a0,a0,-1756 # 1388 <malloc+0x16c>
     a6c:	fffff097          	auipc	ra,0xfffff
     a70:	5e8080e7          	jalr	1512(ra) # 54 <panic>

0000000000000a74 <main>:
{
     a74:	7139                	addi	sp,sp,-64
     a76:	fc06                	sd	ra,56(sp)
     a78:	f822                	sd	s0,48(sp)
     a7a:	f426                	sd	s1,40(sp)
     a7c:	f04a                	sd	s2,32(sp)
     a7e:	ec4e                	sd	s3,24(sp)
     a80:	e852                	sd	s4,16(sp)
     a82:	e456                	sd	s5,8(sp)
     a84:	0080                	addi	s0,sp,64
  while((fd = open("console", O_RDWR)) >= 0){
     a86:	00001497          	auipc	s1,0x1
     a8a:	98248493          	addi	s1,s1,-1662 # 1408 <malloc+0x1ec>
     a8e:	4589                	li	a1,2
     a90:	8526                	mv	a0,s1
     a92:	00000097          	auipc	ra,0x0
     a96:	38c080e7          	jalr	908(ra) # e1e <open>
     a9a:	00054963          	bltz	a0,aac <main+0x38>
    if(fd >= 3){
     a9e:	4789                	li	a5,2
     aa0:	fea7d7e3          	bge	a5,a0,a8e <main+0x1a>
      close(fd);
     aa4:	00000097          	auipc	ra,0x0
     aa8:	362080e7          	jalr	866(ra) # e06 <close>
  while(getcmd(buf, sizeof(buf)) >= 0){
     aac:	00001497          	auipc	s1,0x1
     ab0:	9dc48493          	addi	s1,s1,-1572 # 1488 <buf.1135>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     ab4:	06300913          	li	s2,99
     ab8:	02000993          	li	s3,32
      if(chdir(buf+3) < 0)
     abc:	00001a17          	auipc	s4,0x1
     ac0:	9cfa0a13          	addi	s4,s4,-1585 # 148b <buf.1135+0x3>
        fprintf(2, "cannot cd %s\n", buf+3);
     ac4:	00001a97          	auipc	s5,0x1
     ac8:	94ca8a93          	addi	s5,s5,-1716 # 1410 <malloc+0x1f4>
     acc:	a819                	j	ae2 <main+0x6e>
    if(fork1() == 0)
     ace:	fffff097          	auipc	ra,0xfffff
     ad2:	5ac080e7          	jalr	1452(ra) # 7a <fork1>
     ad6:	c925                	beqz	a0,b46 <main+0xd2>
    wait(0);
     ad8:	4501                	li	a0,0
     ada:	00000097          	auipc	ra,0x0
     ade:	30c080e7          	jalr	780(ra) # de6 <wait>
  while(getcmd(buf, sizeof(buf)) >= 0){
     ae2:	06400593          	li	a1,100
     ae6:	8526                	mv	a0,s1
     ae8:	fffff097          	auipc	ra,0xfffff
     aec:	518080e7          	jalr	1304(ra) # 0 <getcmd>
     af0:	06054763          	bltz	a0,b5e <main+0xea>
    if(buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' '){
     af4:	0004c783          	lbu	a5,0(s1)
     af8:	fd279be3          	bne	a5,s2,ace <main+0x5a>
     afc:	0014c703          	lbu	a4,1(s1)
     b00:	06400793          	li	a5,100
     b04:	fcf715e3          	bne	a4,a5,ace <main+0x5a>
     b08:	0024c783          	lbu	a5,2(s1)
     b0c:	fd3791e3          	bne	a5,s3,ace <main+0x5a>
      buf[strlen(buf)-1] = 0;  // chop \n
     b10:	8526                	mv	a0,s1
     b12:	00000097          	auipc	ra,0x0
     b16:	09e080e7          	jalr	158(ra) # bb0 <strlen>
     b1a:	fff5079b          	addiw	a5,a0,-1
     b1e:	1782                	slli	a5,a5,0x20
     b20:	9381                	srli	a5,a5,0x20
     b22:	97a6                	add	a5,a5,s1
     b24:	00078023          	sb	zero,0(a5)
      if(chdir(buf+3) < 0)
     b28:	8552                	mv	a0,s4
     b2a:	00000097          	auipc	ra,0x0
     b2e:	324080e7          	jalr	804(ra) # e4e <chdir>
     b32:	fa0558e3          	bgez	a0,ae2 <main+0x6e>
        fprintf(2, "cannot cd %s\n", buf+3);
     b36:	8652                	mv	a2,s4
     b38:	85d6                	mv	a1,s5
     b3a:	4509                	li	a0,2
     b3c:	00000097          	auipc	ra,0x0
     b40:	5f4080e7          	jalr	1524(ra) # 1130 <fprintf>
     b44:	bf79                	j	ae2 <main+0x6e>
      runcmd(parsecmd(buf));
     b46:	00001517          	auipc	a0,0x1
     b4a:	94250513          	addi	a0,a0,-1726 # 1488 <buf.1135>
     b4e:	00000097          	auipc	ra,0x0
     b52:	e9e080e7          	jalr	-354(ra) # 9ec <parsecmd>
     b56:	fffff097          	auipc	ra,0xfffff
     b5a:	552080e7          	jalr	1362(ra) # a8 <runcmd>
  exit(0);
     b5e:	4501                	li	a0,0
     b60:	00000097          	auipc	ra,0x0
     b64:	27e080e7          	jalr	638(ra) # dde <exit>

0000000000000b68 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     b68:	1141                	addi	sp,sp,-16
     b6a:	e422                	sd	s0,8(sp)
     b6c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     b6e:	87aa                	mv	a5,a0
     b70:	0585                	addi	a1,a1,1
     b72:	0785                	addi	a5,a5,1
     b74:	fff5c703          	lbu	a4,-1(a1)
     b78:	fee78fa3          	sb	a4,-1(a5)
     b7c:	fb75                	bnez	a4,b70 <strcpy+0x8>
    ;
  return os;
}
     b7e:	6422                	ld	s0,8(sp)
     b80:	0141                	addi	sp,sp,16
     b82:	8082                	ret

0000000000000b84 <strcmp>:

int
strcmp(const char *p, const char *q)
{
     b84:	1141                	addi	sp,sp,-16
     b86:	e422                	sd	s0,8(sp)
     b88:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     b8a:	00054783          	lbu	a5,0(a0)
     b8e:	cb91                	beqz	a5,ba2 <strcmp+0x1e>
     b90:	0005c703          	lbu	a4,0(a1)
     b94:	00f71763          	bne	a4,a5,ba2 <strcmp+0x1e>
    p++, q++;
     b98:	0505                	addi	a0,a0,1
     b9a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     b9c:	00054783          	lbu	a5,0(a0)
     ba0:	fbe5                	bnez	a5,b90 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     ba2:	0005c503          	lbu	a0,0(a1)
}
     ba6:	40a7853b          	subw	a0,a5,a0
     baa:	6422                	ld	s0,8(sp)
     bac:	0141                	addi	sp,sp,16
     bae:	8082                	ret

0000000000000bb0 <strlen>:

uint
strlen(const char *s)
{
     bb0:	1141                	addi	sp,sp,-16
     bb2:	e422                	sd	s0,8(sp)
     bb4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     bb6:	00054783          	lbu	a5,0(a0)
     bba:	cf91                	beqz	a5,bd6 <strlen+0x26>
     bbc:	0505                	addi	a0,a0,1
     bbe:	87aa                	mv	a5,a0
     bc0:	4685                	li	a3,1
     bc2:	9e89                	subw	a3,a3,a0
     bc4:	00f6853b          	addw	a0,a3,a5
     bc8:	0785                	addi	a5,a5,1
     bca:	fff7c703          	lbu	a4,-1(a5)
     bce:	fb7d                	bnez	a4,bc4 <strlen+0x14>
    ;
  return n;
}
     bd0:	6422                	ld	s0,8(sp)
     bd2:	0141                	addi	sp,sp,16
     bd4:	8082                	ret
  for(n = 0; s[n]; n++)
     bd6:	4501                	li	a0,0
     bd8:	bfe5                	j	bd0 <strlen+0x20>

0000000000000bda <memset>:

void*
memset(void *dst, int c, uint n)
{
     bda:	1141                	addi	sp,sp,-16
     bdc:	e422                	sd	s0,8(sp)
     bde:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     be0:	ce09                	beqz	a2,bfa <memset+0x20>
     be2:	87aa                	mv	a5,a0
     be4:	fff6071b          	addiw	a4,a2,-1
     be8:	1702                	slli	a4,a4,0x20
     bea:	9301                	srli	a4,a4,0x20
     bec:	0705                	addi	a4,a4,1
     bee:	972a                	add	a4,a4,a0
    cdst[i] = c;
     bf0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     bf4:	0785                	addi	a5,a5,1
     bf6:	fee79de3          	bne	a5,a4,bf0 <memset+0x16>
  }
  return dst;
}
     bfa:	6422                	ld	s0,8(sp)
     bfc:	0141                	addi	sp,sp,16
     bfe:	8082                	ret

0000000000000c00 <strchr>:

char*
strchr(const char *s, char c)
{
     c00:	1141                	addi	sp,sp,-16
     c02:	e422                	sd	s0,8(sp)
     c04:	0800                	addi	s0,sp,16
  for(; *s; s++)
     c06:	00054783          	lbu	a5,0(a0)
     c0a:	cb99                	beqz	a5,c20 <strchr+0x20>
    if(*s == c)
     c0c:	00f58763          	beq	a1,a5,c1a <strchr+0x1a>
  for(; *s; s++)
     c10:	0505                	addi	a0,a0,1
     c12:	00054783          	lbu	a5,0(a0)
     c16:	fbfd                	bnez	a5,c0c <strchr+0xc>
      return (char*)s;
  return 0;
     c18:	4501                	li	a0,0
}
     c1a:	6422                	ld	s0,8(sp)
     c1c:	0141                	addi	sp,sp,16
     c1e:	8082                	ret
  return 0;
     c20:	4501                	li	a0,0
     c22:	bfe5                	j	c1a <strchr+0x1a>

0000000000000c24 <gets>:

char*
gets(char *buf, int max)
{
     c24:	711d                	addi	sp,sp,-96
     c26:	ec86                	sd	ra,88(sp)
     c28:	e8a2                	sd	s0,80(sp)
     c2a:	e4a6                	sd	s1,72(sp)
     c2c:	e0ca                	sd	s2,64(sp)
     c2e:	fc4e                	sd	s3,56(sp)
     c30:	f852                	sd	s4,48(sp)
     c32:	f456                	sd	s5,40(sp)
     c34:	f05a                	sd	s6,32(sp)
     c36:	ec5e                	sd	s7,24(sp)
     c38:	1080                	addi	s0,sp,96
     c3a:	8baa                	mv	s7,a0
     c3c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     c3e:	892a                	mv	s2,a0
     c40:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     c42:	4aa9                	li	s5,10
     c44:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     c46:	89a6                	mv	s3,s1
     c48:	2485                	addiw	s1,s1,1
     c4a:	0344d863          	bge	s1,s4,c7a <gets+0x56>
    cc = read(0, &c, 1);
     c4e:	4605                	li	a2,1
     c50:	faf40593          	addi	a1,s0,-81
     c54:	4501                	li	a0,0
     c56:	00000097          	auipc	ra,0x0
     c5a:	1a0080e7          	jalr	416(ra) # df6 <read>
    if(cc < 1)
     c5e:	00a05e63          	blez	a0,c7a <gets+0x56>
    buf[i++] = c;
     c62:	faf44783          	lbu	a5,-81(s0)
     c66:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     c6a:	01578763          	beq	a5,s5,c78 <gets+0x54>
     c6e:	0905                	addi	s2,s2,1
     c70:	fd679be3          	bne	a5,s6,c46 <gets+0x22>
  for(i=0; i+1 < max; ){
     c74:	89a6                	mv	s3,s1
     c76:	a011                	j	c7a <gets+0x56>
     c78:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     c7a:	99de                	add	s3,s3,s7
     c7c:	00098023          	sb	zero,0(s3)
  return buf;
}
     c80:	855e                	mv	a0,s7
     c82:	60e6                	ld	ra,88(sp)
     c84:	6446                	ld	s0,80(sp)
     c86:	64a6                	ld	s1,72(sp)
     c88:	6906                	ld	s2,64(sp)
     c8a:	79e2                	ld	s3,56(sp)
     c8c:	7a42                	ld	s4,48(sp)
     c8e:	7aa2                	ld	s5,40(sp)
     c90:	7b02                	ld	s6,32(sp)
     c92:	6be2                	ld	s7,24(sp)
     c94:	6125                	addi	sp,sp,96
     c96:	8082                	ret

0000000000000c98 <stat>:

int
stat(const char *n, struct stat *st)
{
     c98:	1101                	addi	sp,sp,-32
     c9a:	ec06                	sd	ra,24(sp)
     c9c:	e822                	sd	s0,16(sp)
     c9e:	e426                	sd	s1,8(sp)
     ca0:	e04a                	sd	s2,0(sp)
     ca2:	1000                	addi	s0,sp,32
     ca4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     ca6:	4581                	li	a1,0
     ca8:	00000097          	auipc	ra,0x0
     cac:	176080e7          	jalr	374(ra) # e1e <open>
  if(fd < 0)
     cb0:	02054563          	bltz	a0,cda <stat+0x42>
     cb4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     cb6:	85ca                	mv	a1,s2
     cb8:	00000097          	auipc	ra,0x0
     cbc:	17e080e7          	jalr	382(ra) # e36 <fstat>
     cc0:	892a                	mv	s2,a0
  close(fd);
     cc2:	8526                	mv	a0,s1
     cc4:	00000097          	auipc	ra,0x0
     cc8:	142080e7          	jalr	322(ra) # e06 <close>
  return r;
}
     ccc:	854a                	mv	a0,s2
     cce:	60e2                	ld	ra,24(sp)
     cd0:	6442                	ld	s0,16(sp)
     cd2:	64a2                	ld	s1,8(sp)
     cd4:	6902                	ld	s2,0(sp)
     cd6:	6105                	addi	sp,sp,32
     cd8:	8082                	ret
    return -1;
     cda:	597d                	li	s2,-1
     cdc:	bfc5                	j	ccc <stat+0x34>

0000000000000cde <atoi>:

int
atoi(const char *s)
{
     cde:	1141                	addi	sp,sp,-16
     ce0:	e422                	sd	s0,8(sp)
     ce2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     ce4:	00054603          	lbu	a2,0(a0)
     ce8:	fd06079b          	addiw	a5,a2,-48
     cec:	0ff7f793          	andi	a5,a5,255
     cf0:	4725                	li	a4,9
     cf2:	02f76963          	bltu	a4,a5,d24 <atoi+0x46>
     cf6:	86aa                	mv	a3,a0
  n = 0;
     cf8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     cfa:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     cfc:	0685                	addi	a3,a3,1
     cfe:	0025179b          	slliw	a5,a0,0x2
     d02:	9fa9                	addw	a5,a5,a0
     d04:	0017979b          	slliw	a5,a5,0x1
     d08:	9fb1                	addw	a5,a5,a2
     d0a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     d0e:	0006c603          	lbu	a2,0(a3)
     d12:	fd06071b          	addiw	a4,a2,-48
     d16:	0ff77713          	andi	a4,a4,255
     d1a:	fee5f1e3          	bgeu	a1,a4,cfc <atoi+0x1e>
  return n;
}
     d1e:	6422                	ld	s0,8(sp)
     d20:	0141                	addi	sp,sp,16
     d22:	8082                	ret
  n = 0;
     d24:	4501                	li	a0,0
     d26:	bfe5                	j	d1e <atoi+0x40>

0000000000000d28 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     d28:	1141                	addi	sp,sp,-16
     d2a:	e422                	sd	s0,8(sp)
     d2c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     d2e:	02b57663          	bgeu	a0,a1,d5a <memmove+0x32>
    while(n-- > 0)
     d32:	02c05163          	blez	a2,d54 <memmove+0x2c>
     d36:	fff6079b          	addiw	a5,a2,-1
     d3a:	1782                	slli	a5,a5,0x20
     d3c:	9381                	srli	a5,a5,0x20
     d3e:	0785                	addi	a5,a5,1
     d40:	97aa                	add	a5,a5,a0
  dst = vdst;
     d42:	872a                	mv	a4,a0
      *dst++ = *src++;
     d44:	0585                	addi	a1,a1,1
     d46:	0705                	addi	a4,a4,1
     d48:	fff5c683          	lbu	a3,-1(a1)
     d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     d50:	fee79ae3          	bne	a5,a4,d44 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     d54:	6422                	ld	s0,8(sp)
     d56:	0141                	addi	sp,sp,16
     d58:	8082                	ret
    dst += n;
     d5a:	00c50733          	add	a4,a0,a2
    src += n;
     d5e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     d60:	fec05ae3          	blez	a2,d54 <memmove+0x2c>
     d64:	fff6079b          	addiw	a5,a2,-1
     d68:	1782                	slli	a5,a5,0x20
     d6a:	9381                	srli	a5,a5,0x20
     d6c:	fff7c793          	not	a5,a5
     d70:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     d72:	15fd                	addi	a1,a1,-1
     d74:	177d                	addi	a4,a4,-1
     d76:	0005c683          	lbu	a3,0(a1)
     d7a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     d7e:	fee79ae3          	bne	a5,a4,d72 <memmove+0x4a>
     d82:	bfc9                	j	d54 <memmove+0x2c>

0000000000000d84 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     d84:	1141                	addi	sp,sp,-16
     d86:	e422                	sd	s0,8(sp)
     d88:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     d8a:	ca05                	beqz	a2,dba <memcmp+0x36>
     d8c:	fff6069b          	addiw	a3,a2,-1
     d90:	1682                	slli	a3,a3,0x20
     d92:	9281                	srli	a3,a3,0x20
     d94:	0685                	addi	a3,a3,1
     d96:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     d98:	00054783          	lbu	a5,0(a0)
     d9c:	0005c703          	lbu	a4,0(a1)
     da0:	00e79863          	bne	a5,a4,db0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     da4:	0505                	addi	a0,a0,1
    p2++;
     da6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     da8:	fed518e3          	bne	a0,a3,d98 <memcmp+0x14>
  }
  return 0;
     dac:	4501                	li	a0,0
     dae:	a019                	j	db4 <memcmp+0x30>
      return *p1 - *p2;
     db0:	40e7853b          	subw	a0,a5,a4
}
     db4:	6422                	ld	s0,8(sp)
     db6:	0141                	addi	sp,sp,16
     db8:	8082                	ret
  return 0;
     dba:	4501                	li	a0,0
     dbc:	bfe5                	j	db4 <memcmp+0x30>

0000000000000dbe <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     dbe:	1141                	addi	sp,sp,-16
     dc0:	e406                	sd	ra,8(sp)
     dc2:	e022                	sd	s0,0(sp)
     dc4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     dc6:	00000097          	auipc	ra,0x0
     dca:	f62080e7          	jalr	-158(ra) # d28 <memmove>
}
     dce:	60a2                	ld	ra,8(sp)
     dd0:	6402                	ld	s0,0(sp)
     dd2:	0141                	addi	sp,sp,16
     dd4:	8082                	ret

0000000000000dd6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     dd6:	4885                	li	a7,1
 ecall
     dd8:	00000073          	ecall
 ret
     ddc:	8082                	ret

0000000000000dde <exit>:
.global exit
exit:
 li a7, SYS_exit
     dde:	4889                	li	a7,2
 ecall
     de0:	00000073          	ecall
 ret
     de4:	8082                	ret

0000000000000de6 <wait>:
.global wait
wait:
 li a7, SYS_wait
     de6:	488d                	li	a7,3
 ecall
     de8:	00000073          	ecall
 ret
     dec:	8082                	ret

0000000000000dee <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     dee:	4891                	li	a7,4
 ecall
     df0:	00000073          	ecall
 ret
     df4:	8082                	ret

0000000000000df6 <read>:
.global read
read:
 li a7, SYS_read
     df6:	4895                	li	a7,5
 ecall
     df8:	00000073          	ecall
 ret
     dfc:	8082                	ret

0000000000000dfe <write>:
.global write
write:
 li a7, SYS_write
     dfe:	48c1                	li	a7,16
 ecall
     e00:	00000073          	ecall
 ret
     e04:	8082                	ret

0000000000000e06 <close>:
.global close
close:
 li a7, SYS_close
     e06:	48d5                	li	a7,21
 ecall
     e08:	00000073          	ecall
 ret
     e0c:	8082                	ret

0000000000000e0e <kill>:
.global kill
kill:
 li a7, SYS_kill
     e0e:	4899                	li	a7,6
 ecall
     e10:	00000073          	ecall
 ret
     e14:	8082                	ret

0000000000000e16 <exec>:
.global exec
exec:
 li a7, SYS_exec
     e16:	489d                	li	a7,7
 ecall
     e18:	00000073          	ecall
 ret
     e1c:	8082                	ret

0000000000000e1e <open>:
.global open
open:
 li a7, SYS_open
     e1e:	48bd                	li	a7,15
 ecall
     e20:	00000073          	ecall
 ret
     e24:	8082                	ret

0000000000000e26 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     e26:	48c5                	li	a7,17
 ecall
     e28:	00000073          	ecall
 ret
     e2c:	8082                	ret

0000000000000e2e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     e2e:	48c9                	li	a7,18
 ecall
     e30:	00000073          	ecall
 ret
     e34:	8082                	ret

0000000000000e36 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     e36:	48a1                	li	a7,8
 ecall
     e38:	00000073          	ecall
 ret
     e3c:	8082                	ret

0000000000000e3e <link>:
.global link
link:
 li a7, SYS_link
     e3e:	48cd                	li	a7,19
 ecall
     e40:	00000073          	ecall
 ret
     e44:	8082                	ret

0000000000000e46 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     e46:	48d1                	li	a7,20
 ecall
     e48:	00000073          	ecall
 ret
     e4c:	8082                	ret

0000000000000e4e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     e4e:	48a5                	li	a7,9
 ecall
     e50:	00000073          	ecall
 ret
     e54:	8082                	ret

0000000000000e56 <dup>:
.global dup
dup:
 li a7, SYS_dup
     e56:	48a9                	li	a7,10
 ecall
     e58:	00000073          	ecall
 ret
     e5c:	8082                	ret

0000000000000e5e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     e5e:	48ad                	li	a7,11
 ecall
     e60:	00000073          	ecall
 ret
     e64:	8082                	ret

0000000000000e66 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     e66:	48b1                	li	a7,12
 ecall
     e68:	00000073          	ecall
 ret
     e6c:	8082                	ret

0000000000000e6e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     e6e:	48b5                	li	a7,13
 ecall
     e70:	00000073          	ecall
 ret
     e74:	8082                	ret

0000000000000e76 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     e76:	48b9                	li	a7,14
 ecall
     e78:	00000073          	ecall
 ret
     e7c:	8082                	ret

0000000000000e7e <mmtrace>:
.global mmtrace
mmtrace:
 li a7, SYS_mmtrace
     e7e:	48d9                	li	a7,22
 ecall
     e80:	00000073          	ecall
 ret
     e84:	8082                	ret

0000000000000e86 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     e86:	1101                	addi	sp,sp,-32
     e88:	ec06                	sd	ra,24(sp)
     e8a:	e822                	sd	s0,16(sp)
     e8c:	1000                	addi	s0,sp,32
     e8e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     e92:	4605                	li	a2,1
     e94:	fef40593          	addi	a1,s0,-17
     e98:	00000097          	auipc	ra,0x0
     e9c:	f66080e7          	jalr	-154(ra) # dfe <write>
}
     ea0:	60e2                	ld	ra,24(sp)
     ea2:	6442                	ld	s0,16(sp)
     ea4:	6105                	addi	sp,sp,32
     ea6:	8082                	ret

0000000000000ea8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     ea8:	7139                	addi	sp,sp,-64
     eaa:	fc06                	sd	ra,56(sp)
     eac:	f822                	sd	s0,48(sp)
     eae:	f426                	sd	s1,40(sp)
     eb0:	f04a                	sd	s2,32(sp)
     eb2:	ec4e                	sd	s3,24(sp)
     eb4:	0080                	addi	s0,sp,64
     eb6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
     eb8:	c299                	beqz	a3,ebe <printint+0x16>
     eba:	0805c863          	bltz	a1,f4a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
     ebe:	2581                	sext.w	a1,a1
  neg = 0;
     ec0:	4881                	li	a7,0
     ec2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
     ec6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
     ec8:	2601                	sext.w	a2,a2
     eca:	00000517          	auipc	a0,0x0
     ece:	58e50513          	addi	a0,a0,1422 # 1458 <digits>
     ed2:	883a                	mv	a6,a4
     ed4:	2705                	addiw	a4,a4,1
     ed6:	02c5f7bb          	remuw	a5,a1,a2
     eda:	1782                	slli	a5,a5,0x20
     edc:	9381                	srli	a5,a5,0x20
     ede:	97aa                	add	a5,a5,a0
     ee0:	0007c783          	lbu	a5,0(a5)
     ee4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
     ee8:	0005879b          	sext.w	a5,a1
     eec:	02c5d5bb          	divuw	a1,a1,a2
     ef0:	0685                	addi	a3,a3,1
     ef2:	fec7f0e3          	bgeu	a5,a2,ed2 <printint+0x2a>
  if(neg)
     ef6:	00088b63          	beqz	a7,f0c <printint+0x64>
    buf[i++] = '-';
     efa:	fd040793          	addi	a5,s0,-48
     efe:	973e                	add	a4,a4,a5
     f00:	02d00793          	li	a5,45
     f04:	fef70823          	sb	a5,-16(a4)
     f08:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
     f0c:	02e05863          	blez	a4,f3c <printint+0x94>
     f10:	fc040793          	addi	a5,s0,-64
     f14:	00e78933          	add	s2,a5,a4
     f18:	fff78993          	addi	s3,a5,-1
     f1c:	99ba                	add	s3,s3,a4
     f1e:	377d                	addiw	a4,a4,-1
     f20:	1702                	slli	a4,a4,0x20
     f22:	9301                	srli	a4,a4,0x20
     f24:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
     f28:	fff94583          	lbu	a1,-1(s2)
     f2c:	8526                	mv	a0,s1
     f2e:	00000097          	auipc	ra,0x0
     f32:	f58080e7          	jalr	-168(ra) # e86 <putc>
  while(--i >= 0)
     f36:	197d                	addi	s2,s2,-1
     f38:	ff3918e3          	bne	s2,s3,f28 <printint+0x80>
}
     f3c:	70e2                	ld	ra,56(sp)
     f3e:	7442                	ld	s0,48(sp)
     f40:	74a2                	ld	s1,40(sp)
     f42:	7902                	ld	s2,32(sp)
     f44:	69e2                	ld	s3,24(sp)
     f46:	6121                	addi	sp,sp,64
     f48:	8082                	ret
    x = -xx;
     f4a:	40b005bb          	negw	a1,a1
    neg = 1;
     f4e:	4885                	li	a7,1
    x = -xx;
     f50:	bf8d                	j	ec2 <printint+0x1a>

0000000000000f52 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
     f52:	7119                	addi	sp,sp,-128
     f54:	fc86                	sd	ra,120(sp)
     f56:	f8a2                	sd	s0,112(sp)
     f58:	f4a6                	sd	s1,104(sp)
     f5a:	f0ca                	sd	s2,96(sp)
     f5c:	ecce                	sd	s3,88(sp)
     f5e:	e8d2                	sd	s4,80(sp)
     f60:	e4d6                	sd	s5,72(sp)
     f62:	e0da                	sd	s6,64(sp)
     f64:	fc5e                	sd	s7,56(sp)
     f66:	f862                	sd	s8,48(sp)
     f68:	f466                	sd	s9,40(sp)
     f6a:	f06a                	sd	s10,32(sp)
     f6c:	ec6e                	sd	s11,24(sp)
     f6e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
     f70:	0005c903          	lbu	s2,0(a1)
     f74:	18090f63          	beqz	s2,1112 <vprintf+0x1c0>
     f78:	8aaa                	mv	s5,a0
     f7a:	8b32                	mv	s6,a2
     f7c:	00158493          	addi	s1,a1,1
  state = 0;
     f80:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
     f82:	02500a13          	li	s4,37
      if(c == 'd'){
     f86:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
     f8a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
     f8e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
     f92:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
     f96:	00000b97          	auipc	s7,0x0
     f9a:	4c2b8b93          	addi	s7,s7,1218 # 1458 <digits>
     f9e:	a839                	j	fbc <vprintf+0x6a>
        putc(fd, c);
     fa0:	85ca                	mv	a1,s2
     fa2:	8556                	mv	a0,s5
     fa4:	00000097          	auipc	ra,0x0
     fa8:	ee2080e7          	jalr	-286(ra) # e86 <putc>
     fac:	a019                	j	fb2 <vprintf+0x60>
    } else if(state == '%'){
     fae:	01498f63          	beq	s3,s4,fcc <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
     fb2:	0485                	addi	s1,s1,1
     fb4:	fff4c903          	lbu	s2,-1(s1)
     fb8:	14090d63          	beqz	s2,1112 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
     fbc:	0009079b          	sext.w	a5,s2
    if(state == 0){
     fc0:	fe0997e3          	bnez	s3,fae <vprintf+0x5c>
      if(c == '%'){
     fc4:	fd479ee3          	bne	a5,s4,fa0 <vprintf+0x4e>
        state = '%';
     fc8:	89be                	mv	s3,a5
     fca:	b7e5                	j	fb2 <vprintf+0x60>
      if(c == 'd'){
     fcc:	05878063          	beq	a5,s8,100c <vprintf+0xba>
      } else if(c == 'l') {
     fd0:	05978c63          	beq	a5,s9,1028 <vprintf+0xd6>
      } else if(c == 'x') {
     fd4:	07a78863          	beq	a5,s10,1044 <vprintf+0xf2>
      } else if(c == 'p') {
     fd8:	09b78463          	beq	a5,s11,1060 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
     fdc:	07300713          	li	a4,115
     fe0:	0ce78663          	beq	a5,a4,10ac <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
     fe4:	06300713          	li	a4,99
     fe8:	0ee78e63          	beq	a5,a4,10e4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
     fec:	11478863          	beq	a5,s4,10fc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
     ff0:	85d2                	mv	a1,s4
     ff2:	8556                	mv	a0,s5
     ff4:	00000097          	auipc	ra,0x0
     ff8:	e92080e7          	jalr	-366(ra) # e86 <putc>
        putc(fd, c);
     ffc:	85ca                	mv	a1,s2
     ffe:	8556                	mv	a0,s5
    1000:	00000097          	auipc	ra,0x0
    1004:	e86080e7          	jalr	-378(ra) # e86 <putc>
      }
      state = 0;
    1008:	4981                	li	s3,0
    100a:	b765                	j	fb2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    100c:	008b0913          	addi	s2,s6,8
    1010:	4685                	li	a3,1
    1012:	4629                	li	a2,10
    1014:	000b2583          	lw	a1,0(s6)
    1018:	8556                	mv	a0,s5
    101a:	00000097          	auipc	ra,0x0
    101e:	e8e080e7          	jalr	-370(ra) # ea8 <printint>
    1022:	8b4a                	mv	s6,s2
      state = 0;
    1024:	4981                	li	s3,0
    1026:	b771                	j	fb2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    1028:	008b0913          	addi	s2,s6,8
    102c:	4681                	li	a3,0
    102e:	4629                	li	a2,10
    1030:	000b2583          	lw	a1,0(s6)
    1034:	8556                	mv	a0,s5
    1036:	00000097          	auipc	ra,0x0
    103a:	e72080e7          	jalr	-398(ra) # ea8 <printint>
    103e:	8b4a                	mv	s6,s2
      state = 0;
    1040:	4981                	li	s3,0
    1042:	bf85                	j	fb2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    1044:	008b0913          	addi	s2,s6,8
    1048:	4681                	li	a3,0
    104a:	4641                	li	a2,16
    104c:	000b2583          	lw	a1,0(s6)
    1050:	8556                	mv	a0,s5
    1052:	00000097          	auipc	ra,0x0
    1056:	e56080e7          	jalr	-426(ra) # ea8 <printint>
    105a:	8b4a                	mv	s6,s2
      state = 0;
    105c:	4981                	li	s3,0
    105e:	bf91                	j	fb2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    1060:	008b0793          	addi	a5,s6,8
    1064:	f8f43423          	sd	a5,-120(s0)
    1068:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    106c:	03000593          	li	a1,48
    1070:	8556                	mv	a0,s5
    1072:	00000097          	auipc	ra,0x0
    1076:	e14080e7          	jalr	-492(ra) # e86 <putc>
  putc(fd, 'x');
    107a:	85ea                	mv	a1,s10
    107c:	8556                	mv	a0,s5
    107e:	00000097          	auipc	ra,0x0
    1082:	e08080e7          	jalr	-504(ra) # e86 <putc>
    1086:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    1088:	03c9d793          	srli	a5,s3,0x3c
    108c:	97de                	add	a5,a5,s7
    108e:	0007c583          	lbu	a1,0(a5)
    1092:	8556                	mv	a0,s5
    1094:	00000097          	auipc	ra,0x0
    1098:	df2080e7          	jalr	-526(ra) # e86 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    109c:	0992                	slli	s3,s3,0x4
    109e:	397d                	addiw	s2,s2,-1
    10a0:	fe0914e3          	bnez	s2,1088 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    10a4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    10a8:	4981                	li	s3,0
    10aa:	b721                	j	fb2 <vprintf+0x60>
        s = va_arg(ap, char*);
    10ac:	008b0993          	addi	s3,s6,8
    10b0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    10b4:	02090163          	beqz	s2,10d6 <vprintf+0x184>
        while(*s != 0){
    10b8:	00094583          	lbu	a1,0(s2)
    10bc:	c9a1                	beqz	a1,110c <vprintf+0x1ba>
          putc(fd, *s);
    10be:	8556                	mv	a0,s5
    10c0:	00000097          	auipc	ra,0x0
    10c4:	dc6080e7          	jalr	-570(ra) # e86 <putc>
          s++;
    10c8:	0905                	addi	s2,s2,1
        while(*s != 0){
    10ca:	00094583          	lbu	a1,0(s2)
    10ce:	f9e5                	bnez	a1,10be <vprintf+0x16c>
        s = va_arg(ap, char*);
    10d0:	8b4e                	mv	s6,s3
      state = 0;
    10d2:	4981                	li	s3,0
    10d4:	bdf9                	j	fb2 <vprintf+0x60>
          s = "(null)";
    10d6:	00000917          	auipc	s2,0x0
    10da:	37a90913          	addi	s2,s2,890 # 1450 <malloc+0x234>
        while(*s != 0){
    10de:	02800593          	li	a1,40
    10e2:	bff1                	j	10be <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    10e4:	008b0913          	addi	s2,s6,8
    10e8:	000b4583          	lbu	a1,0(s6)
    10ec:	8556                	mv	a0,s5
    10ee:	00000097          	auipc	ra,0x0
    10f2:	d98080e7          	jalr	-616(ra) # e86 <putc>
    10f6:	8b4a                	mv	s6,s2
      state = 0;
    10f8:	4981                	li	s3,0
    10fa:	bd65                	j	fb2 <vprintf+0x60>
        putc(fd, c);
    10fc:	85d2                	mv	a1,s4
    10fe:	8556                	mv	a0,s5
    1100:	00000097          	auipc	ra,0x0
    1104:	d86080e7          	jalr	-634(ra) # e86 <putc>
      state = 0;
    1108:	4981                	li	s3,0
    110a:	b565                	j	fb2 <vprintf+0x60>
        s = va_arg(ap, char*);
    110c:	8b4e                	mv	s6,s3
      state = 0;
    110e:	4981                	li	s3,0
    1110:	b54d                	j	fb2 <vprintf+0x60>
    }
  }
}
    1112:	70e6                	ld	ra,120(sp)
    1114:	7446                	ld	s0,112(sp)
    1116:	74a6                	ld	s1,104(sp)
    1118:	7906                	ld	s2,96(sp)
    111a:	69e6                	ld	s3,88(sp)
    111c:	6a46                	ld	s4,80(sp)
    111e:	6aa6                	ld	s5,72(sp)
    1120:	6b06                	ld	s6,64(sp)
    1122:	7be2                	ld	s7,56(sp)
    1124:	7c42                	ld	s8,48(sp)
    1126:	7ca2                	ld	s9,40(sp)
    1128:	7d02                	ld	s10,32(sp)
    112a:	6de2                	ld	s11,24(sp)
    112c:	6109                	addi	sp,sp,128
    112e:	8082                	ret

0000000000001130 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    1130:	715d                	addi	sp,sp,-80
    1132:	ec06                	sd	ra,24(sp)
    1134:	e822                	sd	s0,16(sp)
    1136:	1000                	addi	s0,sp,32
    1138:	e010                	sd	a2,0(s0)
    113a:	e414                	sd	a3,8(s0)
    113c:	e818                	sd	a4,16(s0)
    113e:	ec1c                	sd	a5,24(s0)
    1140:	03043023          	sd	a6,32(s0)
    1144:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    1148:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    114c:	8622                	mv	a2,s0
    114e:	00000097          	auipc	ra,0x0
    1152:	e04080e7          	jalr	-508(ra) # f52 <vprintf>
}
    1156:	60e2                	ld	ra,24(sp)
    1158:	6442                	ld	s0,16(sp)
    115a:	6161                	addi	sp,sp,80
    115c:	8082                	ret

000000000000115e <printf>:

void
printf(const char *fmt, ...)
{
    115e:	711d                	addi	sp,sp,-96
    1160:	ec06                	sd	ra,24(sp)
    1162:	e822                	sd	s0,16(sp)
    1164:	1000                	addi	s0,sp,32
    1166:	e40c                	sd	a1,8(s0)
    1168:	e810                	sd	a2,16(s0)
    116a:	ec14                	sd	a3,24(s0)
    116c:	f018                	sd	a4,32(s0)
    116e:	f41c                	sd	a5,40(s0)
    1170:	03043823          	sd	a6,48(s0)
    1174:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    1178:	00840613          	addi	a2,s0,8
    117c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    1180:	85aa                	mv	a1,a0
    1182:	4505                	li	a0,1
    1184:	00000097          	auipc	ra,0x0
    1188:	dce080e7          	jalr	-562(ra) # f52 <vprintf>
}
    118c:	60e2                	ld	ra,24(sp)
    118e:	6442                	ld	s0,16(sp)
    1190:	6125                	addi	sp,sp,96
    1192:	8082                	ret

0000000000001194 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    1194:	1141                	addi	sp,sp,-16
    1196:	e422                	sd	s0,8(sp)
    1198:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    119a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    119e:	00000797          	auipc	a5,0x0
    11a2:	2e27b783          	ld	a5,738(a5) # 1480 <freep>
    11a6:	a805                	j	11d6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    11a8:	4618                	lw	a4,8(a2)
    11aa:	9db9                	addw	a1,a1,a4
    11ac:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    11b0:	6398                	ld	a4,0(a5)
    11b2:	6318                	ld	a4,0(a4)
    11b4:	fee53823          	sd	a4,-16(a0)
    11b8:	a091                	j	11fc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    11ba:	ff852703          	lw	a4,-8(a0)
    11be:	9e39                	addw	a2,a2,a4
    11c0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    11c2:	ff053703          	ld	a4,-16(a0)
    11c6:	e398                	sd	a4,0(a5)
    11c8:	a099                	j	120e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    11ca:	6398                	ld	a4,0(a5)
    11cc:	00e7e463          	bltu	a5,a4,11d4 <free+0x40>
    11d0:	00e6ea63          	bltu	a3,a4,11e4 <free+0x50>
{
    11d4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    11d6:	fed7fae3          	bgeu	a5,a3,11ca <free+0x36>
    11da:	6398                	ld	a4,0(a5)
    11dc:	00e6e463          	bltu	a3,a4,11e4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    11e0:	fee7eae3          	bltu	a5,a4,11d4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    11e4:	ff852583          	lw	a1,-8(a0)
    11e8:	6390                	ld	a2,0(a5)
    11ea:	02059713          	slli	a4,a1,0x20
    11ee:	9301                	srli	a4,a4,0x20
    11f0:	0712                	slli	a4,a4,0x4
    11f2:	9736                	add	a4,a4,a3
    11f4:	fae60ae3          	beq	a2,a4,11a8 <free+0x14>
    bp->s.ptr = p->s.ptr;
    11f8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    11fc:	4790                	lw	a2,8(a5)
    11fe:	02061713          	slli	a4,a2,0x20
    1202:	9301                	srli	a4,a4,0x20
    1204:	0712                	slli	a4,a4,0x4
    1206:	973e                	add	a4,a4,a5
    1208:	fae689e3          	beq	a3,a4,11ba <free+0x26>
  } else
    p->s.ptr = bp;
    120c:	e394                	sd	a3,0(a5)
  freep = p;
    120e:	00000717          	auipc	a4,0x0
    1212:	26f73923          	sd	a5,626(a4) # 1480 <freep>
}
    1216:	6422                	ld	s0,8(sp)
    1218:	0141                	addi	sp,sp,16
    121a:	8082                	ret

000000000000121c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    121c:	7139                	addi	sp,sp,-64
    121e:	fc06                	sd	ra,56(sp)
    1220:	f822                	sd	s0,48(sp)
    1222:	f426                	sd	s1,40(sp)
    1224:	f04a                	sd	s2,32(sp)
    1226:	ec4e                	sd	s3,24(sp)
    1228:	e852                	sd	s4,16(sp)
    122a:	e456                	sd	s5,8(sp)
    122c:	e05a                	sd	s6,0(sp)
    122e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    1230:	02051493          	slli	s1,a0,0x20
    1234:	9081                	srli	s1,s1,0x20
    1236:	04bd                	addi	s1,s1,15
    1238:	8091                	srli	s1,s1,0x4
    123a:	0014899b          	addiw	s3,s1,1
    123e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    1240:	00000517          	auipc	a0,0x0
    1244:	24053503          	ld	a0,576(a0) # 1480 <freep>
    1248:	c515                	beqz	a0,1274 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    124a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    124c:	4798                	lw	a4,8(a5)
    124e:	02977f63          	bgeu	a4,s1,128c <malloc+0x70>
    1252:	8a4e                	mv	s4,s3
    1254:	0009871b          	sext.w	a4,s3
    1258:	6685                	lui	a3,0x1
    125a:	00d77363          	bgeu	a4,a3,1260 <malloc+0x44>
    125e:	6a05                	lui	s4,0x1
    1260:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    1264:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    1268:	00000917          	auipc	s2,0x0
    126c:	21890913          	addi	s2,s2,536 # 1480 <freep>
  if(p == (char*)-1)
    1270:	5afd                	li	s5,-1
    1272:	a88d                	j	12e4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
    1274:	00000797          	auipc	a5,0x0
    1278:	27c78793          	addi	a5,a5,636 # 14f0 <base>
    127c:	00000717          	auipc	a4,0x0
    1280:	20f73223          	sd	a5,516(a4) # 1480 <freep>
    1284:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    1286:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    128a:	b7e1                	j	1252 <malloc+0x36>
      if(p->s.size == nunits)
    128c:	02e48b63          	beq	s1,a4,12c2 <malloc+0xa6>
        p->s.size -= nunits;
    1290:	4137073b          	subw	a4,a4,s3
    1294:	c798                	sw	a4,8(a5)
        p += p->s.size;
    1296:	1702                	slli	a4,a4,0x20
    1298:	9301                	srli	a4,a4,0x20
    129a:	0712                	slli	a4,a4,0x4
    129c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    129e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    12a2:	00000717          	auipc	a4,0x0
    12a6:	1ca73f23          	sd	a0,478(a4) # 1480 <freep>
      return (void*)(p + 1);
    12aa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    12ae:	70e2                	ld	ra,56(sp)
    12b0:	7442                	ld	s0,48(sp)
    12b2:	74a2                	ld	s1,40(sp)
    12b4:	7902                	ld	s2,32(sp)
    12b6:	69e2                	ld	s3,24(sp)
    12b8:	6a42                	ld	s4,16(sp)
    12ba:	6aa2                	ld	s5,8(sp)
    12bc:	6b02                	ld	s6,0(sp)
    12be:	6121                	addi	sp,sp,64
    12c0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    12c2:	6398                	ld	a4,0(a5)
    12c4:	e118                	sd	a4,0(a0)
    12c6:	bff1                	j	12a2 <malloc+0x86>
  hp->s.size = nu;
    12c8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    12cc:	0541                	addi	a0,a0,16
    12ce:	00000097          	auipc	ra,0x0
    12d2:	ec6080e7          	jalr	-314(ra) # 1194 <free>
  return freep;
    12d6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    12da:	d971                	beqz	a0,12ae <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    12dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    12de:	4798                	lw	a4,8(a5)
    12e0:	fa9776e3          	bgeu	a4,s1,128c <malloc+0x70>
    if(p == freep)
    12e4:	00093703          	ld	a4,0(s2)
    12e8:	853e                	mv	a0,a5
    12ea:	fef719e3          	bne	a4,a5,12dc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
    12ee:	8552                	mv	a0,s4
    12f0:	00000097          	auipc	ra,0x0
    12f4:	b76080e7          	jalr	-1162(ra) # e66 <sbrk>
  if(p == (char*)-1)
    12f8:	fd5518e3          	bne	a0,s5,12c8 <malloc+0xac>
        return 0;
    12fc:	4501                	li	a0,0
    12fe:	bf45                	j	12ae <malloc+0x92>
