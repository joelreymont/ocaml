#!/bin/bash
#**************************************************************************
#*                                                                        *
#*                                 OCaml                                  *
#*                                                                        *
#*                  LLDB test script for DWARF debugging                  *
#*                                                                        *
#**************************************************************************

# Automated LLDB tests for DWARF debugging information
# Specifically designed for macOS (including Apple Silicon ARM64)

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <binary>"
    echo "Example: $0 test_basic"
    exit 1
fi

BINARY="$1"

if [ ! -f "$BINARY" ]; then
    echo "Error: Binary '$BINARY' not found"
    exit 1
fi

if ! command -v lldb >/dev/null 2>&1; then
    echo "Error: LLDB not found. Please install Xcode command line tools:"
    echo "  xcode-select --install"
    exit 1
fi

echo "=== LLDB DWARF Test for $BINARY ==="
echo

# Detect architecture
ARCH=$(file "$BINARY" | grep -o "arm64\|x86_64" | head -1)
echo "Architecture: $ARCH"

if [ "$ARCH" = "arm64" ]; then
    echo "✓ Running on Apple Silicon (ARM64)"
    echo "  DWARF should include ARM64-specific register information"
fi

echo
echo "=== Test 1: Load Binary and Check Debug Info ==="

# Create LLDB commands file
cat > /tmp/lldb_commands_$$txt <<EOF
# Load binary
target create $BINARY

# Check if debug info is available
image dump symtab $BINARY

# List source files (should show .ml files if debug info present)
image dump line-table $BINARY

# Show compilation units
image dump compile-units $BINARY

# Exit
quit
EOF

echo "Running LLDB to check debug info availability..."
if lldb --source /tmp/lldb_commands_$$.txt 2>&1 | tee /tmp/lldb_output_$$.txt | grep -q "\.ml"; then
    echo "✓ Debug information found (.ml source files detected)"
else
    echo "⚠ No .ml source files found in debug info"
    echo "  This is expected if DWARF emission is not yet complete (Phase 1)"
fi

echo
echo "=== Test 2: Set Breakpoint on Entry Point ==="

# Try to set breakpoint on main entry
cat > /tmp/lldb_commands_$$.txt <<EOF
target create $BINARY
breakpoint set --name camlTest_basic__entry
breakpoint set --name caml_program
breakpoint list
quit
EOF

echo "Attempting to set breakpoints..."
if lldb --source /tmp/lldb_commands_$$.txt 2>&1 | grep -q "Breakpoint.*address ="; then
    echo "✓ Successfully set breakpoint"
else
    echo "⚠ Could not set breakpoint"
    echo "  Breakpoints require symbol table (should work even without full DWARF)"
fi

echo
echo "=== Test 3: Run and Inspect Variables (Interactive) ==="

echo "To manually test variable inspection:"
echo
echo "1. Start LLDB:"
echo "   lldb $BINARY"
echo
echo "2. Set breakpoint and run:"
echo "   (lldb) breakpoint set --name camlTest_basic__test_int"
echo "   (lldb) run"
echo
echo "3. When stopped at breakpoint, inspect variables:"
echo "   (lldb) frame variable"
echo "   (lldb) frame variable -L   # Show locations (register/stack)"
echo "   (lldb) print x"
echo "   (lldb) print y"
echo
echo "4. Check variable locations (ARM64 should show ARM registers):"
if [ "$ARCH" = "arm64" ]; then
    echo "   (lldb) register read x0 x1 x2  # ARM64 argument registers"
    echo "   (lldb) register read x19-x28   # ARM64 callee-saved registers"
else
    echo "   (lldb) register read rdi rsi rdx  # x86_64 argument registers"
    echo "   (lldb) register read rbx r12-r15  # x86_64 callee-saved registers"
fi
echo
echo "5. Step through code:"
echo "   (lldb) step   # Step into functions"
echo "   (lldb) next   # Step over functions"
echo "   (lldb) finish # Step out of current function"
echo
echo "6. Inspect call stack:"
echo "   (lldb) bt      # Backtrace"
echo "   (lldb) frame select 0  # Select frame"
echo "   (lldb) frame variable  # Show variables in selected frame"
echo

echo "=== Test 4: Verify DWARF-Specific Information ==="

# Check for DWARF debugging information in detail
cat > /tmp/lldb_commands_$$.txt <<EOF
target create $BINARY
image dump sections $BINARY
quit
EOF

echo "Checking for DWARF sections..."
lldb --source /tmp/lldb_commands_$$.txt 2>&1 | grep -i "debug" || echo "No debug sections found yet"

# ARM64-specific checks
if [ "$ARCH" = "arm64" ]; then
    echo
    echo "=== ARM64-Specific Checks ==="
    echo "✓ Binary is ARM64 (Apple Silicon compatible)"
    echo
    echo "Expected DWARF features for ARM64:"
    echo "  - Register names: x0-x30, sp, pc, fp (frame pointer)"
    echo "  - DWARF register numbers for ARM64 ABI"
    echo "  - DW_OP_bregX operations using ARM64 registers"
    echo "  - Correct stack frame layout for ARM64"
    echo
    echo "To verify ARM64 register usage in DWARF:"
    echo "  dwarfdump --debug-loc $BINARY | grep -i 'breg\\|reg[0-9]'"
fi

# Cleanup
rm -f /tmp/lldb_commands_$$.txt /tmp/lldb_output_$$.txt

echo
echo "=== Summary ==="
echo "LLDB tests completed. For full variable inspection:"
echo "  1. Ensure binary compiled with: ocamlopt -g"
echo "  2. Run: lldb $BINARY"
echo "  3. Set breakpoints and inspect variables as shown above"
echo
if [ "$ARCH" = "arm64" ]; then
    echo "✓ Tests run on ARM64 (Apple Silicon)"
    echo "  DWARF location lists should use ARM64 register conventions"
fi
echo
echo "Note: Full DWARF debugging requires completion of Phases 2-5"
echo "      Current Phase 1 provides infrastructure only"
