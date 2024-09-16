;cutil.asm
;CAMP07 
;utility routines

;fire_to_confirm() 
;returns 0 if fire key, nonzero val if not fire 
_FTC 
	+__COORD P_TOP,P_FTCC
	+__LAB2XY T_FTC
	JSR _GX_STR

	JSR _INPUTF1
	STA FRET1
	LDA #P_FTCC
	STA GX_LX1
	LDA #P_FTCC2
	STA GX_LX2
	LDA #P_TOP
	STA GX_LY1
	LDA #$01
	STA GX_LY2
	JSR _GX_RECT ;fill in space

	LDA FRET1
	BEQ @RTS
	CMP #$05
	BNE @RTS
	LDA #00 ;fast fire = confirm
@RTS 
	RTS 

;right_select(X=top row,Y=bottom)
;note: rows are separated by 2
;returns (selected row) to A/FRET1
_RSELECT 
	TXA 
	STA GX_CROW
	STA FRET1
_RSELSAV 
	LDA #$01
	STA SPRPOS8
	LDA #$04
	STA SPRPOS+0

	TYA 
	STA FVAR2
	TXA 
	STA FVAR1
	LDA #P_RSEL2C
	STA GX_CCOL
	LDA #$00
	STA GX_BCOL
	LDA #$01
	STA SPRON
@INPUT 
	JSR _RSEL4
	JSR _INPUTF1
	STA FVAR3
	JSR _RSEL2 ;erase prev arrow
	LDA FVAR3
	BEQ @FIRE

	CMP #VK_FASTF
	BEQ @FASTFIR

	CMP #VK_UP ;up
	BNE @DOWN

	JSR _SFXUP

	LDA FRET1
	SEC 
	SBC #$01
	STA FRET1
	LDA FRET1
	CMP FVAR1
	BCC @UWRAP
	BCS @INPUT
@UWRAP 
	LDA FVAR2
	STA FRET1
	BNE @INPUT
@DOWN 
	CMP #VK_DOWN
	BNE @INPUT

	JSR _SFXDOWN

	LDA FRET1
	CMP FVAR2
	BNE @DWRAP
	LDA FVAR1
	STA FRET1
	BNE @INPUT
@DWRAP 
	LDA FRET1
	CLC 
	ADC #$01
	STA FRET1
	LDA FRET1
	BNE @INPUT
@FIRE 
	JSR _SFXFIRE

	JSR _RSEL3
	JSR _INPUTF1 ;;fire
	BNE @INPUT
@FASTFIR 
	JSR _RSEL2

	JSR _SFXFIRE

	LDA #$00
	STA SPRON

	LDA FRET1
	SEC 
	SBC FVAR1
	STA FRET1

	RTS 

;erase arrow
_RSEL2 
	RTS 
	LDA #C_BLACK
	STA GX_DCOL
	LDA #$20
	STA GX_CIND
	JSR _GX_CHAR
	RTS 
;draw fire once arrow
_RSEL3 
	JSR _RSEL5
	LDA #C_DGRAY
_RSEL3_2 
	STA SPRCOL+0
	LDA GX_CROW
	ASL 
	ASL 
	ASL 
	CLC 
	ADC #$32
	STA SPRPOS+1
	RTS 
;draw standard arrow
_RSEL4 
	JSR _RSEL5
	LDA #C_LGRAY
	JSR _RSEL3_2
	RTS 
;update row
_RSEL5 
	LDA FRET1
	STA GX_CROW
	RTS 
;wrapper for action menu save select
_RSEL6 
	JSR _RSEL5
	JSR _RSELSAV
	RTS 

;percent2(smaller=farg1(L),f2(H); larger=f3,f4)
;does not convert to string
_PERCEN2 
	LDA FARG2
	LDY FARG1
	JSR _162FAC
	JSR _FAC2ARG
	LDA FARG4
	LDY FARG3
	JSR _162FAC
	JSR _DIVIDE ;FAC = ARG / FAC
	JSR _CLRSTR
	RTS 

;divide_float()
;jumps to FDIVT, but clears zero flag automatically (otherwise FDIVT throws an error)
_DIVIDE
	JSR _POSFLOAT
	LDA #$01
	JSR _FDIVT
	JSR _POSFLOAT
	RTS

