# Finish Modularizing and Self-Hosting Compiler Lowering

## Objective

Complete the AiLang-written compiler lowering path so the compiler/toolset can
be built through:

```text
.aos -> obj/*.aibco -> bin/app.aibc1 -> aivm execution
```

The transitional native C compiler is a bootstrap dependency only. Do not add
new compiler commands or language semantics to C. The final compiler/toolset
must be implemented in AiLang.

## Current State

Already implemented and tested:

- deterministic parser and module graph collection
- symbol/function record collection
- per-module AiBCO1 objects in `obj/module-<index>.aibco`
- stable entry object at `obj/app.aibco`
- linker output at `bin/app.aibc1`
- linked execution for supported arithmetic, calls, locals, parameters,
  comparisons, Match, imports, relocations, native primitives, and syscalls

Current self-build frontier:

- The recursive self-hosted compiler parser gate passes.
- The workspace-source CLI reaches structural lowering for the complete
  compiler module graph.
- Legacy compiler calls to unqualified `format` and `io.write` have been
  replaced with the canonical `format.format` export and
  `sys.stdout.writeLine` syscall.
- Value-producing `If` expressions inside local bindings now lower through the
  focused `lower/control/value_if.aos` module. Both branches store into the
  binding slot and jump to a merge block before the surrounding sequence
  continues.
- The workspace-source CLI no longer reports the former `LOWER032` frontier.
- The authoritative bootstrap probe now runs the generated CLI through the
  current bundled `aivm-runtime` and keeps its artifact assertions reachable.
  Earlier direct invocations used a stale installed/native VM or were cut off
  by a short command window, which made the build appear to exit silently.
- Identifier scanning now lives in `parser/token_cursor.aos`. It walks only the
  current token instead of running ten full-tail `StringFind` searches for each
  name. The compiled parse of the approximately 100-KiB
  `src/cli/ailang.aos` module fell from more than 150 seconds to about 12
  seconds on the local tooling runtime.
- The arenas are already heap-backed, incrementally grown, profile-capped, and
  compacted. No arena-pressure diagnostic was observed in this iteration, so
  raising or dynamically removing the profile ceilings is not currently
  justified.
- The current frontier has moved to complete multi-module graph compilation.
  The bootstrap continues beyond entry-module parsing but still had not
  reached object emission after several minutes.
- `scripts/probe-selfhost-compiler-phases.sh` now isolates entry parsing, graph
  discovery, program collection, record collection, validation, and object
  emission. The current run reaches `phase=graph` and remains there; it does
  not yet enter program or record collection.
- Large-entry parser diagnostics show no arena pressure: string high-water is
  about 156 KiB, bytes high-water about 103 KiB, and node high-water 3,614,
  with zero string, bytes, or node pressure events. The next optimization must
  therefore target graph/parser work or module size rather than arena limits.
- The focused `lower/expressions/policy.aos` policy now routes every mapped
  unary opcode, including `AttrCount`, through native expression lowering.
  With that eligibility defect fixed, structural plan dispatch moved safely
  into `lower/plans/dispatch.aos`; the focused lowering regressions remain
  green and isolated compiled parsing of `lower.aos` improved from about 43
  seconds to about 28 seconds. Complete graph discovery still does not reach
  program collection within 150 seconds, so further safe facade decomposition
  remains on the critical path.
- Native kind-to-opcode mapping now lives in the focused
  `lower/expressions/opcodes.aos` module. The extraction preserves index,
  unary, variadic, and binary mappings while reducing `lower.aos` from 164,257
  to 156,605 bytes. Native-expression, nested-native-if, module-bundle, and
  self-hosted call-target regressions remain green. The bounded compiler probe
  still reaches `phase=graph` without entering program collection within 150
  seconds.
- Native expression construction now lives in the focused
  `lower/expressions/emission.aos` module. It owns recursive native expression,
  node-index, call-argument, binary-expression, syscall-target, and binding
  emission while leaving sequence and control-flow lowering in the facade.
  This reduces `lower.aos` from 156,605 to 147,378 bytes. The rebuilt compiler,
  structural AiBCO pipeline, and self-hosted linked-object pipeline remain
  green; the bounded compiler probe remains in `phase=graph` after 150 seconds.
  `test-parser-selfhost-compiler-files.sh` also remains unresolved because it
  does not complete within the 30-second diagnostic window.
- Native terminal-sequence and branch control-flow emission now lives in the
  focused `lower/control/native_branches.aos` module. It owns terminal Let,
  Call, Return, and If traversal, error propagation, and recursive native If
  tree construction without absorbing record-plan policy. This reduces
  `lower.aos` from 147,378 to 139,734 bytes. The rebuilt compiler and focused
  control-flow regressions remain green, while the phase probe remains in
  `phase=graph` after 150 seconds and the compiler-files parser test still does
  not complete within its 30-second diagnostic window.
- Literal-return plan emission now lives in the focused
  `lower/plans/literal_returns.aos` module. It owns integer and typed literal
  return plans while `lower.aos` retains only their public exports and routing.
  The extraction reduces the facade to 1,648 lines and 103,699 bytes without
  changing emitted records. Parser, focused lowering, module-bundle, AiBCO
  round-trip, and canonical formatting gates remain green.
- Native return, native If, and terminal-sequence record-plan construction now
  lives in the focused `lower/plans/native_records.aos` module. Expression
  eligibility, expression emission, branch traversal, and record-plan policy
  remain separate responsibilities. This reduces `lower.aos` from 139,734 to
  135,564 bytes. The rebuilt compiler, focused native-plan regressions, AiBCO
  pipeline, and runnable linked-object pipeline remain green. The phase probe
  still remains in `phase=graph` after 150 seconds, and the compiler-files
  parser test still exceeds its 30-second diagnostic window.
- Structural native-expression eligibility now lives entirely in the focused
  `lower/expressions/policy.aos` module alongside unary eligibility. This
  reduces `lower.aos` from 135,564 to 132,306 bytes without mixing opcode or
  emission behavior into policy. The full lowering and linked-object pipelines
  remain green. `test-parser-selfhost-compiler-files.sh` now completes
  successfully in about 28 seconds, crossing its 30-second diagnostic gate;
  the broader compiler phase probe still remains in `phase=graph` after 150
  seconds.
- Structural If-call planning now lives in the focused
  `lower/plans/if_calls.aos` module. It owns return-call branch eligibility,
  target validation, bound and literal condition emission, and parameter/local
  call-branch plan construction without absorbing general If or local-binary
  lowering. This reduces `lower.aos` from 132,306 to 106,395 bytes. All focused
  If-call regressions and linked-object pipelines remain green, while
  `test-parser-selfhost-compiler-files.sh` improves from about 28 to about 21
  seconds. Whole-compiler discovery still remains in `phase=graph` after 150
  seconds.
- Graph display paths now normalize `.` and `..` segments through the focused
  `compiler/linker/paths.aos` module before cycle and visited-path checks. This
  prevents one physical module from being parsed repeatedly under equivalent
  spellings; the linker regression now proves `nested.aos` and
  `./nested.aos` deduplicate. A temporary discovery trace showed traversal
  reaches `src/compiler/lower.aos` after ten modules and then spends the
  remaining diagnostic window parsing it in the accumulated graph context.
  Deferring tooling-profile VM collection did not improve the 150-second gate
  and was removed. The next optimization must target graph parsing strategy or
  representation rather than arena limits.
