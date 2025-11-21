(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                       Joel Reymont                                     *)
(*                                                                        *)
(*   Copyright 2024 Joel Reymont                                          *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

[@@@ocaml.warning "+a-4-30-40-41-42"]

(** Constructor representation *)
type constructor = {
  name : string;
  tag : int;  (* Block tag (0-255) or immediate tag for constants *)
  fields : field list;
}

and field = {
  field_name : string;
  field_type_ref : int;  (* Offset to type DIE *)
  field_offset : int;  (* Byte offset within block *)
}

(** Variant type specification *)
type variant_spec = {
  type_name : string;
  constructors : constructor list;
  has_immediate_ctors : bool;  (* True if variant has constant constructors *)
}

let make_variant_spec ~type_name ~constructors ~has_immediate_ctors =
  { type_name; constructors; has_immediate_ctors }

let make_constructor ~name ~tag ~fields =
  { name; tag; fields }

let make_field ~field_name ~field_type_ref ~field_offset =
  { field_name; field_type_ref; field_offset }

(** Generate DWARF DIEs for a variant type.

    OCaml Memory Layout:
    - Constant constructors: encoded as immediate integers (2*n+1)
      Example: Empty = 1 (tag 0 encoded as immediate)
    - Block constructors: heap-allocated with header
      Header word (64-bit):
        bits 0-7:   tag (constructor index)
        bits 8-9:   color (GC)
        bits 10-63: size (number of fields)
      Fields follow header, each 8 bytes

    DWARF Representation:
    We create a DW_TAG_structure_type with:
    - DW_TAG_member for discriminant (the tag)
    - DW_TAG_variant_part containing:
      - One DW_TAG_variant per constructor
      - Each variant has DW_AT_discr_value matching the tag
      - Block constructors have DW_TAG_member children for fields
*)
let generate_variant_die spec =
  (* Create main structure type *)
  let struct_die = Proto_die.create Dwarf_tag.DW_TAG_structure_type in
  let struct_die = Proto_die.with_name struct_die spec.type_name in
  let struct_die = Proto_die.with_byte_size struct_die 8 in  (* OCaml value = 8 bytes *)

  (* Create variant part (discriminated union) *)
  let variant_part = Proto_die.create Dwarf_tag.DW_TAG_variant_part in

  (* For each constructor, create a variant DIE *)
  let variant_dies = List.map (fun ctor ->
    let variant = Proto_die.create Dwarf_tag.DW_TAG_variant in
    let variant = Proto_die.with_name variant ctor.name in

    (* Add discriminant value (the tag) *)
    let variant = Proto_die.with_discr_value variant ctor.tag in

    (* For block constructors with fields, add members *)
    let variant = if List.length ctor.fields > 0 then
      let field_dies = List.map (fun field ->
        let member = Proto_die.create Dwarf_tag.DW_TAG_member in
        let member = Proto_die.with_name member field.field_name in
        let member = Proto_die.with_type member field.field_type_ref in
        let member = Proto_die.with_data_member_location member field.field_offset in
        member
      ) ctor.fields in
      Proto_die.add_children variant field_dies
    else
      variant
    in
    variant
  ) spec.constructors in

  (* Add all variants to variant part *)
  let variant_part = Proto_die.add_children variant_part variant_dies in

  (* Add variant part to structure *)
  let struct_die = Proto_die.add_child struct_die variant_part in

  struct_die

(** Helper: Generate binary tree variant type.

    OCaml type definition:
      type 'a tree = Empty | Node of 'a * 'a tree * 'a tree

    Memory layout:
      Empty: immediate value 1 (tag 0 as 2*0+1)
      Node: block with tag 0, size 3
        [header: tag=0, size=3]
        [field 0: value (type 'a)]
        [field 1: left subtree]
        [field 2: right subtree]
*)
let generate_tree_variant ~type_name ~value_type_ref ~tree_type_ref =
  (* Empty constructor: tag 0 as immediate (no fields) *)
  let empty_ctor = make_constructor
    ~name:"Empty"
    ~tag:0
    ~fields:[]
  in

  (* Node constructor: tag 0, has 3 fields
     Field offsets:
     - Field 0 (value): offset 8 (after header)
     - Field 1 (left):  offset 16
     - Field 2 (right): offset 24
  *)
  let node_ctor = make_constructor
    ~name:"Node"
    ~tag:0
    ~fields:[
      make_field ~field_name:"value" ~field_type_ref:value_type_ref ~field_offset:8;
      make_field ~field_name:"left" ~field_type_ref:tree_type_ref ~field_offset:16;
      make_field ~field_name:"right" ~field_type_ref:tree_type_ref ~field_offset:24;
    ]
  in

  let spec = make_variant_spec
    ~type_name
    ~constructors:[empty_ctor; node_ctor]
    ~has_immediate_ctors:true
  in

  generate_variant_die spec

(** Calculate DIE size for a variant type.

    Structure:
    - DW_TAG_structure_type: abbrev(1) + name(len+1) + byte_size(1)
    - DW_TAG_variant_part: abbrev(1)
      - For each variant:
        - DW_TAG_variant: abbrev(1) + name(len+1) + discr_value(1)
        - For each field:
          - DW_TAG_member: abbrev(1) + name(len+1) + type_ref(4) + location(1)
        - Null terminator: 1
      - Null terminator: 1
    - Null terminator: 1
*)
let calculate_variant_die_size spec =
  (* Structure DIE *)
  let struct_size =
    1 +  (* abbrev code *)
    (String.length spec.type_name + 1) +  (* name *)
    1  (* byte_size *)
  in

  (* Variant part DIE *)
  let variant_part_size = 1 in  (* abbrev code *)

  (* Variant DIEs *)
  let variants_size = List.fold_left (fun acc ctor ->
    let variant_size =
      1 +  (* abbrev code *)
      (String.length ctor.name + 1) +  (* name *)
      1  (* discr_value *)
    in
    let fields_size = List.fold_left (fun acc field ->
      acc +
      1 +  (* abbrev code *)
      (String.length field.field_name + 1) +  (* name *)
      4 +  (* type ref *)
      1  (* data member location *)
    ) 0 ctor.fields in
    let null_after_fields = if List.length ctor.fields > 0 then 1 else 0 in
    acc + variant_size + fields_size + null_after_fields
  ) 0 spec.constructors in

  (* Null terminators: after variants, after variant_part, after structure *)
  let null_terminators = 3 in

  struct_size + variant_part_size + variants_size + null_terminators
