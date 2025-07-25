PAGE0	EQU	#82	;WIN #0000-#3FFF
PAGE1	EQU	#A2	;WIN #4000-#7FFF
PAGE2	EQU	#C2	;WIN #8000-#BFFF
PAGE3	EQU	#E2	;WIN #C000-#FFFF

DIR	EQU	#C000

DIRPAGE	EQU	0

DAY	EQU	19
MONTH	EQU	05
YEAR	EQU	2002

NAM	EQU	0
EXT	EQU	8
ATR	EQU	11

CLU3	EQU	20
CLU4	EQU	21

TIM1	EQU	22
TIM2	EQU	23
DAT1	EQU	24
DAT2	EQU	25
CLU1	EQU	26
CLU2	EQU	27
LEN1	EQU	28
LEN2	EQU	29
LEN3	EQU	30
LEN4	EQU	31
POS1	EQU	32
POS2	EQU	33
POS3	EQU	34
POS4	EQU	35
DIRCLU1	EQU	36
DIRCLU2	EQU	37
HND1	EQU	38
HND2	EQU	39
FDRV	EQU	40
AMODE	EQU	41
FTASK	EQU	42

;ACCESS	MODE:
;	00 - READ/WRITE
;	01 - READ
;	02 - WRITE

;File Manipulator (FM)
FM_BUF	DB	".       "	;+00 NAME
	DB	"   "		;+08 EXT
	DB	#10		;+11 ATTRIBUT
	DB	0,0,0,0,0,0,0,0,0,0 ;+12 RESERVED
	DW	#0000		;+22 TIME
	DW	#0000		;+24 DATE
	DW	#0000		;+26 START CLUSTER
	DW	#0000,#0000	;+28 SIZE FILE
	DW	#0000,#0000	;+32 FILE POSITION (FP)
	DW	#0000		;+36 DIRECTORY CLUSTER
	DW	#0000		;+38 HANDLE NUMBER
	DB	#00		;+40 DRIVE OR CURRENT
	DB	#00		;+41 ACCESS MODE
	DB	#00		;+42 TASK
	DB	#00		;+43 EMPTY
END_FM
;End of	FM
;	DS	44*2

FM_SIZE	EQU	END_FM-FM_BUF

SET_FM	PUSH	DE
	INC	A
	LD	IY,FM_BUF-FM_SIZE
	LD	DE,FM_SIZE
SET_FM1	ADD	IY,DE
	DEC	A
	JR	NZ,SET_FM1
	POP	DE
	LD	A,(IY+0)
	OR	A
	LD	A,0
	RET	NZ
	LD	A,5
	SCF 
	RET 

; HL:IX	- OFFSET POINTER
;     A	- FILE MANIPULATOR

MOVE_FP	CALL	SET_FM
	RET	C
	INC	B
	DEC	B
	JP	Z,MOVE_FA
	DEC	B
	JP	Z,MOVE_FB
	DEC	B
	JP	Z,MOVE_FC
	LD	A,1
	SCF 
	RET 

;from Start File
MOVE_FA	LD	BC,0
	LD	DE,0
	JR	MOVE_F1

;from End File
MOVE_FC	LD	C,(IY+28)
	LD	B,(IY+29)
	LD	E,(IY+30)
	LD	D,(IY+31)
	JR	MOVE_F1

;from Current Position
MOVE_FB	LD	C,(IY+32)
	LD	B,(IY+33)
	LD	E,(IY+34)
	LD	D,(IY+35)
MOVE_F1	ADD	IX,BC
	ADC	HL,DE
	LD	D,XH
	LD	E,XL
	LD	(IY+32),E
	LD	(IY+33),D
	LD	(IY+34),L
	LD	(IY+35),H
	XOR	A
	RET 

;FP COMPARE
; CY - FILE POINTER > SIZE
; NC - FILE POINTER < SIZE

