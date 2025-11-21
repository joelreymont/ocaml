"""OCaml Runtime Value Decoder for LLDB.

This module provides utilities to decode OCaml runtime values according to
the OCaml value representation scheme with tagged pointers and block headers.
"""

import lldb
from typing import Optional, Tuple, Any


class OCamlValueDecoder:
    """Decodes OCaml runtime values according to the tagging scheme.

    OCaml uses tagged pointers where the LSB indicates the value type:
    - LSB = 1: Immediate integer (value = word >> 1)
    - LSB = 0: Block pointer (heap-allocated structure)

    Block format:
        [header word]  # Contains size, tag, and GC color
        [field 0]      # First field
        [field 1]      # Second field
        ...

    Header word structure (64-bit):
        bits 0-7:   tag (constructor index)
        bits 8-9:   color (GC color)
        bits 10-63: size (number of fields)
    """

    @staticmethod
    def is_int(value: int) -> bool:
        """Check if value is an immediate integer (LSB = 1)."""
        return (value & 1) == 1

    @staticmethod
    def is_block(value: int) -> bool:
        """Check if value is a block pointer (LSB = 0)."""
        return (value & 1) == 0 and value != 0

    @staticmethod
    def int_val(value: int) -> int:
        """Extract integer from tagged immediate."""
        return value >> 1

    @staticmethod
    def block_addr(value: int) -> int:
        """Extract block address from tagged pointer."""
        return value & ~1

    @staticmethod
    def read_header(process: lldb.SBProcess, block_addr: int) -> Optional[Tuple[int, int, int]]:
        """Read block header word.

        Returns:
            (size, tag, color) tuple, or None on error
        """
        error = lldb.SBError()
        header = process.ReadUnsignedFromMemory(block_addr, 8, error)
        if error.Fail():
            return None

        tag = header & 0xFF
        color = (header >> 8) & 0x3
        size = header >> 10
        return (size, tag, color)

    @staticmethod
    def read_field(process: lldb.SBProcess, block_addr: int, field_index: int) -> Optional[int]:
        """Read field from block.

        Fields start after header (8 bytes).
        Each field is 8 bytes (word size).
        """
        error = lldb.SBError()
        field_addr = block_addr + 8 + (field_index * 8)
        value = process.ReadUnsignedFromMemory(field_addr, 8, error)
        if error.Fail():
            return None
        return value


class TreeVisualizer:
    """Pretty-printer for OCaml tree structures.

    Handles binary trees with the structure:
        type 'a tree = Empty | Node of 'a * 'a tree * 'a tree

    Representation:
        Empty: immediate integer (tag 0, encoded as 1)
        Node:  block with tag 0, size 3 (value, left, right)
    """

    def __init__(self, max_depth: int = 10):
        self.max_depth = max_depth
        self.visited = set()  # Track visited block addresses for cycle detection
        self.decoder = OCamlValueDecoder()

    def format_tree(self, value: int, process: lldb.SBProcess,
                   depth: int = 0, indent: int = 0) -> str:
        """Format tree with visual indentation and cycle detection.

        Args:
            value: OCaml value (tagged integer or pointer)
            process: LLDB process for memory access
            depth: Current recursion depth
            indent: Current indentation level

        Returns:
            Formatted string representation
        """
        # Check depth limit
        if depth > self.max_depth:
            return " " * indent + "... (max depth reached)"

        # Handle immediate values (Empty/Leaf)
        if self.decoder.is_int(value):
            int_val = self.decoder.int_val(value)
            if int_val == 0:
                return " " * indent + "Empty"
            else:
                return " " * indent + f"Leaf({int_val})"

        # Handle blocks (Node)
        if self.decoder.is_block(value):
            block_addr = self.decoder.block_addr(value)

            # Cycle detection
            if block_addr in self.visited:
                return " " * indent + "<cycle detected>"

            self.visited.add(block_addr)

            try:
                # Read header
                header_info = self.decoder.read_header(process, block_addr)
                if not header_info:
                    return " " * indent + "<error reading header>"

                size, tag, color = header_info

                # Check if this looks like a Node (tag 0, size 3)
                if tag == 0 and size == 3:
                    # Read tree fields: value, left, right
                    node_value = self.decoder.read_field(process, block_addr, 0)
                    left_tree = self.decoder.read_field(process, block_addr, 1)
                    right_tree = self.decoder.read_field(process, block_addr, 2)

                    if node_value is None or left_tree is None or right_tree is None:
                        return " " * indent + "<error reading fields>"

                    # Extract integer value if tagged
                    if self.decoder.is_int(node_value):
                        node_int = self.decoder.int_val(node_value)
                    else:
                        node_int = node_value  # Already untagged

                    # Build output with tree structure
                    lines = []
                    lines.append(" " * indent + f"Node({node_int})")

                    # Format left subtree
                    lines.append(" " * indent + "├─left:")
                    lines.append(self.format_tree(left_tree, process, depth + 1, indent + 2))

                    # Format right subtree
                    lines.append(" " * indent + "└─right:")
                    lines.append(self.format_tree(right_tree, process, depth + 1, indent + 2))

                    return "\n".join(lines)
                else:
                    # Unknown block structure
                    return " " * indent + f"<block: tag={tag}, size={size}>"

            finally:
                self.visited.remove(block_addr)  # Allow revisiting in different branches

        return " " * indent + f"<unknown value: {value:#x}>"

    def format_simple(self, value: int, process: lldb.SBProcess) -> str:
        """Format tree in compact single-line format.

        Example: Node(5, Node(3, Empty, Empty), Node(7, Empty, Empty))
        """
        if self.decoder.is_int(value):
            int_val = self.decoder.int_val(value)
            return "Empty" if int_val == 0 else f"Leaf({int_val})"

        if self.decoder.is_block(value):
            block_addr = self.decoder.block_addr(value)

            if block_addr in self.visited:
                return "<cycle>"

            self.visited.add(block_addr)

            try:
                header_info = self.decoder.read_header(process, block_addr)
                if not header_info:
                    return "<error>"

                size, tag, color = header_info

                if tag == 0 and size == 3:
                    node_value = self.decoder.read_field(process, block_addr, 0)
                    left_tree = self.decoder.read_field(process, block_addr, 1)
                    right_tree = self.decoder.read_field(process, block_addr, 2)

                    if node_value is None or left_tree is None or right_tree is None:
                        return "<error>"

                    if self.decoder.is_int(node_value):
                        node_int = self.decoder.int_val(node_value)
                    else:
                        node_int = node_value

                    left_str = self.format_simple(left_tree, process)
                    right_str = self.format_simple(right_tree, process)

                    return f"Node({node_int}, {left_str}, {right_str})"
                else:
                    return f"<tag={tag},size={size}>"

            finally:
                self.visited.remove(block_addr)

        return f"<{value:#x}>"


