(* This consumer is compiled outside the source tree against installed findlib
   libraries.  domains:0 means no worker domains, only the main domain. *)
exception Consumer_error of string

let check condition message = if not condition then failwith message

let check_ordering () =
  Miou.run ~domains:0 @@ fun () ->
  let order = ref [] in
  let record item = order := item :: !order in
  let child = Miou.async (fun () -> record "child"; 42) in
  record "parent";
  check (!order = [ "parent" ]) "async ran before the parent awaited";
  check (Miou.await child = Ok 42) "await lost its successful payload";
  check (List.rev !order = [ "parent"; "child" ]) "deferred async order";
  order := [];
  let child = Miou.async (fun () -> record "child"; 73) in
  Miou.yield ();
  record "parent";
  check (List.rev !order = [ "child"; "parent" ]) "yield did not run child first";
  check (Miou.await_exn child = 73) "await_exn lost its successful payload";
  let expected = Consumer_error "await payload" in
  let failed = Miou.async (fun () -> raise expected) in
  (match Miou.await failed with
  | Error actual -> check (actual == expected) "await changed its exception payload"
  | Ok _ -> failwith "await did not return Error");
  let expected = Consumer_error "await_exn payload" in
  let failed = Miou.async (fun () -> raise expected) in
  let caught =
    try ignore (Miou.await_exn failed); false
    with actual -> check (actual == expected) "await_exn changed the exception"; true
  in
  check caught "await_exn did not raise";
  let first = Miou.async (fun () -> 11) in
  let expected = Consumer_error "await_all payload" in
  let second = Miou.async (fun () -> raise expected) in
  let third = Miou.async (fun () -> 33) in
  (* Reverse the argument order relative to spawning, so completion order
     cannot accidentally satisfy the result ordering requirement. *)
  match Miou.await_all [ third; second; first ] with
  | [ Ok 33; Error actual; Ok 11 ] ->
      check (actual == expected) "await_all changed its error payload"
  | _ -> failwith "await_all did not preserve argument order"

let check_sleep () =
  Miou_unix.run ~domains:0 @@ fun () ->
  let awake = ref false in
  let sleeper = Miou.async (fun () -> Miou_unix.sleep 0.01; awake := true; "awake") in
  check (Miou.await sleeper = Ok "awake") "Unix sleep task failed";
  check !awake "Unix sleep did not resume"

let check_bitv () =
  let bits = Miou_bitv.create 17 false in
  check (Miou_bitv.length bits = 17) "Bitv length";
  check (Miou_bitv.next bits = Some 0) "empty Bitv next free bit";
  List.iter (fun i -> Miou_bitv.set bits i true) [ 0; 8; 16 ];
  check (Miou_bitv.get bits 8 && not (Miou_bitv.get bits 7)) "Bitv get/set";
  check (Miou_bitv.max bits = 17) "Bitv high bit";
  let set_bits = ref [] in
  Miou_bitv.iter (fun i -> set_bits := i :: !set_bits) bits;
  check (List.rev !set_bits = [ 0; 8; 16 ]) "Bitv iter or partial final byte";
  Miou_bitv.set bits 16 false;
  check (Miou_bitv.max bits = 9) "Bitv native clz stub";
  (* next finds the first unset bit without consuming it. *)
  check (Miou_bitv.next bits = Some 1) "Bitv native next stub";
  let full = Miou_bitv.create 17 true in
  check (Miou_bitv.next full = None) "full Bitv has a free bit";
  Miou_bitv.set full 16 false;
  check (Miou_bitv.next full = Some 16) "Bitv final-byte next"

let check_sync () =
  let module C = Miou_sync.Computation in
  let computation = C.create () in
  check (C.is_running computation) "new computation is not running";
  check (C.try_return computation 91) "computation could not return";
  check (not (C.try_return computation 12)) "computation completed twice";
  check (C.peek computation = Some (Ok 91)) "computation replaced its result";
  let trigger = Miou_sync.Trigger.create () in
  Miou_sync.Trigger.signal trigger;
  check (Miou_sync.Trigger.is_signaled trigger) "trigger signal transition";
  check (Miou_sync.Trigger.await trigger = None) "signaled trigger did not resume";
  let backoff = Miou_backoff.create ~lower_wait_log:0 ~upper_wait_log:1 () in
  let stepped = Miou_backoff.once backoff in
  check (Miou_backoff.reset stepped = backoff) "backoff reset"

let () =
  check (Sys.getenv_opt "MIOU_TRACE" = Some "1") "MIOU_TRACE must enable tracing";
  Runtime_events.start ();
  let cursor = Runtime_events.create_cursor None in
  let saw_spawn = ref false and saw_yield = ref false and saw_await = ref false in
  let callbacks =
    Miou_runtime_events.add_callbacks (Runtime_events.Callbacks.create ())
      ~fn:(fun _ _ event ->
        match event with
        | Miou.Trace.Spawn _ -> saw_spawn := true
        | Miou.Trace.Yield _ -> saw_yield := true
        | Miou.Trace.Await _ -> saw_await := true
        | _ -> ())
  in
  Miou.Trace.set_reporter Miou_runtime_events.reporter;
  Fun.protect ~finally:(fun () -> Runtime_events.free_cursor cursor) (fun () ->
    check_ordering ();
    check_sleep ();
    check_bitv ();
    check_sync ();
    ignore (Runtime_events.read_poll cursor callbacks None);
    check !saw_spawn "runtime event reporter emitted no Spawn";
    check !saw_yield "runtime event reporter emitted no Yield";
    check !saw_await "runtime event reporter emitted no Await");
  print_endline "miou consumer passed: ordering, results, exceptions, Unix sleep, Bitv, sync/backoff, runtime events"
