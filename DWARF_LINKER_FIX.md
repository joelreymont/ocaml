# Critical Bug Fixes: DWARF Symbol Linkage

## Issues Discovered

When DWARF debugging was enabled, the compiler failed during the linking phase with "undefined reference" errors:

### Issue 1: Function End Labels Not Global

```
/usr/bin/ld: stdlib.a(tmc.o):(.debug_info+0x7be): undefined reference to `camlTmc.let$242b_824_end'
/usr/bin/ld: stdlib.a(stdlib.o):(.debug_info+0x3a9): undefined reference to `camlStdlib.$245e_139_end'
... (many more similar errors)
```

###Issue 2: Double-Encoding of Symbol Names

After fixing Issue 1, the linker still reported errors for nested functions:

```
/usr/bin/ld: stdlib.a(stdlib__Option.o):(.debug_info+0x39e): undefined reference to `camlStdlib__Option.let$242b_500'
/usr/bin/ld: stdlib.a(stdlib__Option.o):(.debug_info+0x3a6): undefined reference to `camlStdlib__Option.let$242b_500_end'
```

The object file contained:
- **Defined**: `camlStdlib__Option.let$2b_500` (hex encoding of "+")
- **Referenced**: `camlStdlib__Option.let$242b_500` (double-encoded: "$" → "$24", "+" → "$2b")

## Root Causes

### Issue 1 Root Cause

The DWARF implementation creates function DIEs with PC ranges specified by start and end labels:
- Start label: `camlFunctionName` (already marked global)
- End label: `camlFunctionName_end` (NOT marked global)

The `.debug_info` section contains symbolic references to these end labels. When the linker processes multiple object files:
1. It encounters relocations referencing `camlFunctionName_end`
2. It searches for the symbol definition
3. **FAILURE**: The end label was emitted but not marked as global, so it's only visible within its object file
4. Linker reports "undefined reference"

### Issue 2 Root Cause

Symbol names with special characters are encoded for assembly output:
1. `emit.mlp` calls `emit_symbol("camlStdlib__Option.let+_500")` → returns `"camlStdlib__Option.let$2b_500"`
2. This ENCODED string was passed to `Code_address.from_label`
3. `emitaux.ml:format_symbol_for_dwarf` encoded it AGAIN: `"let$2b_500"` → `"let$242b_500"`
   - The "$" character (0x24) got encoded as "$24"

This caused a mismatch between defined symbols (single-encoded) and DWARF references (double-encoded).

## Solutions

### Solution 1: Make End Labels Global

Make function end labels globally visible by declaring them with the appropriate directive:

### Solution 1: AMD64 (emit.mlp)
```ocaml
(* Before - end label not global *)
D.label end_label;

(* After - end label declared global *)
let encoded_end_label = emit_symbol end_label_name in
if system = S_macosx && not Config.function_sections
    && is_generic_function fundecl.fun_name
  then
    D.private_extern encoded_end_label
  else
    D.global encoded_end_label;
D.label encoded_end_label;
```

### Solution 1: ARM64 (emit.mlp)
```ocaml
(* Before - end label not global *)
`{emit_symbol end_label}:\n`;

(* After - end label declared global *)
`	.globl	{emit_symbol end_label}\n`;
`{emit_symbol end_label}:\n`;
```

### Solution 2: Fix Double-Encoding

Pass UNENCODED symbol names to DWARF, letting the DWARF emitter handle encoding:

### Solution 2: AMD64 (emit.mlp)
```ocaml
(* Before - double encoding *)
let start_label = emit_symbol fundecl.fun_name in
let start_addr = Code_address.from_label start_label in  (* Encoded string *)

(* After - single encoding *)
let start_addr = Code_address.from_label fundecl.fun_name in  (* Unencoded name *)
let end_addr = Code_address.from_label (fundecl.fun_name ^ "_end") in
```

ARM64 already had this correct - it always passed unencoded names.

## Technical Details

### Why End Labels Need to be Global

DWARF uses symbolic relocations for PC addresses:
```assembly
.section .debug_info
    .quad camlFoo          # Start address (relocation)
    .quad camlFoo_end      # End address (relocation)
```

The assembler generates relocation entries:
```
RELOCATION RECORDS FOR [.debug_info]:
OFFSET   TYPE              VALUE
0x002c   R_X86_64_64       camlFoo
0x0034   R_X86_64_64       camlFoo_end
```

The linker must resolve these relocations across object files. If `camlFoo_end` is not exported, the linker cannot find it in other translation units.

### Visibility Semantics

The fix follows the same visibility pattern as function start labels:
- **Linux/ELF**: `.global` - makes symbol visible to linker
- **macOS (generic functions)**: `.private_extern` - visible during linking but not exported from final binary
- **macOS (non-generic)**: `.global` - fully exported

This ensures:
1. Linker can resolve DWARF relocations
2. Symbol visibility matches function start labels
3. Platform-specific linking semantics are preserved

## Testing

### Before Fix
```bash
$ make world.opt
...
/usr/bin/ld: undefined reference to `camlFoo_end'
collect2: error: ld returned 1 exit status
make: *** [ocamlc.opt] Error 2
```

### After Fix
```bash
$ make world.opt
... (build completes successfully)
$ ./ocamlopt.opt -g test.ml
$ readelf -r test.o | grep _end
0x0034  R_X86_64_64  camlTest_add_274_end  # Relocation present
$ nm test.o | grep _end
0000000000000010 T camlTest_add_274_end   # Symbol is global (T)
$ ./test
(program runs successfully)
```

## Impact

**Before**: Build failed during linking phase with undefined symbol errors - DWARF was completely unusable
**After**: Build succeeds - DWARF fully functional

These were **critical blockers** preventing the DWARF implementation from being used at all:
1. Issue 1 blocked compilation of the compiler itself
2. Issue 2 blocked compilation of ANY code using nested/local functions (which is most OCaml code)

## Files Changed

### Both Fixes
- `asmcomp/amd64/emit.mlp`:
  - Added global/private_extern declaration for end labels
  - Fixed double-encoding by passing unencoded names to DWARF
- `asmcomp/arm64/emit.mlp`:
  - Added .globl directive for end labels
  - Already passed unencoded names (no change needed for Issue 2)

## Related Work

This fix complements:
- Milestone 1: Enhanced primitive types (completed)
- Phase 5-6 documentation (completed)

All three pieces together provide:
1. Working build system (this fix)
2. Enhanced type support (Milestone 1)
3. Implementation roadmap (documentation)