MOVE_CP	LD	L,(IY+28)
	LD	H,(IY+29)
	LD	E,(IY+32)
	LD	D,(IY+33)
	AND	A
	SBC	HL,DE
	LD	L,(IY+30)
	LD	H,(IY+31)
	LD	E,(IY+34)
	LD	D,(IY+35)
	SBC	HL,DE
	RET 

CHANGEDISK:	LD	A,(CDDRIVE)
		LD	C,BIOS.DRV_RESET
		RST	ToBIOS
		JR	NC,.cont
		;
		CP	BIOS.Error.ATAPI.UnitAttention
		JR	Z,.drv_change
		;
		CP	BIOS.Error.ATAPI.NotReady
		SCF 
		RET	NZ
		LD	A,DSS_Error.sys.NOT_READY
		RET 		
		;
.drv_change:	LD	A,(CDDRIVE)
		CALL	SAVE_MEDIA_CHANGED
		;
.cont:		CALL	INITDISK
		RET	C
		AND	A
		RET 

; NDISK11	CP	BIOS.Error.ATAPI.NotReady
; 	SCF 
; 	RET	NZ
; 	;
; 	LD	A,DSS_Error.sys.NOT_READY
; 	RET 

INITDISK:
	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	LD	B,4
CD_I_LP	PUSH	BC
	LD	DE,DIR
	LD	A,(CDDRIVE)
	LD	HL,#0000
	LD	IX,#0010
	LD	BC,1*256 + BIOS.DRV_READ
	RST	ToBIOS
	POP	BC
	JR	NC,CD_I_OK
	DJNZ	CD_I_LP
UNKCD	POP	AF
	OUT	(PAGE3),A
	LD	A,DSS_Error.sys.UNKNOWN_FORMAT
	SCF
	RET

CD_I_OK	LD	HL,DIR
	LD	A,(HL)
	INC	HL
	CP	#01
	JR	NZ,UNKCD
	LD	A,(HL)
	INC	HL
	CP	"C"
	JR	NZ,UNKCD
	LD	A,(HL)
	INC	HL
	CP	"D"
	JR	NZ,UNKCD
	LD	HL,DIR+#009E
	LD	DE,ROOTDIR
	LDI 
	LDI 
	LDI 
	LDI 
	LD	HL,DIR+#00A6
	LD	DE,ROOTLEN
	LDI 
	LDI 
	LDI 
	LDI 
	POP	AF
	OUT	(PAGE3),A
;	LD	HL,0
;	LD	(FATCASH),HL
	XOR	A
	RET 


;----------------------------------------------

OPEN	LD	(ACCESS),A
	CALL	GETWORD
	RET	C
	LD	HL,TMPNAME
	LD	DE,MASKARE
	CALL	MASK
	RET	C
OPENEXE	CALL	SEARCH
	RET	C
	LD	A,1	;;
	CALL	SET_FM	;;	CALL	GET_FM
	RET	C
	LD	A,C
	EX	AF,AF'
	EXX 
	LD	(IY+HND1),E
	LD	(IY+HND2),D
	EXX 
	LD	D,YH
	LD	E,YL
	LD	HL,HANDBUF
	LD	BC,#0020
	LDIR 
	LD	A,(ACCESS)
	LD	(IY+AMODE),A
;;	LD	A,(TASK)
	XOR	A	;;
	LD	(IY+FTASK),A
	XOR	A
	LD	(IY+POS1),A
	LD	(IY+POS2),A
	LD	(IY+POS3),A
	LD	(IY+POS4),A
;;	LD	A,(DRIVE)
;	XOR	A	;;
;	LD	(IY+FDRV),A
	LD	HL,FM_BUF+CLU1
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	(IY+DIRCLU1),E
	LD	(IY+DIRCLU2),D

	LD	C,(IY+CLU1)
	LD	B,(IY+CLU2)
	LD	E,(IY+CLU3)
	LD	D,(IY+CLU4)
	EX	DE,HL
	PUSH	BC
	POP	IX
	LD	C,(IY+LEN1)
	LD	B,(IY+LEN2)
	LD	E,(IY+LEN3)
	LD	D,(IY+LEN4)
	EX	AF,AF'
	AND	A
	RET 

