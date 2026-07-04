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
PACKAGE_RESTORE_DIR="${TMP_DIR}/package-restore-app"
PACKAGE_RESTORE_BAD_DIR="${TMP_DIR}/package-restore-bad-app"
PACKAGE_RESTORE_DUP_DIR="${TMP_DIR}/package-restore-dup-app"
PACKAGE_RESTORE_CYCLE_DIR="${TMP_DIR}/package-restore-cycle-app"
PACKAGE_REGISTRY_DIR="${TMP_DIR}/package-registry"
PACKAGE_SOURCE_REPO="${TMP_DIR}/package-source-repo"

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
printf '%s\n' "${HELP_OUT}" | rg -q 'Commands: init, template, agent, build, run, publish, clean, package, project, version, help'

HELP_BUILD_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help build)"
printf '%s\n' "${HELP_BUILD_OUT}" | rg -q 'Usage: ailang build <project-dir> \[--out <dir>\]'

HELP_PROJECT_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help project)"
printf '%s\n' "${HELP_PROJECT_OUT}" | rg -q 'Usage: ailang project version <project-dir>'

HELP_PACKAGE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" help package)"
printf '%s\n' "${HELP_PACKAGE_OUT}" | rg -Fq 'Usage: ailang package <restore|list|add|remove> [project-dir]'

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

cat > "${APP_DIR}/ailang.lock.toml" <<'EOF'
schema = "ailang.lock.v1"

[[package]]
name = "std-app"
version = "0.0.1"
namespaces = ["std.app"]
EOF
PACKAGE_LIST_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package list "${APP_DIR}")"
printf '%s\n' "${PACKAGE_LIST_OUT}" | rg -q 'schema = "ailang.lock.v1"'
printf '%s\n' "${PACKAGE_LIST_OUT}" | rg -q 'name = "std-app"'
printf '%s\n' "${PACKAGE_LIST_OUT}" | rg -q 'namespaces = \["std.app"\]'
PACKAGE_ADD_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package add std-json@0.0.1 "${APP_DIR}")"
printf '%s\n' "${PACKAGE_ADD_OUT}" | rg -q 'package-added'
rg -q 'Include\(name="std-json" version="0\.0\.1"\)' "${APP_DIR}/project.aiproj"
PACKAGE_ADD_DUP_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package add std-json@0.0.1 "${APP_DIR}" 2>&1 || true)"
printf '%s\n' "${PACKAGE_ADD_DUP_OUT}" | rg -q 'code=PKG005'
PACKAGE_REMOVE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package remove std-json "${APP_DIR}")"
printf '%s\n' "${PACKAGE_REMOVE_OUT}" | rg -q 'package-removed'
! rg -q 'Include\(name="std-json"' "${APP_DIR}/project.aiproj"
PACKAGE_REMOVE_MISSING_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package remove std-json "${APP_DIR}" 2>&1 || true)"
printf '%s\n' "${PACKAGE_REMOVE_MISSING_OUT}" | rg -q 'code=PKG007'
rm -f "${APP_DIR}/ailang.lock.toml"

mkdir -p "${PACKAGE_SOURCE_REPO}/packages/std-app/src" "${PACKAGE_SOURCE_REPO}/packages/std-core/src" "${PACKAGE_REGISTRY_DIR}/packages" "${PACKAGE_RESTORE_DIR}/src"
cat > "${PACKAGE_SOURCE_REPO}/packages/std-app/package.toml" <<'EOF'
schema = "ailang.package-source.v1"
name = "std-app"
version = "0.0.1"
types = ["library"]

[dependencies]
std-core = "0.0.1"

[libraries.app]
namespace = "std.app"
entry = "src/app.aos"
exports = ["hello"]
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/std-app/src/app.aos" <<'EOF'
Program#p1 {
  Export#export1(name=hello)
  Let#let1(name=hello) {
    Fn#fn1(params=_) {
      Block#block1 {
        Return#return1 { Lit#lit1(value="hello") }
      }
    }
  }
}
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/std-core/package.toml" <<'EOF'
schema = "ailang.package-source.v1"
name = "std-core"
version = "0.0.1"
types = ["library"]

[libraries.core]
namespace = "std.core"
entry = "src/core.aos"
exports = ["ok"]
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/std-core/src/core.aos" <<'EOF'
Program#p1 {
  Export#export1(name=ok)
  Let#let1(name=ok) {
    Fn#fn1(params=_) {
      Block#block1 {
        Return#return1 { Lit#lit1(value=1) }
      }
    }
  }
}
EOF
git -C "${PACKAGE_SOURCE_REPO}" init -q
git -C "${PACKAGE_SOURCE_REPO}" add packages/std-app/package.toml packages/std-app/src/app.aos packages/std-core/package.toml packages/std-core/src/core.aos
git -C "${PACKAGE_SOURCE_REPO}" -c user.name=AiLang -c user.email=ailang@example.invalid commit -q -m "Add std-app fixture"
PACKAGE_SOURCE_COMMIT="$(git -C "${PACKAGE_SOURCE_REPO}" rev-parse HEAD)"
cat > "${PACKAGE_REGISTRY_DIR}/packages/std-app.toml" <<EOF
schema = "ailang.package.v1"
name = "std-app"
repo = "${PACKAGE_SOURCE_REPO}"
packageRoot = "packages/std-app"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1"

