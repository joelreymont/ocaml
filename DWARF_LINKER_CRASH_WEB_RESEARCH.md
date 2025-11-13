# DWARF String Table Linker Crash - Web Research Summary

## Search Date: November 13, 2025

## Query Overview
Investigated the macOS linker segmentation fault when using section-relative relocations to `.debug_str` in DWARF debugging sections.

---

## Key Findings

### 1. Apple Linker Transition (Xcode 15+)

**Context**: Apple transitioned from `ld64` (now `ld-classic`) to a new linker called `ld_prime` in Xcode 15.

**Known Issues**:
- The new linker has had multiple bugs causing crashes
- Binaries with weak symbol definitions crashed at runtime on iOS 14/macOS 12 or older
- Particularly impacted C++ projects due to extensive use of weak symbols
- Many issues were fixed in Xcode 15.1

**Workaround Available**:
```bash
# Add to build flags
-Wl,-ld_classic
```

**Current Status (2024)**:
- `-ld_classic` generates deprecation warnings in Xcode 16
- Apple may remove the flag in future releases
- Users encouraged to switch back to `ld_prime` (default)

### 2. DWARF String Table Relocations (Standards Perspective)

**DW_FORM_strp Relocation Requirements**:

From DWARF standards discussions:
- `DW_FORM_strp` references strings in `.debug_str` using 4-byte offsets (DWARF32) or 8-byte offsets (DWARF64)
- **Each occurrence requires a relocation entry** to patch up the references
- When linking multiple object files, linkers merge `.debug_str` sections and must adjust all offsets

**DWARF 5 Improvement (DW_FORM_strx)**:

To reduce relocation count, DWARF 5 introduced:
1. `.debug_str_offsets` section containing offsets into `.debug_str`
2. `DW_FORM_strx` form uses indices (not offsets) into `.debug_str_offsets`
3. **Linker only needs to fix up `.debug_str_offsets`** (one relocation per unique string)
4. Significantly reduces number of relocations needed

**Quote from DWARF discussions**:
> "By removing direct string offsets for strings in .debug_str section, relocations necessary for each occurrence of DW_FORM_strp can be eliminated, with offsets consolidated into a .debug_str_offsets section"

### 3. Split DWARF Constraints

**Key Limitation**:
- `DW_FORM_strp` **cannot be used in `.dwo` files** because they cannot have relocations
- `.dwo` files are not handled by the linker, avoiding relocation work
- This is why Split DWARF uses alternative string forms

### 4. Apple's Unique DWARF Approach

**"Lazy" DWARF Scheme**:

Apple's solution segregates executable linking and debug info linking:
1. DWARF data resides in `.o` files
2. Executables contain **debug maps** with absolute paths to object files
3. Debugger reads DWARF from original `.o` files using the debug map
4. `dsymutil` tool creates bundled `.dSYM` files when needed

**How It Works**:
```
Executable → Debug Map → Points to .o files → Contains DWARF
                    ↓
              dsymutil reads debug map
                    ↓
              Creates .dSYM bundle with relocated DWARF
```

**Impact on Our Issue**:
- Apple's toolchain may have **reduced testing of DWARF section relocations** since they're typically not needed in executables
- This could explain why high volumes of `.debug_str` relocations cause crashes

### 5. Similar Issues Found

**Go Language (2023)**:
- GitHub issue #61229: "cmd/link: issues with Apple's new linker in Xcode 15"
- Various relocation-related crashes with the new linker
- Workarounds involved using `-ld_classic`

**LLD Mach-O (2024)**:
- GitHub issue #97155: Crashes during symbol conversion in `__mod_init_func`
- Fixed with PR #97156
- Shows ongoing relocation handling issues in Apple's toolchain

**LLVM Clang (2024)**:
- Multiple reports of "Segmentation fault: 11" on macOS ARM64
- Particularly with complex compilation scenarios
- Some related to debug information generation

---

## Why Our Specific Issue Isn't Documented

### Probable Reasons:

1. **Apple's DWARF Approach**: Most macOS developers use Apple's debug map approach, not direct DWARF relocations

2. **Scale Threshold**: Simple cases work fine; crashes only occur with high relocation counts (1,276+ in our case)

3. **Uncommon Pattern**: Section-relative relocations to `.debug_str` are uncommon because:
   - GCC/Clang use Apple's debug map approach on macOS
   - Most other toolchains use Split DWARF or `.dwo` files
   - Direct string embedding (DW_FORM_string) avoids relocations entirely

4. **OCaml's Unique Position**: OCaml generates its own DWARF, doesn't use system toolchain conventions

---

## Comparison: Our Approach vs Standard Practices

### Our Implementation (Current):
```assembly
.section __DWARF,__debug_info,regular,debug
    .long 29    # Plain offset (works single-CU, breaks multi-CU)
```

### Our Attempted Fix:
```assembly
.section __DWARF,__debug_info,regular,debug
    .long Ldebug_str_start+29    # Section-relative (CRASHES linker)
```

### Standard GCC/Clang on macOS:
```
# Debug info stays in .o files
# Executable contains debug map pointing to .o files
# No DWARF relocations in final executable
```

### Standard GCC/Clang on Linux:
```assembly
.section .debug_info
    .long Lstr_5 - .debug_str    # Assembler resolves to plain offset
    # OR uses .debug_str_offsets (DWARF 5)
```

