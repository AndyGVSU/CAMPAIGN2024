;csched.asm
;CAMP01 
;schedule routines

;clear_schedule_bottom_right()
_CLRBR 
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
	STA FVAR1
_SCHADD2
	LDX C_SCHEDC
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
	STA V_SCHED,X
	INC C_SCHEDC
	INC V_SCHEDC

	LDA FVAR1
	JSR _SCHPC
	
	LDX C_SCHEDC
	LDA V_CPGPTR
	STA V_CPGPTRO,X
;PROCEED DIRECTLY TO _SCHDRW

;draw_to_schedule(FVAR1=action,FARG1=visited state)
;draws the provided action to schedule
_SCHDRW
	LDA S_SKIPGAME
	BEQ @SKIPGAME
	RTS
@SKIPGAME
	JSR _SCHDRW3
	LDX FVAR1
	JSR _SCHDRW2
	JSR _SCHWARN
	RTS
;text draw (x = selected action)
_SCHDRW2
	BNE @TVADS ;VISIT

	LDX FARG1
	LDA V_STCOL,X
	STA GX_DCOL

	LDA FARG1
	JSR _DRWPOST2
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
;clear schedule line for current count and reset column
_SCHDRW3
	LDA C_SCHEDC
	CLC 
	ADC #P_SCH2R
	STA GX_CROW
	LDA #P_SCH2C
	STA GX_CCOL
	;set blank count
	LDA #09
	JSR _DRWBLANK
	LDA #P_SCH2C
	STA GX_CCOL
	RTS
	
;schedule_warning() 
;draws a warning if one was issued during precalc
_SCHWARN 
	LDA S_SKIPGAME
	BNE @RTS
	LDA V_STAFFOUT
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
	LDA #VK_PERC
	STA GX_CIND
	BNE @DRAW
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
	LDA FARG1
	STA FARG3 ;swap, since uses _CPOFFS
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
	STA V_SCHEDC,X
	INX 
	CPX #ACTIONMAX+1
	BNE @SLOOP
	;clear fund/health precalc
	LDX #00
@PLOOP 
	STA V_FHCOST,X
	INX 
	CPX #CPGAIN_MAX
	BNE @PLOOP
	
	STA V_CPGPTR ;cp gain ptr reset
	
	LDX V_PARTY
	LDA V_STLOCK,X
	BEQ @RTS
	STA V_SCHED
	STA V_SCHED+1
	LDA #02
	STA V_SCHEDC
@RTS
	RTS 

;execute_schedule() 
;adds the precalc'd variables to CP/health/funds
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
	AND #%01111111 ;visit
	PHA

	JSR _STATEGR
	TXA
	LDX V_PARTY
	CMP V_RALLYDEATH,X
	BNE @SKIPDEATH
	LDA #EVC_SCANDAL_DEATH
	STA V_SCANDAL,X
@SKIPDEATH
	PLA
	
	TAX
	JSR _SCHEXE2
	JMP @INC
@TVADS 
	AND #$0F
	TAX 
	JSR _LREGLIM
@REGLOOP 
	LDA LOWSTATE
	JSR _SCHEXE2
	INC LOWSTATE
	LDA LOWSTATE
	CMP HIGHSTATE
	BNE @REGLOOP
@INC 
	INC C_SCHEDC
	LDA C_SCHEDC
	CMP #ACTIONMAX
	BNE @LOOP

	LDA V_FHCOST+14
	STA C_HEALTH
	LDA V_FHCOST+15
	STA C_MONEY

	RTS 
;A = set state, load cp gain, add to state, inc ptr
_SCHEXE2 
	JSR _CPOFFS
	LDX V_CPGPTR
	LDA V_CPGAIN,X
	STA FRET1
	JSR _ADDCP
	INC V_CPGPTR
	RTS 

;calc_fund() 
;calculates the FUNDRAISE gain
_CALCFND 
	LDA C_FUND
	ASL
	STA FRET3 ;running total is COST, so positive
	JSR _STPCHF
	RTS 

;calc_rest() 


_CALCZZ 
	LDA V_PARTY
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
	LDA #$01
	STA V_WARN 
	JMP @COST
@LOWHEAL 

	JSR _LDAPCF
	BNE @NOMONEY
	JMP @WARNING ;if money is zero, action wasted
@NOMONEY 
	LDY FARG1 ;if pandemic event, action wasted
	LDA #EV_PANDEMIC
	JSR _EVENTON
	BNE @DOUBLE
	LDA #$00
	STA FRET1
	STA FRET2
	STA FRET3
	JMP @WARNING
@DOUBLE
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
	LDA FARG1
	JSR _CPOFFS ;state still in FARG1
	LDY V_PARTY
	LDA (CP_ADDR),Y
	CMP #$FF
	BNE @CAP
	JMP @WARNING
@CAP
	
	TYA
	CLC 
	ADC #CPBLEAN
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
	LDA #$01
	STA V_WARN 
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
	JSR _FILLVB

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
@COST ;if we get to this point, there was a CP gain
	;event handling
	LDY FARG1
	LDA #EV_FAIR
	JSR _EVENTON
	BNE @PLUS4
	LDA FRET1
	CLC
	ADC #$04
	STA FRET1
@PLUS4
	LDY FARG1
	LDA #EV_WEATHER
	JSR _EVENTON
	BNE @HALVE
	LSR FRET1
