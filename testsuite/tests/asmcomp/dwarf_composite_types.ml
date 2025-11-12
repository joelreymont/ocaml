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

(* Test 3-tuples *)
let test_3d_int () =
  let p : int * int * int = (1, 2, 3) in
  let (x, y, z) = p in
  Printf.printf "3d int: %d,%d,%d\n" x y z

let test_3d_float () =
  let p : float * float * float = (1.0, 2.0, 3.0) in
  let (x, y, z) = p in
  Printf.printf "3d float: %.1f,%.1f,%.1f\n" x y z

(* Test lists *)
let test_int_list () =
  let empty : int list = [] in
  let nonempty : int list = [10; 20; 30] in
  match nonempty with
  | [] -> Printf.printf "int list: empty\n"
  | h :: _ -> Printf.printf "int list: %d\n" h

(* Test references *)
let test_int_ref () =
  let r : int ref = ref 42 in
  Printf.printf "int ref: %d\n" !r

let test_string_ref () =
  let r : string ref = ref "hello" in
  Printf.printf "string ref: %s\n" !r

(* Test additional types *)
let test_float_list () =
  let l : float list = [1.5; 2.5] in
  match l with
  | [] -> Printf.printf "float list: empty\n"
  | h :: _ -> Printf.printf "float list: %.1f\n" h

let test_char_option () =
  let o : char option = Some 'x' in
  match o with
  | None -> Printf.printf "char option: None\n"
  | Some c -> Printf.printf "char option: %c\n" c

let test_string_int () =
  let p : string * int = ("key", 42) in
  let (s, i) = p in
  Printf.printf "string*int: %s,%d\n" s i

let test_string_string () =
  let p : string * string = ("a", "b") in
  let (s1, s2) = p in
  Printf.printf "string*string: %s,%s\n" s1 s2

let test_4tuple () =
  let t : int * int * int * int = (1, 2, 3, 4) in
  let (a, b, c, d) = t in
  Printf.printf "4tuple: %d,%d,%d,%d\n" a b c d

let () =
  test_int_int_tuple ();
  test_int_float_tuple ();
  test_float_float_tuple ();
  test_int_option ();
  test_option ();
  test_result ();
  test_3d_int ();
  test_3d_float ();
  test_int_list ();
  test_int_ref ();
  test_string_ref ();
  test_float_list ();
  test_char_option ();
  test_string_int ();
  test_string_string ();
  test_4tuple ()
