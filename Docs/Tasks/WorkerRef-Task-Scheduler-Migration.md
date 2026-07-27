# WorkerRef and Task Scheduler Migration

Status: In progress

## Objective

Replace the process/path-based compiler module worker queue with the canonical
AiLang worker facility:

```text
std.worker.run(workerRef,payloadBytes) -> Task | Err
task.then(workerRef) -> Task
tasks.whenAll() -> Task
tasks.whenAny() -> Task
Await { task } -> bytes | Err
std.task.cancel(task) -> bool
```

AiLang owns logical workloads, dependencies, canonical indexes, record schemas,
validation, diagnostics, and linking. AiVM owns only bounded physical execution,
isolation, dispatch, buffering, cancellation, resource limits, and cleanup.

## Completed

- Replaced the normative string-name/integer-handle worker contract.
- Specified source-owned structural Worker declarations and generated catalogs.
- Specified opaque Task, WorkerRef, WorkerTasks, lazy workloads, dependencies,
  backpressure, and canonical indexed observation.
- Removed the fixed four-job self-host default. Automatic bootstrap execution
  now targets 96 percent of detected logical CPUs, with an optional explicit
  profile ceiling.
- Added AiVM mechanical CPU-capacity discovery and focused tests.
- Added the opaque non-comparable/non-transportable AiVM Task value.
- Updated `ASYNC_CALL`, `ASYNC_CALL_SYS`, `AWAIT`, and `PAR_JOIN` to use opaque
  Task values rather than integer handles.
- Added stable consumed-task tombstones for live aliases.
- Removed `sys.worker.start/poll/result/error/cancel` from the normative syscall
  contract table.

## Remaining

1. Add structural `Worker` and `Function(target=...)` validation and package
   export references.
2. Add deterministic AiBCO worker relocations and AiBC1 WorkerCatalog encoding.
3. Add loader validation and opaque WorkerRef values.
4. Implement the bounded lazy VM scheduler and isolated `Fn(bytes) -> bytes`
   invocation source.
5. Implement general Task cancellation and dependency state.
6. Implement `run`, `runAll`, `taskAt`, `then`, `whenAll`, and operational
   `whenAny` bytecode operations.
7. Add modular `src/std/worker.aos` and `src/std/task.aos` facades.
8. Complete self-hosted lowering for Worker declarations, WorkerRef values,
   Task locals, combinators, and Await.
9. Change the module worker to emit compact linker-ready records.
10. Submit the canonical module workload through `std.worker.runAll`, Await and
    commit by canonical module index, and remove process-path worker selection
    and serial `.aibco` reload from the hot path.

## Acceptance Criteria

- Relocation and current working directory cannot affect worker selection.
- Embedded artifact substitution or corruption is rejected before execution.
- Worker functions are validated as exported `Fn(bytes) -> bytes`.
- Each invocation receives fresh mutable VM state.
- Active execution derives from CPU/container and memory capacity, bounded by
  runtime profile; no fixed four-worker default remains.
- Logical workloads larger than pending materialization remain bounded and do
  not require caller refill.
- Task forgery, equality, serialization, and transport are rejected.
- First Await consumes; repeated aliases receive `TASK_CONSUMED`.
- Completion and failure permutations produce byte-identical `.aibc1` and
  identical canonical diagnostics.
- Operational abort cannot commit final output.
- Clean self-host, AiVectra, and Weather validation pass.
