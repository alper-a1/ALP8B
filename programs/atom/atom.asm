; 'atom' program with its own program code in the center of memory space
; the program handles its own two electrons as they orbit their own program code

; bootstrap jump into the nucleus
JMP row_1

; 10 rows of 10 bytes of instruction bytes
; the 'nucleus' is 100 bytes large (-20 for JMP boilerplate)

; row 1 0x33 - 0x3C -- boostrap wipe & memory mapped variables
PCS 0x33        
row_1:
XOR R1 R1       ; CLR R1
XOR R2 R2       ; CLR R2
STM R1 R2       ; overwrite the bootstrap jump with 0
INC R2          ;
STM R1 R2       ; overwrite the bootstrap jump imm8 with 0
JMP loop        ; jump past memory mapped vars
; mem mapped vars 1: 
INI !0x3A 0x11  ; 0x3A = pos; starts at top left
INI !0x3B 0x43  ; 0x3B = pointer current direction var; starts poiting to top left velocity
INI !0x3C 12    ; 0x3C = loop counter

; row 2 0x43 - 0x4C
PCS 0x47    
; mem mapped vars 2: direction values
; (based off ram hex grid starting 0x00 top left)    
INI !0x43 1     ; +1,  left -> right
INI !0x44 16    ; +16, top -> bottom
INI !0x45 0xFF  ; -1,  right -> left
INI !0x46 0xF0  ; -16, bottom -> top
loop:
LDI R0 0x3A     ; point to pos var
LDM R1 R0       ; R1 = pos
XOR R2 R2       ; CLR R2
JMP row_3

; row 3 0x53 - 0x5C
PCS 0x53       
row_3:
STM R2 R1       ; clear old electron
DEC R2          ; underflow R2 = 0xFF
XOR R1 R2       ; xor pos to get clone pos
INC R2          ; overflow R2 = 0
STM R2 R1       ; write a 0 at clone pos
DEC R2          ; underflow R2 = 0xFF
XOR R1 R2       ; xor clone pos to get normal pos back again
INC R0          ; point to direction pointer
JMP row_4

; row 4 0x63 - 0x6C
PCS 0x63  
row_4:
LDM R3 R0       ; R3 = direction pointer
LDM R2 R3       ; R2 = velocity value
CLC
ADC R1 R2       ; add velocity to pos
DEC R0          ; point back to pos var
STM R1 R0       ; save new pos
LDI R3 0xAA     ; load electron value
JMP row_5

; row 5 0x73 - 0x7C
PCS 0x73  
row_5:
STM R3 R1       ; write first electron
LDI R2 0xFF     
XOR R1 R2       ; get clone electron pos
STM R3 R1       ; write clone electron
LDI R0 0x3C     ; point to loop counter
LDM R1 R0       ; R1 = loop counter
JMP row_6

; row 6 0x83 - 0x8C
PCS 0x83  
row_6:
XOR R2 R2       ; CLR R2
CMP R1 R2       ; check if loop counter == 0
                ; if it is, need to change direction & reset it
JEQ next_direction  
DEC R1                 
STM R1 R0       ; store loopcounter - 1
                ; R2 must equal 0 before jumping into busyloop_init
LDI R3 20       ; R3 must be set to XX cycles before jumping into busyloop_init
JMP busyloop    ; row_7 also start of busyloop

; row 7 0x93 - 0x9C
PCS 0x93     
busyloop:
DEC R3
CMP R2 R3       ; check if countdown has hit 0
JEQ loop        ; restart if countdown == 0
JMP busyloop    ; else continue busy loop
next_direction:
LDI R3 12       ; load refreshed loop count #
JMP row_8

; row 8 0xA3 - 0xAC
PCS 0xA3    
row_8:
STM R3 R0       ; store refreshed loop counter
DEC R0          ; point to direction pointer
LDM R1 R0       ; R1 = direction pointer
LDI R3 0x46     ; R3 = address of final direction var
CMP R1 R3       ; if current direction pointer == last direction, wrap around to start otherwise add 1
JEQ reset_dir_pointer
JMP row_9

; row 9 0xB3 - 0xBC
PCS 0xB3      
row_9:
INC R1
STM R1 R0       ; move dir pointer forwad and save
XOR R2 R2       
LDI R3 10       ; init R2/R3 for busy loop
JMP busyloop
INI !0xBA 0xC0
INI !0xBB 0xFF
INI !0xBC 0xEE

; row 10 0xC3 - 0xCC
PCS 0xC3      
reset_dir_pointer:
LDI R3 0x43     ; address of first dir velo var
STM R3 R0       ; store refreshed address
XOR R2 R2      
LDI R3 8        ; init R2/R3 for busy loop
JMP busyloop
INI !0xCB 0xBE
INI !0xCC 0xEF
