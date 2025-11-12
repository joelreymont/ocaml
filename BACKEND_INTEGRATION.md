# DWARF Backend Integration

## Overview

This document describes the integration of DWARF debugging information into the OCaml native code compiler backends for ARM64 and AMD64 architectures.

## Architecture

### Components

The DWARF integration consists of three main layers:

1. **DWARF Infrastructure** (Phases 1-2)
   - Low-level DWARF primitives (tags, attributes, forms, LEB128 encoding)
   - High-level API (Proto_die, Dwarf_world, abbreviation assignment)
   - OCaml entry point (Dwarf module)

2. **Backend Helper Module** (`emitaux.ml`)
   - `Dwarf_helpers` module provides integration points
   - Manages DWARF state across compilation
   - Emits DWARF sections to assembly output

3. **Architecture-Specific Emitters**
   - ARM64: `asmcomp/arm64/emit.mlp`
   - AMD64: `asmcomp/amd64/emit.mlp`

### Integration Points

#### 1. Compilation Start (`begin_assembly()`)

Called once at the beginning of assembly file emission.

**ARM64 (`arm64/emit.mlp:1247`)**:
```ocaml
let begin_assembly() =
  reset_debug_info();
  (* Initialize DWARF generation if enabled *)
  if Dwarf_flags.is_dwarf_enabled () then begin
    let unit_name = Compilenv.current_unit_name () in
    let source_file = unit_name ^ ".ml" in
    let compilation_dir = Sys.getcwd () in
    let producer = "OCaml " ^ Sys.ocaml_version in
    Emitaux.Dwarf_helpers.init ~source_file ~compilation_dir ~producer
  end;
  (* ... rest of function ... *)
```

**AMD64 (`amd64/emit.mlp:977`)**:
```ocaml
let begin_assembly() =
  X86_proc.reset_asm_code ();
  reset_debug_info();
  reset_imp_table();
  float_constants := [];
  all_functions := [];
  (* Initialize DWARF generation if enabled *)
  if Dwarf_flags.is_dwarf_enabled () then begin
    let unit_name = Compilenv.current_unit_name () in
    let source_file = unit_name ^ ".ml" in
    let compilation_dir = Sys.getcwd () in
    let producer = "OCaml " ^ Sys.ocaml_version in
    Emitaux.Dwarf_helpers.init ~source_file ~compilation_dir ~producer
  end;
  (* ... rest of function ... *)
```

#### 2. Function Emission (`fundecl`)

Called for each function being compiled.

**ARM64 (`arm64/emit.mlp:1211`)**:
```ocaml
cfi_endproc();
(* Track function for DWARF debugging information *)
if Dwarf_flags.is_dwarf_enabled () then begin
  let start_addr = Code_address.from_label (fundecl.fun_name) in
  let end_label = fundecl.fun_name ^ "_end" in
  `{emit_symbol end_label}:\n`;
  let end_addr = Code_address.from_label end_label in
  Emitaux.Dwarf_helpers.add_function
    ~name:fundecl.fun_name
    ~start_address:start_addr
    ~end_address:end_addr
end;
emit_type_directive fundecl.fun_name "%function";
```

**AMD64 (`amd64/emit.mlp:945`)**:
```ocaml
cfi_endproc ();
(* Track function for DWARF debugging information *)
if Dwarf_flags.is_dwarf_enabled () then begin
  let start_addr = Code_address.from_label (fundecl.fun_name) in
  let end_label = fundecl.fun_name ^ "_end" in
  D.label (emit_symbol end_label);
  let end_addr = Code_address.from_label end_label in
  Emitaux.Dwarf_helpers.add_function
    ~name:fundecl.fun_name
    ~start_address:start_addr
    ~end_address:end_addr
end;
if Config.asm_size_type_directives then begin
```

#### 3. Compilation End (`end_assembly()`)

Called once at the end of assembly file emission.

**ARM64 (`arm64/emit.mlp:1310`)**:
```ocaml
emit_type_directive lbl "%object";
emit_size_directive lbl;
emit_nonexecstack_note ();
(* Emit DWARF debugging sections if enabled *)
if Dwarf_flags.is_dwarf_enabled () then begin
  Emitaux.Dwarf_helpers.emit_dwarf stdout
end
```

**AMD64 (`amd64/emit.mlp:1120`)**:
```ocaml
X86_proc.generate_code asm;
(* Emit DWARF debugging sections if enabled *)
if Dwarf_flags.is_dwarf_enabled () && !Emitaux.create_asm_file then begin
  Emitaux.Dwarf_helpers.emit_dwarf !Emitaux.output_channel
end
```

## DWARF Section Emission

### Platform-Specific Section Names

