"""
LLDB Data Formatters for OCaml Native Code

This module provides data formatters (synthetic children and summaries) for common
OCaml data types when debugging native OCaml programs with LLDB. It helps display
OCaml values in a human-readable format instead of showing raw memory addresses
and tagged integers.

Usage:
    1. Load in LLDB:
       (lldb) command script import ocaml-lldb.py

    2. Or add to ~/.lldbinit:
       command script import /path/to/ocaml-lldb.py

    3. Debug your program:
       $ lldb myprogram
       (lldb) b camlMain__entry
       (lldb) run
       (lldb) frame variable my_list
       [1; 2; 3; 4; 5]
"""

import lldb

# OCaml value tagging constants
TAG_MASK = 1
TAG_INT = 1
TAG_POINTER = 0

# OCaml block tags
TAG_CLOSURE = 247
TAG_STRING = 252
TAG_DOUBLE = 253
TAG_DOUBLE_ARRAY = 254


class OcamlValueHelper:
    """Helper methods for OCaml value inspection"""

    @staticmethod
    def is_int(value):
        """Check if value is a tagged integer"""
        try:
            int_val = value.GetValueAsUnsigned()
            return (int_val & TAG_MASK) == TAG_INT
        except:
            return False

    @staticmethod
    def get_int(value):
        """Extract integer from tagged value"""
        try:
            int_val = value.GetValueAsUnsigned()
            return int_val >> 1
        except:
            return None

    @staticmethod
    def is_block(value):
        """Check if value is a heap-allocated block"""
        try:
            int_val = value.GetValueAsUnsigned()
            return (int_val & TAG_MASK) == TAG_POINTER and int_val != 0
        except:
            return False

    @staticmethod
    def get_tag(value, process):
        """Get block tag"""
        if not OcamlValueHelper.is_block(value):
            return None
        try:
            ptr = value.GetValueAsUnsigned()
            error = lldb.SBError()
            # Read tag from block header (word before the pointer)
            header = process.ReadUnsignedFromMemory(ptr - 8, 8, error)
            if error.Success():
                return header & 0xFF
            return None
        except:
            return None

    @staticmethod
    def get_size(value, process):
        """Get block size in words"""
        if not OcamlValueHelper.is_block(value):
            return None
        try:
            ptr = value.GetValueAsUnsigned()
            error = lldb.SBError()
            header = process.ReadUnsignedFromMemory(ptr - 8, 8, error)
            if error.Success():
                return (header >> 10) & 0x3FFFFF
            return None
        except:
            return None


class OcamlIntFormatter:
    """Summary provider for OCaml integers"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        pass

    def has_children(self):
        return False

    def get_value(self):
        if OcamlValueHelper.is_int(self.valobj):
            int_val = OcamlValueHelper.get_int(self.valobj)
            return str(int_val)
        return None


class OcamlBoolFormatter:
    """Summary provider for OCaml booleans"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        pass

    def has_children(self):
        return False

    def get_value(self):
        if OcamlValueHelper.is_int(self.valobj):
            int_val = OcamlValueHelper.get_int(self.valobj)
            if int_val == 0:
                return "false"
            elif int_val == 1:
                return "true"
        return None


class OcamlListFormatter:
    """Synthetic children provider for OCaml lists"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def num_children(self):
        return len(self.elements)

    def has_children(self):
        return len(self.elements) > 0

    def get_child_index(self, name):
        try:
            return int(name.lstrip('[').rstrip(']'))
        except:
            return -1

    def get_child_at_index(self, index):
        if index < 0 or index >= len(self.elements):
            return None
        return self.elements[index]

    def update(self):
        self.elements = []
        try:
            process = self.valobj.GetProcess()
            int_val = self.valobj.GetValueAsUnsigned()

            # Empty list is Val_int(0) = 1
            if int_val == 1:
                return

            if not OcamlValueHelper.is_block(self.valobj):
                return

            tag = OcamlValueHelper.get_tag(self.valobj, process)
            if tag != 0:  # List blocks have tag 0
                return

            # Traverse list
            current = int_val
            max_elements = 100
            index = 0

            while current != 1 and index < max_elements:
                error = lldb.SBError()

                # Read head and tail
                head_val = process.ReadUnsignedFromMemory(current, 8, error)
                if not error.Success():
                    break

                tail_val = process.ReadUnsignedFromMemory(current + 8, 8, error)
                if not error.Success():
                    break

                # Create synthetic value for head
                head = self.valobj.CreateValueFromData(
                    f"[{index}]",
                    lldb.SBData.CreateDataFromUInt64Array(
                        self.valobj.GetTarget().GetByteOrder(),
                        self.valobj.GetTarget().GetAddressByteSize(),
                        [head_val]
                    ),
                    self.valobj.GetType()
                )
                self.elements.append(head)

                current = tail_val
                index += 1

        except:
            pass

    def get_summary(self):
        """Provide a summary string for the list"""
        if len(self.elements) == 0:
            return "[]"

        try:
            process = self.valobj.GetProcess()
            items = []
            for elem in self.elements[:10]:  # Limit to first 10 elements
                if OcamlValueHelper.is_int(elem):
                    int_val = OcamlValueHelper.get_int(elem)
                    items.append(str(int_val))
                else:
                    items.append(f"0x{elem.GetValueAsUnsigned():x}")

            result = "[" + "; ".join(items)
            if len(self.elements) > 10:
                result += "; ..."
            result += "]"
            return result
        except:
            return f"[{len(self.elements)} elements]"


class OcamlStringFormatter:
    """Summary provider for OCaml strings"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        pass

    def has_children(self):
        return False

    def get_value(self):
        if not OcamlValueHelper.is_block(self.valobj):
            return None

        process = self.valobj.GetProcess()
        tag = OcamlValueHelper.get_tag(self.valobj, process)
        if tag != TAG_STRING:
            return None

        try:
            ptr = self.valobj.GetValueAsUnsigned()
            size = OcamlValueHelper.get_size(self.valobj, process)
            if size is None:
                return None

            error = lldb.SBError()
            # Last byte contains length of padding
            last_byte = process.ReadUnsignedFromMemory(ptr + size * 8 - 1, 1, error)
            if not error.Success():
                return None

            actual_len = size * 8 - last_byte - 1

            # Read string bytes
            string_data = process.ReadMemory(ptr, min(actual_len, 100), error)
            if not error.Success():
                return None

            result = string_data.decode('utf-8', errors='replace')
            if actual_len > 100:
                result += "..."

            return f'"{result}"'
        except:
            return None


