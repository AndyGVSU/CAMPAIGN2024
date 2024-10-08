;cmap.asm
;CAMP08 
;map routines

;map_view() 
;main SR for map viewing
;saves state index to MAP_RES
_MAP 
	LDA #$02
	STA SPRON

	LDA #01
	STA FARG1
@INPLOOP 
	JSR _MAPCURS
	LDA #00
	STA FARG1
	STA FARG2
	STA FARG3
	JSR _INPUTF1
	BEQ @RTS
	CMP #VK_FASTF
	BEQ @RTS

	CMP #VK_RIGHT
	BNE @DOWN
	INC FARG3

	JMP @INPLOOP
@DOWN 
	CMP #VK_DOWN
	BNE @LEFT
	INC FARG2

	JMP @INPLOOP
@LEFT 
	CMP #VK_LEFT
	BNE @UP
	DEC FARG3

	JMP @INPLOOP
@UP 
	DEC FARG2

	JMP @INPLOOP
@RTS 
	JSR _MAPCUR2 ;clear cursor
	LDA #$00
	STA SPRON
	STA SAVEMAP
	RTS 
;wrap row/col
_MAP2 
	LDA MAP_ROW
	BMI @HIROW
	CMP #$0F
	BCS @LOROW
	BCC @ROWOK
@HIROW 
	LDA #$0E
	STA MAP_ROW
	BNE @ROWOK


@LOROW 
	LDA #00
	STA MAP_ROW
@ROWOK 
	LDA MAP_COL
	BMI @HICOL
	CMP #$19
	BCS @LOCOL
	BCC @COLOK
@HICOL 
	LDA #$18
	STA MAP_COL
	BNE @COLOK
@LOCOL 
	LDA #00
	STA MAP_COL
@COLOK 
	RTS 

_MAPGSHP 
	+__LAB2O D_MAPSHP
	LDX MAP_ROW
	LDY #$19
	JSR _OFFSET
	LDY MAP_COL
	LDA (OFFSET),Y
	STA MAP_RES
	RTS 

;map_draw_cursor(FARG1 = init, FARG2 = new row, FARG3 = new col)
_MAPCURS 
	LDA FARG1
	BNE @SKIP
	;redraw held pixel (unless init)
	JSR _MAPCUR2
	;update row/col
	LDA MAP_ROW
	CLC 
	ADC FARG2
	STA MAP_ROW
	LDA MAP_COL
	CLC 
	ADC FARG3
	STA MAP_COL
	JSR _MAP2
@SKIP ;hold new pixel
	JSR _CURSTSC
	JSR _MAPGSHP
	JSR _MAPINFO

	RTS 
;redraw held pixel
_MAPCUR2 
	LDA MAP_HELD
	STA GX_PCOL
	JSR _CURSTSC
	RTS 

;cursor_coord_to_screen_coord() 
_CURSTSC 
	LDA #00
	STA SPRPOS8
	LDA #C_WHITE
	STA SPRCOL+1
	LDA MAP_ROW
	ASL 
	ASL 
	ASL 
	CLC 
	ADC #$3A ;map offset
	STA SPRPOS+3
	LDA MAP_COL
	ASL 
	ASL 
	ASL 
	CLC 
	ADC #$38 ;map offset
	STA SPRPOS+2
	RTS 

;map_info() 
;displays MAP_RES postal code/EC/party control/region/HQ counts
_MAPINFO 
	LDA SAVEMAP
	CMP MAP_RES
	BNE @INVALID
	RTS
@INVALID

	LDA MAP_RES
	BNE @RESET
	LDA #$FF
	STA SAVEMAP
	RTS 
@RESET

	LDA #P_MAPINFC
	STA GX_CCOL
	LDA #P_TOP
	STA GX_CROW

	LDA #18
	JSR _DRWBLANK

	LDA MAP_RES
	BEQ @RTS

	LDA #P_MAPINFC
	STA GX_CCOL
	LDA #P_TOP
	STA GX_CROW
	LDA #C_WHITE
	STA GX_DCOL

	LDA MAP_RES
	JSR _DRWPOST2
	LDX MAP_RES
	JSR _DRWSTEC
	
	LDA V_STRING+1
	BNE @SPACE
	INC GX_CCOL
@SPACE
	INC GX_CCOL
	LDX MAP_RES
	JSR _LDACTRL
	TAX 
	JSR _DRWPN1

	LDA #C_LBLUE
	STA GX_DCOL

	INC GX_CCOL
	LDA MAP_RES
	JSR _STATEGR
	TXA 
	ORA #NUMBERS
	JSR _GX_STR2
	
	LDA #C_YELLOW
	STA GX_DCOL
	
	INC GX_CCOL
	+__LAB2XY T_HQ
	JSR _GX_STR
	
	LDX #00
	STX FPARTY
@HQLOOP
	LDX FPARTY
	LDY MAP_RES
	JSR _LDAHQ
	LDX FPARTY
	LDA V_PTCOL,X
	STA GX_DCOL
	LDA BITRET
	ORA #NUMBERS
	JSR _GX_STR2
	INC FPARTY
	LDX FPARTY
	CPX S_PLAYER
	BNE @HQLOOP
	
	LDA MAP_RES
	STA SAVEMAP

@RTS 
	RTS

_DRWBORD
	LDA #C_WHITE
	STA GX_DCOL
	LDA #$03
	STA GX_LX1
	LDA #$1E
	STA GX_LX2
	LDA #$00
	STA GX_LY1
	LDA #$11
	STA GX_LY2
	JSR _GX_RECT

	RTS 

;map_combo_1() 
;draws the border and map
_MAPCMB1
	LDA S_SKIPGAME
	BNE @SKIPDRW
	JSR _DRWBORD
	JSR _DRWMAP
@SKIPDRW
	RTS 

;map_combo_2() 
;sets state control
_MAPCMB2
	JSR _STCTRL
	JSR _MAPCMB3
	RTS 

;map_combo_3()
;sets colors and draws map
_MAPCMB3
	LDA S_SKIPGAME
	BNE @SKIPDRW
	JSR _MAPCOL
	JSR _DRWMAP
@SKIPDRW
	RTS
	
;issue_map
;sets map colors to candidate issue bonus
_ISSUEMAP
	JSR _CPOFFR
@STLOOP
	LDA CPSTATE
	STA FARG1
	JSR _CISSUEB
	LDX #00
@LOOP
	CMP D_ISSTBL,X
	BCC @EXIT
	INX
	BNE @LOOP
@EXIT
	LDA D_ISSCOL,X
	LDX CPSTATE
	STA V_STCOL,X
	
	JSR _CPOFFI
	BNE @STLOOP
	RTS
_ISSUEMAP2
	JSR _ISSUEMAP
	JSR _DRWMAP
	RTS