;multiply_float()
;jumps to FMULTT, but clears zero flag automatically (otherwise FMULTT will immediately quit if zero flag set)
_MULTIPLY
	JSR _POSFLOAT
	LDA #$01
	JSR _FMULTT
	JSR _POSFLOAT
	RTS

;subtract_float()
_SUBTRACT
	JSR _POSFLOAT
	JSR _FSUBT
	JSR _POSFLOAT
	RTS

;percent(smaller=farg1(L),f2(H); larger=f3,f4)
;ARGUMENTS ARE NOT POINTERS
;divides smaller (value!) by larger
;#7FFF is max positive value?
_PERCENT 
	JSR _PERCEN2
	JSR _PERCTRUNC
	RTS

;load_fixed_percent(_PCTRL called before, X = player index)
;loads the fixed percentages calculated in _PCTRL, divided by 100
_LDAFPERC
	JSR _SETFPERC
	
	LDA OFFSET
	LDY OFFSET+1
	JSR _MOVFM
	JSR _FDIV10
	JSR _FDIV10
	RTS

;percent_truncate() 
;transfers string to V_FPOINT, truncates to 2 digits
_PERCTRUNC 
	JSR _STRPERC
_PERCTRUNC2
	LDA #00 ;draw 2 digits only
	STA V_FPOINT+3
	LDA #VK_PERC
	STA V_FPOINT+2
	RTS 

;arg_to_float3() 
;transfers ARG to FLOAT3
; _ARG2F3 
	; LDX #00
; @LOOP 
	; LDA ARG,X
	; STA V_FLOAT3,X
	; INX 
	; CPX #FLOATLEN
	; BNE @LOOP
	; RTS 
;float3_to_arg() 
_F32ARG 
	LDX #00
@LOOP 
	LDA V_FLOAT3,X
	STA ARG,X
	INX 
	CPX #FLOATLEN
	BNE @LOOP
	RTS 
;fac_to_float3() 
;transfers FAC to FLOAT3
_FAC2F3 
	LDX #00
@LOOP 
	LDA FAC,X
	STA V_FLOAT3,X
	INX 
	CPX #FLOATLEN
	BNE @LOOP
	RTS 
;float3_to_fac() 
_F32FAC 
	LDX #00
@LOOP 
	LDA V_FLOAT3,X
	STA FAC,X
	INX 
	CPX #FLOATLEN
	BNE @LOOP
	RTS 
;fac_to_margin() 
;transfers FAC to V_MARGIN
_FAC2MARG
	LDX #00
@LOOP 
	LDA FAC,X
	STA V_MARGINF,X
	INX 
	CPX #FLOATLEN
	BNE @LOOP
	RTS 

;percent_string(FAC = percentage to draw in original decimal format)
;outputs 5-char percentage string from FAC to V_FPOINT
_STRPERC
	JSR _FMUL10
	JSR _FMUL10
	JSR _FAC2STR
	
	LDX #00 ;zeroes
@00LOOP 
	LDA T_00PC,X
	STA V_FPOINT,X
	INX 
	CPX #FLOATLEN ;zero-terminated
	BNE @00LOOP

	LDA #<D_FLOATCAP
	LDY #>D_FLOATCAP
	JSR _FCOMP
	BPL @NOTMIN
	RTS
@NOTMIN
	LDA #<D_FLOATMAX
	LDY #>D_FLOATMAX
	JSR _FCOMP
	BNE @NOTMAX
	BMI @NOTMAX
	
	LDX #00
@99LOOP 
	LDA T_99PC,X
	STA V_FPOINT,X
	INX 
	CPX #FLOATLEN ;zero-terminated
	BNE @99LOOP
	RTS
	
@NOTMAX
	
	LDA V_STRING
	CMP #VK_SPACE
	BNE @SPACE
	LDX #00
@SHIFTLP
	LDA V_STRING+1,X
	STA V_STRING,X
	INX
	CPX #FLOATLEN
	BNE @SHIFTLP
@SPACE

	LDX #00
@DECLOOP
	LDA V_STRING,X
	CMP #VK_DEC ;decimal
	BEQ @DECFOUND
	INX
	CPX #03
	BNE @DECLOOP
	BEQ @NODEC
