;
; Macros for COMP2121 project
;


 .macro div10
	ldi temp, 26		; 256 / 10 
	mul @0, temp		; result in r1
.endm

.macro mul10
	push temp
	mov temp, @0
	lsl temp
	mov r1, temp
	lsl temp
	lsl temp
	add r1, temp
	pop temp
.endm

.macro clear
	ldi yl, low(@0)
	ldi yh, high(@0)
	clr temp
	st y+, temp	
	st y, temp
.endmacro

.macro clearb
	ldi yl, low(@0)
	ldi yh, high(@0)
	clr temp
	st y, temp
.endmacro

.macro rotatel
	clc
	rol @0
	rol @1
.endm

.macro rotater
	clc
	ror @1
	ror @0
.endm

.macro mul10w ; numl, numh
	push temp
	push temp2

	rotatel @0, @1	; 2a
	mov temp, @0
	mov temp2, @1

	rotatel @0, @1	; 8a
	rotatel @0, @1	

	add @0, temp	; 10a
	adc @1, temp2

	pop temp2
	pop temp
.endm

.macro div4w ; numl, numh
	rotater @0, @1
	rotater @0, @1
.endm

 .macro div10w ; numl, numh
	push temp
	push resl
	push resh

	ldi temp, 26		; 256 / 10 
	mul @1, temp		; result in r1

	mov resl, r0
	mov resh, r1 

	mul @0, temp
	add resl, r1
	adc resh, zero
		
	mov @0, resl
	mov @1, resh

	pop resh
	pop resl
	pop temp
.endm