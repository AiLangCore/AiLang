# Pre-Build Hooks for AiLang Build System

## Problem

The `std-cli` package needs to generate code (`commands.g.aos`) from command directories before the main compilation phase. Currently, the AiLang build system has no mechanism for running code generation tools before compilation.

## Solution: Pre-Build Hook System

Add support for pre-build hooks that can be declared in `project.aiproj` or triggered by package dependencies.

## Design Options

### Option 1: Package-Declared Pre-Build Tools (Recommended)

Packages can declare tools that should run during pre-build phase.

#### package.toml (std-cli)

```toml
schema = "ailang.package-source.v1"
name = "std-cli"
version = "0.0.1-alpha.1"
types = ["library", "tool"]

[libraries.cli]
namespace = "std.cli"
entry = "src/cli/common.aos"
exports = [...]

[tools.cli-codegen]
entry = "src/tools/codegen.aos"
export = "generate"
phase = "pre-build"
description = "Generate command registry from command.md files"
```

#### Build Flow

```text
1. ailang build <project>
2. Load project.aiproj
3. Resolve dependencies (including std-cli)
4. For each dependency with tools:
   a. Check if tool.phase == "pre-build"
   b. Run tool with project context
   c. Tool generates obj/std-cli/commands.g.aos
5. Continue with normal compilation including generated files
```

### Option 2: Project-Declared Pre-Build Scripts

Projects explicitly declare pre-build scripts in `project.aiproj`.

#### project.aiproj

```xml
Project(
  name="AiLang"
  entryFile="src/compiler/aic.aos"
  entryExport="main"
  version="0.0.1"
) {
  Include(package="std-cli" version="^0.0.1-alpha.1")

  PreBuild {
    Tool(package="std-cli" tool="cli-codegen")
  }
}
```

### Option 3: Convention-Based (Simplest for MVP)

If a dependency is named `std-cli` and project has command directories, automatically run code generation.

**Pros**: Zero configuration
**Cons**: Magic behavior, not extensible

## Recommended Approach: Hybrid

1. **Short-term (MVP)**: Convention-based detection
   - If `std-cli` is a dependency AND `src/cli/*/command.md` files exist
   - Auto-run code generation before build

2. **Long-term**: Package-declared tools
   - Packages declare tools with phase metadata
   - Build system runs tools at appropriate phase
   - Deterministic, explicit, extensible

## Implementation Plan

### Phase 1: Convention-Based MVP (Current Task)

1. **Detect std-cli dependency**
   ```aos
   Let(name=hasStdCliDependency) {
     Fn(params=manifestText) {
       // Check if manifest includes std-cli
     }
   }
   ```

2. **Detect command directories**
   ```aos
   Let(name=hasCommandDirectories) {
     Fn(params=projectPath) {
       // Check for src/cli/*/command.md pattern
     }
   }
   ```

3. **Run code generation**
   ```aos
   Let(name=runStdCliCodegen) {
     Fn(params=projectPath) {
       // Scan command directories
       // Parse command.md files
       // Generate obj/std-cli/commands.g.aos
     }
   }
   ```

4. **Update build command**
   ```aos
   Let(name=buildProject) {
     Fn(params=path,outDir) {
       Block {
         // ... existing code ...

         // NEW: Check for std-cli pre-build
         If {
           And {
             Call(target=hasStdCliDependency) { Var(name=manifestText) }
             Call(target=hasCommandDirectories) { Var(name=path) }
           }
           Block {
             Call(target=runStdCliCodegen) { Var(name=path) }
           }
           Block { Lit(value=0) }
         }

         // ... continue with normal build ...
       }
     }
   }
   ```

### Phase 2: Package Tool Support (Future)

1. **Extend package.toml schema**
   - Add `[tools.<name>]` section
   - Support `phase`, `entry`, `export` fields

2. **Update package resolution**
   - Discover tools during dependency resolution
   - Build tool execution graph

3. **Implement tool runner**
   - Execute tools in correct phase
   - Pass project context to tools
   - Capture tool output

4. **Add to project.aiproj schema**
   - `PreBuild{}`, `PostBuild{}` blocks
   - Explicit tool invocation

## std-cli Package Structure (Updated)

```text
std-cli/
├── package.toml
├── README.md
└── src/
    ├── cli/
    │   └── common.aos          # Runtime utilities (current)
    └── tools/
        ├── codegen.aos         # Pre-build code generator
        ├── parser.aos          # command.md parser
        └── registry.aos        # Registry generator
```

## Code Generation Tool (codegen.aos)

