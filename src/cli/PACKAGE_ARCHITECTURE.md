# std-cli Package Architecture

## Key Decision: Optional Package, Not Standard Library

The `std-cli` package will be an **optional package**, not part of the core AiLang language or standard library.

### Location

- **Repository**: `ailang-core-packages` (https://github.com/AiLangCore/ailang-core-packages)
- **Package Registry**: `ailang-packages` (https://github.com/AiLangCore/ailang-packages)
- **Package Type**: Core optional package

### Rationale

1. **Separation of Concerns**
   - The AiLang language itself does not mandate CLI conventions
   - CLI framework is an application-level concern, not a language feature
   - Other CLI frameworks can be developed independently

2. **Independent Evolution**
   - `std-cli` can be versioned independently of the language
   - Breaking changes to `std-cli` don't affect language compatibility
   - Faster iteration on CLI conventions without language governance

3. **Reusability**
   - Any AiLang project can add `std-cli` as a dependency to build CLI tools
   - Not limited to the AiLang compiler's own CLI
   - Encourages ecosystem of CLI tools with consistent conventions

4. **Optional Dependency**
   - Projects that don't need CLI functionality don't pay for it
   - Smaller footprint for non-CLI applications
   - Clear dependency graph

### How It Will Work

#### AiLang CLI Project

The AiLang CLI will declare `std-cli` as a dependency in `project.aiproj`:

```xml
Project(
  name="AiLang"
  entryFile="src/compiler/aic.aos"
  entryExport="main"
  version="0.0.1"
) {
  Include(package="std-cli" version="^1.0.0")
}
```

#### Other Projects Using std-cli

Any AiLang project can build a CLI tool:

```xml
Project(
  name="MyCliTool"
  entryFile="src/app.aos"
  entryExport="main"
  version="1.0.0"
) {
  Include(package="std-cli" version="^1.0.0")
}
```

### Package Contents

The `std-cli` package will provide:

- **Command Metadata Parser** - Parse `command.md` front matter
- **Command Registry Generator** - Generate `commands.g.aos` from command directories
- **Argument Parser** - Type-safe argument and option parsing
- **Help Generator** - Generate help text from metadata
- **Command Dispatcher** - Route commands to implementations
- **Error Handling** - Standard CLI error patterns

### Comparison with Standard Library

| Feature | Standard Library (`std.*`) | Optional Package (`std-cli`) |
|---------|---------------------------|------------------------------|
| Location | `AiLang/src/std/` | `ailang-core-packages/packages/std-cli/` |
| Availability | Always available | Must be added as dependency |
| Versioning | Tied to language version | Independent semantic versioning |
| Governance | Language specification | Package maintainers |
| Use Case | Core language features | Application-level frameworks |

### Migration Path

1. **Phase 1** (Completed)
   - CLI structure refactored with command directories
   - Command documentation added
   - Sample commands extracted

2. **Phase 2** (Future)
   - Complete command extraction
   - Verify self-hosting

3. **Phase 3** (Future)
   - **Create `std-cli` package in `ailang-core-packages`**
   - Implement command framework in package
   - Publish to `ailang-packages` registry

4. **Phase 4** (Future)
   - Add `std-cli` dependency to AiLang CLI `project.aiproj`
   - Update CLI to use `std-cli` framework
   - Generate command registry using `std-cli`

5. **Phase 5** (Future)
   - External command support
   - Plugin architecture

### Benefits for AiLang Ecosystem

- **Consistency**: CLI tools can share conventions through `std-cli`
- **Best Practices**: Common patterns encoded in the package
- **Reduced Boilerplate**: Standard command infrastructure
- **Community Contribution**: Easier to contribute to CLI framework than language
- **Multiple Implementations**: Alternative CLI frameworks can coexist

## References

- Design document: `/Design/std-cli-future.md`
- Repository structure: `/src/cli/README.md`
- Refactoring summary: `/CLI_REFACTOR_SUMMARY.md`
- Package repository: https://github.com/AiLangCore/ailang-core-packages
- Package registry: https://github.com/AiLangCore/ailang-packages
