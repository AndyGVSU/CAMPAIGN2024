;cdebate1.asm
;CDEBATE - DEBATE CODE

;checks if debate on, and runs if on
_DCHECK 
	LDA S_DEBTON
	BNE @ON
@RTS 
	RTS 
@ON 
	LDA V_PARTY
	BNE @RTS
	LDA V_WEEK
	CMP #$04
	BEQ @DEBWEEK
	CMP #$07
	BEQ @DEBWEEK
	BNE @RTS
@DEBWEEK 
	JSR _DMAIN
	RTS 

;main debate SR
_DMAIN 
	LDA #$01
	STA V_DEBON
	
	JSR _GX_CLRS
	JSR _DRWBORD2
	JSR _DNETWRK
	JSR _CANDOTHR
	
	LDA S_SKIPGAME
	BNE @SKIP1
	
	JSR _DINTRO
	JSR _FTC
@SKIP1
	JSR _MAPCMB1
	LDA #00
	STA V_SUMFH
	STA V_OUTOFM
	STA V_STAFFOUT
	JSR _MAPCMB2
	JSR _POPCMB2
	
	LDA S_SKIPGAME
	BNE @SKIP2
	JSR _CANDLOOP
@SKIP2

	JSR _DQUESTN
	JSR _DNATL
	
	JSR _STCTRL
	LDA #00
	STA V_PARTY
	JSR _CANDLOAD
	
	JSR _DLOG

	LDA #$00
	STA V_REDRW1
	STA V_PARTY

	JSR _MAPCMB1

	LDA #00
	STA V_DEBON
	RTS 

;choose debate TV network
_DNETWRK 
	LDA #$03
	JSR _RNG
	STA V_DCTV
	LDA V_WEEK
	CMP #$07
	BNE @DONE
	LDA V_DPRVTV
	CMP V_DCTV
	BEQ _DNETWRK
@DONE 
	LDA V_DCTV
	STA V_DPRVTV
	RTS 



;debate_intro() 
_DINTRO 
	+__LAB2XY T_DINTRO
	+__COORD P_DINTRR,P_DINTRC
	JSR _GX_STR

	+__COORD P_DINTVR,P_DINTVC
	JSR _DDRWTV

	+__LAB2O T_DEBNUM
	LDA V_WEEK
	CMP #$04
	BEQ @DRWCT
	LDA OFFSET
	CLC 
	ADC #$05
	STA OFFSET
	BCC @DRWCT
	INC OFFSET+1
@DRWCT 
	+__COORD P_DINCTR,P_DINCTC
	+__O2XY
	JSR _GX_STR

	RTS 

;debate_draw_tv_network() 
_DDRWTV 
	+__LAB2O T_DEBNET
	LDX V_DCTV
	LDY #$05
	JSR _OFFSET
	+__O2XY
	JSR _GX_STR
	RTS 

;main question loop
_DQUESTN 
	LDA #$01
	STA V_DQUEST

	JSR _DINIT
@TOP 
	LDA #$00
	STA DPARTY ;current action block processed
	STA V_PARTY
	JSR _DSTATE
	JSR _DNEXTQ
	JSR _DRESET

	+__LAB2O2 V_DACT
@ACTLOOP 
	LDA DPARTY
	JSR _CANDLOAD

	LDX DPARTY
	LDA V_AI,X
	BNE @AISKIP

	LDA #$00
	STA V_DPHASE
	JSR _DCLEAR

	JSR _DCLRMR

	LDA #00
	STA V_REDRW1
	JSR _DRWCAND

	+__COORD P_DPLYRR,P_DPLYRC
	LDA DPARTY
	JSR _DRWPLYR

	JSR _DACTSEL
	JMP @ACTDONE
@AISKIP
	JSR _DACTAI
@ACTDONE
	JSR _DACTINC
	LDA DPARTY
	JSR _CANDSAVE
	
	INC DPARTY
	LDA DPARTY
	STA V_PARTY
	CMP S_PLAYER
	BNE @ACTLOOP

	LDA #$01
	STA V_DPHASE
	JSR _CLRBL
	JSR _DDRWRIN
	
	+__LAB2O2 V_DACT
	LDA #$00
	STA DPARTY ;..
