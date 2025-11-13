(* TEST
 native;
 
 flags = "-g -gdwarf-fidelity enhanced";
*)

(* Test record type definitions *)

type point = { x : int; y : int }

type rect = { top_left : point; bottom_right : point }

let make_point x y = { x; y }

let rect_area r =
  let w = r.bottom_right.x - r.top_left.x in
  let h = r.bottom_right.y - r.top_left.y in
  w * h

let () =
  let p1 = make_point 0 0 in
  let p2 = make_point 10 20 in
  let r = { top_left = p1; bottom_right = p2 } in
  print_int (rect_area r);
  print_newline ()
