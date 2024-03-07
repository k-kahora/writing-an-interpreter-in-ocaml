type parser = {l: Lexer.lexer; curToken: Token.token; peekToken: Token.token}

let print_parser (p : parser) : unit =
  Format.printf "Current Token: %s \n"
    (Token.token_to_string_debug p.curToken.type') ;
  Format.printf "Peek token: %s \n"
    (Token.token_to_string_debug p.peekToken.type')

let next_token (p : parser) : parser =
  let nextToken, l = Lexer.next_token p.l in
  (* Format.printf "Next Token: %s \n" *)
  (* Token.token_to_string_debug nextToken.type' ; *)
  {curToken= p.peekToken; peekToken= nextToken; l}

let new_parser (l : Lexer.lexer) : parser =
  let curToken, cur = Lexer.next_token l in
  let peekToken, l = Lexer.next_token cur in
  {l; curToken; peekToken}

module type Monad = sig
  type 'a t

  val return : 'a -> 'a t

  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
end

module Maybe : Monad = struct
  type 'a t = 'a option

  let return x = Some x

  let ( >>= ) m f = match m with None -> None | Some x -> f x
end

let cur_token_is (p : parser) (t : Token.token_name) : bool =
  p.curToken.type' = t

let peek_token_is (p : parser) (t : Token.token_name) : bool =
  p.peekToken.type' = t

let expect_peek (p : parser) (t : Token.token_name) : parser option =
  let b = peek_token_is p t in
  let p = if b then Some (next_token p) else None in
  p

(* all the bindings will fail if the incorrect token is found *)
let parse_let_statement (p : parser) : Ast.statement * parser =
  let stmt =
    Ast.Letstatement
      {token= p.curToken; name= {token= p.curToken; value= "null"}}
  in
  let ( >>= ) option f = match option with Some x -> f x | None -> None in
  (* First check for the ident token *)
  let last_token = Some p >>= fun ft -> expect_peek ft Token.IDENT in
  (* Set statement name = to the current token *)
  let stmt =
    match stmt with
    | Ast.Letstatement st ->
        Ast.Letstatement
          { st with
            name=
              { token= (Option.get last_token).curToken
              ; value= (Option.get last_token).curToken.literal } }
  in
  (* check for the ASSIGN token *)
  let last_token = last_token >>= fun nt -> expect_peek nt Token.ASSIGN in
  let rec looper nxt =
    match nxt with
    | pst when cur_token_is pst Token.SEMICOLON ->
        nxt
    | _ ->
        looper (next_token nxt)
  in
  (stmt, looper @@ Option.get last_token)
(* Ast.new_let_satement () *)

let parse_statement (p : parser) : (Ast.statement * parser) option =
  match p.curToken.type' with
  | Token.LET ->
      Some (parse_let_statement p)
  | _ ->
      None

let parse_program (p : parser) : Ast.program =
  (* Parse each token until there is a EOF token *)
  let rec looper acc p =
    match p.curToken.type' with
    | Token.EOF ->
        acc
    | _ -> (
      match parse_statement p with
      | None ->
          looper acc (next_token p)
      | Some (stmt, p) ->
          looper (stmt :: acc) (next_token p) )
  in
  let d_stms = looper [] p in
  let _ = List.iter Ast.print_statement d_stms in
  {Ast.statements= List.rev d_stms}