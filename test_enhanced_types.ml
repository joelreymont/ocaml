(* Test enhanced type information in DWARF *)

let test_int (x : int) = x + 1

let test_float (x : float) = x +. 1.0

let test_char (c : char) = Char.code c

let test_bool (b : bool) = if b then 1 else 0

let test_string (s : string) = String.length s

let test_unit () = ()

let test_mixed (i : int) (f : float) (c : char) (b : bool) (s : string) =
  Printf.printf "int=%d float=%f char=%c bool=%b string=%s\n"
    i f c b s

let () =
  test_mixed 42 3.14 'x' true "hello"