```aos
Program {
  Export(name=generate)

  Let(name=generate) {
    Fn(params=projectContext) {
      Block {
        // projectContext contains:
        // - projectPath
        // - manifestText
        // - dependencies
        // - outputDir (obj/)

        Let(name=commandDirs) {
          Call(target=scanCommandDirectories) {
            Var(name=projectContext)
          }
        }

        Let(name=commandMetadata) {
          Call(target=parseCommandFiles) {
            Var(name=commandDirs)
          }
        }

        Let(name=registryCode) {
          Call(target=generateRegistry) {
            Var(name=commandMetadata)
          }
        }

        Let(name=outputPath) {
          StrConcat {
            Var(name=projectPath)
            Lit(value="/obj/std-cli/commands.g.aos")
          }
        }

        Call(target=writeTextFile) {
          Var(name=outputPath)
          Var(name=registryCode)
        }

        Return { Lit(value=0) }
      }
    }
  }
}
```

## Generated Output Example

```aos
// obj/std-cli/commands.g.aos
// Generated by std-cli pre-build tool
// DO NOT EDIT

Program {
  Import(path="../../src/cli/Clean/clean.aos")
  Import(path="../../src/cli/Init/init.aos")
  Import(path="../../src/cli/Build/build.aos")

  Export(name=commandRegistry)
  Export(name=commandHelp)

  Let(name=commandRegistry) {
    Fn(params=_) {
      Block {
        Return {
          Map {
            Entry { Lit(value="clean") Var(name=runClean) }
            Entry { Lit(value="init") Var(name=runInit) }
            Entry { Lit(value="build") Var(name=runBuild) }
          }
        }
      }
    }
  }

  Let(name=commandHelp) {
    Fn(params=command) {
      Block {
        If {
          Eq { Var(name=command) Lit(value="clean") }
          Block {
            Call(target=sys.stdout.writeLine) {
              Lit(value="Usage: ailang clean <project-dir>")
            }
            Return { Lit(value=0) }
          }
          // ... other commands ...
        }
      }
    }
  }
}
```

## Build System Changes

### buildProject function (src/cli/ailang.aos)

Add pre-build hook execution before compilation:

```aos
Let(name=buildProject) {
  Fn(params=path,outDir) {
    Block {
      Let(name=manifestPath) { StrConcat { Var(name=path) Lit(value="/project.aiproj") } }

      If {
        Call(target=sys.fs.path.exists) { Var(name=manifestPath) }
        Block {
          Let(name=manifestText) { Call(target=readTextFile) { Var(name=manifestPath) } }

          // NEW: Pre-build hooks
          Call(target=runPreBuildHooks) { Var(name=path) Var(name=manifestText) }

          // Continue with existing build logic...
        }
        Block {
          Return {
            Call(target=buildError) {
              Lit(value="AILANG007")
              Lit(value="project.aiproj not found.")
              Lit(value="project")
            }
          }
        }
      }
    }
  }
}

Let(name=runPreBuildHooks) {
  Fn(params=projectPath,manifestText) {
    Block {
      // Check for std-cli dependency and command directories
      If {
        And {
          Call(target=hasStdCliDependency) { Var(name=manifestText) }
          Call(target=hasCommandDirectories) { Var(name=projectPath) }
        }
        Block {
          Call(target=runStdCliCodegen) { Var(name=projectPath) }
        }
        Block { Lit(value=0) }
      }
      Return { Lit(value=0) }
    }
  }
}
```

## Determinism Requirements

1. **Stable output**: Same inputs → same generated code
2. **No timestamps**: Generated files must not include timestamps
3. **Canonical formatting**: Generated code uses standard formatting
4. **Sorted entries**: Command registry entries in deterministic order (alphabetical)
5. **Reproducible**: Byte-identical output across builds

## Testing Strategy

1. **Unit tests**: Test code generator functions
2. **Integration tests**: Test full build with pre-build hooks
3. **Golden tests**: Verify generated code matches expected output
4. **Determinism tests**: Run multiple times, verify identical output

## Migration Path

1. ✅ **Phase 1a**: Create std-cli package structure (DONE)
2. **Phase 1b**: Implement command.md parser in std-cli
3. **Phase 1c**: Implement registry generator in std-cli
4. **Phase 1d**: Add convention-based pre-build to build command
5. **Phase 1e**: Test with AiLang CLI project
6. **Phase 2**: Design and implement formal tool system
7. **Phase 3**: Migrate to package-declared tools

## Open Questions

1. **Tool execution context**: What information should be passed to tools?
   - Project path, manifest, dependencies, output directory, ...

2. **Error handling**: How should build fail if pre-build tool fails?
   - Exit code, error messages, partial generation, ...

3. **Incremental builds**: Should pre-build tools support incremental generation?
   - Check modification times, cache generated files, ...

4. **Tool dependencies**: Can tools have dependencies?
   - Yes, tools are AiLang programs that can import packages

5. **Cross-project tools**: Can one project use another's tools?
   - Future: Yes, via package tool declarations

## References

- `std-cli` package: `ailang-core-packages/packages/std-cli/`
- Build command: `AiLang/src/cli/ailang.aos` (runBuild, buildProject)
- Design docs: `AiLang/Design/std-cli-future.md`
