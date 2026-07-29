#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TMP_DIR="${ROOT_DIR}/.tmp/parser-selfhost-stdlib-files"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/app.aos" <<'AOS'
Program#test_p1 {
  Import#test_i1(path="../../src/compiler/parser.aos")
  Import#test_i2(path="../../src/std/bytes.aos")
  Export#test_e1(name=start)

  Let#test_l1(name=fail) {
    Fn#test_f1(params=message) {
      Block#test_b1 {
        Call#test_c1(target=sys.stdout.writeLine) { Var#test_v1(name=message) }
        Return#test_r1 { Lit#test_i1(value=1) }
      }
    }
  }

  Let#test_l2(name=start) {
    Fn#test_f2(params=args) {
      Block#test_b2 {
        Let#test_l3(name=sourcePathNode) { ChildAt#test_ca_source_arg { Var#test_args(name=args) Lit#test_arg_i0(value=0) } }
        Let#test_l4(name=sourcePath) {
          AttrValueString#test_avs_source_arg {
            Var#test_source_path_node(name=sourcePathNode)
            Lit#test_arg_i1(value=0)
          }
        }
        Let#test_l5(name=sourceText) {
          Call#test_c2(target=bytes.toUtf8String) {
            Call#test_c3(target=sys.fs.file.read) {
              Var#test_source_path(name=sourcePath)
            }
          }
        }
        Let#test_l6(name=program) { Call#test_c4(target=parse.parseDocument) { Var#test_v2(name=sourceText) } }
        If#test_if1 {
          Eq#test_e1 {
            NodeKind#test_nk1 { Var#test_program(name=program) }
            Lit#test_i2(value="Program")
          }
          Block#test_b3 { Lit#test_i3(value=0) }
          Block#test_b4 { Return#test_r2 { Call#test_c5(target=fail) { Lit#test_i4(value="stdlib file root kind failed") } } }
        }
        If#test_if2 {
          Eq#test_e2 {
            ChildCount#test_cc1 { Var#test_program_child_count(name=program) }
            Lit#test_i5(value=0)
          }
          Block#test_b5 { Return#test_r3 { Call#test_c6(target=fail) { Lit#test_i6(value="stdlib file child count failed") } } }
          Block#test_b6 { Lit#test_i7(value=0) }
        }
        If#test_if3 {
          Eq#test_e3 {
            Var#test_source_path_number(name=sourcePath)
            Lit#test_i8(value="src/std/number.aos")
          }
          Block#test_b7 {
            Let#test_l7(name=firstNode) { ChildAt#test_ca1 { Var#test_v3(name=program) Lit#test_i9(value=0) } }
            If#test_if4 {
              Eq#test_e4 { NodeKind#test_nk2 { Var#test_v4(name=firstNode) } Lit#test_i10(value="Import") }
              Block#test_b8 { Lit#test_i11(value=0) }
              Block#test_b9 { Return#test_r4 { Call#test_c7(target=fail) { Lit#test_i12(value="stdlib number first child kind failed") } } }
            }
            If#test_if5 {
              Eq#test_e5 { AttrValueString#test_avs1 { Var#test_v5(name=firstNode) Lit#test_i13(value=0) } Lit#test_i14(value="./str.aos") }
              Block#test_b10 { Lit#test_i15(value=0) }
              Block#test_b11 { Return#test_r5 { Call#test_c8(target=fail) { Lit#test_i16(value="stdlib number import path failed") } } }
            }
          }
          Block#test_b12 { Lit#test_i17(value=0) }
        }
        Call#test_c9(target=sys.stdout.writeLine) { Lit#test_i18(value="parser-selfhost-stdlib-files-ok") }
        Return#test_r6 { Lit#test_i19(value=0) }
      }
    }
  }
}
AOS

while IFS= read -r SOURCE_PATH; do
  OUT="$(./tools/ailang run "${TMP_DIR}/app.aos" -- "${SOURCE_PATH}")"
  printf '%s\n' "${OUT}" | rg -Fq 'parser-selfhost-stdlib-files-ok'
  printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
done < <(find src/std -maxdepth 1 -name '*.aos' | sort)
