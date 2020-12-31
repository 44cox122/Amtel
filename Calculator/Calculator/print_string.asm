/*
 * print_string.asm
 *
 *  Created: 10/1/2018 4:07:58 PM
 *   Author: lakew
 */ 
  print_string2:
	push zl
	push zh
	push temp
	push yl
	push yh
	
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, blink
	
	ovrF:
		lpm temp, z+
		cpi temp, '!'
		breq endOVR
		
		cpi temp, 32
		brne contOVR
		do_lcd_command 0b11000000 ; new line
		rjmp ovrF

		contOVR:
			do_lcd_data temp
			rjmp ovrF

	endOVR:

		pop yh
		pop yl
		pop temp
		pop zh
		pop zl

	ret