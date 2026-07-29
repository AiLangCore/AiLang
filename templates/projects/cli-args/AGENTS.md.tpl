# Agent Rules

- Build with ailang build.
- Run with ailang run.
- Keep generated output out of source control.
- Prefer focused semantic `.aos` modules over expanding large entry, facade, or
  host/runtime files.
- Host/runtime changes must remain mechanical and must not introduce language,
  library, parsing, validation, formatting, or application semantics.
- Do not create or continue "blob" files. Split unrelated responsibilities into
  modules with clear imports and exports.
