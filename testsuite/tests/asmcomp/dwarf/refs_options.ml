(* TEST
 native;
 
 flags = "-g -gdwarf-fidelity enhanced";
*)

(* Test references and option types *)

let test_ref () =
  let r = ref 10 in
  r := !r + 5;
  Printf.printf "%d\n" !r

let test_option () =
  let some_val = Some 42 in
  let none_val = None in
  match some_val with
  | Some x -> Printf.printf "%d " x
  | None -> ()
  ;
  match none_val with
  | Some _ -> ()
  | None -> print_endline "none"

let () =
  test_ref ();
  test_option ()
