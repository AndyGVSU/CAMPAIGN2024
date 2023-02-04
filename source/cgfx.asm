;cgfx.asm
;CAMP04 
;custom graphics routines

;gx_char() 
;c_row = row to draw at
;c_col = column to draw at
;c_index = char to draw
;d_col = draw color
;b_col = background color
;draws a character bitmap at the specified location

_GX_CHAR 
	LDA OFFSET
	STA GX_X
	LDA OFFSET+1
	STA GX_Y

	+__LAB2O V_SCREEN

	LDX GX_CROW
	LDY #$28
	JSR _OFFSET

	LDY GX_CCOL
	JSR _CHARMAP ;map GX_CIND
	
	;LDA GX_BCOL
	;AND #$0F
	;TAX 
	;LDA D_C64COL,X
	;CMP #C_BLACK
	;BEQ @SKIPEBG
	;CMP #C_WHITE
	;BEQ @WHITE
	;LDA GX_CIND
	;CLC 
	;ADC #$40
	JMP @DRAW
@WHITE 
	LDA GX_CIND
	CLC 
	ADC #$80
	JMP @DRAW
@SKIPEBG 
	LDA GX_CIND
@DRAW 
	STA (OFFSET),Y

	LDA OFFSET+1
	CLC 
	ADC #$D4
	STA OFFSET+1

	LDA GX_DCOL
	STA (OFFSET),Y

	LDA GX_X
	STA OFFSET
	LDA GX_Y
	STA OFFSET+1



	RTS 

;char_map() 
;remaps ALPHA characters for multicolor background mode
_CHARMAP 
	LDA GX_CIND
	CMP #ALPHAS
	BCS @MAP
	RTS 
@MAP 
	SEC 
	SBC #ALPHAS
	STA GX_CIND
	RTS 

;gx_string(x/y=low/hi byte of null-terminated string address)
;c_row 
;c_col 
;d_col = default draw color (can be changed by pen color codes)
;b_col = background color
;repeat char format [FE, repeat char, repeat count]
_GX_STRA
	LDA #$01
	STA V_STRWAIT
	JMP _GX_STR_2
_GX_STR 
	LDA #00
	STA V_STRWAIT
_GX_STR_2
	STX GX_STLB
	STY GX_STUB
	
	LDA #00
	STA GX_STRC
	
	LDA GX_CCOL
	STA GX_SCOL

	LDA GX_DCOL
	STA GX_PCOL
	
	LDY #00
@LOOP 
	JSR _STRWAIT
	LDY GX_STRC
	INC GX_STRC
	LDA (GX_STLB),Y
	BNE @STRBRK
	RTS 
@STRBRK 
	CMP #NEWLINE
	BNE @STRREP
	LDA GX_SCOL
	STA GX_CCOL
	JSR _GXINCRW
	JMP @LOOP
@STRREP 
	CMP #REPCHAR
	BNE @STRBC
	INC GX_STRC
	INY 
	LDA (GX_STLB),Y
	STA GX_SHLD
	INC GX_STRC
	INY 
	LDA (GX_STLB),Y
	STA GX_SREP
@REPLOOP 
	JSR _STRWAIT
	LDA GX_SHLD
	JSR _GX_STR2
	DEC GX_SREP
	LDA GX_SREP
	BNE @REPLOOP
	JMP @LOOP
@STRBC 
	CMP #BACKCHAR
	BCC @STRPC
	AND #$0F
	STA GX_BCOL
	JMP @LOOP
@STRPC 
	CMP #PENCHAR
	BCC @STRAZ
	AND #$0F
	TAX 
	LDA D_C64COL,X
	STA GX_DCOL
	JMP @LOOP
@STRAZ 
	JSR _GX_STR2
	JMP @LOOP

_GX_STR2 
	STA GX_CIND
	JSR _GX_CHAR
	INC GX_CCOL
	RTS 

_GX_SPACE
	LDA #VK_SPACE
	JSR _GX_STR2
	RTS
	
;string_wait()
;wait a little bit to animate text
_STRWAIT
	LDA V_STRWAIT
	BEQ @RTS
	LDA #$00
	STA V_STRWAIT+1
@LOOP1
	INC V_STRWAIT
	LDA V_STRWAIT
	BNE @LOOP1
	INC V_STRWAIT+1
	LDA V_STRWAIT+1
	CMP #$40
	BNE @LOOP1
	
	LDA #$01
	STA V_STRWAIT
@RTS
	RTS

;gx_clear_screen() 
;clears screen to black
_GX_CLRS 
	LDA #C_BLACK
	STA GX_PCOL
	JSR _GX_FILL
	RTS 

;gx_rectangle() 
;takes dcol
;gx_LX1/x2/y1/y2 are by character (divided by 4)
_GX_RECT 
	LDA #FILLCHR
	STA GX_CIND
	LDA GX_LY1
	STA GX_CROW
@ROWLOOP 
	LDA GX_LX1
	STA GX_CCOL
@COLLOOP 
	JSR _GX_CHAR
	INC GX_CCOL
	LDA GX_CCOL
	CMP GX_LX2
	BCC @COLLOOP
	INC GX_CROW
	LDA GX_CROW
	CMP GX_LY2
	BCC @ROWLOOP
	RTS 

;gx_rectangle_clear() 
;gx_rect, but always uses p_col=0
_GXRECTC 
	LDA #C_BLACK
	STA GX_DCOL
	JSR _GX_RECT
	RTS 

;gx_increment_row() 
;increments row by one standard character
_GXINCRW 
	INC GX_CROW
	RTS 
