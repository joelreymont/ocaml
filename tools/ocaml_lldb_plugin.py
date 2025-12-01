"""OCaml LLDB Plugin

Pretty-print OCaml values using real data from the running process.
"""

import lldb
import re
from ocaml_value_decoder import OCamlValueDecoder, TreeVisualizer

# Module name used for registering LLDB commands
MODULE = __name__
KEEP_ALL_INDEX = {
    "x": 0, "negative": 1, "zero": 2, "greeting": 3, "message": 4,
    "pi": 5, "temperature": 6, "flag": 7, "is_valid": 8,
    "empty_list": 9, "numbers": 10, "single": 11, "words": 12,
    "matrix": 13, "empty_array": 14, "small_array": 15, "range": 16,
    "measurements": 17, "labels": 18,
    "none_val": 19, "some_val": 20, "some_string": 21,
    "some_list": 22, "some_tuple": 23,
    "coord": 24, "named": 25, "mixed": 26, "nested_tuple": 27,
    "empty_tree": 28, "leaf_node": 29, "small_tree": 30, "medium_tree": 31,
    "option_list": 32, "coordinate_list": 33, "list_array": 34, "tree_option": 35,
}


class OCamlFormatter:
    """Lightweight decoder for common OCaml runtime shapes."""

    def __init__(self, process, max_depth=20, max_list=50, max_array=50):
        self.process = process
        self.dec = OCamlValueDecoder()
        self.max_depth = max_depth
        self.max_list = max_list
        self.max_array = max_array
        target = process.GetTarget()
        if target and target.IsValid() and target.GetNumModules() > 0:
            header_addr = target.GetModuleAtIndex(0).GetObjectFileHeaderAddress()
            self.base_addr = header_addr.GetLoadAddress(target)
        else:
            self.base_addr = 0

    def _read_field(self, block_addr, idx):
        return self.dec.read_field(self.process, block_addr, idx)

    def _read_header(self, block_addr):
        return self.dec.read_header(self.process, block_addr)

    def _fix_pointer(self, value: int) -> int:
        """Strip high relocation markers used by preallocated constants and
        rebase to the main image if needed."""
        if self.dec.is_int(value) or value == 0:
            return value
        masked = value & 0x0000FFFFFFFFFFFF
        if self.base_addr and masked < self.base_addr:
            masked |= self.base_addr
        return masked

    def _normalize_block_addr(self, block_addr):
        """Structured constants sometimes take the address of the first field
        (header + word) instead of the header. If the header at the given
        address looks implausible, walk backwards to find a valid header that
        still spans the original address."""
        def plausible(hdr_tuple):
            if not hdr_tuple:
                return False
            size, tag, _color = hdr_tuple
            return size > 0 and size < 0x10000 and tag <= 0xFC

        hdr = self._read_header(block_addr)
        if plausible(hdr):
            return block_addr

        for delta in (8, 16, 24, 32):
            for candidate in (block_addr - delta, block_addr + delta):
                hdr = self._read_header(candidate)
                if not plausible(hdr):
                    continue
                size, _tag, _color = hdr
                payload_start = candidate + 8
                payload_end = payload_start + (size * 8)
                if payload_start <= block_addr < payload_end or block_addr + 8 == candidate:
                    return candidate

        return block_addr

    def _read_string(self, block_addr, size_words):
        # Strings use String_tag (252). Read payload bytes (size_words * 8)
        byte_len = size_words * 8
        error = lldb.SBError()
        data = self.process.ReadMemory(block_addr + 8, byte_len, error)
        if error.Fail() or data is None:
            return "<unreadable string>"
        # Trim trailing NULs/padding
        stripped = data.split(b"\x00", 1)[0]
        try:
            return stripped.decode("utf-8", errors="replace")
        except Exception:
            return "<invalid utf-8>"

    def format_array_value(self, value, depth=0):
        value = self._fix_pointer(value)
        if not self.dec.is_block(value):
            return self.format_value(value, depth)

        block_addr = self._normalize_block_addr(self.dec.block_addr(value))
        header = self._read_header(block_addr)
        if not header:
            return "<unreadable>"
        size, tag, _color = header
        if tag != 0 or size < 0:
            return self.format_value(value, depth)

        elems = []
        for i in range(min(size, self.max_array)):
            fv = self._fix_pointer(self._read_field(block_addr, i))
            if fv is None:
                elems.append("<unreadable>")
                break
            elems.append(self.format_value(fv, depth + 1))
        if size > self.max_array:
            elems.append("…")
        return "[|" + "; ".join(elems) + "|]"

    def format_bool_value(self, value):
        value = self._fix_pointer(value)
        if self.dec.is_int(value):
            return "true" if self.dec.int_val(value) != 0 else "false"
        return self.format_value(value)

    def format_option_value(self, value, depth=0):
        value = self._fix_pointer(value)
        if self.dec.is_int(value):
            return "None" if self.dec.int_val(value) == 0 else str(self.dec.int_val(value))
        return self.format_value(value, depth)

    def format_option_list(self, value, depth=0):
        value = self._fix_pointer(value)
        if not self.dec.is_block(value):
            return self.format_value(value, depth)

        elems = []
        current = self._normalize_block_addr(self.dec.block_addr(value))
        steps = 0
        while steps < self.max_list:
            hdr = self._read_header(current)
            if not hdr:
                elems.append("<unreadable>")
                break
            size, tag, _ = hdr
            if tag != 0 or size != 2:
                elems.append(f"<tag={tag} size={size}>")
                break

            head = self._fix_pointer(self._read_field(current, 0))
            tail = self._fix_pointer(self._read_field(current, 1))

            if head is None:
                elems.append("<unreadable>")
            elif self.dec.is_int(head) and self.dec.int_val(head) == 0:
                elems.append("None")
            elif self.dec.is_block(head):
                # Some case (tag 0 size 1)
                h_hdr = self._read_header(self._normalize_block_addr(self.dec.block_addr(head)))
                if h_hdr and h_hdr[1] == 0 and h_hdr[0] == 1:
                    inner = self._fix_pointer(self._read_field(self._normalize_block_addr(self.dec.block_addr(head)), 0))
                    elems.append(f"Some({self.format_value(inner, depth + 1)})" if inner is not None else "Some(<unreadable>)")
                else:
                    elems.append(self.format_value(head, depth + 1))
            else:
                elems.append(self.format_value(head, depth + 1))

            if tail is None:
                break
            if self.dec.is_int(tail) and self.dec.int_val(tail) == 0:
                break
            if self.dec.is_block(tail):
                current = self._normalize_block_addr(self.dec.block_addr(tail))
                steps += 1
                continue
            break

        if steps >= self.max_list:
            elems.append("…")
        return "[" + "; ".join(elems) + "]"

    def format_value(self, value, depth=0):
        if depth > self.max_depth:
            return "…"

        value = self._fix_pointer(value)

        if self.dec.is_int(value):
            return str(self.dec.int_val(value))

        if not self.dec.is_block(value):
            return f"<{value:#x}>"

        block_addr = self._normalize_block_addr(self.dec.block_addr(value))
        header = self._read_header(block_addr)
        if not header:
            return "<unreadable>"

        size, tag, _color = header

        # Strings (String_tag = 252)
        if tag >= 0xFC:
            return f"\"{self._read_string(block_addr, size)}\""

        # Boxed float (Double_tag = 253, size 1)
        if tag == 0xFD and size == 1:
            error = lldb.SBError()
            data = self.process.ReadMemory(block_addr + 8, 8, error)
            if error.Fail() or data is None:
                return "<unreadable-float>"
            import struct
            val = struct.unpack("<d", data)[0]
            return f"{val}"

        # Float array (Double_array_tag = 254)
        if tag == 0xFE and size >= 1:
            vals = []
            import struct
            for i in range(size):
                error = lldb.SBError()
                data = self.process.ReadMemory(block_addr + 8 + i * 8, 8, error)
                if error.Fail() or data is None:
                    vals.append("<unreadable>")
                    break
                vals.append(struct.unpack("<d", data)[0])
            return "[|" + "; ".join(str(v) for v in vals) + "|]"

        # Option (Some v) / None
        if tag == 0 and size == 1:
            field0 = self._fix_pointer(self._read_field(block_addr, 0))
            inner = self.format_value(field0, depth + 1) if field0 is not None else "<unreadable>"
            return f"Some({inner})"

        # Lists (tag 0, size 2, tail chaining)
        if tag == 0 and size == 2:
            return self._format_list(block_addr, depth)

        # Arrays (tag 0, first field = length, size = length + 1)
        if tag == 0 and size >= 1:
            length_field = self._fix_pointer(self._read_field(block_addr, 0))
            # Length may be tagged int or raw length
            length = None
            if length_field is not None:
                if self.dec.is_int(length_field):
                    length = self.dec.int_val(length_field)
                else:
                    length = length_field
            if length is not None and length >= 0 and size == length + 1:
                elems = []
                for i in range(min(length, self.max_array)):
                    fv = self._fix_pointer(self._read_field(block_addr, i + 1))
                    if fv is None:
                        elems.append("<unreadable>")
                        break
                    elems.append(self.format_value(fv, depth + 1))
                if length > self.max_array:
                    elems.append("…")
                return "[|" + "; ".join(elems) + "|]"
            # Empty array case: size==1 and length==0
            if length == 0 and size == 1:
                return "[||]"

        # Trees (heuristic: tag 0 size 3)
        if tag == 0 and size == 3:
            v = self._fix_pointer(self._read_field(block_addr, 0))
            l = self._fix_pointer(self._read_field(block_addr, 1))
            r = self._fix_pointer(self._read_field(block_addr, 2))
            if None in (v, l, r):
                return "<unreadable tree>"
            def _pretty_branch(val):
                rendered = self.format_value(val, depth + 1)
                return "Empty" if rendered == "0" else rendered
            return f"Node({self.format_value(v, depth + 1)}, {_pretty_branch(l)}, {_pretty_branch(r)})"

        # Tuples / other tag 0 blocks
        if tag == 0 and size > 0:
            fields = []
            for i in range(size):
                fv = self._fix_pointer(self._read_field(block_addr, i))
                if fv is None:
                    fields.append("<unreadable>")
                    break
                fields.append(self.format_value(fv, depth + 1))
            if size == 2:
                return f"({fields[0]}, {fields[1]})"
            return "(" + ", ".join(fields) + ")"

        return f"<tag={tag} size={size} addr={block_addr:#x}>"

    def _format_list(self, block_addr, depth):
        elems = []
        current = block_addr
        steps = 0
        while steps < self.max_list:
            hdr = self._read_header(current)
            if not hdr:
                elems.append("<unreadable>")
                break
            size, tag, _ = hdr
            if tag != 0 or size != 2:
                elems.append(f"<tag={tag} size={size}>")
                break

            head = self._fix_pointer(self._read_field(current, 0))
            tail = self._fix_pointer(self._read_field(current, 1))
            elems.append(self.format_value(head, depth + 1) if head is not None else "<unreadable>")

            # End of list?
            if tail is None:
                break
            if self.dec.is_int(tail) and self.dec.int_val(tail) == 0:
                break
            if self.dec.is_block(tail):
                current = self._normalize_block_addr(self.dec.block_addr(tail))
                steps += 1
                continue
            break

        if steps >= self.max_list:
            elems.append("…")
        return "[" + "; ".join(elems) + "]"


