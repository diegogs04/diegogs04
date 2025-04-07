/*
 * Clase 2603.c
 *
 * Created: 3/26/2025 4:52:15 PM
 * Author : diego
 */ 

//ENCABEZADO
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

volatile uint16_t ADC_val = 0;
volatile uint8_t conta = 0;
volatile uint8_t val = 0;
volatile uint8_t b_sum = 0;
volatile uint8_t b_res = 0;
volatile uint8_t alto = 0;
volatile uint8_t bajo = 0;
volatile uint8_t b_disp = 0 ; 

void setup();
void initADC();
void timer_ini(void);
void DispHex(uint8_t val);

int main(void)
{
	setup();
	initADC();
	while (1)
	{
		if (b_sum) {
			conta++;
			b_sum = 0;
		}

		if (b_res) {
			conta--;
			b_res = 0;	
		}
	}
}

void setup ()
{
	cli();
	
	DDRD = 0xFF;  // Salida de los displays y LEDS
	UCSR0B = 0x00;  // Deshabilitacion de comunicacion serial
	
	DDRC &= ~(1 << PC2) | (1 << PC5); // Entrada de los botones
	PORTC |= (1<< PC2)|(1 << PC5); // Pullups botones
	
	PCICR |= (1 << PCIE1); 
	PCMSK1 |= (PCINT10) | (PCINT13); // Habilitacion de interrupciones en pines
	
	DDRB |= (1 << PB2) | (1 << PB3) | (1 << PB4); // Declaracion de salidas para transistores 
	
	initADC();
	timer_ini();
	sei();
}

void initADC()
{
	ADMUX = 0;
	ADMUX |= (1 << REFS0);
	ADMUX |= (1 << ADLAR); // SOLO IZQUIERDA
	ADMUX |= (1 << MUX2) | (1 << MUX1);  // Configurar A6 como entrada analogica
	
	
	ADCSRA = 0;
	ADCSRA |= (1 << ADPS1) | (1 << ADPS0); // se settea prescaler
	ADCSRA |= (1 << ADIE);     // se habilitan interrupciones 
	ADCSRA |= (1 << ADEN);
	
	ADCSRA |= (1 << ADSC);  //Encender la conversion 
}

 void DispHex(uint8_t val)
 {
 	switch (val)
 	{
 		case 0x00:
 		PORTD = 0xC0;
 		break;
 		
 		case 0x01:
 		PORTD = 0xF9;
 		break;
 		
 		case 0x02:
 		PORTD = 0xA4;
 		break;
 		
 		case 0x03:
 		PORTD = 0xB0;
 		break;
 		
 		case 0x04:
 		PORTD = 0x99;
 		break;
 		
 		case 0x05:
 		PORTD = 0x92;
 		break;
 		
 		case 0x06:
 		PORTD = 0x82;
 		break;
 		
 		case 0x07:
 		PORTD = 0xF8;
 		break;
 		
 		case 0x08:
 		PORTD = 0x80;
 		break;
 		
 		case 0x09:
 		PORTD = 0x90;
 		break;
 		
 		case 0x0A:
 		PORTD = 0x88;
 		break;
 		
 		case 0x0B:
 		PORTD = 0x83; 		
		 break;
	
    	case 0x0C:
		PORTD = 0xC6;
 		break;
		 
		case 0x0D:
 		PORTD = 0xA1;
 		break;
 		
 		case 0x0E:
 		PORTD = 0x86;
 		break; 	
		 	
 		case 0x0F:
 		PORTD = 0x8E;
 		break;
 		
 		default:
 		PORTD = PORTD = 0xC0;
 		break;
 	}
 	
 }

void timer_ini()
{
	TCCR0A = 0;
	TCCR0B = (1 << CS01) |(1 << CS00); //Prescaler 64
	TIMSK0 = (1 << TOIE0);
	
}
// rutinas de interrupciones

ISR(ADC_vect)
{
	ADC_val = ADCH;
	alto = (ADC_val >> 4) & 0x0F;
	bajo = ADC_val & 0x0F;
	ADCSRA |= (1 << ADSC);
}

ISR (PCINT1_vect)
{
	if(!(PINC & (1 << PINC2)))
	{
		b_sum = 1;
		
	}
	
	if (!(PINC & (1 << PINC5)))
	{
		b_res = 1;
	}
}
ISR(TIMER0_OVF_vect)
{
	if (b_disp == 0)
	{
		PORTB &=~(1 << PB4);
		PORTB |= (1 << PB3);
		DispHex(alto);
		b_disp = 1;
	}
	
	else 
	{
		PORTB &=~ (1 << PB3);
		PORTB |=(1 << PB4);
		DispHex(bajo);
		b_disp = 0;
	}
}