@RCTLOOP
	JSR _DRCTCHK
	BEQ @RCTDONE

	LDY #02
	LDA (OFFSET2),Y
	TAX
	LDA V_AI,X
	BNE @RCTAI

	JSR _DRCTSEL
	JMP @RCTDONE
@RCTAI
	JSR _DRCTAI
@RCTDONE
	JSR _DACTINC
	INC DPARTY
	LDA DPARTY
	CMP S_PLAYER
	BNE @RCTLOOP

	JSR _DQRESLT
	LDX V_DQUEST
	JSR _DADDLOG
	LDX V_DQUEST
	DEX 
	JSR _DPENLOG
	JSR _DAPLYDP
	JSR _DDPTOTL

	INC V_DQUEST
	LDA V_DQUEST
	CMP #$04
	BEQ @RTS
	JMP @TOP
@RTS 
	RTS 

;debate_action_block_increment() 
;move to next candidate's action schedule
_DACTINC 
	LDA OFFSET2
	CLC 
	ADC #$07
	STA OFFSET2
	BCC @CARRY
	INC OFFSET2+1
@CARRY 
	RTS 

;generate question state
_DSTATE 
	JSR _DSTATE2
	STA V_DQSTAT
	JSR _CPOFFS
	LDY #00
@CPYISS 
	LDA (IS_ADDR),Y
	STA V_DISSUE,Y
	INY 
	CPY #$05
	BNE @CPYISS

	LDX #$00
@TOP 
	LDA V_DCTV
	BNE @TV1
	LDA V_DISSUE,X
	CMP #$06
	BNE @ISSUE1
	LDA #$03
@DEC 
	DEC V_DISSUE,X
	BNE @ADJUST
@ISSUE1 
	CMP #$01
	BNE @ADJUST
	LDA #$03
@INC 
	INC V_DISSUE,X
	BNE @ADJUST
@TV1 
	CMP #$01
	BEQ @INC
	CMP #$02
	BEQ @DEC
@ADJUST 
	INX 
	CPX #$05
	BNE @TOP

	JSR _DSTATE4
	JSR _DSTATE3
	RTS 

;check picked state/question for repeats
_DSTATE2 
	JSR _DSTATE3
	
	CMP V_DSTATE+0
	BEQ _DSTATE2
	CMP V_DSTATE+1
	BEQ _DSTATE2
	CMP V_DSTATE+2
	BEQ _DSTATE2
	LDX V_DQUEST
	STA V_DSTATE-1,X
	RTS 
;pick question/state
_DSTATE3 
	LDA V_DQUEST
	CMP #$01 ;q1
	BNE @Q2

	LDA #$00
	STA OFFSET
	STA OFFSET+1
	LDX V_DCTV
	LDY #$03
	JSR _OFFSET

	LDA #$03
	JSR _RNG
	CLC 
	ADC OFFSET
	TAX 
	LDA D_TV2REG,X
	TAX 

	JSR _LREGLIM

@REROLL 
	JSR _RANDSTATE
	CMP LOWSTATE
	BCC @REROLL
	CMP HIGHSTATE
	BCS @REROLL
	RTS 
@Q2 
	CMP #$02
	BNE @Q3

	JSR _RANDMEDSTA
	RTS 
@Q3 
	JSR _RANDSTATE
	RTS 

;calculate "others" value for state
_DSTATE4 
	LDX #$00
@CPLOOP 
	LDA V_DISSUE,X
	STA V_STRING,X
	INX 
	CPX #$05
	BNE @CPLOOP
	JSR _AVGISSU
	LDA FRET1
	STA V_DISSUE+5
	RTS

;generate + draw next question
;LOCAL: FVAR1
_DNEXTQ
	LDA S_SKIPGAME
	BNE @REROLL
	
	JSR _GX_CLRS
	JSR _DRWBORD2
	+__COORD P_DBQR,P_DBQC
	+__LAB2XY T_QUEST
	JSR _GX_STR

	+__COORD P_DBQR,P_DBQNC

	LDA #C_WHITE
	STA GX_DCOL
	LDA V_DQUEST
	ORA #NUMBERS
	STA GX_CIND
	JSR _GX_CHAR

	+__COORD P_DBQR,P_DBQTC

	JSR _DDRWTV
	
