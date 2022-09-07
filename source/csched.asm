;csched.asm
;CAMP01 
;schedule routines

;clear_schedule() 
;draws an empty schedule, clears space
_CLRSCHD 
	LDA #$1D
	STA GX_LX1
	LDA #P_RIGHT
	STA GX_LX2
	LDA #$10
	STA GX_LY1
	LDA #P_BOTTOM
	STA GX_LY2
	LDA #C_WHITE
	STA GX_DCOL
	JSR _GX_RECT

	LDA #$1E
	STA GX_LX1
	LDA #P_RIGHT
	STA GX_LX2
	LDA #$11
	STA GX_LY1
	LDA #P_BOTTOM
	STA GX_LY2
	JSR _GXRECTC ;;left border
	RTS 

;add_to_schedule(A=action,FARG1=visited state)
;maps the provided action to its schedule code
;AND precalcs the action's CP/HEALTH/FUNDS
;LOCAL: FVAR1
_SCHADD 
	LDX C_SCHEDC
	STA FVAR1
	TAY 

	LDA #00
	STA V_WARN ;clear schedule warning
	STA V_TVWARN ;clear TV ADS halving warning

	TYA 
	BNE @TVADS ;visit

	LDA FARG1
	BNE @DONE
@TVADS 
	DEY 
	BNE @FUNDR
	LDA C_CREG
	STA FARG1
	ORA #$F0
	BNE @DONE
@FUNDR 
	DEY 
	BNE @REST
	LDA #$FF
	BNE @DONE

@REST 
	LDA #00
@DONE 
	LDX C_SCHEDC
	STA C_SCHED,X
	INC C_SCHEDC

	LDA FVAR1
	JSR _SCHPC
	JSR _SCHWARN

;PROCEED DIRECTLY TO _SCHDRW

;draw_to_schedule(A=action,FARG1=visited state)
;draws the provided action to schedule
_SCHDRW 
	LDA C_SCHEDC
	CLC 
	ADC #P_SCH2R
	STA GX_CROW
	LDA #P_SCH2C
	STA GX_CCOL
	;set blank count
	LDA V_WARN
	BEQ @WARN
	LDA V_TVWARN
	BEQ @WARN
	LDA #$09
	BNE @NOWARN
@WARN 
	LDA #$08
@NOWARN 
	STA T_BLANKX+4

	+__LAB2XY T_BLANKX
	JSR _GX_STR
	LDA #P_SCH2C
	STA GX_CCOL
	LDX FVAR1
	JSR _SCHDRW2
	RTS
;text draw (x = selected action)
_SCHDRW2
	BNE @TVADS ;VISIT

	LDX FARG1
	LDA V_STCOL,X
	STA GX_DCOL

	LDA FARG1
	JSR _DRWPOST
	INC GX_CCOL
	INC GX_CCOL
	LDX FARG1
	JSR _DRWSTEC

	RTS 
@TVADS 
	DEX 
	BNE @FUNDR

	+__LAB2XY T_TVADS
	JSR _GX_STR
	INC GX_CCOL
	LDA C_CREG
	ORA #$30
	STA GX_CIND
	JSR _GX_CHAR

	RTS 
@FUNDR 
	DEX 
	BNE @REST
	+__LAB2XY T_FUNDR
	JSR _GX_STR
	RTS 
@REST 
	+__LAB2XY T_REST
	JSR _GX_STR
	RTS 

;schedule_warning() 
;draws a warning if one was issued during precalc
_SCHWARN 
	LDA V_OUTOFM
	BNE @RTS

	LDX V_PARTY ;skip if AI
	LDA V_AI,X
	BNE @RTS

	LDA C_SCHEDC
	CLC 
	ADC #P_SCH2R
	STA GX_CROW
	LDA #P_WARNC
	STA GX_CCOL
	LDA #C_PINK
	STA GX_DCOL

	LDA V_WARN
	BEQ @TVWARN
	LDA #$21
	STA GX_CIND
	BNE @DRAW
@TVWARN 
	LDA V_TVWARN
	BEQ @RTS
	LDA #$25
	STA GX_CIND
@DRAW 
	JSR _GX_CHAR
@RTS 
	RTS 

;schedule_precalc(A=action) 
;calculates CP gains, HEALTH/FUND costs for action
;RETURNS: FRET1 = CP gain, FRET2 = health loss, FRET3 = fund loss
_SCHPC 
	TAX 
	LDA #00
	STA FRET1
	STA FRET2
	STA FRET3 ;reset gains/losses
	TXA 
	BNE @TVADS ;visit
	JSR _CALCVIS
	RTS 
@TVADS 
	DEX 
	BNE @FUNDR
	JSR _CALCTV
	RTS 
@FUNDR 
	DEX 
	BNE @REST
	JSR _CALCFND
	RTS 
