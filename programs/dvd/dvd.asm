; the 16:9 'screen' will be memory rows 0x60 to 0xE0
; this leaves 96 bytes of instruction space

; core program loop
loop:
; clear old dvd pixel
LDI R0 0xFF         ; R0 bootstrapped to memory address of the AP
LDM R3 R0           ; load AP 
XOR R1 R1           ; CLR R1
STM R1 R3           ; clear old 'dvd' position

; X AXIS
; load variables
DEC R0              ; point to 0xFE (x-pos)
LDM R1 R0           ; R1 = x-pos
DEC R0              ; point to 0xFD (x-velo)
LDM R2 R0           ; R2 = x-velo

; apply x movement
CLC     
ADC R1 R2           ; R1 = new x-pos
LDI R0 0xFF         ; point back to AP
LDM R3 R0           ; R3 = AP
CLC
ADC R3 R2           ; R3 = NEW AP (updated with OLD x velocity)
STM R3 R0           ; store new AP

; x bounds check
LDI R3 15           ; x-pos max value (right side of screen)
CMP R1 R3          
JEQ invert_x_velo   ; if at right edge, invert velo for next frame
XOR R3 R3
CMP R1 R3  
JEQ invert_x_velo   ; if at left edge, invert velo for next frame
JMP save_x_state    ; otherwise save variables

invert_x_velo:
NOT R2
INC R2              ; twos compliment inversion

save_x_state:
DEC R0              ; point to 0xFE (x-pos)
STM R1 R0           ; save new x-pos
DEC R0              ; point to 0xFD (x-velo)
STM R2 R0           ; save (possibly inverted) x-velo

; Y AXIS
; load variable
DEC R0              ; point to 0xFC (y-velo)
LDM R1 R0           ; R1 = y-velo

; apply y movement
LDI R0 0xFF         ; point R0 to AP
LDM R3 R0           ; R3 = AP
CLC
ADC R3 R1           ; R3 = NEW AP (updated with OLD x velocity)
STM R3 R0           ; store new AP

; y bounds check
LDI R2 0xDF         ; >0xDF means on bottom y boundry
CMP R3 R2           
JGT invert_y_velo   ; if at bottom edge, invert velo for next frame
LDI R2 0x70         ; <0x70 means on top y boundry
CMP R3 R2    
JLT invert_y_velo   ; if at bottom edge, invert velo for next frame
JMP draw_pixel      ; no need to save if the velocity did not change

invert_y_velo:
NOT R1
INC R1              ; twos compliment inversion
LDI R0 0xFC         ; point to y-velo       
STM R1 R0           ; store new y-velo

draw_pixel:
LDI R0 0xFF         ; point back to AP
LDM R3 R0           ; load AP
LDI R2 0xAA         ; value at AP
STM R2 R3           ; dvd pixel value

; loop to hold current dvd pixel in place for a bit
XOR R3 R3           ; clr R2
LDI R2 20           ; countdown length = 20
busy_loop:
DEC R2
CMP R3 R2           ; check if countdown has hit 0
JEQ loop            ; restart when countdown 0
JMP busy_loop

; memory mapped variables
; 0xFF: absolute pointer (AP)
; 0xFE: x-pos var
; 0xFD: x velocity
; 0xFC: y velocity
INI 0xFF 0xA7
INI 0xFE 0x07
INI 0xFD 1
INI 0xFC 16

; initalisation of leftover memory (to ensure that only the 'screen' memory space has 0s)

INI 0xF0 0xEE
INI 0xF1 0xEE
INI 0xF2 0xEE
INI 0xF3 0xEE
INI 0xF4 0xEE
INI 0xF5 0xEE
INI 0xF6 0xEE
INI 0xF7 0xEE
INI 0xF8 0xEE
INI 0xF9 0xEE
INI 0xFA 0xEE
INI 0xFB 0xEE

INI 0x50 0xEE
INI 0x51 0xEE
INI 0x52 0xEE
INI 0x53 0xEE
INI 0x54 0xEE
INI 0x55 0xEE
INI 0x56 0xEE
INI 0x57 0xEE
INI 0x58 0xEE
INI 0x59 0xEE
INI 0x5A 0xEE
INI 0x5B 0xEE
INI 0x5C 0xEE
INI 0x5D 0xEE
INI 0x5E 0xEE
INI 0x5F 0xEE

; dead beef 99
INI 0x4B 0xDE
INI 0x4C 0xAD
INI 0x4D 0xBE
INI 0x4E 0xEF
INI 0x4F 0x99