# DWARF Debugging Information Tests

This directory contains tests for DWARF debugging information generation in OCaml's native code compiler.

## Overview

The tests verify that OCaml generates correct DWARF debugging information that allows debuggers (LLDB, GDB) to:
- ✅ Set breakpoints by function name
- ✅ Set breakpoints by line number
- ✅ Step through OCaml source code
- ✅ View source context in debugger
- ✅ Navigate call stacks with source locations
- 🔄 Inspect local variables and function parameters (Phase 5)
- 🔄 Display OCaml types correctly (Phase 6)

## Test Structure

```
testsuite/tests/asmcomp/dwarf/
├── README.md                    # This file
├── test_basic.ml                # Basic types and simple functions
├── test_types.ml                # Complex OCaml types (variants, records, etc.)
├── test_dwarf_automated.sh      # ⭐ Automated test suite (NEW)
├── lldb_test.sh                 # Legacy LLDB test driver
├── verify_dwarf.sh              # DWARF validation script
├── MACOS_ARM64.md               # macOS ARM64 specifics
└── *.reference                  # Expected test outputs
```

## Running Tests

### Prerequisites

- **OCaml compiler built** with DWARF support
- **Build the compiler first**:
  ```bash
  # From OCaml root directory
  ./configure
  make world.opt
  ```
- `dwarfdump` or `llvm-dwarfdump` (for DWARF validation)
- LLDB (for macOS) or GDB (for Linux)
- `readelf` (for Linux, ELF binaries)

### Quick Start - Automated Tests ⭐

```bash
# From the OCaml root directory
cd testsuite/tests/asmcomp/dwarf

# Step 1: Enable DWARF and compile test
export OCAMLPARAM="dwarf_fidelity=enhanced"
../../../../ocamlopt.opt -g -o test_basic test_basic.ml

# Step 2: Run automated test suite
./test_dwarf_automated.sh test_basic

# For verbose output:
VERBOSE=1 ./test_dwarf_automated.sh test_basic
```

The automated test suite checks:
1. ✓ DWARF sections exist (.debug_info, .debug_line, .debug_abbrev, .debug_str)
2. ✓ Set breakpoints by function name (LLDB & GDB)
3. ✓ Set breakpoints by line number (LLDB & GDB)
4. ✓ Step through source code (step-in, step-over)
5. ✓ View source context at breakpoints
6. ✓ Stack traces with source file locations

### Manual Testing

```bash
# Compile test files with DWARF debug info
export OCAMLPARAM="dwarf_fidelity=enhanced"
ocamlopt -g -o test_basic test_basic.ml

# Verify DWARF sections exist
./verify_dwarf.sh test_basic

# Or manually:
dwarfdump test_basic | head -50      # macOS
readelf -w test_basic | head -50     # Linux
```

### Manual Testing with LLDB

```bash
# Compile with debug info
ocamlopt -g -o test_basic test_basic.ml

# Start LLDB
lldb test_basic

# Set breakpoint
(lldb) b camlTest_basic__entry
(lldb) run

# Inspect variables
(lldb) frame variable
(lldb) print my_var

# Step through code
(lldb) step
(lldb) next
(lldb) continue
```

### Manual Testing with GDB

```bash
# Compile with debug info
ocamlopt -g -o test_basic test_basic.ml

# Start GDB
gdb test_basic

# Set breakpoint
(gdb) break camlTest_basic__entry
(gdb) run

# Inspect variables
(gdb) info locals
(gdb) print my_var

# Step through code
(gdb) step
(gdb) next
(gdb) continue
```

## Test Categories

### 1. Basic Types (`test_basic.ml`)
- Integers (tagged and untagged)
- Floating-point numbers
- Booleans
- Characters
- Strings
- Unit type

### 2. Complex Types (`test_types.ml`)
- Records
- Tuples
- Variants (polymorphic and regular)
- Arrays
- Lists
- Options
- References
- Unboxed types

