# DWARF Debugging Tests - Comprehensive Guide

This document describes the automated testing framework for OCaml's DWARF debugging support.

## Overview

The automated test suite (`test_dwarf_automated.sh`) verifies that all DWARF debugging features work correctly with both LLDB (macOS) and GDB (Linux).

## Test Categories

### 1. DWARF Section Verification

Verifies that all required DWARF sections are present in the compiled binary:
- `.debug_info`: Compilation unit and DIE tree
- `.debug_line`: Line number program
- `.debug_abbrev`: Abbreviation table
- `.debug_str`: String table

**Tools used**: `dwarfdump` (macOS), `readelf` (Linux)

**What it tests**:
```bash
# macOS
dwarfdump test_basic | grep "debug_info"
dwarfdump test_basic | grep "debug_line"
dwarfdump test_basic | grep "debug_abbrev"

# Linux
readelf -S test_basic | grep ".debug_info"
readelf -S test_basic | grep ".debug_line"
```

### 2. Breakpoints by Function Name

Tests the ability to set breakpoints on OCaml functions by their mangled names.

**LLDB Test**:
```lldb
target create test_basic
breakpoint set --name camlTest_basic__test_int
breakpoint list
```

**GDB Test**:
```gdb
file test_basic
break camlTest_basic__test_int
info breakpoints
```

**Expected output**:
- LLDB: `Breakpoint 1: where = test_basic\`camlTest_basic__test_int + 0`
- GDB: `Breakpoint 1 at 0x...: file test_basic.ml, line 12.`

**What it verifies**:
- ✓ Function names preserved in symbol table
- ✓ Function addresses correctly linked to DWARF info
- ✓ Debugger can resolve function names

### 3. Breakpoints by Line Number

Tests the ability to set breakpoints on specific source lines.

**LLDB Test**:
```lldb
target create test_basic
breakpoint set --file test_basic.ml --line 14
breakpoint list
```

**GDB Test**:
```gdb
file test_basic
break test_basic.ml:14
info breakpoints
```

**Expected output**:
- LLDB: `Breakpoint 1: where = test_basic\`... at test_basic.ml:14`
- GDB: `Breakpoint 1 at 0x...: file test_basic.ml, line 14.`

**What it verifies**:
- ✓ Line number table correctly generated
- ✓ Source file paths embedded in DWARF
- ✓ Line numbers map to instruction addresses
- ✓ `.debug_line` section properly formatted

### 4. Stepping Through Source Code

Tests the ability to step through code line-by-line.

**LLDB Test**:
```lldb
target create test_basic
breakpoint set --name camlTest_basic__test_int
process launch
thread step-in     # Step into function
thread step-over   # Step over line
thread step-over   # Step over another line
```

**What it verifies**:
- ✓ `step` command works (enters functions)
- ✓ `next` command works (stays in current function)
- ✓ Line number state machine generates correct opcodes
- ✓ Each source line maps to at least one instruction

**Expected behavior**:
- Debugger stops at each source line
- `stop reason = step over/in` shown
- Current line indicated in source view

### 5. Source Context Display

Tests the debugger's ability to show source code at the current position.

**LLDB Test**:
```lldb
target create test_basic
breakpoint set --name camlTest_basic__test_int
process launch
source list
```

**GDB Test**:
```gdb
file test_basic
break camlTest_basic__test_int
run
list
```

**Expected output**:
```
   12    let test_int () =
   13      let x = 42 in
-> 14      let y = 17 in
   15      let sum = x + y in
   16      let diff = x - y in
```

**What it verifies**:
- ✓ Source file locations embedded in DWARF
- ✓ Debugger can find source files
- ✓ Line numbers correctly associated with code
- ✓ Current execution position indicated

### 6. Stack Traces with Source Locations

Tests backtraces showing source file and line information for each frame.

**LLDB Test**:
```lldb
target create test_basic
breakpoint set --name camlTest_basic__test_int
process launch
thread backtrace
```

**GDB Test**:
```gdb
file test_basic
break camlTest_basic__test_int
run
backtrace
```

