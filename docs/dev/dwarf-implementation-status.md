# DWARF Implementation Status

## Summary

OCaml now has partial DWARF v5 debugging support with function-level debugging working correctly. Line-level debugging has a known issue with multi-CU linking that needs to be resolved.

## What Works ✅

### Function Breakpoints
- **GDB**: `break camlSimple.calculate_274` works correctly
- **LLDB**: `breakpoint set --name camlSimple.calculate_274` works correctly
- Full backtraces with OCaml function names
- Source file information (DW_AT_decl_file) properly linked

### DWARF Structure
- Inline string support (DW_FORM_string) - no string table relocations needed
- Proper compilation unit DIEs with metadata
- Function subprogram DIEs with address ranges
- Source file attribution for all functions
- Correct source filename handling (uses actual filename, not capitalized module name)

### Test Coverage
Tests that **PASS**:
- `basic.ml` - Basic DWARF emission
- `dwarf_func_gdb.ml` - GDB function breakpoints ✅
- `dwarf_func_lldb_linux.ml` - LLDB function breakpoints (Linux) ✅
- `dwarf_func_lldb_macos.ml` - LLDB function breakpoints (macOS) ✅ (skipped in CI)
- `functions.ml` - Function DWARF structure
- `types.ml` - Type DWARF structure

## Known Issues ❌

### Line-Based Breakpoints Not Working

**Symptom**: Commands like `break simple.ml:2` fail with "No line 2 in file simple.ml"

**Root Cause**: The `DW_AT_stmt_list` attribute in compilation unit DIEs is hardcoded to offset 0. When linking multiple object files together, the linker concatenates `.debug_line` sections but doesn't update these offsets. This causes all CUs to point to the first (often empty) line table.

**Example**:
```
# In final binary after linking:
Offset 0x0:   caml_startup line table (empty)
Offset 0x1d:  std_exit.ml line table
Offset 0x77:  simple.ml line table

# But all CUs have:
DW_AT_stmt_list: 0   # All point to offset 0!
```

**Affected Tests** (all fail with same root cause):
- `dwarf_gdb.ml` - GDB line breakpoints
- `dwarf_line_gdb.ml` - GDB line breakpoints (explicit test)
- `dwarf_line_lldb_linux.ml` - LLDB line breakpoints (Linux)
- `dwarf_lldb_linux.ml` - LLDB line breakpoints

**Technical Details**:
- Individual `.o` files have correct line tables at offset 0
- The problem occurs during linking when multiple `.o` files are combined
- Need to emit relocations for `DW_AT_stmt_list` so the linker can update offsets

**Fix Required**:
1. **Short term**: Emit a relocation for the `DW_AT_stmt_list` attribute that references the beginning of the `.debug_line` section
2. **Implementation**: Modify `dwarf_world.ml` to track line table section labels and emit proper relocations
3. **Testing**: Verify that linked binaries have correct `DW_AT_stmt_list` values

## Implementation Details

### Source Filename Fix
Fixed critical bug in `emit.mlp` (both amd64 and arm64):
- **Before**: Used capitalized module name (`Simple.ml`)
- **After**: Uses actual filename from `Location.input_name` (`simple.ml`)
- This ensures debuggers can find source files correctly

### String Table Workaround
- Uses `DW_FORM_string` (inline) instead of `DW_FORM_strp` (string table)
- Avoids macOS linker crash with section-relative relocations
- See `docs/dev/dwarf-macos-linker-issue.md` for details

### Test Infrastructure
- Added GDB process ID sanitization in `sanitize.awk`
- Created function breakpoint test scripts (`gdb_func_script`, `lldb_func_script`)
- Reference files for new tests

## Next Steps

### Priority 1: Fix Line Table Offsets
**Goal**: Make line-based breakpoints work

**Tasks**:
1. Modify `dwarf_world.ml` to emit section-relative relocations for `DW_AT_stmt_list`
2. Create a label at the start of each CU's `.debug_line` contribution
3. Update `DW_AT_stmt_list` to reference the label instead of hardcoded 0
4. Verify with multi-CU test case (compile multiple .ml files, link, test)

**Estimated Complexity**: Medium (2-4 hours)
**Blocking**: Line-based debugging functionality

### Priority 2: Enhanced Line Information
**Goal**: Richer debugging experience

**Tasks**:
1. Emit column information for better breakpoint precision
2. Add `is_stmt` flags to mark statement boundaries
3. Implement `basic_block` and `prologue_end` markers
4. Test with complex control flow (if/match/try expressions)

**Estimated Complexity**: Low (1-2 hours)
**Blocking**: None (enhancement)

### Priority 3: Variable Locations
**Goal**: Inspect OCaml variables in debugger

**Tasks**:
1. Implement DW_AT_location for function parameters
2. Add local variable DIEs with location expressions
3. Handle register allocations and stack slots
4. Test variable inspection with `print x` in GDB

**Estimated Complexity**: High (8-16 hours)
**Blocking**: Variable inspection feature

## File Locations

### Core Implementation
- `asmcomp/debug/dwarf/` - DWARF generation library
  - `dwarf_high/dwarf_world.ml` - High-level DWARF world (CUs, DIEs, line tables)
  - `dwarf_ocaml/dwarf.ml` - OCaml-specific DWARF generation
  - `dwarf_low/` - Low-level DWARF encoding
- `asmcomp/amd64/emit.mlp` - AMD64 backend integration
- `asmcomp/arm64/emit.mlp` - ARM64 backend integration
- `asmcomp/emitaux.ml` - DWARF helpers and emission

### Tests
- `testsuite/tests/asmcomp/dwarf/` - DWARF test suite
  - `dwarf_func_*.ml` - Function breakpoint tests (WORKING)
  - `dwarf_line_*.ml` - Line breakpoint tests (BROKEN)
  - `functions.ml`, `types.ml` - Structure tests
  - `gdb_func_script`, `lldb_func_script` - Debugger test scripts

### Documentation
- `docs/dev/dwarf-macos-linker-issue.md` - macOS linker crash details
- `docs/dev/dwarf-implementation-status.md` - This file

## References

- DWARF v5 Specification: http://dwarfstd.org/
- OCaml DWARF PR discussions
- GDB documentation: https://sourceware.org/gdb/current/onlinedocs/gdb/
- LLDB documentation: https://lldb.llvm.org/

## Revision History

- 2025-11-14: Initial status document
  - Function breakpoints working
  - Line breakpoints broken (DW_AT_stmt_list offset issue)
  - macOS linker workaround documented
