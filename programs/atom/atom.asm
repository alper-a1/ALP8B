; 'atom' program with its own program code in the center of memory space
; the program handles its own two electrons as they orbit their own program code



pos
pos2
loopcounter
electronvalue / temp


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
JMP row_2       ; jump past memory mapped vars
; vars (0x3A, 0x3B, 0x3C)
NOP
NOP
NOP

; row 2 0x43 - 0x4C
PCS 0x43        
row_2:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_3

; row 3 0x53 - 0x5C
PCS 0x53       
row_3:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_4

; row 4 0x63 - 0x6C
PCS 0x63  
row_4:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_5

; row 5 0x73 - 0x7C
PCS 0x73  
row_5:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_6

; row 6 0x83 - 0x8C
PCS 0x83  
row_6:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_7

; row 7 0x93 - 0x9C
PCS 0x93     
row_7:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_8

; row 8 0xA3 - 0xAC
PCS 0xA3    
row_8:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_9

; row 9 0xB3 - 0xBC
PCS 0xB3      
row_9:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_10

; row 10 0xC3 - 0xCC
PCS 0xC3      
row_10:
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
JMP row_2