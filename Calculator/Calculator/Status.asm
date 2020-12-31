/*
 * Status.asm
 *
 *  Created: 10/1/2018 3:54:31 PM
 *   Author: lakew
 */ 
 .include "print_string.asm"

.dseg
.equ signed_mask = 0b10000000

.cseg
 statusH:
	push temp
	push temp2
	push counter
	push counter2
	push row
	push col
	push zl
	push zh
	push xl
	push xh

	ldi xl, low(ovr)
	ldi xh, high(ovr)
	ldi temp2, 0
	st x, temp2

	;checking the status (1, 2, or 3)
	ldi zl, low(status)
	ldi zh, high(status)
	ld temp, z

	cpi temp, 1
	breq subtraction2
	cpi temp, 2
	breq addition2
	
	move:	;moves what is in intermediate to final
		ldi zl, low(intermediate)
		ldi zh, high(intermediate)
		ldi xl, low(final)
		ldi xh, high(final)

		ld temp, z+
		ld temp2, z

		ldi col, low(32768)
		ldi row, high(32768)
		cp temp, col
		cpc temp2, row
		breq overflow
		
		continue1:
			st x+, temp
			st x, temp2

		clear intermediate

		rjmp ending

	subtraction2:		;if the status is set to subtraction then we will add the intermediate and final together 
		ldi zl, low(intermediate)
		ldi zh, high(intermediate)
		ldi xl, low(final)
		ldi xh, high(final)

		ld temp, z+
		ld temp2, z
		ld counter, x+
		ld counter2, x

		sub counter, temp
		sbc counter2, temp2
		brvs overflow

		ldi zl, low(intermediate)
		ldi zh, high(intermediate)
		ldi xl, low(final)
		ldi xh, high(final)
		
		clear intermediate

		st x+, counter
		st x, counter2

		rjmp ending

	addition2:		;if the status is set to addition then we will add the intermediate and final together 
		ldi zl, low(intermediate)
		ldi zh, high(intermediate)
		ldi xl, low(final)
		ldi xh, high(final)

		ld temp, z+
		ld temp2, z
		ld counter, x+
		ld counter2, x

		add counter, temp		;carry out addition of the two numbers 
		adc counter2, temp2
		brvs overflow		;branch if the overflow flag is set!!

		continue3:
			ldi xl, low(final)
			ldi xh, high(final)

			clear intermediate
			st x+, counter
			st x, counter2
		rjmp ending

	overflow:		;this simply prints the overflow to the screen!
		ldi xl, low(ovr)
		ldi xh, high(ovr)
		ldi temp2, 1
		st x, temp2

	ending:
		pop xh
		pop xl
		pop zh
		pop zl
		pop col
		pop row
		pop counter2
		pop counter
		pop temp2
		pop temp
			
ret