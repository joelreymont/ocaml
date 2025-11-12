# Optional Enhancements Status

This document tracks the status of optional enhancements requested for the OCaml DWARF implementation.

## Completed Enhancements

### 1. Automatic Type Inference ✓

**Status**: Fully implemented
**Commit**: 4fbf5825

**Description**:
Automatic type inference from `machtype_component` during code emission. The compiler now automatically determines types for variables and parameters based on their register types.

**Implementation**:
- Modified `asmcomp/arm64/emit.mlp` to infer types from `Reg.typ`
- Modified `asmcomp/amd64/emit.mlp` with identical logic
- Type mapping:
  - `Cmm.Int` → "int"
  - `Cmm.Float` → "float"
  - `Cmm.Val` → "value"
  - `Cmm.Addr` → "value"

**Files Modified**:
- `asmcomp/arm64/emit.mlp`
- `asmcomp/amd64/emit.mlp`

**Testing**:
Works automatically for all functions during compilation. Type information is included in DWARF output for all variables and parameters.

---

### 2. GDB Pretty-Printers ✓

**Status**: Fully implemented
**Commit**: 4fbf5825

**Description**:
Python module for GDB that provides pretty-printing for OCaml data types, making debugging sessions more readable.

**Implementation**:
Created `runtime/ocaml-gdb.py` with pretty-printers for:
- Integers (decode tagged ints)
- Booleans (true/false)
- Lists (display as `[1; 2; 3]`)
- Strings (decode with length padding)
- Floats (boxed doubles)
- Options (None/Some)

**Usage**:
```bash
gdb myprogram
(gdb) source runtime/ocaml-gdb.py
(gdb) # OCaml values now display in readable format
```

Or add to `.gdbinit`:
```
source /path/to/ocaml/runtime/ocaml-gdb.py
```

**Technical Details**:
- Uses OCaml value tagging scheme (TAG_MASK = 1, TAG_INT = 1)
- Inspects block headers to determine type tags
- Handles string length padding (last byte)
- Implements list traversal with cycle detection

---

### 3. LLDB Formatters ✓

**Status**: Fully implemented
**Commit**: 4fbf5825

**Description**:
Python module for LLDB that provides data formatters (synthetic children and summaries) for OCaml types.

**Implementation**:
Created `runtime/ocaml-lldb.py` with formatters for:
- Integers (summary provider)
- Booleans (summary provider)
- Lists (synthetic children + summary)
- Strings (summary provider)
- Floats (summary provider)
- Options (summary provider)

**Usage**:
```bash
lldb myprogram
(lldb) command script import runtime/ocaml-lldb.py
(lldb) # OCaml values now display in readable format
```

Or add to `.lldbinit`:
```
command script import /path/to/ocaml/runtime/ocaml-lldb.py
```

**Technical Details**:
- Implements `__lldb_init_module` for auto-registration
- Uses LLDB's synthetic children API for expandable lists
- Provides summary strings for compact display
- Handles memory reading with proper error checking

---

## Deferred Enhancements

### 4. Inlined Function Support ⚠️

**Status**: Deferred - requires compiler pipeline changes
**Reason**: Information not available at emission level

**Description**:
Full support for tracking inlined functions with `DW_TAG_inlined_subroutine` DIEs.

**Why Deferred**:
OCaml performs function inlining during the Flambda optimization phase (or Closure phase), which occurs before the Linear IR emission phase where DWARF information is generated. By the time code reaches `emit.mlp`, the code has been flattened and inlining information is no longer available.

**Required Changes**:
To implement inlined function support properly, the following changes would be needed:

1. **Preserve Inlining Metadata**: Extend the IR to carry inlining information through to emission:
   - Track which functions were inlined
   - Preserve original source locations for inlined code
   - Record call sites where inlining occurred

2. **Extend Flambda/Closure Phase**: Modify the optimization phases to record inlining decisions:
   - Add data structures to track inlining contexts
   - Propagate this information to Cmm/Mach/Linear IRs

3. **Extend DWARF Emission**: Update emission to generate:
   - `DW_TAG_inlined_subroutine` DIEs for each inlined instance
   - `DW_AT_abstract_origin` pointing to original function DIE
   - `DW_AT_call_file`, `DW_AT_call_line`, `DW_AT_call_column` for call sites
   - Proper address ranges for inlined code sections

