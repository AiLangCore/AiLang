#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-call-relocation-validation"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/validate.aos" <<'AOS'
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=object) { Call(target=parse.parseDocument) { Lit(value="Object(format=AiBCO1 version=1 modulePath=\"app.aos\") { Function(name=start symbol=\"app.aos::start\" params=\"\") { Inst(op=CALL a=0) Reloc(kind=call instruction=0 targetSymbol=\"missing.aos::helper\") Inst(op=RETURN a=0) } }") } } Let(name=objects) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=object) } } Let(name=functions) { Call(target=objectLinker.collectFunctions) { Var(name=objects) } } Let(name=result) { Call(target=objectLinker.validateSupported) { Var(name=functions) } } If { Eq { NodeKind { Var(name=result) } Lit(value="Err") } Block { Return { Lit(value=0) } } Block { Return { Lit(value=1) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/validate.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'object linker call relocation validation: PASS'