@DECFOUND
	TXA ;2 - X
	CLC
	ADC #$FE
	JSR _NEGATIV
	TAX
	LDY #00
@COPYLOOP
	LDA V_STRING,Y
	BEQ @NULL
	CMP #VK_DEC
	BEQ @SKIP
	STA V_FPOINT,X
@SKIP
	INX
	INY
	CPX #FLOATLEN
	BNE @COPYLOOP
@NULL
	RTS
@NODEC
	LDX #00
@NULLLP
	LDA V_STRING,X
	BEQ @DECFOUND
	INX
	BNE @NULLLP

;float_append_percent() 
;applies to V_FPOINT
_FSTRAP 
	LDA #VK_PERC
	STA V_FPOINT+5
	LDA #00
	STA V_FPOINT+6
	RTS 

;clear_string() 
_CLRSTR 
	LDX #00
	LDA #00
@LOOP 
	STA V_STRING,X
	INX 
	CPX #10
	BNE @LOOP
	RTS 

;offset(x,y,OFFSET) 
;adds (Y times X) to OFFSET
_OFFSET 
	CPX #00
	BEQ @RTS
@LOOP 
	TYA
	CLC 
	ADC OFFSET
	STA OFFSET
	BCC @CARRY
	INC OFFSET+1
@CARRY 
	DEX
	BNE @LOOP
@RTS 
	RTS

;cp_offset()
;sets CP_ADDR to state CP 8-block, IS_ADDR to issue 5-block
;LOCAL: FX1,FY1
_CPOFFS 
	STX FX1
	STY FY1
	STA CPSTATE ;save state
	+__LAB2O V_CP
	LDY #CPBLOCK
	LDX CPSTATE
	DEX ;in state index starts at 1
	JSR _OFFSET
	LDA OFFSET
	STA CP_ADDR
	LDA OFFSET+1
	STA CP_ADDR+1

	+__LAB2O V_ISSUE
	LDY #$05
	LDX CPSTATE
	DEX 
	JSR _OFFSET
	LDA OFFSET
	STA IS_ADDR
	LDA OFFSET+1
	STA IS_ADDR+1

	LDX FX1
	LDY FY1
	RTS 

;cp_offset_inc() 
;increments both CP_ADDR and IS_ADDR to next state
;returns boolean (last state)
_CPOFFI 
	LDA CP_ADDR
	CLC 
	ADC #CPBLOCK
	STA CP_ADDR
	BCC @CARRY
	INC CP_ADDR+1
@CARRY 
	LDA IS_ADDR
	CLC 
	ADC #$05
	STA IS_ADDR
	BCC @CARRY2
	INC IS_ADDR+1
@CARRY2
	INC CPSTATE
	LDA CPSTATE
	CMP #STATE_C
	RTS 

;cp_offset_reset()
_CPOFFR 
	LDA #<V_CP
	STA CP_ADDR
	LDA #>V_CP
	STA CP_ADDR+1
	LDA #<V_ISSUE
	STA IS_ADDR
	LDA #>V_ISSUE
	STA IS_ADDR+1
	;does NOT reset HS_ADDR!
	LDA #01
	STA CPSTATE
	RTS 

;cp_offset_max()
_CPOFFM
	LDA CPSTATE
	CMP #STATE_C
	RTS

_RNG 
	STA RNG1
	LDA #$FF
	STA RNG2
@LOOP 
	LDA RNG1
	CMP RNG2
	BCS @QUIT
	LSR RNG2
	JMP @LOOP
@QUIT 
	SEC 
	ROL RNG2
@REROLL 
	LDA VOICE3OUT
	AND RNG2
	CMP RNG1
	BCS @REROLL
	CMP #$00
	RTS 
_COINFLIP
	LDA #02
	JSR _RNG
	RTS

;random_state()
;generates a random state and returns to A/FSTATE
_RANDSTATE
	LDA #STATE_C-1
	JSR _RNG
	CLC
	ADC #$01
	STA FSTATE
	RTS
	
;random_medium_state()
;generates a random medium state and returns to A
_RANDMEDSTA	
	LDA #MEDSTAC
	JSR _RNG
	TAX
	LDA D_MEDSTA,X
	RTS
	
