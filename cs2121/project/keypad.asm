;
;	Gets keypad input
;

.equ PORTLDIR = 0xF0
.equ INITCOLMASK = 0xEF
.equ INITROWMASK = 0x01
.equ ROWMASK = 0x0F

; KeyPressed Var
; first  byte stores the ascii of the last pushed button
; second byte stores the corresponding letter for digits
; third  byte stores previous key pushed
; fourth byte stores number of times same key pushed

.cseg
;
;	scan the keypad u
;
get_keypad_alpha:
	push temp
	push temp2
	push mask
	push digit
	push count
	push index
	
	rcall get_keypad_input
	lds mask,  KeyPressed	; get the digit pressed	
	lds digit, KeyPressed+2	; get the previous digit pressed
	lds count, KeyPressed+3	; the number of times this digit was pushed in a row

	clr temp2				; no additional offset

	cpi mask, 'A'
	brge set_space
	cpi mask, '2'			
	brge check_repeat		; only digits 2 and above have letters		

set_space:
	ldi index, ' '			; just set put in a space for everything else
	sts KeyPressed+1, index 
	rjmp end_keypad_alpha

check_repeat:
	cp mask, digit			; previous digit was different so reset count
	breq increment_repeat	; otherwise increment it

	clr count	
	
	cpi mask, '8'
	brlt set_alpha
	ldi temp2, 1			; add one to additional offset since 7 has 4 letters
	rjmp set_alpha			; for digits 8 and 9

increment_repeat:
	inc count

	cpi mask, '7'			; have to mod count since count is the offset from first letter
	brlt mod_count_3		; everything below 7 has 3 letters
	breq mod_count_4		; 7 has 4 letters
	
	ldi temp2, 1			; add one to additional offset
	cpi mask, '9'			; 9 also has 4 letters
	breq mod_count_4

mod_count_3:
	cpi count, 3			; count % 3
	brlt set_alpha
	subi count, 3
	rjmp set_alpha

mod_count_4:				; count % 4
	cpi count, 4
	brlt set_alpha
	subi count, 4	
	
set_alpha:
	sts KeyPressed+3, count

	mov index, mask			; this converts the digit ascii to desired letter ascii
	subi index, '0'			; and saves it to KeyPressed+1
	lsl index				; index = (mask - '0') * 2 + 11 + offsets + mask
	ldi temp, 11			; where index is the letter ascii and mask the digit ascii
	add index, temp
	add index, temp2
	add index, count
	add index, mask

	sts KeyPressed+1, index 

end_keypad_alpha:
	pop index
	pop count
	pop digit
	pop mask
	pop temp2
	pop temp
	ret


;
;	scans the keypad until a button is pushed, then returns
;
get_keypad_input:
	push temp
	push data
	push index

	lds index, KeyPressed	; record the previous key
	mov mask, index			; for saving later

key_loop:
	rcall check_keypad		; loop until a key is pushed
	lds data, KeyPressed
	cpi data, 0
	breq key_loop

	cp  data, index			; compare the key pushed with previous	
	brne save_key_press

	rcall sleep_100ms		; if it's the same, do debouncing
	ldi index, 0			; set previous key to zero, so debounce happens once
	rjmp key_loop

save_key_press:		
	sts KeyPressed+2, mask	; store the previous key 

end_keypad_input:
	pop index
	pop data
	pop temp
	ret


;
;	scan the keypad once for a button push
;
check_keypad:
	push temp
	push temp2
	push mask
	push col
	push row

	clr temp
	sts KeyPressed, temp

	ldi mask, INITCOLMASK	; initial column mask	
	clr col					; initial column

colloop:
	sts PORTL, mask			; set column to mask value (sets column 0 off)
	
	ldi temp, 0xFF			; implement a delay so the hardware can stabilize
	keypad_delay:
	dec temp
	brne keypad_delay

	lds temp, PINL			; read PORTL. Cannot use in 
	andi temp, ROWMASK		; read only the row bits
	cpi temp, ROWMASK		; check if any rows are grounded
	breq nextcol			; if not go to the next column

	ldi mask, INITROWMASK	; initialise row check
	clr row					; initial row

rowloop:
	mov temp2, temp			; save PINL to check for grounded bit      
	and temp2, mask			; check masked bit
	brne skipconv			; if the result is non-zero, we need to look again
	
	rcall key_to_ascii		; if bit is clear, convert the bitcode
	sts KeyPressed, temp
	rjmp keypad_end			; and return value in KeyPressed

skipconv:
	inc row					; else move to the next row
	lsl mask				; shift the mask to the next bit
	jmp rowloop          

nextcol:
	ldi temp, 3     
	cp  col, temp			; check if we're on the last column
	breq keypad_end			; if so, no buttons were pushed, just return

	sec						; else shift the column mask: We must set the carry bit
	rol mask				; and then rotate left by a bit, shifting the carry into
							; bit zero. We need this to make sure all the rows have
							; pull-up resistors

	inc col					; increment column value
	jmp colloop				; and check the next column convert function converts the 
							; row and column given to a binary number and also outputs 
							; the value to KeyPressed.

keypad_end:
	pop row
	pop col
	pop mask
	pop temp2
	pop temp
	ret	

;
; Inputs come from registers row and col and output will in the temp register
; which is then stored in KeyPressed
;
key_to_ascii:
	ldi temp, 3				
	cp col, temp			; if column is 3 we have a letter
	breq letter_keys

	cp row, temp			; if row is 3 we have a symbol or 0
	breq symbol_keys

digit_keys:
	mov temp, row			; otherwise we have a number (1-9)
	lsl temp				; temp = row * 2
	add temp, row			; temp = row * 3
	add temp, col			; add the column address to get the offset from 1
	inc temp				; add 1. Value of switch is row*3 + col + 1.

	ldi temp2, '0'
	add temp, temp2
	jmp key2ascii_end
	
letter_keys:
	ldi temp, 'A'
	add temp, row			; increment from 'A' by the row value
	jmp key2ascii_end

symbol_keys:
	clr temp
	cp  col, temp			; check if we have a star, zero or hash
	breq star_key
	inc temp
	cp  col, temp				
	breq zero_key

hash_key:
	ldi temp, '#'	
	jmp key2ascii_end

star_key:
	ldi temp, '*'
	jmp key2ascii_end

zero_key:
	ldi temp, '0'

key2ascii_end:
	rcall sleep_25ms
	ret