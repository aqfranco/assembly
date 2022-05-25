DISPLAYS   EQU 0A000H  ; endereco dos displays de 7 segmentos (periferico POUT-1)
TEC_LIN    EQU 0C000H  ; endereco das linhas do teclado (periferico POUT-2)
TEC_COL    EQU 0E000H  ; endereco das colunas do teclado (periferico PIN)
LINHA      EQU 8       ; linha a testar (4a linha, 1000b)
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

; corpo principal do programa
ciclo:
    MOV  R1, 0 
    MOVB [R4], R1      ; escreve linha e coluna a zero nos displays

espera_tecla:          ; neste ciclo espera-se ate uma tecla ser premida
    MOV  R1, LINHA     ; testar a linha 4 
    MOVB [R2], R1      ; escrever no periferico de saida (linhas)
    MOVB R0, [R3]      ; ler do periferico de entrada (colunas)
    AND  R0, R5        ; elimina bits para alem dos bits 0-3
    CMP  R0, 0         ; ha tecla premida?
    JZ   espera_tecla  ; se nenhuma tecla premida, repete
                       ; vai mostrar a linha e a coluna da tecla
    SHL  R1, 4         ; coloca linha no nibble high
    OR   R1, R0        ; junta coluna (nibble low)
    MOVB [R4], R1      ; escreve linha e coluna nos displays
    
ha_tecla:              ; neste ciclo espera-se ate NENHUMA tecla estar premida
    MOV  R1, LINHA     ; testar a linha 4  (R1 tinha sido alterado)
    MOVB [R2], R1      ; escrever no periferico de saida (linhas)
    MOVB R0, [R3]      ; ler do periferico de entrada (colunas)
    AND  R0, R5        ; elimina bits para alem dos bits 0-3
    CMP  R0, 0         ; ha tecla premida?
    JNZ  ha_tecla      ; se ainda houver uma tecla premida, espera ate nao haver
    JMP  ciclo         ; repete ciclo