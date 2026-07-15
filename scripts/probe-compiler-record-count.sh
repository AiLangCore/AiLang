#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_PATH="${1:?usage: probe-compiler-record-count.sh <source.aos>}"
TMP_DIR="${ROOT_DIR}/.tmp/probe-compiler-record-count"

rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

cat > "${TMP_DIR}/probe.aos" <<AOS
Program { Import(path="../../src/compiler/parser.aos") Import(path="../../src/compiler/lower.aos") Import(path="../../src/std/bytes.aos") Export(name=start) Let(name=start) { Fn() { Block { Let(name=source) { Call(target=bytes.toUtf8String) { Call(target=io.readFile) { Lit(value="${SOURCE_PATH}") } } } Let(name=program) { Call(target=parse.parseDocument) { Var(name=source) } } Return { ChildCount { Call(target=lower.collectFunctionRecords) { Var(name=program) Lit(value="${SOURCE_PATH}") } } } } } } }
AOS

cd "${ROOT_DIR}"
./tools/ailang run "${TMP_DIR}/probe.aos" || true
