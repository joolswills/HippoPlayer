����                                        *******************************************************************************
*                       External quadrascope for HippoPlayer
*				By K-P Koljonen
*******************************************************************************

*** Includes:

 	incdir	include:
	include	exec/exec_lib.i
	include	exec/ports.i
	include	exec/types.i
	include	graphics/graphics_lib.i
	include	graphics/rastport.i
	include	intuition/intuition_lib.i
	include	intuition/intuition.i
	include	dos/dosextens.i
	incdir

*** Some useful macros

lob	macro
	jsr	_LVO\1(a6)
	endm

lore	macro
	ifc	"\1","Exec"
	ifd	_ExecBase
	ifeq	_ExecBase
	move.l	(a5),a6
	else
	move.l	_ExecBase(a5),a6
	endc
	else
	move.l	4.w,a6
	endc
	else
	move.l	_\1Base(a5),a6
	endc
	jsr	_LVO\2(a6)
	endm

pushm	macro
	ifc	"\1","all"
	movem.l	d0-a6,-(sp)
	else
	movem.l	\1,-(sp)
	endc
	endm

popm	macro
	ifc	"\1","all"
	movem.l	(sp)+,d0-a6
	else
	movem.l	(sp)+,\1
	endc
	endm

push	macro
	move.l	\1,-(sp)
	endm

pop	macro
	move.l	(sp)+,\1
	endm



*** HippoPlayer's port:

	STRUCTURE	HippoPort,MP_SIZE
	LONG		hip_private1	* Private..
	APTR		hip_kplbase	* kplbase address
	WORD		hip_reserved0	* Private..
	BYTE		hip_quit
	BYTE		hip_opencount	* Open count
	BYTE		hip_mainvolume	* Main volume, 0-64
	BYTE		hip_play	* If non-zero, HiP is playing
	BYTE		hip_playertype 	* 33 = Protracker, 49 = PS3M. 
	*** Protracker ***
	BYTE		hip_reserved2
	APTR		hip_PTch1	* Protracker channel data for ch1
	APTR		hip_PTch2	* ch2
	APTR		hip_PTch3	* ch3
	APTR		hip_PTch4	* ch4
	*** PS3M ***
	APTR		hip_ps3mleft	* Buffer for the left side
	APTR		hip_ps3mright	* Buffer for the right side
	LONG		hip_ps3moffs	* Playing position
	LONG		hip_ps3mmaxoffs	* Max value for hip_ps3moffs

	BYTE		hip_PTtrigger1
	BYTE		hip_PTtrigger2
	BYTE		hip_PTtrigger3
	BYTE		hip_PTtrigger4

	LABEL		HippoPort_SIZEOF 

	*** PT channel data block
	STRUCTURE	PTch,0
	LONG		PTch_start	* Start address of sample
	WORD		PTch_length	* Length of sample in words
	LONG		PTch_loopstart	* Start address of loop
	WORD		PTch_replen	* Loop length in words
	WORD		PTch_volume	* Channel volume
	WORD		PTch_period	* Channel period
	WORD		PTch_private1	* Private...

*** Dimensions:

WIDTH	=	320	
HEIGHT	=	256
RHEIGHT	=	HEIGHT+4

*** Variables:

	rsreset
_ExecBase	rs.l	1
_GFXBase	rs.l	1
_IntuiBase	rs.l	1
port		rs.l	1
owntask		rs.l	1
screenlock	rs.l	1
oldpri		rs.l	1
windowbase	rs.l	1
rastport	rs.l	1
userport	rs.l	1
windowtop	rs	1
windowtopb	rs	1
windowright	rs	1
windowleft	rs	1
windowbottom	rs	1
draw1		rs.l	1
draw2		rs.l	1
icounter	rs	1
icounter2	rs	1

tr1		rs.b	1
tr2		rs.b	1
tr3		rs.b	1
tr4		rs.b	1

vol1		rs	1
vol2		rs	1
vol3		rs	1
vol4		rs	1

wbmessage	rs.l	1

omabitmap	rs.b	bm_SIZEOF
size_var	rs.b	0

*** Program

