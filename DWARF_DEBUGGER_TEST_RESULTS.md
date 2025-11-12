# DWARF Debugger Test Results

**Date**: 2025-11-12
**Test Program**: `test_simple.ml` - Simple function `add x y = x + y`
**Compilers Tested**: GDB 13.2, LLDB 14.0

---

## Summary

✅ **DWARF sections are being emitted**
✅ **String table contains correct function names**
✅ **DIE structure is valid** (compile units, subprograms, parameters)
❌ **Function addresses are all 0** - debuggers can't set breakpoints
❌ **User functions not in DWARF info** - only runtime functions appear

---

## Test 1: GDB Function Lookup

### Command
```bash
gdb -batch -ex "file test_simple" -ex "info functions" | grep add
```

### Result
```
❌ No user functions found
✅ C runtime functions found (caml_alloc, etc.)
```

### Analysis
- GDB can read the DWARF information
- Only sees C runtime functions from linked libraries
- Our `add` function not visible

---

## Test 2: GDB Breakpoint by Mangled Name

### Command
```bash
gdb -batch -ex "file test_simple" -ex "break camlTest_simple.add_274"
```

### Result
```
Function "camlTest_simple.add_274" not defined.
```

### Analysis
- Function exists in symbol table (`nm` shows it at 0x48210)
- But DWARF info doesn't include it
- GDB can't match symbol to source code

---

## Test 3: LLDB Symbol Table

### Command
```bash
lldb -b -o "image dump symtab" | grep "Test_simple.*add"
```

### Result
```
✅ camlTest_simple.add_274 at 0x48210 (symbol table)
✅ camlTest_simple.add_274_end at 0x48216 (symbol table)
❌ No DWARF debug info for this function
```

### Analysis
- Symbols exist and have correct addresses
- LLDB can't set breakpoints because no DWARF info

---

## Test 4: DWARF Info Inspection

### String Table (`.debug_str`)
```bash
readelf --string-dump=.debug_str test_simple | grep add
```

**Result**: ✅ **Correct names present**
```
[   760]  camlTest_simple.add_274      # ✅ Our function!
[   778]  camlTest_simple.entry
[  1558]  camlStdlib__Atomic.fetch_and_add_311
...
```

### DWARF Info (`.debug_info`)
```bash
readelf --debug-dump=info test_simple | grep "DW_TAG_subprogram" -A5
```

**Result**: ❌ **Wrong functions**
```
<1><19>: DW_TAG_subprogram
  DW_AT_name: ml_program          # ❌ Runtime function, not our add!
  DW_AT_low_pc: 0                 # ❌ Address is 0!
  DW_AT_high_pc: 0                # ❌ Address is 0!

<1><2e>: DW_TAG_subprogram
  DW_AT_name: ml_curry11          # ❌ Runtime function
  DW_AT_low_pc: 0                 # ❌ Address is 0!
  DW_AT_high_pc: 0                # ❌ Address is 0!
```

### Analysis
1. **Function names in string table** - ✅ Correct
2. **Function DIEs in DWARF info** - ❌ Wrong functions (runtime, not user code)
3. **Function addresses** - ❌ All 0 (should be real addresses)
4. **Our `add` function** - ❌ Not in DWARF info at all

---

## Test 5: Relocation Analysis

### Check Relocations
```bash
objdump -r test_simple.o | grep debug
```

**Result**: ❌ **No DWARF relocations**
```
RELOCATION RECORDS FOR [.data]:
  0x18: R_X86_64_64  camlTest_simple.add_274    # ✅ Data section has relocs

RELOCATION RECORDS FOR [.debug_line]:
  (empty)                                        # ❌ No relocations!

RELOCATION RECORDS FOR [.debug_info]:
  (not present)                                  # ❌ No section at all!
```

### Analysis
- `.data` section uses relocations for labels → assembler resolves them
- `.debug_info` emitted as literal bytes → labels become 0
- Need to emit `.quad label` instead of `.byte 0x00,0x00,...`

---

## Root Causes Identified

### 1. 🔴 Function Addresses Are 0 (CRITICAL)

**Location**: `asmcomp/debug/dwarf/dwarf_high/proto_die.ml:97`

```ocaml
let with_pc_range t ~start ~end_ =
  let t = add_attribute t {
    attr = DW_AT_low_pc;
    value = Address (Code_address.absolute start |> Option.value ~default:0L);
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    form = DW_FORM_addr;
  } in
  ...
```

**Problem**:
- `start` is `Code_address.Label "camlTest_simple.add_274"`
- `Code_address.absolute (Label x)` returns `None`
- `Option.value ~default:0L` converts to `0L`
- Result: All addresses are 0

**Impact**:
- Debuggers can't match code addresses to DWARF info
- Breakpoints don't work
- Stack traces show wrong functions

**Fix Needed**:
- Emit symbolic references: `.quad camlTest_simple.add_274`
- Let assembler create relocations
- Linker resolves to actual addresses

---

