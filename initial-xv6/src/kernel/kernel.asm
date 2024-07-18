
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8d070713          	addi	a4,a4,-1840 # 80008920 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	f7e78793          	addi	a5,a5,-130 # 80005fe0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbc5f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	42e080e7          	jalr	1070(ra) # 80002558 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	1da080e7          	jalr	474(ra) # 800023a2 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f18080e7          	jalr	-232(ra) # 800020ee <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	2f0080e7          	jalr	752(ra) # 80002502 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d0c080e7          	jalr	-756(ra) # 80002152 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	59078793          	addi	a5,a5,1424 # 80021a08 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
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
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
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
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07aa23          	sw	zero,1492(a5) # 80010b20 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	36f72023          	sw	a5,864(a4) # 800088e0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	564dad83          	lw	s11,1380(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	50e50513          	addi	a0,a0,1294 # 80010b08 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3b050513          	addi	a0,a0,944 # 80010b08 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	39448493          	addi	s1,s1,916 # 80010b08 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	35450513          	addi	a0,a0,852 # 80010b28 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0e07a783          	lw	a5,224(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0b07b783          	ld	a5,176(a5) # 800088e8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0b073703          	ld	a4,176(a4) # 800088f0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2c6a0a13          	addi	s4,s4,710 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	07e48493          	addi	s1,s1,126 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	07e98993          	addi	s3,s3,126 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	8be080e7          	jalr	-1858(ra) # 80002152 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	25850513          	addi	a0,a0,600 # 80010b28 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	0007a783          	lw	a5,0(a5) # 800088e0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	00673703          	ld	a4,6(a4) # 800088f0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	ff67b783          	ld	a5,-10(a5) # 800088e8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	22a98993          	addi	s3,s3,554 # 80010b28 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fe248493          	addi	s1,s1,-30 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fe290913          	addi	s2,s2,-30 # 800088f0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	7d0080e7          	jalr	2000(ra) # 800020ee <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1f448493          	addi	s1,s1,500 # 80010b28 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	fae7b423          	sd	a4,-88(a5) # 800088f0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	16e48493          	addi	s1,s1,366 # 80010b28 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	1a478793          	addi	a5,a5,420 # 80022ba0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	14490913          	addi	s2,s2,324 # 80010b60 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	0d250513          	addi	a0,a0,210 # 80022ba0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc461>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	a5a080e7          	jalr	-1446(ra) # 80002918 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	15a080e7          	jalr	346(ra) # 80006020 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	ff8080e7          	jalr	-8(ra) # 80001ec6 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	9ba080e7          	jalr	-1606(ra) # 800028f0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	9da080e7          	jalr	-1574(ra) # 80002918 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	0c4080e7          	jalr	196(ra) # 8000600a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	0d2080e7          	jalr	210(ra) # 80006020 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	258080e7          	jalr	600(ra) # 800031ae <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	8f8080e7          	jalr	-1800(ra) # 80003856 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	89e080e7          	jalr	-1890(ra) # 80004804 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	1ba080e7          	jalr	442(ra) # 80006128 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d32080e7          	jalr	-718(ra) # 80001ca8 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc457>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
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
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc460>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	76448493          	addi	s1,s1,1892 # 80010fb0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	f4aa0a13          	addi	s4,s4,-182 # 800177b0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8595                	srai	a1,a1,0x5
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	1a048493          	addi	s1,s1,416
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	29850513          	addi	a0,a0,664 # 80010b80 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	29850513          	addi	a0,a0,664 # 80010b98 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6a048493          	addi	s1,s1,1696 # 80010fb0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	e7e98993          	addi	s3,s3,-386 # 800177b0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8795                	srai	a5,a5,0x5
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	ecbc                	sd	a5,88(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a048493          	addi	s1,s1,416
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	21450513          	addi	a0,a0,532 # 80010bb0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1bc70713          	addi	a4,a4,444 # 80010b80 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e747a783          	lw	a5,-396(a5) # 80008870 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	f2a080e7          	jalr	-214(ra) # 80002930 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407ad23          	sw	zero,-422(a5) # 80008870 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	db6080e7          	jalr	-586(ra) # 800037d6 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	14a90913          	addi	s2,s2,330 # 80010b80 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e2c78793          	addi	a5,a5,-468 # 80008874 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	07093683          	ld	a3,112(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	7928                	ld	a0,112(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0604b823          	sd	zero,112(s1)
  if (p->pagetable)
    80001b7a:	74a8                	ld	a0,104(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	70ac                	ld	a1,96(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001b8c:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001b98:	16048823          	sb	zero,368(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3ee48493          	addi	s1,s1,1006 # 80010fb0 <proc>
    80001bca:	00016917          	auipc	s2,0x16
    80001bce:	be690913          	addi	s2,s2,-1050 # 800177b0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	1a048493          	addi	s1,s1,416
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a89d                	j	80001c6a <allocproc+0xb4>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  p->que_no = 0;
    80001c04:	1804aa23          	sw	zero,404(s1)
  p->entry_time = ticks;
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	d087a783          	lw	a5,-760(a5) # 80008910 <ticks>
    80001c10:	18f4a823          	sw	a5,400(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	ed2080e7          	jalr	-302(ra) # 80000ae6 <kalloc>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	f8a8                	sd	a0,112(s1)
    80001c20:	cd21                	beqz	a0,80001c78 <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001c22:	8526                	mv	a0,s1
    80001c24:	00000097          	auipc	ra,0x0
    80001c28:	e4c080e7          	jalr	-436(ra) # 80001a70 <proc_pagetable>
    80001c2c:	892a                	mv	s2,a0
    80001c2e:	f4a8                	sd	a0,104(s1)
  if (p->pagetable == 0)
    80001c30:	c125                	beqz	a0,80001c90 <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001c32:	07000613          	li	a2,112
    80001c36:	4581                	li	a1,0
    80001c38:	07848513          	addi	a0,s1,120
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	096080e7          	jalr	150(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c44:	00000797          	auipc	a5,0x0
    80001c48:	da078793          	addi	a5,a5,-608 # 800019e4 <forkret>
    80001c4c:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c4e:	6cbc                	ld	a5,88(s1)
    80001c50:	6705                	lui	a4,0x1
    80001c52:	97ba                	add	a5,a5,a4
    80001c54:	e0dc                	sd	a5,128(s1)
  p->rtime = 0;
    80001c56:	1804a023          	sw	zero,384(s1)
  p->etime = 0;
    80001c5a:	1804a623          	sw	zero,396(s1)
  p->ctime = ticks;
    80001c5e:	00007797          	auipc	a5,0x7
    80001c62:	cb27a783          	lw	a5,-846(a5) # 80008910 <ticks>
    80001c66:	18f4a423          	sw	a5,392(s1)
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret
    freeproc(p);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	ee4080e7          	jalr	-284(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	006080e7          	jalr	6(ra) # 80000c8a <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	bff1                	j	80001c6a <allocproc+0xb4>
    freeproc(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	ecc080e7          	jalr	-308(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	fee080e7          	jalr	-18(ra) # 80000c8a <release>
    return 0;
    80001ca4:	84ca                	mv	s1,s2
    80001ca6:	b7d1                	j	80001c6a <allocproc+0xb4>

0000000080001ca8 <userinit>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f04080e7          	jalr	-252(ra) # 80001bb6 <allocproc>
    80001cba:	84aa                	mv	s1,a0
  initproc = p;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	c4a7b623          	sd	a0,-948(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cc4:	03400613          	li	a2,52
    80001cc8:	00007597          	auipc	a1,0x7
    80001ccc:	bb858593          	addi	a1,a1,-1096 # 80008880 <initcode>
    80001cd0:	7528                	ld	a0,104(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	684080e7          	jalr	1668(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cda:	6785                	lui	a5,0x1
    80001cdc:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cde:	78b8                	ld	a4,112(s1)
    80001ce0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce4:	78b8                	ld	a4,112(s1)
    80001ce6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	00006597          	auipc	a1,0x6
    80001cee:	51658593          	addi	a1,a1,1302 # 80008200 <digits+0x1c0>
    80001cf2:	17048513          	addi	a0,s1,368
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	126080e7          	jalr	294(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	51250513          	addi	a0,a0,1298 # 80008210 <digits+0x1d0>
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	4fa080e7          	jalr	1274(ra) # 80004200 <namei>
    80001d0e:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001d12:	478d                	li	a5,3
    80001d14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	f72080e7          	jalr	-142(ra) # 80000c8a <release>
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <growproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	addi	s0,sp,32
    80001d36:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	c74080e7          	jalr	-908(ra) # 800019ac <myproc>
    80001d40:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d42:	712c                	ld	a1,96(a0)
  if (n > 0)
    80001d44:	01204c63          	bgtz	s2,80001d5c <growproc+0x32>
  else if (n < 0)
    80001d48:	02094663          	bltz	s2,80001d74 <growproc+0x4a>
  p->sz = sz;
    80001d4c:	f0ac                	sd	a1,96(s1)
  return 0;
    80001d4e:	4501                	li	a0,0
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6902                	ld	s2,0(sp)
    80001d58:	6105                	addi	sp,sp,32
    80001d5a:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d5c:	4691                	li	a3,4
    80001d5e:	00b90633          	add	a2,s2,a1
    80001d62:	7528                	ld	a0,104(a0)
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	6ac080e7          	jalr	1708(ra) # 80001410 <uvmalloc>
    80001d6c:	85aa                	mv	a1,a0
    80001d6e:	fd79                	bnez	a0,80001d4c <growproc+0x22>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bff9                	j	80001d50 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	00b90633          	add	a2,s2,a1
    80001d78:	7528                	ld	a0,104(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	64e080e7          	jalr	1614(ra) # 800013c8 <uvmdealloc>
    80001d82:	85aa                	mv	a1,a0
    80001d84:	b7e1                	j	80001d4c <growproc+0x22>

0000000080001d86 <fork>:
{
    80001d86:	7139                	addi	sp,sp,-64
    80001d88:	fc06                	sd	ra,56(sp)
    80001d8a:	f822                	sd	s0,48(sp)
    80001d8c:	f426                	sd	s1,40(sp)
    80001d8e:	f04a                	sd	s2,32(sp)
    80001d90:	ec4e                	sd	s3,24(sp)
    80001d92:	e852                	sd	s4,16(sp)
    80001d94:	e456                	sd	s5,8(sp)
    80001d96:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d98:	00000097          	auipc	ra,0x0
    80001d9c:	c14080e7          	jalr	-1004(ra) # 800019ac <myproc>
    80001da0:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	e14080e7          	jalr	-492(ra) # 80001bb6 <allocproc>
    80001daa:	10050c63          	beqz	a0,80001ec2 <fork+0x13c>
    80001dae:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001db0:	060ab603          	ld	a2,96(s5)
    80001db4:	752c                	ld	a1,104(a0)
    80001db6:	068ab503          	ld	a0,104(s5)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	7ae080e7          	jalr	1966(ra) # 80001568 <uvmcopy>
    80001dc2:	04054863          	bltz	a0,80001e12 <fork+0x8c>
  np->sz = p->sz;
    80001dc6:	060ab783          	ld	a5,96(s5)
    80001dca:	06fa3023          	sd	a5,96(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dce:	070ab683          	ld	a3,112(s5)
    80001dd2:	87b6                	mv	a5,a3
    80001dd4:	070a3703          	ld	a4,112(s4)
    80001dd8:	12068693          	addi	a3,a3,288
    80001ddc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001de0:	6788                	ld	a0,8(a5)
    80001de2:	6b8c                	ld	a1,16(a5)
    80001de4:	6f90                	ld	a2,24(a5)
    80001de6:	01073023          	sd	a6,0(a4)
    80001dea:	e708                	sd	a0,8(a4)
    80001dec:	eb0c                	sd	a1,16(a4)
    80001dee:	ef10                	sd	a2,24(a4)
    80001df0:	02078793          	addi	a5,a5,32
    80001df4:	02070713          	addi	a4,a4,32
    80001df8:	fed792e3          	bne	a5,a3,80001ddc <fork+0x56>
  np->trapframe->a0 = 0;
    80001dfc:	070a3783          	ld	a5,112(s4)
    80001e00:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e04:	0e8a8493          	addi	s1,s5,232
    80001e08:	0e8a0913          	addi	s2,s4,232
    80001e0c:	168a8993          	addi	s3,s5,360
    80001e10:	a00d                	j	80001e32 <fork+0xac>
    freeproc(np);
    80001e12:	8552                	mv	a0,s4
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	d4a080e7          	jalr	-694(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e1c:	8552                	mv	a0,s4
    80001e1e:	fffff097          	auipc	ra,0xfffff
    80001e22:	e6c080e7          	jalr	-404(ra) # 80000c8a <release>
    return -1;
    80001e26:	597d                	li	s2,-1
    80001e28:	a059                	j	80001eae <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e2a:	04a1                	addi	s1,s1,8
    80001e2c:	0921                	addi	s2,s2,8
    80001e2e:	01348b63          	beq	s1,s3,80001e44 <fork+0xbe>
    if (p->ofile[i])
    80001e32:	6088                	ld	a0,0(s1)
    80001e34:	d97d                	beqz	a0,80001e2a <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e36:	00003097          	auipc	ra,0x3
    80001e3a:	a60080e7          	jalr	-1440(ra) # 80004896 <filedup>
    80001e3e:	00a93023          	sd	a0,0(s2)
    80001e42:	b7e5                	j	80001e2a <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e44:	168ab503          	ld	a0,360(s5)
    80001e48:	00002097          	auipc	ra,0x2
    80001e4c:	bce080e7          	jalr	-1074(ra) # 80003a16 <idup>
    80001e50:	16aa3423          	sd	a0,360(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e54:	4641                	li	a2,16
    80001e56:	170a8593          	addi	a1,s5,368
    80001e5a:	170a0513          	addi	a0,s4,368
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	fbe080e7          	jalr	-66(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e66:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e74:	0000f497          	auipc	s1,0xf
    80001e78:	d2448493          	addi	s1,s1,-732 # 80010b98 <wait_lock>
    80001e7c:	8526                	mv	a0,s1
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d58080e7          	jalr	-680(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e86:	055a3823          	sd	s5,80(s4)
  release(&wait_lock);
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	dfe080e7          	jalr	-514(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	d40080e7          	jalr	-704(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e9e:	478d                	li	a5,3
    80001ea0:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea4:	8552                	mv	a0,s4
    80001ea6:	fffff097          	auipc	ra,0xfffff
    80001eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
}
    80001eae:	854a                	mv	a0,s2
    80001eb0:	70e2                	ld	ra,56(sp)
    80001eb2:	7442                	ld	s0,48(sp)
    80001eb4:	74a2                	ld	s1,40(sp)
    80001eb6:	7902                	ld	s2,32(sp)
    80001eb8:	69e2                	ld	s3,24(sp)
    80001eba:	6a42                	ld	s4,16(sp)
    80001ebc:	6aa2                	ld	s5,8(sp)
    80001ebe:	6121                	addi	sp,sp,64
    80001ec0:	8082                	ret
    return -1;
    80001ec2:	597d                	li	s2,-1
    80001ec4:	b7ed                	j	80001eae <fork+0x128>

0000000080001ec6 <scheduler>:
{
    80001ec6:	7119                	addi	sp,sp,-128
    80001ec8:	fc86                	sd	ra,120(sp)
    80001eca:	f8a2                	sd	s0,112(sp)
    80001ecc:	f4a6                	sd	s1,104(sp)
    80001ece:	f0ca                	sd	s2,96(sp)
    80001ed0:	ecce                	sd	s3,88(sp)
    80001ed2:	e8d2                	sd	s4,80(sp)
    80001ed4:	e4d6                	sd	s5,72(sp)
    80001ed6:	e0da                	sd	s6,64(sp)
    80001ed8:	fc5e                	sd	s7,56(sp)
    80001eda:	f862                	sd	s8,48(sp)
    80001edc:	f466                	sd	s9,40(sp)
    80001ede:	f06a                	sd	s10,32(sp)
    80001ee0:	ec6e                	sd	s11,24(sp)
    80001ee2:	0100                	addi	s0,sp,128
    80001ee4:	8492                	mv	s1,tp
  int id = r_tp();
    80001ee6:	2481                	sext.w	s1,s1
  c->proc = 0;
    80001ee8:	00749d93          	slli	s11,s1,0x7
    80001eec:	0000f797          	auipc	a5,0xf
    80001ef0:	c9478793          	addi	a5,a5,-876 # 80010b80 <pid_lock>
    80001ef4:	97ee                	add	a5,a5,s11
    80001ef6:	0207b823          	sd	zero,48(a5)
  printf("FCFS");
    80001efa:	00006517          	auipc	a0,0x6
    80001efe:	31e50513          	addi	a0,a0,798 # 80008218 <digits+0x1d8>
    80001f02:	ffffe097          	auipc	ra,0xffffe
    80001f06:	688080e7          	jalr	1672(ra) # 8000058a <printf>
      swtch(&c->context, &p->context);
    80001f0a:	0000f797          	auipc	a5,0xf
    80001f0e:	cae78793          	addi	a5,a5,-850 # 80010bb8 <cpus+0x8>
    80001f12:	9dbe                	add	s11,s11,a5
    uint m_time = __INT_MAX__;
    80001f14:	800007b7          	lui	a5,0x80000
    80001f18:	fff7c793          	not	a5,a5
    80001f1c:	f8f43423          	sd	a5,-120(s0)
      if (p->state == RUNNABLE)
    80001f20:	4b0d                	li	s6,3
    for (p = proc; p < &proc[NPROC]; p++)
    80001f22:	00016a97          	auipc	s5,0x16
    80001f26:	88ea8a93          	addi	s5,s5,-1906 # 800177b0 <tickslock>
      c->proc = p;
    80001f2a:	049e                	slli	s1,s1,0x7
    80001f2c:	0000fd17          	auipc	s10,0xf
    80001f30:	c54d0d13          	addi	s10,s10,-940 # 80010b80 <pid_lock>
    80001f34:	9d26                	add	s10,s10,s1
    80001f36:	a8bd                	j	80001fb4 <scheduler+0xee>
      release(&p->lock);
    80001f38:	854e                	mv	a0,s3
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d50080e7          	jalr	-688(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f42:	035a7f63          	bgeu	s4,s5,80001f80 <scheduler+0xba>
    80001f46:	1a090913          	addi	s2,s2,416
    80001f4a:	1a048493          	addi	s1,s1,416
    80001f4e:	89ca                	mv	s3,s2
      acquire(&p->lock);
    80001f50:	854a                	mv	a0,s2
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	c84080e7          	jalr	-892(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f5a:	8a26                	mv	s4,s1
    80001f5c:	e784a783          	lw	a5,-392(s1)
    80001f60:	fd679ce3          	bne	a5,s6,80001f38 <scheduler+0x72>
        if (p->ctime < m_time)
    80001f64:	fe84ab83          	lw	s7,-24(s1)
    80001f68:	fd8bf8e3          	bgeu	s7,s8,80001f38 <scheduler+0x72>
      release(&p->lock);
    80001f6c:	854a                	mv	a0,s2
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f76:	0754f163          	bgeu	s1,s5,80001fd8 <scheduler+0x112>
    80001f7a:	8cce                	mv	s9,s3
          m_time = p->ctime;
    80001f7c:	8c5e                	mv	s8,s7
    80001f7e:	b7e1                	j	80001f46 <scheduler+0x80>
    if (p != 0)
    80001f80:	020c8a63          	beqz	s9,80001fb4 <scheduler+0xee>
      acquire(&p->lock);
    80001f84:	8566                	mv	a0,s9
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	c50080e7          	jalr	-944(ra) # 80000bd6 <acquire>
      p->state = RUNNING;
    80001f8e:	4791                	li	a5,4
    80001f90:	00fcac23          	sw	a5,24(s9)
      c->proc = p;
    80001f94:	039d3823          	sd	s9,48(s10)
      swtch(&c->context, &p->context);
    80001f98:	078c8593          	addi	a1,s9,120
    80001f9c:	856e                	mv	a0,s11
    80001f9e:	00001097          	auipc	ra,0x1
    80001fa2:	8e8080e7          	jalr	-1816(ra) # 80002886 <swtch>
      c->proc = 0;
    80001fa6:	020d3823          	sd	zero,48(s10)
      release(&p->lock);
    80001faa:	8566                	mv	a0,s9
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	cde080e7          	jalr	-802(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fbc:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001fc0:	0000f917          	auipc	s2,0xf
    80001fc4:	ff090913          	addi	s2,s2,-16 # 80010fb0 <proc>
    80001fc8:	0000f497          	auipc	s1,0xf
    80001fcc:	18848493          	addi	s1,s1,392 # 80011150 <proc+0x1a0>
    struct proc *tobesch = 0;
    80001fd0:	4c81                	li	s9,0
    uint m_time = __INT_MAX__;
    80001fd2:	f8843c03          	ld	s8,-120(s0)
    80001fd6:	bfa5                	j	80001f4e <scheduler+0x88>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fd8:	8cca                	mv	s9,s2
    80001fda:	b76d                	j	80001f84 <scheduler+0xbe>

0000000080001fdc <sched>:
{
    80001fdc:	7179                	addi	sp,sp,-48
    80001fde:	f406                	sd	ra,40(sp)
    80001fe0:	f022                	sd	s0,32(sp)
    80001fe2:	ec26                	sd	s1,24(sp)
    80001fe4:	e84a                	sd	s2,16(sp)
    80001fe6:	e44e                	sd	s3,8(sp)
    80001fe8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	9c2080e7          	jalr	-1598(ra) # 800019ac <myproc>
    80001ff2:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	b68080e7          	jalr	-1176(ra) # 80000b5c <holding>
    80001ffc:	c93d                	beqz	a0,80002072 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffe:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002000:	2781                	sext.w	a5,a5
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	0000f717          	auipc	a4,0xf
    80002008:	b7c70713          	addi	a4,a4,-1156 # 80010b80 <pid_lock>
    8000200c:	97ba                	add	a5,a5,a4
    8000200e:	0a87a703          	lw	a4,168(a5) # ffffffff800000a8 <end+0xfffffffefffdd508>
    80002012:	4785                	li	a5,1
    80002014:	06f71763          	bne	a4,a5,80002082 <sched+0xa6>
  if (p->state == RUNNING)
    80002018:	4c98                	lw	a4,24(s1)
    8000201a:	4791                	li	a5,4
    8000201c:	06f70b63          	beq	a4,a5,80002092 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002020:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002024:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002026:	efb5                	bnez	a5,800020a2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002028:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000202a:	0000f917          	auipc	s2,0xf
    8000202e:	b5690913          	addi	s2,s2,-1194 # 80010b80 <pid_lock>
    80002032:	2781                	sext.w	a5,a5
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	97ca                	add	a5,a5,s2
    80002038:	0ac7a983          	lw	s3,172(a5)
    8000203c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	0000f597          	auipc	a1,0xf
    80002046:	b7658593          	addi	a1,a1,-1162 # 80010bb8 <cpus+0x8>
    8000204a:	95be                	add	a1,a1,a5
    8000204c:	07848513          	addi	a0,s1,120
    80002050:	00001097          	auipc	ra,0x1
    80002054:	836080e7          	jalr	-1994(ra) # 80002886 <swtch>
    80002058:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	993e                	add	s2,s2,a5
    80002060:	0b392623          	sw	s3,172(s2)
}
    80002064:	70a2                	ld	ra,40(sp)
    80002066:	7402                	ld	s0,32(sp)
    80002068:	64e2                	ld	s1,24(sp)
    8000206a:	6942                	ld	s2,16(sp)
    8000206c:	69a2                	ld	s3,8(sp)
    8000206e:	6145                	addi	sp,sp,48
    80002070:	8082                	ret
    panic("sched p->lock");
    80002072:	00006517          	auipc	a0,0x6
    80002076:	1ae50513          	addi	a0,a0,430 # 80008220 <digits+0x1e0>
    8000207a:	ffffe097          	auipc	ra,0xffffe
    8000207e:	4c6080e7          	jalr	1222(ra) # 80000540 <panic>
    panic("sched locks");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	1ae50513          	addi	a0,a0,430 # 80008230 <digits+0x1f0>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4b6080e7          	jalr	1206(ra) # 80000540 <panic>
    panic("sched running");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	1ae50513          	addi	a0,a0,430 # 80008240 <digits+0x200>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	4a6080e7          	jalr	1190(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020a2:	00006517          	auipc	a0,0x6
    800020a6:	1ae50513          	addi	a0,a0,430 # 80008250 <digits+0x210>
    800020aa:	ffffe097          	auipc	ra,0xffffe
    800020ae:	496080e7          	jalr	1174(ra) # 80000540 <panic>

00000000800020b2 <yield>:
{
    800020b2:	1101                	addi	sp,sp,-32
    800020b4:	ec06                	sd	ra,24(sp)
    800020b6:	e822                	sd	s0,16(sp)
    800020b8:	e426                	sd	s1,8(sp)
    800020ba:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020bc:	00000097          	auipc	ra,0x0
    800020c0:	8f0080e7          	jalr	-1808(ra) # 800019ac <myproc>
    800020c4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c6:	fffff097          	auipc	ra,0xfffff
    800020ca:	b10080e7          	jalr	-1264(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020ce:	478d                	li	a5,3
    800020d0:	cc9c                	sw	a5,24(s1)
  sched();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	f0a080e7          	jalr	-246(ra) # 80001fdc <sched>
  release(&p->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	bae080e7          	jalr	-1106(ra) # 80000c8a <release>
}
    800020e4:	60e2                	ld	ra,24(sp)
    800020e6:	6442                	ld	s0,16(sp)
    800020e8:	64a2                	ld	s1,8(sp)
    800020ea:	6105                	addi	sp,sp,32
    800020ec:	8082                	ret

00000000800020ee <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020ee:	7179                	addi	sp,sp,-48
    800020f0:	f406                	sd	ra,40(sp)
    800020f2:	f022                	sd	s0,32(sp)
    800020f4:	ec26                	sd	s1,24(sp)
    800020f6:	e84a                	sd	s2,16(sp)
    800020f8:	e44e                	sd	s3,8(sp)
    800020fa:	1800                	addi	s0,sp,48
    800020fc:	89aa                	mv	s3,a0
    800020fe:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	8ac080e7          	jalr	-1876(ra) # 800019ac <myproc>
    80002108:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	acc080e7          	jalr	-1332(ra) # 80000bd6 <acquire>
  release(lk);
    80002112:	854a                	mv	a0,s2
    80002114:	fffff097          	auipc	ra,0xfffff
    80002118:	b76080e7          	jalr	-1162(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000211c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002120:	4789                	li	a5,2
    80002122:	cc9c                	sw	a5,24(s1)

  sched();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	eb8080e7          	jalr	-328(ra) # 80001fdc <sched>

  // Tidy up.
  p->chan = 0;
    8000212c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b58080e7          	jalr	-1192(ra) # 80000c8a <release>
  acquire(lk);
    8000213a:	854a                	mv	a0,s2
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	a9a080e7          	jalr	-1382(ra) # 80000bd6 <acquire>
}
    80002144:	70a2                	ld	ra,40(sp)
    80002146:	7402                	ld	s0,32(sp)
    80002148:	64e2                	ld	s1,24(sp)
    8000214a:	6942                	ld	s2,16(sp)
    8000214c:	69a2                	ld	s3,8(sp)
    8000214e:	6145                	addi	sp,sp,48
    80002150:	8082                	ret

0000000080002152 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002152:	7139                	addi	sp,sp,-64
    80002154:	fc06                	sd	ra,56(sp)
    80002156:	f822                	sd	s0,48(sp)
    80002158:	f426                	sd	s1,40(sp)
    8000215a:	f04a                	sd	s2,32(sp)
    8000215c:	ec4e                	sd	s3,24(sp)
    8000215e:	e852                	sd	s4,16(sp)
    80002160:	e456                	sd	s5,8(sp)
    80002162:	0080                	addi	s0,sp,64
    80002164:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002166:	0000f497          	auipc	s1,0xf
    8000216a:	e4a48493          	addi	s1,s1,-438 # 80010fb0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000216e:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002170:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002172:	00015917          	auipc	s2,0x15
    80002176:	63e90913          	addi	s2,s2,1598 # 800177b0 <tickslock>
    8000217a:	a811                	j	8000218e <wakeup+0x3c>
      }
      release(&p->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b0c080e7          	jalr	-1268(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002186:	1a048493          	addi	s1,s1,416
    8000218a:	03248663          	beq	s1,s2,800021b6 <wakeup+0x64>
    if (p != myproc())
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	81e080e7          	jalr	-2018(ra) # 800019ac <myproc>
    80002196:	fea488e3          	beq	s1,a0,80002186 <wakeup+0x34>
      acquire(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a3a080e7          	jalr	-1478(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800021a4:	4c9c                	lw	a5,24(s1)
    800021a6:	fd379be3          	bne	a5,s3,8000217c <wakeup+0x2a>
    800021aa:	709c                	ld	a5,32(s1)
    800021ac:	fd4798e3          	bne	a5,s4,8000217c <wakeup+0x2a>
        p->state = RUNNABLE;
    800021b0:	0154ac23          	sw	s5,24(s1)
    800021b4:	b7e1                	j	8000217c <wakeup+0x2a>
    }
  }
}
    800021b6:	70e2                	ld	ra,56(sp)
    800021b8:	7442                	ld	s0,48(sp)
    800021ba:	74a2                	ld	s1,40(sp)
    800021bc:	7902                	ld	s2,32(sp)
    800021be:	69e2                	ld	s3,24(sp)
    800021c0:	6a42                	ld	s4,16(sp)
    800021c2:	6aa2                	ld	s5,8(sp)
    800021c4:	6121                	addi	sp,sp,64
    800021c6:	8082                	ret

00000000800021c8 <reparent>:
{
    800021c8:	7179                	addi	sp,sp,-48
    800021ca:	f406                	sd	ra,40(sp)
    800021cc:	f022                	sd	s0,32(sp)
    800021ce:	ec26                	sd	s1,24(sp)
    800021d0:	e84a                	sd	s2,16(sp)
    800021d2:	e44e                	sd	s3,8(sp)
    800021d4:	e052                	sd	s4,0(sp)
    800021d6:	1800                	addi	s0,sp,48
    800021d8:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021da:	0000f497          	auipc	s1,0xf
    800021de:	dd648493          	addi	s1,s1,-554 # 80010fb0 <proc>
      pp->parent = initproc;
    800021e2:	00006a17          	auipc	s4,0x6
    800021e6:	726a0a13          	addi	s4,s4,1830 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800021ea:	00015997          	auipc	s3,0x15
    800021ee:	5c698993          	addi	s3,s3,1478 # 800177b0 <tickslock>
    800021f2:	a029                	j	800021fc <reparent+0x34>
    800021f4:	1a048493          	addi	s1,s1,416
    800021f8:	01348d63          	beq	s1,s3,80002212 <reparent+0x4a>
    if (pp->parent == p)
    800021fc:	68bc                	ld	a5,80(s1)
    800021fe:	ff279be3          	bne	a5,s2,800021f4 <reparent+0x2c>
      pp->parent = initproc;
    80002202:	000a3503          	ld	a0,0(s4)
    80002206:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	f4a080e7          	jalr	-182(ra) # 80002152 <wakeup>
    80002210:	b7d5                	j	800021f4 <reparent+0x2c>
}
    80002212:	70a2                	ld	ra,40(sp)
    80002214:	7402                	ld	s0,32(sp)
    80002216:	64e2                	ld	s1,24(sp)
    80002218:	6942                	ld	s2,16(sp)
    8000221a:	69a2                	ld	s3,8(sp)
    8000221c:	6a02                	ld	s4,0(sp)
    8000221e:	6145                	addi	sp,sp,48
    80002220:	8082                	ret

0000000080002222 <exit>:
{
    80002222:	7179                	addi	sp,sp,-48
    80002224:	f406                	sd	ra,40(sp)
    80002226:	f022                	sd	s0,32(sp)
    80002228:	ec26                	sd	s1,24(sp)
    8000222a:	e84a                	sd	s2,16(sp)
    8000222c:	e44e                	sd	s3,8(sp)
    8000222e:	e052                	sd	s4,0(sp)
    80002230:	1800                	addi	s0,sp,48
    80002232:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	778080e7          	jalr	1912(ra) # 800019ac <myproc>
    8000223c:	89aa                	mv	s3,a0
  if (p == initproc)
    8000223e:	00006797          	auipc	a5,0x6
    80002242:	6ca7b783          	ld	a5,1738(a5) # 80008908 <initproc>
    80002246:	0e850493          	addi	s1,a0,232
    8000224a:	16850913          	addi	s2,a0,360
    8000224e:	02a79363          	bne	a5,a0,80002274 <exit+0x52>
    panic("init exiting");
    80002252:	00006517          	auipc	a0,0x6
    80002256:	01650513          	addi	a0,a0,22 # 80008268 <digits+0x228>
    8000225a:	ffffe097          	auipc	ra,0xffffe
    8000225e:	2e6080e7          	jalr	742(ra) # 80000540 <panic>
      fileclose(f);
    80002262:	00002097          	auipc	ra,0x2
    80002266:	686080e7          	jalr	1670(ra) # 800048e8 <fileclose>
      p->ofile[fd] = 0;
    8000226a:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000226e:	04a1                	addi	s1,s1,8
    80002270:	01248563          	beq	s1,s2,8000227a <exit+0x58>
    if (p->ofile[fd])
    80002274:	6088                	ld	a0,0(s1)
    80002276:	f575                	bnez	a0,80002262 <exit+0x40>
    80002278:	bfdd                	j	8000226e <exit+0x4c>
  begin_op();
    8000227a:	00002097          	auipc	ra,0x2
    8000227e:	1a6080e7          	jalr	422(ra) # 80004420 <begin_op>
  iput(p->cwd);
    80002282:	1689b503          	ld	a0,360(s3)
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	988080e7          	jalr	-1656(ra) # 80003c0e <iput>
  end_op();
    8000228e:	00002097          	auipc	ra,0x2
    80002292:	210080e7          	jalr	528(ra) # 8000449e <end_op>
  p->cwd = 0;
    80002296:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    8000229a:	0000f497          	auipc	s1,0xf
    8000229e:	8fe48493          	addi	s1,s1,-1794 # 80010b98 <wait_lock>
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	932080e7          	jalr	-1742(ra) # 80000bd6 <acquire>
  reparent(p);
    800022ac:	854e                	mv	a0,s3
    800022ae:	00000097          	auipc	ra,0x0
    800022b2:	f1a080e7          	jalr	-230(ra) # 800021c8 <reparent>
  wakeup(p->parent);
    800022b6:	0509b503          	ld	a0,80(s3)
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	e98080e7          	jalr	-360(ra) # 80002152 <wakeup>
  acquire(&p->lock);
    800022c2:	854e                	mv	a0,s3
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	912080e7          	jalr	-1774(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022cc:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022d0:	4795                	li	a5,5
    800022d2:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800022d6:	00006797          	auipc	a5,0x6
    800022da:	63a7a783          	lw	a5,1594(a5) # 80008910 <ticks>
    800022de:	18f9a623          	sw	a5,396(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9a6080e7          	jalr	-1626(ra) # 80000c8a <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cf0080e7          	jalr	-784(ra) # 80001fdc <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f8450513          	addi	a0,a0,-124 # 80008278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	c9c48493          	addi	s1,s1,-868 # 80010fb0 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	49498993          	addi	s3,s3,1172 # 800177b0 <tickslock>
  {
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	8b0080e7          	jalr	-1872(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	954080e7          	jalr	-1708(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000233e:	1a048493          	addi	s1,s1,416
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	932080e7          	jalr	-1742(ra) # 80000c8a <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	854080e7          	jalr	-1964(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	8fa080e7          	jalr	-1798(ra) # 80000c8a <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	826080e7          	jalr	-2010(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	8cc080e7          	jalr	-1844(ra) # 80000c8a <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	5be080e7          	jalr	1470(ra) # 800019ac <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000e517          	auipc	a0,0xe
    800023fc:	7a050513          	addi	a0,a0,1952 # 80010b98 <wait_lock>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	7d6080e7          	jalr	2006(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	3a298993          	addi	s3,s3,930 # 800177b0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002416:	0000ec17          	auipc	s8,0xe
    8000241a:	782c0c13          	addi	s8,s8,1922 # 80010b98 <wait_lock>
    havekids = 0;
    8000241e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002420:	0000f497          	auipc	s1,0xf
    80002424:	b9048493          	addi	s1,s1,-1136 # 80010fb0 <proc>
    80002428:	a0bd                	j	80002496 <wait+0xc2>
          pid = pp->pid;
    8000242a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000242e:	000b0e63          	beqz	s6,8000244a <wait+0x76>
    80002432:	4691                	li	a3,4
    80002434:	02c48613          	addi	a2,s1,44
    80002438:	85da                	mv	a1,s6
    8000243a:	06893503          	ld	a0,104(s2)
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	22e080e7          	jalr	558(ra) # 8000166c <copyout>
    80002446:	02054563          	bltz	a0,80002470 <wait+0x9c>
          freeproc(pp);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	712080e7          	jalr	1810(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	834080e7          	jalr	-1996(ra) # 80000c8a <release>
          release(&wait_lock);
    8000245e:	0000e517          	auipc	a0,0xe
    80002462:	73a50513          	addi	a0,a0,1850 # 80010b98 <wait_lock>
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	824080e7          	jalr	-2012(ra) # 80000c8a <release>
          return pid;
    8000246e:	a0b5                	j	800024da <wait+0x106>
            release(&pp->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	818080e7          	jalr	-2024(ra) # 80000c8a <release>
            release(&wait_lock);
    8000247a:	0000e517          	auipc	a0,0xe
    8000247e:	71e50513          	addi	a0,a0,1822 # 80010b98 <wait_lock>
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	808080e7          	jalr	-2040(ra) # 80000c8a <release>
            return -1;
    8000248a:	59fd                	li	s3,-1
    8000248c:	a0b9                	j	800024da <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000248e:	1a048493          	addi	s1,s1,416
    80002492:	03348463          	beq	s1,s3,800024ba <wait+0xe6>
      if (pp->parent == p)
    80002496:	68bc                	ld	a5,80(s1)
    80002498:	ff279be3          	bne	a5,s2,8000248e <wait+0xba>
        acquire(&pp->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    800024a6:	4c9c                	lw	a5,24(s1)
    800024a8:	f94781e3          	beq	a5,s4,8000242a <wait+0x56>
        release(&pp->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7dc080e7          	jalr	2012(ra) # 80000c8a <release>
        havekids = 1;
    800024b6:	8756                	mv	a4,s5
    800024b8:	bfd9                	j	8000248e <wait+0xba>
    if (!havekids || killed(p))
    800024ba:	c719                	beqz	a4,800024c8 <wait+0xf4>
    800024bc:	854a                	mv	a0,s2
    800024be:	00000097          	auipc	ra,0x0
    800024c2:	ee4080e7          	jalr	-284(ra) # 800023a2 <killed>
    800024c6:	c51d                	beqz	a0,800024f4 <wait+0x120>
      release(&wait_lock);
    800024c8:	0000e517          	auipc	a0,0xe
    800024cc:	6d050513          	addi	a0,a0,1744 # 80010b98 <wait_lock>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	7ba080e7          	jalr	1978(ra) # 80000c8a <release>
      return -1;
    800024d8:	59fd                	li	s3,-1
}
    800024da:	854e                	mv	a0,s3
    800024dc:	60a6                	ld	ra,72(sp)
    800024de:	6406                	ld	s0,64(sp)
    800024e0:	74e2                	ld	s1,56(sp)
    800024e2:	7942                	ld	s2,48(sp)
    800024e4:	79a2                	ld	s3,40(sp)
    800024e6:	7a02                	ld	s4,32(sp)
    800024e8:	6ae2                	ld	s5,24(sp)
    800024ea:	6b42                	ld	s6,16(sp)
    800024ec:	6ba2                	ld	s7,8(sp)
    800024ee:	6c02                	ld	s8,0(sp)
    800024f0:	6161                	addi	sp,sp,80
    800024f2:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024f4:	85e2                	mv	a1,s8
    800024f6:	854a                	mv	a0,s2
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	bf6080e7          	jalr	-1034(ra) # 800020ee <sleep>
    havekids = 0;
    80002500:	bf39                	j	8000241e <wait+0x4a>

0000000080002502 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	492080e7          	jalr	1170(ra) # 800019ac <myproc>
  if (user_dst)
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	7528                	ld	a0,104(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	140080e7          	jalr	320(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	ffffe097          	auipc	ra,0xffffe
    80002550:	7e2080e7          	jalr	2018(ra) # 80000d2e <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	43c080e7          	jalr	1084(ra) # 800019ac <myproc>
  if (user_src)
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	7528                	ld	a0,104(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	176080e7          	jalr	374(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char *)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	78c080e7          	jalr	1932(ra) # 80000d2e <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800080c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	b4c48493          	addi	s1,s1,-1204 # 80011120 <proc+0x170>
    800025dc:	00015917          	auipc	s2,0x15
    800025e0:	34490913          	addi	s2,s2,836 # 80017920 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	addi	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800082d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ec06a583          	lw	a1,-320(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002620:	1a048493          	addi	s1,s1,416
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if (p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ea84a783          	lw	a5,-344(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    8000265e:	711d                	addi	sp,sp,-96
    80002660:	ec86                	sd	ra,88(sp)
    80002662:	e8a2                	sd	s0,80(sp)
    80002664:	e4a6                	sd	s1,72(sp)
    80002666:	e0ca                	sd	s2,64(sp)
    80002668:	fc4e                	sd	s3,56(sp)
    8000266a:	f852                	sd	s4,48(sp)
    8000266c:	f456                	sd	s5,40(sp)
    8000266e:	f05a                	sd	s6,32(sp)
    80002670:	ec5e                	sd	s7,24(sp)
    80002672:	e862                	sd	s8,16(sp)
    80002674:	e466                	sd	s9,8(sp)
    80002676:	e06a                	sd	s10,0(sp)
    80002678:	1080                	addi	s0,sp,96
    8000267a:	8b2a                	mv	s6,a0
    8000267c:	8bae                	mv	s7,a1
    8000267e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	32c080e7          	jalr	812(ra) # 800019ac <myproc>
    80002688:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000268a:	0000e517          	auipc	a0,0xe
    8000268e:	50e50513          	addi	a0,a0,1294 # 80010b98 <wait_lock>
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	544080e7          	jalr	1348(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000269a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    8000269c:	4a15                	li	s4,5
        havekids = 1;
    8000269e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800026a0:	00015997          	auipc	s3,0x15
    800026a4:	11098993          	addi	s3,s3,272 # 800177b0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026a8:	0000ed17          	auipc	s10,0xe
    800026ac:	4f0d0d13          	addi	s10,s10,1264 # 80010b98 <wait_lock>
    havekids = 0;
    800026b0:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800026b2:	0000f497          	auipc	s1,0xf
    800026b6:	8fe48493          	addi	s1,s1,-1794 # 80010fb0 <proc>
    800026ba:	a059                	j	80002740 <waitx+0xe2>
          pid = np->pid;
    800026bc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800026c0:	1804a783          	lw	a5,384(s1)
    800026c4:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800026c8:	1884a703          	lw	a4,392(s1)
    800026cc:	9f3d                	addw	a4,a4,a5
    800026ce:	18c4a783          	lw	a5,396(s1)
    800026d2:	9f99                	subw	a5,a5,a4
    800026d4:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800026d8:	000b0e63          	beqz	s6,800026f4 <waitx+0x96>
    800026dc:	4691                	li	a3,4
    800026de:	02c48613          	addi	a2,s1,44
    800026e2:	85da                	mv	a1,s6
    800026e4:	06893503          	ld	a0,104(s2)
    800026e8:	fffff097          	auipc	ra,0xfffff
    800026ec:	f84080e7          	jalr	-124(ra) # 8000166c <copyout>
    800026f0:	02054563          	bltz	a0,8000271a <waitx+0xbc>
          freeproc(np);
    800026f4:	8526                	mv	a0,s1
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	468080e7          	jalr	1128(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	58a080e7          	jalr	1418(ra) # 80000c8a <release>
          release(&wait_lock);
    80002708:	0000e517          	auipc	a0,0xe
    8000270c:	49050513          	addi	a0,a0,1168 # 80010b98 <wait_lock>
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	57a080e7          	jalr	1402(ra) # 80000c8a <release>
          return pid;
    80002718:	a09d                	j	8000277e <waitx+0x120>
            release(&np->lock);
    8000271a:	8526                	mv	a0,s1
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	56e080e7          	jalr	1390(ra) # 80000c8a <release>
            release(&wait_lock);
    80002724:	0000e517          	auipc	a0,0xe
    80002728:	47450513          	addi	a0,a0,1140 # 80010b98 <wait_lock>
    8000272c:	ffffe097          	auipc	ra,0xffffe
    80002730:	55e080e7          	jalr	1374(ra) # 80000c8a <release>
            return -1;
    80002734:	59fd                	li	s3,-1
    80002736:	a0a1                	j	8000277e <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002738:	1a048493          	addi	s1,s1,416
    8000273c:	03348463          	beq	s1,s3,80002764 <waitx+0x106>
      if (np->parent == p)
    80002740:	68bc                	ld	a5,80(s1)
    80002742:	ff279be3          	bne	a5,s2,80002738 <waitx+0xda>
        acquire(&np->lock);
    80002746:	8526                	mv	a0,s1
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	48e080e7          	jalr	1166(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002750:	4c9c                	lw	a5,24(s1)
    80002752:	f74785e3          	beq	a5,s4,800026bc <waitx+0x5e>
        release(&np->lock);
    80002756:	8526                	mv	a0,s1
    80002758:	ffffe097          	auipc	ra,0xffffe
    8000275c:	532080e7          	jalr	1330(ra) # 80000c8a <release>
        havekids = 1;
    80002760:	8756                	mv	a4,s5
    80002762:	bfd9                	j	80002738 <waitx+0xda>
    if (!havekids || p->killed)
    80002764:	c701                	beqz	a4,8000276c <waitx+0x10e>
    80002766:	02892783          	lw	a5,40(s2)
    8000276a:	cb8d                	beqz	a5,8000279c <waitx+0x13e>
      release(&wait_lock);
    8000276c:	0000e517          	auipc	a0,0xe
    80002770:	42c50513          	addi	a0,a0,1068 # 80010b98 <wait_lock>
    80002774:	ffffe097          	auipc	ra,0xffffe
    80002778:	516080e7          	jalr	1302(ra) # 80000c8a <release>
      return -1;
    8000277c:	59fd                	li	s3,-1
  }
}
    8000277e:	854e                	mv	a0,s3
    80002780:	60e6                	ld	ra,88(sp)
    80002782:	6446                	ld	s0,80(sp)
    80002784:	64a6                	ld	s1,72(sp)
    80002786:	6906                	ld	s2,64(sp)
    80002788:	79e2                	ld	s3,56(sp)
    8000278a:	7a42                	ld	s4,48(sp)
    8000278c:	7aa2                	ld	s5,40(sp)
    8000278e:	7b02                	ld	s6,32(sp)
    80002790:	6be2                	ld	s7,24(sp)
    80002792:	6c42                	ld	s8,16(sp)
    80002794:	6ca2                	ld	s9,8(sp)
    80002796:	6d02                	ld	s10,0(sp)
    80002798:	6125                	addi	sp,sp,96
    8000279a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000279c:	85ea                	mv	a1,s10
    8000279e:	854a                	mv	a0,s2
    800027a0:	00000097          	auipc	ra,0x0
    800027a4:	94e080e7          	jalr	-1714(ra) # 800020ee <sleep>
    havekids = 0;
    800027a8:	b721                	j	800026b0 <waitx+0x52>

00000000800027aa <update_time>:

void update_time()
{
    800027aa:	7179                	addi	sp,sp,-48
    800027ac:	f406                	sd	ra,40(sp)
    800027ae:	f022                	sd	s0,32(sp)
    800027b0:	ec26                	sd	s1,24(sp)
    800027b2:	e84a                	sd	s2,16(sp)
    800027b4:	e44e                	sd	s3,8(sp)
    800027b6:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    800027b8:	0000e497          	auipc	s1,0xe
    800027bc:	7f848493          	addi	s1,s1,2040 # 80010fb0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    800027c0:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    800027c2:	00015917          	auipc	s2,0x15
    800027c6:	fee90913          	addi	s2,s2,-18 # 800177b0 <tickslock>
    800027ca:	a811                	j	800027de <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4bc080e7          	jalr	1212(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d6:	1a048493          	addi	s1,s1,416
    800027da:	03248063          	beq	s1,s2,800027fa <update_time+0x50>
    acquire(&p->lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	3f6080e7          	jalr	1014(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800027e8:	4c9c                	lw	a5,24(s1)
    800027ea:	ff3791e3          	bne	a5,s3,800027cc <update_time+0x22>
      p->rtime++;
    800027ee:	1804a783          	lw	a5,384(s1)
    800027f2:	2785                	addiw	a5,a5,1
    800027f4:	18f4a023          	sw	a5,384(s1)
    800027f8:	bfd1                	j	800027cc <update_time+0x22>
  }
}
    800027fa:	70a2                	ld	ra,40(sp)
    800027fc:	7402                	ld	s0,32(sp)
    800027fe:	64e2                	ld	s1,24(sp)
    80002800:	6942                	ld	s2,16(sp)
    80002802:	69a2                	ld	s3,8(sp)
    80002804:	6145                	addi	sp,sp,48
    80002806:	8082                	ret

0000000080002808 <sigalarm>:

int sigalarm(uint n, uint64 handler)
{
    80002808:	1101                	addi	sp,sp,-32
    8000280a:	ec06                	sd	ra,24(sp)
    8000280c:	e822                	sd	s0,16(sp)
    8000280e:	e426                	sd	s1,8(sp)
    80002810:	e04a                	sd	s2,0(sp)
    80002812:	1000                	addi	s0,sp,32
    80002814:	892a                	mv	s2,a0
    80002816:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	194080e7          	jalr	404(ra) # 800019ac <myproc>
  p->alarm_status = 0;
    80002820:	02052c23          	sw	zero,56(a0)
  p->ticks = n;
    80002824:	03252e23          	sw	s2,60(a0)
  p->handler = handler;
    80002828:	e124                	sd	s1,64(a0)
  return 0;
}
    8000282a:	4501                	li	a0,0
    8000282c:	60e2                	ld	ra,24(sp)
    8000282e:	6442                	ld	s0,16(sp)
    80002830:	64a2                	ld	s1,8(sp)
    80002832:	6902                	ld	s2,0(sp)
    80002834:	6105                	addi	sp,sp,32
    80002836:	8082                	ret

0000000080002838 <sigreturn>:

int sigreturn(void)
{
    80002838:	1101                	addi	sp,sp,-32
    8000283a:	ec06                	sd	ra,24(sp)
    8000283c:	e822                	sd	s0,16(sp)
    8000283e:	e426                	sd	s1,8(sp)
    80002840:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002842:	fffff097          	auipc	ra,0xfffff
    80002846:	16a080e7          	jalr	362(ra) # 800019ac <myproc>
  if (p->alarm_status == 1)
    8000284a:	5d18                	lw	a4,56(a0)
    8000284c:	4785                	li	a5,1
    8000284e:	00f70863          	beq	a4,a5,8000285e <sigreturn+0x26>
    p->alarm_tp = 0;
    p->num_ticks = 0;
    p->alarm_status = 0;
  }
  return 0;
    80002852:	4501                	li	a0,0
    80002854:	60e2                	ld	ra,24(sp)
    80002856:	6442                	ld	s0,16(sp)
    80002858:	64a2                	ld	s1,8(sp)
    8000285a:	6105                	addi	sp,sp,32
    8000285c:	8082                	ret
    8000285e:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_tp, PGSIZE);
    80002860:	6605                	lui	a2,0x1
    80002862:	652c                	ld	a1,72(a0)
    80002864:	7928                	ld	a0,112(a0)
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	4c8080e7          	jalr	1224(ra) # 80000d2e <memmove>
    kfree(p->alarm_tp);
    8000286e:	64a8                	ld	a0,72(s1)
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	178080e7          	jalr	376(ra) # 800009e8 <kfree>
    p->alarm_tp = 0;
    80002878:	0404b423          	sd	zero,72(s1)
    p->num_ticks = 0;
    8000287c:	0204aa23          	sw	zero,52(s1)
    p->alarm_status = 0;
    80002880:	0204ac23          	sw	zero,56(s1)
    80002884:	b7f9                	j	80002852 <sigreturn+0x1a>

0000000080002886 <swtch>:
    80002886:	00153023          	sd	ra,0(a0)
    8000288a:	00253423          	sd	sp,8(a0)
    8000288e:	e900                	sd	s0,16(a0)
    80002890:	ed04                	sd	s1,24(a0)
    80002892:	03253023          	sd	s2,32(a0)
    80002896:	03353423          	sd	s3,40(a0)
    8000289a:	03453823          	sd	s4,48(a0)
    8000289e:	03553c23          	sd	s5,56(a0)
    800028a2:	05653023          	sd	s6,64(a0)
    800028a6:	05753423          	sd	s7,72(a0)
    800028aa:	05853823          	sd	s8,80(a0)
    800028ae:	05953c23          	sd	s9,88(a0)
    800028b2:	07a53023          	sd	s10,96(a0)
    800028b6:	07b53423          	sd	s11,104(a0)
    800028ba:	0005b083          	ld	ra,0(a1)
    800028be:	0085b103          	ld	sp,8(a1)
    800028c2:	6980                	ld	s0,16(a1)
    800028c4:	6d84                	ld	s1,24(a1)
    800028c6:	0205b903          	ld	s2,32(a1)
    800028ca:	0285b983          	ld	s3,40(a1)
    800028ce:	0305ba03          	ld	s4,48(a1)
    800028d2:	0385ba83          	ld	s5,56(a1)
    800028d6:	0405bb03          	ld	s6,64(a1)
    800028da:	0485bb83          	ld	s7,72(a1)
    800028de:	0505bc03          	ld	s8,80(a1)
    800028e2:	0585bc83          	ld	s9,88(a1)
    800028e6:	0605bd03          	ld	s10,96(a1)
    800028ea:	0685bd83          	ld	s11,104(a1)
    800028ee:	8082                	ret

00000000800028f0 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800028f0:	1141                	addi	sp,sp,-16
    800028f2:	e406                	sd	ra,8(sp)
    800028f4:	e022                	sd	s0,0(sp)
    800028f6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028f8:	00006597          	auipc	a1,0x6
    800028fc:	a0858593          	addi	a1,a1,-1528 # 80008300 <states.0+0x30>
    80002900:	00015517          	auipc	a0,0x15
    80002904:	eb050513          	addi	a0,a0,-336 # 800177b0 <tickslock>
    80002908:	ffffe097          	auipc	ra,0xffffe
    8000290c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
}
    80002910:	60a2                	ld	ra,8(sp)
    80002912:	6402                	ld	s0,0(sp)
    80002914:	0141                	addi	sp,sp,16
    80002916:	8082                	ret

0000000080002918 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002918:	1141                	addi	sp,sp,-16
    8000291a:	e422                	sd	s0,8(sp)
    8000291c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000291e:	00003797          	auipc	a5,0x3
    80002922:	63278793          	addi	a5,a5,1586 # 80005f50 <kernelvec>
    80002926:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000292a:	6422                	ld	s0,8(sp)
    8000292c:	0141                	addi	sp,sp,16
    8000292e:	8082                	ret

0000000080002930 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002930:	1141                	addi	sp,sp,-16
    80002932:	e406                	sd	ra,8(sp)
    80002934:	e022                	sd	s0,0(sp)
    80002936:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002938:	fffff097          	auipc	ra,0xfffff
    8000293c:	074080e7          	jalr	116(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002940:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002944:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000294a:	00004697          	auipc	a3,0x4
    8000294e:	6b668693          	addi	a3,a3,1718 # 80007000 <_trampoline>
    80002952:	00004717          	auipc	a4,0x4
    80002956:	6ae70713          	addi	a4,a4,1710 # 80007000 <_trampoline>
    8000295a:	8f15                	sub	a4,a4,a3
    8000295c:	040007b7          	lui	a5,0x4000
    80002960:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002962:	07b2                	slli	a5,a5,0xc
    80002964:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002966:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000296a:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000296c:	18002673          	csrr	a2,satp
    80002970:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002972:	7930                	ld	a2,112(a0)
    80002974:	6d38                	ld	a4,88(a0)
    80002976:	6585                	lui	a1,0x1
    80002978:	972e                	add	a4,a4,a1
    8000297a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000297c:	7938                	ld	a4,112(a0)
    8000297e:	00000617          	auipc	a2,0x0
    80002982:	13e60613          	addi	a2,a2,318 # 80002abc <usertrap>
    80002986:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002988:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000298a:	8612                	mv	a2,tp
    8000298c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000298e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002992:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002996:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000299e:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a0:	6f18                	ld	a4,24(a4)
    800029a2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029a6:	7528                	ld	a0,104(a0)
    800029a8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029aa:	00004717          	auipc	a4,0x4
    800029ae:	6f270713          	addi	a4,a4,1778 # 8000709c <userret>
    800029b2:	8f15                	sub	a4,a4,a3
    800029b4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029b6:	577d                	li	a4,-1
    800029b8:	177e                	slli	a4,a4,0x3f
    800029ba:	8d59                	or	a0,a0,a4
    800029bc:	9782                	jalr	a5
}
    800029be:	60a2                	ld	ra,8(sp)
    800029c0:	6402                	ld	s0,0(sp)
    800029c2:	0141                	addi	sp,sp,16
    800029c4:	8082                	ret

00000000800029c6 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800029c6:	1101                	addi	sp,sp,-32
    800029c8:	ec06                	sd	ra,24(sp)
    800029ca:	e822                	sd	s0,16(sp)
    800029cc:	e426                	sd	s1,8(sp)
    800029ce:	e04a                	sd	s2,0(sp)
    800029d0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029d2:	00015917          	auipc	s2,0x15
    800029d6:	dde90913          	addi	s2,s2,-546 # 800177b0 <tickslock>
    800029da:	854a                	mv	a0,s2
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	1fa080e7          	jalr	506(ra) # 80000bd6 <acquire>
  ticks++;
    800029e4:	00006497          	auipc	s1,0x6
    800029e8:	f2c48493          	addi	s1,s1,-212 # 80008910 <ticks>
    800029ec:	409c                	lw	a5,0(s1)
    800029ee:	2785                	addiw	a5,a5,1
    800029f0:	c09c                	sw	a5,0(s1)
  update_time();
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	db8080e7          	jalr	-584(ra) # 800027aa <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    800029fa:	8526                	mv	a0,s1
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	756080e7          	jalr	1878(ra) # 80002152 <wakeup>
  release(&tickslock);
    80002a04:	854a                	mv	a0,s2
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	284080e7          	jalr	644(ra) # 80000c8a <release>
}
    80002a0e:	60e2                	ld	ra,24(sp)
    80002a10:	6442                	ld	s0,16(sp)
    80002a12:	64a2                	ld	s1,8(sp)
    80002a14:	6902                	ld	s2,0(sp)
    80002a16:	6105                	addi	sp,sp,32
    80002a18:	8082                	ret

0000000080002a1a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a24:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002a28:	00074d63          	bltz	a4,80002a42 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002a2c:	57fd                	li	a5,-1
    80002a2e:	17fe                	slli	a5,a5,0x3f
    80002a30:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002a32:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002a34:	06f70363          	beq	a4,a5,80002a9a <devintr+0x80>
  }
}
    80002a38:	60e2                	ld	ra,24(sp)
    80002a3a:	6442                	ld	s0,16(sp)
    80002a3c:	64a2                	ld	s1,8(sp)
    80002a3e:	6105                	addi	sp,sp,32
    80002a40:	8082                	ret
      (scause & 0xff) == 9)
    80002a42:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002a46:	46a5                	li	a3,9
    80002a48:	fed792e3          	bne	a5,a3,80002a2c <devintr+0x12>
    int irq = plic_claim();
    80002a4c:	00003097          	auipc	ra,0x3
    80002a50:	60c080e7          	jalr	1548(ra) # 80006058 <plic_claim>
    80002a54:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002a56:	47a9                	li	a5,10
    80002a58:	02f50763          	beq	a0,a5,80002a86 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002a5c:	4785                	li	a5,1
    80002a5e:	02f50963          	beq	a0,a5,80002a90 <devintr+0x76>
    return 1;
    80002a62:	4505                	li	a0,1
    else if (irq)
    80002a64:	d8f1                	beqz	s1,80002a38 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a66:	85a6                	mv	a1,s1
    80002a68:	00006517          	auipc	a0,0x6
    80002a6c:	8a050513          	addi	a0,a0,-1888 # 80008308 <states.0+0x38>
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	b1a080e7          	jalr	-1254(ra) # 8000058a <printf>
      plic_complete(irq);
    80002a78:	8526                	mv	a0,s1
    80002a7a:	00003097          	auipc	ra,0x3
    80002a7e:	602080e7          	jalr	1538(ra) # 8000607c <plic_complete>
    return 1;
    80002a82:	4505                	li	a0,1
    80002a84:	bf55                	j	80002a38 <devintr+0x1e>
      uartintr();
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	f12080e7          	jalr	-238(ra) # 80000998 <uartintr>
    80002a8e:	b7ed                	j	80002a78 <devintr+0x5e>
      virtio_disk_intr();
    80002a90:	00004097          	auipc	ra,0x4
    80002a94:	ab4080e7          	jalr	-1356(ra) # 80006544 <virtio_disk_intr>
    80002a98:	b7c5                	j	80002a78 <devintr+0x5e>
    if (cpuid() == 0)
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	ee6080e7          	jalr	-282(ra) # 80001980 <cpuid>
    80002aa2:	c901                	beqz	a0,80002ab2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002aa4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aa8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aaa:	14479073          	csrw	sip,a5
    return 2;
    80002aae:	4509                	li	a0,2
    80002ab0:	b761                	j	80002a38 <devintr+0x1e>
      clockintr();
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	f14080e7          	jalr	-236(ra) # 800029c6 <clockintr>
    80002aba:	b7ed                	j	80002aa4 <devintr+0x8a>

0000000080002abc <usertrap>:
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	e04a                	sd	s2,0(sp)
    80002ac6:	1000                	addi	s0,sp,32
  arr[0].timeslice = 1;
    80002ac8:	00015797          	auipc	a5,0x15
    80002acc:	ce878793          	addi	a5,a5,-792 # 800177b0 <tickslock>
    80002ad0:	4705                	li	a4,1
    80002ad2:	cf98                	sw	a4,24(a5)
  arr[1].timeslice = 3;
    80002ad4:	470d                	li	a4,3
    80002ad6:	cfd8                	sw	a4,28(a5)
  arr[2].timeslice = 9;
    80002ad8:	4725                	li	a4,9
    80002ada:	d398                	sw	a4,32(a5)
  arr[3].timeslice = 15;
    80002adc:	473d                	li	a4,15
    80002ade:	d3d8                	sw	a4,36(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae0:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae4:	1007f793          	andi	a5,a5,256
    80002ae8:	ebb5                	bnez	a5,80002b5c <usertrap+0xa0>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aea:	00003797          	auipc	a5,0x3
    80002aee:	46678793          	addi	a5,a5,1126 # 80005f50 <kernelvec>
    80002af2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	eb6080e7          	jalr	-330(ra) # 800019ac <myproc>
    80002afe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b00:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	14102773          	csrr	a4,sepc
    80002b06:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b0c:	47a1                	li	a5,8
    80002b0e:	04f70f63          	beq	a4,a5,80002b6c <usertrap+0xb0>
  else if ((which_dev = devintr()) != 0)
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	f08080e7          	jalr	-248(ra) # 80002a1a <devintr>
    80002b1a:	c155                	beqz	a0,80002bbe <usertrap+0x102>
    if (which_dev == 2)
    80002b1c:	4789                	li	a5,2
    80002b1e:	06f51a63          	bne	a0,a5,80002b92 <usertrap+0xd6>
      p->num_ticks++;
    80002b22:	58dc                	lw	a5,52(s1)
    80002b24:	2785                	addiw	a5,a5,1
    80002b26:	0007871b          	sext.w	a4,a5
    80002b2a:	d8dc                	sw	a5,52(s1)
      if (p->num_ticks == p->ticks && p->alarm_status == 0)
    80002b2c:	5cdc                	lw	a5,60(s1)
    80002b2e:	06e79263          	bne	a5,a4,80002b92 <usertrap+0xd6>
    80002b32:	5c9c                	lw	a5,56(s1)
    80002b34:	efb9                	bnez	a5,80002b92 <usertrap+0xd6>
        p->alarm_status = 1;
    80002b36:	4785                	li	a5,1
    80002b38:	dc9c                	sw	a5,56(s1)
        struct trapframe *tp = kalloc();
    80002b3a:	ffffe097          	auipc	ra,0xffffe
    80002b3e:	fac080e7          	jalr	-84(ra) # 80000ae6 <kalloc>
    80002b42:	892a                	mv	s2,a0
        memmove(tp, p->trapframe, PGSIZE);
    80002b44:	6605                	lui	a2,0x1
    80002b46:	78ac                	ld	a1,112(s1)
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	1e6080e7          	jalr	486(ra) # 80000d2e <memmove>
        p->alarm_tp = tp;
    80002b50:	0524b423          	sd	s2,72(s1)
        p->trapframe->epc = p->handler;
    80002b54:	78bc                	ld	a5,112(s1)
    80002b56:	60b8                	ld	a4,64(s1)
    80002b58:	ef98                	sd	a4,24(a5)
    80002b5a:	a825                	j	80002b92 <usertrap+0xd6>
    panic("usertrap: not from user mode");
    80002b5c:	00005517          	auipc	a0,0x5
    80002b60:	7cc50513          	addi	a0,a0,1996 # 80008328 <states.0+0x58>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	9dc080e7          	jalr	-1572(ra) # 80000540 <panic>
    if (killed(p))
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	836080e7          	jalr	-1994(ra) # 800023a2 <killed>
    80002b74:	ed1d                	bnez	a0,80002bb2 <usertrap+0xf6>
    p->trapframe->epc += 4;
    80002b76:	78b8                	ld	a4,112(s1)
    80002b78:	6f1c                	ld	a5,24(a4)
    80002b7a:	0791                	addi	a5,a5,4
    80002b7c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b86:	10079073          	csrw	sstatus,a5
    syscall();
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	2b4080e7          	jalr	692(ra) # 80002e3e <syscall>
  if (killed(p))
    80002b92:	8526                	mv	a0,s1
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	80e080e7          	jalr	-2034(ra) # 800023a2 <killed>
    80002b9c:	ed31                	bnez	a0,80002bf8 <usertrap+0x13c>
  usertrapret();
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	d92080e7          	jalr	-622(ra) # 80002930 <usertrapret>
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6902                	ld	s2,0(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret
      exit(-1);
    80002bb2:	557d                	li	a0,-1
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	66e080e7          	jalr	1646(ra) # 80002222 <exit>
    80002bbc:	bf6d                	j	80002b76 <usertrap+0xba>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bbe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bc2:	5890                	lw	a2,48(s1)
    80002bc4:	00005517          	auipc	a0,0x5
    80002bc8:	78450513          	addi	a0,a0,1924 # 80008348 <states.0+0x78>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9be080e7          	jalr	-1602(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bd8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bdc:	00005517          	auipc	a0,0x5
    80002be0:	79c50513          	addi	a0,a0,1948 # 80008378 <states.0+0xa8>
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	9a6080e7          	jalr	-1626(ra) # 8000058a <printf>
    setkilled(p);
    80002bec:	8526                	mv	a0,s1
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	788080e7          	jalr	1928(ra) # 80002376 <setkilled>
    80002bf6:	bf71                	j	80002b92 <usertrap+0xd6>
    exit(-1);
    80002bf8:	557d                	li	a0,-1
    80002bfa:	fffff097          	auipc	ra,0xfffff
    80002bfe:	628080e7          	jalr	1576(ra) # 80002222 <exit>
    80002c02:	bf71                	j	80002b9e <usertrap+0xe2>

0000000080002c04 <kerneltrap>:
{
    80002c04:	7179                	addi	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	e44e                	sd	s3,8(sp)
    80002c10:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c16:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1a:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002c1e:	1004f793          	andi	a5,s1,256
    80002c22:	cb85                	beqz	a5,80002c52 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c24:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c28:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002c2a:	ef85                	bnez	a5,80002c62 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	dee080e7          	jalr	-530(ra) # 80002a1a <devintr>
    80002c34:	cd1d                	beqz	a0,80002c72 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c36:	4789                	li	a5,2
    80002c38:	06f50a63          	beq	a0,a5,80002cac <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c3c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c40:	10049073          	csrw	sstatus,s1
}
    80002c44:	70a2                	ld	ra,40(sp)
    80002c46:	7402                	ld	s0,32(sp)
    80002c48:	64e2                	ld	s1,24(sp)
    80002c4a:	6942                	ld	s2,16(sp)
    80002c4c:	69a2                	ld	s3,8(sp)
    80002c4e:	6145                	addi	sp,sp,48
    80002c50:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	74650513          	addi	a0,a0,1862 # 80008398 <states.0+0xc8>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	8e6080e7          	jalr	-1818(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	75e50513          	addi	a0,a0,1886 # 800083c0 <states.0+0xf0>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	8d6080e7          	jalr	-1834(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c72:	85ce                	mv	a1,s3
    80002c74:	00005517          	auipc	a0,0x5
    80002c78:	76c50513          	addi	a0,a0,1900 # 800083e0 <states.0+0x110>
    80002c7c:	ffffe097          	auipc	ra,0xffffe
    80002c80:	90e080e7          	jalr	-1778(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c84:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c88:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	76450513          	addi	a0,a0,1892 # 800083f0 <states.0+0x120>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8f6080e7          	jalr	-1802(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002c9c:	00005517          	auipc	a0,0x5
    80002ca0:	76c50513          	addi	a0,a0,1900 # 80008408 <states.0+0x138>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	89c080e7          	jalr	-1892(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	d00080e7          	jalr	-768(ra) # 800019ac <myproc>
    80002cb4:	d541                	beqz	a0,80002c3c <kerneltrap+0x38>
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	cf6080e7          	jalr	-778(ra) # 800019ac <myproc>
    80002cbe:	bfbd                	j	80002c3c <kerneltrap+0x38>

0000000080002cc0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	ce0080e7          	jalr	-800(ra) # 800019ac <myproc>
  switch (n)
    80002cd4:	4795                	li	a5,5
    80002cd6:	0497e163          	bltu	a5,s1,80002d18 <argraw+0x58>
    80002cda:	048a                	slli	s1,s1,0x2
    80002cdc:	00005717          	auipc	a4,0x5
    80002ce0:	76470713          	addi	a4,a4,1892 # 80008440 <states.0+0x170>
    80002ce4:	94ba                	add	s1,s1,a4
    80002ce6:	409c                	lw	a5,0(s1)
    80002ce8:	97ba                	add	a5,a5,a4
    80002cea:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002cec:	793c                	ld	a5,112(a0)
    80002cee:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf0:	60e2                	ld	ra,24(sp)
    80002cf2:	6442                	ld	s0,16(sp)
    80002cf4:	64a2                	ld	s1,8(sp)
    80002cf6:	6105                	addi	sp,sp,32
    80002cf8:	8082                	ret
    return p->trapframe->a1;
    80002cfa:	793c                	ld	a5,112(a0)
    80002cfc:	7fa8                	ld	a0,120(a5)
    80002cfe:	bfcd                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a2;
    80002d00:	793c                	ld	a5,112(a0)
    80002d02:	63c8                	ld	a0,128(a5)
    80002d04:	b7f5                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a3;
    80002d06:	793c                	ld	a5,112(a0)
    80002d08:	67c8                	ld	a0,136(a5)
    80002d0a:	b7dd                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a4;
    80002d0c:	793c                	ld	a5,112(a0)
    80002d0e:	6bc8                	ld	a0,144(a5)
    80002d10:	b7c5                	j	80002cf0 <argraw+0x30>
    return p->trapframe->a5;
    80002d12:	793c                	ld	a5,112(a0)
    80002d14:	6fc8                	ld	a0,152(a5)
    80002d16:	bfe9                	j	80002cf0 <argraw+0x30>
  panic("argraw");
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	70050513          	addi	a0,a0,1792 # 80008418 <states.0+0x148>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>

0000000080002d28 <fetchaddr>:
{
    80002d28:	1101                	addi	sp,sp,-32
    80002d2a:	ec06                	sd	ra,24(sp)
    80002d2c:	e822                	sd	s0,16(sp)
    80002d2e:	e426                	sd	s1,8(sp)
    80002d30:	e04a                	sd	s2,0(sp)
    80002d32:	1000                	addi	s0,sp,32
    80002d34:	84aa                	mv	s1,a0
    80002d36:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	c74080e7          	jalr	-908(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d40:	713c                	ld	a5,96(a0)
    80002d42:	02f4f863          	bgeu	s1,a5,80002d72 <fetchaddr+0x4a>
    80002d46:	00848713          	addi	a4,s1,8
    80002d4a:	02e7e663          	bltu	a5,a4,80002d76 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d4e:	46a1                	li	a3,8
    80002d50:	8626                	mv	a2,s1
    80002d52:	85ca                	mv	a1,s2
    80002d54:	7528                	ld	a0,104(a0)
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	9a2080e7          	jalr	-1630(ra) # 800016f8 <copyin>
    80002d5e:	00a03533          	snez	a0,a0
    80002d62:	40a00533          	neg	a0,a0
}
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	64a2                	ld	s1,8(sp)
    80002d6c:	6902                	ld	s2,0(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret
    return -1;
    80002d72:	557d                	li	a0,-1
    80002d74:	bfcd                	j	80002d66 <fetchaddr+0x3e>
    80002d76:	557d                	li	a0,-1
    80002d78:	b7fd                	j	80002d66 <fetchaddr+0x3e>

0000000080002d7a <fetchstr>:
{
    80002d7a:	7179                	addi	sp,sp,-48
    80002d7c:	f406                	sd	ra,40(sp)
    80002d7e:	f022                	sd	s0,32(sp)
    80002d80:	ec26                	sd	s1,24(sp)
    80002d82:	e84a                	sd	s2,16(sp)
    80002d84:	e44e                	sd	s3,8(sp)
    80002d86:	1800                	addi	s0,sp,48
    80002d88:	892a                	mv	s2,a0
    80002d8a:	84ae                	mv	s1,a1
    80002d8c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d8e:	fffff097          	auipc	ra,0xfffff
    80002d92:	c1e080e7          	jalr	-994(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d96:	86ce                	mv	a3,s3
    80002d98:	864a                	mv	a2,s2
    80002d9a:	85a6                	mv	a1,s1
    80002d9c:	7528                	ld	a0,104(a0)
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	9e8080e7          	jalr	-1560(ra) # 80001786 <copyinstr>
    80002da6:	00054e63          	bltz	a0,80002dc2 <fetchstr+0x48>
  return strlen(buf);
    80002daa:	8526                	mv	a0,s1
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	0a2080e7          	jalr	162(ra) # 80000e4e <strlen>
}
    80002db4:	70a2                	ld	ra,40(sp)
    80002db6:	7402                	ld	s0,32(sp)
    80002db8:	64e2                	ld	s1,24(sp)
    80002dba:	6942                	ld	s2,16(sp)
    80002dbc:	69a2                	ld	s3,8(sp)
    80002dbe:	6145                	addi	sp,sp,48
    80002dc0:	8082                	ret
    return -1;
    80002dc2:	557d                	li	a0,-1
    80002dc4:	bfc5                	j	80002db4 <fetchstr+0x3a>

0000000080002dc6 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	e426                	sd	s1,8(sp)
    80002dce:	1000                	addi	s0,sp,32
    80002dd0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	eee080e7          	jalr	-274(ra) # 80002cc0 <argraw>
    80002dda:	c088                	sw	a0,0(s1)
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	1000                	addi	s0,sp,32
    80002df0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	ece080e7          	jalr	-306(ra) # 80002cc0 <argraw>
    80002dfa:	e088                	sd	a0,0(s1)
}
    80002dfc:	60e2                	ld	ra,24(sp)
    80002dfe:	6442                	ld	s0,16(sp)
    80002e00:	64a2                	ld	s1,8(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e06:	7179                	addi	sp,sp,-48
    80002e08:	f406                	sd	ra,40(sp)
    80002e0a:	f022                	sd	s0,32(sp)
    80002e0c:	ec26                	sd	s1,24(sp)
    80002e0e:	e84a                	sd	s2,16(sp)
    80002e10:	1800                	addi	s0,sp,48
    80002e12:	84ae                	mv	s1,a1
    80002e14:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e16:	fd840593          	addi	a1,s0,-40
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	fcc080e7          	jalr	-52(ra) # 80002de6 <argaddr>
  return fetchstr(addr, buf, max);
    80002e22:	864a                	mv	a2,s2
    80002e24:	85a6                	mv	a1,s1
    80002e26:	fd843503          	ld	a0,-40(s0)
    80002e2a:	00000097          	auipc	ra,0x0
    80002e2e:	f50080e7          	jalr	-176(ra) # 80002d7a <fetchstr>
}
    80002e32:	70a2                	ld	ra,40(sp)
    80002e34:	7402                	ld	s0,32(sp)
    80002e36:	64e2                	ld	s1,24(sp)
    80002e38:	6942                	ld	s2,16(sp)
    80002e3a:	6145                	addi	sp,sp,48
    80002e3c:	8082                	ret

0000000080002e3e <syscall>:
    [SYS_sigalarm] sys_sigalarm,
    [SYS_sigreturn] sys_sigreturn,
};

void syscall(void)
{
    80002e3e:	1101                	addi	sp,sp,-32
    80002e40:	ec06                	sd	ra,24(sp)
    80002e42:	e822                	sd	s0,16(sp)
    80002e44:	e426                	sd	s1,8(sp)
    80002e46:	e04a                	sd	s2,0(sp)
    80002e48:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	b62080e7          	jalr	-1182(ra) # 800019ac <myproc>
    80002e52:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e54:	07053903          	ld	s2,112(a0)
    80002e58:	0a893783          	ld	a5,168(s2)
    80002e5c:	0007869b          	sext.w	a3,a5
  if (num == 5)
    80002e60:	4715                	li	a4,5
    80002e62:	02e68363          	beq	a3,a4,80002e88 <syscall+0x4a>
    else
    {
      sum++;
    }
  }
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e66:	37fd                	addiw	a5,a5,-1
    80002e68:	4761                	li	a4,24
    80002e6a:	04f76563          	bltu	a4,a5,80002eb4 <syscall+0x76>
    80002e6e:	00369713          	slli	a4,a3,0x3
    80002e72:	00005797          	auipc	a5,0x5
    80002e76:	5e678793          	addi	a5,a5,1510 # 80008458 <syscalls>
    80002e7a:	97ba                	add	a5,a5,a4
    80002e7c:	6398                	ld	a4,0(a5)
    80002e7e:	cb1d                	beqz	a4,80002eb4 <syscall+0x76>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e80:	9702                	jalr	a4
    80002e82:	06a93823          	sd	a0,112(s2)
    80002e86:	a0a9                	j	80002ed0 <syscall+0x92>
    if (p->name[0] == 's' && p->name[1] == 'h')
    80002e88:	17055603          	lhu	a2,368(a0)
    80002e8c:	671d                	lui	a4,0x7
    80002e8e:	87370713          	addi	a4,a4,-1933 # 6873 <_entry-0x7fff978d>
    80002e92:	00e60963          	beq	a2,a4,80002ea4 <syscall+0x66>
      sum++;
    80002e96:	00006617          	auipc	a2,0x6
    80002e9a:	a7e60613          	addi	a2,a2,-1410 # 80008914 <sum>
    80002e9e:	4218                	lw	a4,0(a2)
    80002ea0:	2705                	addiw	a4,a4,1
    80002ea2:	c218                	sw	a4,0(a2)
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002ea4:	37fd                	addiw	a5,a5,-1
    80002ea6:	4661                	li	a2,24
    80002ea8:	00002717          	auipc	a4,0x2
    80002eac:	6f670713          	addi	a4,a4,1782 # 8000559e <sys_read>
    80002eb0:	fcf678e3          	bgeu	a2,a5,80002e80 <syscall+0x42>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002eb4:	17048613          	addi	a2,s1,368
    80002eb8:	588c                	lw	a1,48(s1)
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	56650513          	addi	a0,a0,1382 # 80008420 <states.0+0x150>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	6c8080e7          	jalr	1736(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eca:	78bc                	ld	a5,112(s1)
    80002ecc:	577d                	li	a4,-1
    80002ece:	fbb8                	sd	a4,112(a5)
  }
}
    80002ed0:	60e2                	ld	ra,24(sp)
    80002ed2:	6442                	ld	s0,16(sp)
    80002ed4:	64a2                	ld	s1,8(sp)
    80002ed6:	6902                	ld	s2,0(sp)
    80002ed8:	6105                	addi	sp,sp,32
    80002eda:	8082                	ret

0000000080002edc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002ee4:	fec40593          	addi	a1,s0,-20
    80002ee8:	4501                	li	a0,0
    80002eea:	00000097          	auipc	ra,0x0
    80002eee:	edc080e7          	jalr	-292(ra) # 80002dc6 <argint>
  exit(n);
    80002ef2:	fec42503          	lw	a0,-20(s0)
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	32c080e7          	jalr	812(ra) # 80002222 <exit>
  return 0; // not reached
}
    80002efe:	4501                	li	a0,0
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f08:	1141                	addi	sp,sp,-16
    80002f0a:	e406                	sd	ra,8(sp)
    80002f0c:	e022                	sd	s0,0(sp)
    80002f0e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	a9c080e7          	jalr	-1380(ra) # 800019ac <myproc>
}
    80002f18:	5908                	lw	a0,48(a0)
    80002f1a:	60a2                	ld	ra,8(sp)
    80002f1c:	6402                	ld	s0,0(sp)
    80002f1e:	0141                	addi	sp,sp,16
    80002f20:	8082                	ret

0000000080002f22 <sys_fork>:

uint64
sys_fork(void)
{
    80002f22:	1141                	addi	sp,sp,-16
    80002f24:	e406                	sd	ra,8(sp)
    80002f26:	e022                	sd	s0,0(sp)
    80002f28:	0800                	addi	s0,sp,16
  return fork();
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	e5c080e7          	jalr	-420(ra) # 80001d86 <fork>
}
    80002f32:	60a2                	ld	ra,8(sp)
    80002f34:	6402                	ld	s0,0(sp)
    80002f36:	0141                	addi	sp,sp,16
    80002f38:	8082                	ret

0000000080002f3a <sys_wait>:

uint64
sys_wait(void)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f42:	fe840593          	addi	a1,s0,-24
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	e9e080e7          	jalr	-354(ra) # 80002de6 <argaddr>
  return wait(p);
    80002f50:	fe843503          	ld	a0,-24(s0)
    80002f54:	fffff097          	auipc	ra,0xfffff
    80002f58:	480080e7          	jalr	1152(ra) # 800023d4 <wait>
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	6105                	addi	sp,sp,32
    80002f62:	8082                	ret

0000000080002f64 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f64:	7179                	addi	sp,sp,-48
    80002f66:	f406                	sd	ra,40(sp)
    80002f68:	f022                	sd	s0,32(sp)
    80002f6a:	ec26                	sd	s1,24(sp)
    80002f6c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f6e:	fdc40593          	addi	a1,s0,-36
    80002f72:	4501                	li	a0,0
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	e52080e7          	jalr	-430(ra) # 80002dc6 <argint>
  addr = myproc()->sz;
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	a30080e7          	jalr	-1488(ra) # 800019ac <myproc>
    80002f84:	7124                	ld	s1,96(a0)
  if (growproc(n) < 0)
    80002f86:	fdc42503          	lw	a0,-36(s0)
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	da0080e7          	jalr	-608(ra) # 80001d2a <growproc>
    80002f92:	00054863          	bltz	a0,80002fa2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f96:	8526                	mv	a0,s1
    80002f98:	70a2                	ld	ra,40(sp)
    80002f9a:	7402                	ld	s0,32(sp)
    80002f9c:	64e2                	ld	s1,24(sp)
    80002f9e:	6145                	addi	sp,sp,48
    80002fa0:	8082                	ret
    return -1;
    80002fa2:	54fd                	li	s1,-1
    80002fa4:	bfcd                	j	80002f96 <sys_sbrk+0x32>

0000000080002fa6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fa6:	7139                	addi	sp,sp,-64
    80002fa8:	fc06                	sd	ra,56(sp)
    80002faa:	f822                	sd	s0,48(sp)
    80002fac:	f426                	sd	s1,40(sp)
    80002fae:	f04a                	sd	s2,32(sp)
    80002fb0:	ec4e                	sd	s3,24(sp)
    80002fb2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fb4:	fcc40593          	addi	a1,s0,-52
    80002fb8:	4501                	li	a0,0
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	e0c080e7          	jalr	-500(ra) # 80002dc6 <argint>
  acquire(&tickslock);
    80002fc2:	00014517          	auipc	a0,0x14
    80002fc6:	7ee50513          	addi	a0,a0,2030 # 800177b0 <tickslock>
    80002fca:	ffffe097          	auipc	ra,0xffffe
    80002fce:	c0c080e7          	jalr	-1012(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002fd2:	00006917          	auipc	s2,0x6
    80002fd6:	93e92903          	lw	s2,-1730(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    80002fda:	fcc42783          	lw	a5,-52(s0)
    80002fde:	cf9d                	beqz	a5,8000301c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fe0:	00014997          	auipc	s3,0x14
    80002fe4:	7d098993          	addi	s3,s3,2000 # 800177b0 <tickslock>
    80002fe8:	00006497          	auipc	s1,0x6
    80002fec:	92848493          	addi	s1,s1,-1752 # 80008910 <ticks>
    if (killed(myproc()))
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	9bc080e7          	jalr	-1604(ra) # 800019ac <myproc>
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	3aa080e7          	jalr	938(ra) # 800023a2 <killed>
    80003000:	ed15                	bnez	a0,8000303c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003002:	85ce                	mv	a1,s3
    80003004:	8526                	mv	a0,s1
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	0e8080e7          	jalr	232(ra) # 800020ee <sleep>
  while (ticks - ticks0 < n)
    8000300e:	409c                	lw	a5,0(s1)
    80003010:	412787bb          	subw	a5,a5,s2
    80003014:	fcc42703          	lw	a4,-52(s0)
    80003018:	fce7ece3          	bltu	a5,a4,80002ff0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000301c:	00014517          	auipc	a0,0x14
    80003020:	79450513          	addi	a0,a0,1940 # 800177b0 <tickslock>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	c66080e7          	jalr	-922(ra) # 80000c8a <release>
  return 0;
    8000302c:	4501                	li	a0,0
}
    8000302e:	70e2                	ld	ra,56(sp)
    80003030:	7442                	ld	s0,48(sp)
    80003032:	74a2                	ld	s1,40(sp)
    80003034:	7902                	ld	s2,32(sp)
    80003036:	69e2                	ld	s3,24(sp)
    80003038:	6121                	addi	sp,sp,64
    8000303a:	8082                	ret
      release(&tickslock);
    8000303c:	00014517          	auipc	a0,0x14
    80003040:	77450513          	addi	a0,a0,1908 # 800177b0 <tickslock>
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c46080e7          	jalr	-954(ra) # 80000c8a <release>
      return -1;
    8000304c:	557d                	li	a0,-1
    8000304e:	b7c5                	j	8000302e <sys_sleep+0x88>

0000000080003050 <sys_kill>:

uint64
sys_kill(void)
{
    80003050:	1101                	addi	sp,sp,-32
    80003052:	ec06                	sd	ra,24(sp)
    80003054:	e822                	sd	s0,16(sp)
    80003056:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003058:	fec40593          	addi	a1,s0,-20
    8000305c:	4501                	li	a0,0
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	d68080e7          	jalr	-664(ra) # 80002dc6 <argint>
  return kill(pid);
    80003066:	fec42503          	lw	a0,-20(s0)
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	29a080e7          	jalr	666(ra) # 80002304 <kill>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003084:	00014517          	auipc	a0,0x14
    80003088:	72c50513          	addi	a0,a0,1836 # 800177b0 <tickslock>
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	b4a080e7          	jalr	-1206(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003094:	00006497          	auipc	s1,0x6
    80003098:	87c4a483          	lw	s1,-1924(s1) # 80008910 <ticks>
  release(&tickslock);
    8000309c:	00014517          	auipc	a0,0x14
    800030a0:	71450513          	addi	a0,a0,1812 # 800177b0 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	be6080e7          	jalr	-1050(ra) # 80000c8a <release>
  return xticks;
}
    800030ac:	02049513          	slli	a0,s1,0x20
    800030b0:	9101                	srli	a0,a0,0x20
    800030b2:	60e2                	ld	ra,24(sp)
    800030b4:	6442                	ld	s0,16(sp)
    800030b6:	64a2                	ld	s1,8(sp)
    800030b8:	6105                	addi	sp,sp,32
    800030ba:	8082                	ret

00000000800030bc <sys_waitx>:

uint64
sys_waitx(void)
{
    800030bc:	7139                	addi	sp,sp,-64
    800030be:	fc06                	sd	ra,56(sp)
    800030c0:	f822                	sd	s0,48(sp)
    800030c2:	f426                	sd	s1,40(sp)
    800030c4:	f04a                	sd	s2,32(sp)
    800030c6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030c8:	fd840593          	addi	a1,s0,-40
    800030cc:	4501                	li	a0,0
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	d18080e7          	jalr	-744(ra) # 80002de6 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800030d6:	fd040593          	addi	a1,s0,-48
    800030da:	4505                	li	a0,1
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	d0a080e7          	jalr	-758(ra) # 80002de6 <argaddr>
  argaddr(2, &addr2);
    800030e4:	fc840593          	addi	a1,s0,-56
    800030e8:	4509                	li	a0,2
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	cfc080e7          	jalr	-772(ra) # 80002de6 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800030f2:	fc040613          	addi	a2,s0,-64
    800030f6:	fc440593          	addi	a1,s0,-60
    800030fa:	fd843503          	ld	a0,-40(s0)
    800030fe:	fffff097          	auipc	ra,0xfffff
    80003102:	560080e7          	jalr	1376(ra) # 8000265e <waitx>
    80003106:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003108:	fffff097          	auipc	ra,0xfffff
    8000310c:	8a4080e7          	jalr	-1884(ra) # 800019ac <myproc>
    80003110:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003112:	4691                	li	a3,4
    80003114:	fc440613          	addi	a2,s0,-60
    80003118:	fd043583          	ld	a1,-48(s0)
    8000311c:	7528                	ld	a0,104(a0)
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	54e080e7          	jalr	1358(ra) # 8000166c <copyout>
    return -1;
    80003126:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003128:	00054f63          	bltz	a0,80003146 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000312c:	4691                	li	a3,4
    8000312e:	fc040613          	addi	a2,s0,-64
    80003132:	fc843583          	ld	a1,-56(s0)
    80003136:	74a8                	ld	a0,104(s1)
    80003138:	ffffe097          	auipc	ra,0xffffe
    8000313c:	534080e7          	jalr	1332(ra) # 8000166c <copyout>
    80003140:	00054a63          	bltz	a0,80003154 <sys_waitx+0x98>
    return -1;
  return ret;
    80003144:	87ca                	mv	a5,s2
}
    80003146:	853e                	mv	a0,a5
    80003148:	70e2                	ld	ra,56(sp)
    8000314a:	7442                	ld	s0,48(sp)
    8000314c:	74a2                	ld	s1,40(sp)
    8000314e:	7902                	ld	s2,32(sp)
    80003150:	6121                	addi	sp,sp,64
    80003152:	8082                	ret
    return -1;
    80003154:	57fd                	li	a5,-1
    80003156:	bfc5                	j	80003146 <sys_waitx+0x8a>

0000000080003158 <sys_sigalarm>:

uint64 
sys_sigalarm(void)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	1000                	addi	s0,sp,32
  int n;
  argint(0,&n);
    80003160:	fec40593          	addi	a1,s0,-20
    80003164:	4501                	li	a0,0
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	c60080e7          	jalr	-928(ra) # 80002dc6 <argint>
  uint64 handler;
  argaddr(1,&handler);
    8000316e:	fe040593          	addi	a1,s0,-32
    80003172:	4505                	li	a0,1
    80003174:	00000097          	auipc	ra,0x0
    80003178:	c72080e7          	jalr	-910(ra) # 80002de6 <argaddr>
  sigalarm(n,handler);
    8000317c:	fe043583          	ld	a1,-32(s0)
    80003180:	fec42503          	lw	a0,-20(s0)
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	684080e7          	jalr	1668(ra) # 80002808 <sigalarm>
  return 0;
}
    8000318c:	4501                	li	a0,0
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	6105                	addi	sp,sp,32
    80003194:	8082                	ret

0000000080003196 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80003196:	1141                	addi	sp,sp,-16
    80003198:	e406                	sd	ra,8(sp)
    8000319a:	e022                	sd	s0,0(sp)
    8000319c:	0800                	addi	s0,sp,16
  return sigreturn();
    8000319e:	fffff097          	auipc	ra,0xfffff
    800031a2:	69a080e7          	jalr	1690(ra) # 80002838 <sigreturn>
}
    800031a6:	60a2                	ld	ra,8(sp)
    800031a8:	6402                	ld	s0,0(sp)
    800031aa:	0141                	addi	sp,sp,16
    800031ac:	8082                	ret

00000000800031ae <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800031ae:	7179                	addi	sp,sp,-48
    800031b0:	f406                	sd	ra,40(sp)
    800031b2:	f022                	sd	s0,32(sp)
    800031b4:	ec26                	sd	s1,24(sp)
    800031b6:	e84a                	sd	s2,16(sp)
    800031b8:	e44e                	sd	s3,8(sp)
    800031ba:	e052                	sd	s4,0(sp)
    800031bc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800031be:	00005597          	auipc	a1,0x5
    800031c2:	36a58593          	addi	a1,a1,874 # 80008528 <syscalls+0xd0>
    800031c6:	00014517          	auipc	a0,0x14
    800031ca:	61250513          	addi	a0,a0,1554 # 800177d8 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	978080e7          	jalr	-1672(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031d6:	0001c797          	auipc	a5,0x1c
    800031da:	60278793          	addi	a5,a5,1538 # 8001f7d8 <bcache+0x8000>
    800031de:	0001d717          	auipc	a4,0x1d
    800031e2:	86270713          	addi	a4,a4,-1950 # 8001fa40 <bcache+0x8268>
    800031e6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031ea:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ee:	00014497          	auipc	s1,0x14
    800031f2:	60248493          	addi	s1,s1,1538 # 800177f0 <bcache+0x18>
    b->next = bcache.head.next;
    800031f6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031f8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031fa:	00005a17          	auipc	s4,0x5
    800031fe:	336a0a13          	addi	s4,s4,822 # 80008530 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003202:	2b893783          	ld	a5,696(s2)
    80003206:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003208:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000320c:	85d2                	mv	a1,s4
    8000320e:	01048513          	addi	a0,s1,16
    80003212:	00001097          	auipc	ra,0x1
    80003216:	4c8080e7          	jalr	1224(ra) # 800046da <initsleeplock>
    bcache.head.next->prev = b;
    8000321a:	2b893783          	ld	a5,696(s2)
    8000321e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003220:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003224:	45848493          	addi	s1,s1,1112
    80003228:	fd349de3          	bne	s1,s3,80003202 <binit+0x54>
  }
}
    8000322c:	70a2                	ld	ra,40(sp)
    8000322e:	7402                	ld	s0,32(sp)
    80003230:	64e2                	ld	s1,24(sp)
    80003232:	6942                	ld	s2,16(sp)
    80003234:	69a2                	ld	s3,8(sp)
    80003236:	6a02                	ld	s4,0(sp)
    80003238:	6145                	addi	sp,sp,48
    8000323a:	8082                	ret

000000008000323c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000323c:	7179                	addi	sp,sp,-48
    8000323e:	f406                	sd	ra,40(sp)
    80003240:	f022                	sd	s0,32(sp)
    80003242:	ec26                	sd	s1,24(sp)
    80003244:	e84a                	sd	s2,16(sp)
    80003246:	e44e                	sd	s3,8(sp)
    80003248:	1800                	addi	s0,sp,48
    8000324a:	892a                	mv	s2,a0
    8000324c:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000324e:	00014517          	auipc	a0,0x14
    80003252:	58a50513          	addi	a0,a0,1418 # 800177d8 <bcache>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	980080e7          	jalr	-1664(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000325e:	0001d497          	auipc	s1,0x1d
    80003262:	8324b483          	ld	s1,-1998(s1) # 8001fa90 <bcache+0x82b8>
    80003266:	0001c797          	auipc	a5,0x1c
    8000326a:	7da78793          	addi	a5,a5,2010 # 8001fa40 <bcache+0x8268>
    8000326e:	02f48f63          	beq	s1,a5,800032ac <bread+0x70>
    80003272:	873e                	mv	a4,a5
    80003274:	a021                	j	8000327c <bread+0x40>
    80003276:	68a4                	ld	s1,80(s1)
    80003278:	02e48a63          	beq	s1,a4,800032ac <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000327c:	449c                	lw	a5,8(s1)
    8000327e:	ff279ce3          	bne	a5,s2,80003276 <bread+0x3a>
    80003282:	44dc                	lw	a5,12(s1)
    80003284:	ff3799e3          	bne	a5,s3,80003276 <bread+0x3a>
      b->refcnt++;
    80003288:	40bc                	lw	a5,64(s1)
    8000328a:	2785                	addiw	a5,a5,1
    8000328c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	54a50513          	addi	a0,a0,1354 # 800177d8 <bcache>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	9f4080e7          	jalr	-1548(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000329e:	01048513          	addi	a0,s1,16
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	472080e7          	jalr	1138(ra) # 80004714 <acquiresleep>
      return b;
    800032aa:	a8b9                	j	80003308 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032ac:	0001c497          	auipc	s1,0x1c
    800032b0:	7dc4b483          	ld	s1,2012(s1) # 8001fa88 <bcache+0x82b0>
    800032b4:	0001c797          	auipc	a5,0x1c
    800032b8:	78c78793          	addi	a5,a5,1932 # 8001fa40 <bcache+0x8268>
    800032bc:	00f48863          	beq	s1,a5,800032cc <bread+0x90>
    800032c0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800032c2:	40bc                	lw	a5,64(s1)
    800032c4:	cf81                	beqz	a5,800032dc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800032c6:	64a4                	ld	s1,72(s1)
    800032c8:	fee49de3          	bne	s1,a4,800032c2 <bread+0x86>
  panic("bget: no buffers");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	26c50513          	addi	a0,a0,620 # 80008538 <syscalls+0xe0>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>
      b->dev = dev;
    800032dc:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032e0:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032e4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032e8:	4785                	li	a5,1
    800032ea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032ec:	00014517          	auipc	a0,0x14
    800032f0:	4ec50513          	addi	a0,a0,1260 # 800177d8 <bcache>
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800032fc:	01048513          	addi	a0,s1,16
    80003300:	00001097          	auipc	ra,0x1
    80003304:	414080e7          	jalr	1044(ra) # 80004714 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003308:	409c                	lw	a5,0(s1)
    8000330a:	cb89                	beqz	a5,8000331c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000330c:	8526                	mv	a0,s1
    8000330e:	70a2                	ld	ra,40(sp)
    80003310:	7402                	ld	s0,32(sp)
    80003312:	64e2                	ld	s1,24(sp)
    80003314:	6942                	ld	s2,16(sp)
    80003316:	69a2                	ld	s3,8(sp)
    80003318:	6145                	addi	sp,sp,48
    8000331a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000331c:	4581                	li	a1,0
    8000331e:	8526                	mv	a0,s1
    80003320:	00003097          	auipc	ra,0x3
    80003324:	ff2080e7          	jalr	-14(ra) # 80006312 <virtio_disk_rw>
    b->valid = 1;
    80003328:	4785                	li	a5,1
    8000332a:	c09c                	sw	a5,0(s1)
  return b;
    8000332c:	b7c5                	j	8000330c <bread+0xd0>

000000008000332e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000333a:	0541                	addi	a0,a0,16
    8000333c:	00001097          	auipc	ra,0x1
    80003340:	472080e7          	jalr	1138(ra) # 800047ae <holdingsleep>
    80003344:	cd01                	beqz	a0,8000335c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003346:	4585                	li	a1,1
    80003348:	8526                	mv	a0,s1
    8000334a:	00003097          	auipc	ra,0x3
    8000334e:	fc8080e7          	jalr	-56(ra) # 80006312 <virtio_disk_rw>
}
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret
    panic("bwrite");
    8000335c:	00005517          	auipc	a0,0x5
    80003360:	1f450513          	addi	a0,a0,500 # 80008550 <syscalls+0xf8>
    80003364:	ffffd097          	auipc	ra,0xffffd
    80003368:	1dc080e7          	jalr	476(ra) # 80000540 <panic>

000000008000336c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000336c:	1101                	addi	sp,sp,-32
    8000336e:	ec06                	sd	ra,24(sp)
    80003370:	e822                	sd	s0,16(sp)
    80003372:	e426                	sd	s1,8(sp)
    80003374:	e04a                	sd	s2,0(sp)
    80003376:	1000                	addi	s0,sp,32
    80003378:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000337a:	01050913          	addi	s2,a0,16
    8000337e:	854a                	mv	a0,s2
    80003380:	00001097          	auipc	ra,0x1
    80003384:	42e080e7          	jalr	1070(ra) # 800047ae <holdingsleep>
    80003388:	c92d                	beqz	a0,800033fa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000338a:	854a                	mv	a0,s2
    8000338c:	00001097          	auipc	ra,0x1
    80003390:	3de080e7          	jalr	990(ra) # 8000476a <releasesleep>

  acquire(&bcache.lock);
    80003394:	00014517          	auipc	a0,0x14
    80003398:	44450513          	addi	a0,a0,1092 # 800177d8 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800033a4:	40bc                	lw	a5,64(s1)
    800033a6:	37fd                	addiw	a5,a5,-1
    800033a8:	0007871b          	sext.w	a4,a5
    800033ac:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800033ae:	eb05                	bnez	a4,800033de <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800033b0:	68bc                	ld	a5,80(s1)
    800033b2:	64b8                	ld	a4,72(s1)
    800033b4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800033b6:	64bc                	ld	a5,72(s1)
    800033b8:	68b8                	ld	a4,80(s1)
    800033ba:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800033bc:	0001c797          	auipc	a5,0x1c
    800033c0:	41c78793          	addi	a5,a5,1052 # 8001f7d8 <bcache+0x8000>
    800033c4:	2b87b703          	ld	a4,696(a5)
    800033c8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800033ca:	0001c717          	auipc	a4,0x1c
    800033ce:	67670713          	addi	a4,a4,1654 # 8001fa40 <bcache+0x8268>
    800033d2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033d4:	2b87b703          	ld	a4,696(a5)
    800033d8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033da:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033de:	00014517          	auipc	a0,0x14
    800033e2:	3fa50513          	addi	a0,a0,1018 # 800177d8 <bcache>
    800033e6:	ffffe097          	auipc	ra,0xffffe
    800033ea:	8a4080e7          	jalr	-1884(ra) # 80000c8a <release>
}
    800033ee:	60e2                	ld	ra,24(sp)
    800033f0:	6442                	ld	s0,16(sp)
    800033f2:	64a2                	ld	s1,8(sp)
    800033f4:	6902                	ld	s2,0(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret
    panic("brelse");
    800033fa:	00005517          	auipc	a0,0x5
    800033fe:	15e50513          	addi	a0,a0,350 # 80008558 <syscalls+0x100>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	13e080e7          	jalr	318(ra) # 80000540 <panic>

000000008000340a <bpin>:

void
bpin(struct buf *b) {
    8000340a:	1101                	addi	sp,sp,-32
    8000340c:	ec06                	sd	ra,24(sp)
    8000340e:	e822                	sd	s0,16(sp)
    80003410:	e426                	sd	s1,8(sp)
    80003412:	1000                	addi	s0,sp,32
    80003414:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	3c250513          	addi	a0,a0,962 # 800177d8 <bcache>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	7b8080e7          	jalr	1976(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003426:	40bc                	lw	a5,64(s1)
    80003428:	2785                	addiw	a5,a5,1
    8000342a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000342c:	00014517          	auipc	a0,0x14
    80003430:	3ac50513          	addi	a0,a0,940 # 800177d8 <bcache>
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	856080e7          	jalr	-1962(ra) # 80000c8a <release>
}
    8000343c:	60e2                	ld	ra,24(sp)
    8000343e:	6442                	ld	s0,16(sp)
    80003440:	64a2                	ld	s1,8(sp)
    80003442:	6105                	addi	sp,sp,32
    80003444:	8082                	ret

0000000080003446 <bunpin>:

void
bunpin(struct buf *b) {
    80003446:	1101                	addi	sp,sp,-32
    80003448:	ec06                	sd	ra,24(sp)
    8000344a:	e822                	sd	s0,16(sp)
    8000344c:	e426                	sd	s1,8(sp)
    8000344e:	1000                	addi	s0,sp,32
    80003450:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003452:	00014517          	auipc	a0,0x14
    80003456:	38650513          	addi	a0,a0,902 # 800177d8 <bcache>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	77c080e7          	jalr	1916(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003462:	40bc                	lw	a5,64(s1)
    80003464:	37fd                	addiw	a5,a5,-1
    80003466:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003468:	00014517          	auipc	a0,0x14
    8000346c:	37050513          	addi	a0,a0,880 # 800177d8 <bcache>
    80003470:	ffffe097          	auipc	ra,0xffffe
    80003474:	81a080e7          	jalr	-2022(ra) # 80000c8a <release>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003482:	1101                	addi	sp,sp,-32
    80003484:	ec06                	sd	ra,24(sp)
    80003486:	e822                	sd	s0,16(sp)
    80003488:	e426                	sd	s1,8(sp)
    8000348a:	e04a                	sd	s2,0(sp)
    8000348c:	1000                	addi	s0,sp,32
    8000348e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003490:	00d5d59b          	srliw	a1,a1,0xd
    80003494:	0001d797          	auipc	a5,0x1d
    80003498:	a207a783          	lw	a5,-1504(a5) # 8001feb4 <sb+0x1c>
    8000349c:	9dbd                	addw	a1,a1,a5
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	d9e080e7          	jalr	-610(ra) # 8000323c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800034a6:	0074f713          	andi	a4,s1,7
    800034aa:	4785                	li	a5,1
    800034ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800034b0:	14ce                	slli	s1,s1,0x33
    800034b2:	90d9                	srli	s1,s1,0x36
    800034b4:	00950733          	add	a4,a0,s1
    800034b8:	05874703          	lbu	a4,88(a4)
    800034bc:	00e7f6b3          	and	a3,a5,a4
    800034c0:	c69d                	beqz	a3,800034ee <bfree+0x6c>
    800034c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800034c4:	94aa                	add	s1,s1,a0
    800034c6:	fff7c793          	not	a5,a5
    800034ca:	8f7d                	and	a4,a4,a5
    800034cc:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800034d0:	00001097          	auipc	ra,0x1
    800034d4:	126080e7          	jalr	294(ra) # 800045f6 <log_write>
  brelse(bp);
    800034d8:	854a                	mv	a0,s2
    800034da:	00000097          	auipc	ra,0x0
    800034de:	e92080e7          	jalr	-366(ra) # 8000336c <brelse>
}
    800034e2:	60e2                	ld	ra,24(sp)
    800034e4:	6442                	ld	s0,16(sp)
    800034e6:	64a2                	ld	s1,8(sp)
    800034e8:	6902                	ld	s2,0(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret
    panic("freeing free block");
    800034ee:	00005517          	auipc	a0,0x5
    800034f2:	07250513          	addi	a0,a0,114 # 80008560 <syscalls+0x108>
    800034f6:	ffffd097          	auipc	ra,0xffffd
    800034fa:	04a080e7          	jalr	74(ra) # 80000540 <panic>

00000000800034fe <balloc>:
{
    800034fe:	711d                	addi	sp,sp,-96
    80003500:	ec86                	sd	ra,88(sp)
    80003502:	e8a2                	sd	s0,80(sp)
    80003504:	e4a6                	sd	s1,72(sp)
    80003506:	e0ca                	sd	s2,64(sp)
    80003508:	fc4e                	sd	s3,56(sp)
    8000350a:	f852                	sd	s4,48(sp)
    8000350c:	f456                	sd	s5,40(sp)
    8000350e:	f05a                	sd	s6,32(sp)
    80003510:	ec5e                	sd	s7,24(sp)
    80003512:	e862                	sd	s8,16(sp)
    80003514:	e466                	sd	s9,8(sp)
    80003516:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003518:	0001d797          	auipc	a5,0x1d
    8000351c:	9847a783          	lw	a5,-1660(a5) # 8001fe9c <sb+0x4>
    80003520:	cff5                	beqz	a5,8000361c <balloc+0x11e>
    80003522:	8baa                	mv	s7,a0
    80003524:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003526:	0001db17          	auipc	s6,0x1d
    8000352a:	972b0b13          	addi	s6,s6,-1678 # 8001fe98 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003530:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003532:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003534:	6c89                	lui	s9,0x2
    80003536:	a061                	j	800035be <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003538:	97ca                	add	a5,a5,s2
    8000353a:	8e55                	or	a2,a2,a3
    8000353c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	0b4080e7          	jalr	180(ra) # 800045f6 <log_write>
        brelse(bp);
    8000354a:	854a                	mv	a0,s2
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	e20080e7          	jalr	-480(ra) # 8000336c <brelse>
  bp = bread(dev, bno);
    80003554:	85a6                	mv	a1,s1
    80003556:	855e                	mv	a0,s7
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	ce4080e7          	jalr	-796(ra) # 8000323c <bread>
    80003560:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003562:	40000613          	li	a2,1024
    80003566:	4581                	li	a1,0
    80003568:	05850513          	addi	a0,a0,88
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	766080e7          	jalr	1894(ra) # 80000cd2 <memset>
  log_write(bp);
    80003574:	854a                	mv	a0,s2
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	080080e7          	jalr	128(ra) # 800045f6 <log_write>
  brelse(bp);
    8000357e:	854a                	mv	a0,s2
    80003580:	00000097          	auipc	ra,0x0
    80003584:	dec080e7          	jalr	-532(ra) # 8000336c <brelse>
}
    80003588:	8526                	mv	a0,s1
    8000358a:	60e6                	ld	ra,88(sp)
    8000358c:	6446                	ld	s0,80(sp)
    8000358e:	64a6                	ld	s1,72(sp)
    80003590:	6906                	ld	s2,64(sp)
    80003592:	79e2                	ld	s3,56(sp)
    80003594:	7a42                	ld	s4,48(sp)
    80003596:	7aa2                	ld	s5,40(sp)
    80003598:	7b02                	ld	s6,32(sp)
    8000359a:	6be2                	ld	s7,24(sp)
    8000359c:	6c42                	ld	s8,16(sp)
    8000359e:	6ca2                	ld	s9,8(sp)
    800035a0:	6125                	addi	sp,sp,96
    800035a2:	8082                	ret
    brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	dc6080e7          	jalr	-570(ra) # 8000336c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035ae:	015c87bb          	addw	a5,s9,s5
    800035b2:	00078a9b          	sext.w	s5,a5
    800035b6:	004b2703          	lw	a4,4(s6)
    800035ba:	06eaf163          	bgeu	s5,a4,8000361c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800035be:	41fad79b          	sraiw	a5,s5,0x1f
    800035c2:	0137d79b          	srliw	a5,a5,0x13
    800035c6:	015787bb          	addw	a5,a5,s5
    800035ca:	40d7d79b          	sraiw	a5,a5,0xd
    800035ce:	01cb2583          	lw	a1,28(s6)
    800035d2:	9dbd                	addw	a1,a1,a5
    800035d4:	855e                	mv	a0,s7
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	c66080e7          	jalr	-922(ra) # 8000323c <bread>
    800035de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e0:	004b2503          	lw	a0,4(s6)
    800035e4:	000a849b          	sext.w	s1,s5
    800035e8:	8762                	mv	a4,s8
    800035ea:	faa4fde3          	bgeu	s1,a0,800035a4 <balloc+0xa6>
      m = 1 << (bi % 8);
    800035ee:	00777693          	andi	a3,a4,7
    800035f2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035f6:	41f7579b          	sraiw	a5,a4,0x1f
    800035fa:	01d7d79b          	srliw	a5,a5,0x1d
    800035fe:	9fb9                	addw	a5,a5,a4
    80003600:	4037d79b          	sraiw	a5,a5,0x3
    80003604:	00f90633          	add	a2,s2,a5
    80003608:	05864603          	lbu	a2,88(a2)
    8000360c:	00c6f5b3          	and	a1,a3,a2
    80003610:	d585                	beqz	a1,80003538 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003612:	2705                	addiw	a4,a4,1
    80003614:	2485                	addiw	s1,s1,1
    80003616:	fd471ae3          	bne	a4,s4,800035ea <balloc+0xec>
    8000361a:	b769                	j	800035a4 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000361c:	00005517          	auipc	a0,0x5
    80003620:	f5c50513          	addi	a0,a0,-164 # 80008578 <syscalls+0x120>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	f66080e7          	jalr	-154(ra) # 8000058a <printf>
  return 0;
    8000362c:	4481                	li	s1,0
    8000362e:	bfa9                	j	80003588 <balloc+0x8a>

0000000080003630 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	e052                	sd	s4,0(sp)
    8000363e:	1800                	addi	s0,sp,48
    80003640:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003642:	47ad                	li	a5,11
    80003644:	02b7e863          	bltu	a5,a1,80003674 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003648:	02059793          	slli	a5,a1,0x20
    8000364c:	01e7d593          	srli	a1,a5,0x1e
    80003650:	00b504b3          	add	s1,a0,a1
    80003654:	0504a903          	lw	s2,80(s1)
    80003658:	06091e63          	bnez	s2,800036d4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000365c:	4108                	lw	a0,0(a0)
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	ea0080e7          	jalr	-352(ra) # 800034fe <balloc>
    80003666:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000366a:	06090563          	beqz	s2,800036d4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000366e:	0524a823          	sw	s2,80(s1)
    80003672:	a08d                	j	800036d4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003674:	ff45849b          	addiw	s1,a1,-12
    80003678:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000367c:	0ff00793          	li	a5,255
    80003680:	08e7e563          	bltu	a5,a4,8000370a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003684:	08052903          	lw	s2,128(a0)
    80003688:	00091d63          	bnez	s2,800036a2 <bmap+0x72>
      addr = balloc(ip->dev);
    8000368c:	4108                	lw	a0,0(a0)
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	e70080e7          	jalr	-400(ra) # 800034fe <balloc>
    80003696:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000369a:	02090d63          	beqz	s2,800036d4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000369e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800036a2:	85ca                	mv	a1,s2
    800036a4:	0009a503          	lw	a0,0(s3)
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	b94080e7          	jalr	-1132(ra) # 8000323c <bread>
    800036b0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036b2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036b6:	02049713          	slli	a4,s1,0x20
    800036ba:	01e75593          	srli	a1,a4,0x1e
    800036be:	00b784b3          	add	s1,a5,a1
    800036c2:	0004a903          	lw	s2,0(s1)
    800036c6:	02090063          	beqz	s2,800036e6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800036ca:	8552                	mv	a0,s4
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	ca0080e7          	jalr	-864(ra) # 8000336c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036d4:	854a                	mv	a0,s2
    800036d6:	70a2                	ld	ra,40(sp)
    800036d8:	7402                	ld	s0,32(sp)
    800036da:	64e2                	ld	s1,24(sp)
    800036dc:	6942                	ld	s2,16(sp)
    800036de:	69a2                	ld	s3,8(sp)
    800036e0:	6a02                	ld	s4,0(sp)
    800036e2:	6145                	addi	sp,sp,48
    800036e4:	8082                	ret
      addr = balloc(ip->dev);
    800036e6:	0009a503          	lw	a0,0(s3)
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	e14080e7          	jalr	-492(ra) # 800034fe <balloc>
    800036f2:	0005091b          	sext.w	s2,a0
      if(addr){
    800036f6:	fc090ae3          	beqz	s2,800036ca <bmap+0x9a>
        a[bn] = addr;
    800036fa:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800036fe:	8552                	mv	a0,s4
    80003700:	00001097          	auipc	ra,0x1
    80003704:	ef6080e7          	jalr	-266(ra) # 800045f6 <log_write>
    80003708:	b7c9                	j	800036ca <bmap+0x9a>
  panic("bmap: out of range");
    8000370a:	00005517          	auipc	a0,0x5
    8000370e:	e8650513          	addi	a0,a0,-378 # 80008590 <syscalls+0x138>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	e2e080e7          	jalr	-466(ra) # 80000540 <panic>

000000008000371a <iget>:
{
    8000371a:	7179                	addi	sp,sp,-48
    8000371c:	f406                	sd	ra,40(sp)
    8000371e:	f022                	sd	s0,32(sp)
    80003720:	ec26                	sd	s1,24(sp)
    80003722:	e84a                	sd	s2,16(sp)
    80003724:	e44e                	sd	s3,8(sp)
    80003726:	e052                	sd	s4,0(sp)
    80003728:	1800                	addi	s0,sp,48
    8000372a:	89aa                	mv	s3,a0
    8000372c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000372e:	0001c517          	auipc	a0,0x1c
    80003732:	78a50513          	addi	a0,a0,1930 # 8001feb8 <itable>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	4a0080e7          	jalr	1184(ra) # 80000bd6 <acquire>
  empty = 0;
    8000373e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003740:	0001c497          	auipc	s1,0x1c
    80003744:	79048493          	addi	s1,s1,1936 # 8001fed0 <itable+0x18>
    80003748:	0001e697          	auipc	a3,0x1e
    8000374c:	21868693          	addi	a3,a3,536 # 80021960 <log>
    80003750:	a039                	j	8000375e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003752:	02090b63          	beqz	s2,80003788 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003756:	08848493          	addi	s1,s1,136
    8000375a:	02d48a63          	beq	s1,a3,8000378e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000375e:	449c                	lw	a5,8(s1)
    80003760:	fef059e3          	blez	a5,80003752 <iget+0x38>
    80003764:	4098                	lw	a4,0(s1)
    80003766:	ff3716e3          	bne	a4,s3,80003752 <iget+0x38>
    8000376a:	40d8                	lw	a4,4(s1)
    8000376c:	ff4713e3          	bne	a4,s4,80003752 <iget+0x38>
      ip->ref++;
    80003770:	2785                	addiw	a5,a5,1
    80003772:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003774:	0001c517          	auipc	a0,0x1c
    80003778:	74450513          	addi	a0,a0,1860 # 8001feb8 <itable>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	50e080e7          	jalr	1294(ra) # 80000c8a <release>
      return ip;
    80003784:	8926                	mv	s2,s1
    80003786:	a03d                	j	800037b4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003788:	f7f9                	bnez	a5,80003756 <iget+0x3c>
    8000378a:	8926                	mv	s2,s1
    8000378c:	b7e9                	j	80003756 <iget+0x3c>
  if(empty == 0)
    8000378e:	02090c63          	beqz	s2,800037c6 <iget+0xac>
  ip->dev = dev;
    80003792:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003796:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000379a:	4785                	li	a5,1
    8000379c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037a0:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800037a4:	0001c517          	auipc	a0,0x1c
    800037a8:	71450513          	addi	a0,a0,1812 # 8001feb8 <itable>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	4de080e7          	jalr	1246(ra) # 80000c8a <release>
}
    800037b4:	854a                	mv	a0,s2
    800037b6:	70a2                	ld	ra,40(sp)
    800037b8:	7402                	ld	s0,32(sp)
    800037ba:	64e2                	ld	s1,24(sp)
    800037bc:	6942                	ld	s2,16(sp)
    800037be:	69a2                	ld	s3,8(sp)
    800037c0:	6a02                	ld	s4,0(sp)
    800037c2:	6145                	addi	sp,sp,48
    800037c4:	8082                	ret
    panic("iget: no inodes");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	de250513          	addi	a0,a0,-542 # 800085a8 <syscalls+0x150>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d72080e7          	jalr	-654(ra) # 80000540 <panic>

00000000800037d6 <fsinit>:
fsinit(int dev) {
    800037d6:	7179                	addi	sp,sp,-48
    800037d8:	f406                	sd	ra,40(sp)
    800037da:	f022                	sd	s0,32(sp)
    800037dc:	ec26                	sd	s1,24(sp)
    800037de:	e84a                	sd	s2,16(sp)
    800037e0:	e44e                	sd	s3,8(sp)
    800037e2:	1800                	addi	s0,sp,48
    800037e4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037e6:	4585                	li	a1,1
    800037e8:	00000097          	auipc	ra,0x0
    800037ec:	a54080e7          	jalr	-1452(ra) # 8000323c <bread>
    800037f0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037f2:	0001c997          	auipc	s3,0x1c
    800037f6:	6a698993          	addi	s3,s3,1702 # 8001fe98 <sb>
    800037fa:	02000613          	li	a2,32
    800037fe:	05850593          	addi	a1,a0,88
    80003802:	854e                	mv	a0,s3
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	52a080e7          	jalr	1322(ra) # 80000d2e <memmove>
  brelse(bp);
    8000380c:	8526                	mv	a0,s1
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	b5e080e7          	jalr	-1186(ra) # 8000336c <brelse>
  if(sb.magic != FSMAGIC)
    80003816:	0009a703          	lw	a4,0(s3)
    8000381a:	102037b7          	lui	a5,0x10203
    8000381e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003822:	02f71263          	bne	a4,a5,80003846 <fsinit+0x70>
  initlog(dev, &sb);
    80003826:	0001c597          	auipc	a1,0x1c
    8000382a:	67258593          	addi	a1,a1,1650 # 8001fe98 <sb>
    8000382e:	854a                	mv	a0,s2
    80003830:	00001097          	auipc	ra,0x1
    80003834:	b4a080e7          	jalr	-1206(ra) # 8000437a <initlog>
}
    80003838:	70a2                	ld	ra,40(sp)
    8000383a:	7402                	ld	s0,32(sp)
    8000383c:	64e2                	ld	s1,24(sp)
    8000383e:	6942                	ld	s2,16(sp)
    80003840:	69a2                	ld	s3,8(sp)
    80003842:	6145                	addi	sp,sp,48
    80003844:	8082                	ret
    panic("invalid file system");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	d7250513          	addi	a0,a0,-654 # 800085b8 <syscalls+0x160>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cf2080e7          	jalr	-782(ra) # 80000540 <panic>

0000000080003856 <iinit>:
{
    80003856:	7179                	addi	sp,sp,-48
    80003858:	f406                	sd	ra,40(sp)
    8000385a:	f022                	sd	s0,32(sp)
    8000385c:	ec26                	sd	s1,24(sp)
    8000385e:	e84a                	sd	s2,16(sp)
    80003860:	e44e                	sd	s3,8(sp)
    80003862:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003864:	00005597          	auipc	a1,0x5
    80003868:	d6c58593          	addi	a1,a1,-660 # 800085d0 <syscalls+0x178>
    8000386c:	0001c517          	auipc	a0,0x1c
    80003870:	64c50513          	addi	a0,a0,1612 # 8001feb8 <itable>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	2d2080e7          	jalr	722(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000387c:	0001c497          	auipc	s1,0x1c
    80003880:	66448493          	addi	s1,s1,1636 # 8001fee0 <itable+0x28>
    80003884:	0001e997          	auipc	s3,0x1e
    80003888:	0ec98993          	addi	s3,s3,236 # 80021970 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000388c:	00005917          	auipc	s2,0x5
    80003890:	d4c90913          	addi	s2,s2,-692 # 800085d8 <syscalls+0x180>
    80003894:	85ca                	mv	a1,s2
    80003896:	8526                	mv	a0,s1
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	e42080e7          	jalr	-446(ra) # 800046da <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038a0:	08848493          	addi	s1,s1,136
    800038a4:	ff3498e3          	bne	s1,s3,80003894 <iinit+0x3e>
}
    800038a8:	70a2                	ld	ra,40(sp)
    800038aa:	7402                	ld	s0,32(sp)
    800038ac:	64e2                	ld	s1,24(sp)
    800038ae:	6942                	ld	s2,16(sp)
    800038b0:	69a2                	ld	s3,8(sp)
    800038b2:	6145                	addi	sp,sp,48
    800038b4:	8082                	ret

00000000800038b6 <ialloc>:
{
    800038b6:	715d                	addi	sp,sp,-80
    800038b8:	e486                	sd	ra,72(sp)
    800038ba:	e0a2                	sd	s0,64(sp)
    800038bc:	fc26                	sd	s1,56(sp)
    800038be:	f84a                	sd	s2,48(sp)
    800038c0:	f44e                	sd	s3,40(sp)
    800038c2:	f052                	sd	s4,32(sp)
    800038c4:	ec56                	sd	s5,24(sp)
    800038c6:	e85a                	sd	s6,16(sp)
    800038c8:	e45e                	sd	s7,8(sp)
    800038ca:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800038cc:	0001c717          	auipc	a4,0x1c
    800038d0:	5d872703          	lw	a4,1496(a4) # 8001fea4 <sb+0xc>
    800038d4:	4785                	li	a5,1
    800038d6:	04e7fa63          	bgeu	a5,a4,8000392a <ialloc+0x74>
    800038da:	8aaa                	mv	s5,a0
    800038dc:	8bae                	mv	s7,a1
    800038de:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800038e0:	0001ca17          	auipc	s4,0x1c
    800038e4:	5b8a0a13          	addi	s4,s4,1464 # 8001fe98 <sb>
    800038e8:	00048b1b          	sext.w	s6,s1
    800038ec:	0044d593          	srli	a1,s1,0x4
    800038f0:	018a2783          	lw	a5,24(s4)
    800038f4:	9dbd                	addw	a1,a1,a5
    800038f6:	8556                	mv	a0,s5
    800038f8:	00000097          	auipc	ra,0x0
    800038fc:	944080e7          	jalr	-1724(ra) # 8000323c <bread>
    80003900:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003902:	05850993          	addi	s3,a0,88
    80003906:	00f4f793          	andi	a5,s1,15
    8000390a:	079a                	slli	a5,a5,0x6
    8000390c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000390e:	00099783          	lh	a5,0(s3)
    80003912:	c3a1                	beqz	a5,80003952 <ialloc+0x9c>
    brelse(bp);
    80003914:	00000097          	auipc	ra,0x0
    80003918:	a58080e7          	jalr	-1448(ra) # 8000336c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000391c:	0485                	addi	s1,s1,1
    8000391e:	00ca2703          	lw	a4,12(s4)
    80003922:	0004879b          	sext.w	a5,s1
    80003926:	fce7e1e3          	bltu	a5,a4,800038e8 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000392a:	00005517          	auipc	a0,0x5
    8000392e:	cb650513          	addi	a0,a0,-842 # 800085e0 <syscalls+0x188>
    80003932:	ffffd097          	auipc	ra,0xffffd
    80003936:	c58080e7          	jalr	-936(ra) # 8000058a <printf>
  return 0;
    8000393a:	4501                	li	a0,0
}
    8000393c:	60a6                	ld	ra,72(sp)
    8000393e:	6406                	ld	s0,64(sp)
    80003940:	74e2                	ld	s1,56(sp)
    80003942:	7942                	ld	s2,48(sp)
    80003944:	79a2                	ld	s3,40(sp)
    80003946:	7a02                	ld	s4,32(sp)
    80003948:	6ae2                	ld	s5,24(sp)
    8000394a:	6b42                	ld	s6,16(sp)
    8000394c:	6ba2                	ld	s7,8(sp)
    8000394e:	6161                	addi	sp,sp,80
    80003950:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003952:	04000613          	li	a2,64
    80003956:	4581                	li	a1,0
    80003958:	854e                	mv	a0,s3
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	378080e7          	jalr	888(ra) # 80000cd2 <memset>
      dip->type = type;
    80003962:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003966:	854a                	mv	a0,s2
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	c8e080e7          	jalr	-882(ra) # 800045f6 <log_write>
      brelse(bp);
    80003970:	854a                	mv	a0,s2
    80003972:	00000097          	auipc	ra,0x0
    80003976:	9fa080e7          	jalr	-1542(ra) # 8000336c <brelse>
      return iget(dev, inum);
    8000397a:	85da                	mv	a1,s6
    8000397c:	8556                	mv	a0,s5
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	d9c080e7          	jalr	-612(ra) # 8000371a <iget>
    80003986:	bf5d                	j	8000393c <ialloc+0x86>

0000000080003988 <iupdate>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003996:	415c                	lw	a5,4(a0)
    80003998:	0047d79b          	srliw	a5,a5,0x4
    8000399c:	0001c597          	auipc	a1,0x1c
    800039a0:	5145a583          	lw	a1,1300(a1) # 8001feb0 <sb+0x18>
    800039a4:	9dbd                	addw	a1,a1,a5
    800039a6:	4108                	lw	a0,0(a0)
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	894080e7          	jalr	-1900(ra) # 8000323c <bread>
    800039b0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b2:	05850793          	addi	a5,a0,88
    800039b6:	40d8                	lw	a4,4(s1)
    800039b8:	8b3d                	andi	a4,a4,15
    800039ba:	071a                	slli	a4,a4,0x6
    800039bc:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800039be:	04449703          	lh	a4,68(s1)
    800039c2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800039c6:	04649703          	lh	a4,70(s1)
    800039ca:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800039ce:	04849703          	lh	a4,72(s1)
    800039d2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800039d6:	04a49703          	lh	a4,74(s1)
    800039da:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800039de:	44f8                	lw	a4,76(s1)
    800039e0:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800039e2:	03400613          	li	a2,52
    800039e6:	05048593          	addi	a1,s1,80
    800039ea:	00c78513          	addi	a0,a5,12
    800039ee:	ffffd097          	auipc	ra,0xffffd
    800039f2:	340080e7          	jalr	832(ra) # 80000d2e <memmove>
  log_write(bp);
    800039f6:	854a                	mv	a0,s2
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	bfe080e7          	jalr	-1026(ra) # 800045f6 <log_write>
  brelse(bp);
    80003a00:	854a                	mv	a0,s2
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	96a080e7          	jalr	-1686(ra) # 8000336c <brelse>
}
    80003a0a:	60e2                	ld	ra,24(sp)
    80003a0c:	6442                	ld	s0,16(sp)
    80003a0e:	64a2                	ld	s1,8(sp)
    80003a10:	6902                	ld	s2,0(sp)
    80003a12:	6105                	addi	sp,sp,32
    80003a14:	8082                	ret

0000000080003a16 <idup>:
{
    80003a16:	1101                	addi	sp,sp,-32
    80003a18:	ec06                	sd	ra,24(sp)
    80003a1a:	e822                	sd	s0,16(sp)
    80003a1c:	e426                	sd	s1,8(sp)
    80003a1e:	1000                	addi	s0,sp,32
    80003a20:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a22:	0001c517          	auipc	a0,0x1c
    80003a26:	49650513          	addi	a0,a0,1174 # 8001feb8 <itable>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	1ac080e7          	jalr	428(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a32:	449c                	lw	a5,8(s1)
    80003a34:	2785                	addiw	a5,a5,1
    80003a36:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a38:	0001c517          	auipc	a0,0x1c
    80003a3c:	48050513          	addi	a0,a0,1152 # 8001feb8 <itable>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	24a080e7          	jalr	586(ra) # 80000c8a <release>
}
    80003a48:	8526                	mv	a0,s1
    80003a4a:	60e2                	ld	ra,24(sp)
    80003a4c:	6442                	ld	s0,16(sp)
    80003a4e:	64a2                	ld	s1,8(sp)
    80003a50:	6105                	addi	sp,sp,32
    80003a52:	8082                	ret

0000000080003a54 <ilock>:
{
    80003a54:	1101                	addi	sp,sp,-32
    80003a56:	ec06                	sd	ra,24(sp)
    80003a58:	e822                	sd	s0,16(sp)
    80003a5a:	e426                	sd	s1,8(sp)
    80003a5c:	e04a                	sd	s2,0(sp)
    80003a5e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a60:	c115                	beqz	a0,80003a84 <ilock+0x30>
    80003a62:	84aa                	mv	s1,a0
    80003a64:	451c                	lw	a5,8(a0)
    80003a66:	00f05f63          	blez	a5,80003a84 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a6a:	0541                	addi	a0,a0,16
    80003a6c:	00001097          	auipc	ra,0x1
    80003a70:	ca8080e7          	jalr	-856(ra) # 80004714 <acquiresleep>
  if(ip->valid == 0){
    80003a74:	40bc                	lw	a5,64(s1)
    80003a76:	cf99                	beqz	a5,80003a94 <ilock+0x40>
}
    80003a78:	60e2                	ld	ra,24(sp)
    80003a7a:	6442                	ld	s0,16(sp)
    80003a7c:	64a2                	ld	s1,8(sp)
    80003a7e:	6902                	ld	s2,0(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret
    panic("ilock");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	b7450513          	addi	a0,a0,-1164 # 800085f8 <syscalls+0x1a0>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ab4080e7          	jalr	-1356(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a94:	40dc                	lw	a5,4(s1)
    80003a96:	0047d79b          	srliw	a5,a5,0x4
    80003a9a:	0001c597          	auipc	a1,0x1c
    80003a9e:	4165a583          	lw	a1,1046(a1) # 8001feb0 <sb+0x18>
    80003aa2:	9dbd                	addw	a1,a1,a5
    80003aa4:	4088                	lw	a0,0(s1)
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	796080e7          	jalr	1942(ra) # 8000323c <bread>
    80003aae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ab0:	05850593          	addi	a1,a0,88
    80003ab4:	40dc                	lw	a5,4(s1)
    80003ab6:	8bbd                	andi	a5,a5,15
    80003ab8:	079a                	slli	a5,a5,0x6
    80003aba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003abc:	00059783          	lh	a5,0(a1)
    80003ac0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003ac4:	00259783          	lh	a5,2(a1)
    80003ac8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003acc:	00459783          	lh	a5,4(a1)
    80003ad0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003ad4:	00659783          	lh	a5,6(a1)
    80003ad8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003adc:	459c                	lw	a5,8(a1)
    80003ade:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ae0:	03400613          	li	a2,52
    80003ae4:	05b1                	addi	a1,a1,12
    80003ae6:	05048513          	addi	a0,s1,80
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	244080e7          	jalr	580(ra) # 80000d2e <memmove>
    brelse(bp);
    80003af2:	854a                	mv	a0,s2
    80003af4:	00000097          	auipc	ra,0x0
    80003af8:	878080e7          	jalr	-1928(ra) # 8000336c <brelse>
    ip->valid = 1;
    80003afc:	4785                	li	a5,1
    80003afe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b00:	04449783          	lh	a5,68(s1)
    80003b04:	fbb5                	bnez	a5,80003a78 <ilock+0x24>
      panic("ilock: no type");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	afa50513          	addi	a0,a0,-1286 # 80008600 <syscalls+0x1a8>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a32080e7          	jalr	-1486(ra) # 80000540 <panic>

0000000080003b16 <iunlock>:
{
    80003b16:	1101                	addi	sp,sp,-32
    80003b18:	ec06                	sd	ra,24(sp)
    80003b1a:	e822                	sd	s0,16(sp)
    80003b1c:	e426                	sd	s1,8(sp)
    80003b1e:	e04a                	sd	s2,0(sp)
    80003b20:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b22:	c905                	beqz	a0,80003b52 <iunlock+0x3c>
    80003b24:	84aa                	mv	s1,a0
    80003b26:	01050913          	addi	s2,a0,16
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	c82080e7          	jalr	-894(ra) # 800047ae <holdingsleep>
    80003b34:	cd19                	beqz	a0,80003b52 <iunlock+0x3c>
    80003b36:	449c                	lw	a5,8(s1)
    80003b38:	00f05d63          	blez	a5,80003b52 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	00001097          	auipc	ra,0x1
    80003b42:	c2c080e7          	jalr	-980(ra) # 8000476a <releasesleep>
}
    80003b46:	60e2                	ld	ra,24(sp)
    80003b48:	6442                	ld	s0,16(sp)
    80003b4a:	64a2                	ld	s1,8(sp)
    80003b4c:	6902                	ld	s2,0(sp)
    80003b4e:	6105                	addi	sp,sp,32
    80003b50:	8082                	ret
    panic("iunlock");
    80003b52:	00005517          	auipc	a0,0x5
    80003b56:	abe50513          	addi	a0,a0,-1346 # 80008610 <syscalls+0x1b8>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	9e6080e7          	jalr	-1562(ra) # 80000540 <panic>

0000000080003b62 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b62:	7179                	addi	sp,sp,-48
    80003b64:	f406                	sd	ra,40(sp)
    80003b66:	f022                	sd	s0,32(sp)
    80003b68:	ec26                	sd	s1,24(sp)
    80003b6a:	e84a                	sd	s2,16(sp)
    80003b6c:	e44e                	sd	s3,8(sp)
    80003b6e:	e052                	sd	s4,0(sp)
    80003b70:	1800                	addi	s0,sp,48
    80003b72:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b74:	05050493          	addi	s1,a0,80
    80003b78:	08050913          	addi	s2,a0,128
    80003b7c:	a021                	j	80003b84 <itrunc+0x22>
    80003b7e:	0491                	addi	s1,s1,4
    80003b80:	01248d63          	beq	s1,s2,80003b9a <itrunc+0x38>
    if(ip->addrs[i]){
    80003b84:	408c                	lw	a1,0(s1)
    80003b86:	dde5                	beqz	a1,80003b7e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b88:	0009a503          	lw	a0,0(s3)
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	8f6080e7          	jalr	-1802(ra) # 80003482 <bfree>
      ip->addrs[i] = 0;
    80003b94:	0004a023          	sw	zero,0(s1)
    80003b98:	b7dd                	j	80003b7e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b9a:	0809a583          	lw	a1,128(s3)
    80003b9e:	e185                	bnez	a1,80003bbe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ba0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ba4:	854e                	mv	a0,s3
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	de2080e7          	jalr	-542(ra) # 80003988 <iupdate>
}
    80003bae:	70a2                	ld	ra,40(sp)
    80003bb0:	7402                	ld	s0,32(sp)
    80003bb2:	64e2                	ld	s1,24(sp)
    80003bb4:	6942                	ld	s2,16(sp)
    80003bb6:	69a2                	ld	s3,8(sp)
    80003bb8:	6a02                	ld	s4,0(sp)
    80003bba:	6145                	addi	sp,sp,48
    80003bbc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003bbe:	0009a503          	lw	a0,0(s3)
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	67a080e7          	jalr	1658(ra) # 8000323c <bread>
    80003bca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003bcc:	05850493          	addi	s1,a0,88
    80003bd0:	45850913          	addi	s2,a0,1112
    80003bd4:	a021                	j	80003bdc <itrunc+0x7a>
    80003bd6:	0491                	addi	s1,s1,4
    80003bd8:	01248b63          	beq	s1,s2,80003bee <itrunc+0x8c>
      if(a[j])
    80003bdc:	408c                	lw	a1,0(s1)
    80003bde:	dde5                	beqz	a1,80003bd6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003be0:	0009a503          	lw	a0,0(s3)
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	89e080e7          	jalr	-1890(ra) # 80003482 <bfree>
    80003bec:	b7ed                	j	80003bd6 <itrunc+0x74>
    brelse(bp);
    80003bee:	8552                	mv	a0,s4
    80003bf0:	fffff097          	auipc	ra,0xfffff
    80003bf4:	77c080e7          	jalr	1916(ra) # 8000336c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bf8:	0809a583          	lw	a1,128(s3)
    80003bfc:	0009a503          	lw	a0,0(s3)
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	882080e7          	jalr	-1918(ra) # 80003482 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c08:	0809a023          	sw	zero,128(s3)
    80003c0c:	bf51                	j	80003ba0 <itrunc+0x3e>

0000000080003c0e <iput>:
{
    80003c0e:	1101                	addi	sp,sp,-32
    80003c10:	ec06                	sd	ra,24(sp)
    80003c12:	e822                	sd	s0,16(sp)
    80003c14:	e426                	sd	s1,8(sp)
    80003c16:	e04a                	sd	s2,0(sp)
    80003c18:	1000                	addi	s0,sp,32
    80003c1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c1c:	0001c517          	auipc	a0,0x1c
    80003c20:	29c50513          	addi	a0,a0,668 # 8001feb8 <itable>
    80003c24:	ffffd097          	auipc	ra,0xffffd
    80003c28:	fb2080e7          	jalr	-78(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c2c:	4498                	lw	a4,8(s1)
    80003c2e:	4785                	li	a5,1
    80003c30:	02f70363          	beq	a4,a5,80003c56 <iput+0x48>
  ip->ref--;
    80003c34:	449c                	lw	a5,8(s1)
    80003c36:	37fd                	addiw	a5,a5,-1
    80003c38:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c3a:	0001c517          	auipc	a0,0x1c
    80003c3e:	27e50513          	addi	a0,a0,638 # 8001feb8 <itable>
    80003c42:	ffffd097          	auipc	ra,0xffffd
    80003c46:	048080e7          	jalr	72(ra) # 80000c8a <release>
}
    80003c4a:	60e2                	ld	ra,24(sp)
    80003c4c:	6442                	ld	s0,16(sp)
    80003c4e:	64a2                	ld	s1,8(sp)
    80003c50:	6902                	ld	s2,0(sp)
    80003c52:	6105                	addi	sp,sp,32
    80003c54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c56:	40bc                	lw	a5,64(s1)
    80003c58:	dff1                	beqz	a5,80003c34 <iput+0x26>
    80003c5a:	04a49783          	lh	a5,74(s1)
    80003c5e:	fbf9                	bnez	a5,80003c34 <iput+0x26>
    acquiresleep(&ip->lock);
    80003c60:	01048913          	addi	s2,s1,16
    80003c64:	854a                	mv	a0,s2
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	aae080e7          	jalr	-1362(ra) # 80004714 <acquiresleep>
    release(&itable.lock);
    80003c6e:	0001c517          	auipc	a0,0x1c
    80003c72:	24a50513          	addi	a0,a0,586 # 8001feb8 <itable>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>
    itrunc(ip);
    80003c7e:	8526                	mv	a0,s1
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	ee2080e7          	jalr	-286(ra) # 80003b62 <itrunc>
    ip->type = 0;
    80003c88:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c8c:	8526                	mv	a0,s1
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	cfa080e7          	jalr	-774(ra) # 80003988 <iupdate>
    ip->valid = 0;
    80003c96:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00001097          	auipc	ra,0x1
    80003ca0:	ace080e7          	jalr	-1330(ra) # 8000476a <releasesleep>
    acquire(&itable.lock);
    80003ca4:	0001c517          	auipc	a0,0x1c
    80003ca8:	21450513          	addi	a0,a0,532 # 8001feb8 <itable>
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	f2a080e7          	jalr	-214(ra) # 80000bd6 <acquire>
    80003cb4:	b741                	j	80003c34 <iput+0x26>

0000000080003cb6 <iunlockput>:
{
    80003cb6:	1101                	addi	sp,sp,-32
    80003cb8:	ec06                	sd	ra,24(sp)
    80003cba:	e822                	sd	s0,16(sp)
    80003cbc:	e426                	sd	s1,8(sp)
    80003cbe:	1000                	addi	s0,sp,32
    80003cc0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	e54080e7          	jalr	-428(ra) # 80003b16 <iunlock>
  iput(ip);
    80003cca:	8526                	mv	a0,s1
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	f42080e7          	jalr	-190(ra) # 80003c0e <iput>
}
    80003cd4:	60e2                	ld	ra,24(sp)
    80003cd6:	6442                	ld	s0,16(sp)
    80003cd8:	64a2                	ld	s1,8(sp)
    80003cda:	6105                	addi	sp,sp,32
    80003cdc:	8082                	ret

0000000080003cde <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003cde:	1141                	addi	sp,sp,-16
    80003ce0:	e422                	sd	s0,8(sp)
    80003ce2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ce4:	411c                	lw	a5,0(a0)
    80003ce6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ce8:	415c                	lw	a5,4(a0)
    80003cea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003cec:	04451783          	lh	a5,68(a0)
    80003cf0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cf4:	04a51783          	lh	a5,74(a0)
    80003cf8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cfc:	04c56783          	lwu	a5,76(a0)
    80003d00:	e99c                	sd	a5,16(a1)
}
    80003d02:	6422                	ld	s0,8(sp)
    80003d04:	0141                	addi	sp,sp,16
    80003d06:	8082                	ret

0000000080003d08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d08:	457c                	lw	a5,76(a0)
    80003d0a:	0ed7e963          	bltu	a5,a3,80003dfc <readi+0xf4>
{
    80003d0e:	7159                	addi	sp,sp,-112
    80003d10:	f486                	sd	ra,104(sp)
    80003d12:	f0a2                	sd	s0,96(sp)
    80003d14:	eca6                	sd	s1,88(sp)
    80003d16:	e8ca                	sd	s2,80(sp)
    80003d18:	e4ce                	sd	s3,72(sp)
    80003d1a:	e0d2                	sd	s4,64(sp)
    80003d1c:	fc56                	sd	s5,56(sp)
    80003d1e:	f85a                	sd	s6,48(sp)
    80003d20:	f45e                	sd	s7,40(sp)
    80003d22:	f062                	sd	s8,32(sp)
    80003d24:	ec66                	sd	s9,24(sp)
    80003d26:	e86a                	sd	s10,16(sp)
    80003d28:	e46e                	sd	s11,8(sp)
    80003d2a:	1880                	addi	s0,sp,112
    80003d2c:	8b2a                	mv	s6,a0
    80003d2e:	8bae                	mv	s7,a1
    80003d30:	8a32                	mv	s4,a2
    80003d32:	84b6                	mv	s1,a3
    80003d34:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d36:	9f35                	addw	a4,a4,a3
    return 0;
    80003d38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d3a:	0ad76063          	bltu	a4,a3,80003dda <readi+0xd2>
  if(off + n > ip->size)
    80003d3e:	00e7f463          	bgeu	a5,a4,80003d46 <readi+0x3e>
    n = ip->size - off;
    80003d42:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d46:	0a0a8963          	beqz	s5,80003df8 <readi+0xf0>
    80003d4a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d4c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d50:	5c7d                	li	s8,-1
    80003d52:	a82d                	j	80003d8c <readi+0x84>
    80003d54:	020d1d93          	slli	s11,s10,0x20
    80003d58:	020ddd93          	srli	s11,s11,0x20
    80003d5c:	05890613          	addi	a2,s2,88
    80003d60:	86ee                	mv	a3,s11
    80003d62:	963a                	add	a2,a2,a4
    80003d64:	85d2                	mv	a1,s4
    80003d66:	855e                	mv	a0,s7
    80003d68:	ffffe097          	auipc	ra,0xffffe
    80003d6c:	79a080e7          	jalr	1946(ra) # 80002502 <either_copyout>
    80003d70:	05850d63          	beq	a0,s8,80003dca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d74:	854a                	mv	a0,s2
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	5f6080e7          	jalr	1526(ra) # 8000336c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d7e:	013d09bb          	addw	s3,s10,s3
    80003d82:	009d04bb          	addw	s1,s10,s1
    80003d86:	9a6e                	add	s4,s4,s11
    80003d88:	0559f763          	bgeu	s3,s5,80003dd6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d8c:	00a4d59b          	srliw	a1,s1,0xa
    80003d90:	855a                	mv	a0,s6
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	89e080e7          	jalr	-1890(ra) # 80003630 <bmap>
    80003d9a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d9e:	cd85                	beqz	a1,80003dd6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003da0:	000b2503          	lw	a0,0(s6)
    80003da4:	fffff097          	auipc	ra,0xfffff
    80003da8:	498080e7          	jalr	1176(ra) # 8000323c <bread>
    80003dac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dae:	3ff4f713          	andi	a4,s1,1023
    80003db2:	40ec87bb          	subw	a5,s9,a4
    80003db6:	413a86bb          	subw	a3,s5,s3
    80003dba:	8d3e                	mv	s10,a5
    80003dbc:	2781                	sext.w	a5,a5
    80003dbe:	0006861b          	sext.w	a2,a3
    80003dc2:	f8f679e3          	bgeu	a2,a5,80003d54 <readi+0x4c>
    80003dc6:	8d36                	mv	s10,a3
    80003dc8:	b771                	j	80003d54 <readi+0x4c>
      brelse(bp);
    80003dca:	854a                	mv	a0,s2
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	5a0080e7          	jalr	1440(ra) # 8000336c <brelse>
      tot = -1;
    80003dd4:	59fd                	li	s3,-1
  }
  return tot;
    80003dd6:	0009851b          	sext.w	a0,s3
}
    80003dda:	70a6                	ld	ra,104(sp)
    80003ddc:	7406                	ld	s0,96(sp)
    80003dde:	64e6                	ld	s1,88(sp)
    80003de0:	6946                	ld	s2,80(sp)
    80003de2:	69a6                	ld	s3,72(sp)
    80003de4:	6a06                	ld	s4,64(sp)
    80003de6:	7ae2                	ld	s5,56(sp)
    80003de8:	7b42                	ld	s6,48(sp)
    80003dea:	7ba2                	ld	s7,40(sp)
    80003dec:	7c02                	ld	s8,32(sp)
    80003dee:	6ce2                	ld	s9,24(sp)
    80003df0:	6d42                	ld	s10,16(sp)
    80003df2:	6da2                	ld	s11,8(sp)
    80003df4:	6165                	addi	sp,sp,112
    80003df6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df8:	89d6                	mv	s3,s5
    80003dfa:	bff1                	j	80003dd6 <readi+0xce>
    return 0;
    80003dfc:	4501                	li	a0,0
}
    80003dfe:	8082                	ret

0000000080003e00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e00:	457c                	lw	a5,76(a0)
    80003e02:	10d7e863          	bltu	a5,a3,80003f12 <writei+0x112>
{
    80003e06:	7159                	addi	sp,sp,-112
    80003e08:	f486                	sd	ra,104(sp)
    80003e0a:	f0a2                	sd	s0,96(sp)
    80003e0c:	eca6                	sd	s1,88(sp)
    80003e0e:	e8ca                	sd	s2,80(sp)
    80003e10:	e4ce                	sd	s3,72(sp)
    80003e12:	e0d2                	sd	s4,64(sp)
    80003e14:	fc56                	sd	s5,56(sp)
    80003e16:	f85a                	sd	s6,48(sp)
    80003e18:	f45e                	sd	s7,40(sp)
    80003e1a:	f062                	sd	s8,32(sp)
    80003e1c:	ec66                	sd	s9,24(sp)
    80003e1e:	e86a                	sd	s10,16(sp)
    80003e20:	e46e                	sd	s11,8(sp)
    80003e22:	1880                	addi	s0,sp,112
    80003e24:	8aaa                	mv	s5,a0
    80003e26:	8bae                	mv	s7,a1
    80003e28:	8a32                	mv	s4,a2
    80003e2a:	8936                	mv	s2,a3
    80003e2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e2e:	00e687bb          	addw	a5,a3,a4
    80003e32:	0ed7e263          	bltu	a5,a3,80003f16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e36:	00043737          	lui	a4,0x43
    80003e3a:	0ef76063          	bltu	a4,a5,80003f1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e3e:	0c0b0863          	beqz	s6,80003f0e <writei+0x10e>
    80003e42:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e44:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e48:	5c7d                	li	s8,-1
    80003e4a:	a091                	j	80003e8e <writei+0x8e>
    80003e4c:	020d1d93          	slli	s11,s10,0x20
    80003e50:	020ddd93          	srli	s11,s11,0x20
    80003e54:	05848513          	addi	a0,s1,88
    80003e58:	86ee                	mv	a3,s11
    80003e5a:	8652                	mv	a2,s4
    80003e5c:	85de                	mv	a1,s7
    80003e5e:	953a                	add	a0,a0,a4
    80003e60:	ffffe097          	auipc	ra,0xffffe
    80003e64:	6f8080e7          	jalr	1784(ra) # 80002558 <either_copyin>
    80003e68:	07850263          	beq	a0,s8,80003ecc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e6c:	8526                	mv	a0,s1
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	788080e7          	jalr	1928(ra) # 800045f6 <log_write>
    brelse(bp);
    80003e76:	8526                	mv	a0,s1
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	4f4080e7          	jalr	1268(ra) # 8000336c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e80:	013d09bb          	addw	s3,s10,s3
    80003e84:	012d093b          	addw	s2,s10,s2
    80003e88:	9a6e                	add	s4,s4,s11
    80003e8a:	0569f663          	bgeu	s3,s6,80003ed6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e8e:	00a9559b          	srliw	a1,s2,0xa
    80003e92:	8556                	mv	a0,s5
    80003e94:	fffff097          	auipc	ra,0xfffff
    80003e98:	79c080e7          	jalr	1948(ra) # 80003630 <bmap>
    80003e9c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ea0:	c99d                	beqz	a1,80003ed6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003ea2:	000aa503          	lw	a0,0(s5)
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	396080e7          	jalr	918(ra) # 8000323c <bread>
    80003eae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eb0:	3ff97713          	andi	a4,s2,1023
    80003eb4:	40ec87bb          	subw	a5,s9,a4
    80003eb8:	413b06bb          	subw	a3,s6,s3
    80003ebc:	8d3e                	mv	s10,a5
    80003ebe:	2781                	sext.w	a5,a5
    80003ec0:	0006861b          	sext.w	a2,a3
    80003ec4:	f8f674e3          	bgeu	a2,a5,80003e4c <writei+0x4c>
    80003ec8:	8d36                	mv	s10,a3
    80003eca:	b749                	j	80003e4c <writei+0x4c>
      brelse(bp);
    80003ecc:	8526                	mv	a0,s1
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	49e080e7          	jalr	1182(ra) # 8000336c <brelse>
  }

  if(off > ip->size)
    80003ed6:	04caa783          	lw	a5,76(s5)
    80003eda:	0127f463          	bgeu	a5,s2,80003ee2 <writei+0xe2>
    ip->size = off;
    80003ede:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003ee2:	8556                	mv	a0,s5
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	aa4080e7          	jalr	-1372(ra) # 80003988 <iupdate>

  return tot;
    80003eec:	0009851b          	sext.w	a0,s3
}
    80003ef0:	70a6                	ld	ra,104(sp)
    80003ef2:	7406                	ld	s0,96(sp)
    80003ef4:	64e6                	ld	s1,88(sp)
    80003ef6:	6946                	ld	s2,80(sp)
    80003ef8:	69a6                	ld	s3,72(sp)
    80003efa:	6a06                	ld	s4,64(sp)
    80003efc:	7ae2                	ld	s5,56(sp)
    80003efe:	7b42                	ld	s6,48(sp)
    80003f00:	7ba2                	ld	s7,40(sp)
    80003f02:	7c02                	ld	s8,32(sp)
    80003f04:	6ce2                	ld	s9,24(sp)
    80003f06:	6d42                	ld	s10,16(sp)
    80003f08:	6da2                	ld	s11,8(sp)
    80003f0a:	6165                	addi	sp,sp,112
    80003f0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f0e:	89da                	mv	s3,s6
    80003f10:	bfc9                	j	80003ee2 <writei+0xe2>
    return -1;
    80003f12:	557d                	li	a0,-1
}
    80003f14:	8082                	ret
    return -1;
    80003f16:	557d                	li	a0,-1
    80003f18:	bfe1                	j	80003ef0 <writei+0xf0>
    return -1;
    80003f1a:	557d                	li	a0,-1
    80003f1c:	bfd1                	j	80003ef0 <writei+0xf0>

0000000080003f1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f1e:	1141                	addi	sp,sp,-16
    80003f20:	e406                	sd	ra,8(sp)
    80003f22:	e022                	sd	s0,0(sp)
    80003f24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f26:	4639                	li	a2,14
    80003f28:	ffffd097          	auipc	ra,0xffffd
    80003f2c:	e7a080e7          	jalr	-390(ra) # 80000da2 <strncmp>
}
    80003f30:	60a2                	ld	ra,8(sp)
    80003f32:	6402                	ld	s0,0(sp)
    80003f34:	0141                	addi	sp,sp,16
    80003f36:	8082                	ret

0000000080003f38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f38:	7139                	addi	sp,sp,-64
    80003f3a:	fc06                	sd	ra,56(sp)
    80003f3c:	f822                	sd	s0,48(sp)
    80003f3e:	f426                	sd	s1,40(sp)
    80003f40:	f04a                	sd	s2,32(sp)
    80003f42:	ec4e                	sd	s3,24(sp)
    80003f44:	e852                	sd	s4,16(sp)
    80003f46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f48:	04451703          	lh	a4,68(a0)
    80003f4c:	4785                	li	a5,1
    80003f4e:	00f71a63          	bne	a4,a5,80003f62 <dirlookup+0x2a>
    80003f52:	892a                	mv	s2,a0
    80003f54:	89ae                	mv	s3,a1
    80003f56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f58:	457c                	lw	a5,76(a0)
    80003f5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5e:	e79d                	bnez	a5,80003f8c <dirlookup+0x54>
    80003f60:	a8a5                	j	80003fd8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f62:	00004517          	auipc	a0,0x4
    80003f66:	6b650513          	addi	a0,a0,1718 # 80008618 <syscalls+0x1c0>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5d6080e7          	jalr	1494(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003f72:	00004517          	auipc	a0,0x4
    80003f76:	6be50513          	addi	a0,a0,1726 # 80008630 <syscalls+0x1d8>
    80003f7a:	ffffc097          	auipc	ra,0xffffc
    80003f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f82:	24c1                	addiw	s1,s1,16
    80003f84:	04c92783          	lw	a5,76(s2)
    80003f88:	04f4f763          	bgeu	s1,a5,80003fd6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8c:	4741                	li	a4,16
    80003f8e:	86a6                	mv	a3,s1
    80003f90:	fc040613          	addi	a2,s0,-64
    80003f94:	4581                	li	a1,0
    80003f96:	854a                	mv	a0,s2
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	d70080e7          	jalr	-656(ra) # 80003d08 <readi>
    80003fa0:	47c1                	li	a5,16
    80003fa2:	fcf518e3          	bne	a0,a5,80003f72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003fa6:	fc045783          	lhu	a5,-64(s0)
    80003faa:	dfe1                	beqz	a5,80003f82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003fac:	fc240593          	addi	a1,s0,-62
    80003fb0:	854e                	mv	a0,s3
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	f6c080e7          	jalr	-148(ra) # 80003f1e <namecmp>
    80003fba:	f561                	bnez	a0,80003f82 <dirlookup+0x4a>
      if(poff)
    80003fbc:	000a0463          	beqz	s4,80003fc4 <dirlookup+0x8c>
        *poff = off;
    80003fc0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003fc4:	fc045583          	lhu	a1,-64(s0)
    80003fc8:	00092503          	lw	a0,0(s2)
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	74e080e7          	jalr	1870(ra) # 8000371a <iget>
    80003fd4:	a011                	j	80003fd8 <dirlookup+0xa0>
  return 0;
    80003fd6:	4501                	li	a0,0
}
    80003fd8:	70e2                	ld	ra,56(sp)
    80003fda:	7442                	ld	s0,48(sp)
    80003fdc:	74a2                	ld	s1,40(sp)
    80003fde:	7902                	ld	s2,32(sp)
    80003fe0:	69e2                	ld	s3,24(sp)
    80003fe2:	6a42                	ld	s4,16(sp)
    80003fe4:	6121                	addi	sp,sp,64
    80003fe6:	8082                	ret

0000000080003fe8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fe8:	711d                	addi	sp,sp,-96
    80003fea:	ec86                	sd	ra,88(sp)
    80003fec:	e8a2                	sd	s0,80(sp)
    80003fee:	e4a6                	sd	s1,72(sp)
    80003ff0:	e0ca                	sd	s2,64(sp)
    80003ff2:	fc4e                	sd	s3,56(sp)
    80003ff4:	f852                	sd	s4,48(sp)
    80003ff6:	f456                	sd	s5,40(sp)
    80003ff8:	f05a                	sd	s6,32(sp)
    80003ffa:	ec5e                	sd	s7,24(sp)
    80003ffc:	e862                	sd	s8,16(sp)
    80003ffe:	e466                	sd	s9,8(sp)
    80004000:	e06a                	sd	s10,0(sp)
    80004002:	1080                	addi	s0,sp,96
    80004004:	84aa                	mv	s1,a0
    80004006:	8b2e                	mv	s6,a1
    80004008:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000400a:	00054703          	lbu	a4,0(a0)
    8000400e:	02f00793          	li	a5,47
    80004012:	02f70363          	beq	a4,a5,80004038 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004016:	ffffe097          	auipc	ra,0xffffe
    8000401a:	996080e7          	jalr	-1642(ra) # 800019ac <myproc>
    8000401e:	16853503          	ld	a0,360(a0)
    80004022:	00000097          	auipc	ra,0x0
    80004026:	9f4080e7          	jalr	-1548(ra) # 80003a16 <idup>
    8000402a:	8a2a                	mv	s4,a0
  while(*path == '/')
    8000402c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004030:	4cb5                	li	s9,13
  len = path - s;
    80004032:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004034:	4c05                	li	s8,1
    80004036:	a87d                	j	800040f4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004038:	4585                	li	a1,1
    8000403a:	4505                	li	a0,1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	6de080e7          	jalr	1758(ra) # 8000371a <iget>
    80004044:	8a2a                	mv	s4,a0
    80004046:	b7dd                	j	8000402c <namex+0x44>
      iunlockput(ip);
    80004048:	8552                	mv	a0,s4
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	c6c080e7          	jalr	-916(ra) # 80003cb6 <iunlockput>
      return 0;
    80004052:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004054:	8552                	mv	a0,s4
    80004056:	60e6                	ld	ra,88(sp)
    80004058:	6446                	ld	s0,80(sp)
    8000405a:	64a6                	ld	s1,72(sp)
    8000405c:	6906                	ld	s2,64(sp)
    8000405e:	79e2                	ld	s3,56(sp)
    80004060:	7a42                	ld	s4,48(sp)
    80004062:	7aa2                	ld	s5,40(sp)
    80004064:	7b02                	ld	s6,32(sp)
    80004066:	6be2                	ld	s7,24(sp)
    80004068:	6c42                	ld	s8,16(sp)
    8000406a:	6ca2                	ld	s9,8(sp)
    8000406c:	6d02                	ld	s10,0(sp)
    8000406e:	6125                	addi	sp,sp,96
    80004070:	8082                	ret
      iunlock(ip);
    80004072:	8552                	mv	a0,s4
    80004074:	00000097          	auipc	ra,0x0
    80004078:	aa2080e7          	jalr	-1374(ra) # 80003b16 <iunlock>
      return ip;
    8000407c:	bfe1                	j	80004054 <namex+0x6c>
      iunlockput(ip);
    8000407e:	8552                	mv	a0,s4
    80004080:	00000097          	auipc	ra,0x0
    80004084:	c36080e7          	jalr	-970(ra) # 80003cb6 <iunlockput>
      return 0;
    80004088:	8a4e                	mv	s4,s3
    8000408a:	b7e9                	j	80004054 <namex+0x6c>
  len = path - s;
    8000408c:	40998633          	sub	a2,s3,s1
    80004090:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004094:	09acd863          	bge	s9,s10,80004124 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004098:	4639                	li	a2,14
    8000409a:	85a6                	mv	a1,s1
    8000409c:	8556                	mv	a0,s5
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	c90080e7          	jalr	-880(ra) # 80000d2e <memmove>
    800040a6:	84ce                	mv	s1,s3
  while(*path == '/')
    800040a8:	0004c783          	lbu	a5,0(s1)
    800040ac:	01279763          	bne	a5,s2,800040ba <namex+0xd2>
    path++;
    800040b0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040b2:	0004c783          	lbu	a5,0(s1)
    800040b6:	ff278de3          	beq	a5,s2,800040b0 <namex+0xc8>
    ilock(ip);
    800040ba:	8552                	mv	a0,s4
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	998080e7          	jalr	-1640(ra) # 80003a54 <ilock>
    if(ip->type != T_DIR){
    800040c4:	044a1783          	lh	a5,68(s4)
    800040c8:	f98790e3          	bne	a5,s8,80004048 <namex+0x60>
    if(nameiparent && *path == '\0'){
    800040cc:	000b0563          	beqz	s6,800040d6 <namex+0xee>
    800040d0:	0004c783          	lbu	a5,0(s1)
    800040d4:	dfd9                	beqz	a5,80004072 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    800040d6:	865e                	mv	a2,s7
    800040d8:	85d6                	mv	a1,s5
    800040da:	8552                	mv	a0,s4
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	e5c080e7          	jalr	-420(ra) # 80003f38 <dirlookup>
    800040e4:	89aa                	mv	s3,a0
    800040e6:	dd41                	beqz	a0,8000407e <namex+0x96>
    iunlockput(ip);
    800040e8:	8552                	mv	a0,s4
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	bcc080e7          	jalr	-1076(ra) # 80003cb6 <iunlockput>
    ip = next;
    800040f2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800040f4:	0004c783          	lbu	a5,0(s1)
    800040f8:	01279763          	bne	a5,s2,80004106 <namex+0x11e>
    path++;
    800040fc:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040fe:	0004c783          	lbu	a5,0(s1)
    80004102:	ff278de3          	beq	a5,s2,800040fc <namex+0x114>
  if(*path == 0)
    80004106:	cb9d                	beqz	a5,8000413c <namex+0x154>
  while(*path != '/' && *path != 0)
    80004108:	0004c783          	lbu	a5,0(s1)
    8000410c:	89a6                	mv	s3,s1
  len = path - s;
    8000410e:	8d5e                	mv	s10,s7
    80004110:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004112:	01278963          	beq	a5,s2,80004124 <namex+0x13c>
    80004116:	dbbd                	beqz	a5,8000408c <namex+0xa4>
    path++;
    80004118:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000411a:	0009c783          	lbu	a5,0(s3)
    8000411e:	ff279ce3          	bne	a5,s2,80004116 <namex+0x12e>
    80004122:	b7ad                	j	8000408c <namex+0xa4>
    memmove(name, s, len);
    80004124:	2601                	sext.w	a2,a2
    80004126:	85a6                	mv	a1,s1
    80004128:	8556                	mv	a0,s5
    8000412a:	ffffd097          	auipc	ra,0xffffd
    8000412e:	c04080e7          	jalr	-1020(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004132:	9d56                	add	s10,s10,s5
    80004134:	000d0023          	sb	zero,0(s10)
    80004138:	84ce                	mv	s1,s3
    8000413a:	b7bd                	j	800040a8 <namex+0xc0>
  if(nameiparent){
    8000413c:	f00b0ce3          	beqz	s6,80004054 <namex+0x6c>
    iput(ip);
    80004140:	8552                	mv	a0,s4
    80004142:	00000097          	auipc	ra,0x0
    80004146:	acc080e7          	jalr	-1332(ra) # 80003c0e <iput>
    return 0;
    8000414a:	4a01                	li	s4,0
    8000414c:	b721                	j	80004054 <namex+0x6c>

000000008000414e <dirlink>:
{
    8000414e:	7139                	addi	sp,sp,-64
    80004150:	fc06                	sd	ra,56(sp)
    80004152:	f822                	sd	s0,48(sp)
    80004154:	f426                	sd	s1,40(sp)
    80004156:	f04a                	sd	s2,32(sp)
    80004158:	ec4e                	sd	s3,24(sp)
    8000415a:	e852                	sd	s4,16(sp)
    8000415c:	0080                	addi	s0,sp,64
    8000415e:	892a                	mv	s2,a0
    80004160:	8a2e                	mv	s4,a1
    80004162:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004164:	4601                	li	a2,0
    80004166:	00000097          	auipc	ra,0x0
    8000416a:	dd2080e7          	jalr	-558(ra) # 80003f38 <dirlookup>
    8000416e:	e93d                	bnez	a0,800041e4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004170:	04c92483          	lw	s1,76(s2)
    80004174:	c49d                	beqz	s1,800041a2 <dirlink+0x54>
    80004176:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004178:	4741                	li	a4,16
    8000417a:	86a6                	mv	a3,s1
    8000417c:	fc040613          	addi	a2,s0,-64
    80004180:	4581                	li	a1,0
    80004182:	854a                	mv	a0,s2
    80004184:	00000097          	auipc	ra,0x0
    80004188:	b84080e7          	jalr	-1148(ra) # 80003d08 <readi>
    8000418c:	47c1                	li	a5,16
    8000418e:	06f51163          	bne	a0,a5,800041f0 <dirlink+0xa2>
    if(de.inum == 0)
    80004192:	fc045783          	lhu	a5,-64(s0)
    80004196:	c791                	beqz	a5,800041a2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004198:	24c1                	addiw	s1,s1,16
    8000419a:	04c92783          	lw	a5,76(s2)
    8000419e:	fcf4ede3          	bltu	s1,a5,80004178 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041a2:	4639                	li	a2,14
    800041a4:	85d2                	mv	a1,s4
    800041a6:	fc240513          	addi	a0,s0,-62
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	c34080e7          	jalr	-972(ra) # 80000dde <strncpy>
  de.inum = inum;
    800041b2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041b6:	4741                	li	a4,16
    800041b8:	86a6                	mv	a3,s1
    800041ba:	fc040613          	addi	a2,s0,-64
    800041be:	4581                	li	a1,0
    800041c0:	854a                	mv	a0,s2
    800041c2:	00000097          	auipc	ra,0x0
    800041c6:	c3e080e7          	jalr	-962(ra) # 80003e00 <writei>
    800041ca:	1541                	addi	a0,a0,-16
    800041cc:	00a03533          	snez	a0,a0
    800041d0:	40a00533          	neg	a0,a0
}
    800041d4:	70e2                	ld	ra,56(sp)
    800041d6:	7442                	ld	s0,48(sp)
    800041d8:	74a2                	ld	s1,40(sp)
    800041da:	7902                	ld	s2,32(sp)
    800041dc:	69e2                	ld	s3,24(sp)
    800041de:	6a42                	ld	s4,16(sp)
    800041e0:	6121                	addi	sp,sp,64
    800041e2:	8082                	ret
    iput(ip);
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	a2a080e7          	jalr	-1494(ra) # 80003c0e <iput>
    return -1;
    800041ec:	557d                	li	a0,-1
    800041ee:	b7dd                	j	800041d4 <dirlink+0x86>
      panic("dirlink read");
    800041f0:	00004517          	auipc	a0,0x4
    800041f4:	45050513          	addi	a0,a0,1104 # 80008640 <syscalls+0x1e8>
    800041f8:	ffffc097          	auipc	ra,0xffffc
    800041fc:	348080e7          	jalr	840(ra) # 80000540 <panic>

0000000080004200 <namei>:

struct inode*
namei(char *path)
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004208:	fe040613          	addi	a2,s0,-32
    8000420c:	4581                	li	a1,0
    8000420e:	00000097          	auipc	ra,0x0
    80004212:	dda080e7          	jalr	-550(ra) # 80003fe8 <namex>
}
    80004216:	60e2                	ld	ra,24(sp)
    80004218:	6442                	ld	s0,16(sp)
    8000421a:	6105                	addi	sp,sp,32
    8000421c:	8082                	ret

000000008000421e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000421e:	1141                	addi	sp,sp,-16
    80004220:	e406                	sd	ra,8(sp)
    80004222:	e022                	sd	s0,0(sp)
    80004224:	0800                	addi	s0,sp,16
    80004226:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004228:	4585                	li	a1,1
    8000422a:	00000097          	auipc	ra,0x0
    8000422e:	dbe080e7          	jalr	-578(ra) # 80003fe8 <namex>
}
    80004232:	60a2                	ld	ra,8(sp)
    80004234:	6402                	ld	s0,0(sp)
    80004236:	0141                	addi	sp,sp,16
    80004238:	8082                	ret

000000008000423a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000423a:	1101                	addi	sp,sp,-32
    8000423c:	ec06                	sd	ra,24(sp)
    8000423e:	e822                	sd	s0,16(sp)
    80004240:	e426                	sd	s1,8(sp)
    80004242:	e04a                	sd	s2,0(sp)
    80004244:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004246:	0001d917          	auipc	s2,0x1d
    8000424a:	71a90913          	addi	s2,s2,1818 # 80021960 <log>
    8000424e:	01892583          	lw	a1,24(s2)
    80004252:	02892503          	lw	a0,40(s2)
    80004256:	fffff097          	auipc	ra,0xfffff
    8000425a:	fe6080e7          	jalr	-26(ra) # 8000323c <bread>
    8000425e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004260:	02c92683          	lw	a3,44(s2)
    80004264:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004266:	02d05863          	blez	a3,80004296 <write_head+0x5c>
    8000426a:	0001d797          	auipc	a5,0x1d
    8000426e:	72678793          	addi	a5,a5,1830 # 80021990 <log+0x30>
    80004272:	05c50713          	addi	a4,a0,92
    80004276:	36fd                	addiw	a3,a3,-1
    80004278:	02069613          	slli	a2,a3,0x20
    8000427c:	01e65693          	srli	a3,a2,0x1e
    80004280:	0001d617          	auipc	a2,0x1d
    80004284:	71460613          	addi	a2,a2,1812 # 80021994 <log+0x34>
    80004288:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000428a:	4390                	lw	a2,0(a5)
    8000428c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000428e:	0791                	addi	a5,a5,4
    80004290:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004292:	fed79ce3          	bne	a5,a3,8000428a <write_head+0x50>
  }
  bwrite(buf);
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	096080e7          	jalr	150(ra) # 8000332e <bwrite>
  brelse(buf);
    800042a0:	8526                	mv	a0,s1
    800042a2:	fffff097          	auipc	ra,0xfffff
    800042a6:	0ca080e7          	jalr	202(ra) # 8000336c <brelse>
}
    800042aa:	60e2                	ld	ra,24(sp)
    800042ac:	6442                	ld	s0,16(sp)
    800042ae:	64a2                	ld	s1,8(sp)
    800042b0:	6902                	ld	s2,0(sp)
    800042b2:	6105                	addi	sp,sp,32
    800042b4:	8082                	ret

00000000800042b6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b6:	0001d797          	auipc	a5,0x1d
    800042ba:	6d67a783          	lw	a5,1750(a5) # 8002198c <log+0x2c>
    800042be:	0af05d63          	blez	a5,80004378 <install_trans+0xc2>
{
    800042c2:	7139                	addi	sp,sp,-64
    800042c4:	fc06                	sd	ra,56(sp)
    800042c6:	f822                	sd	s0,48(sp)
    800042c8:	f426                	sd	s1,40(sp)
    800042ca:	f04a                	sd	s2,32(sp)
    800042cc:	ec4e                	sd	s3,24(sp)
    800042ce:	e852                	sd	s4,16(sp)
    800042d0:	e456                	sd	s5,8(sp)
    800042d2:	e05a                	sd	s6,0(sp)
    800042d4:	0080                	addi	s0,sp,64
    800042d6:	8b2a                	mv	s6,a0
    800042d8:	0001da97          	auipc	s5,0x1d
    800042dc:	6b8a8a93          	addi	s5,s5,1720 # 80021990 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042e2:	0001d997          	auipc	s3,0x1d
    800042e6:	67e98993          	addi	s3,s3,1662 # 80021960 <log>
    800042ea:	a00d                	j	8000430c <install_trans+0x56>
    brelse(lbuf);
    800042ec:	854a                	mv	a0,s2
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	07e080e7          	jalr	126(ra) # 8000336c <brelse>
    brelse(dbuf);
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	074080e7          	jalr	116(ra) # 8000336c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004300:	2a05                	addiw	s4,s4,1
    80004302:	0a91                	addi	s5,s5,4
    80004304:	02c9a783          	lw	a5,44(s3)
    80004308:	04fa5e63          	bge	s4,a5,80004364 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000430c:	0189a583          	lw	a1,24(s3)
    80004310:	014585bb          	addw	a1,a1,s4
    80004314:	2585                	addiw	a1,a1,1
    80004316:	0289a503          	lw	a0,40(s3)
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	f22080e7          	jalr	-222(ra) # 8000323c <bread>
    80004322:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004324:	000aa583          	lw	a1,0(s5)
    80004328:	0289a503          	lw	a0,40(s3)
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	f10080e7          	jalr	-240(ra) # 8000323c <bread>
    80004334:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004336:	40000613          	li	a2,1024
    8000433a:	05890593          	addi	a1,s2,88
    8000433e:	05850513          	addi	a0,a0,88
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	9ec080e7          	jalr	-1556(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	fe2080e7          	jalr	-30(ra) # 8000332e <bwrite>
    if(recovering == 0)
    80004354:	f80b1ce3          	bnez	s6,800042ec <install_trans+0x36>
      bunpin(dbuf);
    80004358:	8526                	mv	a0,s1
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	0ec080e7          	jalr	236(ra) # 80003446 <bunpin>
    80004362:	b769                	j	800042ec <install_trans+0x36>
}
    80004364:	70e2                	ld	ra,56(sp)
    80004366:	7442                	ld	s0,48(sp)
    80004368:	74a2                	ld	s1,40(sp)
    8000436a:	7902                	ld	s2,32(sp)
    8000436c:	69e2                	ld	s3,24(sp)
    8000436e:	6a42                	ld	s4,16(sp)
    80004370:	6aa2                	ld	s5,8(sp)
    80004372:	6b02                	ld	s6,0(sp)
    80004374:	6121                	addi	sp,sp,64
    80004376:	8082                	ret
    80004378:	8082                	ret

000000008000437a <initlog>:
{
    8000437a:	7179                	addi	sp,sp,-48
    8000437c:	f406                	sd	ra,40(sp)
    8000437e:	f022                	sd	s0,32(sp)
    80004380:	ec26                	sd	s1,24(sp)
    80004382:	e84a                	sd	s2,16(sp)
    80004384:	e44e                	sd	s3,8(sp)
    80004386:	1800                	addi	s0,sp,48
    80004388:	892a                	mv	s2,a0
    8000438a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000438c:	0001d497          	auipc	s1,0x1d
    80004390:	5d448493          	addi	s1,s1,1492 # 80021960 <log>
    80004394:	00004597          	auipc	a1,0x4
    80004398:	2bc58593          	addi	a1,a1,700 # 80008650 <syscalls+0x1f8>
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffc097          	auipc	ra,0xffffc
    800043a2:	7a8080e7          	jalr	1960(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800043a6:	0149a583          	lw	a1,20(s3)
    800043aa:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800043ac:	0109a783          	lw	a5,16(s3)
    800043b0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800043b2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800043b6:	854a                	mv	a0,s2
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	e84080e7          	jalr	-380(ra) # 8000323c <bread>
  log.lh.n = lh->n;
    800043c0:	4d34                	lw	a3,88(a0)
    800043c2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	02d05663          	blez	a3,800043f0 <initlog+0x76>
    800043c8:	05c50793          	addi	a5,a0,92
    800043cc:	0001d717          	auipc	a4,0x1d
    800043d0:	5c470713          	addi	a4,a4,1476 # 80021990 <log+0x30>
    800043d4:	36fd                	addiw	a3,a3,-1
    800043d6:	02069613          	slli	a2,a3,0x20
    800043da:	01e65693          	srli	a3,a2,0x1e
    800043de:	06050613          	addi	a2,a0,96
    800043e2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043e4:	4390                	lw	a2,0(a5)
    800043e6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043e8:	0791                	addi	a5,a5,4
    800043ea:	0711                	addi	a4,a4,4
    800043ec:	fed79ce3          	bne	a5,a3,800043e4 <initlog+0x6a>
  brelse(buf);
    800043f0:	fffff097          	auipc	ra,0xfffff
    800043f4:	f7c080e7          	jalr	-132(ra) # 8000336c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043f8:	4505                	li	a0,1
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	ebc080e7          	jalr	-324(ra) # 800042b6 <install_trans>
  log.lh.n = 0;
    80004402:	0001d797          	auipc	a5,0x1d
    80004406:	5807a523          	sw	zero,1418(a5) # 8002198c <log+0x2c>
  write_head(); // clear the log
    8000440a:	00000097          	auipc	ra,0x0
    8000440e:	e30080e7          	jalr	-464(ra) # 8000423a <write_head>
}
    80004412:	70a2                	ld	ra,40(sp)
    80004414:	7402                	ld	s0,32(sp)
    80004416:	64e2                	ld	s1,24(sp)
    80004418:	6942                	ld	s2,16(sp)
    8000441a:	69a2                	ld	s3,8(sp)
    8000441c:	6145                	addi	sp,sp,48
    8000441e:	8082                	ret

0000000080004420 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004420:	1101                	addi	sp,sp,-32
    80004422:	ec06                	sd	ra,24(sp)
    80004424:	e822                	sd	s0,16(sp)
    80004426:	e426                	sd	s1,8(sp)
    80004428:	e04a                	sd	s2,0(sp)
    8000442a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000442c:	0001d517          	auipc	a0,0x1d
    80004430:	53450513          	addi	a0,a0,1332 # 80021960 <log>
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	7a2080e7          	jalr	1954(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000443c:	0001d497          	auipc	s1,0x1d
    80004440:	52448493          	addi	s1,s1,1316 # 80021960 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004444:	4979                	li	s2,30
    80004446:	a039                	j	80004454 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004448:	85a6                	mv	a1,s1
    8000444a:	8526                	mv	a0,s1
    8000444c:	ffffe097          	auipc	ra,0xffffe
    80004450:	ca2080e7          	jalr	-862(ra) # 800020ee <sleep>
    if(log.committing){
    80004454:	50dc                	lw	a5,36(s1)
    80004456:	fbed                	bnez	a5,80004448 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004458:	5098                	lw	a4,32(s1)
    8000445a:	2705                	addiw	a4,a4,1
    8000445c:	0007069b          	sext.w	a3,a4
    80004460:	0027179b          	slliw	a5,a4,0x2
    80004464:	9fb9                	addw	a5,a5,a4
    80004466:	0017979b          	slliw	a5,a5,0x1
    8000446a:	54d8                	lw	a4,44(s1)
    8000446c:	9fb9                	addw	a5,a5,a4
    8000446e:	00f95963          	bge	s2,a5,80004480 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004472:	85a6                	mv	a1,s1
    80004474:	8526                	mv	a0,s1
    80004476:	ffffe097          	auipc	ra,0xffffe
    8000447a:	c78080e7          	jalr	-904(ra) # 800020ee <sleep>
    8000447e:	bfd9                	j	80004454 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004480:	0001d517          	auipc	a0,0x1d
    80004484:	4e050513          	addi	a0,a0,1248 # 80021960 <log>
    80004488:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	800080e7          	jalr	-2048(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004492:	60e2                	ld	ra,24(sp)
    80004494:	6442                	ld	s0,16(sp)
    80004496:	64a2                	ld	s1,8(sp)
    80004498:	6902                	ld	s2,0(sp)
    8000449a:	6105                	addi	sp,sp,32
    8000449c:	8082                	ret

000000008000449e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000449e:	7139                	addi	sp,sp,-64
    800044a0:	fc06                	sd	ra,56(sp)
    800044a2:	f822                	sd	s0,48(sp)
    800044a4:	f426                	sd	s1,40(sp)
    800044a6:	f04a                	sd	s2,32(sp)
    800044a8:	ec4e                	sd	s3,24(sp)
    800044aa:	e852                	sd	s4,16(sp)
    800044ac:	e456                	sd	s5,8(sp)
    800044ae:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800044b0:	0001d497          	auipc	s1,0x1d
    800044b4:	4b048493          	addi	s1,s1,1200 # 80021960 <log>
    800044b8:	8526                	mv	a0,s1
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	71c080e7          	jalr	1820(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800044c2:	509c                	lw	a5,32(s1)
    800044c4:	37fd                	addiw	a5,a5,-1
    800044c6:	0007891b          	sext.w	s2,a5
    800044ca:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800044cc:	50dc                	lw	a5,36(s1)
    800044ce:	e7b9                	bnez	a5,8000451c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800044d0:	04091e63          	bnez	s2,8000452c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800044d4:	0001d497          	auipc	s1,0x1d
    800044d8:	48c48493          	addi	s1,s1,1164 # 80021960 <log>
    800044dc:	4785                	li	a5,1
    800044de:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7a8080e7          	jalr	1960(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044ea:	54dc                	lw	a5,44(s1)
    800044ec:	06f04763          	bgtz	a5,8000455a <end_op+0xbc>
    acquire(&log.lock);
    800044f0:	0001d497          	auipc	s1,0x1d
    800044f4:	47048493          	addi	s1,s1,1136 # 80021960 <log>
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004502:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004506:	8526                	mv	a0,s1
    80004508:	ffffe097          	auipc	ra,0xffffe
    8000450c:	c4a080e7          	jalr	-950(ra) # 80002152 <wakeup>
    release(&log.lock);
    80004510:	8526                	mv	a0,s1
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	778080e7          	jalr	1912(ra) # 80000c8a <release>
}
    8000451a:	a03d                	j	80004548 <end_op+0xaa>
    panic("log.committing");
    8000451c:	00004517          	auipc	a0,0x4
    80004520:	13c50513          	addi	a0,a0,316 # 80008658 <syscalls+0x200>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	01c080e7          	jalr	28(ra) # 80000540 <panic>
    wakeup(&log);
    8000452c:	0001d497          	auipc	s1,0x1d
    80004530:	43448493          	addi	s1,s1,1076 # 80021960 <log>
    80004534:	8526                	mv	a0,s1
    80004536:	ffffe097          	auipc	ra,0xffffe
    8000453a:	c1c080e7          	jalr	-996(ra) # 80002152 <wakeup>
  release(&log.lock);
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	74a080e7          	jalr	1866(ra) # 80000c8a <release>
}
    80004548:	70e2                	ld	ra,56(sp)
    8000454a:	7442                	ld	s0,48(sp)
    8000454c:	74a2                	ld	s1,40(sp)
    8000454e:	7902                	ld	s2,32(sp)
    80004550:	69e2                	ld	s3,24(sp)
    80004552:	6a42                	ld	s4,16(sp)
    80004554:	6aa2                	ld	s5,8(sp)
    80004556:	6121                	addi	sp,sp,64
    80004558:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455a:	0001da97          	auipc	s5,0x1d
    8000455e:	436a8a93          	addi	s5,s5,1078 # 80021990 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004562:	0001da17          	auipc	s4,0x1d
    80004566:	3fea0a13          	addi	s4,s4,1022 # 80021960 <log>
    8000456a:	018a2583          	lw	a1,24(s4)
    8000456e:	012585bb          	addw	a1,a1,s2
    80004572:	2585                	addiw	a1,a1,1
    80004574:	028a2503          	lw	a0,40(s4)
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	cc4080e7          	jalr	-828(ra) # 8000323c <bread>
    80004580:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004582:	000aa583          	lw	a1,0(s5)
    80004586:	028a2503          	lw	a0,40(s4)
    8000458a:	fffff097          	auipc	ra,0xfffff
    8000458e:	cb2080e7          	jalr	-846(ra) # 8000323c <bread>
    80004592:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004594:	40000613          	li	a2,1024
    80004598:	05850593          	addi	a1,a0,88
    8000459c:	05848513          	addi	a0,s1,88
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	78e080e7          	jalr	1934(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800045a8:	8526                	mv	a0,s1
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	d84080e7          	jalr	-636(ra) # 8000332e <bwrite>
    brelse(from);
    800045b2:	854e                	mv	a0,s3
    800045b4:	fffff097          	auipc	ra,0xfffff
    800045b8:	db8080e7          	jalr	-584(ra) # 8000336c <brelse>
    brelse(to);
    800045bc:	8526                	mv	a0,s1
    800045be:	fffff097          	auipc	ra,0xfffff
    800045c2:	dae080e7          	jalr	-594(ra) # 8000336c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045c6:	2905                	addiw	s2,s2,1
    800045c8:	0a91                	addi	s5,s5,4
    800045ca:	02ca2783          	lw	a5,44(s4)
    800045ce:	f8f94ee3          	blt	s2,a5,8000456a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800045d2:	00000097          	auipc	ra,0x0
    800045d6:	c68080e7          	jalr	-920(ra) # 8000423a <write_head>
    install_trans(0); // Now install writes to home locations
    800045da:	4501                	li	a0,0
    800045dc:	00000097          	auipc	ra,0x0
    800045e0:	cda080e7          	jalr	-806(ra) # 800042b6 <install_trans>
    log.lh.n = 0;
    800045e4:	0001d797          	auipc	a5,0x1d
    800045e8:	3a07a423          	sw	zero,936(a5) # 8002198c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	c4e080e7          	jalr	-946(ra) # 8000423a <write_head>
    800045f4:	bdf5                	j	800044f0 <end_op+0x52>

00000000800045f6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045f6:	1101                	addi	sp,sp,-32
    800045f8:	ec06                	sd	ra,24(sp)
    800045fa:	e822                	sd	s0,16(sp)
    800045fc:	e426                	sd	s1,8(sp)
    800045fe:	e04a                	sd	s2,0(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004604:	0001d917          	auipc	s2,0x1d
    80004608:	35c90913          	addi	s2,s2,860 # 80021960 <log>
    8000460c:	854a                	mv	a0,s2
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	5c8080e7          	jalr	1480(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004616:	02c92603          	lw	a2,44(s2)
    8000461a:	47f5                	li	a5,29
    8000461c:	06c7c563          	blt	a5,a2,80004686 <log_write+0x90>
    80004620:	0001d797          	auipc	a5,0x1d
    80004624:	35c7a783          	lw	a5,860(a5) # 8002197c <log+0x1c>
    80004628:	37fd                	addiw	a5,a5,-1
    8000462a:	04f65e63          	bge	a2,a5,80004686 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000462e:	0001d797          	auipc	a5,0x1d
    80004632:	3527a783          	lw	a5,850(a5) # 80021980 <log+0x20>
    80004636:	06f05063          	blez	a5,80004696 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000463a:	4781                	li	a5,0
    8000463c:	06c05563          	blez	a2,800046a6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004640:	44cc                	lw	a1,12(s1)
    80004642:	0001d717          	auipc	a4,0x1d
    80004646:	34e70713          	addi	a4,a4,846 # 80021990 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000464a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000464c:	4314                	lw	a3,0(a4)
    8000464e:	04b68c63          	beq	a3,a1,800046a6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004652:	2785                	addiw	a5,a5,1
    80004654:	0711                	addi	a4,a4,4
    80004656:	fef61be3          	bne	a2,a5,8000464c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000465a:	0621                	addi	a2,a2,8
    8000465c:	060a                	slli	a2,a2,0x2
    8000465e:	0001d797          	auipc	a5,0x1d
    80004662:	30278793          	addi	a5,a5,770 # 80021960 <log>
    80004666:	97b2                	add	a5,a5,a2
    80004668:	44d8                	lw	a4,12(s1)
    8000466a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000466c:	8526                	mv	a0,s1
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	d9c080e7          	jalr	-612(ra) # 8000340a <bpin>
    log.lh.n++;
    80004676:	0001d717          	auipc	a4,0x1d
    8000467a:	2ea70713          	addi	a4,a4,746 # 80021960 <log>
    8000467e:	575c                	lw	a5,44(a4)
    80004680:	2785                	addiw	a5,a5,1
    80004682:	d75c                	sw	a5,44(a4)
    80004684:	a82d                	j	800046be <log_write+0xc8>
    panic("too big a transaction");
    80004686:	00004517          	auipc	a0,0x4
    8000468a:	fe250513          	addi	a0,a0,-30 # 80008668 <syscalls+0x210>
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	eb2080e7          	jalr	-334(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004696:	00004517          	auipc	a0,0x4
    8000469a:	fea50513          	addi	a0,a0,-22 # 80008680 <syscalls+0x228>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	ea2080e7          	jalr	-350(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800046a6:	00878693          	addi	a3,a5,8
    800046aa:	068a                	slli	a3,a3,0x2
    800046ac:	0001d717          	auipc	a4,0x1d
    800046b0:	2b470713          	addi	a4,a4,692 # 80021960 <log>
    800046b4:	9736                	add	a4,a4,a3
    800046b6:	44d4                	lw	a3,12(s1)
    800046b8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800046ba:	faf609e3          	beq	a2,a5,8000466c <log_write+0x76>
  }
  release(&log.lock);
    800046be:	0001d517          	auipc	a0,0x1d
    800046c2:	2a250513          	addi	a0,a0,674 # 80021960 <log>
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	5c4080e7          	jalr	1476(ra) # 80000c8a <release>
}
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6902                	ld	s2,0(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret

00000000800046da <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	e04a                	sd	s2,0(sp)
    800046e4:	1000                	addi	s0,sp,32
    800046e6:	84aa                	mv	s1,a0
    800046e8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046ea:	00004597          	auipc	a1,0x4
    800046ee:	fb658593          	addi	a1,a1,-74 # 800086a0 <syscalls+0x248>
    800046f2:	0521                	addi	a0,a0,8
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	452080e7          	jalr	1106(ra) # 80000b46 <initlock>
  lk->name = name;
    800046fc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004700:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004704:	0204a423          	sw	zero,40(s1)
}
    80004708:	60e2                	ld	ra,24(sp)
    8000470a:	6442                	ld	s0,16(sp)
    8000470c:	64a2                	ld	s1,8(sp)
    8000470e:	6902                	ld	s2,0(sp)
    80004710:	6105                	addi	sp,sp,32
    80004712:	8082                	ret

0000000080004714 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004714:	1101                	addi	sp,sp,-32
    80004716:	ec06                	sd	ra,24(sp)
    80004718:	e822                	sd	s0,16(sp)
    8000471a:	e426                	sd	s1,8(sp)
    8000471c:	e04a                	sd	s2,0(sp)
    8000471e:	1000                	addi	s0,sp,32
    80004720:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004722:	00850913          	addi	s2,a0,8
    80004726:	854a                	mv	a0,s2
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	4ae080e7          	jalr	1198(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004730:	409c                	lw	a5,0(s1)
    80004732:	cb89                	beqz	a5,80004744 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004734:	85ca                	mv	a1,s2
    80004736:	8526                	mv	a0,s1
    80004738:	ffffe097          	auipc	ra,0xffffe
    8000473c:	9b6080e7          	jalr	-1610(ra) # 800020ee <sleep>
  while (lk->locked) {
    80004740:	409c                	lw	a5,0(s1)
    80004742:	fbed                	bnez	a5,80004734 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004744:	4785                	li	a5,1
    80004746:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004748:	ffffd097          	auipc	ra,0xffffd
    8000474c:	264080e7          	jalr	612(ra) # 800019ac <myproc>
    80004750:	591c                	lw	a5,48(a0)
    80004752:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000475e:	60e2                	ld	ra,24(sp)
    80004760:	6442                	ld	s0,16(sp)
    80004762:	64a2                	ld	s1,8(sp)
    80004764:	6902                	ld	s2,0(sp)
    80004766:	6105                	addi	sp,sp,32
    80004768:	8082                	ret

000000008000476a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000476a:	1101                	addi	sp,sp,-32
    8000476c:	ec06                	sd	ra,24(sp)
    8000476e:	e822                	sd	s0,16(sp)
    80004770:	e426                	sd	s1,8(sp)
    80004772:	e04a                	sd	s2,0(sp)
    80004774:	1000                	addi	s0,sp,32
    80004776:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004778:	00850913          	addi	s2,a0,8
    8000477c:	854a                	mv	a0,s2
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	458080e7          	jalr	1112(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004786:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000478a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffe097          	auipc	ra,0xffffe
    80004794:	9c2080e7          	jalr	-1598(ra) # 80002152 <wakeup>
  release(&lk->lk);
    80004798:	854a                	mv	a0,s2
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	4f0080e7          	jalr	1264(ra) # 80000c8a <release>
}
    800047a2:	60e2                	ld	ra,24(sp)
    800047a4:	6442                	ld	s0,16(sp)
    800047a6:	64a2                	ld	s1,8(sp)
    800047a8:	6902                	ld	s2,0(sp)
    800047aa:	6105                	addi	sp,sp,32
    800047ac:	8082                	ret

00000000800047ae <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800047ae:	7179                	addi	sp,sp,-48
    800047b0:	f406                	sd	ra,40(sp)
    800047b2:	f022                	sd	s0,32(sp)
    800047b4:	ec26                	sd	s1,24(sp)
    800047b6:	e84a                	sd	s2,16(sp)
    800047b8:	e44e                	sd	s3,8(sp)
    800047ba:	1800                	addi	s0,sp,48
    800047bc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800047be:	00850913          	addi	s2,a0,8
    800047c2:	854a                	mv	a0,s2
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	412080e7          	jalr	1042(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800047cc:	409c                	lw	a5,0(s1)
    800047ce:	ef99                	bnez	a5,800047ec <holdingsleep+0x3e>
    800047d0:	4481                	li	s1,0
  release(&lk->lk);
    800047d2:	854a                	mv	a0,s2
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	4b6080e7          	jalr	1206(ra) # 80000c8a <release>
  return r;
}
    800047dc:	8526                	mv	a0,s1
    800047de:	70a2                	ld	ra,40(sp)
    800047e0:	7402                	ld	s0,32(sp)
    800047e2:	64e2                	ld	s1,24(sp)
    800047e4:	6942                	ld	s2,16(sp)
    800047e6:	69a2                	ld	s3,8(sp)
    800047e8:	6145                	addi	sp,sp,48
    800047ea:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047ec:	0284a983          	lw	s3,40(s1)
    800047f0:	ffffd097          	auipc	ra,0xffffd
    800047f4:	1bc080e7          	jalr	444(ra) # 800019ac <myproc>
    800047f8:	5904                	lw	s1,48(a0)
    800047fa:	413484b3          	sub	s1,s1,s3
    800047fe:	0014b493          	seqz	s1,s1
    80004802:	bfc1                	j	800047d2 <holdingsleep+0x24>

0000000080004804 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004804:	1141                	addi	sp,sp,-16
    80004806:	e406                	sd	ra,8(sp)
    80004808:	e022                	sd	s0,0(sp)
    8000480a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000480c:	00004597          	auipc	a1,0x4
    80004810:	ea458593          	addi	a1,a1,-348 # 800086b0 <syscalls+0x258>
    80004814:	0001d517          	auipc	a0,0x1d
    80004818:	29450513          	addi	a0,a0,660 # 80021aa8 <ftable>
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	32a080e7          	jalr	810(ra) # 80000b46 <initlock>
}
    80004824:	60a2                	ld	ra,8(sp)
    80004826:	6402                	ld	s0,0(sp)
    80004828:	0141                	addi	sp,sp,16
    8000482a:	8082                	ret

000000008000482c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000482c:	1101                	addi	sp,sp,-32
    8000482e:	ec06                	sd	ra,24(sp)
    80004830:	e822                	sd	s0,16(sp)
    80004832:	e426                	sd	s1,8(sp)
    80004834:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004836:	0001d517          	auipc	a0,0x1d
    8000483a:	27250513          	addi	a0,a0,626 # 80021aa8 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	398080e7          	jalr	920(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004846:	0001d497          	auipc	s1,0x1d
    8000484a:	27a48493          	addi	s1,s1,634 # 80021ac0 <ftable+0x18>
    8000484e:	0001e717          	auipc	a4,0x1e
    80004852:	21270713          	addi	a4,a4,530 # 80022a60 <disk>
    if(f->ref == 0){
    80004856:	40dc                	lw	a5,4(s1)
    80004858:	cf99                	beqz	a5,80004876 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000485a:	02848493          	addi	s1,s1,40
    8000485e:	fee49ce3          	bne	s1,a4,80004856 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004862:	0001d517          	auipc	a0,0x1d
    80004866:	24650513          	addi	a0,a0,582 # 80021aa8 <ftable>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	420080e7          	jalr	1056(ra) # 80000c8a <release>
  return 0;
    80004872:	4481                	li	s1,0
    80004874:	a819                	j	8000488a <filealloc+0x5e>
      f->ref = 1;
    80004876:	4785                	li	a5,1
    80004878:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000487a:	0001d517          	auipc	a0,0x1d
    8000487e:	22e50513          	addi	a0,a0,558 # 80021aa8 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	408080e7          	jalr	1032(ra) # 80000c8a <release>
}
    8000488a:	8526                	mv	a0,s1
    8000488c:	60e2                	ld	ra,24(sp)
    8000488e:	6442                	ld	s0,16(sp)
    80004890:	64a2                	ld	s1,8(sp)
    80004892:	6105                	addi	sp,sp,32
    80004894:	8082                	ret

0000000080004896 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004896:	1101                	addi	sp,sp,-32
    80004898:	ec06                	sd	ra,24(sp)
    8000489a:	e822                	sd	s0,16(sp)
    8000489c:	e426                	sd	s1,8(sp)
    8000489e:	1000                	addi	s0,sp,32
    800048a0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800048a2:	0001d517          	auipc	a0,0x1d
    800048a6:	20650513          	addi	a0,a0,518 # 80021aa8 <ftable>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	32c080e7          	jalr	812(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800048b2:	40dc                	lw	a5,4(s1)
    800048b4:	02f05263          	blez	a5,800048d8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800048b8:	2785                	addiw	a5,a5,1
    800048ba:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800048bc:	0001d517          	auipc	a0,0x1d
    800048c0:	1ec50513          	addi	a0,a0,492 # 80021aa8 <ftable>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	3c6080e7          	jalr	966(ra) # 80000c8a <release>
  return f;
}
    800048cc:	8526                	mv	a0,s1
    800048ce:	60e2                	ld	ra,24(sp)
    800048d0:	6442                	ld	s0,16(sp)
    800048d2:	64a2                	ld	s1,8(sp)
    800048d4:	6105                	addi	sp,sp,32
    800048d6:	8082                	ret
    panic("filedup");
    800048d8:	00004517          	auipc	a0,0x4
    800048dc:	de050513          	addi	a0,a0,-544 # 800086b8 <syscalls+0x260>
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>

00000000800048e8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048e8:	7139                	addi	sp,sp,-64
    800048ea:	fc06                	sd	ra,56(sp)
    800048ec:	f822                	sd	s0,48(sp)
    800048ee:	f426                	sd	s1,40(sp)
    800048f0:	f04a                	sd	s2,32(sp)
    800048f2:	ec4e                	sd	s3,24(sp)
    800048f4:	e852                	sd	s4,16(sp)
    800048f6:	e456                	sd	s5,8(sp)
    800048f8:	0080                	addi	s0,sp,64
    800048fa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048fc:	0001d517          	auipc	a0,0x1d
    80004900:	1ac50513          	addi	a0,a0,428 # 80021aa8 <ftable>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	2d2080e7          	jalr	722(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000490c:	40dc                	lw	a5,4(s1)
    8000490e:	06f05163          	blez	a5,80004970 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004912:	37fd                	addiw	a5,a5,-1
    80004914:	0007871b          	sext.w	a4,a5
    80004918:	c0dc                	sw	a5,4(s1)
    8000491a:	06e04363          	bgtz	a4,80004980 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000491e:	0004a903          	lw	s2,0(s1)
    80004922:	0094ca83          	lbu	s5,9(s1)
    80004926:	0104ba03          	ld	s4,16(s1)
    8000492a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000492e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004932:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004936:	0001d517          	auipc	a0,0x1d
    8000493a:	17250513          	addi	a0,a0,370 # 80021aa8 <ftable>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	34c080e7          	jalr	844(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004946:	4785                	li	a5,1
    80004948:	04f90d63          	beq	s2,a5,800049a2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000494c:	3979                	addiw	s2,s2,-2
    8000494e:	4785                	li	a5,1
    80004950:	0527e063          	bltu	a5,s2,80004990 <fileclose+0xa8>
    begin_op();
    80004954:	00000097          	auipc	ra,0x0
    80004958:	acc080e7          	jalr	-1332(ra) # 80004420 <begin_op>
    iput(ff.ip);
    8000495c:	854e                	mv	a0,s3
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	2b0080e7          	jalr	688(ra) # 80003c0e <iput>
    end_op();
    80004966:	00000097          	auipc	ra,0x0
    8000496a:	b38080e7          	jalr	-1224(ra) # 8000449e <end_op>
    8000496e:	a00d                	j	80004990 <fileclose+0xa8>
    panic("fileclose");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	d5050513          	addi	a0,a0,-688 # 800086c0 <syscalls+0x268>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bc8080e7          	jalr	-1080(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	12850513          	addi	a0,a0,296 # 80021aa8 <ftable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	302080e7          	jalr	770(ra) # 80000c8a <release>
  }
}
    80004990:	70e2                	ld	ra,56(sp)
    80004992:	7442                	ld	s0,48(sp)
    80004994:	74a2                	ld	s1,40(sp)
    80004996:	7902                	ld	s2,32(sp)
    80004998:	69e2                	ld	s3,24(sp)
    8000499a:	6a42                	ld	s4,16(sp)
    8000499c:	6aa2                	ld	s5,8(sp)
    8000499e:	6121                	addi	sp,sp,64
    800049a0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800049a2:	85d6                	mv	a1,s5
    800049a4:	8552                	mv	a0,s4
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	34c080e7          	jalr	844(ra) # 80004cf2 <pipeclose>
    800049ae:	b7cd                	j	80004990 <fileclose+0xa8>

00000000800049b0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800049b0:	715d                	addi	sp,sp,-80
    800049b2:	e486                	sd	ra,72(sp)
    800049b4:	e0a2                	sd	s0,64(sp)
    800049b6:	fc26                	sd	s1,56(sp)
    800049b8:	f84a                	sd	s2,48(sp)
    800049ba:	f44e                	sd	s3,40(sp)
    800049bc:	0880                	addi	s0,sp,80
    800049be:	84aa                	mv	s1,a0
    800049c0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800049c2:	ffffd097          	auipc	ra,0xffffd
    800049c6:	fea080e7          	jalr	-22(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800049ca:	409c                	lw	a5,0(s1)
    800049cc:	37f9                	addiw	a5,a5,-2
    800049ce:	4705                	li	a4,1
    800049d0:	04f76763          	bltu	a4,a5,80004a1e <filestat+0x6e>
    800049d4:	892a                	mv	s2,a0
    ilock(f->ip);
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	07c080e7          	jalr	124(ra) # 80003a54 <ilock>
    stati(f->ip, &st);
    800049e0:	fb840593          	addi	a1,s0,-72
    800049e4:	6c88                	ld	a0,24(s1)
    800049e6:	fffff097          	auipc	ra,0xfffff
    800049ea:	2f8080e7          	jalr	760(ra) # 80003cde <stati>
    iunlock(f->ip);
    800049ee:	6c88                	ld	a0,24(s1)
    800049f0:	fffff097          	auipc	ra,0xfffff
    800049f4:	126080e7          	jalr	294(ra) # 80003b16 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049f8:	46e1                	li	a3,24
    800049fa:	fb840613          	addi	a2,s0,-72
    800049fe:	85ce                	mv	a1,s3
    80004a00:	06893503          	ld	a0,104(s2)
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	c68080e7          	jalr	-920(ra) # 8000166c <copyout>
    80004a0c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a10:	60a6                	ld	ra,72(sp)
    80004a12:	6406                	ld	s0,64(sp)
    80004a14:	74e2                	ld	s1,56(sp)
    80004a16:	7942                	ld	s2,48(sp)
    80004a18:	79a2                	ld	s3,40(sp)
    80004a1a:	6161                	addi	sp,sp,80
    80004a1c:	8082                	ret
  return -1;
    80004a1e:	557d                	li	a0,-1
    80004a20:	bfc5                	j	80004a10 <filestat+0x60>

0000000080004a22 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a22:	7179                	addi	sp,sp,-48
    80004a24:	f406                	sd	ra,40(sp)
    80004a26:	f022                	sd	s0,32(sp)
    80004a28:	ec26                	sd	s1,24(sp)
    80004a2a:	e84a                	sd	s2,16(sp)
    80004a2c:	e44e                	sd	s3,8(sp)
    80004a2e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a30:	00854783          	lbu	a5,8(a0)
    80004a34:	c3d5                	beqz	a5,80004ad8 <fileread+0xb6>
    80004a36:	84aa                	mv	s1,a0
    80004a38:	89ae                	mv	s3,a1
    80004a3a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3c:	411c                	lw	a5,0(a0)
    80004a3e:	4705                	li	a4,1
    80004a40:	04e78963          	beq	a5,a4,80004a92 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a44:	470d                	li	a4,3
    80004a46:	04e78d63          	beq	a5,a4,80004aa0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a4a:	4709                	li	a4,2
    80004a4c:	06e79e63          	bne	a5,a4,80004ac8 <fileread+0xa6>
    ilock(f->ip);
    80004a50:	6d08                	ld	a0,24(a0)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	002080e7          	jalr	2(ra) # 80003a54 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a5a:	874a                	mv	a4,s2
    80004a5c:	5094                	lw	a3,32(s1)
    80004a5e:	864e                	mv	a2,s3
    80004a60:	4585                	li	a1,1
    80004a62:	6c88                	ld	a0,24(s1)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	2a4080e7          	jalr	676(ra) # 80003d08 <readi>
    80004a6c:	892a                	mv	s2,a0
    80004a6e:	00a05563          	blez	a0,80004a78 <fileread+0x56>
      f->off += r;
    80004a72:	509c                	lw	a5,32(s1)
    80004a74:	9fa9                	addw	a5,a5,a0
    80004a76:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a78:	6c88                	ld	a0,24(s1)
    80004a7a:	fffff097          	auipc	ra,0xfffff
    80004a7e:	09c080e7          	jalr	156(ra) # 80003b16 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a82:	854a                	mv	a0,s2
    80004a84:	70a2                	ld	ra,40(sp)
    80004a86:	7402                	ld	s0,32(sp)
    80004a88:	64e2                	ld	s1,24(sp)
    80004a8a:	6942                	ld	s2,16(sp)
    80004a8c:	69a2                	ld	s3,8(sp)
    80004a8e:	6145                	addi	sp,sp,48
    80004a90:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a92:	6908                	ld	a0,16(a0)
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	3c6080e7          	jalr	966(ra) # 80004e5a <piperead>
    80004a9c:	892a                	mv	s2,a0
    80004a9e:	b7d5                	j	80004a82 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004aa0:	02451783          	lh	a5,36(a0)
    80004aa4:	03079693          	slli	a3,a5,0x30
    80004aa8:	92c1                	srli	a3,a3,0x30
    80004aaa:	4725                	li	a4,9
    80004aac:	02d76863          	bltu	a4,a3,80004adc <fileread+0xba>
    80004ab0:	0792                	slli	a5,a5,0x4
    80004ab2:	0001d717          	auipc	a4,0x1d
    80004ab6:	f5670713          	addi	a4,a4,-170 # 80021a08 <devsw>
    80004aba:	97ba                	add	a5,a5,a4
    80004abc:	639c                	ld	a5,0(a5)
    80004abe:	c38d                	beqz	a5,80004ae0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ac0:	4505                	li	a0,1
    80004ac2:	9782                	jalr	a5
    80004ac4:	892a                	mv	s2,a0
    80004ac6:	bf75                	j	80004a82 <fileread+0x60>
    panic("fileread");
    80004ac8:	00004517          	auipc	a0,0x4
    80004acc:	c0850513          	addi	a0,a0,-1016 # 800086d0 <syscalls+0x278>
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	a70080e7          	jalr	-1424(ra) # 80000540 <panic>
    return -1;
    80004ad8:	597d                	li	s2,-1
    80004ada:	b765                	j	80004a82 <fileread+0x60>
      return -1;
    80004adc:	597d                	li	s2,-1
    80004ade:	b755                	j	80004a82 <fileread+0x60>
    80004ae0:	597d                	li	s2,-1
    80004ae2:	b745                	j	80004a82 <fileread+0x60>

0000000080004ae4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ae4:	715d                	addi	sp,sp,-80
    80004ae6:	e486                	sd	ra,72(sp)
    80004ae8:	e0a2                	sd	s0,64(sp)
    80004aea:	fc26                	sd	s1,56(sp)
    80004aec:	f84a                	sd	s2,48(sp)
    80004aee:	f44e                	sd	s3,40(sp)
    80004af0:	f052                	sd	s4,32(sp)
    80004af2:	ec56                	sd	s5,24(sp)
    80004af4:	e85a                	sd	s6,16(sp)
    80004af6:	e45e                	sd	s7,8(sp)
    80004af8:	e062                	sd	s8,0(sp)
    80004afa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004afc:	00954783          	lbu	a5,9(a0)
    80004b00:	10078663          	beqz	a5,80004c0c <filewrite+0x128>
    80004b04:	892a                	mv	s2,a0
    80004b06:	8b2e                	mv	s6,a1
    80004b08:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b0a:	411c                	lw	a5,0(a0)
    80004b0c:	4705                	li	a4,1
    80004b0e:	02e78263          	beq	a5,a4,80004b32 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b12:	470d                	li	a4,3
    80004b14:	02e78663          	beq	a5,a4,80004b40 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b18:	4709                	li	a4,2
    80004b1a:	0ee79163          	bne	a5,a4,80004bfc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b1e:	0ac05d63          	blez	a2,80004bd8 <filewrite+0xf4>
    int i = 0;
    80004b22:	4981                	li	s3,0
    80004b24:	6b85                	lui	s7,0x1
    80004b26:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004b2a:	6c05                	lui	s8,0x1
    80004b2c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004b30:	a861                	j	80004bc8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b32:	6908                	ld	a0,16(a0)
    80004b34:	00000097          	auipc	ra,0x0
    80004b38:	22e080e7          	jalr	558(ra) # 80004d62 <pipewrite>
    80004b3c:	8a2a                	mv	s4,a0
    80004b3e:	a045                	j	80004bde <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b40:	02451783          	lh	a5,36(a0)
    80004b44:	03079693          	slli	a3,a5,0x30
    80004b48:	92c1                	srli	a3,a3,0x30
    80004b4a:	4725                	li	a4,9
    80004b4c:	0cd76263          	bltu	a4,a3,80004c10 <filewrite+0x12c>
    80004b50:	0792                	slli	a5,a5,0x4
    80004b52:	0001d717          	auipc	a4,0x1d
    80004b56:	eb670713          	addi	a4,a4,-330 # 80021a08 <devsw>
    80004b5a:	97ba                	add	a5,a5,a4
    80004b5c:	679c                	ld	a5,8(a5)
    80004b5e:	cbdd                	beqz	a5,80004c14 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b60:	4505                	li	a0,1
    80004b62:	9782                	jalr	a5
    80004b64:	8a2a                	mv	s4,a0
    80004b66:	a8a5                	j	80004bde <filewrite+0xfa>
    80004b68:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b6c:	00000097          	auipc	ra,0x0
    80004b70:	8b4080e7          	jalr	-1868(ra) # 80004420 <begin_op>
      ilock(f->ip);
    80004b74:	01893503          	ld	a0,24(s2)
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	edc080e7          	jalr	-292(ra) # 80003a54 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b80:	8756                	mv	a4,s5
    80004b82:	02092683          	lw	a3,32(s2)
    80004b86:	01698633          	add	a2,s3,s6
    80004b8a:	4585                	li	a1,1
    80004b8c:	01893503          	ld	a0,24(s2)
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	270080e7          	jalr	624(ra) # 80003e00 <writei>
    80004b98:	84aa                	mv	s1,a0
    80004b9a:	00a05763          	blez	a0,80004ba8 <filewrite+0xc4>
        f->off += r;
    80004b9e:	02092783          	lw	a5,32(s2)
    80004ba2:	9fa9                	addw	a5,a5,a0
    80004ba4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ba8:	01893503          	ld	a0,24(s2)
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	f6a080e7          	jalr	-150(ra) # 80003b16 <iunlock>
      end_op();
    80004bb4:	00000097          	auipc	ra,0x0
    80004bb8:	8ea080e7          	jalr	-1814(ra) # 8000449e <end_op>

      if(r != n1){
    80004bbc:	009a9f63          	bne	s5,s1,80004bda <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004bc0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004bc4:	0149db63          	bge	s3,s4,80004bda <filewrite+0xf6>
      int n1 = n - i;
    80004bc8:	413a04bb          	subw	s1,s4,s3
    80004bcc:	0004879b          	sext.w	a5,s1
    80004bd0:	f8fbdce3          	bge	s7,a5,80004b68 <filewrite+0x84>
    80004bd4:	84e2                	mv	s1,s8
    80004bd6:	bf49                	j	80004b68 <filewrite+0x84>
    int i = 0;
    80004bd8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004bda:	013a1f63          	bne	s4,s3,80004bf8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004bde:	8552                	mv	a0,s4
    80004be0:	60a6                	ld	ra,72(sp)
    80004be2:	6406                	ld	s0,64(sp)
    80004be4:	74e2                	ld	s1,56(sp)
    80004be6:	7942                	ld	s2,48(sp)
    80004be8:	79a2                	ld	s3,40(sp)
    80004bea:	7a02                	ld	s4,32(sp)
    80004bec:	6ae2                	ld	s5,24(sp)
    80004bee:	6b42                	ld	s6,16(sp)
    80004bf0:	6ba2                	ld	s7,8(sp)
    80004bf2:	6c02                	ld	s8,0(sp)
    80004bf4:	6161                	addi	sp,sp,80
    80004bf6:	8082                	ret
    ret = (i == n ? n : -1);
    80004bf8:	5a7d                	li	s4,-1
    80004bfa:	b7d5                	j	80004bde <filewrite+0xfa>
    panic("filewrite");
    80004bfc:	00004517          	auipc	a0,0x4
    80004c00:	ae450513          	addi	a0,a0,-1308 # 800086e0 <syscalls+0x288>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	93c080e7          	jalr	-1732(ra) # 80000540 <panic>
    return -1;
    80004c0c:	5a7d                	li	s4,-1
    80004c0e:	bfc1                	j	80004bde <filewrite+0xfa>
      return -1;
    80004c10:	5a7d                	li	s4,-1
    80004c12:	b7f1                	j	80004bde <filewrite+0xfa>
    80004c14:	5a7d                	li	s4,-1
    80004c16:	b7e1                	j	80004bde <filewrite+0xfa>

0000000080004c18 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c18:	7179                	addi	sp,sp,-48
    80004c1a:	f406                	sd	ra,40(sp)
    80004c1c:	f022                	sd	s0,32(sp)
    80004c1e:	ec26                	sd	s1,24(sp)
    80004c20:	e84a                	sd	s2,16(sp)
    80004c22:	e44e                	sd	s3,8(sp)
    80004c24:	e052                	sd	s4,0(sp)
    80004c26:	1800                	addi	s0,sp,48
    80004c28:	84aa                	mv	s1,a0
    80004c2a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c2c:	0005b023          	sd	zero,0(a1)
    80004c30:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c34:	00000097          	auipc	ra,0x0
    80004c38:	bf8080e7          	jalr	-1032(ra) # 8000482c <filealloc>
    80004c3c:	e088                	sd	a0,0(s1)
    80004c3e:	c551                	beqz	a0,80004cca <pipealloc+0xb2>
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	bec080e7          	jalr	-1044(ra) # 8000482c <filealloc>
    80004c48:	00aa3023          	sd	a0,0(s4)
    80004c4c:	c92d                	beqz	a0,80004cbe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	e98080e7          	jalr	-360(ra) # 80000ae6 <kalloc>
    80004c56:	892a                	mv	s2,a0
    80004c58:	c125                	beqz	a0,80004cb8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c5a:	4985                	li	s3,1
    80004c5c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c60:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c64:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c68:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c6c:	00004597          	auipc	a1,0x4
    80004c70:	a8458593          	addi	a1,a1,-1404 # 800086f0 <syscalls+0x298>
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	ed2080e7          	jalr	-302(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004c7c:	609c                	ld	a5,0(s1)
    80004c7e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c82:	609c                	ld	a5,0(s1)
    80004c84:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c88:	609c                	ld	a5,0(s1)
    80004c8a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c8e:	609c                	ld	a5,0(s1)
    80004c90:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c94:	000a3783          	ld	a5,0(s4)
    80004c98:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c9c:	000a3783          	ld	a5,0(s4)
    80004ca0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ca4:	000a3783          	ld	a5,0(s4)
    80004ca8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004cac:	000a3783          	ld	a5,0(s4)
    80004cb0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004cb4:	4501                	li	a0,0
    80004cb6:	a025                	j	80004cde <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004cb8:	6088                	ld	a0,0(s1)
    80004cba:	e501                	bnez	a0,80004cc2 <pipealloc+0xaa>
    80004cbc:	a039                	j	80004cca <pipealloc+0xb2>
    80004cbe:	6088                	ld	a0,0(s1)
    80004cc0:	c51d                	beqz	a0,80004cee <pipealloc+0xd6>
    fileclose(*f0);
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	c26080e7          	jalr	-986(ra) # 800048e8 <fileclose>
  if(*f1)
    80004cca:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004cce:	557d                	li	a0,-1
  if(*f1)
    80004cd0:	c799                	beqz	a5,80004cde <pipealloc+0xc6>
    fileclose(*f1);
    80004cd2:	853e                	mv	a0,a5
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	c14080e7          	jalr	-1004(ra) # 800048e8 <fileclose>
  return -1;
    80004cdc:	557d                	li	a0,-1
}
    80004cde:	70a2                	ld	ra,40(sp)
    80004ce0:	7402                	ld	s0,32(sp)
    80004ce2:	64e2                	ld	s1,24(sp)
    80004ce4:	6942                	ld	s2,16(sp)
    80004ce6:	69a2                	ld	s3,8(sp)
    80004ce8:	6a02                	ld	s4,0(sp)
    80004cea:	6145                	addi	sp,sp,48
    80004cec:	8082                	ret
  return -1;
    80004cee:	557d                	li	a0,-1
    80004cf0:	b7fd                	j	80004cde <pipealloc+0xc6>

0000000080004cf2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cf2:	1101                	addi	sp,sp,-32
    80004cf4:	ec06                	sd	ra,24(sp)
    80004cf6:	e822                	sd	s0,16(sp)
    80004cf8:	e426                	sd	s1,8(sp)
    80004cfa:	e04a                	sd	s2,0(sp)
    80004cfc:	1000                	addi	s0,sp,32
    80004cfe:	84aa                	mv	s1,a0
    80004d00:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d02:	ffffc097          	auipc	ra,0xffffc
    80004d06:	ed4080e7          	jalr	-300(ra) # 80000bd6 <acquire>
  if(writable){
    80004d0a:	02090d63          	beqz	s2,80004d44 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d0e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d12:	21848513          	addi	a0,s1,536
    80004d16:	ffffd097          	auipc	ra,0xffffd
    80004d1a:	43c080e7          	jalr	1084(ra) # 80002152 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d1e:	2204b783          	ld	a5,544(s1)
    80004d22:	eb95                	bnez	a5,80004d56 <pipeclose+0x64>
    release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f64080e7          	jalr	-156(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	cb8080e7          	jalr	-840(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004d38:	60e2                	ld	ra,24(sp)
    80004d3a:	6442                	ld	s0,16(sp)
    80004d3c:	64a2                	ld	s1,8(sp)
    80004d3e:	6902                	ld	s2,0(sp)
    80004d40:	6105                	addi	sp,sp,32
    80004d42:	8082                	ret
    pi->readopen = 0;
    80004d44:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d48:	21c48513          	addi	a0,s1,540
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	406080e7          	jalr	1030(ra) # 80002152 <wakeup>
    80004d54:	b7e9                	j	80004d1e <pipeclose+0x2c>
    release(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	f32080e7          	jalr	-206(ra) # 80000c8a <release>
}
    80004d60:	bfe1                	j	80004d38 <pipeclose+0x46>

0000000080004d62 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d62:	711d                	addi	sp,sp,-96
    80004d64:	ec86                	sd	ra,88(sp)
    80004d66:	e8a2                	sd	s0,80(sp)
    80004d68:	e4a6                	sd	s1,72(sp)
    80004d6a:	e0ca                	sd	s2,64(sp)
    80004d6c:	fc4e                	sd	s3,56(sp)
    80004d6e:	f852                	sd	s4,48(sp)
    80004d70:	f456                	sd	s5,40(sp)
    80004d72:	f05a                	sd	s6,32(sp)
    80004d74:	ec5e                	sd	s7,24(sp)
    80004d76:	e862                	sd	s8,16(sp)
    80004d78:	1080                	addi	s0,sp,96
    80004d7a:	84aa                	mv	s1,a0
    80004d7c:	8aae                	mv	s5,a1
    80004d7e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d80:	ffffd097          	auipc	ra,0xffffd
    80004d84:	c2c080e7          	jalr	-980(ra) # 800019ac <myproc>
    80004d88:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d8a:	8526                	mv	a0,s1
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	e4a080e7          	jalr	-438(ra) # 80000bd6 <acquire>
  while(i < n){
    80004d94:	0b405663          	blez	s4,80004e40 <pipewrite+0xde>
  int i = 0;
    80004d98:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d9a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d9c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004da0:	21c48b93          	addi	s7,s1,540
    80004da4:	a089                	j	80004de6 <pipewrite+0x84>
      release(&pi->lock);
    80004da6:	8526                	mv	a0,s1
    80004da8:	ffffc097          	auipc	ra,0xffffc
    80004dac:	ee2080e7          	jalr	-286(ra) # 80000c8a <release>
      return -1;
    80004db0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004db2:	854a                	mv	a0,s2
    80004db4:	60e6                	ld	ra,88(sp)
    80004db6:	6446                	ld	s0,80(sp)
    80004db8:	64a6                	ld	s1,72(sp)
    80004dba:	6906                	ld	s2,64(sp)
    80004dbc:	79e2                	ld	s3,56(sp)
    80004dbe:	7a42                	ld	s4,48(sp)
    80004dc0:	7aa2                	ld	s5,40(sp)
    80004dc2:	7b02                	ld	s6,32(sp)
    80004dc4:	6be2                	ld	s7,24(sp)
    80004dc6:	6c42                	ld	s8,16(sp)
    80004dc8:	6125                	addi	sp,sp,96
    80004dca:	8082                	ret
      wakeup(&pi->nread);
    80004dcc:	8562                	mv	a0,s8
    80004dce:	ffffd097          	auipc	ra,0xffffd
    80004dd2:	384080e7          	jalr	900(ra) # 80002152 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dd6:	85a6                	mv	a1,s1
    80004dd8:	855e                	mv	a0,s7
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	314080e7          	jalr	788(ra) # 800020ee <sleep>
  while(i < n){
    80004de2:	07495063          	bge	s2,s4,80004e42 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004de6:	2204a783          	lw	a5,544(s1)
    80004dea:	dfd5                	beqz	a5,80004da6 <pipewrite+0x44>
    80004dec:	854e                	mv	a0,s3
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	5b4080e7          	jalr	1460(ra) # 800023a2 <killed>
    80004df6:	f945                	bnez	a0,80004da6 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004df8:	2184a783          	lw	a5,536(s1)
    80004dfc:	21c4a703          	lw	a4,540(s1)
    80004e00:	2007879b          	addiw	a5,a5,512
    80004e04:	fcf704e3          	beq	a4,a5,80004dcc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e08:	4685                	li	a3,1
    80004e0a:	01590633          	add	a2,s2,s5
    80004e0e:	faf40593          	addi	a1,s0,-81
    80004e12:	0689b503          	ld	a0,104(s3)
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	8e2080e7          	jalr	-1822(ra) # 800016f8 <copyin>
    80004e1e:	03650263          	beq	a0,s6,80004e42 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e22:	21c4a783          	lw	a5,540(s1)
    80004e26:	0017871b          	addiw	a4,a5,1
    80004e2a:	20e4ae23          	sw	a4,540(s1)
    80004e2e:	1ff7f793          	andi	a5,a5,511
    80004e32:	97a6                	add	a5,a5,s1
    80004e34:	faf44703          	lbu	a4,-81(s0)
    80004e38:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e3c:	2905                	addiw	s2,s2,1
    80004e3e:	b755                	j	80004de2 <pipewrite+0x80>
  int i = 0;
    80004e40:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e42:	21848513          	addi	a0,s1,536
    80004e46:	ffffd097          	auipc	ra,0xffffd
    80004e4a:	30c080e7          	jalr	780(ra) # 80002152 <wakeup>
  release(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	e3a080e7          	jalr	-454(ra) # 80000c8a <release>
  return i;
    80004e58:	bfa9                	j	80004db2 <pipewrite+0x50>

0000000080004e5a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e5a:	715d                	addi	sp,sp,-80
    80004e5c:	e486                	sd	ra,72(sp)
    80004e5e:	e0a2                	sd	s0,64(sp)
    80004e60:	fc26                	sd	s1,56(sp)
    80004e62:	f84a                	sd	s2,48(sp)
    80004e64:	f44e                	sd	s3,40(sp)
    80004e66:	f052                	sd	s4,32(sp)
    80004e68:	ec56                	sd	s5,24(sp)
    80004e6a:	e85a                	sd	s6,16(sp)
    80004e6c:	0880                	addi	s0,sp,80
    80004e6e:	84aa                	mv	s1,a0
    80004e70:	892e                	mv	s2,a1
    80004e72:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e74:	ffffd097          	auipc	ra,0xffffd
    80004e78:	b38080e7          	jalr	-1224(ra) # 800019ac <myproc>
    80004e7c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	d56080e7          	jalr	-682(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e88:	2184a703          	lw	a4,536(s1)
    80004e8c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e90:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e94:	02f71763          	bne	a4,a5,80004ec2 <piperead+0x68>
    80004e98:	2244a783          	lw	a5,548(s1)
    80004e9c:	c39d                	beqz	a5,80004ec2 <piperead+0x68>
    if(killed(pr)){
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	ffffd097          	auipc	ra,0xffffd
    80004ea4:	502080e7          	jalr	1282(ra) # 800023a2 <killed>
    80004ea8:	e949                	bnez	a0,80004f3a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eaa:	85a6                	mv	a1,s1
    80004eac:	854e                	mv	a0,s3
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	240080e7          	jalr	576(ra) # 800020ee <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eb6:	2184a703          	lw	a4,536(s1)
    80004eba:	21c4a783          	lw	a5,540(s1)
    80004ebe:	fcf70de3          	beq	a4,a5,80004e98 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ec4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec6:	05505463          	blez	s5,80004f0e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004eca:	2184a783          	lw	a5,536(s1)
    80004ece:	21c4a703          	lw	a4,540(s1)
    80004ed2:	02f70e63          	beq	a4,a5,80004f0e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ed6:	0017871b          	addiw	a4,a5,1
    80004eda:	20e4ac23          	sw	a4,536(s1)
    80004ede:	1ff7f793          	andi	a5,a5,511
    80004ee2:	97a6                	add	a5,a5,s1
    80004ee4:	0187c783          	lbu	a5,24(a5)
    80004ee8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004eec:	4685                	li	a3,1
    80004eee:	fbf40613          	addi	a2,s0,-65
    80004ef2:	85ca                	mv	a1,s2
    80004ef4:	068a3503          	ld	a0,104(s4)
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	774080e7          	jalr	1908(ra) # 8000166c <copyout>
    80004f00:	01650763          	beq	a0,s6,80004f0e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f04:	2985                	addiw	s3,s3,1
    80004f06:	0905                	addi	s2,s2,1
    80004f08:	fd3a91e3          	bne	s5,s3,80004eca <piperead+0x70>
    80004f0c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f0e:	21c48513          	addi	a0,s1,540
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	240080e7          	jalr	576(ra) # 80002152 <wakeup>
  release(&pi->lock);
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	ffffc097          	auipc	ra,0xffffc
    80004f20:	d6e080e7          	jalr	-658(ra) # 80000c8a <release>
  return i;
}
    80004f24:	854e                	mv	a0,s3
    80004f26:	60a6                	ld	ra,72(sp)
    80004f28:	6406                	ld	s0,64(sp)
    80004f2a:	74e2                	ld	s1,56(sp)
    80004f2c:	7942                	ld	s2,48(sp)
    80004f2e:	79a2                	ld	s3,40(sp)
    80004f30:	7a02                	ld	s4,32(sp)
    80004f32:	6ae2                	ld	s5,24(sp)
    80004f34:	6b42                	ld	s6,16(sp)
    80004f36:	6161                	addi	sp,sp,80
    80004f38:	8082                	ret
      release(&pi->lock);
    80004f3a:	8526                	mv	a0,s1
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	d4e080e7          	jalr	-690(ra) # 80000c8a <release>
      return -1;
    80004f44:	59fd                	li	s3,-1
    80004f46:	bff9                	j	80004f24 <piperead+0xca>

0000000080004f48 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004f48:	1141                	addi	sp,sp,-16
    80004f4a:	e422                	sd	s0,8(sp)
    80004f4c:	0800                	addi	s0,sp,16
    80004f4e:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004f50:	8905                	andi	a0,a0,1
    80004f52:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004f54:	8b89                	andi	a5,a5,2
    80004f56:	c399                	beqz	a5,80004f5c <flags2perm+0x14>
      perm |= PTE_W;
    80004f58:	00456513          	ori	a0,a0,4
    return perm;
}
    80004f5c:	6422                	ld	s0,8(sp)
    80004f5e:	0141                	addi	sp,sp,16
    80004f60:	8082                	ret

0000000080004f62 <exec>:

int
exec(char *path, char **argv)
{
    80004f62:	de010113          	addi	sp,sp,-544
    80004f66:	20113c23          	sd	ra,536(sp)
    80004f6a:	20813823          	sd	s0,528(sp)
    80004f6e:	20913423          	sd	s1,520(sp)
    80004f72:	21213023          	sd	s2,512(sp)
    80004f76:	ffce                	sd	s3,504(sp)
    80004f78:	fbd2                	sd	s4,496(sp)
    80004f7a:	f7d6                	sd	s5,488(sp)
    80004f7c:	f3da                	sd	s6,480(sp)
    80004f7e:	efde                	sd	s7,472(sp)
    80004f80:	ebe2                	sd	s8,464(sp)
    80004f82:	e7e6                	sd	s9,456(sp)
    80004f84:	e3ea                	sd	s10,448(sp)
    80004f86:	ff6e                	sd	s11,440(sp)
    80004f88:	1400                	addi	s0,sp,544
    80004f8a:	892a                	mv	s2,a0
    80004f8c:	dea43423          	sd	a0,-536(s0)
    80004f90:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	a18080e7          	jalr	-1512(ra) # 800019ac <myproc>
    80004f9c:	84aa                	mv	s1,a0

  begin_op();
    80004f9e:	fffff097          	auipc	ra,0xfffff
    80004fa2:	482080e7          	jalr	1154(ra) # 80004420 <begin_op>

  if((ip = namei(path)) == 0){
    80004fa6:	854a                	mv	a0,s2
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	258080e7          	jalr	600(ra) # 80004200 <namei>
    80004fb0:	c93d                	beqz	a0,80005026 <exec+0xc4>
    80004fb2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fb4:	fffff097          	auipc	ra,0xfffff
    80004fb8:	aa0080e7          	jalr	-1376(ra) # 80003a54 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fbc:	04000713          	li	a4,64
    80004fc0:	4681                	li	a3,0
    80004fc2:	e5040613          	addi	a2,s0,-432
    80004fc6:	4581                	li	a1,0
    80004fc8:	8556                	mv	a0,s5
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	d3e080e7          	jalr	-706(ra) # 80003d08 <readi>
    80004fd2:	04000793          	li	a5,64
    80004fd6:	00f51a63          	bne	a0,a5,80004fea <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004fda:	e5042703          	lw	a4,-432(s0)
    80004fde:	464c47b7          	lui	a5,0x464c4
    80004fe2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fe6:	04f70663          	beq	a4,a5,80005032 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fea:	8556                	mv	a0,s5
    80004fec:	fffff097          	auipc	ra,0xfffff
    80004ff0:	cca080e7          	jalr	-822(ra) # 80003cb6 <iunlockput>
    end_op();
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	4aa080e7          	jalr	1194(ra) # 8000449e <end_op>
  }
  return -1;
    80004ffc:	557d                	li	a0,-1
}
    80004ffe:	21813083          	ld	ra,536(sp)
    80005002:	21013403          	ld	s0,528(sp)
    80005006:	20813483          	ld	s1,520(sp)
    8000500a:	20013903          	ld	s2,512(sp)
    8000500e:	79fe                	ld	s3,504(sp)
    80005010:	7a5e                	ld	s4,496(sp)
    80005012:	7abe                	ld	s5,488(sp)
    80005014:	7b1e                	ld	s6,480(sp)
    80005016:	6bfe                	ld	s7,472(sp)
    80005018:	6c5e                	ld	s8,464(sp)
    8000501a:	6cbe                	ld	s9,456(sp)
    8000501c:	6d1e                	ld	s10,448(sp)
    8000501e:	7dfa                	ld	s11,440(sp)
    80005020:	22010113          	addi	sp,sp,544
    80005024:	8082                	ret
    end_op();
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	478080e7          	jalr	1144(ra) # 8000449e <end_op>
    return -1;
    8000502e:	557d                	li	a0,-1
    80005030:	b7f9                	j	80004ffe <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005032:	8526                	mv	a0,s1
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	a3c080e7          	jalr	-1476(ra) # 80001a70 <proc_pagetable>
    8000503c:	8b2a                	mv	s6,a0
    8000503e:	d555                	beqz	a0,80004fea <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005040:	e7042783          	lw	a5,-400(s0)
    80005044:	e8845703          	lhu	a4,-376(s0)
    80005048:	c735                	beqz	a4,800050b4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000504a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005050:	6a05                	lui	s4,0x1
    80005052:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005056:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    8000505a:	6d85                	lui	s11,0x1
    8000505c:	7d7d                	lui	s10,0xfffff
    8000505e:	ac3d                	j	8000529c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005060:	00003517          	auipc	a0,0x3
    80005064:	69850513          	addi	a0,a0,1688 # 800086f8 <syscalls+0x2a0>
    80005068:	ffffb097          	auipc	ra,0xffffb
    8000506c:	4d8080e7          	jalr	1240(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005070:	874a                	mv	a4,s2
    80005072:	009c86bb          	addw	a3,s9,s1
    80005076:	4581                	li	a1,0
    80005078:	8556                	mv	a0,s5
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	c8e080e7          	jalr	-882(ra) # 80003d08 <readi>
    80005082:	2501                	sext.w	a0,a0
    80005084:	1aa91963          	bne	s2,a0,80005236 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005088:	009d84bb          	addw	s1,s11,s1
    8000508c:	013d09bb          	addw	s3,s10,s3
    80005090:	1f74f663          	bgeu	s1,s7,8000527c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005094:	02049593          	slli	a1,s1,0x20
    80005098:	9181                	srli	a1,a1,0x20
    8000509a:	95e2                	add	a1,a1,s8
    8000509c:	855a                	mv	a0,s6
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	fbe080e7          	jalr	-66(ra) # 8000105c <walkaddr>
    800050a6:	862a                	mv	a2,a0
    if(pa == 0)
    800050a8:	dd45                	beqz	a0,80005060 <exec+0xfe>
      n = PGSIZE;
    800050aa:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050ac:	fd49f2e3          	bgeu	s3,s4,80005070 <exec+0x10e>
      n = sz - i;
    800050b0:	894e                	mv	s2,s3
    800050b2:	bf7d                	j	80005070 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050b4:	4901                	li	s2,0
  iunlockput(ip);
    800050b6:	8556                	mv	a0,s5
    800050b8:	fffff097          	auipc	ra,0xfffff
    800050bc:	bfe080e7          	jalr	-1026(ra) # 80003cb6 <iunlockput>
  end_op();
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	3de080e7          	jalr	990(ra) # 8000449e <end_op>
  p = myproc();
    800050c8:	ffffd097          	auipc	ra,0xffffd
    800050cc:	8e4080e7          	jalr	-1820(ra) # 800019ac <myproc>
    800050d0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050d2:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    800050d6:	6785                	lui	a5,0x1
    800050d8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800050da:	97ca                	add	a5,a5,s2
    800050dc:	777d                	lui	a4,0xfffff
    800050de:	8ff9                	and	a5,a5,a4
    800050e0:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050e4:	4691                	li	a3,4
    800050e6:	6609                	lui	a2,0x2
    800050e8:	963e                	add	a2,a2,a5
    800050ea:	85be                	mv	a1,a5
    800050ec:	855a                	mv	a0,s6
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	322080e7          	jalr	802(ra) # 80001410 <uvmalloc>
    800050f6:	8c2a                	mv	s8,a0
  ip = 0;
    800050f8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800050fa:	12050e63          	beqz	a0,80005236 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050fe:	75f9                	lui	a1,0xffffe
    80005100:	95aa                	add	a1,a1,a0
    80005102:	855a                	mv	a0,s6
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	536080e7          	jalr	1334(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    8000510c:	7afd                	lui	s5,0xfffff
    8000510e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005110:	df043783          	ld	a5,-528(s0)
    80005114:	6388                	ld	a0,0(a5)
    80005116:	c925                	beqz	a0,80005186 <exec+0x224>
    80005118:	e9040993          	addi	s3,s0,-368
    8000511c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005120:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005122:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	d2a080e7          	jalr	-726(ra) # 80000e4e <strlen>
    8000512c:	0015079b          	addiw	a5,a0,1
    80005130:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005134:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005138:	13596663          	bltu	s2,s5,80005264 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000513c:	df043d83          	ld	s11,-528(s0)
    80005140:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005144:	8552                	mv	a0,s4
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	d08080e7          	jalr	-760(ra) # 80000e4e <strlen>
    8000514e:	0015069b          	addiw	a3,a0,1
    80005152:	8652                	mv	a2,s4
    80005154:	85ca                	mv	a1,s2
    80005156:	855a                	mv	a0,s6
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	514080e7          	jalr	1300(ra) # 8000166c <copyout>
    80005160:	10054663          	bltz	a0,8000526c <exec+0x30a>
    ustack[argc] = sp;
    80005164:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005168:	0485                	addi	s1,s1,1
    8000516a:	008d8793          	addi	a5,s11,8
    8000516e:	def43823          	sd	a5,-528(s0)
    80005172:	008db503          	ld	a0,8(s11)
    80005176:	c911                	beqz	a0,8000518a <exec+0x228>
    if(argc >= MAXARG)
    80005178:	09a1                	addi	s3,s3,8
    8000517a:	fb3c95e3          	bne	s9,s3,80005124 <exec+0x1c2>
  sz = sz1;
    8000517e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005182:	4a81                	li	s5,0
    80005184:	a84d                	j	80005236 <exec+0x2d4>
  sp = sz;
    80005186:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005188:	4481                	li	s1,0
  ustack[argc] = 0;
    8000518a:	00349793          	slli	a5,s1,0x3
    8000518e:	f9078793          	addi	a5,a5,-112
    80005192:	97a2                	add	a5,a5,s0
    80005194:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005198:	00148693          	addi	a3,s1,1
    8000519c:	068e                	slli	a3,a3,0x3
    8000519e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051a2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051a6:	01597663          	bgeu	s2,s5,800051b2 <exec+0x250>
  sz = sz1;
    800051aa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ae:	4a81                	li	s5,0
    800051b0:	a059                	j	80005236 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051b2:	e9040613          	addi	a2,s0,-368
    800051b6:	85ca                	mv	a1,s2
    800051b8:	855a                	mv	a0,s6
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	4b2080e7          	jalr	1202(ra) # 8000166c <copyout>
    800051c2:	0a054963          	bltz	a0,80005274 <exec+0x312>
  p->trapframe->a1 = sp;
    800051c6:	070bb783          	ld	a5,112(s7)
    800051ca:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051ce:	de843783          	ld	a5,-536(s0)
    800051d2:	0007c703          	lbu	a4,0(a5)
    800051d6:	cf11                	beqz	a4,800051f2 <exec+0x290>
    800051d8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051da:	02f00693          	li	a3,47
    800051de:	a039                	j	800051ec <exec+0x28a>
      last = s+1;
    800051e0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051e4:	0785                	addi	a5,a5,1
    800051e6:	fff7c703          	lbu	a4,-1(a5)
    800051ea:	c701                	beqz	a4,800051f2 <exec+0x290>
    if(*s == '/')
    800051ec:	fed71ce3          	bne	a4,a3,800051e4 <exec+0x282>
    800051f0:	bfc5                	j	800051e0 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800051f2:	4641                	li	a2,16
    800051f4:	de843583          	ld	a1,-536(s0)
    800051f8:	170b8513          	addi	a0,s7,368
    800051fc:	ffffc097          	auipc	ra,0xffffc
    80005200:	c20080e7          	jalr	-992(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005204:	068bb503          	ld	a0,104(s7)
  p->pagetable = pagetable;
    80005208:	076bb423          	sd	s6,104(s7)
  p->sz = sz;
    8000520c:	078bb023          	sd	s8,96(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005210:	070bb783          	ld	a5,112(s7)
    80005214:	e6843703          	ld	a4,-408(s0)
    80005218:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000521a:	070bb783          	ld	a5,112(s7)
    8000521e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005222:	85ea                	mv	a1,s10
    80005224:	ffffd097          	auipc	ra,0xffffd
    80005228:	8e8080e7          	jalr	-1816(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000522c:	0004851b          	sext.w	a0,s1
    80005230:	b3f9                	j	80004ffe <exec+0x9c>
    80005232:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005236:	df843583          	ld	a1,-520(s0)
    8000523a:	855a                	mv	a0,s6
    8000523c:	ffffd097          	auipc	ra,0xffffd
    80005240:	8d0080e7          	jalr	-1840(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005244:	da0a93e3          	bnez	s5,80004fea <exec+0x88>
  return -1;
    80005248:	557d                	li	a0,-1
    8000524a:	bb55                	j	80004ffe <exec+0x9c>
    8000524c:	df243c23          	sd	s2,-520(s0)
    80005250:	b7dd                	j	80005236 <exec+0x2d4>
    80005252:	df243c23          	sd	s2,-520(s0)
    80005256:	b7c5                	j	80005236 <exec+0x2d4>
    80005258:	df243c23          	sd	s2,-520(s0)
    8000525c:	bfe9                	j	80005236 <exec+0x2d4>
    8000525e:	df243c23          	sd	s2,-520(s0)
    80005262:	bfd1                	j	80005236 <exec+0x2d4>
  sz = sz1;
    80005264:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005268:	4a81                	li	s5,0
    8000526a:	b7f1                	j	80005236 <exec+0x2d4>
  sz = sz1;
    8000526c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005270:	4a81                	li	s5,0
    80005272:	b7d1                	j	80005236 <exec+0x2d4>
  sz = sz1;
    80005274:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005278:	4a81                	li	s5,0
    8000527a:	bf75                	j	80005236 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000527c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005280:	e0843783          	ld	a5,-504(s0)
    80005284:	0017869b          	addiw	a3,a5,1
    80005288:	e0d43423          	sd	a3,-504(s0)
    8000528c:	e0043783          	ld	a5,-512(s0)
    80005290:	0387879b          	addiw	a5,a5,56
    80005294:	e8845703          	lhu	a4,-376(s0)
    80005298:	e0e6dfe3          	bge	a3,a4,800050b6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000529c:	2781                	sext.w	a5,a5
    8000529e:	e0f43023          	sd	a5,-512(s0)
    800052a2:	03800713          	li	a4,56
    800052a6:	86be                	mv	a3,a5
    800052a8:	e1840613          	addi	a2,s0,-488
    800052ac:	4581                	li	a1,0
    800052ae:	8556                	mv	a0,s5
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	a58080e7          	jalr	-1448(ra) # 80003d08 <readi>
    800052b8:	03800793          	li	a5,56
    800052bc:	f6f51be3          	bne	a0,a5,80005232 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800052c0:	e1842783          	lw	a5,-488(s0)
    800052c4:	4705                	li	a4,1
    800052c6:	fae79de3          	bne	a5,a4,80005280 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800052ca:	e4043483          	ld	s1,-448(s0)
    800052ce:	e3843783          	ld	a5,-456(s0)
    800052d2:	f6f4ede3          	bltu	s1,a5,8000524c <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052d6:	e2843783          	ld	a5,-472(s0)
    800052da:	94be                	add	s1,s1,a5
    800052dc:	f6f4ebe3          	bltu	s1,a5,80005252 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800052e0:	de043703          	ld	a4,-544(s0)
    800052e4:	8ff9                	and	a5,a5,a4
    800052e6:	fbad                	bnez	a5,80005258 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e8:	e1c42503          	lw	a0,-484(s0)
    800052ec:	00000097          	auipc	ra,0x0
    800052f0:	c5c080e7          	jalr	-932(ra) # 80004f48 <flags2perm>
    800052f4:	86aa                	mv	a3,a0
    800052f6:	8626                	mv	a2,s1
    800052f8:	85ca                	mv	a1,s2
    800052fa:	855a                	mv	a0,s6
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	114080e7          	jalr	276(ra) # 80001410 <uvmalloc>
    80005304:	dea43c23          	sd	a0,-520(s0)
    80005308:	d939                	beqz	a0,8000525e <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000530a:	e2843c03          	ld	s8,-472(s0)
    8000530e:	e2042c83          	lw	s9,-480(s0)
    80005312:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005316:	f60b83e3          	beqz	s7,8000527c <exec+0x31a>
    8000531a:	89de                	mv	s3,s7
    8000531c:	4481                	li	s1,0
    8000531e:	bb9d                	j	80005094 <exec+0x132>

0000000080005320 <argfd>:
int sum = 0;
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005320:	7179                	addi	sp,sp,-48
    80005322:	f406                	sd	ra,40(sp)
    80005324:	f022                	sd	s0,32(sp)
    80005326:	ec26                	sd	s1,24(sp)
    80005328:	e84a                	sd	s2,16(sp)
    8000532a:	1800                	addi	s0,sp,48
    8000532c:	892e                	mv	s2,a1
    8000532e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005330:	fdc40593          	addi	a1,s0,-36
    80005334:	ffffe097          	auipc	ra,0xffffe
    80005338:	a92080e7          	jalr	-1390(ra) # 80002dc6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000533c:	fdc42703          	lw	a4,-36(s0)
    80005340:	47bd                	li	a5,15
    80005342:	02e7eb63          	bltu	a5,a4,80005378 <argfd+0x58>
    80005346:	ffffc097          	auipc	ra,0xffffc
    8000534a:	666080e7          	jalr	1638(ra) # 800019ac <myproc>
    8000534e:	fdc42703          	lw	a4,-36(s0)
    80005352:	01c70793          	addi	a5,a4,28 # fffffffffffff01c <end+0xffffffff7ffdc47c>
    80005356:	078e                	slli	a5,a5,0x3
    80005358:	953e                	add	a0,a0,a5
    8000535a:	651c                	ld	a5,8(a0)
    8000535c:	c385                	beqz	a5,8000537c <argfd+0x5c>
    return -1;
  if(pfd)
    8000535e:	00090463          	beqz	s2,80005366 <argfd+0x46>
    *pfd = fd;
    80005362:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005366:	4501                	li	a0,0
  if(pf)
    80005368:	c091                	beqz	s1,8000536c <argfd+0x4c>
    *pf = f;
    8000536a:	e09c                	sd	a5,0(s1)
}
    8000536c:	70a2                	ld	ra,40(sp)
    8000536e:	7402                	ld	s0,32(sp)
    80005370:	64e2                	ld	s1,24(sp)
    80005372:	6942                	ld	s2,16(sp)
    80005374:	6145                	addi	sp,sp,48
    80005376:	8082                	ret
    return -1;
    80005378:	557d                	li	a0,-1
    8000537a:	bfcd                	j	8000536c <argfd+0x4c>
    8000537c:	557d                	li	a0,-1
    8000537e:	b7fd                	j	8000536c <argfd+0x4c>

0000000080005380 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005380:	1101                	addi	sp,sp,-32
    80005382:	ec06                	sd	ra,24(sp)
    80005384:	e822                	sd	s0,16(sp)
    80005386:	e426                	sd	s1,8(sp)
    80005388:	1000                	addi	s0,sp,32
    8000538a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000538c:	ffffc097          	auipc	ra,0xffffc
    80005390:	620080e7          	jalr	1568(ra) # 800019ac <myproc>
    80005394:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005396:	0e850793          	addi	a5,a0,232
    8000539a:	4501                	li	a0,0
    8000539c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000539e:	6398                	ld	a4,0(a5)
    800053a0:	cb19                	beqz	a4,800053b6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053a2:	2505                	addiw	a0,a0,1
    800053a4:	07a1                	addi	a5,a5,8
    800053a6:	fed51ce3          	bne	a0,a3,8000539e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053aa:	557d                	li	a0,-1
}
    800053ac:	60e2                	ld	ra,24(sp)
    800053ae:	6442                	ld	s0,16(sp)
    800053b0:	64a2                	ld	s1,8(sp)
    800053b2:	6105                	addi	sp,sp,32
    800053b4:	8082                	ret
      p->ofile[fd] = f;
    800053b6:	01c50793          	addi	a5,a0,28
    800053ba:	078e                	slli	a5,a5,0x3
    800053bc:	963e                	add	a2,a2,a5
    800053be:	e604                	sd	s1,8(a2)
      return fd;
    800053c0:	b7f5                	j	800053ac <fdalloc+0x2c>

00000000800053c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053c2:	715d                	addi	sp,sp,-80
    800053c4:	e486                	sd	ra,72(sp)
    800053c6:	e0a2                	sd	s0,64(sp)
    800053c8:	fc26                	sd	s1,56(sp)
    800053ca:	f84a                	sd	s2,48(sp)
    800053cc:	f44e                	sd	s3,40(sp)
    800053ce:	f052                	sd	s4,32(sp)
    800053d0:	ec56                	sd	s5,24(sp)
    800053d2:	e85a                	sd	s6,16(sp)
    800053d4:	0880                	addi	s0,sp,80
    800053d6:	8b2e                	mv	s6,a1
    800053d8:	89b2                	mv	s3,a2
    800053da:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053dc:	fb040593          	addi	a1,s0,-80
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	e3e080e7          	jalr	-450(ra) # 8000421e <nameiparent>
    800053e8:	84aa                	mv	s1,a0
    800053ea:	14050f63          	beqz	a0,80005548 <create+0x186>
    return 0;

  ilock(dp);
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	666080e7          	jalr	1638(ra) # 80003a54 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053f6:	4601                	li	a2,0
    800053f8:	fb040593          	addi	a1,s0,-80
    800053fc:	8526                	mv	a0,s1
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	b3a080e7          	jalr	-1222(ra) # 80003f38 <dirlookup>
    80005406:	8aaa                	mv	s5,a0
    80005408:	c931                	beqz	a0,8000545c <create+0x9a>
    iunlockput(dp);
    8000540a:	8526                	mv	a0,s1
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	8aa080e7          	jalr	-1878(ra) # 80003cb6 <iunlockput>
    ilock(ip);
    80005414:	8556                	mv	a0,s5
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	63e080e7          	jalr	1598(ra) # 80003a54 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000541e:	000b059b          	sext.w	a1,s6
    80005422:	4789                	li	a5,2
    80005424:	02f59563          	bne	a1,a5,8000544e <create+0x8c>
    80005428:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc4a4>
    8000542c:	37f9                	addiw	a5,a5,-2
    8000542e:	17c2                	slli	a5,a5,0x30
    80005430:	93c1                	srli	a5,a5,0x30
    80005432:	4705                	li	a4,1
    80005434:	00f76d63          	bltu	a4,a5,8000544e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005438:	8556                	mv	a0,s5
    8000543a:	60a6                	ld	ra,72(sp)
    8000543c:	6406                	ld	s0,64(sp)
    8000543e:	74e2                	ld	s1,56(sp)
    80005440:	7942                	ld	s2,48(sp)
    80005442:	79a2                	ld	s3,40(sp)
    80005444:	7a02                	ld	s4,32(sp)
    80005446:	6ae2                	ld	s5,24(sp)
    80005448:	6b42                	ld	s6,16(sp)
    8000544a:	6161                	addi	sp,sp,80
    8000544c:	8082                	ret
    iunlockput(ip);
    8000544e:	8556                	mv	a0,s5
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	866080e7          	jalr	-1946(ra) # 80003cb6 <iunlockput>
    return 0;
    80005458:	4a81                	li	s5,0
    8000545a:	bff9                	j	80005438 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000545c:	85da                	mv	a1,s6
    8000545e:	4088                	lw	a0,0(s1)
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	456080e7          	jalr	1110(ra) # 800038b6 <ialloc>
    80005468:	8a2a                	mv	s4,a0
    8000546a:	c539                	beqz	a0,800054b8 <create+0xf6>
  ilock(ip);
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	5e8080e7          	jalr	1512(ra) # 80003a54 <ilock>
  ip->major = major;
    80005474:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005478:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000547c:	4905                	li	s2,1
    8000547e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005482:	8552                	mv	a0,s4
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	504080e7          	jalr	1284(ra) # 80003988 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000548c:	000b059b          	sext.w	a1,s6
    80005490:	03258b63          	beq	a1,s2,800054c6 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005494:	004a2603          	lw	a2,4(s4)
    80005498:	fb040593          	addi	a1,s0,-80
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	cb0080e7          	jalr	-848(ra) # 8000414e <dirlink>
    800054a6:	06054f63          	bltz	a0,80005524 <create+0x162>
  iunlockput(dp);
    800054aa:	8526                	mv	a0,s1
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	80a080e7          	jalr	-2038(ra) # 80003cb6 <iunlockput>
  return ip;
    800054b4:	8ad2                	mv	s5,s4
    800054b6:	b749                	j	80005438 <create+0x76>
    iunlockput(dp);
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	7fc080e7          	jalr	2044(ra) # 80003cb6 <iunlockput>
    return 0;
    800054c2:	8ad2                	mv	s5,s4
    800054c4:	bf95                	j	80005438 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054c6:	004a2603          	lw	a2,4(s4)
    800054ca:	00003597          	auipc	a1,0x3
    800054ce:	24e58593          	addi	a1,a1,590 # 80008718 <syscalls+0x2c0>
    800054d2:	8552                	mv	a0,s4
    800054d4:	fffff097          	auipc	ra,0xfffff
    800054d8:	c7a080e7          	jalr	-902(ra) # 8000414e <dirlink>
    800054dc:	04054463          	bltz	a0,80005524 <create+0x162>
    800054e0:	40d0                	lw	a2,4(s1)
    800054e2:	00003597          	auipc	a1,0x3
    800054e6:	23e58593          	addi	a1,a1,574 # 80008720 <syscalls+0x2c8>
    800054ea:	8552                	mv	a0,s4
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	c62080e7          	jalr	-926(ra) # 8000414e <dirlink>
    800054f4:	02054863          	bltz	a0,80005524 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800054f8:	004a2603          	lw	a2,4(s4)
    800054fc:	fb040593          	addi	a1,s0,-80
    80005500:	8526                	mv	a0,s1
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	c4c080e7          	jalr	-948(ra) # 8000414e <dirlink>
    8000550a:	00054d63          	bltz	a0,80005524 <create+0x162>
    dp->nlink++;  // for ".."
    8000550e:	04a4d783          	lhu	a5,74(s1)
    80005512:	2785                	addiw	a5,a5,1
    80005514:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	46e080e7          	jalr	1134(ra) # 80003988 <iupdate>
    80005522:	b761                	j	800054aa <create+0xe8>
  ip->nlink = 0;
    80005524:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005528:	8552                	mv	a0,s4
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	45e080e7          	jalr	1118(ra) # 80003988 <iupdate>
  iunlockput(ip);
    80005532:	8552                	mv	a0,s4
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	782080e7          	jalr	1922(ra) # 80003cb6 <iunlockput>
  iunlockput(dp);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	778080e7          	jalr	1912(ra) # 80003cb6 <iunlockput>
  return 0;
    80005546:	bdcd                	j	80005438 <create+0x76>
    return 0;
    80005548:	8aaa                	mv	s5,a0
    8000554a:	b5fd                	j	80005438 <create+0x76>

000000008000554c <sys_dup>:
{
    8000554c:	7179                	addi	sp,sp,-48
    8000554e:	f406                	sd	ra,40(sp)
    80005550:	f022                	sd	s0,32(sp)
    80005552:	ec26                	sd	s1,24(sp)
    80005554:	e84a                	sd	s2,16(sp)
    80005556:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005558:	fd840613          	addi	a2,s0,-40
    8000555c:	4581                	li	a1,0
    8000555e:	4501                	li	a0,0
    80005560:	00000097          	auipc	ra,0x0
    80005564:	dc0080e7          	jalr	-576(ra) # 80005320 <argfd>
    return -1;
    80005568:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000556a:	02054363          	bltz	a0,80005590 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000556e:	fd843903          	ld	s2,-40(s0)
    80005572:	854a                	mv	a0,s2
    80005574:	00000097          	auipc	ra,0x0
    80005578:	e0c080e7          	jalr	-500(ra) # 80005380 <fdalloc>
    8000557c:	84aa                	mv	s1,a0
    return -1;
    8000557e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005580:	00054863          	bltz	a0,80005590 <sys_dup+0x44>
  filedup(f);
    80005584:	854a                	mv	a0,s2
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	310080e7          	jalr	784(ra) # 80004896 <filedup>
  return fd;
    8000558e:	87a6                	mv	a5,s1
}
    80005590:	853e                	mv	a0,a5
    80005592:	70a2                	ld	ra,40(sp)
    80005594:	7402                	ld	s0,32(sp)
    80005596:	64e2                	ld	s1,24(sp)
    80005598:	6942                	ld	s2,16(sp)
    8000559a:	6145                	addi	sp,sp,48
    8000559c:	8082                	ret

000000008000559e <sys_read>:
{
    8000559e:	7179                	addi	sp,sp,-48
    800055a0:	f406                	sd	ra,40(sp)
    800055a2:	f022                	sd	s0,32(sp)
    800055a4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800055a6:	fd840593          	addi	a1,s0,-40
    800055aa:	4505                	li	a0,1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	83a080e7          	jalr	-1990(ra) # 80002de6 <argaddr>
  argint(2, &n);
    800055b4:	fe440593          	addi	a1,s0,-28
    800055b8:	4509                	li	a0,2
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	80c080e7          	jalr	-2036(ra) # 80002dc6 <argint>
  if(argfd(0, 0, &f) < 0)
    800055c2:	fe840613          	addi	a2,s0,-24
    800055c6:	4581                	li	a1,0
    800055c8:	4501                	li	a0,0
    800055ca:	00000097          	auipc	ra,0x0
    800055ce:	d56080e7          	jalr	-682(ra) # 80005320 <argfd>
    800055d2:	87aa                	mv	a5,a0
    return -1;
    800055d4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055d6:	0007cc63          	bltz	a5,800055ee <sys_read+0x50>
    return fileread(f, p, n);
    800055da:	fe442603          	lw	a2,-28(s0)
    800055de:	fd843583          	ld	a1,-40(s0)
    800055e2:	fe843503          	ld	a0,-24(s0)
    800055e6:	fffff097          	auipc	ra,0xfffff
    800055ea:	43c080e7          	jalr	1084(ra) # 80004a22 <fileread>
}
    800055ee:	70a2                	ld	ra,40(sp)
    800055f0:	7402                	ld	s0,32(sp)
    800055f2:	6145                	addi	sp,sp,48
    800055f4:	8082                	ret

00000000800055f6 <sys_getreadcount>:
{
    800055f6:	1141                	addi	sp,sp,-16
    800055f8:	e422                	sd	s0,8(sp)
    800055fa:	0800                	addi	s0,sp,16
}
    800055fc:	00003517          	auipc	a0,0x3
    80005600:	31852503          	lw	a0,792(a0) # 80008914 <sum>
    80005604:	6422                	ld	s0,8(sp)
    80005606:	0141                	addi	sp,sp,16
    80005608:	8082                	ret

000000008000560a <sys_write>:
{
    8000560a:	7179                	addi	sp,sp,-48
    8000560c:	f406                	sd	ra,40(sp)
    8000560e:	f022                	sd	s0,32(sp)
    80005610:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005612:	fd840593          	addi	a1,s0,-40
    80005616:	4505                	li	a0,1
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	7ce080e7          	jalr	1998(ra) # 80002de6 <argaddr>
  argint(2, &n);
    80005620:	fe440593          	addi	a1,s0,-28
    80005624:	4509                	li	a0,2
    80005626:	ffffd097          	auipc	ra,0xffffd
    8000562a:	7a0080e7          	jalr	1952(ra) # 80002dc6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000562e:	fe840613          	addi	a2,s0,-24
    80005632:	4581                	li	a1,0
    80005634:	4501                	li	a0,0
    80005636:	00000097          	auipc	ra,0x0
    8000563a:	cea080e7          	jalr	-790(ra) # 80005320 <argfd>
    8000563e:	87aa                	mv	a5,a0
    return -1;
    80005640:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005642:	0007cc63          	bltz	a5,8000565a <sys_write+0x50>
  return filewrite(f, p, n);
    80005646:	fe442603          	lw	a2,-28(s0)
    8000564a:	fd843583          	ld	a1,-40(s0)
    8000564e:	fe843503          	ld	a0,-24(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	492080e7          	jalr	1170(ra) # 80004ae4 <filewrite>
}
    8000565a:	70a2                	ld	ra,40(sp)
    8000565c:	7402                	ld	s0,32(sp)
    8000565e:	6145                	addi	sp,sp,48
    80005660:	8082                	ret

0000000080005662 <sys_close>:
{
    80005662:	1101                	addi	sp,sp,-32
    80005664:	ec06                	sd	ra,24(sp)
    80005666:	e822                	sd	s0,16(sp)
    80005668:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000566a:	fe040613          	addi	a2,s0,-32
    8000566e:	fec40593          	addi	a1,s0,-20
    80005672:	4501                	li	a0,0
    80005674:	00000097          	auipc	ra,0x0
    80005678:	cac080e7          	jalr	-852(ra) # 80005320 <argfd>
    return -1;
    8000567c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000567e:	02054463          	bltz	a0,800056a6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005682:	ffffc097          	auipc	ra,0xffffc
    80005686:	32a080e7          	jalr	810(ra) # 800019ac <myproc>
    8000568a:	fec42783          	lw	a5,-20(s0)
    8000568e:	07f1                	addi	a5,a5,28
    80005690:	078e                	slli	a5,a5,0x3
    80005692:	953e                	add	a0,a0,a5
    80005694:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005698:	fe043503          	ld	a0,-32(s0)
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	24c080e7          	jalr	588(ra) # 800048e8 <fileclose>
  return 0;
    800056a4:	4781                	li	a5,0
}
    800056a6:	853e                	mv	a0,a5
    800056a8:	60e2                	ld	ra,24(sp)
    800056aa:	6442                	ld	s0,16(sp)
    800056ac:	6105                	addi	sp,sp,32
    800056ae:	8082                	ret

00000000800056b0 <sys_fstat>:
{
    800056b0:	1101                	addi	sp,sp,-32
    800056b2:	ec06                	sd	ra,24(sp)
    800056b4:	e822                	sd	s0,16(sp)
    800056b6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800056b8:	fe040593          	addi	a1,s0,-32
    800056bc:	4505                	li	a0,1
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	728080e7          	jalr	1832(ra) # 80002de6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800056c6:	fe840613          	addi	a2,s0,-24
    800056ca:	4581                	li	a1,0
    800056cc:	4501                	li	a0,0
    800056ce:	00000097          	auipc	ra,0x0
    800056d2:	c52080e7          	jalr	-942(ra) # 80005320 <argfd>
    800056d6:	87aa                	mv	a5,a0
    return -1;
    800056d8:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056da:	0007ca63          	bltz	a5,800056ee <sys_fstat+0x3e>
  return filestat(f, st);
    800056de:	fe043583          	ld	a1,-32(s0)
    800056e2:	fe843503          	ld	a0,-24(s0)
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	2ca080e7          	jalr	714(ra) # 800049b0 <filestat>
}
    800056ee:	60e2                	ld	ra,24(sp)
    800056f0:	6442                	ld	s0,16(sp)
    800056f2:	6105                	addi	sp,sp,32
    800056f4:	8082                	ret

00000000800056f6 <sys_link>:
{
    800056f6:	7169                	addi	sp,sp,-304
    800056f8:	f606                	sd	ra,296(sp)
    800056fa:	f222                	sd	s0,288(sp)
    800056fc:	ee26                	sd	s1,280(sp)
    800056fe:	ea4a                	sd	s2,272(sp)
    80005700:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005702:	08000613          	li	a2,128
    80005706:	ed040593          	addi	a1,s0,-304
    8000570a:	4501                	li	a0,0
    8000570c:	ffffd097          	auipc	ra,0xffffd
    80005710:	6fa080e7          	jalr	1786(ra) # 80002e06 <argstr>
    return -1;
    80005714:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005716:	10054e63          	bltz	a0,80005832 <sys_link+0x13c>
    8000571a:	08000613          	li	a2,128
    8000571e:	f5040593          	addi	a1,s0,-176
    80005722:	4505                	li	a0,1
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	6e2080e7          	jalr	1762(ra) # 80002e06 <argstr>
    return -1;
    8000572c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000572e:	10054263          	bltz	a0,80005832 <sys_link+0x13c>
  begin_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	cee080e7          	jalr	-786(ra) # 80004420 <begin_op>
  if((ip = namei(old)) == 0){
    8000573a:	ed040513          	addi	a0,s0,-304
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	ac2080e7          	jalr	-1342(ra) # 80004200 <namei>
    80005746:	84aa                	mv	s1,a0
    80005748:	c551                	beqz	a0,800057d4 <sys_link+0xde>
  ilock(ip);
    8000574a:	ffffe097          	auipc	ra,0xffffe
    8000574e:	30a080e7          	jalr	778(ra) # 80003a54 <ilock>
  if(ip->type == T_DIR){
    80005752:	04449703          	lh	a4,68(s1)
    80005756:	4785                	li	a5,1
    80005758:	08f70463          	beq	a4,a5,800057e0 <sys_link+0xea>
  ip->nlink++;
    8000575c:	04a4d783          	lhu	a5,74(s1)
    80005760:	2785                	addiw	a5,a5,1
    80005762:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005766:	8526                	mv	a0,s1
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	220080e7          	jalr	544(ra) # 80003988 <iupdate>
  iunlock(ip);
    80005770:	8526                	mv	a0,s1
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	3a4080e7          	jalr	932(ra) # 80003b16 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000577a:	fd040593          	addi	a1,s0,-48
    8000577e:	f5040513          	addi	a0,s0,-176
    80005782:	fffff097          	auipc	ra,0xfffff
    80005786:	a9c080e7          	jalr	-1380(ra) # 8000421e <nameiparent>
    8000578a:	892a                	mv	s2,a0
    8000578c:	c935                	beqz	a0,80005800 <sys_link+0x10a>
  ilock(dp);
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	2c6080e7          	jalr	710(ra) # 80003a54 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005796:	00092703          	lw	a4,0(s2)
    8000579a:	409c                	lw	a5,0(s1)
    8000579c:	04f71d63          	bne	a4,a5,800057f6 <sys_link+0x100>
    800057a0:	40d0                	lw	a2,4(s1)
    800057a2:	fd040593          	addi	a1,s0,-48
    800057a6:	854a                	mv	a0,s2
    800057a8:	fffff097          	auipc	ra,0xfffff
    800057ac:	9a6080e7          	jalr	-1626(ra) # 8000414e <dirlink>
    800057b0:	04054363          	bltz	a0,800057f6 <sys_link+0x100>
  iunlockput(dp);
    800057b4:	854a                	mv	a0,s2
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	500080e7          	jalr	1280(ra) # 80003cb6 <iunlockput>
  iput(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	44e080e7          	jalr	1102(ra) # 80003c0e <iput>
  end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	cd6080e7          	jalr	-810(ra) # 8000449e <end_op>
  return 0;
    800057d0:	4781                	li	a5,0
    800057d2:	a085                	j	80005832 <sys_link+0x13c>
    end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	cca080e7          	jalr	-822(ra) # 8000449e <end_op>
    return -1;
    800057dc:	57fd                	li	a5,-1
    800057de:	a891                	j	80005832 <sys_link+0x13c>
    iunlockput(ip);
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	4d4080e7          	jalr	1236(ra) # 80003cb6 <iunlockput>
    end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	cb4080e7          	jalr	-844(ra) # 8000449e <end_op>
    return -1;
    800057f2:	57fd                	li	a5,-1
    800057f4:	a83d                	j	80005832 <sys_link+0x13c>
    iunlockput(dp);
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	4be080e7          	jalr	1214(ra) # 80003cb6 <iunlockput>
  ilock(ip);
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	252080e7          	jalr	594(ra) # 80003a54 <ilock>
  ip->nlink--;
    8000580a:	04a4d783          	lhu	a5,74(s1)
    8000580e:	37fd                	addiw	a5,a5,-1
    80005810:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005814:	8526                	mv	a0,s1
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	172080e7          	jalr	370(ra) # 80003988 <iupdate>
  iunlockput(ip);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	496080e7          	jalr	1174(ra) # 80003cb6 <iunlockput>
  end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	c76080e7          	jalr	-906(ra) # 8000449e <end_op>
  return -1;
    80005830:	57fd                	li	a5,-1
}
    80005832:	853e                	mv	a0,a5
    80005834:	70b2                	ld	ra,296(sp)
    80005836:	7412                	ld	s0,288(sp)
    80005838:	64f2                	ld	s1,280(sp)
    8000583a:	6952                	ld	s2,272(sp)
    8000583c:	6155                	addi	sp,sp,304
    8000583e:	8082                	ret

0000000080005840 <sys_unlink>:
{
    80005840:	7151                	addi	sp,sp,-240
    80005842:	f586                	sd	ra,232(sp)
    80005844:	f1a2                	sd	s0,224(sp)
    80005846:	eda6                	sd	s1,216(sp)
    80005848:	e9ca                	sd	s2,208(sp)
    8000584a:	e5ce                	sd	s3,200(sp)
    8000584c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000584e:	08000613          	li	a2,128
    80005852:	f3040593          	addi	a1,s0,-208
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	5ae080e7          	jalr	1454(ra) # 80002e06 <argstr>
    80005860:	18054163          	bltz	a0,800059e2 <sys_unlink+0x1a2>
  begin_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	bbc080e7          	jalr	-1092(ra) # 80004420 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000586c:	fb040593          	addi	a1,s0,-80
    80005870:	f3040513          	addi	a0,s0,-208
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	9aa080e7          	jalr	-1622(ra) # 8000421e <nameiparent>
    8000587c:	84aa                	mv	s1,a0
    8000587e:	c979                	beqz	a0,80005954 <sys_unlink+0x114>
  ilock(dp);
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	1d4080e7          	jalr	468(ra) # 80003a54 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005888:	00003597          	auipc	a1,0x3
    8000588c:	e9058593          	addi	a1,a1,-368 # 80008718 <syscalls+0x2c0>
    80005890:	fb040513          	addi	a0,s0,-80
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	68a080e7          	jalr	1674(ra) # 80003f1e <namecmp>
    8000589c:	14050a63          	beqz	a0,800059f0 <sys_unlink+0x1b0>
    800058a0:	00003597          	auipc	a1,0x3
    800058a4:	e8058593          	addi	a1,a1,-384 # 80008720 <syscalls+0x2c8>
    800058a8:	fb040513          	addi	a0,s0,-80
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	672080e7          	jalr	1650(ra) # 80003f1e <namecmp>
    800058b4:	12050e63          	beqz	a0,800059f0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058b8:	f2c40613          	addi	a2,s0,-212
    800058bc:	fb040593          	addi	a1,s0,-80
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	676080e7          	jalr	1654(ra) # 80003f38 <dirlookup>
    800058ca:	892a                	mv	s2,a0
    800058cc:	12050263          	beqz	a0,800059f0 <sys_unlink+0x1b0>
  ilock(ip);
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	184080e7          	jalr	388(ra) # 80003a54 <ilock>
  if(ip->nlink < 1)
    800058d8:	04a91783          	lh	a5,74(s2)
    800058dc:	08f05263          	blez	a5,80005960 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058e0:	04491703          	lh	a4,68(s2)
    800058e4:	4785                	li	a5,1
    800058e6:	08f70563          	beq	a4,a5,80005970 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058ea:	4641                	li	a2,16
    800058ec:	4581                	li	a1,0
    800058ee:	fc040513          	addi	a0,s0,-64
    800058f2:	ffffb097          	auipc	ra,0xffffb
    800058f6:	3e0080e7          	jalr	992(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058fa:	4741                	li	a4,16
    800058fc:	f2c42683          	lw	a3,-212(s0)
    80005900:	fc040613          	addi	a2,s0,-64
    80005904:	4581                	li	a1,0
    80005906:	8526                	mv	a0,s1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	4f8080e7          	jalr	1272(ra) # 80003e00 <writei>
    80005910:	47c1                	li	a5,16
    80005912:	0af51563          	bne	a0,a5,800059bc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005916:	04491703          	lh	a4,68(s2)
    8000591a:	4785                	li	a5,1
    8000591c:	0af70863          	beq	a4,a5,800059cc <sys_unlink+0x18c>
  iunlockput(dp);
    80005920:	8526                	mv	a0,s1
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	394080e7          	jalr	916(ra) # 80003cb6 <iunlockput>
  ip->nlink--;
    8000592a:	04a95783          	lhu	a5,74(s2)
    8000592e:	37fd                	addiw	a5,a5,-1
    80005930:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005934:	854a                	mv	a0,s2
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	052080e7          	jalr	82(ra) # 80003988 <iupdate>
  iunlockput(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	376080e7          	jalr	886(ra) # 80003cb6 <iunlockput>
  end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	b56080e7          	jalr	-1194(ra) # 8000449e <end_op>
  return 0;
    80005950:	4501                	li	a0,0
    80005952:	a84d                	j	80005a04 <sys_unlink+0x1c4>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	b4a080e7          	jalr	-1206(ra) # 8000449e <end_op>
    return -1;
    8000595c:	557d                	li	a0,-1
    8000595e:	a05d                	j	80005a04 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005960:	00003517          	auipc	a0,0x3
    80005964:	dc850513          	addi	a0,a0,-568 # 80008728 <syscalls+0x2d0>
    80005968:	ffffb097          	auipc	ra,0xffffb
    8000596c:	bd8080e7          	jalr	-1064(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005970:	04c92703          	lw	a4,76(s2)
    80005974:	02000793          	li	a5,32
    80005978:	f6e7f9e3          	bgeu	a5,a4,800058ea <sys_unlink+0xaa>
    8000597c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005980:	4741                	li	a4,16
    80005982:	86ce                	mv	a3,s3
    80005984:	f1840613          	addi	a2,s0,-232
    80005988:	4581                	li	a1,0
    8000598a:	854a                	mv	a0,s2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	37c080e7          	jalr	892(ra) # 80003d08 <readi>
    80005994:	47c1                	li	a5,16
    80005996:	00f51b63          	bne	a0,a5,800059ac <sys_unlink+0x16c>
    if(de.inum != 0)
    8000599a:	f1845783          	lhu	a5,-232(s0)
    8000599e:	e7a1                	bnez	a5,800059e6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059a0:	29c1                	addiw	s3,s3,16
    800059a2:	04c92783          	lw	a5,76(s2)
    800059a6:	fcf9ede3          	bltu	s3,a5,80005980 <sys_unlink+0x140>
    800059aa:	b781                	j	800058ea <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059ac:	00003517          	auipc	a0,0x3
    800059b0:	d9450513          	addi	a0,a0,-620 # 80008740 <syscalls+0x2e8>
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	b8c080e7          	jalr	-1140(ra) # 80000540 <panic>
    panic("unlink: writei");
    800059bc:	00003517          	auipc	a0,0x3
    800059c0:	d9c50513          	addi	a0,a0,-612 # 80008758 <syscalls+0x300>
    800059c4:	ffffb097          	auipc	ra,0xffffb
    800059c8:	b7c080e7          	jalr	-1156(ra) # 80000540 <panic>
    dp->nlink--;
    800059cc:	04a4d783          	lhu	a5,74(s1)
    800059d0:	37fd                	addiw	a5,a5,-1
    800059d2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059d6:	8526                	mv	a0,s1
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	fb0080e7          	jalr	-80(ra) # 80003988 <iupdate>
    800059e0:	b781                	j	80005920 <sys_unlink+0xe0>
    return -1;
    800059e2:	557d                	li	a0,-1
    800059e4:	a005                	j	80005a04 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059e6:	854a                	mv	a0,s2
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	2ce080e7          	jalr	718(ra) # 80003cb6 <iunlockput>
  iunlockput(dp);
    800059f0:	8526                	mv	a0,s1
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	2c4080e7          	jalr	708(ra) # 80003cb6 <iunlockput>
  end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	aa4080e7          	jalr	-1372(ra) # 8000449e <end_op>
  return -1;
    80005a02:	557d                	li	a0,-1
}
    80005a04:	70ae                	ld	ra,232(sp)
    80005a06:	740e                	ld	s0,224(sp)
    80005a08:	64ee                	ld	s1,216(sp)
    80005a0a:	694e                	ld	s2,208(sp)
    80005a0c:	69ae                	ld	s3,200(sp)
    80005a0e:	616d                	addi	sp,sp,240
    80005a10:	8082                	ret

0000000080005a12 <sys_open>:

uint64
sys_open(void)
{
    80005a12:	7131                	addi	sp,sp,-192
    80005a14:	fd06                	sd	ra,184(sp)
    80005a16:	f922                	sd	s0,176(sp)
    80005a18:	f526                	sd	s1,168(sp)
    80005a1a:	f14a                	sd	s2,160(sp)
    80005a1c:	ed4e                	sd	s3,152(sp)
    80005a1e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a20:	f4c40593          	addi	a1,s0,-180
    80005a24:	4505                	li	a0,1
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	3a0080e7          	jalr	928(ra) # 80002dc6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a2e:	08000613          	li	a2,128
    80005a32:	f5040593          	addi	a1,s0,-176
    80005a36:	4501                	li	a0,0
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	3ce080e7          	jalr	974(ra) # 80002e06 <argstr>
    80005a40:	87aa                	mv	a5,a0
    return -1;
    80005a42:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a44:	0a07c963          	bltz	a5,80005af6 <sys_open+0xe4>

  begin_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	9d8080e7          	jalr	-1576(ra) # 80004420 <begin_op>

  if(omode & O_CREATE){
    80005a50:	f4c42783          	lw	a5,-180(s0)
    80005a54:	2007f793          	andi	a5,a5,512
    80005a58:	cfc5                	beqz	a5,80005b10 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a5a:	4681                	li	a3,0
    80005a5c:	4601                	li	a2,0
    80005a5e:	4589                	li	a1,2
    80005a60:	f5040513          	addi	a0,s0,-176
    80005a64:	00000097          	auipc	ra,0x0
    80005a68:	95e080e7          	jalr	-1698(ra) # 800053c2 <create>
    80005a6c:	84aa                	mv	s1,a0
    if(ip == 0){
    80005a6e:	c959                	beqz	a0,80005b04 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a70:	04449703          	lh	a4,68(s1)
    80005a74:	478d                	li	a5,3
    80005a76:	00f71763          	bne	a4,a5,80005a84 <sys_open+0x72>
    80005a7a:	0464d703          	lhu	a4,70(s1)
    80005a7e:	47a5                	li	a5,9
    80005a80:	0ce7ed63          	bltu	a5,a4,80005b5a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	da8080e7          	jalr	-600(ra) # 8000482c <filealloc>
    80005a8c:	89aa                	mv	s3,a0
    80005a8e:	10050363          	beqz	a0,80005b94 <sys_open+0x182>
    80005a92:	00000097          	auipc	ra,0x0
    80005a96:	8ee080e7          	jalr	-1810(ra) # 80005380 <fdalloc>
    80005a9a:	892a                	mv	s2,a0
    80005a9c:	0e054763          	bltz	a0,80005b8a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aa0:	04449703          	lh	a4,68(s1)
    80005aa4:	478d                	li	a5,3
    80005aa6:	0cf70563          	beq	a4,a5,80005b70 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005aaa:	4789                	li	a5,2
    80005aac:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ab0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ab4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ab8:	f4c42783          	lw	a5,-180(s0)
    80005abc:	0017c713          	xori	a4,a5,1
    80005ac0:	8b05                	andi	a4,a4,1
    80005ac2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ac6:	0037f713          	andi	a4,a5,3
    80005aca:	00e03733          	snez	a4,a4
    80005ace:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ad2:	4007f793          	andi	a5,a5,1024
    80005ad6:	c791                	beqz	a5,80005ae2 <sys_open+0xd0>
    80005ad8:	04449703          	lh	a4,68(s1)
    80005adc:	4789                	li	a5,2
    80005ade:	0af70063          	beq	a4,a5,80005b7e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ae2:	8526                	mv	a0,s1
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	032080e7          	jalr	50(ra) # 80003b16 <iunlock>
  end_op();
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	9b2080e7          	jalr	-1614(ra) # 8000449e <end_op>

  return fd;
    80005af4:	854a                	mv	a0,s2
}
    80005af6:	70ea                	ld	ra,184(sp)
    80005af8:	744a                	ld	s0,176(sp)
    80005afa:	74aa                	ld	s1,168(sp)
    80005afc:	790a                	ld	s2,160(sp)
    80005afe:	69ea                	ld	s3,152(sp)
    80005b00:	6129                	addi	sp,sp,192
    80005b02:	8082                	ret
      end_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	99a080e7          	jalr	-1638(ra) # 8000449e <end_op>
      return -1;
    80005b0c:	557d                	li	a0,-1
    80005b0e:	b7e5                	j	80005af6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b10:	f5040513          	addi	a0,s0,-176
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	6ec080e7          	jalr	1772(ra) # 80004200 <namei>
    80005b1c:	84aa                	mv	s1,a0
    80005b1e:	c905                	beqz	a0,80005b4e <sys_open+0x13c>
    ilock(ip);
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	f34080e7          	jalr	-204(ra) # 80003a54 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b28:	04449703          	lh	a4,68(s1)
    80005b2c:	4785                	li	a5,1
    80005b2e:	f4f711e3          	bne	a4,a5,80005a70 <sys_open+0x5e>
    80005b32:	f4c42783          	lw	a5,-180(s0)
    80005b36:	d7b9                	beqz	a5,80005a84 <sys_open+0x72>
      iunlockput(ip);
    80005b38:	8526                	mv	a0,s1
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	17c080e7          	jalr	380(ra) # 80003cb6 <iunlockput>
      end_op();
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	95c080e7          	jalr	-1700(ra) # 8000449e <end_op>
      return -1;
    80005b4a:	557d                	li	a0,-1
    80005b4c:	b76d                	j	80005af6 <sys_open+0xe4>
      end_op();
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	950080e7          	jalr	-1712(ra) # 8000449e <end_op>
      return -1;
    80005b56:	557d                	li	a0,-1
    80005b58:	bf79                	j	80005af6 <sys_open+0xe4>
    iunlockput(ip);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	15a080e7          	jalr	346(ra) # 80003cb6 <iunlockput>
    end_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	93a080e7          	jalr	-1734(ra) # 8000449e <end_op>
    return -1;
    80005b6c:	557d                	li	a0,-1
    80005b6e:	b761                	j	80005af6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b70:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b74:	04649783          	lh	a5,70(s1)
    80005b78:	02f99223          	sh	a5,36(s3)
    80005b7c:	bf25                	j	80005ab4 <sys_open+0xa2>
    itrunc(ip);
    80005b7e:	8526                	mv	a0,s1
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	fe2080e7          	jalr	-30(ra) # 80003b62 <itrunc>
    80005b88:	bfa9                	j	80005ae2 <sys_open+0xd0>
      fileclose(f);
    80005b8a:	854e                	mv	a0,s3
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	d5c080e7          	jalr	-676(ra) # 800048e8 <fileclose>
    iunlockput(ip);
    80005b94:	8526                	mv	a0,s1
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	120080e7          	jalr	288(ra) # 80003cb6 <iunlockput>
    end_op();
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	900080e7          	jalr	-1792(ra) # 8000449e <end_op>
    return -1;
    80005ba6:	557d                	li	a0,-1
    80005ba8:	b7b9                	j	80005af6 <sys_open+0xe4>

0000000080005baa <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005baa:	7175                	addi	sp,sp,-144
    80005bac:	e506                	sd	ra,136(sp)
    80005bae:	e122                	sd	s0,128(sp)
    80005bb0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	86e080e7          	jalr	-1938(ra) # 80004420 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bba:	08000613          	li	a2,128
    80005bbe:	f7040593          	addi	a1,s0,-144
    80005bc2:	4501                	li	a0,0
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	242080e7          	jalr	578(ra) # 80002e06 <argstr>
    80005bcc:	02054963          	bltz	a0,80005bfe <sys_mkdir+0x54>
    80005bd0:	4681                	li	a3,0
    80005bd2:	4601                	li	a2,0
    80005bd4:	4585                	li	a1,1
    80005bd6:	f7040513          	addi	a0,s0,-144
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	7e8080e7          	jalr	2024(ra) # 800053c2 <create>
    80005be2:	cd11                	beqz	a0,80005bfe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	0d2080e7          	jalr	210(ra) # 80003cb6 <iunlockput>
  end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	8b2080e7          	jalr	-1870(ra) # 8000449e <end_op>
  return 0;
    80005bf4:	4501                	li	a0,0
}
    80005bf6:	60aa                	ld	ra,136(sp)
    80005bf8:	640a                	ld	s0,128(sp)
    80005bfa:	6149                	addi	sp,sp,144
    80005bfc:	8082                	ret
    end_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	8a0080e7          	jalr	-1888(ra) # 8000449e <end_op>
    return -1;
    80005c06:	557d                	li	a0,-1
    80005c08:	b7fd                	j	80005bf6 <sys_mkdir+0x4c>

0000000080005c0a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c0a:	7135                	addi	sp,sp,-160
    80005c0c:	ed06                	sd	ra,152(sp)
    80005c0e:	e922                	sd	s0,144(sp)
    80005c10:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	80e080e7          	jalr	-2034(ra) # 80004420 <begin_op>
  argint(1, &major);
    80005c1a:	f6c40593          	addi	a1,s0,-148
    80005c1e:	4505                	li	a0,1
    80005c20:	ffffd097          	auipc	ra,0xffffd
    80005c24:	1a6080e7          	jalr	422(ra) # 80002dc6 <argint>
  argint(2, &minor);
    80005c28:	f6840593          	addi	a1,s0,-152
    80005c2c:	4509                	li	a0,2
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	198080e7          	jalr	408(ra) # 80002dc6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c36:	08000613          	li	a2,128
    80005c3a:	f7040593          	addi	a1,s0,-144
    80005c3e:	4501                	li	a0,0
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	1c6080e7          	jalr	454(ra) # 80002e06 <argstr>
    80005c48:	02054b63          	bltz	a0,80005c7e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c4c:	f6841683          	lh	a3,-152(s0)
    80005c50:	f6c41603          	lh	a2,-148(s0)
    80005c54:	458d                	li	a1,3
    80005c56:	f7040513          	addi	a0,s0,-144
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	768080e7          	jalr	1896(ra) # 800053c2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c62:	cd11                	beqz	a0,80005c7e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	052080e7          	jalr	82(ra) # 80003cb6 <iunlockput>
  end_op();
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	832080e7          	jalr	-1998(ra) # 8000449e <end_op>
  return 0;
    80005c74:	4501                	li	a0,0
}
    80005c76:	60ea                	ld	ra,152(sp)
    80005c78:	644a                	ld	s0,144(sp)
    80005c7a:	610d                	addi	sp,sp,160
    80005c7c:	8082                	ret
    end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	820080e7          	jalr	-2016(ra) # 8000449e <end_op>
    return -1;
    80005c86:	557d                	li	a0,-1
    80005c88:	b7fd                	j	80005c76 <sys_mknod+0x6c>

0000000080005c8a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c8a:	7135                	addi	sp,sp,-160
    80005c8c:	ed06                	sd	ra,152(sp)
    80005c8e:	e922                	sd	s0,144(sp)
    80005c90:	e526                	sd	s1,136(sp)
    80005c92:	e14a                	sd	s2,128(sp)
    80005c94:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c96:	ffffc097          	auipc	ra,0xffffc
    80005c9a:	d16080e7          	jalr	-746(ra) # 800019ac <myproc>
    80005c9e:	892a                	mv	s2,a0
  
  begin_op();
    80005ca0:	ffffe097          	auipc	ra,0xffffe
    80005ca4:	780080e7          	jalr	1920(ra) # 80004420 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ca8:	08000613          	li	a2,128
    80005cac:	f6040593          	addi	a1,s0,-160
    80005cb0:	4501                	li	a0,0
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	154080e7          	jalr	340(ra) # 80002e06 <argstr>
    80005cba:	04054b63          	bltz	a0,80005d10 <sys_chdir+0x86>
    80005cbe:	f6040513          	addi	a0,s0,-160
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	53e080e7          	jalr	1342(ra) # 80004200 <namei>
    80005cca:	84aa                	mv	s1,a0
    80005ccc:	c131                	beqz	a0,80005d10 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	d86080e7          	jalr	-634(ra) # 80003a54 <ilock>
  if(ip->type != T_DIR){
    80005cd6:	04449703          	lh	a4,68(s1)
    80005cda:	4785                	li	a5,1
    80005cdc:	04f71063          	bne	a4,a5,80005d1c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ce0:	8526                	mv	a0,s1
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	e34080e7          	jalr	-460(ra) # 80003b16 <iunlock>
  iput(p->cwd);
    80005cea:	16893503          	ld	a0,360(s2)
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	f20080e7          	jalr	-224(ra) # 80003c0e <iput>
  end_op();
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	7a8080e7          	jalr	1960(ra) # 8000449e <end_op>
  p->cwd = ip;
    80005cfe:	16993423          	sd	s1,360(s2)
  return 0;
    80005d02:	4501                	li	a0,0
}
    80005d04:	60ea                	ld	ra,152(sp)
    80005d06:	644a                	ld	s0,144(sp)
    80005d08:	64aa                	ld	s1,136(sp)
    80005d0a:	690a                	ld	s2,128(sp)
    80005d0c:	610d                	addi	sp,sp,160
    80005d0e:	8082                	ret
    end_op();
    80005d10:	ffffe097          	auipc	ra,0xffffe
    80005d14:	78e080e7          	jalr	1934(ra) # 8000449e <end_op>
    return -1;
    80005d18:	557d                	li	a0,-1
    80005d1a:	b7ed                	j	80005d04 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	f98080e7          	jalr	-104(ra) # 80003cb6 <iunlockput>
    end_op();
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	778080e7          	jalr	1912(ra) # 8000449e <end_op>
    return -1;
    80005d2e:	557d                	li	a0,-1
    80005d30:	bfd1                	j	80005d04 <sys_chdir+0x7a>

0000000080005d32 <sys_exec>:

uint64
sys_exec(void)
{
    80005d32:	7145                	addi	sp,sp,-464
    80005d34:	e786                	sd	ra,456(sp)
    80005d36:	e3a2                	sd	s0,448(sp)
    80005d38:	ff26                	sd	s1,440(sp)
    80005d3a:	fb4a                	sd	s2,432(sp)
    80005d3c:	f74e                	sd	s3,424(sp)
    80005d3e:	f352                	sd	s4,416(sp)
    80005d40:	ef56                	sd	s5,408(sp)
    80005d42:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d44:	e3840593          	addi	a1,s0,-456
    80005d48:	4505                	li	a0,1
    80005d4a:	ffffd097          	auipc	ra,0xffffd
    80005d4e:	09c080e7          	jalr	156(ra) # 80002de6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d52:	08000613          	li	a2,128
    80005d56:	f4040593          	addi	a1,s0,-192
    80005d5a:	4501                	li	a0,0
    80005d5c:	ffffd097          	auipc	ra,0xffffd
    80005d60:	0aa080e7          	jalr	170(ra) # 80002e06 <argstr>
    80005d64:	87aa                	mv	a5,a0
    return -1;
    80005d66:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005d68:	0c07c363          	bltz	a5,80005e2e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005d6c:	10000613          	li	a2,256
    80005d70:	4581                	li	a1,0
    80005d72:	e4040513          	addi	a0,s0,-448
    80005d76:	ffffb097          	auipc	ra,0xffffb
    80005d7a:	f5c080e7          	jalr	-164(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d7e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d82:	89a6                	mv	s3,s1
    80005d84:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d86:	02000a13          	li	s4,32
    80005d8a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d8e:	00391513          	slli	a0,s2,0x3
    80005d92:	e3040593          	addi	a1,s0,-464
    80005d96:	e3843783          	ld	a5,-456(s0)
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	ffffd097          	auipc	ra,0xffffd
    80005da0:	f8c080e7          	jalr	-116(ra) # 80002d28 <fetchaddr>
    80005da4:	02054a63          	bltz	a0,80005dd8 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005da8:	e3043783          	ld	a5,-464(s0)
    80005dac:	c3b9                	beqz	a5,80005df2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dae:	ffffb097          	auipc	ra,0xffffb
    80005db2:	d38080e7          	jalr	-712(ra) # 80000ae6 <kalloc>
    80005db6:	85aa                	mv	a1,a0
    80005db8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dbc:	cd11                	beqz	a0,80005dd8 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005dbe:	6605                	lui	a2,0x1
    80005dc0:	e3043503          	ld	a0,-464(s0)
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	fb6080e7          	jalr	-74(ra) # 80002d7a <fetchstr>
    80005dcc:	00054663          	bltz	a0,80005dd8 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005dd0:	0905                	addi	s2,s2,1
    80005dd2:	09a1                	addi	s3,s3,8
    80005dd4:	fb491be3          	bne	s2,s4,80005d8a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dd8:	f4040913          	addi	s2,s0,-192
    80005ddc:	6088                	ld	a0,0(s1)
    80005dde:	c539                	beqz	a0,80005e2c <sys_exec+0xfa>
    kfree(argv[i]);
    80005de0:	ffffb097          	auipc	ra,0xffffb
    80005de4:	c08080e7          	jalr	-1016(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de8:	04a1                	addi	s1,s1,8
    80005dea:	ff2499e3          	bne	s1,s2,80005ddc <sys_exec+0xaa>
  return -1;
    80005dee:	557d                	li	a0,-1
    80005df0:	a83d                	j	80005e2e <sys_exec+0xfc>
      argv[i] = 0;
    80005df2:	0a8e                	slli	s5,s5,0x3
    80005df4:	fc0a8793          	addi	a5,s5,-64
    80005df8:	00878ab3          	add	s5,a5,s0
    80005dfc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e00:	e4040593          	addi	a1,s0,-448
    80005e04:	f4040513          	addi	a0,s0,-192
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	15a080e7          	jalr	346(ra) # 80004f62 <exec>
    80005e10:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e12:	f4040993          	addi	s3,s0,-192
    80005e16:	6088                	ld	a0,0(s1)
    80005e18:	c901                	beqz	a0,80005e28 <sys_exec+0xf6>
    kfree(argv[i]);
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	bce080e7          	jalr	-1074(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e22:	04a1                	addi	s1,s1,8
    80005e24:	ff3499e3          	bne	s1,s3,80005e16 <sys_exec+0xe4>
  return ret;
    80005e28:	854a                	mv	a0,s2
    80005e2a:	a011                	j	80005e2e <sys_exec+0xfc>
  return -1;
    80005e2c:	557d                	li	a0,-1
}
    80005e2e:	60be                	ld	ra,456(sp)
    80005e30:	641e                	ld	s0,448(sp)
    80005e32:	74fa                	ld	s1,440(sp)
    80005e34:	795a                	ld	s2,432(sp)
    80005e36:	79ba                	ld	s3,424(sp)
    80005e38:	7a1a                	ld	s4,416(sp)
    80005e3a:	6afa                	ld	s5,408(sp)
    80005e3c:	6179                	addi	sp,sp,464
    80005e3e:	8082                	ret

0000000080005e40 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e40:	7139                	addi	sp,sp,-64
    80005e42:	fc06                	sd	ra,56(sp)
    80005e44:	f822                	sd	s0,48(sp)
    80005e46:	f426                	sd	s1,40(sp)
    80005e48:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e4a:	ffffc097          	auipc	ra,0xffffc
    80005e4e:	b62080e7          	jalr	-1182(ra) # 800019ac <myproc>
    80005e52:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e54:	fd840593          	addi	a1,s0,-40
    80005e58:	4501                	li	a0,0
    80005e5a:	ffffd097          	auipc	ra,0xffffd
    80005e5e:	f8c080e7          	jalr	-116(ra) # 80002de6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005e62:	fc840593          	addi	a1,s0,-56
    80005e66:	fd040513          	addi	a0,s0,-48
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	dae080e7          	jalr	-594(ra) # 80004c18 <pipealloc>
    return -1;
    80005e72:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e74:	0c054463          	bltz	a0,80005f3c <sys_pipe+0xfc>
  fd0 = -1;
    80005e78:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e7c:	fd043503          	ld	a0,-48(s0)
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	500080e7          	jalr	1280(ra) # 80005380 <fdalloc>
    80005e88:	fca42223          	sw	a0,-60(s0)
    80005e8c:	08054b63          	bltz	a0,80005f22 <sys_pipe+0xe2>
    80005e90:	fc843503          	ld	a0,-56(s0)
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	4ec080e7          	jalr	1260(ra) # 80005380 <fdalloc>
    80005e9c:	fca42023          	sw	a0,-64(s0)
    80005ea0:	06054863          	bltz	a0,80005f10 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ea4:	4691                	li	a3,4
    80005ea6:	fc440613          	addi	a2,s0,-60
    80005eaa:	fd843583          	ld	a1,-40(s0)
    80005eae:	74a8                	ld	a0,104(s1)
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	7bc080e7          	jalr	1980(ra) # 8000166c <copyout>
    80005eb8:	02054063          	bltz	a0,80005ed8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ebc:	4691                	li	a3,4
    80005ebe:	fc040613          	addi	a2,s0,-64
    80005ec2:	fd843583          	ld	a1,-40(s0)
    80005ec6:	0591                	addi	a1,a1,4
    80005ec8:	74a8                	ld	a0,104(s1)
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	7a2080e7          	jalr	1954(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ed2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ed4:	06055463          	bgez	a0,80005f3c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005ed8:	fc442783          	lw	a5,-60(s0)
    80005edc:	07f1                	addi	a5,a5,28
    80005ede:	078e                	slli	a5,a5,0x3
    80005ee0:	97a6                	add	a5,a5,s1
    80005ee2:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005ee6:	fc042783          	lw	a5,-64(s0)
    80005eea:	07f1                	addi	a5,a5,28
    80005eec:	078e                	slli	a5,a5,0x3
    80005eee:	94be                	add	s1,s1,a5
    80005ef0:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005ef4:	fd043503          	ld	a0,-48(s0)
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	9f0080e7          	jalr	-1552(ra) # 800048e8 <fileclose>
    fileclose(wf);
    80005f00:	fc843503          	ld	a0,-56(s0)
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	9e4080e7          	jalr	-1564(ra) # 800048e8 <fileclose>
    return -1;
    80005f0c:	57fd                	li	a5,-1
    80005f0e:	a03d                	j	80005f3c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f10:	fc442783          	lw	a5,-60(s0)
    80005f14:	0007c763          	bltz	a5,80005f22 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f18:	07f1                	addi	a5,a5,28
    80005f1a:	078e                	slli	a5,a5,0x3
    80005f1c:	97a6                	add	a5,a5,s1
    80005f1e:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005f22:	fd043503          	ld	a0,-48(s0)
    80005f26:	fffff097          	auipc	ra,0xfffff
    80005f2a:	9c2080e7          	jalr	-1598(ra) # 800048e8 <fileclose>
    fileclose(wf);
    80005f2e:	fc843503          	ld	a0,-56(s0)
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	9b6080e7          	jalr	-1610(ra) # 800048e8 <fileclose>
    return -1;
    80005f3a:	57fd                	li	a5,-1
}
    80005f3c:	853e                	mv	a0,a5
    80005f3e:	70e2                	ld	ra,56(sp)
    80005f40:	7442                	ld	s0,48(sp)
    80005f42:	74a2                	ld	s1,40(sp)
    80005f44:	6121                	addi	sp,sp,64
    80005f46:	8082                	ret
	...

0000000080005f50 <kernelvec>:
    80005f50:	7111                	addi	sp,sp,-256
    80005f52:	e006                	sd	ra,0(sp)
    80005f54:	e40a                	sd	sp,8(sp)
    80005f56:	e80e                	sd	gp,16(sp)
    80005f58:	ec12                	sd	tp,24(sp)
    80005f5a:	f016                	sd	t0,32(sp)
    80005f5c:	f41a                	sd	t1,40(sp)
    80005f5e:	f81e                	sd	t2,48(sp)
    80005f60:	fc22                	sd	s0,56(sp)
    80005f62:	e0a6                	sd	s1,64(sp)
    80005f64:	e4aa                	sd	a0,72(sp)
    80005f66:	e8ae                	sd	a1,80(sp)
    80005f68:	ecb2                	sd	a2,88(sp)
    80005f6a:	f0b6                	sd	a3,96(sp)
    80005f6c:	f4ba                	sd	a4,104(sp)
    80005f6e:	f8be                	sd	a5,112(sp)
    80005f70:	fcc2                	sd	a6,120(sp)
    80005f72:	e146                	sd	a7,128(sp)
    80005f74:	e54a                	sd	s2,136(sp)
    80005f76:	e94e                	sd	s3,144(sp)
    80005f78:	ed52                	sd	s4,152(sp)
    80005f7a:	f156                	sd	s5,160(sp)
    80005f7c:	f55a                	sd	s6,168(sp)
    80005f7e:	f95e                	sd	s7,176(sp)
    80005f80:	fd62                	sd	s8,184(sp)
    80005f82:	e1e6                	sd	s9,192(sp)
    80005f84:	e5ea                	sd	s10,200(sp)
    80005f86:	e9ee                	sd	s11,208(sp)
    80005f88:	edf2                	sd	t3,216(sp)
    80005f8a:	f1f6                	sd	t4,224(sp)
    80005f8c:	f5fa                	sd	t5,232(sp)
    80005f8e:	f9fe                	sd	t6,240(sp)
    80005f90:	c75fc0ef          	jal	ra,80002c04 <kerneltrap>
    80005f94:	6082                	ld	ra,0(sp)
    80005f96:	6122                	ld	sp,8(sp)
    80005f98:	61c2                	ld	gp,16(sp)
    80005f9a:	7282                	ld	t0,32(sp)
    80005f9c:	7322                	ld	t1,40(sp)
    80005f9e:	73c2                	ld	t2,48(sp)
    80005fa0:	7462                	ld	s0,56(sp)
    80005fa2:	6486                	ld	s1,64(sp)
    80005fa4:	6526                	ld	a0,72(sp)
    80005fa6:	65c6                	ld	a1,80(sp)
    80005fa8:	6666                	ld	a2,88(sp)
    80005faa:	7686                	ld	a3,96(sp)
    80005fac:	7726                	ld	a4,104(sp)
    80005fae:	77c6                	ld	a5,112(sp)
    80005fb0:	7866                	ld	a6,120(sp)
    80005fb2:	688a                	ld	a7,128(sp)
    80005fb4:	692a                	ld	s2,136(sp)
    80005fb6:	69ca                	ld	s3,144(sp)
    80005fb8:	6a6a                	ld	s4,152(sp)
    80005fba:	7a8a                	ld	s5,160(sp)
    80005fbc:	7b2a                	ld	s6,168(sp)
    80005fbe:	7bca                	ld	s7,176(sp)
    80005fc0:	7c6a                	ld	s8,184(sp)
    80005fc2:	6c8e                	ld	s9,192(sp)
    80005fc4:	6d2e                	ld	s10,200(sp)
    80005fc6:	6dce                	ld	s11,208(sp)
    80005fc8:	6e6e                	ld	t3,216(sp)
    80005fca:	7e8e                	ld	t4,224(sp)
    80005fcc:	7f2e                	ld	t5,232(sp)
    80005fce:	7fce                	ld	t6,240(sp)
    80005fd0:	6111                	addi	sp,sp,256
    80005fd2:	10200073          	sret
    80005fd6:	00000013          	nop
    80005fda:	00000013          	nop
    80005fde:	0001                	nop

0000000080005fe0 <timervec>:
    80005fe0:	34051573          	csrrw	a0,mscratch,a0
    80005fe4:	e10c                	sd	a1,0(a0)
    80005fe6:	e510                	sd	a2,8(a0)
    80005fe8:	e914                	sd	a3,16(a0)
    80005fea:	6d0c                	ld	a1,24(a0)
    80005fec:	7110                	ld	a2,32(a0)
    80005fee:	6194                	ld	a3,0(a1)
    80005ff0:	96b2                	add	a3,a3,a2
    80005ff2:	e194                	sd	a3,0(a1)
    80005ff4:	4589                	li	a1,2
    80005ff6:	14459073          	csrw	sip,a1
    80005ffa:	6914                	ld	a3,16(a0)
    80005ffc:	6510                	ld	a2,8(a0)
    80005ffe:	610c                	ld	a1,0(a0)
    80006000:	34051573          	csrrw	a0,mscratch,a0
    80006004:	30200073          	mret
	...

000000008000600a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000600a:	1141                	addi	sp,sp,-16
    8000600c:	e422                	sd	s0,8(sp)
    8000600e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006010:	0c0007b7          	lui	a5,0xc000
    80006014:	4705                	li	a4,1
    80006016:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006018:	c3d8                	sw	a4,4(a5)
}
    8000601a:	6422                	ld	s0,8(sp)
    8000601c:	0141                	addi	sp,sp,16
    8000601e:	8082                	ret

0000000080006020 <plicinithart>:

void
plicinithart(void)
{
    80006020:	1141                	addi	sp,sp,-16
    80006022:	e406                	sd	ra,8(sp)
    80006024:	e022                	sd	s0,0(sp)
    80006026:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006028:	ffffc097          	auipc	ra,0xffffc
    8000602c:	958080e7          	jalr	-1704(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006030:	0085171b          	slliw	a4,a0,0x8
    80006034:	0c0027b7          	lui	a5,0xc002
    80006038:	97ba                	add	a5,a5,a4
    8000603a:	40200713          	li	a4,1026
    8000603e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006042:	00d5151b          	slliw	a0,a0,0xd
    80006046:	0c2017b7          	lui	a5,0xc201
    8000604a:	97aa                	add	a5,a5,a0
    8000604c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006050:	60a2                	ld	ra,8(sp)
    80006052:	6402                	ld	s0,0(sp)
    80006054:	0141                	addi	sp,sp,16
    80006056:	8082                	ret

0000000080006058 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006058:	1141                	addi	sp,sp,-16
    8000605a:	e406                	sd	ra,8(sp)
    8000605c:	e022                	sd	s0,0(sp)
    8000605e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006060:	ffffc097          	auipc	ra,0xffffc
    80006064:	920080e7          	jalr	-1760(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006068:	00d5151b          	slliw	a0,a0,0xd
    8000606c:	0c2017b7          	lui	a5,0xc201
    80006070:	97aa                	add	a5,a5,a0
  return irq;
}
    80006072:	43c8                	lw	a0,4(a5)
    80006074:	60a2                	ld	ra,8(sp)
    80006076:	6402                	ld	s0,0(sp)
    80006078:	0141                	addi	sp,sp,16
    8000607a:	8082                	ret

000000008000607c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000607c:	1101                	addi	sp,sp,-32
    8000607e:	ec06                	sd	ra,24(sp)
    80006080:	e822                	sd	s0,16(sp)
    80006082:	e426                	sd	s1,8(sp)
    80006084:	1000                	addi	s0,sp,32
    80006086:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	8f8080e7          	jalr	-1800(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006090:	00d5151b          	slliw	a0,a0,0xd
    80006094:	0c2017b7          	lui	a5,0xc201
    80006098:	97aa                	add	a5,a5,a0
    8000609a:	c3c4                	sw	s1,4(a5)
}
    8000609c:	60e2                	ld	ra,24(sp)
    8000609e:	6442                	ld	s0,16(sp)
    800060a0:	64a2                	ld	s1,8(sp)
    800060a2:	6105                	addi	sp,sp,32
    800060a4:	8082                	ret

00000000800060a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060a6:	1141                	addi	sp,sp,-16
    800060a8:	e406                	sd	ra,8(sp)
    800060aa:	e022                	sd	s0,0(sp)
    800060ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ae:	479d                	li	a5,7
    800060b0:	04a7cc63          	blt	a5,a0,80006108 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800060b4:	0001d797          	auipc	a5,0x1d
    800060b8:	9ac78793          	addi	a5,a5,-1620 # 80022a60 <disk>
    800060bc:	97aa                	add	a5,a5,a0
    800060be:	0187c783          	lbu	a5,24(a5)
    800060c2:	ebb9                	bnez	a5,80006118 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060c4:	00451693          	slli	a3,a0,0x4
    800060c8:	0001d797          	auipc	a5,0x1d
    800060cc:	99878793          	addi	a5,a5,-1640 # 80022a60 <disk>
    800060d0:	6398                	ld	a4,0(a5)
    800060d2:	9736                	add	a4,a4,a3
    800060d4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800060d8:	6398                	ld	a4,0(a5)
    800060da:	9736                	add	a4,a4,a3
    800060dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800060e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800060e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800060e8:	97aa                	add	a5,a5,a0
    800060ea:	4705                	li	a4,1
    800060ec:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800060f0:	0001d517          	auipc	a0,0x1d
    800060f4:	98850513          	addi	a0,a0,-1656 # 80022a78 <disk+0x18>
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	05a080e7          	jalr	90(ra) # 80002152 <wakeup>
}
    80006100:	60a2                	ld	ra,8(sp)
    80006102:	6402                	ld	s0,0(sp)
    80006104:	0141                	addi	sp,sp,16
    80006106:	8082                	ret
    panic("free_desc 1");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	66050513          	addi	a0,a0,1632 # 80008768 <syscalls+0x310>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	430080e7          	jalr	1072(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006118:	00002517          	auipc	a0,0x2
    8000611c:	66050513          	addi	a0,a0,1632 # 80008778 <syscalls+0x320>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	420080e7          	jalr	1056(ra) # 80000540 <panic>

0000000080006128 <virtio_disk_init>:
{
    80006128:	1101                	addi	sp,sp,-32
    8000612a:	ec06                	sd	ra,24(sp)
    8000612c:	e822                	sd	s0,16(sp)
    8000612e:	e426                	sd	s1,8(sp)
    80006130:	e04a                	sd	s2,0(sp)
    80006132:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006134:	00002597          	auipc	a1,0x2
    80006138:	65458593          	addi	a1,a1,1620 # 80008788 <syscalls+0x330>
    8000613c:	0001d517          	auipc	a0,0x1d
    80006140:	a4c50513          	addi	a0,a0,-1460 # 80022b88 <disk+0x128>
    80006144:	ffffb097          	auipc	ra,0xffffb
    80006148:	a02080e7          	jalr	-1534(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000614c:	100017b7          	lui	a5,0x10001
    80006150:	4398                	lw	a4,0(a5)
    80006152:	2701                	sext.w	a4,a4
    80006154:	747277b7          	lui	a5,0x74727
    80006158:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000615c:	14f71b63          	bne	a4,a5,800062b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006160:	100017b7          	lui	a5,0x10001
    80006164:	43dc                	lw	a5,4(a5)
    80006166:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006168:	4709                	li	a4,2
    8000616a:	14e79463          	bne	a5,a4,800062b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000616e:	100017b7          	lui	a5,0x10001
    80006172:	479c                	lw	a5,8(a5)
    80006174:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006176:	12e79e63          	bne	a5,a4,800062b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000617a:	100017b7          	lui	a5,0x10001
    8000617e:	47d8                	lw	a4,12(a5)
    80006180:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006182:	554d47b7          	lui	a5,0x554d4
    80006186:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000618a:	12f71463          	bne	a4,a5,800062b2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000618e:	100017b7          	lui	a5,0x10001
    80006192:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006196:	4705                	li	a4,1
    80006198:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000619a:	470d                	li	a4,3
    8000619c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000619e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061a0:	c7ffe6b7          	lui	a3,0xc7ffe
    800061a4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbbbf>
    800061a8:	8f75                	and	a4,a4,a3
    800061aa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ac:	472d                	li	a4,11
    800061ae:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800061b0:	5bbc                	lw	a5,112(a5)
    800061b2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800061b6:	8ba1                	andi	a5,a5,8
    800061b8:	10078563          	beqz	a5,800062c2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061bc:	100017b7          	lui	a5,0x10001
    800061c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800061c4:	43fc                	lw	a5,68(a5)
    800061c6:	2781                	sext.w	a5,a5
    800061c8:	10079563          	bnez	a5,800062d2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061cc:	100017b7          	lui	a5,0x10001
    800061d0:	5bdc                	lw	a5,52(a5)
    800061d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800061d4:	10078763          	beqz	a5,800062e2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800061d8:	471d                	li	a4,7
    800061da:	10f77c63          	bgeu	a4,a5,800062f2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	908080e7          	jalr	-1784(ra) # 80000ae6 <kalloc>
    800061e6:	0001d497          	auipc	s1,0x1d
    800061ea:	87a48493          	addi	s1,s1,-1926 # 80022a60 <disk>
    800061ee:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	8f6080e7          	jalr	-1802(ra) # 80000ae6 <kalloc>
    800061f8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	8ec080e7          	jalr	-1812(ra) # 80000ae6 <kalloc>
    80006202:	87aa                	mv	a5,a0
    80006204:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006206:	6088                	ld	a0,0(s1)
    80006208:	cd6d                	beqz	a0,80006302 <virtio_disk_init+0x1da>
    8000620a:	0001d717          	auipc	a4,0x1d
    8000620e:	85e73703          	ld	a4,-1954(a4) # 80022a68 <disk+0x8>
    80006212:	cb65                	beqz	a4,80006302 <virtio_disk_init+0x1da>
    80006214:	c7fd                	beqz	a5,80006302 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006216:	6605                	lui	a2,0x1
    80006218:	4581                	li	a1,0
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	ab8080e7          	jalr	-1352(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006222:	0001d497          	auipc	s1,0x1d
    80006226:	83e48493          	addi	s1,s1,-1986 # 80022a60 <disk>
    8000622a:	6605                	lui	a2,0x1
    8000622c:	4581                	li	a1,0
    8000622e:	6488                	ld	a0,8(s1)
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	aa2080e7          	jalr	-1374(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006238:	6605                	lui	a2,0x1
    8000623a:	4581                	li	a1,0
    8000623c:	6888                	ld	a0,16(s1)
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	a94080e7          	jalr	-1388(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006246:	100017b7          	lui	a5,0x10001
    8000624a:	4721                	li	a4,8
    8000624c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000624e:	4098                	lw	a4,0(s1)
    80006250:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006254:	40d8                	lw	a4,4(s1)
    80006256:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000625a:	6498                	ld	a4,8(s1)
    8000625c:	0007069b          	sext.w	a3,a4
    80006260:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006264:	9701                	srai	a4,a4,0x20
    80006266:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000626a:	6898                	ld	a4,16(s1)
    8000626c:	0007069b          	sext.w	a3,a4
    80006270:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006274:	9701                	srai	a4,a4,0x20
    80006276:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000627a:	4705                	li	a4,1
    8000627c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000627e:	00e48c23          	sb	a4,24(s1)
    80006282:	00e48ca3          	sb	a4,25(s1)
    80006286:	00e48d23          	sb	a4,26(s1)
    8000628a:	00e48da3          	sb	a4,27(s1)
    8000628e:	00e48e23          	sb	a4,28(s1)
    80006292:	00e48ea3          	sb	a4,29(s1)
    80006296:	00e48f23          	sb	a4,30(s1)
    8000629a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000629e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800062a2:	0727a823          	sw	s2,112(a5)
}
    800062a6:	60e2                	ld	ra,24(sp)
    800062a8:	6442                	ld	s0,16(sp)
    800062aa:	64a2                	ld	s1,8(sp)
    800062ac:	6902                	ld	s2,0(sp)
    800062ae:	6105                	addi	sp,sp,32
    800062b0:	8082                	ret
    panic("could not find virtio disk");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	4e650513          	addi	a0,a0,1254 # 80008798 <syscalls+0x340>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	286080e7          	jalr	646(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800062c2:	00002517          	auipc	a0,0x2
    800062c6:	4f650513          	addi	a0,a0,1270 # 800087b8 <syscalls+0x360>
    800062ca:	ffffa097          	auipc	ra,0xffffa
    800062ce:	276080e7          	jalr	630(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800062d2:	00002517          	auipc	a0,0x2
    800062d6:	50650513          	addi	a0,a0,1286 # 800087d8 <syscalls+0x380>
    800062da:	ffffa097          	auipc	ra,0xffffa
    800062de:	266080e7          	jalr	614(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	51650513          	addi	a0,a0,1302 # 800087f8 <syscalls+0x3a0>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	256080e7          	jalr	598(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800062f2:	00002517          	auipc	a0,0x2
    800062f6:	52650513          	addi	a0,a0,1318 # 80008818 <syscalls+0x3c0>
    800062fa:	ffffa097          	auipc	ra,0xffffa
    800062fe:	246080e7          	jalr	582(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006302:	00002517          	auipc	a0,0x2
    80006306:	53650513          	addi	a0,a0,1334 # 80008838 <syscalls+0x3e0>
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	236080e7          	jalr	566(ra) # 80000540 <panic>

0000000080006312 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006312:	7119                	addi	sp,sp,-128
    80006314:	fc86                	sd	ra,120(sp)
    80006316:	f8a2                	sd	s0,112(sp)
    80006318:	f4a6                	sd	s1,104(sp)
    8000631a:	f0ca                	sd	s2,96(sp)
    8000631c:	ecce                	sd	s3,88(sp)
    8000631e:	e8d2                	sd	s4,80(sp)
    80006320:	e4d6                	sd	s5,72(sp)
    80006322:	e0da                	sd	s6,64(sp)
    80006324:	fc5e                	sd	s7,56(sp)
    80006326:	f862                	sd	s8,48(sp)
    80006328:	f466                	sd	s9,40(sp)
    8000632a:	f06a                	sd	s10,32(sp)
    8000632c:	ec6e                	sd	s11,24(sp)
    8000632e:	0100                	addi	s0,sp,128
    80006330:	8aaa                	mv	s5,a0
    80006332:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006334:	00c52d03          	lw	s10,12(a0)
    80006338:	001d1d1b          	slliw	s10,s10,0x1
    8000633c:	1d02                	slli	s10,s10,0x20
    8000633e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006342:	0001d517          	auipc	a0,0x1d
    80006346:	84650513          	addi	a0,a0,-1978 # 80022b88 <disk+0x128>
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	88c080e7          	jalr	-1908(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006352:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006354:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006356:	0001cb97          	auipc	s7,0x1c
    8000635a:	70ab8b93          	addi	s7,s7,1802 # 80022a60 <disk>
  for(int i = 0; i < 3; i++){
    8000635e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006360:	0001dc97          	auipc	s9,0x1d
    80006364:	828c8c93          	addi	s9,s9,-2008 # 80022b88 <disk+0x128>
    80006368:	a08d                	j	800063ca <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000636a:	00fb8733          	add	a4,s7,a5
    8000636e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006372:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006374:	0207c563          	bltz	a5,8000639e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006378:	2905                	addiw	s2,s2,1
    8000637a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000637c:	05690c63          	beq	s2,s6,800063d4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006380:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006382:	0001c717          	auipc	a4,0x1c
    80006386:	6de70713          	addi	a4,a4,1758 # 80022a60 <disk>
    8000638a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000638c:	01874683          	lbu	a3,24(a4)
    80006390:	fee9                	bnez	a3,8000636a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006392:	2785                	addiw	a5,a5,1
    80006394:	0705                	addi	a4,a4,1
    80006396:	fe979be3          	bne	a5,s1,8000638c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000639a:	57fd                	li	a5,-1
    8000639c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000639e:	01205d63          	blez	s2,800063b8 <virtio_disk_rw+0xa6>
    800063a2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063a4:	000a2503          	lw	a0,0(s4)
    800063a8:	00000097          	auipc	ra,0x0
    800063ac:	cfe080e7          	jalr	-770(ra) # 800060a6 <free_desc>
      for(int j = 0; j < i; j++)
    800063b0:	2d85                	addiw	s11,s11,1
    800063b2:	0a11                	addi	s4,s4,4
    800063b4:	ff2d98e3          	bne	s11,s2,800063a4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063b8:	85e6                	mv	a1,s9
    800063ba:	0001c517          	auipc	a0,0x1c
    800063be:	6be50513          	addi	a0,a0,1726 # 80022a78 <disk+0x18>
    800063c2:	ffffc097          	auipc	ra,0xffffc
    800063c6:	d2c080e7          	jalr	-724(ra) # 800020ee <sleep>
  for(int i = 0; i < 3; i++){
    800063ca:	f8040a13          	addi	s4,s0,-128
{
    800063ce:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800063d0:	894e                	mv	s2,s3
    800063d2:	b77d                	j	80006380 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063d4:	f8042503          	lw	a0,-128(s0)
    800063d8:	00a50713          	addi	a4,a0,10
    800063dc:	0712                	slli	a4,a4,0x4

  if(write)
    800063de:	0001c797          	auipc	a5,0x1c
    800063e2:	68278793          	addi	a5,a5,1666 # 80022a60 <disk>
    800063e6:	00e786b3          	add	a3,a5,a4
    800063ea:	01803633          	snez	a2,s8
    800063ee:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063f0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800063f4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063f8:	f6070613          	addi	a2,a4,-160
    800063fc:	6394                	ld	a3,0(a5)
    800063fe:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006400:	00870593          	addi	a1,a4,8
    80006404:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006406:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006408:	0007b803          	ld	a6,0(a5)
    8000640c:	9642                	add	a2,a2,a6
    8000640e:	46c1                	li	a3,16
    80006410:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006412:	4585                	li	a1,1
    80006414:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006418:	f8442683          	lw	a3,-124(s0)
    8000641c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006420:	0692                	slli	a3,a3,0x4
    80006422:	9836                	add	a6,a6,a3
    80006424:	058a8613          	addi	a2,s5,88
    80006428:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000642c:	0007b803          	ld	a6,0(a5)
    80006430:	96c2                	add	a3,a3,a6
    80006432:	40000613          	li	a2,1024
    80006436:	c690                	sw	a2,8(a3)
  if(write)
    80006438:	001c3613          	seqz	a2,s8
    8000643c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006440:	00166613          	ori	a2,a2,1
    80006444:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006448:	f8842603          	lw	a2,-120(s0)
    8000644c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006450:	00250693          	addi	a3,a0,2
    80006454:	0692                	slli	a3,a3,0x4
    80006456:	96be                	add	a3,a3,a5
    80006458:	58fd                	li	a7,-1
    8000645a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000645e:	0612                	slli	a2,a2,0x4
    80006460:	9832                	add	a6,a6,a2
    80006462:	f9070713          	addi	a4,a4,-112
    80006466:	973e                	add	a4,a4,a5
    80006468:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000646c:	6398                	ld	a4,0(a5)
    8000646e:	9732                	add	a4,a4,a2
    80006470:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006472:	4609                	li	a2,2
    80006474:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006478:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000647c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006480:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006484:	6794                	ld	a3,8(a5)
    80006486:	0026d703          	lhu	a4,2(a3)
    8000648a:	8b1d                	andi	a4,a4,7
    8000648c:	0706                	slli	a4,a4,0x1
    8000648e:	96ba                	add	a3,a3,a4
    80006490:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006494:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006498:	6798                	ld	a4,8(a5)
    8000649a:	00275783          	lhu	a5,2(a4)
    8000649e:	2785                	addiw	a5,a5,1
    800064a0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064a4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064a8:	100017b7          	lui	a5,0x10001
    800064ac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064b0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800064b4:	0001c917          	auipc	s2,0x1c
    800064b8:	6d490913          	addi	s2,s2,1748 # 80022b88 <disk+0x128>
  while(b->disk == 1) {
    800064bc:	4485                	li	s1,1
    800064be:	00b79c63          	bne	a5,a1,800064d6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800064c2:	85ca                	mv	a1,s2
    800064c4:	8556                	mv	a0,s5
    800064c6:	ffffc097          	auipc	ra,0xffffc
    800064ca:	c28080e7          	jalr	-984(ra) # 800020ee <sleep>
  while(b->disk == 1) {
    800064ce:	004aa783          	lw	a5,4(s5)
    800064d2:	fe9788e3          	beq	a5,s1,800064c2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800064d6:	f8042903          	lw	s2,-128(s0)
    800064da:	00290713          	addi	a4,s2,2
    800064de:	0712                	slli	a4,a4,0x4
    800064e0:	0001c797          	auipc	a5,0x1c
    800064e4:	58078793          	addi	a5,a5,1408 # 80022a60 <disk>
    800064e8:	97ba                	add	a5,a5,a4
    800064ea:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800064ee:	0001c997          	auipc	s3,0x1c
    800064f2:	57298993          	addi	s3,s3,1394 # 80022a60 <disk>
    800064f6:	00491713          	slli	a4,s2,0x4
    800064fa:	0009b783          	ld	a5,0(s3)
    800064fe:	97ba                	add	a5,a5,a4
    80006500:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006504:	854a                	mv	a0,s2
    80006506:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000650a:	00000097          	auipc	ra,0x0
    8000650e:	b9c080e7          	jalr	-1124(ra) # 800060a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006512:	8885                	andi	s1,s1,1
    80006514:	f0ed                	bnez	s1,800064f6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006516:	0001c517          	auipc	a0,0x1c
    8000651a:	67250513          	addi	a0,a0,1650 # 80022b88 <disk+0x128>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	76c080e7          	jalr	1900(ra) # 80000c8a <release>
}
    80006526:	70e6                	ld	ra,120(sp)
    80006528:	7446                	ld	s0,112(sp)
    8000652a:	74a6                	ld	s1,104(sp)
    8000652c:	7906                	ld	s2,96(sp)
    8000652e:	69e6                	ld	s3,88(sp)
    80006530:	6a46                	ld	s4,80(sp)
    80006532:	6aa6                	ld	s5,72(sp)
    80006534:	6b06                	ld	s6,64(sp)
    80006536:	7be2                	ld	s7,56(sp)
    80006538:	7c42                	ld	s8,48(sp)
    8000653a:	7ca2                	ld	s9,40(sp)
    8000653c:	7d02                	ld	s10,32(sp)
    8000653e:	6de2                	ld	s11,24(sp)
    80006540:	6109                	addi	sp,sp,128
    80006542:	8082                	ret

0000000080006544 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006544:	1101                	addi	sp,sp,-32
    80006546:	ec06                	sd	ra,24(sp)
    80006548:	e822                	sd	s0,16(sp)
    8000654a:	e426                	sd	s1,8(sp)
    8000654c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000654e:	0001c497          	auipc	s1,0x1c
    80006552:	51248493          	addi	s1,s1,1298 # 80022a60 <disk>
    80006556:	0001c517          	auipc	a0,0x1c
    8000655a:	63250513          	addi	a0,a0,1586 # 80022b88 <disk+0x128>
    8000655e:	ffffa097          	auipc	ra,0xffffa
    80006562:	678080e7          	jalr	1656(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006566:	10001737          	lui	a4,0x10001
    8000656a:	533c                	lw	a5,96(a4)
    8000656c:	8b8d                	andi	a5,a5,3
    8000656e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006570:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006574:	689c                	ld	a5,16(s1)
    80006576:	0204d703          	lhu	a4,32(s1)
    8000657a:	0027d783          	lhu	a5,2(a5)
    8000657e:	04f70863          	beq	a4,a5,800065ce <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006582:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006586:	6898                	ld	a4,16(s1)
    80006588:	0204d783          	lhu	a5,32(s1)
    8000658c:	8b9d                	andi	a5,a5,7
    8000658e:	078e                	slli	a5,a5,0x3
    80006590:	97ba                	add	a5,a5,a4
    80006592:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006594:	00278713          	addi	a4,a5,2
    80006598:	0712                	slli	a4,a4,0x4
    8000659a:	9726                	add	a4,a4,s1
    8000659c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800065a0:	e721                	bnez	a4,800065e8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065a2:	0789                	addi	a5,a5,2
    800065a4:	0792                	slli	a5,a5,0x4
    800065a6:	97a6                	add	a5,a5,s1
    800065a8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800065aa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065ae:	ffffc097          	auipc	ra,0xffffc
    800065b2:	ba4080e7          	jalr	-1116(ra) # 80002152 <wakeup>

    disk.used_idx += 1;
    800065b6:	0204d783          	lhu	a5,32(s1)
    800065ba:	2785                	addiw	a5,a5,1
    800065bc:	17c2                	slli	a5,a5,0x30
    800065be:	93c1                	srli	a5,a5,0x30
    800065c0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065c4:	6898                	ld	a4,16(s1)
    800065c6:	00275703          	lhu	a4,2(a4)
    800065ca:	faf71ce3          	bne	a4,a5,80006582 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065ce:	0001c517          	auipc	a0,0x1c
    800065d2:	5ba50513          	addi	a0,a0,1466 # 80022b88 <disk+0x128>
    800065d6:	ffffa097          	auipc	ra,0xffffa
    800065da:	6b4080e7          	jalr	1716(ra) # 80000c8a <release>
}
    800065de:	60e2                	ld	ra,24(sp)
    800065e0:	6442                	ld	s0,16(sp)
    800065e2:	64a2                	ld	s1,8(sp)
    800065e4:	6105                	addi	sp,sp,32
    800065e6:	8082                	ret
      panic("virtio_disk_intr status");
    800065e8:	00002517          	auipc	a0,0x2
    800065ec:	26850513          	addi	a0,a0,616 # 80008850 <syscalls+0x3f8>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	f50080e7          	jalr	-176(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
