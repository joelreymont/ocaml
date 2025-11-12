(* TEST
   native;
   flags = "-g";
*)

(* Test automatic composite type generation in DWARF *)

(* Test int * int tuple *)
let test_int_int_tuple () =
  let p : int * int = (42, 24) in
  let (x, y) = p in
  Printf.printf "int*int: %d,%d\n" x y

(* Test int * float tuple *)
let test_int_float_tuple () =
  let t : int * float = (10, 3.14) in
  let (i, f) = t in
  Printf.printf "int*float: %d,%.2f\n" i f

(* Test float * float tuple *)
let test_float_float_tuple () =
  let p : float * float = (1.5, 2.5) in
  let (x, y) = p in
  Printf.printf "float*float: %.1f,%.1f\n" x y

(* Test int option *)
let test_int_option () =
  let some_val : int option = Some 123 in
  let none_val : int option = None in
  match some_val with
  | Some x -> Printf.printf "int option: Some %d\n" x
  | None -> Printf.printf "int option: None\n"

(* Test generic option *)
let test_option () =
  let opt : string option = Some "test" in
  match opt with
  | Some s -> Printf.printf "option: Some %s\n" s
  | None -> Printf.printf "option: None\n"

(* Test result type *)
let test_result () =
  let ok_val : (int, string) result = Ok 42 in
  let err_val : (int, string) result = Error "failed" in
  match ok_val with
  | Ok x -> Printf.printf "result: Ok %d\n" x
  | Error _ -> Printf.printf "result: Error\n"

let () =
  test_int_int_tuple ();
  test_int_float_tuple ();
  test_float_float_tuple ();
  test_int_option ();
  test_option ();
  test_result ()
