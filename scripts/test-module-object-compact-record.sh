#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/module-object-compact-record"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src" "${TMP_DIR}/stage"

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Import(path="dep.aos")
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=input) { Lit(value=7) }
        Return { Call(target=answer) { Lit(value=7) } }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/src/dep.aos" <<'AOS'
Program {
  Export(name=answer)
  Let(name=answer) {
    Fn(params=value) {
      Block {
        Let(name=enabled) { Lit(value=true) }
        If {
          Var(name=enabled)
          Block { Return { Add { Var(name=value) Lit(value=35) } } }
          Block { Return { Lit(value=-1) } }
        }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/verify.aos" <<AOS
Program {
  Import(path="../../src/compiler/format.aos")
  Import(path="../../src/compiler/linker.aos")
  Import(path="../../src/compiler/object_linker.aos")
  Import(path="../../src/compiler/parser.aos")
  Import(path="../../src/compiler/structural_project_incremental.aos")
  Import(path="../../src/compiler/structural_project_worker_inputs.aos")
  Import(path="../../src/compiler/structural_record_codec.aos")
  Import(path="../../src/compiler/workers/module_object.aos")
  Import(path="../../src/std/bytes.aos")
  Export(name=start)

  Let(name=start) {
    Fn() {
      Block {
        Let(name=entry) {
          Call(target=parse.parseDocument) {
            Call(target=bytes.toUtf8String) {
              Call(target=sys.fs.file.read) {
                Lit(value="${TMP_DIR}/src/app.aos")
              }
            }
          }
        }
        Let(name=paths) {
          Call(target=linker.collectProjectModulePaths) {
            Lit(value="${TMP_DIR}") Var(name=entry) Lit(value="src/app.aos")
          }
        }
        Let(name=records) {
          Call(target=structuralProject.prepareWorkerProjectRecords) {
            Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="")
          }
        }
        If {
          Eq { NodeKind { Var(name=records) } Lit(value="Err") }
          Block { Return { Lit(value=10) } }
          Block { Lit(value=0) }
        }
        Let(name=expectedObjects) {
          Call(target=structuralProject.writeProjectObjectFilesIncremental) {
            Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="")
            Lit(value="${TMP_DIR}/objects")
          }
        }
        Let(name=actualObjects) {
          Call(target=verify.collectWorkerRecords) {
            Var(name=paths) Lit(value="${TMP_DIR}") Lit(value="")
            Var(name=records) ChildCount { Var(name=paths) } Lit(value=0)
            MakeBlock { Lit(value="objects") }
          }
        }
        Let(name=expectedBytes) {
          Call(target=verify.linkObjects) { Var(name=expectedObjects) }
        }
        Let(name=actualBytes) {
          Call(target=verify.linkObjects) { Var(name=actualObjects) }
        }
        Let(name=firstExpected) {
          ChildAt { Var(name=expectedObjects) Lit(value=0) }
        }
        Let(name=firstEncoded) {
          Call(target=structuralRecord.encode) { Var(name=firstExpected) }
        }
        Call(target=sys.stdout.writeLine) {
          StrConcat {
            Lit(value="compact-record-bytes=")
            StrConcat {
              ToString { Call(target=bytes.length) { Var(name=firstEncoded) } }
              StrConcat {
                Lit(value=" formatted-record-bytes=")
                ToString {
                  Call(target=bytes.length) {
                    Call(target=bytes.fromUtf8String) {
                      Call(target=format.format) { Var(name=firstExpected) }
                    }
                  }
                }
              }
            }
          }
        }
        If {
          Eq {
            Call(target=bytes.toBase64) { Var(name=expectedBytes) }
            Call(target=bytes.toBase64) { Var(name=actualBytes) }
          }
          Block { Return { Lit(value=0) } }
          Block { Return { Lit(value=11) } }
        }
      }
    }
  }

  Let(name=verify.collectWorkerRecords) {
    Fn(params=paths,projectDir,lockText,records,count,index,objects) {
      Block {
        If {
          Eq { Var(name=index) Var(name=count) }
          Block { Return { Var(name=objects) } }
          Block {
            Let(name=payload) {
              AppendChild {
                AppendAttr {
                  AppendAttr {
                    AppendAttr {
                      MakeNode {
                        Lit(value="ModuleObjectTask")
                        StrConcat { Lit(value="module-") ToString { Var(name=index) } }
                      }
                      MakeLitInt { Lit(value="moduleIndex") Var(name=index) }
                    }
                    MakeLitString {
                      Lit(value="modulePath")
                      AttrValueString {
                        ChildAt { Var(name=paths) Var(name=index) } Lit(value=0)
                      }
                    }
                  }
                  MakeLitString {
                    Lit(value="moduleSource")
                    Call(target=bytes.toUtf8String) {
                      Call(target=sys.fs.file.read) {
                        StrConcat {
                          Var(name=projectDir)
                          StrConcat {
                            Lit(value="/")
                            AttrValueString {
                              ChildAt { Var(name=paths) Var(name=index) } Lit(value=0)
                            }
                          }
                        }
                      }
                    }
                  }
                }
                Var(name=records)
              }
            }
            Let(name=record) {
              Call(target=structuralRecord.decode) {
                Call(target=moduleObjectCompileRecordPayload) {
                  Call(target=structuralRecord.encode) { Var(name=payload) }
                }
              }
            }
            If {
              Eq { NodeKind { Var(name=record) } Lit(value="Err") }
              Block { Return { Var(name=record) } }
              Block {
                Return {
                  Call(target=verify.collectWorkerRecords) {
                    Var(name=paths) Var(name=projectDir) Var(name=lockText)
                    Var(name=records) Var(name=count)
                    Add { Var(name=index) Lit(value=1) }
                    AppendChild { Var(name=objects) Var(name=record) }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Let(name=verify.roundTripObjects) {
    Fn(params=objects,index,decoded) {
      Block {
        If {
          Eq { Var(name=index) ChildCount { Var(name=objects) } }
          Block { Return { Var(name=decoded) } }
          Block {
            Return {
              Call(target=verify.roundTripObjects) {
                Var(name=objects) Add { Var(name=index) Lit(value=1) }
                AppendChild {
                  Var(name=decoded)
                  Call(target=structuralRecord.decode) {
                    Call(target=structuralRecord.encode) {
                      ChildAt { Var(name=objects) Var(name=index) }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Let(name=verify.linkObjects) {
    Fn(params=objects) {
      Block {
        Let(name=functions) {
          Call(target=objectLinker.prependExecutableEntry) {
            Call(target=objectLinker.collectFunctions) { Var(name=objects) }
            Lit(value="src/app.aos::start")
          }
        }
        Return {
          Call(target=objectLinker.emitAibc1BytesWithWorkers) {
            Var(name=objects) Var(name=functions)
          }
        }
      }
    }
  }
}
AOS

OUT="$(
  cd "${ROOT_DIR}" &&
  AILANG_SDK_ROOT="${ROOT_DIR}/src" ./tools/ailang run "${TMP_DIR}/verify.aos"
)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
printf '%s\n' "${OUT}" | rg -F 'compact-record-bytes='

echo "module object compact record equivalence: PASS"