;random_megastate()
;generates a random megastate and returns to A
_RANDMEGAST
	LDA #MEGASTAC
	JSR _RNG
	TAX
	LDA D_MEGAST,X
	RTS
	
;state_is_medium_state(FSTATE = state)
;returns whether state is a medium state
_ISMEDSTA
	
;clears the visit log
_CLRVISLOG
	LDX #00
	TXA
@LOOP
	STA V_VISLOG,X
	INX
	BNE @LOOP
	RTS

;int(x(L),a(U)) 
;converts value to decimal INT, stores to string
;copy of ROM routine, does not print

_INT 
	STA FSUS1
	STX FSUS2
	JSR _CLRSTR
	JSR _CLRFAC
	LDA FSUS1
	STA FAC+1
	LDX FSUS2
	STX FAC+2
	LDX #$90
	SEC 
	JSR _ABS2
	JSR _FAC2STR2
	RTS 
	
_INTCMB
	JSR _INT
	+__LAB2XY V_STRING
	JSR _GX_STR
	RTS
_INTCMB2
	JSR _INT
	JSR _INTWS3
	+__LAB2XY V_STRING
	JSR _GX_STR
	RTS
	
_INPUT
	JSR _GETINP
	CMP #00
	RTS 

;input_filter_1() 
;only filters joystick keys (IJKLM<sp>)
;0=confirm,1=up,2=left,3=down,4=right,5=fastconfirm 
_INPUTF1 
	JSR _INPUT
	CMP #$20
	BEQ @SPACE
	CMP #$49
	BCC _INPUTF1
	CMP #$4F
	BCS _INPUTF1
	SEC 
	SBC #$48
	JMP @RTS
@SPACE 
	LDA #00
@RTS 
	RTS 

;input_filter_2() 
;only filters ALPHA + NUMERAL keys
;also handles space=20,bs=14,return=0D
_INPUTF2 
	JSR _INPUT
	CMP #VK_SPACE
	BEQ @RTS
	CMP #VK_RET
	BEQ @RTS
	CMP #VK_BACK
	BEQ @RTS
	CMP #VK_SPACE
	BCC _INPUTF2
	CMP #$5B
	BCS _INPUTF2
@RTS 
	CMP #00
	RTS 

;input_filter_3()
;only filters NUMERAL keys
_INPUTF3
@INPUT
	JSR _INPUTF2
	CMP #$30
	BCC @INPUT
	CMP #$3A
	BCS @INPUT
	RTS
	
;player_name_input() 
_NAMEINP
	LDA #00
	TAX
	STA FVAR1 ;cursor pos
@CLRLOOP
	STA V_SETTEMP,X ;used for string temp
	INX
	CPX #NAMELEN
	BNE @CLRLOOP

	+__COORD P_PLAYNR,P_PLAYNC
	LDA #NAMELEN-1
	JSR _DRWBLANK
	+__COORD P_PLAYNR,P_PLAYNC
	
	LDA #C_WHITE
	STA GX_DCOL
	STA FVAR2 ;party color
	JSR _NAMEIN2

@GETINP 
	LDA FVAR2
	STA GX_DCOL

	JSR _INPUTF2
	CMP #VK_SPACE
	BEQ @SPACE
	CMP #VK_RET
	BEQ @PPROC
	CMP #VK_BACK
	BEQ @BACKSP
	;valid key
@DRAW 
	STA GX_CIND
	LDX FVAR1
	STA V_SETTEMP,X 
	JSR _GX_CHAR
	INC GX_CCOL
	INC FVAR1

	JSR _NAMEIN2

	LDA FVAR1
	CMP #NAMELEN-1
	BNE @GETINP
	BEQ @PPROC

@SPACE 
	LDA #$20
	BNE @DRAW
@BACKSP 
	LDX FVAR1
	BEQ @GETINP
	DEC GX_CCOL
	DEC FVAR1
	DEX 
	LDA #$20
	STA V_SETTEMP,X
	JSR _NAMEIN2
	JMP @GETINP
