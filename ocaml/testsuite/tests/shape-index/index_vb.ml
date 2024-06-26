(* TEST
 flags = "-bin-annot -bin-annot-occurrences";
 compile_only = "true";
 readonly_files = "index_vb.ml";
 all_modules = "index_vb.ml";
 setup-ocamlc.byte-build-env;
 ocamlc.byte;
 program = "-quiet -index -decls index_vb.cmt";
 output = "out_objinfo";
 check-ocamlc.byte-output;
 ocamlobjinfo;
 check-program-output;
*)

type t = { a : int; b : string * int }

let { a; b = (c, d) } = { a = 42; b = ("", 4) }

let () = print_int (a + d * (int_of_string c))
