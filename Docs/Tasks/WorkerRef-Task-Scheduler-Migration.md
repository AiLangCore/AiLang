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
- Added the modular AiVM WorkerCatalog loader and opaque WorkerRef value.
- WorkerCatalog entries now bind embedded artifact bytes, function target,
  transport ABI, bytecode version, and required capability mask under a
  deterministic content identity.
- Added loader rejection for artifact substitution, incompatible ABI,
  out-of-range function targets, malformed entries, and unsupported
  capabilities.
- Preserved immutable WorkerCatalog artifacts through module-cache copies.
- Added modular structural worker declaration validation under
  `src/compiler/workers/declarations.aos`.
- Added project-wide worker export collection and validation under
  `src/compiler/structural_project_workers.aos`.
- Serial structural project planning and AiBCO object emission now reject
  missing worker names, malformed Function children, missing targets,
  non-exported targets, and invalid transport arity before object emission.
- Required `sys.*` targets are collected in deterministic first-structural-use
  order for subsequent capability derivation.
- AiBCO object emission now supports canonical `WorkerDecl` metadata with
  `<modulePath>::worker::<name>` identity, resolved target symbol, and ordered
  `RequiredSyscall` children.
- Added a focused WorkerCatalog plan collector that merges declarations in
  canonical object order, assigns stable zero-based indexes, validates target
  function symbols, and rejects duplicate worker symbols.
- Added deterministic worker relocation-to-catalog-index resolution with stable
  missing-target diagnostics.
- Added modular capability-mask derivation from ordered required syscall
  metadata.
- Added a cross-runtime deterministic 32-byte worker artifact identity with
  matching AiLang emitter and AiVM loader goldens.
- Added binary WorkerCatalog section type `3` emission for function target,
  capability mask, bytes ABI, bytecode version, artifact length, identity, and
  exact bundled artifact bytes.
- Added stable rejection when catalog enrichment cannot find the declared
  bundled worker artifact.
- Added deterministic transitive function-closure discovery for worker targets.
  Closure membership follows resolved call relocations while artifact function
  order remains canonical global function order.
- Added isolated worker artifact construction with artifact-local entry offsets
  and transitive required-syscall collection.
- Added final three-section AiBC1 emission and wired the structural object-file
  linker to emit WorkerCatalog bundles when Worker declarations are present.
- Preserved byte-identical two-section output for projects with no workers.
- Added the modular AiVM bounded worker scheduler behind an internal mechanical
  API. Active slots and outstanding tasks are independently bounded.
- Made admission deterministic: background completion does not reclaim
  submission credit; owner-visible release does.
- Added automatic completion-order refill while the owner awaits any selected
  Task, so later queued work can start without exposing completion order.
- Added scheduler cancellation for queued work and cleanup that joins all
  active workers before releasing scheduler storage.
- Added a focused seven-task/four-slot test proving bounded refill and proving
  that background completion cannot change whether an eighth task is admitted.
- Added modular AiVM worker-program preparation, isolated invocation, and
  catalog-bound runtime orchestration components.
- Worker artifacts are selected exclusively by validated WorkerCatalog index,
  loaded lazily once per runtime, and reused as immutable programs.
- Every invocation allocates fresh VM state, copies input bytes into
  task-owned transport storage, and copies result bytes before disposing the
  isolated VM.
- Worker capability masks must be a subset of the parent VM grant. Each fresh
  VM receives exactly the worker's required capability mask.
- Scheduler capacity now combines the 96-percent CPU target, runtime-profile
  worker ceiling, and deterministic outstanding-task bound.
- Added an end-to-end identity-worker test covering reverse observation order,
  distinct payloads/fresh invocation state, exact bytes transport, automatic
  capacity selection, program reuse, and capability rejection.
- Assigned and specified the initial mechanical worker opcodes:
  `WORKER_REF=88`, `WORKER_RUN=89`, and `TASK_CANCEL=90`.
- Added an owner-VM worker Task bridge in a focused AiVM module. `WORKER_REF`
  validates a bundled catalog index, `WORKER_RUN` creates an opaque owner Task,
  and existing `AWAIT` collects copied bytes through the catalog runtime.
