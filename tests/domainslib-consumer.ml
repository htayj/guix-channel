(* Compiled outside the checkout against the installed native findlib library. *)
module T = Domainslib.Task
module C = Domainslib.Chan

exception Task_failure of int ref

let check condition message = if not condition then failwith message

let rec sequential_fib n =
  if n < 2 then n else sequential_fib (n - 1) + sequential_fib (n - 2)

let rec parallel_fib pool n =
  if n < 20 then sequential_fib n
  else
    let left = T.async pool (fun () -> parallel_fib pool (n - 1)) in
    let right = parallel_fib pool (n - 2) in
    T.await pool left + right

let sequential_scan op input =
  let result = Array.copy input in
  for i = 1 to Array.length result - 1 do
    result.(i) <- op result.(i - 1) input.(i)
  done;
  result

let with_pool num_domains f =
  let pool = T.setup_pool ~num_domains () in
  Fun.protect ~finally:(fun () -> T.teardown_pool pool) (fun () -> f pool)

let check_channels pool =
  (* Channels block domains using condition variables.  A worker domain and
     the calling domain coordinate a synchronous, zero-buffer handoff. *)
  let rendezvous = C.make_bounded 0 in
  let sender = T.async pool (fun () -> C.send rendezvous 73; 91) in
  check (C.recv rendezvous = 73) "rendezvous payload";
  check (T.await pool sender = 91) "rendezvous sender completion";
  let bounded = C.make_bounded 1 in
  check (C.send_poll bounded 17) "bounded first send";
  check (not (C.send_poll bounded 99)) "bounded capacity";
  check (C.recv bounded = 17) "failed send must not replace payload";
  check (C.recv_poll bounded = None) "bounded drained";
  let unbounded = C.make_unbounded () in
  let producer = T.async pool (fun () ->
    for i = 1 to 1024 do C.send unbounded (i * i) done) in
  let total = ref 0 in
  for i = 1 to 1024 do
    let value = C.recv unbounded in
    check (value = i * i) "channel FIFO order";
    total := !total + value
  done;
  T.await pool producer;
  check (C.recv_poll unbounded = None) "unbounded drained";
  check (!total = 358438400) "channel sum-of-squares oracle";
  !total

let () =
  Printexc.record_backtrace true;
  (match T.setup_pool ~num_domains:(-1) () with
   | pool -> T.teardown_pool pool; failwith "negative domain count accepted"
   | exception Invalid_argument _ -> ());
  (match C.make_bounded (-1) with
   | _ -> failwith "negative channel capacity accepted"
   | exception Invalid_argument _ -> ());
  let fib, reduction, channels = with_pool 2 (fun pool ->
    check (T.get_num_domains pool = 3) "pool domain count";
    T.run pool (fun () ->
      (* Two simultaneously active tasks prove this is a multicore pool,
         rather than a serial implementation that merely returns correct sums. *)
      let arrived = Atomic.make 0 in
      let rendezvous_task () =
        ignore (Atomic.fetch_and_add arrived 1);
        while Atomic.get arrived < 2 do Domain.cpu_relax () done;
        Domain.self ()
      in
      let first = T.async pool rendezvous_task in
      let second = T.async pool rendezvous_task in
      let first_id = T.await pool first in
      let second_id = T.await pool second in
      check (first_id <> second_id) "tasks did not execute concurrently";
      let fib = parallel_fib pool 28 in
      check (fib = sequential_fib 28) "parallel Fibonacci oracle";
      let visits = Array.init 4096 (fun _ -> Atomic.make 0) in
      let values = Array.make 4096 0 in
      let fill i =
        ignore (Atomic.fetch_and_add visits.(i) 1);
        values.(i) <- (i * i) - (3 * i) + 7
      in
      T.parallel_for ~start:0 ~finish:4095 ~body:fill pool;
      Array.iteri (fun i visits ->
        check (Atomic.get visits = 1) "default chunk visited an index twice";
        check (values.(i) = (i * i) - (3 * i) + 7) "parallel array oracle") visits;
      T.parallel_for ~chunk_size:1 ~start:0 ~finish:4095 ~body:fill pool;
      Array.iter (fun visits ->
        check (Atomic.get visits = 2) "unit chunk missed or repeated an index") visits;
      let reduction = T.parallel_for_reduce ~start:1 ~finish:1000
          ~body:Fun.id pool ( + ) 0 in
      check (reduction = 1000 * 1001 / 2) "reduction arithmetic oracle";
      check (T.parallel_for_reduce ~start:5 ~finish:4 ~body:Fun.id
               pool ( + ) 123 = 123) "empty reduction identity";
      let numbers = Array.init 257 (fun i -> (i mod 11) - 5) in
      check (T.parallel_scan pool ( + ) numbers = sequential_scan ( + ) numbers)
        "integer scan oracle";
      let strings = Array.init 37 (fun i -> Printf.sprintf "[%d]" i) in
      check (T.parallel_scan pool ( ^ ) strings = sequential_scan ( ^ ) strings)
        "noncommutative scan oracle";
      check (T.parallel_scan pool ( + ) [||] = [||]) "empty scan";
      check (T.parallel_scan pool ( + ) [|41|] = [|41|]) "singleton scan";
      check (T.parallel_find ~start:0 ~finish:4095
               ~body:(fun i -> if i = 1234 then Some (i * i) else None) pool
             = Some (1234 * 1234)) "parallel search unique match";
      check (T.parallel_find ~start:0 ~finish:31 ~body:(fun _ -> None) pool
             = None) "parallel search missing match";
      let payload = ref 42 in
      let original = Task_failure payload in
      let failed = T.async pool (fun () -> raise original) in
      (match T.await pool failed with
       | _ -> failwith "await swallowed exception"
       | exception exn -> check (exn == original) "await changed exception identity");
      (* Reuse after a failed promise checks scheduler recovery as well. *)
      check (T.await pool (T.async pool (fun () -> 47)) = 47)
        "pool unusable after exception";
      fib, reduction, check_channels pool)) in
  with_pool 0 (fun pool ->
    check (T.get_num_domains pool = 1) "empty pool domain count";
    T.run pool (fun () ->
      check (parallel_fib pool 22 = sequential_fib 22) "sequential pool fallback";
      check (T.parallel_for_reduce ~start:1 ~finish:1000 ~body:Fun.id
               pool ( + ) 0 = reduction) "sequential reduction oracle"));
  Printf.printf "fib=%d reduction=%d channel=%d\ndomainslib consumer passed\n"
    fib reduction channels
