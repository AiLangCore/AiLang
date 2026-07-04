#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/bytecode-emitter-module"
APP="${TMP_DIR}/app.aos"
OUT="${TMP_DIR}/out.txt"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/return-int.aos" <<'AOS'
Program#entry {
  Export#e1(name="entry")
  Let#l1(name="entry") {
    Fn#f1(params="args") {
      Block#b1 {
        Return#r1 { Lit#i1(value=7) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/stdout-return.aos" <<'AOS'
Program#entry {
  Export#e2(name="entry")
  Let#l2(name="entry") {
    Fn#f2(params="args") {
      Block#b4 {
        Call#c1(target="sys.stdout.writeLine") { Lit#s1(value="hello") }
        Return#r2 { Lit#i2(value=0) }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/unsupported-string-return.aos" <<'AOS'
Program#entry {
  Export#e3(name="entry")
  Let#l3(name="entry") {
    Fn#f3(params="args") {
      Block#b6 {
        Return#r3 { Lit#s2(value="unsupported") }
      }
    }
  }
}
AOS

cat > "${TMP_DIR}/cli-args.aos" <<'AOS'
Program#entry {
  Export#e4(name="entry")
  Let#l4(name="entry") {
    Fn#f4(params="args") {
      Block#b8 {
        Let#l5(name=count) { ChildCount#cc1 { Var#v1(name=args) } }
        If#if1 {
          Eq#eq1 { Var#v2(name=count) Lit#i3(value=0) }
          Block#b9 {
            Call#c2(target=sys.stdout.writeLine) { Lit#s3(value="no args") }
            Return#r4 { Lit#i4(value=0) }
          }
          Block#b10 {
            Call#c3(target=sys.stdout.writeLine) {
              AttrValueString#avs1 {
                ChildAt#ca1 { Var#v3(name=args) Lit#i5(value=0) }
                Lit#i6(value=0)
              }
            }
            Return#r5 { Lit#i7(value=0) }
          }
        }
      }
    }
  }
}
AOS

cat > "${APP}" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/compiler/bytecode.aos")
  Import#test_i3(path="../../src/std/bytes.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=start) {
    Fn#test_f1(params=args) {
      Block#test_b1 {
        Let#test_l2(name=program) {
          Call#test_c1(target=parse.parseDocument) {
            Call#test_c1r(target=bytes.toUtf8String) {
              Call#test_c1f(target=sys.fs.file.read) {
                Lit#test_i1(value=".tmp/bytecode-emitter-module/return-int.aos")
              }
            }
          }
        }
        Let#test_l3(name=bytecodeText) {
          Call#test_c2(target=bytecode.buildEntryReturnIntMainText) {
            Var#test_v1(name=program)
            Lit#test_i2(value="entry")
          }
        }
        Call#test_p1(target=sys.stdout.writeLine) {
          AttrValueString#test_avs1 {
            Var#test_v2(name=bytecodeText)
            Lit#test_i2a(value=0)
          }
        }

        Let#test_l4(name=stdoutProgram) {
          Call#test_c3(target=parse.parseDocument) {
            Call#test_c3r(target=bytes.toUtf8String) {
              Call#test_c3f(target=sys.fs.file.read) {
                Lit#test_i6(value=".tmp/bytecode-emitter-module/stdout-return.aos")
              }
            }
          }
        }
        Let#test_l5(name=stdoutResult) {
          Call#test_c4(target=bytecode.buildEntryReturnIntMainText) {
            Var#test_v3(name=stdoutProgram)
            Lit#test_i7(value="entry")
          }
        }
        Call#test_p2(target=sys.stdout.writeLine) {
          AttrValueString#test_avs2 {
            Var#test_v4(name=stdoutResult)
            Lit#test_i8(value=0)
          }
        }

        Let#test_l6(name=unsupportedProgram) {
          Call#test_c5(target=parse.parseDocument) {
            Call#test_c5r(target=bytes.toUtf8String) {
              Call#test_c5f(target=sys.fs.file.read) {
                Lit#test_i11(value=".tmp/bytecode-emitter-module/unsupported-string-return.aos")
              }
            }
          }
        }
        Let#test_l7(name=unsupportedResult) {
          Call#test_c6(target=bytecode.buildEntryReturnIntMainText) {
            Var#test_v5(name=unsupportedProgram)
            Lit#test_i12(value="entry")
          }
        }
        Call#test_p3(target=sys.stdout.writeLine) {
          NodeKind#test_nk1 { Var#test_v6(name=unsupportedResult) }
        }

        Let#test_l8(name=cliArgsProgram) {
          Call#test_c7(target=parse.parseDocument) {
            Call#test_c7r(target=bytes.toUtf8String) {
              Call#test_c7f(target=sys.fs.file.read) {
                Lit#test_i16(value=".tmp/bytecode-emitter-module/cli-args.aos")
              }
            }
          }
        }
        Let#test_l9(name=cliArgsResult) {
          Call#test_c8(target=bytecode.buildEntryReturnIntMainText) {
            Var#test_v7(name=cliArgsProgram)
            Lit#test_i17(value="entry")
          }
        }
        Call#test_p4(target=sys.stdout.writeLine) {
          AttrValueString#test_avs3 {
            Var#test_v8(name=cliArgsResult)
            Lit#test_i18(value=0)
          }
        }

        Return#test_r1 { Lit#test_i19(value=0) }
      }
    }
  }
}
AOS

./tools/ailang run "${APP}" > "${OUT}"

rg -F -q 'Bytecode#bc1(flags=0 format="AiBC1" magic="AIBC" version=2) { Const#k0(kind=int value=7) Func#f_main(name=main) { Inst#i0(a=0 op=CONST) Inst#i1(op=RETURN) } }' "${OUT}"
rg -F -q 'Bytecode#bc1(flags=0 format="AiBC1" magic="AIBC" version=2) { Const#k0(kind=string value="sys.stdout.writeLine") Const#k1(kind=string value="hello") Const#k2(kind=int value=0) Func#f_main(name=main) { Inst#i0(a=0 op=CONST) Inst#i1(a=1 op=CONST) Inst#i2(a=1 op=CALL_SYS) Inst#i3(op=POP) Inst#i4(a=2 op=CONST) Inst#i5(op=RETURN) } }' "${OUT}"
rg -q '^Err$' "${OUT}"
rg -q 'CHILD_COUNT' "${OUT}"
rg -q 'JUMP_IF_FALSE' "${OUT}"
rg -q 'ATTR_VALUE_STRING' "${OUT}"
rg -q 'params="argv"' "${OUT}"

echo "bytecode-emitter-module-ok"