### 3. Variable Tracking (`test_variables.ml`)
- Local variables
- Function parameters
- Global variables
- Mutable variables
- Variables in different scopes
- Variable lifetimes

### 4. Function Calls (`test_functions.ml`)
- Simple function calls
- Recursive functions
- Tail-recursive functions
- Higher-order functions
- Closures
- Partial application

### 5. Inlining (`test_inlining.ml`)
- Inlined functions
- Abstract instances
- Concrete instances
- Call site information
- (Requires Phase 4 completion)

## DWARF Validation

The `verify_dwarf.sh` script checks:
- Presence of .debug_info section
- Presence of .debug_line section
- Presence of .debug_abbrev section
- Presence of .debug_loc section (for variable locations)
- Presence of .debug_ranges section (for non-contiguous code)
- Presence of .debug_str section (for strings)
- Valid DWARF version (expecting DWARF 4)
- OCaml language tag (DW_LANG_OCaml)

## Expected Behavior

### Variable Inspection
When stopped at a breakpoint, the debugger should show:
- Variable names as they appear in source code
- Correct types (int, float, string, custom types)
- Current values in the correct representation
- Location (register or stack offset)

### Type Display
OCaml types should be recognizable:
- `int` → tagged integer representation
- `float` → IEEE 754 double
- `string` → OCaml string structure
- `'a list` → OCaml list structure with tag
- `type t = A | B of int` → variant with tags

### Stack Traces
Call stacks should show:
- Function names
- Source file and line numbers
- Parameter values
- Ability to navigate up and down the stack

## Current Status (67% Complete)

### ✅ Implemented (Phases 1-4)
- **Phase 1-2**: DWARF infrastructure and high-level API
- **Phase 3**: Byte-level DWARF emission (LEB128 encoding, section emission)
- **Phase 4**: Line number support (state machine, line number program)

### ✅ Working Features
1. Set breakpoints by function name (`break camlModule__function_123`)
2. Set breakpoints by line number (`break file.ml:42`)
3. Step through source code (`step`, `next`, `finish`)
4. View source context in debugger (`list`)
5. Stack traces with source locations (`backtrace`)

### 🔄 In Progress (Phase 5)
- Variable location tracking infrastructure (foundation complete)
- Linear IR integration (pending)
- `.debug_loc` section emission (pending)
- Variable inspection in debugger (pending)

### 🔄 Future (Phase 6+)
- OCaml type system integration
- Type-aware variable display
- Complex data structure navigation
- Inlined function support

## Debugging Test Failures

### No DWARF sections found
```bash
# Check if compiled with -g
ocamlopt -config | grep debug

# Verify DWARF flags are set
ocamlopt -g -verbose -o test test.ml 2>&1 | grep -i dwarf
```

### Debugger can't find symbols
```bash
# Check symbol table
nm test | grep caml

# Verify DWARF info is present
dwarfdump test | head -50

# On Linux
readelf -w test | head -50
```

### Variables show as "optimized out"
This is expected for optimized builds. The DWARF location lists
should track variables, but aggressive optimization may eliminate them.

Try compiling with:
```bash
ocamlopt -g -O0 -o test test.ml  # Less optimization
```

## Contributing Tests

When adding new tests:
1. Create a minimal test case in a new .ml file
2. Document what the test checks in comments
3. Add expected behavior to this README
4. Create corresponding LLDB/GDB test script
5. Ensure test passes on both macOS and Linux

## References

- [DWARF 4 Specification](http://dwarfstd.org/)
- [LLDB Debugging Guide](https://lldb.llvm.org/)
- [GDB User Manual](https://www.gnu.org/software/gdb/documentation/)
- [OCaml Compiler Hacking Guide](https://github.com/ocaml/ocaml/blob/trunk/HACKING.adoc)
- [DWARF Implementation Plan](../../../../DWARF_IMPLEMENTATION_PLAN.md)
