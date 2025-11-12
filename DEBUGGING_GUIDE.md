# OCaml DWARF Debugging Guide

Complete guide to debugging OCaml native code with DWARF support.

## Quick Start

### 1. Compile with Debug Information

```bash
# Enable DWARF with enhanced fidelity
export OCAMLPARAM="dwarf_fidelity=enhanced,_"

# Compile with -g flag
ocamlopt -g -o myprogram myprogram.ml
```

### 2. Debug with LLDB (macOS)

```bash
lldb myprogram
(lldb) b camlMyprogram__main
(lldb) r
(lldb) list
(lldb) step
(lldb) bt
```

### 3. Debug with GDB (Linux)

```bash
gdb myprogram
(gdb) break camlMyprogram__main
(gdb) run
(gdb) list
(gdb) step
(gdb) backtrace
```

## Compilation Options

### DWARF Fidelity Levels

**Basic** (default `-g`):
- Line number information only
- Function names
- Minimal overhead

**Enhanced** (`dwarf_fidelity=enhanced`):
- All basic features
- Type information (int, float, records, variants)
- Parameter tracking
- Optimized abbreviations

```bash
# Enhanced mode (recommended)
export OCAMLPARAM="dwarf_fidelity=enhanced,_"
ocamlopt -g -o program program.ml

# Basic mode
ocamlopt -g -o program program.ml
```

### Optimization Levels

```bash
# No optimization (best for debugging)
ocamlopt -g -O0 -o program program.ml

# Standard optimization (some variables may be optimized out)
ocamlopt -g -o program program.ml

# Maximum optimization (many variables optimized out)
ocamlopt -g -O3 -o program program.ml
```

**Recommendation**: Use `-O0` or `-O1` for debugging sessions.

## Debugger Commands

### LLDB (macOS)

#### Breakpoints

```lldb
# Break by function name
(lldb) b camlModule__function_name

# Break by source line
(lldb) b file.ml:42

# Break by label
(lldb) b camlModule__function_name_123

# List breakpoints
(lldb) br list

# Delete breakpoint
(lldb) br delete 1
```

#### Execution Control

```lldb
# Run program
(lldb) r
(lldb) run arg1 arg2

# Step into (follows function calls)
(lldb) s
(lldb) step

# Step over (doesn't follow calls)
(lldb) n
(lldb) next

# Continue execution
(lldb) c
(lldb) continue

# Finish current function
(lldb) finish
```

#### Inspection

```lldb
# View source
(lldb) list
(lldb) l file.ml:42

# Show backtrace
(lldb) bt
(lldb) backtrace

# Show frame info
(lldb) frame info

# Show variables (parameters)
(lldb) frame variable

# Examine memory
(lldb) memory read $rax
```

### GDB (Linux)

#### Breakpoints

```gdb
# Break by function name
(gdb) break camlModule__function_name

# Break by source line
(gdb) break file.ml:42

# List breakpoints
(gdb) info breakpoints

# Delete breakpoint
(gdb) delete 1
```

#### Execution Control

```gdb
# Run program
(gdb) run
(gdb) r arg1 arg2

# Step into
(gdb) step
(gdb) s

# Step over
(gdb) next
(gdb) n

# Continue
(gdb) continue
(gdb) c

# Finish function
(gdb) finish
```

#### Inspection

```gdb
# View source
(gdb) list
(gdb) l file.ml:42

# Show backtrace
(gdb) backtrace
(gdb) bt

# Show frame info
(gdb) frame

# Show local variables
(gdb) info locals

# Show parameters
(gdb) info args

# Examine memory
(gdb) x/8x $rax
```

## Function Name Mangling

OCaml mangles function names in the binary. Here's how to find them:

### Pattern

```
camlModule_name__function_name_nnn
```

Where:
- `Module_name`: Your module name (first letter uppercase)
- `function_name`: Your function name (lowercase)
- `nnn`: Unique identifier number

### Examples

```ocaml
(* file: mymodule.ml *)
let factorial n = ...
let add x y = ...

let rec helper acc = ...
```

Becomes:
```
camlMymodule__factorial_123
camlMymodule__add_456
camlMymodule__helper_789
```

### Finding Function Names

```bash
# List all OCaml functions
nm myprogram | grep "^caml"

# Find specific function
nm myprogram | grep factorial

# With source info
objdump -d -S myprogram | grep factorial
```

## Debugging Techniques

### 1. Setting Breakpoints

```lldb
# Entry point
(lldb) b camlMyprogram__entry

# Specific function
(lldb) b camlMyprogram__factorial_123

# Source line
(lldb) b myprogram.ml:42
```

### 2. Stepping Through Code

```lldb
# Start debugging
(lldb) r

# Step through each line
(lldb) n
(lldb) n
(lldb) n

# Step into function call
(lldb) s

# Return from function
(lldb) finish
```

### 3. Inspecting State

```lldb
# Show current line
(lldb) frame select

# Show surrounding source
(lldb) list

# Show call stack
(lldb) bt

# Show frame details
(lldb) frame variable
```

### 4. Examining Crash Sites

```lldb
# Run until crash
(lldb) r

# Show crash location
(lldb) bt

# Examine registers
(lldb) register read

# View disassembly
(lldb) disassemble
```

## Common Issues

### Issue: Can't find function name

**Symptom**:
```
(lldb) b factorial
Breakpoint 1: no locations (pending).
```

