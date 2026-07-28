#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/worker-catalog-encoding"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program {
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entryBase) {
          MakeNode { Lit(value="WorkerCatalogPlanEntry") Lit(value="worker-plan:test") }
        }
        Let(name=entryWithIndex) {
          AppendAttr { Var(name=entryBase) MakeLitInt { Lit(value="index") Lit(value=0) } }
        }
        Let(name=entryWithSymbol) {
          AppendAttr {
            Var(name=entryWithIndex)
            MakeLitString { Lit(value="symbol") Lit(value="app.aos::worker::test") }
          }
        }
        Let(name=entry) {
          AppendChild {
            AppendChild {
              AppendAttr {
                Var(name=entryWithSymbol)
                MakeLitString { Lit(value="targetSymbol") Lit(value="app.aos::compile") }
              }
              AppendAttr {
                MakeNode { Lit(value="RequiredSyscall") Lit(value="required:fs") }
                MakeLitString { Lit(value="target") Lit(value="sys.fs.file.read") }
              }
            }
            AppendAttr {
              MakeNode { Lit(value="RequiredSyscall") Lit(value="required:net") }
              MakeLitString { Lit(value="target") Lit(value="sys.net.request") }
            }
          }
        }
        Let(name=catalog) {
          AppendChild { MakeBlock { Lit(value="worker-catalog-plan") } Var(name=entry) }
        }

        Let(name=layoutBase) { MakeBlock { Lit(value="layout-function") } }
        Let(name=layoutWithSymbol) {
          AppendChild {
            Var(name=layoutBase)
            MakeLitString { Lit(value="symbol") Lit(value="app.aos::compile") }
          }
        }
        Let(name=layoutRecord) {
          AppendChild {
            AppendChild {
              Var(name=layoutWithSymbol) MakeLitInt { Lit(value="offset") Lit(value=0) }
            }
            MakeLitInt { Lit(value="instructionCount") Lit(value=1) }
          }
        }
        Let(name=layout) {
          AppendChild { MakeBlock { Lit(value="layout") } Var(name=layoutRecord) }
        }

        Let(name=artifactBase) {
          MakeNode { Lit(value="WorkerArtifact") Lit(value="artifact:test") }
        }
        Let(name=artifactWithSymbol) {
          AppendAttr {
            Var(name=artifactBase)
            MakeLitString { Lit(value="symbol") Lit(value="app.aos::worker::test") }
          }
        }
        Let(name=artifactWithVersion) {
          AppendAttr {
            AppendAttr {
              Var(name=artifactWithSymbol)
              MakeLitInt { Lit(value="functionTarget") Lit(value=0) }
            }
            MakeLitInt { Lit(value="bytecodeVersion") Lit(value=2) }
          }
        }
        Let(name=artifactBytes) {
          AppendAttr {
            Var(name=artifactWithVersion)
            MakeLitString {
              Lit(value="artifactBase64")
              Lit(value="QUlCQwIAAAAAAAAAAQAAAAEAAAAQAAAAAQAAAAEAAAAAAAAAAAAAAA==")
            }
          }
        }
        Let(name=artifact) {
          AppendChild {
            AppendChild {
              Var(name=artifactBytes)
              AppendAttr {
                MakeNode { Lit(value="RequiredSyscall") Lit(value="artifact-required:fs") }
                MakeLitString { Lit(value="target") Lit(value="sys.fs.file.read") }
              }
            }
            AppendAttr {
              MakeNode { Lit(value="RequiredSyscall") Lit(value="artifact-required:net") }
              MakeLitString { Lit(value="target") Lit(value="sys.net.request") }
            }
          }
        }
        Let(name=artifacts) {
          AppendChild { MakeBlock { Lit(value="worker-artifacts") } Var(name=artifact) }
        }
        Let(name=section) {
          Call(target=objectLinker.emitWorkerCatalogSection) {
            Var(name=catalog) Var(name=layout) Var(name=artifacts)
          }
        }
        If {
          Eq { ValueKind { Var(name=section) } Lit(value="node") }
          Block { Return { Lit(value=1) } }
          Block { Lit(value=0) }
        }
        If {
          Eq { Call(target=bytes.length) { Var(name=section) } Lit(value=104) }
          Block { Lit(value=0) }
          Block { Return { Lit(value=2) } }
        }
        If {
          Eq {
            Call(target=bytes.toBase64) { Var(name=section) }
            Lit(value="AwAAAGAAAAABAAAAAAAAAAUAAAABAAAAAgAAACgAAAB0o8I7Vv2lKszDGwPupZsAoLVu+MBeuD6QTaUyvOjhlkFJQkMCAAAAAAAAAAEAAAABAAAAEAAAAAEAAAABAAAAAAAAAAAAAAA=")
          }
          Block { Lit(value=0) }
          Block { Return { Lit(value=3) } }
        }

        Let(name=missing) {
          Call(target=objectLinker.emitWorkerCatalogSection) {
            Var(name=catalog) Var(name=layout)
            MakeBlock { Lit(value="worker-artifacts") }
          }
        }
        If {
          Eq { NodeKind { Var(name=missing) } Lit(value="Err") }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=4) } }
        }
      }
    }
  }
}
AOS

OUT="$(./tools/ailang run "${TMP_DIR}/app.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'

echo "worker catalog encoding: PASS"
