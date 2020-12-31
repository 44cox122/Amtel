;
; COMP2121 Monorail Project
;
  
.include "m2560def.inc"
.include "lcd_def.inc"
.include "macros.inc"

.def sigstop = r9
.def stopped = r10
.def col   = r11
.def row   = r12
.def alpha = r13
.def digit = r14
.def zero  = r15

.def data  = r16
.def temp  = r17
.def temp2 = r18
.def temp3 = r19
.def temp4  = r20

.def count = r21
.def mask  = r22
.def index = r23

.def numl  = r24
.def numh  = r25


.equ MAX_NAME_LEN  = 11
.equ MOTOR_SPEED   = 60
.equ PWM_INCREMENT = 2
.equ LED_PATTERN   = 0b00010001
.equ TRUE_MASK     = 0b00000001


.dseg
Status:		   .byte 2	 ; keeps track of the monorail status and what to show on the lcd

KeyPressed:	   .byte 4	 ; stores the ascii of the last pushed button
						 ; second byte stores the corresponding letter for digits
						 ; third  byte stores previous key pushed
						 ; fourth byte stores number of times same key pushed

DebounceFlag:  .byte 1   ; flag to be checked for debouncing, clear by timer1 ovf

TempCounter:   .byte 2	 ; temporary counter used to determine if one second has passed
SecondCounter: .byte 2	 ; keeps track of the number of seconds that have passed
Revolutions:   .byte 2	 ; number of time a hole passes the laser

StationCount:  .byte 1   ; number of stations specified
StationNames:  .byte 110 ; array of the station names
TravelTimes:   .byte 10  ; array of travel times between stations
 StopTime:      .byte 1	 ; single byte stop time

.macro clear_globals
	clear TempCounter  
	clear SecondCounter
	clear Revolutions 
	 
	clearb StationCount
	clearb StopTime

	clear KeyPressed
	clear KeyPressed+2
.endm
.macro toggle
	ldi temp, TRUE_MASK
	eor @0, temp
.endm

.cseg
.org 0x00
jmp RESET		; interrupt vector for RESET
jmp EXT_INT0	; interrupt vector for External Interrupt 0
jmp EXT_INT1	; interrupt vector for External Interrupt 1
jmp EXT_INT2	; interrupt vector for External Interrupt 2

.org OVF1addr	; OVF1addr is the address of Timer1 Overflow Interrupt Vector
jmp TIMER1_OVF	; interrupt handler for Timer1 overflow.	
.org OVF0addr	; this is after OVF1addr
jmp TIMER0_OVF	; interrupt handler for Timer0 overflow.	

.include "delay.asm"
.include "lcd.asm"
.include "print_number.asm"
.include "print_string.asm"
.include "keypad.asm"
.include "motor.asm"
.include "user_input.asm"

; All of the user prompts and other strings
PromptNumStn:   .db "Please type the maximum number of stations: "
PromptStnName:  .db "Please type the name of Station (n)", 0
PromptStopTime: .db "Monorail stop/time:", 0
CompleteMSG:	.db "Configuration /is complete.", 0
CompleteMSG2:   .db "Wait 5 seconds.", 0

PromptStnNum:	.db "Enter number of/stations:", 0
InstrStnNames:	.db "Enter name of/each station.", 0
InstrStpTime:	.db "Enter stop/duration.", 0, 0
InstrStnTimes:	.db "Enter travel/times.", 0
LabelStation:	.db "Station ", 0, 0
LabelStnEnd:	.db ":/", 0, 0
LabelStnTime:	.db " to/", 0, 0
NextStn:		.db "The next Stn is:/", 0


DEFAULT:
	reti

RESET:
	cli
	clr zero

	; Stack pointer reset
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
  
	; LED setup
	ser temp		
	out DDRC, temp		; PORTC is all outputs
	clr temp			; No lights are on at the begininng
	out PORTC, temp

	; Keypad setup
	ldi temp, PORTLDIR	; columns are outputs, rows are inputs
	sts DDRL, temp		; cannot use out

	; LCD port setup
	ser temp	
	out DDRF, temp
	out DDRA, temp
	clr temp
	out PORTF, temp
	out PORTA, temp

	; Initialize the LCD
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, no blink
	
	; External interrupt setup
	clr temp 
	out DDRD, temp			; Port D is set to all inputs
	ser temp
	out PORTD, temp			; Enable pull up resistors 

	ldi temp, (2<<ISC20) | (2<<ISC10) | (2<<ISC00) 
	sts EICRA, temp			; all configured as falling edge triggered interrupts

	in temp, EIMSK
	ori temp, (1<<INT0) | (1<<INT1) | (1<<INT2)
	out EIMSK, temp			; Enable External Interrupts 0, 1, 2

	; Timer0 interrupt setup
	out TCCR0A, zero		; Setting up the Timer Interrupt
	ldi temp, 0b00000010
	out TCCR0B, temp		; set prescalar value to 8
	ldi temp, (1<<TOIE0)	; TOIE0 is the bit number of TOIE0 which is 0
	sts TIMSK0, temp		; enable Timer0 Overflow Interrupt

	; Timer1 interrupt setup for debouncing
	sts TCCR1A, zero
	ldi temp, (1<<CS12)		;(1<<CS11)|(1<<CS10) 64 ; set prescaler to 256
	sts TCCR1B, temp

	; PWM setup
	;ldi temp, 0b00001000	
	ser temp
	out DDRE, temp			; set PE2 (OC3B) as output, which is bit 3

	clr temp				; this value and the operation mode determine the PWM duty cycle
	sts OCR3BH, temp
	ldi temp, 0x4a
	sts OCR3BL, temp

	ldi temp, (1<<CS30)		; CS30=1: no prescaling
	sts TCCR3B, temp
	; WGM30=1: phase correct PWM, 8 bits
	; COM3A1=1: make OC3B override the normal port functionality of the I/O pin PE2
	ldi temp, (1<< WGM30)|(1<<COM3A1)|(1<< WGM32)|(1<<COM3B1)
	sts TCCR3A, temp 

	rjmp main


