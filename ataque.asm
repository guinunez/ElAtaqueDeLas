  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; EL ATAQUE DE LAS BURBUJAS DEL ESPACIO EXTERIOR   ;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; DECLARACION DE VARIABLES
  .rsset $0000  ;;start variables at ram location 0
  
gamestate  .rs 1  ; .rs 1 means reserve one byte of space
player1x  .rs 1  ; player 1 horizontal position
player2x  .rs 1  ; player 2 horizontal position
player1y  .rs 1  ; player 1 vertical position
player2y  .rs 1  ; player 2 vertical position
buttons1   .rs 1  ; player 1 gamepad buttons, one bit per button
buttons2   .rs 1  ; player 2 gamepad buttons, one bit per button
score1     .rs 1  ; player 1 score
score2     .rs 1  ; player 2 score
player1speed .rs 1  ; player 1 speed per frame
player2speed .rs 1  ; player 2 speed per frame


;; DECLARACION DE CONSTANTES
STATETITLE     = $00  ; mostrando pantalla de inicio
STATEPLAYING   = $01  ; mover las naves y enemigos, verificar colisiones
STATEGAMEOVER  = $02  ; mostrar pantalla de game over
  
RIGHTWALL      = $F4  ; Limites de pantalla
TOPWALL        = $20
BOTTOMWALL     = $E0
LEFTWALL       = $04
  
PLAYER1XINICIAL = $20  ; posicion inicial jugador 1
PLAYER2XINICIAL = $F8  ; posicion inicial jugador 2
PLAYER1YINICIAL = $80
PLAYER2YINICIAL = $80

PLAYERVELOCIDADINICIAL = $02  ; velocidad inicial de los jugadores

;;;;;;;;;;;;;;;;;;


  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2


LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $10, decimal 16 - copying 16 bytes = 4 sprites
  BNE LoadPalettesLoop  ; Branch to LoadPalettesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down


LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down
              
              


;;;Inicializacion de valores
Initialize:
  LDA #PLAYER1XINICIAL
  STA player1x
  
  LDA #PLAYER2XINICIAL
  STA player2x

  LDA #PLAYER1YINICIAL
  STA player1y

  LDA #PLAYER2YINICIAL
  STA player2y
  
  LDA #PLAYERVELOCIDADINICIAL
  STA player1speed
  STA player2speed


;; Estado inicial del juego, no olvidarse de cambiar a STATETITLE
  LDA #STATEPLAYING
  STA gamestate


              
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop, waiting for NMI
  
 

NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

  JSR DrawScore

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
    
  ;;;all graphics updates done by here, run game engine


  JSR ReadController1  ;;get the current button data for player 1
  JSR ReadController2  ;;get the current button data for player 2
  
GameEngine:  
  LDA gamestate
  CMP #STATETITLE
  BEQ EngineTitle    ;;game is displaying title screen
    
  LDA gamestate
  CMP #STATEGAMEOVER
  BEQ EngineGameOver  ;;game is displaying ending screen
  
  LDA gamestate
  CMP #STATEPLAYING
  BEQ EnginePlaying   ;;game is playing
GameEngineDone:  
  
  JSR UpdateSprites  ;;set ball/paddle sprites from positions

  RTI             ; return from interrupt
 
;;;;;;;;
 
EngineTitle:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load game screen
  ;;  set starting paddle/ball position
  ;;  go to Playing State
  ;;  turn screen on
  JMP GameEngineDone

;;;;;;;;; 
 
EngineGameOver:
  ;;if start button pressed
  ;;  turn screen off
  ;;  load title screen
  ;;  go to Title State
  ;;  turn screen on 
  JMP GameEngineDone
 
;;;;;;;;;;;
 
EnginePlaying:

MovePlayer1Up:
  ;;if up button pressed
  LDA buttons1
  AND #%00001000
  BEQ MovePlayer1UpDone

  LDA player1y
  SEC
  SBC player1speed
  STA player1y
  
  JMP MovePlayer1UpDone

MovePlayer1UpDone:
  
MovePlayer1Down:
  ;;if down button pressed
  LDA buttons1
  AND #%000000100
  BEQ MovePlayer1DownDone

  LDA player1y
  CLC
  ADC player1speed
  STA player1y
  
  JMP MovePlayer1DownDone

MovePlayer1DownDone:

MovePlayer1Left:
  ;;if left button pressed
  LDA buttons1
  AND #%00000010
  BEQ MovePlayer1LeftDone

  LDA player1x
  SEC
  SBC player1speed
  STA player1x
  
  JMP MovePlayer1LeftDone

MovePlayer1LeftDone:

MovePlayer1Right:
  ;;if right button pressed
  LDA buttons1
  AND #%00000001
  BEQ MovePlayer1RightDone

  LDA player1x
  CLC
  ADC player1speed
  STA player1x
  
  JMP MovePlayer1RightDone

MovePlayer1RightDone:
  
CheckPlayer1Collision:
  ;; vamos a tener que recorrer un listado de enemigos
  ;; si alguno colisiona con player1


  JMP GameEngineDone
 

UpdateSprites:
  LDA player1y  ;;update all sprite info
  STA $0200

  LDA player1x
  STA $0203
  
  RTS
 
 
DrawScore:
  ;;draw score on screen using background tiles
  ;;or using many sprites
  RTS
 
 
 
ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL buttons1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS
  
ReadController2:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController2Loop:
  LDA $4017
  LSR A            ; bit0 -> Carry
  ROL buttons2     ; bit0 <- Carry
  DEX
  BNE ReadController2Loop
  RTS  
  
  
    
        
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;;background palette
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette

sprites:
     ;vert tile attr horiz
  .db $80, $00, $00, $80   ;sprite 0
  .db $80, $01, $00, $88   ;sprite 1
  .db $88, $10, $00, $80   ;sprite 2
  .db $88, $11, $00, $88   ;sprite 3



  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "naveggj.chr"   ;includes 8KB graphics file from SMB1
