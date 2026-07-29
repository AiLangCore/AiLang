#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${1:?self-host project directory is required}"
SELECTION_MODE="${2:-worker}"
STD_CLI_DIR="${AILANG_STD_CLI_SOURCE_DIR:-${ROOT_DIR}/../ailang-core-packages/packages/std-cli}"

if [[ ! -f "${STD_CLI_DIR}/package.toml" ]]; then
  echo "self-host build requires std-cli package source: ${STD_CLI_DIR}" >&2
  exit 1
fi

mkdir -p "${PROJECT_DIR}/.ailang/packages"
cp -R "${ROOT_DIR}/src" "${PROJECT_DIR}/src"
case "${SELECTION_MODE}" in
  worker)
    cp \
      "${ROOT_DIR}/src/compiler/structural_project_object_selection_worker.aos" \
      "${PROJECT_DIR}/src/compiler/structural_project_object_selection.aos"
    ;;
  incremental)
    ;;
  *)
    echo "unsupported self-host object selection mode: ${SELECTION_MODE}" >&2
    exit 2
    ;;
esac
rm -rf "${PROJECT_DIR}/src/std"
cp -R "${STD_CLI_DIR}" "${PROJECT_DIR}/.ailang/packages/std-cli"
find "${PROJECT_DIR}/src" -name app.aibc1 -delete

cat > "${PROJECT_DIR}/project.aiproj" <<'AOS'
Program {
  Project(
    name="AiLangSelfHost"
    entryFile="src/cli/ailang.aos"
    entryExport="main"
    version="0.0.1"
  ) {
    Include(
      name="std-cli"
      version="0.0.1-alpha.2"
      path=".ailang/packages/std-cli"
    )
  }
}
AOS
