# OCaml DWARF Future Work

**Version**: 1.0
**Date**: 2025-11-12

---

## Table of Contents

1. [Completed Enhancements](#completed-enhancements)
2. [Deferred Enhancements](#deferred-enhancements)
3. [Known Limitations](#known-limitations)
4. [Future Possibilities](#future-possibilities)
5. [DWARF 5 Upgrade Path](#dwarf-5-upgrade-path)

---

## Completed Enhancements

These optional enhancements have been successfully implemented.

### 1. Automatic Type Inference ✅

**Status**: Fully implemented (Commit 4fbf5825)

**Description**:
Automatic type inference from `machtype_component` during code emission. The compiler automatically determines types for variables and parameters based on their register types.

**Implementation**:
- Modified `asmcomp/arm64/emit.mlp` to infer types from `Reg.typ`
- Modified `asmcomp/amd64/emit.mlp` with identical logic
- Type mapping:
  - `Cmm.Int` → "int"
  - `Cmm.Float` → "float"
  - `Cmm.Val` → "value"
  - `Cmm.Addr` → "value"

**Impact**: All variables and parameters now have type information in DWARF without manual annotation.

---

### 2. GDB Pretty-Printers ✅

**Status**: Fully implemented (Commit 4fbf5825)

**Description**:
Python module for GDB that provides pretty-printing for OCaml data types, making debugging sessions more readable.

**Created**: `runtime/ocaml-gdb.py`

**Supported Types**:
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
```

**Technical Details**:
- Uses OCaml value tagging scheme (TAG_MASK = 1, TAG_INT = 1)
- Inspects block headers to determine type tags (TAG_STRING = 252, TAG_DOUBLE = 253)
- Handles string length padding (last byte contains padding length)
- Implements list traversal with cycle detection (max 100 elements)

---

### 3. LLDB Formatters ✅

**Status**: Fully implemented (Commit 4fbf5825)

**Description**:
Python module for LLDB that provides data formatters (synthetic children and summaries) for OCaml types.

**Created**: `runtime/ocaml-lldb.py`

**Supported Types**:
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
```

**Technical Details**:
- Implements `__lldb_init_module` for auto-registration
- Uses LLDB's synthetic children API for expandable lists
- Provides summary strings for compact display
- Handles memory reading with proper error checking

---

## Deferred Enhancements

These enhancements require significant compiler pipeline changes and are deferred for future work.

### 4. Inlined Function Support ⚠️

**Status**: Deferred - requires compiler pipeline changes

**Reason**: Information not available at emission level

**Description**:
Full support for tracking inlined functions with `DW_TAG_inlined_subroutine` DIEs.

#### Why Deferred

OCaml performs function inlining during the Flambda optimization phase (or Closure phase), which occurs **before** the Linear IR emission phase where DWARF information is generated. By the time code reaches `emit.mlp`:
- Code has been flattened
- Inlining information is no longer available
- No metadata indicates which functions were inlined or where

#### Required Changes

To implement inlined function support, the following architectural changes would be needed:

**1. Preserve Inlining Metadata** (Flambda/Closure Phase):
- Track which functions were inlined
- Preserve original source locations for inlined code
- Record call sites where inlining occurred
- Add data structures to IR:
  ```ocaml
  type inlining_info = {
    original_function : string;
    call_site_file : int;
    call_site_line : int;
    call_site_column : int;
    inlined_range : (label * label);
  }
  ```

**2. Propagate Through Pipeline** (Cmm → Mach → Linear):
- Extend Cmm IR with inlining metadata field
- Extend Mach IR to carry inlining info
- Extend Linear IR to preserve inlining through register allocation
- Maintain mapping from code ranges to inlined functions

**3. DWARF Emission** (emit.mlp):
- Generate `DW_TAG_inlined_subroutine` DIEs for each inlined instance
- Add `DW_AT_abstract_origin` pointing to original function DIE
- Add `DW_AT_call_file`, `DW_AT_call_line`, `DW_AT_call_column` for call sites
- Generate proper address ranges for inlined code sections
- Track variable locations across inlined boundaries with location lists

#### Existing Infrastructure

The low-level DWARF infrastructure already supports:
- `DW_TAG_inlined_subroutine` tag (in `dwarf_tag.ml`)
- `DW_AT_inline` attribute (in `dwarf_attributes.ml`)
- `DW_AT_abstract_origin` attribute
- `DW_AT_call_file`, `DW_AT_call_line`, `DW_AT_call_column` attributes

#### Example DWARF Structure

```
DW_TAG_subprogram (original function "helper")
  DW_AT_name: "helper"
  DW_AT_inline: DW_INL_inlined
  DW_TAG_formal_parameter (n)

DW_TAG_subprogram (caller function "main")
  DW_AT_name: "main"
  DW_AT_low_pc: 0x1000
  DW_AT_high_pc: 0x1100

  DW_TAG_inlined_subroutine
    DW_AT_abstract_origin: <offset of helper>
    DW_AT_low_pc: 0x1020
    DW_AT_high_pc: 0x1050
    DW_AT_call_file: 1
    DW_AT_call_line: 42
    DW_AT_call_column: 10
```

#### Effort Estimate

- **Time**: 3-4 weeks for experienced compiler engineer
- **Risk**: Medium (requires changes to multiple compiler phases)
- **Testing**: Extensive (must work across optimization levels)

---

### 5. Closure Variable Tracking ⚠️

**Status**: Deferred - requires compiler pipeline changes

**Reason**: Information not available at emission level

**Description**:
Track variables captured in closure environments with their locations within closure blocks.

#### Why Deferred

Similar to inlined functions, closure creation and environment tracking happens during the **Closure phase**, before Linear IR emission. At emission time:
- Closures appear as opaque blocks with `TAG_CLOSURE` (247)
- Environment variables are accessed as memory offsets
- No metadata indicates which variables are in the environment
- No source-level variable names are preserved
- No mapping from closure fields to original variables

#### Required Changes

To implement closure variable tracking, the following would be needed:

**1. Extend Closure Phase**:
- Preserve closure environment information
- Track captured variables (names, types, offsets in closure block)
- Record the mapping of source variables to closure fields
- Add metadata structure:
  ```ocaml
  type closure_env_var = {
    var_name : string;
    var_type : Types.type_expr;
    closure_offset : int;  (* Offset in closure block *)
    source_location : Location.t;
  }

  type closure_info = {
    closure_id : int;
    captured_vars : closure_env_var list;
  }
  ```

**2. Propagate Through Pipeline**:
- Extend Cmm/Mach/Linear IR with closure metadata
- Track which register holds the closure pointer
- Maintain closure_info through register allocation
- Handle nested closures (closures within closures)

**3. DWARF Emission**:
- Generate lexical block DIEs for closure scopes
- Create variable DIEs for each captured variable
- Generate location expressions pointing into closure blocks:
  ```
  DW_OP_breg0 <closure_reg>
  DW_OP_plus_uconst <field_offset>
  DW_OP_deref
  ```
- Handle closure pointer location (register or stack)

#### Example OCaml Code

```ocaml
let make_counter start =
  let count = ref start in           (* captured in closure *)
  fun () ->
    incr count;                       (* accesses closure field *)
    !count
```

#### Desired DWARF Structure

```
DW_TAG_subprogram (make_counter)
  DW_AT_name: "make_counter"
  DW_TAG_formal_parameter (start)

  DW_TAG_lexical_block (closure for anonymous function)
    DW_AT_low_pc: 0x1020
    DW_AT_high_pc: 0x1050

    DW_TAG_variable (count)
      DW_AT_name: "count"
      DW_AT_type: <ref type>
      DW_AT_location: <expression>
        DW_OP_breg5         ; closure in register 5
        DW_OP_plus_uconst 8 ; offset 8 in closure
        DW_OP_deref         ; dereference to get value
```

#### Implementation Challenges

1. **Closure Pointer Location**: Track which register/stack slot holds closure
2. **Nested Closures**: Handle closures that capture closures
3. **Free Variable Analysis**: Thread free variable info from Lambda IR
4. **Offset Calculation**: Accurately compute closure field offsets
5. **Lifetime Tracking**: Determine when closure variables are live

#### Effort Estimate

- **Time**: 3-4 weeks for experienced compiler engineer
- **Risk**: Medium-High (requires deep closure representation knowledge)
- **Testing**: Extensive (many edge cases with nested closures)

---

## Known Limitations

### 1. Closure Variable Inspection

**Limitation**: Captured variables in closures are not visible by name.

**Example**:
```ocaml
let make_adder x =
  fun y -> x + y  (* 'x' captured but not tracked *)
```

**Current State**: Closure appears as memory block; `x` is not visible by name.

**Workaround**: Inspect closure as raw memory block and manually decode fields.

**Impact**: Moderate - closures can still be debugged, just not as conveniently.

---

### 2. Optimized-Out Variables

**Limitation**: Variables optimized away by compiler are not available.

**Example**:
```ocaml
let f x =
  let temp = x + 1 in  (* May be optimized out *)
  temp * 2
```

**Current State**: With `-O2` or `-O3`, intermediate variables may not exist in code.

**Workaround**: Compile with `-O0` or `-O1` for debugging.

**Impact**: Expected behavior - same as C/C++.

---

### 3. Module-Level Values

**Limitation**: Module-level values not fully tracked.

**Example**:
```ocaml
let global_config = { timeout = 30; retries = 3 }  (* Module-level *)
```

**Current State**: Function-level debugging works; module-level values have limited support.

**Workaround**: Use functions to access module-level values.

**Impact**: Low - most debugging is function-scoped.

---

## Future Possibilities

### 1. Enhanced Pretty-Printers

**Description**: Extend GDB/LLDB formatters to support more OCaml types.

**Additional Types**:
- Records (display as `{ x = 10; y = 20 }`)
- Variants (display as `Some 42` or `Error "msg"`)
- Arrays (display as `[|1; 2; 3|]`)
- Hashtables (display key-value pairs)
- Custom block types (identify by tag)

**Effort**: 1-2 weeks

**Benefit**: Significantly improved debugging experience

---

### 2. Location Lists (.debug_loc)

**Description**: Full implementation of `.debug_loc` for tracking variable movement.

**Current State**: Infrastructure exists but not actively used.

**Enhancement**:
- Track variables that move between registers during execution
- Generate location list entries for each code range
- Update location as variable spills/reloads

**Example**:
```
Variable "x":
  0x1000-0x1020: in register 5
  0x1020-0x1030: in memory at FP-24
  0x1030-0x1040: in register 5
```

**Effort**: 2-3 weeks

**Benefit**: Accurate variable inspection throughout function execution

---

### 3. Exception Information

**Description**: DWARF support for OCaml exception handling.

**Enhancement**:
- Track exception types
- Show exception values in debugger
- Step into exception handlers
- Display exception backtraces with DWARF info

**Effort**: 2-3 weeks

**Benefit**: Better exception debugging

---

### 4. Module-Level Variable Support

**Description**: Full DWARF support for module-level values and functions.

**Enhancement**:
- Generate `DW_TAG_variable` for module-level bindings
- Track module initialization
- Support module namespacing in debugger

**Effort**: 1-2 weeks

**Benefit**: Complete variable tracking at all scopes

---

### 5. Source Path Mapping

**Description**: Support for remapped source paths in DWARF.

**Use Case**: Debugging binaries built on different machines.

**Enhancement**:
- Add `DW_AT_comp_dir` remapping
- Support debugger source path substitution
- Add compiler flag for source path prefix mapping

**Example**:
```bash
# Build on CI server
ocamlopt -g -fdebug-prefix-map=/build/=/home/user/ program.ml

# Debug locally
lldb program
(lldb) settings set target.source-map /build/ /home/user/
```

**Effort**: 1 week

**Benefit**: Easier remote debugging and CI integration

---

## DWARF 5 Upgrade Path

### Motivation for DWARF 5

**Benefits**:
- Better type system (improved type units)
- Faster symbol lookup (name index tables)
- More efficient encoding (smaller debug info)
- Better split DWARF support (separate debug files)
- Improved location expressions

### Changes Required

**1. Update Tags and Attributes**:
- Add new DWARF 5 tags (DW_TAG_call_site, etc.)
- Add new attributes (DW_AT_call_all_calls, etc.)
- Update form encodings (DW_FORM_strx, DW_FORM_addrx)

**2. Implement New Sections**:
- `.debug_addr` - Address table
- `.debug_str_offsets` - String offset table
- `.debug_rnglists` - Range lists (replaces .debug_ranges)
- `.debug_loclists` - Location lists (replaces .debug_loc)
- `.debug_names` - Name index

**3. Update Line Number Program**:
- New DWARF 5 line number program format
- Better directory and file name handling
- MD5 checksums for source files

**4. Backward Compatibility**:
- Support both DWARF 4 and DWARF 5 output
- Add compiler flag: `-gdwarf-4` vs `-gdwarf-5`
- Ensure debugger compatibility

### Implementation Strategy

**Phase 1** (2 weeks):
- Update low-level primitives (tags, attributes, forms)
- Add DWARF 5 section definitions
- Implement new encoding formats

**Phase 2** (2 weeks):
- Implement new sections (.debug_addr, .debug_str_offsets)
- Update string table handling
- Implement address table

**Phase 3** (2 weeks):
- Update line number program to DWARF 5 format
- Implement MD5 checksums
- Update name index generation

**Phase 4** (1 week):
- Testing on all platforms
- Debugger compatibility verification
- Performance benchmarking

**Total Effort**: 4-6 weeks

### Debugger Requirements

| Debugger | DWARF 5 Support |
|----------|-----------------|
| LLDB 10+ | ✅ Full |
| GDB 10+ | ✅ Full |
| GDB 8-9 | 🟡 Partial |
| LLDB 6-9 | 🟡 Partial |

**Recommendation**: Maintain DWARF 4 support for compatibility, add DWARF 5 as opt-in.

---

## Summary

### Completed ✅
- Automatic type inference
- GDB pretty-printers
- LLDB formatters

### Deferred ⚠️
- Inlined function support (requires pipeline changes)
- Closure variable tracking (requires pipeline changes)

### Future Possibilities 🔮
- Enhanced pretty-printers (records, variants, arrays)
- Location lists for variable movement tracking
- Exception information in DWARF
- Module-level variable support
- Source path mapping
- DWARF 5 upgrade

The current DWARF implementation provides production-ready debugging for OCaml native code. The deferred enhancements require significant compiler architecture changes and should be considered for future major versions. The future possibilities can be implemented incrementally as needed by the OCaml community.