main	lea	var_b,a5		* Store execbase
	move.l	4.w,a6
	move.l	a6,(a5)

	bsr.w	getwbmessage

	lea	intuiname(pc),a1	* Open libs
	lore	Exec,OldOpenLibrary
	move.l	d0,_IntuiBase(a5)

	lea 	gfxname(pc),a1		
	lob	OldOpenLibrary
	move.l	d0,_GFXBase(a5)

*** Try to find HippoPlayer's port. If succesfull, add 1 to hip_opencount
*** indicating we are using the information in the port.
*** Protect this phase with Forbid()-Permit()!

	lob	Forbid
	lea	portname(pc),a1
	lob	FindPort
	move.l	d0,port(a5)
	beq.w	exit
	move.l	d0,a0
	addq.b	#1,hip_opencount(a0)	* We are using the port now!
	lob	Permit

*** Get some info about the screen we're running on

	bsr.w	getscreendata

*** Open our window

	lea	winstruc,a0
	lore	Intui,OpenWindow
	move.l	d0,windowbase(a5)
	beq.w	exit
	move.l	d0,a0
	move.l	wd_RPort(a0),rastport(a5)	* Store rastport and userport
	move.l	wd_UserPort(a0),userport(a5)

*** Draw some gfx

plx1	equr	d4
plx2	equr	d5
ply1	equr	d6
ply2	equr	d7
 
	moveq   #7,plx1
	move    #332,plx2
	moveq   #13,ply1
	move    #80-64+256-120,ply2
	add	windowleft(a5),plx1
	add	windowleft(a5),plx2
	add	windowtop(a5),ply1
	add	windowtop(a5),ply2
	move.l	rastport(a5),a1
	bsr.w	piirra_loota2a

*** Initialize the bitmap structure

	lea	omabitmap(a5),a0
	moveq	#1,d0			* depth
	move	#WIDTH,d1		* width
	move	#HEIGHT,d2		* height 
	lore	GFX,InitBitMap
	move.l	#buffer1,omabitmap+bm_Planes(a5) * Plane pointer

	move.l	#buffer1+2*WIDTH/8,draw1(a5)	* Buffer pointers for drawing
	move.l	#buffer2+2*WIDTH/8,draw2(a5)


	bsr.w	srand

*** Set task priority to -30 to prevent messing up with other programs

	move.l	owntask(a5),a1		
	moveq	#-30,d0
	lore	Exec,SetTaskPri
	move.l	d0,oldpri(a5)		* Store the old priority

*** Main loop begins here

loop	move.l	_GFXBase(a5),a6		* Wait a while..
	lob	WaitTOF

	move.l	port(a5),a0		* Check if HiP is playing
	tst.b	hip_quit(a0)
	bne.b	exi
	tst.b	hip_play(a0)
	beq.b	.oh

*** See if we should actually update the window.
	move.l	_IntuiBase(a5),a1
	move.l	ib_FirstScreen(a1),a1
	move.l	windowbase(a5),a0	
	cmp.l	wd_WScreen(a0),a1	* Is our screen on top?
	beq.b	.yes
	tst	sc_TopEdge(a1)	 	* Some other screen is partially on top 
	beq.b	.oh		 	* of our screen?
.yes

	bsr.w	dung			* Do the scope
.oh
	move.l	userport(a5),a0		* Get messages from IDCMP
	lore	Exec,GetMsg
	tst.l	d0
	beq.b	loop
	move.l	d0,a1

	move.l	im_Class(a1),d2		
	move	im_Code(a1),d3
	lob	ReplyMsg
	cmp.l	#IDCMP_MOUSEBUTTONS,d2	* Right mousebutton pressed?
	bne.b	.xy
	cmp	#MENUDOWN,d3
	beq.b	.x
.xy	cmp.l	#IDCMP_CLOSEWINDOW,d2	* Should we exit?
	bne.b	loop			* No. Keep loopin'
.x
	
exi	move.l	owntask(a5),a1		* Restore the old priority
	move.l	oldpri(a5),d0
	lore	Exec,SetTaskPri

exit

*** Exit program
	
	move.l	port(a5),d0		* IMPORTANT! Subtract 1 from
	beq.b	.uh0			* hip_opencount when the port is not
	move.l	d0,a0			* needed anymore
	subq.b	#1,hip_opencount(a0)
.uh0
	move.l	windowbase(a5),d0	* Close the window
	beq.b	.uh1
	move.l	d0,a0
	lore	Intui,CloseWindow
