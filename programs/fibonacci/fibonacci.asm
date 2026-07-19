LDI R0 2
LDI R1 1
LDI R2 0xEF
LDI R3 0xF9    ; target end address (0xEF + 10)

; store the initial '2' before we start doing math (fib numbers from >2)
INC R2
STM R0 R2

; calculate the 9 fibonacci numbers after 2, in an alternating addition method
fibloop: 
CMP R2 R3      ; have we reached address 0xF9?
JEQ done

INC R2         ; increment pointer for storing next fib
CMP R0 R1
JLT a_lt_b

CLC            ; clear the left over carry from CMP
ADC R1 R0
STM R1 R2
JMP fibloop

a_lt_b:        
CLC            ; clear the left over carry from CMP
ADC R0 R1

STM R0 R2
JMP fibloop

; inf loop to end program (or HLT)
done:
JMP done