[versions."0.0.1"]
ref = "main"
commit = "${PACKAGE_SOURCE_COMMIT}"
EOF
cat > "${PACKAGE_REGISTRY_DIR}/packages/std-core.toml" <<EOF
schema = "ailang.package.v1"
name = "std-core"
repo = "${PACKAGE_SOURCE_REPO}"
packageRoot = "packages/std-core"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1"

[versions."0.0.1"]
ref = "main"
commit = "${PACKAGE_SOURCE_COMMIT}"
EOF
cat > "${PACKAGE_RESTORE_DIR}/config.local.toml" <<EOF
packageRegistry = "${PACKAGE_REGISTRY_DIR}"
EOF
cat > "${PACKAGE_RESTORE_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="restore-fixture" entryFile="src/app.aos" entryExport="start") {
    Include(name="std-app" version="0.0.1")
  }
}
EOF
cat > "${PACKAGE_RESTORE_DIR}/src/app.aos" <<'EOF'
Program#p1 {
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
PACKAGE_RESTORE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package restore "${PACKAGE_RESTORE_DIR}")"
printf '%s\n' "${PACKAGE_RESTORE_OUT}" | rg -q 'Ok#ok1\(type=int value=2\)'
test -f "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
test -f "${PACKAGE_RESTORE_DIR}/.ailang/packages/std-app/packages/std-app/package.toml"
test -f "${PACKAGE_RESTORE_DIR}/.ailang/packages/std-core/packages/std-core/package.toml"
rg -q 'name = "std-app"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q 'name = "std-core"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q 'path = ".ailang/packages/std-app"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q 'path = ".ailang/packages/std-core"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q 'packageRoot = "packages/std-app"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q 'packageRoot = "packages/std-core"' "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"
rg -q "commit = \"${PACKAGE_SOURCE_COMMIT}\"" "${PACKAGE_RESTORE_DIR}/ailang.lock.toml"

mkdir -p "${PACKAGE_RESTORE_BAD_DIR}/src"
cat > "${PACKAGE_RESTORE_BAD_DIR}/config.local.toml" <<EOF
packageRegistry = "${PACKAGE_REGISTRY_DIR}"
EOF
cat > "${PACKAGE_RESTORE_BAD_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="restore-bad-fixture" entryFile="src/app.aos" entryExport="start") {
    Include(name="missing-package" version="0.0.1")
  }
}
EOF
cat > "${PACKAGE_RESTORE_BAD_DIR}/src/app.aos" <<'EOF'
Program#p1 {
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
PACKAGE_RESTORE_BAD_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package restore "${PACKAGE_RESTORE_BAD_DIR}" 2>&1 || true)"
printf '%s\n' "${PACKAGE_RESTORE_BAD_OUT}" | rg -q 'code=PKG004'
test ! -f "${PACKAGE_RESTORE_BAD_DIR}/ailang.lock.toml"

mkdir -p "${PACKAGE_RESTORE_DUP_DIR}/src"
cat > "${PACKAGE_RESTORE_DUP_DIR}/config.local.toml" <<EOF
packageRegistry = "${PACKAGE_REGISTRY_DIR}"
EOF
cat > "${PACKAGE_RESTORE_DUP_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="restore-dup-fixture" entryFile="src/app.aos" entryExport="start") {
    Include(name="std-app" version="0.0.1")
    Include(name="std-app" version="0.0.1")
  }
}
EOF
cat > "${PACKAGE_RESTORE_DUP_DIR}/src/app.aos" <<'EOF'
Program#p1 {
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
PACKAGE_RESTORE_DUP_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package restore "${PACKAGE_RESTORE_DUP_DIR}" 2>&1 || true)"
printf '%s\n' "${PACKAGE_RESTORE_DUP_OUT}" | rg -q 'code=PKG004'
test ! -f "${PACKAGE_RESTORE_DUP_DIR}/ailang.lock.toml"

mkdir -p "${PACKAGE_SOURCE_REPO}/packages/cycle-a/src" "${PACKAGE_SOURCE_REPO}/packages/cycle-b/src" "${PACKAGE_RESTORE_CYCLE_DIR}/src"
cat > "${PACKAGE_SOURCE_REPO}/packages/cycle-a/package.toml" <<'EOF'
schema = "ailang.package-source.v1"
name = "cycle-a"
version = "0.0.1"
types = ["library"]

