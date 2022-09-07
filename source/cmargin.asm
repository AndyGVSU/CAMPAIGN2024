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
	STA V_CTRL,X

	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE


	CMP #STATE_C
	BNE @LOOP
	RTS 

;color_map() 
;maps party control for all states to map color
;does NOT set party control -- use _STCTRL or _FINALCP
_MAPCOL 
	JSR _CPOFFR
	LDA #01
	STA FSTATE
@LOOP 
	LDX FSTATE
	LDA V_CTRL,X
	TAY 
	LDA V_PTCOL,Y
	STA V_STCOL,X

	LDA V_COLMSK,X
	BEQ @SKIPMSK ;if mask is nonzero, blank state
	LDY #UND_PRTY
	LDA V_PTCOL,Y
	STA V_STCOL,X
@SKIPMSK 

	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	CMP #STATE_C
	BNE @LOOP
	RTS 

;get_party_control(cp_addr) 
;gets highest,second-highest cp values
;if difference out of total is >=10% (>=3% for 4 players), max index, else UND
;LOCAL: FVAR1-5
_PCTRL 
	LDA #00
	STA S_DRWUND
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
	
	LDA S_PLAYER
	CMP #$04
	BNE @4P
	LDA V_FPOINT
	AND #$0F
	BNE @4P
	
	LDA V_FPOINT+1
	AND #$0F
	CMP #$03
	BCC @UND
	JMP @SKIPCHK
@4P
	LDA V_FPOINT
	AND #$0F
	BEQ @UND
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
	STA S_DRWUND
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
	JSR _FAC2STR ;FAC to string
	LDA FVAR2
	STA FVAR4 ;move potential party
	JSR _STRPERC
	LDA #$01 ;return non-zero
	RTS 

;und_setup() 
_UNDCP 
	JSR _CPOFFR
	LDA #01
	STA FSTATE
@LOOP 
	LDX FSTATE
	LDA #147
	CLC 
	ADC V_EC,X
	ADC V_EC,X
	;255 - (54 - EC);2 = 147 + EC;2
	LDY #UND_OFFS
	STA (CP_ADDR),Y
	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	CMP #STATE_C
	BNE @LOOP
	RTS 

;max2nd() 
;max2() but instead gets the second highest value
;only guaranteed a second value, not a second party
;quits if initial tie
_MAX2ND
	JSR _MAX2
	
	BEQ @TIE
	ASL 
	TAY 
	DEY 
	DEY 
	LDA #$00
	STA V_MAX,Y
	STA V_MAX+1,Y
	JSR _MAX2
@TIE 
	RTS 

;max2() 
;2B maximum where values are (L)(H) pairs in V_MAX
;LOCAL: FRET1-2
;returns to MAXLOW/MAXHIGH; if not tie, A = index
_MAX2 
	LDX #01
	JSR _MAXA
	LDX #01
	JSR _MAXB
	PHA 
	LDA FRET1
	STA MAXHIGH
	PLA 
	BNE @NOTTIE
	LDX #00
	JSR _MAXA
	LDX #00
	JSR _MAXB
	PHA 
	LDA FRET1
	STA MAXLOW
	PLA 
@NOTTIE 
	RTS 

;max_a(x = V_MAX offset)
;FRET1 = maximum value
;put maximum value in FRET1
_MAXA 
	LDY #$01
	LDA #00
	STA FRET1
	STA FRET2
@LOOP 
	LDA V_MAX,X
	CMP FRET1
	BCC @SKIPSTA
	STA FRET1
@SKIPSTA 
	INX 
	INX 
	INY 
	CPY S_PLAY1M
	BNE @LOOP

	RTS 


;max_b(X = V_MAX offset)
;returns A = index + 1 (0 for tie)
_MAXB 

	LDY #01
@RLOOP 
	LDA V_MAX,X
	CMP FRET1
	BNE @SKIP
	LDA FRET2
	BNE @TIE
	STY FRET2
