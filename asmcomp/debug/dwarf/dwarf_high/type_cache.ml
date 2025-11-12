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

(** Type cache for DWARF type generation.

    This module maintains a cache of OCaml types that have already been
    converted to DWARF DIEs, allowing us to:
    1. Avoid duplicate type DIEs
    2. Handle recursive types correctly
    3. Generate type references efficiently *)

[@@@ocaml.warning "+a-4-30-40-41-42"]

(** A cache mapping type representations to DWARF offsets *)
type t = {
  (* Map from type ID to DWARF offset *)
  mutable type_map : int Int.Map.t;

  (* Next available offset for type DIEs *)
  mutable next_offset : int;

  (* World for adding DIEs *)
  world : Dwarf_world.t;

  (* Standard type offsets *)
  std_types : Dwarf_world.type_offsets;
}

let create ~world ~std_types =
  { type_map = Int.Map.empty;
    next_offset = 0x50;  (* Start after standard types *)
    world;
    std_types;
  }

(** Look up a type by ID in the cache *)
let lookup t type_id =
  Int.Map.find_opt type_id t.type_map

(** Add a type DIE to the cache and return its offset *)
let add t type_id die =
  let offset = t.next_offset in
  Dwarf_world.add_die t.world die;
  t.type_map <- Int.Map.add type_id offset t.type_map;
  (* Estimate size: base type ~7 bytes, composite types ~20-50 bytes *)
  t.next_offset <- t.next_offset + 30;
  offset

(** Reserve an offset for a type (for forward references in recursive types) *)
let reserve t type_id =
  let offset = t.next_offset in
  t.type_map <- Int.Map.add type_id offset t.type_map;
  t.next_offset <- t.next_offset + 30;
  offset

(** Check if a type is already cached *)
let is_cached t type_id =
  Int.Map.mem type_id t.type_map

(** Get standard type offset for primitive types *)
let get_std_type t = function
  | "int" -> Some t.std_types.ocaml_int
  | "float" -> Some t.std_types.ocaml_float
  | "char" -> Some t.std_types.ocaml_char
  | "bool" -> Some t.std_types.ocaml_bool
  | "string" -> Some t.std_types.ocaml_string
  | "unit" -> Some t.std_types.ocaml_unit
  | _ -> None

(** Get the generic value type for unknown types *)
let get_value_type t = t.std_types.ocaml_value

let clear t =
  t.type_map <- Int.Map.empty;
  t.next_offset <- 0x50