;RET
; HL:IX - SECTOR
; DE:BC - SIZE IN BYTES

;PATH0	DEFW	#0000

ACCESS	DEFB	#00

HANDBUF	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


WRT_HND	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	LD	IX,DIR
	EXX 
	LD	DE,0
	EXX 
WRT_HN1	LD	A,(IX+00)
	OR	A
	JR	Z,WRT_HN2
	CP	#E5
	JR	Z,WRT_HN2
	LD	BC,#0020
	ADD	IX,BC
	JR	NC,WRT_HN1
	POP	AF
	OUT	(PAGE3),A
	LD	A,9
	SCF 
	RET 

WRT_HN2	LD	D,XH
	LD	E,XL
	LD	HL,HANDBUF
	LD	BC,#0020
	LDIR 
	POP	AF
	OUT	(PAGE3),A
	LD	HL,DIR
	LD	BC,(DIRSIZE)
	DEC	BC
	ADD	HL,BC
	AND	A
	SBC	HL,DE
	RET	NC
	LD	HL,(DIRSIZE)
	LD	BC,#0020
	ADD	HL,BC
	LD	(DIRSIZE),HL
	AND	A
	RET 

GETNAME	LD	BC,#08FF
GETN1	LD	A,(HL)
	CP	" "
	JR	NZ,GETN3
GETN2	INC	HL
	DJNZ	GETN2
	JR	GETN4
GETN3	LDI 
	DJNZ	GETN1
GETN4	LD	A,(HL)
	CP	" "
	LD	A,"."
	JR	NZ,GETN5
	LD	A,#00
GETN5	LD	(DE),A
	INC	DE
	RET	Z
	LD	B,#03
GETN6	LD	A,(HL)
	CP	" "
	RET	Z
	LDI 
	XOR	A
	LD	(DE),A
	DJNZ	GETN6
	RET 

DTABUF	DEFW	#0000
CURHND	DEFW	#0000
NO_NEXT	DEFB	#00
FNDMODE	DEFB	#00

F_FIRST	LD	(ACCESS),A
	LD	(DTABUF),DE
	LD	A,B
	LD	(FNDMODE),A
	PUSH	HL
	CALL	LOADDIR
	POP	HL
	CALL	GETWORD
	RET	C
	LD	HL,TMPNAME
	LD	DE,MASKARE
	CALL	MASK
	RET	C
	LD	A,(ACCESS)
	CALL	ASEARCH
	RET	C
	LD	HL,MASKARE
	LD	DE,(DTABUF)
	LD	BC,11
	LDIR 
	LD	A,(ACCESS)
	LD	(DE),A
	INC	DE
FIND_S	LD	BC,#0020
	ADD	IX,BC
	LD	(CURHND),IX
	LD	HL,HANDBUF+12
	LD	BC,20
	LDIR 
	LD	A,(HANDBUF+11)
	LD	(DE),A
	INC	DE
	LD	HL,HANDBUF
	LD	A,(FNDMODE)
	OR	A
	JR	NZ,FIND_M2
	LD	BC,11
	LDIR 
	LD	A,#FF
	LD	(NO_NEXT),A
	XOR	A
	RET 
FIND_M2	CALL	GETNAME
	LD	A,#FF
	LD	(NO_NEXT),A
	XOR	A
	RET 

F_NEXT	LD	A,(NO_NEXT)
	OR	A
	LD	A,14
	SCF 
	RET	Z
	LD	(DTABUF),DE
	LD	DE,MASKARE
	LD	HL,(DTABUF)
	LD	BC,11
	LDIR 
	LD	A,(HL)
	PUSH	HL
	CALL	NSEARCH
	POP	DE
	EX	AF,AF'
	XOR	A
	LD	(NO_NEXT),A
	EX	AF,AF'
	RET	C
	INC	DE
	JP	FIND_S

