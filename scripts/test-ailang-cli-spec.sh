#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${ROOT_DIR}/scripts/aivm-native-paths.sh"
cd "${ROOT_DIR}"

SIBLING_AIVM_BIN="${ROOT_DIR}/../AiVM/.tmp/aivm-c-build-native/aivm"
if [[ -x "${SIBLING_AIVM_BIN}" ]]; then
  AIVM_BIN="${SIBLING_AIVM_BIN}"
else
  AIVM_BIN="$(require_aivm_bin)"
fi
TMP_DIR="${ROOT_DIR}/.tmp/ailang-cli-spec-smoke"
CLI_BYTECODE_DIR="${TMP_DIR}/cli-bytecode"
APP_DIR="${TMP_DIR}/app"
BASIC_CLI_DIR="${TMP_DIR}/basic-cli"
BUILD_DIR="${TMP_DIR}/build"
BASIC_CLI_BUILD_DIR="${TMP_DIR}/basic-cli-build"
LOCAL_BUILD_DIR="${TMP_DIR}/local-build"
PUBLISH_DIR="${TMP_DIR}/publish"
SELF_CONTAINED_PUBLISH_DIR="${TMP_DIR}/publish-self-contained"
FAKE_INSTALL_ROOT="${TMP_DIR}/fake-sdk"
BAD_NO_ENTRY_FILE_DIR="${TMP_DIR}/bad-no-entry-file"
BAD_NO_ENTRY_EXPORT_DIR="${TMP_DIR}/bad-no-entry-export"
BAD_MISSING_SOURCE_DIR="${TMP_DIR}/bad-missing-source"
BAD_UNDECLARED_PACKAGE_IMPORT_DIR="${TMP_DIR}/bad-undeclared-package-import"
GOOD_DECLARED_PACKAGE_IMPORT_DIR="${TMP_DIR}/good-declared-package-import"

run_aivm_program() {
  local program="$1"
  local status
  shift
  set +e
  "${AIVM_BIN}" "${program}" "$@" >/tmp/ailang-cli-spec-probe.out 2>/tmp/ailang-cli-spec-probe.err
  status=$?
  set -e
  if [[ "${status}" -eq 64 ]] && rg -q 'aivm run <program\\.aibc1>' /tmp/ailang-cli-spec-probe.err; then
    "${AIVM_BIN}" run "${program}" "$@"
    return $?
  fi
  cat /tmp/ailang-cli-spec-probe.out
  cat /tmp/ailang-cli-spec-probe.err >&2
  return "${status}"
}

rm -rf "${TMP_DIR}"
mkdir -p "${CLI_BYTECODE_DIR}"

./tools/ailang build src/cli/ailang.aos --out "${CLI_BYTECODE_DIR}" --no-cache >/dev/null

HELP_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help)"
printf '%s\n' "${HELP_OUT}" | rg -q 'Usage: ailang <command> \[options\]'
printf '%s\n' "${HELP_OUT}" | rg -q 'Commands: init, template, agent, build, run, publish, clean, project, version, help'

HELP_BUILD_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help build)"
printf '%s\n' "${HELP_BUILD_OUT}" | rg -q 'Usage: ailang build <project-dir> \[--out <dir>\]'

HELP_PROJECT_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help project)"
printf '%s\n' "${HELP_PROJECT_OUT}" | rg -q 'Usage: ailang project version <project-dir>'

VERSION_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" --version)"
printf '%s\n' "${VERSION_OUT}" | rg -q '^ailang 0\.0\.1-beta\.10$'

TEMPLATE_LIST_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" template list)"
printf '%s\n' "${TEMPLATE_LIST_OUT}" | rg -q 'name = "cli"'
printf '%s\n' "${TEMPLATE_LIST_OUT}" | rg -q 'name = "cli-args"'

TEMPLATE_SHOW_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" template show cli-args)"
printf '%s\n' "${TEMPLATE_SHOW_OUT}" | rg -q 'name = "cli-args"'
printf '%s\n' "${TEMPLATE_SHOW_OUT}" | rg -q 'entry_file = "src/app.aos"'

