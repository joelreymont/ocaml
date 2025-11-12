# DWARF String Table Generation Fix

**Date**: 2025-11-12
**Commit**: `4b106d28`
**Branch**: `claude/ocaml-dwarf-macos-011CV1uGdeHWum1FF3CXBfSq`

---

## Problem Identified

### Critical Bug: Empty String Table

The DWARF `.debug_str` section was being emitted as **empty** (`Bytes.empty`), causing catastrophic encoding errors:

```ocaml
(* BEFORE - asmcomp/debug/dwarf/dwarf_high/dwarf_world.ml:118 *)
let emit_debug_str _t =
  (* String table not yet implemented *)
  Bytes.empty
```

### Symptoms

When examining binaries with `readelf --debug-dump=info`, numerous errors appeared:

```
readelf: Warning: DW_FORM_strp offset too big: 0x1000000
readelf: Warning: Bogus end-of-siblings marker detected
readelf: Warning: Corrupt attribute
<10> DW_AT_producer: (indirect string, offset: 0): memprof_young_trigger
```

### Root Cause Analysis

1. **Empty .debug_str Section**: `emit_debug_str()` returned `Bytes.empty`
2. **Empty Offset Map**: `str_offsets = []` in `emit_debug_info()`
3. **Invalid String References**: All `DW_FORM_strp` attributes referenced offset `0`
4. **Linker Merge**: When linking, only C runtime's `.debug_str` section remained
5. **Garbage Strings**: OCaml's DWARF pointed to C runtime strings at offset 0

Example: OCaml's `DW_AT_producer` (should be "OCaml 5.3.0") pointed to offset 0, which in the final binary was "memprof_young_trigger" from the C runtime.

---

## Solution Implemented

### Changes to `dwarf_world.ml`

#### 1. Added `collect_strings()` Function (Lines 118-129)

Recursively collects all strings that use `DW_FORM_strp`:

```ocaml
let rec collect_strings die acc =
  (* Collect strings from this DIE's attributes *)
  let acc = List.fold_left (fun acc (attr : Proto_die.attribute) ->
    match attr.value, attr.form with
    | String s, DW_FORM_strp -> s :: acc
    | _ -> acc
  ) acc (Proto_die.attributes die) in
  (* Recursively collect from children *)
  List.fold_left (fun acc child ->
    collect_strings child acc
  ) acc (Proto_die.children die)
```

**Purpose**: Walks the entire DIE tree collecting all string values that will need entries in `.debug_str`.

#### 2. Added `build_string_table()` Function (Lines 131-143)

Creates the string table with proper offsets:

```ocaml
let build_string_table strings =
  (* Remove duplicates and sort for determinism *)
  let unique_strings = List.sort_uniq String.compare strings in
  let buf = Buffer.create 1024 in
  let offsets = ref [] in
  List.iter (fun s ->
    let offset = Buffer.length buf in
    offsets := (s, offset) :: !offsets;
    Buffer.add_string buf s;
    Buffer.add_char buf '\000'  (* Null terminator *)
  ) unique_strings;
  (Bytes.of_string (Buffer.contents buf), List.rev !offsets)
```

**Key Features**:
- Deduplicates strings (multiple DIEs can reference the same string)
- Sorts for deterministic output
- Null-terminates each string (DWARF v4 requirement)
- Returns both bytes and offset map

**Example Output**:
```
Offset | String
-------|------------------
0      | "OCaml 5.3.0\0"
13     | "add\0"
17     | "test_simple.ml\0"
...
```

#### 3. Updated `emit_debug_str()` (Lines 145-150)

Now actually generates the string table:

```ocaml
let emit_debug_str t =
  let cu = compilation_unit t in
  let cu_with_children = Proto_die.add_children cu (all_dies t) in
  let strings = collect_strings cu_with_children [] in
  let str_bytes, _offsets = build_string_table strings in
  str_bytes
```

#### 4. Updated `emit_debug_info()` (Lines 281-285)

Now uses the string offset map when writing DIEs:

```ocaml
(* BEFORE *)
let str_offsets = [] in

(* AFTER *)
let cu = compilation_unit t in
let cu_with_children = Proto_die.add_children cu (all_dies t) in
let strings = collect_strings cu_with_children [] in
let _str_bytes, str_offsets = build_string_table strings in
```

This ensures that when `write_attribute_value()` processes `DW_FORM_strp` attributes (lines 173-182), it looks up the correct offset:

```ocaml
| DW_FORM_strp, String s ->
    let offset = match List.assoc_opt s str_offsets with
      | Some off -> off
      | None -> 0  (* Fallback to offset 0 *)
    in
    (* Write 4-byte offset in little-endian *)
    for i = 0 to 3 do
      Buffer.add_char buf (Char.chr ((offset lsr (i * 8)) land 0xff))
    done
```

---

## Expected Results

### Before Fix

```bash
$ readelf --string-dump=.debug_str test_simple
String dump of section '.debug_str':
  [     0]  memprof_young_trigger     # C runtime strings only!
  [    16]  exn_handler
  [    22]  memory_order_release
  # ... no OCaml strings ...
```

