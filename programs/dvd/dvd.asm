
init:
1. init the absolute pointer (AP) to start in the center ish
2. init all the physics velocity variables to something diagonal.
3. init the x pos tracker to the x pos of the AP

loop:
1. load the absolute pointer and write a zero in the location
2.  X axis
2.1 CLC+ADC the velocity to x-pos. all velocities are stored as twos compliment
2.2 check if x-pos is out of bounds via CMP X-pos variable with 0 / 16
2.3 if of bounds, flip the direction velocity (via 0 - dir), then add the velocity to the AP , and add to x-pos var again
3.  Y axis
3.1 CLC+ADC the velocity. all velocities are stored as twos compliment
3.2 check if AP is out of bounds via CMP'ing the AP with constants for the top/bottom of the 'screen'
3.3 if the AP is out of bounds, flip the direction velocity (via 0 - dir), then add the velocity again to the AP

4. fetch AP and write a 0xFF to the new AP location.
5. run a DEC loop decrementing the AP value until 0. jump on zero to do the loop again (giving a 255 instruction wait per slot (765 clock cycle wait) if using 0xFF as the val)
6. restart loop

memory mapped variables layout:




REAL PROGRAM:
---

; the 16:9 'screen' will be memory rows 0x60 to 0xE0
; this leaves 96 bytes of instruction space

; initalisation
LDI R0 0xFF     ; R0 bootstrapped to memory address of the AP

; core program loop
loop:
LDM R3 R0           ; load AP 
XOR R1 R1           ; CLR R1
STM R1 R3           ; clear old 'dvd' position
DEC R0              ; point to x-pos var
LDM R1 R0           ; R1 = x-pos
DEC R0              ; point to x-velo var
LDM R2 R0           ; R2 = x-velo
CLC     
ADC R1 R2           ; add x-velo to x-pos
LDI R3 15           ; x-pos max value (right side of screen)
CMP R1 R3           ; check x-pos == 15
JEQ invert_x_velo   ; if at edge, invert velo for a bounce back
XOR R3 R3
CMP R1 R3           ; check x-pos == 0
JEQ invert_x_velo   ; if at edge, invert velo for a bounce back
JMP add_x_to_ap     ; otherwise add to AP & save variables

invert_x_velo:
    NOT R2
    INC R2          ; twos compliment inversion
    CLC
    ADC R1 R2       ; add 1 unit of velocity back to x-pos to prepare for a bounce back

add_x_to_ap:
    CLC 
    ADC R1 R2       ; add x-velo to x-pos
    STM R2 R0       ; store back our new x-velo
    INC R0          ; point to x-pos
    STM R1 R0       ; store back our new x-pos
    INC R0          ; point back at AP
    LDM R3 R0       ; R3 = AP
    CLC
    ADC R3 R2       ; AP += x-velo 
    STM R3 R0       ; store back AP

; y-axis stuff

JMP loop

; memory mapped variables
; 0xFF: absolute pointer (AP)
; 0xFE: x-pos var
; 0xFD: x velocity
; 0xFC: y velocity
INI 0xFF 0xA8
INI 0xFD 0x08
INI 0xFE 1
INI 0xFC 16

; initalisation of leftover memory (to ensure that only the 'screen' memory space has 0s)