.uh1
	move.l	_IntuiBase(a5),d0	* And the libs
	bsr.b	closel
	move.l	_GFXBase(a5),d0
	bsr.b	closel

	bsr.w	replywbmessage

	moveq	#0,d0			* No error
	rts
	
closel  beq.b   .huh
        move.l  d0,a1
        lore    Exec,CloseLibrary
.huh    rts


***** Get some info about screen we're running on

getscreendata
	move.l	(a5),a0			* Running kick2.0 or newer?
	cmp	#37,LIB_VERSION(a0)
	bhs.b	.new		
	rts				
.new					* Yes.
	
	sub.l	a0,a0			* Default public screen
	lore	Intui,LockPubScreen  	* The only kick2.0+ function
	move.l	d0,d7
	beq.b	exit

	move.l	d0,a0
	move.b	sc_BarHeight(a0),windowtop+1(a5) * Palkin korkeus
	move.b	sc_WBorBottom(a0),windowbottom+1(a5)
	move.b	sc_WBorTop(a0),windowtopb+1(a5)
	move.b	sc_WBorLeft(a0),windowleft+1(a5)
	move.b	sc_WBorRight(a0),windowright+1(a5)

	move	windowtopb(a5),d0
	add	d0,windowtop(a5)

	subq	#4,windowleft(a5)		* saattaa menn� negatiiviseksi
	subq	#4,windowright(a5)
	subq	#2,windowtop(a5)
	subq	#2,windowbottom(a5)

	sub	#10,windowtop(a5)
	bpl.b	.o
	clr	windowtop(a5)
.o

	move	windowtop(a5),d0	* Adjust the window size
	add	d0,winstruc+6		
	move	windowleft(a5),d1
	add	d1,winstruc+4		
	add	d1,winsiz
	move	windowbottom(a5),d3
	add	d3,winsiz+2

	move.l	d7,a1			* Unlock it. Let's hope it doesn't
	sub.l	a0,a0			* go anywhere before we open our
	lob	UnlockPubScreen		* window.
	rts


*** Draw a bevel box

piirra_loota2a

** bevelboksit, reunat kaks pixeli�

laatikko1
	moveq	#1,d3
	moveq	#2,d2

	move.l	a1,a3
	move	d2,a4
	move	d3,a2

** valkoset reunat

	move	a2,d0
	move.l	a3,a1
	lore	GFX,SetAPen

	move	plx2,d0		* x1
	subq	#1,d0		
	move	ply1,d1		* y1
	move	plx1,d2		* x2
	move	ply1,d3		* y2
	bsr.w	drawli

	move	plx1,d0		* x1
	move	ply1,d1		* y1
	move	plx1,d2
	addq	#1,d2
	move	ply2,d3
	bsr.w	drawli
	
** mustat reunat

	move	a4,d0
	move.l	a3,a1
	lob	SetAPen

	move	plx1,d0
	addq	#1,d0
	move	ply2,d1
	move	plx2,d2
	move	ply2,d3
	bsr.b	drawli

	move	plx2,d0
	move	ply2,d1
	move	plx2,d2
	move	ply1,d3
	bsr.b	drawli

	move	plx2,d0
	subq	#1,d0
	move	ply1,d1
	addq	#1,d1
	move	plx2,d2
	subq	#1,d2
	move	ply2,d3
	bsr.b	drawli

looex	moveq	#1,d0
	move.l	a3,a1
	jmp	_LVOSetAPen(a6)



drawli	cmp	d0,d2
	bhi.b	.e
	exg	d0,d2
.e	cmp	d1,d3
	bhi.b	.x
	exg	d1,d3
.x	move.l	a3,a1
	move.l	_GFXBase(a5),a6
	jmp	_LVORectFill(a6)





*** Draw the scope

dung
	move.l	_GFXBase(a5),a6		* Grab the blitter
	lob	OwnBlitter
	lob	WaitBlit

	move.l	draw2(a5),$dff054	* Clear the drawing area
	move	#0,$dff066
	move.l	#$01000000,$dff040
	move	#HEIGHT*64+WIDTH/16,$dff058

	lob	DisownBlitter		* Free the blitter

	bsr.b	efekti



