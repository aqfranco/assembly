DISPLAYS   EQU 0A000H  ; endereco dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereco das linhas do teclado (periferico POUT-2)
TEC_COL    EQU 0E000H  ; endereco das colunas do teclado (periferico PIN)
MASCARA    EQU 0FH     ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado

; **********************************************************************
; * Codigo
; **********************************************************************
PLACE      0
inicio:		
; inicializacoes
    MOV  R2, TEC_LIN   ; endereco do periferico das linhas
    MOV  R3, TEC_COL   ; endereco do periferico das colunas
    MOV  R4, DISPLAYS  ; endereco do periferico dos displays
    MOV  R5, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
    MOV  R6, 8         ; valor da ultima linha (4ª linha, 1000b)

; corpo principal do programa
ciclo:
    MOV  R1, 0
    MOVB [R4], R1      ; escreve linha e coluna a zero nos displays

krj:
    MOV  R1, R6        ; testar a linha 
    MOVB [R2], R1      ; escrever no periférico de saída (linhas)
    MOVB R0, [R3]      ; ler do periférico de entrada (colunas)
    AND  R0, R5        ; elimina bits para além dos bits 0-3
    CMP  R0, 0         ; há tecla premida?
    JZ ciclo_fim       ; se nenhuma tecla premida
    SHL  R1, 4         ; coloca linha no nibble high
    OR   R1, R0        ; junta coluna (nibble low)
    MOVB [R4], R1      ; escreve linha e coluna nos displays
    JMP krj            ; repete ciclo se tecla premida

ciclo_fim:
    SHR R6, 1          ; define a linha como a prévia
    CMP R6, 0          ; compara caso a linha seja 0
    JZ inicio          ; se for, reinicia o valor da linha
    JMP ciclo          ; se nao, mantem o valor atual da linha
