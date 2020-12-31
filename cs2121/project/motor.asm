/*
 * motor.asm
 *
 * Created: 19/10/2018 15:30:58
 * Author: Zahid
 */ 

;
;	Changes the pwm duty cycle
;
set_speed:
	push mask
	push temp
	push temp2
	push numl
	push numh
	push mask

	cp stopped, zero		; 0 is monorail moving, 1 is stop		
	breq move_motor

stop_motor:
	sts OCR3BL, zero
	rjmp speed_end

move_motor:
	lds numl, Revolutions	
	lds numh, Revolutions+1

	mul10w numl, numh
	div4w numl, numh

	lds mask, OCR3BL

	ldi temp, MOTOR_SPEED
	cp numl, temp			; just keep lower byte, assume rps < 255
	brlt incr_speed
	breq speed_end

decr_speed:
	subi mask, PWM_INCREMENT
	sts OCR3BL, mask
	rjmp speed_end
	
incr_speed:
	ldi temp, PWM_INCREMENT
	add mask, temp
	sts OCR3BL, mask

speed_end:
	pop mask
	pop numh
	pop numl
	pop temp2
	pop temp
	ret
	
;
;	Shows the motor's revolutions per second on the lcd
;
PrintRevolutions:
	push numl
	push numh
	push temp

	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001100 ; Cursor on, no bar, no blink

	lds numl, Revolutions	
	lds numh, Revolutions+1

	mul10w numl, numh
	div4w numl, numh

	rcall do_lcd_number

	clear Revolutions

	pop mask
	pop temp
	pop numh
	pop numl
	ret