NSEARCH	EX	AF,AF'
	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	EX	AF,AF'
	CPL 
	LD	C,A
	LD	IX,(CURHND)
	EXX 
	LD	DE,0
	EXX 
	JP	SEARCH1

DSEARCH	LD	A,#10
	CALL	ASEARCH
	RET	NC
	LD	A,4
	RET 

SEARCH	LD	A,#23
ASEARCH	EX	AF,AF'
	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	EX	AF,AF'
	CPL 
	LD	C,A
	LD	IX,DIR
	EXX 
	LD	DE,0
	EXX 
SEARCH1	LD	A,(IX+00)
	OR	A
	JR	Z,SEARCH4
	CP	#E5
	JR	Z,SEARCH3
	LD	A,(IX+11)
	AND	C
	JR	NZ,SEARCH3
	LD	HL,MASKARE
	LD	D,XH
	LD	E,XL
	LD	B,11
	EX	DE,HL
SEARCH2	LD	A,(DE)
	CP	"?"
	JR	Z,SEARCH5
	CP	(HL)
	JR	NZ,SEARCH3
SEARCH5	INC	HL
	INC	DE
	DJNZ	SEARCH2
	LD	D,XH
	LD	E,XL
	LD	HL,HANDBUF
	EX	DE,HL
	LD	BC,#0020
	LDIR 
	POP	AF
	OUT	(PAGE3),A
	AND	A
	RET 

SEARCH3	EXX 
	INC	DE
	EXX 
	LD	DE,#0020
	ADD	IX,DE
	JR	NC,SEARCH1
SEARCH4	POP	AF
	OUT	(PAGE3),A
	LD	A,3
	SCF 
	RET 

GETWORD	LD	DE,TMPNAME
	LD	BC,#0DFF
GETWRD1	LD	A,(HL)
	INC	HL
	CP	'\' ;
	JR	Z,DIRNAME
	CP	":"
	JR	Z,DRVNAME
	LD	(DE),A
	INC	DE
	CP	#21
	CCF 
	RET	NC
	DJNZ	GETWRD1
	LD	A,16
	SCF 
	RET 

DIRNAME	LD	A,#00
	LD	(DE),A
	PUSH	HL
	LD	HL,TMPNAME
	CALL	OPENDIR
	POP	HL
	JP	NC,GETWORD
	RET 

DRVNAME	LD	A,(TMPNAME)
	CP	"a"
	JR	C,DRVN2
	CP	"{"
	JR	NC,DRVN2
	SUB	#20
DRVN2	SUB	"A"
	PUSH	HL
;	CALL	OPENDSK
	POP	HL
	JP	NC,GETWORD
	RET 

TMPNAME	DB	"            ",#00

OPENDIR	XOR	A
	CALL	SET_FM
	LD	A,(HL)
	OR	A
	JP	NZ,SUBDIR

	LD	DE,(ROOTDIR+0)
	LD	(IY+CLU1),E
	LD	(IY+CLU2),D
	LD	DE,(ROOTDIR+2)
	LD	(IY+CLU3),E
	LD	(IY+CLU4),D

	LD	DE,(ROOTLEN+0)
	LD	(IY+LEN1),E
	LD	(IY+LEN2),D
	LD	DE,(ROOTLEN+2)
	LD	(IY+LEN3),E
	LD	(IY+LEN4),D

	CALL	LOADDIR
	LD	HL,DIRSPEC
	LD	(HL),'\'	;
	INC	HL
	LD	(HL),#00
	AND	A
	RET 

SUBDIR	CP	"."
	JR	NZ,SUBDIR2
	EXX 
	LD	HL,MASKARE
	LD	DE,MASKARE+1
	LD	BC,10
	LD	(HL),#20
	LDIR 
	EXX 
	LD	DE,MASKARE
SUBDIR0	LDI 
	LD	A,(HL)
	OR	A
	JR	NZ,SUBDIR0
	JR	SUBDIR3

