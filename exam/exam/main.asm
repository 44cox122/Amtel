;
; exam.asm
;
; Created: 11/3/2018 2:18:30 PM
; Author : lakew
;

.include "m2560def.inc"

clr r16
ldi r20, low(-1)
ldi r21, high(-1)
ldi r22, low(0x500)
ldi r23, high(0x500)

cp r20, r22
cpc r21, r23
brlo end
ldi r16, 1

end:
	rjmp end