**Expected output**:
```
(lldb) bt
* thread #1, queue = 'com.apple.main-thread'
  * frame #0: test_basic`camlTest_basic__test_int at test_basic.ml:14
    frame #1: test_basic`camlTest_basic__entry at test_basic.ml:64
    frame #2: test_basic`caml_program
```

**What it verifies**:
- ✓ Function names in backtrace
- ✓ Source file names in backtrace
- ✓ Line numbers in backtrace
- ✓ Frame chain correctly established

## Running the Tests

### Prerequisites

1. **Build OCaml compiler**:
   ```bash
   ./configure
   make world.opt
   ```

2. **Compile test program**:
   ```bash
   cd testsuite/tests/asmcomp/dwarf
   ../../../../ocamlopt.opt -I ../../../../stdlib -g -o test_basic test_basic.ml
   ```

   **Note**: The `-I ../../../../stdlib` flag is required when compiling from the test directory. The DWARF infrastructure is currently integrated but the `dwarf_fidelity` flag is not yet wired to OCAMLPARAM - this will be completed in the next integration phase.

3. **Run automated tests**:
   ```bash
   ./test_dwarf_automated.sh test_basic
   ```

### Test Output

**Successful run**:
```
==========================================
  OCaml DWARF Debugging Automated Tests
==========================================

[INFO] Checking prerequisites...
[✓] Prerequisites checked

[INFO] Test 1: Verify DWARF sections exist
[✓] DWARF .debug_info section found
[✓] DWARF .debug_line section found
[✓] DWARF .debug_abbrev section found

[INFO] Running LLDB tests...
[INFO] Test 2: Set breakpoint by function name (LLDB)
[✓] Breakpoint by function name set successfully
[INFO] Test 3: Set breakpoint by line number (LLDB)
[✓] Breakpoint by line number set successfully
[INFO] Test 4: Step through source code (LLDB)
[✓] Stepping commands executed successfully
[INFO] Test 5: View source context (LLDB)
[✓] Source context displayed successfully
[INFO] Test 6: Stack traces with source locations (LLDB)
[✓] Stack trace shows OCaml function names
[✓] Stack trace shows source file locations

==========================================
  Test Summary
==========================================
Passed:  9
Failed:  0
Skipped: 0
==========================================

All tests passed! ✓
```

**Failed test example**:
```
[INFO] Test 3: Set breakpoint by line number (LLDB)
[✗] Could not set breakpoint by line number
  Output: error: invalid line number: ...

[INFO] Test Summary
Passed:  2
Failed:  1
Skipped: 0

Some tests failed. To debug:
  1. Ensure binary compiled with: export OCAMLPARAM="dwarf_fidelity=enhanced" && ocamlopt -g ...
  2. Verify DWARF sections: dwarfdump test_basic | head -50
  3. Run with verbose output: VERBOSE=1 ./test_dwarf_automated.sh test_basic
```

### Verbose Mode

For detailed debugging information:
```bash
VERBOSE=1 ./test_dwarf_automated.sh test_basic
```

This shows:
- Full LLDB/GDB command output
- DWARF section dumps
- Detailed error messages
- Intermediate test results

## Platform-Specific Notes

### macOS (LLDB)

**Architecture Detection**:
- Tests automatically detect ARM64 (Apple Silicon) vs. x86_64
- ARM64 tests verify ARM-specific register usage
- Uses `dwarfdump` for DWARF validation

**LLDB Batch Mode**:
```bash
lldb --batch --source commands.txt binary
```

**Common Issues**:
- **Xcode required**: Install with `xcode-select --install`
- **Code signing**: May need to disable SIP for debugging
- **DWARF format**: macOS uses Mach-O with `__DWARF` segments

### Linux (GDB)

**DWARF Validation**:
- Uses `readelf -w` to inspect DWARF sections
- ELF format with `.debug_*` sections

**GDB Batch Mode**:
```bash
gdb --batch --command=commands.txt binary
```

**Common Issues**:
- **Permissions**: May need `ptrace` permissions
- **Symbol loading**: Check with `info sources`
- **DWARF format**: ELF with standard `.debug_*` sections

## Troubleshooting

### Test Fails: "DWARF sections not found"

**Cause**: Binary not compiled with DWARF enabled

**Solution**:
```bash
# Compile with -g flag and stdlib path
../../../../ocamlopt.opt -I ../../../../stdlib -g -o test_basic test_basic.ml