SUBDIR2	LD	DE,MASKARE
	CALL	MASK
	RET	C
SUBDIR3	CALL	FINDDIR
	RET	C
	LD	(IY+CLU1),E
	LD	(IY+CLU2),D
	LD	(IY+CLU3),C
	LD	(IY+CLU4),B
	EXX 
	LD	(IY+LEN1),E
	LD	(IY+LEN2),D
	LD	(IY+LEN3),C
	LD	(IY+LEN4),B
	EXX 
	CALL	LOADDIR
	AND	A
	RET 



FINDD03	LD	BC,#0020
	ADD	IX,BC
	JR	NC,FINDD01
FINDD04	POP	AF
	OUT	(PAGE3),A
	LD	A,4
	SCF 
	RET 

; FIND "MASKAREA" IN DIRECTORY

FINDDIR	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	LD	IX,DIR
FINDD01	LD	A,(IX+00)
	OR	A
	JR	Z,FINDD04
	CP	#E5
	JR	Z,FINDD03
	LD	A,(IX+11)
	AND	#10
	JR	Z,FINDD03
	LD	HL,MASKARE
	LD	D,XH
	LD	E,XL
	EX	DE,HL
	LD	B,11
FINDD02	LD	A,(DE)
	CP	"?"
	JR	Z,FINDD05
	CP	(HL)
	JR	NZ,FINDD03
FINDD05	INC	HL
	INC	DE
	DJNZ	FINDD02
	LD	A,(IX+0)
	CP	"."
	JP	NZ,ADDSPEC
	LD	A,(IX+1)
	CP	"."
	JP	NZ,IT_DIR
	LD	HL,DIRSPEC
	LD	D,H
	LD	E,L
	LD	BC,#100
	XOR	A
	CPIR 
	LD	BC,#100
	LD	A,'\'	;
	CPDR 
	INC	HL
	AND	A
	EX	DE,HL
	SBC	HL,DE
	EX	DE,HL
	JR	NZ,ROTZ
	INC	HL
ROTZ	LD	(HL),0
IT_DIR	LD	E,(IX+CLU1)
	LD	D,(IX+CLU2)
	LD	C,(IX+CLU3)
	LD	B,(IX+CLU4)
	EXX 
	LD	E,(IX+LEN1)
	LD	D,(IX+LEN2)
	LD	C,(IX+LEN3)
	LD	B,(IX+LEN4)
	EXX 
	POP	AF
	OUT	(PAGE3),A
	AND	A
	RET 

ADDSPEC	LD	E,XL
	LD	D,XH
	LD	HL,DIRSPEC
	LD	BC,#FF
	XOR	A
	CPIR 
	DEC	HL
	DEC	HL
	LD	A,#5C	;"\"
	CP	(HL)
	INC	HL
	JR	Z,ADDSPE0
	LD	(HL),A
	INC	HL
ADDSPE0	LD	BC,#0820
MM1	LD	A,(DE)
	INC	DE
	CP	C
	JR	Z,MM2
	LD	(HL),A
	INC	HL
MM2	DJNZ	MM1
	LD	A,(DE)
	INC	DE
	CP	C
	JR	Z,MM3
	LD	(HL),"."
	INC	HL
	LD	(HL),A
	INC	HL
	LD	A,(DE)
	INC	DE
	CP	C
	JR	Z,MM3
	LD	(HL),A
	INC	HL
	LD	A,(DE)
	CP	C
	JR	Z,MM3
	LD	(HL),A
	INC	HL
MM3	LD	(HL),0
	JP	IT_DIR

CURRDIR	EX	DE,HL
	LD	HL,DIRSPEC
CURDIR1	LD	A,(HL)
	OR	A
	LDI 
	JP	NZ,CURDIR1
	RET 

LOADDIR	XOR	A
	LD	HL,0
	LD	IX,0
	LD	B,0
	CALL	MOVE_FP
	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	LD	B,3
LOADFFF	PUSH	BC
	LD	HL,#C000
	LD	DE,#C001
	LD	BC,#3FFF
	LD	(HL),L
	LDIR 
