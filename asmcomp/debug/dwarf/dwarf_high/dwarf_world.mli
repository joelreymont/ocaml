(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                  Mark Shinwell, Jane Street Europe                     *)
(*                                                                        *)
(*   Copyright 2013--2023 Jane Street Group LLC                           *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** DWARF World - Main orchestrator for DWARF generation.

    The DWARF world manages the entire DWARF generation process for a
    compilation unit. It collects DIEs, manages tables (.debug_loc,
    .debug_ranges), assigns abbreviations, and emits all DWARF sections.

    This is the primary entry point for DWARF generation. *)

type t

(** Create a new DWARF world for a compilation unit *)
val create :
  producer:string ->
  comp_dir:string ->
  language:Dwarf_language.t ->
  unit ->
  t

(** Add a top-level DIE (e.g., a function or global variable) *)
val add_die : t -> Proto_die.t -> unit

(** Add a location list and return its offset in .debug_loc *)
val add_location_list :
  t ->
  Location_list_entry.t list ->
  int

(** Add a range list and return its offset in .debug_ranges *)
val add_range_list :
  t ->
  Range_list_entry.t list ->
  int

(** Add a line number entry for source-level debugging *)
val add_line_number_entry :
  t ->
  address:Code_address.t ->
  file:string ->
  line:int ->
  column:int ->
  unit

(** Get the compilation unit DIE *)
val compilation_unit : t -> Proto_die.t

(** Get all top-level DIEs *)
val all_dies : t -> Proto_die.t list

(** Get the location list table *)
val location_list_table : t -> Location_list_table.t

(** Get the range list table *)
val range_list_table : t -> Range_list_table.t

(** Type DIE offsets for referencing standard types *)
type type_offsets = {
  ocaml_value : int;   (** Generic OCaml value type *)
  ocaml_int : int;     (** OCaml integer type *)
  ocaml_float : int;   (** OCaml float type *)
  ocaml_char : int;    (** OCaml char type *)
  ocaml_bool : int;    (** OCaml bool type *)
  ocaml_string : int;  (** OCaml string type *)
  ocaml_unit : int;    (** OCaml unit type *)
}

(** Add standard OCaml type DIEs to the world and return their offsets *)
val add_standard_types : t -> type_offsets

(** Create a member DIE for a struct/union field *)
val create_member : name:string -> type_ref:int -> byte_offset:int -> Proto_die.t

(** Create a tuple type DIE (anonymous struct with numbered fields).
    @param name the type name (e.g., "int * float")
    @param field_types list of type references for each field *)
val create_tuple_type : name:string -> field_types:int list -> Proto_die.t

(** Create a record type DIE (named struct with field names).
    @param name the type name
    @param fields list of (field_name, type_ref) pairs *)
val create_record_type : name:string -> fields:(string * int) list -> Proto_die.t

(** Create a variant type DIE (discriminated union).
    @param name the type name
    @param variants list of (constructor_name, optional_payload_type_ref) pairs *)
val create_variant_type : name:string -> variants:(string * int option) list -> Proto_die.t

(** Create an array type DIE.
    @param element_type_ref type reference for array elements
    @param length array length *)
val create_array_type : element_type_ref:int -> length:int -> Proto_die.t

(** Emit all DWARF sections to a buffer *)
type relocation = {
  offset : int;
  label : string;
}

type section_data = {
  debug_info : bytes;
  debug_info_relocs : relocation list;
  debug_abbrev : bytes;
  debug_str : bytes;
  debug_line : bytes option;
  debug_loc : bytes option;
  debug_ranges : bytes option;
}

(** Generate all DWARF section data *)
val emit : t -> section_data

(** Pretty-print the DWARF world state *)
val print : Format.formatter -> t -> unit
