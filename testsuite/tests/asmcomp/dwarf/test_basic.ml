(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test basic integer operations *)

let test_int () =
  let x = 42 in
  let y = 17 in
  Printf.printf "%d\n" (x + y - x * y)

let test_float () =
  let x = 3.14 in
  let y = 2.71 in
  Printf.printf "%.2f\n" (x +. y)

let test_string () =
  let s = "Hello" ^ " " ^ "World" in
  Printf.printf "%s\n" s

let () =
  test_int ();
  test_float ();
  test_string ()