### DWARF 5 Approach:
```assembly
.section .debug_str_offsets
    .long offset_to_string_1
    .long offset_to_string_2
    # Only these need relocations (far fewer)

.section .debug_info
    .uleb128 0    # Index into .debug_str_offsets (no relocation)
    .uleb128 1    # Another index (no relocation)
```

---

## Recommended Solutions (Prioritized)

### 1. Use DW_FORM_string (RECOMMENDED - Immediate)
**Pros**:
- ✓ No relocations needed at all
- ✓ Works on all platforms
- ✓ Already implemented in codebase
- ✓ Standard DWARF approach

**Cons**:
- ✗ Larger debug sections (~27KB increase per large module)
- ✗ String duplication across CUs

**Implementation**: 1 hour

### 2. Test with -ld_classic Flag (EXPERIMENTAL)
**Worth Testing**: May bypass the crash if it's specific to `ld_prime`

**Command**:
```bash
# In OCaml build system, add to linker flags:
-Wl,-ld_classic
```

**Risks**:
- Deprecated in Xcode 16
- May have other bugs
- Not a long-term solution

### 3. Implement DWARF 5 DW_FORM_strx (LONG-TERM)
**Benefits**:
- ✓ Reduces relocation count drastically
- ✓ Modern standard approach
- ✓ May avoid hitting whatever threshold causes the crash

**Challenges**:
- ✗ Requires DWARF 5 (currently using v4)
- ✗ Needs `.debug_str_offsets` section implementation
- ✗ Complex changes (1-2 days work)
- ✗ May still hit the same linker bug (unknown)

### 4. Adopt Apple's Debug Map Approach (MAJOR CHANGE)
**Concept**: Emit DWARF into `.o` files, create debug map in executable

**Challenges**:
- ✗ Very large implementation effort
- ✗ macOS-specific
- ✗ Requires deep integration with linker
- ✗ Not portable to other platforms

---

## Technical Analysis: Why the Crash Happens

### Hypothesis:

The macOS ARM64 linker (`ld_prime` or `ld-classic`) has a **bug or limitation** when processing:

1. **High volumes** of section-relative relocations (1,276+ in our case)
2. **In DWARF sections** specifically (not text/data sections)
3. **To the `.debug_str` section** (section index 5 in Mach-O)

### Evidence:

1. **Simple cases work**: < 10 relocations link successfully
2. **Complex cases crash**: OCaml compiler with 1,276+ relocations causes segfault
3. **Platform-specific**: This pattern works on Linux (ELF)
4. **Consistent reproduction**: 100% reproducible with our codebase

### Linker Snapshot Analysis:

```bash
$ otool -rv camlstartup.o | grep "__debug_str" | wc -l
1276

Relocation information (__DWARF,__debug_info) 2280 entries
# 1276 of these are to __debug_str (section 5)
```

The linker snapshot shows:
- All relocations are properly formed
- All target section 5 (`__DWARF,__debug_str`)
- All are `UNSIGND` type, 4-byte (`long`) relocations
- No obvious malformation

**Conclusion**: The crash is likely a **buffer overflow, memory allocation issue, or algorithmic complexity problem** in the linker's DWARF relocation processing code when handling high relocation counts.

---

## Action Items

### Immediate (Today):
1. ✓ Document investigation findings
2. ⏭ Test `-ld_classic` flag as potential workaround
3. ⏭ If `-ld_classic` fails, implement `DW_FORM_string` solution

### Short-term (This Week):
4. ⏭ File bug report with Apple (via Feedback Assistant)
5. ⏭ Consider posting to LLVM Discourse / Apple Developer Forums

### Long-term (Future):
6. ⏭ Monitor for macOS toolchain updates
7. ⏭ Consider DWARF 5 migration when tools mature

---

## References

### DWARF Standards:
- DWARF v4 Specification: http://dwarfstd.org/doc/DWARF4.pdf
- DWARF Issue 130313.1: Indirect string table (Split DWARF)
- DWARF Issue 211102.1: No DW_FORM_strp in .dwo files

### Apple Documentation:
- Apple Developer Forums: Linker tag discussions
- Apple's "Lazy" DWARF Scheme: https://wiki.dwarfstd.org/Apple's_%22Lazy%22_DWARF_Scheme.md
- dsymutil man page

### LLVM/Clang Issues:
- golang/go #61229: Issues with Apple's new linker in Xcode 15
- llvm-project #97155: Symbol table crashes in lld-macho
- llvm-project #52767: Branch relocation out of range errors

### Community Discussions:
- LLVM Discussion Forums: Various DWARF error threads
- Stack Overflow: Multiple ld segfault reports on macOS
- MaskRay's Blog: Distribution of debug information

---

## Conclusion

The linker crash is **real, reproducible, and appears to be a macOS toolchain bug**. While we haven't found exact documentation of this specific issue, we found:

1. **Apple's linker has known bugs** with relocations, particularly in Xcode 15+
2. **High relocation counts in DWARF sections are uncommon** due to Apple's debug map approach
3. **Standard workarounds exist** (`-ld_classic`, though deprecated)
4. **Alternative DWARF forms exist** (`DW_FORM_string`, `DW_FORM_strx`) that avoid the problem entirely

**Recommended path forward**: Implement `DW_FORM_string` for immediate correctness, monitor for toolchain fixes, consider DWARF 5 for future optimization.
