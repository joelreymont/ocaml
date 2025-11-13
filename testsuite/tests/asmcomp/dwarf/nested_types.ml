(* TEST
 native;
 
 flags = "-g -gdwarf-fidelity enhanced";
*)

(* Test nested type structures *)

type inner = { a : int; b : string }
type outer = { x : inner; y : float }

type tree = Leaf | Node of int * tree * tree

let make_tree () =
  Node (1, Node (2, Leaf, Leaf), Node (3, Leaf, Leaf))

let rec count = function
  | Leaf -> 0
  | Node (_, l, r) -> 1 + count l + count r

let () =
  let i = { a = 10; b = "test" } in
  let o = { x = i; y = 2.5 } in
  let t = make_tree () in
  Printf.printf "%d %s %.1f %d\n" o.x.a o.x.b o.y (count t)
