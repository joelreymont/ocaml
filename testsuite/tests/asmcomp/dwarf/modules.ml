(* TEST
 native;
 env = "OCAMLPARAM=dwarf_fidelity=enhanced,_";
 flags = "-g";
*)

(* Test module debugging with DWARF *)

module M = struct
  type t = { value : int }
  let create x = { value = x }
  let get t = t.value
end

module type S = sig
  type t
  val add : t -> t -> t
end

module IntOps : S with type t = int = struct
  type t = int
  let add x y = x + y
end

let () =
  let m = M.create 42 in
  let sum = IntOps.add 10 20 in
  Printf.printf "%d %d\n" (M.get m) sum