- First successful Await now releases scheduler admission credit, task-owned
  transport storage, and the owner Task slot through the existing one-shot Task
  lifecycle.
- Owner VM reset/disposal drains the worker scheduler and releases prepared
  programs, invocation state, results, and scheduler threads.
- Added modular self-host linker opcode mapping so AiLang can encode the worker
  opcodes without expanding the existing native-opcode facade.
- Added focused VM and linker tests for catalog reference validation and the
  complete `WorkerRef -> WORKER_RUN -> Task -> AWAIT -> bytes` round trip.
- Added focused `src/std/worker.aos` and `src/std/task.aos` facades for
  `worker.run` and `task.cancel`; `Await` remains the language observation
  construct.
- Added modular structural-expression and return-emission lowering for
  `WorkerRun`, `TaskCancel`, and `Await`, covering both self-host lowering
  paths without adding worker policy to the general opcode facade.
- Added focused standard-library parsing, structural lowering, and emitted
  object-instruction tests for the new worker and Task forms.
- Specified and implemented current-module
  `WorkerRef(name=<worker-name>)` acquisition as a build-time structural
  expression rather than a runtime string lookup.
- Added modular AiBCO worker-reference relocation emission for both structural
  object builders. Relocations target
  `<modulePath>::worker::<worker-name>` in canonical instruction order.
- Added a focused linker transformation that resolves every `WORKER_REF`
  relocation against the canonical WorkerCatalog plan and writes the validated
  catalog index into final instruction operands.
- Wired worker-aware bundle emission to use resolved functions and reject a
  missing worker target before producing final bytes.
- Added an end-to-end two-worker gate proving that the second declared worker
  resolves to catalog index `1`, final AiBC1 bytes are produced, and a missing
  worker reference fails deterministically.
- Added a complete self-host project gate that imports SDK `std.worker`, creates
  a WorkerRef-backed Task, stores it in a local, Awaits that local, links the
  WorkerCatalog, and executes the final AiBC1 on the current sibling AiVM.
- Corrected incremental object generation to validate Worker declarations
  against each module's full structural records instead of lightweight global
  symbol summaries.
- Split worker target lookup into a focused module and scoped unqualified
  function resolution to the declaring module, so a same-named function in
  another module cannot satisfy a Worker declaration.
- Added the missing self-host object-linker mapping for `AWAIT=25` and extended
  the native-opcode golden to cover the complete WorkerRef/Task/Await sequence.
- Assigned and implemented `WORKER_RUN_ALL=91` and `WORKER_TASK_AT=92`.
- Added an opaque, owner-bound `WorkerTasks` VM value and ordered task-group
  storage. It is non-comparable and cannot cross the worker transport boundary.
- Added deterministic bounded batch admission: the complete ordered workload
  must fit the owner Task bound, while active execution remains independently
  CPU/profile bounded and refills from pending tasks as workers complete.
- Added modular self-host lowering for variadic `WorkerRunAll`, SDK
  `worker.taskAt`, and structural-object preservation of the batch-count
  operand.
- Extended the complete self-host project gate to submit three worker payloads,
  select canonical index `1`, Await that Task, and execute the expected result
  through the current sibling AiVM.
- Added the public `std.worker.runAll(workerRef,orderedPayloadBytes)` facade.
- Added focused `std.worker.batch.empty` and `std.worker.batch.append` helpers.
  AiLang owns their deterministic `u32le length + payload` record construction;
  the envelope does not introduce a generic language collection type.
- Changed `WORKER_RUN_ALL` operand `a=1` to identify the initial canonical batch
  transport version. AiVM validates framing, bounds, and exact record lengths,
  then mechanically submits payloads without interpreting them.
- Added rejection coverage for truncated batch framing before any owner Task is
  allocated, and migrated the end-to-end self-host gate from direct variadic
  syntax to the public SDK batch/runAll API.
- Replaced the fixed-size batch handle array with retained immutable batch
  bytes plus dynamically sized canonical payload offsets, lengths, and logical
  handle metadata.
