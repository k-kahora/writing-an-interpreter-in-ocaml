(* Build with `ocamlbuild -pkg alcotest simple.byte` *)
(* A module with functions to test *)

let test_statement () =
  let input = {|
   let x = 5;
   let y = 10;
   let foobar = 838383;
   |} in
  let tests = ["x"; "y"; "foobar"] in
  let l = Lexer.new' input in
  let p = Parser.new_parser l in
  let program = Parser.parse_program p in
  print_endline "here" ;
  Format.printf "Length: %s" (List.nth tests 1) ;
  if List.length program.statements <> 3 then failwith "not enought statements" ;
  let test_inputs stat actual =
    match stat with
    | Ast.Letstatement {name} ->
        Alcotest.(check string) "Check name" name.value actual
  in
  ignore (List.map2 test_inputs program.statements tests)

(* if List.length program.statements > 3 then *)
(*   failwith "To many statements produced" *)
(* else ignore 10 ignore 10 *)

let () =
  Alcotest.run "parser tests"
    [ ( "Let statements"
      , [Alcotest.test_case "Test the let statement" `Quick test_statement] ) ]