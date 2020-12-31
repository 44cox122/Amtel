/*
 * delay.asm
 *
 * Created: 04/10/2018 15:12:34
 * Author: Zahid
 */ 

 ;	if the debounce flag is set, carry bit will be set
 ;	and should branch to the given addr. Otherwise, if 
 ;	flag is not set, carry is cleared, the flag will be
 ;	set and timer 1 enabled
 .macro debounce 
	rcall check_debounce_flag	
	brcs @0
.endm

.macro wait
	push count
	mov count, @0
	rcall wait_for_count
	pop count
.endm

.macro wait_3s
	push count
	ldi count, 3
	rcall wait_for_count
	pop count
.endm

.macro wait_5s
	push count
	ldi count, 5
	rcall wait_for_count
	pop count
.endm

.macro travel
	push count
	mov count, @0
	rcall wait_with_interrupt
	pop count
.endm

 ; 4 cycles per iteration - setup/call-return overhead
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4

.cseg
sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

sleep_10ms:
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_25ms:
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	rcall sleep_5ms
	ret

sleep_100ms:
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	rcall sleep_25ms
	ret
	
;
;	functions to handle debouncing
;
check_debounce_flag:
	push temp

	lds temp, DebounceFlag
	cpi temp, 0
	breq enable_timer1
	
	sec
	rjmp end_db_flag
	
enable_timer1:
	ldi temp, 1
	sts DebounceFlag, temp	

	ldi temp, (1<<TOIE1)	; this enables timer1
	sts TIMSK1, temp
	clc	

end_db_flag:
	pop temp
	ret
	

;
;	waiting functions
;
wait_for_count:
	push count
	push mask
	push numl
	push numh
	push temp

	lds numl, TempCounter		; save initial values
	lds numh, TempCounter+1
	lds mask, SecondCounter

wait_loop:
	lds temp, SecondCounter		; check if count seconds have passed
	sub temp, mask
	cp	temp, count
	brlo wait_loop

	lds temp, TempCounter		; then check if tempcounter is the same
	cp	temp, numl 				; so that exactly count seconds have passed
	lds temp, TempCounter+1
	cpc temp, numh
	brlo wait_loop				

wait_end:
	pop temp
	pop numh
	pop numl
	pop mask
	pop count
	ret



wait_with_interrupt:
	push count
	push mask
	push numl
	push numh
	push temp

	lds numl, TempCounter		; save initial values
	lds numh, TempCounter+1
	lds mask, SecondCounter

wwi_loop:
	rcall check_keypad
	
	lds data, KeyPressed
	cpi data, '#'
	breq breakdown

	cp stopped, zero			; if stopped, don't progress wait
	brne wwi_loop

	lds temp, SecondCounter		; check if count seconds have passed
	sub temp, mask
	cp	temp, count
	brlo wait_loop

	lds temp, TempCounter		; then check if tempcounter is the same
	cp	temp, numl 				; so that exactly count seconds have passed
	lds temp, TempCounter+1
	cpc temp, numh
	brlo wait_loop				

breakdown:
	debounce wwi_loop
	toggle stopped

	cp stopped, zero			; if back to moving, return
	breq wwi_loop

	; update the initial values so the delay lasts for the remaining time
	lds temp, SecondCounter
	sub temp, mask
	sub count, temp	
	lds mask, SecondCounter		
	rjmp wwi_loop

wwi_end:
	pop temp
	pop numh
	pop numl
	pop mask
	pop count
	ret