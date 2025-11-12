(* Test program for composite OCaml types with DWARF debugging *)

(* Tuple types *)
type point_tuple = int * int
type triple = int * float * char

let test_tuple (p : point_tuple) =
  let (x, y) = p in
  x + y

let test_triple (t : triple) =
  let (i, f, c) = t in
  i + int_of_float f + Char.code c

(* Record types *)
type point_record = {
  x : int;
  y : int;
}

type person = {
  name : string;
  age : int;
  height : float;
}

let test_record (p : point_record) =
  p.x + p.y

let test_person (p : person) =
  Printf.printf "Name: %s, Age: %d, Height: %.2f\n" p.name p.age p.height

(* Variant types *)
type option_int =
  | None
  | Some of int

type result =
  | Ok of int
  | Error of string

let test_option (o : option_int) =
  match o with
  | None -> 0
  | Some x -> x

let test_result (r : result) =
  match r with
  | Ok x -> x
  | Error msg -> Printf.printf "Error: %s\n" msg; 0

(* Array types *)
let test_array (arr : int array) =
  if Array.length arr > 0 then
    arr.(0)
  else
    0

let test_float_array (arr : float array) =
  if Array.length arr > 0 then
    arr.(0)
  else
    0.0

(* Main function to exercise all types *)
let () =
  (* Test tuples *)
  let p = (10, 20) in
  let _ = test_tuple p in

  let t = (5, 3.14, 'x') in
  let _ = test_triple t in

  (* Test records *)
  let pr = { x = 15; y = 25 } in
  let _ = test_record pr in

  let person = { name = "Alice"; age = 30; height = 1.65 } in
  test_person person;

  (* Test variants *)
  let opt1 = Some 42 in
  let opt2 = None in
  let _ = test_option opt1 in
  let _ = test_option opt2 in

  let res1 = Ok 100 in
  let res2 = Error "something went wrong" in
  let _ = test_result res1 in
  let _ = test_result res2 in

  (* Test arrays *)
  let int_arr = [| 1; 2; 3; 4; 5 |] in
  let _ = test_array int_arr in

  let float_arr = [| 1.0; 2.0; 3.0 |] in
  let _ = test_float_array float_arr in

  print_endline "All tests completed!"