- Module identity now also canonicalizes Windows `\\` separators to `/` while
  filesystem reads use separator-canonical import paths. Direct regression
  coverage proves Windows-style paths normalize to the same logical module
  identity as Unix-style paths.
- Graph discovery now uses the focused
  `compiler/linker/import_discovery.aos` module to parse only the canonical
  top-level Import declarations for imported modules, regardless of their
  ordering, while ignoring strings and nested bodies. Imported path records no
  longer retain complete syntax trees during discovery; full parsing is
  deferred to program collection. The bounded probe now crosses the former
  blocker and reports the discovered compiler graph within 30 seconds.
- Structural project linking now uses the focused
  `compiler/structural_project_incremental.aos` module. Its first pass parses
  one module at a time and retains only function records; after project-wide
  symbol validation, its second pass reparses, emits, and persists one object
  at a time. This removes the all-module AST accumulator from the production
  self-hosted build while preserving deterministic order and cross-module
  validation. The updated probe reaches
  `phase=incremental-records modules=47`, but record collection still does not
  complete within a 90-second diagnostic window. Per-module parser cost and
  runtime reclamation are therefore the next measured frontier.
- Per-module tracing completed all compiler modules and counted 554 function
  records, proving no individual parser or lowering input is stalled. Record
  aggregation is the bottleneck. The focused
  `compiler/structural_project_records.aos` module now collects per-module
  record chunks independently of the existing flat compatibility collector.
  A balanced compatibility flatten was rejected after regression exposed a
  call-frame overflow, so production behavior remains on the proven collector.
  The next change must keep records chunked through validation, symbol lookup,
  and object emission rather than flattening them.
- The production incremental path now retains compact per-module symbol chunks
  rather than function records with body references. Chunk-aware duplicate
  validation and structural call lookup preserve project-wide semantics, while
  each module's full function records exist only during its object-emission
  pass. The whole-compiler probe now completes collection and validation for 51
  modules in about 69 seconds. The real self-hosted build advances into lowering
  and currently stops at `LOWER032` (`Terminal branches support Let, Call,
  Return, or If.`), making unsupported compiler-source control-flow lowering
  the next blocker rather than graph or record accumulation.
- Focused object-emission tracing identifies `src/cli/ailang.aos::runVersion`
  as the first non-terminal statement-If case. The new focused
  `compiler/lower/control/statement_if.aos` module lowers call-only branches to
  then/else blocks, joins them at a merge block, and resumes the surrounding
  sequence. The probe now advances to `runHelpTopic`. Its next failure reports
  an inconsistent apparent node kind (`f`) with node id `Return_8680`, so the
  next investigation must distinguish deep nested-branch traversal corruption
  from parser/node-arena reuse before adding more lowering cases. A bounded
  CLI analysis profile did not complete within 120 seconds.
- The inconsistent `f:Return_8680` kind was caused by AiVM string-arena
  compaction during partial node construction. Node creation now reserves its
  complete metadata-string requirement before writing kind, id, or attributes,
  preventing later copies from relocating unregistered metadata pointers. The
  object probe now lowers `runHelpTopic` and advances from record 4 through
  record 42. Statement-If lowering also accepts explicit `Lit` no-op branches,
  allowing `writeAgentFiles` to pass.
- The apparent scratch-pair failure in `makeBuildSpawnArgs` was downstream
  masking, not another arena defect. Structural expression emission now
  propagates lowering errors before passing contexts to the block builder, and
  the block builder and linker preserve `Err` nodes instead of applying pair
  operations to them. The resulting `LOWER024` identified the actual gap:
  `AppendChild` and `AppendAttr` were implemented by the native opcode table but
  omitted from native-expression policy. Classifying both constructors fixes
  nested `AppendChild { MakeBlock ... MakeLitString ... }` lowering, with a
  focused regression. The whole-compiler object probe now lowers records 0
  through 61 and stops at `src/cli/ailang.aos::publishPosixLayout`, where a
  nested statement `If` branch exceeds the current call-or-no-op branch support
  (`LOWER033`). Nested statement-branch lowering is the immediate frontier.
- Statement-If branch lowering now recursively lowers nested `If` nodes, gives
  each nested tree its own deterministic merge block, and resumes the enclosing
  branch after that merge. A focused regression proves continuation with a call
  following the nested branch. All 87 functions in `src/cli/ailang.aos` now
  lower, and the object probe serializes that module before advancing to
  `src/std/str.aos::substring`. The newly exposed failure is an `Err` value
  reaching the instruction-opcode boundary while selecting the native
  `StringSlice` opcode; block construction now propagates that error instead of
  crashing in `MAKE_LIT_STRING`. Resolving why native variadic opcode selection
  yields `LOWER025` for `StringSlice` is the immediate frontier.
- `StringSlice` was not reaching native emission: structural-expression policy
  omitted the variadic opcode family and routed the node into legacy binary
  lowering. Policy now recognizes native variadic and binary opcode families,
  while focused opcode mappings cover string slice, remove, find, Unicode
  conversion, UTF-8 byte count, and scalar length. The focused
  `compiler/lower/expressions/variadic.aos` module owns variadic argument and
  opcode emission. All 12 functions in `src/std/str.aos` now lower, and the
  whole-compiler probe serializes both the CLI and string modules. The next
  frontier is `src/std/bytes.aos::bytes.length`, where missing byte-primitive
  routing currently reaches an invalid `ChildAt` path.
- Byte primitives now route through the focused
  `compiler/lower/expressions/byte_opcodes.aos` module. Unary, binary, and
  variadic mappings cover all 11 exports in `src/std/bytes.aos`, including
  length, indexing, slicing, concatenation, encoding conversions, and integer
  byte construction. The whole-compiler probe now serializes the CLI, string,
  and byte modules and enters `src/compiler/parser.aos`. Its next failure is
  `parse.isWhitespace`: a statement-If branch contains an early `Return`, while
  statement branch lowering currently supports calls, nested If nodes, and
  no-op literals. Early-return branch termination is the immediate frontier.
- Early statement-If returns now terminate their branch directly through the
  focused `compiler/lower/control/statement_return.aos` module, while non-returning
  branches still join and continue through the merge block. A regression covers
  multiple guarded returns followed by a final continuation return. The
  whole-compiler probe now lowers and serializes all 45 functions in
  `src/compiler/parser.aos` plus `parser/token_cursor.aos`. It advances into
  `src/compiler/linker.aos` and stops at `linker.collectImportPaths`, where the
  legacy `io.readFile` intrinsic alias is currently treated as an unknown
  structural call target (`LOWER026`). Intrinsic/capability call routing is the
  immediate frontier.
- Compiler-owned host calls now use canonical `sys.*` targets directly; file
  reads retain explicit `bytes.toUtf8String` conversion in AiLang. No alias
  routing or new syscall was added. A repository guard rejects future authored
  `io.*` or `console.*` call targets under `src/compiler`. The whole-compiler
  probe now lowers and serializes the linker facade, focused linker modules,
  bundle module, and structural-project linker. It advances into
  `src/compiler/structural_project.aos` and stops at
  `structuralProject.writeObjectFileAt`, where a statement-If branch contains a
  local `Let` (`LOWER033`). Branch-local binding emission is the immediate
  frontier.
