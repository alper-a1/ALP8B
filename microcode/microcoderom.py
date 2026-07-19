# microcode rom builder and source

# final output word (0bVRDS_TPSC)

# control bits (0bVR00_0P00)

VALID_INSTR    = 0b1000_0000 # required on all instructions
T_RESET        = 0b0100_0000 # early reset to time state

# set to 1 to index RAM via MAR (rather than by PC)
# NOTE: setting to 1 alongside DST_ACC_ONLY means that DST_FLGS & DST_ACC are active at once
# (meaning that both ACC and FLGS are write enable)
# using DST_ACC/DST_FLGS with this control bit as 0 means they behave independantly as normal
ADDR_SEL_CFLGS = 0b0000_0100 

# destination write enables (0b00DS_T000)

DST_RA        = 0b0000_0000 
DST_RB        = 0b0000_1000
DST_ACC_ONLY  = 0b0001_0000
DST_FLGS_ONLY = 0b0001_1000
DST_TMP       = 0b0010_0000 
DST_PC        = 0b0010_1000 
DST_MAR       = 0b0011_0000 
DST_RAM       = 0b0011_1000 

# source output enables (0b0000_00SC)

SC_RA   = 0b0000_0000
SC_RB   = 0b0000_0001
SC_ACC  = 0b0000_0010
SC_RAM  = 0b0000_0011

# all instruction categories (based of the top 4 bits)

OPC_SHL_SHR_NOT     = 0b0000
OPC_INC_DEC         = 0b0001
OPC_CMP             = 0b0010
OPC_SUB             = 0b0011
OPC_JMP_JEQ_JLT_JGT = 0b0100
OPC_ADC             = 0b1000
OPC_ORR             = 0b1001
OPC_AND             = 0b1010
OPC_XOR             = 0b1011
OPC_LDM             = 0b1100
OPC_STM             = 0b1101
OPC_MOV             = 0b1110
OPC_LDI             = 0b1111

# time states 
# note that T0&T1 are hardwired and cannot be changed.

T2 = 0b00
T3 = 0b01
T4 = 0b10
T5 = 0b11

# 64 addr spaces (6bit addr)
rom = [0] * 64


def ucode(opcode, t_state, control_word):
    """
    helper function to format opc sequences
    """
    
    # address = (OPC shifted left 2 bits) OR (T-state)
    address = (opcode << 2) | t_state 

    # sanity check that we havent already written to this rom location
    if (rom[address] != 0):
        raise IndexError(f"ERROR: trying to overwrite previously written instruction at {address:06X}\n")
    
    # sore the word in the final rom , make sure it has the validity bit
    rom[address] = control_word | VALID_INSTR

# -------------------------------
# actual microcode rom sequences
# -------------------------------

# OPC_LI (LOAD IMMEDIATE)
ucode(OPC_LDI, T2, DST_RA | SC_RAM)                  # move immediate value PC points to in RAM after T1 into RA
ucode(OPC_LDI, T3, DST_PC)                           # increment past the immediate value to the next instr
ucode(OPC_LDI, T4, T_RESET)              

# OPC_MOVE sequence
ucode(OPC_MOV, T2, DST_RA | SC_RB)                   # move B into A
ucode(OPC_MOV, T3, T_RESET)

# OPC_JMP_JEQ_JLT_JGT
# note: branch taking is handled through hard wiring
ucode(OPC_JMP_JEQ_JLT_JGT, T2, DST_PC | SC_RAM)      # let RAM broadcast its immediate value jump location onto the bus
                                                     # BRANCH_TAKEN hardwired logic takes decides if we take bus val or increment by 1
ucode(OPC_JMP_JEQ_JLT_JGT, T3, T_RESET)

# OPC_LOAD 
ucode(OPC_LDM, T2, DST_MAR | SC_RB)                  # load address value from B into MAR
ucode(OPC_LDM, T3, ADDR_SEL_CFLGS | DST_RA | SC_RAM) # use MAR address to load RAM value into RA
ucode(OPC_LDM, T4, T_RESET)

