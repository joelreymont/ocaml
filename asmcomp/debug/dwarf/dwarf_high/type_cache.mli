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
    converted to DWARF DIEs, preventing duplicate type DIEs and handling
    recursive types correctly. *)

type t

(** Create a new type cache *)
val create :
  world:Dwarf_world.t ->
  std_types:Dwarf_world.type_offsets ->
  t

(** Look up a type by ID in the cache.
    Returns the DWARF offset if the type is cached. *)
val lookup : t -> int -> int option

(** Add a type DIE to the cache and return its DWARF offset *)
val add : t -> int -> Proto_die.t -> int

(** Reserve an offset for a type (for handling recursive types) *)
val reserve : t -> int -> int

(** Check if a type is already in the cache *)
val is_cached : t -> int -> bool

(** Get the DWARF offset for a standard primitive type by name.
    Returns None if the type is not a standard primitive. *)
val get_std_type : t -> string -> int option

(** Get the generic 'value' type offset for unknown types *)
val get_value_type : t -> int

(** Clear the cache (for starting a new compilation unit) *)
val clear : t -> unit