- Statement-If branches now lower local `Let` nodes through the focused
  `compiler/lower/control/statement_binding.aos` module. The emitted local is
  visible only to the remainder of its branch; sibling branches and the
  post-merge continuation retain their original bindings. The whole-compiler
  probe clears `structuralProject.writeObjectFileAt`, completes
  `structural_project.aos` and `structural_object.aos`, and enters module 12 of
  51 (`src/compiler/lower.aos`). It reached
  `lower.emitGeneralParameterMatchArms` before exceeding the diagnostic silence
  window, so the next iteration must distinguish slow lowering from a stalled
  or unsupported shape at that record.
- Resumable whole-graph probing showed that the module-12 silence was
  graph-scale lookup latency, not a failed record or arena exhaustion.
  `lower.emitGeneralParameterMatchArms` succeeds with full project symbols.
  A missing `localName` binding in the focused local-If call planner was fixed,
  and formatter attribute delimiters now use small helper calls instead of
  unsupported inline value-If expressions. The probe consequently advances
  through module 54. Current graph discovery reports 56 modules total; the
  only undiscovered module frontier is module 55,
  `src/cli/target_packages.aos::findTargetSectionFrom`, which currently fails
  on a nested `Return` (`LOWER031`).
- Target-package section slicing now uses the focused `sliceTargetSection`
  helper instead of an inline value-If expression. The resumed full-symbol
  probe lowers and serializes module 55, so every record in all 56 discovered
  modules is supported. An uninterrupted pass completes modules 0 through 11,
  reaches module 12, and then spends more than four minutes re-lowering its 53
  records during object serialization. Aggregate duplicate lowering and symbol
  lookup performance, rather than an unsupported source shape, is now the
  immediate whole-object frontier.
- The object-emission probe can now disable its diagnostic per-record pass,
  separating probe overhead from production serialization. With diagnostics
  disabled, module 12 completes object construction after approximately four
  and a half minutes, and the same process continues through modules 13 to 55
  successfully. Together with the preceding uninterrupted completion of
  modules 0 to 11, every discovered module now has successful object-emission
  evidence. A single start-to-finish retained-object build and whole-project
  link are the next gates; repeated full-graph symbol lookup remains a measured
  performance defect but is not a memory-capacity blocker.
- A phased whole-compiler link probe now distinguishes graph discovery, symbol
  collection, duplicate validation, object retention, and final linking. Symbol
  collection and validation both complete for all 56 modules. In-memory object
  retention completes modules 0 through 11, including the large CLI, parser,
  and structural-object modules. Module 12 does not fail allocation, but its
  construction slows from roughly four and a half minutes when isolated to
  more than eight minutes with modules 0 through 11 retained. The persisted
  writer is slower still because it formats, writes, reads, and reparses each
  object. Retained-node GC/arena pressure and the redundant persistence round
  trip are now the immediate whole-link architecture frontier.
- Tooling-profile return-boundary node collection is now pressure-aware instead
  of compacting the full retained arena after every 512 allocations. Production,
  debug, and explicit safe-point collection retain their existing behavior.
  With the revised mechanical policy, graph discovery, all 56 symbol chunks,
  duplicate validation, and retained construction of all 56 module objects
  complete in one process for the first time. The large module 12 completes in
  roughly six and a half minutes with modules 0 through 11 retained, versus the
  prior run exceeding eight minutes. The process now exits after reporting
  `objects-done count=56`, during final function collection or validation. The
  phase probe reports those final subphases explicitly so linker-stage diagnosis,
  rather than further general cleanup or arena-limit increases, is the immediate
  frontier.
- The final-link diagnostic now reports stable validator code, message, and
  symbol. It identified `LINK012` at `src/std/str.aos::remove`: lowering emitted
  the valid AiBC1 `STR_REMOVE` opcode, but the object linker maintained partial,
  inconsistent native-opcode tables. Native string, byte, node, and node-builder
  opcode numbers now live in the focused
  `compiler/object_linker_native_opcodes.aos` module and are shared by validation
  and both object-emission paths. A regression covers representative string,
  byte, builder, unknown, validation, and binary-emission cases. The whole graph
  now contains 57 modules and 580 functions; all objects build, function
  collection completes, and whole-project supported-op validation passes.
  Final AiBC1 emission begins without the former invalid `-1`/`BYTES_U32_LE`
  failure, but did not complete during a further ten-minute bounded emission
  window. Recursive byte concatenation and repeated linker lookup during final
  emission are now the measured frontier.
- Whole-function byte emission now divides the function sequence into balanced
  index ranges before concatenation. The implementation does not place byte
  values in AST `Block` children: an initial chunk-accumulator experiment
  correctly failed the node-only child contract and was replaced with the
  focused `compiler/object_linker_byte_ranges.aos` integer range helper.
  Focused opcode, jump-relocation, linked-object execution, and lowering tests
  preserve emitted behavior. The self-hosted graph now contains 58 modules and
  583 functions; all objects and supported-op validation still pass. Balanced
  top-level byte copying alone did not complete final emission within a further
  ten-minute bounded window. Repeated per-instruction layout, symbol, constant,
  and relocation lookup is therefore the immediate measured frontier; the next
  probe should trace emission by function range before changing representation.
- Final-link setup and instruction emission are now separate reusable phases.
  `objectLinker.emitAibc1BytesFromLayout` consumes precomputed layout and
  constants, so diagnostic and production callers do not repeat those passes.
  Function emission reads its own offset directly from the same-index layout
  record, and relocation lookup starts immediately after the current
  instruction rather than rescanning the function from child zero. Focused
  object, jump, call-relocation, and execution regressions remain green. The
  58-module graph now contains 584 functions and 969 constants. Whole-project
  layout assignment completes within 30 seconds, and constant collection
  completes within the next 30 seconds. Instruction emission alone remains
  active beyond a six-minute bounded window. Per-`CONST` linear
  `constantIndex` lookup across 969 constants and per-call target offset lookup
  across 584 layout entries are now isolated as the next indexing frontier.
- Function and instruction byte concatenation now both use balanced index
  ranges. Instruction ranges preserve relocation numbering by counting `Inst`
  nodes in the left range before emitting the right range, and relocation
  searches begin at the current instruction's following child. Function offsets
  are read directly from the same-index layout record. The graph remains 58
  modules and now contains 586 functions; layout and collection of 969 constants
  each complete within 30 seconds. Instruction emission still remains active
  beyond an eight-minute bounded window. This rules out top-level and
  per-function byte concatenation as the primary blocker and leaves repeated
  constant-index and call-target offset searches as the evidence-backed
  frontier. The next representation must carry resolved operands into emission;
  merely moving the same searches into a separate pass is not sufficient.
- Constant operands now have an explicit, focused linker representation in
  `compiler/object_linker_constant_plan.aos`. One traversal builds both the
  deduplicated constant table and a per-function sequence of resolved constant
  indices; final `CONST` emission consumes those indices without rescanning the
  global constant table. `objectLinker.emitAibc1BytesFromPlan` also accepts the
  precomputed layout and constant plan so probes and production emission share
  the same path. A focused regression proves stable deduplication and operand
  ordering. The whole graph now contains 59 modules and 593 functions. All 59
  objects build in one retained process, function collection and supported-op
  validation pass, and the parser, linker, relocation, executable-pipeline, and
  lowering regressions remain green. The whole-link probe then remained active
  for more than ten minutes after function collection, before final byte
  emission was observed. Phase markers now distinguish layout, constant-plan
  construction, and byte emission on the next run. The remaining performance
  work is therefore bounded to those three linker phases; constant-plan
  construction must be indexed rather than retaining a linear search for every
  collected constant, followed by equivalent call-target operand indexing.
