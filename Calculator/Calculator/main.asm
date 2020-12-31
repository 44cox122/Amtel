;
; Calculator.asm
;
; Created: 9/20/2018 3:51:35 PM
; Author : lakew
;

;
; keypad.asm
;
; Created: 9/17/2018 6:09:42 PM
; Author : lakew
;

;IMPORTANT NOTICE: 
;The labels on PORTL are reversed, i.e., PLi is actually PL7-i (i=0, 1, ¡­, 7).  

;Board settings: 
;Connect the four columns C0~C3 of the keypad to PL3~PL0 of PORTL and the four rows R0~R3 to PL7~PL4 of PORTL.
;Connect LED0~LED7 of LEDs to PC0~PC7 of PORTC.
    
; For I/O registers located in extended I/O map, "IN", "OUT", "SBIS", "SBIC", 
; "CBI", and "SBI" instructions must be replaced with instructions that allow access to extended I/O. Typically "LDS" and "STS" combined with "SBRS", "SBRC", "SBR", and "CBR".

.include "m2560def.inc"

.def temp = r16
.def row = r17
.def col = r18
.def mask = r19
.def temp2 = r20
.def prow = r21
.def pcol = r22
.def counter = r23
.def counter2 = r24

;keypaad
.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

;lcd
.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4

.macro clear
ldi YL, low(@0) ; load the memory address to Y pointer
ldi YH, high(@0)
clr temp ; set temp to 0
st Y+, temp ; clear the two bytes at @0 in SRAM
st Y, temp
.endmacro

;lcd
.macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	;ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro lcd_set
	sbi PORTA, @0
.endmacro

.macro lcd_clr
	cbi PORTA, @0
.endmacro

.dseg
	intermediate: .byte 2
	final:	.byte 2
	decnum: .byte 2
	status: .byte 2
	ovr:	.byte 2


.cseg

jmp RESET

.org 0x72

RESET:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp
	
	;keypad
	ldi temp, PORTLDIR ; columns are outputs, rows are inputs
	STS DDRL, temp     ; cannot use out
	ser temp
	out DDRC, temp ; Make PORTC all outputs
	out PORTC, temp ; Turn on all the LEDs main keeps scanning the keypad to find which key is pressed.

	;lcd
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
	do_lcd_command 0b00001111 ; Cursor on, bar, blink
	rjmp intialize

.include "LED.asm"
.include "delay.asm"
.include "printString.asm"
.include "getValue.asm"
.include "printValue.asm"
.include "status.asm"
.include "clear_screen.asm"

intialize:			;making variables
	ldi pcol, 20
	ldi prow, 20
	clr counter
	clr counter2
	clear status
	clear intermediate
	clear final
	ovr_flow: .db "OVERFLOW occured! "
	error_msg: .db "Incorrect expression! "

main:
	ldi mask, INITCOLMASK ; initial column mask
	clr col ; initial column
	
;keypad
colloop:
		STS PORTL, mask ; set column to mask value (sets column 0 off)

		ldi temp, 0xFF ; implement a delay so the hardware can stabilize

delay:
		dec temp
		brne delay
		LDS temp, PINL ; read PORTL. Cannot use in 
		andi temp, ROWMASK ; read only the row bits
		
		cpi temp, 0xF ; check if any rows are grounded
		breq nextcol ; if not go to the next column
		ldi mask, INITROWMASK ; initialise row check
		clr row ; initial row

rowloop:      
		mov temp2, temp
		and temp2, mask ; check masked bit
		brne skipconv ; if the result is non-zero, we need to look again
		
		rcall convert ; if bit is clear, convert the bitcode

		jmp main ; and start again

skipconv:
		inc row ; else move to the next row
		lsl mask ; shift the mask to the next bit
		
		jmp rowloop          

nextcol:     
	cpi col, 3 ; check if we^Òre on the last column
	breq main ; if so, no buttons were pushed, so start again.

	sec ; else shift the column mask: We must set the carry bit
	rol mask ; and then rotate left by a bit, shifting the carry into bit zero. We need this to make sure all the rows have pull-up resistors

	inc col ; increment column value
	jmp colloop ; and check the next column convert function converts the row and column given to a binary number and also outputs the value to PORTC.


; Inputs come from registers row and col and output is in temp. 
convert:
		cp prow, row
		brne cont1
		cp pcol, col
		brne cont1
		
		;debouncing delay
		inc counter
		rcall sleep_1ms
		cpi counter, 125
		breq cont1
		ret
		
	cont1:
		clr counter
		mov pcol, col
		mov prow, row

		cpi col, 3 ; if column is 3 we have a letter
		breq letters
		
		cpi row, 3 ; if row is 3 we have a symbol or 0
		breq symbols
		

		mov temp, row ; otherwise we have a number (1-9)
		lsl temp ; temp = row * 2
		add temp, row ; temp = row * 3
		add temp, col ; add the column address to get the offset from 1
		
		inc temp ; add 1. Value of switch is row*3 + col + 1.
		rcall get_value ; puts number into intermediate

		ldi temp2, 48
		add temp, temp2
		clr temp2
		jmp convert_end

letters:
	ldi zl, low(status)	;load the status
	ldi zh, high(status)
	rcall statusH		

	ldi xl, low(ovr)		;checks if there was an overflow from status, if so sends it right to overflow part!
	ldi xh, high(ovr)
	ld temp2, x
	cpi temp2, 1
	brge ovrflow2

	;checking which letter button was pressed!
	cpi row, 0
	ldi temp, 1
	st z, temp
	breq subtraction

	cpi row, 1
	ldi temp, 2
	st z, temp
	breq addition

	cpi row, 2
	breq equals

	cpi row, 3
	breq d


	subtraction:
		ldi temp, '-'
		jmp convert_end

	addition:
		ldi temp, '+'
		jmp convert_end

	equals:
		ldi temp, '='
		do_lcd_data 
		rcall print_value
		jmp end

	d:
		ldi temp, 'D' ; D is used to clear the screen
		rcall clear_screen
		jmp end

symbols:
		cpi col, 0 ; check if we have a star
		breq star
		cpi col, 1 ; or if we have zero
		breq zero
		
		ldi temp, '#' ; 
		ldi zl, low(error_msg<<1)
		ldi zh, high(error_msg<<1)
		rcall print_string
		jmp end
		

star:
		ldi temp, '*' ; we'll output 0xE for star
		ldi zl, low(error_msg<<1)
		ldi zh, high(error_msg<<1)
		rcall print_string
		jmp end
	
zero:
		clr temp
		rcall get_value
		ldi temp, 48
		jmp end

ovrflow2:
	ldi zl, low(ovr_flow<<1)
	ldi zh, high(ovr_flow<<1)
	rcall print_String2
	rjmp end

convert_end:
		;check if the dispaly is full, if so clear it
		cpi counter2, 16
		brlo cont2

		mov temp2, temp
		do_lcd_command 0b00000001 ; clear display
		do_lcd_command 0b00000110 ; increment, no display shift
		do_lcd_command 0b00001111 ; Cursor on, bar, blink
		
		clr counter2
		mov temp, temp2
		
		cont2:
			do_lcd_data ; write value to LCD
			inc counter2
	
		end:
			rcall sleep_25ms
			ret ; return to caller

