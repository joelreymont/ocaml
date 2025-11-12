(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test simple function compilation *)

let add x y = x + y

let () =
  Printf.printf "Result: %d\n" (add 10 20)