- Constant planning now uses the focused
  `compiler/object_linker_string_index.aos` module, which provides a
  deterministic persistent string-to-integer index ordered by a stable UTF-8
  byte hash with exact collision checks. A 512-key sequential insertion,
  lookup, update, missing-key, and persistence regression completes in under a
  second. Constant, operand, and function-plan collection also uses node
  builders so growing blocks are finished once instead of copied by every
  append. All focused linker and executable-pipeline regressions pass, and the
  complete 60-module graph lowers to objects and collects 600 functions in one
  retained process. Whole-project layout completes in under a minute. Constant
  planning nevertheless remains active beyond an eight-minute diagnostic
  window with both indexed lookup and builder-backed accumulation. This rules
  out constant-key lookup and immutable block growth as the dominant plan
  bottleneck. Per-instruction relocation discovery still searches forward
  through function children and is now the immediate measured frontier. The
  next plan representation must collect relocation operands during the same
  sequential function traversal instead of calling `findReloc` independently
  for each instruction.
- Constant planning now consumes `Reloc(kind=const)` nodes directly in their
  validated function order, eliminating per-instruction `findReloc` calls.
  Planning is also split into independently measurable constant collection,
  constant-index construction, and operand-plan construction. The complete
  graph contains 60 modules and 603 functions. Layout completes in under a
  minute, and the existing collector produces 976 constants within the next
  30 seconds. Persistent constant-index construction then remains active beyond
  four minutes before operand planning begins. This rejects relocation
  discovery as the dominant planner cost and isolates persistent hash-tree
  construction under the retained compiler graph as the current blocker.
  The next index representation must avoid rebuilding a tree path for every
  insertion; a deterministic builder-backed bucket table or an equivalent
  bulk-built immutable lookup structure should be measured before changing
  operand or byte emission again.
- The collection performance work is now tracked independently in
  `Docs/Tasks/Implement-Std-Collections.md` and normatively defined by
  `SPEC/COLLECTIONS.md`. Deterministic UTF-8 string hashing moved out of the
  compiler-specific index into the focused `std/collections/hash.aos` module.
  The linker consumes that shared standard-library function, and the complete
  self-hosted object probe lowers the resulting 61-module graph through the new
  standard module. The next collections iteration must implement the mechanical
  bulk-builder/frozen-map storage boundary and meet the retained 1,000-entry
  construction gate before replacing the linker index.
- AiVM now has focused mechanical bulk-map storage with dynamically checked
  growth, open addressing, exact string collision checks, builder freezing,
  and immutable string-to-int lookup. Its 100,000-entry native contract test
  passes in about 0.01 seconds. AiVM now exposes the storage through distinct
  `mapBuilder` and immutable `map` value kinds and focused opcodes 82 through
  87. Native bytecode tests cover the full builder, insert, finish, count,
  membership, and fallback-lookup stack contract.
- AiLang validation, focused lowering, object-linker opcode mapping, and
  `std.collections.map` now expose that storage without a syscall. The object
  linker's constant index has replaced its persistent hash tree with a
  builder-backed standard map and freezes once before lookup. A focused
  1,000-entry linker-index regression completes in about 0.02 seconds. The
  63-module whole-link probe still spends more than four minutes lowering
  module 12, `src/compiler/lower.aos`, before reaching constant planning, so
  lower-facade object emission is again the immediate measured frontier.
- Retained structural Object and Function child assembly now lives in the
  focused `compiler/structural_object_builders.aos` module and uses node
  builders for imports, exports, symbols, functions, instructions, and
  relocations. This removes repeated immutable `AppendChild` copies without
  changing AiBCO ordering or shape. Starting at module 12, the complete
  52-module emission tail now finishes in about 73 seconds including graph and
  symbol setup; previously module 12 alone exceeded four minutes.
- With objects 0 through 11 retained, module 12 still remains active past six
  minutes. The builder removes isolated object-copy cost but does not remove
  the retained-graph multiplier. The next measurement must distinguish
  pressure-triggered node collection from repeated linear call-symbol scans;
  the whole-link probe has not yet reached constant planning in that retained
  configuration.
- The whole-link probe can now stop after a selected retained object index via
  `STOP_AFTER_OBJECT_INDEX`, allowing reproducible prefix profiling without
  waiting for the complete compiler. The object-0-through-11 prefix finishes
  in about 70 seconds and its debug diagnostics report 39 node compactions,
  217,826 reclaimed nodes, and a 49,154-node high-water mark, with no arena
  pressure errors. By contrast, the per-record module-12 probe lowers all 53
  records quickly when their emitted objects are not retained. This evidence
  identifies repeated full-node compaction over the retained graph—not
  unsupported lowering or isolated call-symbol scanning—as the next dominant
  cost. Node arenas remain fixed-capacity even though string and byte arenas
  grow incrementally; the next VM iteration should add host-memory-admitted
  node/attribute/child arena growth before retrying compaction.
- AiVM now implements generic tooling-profile node, attribute, and child arena
  growth in the focused `aivm_vm_node_arena.c` module. Growth is considered at
  both exhaustion and return-safe-point pressure, doubles only the pressured
  arena, rechecks current host memory immediately before allocation, and falls
  back to normal compaction when growth is unavailable. It contains no compiler
  or AiBCO policy. Core VM, memory-cycle, reference-counting, and map-storage
  regressions pass.
- Dynamic node growth did not materially advance retained module 12 within a
  nearly five-minute bounded rerun. This corrects the earlier diagnosis:
  repeated fixed-capacity compaction was observable, but is not the dominant
  module-12 multiplier under the tooling profile. The next optimization should
  build one call-name-to-record index for lowering rather than repeatedly
  scanning all retained project record chunks.
- Call resolution now supports an opaque indexed context built by the focused
  `lower/records/index.aos` module. It bulk-builds one frozen name-to-ordinal
  map in reverse record order so duplicate unqualified names preserve the
  previous first-match behavior. `lower/records/lookup.aos` remains the public
  resolution facade and retains its linear compatibility path. A regression
  covers first-match and unknown-target diagnostics.
- The whole-link probe builds that call context once and shares it across
  module emission. Retained module 12 still remains active beyond a
  three-minute bounded run, ruling out both repeated index construction and
  linear call-name scanning as its primary multiplier.
- VM return-safe-point collection now keeps independent node and byte decisions.
  A bytes-only threshold no longer forces node, scratch-pair, or string
  compaction; explicit safe points still collect every arena. Focused VM and
  memory tests pass, but this separation also did not remove the retained
  module-12 stall. The next probe must report progress per function while the
  first 12 objects remain live, rather than infer the hot function from
  aggregate module timing.
- Retained phase tracing showed module 12 stalled inside
  `structuralProject.parseModuleProgram`, before record collection or lowering.
  A native five-second stack sample then identified the exact hotspot:
  `aivm_string_arena_alloc` spent nearly all sampled CPU time repeatedly calling
  `aivm_compact_string_arena`.
- String-arena allocation now attempts admitted incremental growth before
  compaction. Previously every 16-KiB limit crossing compacted and relocated the
  complete live string graph before increasing the already-reserved limit.
  Compaction remains the fallback when growth cannot satisfy the request.
  Focused VM core time fell from about eight seconds to 0.02 seconds and the
  retained module-12 parse, record collection, and all 53 function plans now
  complete.
