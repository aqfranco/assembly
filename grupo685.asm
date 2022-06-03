DISPLAYS   EQU 0A000H  ; endereco dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereco das linhas do teclado (periferico POUT-2)
TEC_COL    EQU 0E000H  ; endereco das colunas do teclado (periferico PIN)
DEFINE_LINHA    		EQU 600AH      ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH      ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H      ; endereço do comando para escrever um pixel
SEL_SOM                 EQU 6048H
REP_SOM                 EQU 605AH
APAGA_AVISO     		EQU 6040H      ; endereço do comando para apagar o aviso de nenhum cenário selecionado
APAGA_ECRÃ	 		EQU 6002H      ; endereço do comando para apagar todos os pixels já desenhados
SELECIONA_CENARIO_FUNDO  EQU 6042H      ; endereço do comando para selecionar uma imagem de fundo
ATRASO EQU 60H                     ; atraso para limitar a velocidade do rover
MIN_COLUNA EQU 0000H
MAX_COLUNA EQU 0040H
LINHA        		EQU  31        ; linha do rover (a meio do ecrã))
COLUNA			EQU  30        ; coluna do rover (a meio do ecrã)
COLUNA_M	EQU 7
VALOR_INI EQU 100
LARGURA		EQU	5			; largura do rover
ALTURA  EQU 5
COR_PIXEL		EQU	0FF00H		; cor do pixel: vermelho em ARGB (opaco e vermelho no máximo, verde e azul a 0)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

	PLACE		1000H				

SP_inicial:

DEF_ROVER:					; tabela que define o rover (cor, largura, pixels)
	WORD		LARGURA
	WORD		COR_PIXEL, 0, COR_PIXEL, 0, COR_PIXEL		

DEF_METEORO:
    WORD        LARGURA
    WORD        COR_PIXEL		

PLACE      0
inicio:		
; inicializacoes
    MOV  SP, SP_inicial
    MOV  [APAGA_AVISO], R6	; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R6	; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
	MOV	 R6, 0			; cenário de fundo número 0
    MOV  [SELECIONA_CENARIO_FUNDO], R6	; seleciona o cenário de fundo
    MOV  R2, LINHA
    MOV  R3, COLUNA
    MOV  R4, 8         ; valor da ultima linha (4ª linha, 1000b)
    MOV  R5, ATRASO
	MOV  R6, VALOR_INI
    MOV  R10, 0
	MOV R11, 0

; corpo principal do programa

;R0 substitui R8 codigo antigo
;R7 substitui R4 codigo antigo
;R1 substitui R7 codigo antigo
;
;

display:
    CALL hexa_ini

posição_rover:
    MOV  R2, LINHA			; linha do rover
    MOV  R3, COLUNA		; coluna do rover

desenho_inicial:
	CALL desenha_rover
	CALL desenha_meteoro

detecta_tecla:
    MOV  R1, R4       ; testar a linha
    CALL teclado
    CMP	 R0, 0
    JZ ciclo_fim       ; se nenhuma tecla premida
    SHL  R1, 4         ; coloca linha no nibble high
    OR   R1, R0        ; junta coluna (nibble low)
    MOV  R7, R1
    JMP  eh_mov           ; salta para fora depois de obter a tecla

ciclo_fim:
    SHR R4, 1          ; define a linha como a prévia
    CMP R4, 0          ; compara caso a linha seja 0
    JNZ detecta_tecla  ; se nao, mantem o valor atual da linha
    MOV R4, 8          ; se for, reinicia o valor da linha
    JMP eh_mov            ; salta para fora

eh_mov:
	MOV R1, 0011H
	CMP R7, R1;
	JZ ciclo_atraso
	MOV R1, 0014H
	CMP R1, R7;
	JNZ out

ciclo_atraso:
	SUB R5, 1         ;
	JNZ detecta_tecla            ; salta o movimento enquanto é adequado

apaga_rover:       		; desenha o rover a partir da tabela
    PUSH R4
    PUSH R5
    PUSH R6
	MOV	R6, R3			; cópia da coluna do rover
	MOV	R4, DEF_ROVER		; endereço da tabela que define o rover
	MOV	R5, [R4]			; obtém a largura do rover
apaga_pixels:       		; desenha os pixels do rover a partir da tabela
	MOV	R8, 0			; para apagar, a cor do pixel é sempre 0
	MOV  [DEFINE_LINHA], R2	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R8	; altera a cor do pixel na linha e coluna selecionadas
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  apaga_pixels		; continua até percorrer toda a largura do objeto
    POP R6
     POP R5
     POP R4

escolhe_mov:
	MOV R1, 0011H
	CMP R7, R1
	JZ move_para_esquerda
	MOV R1, 0014H
	CMP R7, R1
	JZ move_para_direita

move_para_direita:
	MOV	R1, 1			; desloca-se para a direita
	JMP	testa_limite_direito
move_para_esquerda:
	MOV	R1, -1			; desloca-se para a esquerda
    JMP testa_limite_esquerdo

testa_limite_esquerdo:		; vê se o rover chegou ao limite esquerdo
    PUSH R5
    PUSH R6
	MOV	R5, MIN_COLUNA
	CMP	R3, R5
    POP R6
    POP R5
	JLE	para
    JMP coluna_seguinte
