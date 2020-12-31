/*
 * user_input.asm
 *
 * Created: 19/10/2018 16:29:06
 */ 


 .macro get_index_addr
 	ldi xl, low(StationNames)
	ldi xh, high(StationNames)
	ldi temp, MAX_NAME_LEN		; length of name string is 11
	mul temp, index
	add xl, r0					; this puts the x pointer to the correct spot to get
	adc xh, r1					; the station name at index	
.endm

.macro print_stn_name
	get_index_addr
	rcall do_lcd_stn_name
.endm

.macro set_travel_time_addr
	ldi xl, low(TravelTimes)
	ldi xh, high(TravelTimes)
	add xl, index
	add xh, zero
.endm


 ;
 ;	Prompt for number of stations, max is 10
 ;
get_station_count:
	push count
	push data
	push temp
	push temp2

station_count_loop:
	clear StationCount

	clr count
	clr temp 
	clr data

	clear_display
	print_string PromptStnNum	; ask for user to enter number of station

check_stn_count:	
	rcall get_keypad_input
		
	lds data, KeyPressed		; check the button pushed is valid
	cpi data, '#'
	breq end_station_count
	cpi data, 'A'
	brge station_count_loop
	cpi data, '*'
	breq station_count_loop	


store_stn_count:

	cpi count, 2				; checking if the user has entered more then 1 number
	brge check_stn_count		

	print_direct				; Print data before saving it

	subi data, '0'				; takes away ascii value of data
	lds temp2, StationCount
	mul10 temp2
	add data, r1				; result of mul10 will be in r1

	cpi data, 11				; ensure count is 10 or less
	brge station_count_loop
	cpi data, 0					; checking if data is equal to 0, and will return 
	breq station_count_loop

	mov temp, data
	sts StationCount, data
	inc count
	rjmp check_stn_count		; checks for another key press
	 
end_station_count:
	cpi temp, 1					; if temp is 1 then only 1 station and that is not allowed
	breq station_count_loop
	cpi count, 0
	breq station_count_loop

	pop temp2
	pop temp
	pop data
	pop count
	ret



 ;
 ;	Prompt for names of the stations
 ;
get_station_names:
	push index
	push mask
	push temp
	push data
	push count
	push alpha
	
	clear_display
	print_string InstrStnNames
	do_lcd_command 0b00001100	; cursor off
	wait_3s

	clr index

station_names_loop:  
	get_index_addr				; get address of index, puts it in xh:xl
	inc index
    
	lds temp, StationCount
	cpi temp, 10
	breq check_ten

	clear_display
	print_string LabelStation
	print_binary index
	print_string LabelStnEnd
	clr count
	rjmp name_char_loop

check_ten:
	cpi index, 10
	brne print_norm

	clear_display
	print_string LabelStation
	ldi data, '1'
	print_direct
	ldi data, '0'
	print_direct
	print_string LabelStnEnd
	clr count
	rjmp name_char_loop

print_norm:
	clear_display
	print_string LabelStation
	print_binary index
	print_string LabelStnEnd
	
	clr count

name_char_loop:
    rcall get_keypad_alpha

    lds mask, KeyPressed
    lds data, KeyPressed+1
		
    ; dealing with special keys for input
    cpi mask, '#'
    breq next_station_name
    cpi mask, '*'
    breq store_name_char
    cpi mask, 'A'
    brge name_char_loop
			
    print_char data				; input was a digit, print the alpha character
	mov alpha, data				; save the print character
    do_lcd_command 0b00010000	; lets user input until '#' is pressed
    rjmp name_char_loop

store_name_char:
	st x+, alpha				; store the charater
	lds alpha, KeyPressed+1		; change to space for next store
	inc count					; count is checking if the name is longer than 10 letters/spaces
	cpi count, 10				; checking number of entered characters is more than 10
    breq next_station_name

	do_lcd_command 0b00010100	; move cursor onto the next space 
	rjmp name_char_loop
  
next_station_name:				; if '#' is pressed then we will put a 0 to the end of the name 
	st x, zero					; to show that it is the end of input
	lds temp, StationCount
	cp index, temp			
	breq end_station_name
	rjmp station_names_loop

