/*
 * printValue.asm
 *
 *  Created: 10/1/2018 12:33:45 PM
 *   Author: lakew
 */ 
 .include "bi2dec.asm"

 print_value:
	push zl
	push zh
	push temp
	push temp2
	push counter
	push r17

	ldi zl, low(final)
	ldi zh, high(final)

	rcall convert2

	ldi zl, low(decnum)
	ldi zh, high(decnum)
	
	clr counter
	ldi r17, 48

	decnumL:
		cpi counter, 5
		breq decnumE
		ld temp, z+
		add temp, r17
		do_lcd_data
		inc counter
		rjmp decnumL
	
	decnumE:
	pop r17
	pop counter
	pop temp2
	pop temp
	pop zh
	pop zl

	ret