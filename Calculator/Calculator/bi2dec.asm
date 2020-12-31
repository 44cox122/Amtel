 /*
 * bi2dec.asm
 *
 *  Created: 10/1/2018 12:42:12 PM
 *   Author: lakew
 */ 
.cseg
convert2: 
;prologue
	push temp
	push mask	;rBin1L old number
	push temp2	;rBin1H
	push row	
	push col	
	push prow	;rBin2H
	push pcol	;rBin2L
	push counter
	push zl
	push zh

	ld mask, z+		;stores origional number
	ld temp2, z

	ldi zl, low(decnum)
	ldi zh, high(decnum) 

	sbrs temp2, 7
	rjmp Bin2Bcd
	
	com mask
	com temp2

	ldi temp, '-'
	do_lcd_data

	ldi temp, 1
	add mask, temp
	ldi temp, 0
	add temp2, temp


Bin2Bcd:	
	ldi pcol, low(10000)
	ldi prow, high(10000)
	rcall Bin2Digit

	ldi pcol, low(1000)
	ldi prow, high(1000)
	rcall Bin2Digit

	ldi pcol, low(100)
	ldi prow, high(100)
	rcall Bin2Digit

	ldi pcol, low(10)
	ldi prow, high(10)
	rcall Bin2Digit

	ldi pcol, low(1)
	ldi prow, high(1)
	rcall Bin2Digit
	
	;epilogue
	pop zh
	pop zl
	pop counter
	pop pcol
	pop prow
	pop col
	pop row
	pop temp2
	pop mask
	pop temp

ret


Bin2Digit:
	clr counter
	Subtract:
		cp mask, pcol
		cpc temp2, prow
		brlt store
	
		sub mask, pcol
		sbc temp2, prow
		inc counter
		rjmp Subtract
	
	store:
		st z+, counter

	ret