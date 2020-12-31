/*
 * tests.asm
 *
 * Created: 24/10/2018 17:08:16
 * Author: Zahid
 */ 

 test_keypad:
	rcall get_keypad_input
	lds data, KeyPressed
	print_direct
	rjmp test_keypad








test_keypad_alpha:
	rcall get_keypad_alpha
	
	lds index, KeyPressed
	lds data, KeyPressed+1
	
	cpi index, '1'
	breq cursor_move

	print_direct
	do_lcd_command 0b00010000
	rjmp test_keypad_alpha
	
	cursor_move:
	do_lcd_command 0b00010100
	rjmp test_keypad_alpha








test_stn_name:
	clr count
	clr index 
	get_index_addr
	
testnameloop:
	rcall get_keypad_alpha
	
	lds data, KeyPressed
	lds alpha, KeyPressed+1
	
	cpi data, '1'
	breq save_alpha

	print_char alpha
	mov digit, alpha
	do_lcd_command 0b00010000
	rjmp testnameloop
	
save_alpha:
	st x+, digit
	inc count
	cpi count, 10
	breq show_results

	do_lcd_command 0b00010100
	rjmp testnameloop

show_results:
	clear_display
	clr index
	print_stn_name
	ret






	