TEMPLATE_PATH_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" template path cli)"
printf '%s\n' "${TEMPLATE_PATH_OUT}" | rg -q '^templates/projects/cli$'

run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" init "${APP_DIR}" --template cli-args --agents all >/dev/null
test -f "${APP_DIR}/project.aiproj"
test -f "${APP_DIR}/src/app.aos"
test -f "${APP_DIR}/AGENTS.md"
test -f "${APP_DIR}/CLAUDE.md"
test -f "${APP_DIR}/GEMINI.md"
test -f "${APP_DIR}/.cursor/rules/ailang.mdc"
test -f "${APP_DIR}/.github/copilot-instructions.md"
test -f "${APP_DIR}/.windsurfrules"
perl -0pi -e 's{\Q'"${APP_DIR}"': no app args\E}{app: no app args}' "${APP_DIR}/src/app.aos"

PROJECT_VERSION_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" project version "${APP_DIR}")"
printf '%s\n' "${PROJECT_VERSION_OUT}" | rg -q '^0\.0\.1$'

run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${APP_DIR}" --out "${BUILD_DIR}" >/dev/null
test -f "${BUILD_DIR}/app.aibc1"
test -f "${APP_DIR}/obj/link-report.aos"
test -f "${APP_DIR}/obj/linked-bundle.aos"
test -f "${APP_DIR}/obj/build-input-report.aos"
test -f "${APP_DIR}/obj/bytecode-emitter-report.aos"
test -f "${APP_DIR}/obj/app.bytecode.aos"
rg -q 'LinkReport#linker_report\(moduleCount=1\)' "${APP_DIR}/obj/link-report.aos"
rg -q 'Bundle#b1\(entryExport="start" entryFile="src/app.aos"' "${APP_DIR}/obj/linked-bundle.aos"
rg -q 'CHILD_COUNT' "${APP_DIR}/obj/app.bytecode.aos"
rg -q 'JUMP_IF_FALSE' "${APP_DIR}/obj/app.bytecode.aos"
rg -q 'ATTR_VALUE_STRING' "${APP_DIR}/obj/app.bytecode.aos"
rg -q 'status="ok"' "${APP_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'output="app.aibc1"' "${APP_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'status="bytecode"' "${APP_DIR}/obj/build-input-report.aos"
rg -q 'input="obj/app.aibc1"' "${APP_DIR}/obj/build-input-report.aos"
APP_NO_ARGS_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1")"
printf '%s\n' "${APP_NO_ARGS_OUT}" | rg -q '^app: no app args$'
APP_WITH_ARG_OUT="$("${AIVM_BIN}" "${BUILD_DIR}/app.aibc1" alpha)"
printf '%s\n' "${APP_WITH_ARG_OUT}" | rg -q '^alpha$'

run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" init "${BASIC_CLI_DIR}" --template cli >/dev/null
run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${BASIC_CLI_DIR}" --out "${BASIC_CLI_BUILD_DIR}" >/dev/null
test -f "${BASIC_CLI_BUILD_DIR}/app.aibc1"
test -f "${BASIC_CLI_DIR}/obj/app.bytecode.aos"
test -f "${BASIC_CLI_DIR}/obj/build-input-report.aos"
test -f "${BASIC_CLI_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'sys.stdout.writeLine' "${BASIC_CLI_DIR}/obj/app.bytecode.aos"
rg -q 'Hello from .*/basic-cli[.]' "${BASIC_CLI_DIR}/obj/app.bytecode.aos"
rg -q 'status="ok"' "${BASIC_CLI_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'output="app.aibc1"' "${BASIC_CLI_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'status="bytecode"' "${BASIC_CLI_DIR}/obj/build-input-report.aos"
rg -q 'input="obj/app.aibc1"' "${BASIC_CLI_DIR}/obj/build-input-report.aos"

mkdir -p "${FAKE_INSTALL_ROOT}/local/bin"
ln -sf "${ROOT_DIR}/tools/ailang" "${FAKE_INSTALL_ROOT}/local/bin/ailang"
mkdir -p "${FAKE_INSTALL_ROOT}/local/runtimes/host"
cp "${AIVM_BIN}" "${FAKE_INSTALL_ROOT}/local/runtimes/host/aivm"
chmod +x "${FAKE_INSTALL_ROOT}/local/runtimes/host/aivm"
cat > "${APP_DIR}/ailang-toolchain.toml" <<'EOF'
[toolchain]
version = "local"
EOF
AILANG_INSTALL_ROOT="${FAKE_INSTALL_ROOT}" run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${APP_DIR}" --out "${LOCAL_BUILD_DIR}" >/dev/null
test -f "${LOCAL_BUILD_DIR}/app.aibc1"

export AILANG_INSTALL_ROOT="${FAKE_INSTALL_ROOT}"
rm -rf "${APP_DIR}/obj"
run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" publish "${APP_DIR}" --out "${PUBLISH_DIR}" >/dev/null
test -f "${APP_DIR}/obj/link-report.aos"
test -f "${APP_DIR}/obj/linked-bundle.aos"
test -f "${APP_DIR}/obj/bytecode-emitter-report.aos"
test -f "${PUBLISH_DIR}/bin/app"
test -f "${PUBLISH_DIR}/bin/app.cmd"
test -f "${PUBLISH_DIR}/lib/ailang/app/app.aibe"
test -f "${PUBLISH_DIR}/lib/ailang/app/ailang.publish.toml"
printf '%s\n' "$(cat "${PUBLISH_DIR}/lib/ailang/app/ailang.publish.toml")" | rg -q 'mode = "framework-dependent"'

run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" publish "${APP_DIR}" --mode self-contained --target host --out "${SELF_CONTAINED_PUBLISH_DIR}" >/dev/null
test -f "${SELF_CONTAINED_PUBLISH_DIR}/bin/app"
test -f "${SELF_CONTAINED_PUBLISH_DIR}/bin/app.cmd"
test -f "${SELF_CONTAINED_PUBLISH_DIR}/lib/ailang/app/app.aibe"
test -f "${SELF_CONTAINED_PUBLISH_DIR}/lib/ailang/app/runtime/aivm"
cmp "${FAKE_INSTALL_ROOT}/local/runtimes/host/aivm" "${SELF_CONTAINED_PUBLISH_DIR}/lib/ailang/app/runtime/aivm"
test -f "${SELF_CONTAINED_PUBLISH_DIR}/lib/ailang/app/ailang.publish.toml"
printf '%s\n' "$(cat "${SELF_CONTAINED_PUBLISH_DIR}/lib/ailang/app/ailang.publish.toml")" | rg -q 'target = "host"'
sh "${SELF_CONTAINED_PUBLISH_DIR}/bin/app" >/dev/null

NO_TARGET_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" publish "${APP_DIR}" --mode self-contained --out "${TMP_DIR}/publish-no-target" 2>&1 || true)"
printf '%s\n' "${NO_TARGET_OUT}" | rg -q 'code=AILANG017'

BAD_TARGET_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" publish "${APP_DIR}" --mode self-contained --target unknown-rid --out "${TMP_DIR}/publish-bad-target" 2>&1 || true)"
printf '%s\n' "${BAD_TARGET_OUT}" | rg -q 'code=AILANG020'

UNAVAILABLE_TARGET_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" publish "${APP_DIR}" --mode self-contained --target linux-x64 --out "${TMP_DIR}/publish-linux-x64" 2>&1 || true)"
printf '%s\n' "${UNAVAILABLE_TARGET_OUT}" | rg -q 'code=AILANG019'
unset AILANG_INSTALL_ROOT

run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" run "${APP_DIR}" >/dev/null
AIVM="${AIVM_BIN}" run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" run "${BUILD_DIR}/app.aibc1" >/dev/null

mkdir -p "${APP_DIR}/bin" "${APP_DIR}/dist" "${APP_DIR}/.toolchain"
touch "${APP_DIR}/bin/app.aibc1" "${APP_DIR}/dist/app.aibc1" "${APP_DIR}/.toolchain/cache"
run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" clean "${APP_DIR}" >/dev/null
test ! -e "${APP_DIR}/bin"
test ! -e "${APP_DIR}/dist"
test ! -e "${APP_DIR}/.toolchain"

mkdir -p "${BAD_NO_ENTRY_FILE_DIR}"
cat > "${BAD_NO_ENTRY_FILE_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="bad" entryExport="start")
}
EOF
BAD_NO_ENTRY_FILE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${BAD_NO_ENTRY_FILE_DIR}" 2>&1 || true)"
printf '%s\n' "${BAD_NO_ENTRY_FILE_OUT}" | rg -q 'code=AILANG008'

mkdir -p "${BAD_NO_ENTRY_EXPORT_DIR}"
cat > "${BAD_NO_ENTRY_EXPORT_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="bad" entryFile="src/app.aos")
}
EOF
BAD_NO_ENTRY_EXPORT_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${BAD_NO_ENTRY_EXPORT_DIR}" 2>&1 || true)"
printf '%s\n' "${BAD_NO_ENTRY_EXPORT_OUT}" | rg -q 'code=AILANG009'

