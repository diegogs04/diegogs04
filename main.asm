;Universidad del Valle de Guatemala
;Programación de Microcontroladores
; PRELAB3.asm
;
; Created: 2/17/2025 12:59:15 PM
; Author : diego
;


; Replace with your application code
.INCLUDE "M328PDEF.INC"
.CSEG
.ORG 0x0000
	JMP PILE
.ORG PCI0addr
	JMP ISR_PINC0
.ORG OVF0addr
	JMP T0_OF
	
//PILE SETUP 
PILE:
LDI R16, LOW(RAMEND)
OUT SPL, R16
LDI R16, HIGH (RAMEND)
OUT SPH, R16

// TABLA VALORES PARA DISPLAY 7 SEGMENTOS

LDI ZH, HIGH (1<<SEG)
LDI ZL, LOW (1<<SEG)
SEG: .DB 0x80, 0x79, 0x24, 0x30, 0x19, 0x12, 0x02, 0x78, 0x00, 0x10
LPM R25, Z
OUT PORTD, R25
//DEFINICIÓN DE VARIABLES

.DEF CONTADOR= R20
.DEF ANT = R23
.DEF DPL = R22
.DEF SOF = R24
.DEF DCN = R25
.DEF VAR = R18 
//CONFIGURACIÓN
SETUP: 
	CLI //NO PERMITE QUE HAYA INTERRUPCIONES EN EL SETUP 

	// CONFIGURACION DE TEMPORIZADOR
	LDI R21, (CLKPCE << 1)// ESCRIBIR UN 1 PARA HABILITAR CAMBIOS EN EL PRESCALER
	STS CLKPR, R21 // LE ESCRIBE EL 1 A CLKPR
	LDI R21, 0x04
	STS CLKPR, R21
	
	CALL TIM_0

	// DESAHIBILITACION DE COMUNICACION SERIAL 
	LDI R21, 0x00
	STS UCSR0B, R21

	// CONFIGURACION DE ENTRADAS
	LDI R16, 0b0001_1000
	OUT DDRB, R16
	LDI R16, 0b0000_0110  // PULLUPS BOTONES
	OUT PORTB, R16   //SE ASIGNA EL VALOR DE R16 A PORTB PARA LOS PULLUPS

	//CONFIGURACION SALIDAS
	LDI R16, 0b0111_1111 //PULLUPS 7-SEGMENTOS
	OUT DDRD, R16 // SE ASIGNA EL VALOR DE R21 A DDRD PARA LOS PULLUPS 
	LDI R16, 0x00
	OUT PORTD, R16

	LDI R16, 0b0000_1111//PULLUPS PARA CONTADOR
	OUT DDRC, R16// SE ASIGNA EL VALOR DE R21 A DDRC PARA LOS PULLUPS
	LDI R16, 0x00
	OUT PORTC, R16

	//CONFIGURACIÓN DE INTERRUPCIONES

	LDI R21, (1 << PCIE0) //HABILITA INTERRUPCIONES EN CAMBIO DE VALOR EN PIN 
	STS PCICR, R21 // HABILITA INTERRUPCIONES EN CAMBIOS DE ESTADO DE PIN
	LDI R21, (1 << PCINT1) | (1 << PCINT2)  // Habilitacion de interrupciones en PB1 Y PB2 
	STS PCMSK0, R21

	LDI R21, (1<<TOIE0) // HABILITA INTERRUPCIONES DE OVERFLOW EN TIMSK0
	STS TIMSK0, R21
	
	//CONFIGURACION DE CONTADOR
	CLR CONTADOR // BORRAR R20 POR SI TIENE ALGUN VALOR GUARDADO 	
	SEI // HABILITA INTERRUPCIONES EN EL SREG

//CICLO PRINCIPAL

