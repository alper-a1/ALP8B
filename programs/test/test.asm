LDI R0 0x01
LDI R1 0x02
loop_add_2:
ADC R0 R1
JMP loop_add_2