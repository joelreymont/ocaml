# DWARF Debug Information: Known Limitations

## Multi-Object Linking on Mach-O (macOS)

**Status**: Known limitation
**Severity**: High
**Affects**: macOS/Mach-O targets with multi-object compilations
**Workaround**: Use dsymutil or single-file compilations

### Description

When linking multiple object files on macOS, DW_AT_stmt_list offsets in compilation units may point to incorrect locations in the merged .debug_line section.

### Technical Details

On ELF targets (Linux), the linker properly adjusts section-relative offsets when merging DWARF debug sections from multiple object files. For example:

- Object A: CU has DW_AT_stmt_list = 0x0000 → points to start of line table A
- Object B: CU has DW_AT_stmt_list = 0x0000 → points to start of line table B
- After linking: Object B's CU has DW_AT_stmt_list updated to 0x0100 (or wherever line table B now starts)

On Mach-O targets (macOS), the current implementation emits:
```assembly
.long Ldebug_line_cu_1    # Creates relocation, but...
```

The Mach-O linker resolves this relocation, but does NOT convert it to a section-relative offset in the same way ELF linkers do. This results in all compilation units pointing to offset 0x0000 after linking.

### Root Cause

The issue is in `asmcomp/emitaux.ml:656-671` where `emit_section_bytes_with_both_relocs` handles `Sec_offset_reloc`:

```ocaml
| Sec_offset_reloc r ->
    let label = r.Dwarf_world.label in
    if Config.system = "linux" || Config.system = "gnu" || Config.system = "macosx" then begin
      (* Emit label directly - works on ELF, but NOT on Mach-O for multi-object *)
      Printf.fprintf oc "\t.long %s\n" label
    end
```

On Mach-O, this creates an address relocation rather than a section-offset relocation, causing incorrect DW_AT_stmt_list values after linking.

### Impact

- Debuggers may show incorrect source file mappings
- Line number information may be wrong for modules other than the first
- Breakpoints may not work correctly

### Workarounds

1. **Use dsymutil** (recommended for macOS):
   ```bash
   ocamlopt -g -o program file1.ml file2.ml
   dsymutil program
   ```
   The dsymutil tool post-processes the binary and creates a correct .dSYM bundle with fixed offsets.

2. **Single-file compilations**: Compile all modules together in one command to avoid multi-object linking.

3. **ELF targets**: Use Linux or other ELF-based targets where relocations work correctly.

### Proper Fix (Future Work)

A proper fix would require one of:

1. **Mach-O section-offset relocations**: Emit special assembler directives that create true section-relative relocations:
   ```assembly
   .long Ldebug_line_cu_1 - Ldebug_line_section_start
   ```
   But this requires the section start label to be global across object files, which is non-trivial.

2. **Post-link DWARF processing**: Integrate dsymutil-like functionality into the OCaml build process automatically.

3. **Inline line tables**: Eliminate DW_AT_stmt_list entirely by embedding line tables inline in each CU. This would require significant architectural changes to `dwarf_world.ml`.

4. **Use DWARFv5 split DWARF**: Use the .dwo file format where debug info stays in separate files, avoiding the multi-object linking issue entirely.

## Architecture Support

**Verified architectures**: AMD64, ARM64
**Other architectures**: May have incorrect register numbers

### Description

Architectures without a proper `dwarf_reg_map.ml` module will use identity mapping for register numbers, which may not match the architecture's DWARF ABI specification.

### Affected Code

- `asmcomp/amd64/dwarf_reg_map.ml` - AMD64 register mapping (complete)
- `asmcomp/arm64/dwarf_reg_map.ml` - ARM64 register mapping (complete)
- Other architectures - Use default identity mapping (likely incorrect)

### Impact

- `DW_AT_frame_base` may use wrong register number
- Parameter locations (`DW_OP_reg*`) may be incorrect
- Debuggers may show wrong values for variables

### Detection

The compiler warns when compiling for unverified architectures:
```
Warning: DWARF support for architecture 'riscv' uses default register mapping.
Register numbers and frame pointer may be incorrect. Verified architectures: amd64, arm64
```

### Tests

- `testsuite/tests/asmcomp/dwarf/validate_arch_registers.sh` validates register mappings
- `testsuite/tests/asmcomp/dwarf/comprehensive_dwarf.ml` runs architecture validation

## Test Coverage

Comprehensive DWARF testing includes:

1. **Structure validation** (`inspect_dwarf.sh`):
   - Validates .debug_info, .debug_line, .debug_abbrev sections exist
   - Checks DW_AT_language is not truncated (0x8001, not 0x0001)
   - Validates DW_AT_frame_base exists in subprograms
   - Checks address size matches target architecture
   - Verifies base types and compilation units present

2. **Multi-object validation** (`multi_obj_dwarf_test.sh`):
   - Tests linking multiple object files
   - Validates DW_AT_stmt_list offsets (detects Mach-O issue)
   - Checks line table coverage for all modules
   - Documents known Mach-O limitation

3. **Architecture validation** (`validate_arch_registers.sh`):
   - Validates frame pointer register numbers
   - Checks parameter location expressions
   - Verifies register mappings match DWARF ABI for target arch

4. **Relocation inspection** (in `inspect_dwarf.sh`):
   - Checks for debug section relocations on ELF
   - Validates relocation types on Mach-O

## References

- DWARF 5 Standard: http://dwarfstd.org/
- AMD64 ABI: https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf
- ARM64 DWARF Register Mapping: https://github.com/ARM-software/abi-aa/blob/main/aadwarf64/aadwarf64.rst
- Mach-O File Format: https://github.com/aidansteele/osx-abi-macho-file-format-reference
