#!/usr/bin/env bash
# Quiet macOS dsymutil warnings from the startup object by stripping its DWARF
# and syncing its timestamp to the main executable. Usage:
#   tools/fix_startup_dsym.sh /path/to/exe
# Expects a sibling <exe>.startup.o generated with -dstartup.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <executable>" >&2
  exit 64
fi

exe="$1"
startup="${exe}.startup.o"

if [ ! -f "$exe" ]; then
  echo "error: executable not found: $exe" >&2
  exit 66
fi
if [ ! -f "$startup" ]; then
  echo "error: startup object not found: $startup (build with -dstartup)" >&2
  exit 66
fi

# Strip debug from the startup object; dsymutil will then ignore it.
strip -S "$startup"

# Match the timestamp in the debug map to avoid dsymutil timestamp warnings.
touch -r "$exe" "$startup"

echo "Stripped DWARF from $startup and synced its timestamp to $exe"