**Existing Infrastructure**:
The low-level DWARF infrastructure already supports:
- `DW_TAG_inlined_subroutine` tag (in `dwarf_tag.ml`)
- `DW_AT_inline` attribute (in `dwarf_attributes.ml`)
- `DW_AT_abstract_origin` attribute

**Future Implementation Notes**:
- Inlining information would need to be tracked in a new field in the Mach or Linear IR
- Each inlined call would need: `(caller_location, callee_function, start_address, end_address)`
- During emission, create inlined_subroutine DIEs as children of the caller function
- Use location lists to track variable locations across inlined boundaries

**Example DWARF Structure** (for reference):
```
DW_TAG_subprogram (original function "foo")
  DW_AT_name: "foo"
  DW_AT_inline: DW_INL_inlined

DW_TAG_subprogram (caller function "main")
  DW_AT_name: "main"
  DW_TAG_inlined_subroutine
    DW_AT_abstract_origin: <offset of foo>
    DW_AT_low_pc: 0x1234
    DW_AT_high_pc: 0x1250
    DW_AT_call_file: 1
    DW_AT_call_line: 42
```

---

### 5. Closure Variable Tracking ⚠️

**Status**: Deferred - requires compiler pipeline changes
**Reason**: Information not available at emission level

**Description**:
Track variables captured in closure environments with their locations within closure blocks.

**Why Deferred**:
Similar to inlined functions, closure creation and environment tracking happens during the Closure phase, before the Linear IR emission. At emission time:
- Closures appear as opaque blocks with `TAG_CLOSURE` (247)
- Environment variables are accessed as memory offsets
- No metadata indicates which variables are in the environment
- No source-level variable names are preserved

**Required Changes**:
To implement closure variable tracking, the following would be needed:

1. **Extend Closure Phase**: Preserve closure environment information:
   - Track captured variables (names, types, offsets)
   - Record the mapping of source variables to closure fields
   - Propagate this through to Linear IR

2. **Add Closure Metadata**: Extend IR with:
   - Closure ID or unique identifier
   - List of captured variables with their positions
   - Original variable names and source locations

3. **DWARF Emission**: Generate:
   - Lexical block DIEs for closure scopes
   - Variable DIEs for each captured variable
   - Location expressions pointing into closure blocks:
     ```
     DW_OP_breg0 <closure_reg>
     DW_OP_plus_uconst <field_offset>
     DW_OP_deref
     ```

**Example Closure**:
```ocaml
let make_counter start =
  let count = ref start in           (* captured in closure *)
  fun () ->
    incr count;                       (* accesses closure field *)
    !count
```

**Desired DWARF** (for reference):
```
DW_TAG_subprogram (make_counter)
  DW_TAG_lexical_block (closure for anonymous function)
    DW_TAG_variable (count)
      DW_AT_name: "count"
      DW_AT_type: <ref type>
      DW_AT_location: <expression>
        DW_OP_breg0 <closure_register>
        DW_OP_plus_uconst 8  (offset in closure)
        DW_OP_deref
```

**Future Implementation Notes**:
- Would require a `closure_info` field in Linear IR functions
- Need to track which register holds the closure pointer
- Must handle nested closures (closures within closures)
- Should track `free variables` from Lambda IR through to emission

---

## Summary

### Implementation Status
- **Completed**: 3 enhancements (automatic type inference, GDB pretty-printers, LLDB formatters)
- **Deferred**: 2 enhancements (inlined functions, closure variables)

### Working Features
The completed enhancements provide immediate value:
- Type information automatically appears in debuggers
- OCaml values display in human-readable format
- No manual type annotations needed

### Deferred Features - Path Forward
Both deferred features require architectural changes:
1. Modify earlier compiler phases (Flambda/Closure)
2. Extend intermediate representations
3. Propagate metadata through compilation pipeline
4. Update DWARF emission to use the metadata

These are significant undertakings that would touch many parts of the compiler and would be best addressed in a dedicated project focused on compiler instrumentation.

### Practical Impact
Despite deferring 2 enhancements, the DWARF implementation is fully functional:
- Line numbers: ✓
- Function names: ✓
- Parameter tracking: ✓
- Local variable tracking: ✓
- Type information: ✓ (with automatic inference)
- Pretty-printing: ✓ (GDB + LLDB)
- Inlined functions: ⚠️ (deferred)
- Closure variables: ⚠️ (deferred)

The current implementation provides a solid foundation for debugging OCaml native code.
