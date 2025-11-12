(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test basic compilation with DWARF enabled *)

let add x y = x + y

let () =
  print_int (add 10 20);
  print_newline ()
