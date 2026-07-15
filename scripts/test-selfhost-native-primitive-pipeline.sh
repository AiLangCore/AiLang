#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/selfhost-native-primitive-pipeline"
AILANG_BIN="${AILANG_BIN:-${ROOT_DIR}/tools/ailang}"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}/src"

cat > "${TMP_DIR}/project.aiproj" <<'AOS'
Program {
  Project(name="native-primitive-pipeline" entryFile="src/app.aos" entryExport="start")
}
AOS

cat > "${TMP_DIR}/src/app.aos" <<'AOS'
Program {
  Export(name=start)
  Let(name=start) {
    Fn() {
      Block {
        Let(name=attribute) { MakeLitBool { Lit(value="enabled") Lit(value=true) } }
        Let(name=node) { MakeNode { Lit(value="Demo") Lit(value="demo-node") } }
        Let(name=withAttribute) { AppendAttr { Var(name=node) Var(name=attribute) } }
        Let(name=kind) { NodeKind { Var(name=withAttribute) } }
        Let(name=id) { NodeId { Var(name=withAttribute) } }
        Let(name=text) { ToString { Var(name=kind) } }
        Let(name=escaped) { StrEscape { Var(name=text) } }
        Let(name=slice) { StringSlice { Var(name=escaped) Lit(value=0) Lit(value=4) } }
        Let(name=found) { StringFind { Var(name=escaped) Lit(value="mo") Lit(value=0) } }
        Let(name=attributeKind) { AttrValueKind { Var(name=withAttribute) Lit(value=0) } }
        Let(name=attributeValue) { AttrValueBool { Var(name=withAttribute) Lit(value=0) } }
        Let(name=pair) { MakePair { Var(name=kind) Var(name=id) } }
        Let(name=pairKind) { ValueKind { Var(name=pair) } }
        Let(name=first) { PairFirst { Var(name=pair) } }
        Let(name=second) { PairSecond { Var(name=pair) } }
        Let(name=attributeCount) { AttrCount { Var(name=withAttribute) } }
        Return { Eq { Var(name=pairKind) Lit(value="pair") } }
      }
    }
  }
}
AOS

"${AILANG_BIN}" run "${ROOT_DIR}/src/cli/ailang.aos" -- build "${TMP_DIR}"
test -f "${TMP_DIR}/obj/module-0.aibco"
test -f "${TMP_DIR}/bin/app.aibc1"

for opcode in NODE_KIND NODE_ID VALUE_KIND TO_STRING STR_ESCAPE STR_SUBSTRING STR_FIND ATTR_VALUE_KIND ATTR_VALUE_BOOL MAKE_LIT_BOOL MAKE_NODE MAKE_PAIR PAIR_FIRST PAIR_SECOND; do
  rg -Fq "op=\"${opcode}\"" "${TMP_DIR}/obj/module-0.aibco"
done

OUT="$("${AILANG_BIN}" run "${TMP_DIR}/bin/app.aibc1" || true)"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=bool value=true)'

echo 'self-hosted native primitive pipeline: PASS'
