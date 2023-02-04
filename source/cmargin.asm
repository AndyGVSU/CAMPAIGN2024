;cmargin.asm
;CAMP06 
;state margin/control/sum routines

;max_party_list() 
;stores to V_MAXPL all the parties with FRET1 maximum value
;returns X = number of tied parties
_MAXPL 
	LDA #00
	TAX 
@CLRLOOP 
	STA V_MAXPL,X
	INX 
	CPX #$04
	BNE @CLRLOOP

	TAY 
	TAX 
@MAXLOOP 
	LDA MAXHIGH
	CMP V_MAX+1,Y
	BNE @NOTEQ
	LDA MAXLOW
	CMP V_MAX,Y
	BNE @NOTEQ

	TYA 
	LSR 
	STA V_MAXPL,X
	INX 
@NOTEQ 
	INY 
	INY 
	TYA 
	LSR 
	CMP S_PLAYER
	BNE @MAXLOOP

; LDA S_PLAYER
; CMP #$04
; BCS @RTS
; LDA #00
; STA V_MAXPL,X ;terminate with 0 if room
@RTS 
	RTS 

;state_control() 
;executes _PCTRL for all states
_STCTRL
	JSR _CPOFFR
	LDA #01
	STA FSTATE
@LOOP 
	JSR _PCTRL
	LDX FSTATE
	PHA
	TAY
	LDA V_WEEK
	CMP #$01 
	BEQ @EQUAL ;no delta week 1
	TYA
	CMP V_CTRL,X ;set control change
	BEQ @EQUAL
	LDA #01
	BNE @STORE
@EQUAL
	LDA #00
@STORE
	STA V_CTRLD,X
	PLA
	STA V_CTRL,X
	
	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	
	CMP #STATE_C
	BNE @LOOP
	RTS 

;get_party_control_by_margin(cp_addr) 
;gets highest,second-highest cp values
;if [difference out of total] >= [current MoE], max index, else UND.
;LOCAL: FVAR1-5
_PCTRL 
	LDA #00
	STA S_SUMUND ;party control is never decided by UND
	STA FVAR4
	JSR _POPSUMR ;clear V_POPSUM
	LDA #00
	STA V_SUMFH ;turn off sum from history
	JSR _STATSUM
	JSR _MARGIN
	BEQ @UND
	
	LDA S_CLASSC
	BEQ @CLASSC
	JMP @SKIPCHK
@CLASSC
	
	JSR _F32FAC
	JSR _FMUL10
	JSR _FMUL10 ;multiply by 100 (percentage)
	JSR _FAC216
	TYA
	
	CMP V_MOE
	BCC @UND
@SKIPCHK
	DEC FVAR4
	LDA FVAR4
	RTS
@UND
	LDA #UND_PRTY
	RTS 

;margin()
;gets % margin between top two states (by CP)
;if tie, returns #00, else #01
;LOCAL: FVAR1-4
_MARGIN 
	JSR _MARGMAX
	BNE @TIE1 ;if 1st tie, UND
	LDA #00
	RTS 
@TIE1 
	TAY 
	LDA FRET1
	STA FVAR1 ;save value 1
	STY FVAR2 ;save party 1
	JSR _MAX2ND
	BNE @TIE2 ;if 2nd-place tie, use value
	LDA FRET1
	JMP @TIE2R
@TIE2 ;save party 2
	STA FVAR4
	LDA FRET1
@TIE2R ;save value 2
	STA FVAR3
	LDA FVAR1
	CMP FVAR3
	BCS @SKIPSWP ;fvar1 always > fvar3
	+__SWAP FVAR1,FVAR3,FVAR5
	+__SWAP FVAR2,FVAR4,FVAR5
@SKIPSWP 
	LDA FVAR1
	STA FARG1
	LDA #00
	STA FARG2
	LDA V_POPSUM+10
	STA FARG3
	LDA V_POPSUM+11
	STA FARG4

	JSR _MARGFMT
	RTS 

;targeted_margin(FARG1=selected party index)
;calculates margin between selected party and max
;if party is max, then between the next highest party 
;returns FRET1 = party has max
_TMARGIN 
	;move CP, calc max
	JSR _MARGMAX
	;if tie, set vpoint to 0, done (CTRL = 0)
	STA FRET1 ;temp max party
	LDA V_PARTY
	ASL 
	TAY 
	LDA V_MAX,Y ;if current party cp == max
	CMP MAXLOW
	BEQ @IAMMAX

	LDY FRET1

	DEY 
	CPY FARG1
	;if max index == selected party
	BNE @NOTMAX
@IAMMAX ;calculate second-highest state
	LDA FRET1
	BNE @FINDPT
	LDY V_PARTY
@FINDPT 
	LDA MAXLOW
	STA FVAR1 ;value 1
	STY FVAR2 ;party 1 (higher)
	;set max party to 1, selected to 2
	JSR _MAX2ND
	TAY 
	DEY 
	LDA FRET1
	STA FVAR3 ;value 2
	STY FVAR4 ;party 2 (lower)

	LDA #01
	STA FRET1
	JMP @FORMAT
@NOTMAX 
	;else, set selected to 2, max to 1 (CTRL = 0)
	LDA MAXLOW
	STA FVAR1 ;value 1 (higher)
	STY FVAR2 ;party 1
	LDY FARG1 ;load selected party
	TYA 
	ASL 
	TAY 
	LDA V_MAX,Y
	STA FVAR3 ;value 2
	TYA 
	LSR 
	TAY 
	STY FVAR4 ;party 2 (lower)

	LDA #00
	STA FRET1
@FORMAT 
	LDA FVAR1
	STA FARG1 ;higher cp value
	LDA #00
	STA FARG2 ;high byte (always zero)
	LDA V_POPSUM+10
	STA FARG3 ;total CP for state
	LDA V_POPSUM+11
	STA FARG4

	JSR _MARGFMT
	RTS 
;combo call
_TMARGIN2
	LDA #00
	STA S_SUMUND ;never uses UND
	JSR _STATSUM
	LDA V_PARTY
	STA FARG1
	JSR _TMARGIN ;% margin between current, highest
	RTS

;margin_max() 
;calculates max of all CP for state
_MARGMAX 
	JSR _MAXR
	LDX #00
@COPY 
	LDA V_POPSUM,X
	STA V_MAX,X
	INX 
	CPX #$08
	BNE @COPY
	;maintain total!
	JSR _MAX2
	RTS 

;margin_format(FARG1(/2) = higher CP, FARG3(/4) = total CP, FVAR2 = party, FVAR3 = lower CP)
;LOCAL: FVAR1-4,FARG1-4
_MARGFMT 
	JSR _PERCEN2 ;do not convert to string
	JSR _FAC2ARG ;FAC to ARG
	JSR _ARG2F3 ;ARG to FLOAT3
	LDA FVAR3
	STA FARG1
	JSR _PERCEN2
	JSR _F32ARG ;FLOAT3 to ARG
	JSR _FSUBT ;FAC = ARG - FAC
	JSR _FAC2F3 ;copy FAC result to float3
	JSR _FAC2STR ;FAC to string
	LDA FVAR2
	STA FVAR4 ;move potential party
	JSR _STRPERC
	LDA #$01 ;return non-zero
	RTS 