**Solution**:
```bash
# Find mangled name
nm myprogram | grep factorial

# Use full mangled name
(lldb) b camlMyprogram__factorial_123
```

### Issue: Variables show as "optimized out"

**Symptom**:
```
(lldb) frame variable
x = <optimized out>
```

**Solution**:
```bash
# Recompile with lower optimization
ocamlopt -g -O0 -o myprogram myprogram.ml
```

### Issue: No source information

**Symptom**:
```
(lldb) list
Unable to find source file
```

**Solution**:
```bash
# Ensure -g flag is used
ocamlopt -g -o myprogram myprogram.ml

# Verify DWARF sections exist
dwarfdump myprogram | head
```

### Issue: Can't set breakpoint on line

**Symptom**:
```
(lldb) b file.ml:42
Breakpoint 1: no locations (pending).
```

**Solution**:
```bash
# Ensure DWARF_fidelity=enhanced
export OCAMLPARAM="dwarf_fidelity=enhanced,_"
ocamlopt -g -o myprogram myprogram.ml

# Check line number info exists
dwarfdump --debug-line myprogram
```

## Advanced Techniques

### Custom Type Inspection

When debugging with types:

```ocaml
type point = { x : int; y : int }
let p = { x = 10; y = 20 }
```

```lldb
# View type information
(lldb) ptype p
type = point { x: int, y: int }

# Note: Full type inspection requires Phase 6 completion
```

### Conditional Breakpoints

```lldb
# Break when condition is true
(lldb) b file.ml:42 -c '$rax == 0'

# Break after N hits
(lldb) b file.ml:42 -i 10
```

### Watchpoints

```lldb
# Watch memory address
(lldb) watchpoint set expression -- 0x12345678

# Watch variable (when supported)
(lldb) watchpoint set variable myvar
```

## Verifying DWARF Information

### Check DWARF Sections

```bash
# macOS
dwarfdump myprogram | head -50
otool -l myprogram | grep -A 3 __DWARF

# Linux
readelf -w myprogram | head -50
readelf -S myprogram | grep debug
```

### Inspect Debug Info

```bash
# Show compilation units
dwarfdump --debug-info myprogram | grep DW_TAG_compile_unit

# Show functions
dwarfdump --debug-info myprogram | grep DW_TAG_subprogram

# Show line numbers
dwarfdump --debug-line myprogram

# Show types
dwarfdump --debug-info myprogram | grep DW_TAG_base_type
```

## Performance Impact

### Compilation Time

- With `-g`: +10-20% compilation time
- With `dwarf_fidelity=enhanced`: +15-25% compilation time

### Binary Size

- With `-g`: +30-50% binary size
- DWARF sections can be stripped after debugging:

```bash
# Strip debug info (after debugging)
strip -S myprogram
```

### Runtime Performance

- No runtime performance impact
- Debug information is not loaded during execution

## Tips and Best Practices

### 1. Always Use DWARF Enhanced Mode

```bash
export OCAMLPARAM="dwarf_fidelity=enhanced,_"
# Add to ~/.bashrc or ~/.zshrc
```

### 2. Keep Source Files

Debuggers need source files. Keep them in the compilation directory or use absolute paths.

### 3. Use Descriptive Function Names

```ocaml
(* Good *)
let calculate_fibonacci_iterative n = ...

(* Avoid *)
let calc n = ...
let f n = ...
```

### 4. Debug Builds vs Release Builds

```bash
# Debug build
ocamlopt -g -O0 -o myprogram.debug myprogram.ml

# Release build
ocamlopt -O3 -o myprogram myprogram.ml
```

### 5. Remote Debugging

```bash
# On target machine
lldb-server platform --listen 0.0.0.0:1234

# On development machine
(lldb) platform select remote-macos
(lldb) platform connect connect://target:1234
(lldb) file myprogram
```

## Troubleshooting Checklist

Before filing a bug report:

- [ ] Compiled with `-g` flag
- [ ] Set `OCAMLPARAM="dwarf_fidelity=enhanced,_"`
- [ ] Verified DWARF sections exist (`dwarfdump` / `readelf`)
- [ ] Using correct mangled function names
- [ ] Source files available in compilation directory
- [ ] Using debugger that supports DWARF 4
- [ ] Not using too high optimization level

## Platform-Specific Notes

### macOS ARM64 (M1/M2)

- Fully supported
- Use LLDB (comes with Xcode)
- Code signing may be required for debugging

### macOS AMD64 (Intel)

- Fully supported
- Use LLDB

### Linux ARM64

- Fully supported
- Use GDB 8.0 or later
- May need `set disable-randomization off`

### Linux AMD64

- Fully supported
- Use GDB 8.0 or later

## Resources

- [DWARF 4 Specification](http://dwarfstd.org/)
- [LLDB Tutorial](https://lldb.llvm.org/use/tutorial.html)
- [GDB Manual](https://www.gnu.org/software/gdb/documentation/)
- [OCaml Manual](https://ocaml.org/manual/)

## Getting Help

If you encounter issues:

1. Check this guide
2. Verify DWARF sections exist
3. Try with simpler program
4. Report issue with:
   - OCaml version
   - Platform and architecture
   - Minimal reproduction case
   - Compiler command line
   - Debugger output

## Future Enhancements

Coming soon:

- Full local variable tracking
- Pretty-printing for OCaml data structures
- Better type integration
- GDB Python scripts for OCaml
- LLDB formatters for OCaml types