@REROLL 
	LDA #$18
	JSR _RNG
	CMP V_DTOPIC+0
	BEQ @REROLL
	CMP V_DTOPIC+1
	BEQ @REROLL
	CMP V_DTOPIC+2
	BEQ @REROLL

	TAY 
	LDX V_DQUEST
	DEX 
	STA V_DTOPIC,X
	TAX 
	STA FVAR1

	LDA D_DTOPIC,Y
	TAX 
	AND #$0F
	STA V_DISS1
	TXA 
	LSR 
	LSR 
	LSR 
	LSR 
	STA V_DISS0

	LDA S_SKIPGAME
	BNE @RTS

	+__COORD P_DBQPR,P_DBQPC
	+__LAB2XY T_DQUEST
	JSR _GX_STR

	+__COORD P_DTOPR,P_DTOPC
	JSR _DRWTOPC

	+__COORD P_DBQPR,P_DBQPC
	LDA #C_YELLOW
	STA GX_DCOL
	LDA V_DQSTAT
	JSR _DRWPOST

	JSR _FTC
@RTS
	RTS 
;debate_draw_topic()
_DRWTOPC 
	+__LAB2O T_DTOPIC
	LDX V_DQUEST
	LDA V_DTOPIC-1,X
	TAX 
	LDY #$10
	JSR _OFFSET
	+__O2XY
	LDA #C_YELLOW
	STA GX_DCOL
	JSR _GX_STR
	RTS 

_DRWBORD2
	LDA S_SKIPGAME
	BNE @SKIP
	JSR _DRWBORD
	LDA #C_BLUE
	STA GX_DCOL
	LDA #P_MAPC
	STA GX_LX1
	LDA #P_MAP2C
	STA GX_LX2
	LDA #P_MAPR
	STA GX_LY1
	LDA #P_MAP2R
	STA GX_LY2
	JSR _GX_RECT
@SKIP
	RTS 

;debate_action_select() 
;LOCAL: FVAR1,2
_DACTSEL 
	JSR _DSTATUS
	JSR _DAMENU
@BACK 
	JSR _DSMENU
	LDX #P_DAMR2
	LDY #P_DAMR3
	JSR _RSELECT
	LDY #$00
	STA (OFFSET2),Y
	CMP #DBPERSNL
	BEQ @NEXT2
	CMP #DBREST
	BNE @SKIPFTC
	JMP @REST
@SKIPFTC
	JSR _DIMENU
	BEQ @BACK
	SEC 
	SBC #$01
	LDY #$01
	STA (OFFSET2),Y

	LDY #$00
	LDA (OFFSET2),Y
	CMP #DBSURVEY
	BNE @NEXT1
	JSR _DSURVEY ;new
	BEQ @BACK
@NEXT1 
	CMP #DBALLY
	BEQ @NEXT2
	CMP #DBDIFFER
	BEQ @NEXT2
	CMP #DBMORAL
	BEQ @NEXT2
	BNE @FTC
@NEXT2
	LDY #00
	LDA (OFFSET2),Y
	CMP #DBPERSNL
	BNE @SKIPCHK
	LDA V_DPERSNL
	BEQ @BACK
@SKIPCHK
	JSR _CLRBR
	LDA #00
	TAX 
	JSR _DOMENU

	BNE @NEXT3
	JMP @BACK
@NEXT3 
	TAX 
	DEX 
	LDA V_DOPPON,X
	LDY #$02
	STA (OFFSET2),Y
@FTC 
	JSR _FTC
	BEQ @RTS
	JMP @BACK
@RTS 
	RTS
@REST
	LDY #$01
	LDA #$FF
	STA (OFFSET2),Y
	JMP @FTC
	
;averages issue values
;FRET1 = VALUE
_AVGISSU 
	LDA #$00
	TAX
	TAY
@ADDLOOP
	PHA
	LDA V_STRING,Y
	CMP #ISSUEX
	BCS @SKIPXN
	PLA
	CLC 
	ADC V_STRING,Y
	INX
	JMP @INCY
@SKIPXN
	PLA
@INCY
	INY
	CPY #$05
	BNE @ADDLOOP
	
	STX FX1 ;non "issue X/N" count
	CPX #00
	BEQ @NONE
	
	TAY 
	LDA #00
	JSR _162FAC
	JSR _FAC2ARG
	LDA #$00
	LDY FX1
	JSR _162FAC
	JSR _DIVIDE	
	JSR _FAC2STR
	LDA V_STRING+2
	BNE @SKIP
	LDA V_STRING+1
	BNE @SKIP2
