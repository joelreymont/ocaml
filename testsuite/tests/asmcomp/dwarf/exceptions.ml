(* TEST
 native;
 env = "OCAMLPARAM=dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test exception handling with DWARF *)

exception DivByZero

let safe_div x y =
  if y = 0 then raise DivByZero
  else x / y

let test_exception () =
  try
    let a = safe_div 10 2 in
    let b = safe_div 10 0 in
    a + b
  with DivByZero -> 99

let () =
  print_int (test_exception ());
  print_newline ()