*** Doublebuffering. 
* Bad: needs mem for two buffers (not that much though)
* Good: fast (blitter and cpu working simultaneously)

	movem.l	draw1(a5),d0/d1		* Switch the buffers
	exg	d0,d1
	movem.l	d0/d1,draw1(a5)

	lea	omabitmap(a5),a0	* Set the bitplane pointer
	move.l	d1,bm_Planes(a0)

;	lea	omabitmap(a5),a0	* Copy from bitmap to rastport
	move.l	rastport(a5),a1
	moveq	#0,d0		* source x,y
	moveq	#120,d1
	moveq	#10,d2		* dest x,y
	moveq	#15,d3
	add	windowleft(a5),d2
	add	windowtop(a5),d3
	move	#$c0,d6		* minterm a->d
	move	#WIDTH,d4	* x-size
	move	#HEIGHT-120,d5	* y-size

	lore	GFX,BltBitMapRastPort
	rts





efekti
	pushm	all
	bsr.b	.f
	popm	all
	rts

.f
	bsr.w	fire


	lea	chunk,a0
	move.l	draw1(a5),a1
	lea	raster2,a2
	lea	raster,a3
	moveq	#0,d0

	moveq	#256/4-1,d7
.loe
	moveq	#320/4/8-1,d6

	bra.w	.xl
	cnop	0,4

.xl
	move.b	(a0)+,d0	
	move.b	(a2,d0*4),d2
	move.b	1(a2,d0*4),d3
	move.b	2(a2,d0*4),d4
	move.b	3(a2,d0*4),d5

	move.b	(a0)+,d0	
	or.b	(a3,d0*4),d2
	or.b	1(a3,d0*4),d3
	or.b	2(a3,d0*4),d4
	or.b	3(a3,d0*4),d5

	rol	#8,d2
	rol	#8,d3
	rol	#8,d4
	rol	#8,d5

	move.b	(a0)+,d0	
	move.b	(a2,d0*4),d2
	move.b	1(a2,d0*4),d3
	move.b	2(a2,d0*4),d4
	move.b	3(a2,d0*4),d5

	move.b	(a0)+,d0	
	or.b	(a3,d0*4),d2
	or.b	1(a3,d0*4),d3
	or.b	2(a3,d0*4),d4
	or.b	3(a3,d0*4),d5

	swap	d2
	swap	d3
	swap	d4
	swap	d5

	move.b	(a0)+,d0	
	move.b	(a2,d0*4),d2
	move.b	1(a2,d0*4),d3
	move.b	2(a2,d0*4),d4
	move.b	3(a2,d0*4),d5

	move.b	(a0)+,d0	
	or.b	(a3,d0*4),d2
	or.b	1(a3,d0*4),d3
	or.b	2(a3,d0*4),d4
	or.b	3(a3,d0*4),d5

	rol	#8,d2
	rol	#8,d3
	rol	#8,d4
	rol	#8,d5

	move.b	(a0)+,d0	
	move.b	(a2,d0*4),d2
	move.b	1(a2,d0*4),d3
	move.b	2(a2,d0*4),d4
	move.b	3(a2,d0*4),d5

	move.b	(a0)+,d0	
	or.b	(a3,d0*4),d2
	or.b	1(a3,d0*4),d3
	or.b	2(a3,d0*4),d4
	or.b	3(a3,d0*4),d5

	move.l	d2,(a1)
	move.l	d3,40(a1)
	move.l	d4,80(a1)
	move.l	d5,120(a1)

	addq.l	#4,a1
.doh
	dbf	d6,.xl

	lea	3*40(a1),a1
	dbf	d7,.loe

.ohi
	rts



srand:  move.l  $dff004,d0      ; Initialize random generator.. Call once
        add.l   $dff002,d0
        add.l   $dc0000,d0
        add.l   $dc0004,d0
        add.l   $dc0008,d0
        add.l   $dc000c,d0
        move.l  d0,seed
        rts

rand:   move.l  seed(pc),d0     ; Returns random number (result: d0 = 0-32767)
        mulu.l	#$41c64e6d,d0
        add.l   #$3039,d0
        move.l  d0,seed
        moveq   #$10,d1
        lsr.l   d1,d0
        and.l   #$7fff,d0
        rts
seed:   dc.l    0       ; random seed storage (long)





lev	=	80
kork	=	64


