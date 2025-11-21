(* Test program for LLDB pretty-printing *)

type 'a tree =
  | Empty
  | Node of 'a * 'a tree * 'a tree

let empty_tree = Empty

let simple_tree = Node (5, Empty, Empty)

let complex_tree =
  Node (10,
    Node (5, Empty, Empty),
    Node (15, Empty, Empty))

let my_list = [1; 2; 3; 4; 5]

let empty_list = []

let nested_list = [[1; 2]; [3; 4]; [5]]

let my_option = Some 42

let none_option = None

let my_bool = true

let other_bool = false

let int_array = [|1; 2; 3; 4; 5|]

let float_array = [|1.5; 2.7; 3.14|]

let my_string = "hello world"

let my_tuple = (42, "answer")

(* Main function that we can set breakpoint on *)
let main () =
  Printf.printf "empty_tree: constructed\n";
  Printf.printf "simple_tree: constructed\n";
  Printf.printf "complex_tree: constructed\n";
  Printf.printf "Lists and options created\n";
  (* Breakpoint here to inspect variables *)
  ()

let () = main ()
