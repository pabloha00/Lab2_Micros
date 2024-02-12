;******************************************************************************
; Universidad del Valle de Guatemala
; IE2023: Programación de microcontroladores
; Laboratorio1
; Autor: Pablo Herrarte
; Proyecto: Laboratorio1
; Hardware: ATMEGA328P
; Creado: 28/01/2023
; Última modificación: 28/01/2023 
;******************************************************************************

.include "M328PDEF.inc"
.CSEG
.ORG 0x0000

;******************************************************************************
; SACK POINTER
;******************************************************************************

	LDI R16, LOW(RAMEND)	
	OUT SPL, R16				;Variable  general
	LDI R17, HIGH(RAMEND)
	OUT SPH, R17				;Contador con botones 7 segmentos
	LDI R18, HIGH(RAMEND)
	OUT SPH, R18				;Contador de segundos
	LDI R19, HIGH(RAMEND)
	OUT SPH, R19				;Variable para Timer0
	LDI R20, HIGH(RAMEND)
	OUT SPH, R20				;Variable para lograr 1 segundo
;******************************************************************************
; TABLA
;******************************************************************************

	TABLA7SEG: .DB 0x3F, 0x05, 0x5B, 0x4F, 0x65, 0x6E, 0x7E, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x3A, 0x5D, 0x7A, 0x72
	;Tabla para el 7 segmentos

;******************************************************************************
; CONFIGURACIÓN
;******************************************************************************

Setup:

	LDI R16, (1 << CLKPCE)
	STS CLKPR, R16			;Habilita prescaler
	LDI R16, 0b0000_0011
	STS CLKPR, R16			;Reloj 2MHz

	LDI R16, 0
	OUT TCCR0A, R16			;Configuración normal

	LDI R16, (1 << CS02) | (1 <<CS00)
	OUT TCCR0B, R16			;Configuración del timer0

	LDI R19, 61				;Valor de desbordamiento
	OUT TCNT0, R19	
		
	LDI R16, 0b0000_1111	
	OUT DDRC, R16			;Salidas PC0 a PC3 (Contador de segundos)
	
	LDI R16, 0b0000_0011	;Suma y resta contador 7 segmentos
	OUT PORTB, R16			;Pull up a PB0 y PB1
	LDI R16, 0b0000_0100	;Asignamos PB0 y PB1 como input y PB2 como out
	OUT DDRB, R16		

	LDI R17, 0				;Valor inicial del 7 segmentos

	LDI R16, 0b1111_1111	;PORTD son salidas (7 segmentos)
	OUT DDRD, R16			

	LDI R16, 0b0011_1111	;Inicializa en 0 el 7 segmentos 
	OUT PORTD, R16			

	LDI R18, 0				;Inicializa el contador de segundos en 0
	OUT PORTC, R18
	
	LDI R20, 0				;La cuenta para llegar al segundo

;******************************************************************************
; LOOP
;******************************************************************************

LOOP:

	SBIS TIFR0, TOV0	; Salta si TOV0 está establecido 
	RJMP LOOP			; Regresa a Suma y espera hasta que TOV0 esté establecido

	IN R16, PINB		;Escribir PINB en R16 
	SBRS R16, PB0		;Salta instrucción si PB0 está encendido
	RJMP DelayBounce	;Función DelayBounce (Suma del 7 segmentos)

	IN R16, PINB		;Escribir PINB en R16
	SBRS R16, PB1		;Salta instrucción si PB1 está encendido
	RJMP DelayBounce2	;Función DelayBounce2 (Resta del 7 segmentos)

	LDI R19, 61			;Reinicia el temporizador
	OUT TCNT0, R19		
	SBI TIFR0, TOV0		;Limpia el bit TOV0

	INC R20				;R20+1
	CPI R20,10			;Esta instrucción se repite 10 veces para que pase 1seg
	BRNE LOOP
	CLR R20				;Se limpia R20
	INC R18				;Se suma uno al contador de segundos
	CPI R18, 16			;R18 no puede ser 16
	BREQ LimSup2		;Limite de R18

	OUT PORTC, R18		;Desplegamos cuenta de segundos en PORTC
	DEC R18				
	CP R17, R18			;Comparamos el 7 segmentos con R18
	BREQ Alarma			;Activamos la alarma
	INC R18				;Regresamos R18 a su estado original

	RJMP LOOP			;Regresa al Loop


;******************************************************************************
; DELAY BOUNCE
;******************************************************************************

DelayBounce:			;Antirerebote (Suma del 7 segmentos)
	LDI R16, 100		
	delay:				
		DEC R16			;Cuenta a 100
		BRNE delay		
	SBIS PINB, PB0		;Salta instrucción si PB0 está encendido
	RJMP DelayBounce	;Regresa a DelayBounce
	RJMP Suma			;Va a suma
	RJMP LOOP

Suma:
	INC R17				;Suma 1
	CPI R17, 16			;El resultado no debe ser 16
	BREQ LimSup			;Limite del 7 segmentos
			
	MOV  R16, R17		;Copiamos 7 segmentos en variable temporal
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL, R16			
	LPM R16, Z			;La buscamos en la tabla 7segmentos
	OUT PORTD, R16		;Desplegamos resultado en PORTD

	RJMP LOOP

LimSup:
	LDI R17, 15			;Limite superior 15
	RJMP LOOP

LimSup2:
	DEC R18				;R18 = 15
	CP R18, R17			;Comparamos R18 (15) con el otro contador (R17)
	BREQ Alarma			;Activamos la alarma
	LDI R18, 0			;R18 = 0
	OUT PORTC, R18		;Despliega el resultado en PORTC
	RJMP LOOP

DelayBounce2:			;Antirrebote (Resta del 7 segmentos)
	LDI R16, 100		
	delay2:	
		DEC R16			;Cuenta a 100
		BRNE delay2
	SBIS PINB, PB1		;Salta instrucción si PB1 está encendido
	RJMP DelayBounce2	;Regresa a DelayBounce2
	RJMP Resta			;Va a resta
	RJMP LOOP

Resta:

	DEC R17				;Resta 1
	CPI R17, -1			;El resultado no debe ser -1
	BREQ LimInf			;Limite del 7 segmentos
	
	MOV  R16, R17		;Copiamos 7 segmentos en variable temporal
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL, R16			
	LPM R16, Z			;La buscamos en tabla de 7segmentos
	OUT PORTD, R16		;Desplegamos resultado en PORTD

	RJMP LOOP

LimInf:
	LDI R17, 0			;Limite inferior 0
	RJMP LOOP

Alarma:					;Led al comparar ambos contadores
	LDI R16, 0b0000_0100	;Negaremos el pin PB2
	IN R18, PINB		;Escribimos en R18 el PINB
	EOR R18, R16		;Negamos PB2
	OUT PORTB, R18		;Lo desplegamos en PORTB
	LDI R18, 0			;Regresamos el contador de segundos a 0
	OUT PORTC, R18		;Desplegamos 0 en PORTC
	RJMP LOOP