@PPROC 
	JSR _NAMEIN3
	;do postproccessing
	LDA V_SETTEMP
	BEQ @PLAYVER ;no empty name

	CMP #$20 ;no leading space
	BEQ @PLAYVER

	+__LAB2O V_PNAME
	LDX V_PARTY
	LDY #NAMELEN
	JSR _OFFSET

	LDX #00
	LDY #00
@CLOOP 
	LDA V_SETTEMP,X
	STA (OFFSET),Y
	INX 
	INY 
	CPX #NAMELEN-1
	BNE @CLOOP
	LDA #00
	LDY #NAMELEN-1
	STA (OFFSET),Y
	
@PLAYVER ;display final name
	+__COORD P_PLAYNR,P_PLAYNC
	LDA V_PARTY
	JSR _DRWPLYR

	JSR _FTC
	BEQ @DONE
	JMP _NAMEINP ;reinput if denied
@DONE 
	RTS 
;draw cursor
_NAMEIN2 
	LDA #FILLCHR
	STA GX_CIND
	JSR _GX_CHAR ;draw cursor
	INC GX_CCOL
_NAMEIN3 
	LDA #C_BLACK
	STA GX_DCOL
	LDA #$20
	STA GX_CIND ;clear in front of cursor
	JSR _GX_CHAR
	DEC GX_CCOL
	RTS 

;copy(farg1,farg2,farg3,farg4,farg5) 
;copies [length farg5] $(2,1) to $(4,3)
_COPY
	LDY #00
@LOOP 
	LDA (FARG1),Y
	STA (FARG3),Y
	INY 
	CPY FARG5
	BNE @LOOP
	RTS

;intws3() 
;pads intstring with whitespace
_INTWS3 
	LDY #$FF
@LOOP 
	INY 
	LDA V_STRING,Y
	BEQ @TERM
	CMP #$2E
	BEQ @TERM
	JMP @LOOP
@TERM 
	TYA 
	TAX 
	CPX #$03
	BNE @DONE
	JMP @ADDTERM
@DONE 
@LOOP2 
	LDA #$20
	STA V_STRING,X
	INX 
	CPX #$03
	BNE @LOOP2
@ADDTERM 
	LDA #$00
	STA V_STRING,X
	RTS 

;clear_floating_point() 
_CLRFP 
	LDA #00
	TAX 
@CLRLOOP 
	STA V_FPOINT,X
	INX 
	CPX #$09
	BNE @CLRLOOP
	RTS 

;clear_fac_arg() 
_CLRFAC 
	LDA #00
	LDX #00
@LOOP 
	STA FAC,X
	STA ARG,X
	STA V_FLOAT3,X
	INX 
	CPX #FLOATLEN
	BNE @LOOP
	RTS 

;charset() 
_CHARSET 
	JSR _CHARSET1
	JSR _CHARSET2
	RTS 
;copies character set to RAM
_CHARSET1 
	LDA $DC0E
	AND #$FE
	STA $DC0E
	LDA $01
	AND #$FB
	STA $01
	LDA #$D1
	STA $FC
	LDA #$39
	STA $FE
	LDY #00
	STY $FB
	STY $FD
@LOOP 
	LDA ($FB),Y
	STA ($FD),Y
	DEY 
	BNE @LOOP

	DEC $FC
	DEC $FE
	LDA #$37
	CMP $FE
	BNE @LOOP

	LDA $01
	ORA #$04
	STA $01
	LDA $DC0E
	ORA #$01
	STA $DC0E
	LDA $D018
	AND #$F0
	ORA #$0E

	STA $D018
	RTS 
;different characters
_CHARSET2 
	LDX #$2F
	LDY #$00
	JSR _CHARSET3

	LDX #$29
	LDY #$08 * 1
	JSR _CHARSET3

	LDX #$3B
	LDY #$08 * 2
	JSR _CHARSET3
	
	LDX #$1C
	LDY #$08 * 3
	JSR _CHARSET3
	
	LDX #$1E
	LDY #$08 * 4
	JSR _CHARSET3
	
	LDX #$1F
	LDY #$08 * 5
	JSR _CHARSET3
	
	LDA #<D_EXCHAR+(CHARLEN*6)
	STA FARG1
	LDA #>D_EXCHAR+(CHARLEN*6)
	STA FARG2
	LDA #<NEWCHAR+(CHARLEN*64)
	STA FARG3
	LDA #>NEWCHAR+(CHARLEN*64)
	STA FARG4
	LDA #(CHARLEN*31)
	STA FARG5
	JSR _COPY
	
	RTS 

