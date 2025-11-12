(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                  Test basic DWARF debugging information                *)
(*                                                                        *)
(**************************************************************************)

(* Test basic types and simple functions for DWARF generation *)

(* Integer operations *)
let test_int () =
  let x = 42 in
  let y = 17 in
  let sum = x + y in
  let diff = x - y in
  let prod = x * y in
  Printf.printf "Int: %d + %d = %d, %d - %d = %d, %d * %d = %d\n"
    x y sum x y diff x y prod

(* Floating point operations *)
let test_float () =
  let x = 3.14 in
  let y = 2.71 in
  let sum = x +. y in
  let diff = x -. y in
  let prod = x *. y in
  Printf.printf "Float: %f + %f = %f, %f - %f = %f, %f * %f = %f\n"
    x y sum x y diff x y prod

(* String operations *)
let test_string () =
  let s1 = "Hello" in
  let s2 = "World" in
  let s3 = s1 ^ " " ^ s2 in
  let len = String.length s3 in
  Printf.printf "String: '%s' has length %d\n" s3 len

(* Boolean operations *)
let test_bool () =
  let a = true in
  let b = false in
  let and_result = a && b in
  let or_result = a || b in
  let not_a = not a in
  Printf.printf "Bool: true && false = %b, true || false = %b, not true = %b\n"
    and_result or_result not_a

(* Character operations *)
let test_char () =
  let c = 'A' in
  let code = Char.code c in
  let c2 = Char.chr (code + 1) in
  Printf.printf "Char: '%c' has code %d, next is '%c'\n" c code c2

(* Unit type *)
let test_unit () =
  let u = () in
  let _ = u in
  Printf.printf "Unit: ()\n"

(* Main entry point - set breakpoint here *)
let () =
  Printf.printf "=== DWARF Basic Types Test ===\n";
  test_int ();
  test_float ();
  test_string ();
  test_bool ();
  test_char ();
  test_unit ();
  Printf.printf "=== Test Complete ===\n"
