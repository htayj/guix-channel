(* A consumer of installed public APIs, compiled only in disposable smoke scratch. *)
open Notty

let require condition message = if not condition then failwith message
let dimensions image = (I.width image, I.height image)

let overlay = I.((void 2 0 <|> string A.(fg cyan) "TOP") </> string A.empty "abcdefg")
let cropped = I.hcrop 1 2 (I.string A.empty "abcdef")
let unicode = I.string A.empty "界é"
let colors =
  I.(string A.(fg red ++ bg blue ++ st bold) "RED" <|> void 1 0
     <|> string A.(fg (rgb ~r:5 ~g:0 ~b:0)) "CUBE" <|> void 1 0
     <|> string A.(fg (rgb_888 ~r:18 ~g:52 ~b:86)) "TRUE" <|> void 1 0
     <|> string A.(fg (gray 12)) "GRAY")

let core () =
  let horizontal = I.(char A.empty 'a' 2 3 <|> char A.empty 'b' 4 1) in
  let vertical = I.(char A.empty 'a' 2 3 <-> char A.empty 'b' 4 1) in
  require (dimensions horizontal = (6, 3)) "horizontal image geometry";
  require (dimensions vertical = (4, 4)) "vertical image geometry";
  require (dimensions overlay = (7, 1)) "transparent overlay geometry";
  require (dimensions cropped = (3, 1)) "crop geometry";
  require (dimensions (I.hcrop (-2) (-1) cropped) = (6, 1)) "padding geometry";
  require (dimensions unicode = (3, 1)) "Unicode cell width";
  require (dimensions colors = (18, 1)) "color image geometry";
  require A.(equal (fg red ++ bg blue ++ st bold)
                   (st bold ++ bg blue ++ fg red)) "attribute composition";
  require A.(equal (fg green ++ fg red) (fg red)) "foreground precedence"

let scene backend size inputs state =
  let w, h = size in
  I.(string A.empty ("NOTTY " ^ String.uppercase_ascii backend)
     <-> colors <-> overlay <-> cropped <-> unicode
     <-> string A.empty (Printf.sprintf "SIZE %dx%d" w h)
     <-> string A.empty ("EVENTS " ^ String.concat " " inputs)
     <-> string A.empty ("STATE " ^ state))

let key = function
  | `Key (`Arrow `Up, []) -> "UP"
  | `Key (`Arrow `Down, []) -> "DOWN"
  | `Key (`Arrow `Left, []) -> "LEFT"
  | `Key (`Arrow `Right, []) -> "RIGHT"
  | `Key (`ASCII 'x', []) -> "x"
  | `Key (`ASCII 'q', []) -> "q"
  | _ -> failwith "unexpected terminal input event"

let report path backend size inputs restored =
  require (inputs = ["UP"; "DOWN"; "LEFT"; "RIGHT"; "x"; "q"])
    "ordered arrow and ASCII input decoding";
  require (size = (52, 16)) "terminal resize not observed";
  require restored "terminal attributes not restored";
  let channel = open_out path in
  Fun.protect ~finally:(fun () -> close_out channel) (fun () ->
    Printf.fprintf channel
      "{\"backend\":\"%s\",\"size\":[%d,%d],\"inputs\":[%s],\"termios_restored\":%b,\"geometry\":{\"horizontal\":[6,3],\"vertical\":[4,4],\"overlay\":[7,1],\"crop\":[3,1],\"pad\":[6,1],\"unicode\":[3,1],\"colors\":[18,1]}}\n"
      backend (fst size) (snd size)
      (String.concat "," (List.map (Printf.sprintf "\"%s\"") inputs)) restored)

let unix path =
  let module T = Notty_unix.Term in
  let original = Unix.tcgetattr Unix.stdin in
  let t = T.create ~dispose:false ~mouse:false ~bpaste:false () in
  let inputs = ref [] and size = ref (T.size t) in
  Fun.protect ~finally:(fun () -> T.release t) (fun () ->
    require (!size = (40, 12)) "Unix initial terminal dimensions";
    require (Notty_unix.winsize Unix.stdout = Some !size) "Unix winsize";
    T.image t (scene "unix" !size !inputs "ready");
    let rec loop () =
      match T.event t with
      | `Resize dimensions ->
          size := dimensions;
          require (T.size t = dimensions) "Unix resized dimensions";
          T.image t (scene "unix" !size !inputs "resized"); loop ()
      | `End -> failwith "Unix input ended prematurely"
      | #Unescape.event as event ->
          let decoded = key event in
          inputs := !inputs @ [decoded];
          if decoded <> "q" then (
            T.image t (scene "unix" !size !inputs "input"); loop ())
    in loop ());
  report path "unix" !size !inputs (Unix.tcgetattr Unix.stdin = original)

let lwt path =
  let module T = Notty_lwt.Term in
  let open Lwt.Infix in
  let original = Unix.tcgetattr Unix.stdin in
  let inputs = ref [] and size = ref (0, 0) in
  Lwt_main.run (
    let t = T.create ~dispose:false ~mouse:false ~bpaste:false () in
    let events = T.events t in
    let draw state =
      T.image t (scene "lwt" !size !inputs state) >>= fun () -> Lwt_io.flush_all ()
    in
    Lwt.finalize (fun () ->
      size := T.size t;
      require (!size = (40, 12)) "Lwt initial terminal dimensions";
      require (Notty_lwt.winsize Lwt_unix.stdout = Some !size) "Lwt winsize";
      draw "ready" >>= fun () ->
      let rec loop () =
        Lwt_stream.get events >>= function
        | None -> Lwt.fail_with "Lwt input ended prematurely"
        | Some (`Resize dimensions) ->
            size := dimensions;
            require (T.size t = dimensions) "Lwt resized dimensions";
            draw "resized" >>= loop
        | Some (#Unescape.event as event) ->
            let decoded = key event in
            inputs := !inputs @ [decoded];
            if decoded = "q" then Lwt.return_unit else draw "input" >>= loop
      in loop ())
      (fun () ->
        T.release t >>= fun () ->
        (* Drain the public stream so its input cleanup runs before inspection. *)
        Lwt_stream.iter (fun _ -> ()) events >>= fun () -> Lwt.pause ()));
  report path "lwt" !size !inputs (Unix.tcgetattr Unix.stdin = original)

let () =
  core ();
  match Sys.argv.(1) with
  | "unix" -> unix Sys.argv.(2)
  | "lwt" -> lwt Sys.argv.(2)
  | _ -> failwith "expected unix or lwt backend"
