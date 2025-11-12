#!/bin/bash
#**************************************************************************
#*                                                                        *
#*                                 OCaml                                  *
#*                                                                        *
#*                  Verify DWARF debugging information                    *
#*                                                                        *
#**************************************************************************

# Script to verify DWARF sections in compiled OCaml binaries
# Works on both macOS (using dwarfdump/llvm-dwarfdump) and Linux (using readelf)

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

echo "=== Verifying DWARF sections in $BINARY ==="

# Detect platform
PLATFORM=$(uname -s)
ARCH=$(uname -m)

echo "Platform: $PLATFORM $ARCH"

# Check for DWARF tools
if command -v llvm-dwarfdump >/dev/null 2>&1; then
    DWARFDUMP="llvm-dwarfdump"
elif command -v dwarfdump >/dev/null 2>&1; then
    DWARFDUMP="dwarfdump"
elif command -v readelf >/dev/null 2>&1; then
    DWARFDUMP="readelf -w"
else
    echo "Error: No DWARF dump tool found (llvm-dwarfdump, dwarfdump, or readelf)"
    exit 1
fi

echo "Using: $DWARFDUMP"
echo

# Function to check section existence
check_section() {
    local section="$1"
    local description="$2"

    echo -n "Checking $description ($section)... "

    if [ "$PLATFORM" = "Darwin" ]; then
        # macOS: Check Mach-O format
        if otool -l "$BINARY" | grep -q "__debug_$section"; then
            echo "✓ Found"
            return 0
        elif otool -l "$BINARY" | grep -q "\.debug_$section"; then
            echo "✓ Found (dwarf)"
            return 0
        else
            echo "✗ Missing"
            return 1
        fi
    else
        # Linux: Check ELF format
        if readelf -S "$BINARY" | grep -q "\.debug_$section"; then
            echo "✓ Found"
            return 0
        else
            echo "✗ Missing"
            return 1
        fi
    fi
}

# Check required DWARF sections
ERRORS=0

check_section "info" "Debug information entries" || ((ERRORS++))
check_section "abbrev" "Abbreviations table" || ((ERRORS++))
check_section "line" "Line number information" || ((ERRORS++))
check_section "str" "String table" || ((ERRORS++))

# Check optional but recommended sections
echo
echo "Optional sections:"
check_section "loc" "Location lists (variable tracking)" || echo "  (Will be added in Phase 4)"
check_section "ranges" "Address ranges (non-contiguous code)" || echo "  (Will be added in Phase 4)"
check_section "frame" "Call frame information" || echo "  (Optional)"
check_section "aranges" "Address range to CU mapping" || echo "  (Optional)"

echo
echo "=== Detailed DWARF Information ==="

# Dump DWARF version and compilation unit info
if [ "$PLATFORM" = "Darwin" ]; then
    echo
    echo "Compilation Units:"
    $DWARFDUMP --debug-info "$BINARY" 2>/dev/null | head -30 || echo "Could not extract debug info"

    if [ "$ARCH" = "arm64" ]; then
        echo
        echo "ARM64-specific checks:"
        echo -n "  Checking ARM64 register names... "
        if $DWARFDUMP "$BINARY" 2>/dev/null | grep -q "DW_OP_breg"; then
            echo "✓ Found register operations"
        else
            echo "⚠ No register operations found (expected in Phase 4)"
        fi
    fi
else
    echo
    echo "Compilation Units:"
    readelf --debug-dump=info "$BINARY" 2>/dev/null | head -30 || echo "Could not extract debug info"
fi

# Check for OCaml language tag
echo
echo -n "Checking for OCaml language tag (DW_LANG_OCaml)... "
if $DWARFDUMP "$BINARY" 2>/dev/null | grep -q "DW_LANG_OCaml\|DW_LANG.*0x0023"; then
    echo "✓ Found"
elif $DWARFDUMP "$BINARY" 2>/dev/null | grep -q "DW_LANG"; then
    echo "⚠ Found other language (expected after Phase 4)"
    $DWARFDUMP "$BINARY" 2>/dev/null | grep "DW_LANG" | head -1
else
    echo "✗ No language tag found"
    ((ERRORS++))
fi

# Summary
echo
echo "=== Summary ==="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All required DWARF sections present"
    echo "Binary appears to have valid DWARF debugging information"
    exit 0
else
    echo "✗ $ERRORS required sections missing"
    echo "Note: This is expected if DWARF emission is not yet implemented (Phase 1)"
    echo "      Full DWARF generation requires completion of Phases 2-5"
    exit 1
fi
