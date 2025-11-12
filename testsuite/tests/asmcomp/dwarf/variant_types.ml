(* TEST
 native;
 set OCAMLPARAM = "dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test variant type definitions *)

type color = Red | Green | Blue | RGB of int * int * int

type shape =
  | Circle of float
  | Rectangle of float * float
  | Triangle of float * float * float

let area = function
  | Circle r -> 3.14 *. r *. r
  | Rectangle (w, h) -> w *. h
  | Triangle (a, b, c) ->
      let s = (a +. b +. c) /. 2.0 in
      sqrt (s *. (s -. a) *. (s -. b) *. (s -. c))

let color_to_int = function
  | Red -> 1
  | Green -> 2
  | Blue -> 3
  | RGB (r, g, b) -> r + g + b

let () =
  let c = Circle 5.0 in
  let r = Rectangle (10.0, 20.0) in
  Printf.printf "%.0f %.0f %d\n" (area c) (area r) (color_to_int (RGB (10, 20, 30)))