@SKIP 
	LDA V_STRING+3
	CMP #$35
	BCC @CARRY
	INC V_STRING+1
@CARRY 
	LDA V_STRING+1
@SKIP2 
	SEC 
	SBC #$30
	STA FRET1
	RTS
@NONE
	LDA #ISSUEX
	STA FRET1
	RTS 
	

;candidate_others_values()
;calculates "OTHER" values for all candidates
_CANDOTHR
	LDA #$00
	STA V_PARTY
@LOOP
	LDA V_PARTY
	JSR _CANDLOAD
	JSR _CANDOTHR2
	INC V_PARTY
	INX
	CPX S_PLAYER
	BNE @LOOP
	
	LDA #00
	JSR _CANDLOAD
	RTS
_CANDOTHR2
	LDX #00
@ISSLOOP
	LDA C_ISSUES,X
	STA V_STRING,X
	INX
	CPX #$05
	BNE @ISSLOOP
	
	JSR _AVGISSU
	LDA FRET1
@OTHER
	LDX V_PARTY
	STA V_DOTHER,X
	RTS

_DINIT 
	LDA #00
	TAX 
@LOOP 
	STA V_DPCOUN,X
	STA V_DPOBSC,X
	STA V_DPCURR,X
	STA V_DPPREV,X
	STA V_DDP,X
	STA V_DDPQ,X
	STA V_DNATL,X
	INX 
	CPX #$04
	BNE @LOOP
	RTS 

;debate_ai_get_incorrect_issue()
;X = issue index
_DAIGNS
	LDA #$06
	JSR _RNG
	CMP V_DISS0
	BEQ _DAIGNS
	CMP V_DISS1
	BEQ _DAIGNS
	TAX
	RTS
	
;debate_ai_get_opponent()
;returns A = random non-self player index
_DAIGOPP
	LDA S_PLAYER
	JSR _RNG
	CMP V_PARTY
	BNE @RTS
	JMP _DAIGOPP
@RTS
	RTS
	
	
;debate_ai_issue_is_x/n(X = party index, Y = issue index)
;returns boolean issue is X or N
_DBAIXN
	JSR _DLCISS
	CMP #ISSUEX
	BEQ @TRUE
	CMP #ISSUEN
	BEQ @TRUE
	LDA #00
	RTS
@TRUE
	LDA #01
	RTS

;debate_ai_reaction_select()	
_DRCTAI
	;RTS
	LDX DPARTY
	LDA V_AI,X
	CMP #$02
	BCS @NOTEASY

	LDY #04
	LDA #DBACCR
	STA (OFFSET2),Y
	RTS
@NOTEASY
	LDY #04
	LDA #DBACCR
	STA (OFFSET2),Y
	RTS

;debate_ai_get_correct_issue()
;returns X = issue index
_DAIGCS
	LDA #$02
	JSR _RNG
	BEQ @ONE
	LDX V_DISS0
	RTS
@ONE
	LDX V_DISS1
	RTS
	

;debate_clear_menu_right() 
;clears more than CLRMENR
_DCLRMR 
	LDA #P_DMRX1
	STA GX_LX1
	LDA #P_DMRX2
	STA GX_LX2
	LDA #P_DMRY1
	STA GX_LY1
	LDA #P_DMRY2
	STA GX_LY2
	JSR _GXRECTC
	RTS 


;debate_draw_action_code(A = action index)
_DRWACOD
	TAX
	LDA D_DACODE,X
	TAX
	STX FX1
	
	LDA #C_WHITE
	STA GX_DCOL
	
	LDA T_DAMENU,X
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CCOL
	LDX FX1
	LDA T_DAMENU+1,X
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CCOL
	RTS
	
;debate_draw_reaction_code(A = reaction index)
_DRWRCOD
	TAX
	LDA D_DRCODE,X
	TAX
	STX FX1
	
	LDA #C_WHITE
	STA GX_DCOL
	
	LDA T_DRMENU,X
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CCOL
	LDX FX1
	LDA T_DRMENU+1,X
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CCOL
	RTS