;	LD	A,(DRIVE)
;	LD	(IY+FDRV),A
;	LD	C,(IY+LEN1)
	LD	C,(IY+LEN2)
	LD	B,(IY+LEN3)
	LD	E,(IY+LEN4)
	LD	D,0
	SRL	D
	RR	E
	RR	B
	RR	C
	SRL	D
	RR	E
	RR	B
	RR	C
	SRL	D
	RR	E
	RR	B
	RR	C
	LD	E,(IY+CLU1)
	LD	D,(IY+CLU2)
	LD	L,(IY+CLU3)
	LD	H,(IY+CLU4)
	LD	XH,D
	LD	XL,E
	LD	B,C
	LD	A,B
	OR	A
	JR	Z,ERRLEND
	CP	#08
	JR	C,NORLEND
	LD	B,8
NORLEND	
	LD	A,(CDDRIVE)
	LD	C,BIOS.DRV_READ
	LD	DE,DIR
	RST	ToBIOS
	POP	BC
	JR	NC,LOADMMM
	DEC	B
	JP	NZ,LOADFFF
	POP	AF
	OUT	(PAGE3),A
	SCF 
	LD	A,20
	RET 

ERRLEND	POP	BC
	POP	AF
	OUT	(PAGE3),A
	SCF 
	LD	A,20
	RET 

LOADMMM	POP	AF
	OUT	(PAGE3),A
	CALL	CORRDIR
	AND	A
	RET 

CORRDIR	LD	A,DIRPAGE
	CALL	BANK
	PUSH	AF
	LD	HL,DIR
	LD	DE,DIR
CORRL1	PUSH	DE
	LD	C,(HL)
	LD	B,0
	LD	DE,ENTRYBF
	LDIR 
	POP	DE
	PUSH	HL
	LD	HL,FCDFLEN
	LD	C,(HL)
	LD	B,0
	ADD	HL,BC
	INC	HL
	LD	(HL),0
	SBC	HL,BC
	PUSH	DE
	CALL	MASK
	POP	HL
	LD	BC,11
	ADD	HL,BC
	LD	A,(FCDFLAG)
	BIT	1,A	;IS IT DIR?
;	AND	2
	LD	C,#01	;ATTRIBUT FILE
	JR	Z,CORRL0
	LD	C,#10	;ATTRIBUT DIRECTORY
CORRL0	BIT	0,A	;IS IT HIDDEN
	JR	Z,CORRL00
	SET	1,C
CORRL00
	LD	(HL),C
	INC	HL
	XOR	A
	LD	B,8
FILLCDN	LD	(HL),A
	INC	HL
	DJNZ	FILLCDN
	LD	A,(FCDSEC+2)
	LD	(HL),A
	INC	HL
	LD	A,(FCDSEC+3)
	LD	(HL),A
	INC	HL
;MKDATE
	PUSH	HL
	LD	A,(FCDYEAR)
	LD	XL,A
	LD	XH,0
	LD	DE,1900
	ADD	IX,DE
	LD	A,(FCDMOUN)
	LD	E,A
	LD	A,(FCDDAY)
	LD	D,A
	LD	A,(FCDHOUR)
	LD	H,A
	LD	A,(FCDMIN)
	LD	L,A
	LD	A,(FCDSECN)
	LD	B,A
	CALL	MK_TIME
	POP	HL
;	LD	DE,#0000	;TIME
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
;	LD	DE,#0000	;DATE
	LD	(HL),C
	INC	HL
	LD	(HL),B
	INC	HL

	LD	DE,(FCDSEC)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	EX	DE,HL
	LD	HL,FCDLEN
	LDI 
	LDI 
	LDI 
	LDI 
	POP	HL
	BIT	7,H
	JR	Z,CORRL2
	LD	A,(HL)
	OR	A
	JP	NZ,CORRL1
	LD	L,0
	INC	H
	JR	Z,CORRL2
	LD	A,(HL)
	OR	A
	JP	NZ,CORRL1
