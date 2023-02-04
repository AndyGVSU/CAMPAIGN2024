;cai.asm
;CAMP05 
;AI routines

;main check routine
;ignores if human player, enters schedule if AI
;returns A = ai schedule was entered
_AI 
	LDX V_PARTY
	LDA V_AI,X
	STA SAVEAI
	BEQ @RTS
	LDA SAVEAI
	CMP #AIPSYCH
	BEQ @PSYCH
	CMP #AINORM
	BCS @HARD
	JSR _EASY
	BNE @RTSAI
@PSYCH
	;JSR _PSYCHAI
	JMP @RTSAI
@HARD
	JSR _HARDAI
@RTSAI
	LDA #01
	RTS 
@RTS 
	RTS 

;easy_ai() 
_EASY 
	JSR _SCHCLR
	;set random region
	LDA #$09
	JSR _RNG
	CLC 
	ADC #$01
	STA C_CREG

	LDA #ACT_REST
	JSR _SCHADD
	LDA #ACT_REST
	JSR _SCHADD
	;rest twice
	LDA #ACT_FUNDR
	JSR _SCHADD
	LDA #ACT_FUNDR
	JSR _SCHADD
	;fundraise twice
@VISIT 
	LDX C_CREG
	DEX 
	LDA D_REGC,X
	JSR _RNG
	LDX C_CREG
	CLC 
	ADC D_REGLIM-1,X
	STA FARG1
	LDA #ACT_REST
	JSR _SCHADD

	LDA C_SCHEDC


	CMP #$06
	BNE @VISIT
	;campaign in two random states
	LDA #ACT_TVADS
	JSR _SCHADD
	;tv ads in region
	LDA #01
	RTS 

;generic_hard_ai()
_HARDAI
	JSR _AICLRP
	
	LDA SAVEAI
	CMP #AINORM
	BNE @NEXT
	JSR _AIHLIST
	JMP @LISTED
