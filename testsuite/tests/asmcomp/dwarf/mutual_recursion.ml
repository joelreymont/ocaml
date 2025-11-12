(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test mutually recursive functions *)

let rec is_even n =
  if n = 0 then true
  else is_odd (n - 1)

and is_odd n =
  if n = 0 then false
  else is_even (n - 1)

let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)

let () =
  Printf.printf "%b %b %d\n"
    (is_even 4)
    (is_odd 5)
    (fib 10)
