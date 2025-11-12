(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test various type definitions *)

type person = { name : string; age : int }

type color = Red | Green | RGB of int * int * int

let test_record () =
  let p = { name = "Alice"; age = 30 } in
  Printf.printf "%s %d\n" p.name p.age

let test_variant () =
  let c = RGB (255, 128, 0) in
  match c with
  | Red -> print_endline "red"
  | Green -> print_endline "green"
  | RGB (r, g, b) -> Printf.printf "%d %d %d\n" r g b

let test_option () =
  match Some 42 with
  | Some v -> Printf.printf "%d\n" v
  | None -> print_endline "none"

let test_list () =
  let sum = List.fold_left (+) 0 [1; 2; 3; 4; 5] in
  Printf.printf "%d\n" sum

let () =
  test_record ();
  test_variant ();
  test_option ();
  test_list ()
