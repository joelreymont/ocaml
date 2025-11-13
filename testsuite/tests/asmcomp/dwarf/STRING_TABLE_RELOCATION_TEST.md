# DWARF String Table Relocation Test

## Purpose

This test verifies that the DWARF emitter generates proper section-relative
relocations for `DW_FORM_strp` attributes instead of raw 32-bit offsets.

## Why This Matters

When multiple compilation units are linked together, the linker concatenates
their `.debug_str` sections. If we emit raw offsets (e.g., `.long 47`), those
offsets will be incorrect after linking. We must emit section-relative
relocations (e.g., `.long .debug_str+47` on ELF or `.long Ldebug_str_start+47`
on macOS) so the linker can adjust them correctly.

## Test Procedure

### Quick Manual Test

```bash
cd testsuite/tests/asmcomp/dwarf

# Create a simple test file
cat > test_reloc.ml <<'EOF'
let f x = x + 1
EOF

# Compile with DWARF enabled
../../../../runtime/ocamlrun ../../../../ocamlopt -I ../../../../stdlib -g -c test_reloc.ml

# Verify section-relative relocations are present
grep -E "\.long\s+\.debug_str\+[0-9]+" test_reloc.s
```

### Expected Output (ELF/Linux)

You should see lines like:
```assembly
.long .debug_str+0
.long .debug_str+47
.long .debug_str+121
```

### Expected Output (Mach-O/macOS)

You should see lines like:
```assembly
.long Ldebug_str_start+0
.long Ldebug_str_start+47
.long Ldebug_str_start+121
```

### What NOT to See

If you see raw numeric values without section references in the .debug_info
section, that indicates a problem:
```assembly
# BAD - raw offsets (will break after linking):
.long 47
.long 121
```

## Automated Test

Run the test script:
```bash
./test_string_table_asm.sh
```

This script:
1. Compiles a test file with `-g`
2. Verifies `.debug_str` section exists
3. Checks for proper section-relative relocations
4. Validates strings are in the string table

## Implementation Details

The fix involves:

1. **dwarf_world.ml**: Track `str_relocation` records with offsets into both
   `.debug_info` and `.debug_str`

2. **dwarf_world.ml**: `write_attribute_value` emits placeholder zeros for
   `DW_FORM_strp` and records relocations instead of writing raw offsets

3. **emitaux.ml**: `emit_section_bytes_with_both_relocs` emits proper assembly
   directives:
   - ELF: `.long .debug_str+offset`
   - Mach-O: `.long Ldebug_str_start+offset`

## Test Results

**Date**: 2025-11-13
**Platform**: Linux x86_64
**Compiler**: OCaml 5.5.0+dev0

✓ Compilation with `-g` succeeds
✓ `.debug_str` section generated
✓ 8 string relocations found in test output
✓ Relocations use correct format: `.long .debug_str+N`
✓ String table contains expected values (filenames, function names, types)

## Related Issues

This fix addresses the code review comment:
> "The DWARF emitter builds per-CU .debug_str tables and writes raw 32-bit
> offsets for DW_FORM_strp without relocation records. This causes incorrect
> string references after the linker concatenates .debug_str sections."