def format_ocaml_value(value: int, process: lldb.SBProcess,
                      tree_format: bool = True, max_depth: int = 10) -> str:
    """Format an OCaml value for display.

    Args:
        value: OCaml value (tagged integer or pointer)
        process: LLDB process for memory access
        tree_format: If True, use tree visualization; otherwise compact format
        max_depth: Maximum recursion depth

    Returns:
        Formatted string representation
    """
    decoder = OCamlValueDecoder()

    # Simple immediate integer
    if decoder.is_int(value):
        return str(decoder.int_val(value))

    # Check if it looks like a tree (heuristic: has 3 fields)
    if decoder.is_block(value):
        block_addr = decoder.block_addr(value)
        header_info = decoder.read_header(process, block_addr)

        if header_info:
            size, tag, color = header_info

            # Looks like a binary tree node
            if tag == 0 and size == 3:
                visualizer = TreeVisualizer(max_depth=max_depth)
                if tree_format:
                    return visualizer.format_tree(value, process)
                else:
                    return visualizer.format_simple(value, process)

    # Fallback: just show the value
    return f"<ocaml value: {value:#x}>"


# Integration with existing LLDB plugin

def add_tree_command(debugger):
    """Add the 'ocaml_tree' command to LLDB."""
    debugger.HandleCommand(
        'command script add -f ocaml_value_decoder.ocaml_tree_command ocaml_tree'
    )


def ocaml_tree_command(debugger, command, exe_ctx, result, _dict):
    """LLDB command to visualize an OCaml tree variable.

    Usage: ocaml_tree <variable-name>

    Example:
        (lldb) ocaml_tree tree
        Node(5)
        ├─left:
          Node(3)
          ├─left:
            Empty
          └─right:
            Empty
        └─right:
          Node(7)
    """
    frame = exe_ctx.frame
    var_name = command.strip()

    if not frame or not frame.IsValid() or not var_name:
        result.AppendMessage("Usage: ocaml_tree <variable-name>")
        return

    # Try to get the variable value
    var = frame.FindVariable(var_name)
    if not var or not var.IsValid():
        result.AppendMessage(f"Variable '{var_name}' not found")
        return

    # Get the value
    error = lldb.SBError()
    value = var.GetValueAsUnsigned(error)
    if error.Fail():
        result.AppendMessage(f"Could not read value: {error}")
        return

    # Get process for memory access
    process = frame.GetThread().GetProcess()
    if not process or not process.IsValid():
        result.AppendMessage("No valid process")
        return

    # Format and display
    try:
        formatted = format_ocaml_value(value, process, tree_format=True, max_depth=10)
        result.AppendMessage(f"{var_name} =")
        result.AppendMessage(formatted)
    except Exception as e:
        result.AppendMessage(f"Error formatting tree: {e}")


def __lldb_init_module(debugger, _dict):
    """Initialize the module when loaded into LLDB."""
    add_tree_command(debugger)
    print("OCaml value decoder loaded. Use 'ocaml_tree <variable>' to visualize trees.")
