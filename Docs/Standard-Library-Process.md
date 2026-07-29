# `std.process`

Status: standard-library API.

`std/process.aos` is the public AiLang boundary for process and executable
operations. Application and package code should import this module instead of
calling `sys.process.*` directly.

## Low-level lifecycle

- `spawn(executable, arguments, workingDirectory, environment)` returns a
  process handle.
- `wait(handle)` returns the exit code and completes the process.
- `poll(handle)` observes completion without waiting.
- `kill(handle)` requests termination.
- `stdoutRead(handle)` and `stderrRead(handle)` return captured bytes.

Arguments and environment are node values whose children are ordered string
entries. The executable is passed separately; callers must not construct a
shell command string unless they explicitly intend to invoke a shell.

## Captured execution

`runCaptured(executable, arguments, workingDirectory, environment)` performs
the normal spawn, wait, stdout-read, and stderr-read lifecycle. It returns a
`ProcessResult` with:

- `exitCode`
- UTF-8 `stdout`
- UTF-8 `stderr`

Use `processResultExitCode`, `processResultStdoutText`, and
`processResultStderrText` to inspect the result.

Use the low-level byte-reading functions when output is not UTF-8.

## CLI integration

`std.cli` executable commands use this API with an explicitly resolved
executable or AiBC1 runtime artifact. Command resolution, argument policy, and
artifact selection remain `std.cli` semantics; process creation remains
`std.process` behavior backed by mechanical `sys.process.*` host operations.
