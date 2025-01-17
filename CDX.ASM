;[BEGIN]
;
; CDX.EXE [command] [-switches] [directory]
;
;commands:
;	OPEN
;	EJECT
;	CLOSE
;	COPY
;	LIST
;	DUMP
;	COMMAND
; -h,?	Help page

	DEFINE _MAME 1


CR	EQU	13
LF	EQU	10

	INCLUDE	"Shared_Includes/constants/BIOS_equ.inc"
	INCLUDE	"Shared_Includes/constants/dss_equ.inc"
	INCLUDE	"Shared_Includes/constants/Sp2000.inc"
	

	ORG	#8100-22

	DB	"EXE"	;EXE ID
	DB	#00	;EXE VERSION
	DW	#0016	;CODE OFFSET LOW
	DW	#0000	;CODE OFFSET HIGH
	DW	#0000	;END-BEG ;PRIMARY LOADER
	DW	#0000	;
	DW	#0000	;RESERVED
	DW	#0000	;
	DW	START	;LOAD ADDRESS
	DW	START	;START ADDRESS
	DW	#BFFF	;STACK ADDRESS
	;DS	490

START:	PUSH	IX
	;
	XOR	A
	;
	 ; LD	HL,BUF1
	 ; LD	(HL),A
	 ; LD	DE,BUF1+1
	 ; LD	BC,BUFFERS_END-1
	 ; LDIR
	;
	LD	HL,'\' ;
	LD	(DIRSPEC),HL
	;
	 LD	HL,BUF1
	 LD	B,BUFERS_NUMBER
.initBuffersLoop:
	 LD	(HL),A
	 INC	H
	 DJNZ	.initBuffersLoop
	;
	
	LD	A,MSG_HELLO
	CALL	MESSAGE
	;
	CALL	INIT
	JR	NC,.next
	;
	LD	HL,PRM1
	LD	(HL),0
	LD	A,MSG_NO_CDROM
	CALL	MESSAGE
	LD	A,1
	LD	(STOPMODE),A
	;
.next:	LD	C,Dss.Version
	RST	ToDSS		;GET DSS VERSION
	EX	DE,HL
	AND	A
	LD	DE,#0146	;1.70
	SBC	HL,DE		;CHECK DSS VERSION
	POP	HL
	;
	JP	C,OLD_DSS
	LD	IX,BUF_PTRS
	CALL	EX_COMMAND_LINE

	CALL	MALLOC
	JR	C,QUIT

	;CALL	FIND_CDROM
	LD	A,(STOPMODE)
	OR	A
	CALL	Z,COMMAND

	CALL	MDEALLOC
QUIT:	CALL	CRLF
.loop:	LD	BC,Dss.Exit
	RST	ToDSS
	JP	.loop

OLD_DSS
	LD	A,MSG_OLD_DSS
	CALL	MESSAGE
	JR	QUIT

HNDMEM	DB	#FF

MALLOC
	LD	BC,2*256 + Dss.GetMem
	RST	ToDSS
	JR	NC,M_ALLOK
	LD	A,MSG_MEMERROR
	CALL	MESSAGE
	SCF
	RET
M_ALLOK
	LD	(HNDMEM),A
	LD	BC,1*256 + Dss.SetWin3
	RST	ToDSS
	LD	HL,BANKTBL
	LD	C,BIOS.GetMemBlkPages
	LD	A,(HNDMEM)
	JP	ToBIOS

MDEALLOC
	LD	A,(HNDMEM)
	LD	C,Dss.FreeMem
	JP	ToDSS

; FIND_CDROM
; 	LD	IX,DEV_CFG
; 	LD	C,BIOS.DRV_LIST
; 	RST	ToBIOS
; 	LD	A,(IX+3)	;CDROM
; 	OR	A
; 	JR	Z,W_O_CD
; 	LD	A,(CDDRIVE)
; 	INC	A
; 	RET	NZ
; 	LD	A,SLAVE		;DEFAULT
; 	LD	(CDDRIVE),A
; 	RET
; W_O_CD	LD	A,MSG_NO_CDROM
; 	CALL	MESSAGE
; 	LD	A,1
; 	LD	(STOPMODE),A
; 	SCF
; 	RET

