(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

let compute x y =
  let sum = x + y in
  let product = x * y in
  let difference = x - y in
  sum + product + difference

let fibonacci n =
  let rec fib a b count =
    if count = 0 then a
    else fib b (a + b) (count - 1)
  in
  fib 0 1 n

let process_list lst =
  let rec loop acc = function
    | [] -> acc
    | x :: xs ->
        let doubled = x * 2 in
        let result = acc + doubled in
        loop result xs
  in
  loop 0 lst

let () =
  let x = 5 in
  let y = 10 in
  let comp_result = compute x y in
  let fib_result = fibonacci 10 in
  let list_result = process_list [1; 2; 3; 4; 5] in
  Printf.printf "%d %d %d\n" comp_result fib_result list_result