CORRL2	XOR	A
	LD	(DE),A
	LD	DE,(ROOTDIR+0)
	LD	L,(IY+CLU1)
	LD	H,(IY+CLU2)
	AND	A
	SBC	HL,DE
	JR	NZ,CORRL6
	LD	DE,(ROOTDIR+2)
	LD	L,(IY+CLU3)
	LD	H,(IY+CLU4)
	AND	A
	SBC	HL,DE
	JR	NZ,CORRL6
	LD	HL,DIR
	LD	A,(HL)
	CP	" "
	JR	NZ,CORRL4
	LD	(HL),#E5
	LD	BC,#0020
	ADD	HL,BC
	LD	A,(HL)
	CP	" "
	JR	NZ,CORRL4
	LD	(HL),#E5
	JR	CORRL4
CORRL6	LD	HL,DIR
	LD	A,(HL)
	CP	" "
	JR	NZ,CORRL4
	LD	(HL),"."
	LD	BC,#0020
	ADD	HL,BC
	LD	A,(HL)
	CP	" "
	JR	NZ,CORRL4
	LD	(HL),"."
	INC	HL
	LD	(HL),"."
CORRL4	POP	AF
	OUT	(PAGE3),A
	AND	A
	RET 

;SYSTEM ATTRIBUTES
READONLY_ATR	EQU	%00000001
HIDDEN_ATR	EQU	%00000010
SYSTEM_ATR	EQU	%00000100
ARCHIVE_ATR	EQU	%00100000

ENTRYBF
	DEFB	#00	;Entry lenght
	DEFB	#00	;XAR in	LBN
FCDSEC	DEFW	#00,#00	;Start sector (Intel)
	DEFW	#00,#00	;Start sector (Motorola)
FCDLEN	DEFW	#00,#00	;Lenght	file (Intel)
	DEFW	#00,#00	;Lenght	file (Motorola)
FCDYEAR	DEFB	#00	;Year
FCDMOUN	DEFB	#00	;Mount
FCDDAY	DEFB	#00	;Day
FCDHOUR	DEFB	#00	;Hour
FCDMIN	DEFB	#00	;Minute
FCDSECN	DEFB	#00	;Second
	DEFB	#00	;Reserve
FCDFLAG	DEFB	#00	;Flag
	DEFB	#00	;Interlive size
	DEFB	#00	;Interlive skip	factor
	DEFW	#0000	;Volume	Set Sequence (Intel)
	DEFW	#0000	;Volume	Set Sequence (Motorola)
FCDFLEN	DEFB	#00
DEFSA	EQU	$-ENTRYBF
FCDNAME	DEFS	#100-DEFSA

ROOTDIR	DEFW	0,0
ROOTLEN	DEFW	0,0

DIRSIZE	DEFW	0

BANK	LD	C,A
	LD	B,0
	LD	HL,BANKTBL
	ADD	HL,BC
	IN	A,(PAGE3)
	LD	C,PAGE3
	OUTI 
	RET 

BANKTBL	DEFB	#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF
	DEFB	#FF,#FF,#FF,#FF,#FF,#FF,#FF,#FF

;HANDTA	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
;	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

MASKARE
	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DEFB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; HL - MASK "file*.t??"
; DE - 11 bytes	filename
; RET: C=2 FILE	WITHOUT	EXTENTION
;      C=1 FILE	WITH EXTENTION

MASK	PUSH	HL
	PUSH	DE
	LD	H,D
	LD	L,E
	INC	DE
	LD	(HL),#20
	LD	BC,10
	LDIR 
	POP	DE
	POP	HL
	LD	A,(HL)
	CP	#21
	RET	C
	LD	BC,#0902
