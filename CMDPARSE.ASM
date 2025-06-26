
; HL - exe-prefix
; IX - pointers at work buffers
EX_COMMAND_LINE:
		INC	HL
.NEXTPR:	LD	DE,ARGCBUF
		LD	BC,Dss.EX_Path.GSWITCH
		RST	ToDSS
		PUSH	AF
		PUSH	HL
		LD	A,(ARGCBUF)
		OR	A
		JR	Z,.EOCL		;end of command line
		CP	"-"
		JR	Z,.ITCKEY
		CP	"/"
		JR	Z,.ITCKEY
		LD	HL,ARGCBUF
		LD	E,(IX+0)
		LD	D,(IX+1)
		INC	IX
		INC	IX
		LD	A,D
		OR	E
		JR	Z,.CL_FAILURE
		;LD	A,1
		;LD	(NAME_FLG),A
.MOVNAME:	LD	A,(HL)
		LDI
		OR	A
		JR	NZ,.MOVNAME
		;
.EOCL:		POP	HL
		POP	AF
		JR	NC,.NEXTPR
		RET
		;
.CL_FAILURE:	POP	HL
		POP	AF
		RET

.ITCKEY:	LD	A,(ARGCBUF+1)
		CP	"5"
		JR	NC,.HELP
		CP	"1"
		JR	NC,.number
		; ERROR
		LD	HL,ARGCBUF+1
		CALL	PUTVAR
		LD	A,MSG_UNK_DEVICE_NUMBER
		CALL	MESSAGE
		LD	A,1
		LD	(STOPMODE),A
		JR	.EOCL
		;
.number:	SUB	'1'
		OR	#C0
		;
		PUSH	IX
		PUSH	AF
		CALL	RESTORE_STATE
		XOR	A
		LD	(RESTORE_STATE.set_par),A
		POP	AF
		LD	(CDDRIVE),A
		LD	C,BIOS.DRV_DETECT
		RST	ToBIOS
		POP	IX
		JR	NC,.EOCL
		;
		CP	BIOS.Error.ATAPI.UnitAttention
		JR	NZ,.error
		;
		LD	A,(CDDRIVE)
		PUSH	IX
		CALL	SAVE_MEDIA_CHANGED
		POP	IX
		JR	NC,.EOCL
		;
.error:		LD	HL,ARGCBUF+1
		CALL	PUTVAR
		LD	A,MSG_NO_CDROM
		CALL	MESSAGE
		LD	A,1
		LD	(STOPMODE),A	
		SCF
		JR	.CL_FAILURE
		;
.HELP:		LD	A,MSG_USAGE
		CALL	MESSAGE
		LD	A,1
		LD	(STOPMODE),A
		JR	.EOCL



; MAS_CD:
; 	;LD	A,MASTER
; 	;LD	(CDDRIVE),A
; 	JR	EOCL

; SLA_CD:
; 	;LD	A,SLAVE
; 	;LD	(CDDRIVE),A
; 	JR	EOCL