**macOS (Mach-O format)**:
- `__DWARF,__debug_info` - Compilation unit and DIE data
- `__DWARF,__debug_abbrev` - Abbreviation table
- `__DWARF,__debug_str` - String table
- `__DWARF,__debug_line` - Line number information (future)
- `__DWARF,__debug_loc` - Location lists (future)
- `__DWARF,__debug_ranges` - Range lists (future)

**Linux (ELF format)**:
- `.debug_info` - Compilation unit and DIE data
- `.debug_abbrev` - Abbreviation table
- `.debug_str` - String table
- `.debug_line` - Line number information (future)
- `.debug_loc` - Location lists (future)
- `.debug_ranges` - Range lists (future)

### Byte Emission Format

DWARF data is emitted as assembly `.byte` directives:

```assembly
	.section __DWARF,__debug_info,regular,debug
	.byte 0x64,0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x08,0x01,0x03
	.byte 0x74,0x65,0x73,0x74,0x00,0x2f,0x70,0x61,0x74,0x68,0x2f,0x74,0x6f
	...
```

## Current Implementation Status

### ✅ Implemented

- DWARF initialization on compilation start
- Function tracking with start/end labels
- DWARF section emission at compilation end
- Platform detection (macOS vs Linux)
- Section format support (Mach-O vs ELF)
- LEB128 encoding for abbreviation tables
- Proper DIE data encoding
- String table management
- Abbreviation table generation

### 🚧 Partial / Future Work

- **Line number information** (`.debug_line`)
  - Requires tracking source locations during emission
  - Would integrate with existing `emit_debug_info fundecl.fun_dbg` calls

- **Variable location tracking** (`.debug_loc`)
  - Requires analyzing register allocation
  - Would integrate with Linear IR analysis (Phase 3)

- **Type information**
  - Requires OCaml type system integration (Phase 4)
  - Would emit DIEs for OCaml types (variants, records, etc.)

- **Inlined function tracking**
  - Requires tracking inlining decisions
  - Would emit `DW_TAG_inlined_subroutine` DIEs

## Enabling DWARF Emission

### Compiler Flags

DWARF emission is controlled by two flags:

1. `-g` - Enable debugging information (already exists)
2. Environment variable `OCAMLPARAM="dwarf_fidelity=enhanced"` - Enable DWARF

### Example Usage

```bash
# Set DWARF fidelity
export OCAMLPARAM="dwarf_fidelity=enhanced"

# Compile with debug info
ocamlopt -g -o test test.ml

# Verify DWARF sections (macOS)
otool -l test | grep -A 5 __DWARF
dwarfdump test

# Verify DWARF sections (Linux)
readelf -S test | grep debug
readelf -w test
```

## Testing

### Manual Testing

1. Compile a simple OCaml program with `-g` and DWARF enabled
2. Use `dwarfdump` (macOS) or `readelf -w` (Linux) to verify sections
3. Use `lldb` or `gdb` to verify debugger can read DWARF info

### Test Programs

See `testsuite/tests/asmcomp/dwarf/` for test cases:
- `test_basic.ml` - Simple function testing
- `test_types.ml` - Complex type testing
- `verify_dwarf.sh` - Automated verification script
- `lldb_test.sh` - LLDB integration test

## Architecture Notes

### ARM64-Specific

- Uses backtick syntax for assembly emission: `` `{emit_symbol label}:\n` ``
- Outputs to `stdout`
- Section directives use `.section` with segment,section syntax

### AMD64-Specific

- Uses DSL (D.label, D.section, etc.) for assembly emission
- Outputs to `!Emitaux.output_channel`
- Has multiple assembly syntax backends (GAS, MASM)
- Windows (MASM) requires different handling (not yet implemented for DWARF)

## Future Integration Points

### Phase 3: Debug Analysis

Add to Linear IR processing:
- Track variable lifetimes
- Record register assignments
- Build location lists for variables

### Phase 4: Type System

Add to type checker/typedtree:
- Collect type information
- Generate type DIEs
- Link value DIEs to type DIEs

### Phase 5: Line Numbers

Add to instruction emission:
- Track source positions
- Build line number table
- Emit `.debug_line` section

## References

- [DWARF 4 Specification](http://dwarfstd.org/doc/DWARF4.pdf)
- OCaml Compiler: `HACKING.adoc`
- Implementation Plan: `DWARF_IMPLEMENTATION_PLAN.md`
- Phase Summaries: `PHASE1_COMPLETE.md`, `PHASE2_COMPLETE.md`

## Author

Joel Reymont <18791+joelreymont@users.noreply.github.com>

Date: 2025-11-11

Branch: `claude/ocaml-dwarf-macos-011CV1uGdeHWum1FF3CXBfSq`
