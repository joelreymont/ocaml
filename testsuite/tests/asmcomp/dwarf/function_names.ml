(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test function name preservation in DWARF *)

let factorial n =
  let rec loop acc n =
    if n <= 1 then acc
    else loop (acc * n) (n - 1)
  in
  loop 1 n

let fibonacci n =
  let rec fib a b n =
    if n = 0 then a
    else fib b (a + b) (n - 1)
  in
  fib 0 1 n

let () =
  Printf.printf "%d %d\n" (factorial 5) (fibonacci 10)
