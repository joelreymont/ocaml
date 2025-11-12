(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test primitive type support in DWARF *)

let test_primitives () =
  let i = 42 in
  let f = 3.14159 in
  let c = 'X' in
  let b = true in
  let s = "hello" in
  let _u = () in
  Printf.printf "%d %.2f %c %b %s\n" i f c b s

let () = test_primitives ()
