/*
 * lcdmacros.inc
 *
 * Created: 04/10/2018 15:40:13
 * Author: Zahid
 */ 

.equ LCD_CLR_DISP   = 0b00000001 ; clear lcd screen
.equ LCD_MOVE_HOME  = 0b10000000 ; move cursor back to start
.equ LCD_SECOND_ROW = 0b10101000 ; move cursor to start of second row

 .macro do_lcd_command
	ldi r16, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro clear_display
	do_lcd_command 0b00000001	; clear display
	do_lcd_command 0b00000110	; increment, no display shift
	do_lcd_command 0b00001111	; Cursor on, blink on
.endm

.macro print_direct
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro print_char
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro print
	mov r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro print_ascii
	ldi r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro print_bin
	ldi r16, '0'
	add r16, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro print_binary
	ldi r16, '0'
	add r16, @0
	rcall lcd_data
	rcall lcd_wait
.endm

.macro print_string
	ldi zl, low(@0<<1)
	ldi zh, high(@0<<1)
	rcall do_lcd_string
.endmacro