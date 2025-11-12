# DWARF Support for macOS ARM64 (Apple Silicon)

## Overview

This document describes platform-specific considerations for DWARF debugging information on macOS ARM64 (Apple Silicon M1/M2/M3).

## Architecture Differences

### ARM64 vs x86_64

| Feature | ARM64 | x86_64 |
|---------|-------|--------|
| Register Count | 31 general (x0-x30) + SP, PC | 16 general (rax-r15) + rsp, rip |
| Register Size | 64-bit | 64-bit |
| Calling Convention | ARM64 ABI | System V AMD64 ABI |
| Argument Registers | x0-x7 | rdi, rsi, rdx, rcx, r8, r9 |
| Return Register | x0 | rax |
| Frame Pointer | x29 (fp) | rbp |
| Stack Pointer | x31 (sp) | rsp |
| Link Register | x30 (lr) | Return address on stack |

### DWARF Register Mapping (ARM64)

According to the DWARF for ARM64 ABI:

```
DW_OP_reg0  to DW_OP_reg30  → x0 to x30
DW_OP_reg31 → SP (stack pointer)
DW_OP_reg32 → PC (program counter)
DW_OP_reg33 → ELR_EL1 (exception link register)
DW_OP_reg34-DW_OP_reg63 → V0-V29 (SIMD/FP registers)
```

For location expressions:
- `DW_OP_breg29` → Frame pointer relative (x29/fp)
- `DW_OP_breg31` → Stack pointer relative (SP)

## macOS-Specific Features

### Mach-O Format

Unlike Linux (ELF), macOS uses Mach-O:
- DWARF sections prefixed with `__debug_` in `__DWARF` segment
- Section names: `__debug_info`, `__debug_line`, etc.
- Use `otool -l` to inspect sections
- Use `dwarfdump` or `llvm-dwarfdump` to read DWARF

### Tools on macOS

**DWARF Inspection:**
```bash
# Apple's dwarfdump
dwarfdump binary

# LLVM's dwarfdump (from Xcode)
llvm-dwarfdump binary

# Check Mach-O sections
otool -l binary | grep -A 5 __DWARF

# Symbol table
nm -pa binary
```

**Debugging:**
```bash
# LLDB (primary debugger on macOS)
lldb binary

# GDB (less recommended, requires signing)
gdb binary  # May need: codesign -s - -f --entitlements gdb.xml gdb
```

## Apple Silicon Specifics

### Register Usage in OCaml on ARM64

OCaml's ARM64 backend uses:
- **x0-x7**: Function arguments and temporary values
- **x19-x26**: OCaml domain state and allocation pointer
- **x27**: OCaml trap pointer
- **x28**: Platform register (reserved)
- **x29**: Frame pointer (when using frames)
- **x30**: Link register (return address)
- **SP (x31)**: Stack pointer

### DWARF Location Expressions

For variables on ARM64:
```
Local variable in register x0:
  DW_AT_location: DW_OP_reg0

Local variable at [fp - 16]:
  DW_AT_location: DW_OP_breg29 -16

Parameter passed in x0, spilled to stack:
  DW_AT_location: location list
    [0x1000, 0x1010): DW_OP_reg0
    [0x1010, 0x1100): DW_OP_breg29 -16
```

### Call Frame Information (CFI)

ARM64 CFI instructions:
```
DW_CFA_def_cfa: x29 (fp) offset 0
DW_CFA_offset: x30 (lr) at cfa-8   # Return address
DW_CFA_offset: x29 (fp) at cfa-16  # Saved frame pointer
```

## Testing on Apple Silicon

### Compile for ARM64

```bash
# Ensure native ARM64 compilation
ocamlopt -config | grep ^architecture
# Should show: architecture: arm64

# Compile with debug info
ocamlopt -g -o test test.ml

# Verify ARM64 binary
file test
# Should show: Mach-O 64-bit executable arm64
```

### Verify DWARF Sections

```bash
# Check for DWARF sections
otool -l test | grep -A 5 "__debug_"

# Expected sections:
#   __debug_info     - DIEs
#   __debug_abbrev   - Abbreviation table
#   __debug_line     - Line number information
#   __debug_str      - String table
#   __debug_loc      - Location lists (Phase 4)
#   __debug_ranges   - Range lists (Phase 4)
```

