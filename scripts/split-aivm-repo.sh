#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

TARGET_REMOTE="${1:-git@github.com:AiLangCore/AiVM.git}"
TARGET_BRANCH="${2:-main}"
SPLIT_BRANCH="${SPLIT_BRANCH:-codex/aivm-split}"
FORCE_PUSH="${FORCE_PUSH:-0}"
DRY_RUN="${DRY_RUN:-0}"
KEEP_SPLIT_BRANCH="${KEEP_SPLIT_BRANCH:-0}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: must run inside a git repository" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/${SPLIT_BRANCH}"; then
  git branch -D "${SPLIT_BRANCH}" >/dev/null
fi

echo "creating subtree split branch ${SPLIT_BRANCH} from src/AiVM.Core"
git subtree split --prefix=src/AiVM.Core -b "${SPLIT_BRANCH}" >/dev/null

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "dry run complete"
  echo "split branch: ${SPLIT_BRANCH}"
  echo "target push: ${TARGET_REMOTE} ${SPLIT_BRANCH}:${TARGET_BRANCH}"
  if [[ "${KEEP_SPLIT_BRANCH}" != "1" ]]; then
    git branch -D "${SPLIT_BRANCH}" >/dev/null
  fi
  exit 0
fi

echo "pushing ${SPLIT_BRANCH} to ${TARGET_REMOTE}:${TARGET_BRANCH}"
if [[ "${FORCE_PUSH}" == "1" ]]; then
  git push --force-with-lease "${TARGET_REMOTE}" "${SPLIT_BRANCH}:${TARGET_BRANCH}"
else
  git push "${TARGET_REMOTE}" "${SPLIT_BRANCH}:${TARGET_BRANCH}"
fi

if [[ "${KEEP_SPLIT_BRANCH}" != "1" ]]; then
  echo "cleaning local split branch ${SPLIT_BRANCH}"
  git branch -D "${SPLIT_BRANCH}" >/dev/null
fi

echo "done"