testa_limite_direito:
    PUSH R5
    PUSH R6		; vê se o rover chegou ao limite direito
	MOV	R6, [DEF_ROVER]	; obtém a largura do rover (primeira WORD da tabela)
	ADD	R6, R3			; posição a seguir ao extremo direito do rover
	MOV	R5, MAX_COLUNA
	CMP	R6, R5
    POP R6
    POP R5
	JGE	para
    JMP coluna_seguinte
	
para:
	MOV R1, 0

coluna_seguinte:
	ADD	R3, R1			; para desenhar objeto na coluna seguinte (direita ou esquerda)
    MOV R5, ATRASO
	CALL	desenha_rover		; vai desenhar o rover de novo

out: 
    MOV R4, 8

i_ou_d:
	MOV R1, 0028H
	CMP R7, R1 
	JZ decrementa_disp
	MOV R1, 0018H
	CMP R7, R1 
	JNZ tec_meteoro

incrementa_disp:
	CMP R7, R10
	JZ  fim
	MOV R9, 100
	CMP R6, R9
	JGE fim
	ADD R6, 5
	CALL hexa_ini
	JMP fim
decrementa_disp:
	CMP R7, R10 
	JZ  fim
	CMP R6, 5
	JN fim
	SUB R6, 5
	CALL hexa_ini

tec_meteoro:
	CMP R7, R10
	JZ fim
	MOV R1, 0021H
	CMP R7, R1
	JNZ fim

apaga_meteoro:       		; desenha o rover a partir da tabela
    PUSH R2
    PUSH R4
    PUSH R5
    PUSH R6
	PUSH R9
    MOV  R2, R11
	MOV	R6, COLUNA_M			; cópia da coluna do rover
	MOV	R4, DEF_METEORO		; endereço da tabela que define o rover
	MOV	R5, [R4]			; obtém a largura do rover
	MOV R9, R5
apaga_pixels_meteoro:       		; desenha os pixels do rover a partir da tabela
	MOV	R8, 0			; para apagar, a cor do pixel é sempre 0
	MOV  [DEFINE_LINHA], R2	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R8	; altera a cor do pixel na linha e coluna selecionadas
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  apaga_pixels_meteoro		; continua até percorrer toda a largura do objeto
	 MOV R5, [DEF_METEORO]
	 MOV R6, COLUNA_M			; cópia da coluna do boneco
	 ADD R2, 1
	 SUB R9, 1	; menos uma linha para tratar
	 JNZ apaga_pixels_meteoro
	 POP R9
    POP R6
     POP R5
     POP R4
     POP R2

proxima_linha:
	PUSH R2
	PUSH R3
	MOV R2, 0
	ADD R11, 1
	MOV [SEL_SOM], R2
	MOV [REP_SOM], R2
	POP R3
	POP R2
	CALL desenha_meteoro

fim:

	MOV R10, R7
    MOV R7, 0
	JMP detecta_tecla

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

desenha_rover:       		; desenha o boneco a partir da tabela
    PUSH R4
    PUSH R5
    PUSH R6
	MOV	R6, R3			; cópia da coluna do boneco
	MOV	R4, DEF_ROVER		; endereço da tabela que define o boneco
	MOV	R5, [R4]			; obtém a largura do boneco
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels_rover:       		; desenha os pixels do boneco a partir da tabela
	MOV	R8, [R4]			; obtém a cor do próximo pixel do boneco
	MOV  [DEFINE_LINHA], R2	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R8	; altera a cor do pixel na linha e coluna selecionadas
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar

     JNZ  desenha_pixels_rover      ; continua até percorrer toda a largura do objeto
     POP R6
     POP R5
     POP R4
    RET

desenha_meteoro:       		; desenha o boneco a partir da tabela
	PUSH R2
	PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
	PUSH R9
	MOV R2, R11
	MOV R6, COLUNA_M
	MOV	R4, DEF_METEORO		; endereço da tabela que define o boneco
	MOV	R5, [R4]			; obtém a largura do boneco
	MOV R9, R5
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels_meteoro:       		; desenha os pixels do boneco a partir da tabela
	MOV	R8, [R4]			; obtém a cor do próximo pixel do boneco
	MOV  [DEFINE_LINHA], R2	; seleciona a linha
	MOV  [DEFINE_COLUNA], R6	; seleciona a coluna
	MOV  [DEFINE_PIXEL], R8	; altera a cor do pixel na linha e coluna selecionadas
     ADD  R6, 1               ; próxima coluna
     SUB  R5, 1			; menos uma coluna para tratar
     JNZ  desenha_pixels_meteoro      ; continua até percorrer toda a largura do objeto
	 MOV R5, [DEF_METEORO]
	 MOV R6, COLUNA_M			; cópia da coluna do boneco
	 ADD R2, 1
	 SUB R9, 1	; menos uma linha para tratar
	 JNZ desenha_pixels_meteoro
	 POP R9
     POP R6
     POP R5
     POP R4
	 POP R3
	 POP R2
    RET


hexa_ini:
	PUSH R1
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R7
	MOV R5, 0
	CMP R6, 0
	JZ hexa_sai
	MOV R1, R6
	MOV R7, 10 
	MOV R0, 1
	MOV R4, 16
hexa:
	MOV R2, R1
	MOD R2, R7
	MUL R2, R0
	MUL R0, R4
	DIV R1, R7
	ADD R5, R2
	CMP R1, 0
	JNZ hexa
hexa_sai:
	MOV [DISPLAYS], R5
	POP R7
	POP R5
	POP R4
	POP R3
	POP R2
	POP R1
	RET