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

[@@@ocaml.warning "+a-4-30-40-41-42"]

type t = {
  source_file : string;
  world : Dwarf_world.t;
  mutable current_function : Proto_die.t option;
  type_offsets : Dwarf_world.type_offsets;
}

let is_enabled () =
  (* Check if debugging is enabled and DWARF fidelity is set *)
  !Clflags.debug && Dwarf_flags.is_dwarf_enabled ()

let create ~source_file ~compilation_dir ~producer () =
  if not (is_enabled ()) then
    Misc.fatal_error "DWARF generation requested but not enabled";

  let world = Dwarf_world.create
    ~producer
    ~comp_dir:compilation_dir
    ~language:Dwarf_language.ocaml
    ()
  in

  (* Add standard OCaml type DIEs (int, value, etc.)
     These will be the first DIEs after the compilation unit DIE *)
  let type_offsets = Dwarf_world.add_standard_types world in

  { source_file; world; current_function = None; type_offsets }

let finalize_current_function t =
  (* Add the current function (with all its variables) to the world *)
  match t.current_function with
  | None -> ()
  | Some func_die ->
      Dwarf_world.add_die t.world func_die;
      t.current_function <- None

let add_function t ~name ~start_address ~end_address =
  (* Finalize any previous function first *)
  finalize_current_function t;

  (* Create a new function DIE *)
  let func_die = Proto_die.create Dwarf_tag.DW_TAG_subprogram in
  let func_die = Proto_die.with_name func_die name in
  let func_die = Proto_die.with_pc_range func_die ~start:start_address ~end_:end_address in
  let func_die = Proto_die.with_external func_die true in

  (* Store as current function (don't add to world yet - we'll add variables first) *)
  t.current_function <- Some func_die

let add_variable t ~name ~(location : Variable_location.location) ~is_parameter ?type_name () =
  match t.current_function with
  | None ->
      (* No current function - ignore variable *)
      ()
  | Some func_die ->
      (* Convert location to DWARF expression bytes *)
      let location_expr = Variable_location.location_to_expression location.kind in

      (* Determine which type to use based on type_name hint.
         Default to generic "value" type if not specified. *)
      let type_ref = match type_name with
        | Some "int" -> t.type_offsets.ocaml_int
        | Some "float" -> t.type_offsets.ocaml_float
        | Some "char" -> t.type_offsets.ocaml_char
        | Some "bool" -> t.type_offsets.ocaml_bool
        | Some "string" -> t.type_offsets.ocaml_string
        | Some "unit" -> t.type_offsets.ocaml_unit
        | Some "int32" -> t.type_offsets.ocaml_int32
        | Some "int64" -> t.type_offsets.ocaml_int64
        | Some "nativeint" -> t.type_offsets.ocaml_nativeint
        | _ -> t.type_offsets.ocaml_value  (* Default *)
      in

      (* Create variable DIE with appropriate type reference *)
      let var_die = Proto_die.create_variable
        ~name
        ~type_ref
        ~location:location_expr
        ~is_parameter
        ()
      in

      (* Add variable as child of function *)
      let func_die = Proto_die.add_child func_die var_die in
      t.current_function <- Some func_die

let add_line_number t ~address ~file ~line ~column =
  Dwarf_world.add_line_number_entry t.world
    ~address
    ~file
    ~line
    ~column

(* User-defined type registration *)

let add_record_type t ~name ~byte_size ~fields =
  let type_die = Dwarf_world.create_record_type ~name ~byte_size ~fields in
  Dwarf_world.add_user_type t.world ~name type_die

let add_variant_type t ~name ~byte_size ~variants =
  let type_die = Dwarf_world.create_variant_type ~name ~byte_size ~variants in
  Dwarf_world.add_user_type t.world ~name type_die

let add_tuple_type t ~name ~byte_size ~field_types =
  let type_die = Dwarf_world.create_tuple_type ~name ~byte_size ~field_types in
  Dwarf_world.add_user_type t.world ~name type_die

let add_array_type t ~name ~element_type_ref =
  let type_die = Dwarf_world.create_array_type ~name ~element_type_ref in
  Dwarf_world.add_user_type t.world ~name type_die

let add_pointer_type t ~name ~byte_size ~element_type_ref =
  let type_die = Dwarf_world.create_pointer_type ~name ~byte_size ~element_type_ref in
  Dwarf_world.add_user_type t.world ~name type_die

let lookup_type t ~name =
  Dwarf_world.lookup_user_type t.world ~name

let emit t =
  (* Finalize any pending function *)
  finalize_current_function t;

  Dwarf_world.emit t.world

let world t = t.world

let print ppf t =
  Format.fprintf ppf "@[<v>DWARF for %s:@," t.source_file;
  Dwarf_world.print ppf t.world;
  Format.fprintf ppf "@]"