hotcol	dc.b	$f
 even

fire

	push	a5

	lea	chunk,a0
	lea	chunk2,a5

	lea	lev(a0),a1
	lea	-1(a1),a2
	
	lea	lev(a1),a3
	lea	-1(a3),a4

	lea	lev(a3),a6

	move	#kork*lev/8-1,d7

	bra.w	.fireloop
	cnop	0,4

.fireloop
 rept 8
	move.b	(a0)+,d0
	add.b	(a2)+,d0
	add.b	(a1)+,d0
	add.b	(a1),d0
	add.b	(a4)+,d0
	add.b	(a3)+,d0
	add.b	(a3),d0
	add.b	(a6)+,d0
	lsr.b	#3,d0
	move.b	d0,(a5)+
 endr
	dbf	d7,.fireloop

	lea	chunk2,a0
	lea	chunk,a1
	move	#kork*lev/(4*4)-1,d0
.rz	
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d0,.rz


	pop	a5

	bsr.b	.sub
	bsr.b	.col

	rts

.kors	dc.l	chunk


.sub

	move.l	.kors(pc),a3
	lea	kork*lev(a3),a3


	move	#3*lev-1,d0
.loep	
	subq.b	#1,(a3)
	bpl.b	.a1
	clr.b	(a3)
.a1	addq	#1,a3
	dbf	d0,.loep
	rts	

.col

* hotspotit
	move.l	.kors(pc),a0
	lea	kork*lev(a0),a0


	moveq	#5-1,d7


.get
	bsr.w	rand
	and	#$f,d0
	move	d0,d2

	moveq	#$f,d2

.r	bsr.w	rand
	and	#$ff,d0
	cmp	#lev-7,d0
	bhs.b	.r

	moveq	#$f,d2


	lea	(a0,d0),a1

	move.b	d2,3-lev(a1)
	move.b	d2,4-lev(a1)

	move.b	d2,(a1)
	move.b	d2,1(a1)
	move.b	d2,2(a1)
	move.b	d2,3(a1)
	move.b	d2,4(a1)
	move.b	d2,5(a1)
;	move.b	d2,6(a1)

	lea	lev(a1),a1
	move.b	d2,(a1)
	move.b	d2,1(a1)
	move.b	d2,2(a1)
	move.b	d2,3(a1)
	move.b	d2,4(a1)
	move.b	d2,5(a1)
	move.b	d2,6(a1)

	lea	lev(a1),a1
	move.b	d2,(a1)
	move.b	d2,1(a1)
	move.b	d2,2(a1)
	move.b	d2,3(a1)
	move.b	d2,4(a1)
	move.b	d2,5(a1)
	move.b	d2,6(a1)


	dbf	d7,.get
	rts



* 0=musta, 16=valkoinen


;raster
;	dc.b	%00000000
;	dc.b	%01000000
;	dc.b	%10100000
;	dc.b	%11110000


doh	macro
	dc.b	~\1&%00001111
	endm

doh2	macro
	dc.b	~\1&%11110000
	endm

raster
	doh	%0000
	doh	%0000
	doh	%0000
	doh	%0000

	doh	%0000
	doh	%0100
	doh	%0000
	doh	%0000

	doh	%0000
	doh	%0100
	doh	%0010
	doh	%0000

	doh	%1000
	doh	%0010
	doh	%0000
	doh	%0100

	doh	%0101
	doh	%0000
	doh	%0010
	doh	%1000

	doh	%1001
	doh	%0010
	doh	%0010
	doh	%1000

	doh	%1010
	doh	%0010
	doh	%0101
	doh	%0010

	doh	%0101
	doh	%1100
	doh	%0010
	doh	%1001

	doh	%1010
	doh	%0101
	doh	%1001
	doh	%0110

	doh	%1010
	doh	%0111
	doh	%0110
	doh	%1001

	doh	%1010
	doh	%0111
	doh	%1110
	doh	%0101

	doh	%1110
	doh	%0111
	doh	%1010
	doh	%1011

	doh	%1011
	doh	%0110
	doh	%1111
	doh	%1110

	doh	%1010
	doh	%1111
	doh	%1111
	doh	%0111

	doh	%1110
	doh	%0111
	doh	%1111
	doh	%1111

	doh	%1111
	doh	%1111
	doh	%1111
	doh	%1111

	doh	%1111
	doh	%1111
	doh	%1111
	doh	%1111

