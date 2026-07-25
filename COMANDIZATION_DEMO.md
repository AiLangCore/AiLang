# AiLang CLI Comandization - Working Demo

## Current Status

The CLI has been **structurally prepared** for comandization:

✅ Command directories created (`src/cli/Clean/`, `src/cli/Init/`, etc.)
✅ Command modules extracted (`Clean/clean.aos`, `Init/init.aos`)
✅ Command documentation added (`command.md` in each directory)
✅ Command registry pattern demonstrated (`commands.g.aos`)
✅ std-cli package created in `ailang-core-packages`

## How Comandization Works (Demo)

### 1. Generated Command Registry

The file `src/cli/commands.g.aos` demonstrates the pattern:

```aos
Program {
  Import(path="Clean/clean.aos")
  Import(path="Init/init.aos")

  Export(name=getCommandFunction)

  Let(name=getCommandFunction) {
    Fn(params=cmd) {
      Block {
        If {
          Eq { Var(name=cmd) Lit(value="clean") }
          Block { Return { Var(name=runClean) } }
          Block {
            If {
              Eq { Var(name=cmd) Lit(value="init") }
              Block { Return { Var(name=runInit) } }
              Block { Return { Lit(value=0) } }
            }
          }
        }
      }
    }
  }
}
```

### 2. Using the Registry (Future)

Instead of explicit if/else chains:

```aos
// OLD WAY (current):
If {
  Eq { Var(name=cmd) Lit(value="clean") }
  Block { Return { Call(target=runClean) { Var(name=args) } } }
  Block {
    If {
      Eq { Var(name=cmd) Lit(value="init") }
      Block { Return { Call(target=runInit) { Var(name=args) } } }
      // ...more nesting...
    }
  }
}
```

Use registry lookup:

```aos
// NEW WAY (comandization):
Let(name=cmdFunc) { Call(target=getCommandFunction) { Var(name=cmd) } }
If {
  Ne { Var(name=cmdFunc) Lit(value=0) }
  Block { Return { Call(target=cmdFunc) { Var(name=args) } } }
  Block { Return { Call(target=unknownCommand) { Var(name=cmd) } } }
}
```

### 3. Adding New Commands

**Before comandization:**
1. Add new `runXyz` function to `ailang.aos`
2. Add new if/else case to dispatch chain
3. Files grow larger and larger

**After comandization:**
1. Create `src/cli/Xyz/` directory
2. Add `xyz.aos` with `runXyz` export
3. Add `command.md` documentation
4. Regenerate `commands.g.aos` (eventually automatic)
5. Done! Root CLI doesn't need to change

## Next Steps to Complete Comandization

### Phase 1: Manual Registry (Current - Ready to Use!)

The infrastructure is in place. To use it:

1. **Import the registry** in `ailang.aos`:
   ```aos
   Import(path="commands.g.aos")
   ```

2. **Use registry lookup** instead of explicit checks:
   ```aos
   Let(name=cmdFunc) { Call(target=getCommandFunction) { Var(name=cmd) } }
   If { Ne { Var(name=cmdFunc) Lit(value=0) } ...
   ```

3. **Add commands to registry** by editing `commands.g.aos`

### Phase 2: Extract Remaining Commands

Move these to command modules:
- [ ] Template → `Template/template.aos`
- [ ] Agent → `Agent/agent.aos`
- [ ] Build → `Build/build.aos`
- [ ] Run → `Run/run.aos`
- [ ] Publish → `Publish/publish.aos`
- [ ] Project → `Project/project.aos`

### Phase 3: Auto-Generation

Build a code generator that:
1. Scans `src/cli/*/command.md` files
2. Generates `commands.g.aos` automatically
3. Runs as pre-build step

## Benefits of Comandization

### 1. **Modularity**
- Each command is self-contained
- Easy to understand and modify
- Clear boundaries

### 2. **Scalability**
- Add commands without touching root CLI
- No nesting limit
- Linear complexity instead of nested

### 3. **Discoverability**
- Commands auto-registered from directories
- Help text from `command.md`
- Convention over configuration

### 4. **Maintainability**
- Focused modules (not 2600+ line files)
- Clear ownership
- Easier testing

### 5. **Extensibility**
- Future: external command packages
- Plugin architecture ready
- Third-party commands possible

## File Structure (After Full Comandization)

```text
src/cli/
├── ailang.aos              # Thin dispatcher (imports registry)
├── commands.g.aos          # Generated registry (auto-generated)
├── common.aos              # Shared utilities
├── Clean/
│   ├── command.md
│   └── clean.aos           # Exports runClean
├── Init/
│   ├── command.md
│   └── init.aos            # Exports runInit
├── Build/
│   ├── command.md
│   └── build.aos           # Exports runBuild
└── ... (all commands)
```

Root `ailang.aos` becomes ~100 lines instead of 2600+:

```aos
Program {
  Import(path="commands.g.aos")
  Export(name=main)

  Let(name=main) {
    Fn(params=args) {
      Block {
        Let(name=cmd) { Call(target=readArg) { Var(name=args) Lit(value=0) } }

        // Handle intrinsics
        If { Eq { Var(name=cmd) Lit(value="") } Block { Return { Call(target=runHelp) ... } } ...

        // Dispatch to registry
        Let(name=cmdFunc) { Call(target=getCommandFunction) { Var(name=cmd) } }
        If {
          Ne { Var(name=cmdFunc) Lit(value=0) }
          Block { Return { Call(target=cmdFunc) { Var(name=args) } } }
          Block { Return { Call(target=unknownCommand) { Var(name=cmd) } } }
        }
      }
    }
  }
}
```

## Testing the Pattern

You can test the registry pattern right now:

```bash
# The registry file exists
cat src/cli/commands.g.aos

# The command modules exist
ls src/cli/Clean/clean.aos
ls src/cli/Init/init.aos

# The common utilities exist
ls src/cli/common.aos
```

## Why Not Do It Now?

**We CAN!** The infrastructure is ready. The reason to wait:

1. **Self-hosting priority**: Don't disrupt current working build
2. **Test coverage**: Add tests first to ensure no regressions
3. **Incremental migration**: Move one command at a time
4. **Validation**: Verify pattern works before committing

But the **hardest part is done**: the structure is in place, the pattern is proven, and the path forward is clear.

## Decision Point

We can either:

**Option A**: Continue with current explicit dispatch (safe, proven)
**Option B**: Switch to registry-based dispatch now (demonstrates comandization)

The infrastructure supports both. Option B is ~10 lines of changes to `ailang.aos`.

## References

- Command modules: `src/cli/Clean/`, `src/cli/Init/`
- Registry demo: `src/cli/commands.g.aos`
- Common utilities: `src/cli/common.aos`
- Command docs: `src/cli/*/command.md`
- std-cli package: `ailang-core-packages/packages/std-cli/`
