# DWARF String Table Multi-CU Investigation

## Executive Summary

**Problem**: The DWARF string table implementation works for single compilation units but breaks when linking multiple .o files together.

**Root Cause**: The macOS linker (ld64) crashes with a segmentation fault when processing section-relative relocations (`Ldebug_str_start+offset`) in DWARF sections. This crash appears to be a bug or limitation in the macOS ARM64 toolchain.

**Status**: The crash has been reproduced and thoroughly investigated. Multiple alternative approaches have been evaluated.

---

## Problem Description

### Current Implementation

The current implementation uses **plain numeric offsets** for string table references:

```assembly
.section __DWARF,__debug_info,regular,debug
    .long 29    # Plain offset into string table
    .long 57    # Another plain offset
```

**This works for single-CU debugging** because:
- Each .o file has its own .debug_str section starting at offset 0
- String references are relative to that file's string table
- Single-file programs only have one string table

**This breaks for multi-CU debugging** because:
- The linker concatenates all .debug_str sections into one merged section
- Module 1's strings are at offsets 0-100
- Module 2's strings are at offsets 101-200
- But Module 2's .debug_info still references offset 0 (now pointing to Module 1's first string)

---

## Investigation Results

### Attempt 1: Section-Relative Relocations

**Approach**: Emit section-relative relocations so the linker can adjust offsets when merging sections.

```ocaml
(* In emitaux.ml *)
Printf.fprintf oc "\t.long Ldebug_str_start+%d\n" str_offset;
```

**Generated Assembly**:
```assembly
.section __DWARF,__debug_info,regular,debug
    .long Ldebug_str_start+29
    .long Ldebug_str_start+57
```

**Object File Relocations**:
```
$ otool -rv camlstartup.o
Relocation information (__DWARF,__debug_info) 1276 entries
address  pcrel length extern type    scattered symbolnum/value
00004100 False long   False  UNSIGND False     5 (__DWARF,__debug_str)
000040f5 False long   False  UNSIGND False     5 (__DWARF,__debug_str)
[... 1274 more ...]
```

**Result**: ✗ **LINKER SEGMENTATION FAULT**

```
clang: error: unable to execute command: Segmentation fault: 11
clang: error: linker command failed due to signal (use -v to see invocation)
Linker snapshot: /var/folders/.../T/linker-crash-d1fcba
```

### Analysis of the Crash

1. **Scale**: The OCaml compiler's startup object file alone has 1,276 section-relative relocations to .debug_str
2. **Toolchain**: macOS Clang 17.0.0 with ld64 on ARM64
3. **Reproducibility**: 100% reproducible when building ocamlopt.opt
4. **Scope**: Simple test cases (< 10 relocations) work fine; the crash appears with high relocation counts

### Attempt 2: Label Subtraction (Standard DWARF)

**Approach**: Use standard DWARF approach with label arithmetic.

```assembly
.section __DWARF,__debug_info,regular,debug
    .long Lstr_5 - Ldebug_str_start
```

**Result**: ✗ **Assembler resolves this at assembly time**

The assembler evaluates `Lstr_5 - Ldebug_str_start` to a plain numeric constant before the linker ever sees it. No relocation is emitted, so we're back to the original problem.

### Attempt 3: Direct Label References

**Approach**: Reference string labels directly.

```assembly
.section __DWARF,__debug_info,regular,debug
    .quad Lstr_5    # 8-byte pointer
```

**Result**: ✗ **Wrong size for DWARF format**

- DW_FORM_strp requires a 4-byte offset
- Direct label references produce 8-byte pointers
- This violates the DWARF v4 specification

---

## Alternative Solutions

### Solution 1: Use DW_FORM_string (Inline Strings) ✓ VIABLE

**Description**: Instead of using DW_FORM_strp (string table offsets), use DW_FORM_string (inline strings) for all string attributes.

**Changes Required**:
```ocaml
(* In standard_abbrevs.ml, change all: *)
(DW_AT_name, DW_FORM_strp);
(* To: *)
(DW_AT_name, DW_FORM_string);
```

**Pros**:
- ✓ No relocations needed
- ✓ Works perfectly across multiple CUs
- ✓ Simple implementation (already supported)
- ✓ Standard DWARF approach

**Cons**:
- ✗ Larger .debug_info sections (strings duplicated)
- ✗ No string deduplication across CUs
- ✗ Slightly slower linking (more data to process)

**Size Impact Estimate**:
- Current: 4 bytes per string reference
- With inline strings: ~15-50 bytes per string reference (avg ~25 bytes)
- For 1,276 string refs: 5KB → 32KB (~27KB increase)
- Acceptable trade-off for correctness

**Implementation Effort**: Low (< 1 hour)