;BUF_PRINT
;	LD	HL,BUF_PTRS
;BUF_PL	LD	E,(HL)
;	INC	HL
;	LD	D,(HL)
;	INC	HL
;	LD	A,D
;	OR	E
;	RET	Z
;	PUSH	HL
;	EX	DE,HL
;	LD	C,Dss.PCHARS
;	RST	ToDSS
;	CALL	CRLF
;	POP	HL
;	JR	BUF_PL

;OPEN_FILE
;	LD	HL,FILENAME
;	XOR	A
;	LD	C,Dss.OPEN
;	RST	ToDSS
;	LD	(FILEHND),A
;	RET	NC
;	LD	HL,FILENAME
;	CALL	PUTVAR
;	LD	A,MSG_CANT_OPEN
;	CALL	MESSAGE
;	SCF
;	RET

;CLOSE_FILE
;	LD	A,(FILEHND)
;	LD	C,Dss.CLOSE
;	RST	ToDSS
;	RET

INIT:	XOR	A
	LD	(STOPMODE),A
	DEC	A
	LD	(CDDRIVE),A
	;
	LD	BC,+(#C0-1)*256 + BIOS.DRV_DETECT
.loop:	INC	B
	LD	A,B
	CP	#C4
	SCF
	RET	Z
	PUSH	BC
	RST	ToBIOS
	POP	BC
	JR	C,.loop
	LD	A,B
	LD	(CDDRIVE),A
	RET
	;
	; LD	C,BIOS.DRV_RESET
	; JP	ToBIOS
;	RET

;VARIABLES

; FILENAME	DS	256
; FILEHND		DB	#FF

STOPMODE	DB	#00

	INCLUDE	"cmdparse.asm"
	INCLUDE	"command.asm"
	INCLUDE	"cd_dos.asm"

CRLF:	PUSH	HL
	LD	HL,MSG0.crlf
	LD	C,Dss.PChars
	; LD	A,#0D
	; LD	C,Dss.PutChar
	; RST	#10
	; LD	A,#0A
	; LD	C,Dss.PutChar
	RST	ToDSS
	POP	HL
	RET
;

ERROR:		CP	MAX_DSS_ERR
		LD	E,A
		LD	D,0
		JR	C,.ERR_MSG
		LD	E,D
		;JP	.ERR_MSG
		;
.ERR_MSG:	PUSH	DE
		LD	HL,ERRCDX
		CALL	PRINTZ
		POP	DE
		CALL	FMESAGE
		CALL	PRINTZ
		CALL	CRLF
		JP	CRLF


FMESAGE	INC	DE
	LD	HL,ERR0
	LD	BC,ERR0.Size
LCPIR	XOR	A
	CPIR
	RET	PO
	RET	NZ
	DEC	DE
	LD	A,D
	OR	E
	JP	NZ,LCPIR
	RET

MAX_DSS_ERR	EQU	33

ERRCDX	DB	"CDX: ",0

	include 'Shared_includes/constants/dss_errors.z80'
; ERR0	DB	#00
; 	DB	"Unknown error",0
; 	DB	"Invalid function",0
; 	DB	"Invalid drive number",0
; 	DB	"File not found",0
; 	DB	"Path not found",0
; 	DB	"Invalid handle",0
; 	DB	"Extended error 6",0
; 	DB	"File exist",0
; 	DB	"File read only",0
; 	DB	"Root overflow",0
; 	DB	"No free space",0
; 	DB	"Directory not empty",0
; 	DB	"Can't delete current directory",0
; 	DB	"Invalid media",0
; 	DB	"Unknown operation",0	;R02
; 	DB	"Directory exist",0
; 	DB	"Invalid filename",0
; 	DB	"Invalid EXE-file",0
; 	DB	"Not supported EXE-file",0
; 	DB	"Access denied",0
; 	DB	"Not ready",0
; 	DB	"Seek error",0
; 	DB	"Sector not found",0
; 	DB	"CRC error",0
; 	DB	"Write protect",0
; 	DB	"Read error",0
; 	DB	"Write error",0
; 	DB	"Drive failure",0
; 	DB	"Extended error 28",0
; 	DB	"Extended error 29",0
; 	DB	"No free memory",0
; 	DB	"Invalid memory block",0
; 	DB	"Extended error 32",0
; 	DB	"Extended error 33",0
; 	DB	"Extended error 34",0
; 	DB	"35",0
; 	DB	"36",0
; 	DB	"37",0
; 	DB	"38",0
; 	DB	"39",0
; 	DB	"40",0
; 	DB	"41",0
; 	DB	"42",0
; 	DB	"43",0
; 	DB	"44",0
; 	DB	"45",0
; 	DB	"46",0
; 	DB	"47",0
; 	DB	"48",0
; 	DB	"49",0
; 	DB	"50"
; 	DB	0
; ERR1

;FIND_MESSAGE
	; LD	E,A
	; LD	D,0
	; CALL	MESAGE
	; RET
MESSAGE	LD	E,A
	LD	D,0
	CALL	MESAGE
	JP	PRINTZ
;

MESAGE	INC	DE
	LD	HL,MSG0
	LD	BC,MSG1-MSG0
LCPIR2	XOR	A
	CPIR
	RET	PO
	RET	NZ
	DEC	DE
	LD	A,D
	OR	E
	JP	NZ,LCPIR2
	RET

PRINTZ	LD	A,(HL)
	INC	HL
	OR	A
	RET	Z
	CP	"%"
	JR	NZ,PRINTZ2
	LD	A,(HL)
	INC	HL
	SUB	"1"
	PUSH	HL
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	LD	BC,PRM1
	ADD	HL,BC
	LD	C,Dss.PChars
	RST	ToDSS
	POP	HL
	JR	PRINTZ
PRINTZ2	LD	C,Dss.PutChar
	RST	ToDSS
	JP	PRINTZ

PRINT_	LD	BC,1*256 + BIOS.LP_PRINT_SYM
	JP	ToBIOS

PUTVAR	LD	DE,PRM1
PUTPRM	LD	BC,15
PUTPRMA	LD	A,(HL)
	LDI
	RET	PO
	OR	A
	JR	NZ,PUTPRMA
	RET

CDDRIVE	DB	#FF

PRM1    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM2    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM3    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM4    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM5    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM6    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM7    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM8    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
PRM9    DB	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0


MSG_HELLO		EQU	0
MSG_TRAY_OPEN		EQU	1
MSG_TRAY_CLOSE		EQU	2
MSG_USAGE		EQU	3
MSG_UNK_DEVICE_NUMBER	EQU	4
MSG_UNK_COMMAND		EQU	5
;MSG_DISABLED		EQU	6
;MSG_ENABLED		EQU	7
MSG_DONE		EQU	6	;8
MSG_NO_CDROM		EQU	7	;9
MSG_IO_ERROR		EQU	8	;10
MSG_OLD_DSS		EQU	9	;11
MSG_COPYFILE		EQU	10	;12
MSG_DIRHEAD		EQU	11	;13
MSG_DIRENTRY		EQU	12	;14
MSG_MEMERROR		EQU	13	;15
MSG_COPYTO		EQU	14	;16
MSG_CD_READ_ERR		EQU	15	;17
MSG_F_WRITE_ERR		EQU	16	;18
MSG_FAILURE		EQU	17	;19
MSG_ERR_DEST		EQU	18	;20
MSG_COPYABORTED		EQU	19	;21

MSG0	BYTE	0
;0
	BYTE	"CDROM eXtension utility v1.01, 2023 (c) Sprinter Team",CR,LF
	DZ	"Type CDX.EXE -? for help.",CR,LF,CR,LF
;1
	DZ	"Opening tray..."
;2
	DZ	"Closing tray..."
	;        01234567890123456789012345678901234567890123456789012345678901234567890123456789
;3
	BYTE	'  Usage: CDX.EXE [-switches] [command] [param1] [param2]',CR,LF,CR,LF
	BYTE	'Commands:',CR,LF
	BYTE	' CDX.EXE OPEN			       - Open tray',CR,LF
	BYTE	' CDX.EXE CLOSE			       - Close tray',CR,LF
	BYTE	' CDX.EXE LIST [\cd_path\][pattern]    - Show CDROM filelist',CR,LF
	BYTE	' CDX.EXE COPY \source d:\destination\ - Copy file(s) from CDROM to another disk',CR,LF
	BYTE	' CDX.EXE DUMP sector [offset]	       - Show sector dump from CDROM',CR,LF
	BYTE	CR,LF
	BYTE	'Switches:',CR,LF
	BYTE	' -1    CDROM installed as Primary IDE Master device',CR,LF
	BYTE	' -2    CDROM installed as Primary IDE Slave device',CR,LF
	BYTE	' -3    CDROM installed as Secondary IDE Master device',CR,LF
	BYTE	' -4    CDROM installed as Secondary IDE Slave device',CR,LF
	DZ	' -h,?	Help page',CR,LF
;4
	DZ	"  Error: Unknown device number %1",CR,LF
;5
	DZ	"  Error: Unknown command: %1",CR,LF
	;6
	;DZ	"Disabled"
	;7
	;DZ	"Enabled"
;6
	DZ	"Done!",CR,LF
;7
	DZ	"  Error: Can't find CDROM device %1",CR,LF
;8
	DZ	"  Error: I/O Error",CR,LF
;9
	DZ	"  Error: Need DSS version 1.70 or higher",CR,LF
;10
	DZ	"Copying "
;11
	DZ	"Directory of CDROM:"
;12		 FILENAME EXT SIZE DATE	TIME
	DZ	"%1 %2  %3  %4  %5",CR,LF
;13
	DZ	"  Error: Memory allocation error",CR,LF
;14
	DZ	" to "
;15
	DZ	"  Error: Reading failure",CR,LF
;16
	DZ	"  Error: Writing failure",CR,LF
;17
	DZ	"Failure!",CR,LF
;18
	DZ	"  Error: Can't open destination file",CR,LF
;19
	DZ	"Copying aborted",CR,LF
;20
.crlf:	DZ	CR,LF
;21
	BYTE	0
MSG1

BUF_PTRS
	DW	BUF1,BUF2,BUF3,BUF4,0

;-------------------------------/BUFFERS\-------------------------------;
FF_STRUCT:
	DB	"12345678"
	DB	"123"
	DB	#00
	DW	0,0,0,0
CDFPOSH	DW	0	;CLUSTER HIGH
CDFTIME	DW	0	;TIME
CDFDATE	DW	0	;DATE
CDFPOSL	DW	0	;CLUSTER
CDFSIZE	DW	0,0	;SIZE
CDFATTR	DB	#00	;ATTR
CDFNAME	DB	"12345678123",0
;
BUFFERS_START	EQU $
	;DS	256-($-FF_STRUCT)

DIRSPEC:	EQU FF_STRUCT+256
		;DB '\',0
		;DS 254
BUF1		EQU DIRSPEC+256
BUF2		EQU DIRSPEC+256+256
BUF3		EQU DIRSPEC+256+256+256
BUF4		EQU DIRSPEC+256+256+256+256
ARGCBUF		EQU DIRSPEC+256+256+256+256+256
DUMPBUF		EQU DIRSPEC+256+256+256+256+256+256
BUFFERS_END	EQU DUMPBUF+2048-BUFFERS_START
;
BUFERS_NUMBER	EQU 6
;
	ASSERT (DUMPBUF+2048 < #C000), "NO FREE SPACE FOR BUFFERS"
;-----------------------------------------------------------------------;
DEV_CFG
;[END]
