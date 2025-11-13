(* TEST
 native;
 
 flags = "-g -gdwarf-fidelity enhanced";
*)

(* Test simple function compilation *)

let add x y = x + y

let () =
  Printf.printf "Result: %d\n" (add 10 20)
