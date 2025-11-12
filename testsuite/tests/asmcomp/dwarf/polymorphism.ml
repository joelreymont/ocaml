(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test polymorphic functions *)

let identity x = x

let map f lst =
  let rec loop acc = function
    | [] -> List.rev acc
    | x :: xs -> loop (f x :: acc) xs
  in
  loop [] lst

let filter p lst =
  let rec loop acc = function
    | [] -> List.rev acc
    | x :: xs -> if p x then loop (x :: acc) xs else loop acc xs
  in
  loop [] lst

let () =
  let nums = [1; 2; 3; 4; 5] in
  let doubled = map (fun x -> x * 2) nums in
  let evens = filter (fun x -> x mod 2 = 0) doubled in
  List.iter (fun x -> Printf.printf "%d " x) evens;
  print_newline ()
