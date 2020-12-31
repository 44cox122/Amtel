/*
 * getValue.asm
 *
 *  Created: 10/1/2018 12:30:21 PM
 *   Author: lakew
 */ 

 .macro rotate
	clc
	rol r19
	rol r20
.endmacro


 get_value:
	push temp
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push zl
	push zh
	push xl
	push xh
	push yl
	push yh

	clr r20
	clr r21

	;load intermediate 
	ldi zl, low(intermediate)
	ldi zh, high(intermediate)

	;put in registers to use
	ld r19, z+
	ld r20, z
	
	;multiplying intermediate by 10
	rotate
	mov r22, r19
	mov r23, r20
	rotate
	rotate

	add r19, r22	
	adc r20, r23

	ldi r24, 0

	add r19, temp
	adc r20, r24

	;store back in intermediate
	ldi zl, low(intermediate)
	ldi zh, high(intermediate)

	st z+, r19
	st z, r20

	;epilogue
		pop yh
		pop yl
		pop xh
		pop xl
		pop zh
		pop zl
		pop r24
		pop r23
		pop r22
		pop r21
		pop r20
		pop r19
		pop temp

	ret