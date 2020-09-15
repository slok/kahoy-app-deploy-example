#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufCo pipefail
export SHELLOPTS
IFS=$'\t\n'

MANIFESTS_PATH="${MANIFESTS_PATH:-}"
[ -z "$MANIFESTS_PATH" ] && echo "MANIFESTS_PATH env is required" && exit 1;

GIT_BEFORE_COMMIT_SHA="${GIT_BEFORE_COMMIT_SHA:-}"
GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-master}" # In case our default branch is different (e.g main).
KAHOY_REPORT="${KAHOY_REPORT:-./kahoy-report.json}"

echo "Kahoy running for ${MANIFESTS_PATH} manifests..."

function kahoy_common() {
    kahoy apply \
       --git-before-commit-sha "${GIT_BEFORE_COMMIT_SHA}" \
       --git-default-branch "${GIT_DEFAULT_BRANCH}" \
       --fs-new-manifests-path "${MANIFESTS_PATH}" \
       --report-path "${KAHOY_REPORT}" \
       --auto-approve
}

case "${1:-"dry-run"}" in
"sync-run")
    kahoy_common
    ;;
"sync-diff")
    KAHOY_DIFF=true kahoy_common | colordiff
    ;;
"sync-dry-run")
    KAHOY_DRY_RUN=true kahoy_common
    ;;
"run")
    KAHOY_INCLUDE_CHANGES=true kahoy_common
    ;;
"diff")
    KAHOY_INCLUDE_CHANGES=true KAHOY_DIFF=true kahoy_common | colordiff
    ;;
"dry-run")
    KAHOY_INCLUDE_CHANGES=true KAHOY_DRY_RUN=true kahoy_common
    ;;
*)
    echo "ERROR: Unknown command"
    exit 1
    ;;
esac