- The complete retained compiler link now succeeds in one process. The current
  67-module graph contains 628 functions and 999
  constants; layout, constant indexing, operand planning, and final byte
  emission complete in about 163 seconds. The generated
  `ailang.aibc1` is non-empty and structurally linkable.
- Executable entry emission now lives in focused
  `object_linker_entry.aos`. It prepends a generic wrapper that loads
  `sys.process.args`, calls a canonical entry symbol, and halts. A focused
  multi-function regression proves argument delivery and exit-code
  propagation.
- Structural constant targets now retain raw semantic string values; only
  legacy text serialization requests escaped targets. The manifest lookup
  regression with embedded quotes passes.
- `MakeNode(kind,id)` now emits `MAKE_NODE_EMPTY`, matching the VM's two-string
  constructor contract rather than the template-instantiation `MAKE_NODE`
  contract. The native primitive regression passes.
- Syscall aliases are canonicalized in focused
  `lower/expressions/syscalls.aos`; `io.write` and `io.print` lower to the
  existing `sys.stdout.writeLine` boundary.
- The generated compiler now builds the `binary_runs` sample project without a
  bootstrap fallback. Structural project linking applies the manifest's
  `entryFile` and `entryExport` to the generic executable wrapper. The
  self-hosted output runs, prints `binary-ok`, and exits successfully.
- The project compiler entry `src/compiler/aic.aos` now lowers and links as a
  complete 17-module graph with 214 functions and 357 constants. Its previously
  unbound `runFmt.mode` local is fixed.
- Bare `Return` statements in terminal and statement-If branches now emit
  value-free returns without indexing a missing child. Nested value-`If`
  expressions recursively share one destination slot and converge at the
  owning merge block. Focused regressions cover both shapes.
- The generation-1 self-hosted CLI now builds the AiLang project compiler
  (`aic`) successfully. Repeating the same self-hosted build produces the
  identical SHA-256
  `62533eedaf01383c6639513e6c36dd063bf898ca26e708487f5a551a9d52dd67`.
- Quoted attribute tokens are now classified before boolean spelling, so
  `"true"` remains a string while unquoted `true` remains a boolean. The
  focused parser regression and compiler-file parser gate pass.
- Structural literal-return lowering now preserves function parameters and
  emits their prologue stores. This fixes ignored `_` arguments and the broader
  parameterized-constant-return stack leak.
- Bare returns now produce the compiler's integer-zero void result through the
  focused `lower/returns/void.aos` module. Statement calls can therefore
  discard the result without underflowing the VM stack.
- The rebuilt generation-2 project compiler completes `fmt`, `check`, and
  `run` for valid input. `run` evaluates `Program { Lit(value=7) }` to
  `Ok#ok0(type=int value=7)` without a VM error.
- The canonical `./build.sh selfhost` and `./build.ps1 selfhost` targets now
  stage the complete self-hosted CLI at
  `.artifacts/ailang-selfhost/bin/ailang.aibc1`. The build uses the full
  `src/cli/ailang.aos` entry, which owns project `build`; the smaller
  `src/compiler/aic.aos` entry remains the stdin-oriented project compiler.
- The staged generation-2 full CLI built a clean generation-3 full CLI.
  Both artifacts are byte-for-byte identical with SHA-256
  `3b5f7649e87a9523b29f12a6b3785a18ac2c24530614e0cc86f2fe4f5d138870`.
  Full-CLI bootstrap command coverage and deterministic generation parity are
  therefore no longer blockers. The immediate frontier is compiling and
  running the sibling `ailang-examples` repository exclusively through this
  staged self-hosted artifact.
- The self-host build now stages `src/std` beside the compiler artifact so
  `AILANG_SDK_ROOT=.artifacts/ailang-selfhost` is a complete, relocatable SDK
  root rather than a repository-local assumption.
- The examples validator has an explicit `--selfhost` mode that runs package,
  build, and run commands through the staged AiBC1 CLI and native VM without
  invoking the bootstrap compiler. The `hello-cli` example builds and prints
  its expected output through this path.
- Finished child-process output is copied into stable host scratch storage
  before its process slot is released. This mechanical AiVM lifetime fix lets
  the self-hosted CLI relay compiler and application stdout; the focused
  process lifecycle regression covers wait-before-read behavior.
- Canonical `sdk:ailang/...` graph display paths now resolve through the
  current `AILANG_SDK_ROOT` at object-emission time using the shared path join
  helper. The package example therefore completes restore and source parsing
  instead of trying to read `sdk:ailang` as a project-relative directory.
- `examples/package-demo` now reaches structural lowering and exposes the next
  semantic frontier: `LOWER024` for a generated `ChildAt` expression in the
  restored `std-json` module. This is a compiler lowering gap, not graph
  discovery, SDK location, parser, process output, or VM memory pressure.
- The canonical self-host build now stages a project manifest and restores its
  local `std-cli` dependency through `package restore`; self-host graph
  discovery consumes the resulting lock file and currently resolves 82
  modules. `Map` and `Field` literals lower through the focused
  `lower/expressions/map_literals.aos` module and have an executable pipeline
  regression. The build now lowers package modules through object index 74 and
  stops at the next focused frontier: `LOWER024` for nested `ChildAt`
  (`ChildAt_3366`) at object index 75.
- Built-in compiler and CLI imports now use canonical
  `Import(sdk="ailang" path="std/...")` declarations. The staged self-host
  project no longer carries a second `src/std` tree; its 81-module graph reads
  standard-library sources only from `AILANG_SDK_ROOT`.
- Structural `ChildAt` return expressions and `MakeFieldString` construction
  now have focused lowering coverage. All 81 modules lower and link into 744
  functions. The resulting 1,127-entry constant pool exposes the current
  1,024-entry AiVM program capacity boundary. A direct static-capacity increase
  is not acceptable because it breaks loader/module-cache stack budgets; the
  next iteration must reduce or segment the linked constant pool before the
  generation build can proceed.
- The first executable built-in command iteration adds the modular
  `std.process` and `std.cli` invocation modules and migrates `clean` to its own
  `clean.aibc1`. The expanded bootstrap graph lowers and links all 86 modules
  and 766 functions. Its current monolithic root still contains 1,142 unique
  constants, confirming that additional command extraction must also remove
  their implementation modules from the root graph before the standard
  1,024-entry AiVM limit is met.
- The second executable built-in iteration moves package-manager policy into
  `src/cli/Package`, adds a focused executable entry module, emits
  `package.aibc1`, and registers it through the same `std.cli`/`std.process`
  contract as `clean`. The root no longer imports or statically dispatches
  package behavior. The canonical self-host probe now lowers and links 83
  modules and 711 functions with 1,038 constants, down from 1,142. The
  remaining frontier is only 14 entries above the standard 1,024-entry AiVM
  capacity, so the next command extraction must keep its implementation out of
  the root graph and rerun the generation build.
- The third executable built-in iteration moves `init`, `template`, and
  `agent` into focused command modules with independent entry points and
  `.aibc1` artifacts. Their descriptors use the same `std.cli` executable
  contract, and no static handler route remains for those commands. The root
  self-host artifact now links 83 modules and 697 functions with 980 constants,
  clearing the standard 1,024-entry AiVM capacity without changing VM limits.
  The generated compiler then emits and links all 83 modules of its own project
  into `bin/app.aibc1`, and its version smoke succeeds. Self-host staging now
  installs the runtime and built-in command artifacts before invoking the
  package sidecar, removing the former bootstrap ordering cycle.
