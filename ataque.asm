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
frameActualFuego .rs 1  ; frame actual de la animacion de fuego

;; RESERVAR ESPACIO PARA LAS VARIABLES DE SONIDO
isShootPlaying        .rs 1
isExplosionPlaying    .rs 1

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

PLAYERVELOCIDADINICIAL = $01  ; velocidad inicial de los jugadores

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


LoadJugadorSprites:
  LDX #$00              ; start at 0
LoadJugadorSpritesLoop:
  LDA jugadorSprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $20, decimal 16
  BNE LoadJugadorSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down


;; Vamos a tener 4 enemigos en pantalla
LoadEnemigoSprites1:
  LDX #$00              ; start at 0
  LDY #$10
LoadEnemigoSpritesLoop1:
  LDA enemigoSprites, x        ; load data from address (sprites +  x)
  STA $0200, y          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  INY                   ; Y = Y + 1
  CPX #$10              ; Compare X to hex $20, decimal 16
  BNE LoadEnemigoSpritesLoop1   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadEnemigoSprites2:
  LDX #$00              ; start at 0
  LDY #$20
LoadEnemigoSpritesLoop2:
  LDA enemigoSprites, x        ; load data from address (sprites +  x)
  STA $0200, y          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  INY                   ; Y = Y + 1
  CPX #$10              ; Compare X to hex $20, decimal 16
  BNE LoadEnemigoSpritesLoop2   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadEnemigoSprites3:
  LDX #$00              ; start at 0
  LDY #$30
LoadEnemigoSpritesLoop3:
  LDA enemigoSprites, x        ; load data from address (sprites +  x)
  STA $0200, y          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  INY                   ; Y = Y + 1
  CPX #$10              ; Compare X to hex $20, decimal 16
  BNE LoadEnemigoSpritesLoop3   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadEnemigoSprites4:
  LDX #$00              ; start at 0
  LDY #$40
LoadEnemigoSpritesLoop4:
  LDA enemigoSprites, x        ; load data from address (sprites +  x)
  STA $0200, y          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  INY                   ; Y = Y + 1
  CPX #$10              ; Compare X to hex $20, decimal 16
  BNE LoadEnemigoSpritesLoop4   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
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

  LDA #$00
  STA frameActualFuego


;; Estado inicial del juego, no olvidarse de cambiar a STATETITLE
  LDA #STATEPLAYING
  STA gamestate

  ;; Sonido
  LDA #$00
  STA isShootPlaying
  STA isExplosionPlaying

  ;; Habilitar canales de sonido
  lda #%00001111
  sta $4015 ; enable Square 1, Square 2 y Noise

  ;; NMI
  LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000

  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

Forever:
  JSR SoundEngine
  JMP Forever     ;jump back to Forever, infinite loop, waiting for NMI

;; Motor de sonido
SoundEngine:
  LDA #$FF
  CMP isShootPlaying
  BEQ shootSound

  LDA #$FF
  CMP isExplosionPlaying
  BEQ explosionSound

  RTS

;; Sonidos
; Cuando se necesite reproducir algun sonido solo basta con
; ejecutar un JSR playShoot ó JSR playExplosion
playShoot:
  LDA #$FF
  STA isShootPlaying
  RTS

playExplosion:
  LDA #$FF
  STA isExplosionPlaying
  RTS

; Machetes
;   * Period: the amount of time it takes for a wave to complete one cycle
shootSound:
  ; Noise
  LDA #%00010100  ; --LC VVVV [BITS]
  STA $400C       ; - L: Envelope loop (on/off),
                  ; - C: Constant volume (on/off)
                  ; - V: Volume envelope

  LDA #%00001000        ; L--- PPPP
  STA $400E       ; - L: Loop noise (on/off),
                  ; - P: Noise period

  LDA #%00000100  ; LLLL L--- [BITS]
                  ; - L: Length counter load
  STA $400F

  ; SQUARE
  LDA #%00010100  ; Duty 00, Loop off, Volumen 4
  STA $4000

  LDA #$A6        ; Low 8 bits of period
  STA $4002       ; 

  LDA #$02        ; Los primeros 5 bits (de izq a derecha) son el volumen
  STA $4003       ; high 3 bits of period
                  ; Period: $2A6 : MI OCTAVA 2

  ; Desactivar flag
  LDA #$00
  STA isShootPlaying
  RTS

explosionSound:
  LDA #%00001111  ; --LC VVVV [BITS]
  STA $400C       ; - L: Envelope loop (on/off),
                  ; - C: Constant volume (on/off)
                  ; - V: Volume envelope

  LDA #$0F        ; L--- PPPP
  STA $400E       ; - L: Loop noise (on/off),
                  ; - P: Noise period

  LDA #%00001000  ; LLLL L--- [BITS]
                  ; - L: Length counter load
  STA $400F
  
  ; Desactivar flag
  LDA #$00
  STA isExplosionPlaying
  RTS

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