mkdir -p "${BAD_MISSING_SOURCE_DIR}"
cat > "${BAD_MISSING_SOURCE_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="bad" entryFile="src/missing.aos" entryExport="start")
}
EOF
BAD_MISSING_SOURCE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${BAD_MISSING_SOURCE_DIR}" 2>&1 || true)"
printf '%s\n' "${BAD_MISSING_SOURCE_OUT}" | rg -q 'code=AILANG010'

mkdir -p "${BAD_UNDECLARED_PACKAGE_IMPORT_DIR}/src"
cat > "${BAD_UNDECLARED_PACKAGE_IMPORT_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="bad" entryFile="src/app.aos" entryExport="start")
}
EOF
cat > "${BAD_UNDECLARED_PACKAGE_IMPORT_DIR}/src/app.aos" <<'EOF'
Program#p1 {
  Import#import1(package="missing-package" path="src/lib.aos")
  Export#export1(name=start)
  Let#let1(name=start) {
    Fn#fn1(params=args) {
      Block#block1 {
        Return#return1 { Lit#lit1(value=0) }
      }
    }
  }
}
EOF
BAD_UNDECLARED_PACKAGE_IMPORT_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${BAD_UNDECLARED_PACKAGE_IMPORT_DIR}" 2>&1 || true)"
printf '%s\n' "${BAD_UNDECLARED_PACKAGE_IMPORT_OUT}" | rg -q 'code=RUN024'