- Added lazy canonical-forward materialization beyond the 256-entry owner Task
  table. Only one bounded owner window is submitted; consuming a Task releases
  deterministic credit and materializes the next canonical logical index.
- Added a 300-task runtime gate proving task 256 is not materialized initially,
  consuming task 0 refills task 256, consuming task 256 refills task 257, and
  the owner Task table never exceeds its declared bound.
- Kept the new lifecycle, framing, logical-index metadata, materialization, and
  refill behavior in the focused `AiVM/src/aivm_vm_worker_batches.c` module;
  the existing single-Task bridge remains separate.
- Extracted module-object preparation into the focused
  `structural_project_module_object.aos` module. Serial incremental generation
  and process workers now share the same parse, lower, Worker-declaration
  validation, and object-record construction path.
- Added a declared `moduleObjectRecord` Worker whose `Fn(bytes) -> bytes`
  boundary returns the canonical formatted object record without writing an
  `.aibco` file.
- Added a separate `std.worker.runAll` project pipeline that submits one task
  per canonical module and Awaits/commits results strictly by canonical module
  index. This pipeline is intentionally not yet the default until final-byte
  and failure-diagnostic equivalence gates cover it.
- Added focused compilation/execution coverage for the module-object worker
  artifact and retained the complete self-host WorkerRef/Task/Await gate.
- Added the focused `structural_record_codec.aos` module with a versioned
  `AOLR` binary envelope, varuint structural lengths, canonical recursive node
  transport, and direct reconstruction of linker-ready structural records.
- Changed successful module-object workers to return the binary record instead
  of formatted `.aibco` text. Ordered collection no longer calls the structural
  document parser on the successful hot path.
- Kept failure transport explicit through the `AOER` envelope and validated
  identical diagnostic kind, attribute contents, and attribute order after
  transport.
- Added a two-module equivalence gate that generates every worker record,
  links the serial and transported object sets independently, and proves the
  final `.aibc1` byte streams are identical.
- Measured the focused fixture at 453 binary record bytes versus 458 formatted
  record bytes. The main gain is removal of serial document parsing; broader
  size and timing measurements remain required before making performance
  claims.
- Split object-pipeline selection into a small serial bootstrap selector and a
  self-host selector. `./build.sh` remains self-host by default; staging
  deterministically replaces only the selector module so the deprecated native
  launcher does not need to lower WorkerRef/Task/Await.
- Made the staged self-host compiler use `std.worker.runAll` module generation
  by default. The first complete generation phase finished in 644 seconds
  versus the recorded 855-second process baseline, a 211-second (24.7%)
  reduction.
- Removed the deprecated process-worker scheduler from the bootstrap compiler
  graph. The native bootstrap now performs only serial compatibility
  generation and dropped from 108 to 103 linked modules.
- Strengthened the bootstrap probe with exact module parse diagnostics and
  independently selectable object ranges, then fixed the malformed incremental
  module and completed lowering for all compiler modules.
- Modularized worker-relocation condition selection into focused helpers so the
  self-hosted lowerer no longer encounters value-position conditional forms.
- Identified and removed the final packaging blocker: AiVM now retains 32,768
  instructions inline and mechanically allocates larger validated instruction
  sections to the exact artifact-declared count. The generated 33,896
  instruction self-host compiler loads and reports its version successfully.

## Remaining

1. Complete qualified imported/package worker target resolution, bytes-result
   flow validation, immutable-data closure, captured-environment rejection, and
   package export references.
2. Add an installed self-host artifact golden through the default CLI build
   path and refresh the staged AiVM runtime used by that path.
3. Complete general Task cancellation, including active-task cooperative
   cancellation and dependency state.
4. Add virtual Tasks for arbitrary out-of-window `taskAt` observation and
   completion-driven refill where result-buffer credit permits; implement
   `then`, `whenAll`, and operational `whenAny`.
5. Complete self-hosted lowering for imported/package WorkerRef values and
   combinators.
6. Add internal stage timers for worker execution, ordered decoding/commit, and
   total generation so the 24.7% end-to-end improvement can be attributed.
7. Extend completion and canonical failure permutation gates, then remove the
   now-unused process worker build artifact and associated scripts.

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