- The fourth built-in iteration moves `project` metadata behavior into focused
  implementation and entry modules and emits `project.aibc1`. The shared
  manifest attribute reader now has its own semantic module instead of living
  in the root CLI. Built-in artifact generation uses a bounded process pool
  controlled by `AILANG_BUILTIN_JOBS` and copies successful artifacts in
  canonical command order; `AILANG_BUILTIN_JOBS=1` remains the diagnostic
  serial mode. The self-host script reports elapsed seconds for SDK staging,
  bootstrap linking, built-ins, project staging, restore, generation, and
  packaging so the next parallelization work targets measured cost. The
  canonical four-job run passes with bootstrap linking at 129 seconds and
  self-host generation at 855 seconds; all other reported phases round below
  one second. Per-module generation is therefore the measured parallelization
  frontier.
- The parallel generation iteration stages the project graph once, emits
  module objects through a core-count-aware pool capped at four workers, and
  reloads those objects in deterministic module order. The canonical
  generation phase improved from 855 seconds to approximately 478 seconds.
  AiVM constant storage now grows beyond its 1,024-entry inline allocation, so
  larger self-host graphs are not rejected by a fixed constant ceiling.
- The telemetry iteration adds a focused `build_telemetry.aos` module and
  reports staging, worker, and reload durations without adding timing policy to
  the structural compiler facade. On the 88-module canonical build, staging
  took 20.6 seconds, worker completion took 131.4 seconds, and deterministic
  object reload/link preparation took 326.1 seconds. Equal 22-module
  round-robin partitions took 82.6, 131.3, 37.8, and 59.3 seconds, proving that
  module count is not an adequate scheduling weight. The next optimization
  must use deterministic estimated module cost and then address the larger
  serial reload phase.
- AiVM debug graph diagnostics now allocate traversal state from the VM's
  configured dynamic node and child capacities rather than the former 16,384
  compile-time ceiling. The integration smoke runs through 17,001 live nodes
  and verifies complete root and node-kind attribution.
- The scheduling iteration introduces a focused, persisted
  `object-schedule.aos` contract between the parent compiler and module-object
  workers. Scheduling policy, worker execution, object emission, and
  deterministic reload remain separate modules. Function-count weighting
  measured 138.3 seconds and structural-AST weighting measured 135.4 seconds,
  both slower than the 131.4-second 88-module round-robin baseline, so neither
  speculative weighting policy remains in production. Stable round-robin is
  retained through the explicit schedule contract and measures 133.3 seconds
  on the expanded 89-module graph. The canonical build passes in 495 seconds;
  its 321.7-second serial object reload is the next measured frontier.
- The reload investigation tested concatenating all object text into one
  parser document. It exceeded 540 seconds before completion and was removed;
  reducing parser entry count does not reduce the dominant work. The retained
  deterministic loader now reports bounded ten-object milestones from the
  focused telemetry module. On the passing 89-module canonical build, reload
  reached 10 objects at 19.4 seconds, 20 at 80.8, 60 at 163.4, 70 at 214.7,
  and 80 at 273.7 before completing at 326.8 seconds. Cost clusters around
  particular large objects rather than growing uniformly by object count.
  The next implementation should have generation workers emit compact
  linker-ready records so the parent does not reconstruct full AiBCO syntax
  trees for those large modules.

Reproduce the frontier with:

```sh
./build.sh selfhost
./tools/aivm-runtime run \
  .artifacts/ailang-selfhost/bin/ailang.aibc1 -- version
```

## Architectural Rules

- Keep semantics in AiLang `.aos` modules. AiVM stays mechanical.
- Do not add compiler semantics, command behavior, or fallback paths to C.
- Prefer focused modules over expanding `lower.aos`.
- Preserve current public `lower.*` contracts unless deliberately replacing the
  entire contract and updating all callers/tests.
- Node IDs are compiler generated. Do not manually assign node IDs in AiLang
  sources, templates, or tests.
- Do not add backward-compatibility adapters or dual paths.
- Every fixed regression needs a test that failed before the fix.
- Follow `SPEC/STYLE_AILANG.md`: one semantic module per `.aos` file. Files over
  1,000 lines trigger a cohesion warning, not an instruction to split code
  arbitrarily.
- Further facade extraction is supporting work only. Do not continue routine
  decomposition unless it directly enables a self-hosting capability or fixes
  a measured bottleneck.

## Required Work

### 1. Complete self-hosted graph discovery

Whole-compiler graph discovery and chunked symbol collection now complete in the
bounded probes. Preserve the focused discovery and incremental object-emission
path while completing lowering; do not reintroduce an all-module AST or flat
whole-project function-record accumulator.

Keep graph semantics in focused AiLang modules. Do not move discovery policy to
the host or raise limits without evidence.

### 2. Maintain `lower.aos` as a facade

`lower.aos` should become a small facade that imports focused lowering modules.

Existing extracted families include:

- `lower/bindings/symbols.aos`
- `lower/bindings/scope.aos`
- `lower/bindings/parameters.aos`
- `lower/bindings/locals.aos`
- `lower/bindings/calls.aos`
- `lower/returns/expressions.aos`
- `lower/returns/routing.aos`
- `lower/returns/parameters.aos`
- `lower/constants/literals.aos`
- `lower/constants/match.aos`
- `lower/constants/locals.aos`
- `lower/constants/policy.aos`
- `lower/constants/expressions.aos`
- `lower/control/value_if.aos`

Remaining extraction candidates:

1. Continue moving constant-expression behavior into
   `lower/constants/expressions.aos` with behavior-preserving tests.
2. Split function-body instruction lowering into focused modules:
   - local binding emission
   - local/parameter return emission
   - call emission and relocation creation
   - parameter prolog/store emission
   - Match and If instruction lowering
3. Split structural/native lowering by ownership where practical.
4. Leave `lower.aos` as imports, public exports, and thin orchestration only.

Do not rewrite a large lowering family while extracting it unless a regression
test first defines the intended changed behavior.

### 3. Maintain the self-hosted compiler parser gate

This currently passes in about 21 seconds and must remain green:

```sh
./scripts/test-parser-selfhost-compiler-files.sh
```

It parses every compiler `.aos` file using the self-hosted parser. Treat a
regression beyond the 30-second diagnostic window as a performance defect.

### 4. Prove lowering to objects and final bytecode

For each supported language shape, prove:

```text
source -> module object -> linked app.aibc1 -> expected execution
```

Cover at least:

- literals and arithmetic
- local bindings and copies
- parameters and calls
- forward and cross-module calls
- imports/exports and transitive module symbols
- If and Match paths
- syscall statements
- diagnostics for unsupported or invalid lowering shapes

Generated objects must remain deterministic across clean repeated builds.

### 5. Bootstrap parity and compiler self-build

Create a compatibility harness that runs supported inputs through the
transitional bootstrap path and the self-hosted path, comparing:

- diagnostics and exit codes
- AiBCO object text
- final AiBC1 bytes where deterministic equality is required
- runtime output

Then build the supported AiLang compiler/tool modules using the self-hosted
pipeline. Document every remaining unsupported source shape as a defect or an
explicitly deferred capability.

