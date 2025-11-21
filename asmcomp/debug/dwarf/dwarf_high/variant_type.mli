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

(** DWARF Variant Type Generation

    This module handles the generation of DWARF DIEs for OCaml variant types.
    OCaml variants are represented in DWARF using a structure with a variant
    part that discriminates between constructors.

    DWARF Structure:
    ```
    DW_TAG_structure_type (tree)
      DW_AT_name: "tree"
      DW_AT_byte_size: 8
      DW_TAG_variant_part
        DW_AT_discr: <reference to tag field>
        DW_TAG_variant (Empty)
          DW_AT_discr_value: 0
        DW_TAG_variant (Node)
          DW_AT_discr_value: 0
          DW_TAG_member (value)
          DW_TAG_member (left)
          DW_TAG_member (right)
    ```
*)

(** Constructor representation *)
type constructor = {
  name : string;
  tag : int;  (** Block tag (0-255) or immediate tag for constants *)
  fields : field list;
}

and field = {
  field_name : string;
  field_type_ref : int;  (** Offset to type DIE *)
  field_offset : int;  (** Byte offset within block *)
}

(** Variant type specification *)
type variant_spec = {
  type_name : string;
  constructors : constructor list;
  has_immediate_ctors : bool;  (** True if variant has constant constructors (Empty, None, etc) *)
}

(** Create a variant type specification *)
val make_variant_spec :
  type_name:string ->
  constructors:constructor list ->
  has_immediate_ctors:bool ->
  variant_spec

(** Create a constructor *)
val make_constructor :
  name:string ->
  tag:int ->
  fields:field list ->
  constructor

(** Create a field *)
val make_field :
  field_name:string ->
  field_type_ref:int ->
  field_offset:int ->
  field

(** Generate DWARF DIEs for a variant type.
    Returns the main structure type DIE. *)
val generate_variant_die : variant_spec -> Proto_die.t

(** Helper: Generate binary tree variant type.
    This is the canonical example for tree types:
      type 'a tree = Empty | Node of 'a * 'a tree * 'a tree
*)
val generate_tree_variant :
  type_name:string ->
  value_type_ref:int ->
  tree_type_ref:int ->
  Proto_die.t

(** Calculate DIE size for a variant type.
    Used for offset calculations when adding to compilation unit. *)
val calculate_variant_die_size : variant_spec -> int

(** Helper: Generate list variant type.
    This is the canonical example for list types:
      type 'a list = [] | (::) of 'a * 'a list
*)
val generate_list_variant :
  type_name:string ->
  value_type_ref:int ->
  list_type_ref:int ->
  Proto_die.t

(** Helper: Generate option variant type.
    For option types:
      type 'a option = None | Some of 'a
*)
val generate_option_variant :
  type_name:string ->
  value_type_ref:int ->
  Proto_die.t

(** Helper: Generate bool variant type.
    For boolean types:
      type bool = false | true
*)
val generate_bool_variant :
  type_name:string ->
  Proto_die.t
