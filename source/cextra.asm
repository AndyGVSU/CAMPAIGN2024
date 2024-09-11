
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

;tests if a candidate has CER > 6 compared to all other candidates
_OVERKILL
@COPYCER
	LDA C_CER
	LDX V_PARTY
	STA V_LEAN,X
	JSR _CANDSWAP
	LDA V_PARTY
	BNE @COPYCER
	JSR _LEANTOMAX
	JSR _LEANDIF
	LDA FRET1
	CMP #06
	BCC @DONE
	LDX V_MAXPL
	LDA #01
	STA V_OVERKILL,X
@DONE
	RTS
	
;sets first state to do POLL
_AITOP
	LDA V_PARTY
	JSR _CANDLOAD
	LDA C_HOME
	LDX V_PARTY
	STA V_AITOP,X
	INC V_PARTY
	LDA V_PARTY
	CMP S_PLAYER
	BNE _AITOP
	LDA #00
	STA V_PARTY
	JSR _CANDLOAD
	RTS
	
;draw_blank(A = count)
_DRWBLANK
    STA T_BLANKX+4
    +__LAB2XY T_BLANKX
    JSR _GX_STR
	RTS

;float_add_with_flag_set()
;FADDT work correctly
_FADDFLAG
	LDA #00
	STA ARG+6 ;why does this work???
	LDA FAC
	JSR _FADDT
	RTS

;load_neglect(X = state index if not from history)
_LDANEGL
	LDA V_SUMFH
	BNE @HIST
	LDA V_NEGLECT,X
	RTS
@HIST
	LDY #06
	LDA (HS_ADDR),Y
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
	
;unpack_nibble(V_NIBBLE+0)
;unpacks two 4-bit values
;returns to V_NIBBLE+0, V_NIBBLE+1
_UNIBBLE
	LDA V_NIBBLE
	PHA
	AND #%11110000
	LSR
	LSR
	LSR
	LSR
	STA V_NIBBLE+0
	PLA
	AND #%00001111
	STA V_NIBBLE+1
	RTS
	
;copies V_MAX1B to V_MAX
_MAX1B
	LDX #00
	LDY #00
@LOOP
	LDA V_MAX1B,X
	STA V_MAX+1,Y
	INX
	INY
	INY
	CPX #$04
	BNE @LOOP
	RTS

;advantage_check()
;if any player has OVERKILL, they get +1 to all SL
_ADVANTAGE
	JSR _CPOFFR
@STLOOP
	LDY #CPBLEAN
@LOOP
	LDA V_OVERKILL-4,Y
	BEQ @SKIP
	LDA (CP_ADDR),Y
	CLC
	ADC #$01
	STA (CP_ADDR),Y
@SKIP
	INY
	CPY #CPBLOCK
	BNE @LOOP
	JSR _CPOFFI
	BNE @STLOOP
	RTS

;if any player has FRINGE, their SL is set to 1 in *every* state
_FRINGE
	JSR _CPOFFR
@STLOOP
	LDY #CPBLEAN
@LEANLOOP
	LDA V_FRINGE-PLAYERMAX,Y
	BEQ @SKIP
	
	LDA #$01
	STA (CP_ADDR),Y
@SKIP
	INY
	CPY #CPBLOCK
	BNE @LEANLOOP
	
	JSR _CPOFFI
	BNE @STLOOP
	
	RTS
	
;table_jsr(X/Y = jump table address, A = jump table index) 
_TABLJSR
	;modify load address
	STX @L1+1
	STY @L1+2
	STX @L2+1
	STY @L2+2
	
	;set load address
	ASL
	TAX
@L1
	LDA $0000,X
	PHA
	INX
@L2
	LDA $0000,X
	STA @TEST+2
	PLA
	STA @TEST+1
@TEST	
	;execute
	JSR $0000
	RTS

;load_state_lean(V_PARTY = party, CP_ADDR set beforehand)
;uses A, Y
_LDALEAN
	LDA V_PARTY
	CLC
	ADC #CPBLEAN
	TAY
	LDA (CP_ADDR),Y
	RTS