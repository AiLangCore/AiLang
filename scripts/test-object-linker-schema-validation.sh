#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="${ROOT_DIR}/.tmp/object-linker-schema-validation"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/validate.aos" <<'AOS'
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/object_linker.aos") Export(name=start) Let(name=check) { Fn(params=text) { Block { Let(name=object) { Call(target=parse.parseDocument) { Var(name=text) } } Let(name=result) { Call(target=objectLinker.collectFunctions) { AppendChild { MakeBlock { Lit(value="objects") } Var(name=object) } } } If { Eq { NodeKind { Var(name=result) } Lit(value="Err") } Block { Return { Lit(value=0) } } Block { Return { Lit(value=1) } } } } } } Let(name=start) { Fn() { Block { Let(name=badFormat) { Call(target=check) { Lit(value="Object(format=AiBCO2 version=1 modulePath=\"app.aos\") { }") } } If { Eq { Var(name=badFormat) Lit(value=0) } Block { Lit(value=0) } Block { Return { Lit(value=1) } } } Let(name=badVersion) { Call(target=check) { Lit(value="Object(format=AiBCO1 version=2 modulePath=\"app.aos\") { }") } } If { Eq { Var(name=badVersion) Lit(value=0) } Block { Lit(value=0) } Block { Return { Lit(value=2) } } } Let(name=badExport) { Call(target=check) { Lit(value="Object(format=AiBCO1 version=1 modulePath=\"app.aos\") { Export(name=\"start\" symbol=\"other.aos::start\") }") } } If { Eq { Var(name=badExport) Lit(value=0) } Block { Return { Lit(value=0) } } Block { Return { Lit(value=3) } } } } } } }
AOS

OUT="$(cd "${ROOT_DIR}" && ./tools/ailang run "${TMP_DIR}/validate.aos")"
printf '%s\n' "${OUT}" | rg -Fq 'Ok#ok1(type=int value=0)'
echo 'object linker schema validation: PASS'
