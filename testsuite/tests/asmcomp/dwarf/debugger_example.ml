(* Practical debugging example - demonstrates DWARF debugging features *)

type person = {
  name : string;
  age : int;
}

type result =
  | Success of int
  | Error of string

let make_person name age =
  { name; age }

let calculate_years_until_retirement person =
  let retirement_age = 65 in
  let years_left = retirement_age - person.age in
  if years_left < 0 then
    Error "Already retired"
  else if years_left = 0 then
    Error "Retirement age reached"
  else
    Success years_left

let process_people people =
  List.map (fun person ->
    match calculate_years_until_retirement person with
    | Success years ->
        Printf.sprintf "%s has %d years until retirement" person.name years
    | Error msg ->
        Printf.sprintf "%s: %s" person.name msg
  ) people

let main () =
  let people = [
    make_person "Alice" 30;
    make_person "Bob" 65;
    make_person "Charlie" 70;
    make_person "Diana" 45;
  ] in

  let results = process_people people in
  List.iter print_endline results

let () = main ()

(* DEBUGGING SESSION EXAMPLE:

   1. Compile with DWARF:
      export OCAMLPARAM="dwarf_fidelity=enhanced,_"
      ocamlopt -g -o debugger_example debugger_example.ml

   2. Start LLDB/GDB:
      lldb debugger_example
      OR
      gdb debugger_example

   3. Set breakpoint on main:
      (lldb) b camlDebugger_example__main_NNN
      (gdb) break camlDebugger_example__main_NNN

      (Find NNN with: nm debugger_example | grep main)

   4. Run and step:
      (lldb) r
      (lldb) step
      (lldb) next
      (lldb) list
      (lldb) bt

   5. Set breakpoint in calculate function:
      (lldb) b debugger_example.ml:18
      (lldb) c

   6. Inspect state:
      (lldb) frame variable
      (lldb) bt

   7. Continue to next breakpoint:
      (lldb) c

   Expected output:
   Alice has 35 years until retirement
   Bob: Retirement age reached
   Charlie: Already retired
   Diana has 20 years until retirement
*)
