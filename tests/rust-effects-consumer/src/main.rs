use rust_effects::typeclasses::free_effect::{FreeEffect, free::new_free};
use rust_effects::types::cfuture::CFuture;
use parking_lot::Mutex;
use std::sync::Arc;
use std::time::Duration;

type Trace = Arc<Mutex<Vec<String>>>;

fn record(trace: &Trace, event: impl Into<String>) {
    trace.lock().push(event.into());
}

fn events(trace: &Trace) -> Vec<String> {
    trace.lock().clone()
}

#[derive(Clone)]
enum Operation {
    Add(i32, i32),
    Multiply(i32, i32),
}

// Interpretation is an actual externally defined effect, not a plain fmap.
struct ArithmeticEffect {
    trace: Trace,
}

impl FreeEffect for ArithmeticEffect {
    type In = Vec<Operation>;
    type Out = Vec<i32>;

    fn fold(&self, source: Self::In) -> Self::Out {
        source.into_iter().map(|operation| match operation {
            Operation::Add(left, right) => {
                record(&self.trace, format!("dispatch:add:{left}:{right}"));
                left + right
            }
            Operation::Multiply(left, right) => {
                record(&self.trace, format!("dispatch:multiply:{left}:{right}"));
                left * right
            }
        }).collect()
    }
}

fn dispatch() {
    let trace = Trace::default();
    let bind_trace = trace.clone();
    let map_trace = trace.clone();
    let program = new_free::<Vec<Operation>>()
        .add_eff(ArithmeticEffect { trace: trace.clone() })
        .free_bind(move |value: i32| {
            record(&bind_trace, format!("bind:{value}"));
            if value % 2 == 0 { vec![value] } else { vec![] }
        })
        .free_map(move |value: i32| {
            record(&map_trace, format!("map:{value}"));
            value / 2
        });
    assert!(events(&trace).is_empty(), "composition must not dispatch");
    let result: Vec<i32> = program.fold_map(vec![
        Operation::Add(1, 2), Operation::Multiply(3, 4), Operation::Add(8, 2),
    ]);
    assert_eq!(result, vec![6, 5]);
    assert_eq!(events(&trace), [
        "dispatch:add:1:2", "dispatch:multiply:3:4", "dispatch:add:8:2",
        "bind:3", "bind:12", "bind:10", "map:12", "map:10",
    ]);
    println!("{{\"case\":\"custom-effect-dispatch\",\"result\":{result:?},\"trace\":{:?}}}", events(&trace));
}

fn short_circuit_and_map() {
    let trace = Trace::default();
    let bind_trace = trace.clone();
    let map_trace = trace.clone();
    let program = new_free::<Option<i32>>()
        .free_bind(move |value: i32| -> Option<i32> {
            record(&bind_trace, format!("reject:{value}"));
            None
        })
        .free_map(move |value: i32| {
            record(&map_trace, "unexpected:map");
            value + 1
        });
    let result: Option<i32> = program.fold_map(Some(9));
    assert_eq!(result, None);
    assert_eq!(events(&trace), ["reject:9"]);
    let empty: Option<i32> = program.fold_map(None);
    assert_eq!(empty, None);
    assert_eq!(events(&trace), ["reject:9"], "None must bypass closures");
    println!("{{\"case\":\"short-circuit\",\"result\":null,\"trace\":{:?}}}", events(&trace));

    let map_only = new_free::<Vec<i32>>().free_map(|value: i32| value * 2);
    let result: Vec<i32> = map_only.fold_map(vec![2, 3]);
    assert_eq!(result, vec![4, 6]);
    println!("{{\"case\":\"map-only\",\"result\":{result:?}}}");
}

struct AsyncEffect {
    trace: Trace,
}

impl FreeEffect for AsyncEffect {
    type In = CFuture<i32>;
    type Out = CFuture<i32>;

    fn fold(&self, source: Self::In) -> Self::Out {
        record(&self.trace, "async:fold");
        let trace = self.trace.clone();
        CFuture::new(async move {
            let value = source.await;
            record(&trace, format!("async:start:{value}"));
            // A real timer yields Pending before completing; this tests the
            // shared boxed Future implementation, not only lazy ready values.
            tokio::time::sleep(Duration::from_millis(10)).await;
            record(&trace, "async:complete");
            value + 1
        })
    }
}

async fn async_completion() {
    let trace = Trace::default();
    let bind_trace = trace.clone();
    let map_trace = trace.clone();
    let program = new_free::<CFuture<i32>>()
        .add_eff(AsyncEffect { trace: trace.clone() })
        .free_bind(move |value: i32| {
            let trace = bind_trace.clone();
            CFuture::new(async move {
                tokio::task::yield_now().await;
                record(&trace, format!("async:bind:{value}"));
                value * 3
            })
        })
        .free_map(move |value: i32| {
            record(&map_trace, format!("async:map:{value}"));
            value + 2
        });
    assert!(events(&trace).is_empty());
    let result: CFuture<i32> = program.fold_map(CFuture::lazy(7));
    assert_eq!(events(&trace), ["async:fold"], "fold must leave futures lazy");
    let shared = result.clone();
    let value = tokio::time::timeout(Duration::from_secs(2), result).await.unwrap();
    assert_eq!(value, 26);
    assert_eq!(events(&trace), [
        "async:fold", "async:start:7", "async:complete", "async:bind:8", "async:map:24",
    ]);
    assert_eq!(shared.await, 26);
    assert_eq!(events(&trace).len(), 5, "cloned shared completion must not rerun effects");
    println!("{{\"case\":\"cfuture-completion\",\"result\":{value},\"shared_result\":26,\"trace\":{:?}}}", events(&trace));
}

fn main() {
    dispatch();
    short_circuit_and_map();
    tokio::runtime::Builder::new_current_thread().enable_time().build()
        .unwrap().block_on(async_completion());
    println!("RUST_EFFECTS_NATIVE_RUNTIME_OK");
}
