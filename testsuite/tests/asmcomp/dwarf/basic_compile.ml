(* TEST
 native;
 
 flags = "-g -gdwarf-fidelity enhanced";
*)

(* Test basic compilation with DWARF enabled *)

let add x y = x + y

let () =
  print_int (add 10 20);
  print_newline ()
