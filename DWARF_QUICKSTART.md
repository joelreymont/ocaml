# DWARF Debugging Quick Start Guide

Get started with DWARF debugging support in OCaml in 5 minutes!

## 🚀 Quick Start

### Step 1: Enable DWARF

```bash
# Set environment variable
export OCAMLPARAM="dwarf_fidelity=enhanced"

# Or pass flag directly
ocamlopt -g -dwarf-fidelity enhanced your_program.ml
```

### Step 2: Compile Your Program

```bash
# Compile with debug info
ocamlopt -g -o program program.ml

# For multiple files
ocamlopt -g -o program file1.ml file2.ml file3.ml
```

### Step 3: Debug!

**macOS (LLDB)**:
```bash
lldb program
(lldb) break program.ml:42
(lldb) run
(lldb) step
```

**Linux (GDB)**:
```bash
gdb program
(gdb) break program.ml:42
(gdb) run
(gdb) step
```

That's it! You now have source-level debugging.

---

## 📝 Complete Example

### 1. Write Your Program

```ocaml
(* factorial.ml *)
let rec factorial n =
  if n <= 1 then 1
  else n * factorial (n - 1)

let () =
  let result = factorial 5 in
  Printf.printf "Result: %d\n" result
```

### 2. Compile with DWARF

```bash
export OCAMLPARAM="dwarf_fidelity=enhanced"
ocamlopt -g -o factorial factorial.ml
```

### 3. Debug with LLDB (macOS)

```bash
$ lldb factorial
(lldb) target create "factorial"
Current executable set to 'factorial' (arm64).

# Set breakpoint at line 2
(lldb) breakpoint set --file factorial.ml --line 2
Breakpoint 1: where = factorial`camlFactorial__factorial_123 + 0
              address = 0x0000000100001000

# Run the program
(lldb) run
Process 12345 launched: 'factorial' (arm64)
Process 12345 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000100001000 factorial`camlFactorial__factorial_123
                at factorial.ml:2:0

# View source
(lldb) list
   1    let rec factorial n =
-> 2      if n <= 1 then 1
   3      else n * factorial (n - 1)
   4
   5    let () =

# Step through code
(lldb) step
Process 12345 stopped
* frame #0: 0x0000000100001008 factorial`camlFactorial__factorial_123
                at factorial.ml:3:5

# Continue stepping
(lldb) next
Process 12345 stopped
* frame #0: 0x0000000100001010 factorial`camlFactorial__factorial_123
                at factorial.ml:3:10

# View backtrace
(lldb) bt
* thread #1, queue = 'com.apple.main-thread'
  * frame #0: factorial`camlFactorial__factorial_123 at factorial.ml:3:10
    frame #1: factorial`camlFactorial__factorial_123 at factorial.ml:3:10
    frame #2: factorial`camlFactorial__entry at factorial.ml:6:19
```

### 4. Debug with GDB (Linux)

```bash
$ gdb factorial
(gdb) break factorial.ml:2
Breakpoint 1 at 0x1000: file factorial.ml, line 2.

(gdb) run
Starting program: factorial

Breakpoint 1, camlFactorial__factorial_123 () at factorial.ml:2
2         if n <= 1 then 1

(gdb) list
1       let rec factorial n =
2         if n <= 1 then 1
3         else n * factorial (n - 1)
4
5       let () =

(gdb) step
3         else n * factorial (n - 1)

(gdb) backtrace
#0  camlFactorial__factorial_123 () at factorial.ml:3
#1  camlFactorial__entry () at factorial.ml:6
```

---

## 🎯 Common Debugging Tasks

### Set Breakpoints

```bash
# By line number
(lldb) break program.ml:42
(gdb) break program.ml:42

# By function name
(lldb) break camlMymodule__myfunction_123
(gdb) break camlMymodule__myfunction_123

# Conditional breakpoint (lldb)
(lldb) breakpoint set --file program.ml --line 42 --condition 'n > 5'

# Conditional breakpoint (gdb)
(gdb) break program.ml:42 if n > 5

# List breakpoints
(lldb) breakpoint list
(gdb) info breakpoints

# Delete breakpoint
(lldb) breakpoint delete 1
(gdb) delete 1
```

### Step Through Code

```bash
# Step into function calls
(lldb) step
(gdb) step