@REST 
	JSR _CALCZZ
	RTS 

;schedule_clear() 
;resets current candidate schedule, precalc values
_SCHCLR 
	LDA #00
	TAX 
@SLOOP ;clear schedule/schedule count
	STA C_SCHEDC,X
	INX 
	CPX #$08
	BNE @SLOOP
	;clear fund/health precalc
	LDX #00
@PLOOP STA V_FHCOST,X
	INX 
	CPX #$4F
	BNE @PLOOP

	STA V_CPGPTR ;cp gain ptr reset
	LDA C_HEALTH ;init running totals
	STA V_FHCOST
	LDA C_MONEY
	STA V_FHCOST+1

	RTS 

;execute_schedule() 
;adds the precalc'd variables to CP/health/funds
;LOCAL: FVAR3
_SCHEXE 
	LDA #00
	TAX 
	STA C_SCHEDC
	STA V_CPGPTR
@LOOP 


	LDX C_SCHEDC
	LDA C_SCHED,X
	BEQ @INC ;rest
	CMP #$FF
	BEQ @INC ;fundraise
	CMP #$F0
	BCS @TVADS
	AND #$7F ;visit
	JSR _SCHEXE2
	JMP @INC
@TVADS 
	AND #$0F
	TAX 
	LDA D_REGLIM,X
	STA FVAR3
	LDA D_REGLIM-1,X
	STA FSTATE
@REGLOOP 
	LDA FSTATE
	JSR _SCHEXE2
	INC FSTATE
	LDA FSTATE
	CMP FVAR3
	BNE @REGLOOP
@INC 
	INC C_SCHEDC
	LDA C_SCHEDC
	CMP #$07
	BNE @LOOP

	LDA V_FHCOST+14
	STA C_HEALTH
	LDA V_FHCOST+15
	STA C_MONEY

	RTS 
;A = set state, load cp gain, add to state, inc ptr
_SCHEXE2 
	STA FARG1
	JSR _CPOFFS
	LDX V_CPGPTR
	LDA V_CPGAIN,X
	STA FRET1
	JSR _ADDCPU
	INC V_CPGPTR
	RTS 

;calc_fund() 
;calculates the FUNDRAISE gain
_CALCFND 
	LDA C_FUND
	ASL ;fund ; 2
	STA FRET3 ;running total is COST, so positive
	JSR _STPCHF
	RTS 

;calc_rest() 


_CALCZZ 
	LDA C_PARTY
	JSR _CTRLCNT
	LDA FRET2
	CLC 
	ADC FRET1 ;state control count
	ADC FRET1
	CLC 
	ADC C_STR
	ADC C_STR
	ADC C_CER
	CMP #$80
	BCC @CAP
	LDA #$7F
@CAP 
	STA FRET2

	LDA #00
	STA FRET1
	JSR _STPCHF
	RTS 

;calc_visit(FARG1=state index)
;calculates the CP/HEALTH/FUNDS changes from a VISIT
;returns to FRET1/2/3 respectively
_CALCVIS 
	JSR _LDAPCH
	AND #$F8
	BNE @LOWHEAL
	LDA #$01 ;1 CP gain
	STA FRET1
	STA FRET3
	LDA FARG1
	ORA #$80
	STA V_VBONUS
	JMP @COST
@LOWHEAL 

	JSR _LDAPCF
	BNE @NOMONEY
	JMP @WARNING ;if money is zero, action wasted
@NOMONEY 
	LDA V_VBONUS
	AND #$7F
	CMP FARG1
	BEQ @CANPAY ;if cumulative bonus, no setup fee

	LDX FARG1
	LDA V_EC,X
	LSR 
	LSR 
	LSR 
	STA FRET3 ;setup fee = base funds
	JSR _LDAPCF
	CMP FRET3
	BCS @CANPAY ;running total funds >= setup fee
	LDA #00
	STA FRET3
	JMP @WARNING ;no setup fee, action wasted
@CANPAY 
	JSR _CALCTRV ;calculate travel cost
	JSR _CPOFFS ;state still in FARG1
	LDA C_PARTY
	CLC 
	ADC #UND_OF1M
	TAY 
	LDA (CP_ADDR),Y
	STA FRET1 ;base CP = state lean

	LDA V_VBONUS
	AND #$7F
	CMP FARG1
	BNE @DIFSTAT ;same state as last
	LDA V_VBONUS
	AND #$80
	BEQ @NOTCSEC
	INC FRET1 ;+1 for >2 visits
	BNE @COST
@NOTCSEC 
	INC FRET1
	INC FRET1 ;+2 for cumulative visit
	LDA V_VBONUS
	ORA #$80
	STA V_VBONUS ;set penalty
	BNE @REMAING
@DIFSTAT 
	LDA FARG1
	STA V_VBONUS
