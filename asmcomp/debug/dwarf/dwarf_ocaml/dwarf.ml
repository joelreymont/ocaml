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

  (* Add standard OCaml type DIEs (int, float, char, bool, string, unit, value)
     These will be the first DIEs after the compilation unit DIE *)
  let type_offsets = Dwarf_world.add_standard_types world in

  (* Add commonly used composite types for better debugging experience *)
  (* These types are frequently used in OCaml programs and having them
     predefined improves the debugging experience *)

  (* Common tuple: int * int (coordinates, pairs, etc.) *)
  let int_int_tuple = Dwarf_world.create_tuple_type
    ~name:"int * int"
    ~field_types:[type_offsets.ocaml_int; type_offsets.ocaml_int]
  in
  Dwarf_world.add_die world int_int_tuple;

  (* Common tuple: int * float (mixed numeric pairs) *)
  let int_float_tuple = Dwarf_world.create_tuple_type
    ~name:"int * float"
    ~field_types:[type_offsets.ocaml_int; type_offsets.ocaml_float]
  in
  Dwarf_world.add_die world int_float_tuple;

  (* Common tuple: float * float (2D points, etc.) *)
  let float_float_tuple = Dwarf_world.create_tuple_type
    ~name:"float * float"
    ~field_types:[type_offsets.ocaml_float; type_offsets.ocaml_float]
  in
  Dwarf_world.add_die world float_float_tuple;

  (* Generic option type: None | Some of value
     This represents option<'a> where 'a is unknown *)
  let option_type = Dwarf_world.create_variant_type
    ~name:"option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_value)
    ]
  in
  Dwarf_world.add_die world option_type;

  (* int option: None | Some of int *)
  let int_option_type = Dwarf_world.create_variant_type
    ~name:"int option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_int)
    ]
  in
  Dwarf_world.add_die world int_option_type;

  (* Generic result type: Ok of value | Error of string *)
  let result_type = Dwarf_world.create_variant_type
    ~name:"result"
    ~variants:[
      ("Ok", Some type_offsets.ocaml_value);
      ("Error", Some type_offsets.ocaml_string)
    ]
  in
  Dwarf_world.add_die world result_type;

  (* Common 3-tuples for 3D coordinates, triples, etc. *)
  let int_int_int_tuple = Dwarf_world.create_tuple_type
    ~name:"int * int * int"
    ~field_types:[
      type_offsets.ocaml_int;
      type_offsets.ocaml_int;
      type_offsets.ocaml_int
    ]
  in
  Dwarf_world.add_die world int_int_int_tuple;

  (* float * float * float for 3D coordinates *)
  let float_float_float_tuple = Dwarf_world.create_tuple_type
    ~name:"float * float * float"
    ~field_types:[
      type_offsets.ocaml_float;
      type_offsets.ocaml_float;
      type_offsets.ocaml_float
    ]
  in
  Dwarf_world.add_die world float_float_float_tuple;

  (* Generic list type: [] | head :: tail
     Simplified representation showing cons cell structure *)
  let list_type = Dwarf_world.create_variant_type
    ~name:"list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_value)
    ]
  in
  Dwarf_world.add_die world list_type;

  (* int list *)
  let int_list_type = Dwarf_world.create_variant_type
    ~name:"int list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_int)
    ]
  in
  Dwarf_world.add_die world int_list_type;

  (* string list *)
  let string_list_type = Dwarf_world.create_variant_type
    ~name:"string list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_string)
    ]
  in
  Dwarf_world.add_die world string_list_type;

  (* bool option *)
  let bool_option_type = Dwarf_world.create_variant_type
    ~name:"bool option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_bool)
    ]
  in
  Dwarf_world.add_die world bool_option_type;

  (* string option *)
  let string_option_type = Dwarf_world.create_variant_type
    ~name:"string option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_string)
    ]
  in
  Dwarf_world.add_die world string_option_type;

  (* float option *)
  let float_option_type = Dwarf_world.create_variant_type
    ~name:"float option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_float)
    ]
  in
  Dwarf_world.add_die world float_option_type;

  (* Reference types: type 'a ref = { mutable contents : 'a }
     Represented as structure with single "contents" field *)

  (* int ref *)
  let int_ref_type = Dwarf_world.create_record_type
    ~name:"int ref"
    ~fields:[("contents", type_offsets.ocaml_int)]
  in
  Dwarf_world.add_die world int_ref_type;

  (* string ref *)
  let string_ref_type = Dwarf_world.create_record_type
    ~name:"string ref"
    ~fields:[("contents", type_offsets.ocaml_string)]
  in
  Dwarf_world.add_die world string_ref_type;

  (* bool ref *)
  let bool_ref_type = Dwarf_world.create_record_type
    ~name:"bool ref"
    ~fields:[("contents", type_offsets.ocaml_bool)]
  in
  Dwarf_world.add_die world bool_ref_type;

  (* float ref *)
  let float_ref_type = Dwarf_world.create_record_type
    ~name:"float ref"
    ~fields:[("contents", type_offsets.ocaml_float)]
  in
  Dwarf_world.add_die world float_ref_type;

  (* Generic ref type *)
  let ref_type = Dwarf_world.create_record_type
    ~name:"ref"
    ~fields:[("contents", type_offsets.ocaml_value)]
  in
  Dwarf_world.add_die world ref_type;

  (* Additional useful list types *)

  (* float list *)
  let float_list_type = Dwarf_world.create_variant_type
    ~name:"float list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_float)
    ]
  in
  Dwarf_world.add_die world float_list_type;

  (* Additional option types *)

  (* char option *)
  let char_option_type = Dwarf_world.create_variant_type
    ~name:"char option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_char)
    ]
  in
  Dwarf_world.add_die world char_option_type;

  (* Additional tuple combinations *)

  (* string * int - common for key-value patterns *)
  let string_int_tuple = Dwarf_world.create_tuple_type
    ~name:"string * int"
    ~field_types:[type_offsets.ocaml_string; type_offsets.ocaml_int]
  in
  Dwarf_world.add_die world string_int_tuple;

  (* string * string - common for string pairs *)
  let string_string_tuple = Dwarf_world.create_tuple_type
    ~name:"string * string"
    ~field_types:[type_offsets.ocaml_string; type_offsets.ocaml_string]
  in
  Dwarf_world.add_die world string_string_tuple;

  (* int * int * int * int - 4-tuples for RGBA, quads *)
  let int_int_int_int_tuple = Dwarf_world.create_tuple_type
    ~name:"int * int * int * int"
    ~field_types:[
      type_offsets.ocaml_int;
      type_offsets.ocaml_int;
      type_offsets.ocaml_int;
      type_offsets.ocaml_int
    ]
  in
  Dwarf_world.add_die world int_int_int_int_tuple;

  (* Additional useful tuple combinations *)

  (* bool * bool - boolean pairs, flags *)
  let bool_bool_tuple = Dwarf_world.create_tuple_type
    ~name:"bool * bool"
    ~field_types:[type_offsets.ocaml_bool; type_offsets.ocaml_bool]
  in
  Dwarf_world.add_die world bool_bool_tuple;

  (* int * string - labeled integers, error messages *)
  let int_string_tuple = Dwarf_world.create_tuple_type
    ~name:"int * string"
    ~field_types:[type_offsets.ocaml_int; type_offsets.ocaml_string]
  in
  Dwarf_world.add_die world int_string_tuple;

  (* float * int - numeric computations with counts *)
  let float_int_tuple = Dwarf_world.create_tuple_type
    ~name:"float * int"
    ~field_types:[type_offsets.ocaml_float; type_offsets.ocaml_int]
  in
  Dwarf_world.add_die world float_int_tuple;

  (* unit option - for optional side effects *)
  let unit_option_type = Dwarf_world.create_variant_type
    ~name:"unit option"
    ~variants:[
      ("None", None);
      ("Some", Some type_offsets.ocaml_unit)
    ]
  in
  Dwarf_world.add_die world unit_option_type;

  (* Additional list types *)

  (* char list - for character processing *)
  let char_list_type = Dwarf_world.create_variant_type
    ~name:"char list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_char)
    ]
  in
  Dwarf_world.add_die world char_list_type;

  (* bool list - for flags and predicates *)
  let bool_list_type = Dwarf_world.create_variant_type
    ~name:"bool list"
    ~variants:[
      ("[]", None);
      ("::", Some type_offsets.ocaml_bool)
    ]
  in
  Dwarf_world.add_die world bool_list_type;

  (* Specialized result types *)

  (* string result - for string operations that can fail *)
  let string_result_type = Dwarf_world.create_variant_type
    ~name:"string result"
    ~variants:[
      ("Ok", Some type_offsets.ocaml_string);
      ("Error", Some type_offsets.ocaml_string)
    ]
  in
  Dwarf_world.add_die world string_result_type;

  (* int result - for numeric operations that can fail *)
  let int_result_type = Dwarf_world.create_variant_type
    ~name:"int result"
    ~variants:[
      ("Ok", Some type_offsets.ocaml_int);
      ("Error", Some type_offsets.ocaml_string)
    ]
  in
  Dwarf_world.add_die world int_result_type;

  { source_file; world; current_function = None }

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

let add_variable t ~name ~(location : Variable_location.location) ~is_parameter =
  match t.current_function with
  | None ->
      (* No current function - ignore variable *)
      ()
  | Some func_die ->
      (* Convert location to DWARF expression bytes *)
      let location_expr = Variable_location.location_to_expression location.kind in

      (* Create variable DIE with type reference.
         For now, all parameters reference the generic "value" type.
         The "value" type DIE is at offset 0x19 in the compilation unit.
         TODO: Calculate this offset dynamically based on CU DIE size. *)
      let var_die = Proto_die.create_variable
        ~name
        ~type_ref:0x19  (* Reference to "value" type *)
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

let emit t =
  (* Finalize any pending function *)
  finalize_current_function t;

  Dwarf_world.emit t.world

let world t = t.world

let print ppf t =
  Format.fprintf ppf "@[<v>DWARF for %s:@," t.source_file;
  Dwarf_world.print ppf t.world;
  Format.fprintf ppf "@]"
