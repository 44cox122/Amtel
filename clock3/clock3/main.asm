;
; clock3.asm
;
; Created: 9/17/2018 3:32:20 PM
; Author : lakew
;


.include "m2560def.inc"

.def temp = r17
.def temp2 = r18
.def secOnes = r19
.def secTens = r20
.def minOnes = r21
.def minTens = r22
.def symbol = r23

; The macro clears a word (2 bytes) in the data memory
; The parameter @0 is the memory address for that word
.macro clear
ldi YL, low(@0) ; load the memory address to Y pointer
ldi YH, high(@0)
clr temp ; set temp to 0
st Y+, temp ; clear the two bytes at @0 in SRAM
st Y, temp
.endmacro

.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	clr r16
	mov r16, @0
	ldi r24, '0'
	add r16, r24
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro do_lcd_data_symbol
	clr r16
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro tens_place	;multiply by 1/10 
	ldi temp2, 26
	mul @0, temp2
	mov temp2, r1
.endmacro

.macro seconds		;take result from tens_place multiply by 10 and then
	ldi temp2, 10
	mul temp2, r1
	sub @0, temp2
.endmacro

.dseg

TempCounter: .byte 2		; temp count to check time passed

.cseg

.org 0x0000

jmp RESET
jmp DEFAULT		; no handling for IRQ0.
jmp DEFAULT		; no handling for IRQ1.

.org OVF0addr	; OVF0addr is the address of Timer0 Overflow Interrupt Vector
jmp Timer0OVF	; jump to the interrupt handler for Timer0 overflow.

jmp DEFAULT ; default service for all other interrupts.

DEFAULT:
	reti ; no interrupt handling
	 
RESET: 
	ldi temp, high(RAMEND) ; initialize the stack pointer SP
	out SPH, temp

	ldi temp, low(RAMEND)
	out SPL, temp

	ser r16
	out DDRF, r16
	out DDRA, r16
	clr r16
	out PORTF, r16
	out PORTA, r16

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	ldi r16, '0'
	do_lcd_data r16
	ldi r16, '0'
	do_lcd_data r16
	ldi r16, ':'
	do_lcd_data r16

	rjmp main		; jump to main program

Timer0OVF: ; interrupt subroutine to Timer0
	in temp, SREG
	push temp ; prologue starts
	push YH ; save all conflicting registers in the prologue
	push YL
	push r25
	push r24 
	push r23 
	push r16	; prologue ends

; Load the value of the temporary counter
	lds r24, TempCounter
	lds r25, TempCounter+1
	
	adiw r25:r24, 1 ; increase the temporary counter by one

	cpi r24, low(7812) ; check if (r25:r24) = 7812
	ldi temp, high(7812) ; 7812 = 106/128
	cpc r25, temp
	brne NotSecond
	clear TempCounter

	rjmp continue

	NotSecond: ; store the new value of the temporary counter
		sts TempCounter, r24
		sts TempCounter+1, r25
		rjmp EndIF

	continue:
		do_lcd_command 0b00000001 ; clear display
		
		inc secOnes
		cpi secOnes, 10
		brlo cont1
		clr secOnes
	addsec:
		inc secTens

		cpi secTens, 6 
		brlo cont1

		clr secTens

	addmin:
		inc minOnes
		cpi minOnes, 10
		brlo cont1
		clr minOnes

	addmin2:
		clr minOnes
		inc minTens
		
	cont1:

		do_lcd_data	minTens
		do_lcd_data minOnes

		ldi symbol, ':'
		do_lcd_data_symbol symbol

		do_lcd_data secTens
		do_lcd_data secOnes

EndIF: 
	pop r16
	pop r23
	pop r24 ; epilogue starts
	pop r25 ; restore all conflicting registers from the stack
	pop YL
	pop YH
	pop temp

	out SREG, temp
	
	reti ; return from the interrupt

main: 
	clr minTens
	clr minOnes
	clr secTens
	clr secOnes

	clear TempCounter ; initialize the temporary counter to 0

	ldi temp, 0b00000000
	out TCCR0A, temp
	
	ldi temp, 0b00000010
	out TCCR0B, temp ; set prescalar value to 8
	
	ldi temp, 1<<TOIE0 ; TOIE0 is the bit number of TOIE0 which is 0
	sts TIMSK0, temp ; enable Timer0 Overflow Interrupt

	sei ; enable global interrupt

stop: 
	rjmp stop ; loop forever


;Functions
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

lcd_command:
	out PORTF, r16
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, r16
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push r16
	clr r16
	out DDRF, r16
	out PORTF, r16
	lcd_set LCD_RW

lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
        nop
	in r16, PINF
	lcd_clr LCD_E
	sbrc r16, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser r16
	out DDRF, r16
	pop r16
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)

delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
