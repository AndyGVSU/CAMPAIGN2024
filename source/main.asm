;cmain.asm;CAMPAIGN MANAGER 2024 V2.1E C64 EDITION
;main source file

;sets draw coordinates
!macro __COORD .row,.col {
	LDA #.row
	STA GX_CROW
	LDA #.col
	STA GX_CCOL
	} 

;unpacks label to X(L),Y(U)
!macro __LAB2XY .label {
	LDX #<.label
	LDY #>.label
	} 

;swaps values; arg1 with arg2
!macro __SWAP .arg1,.arg2,.swap {
	LDA .arg1
	STA .swap
	LDA .arg2
	STA .arg1
	LDA .swap
	STA .arg2
	}

;swaps values using X; arg1,x with arg2,x
!macro __SWAPX .arg1,.arg2,.swap {
	LDA .arg1,x
	STA .swap
	LDA .arg2,x
	STA .arg1,x
	LDA .swap
	STA .arg2,x
	}		

;unpacks label to FVAR1(L),FVAR2(H)
!macro __LAB2FV .label {
	LDA #<.label
	STA FVAR1
	LDA #>.label
	STA FVAR2
	}
;unpacks label to OFFSET(L),OFFSET(H)
!macro __LAB2O .label {
	LDA #<.label
	STA OFFSET
	LDA #>.label
	STA OFFSET+1
	} 
;unpacks label to OFFSET2(L),OFFSET2(H)
!macro __LAB2O2 .label {
	LDA #<.label
	STA OFFSET2
	LDA #>.label
	STA OFFSET2+1
	}
;moves OFFSET to OFFSET2
!macro __O2O2 {
	LDA OFFSET
	STA OFFSET2
	LDA OFFSET+1
	STA OFFSET2+1
	}
;moves OFFSET2 to OFFSET
!macro __O2O {
	LDA OFFSET2
	STA OFFSET
	LDA OFFSET2+1
	STA OFFSET+1
	}
;unpacks label1 to FARG1(L),FARG2(H)
;unpacks label2 to FARG3,FARG4..
!macro __LAB2A2 .label1,.label2 {
	LDA #<.label1
	STA FARG1
	LDA #>.label1
	STA FARG2
	LDA #<.label2
	STA FARG3
	LDA #>.label2
	STA FARG4
	} 

;unpacks label1 to FARG1(L),FARG2(H)
!macro __LAB2A .label {
	LDA #<.label
	STA FARG1
	LDA #>.label
	STA FARG2
	} 
;transfers OFFSET/OFFSET+1 to X/Y
!macro __O2XY {
	LDX OFFSET
	LDY OFFSET+1
	} 

