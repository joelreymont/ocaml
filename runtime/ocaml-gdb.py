"""
GDB Pretty-Printers for OCaml Native Code

This module provides pretty-printers for common OCaml data types when debugging
native OCaml programs with GDB. It helps display OCaml values in a human-readable
format instead of showing raw memory addresses and tagged integers.

Usage:
    1. Source this file in GDB:
       (gdb) source ocaml-gdb.py

    2. Or add to ~/.gdbinit:
       source /path/to/ocaml-gdb.py

    3. Debug your program:
       $ gdb myprogram
       (gdb) break camlMain__entry
       (gdb) run
       (gdb) print my_list
       [1; 2; 3; 4; 5]
"""

import gdb
import re

# OCaml value tagging constants
TAG_MASK = 1
TAG_INT = 1
TAG_POINTER = 0

# OCaml block tags
TAG_CLOSURE = 247
TAG_STRING = 252
TAG_DOUBLE = 253
TAG_DOUBLE_ARRAY = 254

class OcamlValuePrinter:
    """Base printer for OCaml values"""

    def __init__(self, val):
        self.val = val

    @staticmethod
    def is_int(value):
        """Check if value is a tagged integer"""
        return (int(value) & TAG_MASK) == TAG_INT

    @staticmethod
    def get_int(value):
        """Extract integer from tagged value"""
        return int(value) >> 1

    @staticmethod
    def is_block(value):
        """Check if value is a heap-allocated block"""
        return (int(value) & TAG_MASK) == TAG_POINTER and int(value) != 0

    @staticmethod
    def get_tag(value):
        """Get block tag"""
        if not OcamlValuePrinter.is_block(value):
            return None
        try:
            # Read tag from block header (word before the pointer)
            ptr = int(value)
            header = gdb.parse_and_eval(f"*(long*)({ptr} - 8)")
            return int(header) & 0xFF
        except:
            return None

    @staticmethod
    def get_size(value):
        """Get block size in words"""
        if not OcamlValuePrinter.is_block(value):
            return None
        try:
            ptr = int(value)
            header = gdb.parse_and_eval(f"*(long*)({ptr} - 8)")
            return (int(header) >> 10) & 0x3FFFFF
        except:
            return None

class OcamlIntPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml integers"""

    def to_string(self):
        if self.is_int(self.val):
            return str(self.get_int(self.val))
        return None

class OcamlListPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml lists"""

    def to_string(self):
        if int(self.val) == 1:  # Empty list (Val_int(0))
            return "[]"

        if not self.is_block(self.val):
            return None

        tag = self.get_tag(self.val)
        if tag != 0:  # List blocks have tag 0
            return None

        # Build list elements
        elements = []
        current = self.val
        max_elements = 100  # Prevent infinite loops

        try:
            while int(current) != 1 and len(elements) < max_elements:
                if not self.is_block(current):
                    break

                ptr = int(current)
                # List is [head | tail]
                head = gdb.parse_and_eval(f"*(long*){ptr}")
                tail = gdb.parse_and_eval(f"*(long*)({ptr} + 8)")

                # Try to pretty-print head
                if self.is_int(head):
                    elements.append(str(self.get_int(head)))
                else:
                    elements.append(f"0x{int(head):x}")

                current = tail

            if len(elements) >= max_elements:
                elements.append("...")

            return "[" + "; ".join(elements) + "]"
        except:
            return None

class OcamlStringPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml strings"""

    def to_string(self):
        if not self.is_block(self.val):
            return None

        tag = self.get_tag(self.val)
        if tag != TAG_STRING:
            return None

        try:
            ptr = int(self.val)
            size = self.get_size(self.val)
            if size is None:
                return None

            # Read string bytes
            # Last byte contains length of padding
            last_byte = gdb.parse_and_eval(f"*(unsigned char*)({ptr} + {size * 8 - 1})")
            actual_len = size * 8 - int(last_byte) - 1

            chars = []
            for i in range(min(actual_len, 100)):  # Limit to 100 chars
                c = gdb.parse_and_eval(f"*(unsigned char*)({ptr} + {i})")
                chars.append(chr(int(c)))

            result = ''.join(chars)
            if actual_len > 100:
                result += "..."

            return f'"{result}"'
        except:
            return None

class OcamlFloatPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml floats"""

    def to_string(self):
        if not self.is_block(self.val):
            return None

        tag = self.get_tag(self.val)
        if tag != TAG_DOUBLE:
            return None

        try:
            ptr = int(self.val)
            # Read double value
            double_val = gdb.parse_and_eval(f"*(double*){ptr}")
            return f"{float(double_val)}"
        except:
            return None

class OcamlBoolPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml booleans"""

    def to_string(self):
        if self.is_int(self.val):
            int_val = self.get_int(self.val)
            if int_val == 0:
                return "false"
            elif int_val == 1:
                return "true"
        return None

class OcamlOptionPrinter(OcamlValuePrinter):
    """Pretty-printer for OCaml option types"""

    def to_string(self):
        # None is Val_int(0) = 1
        if int(self.val) == 1:
            return "None"

        # Some is a block with tag 0 containing the value
        if self.is_block(self.val):
            tag = self.get_tag(self.val)
            if tag == 0:
                try:
                    ptr = int(self.val)
                    inner = gdb.parse_and_eval(f"*(long*){ptr}")

                    if self.is_int(inner):
                        return f"Some {self.get_int(inner)}"
                    else:
                        return f"Some 0x{int(inner):x}"
                except:
                    pass

        return None

def ocaml_value_lookup(val):
    """Main lookup function for OCaml values"""

    # Only handle types that look like OCaml values
    type_str = str(val.type)
    if 'value' not in type_str.lower() and 'long' not in type_str.lower():
        return None

    # Try each printer in order
    printers = [
        OcamlBoolPrinter,
        OcamlIntPrinter,
        OcamlOptionPrinter,
        OcamlFloatPrinter,
        OcamlStringPrinter,
        OcamlListPrinter,
    ]

    for printer_class in printers:
        try:
            printer = printer_class(val)
            result = printer.to_string()
            if result is not None:
                return printer
        except:
            continue

    return None

def register_ocaml_printers():
    """Register OCaml pretty-printers with GDB"""
    gdb.pretty_printers.append(ocaml_value_lookup)
    print("OCaml GDB pretty-printers loaded")

# Auto-register when sourced
register_ocaml_printers()
