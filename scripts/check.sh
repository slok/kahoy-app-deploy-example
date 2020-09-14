#!/bin/bash
# vim: ai:ts=8:sw=8:noet
set -eufCo pipefail
export SHELLOPTS
IFS=$'\t\n'

# Copy repository in a tmp dir and clean changes.
TMP_DIR="$(mktemp -d)"
echo "Copying repository in ${TMP_DIR}"
cp -r ./ "${TMP_DIR}"
cd "${TMP_DIR}"
git reset HEAD --hard

# Generate manifests.
echo "Generating manifests"
./scripts/generate.sh

# Check if we have changes.
echo "Checking if there are changes..."
git diff --exit-code >/dev/null 2>&1 || { echo 'ERROR: generated manifests are not up to date'; exit 1; }