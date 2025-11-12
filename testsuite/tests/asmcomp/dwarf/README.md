# DWARF Debugging Information Tests

This directory contains tests for DWARF debugging information generation in OCaml's native code compiler.

## Overview

The tests verify that OCaml generates correct DWARF debugging information that allows debuggers to:
- Set breakpoints by function name
- Set breakpoints by line number
- Step through OCaml source code
- View source context in debugger
- Navigate call stacks with source locations

## Test Files

The tests use OCaml's ocamltest framework and automatically compile with DWARF enabled.

### Core Tests
- `basic_compile.ml` - Basic compilation with DWARF enabled
- `function_names.ml` - Function name preservation and recursion
- `test_simple.ml` - Simple parameter tracking
- `test_basic.ml` - Integer, float, and string operations
- `test_debug.ml` - Local variables, nested calls, and pattern matching

### Type System Tests
- `record_types.ml` - Record type definitions and field access
- `variant_types.ml` - Variant types and pattern matching
- `array_list.ml` - Arrays and lists
- `test_types.ml` - Records, variants, options, and lists

### Advanced Tests
- `closures.ml` - Closures and higher-order functions
- `exceptions.ml` - Exception handling and control flow
- `polymorphism.ml` - Polymorphic functions and type parameters

## Running Tests

### Using ocamltest

From the OCaml root directory:

```bash
make tests TEST_SUBDIRS=asmcomp/dwarf
```

Or run individual tests:

```bash
cd testsuite
./ocamltest tests/asmcomp/dwarf/basic_compile.ml
./ocamltest tests/asmcomp/dwarf/function_names.ml
```

### Manual Compilation and Testing

```bash
cd testsuite/tests/asmcomp/dwarf
export OCAMLPARAM="dwarf_fidelity=enhanced,_"
../../../../ocamlopt.opt -g -o test_basic test_basic.ml
./test_basic
```

### DWARF Verification

Verify DWARF sections exist:

```bash
# macOS
dwarfdump test_basic | head -50
otool -l test_basic | grep -A 3 __DWARF

# Linux
readelf -w test_basic | head -50
readelf -S test_basic | grep debug
```

### Debugging with LLDB (macOS)

```bash
lldb test_basic
(lldb) b camlTest_basic__test_int
(lldb) r
(lldb) list
(lldb) step
(lldb) bt
```

### Debugging with GDB (Linux)

```bash
gdb test_basic
(gdb) break camlTest_basic__test_int
(gdb) run
(gdb) list
(gdb) step
(gdb) backtrace
```

## Test Organization

Each test focuses on a specific DWARF feature:

1. **Compilation Tests**: Ensure code compiles and runs with DWARF enabled
2. **Function Tests**: Verify function names preserved and callable in debugger
3. **Line Number Tests**: Check source line mapping for stepping
4. **Type Tests**: Validate type information generation
5. **Advanced Tests**: Test closures, exceptions, and polymorphism

All tests include `.reference` files with expected output.

## DWARF Flags

Tests automatically set:
- `OCAMLPARAM=dwarf_fidelity=enhanced` - Enable full DWARF generation
- `-g` flag - Enable debug information

## Current Implementation Status

### Working
- Function-level debugging (set breakpoints by function name)
- Source-level debugging (set breakpoints by line, step through code)
- Stack traces with source locations
- DWARF 4 section emission (.debug_info, .debug_abbrev, .debug_str, .debug_line)

### In Progress
- Variable location tracking
- Type-aware debugging

## Documentation

See parent directory markdown files for detailed implementation information:
- `DWARF_STATUS.md` - Overall project status
- `PHASE5_6_STATUS.md` - Variable and type integration status
- `DWARF_QUICKSTART.md` - Quick start guide for debugging
