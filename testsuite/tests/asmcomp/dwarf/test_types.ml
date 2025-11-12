(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                  Test complex OCaml types for DWARF                    *)
(*                                                                        *)
(**************************************************************************)

(* Test complex OCaml data types *)

(* Record types *)
type person = {
  name : string;
  age : int;
  height : float;
}

let test_record () =
  let p = { name = "Alice"; age = 30; height = 1.65 } in
  Printf.printf "Record: %s is %d years old, %.2fm tall\n"
    p.name p.age p.height

(* Tuple types *)
let test_tuple () =
  let t2 = (42, "hello") in
  let t3 = (1, 2.0, "three") in
  let (x, y) = t2 in
  let (a, b, c) = t3 in
  Printf.printf "Tuple: (%d, %s), (%d, %f, %s)\n" x y a b c

(* Variant types *)
type color = Red | Green | Blue | RGB of int * int * int

let test_variant () =
  let c1 = Red in
  let c2 = RGB (255, 128, 0) in
  let color_to_string = function
    | Red -> "Red"
    | Green -> "Green"
    | Blue -> "Blue"
    | RGB (r, g, b) -> Printf.sprintf "RGB(%d,%d,%d)" r g b
  in
  Printf.printf "Variant: %s, %s\n" (color_to_string c1) (color_to_string c2)

(* Option type *)
let test_option () =
  let some_val = Some 42 in
  let none_val = None in
  let get_value opt default =
    match opt with
    | Some v -> v
    | None -> default
  in
  Printf.printf "Option: Some = %d, None = %d\n"
    (get_value some_val 0) (get_value none_val 99)

(* List type *)
let test_list () =
  let lst = [1; 2; 3; 4; 5] in
  let len = List.length lst in
  let sum = List.fold_left (+) 0 lst in
  Printf.printf "List: length = %d, sum = %d\n" len sum

(* Array type *)
let test_array () =
  let arr = [| 10; 20; 30; 40; 50 |] in
  let len = Array.length arr in
  let first = arr.(0) in
  let last = arr.(len - 1) in
  Printf.printf "Array: length = %d, first = %d, last = %d\n" len first last

(* Reference type *)
let test_ref () =
  let r = ref 100 in
  let old_val = !r in
  r := !r + 50;
  let new_val = !r in
  Printf.printf "Ref: old = %d, new = %d\n" old_val new_val

(* Polymorphic variant *)
let test_poly_variant () =
  let v1 = `Int 42 in
  let v2 = `String "hello" in
  let process = function
    | `Int n -> Printf.sprintf "int: %d" n
    | `String s -> Printf.sprintf "string: %s" s
    | `Float f -> Printf.sprintf "float: %f" f
  in
  Printf.printf "Poly variant: %s, %s\n" (process v1) (process v2)

(* Main entry point *)
let () =
  Printf.printf "=== DWARF Complex Types Test ===\n";
  test_record ();
  test_tuple ();
  test_variant ();
  test_option ();
  test_list ();
  test_array ();
  test_ref ();
  test_poly_variant ();
  Printf.printf "=== Test Complete ===\n"