mkdir -p "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/src" "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/.ailang/packages/local-lib/src"
cat > "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="good" entryFile="src/app.aos" entryExport="start") {
    Include#include1(name="local-lib" version="0.0.1" path=".ailang/packages/local-lib")
  }
}
EOF
cat > "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/ailang.lock.toml" <<'EOF'
[[package]]
name = "local-lib"
version = "0.0.1"
path = ".ailang/packages/local-lib"
packageRoot = "."
EOF
cat > "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/src/app.aos" <<'EOF'
Program#p1 {
  Import#import1(package="local-lib" path="src/lib.aos")
  Export#export1(name=start)
  Let#let1(name=start) {
    Fn#fn1(params=args) {
      Block#block1 {
        Return#return1 { Lit#lit1(value=0) }
      }
    }
  }
}
EOF
cat > "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/.ailang/packages/local-lib/src/lib.aos" <<'EOF'
Program#libp1 {
  Export#libe1(name=answer)
  Let#libl1(name=answer) {
    Fn#libf1(params=args) {
      Block#libb1 {
        Return#libr1 { Lit#libi1(value=42) }
      }
    }
  }
}
EOF
run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" build "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}" --out "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/bin" >/dev/null
test -f "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/bin/app.aibc1"
test -f "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/link-report.aos"
test -f "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/linked-bundle.aos"
test -f "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/app.bytecode.aos"
test -f "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/bytecode-emitter-report.aos"
rg -q 'package:local-lib/src/lib.aos' "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/link-report.aos"
rg -q 'package:local-lib/src/lib.aos' "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/linked-bundle.aos"
rg -q 'Bytecode#bc1' "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/app.bytecode.aos"
rg -q 'status="ok"' "${GOOD_DECLARED_PACKAGE_IMPORT_DIR}/obj/bytecode-emitter-report.aos"
