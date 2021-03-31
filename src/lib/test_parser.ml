(* Test syntax analyser *)

module L = Lexing

let check str =
  let lexbuf = L.from_string str in
  try
    let ast = Parser.program Lexer.token lexbuf in
    let tree = Absyntree.flat_nodes (Absyntree.tree_of_lfundecs ast) in
    let box = Tree.box_of_tree tree in
    Format.printf "%s\n\n%!" (Box.string_of_box box);
  with
  | Parser.Error ->
     Format.printf "%a error: syntax\n%!" Location.pp_position lexbuf.L.lex_curr_p
  | Error.Error (loc, msg) ->
     Format.printf "%a error: %s%!" Location.pp_location loc msg

let%expect_test _ =
  (* function declaration and constant expression *)
  check "int f(int x) = 100";
  [%expect{|
                 ╭───────╮
                 │Program│
                 ╰────┬──╯
                   ╭──┴╮
                   │Fun│
                   ╰──┬╯
         ╭───────────┬┴───────────╮
    ╭────┴────╮  ╭───┴───╮  ╭─────┴────╮
    │    f    │  │Formals│  │IntExp 100│
    │Absyn.Int│  ╰───┬───╯  ╰──────────╯
    ╰─────────╯ ╭────┴────╮
                │    x    │
                │Absyn.Int│
                ╰─────────╯ |}];

  check "int f(int x, int y, bool z) = 100";
  [%expect{|
                              ╭───────╮
                              │Program│
                              ╰───┬───╯
                                ╭─┴─╮
                                │Fun│
                                ╰─┬─╯
         ╭────────────────────────┴────────────────────────╮
    ╭────┴────╮              ╭────┴──╮               ╭─────┴────╮
    │    f    │              │Formals│               │IntExp 100│
    │Absyn.Int│              ╰────┬──╯               ╰──────────╯
    ╰─────────╯      ╭───────────┬┴───────────╮
                ╭────┴────╮ ╭────┴────╮ ╭─────┴────╮
                │    x    │ │    y    │ │    z     │
                │Absyn.Int│ │Absyn.Int│ │Absyn.Bool│
                ╰─────────╯ ╰─────────╯ ╰──────────╯ |}];

  check "int f() = 100";
  [%expect{| :1.7 error: syntax |}];

  check "foo f(int x) = 100";
  [%expect{| :1.3 error: syntax |}];

  (* binary operators *)
  check "bool f(int x) = 2 + 3 + 4 < 5 + 6";
  [%expect{|
                                       ╭───────╮
                                       │Program│
                                       ╰───┬───╯
                                         ╭─┴─╮
                                         │Fun│
                                         ╰─┬─╯
          ╭───────────┬────────────────────┴────────────╮
    ╭─────┴────╮  ╭───┴───╮                        ╭────┴──╮
    │    f     │  │Formals│                        │OpExp <│
    │Absyn.Bool│  ╰───┬───╯                        ╰────┬──╯
    ╰──────────╯ ╭────┴────╮                 ╭──────────┴───────────────╮
                 │    x    │            ╭────┴──╮                   ╭───┴───╮
                 │Absyn.Int│            │OpExp +│                   │OpExp +│
                 ╰─────────╯            ╰────┬──╯                   ╰───┬───╯
                                       ╭─────┴──────────╮          ╭────┴─────╮
                                   ╭───┴───╮       ╭────┴───╮ ╭────┴───╮ ╭────┴───╮
                                   │OpExp +│       │IntExp 4│ │IntExp 5│ │IntExp 6│
                                   ╰───┬───╯       ╰────────╯ ╰────────╯ ╰────────╯
                                  ╭────┴─────╮
                             ╭────┴───╮ ╭────┴───╮
                             │IntExp 2│ │IntExp 3│
                             ╰────────╯ ╰────────╯ |}];

  check "bool f(int x) = 2 < 3 < 4";
  [%expect{| :1.23 error: syntax |}];

  (* if then else expression *)
  check "int f(int x) = if 4 < 5 then 5 else 4";
  [%expect{|
                                 ╭───────╮
                                 │Program│
                                 ╰───┬───╯
                                   ╭─┴─╮
                                   │Fun│
                                   ╰─┬─╯
         ╭───────────┬───────────────┴───────────╮
    ╭────┴────╮  ╭───┴───╮              ╭────────┴────────╮
    │    f    │  │Formals│              │ConditionalExp if│
    │Absyn.Int│  ╰───┬───╯              ╰────────┬────────╯
    ╰─────────╯ ╭────┴────╮           ╭──────────┴─────┬──────────╮
                │    x    │       ╭───┴───╮       ╭────┴───╮ ╭────┴───╮
                │Absyn.Int│       │OpExp <│       │IntExp 5│ │IntExp 4│
                ╰─────────╯       ╰───┬───╯       ╰────────╯ ╰────────╯
                                 ╭────┴─────╮
                            ╭────┴───╮ ╭────┴───╮
                            │IntExp 4│ │IntExp 5│
                            ╰────────╯ ╰────────╯ |}];       