@HALVE

	LDA FRET1
	LDX FARG1
	JSR _STPCCP
	;warning if CP gain < 10
;@NOWARN
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
	LDX V_PARTY
	LDA V_WARP,X
	BNE @COST0
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
@COST0
	LDA #$00
	BEQ @STA
@COST1 
	LDA #$01
@STA 
	STA V_TRAVEL
	RTS 

;calc_tvads(FARG3=region) 
;calculates the CP/HEALTH/FUNDS changes from a TV ADS
;LOCAL: FVAR2,FVAR3
_CALCTV 
	LDA #00
	STA FVAR2 ;running total

	JSR _LDAPCF
	CMP #25
	BCS @FUNDS
	JMP @WARN ;if funds < 25, action wasted
@FUNDS 
	JSR _LDAPCH
	CMP #10 ;if health < 10, action wasted
	BCS @HEALTH
	JMP @WARN
@HEALTH 

	LDA FARG3 ;if power down event, action wasted
	AND #$0F
	TAX
	JSR _LREGLIM
	LDY LOWSTATE
	LDA #EV_POWER
	JSR _EVENTON ;only one state check required
	BNE @POWEROUT
	JMP @WARN
@POWEROUT

	LDA LOWSTATE
	STA FSTATE
	JSR _CPOFFS
@LOOP
	LDA #00
	STA FRET1

	LDA FSTATE
	JSR _CISSUEB
	ASL
	STA FRET1

	LDA C_TV
	ASL
	JSR _CPADD
	LDA C_CER
	JSR _CPADD
	JSR _LDALEAN
	JSR _CPADD
	;event handling
	LDY FSTATE
	LDA #EV_TVADS
	JSR _EVENTON
	BNE @PLUS
	LDA #04
	JSR _CPADD
@PLUS
	LDA FRET1
	LSR
	LSR
	LSR
	CLC
	ADC FVAR2
	STA FVAR2 ;add (CP/8) to running total as cost (this is really (CP/2) / 4)

	LDA FRET1 ;add (CP/2) to actual gain
	LSR
	JSR _STPCCP
	
	JSR _CPOFFI
	INC FSTATE
	LDA FSTATE
	CMP HIGHSTATE
	BNE @LOOP
	
	LDA #10 ;flat cost of 10 HEALTH
	STA FRET2
	LDA FVAR2
	CLC 
	ADC C_TV
	ADC V_WEEK
	ADC V_WEEK
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

;tv_half(FARG3=region) 
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

	LDX FARG3
	LDA D_REGC-1,X
	TAY 
	INY 
@LOOP 
	LDX V_CPGPTR
	LSR V_CPGAIN,X
	DEC V_CPGPTR
	DEY 
	BNE @LOOP
	LDX FARG3
	LDA D_REGC-1,X
	CLC 
	ADC V_CPGPTR
	STA V_CPGPTR
	INC V_CPGPTR

	LSR FRET2
	LSR FRET3
	JMP _TVHALF ;halve until no cost barrier
@RTS
	LDA V_CPGPTR
	LDX FARG3
	SEC
	SBC D_REGC-1,X
	STA V_CPGPTR
	
	LDA D_REGLIM-1,X
	STA FSTATE
@CAPLOOP
	INC FSTATE
	INC V_CPGPTR
	LDA FSTATE
	LDX FARG3
	CMP D_REGLIM,X
	BNE @CAPLOOP
	
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
	LDA #P_ACTLOGC
	STA GX_CCOL
	LDA #P_TOP
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
	JSR _ACTLOG3
	
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
;converts schedule action code into action index
_ACTLOG2
	CMP #ACTIONREST
	BEQ @REST
	CMP #ACTIONFUND
	BEQ @FUNDRAIS
	BMI @TVADS
	LDX #ACT_VISIT
	STA FARG1
	JMP @DONE
@TVADS
	LDX #ACT_TVADS
	AND #$0F
	STA C_CREG
	ORA #$F0
	JMP @DONE
@REST
	LDX #ACT_REST
	JMP @DONE
@FUNDRAIS
	LDX #ACT_FUNDR
@DONE
	STX FVAR1
	RTS
;action_log_offset()
_ACTLOG3
	+__LAB2O V_SCHIST
	LDX V_WEEK
	DEX
	LDY #PLAYERMAX*ACTIONMAX
	JSR _OFFSET	
	RTS

;schedule_copy()
;clears and adds schedule again
_SCHCOPY
	LDX V_SCHEDC
	BEQ @RTS
	STX FVAR7
	
	JSR _RESETVB
	LDX #00
	STX C_SCHEDC
	STX V_SCHEDC
	STX FVAR6
@ADDLOOP	
	LDA V_SCHED,X
	JSR _ACTLOG2
	LDA FVAR1 ;action index
	JSR _SCHADD2
	INC FVAR6
	LDA FVAR6
	TAX
	CMP FVAR7
	BNE @ADDLOOP
	
@RTS
	RTS

;fill_visit_bonus(A = visit bonus state index)
;fill visit bonus to end of schedule to compensate for other actions not adding it
_FILLVB
	LDX C_SCHEDC
@FILLVB
	STA V_SCHEDVB,X
	INX
	CPX #07
	BCC @FILLVB
	RTS
	
;init_funds_health()
;sets starting funds and health for WEEK
_INITFH
	LDA C_HEALTH ;init running totals
	STA V_FHCOST
	LDA C_MONEY
	STA V_FHCOST+1
	RTS

