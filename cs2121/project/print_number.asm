/*
 * print_number.asm
 *
 *  Created: 19/10/2018 14:19:00
 *   Author: Zahid
 */ 

.cseg
;
; Prints out a max 5 digit number on to the LCD
;
do_lcd_number:
	push temp
	push count
	push digit

	clr temp
	ldi count, 4				; two byte numbers have 5 digits max, 65536

digit_loop:						; get digit at 10^4, then 10^3...
	rcall get_place_digit		; and print them out in that order
	cp  digit, temp				; don't print the leading zeros
	breq next_place				; temp will not be 0, when the first non-zero is encountered

show_digit:
	ldi temp, '0'
	add temp, digit			; digit = get_place_digit(count)		
	print temp

next_place:
	dec count
	cpi count, 0
	brge digit_loop 

	cpi temp, 0					; if number is zero, just print a zero
	brne lcd_number_end
	ldi temp, '0'
	print temp	

lcd_number_end:
	pop digit
	pop count
	pop temp
	ret

;
; Gets the decimal digit from the current value
; in the place specified by col, 10^col place
get_place_digit:
	push temp
	push temp2
	push temp3
	push temp4
	push count

	clr digit
	clr temp3				; use prow and pcol to subtract from num
	clr temp4				; calculate the place value
	inc temp3				; if hundreds place, do 1*10*10

place_loop:					
	cpi count, 0
	breq sub_loop
	dec count
	mul10w temp3, temp4		; mul10w uses temp and temp2
	rjmp place_loop

sub_loop:
	cp  numl, temp3
	cpc numh, temp4
	brlt place_end	

	inc digit				; count how many times place value can be subtracted

	sub numl, temp3			; for hundreds, count num-100, until num < 100
	sbc numh, temp4			; to get the digits in the hundredth place
	rjmp sub_loop 

place_end:
	pop count
	pop temp4
	pop temp3
	pop temp2
	pop temp
	ret