;add extra character
;X = CHARACTER INDEX, Y = EXTRA CHARACTER MAPPING
_CHARSET3 
	STY FVAR1
	+__LAB2O NEWCHAR
	LDY #$08
	JSR _OFFSET
	LDX FVAR1
	LDY #00
@LOOP 
	LDA D_EXCHAR,X
	STA (OFFSET),Y
	INY 
	INX 
	CPY #$08
	BNE @LOOP

	RTS 

;copy_lean()
;copies lean from CP_ADDR/HS_ADDR to V_LEAN
_COPYLEAN
	LDY #CPBLEAN
	LDX #00
	LDA V_SUMFH
	BNE @HIST
@LOOP
	LDA (CP_ADDR),Y
	STA V_LEAN,X
	INX
	INY
	CPX #CPBLEAN
	BNE @LOOP
	RTS
@HIST
	LDA (HS_ADDR),Y
	STA V_NIBBLE
	JSR _UNIBBLE
	LDA V_NIBBLE+0
	STA V_LEAN,X
	LDA V_NIBBLE+1
	INX
	STA V_LEAN,X
	INX
	INY
	CPY #HISTBLOCK-1
	BNE @HIST
	RTS
	
_LEANTOMAX
	LDX #00
	LDY #00
@COPYLOOP
	LDA V_LEAN,X
	STA V_MAX,Y
	INX
	INY
	INY
	CPX S_PLAYER
	BNE @COPYLOOP
	RTS

;set_player_limits(A = player count)
_SETPLIM
	STA S_PLAY1L
	STA S_PLAY1M
	DEC S_PLAY1L
	INC S_PLAY1M
	RTS
	
;float_to_offset(Y = party index)
_FLT2OFF
	+__LAB2O V_CPFLOAT
	LDX #FLOATLEN
	JSR _OFFSET
	RTS
	
;load_region_limits(X = region index)
_LREGLIM
	LDA D_REGLIM-1,X
	STA LOWSTATE
	LDA D_REGLIM,X
	STA HIGHSTATE
	RTS
	
;store_bit(OFFSET = address, X = bit starting from least significant bit 0, A = set value (0 or 1))
;sets bit X at address OFFSET, Y to A
;example: A = 0; X = 0; byte = 11111111; result = 11111110
;example: A = 1; X = 0; byte = 11111111; result = 11111111
;example: A = 1; X = 3; byte = 11110000; result = 11111000
_STABIT
	CMP #00
	BEQ @ZERO
	LDA #01 ;any value not zero = 1
@LOOP
	CPX #00
	BEQ @DONE
	ASL
	DEX
	BNE @LOOP
@DONE
	ORA (OFFSET),Y
	STA (OFFSET),Y
	RTS
@ZERO
	LDA #%11111110
@LOOP2
	CPX #00
	BEQ @DONE2
	SEC
	ROL
	DEX
	BNE @LOOP2
@DONE2
	AND (OFFSET),Y
	STA (OFFSET),Y
	RTS
	
;load_bit(OFFSET = address, X = bit starting from least significant bit 0)
;loads bit X at address OFFSET, Y (returns non-zero)
_LDABIT
	LDA #01
@LOOP
	CPX #00
	BEQ @DONE
	ASL
	DEX
	BNE @LOOP
@DONE
	AND (OFFSET),Y
	BEQ @RTS
	LDA #01
@RTS
	RTS
	
;FAC_is_zero
_FACIS0
	LDX #00
@LOOP
	LDA FAC,X
	BNE @FALSE
	INX
	CPX #FLOATLEN
	BNE @LOOP
	LDA #01
	RTS
@FALSE
	LDA #00
	RTS
	
;pack_nibble(V_NIBBLE+0/+1)
;packs two 4-bit values (formatted like #%0000xxxx)
;returns A = packed value
_NIBBLE
	LDA V_NIBBLE+0
	ASL
	ASL
	ASL
	ASL
	ORA V_NIBBLE+1
	RTS