### Solution 2: Use DWARF 5 DW_FORM_strx ⚠ COMPLEX

**Description**: DWARF 5 introduces an indirect string index approach that might work better with linkers.

**How It Works**:
1. Create a .debug_str_offsets section with 4-byte offsets into .debug_str
2. .debug_info contains indices (not offsets) into .debug_str_offsets
3. Linker only needs to fix up .debug_str_offsets (one relocation per unique string)

**Pros**:
- ✓ Reduces number of relocations
- ✓ Modern DWARF 5 approach

**Cons**:
- ✗ Requires DWARF 5 (currently using DWARF 4)
- ✗ Complex implementation (new section, new formats)
- ✗ May still hit the same linker bug (unknown)

**Implementation Effort**: High (1-2 days)

### Solution 3: Post-Link DWARF Fixer Tool ⚠ COMPLEX

**Description**: Accept broken multi-CU DWARF, provide a post-processing tool to fix it.

**How It Works**:
1. Link binary with broken string offsets
2. Run tool that:
   - Parses .debug_str merged section
   - Parses each CU's .debug_info
   - Calculates correct offsets
   - Patches .debug_info in place

**Pros**:
- ✓ No changes to compiler
- ✓ Allows using DW_FORM_strp

**Cons**:
- ✗ Requires separate tool development
- ✗ Extra build step for users
- ✗ Complex DWARF parsing/patching
- ✗ Fragile (binary patching)

**Implementation Effort**: Very High (3-5 days)

### Solution 4: External String Labels with Linker Script ✗ NOT VIABLE

**Description**: Create global symbols for each string position and use linker script to deduplicate.

**Cons**:
- ✗ Not portable (linker script syntax varies)
- ✗ Very complex
- ✗ May pollute symbol table

---

## Recommendation

**Use DW_FORM_string (Solution 1)** for the following reasons:

1. **Correctness**: Guaranteed to work across all scenarios
2. **Simplicity**: Minimal code changes, leverages existing implementation
3. **Portability**: Standard DWARF approach, works on all platforms
4. **Size Impact**: ~27KB increase per large module is acceptable trade-off
5. **User Experience**: No additional tools or build steps required

The size increase is negligible compared to:
- Text section: typically MB-scale
- Debug info overall: The strings are already in .debug_str, just being duplicated
- Modern disk sizes: KB-scale increases are insignificant

---

## Technical Details

### DWARF String Forms Comparison

| Form | Size | Relocations | Multi-CU | Dedup |
|------|------|-------------|----------|-------|
| DW_FORM_strp (current) | 4B | Yes (crashes) | ✗ | ✓ |
| DW_FORM_string (proposed) | ~25B avg | No | ✓ | ✗ |
| DW_FORM_strx (DWARF 5) | 1-4B | Yes (unknown) | ? | ✓ |

### Linker Crash Details

**Crash Location**: During final link of ocamlopt.opt
**Crash Type**: Segmentation fault: 11
**Affected Files**: All .o files with DWARF debug info
**Relocation Count**: 1,276 string table relocations in camlstartup.o alone
**Platform**: macOS 25.1.0, Apple Clang 17.0.0, ARM64

**Linker Snapshot**: Available in /var/folders/.../T/linker-crash-*

### Simple Test Cases

Simple assembly with < 10 section-relative relocations links successfully:

```assembly
.section __DWARF,__debug_info,regular,debug
    .long Ldebug_str_start+0
    .long Ldebug_str_start+10
```

This suggests the crash is triggered by:
- High relocation count in DWARF sections, OR
- Specific relocation patterns, OR
- Cumulative size of relocated data

---

## Next Steps

1. **Immediate**: Document current limitation (already done in code comments)
2. **Short-term**: Implement DW_FORM_string switch (recommended)
3. **Long-term**: Monitor for macOS toolchain updates that fix the linker crash

---

## References

- DWARF v4 Specification: http://dwarfstd.org/doc/DWARF4.pdf
  - Section 7.5.4: String Table (.debug_str)
  - Section 7.5.5: Attribute Encodings (DW_FORM_*)
- Apple Linker (ld64): Open source but complex relocation handling
- Mach-O Relocations: Documented in mach-o/reloc.h

---

## Appendix: Reproduction Steps

1. Modify `asmcomp/emitaux.ml:644`:
   ```ocaml
   Printf.fprintf oc "\t.long Ldebug_str_start+%d\n" str_offset;
   ```

2. Build compiler:
   ```bash
   make ocamlopt.opt
   ```

3. Observe crash during final link:
   ```
   clang: error: unable to execute command: Segmentation fault: 11
   ```

4. Revert change:
   ```ocaml
   Printf.fprintf oc "\t.long %d\n" str_offset;
   ```

5. Rebuild successfully.
