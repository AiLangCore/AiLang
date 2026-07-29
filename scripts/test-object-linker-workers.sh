#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/object-linker-workers"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=first) {
          Call(target=parse.parseDocument) {
            StrConcat {
              Lit(value="Object(format=AiBCO1 version=1 modulePath=\"a.aos\") { WorkerDecl(name=alpha symbol=\"a.aos::worker::alpha\" targetSymbol=\"a.aos::compile\") { RequiredSyscall(target=\"sys.fs.file.read\") } Function(name=compile symbol=\"a.aos::compile\" params=payload) { Inst(op=STORE_LOCAL a=0) Inst(op=LOAD_LOCAL a=0) Inst(op=CALL a=0) ")
              Lit(value="Reloc(kind=call instruction=2 targetSymbol=\"a.aos::helper\") Inst(op=RETURN) } Function(name=helper symbol=\"a.aos::helper\" params=payload) { Inst(op=STORE_LOCAL a=0) Inst(op=LOAD_LOCAL a=0) Inst(op=RETURN) } }")
            }
          }
        }
        Let(name=second) {
          Call(target=parse.parseDocument) {
            Lit(value="Object(format=AiBCO1 version=1 modulePath=\"b.aos\") { WorkerDecl(name=beta symbol=\"b.aos::worker::beta\" targetSymbol=\"b.aos::compile\") Function(name=compile symbol=\"b.aos::compile\" params=payload) { Inst(op=RETURN) } }")
          }
        }
        Let(name=objects) {
          AppendChild {
            AppendChild { MakeBlock { Lit(value="objects") } Var(name=first) }
            Var(name=second)
          }
        }
        Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } }
        Let(name=catalog) {
          Call(target=objectLinker.collectWorkerCatalogPlan) {
            Var(name=objects) Var(name=functions)
          }
        }
        Let(name=closure) {
          Call(target=objectLinker.workerFunctionClosure) {
            Var(name=functions) Lit(value="a.aos::compile")
          }
        }
        If {
          Eq { ChildCount { Var(name=closure) } Lit(value=2) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=8) } }
        }
        Let(name=builtArtifacts) {
          Call(target=objectLinker.buildWorkerArtifacts) {
            Var(name=catalog) Var(name=functions)
          }
        }
        If {
          Eq { NodeKind { Var(name=builtArtifacts) } Lit(value="Err") }
          Block { Return { Lit(value=9) } }
          Block { Lit(value=0) }
        }
        Let(name=bundledBytes) {
          Call(target=objectLinker.emitAibc1BytesWithWorkers) {
            Var(name=objects) Var(name=functions)
          }
        }
        If {
          Eq { ValueKind { Var(name=bundledBytes) } Lit(value="bytes") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=10) } }
        }
        If {
          Eq { Call(target=bytes.at) { Var(name=bundledBytes) Lit(value=12) } Lit(value=3) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=11) } }
        }
        If {
          Eq { NodeKind { Var(name=catalog) } Lit(value="Err") }
          Block { Return { Lit(value=1) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { ChildCount { Var(name=catalog) } Lit(value=2) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          Eq { AttrValueInt { ChildAt { Var(name=catalog) Lit(value=0) } Lit(value=0) } Lit(value=0) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }
        If {
          Eq { AttrValueInt { ChildAt { Var(name=catalog) Lit(value=1) } Lit(value=0) } Lit(value=1) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=4) } }
        }
        Let(name=relocation) {
          Call(target=parse.parseDocument) {
            Lit(value="Reloc(kind=worker instruction=0 targetSymbol=\"b.aos::worker::beta\")")
          }
        }
        Let(name=resolved) {
          Call(target=objectLinker.resolveWorkerRelocation) {
            Var(name=catalog) Var(name=relocation)
          }
        }
        If {
          Eq { AttrValueInt { Var(name=resolved) Lit(value=0) } Lit(value=1) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=5) } }
        }

        Let(name=duplicateObjects) {
          AppendChild { Var(name=objects) Var(name=first) }
        }
        Let(name=duplicate) {
          Call(target=objectLinker.collectWorkerCatalogPlan) {
            Var(name=duplicateObjects) Var(name=functions)
          }
        }
        If {
          Eq { NodeKind { Var(name=duplicate) } Lit(value="Err") }
          Block { Lit(value=0) }
          Block { Return { Lit(value=6) } }
        }

        Let(name=missingRelocation) {
          Call(target=parse.parseDocument) {
            Lit(value="Reloc(kind=worker instruction=0 targetSymbol=\"missing::worker\")")
          }
        }
        Let(name=missing) {
          Call(target=objectLinker.resolveWorkerRelocation) {
            Var(name=catalog) Var(name=missingRelocation)
          }
        }
        If {
          Eq { NodeKind { Var(name=missing) } Lit(value="Err") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=7) } }
        }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "object linker workers: PASS"