end_station_name:
	pop alpha
	pop count
	pop data
	pop temp
	pop mask
	pop index
	ret



;
;	Function to recive user input for the station times
;
get_station_times:
	push yl
	push yh
	push count
	push data
	push temp
	push temp2
	push temp3
	push index

	clear TravelTimes			; zero out the array
	clear TravelTimes+2
	clear TravelTimes+4
	clear TravelTimes+6
	clear TravelTimes+8

	clear_display
	print_string InstrStnTimes	; ask for user to enter time btwn stations
	do_lcd_command 0b00001100	; cursor off
	wait_3s		
	
	clr index		

station_times_loop:
	clear_display				; to print out " time to name1 to name2"
	print_stn_name				; print the first station name
	print_string LabelStnTime	; station (n) to

	mov temp3, index

	inc index					; if last station, next station is the first
	lds temp, StationCount
	cp  index, temp
	brlt print_second_stn
	clr index

	print_second_stn:
	print_stn_name				; print the next station name
	print_ascii ':'				; station (n+1):
	
	mov index, temp3
	clr count					; keeps track of number of inputs

travel_time_input:	
	rcall get_keypad_input
		
	lds data, KeyPressed		; check the button pushed
	cpi data, '#'				; hash means input done
	breq next_stn_time
	cpi data, 'A'				; ignore letter and star buttons
	brge travel_time_input
	cpi data, '*'
	breq travel_time_input
	cpi count, 2				; maximum of 2 characters allowed
	brge travel_time_input		

	print_direct				; print the digit before saving the value
	set_travel_time_addr		; move to the index in travel times array

	subi data, '0'				; takes away ascii value to get binary value
	ld temp2, x
	mul10 temp2
	add data, r1			

	cpi data, 11				; ensure time is 10 or less
	brge redo_travel_time
	cpi data, 0					; minimum time must be 1
	breq redo_travel_time
 
	st x, data					; store the travel time 
	inc count
	rjmp travel_time_input

redo_travel_time:
	set_travel_time_addr
	st x, zero					; rif time not valid, get user to reinput
	rjmp station_times_loop

next_stn_time:
    cpi count, 0				; ensure user has input something
	breq redo_travel_time

	inc index					; continue to next two stations
	lds temp, StationCount		; no more stations
	cp  index, temp
    breq end_station_time
	rjmp station_times_loop

end_station_time:
	pop index
	pop temp3
	pop temp2
	pop temp
	pop data
	pop count
	pop yh
	pop yl
	ret


;
; Get Stop Time
; Asking user for the stop time at all the stations (one stop time for all)
;
get_stop_time:
	push temp
	push data
	push index
	push zl
	push zh

	clear_display
	print_string InstrStpTime
	do_lcd_command 0b00001100	; cursor off
	wait_3s

	clear_display
	print_string PromptStopTime

stop_time_loop:
	rcall get_keypad_input
	lds index, KeyPressed

	cpi index, '#'
	breq store_time
	cpi index, '0'
	breq stop_time_loop
	cpi index, '2'				; this will cover '*' and '0'
	brlt stop_time_loop
	cpi index, '6'				; cannot be larger than 5
	brge stop_time_loop

	mov temp, index				; this stores the value so that if '#' is pressed 
	mov data, index				; the last value is stored and not '#' 
	print_direct
	do_lcd_command 0b00010000	; lets user input until '#' is pressed
	rjmp stop_time_loop
		
store_time:
	ldi zl, low(StopTime)
	ldi zh, high(StopTime)
	subi temp, '0'
	st z, temp

stop_time:
	pop zh
	pop zl
	pop index
	pop data
	pop temp
	ret 


configuration:	
	push count

	clear_display
	print_string CompleteMSG
	do_lcd_command 0b00001100	; cursor off
	ldi count, 2
	wait count					; waits 2 sec
	
	clear_display
	print_string CompleteMSG2
	do_lcd_command 0b00001100	; cursor off
	wait_5s

	clear_display

	pop count
	ret