CICLO:
	CPI SOF, 50 // REVISA SI LA VARIABLE LLEGA A 50 (50*20m = 1s)
	BREQ RES // SI LLEGA A 50 VA A RESETEAR LA VARIABLE
	CPI VAR, 0 // SI VAR ES 0 VA A DECENAS 
	BREQ DECE
	CPI VAR , 1 // SI VAR ES 1 VA A UNI
	BREQ UNI

	RJMP CICLO
		RES: 
			CLR SOF //RESETTEA LA VARIABLE
			CPI DPL, 9 // COMPARA EL VALOR DE DISPLAY DE UNIDADES CON 9
			BREQ RES_DPL // SI SON IGUALES VA A RESETEAR LAS UNIDADES

			CPI DCN, 6 // COMPARA SI LAS DECENAS ESTAN EN 6
			BREQ RES_DCN // SI SON IGUALES A 6 VA A RESETEAR LAS DECENAS

			INC DPL // AUMENTA LAS UNIDADES
			RJMP CICLO 
		RES_DPL:
			CLR DPL // RESETTEA LAS UNIDADES DEL DISPLAY 
			INC DCN // INCREMENTA LAS DECENAS DE SEGUNDOS 
			RJMP CICLO
		RES_DCN:
			CLR DPL 
			CLR DCN // RESETTEA LAS DECENAS
			RJMP CICLO
		UNI: 
			LDI VAR, 0 // CAMBIA EL VALOR DE VAR A 0
			CBI PORTB, 3 // MANDA UN0AL TRANSISTOR DE DECENAS 
			SBI PORTB, 4 // MANDA UN 1 AL TRANSISTOR DE UNIDADES 
			LDI R16, 0x00 // CARGA 0 AL REGISTRO 
			OUT PORTD, R16 // MANDA 0 A PORTD PARA ELIMINAR GHOST
			LDI ZL, LOW(1<<SEG)
			LDI ZH, HIGH (1<<SEG)
			ADD ZL, DPL 
			LPM R26,Z
			OUT PORTD, R22// SACA EL VALOR DE R26
			RJMP CICLO 
		DECE:
			LDI VAR, 1  // CAMBIA EL VALOR DE VAR A 1
			CBI PORTB, 4 // MANDA UN 0 A TRANSITOR DE UNIDADES 
			SBI PORTB, 3 // MANDA UN 1 A TRANSISTOR DE DECENAS
			LDI R16, 0x00 
			OUT PORTD, R16 // CARGA 0 A PORTD PARA ELIMINAR GHOSTING
			LDI ZL, LOW(1<<SEG)
			LDI ZH, HIGH (1<<SEG)
			ADD ZL, DCN
			LPM R26,Z
			OUT PORTD, R26
			RJMP CICLO
			
			
	RJMP CICLO //BUCLE

// INTERRUPTIONS

ISR_PINC0:

	PUSH R16 // GUARDA R16 EN LA PILA 
	IN R16, PINB // LEE PINB Y LO GUARDA EN R16
	SBRS R16,1 // SALTA SI EL BIT 1 DE PINB ESTÁ SET
	SBRC ANT, 1 // SALTA SI EL ESTADO ANTERIOR ESTABA CLEAR 
	RJMP SUMA // VA A SUMA
	
	MOV R17, ANT // MUEVE ESTADO ANTERIOR A R17
	MOV ANT, R16 // MUEVE ESTADO "ACTUAL" A ESTADO "ANTERIOR"

	
	SBRS R16,2 // SALTA A RESTA SI EL BIT 2 DE PINB ESTÁ EN SET
	SBRC ANT,2 // SALTA SI EL ESTADO ANTERIOR DEL BOTÓN ESTABA CLEAR
	RJMP RESTA // VA A RESTA

	POP R16 // BORRA R16 DE LA PILA 
	RETI

T0_OF:
	SBI TIFR0, TOV0 //LIMPIA LA BANDERA DE OVERFLOW 
	LDI R21, 178    // VALOR PARA HACER 20 ms 
	OUT TCNT0, R21  // CARGA VALOR A TCNT0 

	INC SOF // INCREMENTA VARIABLE QUE CUENTA LOS OVERFLOWS
	RETI
TIM_0:
	LDI R21,(1<<CS00)|(1<<CS02) // SELECCION DE PRESCALER DE 1024
	OUT TCCR0B, R21
	LDI R21, 178
	OUT TCNT0, R21 
	RET

SUMA:
	INC CONTADOR  
	ANDI CONTADOR, 15 // SETTEA LIMITE DE 15 PARA LA VARIABLE CONTADOR
	OUT PORTC, CONTADOR // MUESTRA VARIABLE EN PORTC
	POP R16
	RETI

RESTA:
	DEC CONTADOR 
	ANDI CONTADOR, 15 // SETTEA LIMITE DE 15 PARA LA VARIABLE CONTADOR
	OUT PORTC, CONTADOR // MUESTRA VARIABLE EN PORTC
	POP R16
	RETI