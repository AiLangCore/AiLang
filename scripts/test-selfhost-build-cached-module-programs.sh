#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_PATH="${ROOT_DIR}/src/cli/ailang.aos"

BUILD_BODY="$(sed -n '/Let(name=writeBuildGraphArtifacts)/,/Let(name=selectBootstrapBuildInput)/p' "${CLI_PATH}")"

printf '%s\n' "${BUILD_BODY}" | rg -Fq 'Call(target=structuralProject.writeProjectAibc1FromObjectFiles)'
if printf '%s\n' "${BUILD_BODY}" | rg -Fq 'emitModuleObjects'; then
  echo 'self-hosted build cached module programs: FAIL (legacy object emitter remains active)'
  exit 1
fi
if printf '%s\n' "${BUILD_BODY}" | rg -Fq 'object.emitModuleText'; then
  echo 'self-hosted build cached module programs: FAIL (legacy text object emitter remains active)'
  exit 1
fi

echo 'self-hosted build cached module programs: PASS'