EXT_INT0:
	push temp
	in temp, SREG
	push temp

	debounce int0_end
	ldi temp, 1
	mov sigstop, temp

	int0_end:
	pop temp
	out SREG, temp
	pop temp
	reti


EXT_INT1:
	push temp
	in temp, SREG
	push temp

	debounce int1_end
	ldi temp, 1
	mov sigstop, temp

	int1_end:
	pop temp
	out SREG, temp
	pop temp
	reti


EXT_INT2: 
	push temp
	in temp, SREG
	push temp
	push numl
	push numh

	lds numl, Revolutions	
	lds numh, Revolutions+1
	adiw numh:numl, 1		; just increment the revolutions counter
	sts Revolutions, numl
	sts Revolutions+1, numh

	pop numh
	pop numl
	pop temp
	out SREG, temp
	pop temp
	reti


TIMER0_OVF:					; interrupt subroutine to Timer0
	push temp				; save all conflicting registers in the prologue 
	in temp, SREG			
	push temp				
	push r24
	push r25

	lds r24, TempCounter	; Load the value of the temporary counter
	lds r25, TempCounter+1
	adiw r25:r24, 1			; increase the temporary counter by one
	cpi r24, low(7812)		; check if (r25:r24) = 7812
	ldi temp, high(7812)	; 7812 from 128 * 16MHz
	cpc r25, temp
	brne not_second

	clear TempCounter		; reset the temporary counter

	lds r24, SecondCounter	; Load and increment the seconds counter
	lds r25, SecondCounter+1		
	adiw r25:r24, 1		
	sts SecondCounter, r24
	sts SecondCounter+1, r25
	
	; One second has passed, do stuff here
	;
	rjmp timer_end

not_second: 
	sts TempCounter, r24	; store the new value of the temporary counter
	sts TempCounter+1, r25
	rjmp timer_end

timer_end: 
	pop r25					; epilogue starts
	pop r24					; restore all conflicting registers from the stack
	pop temp
	out SREG, temp
	pop temp
	reti					; return from the interrupt


TIMER1_OVF:
	push temp
	in temp, SREG
	push temp

	sts DebounceFlag, zero	; clear the flag
	sts TIMSK1, zero		; this disables timer1

	timer1_end:
	pop temp
	out SREG, temp
	pop temp
	reti		

;.include "tests.asm"

;
;	Monorail start point
;
main:
	sei	; enable global interrupt

	clear_globals
	clr sigstop
	clr stopped				
	toggle stopped			; monorail starts not travelling
	
	; initialize the global values
	rcall get_station_count
	rcall get_station_names
	rcall get_station_times
	rcall get_stop_time
	rcall configuration

	;test
	clr index
	displayN:
	lds temp2, StationCount
	cp index, temp2
	breq halt

	clear_display
	print_string NextStn
	print_stn_name
	
	set_travel_time_addr
	ld temp, x
	wait temp
	
	inc index
	rjmp displayN
	;test

	clr index				; start at first station
	rcall monorail_loop

halt: 
	rjmp halt
	




;
; do the monorail stuff here
;
monorail_loop:

	cp sigstop, zero
	breq no_stopping

	lds temp, StopTime	 
	wait temp
	rjmp next_station

no_stopping:
	

next_station:
	set_travel_time_addr
	ld temp, x
	clear_display	
	print_stn_name				; This will display the next station name
	wait temp					; Waits for time in between each station



	lds temp, StationCount		; checking if station count is equal to count. If so we have visited each station
	cp count, temp
	breq mono_final

	; poll keypad for the '#' key, if pressed stop everything otherwise continue
	rcall get_keypad_input
	lds index, KeyPressed
	cpi index, '#'
	breq train_stop

	station:
		; stop at station for time in StopTime
		rcall station_stop
		inc count					; increase count as next station has been visited
		rjmp mono_end

	train_stop:	
		; rcall emergency_stop
		rjmp mono_end

		; get the index of the StationNames and rcall print_string
		; continue this until time is up


mono_end:
	rjmp monorail_loop			; repeat

mono_final:						; all stations have been visited, need to reset?
	rjmp mono_final




;
;function to stop train for given time at each stop
;
station_stop:
	push temp
	push count
	push zl
	push zh

	; check if push button has been pressed, if so make a stop, otherwise continue on
	ldi temp, 1
	cp sigstop, temp
	breq next_stop

	; otherwise jmp back to where timer is from station to station

	next_stop:
		; stop the motor

		lds zl, low(StopTime)
		lds zh, high(StopTime)

		ld temp, z
		ldi count, '0'

		station_stop_loop:
			cp count, temp
			breq ret_station_stop

			; call 1 sec delay

			inc count
			rjmp station_stop_loop
				
ret_station_stop:

	pop zh
	pop zl
	pop count
	pop temp

	ret

;
; stops the train if '#' is pressed, waits until '#' pressed again to go
;
emergency_stop:
	push index

	emergency_loop:
		; stop train
		rcall get_keypad_input
		lds index, KeyPressed
		cpi index, '#'
		brne emergency_loop

	pop index

ret