### 6. Real-project and examples-repository proof

Run the projects in the sibling `ailang-examples` repository through the
self-hosted compiler, beginning with `examples/hello-cli` and progressing to
package and AiVectra examples, including Weather:

```sh
ailang package restore
ailang build .
ailang run .
```

Extend `ailang-examples/scripts/validate-examples.sh` with an explicit
self-hosted compiler mode once the self-hosted CLI artifact is available. The
proof is complete only when every supported example builds with self-hosted
compilation, runs with its expected output or deterministic UI mode, and uses
no native compiler fallback.

## Required Tests

At minimum run after each relevant change:

```sh
AILANG_ALLOW_SIBLING_AIVM_SOURCE=1 ./scripts/build-ailang-native.sh
./scripts/test-parser-selfhost.sh
./scripts/test-parser-selfhost-compiler-files.sh
./scripts/test-parser-public-exports.sh
./scripts/test-lower-module.sh
./scripts/test-structural-project-aibco-pipeline.sh
./scripts/test-selfhost-linked-object-pipeline.sh
git diff --check
```

Add focused tests for each newly extracted module and every behavior changed.

## Parallel Module Generation

Status: implemented and validated on 2026-07-26.

The self-host build now generates independent module objects in worker
processes and retains a single deterministic parent link. Worker assignments
use stable strided module indices, and the parent reloads completed objects in
canonical numeric order before linking.

The default is `min(logical cores, AILANG_SELFHOST_MAX_JOBS)`.
`AILANG_SELFHOST_MAX_JOBS` defaults to `4` because every worker is a complete
compiler process with its own graph and symbol view. Set
`AILANG_SELFHOST_JOBS=1` for serial generation, use another positive integer
for an explicit worker count, or leave it as `auto`.

Canonical benchmark on a 10-logical-core host:

```text
serial generation:    855 seconds
4-worker generation:  478 seconds
reduction:             377 seconds (44.1%)
speedup:               1.79x
```

The bootstrap link remained within current format ceilings at 85 modules, 704
functions, and 998 constants. Same-source two-worker and serial fixture builds
produced byte-identical module objects and final AiBC1 output.

### Shared parallel build stage

Status: implemented and validated on 2026-07-26.

The parent compiler now resolves the module graph and validates project-wide
function records once. A focused `structural_project_stage.aos` module persists
canonical module paths and function-record chunks for all workers. Workers
restore the semantic `record-chunks` container after parsing and lower only
their assigned modules.

The stage reduced serialized module-path input from 51 KiB with an accidentally
embedded entry program to 4.2 KiB of canonical paths. Function records occupy
115 KiB. Serial and two-worker fixture builds remain byte-identical, and a
missing stage returns `PARBUILD005`.

The canonical generation benchmark was 479 seconds, effectively unchanged from
the preceding 478-second four-worker result. This removes redundant graph and
symbol construction and should reduce aggregate worker memory/CPU use, but it
does not shorten the critical path. Assigned module lowering and deterministic
parent reload/link now dominate.

The canonical build entrypoints now default to self-hosting:

```text
./build.sh       -> selfhost
./build.ps1      -> selfhost
```

The deprecated native C AiLang bootstrap launcher is explicit:

```text
./build.sh legacy
./build.ps1 legacy
```

On a clean checkout, the default self-host target builds the legacy launcher
only when the required bootstrap tools are absent.

### Dynamic AiBC1 constant storage

Status: implemented and validated on 2026-07-26.

AiBC1 already encodes constant counts as `u32` and instruction operands as
signed 64-bit values. The former 1,024-constant ceiling was an AiVM storage
implementation limit, not a bytecode-width limit.

AiVM now retains 1,024 inline constant slots for small programs and allocates
loader-owned constant storage sized to larger encoded pools. Constant storage,
release behavior, and cache copying live in the focused
`aivm_program_constants.c` module. The deprecated native AiLang bootstrap
builder remains limited to its inline storage; self-hosted AiBC1 loading no
longer has that ceiling.

A focused VM regression loads 1,025 integer constants, executes `CONST 1024`,
and verifies that value `1024` reaches the VM stack. The canonical default
`./build.sh` self-host build also passes using the inline path at 1,007
constants.

Validation boundary:

- all 30 tests selected by `AiVM/test-aivm-c.sh` passed;
- loader, dynamic constants, module cache, loader fuzz, security, and runtime
  stress tests passed;
- the final cross-repository debug-memory smoke remains stale because its
  diagnostic traversal assumes the former fixed 16,384-node arena while AiVM
  node storage is now dynamic;
- the optional performance harness currently reports its existing string
  benchmark type mismatch in both smoke and full modes.

### Canonical installed runtime invocation

Status: implemented and validated on 2026-07-29.

Installed bytecode execution now resolves the SDK-owned `aivm-runtime` and uses
the canonical `run <artifact> -- <application arguments>` contract. Runtime
selection and argument construction live in the focused
`src/cli/runtime_invocation.aos` module instead of the large CLI facade.

The focused argument golden, complete CLI contract suite, and installed
bytecode CLI gate pass. The published beta.53 self-host compiled the complete
updated CLI project, and that generated CLI built and ran the restored
`std-json` package application through the installed runtime boundary. This
removes the `DEV008` failure that followed the package-owned
`std.json.stringify` correction.

### Build-validated dynamic call lowering

Status: binding, statement, conditional-branch, return, and loop continuations
implemented on 2026-07-29.

The self-hosted lowerer now owns single-candidate `CallDynamic` dispatch in
focused control modules. It evaluates and stores the runtime target, compares
it with the build-validated candidate, invokes the resolved canonical symbol,
and preserves the `sys.dynamic.missingFunction` fallback. Binding, discarded
statement, statement-`If` branch, and return continuations have executable
coverage.

The self-hosted lowerer now accepts structural `Loop` nodes through a focused
control module with canonical entry, body, and exit blocks. `Break` and
`Continue` resolve only from the loop labels threaded through nested statement
branches, and loop-local rebinding reuses the existing local slot. Focused
coverage includes a dynamic call binding nested in a loop conditional.

The restored Weather graph now lowers its complete application loop. The
two-statement classification has moved into a focused plan module: only a
validated local `Match` uses its specialized plan, while other supported
records route through the symbol-aware native sequence planner. This removes
the former invalid `ChildAt` failure. Numeric expression policy and opcode
selection have also moved into a focused module, including the specified
`Pow` to `POW_NUM` mapping.

Weather now advances through both of those frontiers. Investigation of
`If_6031` showed that it was package source embedding a multi-block conditional
inside a value expression, not a missing mechanical VM operation. The
authoritative AiVectra and `vectra-ui` sources now bind those conditionals as
ordinary statement control flow before consuming their values.

The restored graph subsequently exposed package portability issues in
`std-http`: a compiler-parser dependency used to construct a command, legacy
unqualified byte helpers, `ToInt`, unsupported `Or` expressions, and another
return-valued conditional. Those paths now use direct structural construction,
canonical `bytes.*` exports, the package's decimal parser, and deterministic
statement control flow. The latest completed generation pass reached
`If_43197` in redirect status classification; that source is normalized for the
next proof run. No new semantics were added to AiVM or the generic expression
emitter.