### After Fix

```bash
$ readelf --string-dump=.debug_str test_simple
String dump of section '.debug_str':
  [     0]  OCaml 5.3.0              # ✅ Correct producer!
  [     c]  /home/user/ocaml         # ✅ Compilation directory!
  [    1d]  test_simple.ml           # ✅ Source file!
  [    2c]  add                       # ✅ Function name!
  [    30]  x                         # ✅ Parameter name!
  [    32]  y                         # ✅ Parameter name!
  # ... plus C runtime strings ...
```

### DWARF Info Dump

```bash
$ readelf --debug-dump=info test_simple
Compilation Unit @ offset 0x0:
  DW_TAG_compile_unit
    DW_AT_producer    : (indirect string, offset: 0x0): OCaml 5.3.0  # ✅ Correct!
    DW_AT_comp_dir    : (indirect string, offset: 0xc): /home/user/ocaml
    DW_AT_name        : (indirect string, offset: 0x1d): test_simple.ml
    DW_AT_language    : 22 (OCaml)

  <1><10>: DW_TAG_subprogram
    DW_AT_name        : (indirect string, offset: 0x2c): add  # ✅ Correct!
    DW_AT_low_pc      : 0x...
    DW_AT_high_pc     : 0x...
```

---

## Compilation Status

### ✅ Successfully Compiles to Bytecode

```
  OCAMLC asmcomp/debug/dwarf/dwarf_high/dwarf_world.cmo
```

The implementation is syntactically correct and type-checks properly.

### ❌ Native Compiler Build Blocked

The full OCaml compiler build (`make world.opt`) fails with pre-existing dependency ordering issues in the DWARF modules:

```
Error (warning 58 [no-cmx-file]): no cmx file was found in path for module
  Location_list_entry, and its interface was not compiled with -opaque
```

**This is NOT caused by the string table fix** - these are pre-existing build system issues that need separate investigation.

---

## Testing Plan

Once the build system is fixed, verify the fix works:

### 1. Compile Test Program

```bash
$ ocamlopt.opt -g -o test_simple test_simple.ml
```

### 2. Check String Table

```bash
$ readelf --string-dump=.debug_str test_simple | grep -E "(OCaml|test_simple|add)"
```

**Expected**: Should show "OCaml X.X.X", "test_simple.ml", "add", etc.

### 3. Check DWARF Info

```bash
$ readelf --debug-dump=info test_simple
```

**Expected**:
- No "offset too big" errors
- `DW_AT_producer` shows "OCaml X.X.X"
- `DW_AT_name` shows "add", "test_simple.ml", etc.

### 4. Test with Debugger

```bash
$ gdb test_simple
(gdb) break add
(gdb) run
(gdb) print x
(gdb) print y
```

**Expected**: Debugger should recognize function names and parameters.

---

## Remaining Issues

### 1. Build System Dependency Ordering

**Status**: ❌ Blocking full testing
**Priority**: High

The DWARF modules have circular or incorrectly ordered dependencies preventing `make world.opt` from completing.

### 2. Potential Endianness Issues

**Status**: ⚠️  Needs Verification
**Priority**: Medium

The original error showed `0x1000000` which looks like a byte-order reversal of `0x00000001`. While the string table fix should resolve most issues, we should verify that all multi-byte integers are correctly written in little-endian:

- ✅ Strings offsets (lines 180-182): Uses manual byte shifts - **correct**
- ✅ Addresses (line 151-152): Uses `Bytes.set_int64_le` - **correct**
- ❓ Unit length, version, etc. (lines 273-281): Manual byte shifts - **should be correct**

### 3. DIE Structure Validation

**Status**: ⚠️  Needs Verification
**Priority**: Low

The original errors mentioned "Bogus end-of-siblings marker". With proper string references, these should be resolved, but we should verify the DIE tree structure is correct.

---

## Success Criteria

The string table fix will be considered complete when:

1. ✅ **Code compiles** - DONE
2. ❌ **Build system works** - Blocked
3. ❌ **readelf shows no errors** - Pending testing
4. ❌ **Producer string correct** - Pending testing
5. ❌ **Function names correct** - Pending testing
6. ❌ **gdb can set breakpoints** - Pending testing

**Current Score**: 1/6 criteria met

---

## References

- **DWARF v4 Specification**: Section 7.20 (String Table)
- **Commit History**:
  - `4b106d28` - Implement string table generation (this fix)
  - `73de66ba` - Update .gitignore
  - `bfa7ec03` - Activate DWARF section emission
  - `d1971a77` - Fix ARM64 parameter tracking

---

## Next Steps

1. **Fix Build System**: Investigate DWARF module dependency ordering
2. **Test String Table**: Compile a program and verify `.debug_str` contents
3. **Verify Endianness**: Confirm all multi-byte integers are little-endian
4. **Test with GDB**: Verify debugger integration works end-to-end
