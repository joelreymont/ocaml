#!/bin/bash
echo "DWARF Test Suite Verification Report"
echo "===================================="
echo ""
for test in test_simple test_basic test_debug test_types; do
  echo "Test: $test"
  if [ -f $test ]; then
    echo "  ✓ Binary exists"
    sections=$(otool -l $test.o 2>/dev/null | grep -c "sectname __debug")
    echo "  ✓ DWARF sections in .o: $sections/4"
    funcs=$(dwarfdump $test.o 2>&1 | grep -c "DW_TAG_subprogram")
    echo "  ✓ Functions found: $funcs"
  else
    echo "  ✗ Binary not found"
  fi
  echo ""
done