;labels resolution][ graphics

START = $0801

;system routines
_162FAC = $B391 ;?
_FAC216 = $B1AA
_FAC2ARG = $BC0F
_ARG2FAC = $BBFC
_FDIVT = $BB12
_FAC2STR = $BDDD ;garbles FAC
_FAC2STR2 = $BDDF
_STR2FAC = $B7B5
_FINT = $BCCC
_FAC232 = $BC9B
_FSUB = $B850
_FSUBT = $B853
_FDIV10 = $BAFE
_FMULTT = $BA2B
_FMUL10 = $BAE2
_FADD = $B867
_FADDT = $B86A
_MOVMF = $BBD4
_MOVFM = $BBA2
_ABS2 = $BC49
_FCOMP = $BC5B
_MEM2ARG = $BA8C

;C64 addresses
INT_ADDR = $0314
KEYREP = $028A
SPRPOS = $D000
SPRPOS8 = $D010
SCRREG1 = $D011
SPRON = $D015
SPRDBL = $D01D
BACKCOL = $D021
SPRCOL = $D027
COLRAM_MAP = $D82C
INTERRUPT = $EA31

V_STRING = $0100
V_KEYBUF = $0277

V_SCREEN = $0400
SPRPTR = $07F8
V_SPRITE = $0840
SFXFRQ = $D400
SFXWIDTH = $D402
SFXCTRL = $D404
SFXATK = $D405
SFXSUS = $D406
SFXVOL = $D418
VOICE3OUT = $D41B
V_COLRAM = $D800
V_TITLANIM = V_COLRAM+$02D6
V_JOY2 = $DC00
V_JOY1 = $DC01
JOYDEF2 = $7F
JOYDEF1 = $FF

_SCNKEY = $FF9F
_GETIN = $FFE4

BASE2 = $8500
V_HQ = $0000+BASE2 ;HQ per party per state, in bit-pairs (aabbccdd)
SCRATCH = $0034+BASE2
V_DBLOG = $0178+BASE2; (84B)
V_POLLMAP = $01CC+BASE2 ;map CTRL values for POLL
;camp2024 addresses
V_CP = $0200+BASE2 ;CP and STATE LEANS by state per party (4*2*51B = 408B)
V_NEGLECT = $0398+BASE2 ;NEGLECT consecutive week count by state (51B)
V_CTRL = $03CB+BASE2
V_STCOL = $0400+BASE2
;V_CPCAP = $0434+BASE2
V_TIERES = $0468+BASE2
V_COLMSK = $049C+BASE2
V_ISSUE = $0500+BASE2
V_ALLCND = $0600+BASE2
V_EC = $0685+BASE2
V_FPOINT = $06C0+BASE2
V_FLOAT3 = $06F8+BASE2
V_PRIMRY = $0700+BASE2
V_FHCOST = V_PRIMRY
V_CPGAIN = $0710+BASE2
V_PNAME = $07A0+BASE2 ;(40B)
V_ETABLE = $07C8+BASE2 ;event table (51B)
V_PRIOR = $0800+BASE2 ;hard AI priority list (64B): 50 states + 9 TV ADS
V_PRIORI = $0840+BASE2 ;hard AI priority list state INDEX (64B)
;;
V_AISTAT = $08B0+BASE2 ;hard AI used for [STATE LEAN averaged by region list] or [list of region states] (9B)
V_MAX = $08C0+BASE2 ;8B (4 pairs of LB/HB)
V_EVENPERC = $08C8+BASE2 ;fixed percentage even share (100 - UND%) / S_PLAYER
V_UNDPERC = $08C9+BASE2 ;UND%
V_EVENPERCST = $08CA+BASE2 ;fixed percentage even share with state's NEGLECT (V_EVENPERCST + (NEGLECT / S_PLAYER))
V_LEANT = $08CB+BASE2 ;for summing STATE LEANS
V_INCPERC = $08CC+BASE2 ;multiplier for STATE LEANS (5B)
V_FIXPERC = $08D1+BASE2 ;fixed percentage floats (4 players * 5B) = 20B
V_POLLON = $08E5+BASE2 ;boolean - POLL has been done for current player this WEEK
V_INCDUBL = $08E6+BASE2 ;flag to double V_INCPERC
;V_ADDCP3P = $08E7+BASE2 ;counter for current party in _CPADD3
V_LEAN = $08E8+BASE2 ;state lean holding area (4B)
V_PARTYH = $08EC+BASE2 ;holds V_PARTY temp
V_RANDCP = $08ED+BASE2 ;boolean - add random factor to state CP
V_AISTATC = $08EE+BASE2 ;carry
V_AIEC = $08EF+BASE2 ;ec sum (2B)
V_HQBUILT = $08F1+BASE2 ;boolean HQ built this turn
V_AIPOLC = $08F2+BASE2 ;hard AI region poll count
V_PLURALF = $08F3+BASE2 ;V_PLURAL as float (5B)
;;
V_REVERT = $0900+BASE2 ;per state
;V_LSTATE = $0934+BASE2
V_DOMNGL = $0935+BASE2 ;DOMINATION/NEGLECT flags per state (51B) [abcdefgh], a = domination, b = neglect, 4 pairs for 4 players
V_DACT = $0970+BASE2 ;debate action blocks (7B*4) [ACTION, ISSUE, SEL. OPPONENT, SUCCESS, REACTION, R. ISSUE, R. SUCCESS]
V_DPCOUN = $098C+BASE2 ;debate penalty counts (4B)
V_DDP = $0990+BASE2 ;debate DP totals (4B)
V_DOPPON = $0994+BASE2 ;debate opponent list (3B)
V_DPOBSC = $0997+BASE2 ;debate penalty obscured flags (4B)
V_DDPQ = $099B+BASE2 ;debate question DP gain (4B)
V_DOTHER = $09A0+BASE2 ;debate others issue values (4B)
V_DPPREV = $09A4+BASE2 ;debate previous penalty flag (4B)
V_DSTATE = $09A8+BASE2 ;debate selected states (3B)
V_DPCURR = $09AB+BASE2 ;debate current penalty flags (4B)
V_DPCLOG = $09AF+BASE2 ;debate penalty count log (12B)
V_DNATL = $09CB+BASE2 ;debate total DP copy / nat'l bonus (4B)
V_DTOPIC = $09CF+BASE2 ;debate selected topics (3B)
V_DPHASE = $09D3+BASE2 ;debate phase (action/reaction)
V_DISS0 = $09D4+BASE2 ;debate issue 0
V_DISS1 = $09D5+BASE2 ;debate issue 1
V_DQUEST = $09D6+BASE2 ;debate question index
V_DISSUE = $09D7+BASE2 ;debate selected state issues + others (6B)
V_DQSTAT = $09DD+BASE2 ;debate question state
V_DCTV = $09DE+BASE2 ;debate current tv network
V_DPRVTV = $09DF+BASE2 ;debate previous tv network
V_DPCQAG = $09E0+BASE2 ;debate precalc question dp attacker (or passive) gain
V_DPCQDG = $09E1+BASE2 ;debate precalc question dp defender gain
V_DPERSNL = $09E2+BASE2 ;debate personal enabled
V_MARGINF = $09E3+BASE2 ;holds margin float (5B)
V_MAXHOLD = $09E8+BASE2 ;holds max2nd value + index (3B)
V_FIXEDPERC = $09EB+BASE2 ;temp for _FIXEDPERC
V_SCHEDC = $09EC+BASE2 ;holds schedule copy (8B)
V_SCHED = $09ED+BASE2 ;..
V_SCHEDVB = $09F4+BASE2 ;holds visit bonus by action (8B)
V_AUTOSTAFF = $09FC+BASE2 ;no staff out flag by player (4B)
V_STLOCK = $0A00+BASE2 ;per player -- locks 2 actions to schedule for one WEEK (4B)
V_RALLYDEATH = $0A04+BASE2 ;region death-on-RALLY by player (4B)
V_SCANDAL = $0A08+BASE2 ;scandal level by player (4B) -- 00 = none, 01 = minor, 10 = major (resign), 11 = major (death)
V_WARP = $0A0C+BASE2 ;travel cost waived flag (4B)
V_STAFFOUT = $0A10+BASE2 ;staff out flag
V_EVCDEAD = $0A11+BASE2 ;major scandal type: (0 = major, non-zero = dead)
V_CPFLOAT = $0A24+BASE2 ;25B float values (5 parties * 5B)
V_STRSTACK = $0A3D+BASE2 ;string stack (4B)
V_CPGPTRO = $0A41+BASE2 ; saves offset for V_CPGAIN (7B)
;;
V_4PREG = $0A72+BASE2 ;4p regional mode selected regions - 4B
V_AIPLUR = $0A80+BASE2 ;ai state-to-plurality list (128B)

BASE3 = $9000
VISSAVE = $0000+BASE3 ;VISIT selection save
V_AITVADS = $0001+BASE3 ;holds swing state / state lean / state control multiplier outcomes (3B)
V_ALLAI = $0004+BASE3 ;boolean if every player is AI
V_SWINGCT = $0005+BASE3 ;count of swing states on map
V_TRAVEL = $0006+BASE3 ;travel cost
V_TVWARN = $0007+BASE3 ;TV ADS half warning
V_COLOR = $0008+BASE3 ;draw with/without color
V_REDRW1 = $0009+BASE3 ;no-redraw for candidate menu
V_REDRW2 = $000A+BASE3 ;no-redraw for action menu
V_AI = $000B+BASE3 ;ai level for each player
V_FVAR = $000F+BASE3 ;5B FOR FVAR
V_MAXPL = $0014+BASE3 ;4 parties
V_GAMEOV = $0018+BASE3
V_OUTOFM = $0019+BASE3 ;Out of Money on start of turn
V_SUMFH = $001A+BASE3 ;Sum From History (if on)
V_WARN = $001B+BASE3 ;current action warning
V_PTCHR3 = $0020+BASE3 ;1420-143F - 3-CHAR PARTY
V_RNG = $0040+BASE3 ;1440-144F (16B)
V_SUMEC = $0056+BASE3 ;1456-145F (10B)
V_POPSUM = $0060+BASE3 ;popular sum by party - (12B)
V_NIBBLE = $006C+BASE3
SAVESEL = $0076+BASE3 ;save action menu select
SAVEMAP = $0077+BASE3 ;save current map state
SAVEAI = SAVEMAP ;saves AI level
MAP_ROW = $0078+BASE3
MAP_COL = $0079+BASE3
MAP_HELD = $007A+BASE3 ;held pixel
MAP_RES = $007B+BASE3 ;state selected on map
V_DEBON = $007C+BASE3 ;currently debating
S_PLAYER = $007D+BASE3 ;count
S_GMMODE = $007E+BASE3
S_SETTING = S_GMMODE ;all binary title settings
S_EQCER = $007F+BASE3
S_DEBTON = $0080+BASE3
S_EVENTS = $0081+BASE3 ;whether to do EVENTS
S_CUSTOM = $0082+BASE3
S_BLIND = $0083+BASE3
S_QUICKG = $0084+BASE3
V_WINNER = $0085+BASE3
S_PLAY1M = $0086+BASE3 ;player + 1
S_PLAY1L = $0087+BASE3 ;player - 1
S_3PMODE = $0088+BASE3 ;0 = IND, 1 = WOR
;S_4PMODE = $0089+BASE3 ;0 = EXTREMES, 1 = REGIONAL
V_FLOATMAX = $008A+BASE3 ;maximum party index for _FLOATMAX
V_MARGIN = $008B+BASE3 ;do margin for _PCTRL
V_PTCHAR = $008D+BASE3 ;6 PARTIES
V_PTCOL = $0093+BASE3 ;6 COLORS
C_SCHEDC = $009A+BASE3 ;count
C_SCHED = $009B+BASE3 ;7 actions
C_HEALTH = $00A2+BASE3
C_MONEY = $00A3+BASE3
C_VBONUS = $00A4+BASE3 ;Last Visit Action
C_IREG = $00A5+BASE3 ;;start of week (initial)
C_HOME = $00A6+BASE3
C_TITLE = $00A7+BASE3
C_CHAR = $00A8+BASE3
C_STAM = $00A9+BASE3
C_INTL = $00AA+BASE3
C_NETW = $00AB+BASE3
C_CORP = $00AC+BASE3
C_VP = $00AD+BASE3
C_CER = $00AE+BASE3
C_STR = $00AF+BASE3
C_FUND = $00B0+BASE3
C_TV = $00B1+BASE3
C_LMIN = $00B2+BASE3
C_ISSUES = $00B3+BASE3
C_CREG = $00B8+BASE3 ;currently processed
C_INCUMB = $00B9+BASE3
V_WEEK = $00BA+BASE3
V_PARTY = $00BB+BASE3
V_CPGPTR = $00BC+BASE3 ;precalc cp gain pointer
V_VBONUS = $00BD+BASE3
V_SPRPTR = $00BE+BASE3
GX_X = $00BF+BASE3
GX_Y = $00C0+BASE3
GX_XO = $00C1+BASE3
GX_XP = $00C2+BASE3
GX_XB = $00C3+BASE3
GX_YO = $00C4+BASE3
GX_UCOL = $00C5+BASE3
GX_PCOL = $00C6+BASE3
GX_RCOL = $00C7+BASE3
GX_LX1 = $00C8+BASE3
GX_LY1 = $00C9+BASE3
GX_LX2 = $00CA+BASE3
GX_LY2 = $00CB+BASE3
S_PCOLOR = $00CC+BASE3
S_MBLANK = $00CD+BASE3
S_EVENMAP = $00CE+BASE3
V_MUSTMR = $00CF+BASE3
V_SCRREG1 = $00D0+BASE3
V_MUSFLAG = $00D1+BASE3
V_MOE = $00D2+BASE3
V_POLLCT = $00D3+BASE3
V_PROFILE = $00D4+BASE3 ;candidate appearance - 4B
V_TVMAX = $00D8+BASE3 ;hard AI max TV ADS
V_AITOP = $00D9+BASE3 ;hard AI last top priority index (4B)
V_MAX1B = $00DD+BASE3 ;hold for a 1B V_MAX (4B)
V_LANDSLIDE = $00E1+BASE3 ;party index if a candidate won >= 1.5x the plurality amount
S_SKIPGAME = $00E2+BASE3 ;whether to skip the game or not (i.e. proceed to results immediately)
V_EVENTS = $00E3+BASE3 ;this week's events (4B) / their targeted states (4B)
V_EVENTC = $00EB+BASE3 ;this week's event count
V_EVBIG = $00EC+BASE3 ;the week when a major event occurs
V_EVBIGR = $00ED+BASE3 ;the major event's region (if applicable)
V_IBONUS = $00EE+BASE3 ;issue bonus sum
V_POLL = $00EF+BASE3 ;poll count by region - 9B
V_POLDIV = $00F8+BASE3 ;poll count for region (temp)
V_STRWAIT = $00F9+BASE3 ;string draw delay
V_MAXPLI = $00FA+BASE3 ;V_MAXPL index
V_PLURAL = $00FB+BASE3 ;floor(EC / player count) (2B)
S_PARTISAN = $00FD+BASE3 ;PARTISAN setting (0 = high, 1 = medium, 2 = low)
V_FPNCHK = $00FE+BASE3 ;hold value for _FPNCHK
V_POPWIN = $00FF+BASE3 ;winner of the popular vote (party index)

V_HIST = $0100+BASE3
V_SCHIST = $0F00+BASE3
BASE4 = $A000

;ZEROPAGE 
LOWSTATE = $03
HIGHSTATE = $04

FVAR7 = $0C

MAXLOW = $10 ;max return value Lower
MAXHIGH = $11 ;max return value Upper

MAXVAR2 = $14
MAXVAR3 = $15

STR2FAC1 = $22
STR2FAC2 = $23

MAXVAR1 = $2A
BITRET = $2B
BITSTA = $2C
;SFX_DUR = $30
;SFX_FRQ = $31
;SFX_VAR = $32

CPSTATE = $3A ;state index for _CP functions

;graphics zp
GX_STLB = $40
GX_STUB = $41
GX_CROW = $42
GX_CCOL = $43
GX_CIND = $44
GX_VARX = $45
GX_VARY = $46
GX_VARI = $47
GX_VARI2 = $48
GX_BCOL = $49 ;background color
GX_DCOL = $4A ;draw color (char/str)
;string counting
GX_STRC = $4B
GX_SCOL = $4C
GX_SREP = $4D
GX_SHLD = $4E
GX_REG = $4F ;region to print from special code

;map counting
MAP_ADR1 = $50
MAP_ADR2 = $51
MAP_STAT = $52
GX_FORM1 = $53 ;string formatting
GX_FORM2 = $54
FVAR6 = $55

RNG1 = $5E
RNG2 = $5F

FAC = $61
ARG = $69

TIMER = $A2

FPARTY = $B0
DPARTY = $B1 ;temp for debates

FSUS1 = $D1 ;signed to unsigned
FSUS2 = $D2
FVAR1 = $D3
FVAR2 = $D4
FVAR3 = $D5
FVAR4 = $D6
FVAR5 = $D7
FARG1 = $D8
FARG2 = $D9
FARG3 = $DA
FARG4 = $DB
FARG5 = $DC

;function-local ZP
FSTATE = $E0 ;US state iterator
FAI = $E1 ;AI list index
EVCI = FAI ;EVC index
FAIMUL = $E2 ;AI multiplier
EVCCOST = FAIMUL ;EVC event cost
FAIPRI = $E3 ;hard AI current priority comparison (3/2/1/0)
FAISUM = $E4 ;AI priority sum (2B)
FAITV = $E5 ;AI TV ADS cap
FAIPTR = $E6

FRET1 = $EB
FRET2 = $EC
FRET3 = $ED
FX1 = $EE ;for calls
FY1 = $EF ;..

OFFSET2 = $F0
HS_ADDR = $F2 ;F6-F7 (history)
IS_ADDR = $FA
CP_ADDR = $FC ;FC-FD (campaign points)
OFFSET = $FE ;FE-FF (general offset)

;graphics constants
C_BLACK = $00
C_DRED = $02
C_DBLUE = $06
C_VIOLET = $04
C_DGREEN = $05
C_DGRAY = $0B
C_BLUE = $0E
C_LBLUE = $03
C_BROWN = $09
C_ORANGE = $08
C_LGRAY = $0F
C_PINK = $0A
C_GREEN = $05
C_YELLOW = $07
C_LGREEN = $0D
C_WHITE = $01

CHARLEN = $08

PUNCS = $20
ASTERISK = $2A
PLUS = $2B
MINUS = $2D
FILLCHR = $2F
NUMBERS = $30
ALPHAS = $40
PENCHAR = $60
BACKCHAR = $70

PLAYERCHAR2 = $F8 ;draws party in DPARTY
ISSUECHAR = $F9 ;draws issue index in GX_REG
PARTYCHAR = $FA ;draws party in V_PARTY
STATECHAR = $FB ;draws state in FSTATE
REGCHAR = $FC ;draws region in GX_REG
PLAYERCHAR = $FD ;draws player index from V_PARTY
REPCHAR = $FE
NEWLINE = $FF

VK_FIRE = $00
VK_UP = $01
VK_LEFT = $02
VK_DOWN = $03
VK_RIGHT = $04
VK_FASTF = $05

VK_RET = $0D
VK_BACK = $14
VK_SPACE = $20
VK_DOLLAR = $24
VK_PERC = $25
VK_DEC = $2E

;campaign 2024 constants
UND_PRTY = $04
STATE_C = $34
REGION_C = $09
PRIMC1L = $07
PRIMARYC = $08
PRIMDATC = $11
NAMELEN = $0A
CANDDATA = $20
CPBLEAN = $04
CPBLOCK = $08
HISTBLOCK = $07
DBLOGBLOCK = $07
FLOATLEN = $05
PERCLEN = $05
AISTATE = $3B
;AISURVLEN = $06
AIPLURLEN = $20
PLAYERMAX = $04
ACTIONMAX = $07
ACTIONREST = $00
ACTIONFUND = $FF
WEEKMAX = $09
EVENTMAX = $04
EVENT_C = $0B
EVENT_MAJOR = $05
EV_WEATHER = $01
EV_ISSUE = $02
EV_FAIR = $03
EV_TVADS = $04
EV_COMMS = $05
EV_ANARCHY = $09
EV_POWER = $0A
EV_PANDEMIC = $0B
EV_TERROR = $0C

EVCAND_C = $0D
EVC_SCANDAL_NONE = $00
EVC_SCANDAL_MINOR = $01
EVC_SCANDAL_MAJOR = $02
EVC_SCANDAL_DEATH = $03

ISSUEC = $05
ISSUEMAX = $07 ;maximum normal issue value
ISSUEX = $08
ISSUEN = $09
SETTINGC = $07
MAP_ROWC = $0F
MAP_COLC = $19
STAFF_COST = $0A
HQ_COST = $05
AI_MAX = $03
CPGAIN_MAX = $4F

ACT_VISIT = $00
ACT_TVADS = $01
ACT_FUNDR = $02
ACT_REST = $03

AIEASY = $01
AIHARD1 = $02
AIHARD2 = $03

DBPIVOT = $00
DBANSWER = $01
DBCHALL = $02
DBALLY = $03
DBDIFFER = $04
DBMORAL = $05
DBPERSNL = $06
DBREST = $07
DBSURVEY = $08

DBACCR = $00
DBPIVR = $01
DBCNTR = $02

DBPIS = $01
DBPIF = $00
DBPIF2 = $FF 
DBANS = $02
DBANF = $FE
DBCHS = $04
DBCHF = $FE
DBCHF2 = $FC
DBALDS = $04
DBALDF = $FE
DBALAS = $04
DBALAF = $01
DBRES = $FE
DBACDS = $FE
DBACDF = $FA
DBACAS = $06
DBPIDS = $00
DBPIDF = $FD
DBPIAS = $08
DBCOAS = $08
DBCOAF = $FC
DBCODS = $04
DBCODF = $FC


;positional 
P_TOP = $00
P_LEFT = P_TOP
P_RIGHT = $28
P_BOTTOM = $19
P_RSELC = $1F
P_RSELC2 = $1E

P_STAFFR = $18
P_STAFR2 = $18
P_STAFFC = $1E
P_AILVLR = $16
P_AILVLC = $17
P_MENBLR = $14
P_MENBRC = P_LEFT
P_POSTLR = $11
P_POSTLR2 = $14
P_POSTLC = $01
P_MONEYR = $12
P_MONEYC = $01
P_VBONSR = $13
P_VBONSC = $01
P_ISSUER = P_MENBLR
P_ISSUEC = $15
P_PRIMR = P_MENBLR
P_PRIMC = $05

P_SECNDR = P_MENBLR
P_SECNDC = $0C
P_REGTPR = $03
P_REGTPC = P_RSELC2
P_REGLSR = $06
P_REGLSC = P_RSELC2
P_REGLSC2 = P_REGLSC+3
P_REGLSR2 = $03
P_REGLSR3 = $0C
P_MENURR = P_TOP
P_MENURC = P_RSELC2
P_MENUR2 = $03
P_MENUR3 = $04
P_WEEKR = $01
P_WEEKC = P_RSELC2
P_TITL2R = $12
P_TITL2C = $06
P_SETTR = $05
P_SETTR2 = $0E
P_INCUMR = $10
P_INCUMC = P_RSELC
P_AIMENR = $10
P_AIMENC = P_RSELC2
P_SCHEDR = $11
P_SCHEDC = $1D
P_ENDPOR = $11
P_ENDPOC = $04
P_ENDP2R = $12
P_ENDP2C = $04
P_ENDP22 = $05
P_COLORR = $10
P_COLOR2 = $11
P_SCH2R = $10
P_SCH2C = P_RSELC
P_WARNC = $27
P_DETSTR = $02
P_DETLHR = $04
P_DETLR = $05
P_POLLR = $11
P_POLLC = P_LEFT
P_WINPTR = P_REGLSR
P_WINPTC = P_RSELC-1
P_PTTLC = $04
P_HEALC = $08
P_HEAL2C = $0F
P_VBON2C = $0E
P_VPSTAR = $17
P_VPSTAC = $17
P_WEEK2C = $25
P_WINC = $05
P_POLL2 = $01
P_PNAMER = $11
P_PNAMEC = P_RSELC2
P_CONVNR = $12
P_CONVNC = P_RSELC2
P_NOYESR = $14
P_NOYESC = P_RSELC
P_VISITR = $05
P_VISITC = P_RSELC2
P_TITLEC = P_RSELC2
P_ENDMNR = $11
P_ENDMNC = P_RSELC
P_PARTISANR = P_ENDMNR
P_PARTISANC = P_RSELC
P_MAPINFC = $05
P_FTCC = $05
P_BL2 = $1D

P_PLAYNR = $11
P_PLAYNC = $08
P_RSEL2C = $0C
P_FTCC2 = $1C
P_TITL2R2 = $14
P_TITL2R3 = $18
P_POLLC2 = $02
P_MENUR4 = $0E
P_RATINGR = $13
P_RATINGC = P_LEFT
P_RATING2R = $11
P_RATING2C = P_LEFT

P_DINTRR = $03
P_DINTRC = $04
P_DINTVR = $0A
P_DINTVC = $04
P_DINCTR = $06
P_DINCTC = $04
P_DBQR = $03
P_DBQC = $05
P_DBQNC = $0E
P_DBQTC = $10
P_DBQPR = $05
P_DBQPC = P_DBQC
P_DTOPR = $08
P_DTOPC = P_DBQC
P_MAPR = $01
P_MAPC = $04
P_MAP2R = $10
P_MAP2C = $1D
P_DAMR = P_TOP
P_DAMR2 = $07
P_DAMR3 = $0F
P_DAMC = $1E
P_DSMR = $11
P_DSMC = P_RSELC
P_DIMR1 = P_DSMR
P_DIMR2 = $12
P_DIMR3 = $17
P_DIMC = P_RSELC
P_DOPPR1 = P_DSMR
P_DOPPR2 = $12
P_DOPPC = P_RSELC
P_DCONFR = $0C
P_DCONFC = P_EVENTC
P_DSTATR = $05
P_DSTATC = P_RSELC2
P_DPLYRR = $01
P_DPLYRC = P_RSELC2
P_UPNEXR = $01
P_UPNEXC = P_RSELC2
P_REACTR = $0C
P_REACTC = $05
P_DATTR = $05
P_DATTC = P_RSELC2
P_DATTOR = $01
P_DATTOC = P_RSELC2
P_DATTAR = $06
P_DATTAC = P_RSELC2
P_DRMENR = $08
P_DRMEN2 = $0A
P_DQAR = $03
P_DQAC = $05
P_DQRR = $07
P_DQRC = P_DQAC
P_DRMENC = P_RSELC2
P_DMRX1 = $1E
P_DMRX2 = P_RIGHT
P_DMRY1 = P_TOP
P_DMRY2 = $10
P_DLOGMR = P_DSMR
P_DLOGMC = P_RSELC
P_DLOGMR2 = P_DSMR+1
P_DLOGMR3 = P_DSMR+2
P_DQAPR = P_DQAR
P_DQAPC = P_DQAC
P_DQF0R = $04
P_DQF0C = $05
P_DQF2R = $04
P_DQF2C = $15
P_DQF4R = $04
P_DQF4C = $05
P_DQF4S = $04
P_DQF4D = $12
P_DQF5R = $04
P_DQF5C = $05
P_DQF5S = $05
P_DQF5D = $17
P_DQF6R = $05
P_DQF6C = $05
P_DQF7R = $08
P_DQF7C = $05
P_DQRPR = P_DQRR
P_DQRPC = $05
P_DAUDC = $05
P_DFINR = $02
P_DFINR2 = $07
P_DFINR3 = $08
P_DFINC = $05
P_DFINC2 = $0F
P_DLOGOR = $02
P_DLOGOC = $05
P_DLOGPR = P_DLOGOR
P_DLOGPC = P_DLOGOC
P_DLOGNR = $03
P_DLOGNC = $10
P_DLOGTR = $05
P_DLOGTC = $07
P_DLOGAC = $05
P_DLOGAR = $0A
P_DLOGA2 = $09
P_DLOGA3 = $12
P_DLOGA4 = $07
P_DLOGA5 = $12
P_CPROFR = $12
P_CPROFC = $19
P_CPRBOXR = $11
P_CPRBOXC = $17
P_SURVEYR = $0B
P_SURVEYC = $20
P_SURVEYC2 = P_RIGHT-1
P_ACTLOGC = $1D

P_EVENTR = $02
P_EVENTC = $05
P_EVCCOSTR = $0D
P_EVCCOSTC = P_EVENTC

*= START
!hex 0C080A009E3234323000000000000000000000
!binary "source/DATASPREMPTY.dat" 

!source "source/CGAME.asm" 
!source "source/CSCHED.asm" 
!source "source/CDEBATE1.asm"
!source "source/CDRAW.asm" 
!source "source/CGFX.asm"
!source "source/CMARGIN.asm" 
!source "source/CUTIL.asm" 
!source "source/CMAP.asm" 
!source "source/CCAND.asm"

_NEWCHARSET

NEWCHAR = $3800
DATA2024 = $3B00 ;separation between character set

SPACE1 = NEWCHAR - _NEWCHARSET
!if SPACE1 < 0 {
	!error "code partition 1 exceeds character set partition"
}


*= DATA2024
;!pseudopc DATA2024 {
;short text files

!source "source/CCALC.asm" 
!source "source/CDEBATE2.asm" 
!source "source/CSFX.asm"
!source "source/CAI.asm"
!source "source/CEVENTS.asm"
!source "source/CMUSIC.asm"
!source "source/CC64.asm" 
 
T_BLANKX !hex 6070FE200B00 ;t_blankx: its repeat count is variable (edited during gameplay)
T_FTC !hex 6F2A4D204F5220535041434520544F20434F4E4649524D2A00
T_SCHED !hex 53FF4DFF54FF57FF54FF46FF5300
;T_TITLE2 !hex 60 41 61 42 62 43 63 44 64 45 65 46 66 47 67 48 68 49 69 4A 6A 4B 6B 4C 6C 4D 6D 4E 6E 4F 6F 00 ;color test
T_TITLE2 !hex 6F43414D504149474E204D414E4147455220643230323400
T_99PC !hex 39392E393900
T_00PC !hex 30302E303100
;T_BLANK3 !hex 6070FE200300
T_MONEY !hex 6C243A2000
T_HEALTH !hex 4845414C54483A6AFE2D0800
T_CONVEN !hex FE290AFF70434F4E56454E54494F4E00
T_NOYES !hex 6F4E4FFF59455300
T_BANNER !hex FE290AFFFFFE290A00
T_WEEK !hex 6F5745454B202000
T_VISIT !hex 6F20714D454E55FE20057000
T_REST !hex 6FFE5A0400
T_TVADS !hex 6E54562041445300
T_FUNDR !hex 6746554E445241495300
T_BONUS !hex 6F52414C4C5920424F4E55533A2020202000
T_STAFF !hex 6F53544146463A00
T_STAFFG !hex 6E474F4F4400
T_STAFFO !hex 6B4F55542000
T_TIE !hex 6F544945FE200500
T_HIST !hex 6F484953544F525900
T_WINPOP !hex 504F50554C415220564F54453A00
T_WINBY !hex 57494E532042593A00
T_T2 !hex 61FE2F286fFFFE2F28FF62FE2F28FFFE292800
T_MOE !hex 4D4F45FF00
T_PROFILE !hex 6F201C1C1CFF1F2020201EFF1F2020201EFF1F2020201EFF203B3B3B00
T_GMPARTY !hex 5041525449455300
T_GMRAND !hex 52414E444F4D2000
T_HQ !hex 48513A00
T_TRAVEL !hex 206F714D454E55FE2004FFFE2009FFFE200900

T_QUEST !hex 5155455354494F4E20202000
T_BACK !hex 6F4241434B00
T_STATP !hex 6B424C554E44455200
T_STATOK !hex 6E46494E4500
T_STATTR !hex 6D54524F55424C4500
T_UPNEXT !hex 6F5550204E4558543A2000
T_REPLY !hex 6F5052455041524520594F5552205245504C49455300
T_ATTACK !hex 6F41545441434B455200
T_DLOGM !hex 6F56494557204C4F4753FF2020594553FF20204E4F00
T_UNFAV !hex 43414E44494441544520202B2520202D25204E41544C00
T_AILEVEL !hex 41493A2000
T_EVINIT !hex 544845204E45575320464F52205745454B20303A00
T_EVNONE !hex 4E4F204E45575320495320474F4F44204E45575300
T_3PARTY !hex 6F33502050415254593F00
T_DETAILED !hex 6F4D415247494E00
T_VP !hex 6F43484F4F5345205650FF53544154453A00
T_VPSTA !hex 6F56503A00
T_OTHER !hex 674F544845522000
;T_EVENMAP !hex 4556454E204D415028302D39293F203000
T_EVENTC !hex 6D2A5350454349414C204E45575320414C455254212A00
T_EVENTC2 !hex 6D54484520534954554154494F4E3A00
T_EVENTC3 !hex 6D594F5552FF524553504F4E53453A00
T_ISSUESTR !hex 6F495353554520535452454E4754483A00

;large text files
T_TITLE !binary "source/TEXTTITLEMENU3.dat"
T_MENUBL !binary "source/TEXTMENUBL.dat" 
T_POSTAL !binary "source/TEXTPOSTAL.dat" 
T_MENUR !binary "source/TEXTRIGHTMENU.dat"
T_PARTISAN !binary "source/TEXTPARTISAN.DAT"
T_MENURLEN = T_PARTISAN - T_MENUR
T_REGION !binary "source/TEXTREGIONS2.dat"
T_ENDMNU !binary "source/TEXTENDMENU.dat" 
T_INCUMB !binary "source/TEXTINCUMBENT.dat" 
T_AI !binary "source/TEXTAIMENU.dat" 
T_WIN !binary "source/TEXTWINCRIT.dat" 
D_CANDID !binary "source/TEXTCTITLES.dat" 
T_DINTRO !binary "source/TEXTDEB1.dat" 
T_DTOPIC !binary "source/TEXTDEB2.dat" 
T_DQUEST !binary "source/TEXTDEB3.dat" 
T_DAMENU !binary "source/TEXTDEB4.dat"  
T_DRMENU !binary "source/TEXTDEB5.dat" 
T_DRESLT !binary "source/TEXTDEB6.dat"
T_ISSUES !binary "source/TEXTDEB7.dat" 
T_DCONF !binary "source/TEXTDEB8.dat" 
T_DAUDI !binary "source/TEXTDEB9.dat"
T_DNCONF = T_DCONF+18
T_DFINAL !binary "source/TEXTDEB10.dat"
T_DLOG !binary "source/TEXTDEB11.dat"
T_EVENTS !binary "source/TEXTEVENTS.dat"
T_RATINGS !binary "source/TEXTRATINGS.dat"
T_RATINGS2 !hex 504F4C4C5354455220524154494E47533A00
D_DRESLT !hex 001835556B829FC5D000EA ;offset table for debate action/reaction text (note PIVOT is used twice)
D_DACODE !hex 171F28343C45505A
D_DBACT !byte %00010000,%11011000,%10011000,%11111100,%10010100,%11011100,%01011000 ;debate action requirement bits: [CS, IC, OIC, CS mismatch penalty flag, IC..flag, OIC..flag, unused, unused] covers PIVOT through MORALIZE, and REACTION PIVOT is the last entry
D_DPPGAIN !hex FF01 FC05 FD03 ;DP gain by passive action [failure, success]
D_DPOGAIN !hex 06FA06FE 08FA0500 08FCFC04 FE010505 ;DP gain by offensive reaction (and ALLY) [successful attacker gain, failed defender gain, failed attacker gain, successful defender gain]
D_TIES !16 _TIESL, _TIEHQ, _TIEISSUE, _TIEPOP, _TIECOIN

T_EVCCEO !binary "source/TEXTEVC_CEO.dat"
T_EVCCHILD !binary "source/TEXTEVC_CHILD.dat"
T_EVCDICT !binary "source/TEXTEVC_DICTATOR.dat"
T_EVCDIRT !binary "source/TEXTEVC_DIRT.dat"
T_EVCXTRME !binary "source/TEXTEVC_EXTREME.dat"
T_EVCFBI !binary "source/TEXTEVC_FBI.dat"
T_EVCGLOW !binary "source/TEXTEVC_GLOWUP.dat"
T_EVCIVAN !binary "source/TEXTEVC_IVAN.dat"
T_EVCLOCK !binary "source/TEXTEVC_LOCK.dat"
T_EVCRESIGN !binary "source/TEXTEVC_MAJOR1.dat"
T_EVCDIE !binary "source/TEXTEVC_MAJOR2.dat"
T_EVCCONTIN !binary "source/TEXTEVC_MAJOR3.dat"
T_EVCMINOR !binary "source/TEXTEVC_MINOR.dat"
T_EVCPILL !binary "source/TEXTEVC_PILL.dat"
T_EVCREAL !binary "source/TEXTEVC_REALEST.dat"
T_EVCSTAFF !binary "source/TEXTEVC_STAFF.dat"
T_EVCVP !binary "source/TEXTEVC_VP.dat"
T_EVCWARP !binary "source/TEXTEVC_WARP.dat"
T_REDBLUE !hex 61524544FF62424C554500

;determines the index of the actual candidate event
T_EVC !16 T_EVCMINOR,T_EVCRESIGN,T_EVCCEO,T_EVCCHILD,T_EVCDICT,T_EVCDIRT,T_EVCXTRME,T_EVCFBI,T_EVCGLOW,T_EVCIVAN,T_EVCLOCK,T_EVCPILL,T_EVCREAL,T_EVCSTAFF,T_EVCVP,T_EVCWARP,T_EVCDIE,T_EVCCONTIN
D_EVC !16 _EVCMINOR, _EVCMAJOR, _EVCCEO, _EVCCHILD, _EVCDICT, _EVCDIRT, _EVCXTRME, _EVCFBI, _EVCGLOW, _EVCIVAN, _EVCLOCK, _EVCPILL, _EVCREAL, _EVCSTAFF, _EVCVP, _EVCWARP

;continual use
D_MAPSHP !binary "source/DATAMAPSHAPE.dat" 
D_MAPCHR !binary "source/DATAMAPCHAR.dat"
D_TVCORP !hex 05060808060300FF
D_REGLIM !hex 01070A0F161F23272F34
D_REGC !hex 060305070904040805
FVALUE1 !hex 8000000000
D_INCCER !hex 0006030201FFFD
D_INCFND !hex 0004020100FFFE
;D_AI_NP !hex 0100FC
;D_AI_NUN !hex 0003
D_AI_CTRL !hex FC0102
D_AI_EC !hex FD00
;D_AI_CD !hex FC0001
D_AI_LEAN !hex FBFE00
D_AI_SWING !hex FF0102
D_AITVADS !hex FF0302010303 ;CTRL table (self/opp/und) 1 ; CTRL table 2
;D_DRWT2C !hex 09060F06
D_MEGAST !hex 071E2631 ;NY/FL/TX/CA
MEGASTAC = $04
D_MEDSTA !hex 08090A0C0D191B1D2F
MEDSTAC = $09
D_TV2REG !hex 030805040607010209
D_ECHANCE !hex 102030405054585C ;5E6062 6466686A6C
D_EADDR !16 _EREGION,_ESTATE,_ESTATE,_EREGION,_ESTATE,_ESRIGHT,_ESLEFT,_ESCENTER,_EANARCHY,_ETV,_EVISIT,_ETERROR,_EIMMIGRAT
;D_EDRAW !hex 1221233344431101 ;event's draw type (half-bytes)
D_UND !hex 0A1014
D_CPLEVEL !hex 80C0E0F000
D_ISSTBL !hex 020406080B
D_ISSCOL !hex 020A0C0D05

D_C64COL !hex 00 02 06 04 05 0B 06 0E 09 08 0F 0A 05 07 0D 01
T_DEBNET !hex 63434E4E0061464F58006250425300
T_DEBNUM !hex 673153540067324E4400
D_DTOPIC !binary "source/DATATOPICISS.dat" 
D_DBAUDI !hex 0F191F
D_DRCODE !hex 020B12
D_HAIR !hex 20848588898a8b8c
;D_4PREG !hex 0102040806070909 ;regions for 4p regional parties
;D_4PREGL !hex 0709 ;leans for REGIONAL mode (non-home region lean, home region lean)
;D_JOYSTICK !hex 494B4A4C4D
D_FLOATCAP !hex 7AA3D70A00 ;00.01, where floating point numbers in C64 get formatted with scientific notation
D_FLOATMAX !hex 87C8000000 ;100, the maximum floating point value
;KEYROW !byte $fe,$fd,$fb,$f7,$ef,$df,$bf,$7f
;KEYCOL !byte $01,$02,$04,$08,$10,$20,$40,$80		
HISTV !byte $00

;one-time (copied) 
D_EXCHAR !binary "source/DATAEXTRACHAR.dat" 
D_SPRITE !binary "source/DATASPRITE.dat" 
D_PTCOL2 !hex 060207050C0408
T_PLAYER !hex 504C4159455220202000

V_POPVOTE = D_EXCHAR ;popular vote in plaintext (20B)
V_REGISS = D_EXCHAR+20 ;issue bonus by region for a candidate (9B)
V_DEADHOLD = D_EXCHAR+29 ;var hold for dead player (3B)

_DATAEND
DATASIZE = _DATAEND-DATA2024
;music files must be compiled with respective addresses separately using GoatTracker (F9 to compile)
MUSIC = $7A00
*= MUSIC

SPACE2 = MUSIC - _DATAEND
!if SPACE2 < 0 {
	!error "code partition 2 exceeds music partition"
}

D_MUSIC !binary "source/song_base.dat" ;the common part of a music .bin file exported by GoatTracker
_MUSICBASE
!fill 256,$00
D_MUSD !binary "source/song_dem.dat" ;individual pieces
D_MUSR !binary "source/song_rep.dat"
D_MUSP !binary "source/song_pat.dat"
D_MUSS !binary "source/song_soc.dat"
D_MUSI !binary "source/song_ind.dat"
_MUSICSIZE
!16 D_MUSR-D_MUSD
!16 D_MUSP-D_MUSR
!16 D_MUSS-D_MUSP
!16 D_MUSI-D_MUSS
!16 _MUSICSIZE-D_MUSI
;one-time data (ctd.)
D_PARTY !binary "source/TEXTPNAME.dat" 
WOR3 = D_PARTY+65
IND3 = D_PARTY+54
PAT3 = D_PARTY+21
D_EC !binary "source/DATAECOLLEGE.dat"
D_INITCP !binary "source/DATAINITCP.dat"
D_ISSUE !binary "source/DATAISSUES.dat"

_MUSICEND
_MUSICTOTAL = _MUSICEND - MUSIC

SPACE3 = BASE2 - _MUSICEND
!if SPACE3 < 0 {
	!error "music partition exceeds variable partition"
}
!16 (_MUSICEND - D_INITCP + 2)

TOTALSPACE = SPACE1+SPACE2+SPACE3