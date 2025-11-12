(* TEST
 native;
 env = "OCAMLPARAM=dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test array and list operations with DWARF *)

let array_sum arr =
  let sum = ref 0 in
  for i = 0 to Array.length arr - 1 do
    sum := !sum + arr.(i)
  done;
  !sum

let rec list_sum = function
  | [] -> 0
  | x :: xs -> x + list_sum xs

let () =
  let arr = [| 1; 2; 3; 4; 5 |] in
  let lst = [1; 2; 3; 4; 5] in
  Printf.printf "%d %d\n" (array_sum arr) (list_sum lst)
