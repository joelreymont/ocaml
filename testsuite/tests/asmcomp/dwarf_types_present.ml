(* TEST
   native;
   flags = "-g";
*)

(* Minimal test to verify DWARF composite types compile
   This test ensures that the automatic generation of composite types
   does not cause any compilation errors. The types generated include:
   - int * int, int * float, float * float (tuples)
   - option, int option (variant types with unions)
   - result (variant type with union) *)

let () = print_endline "ok"
