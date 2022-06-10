TEST = $49
TEST2 = $65

*= $0801

!macro TESTMAC .one,.two {
	lda .one
	sta .two
}

_MAIN
	lda #03
	sta $4000
	lda TEST
	sta TEST2
	+TESTMAC TEST,TEST2

@loop
	ldx #00
	lda $8000,x
	inx
	cpx #$10
	bne @loop

	jsr _SUBR

	rts
	
_SUBR
	ldx #00
@loop
	lda $8000,x
	sta $9000,x
	inx
	cpx #$20
	bne @loop
	rts

!binary "source/DATASPREMPTY.dat"

_FINAL
	lda $1337
	sta $1337
	rts

	