@SKIP 
	INX 
	INX 
	INY 
	CPY S_PLAY1M
	BNE @RLOOP

	LDA FRET2
	RTS 
@TIE 
	LDA #00
	RTS 

;max_reset() 
_MAXR 
	LDX #00
	LDA #00
@LOOP 
	STA V_MAX,X
	INX 
	CPX #$08
	BNE @LOOP
	RTS 

;pop_sum_reset() 
;clears V_POPSUM
_POPSUMR 
	LDX #00
	LDA #00
@LOOPCLR STA V_POPSUM,X
	INX 
	CPX #$0C
	BNE @LOOPCLR
	RTS 

;popular_vote_sum() 
;draw_und set beforehand
;sums ALL state cp by party, returns to v_popsum
_POPSUM 
	LDA #00
	STA HS_ADDR
	LDA #$01
	STA FSTATE
	JSR _CPOFFR
@STLOOP

	JSR _STATSUM
	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	CMP #STATE_C
	BNE @STLOOP
	RTS 

;popsum_combo() 
_POPSUM1 
	JSR _POPSUMR
	JSR _GAINSUM
;JSR _POPSUM ;takes drw_und
	RTS 

;popsum_draw_combo() 
_POPCOM1 
	;LDA #01
	;STA V_SUMFH
	JSR _POPSUM1
	LDA #STATE_C
	STA FARG5
	JSR _DRWPOP
	RTS 

;cp_gain_sum() 
;transfers total action-earned CP by party to V_POPSUM
_GAINSUM 
	LDX #00
@LOOP 
	LDA V_ALLCP,X
	STA V_POPSUM,X
	INX 
	CPX #$0C
	BNE @LOOP
	RTS 

;percent_state(Y = party index * 2)
;divides state CP by total, formats
_PERCSTA 
	LDA V_POPSUM,Y
	STA FARG1
	LDA V_POPSUM+1,Y
	STA FARG2
	LDA V_POPSUM+10
	STA FARG3
	LDA V_POPSUM+11
	STA FARG4
	JSR _PERCENT
	JSR _PERCFMT
	RTS 

;state_control_count(A = party)
;counts the number of states party A is winning
;(only on the map)
;returns to A
;LOCAL: FRET1,FY1
_CTRLCNT 
	TAY 


	STY FY1
	LDX #01
	LDA #00
	STA FRET1
@LOOP 
	LDA V_CTRL,X
	CMP FY1
	BNE @SKIPADD
	INC FRET1
@SKIPADD 
	INX 
	CPX #STATE_C
	BNE @LOOP
	RTS 

;state_cp_sum() 
;sums all candidates' CP at current CP_ADDR/HS_ADDR
;if draw_und is set, adds UND to total as well
;adds result to V_POPSUM; for single-use, clear first
_STATSUM 
	LDY #01
@LOOP 
	JSR _STATSM2
	CLC 
	ADC V_POPSUM+10
	STA V_POPSUM+10
	BCC @NOC
	INC V_POPSUM+11
@NOC 
	DEY 
	TYA 
	ASL 
	TAX 
	INY 
	JSR _STATSM2
	CLC 
	ADC V_POPSUM,X
	STA V_POPSUM,X
	BCC @NOC2
	INC V_POPSUM+1,X
@NOC2 
	INY 
	CPY S_PLAY1M ;loop per player
	BCC @LOOP
	CPY #UND_OF1M
	BEQ @RTS

	LDY #UND_OFFS
	LDA S_DRWUND
	BEQ @RTS ;if draw und off, ignore
	JMP @LOOP ;if on, add UND
@RTS 
	RTS 
;sum from history check
_STATSM2 
	LDA V_SUMFH
	BEQ @FROMCP
	LDA (HS_ADDR),Y
	RTS 
@FROMCP 
	LDA (CP_ADDR),Y
	RTS 