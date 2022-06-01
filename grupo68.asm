DISPLAYS   EQU 0A000H  ; endereco dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereco das linhas do teclado (periferico POUT-2)
TEC_COL    EQU 0E000H  ; endereco das colunas do teclado (periferico PIN)
DEFINE_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
ATRASO EQU 40H                     ; atraso para limitar a velocidade do rover
MIN_COLUNA EQU 0000H
MAX_COLUNA EQU 0040H
LINHA        		EQU  31        ; linha do rover (a meio do ecrã))
COLUNA			EQU  30        ; coluna do rover (a meio do ecrã)
VALOR_INI EQU 100H
LARGURA		EQU	5			; largura do rover
COR_PIXEL		EQU	0FF00H		; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

	PLACE		0100H				

SP_inicial:

DEF_ROVER:					; tabela que define o rover (cor, largura, pixels)
	WORD		LARGURA
	WORD		COR_PIXEL, 0, COR_PIXEL, 0, COR_PIXEL		; # # #   as cores podem ser diferentes			
     

PLACE      0
inicio:		
; inicializacoes
    MOV  SP, SP_inicial
    MOV  R2, COLUNA
    MOV  R9, LINHA
    MOV  R5, 8         ; valor da ultima linha (4ª linha, 1000b)
    MOV  [APAGA_AVISO], R6	; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R6	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R6, 0			; cenário de fundo número 0
    MOV  [SELECIONA_CENARIO_FUNDO], R6	; seleciona o cenário de fundo
    MOV  R11, ATRASO

; corpo principal do programa

display:
    CALL pls
	JMP posição_rover

pls:
    PUSH R1
    PUSH R2
    MOV R1, VALOR_INI
    MOV R2, DISPLAYS
    MOV [R2], R1
    POP R2
    POP R1
    RET

posição_rover:
    MOV  R9, LINHA			; linha do rover
    MOV  R2, COLUNA		; coluna do rover

desenho_inicial:
	CALL desenha_rover

detecta_tecla:
    MOV  R1, R5        ; testar a linha
    CALL teclado
    CMP	R0, 0
    JZ ciclo_fim       ; se nenhuma tecla premida
    SHL  R1, 4         ; coloca linha no nibble high
    OR   R1, R0        ; junta coluna (nibble low)
    MOV  R4, R1
    JMP  eh_mov           ; salta para fora depois de obter a tecla

ciclo_fim:
    SHR R5, 1          ; define a linha como a prévia
    CMP R5, 0          ; compara caso a linha seja 0
    JNZ detecta_tecla  ; se nao, mantem o valor atual da linha
    MOV R5, 8          ; se for, reinicia o valor da linha
    JMP eh_mov            ; salta para fora


teclado:
	PUSH	R2
	PUSH	R3
	PUSH	R4
	MOV  R2, TEC_LIN   ; endereço do periférico das linhas
	MOV  R3, TEC_COL   ; endereço do periférico das colunas
	MOV  R4, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R2], R1      ; escrever no periférico de saída (linhas)
	MOVB R0, [R3]      ; ler do periférico de entrada (colunas)
	AND  R0, R4        ; elimina bits para além dos bits 0-3
	POP	R4
	POP	R3
	POP	R2
	RET

eh_mov:
    MOV R8, R4
	MOV R7, 0011H
	CMP R4, R7;
	JZ ciclo_atraso
	MOV R7, 0014H
	CMP R4, R7;
	JNZ out

ciclo_atraso:
	SUB R11, 1         ;
	JNZ out            ; salta o movimento enquanto é adequado

apaga_rover:       		; desenha o rover a partir da tabela
	MOV	R6, R2			; cópia da coluna do rover
	MOV	R4, DEF_ROVER		; endereço da tabela que define o rover
	MOV	R5, [R4]			; obtém a largura do rover
apaga_pixels:       		; desenha os pixels do rover a partir da tabela
	MOV	R3, 0			; para apagar, a cor do pixel é sempre 0
	MOV  [DEFINE_LINHA], R9	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3	; altera a cor do pixel na linha e coluna selecionadas
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  apaga_pixels		; continua até percorrer toda a largura do objeto

escolhe_mov:
	MOV R7, 0011H
	CMP R8, R7
	JZ move_para_esquerda
	MOV R7, 0014H
	CMP R8, R7
	JZ move_para_direita

move_para_direita:
	MOV	R7, 1			; desloca-se para a direita
	JMP	testa_limite_direito
move_para_esquerda:
	MOV	R7, -1			; desloca-se para a esquerda
    JMP testa_limite_esquerdo

testa_limite_esquerdo:		; vê se o rover chegou ao limite esquerdo
	MOV	R5, MIN_COLUNA
	CMP	R2, R5
	JLE	para
    JMP coluna_seguinte
testa_limite_direito:		; vê se o rover chegou ao limite direito
	MOV	R6, [DEF_ROVER]	; obtém a largura do rover (primeira WORD da tabela)
	ADD	R6, R2			; posição a seguir ao extremo direito do rover
	MOV	R5, MAX_COLUNA
	CMP	R6, R5
	JGE	para
    JMP coluna_seguinte
	
para:
	MOV R7, 0

coluna_seguinte:
	ADD	R2, R7			; para desenhar objeto na coluna seguinte (direita ou esquerda)
    MOV R11, ATRASO     
	CALL	desenha_rover		; vai desenhar o rover de novo

out: 
    MOV R5, 8
	JMP detecta_tecla

desenha_rover:       		; desenha o boneco a partir da tabela
	MOV	R6, R2			; cópia da coluna do boneco
	MOV	R4, DEF_ROVER		; endereço da tabela que define o boneco
	MOV	R5, [R4]			; obtém a largura do boneco
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	R3, [R4]			; obtém a cor do próximo pixel do boneco
	MOV  [DEFINE_LINHA], R9	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3	; altera a cor do pixel na linha e coluna selecionadas
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  desenha_pixels      ; continua até percorrer toda a largura do objeto
    RET