MASK1	LD	A,(HL)
	CP	#21
	CCF 
	RET	NC
	CP	#22
	JR	Z,MASK7
	CP	"*"
	JR	Z,MASK3
	CP	"+"
	JR	Z,MASK7
	CP	","
	JR	Z,MASK7
	CP	"."
	JR	Z,MASK5
	CP	"/"
	JR	Z,MASK7
	CP	":"
	JR	Z,MASK7
	CP	";"
	JR	Z,MASK7
	CP	"<"
	JR	Z,MASK7
	CP	"="
	JR	Z,MASK7
	CP	">"
	JR	Z,MASK7
	CP	"["
	JR	Z,MASK7
	CP	'\'	;
	JR	Z,MASK7
	CP	"]"
	JR	Z,MASK7
	CP	"|"
	JR	Z,MASK7
	CP	"a"
	JR	C,MASK2
	CP	"{"
	JR	NC,MASK2
	SUB	#20
MASK2	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	MASK1
MASK7	LD	A,16
	SCF 
	RET 

MASK3	LD	A,"?"
	INC	HL
	DJNZ	MASK6
	LD	A,16
	SCF 
	RET 

MASK6	LD	(DE),A
	INC	DE
	DJNZ	MASK6
	LD	B,1
	JR	MASK1

MASK5	LD	A," "
	INC	HL
	DJNZ	MASK4
	LD	B,4
	DEC	C
	JP	NZ,MASK1
	LD	A,16
	SCF 
	RET 

MASK4	LD	(DE),A
	INC	DE
	DJNZ	MASK4
	LD	B,4
	DEC	C
	JP	NZ,MASK1
	LD	A,16
	SCF 
	RET 

SYSTIME	LD	DE,DAY*256+MONTH ;DAY/MONTH
	LD	HL,#0000	;HOUR/MINUTE
	LD	BC,#0001	;SECOND/WEEKDAY
	LD	IX,YEAR		;YEAR
	AND	A
	RET 

;INPUT:	D - DAY;  E - MONTH
;	H - HOUR; L - MINUTE
;	B - SECOND (0...59)
;	IX- YEAR (0...65535)
;OUTPUT: DE - hhhhhmmmmmmsssss	h - hour, m - min, s - sec/2
;	 BC - yyyyyyymmmmddddd	y - year, m - month, d - day
;			       (1980-2108)

MK_TIME	LD	A,L
	RLCA 
	RLCA 
	SLA	A
	RL	H
	SLA	A
	RL	H
	SLA	A
	RL	H
	SRL	B
	OR	B
	LD	L,A

	LD	BC,#F844	;(-1980)
	ADD	IX,BC
	LD	A,E
	RLCA 
	RLCA 
	RLCA 
	RLCA 
	AND	#F0
	LD	B,XL
	SLA	A
	RL	B
	OR	D
	LD	C,A
	EX	DE,HL
	AND	A
	RET 

;INPUT:	DE - hhhhhmmmmmmsssss  h - hour, m - min, s - sec/2
;	BC - yyyyyyymmmmddddd  y - year, m - month, d -	day
;			       (1980-2108)
;OUTPUT: D - DAY;  E - MONTH
;	 H - HOUR; L - MINUTE
;	 B - SECOND (0...59)
;	 IX- YEAR (0...65535)

RMKTIME	EX	DE,HL
	LD	A,C
	AND	#1F
	LD	D,A
	SRL	B
	RR	C
	LD	A,C
	RRCA 
	RRCA 
	RRCA 
	RRCA 
	AND	#0F
	LD	E,A
	LD	C,B
	LD	B,0
	LD	IX,1980
	ADD	IX,BC
	LD	A,L
	AND	#1F
	ADD	A,A
	LD	B,A
	SRL	H
	RR	L
	SRL	H
	RR	L
	SRL	H
	RR	L
	SRL	L
	SRL	L
	AND	A
	RET 

;  INPUT: HL - "C:\DIR\DIR\DIR_NAME[\]",0

CHDIR	CALL	GETWORD
	RET	C
	LD	HL,TMPNAME
	LD	A,(HL)
	OR	A
	CALL	NZ,OPENDIR
	RET 
;