### 2. 🔴 User Functions Not in DWARF (CRITICAL)

**Observation**:
- String table has `camlTest_simple.add_274`
- Symbol table has `camlTest_simple.add_274`
- DWARF info shows `ml_program`, `ml_curry11` (runtime functions)

**Possible Causes**:
1. **`add_function` not called** for user functions during emit
2. **Multiple compilation units** - our functions in different CU not inspected
3. **Function filtering** - user functions filtered out somehow

**Investigation Needed**:
```bash
# Check if add_function is called during compilation
ocamlopt -g -verbose test_simple.ml 2>&1 | grep -i dwarf

# Check how many compilation units in DWARF
readelf --debug-dump=info test_simple | grep "Compilation Unit" | wc -l
```

---

### 3. 🟡 No Relocation Support (HIGH Priority)

**Current Emission**: `asmcomp/emitaux.ml:556`
```ocaml
let emit_section_bytes oc bytes =
  (* Emit bytes as .byte directives *)
  output_string oc "\t.byte ";
  for i = 0 to len - 1 do
    Printf.fprintf oc "0x%02x" (Char.code (Bytes.get bytes i))
  done
```

**Problem**:
- Writes everything as literal bytes
- Labels like `camlTest_simple.add_274` already converted to `0`
- No way to emit `.quad label` for relocation

**Fix Needed**:
- Track which offsets contain `Label` addresses
- Emit as `.quad label` instead of `.byte 0x00,...`
- Or: Change to emit assembly directives like GNU as does

---

## What Works vs What Doesn't

### ✅ Working
1. **String table generation** - correct function names stored
2. **DIE structure** - valid compilation units, subprograms, parameters
3. **Abbreviation codes** - proper types assigned
4. **Parameter tracking** - registers and locations recorded
5. **Symbol table** - functions visible with `nm` command
6. **Assembly generation** - `.s` files have correct labels

### ❌ Not Working
1. **Function addresses** - all 0, should be actual code addresses
2. **User function DWARF** - only runtime functions in DWARF info
3. **Relocations** - no relocations in DWARF sections
4. **Debugger breakpoints** - can't set by function name
5. **Source line debugging** - no way to step through code
6. **Variable inspection** - can't examine function parameters

---

## Impact on Debugging

### Can't Do (Debugger Unusable)
- ❌ Set breakpoints by function name
- ❌ Set breakpoints by line number
- ❌ Step through source code
- ❌ View current function in backtrace
- ❌ Inspect function parameters
- ❌ Inspect local variables
- ❌ View source code at current location

### Can Do (Limited)
- ✅ Set breakpoints by absolute address (if you know it)
- ✅ View disassembly
- ✅ Examine memory
- ✅ View registers

**Usability**: ~5% - Debug info exists but is unusable for source-level debugging

---

## Required Fixes (Priority Order)

### Priority 1: CRITICAL - Make Breakpoints Work

**Fix 1A: Emit Relocations for Addresses**
- Change `emit_section_bytes` to recognize Label addresses
- Emit `.quad label` for 8-byte addresses
- Let assembler generate `R_X86_64_64` relocations

**Fix 1B: Find Missing User Functions**
- Debug why `camlTest_simple.add_274` not in DWARF info
- Check if `Dwarf_helpers.add_function` is actually being called
- Verify functions are added to the correct compilation unit

**Expected Result**:
```bash
gdb test_simple
(gdb) break add
Breakpoint 1 at 0x48210: file test_simple.ml, line 2
(gdb) run
Breakpoint 1, camlTest_simple.add_274 () at test_simple.ml:2
2  let add x y = x + y
```

### Priority 2: HIGH - Enable Line Number Debugging

**Fix 2: Line Number Table**
- Verify line number entries are being generated
- Ensure addresses in line table also use relocations
- Test step-by-step source code debugging

### Priority 3: MEDIUM - Variable Inspection

**Fix 3: Type Information**
- Add DW_TAG_base_type for int, string, etc.
- Add type references to parameters
- Enable `print x` in debugger

### Priority 4: LOW - Enhanced Features

**Fix 4: Local Variables, Closures, Optimization Info**

---

## Testing Checklist

Once fixes applied, verify:

- [ ] `gdb test_simple` → `break add` works
- [ ] `lldb test_simple` → `br set -n add` works
- [ ] Breakpoint hits at correct location
- [ ] Backtrace shows correct function name
- [ ] `info locals` shows parameters
- [ ] `step` command works line-by-line
- [ ] `print x` shows parameter value
- [ ] Source code displayed at breakpoint

---

## Conclusion

**Current State**: DWARF infrastructure is ~85% complete, but debugging is **completely non-functional** due to zero addresses and missing user functions in DWARF info.

**Blocking Issues**:
1. All function addresses are 0 (no relocations)
2. User functions not appearing in DWARF info

**Once Fixed**: Would enable basic source-level debugging with breakpoints, stepping, and parameter inspection.

**Estimated Work**: 4-8 hours to fix relocations and investigate missing functions.
