/*
 * printString.asm
 *
 *  Created: 10/1/2018 12:35:05 PM
 *   Author: lakew
 */ 
 print_string:
	push zl
	push zh
	push temp
	push yl
	push yh
	
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, blink
	
	loop:
		lpm temp, z+
		cpi temp, '!'
		breq endst 
		
		cpi temp, 32
		brne cont
		do_lcd_command 0b11000000 ; new line
		rjmp loop

		cont:
			do_lcd_data temp
			rjmp loop

	endst:

		pop yh
		pop yl
		pop temp
		pop zh
		pop zl

	ret