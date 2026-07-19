; 16 bit fibonacci numbers. calculates the first 25 terms 
; (after the 25th term, numbers exceed unsigned 16bit integer limit)
; PREV will reference the HEAD-1 (second largest) fib number
; HEAD will reference the HEAD (current largest) fib number
; NEXT will reference the next fib number 
; HI - top 8bits, LO - bottom 8bits


; SETUP
LDI R2 0xB1         ; seed R2 with PREV LO
LDI R3 0xB3         ; seed R3 with HEAD LO

; CALC LOOP
loop:
LDM R0 R2           ; load PREV LO
LDM R1 R3           ; load HEAD LO
CLC                 ; dont want to use carry for lower 8 addition
ADC R1 R0           ; R1 stores NEXT LO, FLGS set
INC R3          
INC R3              ; move R3 to point to NEXT LO 
STM R1 R3           ; store NEXT LO
DEC R2              ; R2 points to PREV HI
LDM R0 R2           ; load PREV HI to R0
INC R2
INC R2              ; R2 points to HEAD HI
LDM R1 R2           ; load HEAD HI to R1
ADC R1 R0           ; do HI addition (with carry from LO addition)
                    ; will produce carry=1 if next fib num > int16max
JGT done            ; if carry=1, dont write HI and jump done
INC R2
INC R2              ; R2 points to NEXT HI
STM R1 R2           ; store NEXT HI
DEC R2              ; R2 points to HEAD LO 
                    ; R3 is now at new HEAD (current NEXT) LO
                    ; R2 is now at new PREV (current HEAD) LO
JMP loop            ; ready to calc next fibnum

; CLEANUP / END
done:
XOR R0 R0           ; clear R0
STM R0 R3           ; wipe garbage from out of bounds LO

; busyloop (or HLT)
infloop:
JMP infloop

; DATA SECTION (seed of fibonacci sequence)
; will start at address 0xB0 onwards. 64 byte space, 50 will be filled
; byte order of fib numbers stored HI8/LO8 sequence, little endian

INI 0xB0 0x00 ; seed value 0 HI byte
INI 0xB1 0x00 ; seed value 0 LO byte
INI 0xB2 0x00 ; seed value 1 HI byte
INI 0xB3 0x01 ; seed value 1 LO byte 