#!/usr/bin/env python3
"""Assembler for the ALP8B ISA's assembly language to raw machine code.

Parsing rules:
    - Labels must be on their own line and end with ':' (so no comments on label lines).
    - Anything after a ';' is a comment.
    - Jumps must target a label.
    - INI (initialize memory) directives must appear after the last real
      instruction (either HLT or an infinite loop).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

MEM_SIZE = 256

INSTRS: dict[str, int] = {
    "HLT": 0b00_00_00_00,
    "NOP": 0b00_00_00_01,
    "CLC": 0b00_00_00_10,
    "SEC": 0b00_00_00_11,
    "SHL": 0b00_00_01_00,
    "SHR": 0b00_00_10_00,
    "NOT": 0b00_00_11_00,
    "INC": 0b00_01_00_00,
    "DEC": 0b00_01_01_00,
    "CMP": 0b00_10_00_00,
    "SUB": 0b00_11_00_00,

    "JMP": 0b01_00_00_00,
    "JEQ": 0b01_00_00_01,
    "JLT": 0b01_00_00_10,
    "JGT": 0b01_00_00_11,

    "ADC": 0b10_00_00_00,
    "ORR": 0b10_01_00_00,
    "AND": 0b10_10_00_00,
    "XOR": 0b10_11_00_00,

    "LDM": 0b11_00_00_00,
    "STM": 0b11_01_00_00,
    "MOV": 0b11_10_00_00,
    "LDI": 0b11_11_00_00,
}

# Compiler-only pseudo-instructions (not emitted by the ISA itself).
COMP_INSTRS = ("INI",)

REGISTERS: dict[str, int] = {
    "R0": 0b00,
    "R1": 0b01,
    "R2": 0b10,
    "R3": 0b11,
}

NO_OPERAND_INSTRS = ("HLT", "NOP", "CLC", "SEC")
JUMP_INSTRS = ("JMP", "JEQ", "JLT", "JGT")
SINGLE_REG_INSTRS = ("SHL", "SHR", "NOT", "INC", "DEC")
DOUBLE_REG_INSTRS = ("CMP", "SUB", "ADC", "ORR", "AND", "XOR", "LDM", "STM", "MOV")


class AsmError(Exception):
    """Raised for assembly-time errors (bad syntax, unknown label, etc.)."""


def read_source_lines(path: Path) -> list[str]:
    """Read a source file, stripping comments, whitespace, and blank lines."""
    raw = path.read_text()
    lines = [line.split(";")[0].strip() for line in raw.splitlines()]
    return [line for line in lines if line]


def instr_width(instr: str) -> int:
    """Return how many bytes an instruction occupies in the program image."""
    return 2 if instr in JUMP_INSTRS or instr == "LDI" else 1


def build_label_table(lines: list[str]) -> dict[str, int]:
    """First pass: compute the address of every label."""
    labels: dict[str, int] = {}
    pc = 0
    for line in lines:
        if line.endswith(":"):
            name = line[:-1].strip()
            if name in labels:
                raise AsmError(f"duplicate label: {name!r}")
            labels[name] = pc
        else:
            instr = line.split()[0]
            if instr in INSTRS:
                pc += instr_width(instr)
            # COMP_INSTRS (e.g. INI) don't advance the PC; they write directly.
    return labels


def assemble(lines: list[str], labels: dict[str, int]) -> list[int]:
    """Second pass: emit machine code into a fixed-size memory image."""
    mem = [0] * MEM_SIZE
    pc = 0

    for line in lines:
        if line.endswith(":"):
            continue  # labels emit nothing

        tokens = line.split()
        instr = tokens[0]

        if instr in NO_OPERAND_INSTRS:
            mem[pc] = INSTRS[instr]
            pc += 1

        elif instr in JUMP_INSTRS:
            label = tokens[1]
            if label not in labels:
                raise AsmError(f"undefined label: {label!r}")
            mem[pc] = INSTRS[instr]
            mem[pc + 1] = labels[label]
            pc += 2

        elif instr in SINGLE_REG_INSTRS:
            rb = tokens[1]
            mem[pc] = INSTRS[instr] | REGISTERS[rb]
            pc += 1

        elif instr in DOUBLE_REG_INSTRS:
            ra, rb = tokens[1], tokens[2]
            mem[pc] = INSTRS[instr] | (REGISTERS[ra] << 2) | REGISTERS[rb]
            pc += 1

        elif instr == "LDI":
            ra = tokens[1]
            imm = int(tokens[2], 0)
            
            if imm < 0 or imm >= 256:
                raise AsmError("value error: 'LDI' cannot initialise value outside of 8-bit range")
            
            mem[pc] = INSTRS[instr] | (REGISTERS[ra] << 2)
            mem[pc + 1] = imm
            pc += 2

        elif instr == "INI":
            addr = int(tokens[1], 0)
            val = int(tokens[2], 0)
            
            if addr >= MEM_SIZE:
                raise AsmError("value error: 'INI' cannot initialise out of bounds memory")
            
            if val < 0 or val >= 256:
                raise AsmError("value error: 'INI' cannot initialise value outside of 8-bit range")
            
            if addr <= pc:
                raise AsmError("initalisation error: 'INI' tried to overwrite program memory")
            
            mem[addr] = val
            # PC intentionally not advanced; INI writes directly to memory.

        else:
            raise AsmError(f"unknown instruction: {instr!r}")

    return mem


def write_debug_listing(mem: list[int], path: Path) -> None:
    """Write a human-readable ADDR: HEX [BINARY] listing."""
    with path.open("w") as f:
        for addr, byte in enumerate(mem):
            f.write(f"{addr:02X}: {byte:02X} [{byte:08b}]\n")


def write_intel_hex(mem: list[int], path: Path, chunk_size: int = 16) -> None:
    """Write the program image as Intel HEX (for e.g. the Digital simulator)."""
    with path.open("w") as f:
        for offset in range(0, len(mem), chunk_size):
            chunk = mem[offset:offset + chunk_size]
            if not chunk:
                break

            byte_count = len(chunk)
            record_type = 0x00  # data record
            addr_hi = (offset >> 8) & 0xFF
            addr_lo = offset & 0xFF

            total_sum = byte_count + addr_hi + addr_lo + record_type + sum(chunk)
            checksum = ((~total_sum) + 1) & 0xFF

            data_hex = "".join(f"{b:02X}" for b in chunk)
            f.write(f":{byte_count:02X}{offset:04X}{record_type:02X}{data_hex}{checksum:02X}\n")

        f.write(":00000001FF\n")  # EOF record


def compile_file(source: Path, output_dir: Path | None, chunk_size: int) -> tuple[Path, Path]:
    """Compile a single .asm file, returning (debug_path, hex_path)."""
    lines = read_source_lines(source)
    labels = build_label_table(lines)
    mem = assemble(lines, labels)

    # Default: write outputs next to the source file, preserving its subdir.
    out_dir = output_dir if output_dir is not None else source.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    debug_path = out_dir / source.with_suffix(".debug.txt").name
    hex_path = out_dir / source.with_suffix(".hex").name

    write_debug_listing(mem, debug_path)
    write_intel_hex(mem, hex_path, chunk_size)

    return debug_path, hex_path


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="ALP8B assembler",
        description="Compile ALP8B assembly (.asm) into a debug listing and Intel HEX image.",
    )
    parser.add_argument(
        "sources",
        metavar="FILE",
        type=Path,
        nargs="+",
        help="one or more .asm source files (may live in subdirectories)",
    )
    parser.add_argument(
        "-o", "--output-dir",
        type=Path,
        default=None,
        help="write outputs here instead of next to each source file "
             "(applies to all inputs; default: same directory as each source)",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=16,
        help="bytes per Intel HEX data record (default: 16)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    status = 0

    for source in args.sources:
        if not source.is_file():
            print(f"error: {source}: no such file", file=sys.stderr)
            status = 1
            continue

        try:
            debug_path, hex_path = compile_file(source, args.output_dir, args.chunk_size)
        except AsmError as e:
            print(f"error: {source}: {e}", file=sys.stderr)
            status = 1
            continue

        print(f"{source} -> {debug_path}, {hex_path}")

    return status


if __name__ == "__main__":
    sys.exit(main())