@REMAING 
	LDA C_CER
	JSR _CPADD
	JSR _LDAPCH
	LSR 
	LSR 
	LSR 
	LSR 
	LSR 
	JSR _CPADD ;health / 32
	JSR _CISSUEB ;issue bonus
@COST 
	LDA FRET1
	JSR _STPCCP
	PHA 
	CMP #$0A
	BCS @NOWARN
	LDA #$01
	STA V_WARN ;warning if CP gain < 10
@NOWARN 
	PLA 
	LSR 
	STA FRET2
	LSR 
	CLC 
	ADC FRET3


	ADC V_TRAVEL ;travel cost
	STA FRET3

	JSR _HFNEG
	JSR _STPCHF
	RTS 
@WARNING 
	LDA #$01
	STA V_WARN ;warning if failure to visit
	RTS 

;calc_travel(FARG1=state) 
;sets travel cost flag
;VBONUS still set to last bonus
_CALCTRV 
	LDA V_VBONUS
	AND #$7F
	JSR _STATEGR
	TXA 
	STA V_TRAVEL
	LDA FARG1
	JSR _STATEGR
	TXA 
	CMP V_TRAVEL
	BNE @COST1
	LDA #$00
	BEQ @COST0
@COST1 
	LDA #$01
@COST0 
	STA V_TRAVEL
	RTS 

;calc_tvads(FARG1=region) 
;calculates the CP/HEALTH/FUNDS changes from a TV ADS
;LOCAL: FVAR2,FVAR3
_CALCTV 
	LDA #00
	STA FVAR2 ;running total

	JSR _LDAPCF
	CMP #$0F
	BCS @FUNDS
	JMP @WARN ;if funds < 15, action wasted
@FUNDS 
	JSR _LDAPCH
	CMP #$1E ;if health < 30, action wasted
	BCS @HEALTH
	JMP @WARN
@HEALTH 

	LDX FARG1
	DEX 
	LDA D_REGLIM,X
	STA FSTATE
	JSR _CPOFFS
	LDA D_REGLIM+1,X


	STA FVAR3
@LOOP 
	LDA V_WEEK
	ASL 
	STA FRET1

	LDA FSTATE
	JSR _CISSUEB

	LDA C_TV
	JSR _CPADD
	LDA C_CER
	JSR _CPADD
	LSR FRET1

	LDA FVAR2
	CLC 
	ADC FRET1
	STA FVAR2 ;add to running total

	LDA FRET1
	JSR _STPCCP

	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	CMP FVAR3
	BNE @LOOP

	LDA FVAR2
	LSR 
	STA FRET2
	LSR 
	CLC 
	ADC C_TV
	ADC C_TV
	STA FRET3
@COST 
	JSR _TVHALF
	JSR _HFNEG
	JSR _STPCHF
	RTS 
@WARN 
	LDA #$01
	STA V_WARN
	JSR _STPCHF
@RTS 
	RTS 

;tv_half(FARG1=region) 
;checks whether the HEALTH/FUND costs are below precalc h/f
;if not, halves the CP gains and the HEALTH/FUND costs
_TVHALF 
	JSR _LDAPCH
	CMP FRET2
	BCC @HALVE
	JSR _LDAPCF
	CMP FRET3


	BCC @HALVE
	BCS @RTS
@HALVE 
	LDA #$01
	STA V_TVWARN ;warning if halving occurs

	LDX FARG1
	DEX 
	LDA D_REGC,X
	TAY 
	INY 
@LOOP 
	LDX V_CPGPTR
	LSR V_CPGAIN,X
	DEC V_CPGPTR
	DEY 
	BNE @LOOP
	LDX FARG1
	DEX 
	LDA D_REGC,X
	CLC 
	ADC V_CPGPTR
	STA V_CPGPTR
	INC V_CPGPTR

	LSR FRET2
	LSR FRET3
	JMP _TVHALF ;halve until no cost barrier
@RTS 
	RTS 

;health_funds_negative() 
;makes VISIT, TV ADS HEALTH/FUND costs negative
_HFNEG 
	LDA FRET2
	JSR _NEGATIV
	STA FRET2
	LDA FRET3
	JSR _NEGATIV
	STA FRET3
	RTS 

;load_precalc_health() 
;previous action's running totals
_LDAPCH 
	LDA C_SCHEDC
	BEQ @INIT
	ASL 
	TAX 
	DEX 
	DEX ;LAST ACTION
	LDA V_FHCOST,X
	RTS 
@INIT 
	LDA C_HEALTH
	RTS 
;load_precalc_funds() 


;.. 
_LDAPCF 
	LDA C_SCHEDC
	BEQ @INIT
	ASL 
	TAX 
	DEX ;LAST ACTION
	LDA V_FHCOST,X
	RTS 