raster2
	doh2	%0000<<4
	doh2	%0000<<4
	doh2	%0000<<4
	doh2	%0000<<4

	doh2	%0000<<4
	doh2	%0100<<4
	doh2	%0000<<4
	doh2	%0000<<4

	doh2	%0000<<4
	doh2	%0100<<4
	doh2	%0010<<4
	doh2	%0000<<4

	doh2	%1000<<4
	doh2	%0010<<4
	doh2	%0000<<4
	doh2	%0100<<4

	doh2	%0101<<4
	doh2	%0000<<4
	doh2	%0010<<4
	doh2	%1000<<4

	doh2	%1001<<4
	doh2	%0010<<4
	doh2	%0010<<4
	doh2	%1000<<4

	doh2	%1010<<4
	doh2	%0010<<4
	doh2	%0101<<4
	doh2	%0010<<4

	doh2	%0101<<4
	doh2	%1100<<4
	doh2	%0010<<4
	doh2	%1001<<4

	doh2	%1010<<4
	doh2	%0101<<4
	doh2	%1100<<4
	doh2	%0101<<4

	doh2	%1010<<4
	doh2	%0111<<4
	doh2	%0110<<4
	doh2	%1001<<4

	doh2	%1010<<4
	doh2	%0111<<4
	doh2	%1110<<4
	doh2	%0101<<4

	doh2	%1110<<4
	doh2	%0111<<4
	doh2	%1010<<4
	doh2	%1011<<4

	doh2	%1011<<4
	doh2	%0110<<4
	doh2	%1111<<4
	doh2	%1110<<4

	doh2	%1010<<4
	doh2	%1111<<4
	doh2	%1111<<4
	doh2	%0111<<4

	doh2	%1110<<4
	doh2	%0111<<4
	doh2	%1111<<4
	doh2	%1111<<4

	doh2	%1111<<4
	doh2	%1111<<4
	doh2	%1111<<4
	doh2	%1111<<4

	doh2	%1111<<4
	doh2	%1111<<4
	doh2	%1111<<4
	doh2	%1111<<4




**
* Workbench viestit
**
getwbmessage
	sub.l	a1,a1
	lore	Exec,FindTask
	move.l	d0,owntask(a5)

	move.l	d0,a4			* Vastataan WB:n viestiin, jos on.
	tst.l	pr_CLI(a4)
	bne.b	.nowb
	lea	pr_MsgPort(a4),a0
	lob	WaitPort
	lea	pr_MsgPort(a4),a0
	lob	GetMsg
	move.l	d0,wbmessage(a5)	
.nowb	rts

replywbmessage
	move.l	wbmessage(a5),d3
	beq.b	.nomsg
	lore	Exec,Forbid
	move.l	d3,a1
	lob	ReplyMsg
.nomsg	rts


*******************************************************************************
* Window

wflags set WFLG_SMART_REFRESH!WFLG_DRAGBAR!WFLG_CLOSEGADGET!WFLG_DEPTHGADGET
wflags set wflags!WFLG_RMBTRAP
idcmpflags = IDCMP_CLOSEWINDOW!IDCMP_MOUSEBUTTONS


winstruc
	dc	110,85	* x,y position
winsiz	dc	340,277-120	* x,y size
	dc.b	2,1	
	dc.l	idcmpflags
	dc.l	wflags
	dc.l	0
	dc.l	0	
	dc.l	.t	* title
	dc.l	0
	dc.l	0	
	dc	0,640	* min/max x
	dc	0,256	* min/max y
	dc	WBENCHSCREEN
	dc.l	0

.t	dc.b	"Burning window",0

intuiname	dc.b	"intuition.library",0
gfxname		dc.b	"graphics.library",0
dosname		dc.b	"dos.library",0
portname	dc.b	"HiP-Port",0
 even


 	section	udnm,bss_p

var_b		ds.b	size_var

		ds.b	1024
chunk		ds.b	kork*lev
		ds.b	1024
chunk2		ds.b	kork*lev
		ds.b	1024


	section	hihi,bss_c

buffer1	ds.b	WIDTH/8*RHEIGHT
buffer2	ds.b	WIDTH/8*RHEIGHT

 end