### Debug with LLDB

```bash
lldb test

# Check architecture
(lldb) target list
# Should show arm64

# Set breakpoint
(lldb) b camlTest__entry
(lldb) run

# Inspect ARM64 registers
(lldb) register read
(lldb) register read x0 x1 x2 x3  # First 4 args

# View with DWARF info
(lldb) frame variable
(lldb) frame variable -L  # Show locations

# ARM64-specific register info
(lldb) register read x29  # Frame pointer
(lldb) register read x30  # Link register
(lldb) register read sp   # Stack pointer
```

## Common Issues

### Issue 1: "No debug info available"

**Symptom:** LLDB shows functions but no variables

**Check:**
```bash
# Verify debug sections exist
otool -l test | grep __debug_info

# Check DWARF version
dwarfdump test | head -20
```

**Solution:**
- Ensure `-g` flag used: `ocamlopt -g`
- Verify DWARF emission is enabled (Phase 2+)

### Issue 2: "Optimized out" variables

**Symptom:** Variables show as `<optimized out>`

**Explanation:** OCaml optimizer may eliminate or move variables

**Solutions:**
```bash
# Try less optimization
ocamlopt -g -O0 -o test test.ml

# Or use DWARF location lists (Phase 4) to track movement
```

### Issue 3: Wrong register names

**Symptom:** Debugger shows x86_64 register names (rax, etc.)

**Check:**
```bash
# Verify binary architecture
file test

# Check compilation target
ocamlopt -config | grep ^architecture
```

**Solution:** Ensure compiling natively on ARM64, not via Rosetta 2

### Issue 4: Symbol signing on macOS

**Symptom:** GDB fails with "Operation not permitted"

**Solution:** Use LLDB instead, or sign GDB:
```bash
# Create entitlements.xml
cat > gdb-entitlement.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.debugger</key>
    <true/>
</dict>
</plist>
EOF

# Sign GDB
codesign --entitlements gdb-entitlement.xml -fs gdb-cert $(which gdb)
```

## Performance Considerations

### DWARF Size

DWARF debugging info can increase binary size significantly:
- Debug info: +50-100% typical
- With full type info: +100-200%

### Compilation Time

With full DWARF generation (Phase 4+):
- Expect +10-20% compilation time
- Type shape analysis is most expensive part

## Validation Checklist

For ARM64 macOS DWARF support:

- [ ] Binary is ARM64 Mach-O format
- [ ] `__DWARF` segment present
- [ ] `__debug_info` section exists
- [ ] `__debug_abbrev` section exists
- [ ] `__debug_line` section exists
- [ ] DWARF version is 4 (or later)
- [ ] DW_LANG_OCaml language tag present
- [ ] DIEs for functions present
- [ ] DIEs for variables present (Phase 4+)
- [ ] Location lists use ARM64 registers (Phase 4+)
- [ ] ARM64 calling convention followed
- [ ] LLDB can set breakpoints
- [ ] LLDB can inspect variables (Phase 4+)
- [ ] Stack unwinding works correctly

## Future Enhancements

### DWARF 5 on ARM64

DWARF 5 adds:
- Split DWARF (.dwo files)
- Better compression
- Improved location lists
- Type units

### Xcode Integration

Future work could include:
- Xcode project generation
- Xcode debugging support
- Instruments integration
- Proper type display in Xcode UI

## References

- [ARM64 DWARF Register Mapping](https://github.com/ARM-software/abi-aa/blob/main/aadwarf64/aadwarf64.rst)
- [Apple's DWARF Documentation](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/MachOTopics/)
- [LLDB on macOS](https://lldb.llvm.org/)
- [Mach-O File Format](https://github.com/aidansteele/osx-abi-macho-file-format-reference)
- [OCaml ARM64 Backend](https://github.com/ocaml/ocaml/tree/trunk/asmcomp/arm64)

## Contact

For issues specific to ARM64/macOS:
- Check OCaml issue tracker
- Post to OCaml discuss forum
- Tag with: `arm64`, `macos`, `apple-silicon`, `dwarf`