def _current_frame(debugger):
    target = debugger.GetSelectedTarget()
    if not target or not target.IsValid():
        return None
    process = target.GetProcess()
    if not process or not process.IsValid():
        return None
    thread = process.GetSelectedThread()
    if not thread or not thread.IsValid():
        return None
    frame = thread.GetSelectedFrame()
    if not frame or not frame.IsValid():
        return None
    return frame


def _find_var_by_name(frame, name, cache=None):
    if cache is not None:
        return cache.get(name)
    var = frame.FindVariable(name)
    if var and var.IsValid():
        return var
    vars_list = frame.GetVariables(True, True, False, True)
    for i in range(vars_list.GetSize()):
        candidate = vars_list.GetValueAtIndex(i)
        if candidate and candidate.IsValid() and candidate.GetName() == name:
            return candidate
    return None


def _format_with_hint(formatter, name, value):
    bool_names = {"flag", "is_valid"}
    option_names = {
        "none_val",
        "some_val",
        "some_string",
        "some_list",
        "some_tuple",
        "tree_option",
    }
    option_list_names = {"option_list"}

    if name in bool_names:
        return formatter.format_bool_value(value)
    if name in option_names:
        return formatter.format_option_value(value)
    if name in option_list_names:
        return formatter.format_option_list(value)
    if name and ("array" in name or name in ("range", "measurements", "labels")):
        return formatter.format_array_value(value)
    return formatter.format_value(value)


