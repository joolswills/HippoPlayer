���� _� �� �G �   � ǧ �p �a  v	incdir	include:
	include	exec/exec_lib.i
	include	exec/memory.i
	include	mucro.i


ver	macro
	dc.b	"v2.45 (10.1.2000)"
	endm	

	lea	CHECKSTART(pc),a0	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#8,d2
q	move.b	(a0)+,d1
	neg.b	d1
	add	d1,d0
	add	d2,d0
	addq	#1,d2
	cmp.b	#$ff,(a0)
	bne.b	q
;	rts




TABSIZE		=	256
CRC_32          =	$edb88320    * CRC-32 polynomial *
INITCRC		=	$ffffffff

	push	d0


	lea	CHECKSTART,a0
	move.l	#CHECKEND-CHECKSTART,d0
	bsr.b	crc

	move.l	d7,d0	* CRC

	pop	d1

	rts





crc
	pushm	d0/a0

	move.l	#TABSIZE*4,d0
	moveq	#MEMF_PUBLIC,d1
	move.l	4.w,a6
	lob	AllocMem
	move.l	d0,a3

** make crc table

	move.l	a3,a0
	moveq	#0,d4
.loop
	move.l	d4,d0
	moveq	#0,d1		* accum = 0
	lsl.l	#1,d0		* item <<=1
	moveq	#8-1,d2		* for (i = 8;  i > 0;  i--) {
.loop2	lsr.l	#1,d0		* item >>=1
	move.l	d0,d3
	eor.l	d1,d3
	and	#1,d3		* if ((item ^ accum) & 0x0001)
	beq.b	.else
	lsr.l	#1,d1
	eor.l	#CRC_32,d1	* accum = (accum >> 1) ^ CRC_32;
	bra.b	.o
.else	lsr.l	#1,d1		* accum>>=1
.o	dbf	d2,.loop2

	move.l	d1,(a0)+
	addq	#1,d4
	cmp	#TABSIZE,d4
	bne.b	.loop

	popm	d0/a0

** calc crc
	moveq	#INITCRC,d7
	move.l	#$ff,d1
.oop
	move.l	d7,d6
	lsr.l	#8,d6

	move.b	(a0)+,d5
	eor.l	d7,d5
	and.l	d1,d5
	lsl.l	#2,d5
	move.l	(a3,d5),d5
	eor.l	d5,d6
	move.l	d6,d7


	subq.l	#1,d0
	bne.b	.oop

	move.l	a3,a1
	move.l	#4*TABSIZE,d0
	lob	FreeMem
	rts	


*******************888


CHECKSTART
CHECKSUM	=	43524


procname	
reqtitle
windowname1
	dc.b	"HippoPlayer",0

about_tt
 
 dc.b "This program is registered to          ",10,3
 dc.b "%39s",10,3
 dc.b "���������������������������������������",10,3
 dc.b " List has %5ld files,  %5ld dividers ",10,3
 dc.b 0


scrtit	dc.b	"HippoPlayer - Copyright � 1994-2000 K-P Koljonen",0
	dc.b	"$VER: "
banner_t
	dc.b	"HippoPlayer "
	ver
	dc.b	10,"Programmed by K-P Koljonen",0

regtext_t dc.b	"Registered to",0
no_one	 dc.b	"   no-one",0


about_t
 dc.b "���������������������������������������",10,3
 dc.b "���  HippoPlayer v2.45  (10.1.2000) ���",10,3
 dc.b "��          by K-P Koljonen          ��",10,3
 dc.b "���       Hippopotamus Design       ���",10,3
 dc.b "���������������������������������������",10,3

about_t1
 dc.b "    This program is not registered!    ",10,3
 dc.b "You should register to support quality ",10,3
 dc.b "    software and to reward the poor    ",10,3
 dc.b "       author from his hard work.      ",10,3
  
 dc.b "���������������������������������������",10,3
 dc.b " HippoPlayer can be freely distributed",10,3
 dc.b " as long as all the files are included",10,3
 dc.b "   unaltered. Not for commercial use",10,3
 dc.b " without a permission from the author.",10,3
 dc.b " Copyright � 1994-2000 by K-P Koljonen",10,3
 dc.b "           *** SHAREWARE ***",10,3
 dc.b "���������������������������������������",10,3
 dc.b "Snail mail: Kari-Pekka Koljonen",10,3
 dc.b "            Torikatu 31",10,3
 dc.b "            FIN-40900 S�yn�tsalo",10,3
 dc.b "            Finland",10,3
 dc.b 10,3
 dc.b "E-mail:     kpk@cc.tut.fi",10,3
 dc.b "            k-p@s2.org",10,3
 dc.b 10,3
 dc.b "WWW:        www.students.tut.fi/~kpk",10,3
 dc.b "IRC:        K-P",10,3,10,3
 dc.b "���������������������������������������",10,3
 dc.b "    Hippopothamos the river-horse",10,3
 dc.b "    Hippopotamus  amphibius:   a  large",10,3
 dc.b "herbivorous   mammal,  having  a  thick",10,3
 dc.b "hairless  body, short legs, and a large",10,3
 dc.b "head and muzzle.",10,3
 dc.b "    Hippopotami  live in the rivers and",10,3
 dc.b "lakes  of  Africa.  A hippo weighs 2500",10,3
 dc.b "kilos, is 140-160 cm high and 4 m long.",10,3
 dc.b "Hippos  form  herds  of 30 individuals.",10,3
 dc.b "They  are  good swimmers and divers and",10,3
 dc.b "can  stay  under water for six minutes.",10,3
 dc.b "In  the  daytime they lie on the shores",10,3
 dc.b "of  small  islands  or rest in water so",10,3
 dc.b "that  only  their eyes and nostrils can",10,3
 dc.b "be  seen.   With  the  fall of darkness",10,3
 dc.b "they get up from the water and graze on",10,3
 dc.b "the   riverside   walking   along  well",10,3
 dc.b "trampled  paths.   On  a single night a",10,3
 dc.b "hippo   eats   60   kilos   of   grass,",10,3
 dc.b "waterplants and fruit.",10,3
 dc.b 0
 dc.b $ff
 even


CHECKEND