class OcamlFloatFormatter:
    """Summary provider for OCaml floats"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        pass

    def has_children(self):
        return False

    def get_value(self):
        if not OcamlValueHelper.is_block(self.valobj):
            return None

        process = self.valobj.GetProcess()
        tag = OcamlValueHelper.get_tag(self.valobj, process)
        if tag != TAG_DOUBLE:
            return None

        try:
            ptr = self.valobj.GetValueAsUnsigned()
            error = lldb.SBError()

            # Read double value (8 bytes)
            double_bytes = process.ReadMemory(ptr, 8, error)
            if not error.Success():
                return None

            # Create SBData and extract as double
            data = lldb.SBData.CreateDataFromCString(
                self.valobj.GetTarget().GetByteOrder(),
                self.valobj.GetTarget().GetAddressByteSize(),
                double_bytes
            )
            error_read = lldb.SBError()
            double_val = data.GetDouble(error_read, 0)
            if error_read.Success():
                return str(double_val)

            return None
        except:
            return None


class OcamlOptionFormatter:
    """Summary provider for OCaml option types"""

    def __init__(self, valobj, internal_dict):
        self.valobj = valobj
        self.update()

    def update(self):
        pass

    def has_children(self):
        # Some has one child
        int_val = self.valobj.GetValueAsUnsigned()
        return int_val != 1 and OcamlValueHelper.is_block(self.valobj)

    def get_value(self):
        int_val = self.valobj.GetValueAsUnsigned()

        # None is Val_int(0) = 1
        if int_val == 1:
            return "None"

        # Some is a block with tag 0
        if OcamlValueHelper.is_block(self.valobj):
            process = self.valobj.GetProcess()
            tag = OcamlValueHelper.get_tag(self.valobj, process)
            if tag == 0:
                try:
                    ptr = int_val
                    error = lldb.SBError()
                    inner_val = process.ReadUnsignedFromMemory(ptr, 8, error)
                    if not error.Success():
                        return None

                    # Create value for inner
                    inner = self.valobj.CreateValueFromData(
                        "value",
                        lldb.SBData.CreateDataFromUInt64Array(
                            self.valobj.GetTarget().GetByteOrder(),
                            self.valobj.GetTarget().GetAddressByteSize(),
                            [inner_val]
                        ),
                        self.valobj.GetType()
                    )

                    if OcamlValueHelper.is_int(inner):
                        return f"Some {OcamlValueHelper.get_int(inner)}"
                    else:
                        return f"Some 0x{inner_val:x}"
                except:
                    pass

        return None


def ocaml_int_summary(valobj, internal_dict):
    formatter = OcamlIntFormatter(valobj, internal_dict)
    return formatter.get_value()


def ocaml_bool_summary(valobj, internal_dict):
    formatter = OcamlBoolFormatter(valobj, internal_dict)
    return formatter.get_value()


def ocaml_list_summary(valobj, internal_dict):
    formatter = OcamlListFormatter(valobj, internal_dict)
    return formatter.get_summary()


def ocaml_string_summary(valobj, internal_dict):
    formatter = OcamlStringFormatter(valobj, internal_dict)
    return formatter.get_value()


def ocaml_float_summary(valobj, internal_dict):
    formatter = OcamlFloatFormatter(valobj, internal_dict)
    return formatter.get_value()


def ocaml_option_summary(valobj, internal_dict):
    formatter = OcamlOptionFormatter(valobj, internal_dict)
    return formatter.get_value()


def __lldb_init_module(debugger, internal_dict):
    """Register OCaml formatters with LLDB"""

    # Register summary providers for types containing "value" or "long"
    # These heuristics help LLDB identify OCaml values

    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_int_summary -x ".*value.*" -w ocaml'
    )
    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_bool_summary -x ".*value.*" -w ocaml'
    )
    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_list_summary -x ".*value.*" -w ocaml'
    )
    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_string_summary -x ".*value.*" -w ocaml'
    )
    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_float_summary -x ".*value.*" -w ocaml'
    )
    debugger.HandleCommand(
        'type summary add -F ocaml-lldb.ocaml_option_summary -x ".*value.*" -w ocaml'
    )

    # Register synthetic children for lists
    debugger.HandleCommand(
        'type synthetic add -x ".*value.*" -l ocaml-lldb.OcamlListFormatter -w ocaml'
    )

    # Enable the category
    debugger.HandleCommand('type category enable ocaml')

    print("OCaml LLDB formatters loaded")