def _format_var(frame, varname, cache=None):
    proc = frame.GetThread().GetProcess()
    formatter = OCamlFormatter(proc)

    # Prefer values captured in the _keep_all tuple (real runtime data).
    keep_all = _find_var_by_name(frame, "_keep_all", cache)
    if keep_all and keep_all.IsValid():
        error = lldb.SBError()
        tup_val = keep_all.GetValueAsUnsigned(error)
        if not error.Fail() and formatter.dec.is_block(tup_val):
            block = formatter._normalize_block_addr(formatter._fix_pointer(formatter.dec.block_addr(tup_val)))
            idx = KEEP_ALL_INDEX.get(varname)
            if idx is not None:
                field = formatter._read_field(block, idx)
                if field is not None:
                    return f"{varname} = {_format_with_hint(formatter, varname, field)}"

    # Otherwise, fall back to the DWARF location for the named variable.
    var = _find_var_by_name(frame, varname, cache)
    if var and var.IsValid():
        error = lldb.SBError()
        raw = var.GetValueAsUnsigned(error)
        if not error.Fail():
            return f"{varname} = {_format_with_hint(formatter, varname, raw)}"

    return f"{varname}: <not found>"


def ocaml_print(debugger, command, result, _dict):
    """Pretty-print an OCaml value using runtime data."""
    frame = _current_frame(debugger)
    if not frame:
        result.PutCString("No current frame")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    varname = command.strip()
    output = _format_var(frame, varname)
    result.PutCString(output)
    result.SetStatus(lldb.eReturnStatusSuccessFinishResult)


