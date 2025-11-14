# macOS Linker Crash with DWARF String Table Relocations

## Problem Summary

The macOS linker (ld64) crashes when processing Mach-O object files containing DWARF v4/v5 debug information that uses section-relative relocations for the `.debug_str` string table (DW_FORM_strp).

### Error Message
```
ld: in '<object-file>.o', malformed 64-bit a.k.a. x86_64 relocation 13
```

Or the linker may crash/abort without a clear error message.

## Root Cause

The macOS linker does not support section-relative relocations (`X86_64_RELOC_SIGNED` with section reference) in DWARF sections when using DW_FORM_strp. This is a limitation in the ld64 implementation that has existed for years.

### Technical Details

**What happens:**
1. When using DW_FORM_strp, DWARF DIE attributes contain 4-byte offsets into the `.debug_str` section
2. These offsets need to be relocated to point to the correct string table location
3. Standard DWARF uses section-relative relocations: `R_X86_64_32` (ELF) or `X86_64_RELOC_UNSIGNED` (Mach-O)
4. The macOS linker expects absolute relocations for DWARF sections, not section-relative ones

**Why it fails:**
- The linker encounters a relocation type it doesn't know how to handle in the DWARF context
- It either reports "malformed relocation" or crashes during the relocation processing phase
- This affects both DW_FORM_strp (string table pointers) and potentially other section-relative forms

## Workaround Implemented in OCaml

OCaml now uses **DW_FORM_string** instead of DW_FORM_strp for all DWARF string attributes on all platforms. This embeds strings directly inline in the `.debug_info` section, eliminating the need for:
- A separate `.debug_str` section
- String table relocations
- The problematic section-relative relocations

### Implementation Location
- `asmcomp/debug/dwarf/dwarf_high/standard_abbrevs.ml` - Uses DW_FORM_string for all string attributes
- `asmcomp/debug/dwarf/dwarf_high/dwarf_world.ml` - Inline string emission in emit_debug_info

### Trade-offs
- **Advantage**: Works on macOS, Linux, and all platforms without linker issues
- **Advantage**: Simpler relocation model
- **Disadvantage**: Larger `.debug_info` section due to string duplication
- **Disadvantage**: Not using DWARF best practices for string deduplication

## Minimal Reproduction Case

To reproduce the macOS linker crash with DWARF string table relocations:

### 1. Create Test Assembly File

```assembly
# test_dwarf_strp.s
.section __TEXT,__text,regular,pure_instructions
.globl _main
_main:
    movl $42, %eax
    retq

.section __DWARF,__debug_abbrev,regular,debug
Labbrev_begin:
    .byte 1                     # Abbrev code
    .byte 17                    # DW_TAG_compile_unit
    .byte 1                     # DW_CHILDREN_yes
    .byte 37                    # DW_AT_producer
    .byte 14                    # DW_FORM_strp (string table pointer!)
    .byte 3                     # DW_AT_name
    .byte 14                    # DW_FORM_strp
    .byte 0                     # End attributes
    .byte 0
    .byte 0                     # End abbrev table

.section __DWARF,__debug_info,regular,debug
Linfo_begin:
    .long Linfo_end - Linfo_begin - 4  # Length
    .short 4                    # DWARF version 4
    .long 0                     # Abbrev offset
    .byte 8                     # Address size
    .byte 1                     # Abbrev code
    .long Lproducer - Ldebug_str  # DW_AT_producer (section-relative!)
    .long Lfilename - Ldebug_str  # DW_AT_name (section-relative!)
Linfo_end:

.section __DWARF,__debug_str,regular,debug
Ldebug_str:
Lproducer:
    .asciz "Test Producer 1.0"
Lfilename:
    .asciz "test.c"
```

### 2. Assemble and Link

```bash
# This will crash the macOS linker
as -arch x86_64 test_dwarf_strp.s -o test_dwarf_strp.o
ld test_dwarf_strp.o -o test_dwarf_strp -lSystem
```

**Expected result**: Linker crashes or reports malformed relocation error.

### 3. Alternative: Use DW_FORM_string (works)

Change the abbrev table to use DW_FORM_string (0x08) instead of DW_FORM_strp (0x0e), and embed strings directly in `.debug_info`:

```assembly
.section __DWARF,__debug_abbrev,regular,debug
Labbrev_begin:
    .byte 1
    .byte 17
    .byte 1
    .byte 37
    .byte 8                     # DW_FORM_string (inline!)
    .byte 3
    .byte 8                     # DW_FORM_string
    .byte 0
    .byte 0
    .byte 0

.section __DWARF,__debug_info,regular,debug
Linfo_begin:
    .long Linfo_end - Linfo_begin - 4
    .short 4
    .long 0
    .byte 8
    .byte 1
    .asciz "Test Producer 1.0"   # Inline string
    .asciz "test.c"              # Inline string
Linfo_end:
```

This version links successfully on macOS.

## Fixing the LLVM Linker (ld64)

To properly fix this issue in the LLVM/ld64 codebase:

### Key Files to Modify

1. **lld/MachO/Arch/X86_64.cpp**
   - Add support for `X86_64_RELOC_UNSIGNED` in DWARF sections
   - Handle section-relative relocations correctly

2. **lld/MachO/InputSection.cpp**
   - Update relocation processing for debug sections
   - Allow section-relative relocations in `__DWARF` segments

3. **lld/MachO/Writer.cpp**
   - Ensure DWARF sections are written with correct relocation types
   - Handle string table section references

### Implementation Approach

The fix should:
1. Detect when a relocation targets a DWARF section (segment name starts with `__DWARF`)
2. Allow section-relative relocations (X86_64_RELOC_SIGNED, X86_64_RELOC_UNSIGNED) in these sections
3. Properly resolve these relocations to point to the correct offset within the target section
4. Handle both 32-bit and 64-bit DWARF formats

### Testing

After implementing the fix:
1. Compile the minimal reproduction case above - it should link successfully
2. Run `dwarfdump` on the resulting binary - verify string table references are correct
3. Test with `lldb` - ensure debug info loads and displays properly
4. Test with real-world OCaml programs compiled with `-g`

## References

- DWARF v5 specification: http://dwarfstd.org/
- Mach-O relocation types: `/usr/include/mach-o/x86_64/reloc.h`
- LLVM ld64 implementation: https://github.com/llvm/llvm-project/tree/main/lld/MachO
- OCaml DWARF implementation: `asmcomp/debug/dwarf/`

## Notes for LLVM Developers

When working on this fix in a forked LLVM repository:
- The issue affects both the legacy ld64 (Apple's original) and the LLVM lld Mach-O backend
- Focus on the lld implementation as it's actively maintained
- Consider backward compatibility with older object files
- Coordinate with the DWARF and debug info teams for testing

This is a relatively isolated fix that should not affect non-debug code paths.
