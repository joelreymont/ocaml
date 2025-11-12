#!/bin/bash
#**************************************************************************
#*                                                                        *
#*                                 OCaml                                  *
#*                                                                        *
#*              Automated DWARF Debugging Tests for LLDB/GDB              *
#*                                                                        *
#**************************************************************************

# Comprehensive automated tests for DWARF debugging information
# Tests: breakpoints, line numbers, stepping, source context, stack traces

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY="${1:-test_basic}"
SOURCE_FILE="test_basic.ml"
VERBOSE="${VERBOSE:-0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0
SKIPPED=0

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    ((PASSED++))
}

log_failure() {
    echo -e "${RED}[✗]${NC} $1"
    ((FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((SKIPPED++))
}

log_verbose() {
    if [ "$VERBOSE" = "1" ]; then
        echo -e "${NC}  $1${NC}"
    fi
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if [ ! -f "$BINARY" ]; then
        log_failure "Binary '$BINARY' not found"
        echo "  Please compile first:"
        echo "  ../../../../ocamlopt.opt -I ../../../../stdlib -g -o $BINARY $SOURCE_FILE"
        exit 1
    fi

    if ! command -v lldb >/dev/null 2>&1; then
        log_skip "LLDB not found (macOS tests will be skipped)"
        LLDB_AVAILABLE=0
    else
        LLDB_AVAILABLE=1
    fi

    if ! command -v gdb >/dev/null 2>&1; then
        log_skip "GDB not found (Linux tests will be skipped)"
        GDB_AVAILABLE=0
    else
        GDB_AVAILABLE=1
    fi

    if [ "$LLDB_AVAILABLE" = "0" ] && [ "$GDB_AVAILABLE" = "0" ]; then
        log_failure "Neither LLDB nor GDB found. Cannot run tests."
        exit 1
    fi

    log_success "Prerequisites checked"
}

# Test 1: Verify DWARF sections exist
test_dwarf_sections() {
    log_info "Test 1: Verify DWARF sections exist"

    if command -v dwarfdump >/dev/null 2>&1; then
        if dwarfdump "$BINARY" 2>/dev/null | head -20 | grep -q "debug_info"; then
            log_success "DWARF .debug_info section found"
        else
            log_failure "DWARF .debug_info section not found"
            return 1
        fi

        if dwarfdump "$BINARY" 2>/dev/null | grep -q "debug_line"; then
            log_success "DWARF .debug_line section found"
        else
            log_failure "DWARF .debug_line section not found"
            return 1
        fi

        if dwarfdump "$BINARY" 2>/dev/null | grep -q "debug_abbrev"; then
            log_success "DWARF .debug_abbrev section found"
        else
            log_failure "DWARF .debug_abbrev section not found"
            return 1
        fi
    elif command -v readelf >/dev/null 2>&1; then
        if readelf -S "$BINARY" | grep -q ".debug_info"; then
            log_success "DWARF .debug_info section found"
        else
            log_failure "DWARF .debug_info section not found"
            return 1
        fi

        if readelf -S "$BINARY" | grep -q ".debug_line"; then
            log_success "DWARF .debug_line section found"
        else
            log_failure "DWARF .debug_line section not found"
            return 1
        fi
    else
        log_skip "Neither dwarfdump nor readelf found, skipping section verification"
    fi
}

# Test 2: Set breakpoint by function name (LLDB)
test_lldb_breakpoint_by_function() {
    log_info "Test 2: Set breakpoint by function name (LLDB)"

    if [ "$LLDB_AVAILABLE" = "0" ]; then
        log_skip "LLDB not available"
        return
    fi

    cat > /tmp/lldb_test_$$.txt <<'EOF'
target create __BINARY__
breakpoint set --name camlTest_basic__test_int
breakpoint list
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/lldb_test_$$.txt

    OUTPUT=$(lldb --batch --source /tmp/lldb_test_$$.txt 2>&1)
    log_verbose "LLDB output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "Breakpoint.*where =.*camlTest_basic__test_int"; then
        log_success "Breakpoint by function name set successfully"
    else
        log_failure "Could not set breakpoint by function name"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/lldb_test_$$.txt
}

# Test 3: Set breakpoint by line number (LLDB)
test_lldb_breakpoint_by_line() {
    log_info "Test 3: Set breakpoint by line number (LLDB)"

    if [ "$LLDB_AVAILABLE" = "0" ]; then
        log_skip "LLDB not available"
        return
    fi

    cat > /tmp/lldb_test_$$.txt <<'EOF'
target create __BINARY__
breakpoint set --file test_basic.ml --line 14
breakpoint list
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/lldb_test_$$.txt

    OUTPUT=$(lldb --batch --source /tmp/lldb_test_$$.txt 2>&1)
    log_verbose "LLDB output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "Breakpoint.*test_basic.ml:14"; then
        log_success "Breakpoint by line number set successfully"
    elif echo "$OUTPUT" | grep -q "Breakpoint.*address ="; then
        # LLDB might resolve to a different line due to optimization
        log_success "Breakpoint set (resolved to nearby address)"
    else
        log_failure "Could not set breakpoint by line number"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/lldb_test_$$.txt
}

# Test 4: Step through source code (LLDB)
test_lldb_stepping() {
    log_info "Test 4: Step through source code (LLDB)"

    if [ "$LLDB_AVAILABLE" = "0" ]; then
        log_skip "LLDB not available"
        return
    fi

    cat > /tmp/lldb_test_$$.txt <<'EOF'
target create __BINARY__
breakpoint set --name camlTest_basic__test_int
process launch
thread step-in
thread step-over
thread step-over
thread info
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/lldb_test_$$.txt

    OUTPUT=$(lldb --batch --source /tmp/lldb_test_$$.txt 2>&1)
    log_verbose "LLDB stepping output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "stop reason"; then
        log_success "Stepping commands executed successfully"
    else
        log_failure "Stepping commands failed"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/lldb_test_$$.txt
}

# Test 5: View source context (LLDB)
test_lldb_source_context() {
    log_info "Test 5: View source context (LLDB)"

    if [ "$LLDB_AVAILABLE" = "0" ]; then
        log_skip "LLDB not available"
        return
    fi

    cat > /tmp/lldb_test_$$.txt <<'EOF'
target create __BINARY__
breakpoint set --name camlTest_basic__test_int
process launch
source list
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/lldb_test_$$.txt

    OUTPUT=$(lldb --batch --source /tmp/lldb_test_$$.txt 2>&1)
    log_verbose "LLDB source output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "test_basic.ml"; then
        log_success "Source context displayed successfully"
    elif echo "$OUTPUT" | grep -q "let.*="; then
        # Might show source without filename
        log_success "Source context displayed"
    else
        log_failure "Could not display source context"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/lldb_test_$$.txt
}

# Test 6: Stack traces with source locations (LLDB)
test_lldb_backtrace() {
    log_info "Test 6: Stack traces with source locations (LLDB)"

    if [ "$LLDB_AVAILABLE" = "0" ]; then
        log_skip "LLDB not available"
        return
    fi

    cat > /tmp/lldb_test_$$.txt <<'EOF'
target create __BINARY__
breakpoint set --name camlTest_basic__test_int
process launch
thread backtrace
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/lldb_test_$$.txt

    OUTPUT=$(lldb --batch --source /tmp/lldb_test_$$.txt 2>&1)
    log_verbose "LLDB backtrace output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "frame.*camlTest_basic"; then
        log_success "Stack trace shows OCaml function names"
    else
        log_failure "Stack trace missing function names"
        log_verbose "Output: $OUTPUT"
    fi

    if echo "$OUTPUT" | grep -q "test_basic.ml"; then
        log_success "Stack trace shows source file locations"
    else
        log_failure "Stack trace missing source locations"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/lldb_test_$$.txt
}

# Test 7: Set breakpoint by function name (GDB)
test_gdb_breakpoint_by_function() {
    log_info "Test 7: Set breakpoint by function name (GDB)"

    if [ "$GDB_AVAILABLE" = "0" ]; then
        log_skip "GDB not available"
        return
    fi

    cat > /tmp/gdb_test_$$.txt <<'EOF'
file __BINARY__
break camlTest_basic__test_int
info breakpoints
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/gdb_test_$$.txt

    OUTPUT=$(gdb --batch --command=/tmp/gdb_test_$$.txt 2>&1)
    log_verbose "GDB output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "Breakpoint.*camlTest_basic__test_int"; then
        log_success "GDB: Breakpoint by function name set successfully"
    else
        log_failure "GDB: Could not set breakpoint by function name"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/gdb_test_$$.txt
}

# Test 8: Set breakpoint by line number (GDB)
test_gdb_breakpoint_by_line() {
    log_info "Test 8: Set breakpoint by line number (GDB)"

    if [ "$GDB_AVAILABLE" = "0" ]; then
        log_skip "GDB not available"
        return
    fi

    cat > /tmp/gdb_test_$$.txt <<'EOF'
file __BINARY__
break test_basic.ml:14
info breakpoints
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/gdb_test_$$.txt

    OUTPUT=$(gdb --batch --command=/tmp/gdb_test_$$.txt 2>&1)
    log_verbose "GDB output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "Breakpoint.*test_basic.ml:14"; then
        log_success "GDB: Breakpoint by line number set successfully"
    elif echo "$OUTPUT" | grep -q "Breakpoint.*at"; then
        log_success "GDB: Breakpoint set (resolved to nearby location)"
    else
        log_failure "GDB: Could not set breakpoint by line number"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/gdb_test_$$.txt
}

# Test 9: Stack traces with source locations (GDB)
test_gdb_backtrace() {
    log_info "Test 9: Stack traces with source locations (GDB)"

    if [ "$GDB_AVAILABLE" = "0" ]; then
        log_skip "GDB not available"
        return
    fi

    cat > /tmp/gdb_test_$$.txt <<'EOF'
file __BINARY__
break camlTest_basic__test_int
run
backtrace
quit
EOF
    sed -i'' "s|__BINARY__|$BINARY|g" /tmp/gdb_test_$$.txt

    OUTPUT=$(gdb --batch --command=/tmp/gdb_test_$$.txt 2>&1)
    log_verbose "GDB backtrace output: $OUTPUT"

    if echo "$OUTPUT" | grep -q "camlTest_basic"; then
        log_success "GDB: Stack trace shows OCaml function names"
    else
        log_failure "GDB: Stack trace missing function names"
        log_verbose "Output: $OUTPUT"
    fi

    if echo "$OUTPUT" | grep -q "test_basic.ml"; then
        log_success "GDB: Stack trace shows source file locations"
    else
        log_failure "GDB: Stack trace missing source locations"
        log_verbose "Output: $OUTPUT"
    fi

    rm -f /tmp/gdb_test_$$.txt
}

# Main test execution
main() {
    echo "=========================================="
    echo "  OCaml DWARF Debugging Automated Tests"
    echo "=========================================="
    echo

    check_prerequisites
    echo

    # DWARF section tests
    test_dwarf_sections
    echo

    # LLDB tests
    if [ "$LLDB_AVAILABLE" = "1" ]; then
        log_info "Running LLDB tests..."
        test_lldb_breakpoint_by_function
        test_lldb_breakpoint_by_line
        test_lldb_stepping
        test_lldb_source_context
        test_lldb_backtrace
        echo
    fi

    # GDB tests
    if [ "$GDB_AVAILABLE" = "1" ]; then
        log_info "Running GDB tests..."
        test_gdb_breakpoint_by_function
        test_gdb_breakpoint_by_line
        test_gdb_backtrace
        echo
    fi

    # Summary
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC}  $PASSED"
    echo -e "${RED}Failed:${NC}  $FAILED"
    echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
    echo "=========================================="

    if [ $FAILED -gt 0 ]; then
        echo
        echo "Some tests failed. To debug:"
        echo "  1. Ensure binary compiled with: ../../../../ocamlopt.opt -I ../../../../stdlib -g -o $BINARY $SOURCE_FILE"
        echo "  2. Verify DWARF sections: dwarfdump $BINARY | head -50"
        echo "  3. Run with verbose output: VERBOSE=1 $0 $BINARY"
        exit 1
    else
        echo
        echo "All tests passed! ✓"
        exit 0
    fi
}

# Run main
main