# Step over function calls
(lldb) next
(gdb) next

# Step out of current function
(lldb) finish
(gdb) finish

# Continue execution
(lldb) continue
(gdb) continue
```

### View Source and State

```bash
# View source around current line
(lldb) list
(gdb) list

# View specific line
(lldb) list program.ml:42
(gdb) list program.ml:42

# Show current frame
(lldb) frame info
(gdb) frame

# View backtrace
(lldb) backtrace
(gdb) backtrace

# View all threads
(lldb) thread list
(gdb) info threads
```

### Inspect Variables (Future - Phase 5)

Once variable tracking is complete:

```bash
# Print variable value
(lldb) print x
(gdb) print x

# Display local variables
(lldb) frame variable
(gdb) info locals

# Watch variable changes
(lldb) watchpoint set variable x
(gdb) watch x
```

---

## 🔍 Verify DWARF Sections

### macOS

```bash
# Check if DWARF sections exist
otool -l program | grep -A 3 __DWARF

# Dump DWARF information
dwarfdump program

# View line number table
dwarfdump --debug-line program

# View debugging info
dwarfdump --debug-info program
```

### Linux

```bash
# Check if .debug_* sections exist
readelf -S program | grep debug

# Dump all DWARF info
readelf -w program

# Dump specific sections
readelf --debug-dump=info program
readelf --debug-dump=line program
readelf --debug-dump=abbrev program
readelf --debug-dump=str program
```

---

## 🐛 Troubleshooting

### Problem: Breakpoints Don't Work

**Check 1**: DWARF enabled?
```bash
# Should show __DWARF or .debug_* sections
otool -l program | grep DWARF    # macOS
readelf -S program | grep debug   # Linux
```

**Solution**: Recompile with DWARF:
```bash
export OCAMLPARAM="dwarf_fidelity=enhanced"
ocamlopt -g -o program program.ml
```

### Problem: No Source Code in Debugger

**Check 1**: Compiled with -g flag?
```bash
ocamlopt -g -o program program.ml
```

**Check 2**: Source file still at same location?
```bash
# DWARF stores absolute paths
# Move to original compilation directory or use:
(lldb) settings set target.source-map /old/path /new/path
```

### Problem: "Optimized Out" Variables

Variables may be optimized away by the compiler. Solutions:
```bash
# Compile with less optimization
ocamlopt -g -O0 -o program program.ml   # (future)

# Current: Variables not yet tracked (Phase 5)
# Will be available after Phase 5 completion
```

### Problem: Debugger Can't Find Debug Info

**macOS**:
```bash
# Check if dsymutil needed (usually not for -g compilation)
dsymutil program

# Verify debug info
dwarfdump program | head -20
```

**Linux**:
```bash
# Verify debug info exists
readelf -w program | head -20

# Check if stripped (don't strip with -S)
file program
```

---

## 💡 Tips and Tricks

### Tip 1: Use Tab Completion

```bash
# LLDB tab completion for files
(lldb) break fac<TAB>
# Completes to: break factorial.ml:

# GDB tab completion
(gdb) break fac<TAB>
# Completes to: break factorial.ml:
```

### Tip 2: Create Breakpoint Shortcuts

**LLDB**:
```bash
# Add to ~/.lldbinit
command alias bpl breakpoint set -f %1 -l %2

# Usage:
(lldb) bpl program.ml 42
```

**GDB**:
```bash
# Add to ~/.gdbinit
define bpl
  break $arg0:$arg1
end

# Usage:
(gdb) bpl program.ml 42
```

### Tip 3: Save Debugging Sessions

**LLDB**:
```bash
# Save breakpoints
(lldb) breakpoint write -f breakpoints.txt

# Restore breakpoints
(lldb) breakpoint read -f breakpoints.txt
```

**GDB**:
```bash
# Save commands
(gdb) set logging on
(gdb) show breakpoints
(gdb) set logging off

# Use command file
gdb -x commands.txt program
```

### Tip 4: Remote Debugging

**LLDB**:
```bash
# Server:
lldb-server platform --listen *:1234

# Client:
(lldb) platform select remote-macosx
(lldb) platform connect connect://host:1234
```

**GDB**:
```bash
# Server:
gdbserver :1234 program