(* id expression *)
check "int f(int x) = x";
[%expect{|
              ╭───────╮
              │Program│
              ╰───┬───╯
                ╭─┴─╮
                │Fun│
                ╰─┬─╯
       ╭──────────┴┬──────────╮
  ╭────┴────╮  ╭───┴───╮  ╭───┴───╮
  │    f    │  │Formals│  │IdExp x│
  │Absyn.Int│  ╰───┬───╯  ╰───────╯
  ╰─────────╯ ╭────┴────╮
              │    x    │
              │Absyn.Int│
              ╰─────────╯ |}];

  (* let in expression *)
  (* check "int f(int x) = let var = 3 in var + 3" *)
  (* NOT EXPECTED RESULT YET - restudy case and check if example is right on parser.mly later *)

(* id list of expressions - functions call*)
check "int f(int x) = x (1 + 3 + 4, 5 < 4)";
[%expect{|
                                    ╭───────╮
                                    │Program│
                                    ╰────┬──╯
                                      ╭──┴╮
                                      │Fun│
                                      ╰──┬╯
       ╭───────────┬─────────────────────┴───────────╮
  ╭────┴────╮  ╭───┴───╮                      ╭──────┴─────╮
  │    f    │  │Formals│                      │FunctionsExp│
  │Absyn.Int│  ╰───┬───╯                      ╰──────┬─────╯
  ╰─────────╯ ╭────┴────╮                 ╭──────────┴───────────────╮
              │    x    │            ╭────┴──╮                   ╭───┴───╮
              │Absyn.Int│            │OpExp +│                   │OpExp <│
              ╰─────────╯            ╰────┬──╯                   ╰───┬───╯
                                    ╭─────┴──────────╮          ╭────┴─────╮
                                ╭───┴───╮       ╭────┴───╮ ╭────┴───╮ ╭────┴───╮
                                │OpExp +│       │IntExp 4│ │IntExp 5│ │IntExp 4│
                                ╰───┬───╯       ╰────────╯ ╰────────╯ ╰────────╯
                               ╭────┴─────╮
                          ╭────┴───╮ ╭────┴───╮
                          │IntExp 1│ │IntExp 3│
                          ╰────────╯ ╰────────╯ |}];

(* program *)
check "int f(int x) = x (1 + 3 + 4, 5 < 4)\nint f(int x) = if 4 < 5 then 5 else 4";
[%expect{|
                                                                      ╭───────╮
                                                                      │Program│
                                                                      ╰────┬──╯
                                         ╭─────────────────────────────────┴──────────────────────────────────────╮
                                      ╭──┴╮                                                                     ╭─┴─╮
                                      │Fun│                                                                     │Fun│
                                      ╰──┬╯                                                                     ╰─┬─╯
       ╭───────────┬─────────────────────┴───────────╮                                ╭───────────┬───────────────┴───────────╮
  ╭────┴────╮  ╭───┴───╮                      ╭──────┴─────╮                     ╭────┴────╮  ╭───┴───╮              ╭────────┴────────╮
  │    f    │  │Formals│                      │FunctionsExp│                     │    f    │  │Formals│              │ConditionalExp if│
  │Absyn.Int│  ╰───┬───╯                      ╰──────┬─────╯                     │Absyn.Int│  ╰───┬───╯              ╰────────┬────────╯
  ╰─────────╯ ╭────┴────╮                 ╭──────────┴───────────────╮           ╰─────────╯ ╭────┴────╮           ╭──────────┴─────┬──────────╮
              │    x    │            ╭────┴──╮                   ╭───┴───╮                   │    x    │       ╭───┴───╮       ╭────┴───╮ ╭────┴───╮
              │Absyn.Int│            │OpExp +│                   │OpExp <│                   │Absyn.Int│       │OpExp <│       │IntExp 5│ │IntExp 4│
              ╰─────────╯            ╰────┬──╯                   ╰───┬───╯                   ╰─────────╯       ╰───┬───╯       ╰────────╯ ╰────────╯
                                    ╭─────┴──────────╮          ╭────┴─────╮                                  ╭────┴─────╮
                                ╭───┴───╮       ╭────┴───╮ ╭────┴───╮ ╭────┴───╮                         ╭────┴───╮ ╭────┴───╮
                                │OpExp +│       │IntExp 4│ │IntExp 5│ │IntExp 4│                         │IntExp 4│ │IntExp 5│
                                ╰───┬───╯       ╰────────╯ ╰────────╯ ╰────────╯                         ╰────────╯ ╰────────╯
                               ╭────┴─────╮
                          ╭────┴───╮ ╭────┴───╮
                          │IntExp 1│ │IntExp 3│
                          ╰────────╯ ╰────────╯ |}];