@NEXT
	JSR _AIHLIST2
	JSR _AISURVEY ;apply survey
	JSR _AIPOLL2 ;apply polls (works in tandem with SURVEY: finds UND states with 0 UND, then POLLS that region to find the margin and removes them from the SURVEY list if they're still worth going to)
	JSR _AIHLIST2 ;recalculate with polls
@LISTED	
	LDA SAVEAI
	CMP #AIPSYCH
	BEQ @SKIPCLR
	JSR _SCHCLR
@SKIPCLR
	;var init
	LDA #00
	STA FAI
	STA FAITV ;tv ads limit
	STA FARG5 ;max TV priority
	STA FAIPTR
	LDA #$03
	STA FAIPRI
		
	JSR _SCHFULL ;SAFETY CHECK
	BNE @FULLCHK
	JMP @DONE
@FULLCHK

	;AUX REST/FUNDR ON EVEN WEEKS
	LDA SAVEAI
	CMP #AIPSYCH
	BEQ @SKIPAUX
	JSR _AIHAUX
@SKIPAUX
	LDA SAVEAI
	CMP #AINORM
	BNE @WEEK9
	JSR _NORMW9
@WEEK9
	
	;MAIN LOOP
@LOOP1

	LDA V_CPGPTR
	STA FAIPTR
	
	;OUT OF PRIORITIZED STATES
	LDA FAIPRI
	CMP #$FF
	BNE @NOTOUT
	JSR _AISAFE
	LDA FRET1
	JMP @VISIT
@NOTOUT
	
	;WARNING PREVENTION	
	JSR _NOTLAST
	BNE @SKIPPREV
	JSR _LDAPCFC 
	CMP #20
	BCC @FUNDR 
	JSR _LDAPCHC
	CMP #20
	BCC @REST
@SKIPPREV
	;OUT OF USABLE PRIORITY STATES
	LDX FAI
	LDA V_PRIOR,X
	CMP FAIPRI
	BEQ @CONTINU
	JMP @INC
@CONTINU
	
	LDA V_PRIOR2,X
	BEQ @INC
	BMI @TVADS
@VISIT
	STA FARG1
	LDA V_VBONUS
	AND #$7F
	CMP FARG1
	BNE @NOPENAL
	LDA V_VBONUS
	BPL @NOPENAL ;if VISIT penalty
	JMP @INC
@NOPENAL
	LDA FARG1
	JSR _AISETREG
	
	JSR _HARDW9 ;week 9 end with TV ADS if enough money/health
	BNE @TVLIMIT
	
	LDA #ACT_VISIT
	JSR _SCHADD
	
	LDA C_SCHEDC
	CMP #$01
	BNE @TWICE ;visit highest-priority state twice on odd weeks (not week 1, and if TV ADS is not first)
	LDA V_WEEK
	CMP #$01
	BEQ @TWICE
	LDA FARG1
	JMP @VISIT
@TWICE
	JMP @INC
@TVADS 
	AND #$0F
	STA C_CREG

	INC FAITV
	LDA FAITV
	CMP #03 ;no more than 2 TV ADS
	BCC @TVLIMIT
	JMP @INC
@TVLIMIT 
	LDA #ACT_TVADS
	JSR _SCHADD
	LDA V_WARN
	BEQ @TVOK
	DEC C_SCHEDC
@TVOK
	JMP @INC

@FUNDR
	LDA #ACT_FUNDR
	JSR _SCHADD
	JMP @FULL
@REST 
	LDA #ACT_REST
	JSR _SCHADD
	JMP @FULL
@INC 
	INC FAI
	LDA FAI
	CMP #AISTATE
	BNE @DECPRI
	DEC FAIPRI
	LDA #$00
	STA FAI
@DECPRI
@FULL
	JSR _SCHFULL
	BEQ @DONE
	JMP @LOOP1
@DONE 
	RTS 
	
;normal_ai_week9
_NORMW9
	LDA V_WEEK
	CMP #$09
	BNE @GARANTV
	LDX #$07
@WEEK9LP 
	LDA V_PRIOR2,X
	BPL @NOTTV
	STA V_PRIOR2+6 ;last action; if surplus, kept
	;JMP @LOOP1
	RTS
@NOTTV 
	INX 
	CPX #$1D
	BNE @WEEK9LP
@GARANTV 	
	RTS 

;ai_hard_week_9()
_HARDW9
	LDA V_WEEK
	CMP #$09
	BNE @FALSE
	LDA C_SCHEDC
	CMP #$06
	BNE @FALSE
	JSR _LDAPCF
	CMP #15
	BCC @FALSE
	JSR _LDAPCH
	CMP #30
	BCC @FALSE
	
	LDA FARG1
	JSR _STATEGR
	STX C_CREG
	LDA #$01
	BNE @RTS
@FALSE
	LDA #$00
@RTS
	RTS

;ai_safe()
;picks a random state that is not under its control
;returns to FRET1
_AISAFE
	TXA
	PHA
	LDX #00
	STX FVAR6
	LDA #$01
	STA FSTATE
@LOOP
	LDX FSTATE
	LDA V_CTRL,X
	CMP V_PARTY
	BEQ @SKIP
	LDY FVAR6
	TXA
	STA SCRATCH,Y
	INC FVAR6
@SKIP
	INC FSTATE
	LDA FSTATE
	CMP #STATE_C
	BNE @LOOP
	
	LDA FVAR6
	CMP #$02
	BCC @RANDOM
	JSR _RNG
	TAX
	LDA SCRATCH,X
	JMP @RTS
@RANDOM
	LDA #STATE_C
	JSR _RNG
@RTS
	STA FRET1
	PLA
	TAX
	RTS
	
	


;action_not_last()
;returns 1 if week = 9 AND schedule count = 6
_NOTLAST
	LDA V_WEEK
	CMP #$09
	BNE @FALSE
	LDA C_SCHEDC
	CMP #$06
	BNE @FALSE
	LDA #$01
	RTS
@FALSE
	LDA #00
	RTS

;clear_priority_values()
_AICLRP 
	LDA #00
	TAX 
@CLRLOOP ;for second pass ONLY
	STA V_PRIOR,X
	STA V_PRIOR2,X
	INX 
	CPX #AISTATE
	BNE @CLRLOOP
	JSR _AICLRPL

	RTS 

;auxiliary_rest() 
;does REST/FUNDRAISE conditionally
_AIHAUX 
	LDA V_WEEK
	AND #$01
	BEQ @ODD
	RTS
@ODD
	
	JSR _LDAPCF
	CMP #128 ;1 if FUNDS < 128
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD

	JSR _LDAPCF
	CMP #100
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD

	JSR _LDAPCF
	CMP #80
	BCS @SECOND

	LDA #ACT_FUNDR
	JSR _SCHADD
@SECOND 
	JSR _LDAPCH
	CMP #128
	BCS @RTS
	
	LDA #ACT_REST
	JSR _SCHADD

	JSR _LDAPCH
	CMP #128
	BCS @RTS
	
	LDA #ACT_REST
	JSR _SCHADD
@RTS 
	RTS 

;schedule_full_check 
_SCHFULL 
	LDA C_SCHEDC
	CMP #$07
	RTS 
	
;calc_priority_list() 
_AIHLIST ;set up index list
	LDA #00
	TAX 
	STA V_PRIOR2+AISTATE

	TAY 
	LDX #01
	STA V_POLLCT
@SLOOP 
	LDA V_EC,X
	CMP #$0A
	BCC @SKIPSTA
	TXA 
	STA V_PRIOR2,Y
	TAX 
	INY 
@SKIPSTA 
	INX 
	CPX #STATE_C
	BNE @SLOOP

	LDX #01
@TVLOOP 
	TXA 
	ORA #$F0
	STA V_PRIOR2,Y
	INX 
	INY 
	CPX #$0A
	BNE @TVLOOP

@CALC2 
	LDA #00
	STA FAI
@CALCLP 
	;single/group state index
	LDX FAI
	LDA V_PRIOR2,X
	BEQ @CLCINC ;ignore if state index 0
	BMI @GROUP
	JSR _AIHONE
	JMP @CLCINC
@GROUP 
	AND #$0F
	JSR _AIHMANY
@CLCINC 
	LDX FAI
	STA V_PRIOR,X

	INC FAI
	LDA FAI
	CMP #$1F
	BNE @CALCLP

	JSR _AISORT
	
	JMP @POLLED
	;skip polling WEEK < 3
	LDA V_WEEK
	CMP #$03
	BCC @POLLED
	;if no money, no polls
	LDA V_OUTOFM
	BNE @POLLED
	;if poll count > 0, no further polls
	LDA V_POLLCT
	BNE @POLLED
	LDY #00
@POLLOOP 
	LDA V_WEEK
	CMP #$09
	BNE @BLITZ
	INC V_POLLCT
	LDX #01
	JMP @DONEPOLL
@BLITZ 
	LDA V_PRIOR2,Y
	BMI @TVADREG
	JSR _STATEGR
	BNE @GOTREG
@TVADREG 
	AND #$0F
	TAX 
@GOTREG 
	LDA V_AIPOLL,X
	BNE @OLDREG
	INC V_AIPOLL,X
	JSR _AIPLCOST
@OLDREG 
	INY 
	LDA V_POLLCT
	CMP #$02
	BNE @POLLOOP

@DONEPOLL 
	JSR _AICLRP
	JMP @CALC2
@POLLED 
	
	;all states on by default
	LDX #$00
	LDA #$01
@FILLOOP
	STA V_PRIOR,X
	INX
	CPX #AISTATE
	BNE @FILLOOP
	RTS 

;calc_priority_list() 
_AIHLIST2 ;set up index list
	LDA #01
	STA FARG1
	JSR _CPOFFS
	LDA #00
	TAY
	STA V_PRIOR2+AISTATE
	LDX #01
	;build VISIT state list
@SLOOP
	LDA V_EC,X
	CMP #$0A
	BCC @SKIPSTA
	
	LDA V_PARTY
	CMP #$02
	BNE @INDFILT
	LDA S_PLAYER
	CMP #$03
	BNE @INDFILT
	CPX V_INDSTA
	BEQ @SKIPSTA
	CPX V_INDSTA+1
	BEQ @SKIPSTA
@INDFILT
	TXA 
	STA V_PRIOR2,Y
	TAX
	
	TYA
	PHA
	LDA V_PARTY
	CLC
	ADC #UND_OF1M
	TAY
	LDA (CP_ADDR),Y
	STA FVAR1
	PLA
	TAY
	LDA FVAR1
	STA V_PRIOR,Y
	
	INY 
@SKIPSTA 
	JSR _CPOFFI
	INX 
	CPX #STATE_C
	BNE @SLOOP

	STY FY1
	;build TV ADS list
	+__LAB2O V_AIH2REG
	LDX V_PARTY
	LDY #$09
	JSR _OFFSET
	
	LDY #01
@REGLOOP
	TYA
	;CMP #$03 ;NO TV ADS IN GR8LAKES/ATLANTIC!
	;BEQ @NOTVADS
	;CMP #$05
	;BEQ @NOTVADS
	ORA #$F0
	LDX FY1
	STA V_PRIOR2,X
	DEY
	LDA (OFFSET),Y
	INY
	STA V_PRIOR,X
	INC FY1
@NOTVADS
	INY
	CPY #$0A
	BNE @REGLOOP
	
	JSR _AISORT ;sort by STATE LEAN, then by EC
	JSR _AICSORT

	;determine whether to do action or not
	LDX #00
@TOVISIT
	STX FAI
	LDA V_PRIOR2,X
	BEQ @NEXTST
	BMI @TVADS
	STA FSTATE
	JSR _AIHLIST2V
@VISDONE
	LDX FAI
	STA V_PRIOR,X
	JMP @NEXTST
@TVADS
	JSR _AIHLIST2T
	JMP @VISDONE
@NEXTST
	LDX FAI
	INX
	CPX #AISTATE
	BNE @TOVISIT
	
	RTS
	
;calculate TV ADS to-visit (A = region code #$Fx)
_AIHLIST2T
	AND #$0F
	TAX
	STX FVAR1 ;region
	LDA D_REGLIM-1,X
	STA FVAR5 ;lower limit
	LDA D_REGLIM,X
	STA FVAR6 ;upper limit
	
	LDA #$00
	STA FVAR2 ;count
	
@STLOOP
	LDA FVAR5
	STA FSTATE
	JSR _AIHLIST2V
	BEQ @FALSE
	CLC 
	ADC FVAR2
	STA FVAR2
@FALSE
	INC FVAR5
	LDA FVAR5
	CMP FVAR6
	BNE @STLOOP
	
	LDX FVAR1
	LDA D_REGC-1,X
	LSR
	CLC
	ADC #$01
	CMP FVAR2 ;sum of states' priorities is greater than [half the state count + 1]
	BCS @RETFAL
	LDX FVAR1
	LDA D_REGC-1,X
	CMP FVAR2
	BCC @NORMAL ;sum of states' priorities is greater than or equal to [state count]
	LDA #$03 ;priority 3
	RTS
@NORMAL
	LDA #$01 ;priority 1
	RTS
@RETFAL
	LDA #$00 ;priority 0
	RTS

;ai_hard_2_poll()
;works in tandem with _AISURVEY to complete a short blacklist of states in V_AISURV
_AIPOLL2
	LDA V_WEEK
	CMP #$07
	BCS @EARLY
	RTS
@EARLY
	LDA C_MONEY
	CMP #10
	BCS @OUTOFM
	RTS
@OUTOFM
	+__LAB2O V_AISURV
	LDX V_PARTY
	LDY #$03
	JSR _OFFSET
	LDY #$02
@LOOP
	LDA (OFFSET),Y
	BMI @SKIP ;miss
	BEQ @SKIP ;empty
	;state found
	JSR _STATEGR
	JMP @FOUND
@SKIP
	DEY
	CPY #$FF
	BNE @LOOP
	RTS
@FOUND
	STX V_AIPOLL
	JSR _AIPLCOST
	RTS

;calculate single-state to-visit
;LOCAL: FAI = priority index, FSTATE = priority state index
_AIHLIST2V
	LDA SAVEAI
	CMP #AIPSYCH
	BNE @PSYCH
	LDX FSTATE
	JSR _VISLOG
	BCC @PSYCH
	JMP @FALSE
@PSYCH
	
	LDA FSTATE
	JSR _STATEGR
	CPX V_AIPOLL
	BEQ @POLL
@NOPOLL
	LDX FSTATE
	STX FARG1
	JSR _CPOFFS
	
	+__LAB2O V_AISURV 
	LDX V_PARTY
	LDY #$03
	JSR _OFFSET
	LDY #00
@BLACKLIST
	LDA (OFFSET),Y
	CMP FSTATE
	BEQ @FALSE ;no survey/poll-blacklisted states
	INY
	CPY #$03
	BNE @BLACKLIST
	
	JSR _MULTSWING ;is this state a "Swing" state for me?
	TXA
	EOR #$01
	STA FX1 ;hold NOT(return)
	
	LDA V_PARTY
	CLC
	ADC #UND_OFFS+1
	TAY
	LDA (CP_ADDR),Y
	CMP #$05
	BCC @NODELTA ;delta only works for LEAN >= 5 (this is arbitrary in RANDOM mode)
	
	LDX FSTATE
	LDA V_CTRLD,X
	BEQ @NODELTA
	LDA V_CTRL,X
	CMP V_PARTY
	BEQ @NODELTA ;if control changed to AI, normal priority check
	CMP #UND_PRTY 
	BNE @OPPONENT
	LDA #$02 ;priority 2
	SEC
	SBC FX1 ;priority 1 IF NOT swing state
	RTS
@OPPONENT
	LDA #$03 ;priority 3
	RTS
@NODELTA
	JSR _MULTNP ;if AI controls, priority 0
	CPX #$02
	BEQ @FALSE
@TRUE
	LDA #$01 ;if opponent or UND controls, priority 1
	CPX #$00
	BEQ @SKIPSWNG
	SEC
	SBC FX1 ;priority 0 IF NOT swing state
@SKIPSWNG
	JMP @VISDONE
@FALSE
	LDA #$00 ;priority 0
@VISDONE
	RTS
@POLL
	LDA FSTATE
	STA FARG1
	JSR _CPOFFS
	JSR _POPSUMR
	JSR _TMARGIN2 ;% margin between current, highest
	
	+__LAB2O V_AISURV 
	LDX V_PARTY
	LDY #$03
	JSR _OFFSET
	LDY #$00
@CHKSURV
	LDA (OFFSET),Y
	CMP FSTATE
	BEQ @POLLED
	INY
	CPY #$03
	BNE @CHKSURV
	JMP @NOPOLL
@POLLED
	LDA #$00
	STA FY1 ;reset zero-priority flag
	JSR _MULTNUN
	LDA FY1
	BNE @FALSE
	CPX #$01 ;if margin >5%, do not do action and keep state in blacklist
	BNE @FALSE
	;else, remove from blacklist
	LDY #$00
@RMLOOP
	LDA (OFFSET),Y
	CMP FSTATE
	BEQ @REMOVE
	INY
	CPY #$03
	BNE @RMLOOP
@REMOVE
	LDA #$FF
	STA (OFFSET),Y
	JMP @TRUE
;@FORGET
	;LDY FAI
	;LDA #$01
	;STA (OFFSET2),Y
	;JMP @FALSE
@CONTIN
	JSR _MULTNP
	CPX #$02
	BEQ @FALSE
	JMP @TRUE
	
;ai_survey()
_AISURVEY
	LDA V_WEEK
	CMP #$05
	BCC @QUIT
	
	LDX V_PARTY
	LDA V_SURVEY,X
	CMP #$03
	BNE @REMAING
@QUIT
	RTS
@REMAING
	;check prioritized states that are UNSURE
	LDA #$01
	STA FAI
@UNDLOOP
	LDX FAI
	LDA V_PRIOR2,X
	BMI @SKIPTV
	TAX
	LDA V_CTRL,X
	CMP #UND_PRTY
	BEQ @VALID
	
@SKIPTV
	INC FAI
	LDA FAI
	CMP #AISTATE
	BNE @UNDLOOP
	;check list of surveyed states; do not repeat a state
	RTS
@VALID
	STX FSTATE
	+__LAB2O V_AISURV
	LDY #$03
	LDX V_PARTY
	JSR _OFFSET
	+__O2O2
	LDY #$00
@NOREPEATS
	LDA (OFFSET),Y
	BEQ @OK
	CMP #$FF
	BEQ @SKIP
	CMP FSTATE
	BNE @OK
	BEQ @REPEAT
	JMP @OK
@SKIP
	INY
	CPY #$03
	BNE @NOREPEATS
@REPEAT
	JMP @SKIPTV
@OK
	LDA V_FHCOST+1
	SEC
	SBC #SURVEY_COST
	STA V_FHCOST+1
	
	;check UND CP, if < 3 add to list, otherwise add #$FF
	LDA FSTATE
	STA FARG1
	JSR _CPOFFS
	+__O2O
	LDY #UND_OFFS
	LDX V_PARTY
	LDA V_SURVEY,X
	PHA
	LDA (CP_ADDR),Y
	CMP #04
	BCC @REMOVE
	PLA
	TAY
	LDA #$FF
	STA (OFFSET),Y
	JMP @DONE
@REMOVE
	PLA
	TAY
	LDA FSTATE
	STA (OFFSET),Y
	PHA
	TYA
	CLC
	ADC #12
	TAY
	PLA
	STA (OFFSET),Y
@DONE
	LDX V_PARTY
	INC V_SURVEY,X
	RTS

;ai_poll_cost()
_AIPLCOST
	LDA V_FHCOST+1
	SEC 
	SBC #06
	SBC V_POLLCT
	STA V_FHCOST+1
	RTS 

;calc_priority_single(A = state index)
;calculate priority value for single state
;returns A = priority
;LOCAL: FVAR1
_AIHONE 
	STA FSTATE ;state index
	STA FARG1
	JSR _CPOFFS
	JSR _POPSUMR

	LDA #00
	STA FAIMUL ;start with 1x multiplier
	STA FY1 ;zero priority flag
	;IND ignores 2 megastates
	LDA V_PARTY
	CMP #$02
	BNE @INDFILT
	LDA S_PLAYER
	CMP #$03
	BNE @INDFILT
	LDA FSTATE
	CMP V_INDSTA
	BEQ @IGNORE
	CMP V_INDSTA+1
	BEQ @IGNORE
	BNE @INDFILT
@IGNORE 
	LDA #01
	STA FY1
	JMP @ZEROPRI
@INDFILT 
	LDA FSTATE
	JSR _STATEGR
	;LDA V_AIPOLL,X
	;BNE @POLL
;JSR _MULTAS
	JSR _MULTNP

@CALC ;state lean / 2
	LDA V_PARTY
	CLC 
	ADC #UND_OF1M
	TAY 
	LDA (CP_ADDR),Y
	LSR 
	STA FVAR1
	;if week < 4, no SL < 4
	LDA V_WEEK
	CMP #$04
	BCS @LEAN3
	LDA (CP_ADDR),Y
	CMP #$04
	BCS @LEAN3
	JMP @ZEROPRI
@LEAN3 
	;state EC / 4
	LDX FSTATE
	LDA V_EC,X
	LSR 
	LSR 
	LDX FVAR1
	BNE @ZEROLEAN
	LSR ;state EC / 8 if STATE LEAN = 1
@ZEROLEAN 
	CLC 
	ADC FVAR1
	BNE @MIN
	LDA #01 ;at least 1
@MIN 
	STA FVAR1

@MULTIPLY ;execute multipliers
	LDA FY1
	BEQ @SKIP0
@ZEROPRI 
	LDA #00 ;zero-priority exit
	RTS 
@SKIP0 
	LDX FAIMUL
	BEQ @SKIPMUL ;skip if no multiplier
	BMI @LESS
	LDA FVAR1
@2XLOOP 
	CLC 
	ROL 
	BCC @NOWRAP
	LDA #$FF ;cap priority at #$FF 
@NOWRAP 
	DEX 
	BNE @2XLOOP
	BEQ @DONEMUL
@LESS 
	LDA FVAR1
@12XLOOP 
	LSR 
	INX 
	BNE @12XLOOP
	CMP #00
	BNE @DONEMUL
	LDA #01
@DONEMUL 
	STA FVAR1
@SKIPMUL 
	LDA FVAR1
	RTS 
;sub-branches 
;@POLL 
;	JSR _MULTPOL
;	JMP @CALC
;@NOUND 
;	JSR _MULTNUN
;	JMP @CALC

;calc_priority_group(A = REGION)
;..for group of states
;averages all single state priorities in group
;LOCAL: FX1,FVAR5-6
_AIHMANY 
	STA FVAR5
	JSR _GROUPLS ;get all states in region

	LDA #00
	STA FAISUM ;priority sum
	STA FAISUM+1

	LDX #00
	STX FX1
	STX FVAR6
@LOOP 
	LDX FX1
	LDA V_AISTAT,X
	BEQ @BREAK
	JSR _AIHONE
	BNE @ZEROINC
	INC FVAR6
@ZEROINC 
	CLC 
	ADC FAISUM
	STA FAISUM
	BCC @CARRY
	INC FAISUM+1
@CARRY 
	INC FX1
	JMP @LOOP
@BREAK 
	LDX FVAR5
	LDA D_REGC-1,X
	LSR 
	CMP FVAR6
	BCS @ZEROPRI
	LDA #00
	RTS 
@ZEROPRI 
	LDA FAISUM+1
	LDY FAISUM
	JSR _162FAC ;16bit to float FAC
	JSR _FAC2ARG ;FAC to ARG
	LDA #00
	LDY #00

	LDY FX1 ;state count
@COUNT 

	JSR _162FAC ;16bit to float FAC
	JSR _DIVIDE ;FAC = ARG / FAC
	LDA #00 ;no negatives!
	STA $A2
	STA $AA
	JSR _FAC232 ;float FAC to 32bit

	LDA FAC+3
	BEQ @CAP
	LDA #$FF
	RTS 
@CAP 
	LDA FAC+4
	RTS 

;swap_sort() 
;LOCAL: FVAR1-3,FARG3
;sorts the priority list and its INDEX list 

;hard 2 AI call
;_AISORT2 
;	LDA #STATE_C
;	STA FVAR3 ;length
;	JMP _AISORT3
;hard 1 AI call
_AISORT 
	LDA #AISTATE
	STA FVAR3 ;length
;_AISORT3 
	LDA #00
	STA FVAR2 ;done

@LOOP2 
	DEC FVAR3
	LDA #00
	STA FVAR1 ;index
@LOOP1 
	LDX FVAR1
	LDA V_PRIOR,X
	CMP V_PRIOR+1,X
	BCS @SKIPSWAP
	+__SWAPX V_PRIOR,V_PRIOR+1,FARG3
	+__SWAPX V_PRIOR2,V_PRIOR2+1,FARG3
;	+__SWAP .vprior1,.vprior1+1,FARG3
;	+__SWAP .vprior2,.vprior2+1,FARG3
	LDA #01
	STA FVAR2
@SKIPSWAP 
	INC FVAR1
	LDA FVAR1
	CMP FVAR3
	BCC @LOOP1

	LDA FVAR2
	BEQ @DONE
	LDA FVAR3
	BEQ @DONE
	BNE @LOOP2
@DONE 
	RTS 
	
;hard 2 AI call (conditional sort)
_AICSORT
	LDA #00
	STA FVAR1 ;priority index
@LOOP3
	LDA #00
	STA FVAR2 ;done sorting

	LDX FVAR1
	LDA V_PRIOR,X
	BEQ @RTS ;if 00, end
	STA FVAR3
@NEXTSL
	LDA V_PRIOR,X
	INX
	CMP FVAR3
	BEQ @NEXTSL
	DEX
	STX FVAR3 ;next state lean starting index
	STX FVAR4 ;copy
	LDX FVAR1
	STX FVAR5 ;priority starting index
	
	INX
	CPX FVAR4
	BEQ @DONE ;only one entry
	
@LOOP2 
	DEC FVAR4
	LDX FVAR5
	STX FVAR1
@LOOP1 
	LDX FVAR1
	LDA V_PRIOR2+1,X
	TAX
	JSR _AIH2EC
	STA FVAR6 ;EC count
	
	LDX FVAR1
	LDA V_PRIOR2,X
	TAX
	JSR _AIH2EC
	CMP FVAR6
	BCS @SKIPSWAP
	LDX FVAR1
	;+__SWAPX V_PRIOR,V_PRIOR+1,FARG3
	+__SWAPX V_PRIOR2,V_PRIOR2+1,FARG3
	LDA #01
	STA FVAR2
@SKIPSWAP
	INC FVAR1
	LDA FVAR1
	CMP FVAR4
	BCC @LOOP1

	LDA FVAR2
	BEQ @DONE
	LDX FVAR4
	CPX FVAR5
	BEQ @DONE
	;BCC @DONE
	BNE @LOOP2
@DONE
	LDX FVAR3
	STX FVAR1
	JMP @LOOP3
@RTS
	RTS

;get_vislog_limit(X = state index)
;returns compare to either 6 VISITS or 12 VISITS
_VISLOG
	LDA S_PLAYER
	CMP #$04
	BEQ @4PLAYER
	
	LDA V_VISLOG,X
	CMP #06 ;a state may be visited no more than 6 times in total
	RTS
@4PLAYER
	LDA V_VISLOG,X
	CMP #12
	RTS

;get_nopoll_multiplier()
;returns X = [opponent controls = 0, UND CTRL = 1, ai controls = 2] 
_MULTNP
	JSR _GETCTRL ;get control value (as on map)
	BEQ @MINE
	LDX FSTATE
	LDA V_CTRL,X
	CMP #UND_PRTY
	BNE @NOTMINE
	LDX #01
	BNE @DONE
@NOTMINE 
	LDX #00
	BEQ @DONE
@MINE 
	LDX #02
@DONE 
	LDA D_AI_NP,X
	CLC 
	ADC FAIMUL
	STA FAIMUL
	RTS 

;get_nound_multiplier() 
_MULTNUN 
	LDA V_FPOINT
	AND #$0F
	STA FVAR1
	BNE @ZEROMUL ;>10%

	LDA V_FPOINT+1
	AND #$0F
	CMP #$06
	BCS @CLOSE
	LDX #01 ;<5% for any party
	BNE @DONE
@CLOSE 
	LDX #00 ;<10%..
@DONE 
	LDA D_AI_NUN,X
	CLC 
	ADC FAIMUL
	STA FAIMUL
	RTS 
@ZEROMUL 
	LDA #01 ;zero-priority flag ON
	STA FY1
	RTS

;multiplier_swing_state(FSTATE = state index, CP_ADDR set)
;times 2 for a "swing" state, which is if the state's [max STATE LEAN - current party's STATE LEAN] is <= 2 (e.g. 6/4 or 8/2/2/8 would be swing states for D/S) 
_MULTSWING
	JSR _MAXR
	
	LDX #00
	LDY #UND_OF1M
@LOOP
	LDA (CP_ADDR),Y
	STA V_MAX,X
	INY
	INX
	INX
	TXA
	LSR
	CMP S_PLAYER
	BNE @LOOP
	
	JSR _MAX2
	LDA #$00
	TAX
	TAY
@LOOP2
	CPY V_PARTY
	BEQ @INC ;skip check of own party's STATE LEAN
	LDA MAXLOW
	SEC
	SBC V_MAX,X
	CMP #$03
	BCC @SWING
@INC
	INX
	INX
	INY
	CPY S_PLAYER
	BNE @LOOP2
	LDX #00
	JMP @RESULT
@SWING
	LDX #01
@RESULT
	TXA
	CLC
	ADC FAIMUL
	STA FAIMUL
	RTS

;group_state_list(A=region) 
;gets all states in region with EC < 10
;LOCAL: FVAR1-2
_GROUPLS 
	TAX 
	LDA D_REGLIM-1,X
	STA FVAR1
	LDA D_REGLIM,X
	STA FVAR2

	LDY #00
@LOOP 
	LDA FVAR1
	STA V_AISTAT,Y
	INY 
	INC FVAR1
	LDA FVAR1
	CMP FVAR2
	BNE @LOOP

	LDA #00
	STA V_AISTAT,Y ;list terminate
	RTS 

;get_control_state() 
;returns CMP (v_party == state control)
_GETCTRL 
	LDX FSTATE
	LDA V_CTRL,X
	CMP V_PARTY
	RTS
	
;average_values(FARG1 = count)
;averages up to 16 8-bit values in V_AISTAT
;cannot average totals past #$FF
_AVGVAL
	
	LDA #00
	TAX
@LOOP
	CLC
	ADC V_AISTAT,X
	INX
	CPX FARG1
	BNE @LOOP
	
	TAY
	LDA #00
	JSR _162FAC ;16bit to float FAC
	JSR _FAC2ARG ;FAC to ARG
	LDA #00
	LDY #00

	LDY FARG1 ;count

	JSR _162FAC ;16bit to float FAC
	JSR _DIVIDE ;FAC = ARG / FAC
	LDA #00 ;no negatives!
	STA $A2
	STA $AA
	JSR _FAC232 ;float FAC to 32bit

	LDA FAC+3
	BEQ @CAP
	LDA #$FF
	RTS 
@CAP 
	LDA FAC+4
	RTS
		
;ai_hard_2_get_EC()
;gets EC value for specific state, or #$FF for region
_AIH2EC
	BMI @TVADS
	LDA V_EC,X
	RTS
@TVADS
	LDA #$FF
	RTS
	
;ai_clear_polls()
;clears all polled regions, resets weekly survey flags
_AICLRPL
	LDA #$00
	STA V_AIPOLL
	LDX #$00
@CLR2
	STA V_SURVWK,X
	INX
	CPX S_PLAYER
	BNE @CLR2
	RTS
	
;ai_set_region(A = region)
_AISETREG
	JSR _STATEGR
	STX C_CREG
	RTS