# Client:
gdb program
(gdb) target remote host:1234
```

---

## 📊 What Works Now vs. Future

### ✅ Currently Working

- ✅ Set breakpoints by function name
- ✅ Set breakpoints by line number
- ✅ Step through source code (step, next, finish)
- ✅ View source context in debugger
- ✅ Stack traces with source locations
- ✅ View current line and frame info
- ✅ Multiple threads/processes

### 🔄 Coming Soon (Phase 5)

- 🔄 Inspect variable values
- 🔄 Watch variables for changes
- 🔄 Display local variables
- 🔄 Print expressions

### 🔄 Future (Phase 6)

- 🔄 Type-aware variable display
- 🔄 Inspect OCaml data structures
- 🔄 Pretty-print records/variants
- 🔄 Navigate through complex types

---

## 🎓 Advanced Usage

### Custom Debug Commands

**LLDB Python Scripting**:
```python
# ~/.lldbinit
command script import ~/lldb_ocaml.py

# lldb_ocaml.py
def ocaml_info(debugger, command, result, internal_dict):
    target = debugger.GetSelectedTarget()
    process = target.GetProcess()
    thread = process.GetSelectedThread()
    frame = thread.GetSelectedFrame()

    print("OCaml Frame Info:")
    print(f"  Function: {frame.GetFunctionName()}")
    print(f"  Location: {frame.GetLineEntry().GetFileSpec().GetFilename()}:"
          f"{frame.GetLineEntry().GetLine()}")

def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f lldb_ocaml.ocaml_info ocaml')
```

**GDB Python Scripting**:
```python
# ~/.gdbinit
source ~/gdb_ocaml.py

# gdb_ocaml.py
import gdb

class OcamlInfo(gdb.Command):
    def __init__(self):
        super(OcamlInfo, self).__init__("ocaml-info", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        frame = gdb.selected_frame()
        sal = frame.find_sal()

        print("OCaml Frame Info:")
        print(f"  Function: {frame.name()}")
        print(f"  Location: {sal.symtab.filename}:{sal.line}")

OcamlInfo()
```

### Debugging Optimized Code

```bash
# View disassembly with source
(lldb) disassemble -F intel -m
(gdb) disassemble /m

# View registers
(lldb) register read
(gdb) info registers

# View memory
(lldb) memory read 0x100001000
(gdb) x/20x 0x100001000
```

---

## 📚 Learn More

### Documentation
- `DWARF_STATUS.md` - Complete project status
- `PHASE4_LINE_NUMBERS.md` - Line number implementation details
- `BACKEND_INTEGRATION.md` - Backend integration guide
- `SESSION_SUMMARY.md` - Implementation session notes

### DWARF Resources
- [DWARF 4 Specification](http://dwarfstd.org/doc/DWARF4.pdf)
- [Introduction to DWARF](http://dwarfstd.org/doc/Debugging%20using%20DWARF-2012.pdf)
- [LLDB Tutorial](https://lldb.llvm.org/use/tutorial.html)
- [GDB Documentation](https://sourceware.org/gdb/documentation/)

### Getting Help
- Check `DWARF_STATUS.md` for current capabilities
- Review examples in `testsuite/tests/asmcomp/dwarf/`
- File issues on the project repository

---

## ✅ Quick Reference

### Essential Commands

| Task | LLDB | GDB |
|------|------|-----|
| Set breakpoint | `break file:line` | `break file:line` |
| Run program | `run` | `run` |
| Step into | `step` | `step` |
| Step over | `next` | `next` |
| Continue | `continue` | `continue` |
| Backtrace | `bt` | `bt` |
| View source | `list` | `list` |
| Quit | `quit` | `quit` |

### Compilation Flags

| Flag | Purpose |
|------|---------|
| `-g` | Enable debug info (required) |
| `-dwarf-fidelity enhanced` | Enable DWARF emission |
| Environment: `OCAMLPARAM="dwarf_fidelity=enhanced"` | Alternative way to enable |

---

**Quick Start Version**: 1.0
**Last Updated**: 2025-11-11
**Status**: Fully Functional
**Requirements**: OCaml compiler with DWARF support, LLDB or GDB

---

Happy Debugging! 🐛🔍