[dependencies]
cycle-b = "0.0.1"

[libraries.cycle_a]
namespace = "cycle.a"
entry = "src/a.aos"
exports = ["a"]
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/cycle-a/src/a.aos" <<'EOF'
Program#p1 {
  Export#export1(name=a)
  Let#let1(name=a) {
    Fn#fn1(params=_) {
      Block#block1 {
        Return#return1 { Lit#lit1(value=1) }
      }
    }
  }
}
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/cycle-b/package.toml" <<'EOF'
schema = "ailang.package-source.v1"
name = "cycle-b"
version = "0.0.1"
types = ["library"]

[dependencies]
cycle-a = "0.0.1"

[libraries.cycle_b]
namespace = "cycle.b"
entry = "src/b.aos"
exports = ["b"]
EOF
cat > "${PACKAGE_SOURCE_REPO}/packages/cycle-b/src/b.aos" <<'EOF'
Program#p1 {
  Export#export1(name=b)
  Let#let1(name=b) {
    Fn#fn1(params=_) {
      Block#block1 {
        Return#return1 { Lit#lit1(value=2) }
      }
    }
  }
}
EOF
git -C "${PACKAGE_SOURCE_REPO}" add packages/cycle-a/package.toml packages/cycle-a/src/a.aos packages/cycle-b/package.toml packages/cycle-b/src/b.aos
git -C "${PACKAGE_SOURCE_REPO}" -c user.name=AiLang -c user.email=ailang@example.invalid commit -q -m "Add package cycle fixture"
PACKAGE_CYCLE_COMMIT="$(git -C "${PACKAGE_SOURCE_REPO}" rev-parse HEAD)"
cat > "${PACKAGE_REGISTRY_DIR}/packages/cycle-a.toml" <<EOF
schema = "ailang.package.v1"
name = "cycle-a"
repo = "${PACKAGE_SOURCE_REPO}"
packageRoot = "packages/cycle-a"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1"

[versions."0.0.1"]
ref = "main"
commit = "${PACKAGE_CYCLE_COMMIT}"
EOF
cat > "${PACKAGE_REGISTRY_DIR}/packages/cycle-b.toml" <<EOF
schema = "ailang.package.v1"
name = "cycle-b"
repo = "${PACKAGE_SOURCE_REPO}"
packageRoot = "packages/cycle-b"
license = "MIT"
types = ["library"]
defaultVersion = "0.0.1"

[versions."0.0.1"]
ref = "main"
commit = "${PACKAGE_CYCLE_COMMIT}"
EOF
cat > "${PACKAGE_RESTORE_CYCLE_DIR}/config.local.toml" <<EOF
packageRegistry = "${PACKAGE_REGISTRY_DIR}"
EOF
cat > "${PACKAGE_RESTORE_CYCLE_DIR}/project.aiproj" <<'EOF'
Program#p1 {
  Project#proj1(name="restore-cycle-fixture" entryFile="src/app.aos" entryExport="start") {
    Include(name="cycle-a" version="0.0.1")
  }
}
EOF
cat > "${PACKAGE_RESTORE_CYCLE_DIR}/src/app.aos" <<'EOF'
Program#p1 {
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
PACKAGE_RESTORE_CYCLE_OUT="$(run_aivm_program "${CLI_BYTECODE_DIR}/app.aibc1" package restore "${PACKAGE_RESTORE_CYCLE_DIR}" 2>&1 || true)"
printf '%s\n' "${PACKAGE_RESTORE_CYCLE_OUT}" | rg -q 'code=PKG004'
test ! -f "${PACKAGE_RESTORE_CYCLE_DIR}/ailang.lock.toml"

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

mkdir -p "${FAKE_INSTALL_ROOT}/local/bin" "${FAKE_INSTALL_ROOT}/local/libexec/ailang/cli"
cp "${AIVM_BIN}" "${FAKE_INSTALL_ROOT}/local/bin/aivm"
chmod +x "${FAKE_INSTALL_ROOT}/local/bin/aivm"
cp "${CLI_BYTECODE_DIR}/app.aibc1" "${FAKE_INSTALL_ROOT}/local/libexec/ailang/cli/app.aibc1"
cat > "${FAKE_INSTALL_ROOT}/local/bin/ailang" <<'EOF'
#!/usr/bin/env sh
set -eu
SDK_ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
export AILANG_SDK_ROOT="$SDK_ROOT"
exec "$SDK_ROOT/bin/aivm" "$SDK_ROOT/libexec/ailang/cli/app.aibc1" "$@"
EOF
chmod +x "${FAKE_INSTALL_ROOT}/local/bin/ailang"
if file "${FAKE_INSTALL_ROOT}/local/bin/ailang" | grep -Eiq 'Mach-O|ELF|PE32'; then
  echo "fake SDK fixture must use a non-C ailang shim" >&2
  exit 1
fi
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