@INIT 
	LDA C_MONEY
	RTS 

;load_precalc_health_current() 
;load pc health for current action
_LDAPCHC 
	LDA C_SCHEDC
	ASL 
	TAX 
	LDA V_FHCOST,X
	RTS 
;load_precalc_funds_current() 
;load pc health for current action
_LDAPCFC 
	LDA C_SCHEDC
	ASL 
	TAX 
	INX 
	LDA V_FHCOST,X
	RTS 

;store_precalc_health_funds(FRET2 = health, FRET3 = funds)
_STPCHF 
	LDA C_SCHEDC
	ASL 
	TAX 

	LDA V_FHCOST-2,X
	STA FSUS2
	LDA FRET2
	JSR _ADDSUS
	LDA FSUS1
	STA V_FHCOST,X

	LDA V_FHCOST-1,X
	STA FSUS2
	LDA FRET3
	JSR _ADDSUS
	LDA FSUS1
	STA V_FHCOST+1,X
	RTS 

;store_precalc_cp_gain(A=value) 
_STPCCP 
	LDX V_CPGPTR
	STA V_CPGAIN,X
	INC V_CPGPTR
	RTS
	
;schedule_save()
;saves scheduled actions by week/candidate
_SCHSAV
	+__LAB2O V_SCHIST
	LDX V_WEEK
	DEX
	LDY #28
	JSR _OFFSET
	LDX V_PARTY
	LDY #07
	JSR _OFFSET
	
	LDY #00
@LOOP
	LDA C_SCHED,Y
	STA (OFFSET),Y
	INY
	CPY #$07
	BNE @LOOP
	RTS

;draw_action_log()
;draws the weekly actions per candidate
_ACTLOG
	LDA #$01
	STA V_WEEK
@TOP
	JSR _GX_CLRS
	
	LDA #$00
	STA FVAR4 ;week
	LDA #$00
	STA V_PARTY ;party
	
	;header
	LDA #$18
	STA GX_CCOL
	LDA #$00
	STA GX_CROW
	
	+__LAB2XY T_WEEK
	JSR _GX_STR
	
	LDA V_WEEK
	ORA #$30
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CIND
	INC GX_CCOL
	JSR _GX_CHAR
	INC GX_CIND
	INC GX_CCOL
	JSR _GX_CHAR
	
	INC GX_CROW
	LDA #$00
	STA GX_CCOL
@HEADER
	LDX V_PARTY
	JSR _DRWPN3
	LDA GX_CCOL
	CLC
	ADC #07
	STA GX_CCOL
	INC V_PARTY
	LDX V_PARTY
	CPX S_PLAYER
	BNE @HEADER
	
	INC GX_CROW
	;logs
@WEEK
	+__LAB2O V_SCHIST
	LDX V_WEEK
	DEX
	LDY #28
	JSR _OFFSET
	
	LDA #$00
	STA V_PARTY
	STA GX_CCOL
	STA GX_LX1
	STA FVAR3 ;schedule offset
	LDA GX_CROW
	STA GX_LY1 ;hold row
@LOGLOOP
	LDA GX_LX1
	STA GX_CCOL ;hold column
	LDY FVAR3
	+__O2O2
	LDA (OFFSET),Y
	JSR _ACTLOG2
	LDX FVAR1
	JSR _SCHDRW2
	+__O2O
	INC GX_CROW
	INC FVAR3
	LDA FVAR3
	CMP #$07
	BNE @LOGLOOP
	
	LDX #$01
	LDY #$07
	JSR _OFFSET
	
	LDA GX_LX1
	CLC
	ADC #10
	STA GX_LX1
	
	LDA GX_LY1
	STA GX_CROW
	
	LDA #$00
	STA FVAR3
	
	INC V_PARTY
	LDA V_PARTY
	CMP S_PLAYER
	BNE @LOGLOOP
	
	LDA GX_LY1
	CLC
	ADC #$08
	STA GX_LY1
	STA GX_CROW
	
	INC V_WEEK
	INC FVAR4
	LDA FVAR4
	CMP #$03
	BEQ @THIRD
	JMP @WEEK
@THIRD
	JSR _FTC
	LDA V_WEEK
	CMP #$0A
	BEQ @DONE
	JMP @TOP
@DONE
	JSR _GX_CLRS
	RTS

;action_to_action_selection (A = action)
_ACTLOG2
	BEQ @REST
	CMP #$FF
	BEQ @FUNDRAIS
	BMI @TVADS
	LDX #$00
	STA FARG1
	JMP @DONE
@TVADS
	LDX #$01
	AND #$0F
	STA C_CREG
	ORA #$F0
	JMP @DONE
@REST
	LDX #$03
	JMP @DONE
@FUNDRAIS
	LDX #$02
@DONE
	STX FVAR1
	RTS
	
	



