(* TEST
 native;
 env = "OCAMLPARAM=dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test closure creation and application *)

let make_adder x =
  fun y -> x + y

let apply_twice f x =
  f (f x)

let compose f g x =
  f (g x)

let () =
  let add5 = make_adder 5 in
  let add10 = apply_twice add5 in
  let double x = x * 2 in
  let add_then_double = compose double add5 in
  Printf.printf "%d %d %d\n" (add5 10) (add10 10) (add_then_double 10)
