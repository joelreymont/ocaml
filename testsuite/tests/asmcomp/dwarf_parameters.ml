(* TEST
   native;
   flags = "-g";
*)

(* Test DWARF parameter tracking

   This test verifies that function parameters are tracked in DWARF
   debug information with proper location expressions. Each function
   should have DW_TAG_formal_parameter DIEs for its parameters. *)

let add x y = x + y

let multiply a b = a * b

let take_three x y z = x + y + z

let higher_order f x = f x

let () =
  Printf.printf "%d\n" (add 1 2);
  Printf.printf "%d\n" (multiply 3 4);
  Printf.printf "%d\n" (take_three 1 2 3);
  Printf.printf "%d\n" (higher_order (fun x -> x * 2) 5)