The following iteration added optional-else support to the focused
`lower.statementIf` module. A statement `If` with two children now receives a
deterministic empty else block during lowering instead of attempting an
out-of-range `ChildAt`. The focused regression and the default self-host build
pass; the latter generated the self-hosted CLI in 677 seconds using nine jobs
derived from the 96-percent capacity profile.

Using that fresh self-hosted CLI with the explicit serial object-selection
proof, the restored Weather application now compiles completely to
`bin/app.aibc1`. App-owned inline conditionals in HTTP URL construction,
forecast text, UI control states, and the ForecastCard companion were moved
into focused reusable functions. The default worker path remains blocked
earlier: the first canonical module task fails at `Await`. AiVM diagnosis now
snapshots terminal worker details before automatic Task reclamation. The
canonical failure is therefore visible as `AIVMS008`: the module-object worker
calls `sys.fs.path.exists`, but filesystem capability is intentionally denied
because the current filesystem host binding retains process-global mutable
state.

The serial success isolates that defect to the path-coupled worker task schema
rather than Weather lowering. The next worker iteration must transport
canonical staged input bytes or compact records to the isolated invocation; it
must not grant unsafe concurrent filesystem access. The measured Weather stage
documents are 99,433 bytes before program payload expansion, providing the
first bound for that transport design. Runtime launch reaches the macOS
application boundary, but injected close did not terminate the application, so
executable runtime acceptance remains open.

The following iteration removes host paths from the built-in module-object
worker payload. The owner compiler resolves and reads each canonical module,
then submits its raw source together with validated project function-record
chunks. The isolated worker parses that source, lowers it without filesystem
capability, and returns the existing linker-ready compact object record.
Compiler-owned payload construction lives in focused worker-input and
worker-source modules; AiVM behavior is unchanged.

The compact structural codec now preserves stable node IDs and correctly
encodes lengths larger than one varint byte. These are semantic requirements
for transporting compiler records: kinds, attributes, and children alone are
not sufficient because canonical function symbols use node identity. A valid
two-module project built by the newly self-hosted compiler produces
byte-identical `.aibc1` output through the serial reference and VM-worker
pipelines.

The refreshed public Weather graph exposed one owner-side portability bug:
absolute local-development package paths from `ailang.lock.toml` were being
prefixed with the project directory. Absolute-path classification now lives in
the focused linker path module, and the linker has a regression covering an
external absolute package root. No package-resolution policy was added to
AiVM.

With that correction, Weather builds through both the serial self-host
reference and the built-in worker pipeline. Both paths emit the same
214,324-byte `.aibc1` with SHA-256
`7c86601954fa17c0c1b41e1b13bcf2f47f3e539c8d47eb60aaad08605f12297d`.
Using the same packaged self-host compiler and restored graph, the serial
reference build takes 199.78 seconds and the built-in worker build takes 80.17
seconds. That is a 119.61-second reduction, or 59.9 percent, while preserving
the final bytes.
Runtime launch creates the Weather window and reaches the live Open-Meteo TLS
boundary. An injected close event is observed, but network work continues and
the application does not terminate promptly, so close/shutdown acceptance
remains open.

Shutdown acceptance now passes. The debug host emits the same canonical
`closed` event as the platform UI hosts, and the Weather application routes a
main-window close through its focused shutdown module before AiVectra exits the
semantic loop. Any active HTTP operation is cancelled through the canonical
`sys.net.async.cancel` contract. The obsolete camel-case alias has been removed
from authored sources and runtime compatibility binding. The live Weather
launch observes `op=1 cancel`, returns success, and terminates in 0.41 seconds.

The clean-checkout bootstrap audit now stages an installed SDK without copying
its relative `bin/ailang` launcher out of context. Modern SDK launchers remain
bound to their installed SDK root, and published built-in command bytecode is
reused for package restore instead of recompiling those commands through an
older CLI contract. The clean-bootstrap regression covers both behaviors.

The default build reaches bootstrap linking from a checkout containing no
generated `tools/ailang` or `tools/aivm-runtime`, without invoking the legacy C
build. The latest installed published SDK, beta.53, cannot finish seeding this
branch: it predates the current nested modular compiler graph and reports
`AILANG021` while linking the generated bootstrap probe. A later relocated
release-candidate SDK supplies the current self-host seed and passes the clean
checkout proof described below.

The release-candidate SDK proof now passes from a detached clean checkout. The
relocated SDK supplies its compiled AiLang CLI, built-in commands, module-object
worker, and AiVM runtime; the default build does not invoke `build.sh legacy`,
recompile the native launcher, or select artifacts by checkout-relative host
paths. Generation completes in 662 seconds and self-hosted built-ins in 44
seconds. The generation-one and generation-two CLI artifacts are byte-identical
at 622,083 bytes with SHA-256
`af23bda0882568dc704922f71e1d0e3072cf54e4856becc5e341662a7c9cb9da`.

The fixed 16, 32, and 64 MiB tooling byte-arena ceilings have been removed.
AiVM now compacts dead phase-local bytes before growing pressure-aware hosted
backing, spills completed unobserved worker results to reloadable temporary
storage, releases materialized batch framing, and reduces physical worker
dispatch as available memory falls. Production and debug remain bounded. A
full default self-host completes generation in 630 seconds and seven built-ins in 62
seconds; generation-one and generation-two remain byte-identical at 622,083
bytes with SHA-256
`af23bda0882568dc704922f71e1d0e3072cf54e4856becc5e341662a7c9cb9da`.
The build also reuses a prior local self-host CLI and module-object worker when
an installed bootstrap catalog is absent, preventing stale native-runtime
refresh from falling back to the obsolete modular-link probe.

The compiled `parse-check.aibc1` built-in now parses the ordered authored AOS
corpus through `parse.parseDocument`. The canonical formatting gate invokes
that bytecode command through AiVM, and the standalone `tools/aos_frontend.c`
source, native build helper, SDK staging, and CI/release matrix artifacts have
been removed. The migration also corrected the generated command registry by
removing non-AOS comment syntax discovered by the self-host parser.

The self-hosted parser corpus gate passes on macOS, Linux, and Windows release
hosts. The direct Windows native build now reserves the same 16 MiB stack as
the existing AiVM CMake build, and parser newline literals use explicit escape
sequences so Git checkout line-ending conversion cannot change their semantic
value. A native PowerShell gate parses the full Windows corpus and verifies the
canonical malformed-input diagnostic without relying on a POSIX compatibility
shell. These changes remain host/build mechanics and do not add parser policy
to AiVM. Broader Windows execution coverage remains a focused AiVM
host-boundary item; it must not reintroduce a C parser or duplicate parsing
semantics in the runtime.

## Acceptance Criteria

- [ ] `lower.aos` is a thin facade; lowering families live in focused modules.
- [x] Full compiler-file self-hosted parser gate passes.
- [ ] Supported compiler modules lower to deterministic AiBCO1 objects.
- [ ] Objects link deterministically into executable AiBC1.
- [x] Self-hosted and bootstrap paths have automated parity coverage.
- [x] Supported compiler/tool sources build through the self-hosted path.
- [x] Weather builds and runs through self-hosted compilation without fallback.
- [x] No new compiler semantics or CLI commands were added to C.
- [x] All affected tests pass from a clean workspace.

## Deliverables

- focused lowering modules and a thin `lower.aos` facade
- regression and parity tests
- self-hosted compiler/module build evidence
- Weather end-to-end evidence
- a concise audit of remaining bootstrap dependencies, if any