# OPC_STORE
ucode(OPC_STM, T2, DST_MAR | SC_RB)                  # load address value from B into MAR
ucode(OPC_STM, T3, ADDR_SEL_CFLGS | DST_RAM | SC_RA) # use MAR  address to load RA value into RAM
ucode(OPC_STM, T4, T_RESET)

# all two register aluops - not CMP since that follows different path
ALU2REGOPS = [OPC_ADC, OPC_ORR, OPC_AND, OPC_XOR, OPC_SUB]
for opc in ALU2REGOPS:
    ucode(opc, T2, DST_TMP | SC_RB)                                  # move RB into TMP
    ucode(opc, T3, ADDR_SEL_CFLGS | DST_ACC_ONLY | SC_RA)            # broadcast RA onto bus and save results of aluop to ACC & FLGS
                                                                     # note: aluop sent through hardwire 
    ucode(opc, T4, DST_RA | SC_ACC)                                  # move result of aluop back to RA
    ucode(opc, T5, T_RESET)

# OPC_CMP (two reg aluop without writeback to RA)
ucode(OPC_CMP, T2, DST_TMP | SC_RB)                 # move RB into TMP
ucode(OPC_CMP, T3, DST_FLGS_ONLY | SC_RA)           # broadcast RA onto bus and save results of aluop to FLGS ONLY
                                                    # note: aluop sent through hardwire 
ucode(OPC_CMP, T4, T_RESET)

# 1reg aluops that set flags
ucode(OPC_SHL_SHR_NOT, T2, ADDR_SEL_CFLGS | DST_ACC_ONLY | SC_RB)    # single reg alu ops work from bus input only
ucode(OPC_SHL_SHR_NOT, T3, DST_RB | SC_ACC)                          # move result back to RB
ucode(OPC_SHL_SHR_NOT, T4, T_RESET)     

# 1reg aluops that DO NOT SET flags
ucode(OPC_INC_DEC, T2, DST_ACC_ONLY | SC_RB)        # single reg alu ops work from bus input only
ucode(OPC_INC_DEC, T3, DST_RB | SC_ACC)             # move result back to RB
ucode(OPC_INC_DEC, T4, T_RESET)     


def write_intel_hex(rom_data, filename="microcoderom.hex"):
    """
    Converts a list of byte integers into an Intel HEX file format.
    note: ai generated
    """
    with open(filename, "w") as f:
        chunk_size = 16  # Standard Intel HEX line length
        
        for offset in range(0, len(rom_data), chunk_size):
            chunk = rom_data[offset:offset + chunk_size]
            if not chunk:
                break
                
            byte_count = len(chunk)
            record_type = 0x00  # 00 means Data Record
            
            # Split 16-bit address into high and low bytes for the checksum
            addr_hi = (offset >> 8) & 0xFF
            addr_lo = offset & 0xFF
            
            # Sum all components to calculate the checksum
            total_sum = byte_count + addr_hi + addr_lo + record_type + sum(chunk)
            
            # Intel HEX checksum is the two's complement of the least significant byte of the sum
            checksum = ((~total_sum) + 1) & 0xFF
            
            # Format the data payload as a continuous hex string
            data_hex = "".join(f"{b:02X}" for b in chunk)
            
            # Construct the full record string
            # Format: :[Count][Address][Type][Data][Checksum]
            record = f":{byte_count:02X}{offset:04X}{record_type:02X}{data_hex}{checksum:02X}"
            f.write(record + "\n")
            
        # Write the mandatory End Of File (EOF) record
        # Format: :00000001FF
        f.write(":00000001FF\n")
        
    print(f"Successfully wrote {len(rom_data)} bytes to {filename}")

# write the ROM intel hex file
write_intel_hex(rom)