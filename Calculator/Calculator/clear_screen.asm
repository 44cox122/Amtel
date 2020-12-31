/*
 * clear_screen.asm
 *
 *  Created: 10/1/2018 4:39:21 PM
 *   Author: lakew
 */ 
 clear_screen:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, blink

	ret