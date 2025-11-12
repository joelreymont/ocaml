(* TEST
 native;
 env = "OCAMLPARAM=dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test debugging with nested calls and recursion *)

let add x y =
  let sum = x + y in
  Printf.printf "add: %d + %d = %d\n" x y sum;
  sum

let multiply_and_add a b c =
  let product = a * b in
  let result = add product c in
  Printf.printf "multiply_and_add: (%d * %d) + %d = %d\n" a b c result;
  result

let rec factorial n =
  if n <= 1 then
    1
  else
    n * factorial (n - 1)

let describe_number n =
  match n with
  | 0 -> "zero"
  | 1 -> "one"
  | n when n < 0 -> "negative"
  | n when n > 100 -> "large"
  | _ -> "normal"

let () =
  Printf.printf "=== DWARF Debugging Test ===\n";
  let x = 10 in
  let y = 20 in
  let sum = add x y in
  let result = multiply_and_add 3 4 5 in
  let fact = factorial 5 in
  Printf.printf "factorial(5) = %d\n" fact;
  let desc = describe_number sum in
  Printf.printf "sum is: %s\n" desc;
  Printf.printf "=== Test Complete ===\n"
