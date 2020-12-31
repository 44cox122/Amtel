/*
 * print_string.asm
 */ 
 
;
; Prints out a string on to the LCD
;
do_lcd_string:
	push zl
	push zh
	push data

char_loop:
	lpm data, z+				; get character from string
	cpi data, 0					; if character is null
	breq lcd_string_end			; then return
		
	cpi data, '/'				; if character is a flash
	brne output_char			; print on next line
	do_lcd_command 0b11000000
	rjmp char_loop

output_char:					; print character to lcd
	print_direct
	rjmp char_loop

lcd_string_end:
	pop data
	pop zh
	pop zl
	ret


;
;	Prints out a station name
;
do_lcd_stn_name:
	push xl
	push xh
	push data
	push count

	clr count

char_loop_stn:
	ld data, x+					; get character from string
	cpi data, 0					; if character is null
	breq lcd_stn_name_end		; then return
			
	print_direct				; print character to lcd
	inc count
	cpi count, MAX_NAME_LEN
	breq lcd_stn_name_end
	rjmp char_loop_stn

lcd_stn_name_end:
	pop count
	pop data
	pop xh
	pop xl
	ret