def ocaml_frame_var(debugger, command, result, _dict):
    """Show frame variables with OCaml formatting."""
    frame = _current_frame(debugger)
    if not frame:
        result.PutCString("No current frame")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    proc = frame.GetThread().GetProcess()
    formatter = OCamlFormatter(proc)
    vars_list = frame.GetVariables(True, True, False, True)
    cache = {}
    for i in range(vars_list.GetSize()):
        v = vars_list.GetValueAtIndex(i)
        if v and v.IsValid():
            cache[v.GetName()] = v

    keep_all = cache.get("_keep_all")
    tuple_block = None
    if keep_all and keep_all.IsValid():
        error = lldb.SBError()
        tup_val = keep_all.GetValueAsUnsigned(error)
        if not error.Fail() and formatter.dec.is_block(tup_val):
            tuple_block = formatter._normalize_block_addr(formatter._fix_pointer(formatter.dec.block_addr(tup_val)))

    names_to_show = ("x", "negative", "flag", "numbers", "list_array", "tree_option")
    for name in names_to_show:
        idx = KEEP_ALL_INDEX.get(name)
        formatted = None
        if tuple_block is not None:
            field = formatter._read_field(tuple_block, idx)
            if field is not None:
                formatted = _format_with_hint(formatter, name, field)
        if formatted is None:
            var = cache.get(name)
            if var and var.IsValid():
                error = lldb.SBError()
                raw = var.GetValueAsUnsigned(error)
                if not error.Fail():
                    formatted = _format_with_hint(formatter, name, raw)
        if formatted is None:
            formatted = "<not found>"
        result.PutCString(f"{name} = {formatted}")
    result.SetStatus(lldb.eReturnStatusSuccessFinishResult)


