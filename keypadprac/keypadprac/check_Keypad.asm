/*
 * check_Keypad.asm
 *
 *  Created: 10/19/2018 3:07:41 PM
 *   Author: lakew
 */ 
 .dseg
 PRow: .byte 1
 PCol: .byte 1

.cseg
.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

check_keypad:
	push temp
	push temp2
	push temp3	
	push temp4	;replaces counter2
	push count	;remains counter
	push resl	;replaces col
	push resh	; replaces row
	push numl	;replaces mask
	

	intialize:
		ldi temp3, 20		; giving pcol and prow values so they are not in valid range
		ldi temp4, 20
		mov pcol, temp3
		mov prow, temp4
		clr counter
		clr temp3
		clr temp4

	main:
		ldi numl, INITCOLMASK ; initial column mask
		clr resl ; initial column
	
	;keypad
	colloop:
		STS PORTL, numl ; set column to mask value (sets column 0 off)

		ldi temp, 0xFF ; implement a delay so the hardware can stabilize

	delay:
		dec temp
		brne delay
		LDS temp, PINL ; read PORTL. Cannot use in 
		andi temp, ROWMASK ; read only the row bits
		
		cpi temp, 0xF ; check if any rows are grounded
		breq nextcol ; if not go to the next column
		ldi numl, INITROWMASK ; initialise row check
		clr resh ; initial row

	rowloop:      
		mov temp2, temp
		and temp2, numl ; checknumled bit
		brne skipconv ; if the result is non-zero, we need to look again

		rcall convert ; if bit is clear, convert the bitcode

		jmp main ; and start again

	skipconv:
		inc resh ; else move to the next row
		lsl numl ; shift the mask to the next bit
		
		jmp rowloop          

	nextcol:     
		cpi resl, 3 ; check if we^Òre on the last column
		breq main ; if so, no buttons were pushed, so start again.

		sec ; else shift the columnnuml: We must set the carry bit
		rol numl ; and then rotate left by a bit, shifting the carry into bit zero. We need this to make sure all the rows have pull-up resistors
	
		inc resl ; increment column value
		jmp colloop ; and check the next column convert function converts the row and column given to a binary number and also outputs the value to PORTC.

		; Inputs come from registers row and col and output is in temp. 
	convert:
		cp prow, resh
		brne cont1
		cp pcol, resl
		brne cont1
		
		inc temp3
		;debouncing delay
		inc counter
		rcall sleep_1ms
		cpi counter, 100
		breq test
		ret 

	test:
		cpi temp3, 2
		brge cont1
		cp prow, resH
		brne cont1
		cp pcol, resl
		brne cont1
		;inc temp3
		
	delay2:
		inc counter
		rcall sleep_1ms
		cpi counter, 50
		brlo test
	
	cont1:
		clr counter
		st PCol, resl
		st PRow, resh

		cpi resl, 3 ; if column is 3 we have a letter
		breq letters
		
		cpi resh, 3 ; if row is 3 we have a symbol or 0
		breq symbols
		
		mov temp, resh ; otherwise we have a number (1-9)
		lsl temp ; temp = row * 2
		add temp, resh ; temp = row * 3
		add temp, resl ; add the column address to get the offset from 1
		
		ldi temp2, 48
		inc temp ; add 1. Value of switch is row*3 + col + 1.
		add temp, temp2
		;add temp, temp3
		clr temp2
		jmp convert_end

	letters:
		ldi temp, 65
		add temp, temp3
		;add temp, resh ; increment from 0xA by the row value
		jmp convert_end
	symbols:
		cpi resl, 0 ; check if we have a star
		breq star
		cpi resl, 1 ; or if we have zero
		breq zero
		ldi temp, '#' ; we'll output 0xF for hash
		jmp convert_end
		
	star:
		ldi temp, '*' ; we'll output 0xE for star
		jmp convert_end
	
	zero:
		ldi temp, 48

	convert_end:
		rcall sleep_25ms
		;check if the dispaly is full, if so clear it
		cpi temp4, 16
		brlo cont2
		mov temp2, temp
		do_lcd_command 0b00000001 ; clear display
		do_lcd_command 0b00000110 ; increment, no display shift
		do_lcd_command 0b00001111 ; Cursor on, bar, blink
		
		clr temp4
		mov temp, temp2

		cont2:
			cpi temp3, 1
			breq add1
			cpi temp3, 2
			brge add2
			
			do_lcd_data
			inc temp4
			rjmp return

			add1:
			ldi temp2, 1
			add temp, temp2
			do_lcd_data ; write value to LCD
			inc temp4
			rjmp return

			add2:
			ldi temp2, 2
			add temp, temp2
			do_lcd_data ; write value to LCD
			inc temp4

			return:

				do_lcd_command 0b00010000
				clr temp3
				;do_lcd_command 0b00010100
				ret ; return to caller
	store:
		sts PCol, resl	; storing col
		sts PRow, resh	; storing row
		