# Verify sections exist
dwarfdump test_basic | head -20  # macOS
readelf -w test_basic | head -20 # Linux
```

**Note**: The `dwarf_fidelity` OCAMLPARAM option is not yet functional - this will be wired up in the next integration phase.

### Test Fails: "Cannot set breakpoint by line"

**Cause**: Line number table not generated or incorrect

**Solution**:
```bash
# Check line number table
dwarfdump --debug-line test_basic | head -50

# Look for entries like:
#   Address            Line   Column File
#   ------------------ ------ ------ ------
#   0x0000000100001000     12      0      1
#   0x0000000100001008     14      0      1
```

### Test Fails: "Source context not displayed"

**Cause**: Source file path mismatch or file moved

**Solution**:
```bash
# Check source paths in DWARF
dwarfdump --debug-info test_basic | grep DW_AT_comp_dir
dwarfdump --debug-info test_basic | grep DW_AT_name

# DWARF stores absolute paths
# If you moved files, use LLDB source mapping:
(lldb) settings set target.source-map /old/path /new/path
```

### Test Fails: "Stack trace missing locations"

**Cause**: Function addresses not properly tracked

**Solution**:
```bash
# Verify function DIEs exist
dwarfdump --debug-info test_basic | grep DW_TAG_subprogram -A 10

# Check for DW_AT_low_pc and DW_AT_high_pc
```

## Test Coverage Matrix

| Feature | LLDB | GDB | macOS | Linux | Status |
|---------|------|-----|-------|-------|--------|
| DWARF sections | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Function breakpoints | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Line breakpoints | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Stepping | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Source context | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Stack traces | ✓ | ✓ | ✓ | ✓ | ✅ Complete |
| Variable inspection | - | - | - | - | 🔄 Phase 5 |
| Type display | - | - | - | - | 🔄 Phase 6 |

## Adding New Tests

To add a new test case:

1. **Create test function** in `test_dwarf_automated.sh`:
   ```bash
   test_my_new_feature() {
       log_info "Test N: Description"

       # Create LLDB/GDB commands
       cat > /tmp/test_$$.txt <<'EOF'
       # commands here
   EOF

       # Run and verify
       OUTPUT=$(lldb --batch --source /tmp/test_$$.txt 2>&1)

       if echo "$OUTPUT" | grep -q "expected_string"; then
           log_success "Test passed"
       else
           log_failure "Test failed"
       fi

       rm -f /tmp/test_$$.txt
   }
   ```

2. **Call test function** in `main()`:
   ```bash
   test_my_new_feature
   ```

3. **Document test** in this file

4. **Update test count** in README.md

## Integration with CI

The test suite is designed for continuous integration:

```yaml
# Example GitHub Actions workflow
name: DWARF Tests
on: [push, pull_request]
jobs:
  test-dwarf:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v2
      - name: Build OCaml
        run: |
          ./configure
          make world.opt
      - name: Run DWARF tests
        run: |
          cd testsuite/tests/asmcomp/dwarf
          ../../../../ocamlopt.opt -I ../../../../stdlib -g -o test_basic test_basic.ml
          ./test_dwarf_automated.sh test_basic
```

## References

- **DWARF 4 Specification**: http://dwarfstd.org/doc/DWARF4.pdf
- **LLDB Documentation**: https://lldb.llvm.org/use/tutorial.html
- **GDB Documentation**: https://sourceware.org/gdb/documentation/
- **OCaml DWARF Status**: ../../../../DWARF_STATUS.md
- **Implementation Plan**: ../../../../DWARF_IMPLEMENTATION_PLAN.md
- **Quick Start Guide**: ../../../../DWARF_QUICKSTART.md

---

**Last Updated**: 2025-11-11
**Test Suite Version**: 1.0
**OCaml DWARF Status**: 67% complete (Phases 1-4 done)