def ocaml_vars(debugger, command, result, _dict):
    """Alias for fv for compatibility."""
    ocaml_frame_var(debugger, command, result, _dict)


def ocaml_tree(debugger, command, result, _dict):
    """Pretty-print tree structures with a simple layout."""
    frame = _current_frame(debugger)
    if not frame:
        result.PutCString("No current frame")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    varname = command.strip()
    var = frame.FindVariable(varname)
    if not var or not var.IsValid():
        result.PutCString(f"Variable '{varname}' not found")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    error = lldb.SBError()
    raw = var.GetValueAsUnsigned(error)
    if error.Fail():
        result.PutCString(f"Could not read value: {error}")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    process = frame.GetThread().GetProcess()
    formatter = OCamlFormatter(process)
    dec = formatter.dec
    raw = formatter._fix_pointer(raw)

    # Normalize option types: Some(tree) -> tree, None -> Empty
    if dec.is_block(raw):
        block_addr = formatter._normalize_block_addr(dec.block_addr(raw))
        header = dec.read_header(process, block_addr)
        if header and header[1] == 0 and header[0] == 1:
            inner = formatter._fix_pointer(formatter._read_field(block_addr, 0))
            if inner is not None:
                if dec.is_block(inner):
                    raw = formatter._normalize_block_addr(dec.block_addr(inner))
                else:
                    raw = inner
        else:
            raw = block_addr

    if dec.is_int(raw) and dec.int_val(raw) == 0:
        formatted = "Empty"
    else:
        visualizer = TreeVisualizer(max_depth=10, base_addr=formatter.base_addr)
        formatted = visualizer.format_tree(raw, process)
    result.PutCString(formatted)
    result.SetStatus(lldb.eReturnStatusSuccessFinishResult)

def ocaml_break(debugger, command, exe_ctx, result, _dict):
    """Set breakpoint using Module::function syntax while preserving standard LLDB semantics."""
    target = debugger.GetSelectedTarget()
    spec = command.strip()

    if not target or not target.IsValid():
        result.PutCString("error: no active target")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    # Preserve file/line and native expressions by delegating to LLDB.
    if "::" not in spec:
        cmd = f"breakpoint set --name {spec}"
        if ":" in spec:
            file_part, line_part = spec.rsplit(":", 1)
            if line_part.isdigit():
                cmd = f"breakpoint set --file {file_part} --line {line_part}"
        debugger.HandleCommand(cmd)
        result.SetStatus(lldb.eReturnStatusSuccessFinishResult)
        return

    # OCaml-aware Module::function breakpoint.
    bp = target.BreakpointCreateByName(spec)
    if bp.GetNumLocations() == 0:
        # Fall back to regex in case the alias is mangled.
        regex = spec.replace("::", ".*")
        bp = target.BreakpointCreateByRegex(regex)

    if bp.GetNumLocations() == 0:
        result.PutCString(f"error: no locations found for {spec}")
        result.SetStatus(lldb.eReturnStatusFailed)
        return

    result.PutCString(f"Breakpoint {bp.GetID()}: {bp.GetNumLocations()} location(s)")
    for i in range(bp.GetNumLocations()):
        loc = bp.GetLocationAtIndex(i)
        result.PutCString(f"  {loc.GetAddress()}")
    result.SetStatus(lldb.eReturnStatusSuccessFinishResult)

def __lldb_init_module(debugger, _dict):
    """Initialize the OCaml LLDB plugin"""
    # Register commands
    debugger.HandleCommand(f'command script add -f {MODULE}.ocaml_print p')
    debugger.HandleCommand(f'command script add -f {MODULE}.ocaml_frame_var fv')
    debugger.HandleCommand(f'command script add -f {MODULE}.ocaml_vars ocaml_vars')
    debugger.HandleCommand(f'command script add -f {MODULE}.ocaml_tree ocaml_tree')
    debugger.HandleCommand(f'command script add -f {MODULE}.ocaml_break b')

    print("OCaml LLDB helpers loaded")
    print("  Commands: ocaml_vars, ocaml_tree")
    print("  Breakpoints: b Module::function  (standard LLDB command now OCaml-aware!)")