;; Ver si dispara
CheckFirePlayer1:
  ;; si el boton de disparo esta presionado
  ;;  crear una nueva bala
  LDA buttons1
  AND #%10000000
  BEQ CheckFirePlayer1Done

  JSR FirePlayer1

CheckFirePlayer1Done:

;; Procesar Enemigos
  JSR UpdateEnemigos


CheckPlayer1Collision:
  ;; vamos a tener que recorrer un listado de enemigos
  ;; si alguno colisiona con player1


  JMP GameEngineDone


UpdateSprites:

  JSR UpdatePlayer1Sprites
  RTS

UpdatePlayer1Sprites:

  LDA player1y  ;;update all sprite info
  ;; guardamos en la posicion del sprite 0
  STA $0200
  ;; establecemos la posicion del sprite 1, en la misma posicion y que el sprite 0
  STA $0204
  ;; establecemos la posicion del sprite 2, 8 pixeles abajo
  CLC
  ADC #$08
  STA $0208
  ;; establecemos la posicion del sprite 3, 8 pixeles abajo
  STA $020C

  LDA player1x
  ;; guardamos en la posicion del sprite 0
  STA $0203
  ;; establecemos la posicion del sprite 2, en la misma posicion x que el sprite 0
  STA $020B
  ;; establecemos la posicion del sprite 1, 8 pixeles a la derecha
  CLC
  ADC #$08
  STA $0207
  ;; establecemos la posicion del sprite 3, 8 pixeles a la izquierda
  STA $020F




FinLoopFuego:
  RTS

; ReseteamosFrameActualFuego:
;   LDA #$00
;   JMP FinLoopFuego

; UpdatePlayer1SpritesFuego0:
;   LDA #$10
;   STA $0209
;   LDA #$11
;   STA $0213
;   JMP ListoFuego

; UpdatePlayer1SpritesFuego1:
;   LDA #$20
;   STA $0209
;   LDA #$21
;   STA $0213
;   JMP ListoFuego

; UpdatePlayer1SpritesFuego2:
;   LDA #$30
;   STA $0209
;   LDA #$31
;   STA $0213
;   JMP ListoFuego



FirePlayer1:
  JSR playShoot
  ;; >> Introducir Disparo aca
  RTS

DrawScore:
  ;;draw score on screen using background tiles
  ;;or using many sprites
  RTS

UpdateEnemigos:
  ;; recorrer la lista de enemigos
  ;;  mover los enemigos
  ;;  verificar colisiones
  ;;  disparar
  ;;  actualizar sprites
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
  .db $00,$29,$1A,$0F,  $00,$36,$17,$0F,  $00,$30,$21,$0F,  $00,$27,$17,$0F   ;;background palette
  .db $22,$1C,$15,$14,  $22,$02,$38,$3C,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;;sprite palette

jugadorSprites:
     ;vert tile attr horiz
  .db $80, $00, $00, $80   ;sprite 0
  .db $80, $01, $00, $88   ;sprite 1
  .db $88, $10, $00, $80   ;sprite 2
  .db $88, $11, $00, $88   ;sprite 3

tiposEnemigos:
    ; tipo  tile1 tile2 tile3 tile4 speedx  speedy vida  cadencia  cantTorretas  torr1x  torr1y  torr2x  torr2y
  .db $00,  $02,  $03,  $12,  $13,   $00,   $01,    $01,    $78,      $01,        $07,    $04,    $00,    $00
  .db $01,  $04,  $05,  $14,  $15,   $01,   $01,    $01,    $50,      $02,        $02,    $00,    $05,    $00
  .db $02,  $22,  $23,  $32,  $33,   $02,   $01,    $01,    $40,      $01,        $07,    $12,    $00,    $00
  .db $03,  $24,  $25,  $34,  $35,   $00,   $02,    $01,    $30,      $01,        $07,    $00,    $00,    $00

enemigos:
  ;; 4 enemigos de tipo 1
  ;   tipo x    y     vida  ultimodisparo cooldown
  .db $00, $20, $00,  $00,  $00,            $00 
  .db $00, $10, $00,  $00,  $00,            $00
  .db $00, $60, $00,  $00,  $00,            $00
  .db $00, $80, $00,  $00,  $00,            $00


;; Armamos la estructura de los sprites de los enemigos en base a los datos anteriores
enemigoSprites:
      ;vert tile attr horiz
  .db $10, $22, $00, $10   ;sprite 0
  .db $10, $23, $00, $18   ;sprite 1
  .db $18, $32, $00, $10   ;sprite 2
  .db $18, $33, $00, $18   ;sprite 3


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